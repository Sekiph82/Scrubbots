extends Control
## GameplayScreen — production gameplay screen (M28-C002 Gameplay V02 composition).
## Preload/instantiate scene res://scenes/gameplay/gameplay_screen.tscn (AL-001).
##
## Composition authority: coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md and the
## owner-approved master visual (assets/ui/final/gameplay/master/scrubbots_gameplay_master.png,
## REFERENCE ONLY — never shipped as a flattened screen). V02 supersedes the historical
## M28-C001 bottom Pause / ad / speed row.
##
##   TOP      profile chip (top-left)                     PAUSE | 2x (top-right)
##   BOARD    BoardRenderer + full four-sided Railroad V1 (dominant, aspect-correct)
##            five permanent slot -> bottom-rail connectors (sixth only with +1 Slot)
##   SLOTS    execution slots immediately below the board
##   SUPPLY   Batch Supply (3/4/5 columns x 3 visible rows; only fronts interactive)
##            Scrubby / speech area low-left, cleaning props right
##   BOOSTERS exactly four: +1 Slot / Random / Selector / Tornado
##   (no Settings, no Heart HUD, no Goal/Moves/Time, no Level rail, no ad placeholder)
##
## Boundaries (blocking, unchanged from M28-C001):
##   - This screen is PRESENTATION. It owns no BoardState/M23/M24/M25/M26/M27 truth; batch
##     views are fed DETACHED scalar snapshots; HUD/booster/speed values are pushed in by
##     the host from the canonical services. Controls only emit intents.
##   - Supply-front selection stays the only board-side input (M29 controller); the slots
##     are never destination buttons.
##   - Single-Image BoardRenderer preserved; railroad geometry comes only from
##     ScrubRailGeometry; connectors come from the SAME slot-origin mapping the runtime
##     route uses (SlotOriginProvider + ScrubRailGeometry.bottom_entry).

signal booster_pressed(booster_id: String)

