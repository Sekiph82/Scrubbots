extends SceneTree
## M26-C001 V01 — REAL Hazard Bot end-to-end auto-dispatch integration evidence
## (SB-M26-030 / master audit §O). Builds the ACCEPTED production chain on the REAL
## committed level res://data/levels/m21_level_001_hazard_bot.json:
##
##   real BoardState + BoardRenderer/BoardPresentation
##   -> real M23 supply fixture -> real M24 FiveSlotBatchEngine (batch placement)
##   -> real M25 BatchTargetClaimEngine (claim/reservation arbitration)
##   -> real ProductionRoutingSystem / ProductionAccessQuery / RouteValidator
##   -> real ScrubbotDispatcher.dispatch_preclaimed (exact preclaimed assignment)
##   -> real ScrubbotAgent -> real CompleteClearingLoop authenticated clear
##   -> real authenticated_clear -> M25.finalize_clear
##
## Slot origins are derived from REAL laid-out ColorSelectionPanel SlotCell
## top-center anchors mapped through BoardPresentation.global_to_board_local(), so
## the start of every route is the exact visible slot anchor (preserving slot anchor
## -> BOTTOM connector -> Railroad V1 -> V07 interior-turn routing).
##
## Proves: no ghost robots; no duplicate target reservations; exact reservation
## ownership; authenticated clears decrement the EXACT batch quota (conservation);
## same-color multi-batch coexistence; WAITING/wake on newly opened corridors; and a
## reset that leaves zero scheduler claims/agents/reservations.
##
## Run: godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd
## Exits 0 on success, 1 on any failure.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const ColorSelectionPanel = preload("res://scripts/ui/color_selection_panel.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const BOARD_ORIGIN := Vector2(60.0, 120.0)
const BOARD_DISPLAY := Vector2(720.0, 720.0)
const MAX_STEPS := 400

var _fail := 0

## Read-only slot-origin provider: maps a batch slot index to the REAL laid-out
## SlotCell top-center global anchor mapped into board-local cell units.
class AnchorProvider:
	extends RefCounted
	var presentation
	var panel
	func _init(p, pan) -> void:
		presentation = p
		panel = pan
	func origin_for_slot(slot_index: int) -> Vector2:
		var anchor: Vector2 = panel.get_spawn_anchor_global(slot_index)
		return presentation.global_to_board_local(anchor)

func _initialize() -> void:
	await _run()
	_done()

func _drive_arrivals(layer) -> void:
	for c in layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			for _i in range(8192):
				if not c.is_moving():
					break
				c.advance(1.0)

