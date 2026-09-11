extends SceneTree
## M20-C001 V08 — frame-aware final validation smoke. Covers the cases that need
## real SceneTree frames / true GC: single-M20-owner claim release after the owner
## loop is genuinely freed (with a no-strong-cycle-leak proof), a truly-freed
## explicit agent_parent, an explicit parent destroyed after a healthy bind but
## before dispatch, and a configured renderer truly destroyed before arrival.
## Validation-only (production is immutable). Must exit 0.
##
## Run:  godot --headless --path . -s res://tests/m20_v08_lifecycle_smoke.gd

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

func _dispatcher(board):
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var ra = ProductionAccessQuery.new(board)
	var sa = ProductionTargetAccess.new(routing, ra, board)
	var d = ScrubbotDispatcher.new(); root.add_child(d)
	return {"d": d, "selector": selector, "reservations": reservations, "candidates": candidates,
		"routing": routing, "ra": ra, "sa": sa}

func _bound_dispatcher(board):
	var b = _dispatcher(board)
	b["d"].bind(board, b["selector"], b["reservations"], b["routing"], b["ra"], b["sa"])
	return b

func _slots(color):
	var s = SlotSystem.new(); s.configure([color, color, color, color, color], 256); return s

func _ok(cond, msg):
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V08 lifecycle smoke")
	# --- §3 owner-GC claim release + no-leak ---
	var b1 = _board()
	var color: int = b1.get_color_id(b1.get_cell_index(11, 11))
	var bd1 = _bound_dispatcher(b1)
	var l1 = CompleteClearingLoop.new()
	_ok(l1.bind(b1, _slots(color), bd1["candidates"], bd1["reservations"], bd1["d"]), "first loop binds")
	var l2 = CompleteClearingLoop.new()
	_ok(not l2.bind(b1, _slots(color), bd1["candidates"], bd1["reservations"], bd1["d"]), "second live loop rejected")
	l2 = null
	var wr = weakref(l1)
	l1 = null
	await process_frame
	await process_frame
	_ok(wr.get_ref() == null, "no strong-cycle leak: owner loop genuinely freed after release")
	var l3 = CompleteClearingLoop.new()
	_ok(l3.bind(b1, _slots(color), bd1["candidates"], bd1["reservations"], bd1["d"]), "fresh loop claims once after owner GC")
	l3 = null

	# --- §4 truly-freed explicit agent_parent before bind ---
	var b4 = _board()
	var bd4 = _dispatcher(b4)
	var parent = Node.new(); root.add_child(parent); parent.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(parent), "explicit parent truly destroyed")
	_ok(not bd4["d"].bind(b4, bd4["selector"], bd4["reservations"], bd4["routing"], bd4["ra"], bd4["sa"], parent) and not bd4["d"].is_bound(), "bind rejects truly-freed explicit parent (no self fallback, no SCRIPT ERROR)")

	# --- §4 healthy bind, then explicit parent destroyed BEFORE dispatch ---
	var b4b = _board()
	var c4b: int = b4b.get_color_id(b4b.get_cell_index(11, 11))
	var bd4b = _dispatcher(b4b)
	var pp = Node.new(); root.add_child(pp)
	_ok(bd4b["d"].bind(b4b, bd4b["selector"], bd4b["reservations"], bd4b["routing"], bd4b["ra"], bd4b["sa"], pp), "healthy explicit parent binds")
	pp.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(pp), "explicit parent destroyed before dispatch")
	var rd = bd4b["d"].dispatch(c4b, Vector2(-2.0, 11.5), 6.0)
	_ok(not rd.success, "dispatch fails closed when explicit parent destroyed (no orphan agent)")
	_ok(bd4b["d"].get_active_count() == 0 and bd4b["reservations"].get_reservation_count() == 0, "no active/reservation left by the failed dispatch")

	# --- §5 configured renderer truly destroyed after dispatch, before arrival ---
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
	_ok(bd5["reservations"].get_owner(t5) == res.owner_id and bd5["d"].has_owner(res.owner_id), "assignment+reservation held until reset")
	loop.reset()
	_ok(bd5["d"].get_active_count() == 0, "reset cleans the held assignment")

	print("M20 V08 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
