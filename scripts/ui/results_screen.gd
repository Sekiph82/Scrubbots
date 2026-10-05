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
##     row immediately. M43-C005-C005: driven by the shared RevealSequencer.
## M43-C004 (SB-M43-050) — LOST is the production Fail surface in the same family: the
##   existing help Scrubby pose (no sad pose exists yet) above the cream frame, the
##   existing fail emblem in the header, `LEVEL FAILED`, live level, the committed loss
##   rows from the receipt (Hearts before -> after, ended Win Streak), Retry primary and
##   Home secondary. No Victory art, no Replay, no ad CTA. It only presents the loss the
##   host already committed; Retry/Home apply nothing here.
## ERROR keeps the technical fallback layout with NO Victory art.
## M43-C001R (SB-M43-R01-001..004) — WON momentum corridor, after the committed reward rows:
##   compact 10-Level Cleaning Journey (shared JourneyStrip) -> Next Cleanup teaser (a
##   cropped AtlasTexture region of the REAL next preview; the full image is never drawn)
##   -> dominant CLEAN NEXT (the existing Continue intent) -> Home secondary. Read-only:
##   model["momentum"] comes from ResultsMomentum; nothing here grants or resolves content.
##   Ceremony barrier seam (future M43-C005): while any barrier is set, the teaser and
##   CLEAN NEXT are held; releasing shows the same already-resolved teaser.
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
const JourneyStrip = preload("res://scripts/ui/components/journey_strip.gd")
const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const GiftProgressModel = preload("res://scripts/economy/gift_progress_model.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

## Existing approved production art (never written by this screen).
const ROBOT_ART := "res://assets/ui/final/popups/victory/victory_scrubby_pose.png"
const EMBLEM_ART := "res://assets/ui/final/popups/victory/victory_emblem.png"
const FAIL_ROBOT_ART := "res://assets/ui/final/popups/help/help_scrubby_pose.png"
const FAIL_EMBLEM_ART := "res://assets/ui/final/popups/failure/fail_header_emblem.png"
const ICON_ART := {
	"first_clear_sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"win_streak_sb": "res://assets/ui/final/home/reward_track/win_streak_reward_badge.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"gift_meter": "res://assets/ui/final/home/gift_meter/gift_meter_emblem.png",
	"collection_cards": "res://assets/ui/final/rewards/card_pack_standard.png",
	"gift_ready": "res://assets/ui/final/rewards/gift_box.png",
	"heart": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
}

## WON composition metrics (reference 1080-wide portrait).
const FRAME_WIDTH := 880
const ROBOT_SIZE := Vector2(340, 340)
const ROBOT_OVERLAP := 96
const EMBLEM_SIZE := 96
const ICON_SIZE := 76
const REVEAL_STEP_S := 0.16   ## per-row fade; visual-only candidate timing (owner gate)
const TEASER_SIZE := 132
const JOURNEY_H := 76   ## V02: proportionally larger for the beat size hierarchy (V01 56)

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
## Production family chrome (WON Victory or LOST Fail); false = ERROR technical fallback.
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
var _reveal: RevealSequencer
var _reveal_serial := 0   ## each show_model builds fresh rows = a new presentation key
var _momentum: VBoxContainer
var _journey_caption: Label
var _journey
var _next: PanelContainer
var _teaser: TextureRect
var _teaser_none: Label
var _next_title: Label
var _next_level: Label
var _next_facts: Label
var _has_next := false
var _barriers: Dictionary = {}   ## ceremony barrier id -> true (presentation hold only)
var _victory_theme: Theme

func _init() -> void:
	name = "ResultsScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_victory_theme = HomeStyle.make_theme()
	_reveal = RevealSequencer.new(self)
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
	_build_momentum(col)
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

## Momentum section (built once; only data changes per model -> no node accumulation).
func _build_momentum(col: VBoxContainer) -> void:
	_momentum = VBoxContainer.new()
	_momentum.name = "Momentum"
	_momentum.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	_momentum.visible = false
	col.add_child(_momentum)
	_journey_caption = _ink_label("JourneyCaption", 26)
	_momentum.add_child(_journey_caption)
	_journey = JourneyStrip.new()
	_journey.custom_minimum_size = Vector2(0, JOURNEY_H)
	_momentum.add_child(_journey)
	_next = PanelContainer.new()
	_next.name = "NextCleanup"
	_next.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(ROW, ROYAL, 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	_momentum.add_child(_next)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_next.add_child(h)
	var frame := PanelContainer.new()
	frame.name = "TeaserFrame"
	frame.custom_minimum_size = Vector2(TEASER_SIZE, TEASER_SIZE)
	frame.add_theme_stylebox_override("panel", HomeStyle.box(Color(0.125, 0.145, 0.2), ROYAL_EDGE, 4, 18, 0))
	h.add_child(frame)
	_teaser = TextureRect.new()
	_teaser.name = "TeaserImage"
	_teaser.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_teaser.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_teaser.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_teaser.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_teaser)
	_teaser_none = Label.new()
	_teaser_none.name = "TeaserUnavailable"
	_teaser_none.text = "?"
	_teaser_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_teaser_none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_teaser_none.add_theme_font_size_override("font_size", 72)
	frame.add_child(_teaser_none)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(info)
	_next_title = _ink_label("NextTitle", 26)
	_next_level = _ink_label("NextLevel", 40)
	_next_facts = _ink_label("NextFacts", 26)
	for l in [_next_title, _next_level, _next_facts]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(l)

func _ink_label(n: String, fs: int) -> Label:
	var l := Label.new()
	l.name = n
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l

## WON momentum from model["momentum"] (ResultsMomentum.results_model). Hidden otherwise.
func _render_momentum(won: bool) -> void:
	var m: Dictionary = _model.get("momentum", {})
	_has_next = false
	_teaser.texture = null
	_momentum.visible = won and bool(m.get("ok", false))
	if not _momentum.visible:
		_sync_barrier()
		return
	var j: Dictionary = m.get("journey", {})
	_journey.set_model(j)
	_journey_caption.text = UiText.t("JOURNEY_CAPTION", [int(j.get("completed", 0)), int(j.get("length", 10))]) if j.get("ok", false) else ""
	var n: Dictionary = m.get("next", {})
	_has_next = true
	_next_title.text = UiText.t("NEXT_CLEANUP_TITLE")
	_next_level.text = UiText.t("NEXT_CLEANUP_LEVEL", [int(n.get("level", 0))])
	if bool(n.get("available", false)):
		var facts := UiText.t("DIFFICULTY_" + String(n.get("difficulty", "")))
		if int(n.get("color_count", -1)) > 0:
			facts = UiText.t("NEXT_CLEANUP_FACTS", [facts, int(n["color_count"])])
		_next_facts.text = facts
	else:
		_next_facts.text = UiText.t("NEXT_CLEANUP_SOON")
	# Only the crop region is ever bound; without an honest crop there is no image at all.
	if bool(n.get("available", false)) and bool(n.get("image_ok", false)):
		var full = load(String(n["preview_path"])) as Texture2D
		if full != null:
			var at := AtlasTexture.new()
			at.atlas = full
			at.region = Rect2(n["crop"])
			_teaser.texture = at
	_teaser_none.visible = _teaser.texture == null
	_sync_barrier()

## V02 owner decision: when the Next Cleanup card already states this unavailable frontier
## ("Coming soon"), the older note above CLEAN NEXT would repeat it, so it is suppressed.
## Without a momentum card (e.g. malformed config) the note remains the honest message.
func _momentum_shows_unavailable(level: int) -> bool:
	var m: Dictionary = _model.get("momentum", {})
	var n: Dictionary = m.get("next", {})
	return bool(m.get("ok", false)) and not bool(n.get("available", true)) and int(n.get("level", -1)) == level

## Future M43-C005 seam: hold (active) / release the teaser + CLEAN NEXT for a mandatory
## ceremony `id`. Presentation only; rewards / progression / economy are never touched.
func set_ceremony_barrier(id: String, active: bool) -> void:
	if active:
		_barriers[id] = true
	else:
		_barriers.erase(id)
	_sync_barrier()

func has_ceremony_barrier() -> bool:
	return not _barriers.is_empty()

func _sync_barrier() -> void:
	_next.visible = _has_next and _barriers.is_empty()
	_sync_primary()

func _sync_primary() -> void:
	var status := String(_payload.get("status", ""))
	var won := status == "WON"
	var available := bool((_model.get("continue", {}) as Dictionary).get("available", false))
	# WON continues only to real next-frontier content and never while latched or held by a
	# ceremony barrier; LOST may Retry; ERROR only HOME.
	_primary.disabled = (won and (not available or _continue_latched or not _barriers.is_empty())) or not (won or status == "LOST")

func get_teaser_image() -> TextureRect:
	return _teaser

func get_journey_strip():
	return _journey

func get_next_cleanup_panel() -> PanelContainer:
	return _next

func get_momentum_section() -> VBoxContainer:
	return _momentum

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
	_apply_layout(status)
	_title.text = UiText.t("RESULTS_WON" if won else ("RESULTS_LOST" if status == "LOST" else "RESULTS_ERROR"))
	_level.text = UiText.t("RESULTS_LEVEL", [int(_payload["level"])])
	_primary.text = UiText.t("RESULTS_CLEAN_NEXT" if won else "RESULTS_RETRY")
	_primary.visible = won or status == "LOST"
	_home.text = UiText.t("RESULTS_HOME")
	_clear_lines()
	var receipt: Dictionary = _model.get("receipt", {})
	for r in (reward_rows(receipt) if won else loss_rows(receipt)):
		_lines.add_child(_row(r) if _styled else _plain_line(r["text"]))
	_note.text = ""
	if status == "LOST":
		_note.text = UiText.t("FAIL_ENCOURAGE")
	elif won and bool(receipt.get("already_cleared", false)):
		_note.text = UiText.t("RESULTS_ALREADY_CLEARED")
	elif won and not continue_available and cont.has("next_level") and not _momentum_shows_unavailable(int(cont["next_level"])):
		_note.text = UiText.t("RESULTS_NEXT_UNAVAILABLE", [int(cont["next_level"])])
	_note.visible = not _note.text.is_empty()
	_render_momentum(won)
	_sync_primary()
	_start_reveal(bool(_model.get("reduced_effects", false)))

## WON = Victory composition; LOST = Fail composition (same family, failure art);
## ERROR = technical fallback. No Victory art outside WON.
func _apply_layout(status: String) -> void:
	var won := status == "WON"
	_victory = won
	_styled = won or status == "LOST"
	theme = _victory_theme if _styled else null
	_robot_slot.visible = _styled
	_emblem.visible = _styled
	# M43-C008 (SB-M43-108): the active robot's approved victory / help pose (Scrubby default).
	var rid := String(_model.get("robot_id", ""))
	var pose := ROBOT_ART if won else FAIL_ROBOT_ART
	if not rid.is_empty():
		pose = RobotRoster.asset(rid, "victory_pose" if won else "help_pose")
	_robot.texture = load(pose) if _styled else null
	_emblem.texture = load(EMBLEM_ART if won else FAIL_EMBLEM_ART) if _styled else null
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
## shows all rows immediately. One RevealSequencer step per committed row, then (M43-C001R)
## the momentum section after its configured delay (the teaser is the crop at every alpha).
func _start_reveal(reduced: bool) -> void:
	_momentum.modulate.a = 1.0
	var steps: Array = []
	if _victory:
		for c in _lines.get_children():
			steps.append(RevealSequencer.fade(c, REVEAL_STEP_S))
		if _momentum.visible:
			steps.append(RevealSequencer.fade(_momentum, REVEAL_STEP_S, float((_model.get("momentum", {}) as Dictionary).get("reveal_delay_s", 0.0))))
	_reveal_serial += 1
	_reveal.play("results_%d" % _reveal_serial, steps, reduced)

## Fast-forward the reveal to its final state (all committed rows visible). Presentation only.
func finish_reveal() -> void:
	_reveal.finish()

func is_revealing() -> bool:
	return _reveal.is_running()

func get_reveal_sequencer() -> RevealSequencer:
	return _reveal

func _clear_lines() -> void:
	_reveal.cancel()
	_momentum.modulate.a = 1.0   # persistent node: never left hidden by a cancelled reveal
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()

## Hidden Results keeps no per-receipt nodes (steady-state Home node count, M55).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _lines != null:
		_clear_lines()
		_barriers.clear()   # a ceremony hold belongs to the Results it was set on
		_teaser.texture = null

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
				# M43-C005R: the shared normalized model of the COMMITTED value (receipt "to").
				var gm := GiftProgressModel.build(int(e["to"]), int(e["cycle_max"]))
				text = UiText.t("RESULTS_GIFT_METER_NEXT", [UiText.num(gm["progress"]), UiText.num(gm["cycle_max"]), UiText.num(gm["next"])])
			"collection_cards":
				text = UiText.t("RESULTS_CARDS", [e["amount"]])
		if not text.is_empty():
			out.append({"kind": kind, "icon": kind, "text": text})
	for f in receipt.get("follow_ups", []):
		if String(f.get("kind", "")) == "gift_milestone":
			out.append({"kind": "gift_milestone", "icon": "gift_ready", "text": UiText.t("RESULTS_GIFT_READY")})
	return out

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
