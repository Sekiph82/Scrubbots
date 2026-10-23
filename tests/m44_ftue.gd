extends SceneTree
## M44 FTUE master (SB-M44-001..024, owner V03) — first-time experience evidence against the
## REAL services and the REAL app root (main.tscn), with an injected clock / local calendar day:
##   - conclusive fresh-profile detection; one-time 2/2/2/2 starter charges; first-day Welcome
##     task (index 0, 100 SB) replacing that day's easy task; ordinary 75/100/125 untouched;
##   - DAILY 100 + TASKS 100 first-Home claims in both orders (1,000 -> 1,200), durable, with
##     save-failure rollback, double tap, relaunch and clock rollback;
##   - data-driven L1-L3 coachmarks on real controls, none at L4+, Skip Tips, read-only Help,
##     What's New for established saves, Reduced Effects / layout / non-blocking overlay.
##
## Run: godot --headless --path . -s res://tests/m44_ftue.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const FtueConfig = preload("res://scripts/app/ftue_config.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
const L1 := "m21_level_001_hazard_bot"

var EXPECTED_CASES := [
	"t01_fresh_detection_strict", "t02_bootstrap_exact_grant", "t03_bootstrap_idempotent_relaunch",
	"t04_bootstrap_save_failure_rollback", "t05_first_home_claims_both_orders", "t06_welcome_tiers_scrubbox",
	"t07_welcome_expiry_clock_rollback", "t08_claim_save_failure_rollback", "t09_double_tap_once",
	"t10_strict_schema", "t11_config_strict_data_driven", "t12_director_rules", "t13_no_tutorial_l4_plus",
	"t14_first_home_ui_claims", "t15_gameplay_l1_l3_real_controls", "t16_skip_tips_help_read_only",
	"t17_old_save_whats_new_once", "t18_layout_reduced_effects_non_blocking", "t19_relaunch_modal_resume",
	"t20_fresh_meta_dependencies", "t21_static_guards",
	"t22_d2_future_whats_new_rules", "t23_d2_quiet_home_once",
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
	MainScript.boot_ftue_override = 1
	_t01()
	_t02()
	_t03()
	_t04()
	_t05()
	_t06()
	_t07()
	_t08()
	_t09()
	_t10()
	_t11()
	_t12()
	_t13()
	await _t14()
	await _t15()
	await _t16()
	await _t17()
	await _t18()
	await _t19()
	await _t20()
	_t21()
	_t22()
	await _t23()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------ economy / bootstrap ----

func _t01() -> void:
	print("[t01 fresh = no save artefact at all; existing / corrupt / backup / future / legacy never fresh]")
	var p := _path("t01")
	var a = _app(p)
	_ok(String(a.load_result.get("source", "")) == "defaults" and bool(a.load_result.get("fresh", false)), "no save artefact: conclusively fresh %s" % str(a.load_result))
	a.request_save()
	var b = _app(p)
	_ok(String(b.load_result.get("source", "")) == "primary" and not bool(b.load_result.get("fresh", false)), "existing primary: not fresh")
	_ok(String(b.bootstrap_new_profile().get("reason", "")) == "not_fresh" and _total(b) == 0 and not b.economy.daily.is_welcome_task(0), "an existing (L1) save is never re-classified: no starter, no welcome")
	b.progression.record_win(1)
	_ok(bool(b.request_save().get("ok", false)), "progressed (L1 won) save written")
	var b2 = _app(p)
	_ok(b2.progression.current_level() == 2 and not b2.bootstrap_new_profile()["ok"] and _total(b2) == 0, "a progressed save: no starter grant")
	var pc := _path("t01c")
	_write(pc, "{not json")
	var c = _app(pc)
	_ok(String(c.load_result.get("source", "")) == "defaults" and not bool(c.load_result.get("fresh", true)), "corrupt save -> defaults but NOT fresh")
	_ok(String(c.bootstrap_new_profile().get("reason", "")) == "not_fresh" and _total(c) == 0, "corrupt / ambiguous save never receives the new-player grant")
	var pb := _path("t01b")
	var d = _app(pb)
	d.request_save()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(pb), ProjectSettings.globalize_path(pb + ".bak"))
	var d2 = _app(pb)
	_ok(String(d2.load_result.get("source", "")) == "backup" and not d2.bootstrap_new_profile()["ok"] and _total(d2) == 0, "backup recovery: not fresh, no grant")
	var pf := _path("t01f")
	_write(pf, JSON.stringify({"schema": "scrubbots.save", "version": 99}))
	var f = _app(pf)
	_ok(f.is_blocked and String(f.bootstrap_new_profile().get("reason", "")) == "app_blocked" and _total(f) == 0, "future schema: blocked, no grant, file untouched")
	var pl := _path("t01l")
	var legacy := _path("t01_legacy_audio") + ".cfg"
	_write(legacy, "[audio]\n")
	var econ = EconomyServices.new()
	var ss = SaveService.new(pl, AudioSettingsService.new(_path("t01_a") + ".cfg"), HapticsSettingsService.new(_path("t01_h") + ".cfg"), LevelProgressionService.new(), econ)
	ss.set_legacy_audio_path(legacy)
	_ok(not bool(ss.load().get("fresh", true)), "a legacy (pre-M40) settings file: migrated install, not fresh")
	econ.dispose()
	_complete("t01_fresh_detection_strict")

