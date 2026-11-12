extends "res://tests/m49_surface_matrix.gd"
## M50 rendered text contrast + font floor (SB-M50-004, SB-M50-007) on every M43/M44 surface the
## factory 118 walk reaches (tests/m49_surface_matrix.gd rows: Home + every Home popup, Collection,
## Robots, ceremonies, packs, gameplay HUD + its popups, Level Intro, the win animation, Results LOST), REAL app
## root on throw-away saves, one phone size: 1080x2400.
##   c01 every visible Label / Button text (disabled buttons are WCAG-exempt inactive controls):
##       render the surface (A), hide only the text colours (B), ink = pixels where A != B inside
##       the text rect. Background = the B pixel of median luminance under the ink. Fill = the
##       theme font colour x the modulate chain, blended over that background. An outline of
##       >= 2 px (alpha >= 0.5) is the glyph's own immediate background, so the ratio is the
##       better of fill/background and fill/outline. Rule: >= 4.5:1, large text >= 3:1, large =
##       >= 24 design px with a bold face (weight >= 700) or >= 32 design px.
##   c02 every visible (English) text is >= FONT_FLOOR design px (the floor and the fit_font
##       long-locale finding: tests/m50_accessibility_audit.gd a06).
## Needs a rendering driver (pixel readback): run WITHOUT --headless; headless prints NOT_RUN and
## exits 1. Touch sizes / clipping on these surfaces: tests/m49_surface_matrix.gd (not repeated).
##
## Run: godot --path . -s res://tests/m50_contrast_surfaces.gd   (windowed, ~1 min, local only)

const A11y = preload("res://tools/accessibility_audit.gd")
const PHONE := Vector2i(1080, 2400)
const NORMAL_MIN := 4.5
const LARGE_MIN := 3.0
const LARGE_BOLD_PX := 24
const LARGE_PX := 32
const FONT_FLOOR: int = preload("res://tests/m50_accessibility_audit.gd").FONT_FLOOR
const LABEL_COLORS := ["font_color", "font_outline_color", "font_shadow_color"]
const BUTTON_COLORS := ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]

var _measured := 0
var _exempt := 0
var _semantic := 0
var _unreached := 0
var _contrast_bad: Array = []
var _small: Array = []
var _min_font := 1000

func _initialize() -> void:
	EXPECTED_CASES = ["c01_text_contrast", "c02_font_floor"]
	if DisplayServer.get_name() == "headless":
		print("M50 contrast surfaces evidence: NOT_RUN (needs a rendering driver; run without --headless)")
		quit(1)
		return
	await _setup()
	print("[c01 rendered WCAG contrast of every visible text, c02 font floor %d px, at %s]" % [FONT_FLOOR, str(PHONE)])
	await _walk(PHONE)
	var missing: Array = []
	for row in _rows():
		if int(_walked.get(row, 0)) != 1:
			missing.append(row)
	_ok(missing.is_empty(), "every inventory row walked once %s" % str(missing))
	_ok(_measured > 400 and _contrast_bad.is_empty(), "%d text controls measured (%d disabled exempt, %d transparent semantic, %d never scrolled into view): normal >= %.1f, large >= %.1f %s" % [_measured, _exempt, _semantic, _unreached, NORMAL_MIN, LARGE_MIN, str(_contrast_bad)])
	_complete("c01_text_contrast")
	_ok(_small.is_empty(), "smallest visible text %d px >= floor %d %s" % [_min_font, FONT_FLOOR, str(_small)])
	_complete("c02_font_floor")
	_finish()

## One surface: two renders per scroll page, every visible text measured once. Lists are paged
## through (scroll_vertical) so rows below the fold are measured too, then scrolled back.
func _scan(_phys: Vector2i, _lv: Vector2i, surf: String, node, _extra: Array = []) -> void:
	if node == null or not is_instance_valid(node):
		_ok(false, "%s: surface missing" % surf)
		return
	_walked[surf] = int(_walked.get(surf, 0)) + 1
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if node == _root.get_results_screen():
		_root.move_child(node, _root.get_child_count() - 1)   # main.gd raises Results the same way on route entry
	await create_timer(0.6).timeout   # popup open tweens settle: A and B must differ only by the text
	var seen := {}
	var bad: Array = await _pass(surf, node, seen)
	for sc in node.find_children("*", "ScrollContainer", true, false):
		var s := sc as ScrollContainer
		if not s.is_visible_in_tree():
			continue
		var bar := s.get_v_scroll_bar()
		while s.scroll_vertical + s.size.y < bar.max_value - 1.0:
			s.scroll_vertical += int(s.size.y * 0.8)
			bad.append_array(await _pass(surf, node, seen))
		s.scroll_vertical = 0
	var left := 0
	for n in node.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and not String(n.text).strip_edges().is_empty() and not seen.has(n.get_instance_id()):
			left += 1
	_unreached += left
	print("    %s: %d texts, %d never in view %s" % [surf, seen.size(), left, "ok" if bad.is_empty() else str(bad)])
	_contrast_bad.append_array(bad)

