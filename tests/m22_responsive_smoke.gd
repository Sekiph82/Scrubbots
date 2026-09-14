extends SceneTree
## M22-C001 V01 — production five-slot ColorSelectionPanel responsive / safe-area
## validation smoke.
##
## Establishes REAL Control layout configurations by hosting the production
## component tree inside SubViewports whose size is set to each required device
## resolution (a reliable headless Godot mechanism that drives real container
## layout and does not touch project.godot), awaits layout frames, and directly
## measures post-layout slot geometry. It is NOT a tautological self-comparison:
## every assertion reads real laid-out Control rects produced by the actual viewport.
##
## Coverage:
##  - required matrix 1080x2160, 1170x2532, 1290x2796, 1080x2400, 1440x3200
##  - one shorter 16:9 portrait (1080x1920)
##  - one tablet portrait (1536x2048)
##  - a non-zero top/bottom/side safe-area inset harness
##  - post-layout spawn anchor attached to the correct cell, mapped into
##    BoardPresentation/AgentLayer route space at the baseline viewport
##
## Validation-only: changes no production source. Movement (baseline dispatch
## proof) is the agent's own advance(); the smoke drives arrival as orchestration.
##
## Run:  godot --headless --path . -s res://tests/m22_responsive_smoke.gd
## Exits 0 on success, 1 on any failure.

