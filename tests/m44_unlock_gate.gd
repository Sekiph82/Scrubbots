extends SceneTree
## SB-M44-031 part 1 — owner feature unlock gate (data/config/feature_unlocks_v1.json):
##   - strict reader, fail-open on missing / malformed config and unknown ids;
##   - fresh-profile level walk via record_win: exact locked set at every listed frontier;
##   - grandfather: an established (not new FTUE) save keeps every feature;
##   - Home shortcuts / nav tabs locked with unlock-level text, no badge, no navigation;
##   - booster bar "locked" with charges untouched; a locked press does nothing;
##   - FTUE director never points at a locked control; the L1-L3 window still closes at L3.
##
## Run: godot --headless --path . -s res://tests/m44_unlock_gate.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const FeatureUnlocks = preload("res://scripts/progression/feature_unlocks.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const UiText = preload("res://scripts/ui/ui_text.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

## The owner table (TASKS.md SB-M44-010), restated here so a silent config edit fails.
const OWNER_TABLE := {"hearts": 1, "gift_bar": 1, "daily": 4, "shop": 8, "tasks": 12, "collection": 20,
	"card_packs": 20, "robots": 25, "events": 30, "achievements": 35, "ranks": 40,
	"plus_one_slot": 6, "random": 11, "selector": 16, "tornado": 21}
const WALK := [1, 3, 4, 5, 6, 8, 11, 12, 16, 20, 21, 25, 30, 35, 39, 40]
const HOME_ENTRIES := ["Shortcut_daily", "Shortcut_tasks", "Shortcut_shop", "Shortcut_collection", "Nav_robots", "Nav_events", "Nav_leaderboard"]

