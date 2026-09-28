extends Control
## ResultsScreen — preload (res://scripts/ui/results_screen.gd).
##
## M42 (SB-M42-007) — the Results navigation surface shown once per gameplay terminal.
## M43-C001A — presents ONE read-only Results model built by the app root:
##   {status, level, attempt, receipt, continue:{available, reason, next_level}, reduced_effects}
## where `receipt` is the host's committed TerminalRewardReceipt. It never computes
## rewards or mutates any state (the terminal economy/save already ran inside the
## gameplay host before this is shown); re-showing/refreshing the same model is pure
## presentation.
## M43-C001B — WON visual candidate per OWNER_RESULTS_VISUAL_REPLAY_V01:
##   - warm Life/Help-family frame built from native StyleBoxes (no one-piece chrome PNG
##     exists; no art generated);
##   - the celebrating robot (Scrubby until an equipped-robot authority exists) sits
##     above and overlaps the frame; a small Victory emblem sits in the header;
##   - reward rows come ONLY from receipt.reveal_queue (+ gift follow-up), in that order,
##     each with an existing approved icon + live text;
##   - green Life/Help-family Continue CTA, subordinate Home;
##   - a short ordered row reveal (presentation only; rows exist from the start, grants
##     are already committed, Continue is never gated by it). Reduced Effects shows every
##     row immediately.
## LOST/ERROR keep the technical fallback layout with NO Victory art (final LOST is M43-C004).
## There is no Replay control (owner A1-NO).
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
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

## Existing approved production art (never written by this screen).
const ROBOT_ART := "res://assets/ui/final/popups/victory/victory_scrubby_pose.png"
const EMBLEM_ART := "res://assets/ui/final/popups/victory/victory_emblem.png"
const ICON_ART := {
	"first_clear_sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"win_streak_sb": "res://assets/ui/final/home/reward_track/win_streak_reward_badge.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"gift_meter": "res://assets/ui/final/home/gift_meter/gift_meter_emblem.png",
	"collection_cards": "res://assets/ui/final/rewards/card_pack_standard.png",
	"gift_ready": "res://assets/ui/final/rewards/gift_box.png",
}

## WON composition metrics (reference 1080-wide portrait).
const FRAME_WIDTH := 880
const ROBOT_SIZE := Vector2(340, 340)
const ROBOT_OVERLAP := 96
const EMBLEM_SIZE := 96
const ICON_SIZE := 76
const REVEAL_STEP_S := 0.16   ## per-row fade; visual-only candidate timing (owner gate)

## Warm Life/Help-family palette (native chrome; values only).
const CREAM := Color(1.0, 0.957, 0.878)
const ROW := Color(0.976, 0.898, 0.769)
const ROYAL := Color(0.106, 0.365, 0.788)
const ROYAL_EDGE := Color(0.047, 0.180, 0.459)
const INK := Color(0.106, 0.180, 0.349)

var _payload: Dictionary = {}
var _model: Dictionary = {}
var _continue_latched := false
var _victory := false
var _stack: VBoxContainer
var _robot_slot: CenterContainer
var _robot: TextureRect
var _panel: PanelContainer
var _header: PanelContainer
var _emblem: TextureRect
var _title: Label
var _level: Label
var _lines: VBoxContainer
var _note: Label
var _primary: Button
var _home: Button
var _reveal: Tween
var _victory_theme: Theme

