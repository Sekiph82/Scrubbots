extends "res://tests/m49_surface_matrix.gd"
## Popup frame fit (SB-PHONE-2026-11-12-A, owner phone test 2026-11-12: footer buttons on the
## corner orbs, rows touching the side bars, EMEĞİ GEÇENLER / "Temizlenen Bölüm" spilling out,
## TEKRAR HOŞ GELDİN wrapping). REAL app root on throw-away saves, every surface the factory 118
## walk reaches (tests/m49_surface_matrix.gd: Welcome Back, Home popups incl. Settings, Shop,
## Achievements, Profile, Collection, Robots, Daily, Rewarded Ads, Life, Gift, Tasks, Events,
## card / robot detail, exchange, acquisition, generic popups, ceremonies, gameplay popups):
##   f01 every BasePopup.FRAMES kind, read from its PNG: the `clear` rect perimeter is cream
##       interior (within 60 of the centre colour, opaque), and the stretched band between the
##       `patch` top / bottom rows is cream across the clear width (no corner art stretches)
##   f02 English, f03 real Turkish table, at 720x1520 and 1080x2400: in every FrameBox popup
##       the Body is no wider than its slot, each visible Control of the Body (clipped by its
##       scroll / clip ancestors) lies inside
##       the frame's clear interior, and its corners sample cream through the live 9-slice
##       mapping; every Label / Button text fits its rect (one-line text <= width; a button's
##       text also clears its rounded ends: max(content margin, corner radius / 2) per side);
##       every popup title is one line.
## Windowed with `-- --capture=DIR`: also saves a JPG of each owner-listed surface per size and
## locale to DIR (evidence only; not a pass condition).
##
## Run: godot --headless --path . -s res://tests/m49_popup_frame_fit.gd

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const SIZES := [Vector2i(720, 1520), Vector2i(1080, 2400)]
const CREAM_TOL := 60.0 / 255.0
const CAPTURE := ["comeback", "shop", "settings", "achievements", "collection", "robots", "profile", "rewarded_ads",
	"daily", "life", "gift_bar", "tasks", "events", "robot_detail", "cards_exchange", "collection_set"]

var _cap_dir := ""
var _loc := "en"
var _art: Dictionary = {}     ## frame path -> Image
var _frame_count := 0
var _ctrl_count := 0
var _text_count := 0
var _bad: Array = []

func _initialize() -> void:
	EXPECTED_CASES = ["f01_frame_art_measured", "f02_chrome_clear_en", "f03_chrome_clear_tr"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			_cap_dir = a.trim_prefix("--capture=")
	if DisplayServer.get_name() == "headless":
		_cap_dir = ""
	await _setup()
	_f01()
	for loc in ["en", "tr"]:
		_loc = loc
		UiText.locale = loc
		print("[%s %s: FrameBox content inside the clear interior, text inside its rect]" % ["f02" if loc == "en" else "f03", loc])
		_frame_count = 0
		_ctrl_count = 0
		_text_count = 0
		_bad = []
		for phys in SIZES:
			await _walk(phys)
		_ok(_frame_count >= 2 * 40 and _ctrl_count > 1000 and _text_count > 1000, "%s: %d framed surfaces, %d controls, %d texts measured" % [loc, _frame_count, _ctrl_count, _text_count])
		for b in _bad.slice(0, 150):
			print("    bad: " + String(b))
		_ok(_bad.is_empty(), "%s: nothing on the frame chrome, no text outside its rect (%d findings)" % [loc, _bad.size()])
		_complete("f02_chrome_clear_en" if loc == "en" else "f03_chrome_clear_tr")
	UiText.locale = "en"
	_finish()

func _title() -> String:
	return "M49 popup frame fit"

# ------------------------------------------------------------------ f01 ----

func _f01() -> void:
	print("[f01 frame art: clear rect on cream, stretched band free of corner art]")
	for kind in BasePopup.FRAMES:
		var spec: Dictionary = BasePopup.FRAMES[kind]
		var img := _image(spec["path"])
		var w := img.get_width()
		var h := img.get_height()
		var cl: Array = spec["clear"]
		var pa: Array = spec["patch"]
		var x0: int = cl[0]
		var y0: int = cl[1]
		var x1: int = w - 1 - int(cl[2])
		var y1: int = h - 1 - int(cl[3])
		var off: Array = []
		for x in range(x0, x1 + 1):
			for y in [y0, y1]:
				if not _cream(img, x, y):
					off.append(Vector2i(x, y))
		for y in range(y0, y1 + 1):
			for x in [x0, x1]:
				if not _cream(img, x, y):
					off.append(Vector2i(x, y))
		var band: Array = []
		for y in range(int(pa[1]), h - int(pa[3])):
			for x in range(x0, x1 + 1, 2):
				if not _cream(img, x, y):
					band.append(Vector2i(x, y))
					break
		_ok(Vector2(w, h) == spec["tex"] and off.is_empty() and band.is_empty() and int(pa[1]) >= y0 and int(pa[3]) >= int(cl[3]),
			"%s %dx%d: clear %s perimeter cream (%d off), patch %s band cream (%d rows off) %s" % [kind, w, h, str(cl), off.size(), str(pa), band.size(), str(off.slice(0, 4) + band.slice(0, 4))])
	_complete("f01_frame_art_measured")

func _image(path: String) -> Image:
	if not _art.has(path):
		_art[path] = Image.load_from_file(ProjectSettings.globalize_path(path))
	return _art[path]

func _cream(img: Image, x: int, y: int) -> bool:
	var c := img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
	var m := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	return c.a >= 200.0 / 255.0 and absf(c.r - m.r) + absf(c.g - m.g) + absf(c.b - m.b) < CREAM_TOL

# ------------------------------------------------------------- f02 / f03 ----

## Walked surfaces carrying a FrameBox (BasePopup, Settings) are measured; the rest only count
## as walked. Owner-listed surfaces are captured when a capture dir is given.
func _scan(phys: Vector2i, _lv: Vector2i, surf: String, node, _extra: Array = []) -> void:
	if node == null or not is_instance_valid(node):
		_bad.append("%s %s missing" % [str(phys), surf])
		return
	_walked[surf] = int(_walked.get(surf, 0)) + 1
	var frames: Array = node.find_children("*", "", true, false).filter(func(n): return n is BasePopup.FrameBox and (n as Control).is_visible_in_tree())
	if node is BasePopup.FrameBox:
		frames.append(node)
	for fb in frames:
		_frame_count += 1
		_check_frame(phys, surf, fb)
	if not _cap_dir.is_empty() and CAPTURE.has(surf):
		_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await create_timer(0.6).timeout   # open tweens settle
		var img := _sub.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_cap_dir)
		img.save_jpg("%s/%s_%dx%d_%s.jpg" % [_cap_dir, _loc, phys.x, phys.y, surf], 0.85)