const SafeAreaRootScene = preload("res://scenes/components/ui/common/safe_area_root.tscn")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const ScrubRailView = preload("res://scripts/ui/scrub_rail_view.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const SlotOriginProvider = preload("res://scripts/gameplay/runtime/slot_origin_provider.gd")
const FiveSlotStrip = preload("res://scripts/ui/five_slot_strip.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")

const BG01 := Color8(32, 37, 51, 255)   # BG01 Midnight Slate — gameplay background
## Rail envelope pad in logical cells beyond the board on each side: outer rail edge =
## board boundary + CENTER_OFFSET (2.5) + RAIL_WIDTH * 0.5 = +3.0 cells.
const RAIL_PAD_CELLS := 3.0

## V02 layout metrics (reference px; the safe rect is the layout space).
const TOP_H := 128.0
const CONTROL_SIZE := 112.0        # Pause / 2x (>= TOUCH_MIN)
const CONNECTOR_GAP := 84.0        # bottom rail outer edge -> slot tops (visible connectors)
const STRIP_H := 132.0
const TRAY_GAP := 14.0
const SUPPLY_H := 262.0
const BOOSTER_H := 150.0
const BOOSTER_SIZE := 132.0
const GAP := 16.0
const STRIP_WIDTH_FRAC := 0.68

## Approved art (read-only; never regenerated/overwritten).
const ART := {
	"portrait": "res://assets/ui/final/gameplay/profile/scrubby_portrait.png",
	"pause": "res://assets/ui/final/gameplay/controls/button_pause.png",
	"speed": "res://assets/ui/final/gameplay/controls/button_speed_2x.png",
	"speed_active": "res://assets/ui/final/gameplay/controls/button_speed_2x_active.png",
	"speed_timed": "res://assets/ui/final/gameplay/controls/button_speed_2x_countdown_frame.png",
	"scrubby": "res://assets/ui/final/characters/scrubby/scrubby_gameplay.png",
	"speech": "res://assets/ui/final/gameplay/tutorial/speech_bubble.png",
	"bucket": "res://assets/ui/final/gameplay/decorative/bubble_bucket.png",
	"wet_sign": "res://assets/ui/final/gameplay/decorative/caution_wet_floor_sign.png",
	"booster_selected": "res://assets/ui/final/boosters/states/booster_selected_ring.png",
	"booster_unavailable": "res://assets/ui/final/boosters/states/booster_unavailable_overlay.png",
}
## Exactly the four canonical Economy V1 boosters, in owner order.
const BOOSTERS := [
	{"id": "plus_one_slot", "art": "res://assets/ui/final/boosters/extra_slot.png"},
	{"id": "random", "art": "res://assets/ui/final/boosters/random.png"},
	{"id": "selector", "art": "res://assets/ui/final/boosters/selector.png"},
	{"id": "tornado", "art": "res://assets/ui/final/boosters/tornado.png"},
]
## Booster presentation states (pushed by the host from canonical services).
const BOOSTER_AVAILABLE := "available"      # owned charge(s): shows the live count
const BOOSTER_PURCHASABLE := "purchasable"  # no charge: shows the canonical SB price
const BOOSTER_UNAVAILABLE := "unavailable"  # cannot be used right now
const BOOSTER_SELECTED := "selected"        # active this attempt (e.g. +1 Slot in use)
const BOOSTER_LOCKED := "locked"            # feature-locked (no unlock authority yet)

## 2x presentation modes.
const SPEED_OFF := "off"
const SPEED_LEVEL := "level"    # manual 2x on, current-level entitlement
const SPEED_TIMED := "timed"    # timed entitlement exists: live wall-clock label
const SPEED_AUTO := "auto"      # free M23-exhausted automatic 2x (never a purchase)

# --- bound presentation state (detached; no gameplay truth retained) ---
var _board                       # BoardState (read-only source for renderer/geometry)
var _palette: PackedStringArray
var _palette_colors: Array = []
var _slot_snapshots: Array = []
var _supply_snapshot: Array = []

# --- node handles ---
var _background: ColorRect
var _backdrop: TextureRect
var _safe_root
var _content: Control
var _screen_content: Control
var _top_region: Control
var _profile: Panel
var _profile_name: Label
var _profile_level: Label
var _profile_parts: Label
var _profile_bar: ProgressBar
var _board_region: Control
var _presentation
var _rail_view
var _batch_region: Control
var _slot_tray: Panel
var _supply_tray: Panel
var _speech_anchor: TextureRect
var _scrubby_anchor: TextureRect
var _props_anchor: Control
var _five_slot_strip
var _supply_panel
var _booster_row: HBoxContainer
var _booster_buttons: Dictionary = {}   # id -> Button
var _booster_states: Dictionary = {}    # id -> {charges, price, state}
var _pause_btn: Button
var _paused := false
var _speed_btn: Button
var _speed_top: Label
var _speed_time: Label
var _speed_2x := false
var _speed_entitlement := "none"        # none | level | timed
var _speed_remaining := 0

var _layout_mode: int = ResponsiveLayout.LayoutMode.NORMAL
var _cell_size: float = 1.0
var _laid_capacity: int = FiveSlotStrip.SLOT_COUNT
var _connector_segments: Array = []
var _built := false

func _ready() -> void:
	if not _built:
		_build_tree()
	resized.connect(relayout)
	relayout()

## Bind a board + palette + detached batch snapshots, then relayout.
func configure(board, palette: PackedStringArray, slot_snapshots: Array = [], supply_snapshot: Array = []) -> void:
	_board = board
	_palette = palette
	var parse = PaletteColors.parse(palette)
	_palette_colors = parse.colors
	_slot_snapshots = slot_snapshots.duplicate(true)
	_supply_snapshot = supply_snapshot.duplicate(true)
	if not _built:
		_build_tree()
	_build_board_presentation()
	_bind_batch_views()
	relayout()

## Update only the detached batch snapshots (no board rebuild). Presentation only.
func update_snapshots(slot_snapshots: Array, supply_snapshot: Array) -> void:
	_slot_snapshots = slot_snapshots.duplicate(true)
	_supply_snapshot = supply_snapshot.duplicate(true)
	_bind_batch_views()
	_sync_capacity_layout()

## Live five-slot refresh (M29-C001 V03): push a fresh DETACHED authoritative M24
## snapshot into the strip after any runtime M24 mutation. Presentation-only.
func refresh_slot_snapshot(slot_snapshots: Array) -> void:
	_slot_snapshots = slot_snapshots.duplicate(true)
	if _five_slot_strip != null:
		_five_slot_strip.bind_snapshots(_slot_snapshots, _palette_colors)
	_sync_capacity_layout()

## Test/preview seam: apply synthetic safe-area insets (this viewport's pixels).
func set_synthetic_safe_insets(left: int, top: int, right: int, bottom: int) -> void:
	if _safe_root != null:
		_safe_root.set_synthetic_insets(left, top, right, bottom)

# ------------------------------------------------------------------ tree build --

func _build_tree() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = HomeStyle.make_theme()

	_background = ColorRect.new()
	_background.name = "Background"
	_background.color = BG01
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	# Native depth gradient over BG01 (no approved portrait gameplay backdrop exists).
	_backdrop = TextureRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.set_color(0, Color(0.10, 0.17, 0.33))
	grad.set_color(1, Color(0.035, 0.05, 0.10))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 256
	_backdrop.texture = gt
	add_child(_backdrop)

	_safe_root = SafeAreaRootScene.instantiate()
	add_child(_safe_root)
	_content = _safe_root.get_node("MarginContainer/Content")

	_screen_content = Control.new()
	_screen_content.name = "ScreenContent"
	_screen_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_screen_content)
	_content.resized.connect(relayout)

	_top_region = _new_region("TopRegion")
	_board_region = _new_region("BoardRegion")
	_batch_region = _new_region("BatchRegion")
	_build_top()

	# --- Slots / supply trays, decoration, batch views ---
	_slot_tray = _tray("SlotTray")
	_supply_tray = _tray("SupplyTray")
	_speech_anchor = _art_rect("ScrubbySpeechAnchor", ART["speech"])
	_speech_anchor.visible = false   # no authorised tutorial copy yet (FTUE is M44)
	_scrubby_anchor = _art_rect("ScrubbyDecorationAnchor", ART["scrubby"])
	_props_anchor = Control.new()
	_props_anchor.name = "CleaningPropsAnchor"
	_props_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bucket := _art_rect("BubbleBucket", ART["bucket"])
	bucket.set_anchors_preset(Control.PRESET_FULL_RECT)
	bucket.anchor_top = 0.0
	bucket.anchor_bottom = 0.55
	var wet_sign := _art_rect("WetFloorSign", ART["wet_sign"])
	wet_sign.set_anchors_preset(Control.PRESET_FULL_RECT)
	wet_sign.anchor_top = 0.42
	_props_anchor.add_child(bucket)
	_props_anchor.add_child(wet_sign)
	for n in [_slot_tray, _supply_tray, _speech_anchor, _scrubby_anchor, _props_anchor]:
		_batch_region.add_child(n)

	_five_slot_strip = FiveSlotStrip.new()
	_five_slot_strip.name = "FiveSlotStrip"
	_batch_region.add_child(_five_slot_strip)
	# Connectors track the strip's REAL laid-out slot anchors (incl. the +1 Slot sixth).
	_five_slot_strip.sort_children.connect(_queue_connector_update)

	_supply_panel = BatchSupplyPanel.new()
	_supply_panel.name = "BatchSupplyPanel"
	_batch_region.add_child(_supply_panel)

	# --- Booster row: exactly four canonical boosters ---
	_booster_row = HBoxContainer.new()
	_booster_row.name = "BoosterRow"
	_booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_booster_row.add_theme_constant_override("separation", 40)
	_screen_content.add_child(_booster_row)
	for spec in BOOSTERS:
		var b := _make_booster(spec)
		_booster_row.add_child(b)
		_booster_buttons[spec["id"]] = b
		_booster_states[spec["id"]] = {"charges": 0, "price": 0, "state": BOOSTER_UNAVAILABLE}
		_apply_booster_visual(spec["id"])

