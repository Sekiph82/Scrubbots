extends SceneTree
## M28-C002-C003-R01 V02 evidence: railway-first vs the previous equal-weight routing, drawn from
## the REAL ProductionRoutingSystem on real BoardState / ProductionAccessQuery / ScrubRailGeometry.
## Pure Image drawing (no rendering driver needed):
##   godot --headless --path . -s res://tests/tools/route_compare_snapshot.gd -- <out_dir>
## Green = railway-first (production), red = the pre-V02 route (interior_step_cost = 1.0).
## Grey grid = the board (cleared corridor everywhere, ACTIVE targets as dark squares), blue loop =
## the Scrubbot railroad centreline, yellow dot = slot connector entry.

const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")

const PX := 14.0            ## pixels per logical cell
const MARGIN := 5.0         ## cells of margin around the board (holds the rail at 2.5)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://route_compare"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	var w := 40
	var h := 40
	var targets := [Vector2i(3, 20), Vector2i(36, 22), Vector2i(18, 4), Vector2i(25, 35), Vector2i(9, 14), Vector2i(30, 8), Vector2i(1, 1), Vector2i(38, 38)]
	_render(out_dir + "/route_compare_open_40x40_slot_left.png", w, h, Vector2(5.5, float(h) + 3.6), targets, [])
	_render(out_dir + "/route_compare_open_40x40_slot_right.png", w, h, Vector2(33.5, float(h) + 3.6), targets, [])
	# Blocked aligned exit: cells (0,15),(1,15) ACTIVE, target (3,15).
	_render(out_dir + "/route_compare_blocked_exit_30x30.png", 30, 30, Vector2(4.5, 33.6), [Vector2i(3, 15)], [Vector2i(0, 15), Vector2i(1, 15)])
	quit(0)

func _render(path: String, w: int, h: int, start: Vector2, targets: Array, blockers: Array) -> void:
	var img := Image.create(int((w + MARGIN * 2.0) * PX), int((h + MARGIN * 2.0 + 2.0) * PX), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.07, 0.08, 0.11))
	var o := Vector2(MARGIN * PX, MARGIN * PX)
	# Board cells.
	for y in range(h):
		for x in range(w):
			_rect(img, o + Vector2(x, y) * PX, Vector2(PX - 1.0, PX - 1.0), Color(0.16, 0.19, 0.25))
	for b in blockers:
		_rect(img, o + Vector2(b.x, b.y) * PX, Vector2(PX - 1.0, PX - 1.0), Color(0.55, 0.30, 0.12))
	var g := ScrubRailGeometry.new(w, h)
	var loop := PackedVector2Array([Vector2(g.left_x(), g.top_y()), Vector2(g.right_x(), g.top_y()), Vector2(g.right_x(), g.bottom_y()), Vector2(g.left_x(), g.bottom_y()), Vector2(g.left_x(), g.top_y())])
	_poly(img, o, loop, Color(0.25, 0.55, 0.95), 2)
	var entry := g.bottom_entry(start.x)
	_disc(img, o + entry * PX, 5, Color(1.0, 0.85, 0.2))
	_poly(img, o, PackedVector2Array([start, entry]), Color(1.0, 0.85, 0.2), 2)
	var lens_new := 0.0
	var lens_old := 0.0
	for t in targets:
		var bn := _board(w, h, blockers, t)
		var ro = _route(bn, start, t, -1.0)
		var bo := _board(w, h, blockers, t)
		var rl = _route(bo, start, t, 1.0)
		_rect(img, o + Vector2(t.x, t.y) * PX, Vector2(PX - 1.0, PX - 1.0), Color(0.95, 0.95, 0.95))
		if rl.success:
			_poly(img, o, rl.get_points(), Color(0.95, 0.25, 0.25), 4)
		if ro.success:
			_poly(img, o, ro.get_points(), Color(0.2, 0.95, 0.4), 2)
		lens_new += _inside(ro.get_points(), w, h) if ro.success else 0.0
		lens_old += _inside(rl.get_points(), w, h) if rl.success else 0.0
	print("ROUTE_COMPARE ", path.get_file(), " board travel (cells): railway-first ", snappedf(lens_new, 0.1), " vs previous ", snappedf(lens_old, 0.1))
	img.save_png(path)

func _board(w: int, h: int, blockers: Array, target: Vector2i) -> BoardState:
	var b := BoardDebugFixtures.make_board(w, h)
	for i in range(w * h):
		b.set_cell_state(i, BoardState.CellState.CLEARED)
	for c in blockers:
		b.set_cell_state(b.get_cell_index(c.x, c.y), BoardState.CellState.ACTIVE)
	b.set_cell_state(b.get_cell_index(target.x, target.y), BoardState.CellState.ACTIVE)
	return b

func _route(b: BoardState, start: Vector2, t: Vector2i, cost: float) -> RefCounted:
	var rs := ProductionRoutingSystem.new()
	if cost > 0.0:
		rs.interior_step_cost = cost
	return rs.compute_route(RouteRequest.for_target(b, start, b.get_cell_index(t.x, t.y)), b, ProductionAccessQuery.new(b))

func _inside(pts: PackedVector2Array, w: int, h: int) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		var a := pts[i]
		var c := pts[i + 1]
		if absf(a.x - c.x) < 0.0001:
			if a.x > 0.0 and a.x < float(w):
				total += clampf(maxf(a.y, c.y), 0.0, float(h)) - clampf(minf(a.y, c.y), 0.0, float(h))
		elif a.y > 0.0 and a.y < float(h):
			total += clampf(maxf(a.x, c.x), 0.0, float(w)) - clampf(minf(a.x, c.x), 0.0, float(w))
	return total

func _rect(img: Image, p: Vector2, s: Vector2, c: Color) -> void:
	img.fill_rect(Rect2i(int(p.x), int(p.y), int(s.x), int(s.y)), c)

func _disc(img: Image, p: Vector2, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				var x := int(p.x) + dx
				var y := int(p.y) + dy
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					img.set_pixel(x, y, c)

func _poly(img: Image, origin: Vector2, pts: PackedVector2Array, c: Color, thick: int) -> void:
	for i in range(pts.size() - 1):
		var a := origin + pts[i] * PX
		var b := origin + pts[i + 1] * PX
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
		for k in range(steps + 1):
			var p := a.lerp(b, float(k) / float(steps))
			for dy in range(-thick / 2, thick / 2 + 1):
				for dx in range(-thick / 2, thick / 2 + 1):
					var x := int(p.x) + dx
					var y := int(p.y) + dy
					if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
						img.set_pixel(x, y, c)
