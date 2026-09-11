extends SceneTree
## M20-C001 V09 — frame-aware exact-evidence smoke. Proves the GC/frame cases: the
## single-M20-owner claim releases after the owner loop is genuinely freed, the old
## M20 transaction signal callback is gone while a pre-existing diagnostic listener
## stays independent, a fresh loop then contributes exactly one M20 callback, and a
## configured renderer truly destroyed before arrival clears nothing. Validation-
## only (production immutable). Must exit 0.
##
## Run:  godot --headless --path . -s res://tests/m20_v09_lifecycle_smoke.gd

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

func _board():
	var b = RoutingLabScenarios.make_open_board(22, 22)
	b.set_cell_state(b.get_cell_index(11, 11), BoardState.CellState.ACTIVE)
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

func _conn(d) -> int:
	return d.assignment_arrived.get_connections().size()

func _ok(cond, msg):
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V09 lifecycle smoke")
	# §3 owner-GC claim release + old-callback-absent + diagnostic independent.
	var b1 = _board()
	var color: int = b1.get_color_id(b1.get_cell_index(11, 11))
	var bd1 = _bound_dispatcher(b1)
	var diag := func(_o, _t, _c, _a): pass
	bd1["d"].assignment_arrived.connect(diag)
	var l1 = CompleteClearingLoop.new()
	_ok(l1.bind(b1, _slots(color), bd1["candidates"], bd1["reservations"], bd1["d"]), "owner loop binds (with pre-existing diagnostic)")
	_ok(_conn(bd1["d"]) == 2, "diagnostic + owner M20 callback = 2 connections")
	var wr = weakref(l1)
	l1 = null
	await process_frame
	await process_frame
	_ok(wr.get_ref() == null, "no strong cycle: owner loop genuinely freed")
	_ok(bd1["d"].assignment_arrived.is_connected(diag), "diagnostic listener still independent/present")
	_ok(_conn(bd1["d"]) == 1, "old M20 transaction callback is gone (only diagnostic remains)")
	var l3 = CompleteClearingLoop.new()
	_ok(l3.bind(b1, _slots(color), bd1["candidates"], bd1["reservations"], bd1["d"]), "fresh loop binds after owner GC")
	_ok(_conn(bd1["d"]) == 2, "fresh loop contributes exactly one M20 transaction callback")
	l3 = null
	bd1["d"].assignment_arrived.disconnect(diag)

	# §5 configured renderer truly destroyed after dispatch, before arrival.
	var b5 = _board()
	var t5: int = b5.get_cell_index(11, 11)
	var c5: int = b5.get_color_id(t5)
	var bd5 = _bound_dispatcher(b5)
	var renderer = BoardRenderer.new(); root.add_child(renderer)
	renderer.configure(b5, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(200, 200))
	var loop = CompleteClearingLoop.new()
	_ok(loop.bind(b5, _slots(c5), bd5["candidates"], bd5["reservations"], bd5["d"], renderer), "healthy renderer bind")
	var res = loop.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	_ok(res.success, "dispatched a live assignment")
	renderer.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(renderer), "configured renderer truly destroyed before arrival")
	for _i in range(128):
		if not res.agent.is_moving():
			break
		res.agent.advance(1.0)
	_ok(b5.get_cell_state(t5) == BoardState.CellState.ACTIVE and loop.get_cleared_count() == 0, "truly-freed configured renderer -> arrival clears nothing")
	_ok(bd5["reservations"].get_owner(t5) == res.owner_id and bd5["d"].has_owner(res.owner_id), "reservation+assignment held until reset")
	loop.reset()
	_ok(bd5["d"].get_active_count() == 0, "reset cleans the held assignment")

	print("M20 V09 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