func _build_top() -> void:
	# Profile chip (top-left): native panel (the approved profile_panel_frame / bar_fill
	# pieces carry opaque white corners and cannot be shown as-is) + approved Scrubby
	# portrait + live level / Bot Parts progress.
	_profile = Panel.new()
	_profile.name = "ProfileChip"
	_profile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile.add_theme_stylebox_override("panel", HomeStyle.box(Color(0.05, 0.15, 0.40, 0.96), HomeStyle.EDGE, 5, 30, 10, 3))
	_top_region.add_child(_profile)
	var portrait := _art_rect("Portrait", ART["portrait"])
	_frac(portrait, 0.03, 0.12, 0.235, 0.88)
	_profile.add_child(portrait)
	_profile_name = HomeStyle.label(UiText.t("HOME_PLAYER_NAME_DEFAULT"), 32)
	_profile_name.name = "ProfileName"
	_profile_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frac(_profile_name, 0.27, 0.06, 0.64, 0.50)
	_profile.add_child(_profile_name)
	_profile_level = HomeStyle.label("", 26, HomeStyle.SUBTITLE)
	_profile_level.name = "ProfileLevel"
	_profile_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_frac(_profile_level, 0.62, 0.06, 0.95, 0.50)
	_profile.add_child(_profile_level)
	_profile_bar = ProgressBar.new()
	_profile_bar.name = "BotPartsBar"
	_profile_bar.show_percentage = false
	_profile_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeStyle.style_meter(_profile_bar, HomeStyle.GOLD, 34)
	_frac(_profile_bar, 0.27, 0.56, 0.95, 0.86)
	_profile.add_child(_profile_bar)
	_profile_parts = HomeStyle.label("", 22)
	_profile_parts.name = "BotPartsText"
	_profile_parts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_parts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frac(_profile_parts, 0.27, 0.56, 0.95, 0.86)
	_profile.add_child(_profile_parts)

	# PAUSE | 2x (top-right). Existing host seams: pressed -> pause toggle / speed gate.
	_pause_btn = _art_button("PauseButton", ART["pause"])
	_pause_btn.text = "II"
	_top_region.add_child(_pause_btn)
	_speed_btn = _art_button("SpeedControl", ART["speed"])
	_top_region.add_child(_speed_btn)
	_speed_top = HomeStyle.label("2x", 40)
	_speed_top.name = "SpeedTop"
	_speed_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_top.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frac(_speed_top, 0.08, 0.08, 0.92, 0.50)
	_speed_btn.add_child(_speed_top)
	_speed_time = HomeStyle.label("", 26)
	_speed_time.name = "SpeedTime"
	_speed_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frac(_speed_time, 0.15, 0.50, 0.85, 0.78)
	_speed_btn.add_child(_speed_time)
	_apply_speed_visual()

