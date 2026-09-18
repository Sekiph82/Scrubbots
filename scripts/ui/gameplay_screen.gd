extends Control
## GameplayScreen — M28-C001 V01 production responsive gameplay screen LAYOUT.
## Preload/instantiate scene res://scenes/gameplay/gameplay_screen.tscn (AL-001).
##
## M28 owns presentation composition and responsive geometry ONLY. It composes the
## already-closed M23–M27 gameplay engine's presentation pieces (BoardRenderer via
## BoardPresentation, ScrubRailView on canonical ScrubRailGeometry) plus read-only
## batch presentation (FiveSlotStrip, BatchSupplyPanel) and neutral decoration/HUD
## anchors, and lays them out responsively (SafeAreaRoot + ResponsiveLayout
## COMPACT/NORMAL/TALL) with the board as the dominant, aspect-correct region.
##
## Boundaries (blocking):
##   - NO gameplay input. Production input is supply-front batch selection; M29 wires
##     touch. This screen never revives ColorSelectionPanel.slot_activated as input,
##     never makes the five slots clickable destinations, and wires no clearing loop
##     / dispatch / target selection.
##   - NO UI component owns BoardState/M23/M24/M25/M26/M27 mutable truth. All batch
##     presentation is fed DETACHED scalar snapshots.
##   - NO Goal/Moves panel, NO Level/lock rail.
##   - NO per-cell Control/Node board renderer (single-Image BoardRenderer preserved).
##   - NO AI-generated / cropped / reference-promoted art. Decoration is neutral
##     native placeholders until an explicitly APPROVED asset exists.