func _t02() -> void:
	print("[t02 bootstrap: exactly 2 charges EACH (8), wallet 1,000, nothing else; Welcome task 100 SB]")
	var a = _app(_path("t02"))
	var base = EconomyServices.new()
	var r: Dictionary = a.bootstrap_new_profile()
	_ok(bool(r.get("ok", false)) and bool(r["save"].get("ok", false)), "bootstrap committed + saved %s" % str(r))
	_ok(BOOSTERS.all(func(id): return a.economy.boosters.charges(id) == 2) and _total(a) == 8, "2 x +1 Slot / Random / Selector / Tornado = 8 real charges")
	_ok(a.economy.wallet.scrub_bucks() == 1000 and a.economy.wallet.scrub_bucks() == base.wallet.scrub_bucks(), "wallet = canonical starting 1,000 SB (no extra SB)")
	_ok(a.economy.hearts.hearts() == base.hearts.hearts() and a.economy.boosters.pending_selected() == 0 and a.economy.pending_packs.entries().is_empty(), "no extra Hearts / pending choice / card packs")
	_ok(a.economy.speed.timed_seconds_remaining() == 0 and not a.economy.speed.is_manual_2x_entitled(1), "no paid 2x entitlement")
	_ok(a.economy.reward.already_applied(AppState.STARTER_TX) and a.economy.ftue.is_new_profile() and a.economy.ftue.tips_active(), "one ledger tx; profile NEW, tips active")
	var dly = a.economy.daily
	_ok(dly.is_welcome_task(0) and dly.is_task_done(0) and not dly.task_claimed(0) and dly.task_reward_sb(0) == 100, "Welcome task = index 0, done, unclaimed, 100 SB")
	_ok(not dly.is_task_done(1) and not dly.is_task_done(2) and dly.tasks_done_count() == 1 and a.economy.orders.orders().size() == 3, "still exactly three task slots; 1 of 3 done")
	var tsb: Array = (a.economy.config.daily_config()["task_sb"] as Array).map(func(v): return int(v))
	_ok(tsb == [75, 100, 125], "global daily.task_sb stays [75, 100, 125] %s" % str(tsb))
	var badges: Dictionary = HomeBadges.compute(a)
	_ok(int(badges["tasks"]) == 1 and int(badges["daily"]) == 1, "first Home: TASKS 1 and DAILY 1 real claimable badges %s" % str(badges))
	_ok(a.economy.gift.total_progress() == 0 and a.economy.streak.streak() == 0 and a.progression.current_level() == 1, "no first-clear / streak / Gift Meter / progression touched")
	base.dispose()
	_complete("t02_bootstrap_exact_grant")

func _t03() -> void:
	print("[t03 idempotent: repeat / relaunch / next day never re-grant]")
	var p := _path("t03")
	var a = _app(p)
	a.bootstrap_new_profile()
	var r2: Dictionary = a.bootstrap_new_profile()
	_ok(bool(r2.get("replay", false)) and _total(a) == 8, "second call: replay no-op")
	var b = _app(p)
	_ok(String(b.load_result.get("source", "")) == "primary" and _total(b) == 8 and b.economy.ftue.is_new_profile() and b.economy.daily.is_welcome_task(0), "relaunch: same 8 charges, same Welcome")
	_ok(bool(b.bootstrap_new_profile().get("replay", false)) and _total(b) == 8, "relaunch bootstrap: replay, no second grant")
	_day[0] += 1
	var c = _app(p)
	_ok(c.bootstrap_new_profile().get("replay", false) and _total(c) == 8 and not c.economy.daily.is_welcome_task(0), "next day relaunch: no starter, no Welcome")
	_day[0] -= 1
	_complete("t03_bootstrap_idempotent_relaunch")

func _t04() -> void:
	print("[t04 bootstrap save failure: exact pre-state, retried only while no file exists]")
	var p := _path("t04")
	var a = _app(p)
	var pre := JSON.stringify(a.economy.snapshot())
	a.save.set_fault_injector(func(stage): return stage == "temp_write")
	var r: Dictionary = a.bootstrap_new_profile()
	_ok(not r["ok"] and String(r["reason"]) == "save_failed" and bool(r.get("restored", false)), "save failed -> refused + restored")
	_ok(JSON.stringify(a.economy.snapshot()) == pre and _total(a) == 0 and not a.economy.ftue.is_new_profile() and not a.economy.daily.is_welcome_task(0), "no half-created grant (exact pre-bootstrap economy)")
	_ok(a.is_bootstrap_pending() and not FileAccess.file_exists(p), "pending; nothing on disk")
	var s2: Dictionary = a.request_save()
	_ok(not bool(s2.get("ok", true)) and _total(a) == 0 and not FileAccess.file_exists(p), "a later save cannot persist a starter-less profile while faulted")
	a.save.set_fault_injector(Callable())
	var s3: Dictionary = a.request_save()
	_ok(bool(s3.get("ok", false)) and _total(a) == 8 and FileAccess.file_exists(p) and not a.is_bootstrap_pending(), "retry (still proven fresh) commits once")
	var b = _app(p)
	_ok(_total(b) == 8 and b.economy.daily.is_welcome_task(0) and bool(b.bootstrap_new_profile().get("replay", false)), "durable after relaunch; no duplicate")
	_complete("t04_bootstrap_save_failure_rollback")

func _t05() -> void:
	print("[t05 first Home: DAILY 100 + TASKS 100, both orders 1,000 -> 1,100 -> 1,200]")
	for order in [["daily", "task"], ["task", "daily"]]:
		var p := _path("t05_" + String(order[0]))
		var a = _app(p)
		a.bootstrap_new_profile()
		var w = a.economy.wallet
		var seq: Array = [w.scrub_bucks()]
		for kind in order:
			var r: Dictionary = a.actions.claim_daily_login() if kind == "daily" else a.actions.claim_daily_task(0)
			_ok(bool(r.get("ok", false)), "%s claim committed %s" % [kind, str(r.get("reason", ""))])
			seq.append(w.scrub_bucks())
			var bd: Dictionary = HomeBadges.compute(a)
			_ok(int(bd["daily" if kind == "daily" else "tasks"]) == 0, "%s badge cleared after its own claim" % kind)
		_ok(seq == [1000, 1100, 1200], "%s: wallet %s" % [str(order), str(seq)])
		var day := int(_day[0])
		_ok(a.economy.reward.already_applied("daily_login:%d" % day) and a.economy.reward.already_applied("daily_task:%d:0" % day), "two separate ledger txs")
		_ok(not a.actions.claim_daily_login()["ok"] and not a.actions.claim_daily_task(0)["ok"] and w.scrub_bucks() == 1200, "repeat claims refused")
		_ok(a.economy.gift.total_progress() == 0 and a.economy.streak.streak() == 0 and a.progression.current_level() == 1, "neither claim feeds Gift / streak / first-clear")
		var b = _app(p)
		_ok(b.economy.wallet.scrub_bucks() == 1200 and not b.actions.claim_daily_login()["ok"] and not b.actions.claim_daily_task(0)["ok"], "relaunch: 1,200 kept, no reissue")
	_complete("t05_first_home_claims_both_orders")

