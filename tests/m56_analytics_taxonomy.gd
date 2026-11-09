extends SceneTree
## SB-M56-001..023 — analytics taxonomy V1 evidence. The versioned catalogue
## (data/config/analytics_taxonomy_v1.json) + AnalyticsService (consent gate, schema
## validation, NullSink default / MemorySink here, batching, local retention markers), and
## the real call sites: app root session lifecycle, ProductionGameplayHost level funnel /
## booster use, FailureAssistanceService + AcquisitionFlow Need a Hand / booster acquisition,
## wallet sources / sinks, Hearts gate, packs / Collection / robots, Home navigation, Shop,
## rewarded offers / requests / results (provider double), reminders + permission, deep links,
## and the feature measures (SB-M56-011, 017..022): Next Cleanup / journey on WON Results, pack
## pity, Daily Scrub Orders, Weekly / First-Try, Comeback Catch-Up, Ranks view.
## Real app root (main.tscn) on throw-away save paths only (boot_save_path_override).
##
## Run: godot --headless --path . -s res://tests/m56_analytics_taxonomy.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const AnalyticsService = preload("res://scripts/app/analytics_service.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const NotificationPermission = preload("res://scripts/economy/notification_permission.gd")
const PendingPackQueue = preload("res://scripts/collection/pending_pack_queue.gd")
const ResultsMomentum = preload("res://scripts/progression/results_momentum.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000
const LEVEL := 2

var EXPECTED_CASES := [
	"config_schema", "defaults_null_sink_consent_off", "consent_off_real_paths", "invalid_dropped",
	"batching", "retention_markers", "consent_persist_revoke", "session_events", "level_funnel",
	"pause_restart_and_exit", "assistance", "booster_acquire_rewarded", "booster_use",
	"economy_events", "collection_robot_events", "navigation_events", "ads_store_events",
	"notification_events", "next_cleanup_journey", "collection_pity", "daily_orders", "weekly_first_try",
	"comeback_catchup", "ranks_view", "provider_offline", "no_economy_change", "pii_scan",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _host
var _sink
var _all_events: Array = []
var _cfg: Dictionary = {}
var _real_drops := 0
var _expect_drops := false

func _initialize() -> void:
	AppState.test_unlock_all = true   # boosters are L6+ gated; this suite exercises them on L2
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(AnalyticsService.PATH))
	_config_schema()
	_defaults()
	await _consent_off_real_paths()
	_invalid_dropped()
	_batching()
	_retention_markers()
	_consent_persist_revoke()
	await _session_events()
	await _level_funnel()
	await _pause_restart_and_exit()
	await _assistance()
	await _booster_acquire_rewarded()
	await _booster_use()
	await _economy_events()
	await _collection_robot_events()
	await _navigation_events()
	await _ads_store_events()
	await _notification_events()
	await _feature_events()
	_provider_offline()
	await _no_economy_change()
	_pii_scan()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	AppState.test_unlock_all = false
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _tmp_path(tag: String) -> String:
	var path := "user://m56_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

## Boot the real app root on a fresh save; consent on + MemorySink unless `consent` is false.
func _boot(consent := true, level := LEVEL) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _tmp_path("app")
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_sink = AnalyticsService.MemorySink.new()
	_an().sink = _sink
	if consent:
		_an().set_consent(true)
	_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": level, "completed": range(1, level)})
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})

func _play() -> void:
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _shutdown() -> void:
	if _an() != null:
		_an().flush()
		if not _expect_drops:
			_real_drops += _an().dropped
	_collect()
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _app():
	return _root.get_app_state()

func _an():
	return _root.get_app_state().analytics if _root != null and is_instance_valid(_root) else null

func _eco():
	return _app().economy

func _settle() -> void:
	for _i in range(4):
		await process_frame

## Every event the sink received so far (flushes the queue first).
func _events() -> Array:
	_an().flush()
	return _sink.events

func _named(name: String) -> Array:
	return _events().filter(func(e): return e["event"] == name)

## Keep every emitted event for the suite-wide PII scan.
func _collect() -> void:
	if _sink != null:
		_all_events.append_array(_sink.events)
		_sink = null

func _first_action() -> bool:
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			return true
	return false

func _terminal(status: StringName) -> void:
	_host.get_completion().terminal_reached.emit(status, {})
	await _settle()

func _retry_from_results() -> bool:
	_root.get_modal_stack().clear("t")
	await _settle()
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	var ok: bool = _root.retry_from_results()
	await _settle()
	return ok

func _svc(tag: String, day: Array) -> AnalyticsService:
	var a := AnalyticsService.new(_tmp_path(tag).get_basename() + "_analytics.json", func(): return _now[0], func(): return day[0])
	a.sink = AnalyticsService.MemorySink.new()
	return a

# ================================================================== catalogue ====

