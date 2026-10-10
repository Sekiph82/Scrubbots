extends SceneTree
## M43 master — Lanes C010 BottomNav / Profile / Achievements / Events / Ranks / badges and
## C010R Weekly Event / First-Try Cleanup / Personal Best (SB-M43-122..134, R10-001..007).
## Real app root (main.tscn), injected clock + local day, real gameplay host terminals.
##
## Run: godot --headless --path . -s res://tests/m43_master_c010_meta.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const EventService = preload("res://scripts/economy/event_service.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

var EXPECTED_CASES := [
	"m01_bottom_nav_real_or_disabled", "m02_settings_preserved", "m03_profile_entry_live", "m04_achievements_data_driven",
	"m05_events_empty_state", "m06_weekly_event_template", "m07_weekly_expiry_policy", "m08_first_try_run",
	"m09_personal_bests_self_only", "m10_badges", "m11_ranks_not_invented", "m12_strict_imports",
]

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
	await _m01()
	await _m02()
	await _m03()
	await _m04()
	await _m05()
	await _m06()
	await _m07()
	await _m08()
	await _m09()
	await _m10()
	await _m11()
	await _m12()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _m01() -> void:
	print("[m01 BottomNav: EVENTS / ROBOTS / HOME / SETTINGS real; RANKS disabled (policy), never faked]")
	await _boot("m01")
	var h = _root.get_home()
	var opened := {}
	for id in ["events", "robots"]:
		var b: Button = h.get_region("Nav_" + id)
		_ok(not b.disabled, "Nav_%s live" % id)
		b.pressed.emit()
		await _frames(2)
		opened[id] = _top_id()
		_root.get_modal_stack().clear("test")
		await _frames(2)
	_ok(opened == {"events": "events", "robots": "robots"}, "EVENTS / ROBOTS open their destinations %s" % str(opened))
	var r: Button = h.get_region("Nav_leaderboard")
	_ok(r.disabled and r.tooltip_text == UiText.t("HOME_COMING_LATER"), "RANKS disabled with honest coming-later, no fake board")
	_complete("m01_bottom_nav_real_or_disabled")

func _m02() -> void:
	print("[m02 SETTINGS stays the M41 panel]")
	await _boot("m02")
	var b: Button = _root.get_home().get_region("Nav_settings")
	b.pressed.emit()
	await _frames(2)
	var panel = _root.get_settings_panel() if _root.has_method("get_settings_panel") else null
	_ok(panel != null and panel.visible and _top_id() == "", "M41 Settings panel, no second Settings popup")
	_complete("m02_settings_preserved")

func _m03() -> void:
	print("[m03 Profile from the Home profile card: robot, level, stats, Collection, achievements]")
	await _boot("m03")
	var e = _eco()
	_root.get_app_state().progression.debug_set_current_level(4)
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var p = _top()
	_ok(_top_id() == "profile", "profile card -> Profile")
	_ok(_txt(p, "ActiveRobot") == UiText.t("PROFILE_ROBOT", ["Scrubby"]) and _txt(p, "Level") == UiText.t("PROFILE_LEVEL", ["4"]), "active robot + campaign level")
	_ok(_txt(p, "Collection") == UiText.t("PROFILE_COLLECTION", ["0", "135", "0"]) and _txt(p, "Robots") == UiText.t("PROFILE_ROBOTS", ["1", "10"]), "Collection + robots live")
	_ok(_txt(p, "AchievementSummary") == UiText.t("PROFILE_ACHIEVEMENTS", ["0", str(Achievements.load_defs().size())]), "achievement summary")
	_tap("achievements")
	await _frames(2)
	_ok(_top_id() == "achievements", "ACHIEVEMENTS from Profile")
	_complete("m03_profile_entry_live")