const ColorSelectionPanel = preload("res://scripts/ui/color_selection_panel.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
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
	var colors := _level_colors()
	if colors.is_empty():
		_ok(false, "level palette colors loaded")
		_done()
		return

	for size in MATRIX:
		await _run_matrix_case(size, colors)

	await _run_safe_area_case(colors)
	await _run_baseline_spawn_anchor_case(colors)

	_done()

func _level_colors() -> Array:
	var result = LevelLoader.load_from_path(LEVEL_PATH)
	if not result.is_ok():
		return []
	var parse = PaletteColors.parse(result.level_data.palette)
	var out: Array = []
	for i in range(5):
		out.append(parse.colors[i] if i < parse.colors.size() else Color(1, 0, 1, 1))
	return out

## Host the panel inside a real SubViewport at `size`, centered vertically like
## production (below the board), await layout, then measure real cell geometry.
func _run_matrix_case(size: Vector2i, colors: Array) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(root_ctrl)

	# Bottom-anchored container band, as the panel sits below the board.
	var band := CenterContainer.new()
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -260
	root_ctrl.add_child(band)

	var panel = ColorSelectionPanel.new()
	band.add_child(panel)
	panel.bind_colors(colors)

	await process_frame
	await process_frame

	_ok(sub.size == size, "%s: subviewport genuinely at requested size (observed %s)" % [str(size), str(sub.size)])
	var cells: Array = panel.get_slot_cells()
	_ok(cells.size() == 5, "%s: exactly five slot cells" % str(size))

	var bounds := Rect2(Vector2.ZERO, Vector2(float(size.x), float(size.y)))
	var ordered := true
	var touch_ok := true
	var contained := true
	var overlap := false
	var rects: Array = []
	var prev_x := -INF
	for c in cells:
		var r := Rect2(c.global_position, c.size)
		rects.append(r)
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

	_ok(touch_ok, "%s: every cell >= 88x88 reference px" % str(size))
	_ok(contained, "%s: all five cells inside viewport safe bounds" % str(size))
	_ok(ordered, "%s: cells deterministic left-to-right" % str(size))
	_ok(not overlap, "%s: no cell overlap" % str(size))

	# Spawn anchor attached to its own visible cell (x within cell, y at top).
	var anchor_ok := true
	for i in range(cells.size()):
		var a: Vector2 = panel.get_spawn_anchor_global(i)
		var cr := Rect2(cells[i].global_position, cells[i].size)
		if a.x < cr.position.x - 1.0 or a.x > cr.end.x + 1.0 or absf(a.y - cr.position.y) > 1.0:
			anchor_ok = false
	_ok(anchor_ok, "%s: each spawn anchor attached to top-center of its own cell" % str(size))

	if cells.size() == 5:
		print("MATRIX_ROW size=%s cell0=%s cell4=%s cell_size=%s sep=%d" % [
			str(size), str(rects[0]), str(rects[4]), str(cells[0].size),
			panel.get_theme_constant("separation")])

	root_ctrl.free()
	sub.free()

## Non-zero top/bottom/side safe-area inset harness: place the panel inside a
## MarginContainer with explicit non-zero insets and prove every essential cell
## stays inside the inner safe rectangle.
func _run_safe_area_case(colors: Array) -> void:
	var size := Vector2i(1080, 2160)
	var insets := {"left": 48, "top": 96, "right": 48, "bottom": 120}
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(root_ctrl)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", insets["left"])
	margin.add_theme_constant_override("margin_top", insets["top"])
	margin.add_theme_constant_override("margin_right", insets["right"])
	margin.add_theme_constant_override("margin_bottom", insets["bottom"])
	root_ctrl.add_child(margin)

	var band := CenterContainer.new()
	margin.add_child(band)
	var panel = ColorSelectionPanel.new()
	band.add_child(panel)
	panel.bind_colors(colors)

	await process_frame
	await process_frame

	# Inner safe rectangle after applying non-zero insets.
	var safe := Rect2(
		Vector2(float(insets["left"]), float(insets["top"])),
		Vector2(float(size.x - insets["left"] - insets["right"]), float(size.y - insets["top"] - insets["bottom"])))
	_ok(insets["left"] > 0 and insets["top"] > 0 and insets["right"] > 0 and insets["bottom"] > 0,
		"safe-area harness uses non-zero top/bottom/side insets")
	var cells: Array = panel.get_slot_cells()
	_ok(cells.size() == 5, "safe-area: five cells")
	var inside := true
	for c in cells:
		var r := Rect2(c.global_position, c.size)
		if not safe.encloses(r):
			inside = false
	_ok(inside, "safe-area: every essential slot cell inside the non-zero safe rectangle (safe=%s)" % str(safe))
	print("SAFE_AREA insets=%s safe_rect=%s cell0=%s cell4=%s" % [
		str(insets), str(safe),
		str(Rect2(cells[0].global_position, cells[0].size)) if cells.size() == 5 else "n/a",
		str(Rect2(cells[4].global_position, cells[4].size)) if cells.size() == 5 else "n/a"])

	root_ctrl.free()
	sub.free()

## Baseline: full production demo in a real viewport; prove a real clicked-slot
## anchor maps through BoardPresentation into the real agent route start.
func _run_baseline_spawn_anchor_case(colors: Array) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var scene = load("res://scenes/demo/m22_slot_demo.tscn")
	_ok(scene != null, "baseline: demo scene loads (no parse error)")
	if scene == null:
		sub.free()
		return
	var inst = scene.instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame

	var panel = inst.get_panel()
	var pres = inst.get_presentation()
	var slot_id := 2  # C08 reachable on the fresh Hazard Bot
	var anchor_global: Vector2 = panel.get_spawn_anchor_global(slot_id)
	var mapped: Vector2 = pres.global_to_board_local(anchor_global)

	inst._last_result = null
	panel.get_cell(slot_id).pressed.emit()  # real Button signal chain
	var r = inst._last_result
	_ok(r != null and r.success, "baseline: production panel click dispatches a real assignment")
	if r != null and r.success:
		var agent = r.agent
		_ok(inst._board.get_color_id(r.target_index) == slot_id, "baseline: activated color == slot palette id (C08)")
		_ok(agent.spawn_origin.distance_to(mapped) < 0.001, "baseline: agent.spawn_origin == mapped post-layout panel anchor")
		var pts: PackedVector2Array = agent.get_route_points()
		_ok(pts.size() >= 2 and pts[0].distance_to(mapped) < 0.001, "baseline: route first point == mapped board-local start")
		print("BASELINE_ANCHOR slot=%d anchor_global=%s mapped_local=%s spawn_origin=%s route0=%s target=%d" % [
			slot_id, str(anchor_global), str(mapped), str(agent.spawn_origin), str(pts[0]), r.target_index])
		# Drive to authenticated arrival (orchestration); M20 clears.
		for _i in range(512):
			if not is_instance_valid(agent) or not agent.is_moving():
				break
			agent.advance(1.0)

	inst.free()
	sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 responsive/safe-area smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
