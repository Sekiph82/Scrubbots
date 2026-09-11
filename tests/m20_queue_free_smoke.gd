extends SceneTree
## M20-C001 V02 — dedicated deferred-destruction smoke (F-M20-STRICT-007/§14).
##
## The synchronous root runner (tests/run_tests.gd) cannot prove that a
## queue_free()'d Scrubbot is actually destroyed after a frame. This tiny
## headless script builds a real production M20 bundle, drives one arrival to a
## committed clear (which finalizes via ScrubbotDispatcher.finalize_arrival ->
## agent.queue_free()), proves the agent is queued-for-deletion immediately, then
## processes real SceneTree frames and proves the agent instance is gone with no
## orphan child left under the dispatcher.
##
## Run:  godot --headless --path . -s res://tests/m20_queue_free_smoke.gd
## Exits 0 on success, 1 on any failure.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")

func _initialize() -> void:
	var ok := true
	var board = RoutingLabScenarios.make_open_board(20, 20)
	var target: int = board.get_cell_index(10, 10)
	board.set_cell_state(target, BoardState.CellState.ACTIVE)
	var color: int = board.get_color_id(target)

	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var dispatcher = ScrubbotDispatcher.new(); root.add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access)

	var slots = SlotSystem.new()
	slots.configure([color, color, color, color, color], 256)
	var loop = CompleteClearingLoop.new()
	if not loop.bind(board, slots, candidates, reservations, dispatcher):
		_done(false, "bind failed")
		return

	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	if not res.success:
		_done(false, "activation did not dispatch")
		return
	var agent = res.agent
	# Drive to arrival -> synchronous authenticated clear + finalize (queue_free).
	for _i in range(128):
		if not agent.is_moving():
			break
		agent.advance(1.0)

	if loop.get_cleared_count() != 1:
		_done(false, "arrival did not clear (outcome=%s)" % str(loop.get_last_outcome()))
		return
	# Immediately after finalize the agent must be queued for deletion, still valid.
	if not is_instance_valid(agent):
		_done(false, "agent freed synchronously (should be queue_free deferred)")
		return
	if not agent.is_queued_for_deletion():
		_done(false, "agent not queued for deletion after finalize")
		return

	# Process real frames so the deferred free actually completes.
	await process_frame
	await process_frame

	if is_instance_valid(agent):
		_done(false, "agent still valid after frames (deferred free did not complete)")
		return
	if dispatcher.get_child_count() != 0:
		_done(false, "orphan child remains under dispatcher after free")
		return
	_done(true, "deferred destruction verified: agent freed after one frame, no orphan child")

func _done(success: bool, msg: String) -> void:
	print("M20 queue_free smoke: %s — %s" % ["PASS" if success else "FAIL", msg])
	quit(0 if success else 1)
