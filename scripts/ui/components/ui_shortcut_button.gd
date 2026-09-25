extends Button
## UiShortcutButton — preload (res://scripts/ui/components/ui_shortcut_button.gd).
##
## M42 reusable component (SB-M42-010; restyled in master-convergence V02): Home shortcut
## CARD. Large icon on top (Button icon, no baked text), full live label below (wraps to a
## second line instead of clipping), live notification badge attached to the card's top
## right corner (hidden at 0). Touch target >= TOUCH_MIN in both axes. Destinations that
## belong to later milestones are shown disabled by the owner screen, never faked.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const BADGE_SIZE := 52

var shortcut_id: String
var badge: Label

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
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	alignment = HORIZONTAL_ALIGNMENT_CENTER
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

func set_badge(count: int) -> void:
	badge.text = str(count)
	badge.visible = count > 0

func set_label(t: String) -> void:
	text = t