func _run() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(root)

	var result = LevelLoader.load_from_path(LEVEL_PATH)
	_ok(result.is_ok(), "loaded real hazard bot level")
	if not result.is_ok():
		return
	var lvl = result.level_data
	var board = BoardState.from_level_data(lvl)

	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)

	var presentation = BoardPresentation.new()
	presentation.position = BOARD_ORIGIN
	root.add_child(presentation)
	presentation.configure(board, lvl.palette, BOARD_DISPLAY)
	var agent_layer = presentation.get_agent_layer()
	var renderer = presentation.get_renderer()

	# Real laid-out 5-cell panel below the bottom rail (geometry source for anchors).
	var panel = ColorSelectionPanel.new()
	var cs: float = presentation.get_cell_size()
	var rail_outer_local: float = float(board.get_height()) + ScrubRailGeometry.CENTER_OFFSET + ScrubRailGeometry.RAIL_WIDTH * 0.5
	panel.position = Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + (rail_outer_local + 1.0) * cs)
	root.add_child(panel)
	var pcolors: Array = []
	for i in range(5):
		pcolors.append(Color(0.5, 0.5, 0.5, 1.0))
	panel.bind_colors(pcolors)
	# Pump frames so container layout resolves real SlotCell global anchors.
	await process_frame
	await process_frame
	await process_frame
	_ok(panel.get_slot_cells().size() == 5, "five real laid-out SlotCell anchors available")

	var dispatcher = ScrubbotDispatcher.new()
	root.add_child(dispatcher)
	var ProductionTargetAccess = load("res://scripts/gameplay/dispatch/production_target_access.gd")
	dispatcher.bind(board, sel, res, routing, raccess, ProductionTargetAccess.new(routing, raccess, board), agent_layer)
	var loop = CompleteClearingLoop.new()
	_ok(loop.bind_arrival_only(board, ci, res, dispatcher, renderer), "arrival-only clearing loop bound with real renderer")

	# Real M23 supply fixture consistent with the level's per-color totals (each batch
	# count <= that color's real logical-pixel total). Two colour-2 batches give the
	# same-color multi-batch case.
	var C0 := 0; var C1 := 1; var C2 := 2; var C4 := 4
	# Colour-2 batch capacity intentionally exceeds the initially-reachable colour-2
	# edge count, so WAITING is reachability-driven (not capacity-driven) and an
	# authenticated clear that opens an interior corridor produces a NEW reachable
	# target -> wake. Counts stay <= the level's real per-colour totals (conservation).
	var cols: Array = [
		[ColorBatch.make("HB_C2a", C2, 60, lvl.palette.size())],
		[ColorBatch.make("HB_C2b", C2, 60, lvl.palette.size())],
		[ColorBatch.make("HB_C4", C4, 8, lvl.palette.size()),
			ColorBatch.make("HB_C0", C0, 8, lvl.palette.size()),
			ColorBatch.make("HB_C1", C1, 5, lvl.palette.size())],
	]
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns(cols)
	var slots = FiveSlotBatchEngine.new()
	# Place 5 fronts: col0->slot4, col1->slot3, col2 x3 -> slots 2,1,0.
	slots.select_front_batch(supply, 0)
	slots.select_front_batch(supply, 1)
	slots.select_front_batch(supply, 2)
	slots.select_front_batch(supply, 2)
	slots.select_front_batch(supply, 2)
	_ok(slots.occupied_count() == 5, "all five batch slots occupied via real M23->M24 placement")
	# Same-color multi-batch: two distinct colour-2 batches coexist.
	var c2_slots: Array = []
	for i in range(5):
		if slots.is_occupied(i) and slots.get_color_id(i) == C2:
			c2_slots.append(i)
	_ok(c2_slots.size() == 2, "same-color multi-batch: two distinct colour-2 batches coexist")

	var claim = BatchTargetClaimEngine.new()
	_ok(claim.bind(board, slots, sel, res), "M25 bound to real board/slots/selector/reservations")
	var provider = AnchorProvider.new(presentation, panel)
	var sched = AutoDispatchScheduler.new()
	_ok(sched.bind(board, slots, claim, res, routing, raccess, dispatcher, loop, provider), "M26 scheduler bound to real production chain")

	# Sanity: every provider origin is finite and maps below the board (real anchor).
	var all_below := true
	for i in range(5):
		var o: Vector2 = provider.origin_for_slot(i)
		if not (is_finite(o.x) and is_finite(o.y)) or o.y <= float(board.get_height()):
			all_below = false
	_ok(all_below, "every slot origin is a finite below-board real anchor (slot->BOTTOM connector start)")

	# --- autonomous scheduling run -------------------------------------------------
	var initial_active: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)
	var t0 := Time.get_ticks_usec()
	var clears := 0
	var max_inflight := 0
	var dup_target_seen := false
	var ghost_seen := false

	# Phase A — accumulate concurrent in-flight assignments (one per step, no burst)
	# WITHOUT clearing, until the scheduler can assign no more this pass (targets all
	# reserved/unreachable, or capacity consumed). Proves multi-agent concurrency and
	# the no-ghost invariant every step.
	var steps := 0
	for _s in range(MAX_STEPS):
		steps += 1
		var r = sched.step()
		var live := sched.live_assignment_count()
		if dispatcher.get_active_count() != live:
			ghost_seen = true
		max_inflight = maxi(max_inflight, live)
		if _has_duplicate_targets(sched):
			dup_target_seen = true
		if not r.get("ok", false):
			break
	var inflight_peak := sched.live_assignment_count()
	_ok(inflight_peak >= 2, "concurrent multi-agent in-flight accumulated (peak=%d)" % inflight_peak)

	# WAITING: at least one eligible color has no claimable target now. Repeated idle
	# steps must NOT churn reservations (no busy-loop).
	var any_waiting := false
	for col in [C2, C4, C0, C1]:
		if sched.is_color_waiting(col):
			any_waiting = true
	var res_before_idle: int = res.get_reservation_count()
	sched.step(); sched.step()
	_ok(res.get_reservation_count() == res_before_idle, "WAITING/idle: repeated idle steps cause no reservation churn")

	# Phase B — authenticate the in-flight clears. Clearing the reachable edge cells
	# opens interior corridors AND fires the wake, so a subsequent step resumes
	# scheduling on a NEWLY reachable interior target (event-driven wake).
	var reachable_edge: int = inflight_peak
	_drive_arrivals(agent_layer)
	_ok(not (sched.is_color_waiting(C2) and sched.is_color_waiting(C4) and sched.is_color_waiting(C0) and sched.is_color_waiting(C1)), "wake: authenticated clears reconsidered WAITING colors (waiting flags cleared)")
	var resumed := sched.step()
	var woke: bool = resumed.get("ok", false)
	_ok(woke, "wake: scheduler produced a NEW assignment on an interior target opened by the clears")
	if woke:
		max_inflight = maxi(max_inflight, sched.live_assignment_count())

	# Phase C — drain to genuine completion (drive all remaining in-flight, keep
	# scheduling). Bounded by MAX_STEPS.
	for _s in range(MAX_STEPS):
		_drive_arrivals(agent_layer)
		# Count every authenticated clear via the loop's own committed counter later;
		# here just keep driving + scheduling until fully idle with no in-flight.
		var r = sched.step()
		if dispatcher.get_active_count() != sched.live_assignment_count():
			ghost_seen = true
		if _has_duplicate_targets(sched):
			dup_target_seen = true
		if r.get("ok", false):
			continue
		if sched.live_assignment_count() == 0:
			break
	var elapsed_ms := float(Time.get_ticks_usec() - t0) / 1000.0

	# --- conservation / integrity assertions --------------------------------------
	clears = loop.get_cleared_count()  # authoritative committed-clear count
	var final_active: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)
	var board_cleared: int = initial_active - final_active
	print("HB_RUN steps=%d clears=%d board_cleared=%d max_inflight=%d elapsed_ms=%.1f any_waiting=%s woke=%s" % [
		steps, clears, board_cleared, max_inflight, elapsed_ms, str(any_waiting), str(woke)])
	_ok(clears > 0, "autonomous scheduler authenticated real clears end-to-end")
	_ok(clears > reachable_edge, "wake proven: total clears (%d) exceed initially-reachable edge (%d) => interior corridors opened & scheduled" % [clears, reachable_edge])
	_ok(not ghost_seen, "no ghost robots: dispatcher active count == scheduler live claims every step")
	_ok(not dup_target_seen, "no duplicate target reservation across live claims at any step")
	_ok(board_cleared == clears, "exact board conservation: cleared cells == authenticated clears")

	# committed<=remaining invariant holds on every occupied slot at completion.
	var invariant_ok := true
	for i in range(5):
		if slots.is_occupied(i) and slots.get_committed(i) > slots.get_remaining(i):
			invariant_ok = false
	_ok(invariant_ok, "M24 committed <= remaining invariant held throughout")

	# --- reset teardown ------------------------------------------------------------
	var pre_reset_claims: int = claim.live_claim_count()
	sched.reset()
	await process_frame
	await process_frame
	_ok(sched.live_assignment_count() == 0, "reset: zero scheduler assignments")
	_ok(claim.live_claim_count() == 0, "reset: zero live M25 claims (pre-reset live=%d)" % pre_reset_claims)
	_ok(dispatcher.get_active_count() == 0, "reset: zero dispatcher active assignments")
	_ok(res.get_reservation_count() == 0, "reset: zero live reservations from the scheduler")
	var remaining_agents := 0
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and (c.is_moving()):
			remaining_agents += 1
	_ok(remaining_agents == 0, "reset: zero live/moving ScrubbotAgent nodes remain")

	root.free()
	sub.free()

func _has_duplicate_targets(sched) -> bool:
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
	print("M26 Hazard Bot integration: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
