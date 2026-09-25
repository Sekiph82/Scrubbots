extends RefCounted
## HomeStyle — preload (res://scripts/ui/home/home_style.gd).
##
## M42 master-convergence V02: the ONE place that defines the Home visual language
## (blue/cyan beveled game-UI panels, green hero CTA, gold meter fill, navy dock) as
## native Godot StyleBoxes + a Theme. Pure presentation; no state.

const NAVY := Color(0.043, 0.114, 0.259)          ## deep dock/panel navy
const PANEL := Color(0.078, 0.200, 0.450, 0.94)   ## meter / track panels
const CARD := Color(0.110, 0.337, 0.702)          ## shortcut / profile cards
const CARD_HOVER := Color(0.149, 0.420, 0.820)
const CARD_PRESSED := Color(0.078, 0.255, 0.560)
const CARD_DISABLED := Color(0.098, 0.227, 0.451)
const EDGE := Color(0.620, 0.894, 1.0)            ## light cyan rim
const EDGE_DIM := Color(0.357, 0.557, 0.788)
const GLOW := Color(0.227, 0.659, 1.0)
const OUTLINE := Color(0.035, 0.086, 0.216)       ## text outline navy
const GREEN := Color(0.337, 0.769, 0.169)
const GREEN_HOVER := Color(0.408, 0.847, 0.227)
const GREEN_PRESSED := Color(0.275, 0.651, 0.129)
const GREEN_EDGE := Color(0.137, 0.431, 0.051)
const GREEN_DISABLED := Color(0.380, 0.490, 0.345)
const GOLD := Color(1.0, 0.765, 0.102)
const SUBTITLE := Color(1.0, 0.925, 0.380)
const BADGE := Color(0.890, 0.157, 0.200)
const TEXT := Color(1, 1, 1)
const TEXT_DISABLED := Color(0.800, 0.870, 0.980)

static func box(bg: Color, edge: Color, edge_w: int, radius: int, shadow: int = 8, bottom_extra: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(edge_w)
	s.border_width_bottom = edge_w + bottom_extra
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, shadow * 0.5)
	s.anti_aliasing = true
	return s

static func pad(s: StyleBoxFlat, h: int, v: int) -> StyleBoxFlat:
	s.content_margin_left = h
	s.content_margin_right = h
	s.content_margin_top = v
	s.content_margin_bottom = v
	return s

## Branded shortcut card: strong opaque body, cyan rim, readable disabled state.
static func style_card_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", pad(box(CARD, EDGE, 4, 26, 8, 4), 10, 8))
	b.add_theme_stylebox_override("hover", pad(box(CARD_HOVER, EDGE, 4, 26, 8, 4), 10, 8))
	b.add_theme_stylebox_override("pressed", pad(box(CARD_PRESSED, EDGE, 4, 26, 4, 2), 10, 8))
	b.add_theme_stylebox_override("disabled", pad(box(CARD_DISABLED, EDGE_DIM, 4, 26, 6, 4), 10, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colors(b)

## Hero Play CTA: dominant green, thick dark bevel, big rounded body.
static func style_play_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", pad(box(GREEN, GREEN_EDGE, 6, 48, 12, 12), 36, 10))
	b.add_theme_stylebox_override("hover", pad(box(GREEN_HOVER, GREEN_EDGE, 6, 48, 12, 12), 36, 10))
	b.add_theme_stylebox_override("pressed", pad(box(GREEN_PRESSED, GREEN_EDGE, 6, 48, 6, 6), 36, 10))
	b.add_theme_stylebox_override("disabled", pad(box(GREEN_DISABLED, Color(0.25, 0.32, 0.23), 6, 48, 8, 10), 36, 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colors(b)
	b.add_theme_color_override("font_outline_color", GREEN_EDGE)

## Bottom-nav tab: framed tab; `selected` = raised bright Home state.
static func style_nav_button(b: Button, selected: bool) -> void:
	if selected:
		var s := pad(box(Color(0.180, 0.506, 0.918), EDGE, 5, 26, 10, 6), 6, 6)
		s.expand_margin_top = 16
		for state in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, s)
	else:
		b.add_theme_stylebox_override("normal", pad(box(Color(0.090, 0.235, 0.522), EDGE_DIM, 2, 20, 0), 6, 6))
		b.add_theme_stylebox_override("hover", pad(box(Color(0.125, 0.300, 0.620), EDGE, 2, 20, 0), 6, 6))
		b.add_theme_stylebox_override("pressed", pad(box(Color(0.070, 0.190, 0.450), EDGE, 2, 20, 0), 6, 6))
		b.add_theme_stylebox_override("disabled", pad(box(Color(0.082, 0.208, 0.470), EDGE_DIM, 2, 20, 0), 6, 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colors(b)

static func style_icon_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", box(CARD, EDGE, 4, 28, 8, 4))
	b.add_theme_stylebox_override("hover", box(CARD_HOVER, EDGE, 4, 28, 8, 4))
	b.add_theme_stylebox_override("pressed", box(CARD_PRESSED, EDGE, 4, 28, 4, 2))
	b.add_theme_stylebox_override("disabled", box(CARD_DISABLED, EDGE_DIM, 4, 28, 6, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

static func _text_colors(b: Button) -> void:
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, TEXT)
	b.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	b.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.82))
	b.add_theme_color_override("font_outline_color", OUTLINE)
	b.add_theme_constant_override("outline_size", 10)

static func panel(bg: Color = PANEL, edge: Color = GLOW, radius: int = 30, h: int = 18, v: int = 12) -> StyleBoxFlat:
	return pad(box(bg, edge, 4, radius, 10, 2), h, v)

## Gold, thick meter fill on a dark trough.
static func style_meter(bar: ProgressBar, fill: Color = GOLD, height: int = 44) -> void:
	bar.custom_minimum_size.y = height
	var bg := box(Color(0.020, 0.071, 0.200), Color(0.0, 0.0, 0.0, 0.6), 3, height / 2, 0)
	var fg := box(fill, fill.lightened(0.35), 3, height / 2, 0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

## Home-wide typography: bolder face (embolden of the project default font; no external
## font is added) + navy outline on every Label/Button for contrast over art.
static func make_theme() -> Theme:
	var t := Theme.new()
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 0.9
	t.default_font = fv
	for type in ["Label", "Button"]:
		t.set_color("font_outline_color", type, OUTLINE)
		t.set_constant("outline_size", type, 9)
		t.set_color("font_color", type, TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	t.set_constant("shadow_offset_y", "Label", 3)
	return t

static func label(text: String, size: int, color: Color = TEXT, outline: int = 9) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func art(name: String) -> TextureRect:
	var t := TextureRect.new()
	t.name = name
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
