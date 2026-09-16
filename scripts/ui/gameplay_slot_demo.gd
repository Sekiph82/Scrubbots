extends Control
## GameplaySlotDemo — preload/instantiate this scene
## (res://scenes/demo/m22_slot_demo.tscn); AL-001 preload convention.
##
## M22-C001 V01 narrow PRODUCTION integration/demo harness. It proves the reusable
## production ColorSelectionPanel can drive the ALREADY-ACCEPTED M21 gameplay chain:
##
##   visible slot click -> CompleteClearingLoop -> TargetSelector ->
##   ProductionRoutingSystem -> ScrubbotDispatcher -> ScrubbotAgent ->
##   authenticated arrival -> clear
##
## It is NOT the final M23 gameplay screen and NOT a rename of the M21 debug scene.
## It reuses the exact same accepted production collaborators (same preloaded
## classes M21 uses) so it introduces no new gameplay truth. Gameplay authority
## stays entirely in those collaborators; this controller only:
##   - builds the real board + collaborators from the committed real level,
##   - hosts the production ColorSelectionPanel,
##   - maps each clicked slot's real laid-out anchor into board-local route space,
##   - routes the activation through the real CompleteClearingLoop,
##   - reconciles presentation-only active/in-flight visuals from in-flight truth.
##
## No SPACE / keyboard gameplay path. No target forcing, board mutation, fake
## agent, or reservation bypass. TargetSelector keeps the owner-locked
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
const ColorSelectionPanel = preload("res://scripts/ui/color_selection_panel.gd")
const ScrubRailView = preload("res://scripts/ui/scrub_rail_view.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const BG01 := Color8(32, 37, 51, 255)
const BOARD_ORIGIN := Vector2(60.0, 120.0)
const BOARD_DISPLAY := Vector2(720.0, 720.0)
const FALLBACK_START := Vector2(-1.5, 10.0)

var _background: ColorRect
var _presentation           # BoardPresentation
var _renderer               # BoardRenderer
var _agent_layer: Node2D    # AgentLayer (dispatcher agent_parent)
var _board
var _loop
var _dispatcher
var _slots
var _panel                  # ColorSelectionPanel
var _rail_view              # ScrubRailView (Railroad V1 presentation)
var _lvl
## Per-assignment presentation bookkeeping: owner_id -> {slot=int, agent=Object}.
## A slot is active iff it has >=1 still-in-flight assignment (concurrency-correct).
var _assignments: Dictionary = {}
var _last_result = null      # last DispatchResult from a visible activation (tests)

func _ready() -> void:
	build()

## Public + idempotent so a headless smoke can drive it without pumping frames.
func build() -> void:
	if _board != null:
		return
	_background = ColorRect.new()
	_background.color = BG01
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var result = LevelLoader.load_from_path(LEVEL_PATH)
	if not result.is_ok():
		push_error("M22 slot demo: could not load %s: %s" % [LEVEL_PATH, str(result.errors)])
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

	# Railroad V1 presentation: same board-local transform as the agents, inserted
	# just under the AgentLayer so Scrubbots draw on top of the rail. Consumes the
	# single-source ScrubRailGeometry via the board W/H.
	_rail_view = ScrubRailView.new()
	_presentation.add_child(_rail_view)
	_presentation.move_child(_rail_view, _agent_layer.get_index())
	_rail_view.position = Vector2.ZERO
	var cs: float = _presentation.get_cell_size()
	_rail_view.scale = Vector2(cs, cs)
	_rail_view.configure(_board.get_width(), _board.get_height())

	_dispatcher = ScrubbotDispatcher.new()
	add_child(_dispatcher)
	_dispatcher.bind(_board, selector, reservations, routing, routing_access, select_access, _agent_layer)

	_slots = SlotSystem.new()
	_slots.configure([0, 1, 2, 3, 4], _lvl.palette.size())
	_loop = CompleteClearingLoop.new()
	_loop.bind(_board, _slots, candidates, reservations, _dispatcher, _renderer)

	_build_panel()

## Instantiate the reusable production panel and bind it to the REAL SlotSystem
## palette mapping via a scalar Color snapshot (no gameplay reference leaks into
## the panel). Positioned below the board — container-driven internally.
func _build_panel() -> void:
	var parse = PaletteColors.parse(_lvl.palette)
	var colors: Array = []
	for slot_id in range(_slots.get_slot_count()):
		var pid: int = _slots.get_slot_palette_id(slot_id)
		colors.append(parse.colors[pid] if pid >= 0 and pid < parse.colors.size() else Color(1, 0, 1, 1))
	_panel = ColorSelectionPanel.new()
	_panel.name = "ColorSelectionPanel"
	# Slots sit BELOW the bottom rail, never inside the 2-cell artwork clearance
	# (owner §4 / criteria M22-V02-065). Bottom-rail outer edge is board-local
	# y = H + (CENTER_OFFSET + RAIL_WIDTH*0.5) = H + 3; place the panel one cell
	# below that. Mapped board-local anchor y therefore exceeds the rail, so the
	# slot start is a genuine below-board railroad start.
	var cs: float = _presentation.get_cell_size()
	var rail_outer_local: float = float(_board.get_height()) + ScrubRailGeometry.CENTER_OFFSET + ScrubRailGeometry.RAIL_WIDTH * 0.5
	var panel_y: float = BOARD_ORIGIN.y + (rail_outer_local + 1.0) * cs
	_panel.position = Vector2(BOARD_ORIGIN.x, panel_y)
	add_child(_panel)
	_panel.bind_colors(colors)
	_panel.slot_activated.connect(_on_slot_activated)

## Board-local Scrubbot spawn origin for a visible slot, derived from the panel
## cell's real laid-out global anchor through the shared AgentLayer inverse.
func spawn_start_for(slot_id: int) -> Vector2:
	if _presentation != null and _panel != null and slot_id >= 0 and slot_id < _panel.get_slot_count():
		var anchor: Vector2 = _panel.get_spawn_anchor_global(slot_id)
		return _presentation.global_to_board_local(anchor)
	return FALLBACK_START

func _on_slot_activated(slot_id: int) -> void:
	_last_result = request_slot(slot_id)

## Route one visible slot activation through the REAL CompleteClearingLoop from the
## slot's mapped board-local anchor. No board mutation / target forcing / fake
## agent / reservation bypass. Returns the DispatchResult.
func request_slot(slot_id: int) -> RefCounted:
	if _loop == null or _panel == null or slot_id < 0 or slot_id >= _panel.get_slot_count():
		return null
	var start: Vector2 = spawn_start_for(slot_id)
	var r = _loop.activate_slot(slot_id, start, 6.0)
	if r != null and r.success:
		_assignments[r.owner_id] = {"slot": slot_id, "agent": r.agent}
		_reconcile()
	return r

## Derive each slot's active visual from its still-in-flight assignment set. Pure
## observation — never advances agents, never clears cells. Safe against freed
## agents. Presentation-only (no gameplay authority).
func _reconcile() -> void:
	var active_slots: Dictionary = {}
	for owner in _assignments.keys():
		var e = _assignments[owner]
		var ag = e["agent"]
		if ag != null and is_instance_valid(ag) and ag.is_moving():
			active_slots[int(e["slot"])] = true
		else:
			_assignments.erase(owner)
	for i in range(_panel.get_slot_count()):
		_panel.set_slot_active(i, active_slots.has(i))

## Count of currently-tracked in-flight assignments for a slot (test accessor).
func active_count_for_slot(slot_id: int) -> int:
	var n := 0
	for owner in _assignments.keys():
		if int(_assignments[owner]["slot"]) == slot_id:
			var ag = _assignments[owner]["agent"]
			if ag != null and is_instance_valid(ag) and ag.is_moving():
				n += 1
	return n

## Clear presentation bookkeeping + reset the gameplay loop. Leaves no active
## visual. Does not change accepted M21 reset gameplay semantics.
func reset_presentation() -> void:
	_assignments.clear()
	if _panel != null:
		_panel.reset_active_visuals()
	if _loop != null:
		_loop.reset()

## Observation only — NEVER advances a real agent. Each ScrubbotAgent moves itself
## through its own _process. The controller just reconciles slot visuals.
func _process(_delta: float) -> void:
	if not _assignments.is_empty():
		_reconcile()

# --- test accessors (presentation-only; no gameplay authority) ---
func get_presentation():
	return _presentation

func get_agent_layer() -> Node2D:
	return _agent_layer

func get_panel():
	return _panel

func get_rail_view():
	return _rail_view
