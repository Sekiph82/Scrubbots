extends "res://scripts/ui/popup/base_popup.gd"
## StandardPackCeremony — preload (res://scripts/ui/ceremony/standard_pack_ceremony.gd).
##
## M43-C005-C006 (SB-M43-064) — the shipping Standard Card Pack opening: a BasePopup (pushed
## on the ModalStack like every popup) presenting ONE already-committed Standard pack of
## exactly 3 cards (StandardPackModel). PRESENTATION ONLY: it never opens/draws a pack,
## grants, claims, adds to Collection, saves or navigates; its single action ("continue")
## only closes the popup and is reported through action_selected like any popup action.
##
##   STANDARD PACK (title pill)
##   PackStage   owner-approved 9-frame opening, frames 01 -> 09, card backs only
##   Cards       3 canonical C003 card images (their own frame/name/rarity art), each with a
##               live NEW / DUPLICATE badge, live name, rarity chip and the post-commit
##               owned count
##   CommittedNote + CONTINUE (blocked until the presentation completes)
##
## Sequencing: one RevealSequencer (key = presentation_id, one-shot per instance). Each pack
## beat is a zero-duration step on `pack_frame` after its hold; then the 3 card tiles fade in
## in model order. Reduced Effects plays only the final frame + cards, landing at once.
## A tap on the stage/cards fast-forwards (presentation only). Back/Escape is consumed and
## does nothing (not dismissible). Closing cancels the presentation.

signal presentation_completed(presentation_id: String)

const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const SELF_PATH := "res://scripts/ui/ceremony/standard_pack_ceremony.gd"

## Owner-approved Standard opening (M43-C005-C002 FINAL OWNER ACCEPTANCE), byte-identical
## promotion of the accepted candidates. Order is the approved beat order.
const FRAME_DIR := "res://assets/ui/final/rewards/pack_opening/standard/"
const PACK_FRAMES := ["frame_01_closed.png", "frame_02_charge.png", "frame_03_pressure.png",
	"frame_04_first_tear.png", "frame_05_tear_widens.png", "frame_06_card_edge.png",
	"frame_07_one_card_rises.png", "frame_08_cards_emerge.png", "frame_09_final_reveal.png"]
## Hold (s) before each frame appears: the closed pack rests a little longer before the charge.
const FRAME_HOLD := [0.0, 0.40, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14]
const FINAL_HOLD_S := 0.35   ## frame 09 rests before the faces
const CARD_S := 0.20         ## per-card face fade
const STAGE_SIZE := Vector2(320, 480)   ## 2:3 like the 1024x1536 frames
const CARD_W := 196
const STAGE_BG := Color(0.0, 0.0, 0.0)  ## frames 05/07/09 carry an accepted near-black ground
const RARITY_COLOR := {"COMMON": Color(0.47, 0.53, 0.62), "RARE": Color(0.10, 0.45, 0.92),
	"EPIC": Color(0.56, 0.25, 0.86), "LEGENDARY": Color(0.92, 0.62, 0.05)}
const NEW_GREEN := Color(0.20, 0.66, 0.14)
const DUP_BROWN := Color(0.62, 0.50, 0.30)

var pack_frame: int = 1:
	set = _set_pack_frame

var _model: Dictionary
var _reduced := false
var _seq: RevealSequencer
var _stage: TextureRect
var _tiles: Array = []
var _note: Label
var _frame_tex: Array = []
var _frame_log: Array = []   ## every frame change actually bound, in order (evidence)

## {ok, reason, popup}: a ceremony only for a valid committed model; otherwise fail closed.
static func create(model, reduced := false) -> Dictionary:
	var v := StandardPackModel.validate(model)
	if not v["ok"]:
		return {"ok": false, "reason": v["reason"], "popup": null}
	var script: GDScript = load(SELF_PATH)
	return {"ok": true, "reason": "", "popup": script.new(v["model"], reduced)}

func _init(model: Dictionary = {}, reduced := false) -> void:
	super("standard_pack")
	_model = model.duplicate(true)
	_reduced = reduced
	_seq = RevealSequencer.new(self)
	_seq.completed.connect(_on_completed)
	set_frame("large")
	set_close_enabled(false)   # Back is consumed; the ceremony ends only through Continue
	set_title(UiText.t("PACK_STANDARD_TITLE"))
	for f in PACK_FRAMES:
		_frame_tex.append(load(FRAME_DIR + f))
	_build()
	add_action("continue", UiText.t("PACK_CONTINUE"), "primary", true)
	set_action_blocked("continue", true)
	opened.connect(start_presentation)
	closed.connect(func(_r): _seq.cancel())

