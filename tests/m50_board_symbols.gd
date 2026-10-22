extends SceneTree
## M50-BOARD (SB-M50-002 board part, owner 2026-10-15): per-cell colour symbols on the real
## pixel-art board, the COLOR SYMBOLS setting and the press-and-hold board magnifier.
## SB-M50-OPTIN-001 (owner 2026-10-22): symbols are opt-in (default OFF) and small (glyph_span 0.5,
## hidden below min_glyph_px on screen); cases that check glyphs switch them ON explicitly.
##   b01 glyph atlas: 16 tiles == the Supply/Slot shapes (same _parts), halo contains the shape,
##       empty tile margin (no mipmap bleed); built once (cached)
##   b02 board ink: WCAG pick per colour, ink / halo contrast on all 16 colours
##   b03 identity map on real L7 pigeon + 20x20 / 32x32 / 40x24 / 53x59 / 59x59, two palette orders
##       and a VOID level: every ACTIVE cell -> its canonical C-ID; VOID -> none; base pixels
##       unchanged; shader gates glyphs behind the CLEARED alpha test; no child nodes
##   b04 COLOR SYMBOLS setting: default OFF, persisted, optional in old saves, strict bool, live
##       toggle repaints board + tiles + renderer material; Settings panel toggle drives AppState
##   b05 lifecycle: clear (texel alpha 0, identity kept), reset, relayout (identity-stable
##       renderer), reconfigure with another palette order -> no stale identities
##   b06 real app root, L7 production gameplay: board symbols ON, magnifier covers exactly the board,
##       no Supply hit rect overlaps it, press/drag/release through real input events, zoom
##       >= 24 px per cell, same texture + material, zero gameplay mutation; Supply tap still works
##   b07 cost at 59x59: refresh_all / update_cells / atlas build bounds, constant node count
##   b08 GPU readback (needs a rendering driver; NOT_RUN under --headless): glyph ink visible
##       inside ACTIVE cells and confined to the central glyph square, rendered ink mask == the
##       cell's OWN C-ID shape (not the next one), CLEARED cells show exactly the BG01 backdrop,
##       default / OFF == pure pixel art, no glyph below 10 px per cell
##
## Run: godot --headless --path . -s res://tests/m50_board_symbols.gd   (b08 windowed: no --headless)

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ColorSymbols = preload("res://scripts/ui/color_symbols.gd")
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")
const BG01 := Color(0x202533ff)

