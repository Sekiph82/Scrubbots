extends SceneTree
## SB-M44-032 + SB-M44-033 + SB-M44-031 part 2 (owner 2026-11-03) against the REAL services and
## the REAL app root (main.tscn), injected clock / local day:
##   - first Home at L1: Daily / Shop / Tasks / Collection / Card Packs / Achievements / Gift Bar
##     open, Robots 25 / Events 30 / Ranks 40 locked; the Daily coach tip at L1;
##   - gate bypass: deep link / direct nav entry, Shop + facade booster buy / watch, robot /
##     event actions refused while locked (nothing spent);
##   - boosters at the edge levels 5/6, 10/11, 15/16, 20/21: frosted plate + padlock + "LV N",
##     touch disabled, starter charges kept; Need a Hand never offers a locked booster;
##   - old / established / debug saves get the same gate (no grandfather), inventory kept;
##   - the 100 SB Welcome task: claimable at first Home, +100 once on claim (rapid taps),
##     durable across relaunch, gone after the local-day rollover, never re-granted;
##   - no Level-2 booster lesson; once-only per-booster intro at 6/11/16/21, saved across
##     retry / relaunch, never for a locked booster.
##
## Run: godot --headless --path . -s res://tests/m44_meta_l1_unlock_ftue.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")

const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
const BOOSTER_LEVEL := {"plus_one_slot": 6, "random": 11, "selector": 16, "tornado": 21}
const L1_OPEN := ["hearts", "gift_bar", "daily", "shop", "tasks", "collection", "card_packs", "achievements"]
const LOCKED_NAV := {"Nav_robots": 25, "Nav_events": 30, "Nav_leaderboard": 40}

var EXPECTED_CASES := ["first_home_l1_meta_open", "gate_bypass", "welcome_claim_once", "booster_edges",
	"old_save_same_gate", "booster_intro_once"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MainScript.boot_ftue_override = 1
	await _first_home()
	await _gate_bypass()
	await _welcome()
	await _booster_edges()
	_old_saves()
	await _booster_intro()
	_shutdown()
	_cleanup()
	_done()

func _first_home() -> void:
	print("[first Home L1: required meta open, Robots / Events / Ranks locked, Daily coach]")
	await _boot("home")
	var app = _root.get_app_state()
	var home = _root.get_home()
	_ok(app.economy.ftue.is_new_profile() and app.progression.current_level() == 1, "fresh profile at L1")
	_ok(L1_OPEN.all(func(id): return app.feature_unlocked(id)), "L1 unlocked: %s" % str(L1_OPEN))
	_ok(["robots", "events", "ranks"] + BOOSTERS == (["robots", "events", "ranks"] + BOOSTERS).filter(func(id): return not app.feature_unlocked(id)), "L1 locked: robots / events / ranks / four boosters")
	var sc_ok := true
	for id in ["daily", "tasks", "shop", "collection"]:
		var b: Button = home.get_region("Shortcut_" + id)
		sc_ok = sc_ok and not b.disabled and b.tooltip_text == ""
	_ok(sc_ok, "DAILY / TASKS / SHOP / COLLECTION enabled, no lock text")
	var nav_ok := true
	for n in LOCKED_NAV:
		var nb: Button = home.get_region(n)
		nav_ok = nav_ok and nb.disabled and nb.tooltip_text == UiText.t("HOME_UNLOCKS_AT_LEVEL", [LOCKED_NAV[n]])
	_ok(nav_ok, "ROBOTS 25 / EVENTS 30 / RANKS 40 disabled with their unlock level")
	_ok(not home.get_region("GiftMeterButton").disabled, "Gift Bar visible / enabled at L1")
	var bd: Dictionary = HomeBadges.compute(app)
	_ok(int(bd["daily"]) == 1 and int(bd["tasks"]) == 1, "Daily + Welcome task badges live at L1 %s" % str(bd))
	_root.refresh_coachmark()
	var cm = _root.get_coachmarks()
	_ok(cm.get_step_id() == "home_daily" and cm.get_target() == home.get_region("Shortcut_daily").get_global_rect(), "first-Home coach: DAILY tip on the real panel at L1")
	app.actions.claim_daily_login()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "home_tasks" and cm.get_target() == home.get_region("Shortcut_tasks").get_global_rect(), "then the TASKS (Welcome) tip on the real panel")
	_complete("first_home_l1_meta_open")