func _init() -> void:
	name = "ResultsScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_victory_theme = HomeStyle.make_theme()
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_stack = VBoxContainer.new()
	_stack.name = "Stack"
	center.add_child(_stack)
	_robot_slot = CenterContainer.new()
	_robot_slot.name = "RobotSlot"
	_stack.add_child(_robot_slot)
	_robot = HomeStyle.art("VictoryRobot")
	_robot.custom_minimum_size = ROBOT_SIZE
	_robot.z_index = 1   # the robot overlaps (draws over) the frame's top edge
	_robot_slot.add_child(_robot)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_stack.add_child(_panel)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_panel.add_child(col)
	_header = PanelContainer.new()
	_header.name = "Header"
	col.add_child(_header)
	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_header.add_child(head_row)
	_emblem = HomeStyle.art("VictoryEmblem")
	_emblem.custom_minimum_size = Vector2(EMBLEM_SIZE, EMBLEM_SIZE)
	head_row.add_child(_emblem)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", UiTokens.FONT_TITLE)
	head_row.add_child(_title)
	_level = Label.new()
	_level.name = "LevelLabel"
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	col.add_child(_level)
	_lines = VBoxContainer.new()
	_lines.name = "RewardLines"
	_lines.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	col.add_child(_lines)
	_note = Label.new()
	_note.name = "NoteLabel"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	_apply_layout(won)
	_title.text = UiText.t("RESULTS_WON" if won else ("RESULTS_LOST" if status == "LOST" else "RESULTS_ERROR"))
	_level.text = UiText.t("RESULTS_LEVEL", [int(_payload["level"])])
	_primary.text = UiText.t("RESULTS_CONTINUE" if won else "RESULTS_RETRY")
	# WON continues only to real next-frontier content; LOST may Retry; ERROR only HOME.
	_primary.disabled = (won and not continue_available) or not (won or status == "LOST")
	_primary.visible = won or status == "LOST"
	_home.text = UiText.t("RESULTS_HOME")
	_clear_lines()
	var receipt: Dictionary = _model.get("receipt", {})
	for r in reward_rows(receipt):
		_lines.add_child(_row(r) if _victory else _plain_line(r["text"]))
	_note.text = ""
	if won and bool(receipt.get("already_cleared", false)):
		_note.text = UiText.t("RESULTS_ALREADY_CLEARED")
	elif won and not continue_available and cont.has("next_level"):
		_note.text = UiText.t("RESULTS_NEXT_UNAVAILABLE", [int(cont["next_level"])])
	_note.visible = not _note.text.is_empty()
	_start_reveal(bool(_model.get("reduced_effects", false)))

## WON = Victory composition; LOST/ERROR = technical fallback with no Victory art.
func _apply_layout(won: bool) -> void:
	_victory = won
	theme = _victory_theme if won else null
	_robot_slot.visible = won
	_emblem.visible = won
	_robot.texture = load(ROBOT_ART) if won else null
	_emblem.texture = load(EMBLEM_ART) if won else null
	_stack.add_theme_constant_override("separation", -ROBOT_OVERLAP if won else 0)
	if won:
		_panel.custom_minimum_size = Vector2(FRAME_WIDTH, 0)
		var frame := HomeStyle.box(CREAM, ROYAL, 12, 44, 18, 6)
		HomeStyle.pad(frame, UiTokens.SPACE_XL, UiTokens.SPACE_LG)
		frame.content_margin_top = ROBOT_OVERLAP * 0.5
		_panel.add_theme_stylebox_override("panel", frame)
		_header.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(ROYAL, ROYAL_EDGE, 5, 30, 6, 6), UiTokens.SPACE_LG, UiTokens.SPACE_SM))
		_title.add_theme_color_override("font_color", HomeStyle.TEXT)
		for l in [_level, _note]:
			l.add_theme_color_override("font_color", INK)
			l.add_theme_constant_override("outline_size", 0)
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		HomeStyle.style_play_button(_primary)
		_primary.custom_minimum_size = Vector2(0, 112)
		var home := HomeStyle.box(ROW, Color(0.749, 0.604, 0.380), 4, 30, 4, 4)
		for st in ["normal", "hover", "pressed", "disabled"]:
			_home.add_theme_stylebox_override(st, home)
		_home.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			_home.add_theme_color_override(c, INK)
		_home.add_theme_constant_override("outline_size", 0)
		_home.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
		_home.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	else:
		# Technical fallback (pre-C001B look). M43-C004 replaces this for LOST.
		_panel.custom_minimum_size = Vector2(720, 0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.125, 0.145, 0.2, 1.0)
		sb.set_corner_radius_all(UiTokens.RADIUS_LG)
		sb.set_content_margin_all(UiTokens.SPACE_XL)
		_panel.add_theme_stylebox_override("panel", sb)
		_header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_title.remove_theme_color_override("font_color")
		for c in [_primary, _home]:
			for st in ["normal", "hover", "pressed", "disabled", "focus"]:
				c.remove_theme_stylebox_override(st)
			for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color", "font_outline_color", "icon_disabled_color"]:
				c.remove_theme_color_override(k)
			c.remove_theme_constant_override("outline_size")
			c.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
			c.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
		for l in [_level, _note]:
			l.remove_theme_color_override("font_color")
			l.remove_theme_constant_override("outline_size")
			l.remove_theme_color_override("font_shadow_color")