func _config_schema() -> void:
	print("[001 versioned privacy-minimized taxonomy]")
	_ok(typeof(_cfg) == TYPE_DICTIONARY and _cfg["schema"] == AnalyticsService.SCHEMA and int(_cfg["version"]) == 1, "schema + version 1")
	var tasks := {}
	var types: Array = _cfg["privacy"]["param_types"]
	var forbidden: Array = _cfg["privacy"]["forbidden_param_names"]
	var bad: Array = []
	for ev in _cfg["events"]:
		var d: Dictionary = _cfg["events"][ev]
		tasks[d["task"]] = true
		for k in d["params"]:
			var p: Dictionary = d["params"][k]
			if not types.has(p["type"]) or forbidden.has(k):
				bad.append("%s.%s" % [ev, k])
			if p["type"] in ["enum", "enum_list"] and not p.has("values") and not _cfg["enums"].has(p.get("enum", "")):
				bad.append("%s.%s enum" % [ev, k])
			if p.has("fallback") and not (p["values"] if p.has("values") else _cfg["enums"][p["enum"]]).has(p["fallback"]):
				bad.append("%s.%s fallback" % [ev, k])
	_ok(bad.is_empty(), "every param is int/bool/enum/enum_list, no forbidden (PII) name, enums + fallbacks resolve: %s" % str(bad))
	var want: Array = ["SB-M56-002", "SB-M56-003", "SB-M56-004", "SB-M56-005", "SB-M56-006", "SB-M56-007", "SB-M56-008", "SB-M56-009", "SB-M56-010", "SB-M56-011", "SB-M56-012",
		"SB-M56-017", "SB-M56-018", "SB-M56-020", "SB-M56-021", "SB-M56-022"]
	_ok(tasks.keys().size() == want.size() and want.all(func(t): return tasks.has(t)), "events cover SB-M56-002..012 + 017..022 (019 extends pack_opened): %s" % str(tasks.keys()))
	_ok(not types.has("string"), "no free-text param type exists")
	var tax_doc := FileAccess.get_file_as_string("res://" + String(_cfg["doc"]))
	var inv_doc := FileAccess.get_file_as_string("res://docs/PRIVACY_DATA_INVENTORY.md")
	var undocumented: Array = (_cfg["events"] as Dictionary).keys().filter(func(ev): return not (tax_doc.contains("`%s`" % ev) and inv_doc.contains("`%s`" % ev)))
	_ok(undocumented.is_empty(), "every event is listed in the taxonomy doc and the privacy inventory: missing %s" % str(undocumented))
	var an := _svc("cfg", [0])
	var bucket_ok := true
	for kind in {"duration_s": "duration", "attempt": "attempt", "count": "count", "progress_pct": "progress"}:
		var labels: Array = (_cfg["buckets"][kind] as Array).map(func(e): return e[1])
		bucket_ok = bucket_ok and labels == _cfg["enums"][{"duration_s": "duration", "attempt": "attempt", "count": "count", "progress_pct": "progress"}[kind]]
	bucket_ok = bucket_ok and (_cfg["buckets"]["amount"] as Array).map(func(e): return e[1]) == _cfg["enums"]["amount"]
	_ok(bucket_ok and an.bucket("amount", 10) == "1_10" and an.bucket("amount", 500) == "101_500" and an.bucket("amount", 5001) == "gt_5000"
		and an.bucket("duration_s", 29) == "lt_30s" and an.bucket("duration_s", 30) == "30s_2m" and an.bucket("duration_s", 99999) == "gt_60m"
		and an.bucket("attempt", 1) == "1" and an.bucket("attempt", 5) == "4_5" and an.bucket("progress_pct", 100) == "90_100", "coarse buckets match their enums")
	_complete("config_schema")

func _defaults() -> void:
	print("[default: NullSink, consent OFF]")
	var app := AppState.new(_tmp_path("def"), func(): return _now[0])
	_ok(app.analytics.sink is AnalyticsService.NullSink and not app.analytics.has_consent() and app.analytics.config_ok, "shipping graph: NullSink + consent off + catalogue loaded")
	_ok(not app.analytics.track("session_start", {"trigger": "cold_start"}) and app.analytics.queued() == 0, "consent off: track refused, nothing queued")
	app.economy.dispose()
	_complete("defaults_null_sink_consent_off")

func _consent_off_real_paths() -> void:
	print("[consent OFF: real paths emit nothing]")
	await _boot(false)
	await _play()
	_first_action()
	await _terminal(&"LOST")
	await _retry_from_results()
	_root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var state_file: String = MainScript.boot_save_path_override.get_basename() + "_analytics.json"
	_ok(_events().is_empty() and _an().queued() == 0 and _an().dropped == 0, "launch / first action / LOST / retry / background / foreground: 0 events")
	_ok(not FileAccess.file_exists(state_file), "no local analytics state written without consent")
	_complete("consent_off_real_paths")

func _invalid_dropped() -> void:
	print("[invalid events dropped, never crash]")
	var an := _svc("inv", [0])
	an.set_consent(true)
	var cases := [
		["no_such_event", {}],
		["session_start", {}],
		["session_start", {"trigger": "cold_start", "email": "a@b.c"}],
		["session_start", {"trigger": "free text"}],
		["level_first_action", {"level": "2", "attempt": "1", "elapsed": "lt_30s"}],
		["level_first_action", {"level": 0, "attempt": "1", "elapsed": "lt_30s"}],
		["level_first_action", {"level": 2, "attempt": 1, "elapsed": "lt_30s"}],
		["assist_shown", {"level": 2, "boosters": ["random", "fifth_booster"]}],
		["assist_shown", {"level": 2, "boosters": "random"}],
		["booster_acquire", {"booster": "random", "path": "sb", "source": "need_a_hand", "ok": 1}],
	]
	for c in cases:
		an.track(c[0], c[1])
	_ok(an.dropped == cases.size() and an.queued() == 0, "%d malformed events dropped, none queued" % cases.size())
	_ok(an.track("assist_fail_closed", {"level": 2, "reason": "some_new_reason"}) and an.queued() == 1, "enum with fallback: unknown value kept as fallback")
	an.flush()
	_ok(an.sink.events[0]["params"]["reason"] == "other" and an.sink.events[0]["v"] == 1, "fallback 'other', event carries taxonomy version")
	var broken := AnalyticsService.new(_tmp_path("brk").get_basename() + "_analytics.json", func(): return 0, func(): return 0, "res://no/such/taxonomy.json")
	broken.set_consent(true)
	_ok(not broken.config_ok and not broken.track("session_start", {"trigger": "cold_start"}), "missing catalogue: fail closed (everything dropped)")
	_complete("invalid_dropped")

