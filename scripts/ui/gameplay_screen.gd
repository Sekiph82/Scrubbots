extends Control
## GameplayScreen — production gameplay screen (M28-C002 Gameplay V02, static master shell).
## Preload/instantiate scene res://scenes/gameplay/gameplay_screen.tscn (AL-001).
##
## Authority: coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md (supersedes the
## C001 native-redrawn chrome). The whole static composition — environment, visible
## Railway, board frame/field, 5 or 6 slot frames + connectors, 3/4/5×3 Batch Supply cells,
## profile frame, Pause/2x frames, Scrubby, speech bubble, props — comes from ONE of six
## owner masters, selected by two authoritative runtime facts:
##
##   Batch Supply columns (3/4/5)  ×  execution-slot capacity (5/6)  ->  "<cap>slot_<cols>col"
##
## Godot overlays ONLY live content, all placed through ONE uniform reference transform
## (master px -> screen: origin + p * scale, aspect-fit inside the safe rect):
##   BoardRenderer (fitted so the runtime ScrubRailGeometry loop lands on the baked rail),
##   Scrubbot agents, live slot colour/count/state, live supply colour/count + front-only
##   hitboxes, profile portrait/Level/Bot Parts, Pause state, 2x state/timer, four boosters,
##   the reserved bottom ad region, and a clean mask over the obsolete baked bubble text.
## No second visible rail, slot frame, connector, supply frame or profile/control chrome is
## drawn. Presentation only: no gameplay truth is owned here; controls emit intents.

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
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")

const FILL := Color(0.035, 0.055, 0.11)   # surround outside the aspect-fitted shell
## Rail envelope pad in logical cells beyond the board (outer rail edge = +3.0 cells).
const RAIL_PAD_CELLS := 3.0
## Geometry used for layout when the shell fails closed (no valid column/capacity pair).
const FALLBACK_SHELL := "5slot_5col"

const PORTRAIT_ART := "res://assets/ui/final/gameplay/profile/scrubby_portrait.png"
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
var _portrait: TextureRect = null
var _portrait_robot := ""
## Profile overlay layout inside the baked profile box (master px).
const PROFILE_PORTRAIT := [54, 38, 162, 150]
const PROFILE_NAME := [176, 40, 300, 92]
const PROFILE_LEVEL := [290, 40, 398, 92]
const PROFILE_BAR := [176, 102, 398, 140]
## Invisible anchors on the baked Scrubby / bubble / props (future FTUE text anchor, tests).
const SPEECH_ANCHOR := [19, 1188, 204, 1356]
const SCRUBBY_ANCHOR := [18, 1345, 245, 1590]
const PROPS_ANCHOR := [705, 1265, 880, 1590]

const BOOSTERS := [
	{"id": "plus_one_slot", "art": "res://assets/ui/final/boosters/extra_slot.png"},
	{"id": "random", "art": "res://assets/ui/final/boosters/random.png"},
	{"id": "selector", "art": "res://assets/ui/final/boosters/selector.png"},
	{"id": "tornado", "art": "res://assets/ui/final/boosters/tornado.png"},
]
## Live bubble copy layout inside the masked text area (master px) + colours sampled to
## match the master's own navy lettering.
const BUBBLE_HEADLINE_REF := [34, 1200, 191, 1252]
const BUBBLE_INSTRUCTION_REF := [34, 1256, 191, 1320]
const BUBBLE_HEADLINE_COLOR := Color8(22, 36, 128)
const BUBBLE_TEXT_COLOR := Color8(28, 44, 110)
const BUBBLE_HEADLINE_REF_PX := 21.0
const BUBBLE_TEXT_REF_PX := 17.0

const BOOSTER_SELECTED_ART := "res://assets/ui/final/boosters/states/booster_selected_ring.png"
const BOOSTER_UNAVAILABLE_ART := "res://assets/ui/final/boosters/states/booster_unavailable_overlay.png"
const BOOSTER_AVAILABLE := "available"
const BOOSTER_PURCHASABLE := "purchasable"
const BOOSTER_UNAVAILABLE := "unavailable"
const BOOSTER_SELECTED := "selected"
const BOOSTER_LOCKED := "locked"

const SPEED_OFF := "off"
const SPEED_LEVEL := "level"
const SPEED_TIMED := "timed"
const SPEED_AUTO := "auto"