func _t06() -> void:
	print("[t06 Welcome replaces only day-one index 0; 100/100/125 that day; ScrubBox needs 3/3]")
	var a = _app(_path("t06"))
	a.bootstrap_new_profile()
	var dly = a.economy.daily
	_ok([dly.task_reward_sb(0), dly.task_reward_sb(1), dly.task_reward_sb(2)] == [100, 100, 125], "day one: Welcome 100 / normal 100 / stretch 125")
	_ok(not a.actions.claim_daily_all_tasks()["ok"], "ScrubBox not claimable with the Welcome slot alone (1 of 3)")
	var c0 := _total(a)
	dly.mark_task_done(1)
	dly.mark_task_done(2)
	_ok(a.actions.claim_daily_all_tasks()["ok"] and _total(a) == c0 + 1 and not a.actions.claim_daily_all_tasks()["ok"] and _total(a) == c0 + 1, "3/3 actually done: one Mystery Booster once")
	var sb0: int = a.economy.wallet.scrub_bucks()
	a.actions.claim_daily_task(1)
	a.actions.claim_daily_task(2)
	_ok(a.economy.wallet.scrub_bucks() == sb0 + 225, "ordinary tasks still pay 100 + 125")
	_day[0] += 1
	_ok(not dly.is_welcome_task(0) and [dly.task_reward_sb(0), dly.task_reward_sb(1), dly.task_reward_sb(2)] == [75, 100, 125], "next day: ordinary 75 / 100 / 125")
	_ok(dly.tasks_done_count() == 0 and String(a.actions.claim_daily_task(0).get("reason", "")) == "not_done", "next day: no free starter claim")
	_day[0] -= 1
	_complete("t06_welcome_tiers_scrubbox")

func _t07() -> void:
	print("[t07 unclaimed Welcome expires at local rollover; rollback cannot revive it]")
	var a = _app(_path("t07"))
	a.bootstrap_new_profile()
	_day[0] += 1
	_now[0] += 86400
	_ok(not a.actions.claim_daily_task(0)["ok"] and a.economy.wallet.scrub_bucks() == 1000 and int(HomeBadges.compute(a)["tasks"]) == 0, "expired at rollover: not claimable, no badge")
	_day[0] -= 1
	_now[0] -= 86400
	_ok(not a.actions.claim_daily_task(0)["ok"] and a.economy.wallet.scrub_bucks() == 1000 and int(HomeBadges.compute(a)["tasks"]) == 0, "clock rolled back to day one: still not claimable")
	_day[0] += 5
	_now[0] += 5 * 86400
	_ok(not a.economy.daily.is_welcome_task(0) and not a.actions.claim_daily_task(0)["ok"], "never reappears on a later day")
	_day[0] -= 5
	_now[0] -= 5 * 86400
	_complete("t07_welcome_expiry_clock_rollback")

func _t08() -> void:
	print("[t08 claim + failed save: rollback, badge stays, no grant-first-save-later]")
	var p := _path("t08")
	var a = _app(p)
	a.bootstrap_new_profile()
	var day := int(_day[0])
	a.save.set_fault_injector(func(stage): return stage == "temp_write")
	var rt: Dictionary = a.actions.claim_daily_task(0)
	_ok(not rt["ok"] and String(rt["reason"]) == "save_failed" and bool(rt.get("restored", false)), "task claim refused on save failure")
	_ok(a.economy.wallet.scrub_bucks() == 1000 and not a.economy.daily.task_claimed(0) and a.economy.daily.is_task_done(0) and not a.economy.reward.already_applied("daily_task:%d:0" % day) and int(HomeBadges.compute(a)["tasks"]) == 1, "wallet / ledger / badge exact")
	var rl: Dictionary = a.actions.claim_daily_login()
	_ok(not rl["ok"] and String(rl["reason"]) == "save_failed" and a.economy.wallet.scrub_bucks() == 1000 and not a.economy.daily.claimed_today() and int(HomeBadges.compute(a)["daily"]) == 1, "daily claim refused, badge kept")
	a.save.set_fault_injector(Callable())
	_ok(a.actions.claim_daily_task(0)["ok"] and a.actions.claim_daily_login()["ok"] and a.economy.wallet.scrub_bucks() == 1200, "after recovery: each claim exactly once")
	_ok(_app(p).economy.wallet.scrub_bucks() == 1200, "durable 1,200")
	_complete("t08_claim_save_failure_rollback")

func _t09() -> void:
	print("[t09 double / repeated taps and retries pay once]")
	var a = _app(_path("t09"))
	a.bootstrap_new_profile()
	for _i in range(6):
		a.actions.claim_daily_task(0)
		a.actions.claim_daily_login()
	_ok(a.economy.wallet.scrub_bucks() == 1200, "6 x (task + daily): +100 +100 once")
	_complete("t09_double_tap_once")

func _t10() -> void:
	print("[t10 strict ftue / welcome sections; invalid rejected with no state change]")
	var a = _app(_path("t10"))
	a.bootstrap_new_profile()
	var e = a.economy
	var good: Dictionary = e.snapshot()
	var bad_ftue := [
		{"version": 2, "profile": "new", "skipped": false, "closed": false, "seen": []},
		{"version": 1, "profile": "new", "skipped": false, "closed": false},
		{"version": 1, "profile": "veteran", "skipped": false, "closed": false, "seen": []},
		{"version": 1, "profile": "new", "skipped": "no", "closed": false, "seen": []},
		{"version": 1, "profile": "new", "skipped": false, "closed": false, "seen": [""]},
		{"version": 1, "profile": "new", "skipped": false, "closed": false, "seen": ["a", "a"]},
		{"version": 1, "profile": "new", "skipped": false, "closed": false, "seen": [], "x": 1},
		5,
	]
	var rejected := 0
	for b in bad_ftue:
		var s: Dictionary = good.duplicate(true)
		s["ftue"] = b
		if not e.import_snapshot(s) and e.snapshot() == good:
			rejected += 1
	_ok(rejected == bad_ftue.size(), "%d/%d malformed ftue sections rejected, state untouched" % [rejected, bad_ftue.size()])
	var bad_daily := [{"welcome_day": 5}, {"welcome_sb": 100}, {"welcome_day": 5, "welcome_sb": 0}, {"welcome_day": 1.5, "welcome_sb": 100}, {"welcome_day": -2, "welcome_sb": 100}]
	rejected = 0
	for b in bad_daily:
		var s: Dictionary = good.duplicate(true)
		var dsec: Dictionary = s["daily"]
		dsec.erase("welcome_day")
		dsec.erase("welcome_sb")
		dsec.merge(b, true)
		if not e.import_snapshot(s) and e.snapshot() == good:
			rejected += 1
	_ok(rejected == bad_daily.size(), "%d/%d malformed welcome pairs rejected" % [rejected, bad_daily.size()])
	var cand: Dictionary = a.save.collect()
	cand["economy"]["ftue"]["profile"] = "x"
	_ok(not bool(a.save.validate_candidate(cand).get("ok", true)), "a save candidate with a bad ftue section fails closed")
	var legacy: Dictionary = good.duplicate(true)
	legacy.erase("ftue")
	legacy["daily"].erase("welcome_day")
	legacy["daily"].erase("welcome_sb")
	_ok(e.import_snapshot(legacy) and not e.ftue.is_new_profile() and not e.ftue.tips_active() and not e.daily.is_welcome_task(0), "absent sections (pre-M44 save) = established, no beginner tips, no Welcome")
	_complete("t10_strict_schema")

