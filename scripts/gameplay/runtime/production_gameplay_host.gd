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
const MusicController = preload("res://scripts/audio/music_controller.gd")
const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsController = preload("res://scripts/haptics/haptics_controller.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const TerminalRewardReceipt = preload("res://scripts/economy/terminal_reward_receipt.gd")
const ProductionActionFacade = preload("res://scripts/economy/production_action_facade.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const BoosterService = preload("res://scripts/economy/booster_service.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const ProductionBoosterAdapter = preload("res://scripts/economy/production_booster_adapter.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const SpeedAcquisitionPopup = preload("res://scripts/ui/speed_acquisition_popup.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const AcquisitionFlow = preload("res://scripts/ui/popup/acquisition_flow.gd")
const ShopHandoff = preload("res://scripts/app/shop_handoff.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")
const FailureAssistanceService = preload("res://scripts/economy/failure_assistance_service.gd")

const HAZARD_BOT_LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"

@export var level_path: String = HAZARD_BOT_LEVEL
@export var gen_seed: int = 1
@export var column_count: int = 3
@export var preview_depth: int = 3
## M52-C001 owner supply plan. Empty => M23 generator candidate (gen_seed/column_count/
## preview_depth). Non-empty => the exact plan queues via SupplyPlanLoader; a missing or
## malformed plan fails the build closed (no generated fallback). In the AppState path
## this is set from the resolved catalog entry.
@export var supply_plan_path: String = ""
@export var base_cadence: float = GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL
@export var auto_build: bool = true
## Campaign progression level number this host instance represents (M39 V02).
## Drives first-clear class/reward and the current-level 2x entitlement gate.
@export var progression_level: int = 1
## M40 V02 canonical save path. Empty (default) => no disk save lifecycle (tests
## and the regression suite are unaffected). A real app/bootstrap sets this to a
## user:// path; the host then loads it BEFORE gameplay consumes economy/
## progression/settings, and saves at the terminal lifecycle boundary.
@export var save_path: String = ""
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
var _music
var _haptics
var _haptics_settings
## M39 V02 Economy V1 runtime composition (fail-safe: economy never blocks
## gameplay). Present when the config loads; null otherwise.
var _economy
## M55-C001: true only for the legacy no-AppState path, where this host built its own
## private EconomyServices graph and must dispose it (breaks its handler cycle).
var _owns_economy := false
var _progression
var _booster_service
var _attempt_boosters := 0
var _booster_adapter
var _save
## M40 V03: optional injected AppState composition root. When set, the host
## consumes its canonical audio/haptics/progression/economy/save graph instead
## of building duplicates. Tests inject an isolated instance; production
## bootstrap wires the app-level AppState here.
var app_state = null
var _economy_terminal_done := false
## Last WON first-clear transaction result (diagnostic; M39 V04).
var last_first_clear_result: Dictionary = {}
## M43-C001A: read-only receipt of what THIS attempt's terminal committed (built once,
## inside the latched terminal economy transaction; cleared by a successful Retry).
var _terminal_receipt: Dictionary = {}
## M43-C004: the ONE failure-assistance authority (AppState's; a private one without it)
## and this attempt's Need a Hand offer, decided once inside the latched terminal.
var _assist = null
var _assist_offer: Dictionary = {}
var _actions = null   # ProductionActionFacade (M39 V04)
## M52-C001-R01 functional 2x acquisition popup (created on first need).
var _speed_popup = null
var _pause_popup = null
## Last 2x purchase result from the popup (diagnostic/tests).
var last_speed_purchase_result: Dictionary = {}
## True while the live 2x is a PAID/entitled 2x (timed default, purchase or entitled
## toggle) as opposed to the free M23 supply-exhausted auto-2x. Only a paid 2x is dropped
## when its entitlement expires mid-level (OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01 §5).
var _paid_2x := false
## M28-C002 V02: last booster-control request result (diagnostic/tests) and the 1 s HUD
## redraw timer (wall-clock values are read from services, never accumulated).
var last_booster_request: Dictionary = {}
var _hud_timer: Timer = null
## Request seam for the canonical BoosterAcquire popup (SB-M28-C002-012 / M43, deferred):
## emitted when a booster control is tapped with no owned charge. Nothing is spent.
signal booster_acquire_requested(booster_id: String)
## Catalog entry id the AppState path resolved for this attempt (M40 V04).
var launch_entry_id: String = ""
## M43-C002: the ONE ModalStack authority. The app root injects its own before build();
## a harness host with none creates (and owns) a private one.
var modal_stack = null
var _owns_modal_stack := false
## M43-C003: the ONE AcquisitionFlow (Life / Booster Acquire / Shop handoff). The app root
## injects its own; a harness host with none creates a private one on its own stack.
var acquisition = null
var _owns_acquisition := false
## True only while THIS host's modal hold set the runtime user pause (so closing the last
## popup resumes exactly what the modal suspended, never a system suspension).
var _paused_by_modal := false
var _exited := false
## Pause -> Home confirmed: the applied attempt consequence (see exit_to_home).
signal home_requested(result: Dictionary)
## Diagnostic: last Pause-flow outcome ("resume" | "restart" | "restart_failed" | "home").
var last_pause_outcome: String = ""
## Test-only fault seam forwarded to FirstClearTransaction.commit.
var _first_clear_fault: Callable = Callable()

func set_first_clear_fault_injector(f: Callable) -> void:
	_first_clear_fault = f
var _built := false
var _build_error := ""

## M55-C001 (SB-M55-010): a host-private fallback economy (no AppState) is released
## with the host; the shared AppState graph is never touched here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release_owned_economy()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and _owns_modal_stack and modal_stack != null:
		# Harness host (no app root): its private stack consumes back. With an app root,
		# main.handle_back() consults the shared stack first.
		modal_stack.handle_back()

func _release_owned_economy() -> void:
	if _owns_economy and _economy != null:
		_economy.dispose()
	_owns_economy = false

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
	# M40 V03 (F-M40-V02-002): if an AppState was injected and its SaveService
	# rejected the primary save with an unsupported/future-schema result, refuse
	# to run normal gameplay. Fresh in-memory defaults must not silently take
	# over an unsupported future save.
	if app_state != null and app_state.is_blocked:
		_build_error = "save_blocked:%s" % app_state.blocked_reason()
		return false
	# M40 V03 (F-M40-V02-004): bind the gameplay level identity to the canonical
	# LevelProgressionService frontier when AppState is present. This closes the
	# hazard where a loaded frontier can disagree with the host's separate
	# `progression_level` export.
	# M40 V04 (F-M40-V03-002): in the AppState (shipping) path the frontier is
	# resolved through the canonical LevelCatalog; the exported level_path /
	# progression_level are ignored. No catalog entry => explicit CONTENT_MISSING
	# (never run level-1 content labelled as level N). The exports remain only
	# for the no-AppState debug/test harness path.
	if app_state != null:
		var launch := GameplayLaunchResolver.resolve(app_state)
		if not launch.get("ok", false):
			_build_error = String(launch.get("reason", GameplayLaunchResolver.CONTENT_MISSING))
			return false
		level_path = launch["level_path"]
		progression_level = int(launch["level"])
		launch_entry_id = String(launch["entry_id"])
		supply_plan_path = String(launch.get("supply_plan_path", ""))
	var res_load = LevelLoader.load_from_path(level_path)
	if not res_load.is_ok():
		_build_error = "level load failed"
		return false
	var lvl = res_load.level_data
	_level = lvl
	_board = BoardState.from_level_data(lvl)

	_supply = _make_supply(lvl)
	if _supply == null:
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
	# M41-C002 (SB-M41-005): the canonical Reduced Effects setting drives the accepted M31
	# set_reduced_effects() seam, now and live on every later change (no rebuild).
	# Presentation-only; the FX enable toggle stays independent. No AppState => OFF.
	if app_state != null and app_state.effects != null:
		_cleaning_fx.set_reduced_effects(app_state.effects.is_reduced())
		if not app_state.effects.changed.is_connected(_cleaning_fx.set_reduced_effects):
			app_state.effects.changed.connect(_cleaning_fx.set_reduced_effects)

	# M32 presentation-only arrival/disappearance echo: a second pure observer on the SAME
	# authoritative committed-clear notification. It spawns a short detached Scrubby echo at the
	# cleared cell and never mutates gameplay truth or delays the M20 finalize; a bind failure
	# (no retire layer) simply means no echoes, never a build/gameplay failure.
	_retire_echo = ScrubbotRetireEchoController.new()
	add_child(_retire_echo)
	_retire_echo.bind(presentation.get_retire_fx_layer(), _board)
	_loop.authenticated_clear.connect(_retire_echo._on_authenticated_clear)

	# M33 presentation-only audio: user volume settings (persisted) + a bounded-voice SFX
	# controller observing the SAME authoritative events. Owner audio decision V02: NO dispatch
	# sound (assignment_dispatched has no audio observer); cleaning (dispatch.wav, short
	# bounded) on authenticated clear; completion on WON only. Plus one looping Music-bus
	# background controller that no gameplay event restarts. Audio never mutates
	# gameplay/terminal/speed truth.
	# M40 V03 (F-M40-V02-005/G): when an AppState is injected, consume its
	# canonical audio settings rather than loading the legacy side file (which
	# would be a competing persistence authority). No injection => back-compat
	# side-file load.
	if app_state != null and app_state.audio != null:
		_audio_settings = app_state.audio
	else:
		_audio_settings = AudioSettingsService.new()
		_audio_settings.load()
	_audio = GameplayAudioController.new()
	add_child(_audio)
	_loop.authenticated_clear.connect(_audio._on_authenticated_clear)
	_completion.terminal_reached.connect(_audio._on_terminal_reached)
	# Background music: started once when the host enters gameplay; stopped only when the
	# host (scene) leaves the tree. Retry/dispatch/clear/terminal/speed never touch it.
	_music = MusicController.new()
	add_child(_music)

	# M34 presentation-only haptics: one live HapticsController owned by the production
	# host, observing the SAME authoritative committed events — cleaning on
	# authenticated_clear, completion on WON only. Fail-open: an unsupported platform,
	# disabled toggle or throttled request never blocks the gameplay clear/terminal.
	# The persisted enabled setting drives the live controller. Bound exactly once here;
	# _bind_haptics_signals guards against duplicate connections on host rebuild.
	# M40 V03 (F-M40-V02-005/G): consume AppState haptics settings when
	# available; back-compat side-file otherwise.
	if app_state != null and app_state.haptics != null:
		_haptics_settings = app_state.haptics
	else:
		_haptics_settings = HapticsSettingsService.new()
		_haptics_settings.load()
	_haptics = HapticsController.new()
	# M41 V01: bind the live canonical settings so a Settings toggle applies immediately.
	_haptics.bind_settings(_haptics_settings)
	add_child(_haptics)
	_bind_haptics_signals()

	# M39 V02 Economy V1 runtime composition. Fail-safe: economy is meta state and
	# never affects gameplay/terminal/solver truth. If the config cannot load,
	# _economy stays null and gameplay proceeds normally. The canonical service
	# graph is driven by authoritative production events (see _on_terminal_reached
	# and the manual-2x gate) — never by UI directly.
	# M40 V03 (F-M40-V02-001): when an AppState is injected, consume its shared
	# progression + economy + save graph so there is EXACTLY ONE authoritative
	# graph app-wide. Fall back to the pre-M40-V03 legacy path only when no
	# AppState was supplied (tests + a few older harnesses).
	if app_state != null and app_state.economy != null:
		_economy = app_state.economy
		_progression = app_state.progression
		_save = app_state.save
	else:
		_release_owned_economy()
		_economy = EconomyServices.new()
		_owns_economy = true
		if _economy != null and not _economy.config.is_ok():
			_economy = null
		if _economy != null:
			_progression = LevelProgressionService.new()
			if not save_path.is_empty():
				_save = SaveService.new(save_path, _audio_settings, _haptics_settings, _progression, _economy)
				_save.load()
	if _economy != null:
		_booster_adapter = ProductionBoosterAdapter.new(_level, _board, _supply, _slots, _scheduler)
		_booster_service = BoosterService.new(_economy.boosters)
		# M39 V04 (F-M39-V03-005): the ONE canonical production action surface.
		# Committed actions hit the host save boundary; M40 binds the same seam.
		_actions = ProductionActionFacade.new(_economy, self, Callable(self, "request_save"))
		# No AppState: this host's private economy saves rewarded grants at its boundary.
		if app_state == null:
			_economy.rewarded.bind_save(Callable(self, "request_save"))
	_economy_terminal_done = false
	_attempt_boosters = 0
	_assist = app_state.assist if app_state != null and app_state.assist != null else FailureAssistanceService.new()
	_assist.on_attempt_started(progression_level, is_progression_attempt())
	_bind_modal_stack()

	# Meaningful gameplay boundaries mark the completion state dirty (authenticated clear +
	# accepted supply-front placement). on_tick (below) then gets one chance to run the M27
	# proof at quiescence; idle ticks with no event never re-run it.
	_loop.authenticated_clear.connect(_on_clear_event)
	_input.activation_result.connect(_on_activation_event)
	# Live five-slot presentation sync AND completion evaluation after every driven tick.
	_runtime.set_state_sync(Callable(self, "_on_runtime_tick"))

	_apply_default_speed()
	_wire_controls()
	_built = true
	return true

## The attempt's initial supply engine (generated candidate or owner plan, plus the QA
## deadlock drop). Also builds the detached next-start probe for Need a Hand, so both are
## the same canonical start-state. null on failure (with _build_error set).
func _make_supply(lvl):
	var eng
	# M23 deterministic candidate (M27-proven for seed 1 / 3 columns / preview 3).
	if supply_plan_path.is_empty():
		eng = BatchSupplyGenerator.generate(lvl, column_count, preview_depth, gen_seed)
		if eng == null:
			_build_error = "supply generation failed"
			return null
	else:
		var plan := SupplyPlanLoader.load_engine(supply_plan_path, lvl)
		if not plan["ok"]:
			_build_error = "supply_plan_invalid:%s" % plan["error"]
			return null
		eng = plan["engine"]
	# QA/debug-only DEADLOCK fixture: drop the last N generated batches (see qa_supply_drop_last).
	if qa_supply_drop_last > 0:
		eng = _make_deadlock_supply(eng, qa_supply_drop_last, lvl.palette.size())
		if eng == null:
			_build_error = "qa deadlock supply build failed"
			return null
	return eng

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
	# The source engine's own shape (a plan may declare 3/4/5 columns), not the generator export.
	var out = BatchSupplyEngine.create(engine.get_column_count(), engine.get_preview_depth())
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
		_apply_default_speed()
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
	# M34 (V02): re-arm the once-per-attempt completion-haptic latch and clear the
	# cleaning throttle window so a later fresh WON buzzes again. Presentation-only;
	# the persisted enabled setting is unchanged.
	if _haptics != null and is_instance_valid(_haptics):
		_haptics.reset_for_new_attempt()
	# M39 V02/V03: a fresh attempt re-arms the terminal economy hook and the once-
	# per-attempt +1 Slot gate (the engine reset already restored the baseline
	# five). Restart-after-action law (F-M39-V02-007): if real gameplay had begun
	# BEFORE this Retry, consume exactly one Heart and reset the Win Streak;
	# pre-action Retry (no real player activation yet) consumes nothing. The
	# Heart consume runs BEFORE on_restart wipes the gameplay-started flag.
	if _economy != null:
		_economy_terminal_done = false
		_attempt_boosters = 0
		_terminal_receipt = {}
		_assist_offer = {}
		_economy.capacity.begin_new_attempt()
		var restart_mutated: bool = _economy.streak.gameplay_started()
		if restart_mutated:
			_economy.hearts.consume()
		_economy.streak.on_restart()
		# M40 V04: a post-action Retry consumed a Heart + reset the streak —
		# a durable mutation, so it hits the save boundary.
		if restart_mutated:
			_flush_durable_save()
	# M39 V03 (F-M39-V02-001): the M24 engine reset restored the baseline five;
	# also shrink the presentation strip back so a fresh attempt shows exactly
	# five slots and slot index 5 has no origin until +1 Slot is used again.
	if _screen != null and is_instance_valid(_screen):
		var strip = _screen.get_five_slot_strip()
		if strip != null:
			strip.set_capacity(5)
		# V02: re-lay the slot row for five and drop the sixth connector; fresh HUD.
		_screen.refresh_slot_snapshot(_slots.snapshot())
		_screen.set_paused(_runtime != null and _runtime.is_user_paused())
	_refresh_hud()

## Connect the live haptics controller to the authoritative committed seams exactly
## once. Idempotent: a rebuild/rebind that re-runs this never stacks duplicate
## connections (Godot's connect would push an error and double-fire).
func _bind_haptics_signals() -> void:
	if _haptics == null:
		return
	if not _loop.authenticated_clear.is_connected(_haptics._on_authenticated_clear):
		_loop.authenticated_clear.connect(_haptics._on_authenticated_clear)
	if not _completion.terminal_reached.is_connected(_haptics._on_terminal_reached):
		_completion.terminal_reached.connect(_haptics._on_terminal_reached)

## Runtime state-sync tail: refresh the five-slot strip from authoritative M24, then run one
## dirty/event-gated completion evaluation pass.
func _on_runtime_tick() -> void:
	var t0 := RuntimePerfProbe.now()
	_sync_slots()
	RuntimePerfProbe.add("ui_snapshot_sync", t0)
	if _completion != null:
		var t1 := RuntimePerfProbe.now()
		_completion.on_tick()
		RuntimePerfProbe.add("completion_on_tick", t1)

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
	# M39 V03 (F-M39-V02-007): the first ACCEPTED real player action arms attempt
	# gameplay-start truth so a Retry after this consumes a Heart + resets the
	# Win Streak. A pre-action exit/restart leaves both untouched. Idempotent —
	# WinStreak.on_gameplay_started sets a flag; later successful activations
	# re-set the same true state, no economy mutation.
	if ok and _economy != null:
		_economy.streak.on_gameplay_started()

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
	_drive_economy_terminal(_status)
	_refresh_hud()

## M39 V02 (F-M39-010): the authoritative M30 terminal drives Economy V1 exactly
## once per attempt. WON => first-clear reward + Win Streak + progression advance
## + current-level 2x entitlement clear. LOST => Heart consume + streak reset +
## entitlement survives the failed attempt. Economy never affects gameplay truth;
## a null economy (config missing) is a silent no-op.
func _drive_economy_terminal(status) -> void:
	if _economy == null or _economy_terminal_done:
		return
	# M43-C001A: authoritative pre-commit probe for the Results receipt (read-only).
	var pre: Dictionary = TerminalRewardReceipt.capture(_progression, _economy)
	var progression_attempt := is_progression_attempt()
	if status == CompletionEvaluator.WON:
		_economy_terminal_done = true
		# M39 V03 (F-M39-V02-014): the M37 forward-only progression authority
		# gates whether economy is granted. If record_win rejects (stale/future),
		# NO first-clear SB / bot part / streak / gift-feed happens. Ordering:
		#   1. progression.record_win — authoritative decision (bool);
		#   2. only on true, grant first-clear (SB by class + 1 bot part), advance
		#      streak (with the streak-SB gift-meter feed) and clear the current-
		#      level 2x entitlement on success.
		# All service calls are idempotent by stable tx id, so a stale double-WON
		# in the same attempt (economy_terminal_done latches above) is a no-op.
		# M39 V04 (F-M39-V03-004): progression + first-clear + streak/Gift +
		# entitlement commit as ONE snapshot/rollback transaction.
		last_first_clear_result = FirstClearTransaction.commit(_progression, _economy,
			progression_level, _first_clear_fault)
		# M43-C009R: a committed progression win advances today's Daily Scrub Orders
		# (saved by the terminal boundary below). Losses / replays never count.
		if bool(last_first_clear_result.get("ok", false)):
			_economy.orders.on_level_won({"level": progression_level,
				"difficulty": String(last_first_clear_result.get("difficulty", "")),
				"boosters_used": _attempt_boosters,
				"cells": _board.get_artwork_cell_count() if _board != null else 0})
			_meta_terminal(true)
	elif status == CompletionEvaluator.LOST:
		_economy_terminal_done = true
		_economy.hearts.consume()
		_economy.streak.on_progression_loss()
		_economy.speed.on_level_completed(progression_level, false)
		if progression_attempt:
			_meta_terminal(false)
	# M40 V02 (F-M40-006): terminal is a defined safe save boundary (not per-frame).
	var saved: Dictionary = request_save()
	# M43-C001A: receipt = committed before/after truth. Built only by the latched
	# WON/LOST branch, so a duplicate terminal can never rebuild/overwrite it.
	if _economy_terminal_done:
		_terminal_receipt = TerminalRewardReceipt.build(String(status), progression_level, pre,
			TerminalRewardReceipt.capture(_progression, _economy),
			last_first_clear_result if status == CompletionEvaluator.WON else {}, saved)
		_record_assistance(String(status), progression_attempt)

# ------------------------------------------------------- M43-C004 Need a Hand --

## Is this attempt a PROGRESSION attempt (the canonical frontier)? Replay / stale /
## future levels are not, and never touch the failure-assistance counter.
func is_progression_attempt() -> bool:
	return _progression != null and progression_level == int(_progression.current_level())

## Count this terminal (after economy + save committed) and, when assistance is due,
## decide the Need a Hand offer once: two boosters proved legal on the NEXT canonical
## start-state, ranked by read-only terminal context. Fewer than two -> fail closed.
func _record_assistance(status: String, progression_attempt: bool) -> void:
	if _assist == null:
		return
	var rec: Dictionary = _assist.record_terminal(progression_level, status, progression_attempt)
	_assist_offer = {"show": false, "due": bool(rec["due"]), "count": int(rec["count"]),
		"level": progression_level, "picks": [], "reason": "not_due"}
	if not rec["due"]:
		return
	var r: Dictionary = _assist.recommend(next_start_prover(), terminal_context())
	_assist_offer["picks"] = r["picks"]
	_assist_offer["reason"] = r["reason"]
	_assist_offer["show"] = bool(r["ok"])
	if not r["ok"]:
		_assist.note_fail_closed(progression_level, String(r["reason"]))

## Detached copy of this attempt's Need a Hand offer ({} before a terminal / after Retry).
func get_assistance_offer() -> Dictionary:
	return _assist_offer.duplicate(true)

func get_failure_assistance():
	return _assist

## Need a Hand was presented for this attempt's offer (analytics seam only).
func note_assistance_shown() -> void:
	if _assist != null and bool(_assist_offer.get("show", false)):
		_assist.note_shown(progression_level, (_assist_offer["picks"] as Array).map(func(p): return p["id"]))

## Booster legality prover for the NEXT canonical retry/start-state: a detached fresh
## board, the same deterministic initial supply and empty five slots, checked by the SAME
## adapter solver proofs the live booster transactions use. The live (terminal) board,
## supply and slots are never touched. Returns Callable(id) -> bool.
func next_start_prover() -> Callable:
	var supply = _make_supply(_level) if _level != null else null
	if supply == null:
		return func(_id): return false
	var slots = FiveSlotBatchEngine.new()
	var adapter = ProductionBoosterAdapter.new(_level, BoardState.from_level_data(_level), supply, slots, null)
	return func(id) -> bool:
		match String(id):
			BoosterInventory.PLUS_ONE_SLOT:
				return slots.can_grow_to_sixth()
			BoosterInventory.RANDOM:
				return bool(adapter.propose_random_reorder().get("safe", false))
			BoosterInventory.SELECTOR:
				return adapter.has_eligible_safe_batch()
			BoosterInventory.TORNADO:
				return not adapter.present_colors().is_empty()
		return false

## All four proofs on the next start-state (evidence/tests): {id: bool}.
func next_start_legality() -> Dictionary:
	var prove := next_start_prover()
	var out := {}
	for id in BoosterInventory.BOOSTERS:
		out[id] = bool(prove.call(id))
	return out

## Read-only signals from the terminal state that explain the failure: every slot was
## occupied, one colour dominates the remaining cells, supply was left over.
func terminal_context() -> Dictionary:
	var counts := {}
	var total := 0
	if _board != null:
		for i in range(_board.get_cell_count()):
			if _board.get_cell_state(i) == BoardState.CellState.ACTIVE:
				var c = _board.get_color_id(i)
				counts[c] = int(counts.get(c, 0)) + 1
				total += 1
	var top := 0
	for c in counts:
		top = maxi(top, int(counts[c]))
	return {
		"slots_full": _slots != null and _slots.rightmost_empty_index() == -1,
		"dominant_color": total > 0 and _assist != null and float(top) / float(total) >= float(_assist.dominant_share),
		"supply_remaining": _supply != null and not _supply.is_exhausted(),
	}

## M43-C010R / C012R: a committed progression terminal feeds the self-only records, the
## configured events and the Catch-Up track (presentation/meta; saved by the terminal boundary).
func _meta_terminal(won: bool) -> void:
	var r: Dictionary = _economy.records.on_progression_terminal(progression_level, won, _attempt_boosters, _economy.streak.streak())
	_economy.events.on_progression_terminal(won, bool(r["first_try"]))
	if won:
		_economy.returns.on_first_clear_win()

## M43-C009R: committed booster actions in the current attempt (reset per attempt / Retry).
func get_attempt_boosters_used() -> int:
	return _attempt_boosters

## M43-C001A: detached copy of this attempt's terminal receipt ({} before a WON/LOST
## terminal committed, or after a Retry began a fresh attempt).
func get_terminal_receipt() -> Dictionary:
	return _terminal_receipt.duplicate(true)

func _wire_controls() -> void:
	var pause_btn = _screen.get_pause_button()
	if pause_btn != null and not pause_btn.pressed.is_connected(_on_pause_pressed):
		pause_btn.pressed.connect(_on_pause_pressed)
	var speed_btn = _screen.get_speed_button()
	if speed_btn != null and not speed_btn.pressed.is_connected(_on_speed_pressed):
		speed_btn.pressed.connect(_on_speed_pressed)
	if not _screen.booster_pressed.is_connected(request_booster):
		_screen.booster_pressed.connect(request_booster)
	# M28-C002 V02: live HUD (profile / 2x state / boosters). The timer only schedules a
	# redraw; the timed-2x value itself is SpeedEntitlementService wall-clock truth (with
	# its anti-rollback high-water), never gameplay delta or Engine.time_scale.
	if _hud_timer == null:
		_hud_timer = Timer.new()
		_hud_timer.name = "HudTimer"
		_hud_timer.wait_time = 1.0
		_hud_timer.ignore_time_scale = true
		add_child(_hud_timer)
		_hud_timer.timeout.connect(_refresh_hud)
		_hud_timer.start()
	_refresh_hud()

## Default live speed of a newly built / restarted attempt (OWNER_TIMED_2X_CROSS_LEVEL_
## RUNTIME_V01): an active timed 2x entitlement (remaining wall-clock time > 0) is a
## cross-level entitlement, so the attempt starts at live 2x; otherwise 1x. The runtime
## speed authority and the HUD are set together so the countdown and the live factor
## cannot disagree. The current-level 200 SB entitlement is level-scoped and manual, so
## it never auto-starts 2x here. Free M23 auto-2x is applied by the input controller
## later and is never touched by this.
func _apply_default_speed() -> void:
	var two: bool = _economy != null and _economy.speed.timed_seconds_remaining() > 0
	_paid_2x = two
	if _runtime != null:
		_runtime.set_speed_2x(two)
	if _screen != null and is_instance_valid(_screen):
		_screen.set_speed_2x(two)

## Timed / level 2x expired mid-level: a PAID 2x no longer holds gameplay at 2x, but the
## free M23 supply-exhausted auto-2x stays independent and is never dropped.
func _drop_expired_paid_2x() -> void:
	if not _paid_2x or _economy == null or _speed == null or not _speed.is_2x():
		return
	if _economy.speed.is_manual_2x_entitled(progression_level):
		return
	_paid_2x = false
	if _supply != null and _supply.is_exhausted():
		return   # the free auto-2x owns the speed now
	_runtime.set_speed_2x(false)
	_screen.set_speed_2x(false)

## Push live, canonical values into the V02 HUD. Presentation only; reads services.
func _refresh_hud() -> void:
	if _screen == null or not is_instance_valid(_screen):
		return
	_drop_expired_paid_2x()
	var prof := {"level": progression_level}
	if _economy != null:
		var p: Dictionary = _economy.robots.next_robot_progress()
		prof["bot_parts"] = int(p.get("parts", 0))
		prof["bot_parts_cost"] = int(p.get("cost", 0))
		prof["robot_id"] = _economy.robots.active_robot()   # M43-C008: HUD portrait/name only
		var rem: int = _economy.speed.timed_seconds_remaining()
		var ent := "timed" if rem > 0 else ("level" if _economy.speed.is_manual_2x_entitled(progression_level) else "none")
		_screen.set_speed_presentation(ent, rem)
		_screen.set_booster_states(booster_states())
	_screen.set_profile(prof)

## Live state of the four canonical boosters from BoosterInventory / EconomyConfig /
## wallet / capacity authority. No feature-unlock authority exists for boosters yet, so
## none is presented as locked.
func booster_states() -> Array:
	var out: Array = []
	if _economy == null:
		return out
	var terminal: bool = _completion != null and _completion.is_terminal()
	for id in BoosterInventory.BOOSTERS:
		var charges: int = _economy.boosters.charges(id)
		var price: int = int(_economy.config.booster_price(id))
		var state := "available" if charges > 0 else ("purchasable" if _economy.wallet.scrub_bucks() >= price else "unavailable")
		if id == BoosterInventory.PLUS_ONE_SLOT:
			if _economy.capacity.plus_one_active():
				state = "selected"
			elif _slots == null or not _slots.can_grow_to_sixth():
				state = "unavailable"
		if terminal and state != "selected":
			state = "unavailable"
		out.append({"id": id, "charges": charges, "price": price, "state": state})
	return out

## M43-C003: can booster `id` legally execute right now? Read-only proofs from the SAME
## adapter the transaction uses (Random: >=3 safe fronts; Selector: solver-safe batches +
## empty slot; Tornado: present colours; +1 Slot: once per attempt, capacity <= 6).
## {legal, reason, targets:[{key, color, label}]}. Never reserves or mutates.
func booster_legality(id: String) -> Dictionary:
	if _economy == null or _booster_adapter == null:
		return {"legal": false, "reason": "economy_unavailable", "targets": []}
	if _completion != null and _completion.is_terminal():
		return {"legal": false, "reason": "terminal", "targets": []}
	var colors: Array = PaletteColors.parse(_level.palette).colors if _level != null else []
	match id:
		BoosterInventory.PLUS_ONE_SLOT:
			var ok: bool = _economy.capacity.can_activate_plus_one() and _slots != null and _slots.can_grow_to_sixth()
			return {"legal": ok, "reason": "" if ok else "plus_one_used", "targets": []}
		BoosterInventory.RANDOM:
			var ok2: bool = bool(_booster_adapter.propose_random_reorder().get("safe", false))
			return {"legal": ok2, "reason": "" if ok2 else "not_solver_safe", "targets": []}
		BoosterInventory.SELECTOR:
			var info := {}
			for col in _supply.debug_snapshot()["columns"]:
				for bd in col:
					info[String(bd["batch_id"])] = bd
			var targets: Array = []
			for bid in _booster_adapter.eligible_safe_batches():
				var bd: Dictionary = info.get(String(bid), {})
				var ci := int(bd.get("color_id", -1))
				targets.append({"key": bid, "color": colors[ci] if ci >= 0 and ci < colors.size() else Color(0.5, 0.5, 0.5),
					"label": str(int(bd.get("robot_count", 0)))})
			return {"legal": not targets.is_empty(), "reason": "" if not targets.is_empty() else "not_eligible", "targets": targets}
		BoosterInventory.TORNADO:
			var ct: Array = []
			for c in _booster_adapter.present_colors():
				ct.append({"key": c, "color": colors[int(c)] if int(c) >= 0 and int(c) < colors.size() else Color(0.5, 0.5, 0.5), "label": ""})
			return {"legal": not ct.is_empty(), "reason": "" if not ct.is_empty() else "color_not_present", "targets": ct}
	return {"legal": false, "reason": "unknown_booster", "targets": []}

## M43-C003: execute booster `id` through the canonical facade (charge-first, then SB,
## reserved only after the solver-safety pre-checks; refunded on a failed commit).
## Called by the Booster Acquire popup while it owns input, so the modal gate of
## request_booster() does not apply; the terminal gate does.
func execute_booster(id: String, target = null) -> Dictionary:
	var r: Dictionary
	if _economy == null or _actions == null:
		r = {"ok": false, "reason": "economy_unavailable"}
	elif not BoosterInventory.BOOSTERS.has(id):
		r = {"ok": false, "reason": "unknown_booster"}
	elif _completion != null and _completion.is_terminal():
		r = {"ok": false, "reason": "terminal"}
	elif id == BoosterInventory.PLUS_ONE_SLOT:
		# activate_plus_one_slot() reports only bool; surface the SB shortfall explicitly.
		if _economy.boosters.charges(id) <= 0 and _economy.wallet.scrub_bucks() < int(_economy.config.booster_price(id)):
			r = {"ok": false, "reason": "insufficient_sb"}
		else:
			r = _actions.plus_one_slot()
	elif id == BoosterInventory.RANDOM:
		r = _actions.random()
	elif target == null:
		r = {"ok": false, "reason": "target_required"}
	elif id == BoosterInventory.SELECTOR:
		r = _actions.selector(target)
	else:
		r = _actions.tornado(target)
	r["id"] = id
	last_booster_request = r
	_refresh_hud()
	return r

## Booster control intent (V02 booster row). Never spends SB from a tap:
##   - owned charge + no target needed (+1 Slot, Random) -> canonical action facade, which
##     consumes the charge (Economy V1 charge-first) through BoosterService;
##   - no charge -> no spend; `booster_acquire_requested` + the canonical M43-C003
##     Booster Acquire popup on the shared ModalStack (SB-M28-C002-012);
##   - owned Selector / Tornado -> the same popup in USE mode for the target pick
##     (owner decision B1-POPUP); nothing is consumed until the pick is committed.
func request_booster(id: String) -> Dictionary:
	var r: Dictionary
	if _economy == null or _actions == null:
		r = {"ok": false, "reason": "economy_unavailable"}
	elif not BoosterInventory.BOOSTERS.has(id):
		r = {"ok": false, "reason": "unknown_booster"}
	elif _completion != null and _completion.is_terminal():
		r = {"ok": false, "reason": "terminal"}
	elif is_modal_open():
		r = {"ok": false, "reason": "modal_open"}
	elif _economy.boosters.charges(id) <= 0:
		# M43-C003: zero charge -> the canonical Booster Acquire popup (SB / rewarded).
		r = {"ok": false, "reason": "acquire_required"}
		booster_acquire_requested.emit(id)
		if acquisition != null:
			acquisition.open_booster(self, id)
	elif id == BoosterInventory.PLUS_ONE_SLOT:
		r = _actions.plus_one_slot()
	elif id == BoosterInventory.RANDOM:
		r = _actions.random()
	else:
		# Owned Selector / Tornado charge: the same component in USE mode picks the target
		# (solver-safe batches / present colours); no purchase CTA, nothing consumed yet.
		r = {"ok": false, "reason": "target_selection"}
		if acquisition != null:
			acquisition.open_booster(self, id)
	r["id"] = id
	last_booster_request = r
	_refresh_hud()
	return r

## M43-C002 (SB-M43-019): the V02 top-right Pause control opens the canonical Pause
## popup. Ignored while any popup owns input or after a terminal result (Results owns it).
func _on_pause_pressed() -> void:
	open_pause()

# ------------------------------------------------------------- M43-C002 modal --

func _bind_modal_stack() -> void:
	if modal_stack == null:
		modal_stack = ModalStack.new()
		_owns_modal_stack = true
		add_child(modal_stack)
	if not modal_stack.modal_changed.is_connected(_on_modal_changed):
		modal_stack.modal_changed.connect(_on_modal_changed)
	if acquisition == null and _economy != null:
		acquisition = AcquisitionFlow.new()
		acquisition.bind(modal_stack, _economy, _actions, ShopHandoff.new())
		_owns_acquisition = true

func _exit_tree() -> void:
	if _owns_acquisition and acquisition != null:
		acquisition.unbind()
	if modal_stack != null and is_instance_valid(modal_stack) and not _owns_modal_stack \
			and modal_stack.modal_changed.is_connected(_on_modal_changed):
		modal_stack.modal_changed.disconnect(_on_modal_changed)

func get_modal_stack():
	return modal_stack

func get_acquisition():
	return acquisition

func is_modal_open() -> bool:
	return modal_stack != null and is_instance_valid(modal_stack) and modal_stack.is_open()

## Canonical modal hold: while ANY popup is on the stack over gameplay, supply input is
## gated and the runtime is held in user pause (no cadence, no agent travel). Closing the
## last popup releases ONLY a pause this hold created; a focus/system suspension is a
## separate runtime reason and is never cleared here.
func _on_modal_changed(active: bool) -> void:
	if _input != null:
		_input.set_modal_blocked(active)
	if _runtime == null:
		return
	if active:
		if not _runtime.is_user_paused():
			_runtime.set_user_paused(true)
			_paused_by_modal = true
	elif _paused_by_modal:
		_paused_by_modal = false
		_runtime.set_user_paused(false)
	if _screen != null and is_instance_valid(_screen):
		_screen.set_paused(_runtime.is_user_paused())
		var pause_btn = _screen.get_pause_button()
		if pause_btn != null:
			pause_btn.text = "▶" if _runtime.is_user_paused() else "II"

## Open the Pause popup. Returns it, or null when refused (not built, terminal, exited, or
## a popup already owns input -- rapid repeats are therefore no-ops).
func open_pause():
	if not _built or _exited or is_modal_open():
		return null
	if _completion != null and _completion.is_terminal():
		return null
	var p = Popups.pause({"level": progression_level})
	p.action_selected.connect(_on_pause_action.bind(p))
	if not modal_stack.push(p):
		p.free()
		return null
	_pause_popup = p
	return p

## The open Pause popup, or null.
func get_pause_popup():
	if _pause_popup != null and is_instance_valid(_pause_popup) and _pause_popup.is_open():
		return _pause_popup
	return null

func _on_pause_action(id: String, _ctx: Dictionary, pause) -> void:
	match id:
		"resume":
			last_pause_outcome = "resume"
		"restart", "home":
			var c = Popups.attempt_confirm(id, attempt_consequence())
			c.action_selected.connect(_on_attempt_confirmed.bind(id))
			c.closed.connect(func(_r):
				if is_instance_valid(pause) and pause.is_open():
					pause.rearm())
			modal_stack.push(c)

## Exactly-once confirmation (the confirm popup closes itself before emitting).
func _on_attempt_confirmed(id: String, _ctx: Dictionary, kind: String) -> void:
	if id != "confirm":
		return
	if kind == "restart":
		# M43-C003 zero-Heart attempt gate: a Restart that would begin the new attempt with
		# no Heart opens the canonical Life popup instead (nothing is consumed or reset).
		if _economy != null and int(attempt_consequence()["hearts_after"]) < 1:
			last_pause_outcome = "restart_gated"
			if acquisition != null:
				acquisition.open_life("restart_gate")
			return
		# The REAL M30 transaction-safe Retry; its restore seam applies the M39
		# restart-after-action law (Heart + Win Streak) exactly as the preview stated.
		if retry():
			last_pause_outcome = "restart"
			modal_stack.clear("restart")
		else:
			last_pause_outcome = "restart_failed"
			modal_stack.push(Popups.feedback({"ok": false, "reason": "restart_unavailable"}))
	else:
		var r := exit_to_home()
		last_pause_outcome = "home"
		modal_stack.clear("home")
		home_requested.emit(r)

## Read-only consequence of ending this attempt now (Restart or Home), derived from the
## accepted authorities the Retry/exit paths themselves use: WinStreakService
## .gameplay_started() (armed by the first accepted supply activation), HeartService
## .hearts() (consume() fails closed at 0) and WinStreakService.streak(). Never a UI flag.
func attempt_consequence() -> Dictionary:
	var started: bool = _economy != null and _economy.streak.gameplay_started()
	var out := {"level": progression_level, "gameplay_started": started, "economy": _economy != null,
		"heart_loss": false, "hearts_before": -1, "hearts_after": -1, "streak_before": 0, "streak_reset": false}
	if _economy != null:
		var h: int = _economy.hearts.hearts()
		var st: int = _economy.streak.streak()
		out["hearts_before"] = h
		out["streak_before"] = st
		out["heart_loss"] = started and h > 0
		out["hearts_after"] = maxi(h - 1, 0) if started else h
		out["streak_reset"] = started and st > 0
	return out

## End this attempt to Home (Pause -> Home confirmed). Owner Economy V1: leaving before
## the first real action costs nothing (WinStreakService.on_pre_action_exit); leaving after
## it counts as a loss exactly like restart-after-action (-1 Heart, streak reset). The
## attempt-scoped +1 Slot capacity ends with the attempt. Exactly once per host.
func exit_to_home() -> Dictionary:
	if _exited:
		return {"ok": false, "reason": "already_exited"}
	if _completion != null and _completion.is_terminal():
		return {"ok": false, "reason": "terminal"}
	_exited = true
	var c := attempt_consequence()
	if _economy != null:
		if bool(c["gameplay_started"]):
			_economy.hearts.consume()
			_economy.streak.on_restart()
		else:
			_economy.streak.on_pre_action_exit()
		_economy.capacity.begin_new_attempt()
		if bool(c["gameplay_started"]):
			_flush_durable_save()
	c["ok"] = true
	return c

## M29 temporal/debug seam. Economy V1 supersedes free shipping manual 2x:
## M39 must route this production-facing request through SpeedEntitlementService
## (level/timed SB entitlement) before enabling 2x. Keep this direct toggle only as
## pre-M39 playable/audit behavior; authoritative M23-exhausted auto-2x remains free.
## M40 V03 (F-M40-V02-008): durable save at a defined runtime boundary. Used by
## host-owned action APIs (activate_plus_one_slot, terminal, purchase, claim,
## unlock, exchange, settings) and by external callers via request_save(). Not
## per-frame. Fail-safe when no SaveService is bound.
func _flush_durable_save() -> void:
	request_save()

## M40 V04 (F-M40-V03-003): with an AppState the canonical app save boundary
## (blocked-safe, clears dirty) is used; otherwise the legacy host SaveService.
func request_save() -> Dictionary:
	if app_state != null:
		return app_state.request_save()
	if _save == null:
		return {"ok": true, "source": "no_save_bound"}
	return _save.save()

## Manual 2x control (M52-C001-R01; OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01
## §6). The control NEVER silently does nothing:
##   - currently 2x                    -> back to 1x (always allowed);
##   - 1x + manual entitlement          -> 2x;
##   - 1x + NO entitlement (Economy V1) -> open the functional 2x acquisition popup.
## Turning 2x ON stays gated by SpeedEntitlementService. The free M23-exhausted automatic
## 2x uses the speed authority directly (set_2x), never this button, so it stays free and
## entitlement-independent.
func _on_speed_pressed() -> void:
	if is_modal_open():
		return
	var currently_2x: bool = _speed != null and _speed.is_2x()
	if not currently_2x and _economy != null:
		if not _economy.speed.is_manual_2x_entitled(progression_level):
			_open_speed_acquisition()
			return
	var two: bool = _runtime.toggle_speed()
	_paid_2x = two
	_screen.set_speed_2x(two)
	_refresh_hud()

## Canonical Economy V1 2x offers (prices from EconomyConfig, never hardcoded here).
func speed_offers() -> Array:
	var out: Array = [{"key": "level", "kind": "level", "seconds": 0, "label": UiText.t("SPEED_LABEL_LEVEL"),
		"price_sb": _economy.config.speed_current_level_sb()}]
	for p in _economy.config.speed_timed_products():
		var secs: int = int(p.get("seconds", 0))
		out.append({"key": "timed_%d" % secs, "kind": "timed", "seconds": secs,
			"label": UiText.t("SPEED_LABEL_MINUTES", [secs / 60]), "price_sb": int(p.get("sb", 0))})
	return out

## M43-C003: the canonical 2x Acquire popup on the shared ModalStack.
func _open_speed_acquisition() -> void:
	if is_modal_open():
		return
	_speed_popup = SpeedAcquisitionPopup.new()
	_speed_popup.offer_chosen.connect(_on_speed_offer_chosen)
	_speed_popup.open(speed_offers(), speed_state())
	if not modal_stack.push(_speed_popup):
		_speed_popup.free()
		_speed_popup = null
		return
	# Live timed countdown: popup-owned 1 s redraw of SpeedEntitlementService truth.
	var t := Timer.new()
	t.name = "LiveRefresh"
	t.wait_time = 1.0
	t.ignore_time_scale = true
	var pop = _speed_popup
	t.timeout.connect(func():
		if is_instance_valid(pop) and pop.is_open():
			pop.refresh(speed_state()))
	pop.add_child(t)
	t.start()

## Live 2x entitlement view for the popup (SpeedEntitlementService truth).
func speed_state() -> Dictionary:
	return {"scrub_bucks": _economy.wallet.scrub_bucks(),
		"level_active": _economy.speed.is_level_entitled(progression_level),
		"timed_remaining": _economy.speed.timed_seconds_remaining()}

## Purchase through the ONE canonical action surface (durable save on commit). Success ->
## 2x immediately + control updated + popup closed. Failure/insufficient SB -> nothing
## spent, no entitlement, speed unchanged, visible reason in the popup.
func _on_speed_offer_chosen(kind: String, seconds: int) -> void:
	if _actions == null:
		_speed_popup.show_status("2x purchase unavailable right now.")
		return
	var r: Dictionary = _actions.buy_current_level_2x(progression_level) if kind == "level" \
		else _actions.buy_timed_2x(seconds)
	last_speed_purchase_result = r
	var pop = get_speed_acquisition_popup()
	if not r.get("ok", false):
		var reason: String = String(r.get("reason", "failed"))
		if pop != null:
			pop.show_status(UiText.t("ACQ_NOT_ENOUGH") if reason == "insufficient_sb"
				else UiText.t("SPEED_UNAVAILABLE", [reason]))
			pop.rearm_soon()
			pop.refresh(speed_state())
		if reason == "insufficient_sb" and acquisition != null:
			var key := "level" if kind == "level" else "timed_%d" % seconds
			var price := 0
			var label := key
			for o in speed_offers():
				if o["key"] == key:
					price = int(o["price_sb"])
					label = UiText.t("SPEED_ITEM", [o["label"]])
			acquisition.open_insufficient({"source": "speed", "product": "speed:" + key, "offer_key": key,
				"level": progression_level, "item_label": label,
				"price_sb": price, "balance_sb": _economy.wallet.scrub_bucks()})
		return
	if pop != null:
		pop.close("purchased")
	if _economy.speed.is_manual_2x_entitled(progression_level):
		_paid_2x = true
		_runtime.set_speed_2x(true)
		_screen.set_speed_2x(true)
	_refresh_hud()

## The open canonical 2x Acquire popup, or null.
func get_speed_acquisition_popup():
	if _speed_popup != null and is_instance_valid(_speed_popup) and _speed_popup.is_open():
		return _speed_popup
	return null

## Test-only fault seam for the +1 Slot transition (M39 V04, F-M39-V03-003):
## f(stage) -> true forces a failure at "engine" (after the M24 grow) or
## "strip" (after the presentation grow). Never set in production.
var _plus_one_fault: Callable = Callable()

func set_plus_one_fault_injector(f: Callable) -> void:
	_plus_one_fault = f

func _plus_one_faulted(stage: String) -> bool:
	return _plus_one_fault.is_valid() and bool(_plus_one_fault.call(stage))

## +1 Slot booster: economy reserve + capacity authority + M24 engine grow +
## presentation strip/origin grow are ONE reversible transition (M39 V04,
## F-M39-V03-003). Any failure after the reservation restores the exact prior
## five-slot state: charge/SB refunded, capacity authority back to (5, unused),
## M24 shrunk via rollback_grow_to_sixth (legal: the new sixth slot is still
## EMPTY and uncommitted inside this synchronous call), strip back to its prior
## capacity (so origin_for_slot(5) is unroutable again). Never returns false
## with M24 left at six.
func activate_plus_one_slot() -> bool:
	if _economy == null or _slots == null:
		return false
	if not _slots.can_grow_to_sixth():
		return false
	var strip = _screen.get_five_slot_strip() if _screen != null else null
	var strip_prev: int = strip.get_capacity() if strip != null else 5
	var res = _booster_service.apply_plus_one_slot(_economy.capacity)
	if not res.get("ok", false):
		return false
	var engine_grown := false
	var ok: bool = _slots.grow_to_sixth()
	if ok:
		engine_grown = true
		ok = not _plus_one_faulted("engine")
	if ok and strip != null:
		ok = strip.set_capacity(6) and not _plus_one_faulted("strip")
	if not ok:
		if strip != null:
			strip.set_capacity(strip_prev)
		if engine_grown:
			_slots.rollback_grow_to_sixth()
		_economy.boosters.refund(BoosterInventory.PLUS_ONE_SLOT, res)
		_economy.capacity.begin_new_attempt()   # pre-state was (5, unused): exact
		if _screen != null:
			_screen.refresh_slot_snapshot(_slots.snapshot())
		return false
	# Push a fresh 6-slot snapshot so the newly appended view has content.
	if _screen != null and _slots != null:
		_screen.refresh_slot_snapshot(_slots.snapshot())
	# M40 V03 (F-M40-V02-008): a durable meta mutation is a defined save boundary.
	_flush_durable_save()
	return true

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

func get_music_controller():
	return _music

func get_haptics_controller():
	return _haptics

func get_haptics_settings():
	return _haptics_settings

func get_economy():
	return _economy

func get_progression():
	return _progression

func get_booster_service():
	return _booster_service

func get_booster_adapter():
	return _booster_adapter

## Canonical production action facade (M39 V04). null when economy is absent.
func get_actions():
	return _actions

## Post-commit reconciliation after a booster edited board/supply/slots outside
## the clearing loop (Random/Selector/Tornado): resync the raw candidate index
## and renderer to BoardState truth, refresh slot/supply UI, and mark the
## completion evaluator dirty (a Tornado can finish the board).
func on_booster_committed() -> void:
	_attempt_boosters += 1
	if _ci != null:
		_ci.rebuild()
	var r = _renderer()
	if r != null:
		r.refresh_all()
	if _screen != null and is_instance_valid(_screen):
		_screen.update_snapshots(_slots.snapshot(), _supply.player_snapshot())
	if _completion != null:
		_completion.notify_event()
	_refresh_hud()

func get_save():
	return _save

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
