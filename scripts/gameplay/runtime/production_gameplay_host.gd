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
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const CompletionController = preload("res://scripts/gameplay/completion/completion_controller.gd")
const RetryCoordinator = preload("res://scripts/gameplay/completion/retry_coordinator.gd")
const CleaningEffectsController = preload("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const ScrubbotRetireEchoController = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")
const GameplayAudioController = preload("res://scripts/audio/gameplay_audio_controller.gd")
const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")

const HAZARD_BOT_LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"

@export var level_path: String = HAZARD_BOT_LEVEL
@export var gen_seed: int = 1
@export var column_count: int = 3
@export var preview_depth: int = 3
@export var base_cadence: float = GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL
@export var auto_build: bool = true
## QA/debug-only DEADLOCK fixture seam (M30 manual LOST demo + tests). When > 0, the last N
## batches of the deterministic generated candidate are dropped so total supply robots <
## ACTIVE cells: the board can never fully clear, and once supply is exhausted at quiescence
## the REAL M27 DeadlockClassifier proves DEADLOCK -> owner-visible LOST via the SAME real
## production stack. Default 0 keeps the full solvable production candidate; no production
## path sets this.
@export var qa_supply_drop_last: int = 0

var _screen
var _board
var _level
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
var _evaluator
var _completion
var _cleaning_fx
var _retire_echo
var _audio
var _audio_settings
var _built := false
var _build_error := ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# A plain Control does not auto-size its Control children, so keep the screen matched
	# to this host's rect — including after a responsive viewport/host resize, so the
	# visible slot anchors (and thus the routing origins) track the current layout.
	resized.connect(_fit_screen)
	if auto_build and not _built:
		build()

func _fit_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		# Full-rect anchors + zero offsets make the screen track this host's rect on every
		# layout pass (a plain Control parent does not sort its children like a Container).
		_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
	_level = lvl
	_board = BoardState.from_level_data(lvl)

	# M23 deterministic candidate (M27-proven for seed 1 / 3 columns / preview 3).
	_supply = BatchSupplyGenerator.generate(lvl, column_count, preview_depth, gen_seed)
	if _supply == null:
		_build_error = "supply generation failed"
		return false
	# QA/debug-only DEADLOCK fixture: drop the last N generated batches (see qa_supply_drop_last).
	if qa_supply_drop_last > 0:
		_supply = _make_deadlock_supply(_supply, qa_supply_drop_last, lvl.palette.size())
		if _supply == null:
			_build_error = "qa deadlock supply build failed"
			return false
	_slots = FiveSlotBatchEngine.new()

	# Production GameplayScreen composition (M28), configured with detached snapshots.
	_screen = GameplayScreen.new()
	add_child(_screen)
	_fit_screen()   # size the screen to this host BEFORE configuring so board layout resolves
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
	# M32: inject an agent factory so every dispatched (legacy AND preclaimed) agent is born
	# with one canonical Scrubby ScrubbotVisual child. The factory returns a fresh, unparented,
	# UNASSIGNED ScrubbotAgent exactly as the dispatcher requires; the visual is a
	# presentation-only child that rides the agent transform and owns no gameplay identity, so
	# target/route/clear truth is untouched (M32 audit §3/§9).
	if not _dispatcher.bind(_board, _sel, _res, _routing, _raccess,
			ProductionTargetAccess.new(_routing, _raccess, _board), agent_layer,
			Callable(self, "_make_scrubbot_agent")):
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

	# M30 completion authority: read-only evaluator + terminal controller over the exact
	# live engines. Dirty/event-driven — the expensive real M27 proof runs only at a
	# quiescent boundary the controller marks dirty (placement / authenticated clear).
	_evaluator = CompletionEvaluator.new()
	_completion = CompletionController.new()
	if not _completion.bind(_evaluator, _board, _scheduler, _dispatcher, _claim, _res,
			_slots, _level, _supply):
		_build_error = "completion bind failed"
		return false
	_completion.terminal_reached.connect(_on_terminal_reached)
	# M31 presentation-only cleaning effect: a pure observer on the SAME authoritative
	# committed-clear notification. It never mutates gameplay truth; a bind failure (no FX
	# layer) simply means no cues, never a build/gameplay failure.
	_cleaning_fx = CleaningEffectsController.new()
	add_child(_cleaning_fx)
	_cleaning_fx.bind(presentation.get_cleaning_fx_layer(), _board)
	_loop.authenticated_clear.connect(_cleaning_fx._on_authenticated_clear)

	# M32 presentation-only arrival/disappearance echo: a second pure observer on the SAME
	# authoritative committed-clear notification. It spawns a short detached Scrubby echo at the
	# cleared cell and never mutates gameplay truth or delays the M20 finalize; a bind failure
	# (no retire layer) simply means no echoes, never a build/gameplay failure.
	_retire_echo = ScrubbotRetireEchoController.new()
	add_child(_retire_echo)
	_retire_echo.bind(presentation.get_retire_fx_layer(), _board)
	_loop.authenticated_clear.connect(_retire_echo._on_authenticated_clear)

	# M33 presentation-only audio: user volume settings (persisted) + a bounded-voice SFX
	# controller observing the SAME authoritative events. All three wirings are pure observers
	# — dispatch on committed dispatch, cleaning on authenticated clear, completion on WON
	# only. Audio never mutates gameplay/terminal/speed truth.
	_audio_settings = AudioSettingsService.new()
	_audio_settings.load()  # persisted user volumes -> AudioServer buses (defaults if none)
	_audio = GameplayAudioController.new()
	add_child(_audio)
	_dispatcher.assignment_dispatched.connect(_audio._on_assignment_dispatched)
	_loop.authenticated_clear.connect(_audio._on_authenticated_clear)
	_completion.terminal_reached.connect(_audio._on_terminal_reached)

	# Meaningful gameplay boundaries mark the completion state dirty (authenticated clear +
	# accepted supply-front placement). on_tick (below) then gets one chance to run the M27
	# proof at quiescence; idle ticks with no event never re-run it.
	_loop.authenticated_clear.connect(_on_clear_event)
	_input.activation_result.connect(_on_activation_event)
	# Live five-slot presentation sync AND completion evaluation after every driven tick.
	_runtime.set_state_sync(Callable(self, "_on_runtime_tick"))

	_wire_controls()
	_built = true
	return true