func _m04() -> void:
	print("[m04 Achievements: data-driven, progress, completed, no reward]")
	await _boot("m04")
	var defs := Achievements.load_defs()
	_ok(defs.size() >= 5 and defs.all(func(a): return Achievements.METRICS.has(a["metric"])), "%d definitions, known metrics" % defs.size())
	var a = _root.get_app_state()
	for n in range(1, 11):
		a.progression.record_win(n)
	var ev := Achievements.evaluate(a)
	var by := {}
	for x in ev:
		by[x["id"]] = x
	_ok(by["clean_start"]["done"] and by["tidy_ten"]["done"] and not by["spotless_fifty"]["done"] and by["spotless_fifty"]["value"] == 10, "10 clears: 1 / 10 done, 50 at 10/50")
	var sb0: int = _eco().wallet.scrub_bucks()
	var p = ProfileScreens.open_achievements(_root.get_modal_stack(), a)
	await _frames(2)
	_ok(bool(p.find_child("Ach_tidy_ten", true, false).get_meta("done")) and _eco().wallet.scrub_bucks() == sb0, "completed state shown; nothing granted")
	var bad := "user://m43c010_badach.json"
	var f := FileAccess.open(bad, FileAccess.WRITE)
	f.store_string('{"schema":"scrubbots.achievements.v1","achievements":[{"id":"x","metric":"spend_money","target":1}]}')
	f.close()
	_ok(Achievements.load_defs(bad).is_empty(), "unknown metric rejects the file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad))
	_complete("m04_achievements_data_driven")

func _m05() -> void:
	print("[m05 EVENTS: shipped config schedules nothing -> honest empty state]")
	await _boot("m05")
	var p = ProfileScreens.open_events(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	_ok(_eco().events.config_ok and _eco().events.list().is_empty() and _txt(p, "Empty") == UiText.t("EVENTS_EMPTY"), "no event, no fake card")
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EventService.PATH))
	_ok(not JSON.stringify(cfg).to_lower().contains("point") and not JSON.stringify(cfg).contains("currency\":"), "no event points / event currency")
	_eco().events.load_config("user://__missing_events.json")
	ProfileScreens.refresh_events(p, _root.get_app_state())
	_ok(_txt(p, "Empty") == UiText.t("EVENTS_UNAVAILABLE"), "unreadable config -> unavailable state")
	_complete("m05_events_empty_state")

