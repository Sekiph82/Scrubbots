extends RefCounted
## ProofKernel — M27 legal transition kernel (SB-M27-001..012). Preload this script
## (res://scripts/gameplay/solver/proof_kernel.gd); do not rely on global class_name.
##
## The kernel is the ONLY bridge between a detached ProofState and the ACCEPTED
## gameplay-domain engines. It NEVER invents a simplified notion of reachability, slot,
## claim or supply behavior (master prompt "core architectural rule", audit §B): it
## reconstructs isolated instances of the real M24 FiveSlotBatchEngine, M25
## BatchTargetClaimEngine + TargetSelector + ReservationState + ColorCandidateIndex, and
## the real ProductionRoutingSystem/ProductionAccessQuery/RouteValidator/ProductionTargetAccess
## stack from a ProofState, then drives them exactly as the runtime would.
##
## Two operations:
##  - apply_placement(state, column): select the column's FRONT batch through the real
##    M23->M24 transaction (rightmost-empty placement; full-slot rejection consumes no
##    supply), then run the serial clear kernel to quiescence.
##  - quiesce(state): run the serial clear kernel to quiescence with no placement.
##
## Wave clear kernel (M52-C001-R01; supersedes the M27 color-serialized kernel): runtime
## dispatch is now one parallel wave per cadence — at most one exact-slot M25 claim per
## eligible occupied slot, each from that slot's own origin, same-color slots independent
## (OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01). The kernel applies exactly that
## lane policy: one wave of exact-slot claims against the pre-wave board, then the wave's
## authenticated-equivalent clears (BoardState ACTIVE->CLEARED -> candidate sync ->
## reservation resolve -> M25.finalize_clear updating M24 quota exactly as successful
## finalization would), repeated to quiescence. WAITING is per slot and every clear wakes
## all lanes, mirroring M26. It never uses ScrubbotAgent animation timing.
##
## Proof/runtime relationship (documented, not overclaimed): claim semantics (per-slot
## origin access, TargetSelector order, reservation uniqueness) are identical to runtime;
## what the kernel fixes is one TIMING of clears (all of a wave's clears land before the
## next wave). Runtime travel time may let later waves claim before earlier clears land,
## selecting different same-color cells. Consequences:
##   - DEADLOCK/LOST soundness: from a quiescent state no clear happens before the next
##     successful claim, and claims are identical, so "no future progress" in the kernel is
##     exactly "no future progress" at runtime — the classifier cannot report a false LOST.
##   - SOLVED is a proof for this canonical timing only; production admission additionally
##     requires the owner click sequence to reach WON through the REAL production runtime
##     (tests/m52_owner_supply_plans.gd, tests/m52_r01_parallel_runtime.gd).

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")

## Below-board start clearance beyond the rail center offset (logical cells). A start at
## y = height + this is a legal outside-start that reaches the Railroad V1 bottom entry.
const ORIGIN_BELOW := 4.0

## Bounded guard against a pathological non-terminating clear loop (never expected —
## every clear strictly reduces ACTIVE cells — but fail-closed rather than hang).
const MAX_CLEARS_GUARD := 4000000

# ---------------------------------------------------------------- public API ---

## Run the serial clear kernel from `state` (no placement). Returns
## {"ok":true, "state":ProofState, "clears":int} or {"ok":false, "error":...}.
func quiesce(state) -> Dictionary:
	var live := _build_live(state)
	if live.is_empty():
		return {"ok": false, "error": "build_failed"}
	var clears := _run_to_quiescence(live)
	if clears < 0:
		return {"ok": false, "error": "kernel_incoherent"}
	return {"ok": true, "state": _read_back(state, live), "clears": clears}

## Place the FRONT batch of `column` through the real M23->M24 transaction, then quiesce.
## Returns {"ok":true, "state":ProofState, "clears":int, "placed_slot":int,
## "placed":{color,count}} on a legal placement; {"ok":false, "error":...} when the
## placement is illegal (all slots occupied, empty/invalid column, or supply rejects it)
## — in which case no supply is consumed, exactly the runtime rule.
func apply_placement(state, column: int) -> Dictionary:
	var live := _build_live(state)
	if live.is_empty():
		return {"ok": false, "error": "build_failed"}
	var front = live.supply.get_front(column)
	var place = live.slots.select_front_batch(live.supply, column)
	if not place.get("ok", false):
		return {"ok": false, "error": place.get("error", "placement_failed")}
	var placed_slot: int = int(place["slot"])
	var placed_color: int = front.get_color_id()
	var placed_count: int = front.get_robot_count()
	var clears := _run_to_quiescence(live)
	if clears < 0:
		return {"ok": false, "error": "kernel_incoherent"}
	return {"ok": true, "state": _read_back(state, live), "clears": clears,
		"placed_slot": placed_slot, "placed": {"color": placed_color, "count": placed_count}}