func _t11() -> void:
	print("[t11 versioned data-driven config; L1-L3 = real production ids; malformed rejected]")
	var c: Dictionary = FtueConfig.load_config()
	_ok(bool(c.get("ok", false)), "shipped config valid %s" % str(c.get("reason", "")))
	_ok(BOOSTERS.all(func(id): return int(c["starter_booster_charges"][id]) == 2) and int(c["welcome_sb"]) == 100 and int(c["max_tutorial_level"]) == 3, "owner V03 values: 2 each, 100 SB, max L3")
	var order_of := {}
	var cat = LevelCatalog.new()
	cat.load_manifest()
	for en in cat.get_entries_ordered():
		order_of[String(en.id)] = int(en.order)
	var levels: Array = []
	var ids_ok := true
	for l in c["lessons"]:
		if String(l["surface"]) == "gameplay":
			levels.append(int(l["level"]))
			ids_ok = ids_ok and int(order_of.get(String(l["level_id"]), -1)) == int(l["level"])
	levels.sort()
	_ok(levels == [1, 2, 3] and ids_ok, "gameplay lessons exactly L1 / L2 / L3 bound to their catalog ids %s" % str(levels))
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FtueConfig.PATH))
	var muts := {
		"lesson at L4": func(d): d["lessons"][1]["level"] = 4,
		"max level 4": func(d): d["max_tutorial_level"] = 4,
		"fifth booster": func(d): d["starter_booster_charges"]["magnet"] = 2,
		"missing tornado": func(d): d["starter_booster_charges"].erase("tornado"),
		"welcome 0 SB": func(d): d["first_day_welcome_task"]["scrub_bucks"] = 0,
		"welcome slot 1": func(d): d["first_day_welcome_task"]["task_index"] = 1,
		"unknown target": func(d): d["lessons"][1]["steps"][0]["target"] = "shop_offer",
		"duplicate step": func(d): d["lessons"][2]["steps"][1]["id"] = "l2_boosters_a",
		"bad schema": func(d): d["schema"] = "x",
	}
	var rej := 0
	for k in muts:
		var m: Dictionary = raw.duplicate(true)
		(muts[k] as Callable).call(m)
		if not bool(FtueConfig.validate(m).get("ok", true)):
			rej += 1
		else:
			print("    accepted mutation: " + String(k))
	_ok(rej == muts.size(), "%d/%d malformed configs rejected" % [rej, muts.size()])
	# SB-M44-031: no soft-discovery policy any more; gating is feature_unlocks_v1.json.
	_ok(not c.has("available_from_first_home") and not raw["feature_discovery"].has("policy"), "soft_no_hard_locks / available_from_first_home retired")
	_complete("t11_config_strict_data_driven")

