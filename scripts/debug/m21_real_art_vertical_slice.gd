extends Control
## M21-C001 V04 — owner-playable real-art vertical-slice scene controller.
## Preload convention (AL-001). This is a developer/owner-playtest harness, NOT
## final production UI.
##
## Loads the committed real Level Data (m21_level_001_hazard_bot.json), displays it
## through the real single-Image BoardRenderer over owner-locked BG01, and wires the
## SAME real production gameplay collaborators (LevelLoader/LevelData, BoardState,
## BoardRenderer, SlotSystem, ColorCandidateIndex, ReservationState, TargetSelector,
## ProductionAccessQuery/RoutingSystem/TargetAccess, ScrubbotDispatcher,
## ScrubbotAgent, CompleteClearingLoop).
##
## V04 additions (owner playtest decisions):
##  - a shared BoardPresentation transform so the real ScrubbotAgent is visibly
##    aligned with the board (AgentLayer = dispatcher agent_parent);
##  - exactly five visible SlotView components bound to real SlotSystem colors;
##  - clicking a slot routes through the real CompleteClearingLoop path (no debug
##    shortcut), with a per-slot coherent board-local Scrubbot spawn origin.
##
## No production win/lose, scoring, economy, progression, booster art, touch/M24, or
## final Scrubbot character art. TargetSelector now uses the owner-locked
## bottom-most/left-most reachable priority.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")
const SlotView = preload("res://scripts/ui/slot_view.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const BG01 := Color8(32, 37, 51, 255)
const BOARD_ORIGIN := Vector2(60.0, 120.0)
const BOARD_DISPLAY := Vector2(720.0, 720.0)
const SLOT_ORDER := [2, 0, 1, 3, 4]  # C08 (frame) first for the SPACE fallback

var _background: ColorRect
var _presentation           # BoardPresentation
var _renderer               # BoardRenderer (from presentation)
var _agent_layer: Node2D    # AgentLayer (dispatcher agent_parent)
var _board
var _loop
var _dispatcher
var _slots
var _slot_views: Array = []
var _slot_origins: Array = []   # board-local spawn origin per slot id
var _active_agent = null
var _active_slot: int = -1
var _lvl

func _ready() -> void:
	build()

## Public + idempotent so the headless smoke can drive it without pumping frames.
func build() -> void:
	if _board != null:
		return
	_background = ColorRect.new()
	_background.color = BG01
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var result = LevelLoader.load_from_path(LEVEL_PATH)
	if not result.is_ok():
		push_error("M21 V04 debug: could not load %s: %s" % [LEVEL_PATH, str(result.errors)])
		return
	_lvl = result.level_data
	_board = BoardState.from_level_data(_lvl)
	var h: int = _board.get_height()

	var reservations = ReservationState.new(); reservations.bind(_board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(_board)
	var selector = TargetSelector.create(); selector.bind(_board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(_board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, _board)

	# Shared board/agent presentation transform (F-M21-OWNER-PLAYTEST-002).
	_presentation = BoardPresentation.new()
	_presentation.position = BOARD_ORIGIN
	add_child(_presentation)
	_presentation.configure(_board, _lvl.palette, BOARD_DISPLAY)
	_renderer = _presentation.get_renderer()
	_agent_layer = _presentation.get_agent_layer()

	_dispatcher = ScrubbotDispatcher.new()
	add_child(_dispatcher)
	# Bind the dispatcher with the AgentLayer as agent_parent so spawned agents
	# inherit the visible board transform (no unscaled root-space dot).
	_dispatcher.bind(_board, selector, reservations, routing, routing_access, select_access, _agent_layer)

	_slots = SlotSystem.new()
	_slots.configure([0, 1, 2, 3, 4], _lvl.palette.size())
	_loop = CompleteClearingLoop.new()
	_loop.bind(_board, _slots, candidates, reservations, _dispatcher, _renderer)

	_build_slot_bar(h)

func _build_slot_bar(h: int) -> void:
	var parse = PaletteColors.parse(_lvl.palette)
	var bar = HBoxContainer.new()
	bar.name = "SlotBar"
	bar.position = Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + BOARD_DISPLAY.y + 40.0)
	bar.add_theme_constant_override("separation", 20)
	add_child(bar)
	_slot_views.clear()
	_slot_origins.clear()
	for slot_id in range(_slots.get_slot_count()):
		var pid: int = _slots.get_slot_palette_id(slot_id)
		var col: Color = parse.colors[pid] if pid >= 0 and pid < parse.colors.size() else Color(1, 0, 1, 1)
		var view = SlotView.new()
		view.setup(slot_id, col)
		view.slot_activated.connect(_on_slot_activated)
		bar.add_child(view)
		_slot_views.append(view)
		# Coherent per-slot board-local spawn origin just off the left edge, one per
		# slot row band. Routing supports exterior origins.
		var oy: float = (float(slot_id) + 0.5) * float(h) / float(_slots.get_slot_count())
		_slot_origins.append(Vector2(-1.5, oy))

func _on_slot_activated(slot_id: int) -> void:
	request_slot(slot_id)

## Route one slot activation through the REAL CompleteClearingLoop path and return
## the DispatchResult. No direct board mutation / target forcing / fake agent.
func request_slot(slot_id: int) -> RefCounted:
	if _loop == null or slot_id < 0 or slot_id >= _slot_origins.size():
		return null
	var r = _loop.activate_slot(slot_id, _slot_origins[slot_id], 6.0)
	if r != null and r.success:
		_active_agent = r.agent
		_active_slot = slot_id
		if slot_id < _slot_views.size():
			_slot_views[slot_id].set_active_visual(true)
	return r

## Developer SPACE fallback: try slots in C08-first order from off-board origins.
func step_one_clear() -> bool:
	if _loop == null:
		return false
	var origins := [Vector2(-1.5, 10.0), Vector2(21.5, 10.0), Vector2(10.0, -1.5), Vector2(10.0, 21.5)]
	for slot_id in SLOT_ORDER:
		for origin in origins:
			var r = _loop.activate_slot(slot_id, origin, 6.0)
			if r.success:
				_active_agent = r.agent
				_active_slot = slot_id
				return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		step_one_clear()

func _process(delta: float) -> void:
	if _active_agent != null and is_instance_valid(_active_agent) and _active_agent.is_moving():
		_active_agent.advance(delta * 6.0)
	elif _active_slot != -1 and (_active_agent == null or not is_instance_valid(_active_agent) or not _active_agent.is_moving()):
		# Assignment finished/failed: resolve the slot's active highlight.
		if _active_slot < _slot_views.size():
			_slot_views[_active_slot].set_active_visual(false)
		_active_slot = -1
		_active_agent = null

# --- test accessors (presentation-only; no gameplay authority) ---
func get_presentation():
	return _presentation

func get_agent_layer() -> Node2D:
	return _agent_layer

func get_slot_views() -> Array:
	return _slot_views

func get_slot_origin(slot_id: int) -> Vector2:
	return _slot_origins[slot_id] if slot_id >= 0 and slot_id < _slot_origins.size() else Vector2.ZERO
