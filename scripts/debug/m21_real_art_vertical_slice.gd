extends Control
## M21-C001 V01 — debug-only real-art vertical-slice scene controller.
## Preload convention (AL-001): this is a debug demonstration, NOT production UI.
##
## Loads the SAME committed real Level Data (m21_level_001_hazard_bot.json),
## displays it through the real single-Image BoardRenderer over the owner-locked
## BG01 gameplay background, and wires the SAME real production gameplay
## collaborators used everywhere else (LevelLoader/LevelData, BoardState,
## BoardRenderer, SlotSystem, ColorCandidateIndex, ReservationState,
## TargetSelector, ProductionAccessQuery/RoutingSystem/TargetAccess,
## ScrubbotDispatcher, CompleteClearingLoop). A manual debug key steps ONE real
## clear so an owner can visually inspect ACTIVE artwork clearing to CLEARED
## transparency (BG01 shows through). The moving Scrubbot is the existing M18
## debug agent marker — NOT final Scrubbot art.
##
## It implements NO production slot UI, NO touch controls, NO win/lose, rewards,
## economy, autoplay, or follow-up dispatch. This is a developer harness.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const BG01 := Color8(32, 37, 51, 255)  # owner-locked gameplay background
const SLOT_ORDER := [2, 0, 1, 3, 4]    # C08 (frame) first, then interior colors

var _background: ColorRect
var _renderer
var _board
var _loop
var _dispatcher
var _slots
var _active_agent = null

func _ready() -> void:
	build()

## Public so the headless smoke can drive it without pumping frames (mirrors the
## M18 debug scene). Idempotent: a second call is a no-op once built.
func build() -> void:
	if _board != null:
		return
	# BG01 background behind the board.
	_background = ColorRect.new()
	_background.color = BG01
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var result = LevelLoader.load_from_path(LEVEL_PATH)
	if not result.is_ok():
		push_error("M21 debug: could not load %s: %s" % [LEVEL_PATH, str(result.errors)])
		return
	var lvl = result.level_data
	_board = BoardState.from_level_data(lvl)

	var reservations = ReservationState.new(); reservations.bind(_board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(_board)
	var selector = TargetSelector.create(); selector.bind(_board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(_board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, _board)
	_dispatcher = ScrubbotDispatcher.new(); add_child(_dispatcher)
	_dispatcher.bind(_board, selector, reservations, routing, routing_access, select_access)

	_renderer = BoardRenderer.new()
	_renderer.configure(_board, lvl.palette, Vector2(720, 720))
	_renderer.position = Vector2(60, 60)
	add_child(_renderer)

	_slots = SlotSystem.new()
	_slots.configure([0, 1, 2, 3, 4], lvl.palette.size())
	_loop = CompleteClearingLoop.new()
	_loop.bind(_board, _slots, candidates, reservations, _dispatcher, _renderer)

## Manual debug step: dispatch ONE real clear through the real production path.
## Owner/dev-driven only; no autoplay. Returns true if a clear was dispatched.
func step_one_clear() -> bool:
	if _loop == null:
		return false
	var origins := [Vector2(-1.5, 10.0), Vector2(21.5, 10.0), Vector2(10.0, -1.5), Vector2(10.0, 21.5)]
	for slot_id in SLOT_ORDER:
		for origin in origins:
			var r = _loop.activate_slot(slot_id, origin, 6.0)
			if r.success:
				_active_agent = r.agent
				return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		step_one_clear()

func _process(delta: float) -> void:
	# Advance the current debug agent along its real route (marker presentation).
	if _active_agent != null and is_instance_valid(_active_agent) and _active_agent.is_moving():
		_active_agent.advance(delta * 6.0)
