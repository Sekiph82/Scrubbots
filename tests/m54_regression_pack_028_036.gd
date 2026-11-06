extends SceneTree
## M54 regression pack SB-M54-028..030 + 033..036: the cases the existing suites did not assert
## (coverage map: factory/jobs/125-regressions-tasks-nav-ftue/build.md).
##   028 Home badge counts = HomeBadges = the claim state, across claims, relaunch and a new day;
##       claimed Tasks / ScrubBox / Daily / Gift never come back after a relaunch.
##   029 BottomNav tabs: a double tap opens one destination; popup over popup closes LIFO on back;
##       Settings overlay closes on back; Home stays put.
##   030 FTUE once-only across a cloud restore onto a fresh device: acknowledged booster intro /
##       contextual tip stay seen, the bootstrap is a replay (no second starter grant), the next
##       intro still comes at its own level.
##   034 earned-pack pity: a duplicate reward-source grant queues one pack, a replayed open counts
##       once, the sprint counter and its guarantee survive relaunch and a cloud restore.
##   035 Weekly Event progress / claimed milestone, First-Try run and Personal Bests persist across
##       a local-day rollover and a relaunch; a replay after the relaunch farms nothing.
##   036 Comeback window vs reminder preferences: a genuine absence opens the window and leaves the
##       saved toggles / last-sent untouched; Catch-Up wins never change them; a rolled-back clock
##       opens no window and does not lift the 24 h cap.
## Real app root (main.tscn) on throw-away saves where a surface is involved; injected clock + day.
##
## Run: godot --headless --path . -s res://tests/m54_regression_pack_028_036.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const CloudSave = preload("res://scripts/save/cloud_save.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000
const DAY0 := 21_000
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]