var EXPECTED_CASES := ["b01_atlas", "b02_ink_contrast", "b03_identity_map", "b04_setting", "b05_lifecycle",
	"b06_real_l7_magnifier", "b07_cost", "b08_gpu_readback"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _v3 := PackedStringArray()
var _sub: SubViewport
var _root = null
var _default_symbols := true

func _initialize() -> void:
	await process_frame
	_default_symbols = ColorSymbols.enabled
	MainScript.boot_opening_override = 0
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append(String(c["hex"]))
	_b01()
	_b02()
	_b03()
	await _b04()
	await _b05()
	await _b06()
	_b07()
	await _b08()
	_shutdown()
	_cleanup()
	_done()

func _b01() -> void:
	print("[b01 glyph atlas == Supply/Slot shapes]")
	var t0 := Time.get_ticks_usec()
	var img := ColorSymbols.build_atlas_image()
	var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var n := ColorSymbols.ATLAS_TILE
	_ok(img.get_width() == 16 * n and img.get_height() == n and img.has_mipmaps() and img.get_format() == Image.FORMAT_RG8, "one %dx%d RG8 mipmapped atlas, 16 tiles (built in %.1f ms)" % [img.get_width(), img.get_height(), build_ms])
	var ok_match := true
	var ok_halo := true
	var ok_margin := true
	var cover: Array = []
	for i in range(16):
		var shape := String(ColorSymbols.SHAPE_BY_CID["C%02d" % (i + 1)])
		var parts := ColorSymbols._parts(shape)
		var on := 0
		for y in range(n):
			for x in range(n):
				var px := img.get_pixel(i * n + x, y)
				var p := Vector2((x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5) * ColorSymbols.ATLAS_SPAN
				ok_match = ok_match and (px.r > 0.5) == _inside(parts, p)
				ok_halo = ok_halo and (px.r <= 0.5 or px.g > 0.5)
				if x == 0 or y == 0 or x == n - 1 or y == n - 1:
					ok_margin = ok_margin and px.g < 0.5
				on += 1 if px.r > 0.5 else 0
		cover.append(on)
	_ok(ok_match, "every atlas texel == point-in-shape of the SAME ColorSymbols._parts() the tiles draw (16 shapes)")
	_ok(ok_halo, "halo channel contains the whole shape (outline on any face)")
	_ok(ok_margin, "tile borders empty: no neighbour bleed under mipmapping")
	_ok(cover.all(func(c): return c > n * n / 12), "every shape has real coverage %s" % str(cover))
	_ok(ColorSymbols.board_atlas() == ColorSymbols.board_atlas(), "atlas built once and cached")
	_complete("b01_atlas")

func _b02() -> void:
	print("[b02 board symbol ink contrast]")
	var worst := 99.0
	var worst_id := ""
	var halo_worst := 99.0
	for hex in _v3:
		var face := Color.html(hex)
		var dark := BoardRenderer.symbol_ink_is_dark(face)
		var ink: Color = BoardRenderer.SYMBOL_INK_DARK if dark else BoardRenderer.SYMBOL_INK_LIGHT
		var halo: Color = BoardRenderer.SYMBOL_INK_LIGHT if dark else BoardRenderer.SYMBOL_INK_DARK
		var c := BoardRenderer._contrast(face, ink)
		var h := BoardRenderer._contrast(ink, face.lerp(halo, 0.5))
		print("    %s %s ink=%s %.2f:1 (ink vs halo-mixed rim %.2f:1)" % [ColorSymbols.cid_for_color(face), hex, "dark" if dark else "white", c, h])
		if c < worst:
			worst = c
			worst_id = ColorSymbols.cid_for_color(face)
		halo_worst = minf(halo_worst, h)
	_ok(worst >= 3.0, "board glyph ink vs its pixel colour >= 3:1 on all 16 colours (weakest %s %.2f:1)" % [worst_id, worst])
	_ok(halo_worst >= 3.0, "glyph ink vs its halo rim >= 3:1 on all 16 colours (weakest %.2f:1)" % halo_worst)
	var code: String = load("res://scripts/gameplay/board/board_pixel_grid.gdshader").code
	_ok(code.find("vec3(0.03, 0.04, 0.09)") != -1 and BoardRenderer.SYMBOL_INK_DARK == Color(0.03, 0.04, 0.09) and BoardRenderer.SYMBOL_INK_LIGHT == Color(1, 1, 1), "shader ink defaults == the inks the contrast check uses")
	_complete("b02_ink_contrast")

func _b03() -> void:
	print("[b03 per-cell identity map]")
	ColorSymbols.enabled = true   # opt-in: the identity map is checked with symbols ON
	var rev := PackedStringArray()
	for i in range(_v3.size() - 1, -1, -1):
		rev.append(_v3[i])
	var res = LevelLoader.load_from_path("res://data/levels/level_007_pigeon.json")
	_ok(res.is_ok(), "real L7 pigeon loads")
	var boards: Array = [["L7 pigeon", BoardState.from_level_data(res.level_data), res.level_data.palette]]
	for d in [Vector2i(20, 20), Vector2i(32, 32), Vector2i(40, 24), Vector2i(53, 59), Vector2i(59, 59)]:
		for p in [_v3, rev]:
			boards.append(["%dx%d %s" % [d.x, d.y, "V3" if p == _v3 else "reversed"], _board(d.x, d.y, p), p])
	boards.append(["30x30 VOID ring", _void_board(30, 30), _v3])
	var ok := true
	var ok_px := true
	var cells := 0
	var voids := 0
	var nodes := 0
	for b in boards:
		var board: BoardState = b[1]
		var pal: PackedStringArray = b[2]
		var r: BoardRenderer = BoardRenderer.new()
		r.configure(board, pal, Vector2(board.get_width(), board.get_height()) * 8.0)
		var m: ShaderMaterial = r.get_board_material()
		ok = ok and r.are_symbols_shown() and m != null and bool(m.get_shader_parameter("symbols_on")) and m.get_shader_parameter("glyph_atlas") == ColorSymbols.board_atlas()
		for y in range(board.get_height()):
			for x in range(board.get_width()):
				var i := board.get_cell_index(x, y)
				var want := 0
				if board.is_void(i):
					voids += 1
					ok_px = ok_px and r.get_pixel_color(x, y).a == 0.0
				else:
					var col := Color.html(pal[board.get_color_id(i)])
					want = ColorSymbols.cid_index_for_color(col)
					ok = ok and want > 0 and ColorSymbols.SHAPE_BY_CID["C%02d" % want] == ColorSymbols.shape_for_color(col)
					ok_px = ok_px and r.get_pixel_color(x, y) == Color(col.r, col.g, col.b, 1.0)
					cells += 1
				ok = ok and r.get_cell_symbol_cid(x, y) == want
		nodes += r.get_child_count()
		print("    %s: %dx%d, %d colours" % [b[0], board.get_width(), board.get_height(), pal.size()])
		r.free()
	_ok(ok, "%d ACTIVE cells over %d boards carry their CANONICAL C-ID (Supply/Slot shape), local palette order irrelevant; %d VOID cells none" % [cells, boards.size(), voids])
	_ok(ok_px, "base pixel RGB / alpha unchanged (ACTIVE = exact palette colour, VOID transparent)")
	_ok(nodes == 0, "no child nodes on any renderer (no per-cell nodes)")
	var code: String = load("res://scripts/gameplay/board/board_pixel_grid.gdshader").code
	_ok(code.find("base.a < 0.5") != -1 and code.find("base.a < 0.5") < code.find("if (symbols_on"), "shader returns transparent for CLEARED / VOID texels BEFORE any glyph is drawn")
	_ok(code.find("uniform float glyph_span = 0.5;") != -1 and code.find("uniform float min_glyph_px = 5.0;") != -1 and code.find("if (symbols_on && ppc * glyph_span >= min_glyph_px)") != -1, "shader: glyph_span 0.5, min_glyph_px 5.0, glyph drawn only when ppc * glyph_span >= min_glyph_px")
	_complete("b03_identity_map")

func _b04() -> void:
	print("[b04 COLOR SYMBOLS setting]")
	_ok(not _default_symbols, "process default: ColorSymbols.enabled OFF before any setting is applied")
	var path := _path("setting")
	var app = AppState.new(path)
	_ok(not app.effects.is_color_symbols(), "new profile: COLOR SYMBOLS default OFF (opt-in)")
	_ok(app.set_color_symbols(true).get("ok", false), "ON saves")
	var r1 = AppState.new(path)
	_ok(r1.load_result.get("source") == "primary" and r1.effects.is_color_symbols(), "relaunch: ON restored")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ok(saved["settings"]["effects"] == {"reduced": false, "color_symbols": true, "color_symbols_optin": true}, "canonical save carries settings.effects.color_symbols (exact bool) + color_symbols_optin marker")
	r1.set_color_symbols(false)
	_ok(not AppState.new(path).effects.is_color_symbols(), "relaunch: OFF restored")
	var base := {"schema": "scrubbots.save", "version": 1,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}, "effects": {"reduced": true}},
		"progression": app.progression.snapshot(), "economy": app.economy.snapshot()}
	var old := _path("pre_m50")
	var f := FileAccess.open(old, FileAccess.WRITE)
	f.store_string(JSON.stringify(base))
	f.close()
	var r2 = AppState.new(old)
	_ok(r2.load_result.get("source") == "primary" and not r2.effects.is_color_symbols() and r2.effects.is_reduced(), "pre-M50 save (no color_symbols key) loads: symbols OFF, Reduced Effects kept")
	var rej := 0
	var bads: Array = [1, 0, "true", null, [], {}]
	for bad in bads:
		var c: Dictionary = base.duplicate(true)
		c["settings"]["effects"]["color_symbols"] = bad
		if app.save.validate_candidate(c).get("reason") == "effects_malformed":
			rej += 1
	_ok(rej == bads.size(), "non-bool color_symbols rejects the whole candidate (%d/%d)" % [rej, bads.size()])
	# Live toggle from the default OFF: board renderer material + tiles.
	ColorSymbols.enabled = false
	_new_sub(Vector2i(1080, 2160))
	var scr = GameplayScreen.new()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(scr)
	scr.configure(_board(32, 32, _v3), _v3, [], _supply(4))
	await _frames(3)
	var rend = scr.get_presentation().get_renderer()
	var tile: ColorBatchTile = scr.get_supply_panel()._columns[0]["rows"][0]["tile"]
	var off0: bool = not rend.are_symbols_shown() and bool(rend.get_board_material().get_shader_parameter("symbols_on")) == false and tile.get_symbol_shape() == ""
	ColorSymbols.set_enabled(true, self)
	var on_ok: bool = rend.are_symbols_shown() and bool(rend.get_board_material().get_shader_parameter("symbols_on")) and tile.get_symbol_shape() != ""
	ColorSymbols.set_enabled(false, self)
	var off_ok: bool = not rend.are_symbols_shown() and bool(rend.get_board_material().get_shader_parameter("symbols_on")) == false and tile.get_symbol_shape() == ""
	_ok(off0 and on_ok and off_ok, "live toggle from OFF: board shader + Supply tiles ON together, back OFF together (no rebuild)")
	_shutdown()
	# Real app root: Settings toggle -> canonical AppState -> ColorSymbols.
	await _boot("b04")
	_root.open_settings()
	await _frames(3)
	var panel = _root.get_settings_panel()
	var t: CheckButton = panel.get_color_symbols_toggle() if panel != null else null
	var a = _root.get_app_state()
	var ok: bool = t != null and not t.button_pressed and not a.effects.is_color_symbols() and not ColorSymbols.enabled and t.text == "COLOR SYMBOLS" and t.custom_minimum_size.y >= 88
	if t != null:
		t.button_pressed = true
		ok = ok and a.effects.is_color_symbols() and ColorSymbols.enabled
		t.button_pressed = false
		ok = ok and not a.effects.is_color_symbols() and not ColorSymbols.enabled
	_ok(ok, "Settings COLOR SYMBOLS switch (>= 88 px, OFF after boot) drives AppState and the live symbol flag ON / OFF")
	var hint: Label = panel.find_child("ColorSymbolsHint", true, false) if panel != null else null
	_ok(hint != null and hint.text.find("color-blind") != -1 and hint.text.find("hold the board") != -1, "color-blind + magnifier hint under the switch: '%s'" % (hint.text if hint != null else ""))
	_shutdown()
	_complete("b04_setting")

