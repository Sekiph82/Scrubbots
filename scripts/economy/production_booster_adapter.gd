extends RefCounted
## ProductionBoosterAdapter — preload
## (res://scripts/economy/production_booster_adapter.gd).
##
## The CONCRETE adapter BoosterService drives against the REAL gameplay engines
## (M23 supply, M24 slots, M27 solver, BoardState) — replacing the V01 fake-only
## adapter (M39 V02, F-M39-003). All safety proofs use the real DeadlockClassifier
## (SolvabilitySolver progress search) over a real ProofState; all commits/rollbacks act on
## the live engines.
##
## Random  — reorders remaining unselected M23 batches (conservation preserved),
##           committed only if three consecutive front selections from the reordered
##           supply are each proven non-deadlocked; rollback reloads the exact prior supply.
## Selector— extracts an arbitrary solver-safe remaining batch to the rightmost
##           EMPTY slot (capacity 5 or 6) via a reorder-to-front + real select;
##           rollback reloads the exact prior supply and frees the placed slot.
## Tornado — purges one present color atomically across BoardState + supply +
##           idle slots, requiring quiescence (no in-flight M26 work / no live
##           M25 claims), with exact per-stage rollback and fault injection.

const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const DeadlockClassifier = preload("res://scripts/gameplay/solver/deadlock_classifier.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")

var _level
var _board
var _supply
var _slots
var _scheduler          # M26 auto-dispatch scheduler (for in-flight quiescence)
var _classifier
## Owner proof budget (ms) for one player-facing booster safety question; see _begin_budget().
## Owner target 250 ms (2026-10-16), raised to the measured safe limit: at a 59x59 quiet moment
## (no robot in flight) one Selector single-batch proof needs 249-361 ms on the desktop, so 250
## would refuse the player's chosen batch; Random's 3-placement proof needs 3.8-24.5 s there,
## which no responsive budget covers (it fails closed and is ~3 ms once any robot moves).
const PROOF_BUDGET_MS := 400
## This adapter's budget; 0 = unbudgeted (the Need-a-Hand next-start prover keeps its pre-R05
## deterministic, machine-speed-independent proofs). Tests may lower it to force a timeout.
var budget_ms := PROOF_BUDGET_MS
var _deadline_usec := 0
var _budget_hit := false
var _last_timed_out := false
## Selector list resume point: a cut-off list continues from here on the next call, so a
## valid batch is never permanently hidden by the budget.
var _list_offset := 0
## Optional fault injector for tests: Callable(stage:String) -> bool; true forces
## that stage to fail so rollback can be proven. Never set in production.
var _fault: Callable = Callable()
## M46 R06 off-frame proof (owner 2026-10-16: no freeze, "Checking…" state). A detached copy
## (detached_copy) proves on a worker thread under this total cap; the verdict is cached here
## for the exact state it was proven on, so legality and execute answer without re-proving.
const PROOF_TOTAL_MS := 5000
## The cap a detached_copy() proves under (tests may lower it to force a timeout).
var offframe_budget_ms := PROOF_TOTAL_MS
var _cancelled := false
## kind -> verdict for the state _verdict_key: "random" -> true / false / "timeout" (5 s cap hit);
## "selector_list" -> {"ids": proven batch ids, "partial": cap hit (unlisted = unproven)}.
var _verdicts := {}
var _verdict_key: Array = []
## Diagnostic: synchronous (main-thread) proofs started on this adapter (tests prove a cached
## verdict answers without one).
var live_proof_count := 0

## Read-only frozen board for a worker-thread proof: ProofState.from_runtime reads only the
## cell count + per-cell state, captured on the main thread.
class FrozenBoard extends RefCounted:
	var _states: PackedByteArray
	var _rev: int
	func _init(board) -> void:
		_states = board.get_cell_states_copy()
		_rev = board.get_revision()
	func get_cell_count() -> int:
		return _states.size()
	func get_cell_state(i: int) -> int:
		return _states[i]
	func get_revision() -> int:
		return _rev

func _init(level, board, supply_engine, slots_engine, scheduler) -> void:
	_level = level
	_board = board
	_supply = supply_engine
	_slots = slots_engine
	_scheduler = scheduler
	_classifier = DeadlockClassifier.new()