# ------------------------------------------------------- live reconstruction ---

## Reconstruct isolated live gameplay-domain engines from a ProofState. Returns a
## Dictionary bundle, or {} on malformed input.
func _build_live(state) -> Dictionary:
	if not (state is ProofState) or state.level == null:
		return {}
	var level = state.level
	var board = BoardState.from_level_data(level)
	var count: int = board.get_cell_count()
	if state.active.size() != count:
		return {}
	# Apply the CLEARED mask through the real BoardState mutator.
	for i in range(count):
		if state.active[i] == ProofState.CLEARED_BYTE:
			if not board.set_cell_state(i, BoardState.CellState.CLEARED):
				return {}
	var ci = ColorCandidateIndex.create()
	if not ci.bind(board):
		return {}
	var res = ReservationState.new()
	if not res.bind(board):
		return {}
	var sel = TargetSelector.create()
	if not sel.bind(board, ci, res):
		return {}
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	# Reconstruct the five M24 slots exactly (committed is 0 at every quiescent proof
	# state, so `remaining` is the whole accounting; initial == remaining is future-
	# behavior-equivalent — nothing reads initial_count for future behavior).
	var slots = FiveSlotBatchEngine.new()
	# Reconstruct at the state's active capacity (M39 V03, F-M39-V02-002). A
	# 6-slot proof state must reconstruct into a 6-slot engine so future-behavior
	# solver transitions see slot 5 exactly as the runtime would.
	var cap: int = int(state.capacity) if state.capacity != null else ProofState.SLOT_COUNT
	if cap == FiveSlotBatchEngine.MAX_CAPACITY:
		slots.grow_to_sixth()
	var max_seq := 0
	for i in range(cap):
		if i >= state.slots.size():
			break
		var sd = state.slots[i]
		if sd == null:
			continue
		var remaining: int = int(sd["remaining"])
		var occ = SlotBatchState.make_occupied(String(sd["batch_id"]), int(sd["color"]),
			remaining, int(sd["seq"]))
		if occ == null:
			return {}
		if String(sd["state"]) == SlotBatchState.WAITING:
			occ.set_state(SlotBatchState.WAITING)
		slots._slots[i] = occ
		max_seq = maxi(max_seq, int(sd["seq"]))
	slots._next_sequence = maxi(int(state.next_seq), max_seq + 1)
	var claim = BatchTargetClaimEngine.new()
	if not claim.bind(board, slots, sel, res):
		return {}
	# Reconstruct the M23 supply queues (front-only FIFO preserved).
	var supply = BatchSupplyEngine.create(state.column_count, state.preview_depth)
	if supply == null:
		return {}
	var cols: Array = []
	for q in state.supply:
		var qc: Array = []
		for b in q:
			var cb = ColorBatch.make(String(b["id"]), int(b["color"]), int(b["count"]), state.palette_size)
			if cb == null:
				return {}
			qc.append(cb)
		cols.append(qc)
	if not supply.load_candidate(cols, 0, state.palette_size):
		return {}
	return {"level": level, "board": board, "ci": ci, "res": res, "sel": sel,
		"routing": routing, "raccess": raccess, "slots": slots, "claim": claim,
		"supply": supply, "w": board.get_width(), "h": board.get_height()}

# --------------------------------------------------------- serial clear kernel --

## Wave kernel (M52-C001-R01, mirrors the production M26 parallel wave): each iteration
## is ONE dispatch wave — every eligible slot (occupied, capacity > 0, not WAITING on its
## current batch), in ascending placement sequence then slot index, makes at most one
## exact-slot M25 claim using ITS OWN below-board origin/access, all against the same
## pre-wave board (reservations keep the wave's targets unique). The wave's clears are then
## applied (authenticated-equivalent, claim order). A clear wakes every WAITING lane.
## Repeats until a wave claims nothing. Returns the number of clears, or -1 if an
## authenticated-clear transition unexpectedly failed (incoherent).
func _run_to_quiescence(live: Dictionary) -> int:
	var clears := 0
	var waiting: Dictionary = {}   # slot -> batch_id WAITING on its current batch
	while true:
		var claims: Array = []
		for slot in _eligible_slots(live.slots, waiting):
			var origin: Vector2 = _origin_for_slot(slot, live.w, live.h, live.slots.get_slot_count())
			var access = ProductionTargetAccess.new(live.routing, live.raccess, live.board, origin)
			var batch_id: String = live.slots.get_batch_id(slot)
			var claim: Dictionary = live.claim.claim_for_slot(slot, access)
			if claim.get("ok", false):
				claims.append(claim)
			elif claim.get("waiting", false):
				waiting[slot] = batch_id
		if claims.is_empty():
			break
		for claim in claims:
			if not _apply_clear(live, claim):
				return -1
			clears += 1
			if clears > MAX_CLEARS_GUARD:
				return -1
		waiting.clear()  # clears can open corridors -> wake all WAITING lanes
	return clears

