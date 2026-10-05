extends SceneTree
## M43 master — Lanes C009 Tasks / Daily / Gift Bar + C009R Daily Scrub Orders / ScrubBox
## (SB-M43-112..121, SB-M43-R09-001..006). Real app root (main.tscn) with injected clock and
## local calendar day; real AppState / facade / ModalStack / gameplay host.
##
## Run: godot --headless --path . -s res://tests/m43_master_c009_daily.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const DailyOrders = preload("res://scripts/economy/daily_orders.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

var EXPECTED_CASES := [
	"t01_tasks_destination_three_orders", "t02_orders_deterministic_no_reroll", "t03_progress_from_real_wins_only",
	"t04_task_claim_exactly_once", "t05_scrubbox_all_three_once", "t06_daily_destination_states",
	"t07_daily_rollover_missed_rollback", "t08_gift_bar_claim_history_non_recursive", "t09_eligibility_frontier_content",
	"t10_strict_import_and_pool", "t11_no_paid_path_surprise_disabled", "t12_duplicate_taps",
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
	await _t01()
	await _t02()
	await _t03()
	await _t04()
	await _t05()
	await _t06()
	await _t07()
	await _t08()
	await _t09()
	await _t10()
	await _t11()
	await _t12()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _t01() -> void:
	print("[t01 Home TASKS -> real Tasks destination, exactly three orders, 75/100/125 SB]")
	await _boot("t01")
	var b: Button = _root.get_home().get_region("Shortcut_tasks")
	_ok(not b.disabled, "TASKS panel live")
	var h = _root.get_home()
	_ok(not h.get_region("Shortcut_shop").disabled and not h.get_region("Shortcut_collection").disabled and not h.get_region("Shortcut_daily").disabled, "SHOP / COLLECTION / DAILY panels tappable in the real app (follow-up SB-M43-078 / 090)")
	b.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "tasks" and _root.get_home().get_popup("tasks") == null, "TASKS -> app-level Tasks (no Home placeholder)")
	var o: Array = _eco().orders.orders()
	_ok(o.size() == 3 and o.map(func(x): return x["tier"]) == ["easy", "normal", "stretch"] and o.all(func(x): return x["available"]), "three orders easy / normal / stretch %s" % str(o.map(func(x): return x["id"])))
	var labels: Array = []
	for i in range(3):
		labels.append(_top().get_action_button("task:%d" % i).text)
	_ok(labels == ["75 SB", "100 SB", "125 SB"], "per-task reward from config %s" % str(labels))
	_ok(_top().find_child("ScrubBox", true, false) != null and bool(_top().get_action_button("scrubbox").disabled), "ScrubBox shown, closed until all three are done")
	_complete("t01_tasks_destination_three_orders")

func _t02() -> void:
	print("[t02 deterministic per local day, persisted, never rerolled on relaunch]")
	await _boot("t02")
	var ids0: Array = _ids()
	var path: String = MainScript.boot_save_path_override
	_root.get_app_state().request_save()
	var re = AppState.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(_ids_of(re) == ids0, "relaunch same day: same orders %s" % str(ids0))
	var o2 = DailyOrders.new(_eco().daily)
	o2.bind_context(func(): return _ctx())
	_ok(o2.generate(_day[0], _ctx()) == ids0, "pure function of (version, day, eligibility)")
	_eco().orders.on_level_won({"difficulty": "EASY", "boosters_used": 0, "cells": 10})
	var p0: Array = _progress()
	_day[0] += 1
	var ids1: Array = _ids()
	_ok(_progress() == [0, 0, 0] and ids1 == o2.generate(_day[0], _ctx()), "next local day: fresh deterministic orders %s" % str(ids1))
	_day[0] -= 1
	_ok(_ids() == ids1 and _eco().orders.on_level_won({"difficulty": "EASY", "cells": 400}).is_empty() and _progress() == [0, 0, 0], "clock rollback: no regeneration, no progress")
	_day[0] += 1
	_ok(p0.any(func(v): return v > 0), "progress had counted before the rollover %s" % str(p0))
	_complete("t02_orders_deterministic_no_reroll")