## One WON reward row: warm inset card, existing approved icon, live text.
func _row(r: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "Row_" + String(r["kind"])
	card.set_meta("kind", r["kind"])
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(ROW, Color(0.890, 0.765, 0.545), 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	card.add_child(h)
	var icon := HomeStyle.art("Icon")
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.texture = load(ICON_ART[r["icon"]])
	h.add_child(icon)
	var l := Label.new()
	l.name = "Text"
	l.text = r["text"]
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	h.add_child(l)
	return card

func _plain_line(text: String) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	l.text = text
	return l

## Ordered row reveal. Presentation only: every row already exists and every grant is
## already committed; Continue/Home stay live throughout. Reduced Effects (or no tree)
## shows all rows immediately.
func _start_reveal(reduced: bool) -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	_reveal = null
	var rows := _lines.get_children()
	if reduced or rows.is_empty() or not _victory or not is_inside_tree():
		return
	for c in rows:
		c.modulate.a = 0.0
	_reveal = create_tween()
	for c in rows:
		_reveal.tween_property(c, "modulate:a", 1.0, REVEAL_STEP_S)

## Fast-forward the reveal to its final state (all committed rows visible).
func finish_reveal() -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	_reveal = null
	for c in _lines.get_children():
		c.modulate.a = 1.0

func is_revealing() -> bool:
	return _reveal != null and _reveal.is_valid() and _reveal.is_running()

func _clear_lines() -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	_reveal = null
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()

## Hidden Results keeps no per-receipt nodes (steady-state Home node count, M55).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _lines != null:
		_clear_lines()

## Display rows for a receipt, in its committed reveal_queue order (then follow-ups):
## [{kind, icon, text}]. Nothing outside the receipt can create a row.
static func reward_rows(receipt: Dictionary) -> Array:
	var out: Array = []
	for e in receipt.get("reveal_queue", []):
		var kind := String(e.get("kind", ""))
		var text := ""
		match kind:
			"first_clear_sb":
				text = UiText.t("RESULTS_FIRST_CLEAR_SB", [e["amount"]])
			"win_streak_sb":
				text = UiText.t("RESULTS_STREAK_SB", [e["streak"], e["amount"]])
			"bot_parts":
				text = UiText.t("RESULTS_BOT_PARTS", [e["amount"]])
			"gift_meter":
				text = UiText.t("RESULTS_GIFT_METER", [e["to"], e["cycle_max"]])
			"collection_cards":
				text = UiText.t("RESULTS_CARDS", [e["amount"]])
		if not text.is_empty():
			out.append({"kind": kind, "icon": kind, "text": text})
	for f in receipt.get("follow_ups", []):
		if String(f.get("kind", "")) == "gift_milestone":
			out.append({"kind": "gift_milestone", "icon": "gift_ready", "text": UiText.t("RESULTS_GIFT_READY")})
	return out

## Text-only view of reward_rows (M43-C001A contract).
static func reward_lines(receipt: Dictionary) -> Array:
	return reward_rows(receipt).map(func(r): return r["text"])

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

## Texts of the currently shown reward rows, in display order.
func shown_row_texts() -> Array:
	var out: Array = []
	for c in _lines.get_children():
		if c.is_queued_for_deletion():
			continue
		for l in ([c] if c is Label else c.find_children("Text", "Label", true, false)):
			out.append(l.text)
	return out

func is_victory_layout() -> bool:
	return _victory

func get_robot() -> TextureRect:
	return _robot

func get_emblem() -> TextureRect:
	return _emblem

func get_panel() -> PanelContainer:
	return _panel

func get_note_label() -> Label:
	return _note

func get_payload() -> Dictionary:
	return _payload.duplicate(true)

func get_primary_button() -> Button:
	return _primary

func get_home_button() -> Button:
	return _home
