extends "res://scripts/ui/popup/base_popup.gd"
## StandardPackCeremony — preload (res://scripts/ui/ceremony/standard_pack_ceremony.gd).
##
## M43-C005-C006 (SB-M43-064) V02 — the shipping Standard Card Pack opening, owner flow:
##
##   IDLE        Standard Pack alone (frame 01), "Tap to open". Nothing auto-starts.
##   OPENING     TAP 1 -> frames 01 -> 09, one current beat at a time; in the final beat the 3
##               committed cards rise out of the pack mouth into a centred row; the pack fades
##               away (three-card hold); then COLLECTION (upper-left) and CARDS EXCHANGE
##               (upper-right) destination icons appear.
##   AWAIT_ROUTE waits for TAP 2 ("Tap to collect"). No card moves on its own.
##   ROUTING     TAP 2 -> each card in model order travels to its destination: NEW ->
##               Collection, DUPLICATE -> Cards Exchange.
##   COMPLETE    after the 3rd arrival: presentation_completed(id) once, then the popup
##               closes ("complete") through the normal ModalStack lifecycle.
##
## PRESENTATION ONLY: it consumes one validated, already-committed StandardPackModel. It
## never opens/draws a pack, grants, adds/exchanges a card, saves or navigates — routing is a
## picture of where the committed cards already are. BasePopup/ModalStack own lifecycle and
## Back (consumed; never dismissible, so nothing is left half-resolved). The cream frame is
## hidden: the ceremony is a full-screen dark stage inside the popup's safe area.
## Sequencing: one RevealSequencer, two one-shot keys "<id>:open" and "<id>:route"; extra or
## early taps are ignored. Reduced Effects keeps both taps and both destinations; it only
## skips frames 01..08 and shortens / flattens the motion (fades + straight short moves).
##
## M43-C005-C009 (SB-M43-067) card state, from the committed row only (`is_new`, `copies_after`;
## never live Collection): NEW -> NEW badge + FIRST COPY + the canonical new-card glow; in FULL
## each NEW card gets ONE restrained pulse once the cards have settled in their slots and the
## pack has faded (accepted pack-out timing unchanged; the pulse plays on the clean stage before
## the hold / destinations: one `celebration` step, NEW cards staggered in model order).
## DUPLICATE -> DUPLICATE badge + EXTRAS xN, N = copies_after - 1 (the first copy is protected).
## Reduced: static glow, no pulse. Shared by Standard and Premium through CardView.
##
## M43-C005F-PHASE2 (SB-M43-C005F-005) — optional feel through the ONE app feel adapter
## (bind_feedback; null = exactly the native ceremony above). FULL only: when a committed card
## has LANDED in its hold slot (the next emerge step / the pack-out step starts) and it is NEW or
## Rare-or-better, one adapter REWARD burst at its NEW / DUPLICATE badge (the face's top edge, so
## the rising particles read against the dark stage, not the card art), key
## "<presentation_id>:card<i>:reveal".
## Cards land one emerge step apart, so bursts are serialized (never all five at once); COMMON
## duplicates get none; no flash, no GFF on these Controls, no change to frames / timing /
## layout / routing / truth. Reduced: no adapter call at all.

signal presentation_completed(presentation_id: String)

const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const SELF_PATH := "res://scripts/ui/ceremony/standard_pack_ceremony.gd"

## Owner-approved Standard opening (M43-C005-C002 FINAL OWNER ACCEPTANCE), byte-identical.
const FRAME_DIR := "res://assets/ui/final/rewards/pack_opening/standard/"
const PACK_FRAMES := ["frame_01_closed.png", "frame_02_charge.png", "frame_03_pressure.png",
	"frame_04_first_tear.png", "frame_05_tear_widens.png", "frame_06_card_edge.png",
	"frame_07_one_card_rises.png", "frame_08_cards_emerge.png", "frame_09_final_reveal.png"]
