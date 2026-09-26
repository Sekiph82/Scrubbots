extends SceneTree
## M40-C001 V04 — actual app bootstrap + durable lifecycle (F-M40-V03-001..004).
## Boots the REAL project main scene (res://scenes/app/main.tscn) with isolated
## user:// save paths and deterministic clock/local-day seams, and drives the
## real resolver, action facade, save, lifecycle flush and relaunch paths.
## Run: godot --headless --path . -s res://tests/m40_v04_bootstrap.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _fail := 0
var _tmp: Array = []
var _now := 0

func _uniq(tag: String) -> String:
	var p := "user://m40v4_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _initialize() -> void:
	_check_project_main_scene()
	await _fresh_boot()
	await _future_schema_blocks()
	await _frontier_resolves_catalog()
	await _frontier_missing_content()
	await _durable_action_relaunch()
	await _failed_action_no_save()
	await _settings_relaunch()
	await _lifecycle_flush_relaunch()
	await _daily_local_boundary_relaunch()
	await _no_per_frame_writes()
	_cleanup()
	_done()

# --- boot helpers ---

func _boot(path: String, with_clock: bool = false, offset: int = 0):
	MainScript.boot_save_path_override = path
	if with_clock:
		MainScript.boot_clock_override = func(): return _now
		MainScript.boot_local_day_override = LocalCalendar.offset_provider(func(): return _now, offset)
	else:
		MainScript.boot_clock_override = Callable()
		MainScript.boot_local_day_override = Callable()
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()

func _bytes(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func _unix(y: int, m: int, d: int, hh: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d, "hour": hh, "minute": 0, "second": 0}))

# --- tests ---

