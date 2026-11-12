extends SceneTree
## SB-M43-131/132 — RANKS two tables (owner 2026-10-22): ALL-TIME = highest campaign level
## reached, WEEKLY = levels completed this week, the week resets Monday 00:00 UTC; nothing
## bought with money or boosters counts. WeeklyRanks boundaries / rollback / strict import,
## real committed wins on the app root (losses, purchases and boosters add nothing, the count
## survives a reboot), the two tabs in English and Turkish, ranks_view table weekly.
##
## Run: godot --headless --path . -s res://tests/m43_ranks_weekly.gd

const WeeklyRanks = preload("res://scripts/progression/weekly_ranks.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const AnalyticsService = preload("res://scripts/app/analytics_service.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")

var EXPECTED_CASES := [
	"r01_week_boundaries", "r02_counting_reset", "r03_clock_rollback", "r04_import_strict",
	"r05_real_wins_only", "r06_tabs_en_tr", "r07_screen_after_reset",
]

## 2026-11-09 00:00:00 UTC, a Monday.
var MON := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 11, "day": 9, "hour": 0, "minute": 0, "second": 0}))
const DAY := 86400

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [0]
var _sub: SubViewport
var _root
var _host
var _sink

func _initialize() -> void:
	AppState.test_unlock_all = true
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_r01()
	_r02()
	_r03()
	_r04()
	await _r05()
	await _r06()
	await _r07()
	_shutdown()
	UiText.locale = "en"
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	AppState.test_unlock_all = false
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _r01() -> void:
	print("[r01 week_start = Monday 00:00 UTC at and around the boundary]")
	_ok(Time.get_datetime_dict_from_unix_time(MON)["weekday"] == 1, "fixture 2026-11-09 00:00 UTC is a Monday")
	_ok(WeeklyRanks.week_start(MON) == MON and WeeklyRanks.week_start(MON - 1) == MON - 7 * DAY and WeeklyRanks.week_start(MON + 7 * DAY - 1) == MON and WeeklyRanks.week_start(MON + 7 * DAY) == MON + 7 * DAY,
		"Mon 00:00:00 -> this week; Sun 23:59:59 -> previous week; next Mon 00:00:00 -> next week")
	var good := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 131
	for _i in range(500):
		var ts := rng.randi_range(0, 2_000_000_000)
		var w := WeeklyRanks.week_start(ts)
		var d := Time.get_datetime_dict_from_unix_time(w)
		good = good and w <= ts and ts - w < 7 * DAY and d["weekday"] == 1 and d["hour"] == 0 and d["minute"] == 0 and d["second"] == 0
	_ok(good, "500 random timestamps: start is a Monday 00:00:00 UTC within the last 7 days")
	_complete("r01_week_boundaries")

func _r02() -> void:
	print("[r02 wins count in their week; Monday 00:00 UTC starts again from 0]")
	var t := [MON + 3 * DAY]
	var w := WeeklyRanks.new(func(): return t[0])
	_ok(w.weekly_count() == 0 and w.window() == {"start": MON, "end": MON + 7 * DAY}, "fresh: 0, window Mon 2026-11-09 .. next Mon")
	for _i in range(3):
		w.on_level_won()
	t[0] = MON + 7 * DAY - 1
	w.on_level_won()
	_ok(w.weekly_count() == 4, "3 wins Thursday + 1 Sunday 23:59:59 -> 4")
	t[0] = MON + 7 * DAY
	_ok(w.weekly_count() == 0 and w.window()["start"] == MON + 7 * DAY, "Monday 00:00:00 UTC: 0, new window")
	w.on_level_won()
	_ok(w.weekly_count() == 1 and w.snapshot() == {"version": 1, "week_start": MON + 7 * DAY, "count": 1}, "first win of the new week -> 1")
	t[0] = MON + 30 * DAY
	_ok(w.weekly_count() == 0, "weeks later without a win -> 0")
	_complete("r02_counting_reset")

func _r03() -> void:
	print("[r03 clock rollback: an earlier week is never counted or rewritten]")
	var t := [MON + DAY]
	var w := WeeklyRanks.new(func(): return t[0])
	w.on_level_won()
	w.on_level_won()
	t[0] = MON - 1
	var counted := w.on_level_won()
	_ok(not counted and w.weekly_count() == 0 and w.snapshot()["count"] == 2 and w.snapshot()["week_start"] == MON, "clock to Sunday before: win not counted, shows 0, stored week kept")
	t[0] = MON + 2 * DAY
	_ok(w.weekly_count() == 2, "clock back to this week: 2 again (no double count)")
	t[0] = MON + 3 * DAY - 1
	_ok(w.on_level_won() and w.weekly_count() == 3, "a rollback inside the same week still counts in that week")
	_complete("r03_clock_rollback")

