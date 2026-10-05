extends SceneTree
## M43 master — Lanes C011 Worlds, C012/C012R Comeback + Notifications, C013 Cloud save,
## C014 meta audio / haptics / offline language (SB-M43-135..168, R12-001..007).
## Real app root (main.tscn) with injected clock + local day where a surface is involved.
##
## Run: godot --headless --path . -s res://tests/m43_master_c011_c014.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const WorldRegistry = preload("res://scripts/progression/world_registry.gd")
const ReturnService = preload("res://scripts/economy/return_service.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const CloudSave = preload("res://scripts/save/cloud_save.gd")
const MetaFeedback = preload("res://scripts/ui/feel/meta_feedback.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

var EXPECTED_CASES := [
	"w01_world01_default_preserved", "w02_registry_ranges_fail_closed", "w03_current_world_derived", "w04_worlds_presentation_only",
	"c01_absence_window_once", "c02_comeback_summary_no_mint", "c03_catchup_disabled_without_config", "c04_catchup_track_rules",
	"n01_opt_in_and_toggles", "n02_priority_cap_quiet", "n03_stale_suppression_deep_links",
	"s01_local_authoritative_offline", "s02_resolve_rules", "s03_restore_integrity",
	"a01_committed_only", "a02_settings_live", "a03_fatigue", "a04_empty_offline_language",
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
	_w01(); _w02(); _w03(); _w04()
	await _c01()
	await _c02()
	_c03(); _c04()
	_n01(); await _n02(); await _n03()
	_s01(); _s02(); _s03()
	await _a01(); await _a02(); _a03(); await _a04()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ worlds ----

func _w01() -> void:
	print("[w01 World 01 Whispering Park stays the default Home world]")
	var d := WorldRegistry.load_worlds()
	_ok(d["ok"] and d["default"] == "world_01" and String(d["worlds"]["world_01"]["background_slug"]) == "home_background_whispering_park", "world_01 default, owner background slug")
	_ok(WorldRegistry.current_world(1) == "world_01" and WorldRegistry.current_world(500) == "world_01", "no owner range -> world_01 at every level")
	_complete("w01_world01_default_preserved")

func _w02() -> void:
	print("[w02 ranges are data; malformed / overlapping ranges fail closed]")
	var d := WorldRegistry.load_worlds()
	_ok(WorldRegistry.ranged(d).is_empty(), "shipped data defines no range (SB-M43-136 open)")
	var bad := {"default": "world_01", "worlds": {"world_01": {"range": {"first": 1, "last": 30}}, "world_02": {"range": {"first": 20, "last": 60}}}}
	_ok(WorldRegistry.ranged(bad).is_empty() and WorldRegistry.current_world(25, bad) == "world_01", "overlap -> no ranges, default")
	_complete("w02_registry_ranges_fail_closed")

func _w03() -> void:
	print("[w03 current world derived from progression (never stored)]")
	var d := {"default": "world_01", "worlds": {"world_01": {"range": {"first": 1, "last": 30}}, "world_02": {"range": {"first": 31, "last": 60}}}}
	_ok(WorldRegistry.current_world(30, d) == "world_01" and WorldRegistry.current_world(31, d) == "world_02", "boundary 30 / 31")
	_ok(WorldRegistry.states(31, d) == {"world_01": "completed", "world_02": "current"} and WorldRegistry.states(5, d) == {"world_01": "current", "world_02": "locked"}, "locked / current / completed")
	_complete("w03_current_world_derived")

func _w04() -> void:
	print("[w04 world data is presentation only]")
	var s := _code(FileAccess.get_file_as_string("res://scripts/progression/world_registry.gd"))
	_ok(not s.contains("Solver") and not s.contains("BoardState") and not s.contains("difficulty") and not s.contains("LevelData"), "no solver / board / difficulty access")
	_complete("w04_worlds_presentation_only")

# ---------------------------------------------------------------- comeback ----

func _c01() -> void:
	print("[c01 genuine absence (>= 48 h) opens one return window; rollback never does]")
	var r := ReturnService.new(func(): return _now[0])
	r.on_active()
	_now[0] += 47 * 3600
	_ok(not r.on_active()["opened"], "47 h: no window")
	_now[0] += 49 * 3600
	_ok(r.on_active()["opened"] and r.summary_due(), "49 h gap: window opened, summary due")
	r.mark_summary_shown()
	_ok(not r.summary_due() and not r.on_active()["opened"], "summary once; resume minutes later opens nothing")
	var hi: int = _now[0]
	_now[0] -= 10 * 86400
	_ok(not r.on_active()["opened"], "clock rollback cannot open a window")
	_now[0] = hi + 3600
	r.touch()
	_now[0] += 3600
	_ok(not r.on_active()["opened"], "touch on lifecycle flush: short break is not an absence")
	var re := ReturnService.new(func(): return _now[0])
	_ok(re.import_snapshot(r.snapshot()) and not re.summary_due(), "persisted across relaunch")
	_ok(not re.import_snapshot({"version": 1, "last": 5, "high": 4, "window": 0, "window_ts": 0, "summary_shown": 0, "catchup": {}}), "high < last rejected")
	_complete("c01_absence_window_once")

func _c02() -> void:
	print("[c02 comeback summary on Home lists real ready state, grants nothing]")
	await _boot("c02")
	var a = _root.get_app_state()
	a.request_save()
	var path: String = MainScript.boot_save_path_override
	_root.flush_lifecycle("test")
	_now[0] += 3 * 86400
	_day[0] += 3
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)
	var e = _root.get_app_state().economy
	var sb0: int = e.wallet.scrub_bucks()
	var top = _root.get_modal_stack().top()
	_ok(top != null and String(top.popup_id) == "comeback", "Welcome Back on Home after 3 days (got %s)" % (String(top.popup_id) if top != null else "none"))
	_ok(top.find_child("Ready_daily", true, false) != null and top.find_child("Hearts", true, false) != null, "Hearts + Daily-ready lines")
	_ok(e.wallet.scrub_bucks() == sb0 and e.daily.streak() == 0, "nothing granted, Daily untouched")
	top.close("test")
	await _frames(3)
	_ok(_root.get_modal_stack().top() == null, "shown once (not re-opened on drain)")
	_complete("c02_comeback_summary_no_mint")

func _c03() -> void:
	print("[c03 Catch-Up: no owner reward sequence -> never offered]")
	var r := ReturnService.new(func(): return _now[0])
	r.on_active()
	_now[0] += 72 * 3600
	r.on_active()
	_ok(r.catchup().is_empty(), "shipped comeback_v1 has no steps: track not offered")
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ReturnService.PATH))
	_ok(int(cfg["absence_hours"]) == 48 and (cfg["catchup_steps"] as Array).is_empty(), "48 h candidate; rewards unconfigured")
	_complete("c03_catchup_disabled_without_config")