func _m06() -> void:
	print("[m06 Weekly Cleaning Event: window, auto progress from first clears, fixed milestones once]")
	await _boot("m06")
	var e = _eco()
	_event_config({"start_ts": _now[0] - 3600, "policy": "forfeit"})
	_ok(e.events.list().size() == 1 and e.events.list()[0]["phase"] == "active", "event active")
	await _win(1)
	_day[0] += 3
	_now[0] += 3 * 86400
	await _win(2)
	var v: Dictionary = e.events.view("wk1")
	_ok(v["progress"] == 2 and v["milestones"][0]["claimable"] and not v["milestones"][1]["reached"], "two first clears (3 days apart, no reset): milestone 1 reached")
	await _lose(3)
	_ok(e.events.view("wk1")["progress"] == 2, "a loss adds nothing")
	var p = ProfileScreens.open_events(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	var sb0: int = e.wallet.scrub_bucks()
	_tap("ev:wk1:0")
	_tap("ev:wk1:0")
	await _frames(1)
	_ok(e.wallet.scrub_bucks() == sb0 + 50 and e.events.view("wk1")["milestones"][0]["claimed"], "milestone reward once (+50 SB)")
	_ok(not _root.get_app_state().actions.claim_event_milestone("wk1", 0)["ok"] and not _root.get_app_state().actions.claim_event_milestone("wk1", 1)["ok"], "re-claim / unreached refused")
	_ok(_txt(p.find_child("Event_wk1", true, false), "When").begins_with(UiText.t("EVENT_ENDS_IN", [""]).substr(0, 4)), "countdown shown")
	_complete("m06_weekly_event_template")

func _m07() -> void:
	print("[m07 expiry: explicit policy required; forfeit vs claim_after_end; stale safe]")
	await _boot("m07")
	var e = _eco()
	_event_config({"start_ts": _now[0] - 3600, "policy": ""})
	_ok(e.events.list().is_empty(), "no unclaimed-expiry policy -> event invalid, not listed")
	_event_config({"start_ts": _now[0] - 3600, "policy": "forfeit"})
	await _win(1)
	await _win(2)
	_now[0] += 8 * 86400
	_ok(e.events.list().is_empty() and not _root.get_app_state().actions.claim_event_milestone("wk1", 0)["ok"], "forfeit: ended event gone, claim refused")
	_now[0] -= 8 * 86400
	_event_config({"start_ts": _now[0] - 3600, "policy": "claim_after_end"})
	_now[0] += 8 * 86400
	var v: Dictionary = e.events.view("wk1")
	_ok(v["phase"] == "ended" and v["milestones"][0]["claimable"] and e.events.list().size() == 1, "claim_after_end: ended event listed while reward unclaimed")
	await _win(3)
	_ok(e.events.view("wk1")["progress"] == 2, "no progress after the window")
	_complete("m07_weekly_expiry_policy")

func _m08() -> void:
	print("[m08 First-Try Cleanup: opt-in, first attempts only, loss resets the run only]")
	await _boot("m08")
	var e = _eco()
	var a = _root.get_app_state()
	_event_config({"start_ts": _now[0] + 86400, "policy": "forfeit", "first_try": true})
	var f: Dictionary = e.events.first_try()
	_ok(not f["joined"] and int(f["reward"].get("standard_card_packs", 0)) == 1 and f["reward"].size() == 1, "reward fixed and visible before joining")
	await _win(1)
	_ok(e.events.first_try()["run"] == 0, "not joined: nothing counts")
	a.actions.join_first_try()
	await _win(2)
	await _win(3)
	_ok(e.events.first_try()["run"] == 2, "two first-try clears")
	var hearts0: int = e.hearts.hearts()
	await _lose(4)
	_ok(e.events.first_try()["run"] == 0 and a.progression.current_level() == 4 and e.hearts.hearts() == hearts0 - 1, "first-try loss: run 0, campaign kept, only the normal Heart")
	await _win(4)
	_ok(e.events.first_try()["run"] == 0, "second attempt at level 4 cannot extend the run")
	for n in [5, 6, 7, 8, 9]:
		await _win(n)
	_ok(e.events.first_try()["complete"] and a.actions.claim_first_try()["ok"] and not a.actions.claim_first_try()["ok"], "5 in a row -> reward once")
	_complete("m08_first_try_run")

func _m09() -> void:
	print("[m09 Personal Bests: self-comparison only + self-ghost]")
	await _boot("m09")
	var e = _eco()
	await _win(1)
	await _win(2)
	await _lose(3)
	await _win(3)
	var r = e.records
	_ok(r.get_value("best_win_streak") == 2 and r.get_value("best_first_try_run") == 2 and r.get_value("first_try_run") == 0, "best streak 2, best first-try run 2")
	_ok(r.get_value("boosterless_wins") == 3 and r.get_value("best_boosterless_run") == 3, "boosterless first clears 3")
	var p = ProfileScreens.open_profile(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	var ghost: ProgressBar = p.find_child("BestFirstTry", true, false).find_child("Ghost", true, false)
	_ok(ghost.max_value == 2 and ghost.value == 0, "self-ghost: current 0 against own best 2")
	var src := FileAccess.get_file_as_string("res://scripts/ui/profile/profile_screens.gd") + FileAccess.get_file_as_string("res://scripts/economy/player_records.gd")
	_ok(not src.contains("friend") and not src.contains("leaderboard") and not src.contains("http"), "no social / remote comparison")
	_complete("m09_personal_bests_self_only")

func _m10() -> void:
	print("[m10 Home / BottomNav badges from canonical state, cleared when handled]")
	await _boot("m10")
	var e = _eco()
	var a = _root.get_app_state()
	var b := HomeBadges.compute(a)
	# M47-FAMILY-APK-TOUCH-R01 owner decision: today's free Rewarded Ads slot is actionable on a fresh day.
	_ok(b == {"tasks": 0, "daily": 1, "gift_bar": 0, "robots": 0, "collection": 0, "events": 0, "rewarded_ads": 1}, "fresh: only Daily + today's free Rewarded Ads slot %s" % str(b))
	e.daily.mark_task_done(0)
	e.gift.add_streak_sb("m10", 60)
	e.wallet.credit("bot_parts", 250)
	e.collection.add_card(e.collection.all_card_ids()[0])
	_root.get_home().refresh()
	b = HomeBadges.compute(a)
	_ok(b["tasks"] == 1 and b["gift_bar"] == 2 and b["robots"] == 1 and b["collection"] == 1, "tasks / gift / robots / collection %s" % str(b))
	var h = _root.get_home()
	_ok(h.get_region("Shortcut_tasks").badge.visible and h.get_region("Shortcut_collection").badge.visible and h.get_region("NavBadge_robots").visible, "badges rendered on Home + BottomNav")
	a.actions.claim_daily_task(0)
	a.actions.claim_daily_login()
	a.actions.claim_rewarded_daily_free()   # slot 1 claimed; slot 2 needs an ad and no provider -> not actionable
	for o in e.gift.claimable():
		a.actions.claim_gift(o["id"])
	a.actions.unlock_next_robot()
	e.meta_ui.mark_seen("robot_seen:moppy")
	for cid in e.collection.all_card_ids():   # the claimed Gift card pack added real cards too
		if e.collection.owned(cid) > 0:
			e.meta_ui.mark_seen("card:" + cid)
	h.refresh()
	b = HomeBadges.compute(a)
	_ok(b.values().all(func(v): return v == 0) and not h.get_region("Shortcut_tasks").badge.visible and not h.get_region("NavBadge_robots").visible, "all handled -> no badge %s" % str(b))
	_complete("m10_badges")

func _m11() -> void:
	print("[m11 RANKS: no ranking metric / scoring invented]")
	var hits: Array = []
	for f in ["res://scripts/ui/profile/profile_screens.gd", "res://scripts/ui/home/home_badges.gd", "res://scripts/economy/event_service.gd", "res://scripts/economy/player_records.gd"]:
		var s := FileAccess.get_file_as_string(f).to_lower()
		for w in ["rank_score", "ranking", "leaderboard_score", "placement"]:
			if s.contains(w):
				hits.append("%s:%s" % [f.get_file(), w])
	_ok(hits.is_empty(), "no rank scoring code %s" % str(hits))
	_complete("m11_ranks_not_invented")

func _m12() -> void:
	print("[m12 strict records / events imports; absent = fresh]")
	await _boot("m12")
	var e = _eco()
	var good: Dictionary = e.snapshot()
	var bad := [
		["records", {"version": 1}],
		["records", {"version": 2, "best_win_streak": 0}],
		["events", {"version": 1, "weekly": {"a": {"progress": -1, "claimed": []}}, "first_try": {}}],
		["events", {"version": 1, "weekly": {"a": {"progress": 1, "claimed": [0, 0]}}, "first_try": {}}],
		["events", {"version": 1, "weekly": {}, "first_try": {"id": "x", "joined": 1, "run": 0, "claimed": false}}],
	]
	var rejected := 0
	for bb in bad:
		var s: Dictionary = good.duplicate(true)
		s[bb[0]] = bb[1]
		if not e.import_snapshot(s):
			rejected += 1
	_ok(rejected == bad.size() and e.snapshot() == good, "%d/%d malformed sections rejected" % [rejected, bad.size()])
	var legacy: Dictionary = good.duplicate(true)
	legacy.erase("records")
	legacy.erase("events")
	_ok(e.import_snapshot(legacy) and e.records.get_value("best_win_streak") == 0, "absent sections -> fresh")
	_complete("m12_strict_imports")

# ------------------------------------------------------------------ helpers ----

func _event_config(o: Dictionary) -> void:
	var cfg := {"schema": "scrubbots.events.v1", "version": 1,
		"approved_reward_types": ["scrub_bucks", "bot_parts", "standard_card_packs", "premium_card_packs", "random_booster_charges", "selected_booster_charges"],
		"weekly_events": [{"id": "wk1", "start_ts": o["start_ts"], "unclaimed_on_expiry": o["policy"],
			"milestones": [{"target": 2, "reward": {"scrub_bucks": 50}}, {"target": 5, "reward": {"bot_parts": 1}}]}],
		"first_try_cleanup": {"id": "ft1", "levels": 5, "reward": {"standard_card_packs": 1}} if o.get("first_try", false) else null}
	var path := "user://m43c010_events_%d.json" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	_eco().events.load_config(path)

func _win(level: int) -> void:
	await _play(level)
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.WON)

func _lose(level: int) -> void:
	await _play(level)
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.LOST)

func _play(level: int) -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	if nav.current() != NavigationController.Route.HOME:
		nav.go(NavigationController.Route.HOME)
		await _frames(2)
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(4)
	_root.get_gameplay_host().get_runtime().set_process(false)

func _boot(tag: String, size := Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43master_c010_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
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

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _txt(p, n: String) -> String:
	var l = p.find_child(n, true, false) if p != null else null
	return l.text if l is Label else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
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
	print("M43 master C010 meta evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
