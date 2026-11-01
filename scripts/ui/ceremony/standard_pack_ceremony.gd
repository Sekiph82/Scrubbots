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
##
## SB-POLISH-010 V04 storyboard (assets/ui/generated/masters/scrubbots_pack_opening_master_v01.png)
## restyles the same two-tap flow; frames, card truth, destinations and routing are unchanged:
##   1 DROP    IDLE: the pack drops in from the top with a slight tilt over the blurred, darkened
##             Home background (radial spotlight), rim glow, slow light rays, "Tap to open".
##   2 CHARGE  frames 01..03: the pack shakes, the rays brighten, sparkles appear.
##   3 BURST   frames 04..09: light burst + confetti at the tear; the committed cards fly out
##             FACE-DOWN (canonical card back) into a fanned arc above the pack.
##   4 REVEAL  the pack fades; each card flips face-up into its row slot with its rarity glow
##             (Legendary gold rays + halo, Epic purple, Rare blue, Common soft grey) and its
##             NEW / DUPLICATE ribbon; a green COLLECT button is Tap 2 (a tap anywhere still is).
## A tap during OPENING skips forward to the next stage (2 -> 3 -> 4 -> settled hold); cards,
## order and routing never change. Ambient motion (drop, shake, rays, rim pulse) runs in
## _process, never as a tween; the particles are two fixed CPUParticles2D freed with the popup.
## Reduced Effects: no drop / shake / particles / burst / flip / spin (the short version above).

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

## V04 stage dressing: existing approved art only (Home background, card back, sparkle).
const HOME_BG := "res://assets/ui/final/home/background/home_background.png"
const CARD_BACK := "res://assets/ui/final/collection/states/card_back.png"
const SPARKLE := "res://assets/ui/final/gameplay/effects/fx_clean_sparkle.png"
const ACCENT := Color(0.30, 0.68, 1.0)          ## Standard rim glow / rays (blue)
const CONFETTI := [Color(1.0, 0.82, 0.20), Color(0.35, 0.85, 1.0), Color(1.0, 0.45, 0.70), Color(0.55, 0.95, 0.40), Color(1, 1, 1)]
const CONFETTI_AMOUNT := 48

## Timing (s): [FULL, REDUCED]. FULL opening (Tap 1 -> destinations) stays within 2.5..4.0 s.
## FRAME_HOLD[i] = how long frame i (1-based) stays bound before frame i+1 (FULL only).
## V03 owner lock: every FULL beat 01..08 must read as its own beat -> >= 0.18 s each.
const MIN_FULL_HOLD := 0.18
const FRAME_HOLD := [0.0, 0.24, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20]
const FRAME09_HOLD_S := 0.10       ## the open pack (09) rests before the cards fly out
const EMERGE_S := [0.40, 0.30]     ## ALL cards out of the pack (split evenly per card)
const SETTLE_S := 0.50             ## ALL cards flip into their slots (FULL only, split per card)
const PACK_OUT_S := [0.18, 0.10]
const HOLD_S := [0.15, 0.15]       ## card hold (no pack) before the destinations appear
const DEST_IN_S := [0.20, 0.10]
const ROUTE_S := [0.45, 0.20]
const CELEBRATE_PULSE_S := 0.40    ## one NEW card's pulse (FULL only)
const CELEBRATE_STAGGER_S := 0.10  ## start offset between consecutive NEW cards (model order)
const REDUCED_FRAME09_S := 0.15    ## Reduced: the open pack (frame 09) shows briefly
const DROP_S := 0.50               ## IDLE drop-in (FULL; before Tap 1, not part of the opening)
const TILT := -0.10                ## resting tilt of the closed pack (rad)
const BURST_FRAMES := [4, 9]       ## light burst at the first tear and when the cards show

## Pack mouth in frame space (where frame 09's card backs sit), as a fraction of the frame.
const MOUTH := Vector2(0.5, 0.45)
const CARD_MAX_W := 300.0
const CARD_GAP := 24.0
const DEST_BOX := Vector2(220, 150)
const EDGE := 20.0
const SCRIM_DARK := Color(0, 0, 0, 0.92)
const FAN_RAD := 0.60              ## total fan spread of the face-down arc (rad)