func _new_region(node_name: String) -> Control:
	var c := Control.new()
	c.name = node_name
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_content.add_child(c)
	return c

func _tray(node_name: String) -> Panel:
	var p := Panel.new()
	p.name = node_name
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", HomeStyle.box(Color(0.075, 0.13, 0.30, 0.92), Color(0.30, 0.55, 0.95, 0.9), 4, 30, 10, 3))
	return p

func _art_rect(node_name: String, path: String) -> TextureRect:
	var t := HomeStyle.art(node_name)
	t.texture = load(path) as Texture2D
	return t

## Anchor a child by fractions of its parent (resolution independent).
func _frac(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0

static func _texture_style(path: String) -> StyleBox:
	var tex := load(path) as Texture2D
	if tex == null:
		return HomeStyle.box(HomeStyle.CARD, HomeStyle.EDGE, 4, 24)
	var s := StyleBoxTexture.new()
	s.texture = tex
	return s

func _art_button(node_name: String, path: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(CONTROL_SIZE, CONTROL_SIZE)
	_set_button_art(b, path)
	# The approved control art carries its own glyph; the Button text stays as the
	# semantic/accessibility value but is not painted over the art.
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	return b

func _set_button_art(b: Button, path: String) -> void:
	var s := _texture_style(path)
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_booster(spec: Dictionary) -> Button:
	var b := Button.new()
	b.name = "Booster_" + String(spec["id"])
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(BOOSTER_SIZE, BOOSTER_SIZE)
	var disc := HomeStyle.box(Color(0.96, 0.92, 0.84), Color(0.62, 0.72, 0.88), 5, int(BOOSTER_SIZE / 2), 8, 4)
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, disc)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var icon := _art_rect("Icon", spec["art"])
	_frac(icon, 0.12, 0.12, 0.88, 0.88)
	b.add_child(icon)
	var ring := _art_rect("SelectedRing", ART["booster_selected"])
	_frac(ring, -0.08, -0.08, 1.08, 1.08)
	b.add_child(ring)
	var overlay := _art_rect("UnavailableOverlay", ART["booster_unavailable"])
	_frac(overlay, 0.0, 0.0, 1.0, 1.0)
	b.add_child(overlay)
	var badge := Label.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 30)
	badge.add_theme_stylebox_override("normal", HomeStyle.box(HomeStyle.GREEN, Color(1, 1, 1), 4, 26, 4, 0))
	_frac(badge, 0.66, -0.04, 1.08, 0.36)
	b.add_child(badge)
	var price := Label.new()
	price.name = "Price"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 26)
	price.add_theme_stylebox_override("normal", HomeStyle.box(Color(0.08, 0.20, 0.50), HomeStyle.GOLD, 3, 18, 4, 0))
	_frac(price, 0.10, 0.78, 0.90, 1.06)
	b.add_child(price)
	var id: String = spec["id"]
	b.pressed.connect(func(): booster_pressed.emit(id))
	return b

# ------------------------------------------------------------ board presentation --