func _t12() -> void:
	print("[t12 director: one step at a time, truthful conditions, real actions, skip, settle, What's New]")
	var a = _app(_path("t12"))
	a.bootstrap_new_profile()
	var d = FtueDirector.new(a)
	# SB-M44-031: Daily (L4) / Tasks (L12) are locked on a fresh L1 profile: their tips are skipped.
	_ok(String(d.current_step("home", d.home_context()).get("id", "")) == "home_play", "fresh L1: DAILY / TASKS locked -> first Home tip is PLAY")
	_unlock_at_l1(a, ["daily", "tasks", "plus_one_slot", "random", "selector", "tornado"])
	_ok(String(d.current_step("home", d.home_context()).get("id", "")) == "home_daily", "first Home: DAILY tip first")
	a.actions.claim_daily_login()
	_ok(String(d.current_step("home", d.home_context()).get("id", "")) == "home_tasks", "DAILY claimed -> its tip no longer applies; TASKS tip")
	_ok(d.notify("shortcut:tasks", "home", d.home_context()) and String(d.current_step("home", d.home_context()).get("id", "")) == "home_play", "tapping TASKS completes the TASKS tip")
	var g1 := {"level": 1, "level_id": L1}
	_ok(String(d.current_step("gameplay", g1).get("id", "")) == "l1_tap_front", "L1: first tip = real front tap")
	_ok(d.current_step("gameplay", {"level": 1, "level_id": "level_002_apple"}).is_empty() and d.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"}).is_empty(), "wrong level id / not the frontier: nothing")
	_ok(not d.notify("play", "gameplay", g1) and d.notify("supply_placed", "gameplay", g1) and String(d.current_step("gameplay", g1).get("id", "")) == "l1_slots", "only the real placement completes the front tip")
	_ok(not d.acknowledge("l1_tap_front"), "an acknowledged step cannot be acknowledged twice")
	a.progression.debug_set_current_level(2)
	var st: Dictionary = d.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"})
	var body := String(d.step_copy(st).get("body", ""))
	_ok(String(st.get("id", "")) == "l2_boosters_a" and body.contains(UiText.t("BOOSTER_NAME_PLUS_ONE_SLOT")) and body.contains(UiText.t("BOOSTER_EFFECT_SELECTOR")) and body.contains("owned: 2"), "L2 booster copy: real names / effects / live charges")
	var sb: int = a.economy.wallet.scrub_bucks()
	var c0 := _total(a)
	_ok(d.skip_tips() and not d.tips_active() and d.current_step("gameplay", {"level": 2, "level_id": "level_002_apple"}).is_empty() and not d.skip_tips(), "Skip Tips: once, all tips stop")
	_ok(a.economy.wallet.scrub_bucks() == sb and _total(a) == c0, "Skip Tips changes no wallet / charges")
	var b = _app(_path("t12b"))
	b.bootstrap_new_profile()
	var db = FtueDirector.new(b)
	b.progression.debug_set_current_level(4)
	_ok(db.settle() and b.economy.ftue.closed and not db.settle() and not db.tips_active(), "frontier past L3: window closed once")
	var est = _app(_path("t12e"))
	var de = FtueDirector.new(est)
	_ok(de.current_step("home", de.home_context()).is_empty(), "established profile: no beginner tips")
	var due: Array = de.whats_new_due()
	_ok(due.size() == 1 and de.acknowledge_whats_new(due[0]) and de.whats_new_due().is_empty() and not de.acknowledge_whats_new(due[0]), "What's New once per feature / version")
	_ok(FtueDirector.new(b).whats_new_due().is_empty(), "a new profile gets tips, not What's New")
	var off = FtueDirector.new(_app(_path("t12o")))
	off.enabled = false
	_ok(not off.tips_active() and off.whats_new_due().is_empty(), "presentation seam off: nothing")
	_complete("t12_director_rules")

func _t13() -> void:
	print("[t13 L4..L10: zero scheduled tips, even with the window forced open]")
	var a = _app(_path("t13"))
	a.bootstrap_new_profile()
	_unlock_at_l1(a, ["daily", "tasks", "plus_one_slot", "random", "selector", "tornado"])
	var d = FtueDirector.new(a)
	var cat = LevelCatalog.new()
	cat.load_manifest()
	var none := true
	for en in cat.get_entries_ordered():
		var n := int(en.order)
		if n < 4 or n > 10:
			continue
		a.progression.debug_set_current_level(n)
		a.economy.ftue.closed = false
		none = none and d.current_step("gameplay", {"level": n, "level_id": String(en.id)}).is_empty() and d.current_step("home", d.home_context()).is_empty()
	_ok(none, "no step at levels 4..10 (data has no lesson past L3)")
	_ok((d.config()["lessons"] as Array).all(func(l): return int(l["level"]) <= 3), "every lesson <= L3")
	_complete("t13_no_tutorial_l4_plus")

# ------------------------------------------------------------ real app root ----

func _t14() -> void:
	print("[t14 first Home UI: both real CLAIMs, no forced popup, coachmark on the real panels]")
	await _boot("t14")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	_ok(bool(app.last_bootstrap.get("ok", false)) and _total(app) == 8 and app.economy.wallet.scrub_bucks() == 1000, "fresh boot: starter 2 each, 1,000 SB")
	_ok(_root.get_modal_stack().depth() == 0, "no forced popup / auto claim on first Home")
	_root.refresh_coachmark()
	var daily_b: Button = _root.get_home().get_region("Shortcut_daily")
	var tasks_b: Button = _root.get_home().get_region("Shortcut_tasks")
	# SB-M44-031: fresh L1 Home gates DAILY / TASKS / SHOP / COLLECTION; the tip skips to PLAY.
	_ok(cm.get_step_id() == "home_play" and daily_b.disabled and tasks_b.disabled and _root.get_home().get_region("Shortcut_shop").disabled and _root.get_home().get_region("Shortcut_collection").disabled, "fresh L1: the four panels are locked, tip on PLAY")
	_unlock_at_l1(app, ["daily", "tasks", "shop", "collection"])
	_root.get_home().refresh()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "home_daily" and cm.get_target() == daily_b.get_global_rect(), "Scrubby tip points at the real DAILY panel")
	_ok(not daily_b.disabled and not tasks_b.disabled and not _root.get_home().get_region("Shortcut_shop").disabled and not _root.get_home().get_region("Shortcut_collection").disabled, "all four Home panels live once unlocked")
	tasks_b.pressed.emit()
	await _frames(2)
	_root.refresh_coachmark()
	var p = _top()
	_ok(_top_id() == "tasks" and not cm.is_showing(), "TASKS opens; the tip hides under the popup")
	_ok(p.get_action_button("task:0").text == UiText.t("TASK_REWARD_SB", ["100"]) and _txt_in(p, "Task_0", "Text") == UiText.t("TASK_WELCOME") and not p.get_action_button("task:0").disabled, "Welcome row shows 100 SB, ready")
	_ok(p.get_action_button("task:1").text == "100 SB" and p.get_action_button("task:2").text == "125 SB" and bool(p.get_action_button("scrubbox").disabled), "other rows ordinary; ScrubBox closed")
	p._on_action("task:0")
	await _frames(2)
	_ok(app.economy.wallet.scrub_bucks() == 1100 and p.get_action_button("task:0").text == UiText.t("TASK_CLAIMED"), "+100 SB credited = shown")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "home_daily", "back on Home: DAILY tip (tasks claimed)")
	daily_b.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "daily_login", "DAILY opens")
	_top()._on_action("claim")
	await _frames(2)
	_ok(app.economy.wallet.scrub_bucks() == 1200, "DAILY +100 -> 1,200")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_root.refresh_coachmark()
	var bd: Dictionary = HomeBadges.compute(app)
	_ok(cm.get_step_id() == "home_play" and int(bd["tasks"]) == 0 and int(bd["daily"]) == 0, "both claimed: badges clear; next tip PLAY")
	_ok(AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override).economy.wallet.scrub_bucks() == 1200, "durable 1,200")
	_complete("t14_first_home_ui_claims")

