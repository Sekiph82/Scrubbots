extends RefCounted
## CompleteClearingLoop — preload this script
## (res://scripts/gameplay/clearing/complete_clearing_loop.gd) rather than
## relying on global class_name lookup (AL-001 / ADR-009).
##
## M20 — the CLEARING-LOOP ORCHESTRATOR. Owns exactly one narrow
## responsibility: the synchronized cross-module clear TRANSACTION that turns
## one authenticated Scrubbot arrival into a committed cell clear, and the
## slot-activation entry point that turns one slot event into one M19 dispatch.
##
## It does NOT own (those stay their own separate modules, CLAUDE.md §4):
## target selection, routing geometry, reservation storage, BoardState storage,
## candidate buckets, Scrubbot movement, M19 assignment/agent orchestration,
## win/lose/scoring/session completion, or slot cooldown/queue/consumption.
##
## Arrival authority flows ONE way: the loop listens ONLY to the dispatcher's
## authenticated `assignment_arrived` signal (emitted once after M19's own
## immutable owner/target/color/agent identity checks). It never treats a raw
## ScrubbotAgent.agent_completed signal as clearing authority.
##
## strict-v2 transaction correction (M20-C001 V02, F-M20-STRICT-001..007):
##   - bind() is a real transaction: a guard is armed before the first external
##     coherence callback, the signal is connected ONLY after full validation +
##     a drift re-check, and a nested/failed bind connects no ghost signal and
##     leaves the loop unbound. Board/Slot/Dispatcher/Renderer are narrowed to
##     EXACT production script identity (no adversarial subclass seam); only the
##     candidate index / reservation state accept subclasses, for controlled
##     rollback testing, and their callbacks are treated as transaction-safe.
##   - activate_slot() is serialized: at most one activation body runs, it is
##     rejected while an arrival transaction is committing, and a reset requested
##     (or live-coherence drift) during preflight aborts before dispatch.
##   - authenticated arrivals are serialized losslessly through a private queue:
##     a second DISTINCT arrival that fires while one transaction is committing is
##     queued and drained after it (M19 emits the bridge once), never dropped.
##   - reset() is transactional: it records intent + advances a generation, never
##     calls dispatcher.reset() mid-mutated tuple; a mid-transaction reset rolls
##     the arrival back to a proven-coherent pre-clear tuple first, then drains
##     the dispatcher reset at a safe point and clears any stale queued arrivals.
##   - the clear transaction commits gameplay truth in the corrected order
##     (BoardState -> candidate -> reservation -> dispatcher finalize) and only
##     THEN repaints the optional renderer (presentation-only, never between
##     ownership resolution and finalization). Each step captures a detached
##     pre-state snapshot, verifies its postcondition, and on any failure runs a
##     VERIFIED rollback to the exact pre-arrival tuple — or surfaces the explicit
##     ROLLBACK_FAILED fatal outcome. Never a half-clear, never a false-clear
##     frame on rollback.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const DispatchResult = preload("res://scripts/gameplay/dispatch/dispatch_result.gd")

const SLOT_COUNT := 5
const DEFAULT_SPEED := 6.0

## Stable arrival-transaction outcomes (observation/testing only — the loop
## introduces NO win/lose/session policy).
class Outcome:
	const NONE := &"NONE"
	const CLEARED := &"CLEARED"
	const PREFLIGHT_REJECTED := &"PREFLIGHT_REJECTED"
	const BOARD_WRITE_FAILED := &"BOARD_WRITE_FAILED"
	const BOARD_POSTCONDITION_FAILED := &"BOARD_POSTCONDITION_FAILED"
	const CANDIDATE_ROLLBACK := &"CANDIDATE_ROLLBACK"
	const RESERVATION_ROLLBACK := &"RESERVATION_ROLLBACK"
	const FINALIZE_FAILED := &"FINALIZE_FAILED"
	const RESET_ABORTED := &"RESET_ABORTED"
	## Fatal: authoritative layers could not be restored to a coherent
	## pre-arrival tuple. Never reported as ordinary success.
	const ROLLBACK_FAILED := &"ROLLBACK_FAILED"

# --- injected bundle (all null until bind()) ---------------------------------
var _board = null
var _slots = null
var _candidates = null
var _reservations = null
var _dispatcher = null
var _renderer = null

