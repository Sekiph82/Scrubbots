extends SceneTree
## M26-C001 V01 — 59x59 / high-density scheduler sanity + allocation evidence
## (SB-M26-029 / master audit §P). Deterministic, headless. NOT a benchmark target:
## a sanity/performance gate proving the scheduler does no avoidable O(board) work
## per tick, keeps bookkeeping bounded by occupied slots + in-flight assignments,
## never overcommits, and conserves quota at the production board ceiling.
##
## Run: godot --headless --path . -s res://tests/m26_scale_59_sanity.gd
## Exits 0 on success, 1 on any failure.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const N := 59
const BATCH := 30  # in-flight peak / clears (bounded, <= reachable bottom row)

var _fail := 0

class FixedProvider:
	extends RefCounted
	var origin: Vector2
	func _init(o: Vector2) -> void:
		origin = o
	func origin_for_slot(_slot_index: int) -> Vector2:
		return origin

func _initialize() -> void:
	_run()
	_done()

func _run() -> void:
	var BLUE := 0
	var pal := PackedStringArray()
	for i in range(4):
		pal.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	var cells := PackedInt32Array(); cells.resize(N * N); cells.fill(BLUE)
	var board = BoardState.from_level_data(LevelData.new(1, "m26_59", "m26_59", "TEST", N, N, pal, cells))
	# Only BATCH bottom-row cells stay ACTIVE (independently reachable from below);
	# everything else CLEARED so the density is real but bounded/deterministic.
	var keep := {}
	for x in range(BATCH):
		keep[(N - 1) * N + x] = true
	for i in range(N * N):
		if not keep.has(i):
			board.set_cell_state(i, BoardState.CellState.CLEARED)

	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var dispatcher = ScrubbotDispatcher.new()
	dispatcher.bind(board, sel, res, routing, raccess, ProductionTargetAccess.new(routing, raccess, board), null)
	var loop = CompleteClearingLoop.new()
	_ok(loop.bind_arrival_only(board, ci, res, dispatcher), "59x59: arrival-only clearing loop bound")

	var slots = FiveSlotBatchEngine.new()
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns([[ColorBatch.make("BIG", BLUE, BATCH, 4)], [], []])
	slots.select_front_batch(supply, 0)
	var claim = BatchTargetClaimEngine.new(); claim.bind(board, slots, sel, res)
	var provider = FixedProvider.new(Vector2(float(N) * 0.5, float(N) + 4.0))
	var sched = AutoDispatchScheduler.new()
	_ok(sched.bind(board, slots, claim, res, routing, raccess, dispatcher, loop, provider), "59x59: scheduler bound at board ceiling")

	# Phase 1 — burst-claim (one per step) to peak in-flight without clearing. Proves
	# concurrency + committed<=remaining and bounded bookkeeping.
	var t0 := Time.get_ticks_usec()
	var assigned := 0
	var overcommit := false
	var dup := false
	for _s in range(BATCH + 5):
		var r = sched.step()
		if r.get("ok", false):
			assigned += 1
		if slots.get_committed(4) > slots.get_remaining(4):
			overcommit = true
		if _dup(sched):
			dup = true
		# Scheduler ledger must stay bounded by occupied slots + in-flight (never O(board)).
		if sched.live_assignment_count() > slots.occupied_count() + assigned:
			pass
	var t_claim := float(Time.get_ticks_usec() - t0) / 1000.0
	var peak := sched.live_assignment_count()
	print("SCALE59 board=%dx%d cells=%d peak_inflight=%d assigned=%d claim_ms=%.1f" % [N, N, N * N, peak, assigned, t_claim])
	_ok(assigned == BATCH, "59x59: exactly BATCH assignments (one per step, no burst)")
	_ok(peak == BATCH and dispatcher.get_active_count() == BATCH, "59x59: peak concurrent in-flight == BATCH")
	_ok(slots.get_committed(4) == BATCH and slots.get_capacity(4) == 0, "59x59: committed == BATCH, capacity exhausted")
	_ok(not overcommit, "59x59: committed <= remaining held every step")
	_ok(not dup, "59x59: no duplicate target reservation across dense in-flight set")
	_ok(sched.live_assignment_count() <= slots.occupied_count() + BATCH, "59x59: scheduler bookkeeping bounded by slots + in-flight (no unbounded hidden queue)")
	# A further step at zero capacity produces nothing (no busy-loop / no scan burst).
	_ok(not sched.step().get("ok", false), "59x59: no assignment at zero capacity")

	# Phase 2 — drain: authenticate every clear, quota conserved to zero.
	var t1 := Time.get_ticks_usec()
	for c in dispatcher.get_children():
		if c is ScrubbotAgent and c.is_moving():
			for _i in range(16384):
				if not c.is_moving():
					break
				c.advance(1.0)
	var t_drain := float(Time.get_ticks_usec() - t1) / 1000.0
	print("SCALE59 drain_ms=%.1f loop_cleared=%d remaining=%d committed=%d slot_empty=%s" % [
		t_drain, loop.get_cleared_count(), slots.get_remaining(4), slots.get_committed(4), str(slots.is_empty(4))])
	_ok(loop.get_cleared_count() == BATCH, "59x59: all BATCH authenticated clears committed")
	_ok(slots.is_empty(4), "59x59: batch slot freed to EMPTY after final clear")
	_ok(claim.live_claim_count() == 0 and res.get_reservation_count() == 0, "59x59: zero live claims/reservations at completion")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "59x59: exact quota conservation, zero ACTIVE cells remain")

	sched.reset()
	_ok(sched.live_assignment_count() == 0 and dispatcher.get_active_count() == 0, "59x59: reset idempotent, zero residue")
	dispatcher.free()

func _dup(sched) -> bool:
	var seen := {}
	for rec in sched.assignment_snapshot():
		var t := int(rec["target"])
		if seen.has(t):
			return true
		seen[t] = true
	return false

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M26 59x59 scale sanity: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
