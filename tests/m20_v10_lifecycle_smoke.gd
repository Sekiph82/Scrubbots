extends SceneTree
## M20-C001 V10 — frame-aware closure smoke. (A) a configured renderer truly freed
## after dispatch but before arrival clears nothing while the exact reservation
## (both directions), dispatcher assignment and raw target candidate are preserved;
## (B) a real assignment held via an intentional failed preflight is cleaned by an
## authorized loop reset across real frames — agent no longer valid, no orphan
## child under the dispatcher, the original reservation pair gone, and an unrelated
## sentinel reservation/cell intact. Validation-only. Must exit 0.
##
## Run:  godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")

var _fail: bool = false

func _board(cells):
	var b = RoutingLabScenarios.make_open_board(22, 22)
	for c in cells:
		b.set_cell_state(b.get_cell_index(int(c.x), int(c.y)), BoardState.CellState.ACTIVE)
	return b

func _bound_dispatcher(board):
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var ra = ProductionAccessQuery.new(board)
	var sa = ProductionTargetAccess.new(routing, ra, board)
	var d = ScrubbotDispatcher.new(); root.add_child(d)
	d.bind(board, selector, reservations, routing, ra, sa)
	return {"d": d, "candidates": candidates, "reservations": reservations}

func _slots(color):
	var s = SlotSystem.new(); s.configure([color, color, color, color, color], 256); return s

func _ok(cond, msg):
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V10 lifecycle smoke")
	# (A) truly-freed configured renderer before arrival: preservation.
	var bA = _board([Vector2(11, 11)])
	var tA: int = bA.get_cell_index(11, 11)
	var cA: int = bA.get_color_id(tA)
	var bdA = _bound_dispatcher(bA)
	var renderer = BoardRenderer.new(); root.add_child(renderer)
	renderer.configure(bA, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(200, 200))
	var loop = CompleteClearingLoop.new()
	_ok(loop.bind(bA, _slots(cA), bdA["candidates"], bdA["reservations"], bdA["d"], renderer), "renderer bind")
	var resA = loop.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	_ok(resA.success, "dispatched an assignment")
	renderer.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(renderer), "configured renderer truly destroyed before arrival")
	for _i in range(128):
		if not resA.agent.is_moving():
			break
		resA.agent.advance(1.0)
	_ok(bA.get_cell_state(tA) == BoardState.CellState.ACTIVE and loop.get_cleared_count() == 0, "truly-freed renderer -> no clear")
	_ok(bdA["reservations"].get_owner(tA) == resA.owner_id and bdA["reservations"].get_target_for_owner(resA.owner_id) == tA, "reservation both directions preserved")
	_ok(bdA["d"].has_owner(resA.owner_id), "dispatcher assignment preserved")
	_ok(bdA["candidates"].get_candidates(cA, null).has(tA), "raw target candidate preserved")
	loop.reset()

	# (B) failed-preflight cleanup frame proof.
	var bB = _board([Vector2(11, 11), Vector2(13, 11)])
	var tB: int = bB.get_cell_index(11, 11)
	var cB: int = bB.get_color_id(tB)
	var sentinel: int = bB.get_cell_index(13, 11)
	var bdB = _bound_dispatcher(bB)
	var l2 = CompleteClearingLoop.new()
	_ok(l2.bind(bB, _slots(cB), bdB["candidates"], bdB["reservations"], bdB["d"]), "headless bind")
	var resB = l2.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	_ok(resB.success, "dispatched an assignment")
	# Hold it via an intentional failed preflight: disconnect loop, drive to arrived,
	# reserve an unrelated sentinel, then inject a wrong-owner tuple (rejected).
	bdB["d"].assignment_arrived.disconnect(l2._arrival_cb)
	for _i in range(128):
		if not resB.agent.is_moving():
			break
		resB.agent.advance(1.0)
	bdB["reservations"].reserve(sentinel, 9090)
	l2._on_assignment_arrived(resB.owner_id + 1, tB, cB, resB.agent) # wrong owner -> rejected
	_ok(l2.get_last_outcome() == CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "intentional preflight failure")
	_ok(bdB["d"].has_owner(resB.owner_id), "assignment still pending after failed preflight")
	bdB["d"].assignment_arrived.connect(l2._arrival_cb)
	var agentB = resB.agent
	var child_target: int = bdB["d"].get_child_count()
	l2.reset()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(agentB), "held agent no longer valid after reset + frames")
	_ok(bdB["d"].get_child_count() == 0, "no orphan child under dispatcher for that assignment")
	_ok(bdB["reservations"].get_owner(tB) == -1 and bdB["reservations"].get_target_for_owner(resB.owner_id) == -1, "original reservation pair gone")
	_ok(bdB["reservations"].get_owner(sentinel) == 9090, "unrelated sentinel reservation intact")
	_ok(bB.get_cell_state(sentinel) == BoardState.CellState.ACTIVE, "unrelated sentinel cell intact")

	print("M20 V10 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
