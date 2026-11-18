extends SceneTree
## SB-M44-013 — NEW badge on newly unlocked Home entries until first visit:
##   - HomeBadges.new_features: unlocked + unvisited gated entries of a NEW FTUE profile only;
##   - visiting (meta_ui "feature_visited:<feature>") clears it and survives save / reload;
##   - grandfathered profiles and legacy snapshots (no feature_visited keys / no meta_ui) never show NEW;
##   - Home: "NEW" pill on the activity buttons, a real count wins, the press clears it,
##     locked entries never show NEW and never mark visited. SB-TF-03: Robots / Ranks / Collection
##     moved into Profile, so their NEW shows on the Home profile card and on the Profile button
##     (whose press clears it); Events NEW shows on the Event activity buttons.
## SB-M44-032: entries open at L1 (shipped: Daily / Shop / Tasks / Collection) were never
## "newly unlocked", so they never show NEW (shipped_table case). The mechanism cases run on an
## in-memory fixture table with those four at their 2026-10-22 levels (LEGACY_LEVELS).
##
## Run: godot --headless --path . -s res://tests/m44_new_badge.gd

const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["rule_walk", "visit_clears", "persistence", "grandfather", "legacy_snapshot", "home_ui", "shipped_table"]
const LEGACY_LEVELS := {"daily": 4, "shop": 8, "tasks": 12, "collection": 20}

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
	_shipped_table()
	_shutdown()
	_cleanup()
	_done()

func _fresh(tag: String):
	var a = AppState.new(_path(tag))
	a.bootstrap_new_profile()
	return _legacy(a)

## Fixture seam (in-memory only): the four Home shortcuts at their 2026-10-22 levels.
func _legacy(app):
	for id in LEGACY_LEVELS:
		app.unlocks.cfg["unlocks"][id] = LEGACY_LEVELS[id]
	return app

