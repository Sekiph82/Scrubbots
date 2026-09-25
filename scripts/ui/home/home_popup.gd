extends Control
## HomePopup — preload (res://scripts/ui/home/home_popup.gd).
##
## M42 reusable modal list popup for Home shortcuts (Gift Bar SB-M42-021, Cards Exchange
## SB-M42-022, Daily SB-M42-024). Pure presentation: rows are {text, action_text,
## action_enabled, action_id}; pressing an action emits action_pressed(action_id) and the
## owner calls the canonical service/facade. The popup mints nothing and stores no truth.

signal action_pressed(action_id: String)
signal closed

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

var popup_id: String
var _title: Label
var _rows: VBoxContainer
var _note: Label

func _init(id: String = "popup") -> void:
	popup_id = id
	name = "Popup_" + id
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
	panel.custom_minimum_size = Vector2(760, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.125, 0.145, 0.2, 1.0)
	sb.set_corner_radius_all(UiTokens.RADIUS_LG)
	sb.set_content_margin_all(UiTokens.SPACE_XL)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	panel.add_child(col)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", UiTokens.FONT_TITLE)
	col.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	col.add_child(_rows)
	_note = Label.new()
	_note.name = "Note"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	col.add_child(_note)
	var close := Button.new()
	close.name = "CloseButton"
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	close.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
	close.pressed.connect(close_popup)
	col.add_child(close)

func set_content(title: String, rows: Array, note: String = "") -> void:
	_title.text = title
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()   # deferred: a row may be rebuilt from inside its own button signal
	for r in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UiTokens.SPACE_MD)
		var l := Label.new()
		l.text = String(r.get("text", ""))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
		line.add_child(l)
		if r.has("action_id"):
			var b := Button.new()
			b.name = _node_name(String(r["action_id"]))
			b.text = String(r.get("action_text", "OK"))
			b.disabled = not bool(r.get("action_enabled", true))
			b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN * 2, UiTokens.TOUCH_MIN)
			b.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
			b.focus_mode = Control.FOCUS_NONE
			var aid := String(r["action_id"])
			b.pressed.connect(func():
				if not b.disabled:
					action_pressed.emit(aid))
			line.add_child(b)
		_rows.add_child(line)
	_note.text = note
	_note.visible = not note.is_empty()

func get_row_count() -> int:
	return _rows.get_child_count()

func get_action_button(action_id: String) -> Button:
	return find_child(_node_name(action_id), true, false) as Button

## Action ids may contain ':' etc. (occurrence ids); node names may not.
static func _node_name(action_id: String) -> String:
	return ("Action_" + action_id).validate_node_name()

func get_title() -> String:
	return _title.text

func get_note() -> String:
	return _note.text

func close_popup() -> void:
	hide()
	closed.emit()