const SafeAreaRootScene = preload("res://scenes/components/ui/common/safe_area_root.tscn")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const ScrubRailView = preload("res://scripts/ui/scrub_rail_view.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const FiveSlotStrip = preload("res://scripts/ui/five_slot_strip.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")

const BG01 := Color8(32, 37, 51, 255)   # BG01 Midnight Slate — gameplay background
## Rail envelope pad in logical cells beyond the board on each side, so the
## ScrubRailView (drawn 3 cells outside the board boundary) is never clipped:
## outer rail edge = board boundary + CENTER_OFFSET + RAIL_WIDTH*0.5 = +3.0 cells.
const RAIL_PAD_CELLS := 3.0

# --- bound presentation state (detached; no gameplay truth retained) ---
var _board                       # BoardState (read-only source for renderer/geometry)
var _palette: PackedStringArray
var _palette_colors: Array = []
var _slot_snapshots: Array = []  # detached FiveSlotBatchEngine.snapshot()
var _supply_snapshot: Array = [] # detached BatchSupplyEngine.player_snapshot()

# --- node handles ---
var _background: ColorRect
var _safe_root                   # SafeAreaRoot (Control) instance
var _content: Control            # inner safe Content control
var _screen_content: Control
var _top_region: Control
var _board_region: Control
var _presentation                # BoardPresentation (Node2D)
var _rail_view
var _batch_region: Control
var _speech_anchor: Control
var _scrubby_anchor: Control
var _props_anchor: Control
var _five_slot_strip
var _supply_panel
var _booster_row: HBoxContainer
var _bottom_row: HBoxContainer
var _pause_btn: Button
var _ad_placeholder: PanelContainer
## Bottom-right SPEED control (owner-locked: replaces the old Settings position;
## OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01 / OWNER_GAMEPLAY_SPEED_RULE_V01).
## M28 owns ONLY its placement/sizing/safe-area/1x-2x visual state. It wires NO
## timing/payment behavior. M29 wires the temporal seam; Economy V1 M39 later gates
## production manual 2x through paid entitlement. Automatic M23-supply-exhausted -> 2x
## remains free and consumes authoritative M23 state (never inferred from UI visuals).
## A new session presents 1x.
var _speed_btn: Button
var _speed_2x := false

var _layout_mode: int = ResponsiveLayout.LayoutMode.NORMAL
var _cell_size: float = 1.0
var _built := false

func _ready() -> void:
	if not _built:
		_build_tree()
	resized.connect(relayout)
	relayout()

## Bind a board fixture + palette + detached batch snapshots, then relayout. `board`
## is a BoardState (used read-only for size/pixels). `palette` is the LevelData
## palette. Snapshots are detached scalar arrays; pass [] to leave a region empty.
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

## Test/preview seam: apply synthetic safe-area insets (this viewport's pixels).
func set_synthetic_safe_insets(left: int, top: int, right: int, bottom: int) -> void:
	if _safe_root != null:
		_safe_root.set_synthetic_insets(left, top, right, bottom)

func _build_tree() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_background = ColorRect.new()
	_background.name = "Background"
	_background.color = BG01
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
	# Content (the inner safe rect) is sized by the MarginContainer a layout pass
	# AFTER this Control first gets its own size, so relayout must react to Content's
	# own resize, not only this node's.
	_content.resized.connect(relayout)

	# NOTE: NO Goal/Moves panel and NO Level/lock rail are created (owner-locked
	# M28 composition). TopRegion is an intentionally minimal spacer.
	_top_region = _new_region("TopRegion")
	_board_region = _new_region("BoardRegion")
	_batch_region = _new_region("BatchRegion")

	# --- BatchRegion contents ---
	# Left decoration column: SpeechAnchor above ScrubbyAnchor (Scrubby low-left).
	_speech_anchor = _new_placeholder_anchor("ScrubbySpeechAnchor", Color(0.20, 0.24, 0.30, 0.55))
	_scrubby_anchor = _new_placeholder_anchor("ScrubbyDecorationAnchor", Color(0.16, 0.19, 0.25, 0.65))
	_props_anchor = _new_placeholder_anchor("CleaningPropsAnchor", Color(0.16, 0.19, 0.25, 0.5))
	_batch_region.add_child(_speech_anchor)
	_batch_region.add_child(_scrubby_anchor)
	_batch_region.add_child(_props_anchor)

	_five_slot_strip = FiveSlotStrip.new()
	_five_slot_strip.name = "FiveSlotStrip"
	_batch_region.add_child(_five_slot_strip)

	_supply_panel = BatchSupplyPanel.new()
	_supply_panel.name = "BatchSupplyPanel"
	_batch_region.add_child(_supply_panel)

	# --- Booster row: exactly four compact presentation-only controls ---
	_booster_row = HBoxContainer.new()
	_booster_row.name = "BoosterRow"
	_booster_row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_screen_content.add_child(_booster_row)
	for i in range(4):
		var b := PanelContainer.new()
		b.name = "Booster%d" % i
		b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE  # presentation only; no mechanic
		_booster_row.add_child(b)

	# --- Bottom action row: pause | ad placeholder | settings ---
	_bottom_row = HBoxContainer.new()
	_bottom_row.name = "BottomActionRow"
	_bottom_row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_screen_content.add_child(_bottom_row)
	_pause_btn = _new_action_button("PauseButton", "II")
	_bottom_row.add_child(_pause_btn)
	_ad_placeholder = PanelContainer.new()
	_ad_placeholder.name = "AdPlaceholder"
	_ad_placeholder.custom_minimum_size = Vector2(0, UiTokens.BOTTOM_ACTION_ROW_MIN_HEIGHT)
	_ad_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ad_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ads design-gated (M57)
	var ad_label := Label.new()
	ad_label.text = "AD"
	ad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ad_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ad_placeholder.add_child(ad_label)
	_bottom_row.add_child(_ad_placeholder)
	# Bottom-right SPEED control (not Settings). Presentation-only; no handler wired.
	_speed_btn = _new_action_button("SpeedControl", "1x")
	_bottom_row.add_child(_speed_btn)
	_apply_speed_visual()

func _new_region(node_name: String) -> Control:
	var c := Control.new()
	c.name = node_name
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_content.add_child(c)
	return c

func _new_placeholder_anchor(node_name: String, tint: Color) -> Control:
	# Neutral native placeholder for a later explicitly-APPROVED illustration. No art
	# is bound; it is intentionally empty decoration that shrinks before supply/slots.
	var p := PanelContainer.new()
	p.name = node_name
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint
	sb.set_corner_radius_all(UiTokens.RADIUS_MD)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _new_action_button(node_name: String, glyph: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
	return b

func _build_board_presentation() -> void:
	if _board == null:
		return
	if _presentation != null and is_instance_valid(_presentation):
		_presentation.queue_free()
	_presentation = BoardPresentation.new()
	_presentation.name = "BoardPresentation"
	_board_region.add_child(_presentation)
	# available_size set precisely in relayout() once BoardRegion has real geometry;
	# configure once here so the renderer/agent-layer exist before first layout.
	_presentation.configure(_board, _palette, Vector2(_board.get_width(), _board.get_height()))
	# ScrubRailView: canonical ScrubRailGeometry, same board-local transform as the
	# agents, drawn just under AgentLayer. Created here so it exists after configure;
	# its scale/position are finalized per-layout in _layout_board().
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

## Recompute all responsive band rects from the current inner safe Content rect.
func relayout() -> void:
	if not _built or _content == null:
		return
	# Content already sits inside SafeAreaRoot's MarginContainer, so its rect IS the
	# safe rect. ScreenContent fills it; band math is in ScreenContent-local space.
	var s: Vector2 = _content.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	_layout_mode = ResponsiveLayout.get_layout_mode(get_viewport_rect().size)

	var gap: float = float(UiTokens.SPACE_MD)
	var top_h: float = float(UiTokens.SPACE_LG)          # minimal; no HUD content
	var bottom_h: float = float(UiTokens.BOTTOM_ACTION_ROW_MIN_HEIGHT)
	var booster_h: float = float(UiTokens.BOOSTER_ROW_MIN_HEIGHT)
	# Protected batch region: never below its usable minimum.
	var batch_h: float = maxf(float(UiTokens.BATCH_REGION_MIN_HEIGHT), s.y * 0.28)
	var fixed: float = top_h + batch_h + booster_h + bottom_h + gap * 4.0
	var board_h: float = s.y - fixed
	# Board must stay dominant: if a short viewport squeezes it under the batch
	# region, reclaim height from the batch region down to its protected minimum.
	if board_h < batch_h:
		var need: float = batch_h - board_h
		var slack: float = batch_h - float(UiTokens.BATCH_REGION_MIN_HEIGHT)
		var give: float = minf(need, maxf(0.0, slack))
		batch_h -= give
		board_h = s.y - (top_h + batch_h + booster_h + bottom_h + gap * 4.0)
	board_h = maxf(board_h, 1.0)

	var y: float = 0.0
	_place(_top_region, 0.0, y, s.x, top_h); y += top_h + gap
	_place(_board_region, 0.0, y, s.x, board_h); y += board_h + gap
	_place(_batch_region, 0.0, y, s.x, batch_h); y += batch_h + gap
	_place(_booster_row, 0.0, y, s.x, booster_h); y += booster_h + gap
	_place(_bottom_row, 0.0, y, s.x, bottom_h)

	_layout_batch_region(Vector2(s.x, batch_h))
	_layout_board()

func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)

func _layout_batch_region(region: Vector2) -> void:
	# Top sub-band: five-slot status strip (full width). Lower sub-band: [Scrubby
	# decoration + speech | protected supply | cleaning props].
	var strip_h: float = float(UiTokens.FIVE_SLOT_STRIP_MIN_HEIGHT)
	var gap: float = float(UiTokens.SPACE_SM)
	_place(_five_slot_strip, 0.0, 0.0, region.x, strip_h)
	var lower_y: float = strip_h + gap
	var lower_h: float = maxf(region.y - lower_y, 1.0)

	# Supply keeps its protected minimum width; decoration/props share the rest and
	# shrink first. Scrubby anchored low-left, props right.
	var supply_w: float = maxf(float(UiTokens.SUPPLY_PANEL_MIN_WIDTH), region.x * 0.5)
	var side_total: float = maxf(region.x - supply_w - gap * 2.0, 0.0)
	var scrubby_w: float = side_total * 0.55
	var props_w: float = side_total - scrubby_w
	var supply_x: float = scrubby_w + gap

	# Left decoration column (in batch-region-local coords).
	var speech_h: float = lower_h * 0.42
	var scrubby_h: float = lower_h - speech_h - gap
	_place(_speech_anchor, 0.0, lower_y, scrubby_w, speech_h)
	_place(_scrubby_anchor, 0.0, lower_y + speech_h + gap, scrubby_w, scrubby_h)  # low-left
	_place(_supply_panel, supply_x, lower_y, supply_w, lower_h)
	_place(_props_anchor, supply_x + supply_w + gap, lower_y, props_w, lower_h)

func _layout_board() -> void:
	if _presentation == null or not is_instance_valid(_presentation) or _board == null:
		return
	var region: Vector2 = _board_region.size
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	# Fit board+rail envelope (board + RAIL_PAD_CELLS on each side) inside the region,
	# preserving the board's true aspect (never stretched to square). Integer cell.
	var env_w: float = float(w) + 2.0 * RAIL_PAD_CELLS
	var env_h: float = float(h) + 2.0 * RAIL_PAD_CELLS
	var fit: float = min(region.x / env_w, region.y / env_h)
	_cell_size = max(floor(fit), 1.0)
	# Configure the renderer to reproduce exactly this cell size.
	_presentation.configure(_board, _palette, Vector2(w * _cell_size, h * _cell_size))
	_cell_size = _presentation.get_cell_size()

	# Rail view already exists (built in _build_board_presentation); finalize its
	# per-layout transform so it aligns exactly with the rendered board cell size.
	if _rail_view != null:
		_rail_view.position = Vector2.ZERO
		_rail_view.scale = Vector2(_cell_size, _cell_size)
		_rail_view.configure(w, h)

	# Center the board+rail envelope within the region; board origin is offset by the
	# rail pad so the rail loop stays inside the region (no clipping).
	var env_px: Vector2 = Vector2(env_w * _cell_size, env_h * _cell_size)
	var board_origin := Vector2(
		(region.x - env_px.x) * 0.5 + RAIL_PAD_CELLS * _cell_size,
		(region.y - env_px.y) * 0.5 + RAIL_PAD_CELLS * _cell_size)
	_presentation.position = board_origin

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

## M29 wiring seams: the bottom-row Pause and Speed controls (presentation Buttons).
## M28 wires no behavior; M29 connects the temporal seam. Economy V1 M39 gates shipping manual 2x entitlement/payment.
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

func get_bottom_row_rect() -> Rect2:
	return _global_rect(_bottom_row)

func get_pause_rect() -> Rect2:
	return _global_rect(_pause_btn)

func get_ad_placeholder_rect() -> Rect2:
	return _global_rect(_ad_placeholder)

func get_speed_control_rect() -> Rect2:
	return _global_rect(_speed_btn)

## Current presented gameplay speed state: "1x" or "2x". A new session presents 1x.
func get_speed_state() -> String:
	return "2x" if _speed_2x else "1x"

## Presentation-only: set the displayed speed state (distinct/readable 1x vs 2x). Does
## NOT change any timing/gameplay truth; M28 never activates the transition itself.
func set_speed_2x(value: bool) -> void:
	_speed_2x = value
	_apply_speed_visual()

func _apply_speed_visual() -> void:
	if _speed_btn == null:
		return
	_speed_btn.text = "2x" if _speed_2x else "1x"
	# Distinct state visual so 1x and 2x are readable at a glance.
	_speed_btn.modulate = Color(0.20, 0.85, 0.95, 1.0) if _speed_2x else Color(1, 1, 1, 1)

## True iff a Goal/Moves panel exists anywhere in the tree (must be false).
func has_goal_moves_panel() -> bool:
	return _find_named(self, ["GoalMoves", "GoalPanel", "MovesPanel", "GoalMovesPanel"])

## True iff a Level/lock rail exists anywhere in the tree (must be false).
func has_level_lock_rail() -> bool:
	return _find_named(self, ["LevelRail", "LockRail", "LevelLockRail"])

func _find_named(node: Node, names: Array) -> bool:
	if names.has(node.name):
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