func _gate_bypass() -> void:
	print("[gate bypass: deep link / direct entry / Shop / facade refuse locked features]")
	await _boot("bypass")
	var app = _root.get_app_state()
	var ms = _root.get_modal_stack()
	_ok(_root.open_deep_link("robots") == "home" and ms.depth() == 0, "deep link to locked ROBOTS lands on Home, nothing opens")
	_root._on_home_nav("robots")
	_root._on_home_nav("events")
	_root._on_home_nav("leaderboard")
	_ok(ms.depth() == 0, "direct nav entry to ROBOTS / EVENTS / RANKS opens nothing while locked")
	_ok(_root.open_deep_link("tasks") == "tasks" and _top_id() == "tasks", "deep link to (L1) TASKS opens it")
	ms.clear("test")
	await _frames(2)
	_root._on_home_shortcut("shop")
	await _frames(2)
	var shop = _top().get_meta("shop_screen") if _top() != null and _top().has_meta("shop_screen") else null
	_ok(shop != null, "SHOP opens at L1")
	var rows_ok := true
	for id in BOOSTERS:
		var o: Dictionary = shop.offer("booster:" + id)
		var card = shop.popup.find_child("Item_booster_" + id, true, false)
		var detail: Label = card.find_child("Detail", true, false)
		rows_ok = rows_ok and not bool(o["available"]) and String(o["reason"]) == "locked" \
			and shop.popup.get_action_button("buy:booster:" + id).disabled \
			and detail.text == UiText.t("HOME_UNLOCKS_AT_LEVEL", [BOOSTER_LEVEL[id]])
	_ok(rows_ok, "Shop booster rows: not for sale, BUY blocked, 'Unlocks at level N'")
	_ok(bool(shop.offer("heart_plus_one")["available"]) or String(shop.offer("heart_plus_one")["reason"]) == "hearts_full", "Shop hearts row unaffected")
	ms.clear("test")
	var sb: int = app.economy.wallet.scrub_bucks()
	var ch := _charges(app)
	var reasons: Array = []
	for id in BOOSTERS:
		reasons.append(String(app.actions.buy_booster_charge(id).get("reason", "")))
		reasons.append(String(app.actions.start_rewarded(RewardedGrantService.booster_product(id)).get("reason", "")))
	reasons.append(String(app.actions.unlock_next_robot().get("reason", "")))
	reasons.append(String(app.actions.equip_robot(app.economy.robots.active_robot()).get("reason", "")))
	reasons.append(String(app.actions.join_first_try().get("reason", "")))
	reasons.append(String(app.actions.claim_first_try().get("reason", "")))
	_ok(reasons.all(func(r): return r == "locked"), "facade refuses locked booster buy / watch, robot unlock / equip, event join / claim %s" % str(reasons))
	_ok(app.economy.wallet.scrub_bucks() == sb and _charges(app) == ch, "nothing spent / granted")
	_walk_to(app, 11)
	var r: Dictionary = app.actions.buy_booster_charge("random")
	_ok(bool(r.get("ok", false)) and app.economy.boosters.charges("random") == 3, "L11: Random unlocked -> the same buy commits")
	_ok(String(app.actions.buy_booster_charge("selector").get("reason", "")) == "locked", "L11: Selector (16) still locked")
	_complete("gate_bypass")