# --- bound presentation state (detached; no gameplay truth retained) ---
var _board
var _palette: PackedStringArray
var _palette_colors: Array = []
var _slot_snapshots: Array = []
var _supply_snapshot: Array = []

# --- shell / transform ---
var _shell_id := ""
var _shell_error := ""
var _geom_id := FALLBACK_SHELL
var _scale := 1.0
var _origin := Vector2.ZERO           # ScreenContent-local position of master (0,0)
var _shell_tex_cache: Dictionary = {}

# --- node handles ---
var _background: ColorRect
var _safe_root
var _content: Control
var _screen_content: Control
var _shell: TextureRect
var _bubble_mask: Panel
var _bubble_headline: Label
var _bubble_instruction: Label
var _top_region: Control
var _profile: Control
var _profile_name: Label
var _profile_level: Label
var _profile_parts: Label
var _profile_bar: ProgressBar
var _board_region: Control
var _presentation
var _rail_view
var _batch_region: Control
var _five_slot_strip
var _supply_panel
var _speech_anchor: Control
var _scrubby_anchor: Control
var _props_anchor: Control
var _booster_row: HBoxContainer
var _booster_buttons: Dictionary = {}
var _booster_states: Dictionary = {}
var _ad_region: Panel
var _pause_btn: Button
var _pause_glyph: Control
var _paused := false
var _speed_btn: Button
var _speed_main: Label
var _speed_time: Label
var _speed_2x := false
var _speed_entitlement := "none"
var _speed_remaining := 0

var _layout_mode: int = ResponsiveLayout.LayoutMode.NORMAL
var _cell_size: float = 1.0
var _connector_segments: Array = []
var _built := false

func _ready() -> void:
	if not _built:
		_build_tree()
	resized.connect(relayout)
	relayout()

## Bind a board + palette + detached batch snapshots, then select the shell and relayout.
func configure(board, palette: PackedStringArray, slot_snapshots: Array = [], supply_snapshot: Array = []) -> void:
	_board = board
	_palette = palette
	_palette_colors = PaletteColors.parse(palette).colors
	_slot_snapshots = slot_snapshots.duplicate(true)
	_supply_snapshot = supply_snapshot.duplicate(true)
	if not _built:
		_build_tree()
	_build_board_presentation()
	_bind_batch_views()
	relayout()

func update_snapshots(slot_snapshots: Array, supply_snapshot: Array) -> void:
	_slot_snapshots = slot_snapshots.duplicate(true)
	_supply_snapshot = supply_snapshot.duplicate(true)
	_bind_batch_views()
	_sync_shell()

func refresh_slot_snapshot(slot_snapshots: Array) -> void:
	_slot_snapshots = slot_snapshots.duplicate(true)
	if _five_slot_strip != null:
		_five_slot_strip.bind_snapshots(_slot_snapshots, _palette_colors)
	_sync_shell()

func set_synthetic_safe_insets(left: int, top: int, right: int, bottom: int) -> void:
	if _safe_root != null:
		_safe_root.set_synthetic_insets(left, top, right, bottom)

# ------------------------------------------------------------------ shell selection --

## Authoritative facts: supply column count (from the detached M23 snapshot) and the
## live execution-slot capacity (5, or 6 after +1 Slot). Unsupported pairs fail closed.
func _wanted_shell() -> String:
	var cap: int = _five_slot_strip.get_capacity() if _five_slot_strip != null else FiveSlotStrip.SLOT_COUNT
	return Shell.shell_id(_supply_snapshot.size(), cap)

func _sync_shell() -> void:
	if _wanted_shell() != _shell_id or (_shell_id == "" and _shell_error == ""):
		relayout()

func _apply_shell_selection() -> void:
	var id := _wanted_shell()
	_shell_id = id
	if id == "":
		var cap: int = _five_slot_strip.get_capacity() if _five_slot_strip != null else 0
		_shell_error = "unsupported:%dcol/%dslot" % [_supply_snapshot.size(), cap]
		_shell.texture = null
		_shell.visible = false
		_geom_id = FALLBACK_SHELL
		return
	_shell_error = ""
	_geom_id = id
	if not _shell_tex_cache.has(id):
		_shell_tex_cache[id] = load(Shell.texture_path(id)) as Texture2D
	_shell.texture = _shell_tex_cache[id]
	_shell.visible = _shell.texture != null