func _batching() -> void:
	print("[batched hand-over]")
	var an := _svc("bat", [0])
	an.set_consent(true)
	for i in range(25):
		an.track("retention_day", {"day": "d1"})
	_ok(an.sink.events.size() == 20 and an.queued() == 5, "batch_size 20: one batch handed over, 5 queued")
	an.flush()
	_ok(an.sink.events.size() == 25 and an.queued() == 0, "flush hands over the rest")
	_complete("batching")

func _retention_markers() -> void:
	print("[004 local D1/D7 markers]")
	var day := [100]
	var an := _svc("ret", day)
	an.set_consent(true)
	var marks := func(): return an.sink.events.filter(func(e): return e["event"] == "retention_day").map(func(e): return e["params"]["day"])
	for d in [100, 101, 101, 102, 103, 107, 107, 114, 130, 131]:
		day[0] = d
		an.start_session("foreground")
		an.end_session("background")
	_ok(marks.call() == ["d1", "d3", "d7", "d14", "d30"], "first consented day 100 -> exactly d1/d3/d7/d14/d30 once each: %s" % str(marks.call()))
	_complete("retention_markers")

func _consent_persist_revoke() -> void:
	print("[consent persists locally; revoke clears]")
	var path: String = _tmp_path("per").get_basename() + "_analytics.json"
	var a := AnalyticsService.new(path, func(): return 0, func(): return 5)
	a.set_consent(true)
	a.start_session("cold_start")
	var b := AnalyticsService.new(path, func(): return 0, func(): return 6)
	b.sink = AnalyticsService.MemorySink.new()
	b.start_session("cold_start")
	b.flush()
	_ok(b.has_consent() and b.sink.events.map(func(e): return e["event"]) == ["session_start", "retention_day"], "relaunch keeps consent + first day (d1 on day 6)")
	b.track("session_start", {"trigger": "foreground"})
	b.set_consent(false)
	var c := AnalyticsService.new(path, func(): return 0, func(): return 7)
	_ok(not b.has_consent() and b.queued() == 0 and not c.has_consent(), "revoke: queue dropped, OFF after relaunch")
	_tmp.append(path)
	_complete("consent_persist_revoke")

# ================================================================== real paths ====

func _session_events() -> void:
	print("[002 session start / end]")
	await _boot()
	_now[0] += 45
	_root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_now[0] += 400
	_root._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var s: Array = _events().filter(func(e): return e["event"].begins_with("session_"))
	var got: Array = s.map(func(e): return [e["event"], e["params"]["trigger"], e["params"].get("duration", "")])
	_ok(got == [["session_end", "background", "30s_2m"], ["session_start", "foreground", ""], ["session_end", "close", "5m_15m"]],
		"cold session (opened at boot) ends once on background, one foreground start, close ends it: %s" % str(got))
	_complete("session_events")

func _level_funnel() -> void:
	print("[003/004 level funnel]")
	await _boot()
	await _play()
	var st: Array = _named("level_start")
	var meta: Dictionary = _app().progression.describe(LEVEL)
	_ok(st.size() == 1 and st[0]["params"] == {"level": LEVEL, "progression": true, "entry": "launch", "attempt": "1",
		"difficulty": meta["class"], "cadence_slot": meta["slot"], "difficulty_model": _app().progression.model_version()}, "launch -> level_start %s" % str(st))
	_now[0] += 10
	_ok(_first_action() and _first_action(), "two real activations")
	var fa: Array = _named("level_first_action")
	_ok(fa.size() == 1 and fa[0]["params"] == {"level": LEVEL, "attempt": "1", "elapsed": "lt_30s"}, "exactly one level_first_action")
	_now[0] += 200
	await _terminal(&"LOST")
	var end: Array = _named("level_end")
	_ok(end.size() == 1 and end[0]["params"]["outcome"] == "lost" and end[0]["params"]["first_attempt"] and end[0]["params"]["attempt"] == "1"
		and end[0]["params"]["duration"] == "2m_5m" and end[0]["params"]["progress"] == "0_25" and end[0]["params"]["boosters_used"] == "0"
		and not end[0]["params"]["assisted"], "LOST -> level_end lost, attempt 1, duration / progress buckets: %s" % str(end))
	_now[0] += 20
	_ok(await _retry_from_results(), "Retry from Results")
	st = _named("level_start")
	_ok(st.size() == 2 and st[1]["params"]["entry"] == "retry_results" and st[1]["params"]["attempt"] == "2" and st[1]["params"]["retry_latency"] == "lt_30s",
		"retry -> level_start retry_results, attempt 2, retry latency bucket: %s" % str(st))
	_first_action()
	await _terminal(&"WON")
	end = _named("level_end")
	_ok(end.size() == 2 and end[1]["params"]["outcome"] == "won" and end[1]["params"]["attempt"] == "2" and not end[1]["params"]["first_attempt"]
		and end[1]["params"]["progression"], "WON -> level_end won, attempts-to-clear 2, not first-attempt: %s" % str(end))
	_root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var se: Array = _named("session_end")
	_ok(se.size() == 1 and se[0]["params"]["after_level"] == "won", "session_end records the last level outcome (abandonment after level)")
	_complete("level_funnel")

