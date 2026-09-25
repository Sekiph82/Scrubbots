extends SceneTree
## M42-C001 — production Home evidence (SB-M42-002 and later Home tasks append cases).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const REQUIRED_VIEWPORTS := [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200)]

var EXPECTED_CASES := [
	"home_shell_tree", "home_in_real_root", "home_blocked_state",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _home_shell_tree()
	await _home_in_real_root()
	await _home_blocked_state()
	_cleanup()
	_done()

func _home_shell_tree() -> void:
	print("[home shell tree]")
	var app = AppState.new(_uniq("shell"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	await process_frame
	_ok(home.get_node_or_null("SafeAreaRoot/MarginContainer/Content/HomeLayout") != null, "SafeAreaRoot -> MarginContainer -> Content -> HomeLayout")
	var layout: Control = home.get_region("HomeLayout")
	var names: Array = []
	for c in layout.get_children():
		names.append(String(c.name))
	_ok(names == ["TopCurrencyHUD", "GiftMeter", "MainWorldArea", "PlayButton", "StatusLabel", "WinStreakRewardTrack", "BottomNav"], "MASTER_UI §6 region order %s" % str(names))
	var world_names: Array = []
	for c in home.get_region("MainWorldArea").get_children():
		world_names.append(String(c.name))
	_ok(world_names == ["LeftShortcutColumn", "CenterScrubbyArea", "RightShortcutColumn"], "MainWorldArea left/center/right")
	_ok(home.get_region("PlayButton") is Button and not home.get_region("PlayButton").disabled, "live PLAY button enabled for a healthy save")
	var full_textures := 0
	for n in home.find_children("*", "TextureRect", true, false):
		if (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			full_textures += 1
	_ok(full_textures == 0, "no interactive bitmap (no input-receiving TextureRect)")
	_ok(home.get_region("Nav_settings").name == "SettingsButton" and not home.get_region("Nav_settings").disabled, "bottom-nav SETTINGS live")
	_ok(home.get_region("Nav_events").disabled and home.get_region("Nav_robots").disabled and home.get_region("Nav_leaderboard").disabled, "later-milestone tabs disabled, not faked")
	sub.free()
	_complete("home_shell_tree")

func _home_in_real_root() -> void:
	print("[home in real root]")
	var root = await _boot_main(_uniq("root"))
	var home = root.get_home()
	_ok(home != null and home.get_app_state() == root.get_app_state(), "real root Home bound to the ONE canonical AppState")
	_ok(home.visible and root.get_navigation().current() == NavigationController.Route.HOME, "Home visible at route HOME")
	_ok(root.find_child("GodotVersionLabel", true, false) == null and root.find_child("BoardCoreLabel", true, false) == null, "pre-M42 debug label shell removed")
	var settings_btn: Button = root.find_child("SettingsButton", true, false)
	settings_btn.pressed.emit()
	_ok(root.get_navigation().is_settings_open() and root.get_settings_panel().visible, "Home SETTINGS opens the canonical Settings overlay")
	_ok(root.get_settings_panel().get_index() > home.get_index(), "Settings overlay drawn above Home")
	_shutdown(root)
	_complete("home_in_real_root")

func _home_blocked_state() -> void:
	print("[home blocked state]")
	var path := _uniq("blocked")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.save", "version": 999}))
	f.close()
	var before := FileAccess.get_file_as_string(path)
	var root = await _boot_main(path)
	var home = root.get_home()
	_ok(root.is_blocked() and home.get_region("PlayButton").disabled, "blocked save: PLAY disabled")
	_ok(String(home.get_region("StatusLabel").text).find("newer version") != -1, "blocked save: explicit read-only message")
	home.get_region("PlayButton").pressed.emit()
	_ok(root.get_navigation().current() == NavigationController.Route.HOME and root.get_gameplay_host() == null, "blocked: no gameplay")
	_shutdown(root)
	_ok(FileAccess.get_file_as_string(path) == before, "blocked future-schema save untouched")
	_complete("home_blocked_state")

# ---------------------------------------------------------------- helpers ----

func _boot_main(path: String):
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _uniq(tag: String) -> String:
	var p := "user://m42home_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M42 home cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 home evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