func _t15() -> void:
	print("[t15 L1 / L2 / L3 tips on real controls, real actions only; closes by L3; none at L4]")
	await _boot("t15")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	var sb0: int = app.economy.wallet.scrub_bucks()
	var h0: int = app.economy.hearts.hearts()
	await _play(1)
	var host = _root.get_gameplay_host()
	_root.refresh_coachmark()
	var panel = host.get_screen().get_supply_panel()
	var col := -1
	for c in range(panel.get_column_count()):
		if col < 0 and panel.get_front_enabled(c):
			col = c
	_ok(cm.get_step_id() == "l1_tap_front" and col >= 0 and cm.get_target() == panel.get_front_hit_rect(col), "L1 pointer on a real legal front batch")
	var expect: int = host.get_slots().rightmost_empty_index()
	var r: Dictionary = host.get_input_controller().activate_front(col)
	_ok(bool(r.get("ok", false)) and int(host.get_input_controller().get_last_placement().get("slot", -9)) == expect, "real front press -> rightmost EMPTY slot %d" % expect)
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l1_slots" and cm.get_target() == host.get_screen().get_five_slot_strip_rect(), "the real placement completed the tip; slots tip on the real strip")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	var front_r: Rect2 = panel.get_front_hit_rect(col)
	_ok(cm.get_step_id() == "l1_preview" and cm.get_target().has_area() and not cm.get_target().intersects(front_r), "preview tip frames the preview rows, not the front")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l1_cleaning", "cleaning tip")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(not cm.is_showing(), "L1 lesson complete")
	await _play(2)
	host = _root.get_gameplay_host()
	_root.refresh_coachmark()
	# SB-M44-031: all four boosters are locked at a fresh L2, so both L2 booster steps are skipped.
	_ok(not cm.is_showing() and host.booster_states().all(func(s): return String(s["state"]) == "locked"), "fresh L2: boosters locked, no booster tip")
	_unlock_at_l1(app, BOOSTERS)
	_root.refresh_coachmark()
	var scr = host.get_screen()
	var ab: Rect2 = scr.get_booster_button("plus_one_slot").get_global_rect().merge(scr.get_booster_button("selector").get_global_rect())
	var body: String = cm.get_body_label().text
	_ok(cm.get_step_id() == "l2_boosters_a" and cm.get_target() == ab and body.contains(UiText.t("BOOSTER_NAME_PLUS_ONE_SLOT")) and body.contains("owned: 2"), "L2 phase 1 on the real +1 Slot / Selector controls with live count")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	body = cm.get_body_label().text
	_ok(cm.get_step_id() == "l2_boosters_b" and body.contains(UiText.t("BOOSTER_NAME_RANDOM")) and body.contains(UiText.t("BOOSTER_NAME_TORNADO")), "L2 phase 2: Random / Tornado")
	_ok(_total(app) == 8 and app.economy.wallet.scrub_bucks() == sb0, "introducing boosters spent nothing")
	cm.get_got_it_button().pressed.emit()
	await _play(3)
	host = _root.get_gameplay_host()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l3_waiting", "L3 waiting tip (informational, no forced stall)")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l3_hearts" and not cm.get_pointer().visible, "Hearts / Retry as information (no forced loss, nothing to point at)")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l3_speed" and cm.get_target() == host.get_screen().get_speed_button().get_global_rect(), "2x tip on the real 2x control")
	_ok(app.economy.speed.timed_seconds_remaining() == 0 and not app.economy.speed.is_manual_2x_entitled(3), "no paid 2x granted or started")
	_ok(app.economy.hearts.hearts() == h0, "no Heart lost by any tip")
	host._drive_economy_terminal(CompletionEvaluator.WON)
	_root.get_modal_stack().clear("test")
	_root.get_navigation().go(NavigationController.Route.HOME)
	await _frames(2)
	_ok(app.progression.current_level() == 4 and app.economy.ftue.closed, "L3 won -> compulsory window closed (even with l3_speed unacknowledged)")
	await _play(4)
	_root.refresh_coachmark()
	_ok(not cm.is_showing(), "L4: no tutorial")
	_complete("t15_gameplay_l1_l3_real_controls")

func _t16() -> void:
	print("[t16 Skip Tips (tips only, persisted); Help & Tips read-only]")
	await _boot("t16")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	_root.refresh_coachmark()
	_ok(cm.is_showing(), "tip shown")
	cm.get_skip_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(app.economy.ftue.skipped and not cm.is_showing(), "SKIP TIPS hides all beginner tips")
	var re = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(re.economy.ftue.skipped and _total(re) == 8 and re.economy.daily.is_welcome_task(0) and re.economy.daily.is_task_done(0), "skip persisted; starter charges + Welcome claim untouched")
	await _play(1)
	_root.refresh_coachmark()
	_ok(not cm.is_showing(), "skipped: no L1 tip")
	_root.get_modal_stack().clear("test")
	_root.get_navigation().go(NavigationController.Route.HOME)
	await _frames(2)
	var econ0 := JSON.stringify(app.economy.snapshot())
	var prog0 := JSON.stringify(app.progression.snapshot())
	_root.open_settings()
	await _frames(2)
	_root.get_settings_panel().get_help_button().pressed.emit()
	await _frames(2)
	var hp = _top()
	_ok(_top_id() == "help_tips" and not _root.get_navigation().is_settings_open(), "Settings ? -> Help & Tips popup")
	_ok(hp.get_action_ids() == ["close"], "exactly one action: CLOSE (no replay / claim / restart)")
	var lines_ok := true
	for id in BOOSTERS:
		var l = hp.find_child("Booster_" + id, true, false)
		lines_ok = lines_ok and l is Label and (l as Label).text == UiText.t("FTUE_BOOSTER_LINE", [UiText.t("BOOSTER_NAME_" + id.to_upper()), "2", UiText.t("BOOSTER_EFFECT_" + id.to_upper())])
	_ok(lines_ok, "all four boosters: name, effect, live owned count")
	hp._on_action("close")
	await _frames(2)
	_ok(JSON.stringify(app.economy.snapshot()) == econ0 and JSON.stringify(app.progression.snapshot()) == prog0, "Help wrote no economy / progression state")
	_complete("t16_skip_tips_help_read_only")

func _t17() -> void:
	print("[t17 established (pre-M44 style) save: no beginner overlay, no grant, What's New once]")
	var p := _path("t17")
	var a = _app(p)
	a.progression.record_win(1)
	_ok(bool(a.request_save().get("ok", false)) and FileAccess.file_exists(p) and a.progression.current_level() == 2, "fixture: established save at L2 written")
	await _boot("t17", Vector2i(1080, 2160), p)
	var app = _root.get_app_state()
	await _frames(3)
	_ok(String(app.last_bootstrap.get("reason", "")) == "not_fresh" and _total(app) == 0 and not app.economy.daily.is_welcome_task(0), "existing save: no starter, no Welcome")
	_ok(_top_id() == "ceremony_feature_unlock" and not _root.get_coachmarks().is_showing(), "What's New via the M43 Feature Unlock ceremony; no tips")
	if _top() != null:
		_top()._on_action("got_it")
	await _frames(3)
	_ok(app.economy.meta_ui.is_seen("feature:help_tips:1"), "acknowledged (durable presentation mark)")
	await _boot("t17b", Vector2i(1080, 2160), p)
	await _frames(3)
	_ok(_top_id() != "ceremony_feature_unlock", "relaunch: not shown again")
	_complete("t17_old_save_whats_new_once")