func _pause_restart_and_exit() -> void:
	print("[003 pause restart / exit to Home / back exit]")
	await _boot()
	await _play()
	_first_action()
	_ok(_host.retry(), "Pause Restart (RetryCoordinator)")
	await _settle()
	var ev: Array = _events().filter(func(e): return e["event"] in ["level_start", "level_end"]).map(func(e): return [e["event"], e["params"].get("entry", e["params"].get("outcome"))])
	_ok(ev == [["level_start", "launch"], ["level_end", "restart"], ["level_start", "retry_pause"]], "restart ends the attempt then starts a new one: %s" % str(ev))
	_first_action()
	_ok(_host.exit_to_home()["ok"], "Pause Home")
	var end: Array = _named("level_end")
	_ok(end.size() == 2 and end[1]["params"]["outcome"] == "exit", "exit_to_home -> level_end exit")
	_ok(not _host.exit_to_home()["ok"] and _named("level_end").size() == 2, "second exit: no duplicate event")
	await _boot()
	await _play()
	_ok(_root.handle_back() == "home", "Back before the first action -> Home")
	end = _named("level_end")
	_ok(end.size() == 1 and end[0]["params"]["outcome"] == "exit", "pre-action back exit -> level_end exit")
	_complete("pause_restart_and_exit")

func _assistance() -> void:
	print("[005 Need a Hand shown / acquired / dismissed / later clear]")
	await _boot()
	await _play()
	_eco().wallet.credit("scrub_bucks", 5000)
	for i in range(3):
		if i > 0:
			await _retry_from_results()
		await _terminal(&"LOST")
	var nah = _root.get_acquisition().find_open("need_a_hand")
	var shown: Array = _named("assist_shown")
	_ok(nah != null and shown.size() == 1 and shown[0]["params"] == {"level": LEVEL, "boosters": nah.context["boosters"]}, "assist_shown with the two recommended booster ids: %s" % str(shown))
	var id: String = nah.context["boosters"][0]
	nah.get_action_button("buy:" + id).pressed.emit()
	await _settle()
	var acq: Array = _named("booster_acquire")
	_ok(acq.size() == 1 and acq[0]["params"] == {"booster": id, "path": "sb", "source": "need_a_hand", "ok": true}, "BUY -> booster_acquire sb / need_a_hand")
	nah.get_close_button().pressed.emit()
	await _settle()
	var dis: Array = _named("assist_dismissed")
	_ok(dis.size() == 1 and dis[0]["params"] == {"level": LEVEL, "acquired": true}, "close after buying -> assist_dismissed acquired")
	await _retry_from_results()
	await _terminal(&"WON")
	var end: Array = _named("level_end")
	_ok(end.back()["params"]["outcome"] == "won" and end.back()["params"]["assisted"] and end.back()["params"]["attempt"] == "4_5", "later clear outcome: WON with assisted = true, attempt 4 (bucket 4_5)")
	# A second offer closed without acquiring = declined.
	await _boot()
	await _play()
	for i in range(3):
		if i > 0:
			await _retry_from_results()
		await _terminal(&"LOST")
	nah = _root.get_acquisition().find_open("need_a_hand")
	_ok(nah != null and _root.handle_back() == "close_modal", "Back closes Need a Hand")
	dis = _named("assist_dismissed")
	_ok(dis.size() == 1 and dis[0]["params"]["acquired"] == false and _named("booster_acquire").is_empty(), "declined -> assist_dismissed acquired false")
	var fc := AppState.new(_tmp_path("fc"), func(): return _now[0])
	fc.analytics.sink = AnalyticsService.MemorySink.new()
	fc.analytics.set_consent(true)
	fc.assist.note_fail_closed(3, "insufficient_meaningful")
	fc.analytics.flush()
	_ok(fc.analytics.sink.events.map(func(e): return [e["event"], e["params"]]) == [["assist_fail_closed", {"level": 3, "reason": "insufficient_meaningful"}]], "fail-closed offer -> assist_fail_closed")
	fc.economy.dispose()
	_complete("assistance")

func _booster_acquire_rewarded() -> void:
	print("[006 rewarded acquisition path]")
	await _boot()
	var prov := ProviderDouble.new()
	_eco().rewarded.set_provider(prov)
	await _play()
	for i in range(3):
		if i > 0:
			await _retry_from_results()
		await _terminal(&"LOST")
	var nah = _root.get_acquisition().find_open("need_a_hand")
	var id: String = nah.context["boosters"][1]
	nah.get_action_button("watch:" + id).pressed.emit()
	prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	nah.get_action_button("watch:" + nah.context["boosters"][0]).pressed.emit()
	prov.deliver_last({"outcome": "cancelled"})
	await _settle()
	var acq: Array = _named("booster_acquire").map(func(e): return e["params"])
	_ok(acq == [{"booster": id, "path": "rewarded", "source": "need_a_hand", "ok": true},
		{"booster": nah.context["boosters"][0], "path": "rewarded", "source": "need_a_hand", "ok": false}], "verified ad -> ok; cancelled -> not ok: %s" % str(acq))
	_complete("booster_acquire_rewarded")