func _build_board_presentation() -> void:
	if _board == null:
		return
	if _presentation != null and is_instance_valid(_presentation):
		_presentation.queue_free()
	_presentation = BoardPresentation.new()
	_presentation.name = "BoardPresentation"
	_board_region.add_child(_presentation)
	_presentation.configure(_board, _palette, Vector2(_board.get_width(), _board.get_height()))
	# ScrubRailView: canonical ScrubRailGeometry, same board-local transform as the agents,
	# drawn just under AgentLayer; finalized per layout in _layout_board().
	_rail_view = ScrubRailView.new()
	_rail_view.name = "ScrubRailView"
	_presentation.add_child(_rail_view)
	var agent_layer: Node2D = _presentation.get_agent_layer()
	if agent_layer != null:
		_presentation.move_child(_rail_view, agent_layer.get_index())
	_rail_view.configure(_board.get_width(), _board.get_height())

func _bind_batch_views() -> void:
	if _five_slot_strip != null:
		_five_slot_strip.bind_snapshots(_slot_snapshots, _palette_colors)
	if _supply_panel != null and not _supply_snapshot.is_empty():
		_supply_panel.bind_player_snapshot(_supply_snapshot, _palette_colors)

## +1 Slot grows the strip to six (host-owned transition): widen the slot row and
## redraw connectors so the sixth connector appears only while the sixth slot exists.
func _sync_capacity_layout() -> void:
	if _five_slot_strip != null and _five_slot_strip.get_capacity() != _laid_capacity:
		relayout()

# ------------------------------------------------------------------ layout --

func relayout() -> void:
	if not _built or _content == null:
		return
	var s: Vector2 = _content.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	_layout_mode = ResponsiveLayout.get_layout_mode(get_viewport_rect().size)
	var bw: float = float(_board.get_width()) if _board != null else 20.0
	var bh: float = float(_board.get_height()) if _board != null else 20.0
	var batch_h: float = STRIP_H + TRAY_GAP + 10.0 + SUPPLY_H
	var fixed: float = TOP_H + GAP + CONNECTOR_GAP + batch_h + GAP + BOOSTER_H + GAP
	var avail: float = maxf(s.y - fixed, 1.0)
	var env := Vector2(bw + 2.0 * RAIL_PAD_CELLS, bh + 2.0 * RAIL_PAD_CELLS)
	_cell_size = maxf(floor(minf(s.x / env.x, avail / env.y)), 1.0)
	var env_px: Vector2 = env * _cell_size
	# Spare height (tall phones) is shared above the board and above the boosters so the
	# board -> connectors -> slots -> supply chain stays contiguous.
	var extra: float = maxf(avail - env_px.y, 0.0)

	_place(_top_region, 0.0, 0.0, s.x, TOP_H)
	_layout_top(Vector2(s.x, TOP_H))
	var y: float = TOP_H + GAP + extra * 0.35
	_place(_board_region, 0.0, y, s.x, env_px.y)
	y += env_px.y + CONNECTOR_GAP
	_place(_batch_region, 0.0, y, s.x, batch_h)
	y += batch_h + GAP + extra * 0.35
	var row_w: float = minf(s.x, 4.0 * BOOSTER_SIZE + 3.0 * 40.0 + 2.0 * GAP)
	_place(_booster_row, (s.x - row_w) * 0.5, y, row_w, BOOSTER_H)

	_layout_board(env)
	_layout_batch_region(Vector2(s.x, batch_h), bw)
	_laid_capacity = _five_slot_strip.get_capacity()
	_queue_connector_update()

func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)

func _layout_top(region: Vector2) -> void:
	var ch: float = region.y - 8.0
	var cw: float = minf(500.0, region.x - 2.0 * CONTROL_SIZE - 3.0 * GAP)
	_place(_profile, 0.0, 4.0, cw, ch)
	var cy: float = (region.y - CONTROL_SIZE) * 0.5
	_place(_speed_btn, region.x - CONTROL_SIZE, cy, CONTROL_SIZE, CONTROL_SIZE)
	_place(_pause_btn, region.x - 2.0 * CONTROL_SIZE - GAP, cy, CONTROL_SIZE, CONTROL_SIZE)

