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
## The debug labels remain (no Home UI before M42) but are no longer the whole
## bootstrap.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")

## Test-only boot seams, read once when the root enters the tree. Production
## leaves them unset (canonical save path, system clock, OS local calendar).
static var boot_save_path_override: String = ""
static var boot_clock_override: Callable = Callable()
static var boot_local_day_override: Callable = Callable()

var app_state = null
var last_launch: Dictionary = {}
var last_flush: Dictionary = {}
var _gameplay_host = null
## M41 V01 Settings panel bound to THIS canonical AppState (no second settings authority).
var _settings_panel = null

func _enter_tree() -> void:
	_boot()

func _boot() -> void:
	if app_state != null:
		return
	var path: String = boot_save_path_override if not boot_save_path_override.is_empty() else AppState.CANONICAL_SAVE_PATH
	app_state = AppState.new(path, boot_clock_override, boot_local_day_override)

func _ready() -> void:
	%GodotVersionLabel.text = "Godot %s" % Engine.get_version_info().string
	%BoardCoreLabel.text = _describe_board_core()
	var status := get_node_or_null("VBoxContainer/StatusLabel")
	if status != null:
		status.text = _describe_app_state()
	_build_settings_entry()

## M41 V01: a native SETTINGS button on the pre-M42 app root opens the Settings panel.
func _build_settings_entry() -> void:
	var box := get_node_or_null("VBoxContainer")
	if box != null:
		var b := Button.new()
		b.name = "SettingsButton"
		b.text = "SETTINGS"
		b.custom_minimum_size = Vector2(360, 88)
		b.add_theme_font_size_override("font_size", 34)
		b.pressed.connect(open_settings)
		box.add_child(b)
	_settings_panel = SettingsPanelScene.instantiate()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.visible = false
	add_child(_settings_panel)
	_settings_panel.bind(app_state)

func open_settings() -> void:
	if _settings_panel != null:
		_settings_panel.open_panel()

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

func _describe_app_state() -> String:
	if app_state == null:
		return "AppState: missing"
	if app_state.is_blocked:
		return "Save blocked: %s" % app_state.blocked_reason()
	var launch := GameplayLaunchResolver.resolve(app_state)
	if launch.get("ok", false):
		return "Frontier %d: %s" % [launch["level"], launch["entry_id"]]
	return "Frontier %d: %s" % [int(launch.get("level", 0)), launch.get("reason", "")]

func _describe_board_core() -> String:
	var parts: PackedStringArray = []
	for path in ["res://data/levels/test_40x40.json", "res://data/levels/test_50x50.json"]:
		var result = LevelLoader.load_from_path(path)
		if result.is_ok():
			var level = result.level_data
			parts.append("%dx%d: %d" % [level.width, level.height, level.get_cell_count()])
		else:
			parts.append("%s: FAILED" % path)
	return "Board Core OK  |  " + "  |  ".join(parts)