func _t03() -> void:
	print("[t03 progress only from committed progression wins (real host)]")
	await _boot("t03")
	_force_orders(["win_1", "win_no_booster_1", "clear_2000"])
	await _play(1)
	var host = _root.get_gameplay_host()
	var cells: int = host.get_board().get_cell_count() if host.has_method("get_board") else 0
	host._drive_economy_terminal(CompletionEvaluator.LOST)
	_ok(_progress() == [0, 0, 0], "a LOST terminal counts nothing")
	await _play(1)
	host = _root.get_gameplay_host()
	host._drive_economy_terminal(CompletionEvaluator.WON)
	var pr := _progress()
	_ok(pr[0] == 1 and pr[1] == 1 and pr[2] > 0, "WON (no booster): win 1/1, no-booster 1/1, pixels %s" % str(pr))
	_ok(_eco().daily.is_task_done(0) and _eco().daily.is_task_done(1) and not _eco().daily.is_task_done(2), "targets met -> DailyService tasks done")
	var re = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(_progress_of(re) == pr, "progress saved at the terminal boundary")
	await _play(2)
	host = _root.get_gameplay_host()
	_day[0] += 1   # fresh day: yesterday's done tasks are not re-counted
	_force_orders(["win_1", "win_no_booster_1", "clear_2000"])
	host.on_booster_committed()   # the facade's committed-booster seam (any booster)
	host._drive_economy_terminal(CompletionEvaluator.WON)
	var pb := _progress()
	_ok(host.get_attempt_boosters_used() == 1 and pb[0] == 1 and pb[1] == 0, "win with a committed booster: counts as a win, not as boosterless %s" % str(pb))
	_complete("t03_progress_from_real_wins_only")

func _t04() -> void:
	print("[t04 task claim exactly once, after completion only]")
	await _boot("t04")
	var e = _eco()
	var p = await _open_tasks()
	var sb0: int = e.wallet.scrub_bucks()
	_ok(bool(p.get_action_button("task:0").disabled), "not done: CLAIM blocked")
	_complete_orders([0])
	DailyScreens.refresh_tasks(p, _root.get_app_state())
	_tap("task:0")
	await _frames(1)
	_ok(e.wallet.scrub_bucks() == sb0 + 75 and p.get_action_button("task:0").text == UiText.t("TASK_CLAIMED") and bool(p.get_action_button("task:0").disabled), "+75 SB once; CLAIMED")
	_ok(not _root.get_app_state().actions.claim_daily_task(0)["ok"] and e.wallet.scrub_bucks() == sb0 + 75, "facade re-claim refused")
	var re = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(re.economy.daily.task_claimed(0) and not re.actions.claim_daily_task(0)["ok"], "claim survives relaunch, no second grant")
	_complete("t04_task_claim_exactly_once")

func _t05() -> void:
	print("[t05 all three -> earned ScrubBox: one Random Booster Charge exactly once]")
	await _boot("t05")
	var e = _eco()
	var p = await _open_tasks()
	_complete_orders([0, 1, 2])
	DailyScreens.refresh_tasks(p, _root.get_app_state())
	var r0: int = e.boosters.charges("random")
	_ok(not p.get_action_button("scrubbox").disabled, "3/3: OPEN enabled")
	_tap("scrubbox")
	await _frames(2)
	_ok(_top_id() == "ceremony_scrubbox" and e.boosters.charges("random") == r0 + 1, "ScrubBox ceremony after the commit; +1 Random charge")
	_ok(_top().find_child("RewardText", true, false).text == UiText.reward_text({"random_booster_charges": 1}), "shows exactly what was granted")
	_tap("ok")
	await _frames(2)
	await create_timer(0.5).timeout
	_ok(_top_id() == "tasks" and bool(_top().get_action_button("scrubbox").disabled) and _txt_in(_top(), "ScrubBox", "Text") == UiText.t("TASKS_BOX_OPENED"), "back on Tasks: opened, blocked")
	_ok(not _root.get_app_state().actions.claim_daily_all_tasks()["ok"] and e.boosters.charges("random") == r0 + 1, "second open refused")
	_complete("t05_scrubbox_all_three_once")

