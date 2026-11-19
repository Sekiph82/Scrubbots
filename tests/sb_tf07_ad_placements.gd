extends SceneTree
## SB-TF-07 (owner 2026-11-18) new ad placements, on a real EconomyServices / AppState / main.tscn
## with an injected mock AdProvider, a fake local day and a fake clock (no SDK, no network):
##   - data/config/ad_placements_v1.json (policy_version 2) drives the cadence; a missing / corrupt
##     file turns interstitial + App Open off only;
##   - interstitial: never before level 10, then every 4 finished plays;
##   - App Open: frontier >= 20, never on the install day, once per local day, only a shown ad
##     consumes the day, after the opening video's Home entry (never during it);
##   - event ad: +1 progress on a joined active event (not quest / colors) once per event per
##     local day, only on a verified completed view, saved before `resolved`, rollback-safe;
##   - No Ads removes App Open + interstitial, rewarded stays; snapshots stay strict and old
##     saves import; ad_placement / ad_request / ad_result analytics only with consent.
##
## Run: godot --headless --path . -s res://tests/sb_tf07_ad_placements.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const LaunchSession = preload("res://scripts/app/launch_session.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const AdService = preload("res://scripts/economy/ad_service.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const ProductionActionFacade = preload("res://scripts/economy/production_action_facade.gd")
const AnalyticsService = preload("res://scripts/app/analytics_service.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const D0 := 20000
const EVENT_PLACEMENT := "rewarded_event_progress"

var EXPECTED_CASES := [
	"c01_config", "c02_interstitial_gate", "c03_interstitial_cadence", "c04_app_open_day_gates",
	"c05_app_open_consumption", "c06_no_ads", "c07_snapshot", "c08_event_ad_happy_path",
	"c09_event_ad_non_grants", "c10_event_ad_refusals", "c11_save_relaunch", "c12_main_flow",
	"c13_events_ui", "c14_analytics",
]

## Records every provider call; App Open records the app route at the call (main = the app root).
class MockProvider extends AdProvider:
	var fill := true
	var available := true
	var log: Array = []
	var requests: Array = []
	var main = null
	var _deliver: Callable
	func set_banner(visible: bool) -> void:
		log.append(["banner", visible])
	func show_interstitial(placement: String) -> bool:
		log.append(["interstitial", placement])
		return fill
	func show_app_open(placement: String) -> bool:
		log.append(["app_open", placement, main.nav.current() if main != null and main.nav != null else -1])
		return fill
	func is_available(_placement: String) -> bool:
		return available
	func request(placement: String, token: String, deliver: Callable) -> bool:
		requests.append([placement, token])
		_deliver = deliver
		return true
	func finish(outcome: String, verified: bool = true) -> Dictionary:
		return _deliver.call(requests[-1][1], {"outcome": outcome, "verified": verified})
	func count(kind: String) -> int:
		return log.filter(func(e): return e[0] == kind).size()

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [0]
var _day := [D0]
var _rt: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_rt = JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))
	_now[0] = int(_rt["schedule"]["epoch_utc"]) + 3600
	_c01()
	_c02()
	_c03()
	_c04()
	_c05()
	_c06()
	_c07()
	_c08()
	_c09()
	_c10()
	_c11()
	await _c12()
	await _c13()
	_c14()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _c01() -> void:
	print("[c01 ad_placements_v1.json: policy 2 values; missing / corrupt -> interstitial + App Open off only]")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AdService.PATH))
	_ok(d["schema"] == "scrubbots.ad_placements.v1" and int(d["policy_version"]) == 2 and String(d["supersedes"]).contains("every 5"), "schema, policy_version 2, supersedes version 1 (every 5 plays)")
	_ok([int(d["interstitial"]["min_level"]), int(d["interstitial"]["interval_plays"]), int(d["app_open"]["min_level"]), int(d["app_open"]["max_per_day"]), int(d["event_progress_ad"]["per_event_per_day"]), int(d["event_progress_ad"]["progress"])] == [10, 4, 20, 1, 1, 1]
		and d["app_open"]["skip_install_day"] == true, "values 10 / 4 / 20 / 1 / 1 / 1, skip_install_day")
	var e := _eco()
	_ok(e.ads.config_ok(), "the shipped file is valid")
	var src := FileAccess.get_file_as_string("res://scripts/economy/ad_service.gd")
	_ok(not src.contains("INTERVAL") and not src.contains(":= 5") and not src.contains(":= 4") and not src.contains(":= 10") and not src.contains(":= 20"), "no hard-coded cadence / level constants left in AdService")
	var bad := "user://sb_tf07_bad_%d.json" % Time.get_ticks_usec()
	_tmp.append(bad)
	var f := FileAccess.open(bad, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var wrong := "user://sb_tf07_v1_%d.json" % Time.get_ticks_usec()
	_tmp.append(wrong)
	var w := FileAccess.open(wrong, FileAccess.WRITE)
	d["policy_version"] = 1
	w.store_string(JSON.stringify(d))
	w.close()
	for path in ["res://data/config/__missing_ad_placements.json", bad, wrong]:
		var x := _eco()
		var m := MockProvider.new()
		x.ads.set_provider(m)
		x.ads.load_config(path)
		x.ads.bind_level(func(): return 30)
		x.ads.note_launch()
		_day[0] = D0 + 1
		for _i in range(12):
			x.ads.on_play_finished(12)
		_ok(not x.ads.config_ok() and not x.ads.interstitial_due() and not x.ads.try_interstitial() and not x.ads.try_app_open() and m.count("interstitial") == 0 and m.count("app_open") == 0,
			"%s: interstitial + App Open off, provider never asked" % path.get_file())
		x.ads.update_banner()
		_ok(m.log[-1] == ["banner", true] and x.rewarded.start("booster:tornado")["ok"] and m.requests.size() == 1, "%s: banner + rewarded unaffected" % path.get_file())
		_day[0] = D0
	_complete("c01_config")

func _c02() -> void:
	print("[c02 interstitial: never before level 10; plays still counted]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var due := false
	for lv in [1, 2, 3, 4, 5, 6, 7, 8, 9, 9]:
		e.ads.on_play_finished(lv)
		due = due or e.ads.interstitial_due() or e.ads.try_interstitial()
	_ok(not due and m.count("interstitial") == 0 and e.ads.plays() == 10, "10 plays at levels 1..9: never due, plays() == 10")
	for _i in range(3):
		e.ads.on_play_finished(10)
	_ok(not e.ads.interstitial_due(), "plays below 10 never bank toward the first ad (3 at level 10: not due)")
	_complete("c02_interstitial_gate")

func _c03() -> void:
	print("[c03 interstitial: every 4 finished plays from level 10]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var shown: Array = []
	for play in range(1, 13):
		e.ads.on_play_finished(10 + play)
		if e.ads.try_interstitial():
			shown.append(play)
	_ok(shown == [4, 8, 12] and m.count("interstitial") == 3, "shown at plays %s" % str(shown))
	m.fill = false
	for _i in range(4):
		e.ads.on_play_finished(30)
	_ok(not e.ads.try_interstitial() and e.ads.interstitial_due(), "no fill: not shown, stays due")
	m.fill = true
	_ok(e.ads.try_interstitial() and not e.ads.interstitial_due(), "shown at the next transition")
	for _i in range(3):
		e.ads.on_play_finished(30)
	_ok(not e.ads.interstitial_due(), "cadence restarts after a shown ad (3 plays: not due)")
	_complete("c03_interstitial_cadence")

func _c04() -> void:
	print("[c04 App Open day gates: install day, once per day, clock back, level 20]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var lvl := [20]
	e.ads.bind_level(func(): return lvl[0])
	_day[0] = D0
	_ok(e.ads.note_launch() and e.ads.first_day() == D0 and not e.ads.note_launch() and e.ads.first_day() == D0, "first launch records install day D0 once")
	_ok(not e.ads.try_app_open() and m.count("app_open") == 0, "D0 (install day), level 20: not shown, provider not asked")
	_day[0] = D0 + 1
	_ok(e.ads.try_app_open() and m.log[-1][1] == "app_open_launch", "D0+1: shown (placement app_open_launch)")
	_ok(not e.ads.try_app_open() and m.count("app_open") == 1, "second try the same day: refused")
	_day[0] = D0 + 2
	_ok(e.ads.try_app_open() and m.count("app_open") == 2, "D0+2: shown again")
	_day[0] = D0 + 1
	_ok(not e.ads.try_app_open() and m.count("app_open") == 2, "clock moved back to D0+1: refused")
	_day[0] = D0 + 5
	lvl[0] = 19
	_ok(not e.ads.try_app_open() and m.count("app_open") == 2, "D0+5 at level 19: refused")
	lvl[0] = 20
	_ok(e.ads.try_app_open() and m.count("app_open") == 3, "D0+5 at level 20: shown")
	_day[0] = D0
	_complete("c04_app_open_day_gates")

func _c05() -> void:
	print("[c05 App Open: no fill keeps the day, shown writes it]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	e.ads.bind_level(func(): return 25)
	_day[0] = D0
	e.ads.note_launch()
	_day[0] = D0 + 3
	m.fill = false
	_ok(not e.ads.try_app_open() and m.count("app_open") == 1 and e.ads.app_open_day() == -1, "no fill: asked once, app_open_day not written")
	m.fill = true
	_ok(e.ads.try_app_open() and e.ads.app_open_day() == D0 + 3 and e.snapshot()["ads"]["app_open_day"] == D0 + 3, "same day, filled: shown, day written into the saved ads section")
	_day[0] = D0
	_complete("c05_app_open_consumption")

func _c06() -> void:
	print("[c06 No Ads: no App Open, no interstitial; rewarded (event ad + products) stays]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	e.ads.bind_level(func(): return 40)
	_day[0] = D0
	e.ads.note_launch()
	_ok(e.reward.grant("store:tok_noads", {"store_no_ads": 1}) and e.store.no_ads(), "No Ads bought")
	e.ads.update_banner()
	_ok(m.log[-1] == ["banner", false], "banner hidden by update_banner()")
	_day[0] = D0 + 1
	for _i in range(8):
		e.ads.on_play_finished(15)
	_ok(not e.ads.try_app_open() and not e.ads.try_interstitial() and m.count("app_open") == 0 and m.count("interstitial") == 0, "neither App Open nor interstitial asks the provider")
	var iid: String = _join(e, ["race"])["race"]
	_ok(e.rewarded.start_event_ad(iid, _day[0])["ok"] and m.requests[-1][0] == EVENT_PLACEMENT and m.finish("completed")["ok"], "event ad still starts and grants")
	_ok(e.rewarded.start("booster:tornado")["ok"] and m.finish("completed")["ok"], "rewarded booster still starts and grants")
	_day[0] = D0
	_complete("c06_no_ads")

func _c07() -> void:
	print("[c07 ads snapshot: round trip, old saves, strict new fields]")
	var e := _eco()
	e.ads.set_provider(MockProvider.new())
	e.ads.bind_level(func(): return 20)
	_day[0] = D0
	e.ads.note_launch()
	_day[0] = D0 + 1
	e.ads.try_app_open()
	for _i in range(6):
		e.ads.on_play_finished(11)
	e.ads.try_interstitial()
	var snap: Dictionary = JSON.parse_string(JSON.stringify(e.snapshot()))
	var e2 := _eco()
	_ok(e2.import_snapshot(snap) and e2.ads.snapshot() == {"plays": 6, "last_interstitial": 6, "first_day": D0, "app_open_day": D0 + 1}, "JSON round trip keeps plays, last_interstitial, first_day, app_open_day: %s" % str(e2.ads.snapshot()))
	var old: Dictionary = snap.duplicate(true)
	old["ads"] = {"plays": 3, "last_interstitial": 2}
	var e3 := _eco()
	_ok(e3.import_snapshot(old) and e3.ads.plays() == 3 and e3.ads.first_day() == -1 and e3.ads.app_open_day() == -1, "old {plays, last_interstitial} imports, new fields -1")
	for field in ["first_day", "app_open_day"]:
		for v in [-2, "3", 1.5]:
			var s: Dictionary = snap.duplicate(true)
			s["ads"][field] = v
			_ok(not e2.import_snapshot(s) and e2.ads.first_day() == D0 and e2.ads.app_open_day() == D0 + 1, "%s = %s rejected (state unchanged)" % [field, str(v)])
	_day[0] = D0
	_complete("c07_snapshot")

func _c08() -> void:
	print("[c08 event ad: verified view -> +1 once per event per day, saved before resolved]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var order: Array = []
	e.rewarded.bind_save(func():
		order.append("save")
		return {"ok": true})
	e.rewarded.resolved.connect(func(_t, _p, _r): order.append("resolved"))
	var ids := _join(e, ["race", "other"])
	var iid: String = ids["race"]
	var ev = e.events_v02
	var p0: int = ev.view(iid)["progress"]
	var r: Dictionary = e.rewarded.start_event_ad(iid, D0, "tok_ev1")
	_ok(r["ok"] and m.requests[-1] == [EVENT_PLACEMENT, "tok_ev1"], "start -> provider request on rewarded_event_progress")
	var res: Dictionary = m.finish("completed")
	_ok(res["ok"] and ev.view(iid)["progress"] == p0 + 1 and e.reward.already_applied("event_ad:%s:%d" % [iid, D0]), "completed + verified -> race progress +1 under event_ad:<iid>:<day>")
	_ok(order == ["save", "resolved"], "save callback before resolved %s" % str(order))
	_ok(not e.rewarded.resolve("tok_ev1", {"outcome": "completed", "verified": true})["ok"] and ev.view(iid)["progress"] == p0 + 1, "duplicate resolve grants nothing")
	var n := m.requests.size()
	_ok(e.rewarded.start_event_ad(iid, D0)["reason"] == "already_claimed" and m.requests.size() == n and ev.view(iid)["progress"] == p0 + 1, "second start the same day: already_claimed, provider not asked")
	_ok(e.rewarded.start_event_ad(iid, D0 + 1)["ok"] and m.finish("completed")["ok"] and ev.view(iid)["progress"] == p0 + 2, "next day: works again (+1)")
	var other: String = ids["other"]
	var o0: int = ev.view(other)["progress"]
	_ok(e.rewarded.start_event_ad(other, D0 + 1)["ok"] and m.finish("completed")["ok"] and ev.view(other)["progress"] == o0 + 1, "a different event the same day: independent (+1 on %s)" % other)
	_complete("c08_event_ad_happy_path")

func _c09() -> void:
	print("[c09 event ad non-grants: cancel / skip / failed / timeout / unverified / unknown token]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var iid: String = _join(e, ["race"])["race"]
	var ev = e.events_v02
	var p0: int = ev.view(iid)["progress"]
	var n0: int = e.reward.applied_transaction_count()
	for outcome in ["cancelled", "skipped", "failed"]:
		e.rewarded.start_event_ad(iid, D0)
		var r: Dictionary = m.finish(outcome)
		_ok(not r["ok"] and r["reason"] == outcome, "%s -> nothing" % outcome)
	var t: Dictionary = e.rewarded.start_event_ad(iid, D0)
	_ok(e.rewarded.abandon(t["token"])["reason"] == "timeout", "abandon (UI timeout) -> timeout, nothing")
	e.rewarded.start_event_ad(iid, D0)
	_ok(m.finish("completed", false)["reason"] == "unverified", "completed but unverified -> nothing")
	_ok(e.rewarded.resolve("tok_unknown", {"outcome": "completed", "verified": true})["reason"] == "unknown_token", "unknown token -> nothing")
	_ok(ev.view(iid)["progress"] == p0 and e.reward.applied_transaction_count() == n0, "progress and ledger unchanged")
	_ok(e.rewarded.can_start_event_ad(iid, D0)["ok"], "the day's slot is still available")
	_complete("c09_event_ad_non_grants")

func _c10() -> void:
	print("[c10 event ad refusals: provider never asked]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var ids := _join(e, ["race", "other"], ["other"])
	var ev = e.events_v02
	_ok(e.rewarded.start_event_ad(ids["other"], D0)["reason"] == "not_joined", "not joined -> not_joined")
	var later: Array = ev.scheduled(_now[0] + 1, _now[0] + 30 * 24 * 3600).filter(func(s): return int(s["start"]) > _now[0])
	_ok(not later.is_empty() and ["not_joined", "not_active"].has(e.rewarded.start_event_ad(later[0]["iid"], D0)["reason"]), "upcoming instance -> refused")
	m.available = false
	_ok(e.rewarded.start_event_ad(ids["race"], D0)["reason"] == "unavailable", "no ad available -> unavailable")
	m.available = true
	var gate := ProductionActionFacade.new(e)
	gate.feature_gate = func(_id): return false
	_ok(gate.start_event_ad(ids["race"])["reason"] == "locked" and not gate.event_ad_available(ids["race"]), "Events locked -> locked, not available")
	_ok(m.requests.is_empty(), "so far no provider request")
	for kind in ["quest", "colors"]:
		var x := _eco()
		var xm := MockProvider.new()
		x.ads.set_provider(xm)
		var k: String = _join(x, [kind])[kind]
		_ok(x.events_v02.view(k)["joined"] and x.rewarded.start_event_ad(k, D0)["reason"] == "ineligible_kind" and xm.requests.is_empty(), "joined %s event -> ineligible_kind" % kind)
	var y := _eco()
	var ym := MockProvider.new()
	y.ads.set_provider(ym)
	var r: String = _join(y, ["race"])["race"]
	var end: int = y.events_v02.view(r)["end"]
	_now[0] = end + 10
	_ok(y.rewarded.start_event_ad(r, D0)["reason"] == "not_active" and ym.requests.is_empty(), "joined but ended -> not_active")
	var z := _eco()
	var zm := MockProvider.new()
	z.ads.set_provider(zm)
	var zr: String = _join(z, ["race"])["race"]
	z.rewarded.start_event_ad(zr, D0 + 3)
	zm.finish("completed")
	var n := zm.requests.size()
	_ok(z.rewarded.event_ad_high_water_day() == D0 + 3 and z.rewarded.start_event_ad(zr, D0 + 2)["reason"] == "clock_rollback" and zm.requests.size() == n, "day below the highest used event_ad day -> clock_rollback")
	_complete("c10_event_ad_refusals")

func _c11() -> void:
	print("[c11 save / relaunch keeps the day's event ad used]")
	var e := _eco()
	var m := MockProvider.new()
	e.ads.set_provider(m)
	var iid: String = _join(e, ["race"])["race"]
	e.rewarded.start_event_ad(iid, D0)
	m.finish("completed")
	var p: int = e.events_v02.view(iid)["progress"]
	var snap: Dictionary = JSON.parse_string(JSON.stringify(e.snapshot()))
	var e2 := _eco()
	e2.ads.set_provider(MockProvider.new())
	_ok(e2.import_snapshot(snap) and e2.rewarded.can_start_event_ad(iid, D0)["reason"] == "already_claimed" and e2.events_v02.view(iid)["progress"] == p, "relaunch: already_claimed for event + day, progress %d kept" % p)
	_ok(e2.rewarded.can_start_event_ad(iid, D0 + 1)["ok"], "relaunch: next day available")
	var bad: Dictionary = snap.duplicate(true)
	bad["events_v02"]["version"] = 99
	_ok(not _eco().import_snapshot(bad), "events_v02 import still strict (bad version rejected)")
	_complete("c11_save_relaunch")

func _c12() -> void:
	print("[c12 main flow: App Open only after the opening's Home entry, once per cold launch]")
	var R := NavigationController.Route
	# Opening plays: nothing while OPENING; after completion exactly one call on HOME.
	var p1 := _save("c12a", 20, D0)
	_day[0] = D0 + 1
	var m1 := MockProvider.new()
	var root = await _boot_main(p1, 1, m1)
	var nav = root.get_navigation()
	var during: int = m1.count("app_open")
	if nav.current() == R.OPENING:
		_ok(during == 0 and root.get_opening() != null, "opening playing: show_app_open not called")
		root.get_opening().completed.emit()
		await process_frame
	_ok(nav.current() == R.HOME and m1.count("app_open") == 1 and m1.log.filter(func(x): return x[0] == "app_open")[0][2] == R.HOME, "after the opening -> HOME, then one App Open recorded on route HOME")
	root._finish_opening("completed")
	nav.go(R.HOME, {"via": "test"})
	await process_frame
	_ok(m1.count("app_open") == 1 and root.get_app_state().economy.ads.app_open_day() == D0 + 1 and root.get_app_state().is_dirty(), "exactly once per cold launch; shown day kept + save marked dirty")
	_shutdown(root)
	# Failed opening also enters Home then tries.
	var p1b := _save("c12b", 20, D0)
	_day[0] = D0 + 1
	var m1b := MockProvider.new()
	root = await _boot_main(p1b, 1, m1b)
	if root.get_navigation().current() == R.OPENING:
		_ok(m1b.count("app_open") == 0, "opening (to fail) playing: not called")
		root.get_opening().failed.emit("decode_error")
		await process_frame
	_ok(m1b.count("app_open") == 1 and m1b.log.filter(func(x): return x[0] == "app_open")[0][2] == R.HOME, "failed opening -> HOME -> one App Open")
	_shutdown(root)
	# No opening: attempted right after the boot HOME.
	var p2 := _save("c12c", 20, D0)
	_day[0] = D0 + 1
	var m2 := MockProvider.new()
	root = await _boot_main(p2, 0, m2)
	_ok(m2.count("app_open") == 1 and m2.log.filter(func(x): return x[0] == "app_open")[0][2] == R.HOME, "boot_opening_override 0: tried right after the boot HOME")
	_shutdown(root)
	# Level 19 / install day: never asked.
	var p3 := _save("c12d", 19, D0)
	_day[0] = D0 + 1
	var m3 := MockProvider.new()
	root = await _boot_main(p3, 0, m3)
	_ok(m3.count("app_open") == 0, "frontier 19: not called")
	_shutdown(root)
	var p4 := _save("c12e", 25, -1)
	_day[0] = D0 + 7
	var m4 := MockProvider.new()
	root = await _boot_main(p4, 0, m4)
	_ok(m4.count("app_open") == 0 and root.get_app_state().economy.ads.first_day() == D0 + 7, "first launch (install day recorded now): not called")
	_shutdown(root)
	_day[0] = D0
	_complete("c12_main_flow")

func _c13() -> void:
	print("[c13 events UI: WATCH AD · +1 on a joined race; hidden after use, for quest and unjoined]")
	var race := _scene_time(["race", "other"])
	var quest := _scene_time(["quest"])
	var first: Dictionary = race if int(race["t"]) <= int(quest["t"]) else quest
	var second: Dictionary = quest if first == race else race
	_now[0] = int(first["t"])
	var path := _save("c13", 30, D0)
	_day[0] = D0 + 1
	var m := MockProvider.new()
	var root = await _boot_main(path, 0, m)
	var app = root.get_app_state()
	for sc in [first, second]:
		_now[0] = int(sc["t"])
		if sc == race:
			await _ui_race(root, app, m, sc["iid"]["race"], sc["iid"]["other"])
		else:
			var q: String = sc["iid"]["quest"]
			app.actions.join_event(q)
			var p = _details(root, app, q)
			_ok(not p.get_action_button("ad").visible, "joined quest event: ad action hidden")
			root.get_modal_stack().clear("t")
	_ok(UiText.EN.get("EV2_WATCH_AD") == "WATCH AD · +1", "EN text WATCH AD · +1")
	UiText.locale = "tr"
	_ok(UiText.t("EV2_WATCH_AD") == "REKLAM İZLE · +1", "TR text REKLAM İZLE · +1")
	UiText.locale = "en"
	_shutdown(root)
	_day[0] = D0
	_complete("c13_events_ui")

func _ui_race(root, app, m: MockProvider, iid: String, other: String) -> void:
	var p = _details(root, app, other)
	_ok(not p.get_action_button("ad").visible, "unjoined event: ad action hidden")
	root.get_modal_stack().clear("t")
	app.actions.join_event(iid)
	p = _details(root, app, iid)
	var b: Button = p.get_action_button("ad")
	_ok(b.visible and b.text == UiText.t("EV2_WATCH_AD"), "joined race: WATCH AD · +1 visible")
	var p0: int = app.economy.events_v02.view(iid)["progress"]
	b.pressed.emit()
	_ok(m.requests.size() == 1 and m.requests[0][0] == EVENT_PLACEMENT, "tap -> one rewarded request through the facade")
	m.finish("completed")
	await process_frame
	_ok(app.economy.events_v02.view(iid)["progress"] == p0 + 1 and not p.get_action_button("ad").visible, "verified view -> +1 progress, ad action hidden for the day")
	root.get_modal_stack().clear("t")

func _c14() -> void:
	print("[c14 analytics: ad_placement / ad_request / ad_result, consent-gated]")
	for consent in [true, false]:
		var t := _scene_time(["race"])
		_now[0] = int(t["t"])
		var path := _save("c14_%s" % str(consent), 30, D0)
		_day[0] = D0 + 1
		var app = AppState.new(path, func(): return _now[0], func(): return _day[0])
		var an = app.analytics
		an.sink = AnalyticsService.MemorySink.new()
		an.set_consent(consent)
		var m := MockProvider.new()
		app.economy.ads.set_provider(m)
		m.fill = false
		app.economy.ads.try_app_open()
		m.fill = true
		app.economy.ads.try_app_open()
		app.economy.ads.try_app_open()   # ineligible (day used): no event
		for _i in range(4):
			app.economy.ads.on_play_finished(12)
		m.fill = false
		app.economy.ads.try_interstitial()
		m.fill = true
		app.economy.ads.try_interstitial()
		app.economy.ads.try_interstitial()   # not due: no event
		var iid: String = t["iid"]["race"]
		app.actions.join_event(iid)
		var p := BasePopup.new("t")
		EventsV02Ui._watch_ad(p, app, iid)
		m.finish("completed")
		p.free()
		an.flush()
		var evs: Array = an.sink.events
		var pick := func(name: String) -> Array: return evs.filter(func(x): return x["event"] == name).map(func(x): return x["params"])
		if consent:
			var pl: Array = pick.call("ad_placement")
			_ok(pl == [{"placement": "app_open", "shown": false, "reason": "no_fill"}, {"placement": "app_open", "shown": true, "reason": "shown"},
				{"placement": "interstitial", "shown": false, "reason": "no_fill"}, {"placement": "interstitial", "shown": true, "reason": "shown"}], "ad_placement x4 (no fill + shown per placement), none when ineligible: %s" % str(pl))
			_ok(pick.call("ad_request") == [{"product": "event_progress", "ok": true, "reason": "ok"}], "ad_request product event_progress: %s" % str(pick.call("ad_request")))
			_ok(pick.call("ad_result") == [{"product": "event_progress", "outcome": "granted"}], "ad_result product event_progress granted: %s" % str(pick.call("ad_result")))
		else:
			_ok(evs.is_empty() and an.queued() == 0 and m.count("app_open") == 2, "consent off: nothing queued or sent (ads still ran)")
		app.economy.dispose()
	_day[0] = D0
	_complete("c14_analytics")

# ------------------------------------------------------------------ helpers ----

func _eco() -> EconomyServices:
	return EconomyServices.new(EconomyConfig.DEFAULT_PATH, func(): return _now[0], null, func(): return _day[0])

## First whole hour (+60 s) of the schedule where every wanted kind is active ("other" = any
## event that can take an event ad and is not a race). {t, iid: {kind: iid}}.
func _scene_time(want: Array) -> Dictionary:
	var ev := EventsV02.new(func(): return 0)
	var epoch := int(_rt["schedule"]["epoch_utc"])
	for h in range(int(_rt["schedule"]["cycle_hours"])):
		var t := epoch + h * 3600 + 60
		var got := {}
		for s in ev.scheduled(t, t + 1):
			var k := String(ev.def(s["id"])["kind"])
			if want.has(k) and not got.has(k):
				got[k] = s["iid"]
			elif want.has("other") and not got.has("other") and k != "race" and not EventsV02.AD_EXCLUDED_KINDS.has(k):
				got["other"] = s["iid"]
		if got.size() == want.size():
			return {"t": t, "iid": got}
	return {}

## Moves the clock to a time where `want` is active and joins each (except `skip`).
func _join(e, want: Array, skip: Array = []) -> Dictionary:
	var sc := _scene_time(want)
	_now[0] = int(sc["t"])
	for k in sc["iid"]:
		if not skip.has(k):
			e.events_v02.join(sc["iid"][k], true)
	return sc["iid"]

## A throw-away save at frontier `level`; first_day >= 0 records the install day.
func _save(tag: String, level: int, first_day: int) -> String:
	var path := "user://sb_tf07_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var a = AppState.new(path, func(): return _now[0], func(): return _day[0])
	a.progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": level, "completed": range(1, level)})
	if first_day >= 0:
		_day[0] = first_day
		a.economy.ads.note_launch()
	a.request_save()
	a.economy.dispose()
	return path

func _boot_main(path: String, opening: int, m: MockProvider):
	LaunchSession.debug_reset_for_new_process()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = opening
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MainScript.boot_ad_provider_override = m
	var root = MainScene.instantiate()
	m.main = root
	get_root().add_child(root)
	await process_frame
	return root

func _details(root, app, iid: String):
	root.get_modal_stack().clear("t")
	app.actions.mark_event_tutorial_seen(String(app.economy.events_v02.view(iid)["id"]))
	return EventsV02Ui.open_details(root.get_modal_stack(), app, iid)

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	MainScript.boot_ad_provider_override = null

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		for side in ["_analytics.json", "_cloud.json"]:
			var f: String = p.get_basename() + side
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
	print("SB-TF-07 ad placements evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