func _c04() -> void:
	print("[c04 Catch-Up with a test sequence: 3 first clears, once per window, expiry, no farming]")
	var path := _write_json("comeback", {"schema": "scrubbots.comeback.v1", "absence_hours": 48, "catchup_expire_days": 7,
		"approved_reward_types": ["scrub_bucks"], "catchup_steps": [{"wins": 1, "reward": {"scrub_bucks": 20}}, {"wins": 3, "reward": {"scrub_bucks": 40}}]})
	var r := ReturnService.new(func(): return _now[0], path)
	var rw := RewardGrantService.new()
	var sb0: int = rw.wallet().scrub_bucks()
	r.on_active()
	_now[0] += 50 * 3600
	r.on_active()
	_ok(not r.catchup().is_empty() and r.catchup()["wins"] == 0, "offered in the new window")
	r.on_first_clear_win()
	_ok(r.claim_catchup(0, rw)["ok"] and not r.claim_catchup(0, rw)["ok"] and not r.claim_catchup(1, rw)["ok"], "step 1 once; step 2 not reached")
	r.on_first_clear_win()
	r.on_first_clear_win()
	r.on_first_clear_win()
	_ok(r.catchup()["wins"] == 3 and r.claim_catchup(1, rw)["ok"] and rw.wallet().scrub_bucks() == sb0 + 60, "capped at 3 wins; +60 SB total")
	var snap := r.snapshot()
	r.on_active()
	_ok(r.catchup()["window"] == snap["window"] and not r.claim_catchup(1, rw)["ok"], "relaunch / resume: same window, no re-grant")
	_now[0] += 8 * 86400
	r.on_active()
	_ok(r.catchup()["window"] != snap["window"], "a new genuine absence opens a new window (new track)")
	var lt := _write_json("comeback_bad", {"schema": "scrubbots.comeback.v1", "approved_reward_types": ["scrub_bucks"], "catchup_steps": [{"wins": 4, "reward": {"scrub_bucks": 1}}]})
	var r2 := ReturnService.new(func(): return _now[0], lt)
	r2.on_active()
	_now[0] += 50 * 3600
	r2.on_active()
	_ok(r2.catchup().is_empty(), "more than three wins rejects the sequence")
	var src := _code(FileAccess.get_file_as_string("res://scripts/economy/return_service.gd"))
	_ok(not src.contains("daily") and not src.contains("first_clear_sb") and not src.contains("multiplier"), "never touches Daily / level economy")
	_complete("c04_catchup_track_rules")