func _r04() -> void:
	print("[r04 strict import: absent = fresh, malformed fails closed, aggregate rolls back]")
	var w := WeeklyRanks.new(func(): return MON + DAY)
	_ok(w.import_snapshot({"version": 1, "week_start": MON, "count": 5}) and w.weekly_count() == 5, "valid snapshot -> 5")
	_ok(w.import_snapshot({"version": 1.0, "week_start": float(MON), "count": 5.0}) and w.weekly_count() == 5, "integral floats (JSON) accepted")
	var bad := [{"version": 2, "week_start": MON, "count": 1}, {"version": 1, "week_start": MON + 3600, "count": 1},
		{"version": 1, "week_start": MON, "count": -1}, {"version": 1, "week_start": MON, "count": 1.5},
		{"version": 1, "week_start": 0, "count": 3}, {"version": 1, "week_start": MON, "count": 0},
		{"version": 1, "week_start": -7 * DAY, "count": 1}, {"version": 1, "week_start": str(MON), "count": 1},
		{"version": 1, "week_start": MON, "count": 1, "bonus": 9}, {"version": 1, "count": 1}, [], "x"]
	_ok(bad.all(func(b): return not w.import_snapshot(b)) and w.weekly_count() == 5, "%d malformed sections refused, state kept" % bad.size())
	_ok(w.import_snapshot(null) and w.snapshot() == {"version": 1, "week_start": 0, "count": 0}, "absent section -> fresh")
	var e := EconomyServices.new("res://data/config/economy_rewards_v1.json", func(): return MON + DAY)
	var s: Dictionary = e.snapshot()
	_ok(s.has("ranks") and s["ranks"] == {"version": 1, "week_start": 0, "count": 0}, "EconomyServices snapshot carries a ranks section")
	s.erase("ranks")
	_ok(e.import_snapshot(s), "old save without ranks imports (fresh)")
	e.ranks.on_level_won()
	var before: Dictionary = e.snapshot()
	var s2: Dictionary = before.duplicate(true)
	s2["ranks"] = {"version": 1, "week_start": MON + 1, "count": 1}
	s2["records"]["boosterless_wins"] = 7
	_ok(not e.import_snapshot(s2) and e.snapshot() == before, "bad ranks section fails the whole economy import, nothing applied")
	e.dispose()
	_complete("r04_import_strict")

func _r05() -> void:
	print("[r05 real app: committed wins count; loss / purchases / boosters add nothing; saved]")
	_now[0] = MON + 2 * DAY
	var path := _tmp_path("r05")
	await _boot(path, 2)
	var r = _eco().ranks
	await _play()
	_eco().wallet.credit("scrub_bucks", 5000)
	_app().actions.buy_heart()
	_ok(_app().actions.buy_booster_charge("tornado").get("ok", false), "Tornado charge bought with Scrub Bucks")
	_ok(r.weekly_count() == 0, "SB credit + Heart + booster purchases -> still 0")
	await _terminal(&"LOST")
	_ok(r.weekly_count() == 0 and _app().progression.current_level() == 2, "LOST -> 0")
	_root.get_modal_stack().clear("t")
	await _settle()
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	await _start(_root.retry_from_results())
	var used: Dictionary = _host.execute_booster("tornado", _host.get_booster_adapter().present_colors()[0])
	_ok(used.get("ok", false) and _host.get_attempt_boosters_used() >= 1, "bought Tornado used in the attempt (%d committed booster actions)" % _host.get_attempt_boosters_used())
	await _terminal(&"WON")
	_ok(r.weekly_count() == 1 and _app().progression.current_level() == 3, "WON with a booster -> exactly 1 (level 2 completed)")
	_root.get_modal_stack().clear("t")
	await _settle()
	await _start(_home_play())   # a win goes Home; Home PLAY starts the next level
	await _terminal(&"WON")
	_ok(r.weekly_count() == 2, "second WON -> 2")
	_root.get_modal_stack().clear("t")
	await _settle()
	await _boot(path, -1)
	_ok(_eco().ranks.weekly_count() == 2 and _app().progression.current_level() == 4, "reboot on the save: weekly 2, frontier 4")
	_complete("r05_real_wins_only")