var _bound: bool = false
var _arrival_cb: Callable = Callable()

# --- transaction guards / generation -----------------------------------------
## Armed only while bind() validates/commits, so a nested bind() from a bind-time
## coherence callback fails closed (F-M20-STRICT-001).
var _in_bind: bool = false
## Armed only while one activate_slot() body runs (F-M20-STRICT-002).
var _in_activation: bool = false
## Armed while the serial arrival drain is running (F-M20-STRICT-006). Blocks
## activation and re-entrant drains.
var _draining: bool = false
## Loop reset generation + request flag (F-M20-STRICT-005/006). reset() advances
## the generation and records intent; a running activation/arrival aborts when it
## moves, and the heavy dispatcher.reset() drains at a safe point.
var _generation: int = 0
var _reset_requested: bool = false
var _reset_in_progress: bool = false

## Private lossless serial arrival queue of immutable tuples
## {owner,target,color,agent}. Never exposed by any public query.
var _arrival_queue: Array = []

# --- observation counters (no gameplay policy) -------------------------------
var _cleared_count: int = 0
var _last_outcome: StringName = Outcome.NONE

# ------------------------------------------------------------------- bind ----

## Bind the separate systems into one clearing bundle as a real transaction
## (F-M20-STRICT-001). Board / SlotSystem / ScrubbotDispatcher / BoardRenderer
## are required to be the EXACT production scripts (no adversarial subclass seam);
## the candidate index and reservation state accept subclasses (for controlled
## rollback testing). The `assignment_arrived` signal is connected ONLY after full
## validation + a drift re-check, so a nested or failed bind connects no ghost
## callback and leaves the loop fully unbound. A second bind on an already-bound
## loop returns false and preserves the original bundle (no destructive rebind).
func bind(board, slot_system, candidate_index, reservation_state, dispatcher, renderer = null) -> bool:
	if _bound:
		return false
	if _in_bind:
		return false
	_in_bind = true
	var ok := _bind_txn(board, slot_system, candidate_index, reservation_state, dispatcher, renderer)
	_in_bind = false
	return ok

func _bind_txn(board, slot_system, candidate_index, reservation_state, dispatcher, renderer) -> bool:
	# Exact production script identity for the four dependencies M20 has no reason
	# to accept subclasses of.
	if not _is_exact_script(board, BoardState):
		return false
	if not _is_exact_script(slot_system, SlotSystem):
		return false
	if not slot_system.is_configured():
		return false
	if slot_system.get_slot_count() != SLOT_COUNT:
		return false
	# Candidate index / reservation state: subclasses accepted (rollback doubles).
	if not (candidate_index is ColorCandidateIndex):
		return false
	if not (reservation_state is ReservationState):
		return false
	if not _is_exact_script(dispatcher, ScrubbotDispatcher):
		return false
	if renderer != null:
		if not _is_exact_script(renderer, BoardRenderer) or not is_instance_valid(renderer):
			return false
	# Coherence probe (external callbacks) run TWICE: the second run detects a
	# callback-induced same-size foreign-board drift/rebind from the first.
	if not _probe(board, candidate_index, reservation_state, dispatcher, renderer):
		return false
	if not _probe(board, candidate_index, reservation_state, dispatcher, renderer):
		return false
	if dispatcher.get_active_count() != 0:
		return false
	# Commit + connect the arrival bridge ONLY now (no signal before validation).
	_board = board
	_slots = slot_system
	_candidates = candidate_index
	_reservations = reservation_state
	_dispatcher = dispatcher
	_renderer = renderer
	_arrival_cb = Callable(self, "_on_assignment_arrived")
	dispatcher.assignment_arrived.connect(_arrival_cb)
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

## Exact read-only bundle-coherence query. True only when every bound collaborator
## still reports exact-identity binding (F-M20-STRICT-001). Never exposes refs.
func is_coherent() -> bool:
	if not _bound:
		return false
	return _probe(_board, _candidates, _reservations, _dispatcher, _renderer)

func _probe(board, ci, rs, disp, renderer) -> bool:
	if not _bool_true(ci.is_bound_to(board)):
		return false
	if not _bool_true(rs.is_bound_to(board)):
		return false
	if not _bool_true(disp.is_bound_to(board, rs)):
		return false
	if renderer != null:
		if not is_instance_valid(renderer) or not _bool_true(renderer.is_bound_to(board)):
			return false
	return true