func _layout_batch_region(region: Vector2, bw: float) -> void:
	var cx: float = region.x * 0.5
	var cap: int = _five_slot_strip.get_capacity()
	var min_strip: float = cap * UiTokens.BATCH_SLOT_MIN + (cap - 1) * UiTokens.SPACE_SM
	var rail_span: float = (bw + 2.0 * ScrubRailGeometry.CENTER_OFFSET) * _cell_size
	# Slots sit under the bottom rail: kept within the rail span (vertical connectors),
	# never narrower than their readable minimum (then outer anchors clamp exactly as
	# the route does).
	var strip_w: float = clampf(region.x * STRIP_WIDTH_FRAC, min_strip, maxf(min_strip, rail_span - _cell_size))
	strip_w = minf(strip_w, region.x)
	var supply_w: float = minf(maxf(strip_w, float(UiTokens.SUPPLY_PANEL_MIN_WIDTH)), region.x)
	var pad := 10.0
	_place(_five_slot_strip, cx - strip_w * 0.5, 0.0, strip_w, STRIP_H)
	_place(_slot_tray, cx - strip_w * 0.5 - pad, -pad, strip_w + 2.0 * pad, STRIP_H + 2.0 * pad)
	var sy: float = STRIP_H + TRAY_GAP + pad
	_place(_supply_tray, cx - supply_w * 0.5, sy, supply_w, SUPPLY_H)
	_place(_supply_panel, cx - supply_w * 0.5 + pad, sy + pad, supply_w - 2.0 * pad, SUPPLY_H - 2.0 * pad)
	# Decoration shares the side space left of / right of the supply and shrinks first.
	var side: float = maxf(cx - supply_w * 0.5 - 8.0, 0.0)
	_place(_speech_anchor, 0.0, sy, side, SUPPLY_H * 0.42)
	_place(_scrubby_anchor, 0.0, sy + SUPPLY_H * 0.30, side, SUPPLY_H * 0.70)
	_place(_props_anchor, region.x - side, sy + SUPPLY_H * 0.22, side, SUPPLY_H * 0.78)
	var show_decor: bool = side >= 96.0
	_scrubby_anchor.visible = show_decor
	_props_anchor.visible = show_decor

func _layout_board(env: Vector2) -> void:
	if _presentation == null or not is_instance_valid(_presentation) or _board == null:
		return
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	_presentation.configure(_board, _palette, Vector2(w * _cell_size, h * _cell_size))
	_cell_size = _presentation.get_cell_size()
	if _rail_view != null:
		_rail_view.position = Vector2.ZERO
		_rail_view.scale = Vector2(_cell_size, _cell_size)
		_rail_view.configure(w, h)
	var region: Vector2 = _board_region.size
	var env_px: Vector2 = env * _cell_size
	_presentation.position = Vector2(
		(region.x - env_px.x) * 0.5 + RAIL_PAD_CELLS * _cell_size,
		(region.y - env_px.y) * 0.5 + RAIL_PAD_CELLS * _cell_size)

# ------------------------------------------------------------------ connectors --

func _queue_connector_update() -> void:
	if is_inside_tree():
		call_deferred("_update_connectors")
	else:
		_update_connectors()

## One connector per CURRENT slot (5, or 6 with +1 Slot): the exact runtime route start
## (SlotOriginProvider.origin_for_slot) to its bottom-rail entry
## (ScrubRailGeometry.bottom_entry(origin.x)) — the same two points ProductionRoutingSystem
## uses for real Scrubbot travel. Unmappable slots get no connector (fail closed).
func _update_connectors() -> void:
	_connector_segments = []
	if _rail_view == null or not is_instance_valid(_rail_view) or _board == null:
		return
	var geom = _rail_view.get_geometry()
	if geom == null or not geom.is_valid():
		return
	var provider = SlotOriginProvider.new(_presentation, _five_slot_strip, _board)
	for i in range(_five_slot_strip.get_slot_count()):
		var o: Vector2 = provider.origin_for_slot(i)
		if not (is_finite(o.x) and is_finite(o.y)):
			continue
		_connector_segments.append([o, geom.bottom_entry(o.x)])
	_rail_view.set_connectors(_connector_segments)

## Board-local [origin, bottom_entry] per visible slot connector.
func get_connector_segments() -> Array:
	return _connector_segments.duplicate(true)

# ------------------------------------------------------------------ HUD binding --

## Live profile values from canonical authorities (host): {level, bot_parts, bot_parts_cost}.
func set_profile(data: Dictionary) -> void:
	var level: int = int(data.get("level", 0))
	_profile_level.text = UiText.t("RESULTS_LEVEL", [level]) if level > 0 else ""
	var parts: int = int(data.get("bot_parts", -1))
	var cost: int = int(data.get("bot_parts_cost", 0))
	var has_parts: bool = parts >= 0 and cost > 0
	_profile_parts.text = UiText.t("HOME_RATIO", [parts, cost]) if has_parts else ""
	_profile_bar.max_value = maxf(float(cost), 1.0)
	_profile_bar.value = clampf(float(parts), 0.0, float(cost)) if has_parts else 0.0
	_profile_bar.visible = has_parts

