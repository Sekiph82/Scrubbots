extends Control
## ColorBatchTile — M28-C002-C004 the ONE shared presentation of a colour/batch tile.
## Preload this script (res://scripts/ui/color_batch_tile.gd); no global class_name (AL-001).
##
## Used by the five/six execution slots (BatchSlotView) AND by every Batch Supply tile
## (BatchSupplyPanel front + preview rows), so both read as the same rounded 3D
## cartridge: a rounded coloured TOP FACE (exact Palette v3 colour), a restrained top
## highlight, a visible BASE (exact batch colour, same as the face) projecting under the face with a compact
## shadow, and a large white count with a dark outline.
##
## COUNT CENTRING (owner correction, blocking): the count Label is a child of the FACE
## panel and fills it (anchors 0..1, zero offsets, horizontal + vertical CENTER). Its rect
## therefore IS the face rect, so its centre == the face centre on both axes by
## construction — independent of the lower base, of any sibling / hidden state line, of
## container spacing, of the digit count and of the size. No per-value offset exists.
##
## Presentation only: it holds scalar colour/count/state, no engine reference, no input.

const OUTLINE_COLOR := Color(0.03, 0.04, 0.09, 1.0)
const ACTIVE_GLOW := Color(0.30, 0.90, 1.0, 1.0)
const EMPTY_WELL := Color(0.05, 0.08, 0.20, 0.55)
const EMPTY_RIM := Color(0.62, 0.70, 0.90, 0.55)

## Visible lower base as a fraction of the tile height (the face is the rest).
const BASE_FRACTION := 0.17
const FACE_FONT_FRACTION := 0.56
const MAX_TEXT_WIDTH_FRACTION := 0.86
const DIGIT_EM := 0.68   # conservative digit advance of the emboldened default font
const FONT_STEP := 4

static var _font: FontVariation

var _color: Color = Color(1, 0, 1, 1)
var _text := ""
var _empty := true
var _draw_well := true
var _active := false
var _preview := false
var _inset := 0.0

var _glow: Panel
var _base: Panel
var _face: Panel
var _highlight: Panel
var _count: Label
var _well: Panel

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow = _panel("Glow")
	_base = _panel("Base")
	_face = _panel("Face")
	_highlight = _panel("Highlight", _face)
	_count = Label.new()
	_count.name = "Count"
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)   # == the face rect
	_count.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_count.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	_count.add_theme_font_override("font", _shared_font())
	_face.add_child(_count)
	_well = _panel("EmptyWell")
	_refresh()

func _panel(node_name: String, parent: Node = null) -> Panel:
	var p := Panel.new()
	p.name = node_name
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(p)
	return p

static func _shared_font() -> FontVariation:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = 0.8
	return _font

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

# ---------------------------------------------------------------- public API --

## Occupied tile: canonical face colour + live count text.
func set_batch(color: Color, count_text: String) -> void:
	_color = color
	_text = count_text
	_empty = false
	_refresh()

## Empty tile: no face, no count. `draw_well` shows a neutral recessed placeholder; pass false
## where the housing is baked into shell art (the baked frame/cell is then the placeholder).
func set_empty(draw_well: bool = true) -> void:
	_text = ""
	_empty = true
	_active = false
	_draw_well = draw_well
	_refresh()

func set_active(on: bool) -> void:
	_active = on and not _empty
	_refresh()

## Lower-emphasis, non-interactive-looking tile (Batch Supply preview rows).
func set_preview(on: bool) -> void:
	_preview = on
	_refresh()

## Shrinks the drawn tile inside its own rect (px per side); the rect itself is untouched.
func set_inset(px: float) -> void:
	_inset = maxf(px, 0.0)
	_layout()

# ------------------------------------------------------------------- layout ----

func _tile_rect() -> Rect2:
	var s := size
	var d := minf(_inset, minf(s.x, s.y) * 0.25)
	return Rect2(Vector2(d, d), Vector2(maxf(s.x - d * 2.0, 1.0), maxf(s.y - d * 2.0, 1.0)))

func _face_rect_local() -> Rect2:
	var r := _tile_rect()
	var base_h := roundf(r.size.y * BASE_FRACTION)
	return Rect2(r.position, Vector2(r.size.x, r.size.y - base_h))