# ----------------------------------------------------------- notifications ----

func _n01() -> void:
	print("[n01 opt-in by default; per-category toggles; deep links validated]")
	var n := NotificationPolicy.new()
	_ok(not n.enabled and n.categories.values().all(func(v): return v), "global OFF by default")
	_ok(n.set_category("daily", false) and not n.set_category("ads", true), "known categories only")
	_ok(NotificationPolicy.deep_link("daily") == "daily" and NotificationPolicy.deep_link("debug_menu") == "home" and NotificationPolicy.deep_link("") == "home", "unknown deep link -> home")
	_ok(NotificationPolicy.in_quiet_hours(23, 22, 8) and NotificationPolicy.in_quiet_hours(7, 22, 8) and not NotificationPolicy.in_quiet_hours(12, 22, 8), "quiet hours across midnight")
	_complete("n01_opt_in_and_toggles")

func _n02() -> void:
	print("[n02 one message: priority collapse, 24 h cap, quiet hours]")
	await _boot("n02")
	var a = _root.get_app_state()
	var n = a.economy.notify
	_ok(n.decide(a, _now[0], 12).is_empty(), "opted out: nothing")
	n.enabled = true
	a.economy.gift.add_streak_sb("n02", 20)
	var m: Dictionary = n.decide(a, _now[0], 12)
	_ok(m["category"] == "daily" and m["link"] == "daily", "Hearts full + Daily + Gift -> one Daily message %s" % str(m))
	_ok(n.decide(a, _now[0], 23).is_empty(), "quiet hours: nothing")
	n.mark_sent(_now[0])
	_ok(n.decide(a, _now[0] + 3600, 12).is_empty() and not n.decide(a, _now[0] + 86400, 12).is_empty(), "cap: one per 24 h")
	n.set_category("daily", false)
	_ok(n.decide(a, _now[0] + 86400, 12)["category"] == "gift", "category OFF -> next priority")
	_complete("n02_priority_cap_quiet")

func _n03() -> void:
	print("[n03 stale prompts suppressed from live state; factual copy]")
	await _boot("n03")
	var a = _root.get_app_state()
	var n = a.economy.notify
	n.enabled = true
	a.actions.claim_daily_login()
	a.economy.hearts.consume()
	var c := NotificationPolicy.candidates(a)
	_ok(c.is_empty(), "Daily claimed + Hearts not full + nothing claimable -> no candidate %s" % str(c))
	var copy := ""
	for k in ["NOTIFY_HEARTS_FULL", "NOTIFY_DAILY", "NOTIFY_GIFT", "NOTIFY_EVENT_ENDING"]:
		copy += UiText.t(k).to_lower()
	_ok(not copy.contains("miss") and not copy.contains("lose") and not copy.contains("last chance"), "no guilt / false-expiry wording")
	_ok(_code(FileAccess.get_file_as_string("res://scripts/economy/notification_policy.gd")).contains("int(v[\"claimable\"]) > 0"), "event-ending only with a real claimable reward")
	_complete("n03_stale_suppression_deep_links")