func get_profile_level_text() -> String:
	return _profile_level.text

func get_profile_parts_text() -> String:
	return _profile_parts.text

## Entitlement presentation pushed by the host from SpeedEntitlementService:
## entitlement = "none" | "level" | "timed"; timed_remaining = wall-clock seconds.
func set_speed_presentation(entitlement: String, timed_remaining: int = 0) -> void:
	_speed_entitlement = entitlement
	_speed_remaining = maxi(timed_remaining, 0)
	_apply_speed_visual()

## Presented gameplay speed ("1x"/"2x"). A new session presents 1x.
func get_speed_state() -> String:
	return "2x" if _speed_2x else "1x"

## Presentation-only: displayed speed state. Never changes timing truth.
func set_speed_2x(value: bool) -> void:
	_speed_2x = value
	_apply_speed_visual()

## off | level | timed | auto (see constants).
func get_speed_mode() -> String:
	if _speed_entitlement == "timed" and _speed_remaining > 0:
		return SPEED_TIMED
	if not _speed_2x:
		return SPEED_OFF
	return SPEED_LEVEL if _speed_entitlement == "level" else SPEED_AUTO

## Live label: remaining wall-clock time while a timed entitlement exists, else "2x".
func get_speed_label() -> String:
	return _speed_btn.text

static func format_remaining(seconds: int) -> String:
	var s := maxi(seconds, 0)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%02d:%02d" % [s / 60, s % 60]

func _apply_speed_visual() -> void:
	if _speed_btn == null:
		return
	var mode := get_speed_mode()
	var timed := mode == SPEED_TIMED
	_speed_btn.text = format_remaining(_speed_remaining) if timed else "2x"
	_speed_top.visible = timed
	_speed_time.visible = timed
	_speed_time.text = _speed_btn.text if timed else ""
	var path: String = ART["speed_timed"] if timed else (ART["speed_active"] if _speed_2x else ART["speed"])
	_set_button_art(_speed_btn, path)
	# Timed but currently 1x: the countdown keeps running, the control reads unselected.
	# Free automatic 2x is visibly distinct from paid 2x (green tint).
	if timed and not _speed_2x:
		_speed_btn.modulate = Color(0.72, 0.76, 0.86)
	elif mode == SPEED_AUTO:
		_speed_btn.modulate = Color(0.70, 1.0, 0.72)
	else:
		_speed_btn.modulate = Color(1, 1, 1)

## Presentation-only pause state (the canonical Pause popup is M43-C002).
func set_paused(paused: bool) -> void:
	_paused = paused
	if _pause_btn != null:
		_pause_btn.modulate = Color(0.62, 0.66, 0.78) if paused else Color(1, 1, 1)

func is_paused_visual() -> bool:
	return _paused

## Push live booster states from the canonical services:
## [{id, charges, price, state}] with state in available/purchasable/unavailable/selected/locked.
func set_booster_states(states: Array) -> void:
	for st in states:
		var id := String(st.get("id", ""))
		if not _booster_states.has(id):
			continue   # exactly four canonical boosters; anything else is ignored
		_booster_states[id] = {"charges": int(st.get("charges", 0)), "price": int(st.get("price", 0)),
			"state": String(st.get("state", BOOSTER_UNAVAILABLE))}
		_apply_booster_visual(id)

func _apply_booster_visual(id: String) -> void:
	var b: Button = _booster_buttons.get(id)
	var st: Dictionary = _booster_states[id]
	var state := String(st["state"])
	var badge: Label = b.get_node("Badge")
	var price: Label = b.get_node("Price")
	badge.visible = int(st["charges"]) > 0
	badge.text = str(int(st["charges"]))
	price.visible = int(st["charges"]) <= 0 and int(st["price"]) > 0 and state != BOOSTER_LOCKED and state != BOOSTER_SELECTED
	price.text = "%d SB" % int(st["price"])
	b.get_node("SelectedRing").visible = state == BOOSTER_SELECTED
	b.get_node("UnavailableOverlay").visible = state == BOOSTER_UNAVAILABLE or state == BOOSTER_LOCKED
	b.disabled = state == BOOSTER_LOCKED
	b.modulate = Color(0.72, 0.72, 0.78) if state == BOOSTER_UNAVAILABLE or state == BOOSTER_LOCKED else Color(1, 1, 1)

