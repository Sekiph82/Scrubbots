extends SceneTree
## M29-C001 V02 — exact visible slot-origin evidence (F-M29-V01-STRICT-001, criteria §1-§4).
##
## Proves SlotOriginProvider.origin_for_slot(i) derives the routing start from the ACTUAL
## laid-out M28 production slot top-center — FiveSlotStrip.get_slot_anchor_global(i) mapped
## through BoardPresentation.global_to_board_local(...) — dynamically (no stale cached
## screen pixels, follows responsive relayout), fails closed for invalid/dead/non-finite
## state with NO synthetic fallback, and yields a route whose point 0 is exactly that
## visible mapping and still reaches the canonical BOTTOM rail (M22 Railroad V1/V07).
##
## Run: godot --headless --path . -s res://tests/m29_exact_slot_origin_evidence.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SlotOriginProvider = preload("res://scripts/gameplay/runtime/slot_origin_provider.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

const EPS := 1.0e-4
const SLOT_COUNT := 5

var _fail := 0
var _sub

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	var host = await _make_host(Vector2i(1080, 2160))
	if host == null:
		return
	var screen = host.get_screen()
	var strip = screen.get_five_slot_strip()
	var pres = screen.get_presentation()
	var provider = host.get_origin_provider()
	var board = host.get_board()

	# §1 exact mapping at 1080x2160: provider == strip anchor mapped through presentation.
	var origins_1080: Array = []
	var all_below := true
	var any_diff_from_synthetic := false
	var w: float = float(board.get_width())
	var h: float = float(board.get_height())
	for i in range(SLOT_COUNT):
		var expected: Vector2 = pres.global_to_board_local(strip.get_slot_anchor_global(i))
		var got: Vector2 = provider.origin_for_slot(i)
		origins_1080.append(got)
		_ok(got.is_equal_approx(expected), "slot %d origin == visible top-center mapping at 1080x2160 (%s == %s)" % [i, got, expected])
		if not (is_finite(got.x) and is_finite(got.y)) or got.y <= h:
			all_below = false
		var synthetic := Vector2((float(i) + 0.5) * w / float(SLOT_COUNT), h + 4.0)
		if not got.is_equal_approx(synthetic):
			any_diff_from_synthetic = true
	_ok(all_below, "every visible origin is finite and below the board bottom (routable exterior start)")
	_ok(any_diff_from_synthetic, "origins are the real visible mapping, NOT the old synthetic board_width/5 lanes")

	# §2 dynamic responsive mapping: resize the viewport, relayout, re-map. Origins must
	# still equal the (recomputed) visible mapping AND must have moved (no stale cache).
	_sub.size = Vector2i(1440, 3200)
	await process_frame
	await process_frame
	screen.relayout()
	await process_frame
	await process_frame
	var moved := false
	for i in range(SLOT_COUNT):
		var expected2: Vector2 = pres.global_to_board_local(strip.get_slot_anchor_global(i))
		var got2: Vector2 = provider.origin_for_slot(i)
		_ok(got2.is_equal_approx(expected2), "slot %d origin tracks the visible mapping after relayout (%s)" % [i, got2])
		if not got2.is_equal_approx(origins_1080[i]):
			moved = true
	_ok(moved, "origins updated after responsive viewport/layout change (no stale cached screen coordinate)")

	# §3 fail closed.
	_ok(not _finite(provider.origin_for_slot(-1)), "out-of-range slot (-1) fails closed")
	_ok(not _finite(provider.origin_for_slot(SLOT_COUNT)), "out-of-range slot (5) fails closed")
	_ok(not _finite(SlotOriginProvider.new(null, null, board).origin_for_slot(0)), "null presentation+strip fails closed")
	_ok(not _finite(SlotOriginProvider.new(pres, null, board).origin_for_slot(0)), "missing strip fails closed")
	_ok(not _finite(SlotOriginProvider.new(null, strip, board).origin_for_slot(0)), "missing presentation fails closed")

	# §4 Railroad integration: the route from a visible origin starts exactly there and is
	# RouteValidator-clean to the canonical BOTTOM rail (no diagonal/corner-cut/teleport).
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var origin0: Vector2 = provider.origin_for_slot(0)
	var routed := false
	for t in range(board.get_width() * board.get_height()):
		if board.get_cell_state(t) != BoardState.CellState.ACTIVE:
			continue
		var req = RouteRequest.for_target(board, origin0, t)
		if req == null:
			continue
		var route = routing.compute_route(req, board, raccess)
		if route != null and route.success:
			var pts = route.get_points()
			_ok(pts[0].is_equal_approx(origin0), "route point 0 == the exact visible slot origin (%s)" % origin0)
			_ok(RouteValidator.validate_route(req, route, board, raccess) == RouteResult.FailureReason.NONE, "route from the visible origin is Railroad V1/V07 clean (no diagonal/corner-cut/teleport)")
			routed = true
			break
	_ok(routed, "a real target routes from the exact visible slot origin")

	_sub.free()

func _make_host(size: Vector2i):
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)
	return host

func _finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 exact slot-origin evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