# ------------------------------------------------------------------- cloud ----

func _s01() -> void:
	print("[s01 local save authoritative + offline: no network / SDK in the save path]")
	var bad: Array = []
	for f in ["res://scripts/save/save_service.gd", "res://scripts/save/cloud_save.gd", "res://scripts/app/app_state.gd"]:
		var s := _code(FileAccess.get_file_as_string(f))
		for t in ["HTTPRequest", "HTTPClient", "StreamPeerTCP", "WebSocket", "JavaClassWrapper", "Engine.get_singleton"]:
			if s.contains(t):
				bad.append("%s:%s" % [f.get_file(), t])
	_ok(bad.is_empty(), "no network / platform SDK %s" % str(bad))
	_complete("s01_local_authoritative_offline")

func _s02() -> void:
	print("[s02 resolve: superset wins, equal keeps local, divergence = explicit conflict, invalid ignored]")
	var a := AppState.new(_tmp_path("s02a"), func(): return _now[0], func(): return _day[0])
	var base := CloudSave.envelope(a.save, "dev-a", 1, _now[0])
	a.actions.claim_daily_login()
	a.progression.record_win(1)
	var ahead := CloudSave.envelope(a.save, "dev-a", 2, _now[0])
	_ok(CloudSave.resolve(a.save, ahead, base)["action"] == "keep_local", "local ahead keeps local")
	_ok(CloudSave.resolve(a.save, base, ahead)["action"] == "take_remote", "remote ahead taken")
	_ok(CloudSave.resolve(a.save, ahead, ahead.duplicate(true))["reason"] == "equal", "equal keeps local")
	var b := AppState.new(_tmp_path("s02b"), func(): return _now[0], func(): return _day[0])
	CloudSave.restore(b.save, base)
	b.economy.gift.add_streak_sb("other", 10)
	b.economy.reward.grant("other-device-tx", {"scrub_bucks": 5})
	var other := CloudSave.envelope(b.save, "dev-b", 2, _now[0])
	var r := CloudSave.resolve(a.save, ahead, other)
	_ok(r["action"] == "conflict" and r.has("local") and r.has("remote"), "diverged copies -> conflict with both summaries (no merge)")
	var broken: Dictionary = other.duplicate(true)
	broken["payload"]["economy"]["wallet_hack"] = 1
	broken["payload"]["version"] = 99
	_ok(CloudSave.resolve(a.save, ahead, broken)["action"] == "invalid_remote" and CloudSave.resolve(a.save, ahead, "x")["action"] == "invalid_remote", "future / malformed remote ignored")
	_complete("s02_resolve_rules")

func _s03() -> void:
	print("[s03 restore on a new device: Collection / robots / boosters / entitlement / Daily intact]")
	var a := AppState.new(_tmp_path("s03a"), func(): return _now[0], func(): return _day[0])
	a.actions.claim_daily_login()
	a.economy.collection.add_card(a.economy.collection.all_card_ids()[3])
	a.economy.wallet.credit("bot_parts", 260)
	a.actions.unlock_next_robot()
	a.economy.boosters.add_charges("tornado", 2)
	a.economy.wallet.credit("scrub_bucks", 1000)
	a.actions.buy_timed_2x(900)
	var env := CloudSave.envelope(a.save, "dev-a", 3, _now[0])
	var fresh := AppState.new(_tmp_path("s03b"), func(): return _now[0], func(): return _day[0])
	_ok(CloudSave.restore(fresh.save, env)["ok"], "restore applied")
	var same: bool = JSON.stringify(fresh.economy.snapshot()) == JSON.stringify(a.economy.snapshot()) and JSON.stringify(fresh.progression.snapshot()) == JSON.stringify(a.progression.snapshot())
	_ok(same and fresh.economy.robots.is_unlocked("moppy") and fresh.economy.boosters.charges("tornado") == 2 and fresh.economy.daily.claimed_today(), "byte-identical economy + progression")
	_ok(not fresh.actions.claim_daily_login()["ok"], "restored Daily claim cannot be repeated")
	var bad: Dictionary = env.duplicate(true)
	bad["payload"]["economy"]["reward"]["applied"] = [1, 2]
	var fresh2 := AppState.new(_tmp_path("s03c"), func(): return _now[0], func(): return _day[0])
	var before := JSON.stringify(fresh2.economy.snapshot())
	_ok(not CloudSave.restore(fresh2.save, bad)["ok"] and JSON.stringify(fresh2.economy.snapshot()) == before, "corrupt copy refused, device untouched")
	_complete("s03_restore_integrity")