func _build() -> void:
	var reveal := VBoxContainer.new()
	reveal.name = "Reveal"
	reveal.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	reveal.gui_input.connect(_on_reveal_input)
	get_content().add_child(reveal)
	var stage := PanelContainer.new()
	stage.name = "PackStage"
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_theme_stylebox_override("panel", HomeStyle.box(STAGE_BG, ROYAL_EDGE, 4, 26, 0))
	reveal.add_child(stage)
	_stage = TextureRect.new()
	_stage.name = "PackFrame"
	_stage.custom_minimum_size = STAGE_SIZE
	_stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.texture = _frame_tex[0]
	stage.add_child(_stage)
	var row := HBoxContainer.new()
	row.name = "Cards"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal.add_child(row)
	for i in range(_model.get("cards", []).size()):
		var t := _card_tile(_model["cards"][i], i)
		row.add_child(t)
		_tiles.append(t)
	_note = add_body_line(UiText.t("PACK_COMMITTED_NOTE"), "CommittedNote", INK, 24)

## One committed card: the canonical card image as-is (no second frame drawn over it), a
## live NEW / DUPLICATE badge on its top edge, live name, rarity chip, owned count.
func _card_tile(c: Dictionary, i: int) -> Control:
	var is_new := bool(c["is_new"])
	var rarity := String(c["rarity"])
	var tile := VBoxContainer.new()
	tile.name = "CardTile_%d" % i
	tile.set_meta("card", c.duplicate(true))
	tile.custom_minimum_size = Vector2(CARD_W, 0)
	tile.add_theme_constant_override("separation", 4)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := Control.new()
	face.name = "Face"
	face.custom_minimum_size = Vector2(CARD_W, CARD_W * 1.5)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(face)
	var art := HomeStyle.art("CardArt")
	art.texture = load(String(c["art"]))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(art)
	var badge := _chip(UiText.t("PACK_CARD_NEW" if is_new else "PACK_CARD_DUPLICATE"), NEW_GREEN if is_new else DUP_BROWN, 20)
	badge.name = "State"
	badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	badge.offset_top = -14
	face.add_child(badge)
	var name_l := body_label(String(c["name"]), 24)
	name_l.name = "Name"
	tile.add_child(name_l)
	var r := _chip(UiText.t("RARITY_" + rarity), RARITY_COLOR[rarity], 20)
	r.name = "Rarity"
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_child(r)
	var own := body_label(UiText.t("PACK_CARD_OWNED", [int(c["copies_after"])]), 20)
	own.name = "Copies"
	tile.add_child(own)
	return tile

static func _chip(text: String, bg: Color, fs: int) -> PanelContainer:
	var c := PanelContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, bg.darkened(0.35), 3, 18, 0), 12, 2))
	var l := Label.new()
	l.name = "Text"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", bg.darkened(0.5))
	c.add_child(l)
	return c

# ------------------------------------------------------------------ presentation --

## Start the one-shot presentation for this instance (called on open). False when it
## already ran (same presentation id) — a re-open never produces a second run.
func start_presentation() -> bool:
	return _seq.play(String(_model.get("presentation_id", "")), _plan(), _reduced)

## Fast-forward to the exact final state (frame 09 + all 3 faces). Presentation only.
func finish_presentation() -> void:
	_seq.finish()

func is_presenting() -> bool:
	return _seq.is_active()

## FULL: frames 01..09 (each after its hold), then the faces in model order, then the note.
## REDUCED: frame 09 + faces only, landed immediately by the sequencer.
func _plan() -> Array:
	var steps: Array = []
	var first := 0 if not _reduced else PACK_FRAMES.size() - 1
	for i in range(first, PACK_FRAMES.size()):
		var s := {"target": self, "property": "pack_frame", "to": i + 1, "duration": 0.0, "delay": FRAME_HOLD[i] if i > first else 0.0}
		if i == first:
			s["from"] = i + 1
		steps.append(s)
	for i in range(_tiles.size()):
		steps.append(RevealSequencer.fade(_tiles[i], CARD_S, FINAL_HOLD_S if i == 0 else 0.0))
	steps.append(RevealSequencer.fade(_note, CARD_S))
	return steps

func _set_pack_frame(v: int) -> void:
	pack_frame = clampi(v, 1, PACK_FRAMES.size())
	if _stage != null:
		_stage.texture = _frame_tex[pack_frame - 1]
	if _frame_log.is_empty() or _frame_log.back() != pack_frame:
		_frame_log.append(pack_frame)

func _on_completed(key: String) -> void:
	set_action_blocked("continue", false)
	presentation_completed.emit(key)

func _on_reveal_input(event: InputEvent) -> void:
	if not (is_open() and is_top()):
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		finish_presentation()

# ------------------------------------------------------------------ inspection ---

func get_model() -> Dictionary:
	return _model.duplicate(true)

func get_sequencer() -> RevealSequencer:
	return _seq

func get_stage() -> TextureRect:
	return _stage

func get_note() -> Label:
	return _note

func get_card_tiles() -> Array:
	return _tiles.duplicate()

func frame_history() -> Array:
	return _frame_log.duplicate()
