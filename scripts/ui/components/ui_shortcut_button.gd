extends Button
## UiShortcutButton — preload (res://scripts/ui/components/ui_shortcut_button.gd).
##
## M42 reusable component (SB-M42-010): Home shortcut. Touch target >= TOUCH_MIN in both
## axes, optional decorative icon (Button icon, no baked text), live label and a live
## notification badge (hidden at 0). Destinations that belong to later milestones are
## shown disabled by the owner screen, never faked.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var shortcut_id: String
var badge: Label

func _init(id: String = "shortcut", label_text: String = "") -> void:
	shortcut_id = id
	name = "Shortcut_" + id
	text = label_text
	custom_minimum_size = Vector2(UiTokens.TOUCH_MIN * 2, UiTokens.TOUCH_MIN)
	add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge = Label.new()
	badge.name = "Badge"
	badge.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.9, 0.2, 0.25, 1.0)
	sb.set_corner_radius_all(UiTokens.RADIUS_SM)
	sb.content_margin_left = UiTokens.SPACE_XS
	sb.content_margin_right = UiTokens.SPACE_XS
	badge.add_theme_stylebox_override("normal", sb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.visible = false
	add_child(badge)

func set_badge(count: int) -> void:
	badge.text = str(count)
	badge.visible = count > 0

func set_label(t: String) -> void:
	text = t
