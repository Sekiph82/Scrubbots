extends Control
## ResultsScreen — preload (res://scripts/ui/results_screen.gd).
##
## M42 (SB-M42-007) — the Results navigation surface shown once per LOST / ERROR gameplay
## terminal. SB-PHONE-2026-11-12-E (owner 2026-11-12): a WON never shows Results; the win
## animation plays over the board and Home opens by itself (main.gd, WinOverlay, Home reward
## flight), so the WON branch (Victory layout, reward rows, journey, ceremony barrier, feel)
## is gone.
## M43-C001A — presents ONE read-only Results model built by the app root:
##   {status, level, attempt, receipt, reduced_effects, robot_id}
## where `receipt` is the host's committed TerminalRewardReceipt. It never computes or
## mutates any state (the terminal economy/save already ran inside the gameplay host before
## this is shown); re-showing/refreshing the same model is pure presentation.
## M43-C004 (SB-M43-050) — LOST is the production Fail surface: the existing help Scrubby pose
##   above the cream Life/Help-family frame (native StyleBoxes), the existing fail emblem in the
##   header, `LEVEL FAILED`, live level, the committed loss rows from the receipt (Hearts
##   before -> after, ended Win Streak), Retry primary and Home secondary. No Victory art, no
##   Replay, no ad CTA. It only presents the loss the host already committed; Retry/Home apply
##   nothing here.
## ERROR keeps the technical fallback layout.
## SB-POLISH-011 V1 — LOST robot motion (CharacterMotion `lose`) on the existing pose: draw-only
##   (layout and input untouched), Reduced = static, a re-show of the same terminal skips the
##   intro straight to the idle loop, hidden = stopped.
## SB-VIDEO-002 — Scrubby's LOST robot slot plays the owner's Flow result video once, magenta
##   keyed by chroma_key_magenta.gdshader, then holds the pre-keyed still (frame 0 = last
##   frame). Reduced Effects or a re-show of the same terminal shows only the still. One decoder,
##   freed when Results hides or re-shows; it never takes input and the slot rect never changes.
##   Other robots, or a video that fails to load / play, keep the approved pose + CharacterMotion.
##
## Actions (intents only; the app root performs them):
##   LOST: RETRY (primary) -> retry_requested     (M30 transaction-safe retry)
##   HOME (secondary)      -> home_requested

signal home_requested
signal retry_requested

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")

## Existing approved production art (never written by this screen).
const FAIL_ROBOT_ART := "res://assets/ui/final/popups/help/help_scrubby_pose.png"
const FAIL_EMBLEM_ART := "res://assets/ui/final/popups/failure/fail_header_emblem.png"
## SB-VIDEO-002: Scrubby LOSE result video (see assets/ui/final/popups/videos/PROVENANCE.md).
const SCRUBBY_ID := "scrubby"
const LOSE_VIDEO := "res://assets/ui/final/popups/videos/result_scrubby_lose.ogv"
const LOSE_STILL := "res://assets/ui/final/popups/videos/result_scrubby_lose_still.png"
const CHROMA_KEY := preload("res://scripts/ui/feel/chroma_key_magenta.gdshader")
const ICON_ART := {
	"win_streak_sb": "res://assets/ui/final/home/reward_track/win_streak_reward_badge.png",
	"heart": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
}

## Fail composition metrics (reference 1080-wide portrait).
const FRAME_WIDTH := 880
const ROBOT_SIZE := Vector2(340, 340)
const ROBOT_OVERLAP := 96
const EMBLEM_SIZE := 96
const ICON_SIZE := 76

## Warm Life/Help-family palette (native chrome; values only).
const CREAM := Color(1.0, 0.957, 0.878)
const ROW := Color(0.976, 0.898, 0.769)
const ROYAL := Color(0.106, 0.365, 0.788)
const ROYAL_EDGE := Color(0.047, 0.180, 0.459)
const INK := Color(0.106, 0.180, 0.349)

var _payload: Dictionary = {}
var _model: Dictionary = {}
## Production family chrome (LOST Fail); false = ERROR technical fallback.
var _styled := false
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
var _family_theme: Theme
var _motion_id := ""   ## terminal identity whose robot intro already played
var _video: VideoStreamPlayer = null   ## the one result-video decoder (only while it plays)

func _init() -> void:
	name = "ResultsScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_family_theme = HomeStyle.make_theme()
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
	_robot = HomeStyle.art("ResultRobot")
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
	_emblem = HomeStyle.art("ResultEmblem")
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
	b.focus_mode = Control.FOCUS_ACCESSIBILITY
	b.pressed.connect(cb)
	return b

## Show one terminal Results model (see header).
func show_model(model: Dictionary) -> void:
	_model = model.duplicate(true)
	_payload = {"status": _model.get("status", ""), "level": _model.get("level", 0), "attempt": _model.get("attempt", 0)}
	var status := String(_payload["status"])
	var lost := status == "LOST"
	_apply_layout(status)
	_title.text = UiText.t("RESULTS_LOST" if lost else "RESULTS_ERROR")
	_level.text = UiText.t("RESULTS_LEVEL", [int(_payload["level"])])
	# LOST: Retry + Home; ERROR: Home only.
	_primary.text = UiText.t("RESULTS_RETRY")
	_primary.visible = lost
	_primary.disabled = not lost
	_home.text = UiText.t("RESULTS_HOME")
	_home.visible = true
	_clear_lines()
	for r in loss_rows(_model.get("receipt", {})):
		_lines.add_child(_row(r) if _styled else _plain_line(r["text"]))
	_note.text = UiText.t("FAIL_ENCOURAGE") if lost else ""
	_note.visible = not _note.text.is_empty()
	if _styled:
		var intro := _show_id() != _motion_id
		if not _show_scrubby_video(intro):
			CharacterMotion.play(_robot, "lose", _reduced(), intro)
		_motion_id = _show_id()

