extends Control
## M21-C001 V05 — owner-playable real-art vertical-slice scene controller.
## Preload convention (AL-001). Developer/owner-playtest harness, NOT production UI.
##
## Loads the committed real Level Data (m21_level_001_hazard_bot.json), renders it
## through the real single-Image BoardRenderer over owner-locked BG01, and wires the
## SAME real production gameplay collaborators (LevelLoader/LevelData, BoardState,
## BoardRenderer, SlotSystem, ColorCandidateIndex, ReservationState, TargetSelector,
## ProductionAccessQuery/RoutingSystem/TargetAccess, ScrubbotDispatcher,
## ScrubbotAgent, CompleteClearingLoop).
##
## V05 owner-playtest corrections (frozen findings F-M21-V04-001..004):
##  - F-001: the controller NEVER advances a real ScrubbotAgent. Each agent moves
##    itself via its own _process(delta) -> advance(delta). The controller observes
##    lifecycle only (_reconcile), so there is exactly one movement driver.
##  - F-002: each visible slot's Scrubbot spawn origin is derived from the SlotView's
##    real laid-out anchor, mapped through BoardPresentation/AgentLayer inverse into
##    board-local units — no hardcoded left-edge constant.
##  - F-003: active/in-flight UI is tracked PER real assignment (owner_id -> slot),
##    so multiple concurrent assignments (same or different slots) are represented
##    correctly; a slot is active iff it has >=1 in-flight assignment.
##
## No production win/lose, scoring, economy, progression, booster art, touch/M24, or
## final Scrubbot character art. TargetSelector uses the owner-locked
## bottom-most/left-most reachable priority (unchanged in V05).

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
const FALLBACK_START := Vector2(-1.5, 10.0)

var _background: ColorRect
var _presentation           # BoardPresentation
var _renderer               # BoardRenderer (from presentation)
var _agent_layer: Node2D    # AgentLayer (dispatcher agent_parent)
var _board
var _loop
var _dispatcher
var _slots
var _slot_views: Array = []
var _lvl
## Per-assignment presentation bookkeeping: owner_id -> {slot=int, agent=Object}.
## Concurrency-correct: a slot is active iff it has >=1 still-in-flight assignment.
var _assignments: Dictionary = {}
var _last_result = null      # last DispatchResult from a visible activation (tests)

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
		push_error("M21 V05 debug: could not load %s: %s" % [LEVEL_PATH, str(result.errors)])
		return
	_lvl = result.level_data
	_board = BoardState.from_level_data(_lvl)

	var reservations = ReservationState.new(); reservations.bind(_board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(_board)
	var selector = TargetSelector.create(); selector.bind(_board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(_board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, _board)

	_presentation = BoardPresentation.new()
	_presentation.position = BOARD_ORIGIN
	add_child(_presentation)
	_presentation.configure(_board, _lvl.palette, BOARD_DISPLAY)
	_renderer = _presentation.get_renderer()
	_agent_layer = _presentation.get_agent_layer()

	_dispatcher = ScrubbotDispatcher.new()
	add_child(_dispatcher)
	# AgentLayer as agent_parent so spawned agents inherit the visible transform.
	_dispatcher.bind(_board, selector, reservations, routing, routing_access, select_access, _agent_layer)

	_slots = SlotSystem.new()
	_slots.configure([0, 1, 2, 3, 4], _lvl.palette.size())
	_loop = CompleteClearingLoop.new()
	_loop.bind(_board, _slots, candidates, reservations, _dispatcher, _renderer)

	_build_slot_bar()

func _build_slot_bar() -> void:
	var parse = PaletteColors.parse(_lvl.palette)
	var bar = HBoxContainer.new()
	bar.name = "SlotBar"
	bar.position = Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + BOARD_DISPLAY.y + 40.0)
	bar.add_theme_constant_override("separation", 20)
	add_child(bar)
	_slot_views.clear()
	for slot_id in range(_slots.get_slot_count()):
		var pid: int = _slots.get_slot_palette_id(slot_id)
		var col: Color = parse.colors[pid] if pid >= 0 and pid < parse.colors.size() else Color(1, 0, 1, 1)
		var view = SlotView.new()
		view.setup(slot_id, col)
		view.slot_activated.connect(_on_slot_activated)
		bar.add_child(view)
		_slot_views.append(view)

## Board-local Scrubbot spawn origin for a visible slot, derived from the SlotView's
## real laid-out global anchor through the AgentLayer inverse transform (F-002).
func spawn_start_for(slot_id: int) -> Vector2:
	if _presentation != null and slot_id >= 0 and slot_id < _slot_views.size():
		var anchor: Vector2 = _slot_views[slot_id].get_spawn_anchor_global()
		return _presentation.global_to_board_local(anchor)
	return FALLBACK_START

func _on_slot_activated(slot_id: int) -> void:
	_last_result = request_slot(slot_id)

## Route one visible slot activation through the REAL CompleteClearingLoop path from
## the slot's mapped board-local anchor. No direct board mutation / target forcing /
## fake agent / reservation bypass. Returns the DispatchResult.
func request_slot(slot_id: int) -> RefCounted:
	if _loop == null or slot_id < 0 or slot_id >= _slot_views.size():
		return null
	var start: Vector2 = spawn_start_for(slot_id)
	var r = _loop.activate_slot(slot_id, start, 6.0)
	if r != null and r.success:
		_assignments[r.owner_id] = {"slot": slot_id, "agent": r.agent}
		_reconcile()
	return r

## Derive each slot's active visual from its still-in-flight assignment set. Pure
## observation — never advances agents, never clears cells. Safe against freed
## agents. (F-001 single-mover, F-003 per-assignment concurrency.)
func _reconcile() -> void:
	var active_slots: Dictionary = {}
	for owner in _assignments.keys():
		var e = _assignments[owner]
		var ag = e["agent"]
		if ag != null and is_instance_valid(ag) and ag.is_moving():
			active_slots[int(e["slot"])] = true
		else:
			_assignments.erase(owner)
	for i in range(_slot_views.size()):
		_slot_views[i].set_active_visual(active_slots.has(i))

## Count of currently-tracked in-flight assignments for a slot (test accessor).
func active_count_for_slot(slot_id: int) -> int:
	var n := 0
	for owner in _assignments.keys():
		if int(_assignments[owner]["slot"]) == slot_id:
			var ag = _assignments[owner]["agent"]
			if ag != null and is_instance_valid(ag) and ag.is_moving():
				n += 1
	return n

## Clear presentation bookkeeping + reset the gameplay loop. Leaves no active visual.
func reset_presentation() -> void:
	_assignments.clear()
	for v in _slot_views:
		v.set_active_visual(false)
	if _loop != null:
		_loop.reset()

## Observation only — NEVER advances a real agent (F-001). Each ScrubbotAgent moves
## itself through its own _process. The controller just reconciles slot visuals.
func _process(_delta: float) -> void:
	if not _assignments.is_empty():
		_reconcile()

# --- test accessors (presentation-only; no gameplay authority) ---
func get_presentation():
	return _presentation

func get_agent_layer() -> Node2D:
	return _agent_layer

func get_slot_views() -> Array:
	return _slot_views
