extends Control
## ResultsScreen — preload (res://scripts/ui/results_screen.gd).
##
## M42 (SB-M42-007) — the Results navigation surface shown once per gameplay terminal.
## M43-C001A — evolved to present ONE read-only Results model built by the app root:
##   {status, level, attempt, receipt, continue:{available, reason, next_level}}
## where `receipt` is the host's committed TerminalRewardReceipt. It never computes
## rewards or mutates any state (the terminal economy/save already ran inside the
## gameplay host before this is shown); re-showing/refreshing the same model is pure
## presentation. Reward lines are a technical/wireframe-safe binding of the receipt's
## reveal_queue — final Victory/Results styling and choreography stay owner-gated.
##
## Actions (intents only; the app root performs them):
##   HOME                -> home_requested
##   WON:  CONTINUE      -> continue_requested(attempt)  (next canonical frontier)
##         latched: the first accepted tap disables Continue; later taps are no-ops
##         until the app root re-shows a model (e.g. a Continue that failed to launch).
##   LOST: RETRY         -> retry_requested     (M30 transaction-safe retry)

signal home_requested
signal continue_requested(attempt: int)
signal retry_requested

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var _payload: Dictionary = {}
var _model: Dictionary = {}
var _continue_latched := false
var _title: Label
var _level: Label
var _lines: VBoxContainer
var _note: Label
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
	_lines = VBoxContainer.new()
	_lines.name = "RewardLines"
	col.add_child(_lines)
	_note = Label.new()
	_note.name = "NoteLabel"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	col.add_child(_note)
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

## M42 compatibility: payload + next-frontier availability, no receipt.
func show_result(payload: Dictionary, continue_available: bool) -> void:
	var m := payload.duplicate(true)
	m["continue"] = {"available": continue_available}
	show_model(m)

## Show one terminal Results model (see header). Re-arms the Continue latch.
func show_model(model: Dictionary) -> void:
	_model = model.duplicate(true)
	_payload = {"status": _model.get("status", ""), "level": _model.get("level", 0), "attempt": _model.get("attempt", 0)}
	_continue_latched = false
	var status := String(_payload["status"])
	var won := status == "WON"
	var cont: Dictionary = _model.get("continue", {})
	var continue_available := bool(cont.get("available", false))
	_title.text = UiText.t("RESULTS_WON" if won else ("RESULTS_LOST" if status == "LOST" else "RESULTS_ERROR"))
	_level.text = UiText.t("RESULTS_LEVEL", [int(_payload["level"])])
	_primary.text = UiText.t("RESULTS_CONTINUE" if won else "RESULTS_RETRY")
	# WON continues only to real next-frontier content; LOST may Retry; ERROR only HOME.
	_primary.disabled = (won and not continue_available) or not (won or status == "LOST")
	_primary.visible = won or status == "LOST"
	_home.text = UiText.t("RESULTS_HOME")
	_clear_lines()
	var receipt: Dictionary = _model.get("receipt", {})
	for line in reward_lines(receipt):
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
		l.text = line
		_lines.add_child(l)
	_note.text = ""
	if won and bool(receipt.get("already_cleared", false)):
		_note.text = UiText.t("RESULTS_ALREADY_CLEARED")
	elif won and not continue_available and cont.has("next_level"):
		_note.text = UiText.t("RESULTS_NEXT_UNAVAILABLE", [int(cont["next_level"])])
	_note.visible = not _note.text.is_empty()

func _clear_lines() -> void:
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()

## Hidden Results keeps no per-receipt nodes (steady-state Home node count, M55).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _lines != null:
		_clear_lines()

## Display lines for a receipt, in its committed reveal_queue order (then follow-ups).
static func reward_lines(receipt: Dictionary) -> Array:
	var out: Array = []
	for e in receipt.get("reveal_queue", []):
		match String(e.get("kind", "")):
			"first_clear_sb":
				out.append(UiText.t("RESULTS_FIRST_CLEAR_SB", [e["amount"]]))
			"win_streak_sb":
				out.append(UiText.t("RESULTS_STREAK_SB", [e["streak"], e["amount"]]))
			"bot_parts":
				out.append(UiText.t("RESULTS_BOT_PARTS", [e["amount"]]))
			"gift_meter":
				out.append(UiText.t("RESULTS_GIFT_METER", [e["to"], e["cycle_max"]]))
			"collection_cards":
				out.append(UiText.t("RESULTS_CARDS", [e["amount"]]))
	for f in receipt.get("follow_ups", []):
		if String(f.get("kind", "")) == "gift_milestone":
			out.append(UiText.t("RESULTS_GIFT_READY"))
	return out

func _on_primary() -> void:
	if _primary.disabled:
		return
	if String(_payload.get("status", "")) == "WON":
		if _continue_latched:
			return
		_continue_latched = true
		_primary.disabled = true
		continue_requested.emit(int(_payload.get("attempt", 0)))
	else:
		retry_requested.emit()

func get_model() -> Dictionary:
	return _model.duplicate(true)

func get_reward_lines_node() -> VBoxContainer:
	return _lines

func get_note_label() -> Label:
	return _note

func get_payload() -> Dictionary:
	return _payload.duplicate(true)

func get_primary_button() -> Button:
	return _primary

func get_home_button() -> Button:
	return _home
