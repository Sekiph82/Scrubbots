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
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

var EXPECTED_CASES := [
	"w01_world01_default_preserved", "w02_registry_ranges_fail_closed", "w03_current_world_derived", "w04_worlds_presentation_only",
	"c01_absence_window_once", "c02_comeback_summary_no_mint", "c03_catchup_disabled_without_config", "c04_catchup_track_rules",
	"n01_opt_in_and_toggles", "n02_priority_cap_quiet", "n03_stale_suppression_deep_links",
	"n04_clock_rollback_cap_reload", "n05_timezone_local_hour_policy",
	"s01_local_authoritative_offline", "s02_resolve_rules", "s03_restore_integrity",
	"s04_conflict_matrix_economy_safety", "s05_order_and_history_contradictions", "s06_invalid_envelopes_fail_closed", "s07_whole_copy_no_merge",
	"a01_committed_only", "a02_settings_live", "a03_fatigue_real_loops", "a04_empty_offline_language",
	"a05_family_mapping_table", "a06_popup_seams_real_ui", "a07_canonical_ceremony_kinds", "a08_pack_reveal_rare_hook",
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
	_n01(); await _n02(); await _n03(); await _n04(); await _n05()
	_s01(); _s02(); _s03(); _s04(); _s05(); _s06(); _s07()
	await _a01(); await _a02(); await _a03(); await _a04()
	_a05(); await _a06(); await _a07(); await _a08()
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

func _n04() -> void:
	print("[n04 R12-005 / R12-007: clock rollback behind the last send never bypasses the 24 h cap, across reload]")
	await _boot("n04")
	var a = _root.get_app_state()
	var n = a.economy.notify
	n.enabled = true
	var t: int = _now[0]
	_ok(not n.decide(a, t, 12).is_empty(), "eligible at T (Hearts full + Daily ready)")
	n.mark_sent(t)
	_ok(n.decide(a, t - 3600, 12).is_empty(), "send at T, decide at T-1h (clock rolled back) -> none")
	_ok(n.decide(a, t - 10 * 86400, 12).is_empty(), "rollback by 10 days -> still none (cap not forgiven)")
	n.mark_sent(t - 3600)
	_ok(int(n.snapshot()["last_sent"]) == t, "a stale mark_sent never lowers the high-water")
	a.request_save()
	var path: String = MainScript.boot_save_path_override
	_root.flush_lifecycle("test")
	_shutdown()
	_now[0] = t - 3600
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	a = _root.get_app_state()
	n = a.economy.notify
	_ok(n.enabled and int(n.snapshot()["last_sent"]) == t, "reloaded with the persisted high-water (clock at T-1h)")
	_ok(n.decide(a, t - 3600, 12).is_empty(), "reload at T-1h -> none")
	_ok(n.decide(a, t + 23 * 3600, 12).is_empty(), "T+23h -> none")
	_ok(n.decide(a, t + 86400 - 1, 12).is_empty(), "T+24h-1s -> none")
	_ok(not n.decide(a, t + 86400, 12).is_empty(), "T+24h -> eligible again (rollback suppression is not permanent)")
	_ok(n.decide(a, t + 86400, 23).is_empty(), "quiet hours still apply after catch-up")
	n.set_category("daily", false)
	_ok(n.decide(a, t + 86400, 12)["category"] == "hearts", "category toggle + priority still apply after catch-up")
	n.set_category("daily", true)
	_now[0] = t
	_complete("n04_clock_rollback_cap_reload")

func _n05() -> void:
	print("[n05 SB-M43-151 policy: same UTC instant, different injected local hour / timezone]")
	await _boot("n05")
	var a = _root.get_app_state()
	var n = a.economy.notify
	n.enabled = true
	var t: int = _now[0]
	var utc_hour: int = int(Time.get_datetime_dict_from_unix_time(t)["hour"])
	var zones := {"UTC+0": utc_hour, "UTC+9": (utc_hour + 9) % 24, "UTC-5": (utc_hour + 19) % 24}
	var quiet := {}
	for z in zones:
		quiet[z] = n.decide(a, t, zones[z]).is_empty()
		_ok(quiet[z] == NotificationPolicy.in_quiet_hours(zones[z], n.quiet_from, n.quiet_to), "%s (local %02d:00): outcome follows that zone's quiet hours" % [z, zones[z]])
	_ok(n.decide(a, t, 23).is_empty() and not n.decide(a, t, 12).is_empty(), "same UTC timestamp: local 23:00 quiet, local 12:00 eligible")
	_ok(int(n.snapshot()["last_sent"]) == 0, "quiet-hours decisions never consume / move the cap")
	n.mark_sent(t)
	_ok(n.decide(a, t + 6 * 3600, 12).is_empty() and n.decide(a, t + 6 * 3600, 3).is_empty(), "a zone change after a send (any local hour) cannot reopen the 24 h cap")
	_ok(not n.decide(a, t + 86400, 12).is_empty() and n.decide(a, t + 86400, 23).is_empty(), "after 24 h: eligibility again decided by the local hour only")
	_complete("n05_timezone_local_hour_policy")

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
	var ahead := CloudSave.envelope(a.save, "dev-a", 2, _now[0], base)
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

## SB-M43-155 remediation V03 helpers: a copy restored from `env` on a fresh device, mutated by
## `mutate`, re-enveloped at (revision, saved_at).
func _fork(env: Dictionary, tag: String, mutate: Callable, revision: int, saved_at: int) -> Dictionary:
	var d := AppState.new(_tmp_path(tag), func(): return _now[0], func(): return _day[0])
	_ok(CloudSave.restore(d.save, env)["ok"], "%s: fork restored" % tag)
	mutate.call(d)
	return CloudSave.envelope(d.save, "dev-" + tag, revision, saved_at, env)

func _act(r: Dictionary) -> String:
	return "%s/%s" % [r["action"], r["reason"]]

func _s04() -> void:
	print("[s04 SB-M43-155 conflict matrix: only exact payload equality is 'equal'; same history + different economy = conflict]")
	var t0: int = _now[0]
	var a := AppState.new(_tmp_path("s04a"), func(): return _now[0], func(): return _day[0])
	a.actions.claim_daily_login()
	a.progression.record_win(1)
	var base := CloudSave.envelope(a.save, "dev-a", 5, t0)
	var sv = a.save
	_ok(_act(CloudSave.resolve(sv, base, base.duplicate(true))) == "keep_local/equal", "exact payload equality -> keep_local/equal")
	var wire = JSON.parse_string(JSON.stringify(base))
	_ok(_act(CloudSave.resolve(sv, base, wire)) == "keep_local/equal", "JSON round-tripped identical copy (ints as floats) -> equal (canonical)")
	var ahead := _fork(base, "s04ahead", func(d): d.progression.record_win(2); d.economy.reward.grant("s04-ahead-tx", {"scrub_bucks": 5}), 6, t0 + 60)
	_ok(_act(CloudSave.resolve(sv, ahead, base)) == "keep_local/local_ahead", "local strict descendant (rev 6 > 5, later) -> keep_local")
	_ok(_act(CloudSave.resolve(sv, base, ahead)) == "take_remote/remote_ahead", "remote strict descendant -> take_remote")
	var cases := {
		"wallet (legit spend lowers SB)": func(d): d.economy.wallet.debit("scrub_bucks", 100),
		"wallet (higher SB is not 'newer')": func(d): d.economy.wallet.credit("scrub_bucks", 500),
		"Collection copies": func(d): d.economy.collection.add_card(d.economy.collection.all_card_ids()[3]),
		"robot active / unlock": func(d): d.economy.wallet.credit("bot_parts", 260); d.economy.robots.unlock("moppy"),
		"booster inventory": func(d): d.economy.boosters.add_charges("tornado", 2),
		"Daily task state": func(d): d.economy.daily.import_snapshot(_with(d.economy.daily.snapshot(), "highest_seen_ts", t0 + 3600)),
	}
	for label in cases:
		var other := _fork(base, "s04x", cases[label], 6, t0 + 60)
		var r1 := CloudSave.resolve(sv, base, other)
		var r2 := CloudSave.resolve(sv, other, base)
		_ok(_act(r1) == "conflict/same_history_economy_differs" and _act(r2) == "conflict/same_history_economy_differs" and r1.has("local") and r1.has("remote"),
			"same tx + progression, different %s -> conflict both directions (%s | %s)" % [label, _act(r1), _act(r2)])
	var muted := _fork(base, "s04set", func(d): d.audio.set_sfx_enabled(false), 6, t0 + 60)
	_ok(_act(CloudSave.resolve(sv, base, muted)) == "keep_local/same_authority", "only device settings differ -> keep_local/same_authority (never 'equal')")
	_complete("s04_conflict_matrix_economy_safety")

func _with(d: Dictionary, k: String, v) -> Dictionary:
	var o := d.duplicate(true)
	o[k] = v
	return o

func _s05() -> void:
	print("[s05 SB-M43-155 revision / saved_at and append-only history must agree with the descendant direction]")
	var t0: int = _now[0]
	var a := AppState.new(_tmp_path("s05a"), func(): return _now[0], func(): return _day[0])
	a.progression.record_win(1)
	var base := CloudSave.envelope(a.save, "dev-a", 5, t0)
	var sv = a.save
	var grow := func(d): d.progression.record_win(2); d.economy.reward.grant("s05-tx", {"scrub_bucks": 5})
	var stale_rev := _fork(base, "s05r", grow, 4, t0 + 60)
	var same_rev := _fork(base, "s05s", grow, 5, t0 + 60)
	var old_ts := _fork(base, "s05t", grow, 6, t0 - 60)
	for pair in [["revision lower than ancestor", stale_rev], ["revision equal to ancestor", same_rev], ["saved_at older than ancestor", old_ts]]:
		var r1 := CloudSave.resolve(sv, base, pair[1])
		var r2 := CloudSave.resolve(sv, pair[1], base)
		_ok(_act(r1) == "conflict/order_contradiction" and _act(r2) == "conflict/order_contradiction", "superset history but %s -> conflict (%s | %s)" % [pair[0], _act(r1), _act(r2)])
	var ok_order := _fork(base, "s05ok", grow, 6, t0)
	_ok(_act(CloudSave.resolve(sv, base, ok_order)) == "take_remote/remote_ahead", "same saved_at + higher revision is coherent -> take_remote")
	var robot_local := _fork(base, "s05rb", func(d): d.economy.wallet.credit("bot_parts", 260); d.economy.robots.unlock("moppy"), 6, t0 + 30)
	var tx_remote := _fork(base, "s05tx", grow, 7, t0 + 60)
	var r := CloudSave.resolve(sv, robot_local, tx_remote)
	_ok(_act(r) == "conflict/history_contradiction", "remote has more tx/progression but lacks a robot unlock the local copy holds -> conflict (%s)" % _act(r))
	var b1 := _fork(base, "s05d1", func(d): d.economy.reward.grant("dev1-only", {"scrub_bucks": 5}), 6, t0 + 60)
	var b2 := _fork(base, "s05d2", func(d): d.progression.record_win(2), 7, t0 + 90)
	_ok(_act(CloudSave.resolve(sv, b1, b2)) == "conflict/diverged" and _act(CloudSave.resolve(sv, b2, b1)) == "conflict/diverged", "tx-only vs progression-only divergence -> conflict, regardless of revision")
	_complete("s05_order_and_history_contradictions")

func _s06() -> void:
	print("[s06 SB-M43-155 malformed / future envelopes fail closed on BOTH sides]")
	var a := AppState.new(_tmp_path("s06a"), func(): return _now[0], func(): return _day[0])
	var good := CloudSave.envelope(a.save, "dev-a", 1, _now[0])
	var sv = a.save
	var muts := {
		"future envelope schema": func(e): e["schema"] = "scrubbots.cloud.v2",
		"future payload version": func(e): e["payload"]["version"] = 99,
		"string revision": func(e): e["revision"] = "2",
		"fractional revision": func(e): e["revision"] = 1.5,
		"negative revision": func(e): e["revision"] = -1,
		"missing saved_at": func(e): e.erase("saved_at"),
		"NaN saved_at": func(e): e["saved_at"] = NAN,
		"non-string device": func(e): e["device"] = 7,
		"missing lineage": func(e): e.erase("lineage"),
		"non-hex lineage entry": func(e): e["lineage"] = ["not-a-fingerprint"],
		"oversized lineage": func(e): e["lineage"] = range(CloudSave.LINEAGE_MAX + 1).map(func(_i): return "a".repeat(64)),
		"payload not an object": func(e): e["payload"] = [],
		"corrupt reward tx ids": func(e): e["payload"]["economy"]["reward"]["applied"] = [1, 2],
		"removed economy present": func(e): e["payload"]["economy"]["stars"] = 3,
	}
	for label in muts:
		var bad: Dictionary = good.duplicate(true)
		muts[label].call(bad)
		var rr := CloudSave.resolve(sv, good, bad)
		var rl := CloudSave.resolve(sv, bad, good)
		_ok(rr["action"] == "invalid_remote" and rl["action"] == "invalid_local", "%s -> invalid_remote / invalid_local (%s | %s)" % [label, _act(rr), _act(rl)])
	_ok(CloudSave.resolve(sv, good, null)["action"] == "invalid_remote" and CloudSave.resolve(sv, good, "x")["action"] == "invalid_remote", "null / string remote rejected")
	_complete("s06_invalid_envelopes_fail_closed")

func _s07() -> void:
	print("[s07 SB-M43-155 ancestry proof + whole-copy apply: a wallet-only change is never overwritten, refunded or merged]")
	var t0: int = _now[0]
	var a := AppState.new(_tmp_path("s07a"), func(): return _now[0], func(): return _day[0])
	var base := CloudSave.envelope(a.save, "dev-a", 1, t0)
	var spent := _fork(base, "s07l", func(d): d.economy.wallet.debit("scrub_bucks", 300), 2, t0 + 10)
	var remote := _fork(base, "s07r", func(d): d.progression.record_win(1); d.economy.reward.grant("s07-remote", {"scrub_bucks": 5}), 3, t0 + 20)
	var r := CloudSave.resolve(a.save, spent, remote)
	_ok(_act(r) == "conflict/no_ancestry_proof", "local spent 300 SB after the fork; remote has more history but was built on the pre-spend state -> conflict, not a silent refund (%s)" % _act(r))
	_ok(not r.has("payload") and not r.has("wallet") and not r.has("merged") and r["local"]["tx"] == 0 and r["remote"]["tx"] == 1, "a decision carries summaries only, no merged payload")
	var synced := _fork(base, "s07s", func(_d): pass, 1, t0)
	_ok(_act(CloudSave.resolve(a.save, synced, remote)) == "take_remote/remote_ahead", "device untouched since the shared copy -> remote descendant taken")
	var on_spent := _fork(spent, "s07c", func(d): d.progression.record_win(1), 4, t0 + 30)
	_ok(_act(CloudSave.resolve(a.save, spent, on_spent)) == "take_remote/remote_ahead" and _act(CloudSave.resolve(a.save, on_spent, spent)) == "keep_local/local_ahead", "a copy built on the spent state is a proven descendant (both directions)")
	var fresh := AppState.new(_tmp_path("s07f"), func(): return _now[0], func(): return _day[0])
	fresh.economy.wallet.credit("scrub_bucks", 777)
	_ok(CloudSave.restore(fresh.save, remote)["ok"], "take_remote restores the remote copy")
	_ok(CloudSave.fingerprint(fresh.save.collect()["economy"]) == CloudSave.fingerprint(remote["payload"]["economy"]) and fresh.economy.wallet.scrub_bucks() == int(remote["payload"]["economy"]["reward"]["wallet"]["scrub_bucks"]),
		"economy is exactly the remote copy (the device's own +777 SB is not merged in)")
	var src := _code(FileAccess.get_file_as_string("res://scripts/save/cloud_save.gd"))
	_ok(not src.contains(".credit(") and not src.contains(".debit(") and not src.contains(".grant(") and not src.contains(".merge("), "resolver / restore never credit, debit, grant or merge")
	_complete("s07_whole_copy_no_merge")

# --------------------------------------------------------------- feedback ----

func _a01() -> void:
	print("[a01 success / reward only after a committed result; a refusal is a distinct warning, never the success chime]")
	await _boot("a01")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	mf.platform_vibrate = func(ms): buzz.append(ms)
	var ms := [300000]
	mf.clock_ms = func(): return ms[0]
	mf.played.clear()
	a.economy.wallet.debit("scrub_bucks", a.economy.wallet.scrub_bucks())
	a.actions.buy_booster_charge("random")
	_ok(_moments(mf) == ["error"] and buzz == [MetaFeedback.WARNING_MS] and MetaFeedback.SPEC["error"]["stream"] == "tick", "failed purchase (no SB): one warning tick + warning buzz, no success / reward %s" % str(mf.played))
	mf.played.clear(); buzz.clear()
	ms[0] += 1000
	a.actions.claim_daily_login()
	_ok(mf.played.size() == 1 and mf.played[0][0] == "reward" and mf.played[0][1] and buzz == [MetaFeedback.SUCCESS_MS], "committed Daily claim: one reward chime + success buzz")
	mf.played.clear(); buzz.clear()
	ms[0] += 1000
	_ok(not a.actions.claim_daily_login()["ok"] and mf.played.is_empty() and buzz.is_empty(), "repeated claim (already claimed) is an idempotent no-op: silent")
	_complete("a01_committed_only")

func _a02() -> void:
	print("[a02 Master / SFX / Haptics / Reduced Effects obeyed immediately (live, per request)]")
	await _boot("a02")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	var ms := [100000]
	mf.clock_ms = func(): return ms[0]
	mf.platform_vibrate = func(v): buzz.append(v)
	a.audio.set_sfx_enabled(false)
	a.haptics.set_enabled(false)
	for m in ["reward", "unlock", "error", "pack_rare", "success"]:
		ms[0] += 1000
		mf.moment(m)
	_ok(mf.played.slice(-5).all(func(p): return not p[1] and p[2] == 0) and buzz.is_empty(), "SFX off + Haptics off: every moment silent, no buzz")
	a.audio.set_sfx_enabled(true)
	a.haptics.set_enabled(true)
	a.effects.set_reduced(true)
	for m in ["reward", "unlock", "error", "pack_rare"]:
		ms[0] += 1000
		mf.moment(m)
	_ok(mf.played[-4][1] and mf.played[-4][2] == 0 and buzz.is_empty(), "Reduced Effects: sound kept, no haptic for any moment")
	a.effects.set_reduced(false)
	ms[0] += 1000
	mf.moment("unlock")
	_ok(buzz == [MetaFeedback.UNLOCK_MS], "Reduced Effects OFF again: unlock buzz returns at once")
	a.haptics.set_enabled(false)
	ms[0] += 1000
	mf.moment("unlock")
	_ok(buzz == [MetaFeedback.UNLOCK_MS], "Haptics OFF mid-session: next moment does not buzz")
	a.haptics.set_enabled(true)
	_ok(mf._player.bus == "SFX" or mf._player.bus == "Master", "voice on the SFX bus (bus volume = settings)")
	_complete("a02_settings_live")

## SB-M43-167: real representative UI loops on the real app root (Home shortcuts, real popups,
## real facade claims, real ceremonies, a real Premium pack), with an injected UI clock.
func _a03() -> void:
	print("[a03 fatigue: repeated open/close, back/confirm, claims, pack reveal, unlock in real UI loops]")
	await _boot("a03")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	var ms := [500000]
	mf.clock_ms = func(): return ms[0]
	mf.platform_vibrate = func(v): buzz.append(v)
	var voices := func(): return mf.find_children("*", "AudioStreamPlayer", true, false).size()
	# Loop 1: Daily popup open -> X (back) twenty times, 40 ms apart (rapid tapping).
	mf.played.clear()
	for _i in range(20):
		(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
		await _frames(1)
		ms[0] += 40
		_top().get_close_button().pressed.emit()
		await _frames(1)
		ms[0] += 40
	var opens := _moments(mf).count("popup_open")
	var backs := _moments(mf).count("back")
	_ok(opens >= 1 and opens <= 10 and backs >= 1 and backs <= 10, "20 rapid open/back loops -> rate-limited ticks (%d opens, %d backs)" % [opens, backs])
	_ok(voices.call() == 1 and buzz.is_empty(), "one voice node; UI ticks never buzz")
	# A genuinely different later action is heard (gap is short, not a permanent mute).
	ms[0] += 2000
	mf.played.clear()
	(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
	await _frames(1)
	_ok(_moments(mf) == ["popup_open"], "after a pause the next open is heard %s" % str(mf.played))
	# Loop 2: confirm + claim on the real Daily popup, then repeated claim taps.
	mf.played.clear()
	ms[0] += 1000
	var daily = _top()
	daily.get_action_button("claim").pressed.emit()
	await _frames(2)
	_ok(_moments(mf) == ["reward"] and buzz == [MetaFeedback.SUCCESS_MS], "CLAIM tap: the reward chime owns the frame, the confirm tick does not double-fire %s" % str(mf.played))
	_ok(_top() != null and String(_top().popup_id) == "ceremony_daily", "the claim's own reward popup opened in the same frame without its own tick")
	for _i in range(5):
		ms[0] += 300
		daily.get_action_button("claim").pressed.emit()
		await _frames(1)
		a.actions.claim_daily_login()
	_ok(_moments(mf).count("reward") == 1 and buzz.size() == 1 and not _moments(mf).has("error"), "repeated claim attempts (blocked button + already-claimed facade): no second reward, no buzz, no error %s" % str(mf.played))
	ms[0] += 1000
	_top().get_action_button(String(_top().get_action_ids()[0])).pressed.emit()
	await _frames(1)
	_ok(_moments(mf).slice(-1) == ["confirm"], "reward popup COLLECT -> one confirm tick")
	# Refresh / reopen of the same popup: no reward replays.
	ms[0] += 1000
	_root.get_modal_stack().clear("clear")
	await _frames(1)
	(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
	await _frames(2)
	_ok(_moments(mf).count("reward") == 1 and buzz.size() == 1, "reopen after claim: nothing replays")
	# Route change: stack cleared -> voice stopped, nothing queued, no later work.
	mf.moment("reward")
	ms[0] += 1000
	mf.moment("popup_open")
	_root.get_modal_stack().clear("deep_link")
	var n_before: int = mf.played.size()
	await _frames(4)
	_ok(not mf.is_voice_active() and mf._voice_until == 0 and mf._voice_prio == 0 and mf._ui_queue.is_empty() and not mf.is_processing() and mf.played.size() == n_before, "route change: voice stopped, queued tick dropped, no orphan work")
	# Loop 3: robot unlock (commit + ceremony) and a Premium pack reveal, each once.
	buzz.clear(); mf.played.clear()
	ms[0] += 2000
	a.economy.wallet.credit("bot_parts", 260)
	a.actions.unlock_next_robot()
	_root.ceremonies.drain("a03")
	await _frames(2)
	_ok(_moments(mf).count("unlock") == 1 and buzz == [MetaFeedback.UNLOCK_MS], "robot unlock commit + its ceremony -> ONE unlock chime + ONE unlock buzz %s" % str(mf.played))
	var c = _root.ceremonies.current()
	if c != null:
		c.close("action:" + String(c.get_action_ids()[0]))
	await _frames(2)
	_root.get_modal_stack().clear("clear")
	ms[0] += 2000
	buzz.clear(); mf.played.clear()
	var pack: Dictionary = await _open_pack("premium", "a03_premium")
	_ok(_moments(mf).count("pack_reveal") == 1 and _moments(mf).count("pack_rare") == 1 and buzz == [MetaFeedback.PACK_RARE_MS], "Premium pack: one reveal chime, one Rare+ buzz %s" % str(mf.played))
	_ok(voices.call() == 1, "still exactly one voice node after every loop")
	# Reduced Effects + Haptics OFF: the same loops stay buzz-free.
	a.effects.set_reduced(true)
	a.haptics.set_enabled(false)
	buzz.clear()
	for _i in range(5):
		ms[0] += 1000
		(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
		await _frames(1)
		_top().get_close_button().pressed.emit()
		await _frames(1)
		a.actions.claim_daily_login()
	ms[0] += 1000
	await _open_pack("premium", "a03_premium_reduced")
	_ok(buzz.is_empty(), "Reduced Effects + Haptics OFF: no buzz across open/close/claim/pack loops")
	a.effects.set_reduced(false)
	a.haptics.set_enabled(true)
	_ok(not pack.is_empty(), "pack loop ran on a committed receipt")
	_complete("a03_fatigue_real_loops")

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

func _a05() -> void:
	print("[a05 SB-M43-161/162 complete family: every moment bound, failure never sounds like success]")
	var want := ["confirm", "back", "popup_open", "popup_close", "reward", "pack_reveal", "unlock", "error", "success", "pack_rare"]
	_ok(want.all(func(m): return MetaFeedback.SPEC.has(m)) and MetaFeedback.SPEC.size() == want.size(), "family = %s" % str(MetaFeedback.SPEC.keys()))
	_ok(MetaFeedback.SPEC["error"]["stream"] == "tick" and MetaFeedback.SPEC["error"]["pitch"] < MetaFeedback.SPEC["back"]["pitch"], "error = low warning tick, never the completion chime")
	var hap := {}
	for m in MetaFeedback.SPEC:
		if int(MetaFeedback.SPEC[m]["haptic"]) > 0:
			hap[m] = int(MetaFeedback.SPEC[m]["haptic"])
	_ok(hap == {"error": MetaFeedback.WARNING_MS, "success": MetaFeedback.SUCCESS_MS, "reward": MetaFeedback.SUCCESS_MS, "pack_rare": MetaFeedback.PACK_RARE_MS, "unlock": MetaFeedback.UNLOCK_MS}, "haptic moments: success / warning / pack Rare+ / unlock %s" % str(hap))
	_ok([MetaFeedback.SUCCESS_MS, MetaFeedback.WARNING_MS, MetaFeedback.PACK_RARE_MS, MetaFeedback.UNLOCK_MS].all(func(v): return [MetaFeedback.SUCCESS_MS, MetaFeedback.WARNING_MS, MetaFeedback.PACK_RARE_MS, MetaFeedback.UNLOCK_MS].count(v) == 1), "four distinct haptic durations")
	var streams := {}
	for m in MetaFeedback.SPEC:
		streams[String(MetaFeedback.SPEC[m]["stream"])] = true
	_ok(streams.keys().all(func(k): return k in ["", "tick", "chime"]), "reuses only the two approved M33 files (no per-screen sound zoo)")
	var src := _code(FileAccess.get_file_as_string("res://scripts/ui/feel/meta_feedback.gd"))
	_ok(not src.contains("wallet") and not src.contains("commit_pack") and not src.contains("request_save") and not src.contains("navigate"), "observer only: no economy / save / navigation access")
	_complete("a05_family_mapping_table")

func _a06() -> void:
	print("[a06 real popup seams: open / confirm / back / programmatic close / route change]")
	await _boot("a06")
	var mf = _root.meta_feedback
	var ms := [700000]
	mf.clock_ms = func(): return ms[0]
	mf.played.clear()
	(_root.get_home().get_region("Shortcut_tasks") as Button).pressed.emit()
	await _frames(1)
	_ok(_moments(mf) == ["popup_open"], "Home TASKS -> popup_open %s" % str(mf.played))
	ms[0] += 500
	_top().get_action_button("close").pressed.emit()
	await _frames(1)
	_ok(_moments(mf) == ["popup_open", "confirm"], "popup action button -> confirm (action close itself is silent) %s" % str(mf.played))
	ms[0] += 500
	(_root.get_home().get_region("Shortcut_tasks") as Button).pressed.emit()
	await _frames(1)
	ms[0] += 500
	_top().get_close_button().pressed.emit()
	await _frames(1)
	_ok(_moments(mf).slice(-2) == ["popup_open", "back"], "X / Back -> back %s" % str(mf.played))
	ms[0] += 500
	(_root.get_home().get_region("Shortcut_tasks") as Button).pressed.emit()
	await _frames(1)
	ms[0] += 500
	_top().close("close")
	await _frames(1)
	_ok(_moments(mf).slice(-1) == ["popup_close"], "programmatic close -> popup_close")
	ms[0] += 500
	(_root.get_home().get_region("Shortcut_tasks") as Button).pressed.emit()
	await _frames(1)
	var n: int = mf.played.size()
	ms[0] += 500
	_root.get_modal_stack().clear("deep_link")
	await _frames(2)
	_ok(mf.played.size() == n and _root.get_modal_stack().depth() == 0, "route change closes silently")
	mf.ui_gate = func(): return false
	n = mf.played.size()
	mf.moment("popup_open")
	await _frames(1)
	_ok(mf.played.size() == n, "UI ticks gated off outside the HOME route (gameplay keeps its own M33 / M34 feedback)")
	_complete("a06_popup_seams_real_ui")

func _a07() -> void:
	print("[a07 canonical CeremonyEvents kinds map to the right moments]")
	var src := FileAccess.get_file_as_string("res://scripts/economy/ceremony_events.gd")
	var kinds: Array = []
	var re := RegEx.new()
	re.compile("\"kind\": \"([a-z_]+)\"")
	for m in re.search_all(src):
		kinds.append(m.get_string(1))
	_ok(kinds == ["gift_milestone", "set_complete", "master_complete", "robot_unlock"], "emitted kinds %s" % str(kinds))
	var mapped := {}
	for k in kinds:
		mapped[k] = MetaFeedback.moment_for_ceremony(k)
	_ok(mapped == {"gift_milestone": "reward", "set_complete": "unlock", "master_complete": "unlock", "robot_unlock": "unlock"}, "robot / master / set -> unlock, gift -> reward %s" % str(mapped))
	await _boot("a07")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	mf.platform_vibrate = func(v): buzz.append(v)
	_root.get_modal_stack().clear("clear")
	a.economy.wallet.credit("bot_parts", 260)
	a.economy.robots.unlock("moppy")
	mf.played.clear()
	_root.ceremonies.drain("a07")
	await _frames(2)
	var log: Array = _root.ceremonies.presented_log()
	_ok(not log.is_empty() and log[-1][1] == "robot_unlock" and _moments(mf) == ["unlock"] and buzz == [MetaFeedback.UNLOCK_MS], "real robot_unlock ceremony -> unlock chime + unlock buzz (not 'reward') %s" % str(mf.played))
	_complete("a07_canonical_ceremony_kinds")

func _a08() -> void:
	print("[a08 Standard / Premium pack: reveal + first Rare+ from committed truth; read-only, once per presentation]")
	await _boot("a08")
	var a = _root.get_app_state()
	var mf = _root.meta_feedback
	var buzz: Array = []
	var ms := [900000]
	mf.clock_ms = func(): return ms[0]
	mf.platform_vibrate = func(v): buzz.append(v)
	mf.played.clear()
	var r: Dictionary = await _open_pack("premium", "a08_p1")
	var cards: Array = r["model"]["cards"]
	var first_rare := -1
	for i in cards.size():
		if first_rare < 0 and String(cards[i]["rarity"]) in MetaFeedback.RARE_OR_BETTER:
			first_rare = i
	_ok(first_rare == 0 and _moments(mf).count("pack_reveal") == 1 and _moments(mf).count("pack_rare") == 1 and buzz == [MetaFeedback.PACK_RARE_MS], "Premium (card 0 guaranteed Rare+): one reveal + one Rare+ buzz %s" % str(mf.played))
	_ok(JSON.stringify(a.pack_receipt("a08_p1")) == JSON.stringify(r["receipt"]) and JSON.stringify(a.pack_presentation_model("a08_p1")) == JSON.stringify(r["model"]), "receipt / model unchanged by the hook (no reroll / reorder)")
	_ok(JSON.stringify(r["econ_after"]) == JSON.stringify(r["econ_before"]), "economy snapshot identical before / after the presentation (presentation only)")
	ms[0] += 5000
	buzz.clear(); mf.played.clear()
	var again: Dictionary = await _open_pack("premium", "a08_p1")
	_ok(bool(again["replay"]) and _moments(mf).count("pack_reveal") == 0 and _moments(mf).count("pack_rare") == 0 and buzz.is_empty(), "reopen of the same committed presentation: no second reveal / Rare+ %s" % str(mf.played))
	var std_any_rare := false
	var std_ok := false
	for t in range(12):
		ms[0] += 5000
		buzz.clear(); mf.played.clear()
		var s: Dictionary = await _open_pack("standard", "a08_s%d" % t)
		var rare := (s["model"]["cards"] as Array).any(func(c): return String(c["rarity"]) in MetaFeedback.RARE_OR_BETTER)
		std_ok = _moments(mf).count("pack_reveal") == 1 and _moments(mf).count("pack_rare") == (1 if rare else 0) and buzz == ([MetaFeedback.PACK_RARE_MS] if rare else [])
		if not std_ok:
			break
		if not rare:
			break
		std_any_rare = true
	_ok(std_ok, "Standard pack: reveal once; Rare+ buzz only when a committed card is Rare+ %s" % str(mf.played))
	_ok(_code(FileAccess.get_file_as_string("res://scripts/ui/feel/meta_feedback.gd")).contains("get_card_views().find("), "rarity read from the emerging CardView's committed model row")
	_complete("a08_pack_reveal_rare_hook")

## Commit + present a real pack ceremony on the app ModalStack, tap to open, wait for the cards.
func _open_pack(kind: String, tx: String) -> Dictionary:
	var a = _root.get_app_state()
	var before: Dictionary = a.economy.snapshot()
	var r: Dictionary = a.commit_pack(kind, tx)
	var mk: Dictionary = PremiumPackCeremony.create_premium(r["model"]) if kind == "premium" else StandardPackCeremony.create(r["model"])
	var p = mk["popup"]
	_root.get_modal_stack().push(p)
	await _frames(1)
	var econ_before: Dictionary = a.economy.snapshot()
	p.tap()
	for _i in range(400):
		if p.phase() != "OPENING":
			break
		await process_frame
	var out := {"receipt": r["receipt"], "model": r["model"], "replay": r.get("replay", false), "econ_before": econ_before, "econ_after": a.economy.snapshot(), "committed_before": before}
	_root.get_modal_stack().clear("clear")
	await _frames(1)
	return out

func _top():
	return _root.get_modal_stack().top()

func _moments(mf) -> Array:
	return mf.played.map(func(p): return p[0])

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