## Existing approved destination art (Home shortcut family).
const DEST_ART := {
	"collection": "res://assets/ui/final/home/shortcuts/icon_shortcut_collection.png",
	"exchange": "res://assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png",
}
enum Phase { IDLE, OPENING, AWAIT_ROUTE, ROUTING, COMPLETE }
const PHASE_NAMES := ["IDLE", "OPENING", "AWAIT_ROUTE", "ROUTING", "COMPLETE"]

## Timing (s): [FULL, REDUCED].
## FRAME_HOLD[i] = how long frame i (1-based) stays bound before frame i+1 (FULL only).
## V03 owner lock: every FULL beat 01..08 must read as its own beat -> >= 0.18 s each.
const MIN_FULL_HOLD := 0.18
const FRAME_HOLD := [0.0, 0.40, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22]
const FRAME09_HOLD_S := 0.30       ## the open pack (09) rests before the cards rise
const EMERGE_S := [0.24, 0.10]
const PACK_OUT_S := [0.25, 0.10]
const HOLD_S := [0.40, 0.15]       ## three-card hold (no pack) before the destinations appear
const DEST_IN_S := [0.25, 0.10]
const ROUTE_S := [0.45, 0.20]
const CELEBRATE_PULSE_S := 0.40    ## one NEW card's pulse (FULL only)
const CELEBRATE_STAGGER_S := 0.10  ## start offset between consecutive NEW cards (model order)
const REDUCED_FRAME09_S := 0.15    ## Reduced: the open pack (frame 09) shows briefly

## Pack mouth in frame space (where frame 09's card backs sit), as a fraction of the frame.
const MOUTH := Vector2(0.5, 0.45)
const CARD_MAX_W := 300.0
const CARD_GAP := 24.0
const DEST_BOX := Vector2(220, 150)
const EDGE := 20.0
const SCRIM_DARK := Color(0, 0, 0, 0.92)

var pack_frame: int = 1:
	set = _set_pack_frame
## 0..1 over the one FULL celebration step; drives each NEW card's own pulse window.
var celebration := 0.0:
	set = _set_celebration

var _model: Dictionary
var _reduced := false
var _phase: int = Phase.IDLE
var _seq: RevealSequencer
var _layer: Control
var _title_l: Label
var _hint: Label
var _stage: TextureRect
var _dest_layer: Control
var _dest: Dictionary = {}     ## "collection"/"exchange" -> TextureRect
var _cards: Array = []         ## CardView x3, model order
var _new_cards: Array = []     ## the NEW CardViews, model order (celebration order)
var _glow_layer: Control
var _frame_tex: Array = []
var _frame_log: Array = []     ## every frame change actually bound, in order (evidence)
var _route_log: Array = []     ## [card index, destination] as each route starts
var _arrivals: Array = []      ## card indices in arrival order
var _feel = null               ## M43-C005F-005: optional app feel adapter (presentation only)
var _feel_log: Array = []      ## [card index, intent, key] actually requested (evidence)

## {ok, reason, popup}: a ceremony only for a valid committed model; otherwise fail closed.
static func create(model, reduced := false) -> Dictionary:
	var v := StandardPackModel.validate(model)
	if not v["ok"]:
		return {"ok": false, "reason": v["reason"], "popup": null}
	var script: GDScript = load(SELF_PATH)
	return {"ok": true, "reason": "", "popup": script.new(v["model"], reduced)}

## Destination of one committed card: NEW -> Collection, DUPLICATE -> Cards Exchange.
static func destination_of(card: Dictionary) -> String:
	return "collection" if bool(card["is_new"]) else "exchange"

func _init(model: Dictionary = {}, reduced := false) -> void:
	super("standard_pack")
	_model = model.duplicate(true)
	_reduced = reduced
	_seq = RevealSequencer.new(self)
	_seq.completed.connect(_on_run_completed)
	_seq.step_started.connect(_on_step)
	set_close_enabled(false)   # Back is consumed (ModalStack) and changes nothing
	set_title(UiText.t("PACK_STANDARD_TITLE"))
	_scrim.color = SCRIM_DARK
	_stack_box.visible = false   # no cream frame: full-screen dark stage
	for path in _frame_paths():
		_frame_tex.append(load(path))
	_build()
	closed.connect(func(_r): _seq.cancel())