func _booster_use() -> void:
	print("[006 booster use: success / fail-closed reason / level context]")
	await _boot()
	await _play()
	_eco().boosters.add_charges("plus_one_slot", 1)
	_eco().boosters.add_charges("tornado", 1)
	var r1: Dictionary = _host.execute_booster("plus_one_slot")
	var r2: Dictionary = _host.execute_booster("tornado", 9999)
	var color = _host.get_booster_adapter().present_colors()[0]
	var r3: Dictionary = _host.execute_booster("tornado", color)
	var use: Array = _named("booster_use").map(func(e): return e["params"])
	var diff: String = _app().progression.class_for(LEVEL)
	_ok(r1["ok"] and not r2["ok"] and r3["ok"] and use.size() == 3, "three activations through the facade -> three booster_use")
	_ok(use[0] == {"booster": "plus_one_slot", "ok": true, "reason": "ok", "level": LEVEL, "attempt": "1", "difficulty": diff}, "+1 Slot success: %s" % str(use[0]))
	_ok(use[1] == {"booster": "tornado", "ok": false, "reason": "color_not_present", "level": LEVEL, "attempt": "1", "difficulty": diff}, "fail-closed reason, no paid_with: %s" % str(use[1]))
	_ok(use[2]["ok"] and use[2]["paid_with"] == "charge", "Tornado with a charge -> paid_with charge")
	_first_action()
	await _terminal(&"LOST")
	var n: int = _host.get_attempt_boosters_used()
	_ok(n >= 1 and _named("level_end")[0]["params"]["boosters_used"] == _an().bucket("count", n), "level_end boosters_used = the host's committed attempt booster count (%d)" % n)
	_complete("booster_use")

func _no_economy_change() -> void:
	print("[analytics never changes economy / progression]")
	var runs: Array = []
	for consent in [false, true]:
		await _boot(consent)
		_seed_packs()
		await _play()
		_first_action()
		await _terminal(&"LOST")
		await _retry_from_results()
		_first_action()
		await _terminal(&"WON")
		# SB-M56-014: every M56-007..012 call site runs the same way with consent OFF and ON.
		await _go_home()
		await _tour_spend()
		await _tour_collection()
		await _tour_navigation()
		await _tour_ads()
		await _tour_notifications()
		await _tour_features()   # SB-M56-011, 017..022
		var eco: Dictionary = _eco().snapshot()
		eco.erase("packs")   # the card-pack RNG state is seeded per fresh profile, not by play
		runs.append([eco, _app().progression.snapshot()])
	_ok(runs[0] == runs[1], "same play + spends / pack / Collection / robots / navigation / ads / reminders / feature measures with consent OFF vs ON: identical economy + progression snapshots (differing: %s)" % str((runs[0][0] as Dictionary).keys().filter(func(k): return runs[0][0][k] != runs[1][0][k])))
	var before: Array = [_eco().snapshot(), _app().progression.snapshot()]
	_expect_drops = true   # the 50 bogus level_end calls below are dropped on purpose
	for i in range(50):
		_an().track("booster_acquire", {"booster": "random", "path": "rewarded", "source": "need_a_hand", "ok": true})
		_an().track("level_end", {"bogus": true})
		_an().start_session("foreground")
		_an().end_session("background")
	_an().set_consent(false)
	_ok([_eco().snapshot(), _app().progression.snapshot()] == before, "200 analytics calls + revoke: economy / progression untouched")
	_complete("no_economy_change")

func _pii_scan() -> void:
	print("[PII scan of every emitted event]")
	_collect()
	var forbidden: Array = _cfg["privacy"]["forbidden_param_names"]
	var bad: Array = []
	var names := {}
	for e in _all_events:
		names[e["event"]] = true
		var spec: Dictionary = _cfg["events"][e["event"]]["params"]
		for k in e["params"]:
			var v = e["params"][k]
			if forbidden.has(k) or not spec.has(k) or not (v is int or v is bool or v is String or v is Array):
				bad.append([e["event"], k])
	_ok(bad.is_empty(), "%d events, only declared int/bool/enum params: %s" % [_all_events.size(), str(bad)])
	_ok(_real_drops == 0, "no real call site ever produced an invalid (dropped) event: %d" % _real_drops)
	var missing: Array = (_cfg["events"] as Dictionary).keys().filter(func(n): return not names.has(n) and n != "retention_day" and n != "assist_fail_closed")
	_ok(missing.is_empty(), "every real-path event was emitted at least once: missing %s" % str(missing))
	_complete("pii_scan")

# ============================================================ SB-M56-007..012 ====

func _go_home() -> void:
	_root.get_modal_stack().clear("t")
	_root.get_navigation().go(R.HOME, {"via": "results"})
	await _settle()

func _seed_packs() -> void:
	_eco().packs.import_snapshot({"rng": {"hi": 7, "lo": 11}})

func _press(p, id: String) -> void:
	p.rearm()
	p.get_action_button(id).pressed.emit()

func _params(name: String) -> Array:
	return _named(name).map(func(e): return e["params"])

## 007: SB spends through the app facade + the zero-Heart gate on Home PLAY.
func _tour_spend() -> void:
	_eco().wallet.credit("scrub_bucks", 5000)
	_eco().hearts.import_snapshot({"hearts": 3, "anchor": _now[0]})
	_app().actions.buy_heart()
	_app().actions.refill_hearts()
	_app().actions.buy_current_level_2x(LEVEL + 1)
	_app().actions.buy_booster_charge("tornado")
	_eco().hearts.import_snapshot({"hearts": 0, "anchor": _now[0]})
	_root.play_current_frontier()
	_root.get_modal_stack().clear("t")
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	await _settle()

## 008: one earned standard pack opened (and replayed), every card added (15 sets + Master),
## the next robot unlocked and equipped.
func _tour_collection() -> void:
	_seed_packs()
	_eco().reward.grant("m56:pack", {"standard_card_packs": 1})
	var id := PendingPackQueue.entry_id("m56:pack", "standard", 0)
	_app().open_earned_pack(id)
	_app().open_earned_pack(id)
	for cid in _eco().collection.all_card_ids():
		_eco().collection.add_card(cid)
	_eco().wallet.credit("bot_parts", 250)
	var u: Dictionary = _app().actions.unlock_next_robot()
	_app().actions.equip_robot(String(u.get("robot_id", "")))
	await _settle()
	_root.get_modal_stack().clear("t")

