extends SceneTree
## M20-C001 V05 — dedicated truly-freed Node smoke (§3E). Independently revalidates
## the liveness law for BOTH the dispatcher AND the renderer, destroyed before bind
## and after a healthy bind. Needs real SceneTree frames (queue_free defers).
##
## EVIDENCE ARTIFACT — this smoke currently EXPOSES a V04 gap and exits 1 on the
## TRULY-FREED OPTIONAL RENDERER cases (see CLAUDE_LOG_V05.md,
## V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT). In Godot 4.7 a freed Object compares
## `== null` (verified), so the optional renderer's `if renderer != null:` guard
## skips the liveness check once the renderer is truly destroyed: after a healthy
## bind, `is_coherent()` stays true and activation still succeeds instead of
## failing closed as §3B/§3D/§3E require. The DISPATCHER cases all pass (it is
## checked unconditionally). Not fixed here — V05 is validation-only; production is
## immutable and the fix belongs to a ChatGPT-authored production cycle.
##
## Run:  godot --headless --path . -s res://tests/m20_v05_lifecycle_smoke.gd
## Exits 0 only once the exposed gap is closed by a future production correction.

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

func _bundle(board):
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var ra = ProductionAccessQuery.new(board)
	var sa = ProductionTargetAccess.new(routing, ra, board)
	var d = ScrubbotDispatcher.new(); root.add_child(d)
	d.bind(board, selector, reservations, routing, ra, sa)
	return {"d": d, "candidates": candidates, "reservations": reservations}

func _renderer(board):
	var r = BoardRenderer.new(); root.add_child(r)
	r.configure(board, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(200, 200))
	return r

func _slots(color):
	var s = SlotSystem.new(); s.configure([color, color, color, color, color], 256); return s

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail = true
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _initialize() -> void:
	print("M20 V05 lifecycle smoke")
	# Case 1: truly-freed RENDERER before bind.
	var b1 = _board()
	var color: int = b1.get_color_id(b1.get_cell_index(10, 10))
	var bundle1 = _bundle(b1)
	var r1 = _renderer(b1)
	r1.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(r1), "renderer truly destroyed before bind")
	var loop1 = CompleteClearingLoop.new()
	var bound1: bool = loop1.bind(b1, _slots(color), bundle1["candidates"], bundle1["reservations"], bundle1["d"], r1)
	_ok(not bound1 and not loop1.is_bound(), "bind rejects truly-freed renderer without SCRIPT ERROR")

	# Case 2: healthy bind with renderer, then destroy the renderer across a frame.
	var b2 = _board()
	var c2: int = b2.get_color_id(b2.get_cell_index(10, 10))
	var bundle2 = _bundle(b2)
	var r2 = _renderer(b2)
	var loop2 = CompleteClearingLoop.new()
	_ok(loop2.bind(b2, _slots(c2), bundle2["candidates"], bundle2["reservations"], bundle2["d"], r2), "healthy bind with renderer")
	r2.queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(r2), "bound renderer destroyed across frame")
	_ok(not loop2.is_coherent(), "is_coherent() false after renderer destroyed (no SCRIPT ERROR)")
	_ok(not loop2.activate_slot(0, Vector2(-2.0, 10.5)).success, "activation fails closed with destroyed renderer")
	loop2.reset()
	_ok(true, "reset() safe with destroyed renderer (no SCRIPT ERROR)")

	# Case 3: truly-freed DISPATCHER before + after bind (revalidate independently).
	var b3 = _board()
	var c3: int = b3.get_color_id(b3.get_cell_index(10, 10))
	var bundle3 = _bundle(b3)
	bundle3["d"].queue_free()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(bundle3["d"]), "dispatcher truly destroyed before bind")
	var loop3 = CompleteClearingLoop.new()
	_ok(not loop3.bind(b3, _slots(c3), bundle3["candidates"], bundle3["reservations"], bundle3["d"]) and not loop3.is_bound(), "bind rejects truly-freed dispatcher")

	var b4 = _board()
	var c4: int = b4.get_color_id(b4.get_cell_index(10, 10))
	var bundle4 = _bundle(b4)
	var loop4 = CompleteClearingLoop.new()
	_ok(loop4.bind(b4, _slots(c4), bundle4["candidates"], bundle4["reservations"], bundle4["d"]), "healthy bind (dispatcher)")
	bundle4["d"].queue_free()
	await process_frame
	await process_frame
	_ok(not loop4.is_coherent(), "is_coherent() false after dispatcher destroyed")
	_ok(not loop4.activate_slot(0, Vector2(-2.0, 10.5)).success, "activation fails closed with destroyed dispatcher")
	loop4.reset()
	_ok(true, "reset() safe with destroyed dispatcher")

	print("M20 V05 lifecycle smoke: %s" % ["PASS" if not _fail else "FAIL"])
	quit(1 if _fail else 0)