func _b05() -> void:
	print("[b05 lifecycle: clear / reset / relayout / palette change]")
	ColorSymbols.enabled = true
	var board := _board(24, 24, _v3)
	var pres = BoardPresentation.new()
	get_root().add_child(pres)
	pres.configure(board, _v3, Vector2(24 * 10, 24 * 10))
	var r = pres.get_renderer()
	var before: Array = _cids(r, board)
	var idx := board.get_cell_index(3, 4)
	board.set_cell_state(idx, BoardState.CellState.CLEARED)
	r.update_cells([idx])
	_ok(r.get_pixel_color(3, 4).a == 0.0 and _cids(r, board) == before, "clear: texel alpha 0 (shader drops the glyph), identity map unchanged, neighbours intact")
	board.restore_all_active()
	r.refresh_all()
	_ok(r.get_pixel_color(3, 4).a == 1.0 and _cids(r, board) == before and r.are_symbols_shown(), "reset: cell ACTIVE again with the same symbol")
	pres.configure(board, _v3, Vector2(24 * 20, 24 * 20))
	_ok(pres.get_renderer() == r and _cids(r, board) == before and r.get_board_material().get_shader_parameter("cid_map") != null, "relayout: same renderer, same identities")
	var rev := PackedStringArray()
	for i in range(_v3.size() - 1, -1, -1):
		rev.append(_v3[i])
	pres.configure(board, rev, Vector2(24 * 20, 24 * 20))
	var ok := true
	for y in range(24):
		for x in range(24):
			ok = ok and r.get_cell_symbol_cid(x, y) == ColorSymbols.cid_index_for_color(Color.html(rev[board.get_color_id(board.get_cell_index(x, y))]))
	_ok(ok and _cids(r, board) != before, "palette order changed: every cell re-resolved, no stale identity")
	pres.free()
	_complete("b05_lifecycle")