func set_fault_injector(f: Callable) -> void:
	_fault = f

func _faulted(stage: String) -> bool:
	return _fault.is_valid() and bool(_fault.call(stage))

# ------------------------------------------------------ R06 off-frame proof ----

## A copy that shares nothing mutable with the live engines (frozen board, copied supply +
## slots, no scheduler => in-flight 0), so its proofs may run on a worker thread while the
## main thread keeps rendering. Same proof code, budget = PROOF_TOTAL_MS. Main thread only.
func detached_copy():
	var sup = BatchSupplyEngine.create(_supply.get_column_count(), _supply.get_preview_depth())
	if sup == null or not sup.load_candidate(_current_cols(), _supply.get_seed(), _supply.get_palette_size()):
		return null
	var ss = _scratch_slots_from_live()
	if ss == null:
		return null
	var d = get_script().new(_level, FrozenBoard.new(_board), sup, ss, null)
	d.budget_ms = offframe_budget_ms
	return d

## Worker-thread entry (WorkerThreadPool task) on a detached_copy(): runs one proof and writes
## {"value", "timed_out"} into out[0]. Touches nothing but this detached adapter.
func run_offframe(kind: String, out: Array) -> void:
	if kind == "random":
		var p: Dictionary = propose_random_reorder()
		out[0] = {"value": bool(p.get("safe", false)), "timed_out": String(p.get("reason", "")) == "proof_timeout"}
	else:
		var ids: Array = eligible_safe_batches()
		out[0] = {"value": ids, "timed_out": last_proof_timed_out()}

## Stop this (detached) adapter's proofs for good; safe to call from the main thread while a
## worker runs them: every later probe fails closed as a timeout.
func cancel_proof() -> void:
	_cancelled = true
	_classifier.cancel()

## Identity of the gameplay state a booster proof depends on (board instance + monotonic
## revision, full supply snapshot incl. seed, slot snapshots incl. capacity). Compared with ==
## (exact, no hash collisions).
func state_key() -> Array:
	return [_board.get_instance_id(), _board.get_revision(), _supply.debug_snapshot(), _slots.snapshot()]

## Store an off-frame verdict for the state `key` it was proven on (older ones drop).
func put_verdict(kind: String, key: Array, value) -> void:
	if key != _verdict_key:
		_verdicts.clear()
		_verdict_key = key
	_verdicts[kind] = value

## The cached verdict for `kind` if it was proven on exactly the current state, else null.
## Only at still moments: with robots in flight the in-flight shortcut answers anyway.
func cached_verdict(kind: String):
	if not _verdicts.has(kind) or _inflight() > 0 or _verdict_key != state_key():
		return null
	return _verdicts[kind]

# ------------------------------------------------------------ helpers ----

func _inflight() -> int:
	if _scheduler != null and _scheduler.has_method("live_assignment_count"):
		return _scheduler.live_assignment_count()
	return 0

## Current supply as Array[column] of Array[ColorBatch] (deep, detached).
func _current_cols() -> Array:
	var dbg: Dictionary = _supply.debug_snapshot()
	var ps: int = int(dbg["palette_size"])
	var out: Array = []
	for col in dbg["columns"]:
		var q: Array = []
		for b in col:
			q.append(ColorBatch.make(String(b["batch_id"]), int(b["color_id"]), int(b["robot_count"]), ps))
		out.append(q)
	return out

## Is a candidate cols layout solver-SAFE (not proven-deadlocked) from the
## current board+slots? Uses the bounded runtime DeadlockClassifier (progress
## search), which is feasible on production-size boards. Safe = the candidate can
## still make authenticated progress (PROGRESSABLE / STALLED / COMPLETED).
## DEADLOCK or an inconclusive UNKNOWN_BOUND fail closed (not safe).
func _is_safe(cols: Array) -> bool:
	var probe = BatchSupplyEngine.create(_supply.get_column_count(), _supply.get_preview_depth())
	if probe == null:
		return false
	if not probe.load_candidate(cols, _supply.get_seed(), _supply.get_palette_size()):
		return false
	var state = ProofState.from_runtime(_level, _board, probe, _slots)
	if state == null:
		return false
	var status = _classifier.classify(state, _inflight()).get("status", &"")
	return status == DeadlockClassifier.PROGRESSABLE \
		or status == DeadlockClassifier.STALLED \
		or status == DeadlockClassifier.COMPLETED

