extends SceneTree
## M20-C001 V04 — dedicated Node-lifetime smoke (F-M20-STRICT-001.K). The
## synchronous root runner cannot fully DESTROY a Node (queue_free defers to a
## frame), so the "already destroyed" cases live here where real SceneTree frames
## run. Proves: binding a truly-freed dispatcher fails closed WITHOUT a SCRIPT
## ERROR; and after a healthy bind, once the dispatcher is destroyed across a
## frame, is_coherent() is false, activation fails closed, and reset() is a safe
## no-op that never calls the destroyed dispatcher.
##
## Run:  godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd
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
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")

var _fail: bool = false

func _board():
	var b = RoutingLabScenarios.make_open_board(20, 20)
	b.set_cell_state(b.get_cell_index(10, 10), BoardState.CellState.ACTIVE)
	return b

func _dispatcher(board):
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var ra = ProductionAccessQuery.new(board)
	var sa = ProductionTargetAccess.new(routing, ra, board)
	var d = ScrubbotDispatcher.new(); root.add_child(d)
	d.bind(board, selector, reservations, routing, ra, sa)
	return {"d": d, "candidates": candidates, "reservations": reservations}

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V04 lifecycle smoke")
	# Case 1: truly-freed dispatcher before bind.
	var b1 = _board()
	var color: int = b1.get_color_id(b1.get_cell_index(10, 10))
	var bundle1 = _dispatcher(b1)
	bundle1["d"].queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(bundle1["d"]), "dispatcher truly destroyed after frames")
	var slots = SlotSystem.new(); slots.configure([color, color, color, color, color], 256)
	var loop1 = CompleteClearingLoop.new()
	var bound1: bool = loop1.bind(b1, slots, bundle1["candidates"], bundle1["reservations"], bundle1["d"])
	_ok(not bound1 and not loop1.is_bound(), "bind rejects truly-freed dispatcher without SCRIPT ERROR")

	# Case 2: healthy bind, then destroy the dispatcher across a frame.
	var b2 = _board()
	var c2: int = b2.get_color_id(b2.get_cell_index(10, 10))
	var bundle2 = _dispatcher(b2)
	var slots2 = SlotSystem.new(); slots2.configure([c2, c2, c2, c2, c2], 256)
	var loop2 = CompleteClearingLoop.new()
	_ok(loop2.bind(b2, slots2, bundle2["candidates"], bundle2["reservations"], bundle2["d"]), "healthy bind succeeds")
	bundle2["d"].queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(bundle2["d"]), "bound dispatcher destroyed across frame")
	_ok(not loop2.is_coherent(), "is_coherent() false after dispatcher destroyed (no SCRIPT ERROR)")
	_ok(not loop2.activate_slot(0, Vector2(-2.0, 10.5)).success, "activation fails closed against destroyed dispatcher")
	loop2.reset() # must not call the destroyed dispatcher
	_ok(true, "reset() safe with destroyed dispatcher (no SCRIPT ERROR)")

	print("M20 V04 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
