extends SceneTree
## M50 decisions A + B owner-review capture (evidence only, never UI). Renders the REAL app root
## Home (hero PLAY label) and production L1 gameplay through main.tscn with a throw-away save, plus
## GameplayScreen arrangements on the real L3 / L5 palettes and a 16-colour symbol legend.
## SB-M50-OPTIN-001: the real L7 board (app root) and test_59x59 at 1080x2160 and 720x1520 with
## symbols OFF / ON and BEFORE (the pre-OPTIN 0.8 glyph, set through shader parameters only),
## printing px per cell and glyph px; full screen JPG + native board crop PNG per state.
## Needs a rendering driver (run WITHOUT --headless); writes small JPGs into <out_dir>:
##   godot --path . -s res://tests/tools/m50_symbol_capture.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ColorSymbols = preload("res://scripts/ui/color_symbols.gd")
const PRE_OPTIN := {"glyph_span": 0.8, "ink_alpha": 0.92, "halo_alpha": 0.5, "min_glyph_px": 0.0}

const SIZE := Vector2i(1080, 2160)
var _out := "user://"
var _save := ""

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0].trim_suffix("/") + "/"
	MainScript.boot_opening_override = 0
	_save = "user://m50_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	var sub := _sub(SIZE)
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(10)
	_shot(sub, "m50_home_play")
	root.play_current_frontier()
	await _frames(12)
	if root.get_gameplay_host() != null:
		root.get_gameplay_host().get_runtime().set_process(false)
	_shot(sub, "m50_l1_gameplay")
	root.free()
	sub.free()
	for lvl in ["level_003_palm_tree", "level_005_party_toucan"]:
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/%s.json" % lvl))
		var pal := PackedStringArray(data["palette"])
		var s2 := _sub(SIZE)
		var scr = GameplayScreen.new()
		scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s2.add_child(scr)
		var cols := 5 if pal.size() > 6 else 4
		var supply: Array = []
		for c in range(cols):
			var pv: Array = []
			for r in range(3):
				pv.append({"color_id": (c * 3 + r) % pal.size(), "robot_count": [7, 45, 120][r] + c})
			supply.append({"front": pv[0], "preview": pv, "remaining": 9})
		scr.configure(BoardDebugFixtures.make_board(24, 24), pal, [], supply)
		scr.get_five_slot_strip().set_capacity(6)
		var slots: Array = []
		for i in range(6):
			slots.append({"state": "ACTIVE" if i == 0 else "WAITING", "occupied": true, "remaining_to_clear": 5 + i * 9, "committed": 0, "color_id": i % pal.size()} if i < 5 else {"state": "EMPTY", "occupied": false})
		scr.refresh_slot_snapshot(slots)
		await _frames(8)
		_shot(s2, "m50_%s_supply_slots" % lvl)
		s2.free()
	await _legend()
	await _boards()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))
	quit(0)

func _boards() -> void:
	var res = LevelLoader.load_from_path("res://data/levels/test_59x59.json")
	for size in [Vector2i(1080, 2160), Vector2i(720, 1520)]:
		var tag := "%dx%d" % [size.x, size.y]
		var sub := _sub(size)
		var root = MainScene.instantiate()
		sub.add_child(root)
		await _frames(10)
		root.get_app_state().progression.debug_set_current_level(7)
		root.play_current_frontier()
		await _frames(12)
		root.get_gameplay_host().get_runtime().set_process(false)
		await _board_shots(sub, root.get_gameplay_host().get_screen(), "l7_" + tag, func(on): root.get_app_state().set_color_symbols(on))
		root.free()
		sub.free()
		var s2 := _sub(size)
		var scr = GameplayScreen.new()
		scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s2.add_child(scr)
		var pal: PackedStringArray = res.level_data.palette
		var supply: Array = []
		for c in range(5):
			var pv: Array = []
			for r in range(3):
				pv.append({"color_id": (c * 3 + r) % pal.size(), "robot_count": 30 + c})
			supply.append({"front": pv[0], "preview": pv, "remaining": 9})
		scr.configure(BoardState.from_level_data(res.level_data), pal, [], supply)
		await _frames(8)
		await _board_shots(s2, scr, "59x59_" + tag, func(on): ColorSymbols.set_enabled(on, self))
		s2.free()

func _board_shots(sub: SubViewport, scr, stem: String, set_on: Callable) -> void:
	var r = scr.get_presentation().get_renderer()
	var m: ShaderMaterial = r.get_board_material()
	var span: float = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), "glyph_span")
	var min_px: float = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), "min_glyph_px")
	var ppc: float = r.get_cell_size() * absf(r.get_global_transform().get_scale().x)
	print("%s: %.2f px per cell, glyph %.2f px (%s; before: %.2f px)" % [stem, ppc, ppc * span, "drawn" if ppc * span >= min_px else "hidden, magnifier", ppc * 0.8])
	var rect := Rect2i(scr.get_board_rect())
	for state in ["off", "on", "before"]:
		set_on.call(state != "off")
		if state == "before":
			for k in PRE_OPTIN:
				m.set_shader_parameter(k, PRE_OPTIN[k])
		await _frames(4)
		var img := sub.get_texture().get_image()
		var path := _out + "m50optin_%s_%s" % [stem, state]
		img.save_jpg(path + ".jpg", 0.9)
		img.get_region(rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))).save_png(path + "_board.png")
		print("saved %s.jpg + _board.png" % path)
	for k in PRE_OPTIN:
		m.set_shader_parameter(k, RenderingServer.shader_get_parameter_default(m.shader.get_rid(), k))
	set_on.call(false)

func _legend() -> void:
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	var s := _sub(Vector2i(4 * 170 + 20, 4 * 190 + 20))
	var bg := ColorRect.new()
	bg.color = Color("#202533")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.add_child(bg)
	var i := 0
	for c in pal["colors"]:
		var t: ColorBatchTile = ColorBatchTile.new()
		t.position = Vector2(20 + (i % 4) * 170, 20 + (i / 4) * 190)
		t.size = Vector2(150, 130)
		s.add_child(t)
		t.set_batch(Color.html(String(c["hex"])), String(c["id"]).substr(1))
		var l := Label.new()
		l.text = "%s %s" % [c["id"], c["name"]]
		l.position = t.position + Vector2(0, 134)
		l.add_theme_font_size_override("font_size", 18)
		s.add_child(l)
		i += 1
	await _frames(6)
	_shot(s, "m50_symbol_legend", 1.0)
	s.free()

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _shot(sub: SubViewport, stem: String, scale: float = 0.5) -> void:
	var img := sub.get_texture().get_image()
	if scale != 1.0:
		img.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var path := _out + stem + ".jpg"
	img.save_jpg(path, 0.82)
	print("saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