# ------------------------------------------------------------ Random ----

func propose_random_reorder() -> Dictionary:
	# Reorder the flattened remaining batches deterministically, refilling columns
	# with their original sizes (conservation of ids/colors/counts, only order
	# changes). Prove owner-required >=3 consecutive legal accepted front choices
	# BEFORE offering commit (M39 V03, F-M39-V02-003).
	var original := _current_cols()
	var flat: Array = []
	for q in original:
		for b in q:
			flat.append(b)
	if flat.size() < 2:
		return {"safe": false}   # nothing meaningful to reorder
	# Deterministic reversal is a stable, conservation-preserving reorder.
	flat.reverse()
	var reordered: Array = []
	var k := 0
	for q in original:
		var nq: Array = []
		for _i in range(q.size()):
			nq.append(flat[k]); k += 1
		reordered.append(nq)
	var cached = cached_verdict("random")
	var proven: bool = typeof(cached) == TYPE_BOOL and cached
	var timed_out: bool = typeof(cached) == TYPE_STRING   # the 5 s proof ran out on this state
	if cached == null:
		_begin_budget()
		proven = _prove_three_consecutive_safe(reordered)
		timed_out = _budget_hit
		_end_budget()
	if not proven:
		return {"safe": false, "reason": "proof_timeout" if timed_out else "not_solver_safe"}
	return {
		"safe": true,
		"commit": func():
			if _faulted("random_commit"):
				return false
			return _supply.replace_live_columns(reordered),
		"rollback": func():
			_supply.replace_live_columns(original),
	}

## Owner-required 3-consecutive safe-selection proof (F-M39-V02-003). Simulates
## up to `steps` (default 3) successive accepted front-batch selections from the
## reordered supply and requires each resulting state to remain non-DEADLOCK.
## Deterministic: picks the LOWEST-index column with a non-empty front + an
## empty slot at each step. If no qualifying step exists (no empty slot / all
## columns empty), the sequence fails (`no_step`). Returns true only when three
## consecutive steps all succeed with a non-deadlock classifier verdict.
func _prove_three_consecutive_safe(cols: Array, steps: int = 3) -> bool:
	# Simulate on a scratch supply engine + a scratch slot engine mirroring the
	# current live slots — never mutate the live engines.
	var scratch_supply = BatchSupplyEngine.create(_supply.get_column_count(), _supply.get_preview_depth())
	if scratch_supply == null:
		return false
	if not scratch_supply.load_candidate(cols, _supply.get_seed(), _supply.get_palette_size()):
		return false
	var scratch_slots = _scratch_slots_from_live()
	if scratch_slots == null:
		return false
	# Baseline safety on the reordered starting state must hold.
	if not _is_safe_probe(scratch_supply, scratch_slots):
		return false
	for _step in range(steps):
		# Pick the lowest-index column whose front batch is a legal placement
		# (front non-null + at least one EMPTY slot). If none, the sequence
		# cannot produce three accepted selections deterministically.
		if scratch_slots.rightmost_empty_index() == -1:
			return false
		var chosen := -1
		for c in range(scratch_supply.get_column_count()):
			if scratch_supply.get_front(c) != null:
				chosen = c
				break
		if chosen == -1:
			return false
		var r = scratch_slots.select_front_batch(scratch_supply, chosen)
		if not r.get("ok", false):
			return false
		# The state after the accepted selection must remain non-deadlocked.
		if not _is_safe_probe(scratch_supply, scratch_slots):
			return false
	return true