# --------------------------------------------------------------- activation --

## One slot activation -> at most one M19 dispatch request (F-M20-STRICT-002).
## Serialized: rejected (REENTRANT) while another activation or an arrival
## transaction is active, (RESETTING) while a reset is pending or one is injected
## during preflight, (INVALID_REQUEST) for a malformed slot/argument or lost
## coherence. Slot fields are never mutated; the no-work/reachability decision is
## delegated entirely to the dispatcher path.
func activate_slot(slot_id, start_position: Vector2, speed: float = DEFAULT_SPEED) -> RefCounted:
	if not _bound:
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if _in_activation or _draining:
		return _fail(DispatchResult.FailureReason.REENTRANT)
	if _reset_requested:
		return _fail(DispatchResult.FailureReason.RESETTING)
	_in_activation = true
	var my_gen: int = _generation
	var r := _activate_core(slot_id, start_position, speed, my_gen)
	_in_activation = false
	_drain_pending_reset()
	return r

func _activate_core(slot_id, start_position: Vector2, speed: float, my_gen: int) -> RefCounted:
	if not is_coherent():
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if _reset_requested or _generation != my_gen:
		return _fail(DispatchResult.FailureReason.RESETTING)
	if typeof(slot_id) != TYPE_INT:
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if not _slots.is_configured():
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if not _slots.is_slot_available(slot_id):
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	var palette_id: int = _slots.get_slot_palette_id(slot_id)
	if palette_id < 0:
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if not _is_finite_vec(start_position):
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	if not is_finite(speed) or speed <= 0.0:
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	# Live-coherence drift / injected reset during preflight -> abort before dispatch.
	if _reset_requested or _generation != my_gen:
		return _fail(DispatchResult.FailureReason.RESETTING)
	if not is_coherent():
		return _fail(DispatchResult.FailureReason.INVALID_REQUEST)
	return _dispatcher.dispatch(palette_id, start_position, speed)

func _fail(reason: StringName) -> RefCounted:
	return DispatchResult.failure(reason)

# --------------------------------------------------------------- arrival -----

## Authenticated-arrival entry (F-M20-STRICT-006). Connected ONLY to the
## dispatcher's `assignment_arrived` signal. Enqueues the immutable tuple and
## drains the serial processor, so a distinct arrival that fires synchronously
## while another transaction is committing is queued, not dropped.
func _on_assignment_arrived(owner_id: int, target_index: int, color_id: int, agent) -> void:
	_enqueue_arrival(owner_id, target_index, color_id, agent)
	_drain_arrivals()

func _enqueue_arrival(owner_id: int, target_index: int, color_id: int, agent) -> void:
	# Duplicate same assignment is not queued twice (idempotent).
	for e in _arrival_queue:
		if e["owner"] == owner_id and e["agent"] == agent:
			return
	_arrival_queue.append({"owner": owner_id, "target": target_index, "color": color_id, "agent": agent})

func _drain_arrivals() -> void:
	if _draining:
		return
	_draining = true
	while not _arrival_queue.is_empty():
		if _reset_requested:
			break
		var t: Dictionary = _arrival_queue.pop_front()
		_last_outcome = _run_transaction(t, _generation)
	_draining = false
	_drain_pending_reset()