func _welcome() -> void:
	print("[Welcome 100 SB: claimable at first Home, +100 once on claim, durable, never again]")
	var p := _path("welcome")
	await _boot("welcome", p)
	var app = _root.get_app_state()
	var sb0: int = app.economy.wallet.scrub_bucks()
	_ok(sb0 == 1000 and not app.economy.daily.task_claimed(0), "starting balance unchanged (1,000); nothing credited before the claim")
	_now[0] += 600
	_root.get_home().refresh()
	_ok(app.economy.wallet.scrub_bucks() == sb0, "Home refresh / time passing: still no welcome SB")
	_root.get_home().get_region("Shortcut_tasks").pressed.emit()
	await _frames(2)
	var tp = _top()
	_ok(_top_id() == "tasks" and tp.get_action_button("task:0").text == UiText.t("TASK_REWARD_SB", ["100"]) \
		and _txt_in(tp, "Task_0", "Text") == UiText.t("TASK_WELCOME") and not tp.get_action_button("task:0").disabled, "TASKS at L1: Welcome row active, 100 SB, CLAIM ready")
	for _i in range(5):
		tp._on_action("task:0")
	await _frames(2)
	_ok(app.economy.wallet.scrub_bucks() == sb0 + 100 and tp.get_action_button("task:0").text == UiText.t("TASK_CLAIMED"), "5 rapid taps: exactly +100 (1,100), row CLAIMED")
	_ok(app.economy.reward.already_applied("daily_task:%d:0" % _day[0]) and int(HomeBadges.compute(app)["tasks"]) == 0, "one ledger tx, badge cleared")
	_ok(not app.actions.claim_daily_task(0)["ok"] and app.economy.wallet.scrub_bucks() == 1100, "replayed claim refused")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_root.get_home().get_region("Shortcut_tasks").pressed.emit()
	await _frames(2)
	_ok(_top_id() == "tasks" and _top().get_action_button("task:0").text == UiText.t("TASK_CLAIMED") and _top().get_action_button("task:0").disabled \
		and app.economy.wallet.scrub_bucks() == 1100, "exit + re-enter TASKS: Welcome row CLAIMED, blocked, no new grant")
	_shutdown()
	var est = _app(_path("welcome_est"))
	_ok(est.feature_unlocked("tasks") and not est.economy.daily.is_welcome_task(0) and est.economy.daily.task_reward_sb(0) == 75 \
		and not est.actions.claim_daily_task(0)["ok"], "existing (established) save: Tasks open, ordinary tasks, no Welcome / grant")
	var re = _app(p)
	_ok(re.economy.wallet.scrub_bucks() == 1100 and re.economy.daily.task_claimed(0) and not re.actions.claim_daily_task(0)["ok"], "relaunch: 1,100 kept, claim refused")
	_ok(bool(re.bootstrap_new_profile().get("replay", false)) and re.economy.wallet.scrub_bucks() == 1100, "bootstrap replay: no second Welcome")
	_day[0] += 1
	_now[0] += 86400
	var nd = _app(p)
	_ok(not nd.economy.daily.is_welcome_task(0) and nd.economy.daily.task_reward_sb(0) == 75 and not nd.actions.claim_daily_task(0)["ok"] and nd.economy.wallet.scrub_bucks() == 1100, "day rollover: ordinary Daily Tasks (75 SB slot), no Welcome, no grant")
	var snap: Dictionary = nd.economy.snapshot()
	_ok(nd.economy.import_snapshot(snap) and not nd.economy.daily.set_first_day_welcome(nd.economy.daily.local_day(), 100), "snapshot re-import (cloud / migration path): the Welcome cannot be installed again")
	_day[0] -= 1
	_now[0] -= 86400
	_complete("welcome_claim_once")