func _scratch_slots_from_live():
	# Rebuild a detached FiveSlotBatchEngine that reproduces the live slots exactly as the proof
	# reads them, mirroring ProofKernel's own rebuild: REMAINING robots (initial == remaining:
	# nothing reads initial_count for future behaviour), the WAITING state, the placement
	# sequence, and the next sequence (a batch the proof places dispatches after every live one).
	# Committed work is 0 at a still moment; with robots in flight the in-flight shortcut answers
	# before this state is read. (Before M46 it used initial_count, forced ACTIVE and restarted
	# the sequence at 1: CLAUDE_PEER_REVIEW R06 MAJOR-2, tests/m46_slot_rebuild.gd.)
	var live = FiveSlotBatchEngine.new()
	if _slots.get_slot_count() == FiveSlotBatchEngine.MAX_CAPACITY:
		live.grow_to_sixth()
	for i in range(_slots.get_slot_count()):
		if _slots.is_occupied(i):
			var occ = SlotBatchState.make_occupied(_slots.get_batch_id(i), _slots.get_color_id(i),
				_slots.get_remaining(i), _slots.get_placement_sequence(i))
			if occ == null:
				return null   # malformed / remaining 0: fail closed (never prove a different state)
			if _slots.get_state(i) == SlotBatchState.WAITING:
				occ.set_state(SlotBatchState.WAITING)
			live._slots[i] = occ
	live._next_sequence = _slots._next_sequence
	return live

## Same DeadlockClassifier gate as `_is_safe` but taking already-built scratch
## supply + slots engines (used inside the 3-consecutive simulation).
func _is_safe_probe(scratch_supply, scratch_slots) -> bool:
	# M46: with live in-flight M26 work the classifier answers PROGRESSABLE before reading the
	# state, so skip building the full ProofState (~6 ms at 59x59, per probe). Exact: the same
	# null conditions ProofState.from_runtime would hit are checked first.
	var inflight := _inflight()
	if inflight > 0 and _proof_state_buildable(scratch_supply, scratch_slots):
		return true
	# Owner proof budget: an exhausted budget (or an R06 cancel) is "not proven safe" (fail closed,
	# nothing reserved).
	if _cancelled or (_deadline_usec > 0 and Time.get_ticks_usec() >= _deadline_usec):
		_budget_hit = true
		return false
	var state = ProofState.from_runtime(_level, _board, scratch_supply, scratch_slots)
	if state == null:
		return false
	var res: Dictionary = _classifier.classify(state, inflight, {"deadline_usec": _deadline_usec} if _deadline_usec > 0 else {})
	var status = res.get("status", &"")
	if String(res.get("reason", "")) == "time_budget_exhausted" \
			or (status == DeadlockClassifier.UNKNOWN_BOUND and _deadline_usec > 0 and Time.get_ticks_usec() >= _deadline_usec):
		_budget_hit = true
	return status == DeadlockClassifier.PROGRESSABLE \
		or status == DeadlockClassifier.STALLED \
		or status == DeadlockClassifier.COMPLETED

## Owner proof budget (2026-10-16): one wall-clock budget per player-facing safety question
## (Random legality / apply, Selector list / single batch / has-any). Never nested; each question
## starts a fresh deadline, so an aborted call can never leave a stale one behind.
func _begin_budget() -> void:
	live_proof_count += 1
	_budget_hit = false
	_deadline_usec = Time.get_ticks_usec() + budget_ms * 1000 if budget_ms > 0 else 0

func _end_budget() -> void:
	_deadline_usec = 0

## True when the most recent Selector single-batch / list proof ran out of its budget.
func last_proof_timed_out() -> bool:
	return _last_timed_out

## Exactly the conditions under which ProofState.from_runtime returns a state (not null).
func _proof_state_buildable(scratch_supply, scratch_slots) -> bool:
	return _level is LevelData and _board != null and scratch_slots != null \
		and scratch_supply is BatchSupplyEngine and _board.get_cell_count() == _level.get_cell_count()

# ------------------------------------------------------------ Selector ----

