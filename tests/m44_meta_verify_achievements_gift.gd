extends SceneTree
## SB-M44-028 + SB-M44-030 (owner 2026-11-03 meta at L1) against the REAL app root (main.tscn),
## no test_unlock_all, injected clock / local day:
##   - the 50 SB-POLISH-007 achievements are intact: ids / metrics / targets / tiers / rewards
##     pinned by fingerprint (never the old 8->32 plan, never cosmetic-only);
##   - first Home at L1: Achievements reachable from Profile, every stat 0; Gift Bar visible at
##     0/1 on the schema-3 cycle 1/5/10/25/100/250/500/1000;
##   - the first L1 win counts: levels_completed / streak 1, Clean Start claimable, Gift Bar 1/5
##     with GIFT 1 (25 SB) claimable once;
##   - an achievement CLAIM pays exactly once across replay, relaunch and snapshot import.
##
## Run: godot --headless --path . -s res://tests/m44_meta_verify_achievements_gift.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

const CYCLE := [1, 5, 10, 25, 100, 250, 500, 1000]
## sha256 of the id|metric|target|tier|reward lines of data/config/achievements_v2.json (shipped
## SB-POLISH-007 table). Changing any reward / target needs a separate owner decision.
const FINGERPRINT := "eaf4e9474e9a14d9989668716dbb2d04a58f508cf81e91cb75b0625befd1e47e"
const TIER_COUNTS := {"bronze": 13, "silver": 12, "gold": 15, "platinum": 10}

var EXPECTED_CASES := ["a01_fifty_intact", "a02_first_home_l1", "a03_first_win_counts", "a04_claim_once"]

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
	_fifty_intact()
	var p := _path("first")
	await _first_home(p)
	await _first_win()
	await _claim_once(p)
	_shutdown()
	_cleanup()
	_done()

func _fifty_intact() -> void:
	print("[a01 the 50 SB-POLISH-007 achievements: pinned ids / targets / rewards]")
	var defs := Achievements.load_defs()
	var lines: Array = []
	var tiers := {}
	for a in defs:
		var r: Dictionary = a["reward"]
		var keys: Array = r.keys()
		keys.sort()
		lines.append("%s|%s|%d|%s|%s" % [a["id"], a["metric"], int(a["target"]), a["tier"], ",".join(keys.map(func(k): return "%s=%d" % [k, int(r[k])]))])
		tiers[a["tier"]] = int(tiers.get(a["tier"], 0)) + 1
	var fp := "\n".join(lines).sha256_text()
	print("  fingerprint " + fp)
	_ok(defs.size() == 50, "exactly 50 definitions (%d)" % defs.size())
	_ok(tiers == TIER_COUNTS, "tier split %s" % str(tiers))
	_ok(fp == FINGERPRINT, "ids / metrics / targets / tiers / rewards unchanged")
	_ok(defs.all(func(a): return not (a["reward"] as Dictionary).is_empty()), "every achievement pays an economic reward (not cosmetic-only)")
	_complete("a01_fifty_intact")