## Measure the texts of `node` currently in view that `seen` does not hold yet.
func _pass(surf: String, node, seen: Dictionary) -> Array:
	var vp := Rect2(Vector2.ZERO, Vector2(_sub.size))
	var a: Image = await _snap()
	var items: Array = []
	for n in [node] + node.find_children("*", "", true, false):
		if not (n is Label or n is Button) or seen.has(n.get_instance_id()) or not (n as Control).is_visible_in_tree() or String(n.text).strip_edges().is_empty():
			continue
		var c := n as Control
		var r := (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)).intersection(_clip_rect(c, true)).intersection(vp)
		if r.size.y < c.size.y * 0.6:
			continue   # mostly scrolled out of view: measured on a later page
		seen[n.get_instance_id()] = true
		if c is BaseButton and (c as BaseButton).disabled:
			_exempt += 1
			continue
		if (c.get_theme_color("font_color") * _modulate(c)).a < 0.05:
			_semantic += 1   # transparent semantic text (e.g. the HUD Pause / 2x button value); the glyph / labels over it are measured
			continue
		items.append([c, r])
	var saved: Array = []
	for it in items:
		saved.append(_hide_text(it[0]))
	var b: Image = await _snap()
	for i in range(items.size()):
		_restore_text(items[i][0], saved[i])
	await _frames(2)
	var bad: Array = []
	for it in items:
		var why := _measure(surf, it[0], it[1], a, b)
		if not why.is_empty():
			bad.append(why)
	return bad

func _snap() -> Image:
	await _frames(3)
	return _sub.get_texture().get_image()

func _hide_text(c: Control) -> Dictionary:
	var old := {}
	for k in (LABEL_COLORS if c is Label else BUTTON_COLORS):
		old[k] = c.get_theme_color(k) if c.has_theme_color_override(k) else null
		c.add_theme_color_override(k, Color(0, 0, 0, 0))
	return old

func _restore_text(c: Control, old: Dictionary) -> void:
	for k in old:
		if old[k] == null:
			c.remove_theme_color_override(k)
		else:
			c.add_theme_color_override(k, old[k])

## "" = readable; else the finding. Also records the font floor.
func _measure(surf: String, c: Control, r: Rect2, a: Image, b: Image) -> String:
	if String(c.text).strip_edges().is_empty():
		return ""   # cleared by the surface's own refresh after the first render (booster Safety line)
	var fs := c.get_theme_font_size("font_size")
	var tag := "%s/%s '%s' %dpx" % [surf, c.name, String(c.text).left(18).replace("\n", " "), fs]
	_min_font = mini(_min_font, fs)
	if fs < FONT_FLOOR:
		_small.append(tag)
	var bg_px: Array = []
	for y in range(int(r.position.y), int(r.end.y)):
		for x in range(int(r.position.x), int(r.end.x)):
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			if maxf(maxf(absf(pa.r - pb.r), absf(pa.g - pb.g)), absf(pa.b - pb.b)) > 0.08:
				bg_px.append(pb)
	_measured += 1
	if bg_px.size() < 4:
		return tag + " no rendered ink"
	bg_px.sort_custom(func(p, q): return A11y.relative_luminance(p) < A11y.relative_luminance(q))
	var bg: Color = bg_px[bg_px.size() / 2]
	var mod := _modulate(c)
	var fill := _over(c.get_theme_color("font_color") * mod, bg)
	var ratio := A11y.contrast_ratio(fill, bg)
	var oc := c.get_theme_color("font_outline_color") * mod
	if c.get_theme_constant("outline_size") >= 2 and oc.a >= 0.5:
		ratio = maxf(ratio, A11y.contrast_ratio(fill, _over(oc, bg)))
	var w := c.get_theme_font("font").get_font_weight()
	var large := fs >= LARGE_PX or (fs >= LARGE_BOLD_PX and w >= 700)
	var need := LARGE_MIN if large else NORMAL_MIN
	if ratio >= need:
		return ""
	return "%s %.2f:1 < %.1f (fill %s bg %s)" % [tag, ratio, need, fill.to_html(false), bg.to_html(false)]

static func _modulate(c: CanvasItem) -> Color:
	var m := c.self_modulate
	var n: Node = c
	while n is CanvasItem:
		m *= (n as CanvasItem).modulate
		n = n.get_parent()
	return m

static func _over(fg: Color, bg: Color) -> Color:
	return Color(lerpf(bg.r, fg.r, fg.a), lerpf(bg.g, fg.g, fg.a), lerpf(bg.b, fg.b, fg.a))

func _title() -> String:
	return "M50 contrast surfaces"