## 009: Home shortcuts / BottomNav / Settings / Help / deep link, and a refused launch.
func _tour_navigation() -> void:
	for id in ["collection", "daily", "shop"]:
		_root._on_home_shortcut(id)
		await _settle()
		_root.get_modal_stack().clear("t")
	_root._on_home_nav("robots")
	await _settle()
	_root.get_modal_stack().clear("t")
	_root.open_settings()
	await _settle()
	_root.get_navigation().close_settings()
	_root.open_help()
	await _settle()
	_root.get_modal_stack().clear("t")
	_root.open_deep_link("tasks")
	await _settle()
	_root.get_modal_stack().clear("t")
	_app().is_blocked = true
	_root.launch_gameplay()
	_app().is_blocked = false

## 010: Life offer -> heart video cancelled (late duplicate ignored); Rewarded Ads slot 1 free
## claim + slot 2 verified video.
func _tour_ads() -> void:
	var prov := ProviderDouble.new()
	_eco().rewarded.set_provider(prov)
	_eco().hearts.import_snapshot({"hearts": 4, "anchor": _now[0]})
	var life = _root.open_life("t")
	_press(life, "watch")
	prov.deliver_last({"outcome": "cancelled"})
	prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_root.get_modal_stack().clear("t")
	var ra = RewardedAdsScreen.open(_root.get_modal_stack(), _app())
	_press(ra, "slot:1")
	_press(ra, "slot:2")
	prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_root.get_modal_stack().clear("t")
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})

## 012: REMINDERS ON -> explainer -> Allow -> OS answer; one category toggled.
func _tour_notifications() -> void:
	var np = _eco().notify_permission
	np.platform = "Android"
	np.granted_fn = func() -> bool: return false
	np.request_fn = func() -> void: pass
	var p = ProfileScreens.open_notifications(_root.get_modal_stack(), _app())
	_press(p, "notify_all")
	await _settle()
	var x = _root.get_modal_stack().top()
	if x != null and x.popup_id == "notification_permission":
		_press(x, "allow")
	await _settle()
	on_request_permissions_result.emit(NotificationPermission.PERMISSION, false)
	_press(p, "notify:daily")
	await _settle()
	_root.get_modal_stack().clear("t")

func _economy_events() -> void:
	print("[007 economy sources / sinks, Hearts gate]")
	await _boot()
	var changes: Array = []
	_eco().wallet.changed.connect(func(r, d, t): changes.append([r, d, t]))
	await _play()
	_first_action()
	await _terminal(&"WON")
	await _go_home()
	await _tour_spend()
	var src: Array = _params("economy_source")
	var snk: Array = _params("economy_sink")
	_ok(changes.size() >= 6 and src.size() + snk.size() == changes.size(), "every wallet change is one economy event (%d changes)" % changes.size())
	_ok(src.any(func(p): return p["source"] == "first_clear") and src.any(func(p): return p["source"] == "other" and p["amount"] == "1001_5000"),
		"WON first clear -> source first_clear; untagged credit 5000 -> other / 1001_5000: %s" % str(src))
	var spent := {}
	for c in changes:
		if c[1] < 0:
			spent[c[2]] = -int(c[1])
	var cfg = _eco().config
	_ok(spent.get("heart_plus_one") == int(cfg.hearts_plus_one_sb()) and spent.get("heart_refill") == int(cfg.hearts_full_refill_sb_per_missing())
		and spent.get("booster_buy") == int(cfg.booster_price("tornado")) and spent.has("speed_level"), "wallet tags carry the exact canonical prices: %s" % str(spent))
	_ok(snk == ["heart_plus_one", "heart_refill", "speed_level", "booster_buy"].map(func(k): return {"currency": "scrub_bucks", "amount": _an().bucket("amount", int(spent[k])), "sink": k}),
		"+1 Heart / refill / current-level 2x / booster charge -> sink + bucketed price: %s" % str(snk))
	_ok(_params("hearts_empty") == [{"at": "home_play"}], "Home PLAY with 0 Hearts -> hearts_empty home_play")
	_complete("economy_events")

func _collection_robot_events() -> void:
	print("[008 pack / Collection / robots]")
	await _boot()
	await _tour_collection()
	var packs: Array = _params("pack_opened")
	var rc: Dictionary = _app().commit_pack("standard", PendingPackQueue.entry_id("m56:pack", "standard", 0))
	var cards: Array = rc["receipt"]["cards"]
	var fresh: int = cards.filter(func(c): return c["is_new"]).size()
	_ok(rc["replay"] and packs.size() >= 1 and packs[0]["kind"] == "standard" and packs[0]["new_cards"] == _an().bucket("count", fresh)
		and packs[0]["duplicates"] == _an().bucket("count", cards.size() - fresh), "committed pack -> pack_opened with receipt counts: %s" % str(packs))
	_ok(_named("pack_opened").size() == packs.size(), "replayed receipt (2x open_earned_pack + commit_pack) sends nothing more")
	var sets: Array = _params("collection_set_complete").map(func(p): return p["set"])
	sets.sort()
	_ok(sets == range(1, 16) and _named("collection_master_complete").size() == 1, "15 sets complete once each + Master once: %s" % str(sets))
	_ok(_params("collection_set_complete").all(func(p): return p["level"] == LEVEL), "019: set completion carries the campaign level (Set-1 completion level)")
	_ok(_params("robot_unlock") == [{"robot": 2}] and _params("robot_equip") == [{"robot": 2}], "next robot (roster #2) unlock + equip")
	_ok(_params("economy_sink").any(func(p): return p["sink"] == "robot_unlock" and p["currency"] == "bot_parts")
		and _params("economy_source").any(func(p): return p["source"] == "collection"), "robot unlock -> bot_parts sink; set rewards -> collection source")
	_complete("collection_robot_events")