## The nine opening frame paths, 01..09 (M43-C005-C007: a pack subclass supplies its own family).
func _frame_paths() -> Array:
	return PACK_FRAMES.map(func(f): return FRAME_DIR + f)

func _build() -> void:
	_layer = Control.new()
	_layer.name = "Ceremony"
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.gui_input.connect(_on_input)
	_layer.resized.connect(_layout)
	(get_safe_root().get_node("MarginContainer/Content") as Control).add_child(_layer)
	_title_l = _label("Title", UiText.t("PACK_STANDARD_TITLE"), 52)
	_layer.add_child(_title_l)
	_stage = TextureRect.new()
	_stage.name = "PackFrame"
	_stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.texture = _frame_tex[0]
	_layer.add_child(_stage)
	_glow_layer = Control.new()   # under every card and destination: a glow never covers card art or text
	_glow_layer.name = "NewGlows"
	_glow_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_glow_layer)
	_dest_layer = Control.new()
	_dest_layer.name = "Destinations"
	_dest_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dest_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dest_layer.visible = false
	_layer.add_child(_dest_layer)
	for key in ["collection", "exchange"]:
		var icon := HomeStyle.art("Dest_" + key)
		icon.texture = load(DEST_ART[key])
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_meta("destination", key)
		_dest_layer.add_child(icon)
		icon.add_child(_label("Label", UiText.t("HOME_SC_COLLECTION" if key == "collection" else "HOME_SC_CARDS_EXCHANGE"), 24))
		_dest[key] = icon
	for i in range(_model.get("cards", []).size()):
		var cv := CardView.new(_model["cards"][i], i, _reduced)
		cv.arrived.connect(_on_arrived)
		_layer.add_child(cv)
		_cards.append(cv)
		if cv.get_glow() != null:
			_glow_layer.add_child(cv.get_glow())
			_new_cards.append(cv)
	_hint = _label("Hint", UiText.t("PACK_TAP_OPEN"), 34)
	_layer.add_child(_hint)

static func _label(n: String, text: String, fs: int) -> Label:
	var l := Label.new()
	l.name = n
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", ROYAL_EDGE)
	return l

## Geometry from the safe-area layer size (re-run on resize; CardView re-applies its pose).
func _layout() -> void:
	var sz := _layer.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	_title_l.position = Vector2(DEST_BOX.x + EDGE, EDGE)
	_title_l.size = Vector2(sz.x - 2.0 * (DEST_BOX.x + EDGE), 70)
	_hint.position = Vector2(0, sz.y - 90)
	_hint.size = Vector2(sz.x, 60)
	var pw := minf(minf(sz.x * 0.8, (sz.y - 320.0) / 1.5), 760.0)
	var ps := Vector2(pw, pw * 1.5)
	_stage.size = ps
	_stage.position = (sz - ps) * 0.5
	var mouth := _stage.position + ps * MOUTH
	for key in _dest:
		var icon: TextureRect = _dest[key]
		icon.size = DEST_BOX
		icon.position = Vector2(EDGE if key == "collection" else sz.x - EDGE - DEST_BOX.x, EDGE)
		var l: Label = icon.get_node("Label")
		l.position = Vector2(0, DEST_BOX.y)
		l.size = Vector2(DEST_BOX.x, 40)
	var cw := minf(CARD_MAX_W, (sz.x - 2.0 * EDGE - 2.0 * CARD_GAP) / 3.0)
	var row_w := 3.0 * cw + 2.0 * CARD_GAP
	for i in range(_cards.size()):
		var cv: CardView = _cards[i]
		cv.set_card_width(cw)
		var slot := Vector2((sz.x - row_w) * 0.5 + cw * 0.5 + i * (cw + CARD_GAP), sz.y * 0.5)
		cv.set_path(mouth, slot, _dest[destination_of(_model["cards"][i])].position + DEST_BOX * 0.5)