## Remaining batch ids that are solver-safe to extract into the rightmost EMPTY
## slot right now (requires an empty slot at the current capacity).
## Under the owner proof budget the list may be cut short (last_proof_timed_out() true): the
## unproven batches are left out (fail closed) and the next call starts where this one stopped,
## so every batch is reached again on retry. The result keeps supply (column) order.
func eligible_safe_batches() -> Array:
	var out: Array = []
	_last_timed_out = false
	if _slots.rightmost_empty_index() == -1:
		return out   # full at current capacity
	var cached = cached_verdict("selector_list")
	if cached != null:
		_last_timed_out = cached["partial"]
		return (cached["ids"] as Array).duplicate()
	var original := _current_cols()
	var ids := _batch_ids(original)
	if ids.is_empty():
		return out
	_begin_budget()
	var start := _list_offset % ids.size()
	var proven := {}
	var checked := 0
	for k in range(ids.size()):
		var bid = ids[(start + k) % ids.size()]
		if _selector_reorder_solvable(original, bid):
			proven[bid] = true
		checked += 1
		if _budget_hit:
			break   # the rest stay unproven
	_last_timed_out = _budget_hit
	# Resume AFTER the batch that ran out, so one slow batch can never pin every retry.
	_list_offset = (start + checked) % ids.size() if _budget_hit else 0
	_end_budget()
	for bid in ids:
		if proven.has(bid):
			out.append(bid)
	return out

func _batch_ids(cols: Array) -> Array:
	var ids: Array = []
	for col in cols:
		for b in col:
			ids.append(b.get_batch_id())
	return ids

## Is exactly `batch_id` solver-safe to extract right now? The same rule as membership in
## eligible_safe_batches() (empty slot + remaining batch + post-placement safety), proven for
## that one batch only (M46: the full list re-runs the solver per remaining batch). False with
## last_proof_timed_out() when the owner proof budget ran out (fail closed, retry later).
func is_batch_eligible(batch_id) -> bool:
	_last_timed_out = false
	if typeof(batch_id) != TYPE_STRING and typeof(batch_id) != TYPE_STRING_NAME:
		return false   # malformed target: never eligible (was never in the id list either)
	if _slots.rightmost_empty_index() == -1:
		return false
	var cached = cached_verdict("selector_list")
	if cached != null:
		var hit: bool = (cached["ids"] as Array).has(String(batch_id))
		_last_timed_out = cached["partial"] and not hit
		return hit
	_begin_budget()
	var ok := _selector_reorder_solvable(_current_cols(), String(batch_id))
	_last_timed_out = _budget_hit and not ok
	_end_budget()
	return ok

## M43-C004: is at least one batch solver-safe to extract right now? Same proof as
## eligible_safe_batches(), stopping at the first safe batch (read-only). Under a budget it
## shares the list's resume offset, so a slow first batch cannot pin the answer to false.
func has_eligible_safe_batch() -> bool:
	_last_timed_out = false
	if _slots.rightmost_empty_index() == -1:
		return false
	var cached = cached_verdict("selector_list")
	if cached != null:
		_last_timed_out = cached["partial"] and (cached["ids"] as Array).is_empty()
		return not (cached["ids"] as Array).is_empty()
	var original := _current_cols()
	var ids := _batch_ids(original)
	if ids.is_empty():
		return false
	_begin_budget()
	var start := _list_offset % ids.size()
	var found := false
	var checked := 0
	for k in range(ids.size()):
		found = _selector_reorder_solvable(original, ids[(start + k) % ids.size()])
		checked += 1
		if found or _budget_hit:
			break
	_last_timed_out = _budget_hit and not found
	_list_offset = (start + checked) % ids.size() if _last_timed_out else 0
	_end_budget()
	return found

## Move `batch_id` to the front of its column; the rest keep order. Returns the
## reordered cols (or null if not found).
func _cols_with_front(original: Array, batch_id: String):
	var out: Array = []
	var found := false
	for col in original:
		var front: Array = []
		var rest: Array = []
		for b in col:
			if b.get_batch_id() == batch_id:
				front.append(b); found = true
			else:
				rest.append(b)
		out.append(front + rest)
	return out if found else null