func _layout() -> void:
	if _face == null:
		return
	var r := _tile_rect()
	var f := _face_rect_local()
	var radius := int(roundf(minf(f.size.x, f.size.y) * 0.24))
	_glow.position = r.position - Vector2(2, 2)
	_glow.size = r.size + Vector2(4, 4)
	# The base spans from mid-face to the bottom so it shows as the strip under the face.
	var base_top: float = f.position.y + f.size.y * 0.5
	_base.position = Vector2(r.position.x, base_top)
	_base.size = Vector2(r.size.x, r.end.y - base_top)
	_face.position = f.position
	_face.size = f.size
	_well.position = r.position
	_well.size = r.size
	# Restrained top highlight band inside the face (never over its centre).
	_highlight.position = Vector2(f.size.x * 0.14, f.size.y * 0.08)
	_highlight.size = Vector2(f.size.x * 0.72, f.size.y * 0.13)
	_style(radius)
	_fit_text()

func _sb(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb

func _style(radius: int) -> void:
	var a: float = 0.55 if _preview else 1.0
	# Base: platform in the batch colour + compact shadow.
	# V02 (owner): the base BODY is the exact batch colour, identical to the face; only its thin
	# bottom edge is a darker shade of the same hue (depth), like the face rim.
	var base := _sb(_color, radius)
	base.border_color = _color.darkened(0.32)
	base.border_width_bottom = 3
	base.shadow_color = Color(0, 0, 0, 0.34 * a)
	base.shadow_size = 4 if not _preview else 2
	base.shadow_offset = Vector2(0, 3)
	_base.add_theme_stylebox_override("panel", base)
	# Face: exact canonical colour (only a thin darker rim of the same hue).
	var face := _sb(_color, radius)
	face.set_border_width_all(2)
	face.border_color = _color.darkened(0.32)
	_face.add_theme_stylebox_override("panel", face)
	var hi := _sb(Color(1, 1, 1, 0.16 if not _active else 0.24), int(radius * 0.7))
	_highlight.add_theme_stylebox_override("panel", hi)
	var glow := _sb(Color(0, 0, 0, 0), radius + 2)
	glow.set_border_width_all(3)
	glow.border_color = ACTIVE_GLOW
	glow.shadow_color = Color(ACTIVE_GLOW.r, ACTIVE_GLOW.g, ACTIVE_GLOW.b, 0.55)
	glow.shadow_size = 6
	_glow.add_theme_stylebox_override("panel", glow)
	var well := _sb(EMPTY_WELL, radius)
	well.set_border_width_all(2)
	well.border_color = EMPTY_RIM
	_well.add_theme_stylebox_override("panel", well)

## Font size follows the face; it only shrinks (never offsets) so 1-3 digits always fit.
## Sized arithmetically (a digit is <= DIGIT_EM wide) and quantised to FONT_STEP so a session
## reuses a handful of font-cache sizes instead of one per tile geometry.
func _fit_text() -> void:
	var f := _face_rect_local()
	var digits := maxi(_text.length(), 1)
	var fs: float = minf(f.size.y * FACE_FONT_FRACTION, f.size.x * MAX_TEXT_WIDTH_FRACTION / (digits * DIGIT_EM))
	var q := maxi(int(floorf(fs / FONT_STEP)) * FONT_STEP, 12)
	_count.add_theme_font_size_override("font_size", q)
	_count.add_theme_constant_override("outline_size", maxi(int(roundf(q * 0.24 / 2.0)) * 2, 4))

func _refresh() -> void:
	if _face == null:
		return
	_glow.visible = _active and not _empty
	_base.visible = not _empty
	_face.visible = not _empty
	_well.visible = _empty and _draw_well
	_count.text = "" if _empty else _text
	_layout()

# --------------------------------------------------- read-only test accessors ---

func is_empty_tile() -> bool:
	return _empty

func is_active_style() -> bool:
	return _active

func is_preview() -> bool:
	return _preview

func get_face_color() -> Color:
	return _color

func get_count_text() -> String:
	return _count.text

func get_count_label() -> Label:
	return _count

func get_face_panel() -> Panel:
	return _face

func get_base_panel() -> Panel:
	return _base

func get_highlight_panel() -> Panel:
	return _highlight

## GLOBAL rect of the coloured top face (the centring reference).
func get_face_rect_global() -> Rect2:
	return _face.get_global_rect()

## GLOBAL rect of the count label; its centre must equal get_face_rect_global().get_center().
func get_count_rect_global() -> Rect2:
	return _count.get_global_rect()

## Signed offset (count centre - face centre) in GLOBAL px; (0,0) when exactly centred.
func get_count_center_delta() -> Vector2:
	return get_count_rect_global().get_center() - get_face_rect_global().get_center()