static var _bg_tex: Texture2D       ## the blurred Home background, built once per run

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
var _accent := ACCENT
var _rays: Control             ## light rays behind the pack (drawn)
var _rim: TextureRect          ## soft rim glow, child of the pack frame (follows its pose)
var _burst_fx: TextureRect     ## additive light burst at the pack mouth
var _sparkles: CPUParticles2D
var _confetti: CPUParticles2D
var _collect: Button
var _stage_base := Vector2.ZERO
var _t := 0.0                  ## ambient clock (FULL)
var _drop := 0.0               ## IDLE drop-in progress 0..1
var _rays_a := 0.35
var _burst := 0.0
var _ix_out := 0               ## open-plan step indices: pack-out, first settle, destinations
var _ix_settle := 0
var _ix_dest := 0

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

## Ambient motion is FULL only (set here: entering the tree re-enables _process).
func _ready() -> void:
	set_process(not _reduced)

## The nine opening frame paths, 01..09 (M43-C005-C007: a pack subclass supplies its own family).
func _frame_paths() -> Array:
	return PACK_FRAMES.map(func(f): return FRAME_DIR + f)

func _build() -> void:
	# Full-screen backdrop on the scrim (under the safe area): blurred, darkened Home + spotlight.
	var bg := HomeStyle.art("HomeBackdrop")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture = _blurred_home()
	bg.modulate = Color(0.55, 0.62, 0.80)
	_scrim.add_child(bg)
	var spot := HomeStyle.art("Spotlight")
	spot.set_anchors_preset(Control.PRESET_FULL_RECT)
	spot.stretch_mode = TextureRect.STRETCH_SCALE
	spot.texture = _radial([Color(0.45, 0.75, 1.0, 0.22), Color(0, 0, 0, 0.30), Color(0, 0, 0, 0.78)], [0.0, 0.45, 1.0])
	_scrim.add_child(spot)
	_layer = Control.new()
	_layer.name = "Ceremony"
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.gui_input.connect(_on_input)
	_layer.resized.connect(_layout)
	(get_safe_root().get_node("MarginContainer/Content") as Control).add_child(_layer)
	_title_l = _label("Title", UiText.t("PACK_STANDARD_TITLE"), 52)
	_layer.add_child(_title_l)
	_rays = Control.new()
	_rays.name = "Rays"
	_rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rays.draw.connect(_draw_rays)
	_layer.add_child(_rays)
	_stage = TextureRect.new()
	_stage.name = "PackFrame"
	_stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.texture = _frame_tex[0]
	_layer.add_child(_stage)
	_rim = HomeStyle.art("RimGlow")   # around the pack body of the 1024x1536 frames
	_rim.stretch_mode = TextureRect.STRETCH_SCALE
	_rim.texture = CardView.soft_glow()
	_rim.show_behind_parent = true
	_rim.self_modulate = ACCENT
	_rim.modulate.a = 0.6
	_rim.anchor_left = 0.12
	_rim.anchor_right = 0.88
	_rim.anchor_top = 0.22
	_rim.anchor_bottom = 0.92
	_stage.add_child(_rim)
	_burst_fx = HomeStyle.art("Burst")
	_burst_fx.stretch_mode = TextureRect.STRETCH_SCALE
	_burst_fx.texture = CardView.soft_glow()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_burst_fx.material = add
	_burst_fx.visible = false
	_layer.add_child(_burst_fx)
	_sparkles = CPUParticles2D.new()
	_sparkles.name = "Sparkles"
	_sparkles.emitting = false
	_sparkles.amount = 18
	_sparkles.lifetime = 1.0
	_sparkles.texture = load(SPARKLE)
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.gravity = Vector2(0, -60)
	_sparkles.initial_velocity_min = 10.0
	_sparkles.initial_velocity_max = 50.0
	_sparkles.scale_amount_min = 0.025
	_sparkles.scale_amount_max = 0.06
	_sparkles.color_ramp = _ramp([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.3, 1.0])
	_layer.add_child(_sparkles)
	_confetti = CPUParticles2D.new()
	_confetti.name = "Confetti"
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.explosiveness = 0.92
	_confetti.amount = CONFETTI_AMOUNT
	_confetti.lifetime = 1.4
	_confetti.direction = Vector2(0, -1)
	_confetti.spread = 60.0
	_confetti.gravity = Vector2(0, 1500)
	_confetti.initial_velocity_min = 650.0
	_confetti.initial_velocity_max = 1150.0
	_confetti.damping_min = 40.0
	_confetti.damping_max = 120.0
	_confetti.angle_max = 360.0
	_confetti.angular_velocity_min = -420.0
	_confetti.angular_velocity_max = 420.0
	_confetti.scale_amount_min = 9.0
	_confetti.scale_amount_max = 16.0
	_confetti.color_initial_ramp = _ramp(CONFETTI, [0.0, 0.2, 0.4, 0.6, 0.8])
	_confetti.color_initial_ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_confetti.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.7, 1.0])
	_layer.add_child(_confetti)
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
	_hint = _label("Hint", UiText.t("PACK_TAP_OPEN"), 44)
	_hint.add_theme_color_override("font_color", HomeStyle.SUBTITLE)
	_layer.add_child(_hint)
	_collect = Button.new()
	_collect.name = "Collect"
	_collect.text = UiText.t("POPUP_COLLECT")
	_collect.add_theme_font_size_override("font_size", 48)
	HomeStyle.style_play_button(_collect)
	_collect.visible = false
	_collect.pressed.connect(tap)
	_layer.add_child(_collect)