# ------------------------------------------------------------------ gates --

## One deliberate player tap. Gate 1 (IDLE) starts the opening; gate 2 (AWAIT_ROUTE) starts
## routing. Any other tap (mid-animation, repeated, after completion, not top) is ignored.
func tap() -> bool:
	if not (is_open() and is_top()):
		return false
	var pid := String(_model.get("presentation_id", ""))
	if _phase == Phase.IDLE and _seq.play(pid + ":open", _open_plan()):
		_phase = Phase.OPENING
		_hint.visible = false
		return true
	if _phase == Phase.AWAIT_ROUTE and _seq.play(pid + ":route", _route_plan()):
		_phase = Phase.ROUTING
		_hint.visible = false
		return true
	return false

func _on_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		tap()

## FULL: frames 01..09 (each after its hold), the 3 cards rise from the pack mouth in model
## order, the pack fades out, a short three-card hold, then the destinations appear.
## REDUCED: frame 09 only (briefly), cards fade in at their slots, same hold/destinations.
func _open_plan() -> Array:
	var r := 1 if _reduced else 0
	var steps: Array = []
	var first := 0 if not _reduced else PACK_FRAMES.size() - 1
	for i in range(first, PACK_FRAMES.size()):
		var s := {"target": self, "property": "pack_frame", "to": i + 1, "duration": 0.0, "delay": FRAME_HOLD[i] if i > first else 0.0}
		if i == first:
			s["from"] = i + 1
		steps.append(s)
	for i in range(_cards.size()):
		var d: float = (REDUCED_FRAME09_S if _reduced else FRAME09_HOLD_S) if i == 0 else 0.0
		steps.append({"target": _cards[i], "property": "emerge", "from": 0.0, "to": 1.0, "duration": EMERGE_S[r], "delay": d})
	steps.append({"target": _stage, "property": "modulate:a", "from": 1.0, "to": 0.0, "duration": PACK_OUT_S[r]})
	if _has_celebration():
		steps.append({"target": self, "property": "celebration", "from": 0.0, "to": 1.0, "duration": _celebration_s()})
	steps.append({"target": _dest_layer, "property": "modulate:a", "from": 0.0, "to": 1.0, "duration": DEST_IN_S[r], "delay": HOLD_S[r]})
	return steps

## Each card in model order travels to its destination (NEW Collection / DUPLICATE Exchange).
func _route_plan() -> Array:
	var r := 1 if _reduced else 0
	return _cards.map(func(cv): return {"target": cv, "property": "route", "from": 0.0, "to": 1.0, "duration": ROUTE_S[r]})

func _on_step(key: String, index: int) -> void:
	var pid := String(_model.get("presentation_id", ""))
	if key == pid + ":open":
		_card_feel_on_step(index)
	if key == pid + ":open" and index == _dest_step_index():
		_dest_layer.visible = true   # shown as its fade starts, after the three-card hold
	elif key == pid + ":route":
		_route_log.append([index, destination_of(_model["cards"][index])])

## Bind (or clear with null) the app's feel adapter. Presentation only; never saved.
func bind_feedback(adapter) -> void:
	_feel = adapter

func feel_log() -> Array:
	return _feel_log.duplicate(true)

## Open-run step `index` starting means card (index - first_emerge - 1) has just landed (the
## pack-out step follows the last card). One feel event per landed NEW / Rare-or-better card.
func _card_feel_on_step(index: int) -> void:
	var landed := index - (PACK_FRAMES.size() if not _reduced else 1) - 1
	if _feel == null or _reduced or landed < 0 or landed >= _cards.size():
		return
	var c: Dictionary = _model["cards"][landed]
	if not bool(c["is_new"]) and String(c["rarity"]) == "COMMON":
		return
	var k := "%s:card%d:reveal" % [String(_model.get("presentation_id", "")), landed]
	if _feel.play("REWARD", (_cards[landed] as CardView).get_badge(), k):
		_feel_log.append([landed, "REWARD", k])