# --------------------------------------------------------------- feedback ----

func _a01() -> void:
	print("[a01 meta sound / haptics only after a committed result]")
	await _boot("a01")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	mf.platform_vibrate = func(ms): buzz.append(ms)
	mf.played.clear()
	a.economy.wallet.debit("scrub_bucks", a.economy.wallet.scrub_bucks())
	a.actions.buy_booster_charge("random")
	_ok(mf.played.is_empty() and buzz.is_empty(), "failed purchase (no SB): silent")
	a.actions.claim_daily_login()
	_ok(mf.played.size() == 1 and mf.played[0][0] == "reward" and mf.played[0][1] and buzz == [MetaFeedback.SUCCESS_MS], "committed Daily claim: one reward sound + short buzz")
	_complete("a01_committed_only")

func _a02() -> void:
	print("[a02 Master / SFX / Haptics / Reduced Effects obeyed immediately]")
	await _boot("a02")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	mf.platform_vibrate = func(ms): buzz.append(ms)
	a.audio.set_sfx_enabled(false)
	a.haptics.set_enabled(false)
	mf.moment("reward")
	_ok(mf.played[-1] == ["reward", false, 0] and buzz.is_empty(), "SFX off + Haptics off: silent, no buzz")
	a.audio.set_sfx_enabled(true)
	a.haptics.set_enabled(true)
	a.effects.set_reduced(true)
	await create_timer(0.7).timeout
	mf.moment("reward")
	_ok(mf.played[-1] == ["reward", true, 0] and buzz.is_empty(), "Reduced Effects: sound kept, no haptic")
	_ok(mf._player.bus == "SFX" or mf._player.bus == "Master", "voice on the SFX bus (bus volume = settings)")
	a.effects.set_reduced(false)
	_complete("a02_settings_live")

func _a03() -> void:
	print("[a03 fatigue: repeated claim / open / close loops never stack]")
	var mf := MetaFeedback.new()
	var buzz: Array = []
	mf.platform_vibrate = func(ms): buzz.append(ms)
	for _i in range(20):
		mf.moment("reward")
	_ok(mf.played.size() == 1 and buzz.size() == 0, "20 rapid moments -> 1 (no app bound: no haptic)")
	mf.free()
	_complete("a03_fatigue")

func _a04() -> void:
	print("[a04 graceful empty / offline language]")
	await _boot("a04")
	var keys := ["GIFTS_EMPTY", "EVENTS_EMPTY", "EVENTS_UNAVAILABLE", "TASK_NONE", "CARDS_EMPTY", "NOTIFY_PLATFORM_PENDING"]
	var missing: Array = keys.filter(func(k): return UiText.t(k) == k or UiText.t(k).is_empty())
	_ok(missing.is_empty(), "empty / unavailable copy exists %s" % str(missing))
	_root.get_home().get_region("GiftMeterButton").pressed.emit()
	await _frames(2)
	var top = _root.get_modal_stack().top()
	_ok(top != null and top.find_child("Empty", true, false) != null and top.find_child("Empty", true, false).text == UiText.t("GIFTS_EMPTY"), "no claimable gifts -> empty state")
	_complete("a04_empty_offline_language")

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _tmp_path(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _tmp_path(tag: String) -> String:
	var path := "user://m43master_c014_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

func _write_json(tag: String, d: Dictionary) -> String:
	var path := "user://m43master_c014_%s_%d.json" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return path

func _code(src: String) -> String:
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
	print("M43 master C011-C014 evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