func _navigation_events() -> void:
	print("[009 navigation / Shop entry / launch error]")
	await _boot()
	await _tour_navigation()
	var screens: Array = _params("screen_view").map(func(p): return p["screen"])
	_ok(screens == ["collection", "daily", "shop", "robots", "settings", "help", "tasks"], "shortcuts / BottomNav / Settings / Help / deep link: %s" % str(screens))
	_ok(_params("shop_open") == [{"source": "home_shop"}], "Shop shortcut -> shop_open home_shop")
	_ok(_params("deep_link_open") == [{"dest": "tasks"}], "deep link -> deep_link_open tasks")
	_ok(_params("launch_failed") == [{"reason": "APP_BLOCKED"}], "blocked launch -> launch_failed APP_BLOCKED")
	_complete("navigation_events")

func _ads_store_events() -> void:
	print("[010 rewarded offer / request / result (provider double)]")
	await _boot()
	await _tour_ads()
	_ok(_params("ad_offer_shown") == [{"placement": "life", "available": true}], "Life popup -> ad_offer_shown life available")
	_ok(_params("ad_request") == [{"product": "heart", "ok": true, "reason": "ok"}, {"product": "daily_slot", "ok": true, "reason": "ok"}], "heart + daily slot requests: %s" % str(_params("ad_request")))
	_ok(_params("ad_result") == [{"product": "heart", "outcome": "cancelled"}, {"product": "daily_slot", "outcome": "granted"}],
		"cancelled heart (late duplicate ignored) + verified daily slot granted: %s" % str(_params("ad_result")))
	_ok(_params("economy_source").any(func(p): return p["source"] == "rewarded_daily"), "Rewarded Ads daily grants -> source rewarded_daily")
	_eco().rewarded.set_provider(null)
	_eco().hearts.import_snapshot({"hearts": 4, "anchor": _now[0]})
	_root.open_life("t")
	_ok(_params("ad_offer_shown").back() == {"placement": "life", "available": false}, "production provider (no SDK) -> offer shown unavailable")
	_root.get_modal_stack().clear("t")
	_complete("ads_store_events")

func _notification_events() -> void:
	print("[012 reminders / permission explainer / OS result]")
	await _boot()
	await _tour_notifications()
	_ok(_params("notify_toggle") == [{"category": "all", "on": true}, {"category": "daily", "on": _eco().notify.categories["daily"]}], "REMINDERS ON + one category toggle: %s" % str(_params("notify_toggle")))
	_ok(_params("notification_prompt").map(func(p): return p["step"]) == ["explainer_shown", "allowed", "os_denied"], "explainer shown -> Allow -> OS denied: %s" % str(_params("notification_prompt")))
	_complete("notification_events")

# ====================================================== SB-M56-011, 017..022 ====

## A Weekly event (milestones at 1 and 2 counted wins, running now) + a 2-level First-Try.
func _load_events() -> void:
	var path: String = _tmp_path("events").get_basename() + ".json"
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.events.v1", "version": 1, "approved_reward_types": ["scrub_bucks"],
		"weekly_events": [{"id": "wk1", "start_ts": _now[0] - 3600, "unclaimed_on_expiry": "forfeit",
			"milestones": [{"target": 1, "reward": {"scrub_bucks": 20}}, {"target": 2, "reward": {"scrub_bucks": 30}}]}],
		"first_try_cleanup": {"id": "ft1", "levels": 2, "reward": {"scrub_bucks": 40}}}))
	f.close()
	_eco().events.load_config(path)

## Real first action + WON on the current host, then the WON Results route.
func _win_current() -> void:
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_first_action()
	await _terminal(&"WON")
	_root.get_modal_stack().clear("t")
	await _settle()

## 011 + 017..022 on their real paths, from Home at frontier F with Hearts: a 3-day absence
## (return window + Catch-Up), Weekly + First-Try joined, today's orders win_1 / win_2 / win_3
## one win from done, a pity-due pack, WON F -> CLEAN NEXT (+ a stale second tap) -> WON F+1,
## then the order / First-Try / milestone claims and the Ranks screen.
func _tour_features() -> void:
	_load_events()
	_app().actions.join_first_try()
	_eco().orders.import_snapshot({"version": 1, "day": _eco().daily.local_day(), "ids": ["win_1", "win_2", "win_3"], "progress": [0, 1, 1]})
	_eco().returns.import_snapshot({"version": 1, "last": _now[0] - 3 * 86400, "high": _now[0] - 3 * 86400, "window": 0, "window_ts": 0, "summary_shown": 0, "catchup": {}})
	_root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_eco().pack_pity.threshold_override = 1
	_eco().pack_pity.import_snapshot({"version": 1, "count": 1})
	_eco().reward.grant("m56:pity", {"standard_card_packs": 1})
	_app().open_earned_pack(PendingPackQueue.entry_id("m56:pity", "standard", 0))
	_eco().pack_pity.threshold_override = -1
	_root.get_modal_stack().clear("t")
	await _settle()
	_root.play_current_frontier()
	await _settle()
	await _win_current()
	_root.continue_from_results()
	await _settle()
	_root.continue_from_results()
	await _win_current()
	for i in range(3):
		_app().actions.claim_daily_task(i)
	_app().actions.claim_daily_all_tasks()
	_app().actions.claim_first_try()
	_app().actions.claim_event_milestone("wk1", 0)
	ProfileScreens.open_ranks(_root.get_modal_stack(), _app()).find_child("WeeklyTab", true, false).button_pressed = true
	_root.get_modal_stack().clear("t")
	await _settle()