## Solver safety of the ACTUAL post-extraction/post-placement state
## (F-M39-V02-004): reorder the selected batch to the front, actually place it
## into the rightmost EMPTY slot on scratch engines, then classify. A reorder-
## only check is insufficient because the placement itself changes the supply
## queue AND the slot state.
func _selector_reorder_solvable(_original: Array, batch_id: String) -> bool:
	# Which column holds this batch?
	var target_col := -1
	for c in range(_original.size()):
		for b in _original[c]:
			if b.get_batch_id() == batch_id:
				target_col = c
	if target_col == -1:
		return false
	var cols = _cols_with_front(_original, batch_id)
	if cols == null:
		return false
	# Build scratch supply + slots and actually perform the M24 select_front.
	var scratch_supply = BatchSupplyEngine.create(_supply.get_column_count(), _supply.get_preview_depth())
	if scratch_supply == null or not scratch_supply.load_candidate(cols, _supply.get_seed(), _supply.get_palette_size()):
		return false
	var scratch_slots = _scratch_slots_from_live()
	if scratch_slots == null:
		return false
	if scratch_slots.rightmost_empty_index() == -1:
		return false
	var r = scratch_slots.select_front_batch(scratch_supply, target_col)
	if not r.get("ok", false):
		return false
	return _is_safe_probe(scratch_supply, scratch_slots)

func extract_batch(batch_id) -> Dictionary:
	var original := _current_cols()
	var target_col := -1
	for c in range(original.size()):
		for b in original[c]:
			if b.get_batch_id() == batch_id:
				target_col = c
	# Track exactly which slot the extraction placed the batch into so a stage
	# failure or a later transaction failure can free just that slot (M39 V03,
	# F-M39-V02-004/005). -1 = nothing placed yet.
	var placed_slot := [-1]
	return {
		"apply": func():
			if _faulted("selector_extract"):
				return false
			var cols = _cols_with_front(original, batch_id)
			if cols == null:
				return false
			if not _supply.replace_live_columns(cols):
				return false
			var r = _slots.select_front_batch(_supply, target_col)
			if not r.get("ok", false):
				# The failing stage partially mutated (supply reorder happened);
				# unwind the supply reload here so the transaction runner's own
				# rollback sees the pre-apply state.
				_supply.replace_live_columns(original)
				return false
			placed_slot[0] = int(r.get("slot", -1))
			return true,
		"rollback": func():
			# Restore exact prior supply + free the placed slot if any (leaves
			# no orphan sixth-slot batch on a later transaction failure).
			_supply.replace_live_columns(original)
			if placed_slot[0] != -1:
				_slots.free_slot_if_idle(placed_slot[0]),
	}

# ------------------------------------------------------------ Tornado ----

func present_colors() -> Array:
	var seen := {}
	var out: Array = []
	for i in range(_board.get_cell_count()):
		if _board.get_cell_state(i) == BoardState.CellState.ACTIVE:
			var c = _board.get_color_id(i)
			if not seen.has(c):
				seen[c] = true
				out.append(c)
	return out

## M46 RM003: present_colors() is non-empty exactly when some cell is ACTIVE (VOID cells are
## CLEARED); a native byte search, not a per-cell script loop, for yes/no hints.
func has_present_color() -> bool:
	return _board.get_cell_states_copy().has(BoardState.CellState.ACTIVE)

