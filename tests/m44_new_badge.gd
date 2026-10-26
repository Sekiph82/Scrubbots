extends SceneTree
## SB-M44-013 — NEW badge on newly unlocked Home entries until first visit:
##   - HomeBadges.new_features: unlocked + unvisited gated entries of a NEW FTUE profile only;
##   - visiting (meta_ui "feature_visited:<feature>") clears it and survives save / reload;
##   - grandfathered profiles and legacy snapshots (no feature_visited keys / no meta_ui) never show NEW;
##   - Home: "NEW" pill on Shortcut_* / NavBadge_*, a real count wins, the press clears it,
##     locked entries never show NEW and never mark visited.
##
## Run: godot --headless --path . -s res://tests/m44_new_badge.gd

const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["rule_walk", "visit_clears", "persistence", "grandfather", "legacy_snapshot", "home_ui"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport

func _initialize() -> void:
	await process_frame
	_rule_walk()
	_visit_clears()
	_persistence()
	_grandfather()
	_legacy_snapshot()
	await _home_ui()
	_shutdown()
	_cleanup()
	_done()

func _fresh(tag: String):
	var a = AppState.new(_path(tag))
	a.bootstrap_new_profile()
	return a

func _rule_walk() -> void:
	print("[rule: fresh profile, NEW = unlocked and not visited]")
	var a = _fresh("walk")
	_ok(a.economy.ftue.is_new_profile() and HomeBadges.new_features(a).is_empty(), "fresh L1: no NEW")
	_walk_to(a, 4)
	_ok(HomeBadges.new_features(a) == ["daily"], "L4: daily NEW %s" % str(HomeBadges.new_features(a)))
	_walk_to(a, 7)
	_ok(HomeBadges.new_features(a) == ["daily"], "L7, daily unvisited: still only daily %s" % str(HomeBadges.new_features(a)))
	a.economy.meta_ui.mark_seen(HomeBadges.visited_key("daily"))
	_ok(HomeBadges.new_features(a).is_empty(), "L7, daily visited: empty")
	_walk_to(a, 8)
	_ok(HomeBadges.new_features(a) == ["shop"], "L8: shop NEW (unlock level 8) %s" % str(HomeBadges.new_features(a)))
	var b = _fresh("walk8")
	_walk_to(b, 8)
	var got: Array = HomeBadges.new_features(b)
	got.sort()
	_ok(got == ["daily", "shop"], "L8 nothing visited: daily + shop, nothing above L8 %s" % str(got))
	_walk_to(b, 40)
	got = HomeBadges.new_features(b)
	got.sort()
	_ok(got == ["collection", "daily", "events", "leaderboard", "robots", "shop", "tasks"], "L40: all seven entries NEW %s" % str(got))
	_complete("rule_walk")

func _visit_clears() -> void:
	print("[visit: marking shop visited removes only shop]")
	var a = _fresh("visit")
	_walk_to(a, 12)
	_ok(a.economy.meta_ui.mark_seen(HomeBadges.visited_key("shop")), "shop marked visited")
	var got: Array = HomeBadges.new_features(a)
	got.sort()
	_ok(got == ["daily", "tasks"], "shop gone, daily + tasks remain %s" % str(got))
	_complete("visit_clears")

func _persistence() -> void:
	print("[persistence: save, reload into a fresh AppState]")
	var p := _path("persist")
	var a = AppState.new(p)
	a.bootstrap_new_profile()
	_walk_to(a, 12)
	a.economy.meta_ui.mark_seen(HomeBadges.visited_key("shop"))
	_ok(bool(a.request_save()["ok"]), "save written")
	var re = AppState.new(p)
	var got: Array = HomeBadges.new_features(re)
	got.sort()
	_ok(re.economy.meta_ui.is_seen("feature_visited:shop") and got == ["daily", "tasks"], "reload: shop stays cleared, daily + tasks stay NEW %s" % str(got))
	_complete("persistence")

func _grandfather() -> void:
	print("[grandfather: established profile never shows NEW]")
	var est = AppState.new(_path("est"))
	var ok: bool = not est.economy.ftue.is_new_profile() and HomeBadges.new_features(est).is_empty()
	for lvl in [5, 8, 20, 40]:
		_walk_to(est, lvl)
		ok = ok and HomeBadges.new_features(est).is_empty()
	_ok(ok, "established: empty at L1, L5, L8, L20, L40")
	_complete("grandfather")

func _legacy_snapshot() -> void:
	print("[legacy: snapshots without feature_visited keys / without meta_ui]")
	var src = AppState.new(_path("legacy_src"))
	_walk_to(src, 40)
	var snap: Dictionary = src.economy.snapshot()
	snap.erase("ftue")
	var no_keys = AppState.new(_path("legacy_a"))
	_walk_to(no_keys, 40)
	_ok(no_keys.economy.import_snapshot(snap.duplicate(true)) and not snap["meta_ui"]["seen"].any(func(k): return String(k).begins_with("feature_visited:")), "pre-M44 snapshot with meta_ui, no feature_visited keys: imports")
	_ok(HomeBadges.new_features(no_keys).is_empty(), "  -> grandfathered, no NEW at L40")
	snap.erase("meta_ui")
	var no_meta = AppState.new(_path("legacy_b"))
	_walk_to(no_meta, 40)
	_ok(no_meta.economy.import_snapshot(snap.duplicate(true)), "legacy snapshot without meta_ui: imports")
	_ok(HomeBadges.new_features(no_meta).is_empty(), "  -> grandfathered, no NEW at L40")
	_complete("legacy_snapshot")

func _home_ui() -> void:
	print("[Home: NEW pill, count wins, press clears, locked never marks]")
	var new_text := UiText.t("HOME_BADGE_NEW")
	_ok(new_text == "NEW", "UiText HOME_BADGE_NEW == NEW")
	var hp := _path("home")
	var a = AppState.new(hp)
	a.bootstrap_new_profile()
	_walk_to(a, 8)
	var home = await _home(a)
	var shop = home.get_region("Shortcut_shop")
	_ok(shop.badge.visible and shop.badge.text == new_text, "L8: Shortcut_shop shows NEW")
	var daily = home.get_region("Shortcut_daily")
	_ok(daily.badge.visible and daily.badge.text == "1", "L8: DAILY count 1 (login claimable) wins over NEW, text '%s'" % daily.badge.text)
	var tasks = home.get_region("Shortcut_tasks")
	_ok(not tasks.badge.visible, "L8: locked TASKS shows no badge")
	home._shortcut_pressed("tasks")
	_ok(not a.economy.meta_ui.is_seen("feature_visited:tasks"), "locked TASKS press never marks visited")
	for nid in ["robots", "events"]:
		home.get_region("Nav_" + nid).pressed.emit()
	_ok(not a.economy.meta_ui.is_seen("feature_visited:robots") and not a.economy.meta_ui.is_seen("feature_visited:events") and not home.get_region("NavBadge_robots").visible, "locked ROBOTS / EVENTS: no badge, press never marks")
	home._shortcut_pressed("shop")
	_ok(not shop.badge.visible and a.economy.meta_ui.is_seen("feature_visited:shop"), "SHOP press: NEW hidden, visited marked")
	var re = AppState.new(hp)
	_ok(re.economy.meta_ui.is_seen("feature_visited:shop"), "press requested a canonical save (visited survives reload)")
	home._shortcut_pressed("daily")
	_ok(daily.badge.text == "1" and a.economy.meta_ui.is_seen("feature_visited:daily"), "DAILY press marks visited; its count badge stays")
	_walk_to(a, 30)
	home.refresh()
	var bd := HomeBadges.compute(a)
	for nid in ["robots", "events"]:
		var nl: Label = home.get_region("NavBadge_" + nid)
		var want: String = str(int(bd[nid])) if int(bd[nid]) > 0 else new_text
		_ok(nl.visible and nl.text == want, "L30: NavBadge_%s shows '%s'" % [nid, nl.text])
		home.get_region("Nav_" + nid).pressed.emit()
		_ok(a.economy.meta_ui.is_seen(HomeBadges.visited_key(nid)) and (int(bd[nid]) > 0 or not nl.visible), "Nav_%s press: visited, NEW hidden" % nid)
	_walk_to(a, 40)
	home.refresh()
	_ok(not home.get_region("NavBadge_leaderboard").visible, "L40: RANKS unserved (disabled) -> no NEW")
	var h2 = await _home(AppState.new(_path("home_est")))
	_ok(["shop", "collection", "tasks"].all(func(s): return not h2.get_region("Shortcut_" + s).badge.visible or h2.get_region("Shortcut_" + s).badge.text != new_text), "established profile Home: no NEW pill")
	_complete("home_ui")

# ------------------------------------------------------------------ helpers ----

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

func _home(app):
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var home = HomeScreenScene.instantiate()
	_sub.add_child(home)
	home.bind(app)
	home.set_app_shortcuts(MainScript.APP_SHORTCUTS)
	home.set_app_nav(MainScript.APP_NAV)
	await _frames(2)
	home.refresh()
	return home

func _shutdown() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = null

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _path(tag: String) -> String:
	var p := "user://m44_new_badge_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
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
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("M44 new badge evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
