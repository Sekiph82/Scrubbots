extends SceneTree
## M54 regression pack SB-M54-022..027: the cases the existing suites did not assert
## (coverage map: factory/jobs/119-regressions-results-spend-shop/build.md).
##   022 Need a Hand offers only boosters the owner unlock table has unlocked; fails closed below two.
##   023 2x level / timed purchases stay idempotent across a relaunch.
##   024 rewarded callback ordering on one token (close-before-reward, reward-before-close,
##       repeats), interleaved tokens, unknown tokens, a request still pending at relaunch.
##   027 robot unlock rapid taps / re-unlock / locked equip / re-equip, persisted across relaunch.
## Real app root (main.tscn) on throw-away saves; mocked rewarded provider (tests/support).
##
## Run: godot --headless --path . -s res://tests/m54_regression_pack_022_027.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000
const LEVEL := 2
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
const OK := {"outcome": "completed", "verified": true}

var EXPECTED_CASES := [
	"m022_nah_only_unlocked_pair", "m022_nah_one_unlocked_fail_closed", "m022_nah_real_table_l2_none",
	"m023_2x_relaunch_idempotent",
	"m024_close_then_reward", "m024_reward_then_close", "m024_interleaved_tokens", "m024_unknown_token",
	"m024_pending_at_relaunch",
	"m027_robot_rapid_unlock_once", "m027_robot_idempotent_calls", "m027_robot_relaunch_persist",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _host
var _prov

func _initialize() -> void:
	AppState.test_unlock_all = true
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _m022()
	_m023()
	_m024()
	await _m027()
	_shutdown()
	AppState.test_unlock_all = false
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ 022 ----

func _m022() -> void:
	print("[022 Need a Hand offers only unlocked boosters]")
	await _boot_play()
	var legal: Array = BOOSTERS.filter(func(id): return bool(_host.next_start_legality()[id]))
	_ok(legal.size() >= 2, "all unlocked: next-start legal boosters %s" % str(legal))
	var keep: Array = legal.slice(legal.size() - 2)   # the two the ranking would NOT pick first
	_lock_all_but(keep)
	var leg: Dictionary = _host.next_start_legality()
	_ok(BOOSTERS.all(func(id): return bool(leg[id]) == keep.has(id)), "locked boosters prove false on the next start %s" % str(leg))
	await _fail_times(3)
	var nah = _nah()
	var picks: Array = (_host.get_assistance_offer()["picks"] as Array).map(func(p): return p["id"])
	picks.sort()
	keep.sort()
	_ok(nah != null and picks == keep and (nah.context["boosters"] as Array).all(func(id): return keep.has(id)), "third failure: the pair is exactly the unlocked %s (got %s)" % [str(keep), str(picks)])
	_complete("m022_nah_only_unlocked_pair")

	await _boot_play()
	_lock_all_but([legal[0]])
	await _fail_times(3)
	var offer: Dictionary = _host.get_assistance_offer()
	_ok(offer["due"] and not offer["show"] and offer["reason"] == "insufficient_meaningful" and _nah() == null, "one unlocked booster: due but fail-closed, no Need a Hand")
	_ok(_res().visible and await _retry(), "Fail / Retry stay usable")
	_complete("m022_nah_one_unlocked_fail_closed")

	await _boot_play()
	_root.get_app_state().unlocks.load_config()   # the shipped owner table at frontier L2: all four locked
	_ok(BOOSTERS.all(func(id): return not _root.get_app_state().feature_unlocked(id)), "shipped table: no booster unlocked at L2")
	var sb0: int = _eco().wallet.scrub_bucks()
	await _fail_times(3)
	offer = _host.get_assistance_offer()
	_ok(offer["due"] and not offer["show"] and _nah() == null and _stack().depth() == 0 and _eco().wallet.scrub_bucks() == sb0, "real L2 third failure: no Need a Hand, nothing offered or spent")
	_complete("m022_nah_real_table_l2_none")

# ------------------------------------------------------------------ 023 ----

func _m023() -> void:
	print("[023 2x purchases idempotent across relaunch]")
	var path := _path("m023")
	var a := AppState.new(path, func(): return _now[0])
	a.economy.wallet.credit("scrub_bucks", 5000)
	var r1: Dictionary = a.actions.buy_current_level_2x(5)
	var r2: Dictionary = a.actions.buy_timed_2x(900)
	var sb1: int = a.economy.wallet.scrub_bucks()
	a.economy.dispose()
	var b := AppState.new(path, func(): return _now[0])
	_ok(bool(r1["ok"]) and bool(r2["ok"]) and b.economy.wallet.scrub_bucks() == sb1 and b.economy.speed.is_level_entitled(5) and b.economy.speed.timed_seconds_remaining() == 900,
		"relaunch: level-5 2x + 900 s timed persisted, SB %d" % sb1)
	var again: Dictionary = b.actions.buy_current_level_2x(5)
	_ok(again["reason"] == "already_entitled" and b.economy.wallet.scrub_bucks() == sb1, "relaunched re-buy of the same level 2x refused, nothing debited")
	_ok(b.economy.speed.is_manual_2x_entitled(5) and b.economy.wallet.scrub_bucks() == sb1, "entitlement read after relaunch spends nothing")
	b.economy.dispose()
	_complete("m023_2x_relaunch_idempotent")

# ------------------------------------------------------------------ 024 ----

func _m024() -> void:
	print("[024 rewarded callback ordering, provider mocked]")
	var path := _path("m024")
	var a = _app(path)
	var e = a.economy
	e.hearts.import_snapshot({"hearts": 2, "anchor": _now[0]})
	var t: String = a.actions.start_rewarded("heart")["token"]
	_ok(e.rewarded.resolve(t, {"outcome": "cancelled"})["reason"] == "cancelled" and e.hearts.hearts() == 2, "closed without reward: 0")
	var late: Dictionary = e.rewarded.resolve(t, OK)
	_ok(late["reason"] == "duplicate" and e.hearts.hearts() == 2 and not e.reward.already_applied("rewarded:" + t), "reward arriving after close: refused, 0")
	_complete("m024_close_then_reward")

	var n0: int = e.reward.applied_transaction_count()
	t = a.actions.start_rewarded("heart")["token"]
	_ok(bool(e.rewarded.resolve(t, OK)["ok"]) and e.hearts.hearts() == 3, "reward earned: +1 Heart")
	var close: Dictionary = e.rewarded.resolve(t, {"outcome": "cancelled"})
	for _i in range(3):
		e.rewarded.resolve(t, OK)
	_ok(close["reason"] == "duplicate" and e.hearts.hearts() == 3 and e.reward.applied_transaction_count() == n0 + 1, "close after reward + 3 repeats: kept, never revoked, one tx")
	_complete("m024_reward_then_close")

	var th: String = a.actions.start_rewarded("heart")["token"]
	var tb: String = a.actions.start_rewarded(RewardedGrantService.booster_product("random"))["token"]
	var c0: int = e.boosters.charges("random")
	e.rewarded.resolve(tb, OK)
	e.rewarded.resolve(th, OK)
	e.rewarded.resolve(tb, OK)
	_ok(th != tb and e.hearts.hearts() == 4 and e.boosters.charges("random") == c0 + 1 and e.rewarded.pending_count() == 0, "two pending tokens resolved out of order: each grants its own product once")
	_complete("m024_interleaved_tokens")

	var snap: Dictionary = e.snapshot()
	var u: Dictionary = e.rewarded.resolve("never-issued", OK)
	_ok(u["reason"] == "unknown_token" and JSON.stringify(e.snapshot()) == JSON.stringify(snap), "unknown token: unknown_token, economy unchanged")
	_complete("m024_unknown_token")

	var tp: String = a.actions.start_rewarded("heart")["token"]
	a.request_save()
	e.dispose()
	var b = _app(path)
	var h: int = b.economy.hearts.hearts()
	var stale: Dictionary = b.economy.rewarded.resolve(tp, OK)
	_ok(h == 4 and b.economy.rewarded.pending_count() == 0 and stale["reason"] == "unknown_token" and b.economy.hearts.hearts() == h,
		"request pending at relaunch: dropped, its late callback grants nothing")
	_ok(b.economy.rewarded.start("heart", th)["reason"] == "duplicate_token", "a committed token cannot be restarted after relaunch")
	b.economy.dispose()
	_complete("m024_pending_at_relaunch")

# ------------------------------------------------------------------ 027 ----

func _m027() -> void:
	print("[027 robot unlock / equip idempotency + persistence]")
	await _boot_home()
	var e = _eco()
	var actions = _root.get_app_state().actions
	e.wallet.credit(EconomyWallet.BOT_PARTS, 600)
	var p = RobotsScreen.open(_stack(), _root.get_app_state(), _root.ceremonies)
	await _settle()
	for _i in range(5):
		p._on_action("robot:moppy")
	await _settle()
	_ok(e.robots.is_unlocked("moppy") and not e.robots.is_unlocked("bubbles") and e.wallet.bot_parts() == 350, "5 UNLOCK taps in one frame: Moppy only, exactly 250 parts")
	_complete("m027_robot_rapid_unlock_once")

	var re: Dictionary = actions.unlock_robot("moppy")
	var lk: Dictionary = actions.equip_robot("bubbles")
	var eq1: Dictionary = actions.equip_robot("moppy")
	var eq2: Dictionary = actions.equip_robot("moppy")
	_ok(re["reason"] == "already_unlocked" and e.wallet.bot_parts() == 350, "re-unlock: already_unlocked, nothing spent")
	_ok(lk["reason"] == "locked" and eq1["reason"] == "equipped" and eq2["reason"] == "already_active" and e.robots.active_robot() == "moppy" and e.wallet.bot_parts() == 350,
		"locked equip refused; equip twice = equipped then already_active; no parts spent")
	_complete("m027_robot_idempotent_calls")

	var path: String = MainScript.boot_save_path_override
	_shutdown()
	await _boot_home(path)
	e = _eco()
	_ok(e.robots.is_unlocked("moppy") and e.robots.active_robot() == "moppy" and e.wallet.bot_parts() == 350, "relaunch: Moppy unlocked + active, 350 parts")
	_ok(_root.get_app_state().actions.unlock_robot("moppy")["reason"] == "already_unlocked" and e.wallet.bot_parts() == 350, "relaunched re-unlock spends nothing")
	p = RobotsScreen.open(_stack(), _root.get_app_state(), _root.ceremonies)
	await _settle()
	var row = p.find_child("Robot_moppy", true, false)
	var m: Dictionary = RobotRoster.entry("moppy")
	_ok(row != null and row.find_child("State", true, false).get_node("Text").text == UiText.t("ROBOTS_ACTIVE")
		and (row.find_child("Perk", true, false) as Label).text == "%s: %s" % [m["perk_name"], m["perk_text"]]
		and _root.get_home().get_region("ProfileName").text == "Moppy", "relaunched roster: Moppy ACTIVE with its perk; Home shows Moppy")
	_complete("m027_robot_relaunch_persist")

# ------------------------------------------------------------------ fixtures ----

func _path(tag: String) -> String:
	var p := "user://m54_022_027_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _app(path: String):
	var a := AppState.new(path, func(): return _now[0])
	_prov = ProviderDouble.new()
	a.economy.rewarded.set_provider(_prov)
	return a

func _boot_home(path: String = "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path if not path.is_empty() else _path("app")
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _settle()

func _boot_play() -> void:
	await _boot_home()
	_prov = ProviderDouble.new()
	_eco().rewarded.set_provider(_prov)
	_root.get_app_state().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": LEVEL, "completed": range(1, LEVEL)})
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	_eco().wallet.credit("scrub_bucks", 5000)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _lock_all_but(keep: Array) -> void:
	var u: Dictionary = _root.get_app_state().unlocks.cfg["unlocks"]
	for id in BOOSTERS:
		u[id] = 1 if keep.has(id) else 99

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _eco():
	return _root.get_app_state().economy

func _stack():
	return _root.get_modal_stack()

func _res():
	return _root.get_results_screen()

func _nah():
	return _root.get_acquisition().find_open("need_a_hand")

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _lose() -> void:
	_host.get_completion().terminal_reached.emit(&"LOST", {})
	await _settle()

func _retry() -> bool:
	_stack().clear("t")
	await _settle()
	if _eco().hearts.hearts() == 0:
		_eco().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	var ok: bool = _root.retry_from_results()
	await _settle()
	return ok

func _fail_times(n: int) -> void:
	for i in range(n):
		if _root.get_navigation().current() == R.RESULTS:
			await _retry()
		await _lose()

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
	print("M54 regression pack 022-027: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