func _t06() -> void:
	print("[t06 DAILY destination: consecutive count, D1..D5 states and canonical rewards]")
	await _boot("t06")
	var d = _eco().daily
	(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
	await _frames(2)
	var p = _top()
	_ok(_top_id() == "daily_login" and _root.get_home().get_popup("daily") == null, "DAILY -> app-level Daily")
	var rewards_ok := true
	for day in range(1, 6):
		rewards_ok = rewards_ok and _txt_in(p, "Day_%d" % day, "RewardText") == UiText.reward_text(d.login_reward_for(day))
	_ok(rewards_ok and JSON.stringify(d.login_reward_for(5)) == JSON.stringify(_eco().config.daily_config()["login_rewards"]["5"]), "D1..D5 rewards from config")
	_ok(_states(p) == ["today", "upcoming", "upcoming", "upcoming", "upcoming"] and _txt_in(p, "StreakRow", "Streak") == UiText.t("DAILY_CONSECUTIVE", ["0"]), "fresh: D1 today, count 0")
	_tap("claim")
	await _frames(1)
	_ok(_states(p) == ["claimed_today", "upcoming", "upcoming", "upcoming", "upcoming"] and d.streak() == 1 and bool(p.get_action_button("claim").disabled), "claimed today, count 1, claim blocked")
	for _i in range(5):
		_day[0] += 1
		_now[0] += 86400
		_root.get_app_state().actions.claim_daily_login()
	DailyScreens.refresh_daily(p, _root.get_app_state())
	_ok(d.streak() == 6 and _states(p)[0] == "claimed_today" and _txt_in(p, "StreakRow", "Streak") == UiText.t("DAILY_CONSECUTIVE", ["6"]), "day 6 repeats the cycle at D1, count keeps 6")
	_complete("t06_daily_destination_states")

func _t07() -> void:
	print("[t07 local-day rollover, missed-day reset, clock rollback, tasks reset]")
	await _boot("t07")
	var a = _root.get_app_state()
	var d = a.economy.daily
	a.actions.claim_daily_login()
	_complete_orders([0, 1, 2])
	_day[0] += 1
	_now[0] += 86400
	_ok(d.tasks_done_count() == 0 and _progress() == [0, 0, 0], "rollover: yesterday's orders do not leak")
	a.actions.claim_daily_login()
	_ok(d.streak() == 2, "next day: streak 2")
	_day[0] += 3
	_now[0] += 86400 * 3
	_ok(d.next_claim_cycle_day() == 1, "missed days: back to D1")
	a.actions.claim_daily_login()
	_ok(d.streak() == 1, "streak reset to 1")
	_day[0] -= 2
	_now[0] -= 86400 * 2
	var sb: int = a.economy.wallet.scrub_bucks()
	_ok(not a.actions.claim_daily_login()["ok"] and a.economy.wallet.scrub_bucks() == sb, "clock rollback: no duplicate login claim")
	_ok(not a.actions.claim_daily_task(0)["ok"], "clock rollback: no task claim")
	_complete("t07_daily_rollover_missed_rollback")

func _t08() -> void:
	print("[t08 Gift Bar: claim + history, never feeds the Gift Meter, never re-grants]")
	await _boot("t08")
	var e = _eco()
	e.gift.add_streak_sb("t08:a", 260)   # crosses 10 / 50 / 250
	(_root.get_home().get_region("GiftMeterButton") as Button).pressed.emit()
	await _frames(2)
	var p = _top()
	_ok(_top_id() == "gift_bar", "Gift Bar destination")
	_ok(_claimable_rows(p) == 3, "three queued milestones claimable")
	var prog0: int = e.gift.cycle_progress()
	var total0: int = e.gift.total_progress()
	var sb0: int = e.wallet.scrub_bucks()
	var occ: String = e.gift.claimable()[2]["id"]
	_tap("gift:" + occ)
	await _frames(1)
	_ok(e.wallet.scrub_bucks() == sb0 + 100 and e.gift.cycle_progress() == prog0 and e.gift.total_progress() == total0, "claim granted 250-milestone SB; Gift Meter unchanged (non-recursive)")
	_ok(_claimable_rows(p) == 2 and _history_rows(p) == 1 and bool(p.get_action_button("gift:" + occ).disabled), "claimed moves to history, blocked")
	_ok(not _root.get_app_state().actions.claim_gift(occ)["ok"] and e.wallet.scrub_bucks() == sb0 + 100, "re-claim refused")
	e.gift.add_streak_sb("t08:b", 800)   # rollover into cycle 1
	DailyScreens.refresh_gift_bar(p, _root.get_app_state())
	_ok(e.gift.cycles_completed() == 1 and _claimable_rows(p) == 6 and _history_rows(p) == 1, "Gift rollover queues the next cycle's milestones; history kept")
	_complete("t08_gift_bar_claim_history_non_recursive")

func _t09() -> void:
	print("[t09 eligibility: frontier / class lookahead / available content]")
	await _boot("t09")
	var o = _eco().orders
	var med: Dictionary = o.archetype("win_medium_plus_1")
	var cf: Callable = func(n): return ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"][(n - 1) % 10]
	_ok(o.eligible(med, {"frontier": 1, "playable_ahead": 9, "class_for": cf}), "MEDIUM at level 3 within 3 of frontier 1: eligible")
	_ok(o.eligible(med, {"frontier": 6, "playable_ahead": 9, "class_for": cf}), "frontier 6: 6..8 includes MEDIUM 8")
	_ok(o.eligible(med, {"frontier": 4, "playable_ahead": 9, "class_for": cf}), "frontier 4: 4..6 includes HARD 5 (MEDIUM or harder)")
	_ok(o.eligible(med, {"frontier": 9, "playable_ahead": 9, "class_for": cf}), "frontier 9: VERY_HARD 10 counts")
	_ok(not o.eligible(med, {"frontier": 11, "playable_ahead": 2, "class_for": cf}), "frontier 11..12 only (EASY, EASY): excluded")
	_ok(not o.eligible(med, {"frontier": 6, "playable_ahead": 2, "class_for": cf}), "only levels 6..7 playable: excluded")
	_ok(not o.eligible(o.archetype("win_3"), {"playable_ahead": 2}) and o.eligible(o.archetype("win_2"), {"playable_ahead": 2}), "win 3 needs 3 playable levels")
	_ok(o.generate(_day[0], {"playable_ahead": 0}) == ["", "", ""], "no playable content: no order offered (honest)")
	o.import_snapshot({"version": 1, "day": _day[0], "ids": ["", "", ""], "progress": [0, 0, 0]})
	var p = await _open_tasks()
	_ok(_txt_in(p, "Task_0", "Text") == UiText.t("TASK_NONE") and bool(p.get_action_button("task:0").disabled), "unavailable order shown honestly, not claimable")
	var c: Dictionary = _ctx()
	_ok(int(c["frontier"]) == 1 and int(c["playable_ahead"]) >= 3, "live context from progression + catalog %s" % str(c))
	_complete("t09_eligibility_frontier_content")

func _t10() -> void:
	print("[t10 strict daily_orders import; malformed pool fails closed]")
	await _boot("t10")
	var e = _eco()
	var good: Dictionary = e.snapshot()
	var bad := [
		{"version": 2, "day": 1, "ids": ["", "", ""], "progress": [0, 0, 0]},
		{"version": 1, "day": 1.5, "ids": ["", "", ""], "progress": [0, 0, 0]},
		{"version": 1, "day": 1, "ids": ["", ""], "progress": [0, 0, 0]},
		{"version": 1, "day": 1, "ids": ["nope", "", ""], "progress": [0, 0, 0]},
		{"version": 1, "day": 1, "ids": ["win_1", "", ""], "progress": [2, 0, 0]},
		{"version": 1, "day": 1, "ids": ["win_1", "", ""], "progress": [-1, 0, 0]},
		"x",
	]
	var rejected := 0
	for b in bad:
		var s: Dictionary = good.duplicate(true)
		s["daily_orders"] = b
		if not e.import_snapshot(s):
			rejected += 1
	_ok(rejected == bad.size() and e.snapshot() == good, "%d/%d malformed sections rejected, state untouched" % [rejected, bad.size()])
	var legacy: Dictionary = good.duplicate(true)
	legacy.erase("daily_orders")
	_ok(e.import_snapshot(legacy) and e.orders.snapshot()["day"] == -1, "absent section (legacy save) -> fresh, generated on demand")
	var tmp := "user://m43c009_badpool.json"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string('{"schema":"scrubbots.daily_scrub_orders.v1","version":1,"archetypes":[{"id":"a","tier":"easy","metric":"levels_won","target":0}]}')
	f.close()
	_ok(not DailyOrders.load_pool(tmp)["ok"] and DailyOrders.load_pool()["ok"], "target 0 rejects the file; shipped pool valid")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	_complete("t10_strict_import_and_pool")

func _t11() -> void:
	print("[t11 ScrubBox never sold; surprise slot absent; tasks need no spend/ads]")
	var src := FileAccess.get_file_as_string("res://scripts/ui/daily/daily_screens.gd") + FileAccess.get_file_as_string("res://scripts/economy/daily_orders.gd")
	var code := _code_only(src)
	_ok(not code.contains("debit(") and not code.contains("ShopHandoff") and not code.contains("rewarded") and not code.contains("price"), "no spend / ad / price path in Tasks or ScrubBox")
	var shop := FileAccess.get_file_as_string("res://scripts/ui/shop/shop_screen.gd").to_lower()
	_ok(not shop.contains("scrubbox"), "ScrubBox not in the Shop")
	var pool: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DailyOrders.PATH))
	var metrics: Array = pool["archetypes"].map(func(a): return a["metric"])
	var keys_ok: bool = pool["archetypes"].all(func(a): return a.keys().all(func(k): return k in ["id", "tier", "metric", "target", "min_class", "within_levels"]))
	_ok(metrics.all(func(m): return DailyOrders.METRICS.has(m)) and keys_ok and not JSON.stringify(pool).to_lower().contains("surprise"), "ordinary-play metrics only; no reward field / surprise slot in the pool")
	var maxw := 0
	for a in pool["archetypes"]:
		if String(a["metric"]).begins_with("levels_won"):
			maxw = maxi(maxw, int(a["target"]))
	_ok(maxw <= 3, "bounded grind: at most 3 wins for any order")
	_complete("t11_no_paid_path_surprise_disabled")

