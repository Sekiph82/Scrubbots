extends PanelContainer
## UiValueChip — preload (res://scripts/ui/components/ui_value_chip.gd).
##
## M42 reusable component (SB-M42-010): a live-text value chip (currency / hearts /
## counters). Optional decorative icon (never receives input) + one live Label + optional
## secondary live Label (e.g. a timer). Values are set by the owner screen from canonical
## state; the chip holds no truth. Min height = TOUCH_MIN.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var icon: TextureRect
## Layout footprint of the icon inside the row; the icon itself is a free child of this
## slot so it can be drawn larger than the footprint (V04 pop-out) without the container
## resetting its size/scale.
var icon_slot: Control
var _icon_px := 0.0
var _icon_pop := 1.0
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
	icon_slot = Control.new()
	icon_slot.name = "IconSlot"
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_slot.visible = false
	row.add_child(icon_slot)
	icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.visible = false
	icon_slot.add_child(icon)
	_apply_icon_rect(UiTokens.ICON_SM)
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

## V02: larger icons for the branded HUD / reward track.
func set_icon_size(px: int) -> void:
	_apply_icon_rect(px)

func _apply_icon_rect(px: float) -> void:
	_icon_px = px
	icon_slot.custom_minimum_size = Vector2(px, px)
	# The enlarged icon keeps its right edge on the footprint's right edge (never covers
	# the value text) and overhangs up/down/left, out of the chip panel's left end.
	var h := px * _icon_pop * 0.5
	icon.offset_right = px * 0.5
	icon.offset_left = icon.offset_right - 2.0 * h
	icon.offset_top = -h
	icon.offset_bottom = h

## V04: draw the icon `k` times larger than its layout footprint (centred on it), so it
## sits in front of the chip panel and overhangs it. Layout is unchanged.
func set_icon_pop(k: float) -> void:
	_icon_pop = k
	_apply_icon_rect(_icon_px)

func set_panel_style(sb: StyleBox) -> void:
	add_theme_stylebox_override("panel", sb)

func set_value_size(px: int) -> void:
	value_label.add_theme_font_size_override("font_size", px)

func set_icon(tex: Texture2D) -> void:
	icon.texture = tex
	icon.visible = tex != null
	icon_slot.visible = tex != null
	tag.visible = tex == null and not tag.text.is_empty()

func set_tag(text: String) -> void:
	tag.text = text
	tag.visible = icon.texture == null and not text.is_empty()

func set_value(text: String) -> void:
	value_label.text = text

func set_sub(text: String) -> void:
	sub_label.text = text
	sub_label.visible = not text.is_empty()
