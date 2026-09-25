extends PanelContainer
## UiValueChip — preload (res://scripts/ui/components/ui_value_chip.gd).
##
## M42 reusable component (SB-M42-010): a live-text value chip (currency / hearts /
## counters). Optional decorative icon (never receives input) + one live Label + optional
## secondary live Label (e.g. a timer). Values are set by the owner screen from canonical
## state; the chip holds no truth. Min height = TOUCH_MIN.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var icon: TextureRect
## Native text tag shown in place of the icon while no approved icon art is bound
## (e.g. "SB" for Scrub Bucks). Live Label, never baked.
var tag: Label
var value_label: Label
var sub_label: Label

func _init(id: String = "chip") -> void:
	name = id
	custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.35)
	sb.set_corner_radius_all(UiTokens.RADIUS_MD)
	sb.content_margin_left = UiTokens.SPACE_SM
	sb.content_margin_right = UiTokens.SPACE_MD
	add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	add_child(row)
	icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(UiTokens.ICON_SM, UiTokens.ICON_SM)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.visible = false
	row.add_child(icon)
	tag = Label.new()
	tag.name = "Tag"
	tag.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.visible = false
	row.add_child(tag)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	value_label = Label.new()
	value_label.name = "Value"
	value_label.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
	col.add_child(value_label)
	sub_label = Label.new()
	sub_label.name = "Sub"
	sub_label.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	sub_label.visible = false
	col.add_child(sub_label)

func set_icon(tex: Texture2D) -> void:
	icon.texture = tex
	icon.visible = tex != null
	tag.visible = tex == null and not tag.text.is_empty()

func set_tag(text: String) -> void:
	tag.text = text
	tag.visible = icon.texture == null and not text.is_empty()

func set_value(text: String) -> void:
	value_label.text = text

func set_sub(text: String) -> void:
	sub_label.text = text
	sub_label.visible = not text.is_empty()