func _check_project_main_scene() -> void:
	print("[project main scene]")
	_ok(String(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/app/main.tscn", "project.godot launches scenes/app/main.tscn")
	var scene_text := FileAccess.get_file_as_string("res://scenes/app/main.tscn")
	_ok(scene_text.find("res://scripts/app/main.gd") != -1, "main.tscn root script is scripts/app/main.gd (the AppState owner)")

func _fresh_boot() -> void:
	print("[fresh boot]")
	var path := _uniq("fresh")
	var root = await _boot(path)
	var app = root.get_app_state()
	_ok(app != null, "actual root owns an AppState")
	_ok(not root.is_blocked(), "fresh boot not blocked")
	_ok(app.save != null and app.economy != null and app.progression != null, "AppState graph present")
	var r = root.launch_gameplay()
	_ok(r["ok"], "launch_gameplay builds production host (%s)" % r.get("reason", ""))
	var host = root.get_gameplay_host()
	_ok(host != null and host.app_state == app, "host received the SAME AppState")
	_ok(host.get_economy() == app.economy and host.get_progression() == app.progression, "no second economy/progression graph")
	_ok(host.get_actions() != null, "host exposes canonical action facade")
	_shutdown(root)

func _future_schema_blocks() -> void:
	print("[future schema blocks]")
	var path := _uniq("future")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.save", "version": 999, "future": true}))
	f.close()
	var before := _bytes(path)
	var root = await _boot(path)
	_ok(root.is_blocked(), "future-schema save blocks the actual root")
	var r = root.launch_gameplay()
	_ok(not r["ok"] and r["reason"] == GameplayLaunchResolver.APP_BLOCKED, "blocked root refuses gameplay")
	_ok(not root.flush_lifecycle("test")["ok"], "blocked root refuses lifecycle flush")
	_ok(not root.get_app_state().request_save()["ok"], "blocked AppState refuses save")
	_ok(not root.get_app_state().set_haptics_enabled(false)["ok"], "blocked AppState refuses settings mutation")
	root._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_ok(_bytes(path) == before, "future-schema file never overwritten")
	_shutdown(root)

func _frontier_resolves_catalog() -> void:
	print("[frontier 1 -> catalog content]")
	var cat = LevelCatalog.new()
	_ok(cat.load_manifest().ok, "production catalog valid")
	var entry = null
	for e in cat.get_entries_ordered():
		if e.order == 1:
			entry = e
	_ok(entry != null, "catalog has order-1 entry")
	var root = await _boot(_uniq("f1"))
	var res = GameplayLaunchResolver.resolve(root.get_app_state())
	_ok(res["ok"] and res["level"] == 1 and res["entry_id"] == entry.id, "resolver frontier 1 -> %s" % entry.id)
	var r = root.launch_gameplay()
	var host = root.get_gameplay_host()
	_ok(r["ok"] and host.level_path == entry.level_path and host.progression_level == 1, "host built from catalog entry path, labelled level 1")
	# A stale exported level_path is ignored in the AppState (shipping) path.
	var h2 = ProductionGameplayHost.new()
	h2.app_state = root.get_app_state()
	h2.auto_build = false
	h2.level_path = "res://data/levels/test_40x40.json"
	h2.progression_level = 7
	root.add_child(h2)
	_ok(h2.build(), "host with stale exports still builds from catalog")
	_ok(h2.level_path == entry.level_path and h2.progression_level == 1, "stale level_path/progression_level overridden by resolver")
	_shutdown(root)

func _frontier_missing_content() -> void:
	# M52-C001: the catalog now holds orders 1..10, so frontier 2 is real content
	# (Apple) and the first frontier without content is 11.
	print("[frontier 2 -> Apple; frontier 11 -> CONTENT_MISSING]")
	var path := _uniq("f11")
	var root = await _boot(path)
	var app = root.get_app_state()
	_ok(app.progression.record_win(1), "frontier advanced to 2")
	var r2: Dictionary = GameplayLaunchResolver.resolve(app)
	_ok(r2["ok"] and r2["level"] == 2 and r2["entry_id"] == "level_002_apple", "frontier 2 resolves level_002_apple (no level-1 fallback)")
	for n in range(2, 11):
		app.progression.record_win(n)
	_ok(app.progression.current_level() == 11, "frontier advanced to 11")
	_ok(app.request_save()["ok"], "saved")
	_shutdown(root)
	var root2 = await _boot(path)
	_ok(root2.get_app_state().progression.current_level() == 11, "relaunch frontier 11")
	var r = root2.launch_gameplay()
	_ok(not r["ok"] and r["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "launch refuses: CONTENT_MISSING")
	_ok(root2.get_gameplay_host() == null, "no gameplay host created for missing content")
	var h = ProductionGameplayHost.new()
	h.app_state = root2.get_app_state()
	h.auto_build = false
	root2.add_child(h)
	_ok(not h.build() and h.get_build_error() == GameplayLaunchResolver.CONTENT_MISSING, "direct host build also fails CONTENT_MISSING (never runs level-1 content as level 11)")
	_shutdown(root2)

func _durable_action_relaunch() -> void:
	print("[durable action -> save -> relaunch, no terminal]")
	var path := _uniq("act")
	var root = await _boot(path)
	var app = root.get_app_state()
	# Economy-only app action (menus): Daily login.
	var r1 = app.actions.claim_daily_login()
	_ok(r1["ok"] and r1.has("save") and r1["save"]["ok"], "Daily login committed + saved via AppState facade")
	var sb_after: int = app.economy.wallet.scrub_bucks()
	# Gameplay action through the host facade: +1 Slot paid by charge.
	app.economy.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 2)
	root.launch_gameplay()
	var host = root.get_gameplay_host()
	var r2 = host.get_actions().plus_one_slot()
	_ok(r2["ok"] and r2["save"]["ok"], "+1 Slot committed + saved via host facade")
	var charges_after: int = app.economy.boosters.charges(BoosterInventory.PLUS_ONE_SLOT)
	_shutdown(root)
	var root2 = await _boot(path)
	var app2 = root2.get_app_state()
	_ok(app2.economy.wallet.scrub_bucks() == sb_after, "relaunch: Daily SB persisted")
	_ok(not app2.actions.claim_daily_login()["ok"], "relaunch same local day: no regrant")
	_ok(app2.economy.boosters.charges(BoosterInventory.PLUS_ONE_SLOT) == charges_after, "relaunch: +1 Slot charge spend persisted")
	_shutdown(root2)

func _failed_action_no_save() -> void:
	print("[failed action -> no save]")
	var path := _uniq("fail")
	var root = await _boot(path)
	var app = root.get_app_state()
	app.request_save()
	var before := _bytes(path)
	var committed := [0]
	app.actions.action_committed.connect(func(_a, _r): committed[0] += 1)
	_ok(not app.actions.unlock_robot("m40v4_robot")["ok"], "unlock without Bot Parts refused")
	_ok(not app.actions.buy_timed_2x(-5)["ok"], "unknown 2x product refused")
	_ok(committed[0] == 0 and _bytes(path) == before, "failed actions: no signal, save file unchanged")
	_shutdown(root)

func _settings_relaunch() -> void:
	print("[settings mutation -> relaunch]")
	var path := _uniq("set")
	var root = await _boot(path)
	var app = root.get_app_state()
	_ok(app.set_haptics_enabled(false)["ok"], "haptics setting via AppState action")
	_ok(app.set_volumes(0.25, 0.5, 0.75)["ok"], "audio volumes via AppState action")
	_shutdown(root)
	var root2 = await _boot(path)
	var app2 = root2.get_app_state()
	_ok(not app2.haptics.is_enabled(), "relaunch: haptics off persisted")
	_ok(is_equal_approx(app2.audio.get_master_volume(), 0.25) and is_equal_approx(app2.audio.get_music_volume(), 0.5) and is_equal_approx(app2.audio.get_sfx_volume(), 0.75), "relaunch: volumes persisted")
	_shutdown(root2)

func _lifecycle_flush_relaunch() -> void:
	print("[background/quit flush -> relaunch]")
	for note in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		var path := _uniq("life%d" % note)
		var root = await _boot(path)
		var app = root.get_app_state()
		var start: int = app.progression.current_level()
		# Pending (unsaved) durable state: progression advanced without a save.
		app.progression.record_win(start)
		app.mark_dirty()
		_ok(not FileAccess.file_exists(path) or _bytes(path).find("\"current_level\":%d" % (start + 1)) == -1, "note %d: not yet on disk" % note)
		root._notification(note)
		_ok(root.last_flush.get("ok", false), "note %d: root lifecycle flush saved (%s)" % [note, root.last_flush.get("lifecycle", "")])
		_shutdown(root)
		var root2 = await _boot(path)
		_ok(root2.get_app_state().progression.current_level() == start + 1, "note %d: relaunch sees flushed state" % note)
		_shutdown(root2)

func _daily_local_boundary_relaunch() -> void:
	print("[local Daily boundary -> relaunch]")
	var path := _uniq("daily")
	var off := -5 * 3600
	_now = _unix(2026, 12, 31, 20)     # local 15:00 Dec 31 (UTC-5)
	var root = await _boot(path, true, off)
	_ok(root.get_app_state().actions.claim_daily_login()["ok"], "claim Dec 31 local")
	_shutdown(root)
	_now = _unix(2027, 1, 1, 3)        # UTC Jan 1, local 22:00 Dec 31
	var root2 = await _boot(path, true, off)
	_ok(not root2.get_app_state().actions.claim_daily_login()["ok"], "relaunch same local day (across UTC new year) cannot regrant")
	_shutdown(root2)
	_now = _unix(2027, 1, 1, 6)        # local 01:00 Jan 1 2027
	var root3 = await _boot(path, true, off)
	var r = root3.get_app_state().actions.claim_daily_login()
	_ok(r["ok"] and root3.get_app_state().economy.daily.streak() == 2, "relaunch next local day (year boundary) claims, streak 2")
	_shutdown(root3)
	_now = _unix(2026, 12, 30, 12)     # rollback
	var root4 = await _boot(path, true, off)
	_ok(not root4.get_app_state().actions.claim_daily_login()["ok"], "relaunch with clock rollback stays blocked")
	_ok(root4.get_app_state().economy.daily.streak() == 2, "rollback left streak intact")
	_shutdown(root4)
	# Month boundary.
	var path2 := _uniq("daily_m")
	_now = _unix(2027, 4, 30, 12)
	var r5 = await _boot(path2, true, 0)
	r5.get_app_state().actions.claim_daily_login()
	_shutdown(r5)
	_now = _unix(2027, 5, 1, 12)
	var r6 = await _boot(path2, true, 0)
	_ok(r6.get_app_state().actions.claim_daily_login()["ok"] and r6.get_app_state().economy.daily.streak() == 2, "relaunch across month boundary: consecutive")
	_shutdown(r6)
	# Production root (no seams) uses the OS local calendar.
	var r7 = await _boot(_uniq("sys"))
	_ok(int(r7.get_app_state().economy.daily._local_day_provider.call()) == LocalCalendar.ordinal_of_dict(Time.get_date_dict_from_system(false)), "production root injects OS local-calendar provider")
	_shutdown(r7)

func _no_per_frame_writes() -> void:
	print("[no per-frame writes]")
	var path := _uniq("frames")
	var root = await _boot(path)
	root.get_app_state().request_save()
	root.launch_gameplay()
	var before := _bytes(path)
	var rt = root.get_gameplay_host().get_runtime()
	for _i in range(60):
		rt.tick(0.016)
		await process_frame
	_ok(_bytes(path) == before, "60 gameplay frames with no durable action -> save file untouched")
	_shutdown(root)

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M40 V04 bootstrap evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