## Atomic multi-system purge of one color across BoardState + supply + idle
## slots. Owner in-flight law (M39 V03, F-M39-V02-006): Tornado must reconcile
## selected-color committed/in-flight assignments. The audited M25/M26/M19
## APIs do not currently expose a targeted per-color cancellation seam that
## unwinds claims + agents + committed slot work atomically. Adding that
## surgery is a follow-up in its own audited cycle (recorded in the V03 log).
## Interim honest behavior: the guard checks whether ANY in-flight assignment
## currently carries the SELECTED color; if so, Tornado fails closed and no
## state mutates — unrelated colors' work is preserved, and no charge/SB is
## consumed. This is strictly stronger than the V02 global-quiescence rule
## (it allows Tornado while other colors are in flight) while remaining
## identity-safe against active same-color work.
func tornado_stages(color) -> Array:
	# M39 V04 (F-M39-V03-001): Tornado works WITH selected-color in-flight work.
	# guard (read-only exact-identity preflight) -> claims (reversible targeted
	# M25/M26 detach, one identity at a time) -> board -> slots -> supply ->
	# finalize (irreversible agent cancel, only after every reversible stage).
	# Never a global scheduler/dispatcher reset; unrelated colors are untouched.
	var detached: Array = []              # scheduler detach entries (claims rolled back)
	var cleared_indices: Array = []       # board cells set CLEARED by this purge
	var purged_slots: Array = []          # {index, slot_state} detached slot objects
	var purged_draining: Array = []       # M52-C001-R02 draining records of the color
	var supply_before: Array = []         # exact prior supply for rollback
	var has_sched: bool = _scheduler != null and _scheduler.has_method("preflight_color_cancel")

	var stage_guard := {
		"apply": func():
			if _faulted("tornado_guard"):
				return false
			if not has_sched:
				return _inflight() == 0
			return _scheduler.preflight_color_cancel(int(color)),
		"rollback": func(): pass,
	}
	var stage_claims := {
		"apply": func():
			if not has_sched:
				return true
			for o in _scheduler.color_assignment_owners(int(color)):
				var e: Dictionary = _scheduler.detach_assignment(o)
				if e.is_empty():
					return false
				detached.append(e)
				if detached.size() == 1 and _faulted("tornado_cancel_one"):
					return false
			return not _faulted("tornado_claims"),
		"rollback": func():
			for i in range(detached.size() - 1, -1, -1):
				_scheduler.reattach_assignment(detached[i])
			detached.clear(),
	}
	var stage_board := {
		"apply": func():
			for i in range(_board.get_cell_count()):
				if _board.get_cell_state(i) == BoardState.CellState.ACTIVE and _board.get_color_id(i) == int(color):
					if _board.set_cell_state(i, BoardState.CellState.CLEARED):
						cleared_indices.append(i)
			return not _faulted("tornado_board"),
		"rollback": func():
			for i in cleared_indices:
				_board.set_cell_state(i, BoardState.CellState.ACTIVE)
			cleared_indices.clear(),
	}
	var stage_slots := {
		"apply": func():
			for si in range(_slots.get_slot_count()):
				if _slots.is_occupied(si) and _slots.get_color_id(si) == int(color):
					var r = _slots.purge_uncommitted_slot(si)
					if not r.get("ok", false):
						return false   # committed work still bound => cannot purge safely
					purged_slots.append({"index": si, "slot_state": r["slot_state"]})
			# M52-C001-R02: batches of this color that already released their physical slot
			# (draining, all claims rolled back by stage_claims) are purged too, so no
			# unschedulable capacity is stranded. Exact records kept for rollback.
			if _slots.has_method("purge_draining_color"):
				var dr = _slots.purge_draining_color(int(color))
				if not dr.get("ok", false):
					return false
				purged_draining.append_array(dr["records"])
			return not _faulted("tornado_slots"),
		"rollback": func():
			if not purged_draining.is_empty():
				_slots.restore_draining(purged_draining)
				purged_draining.clear()
			for i in range(purged_slots.size() - 1, -1, -1):
				_slots.restore_purged_slot(purged_slots[i]["index"], purged_slots[i]["slot_state"])
			purged_slots.clear(),
	}
	var stage_supply := {
		"apply": func():
			supply_before.clear()
			supply_before.append_array(_current_cols())
			var cols: Array = []
			for q in supply_before:
				var nq: Array = []
				for b in q:
					if b.get_color_id() != int(color):
						nq.append(b)
				cols.append(nq)
			if not _supply.replace_live_columns(cols):
				return false
			return not _faulted("tornado_supply"),
		"rollback": func():
			if not supply_before.is_empty():
				_supply.replace_live_columns(supply_before),
	}
	var stage_finalize := {
		"apply": func():
			if _faulted("tornado_finalize"):
				return false
			# Re-prove every detached agent is still cancellable BEFORE the first
			# irreversible cancel, so this stage is all-or-nothing.
			for e in detached:
				if not _scheduler.get_dispatcher_can_cancel(e):
					return false
			for e in detached:
				_scheduler.finalize_detached(e)
			detached.clear()
			return true,
		"rollback": func(): pass,
	}
	return [stage_guard, stage_claims, stage_board, stage_slots, stage_supply, stage_finalize]