var EXPECTED_CASES := ["config_reader", "level_walk", "grandfather", "home_gating", "booster_gating", "ftue_director"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	_config_reader()
	_level_walk()
	_grandfather()
	await _home_gating()
	await _booster_gating()
	_ftue_director()
	_shutdown()
	_cleanup()
	_done()

func _config_reader() -> void:
	print("[config reader: owner table exact, fail open]")
	var u = FeatureUnlocks.new()
	var c: Dictionary = u.load_config()
	_ok(bool(c["ok"]) and c["unlocks"] == OWNER_TABLE, "shipped config == owner table %s" % str(c))
	var raw = JSON.parse_string(FileAccess.get_file_as_string(FeatureUnlocks.PATH))
	_ok(typeof(raw) == TYPE_DICTIONARY, "feature_unlocks_v1.json parses as JSON")
	var ids: Array = BoosterInventory.BOOSTERS.filter(func(b): return OWNER_TABLE.has(b))
	_ok(ids.size() == 4, "booster ids equal BoosterInventory.BOOSTERS")
	_ok(u.is_unlocked("no_such_feature", 1, false) and u.unlock_level("no_such_feature") == 1, "unknown id -> unlocked")
	var bads := [null, {}, {"schema": "x", "version": 1, "unlocks": {"daily": 4}},
		{"schema": FeatureUnlocks.SCHEMA, "version": 2, "unlocks": {"daily": 4}},
		{"schema": FeatureUnlocks.SCHEMA, "version": 1, "unlocks": {"daily": 0}},
		{"schema": FeatureUnlocks.SCHEMA, "version": 1, "unlocks": {"daily": "4"}},
		{"schema": FeatureUnlocks.SCHEMA, "version": 1, "unlocks": {"daily": 4.5}},
		{"schema": FeatureUnlocks.SCHEMA, "version": 1, "unlocks": []}]
	_ok(bads.all(func(d): return not bool(FeatureUnlocks.validate(d)["ok"])), "malformed tables rejected")
	var p := _path("bad") + ".json"
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("{\"schema\": \"%s\", \"version\": 1, \"unlocks\": {\"daily\": -3}}" % FeatureUnlocks.SCHEMA)
	f.close()
	var bad = FeatureUnlocks.new()
	var missing = FeatureUnlocks.new()
	_ok(not bool(bad.load_config(p)["ok"]) and not bool(missing.load_config("res://no/such.json")["ok"]), "malformed / missing file: ok:false")
	_ok(OWNER_TABLE.keys().all(func(id): return bad.is_unlocked(id, 1, false) and missing.is_unlocked(id, 1, false)), "malformed / missing config: all 15 unlocked at L1 (fail open)")
	_complete("config_reader")

func _level_walk() -> void:
	print("[level walk: fresh profile, record_win from L1, exact locked set]")
	var p := _path("walk")
	var a = AppState.new(p)
	_ok(bool(a.bootstrap_new_profile()["ok"]) and a.economy.ftue.is_new_profile(), "fresh profile bootstrapped")
	var all_ok := true
	for frontier in WALK:
		while a.progression.current_level() < frontier:
			a.progression.record_win(a.progression.current_level())
		var got := {}
		var want := {}
		for id in OWNER_TABLE:
			got[id] = a.feature_unlocked(id)
			want[id] = frontier >= int(OWNER_TABLE[id])
		var ok: bool = a.progression.current_level() == frontier and got == want
		all_ok = all_ok and ok
		_ok(ok, "L%d unlocked = %s" % [frontier, str(OWNER_TABLE.keys().filter(func(id): return got[id]))])
	_ok(all_ok, "every frontier matches the table (incl. L3/L4, L5/L6, L11/L12, L39/L40)")
	_ok(bool(a.request_save()["ok"]), "walked save written")
	var re = AppState.new(p)
	_ok(re.economy.ftue.is_new_profile() and re.progression.current_level() == 40 and OWNER_TABLE.keys().all(func(id): return re.feature_unlocked(id)), "relaunch at L40: still new profile, everything unlocked (frontier never drops)")
	_complete("level_walk")

func _grandfather() -> void:
	print("[grandfather: established save keeps every feature]")
	var est = AppState.new(_path("est"))
	_ok(not est.economy.ftue.is_new_profile() and est.progression.current_level() == 1, "established L1 save (not a new FTUE profile)")
	_ok(OWNER_TABLE.keys().all(func(id): return est.feature_unlocked(id)), "established L1: all 15 unlocked")
	var fresh = AppState.new(_path("fresh"))
	fresh.bootstrap_new_profile()
	var open: Array = OWNER_TABLE.keys().filter(func(id): return fresh.feature_unlocked(id))
	open.sort()
	_ok(open == ["gift_bar", "hearts"], "fresh L1: only hearts + gift_bar %s" % str(open))
	_complete("grandfather")

func _home_gating() -> void:
	print("[Home: locked entries disabled with unlock level, no badge, no navigation]")
	var a = AppState.new(_path("home"))
	a.bootstrap_new_profile()
	var home = await _home(a)
	var emitted: Array = []
	home.shortcut_requested.connect(func(id): emitted.append(id))
	home.nav_requested.connect(func(id): emitted.append(id))
	_ok(HOME_ENTRIES.all(func(n): return home.get_region(n).disabled), "fresh L1: daily / tasks / shop / collection / robots / events / ranks disabled")
	var texts_ok := true
	for n in HOME_ENTRIES:
		var fid: String = "ranks" if n == "Nav_leaderboard" else n.get_slice("_", 1)
		texts_ok = texts_ok and home.get_region(n).tooltip_text == UiText.t("HOME_UNLOCKS_AT_LEVEL", [OWNER_TABLE[fid]])
	_ok(texts_ok and home.get_region("Shortcut_daily").tooltip_text == "Unlocks at level 4", "each shows its table unlock level")
	_ok(not home.get_region("Shortcut_daily").badge.visible and not home.get_region("Shortcut_tasks").badge.visible and not home.get_region("NavBadge_robots").visible, "locked entries carry no badge (daily claimable / welcome task ready)")
	_ok(not home.get_region("GiftMeterButton").disabled, "Gift Bar stays enabled at L1")
	for id in ["daily", "tasks", "shop", "collection"]:
		home._shortcut_pressed(id)
	for id in ["robots", "events", "leaderboard"]:
		home.get_region("Nav_" + id).pressed.emit()
	_ok(emitted.is_empty(), "locked press: no shortcut_requested / nav_requested")
	_walk_to(a, 4)
	home.refresh()
	var en := HOME_ENTRIES.filter(func(n): return not home.get_region(n).disabled)
	_ok(en == ["Shortcut_daily"] and home.get_region("Shortcut_daily").tooltip_text == "", "L4: only DAILY enabled %s" % str(en))
	_ok(home.get_region("Shortcut_daily").badge.visible, "L4: DAILY badge back (login claimable)")
	_walk_to(a, 12)
	home.refresh()
	en = HOME_ENTRIES.filter(func(n): return not home.get_region(n).disabled)
	_ok(en == ["Shortcut_daily", "Shortcut_tasks", "Shortcut_shop"], "L12: DAILY / TASKS / SHOP enabled %s" % str(en))
	home._shortcut_pressed("tasks")
	_ok(emitted == ["tasks"], "unlocked TASKS press emits shortcut_requested")
	_walk_to(a, 40)
	home.refresh()
	en = HOME_ENTRIES.filter(func(n): return not home.get_region(n).disabled)
	_ok(en.size() == 6 and home.get_region("Nav_leaderboard").tooltip_text == UiText.t("HOME_COMING_LATER"), "L40: all served entries enabled; RANKS back to coming-later")
	var est = AppState.new(_path("home_est"))
	var h2 = await _home(est)
	en = HOME_ENTRIES.filter(func(n): return not h2.get_region(n).disabled)
	_ok(en.size() == 6 and HOME_ENTRIES.all(func(n): return n == "Nav_leaderboard" or h2.get_region(n).tooltip_text == "") and h2.get_region("Nav_leaderboard").tooltip_text == UiText.t("HOME_COMING_LATER"), "established L1 save: Home exactly as before %s" % str(en))
	_shutdown()
	_complete("home_gating")

func _booster_gating() -> void:
	print("[boosters: locked over every state, charges kept, locked press inert]")
	await _boot("boost")
	var app = _root.get_app_state()
	_ok(app.economy.ftue.is_new_profile() and _charges(app) == [2, 2, 2, 2], "fresh boot: new profile, 2 charges each")
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var st: Array = host.booster_states()
	_ok(st.size() == 4 and st.all(func(s): return String(s["state"]) == "locked" and int(s["charges"]) == 2), "L1: all four locked, charges 2 each %s" % str(st))
	_ok(BoosterInventory.BOOSTERS.all(func(id): return host.get_screen().get_booster_button(id).disabled), "L1: booster buttons disabled")
	var sb: int = app.economy.wallet.scrub_bucks()
	var reasons: Array = []
	for id in BoosterInventory.BOOSTERS:
		reasons.append(String(host.request_booster(id).get("reason", "")))
		reasons.append(String(host.execute_booster(id, 0).get("reason", "")))
	_ok(reasons.all(func(r): return r == "locked") and _charges(app) == [2, 2, 2, 2] and app.economy.wallet.scrub_bucks() == sb and host.get_attempt_boosters_used() == 0, "locked press / execute: nothing happens, charges + SB unchanged %s" % str(reasons))
	var steps := {6: ["random", "selector", "tornado"], 11: ["selector", "tornado"], 16: ["tornado"], 21: []}
	for lvl in steps:
		_walk_to(app, lvl)
		var locked: Array = host.booster_states().filter(func(s): return String(s["state"]) == "locked").map(func(s): return String(s["id"]))
		_ok(locked == steps[lvl] and _charges(app) == [2, 2, 2, 2], "L%d locked %s" % [lvl, str(locked)])
	_shutdown()
	_complete("booster_gating")

func _ftue_director() -> void:
	print("[FTUE: no coachmark on a locked control; the L1-L3 window still closes at L3]")
	var a = AppState.new(_path("ftue"))
	a.bootstrap_new_profile()
	var d = FtueDirector.new(a)
	var ctx: Dictionary = d.home_context()
	ctx["daily_claimable"] = true
	ctx["tasks_claimable"] = true
	_ok(String(d.current_step("home", ctx).get("id", "")) == "home_play", "fresh L1 Home: PLAY tip, never DAILY / TASKS")
	_ok(not a.economy.ftue.is_seen("home_daily") and not a.economy.ftue.is_seen("home_tasks"), "skipped steps are not marked seen")
	_ok(d.notify("play", "home", ctx) and d.current_step("home", ctx).is_empty(), "PLAY tip completes; nothing locked offered after")
	_ok(String(d.current_step("gameplay", {"level": 1, "level_id": "m21_level_001_hazard_bot"}).get("id", "")) == "l1_tap_front", "L1 lesson runs")
	a.progression.record_win(1)
	_ok(d.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"}).is_empty() and not a.economy.ftue.is_seen("l2_boosters_a") and not a.economy.ftue.is_seen("l2_boosters_b"), "L2: all four boosters locked -> both booster steps skipped, not seen")
	a.unlocks.cfg["unlocks"]["plus_one_slot"] = 1
	var part: Dictionary = d.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"})
	_ok(String(part.get("id", "")) == "l2_boosters_a" and part["boosters"] == ["plus_one_slot"], "a step keeps only its unlocked boosters %s" % str(part.get("boosters")))
	a.unlocks.cfg["unlocks"]["plus_one_slot"] = 6
	a.progression.record_win(2)
	_ok(String(d.current_step("gameplay", {"level": 3, "level_id": "level_003_palm_tree"}).get("id", "")) == "l3_speed", "L3 lesson runs")
	_ok(not d.settle() and not a.economy.ftue.closed, "window open during L3")
	a.progression.record_win(3)
	_ok(d.settle() and a.economy.ftue.closed and not d.tips_active(), "L3 Results: window closes exactly as before")
	_complete("ftue_director")

# ------------------------------------------------------------------ helpers ----

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

func _charges(app) -> Array:
	return BoosterInventory.BOOSTERS.map(func(id): return int(app.economy.boosters.charges(id)))

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

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _path("boot_" + tag)
	MainScript.boot_ftue_override = 1
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _shutdown() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = null
	_root = null

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _path(tag: String) -> String:
	var p := "user://m44_unlock_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_ftue_override = -1
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
	print("M44 unlock gate evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