func _t12() -> void:
	print("[t12 duplicate taps never double-grant]")
	await _boot("t12")
	var e = _eco()
	var p = await _open_tasks()
	_complete_orders([0, 1, 2])
	DailyScreens.refresh_tasks(p, _root.get_app_state())
	var sb0: int = e.wallet.scrub_bucks()
	for _i in range(5):
		p._on_action("task:1")
	await create_timer(0.5).timeout
	for _i in range(5):
		p._on_action("task:1")
	_ok(e.wallet.scrub_bucks() == sb0 + 100, "5+5 taps on task 2: +100 once")
	var r0: int = e.boosters.charges("random")
	for _i in range(4):
		p._on_action("scrubbox")
	await _frames(2)
	_ok(e.boosters.charges("random") == r0 + 1, "4 taps on OPEN: one charge")
	_complete("t12_duplicate_taps")

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String, size := Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43master_c009_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _play(level: int) -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	if nav.current() != NavigationController.Route.HOME:
		nav.go(NavigationController.Route.HOME)
		await _frames(2)
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(6)
	_root.get_gameplay_host().get_runtime().set_process(false)

func _ctx() -> Dictionary:
	return _root.get_app_state().orders_context()

func _force_orders(ids: Array) -> void:
	_eco().orders.import_snapshot({"version": 1, "day": _day[0], "ids": ids, "progress": [0, 0, 0]})

func _complete_orders(idx: Array) -> void:
	for i in idx:
		_eco().daily.mark_task_done(i)

func _ids() -> Array:
	return _eco().orders.orders().map(func(o): return o["id"])

func _ids_of(app) -> Array:
	return app.economy.orders.orders().map(func(o): return o["id"])

func _progress() -> Array:
	return _eco().orders.orders().map(func(o): return o["progress"])

func _progress_of(app) -> Array:
	return app.economy.orders.orders().map(func(o): return o["progress"])

func _open_tasks():
	var p = DailyScreens.open_tasks(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	return p

func _states(p) -> Array:
	var out: Array = []
	for day in range(1, 6):
		out.append(String(p.find_child("Day_%d" % day, true, false).get_meta("state")))
	return out

func _claimable_rows(p) -> int:
	return p.find_child("Gifts", true, false).get_children().filter(func(c): return c.has_meta("claimed") and not c.get_meta("claimed")).size()

func _history_rows(p) -> int:
	return p.find_child("Gifts", true, false).get_children().filter(func(c): return c.has_meta("claimed") and c.get_meta("claimed")).size()

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
	print("M43 master C009 Tasks / Daily / Gift evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