## QA-only: rebuild `engine` minus `drop` batches taken from the DRAIN TAIL — the deepest
## batches of the highest-index non-empty column first (col N back, then col N-1, ...). That
## is exactly the tail of the col0->col1->col2 front-to-back drain the manual/test path uses,
## so every remaining batch clears from a state a proven-solvable prefix already reached
## (no placed batch is stranded), while the dropped tail's cells stay permanently ACTIVE.
## Once that residual supply is exhausted at quiescence the real M27 classifier proves
## DEADLOCK -> owner-visible LOST.
func _make_deadlock_supply(engine, drop: int, palette_size: int):
	var dbg: Dictionary = engine.debug_snapshot()
	var cols: Array = dbg["columns"]
	var remaining := drop
	while remaining > 0:
		var popped := false
		for c in range(cols.size() - 1, -1, -1):
			if cols[c].size() > 0:
				cols[c].remove_at(cols[c].size() - 1)
				remaining -= 1
				popped = true
				break
		if not popped:
			break  # nothing left to drop
	var cols_out: Array = []
	for c in range(cols.size()):
		var q: Array = []
		for bd in cols[c]:
			var batch = ColorBatch.make(String(bd["batch_id"]), int(bd["color_id"]),
				int(bd["robot_count"]), palette_size)
			if batch == null:
				return null
			q.append(batch)
		cols_out.append(q)
	var out = BatchSupplyEngine.create(column_count, preview_depth)
	if out == null or not out.load_candidate(cols_out, gen_seed, palette_size):
		return null
	return out

## M30 transaction-safe same-puzzle Retry (SB-M30-007). The accepted M26 scheduler teardown
## is the FIRST destructive gate: if it fails/defers/pends/is fatal, Retry FAILS CLOSED and
## nothing else is reset (no half-old/half-new attempt). On a proven-clean teardown, restores
## one coherent fresh attempt — same level, same deterministic initial supply, board fully
## ACTIVE, empty slots, zero claims/reservations/agents/committed work, speed 1x, PLAYING,
## input unblocked. Returns true on a fully restored attempt, false on a fail-closed gate.
func retry() -> bool:
	if not _built:
		return false
	return RetryCoordinator.attempt({
		"scheduler": _scheduler,
		"slots": _slots,
		"supply": _supply,
		"board": _board,
		"candidate_index": _ci,
		"runtime": _runtime,
		"input": _input,
		"completion": _completion,
		"clearing_loop": _loop,
		"renderer": _renderer(),
		"on_restored": Callable(self, "_on_retry_restored"),
	})