## SB-VIDEO-002: Scrubby's LOSE video in the robot slot, or only its keyed still (Reduced Effects,
## a re-show of the same terminal, outside the tree). False = not Scrubby, or the video could not
## load / play: the caller keeps the approved pose + CharacterMotion.
func _show_scrubby_video(intro: bool) -> bool:
	var rid := String(_model.get("robot_id", ""))
	if not rid.is_empty() and rid != SCRUBBY_ID:
		return false
	var still := load(LOSE_STILL) as Texture2D
	if still == null:
		return false
	if intro and not _reduced() and is_inside_tree() and not _start_video(load(LOSE_VIDEO) as VideoStream, still):
		return false
	_robot.texture = still
	return true

## One keyed VideoStreamPlayer over the robot, aspect-fitted like the still it ends on. The robot's
## own pixels are hidden (self_modulate) while it plays; finishing frees it and shows the still.
func _start_video(stream: VideoStream, still: Texture2D) -> bool:
	if stream == null:
		return false
	var box := AspectRatioContainer.new()
	box.name = "VideoBox"
	box.ratio = float(still.get_width()) / float(still.get_height())
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video = VideoStreamPlayer.new()
	_video.name = "ResultVideo"
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.material = ShaderMaterial.new()
	(_video.material as ShaderMaterial).shader = CHROMA_KEY
	_video.stream = stream
	box.add_child(_video)
	_robot.add_child(box)
	_video.finished.connect(_on_video_finished.bind(_video), CONNECT_DEFERRED)
	_video.play()
	if not _video.is_playing() or _video.get_stream_length() <= 0.0:
		_stop_video()
		return false
	_robot.self_modulate.a = 0.0
	return true

func _on_video_finished(player) -> void:   # untyped: may be a freed player
	if player == _video:
		_stop_video()

func _stop_video() -> void:
	_robot.self_modulate.a = 1.0
	if _video == null:
		return
	var box := _video.get_parent()
	_video.stop()
	_robot.remove_child(box)
	box.queue_free()
	_video = null

func get_result_video() -> VideoStreamPlayer:
	return _video

## LOST = Fail composition; ERROR = technical fallback.
func _apply_layout(status: String) -> void:
	_styled = status == "LOST"
	theme = _family_theme if _styled else null
	_robot_slot.visible = _styled
	_emblem.visible = _styled
	# M43-C008 (SB-M43-108): the active robot's approved help pose (Scrubby default).
	var rid := String(_model.get("robot_id", ""))
	var pose := FAIL_ROBOT_ART
	if not rid.is_empty():
		pose = RobotRoster.asset(rid, "help_pose")
	_robot.texture = load(pose) if _styled else null
	_emblem.texture = load(FAIL_EMBLEM_ART) if _styled else null
	_stack.add_theme_constant_override("separation", -ROBOT_OVERLAP if _styled else 0)
	if _styled:
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
		# Technical fallback (pre-C001B look), ERROR only.
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

## One loss row: warm inset card, existing approved icon, live text.
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
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # SB-M49-027: a long row wraps, never widens the frame
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

func _clear_lines() -> void:
	_stop_motion()
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()

## Hidden Results keeps no per-receipt nodes (steady-state Home node count, M55).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _lines != null:
		_clear_lines()

## M43-C004: committed loss rows of a LOST receipt (Hearts before -> after, an ended Win
## Streak). Only what the terminal actually changed; nothing outside the receipt.
static func loss_rows(receipt: Dictionary) -> Array:
	var out: Array = []
	if String(receipt.get("status", "")) != "LOST":
		return out
	var h: Dictionary = receipt.get("hearts", {})
	if h.has("before") and h.has("after"):
		out.append({"kind": "hearts", "icon": "heart", "text": UiText.t("FAIL_HEARTS", [int(h["before"]), int(h["after"])])})
	var s: Dictionary = receipt.get("streak", {})
	if int(s.get("before", 0)) > int(s.get("after", 0)):
		out.append({"kind": "streak_reset", "icon": "win_streak_sb", "text": UiText.t("FAIL_STREAK_RESET", [int(s["before"])])})
	return out

func _on_primary() -> void:
	if not _primary.disabled:
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

## Immutable identity of the shown terminal (a re-show of it skips the robot intro).
func _show_id() -> String:
	return "results:%s:a%d:L%d" % [String(_payload.get("status", "")), int(_payload.get("attempt", 0)), int(_payload.get("level", 0))]

func _reduced() -> bool:
	return bool(_model.get("reduced_effects", false))

## Hidden / rebuilt: the robot motion and its decoder stop.
func _stop_motion() -> void:
	CharacterMotion.stop(_robot)
	_stop_video()
