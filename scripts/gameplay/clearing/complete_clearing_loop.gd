extends RefCounted
## CompleteClearingLoop — preload this script
## (res://scripts/gameplay/clearing/complete_clearing_loop.gd) rather than
## relying on global class_name lookup (AL-001 / ADR-009).
##
## M20 — the CLEARING-LOOP ORCHESTRATOR. It owns exactly one narrow
## responsibility: the synchronized cross-module clear TRANSACTION that turns
## one authenticated Scrubbot arrival into a committed cell clear, and the
## slot-activation entry point that turns one slot event into one M19 dispatch
## request.
##
## It does NOT own (those stay their own separate modules, CLAUDE.md §4):
##   - target selection (TargetSelector / ColorCandidateIndex);
##   - routing geometry (RoutingSystem / access truth);
##   - reservation storage (ReservationState);
##   - BoardState storage (BoardState);
##   - Scrubbot movement (ScrubbotAgent);
##   - assignment/agent orchestration (ScrubbotDispatcher — M19);
##   - win / lose / scoring / session completion (NOT M20, §13);
##   - slot cooldown / queue / consumption policy (NOT M20, §13).
##
## Arrival authority flows ONE way: the loop listens ONLY to the dispatcher's
## authenticated `assignment_arrived` signal (emitted after M19's own immutable
## owner/target/color/agent identity checks). It NEVER treats a raw
## ScrubbotAgent.agent_completed signal as clearing authority (§5).
##
## The clear transaction (§6) is fail-closed with explicit rollback: a failed
## BoardState write clears nothing; a failed candidate sync or reservation
## resolve rolls BoardState back to ACTIVE and restores candidate truth, leaving
## the reservation and the dispatcher assignment held — never a half-clear.

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
## introduces NO win/lose/session policy, §13).
class Outcome:
	const NONE := &"NONE"
	const CLEARED := &"CLEARED"
	const PREFLIGHT_REJECTED := &"PREFLIGHT_REJECTED"
	const BOARD_WRITE_FAILED := &"BOARD_WRITE_FAILED"
	const CANDIDATE_ROLLBACK := &"CANDIDATE_ROLLBACK"
	const RESERVATION_ROLLBACK := &"RESERVATION_ROLLBACK"
	const FINALIZE_FAILED := &"FINALIZE_FAILED"

# --- injected bundle (all null until bind()) ---------------------------------
var _board = null
var _slots = null
var _candidates = null
var _reservations = null
var _dispatcher = null
var _renderer = null

var _bound: bool = false
## Callable connected to the dispatcher's arrival signal; kept so reset/rebind
## semantics stay explicit even though M20 constructs a fresh loop per bundle.
var _arrival_cb: Callable = Callable()

# --- observation counters (no gameplay policy) -------------------------------
var _cleared_count: int = 0
var _last_outcome: StringName = Outcome.NONE

## Bind the separate systems into one clearing bundle (§2). Initialization-only
## and fail-closed: any failure returns false and leaves the loop fully unbound.
## A second bind() on an already-bound loop returns false and preserves the
## original bundle (no destructive rebind — construct a fresh loop for a new
## board/session, §2).
func bind(board, slot_system, candidate_index, reservation_state, dispatcher, renderer = null) -> bool:
	if _bound:
		return false
	if not (board is BoardState):
		return false
	# SlotSystem: real, configured, exactly five slots (§2, §8.8).
	if not (slot_system is SlotSystem):
		return false
	if not slot_system.is_configured():
		return false
	if slot_system.get_slot_count() != SLOT_COUNT:
		return false
	# Candidate index / reservation state / dispatcher: exact-bound to THIS board
	# (reference identity, not merely compatible shapes).
	if not (candidate_index is ColorCandidateIndex) or not _bool_true(candidate_index.is_bound_to(board)):
		return false
	if not (reservation_state is ReservationState) or not _bool_true(reservation_state.is_bound_to(board)):
		return false
	if not (dispatcher is ScrubbotDispatcher):
		return false
	if not _bool_true(dispatcher.is_bound_to(board, reservation_state)):
		return false
	# No in-flight assignments may already exist at initial bind (§2).
	if dispatcher.get_active_count() != 0:
		return false
	# Optional renderer: when supplied it must be a live, real BoardRenderer
	# exact-bound to the same board (§2). renderer == null is a valid headless
	# configuration (§6).
	if renderer != null:
		if not (renderer is BoardRenderer) or not is_instance_valid(renderer):
			return false
		if not _bool_true(renderer.is_bound_to(board)):
			return false
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

## Exact read-only bundle-coherence query (§2). True only when every bound
## collaborator still reports exact-identity binding to this board (and the
## reservation state), so a sibling rebound after bind() is detected before the
## loop mutates gameplay truth. Never exposes the internal references.
func is_coherent() -> bool:
	if not _bound:
		return false
	if not _bool_true(_candidates.is_bound_to(_board)):
		return false
	if not _bool_true(_reservations.is_bound_to(_board)):
		return false
	if not _bool_true(_dispatcher.is_bound_to(_board, _reservations)):
		return false
	if _renderer != null:
		if not is_instance_valid(_renderer) or not _bool_true(_renderer.is_bound_to(_board)):
			return false
	return true

# --------------------------------------------------------------- activation --

