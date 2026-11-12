extends SceneTree
## SB-M57-001..011 (provider-independent part, owner 2026-10-22) — AdService over the AdProvider
## seam with a MockProvider (no SDK, no network): the shipping null provider shows nothing; an
## interstitial is due on every 5th finished play (win or loss) and is shown only at the real
## app's next attempt start (Home PLAY after a win, Results Retry after a loss), never mid-level; No Ads removes the banner and
## interstitials but not rewarded; a rewarded video grants only on a verified completed view
## (through RewardedGrantService), never on cancel / skip / fail; the play counter is saved.
##
## Run: godot --headless --path . -s res://tests/m57_ads_cadence.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const StoreService = preload("res://scripts/economy/store_service.gd")

var EXPECTED_CASES := [
	"a01_null_provider", "a02_every_fifth_play", "a03_app_win_lose_between_levels",
	"a04_no_ads_banner_interstitial_only", "a05_rewarded_completion_only", "a06_counter_persisted",
]

## Test double: records banner / interstitial calls; rewarded requests resolve via finish().
class MockProvider extends AdProvider:
	var fill := true
	var banner: Array = []
	var interstitials: Array = []
	var requests: Array = []
	var _deliver: Callable
	func set_banner(visible: bool) -> void:
		banner.append(visible)
	func show_interstitial(placement: String) -> bool:
		if fill:
			interstitials.append(placement)
		return fill
	func is_available(_placement: String) -> bool:
		return true
	func request(placement: String, token: String, deliver: Callable) -> bool:
		requests.append([placement, token])
		_deliver = deliver
		return true
	func finish(outcome: String, verified: bool = true) -> Dictionary:
		return _deliver.call(requests[-1][1], {"outcome": outcome, "verified": verified})

## A store whose ads_allowed() denies every kind: proves AdService asks it for each decision.
class DenyStore:
	func ads_allowed(_kind: String) -> bool:
		return false

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	AppState.test_unlock_all = true
	MainScript.boot_opening_override = 0
	await process_frame
	_a01()
	_a02()
	await _a03()
	_a04()
	_a05()
	await _a06()
	_shutdown()
	MainScript.boot_opening_override = -1
	AppState.test_unlock_all = false
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _a01() -> void:
	print("[a01 shipping null provider: nothing shown, shared with rewarded]")
	var e := EconomyServices.new()
	var ads = e.ads
	_ok(ads.get_provider().get_script() == AdProvider and e.rewarded.get_provider() == ads.get_provider(), "default = null AdProvider, the same object RewardedGrantService uses")
	for _i in range(5):
		ads.on_play_finished()
	_ok(ads.interstitial_due() and not ads.try_interstitial() and ads.interstitial_due(), "5 plays: due, null provider shows nothing, stays due")
	_ok(not e.rewarded.is_available("heart") and not e.rewarded.is_available("booster:tornado"), "no rewarded video offered")
	_complete("a01_null_provider")

func _a02() -> void:
	print("[a02 interstitial every 5th play]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var shown: Array = []
	for play in range(1, 16):
		e.ads.on_play_finished()
		if e.ads.try_interstitial():
			shown.append(play)
	_ok(shown == [5, 10, 15] and m.interstitials.size() == 3, "plays 1-4 none, 5 / 10 / 15 shown %s" % str(shown))
	_ok(m.interstitials[0] == "interstitial_between_levels" and not e.ads.try_interstitial(), "between-levels placement; a second try after a shown ad is refused")
	m.fill = false
	for _i in range(5):
		e.ads.on_play_finished()
	_ok(not e.ads.try_interstitial() and e.ads.interstitial_due(), "no fill: not shown, still due")
	m.fill = true
	e.ads.on_play_finished()
	_ok(e.ads.try_interstitial() and not e.ads.interstitial_due(), "next transition shows it, cadence restarts")
	_complete("a02_every_fifth_play")

func _a03() -> void:
	print("[a03 real app: win and lose each count; the ad only at the next attempt start]")
	await _boot(_tmp_path("a03"), 2)
	var m := MockProvider.new()
	_eco().ads.set_provider(m)
	await _start(_root.play_current_frontier().get("ok", false))
	var plan := [&"LOST", &"WON", &"LOST", &"WON", &"LOST"]
	var mid_level_shown := 0
	for i in range(plan.size()):
		mid_level_shown += m.interstitials.size()
		await _terminal(plan[i])
		_ok(_eco().ads.plays() == i + 1, "%s -> plays %d" % [plan[i], i + 1])
		if i < plan.size() - 1:
			_ok(m.interstitials.is_empty(), "after play %d: no interstitial" % (i + 1))
			_eco().hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})
			_root.get_modal_stack().clear("t")
			await _settle()
			await _start(_home_play() if plan[i] == &"WON" else _root.retry_from_results())
	_ok(mid_level_shown == 0 and m.interstitials.is_empty(), "5th play finished: nothing shown during gameplay or at the terminal")
	_eco().hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})
	_root.get_modal_stack().clear("t")
	await _settle()
	await _start(_root.retry_from_results())
	_ok(m.interstitials.size() == 1, "Results -> Retry after play 5: one interstitial")
	await _terminal(&"WON")
	_root.get_modal_stack().clear("t")
	await _settle()
	await _start(_home_play())
	_ok(m.interstitials.size() == 1 and _eco().ads.plays() == 6, "play 6 -> Home -> PLAY: no second interstitial")
	var c0: int = _eco().boosters.charges("tornado")
	_ok(_app().actions.start_rewarded("booster:tornado")["ok"], "app facade starts a rewarded video through the shared provider")
	m.finish("cancelled")
	_ok(_eco().boosters.charges("tornado") == c0, "cancelled -> no charge")
	_app().actions.start_rewarded("booster:tornado")
	_ok(m.finish("completed")["ok"] and _eco().boosters.charges("tornado") == c0 + 1, "completed -> +1 charge (RewardedGrantService)")
	var store = _eco().ads._store
	_eco().ads._store = DenyStore.new()
	_ok(_app().actions.start_rewarded("booster:tornado")["reason"] == "ads_disallowed" and _app().actions.start_rewarded_daily(2)["reason"] == "ads_disallowed", "facade rewarded starts ask ads_allowed(rewarded)")
	_eco().ads._store = store
	_complete("a03_app_win_lose_between_levels")