func _b06() -> void:
	print("[b06 real app root, L7 production gameplay + magnifier]")
	await _boot("b06")
	_ok(not ColorSymbols.enabled and _root.get_app_state().set_color_symbols(true).get("ok", false) and ColorSymbols.enabled, "fresh profile boots OFF; the player opts in")
	_root.get_app_state().progression.debug_set_current_level(7)
	_root.play_current_frontier()
	await _frames(8)
	var host = _root.get_gameplay_host()
	_ok(host != null and host.get_level() != null and String(host.get_level().id) == "level_007_pigeon", "L7 pigeon entered from the real app root")
	if host == null:
		_complete("b06_real_l7_magnifier")
		return
	host.get_runtime().set_process(false)
	var scr = host.get_screen()
	var board = host.get_board()
	var r = scr.get_presentation().get_renderer()
	var ok: bool = r.are_symbols_shown() and r.is_bound_to(board)
	var pal: PackedStringArray = host.get_level().palette
	var active := 0
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var i: int = board.get_cell_index(x, y)
			if board.is_void(i):
				continue
			active += 1
			ok = ok and r.get_cell_symbol_cid(x, y) == ColorSymbols.cid_index_for_color(Color.html(pal[board.get_color_id(i)]))
	_ok(ok and active > 0, "L7 production board: %d artwork cells carry their canonical symbol" % active)
	var mag = scr.get_board_magnifier()
	var mrect := Rect2(mag.global_position, mag.size)
	_ok(mrect.position.distance_to(scr.get_board_rect().position) < 0.5 and mrect.size.distance_to(scr.get_board_rect().size) < 0.5 and mag.mouse_filter == Control.MOUSE_FILTER_STOP, "magnifier covers exactly the board rect %s" % str(mrect))
	var sp = scr.get_supply_panel()
	var overlap := false
	for c in range(sp.get_column_count()):
		overlap = overlap or sp.get_front_hit_rect(c).intersects(mrect)
	for rect in [scr.get_pause_rect(), scr.get_speed_control_rect(), scr.get_booster_row_rect(), scr.get_five_slot_strip_rect()]:
		overlap = overlap or rect.intersects(mrect)
	_ok(not overlap, "no Supply front hit rect, slot strip, booster row, Pause or 2x overlaps the magnifier")
	var states0: PackedByteArray = board.get_cell_states_copy()
	var sup0 = host.get_supply().debug_snapshot()
	var slots0 = host.get_slots().snapshot()
	var centre: Vector2 = scr.cell_center_to_global(12, 10)
	_click(centre, true)
	await _frames(2)
	var z: float = mag.get_zoom_cell()
	var shown: float = r.get_cell_size() * absf(r.get_global_transform().get_scale().x)
	_ok(mag.is_inspecting() and mag.get_focus_cell() == Vector2i(12, 10), "press on the board shows the loupe on the pressed cell %s" % str(mag.get_focus_cell()))
	_ok(z >= 24.0 and z >= shown * 2.0, "loupe: %.1f px per cell (board cell %.1f px)" % [z, shown])
	_ok(mag.get_zoom_view().texture == r.texture and mag.get_zoom_view().material == r.material, "loupe draws the renderer's own texture + symbol material (same symbols, same holes)")
	var mv := InputEventMouseMotion.new()
	mv.position = scr.cell_center_to_global(20, 15)
	mv.global_position = mv.position
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	_sub.push_input(mv)
	await _frames(2)
	_ok(mag.get_focus_cell() == Vector2i(20, 15), "drag moves the loupe to %s" % str(mag.get_focus_cell()))
	var lr := Rect2(mag.get_loupe().global_position, mag.get_loupe().size)
	_ok(Rect2(Vector2.ZERO, Vector2(_sub.size)).encloses(lr), "loupe stays on screen %s" % str(lr))
	_click(scr.cell_center_to_global(20, 15), false)
	await _frames(2)
	_ok(not mag.is_inspecting() and mag.get_zoom_view().texture == null, "release hides the loupe")
	_ok(board.get_cell_states_copy() == states0 and host.get_supply().debug_snapshot() == sup0 and host.get_slots().snapshot() == slots0, "inspect changed no board cell, supply or slot state")
	# The Supply one-tap still lands (real input, outside the magnifier).
	var front: Rect2 = sp.get_front_hit_rect(0)
	_click(front.get_center(), true)
	await _frames(1)
	_click(front.get_center(), false)
	for _i in range(10):
		await process_frame
		if host.get_slots().snapshot() != slots0:
			break
	_ok(not mag.is_inspecting() and host.get_slots().snapshot() != slots0, "a Supply front tap still places its batch (magnifier untouched; modals open %d)" % _root.get_modal_stack().depth())
	_shutdown()
	_complete("b06_real_l7_magnifier")