func _dest_step_index() -> int:
	return (PACK_FRAMES.size() if not _reduced else 1) + _cards.size() + (2 if _has_celebration() else 1)

## FULL only, and only when the committed pack has at least one NEW card.
func _has_celebration() -> bool:
	return not _reduced and not _new_cards.is_empty()

func _celebration_s() -> float:
	return CELEBRATE_PULSE_S + (_new_cards.size() - 1) * CELEBRATE_STAGGER_S

## NEW card k pulses over [k * STAGGER, k * STAGGER + PULSE] of the step (bounded overlap).
func _set_celebration(v: float) -> void:
	celebration = v
	if _new_cards.is_empty():
		return
	var t := v * _celebration_s()
	for k in range(_new_cards.size()):
		_new_cards[k].celebrate = clampf((t - k * CELEBRATE_STAGGER_S) / CELEBRATE_PULSE_S, 0.0, 1.0)

func _on_run_completed(key: String) -> void:
	var pid := String(_model.get("presentation_id", ""))
	if key == pid + ":open" and _phase == Phase.OPENING:
		_stage.visible = false   # the pack is gone once the cards are out
		_dest_layer.visible = true
		_phase = Phase.AWAIT_ROUTE
		_hint.text = UiText.t("PACK_TAP_COLLECT")
		_hint.visible = true
	elif key == pid + ":route" and _phase == Phase.ROUTING and _arrivals.size() == _cards.size():
		_phase = Phase.COMPLETE
		presentation_completed.emit(pid)
		close("complete")

func _on_arrived(index: int) -> void:
	if not _arrivals.has(index):
		_arrivals.append(index)

func _set_pack_frame(v: int) -> void:
	pack_frame = clampi(v, 1, PACK_FRAMES.size())
	if _stage != null:
		_stage.texture = _frame_tex[pack_frame - 1]
	if _frame_log.is_empty() or _frame_log.back() != pack_frame:
		_frame_log.append(pack_frame)

# ------------------------------------------------------------------ inspection --

func phase() -> String:
	return PHASE_NAMES[_phase]

func get_model() -> Dictionary:
	return _model.duplicate(true)

func get_sequencer() -> RevealSequencer:
	return _seq

func get_stage() -> TextureRect:
	return _stage

func get_layer() -> Control:
	return _layer

func get_hint() -> Label:
	return _hint

func get_destination(key: String) -> TextureRect:
	return _dest.get(key)

func get_destinations_layer() -> Control:
	return _dest_layer

func get_card_views() -> Array:
	return _cards.duplicate()

func frame_history() -> Array:
	return _frame_log.duplicate()

func route_log() -> Array:
	return _route_log.duplicate(true)

func arrivals() -> Array:
	return _arrivals.duplicate()

func get_glow_layer() -> Control:
	return _glow_layer