func _booster_edges() -> void:
	print("[boosters at 5/6, 10/11, 15/16, 20/21: locked plate + LV N, charges kept, then usable]")
	await _boot("edges")
	var app = _root.get_app_state()
	for id in BOOSTERS:
		var lvl: int = BOOSTER_LEVEL[id]
		for f in [lvl - 1, lvl]:
			await _play_at(app, f)
			var host = _root.get_gameplay_host()
			var b: Button = host.get_screen().get_booster_button(id)
			var plate: Control = b.get_node("LockedPlate")
			var st: Dictionary = host.booster_states().filter(func(s): return s["id"] == id)[0]
			var locked: bool = f < lvl
			_ok((String(st["state"]) == "locked") == locked and int(st["unlock_level"]) == lvl, "L%d %s state %s" % [f, id, String(st["state"])])
			if locked:
				_ok(b.disabled and plate.visible and (b.get_node("LockedPlate/LockedLevel") as Label).text == "LV %d" % lvl \
					and (b.get_node("LockedPlate/LockIcon") as TextureRect).texture != null and b.tooltip_text == UiText.t("HOME_UNLOCKS_AT_LEVEL", [lvl]) \
					and not b.get_node("UnavailableOverlay").visible, "L%d %s: frosted plate, padlock, 'LV %d', touch disabled" % [f, id, lvl])
				var sb: int = app.economy.wallet.scrub_bucks()
				var c: int = app.economy.boosters.charges(id)
				_ok(String(host.request_booster(id).get("reason", "")) == "locked" and app.economy.boosters.charges(id) == c and app.economy.wallet.scrub_bucks() == sb \
					and _root.get_modal_stack().depth() == 0, "L%d %s press: refused, no popup, charges %d / SB kept" % [f, id, c])
				_ok(not bool(host.next_start_prover().call(id)), "L%d %s: never a Need a Hand pick" % [f, id])
			else:
				_ok(not b.disabled and not plate.visible and b.tooltip_text == "", "L%d %s: unlocked, plate gone" % [f, id])
	_ok(_charges(app) == [2, 2, 2, 2], "starter 2 charges each kept through every lock (none used)")
	_complete("booster_edges")

func _old_saves() -> void:
	print("[old / established / debug saves: the same gate, inventory never wiped]")
	var p := _path("old")
	var a = _app(p)
	_ok(not a.economy.ftue.is_new_profile(), "established (pre-FTUE) save")
	_ok(a.economy.reward.grant("test_old_save_charges", {RewardedGrantService.RES_BOOSTER_PREFIX + "random": 3, RewardedGrantService.RES_BOOSTER_PREFIX + "tornado": 1}), "old save holds 3 Random + 1 Tornado")
	_walk_to(a, 3)
	_ok(bool(a.request_save()["ok"]), "saved at L3")
	var b = _app(p)
	_ok(not b.economy.ftue.is_new_profile() and b.progression.current_level() == 3, "reloaded established L3")
	_ok(L1_OPEN.all(func(id): return b.feature_unlocked(id)) and BOOSTERS.all(func(id): return not b.feature_unlocked(id)) \
		and not b.feature_unlocked("robots"), "established L3: meta open, boosters / Robots locked (no grandfather)")
	_ok(b.economy.boosters.charges("random") == 3 and b.economy.boosters.charges("tornado") == 1, "locked charges kept, not wiped")
	_walk_to(b, 30)
	_ok(b.feature_unlocked("robots") and b.feature_unlocked("events") and not b.feature_unlocked("ranks") and BOOSTERS.all(func(id): return b.feature_unlocked(id)), "established L30: Robots / Events / boosters open, Ranks (40) locked")
	_ok(b.economy.boosters.charges("random") == 3, "charges still 3")
	var d = _app(_path("debug"))
	d.progression.debug_set_current_level(16)
	_ok(d.feature_unlocked("selector") and not d.feature_unlocked("tornado"), "debug frontier L16: the same table (Selector open, Tornado locked)")
	_complete("old_save_same_gate")