func _t18() -> void:
	print("[t18 layout matrix, non-blocking overlay, Reduced Effects, tween cleanup]")
	for size in [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(1536, 2048), Vector2i(720, 1280)]:
		await _boot("t18", size)
		var cm = _root.get_coachmarks()
		_root.refresh_coachmark()
		await _frames(2)   # let the button row sort its children
		var vp := Rect2(Vector2.ZERO, Vector2(size)).grow(0.5)
		var bub := Rect2(cm.get_bubble().position, cm.get_bubble().size)
		var btn := Rect2(cm.get_got_it_button().global_position, cm.get_got_it_button().size)
		var ok: bool = cm.is_showing() and vp.encloses(bub) and vp.encloses(btn) and cm.text_fits()
		ok = ok and cm.get_got_it_button().size.y >= 88.0 - 0.5 and cm.get_skip_button().size.y >= 88.0 - 0.5
		ok = ok and not bub.intersects(cm.get_target()) and not btn.intersects(cm.get_target())
		_ok(ok, "%s: bubble %s inside, text fits, 88 px buttons, target uncovered" % [str(size), str(bub)])
	var cm2 = _root.get_coachmarks()
	var ign := true
	for n in [cm2.get_root(), cm2.get_bubble(), cm2.get_ring(), cm2.get_pointer(), cm2.get_title_label(), cm2.get_body_label()]:
		ign = ign and (n as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE
	_ok(ign and cm2.get_got_it_button().mouse_filter == Control.MOUSE_FILTER_STOP, "overlay ignores input except its two buttons (real controls stay tappable)")
	_ok(cm2.has_live_tween(), "pointer motion in full effects")
	_root.get_app_state().set_reduced_effects(true)
	_root.refresh_coachmark()
	_ok(cm2.is_showing() and not cm2.has_live_tween() and cm2.is_reduced(), "Reduced Effects: same tip, no motion")
	_root.get_app_state().set_reduced_effects(false)
	_root.refresh_coachmark()
	cm2.get_skip_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(not cm2.is_showing() and not cm2.has_live_tween(), "hidden: tween killed")
	_complete("t18_layout_reduced_effects_non_blocking")

func _t19() -> void:
	print("[t19 background flush / relaunch mid-lesson; popup hides the tip; no replay of acknowledged]")
	await _boot("t19")
	var path: String = MainScript.boot_save_path_override
	await _play(1)
	var host = _root.get_gameplay_host()
	var panel = host.get_screen().get_supply_panel()
	for c in range(panel.get_column_count()):
		if panel.get_front_enabled(c):
			host.get_input_controller().activate_front(c)
			break
	_root.flush_lifecycle("application_paused")
	var re = AppState.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(re.economy.ftue.is_seen("l1_tap_front") and not re.economy.ftue.is_seen("l1_slots"), "acknowledged step persisted at the lifecycle flush")
	await _boot("t19b", Vector2i(1080, 2160), path)
	var app = _root.get_app_state()
	_ok(_total(app) == 8 and bool(app.last_bootstrap.get("replay", false)), "relaunch: replay, no second starter grant")
	await _play(1)
	var cm = _root.get_coachmarks()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l1_slots", "relaunch resumes at the next tip (front tip never replays)")
	_root.get_gameplay_host().open_pause()
	await _frames(2)
	_root.refresh_coachmark()
	_ok(_root.get_modal_stack().depth() > 0 and not cm.is_showing(), "Pause popup: tip hidden (never over a popup)")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "l1_slots", "popup closed: same tip back, not double-acknowledged")
	_complete("t19_relaunch_modal_resume")

func _t20() -> void:
	print("[t20 M44-021..024 on a fresh profile: no Comeback, no fake events, Orders active, truthful Results]")
	await _boot("t20")
	var e = _root.get_app_state().economy
	_ok(not e.returns.summary_due() and not bool(e.returns.on_active().get("opened", true)), "Comeback Catch-Up never for a fresh profile")
	_ok(e.events.claimable_count() == 0, "no fabricated Weekly / First-Try reward")
	var o: Array = e.orders.orders()
	_ok(o.size() == 3 and bool(o[1]["available"]) and bool(o[2]["available"]), "Daily Scrub Orders live from day one (slots 1, 2)")
	var m: Dictionary = _root._results_model({"status": "WON", "level": 1, "attempt": 1})
	_ok(m.has("momentum") and bool(m["continue"].get("available", false)) and int(m["continue"].get("next_level", 0)) == 1, "Results journey / Next Cleanup from the canonical resolver (no invented level)")
	_complete("t20_fresh_meta_dependencies")

func _t21() -> void:
	print("[t21 static guards: presentation code owns no economy path; tiers; no WAITING/ACTIVE copy]")
	var src := ""
	for f in ["res://scripts/app/ftue_director.gd", "res://scripts/ui/tutorial/coachmark_layer.gd", "res://scripts/ui/tutorial/help_tips_screen.gd"]:
		src += _code_only(FileAccess.get_file_as_string(f))
	var banned := [".grant(", "debit(", "credit(", "claim_login", "claim_task(", "buy_", "apply_random", "apply_selector", "apply_tornado", "plus_one_slot()", "record_win", "hearts.consume", "set_speed_2x", "purchase", "add_charges", "reserve("]
	var hits: Array = banned.filter(func(b): return src.contains(b))
	_ok(hits.is_empty(), "no grant / spend / claim / booster / 2x / progression call in FTUE presentation %s" % str(hits))
	var econ: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/economy_rewards_v1.json"))
	_ok((econ["daily"]["task_sb"] as Array).map(func(v): return int(v)) == [75, 100, 125], "economy config task tiers unchanged")
	var copy_ok := true
	for k in UiText.EN:
		if String(k).begins_with("FTUE_") or String(k).begins_with("HELP_"):
			var v := String(UiText.EN[k])
			copy_ok = copy_ok and not v.contains("WAITING") and not v.contains("ACTIVE")
	_ok(copy_ok, "no WAITING / ACTIVE tile words reintroduced")
	var op := FileAccess.get_file_as_string("res://scripts/app/opening_screen.gd").to_lower()
	_ok(not op.contains("skip"), "opening cinematic has no skip path (M42 non-skippable)")
	_complete("t21_static_guards")

## Owner D2 (OWNER_D2_WHATS_NEW_AND_DISK_DIAG_DECISION_V01): a simulated LATER build that adds
## one feature version to the real config (real catalog / levels untouched).
func _later_raw() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FtueConfig.PATH))
	(raw["whats_new"] as Array).append({"feature_id": "m44_d2_future_probe", "version": 2,
		"name": "FTUE_WHATSNEW_HELP_NAME", "body": "FTUE_WHATSNEW_HELP_BODY",
		"icon": "res://assets/ui/final/gameplay/tutorial/speech_bubble.png"})
	return raw

## The later build's config through the SAME strict reader production uses.
func _later_cfg() -> Dictionary:
	return FtueConfig.validate(_later_raw())

## Economy truth that What's New must never touch.
func _econ_core(app) -> String:
	var s: Dictionary = app.economy.snapshot()
	return JSON.stringify([s["reward"], s["boosters"], s["daily"], s["hearts"]["hearts"], s["speed"]["entitled_level"], s["speed"]["timed_expiry"], s["pending_packs"]])

