extends SceneTree
## M28-C002-C004 — Color / Batch Tile visual polish: focused suite.
## Presentation-only. The shared ColorBatchTile drives the five/six execution slots AND every
## Batch Supply tile. BLOCKING owner correction: the slot count is centred in the COLOURED
## FACE on both axes - proven here by direct rect comparison (count label rect vs the explicit
## face rect, never the outer tile / base), across digit counts, ACTIVE/WAITING, five/six slots,
## a hostile hidden-spacer, and a phone / narrow / short / tablet matrix.
## Rendered-pixel centring + close-up evidence: tests/tools/m28_c004_tile_evidence.gd (GPU).
##
## Run: godot --headless --path . -s res://tests/m28_c002_c004_tile_visual.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const TILE_PATH := "res://scripts/ui/color_batch_tile.gd"
const TOL := 1.0   # audit tolerance (px) for centre == centre

const MATRIX := [Vector2i(1080, 2160), Vector2i(720, 1600), Vector2i(1080, 1920), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var EXPECTED_CASES := [
	"c01_shared_component", "c02_five_slot_live_counts", "c03_sixth_slot_same_tile",
	"c04_supply_3_4_5_columns", "c05_front_vs_preview", "c06_no_words_empty_no_count",
	"c07_centering_digits_states_capacity", "c08_centering_face_not_base",
	"c09_hidden_spacer_cannot_move_count", "c10_responsive_centering", "c11_palette_face_identity",
	"c12_spawn_anchor_pinned", "c13_supply_hit_rects_and_gesture", "c14_no_truth_mutation",
	"c15_lightweight_no_baked_art", "c16_count_readable_fit",
	"c17_base_body_equals_face_colour",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _palette := PackedStringArray()
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_palette.append(String(c["hex"]))
	MainScript.boot_opening_override = 0
	await _standalone_cases()
	await _same_color_base()
	await _real_host_cases()
	await _anchor_pin()
	await _supply_gesture()
	_shutdown()
	MainScript.boot_opening_override = -1
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _slot(state: String, remaining: int, committed: int, color_id: int) -> Dictionary:
	if state == "EMPTY":
		return {"state": "EMPTY", "occupied": false}
	return {"state": state, "occupied": true, "remaining_to_clear": remaining, "committed": committed, "color_id": color_id}

func _supply(cols: int, count: int = 12) -> Array:
	var out: Array = []
	for c in range(cols):
		var pv: Array = []
		for r in range(3):
			pv.append({"color_id": (c * 3 + r) % 16, "robot_count": count + c + r})
		out.append({"front": pv[0], "preview": pv, "remaining": 9})
	return out

func _screen(size: Vector2i, slots: Array, capacity: int, cols: int) -> Control:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var scr = GameplayScreen.new()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(BoardDebugFixtures.make_board(24, 24), _palette, [], _supply(cols))
	if capacity == 6:
		scr.get_five_slot_strip().set_capacity(6)
	scr.refresh_slot_snapshot(slots.slice(0, capacity))
	return scr

func _free_screen(scr: Control) -> void:
	var sub := scr.get_parent()
	scr.free()
	sub.free()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _boot(level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m28c004_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.get_app_state().economy.wallet.credit("scrub_bucks", 5000)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _tiles(strip) -> Array:
	return strip.get_slot_views().map(func(v): return v.get_tile())

## count centre - face centre must be inside the audit tolerance on both axes, computed from the
## COLOURED FACE rect (never the outer tile / base rect).
func _centred(t: ColorBatchTile) -> bool:
	var f: Rect2 = t.get_face_rect_global()
	var c: Rect2 = t.get_count_rect_global()
	var d: Vector2 = c.get_center() - f.get_center()
	return absf(d.x) <= TOL and absf(d.y) <= TOL and f.size.x > 0.0

# ------------------------------------------------------- standalone screen cases ----

func _standalone_cases() -> void:
	print("[standalone GameplayScreen: shared tile, supply, centring, responsive]")
	var slots := [_slot("ACTIVE", 7, 0, 2), _slot("WAITING", 45, 3, 7), _slot("WAITING", 120, 0, 0),
		_slot("ACTIVE", 33, 1, 13), _slot("EMPTY", 0, 0, 0), _slot("WAITING", 250, 0, 6)]
	var scr := _screen(Vector2i(1080, 2160), slots, 5, 5)
	await _settle()
	var strip = scr.get_five_slot_strip()
	var sp = scr.get_supply_panel()

	# c01 one shared component
	var slot_ok := true
	for v in strip.get_slot_views():
		slot_ok = slot_ok and v.get_tile().get_script().resource_path == TILE_PATH
	var supply_ok := true
	for c in range(sp.get_column_count()):
		for p in sp.get_column_row_panels(c):
			supply_ok = supply_ok and p.get_node("Tile").get_script().resource_path == TILE_PATH
	_ok(slot_ok and supply_ok, "slot views and every supply tile use the one ColorBatchTile script (%s)" % TILE_PATH)
	_complete("c01_shared_component")

	# c04 supply 3/4/5 columns x exactly 3 visible rows, live counts through the tile
	for cols in [3, 4, 5]:
		var s2 := _screen(Vector2i(1080, 2160), slots, 5, cols)
		await _settle()
		var p2 = s2.get_supply_panel()
		var good: bool = p2.get_column_count() == cols
		for c in range(cols):
			var rows: Array = p2.get_column_row_panels(c)
			good = good and rows.size() == 3
			for r in range(3):
				var tile: ColorBatchTile = rows[r].get_node("Tile")
				good = good and not tile.is_empty_tile() and tile.get_count_text() == p2.get_row_count_text(c, r) and tile.get_count_text() == str(12 + c + r)
		_ok(good, "%d-column supply: %dx3 tiles, live counts via the shared tile" % [cols, cols])
		_free_screen(s2)
	_complete("c04_supply_3_4_5_columns")

	# c05 front vs preview distinguishable; preview not interactive
	var fp: Array = sp.get_column_row_panels(0)
	var ftile: ColorBatchTile = fp[0].get_node("Tile")
	var ptile: ColorBatchTile = fp[1].get_node("Tile")
	_ok(not ftile.is_preview() and ptile.is_preview() and ftile.is_active_style() and not ptile.is_active_style()
		and fp[0].modulate.a > fp[1].modulate.a and fp[0].modulate.r > fp[1].modulate.r,
		"front tile primary (full strength, rim); preview tile lower emphasis (dimmed, no rim)")
	sp.enable_front_input()
	_ok(fp[0].mouse_filter == Control.MOUSE_FILTER_STOP and fp[1].mouse_filter == Control.MOUSE_FILTER_IGNORE and fp[2].mouse_filter == Control.MOUSE_FILTER_IGNORE
		and fp[1].gui_input.get_connections().is_empty() and ptile.mouse_filter == Control.MOUSE_FILTER_IGNORE and ftile.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"preview rows non-interactive; tiles never take input (the row panel stays the only front surface)")
	_complete("c05_front_vs_preview")

	# c06 no words; empty has no fake count / face
	var words: Array = []
	for n in scr.find_children("*", "Label", true, false):
		var u := String((n as Label).text).to_upper()
		if u.find("WAITING") != -1 or u.find("ACTIVE") != -1:
			words.append(u)
	var et: ColorBatchTile = strip.get_slot_views()[4].get_tile()
	_ok(words.is_empty() and strip.get_slot_views().all(func(v): return v.get_state_text() == ""), "no visible WAITING / ACTIVE text anywhere")
	_ok(et.is_empty_tile() and et.get_count_text() == "" and not et.get_face_panel().visible and not et.get_base_panel().visible
		and strip.get_slot_views()[4].get_count_label_text() == "" and strip.get_slot_views()[4].get_display_count() == 0,
		"EMPTY slot: no face, no base, no count")
	_complete("c06_no_words_empty_no_count")

	# c07 centring: digits x states x capacity (5 and 6)
	_free_screen(scr)
	var cases: Array = []
	for n in [1, 2, 3]:
		for st in ["ACTIVE", "WAITING"]:
			cases.append([n, st])
	var all_ok := true
	var checked := 0
	for cap in [5, 6]:
		for cs in cases:
			var rem: int = [7, 45, 120][int(cs[0]) - 1]
			var sl: Array = []
			for i in range(cap):
				sl.append(_slot(cs[1], rem + (i if cs[0] < 3 else 0), 0, i * 3 % 16))
			var s3 := _screen(Vector2i(1080, 2160), sl, cap, 4)
			await _settle()
			for t in _tiles(s3.get_five_slot_strip()):
				checked += 1
				var digits: int = String(t.get_count_text()).length()
				all_ok = all_ok and _centred(t) and digits >= 1
				if not _centred(t):
					print("    off-centre: ", cs, " cap ", cap, " delta ", t.get_count_center_delta())
			_free_screen(s3)
	_ok(all_ok and checked > 50, "count centre == FACE centre (<= %.0f px both axes): 1/2/3 digits x ACTIVE/WAITING x 5 and 6 slots (%d tiles)" % [TOL, checked])
	_complete("c07_centering_digits_states_capacity")

	# c08 centring is against the FACE, not the tile/base
	var s4 := _screen(Vector2i(1080, 2160), slots, 6, 5)
	await _settle()
	var face_ok := true
	for t in _tiles(s4.get_five_slot_strip()):
		if t.is_empty_tile():
			continue
		var whole: Rect2 = t.get_global_rect()
		var f: Rect2 = t.get_face_rect_global()
		var c: Rect2 = t.get_count_rect_global()
		var base: Rect2 = t.get_base_panel().get_global_rect()
		face_ok = face_ok and t.get_count_label().get_parent() == t.get_face_panel()
		face_ok = face_ok and c.size.is_equal_approx(f.size) and c.position.is_equal_approx(f.position)   # full-face overlay
		face_ok = face_ok and f.size.y < whole.size.y - 2.0 and base.end.y >= f.end.y + 2.0 and f.position.y >= whole.position.y   # a real base below the face
		# The number would sit lower if it were centred on the whole tile (incl. base): prove it is not.
		face_ok = face_ok and absf(c.get_center().y - whole.get_center().y) > 1.0 and absf(c.get_center().y - f.get_center().y) <= TOL
		face_ok = face_ok and t.get_count_label().horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and t.get_count_label().vertical_alignment == VERTICAL_ALIGNMENT_CENTER
	_ok(face_ok, "count label = full-face overlay (rect == face rect), centred on the FACE; the lower base is outside the centring box")
	_complete("c08_centering_face_not_base")

	# c09 hidden spacer / state line / legacy min-size cannot move the count
	var v0 = s4.get_five_slot_strip().get_slot_views()[1]
	var t0: ColorBatchTile = v0.get_tile()
	var face_before: Rect2 = t0.get_face_rect_global()
	var st_lbl: Label = v0.get_node("StateLineReserve")
	st_lbl.custom_minimum_size = Vector2(400, 400)   # hostile spacer
	st_lbl.text = "WAITING"                            # even visible words must not touch the tile
	await _settle()
	var sp_ok: bool = _centred(t0) and t0.get_face_rect_global().is_equal_approx(face_before)
	_ok(sp_ok, "hostile / populated state-line spacer: count stays centred and the face rect does not move (spacer is a sibling of the tile)")
	_ok(st_lbl.get_parent() == v0 and not t0.is_ancestor_of(st_lbl) and not st_lbl.is_ancestor_of(t0), "state line is outside the tile (not in the face / count layout)")
	_free_screen(s4)
	_complete("c09_hidden_spacer_cannot_move_count")

	# c10 responsive matrix (phone / narrow / short / tall / tablet) x 5 and 6 slots x 3/4/5 cols
	var resp_ok := true
	var n_checked := 0
	for size in MATRIX:
		for cap in [5, 6]:
			for cols in [3, 5]:
				var s5 := _screen(size, slots, cap, cols)
				await _settle()
				for t in _tiles(s5.get_five_slot_strip()):
					if t.is_empty_tile():
						continue
					n_checked += 1
					resp_ok = resp_ok and _centred(t)
					if not _centred(t):
						print("    off-centre @", size, " cap ", cap, " delta ", t.get_count_center_delta())
				_free_screen(s5)
	_ok(resp_ok and n_checked >= 90, "centring holds on phone/narrow/short/tall/tablet, 5 & 6 slots (%d tiles)" % n_checked)
	# re-layout on a live resize keeps the relationship
	var s6 := _screen(Vector2i(1080, 2160), slots, 5, 5)
	await _settle()
	(s6.get_parent() as SubViewport).size = Vector2i(720, 1600)
	await _settle()
	await _settle()
	_ok(_tiles(s6.get_five_slot_strip()).all(func(t): return t.is_empty_tile() or _centred(t)), "live resize 1080x2160 -> 720x1600 keeps every count centred")
	_free_screen(s6)
	_complete("c10_responsive_centering")

	# c11 palette identity + readability colours
	var pal_ok := true
	var hi_ok := true
	for cid in range(16):
		var tile := ColorBatchTile.new()
		tile.size = Vector2(90, 90)
		var want := Color.html(_palette[cid])
		tile.set_batch(want, "88")
		var sb := tile.get_face_panel().get_theme_stylebox("panel") as StyleBoxFlat
		pal_ok = pal_ok and sb.bg_color == want and tile.get_face_color() == want
		# the highlight band must not cover the face centre (central colour identity)
		var hr := Rect2(tile.get_highlight_panel().position, tile.get_highlight_panel().size)
		hi_ok = hi_ok and not hr.has_point(tile.get_face_panel().size * 0.5)
		pal_ok = pal_ok and tile.get_count_label().get_theme_color("font_color") == Color(1, 1, 1, 1)
		pal_ok = pal_ok and tile.get_count_label().get_theme_color("font_outline_color").v < 0.15 and tile.get_count_label().get_theme_constant("outline_size") >= 3
		tile.free()
	_ok(pal_ok, "all 16 Palette v3 colours: face bg == exact palette colour; count white with a strong dark outline (light AND dark faces)")
	_ok(hi_ok, "top highlight never covers the face centre (central colour stays canonical)")
	_complete("c11_palette_face_identity")

	# c16 fit: 1..3 digits inside the face at every size, never clipped
	var fit_ok := true
	for size in [Vector2(48, 48), Vector2(70, 70), Vector2(85, 80), Vector2(120, 120)]:
		for txt in ["7", "45", "250", "999"]:
			var t := ColorBatchTile.new()
			t.size = size
			t.set_batch(Color.html(_palette[7]), txt)
			var lab := t.get_count_label()
			var fsz := lab.get_theme_font_size("font_size")
			var w: float = lab.get_theme_font("font").get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
			fit_ok = fit_ok and w <= t.get_face_panel().size.x + 0.5 and lab.get_minimum_size().y <= t.get_face_panel().size.y + 0.5
			t.free()
	_ok(fit_ok, "1-3 digit counts fit inside the face at 48..120 px tiles (font only shrinks; no offsets)")
	_complete("c16_count_readable_fit")

	# c15 lightweight, no baked art
	var t2 := ColorBatchTile.new()
	t2.size = Vector2(90, 90)
	t2.set_batch(Color.html(_palette[3]), "12")
	var nodes := t2.find_children("*", "", true, false)
	var no_tex := nodes.all(func(n): return not (n is TextureRect) and not (n is Sprite2D) and not (n is NinePatchRect))
	_ok(nodes.size() <= 8 and no_tex, "tile is %d native nodes (Panel/Label only): no baked per-colour / per-count textures" % nodes.size())
	t2.free()
	_complete("c15_lightweight_no_baked_art")

	# c14 (part) snapshot detachment: mutating the source dict after binding never changes the view
	var snap := _slot("WAITING", 20, 5, 3)
	var view := BatchSlotView.new()
	view.set_shell_mode(true)
	view.bind_snapshot(snap, Color.html(_palette[3]))
	snap["remaining_to_clear"] = 999
	_ok(view.get_display_count() == 15 and view.get_count_label_text() == "15", "displayed count = remaining_to_clear - committed (20-5=15) from a detached snapshot")
	view.free()

# ------------------------------------------------- V02: base body == face colour ----

## V02 owner correction: for every occupied tile the lower base BODY fill is exactly the same
## canonical Palette v3 batch colour as the top face (a darker edge / neutral shadow may remain).
## Everything else the owner accepted in V01 is asserted unchanged.
func _same_color_base() -> void:
	print("[V02 base body == face colour; accepted visuals preserved]")
	var old_white := Color(0.93, 0.95, 0.98, 1.0)   # the rejected fixed base fill
	var eq_ok := true
	var no_white := true
	var edge_ok := true
	for cid in range(16):
		var want := Color.html(_palette[cid])
		var t := ColorBatchTile.new()
		t.size = Vector2(90, 90)
		t.set_batch(want, "88")
		var fb := t.get_face_panel().get_theme_stylebox("panel") as StyleBoxFlat
		var bb := t.get_base_panel().get_theme_stylebox("panel") as StyleBoxFlat
		eq_ok = eq_ok and fb.bg_color == want and bb.bg_color == want and bb.bg_color == fb.bg_color   # exact, not perceptual
		no_white = no_white and not bb.bg_color.is_equal_approx(old_white)
		edge_ok = edge_ok and bb.border_color == want.darkened(0.32) and bb.border_width_bottom == 3   # depth edge only
		t.free()
	_ok(eq_ok, "all 16 Palette v3 colours: base StyleBoxFlat.bg_color == face bg_color == canonical palette colour (exact equality)")
	_ok(no_white, "the fixed white / light-grey base fill is gone (no occupied base uses it)")
	_ok(edge_ok, "only a thin darker same-hue bottom edge remains as depth (body fill untouched)")

	# Accepted geometry / shadow / highlight / states unchanged (measured on the V01 values).
	var t2 := ColorBatchTile.new()
	t2.size = Vector2(90, 90)
	t2.set_batch(Color.html(_palette[6]), "30")
	var strip_h: float = t2.get_base_panel().position.y + t2.get_base_panel().size.y - (t2.get_face_panel().position.y + t2.get_face_panel().size.y)
	var bs := t2.get_base_panel().get_theme_stylebox("panel") as StyleBoxFlat
	var hs := t2.get_highlight_panel().get_theme_stylebox("panel") as StyleBoxFlat
	_ok(is_equal_approx(strip_h, roundf(90.0 * 0.17)) and is_equal_approx(t2.get_face_panel().size.y, 90.0 - roundf(90.0 * 0.17)) and ColorBatchTile.BASE_FRACTION == 0.17,
		"base height / face geometry unchanged (visible base strip %.0f px of 90, BASE_FRACTION 0.17)" % strip_h)
	_ok(bs.shadow_size == 4 and is_equal_approx(bs.shadow_color.a, 0.34) and bs.shadow_offset == Vector2(0, 3) and bs.shadow_color.r == 0.0,
		"shadow unchanged: size 4, alpha 0.34, offset (0,3), neutral black")
	_ok(t2.get_highlight_panel().visible and is_equal_approx(hs.bg_color.a, 0.16) and t2.get_highlight_panel().size.x > 0.0, "top highlight present, alpha 0.16 unchanged")
	t2.set_active(true)
	var hs2 := t2.get_highlight_panel().get_theme_stylebox("panel") as StyleBoxFlat
	var bb2 := t2.get_base_panel().get_theme_stylebox("panel") as StyleBoxFlat
	_ok(t2.is_active_style() and is_equal_approx(hs2.bg_color.a, 0.24) and bb2.bg_color == Color.html(_palette[6]), "ACTIVE unchanged (glow, highlight 0.24) and its base is still the batch colour")
	t2.set_active(false)
	t2.set_preview(true)
	var bp := t2.get_base_panel().get_theme_stylebox("panel") as StyleBoxFlat
	_ok(t2.is_preview() and bp.shadow_size == 2 and bp.bg_color == Color.html(_palette[6]), "preview unchanged (shadow 2) and its base is the batch colour")
	t2.set_empty()
	_ok(t2.is_empty_tile() and not t2.get_base_panel().visible and not t2.get_face_panel().visible and t2.get_count_text() == "", "EMPTY unchanged: no face, no base, no count")
	t2.free()

	# The real slot + supply tiles (production path) follow the same rule, incl. preview rows.
	var slots := [_slot("ACTIVE", 7, 0, 2), _slot("WAITING", 45, 3, 7), _slot("WAITING", 120, 0, 11), _slot("ACTIVE", 33, 1, 13), _slot("WAITING", 9, 0, 15), _slot("WAITING", 250, 0, 12)]
	var scr := _screen(Vector2i(1080, 2160), slots, 6, 5)
	await _settle()
	var prod_ok := true
	var n := 0
	var tiles: Array = _tiles(scr.get_five_slot_strip())
	var sp = scr.get_supply_panel()
	for c in range(sp.get_column_count()):
		for p in sp.get_column_row_panels(c):
			tiles.append(p.get_node("Tile"))
	for t in tiles:
		if t.is_empty_tile():
			continue
		n += 1
		var f := t.get_face_panel().get_theme_stylebox("panel") as StyleBoxFlat
		var b := t.get_base_panel().get_theme_stylebox("panel") as StyleBoxFlat
		prod_ok = prod_ok and b.bg_color == f.bg_color and b.bg_color == t.get_face_color()
		if not t.is_preview():
			prod_ok = prod_ok and _centred(t)
	_ok(prod_ok and n == 21, "production slot (5/6) + supply (front & preview) tiles: base == face colour, slot counts still exactly face-centred (%d tiles)" % n)
	_free_screen(scr)
	_complete("c17_base_body_equals_face_colour")

# --------------------------------------------------------- real host cases ----

func _clicks(h) -> Array:
	if String(h.supply_plan_path).is_empty():
		return []
	return SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]

func _real_host_cases() -> void:
	print("[real ProductionGameplayHost: live counts, sixth slot, no truth mutation]")
	await _boot(2)
	var s = _host.get_screen()
	var strip = s.get_five_slot_strip()
	var clicks := _clicks(_host)
	var i := 0
	while _host.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
		if _host.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
			i += 1
	for _k in range(30):
		_host.get_runtime().tick(0.05)   # some Scrubbots leave: committed > 0 -> count = remaining - committed
	await _settle()
	var snap: Array = _host.get_slots().snapshot()
	var live := true
	var occ := 0
	var some_committed := false
	for k in range(strip.get_slot_count()):
		var v = strip.get_slot_views()[k]
		var d: Dictionary = snap[k]
		if bool(d.get("occupied", false)):
			occ += 1
			var want: int = maxi(int(d["remaining_to_clear"]) - int(d.get("committed", 0)), 0)
			some_committed = some_committed or int(d.get("committed", 0)) > 0
			live = live and v.get_tile().get_count_text() == str(want) and v.get_display_count() == want and _centred(v.get_tile())
	_ok(occ >= 3 and live, "five-slot runtime: %d occupied, count = remaining_to_clear - committed (committed seen: %s), every count face-centred" % [occ, str(some_committed)])
	_complete("c02_five_slot_live_counts")

	# c14 truth immutable across presentation refresh
	var before_slots: String = JSON.stringify(_host.get_slots().snapshot())
	var before_sup: String = JSON.stringify(_host.get_supply().player_snapshot())
	var before_sb: int = _root.get_app_state().economy.wallet.scrub_bucks()
	for _r in range(3):
		s.refresh_slot_snapshot(_host.get_slots().snapshot())
		s.update_snapshots(_host.get_slots().snapshot(), _host.get_supply().player_snapshot())
		s.relayout()
	await _settle()
	_ok(before_slots == JSON.stringify(_host.get_slots().snapshot()) and before_sup == JSON.stringify(_host.get_supply().player_snapshot())
		and before_sb == _root.get_app_state().economy.wallet.scrub_bucks(), "repeated presentation refresh mutates no slot / supply / economy truth")
	_complete("c14_no_truth_mutation")

	# c03 sixth slot
	_root.get_app_state().economy.boosters.add_charges("plus_one_slot", 1)
	var r: Dictionary = _host.request_booster("plus_one_slot")
	await _settle()
	var clicks2 := _clicks(_host)
	var j := i
	while _host.get_slots().rightmost_empty_index() != -1 and j < clicks2.size():
		if _host.get_input_controller().activate_front(int(clicks2[j]) - 1).get("ok", false):
			j += 1
	_host.get_runtime().tick(0.05)
	await _settle()
	var six: Array = strip.get_slot_views()
	var sixth_ok: bool = r.get("ok", false) and strip.get_capacity() == 6 and six.size() == 6 and six[5].get_tile().get_script().resource_path == TILE_PATH
	sixth_ok = sixth_ok and six.all(func(v): return v.get_tile().is_empty_tile() or _centred(v.get_tile()))
	_ok(sixth_ok and six[5].is_occupied_view(), "temporary sixth slot: same ColorBatchTile, occupied, count face-centred (%s)" % six[5].get_count_label_text())
	_complete("c03_sixth_slot_same_tile")

# ---------------------------------------------------------- anchors / gestures ----

## Slot spawn anchors + slot view rects PINNED to the values measured on the pre-C004 slot code
## (the accepted V02 layout) with tests/tools/m28_c004_anchor_probe.gd: [ax, ay, x, y, w, h] per
## slot. Any drift - including the state-dependent outer size the old borders produced on narrow
## phones - fails.
const ANCHOR_BASELINE := {
	"1080x2160/5": [[284.92,1323.52,233.78,1323.52,102.28,96.19],[414.59,1323.52,362.84,1323.52,103.49,96.19],[544.26,1323.52,493.12,1323.52,102.28,96.19],[673.33,1323.52,622.19,1323.52,102.28,96.19],[803.00,1323.52,751.25,1323.52,103.49,96.19]],
	"1080x2160/6": [[236.82,1325.95,187.51,1325.95,98.62,94.97],[357.97,1325.95,308.05,1325.95,99.84,94.97],[478.51,1325.95,429.81,1325.95,97.41,94.97],[597.84,1325.95,549.13,1325.95,97.41,94.97],[717.77,1324.73,668.46,1324.73,98.62,96.19],[838.31,1325.95,789.00,1325.95,98.62,94.97]],
	"720x1600/5": [[198.85,962.34,155.85,962.34,86.00,83.00],[283.89,962.34,241.89,962.34,84.00,81.00],[371.75,962.34,328.75,962.34,86.00,83.00],[456.79,962.34,414.79,962.34,84.00,81.00],[540.83,962.34,500.83,962.34,80.00,77.00]],
	"720x1600/6": [[168.01,963.97,125.01,963.97,86.00,83.00],[247.37,963.97,205.37,963.97,84.00,81.00],[329.54,963.97,286.54,963.97,86.00,83.00],[408.09,963.97,366.09,963.97,84.00,81.00],[485.64,963.16,445.64,963.16,80.00,77.00],[566.00,963.97,526.00,963.97,80.00,77.00]],
	"1080x1920/5": [[313.26,1176.46,267.80,1176.46,90.91,85.50],[428.52,1176.46,382.53,1176.46,92.00,85.50],[543.79,1176.46,498.33,1176.46,90.91,85.50],[658.51,1176.46,613.06,1176.46,90.91,85.50],[773.78,1176.46,727.78,1176.46,92.00,85.50]],
	"1080x1920/6": [[270.51,1178.62,226.67,1178.62,87.67,84.42],[378.20,1178.62,333.82,1178.62,88.75,84.42],[485.34,1178.62,442.05,1178.62,86.58,84.42],[591.41,1178.62,548.12,1178.62,86.58,84.42],[698.02,1177.54,654.18,1177.54,87.67,85.50],[805.16,1178.62,761.33,1178.62,87.67,84.42]],
	"1536x2048/5": [[526.14,1254.89,477.65,1254.89,96.97,91.20],[649.09,1254.89,600.03,1254.89,98.13,91.20],[772.04,1254.89,723.55,1254.89,96.97,91.20],[894.41,1254.89,845.93,1254.89,96.97,91.20],[1017.36,1254.89,968.30,1254.89,98.13,91.20]],
	"1536x2048/6": [[480.54,1257.20,433.79,1257.20,93.51,90.05],[595.41,1257.20,548.08,1257.20,94.67,90.05],[709.70,1257.20,663.52,1257.20,92.36,90.05],[822.84,1257.20,776.66,1257.20,92.36,90.05],[936.55,1256.05,889.79,1256.05,93.51,91.20],[1050.84,1257.20,1004.09,1257.20,93.51,90.05]],
	"1290x2796/5": [[340.32,1688.87,279.23,1688.87,122.16,114.89],[495.20,1688.87,433.39,1688.87,123.62,114.89],[650.09,1688.87,589.01,1688.87,122.16,114.89],[804.25,1688.87,743.17,1688.87,122.16,114.89],[959.14,1688.87,897.33,1688.87,123.62,114.89]],
	"1290x2796/6": [[282.87,1691.78,223.97,1691.78,117.80,113.44],[427.58,1691.78,367.95,1691.78,119.26,113.44],[571.56,1691.78,513.38,1691.78,116.35,113.44],[714.08,1691.78,655.91,1691.78,116.35,113.44],[857.33,1690.32,798.43,1690.32,117.80,114.89],[1001.31,1691.78,942.41,1691.78,117.80,113.44]],
}

func _anchor_pin() -> void:
	print("[slot spawn anchors / outer slot rects]")
	var slots: Array = []
	for i in range(6):
		slots.append({"state": "WAITING" if i % 2 else "ACTIVE", "occupied": i < 4, "remaining_to_clear": 20 + i, "committed": 1, "color_id": i})
	var ok := true
	for key in ANCHOR_BASELINE:
		var parts: PackedStringArray = String(key).split("/")
		var dims: PackedStringArray = parts[0].split("x")
		var scr := _screen(Vector2i(int(dims[0]), int(dims[1])), slots, int(parts[1]), 5)
		await _settle()
		var strip = scr.get_five_slot_strip()
		var want: Array = ANCHOR_BASELINE[key]
		ok = ok and strip.get_slot_count() == want.size()
		for k in range(want.size()):
			var a: Vector2 = strip.get_slot_anchor_global(k)
			var v = strip.get_slot_views()[k]
			var got := [a.x, a.y, v.global_position.x, v.global_position.y, v.size.x, v.size.y]
			var okk := true
			for m in range(6):
				okk = okk and absf(float(got[m]) - float(want[k][m])) <= 0.01
			if not okk:
				print("    drift ", key, " slot ", k, " got ", got, " baseline ", want[k])
			ok = ok and okk and a.is_equal_approx(v.global_position + Vector2(v.size.x * 0.5, 0.0))
		_free_screen(scr)
	_ok(ok, "slot spawn anchors + outer slot rects identical to pre-C004 across %d viewport/capacity configs" % ANCHOR_BASELINE.size())
	_complete("c12_spawn_anchor_pinned")

func _supply_gesture() -> void:
	print("[supply hit rects / one gesture = one activation]")
	var scr := _screen(Vector2i(1080, 2160), [], 5, 5)
	await _settle()
	await _settle()
	var sp = scr.get_supply_panel()
	sp.enable_front_input()
	sp.refresh_hit_areas()
	var hits: Array = []
	for c in range(sp.get_column_count()):
		hits.append(sp.get_front_hit_rect(c))
	var no_overlap := true
	for a in range(hits.size()):
		no_overlap = no_overlap and hits[a].size.x >= 60.0 and hits[a].size.y >= 60.0
		for b in range(a + 1, hits.size()):
			no_overlap = no_overlap and not hits[a].intersects(hits[b])
		var panel_rect: Rect2 = sp.get_column_row_panels(a)[0].get_global_rect()
		no_overlap = no_overlap and hits[a].encloses(panel_rect)
		var tile_rect: Rect2 = sp.get_column_row_panels(a)[0].get_node("Tile").get_global_rect()
		no_overlap = no_overlap and panel_rect.encloses(tile_rect.grow(-0.5))
	# rebinding new counts must not move a hit rect
	var moved := false
	scr.update_snapshots([], _supply(5, 88))
	await _settle()
	sp.refresh_hit_areas()
	for c in range(hits.size()):
		moved = moved or not sp.get_front_hit_rect(c).is_equal_approx(hits[c])
	_ok(no_overlap and not moved, "front hit rects: non-overlapping, enclose the tile, unchanged by a data rebind")
	var got: Array = []
	sp.front_batch_activated.connect(func(c): got.append(c))
	var col := 2
	var p: Vector2 = sp.get_front_hit_rect(col).get_center()
	var sub := scr.get_parent() as SubViewport
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		sub.push_input(e)
		await process_frame
	var one := got == [col]
	got.clear()
	var pp: Vector2 = sp.get_column_row_panels(col)[1].get_global_rect().get_center()
	for pressed in [true, false]:
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = pressed
		e2.position = pp
		e2.global_position = pp
		sub.push_input(e2)
		await process_frame
	_ok(one and got.is_empty(), "one press+release on a front = exactly one activation; a preview tile activates nothing")
	_free_screen(scr)
	_complete("c13_supply_hit_rects_and_gesture")

# -------------------------------------------------------------------- harness ----

func _cleanup() -> void:
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
	print("M28-C002-C004 color/batch tile visual: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
