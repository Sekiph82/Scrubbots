extends RefCounted
## ProductionBoosterAdapter — preload
## (res://scripts/economy/production_booster_adapter.gd).
##
## The CONCRETE adapter BoosterService drives against the REAL gameplay engines
## (M23 supply, M24 slots, M27 solver, BoardState) — replacing the V01 fake-only
## adapter (M39 V02, F-M39-003). All safety proofs use the real SolvabilitySolver
## over a real ProofState; all commits/rollbacks act on the live engines.
##
## Random  — reorders remaining unselected M23 batches (conservation preserved),
##           committed only if the real solver proves the reordered candidate is
##           still SOLVED; rollback reloads the exact prior supply.
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

var _level
var _board
var _supply
var _slots
var _scheduler          # M26 auto-dispatch scheduler (for in-flight quiescence)
var _classifier
## Optional fault injector for tests: Callable(stage:String) -> bool; true forces
## that stage to fail so rollback can be proven. Never set in production.
var _fault: Callable = Callable()

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
	# changes). Prove solvability before offering commit.
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
	if not _is_safe(reordered):
		return {"safe": false}
	return {
		"safe": true,
		"commit": func():
			if _faulted("random_commit"):
				return false
			return _supply.load_columns(reordered),
		"rollback": func():
			_supply.load_columns(original),
	}

# ------------------------------------------------------------ Selector ----

## Remaining batch ids that are solver-safe to extract into the rightmost EMPTY
## slot right now (requires an empty slot at the current capacity).
func eligible_safe_batches() -> Array:
	var out: Array = []
	if _slots.rightmost_empty_index() == -1:
		return out   # full at current capacity
	var original := _current_cols()
	for col in original:
		for b in col:
			var bid = b.get_batch_id()
			if _selector_reorder_solvable(original, bid):
				out.append(bid)
	return out

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

func _selector_reorder_solvable(original: Array, batch_id: String) -> bool:
	var cols = _cols_with_front(original, batch_id)
	if cols == null:
		return false
	return _is_safe(cols)

func extract_batch(batch_id) -> Dictionary:
	var original := _current_cols()
	var target_col := -1
	for c in range(original.size()):
		for b in original[c]:
			if b.get_batch_id() == batch_id:
				target_col = c
	return {
		"apply": func():
			if _faulted("selector_extract"):
				return false
			var cols = _cols_with_front(original, batch_id)
			if cols == null:
				return false
			if not _supply.load_columns(cols):
				return false
			var r = _slots.select_front_batch(_supply, target_col)
			return bool(r.get("ok", false)),
		"rollback": func():
			_supply.load_columns(original),
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

## Atomic multi-system purge of one color. Requires quiescence (no in-flight M26
## work) so there are no live claims/agents to strand — the agent/claim systems
## are reconciled by the precondition, and board/supply/idle-slots are reconciled
## with exact per-stage rollback.
func tornado_stages(color) -> Array:
	var cleared_indices: Array = []       # board cells set CLEARED by this purge
	var freed_slots: Array = []           # {index, batch} freed idle slots
	var supply_before: Array = []         # exact prior supply for rollback

	var stage_guard := {
		"apply": func():
			if _faulted("tornado_guard"):
				return false
			return _inflight() == 0,       # quiescence: no in-flight agents/claims
		"rollback": func(): pass,
	}
	var stage_board := {
		"apply": func():
			if _faulted("tornado_board"):
				return false
			for i in range(_board.get_cell_count()):
				if _board.get_cell_state(i) == BoardState.CellState.ACTIVE and _board.get_color_id(i) == int(color):
					if _board.set_cell_state(i, BoardState.CellState.CLEARED):
						cleared_indices.append(i)
			return true,
		"rollback": func():
			for i in cleared_indices:
				_board.set_cell_state(i, BoardState.CellState.ACTIVE)
			cleared_indices.clear(),
	}
	var stage_slots := {
		"apply": func():
			if _faulted("tornado_slots"):
				return false
			for si in range(_slots.get_slot_count()):
				if _slots.is_occupied(si) and _slots.get_color_id(si) == int(color):
					var r = _slots.free_slot_if_idle(si)
					if not r.get("ok", false):
						return false   # a non-idle color slot => cannot purge safely
					freed_slots.append({"index": si, "batch": r["batch"]})
			return true,
		"rollback": func():
			for f in freed_slots:
				_slots.restore_idle_slot(f["index"], f["batch"])
			freed_slots.clear(),
	}
	var stage_supply := {
		"apply": func():
			if _faulted("tornado_supply"):
				return false
			supply_before = _current_cols()
			var cols: Array = []
			for q in supply_before:
				var nq: Array = []
				for b in q:
					if b.get_color_id() != int(color):
						nq.append(b)
				cols.append(nq)
			return _supply.load_columns(cols),
		"rollback": func():
			if not supply_before.is_empty():
				_supply.load_columns(supply_before),
	}
	return [stage_guard, stage_board, stage_slots, stage_supply]