func _check_frame(phys: Vector2i, surf: String, fb) -> void:
	var clear: Rect2 = fb.get_clear_rect()
	var img := _image(fb.get_texture_path())
	var tag := "%s %s %s" % [_loc, str(phys), surf]
	if fb._body.size.x > fb.body_width() + 0.5:
		_bad.append("%s Body %d px wider than its %d px slot (content min width)" % [tag, int(fb._body.size.x), int(fb.body_width())])
	for n in fb._body.find_children("*", "", true, false):
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var c := n as Control
		var r := c.get_global_rect().intersection(_clip_rect(c, true))
		if not r.has_area():
			continue
		_ctrl_count += 1
		if not _inside(r, clear):
			_bad.append("%s %s %s outside clear %s" % [tag, _path(fb, c), _rs(r), _rs(clear)])
		else:
			for p in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
				var t := _to_texture(fb, img, p)
				if not _cream(img, int(t.x), int(t.y)):
					_bad.append("%s %s corner %s on chrome (tex %s)" % [tag, _path(fb, c), str(p), str(Vector2i(t))])
					break
		if (c is Label or c is Button) and not String(c.get("text")).strip_edges().is_empty():
			_text_count += 1
			var why := _overflow(c)
			if not why.is_empty():
				_bad.append("%s %s '%s' %s" % [tag, _path(fb, c), String(c.get("text")).left(24), why])
	var title := fb._body.find_child("Title", true, false) as Label
	if title != null and title.is_visible_in_tree() and title.get_line_count() != 1:
		_bad.append("%s title '%s' %d lines" % [tag, title.text, title.get_line_count()])

## Live 9-slice mapping (FrameBox: uniform scale k, chrome = size / k, patch rows fixed, the
## band between them stretched) from a global point to the frame PNG pixel under it.
func _to_texture(fb, img: Image, p: Vector2) -> Vector2:
	var k: float = fb._k()
	var v: Vector2 = (p - fb.get_global_rect().position) / k
	var ch: Vector2 = fb.size / k
	var tex := Vector2(img.get_width(), img.get_height())
	var pa: Array = fb._patch
	return Vector2(_axis(v.x, ch.x, tex.x, pa[0], pa[2]), _axis(v.y, ch.y, tex.y, pa[1], pa[3]))

static func _axis(v: float, ch: float, tex: float, a: float, b: float) -> float:
	if v <= a:
		return v
	if v >= ch - b:
		return tex - (ch - v)
	return a + (v - a) * (tex - a - b) / maxf(ch - a - b, 1.0)

## Why `c`'s text leaves its rect ("" = it fits): autowrap Labels may not lose lines; one-line
## text must fit the width; a Button's text also keeps clear of its rounded ends.
func _overflow(c: Control) -> String:
	var fs := c.get_theme_font_size("font_size")
	var font := c.get_theme_font("font")
	var txt := String(c.get("text"))
	if c is Label:
		var l := c as Label
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return "lines %d>%d" % [l.get_line_count(), l.get_visible_line_count()] if l.get_line_count() > l.get_visible_line_count() else ""
		var lw := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		return "w %d>%d" % [int(lw), int(l.size.x)] if lw > l.size.x + 1.0 else ""
	var b := c as Button
	if b.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return ""
	var sb := b.get_theme_stylebox("normal")
	var side := sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		side = maxf(f.get_margin(SIDE_LEFT), f.corner_radius_top_left * 0.5) + maxf(f.get_margin(SIDE_RIGHT), f.corner_radius_top_right * 0.5)
	var avail := b.size.x - side
	if b.icon != null and not b.expand_icon:
		avail -= b.icon.get_width() + b.get_theme_constant("h_separation")
	var tw := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x   # widest line
	return "w %d>%d" % [int(tw), int(avail)] if tw > avail + 1.0 else ""
