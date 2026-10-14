extends CanvasLayer
## CoachmarkLayer — preload (res://scripts/ui/tutorial/coachmark_layer.gd).
##
## M44 (SB-M44-016/017/018) — the ONE presentation of a single FTUE coachmark: the approved
## tutorial_highlight_ring around the real target control, the approved tutorial_pointer next
## to it, and the approved speech_bubble with live localized copy, plus two small buttons:
## GOT IT (acknowledge this tip) and SKIP TIPS (stop all beginner tips; never the cinematic).
##
## NON-BLOCKING: everything except the two buttons is MOUSE_FILTER_IGNORE, so taps reach the
## real Home / gameplay control underneath (a Supply front, a booster, a Home panel). It sits
## below the app ModalStack (layer 64), owns no state and decides nothing: the app root shows
## exactly the step FtueDirector picked, or hides it. Cue = shape (ring + arrow) + text, never
## colour alone. Reduced Effects: no pointer motion. All tweens die on hide / exit.

signal acknowledged(step_id: String)
signal skip_requested

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

const LAYER := 40   ## above Home / gameplay / Results, below ModalStack (64)
const ART := {
	"ring": "res://assets/ui/final/gameplay/tutorial/tutorial_highlight_ring.png",
	"pointer": "res://assets/ui/final/gameplay/tutorial/tutorial_pointer.png",
	"bubble": "res://assets/ui/final/gameplay/tutorial/speech_bubble.png",
}
## speech_bubble.png (1536x1024): the white text body as fractions of the texture.
const BUBBLE_ASPECT := 1024.0 / 1536.0
const BUBBLE_TEXT := Rect2(0.17, 0.20, 0.66, 0.52)
const GUTTER := 24.0
const MAX_BUBBLE_W := 820.0
const BUTTON_H := 88.0
const INK := Color(0.106, 0.180, 0.349)
const TITLE_PX := 34
const BODY_PX := 28
const MIN_PX := 14

var _root: Control
var _ring: TextureRect
var _pointer: TextureRect
var _bubble: TextureRect
var _title: Label
var _body: Label
var _buttons: HBoxContainer
var _got: Button
var _skip: Button
var _step_id := ""
var _target := Rect2()
var _reduced := false
var _tween: Tween = null
var _shown_log: Array = []   ## step ids in show order (evidence)