func _r06() -> void:
	print("[r06 RANKS tabs EN / TR: ALL-TIME default, WEEKLY switch, ranks_view weekly]")
	for lang in ["en", "tr"]:
		UiText.locale = lang
		var p = ProfileScreens.open_ranks(_root.get_modal_stack(), _app())
		await _settle()
		var at: Button = p.find_child("AllTimeTab", true, false)
		var wt: Button = p.find_child("WeeklyTab", true, false)
		var all_t: Control = p.find_child("AllTimeTable", true, false)
		var wk_t: Control = p.find_child("WeeklyTable", true, false)
		_ok(at.text == UiText.t("RANKS_TAB_ALL_TIME") and wt.text == UiText.t("RANKS_TAB_WEEKLY") and at.button_pressed and not wt.button_pressed and all_t.visible and not wk_t.visible,
			"%s: tabs '%s' / '%s', ALL-TIME shown" % [lang, at.text, wt.text])
		_ok(_txt(p, "HighestLevel") == UiText.t("RANKS_HIGHEST", [UiText.num(4)]) and _txt(all_t.find_child("YouRow", true, false), "You") == UiText.t("RANKS_YOU")
			and _txt(all_t.find_child("YouRow", true, false), "Value") == UiText.t("RANKS_YOU_LEVEL", [UiText.num(4)]), "%s: '%s', You row" % [lang, _txt(p, "HighestLevel")])
		wt.button_pressed = true
		await _settle()
		_ok(wk_t.visible and not all_t.visible and not at.button_pressed, "%s: WEEKLY tab -> weekly table only" % lang)
		_ok(_txt(p, "WeekWindow") == UiText.t("RANKS_WEEK_WINDOW", ["2026-11-09", "2026-11-15"]) and _txt(p, "WeeklyCount") == UiText.t("RANKS_WEEK_COUNT", [UiText.num(2)])
			and _txt(wk_t.find_child("YouRow", true, false), "Value") == UiText.tn("RANKS_YOU_WEEKLY", 2, [UiText.num(2)]) and _txt(p, "WeekReset") == UiText.t("RANKS_WEEK_RESET"),
			"%s: '%s' / '%s'" % [lang, _txt(p, "WeekWindow"), _txt(p, "WeeklyCount")])
		_ok(_txt(p, "OnlineSoon") == UiText.t("RANKS_ONLINE_SOON") and p.find_children("*", "Label", true, false).all(func(l): return not String(l.text).contains("%s")),
			"%s: offline note for other players, no unformatted text" % lang)
		_ok(lang == "en" or UiTextTr.TR.has("RANKS_WEEK_WINDOW") and _txt(p, "WeeklyCount").begins_with("Bu hafta"), "%s: Turkish copy shown" % lang)
		at.button_pressed = true
		await _settle()
		_ok(all_t.visible and not wk_t.visible, "%s: back to ALL-TIME" % lang)
		_root.get_modal_stack().clear("t")
		await _settle()
	UiText.locale = "en"
	var views: Array = _sink_events("ranks_view")
	var once := [{"table": "all_time", "band": 1}, {"table": "weekly", "band": 1}, {"table": "all_time", "band": 1}]
	_ok(views == once + once,
		"ranks_view: all_time on open, weekly / all_time on each tab switch (band 1 = Bronze at 3 cleared): %s" % str(views))
	_complete("r06_tabs_en_tr")

func _r07() -> void:
	print("[r07 screen after Monday 00:00 UTC: next week window, 0 levels; all-time unchanged]")
	_now[0] = MON + 7 * DAY
	var p = ProfileScreens.open_ranks(_root.get_modal_stack(), _app())
	await _settle()
	_ok(_txt(p, "WeekWindow") == UiText.t("RANKS_WEEK_WINDOW", ["2026-11-16", "2026-11-22"]) and _txt(p, "WeeklyCount") == UiText.t("RANKS_WEEK_COUNT", ["0"])
		and _txt(p, "HighestLevel") == UiText.t("RANKS_HIGHEST", ["4"]), "'%s' / '%s' / '%s'" % [_txt(p, "WeekWindow"), _txt(p, "WeeklyCount"), _txt(p, "HighestLevel")])
	_root.get_modal_stack().clear("t")
	_complete("r07_screen_after_reset")

# ------------------------------------------------------------------ helpers ----

func _tmp_path(tag: String) -> String:
	var path := "user://m43_ranks_weekly_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

## Real app root on `path`; level > 0 = a fresh frontier save at that level (L1..level-1 cleared).
func _boot(path: String, level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_sink = AnalyticsService.MemorySink.new()
	_app().analytics.sink = _sink
	_app().analytics.set_consent(true)
	if level > 0:
		_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": level, "completed": range(1, level)})
		_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})

func _play() -> void:
	await _start(_root.play_current_frontier().get("ok", false))

## A level just started (`ok`): bind its host, pause the runtime, dispatch one Scrubbot.
func _start(ok: bool) -> void:
	_ok(ok, "level %d started" % _app().progression.current_level())
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			break

func _terminal(status: StringName) -> void:
	_host.get_completion().terminal_reached.emit(status, {})
	await _settle()

func _sink_events(name: String) -> Array:
	_app().analytics.flush()
	return _sink.events.filter(func(e): return e["event"] == name).map(func(e): return e["params"])

func _app():
	return _root.get_app_state()

func _eco():
	return _app().economy

func _txt(n, child: String) -> String:
	var l = n.find_child(child, true, false) if n != null else null
	return l.text if l is Label else ""

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		var an: String = p.get_basename() + "_analytics.json"
		if FileAccess.file_exists(an):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(an))

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
	print("M43 ranks weekly evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)

## SB-PHONE-2026-11-12-B: a win goes Home (the WON primary), then Home PLAY starts the next level.
func _home_play() -> bool:
	_root.get_results_screen().get_primary_button().pressed.emit()
	return _root.play_current_frontier().get("ok", false)
