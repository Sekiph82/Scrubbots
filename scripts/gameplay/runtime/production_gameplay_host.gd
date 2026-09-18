extends Control
## ProductionGameplayHost — M29 production stack host. Preload this script
## (res://scripts/gameplay/runtime/production_gameplay_host.gd); do not rely on global
## class_name (AL-001).
##
## Assembles the ENTIRE accepted production chain around the real M28 GameplayScreen so
## the manual playtest scene AND the headless runtime smoke share one wiring (no fake
## UI, no duplicated harness):
##
##   real LevelData/BoardState
##   -> real M23 BatchSupplyEngine (deterministic M27-proven candidate)
##   -> real M24 FiveSlotBatchEngine
##   -> real M25 BatchTargetClaimEngine + ReservationState/TargetSelector
##   -> real ProductionRoutingSystem/ProductionAccessQuery
##   -> real ScrubbotDispatcher (preclaimed) -> real ScrubbotAgent
##   -> real M20 CompleteClearingLoop authenticated clear
##   -> real M26 AutoDispatchScheduler
##   -> M29 ProductionInputController (supply-front gate) + ProductionRuntimeController
##      (automatic cadence + 1x/2x speed authority + pause/focus).
##
## The screen composes the presentation; the host owns NO target/route/clear logic — it
## only wires the accepted engines together and drives them through the M29 controllers.

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const GameplaySpeedAuthority = preload("res://scripts/gameplay/runtime/gameplay_speed_authority.gd")
const ProductionRuntimeController = preload("res://scripts/gameplay/runtime/production_runtime_controller.gd")
const SlotOriginProvider = preload("res://scripts/gameplay/runtime/slot_origin_provider.gd")
const ProductionInputController = preload("res://scripts/ui/production_input_controller.gd")

const HAZARD_BOT_LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"

@export var level_path: String = HAZARD_BOT_LEVEL
@export var gen_seed: int = 1
@export var column_count: int = 3
@export var preview_depth: int = 3
@export var base_cadence: float = GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL
@export var auto_build: bool = true

var _screen
var _board
var _supply
var _slots
var _res
var _ci
var _sel
var _routing
var _raccess
var _dispatcher
var _loop
var _claim
var _scheduler
var _speed
var _runtime
var _input
var _origin_provider
var _built := false
var _build_error := ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if auto_build and not _built:
		build()

## Build the whole production stack. Returns true on success; on failure returns false
## and leaves get_build_error() set. Idempotent (a second call is a no-op success).
func build() -> bool:
	if _built:
		return true
	var res_load = LevelLoader.load_from_path(level_path)
	if not res_load.is_ok():
		_build_error = "level load failed"
		return false
	var lvl = res_load.level_data
	_board = BoardState.from_level_data(lvl)

	# M23 deterministic candidate (M27-proven for seed 1 / 3 columns / preview 3).
	_supply = BatchSupplyGenerator.generate(lvl, column_count, preview_depth, gen_seed)
	if _supply == null:
		_build_error = "supply generation failed"
		return false
	_slots = FiveSlotBatchEngine.new()

	# Production GameplayScreen composition (M28), configured with detached snapshots.
	_screen = GameplayScreen.new()
	add_child(_screen)
	_screen.configure(_board, lvl.palette, _slots.snapshot(), _supply.player_snapshot())
	var presentation = _screen.get_presentation()
	if presentation == null:
		_build_error = "screen presentation missing"
		return false
	var agent_layer = presentation.get_agent_layer()
	var renderer = presentation.get_renderer()

	# Accepted targeting / routing / dispatch / clearing bundle.
	_res = ReservationState.new(); _res.bind(_board)
	_ci = ColorCandidateIndex.create(); _ci.bind(_board)
	_sel = TargetSelector.create(); _sel.bind(_board, _ci, _res)
	_routing = ProductionRoutingSystem.new()
	_raccess = ProductionAccessQuery.new(_board)
	_dispatcher = ScrubbotDispatcher.new()
	add_child(_dispatcher)
	if not _dispatcher.bind(_board, _sel, _res, _routing, _raccess,
			ProductionTargetAccess.new(_routing, _raccess, _board), agent_layer):
		_build_error = "dispatcher bind failed"
		return false
	_loop = CompleteClearingLoop.new()
	if not _loop.bind_arrival_only(_board, _ci, _res, _dispatcher, renderer):
		_build_error = "clearing loop bind failed"
		return false
	_claim = BatchTargetClaimEngine.new()
	if not _claim.bind(_board, _slots, _sel, _res):
		_build_error = "claim engine bind failed"
		return false

	# M29 runtime: origin provider from the REAL laid-out five-slot strip.
	_origin_provider = SlotOriginProvider.new(presentation, _screen.get_five_slot_strip(), _board)
	_scheduler = AutoDispatchScheduler.new()
	if not _scheduler.bind(_board, _slots, _claim, _res, _routing, _raccess, _dispatcher, _loop, _origin_provider):
		_build_error = "scheduler bind failed"
		return false

	_speed = GameplaySpeedAuthority.new(base_cadence)
	_input = ProductionInputController.new()
	add_child(_input)
	_runtime = ProductionRuntimeController.new()
	add_child(_runtime)
	if not _runtime.bind(_scheduler, _speed, agent_layer, _input):
		_build_error = "runtime bind failed"
		return false
	if not _input.bind(_supply, _slots, _scheduler, _runtime, _screen.get_supply_panel(), _screen):
		_build_error = "input controller bind failed"
		return false

	_wire_controls()
	_built = true
	return true

func _wire_controls() -> void:
	var pause_btn = _screen.get_pause_button()
	if pause_btn != null and not pause_btn.pressed.is_connected(_on_pause_pressed):
		pause_btn.pressed.connect(_on_pause_pressed)
	var speed_btn = _screen.get_speed_button()
	if speed_btn != null and not speed_btn.pressed.is_connected(_on_speed_pressed):
		speed_btn.pressed.connect(_on_speed_pressed)

func _on_pause_pressed() -> void:
	var now: bool = not _runtime.is_user_paused()
	_runtime.set_user_paused(now)
	var pause_btn = _screen.get_pause_button()
	if pause_btn != null:
		pause_btn.text = "▶" if now else "II"

## M29 temporal/debug seam. Economy V1 supersedes free shipping manual 2x:
## M39 must route this production-facing request through SpeedEntitlementService
## (level/timed SB entitlement) before enabling 2x. Keep this direct toggle only as
## pre-M39 playable/audit behavior; authoritative M23-exhausted auto-2x remains free.
func _on_speed_pressed() -> void:
	var two: bool = _runtime.toggle_speed()
	_screen.set_speed_2x(two)

# ---------------------------------------------------------------- accessors ----

func is_built() -> bool:
	return _built

func get_build_error() -> String:
	return _build_error

func get_screen():
	return _screen

func get_board():
	return _board

func get_supply():
	return _supply

func get_slots():
	return _slots

func get_scheduler():
	return _scheduler

func get_runtime():
	return _runtime

func get_input_controller():
	return _input

func get_speed_authority():
	return _speed

func get_clearing_loop():
	return _loop

func get_dispatcher():
	return _dispatcher

func get_claim_engine():
	return _claim

func get_reservations():
	return _res

func get_agent_layer():
	var p = _screen.get_presentation() if _screen != null else null
	return p.get_agent_layer() if p != null else null

func get_origin_provider():
	return _origin_provider