func _t22() -> void:
	print("[t22 owner D2: new profile sees only LATER What's New, once, only after genuine L3]")
	var p := _path("t22")
	var a = _app(p)
	a.bootstrap_new_profile()
	var later := _later_cfg()
	_ok(bool(later.get("ok", false)) and (later["whats_new"] as Array).size() == 2, "simulated later-build config passes the strict reader")
	var d = FtueDirector.new(a, later)
	_ok(a.economy.meta_ui.is_seen("feature:help_tips:1"), "bootstrap baselined this build's What's New entries (presentation only)")
	_ok(d.whats_new_due().is_empty(), "L1, onboarding open: nothing, even with a later feature version")
	_ok(d.skip_tips() and d.whats_new_due().is_empty(), "Skip Tips before L3 does not open What's New")
	a.progression.record_win(1)
	a.progression.record_win(2)
	_ok(not d.settle() and d.whats_new_due().is_empty(), "after L2: still onboarding")
	var core0 := _econ_core(a)
	a.progression.record_win(3)
	_ok(d.settle() and a.economy.ftue.closed, "genuine L3 completion closes the window")
	var due: Array = d.whats_new_due()
	_ok(due.size() == 1 and String(due[0]["feature_id"]) == "m44_d2_future_probe", "only the later feature version is due (bootstrap-era Help & Tips suppressed)")
	a.save.set_fault_injector(func(stage): return stage == "temp_write")
	_ok(not d.acknowledge_whats_new(due[0]) and not a.economy.meta_ui.is_seen("feature:m44_d2_future_probe:2"), "ack with a failed save: not durably dismissed (fail closed)")
	_ok(d.whats_new_due().is_empty() and FtueDirector.new(a, later).whats_new_due().size() == 1, "snoozed for this session only (no re-open loop); due again for a new session")
	a.save.set_fault_injector(Callable())
	_ok(d.acknowledge_whats_new(due[0]) and d.whats_new_due().is_empty() and not d.acknowledge_whats_new(due[0]), "durable ack, exactly once")
	var re = _app(p)
	_ok(re.economy.meta_ui.is_seen("feature:m44_d2_future_probe:2") and FtueDirector.new(re, later).whats_new_due().is_empty(), "relaunch: never again")
	_ok(_econ_core(a) == core0, "wallet / ledger / boosters / Daily / Hearts / 2x / packs untouched by What's New")
	var est = _app(_path("t22e"))
	var de = FtueDirector.new(est, later)
	_ok(de.whats_new_due().size() == 2 and not est.economy.meta_ui.is_seen("feature:help_tips:1"), "established profile unchanged: both unseen entries due")
	var bad: Dictionary = _later_raw()
	(bad["whats_new"] as Array)[1]["version"] = 0
	_ok(not bool(FtueConfig.validate(bad).get("ok", true)) and String(FtueConfig.validate(bad).get("reason", "")) == "whats_new", "malformed later entry (version 0) rejected for exactly that reason")
	_ok(not d.use_config(bad) and not d.use_config({}), "use_config refuses an unvalidated config")
	_complete("t22_d2_future_whats_new_rules")

func _t23() -> void:
	print("[t23 owner D2 in the real app: Feature Unlock ceremony once on quiet Home after L3, never during onboarding]")
	await _boot("t23")
	var path: String = MainScript.boot_save_path_override
	var app = _root.get_app_state()
	var f = _root.get_ftue()
	f.use_config(_later_cfg())
	_root.request_home_ceremonies()
	await _frames(3)
	_ok(f.whats_new_due().is_empty() and _top_id() != "ceremony_feature_unlock", "during onboarding (L1 frontier): no What's New due or shown on Home")
	_root.get_modal_stack().clear("test")
	for n in [1, 2, 3]:
		app.progression.record_win(n)
	var core0 := _econ_core(app)
	_root.get_navigation().go(NavigationController.Route.HOME)   # Home entry settles the window
	f.settle()
	_root.request_home_ceremonies()
	await _frames(4)
	var top = _top()
	var name_l = top.find_child("FeatureName", true, false) if top != null else null
	_ok(app.economy.ftue.closed and _top_id() == "ceremony_feature_unlock" and name_l is Label, "after genuine L3: the later feature shows via the M43 Feature Unlock ceremony")
	if top != null:
		top._on_action("got_it")
	await _frames(3)
	_ok(app.economy.meta_ui.is_seen("feature:m44_d2_future_probe:2") and _top_id() != "ceremony_feature_unlock", "acknowledged by its CTA, not re-opened")
	_ok(_econ_core(app) == core0, "no reward / booster / Daily / Hearts change from the ceremony")
	await _boot("t23b", Vector2i(1080, 2160), path)
	_root.get_ftue().use_config(_later_cfg())
	_root.request_home_ceremonies()
	await _frames(4)
	_ok(_root.get_ftue().whats_new_due().is_empty() and _top_id() != "ceremony_feature_unlock", "relaunch: not due and not shown again")
	_complete("t23_d2_quiet_home_once")

# ------------------------------------------------------------------ helpers ----

func _path(tag: String) -> String:
	var p := "user://m44_ftue_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _app(path: String):
	return AppState.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)

## SB-M44-031 test seam: the in-memory unlock table opens `ids` at L1, so the L1-L3 coachmark
## content they guard stays covered (the shipped table locks them past the tutorial window).
func _unlock_at_l1(app, ids: Array) -> void:
	for id in ids:
		app.unlocks.cfg["unlocks"][id] = 1

func _write(path: String, text: String) -> void:
	if not _tmp.has(path):
		_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _total(app) -> int:
	var n := 0
	for id in BOOSTERS:
		n += int(app.economy.boosters.charges(id))
	return n

func _boot(tag: String, size := Vector2i(1080, 2160), path := "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path if not path.is_empty() else _path("boot_" + tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _play(level: int) -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	if nav.current() != NavigationController.Route.HOME:
		nav.go(NavigationController.Route.HOME)
		await _frames(2)
	_root.get_modal_stack().clear("test")
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(6)
	var h = _root.get_gameplay_host()
	if h != null:
		h.get_runtime().set_process(false)

func _code_only(src: String) -> String:
	var out: PackedStringArray = []
	for line in src.split("\n"):
		if not line.strip_edges().begins_with("#"):
			out.append(line)
	return "\n".join(out)

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
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M44 FTUE evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
