extends Button
## UiShortcutButton — preload (res://scripts/ui/components/ui_shortcut_button.gd).
##
## M42 reusable component (SB-M42-010; V02 card; V04 light panel). Home shortcut PANEL:
## a light, near-transparent panel (style set by the owner screen) with a live label at
## the bottom and a decorative icon (`icon_rect`, never receives input) standing on the
## label that may rise above the panel's top edge. The icon keeps its texture aspect;
## its box is set per shortcut so panels share one size system while icons differ.
## Live notification badge on the panel's top-right corner (hidden at 0). Touch target
## >= TOUCH_MIN. Destinations belonging to later milestones are shown disabled by the
## owner screen, never faked.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const BADGE_SIZE := 52
## Label band at the bottom of the panel (the owner screen's content margin keeps the
## text there).
const LABEL_BAND := 46

var shortcut_id: String
var badge: Label
var icon_rect: TextureRect
var _icon_box := Vector2(160, 160)   ## max icon box; the texture is fitted inside it

func _init(id: String = "shortcut", label_text: String = "") -> void:
	shortcut_id = id
	name = "Shortcut_" + id
	text = label_text
	custom_minimum_size = Vector2(UiTokens.TOUCH_MIN * 2, UiTokens.TOUCH_MIN)
	add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	focus_mode = Control.FOCUS_NONE
	clip_text = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_rect = TextureRect.new()
	icon_rect.name = "ShortcutIcon_" + id
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)
	badge = Label.new()
	badge.name = "Badge"
	badge.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.890, 0.157, 0.200, 1.0)
	sb.border_color = Color(1, 1, 1, 1)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(BADGE_SIZE / 2)
	badge.add_theme_stylebox_override("normal", sb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -BADGE_SIZE + 2
	badge.offset_right = 2
	badge.offset_top = -12
	badge.offset_bottom = BADGE_SIZE - 12
	badge.visible = false
	add_child(badge)
	resized.connect(_layout_icon)

func set_badge(count: int) -> void:
	badge.text = str(count)
	badge.visible = count > 0

func set_label(t: String) -> void:
	text = t

func set_icon_texture(tex: Texture2D) -> void:
	icon_rect.texture = tex
	_layout_icon()

## Max icon box (px). The icon is fitted inside it keeping aspect, centred, standing on
## the label band; it may extend above the panel.
func set_icon_box(box: Vector2) -> void:
	_icon_box = box
	_layout_icon()

func get_icon_box() -> Vector2:
	return _icon_box

## Drawn icon size (texture fitted in the icon box).
func get_icon_draw_size() -> Vector2:
	var t := icon_rect.texture
	if t == null or t.get_height() == 0:
		return Vector2.ZERO
	var a := float(t.get_width()) / float(t.get_height())
	return Vector2(_icon_box.y * a, _icon_box.y) if _icon_box.y * a <= _icon_box.x else Vector2(_icon_box.x, _icon_box.x / a)

func _layout_icon() -> void:
	var d := get_icon_draw_size()
	if d == Vector2.ZERO:
		d = _icon_box
	icon_rect.size = d
	icon_rect.position = Vector2((size.x - d.x) * 0.5, size.y - LABEL_BAND - d.y)