func get_shell_id() -> String:
	return _shell_id

func get_shell_error() -> String:
	return _shell_error

func get_shell_texture_path() -> String:
	return _shell.texture.resource_path if _shell != null and _shell.texture != null else ""

# ------------------------------------------------------------------ tree build --

func _build_tree() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = HomeStyle.make_theme()
	_background = ColorRect.new()
	_background.name = "Background"
	_background.color = FILL
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_safe_root = SafeAreaRootScene.instantiate()
	add_child(_safe_root)
	_content = _safe_root.get_node("MarginContainer/Content")
	_screen_content = Control.new()
	_screen_content.name = "ScreenContent"
	_screen_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_screen_content)
	_content.resized.connect(relayout)

	# The selected owner master (static shell) — one TextureRect, uniform scale only.
	_shell = TextureRect.new()
	_shell.name = "GameplayShell"
	_shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shell.stretch_mode = TextureRect.STRETCH_SCALE
	_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_content.add_child(_shell)

	# Obsolete baked instruction masked with the bubble's own fill (bubble art kept).
	_bubble_mask = Panel.new()
	_bubble_mask.name = "SpeechBubbleMask"
	_bubble_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_content.add_child(_bubble_mask)
	# R01 (owner item B): live, localizable bubble copy over the masked area (the master
	# bytes are untouched; the obsolete baked sentence stays covered).
	_bubble_headline = _bubble_label("BubbleHeadline", "GP_BUBBLE_HEADLINE", BUBBLE_HEADLINE_COLOR)
	_bubble_instruction = _bubble_label("BubbleInstruction", "GP_BUBBLE_INSTRUCTION", BUBBLE_TEXT_COLOR)

	_top_region = _new_region("TopRegion")
	_board_region = _new_region("BoardRegion")
	_batch_region = _new_region("BatchRegion")
	_speech_anchor = _new_region("ScrubbySpeechAnchor")
	_scrubby_anchor = _new_region("ScrubbyDecorationAnchor")
	_props_anchor = _new_region("CleaningPropsAnchor")
	_build_top()

	_five_slot_strip = FiveSlotStrip.new()
	_five_slot_strip.name = "FiveSlotStrip"
	_batch_region.add_child(_five_slot_strip)
	_five_slot_strip.set_slot_rects([])   # shell mode: no slot frame chrome
	_five_slot_strip.sort_children.connect(_queue_connector_update)
	_supply_panel = BatchSupplyPanel.new()
	_supply_panel.name = "BatchSupplyPanel"
	_batch_region.add_child(_supply_panel)
	_supply_panel.set_shell_grid(Vector2(UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	_supply_panel.set_min_hit_size(float(UiTokens.TOUCH_MIN))   # S2-B invisible touch geometry

	_booster_row = HBoxContainer.new()
	_booster_row.name = "BoosterRow"
	_booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_screen_content.add_child(_booster_row)
	for spec in BOOSTERS:
		var b := _make_booster(spec)
		_booster_row.add_child(b)
		_booster_buttons[spec["id"]] = b
		_booster_states[spec["id"]] = {"charges": 0, "price": 0, "state": BOOSTER_UNAVAILABLE}
		_apply_booster_visual(spec["id"])

	# Reserved bottom ad region (layout only; ad serving is M57).
	_ad_region = Panel.new()
	_ad_region.name = "AdRegion"
	_ad_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# S3-B: reserved but INVISIBLE until M57 real ad integration (no band, no label).
	_ad_region.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_screen_content.add_child(_ad_region)

func _build_top() -> void:
	# Profile: live content only inside the baked profile box (no panel chrome).
	_profile = Control.new()
	_profile.name = "ProfileChip"
	_profile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_region.add_child(_profile)
	var portrait := HomeStyle.art("Portrait")
	portrait.texture = load(PORTRAIT_ART) as Texture2D
	_profile.add_child(portrait)
	_portrait = portrait
	_profile_name = HomeStyle.label(UiText.t("HOME_PLAYER_NAME_DEFAULT"), 30)
	_profile_name.name = "ProfileName"
	_profile_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile.add_child(_profile_name)
	_profile_level = HomeStyle.label("", 24, HomeStyle.SUBTITLE)
	_profile_level.name = "ProfileLevel"
	_profile_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_profile.add_child(_profile_level)
	_profile_bar = ProgressBar.new()
	_profile_bar.name = "BotPartsBar"
	_profile_bar.show_percentage = false
	_profile_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeStyle.style_meter(_profile_bar, HomeStyle.GOLD, 30)
	_profile_bar.custom_minimum_size = Vector2.ZERO
	_profile.add_child(_profile_bar)
	_profile_parts = HomeStyle.label("", 20)
	_profile_parts.name = "BotPartsText"
	_profile_parts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_parts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_profile.add_child(_profile_parts)

	# Pause / 2x: flat hit areas exactly over the baked boxes; glyph/state/text only.
	_pause_btn = _flat_button("PauseButton")
	_pause_btn.text = "II"
	_top_region.add_child(_pause_btn)
	_pause_glyph = Control.new()
	_pause_glyph.name = "PauseGlyph"
	_pause_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_glyph.draw.connect(_draw_pause_glyph)
	_pause_btn.add_child(_pause_glyph)
	_speed_btn = _flat_button("SpeedControl")
	_top_region.add_child(_speed_btn)
	_speed_main = HomeStyle.label("2x", 56)
	_speed_main.name = "SpeedMain"
	_speed_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speed_main.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_btn.add_child(_speed_main)
	_speed_time = HomeStyle.label("", 26)
	_speed_time.name = "SpeedTime"
	_speed_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speed_btn.add_child(_speed_time)
	_apply_speed_visual()

func _bubble_label(node_name: String, key: String, color: Color) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = UiText.t(key)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = false
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_screen_content.add_child(l)
	return l

## Place both bubble lines through the master transform and shrink each font until its
## wrapped text fits its box (all six masters share the same bubble geometry).
func _layout_bubble_text() -> void:
	for pair in [[_bubble_headline, BUBBLE_HEADLINE_REF, BUBBLE_HEADLINE_REF_PX], [_bubble_instruction, BUBBLE_INSTRUCTION_REF, BUBBLE_TEXT_REF_PX]]:
		var l: Label = pair[0]
		_place_ref(l, pair[1])
		var px: int = maxi(int(pair[2] * _scale), 8)
		var box: Rect2 = ref_rect_to_local(Shell.rect(pair[1]))
		# Measure with the Label's own wrapped minimum (includes its line spacing), not a
		# raw font metric, so the chosen size can never make the Label outgrow its box.
		while true:
			l.add_theme_font_size_override("font_size", px)
			l.size = Vector2(box.size.x, 0.0)
			if px <= 8 or l.get_minimum_size().y <= box.size.y:
				break
			px -= 1
		l.position = box.position
		l.size = box.size

## True when both live bubble strings fit their boxes at the current size (tests).
func bubble_text_fits() -> bool:
	for l in [_bubble_headline, _bubble_instruction]:
		if l.text.is_empty() or l.get_minimum_size().y > l.size.y + 0.5:
			return false
	return true

func _new_region(node_name: String) -> Control:
	var c := Control.new()
	c.name = node_name
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_content.add_child(c)
	return c

func _flat_button(node_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	# Button text stays the semantic/accessibility value; the visible content is the
	# overlaid glyph / live labels.
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	return b

func _draw_pause_glyph() -> void:
	var sz: Vector2 = _pause_glyph.size
	var c := sz * 0.5
	var h: float = minf(sz.x, sz.y) * 0.46
	var ink := Color(1, 1, 1)
	var outline := Color(0.05, 0.10, 0.25)
	if _paused:
		# Play triangle: the control resumes.
		var pts := PackedVector2Array([c + Vector2(-h * 0.38, -h * 0.5), c + Vector2(h * 0.52, 0), c + Vector2(-h * 0.38, h * 0.5)])
		_pause_glyph.draw_colored_polygon(pts, ink)
		pts.append(pts[0])
		_pause_glyph.draw_polyline(pts, outline, maxf(h * 0.08, 2.0), true)
	else:
		var bw: float = h * 0.28
		for dx in [-h * 0.24, h * 0.24]:
			var r := Rect2(c.x + dx - bw * 0.5, c.y - h * 0.5, bw, h)
			_pause_glyph.draw_rect(r.grow(maxf(h * 0.05, 1.5)), outline)
			_pause_glyph.draw_rect(r, ink)

func _make_booster(spec: Dictionary) -> Button:
	var b := Button.new()
	b.name = "Booster_" + String(spec["id"])
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var icon := HomeStyle.art("Icon")
	icon.texture = load(spec["art"]) as Texture2D
	_frac(icon, 0.12, 0.12, 0.88, 0.88)
	b.add_child(icon)
	var ring := HomeStyle.art("SelectedRing")
	ring.texture = load(BOOSTER_SELECTED_ART) as Texture2D
	_frac(ring, -0.08, -0.08, 1.08, 1.08)
	b.add_child(ring)
	var overlay := HomeStyle.art("UnavailableOverlay")
	overlay.texture = load(BOOSTER_UNAVAILABLE_ART) as Texture2D
	_frac(overlay, 0.0, 0.0, 1.0, 1.0)
	b.add_child(overlay)
	var badge := Label.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", HomeStyle.box(HomeStyle.GREEN, Color(1, 1, 1), 3, 24, 4, 0))
	_frac(badge, 0.66, -0.04, 1.08, 0.36)
	b.add_child(badge)
	var price := Label.new()
	price.name = "Price"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.add_theme_stylebox_override("normal", HomeStyle.box(Color(0.08, 0.20, 0.50), HomeStyle.GOLD, 3, 16, 4, 0))
	_frac(price, 0.06, 0.78, 0.94, 1.06)
	b.add_child(price)
	var id: String = spec["id"]
	b.pressed.connect(func(): booster_pressed.emit(id))
	return b

func _frac(c: Control, l: float, t: float, r: float, bt: float) -> void:
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = bt
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0

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
	# Canonical ScrubRailGeometry provider for connectors/tests. The VISIBLE Railway is
	# the baked shell art, so this view never draws (no second rail skin).
	_rail_view = ScrubRailView.new()
	_rail_view.name = "ScrubRailView"
	_rail_view.visible = false
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

# ------------------------------------------------------------------ layout --

## ONE uniform reference transform: master px -> ScreenContent-local px.
func ref_to_local(p: Vector2) -> Vector2:
	return _origin + p * _scale

func ref_rect_to_local(r: Rect2) -> Rect2:
	return Rect2(ref_to_local(r.position), r.size * _scale)

## Same transform in GLOBAL (viewport) coordinates.
func ref_to_global(p: Vector2) -> Vector2:
	return _screen_content.global_position + ref_to_local(p)

func ref_rect_to_global(r: Rect2) -> Rect2:
	return Rect2(ref_to_global(r.position), r.size * _scale)

func get_shell_scale() -> float:
	return _scale

func get_shell_rect() -> Rect2:
	return ref_rect_to_global(Rect2(Vector2.ZERO, Shell.SIZE))

## Actual on-screen rect of the shell TextureRect (must equal get_shell_rect()).
func get_shell_node_rect() -> Rect2:
	return _global_rect(_shell)

func relayout() -> void:
	if not _built or _content == null:
		return
	# Shell selection depends only on authoritative facts, never on layout size.
	_apply_shell_selection()
	var s: Vector2 = _content.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	_layout_mode = ResponsiveLayout.get_layout_mode(get_viewport_rect().size)
	# Safe-area-aware uniform aspect-fit of the 887×1774 master (never stretched).
	_scale = minf(s.x / Shell.SIZE.x, s.y / Shell.SIZE.y)
	_origin = ((s - Shell.SIZE * _scale) * 0.5).floor()
	_place_rect(_shell, Rect2(Vector2.ZERO, Shell.SIZE))
	_place_ref(_bubble_mask, Shell.BUBBLE_TEXT)
	_bubble_mask.add_theme_stylebox_override("panel", HomeStyle.box(Shell.BUBBLE_FILL, Shell.BUBBLE_FILL, 0, int(18.0 * _scale), 0))
	_layout_bubble_text()
	_place_ref(_speech_anchor, SPEECH_ANCHOR)
	_place_ref(_scrubby_anchor, SCRUBBY_ANCHOR)
	_place_ref(_props_anchor, PROPS_ANCHOR)
	_layout_top()
	_layout_board()
	_layout_batch()
	# Button minimums first, THEN the row rect: the row is clamped to its children's
	# minimum, so placing it first would keep a larger previous-size minimum on shrink.
	var bsz: float = maxf(Shell.rect(Shell.BOOSTERS).size.y * _scale, float(UiTokens.TOUCH_MIN))
	_booster_row.add_theme_constant_override("separation", int(28.0 * _scale))
	for b in _booster_row.get_children():
		b.custom_minimum_size = Vector2(bsz, bsz)
		b.add_theme_stylebox_override("normal", HomeStyle.box(Color(0.96, 0.92, 0.84), Color(0.62, 0.72, 0.88), 4, int(bsz / 2), 8, 3))
		for st in ["hover", "pressed", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(st, b.get_theme_stylebox("normal"))
		b.get_node("Badge").add_theme_font_size_override("font_size", int(26.0 * _scale))
		b.get_node("Price").add_theme_font_size_override("font_size", int(20.0 * _scale))
	_place_ref(_booster_row, Shell.BOOSTERS)
	_place_ref(_ad_region, Shell.AD)
	_queue_connector_update()

func _place_rect(c: Control, ref: Rect2) -> void:
	var r := ref_rect_to_local(ref)
	c.position = r.position
	c.size = r.size

func _place_ref(c: Control, ref: Array) -> void:
	_place_rect(c, Shell.rect(ref))

## Place `c` (child of `parent_ref`-placed control) at reference rect `ref`.
func _place_child(c: Control, parent_ref: Array, ref: Array) -> void:
	var p := Shell.rect(parent_ref)
	var r := Shell.rect(ref)
	c.position = (r.position - p.position) * _scale
	c.size = r.size * _scale

func _layout_top() -> void:
	var top := [0, 0, 887, 170]
	_place_ref(_top_region, top)
	_place_child(_profile, top, Shell.PROFILE)
	for pair in [[_profile.get_node("Portrait"), PROFILE_PORTRAIT], [_profile_name, PROFILE_NAME],
			[_profile_level, PROFILE_LEVEL], [_profile_bar, PROFILE_BAR], [_profile_parts, PROFILE_BAR]]:
		_place_child(pair[0], Shell.PROFILE, pair[1])
	_profile_name.add_theme_font_size_override("font_size", int(28.0 * _scale))
	_profile_level.add_theme_font_size_override("font_size", int(22.0 * _scale))
	_profile_parts.add_theme_font_size_override("font_size", int(18.0 * _scale))
	_place_child(_pause_btn, top, Shell.PAUSE)
	_place_child(_speed_btn, top, Shell.SPEED)
	var sb: Vector2 = _speed_btn.size
	_speed_time.position = Vector2(0, sb.y * 0.50)
	_speed_time.size = Vector2(sb.x, sb.y * 0.42)
	_speed_time.add_theme_font_size_override("font_size", int(24.0 * _scale))
	_pause_glyph.queue_redraw()
	_apply_speed_visual()

## Board fitted to the baked rail: the runtime ScrubRailGeometry loop (centrelines 2.5
## cells outside the board) is scaled onto the baked rail centrelines of the shell.
func _layout_board() -> void:
	var rr: Rect2 = ref_rect_to_local(Shell.rail_rect(_geom_id))
	_place_rect(_board_region, Shell.rail_rect(_geom_id))
	if _presentation == null or not is_instance_valid(_presentation) or _board == null:
		return
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	# Square cells onto a baked loop that is not exactly square: take the cell that splits
	# the horizontal/vertical misfit evenly. The renderer draws at an integer cell; the whole
	# BoardPresentation (renderer + agents + rail geometry, one transform) is then scaled by
	# the small fractional remainder so the runtime rail centrelines meet the baked rail.
	# Capped at 3% over the strict fit so a non-square board (not in the current catalog)
	# always stays inside the baked rail; near-square boards keep the even split.
	var exact: float = _board_display_cell(rr, w, h)
	var cell: float = maxf(floor(exact), 1.0)
	_presentation.configure(_board, _palette, Vector2(w * cell, h * cell))
	var render_cell: float = _presentation.get_cell_size()
	_presentation.scale = Vector2.ONE * (exact / render_cell)
	# M32-C002: Scrubbot apparent size is board-resolution independent. The reference is the
	# display cell a 32x32 board gets from this SAME fit in this SAME rail region (presentation
	# only; the board/agent transform above is unchanged).
	var ref_n: int = int(BoardPresentation.SCRUBBOT_REFERENCE_CELLS)
	_presentation.set_scrubbot_reference_display_cell(_board_display_cell(rr, ref_n, ref_n))
	_cell_size = exact
	if _rail_view != null:
		_rail_view.position = Vector2.ZERO
		_rail_view.scale = Vector2(render_cell, render_cell)
		_rail_view.configure(w, h)
	var board_px := Vector2(w, h) * _cell_size
	_presentation.position = (rr.size - board_px) * 0.5

## Display cell size (exact, unfloored) for a w x h board fitted onto the baked rail region.
func _board_display_cell(rr: Rect2, w: int, h: int) -> float:
	var loop := Vector2(w + 2.0 * ScrubRailGeometry.CENTER_OFFSET, h + 2.0 * ScrubRailGeometry.CENTER_OFFSET)
	var fit_x: float = rr.size.x / loop.x
	var fit_y: float = rr.size.y / loop.y
	return maxf(minf((fit_x + fit_y) * 0.5, minf(fit_x, fit_y) * 1.03), 1.0)

func _layout_batch() -> void:
	var slots: Array = Shell.slot_rects(_geom_id)
	var grid: Dictionary = Shell.supply_grid(_geom_id)
	var union: Rect2 = grid["rect"]
	for r in slots:
		union = union.merge(r)
	_place_rect(_batch_region, union)
	var strip_ref: Rect2 = slots[0]
	for r in slots:
		strip_ref = strip_ref.merge(r)
	var strip_local := Rect2((strip_ref.position - union.position) * _scale, strip_ref.size * _scale)
	_five_slot_strip.position = strip_local.position
	_five_slot_strip.size = strip_local.size
	var rects: Array = []
	for r in slots:
		rects.append(Rect2((r.position - strip_ref.position) * _scale, r.size * _scale))
	_five_slot_strip.set_slot_rects(rects)
	var g: Rect2 = grid["rect"]
	_supply_panel.position = (g.position - union.position) * _scale
	_supply_panel.size = g.size * _scale
	_supply_panel.set_shell_grid(Vector2(grid["gap_x"], grid["gap_y"]) * _scale)
	_supply_panel.call_deferred("refresh_hit_areas")   # after the containers sort

# ------------------------------------------------------------------ connectors --

func _queue_connector_update() -> void:
	if is_inside_tree():
		call_deferred("_update_connectors")
	else:
		_update_connectors()

## Runtime connector truth (not drawn — the shell bakes the visible connectors): per
## current slot, [SlotOriginProvider.origin_for_slot(i), ScrubRailGeometry.bottom_entry].
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

func get_connector_segments() -> Array:
	return _connector_segments.duplicate(true)

## Board-local cell units -> global screen point (same transform as agents).
func board_local_to_global(p: Vector2) -> Vector2:
	if _presentation == null or not is_instance_valid(_presentation):
		return Vector2.INF
	return _presentation.get_agent_layer().get_global_transform() * p

# ------------------------------------------------------------------ HUD binding --

func set_profile(data: Dictionary) -> void:
	# M43-C008 (SB-M43-108): active robot portrait + name (presentation only; Scrubby default).
	var rid := String(data.get("robot_id", ""))
	if not rid.is_empty() and _portrait != null and rid != _portrait_robot:
		_portrait_robot = rid
		var r := RobotRoster.entry(rid)
		_portrait.texture = load(PORTRAIT_ART if rid == String(RobotRoster.load_roster()["initial_robot_id"]) else RobotRoster.asset(rid, "profile_portrait")) as Texture2D
		_profile_name.text = String(r.get("name", UiText.t("HOME_PLAYER_NAME_DEFAULT")))
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

func set_speed_presentation(entitlement: String, timed_remaining: int = 0) -> void:
	_speed_entitlement = entitlement
	_speed_remaining = maxi(timed_remaining, 0)
	_apply_speed_visual()

func get_speed_state() -> String:
	return "2x" if _speed_2x else "1x"

func set_speed_2x(value: bool) -> void:
	_speed_2x = value
	_apply_speed_visual()

func get_speed_mode() -> String:
	if _speed_entitlement == "timed" and _speed_remaining > 0:
		return SPEED_TIMED
	if not _speed_2x:
		return SPEED_OFF
	return SPEED_LEVEL if _speed_entitlement == "level" else SPEED_AUTO

func get_speed_label() -> String:
	return _speed_btn.text

static func format_remaining(seconds: int) -> String:
	var s := maxi(seconds, 0)
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%02d:%02d" % [s / 60, s % 60]

## 2x state lives INSIDE the baked box: selected = translucent cyan fill, free automatic
## 2x = translucent green, timed = small "2x" over the live wall-clock countdown.
func _apply_speed_visual() -> void:
	if _speed_btn == null:
		return
	var mode := get_speed_mode()
	var timed := mode == SPEED_TIMED
	_speed_btn.text = format_remaining(_speed_remaining) if timed else "2x"
	_speed_main.text = "2x"
	_speed_time.visible = timed
	_speed_time.text = _speed_btn.text if timed else ""
	if timed:
		_speed_main.anchor_bottom = 0.55
		_speed_main.add_theme_font_size_override("font_size", int(34.0 * _scale))
	else:
		_speed_main.anchor_bottom = 1.0
		_speed_main.add_theme_font_size_override("font_size", int(46.0 * _scale))
	var fill := Color(0, 0, 0, 0)
	if _speed_2x:
		fill = Color(0.45, 1.0, 0.55, 0.30) if mode == SPEED_AUTO else Color(0.25, 0.85, 1.0, 0.34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(16.0 * _scale))
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		_speed_btn.add_theme_stylebox_override(st, sb)
	_speed_main.modulate = Color(1, 1, 1) if (_speed_2x or not timed) else Color(0.80, 0.84, 0.92)

func set_paused(paused: bool) -> void:
	_paused = paused
	if _pause_glyph != null:
		_pause_glyph.queue_redraw()

func is_paused_visual() -> bool:
	return _paused

func set_booster_states(states: Array) -> void:
	for st in states:
		var id := String(st.get("id", ""))
		if not _booster_states.has(id):
			continue
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

func get_pause_button() -> Button:
	return _pause_btn

func get_speed_button() -> Button:
	return _speed_btn

func get_bubble_mask() -> Panel:
	return _bubble_mask

func get_ad_region_rect() -> Rect2:
	return _global_rect(_ad_region)

func _global_rect(c: Control) -> Rect2:
	return Rect2(c.global_position, c.size)

func get_safe_rect() -> Rect2:
	return _global_rect(_content) if _content != null else Rect2()

func get_top_region_rect() -> Rect2:
	return _global_rect(_top_region)

func get_profile_rect() -> Rect2:
	return _global_rect(_profile)

func get_board_region_rect() -> Rect2:
	return _global_rect(_board_region)

func get_board_rect() -> Rect2:
	if _presentation == null or not is_instance_valid(_presentation) or _board == null:
		return Rect2()
	return Rect2(_presentation.global_position, Vector2(_board.get_width(), _board.get_height()) * _cell_size)

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

func has_goal_moves_panel() -> bool:
	return _find_named(self, ["GoalMoves", "GoalPanel", "MovesPanel", "GoalMovesPanel", "TimePanel", "MovesTimePanel"])

func has_level_lock_rail() -> bool:
	return _find_named(self, ["LevelRail", "LockRail", "LevelLockRail"])

## Legacy C001-era bottom Pause/ad/speed row (must stay absent). The owner-reserved
## lower ad region (`AdRegion`) is a different, authorised layout band.
func has_ad_placeholder() -> bool:
	return _find_named(self, ["AdPlaceholder", "BottomActionRow"])

## The reserved ad band exists (layout anchor for M57) ...
func has_ad_region() -> bool:
	return _ad_region != null and _ad_region.visible

## ... but draws nothing until M57 (owner S3-B).
func is_ad_placeholder_visible() -> bool:
	if _ad_region == null:
		return false
	var drawn: bool = not (_ad_region.get_theme_stylebox("panel") is StyleBoxEmpty)
	return drawn or _ad_region.get_children().any(func(c): return c is CanvasItem and c.visible)

func get_bubble_labels() -> Array:
	return [_bubble_headline, _bubble_instruction]

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

func cell_center_to_global(x: int, y: int) -> Vector2:
	if _presentation == null or not is_instance_valid(_presentation):
		return Vector2.INF
	return _presentation.get_renderer().get_cell_center_global(x, y)

func global_to_board_local(p: Vector2) -> Vector2:
	if _presentation == null or not is_instance_valid(_presentation):
		return Vector2.INF
	return _presentation.global_to_board_local(p)
