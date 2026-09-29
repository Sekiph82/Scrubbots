extends SceneTree
## M28-C002-C004 runtime evidence for the shared ColorBatchTile (slots + Batch Supply).
## The REAL GameplayScreen (production shell, production BatchSlotView / BatchSupplyPanel /
## ColorBatchTile) is instantiated in a SubViewport with hand-authored DETACHED snapshots,
## rendered, and saved. Every shot is measured: the count-label centre vs the COLOURED FACE
## centre (layout rects AND rendered white-ink bounds). Close-ups draw a debug overlay
## (face centre = green cross, count-rect centre = red cross) - evidence only, never UI.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/m28_c004_tile_evidence.gd -- <out_dir>

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")

const PHONE := Vector2i(1080, 2160)
const NARROW := Vector2i(720, 1600)
const TABLET := Vector2i(1536, 2048)

## color ids on the real Palette v3 list: 0 C01 orange-red, 2 C03 yellow (light), 3 C04 green,
## 6 C07 blue, 7 C08 dark blue, 13 C14 dark gray (dark), 11 C12 pale yellow (very light)
const SLOTS_FIVE := [
	{"state": "ACTIVE", "occupied": true, "remaining_to_clear": 7, "committed": 0, "color_id": 2},
	{"state": "WAITING", "occupied": true, "remaining_to_clear": 45, "committed": 3, "color_id": 7},
	{"state": "WAITING", "occupied": true, "remaining_to_clear": 120, "committed": 0, "color_id": 0},
	{"state": "ACTIVE", "occupied": true, "remaining_to_clear": 33, "committed": 1, "color_id": 13},
	{"state": "EMPTY", "occupied": false},
]
const SLOTS_SIX := [
	{"state": "ACTIVE", "occupied": true, "remaining_to_clear": 5, "committed": 0, "color_id": 3},
	{"state": "WAITING", "occupied": true, "remaining_to_clear": 18, "committed": 2, "color_id": 11},
	{"state": "WAITING", "occupied": true, "remaining_to_clear": 250, "committed": 0, "color_id": 6},
	{"state": "ACTIVE", "occupied": true, "remaining_to_clear": 64, "committed": 4, "color_id": 9},
	{"state": "WAITING", "occupied": true, "remaining_to_clear": 9, "committed": 0, "color_id": 13},
	{"state": "EMPTY", "occupied": false},
]
const SUPPLY_COUNTS := [[7, 45, 120], [30, 8, 250], [12, 99, 3], [64, 5, 18], [2, 77, 140]]
const SUPPLY_COLORS := [[2, 7, 0], [3, 11, 6], [9, 13, 4], [0, 5, 1], [10, 12, 8]]

## [stem, size, slot snapshots, capacity, supply columns, close-up slot indices]
const SHOTS := [
	["c004_5slot_5col_phone", PHONE, SLOTS_FIVE, 5, 5, [0, 1, 2]],
	["c004_6slot_4col_phone", PHONE, SLOTS_SIX, 6, 4, [0, 1, 2]],
	["c004_5slot_3col_phone", PHONE, SLOTS_FIVE, 5, 3, []],
	["c004_5slot_4col_phone", PHONE, SLOTS_FIVE, 5, 4, []],
	["c004_6slot_5col_phone", PHONE, SLOTS_SIX, 6, 5, []],
	["c004_5slot_5col_narrow", NARROW, SLOTS_FIVE, 5, 5, [0, 1, 2]],
	["c004_6slot_5col_narrow", NARROW, SLOTS_SIX, 6, 5, [0, 1, 2]],
	["c004_5slot_5col_tablet", TABLET, SLOTS_FIVE, 5, 5, [0, 1, 2]],
	["c004_6slot_3col_tablet", TABLET, SLOTS_SIX, 6, 3, [0, 1, 2]],
]

var _palette := PackedStringArray()
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://c004_evidence"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_palette.append(String(c["hex"]))
	for shot in SHOTS:
		await _shot(out_dir, shot)
	await _gallery(out_dir)
	quit(1 if _bad > 0 else 0)

const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")

## Isolated tile sheet: all 16 Palette v3 faces (light -> dark), then ACTIVE / WAITING / EMPTY /
## SUPPLY-FRONT / SUPPLY-PREVIEW states, at a large scale, with the face-centre / count-centre overlay.
func _gallery(out_dir: String) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1200, 900)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.13, 0.31, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)
	var tiles: Array = []
	for cid in range(16):
		var t := ColorBatchTile.new()
		t.size = Vector2(120, 120)
		t.position = Vector2(30 + (cid % 8) * 143, 30 + (cid / 8) * 150)
		bg.add_child(t)
		t.set_batch(Color.html(_palette[cid]), ["7", "45", "120"][cid % 3])
		tiles.append(t)
	var states := [["normal", false, false, false], ["ACTIVE", true, false, false], ["WAITING", false, false, false], ["EMPTY", false, false, true], ["supply front", true, false, false], ["supply preview", false, true, false]]
	var k := 0
	for st in states:
		var t2 := ColorBatchTile.new()
		t2.size = Vector2(120, 120)
		t2.position = Vector2(30 + k * 190, 400)
		bg.add_child(t2)
		if st[3]:
			t2.set_empty()
		else:
			t2.set_batch(Color.html(_palette[6]), "30")
			t2.set_active(st[1])
			t2.set_preview(st[2])
			if st[2]:
				t2.modulate = Color(0.62, 0.62, 0.70, 0.85)
		var l := Label.new()
		l.text = st[0]
		l.position = t2.position + Vector2(0, 128)
		bg.add_child(l)
		tiles.append(t2)
		k += 1
	# small sizes: 48 / 70 / 85 with a 3-digit count
	var sx := 30
	for px in [48, 70, 85, 120]:
		var t3 := ColorBatchTile.new()
		t3.size = Vector2(px, px)
		t3.position = Vector2(sx, 620)
		bg.add_child(t3)
		t3.set_batch(Color.html(_palette[2]), "250")
		sx += px + 40
		tiles.append(t3)
	for _i in range(4):
		await process_frame
	var img: Image = sub.get_texture().get_image()
	var worst := 0.0
	for t in tiles:
		if not t.is_empty_tile():
			worst = maxf(worst, maxf(absf(t.get_count_center_delta().x), absf(t.get_count_center_delta().y)))
	for t in tiles:
		if not t.is_empty_tile():
			var fr: Rect2 = t.get_face_rect_global()
			_cross(img, fr.get_center(), Color(0, 1, 0, 1), 5)
	img.save_png(out_dir + "/c004_tile_gallery_palette_states_sizes.png")
	print("GALLERY worst layout delta = %.3f px over %d tiles" % [worst, tiles.size()])
	sub.queue_free()
	await process_frame