func _b07() -> void:
	print("[b07 cost at 59x59]")
	ColorSymbols.enabled = true
	var board := _board(59, 59, _v3)
	var r: BoardRenderer = BoardRenderer.new()
	get_root().add_child(r)
	r.configure(board, _v3, Vector2(59 * 13, 59 * 13))
	var t0 := Time.get_ticks_usec()
	for _i in range(20):
		r.refresh_all()
	var full_ms := (Time.get_ticks_usec() - t0) / 20000.0
	var map0 = r.get_board_material().get_shader_parameter("cid_map")
	t0 = Time.get_ticks_usec()
	for _i in range(5):
		r.configure(board, _v3, Vector2(59 * 13, 59 * 13))
	var relayout_ms := (Time.get_ticks_usec() - t0) / 5000.0
	var kept: bool = r.get_board_material().get_shader_parameter("cid_map") == map0
	t0 = Time.get_ticks_usec()
	for _i in range(5):
		r._cid_texture = null
		r._rebuild_symbol_map(_v3)
	var map_ms := (Time.get_ticks_usec() - t0) / 5000.0
	t0 = Time.get_ticks_usec()
	for i in range(200):
		r.update_cells([i])
	var upd_ms := (Time.get_ticks_usec() - t0) / 200000.0
	t0 = Time.get_ticks_usec()
	ColorSymbols.build_atlas_image()
	var atlas_ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("    refresh_all %.2f ms, relayout configure %.2f ms, identity map build %.2f ms, update_cells %.3f ms, atlas build %.1f ms" % [full_ms, relayout_ms, map_ms, upd_ms, atlas_ms])
	_ok(full_ms < 40.0, "59x59 refresh_all (colour texels only, as before): %.2f ms" % full_ms)
	_ok(kept, "relayout (same board + palette) reuses the identity map: no rebuild, %.2f ms per configure" % relayout_ms)
	_ok(map_ms < 40.0, "identity map build once per board / palette: %.2f ms" % map_ms)
	_ok(upd_ms < 2.0, "update_cells unchanged path (identity map untouched): %.3f ms" % upd_ms)
	_ok(atlas_ms < 1500.0, "one-time atlas build %.1f ms (cached for the process)" % atlas_ms)
	_ok(r.are_symbols_shown() and r.get_child_count() == 0 and r.find_children("*", "", true, false).is_empty(), "3,481 cells, symbols ON: ONE TextureRect, 0 child nodes")
	r.free()
	_complete("b07_cost")

