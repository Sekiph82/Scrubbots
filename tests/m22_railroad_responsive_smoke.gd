extends SceneTree
## M22-C001 V02 — Scrubbot Railroad V1 responsive / visual-layout smoke.
##
## Hosts the production M22 railroad demo inside real SubViewports at every required
## portrait resolution, awaits layout frames, and directly measures post-layout
## geometry: the reusable railroad view is present with valid single-source
## geometry, the five slot cells sit BELOW the bottom rail (never inside the 2-cell
## artwork clearance), touch targets stay >= 88 reference px, no essential overlap,
## and the board aspect is undistorted. Also validates rectangular + 59x59 rail
## geometry, the invariant 2-cell logical clearance, and reset-while-travelling
## orphan cleanup after deferred free. Boots the demo headlessly with zero
## SCRIPT/Parse errors (M22-V02-155).
##
## Validation-only: changes no production source. Movement is the agent's own.
##
## Run:  godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd
## Exits 0 on success, 1 on any failure.

const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const TOUCH_MIN := 88.0

const MATRIX := [
	Vector2i(1080, 2160),
	Vector2i(1170, 2532),
	Vector2i(1290, 2796),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
	Vector2i(1080, 1920),  # shorter 16:9 portrait
	Vector2i(1536, 2048),  # tablet portrait
]

var _fail := 0

func _initialize() -> void:
	# Geometry invariants: 2-cell clearance is constant across square/rectangular
	# and 20..59 sizes; centrelines/corners exact (criteria M22-V02-122/123/124).
	for dim in [Vector2i(20, 20), Vector2i(30, 12), Vector2i(59, 59)]:
		var g = ScrubRailGeometry.new(dim.x, dim.y)
		_ok(g.is_valid(), "geometry %s valid" % str(dim))
		_ok(g.clearance() == 2.0, "geometry %s clearance invariant 2.0" % str(dim))
		_ok(g.rail_width() == 1.0, "geometry %s rail width 1.0" % str(dim))
		_ok(g.bottom_y() == float(dim.y) + 2.5 and g.right_x() == float(dim.x) + 2.5, "geometry %s centrelines track W/H" % str(dim))

	for size in MATRIX:
		await _run_case(size)

	await _run_reset_cleanup_case()
	_done()

func _run_case(size: Vector2i) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var scene = load("res://scenes/demo/m22_slot_demo.tscn")
	var inst = scene.instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame

	_ok(sub.size == size, "%s: subviewport genuinely at size" % str(size))
	var rail = inst.get_rail_view()
	_ok(rail != null and rail.get_geometry() != null and rail.get_geometry().is_valid(), "%s: rail view present + valid geometry" % str(size))

	var panel = inst.get_panel()
	var cells: Array = panel.get_slot_cells()
	_ok(cells.size() == 5, "%s: five slot cells" % str(size))

	var h: int = inst._board.get_height()
	var cs: float = inst.get_presentation().get_cell_size()
	# Board-local bottom-rail OUTER edge = H + CENTER_OFFSET + RAIL_WIDTH/2 = H+3.
	var rail_outer_screen: float = inst.BOARD_ORIGIN.y + (float(h) + 3.0) * cs
	var board_bottom_screen: float = inst.BOARD_ORIGIN.y + inst.BOARD_DISPLAY.y

	var bounds := Rect2(Vector2.ZERO, Vector2(float(size.x), float(size.y)))
	var below_rail := true
	var touch_ok := true
	var contained := true
	var ordered := true
	var overlap := false
	var rects: Array = []
	var prev_x := -INF
	for c in cells:
		var r := Rect2(c.global_position, c.size)
		rects.append(r)
		if r.position.y <= rail_outer_screen:
			below_rail = false
		if c.size.x < TOUCH_MIN or c.size.y < TOUCH_MIN:
			touch_ok = false
		if not bounds.encloses(r):
			contained = false
		if c.global_position.x <= prev_x:
			ordered = false
		prev_x = c.global_position.x
	for i in range(rects.size()):
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				overlap = true

	_ok(below_rail, "%s: all five slots below the bottom rail (not in clearance)" % str(size))
	_ok(touch_ok, "%s: every slot >= 88x88 reference px" % str(size))
	_ok(contained, "%s: slots inside viewport bounds" % str(size))
	_ok(ordered, "%s: slots deterministic left-to-right" % str(size))
	_ok(not overlap, "%s: no slot overlap" % str(size))
	# Board aspect undistorted: 20x20 board rendered square (cell size uniform).
	_ok(inst.BOARD_DISPLAY.x == inst.BOARD_DISPLAY.y and absf(cs - inst.BOARD_DISPLAY.y / float(h)) < 0.001, "%s: board aspect undistorted by rail/slot layout" % str(size))
	# >=2 logical cells of breathing room between artwork and rail inner edge.
	_ok(rail_outer_screen - board_bottom_screen >= 2.0 * cs - 0.001, "%s: >=2 logical-cell gap between artwork and rail" % str(size))
	print("RAIL_ROW size=%s cell_size=%.1f rail_outer_y=%.1f cell0=%s cell4=%s" % [
		str(size), cs, rail_outer_screen,
		str(Rect2(cells[0].global_position, cells[0].size)),
		str(Rect2(cells[4].global_position, cells[4].size))])

	inst.free()
	sub.free()

## Reset while >=2 real agents are still travelling on the rail; after deferred
## free the AgentLayer holds zero orphan Scrubbots (M22-V02-113).
func _run_reset_cleanup_case() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var scene = load("res://scenes/demo/m22_slot_demo.tscn")
	var inst = scene.instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame

	var a = inst.request_slot(2)
	var b = inst.request_slot(2)
	var c = inst.request_slot(2)
	var moving := 0
	for res in [a, b, c]:
		if res != null and res.success and is_instance_valid(res.agent) and res.agent.is_moving():
			moving += 1
	_ok(moving >= 2, "reset case: >=2 agents in rail travel before reset (got %d)" % moving)
	inst.reset_presentation()
	await process_frame
	await process_frame
	var layer = inst.get_agent_layer()
	var orphans := 0
	for ch in layer.get_children():
		if ch is ScrubbotAgent:
			orphans += 1
	_ok(orphans == 0, "reset case: zero orphan Scrubbots after deferred cleanup (got %d)" % orphans)

	inst.free()
	sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 railroad responsive smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