## The one authoritative clear transaction for one arrival tuple (F-M20-STRICT-004).
func _run_transaction(t: Dictionary, my_gen: int) -> StringName:
	var owner: int = t["owner"]
	var target: int = t["target"]
	var color: int = t["color"]
	var agent = t["agent"]

	# 1. Authenticated preflight + reset/generation gate BEFORE any mutation.
	if _reset_requested or _generation != my_gen:
		return Outcome.RESET_ABORTED
	if not _arrival_preflight_ok(owner, target, color, agent):
		return Outcome.PREFLIGHT_REJECTED
	var snap := _snapshot(owner, target, color)

	# 2. BoardState ACTIVE -> CLEARED. Failure here mutates nothing after it.
	if not _board.set_cell_state(target, BoardState.CellState.CLEARED):
		return Outcome.BOARD_WRITE_FAILED
	if _board.get_cell_state(target) != BoardState.CellState.CLEARED or _board.get_color_id(target) != color:
		return Outcome.BOARD_POSTCONDITION_FAILED if _rollback(t, snap) else Outcome.ROLLBACK_FAILED
	if _reset_requested or _generation != my_gen:
		return Outcome.RESET_ABORTED if _rollback(t, snap) else Outcome.ROLLBACK_FAILED

	# 3. ColorCandidateIndex single-cell sync + postcondition.
	var csync := _bool_true(_candidates.sync_cell(target))
	var cpost := _bool_true(_candidates.is_bound_to(_board)) and not _raw_has_candidate(color, target)
	if not (csync and cpost):
		return Outcome.CANDIDATE_ROLLBACK if _rollback(t, snap) else Outcome.ROLLBACK_FAILED
	if _reset_requested or _generation != my_gen:
		return Outcome.RESET_ABORTED if _rollback(t, snap) else Outcome.ROLLBACK_FAILED

	# 4. ReservationState exact arrival resolve + postcondition.
	var rres := _bool_true(_reservations.resolve_arrival(target, owner))
	var rpost: bool = _reservations.get_owner(target) == -1 \
		and _reservations.get_target_for_owner(owner) == -1 \
		and _reservations.get_reservation_count() == snap["res_count"] - 1
	if not (rres and rpost):
		return Outcome.RESERVATION_ROLLBACK if _rollback(t, snap) else Outcome.ROLLBACK_FAILED
	if _reset_requested or _generation != my_gen:
		return Outcome.RESET_ABORTED if _rollback(t, snap) else Outcome.ROLLBACK_FAILED

	# 5. ScrubbotDispatcher exact finalization + postcondition. No renderer yet.
	var fret = _dispatcher.finalize_arrival(owner, target, color, agent)
	var fpost: bool = (not _dispatcher.has_owner(owner)) and _dispatcher.get_active_count() == snap["active_count"] - 1
	if not (_bool_true(fret) and fpost):
		# Finalization failed: if the dispatcher still retains the exact arrived
		# assignment, restore the full pre-arrival tuple; otherwise it is fatal.
		if _dispatcher.is_arrival_pending(owner, target, color, agent):
			return Outcome.FINALIZE_FAILED if _rollback(t, snap) else Outcome.ROLLBACK_FAILED
		return Outcome.ROLLBACK_FAILED

	# 6. Optional presentation repaint from the already-committed BoardState.
	if _renderer != null and is_instance_valid(_renderer) and _bool_true(_renderer.is_bound_to(_board)):
		_renderer.update_cells([target])

	_cleared_count += 1
	return Outcome.CLEARED

## Full pre-mutation preflight. Any false leaves gameplay truth untouched.
func _arrival_preflight_ok(owner_id: int, target_index: int, color_id: int, agent) -> bool:
	if not _bound or not is_coherent():
		return false
	if not _bool_true(_dispatcher.is_arrival_pending(owner_id, target_index, color_id, agent)):
		return false
	if not _board.is_valid_index(target_index):
		return false
	if _board.get_cell_state(target_index) != BoardState.CellState.ACTIVE:
		return false
	if _board.get_color_id(target_index) != color_id:
		return false
	if _reservations.get_owner(target_index) != owner_id:
		return false
	if _reservations.get_target_for_owner(owner_id) != target_index:
		return false
	return true

## Detached pre-state snapshot sufficient to prove exact rollback (F-M20-STRICT-007).
func _snapshot(owner: int, target: int, color: int) -> Dictionary:
	return {
		"target": target,
		"color": color,
		"in_candidates": _raw_has_candidate(color, target),
		"res_count": _reservations.get_reservation_count(),
		"reserved": _reservations.get_reserved_indices(),
		"owner_of_target": _reservations.get_owner(target),
		"target_of_owner": _reservations.get_target_for_owner(owner),
		"active_count": _dispatcher.get_active_count(),
		"renderer_pixel": _renderer_pixel(target),
	}