func _feature_events() -> void:
	print("[011 / 017..022 feature measures]")
	await _boot()
	await _tour_features()
	print("[017 Next Cleanup + 018 journey]")
	_ok(_params("journey_progress") == [{"slot": LEVEL, "cycle": 1, "cycle_complete": false, "first_clear": true},
		{"slot": LEVEL + 1, "cycle": 1, "cycle_complete": false, "first_clear": true}], "two WON Results -> journey node (cadence slot, cycle): %s" % str(_params("journey_progress")))
	var shown: Array = _params("next_cleanup_shown")
	_ok(shown.size() == 2 and shown.all(func(p): return p["available"] and p["reason"] == "ok"), "WON Results -> teaser shown, next frontier available: %s" % str(shown))
	_ok(_params("next_cleanup_tap") == [{"ok": true, "reason": "ok"}, {"ok": false, "reason": "not_results"}], "CLEAN NEXT -> ok; stale second tap -> refusal reason: %s" % str(_params("next_cleanup_tap")))
	var st: Array = _params("level_start")
	_ok(st.size() == 2 and st[1]["level"] == LEVEL + 1 and st[1]["entry"] == "launch", "the accepted tap starts the next level (conversion)")
	var j := ResultsMomentum.journey(_app().progression, "results", 10, ResultsMomentum.load_config())
	_ok(j["slot"] == 10 and j["slot"] == j["length"], "cycle_complete = slot 10 of 10 (the L10 Results journey)")
	_complete("next_cleanup_journey")
	print("[019 pack pity / dry streak / set level]")
	var pk: Array = _params("pack_opened")
	_ok(pk.size() >= 1 and pk[0]["pity"] and pk[0]["new_cards"] != "0" and pk[0]["dry_streak"] == "0", "pity-due pack -> pity true, guarantee fulfilled (new card), dry streak reset: %s" % str(pk))
	_ok(pk.slice(1).all(func(p): return not p["pity"]), "later packs: pity false")
	_complete("collection_pity")
	print("[020 Daily Scrub Orders]")
	_ok(_params("daily_order_done") == [{"tier": "easy", "metric": "levels_won", "target": 1}, {"tier": "normal", "metric": "levels_won", "target": 2},
		{"tier": "stretch", "metric": "levels_won", "target": 3}], "orders done on the committed wins: %s" % str(_params("daily_order_done")))
	_ok(_params("daily_order_claim").map(func(p): return p["tier"]) == ["easy", "normal", "stretch", "scrubbox"], "three order claims + ScrubBox: %s" % str(_params("daily_order_claim")))
	_complete("daily_orders")
	print("[021 Weekly / First-Try]")
	_ok(_params("weekly_event") == [{"step": "joined", "milestone": 0}, {"step": "milestone_reached", "milestone": 1}, {"step": "milestone_reached", "milestone": 2},
		{"step": "milestone_claimed", "milestone": 1}], "Weekly: joined on the first counted win, milestones 1 / 2 reached, 1 claimed: %s" % str(_params("weekly_event")))
	_ok(_params("first_try") == [{"step": "joined", "run": 0}, {"step": "advanced", "run": 1}, {"step": "completed", "run": 2}, {"step": "claimed", "run": 2}],
		"First-Try: joined -> run 1 -> complete at 2 -> claimed: %s" % str(_params("first_try")))
	print("[022 Comeback / Catch-Up]")
	_ok(_params("comeback_window") == [{"catchup_offered": true}], "3-day absence -> one return window with Catch-Up offered")
	_ok(_params("catchup_step") == [{"step": 1, "complete": false}, {"step": 2, "complete": false}], "two first-clear wins -> Catch-Up steps 1, 2: %s" % str(_params("catchup_step")))
	_root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_ok(_params("comeback_window").size() == 1, "a resume without a new absence opens nothing")
	_complete("comeback_catchup")
	print("[011 Ranks view]")
	_ok(_params("ranks_view") == [{"table": "all_time", "band": 1}, {"table": "weekly", "band": 1}], "RANKS screen -> all_time table, WEEKLY tab -> weekly table, rank band 1 (Bronze): %s" % str(_params("ranks_view")))
	_complete("ranks_view")
	await _boot()
	_load_events()
	_app().actions.join_first_try()
	await _play()
	_first_action()
	await _terminal(&"LOST")
	_ok(_params("first_try") == [{"step": "joined", "run": 0}, {"step": "reset", "run": 0}], "first-attempt loss -> reset (run depth 0): %s" % str(_params("first_try")))
	_ok(_params("weekly_event").is_empty(), "a loss counts nothing for the Weekly event")
	_complete("weekly_first_try")

## 016: a provider that is offline (drops every batch) never blocks or grows the queue.
func _provider_offline() -> void:
	print("[016 provider offline fail-safe]")
	var an := _svc("off", [0])
	an.sink = AnalyticsService.NullSink.new()
	an.set_consent(true)
	var peak := 0
	for i in range(1000):
		an.track("screen_view", {"screen": "home"})
		peak = maxi(peak, an.queued())
	an.flush()
	_ok(peak < 20 and an.queued() == 0 and an.dropped == 0, "1000 events into an offline sink: queue peaks at %d (< batch 20), nothing kept" % peak)
	_complete("provider_offline")

# ------------------------------------------------------------------ ledger ----

func _cleanup() -> void:
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp", p.get_basename() + "_analytics.json"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))

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
	print("M56 analytics taxonomy evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