## One committed card: the canonical card image as-is (no frame drawn over it), a live NEW /
## DUPLICATE badge on its top edge, live name, rarity chip and the card-state count line
## (FIRST COPY / EXTRAS xN). Its pose is driven by presentation properties: `emerge` (pack
## mouth -> row slot), `celebrate` (NEW only, FULL: one pulse + glow settle) and `route` (row
## slot -> destination icon, shrinking and fading as it lands). A NEW card also owns a glow
## TextureRect (canonical card_new_glow.png) that the ceremony parents UNDER all cards.
class CardView extends Control:
	signal arrived(index: int)
	signal celebrated(index: int)

	const UiText = preload("res://scripts/ui/ui_text.gd")
	const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
	const LABEL_H := 118.0
	const RARITY_COLOR := {"COMMON": Color(0.47, 0.53, 0.62), "RARE": Color(0.10, 0.45, 0.92),
		"EPIC": Color(0.56, 0.25, 0.86), "LEGENDARY": Color(0.92, 0.62, 0.05)}
	const NEW_GREEN := Color(0.20, 0.66, 0.14)
	const DUP_BROWN := Color(0.62, 0.50, 0.30)
	const OUTLINE := Color(0.047, 0.180, 0.459)
	const NEW_GLOW := "res://assets/ui/final/collection/states/card_new_glow.png"
	const GLOW_SCALE := 1.6      ## glow rect = face size x this (same 2:3 aspect as the card)
	const GLOW_REST := 0.5       ## settled glow alpha (FULL after the pulse; Reduced always)
	const GLOW_PEAK_T := 0.35    ## FULL pulse: glow peaks here, then settles to GLOW_REST
	const GLOW_SWELL := 1.12     ## FULL pulse: glow size at its peak (x GLOW_SCALE), settles to 1.0
	const POP := 0.04            ## FULL pulse: max extra card scale (one sine bump, 1.0 -> 1.04 -> 1.0)
	const FIRST_COPY_COLOR := Color(0.72, 1.0, 0.55)
	const EXTRAS_COLOR := Color(1.0, 0.86, 0.45)

	var emerge := 0.0:
		set(v):
			emerge = v
			_apply()
	var route := 0.0:
		set(v):
			route = v
			_apply()
	## NEW + FULL only. The first rise above 0 is THE celebration of this instance
	## (`celebrated` fires at most once; relayout / resize never touch this value).
	var celebrate := 0.0:
		set(v):
			celebrate = v
			if v > 0.0 and not _celebrated and _glow != null and not reduced:
				_celebrated = true
				celebrated.emit(index)
			_apply()
	var card: Dictionary
	var index := 0
	var reduced := false
	var _mouth := Vector2.ZERO
	var _slot := Vector2.ZERO
	var _dest := Vector2.ZERO
	var _face: Control
	var _glow: TextureRect
	var _arrived := false
	var _celebrated := false

	func _init(c: Dictionary, i: int, reduced_effects: bool) -> void:
		card = c.duplicate(true)
		index = i
		reduced = reduced_effects
		name = "CardView_%d" % i
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_meta("card", card.duplicate(true))
		var col := VBoxContainer.new()
		col.name = "Column"
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.add_theme_constant_override("separation", 4)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(col)
		_face = Control.new()
		_face.name = "Face"
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(_face)
		var art := HomeStyle.art("CardArt")
		art.texture = load(String(card["art"]))
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face.add_child(art)
		var is_new := bool(card["is_new"])
		var badge := _chip(UiText.t("PACK_CARD_NEW" if is_new else "PACK_CARD_DUPLICATE"), NEW_GREEN if is_new else DUP_BROWN, 22)
		badge.name = "State"
		badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
		badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
		badge.offset_top = -16
		_face.add_child(badge)
		col.add_child(_text_label("Name", String(card["name"]), 26))
		var rarity := String(card["rarity"])
		var r := _chip(UiText.t("RARITY_" + rarity), RARITY_COLOR[rarity], 22)
		r.name = "Rarity"
		r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(r)
		var count := _text_label("Copies", count_text(card), 24)
		count.add_theme_color_override("font_color", FIRST_COPY_COLOR if is_new else EXTRAS_COLOR)
		col.add_child(count)
		if is_new:
			_glow = TextureRect.new()
			_glow.name = "NewGlow_%d" % i
			_glow.texture = load(NEW_GLOW)
			_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_glow.visible = false
		_apply()

	## Duplicate count of one committed row: the first copy is protected, extras are the rest.
	static func extra_copies(c: Dictionary) -> int:
		return int(c["copies_after"]) - 1

	## The card-state count line, from the committed row only: NEW -> FIRST COPY,
	## DUPLICATE -> EXTRAS xN (N = copies_after - 1, never x0).
	static func count_text(c: Dictionary) -> String:
		return UiText.t("PACK_CARD_FIRST_COPY") if bool(c["is_new"]) else UiText.t("PACK_CARD_EXTRAS", [extra_copies(c)])

	## The card face (art + badge).
	func get_face() -> Control:
		return _face

	## The NEW / DUPLICATE badge on the face's top edge — the feel anchor of this card.
	func get_badge() -> Control:
		return _face.get_node("State")

	## The NEW-card glow (null for a DUPLICATE). The ceremony parents it under every card.
	func get_glow() -> TextureRect:
		return _glow

	func has_celebrated() -> bool:
		return _celebrated

	func set_card_width(cw: float) -> void:
		_face.custom_minimum_size = Vector2(cw, cw * 1.5)
		size = Vector2(cw, cw * 1.5 + LABEL_H)
		pivot_offset = Vector2(cw * 0.5, cw * 0.75)   # face centre
		_apply()

	## Centres (layer space) of the pack mouth, the row slot and the destination icon.
	func set_path(mouth: Vector2, slot: Vector2, dest: Vector2) -> void:
		_mouth = mouth
		_slot = slot
		_dest = dest
		_apply()

	func destination_point() -> Vector2:
		return _dest

	func slot_point() -> Vector2:
		return _slot

	## Current face centre in layer space.
	func face_center() -> Vector2:
		return position + pivot_offset

	func _apply() -> void:
		var c: Vector2
		var s: float
		var a: float
		if route > 0.0:
			var t := 1.0 - (1.0 - route) * (1.0 - route)   # ease-out travel
			c = _slot.lerp(_dest, t)
			s = lerpf(1.0, 0.25, t)
			a = 1.0 - smoothstep(0.8, 1.0, route)
			if route >= 1.0 and not _arrived:
				_arrived = true
				arrived.emit(index)
		elif reduced:
			c = _slot
			s = 1.0
			a = emerge
		else:
			var e := 1.0 - (1.0 - emerge) * (1.0 - emerge)
			c = _mouth.lerp(_slot, e)
			s = lerpf(0.3, 1.0, e)
			a = clampf(emerge * 4.0, 0.0, 1.0)
		if not reduced and route <= 0.0 and _glow != null:
			s *= 1.0 + POP * sin(PI * celebrate)   # one bump, back to exactly 1.0 at the end
		scale = Vector2(s, s)
		position = c - pivot_offset
		modulate.a = a
		visible = a > 0.0
		_apply_glow(c, s, a)

	## Glow centred on the face, under the cards. FULL: invisible until the pulse, peaks, then
	## rests at GLOW_REST. Reduced: GLOW_REST, static. Fades out as routing starts.
	func _apply_glow(c: Vector2, s: float, a: float) -> void:
		if _glow == null:
			return
		var g: float
		var gs := 1.0
		if reduced:
			g = GLOW_REST
		elif celebrate <= 0.0:
			g = 0.0
		elif celebrate < GLOW_PEAK_T:
			g = celebrate / GLOW_PEAK_T
			gs = lerpf(0.85, GLOW_SWELL, g)
		else:
			var k := (celebrate - GLOW_PEAK_T) / (1.0 - GLOW_PEAK_T)
			g = lerpf(1.0, GLOW_REST, k)
			gs = lerpf(GLOW_SWELL, 1.0, k)
		g *= a * (1.0 - clampf(route * 3.0, 0.0, 1.0))
		var gsz := _face.custom_minimum_size * GLOW_SCALE * gs * s
		_glow.size = gsz
		_glow.position = c - gsz * 0.5
		_glow.modulate.a = g
		_glow.visible = g > 0.0

	func glow_alpha() -> float:
		return 0.0 if _glow == null or not _glow.visible else _glow.modulate.a

	func _text_label(n: String, text: String, fs: int) -> Label:
		var l := Label.new()
		l.name = n
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_color_override("font_color", Color(1, 1, 1))
		l.add_theme_constant_override("outline_size", 6)
		l.add_theme_color_override("font_outline_color", OUTLINE)
		return l

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
