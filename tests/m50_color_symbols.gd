extends SceneTree
## M50 owner decisions A + B (2026-10-15) and the M51 HUD price follow-up:
##   s01 symbol table == Palette V3 (16 C-IDs, 16 different shapes, every shape drawable)
##   s02 identity is the canonical colour, never the level-local palette index (all shipped levels)
##   s03 silhouettes differ (rasterised unit masks): every pair IoU < 0.75, the M50 CVD-confusable
##       pairs C01/C11, C04/C05, C02/C03 IoU < 0.5
##   s04 tile: occupied -> translucent watermark centred behind the count (count still centred),
##       visible on every colour; empty / non-canonical -> no symbol; input-transparent
##   s05 Supply 3/4/5 columns x 3 rows (front + preview) and 5/6 slots, two palettes: shape == colour
##   s06 real app root: L1 production gameplay tiles carry symbols; front hit rects >= touch min
##   s07 hero PLAY label is NAVY with WCAG >= 4.5 on normal / hover / pressed; other green
##       buttons keep their white label (scoped)
##   s08 HUD booster price via UiText key + UiText.num (English unchanged, grouped, pseudo-aware)
##   s09 cost: 300 supply rebinds (5x3) + 6 slots stay cheap; symbols never touch the board
##   s10 Tornado / Selector booster target chips carry the same colour symbol (real L1 host)
##
## Run: godot --headless --path . -s res://tests/m50_color_symbols.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")
const ColorSymbols = preload("res://scripts/ui/color_symbols.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const Audit = preload("res://tools/accessibility_audit.gd")
## Smallest acceptable symbol side in logical px (the count digits on the smallest tiles are ~40 px).
const MIN_SYMBOL_PX := 32.0

var EXPECTED_CASES := ["s01_table_matches_palette_v3", "s02_identity_not_local_index", "s03_silhouettes_distinct",
	"s04_tile_symbol_placement", "s05_supply_and_slots_modes", "s06_real_l1_gameplay", "s07_play_label_navy",
	"s08_hud_price_ui_text", "s09_cost", "s10_booster_target_chips"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _v3 := PackedStringArray()
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append(String(c["hex"]))
	_s01(pal)
	_s02()
	_s03()
	await _s04()
	await _s05()
	await _s06()
	await _s07()
	await _s08()
	await _s09()
	await _s10()
	_shutdown()
	_cleanup()
	_done()

func _s01(pal) -> void:
	print("[s01 symbol table == Palette V3]")
	var ok: bool = ColorSymbols.CID_BY_HEX.size() == pal["colors"].size()
	for c in pal["colors"]:
		ok = ok and ColorSymbols.cid_for_color(Color.html(String(c["hex"]))) == String(c["id"])
	_ok(ok and ColorSymbols.CID_BY_HEX.size() == 16, "16 canonical hex -> C-ID entries equal the palette file")
	var shapes := {}
	var drawable := true
	for cid in ColorSymbols.SHAPE_BY_CID:
		shapes[ColorSymbols.SHAPE_BY_CID[cid]] = cid
		drawable = drawable and not ColorSymbols._parts(String(ColorSymbols.SHAPE_BY_CID[cid])).is_empty()
	_ok(shapes.size() == 16 and drawable, "16 C-IDs -> 16 different, drawable shapes")
	_ok(ColorSymbols.cid_for_color(Color(1, 0, 1)) == "" and ColorSymbols.cid_for_color(Color.html("#E5484D")) == "", "non-canonical colours have no identity")
	print("    legend: %s" % str(ColorSymbols.SHAPE_BY_CID))
	_complete("s01_table_matches_palette_v3")

func _s02() -> void:
	print("[s02 identity = canonical colour across every shipped level palette]")
	var cat = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/catalog/production_catalog_v1.json"))
	var shipped := {}
	var index_of_brown := {}
	var ok := true
	for e in cat["entries"]:
		var lvl = JSON.parse_string(FileAccess.get_file_as_string(String(e["level_path"])))
		var p: Array = lvl["palette"]
		for i in range(p.size()):
			var col := Color.html(String(p[i]))
			var cid := ColorSymbols.cid_for_color(col)
			ok = ok and cid != "" and ColorSymbols.shape_for_color(col) == ColorSymbols.SHAPE_BY_CID[cid]
			shipped[cid] = true
			if cid == "C11":
				index_of_brown[String(e["id"])] = i
	var idx := {}
	for k in index_of_brown:
		idx[index_of_brown[k]] = true
	_ok(ok and cat["entries"].size() >= 10, "every colour of %d production levels resolves to a canonical C-ID and its fixed shape" % cat["entries"].size())
	_ok(idx.size() >= 2, "brown C11 sits at different local indices %s yet always maps to '%s'" % [str(index_of_brown), ColorSymbols.SHAPE_BY_CID["C11"]])
	var ids := shipped.keys()
	ids.sort()
	print("    shipped identities (%d): %s" % [ids.size(), str(ids)])
	_ok(ids.size() >= 15, "%d shipped colour identities all covered" % ids.size())
	_complete("s02_identity_not_local_index")

func _s03() -> void:
	print("[s03 silhouettes pairwise distinct (unit masks 32x32)]")
	var masks := {}
	for cid in ColorSymbols.SHAPE_BY_CID:
		masks[cid] = _mask(String(ColorSymbols.SHAPE_BY_CID[cid]))
	var worst := 0.0
	var worst_pair := ""
	var ids: Array = masks.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var u := _iou(masks[ids[i]], masks[ids[j]])
			if u >= 0.5:
				print("    close pair %s/%s IoU %.2f" % [ids[i], ids[j], u])
			if u > worst:
				worst = u
				worst_pair = "%s/%s" % [ids[i], ids[j]]
	_ok(worst < 0.75, "max IoU %.2f (%s) over all 120 pairs" % [worst, worst_pair])
	# The M50 CVD findings: protan C01/C11 (dE00 3.3), tritan C04/C05 (3.8), deutan C02/C03 (6.7).
	for pair in [["C01", "C11"], ["C04", "C05"], ["C02", "C03"]]:
		var u := _iou(masks[pair[0]], masks[pair[1]])
		_ok(u < 0.5, "CVD-confusable %s '%s' vs %s '%s' IoU %.2f" % [pair[0], ColorSymbols.SHAPE_BY_CID[pair[0]], pair[1], ColorSymbols.SHAPE_BY_CID[pair[1]], u])
	_complete("s03_silhouettes_distinct")

func _s04() -> void:
	print("[s04 tile: centred watermark behind the count, empty / non-canonical clean, input-transparent]")
	_new_sub(Vector2i(400, 400))
	var t: ColorBatchTile = ColorBatchTile.new()
	t.size = Vector2(150, 130)
	_sub.add_child(t)
	var ok := true
	for sz in [Vector2(150, 130), Vector2(96, 92), Vector2(120, 150)]:
		t.size = sz
		for hex in _v3:
			for txt in ["7", "88", "123"]:
				t.set_batch(Color.html(hex), txt)
				await process_frame
				var f := t.get_face_rect_global()
				var s := t.get_symbol_control().get_global_rect()
				var sym: Control = t.get_symbol_control()
				ok = ok and t.get_symbol_shape() == ColorSymbols.shape_for_color(Color.html(hex)) and t.get_symbol_shape() != ""
				ok = ok and f.encloses(s) and s.get_center().distance_to(f.get_center()) <= 1.0 and s.size.x >= minf(f.size.x, f.size.y) * 0.75
				ok = ok and sym.get_index() < t.get_count_label().get_index() and sym.get_parent() == t.get_count_label().get_parent()
				ok = ok and t.get_count_center_delta().length() <= 1.0 and t.get_count_text() == txt
	_ok(ok, "16 colours x 1-3 digits x 3 tile sizes: watermark centred on the face, >= 75% of its short side, drawn BEHIND the count; count exact and centred")
	var weakest := 99.0
	var weakest_id := ""
	for hex in _v3:
		var face := Color.html(hex)
		var ink := ColorSymbols.watermark_ink(face)
		var mixed := face.lerp(Color(ink.r, ink.g, ink.b), ink.a)
		var cr: float = Audit.contrast_ratio(mixed, face)
		if cr < weakest:
			weakest = cr
			weakest_id = ColorSymbols.cid_for_color(face)
	_ok(weakest >= 1.3, "watermark vs face luminance contrast >= 1.3:1 on all 16 colours (weakest %s %.2f:1; dark ink on light faces)" % [weakest_id, weakest])
	t.set_empty()
	await process_frame
	var empty_ok := t.get_symbol_shape() == "" and not t.get_symbol_control().is_visible_in_tree()
	t.set_batch(Color(1, 0, 1), "5")
	_ok(empty_ok and t.get_symbol_shape() == "", "EMPTY and non-canonical tiles show no symbol")
	_ok(t.get_symbol_control().mouse_filter == Control.MOUSE_FILTER_IGNORE, "symbol never takes input")
	_shutdown()
	_complete("s04_tile_symbol_placement")

func _s05() -> void:
	print("[s05 Supply 3/4/5 x 3 rows + 5/6 slots, V3 order and reversed palette]")
	var rev := PackedStringArray()
	for i in range(_v3.size() - 1, -1, -1):
		rev.append(_v3[i])
	var checked := 0
	var ok := true
	var min_side := 9999.0
	for run in [[_v3, Vector2i(1080, 2160)], [rev, Vector2i(1080, 2160)], [_v3, Vector2i(720, 1280)], [_v3, Vector2i(1440, 3200)], [_v3, Vector2i(1536, 2048)]]:
		var pal: PackedStringArray = run[0]
		for cols in [3, 4, 5]:
			for cap in [5, 6]:
				var scr = await _screen(run[1], pal, cols, cap)
				var sp = scr.get_supply_panel()
				for c in range(sp.get_column_count()):
					for r in range(3):
						var tile: ColorBatchTile = sp._columns[c]["rows"][r]["tile"]
						var want := ColorSymbols.shape_for_color(Color.html(pal[(c * 3 + r) % 16]))
						ok = ok and tile.get_symbol_shape() == want and want != "" and tile.get_count_text() == str(12 + c + r)
						min_side = minf(min_side, tile.get_symbol_control().get_global_rect().size.x)
						if tile.get_symbol_control().get_global_rect().size.x < MIN_SYMBOL_PX:
							print("    small supply: %s cols %d cap %d row %d face %s side %.1f" % [str(run[1]), cols, cap, r, str(tile.get_face_rect_global().size), tile.get_symbol_control().get_global_rect().size.x])
						checked += 1
				var views: Array = scr.get_five_slot_strip().get_slot_views()
				for i in range(views.size()):
					var tile: ColorBatchTile = views[i].get_tile()
					var want := ColorSymbols.shape_for_color(Color.html(pal[i])) if i < 4 else ""
					ok = ok and tile.get_symbol_shape() == want
					if want != "":
						min_side = minf(min_side, tile.get_symbol_control().get_global_rect().size.x)
						if tile.get_symbol_control().get_global_rect().size.x < MIN_SYMBOL_PX:
							print("    small slot: %s cols %d cap %d face %s side %.1f" % [str(run[1]), cols, cap, str(tile.get_face_rect_global().size), tile.get_symbol_control().get_global_rect().size.x])
					checked += 1
				ok = ok and views.size() == cap
				_shutdown()
	_ok(ok, "%d tiles at 1080x2160 (two palettes), 720x1280, 1440x3200, 1536x2048: occupied front + preview + slots show their colour's shape; empty slots none" % checked)
	_ok(min_side >= MIN_SYMBOL_PX, "smallest occupied-tile symbol %.1f px (>= %d) on compact / tall / tablet viewports" % [min_side, MIN_SYMBOL_PX])
	_complete("s05_supply_and_slots_modes")

func _s06() -> void:
	print("[s06 real app root: L1 production gameplay]")
	await _boot("s06")
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	_ok(host != null, "L1 gameplay entered from the real app root")
	if host == null:
		_complete("s06_real_l1_gameplay")
		return
	host.get_runtime().set_process(false)
	var scr = host.get_screen()
	var sp = scr.get_supply_panel()
	var occupied := 0
	var ok := true
	for c in range(sp.get_column_count()):
		for r in range(3):
			var tile: ColorBatchTile = sp._columns[c]["rows"][r]["tile"]
			if tile.is_empty_tile():
				ok = ok and tile.get_symbol_shape() == ""
			else:
				occupied += 1
				ok = ok and tile.get_symbol_shape() == ColorSymbols.shape_for_color(tile.get_face_color()) and tile.get_symbol_shape() != ""
	var hits := true
	for c in range(sp.get_column_count()):
		var hr: Rect2 = sp.get_front_hit_rect(c)
		hits = hits and hr.size.x >= UiTokens.TOUCH_MIN - 0.5 and hr.size.y >= UiTokens.TOUCH_MIN - 0.5
	_ok(ok and occupied > 0, "%d occupied L1 supply tiles carry their colour's shape" % occupied)
	_ok(hits, "front hit rects still >= %d px" % UiTokens.TOUCH_MIN)
	_complete("s06_real_l1_gameplay")

func _s07() -> void:
	print("[s07 hero PLAY label: navy, WCAG >= 4.5 on interactive states]")
	await _boot("s07")
	var play: Button = _root.get_home().find_child("PlayButton", true, false)
	var ok := play != null
	if ok:
		for pair in [["font_color", "normal"], ["font_hover_color", "hover"], ["font_pressed_color", "pressed"]]:
			var fg: Color = play.get_theme_color(pair[0])
			var bg: Color = (play.get_theme_stylebox(pair[1]) as StyleBoxFlat).bg_color
			var cr: float = Audit.contrast_ratio(fg, bg)
			print("    %s: %.2f:1" % [pair[1], cr])
			ok = ok and fg == HomeStyle.NAVY and cr >= 4.5
		var dis: float = Audit.contrast_ratio(play.get_theme_color("font_disabled_color"), (play.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color)
		print("    disabled (reported; WCAG exempts inactive controls): %.2f:1" % dis)
	_ok(ok, "PLAY text is HomeStyle.NAVY with >= 4.5:1 on normal / hover / pressed green")
	var other := Button.new()
	HomeStyle.style_play_button(other)
	_ok(other.get_theme_color("font_color") == HomeStyle.TEXT and (play.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == HomeStyle.GREEN,
		"green body unchanged; other green buttons keep white labels")
	other.free()
	_complete("s07_play_label_navy")

func _s08() -> void:
	print("[s08 HUD booster price through UiText]")
	var scr = await _screen(Vector2i(1080, 2160), _v3, 3, 5)
	var ok := true
	var n := 0
	for id in scr.get_booster_ids():
		scr._booster_states[id] = {"charges": 0, "price": 500, "state": "AVAILABLE"}
		scr._apply_booster_visual(id)
		ok = ok and scr.get_booster_button(id).get_node("Price").text == "500 SB"
		scr._booster_states[id]["price"] = 1500
		scr._apply_booster_visual(id)
		ok = ok and scr.get_booster_button(id).get_node("Price").text == "1,500 SB"
		UiText.pseudo = true
		scr._apply_booster_visual(id)
		UiText.pseudo = false
		ok = ok and scr.get_booster_button(id).get_node("Price").text.begins_with("[")
		n += 1
	_shutdown()
	_ok(ok and n > 0, "%d booster prices: '500 SB' unchanged, '1,500 SB' grouped, pseudo-localised when enabled" % n)
	_complete("s08_hud_price_ui_text")

func _s09() -> void:
	print("[s09 cost of symbols]")
	var scr = await _screen(Vector2i(1080, 2160), _v3, 5, 6)
	var t0 := Time.get_ticks_usec()
	for i in range(300):
		scr.get_supply_panel().bind_player_snapshot(_supply(5, 12 + i % 50), scr._palette_colors)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var board_symbols: Array = scr.find_children("*", "", true, false).filter(func(n): return n.get_script() == ColorSymbols)
	print("    300 rebinds of a 5x3 supply: %.1f ms; symbol nodes on screen: %d" % [ms, board_symbols.size()])
	_ok(ms < 3000.0, "300 rebinds in %.1f ms" % ms)
	_ok(board_symbols.size() == 5 * 3 + 6, "exactly one symbol per supply / slot tile (%d); none on the board" % board_symbols.size())
	_shutdown()
	_complete("s09_cost")

func _s10() -> void:
	print("[s10 booster target chips: same symbol as the tiles]")
	await _boot("s10")
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	var chips := 0
	var ok := host != null
	if ok:
		host.get_runtime().set_process(false)
		for id in ["tornado", "selector"]:
			_root.get_modal_stack().clear("test")
			await _frames(1)
			host.request_booster(id)
			await _frames(4)
			var p = _root.get_modal_stack().top()
			var flow: Node = p.find_child("Targets", true, false) if p != null else null
			if flow == null:
				continue
			for b in flow.get_children():
				var sym: Control = b.get_node_or_null("Symbol")
				var col: Color = (b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
				ok = ok and sym != null and sym.get_shape() == ColorSymbols.shape_for_color(col) and sym.get_shape() != "" and sym.mouse_filter == Control.MOUSE_FILTER_IGNORE
				if id == "selector":
					var lab: Label = b.get_node_or_null("Count")
					ok = ok and lab != null and lab.text.is_valid_int() and lab.get_index() > sym.get_index() and not sym.emblem and String((b as Button).text).is_empty()
				else:
					ok = ok and sym.emblem
				chips += 1
			print("    %s: %d chips" % [id, flow.get_child_count()])
	_ok(ok and chips > 0, "%d Tornado (emblem) / Selector (watermark under the count) chips carry their colour's symbol, input-transparent" % chips)
	_shutdown()
	_complete("s10_booster_target_chips")

# ------------------------------------------------------------------ helpers ----

func _mask(shape: String) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(32 * 32)
	var parts := ColorSymbols._parts(shape)
	for y in range(32):
		for x in range(32):
			var p := Vector2((x + 0.5) / 16.0 - 1.0, (y + 0.5) / 16.0 - 1.0)
			var inside := false
			for part in parts:
				match String(part[0]):
					"poly":
						inside = inside or Geometry2D.is_point_in_polygon(p, PackedVector2Array(part[1]))
					"disc":
						inside = inside or p.distance_to(part[2] if part.size() > 2 else Vector2.ZERO) <= float(part[1])
					"ring":
						inside = inside or absf(p.length() - float(part[1])) <= float(part[2]) * 0.5
			out[y * 32 + x] = 1 if inside else 0
	return out

func _iou(a: PackedByteArray, b: PackedByteArray) -> float:
	var i := 0
	var u := 0
	for k in range(a.size()):
		i += a[k] & b[k]
		u += a[k] | b[k]
	return float(i) / maxf(u, 1.0)

func _supply(cols: int, count: int = 12) -> Array:
	var out: Array = []
	for c in range(cols):
		var pv: Array = []
		for r in range(3):
			pv.append({"color_id": (c * 3 + r) % 16, "robot_count": count + c + r})
		out.append({"front": pv[0], "preview": pv, "remaining": 9})
	return out

func _slots(cap: int) -> Array:
	var out: Array = []
	for i in range(cap):
		out.append({"state": "ACTIVE", "occupied": true, "remaining_to_clear": 3 + i, "committed": 0, "color_id": i} if i < 4 else {"state": "EMPTY", "occupied": false})
	return out

func _screen(size: Vector2i, pal: PackedStringArray, cols: int, cap: int):
	_new_sub(size)
	var scr = GameplayScreen.new()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(scr)
	scr.configure(BoardDebugFixtures.make_board(24, 24), pal, [], _supply(cols))
	if cap == 6:
		scr.get_five_slot_strip().set_capacity(6)
	scr.refresh_slot_snapshot(_slots(cap))
	await _frames(3)
	return scr

func _new_sub(size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)

func _boot(tag: String) -> void:
	_new_sub(Vector2i(1080, 2160))
	var path := "user://m50s_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
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
	UiText.pseudo = false
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
	print("M50 color symbols evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