## The Home background, downscaled once (a cheap, strong blur when shown stretched).
static func _blurred_home() -> Texture2D:
	if _bg_tex == null:
		var img := (load(HOME_BG) as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(maxi(img.get_width() / 14, 1), maxi(img.get_height() / 14, 1), Image.INTERPOLATE_LANCZOS)
		_bg_tex = ImageTexture.create_from_image(img)
	return _bg_tex

static func _ramp(colors: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	return g

## Radial gradient (centre -> edge) texture.
static func _radial(colors: Array, offsets: Array) -> GradientTexture2D:
	var t := GradientTexture2D.new()
	t.gradient = _ramp(colors, offsets)
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

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
	_stage_base = (sz - ps) * 0.5
	_stage.position = _stage_base
	_stage.pivot_offset = ps * 0.5
	var mouth := _stage_base + ps * MOUTH
	_burst_fx.size = Vector2(ps.x, ps.x) * 1.3
	_burst_fx.position = mouth - _burst_fx.size * 0.5
	_sparkles.position = _stage_base + ps * 0.5
	_sparkles.emission_rect_extents = ps * Vector2(0.36, 0.34)
	_confetti.position = mouth
	_collect.size = Vector2(minf(sz.x * 0.6, 520.0), 124)
	_collect.position = Vector2((sz.x - _collect.size.x) * 0.5, sz.y - 170)
	_rays.queue_redraw()
	for key in _dest:
		var icon: TextureRect = _dest[key]
		icon.size = DEST_BOX
		icon.position = Vector2(EDGE if key == "collection" else sz.x - EDGE - DEST_BOX.x, EDGE)
		var l: Label = icon.get_node("Label")
		l.position = Vector2(0, DEST_BOX.y)
		l.size = Vector2(DEST_BOX.x, 40)
	var cw := minf(CARD_MAX_W, (sz.x - 2.0 * EDGE - 2.0 * CARD_GAP) / 3.0)
	var row_w := 3.0 * cw + 2.0 * CARD_GAP
	var n := _cards.size()
	var fan_r := ps.y * 0.6   # face-down fan: an arc above the pack mouth, centred below it
	var fan_c := Vector2(sz.x * 0.5, mouth.y - ps.y * 0.22 + fan_r)
	for i in range(n):
		var cv: CardView = _cards[i]
		cv.set_card_width(cw)
		var ang := (i - (n - 1) * 0.5) * FAN_RAD / maxf(n - 1, 1)
		cv.set_arc(fan_c + Vector2.from_angle(-PI * 0.5 + ang) * fan_r, ang)
		var slot := Vector2((sz.x - row_w) * 0.5 + cw * 0.5 + i * (cw + CARD_GAP), sz.y * 0.5)
		cv.set_path(mouth, slot, _dest[destination_of(_model["cards"][i])].position + DEST_BOX * 0.5)

# ------------------------------------------------------------------ gates --

## One deliberate player tap. Gate 1 (IDLE) starts the opening; a tap during the opening skips
## forward to the next stage (V04); gate 2 (AWAIT_ROUTE, or COLLECT) starts routing. Any other
## tap (routing, after completion, not top) is ignored.
func tap() -> bool:
	if not (is_open() and is_top()):
		return false
	var pid := String(_model.get("presentation_id", ""))
	if _phase == Phase.IDLE and _seq.play(pid + ":open", _open_plan()):
		_phase = Phase.OPENING
		_hint.visible = false
		_drop = 1.0
		return true
	if _phase == Phase.OPENING:
		return _skip_stage()
	if _phase == Phase.AWAIT_ROUTE and _seq.play(pid + ":route", _route_plan()):
		_phase = Phase.ROUTING
		_hint.visible = false
		_collect.visible = false
		return true
	return false

## Skip to the next stage start (BURST = frame 04, REVEAL = pack-out), else to the settled hold.
func _skip_stage() -> bool:
	if not _reduced:
		for mark in [3, _ix_out]:
			if _seq.skip_to(mark):
				return true
	_seq.finish()
	return true

func _on_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		tap()

## FULL: frames 01..09 (each after its hold), the cards fly face-down from the pack mouth into
## the fan in model order, the pack fades out, each card flips face-up into its slot, the NEW
## celebration, a short hold, then the destinations appear.
## REDUCED: frame 09 only (briefly), cards fade in face-up at their slots, same hold/destinations.
func _open_plan() -> Array:
	var r := 1 if _reduced else 0
	var n := _cards.size()
	var steps: Array = []
	var first := 0 if not _reduced else PACK_FRAMES.size() - 1
	for i in range(first, PACK_FRAMES.size()):
		var s := {"target": self, "property": "pack_frame", "to": i + 1, "duration": 0.0, "delay": FRAME_HOLD[i] if i > first else 0.0}
		if i == first:
			s["from"] = i + 1
		steps.append(s)
	for i in range(n):
		var d: float = (REDUCED_FRAME09_S if _reduced else FRAME09_HOLD_S) if i == 0 else 0.0
		steps.append({"target": _cards[i], "property": "emerge", "from": 0.0, "to": 1.0, "duration": EMERGE_S[r] / n, "delay": d})
	_ix_out = steps.size()
	steps.append({"target": _stage, "property": "modulate:a", "from": 1.0, "to": 0.0, "duration": PACK_OUT_S[r]})
	_ix_settle = steps.size()
	if not _reduced:
		for i in range(n):
			steps.append({"target": _cards[i], "property": "settle", "from": 0.0, "to": 1.0, "duration": SETTLE_S / n})
	if _has_celebration():
		steps.append({"target": self, "property": "celebration", "from": 0.0, "to": 1.0, "duration": _celebration_s()})
	_ix_dest = steps.size()
	steps.append({"target": _dest_layer, "property": "modulate:a", "from": 0.0, "to": 1.0, "duration": DEST_IN_S[r], "delay": HOLD_S[r]})
	return steps

## Seconds from Tap 1 to the settled hold of the uninterrupted opening (evidence / tests).
func opening_seconds() -> float:
	var t := 0.0
	for s in _open_plan():
		t += float(s.get("delay", 0.0)) + float(s.get("duration", 0.0))
	return t

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

## Open-run step `index` starting means card (index - first_settle - 1) has just landed face-up
## in its slot (FULL). One feel event per landed NEW / Rare-or-better card.
func _card_feel_on_step(index: int) -> void:
	var landed := index - _ix_settle - 1
	if _feel == null or _reduced or landed < 0 or landed >= _cards.size():
		return
	var c: Dictionary = _model["cards"][landed]
	if not bool(c["is_new"]) and String(c["rarity"]) == "COMMON":
		return
	var k := "%s:card%d:reveal" % [String(_model.get("presentation_id", "")), landed]
	if _feel.play("REWARD", (_cards[landed] as CardView).get_badge(), k):
		_feel_log.append([landed, "REWARD", k])

func _dest_step_index() -> int:
	return _ix_dest

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
		_collect.visible = true   # the V04 COLLECT button replaces the caption (a tap anywhere still routes)
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
		if not _reduced and pack_frame in BURST_FRAMES and _confetti != null:
			_burst = 1.0
			if pack_frame == BURST_FRAMES[0]:
				_confetti.restart()

# ------------------------------------------------------------------ ambient (FULL) --

## Drop-in, idle bob, charge shake, rays / rim / burst / hint pulse. Never a tween (no run).
func _process(delta: float) -> void:
	_t += delta
	var off := Vector2.ZERO
	var rot := 0.0
	var charge := 0.0
	if _phase == Phase.IDLE:
		_drop = minf(_drop + delta / DROP_S, 1.0)
		var k := _drop - 1.0
		off.y = (2.70158 * k * k * k + 1.70158 * k * k) * _layer.size.y * 0.75   # ease-out-back drop
		off.y += sin(_t * 2.2) * 8.0 * _drop
		rot = TILT
	elif _phase == Phase.OPENING and pack_frame <= 3:
		charge = pack_frame / 3.0
		rot = sin(_t * 47.0) * 0.045 * charge
		off.x = sin(_t * 61.0) * 8.0 * charge
	_stage.position = _stage_base + off
	_stage.rotation = rot
	var rays_to := 0.35
	if _phase == Phase.OPENING:
		rays_to = 0.45 + 0.18 * pack_frame if pack_frame < 4 else 1.0
	elif _phase == Phase.AWAIT_ROUTE:
		rays_to = 0.6
	elif _phase != Phase.IDLE:
		rays_to = 0.0
	_rays_a = move_toward(_rays_a, rays_to, delta * 2.5)
	_rays.queue_redraw()
	_rim.modulate.a = minf((0.55 + 0.15 * sin(_t * 3.0)) * (1.0 + 0.6 * charge), 1.0)
	_burst = maxf(_burst - delta * 2.5, 0.0)
	_burst_fx.modulate.a = _burst
	_burst_fx.visible = _burst > 0.0
	_sparkles.emitting = _phase == Phase.OPENING or _phase == Phase.AWAIT_ROUTE
	_hint.modulate.a = 0.75 + 0.25 * sin(_t * 4.0)

## Slowly turning light rays from the pack centre, fading outward.
func _draw_rays() -> void:
	var a := _rays_a * (0.75 if not _reduced else 0.5)
	if a <= 0.0:
		return
	var c := _stage_base + _stage.size * 0.5
	var reach := _layer.size.length()
	var clear := Color(_accent, 0.0)
	for i in range(16):
		var ang := _t * 0.25 + TAU * i / 16.0
		_rays.draw_polygon(PackedVector2Array([c, c + Vector2.from_angle(ang - 0.07) * reach, c + Vector2.from_angle(ang + 0.07) * reach]),
			PackedColorArray([Color(_accent, 0.30 * a), clear, clear]))

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
## mouth -> face-down fan; Reduced: fade in face-up at the slot), `settle` (FULL: fan -> row
## slot, flipping face-up), `celebrate` (NEW only, FULL: one pulse + glow settle) and `route`
## (row slot -> destination icon, shrinking and fading as it lands). A NEW card also owns a glow
## TextureRect (canonical card_new_glow.png) that the ceremony parents UNDER all cards. The card
## back and the rarity glow / Legendary rays are drawn by the CardView itself (no extra node).
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
	const CARD_BACK := "res://assets/ui/final/collection/states/card_back.png"
	## V04 rarity glow behind the face (Legendary adds turning gold rays).
	const RARITY_GLOW := {"COMMON": Color(0.86, 0.89, 0.94, 0.45), "RARE": Color(0.30, 0.62, 1.0, 0.80),
		"EPIC": Color(0.72, 0.40, 1.0, 0.85), "LEGENDARY": Color(1.0, 0.80, 0.25, 0.95)}
	const ARC_SCALE := 0.62      ## face-down card size in the fan

	static var _soft: GradientTexture2D

	var emerge := 0.0:
		set(v):
			emerge = v
			_apply()
	var route := 0.0:
		set(v):
			route = v
			_apply()
	## FULL only: 0 = face-down in the fan, 1 = face-up in the row slot (flips at 0.5).
	var settle := 0.0:
		set(v):
			settle = v
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
	var _arc := Vector2.ZERO
	var _arc_rot := 0.0
	var _back_on := false
	var _back_tex: Texture2D
	var _spin := 0.0

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
		var badge := _chip(UiText.t("PACK_CARD_NEW" if is_new else "PACK_CARD_DUPLICATE"), HomeStyle.BADGE if is_new else DUP_BROWN, 22)
		badge.name = "State"   # V04 ribbon on the top-right corner
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		badge.offset_top = -16
		badge.offset_right = 10
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
		_back_tex = load(CARD_BACK)
		_apply()

	## Only a FULL Legendary card turns its rays (entering the tree re-enables _process).
	func _ready() -> void:
		set_process(not reduced and String(card["rarity"]) == "LEGENDARY")

	## Soft white radial glow (tinted by its user), shared.
	static func soft_glow() -> GradientTexture2D:
		if _soft == null:
			_soft = GradientTexture2D.new()
			var g := Gradient.new()
			g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
			g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
			_soft.gradient = g
			_soft.fill = GradientTexture2D.FILL_RADIAL
			_soft.fill_from = Vector2(0.5, 0.5)
			_soft.fill_to = Vector2(1.0, 0.5)
		return _soft

	func _process(delta: float) -> void:
		_spin += delta * 0.5
		queue_redraw()

	## Face-down: the canonical card back. Face-up: the rarity glow (+ Legendary rays) under the face.
	func _draw() -> void:
		var fr := Rect2(Vector2.ZERO, _face.custom_minimum_size)
		if _back_on:
			draw_texture_rect(_back_tex, fr, false)
			return
		var rarity := String(card["rarity"])
		var col: Color = RARITY_GLOW[rarity]
		var c := fr.get_center()
		if rarity == "LEGENDARY":
			var reach := fr.size.y * 0.95
			var clear := Color(col, 0.0)
			for i in range(12):
				var a := _spin + TAU * i / 12.0
				draw_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.09) * reach, c + Vector2.from_angle(a + 0.09) * reach]),
					PackedColorArray([Color(col, 0.55), clear, clear]))
		draw_texture_rect(soft_glow(), fr.grow(fr.size.x * 0.45), false, col)

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

	## Centre (layer space) and tilt of this card's place in the face-down fan.
	func set_arc(point: Vector2, angle: float) -> void:
		_arc = point
		_arc_rot = angle
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
		var rot := 0.0
		var flip := 1.0
		var back := false
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
		elif settle > 0.0:
			var e := 1.0 - (1.0 - settle) * (1.0 - settle)
			c = _arc.lerp(_slot, e)
			s = lerpf(ARC_SCALE, 1.0, e)
			a = 1.0
			rot = lerpf(_arc_rot, 0.0, e)
			flip = absf(cos(PI * settle))   # edge-on at 0.5: back -> face
			back = settle < 0.5
		else:
			var e := 1.0 - (1.0 - emerge) * (1.0 - emerge)
			c = _mouth.lerp(_arc, e)
			s = lerpf(0.3, ARC_SCALE, e)
			a = clampf(emerge * 4.0, 0.0, 1.0)
			rot = lerpf(0.0, _arc_rot, e)
			back = true
		if not reduced and route <= 0.0 and _glow != null:
			s *= 1.0 + POP * sin(PI * celebrate)   # one bump, back to exactly 1.0 at the end
		scale = Vector2(s * flip, s)
		rotation = rot
		position = c - pivot_offset
		modulate.a = a
		visible = a > 0.0
		if back != _back_on:
			_back_on = back
			get_child(0).visible = not back   # Column (face, name, rarity, count)
			queue_redraw()
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