func _supply(cols: int) -> Array:
	var out: Array = []
	for c in range(cols):
		var pv: Array = []
		for r in range(3):
			pv.append({"color_id": SUPPLY_COLORS[c][r], "robot_count": SUPPLY_COUNTS[c][r]})
		out.append({"front": pv[0], "preview": pv, "remaining": 9})
	return out

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var scr = GameplayScreen.new()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	var lvl = BoardDebugFixtures.make_level(24, 24)
	scr.configure(BoardDebugFixtures.make_board(24, 24), _palette, [], _supply(shot[4]))
	if shot[3] == 6:
		scr.get_five_slot_strip().set_capacity(6)
	scr.refresh_slot_snapshot((shot[2] as Array).slice(0, shot[3]))
	for _i in range(6):
		await process_frame
	var strip = scr.get_five_slot_strip()
	var report := ""
	var img: Image = sub.get_texture().get_image()
	var views: Array = strip.get_slot_views()
	for i in range(views.size()):
		var t = views[i].get_tile()
		if t.is_empty_tile():
			continue
		var fr: Rect2 = t.get_face_rect_global()
		var d: Vector2 = t.get_count_center_delta()
		var ink := _ink_center(img, fr)
		var idelta := ink - fr.get_center() if ink.x >= 0.0 else Vector2(NAN, NAN)
		report += " s%d[%s d=(%.2f,%.2f) ink=(%.1f,%.1f)]" % [i, t.get_count_text(), d.x, d.y, idelta.x, idelta.y]
		if absf(d.x) > 0.6 or absf(d.y) > 0.6:
			_bad += 1
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	img.save_png(path)
	print("SNAPSHOT ", path, " shell=", scr.get_shell_id(), " slots=", views.size(), report)
	# close-ups with the debug overlay
	for idx in shot[5]:
		var t2 = views[idx].get_tile()
		_closeup(img, t2, "%s/%s_closeup_slot%d_%s.png" % [out_dir, shot[0], idx, t2.get_count_text()])
	scr.free()
	sub.queue_free()
	await process_frame

## Centre of the pure-white count fill pixels inside the face rect (rendered ink, not layout).
func _ink_center(img: Image, fr: Rect2) -> Vector2:
	var x0 := int(fr.position.x + fr.size.x * 0.12)
	var y0 := int(fr.position.y + fr.size.y * 0.24)   # below the top highlight band
	var x1 := int(fr.end.x - fr.size.x * 0.12)
	var y1 := int(fr.end.y - fr.size.y * 0.08)
	var minx := 1 << 30
	var miny := 1 << 30
	var maxx := -1
	var maxy := -1
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c := img.get_pixel(x, y)
			if c.r > 0.985 and c.g > 0.985 and c.b > 0.985:
				minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
	if maxx < 0:
		return Vector2(-1, -1)
	return Vector2((minx + maxx + 1) * 0.5, (miny + maxy + 1) * 0.5)

func _closeup(img: Image, tile, path: String) -> void:
	var fr: Rect2 = tile.get_face_rect_global()
	var pad := 14
	var all: Rect2 = fr.merge(tile.get_global_rect()).grow(pad)
	var crop := img.get_region(Rect2i(all.position, all.size))
	var k := 5
	crop.resize(crop.get_width() * k, crop.get_height() * k, Image.INTERPOLATE_NEAREST)
	_cross(crop, (fr.get_center() - all.position) * k, Color(0, 1, 0, 1), 26)
	_cross(crop, (tile.get_count_rect_global().get_center() - all.position) * k, Color(1, 0, 0, 1), 16)
	# face rect outline (magenta)
	var r := Rect2i(((fr.position - all.position) * k), (fr.size * k))
	for x in range(r.position.x, r.end.x):
		crop.set_pixel(x, r.position.y, Color(1, 0, 1, 1)); crop.set_pixel(x, r.end.y - 1, Color(1, 0, 1, 1))
	for y in range(r.position.y, r.end.y):
		crop.set_pixel(r.position.x, y, Color(1, 0, 1, 1)); crop.set_pixel(r.end.x - 1, y, Color(1, 0, 1, 1))
	crop.save_png(path)

func _cross(im: Image, c: Vector2, col: Color, arm: int) -> void:
	for d in range(-arm, arm + 1):
		for w in range(-1, 2):
			var a := Vector2i(int(c.x) + d, int(c.y) + w)
			var b := Vector2i(int(c.x) + w, int(c.y) + d)
			if Rect2i(0, 0, im.get_width(), im.get_height()).has_point(a):
				im.set_pixelv(a, col)
			if Rect2i(0, 0, im.get_width(), im.get_height()).has_point(b):
				im.set_pixelv(b, col)