func _a04() -> void:
	print("[a04 No Ads: banner + interstitial off, rewarded stays]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	_ok(m.banner == [true], "banner shown without No Ads")
	_ok(e.reward.grant("store:tokN", {StoreService.RES_NO_ADS: 1}) and e.store.no_ads(), "No Ads entitlement granted (store path)")
	e.ads.update_banner()
	_ok(m.banner[-1] == false, "banner hidden")
	for _i in range(10):
		e.ads.on_play_finished()
	_ok(not e.ads.interstitial_due() and not e.ads.try_interstitial() and m.interstitials.is_empty(), "10 plays: no interstitial")
	_ok(e.ads.allowed("rewarded") and e.rewarded.start("booster:tornado")["ok"] and m.requests.size() == 1, "rewarded still offered and started")
	var c0: int = e.boosters.charges("tornado")
	_ok(m.finish("completed")["ok"] and e.boosters.charges("tornado") == c0 + 1, "completed rewarded view still grants with No Ads")
	_complete("a04_no_ads_banner_interstitial_only")

func _a05() -> void:
	print("[a05 rewarded grants only on a verified completed view]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var c0: int = e.boosters.charges("selector")
	var n0: int = e.reward.applied_transaction_count()
	for outcome in ["cancelled", "skipped", "failed", "timeout"]:
		e.rewarded.start("booster:selector")
		var r: Dictionary = m.finish(outcome)
		_ok(not r["ok"] and r["reason"] == outcome, "%s -> nothing" % outcome)
	e.rewarded.start("booster:selector")
	_ok(not m.finish("completed", false)["ok"], "completed but unverified -> nothing")
	_ok(e.boosters.charges("selector") == c0 and e.reward.applied_transaction_count() == n0, "no charge, no ledger entry")
	e.rewarded.start("booster:selector")
	var ok: Dictionary = m.finish("completed")
	_ok(ok["ok"] and e.boosters.charges("selector") == c0 + 1 and e.reward.already_applied("rewarded:" + String(ok["token"])), "verified completion -> +1 charge under rewarded:<token>")
	_ok(not m.finish("completed")["ok"] and e.boosters.charges("selector") == c0 + 1, "duplicate completion callback grants nothing")
	e.ads._store = DenyStore.new()
	e.ads.on_play_finished()
	_ok(not e.ads.allowed("rewarded") and not e.ads.interstitial_due() and not e.ads.try_interstitial(), "every decision asks the store seam (a store that denies all -> nothing)")
	_complete("a05_rewarded_completion_only")

func _a06() -> void:
	print("[a06 play counter persisted]")
	var e := EconomyServices.new()
	e.ads.set_provider(MockProvider.new())
	for _i in range(7):
		e.ads.on_play_finished()
	e.ads.try_interstitial()
	var snap: Dictionary = e.snapshot()
	_ok(snap["ads"] == {"plays": 7, "last_interstitial": 7}, "economy snapshot section ads %s" % str(snap["ads"]))
	var e2 := EconomyServices.new()
	_ok(e2.import_snapshot(JSON.parse_string(JSON.stringify(snap))) and e2.ads.plays() == 7 and not e2.ads.interstitial_due(), "JSON round trip keeps plays + last shown")
	var old: Dictionary = snap.duplicate(true)
	old.erase("ads")
	var e3 := EconomyServices.new()
	_ok(e3.import_snapshot(old) and e3.ads.plays() == 0, "a pre-ads save (no section) imports with 0 plays")
	for bad in [{"plays": -1, "last_interstitial": 0}, {"plays": 2, "last_interstitial": 3}, {"plays": 1.5, "last_interstitial": 0}, {"plays": 3}]:
		var s: Dictionary = snap.duplicate(true)
		s["ads"] = bad
		_ok(not e2.import_snapshot(s) and e2.ads.plays() == 7, "malformed %s fails closed (state unchanged)" % str(bad))
	var path := _tmp_path("a06")
	await _boot(path, 2)
	await _start(_root.play_current_frontier().get("ok", false))
	await _terminal(&"LOST")
	_ok(_eco().ads.plays() == 1, "real LOST -> 1 play")
	await _boot(path, -1)
	_ok(_eco().ads.plays() == 1, "reboot on the save: still 1 play (terminal save holds it)")
	_complete("a06_counter_persisted")

# ------------------------------------------------------------------ helpers ----

func _tmp_path(tag: String) -> String:
	var path := "user://m57_ads_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	if level > 0:
		_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": level, "completed": range(1, level)})
		_eco().hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})

## A level just started (`ok`): bind its host, pause the runtime.
func _start(ok: bool) -> void:
	_ok(ok, "level %d started" % _app().progression.current_level())
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _terminal(status: StringName) -> void:
	_host.get_completion().terminal_reached.emit(status, {})
	await _settle()

func _app():
	return _root.get_app_state()

func _eco():
	return _app().economy

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
	print("M57 ads cadence evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)

## SB-PHONE-2026-11-12-B: a win goes Home (the WON primary), then Home PLAY starts the next level.
func _home_play() -> bool:
	_root.get_results_screen().get_primary_button().pressed.emit()
	return _root.play_current_frontier().get("ok", false)