func _b08() -> void:
	print("[b08 GPU readback]")
	if DisplayServer.get_name() == "headless":
		print("    NOT_RUN: headless (no rendering driver); run windowed for the rendered-pixel proof")
		_complete("b08_gpu_readback")
		return
	ColorSymbols.enabled = _default_symbols   # the process default (OFF)
	var cs := 48                               # large cells keep the 0.5-span glyph measurable
	var board := _board(20, 20, _v3)
	board.set_cell_state(board.get_cell_index(5, 5), BoardState.CellState.CLEARED)
	var r: BoardRenderer = await _render(board, 20 * cs)
	var m: ShaderMaterial = r.get_board_material()
	var span: float = float(RenderingServer.shader_get_parameter_default(m.shader.get_rid(), "glyph_span"))
	var min_px: float = float(RenderingServer.shader_get_parameter_default(m.shader.get_rid(), "min_glyph_px"))
	_ok(int(r.get_cell_size()) == cs and is_equal_approx(span, 0.5) and is_equal_approx(min_px, 5.0), "rendered at %d px per cell; shader defaults glyph_span %.2f, min_glyph_px %.1f" % [int(r.get_cell_size()), span, min_px])
	var img_def := await _snap()
	ColorSymbols.set_enabled(true, self)
	var img := await _snap()
	# Pure-art reference: symbols_on stays true but the size gate suppresses every glyph.
	m.set_shader_parameter("min_glyph_px", 1.0e9)
	var img_ref := await _snap()
	m.set_shader_parameter("min_glyph_px", min_px)
	ColorSymbols.set_enabled(false, self)
	var img_off := await _snap()
	_ok(bool(m.get_shader_parameter("symbols_on")) == false and img_def.get_data() == img_ref.get_data() and img_off.get_data() == img_ref.get_data(), "default (OFF) and toggled-OFF renders are pixel-identical to the glyph-free board: no glyph pixels")
	_ok(img.get_data() != img_ref.get_data(), "symbols ON changes the render")
	var marked := 0
	var checked := 0
	var ring_bad := 0
	var widest := 0
	var lo := int(cs * 0.2)
	var hi := int(cs * 0.8)
	for y in range(20):
		for x in range(20):
			if x == 5 and y == 5:
				continue
			var face := Color.html(_v3[board.get_color_id(board.get_cell_index(x, y))])
			var ink: Color = BoardRenderer.SYMBOL_INK_DARK if BoardRenderer.symbol_ink_is_dark(face) else BoardRenderer.SYMBOL_INK_LIGHT
			var near := 0
			var bb := Rect2i()
			var any := false
			for py in range(cs):
				for px in range(cs):
					var c := img.get_pixel(x * cs + px, y * cs + py)
					if c == img_ref.get_pixel(x * cs + px, y * cs + py):
						continue
					if px < lo or px >= hi or py < lo or py >= hi:
						ring_bad += 1
					bb = bb.expand(Vector2i(px, py)) if any else Rect2i(px, py, 1, 1)
					any = true
					if Vector3(c.r - ink.r, c.g - ink.g, c.b - ink.b).length() < 0.3:   # ink_alpha 0.85 leaves <= 0.26 of the face/halo
						near += 1
			widest = maxi(widest, maxi(bb.size.x + 1, bb.size.y + 1) if any else 0)
			checked += 1
			marked += 1 if near >= 6 else 0
	_ok(marked == checked, "%d/%d rendered ACTIVE cells show symbol ink pixels inside the cell" % [marked, checked])
	_ok(ring_bad == 0, "no glyph pixel (ink or halo) outside the central 60%% of any cell (%d stray)" % ring_bad)
	_ok(widest > 0 and widest <= int(cs * 0.55), "glyph bounding box at most %d px of a %d px cell (widest %d px = %.2f of the side)" % [int(cs * 0.55), cs, widest, float(widest) / cs])
	# Which glyph: per cell, the rendered ink mask must match ITS C-ID shape (and not the next one),
	# sampled 16x16 over the central glyph square.
	var worst_right := 1.0
	var mean_right := 0.0
	var diff_total := 0
	var diff_own := 0
	var n_cells := 0
	for y in range(20):
		for x in range(20):
			if x == 5 and y == 5:
				continue
			var face := Color.html(_v3[board.get_color_id(board.get_cell_index(x, y))])
			var cid := ColorSymbols.cid_index_for_color(face)
			var ink: Color = BoardRenderer.SYMBOL_INK_DARK if BoardRenderer.symbol_ink_is_dark(face) else BoardRenderer.SYMBOL_INK_LIGHT
			var right := ColorSymbols._parts(String(ColorSymbols.SHAPE_BY_CID["C%02d" % cid]))
			var wrong := ColorSymbols._parts(String(ColorSymbols.SHAPE_BY_CID["C%02d" % (cid % 16 + 1)]))
			var agree := 0
			var total := 0
			for sy in range(16):
				for sx in range(16):
					var gp := Vector2((sx + 0.5) / 16.0, (sy + 0.5) / 16.0)
					var fpos := Vector2(0.5, 0.5) + (gp - Vector2(0.5, 0.5)) * span
					var p := (gp - Vector2(0.5, 0.5)) * ColorSymbols.ATLAS_SPAN
					# Skip points near a shape edge (filtering blends them).
					var e := 0.14
					var want := _inside(right, p)
					if [Vector2(e, 0), Vector2(-e, 0), Vector2(0, e), Vector2(0, -e)].any(func(d): return _inside(right, p + d) != want):
						continue
					var c := img.get_pixel(x * cs + int(fpos.x * cs), y * cs + int(fpos.y * cs))
					var is_ink := Vector3(c.r - ink.r, c.g - ink.g, c.b - ink.b).length() < 0.3
					agree += 1 if is_ink == want else 0
					total += 1
					# Discriminating points: own and next shape disagree here.
					if _inside(wrong, p) != want:
						diff_total += 1
						diff_own += 1 if is_ink == want else 0
			var ra := float(agree) / maxf(total, 1.0)
			worst_right = minf(worst_right, ra)
			mean_right += ra
			n_cells += 1
	mean_right /= n_cells
	var disc := float(diff_own) / maxf(diff_total, 1.0)
	_ok(worst_right >= 0.85 and disc >= 0.9 and diff_total > 1000, "rendered glyph == the cell's own C-ID shape: mean agreement %.2f (worst cell %.2f); on %d points where it differs from the next C-ID's shape, %.0f%% follow the own shape" % [mean_right, worst_right, diff_total, disc * 100.0])
	var hole_ok := true
	for py in range(cs):
		for px in range(cs):
			var c := img.get_pixel(5 * cs + px, 5 * cs + py)
			hole_ok = hole_ok and Vector3(c.r - BG01.r, c.g - BG01.g, c.b - BG01.b).length() < 0.02
	_ok(hole_ok, "CLEARED cell: every one of its %d px is exactly the BG01 background (transparent, no ghost glyph / grid)" % (cs * cs))
	# Size gate: under 10 px per cell no glyph is drawn even with symbols ON; at 12 px it is.
	var dense := _board(59, 59, _v3)
	for side in [500, 59 * 12]:
		var rd: BoardRenderer = await _render(dense, side)
		var ppc := rd.get_cell_size() * absf(rd.get_global_transform().get_scale().x)
		ColorSymbols.set_enabled(true, self)
		var d_on := await _snap()
		ColorSymbols.set_enabled(false, self)
		var d_off := await _snap()
		var same := d_on.get_data() == d_off.get_data()
		if side == 500:
			_ok(ppc < 10.0 and same, "59x59 in %d px: %.2f px per cell (glyph %.2f px < %.0f): symbols ON draws no glyph pixel" % [side, ppc, ppc * span, min_px])
		else:
			_ok(ppc >= 10.0 and not same, "59x59 in %d px: %.2f px per cell (glyph %.2f px): glyphs drawn" % [side, ppc, ppc * span])
	_shutdown()
	_complete("b08_gpu_readback")