func _first_home(p: String) -> void:
	print("[a02 first Home at L1: Achievements from Profile, Gift Bar 0/1 on the schema-3 cycle]")
	await _boot(p)
	var app = _root.get_app_state()
	var home = _root.get_home()
	var e = app.economy
	_ok(e.ftue.is_new_profile() and app.progression.current_level() == 1 and not AppState.test_unlock_all, "fresh profile at L1, real gates")
	var s := Achievements.stats(app)
	_ok(s.keys().all(func(k): return int(s[k]) == (1 if k == "robots_unlocked" else 0)) and Achievements.claimable_count(app) == 0, "stats start fresh at L1 (only the starter robot), nothing claimable %s" % str(s))
	_ok(app.feature_unlocked("achievements") and app.feature_unlocked("gift_bar"), "Achievements + Gift Bar unlocked at L1")
	(home.get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	_tap("achievements")
	await _frames(2)
	_ok(_top_id() == "achievements" and _top().find_child("Ach_clean_start", true, false) != null, "Profile -> ACHIEVEMENTS opens at L1 with the cards")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_ok(e.config.gift_meter_milestones() == CYCLE and e.config.gift_meter_milestone(1).keys() == ["scrub_bucks"] and int(e.config.gift_meter_milestone(1)["scrub_bucks"]) == 25, "economy_rewards_v1 schema-3 cycle %s, GIFT 1 = 25 SB" % str(e.config.gift_meter_milestones()))
	home.refresh()
	var btn: Button = home.get_region("GiftMeterButton")
	var meter = home.get_region("GiftMeterBar")
	_ok(btn.is_visible_in_tree() and not btn.disabled and meter.caption.text == "0/1" and int(home.get_view_model()["gift_next_milestone"]) == 1, "Gift Bar visible, enabled, '%s' toward GIFT 1" % meter.caption.text)
	_complete("a02_first_home_l1")

func _first_win() -> void:
	print("[a03 first L1 win: stats count, Clean Start claimable, Gift Bar 1/5, GIFT 1 once]")
	var app = _root.get_app_state()
	var e = app.economy
	await _play()
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.WON)
	await _home()
	var s := Achievements.stats(app)
	_ok(int(s["levels_completed"]) == 1 and int(s["best_win_streak"]) == 1, "L1 win counted: levels_completed 1, best streak 1")
	var open_ids: Array = Achievements.evaluate(app).filter(func(x): return x["claimable"]).map(func(x): return x["id"])
	_ok(open_ids == ["clean_start", "no_help_needed"] and int(HomeBadges.compute(app)["achievements"]) == 2, "Clean Start + No Help Needed claimable after the first clear, badge 2 %s" % str(open_ids))
	var home = _root.get_home()
	home.refresh()
	_ok(home.get_region("GiftMeterBar").caption.text == "1/5" and int(e.gift.total_progress()) == 1, "Gift Bar progressed: '%s'" % home.get_region("GiftMeterBar").caption.text)
	var q: Array = e.gift.claimable()
	_ok(q.size() == 1 and int(q[0]["milestone"]) == 1 and int(HomeBadges.compute(app)["gift_bar"]) == 1, "GIFT 1 queued, Gift Bar badge 1 %s" % str(q))
	var sb0: int = e.wallet.scrub_bucks()
	var first: Dictionary = app.actions.claim_gift(String(q[0]["id"]))
	var again: Dictionary = app.actions.claim_gift(String(q[0]["id"]))
	_ok(first["ok"] and not again["ok"] and e.wallet.scrub_bucks() == sb0 + 25 and int(Achievements.stats(app)["gifts_claimed"]) == 1, "GIFT 1: +25 SB once, second claim refused, gifts_claimed 1")
	_complete("a03_first_win_counts")

func _claim_once(p: String) -> void:
	print("[a04 Clean Start CLAIM pays once across replay, relaunch, snapshot import]")
	var app = _root.get_app_state()
	var e = app.economy
	var sb0: int = e.wallet.scrub_bucks()
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	_tap("achievements")
	await _frames(2)
	for _i in range(3):
		_tap("ach:clean_start")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 100 and e.reward.already_applied("achievement:clean_start"), "3 CLAIM taps: exactly +100 SB through tx achievement:clean_start")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	var sb1: int = e.wallet.scrub_bucks()
	# Replay: a WON for the already-cleared L1 (stale attempt on the L2 host) commits nothing.
	await _play()
	var host = _root.get_gameplay_host()
	host.progression_level = 1
	host._drive_economy_terminal(CompletionEvaluator.WON)
	var replay: Dictionary = host.last_first_clear_result
	await _home()
	_ok(not bool(replay.get("ok", false)) and int(Achievements.stats(app)["levels_completed"]) == 1 and app.progression.current_level() == 2
		and not app.actions.claim_achievement(app, "clean_start")["ok"] and e.wallet.scrub_bucks() == sb1, "replay L1 to WON: still 1 clear, claim refused, wallet %d" % e.wallet.scrub_bucks())
	_ok(bool(app.request_save()["ok"]), "saved")
	await _boot(p)
	var re = _root.get_app_state()
	var r: Dictionary = re.actions.claim_achievement(re, "clean_start")
	_ok(re.economy.wallet.scrub_bucks() == sb1 and not r["ok"] and r["reason"] == "already_claimed" and int(HomeBadges.compute(re)["achievements"]) == Achievements.claimable_count(re), "relaunch: claimed kept, re-claim refused, badge excludes it")
	var econ: Dictionary = re.economy.snapshot()
	var prog: Dictionary = re.progression.snapshot()
	var im = AppState.new(_path("import"), MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(im.economy.import_snapshot(econ) and im.progression.import_snapshot(prog), "snapshot imported into a fresh profile")
	var ri: Dictionary = im.actions.claim_achievement(im, "clean_start")
	_ok(im.economy.wallet.scrub_bucks() == sb1 and not ri["ok"] and ri["reason"] == "already_claimed" and int(Achievements.stats(im)["levels_completed"]) == 1, "after import: same wallet, claim refused, stats kept")
	_complete("a04_claim_once")

# ------------------------------------------------------------------ helpers ----

func _play() -> void:
	_root.get_modal_stack().clear("test")
	_root.play_current_frontier()
	await _frames(6)
	_root.get_gameplay_host().get_runtime().set_process(false)

func _home() -> void:
	_root.get_modal_stack().clear("test")
	_root.get_navigation().go(NavigationController.Route.HOME)
	await _frames(3)
	_root.get_modal_stack().clear("test")

func _boot(path: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
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

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _path(tag: String) -> String:
	var p := "user://m44_meta_verify_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M44 meta verify achievements + gift evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