## Backwards-compatible M29 alias. reset_session() now routes through the hardened
## transaction-safe Retry path (return value ignored by legacy void callers).
func reset_session() -> void:
	retry()

func _renderer():
	var p = _screen.get_presentation() if (_screen != null and is_instance_valid(_screen)) else null
	return p.get_renderer() if p != null else null

## After a successful Retry restore, refresh the live UI (five-slot strip + supply panel) to
## the fresh attempt's initial state.
func _on_retry_restored() -> void:
	if _screen != null and is_instance_valid(_screen) and _slots != null:
		_screen.update_snapshots(_slots.snapshot(), _supply.player_snapshot())
		_screen.set_speed_2x(false)
	# M31 (§10): a successful Retry starts a fresh visual attempt — remove stale cleaning
	# cues and reset the attempt-scoped diagnostic counters. Presentation-only; runs only on
	# the RetryCoordinator's post-success restore seam, so it never weakens the M30 gate.
	if _cleaning_fx != null and is_instance_valid(_cleaning_fx):
		_cleaning_fx.reset_for_new_attempt()
	# M32 (§13): the same Retry restore removes stale disappearance echoes and resets their
	# attempt-scoped counters. Presentation-only; never weakens the M30 gate.
	if _retire_echo != null and is_instance_valid(_retire_echo):
		_retire_echo.reset_for_new_attempt()
	# M33 (§11): re-arm the once-per-attempt completion-audio latch so a later fresh WON can
	# play completion again. Presentation-only; user volume settings are unchanged.
	if _audio != null and is_instance_valid(_audio):
		_audio.reset_for_new_attempt()

## Runtime state-sync tail: refresh the five-slot strip from authoritative M24, then run one
## dirty/event-gated completion evaluation pass.
func _on_runtime_tick() -> void:
	_sync_slots()
	if _completion != null:
		_completion.on_tick()

## Push a fresh detached M24 snapshot into the live five-slot strip (runtime state-sync).
func _sync_slots() -> void:
	if _screen != null and is_instance_valid(_screen) and _slots != null:
		_screen.refresh_slot_snapshot(_slots.snapshot())

func _on_clear_event(_owner_id, _target_index, _color_id, _agent) -> void:
	if _completion != null:
		_completion.notify_event()

func _on_activation_event(_column: int, ok: bool, _error: String) -> void:
	if ok and _completion != null:
		_completion.notify_event()

## Exact-once terminal latch handler: stop new dispatch cadence + travel (distinct terminal
## stop, not a user pause), block new M26 assignments, and block new supply-front input. No
## legitimate in-flight work is discarded — the latch only fires at a quiescent boundary.
func _on_terminal_reached(_status, _detail) -> void:
	if _runtime != null:
		_runtime.set_terminal_stopped(true)
	if _input != null:
		_input.set_terminal_stopped(true)
	if _scheduler != null:
		_scheduler.pause()

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

func get_completion():
	return _completion

func get_completion_evaluator():
	return _evaluator

func get_level():
	return _level

func get_candidate_index():
	return _ci

func get_cleaning_fx():
	return _cleaning_fx

func get_retire_echo():
	return _retire_echo

func get_audio_controller():
	return _audio

func get_audio_settings():
	return _audio_settings

# ------------------------------------------------------------ M32 agent factory ----

## Dispatcher agent factory (M32). Returns a fresh, unparented, UNASSIGNED ScrubbotAgent
## carrying one presentation-only canonical Scrubby ScrubbotVisual child. The visual reads
## only the parent transform and mutates no gameplay truth, so the dispatcher's ownability /
## assignment postconditions (UNASSIGNED, unparented, MOVING-after-assign) are all preserved.
func _make_scrubbot_agent():
	var a = ScrubbotAgent.new()
	var v = ScrubbotVisual.new()
	a.add_child(v)
	return a