func _render(board: BoardState, side: int) -> BoardRenderer:
	_new_sub(Vector2i(side, side))
	# BG01 behind the board, as in gameplay: a CLEARED hole must show exactly this colour.
	var bg := ColorRect.new()
	bg.color = BG01
	bg.size = Vector2(_sub.size)
	_sub.add_child(bg)
	var r: BoardRenderer = BoardRenderer.new()
	_sub.add_child(r)
	r.configure(board, _v3, Vector2(side, side))
	await _frames(4)
	return r

func _snap() -> Image:
	await _frames(3)
	return _sub.get_texture().get_image()

# ------------------------------------------------------------------ helpers ----

func _board(w: int, h: int, pal: PackedStringArray) -> BoardState:
	var cells := PackedInt32Array()
	cells.resize(w * h)
	for y in range(h):
		for x in range(w):
			cells[y * w + x] = (x / 2 + y * 3) % pal.size()
	return BoardState.from_level_data(LevelData.new(1, "m50b_%dx%d" % [w, h], "m50b", "TEST", w, h, pal, cells))

## Version-2 level: a VOID ring around the artwork.
func _void_board(w: int, h: int) -> BoardState:
	var cells := PackedInt32Array()
	cells.resize(w * h)
	for y in range(h):
		for x in range(w):
			var edge := x < 3 or y < 3 or x >= w - 3 or y >= h - 3
			cells[y * w + x] = LevelData.VOID_CELL if edge else (x + y) % _v3.size()
	return BoardState.from_level_data(LevelData.new(2, "m50b_void", "m50b", "TEST", w, h, _v3, cells))

func _cids(r, board) -> Array:
	var out: Array = []
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			out.append(r.get_cell_symbol_cid(x, y))
	return out

func _inside(parts: Array, p: Vector2) -> bool:
	for part in parts:
		match String(part[0]):
			"poly":
				if Geometry2D.is_point_in_polygon(p, PackedVector2Array(part[1])):
					return true
			"disc":
				if p.distance_to(part[2] if part.size() > 2 else Vector2.ZERO) <= float(part[1]):
					return true
	return false

func _supply(cols: int) -> Array:
	var out: Array = []
	for c in range(cols):
		var pv: Array = []
		for r in range(3):
			pv.append({"color_id": (c * 3 + r) % 16, "robot_count": 12 + c + r})
		out.append({"front": pv[0], "preview": pv, "remaining": 9})
	return out

func _click(at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_sub.push_input(e)

func _path(tag: String) -> String:
	var p := "user://m50b_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _new_sub(size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)

func _boot(tag: String) -> void:
	_new_sub(Vector2i(1080, 2160))
	MainScript.boot_save_path_override = _path(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	ColorSymbols.enabled = _default_symbols
	ColorSymbols._atlas = null
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M50 board symbols evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
