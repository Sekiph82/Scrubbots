extends VBoxContainer
## UiProgressMeter — preload (res://scripts/ui/components/ui_progress_meter.gd).
##
## M42 reusable component (SB-M42-010): native progress bar + live caption (Gift Meter,
## Bot Parts). Pure presentation: set_progress(value, max, caption). No baked text.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var caption: Label
var bar: ProgressBar

func _init(id: String = "meter") -> void:
	name = id
	add_theme_constant_override("separation", UiTokens.SPACE_XS)
	caption = Label.new()
	caption.name = "Caption"
	caption.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	caption.clip_text = true
	add_child(caption)
	bar = ProgressBar.new()
	bar.name = "Bar"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, UiTokens.SPACE_LG)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

func set_progress(value: float, max_value: float, text: String) -> void:
	bar.max_value = maxf(max_value, 1.0)
	bar.value = clampf(value, 0.0, bar.max_value)
	caption.text = text
