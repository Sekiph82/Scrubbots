extends SceneTree
## M20-C001 V07 — frame-aware lifecycle smoke. Covers the cases that need real
## SceneTree frames (true Node destruction): a truly-freed explicit agent_parent
## passed to ScrubbotDispatcher.bind (F-M20-STRICT-001.N), and a configured
## renderer truly destroyed after dispatch but before arrival (F-M20-STRICT-001.L
## no-clear law). Must exit 0.
##
## Run:  godot --headless --path . -s res://tests/m20_v07_lifecycle_smoke.gd

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
	var b = RoutingLabScenarios.make_open_board(20, 20)
	b.set_cell_state(b.get_cell_index(10, 10), BoardState.CellState.ACTIVE)
	return b

func _parts(board):
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var ra = ProductionAccessQuery.new(board)
	var sa = ProductionTargetAccess.new(routing, ra, board)
	var d = ScrubbotDispatcher.new(); root.add_child(d)
	return {"d": d, "selector": selector, "reservations": reservations, "candidates": candidates,
		"routing": routing, "ra": ra, "sa": sa}

func _slots(color):
	var s = SlotSystem.new(); s.configure([color, color, color, color, color], 256); return s

func _ok(cond, msg):
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V07 lifecycle smoke")
	# Case 1: truly-freed explicit agent_parent -> dispatcher.bind false, no self fallback.
	var b1 = _board()
	var parts1 = _parts(b1)
	var parent = Node.new(); root.add_child(parent)
	parent.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(parent), "explicit parent truly destroyed")
	var bound1: bool = parts1["d"].bind(b1, parts1["selector"], parts1["reservations"], parts1["routing"], parts1["ra"], parts1["sa"], parent)
	_ok(not bound1 and not parts1["d"].is_bound(), "bind rejects truly-freed explicit agent_parent (no self fallback, no SCRIPT ERROR)")

	# Case 2: configured renderer truly destroyed AFTER dispatch, BEFORE arrival ->
	# authenticated arrival clears nothing; assignment/reservation stay held.
	var b2 = _board()
	var t2: int = b2.get_cell_index(10, 10)
	var c2: int = b2.get_color_id(t2)
	var parts2 = _parts(b2)
	parts2["d"].bind(b2, parts2["selector"], parts2["reservations"], parts2["routing"], parts2["ra"], parts2["sa"])
	var renderer = BoardRenderer.new(); root.add_child(renderer)
	renderer.configure(b2, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(200, 200))
	var loop = CompleteClearingLoop.new()
	_ok(loop.bind(b2, _slots(c2), parts2["candidates"], parts2["reservations"], parts2["d"], renderer), "healthy renderer bind")
	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_ok(res.success, "dispatched a live assignment")
	# Truly destroy the configured renderer across a frame, before driving arrival.
	renderer.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(renderer), "configured renderer truly destroyed before arrival")
	for _i in range(128):
		if not res.agent.is_moving():
			break
		res.agent.advance(1.0)
	_ok(b2.get_cell_state(t2) == BoardState.CellState.ACTIVE, "truly-freed configured renderer -> arrival clears nothing")
	_ok(loop.get_cleared_count() == 0, "cleared_count unchanged")
	_ok(parts2["reservations"].get_owner(t2) == res.owner_id, "reservation still held")
	_ok(parts2["d"].has_owner(res.owner_id), "dispatcher assignment held until reset")
	loop.reset()
	_ok(parts2["d"].get_active_count() == 0, "reset cleans the held assignment")

	print("M20 V07 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