func get_booster_button(id: String) -> Button:
	return _booster_buttons.get(id)

func get_booster_state(id: String) -> Dictionary:
	return (_booster_states.get(id, {}) as Dictionary).duplicate()

func get_booster_ids() -> Array:
	return BOOSTERS.map(func(b): return b["id"])

# ---------------------------------------------------------------- accessors --
# Read-only presentation/test accessors. None expose or mutate gameplay truth.

func get_layout_mode() -> int:
	return _layout_mode

func get_cell_size() -> float:
	return _cell_size

func get_presentation():
	return _presentation

func get_rail_view():
	return _rail_view

func get_five_slot_strip():
	return _five_slot_strip

func get_supply_panel():
	return _supply_panel

## Host wiring seams: top-right Pause and 2x controls.
func get_pause_button() -> Button:
	return _pause_btn

func get_speed_button() -> Button:
	return _speed_btn

func _global_rect(c: Control) -> Rect2:
	return Rect2(c.global_position, c.size)

func get_safe_rect() -> Rect2:
	return _global_rect(_content) if _content != null else Rect2()

func get_top_region_rect() -> Rect2:
	return _global_rect(_top_region)

func get_profile_rect() -> Rect2:
	return _global_rect(_profile)

## Board + four-sided rail envelope region (global).
func get_board_region_rect() -> Rect2:
	return _global_rect(_board_region)

## Rendered board pixel rect in GLOBAL space (excludes rail clearance).
func get_board_rect() -> Rect2:
	if _presentation == null or not is_instance_valid(_presentation) or _board == null:
		return Rect2()
	var origin: Vector2 = _presentation.global_position
	return Rect2(origin, Vector2(_board.get_width() * _cell_size, _board.get_height() * _cell_size))

func get_batch_region_rect() -> Rect2:
	return _global_rect(_batch_region)

func get_five_slot_strip_rect() -> Rect2:
	return _global_rect(_five_slot_strip)

func get_supply_panel_rect() -> Rect2:
	return _global_rect(_supply_panel)

func get_scrubby_anchor_rect() -> Rect2:
	return _global_rect(_scrubby_anchor)

func get_speech_anchor_rect() -> Rect2:
	return _global_rect(_speech_anchor)

func get_props_anchor_rect() -> Rect2:
	return _global_rect(_props_anchor)

func get_booster_row_rect() -> Rect2:
	return _global_rect(_booster_row)

func get_booster_count() -> int:
	return _booster_row.get_child_count() if _booster_row != null else 0

func get_pause_rect() -> Rect2:
	return _global_rect(_pause_btn)

func get_speed_control_rect() -> Rect2:
	return _global_rect(_speed_btn)

## True iff a Goal/Moves panel exists anywhere in the tree (must be false).
func has_goal_moves_panel() -> bool:
	return _find_named(self, ["GoalMoves", "GoalPanel", "MovesPanel", "GoalMovesPanel", "TimePanel", "MovesTimePanel"])

## True iff a Level/lock rail exists anywhere in the tree (must be false).
func has_level_lock_rail() -> bool:
	return _find_named(self, ["LevelRail", "LockRail", "LevelLockRail"])

## V02: no gameplay ad placeholder / bottom action row, no Settings, no Heart HUD.
func has_ad_placeholder() -> bool:
	return _find_named(self, ["AdPlaceholder", "BottomActionRow", "AdBanner"])

func has_settings_control() -> bool:
	return _find_named(self, ["SettingsButton", "SettingsControl", "Settings"])

func has_heart_hud() -> bool:
	return _find_named(self, ["HeartsChip", "HeartHud", "HeartsHud", "Hearts"])

func _find_named(node: Node, names: Array) -> bool:
	if names.has(String(node.name)):
		return true
	for child in node.get_children():
		if _find_named(child, names):
			return true
	return false

## Map a logical board cell center -> global screen point (via the renderer).
func cell_center_to_global(x: int, y: int) -> Vector2:
	if _presentation == null or not is_instance_valid(_presentation):
		return Vector2.INF
	return _presentation.get_renderer().get_cell_center_global(x, y)

## Inverse: global screen point -> board-local cell units (via AgentLayer transform).
func global_to_board_local(p: Vector2) -> Vector2:
	if _presentation == null or not is_instance_valid(_presentation):
		return Vector2.INF
	return _presentation.global_to_board_local(p)
