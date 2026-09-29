extends SceneTree
## M32-C002 owner visual evidence: board-resolution-independent Scrubbot apparent size.
## REAL ProductionGameplayHost / GameplayScreen, ONE fixed 1080x2160 viewport for the main
## 20/32/38/59 comparison, real gameplay ticks so live Scrubbots are genuinely dispatched and
## moving (2x), plus rectangular boards, a TEST-only synthetic 100x100 (screen-only, never a
## production level), a responsive before/after relayout pair and side-by-side montages.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/m32_c002_size_snapshot.gd -- <out_dir>

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const PHONE := Vector2i(1080, 2160)

var _out := ""
var _tmp: Array = []
var _measure: Array = []
var _main_imgs: Dictionary = {}

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "res://coordination/sessions/M32-C002/evidence"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var cases := [
		["m32c002_20x20_L1_hazard_bot_1080x2160", "res://data/levels/m21_level_001_hazard_bot.json", true],
		["m32c002_32x32_L2_apple_REFERENCE_1080x2160", "res://data/levels/level_002_apple.json", true],
		["m32c002_38x38_L3_palm_tree_1080x2160", "res://data/levels/level_003_palm_tree.json", true],
		["m32c002_59x59_TEST_stripe_1080x2160", _level_json(59, 59, "m32c002_59"), true],
		["m32c002_rect_59x40_TEST_width_limited_1080x2160", _level_json(59, 40, "m32c002_59x40"), false],
		["m32c002_rect_24x40_TEST_height_limited_1080x2160", _level_json(24, 40, "m32c002_24x40"), false],
	]
	for c in cases:
		await _shot(c[0], c[1], c[2])
	await _synthetic_100()
	await _relayout_pair()
	_montage("m32c002_MONTAGE_20_32_38_59_same_viewport.png", ["m32c002_20x20_L1_hazard_bot_1080x2160", "m32c002_32x32_L2_apple_REFERENCE_1080x2160",
		"m32c002_38x38_L3_palm_tree_1080x2160", "m32c002_59x59_TEST_stripe_1080x2160"])
	_montage("m32c002_MONTAGE_BOARD_CROP_20_32_38_59_full_res.png", ["m32c002_20x20_L1_hazard_bot_1080x2160", "m32c002_32x32_L2_apple_REFERENCE_1080x2160",
		"m32c002_38x38_L3_palm_tree_1080x2160", "m32c002_59x59_TEST_stripe_1080x2160"], Rect2i(20, 170, 1040, 1000))
	_montage("m32c002_MONTAGE_BOARD_CROP_preC002_vs_C002_20_38_59_full_res.png", ["pre_m32c002_20x20_L1_hazard_bot_1080x2160", "m32c002_20x20_L1_hazard_bot_1080x2160",
		"pre_m32c002_38x38_L3_palm_tree_1080x2160", "m32c002_38x38_L3_palm_tree_1080x2160",
		"pre_m32c002_59x59_TEST_stripe_1080x2160", "m32c002_59x59_TEST_stripe_1080x2160"], Rect2i(20, 170, 1040, 1000))
	_montage("m32c002_MONTAGE_preC002_vs_C002_20_and_59.png", ["pre_m32c002_20x20_L1_hazard_bot_1080x2160", "m32c002_20x20_L1_hazard_bot_1080x2160",
		"pre_m32c002_59x59_TEST_stripe_1080x2160", "m32c002_59x59_TEST_stripe_1080x2160"])
	var f := FileAccess.open(_out.path_join("m32c002_snapshot_measurements.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_measure, "  "))
	f.close()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit(0)

func _level_json(w: int, h: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(h):
		for x in range(w):
			cells.append((x * 6 / w + y / 7) % 6)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": h, "palette": HEX, "cells": cells}

func _host(lvl, vp: Vector2i):
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	var path: String = lvl if lvl is String else ""
	if path.is_empty():
		path = "user://m32c002snap_%d.json" % Time.get_ticks_usec()
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(lvl))
		f.close()
		_tmp.append(path)
	h.level_path = path
	var sub := SubViewport.new()
	sub.size = vp
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	h.set_meta("sub", sub)
	await process_frame
	await process_frame
	if not h.build():
		push_error("build failed %s" % h.get_build_error())
	await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame

## Real gameplay: fill slots from the supply, tick the runtime at 2x until several bots fly.
func _play(h, frames: int) -> void:
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var col := 0
	for _i in range(frames):
		if h.get_slots().rightmost_empty_index() != -1 and not h.get_supply().is_exhausted():
			for k in range(3):
				if h.get_input_controller().activate_front((col + k) % 3).get("ok", false):
					col = (col + k + 1) % 3
					break
		rt.tick(1.0 / 60.0)

func _agents(h) -> Array:
	return h.get_screen().get_presentation().get_agent_layer().get_children().filter(func(a): return a is ScrubbotAgent)

func _capture(h, stem: String) -> Image:
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = h.get_meta("sub").get_texture().get_image()
	var path := _out.path_join(stem + ".png")
	img.save_png(ProjectSettings.globalize_path(path) if path.begins_with("res://") else path)
	_main_imgs[stem] = img
	print("SNAPSHOT %s" % path)
	return img

func _record(h, stem: String, extra: Dictionary = {}) -> void:
	var pres = h.get_screen().get_presentation()
	var b = pres.get_renderer()
	var k: float = pres.get_parent().get_global_transform().x.length()
	var spans: Array = []
	for a in _agents(h):
		for v in a.get_children():
			if v is ScrubbotVisual and v.has_body():
				var body: Sprite2D = v.get_child(0)
				var tex: Vector2 = body.texture.get_size()
				var gt: Transform2D = pres.get_agent_layer().get_global_transform() * a.get_transform() * v.get_transform() * Transform2D(0.0, v._base_scale, 0.0, Vector2.ZERO)
				spans.append(snappedf(maxf(tex.x * gt.x.length(), tex.y * gt.y.length()), 0.01))
	var row := {"shot": stem, "viewport": [h.get_meta("sub").size.x, h.get_meta("sub").size.y],
		"board": [h.get_screen().get_presentation().get_renderer().get_board_pixel_size().x / b.get_cell_size(), h.get_screen().get_presentation().get_renderer().get_board_pixel_size().y / b.get_cell_size()],
		"renderer_cell_px": b.get_cell_size(), "presentation_scale": pres.scale.x, "display_cell_px": b.get_cell_size() * pres.scale.x,
		"reference_32_display_cell_px": pres.get_reference_cell_size(), "compensation": pres.get_scrubbot_size_compensation(),
		"local_body_span_cells": 2.4 * pres.get_scrubbot_size_compensation(), "shell_scale": k,
		"expected_body_px": 2.4 * pres.get_reference_cell_size() * k, "expected_echo_px": 2.1 * pres.get_reference_cell_size() * k,
		"live_agents": spans.size(), "measured_live_body_px": spans}
	row.merge(extra)
	_measure.append(row)

## Static lineup probes: real ScrubbotVisual nodes on real ScrubbotAgents in the real AgentLayer,
## at the SAME board fractions on every board (presentation-only; never assigned a route), so
## the apparent-size comparison is obvious side by side. Returns the probe agents.
func _lineup(h) -> Array:
	var pres = h.get_screen().get_presentation()
	var r = pres.get_renderer()
	var bw: float = r.get_board_pixel_size().x / r.get_cell_size()
	var bh: float = r.get_board_pixel_size().y / r.get_cell_size()
	var out: Array = []
	for fx in [0.2, 0.4, 0.6, 0.8]:
		var a = ScrubbotAgent.new()
		var v = ScrubbotVisual.new()
		a.add_child(v)
		pres.get_agent_layer().add_child(a)
		a.position = Vector2(bw * fx, bh * 0.5)
		out.append(a)
	return out

func _shot(stem: String, lvl, with_pre: bool) -> void:
	var h = await _host(lvl, PHONE)
	_play(h, 600)
	_lineup(h)
	await process_frame
	_record(h, stem)
	await _capture(h, stem)
	if with_pre:
		# Pre-C002 look for comparison: the old constant 2.4 board-cell body (display only).
		for a in _agents(h):
			for v in a.get_children():
				if v is ScrubbotVisual and v.has_body():
					v.set_process(false)
					var tx: Vector2 = v.get_child(0).texture.get_size()
					v.get_child(0).scale = Vector2.ONE * (2.4 / maxf(tx.x, tx.y))
		await _capture(h, "pre_" + stem)
	h.get_meta("sub").free()

func _synthetic_100() -> void:
	# Screen-only TEST fixture: the SAME real GameplayScreen reconfigured with a detached 100x100
	# BoardState (outside the production envelope, never a level file / catalog entry). Static
	# Scrubbots are placed (the runtime cannot dispatch on it and is never ticked).
	var h = await _host("res://data/levels/level_002_apple.json", PHONE)
	var cells := PackedInt32Array()
	for y in range(100):
		for x in range(100):
			cells.append((x * 6 / 100 + y / 7) % 6)
	var b = BoardState.from_level_data(LevelData.new(1, "m32c002_synth100", "m32c002", "TEST", 100, 100, PackedStringArray(HEX), cells))
	for i in range(100 * 100):
		if (i / 100) > 70 or (i % 100) < 6:
			b.set_cell_state(i, BoardState.CellState.CLEARED)
	h.get_screen().configure(b, PackedStringArray(HEX), h.get_slots().snapshot(), h.get_supply().player_snapshot())
	await _settle(h)
	_lineup(h)
	await process_frame
	_record(h, "m32c002_synthetic_100x100_TEST_screen_only_1080x2160", {"note": "TEST-only synthetic 100x100, static Scrubbots"})
	await _capture(h, "m32c002_synthetic_100x100_TEST_screen_only_1080x2160")
	h.get_meta("sub").free()

func _relayout_pair() -> void:
	var h = await _host("res://data/levels/level_003_palm_tree.json", PHONE)
	_play(h, 600)
	_lineup(h)
	var ids: Array = _agents(h).map(func(a): return a.get_instance_id())
	var pos: Array = _agents(h).map(func(a): return a.position)
	_record(h, "m32c002_relayout_BEFORE_38x38_1080x2160", {"agent_ids": ids})
	await _capture(h, "m32c002_relayout_BEFORE_38x38_1080x2160")
	h.get_meta("sub").size = Vector2i(1536, 2048)
	await _settle(h)
	await process_frame
	var ids2: Array = _agents(h).map(func(a): return a.get_instance_id())
	var pos2: Array = _agents(h).map(func(a): return a.position)
	_record(h, "m32c002_relayout_AFTER_38x38_tablet_1536x2048", {"agent_ids": ids2, "same_agents": ids == ids2, "same_positions": pos == pos2})
	await _capture(h, "m32c002_relayout_AFTER_38x38_tablet_1536x2048")
	h.get_meta("sub").free()

## Side-by-side montage: full-viewport shots at half size, or a full-resolution crop.
func _montage(name: String, stems: Array, crop: Rect2i = Rect2i()) -> void:
	var imgs: Array = []
	for s in stems:
		if _main_imgs.has(s):
			var im: Image = _main_imgs[s].duplicate()
			im.convert(Image.FORMAT_RGBA8)
			if crop.size != Vector2i.ZERO:
				im = im.get_region(crop)
			else:
				im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_BILINEAR)
			imgs.append(im)
	if imgs.is_empty():
		return
	var w := 0
	var hh := 0
	for im in imgs:
		w += im.get_width() + 8
		hh = maxi(hh, im.get_height())
	var out := Image.create(w, hh, false, Image.FORMAT_RGBA8)
	out.fill(Color(1, 1, 1, 1))
	var x := 0
	for im in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, 0))
		x += im.get_width() + 8
	var path := _out.path_join(name)
	out.save_png(ProjectSettings.globalize_path(path) if path.begins_with("res://") else path)
	print("MONTAGE %s" % path)
