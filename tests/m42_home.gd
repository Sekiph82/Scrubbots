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
	"play_cta_fresh", "continue_cta_frontier",
	"settings_single_authority",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _home_shell_tree()
	await _home_in_real_root()
	await _home_blocked_state()
	await _play_cta_fresh()
	await _continue_cta_frontier()
	await _settings_single_authority()
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

func _play_cta_fresh() -> void:
	print("[play cta fresh]")
	var root = await _boot_main(_uniq("play"))
	var home = root.get_home()
	var play: Button = home.get_region("PlayButton")
	_ok(play.text == "PLAY" and not play.disabled, "fresh save: live CTA 'PLAY'")
	_ok(home.get_launch_preview().get("level") == 1 and home.get_launch_preview().get("ok"), "CTA previews canonical frontier level 1")
	play.pressed.emit()
	await process_frame
	var host = root.get_gameplay_host()
	_ok(root.get_navigation().current() == NavigationController.Route.GAMEPLAY, "PLAY -> GAMEPLAY")
	_ok(host != null and host.is_built() and host.app_state == root.get_app_state(), "host built with the same AppState")
	_ok(host != null and host.progression_level == 1 and root.last_launch["launch"]["entry_id"] == "m21_level_001_hazard_bot", "launched exactly the frontier entry")
	_ok(not home.visible, "Home hidden during gameplay")
	var pickers: int = root.find_children("*", "OptionButton", true, false).size() + root.find_children("*", "ItemList", true, false).size()
	_ok(pickers == 0, "no level picker control anywhere")
	_shutdown(root)
	_complete("play_cta_fresh")

func _continue_cta_frontier() -> void:
	print("[continue cta frontier]")
	var path := _uniq("cont")
	var app = AppState.new(path)
	_ok(app.progression.record_win(1), "record level-1 win")
	app.request_save()
	var root = await _boot_main(path)
	var home = root.get_home()
	var play: Button = home.get_region("PlayButton")
	_ok(play.text == "CONTINUE · LEVEL 2", "CTA shows CONTINUE · LEVEL 2 (%s)" % play.text)
	_ok(play.disabled and String(home.get_region("StatusLabel").text).find("coming soon") != -1, "frontier without content: disabled + honest message")
	play.pressed.emit()
	var r: Dictionary = root.play_current_frontier()
	_ok(not r.get("ok", true) and r.get("reason") == "CONTENT_MISSING", "direct launch refuses CONTENT_MISSING")
	_ok(root.get_gameplay_host() == null and root.get_navigation().current() == NavigationController.Route.HOME, "no gameplay, still HOME (never falls back to level 1)")
	_shutdown(root)
	_complete("continue_cta_frontier")

## SB-M42-004: Home Settings reuses the ONE M41 panel bound to the ONE AppState.
func _settings_single_authority() -> void:
	print("[settings single authority]")
	var path := _uniq("settings")
	var root = await _boot_main(path)
	var app = root.get_app_state()
	var btn: Button = root.get_home().get_region("Nav_settings")
	var panel = root.get_settings_panel()
	for _i in range(3):
		btn.pressed.emit()
		panel.close_panel()
	btn.pressed.emit()
	_ok(root.find_children("*", "", true, false).filter(func(n): return n.get_script() == panel.get_script()).size() == 1, "exactly one SettingsPanel instance after repeated opens")
	_ok(panel.visible and root.get_navigation().is_settings_open(), "Home SETTINGS opens it")
	panel.get_toggle("music").button_pressed = false
	panel.get_reduced_effects_toggle().button_pressed = true
	_ok(not app.audio.is_music_enabled() and app.effects.is_reduced(), "changes land in the canonical AppState services")
	panel.close_panel()
	var p2 = AppState.new(path)
	_ok(not p2.audio.is_music_enabled() and p2.effects.is_reduced(), "persisted through the canonical save (no side authority)")
	_ok(root.get_navigation().current() == NavigationController.Route.HOME and not root.get_navigation().is_settings_open(), "closing returns to Home")
	_ok(app.progression.current_level() == 1 and app.economy.wallet.scrub_bucks() == p2.economy.wallet.scrub_bucks(), "no unrelated side effects (progression/economy unchanged)")
	root.get_home().get_region("PlayButton").pressed.emit()
	root.open_settings()
	_ok(not root.get_navigation().is_settings_open() and not panel.visible, "Settings cannot open during gameplay")
	_shutdown(root)
	_complete("settings_single_authority")

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
