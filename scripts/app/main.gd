extends Control
## App root / bootstrap (res://scenes/app/main.tscn — project.godot run/main_scene).
##
## M40 V04 (F-M40-V03-001/003): this actual launched root OWNS the ONE canonical
## AppState (audio + haptics + progression + economy + save) for the whole app:
##   - loads the canonical save at startup (AppState constructor);
##   - exposes the blocked/future-schema state to the app flow (no gameplay,
##     no save overwrite while blocked);
##   - creates production gameplay ONLY through launch_gameplay(), which resolves
##     the frontier through LevelCatalog and injects this same AppState;
##   - flushes durable state at app lifecycle boundaries (background/pause,
##     focus loss, close/quit) — never per frame.
## M42: the pre-M42 debug label shell is replaced by the production Home screen
## (SB-M42-002), shown whenever the navigation route is HOME.

const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const OpeningScreen = preload("res://scripts/app/opening_screen.gd")
const LaunchSession = preload("res://scripts/app/launch_session.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const AcquisitionFlow = preload("res://scripts/ui/popup/acquisition_flow.gd")
const ShopHandoff = preload("res://scripts/app/shop_handoff.gd")
const ResultsMomentum = preload("res://scripts/progression/results_momentum.gd")
const CeremonyPresenter = preload("res://scripts/ui/ceremony/ceremony_presenter.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const MetaFeedback = preload("res://scripts/ui/feel/meta_feedback.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
## BottomNav tabs the app root serves (RANKS waits for the SB-M43-131 owner policy).
const APP_NAV := ["events"]
## Home shortcut panels the app root turns into app-level destinations (Home opens none of
## its M42 popups for these; Cards Exchange keeps its Home seam).
const APP_SHORTCUTS := ["shop", "collection", "tasks", "daily", "gift_bar", "profile", "rewarded_ads"]

## Test-only boot seams, read once when the root enters the tree. Production
## leaves them unset (canonical save path, system clock, OS local calendar).
static var boot_save_path_override: String = ""
static var boot_clock_override: Callable = Callable()
static var boot_local_day_override: Callable = Callable()
## SB-M42-029 opening boot policy seam: -1 auto (play when a display exists; a headless
## run has nothing to present on and boots straight to Home), 0 never, 1 always.
static var boot_opening_override: int = -1

var app_state = null
## M42 (SB-M42-001): the ONE app-root-owned navigation authority.
var nav = null
var last_launch: Dictionary = {}
var last_flush: Dictionary = {}
var _gameplay_host = null
## M41 V01 Settings panel bound to THIS canonical AppState (no second settings authority).
var _settings_panel = null
## M42 production Home (SB-M42-002), bound to THIS AppState.
var _home = null
## M42 Results surface (SB-M42-007): shown once per gameplay terminal.
var _results = null
## SB-M42-028/029 opening cinematic (only during the OPENING route).
var _opening = null
## M43-C002 (SB-M43-016): the ONE app-level ModalStack, above Home / gameplay / Results.
var _modals = null
## M43-C003: the ONE Shop handoff + acquisition flow (Life / Booster / Shop), app-level.
var shop = null
var _acq = null
## M43-C001R: validated momentum presentation config (read once; shared by Results/Home).
var momentum_cfg: Dictionary = {}
## M43 master: the ONE presenter of committed-but-unseen meta ceremonies (presentation only).
var ceremonies = null
var meta_feedback = null
## M43-C005F (SB-M43-C005F-002): the ONE fail-open presentation-feel adapter (no call site yet).
## Ephemeral: never saved; cancelled + unbound when the app root leaves the tree.
## Handed (presentation-only) to ResultsScreen; a pack ceremony takes it via bind_feedback().
var feel = null

func _enter_tree() -> void:
	_boot()

func _boot() -> void:
	if app_state != null:
		return
	var path: String = boot_save_path_override if not boot_save_path_override.is_empty() else AppState.CANONICAL_SAVE_PATH
	app_state = AppState.new(path, boot_clock_override, boot_local_day_override)
	nav = NavigationController.new()
	nav.settings_changed.connect(_on_nav_settings_changed)

func _ready() -> void:
	_modals = ModalStack.new()
	add_child(_modals)
	_home = HomeScreenScene.instantiate()
	_home.name = "HomeScreen"
	add_child(_home)
	_home.bind(app_state)
	set_momentum_config(ResultsMomentum.load_config())
	_home.settings_requested.connect(open_settings)
	_home.play_requested.connect(play_current_frontier)
	_results = ResultsScreen.new()
	_results.visible = false
	add_child(_results)
	_results.home_requested.connect(func(): nav.go(NavigationController.Route.HOME, {"via": "results"}))
	_results.continue_requested.connect(continue_from_results)
	_results.retry_requested.connect(retry_from_results)
	_build_settings_entry()
	# Home hides its action layer while any stacked popup owns input (existing seam);
	# closing the last popup re-reads live values (a purchase may have changed them).
	_modals.modal_changed.connect(func(active):
		_home.set_modal_active("modal_stack", active)
		if not active and _home.visible:
			_home.refresh()
			request_home_ceremonies())
	shop = ShopHandoff.new()
	_acq = AcquisitionFlow.new()
	if app_state != null and app_state.economy != null:
		_acq.bind(_modals, app_state.economy, app_state.actions, shop)
	# SB-M43-032 / 036: Home Heart + -> canonical Life; Home SB + -> canonical Shop intent.
	_home.hearts_purchase_requested.connect(func(): open_life("home_heart_plus"))
	_home.scrub_bucks_purchase_requested.connect(func(): _acq.open_shop({"source": "home_sb_plus"}))
	# M43 destinations from the Home shortcut panels (SB-M43-078 Shop, ...).
	_home.shortcut_requested.connect(_on_home_shortcut)
	_home.nav_requested.connect(_on_home_nav)
	_home.set_app_shortcuts(APP_SHORTCUTS)
	_home.set_app_nav(APP_NAV)
	feel = FeedbackAdapter.new()
	feel.bind(get_tree(), app_state.effects if app_state != null else null)
	_results.set_feedback(feel)   # M43-C005F-003/004: presentation-only Results feel
	ceremonies = CeremonyPresenter.new()
	ceremonies.bind(_modals, app_state)
	# M43-C014: committed-only meta sound / haptic moments.
	meta_feedback = MetaFeedback.new()
	meta_feedback.name = "MetaFeedback"
	add_child(meta_feedback)
	meta_feedback.bind(app_state)
	meta_feedback.bind_stack(_modals)
	meta_feedback.ui_gate = func(): return nav != null and nav.current() == NavigationController.Route.HOME
	ceremonies.ceremony_shown.connect(meta_feedback.on_ceremony_shown)
	# M43-C012: a genuine absence opens a return window (summary shown once on Home).
	if app_state != null and app_state.economy != null and not app_state.is_blocked:
		app_state.economy.returns.on_active()
		app_state.mark_dirty()
	ceremonies.idle.connect(func(src):
		if src == "results" and _results != null:
			_results.set_ceremony_barrier(RESULTS_CEREMONY_BARRIER, false))
	# Every committed facade action (Gift / Daily claim, exchange, unlock, ...) may have
	# completed a set / Master / robot event: show its ceremony once Home is quiet.
	if app_state != null and app_state.actions != null:
		app_state.actions.action_committed.connect(func(_a, _r): request_home_ceremonies())
	nav.route_changed.connect(_on_route_changed)
	_start_remote_content()
	if _should_play_opening():
		_start_opening()
	else:
		nav.go(NavigationController.Route.HOME, {"via": "boot"})

## CP04/CP05: one background remote refresh per cold launch, only when the runtime config
## names an HTTPS endpoint. Boot never waits on it: builtin + cached LKG are already live.
## A successful activation re-reads Home's frontier/launch truth; failure is diagnostic only.
func _start_remote_content() -> void:
	if app_state == null or app_state.content == null or app_state.content.transport != null:
		return
	var t = app_state.content.make_production_transport()
	if t == null:
		return
	add_child(t)
	app_state.content.transport = t
	app_state.content.content_changed.connect(func():
		if _home != null and _home.visible:
			_home.refresh())
	app_state.content.refresh()

## SB-M42-031: presentation policy (display available / test override) AND the
## once-per-cold-launch LaunchSession gate. Only a new native process plays it again.
func _should_play_opening() -> bool:
	if boot_opening_override == 0:
		return false
	if boot_opening_override == -1 and DisplayServer.get_name() == "headless":
		return false
	return LaunchSession.try_consume_opening()

## SB-M42-029: BOOT -> OPENING; the cinematic's single terminal outcome (completed or
## failed) enters normal Home exactly once. Any load/decode/play failure is fail-safe.
func _start_opening() -> void:
	if not nav.go(NavigationController.Route.OPENING, {"via": "boot"}):
		nav.go(NavigationController.Route.HOME, {"via": "boot"})
		return
	_opening = OpeningScreen.new()
	add_child(_opening)
	_opening.completed.connect(func(): _finish_opening("completed"))
	_opening.failed.connect(func(reason): _finish_opening("failed:" + reason))
	_opening.begin()

## Idempotent: only the first outcome transitions (nav OPENING -> HOME edge exists once).
func _finish_opening(outcome: String) -> void:
	if nav.current() != NavigationController.Route.OPENING:
		return
	nav.go(NavigationController.Route.HOME, {"via": "opening", "outcome": outcome})

func get_opening():
	return _opening

## M42: show the screen that belongs to the current route.
func _on_route_changed(_from: int, to: int, _payload: Dictionary) -> void:
	# Returning HOME ends the gameplay scene: the host (and its music/FX) is released.
	if to == NavigationController.Route.HOME:
		_release_gameplay_host()
		if _opening != null and is_instance_valid(_opening):
			_opening.cleanup()
			remove_child(_opening)
			_opening.queue_free()
			_opening = null
	if _home != null:
		_home.visible = to == NavigationController.Route.HOME
		if _home.visible:
			_home.refresh()
			request_home_ceremonies()
	if _results != null:
		_results.visible = to == NavigationController.Route.RESULTS
		if _results.visible:
			_results.show_model(_results_model(_payload))
			move_child(_results, get_child_count() - 1)
			if String(_payload.get("status", "")) == "LOST":
				_offer_need_a_hand()
			elif String(_payload.get("status", "")) == "WON":
				_begin_results_ceremonies()

## SB-M43-013: a WON Results whose committed terminal (economy + save already done inside the
## host) produced a ceremony event (Gift milestone, set, Master, robot) hands off to it: the
## teaser + CLEAN NEXT are held by a ceremony barrier, the ceremonies open one at a time AFTER
## the committed reward-row reveal, and the barrier releases when none is left. Presentation
## only — Continue / rewards / progression are untouched; a route change leaves any unshown
## ceremony pending for Home.
const RESULTS_CEREMONY_BARRIER := "meta_ceremonies"

func _begin_results_ceremonies() -> void:
	if ceremonies == null or ceremonies.pending().is_empty():
		return
	_results.set_ceremony_barrier(RESULTS_CEREMONY_BARRIER, true)
	if _results.is_revealing():
		_results.get_reveal_sequencer().completed.connect(func(_k): call_deferred("_drain_results_ceremonies"), CONNECT_ONE_SHOT)
	else:
		call_deferred("_drain_results_ceremonies")

func _drain_results_ceremonies() -> void:
	if nav.current() != NavigationController.Route.RESULTS or ceremonies == null:
		return
	if not ceremonies.drain("results") and not ceremonies.is_presenting():
		_results.set_ceremony_barrier(RESULTS_CEREMONY_BARRIER, false)

## M43-C004: on the Fail surface of a due third failure, Need a Hand opens on the ONE
## ModalStack over Fail. The host decided the offer inside its latched terminal (after the
## loss/economy/save committed); closing it returns to the usable Fail, no auto-Retry.
func _offer_need_a_hand() -> void:
	var host = _gameplay_host
	if host == null or not is_instance_valid(host) or _acq == null:
		return
	if _acq.open_need_a_hand(host.get_assistance_offer()) != null:
		host.note_assistance_shown()

## M43-C001A: the ONE Results model for a RESULTS route payload. The receipt is the
## host's committed terminal truth (never recomputed here); continue availability is the
## canonical frontier resolver. Pure read: building it any number of times grants nothing.
func _results_model(payload: Dictionary) -> Dictionary:
	var m := payload.duplicate(true)
	m["receipt"] = _gameplay_host.get_terminal_receipt() if _gameplay_host != null and is_instance_valid(_gameplay_host) else {}
	var launch := GameplayLaunchResolver.resolve(app_state)
	m["continue"] = {"available": bool(launch.get("ok", false)), "reason": String(launch.get("reason", "")),
		"next_level": int(launch.get("level", 0))}
	# M43-C001R: journey (anchor = the just-completed level) + Next Cleanup from the SAME
	# resolved launch CLEAN NEXT uses. Read-only; a malformed config just omits it.
	if String(m.get("status", "")) == "WON":
		m["momentum"] = ResultsMomentum.results_model(app_state, int(m.get("level", 0)), launch, momentum_cfg)
	# M43-C001B: presentation-only Reduced Effects flag (canonical settings service).
	m["reduced_effects"] = app_state != null and app_state.effects != null and app_state.effects.is_reduced()
	# M43-C008 (SB-M43-108): the active robot's approved victory / help pose (presentation only).
	m["robot_id"] = app_state.economy.robots.active_robot() if app_state != null and app_state.economy != null else ""
	return m

## Share one validated momentum config with Results (via _results_model) and Home.
func set_momentum_config(cfg: Dictionary) -> void:
	momentum_cfg = cfg.duplicate(true)
	if _home != null:
		_home.set_momentum_config(momentum_cfg)

func get_home():
	return _home

## BottomNav destinations that open an app-level surface (SETTINGS keeps its M41 overlay).
func _on_home_nav(id: String) -> void:
	if nav == null or nav.current() != NavigationController.Route.HOME or (_modals != null and _modals.depth() > 0):
		return
	match id:
		"robots":
			RobotsScreen.open(_modals, app_state, ceremonies)
		"events":
			ProfileScreens.open_events(_modals, app_state)

## Home shortcut panels / Gift Meter that open an app-level destination (APP_SHORTCUTS).
func _on_home_shortcut(id: String) -> void:
	if nav == null or nav.current() != NavigationController.Route.HOME or (_modals != null and _modals.depth() > 0):
		return
	match id:
		"shop":
			_acq.open_shop({"source": "home_shop"})
		"collection":
			CollectionScreen.open_album(_modals, app_state)
		"tasks":
			DailyScreens.open_tasks(_modals, app_state)
		"daily":
			DailyScreens.open_daily(_modals, app_state)
		"rewarded_ads":
			RewardedAdsScreen.open(_modals, app_state)
		"gift_bar":
			DailyScreens.open_gift_bar(_modals, app_state)
		"profile":
			ProfileScreens.open_profile(_modals, app_state)

## M43 master: on HOME, with no other popup open, present pending meta ceremonies (deferred so
## it never pushes from inside a route / modal signal handler).
func request_home_ceremonies() -> void:
	call_deferred("_drain_home_ceremonies")

func _drain_home_ceremonies() -> void:
	if ceremonies == null or nav == null or nav.current() != NavigationController.Route.HOME or nav.is_settings_open():
		return
	if _modals != null and _modals.depth() > 0:
		return
	if not ceremonies.drain("home") and app_state != null and app_state.economy.returns.summary_due():
		ProfileScreens.open_comeback(_modals, app_state)

## M43-C012 (SB-M43-148): open a notification deep link. Only known destinations; anything
## unknown / stale lands on Home. Returns the destination actually opened.
func open_deep_link(dest: String) -> String:
	var d := NotificationPolicy.deep_link(dest)
	if nav == null or app_state == null or app_state.is_blocked:
		return "none"
	if nav.current() != NavigationController.Route.HOME:
		return "home"
	if _modals != null:
		_modals.clear("deep_link")
	match d:
		"robots", "events":
			_on_home_nav(d)
		"home":
			pass
		_:
			_on_home_shortcut(d)
	return d

func get_ceremonies():
	return ceremonies

## M41 V01 Settings panel (M42: opened from the Home bottom-nav SETTINGS button).
func _build_settings_entry() -> void:
	_settings_panel = SettingsPanelScene.instantiate()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.visible = false
	add_child(_settings_panel)
	_settings_panel.bind(app_state)
	_settings_panel.closed.connect(func(): nav.close_settings())

## Settings is a navigation overlay (HOME only); the panel follows nav state.
func open_settings() -> void:
	nav.open_settings()

func _on_nav_settings_changed(open: bool) -> void:
	if _settings_panel == null:
		return
	# V03 K: Settings obscures Home exactly like a Home popup (action controls hidden).
	if _home != null:
		_home.set_modal_active("settings", open)
	if open:
		_settings_panel.open_panel()
	elif _settings_panel.visible:
		_settings_panel.close_panel()

func get_navigation():
	return nav

func get_settings_panel():
	return _settings_panel

func get_app_state():
	return app_state

func is_blocked() -> bool:
	return app_state == null or app_state.is_blocked

## Resolve the frontier through LevelCatalog and create the production gameplay
## host with THIS AppState injected. Returns {ok, reason?, launch, host?}.
## Blocked app / missing content never builds gameplay.
func launch_gameplay(parent: Node = null) -> Dictionary:
	if is_blocked():
		last_launch = {"ok": false, "reason": GameplayLaunchResolver.APP_BLOCKED}
		return last_launch
	var launch := GameplayLaunchResolver.resolve(app_state)
	if not launch.get("ok", false):
		last_launch = {"ok": false, "reason": launch.get("reason", ""), "launch": launch}
		return last_launch
	# SB-M42-006: exactly one gameplay host. The previous host leaves the tree NOW
	# (not a deferred queue_free that would coexist for a frame).
	_release_gameplay_host()
	var host = ProductionGameplayHost.new()
	host.name = "GameplayHost"
	host.app_state = app_state
	host.modal_stack = _modals
	host.acquisition = _acq
	host.home_requested.connect(_on_gameplay_home_requested.bind(host))
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	(parent if parent != null else self).add_child(host)
	var ok: bool = host.build()
	if not ok:
		# A failed build never leaves an orphan half-built host behind.
		var err: String = host.get_build_error()
		host.get_parent().remove_child(host)
		host.queue_free()
		last_launch = {"ok": false, "reason": err, "launch": launch}
		return last_launch
	_gameplay_host = host
	last_launch = {"ok": true, "reason": "", "launch": launch, "host": host}
	return last_launch

## Remove the current gameplay host from the tree immediately and free it. Only the
## app root owns host lifetime.
func _release_gameplay_host() -> void:
	# Popups over the released gameplay never outlive it (no stale callbacks).
	if _modals != null:
		_modals.clear("host_released")
	if _gameplay_host != null and is_instance_valid(_gameplay_host):
		if _gameplay_host.get_parent() != null:
			_gameplay_host.get_parent().remove_child(_gameplay_host)
		_gameplay_host.queue_free()
	_gameplay_host = null

## SB-M42-003: Home PLAY/CONTINUE. Launches ONLY the canonical frontier through the
## existing resolver + launch_gameplay() (same AppState). Returns the launch result.
func play_current_frontier() -> Dictionary:
	# SB-M42-006: accepted only when navigation can enter GAMEPLAY right now (HOME, no
	# transition in flight); otherwise nothing is built.
	if not nav.can_go(NavigationController.Route.GAMEPLAY) or nav.current() != NavigationController.Route.HOME:
		return {"ok": false, "reason": "not_home"}
	if _zero_heart_gate("attempt_gate"):
		return {"ok": false, "reason": "no_hearts"}
	var r := launch_gameplay()
	if r.get("ok", false):
		nav.go(NavigationController.Route.GAMEPLAY, {"level": r["launch"]["level"], "entry_id": r["launch"]["entry_id"]})
		_bind_terminal(r["host"])
	elif _home != null:
		_home.refresh()
	return r

## SB-M42-007: authoritative M30 terminal -> RESULTS exactly once per attempt. The host's
## own terminal handler (economy + save) is connected first, so it has committed before
## Results appear. The attempt id is read at signal time (Retry re-arms a new attempt).
func _bind_terminal(host) -> void:
	var completion = host.get_completion()
	if completion == null:
		return
	completion.terminal_reached.connect(func(status, _detail):
		if host == _gameplay_host:
			nav.on_gameplay_terminal(nav.attempt_id(), status, int(host.progression_level)))

## RESULTS (WON) -> next canonical frontier, only when it has content. Exactly one
## accepted launch per Results: the first success leaves RESULTS, so every later/rapid
## call is refused. attempt (from ResultsScreen) must match the shown Results attempt,
## so a stale Continue from an earlier Results can never launch. Never grants rewards.
func continue_from_results(attempt: int = -1) -> Dictionary:
	if nav.current() != NavigationController.Route.RESULTS:
		return {"ok": false, "reason": "not_results"}
	var shown: Dictionary = nav.last_payload()
	if attempt >= 0 and attempt != int(shown.get("attempt", -1)):
		return {"ok": false, "reason": "stale_results"}
	if String(shown.get("status", "")) != "WON":
		return {"ok": false, "reason": "not_won"}
	if not GameplayLaunchResolver.resolve(app_state).get("ok", false):
		_results.show_model(_results_model(shown))
		return {"ok": false, "reason": "no_next_content"}
	if _zero_heart_gate("attempt_gate"):
		_results.show_model(_results.get_model())   # re-arm Continue
		return {"ok": false, "reason": "no_hearts"}
	var r := launch_gameplay()
	if r.get("ok", false):
		nav.go(NavigationController.Route.GAMEPLAY, {"level": r["launch"]["level"], "entry_id": r["launch"]["entry_id"]})
		_bind_terminal(r["host"])
	elif nav.current() == NavigationController.Route.RESULTS:
		# Launch failed with no transition: re-show the same committed model (re-arms
		# Continue). launch_gameplay released the old host, so the receipt comes from
		# the Results model already shown.
		var m: Dictionary = _results.get_model()
		m["continue"] = _results_model(shown)["continue"]
		_results.show_model(m)
	return r

## RESULTS (LOST) -> M30 transaction-safe Retry of the same host, new attempt id.
func retry_from_results() -> bool:
	if nav.current() != NavigationController.Route.RESULTS or _gameplay_host == null:
		return false
	if _zero_heart_gate("attempt_gate"):
		return false
	if not _gameplay_host.retry():
		return false
	return nav.resume_gameplay_after_retry()

func get_results_screen():
	return _results

func get_modal_stack():
	return _modals

func get_acquisition():
	return _acq

## SB-M43-032: the ONE Life surface (Home Heart + and every zero-Heart attempt gate).
func open_life(source: String):
	return _acq.open_life(source) if _acq != null else null

## Zero-Heart attempt gate: a new attempt needs >= 1 Heart (HeartService truth). With none,
## the canonical Life popup opens and nothing launches. Returns true when gated.
func _zero_heart_gate(source: String) -> bool:
	if app_state == null or app_state.economy == null or app_state.economy.hearts.hearts() > 0:
		return false
	open_life(source)
	return true

## Pause -> Home confirmed by the CURRENT host (which already applied the owner
## pre-/post-action exit law). GAMEPLAY -> HOME releases the host.
func _on_gameplay_home_requested(result: Dictionary, host) -> void:
	if host != _gameplay_host or nav.current() != NavigationController.Route.GAMEPLAY:
		return
	nav.go(NavigationController.Route.HOME, {"via": "pause_home",
		"gameplay_started": bool(result.get("gameplay_started", false))})

func get_gameplay_host():
	return _gameplay_host

## Narrow lifecycle flush seam (tests call it directly; the OS delivers the
## notifications below). Never writes while the app is blocked.
func flush_lifecycle(reason: String) -> Dictionary:
	if app_state == null:
		last_flush = {"ok": false, "reason": "no_app_state"}
	else:
		if app_state.economy != null and not app_state.is_blocked:
			app_state.economy.returns.touch()
			app_state.mark_dirty()
		last_flush = app_state.flush()
	last_flush["lifecycle"] = reason
	return last_flush

## SB-M42-009: deterministic back (Android back / Esc). The OS auto-quit on back is
## disabled in project.godot (application/config/quit_on_go_back=false) so back is
## routed only through the navigation authority:
##   Settings open -> close it; RESULTS -> HOME;
##   GAMEPLAY -> HOME only before the first real action (Economy V1: pre-action exit =
##   no Heart/streak consequence; WinStreakService.on_pre_action_exit); after the first
##   action there is no owner-defined mid-level exit rule, so back does nothing;
##   HOME / OPENING -> nothing (no Level Select, no exit policy invented).
## M43-C002: any ModalStack popup takes back first; mid-level exit after the first
## action is available only through Pause -> Home with its loss confirmation.
func handle_back() -> String:
	# M43-C002 (SB-M43-026): an open popup consumes back first (top only, never leaks).
	if _modals != null and _modals.handle_back():
		return "close_modal"
	var pre_action := false
	if nav.current() == NavigationController.Route.GAMEPLAY and _gameplay_host != null 			and app_state != null and app_state.economy != null:
		pre_action = not app_state.economy.streak.gameplay_started() 			and not _gameplay_host.get_completion().is_terminal()
	# Home popups (Gift Bar / Cards Exchange / Daily) close before anything else.
	if nav.current() == NavigationController.Route.HOME and not nav.is_settings_open() 			and _home != null and _home.close_top_popup():
		return "close_popup"
	var action: String = nav.back(pre_action)
	if action == "home" and pre_action:
		app_state.economy.streak.on_pre_action_exit()
	return action

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()
		get_viewport().set_input_as_handled()

## Presentation-only teardown: the feel adapter cancels its own plugin work (SB-M43-C005F-002).
func _exit_tree() -> void:
	if feel != null:
		feel.unbind()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			handle_back()
		NOTIFICATION_APPLICATION_PAUSED:
			flush_lifecycle("application_paused")
		NOTIFICATION_APPLICATION_RESUMED:
			if app_state != null and app_state.economy != null and not app_state.is_blocked and app_state.economy.returns.on_active()["opened"]:
				request_home_ceremonies()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			flush_lifecycle("focus_out")
		NOTIFICATION_WM_CLOSE_REQUEST:
			flush_lifecycle("close_request")