func _booster_intro() -> void:
	print("[no L2 booster lesson; once-only per-booster intros at 6 / 11 / 16 / 21]")
	var a = _app(_path("intro_dir"))
	a.bootstrap_new_profile()
	var dr = FtueDirector.new(a)
	var lessons: Array = dr.config()["lessons"]
	_ok(lessons.all(func(l): return (l["steps"] as Array).all(func(s): return not s.has("boosters"))) \
		and lessons.map(func(l): return String(l["id"])) == ["home_welcome", "l1_core_loop", "l3_rules"], "lessons: L1 Home / L1 core loop / L3 speed only (l2_boosters removed)")
	_walk_to(a, 2)
	_ok(dr.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"}).is_empty(), "L2: no booster lesson")
	var seen: Array = []
	for f in [5, 6, 10, 11, 15, 16, 20, 21]:
		_walk_to(a, f)
		var st: Dictionary = dr.booster_intro_step()
		if not st.is_empty():
			seen.append([f, String(st["id"])])
			_ok(st["boosters"].size() == 1 and a.feature_unlocked(String(st["boosters"][0])), "L%d intro is for an unlocked booster %s" % [f, str(st["boosters"])])
			_ok(dr.acknowledge(String(st["id"])) and dr.booster_intro_step().is_empty(), "L%d: acknowledged once, nothing else due" % f)
	_ok(seen == [[6, "intro_plus_one_slot"], [11, "intro_random"], [16, "intro_selector"], [21, "intro_tornado"]], "intros exactly at 6 / 11 / 16 / 21 %s" % str(seen))
	_ok(FtueDirector.new(_app(_path("intro_est"))).booster_intro_step().is_empty(), "established profile: no intro tips")
	var s = _app(_path("intro_skip"))
	s.bootstrap_new_profile()
	var ds = FtueDirector.new(s)
	_walk_to(s, 6)
	ds.settle()
	_ok(s.economy.ftue.closed and not ds.booster_intro_step().is_empty() and ds.skip_tips() and ds.booster_intro_step().is_empty(), "optional: Skip Tips after the L1-L3 window dismisses intros")
	print("  [real gameplay at L6]")
	var p := _path("intro_ui")
	await _boot("intro_ui", p)
	var app = _root.get_app_state()
	await _play_at(app, 6)
	_root.refresh_coachmark()
	var cm = _root.get_coachmarks()
	var host = _root.get_gameplay_host()
	var btn: Button = host.get_screen().get_booster_button("plus_one_slot")
	var body: String = cm.get_body_label().text
	_ok(cm.get_step_id() == "intro_plus_one_slot" and cm.get_target() == btn.get_global_rect() and body.contains(UiText.t("BOOSTER_NAME_PLUS_ONE_SLOT")) and body.contains("owned: 2") \
		and cm.get_title_label().text == UiText.t("FTUE_BOOSTER_INTRO_TITLE"), "L6 first gameplay: +1 Slot intro on the real unlocked button, live count")
	_ok(_charges(app) == [2, 2, 2, 2] and not app.economy.ftue.is_seen("intro_plus_one_slot"), "showing it spends nothing, not yet acknowledged")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(not cm.is_showing() and app.economy.ftue.is_seen("intro_plus_one_slot"), "GOT IT: dismissed, introduced flag set")
	await _play_at(app, 6)
	_root.refresh_coachmark()
	_ok(not cm.is_showing(), "retry: not shown again")
	_shutdown()
	await _boot("intro_ui2", p)
	await _play_at(_root.get_app_state(), 6)
	_root.refresh_coachmark()
	_ok(_root.get_app_state().economy.ftue.is_seen("intro_plus_one_slot") and not _root.get_coachmarks().is_showing(), "relaunch: flag persisted, not shown again")
	_complete("booster_intro_once")

# ------------------------------------------------------------------ helpers ----

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

func _play_at(app, level: int) -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	if nav.current() != NavigationController.Route.HOME:
		nav.go(NavigationController.Route.HOME)
		await _frames(2)
	_root.get_modal_stack().clear("test")
	_walk_to(app, level)
	_root.play_current_frontier()
	await _frames(6)
	var h = _root.get_gameplay_host()
	if h != null:
		h.get_runtime().set_process(false)
		_root.get_modal_stack().clear("test")

func _charges(app) -> Array:
	return BOOSTERS.map(func(id): return int(app.economy.boosters.charges(id)))

func _app(path: String):
	return AppState.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)

func _boot(tag: String, path := "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path if not path.is_empty() else _path("boot_" + tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _txt_in(p, parent: String, n: String) -> String:
	var c = p.find_child(parent, true, false)
	var l = c.find_child(n, true, false) if c != null else null
	return l.text if l is Label else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _path(tag: String) -> String:
	var p := "user://m44_meta_l1_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	MainScript.boot_ftue_override = -1
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("M44 meta L1 unlock + FTUE evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