func _init() -> void:
	name = "CoachmarkLayer"
	layer = LAYER
	_root = Control.new()
	_root.name = "CoachmarkRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = HomeStyle.make_theme()
	_root.visible = false
	add_child(_root)
	_ring = _art("HighlightRing", ART["ring"], TextureRect.STRETCH_SCALE)
	_pointer = _art("Pointer", ART["pointer"], TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_bubble = _art("SpeechBubble", ART["bubble"], TextureRect.STRETCH_SCALE)
	_title = _label("Title", TITLE_PX)
	_body = _label("Body", BODY_PX)
	_buttons = HBoxContainer.new()
	_buttons.name = "Buttons"
	_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	_root.add_child(_buttons)
	_skip = _button("SkipTips", "FTUE_SKIP_TIPS", Color(0.976, 0.898, 0.769), Color(0.749, 0.604, 0.380), INK)
	_got = _button("GotIt", "FTUE_GOT_IT", HomeStyle.GREEN, HomeStyle.GREEN_EDGE, Color(1, 1, 1))
	_skip.pressed.connect(func(): skip_requested.emit())
	_got.pressed.connect(func():
		if not _step_id.is_empty():
			acknowledged.emit(_step_id))

func _art(n: String, path: String, mode: int) -> TextureRect:
	var t := TextureRect.new()
	t.name = n
	t.texture = load(path) as Texture2D
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = mode
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(t)
	return t

func _label(n: String, px: int) -> Label:
	var l := Label.new()
	l.name = n
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_root.add_child(l)
	return l

func _button(n: String, key: String, bg: Color, edge: Color, ink: Color) -> Button:
	var b := Button.new()
	b.name = n
	b.text = UiText.t(key)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(0, BUTTON_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 28)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, HomeStyle.pad(HomeStyle.box(bg, edge, 4, 30, 4, 4), 18, 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_constant_override("outline_size", 0)
	_buttons.add_child(b)
	return b

# ------------------------------------------------------------------ API --

## Show (or re-place) one step. `target` is the real control's global rect (Rect2() = no
## pointer / ring, e.g. an explanation without a legal control to point at).
func show_step(step_id: String, title: String, body: String, target: Rect2) -> void:
	var changed := step_id != _step_id
	if not changed and _root.visible and target == _target and title == _title.text and body == _body.text:
		return   # periodic re-show of the same tip: nothing moved, keep the running motion
	if changed:
		_shown_log.append(step_id)
	_step_id = step_id
	_target = target
	_title.text = title
	_body.text = body
	_root.visible = true
	_layout()
	_restart_motion()

func hide_step() -> void:
	_kill_tween()
	_step_id = ""
	_target = Rect2()
	_root.visible = false

func is_showing() -> bool:
	return _root.visible and not _step_id.is_empty()

func get_step_id() -> String:
	return _step_id if _root.visible else ""

func get_target() -> Rect2:
	return _target

func shown_log() -> Array:
	return _shown_log.duplicate()

func set_reduced(on: bool) -> void:
	if on == _reduced:
		return
	_reduced = on
	if _root.visible:
		_restart_motion()

func is_reduced() -> bool:
	return _reduced

func has_live_tween() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()

func get_root() -> Control:
	return _root

func get_got_it_button() -> Button:
	return _got

func get_skip_button() -> Button:
	return _skip

func get_bubble() -> TextureRect:
	return _bubble

func get_pointer() -> TextureRect:
	return _pointer

func get_ring() -> TextureRect:
	return _ring

func get_title_label() -> Label:
	return _title

func get_body_label() -> Label:
	return _body

## True when the title/body fit the bubble's text box at the current size (tests).
func text_fits() -> bool:
	var box := _text_box()
	return _title.get_minimum_size().y + _body.get_minimum_size().y <= box.size.y + 0.5

# ------------------------------------------------------------------ layout --

func _viewport_rect() -> Rect2:
	var vp := _root.get_viewport()
	return vp.get_visible_rect() if vp != null else Rect2(0, 0, 1080, 2160)

func _text_box() -> Rect2:
	var b := Rect2(_bubble.position, _bubble.size)
	return Rect2(b.position + b.size * BUBBLE_TEXT.position, b.size * BUBBLE_TEXT.size)

func _layout() -> void:
	var vp := _viewport_rect()
	var w: float = minf(vp.size.x - 2.0 * GUTTER, MAX_BUBBLE_W)
	var h: float = w * BUBBLE_ASPECT
	var block_h: float = h + UiTokens.SPACE_XS + BUTTON_H
	var has_target := _target.size.x > 0.0 and _target.size.y > 0.0
	_ring.visible = has_target
	_pointer.visible = has_target
	var p: float = clampf(vp.size.x * 0.10, 64.0, 128.0)
	var top := vp.position.y + vp.size.y * 0.28
	if has_target:
		var grow: float = maxf(_target.size.x, _target.size.y) * 0.10 + 12.0
		var ring := _target.grow(grow)
		_ring.position = ring.position
		_ring.size = ring.size
		var cx: float = _target.get_center().x
		var room_above: float = ring.position.y - vp.position.y
		var room_below: float = vp.end.y - ring.end.y
		# Never cover the real target: shrink the bubble to the larger free side if needed.
		var room: float = maxf(room_above, room_below) - p - 2.0 * GUTTER
		if block_h > room:
			w = clampf((room - UiTokens.SPACE_XS - BUTTON_H) / BUBBLE_ASPECT, 280.0, w)
			h = w * BUBBLE_ASPECT
			block_h = h + UiTokens.SPACE_XS + BUTTON_H
		if room_above >= p + block_h + GUTTER or room_above >= room_below:
			# Arrow above the target pointing down; the bubble above the arrow.
			_pointer.flip_v = false
			_pointer.position = Vector2(cx - p * 0.5, ring.position.y - p)
			top = _pointer.position.y - block_h - UiTokens.SPACE_XS
		else:
			# Arrow below the target pointing up; the bubble below the arrow.
			_pointer.flip_v = true
			_pointer.position = Vector2(cx - p * 0.5, ring.end.y)
			top = _pointer.position.y + p + UiTokens.SPACE_XS
		_pointer.size = Vector2(p, p)
	top = clampf(top, vp.position.y + GUTTER, vp.end.y - GUTTER - block_h)
	var left: float = vp.position.x + (vp.size.x - w) * 0.5
	_bubble.position = Vector2(left, top)
	_bubble.size = Vector2(w, h)
	_buttons.position = Vector2(left, top + h + UiTokens.SPACE_XS)
	_buttons.size = Vector2(w, BUTTON_H)
	_fit_text()

## Shrink both fonts together until title + body fit the bubble text box (never clipped).
func _fit_text() -> void:
	var box := _text_box()
	var tp := TITLE_PX
	var bp := BODY_PX
	while true:
		_title.add_theme_font_size_override("font_size", tp)
		_body.add_theme_font_size_override("font_size", bp)
		_title.size = Vector2(box.size.x, 0.0)
		_body.size = Vector2(box.size.x, 0.0)
		var th: float = _title.get_minimum_size().y
		var bh: float = _body.get_minimum_size().y
		if th + bh <= box.size.y or bp <= MIN_PX:
			_title.position = box.position + Vector2(0.0, maxf(0.0, (box.size.y - th - bh) * 0.5))
			_title.size = Vector2(box.size.x, th)
			_body.position = _title.position + Vector2(0.0, th)
			_body.size = Vector2(box.size.x, bh)
			return
		tp = maxi(tp - 2, MIN_PX)
		bp = maxi(bp - 2, MIN_PX)

func _restart_motion() -> void:
	_kill_tween()
	_pointer.modulate = Color(1, 1, 1, 1)
	if _reduced or not _pointer.visible or not _root.is_inside_tree():
		return
	var y0: float = _pointer.position.y
	var d: float = -14.0 if not _pointer.flip_v else 14.0
	_tween = _root.create_tween().set_loops()
	_tween.tween_property(_pointer, "position:y", y0 + d, 0.45).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_pointer, "position:y", y0, 0.45).set_trans(Tween.TRANS_SINE)

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _exit_tree() -> void:
	_kill_tween()