var EXPECTED_CASES := [
	"m028_badges_claims_relaunch", "m028_badges_next_day",
	"m029_tab_double_tap_one", "m029_modal_lifo_back", "m029_settings_back",
	"m030_ftue_once_cloud_restore",
	"m034_pity_source_idempotent", "m034_pity_relaunch_cloud",
	"m035_event_rollover_relaunch", "m035_replay_after_relaunch",
	"m036_comeback_keeps_reminders", "m036_rollback_no_window_cap",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _day := [DAY0]
var _sub: SubViewport
var _root
var _save := ""

func _initialize() -> void:
	AppState.test_unlock_all = true
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _m028()
	await _m029()
	_m030()
	_m034()
	await _m035()
	await _m036()
	_shutdown()
	AppState.test_unlock_all = false
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ 028 ----

func _m028() -> void:
	print("[028 badge counts across claims, relaunch and a new local day]")
	_reset_clock()
	await _boot()
	var a = _root.get_app_state()
	var e = a.economy
	for i in range(3):
		e.daily.mark_task_done(i)
	e.gift.add_streak_sb("m028", 60)   # crosses Gift milestones 1 / 5 / 10 / 25
	a.request_save()
	var b0 := _badges()
	_ok(b0["tasks"] == 4 and b0["daily"] == 1 and b0["gift_bar"] == 4, "3 orders done + ScrubBox + Daily + 4 gifts %s" % str(b0))
	_ok(_home_matches(b0), "Home shows the HomeBadges counts %s" % str(_home_texts()))
	a.actions.claim_daily_task(0)
	a.actions.claim_gift(e.gift.claimable()[0]["id"])
	var b1 := _badges()
	_ok(b1["tasks"] == 3 and b1["gift_bar"] == 3 and b1["daily"] == 1, "one task + one gift claimed: 3 / 3 / 1 %s" % str(b1))
	await _reboot()
	var b2 := _badges()
	_ok(b2 == b1 and _home_matches(b2), "relaunch: same counts, Home matches %s" % str(b2))
	a = _root.get_app_state()
	e = a.economy
	a.actions.claim_daily_task(1)
	a.actions.claim_daily_task(2)
	a.actions.claim_daily_all_tasks()
	a.actions.claim_daily_login()
	for o in e.gift.claimable():
		a.actions.claim_gift(o["id"])
	await _reboot()
	a = _root.get_app_state()
	e = a.economy
	var b3 := _badges()
	var sb0: int = e.wallet.scrub_bucks()
	var again: Array = [a.actions.claim_daily_task(0), a.actions.claim_daily_task(2), a.actions.claim_daily_all_tasks(), a.actions.claim_daily_login()]
	_ok(b3["tasks"] == 0 and b3["daily"] == 0 and b3["gift_bar"] == 0 and _home_matches(b3), "all claimed + relaunch: Tasks / Daily / Gift badges 0 and hidden %s" % str(b3))
	_ok(again.all(func(r): return not r["ok"]) and e.wallet.scrub_bucks() == sb0 and _badges() == b3, "relaunched re-claims (task / ScrubBox / login) refused, nothing paid, no badge back")
	_complete("m028_badges_claims_relaunch")

	_day[0] += 1
	_now[0] += 86400
	await _reboot()
	var b4 := _badges()
	_ok(b4["daily"] == 1 and b4["tasks"] == 0 and b4["gift_bar"] == 0 and _home_matches(b4), "next local day: Daily badge 1 again, new orders not done -> Tasks 0 %s" % str(b4))
	_complete("m028_badges_next_day")

func _badges() -> Dictionary:
	_root.get_home().refresh()
	return HomeBadges.compute(_root.get_app_state())

func _home_texts() -> Dictionary:
	var h = _root.get_home()
	return {"tasks": h.get_region("Shortcut_tasks").badge.text, "daily": h.get_region("Shortcut_daily").badge.text}

## Tasks / Daily shortcut pills show exactly the HomeBadges count (hidden at 0).
func _home_matches(b: Dictionary) -> bool:
	var h = _root.get_home()
	for id in ["tasks", "daily"]:
		var l: Label = h.get_region("Shortcut_" + id).badge
		if l.text != (str(b[id]) if b[id] > 0 else "") or l.visible != (b[id] > 0):
			return false
	return true

# ------------------------------------------------------------------ 029 ----

func _m029() -> void:
	print("[029 BottomNav transitions + modal stack]")
	_reset_clock()
	await _boot()
	var h = _root.get_home()
	var stack = _root.get_modal_stack()
	var got := {}
	for id in ["events", "robots", "leaderboard"]:
		var b: Button = h.get_region("Nav_" + id)
		b.pressed.emit()
		b.pressed.emit()
		await _settle()
		got[id] = stack.ids()
		_ok(_root.handle_back() == "close_modal" and stack.depth() == 0, "back closes the %s destination" % id)
	_ok(got == {"events": ["events"], "robots": ["robots"], "leaderboard": ["ranks"]} and _nav() == R.HOME, "double tap on each tab: exactly one destination %s" % str(got))
	_complete("m029_tab_double_tap_one")

	(h.get_region("ProfileButton") as Button).pressed.emit()
	await _settle()
	stack.top()._on_action("achievements")
	await _settle()
	var ids0: Array = stack.ids()
	_root.handle_back()
	await _settle()
	var ids1: Array = stack.ids()
	_root.handle_back()
	await _settle()
	_ok(ids0 == ["profile", "achievements"] and ids1 == ["profile"] and stack.depth() == 0, "Profile -> Achievements: back closes Achievements, then Profile (LIFO) %s %s" % [str(ids0), str(ids1)])
	_root.handle_back()
	await _settle()
	_ok(_nav() == R.HOME and stack.depth() == 0, "back on a bare Home: Home stays, nothing opens")
	_complete("m029_modal_lifo_back")

	(h.get_region("Nav_settings") as Button).pressed.emit()
	await _settle()
	var open: bool = _root.get_navigation().is_settings_open()
	_root.handle_back()
	await _settle()
	_ok(open and not _root.get_navigation().is_settings_open() and _nav() == R.HOME and stack.depth() == 0, "SETTINGS overlay opens, back closes it, Home stays")
	_complete("m029_settings_back")

func _nav() -> int:
	return _root.get_navigation().current()

# ------------------------------------------------------------------ 030 ----

func _m030() -> void:
	print("[030 FTUE once-only across a cloud restore]")
	_reset_clock()
	AppState.test_unlock_all = false   # the real unlock table decides which intro is due
	var a := _app(_path("m030a"))
	_ok(bool(a.bootstrap_new_profile()["ok"]), "fresh profile bootstrapped")
	var dr := FtueDirector.new(a)
	_walk_to(a, 6)
	var intro: Dictionary = dr.booster_intro_step()
	var ctx: Dictionary = dr.contextual_step("result_won")
	_ok(intro.get("id", "") == "intro_plus_one_slot" and dr.acknowledge("intro_plus_one_slot") and ctx.get("id", "") == "ctx_result_won" and dr.acknowledge("ctx_result_won"),
		"L6: +1 Slot intro and the first-win tip acknowledged")
	dr.settle()
	var charges := BOOSTERS.map(func(id): return a.economy.boosters.charges(id))
	var env := CloudSave.envelope(a.save, "dev-a", 1, _now[0])
	var bpath := _path("m030b")
	var b := _app(bpath)
	_ok(bool(CloudSave.restore(b.save, env)["ok"]) and bool(b.bootstrap_new_profile().get("replay", false)), "fresh device: restore applied, bootstrap is a replay")
	var db := FtueDirector.new(b)
	_ok(db.booster_intro_step().is_empty() and db.contextual_step("result_won").is_empty() and b.economy.ftue.seen_steps() == a.economy.ftue.seen_steps(),
		"restored: acknowledged intro / tip never shown again %s" % str(b.economy.ftue.seen_steps()))
	_ok(BOOSTERS.map(func(id): return b.economy.boosters.charges(id)) == charges and db.whats_new_due().is_empty(), "no second starter grant, no What's New %s" % str(charges))
	b.request_save()
	var c := _app(bpath)
	var dc := FtueDirector.new(c)
	_ok(bool(c.bootstrap_new_profile().get("replay", false)) and BOOSTERS.map(func(id): return c.economy.boosters.charges(id)) == charges, "relaunch of the restored device: bootstrap replay, charges unchanged")
	_ok(dc.booster_intro_step().is_empty() and dc.contextual_step("result_won").is_empty(), "relaunch: still nothing replayed")
	_walk_to(c, 11)
	_ok(dc.booster_intro_step().get("id", "") == "intro_random", "the next intro still comes at its own level (L11 Random)")
	for x in [a, b, c]:
		x.economy.dispose()
	AppState.test_unlock_all = true
	_complete("m030_ftue_once_cloud_restore")

# ------------------------------------------------------------------ 034 ----

func _m034() -> void:
	print("[034 earned-pack pity: reward-source idempotency, relaunch, cloud restore]")
	_reset_clock()
	var path := _path("m034")
	var a := _app(path)
	var e = a.economy
	e.packs._rng.seed = 77
	for cid in e.collection.all_card_ids():
		if cid != "s1_c8":
			e.collection.add_card(cid)
	_ok(e.pack_pity.focus_set(e.collection) == 1 and e.pack_pity.threshold(e.collection) == 1 and e.pack_pity.count() == 0, "First Collection Sprint: Set 1 missing s1_c8, threshold 1")
	var g1: bool = e.reward.grant("m034:gift", {"standard_card_packs": 1})
	var g2: bool = e.reward.grant("m034:gift", {"standard_card_packs": 1})
	var pend: Array = e.pending_packs.entries()
	_ok(g1 and not g2 and pend.size() == 1, "same reward source granted twice: one pending pack")
	var id: String = pend[0]["id"]
	var r1: Dictionary = a.open_earned_pack(id)
	var col: String = JSON.stringify(e.collection.snapshot())
	var r2: Dictionary = a.open_earned_pack(id)
	var got: Array = (r1["receipt"]["cards"] as Array).map(func(c): return c["card_id"])
	_ok(bool(r1["ok"]) and bool(r2["ok"]) and bool(r2["replay"]) and JSON.stringify(r2["receipt"]) == JSON.stringify(r1["receipt"]) and JSON.stringify(e.collection.snapshot()) == col,
		"open twice: same receipt, no second draw")
	_ok(not got.has("s1_c8") and e.pack_pity.count() == 1 and e.pack_pity.guarantee_due(e.collection), "a pack without the missing Set 1 card counts once -> guarantee due %s" % str(got))
	_ok(bool(a.acknowledge_earned_pack(id)["ok"]) and a.acknowledge_earned_pack(id)["reason"] == "not_pending" and e.pack_pity.count() == 1, "acknowledged once; a second ack changes nothing")
	_complete("m034_pity_source_idempotent")

	e.dispose()
	var b := _app(path)
	_ok(b.economy.pack_pity.count() == 1 and b.economy.pack_pity.guarantee_due(b.economy.collection) and b.economy.pending_packs.size() == 0, "relaunch: counter 1, guarantee due, nothing pending")
	_ok(not b.economy.reward.grant("m034:gift", {"standard_card_packs": 1}) and b.economy.pending_packs.size() == 0, "relaunched re-grant of the same source: refused, no pack")
	var env := CloudSave.envelope(b.save, "dev-a", 1, _now[0])
	var c := _app(_path("m034c"))
	_ok(bool(CloudSave.restore(c.save, env)["ok"]) and c.economy.pack_pity.count() == 1 and c.economy.pack_pity.guarantee_due(c.economy.collection), "cloud restore: counter 1, guarantee due on the new device")
	c.economy.reward.grant("m034:gift2", {"standard_card_packs": 1})
	var r3: Dictionary = c.open_earned_pack(c.economy.pending_packs.entries()[0]["id"])
	var got3: Array = (r3["receipt"]["cards"] as Array).map(func(x): return x["card_id"])
	_ok(bool(r3["ok"]) and got3.has("s1_c8") and c.economy.collection.is_set_complete(1) and c.economy.pack_pity.count() == 0, "next earned pack on the new device holds s1_c8; counter reset %s" % str(got3))
	for x in [b, c]:
		x.economy.dispose()
	_complete("m034_pity_relaunch_cloud")

# ------------------------------------------------------------------ 035 ----

func _m035() -> void:
	print("[035 Weekly Event / First-Try / Personal Best across day rollover + relaunch]")
	_reset_clock()
	await _boot()
	var cfg := _event_config()
	var a = _root.get_app_state()
	var e = a.economy
	a.actions.join_first_try()
	await _win(1)
	await _win(2)
	var sb0: int = e.wallet.scrub_bucks()
	_ok(bool(a.actions.claim_event_milestone("wk1", 0)["ok"]) and e.wallet.scrub_bucks() == sb0 + 50, "2 first clears: milestone 0 claimed (+50 SB)")
	_day[0] += 1
	_now[0] += 86400
	await _win(3)
	var pre := {"progress": e.events.view("wk1")["progress"], "run": e.events.first_try()["run"], "streak": e.records.get_value("best_win_streak"), "ft": e.records.get_value("best_first_try_run")}
	_ok(pre == {"progress": 3, "run": 3, "streak": 3, "ft": 3}, "local-day rollover keeps the event progress and the First-Try run %s" % str(pre))
	await _reboot()
	a = _root.get_app_state()
	e = a.economy
	e.events.load_config(cfg)
	var post := {"progress": e.events.view("wk1")["progress"], "run": e.events.first_try()["run"], "streak": e.records.get_value("best_win_streak"), "ft": e.records.get_value("best_first_try_run")}
	var sb1: int = e.wallet.scrub_bucks()
	_ok(post == pre and e.events.view("wk1")["milestones"][0]["claimed"] and e.events.first_try()["joined"], "relaunch: progress / run / bests / claimed milestone kept %s" % str(post))
	_ok(not a.actions.claim_event_milestone("wk1", 0)["ok"] and e.wallet.scrub_bucks() == sb1, "relaunched re-claim refused, nothing paid")
	var p = ProfileScreens.open_profile(_root.get_modal_stack(), a)
	await _settle()
	var row: Node = p.find_child("BestFirstTry", true, false)
	_ok(_txt(row, "Current") == "3" and _txt(row, "Best") == "3", "Profile Personal Best row after relaunch: Current 3 / Best 3")
	_complete("m035_event_rollover_relaunch")

	await _win(1)   # a replay of a cleared level
	a.progression.debug_set_current_level(4)
	_ok(e.events.view("wk1")["progress"] == 3 and e.events.first_try()["run"] == 3, "replay after the relaunch: no event progress, no First-Try step")
	await _lose(4)
	_ok(e.events.first_try()["run"] == 0 and e.records.get_value("best_first_try_run") == 3 and e.events.view("wk1")["progress"] == 3, "first-try loss: run 0, best 3 kept, event unchanged")
	await _reboot()
	e = _eco()
	e.events.load_config(cfg)
	_ok(e.events.first_try()["run"] == 0 and e.records.get_value("best_first_try_run") == 3 and e.events.view("wk1")["progress"] == 3, "relaunch after the loss: run 0, best 3, progress 3")
	_complete("m035_replay_after_relaunch")

func _event_config() -> String:
	var cfg := {"schema": "scrubbots.events.v1", "version": 1,
		"approved_reward_types": ["scrub_bucks", "bot_parts", "standard_card_packs", "premium_card_packs", "random_booster_charges", "selected_booster_charges"],
		"weekly_events": [{"id": "wk1", "start_ts": _now[0] - 3600, "unclaimed_on_expiry": "forfeit",
			"milestones": [{"target": 2, "reward": {"scrub_bucks": 50}}, {"target": 5, "reward": {"bot_parts": 1}}]}],
		"first_try_cleanup": {"id": "ft1", "levels": 5, "reward": {"standard_card_packs": 1}}}
	var path := "user://m54_028_036_events_%d.json" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	_eco().events.load_config(path)
	return path

# ------------------------------------------------------------------ 036 ----

func _m036() -> void:
	print("[036 Comeback window vs reminder preferences]")
	_reset_clock()
	await _boot()
	var a = _root.get_app_state()
	var p = ProfileScreens.open_notifications(_root.get_modal_stack(), a)
	await _settle()
	p._on_action("notify_all")
	await _settle()
	_root.get_modal_stack().clear("t")   # a permission explainer, if the platform shows one
	p = ProfileScreens.open_notifications(_root.get_modal_stack(), a)
	await _settle()
	p._on_action("notify:daily")
	await _settle()
	a.economy.notify.mark_sent(_now[0])
	a.request_save()
	var prefs: Dictionary = a.economy.notify.snapshot()
	_ok(prefs["enabled"] and not prefs["categories"]["daily"] and prefs["last_sent"] == _now[0], "reminders ON, Daily OFF, one send recorded")
	var t_sent: int = _now[0]
	_now[0] += 49 * 3600
	_day[0] += 2
	await _reboot()
	a = _root.get_app_state()
	var e = a.economy
	var ret: Dictionary = e.returns.snapshot()
	_ok(int(ret["window"]) == t_sent and int(ret["window_ts"]) == _now[0], "49 h away: the relaunch opens one return window %s" % str(ret))
	_ok(e.notify.snapshot() == prefs, "the comeback leaves the saved reminder toggles and last-sent untouched")
	var m: Dictionary = e.notify.decide(a, _now[0], 12)
	_ok(not e.daily.claimed_today() and m.get("category", "") == "hearts" and NotificationPolicy.CATEGORIES.all(func(c): return c != "comeback"),
		"Daily ready but Daily reminders OFF: the one message is Hearts, no comeback push %s" % str(m))
	_ok(e.notify.decide(a, _now[0], 23).is_empty(), "quiet hours still hold after the comeback")
	var login0 := [e.daily.claimed_today(), e.daily.streak(), e.daily.next_claim_cycle_day()]
	await _win(1)
	var cu: Dictionary = e.returns.catchup()
	_ok(not cu.is_empty() and int(cu["wins"]) == 1 and e.notify.snapshot() == prefs and [e.daily.claimed_today(), e.daily.streak(), e.daily.next_claim_cycle_day()] == login0,
		"a Catch-Up first clear changes neither the reminders nor the Daily login rule %s" % str(login0))
	_complete("m036_comeback_keeps_reminders")

	e.notify.mark_sent(_now[0])
	a.request_save()
	var sent: int = _now[0]
	var win0: int = int(e.returns.snapshot()["window"])
	_now[0] -= 10 * 86400
	await _reboot()
	e = _eco()
	_ok(int(e.returns.snapshot()["window"]) == win0 and e.notify.decide(_root.get_app_state(), _now[0], 12).is_empty(), "clock rolled back 10 days: no new window, the 24 h cap holds")
	_now[0] = sent + 86400
	_ok(not e.notify.decide(_root.get_app_state(), _now[0], 12).is_empty() and int(e.returns.snapshot()["window"]) == win0, "clock back past the cap: one reminder allowed again, still the same window")
	_complete("m036_rollback_no_window_cap")

# ------------------------------------------------------------------ fixtures ----

func _reset_clock() -> void:
	_now[0] = T0
	_day[0] = DAY0

func _path(tag: String) -> String:
	var p := "user://m54_028_036_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _app(path: String) -> AppState:
	return AppState.new(path, func(): return _now[0], func(): return _day[0])

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

func _boot() -> void:
	_save = _path("app")
	await _start()

## Relaunch the app root on the same save, after the lifecycle flush a background would do.
func _reboot() -> void:
	_root.get_app_state().flush()
	await _start()

func _start() -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _save
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _settle()
	_root.get_modal_stack().clear("t")   # e.g. the Welcome Back summary

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _eco():
	return _root.get_app_state().economy

func _win(level: int) -> void:
	await _play(level)
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.WON)
	await _settle()

func _lose(level: int) -> void:
	await _play(level)
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.LOST)
	await _settle()

func _play(level: int) -> void:
	_root.get_modal_stack().clear("t")
	if _nav() != R.HOME:
		_root.get_navigation().go(R.HOME)
		await _settle()
	if _root.get_app_state().progression.current_level() != level:
		_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_root.get_gameplay_host().get_runtime().set_process(false)

func _txt(p, n: String) -> String:
	var l = p.find_child(n, true, false) if p != null else null
	return l.text if l is Label else ""

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _cleanup() -> void:
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
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M54 regression pack 028-036: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