## Eligible lanes, exactly the production M26 wave order: occupied slots with dispatch
## capacity > 0 not WAITING on their current batch, ascending placement sequence then
## physical slot index (deterministic; never Dictionary iteration order).
func _eligible_slots(slots, waiting: Dictionary) -> Array:
	var lanes: Array = []
	for i in range(slots.get_slot_count()):
		if not slots.is_occupied(i):
			continue
		if slots.get_capacity(i) <= 0:
			continue
		if waiting.get(i, "") == slots.get_batch_id(i):
			continue
		lanes.append(i)
	lanes.sort_custom(func(a, b):
		var sa: int = slots.get_placement_sequence(a)
		var sb: int = slots.get_placement_sequence(b)
		if sa != sb:
			return sa < sb
		return a < b)
	return lanes

## Apply one authenticated-equivalent clear transition synchronously, exactly mirroring
## CompleteClearingLoop's committed order (BoardState -> candidate -> reservation ->
## M25.finalize_clear). Returns false if any authoritative step fails (incoherent kernel).
func _apply_clear(live: Dictionary, claim: Dictionary) -> bool:
	var target: int = int(claim["target"])
	var owner: int = int(claim["owner_id"])
	var claim_id = claim["claim_id"]
	if not live.board.set_cell_state(target, BoardState.CellState.CLEARED):
		return false
	if not _bool_true(live.ci.sync_cell(target)):
		return false
	if not _bool_true(live.res.resolve_arrival(target, owner)):
		return false
	if not _bool_true(live.claim.finalize_clear(claim_id)):
		return false
	return true

# ------------------------------------------------------------- read-back -------

## Read a fresh quiescent ProofState back out of the live engines. committed is 0 at
## quiescence (every claim was finalized), so the slot accounting is exactly `remaining`.
func _read_back(template, live: Dictionary):
	var s = ProofState.new()
	s.level = template.level
	s.column_count = template.column_count
	s.preview_depth = template.preview_depth
	s.palette_size = template.palette_size
	# Board mask.
	var count: int = live.board.get_cell_count()
	s.active = PackedByteArray()
	s.active.resize(count)
	for i in range(count):
		s.active[i] = ProofState.ACTIVE_BYTE if live.board.get_cell_state(i) == BoardState.CellState.ACTIVE else ProofState.CLEARED_BYTE
	# Supply (remaining FIFO per column) from the non-player-facing debug snapshot.
	var dbg: Dictionary = live.supply.debug_snapshot()
	s.supply = []
	for col in dbg["columns"]:
		var q: Array = []
		for b in col:
			q.append({"id": String(b["batch_id"]), "color": int(b["color_id"]), "count": int(b["robot_count"])})
		s.supply.append(q)
	# Slots. Read back the ACTIVE capacity (5 or 6) so a 6-slot readout carries
	# the sixth slot's occupancy (M39 V03, F-M39-V02-002).
	s.capacity = live.slots.get_slot_count()
	s.slots = []
	for i in range(live.slots.get_slot_count()):
		if not live.slots.is_occupied(i):
			s.slots.append(null)
		else:
			s.slots.append({"batch_id": live.slots.get_batch_id(i), "color": live.slots.get_color_id(i),
				"remaining": live.slots.get_remaining(i), "seq": live.slots.get_placement_sequence(i),
				"state": live.slots.get_state(i)})
	s.next_seq = live.slots._next_sequence
	return s

# -------------------------------------------------------------- origins --------

## Deterministic below-board slot origin (a legal outside-start for Railroad V1). Five
## lanes spread across the board width, all finite and below the bottom rail, so the exact
## slot anchor semantics (slot -> BOTTOM connector -> rail -> interior turns) hold headless
## without any UI layout. Reachability via the rail is lane-robust, so this is a faithful
## legal start for every slot.
## Below-board slot origin lane math uses the CURRENT active capacity so at
## capacity 6 the lanes spread across six rather than five slots (M39 V03,
## F-M39-V02-002). Signature is unchanged; the kernel passes the live capacity
## via the `cap` argument.
func _origin_for_slot(slot: int, w: int, h: int, cap: int = ProofState.SLOT_COUNT) -> Vector2:
	var lane_x: float = (float(slot) + 0.5) * float(w) / float(cap)
	return Vector2(lane_x, float(h) + ORIGIN_BELOW)

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true