## One slot activation -> at most one M19 dispatch request (§4). Returns the
## dispatcher's DispatchResult; loop-level rejects return an inert
## DispatchResult.failure(INVALID_REQUEST). Slot fields are never mutated by a
## success OR a failure (§4). The no-work / reachability decision is delegated
## entirely to the M19 dispatcher + TargetSelector + ProductionTargetAccess
## path — the loop performs NO board scan or reachability logic itself.
func activate_slot(slot_id, start_position: Vector2, speed: float = DEFAULT_SPEED) -> RefCounted:
	if not _bound or not is_coherent():
		return _reject()
	# Actual integer slot id in 0..4 (a float/bool/other Variant is not a slot).
	if typeof(slot_id) != TYPE_INT:
		return _reject()
	if slot_id < 0 or slot_id >= SLOT_COUNT:
		return _reject()
	if not _slots.is_configured():
		return _reject()
	if not _slots.is_slot_available(slot_id):
		return _reject()
	var palette_id: int = _slots.get_slot_palette_id(slot_id)
	if palette_id < 0:
		return _reject()
	if not _is_finite_vec(start_position):
		return _reject()
	if not is_finite(speed) or speed <= 0.0:
		return _reject()
	# Delegate: the dispatcher makes at most one Scrubbot; no target / blocked
	# target -> zero agent, zero reservation, no BoardState/slot mutation (§4).
	return _dispatcher.dispatch(palette_id, start_position, speed)

func _reject() -> RefCounted:
	return DispatchResult.failure(DispatchResult.FailureReason.INVALID_REQUEST)

# --------------------------------------------------------------- arrival -----

## Authenticated-arrival handler (§5/§6). Connected ONLY to the dispatcher's
## `assignment_arrived` signal. Re-validates the full pre-arrival tuple before
## mutating any gameplay truth, then executes the authoritative clear
## transaction in the exact locked order, with explicit rollback on partial
## failure. Records an observation outcome; introduces no win/session policy.
func _on_assignment_arrived(owner_id: int, target_index: int, color_id: int, agent) -> void:
	if not _arrival_preflight_ok(owner_id, target_index, color_id, agent):
		_last_outcome = Outcome.PREFLIGHT_REJECTED
		return

	# 1. Commit the physical clear. Nothing after may run if this fails.
	if not _board.set_cell_state(target_index, BoardState.CellState.CLEARED):
		_last_outcome = Outcome.BOARD_WRITE_FAILED
		return

	# 2. Keep the candidate index coherent with the mutated cell. On failure roll
	#    BoardState back to ACTIVE and restore candidate truth; hold the
	#    reservation and the dispatcher assignment; do NOT finalize the agent.
	if not _bool_true(_candidates.sync_cell(target_index)):
		_board.set_cell_state(target_index, BoardState.CellState.ACTIVE)
		_restore_candidate(target_index)
		_last_outcome = Outcome.CANDIDATE_ROLLBACK
		return

	# 3. Resolve the reservation exactly once. On failure roll BoardState back to
	#    ACTIVE, resync candidate truth, leave the reservation as it was, hold the
	#    dispatcher assignment, do NOT finalize the agent.
	if not _bool_true(_reservations.resolve_arrival(target_index, owner_id)):
		_board.set_cell_state(target_index, BoardState.CellState.ACTIVE)
		_restore_candidate(target_index)
		_last_outcome = Outcome.RESERVATION_ROLLBACK
		return

	# 4. Presentation-only single-cell repaint (alpha 0), when a renderer is bound.
	if _renderer != null and is_instance_valid(_renderer):
		_renderer.update_cells([target_index])

	# 5. Dispatcher finalization AFTER the gameplay-state commit: removes the
	#    active entry exactly once and schedules the Scrubbot for safe destruction
	#    with no return path. Healthy production finalization must succeed; a
	#    failure is surfaced (not hidden) via the outcome.
	if not _dispatcher.finalize_arrival(owner_id, target_index, color_id, agent):
		_last_outcome = Outcome.FINALIZE_FAILED
		return

	_cleared_count += 1
	_last_outcome = Outcome.CLEARED

## Full pre-mutation preflight (§5). Any false leaves gameplay truth untouched.
func _arrival_preflight_ok(owner_id: int, target_index: int, color_id: int, agent) -> bool:
	if not _bound or not is_coherent():
		return false
	# The dispatcher must still report EXACTLY this arrived assignment (authority).
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

## Best-effort candidate-truth restore for a rolled-back target: the cell is
## ACTIVE again, so a single-cell sync re-adds it to its color bucket; if the
## cache neutralized, a full rebuild from live BoardState restores it.
func _restore_candidate(target_index: int) -> void:
	if _bool_true(_candidates.sync_cell(target_index)):
		return
	if _candidates.has_method("rebuild"):
		_candidates.rebuild()

# ------------------------------------------------------------------ reset ----

## Cancel/reset all in-flight dispatch state without undoing already-cleared
## artwork (§9). Delegates to the dispatcher's existing cancel-all, which frees
## every active agent and releases every dispatcher-owned reservation. It does
## NOT mutate BoardState (already-CLEARED cells stay CLEARED, candidate truth for
## unchanged cells is untouched) and does NOT rewind owner ids. A stale
## completion after reset cannot clear anything: the dispatcher no longer reports
## the assignment as pending, so the arrival preflight rejects it. Re-entry-safe
## (the dispatcher's own reset guard collapses nested resets).
func reset() -> void:
	if not _bound:
		return
	_dispatcher.reset()

# ------------------------------------------------------------- read-only -----

func get_cleared_count() -> int:
	return _cleared_count

func get_last_outcome() -> StringName:
	return _last_outcome

# ------------------------------------------------------------- internals -----

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true

static func _is_finite_vec(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
