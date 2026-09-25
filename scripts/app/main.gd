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

## Test-only boot seams, read once when the root enters the tree. Production
## leaves them unset (canonical save path, system clock, OS local calendar).
static var boot_save_path_override: String = ""
static var boot_clock_override: Callable = Callable()
static var boot_local_day_override: Callable = Callable()

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
	_home = HomeScreenScene.instantiate()
	_home.name = "HomeScreen"
	add_child(_home)
	_home.bind(app_state)
	_home.settings_requested.connect(open_settings)
	_home.play_requested.connect(play_current_frontier)
	_build_settings_entry()
	nav.route_changed.connect(_on_route_changed)
	nav.go(NavigationController.Route.HOME, {"via": "boot"})

## M42: show the screen that belongs to the current route.
func _on_route_changed(_from: int, to: int, _payload: Dictionary) -> void:
	if _home != null:
		_home.visible = to == NavigationController.Route.HOME
		if _home.visible:
			_home.refresh()

func get_home():
	return _home

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
	if _gameplay_host != null and is_instance_valid(_gameplay_host):
		_gameplay_host.queue_free()
	var host = ProductionGameplayHost.new()
	host.app_state = app_state
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	(parent if parent != null else self).add_child(host)
	var ok: bool = host.build()
	_gameplay_host = host
	last_launch = {"ok": ok, "reason": "" if ok else host.get_build_error(), "launch": launch, "host": host}
	return last_launch

## SB-M42-003: Home PLAY/CONTINUE. Launches ONLY the canonical frontier through the
## existing resolver + launch_gameplay() (same AppState). Returns the launch result.
func play_current_frontier() -> Dictionary:
	if nav.current() != NavigationController.Route.HOME:
		return {"ok": false, "reason": "not_home"}
	var r := launch_gameplay()
	if r.get("ok", false):
		nav.go(NavigationController.Route.GAMEPLAY, {"level": r["launch"]["level"], "entry_id": r["launch"]["entry_id"]})
	elif _home != null:
		_home.refresh()
	return r

func get_gameplay_host():
	return _gameplay_host

## Narrow lifecycle flush seam (tests call it directly; the OS delivers the
## notifications below). Never writes while the app is blocked.
func flush_lifecycle(reason: String) -> Dictionary:
	if app_state == null:
		last_flush = {"ok": false, "reason": "no_app_state"}
	else:
		last_flush = app_state.flush()
	last_flush["lifecycle"] = reason
	return last_flush

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			flush_lifecycle("application_paused")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			flush_lifecycle("focus_out")
		NOTIFICATION_WM_CLOSE_REQUEST:
			flush_lifecycle("close_request")