func _shipped_table() -> void:
	print("[shipped table: L1 entries never NEW; ROBOTS NEW at L25]")
	var a = AppState.new(_path("shipped"))
	a.bootstrap_new_profile()
	_ok(a.feature_unlocked("daily") and a.feature_unlocked("shop") and HomeBadges.new_features(a).is_empty(), "fresh L1 (Daily / Shop / Tasks / Collection open): no NEW")
	_walk_to(a, 25)
	_ok(HomeBadges.new_features(a) == ["robots"], "L25: only ROBOTS NEW %s" % str(HomeBadges.new_features(a)))
	_complete("shipped_table")

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
	var a = _legacy(AppState.new(p))
	a.bootstrap_new_profile()
	_walk_to(a, 12)
	a.economy.meta_ui.mark_seen(HomeBadges.visited_key("shop"))
	_ok(bool(a.request_save()["ok"]), "save written")
	var re = _legacy(AppState.new(p))
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
	var a = _legacy(AppState.new(hp))
	a.bootstrap_new_profile()
	_walk_to(a, 8)
	var home = await _home(a)
	_ok(home.get_region("Shortcut_shop") == null and HomeBadges.new_features(a).has("shop"), "L8: SHOP is new but has no Home tile (SB-TF-03: Shop opens from the (+) popups)")
	var pb: Label = home.get_region("ProfileBadge")
	_ok(pb.text != new_text, "L8: no Profile destination is new yet -> no NEW on the profile card ('%s' = achievement count only)" % pb.text)
	var daily = home.get_region("Shortcut_daily")
	_ok(daily.badge.visible and daily.badge.text == "1", "L8: DAILY count 1 (login claimable) wins over NEW, text '%s'" % daily.badge.text)
	var tasks = home.get_region("Shortcut_tasks")
	_ok(not tasks.badge.visible, "L8: locked TASKS shows no badge")
	home._shortcut_pressed("tasks")
	_ok(not a.economy.meta_ui.is_seen("feature_visited:tasks"), "locked TASKS press never marks visited")
	for nid in ["robots", "event:x"]:
		home._shortcut_pressed(nid)
	_ok(not a.economy.meta_ui.is_seen("feature_visited:robots") and not a.economy.meta_ui.is_seen("feature_visited:events"), "locked ROBOTS / EVENTS: press never marks")
	_walk_to(a, 20)
	home.refresh()
	var cnt := int(HomeBadges.compute(a)["achievements"]) + int(HomeBadges.compute(a)["robots"]) + int(HomeBadges.compute(a)["collection"])
	_ok(HomeBadges.new_features(a).has("collection") and pb.visible and pb.text == (str(cnt) if cnt > 0 else new_text), "L20: COLLECTION newly unlocked -> profile card shows NEW, a real count wins ('%s')" % pb.text)
	var p = await _profile(a)
	var cb: Label = p.get_action_button("collection").get_node("CollectionBadge")
	_ok(cb.visible and cb.text == new_text, "L20: Profile COLLECTION shows NEW")
	p._on_action("collection")
	_ok(a.economy.meta_ui.is_seen("feature_visited:collection"), "Profile COLLECTION press: visited marked")
	var re = AppState.new(hp)
	_ok(re.economy.meta_ui.is_seen("feature_visited:collection"), "press requested a canonical save (visited survives reload)")
	home.refresh()
	_ok(pb.text != new_text and not HomeBadges.new_features(a).has("collection"), "profile card NEW cleared ('%s')" % pb.text)
	home._shortcut_pressed("daily")
	_ok(daily.badge.text == "1" and a.economy.meta_ui.is_seen("feature_visited:daily"), "DAILY press marks visited; its count badge stays")
	_walk_to(a, 30)
	home.refresh()
	var bd := HomeBadges.compute(a)
	p = await _profile(a)
	var rb: Label = p.get_action_button("robots").get_node("RobotsBadge")
	var want: String = str(int(bd["robots"])) if int(bd["robots"]) > 0 else new_text
	_ok(rb.visible and rb.text == want, "L30: Profile ROBOTS shows '%s'" % rb.text)
	_ok(pb.visible and pb.text == (str(int(bd["robots"]) + int(bd["achievements"])) if int(bd["robots"]) + int(bd["achievements"]) > 0 else new_text), "L30: profile card shows the count or NEW ('%s')" % pb.text)
	p._on_action("robots")
	_ok(a.economy.meta_ui.is_seen(HomeBadges.visited_key("robots")), "Profile ROBOTS press: visited")
	var ev: Array = home.find_children("Shortcut_event_*", "", true, false)
	if not ev.is_empty():
		_ok((ev[0] as Button).get("badge").text == new_text or int(bd["events"]) > 0, "L30: Event button shows NEW")
		home._shortcut_pressed("event:" + String(ev[0].get_meta("iid")))
	else:
		home._shortcut_pressed("event:none")
	_ok(a.economy.meta_ui.is_seen(HomeBadges.visited_key("events")), "an Event button press marks EVENTS visited")
	_walk_to(a, 40)
	home.refresh()
	# SB-M43-122: RANKS (personal rank ladder) gets NEW like any unlocked entry, now in Profile.
	p = await _profile(a)
	var rl: Label = p.get_action_button("ranks").get_node("RanksBadge")
	_ok(rl.visible and rl.text == new_text, "L40: Profile RANKS shows NEW, text '%s'" % rl.text)
	p._on_action("ranks")
	_ok(a.economy.meta_ui.is_seen(HomeBadges.visited_key("ranks")), "Profile RANKS press: visited")
	p = await _profile(a)
	_ok(not p.get_action_button("ranks").get_node("RanksBadge").visible, "reopened Profile: RANKS NEW hidden")
	var h2 = await _home(AppState.new(_path("home_est")))
	_ok(["tasks", "daily"].all(func(s): return not h2.get_region("Shortcut_" + s).badge.visible or h2.get_region("Shortcut_" + s).badge.text != new_text) and h2.get_region("ProfileBadge").text != new_text, "established profile Home: no NEW pill")
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
	await _frames(2)
	home.refresh()
	return home

## A real Profile popup on its own ModalStack (closes the previous one).
var _stack = null
func _profile(app):
	if _stack != null and is_instance_valid(_stack):
		_stack.queue_free()
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	var p = ProfileScreens.open_profile(_stack, app)
	await _frames(2)
	return p

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