## VERIFIED rollback to the exact pre-arrival tuple (F-M20-STRICT-010). Returns
## true ONLY when the full intended tuple is restored and proven; false surfaces a
## ROLLBACK_FAILED fatal outcome upstream.
func _rollback(t: Dictionary, snap: Dictionary) -> bool:
	var owner: int = t["owner"]
	var target: int = snap["target"]
	var color: int = snap["color"]
	# Restore BoardState first (required before any re-reserve — reserve needs ACTIVE).
	_board.set_cell_state(target, BoardState.CellState.ACTIVE)
	# Restore candidate membership: healthy single-cell sync, else exceptional
	# rebuild/rebind (allowed only on rollback recovery).
	if not (_bool_true(_candidates.sync_cell(target)) and _raw_has_candidate(color, target)):
		if _candidates.is_bound() and _candidates.has_method("rebuild"):
			_candidates.rebuild()
		if not _bool_true(_candidates.is_bound_to(_board)) and _candidates.has_method("rebind"):
			_candidates.rebind(_board)
	# Restore the exact reservation pair if a failed callback removed it.
	if _reservations.get_owner(target) != owner or _reservations.get_target_for_owner(owner) != target:
		_reservations.reserve(target, owner)
	return _verify_pre_arrival(t, snap)

func _verify_pre_arrival(t: Dictionary, snap: Dictionary) -> bool:
	var owner: int = t["owner"]
	var target: int = snap["target"]
	var color: int = snap["color"]
	if _board.get_cell_state(target) != BoardState.CellState.ACTIVE:
		return false
	if _board.get_color_id(target) != color:
		return false
	if not _raw_has_candidate(color, target):
		return false
	if not _bool_true(_candidates.is_bound_to(_board)):
		return false
	if _reservations.get_owner(target) != owner:
		return false
	if _reservations.get_target_for_owner(owner) != target:
		return false
	if _reservations.get_reservation_count() != snap["res_count"]:
		return false
	if not _bool_true(_dispatcher.is_arrival_pending(owner, target, color, t["agent"])):
		return false
	# Presentation was never repainted before finalization, so a healthy renderer
	# must still show the pre-clear source pixel (no false-clear frame).
	if snap["renderer_pixel"] != null:
		var px = _renderer_pixel(target)
		if px == null or not _colors_close(px, snap["renderer_pixel"], 0.02):
			return false
	return true

# ------------------------------------------------------------------ reset ----

## Cancel/reset all in-flight dispatch state without undoing already-cleared
## artwork (F-M20-STRICT-005/006). Transactional: records intent + advances the
## generation immediately so any running activation/arrival aborts; the heavy
## dispatcher.reset() (which frees agents + releases reservations) is deferred to
## a safe point when no activation/arrival is mid-flight, so it never runs against
## a partially-mutated cross-module tuple. Preserves BoardState/candidate truth
## for unchanged cells, does not rewind owner ids, and is re-entry-safe.
func reset() -> void:
	if not _bound:
		return
	_reset_requested = true
	_generation += 1
	if _in_activation or _draining or _reset_in_progress:
		return # deferred to a safe point
	_perform_reset()

## Drain a deferred reset once the current activation/drain has fully unwound.
func _drain_pending_reset() -> void:
	if _reset_requested and not _in_activation and not _draining and not _reset_in_progress:
		_perform_reset()

func _perform_reset() -> void:
	if _reset_in_progress:
		return
	_reset_in_progress = true
	_arrival_queue.clear()
	_dispatcher.reset()
	_reset_requested = false
	_reset_in_progress = false

# ------------------------------------------------------------- read-only -----

func get_cleared_count() -> int:
	return _cleared_count

func get_last_outcome() -> StringName:
	return _last_outcome

# ------------------------------------------------------------- internals -----

func _raw_has_candidate(color: int, target: int) -> bool:
	# null = the documented no-exclusion contract (raw membership, ignoring any
	# reservation exclusion).
	var arr = _candidates.get_candidates(color, null)
	if typeof(arr) != TYPE_ARRAY:
		return false
	return arr.has(target)

func _renderer_pixel(target: int):
	if _renderer == null or not is_instance_valid(_renderer):
		return null
	if not _bool_true(_renderer.is_bound_to(_board)):
		return null
	var pos: Vector2i = _board.get_cell_position(target)
	if pos.x < 0:
		return null
	return _renderer.get_pixel_color(pos.x, pos.y)

static func _colors_close(a: Color, b: Color, tol: float) -> bool:
	return absf(a.r - b.r) <= tol and absf(a.g - b.g) <= tol \
		and absf(a.b - b.b) <= tol and absf(a.a - b.a) <= tol

static func _is_exact_script(obj, script) -> bool:
	return obj != null and typeof(obj) == TYPE_OBJECT and obj.get_script() == script

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true

static func _is_finite_vec(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
