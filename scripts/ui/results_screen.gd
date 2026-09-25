extends Control
## ResultsScreen — preload (res://scripts/ui/results_screen.gd).
##
## M42 (SB-M42-007) — the narrow Results navigation surface shown once per gameplay
## terminal. It carries only the minimum payload {status, level, attempt} decided by the
## authoritative M30 terminal; it never computes rewards or mutates any state (the
## terminal economy/save already ran inside the gameplay host before this is shown).
## Later results-content milestones (reward breakdown, animations) are NOT pulled in.
##
## Actions (intents only; the app root performs them):
##   HOME                -> home_requested
##   WON:  CONTINUE      -> continue_requested  (next canonical frontier)
##   LOST: RETRY         -> retry_requested     (M30 transaction-safe retry)

signal home_requested
signal continue_requested
signal retry_requested

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var _payload: Dictionary = {}
var _title: Label
var _level: Label
var _primary: Button
var _home: Button

func _init() -> void:
	name = "ResultsScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.125, 0.145, 0.2, 1.0)
	sb.set_corner_radius_all(UiTokens.RADIUS_LG)
	sb.set_content_margin_all(UiTokens.SPACE_XL)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_LG)
	panel.add_child(col)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", UiTokens.FONT_TITLE)
	col.add_child(_title)
	_level = Label.new()
	_level.name = "LevelLabel"
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	col.add_child(_level)
	_primary = _button("PrimaryButton", func(): _on_primary())
	col.add_child(_primary)
	_home = _button("HomeButton", func(): home_requested.emit())
	col.add_child(_home)

func _button(n: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = n
	b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	b.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

## Show one terminal result. continue_available: whether the next frontier has content.
func show_result(payload: Dictionary, continue_available: bool) -> void:
	_payload = payload.duplicate(true)
	var status := String(_payload.get("status", ""))
	var won := status == "WON"
	_title.text = "LEVEL COMPLETE" if won else ("LEVEL FAILED" if status == "LOST" else "SOMETHING WENT WRONG")
	_level.text = "Level %d" % int(_payload.get("level", 0))
	_primary.text = "CONTINUE" if won else "RETRY"
	# WON continues only to real next-frontier content; LOST may Retry; ERROR only HOME.
	_primary.disabled = (won and not continue_available) or not (won or status == "LOST")
	_primary.visible = won or status == "LOST"
	_home.text = "HOME"

func _on_primary() -> void:
	if _primary.disabled:
		return
	if String(_payload.get("status", "")) == "WON":
		continue_requested.emit()
	else:
		retry_requested.emit()

func get_payload() -> Dictionary:
	return _payload.duplicate(true)

func get_primary_button() -> Button:
	return _primary

func get_home_button() -> Button:
	return _home
