extends SceneTree
## SB-TF-05 (owner 2026-11-18) shared reward reveal: every reward source shows its committed
## rewards together, holds exactly 1.5 s, then flies them to their HUD targets with one input
## lock; Reduced Effects keeps the hold and drops the flight; a card pack grows and hands over to
## the earned-pack flow; after a win a rewarded "Watch ad, x2" doubles only that win's Scrub
## Bucks on a verified completed view, once (deterministic tx, survives a reload).
## Presenter cases run on a fake Home with a manual clock; routing / x2 cases on the real
## main.tscn root, AppState graph, ProductionActionFacade and RewardedGrantService.
##
## Run: godot --headless --path . -s res://tests/sb_tf05_reward_reveal.gd

const RewardReveal = preload("res://scripts/ui/components/reward_reveal.gd")
const HomeRewardFlight = preload("res://scripts/ui/home/home_reward_flight.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const R := NavigationController.Route

var EXPECTED_CASES := [
	"timeline", "input_lock", "empty_entries", "reduced_effects", "one_shot_finish", "win_entries",
	"x2_visibility", "x2_granted_once", "x2_not_granted", "hold_pauses_during_ad", "x2_only_scrub_bucks",
	"no_ads_and_test_mode", "routing_all_sources", "card_pack_handoff", "presenter_source_clean",
]

## Minimal Home: named HUD regions + the counter seam the reveal calls.
class FakeHome extends Control:
	var regions := {}
	var shown: Array = []
	func get_region(n: String) -> Control:
		return regions.get(n)
	func show_hud_value(kind: String, v: float) -> void:
		shown.append([kind, int(round(v))])
	func last(kind: String) -> int:
		for i in range(shown.size() - 1, -1, -1):
			if shown[i][0] == kind:
				return shown[i][1]
		return -1

## Rewarded provider: ready / not ready; keeps every request so the test delivers the result.
class MockAds extends AdProvider:
	var ready := true
	var requests: Array = []   # [placement, token, deliver]
	func is_available(_placement: String) -> bool:
		return ready
	func request(placement: String, token: String, deliver: Callable) -> bool:
		requests.append([placement, token, deliver])
		return true
	func deliver_last(result: Dictionary) -> Dictionary:
		var q: Array = requests[-1]
		return (q[2] as Callable).call(q[1], result)

## Earned-pack presenter stand-in: counts drain() (the first one "opens" a pack).
class FakePacks extends RefCounted:
	var drains := 0
	func drain() -> bool:
		drains += 1
		return true
	func is_presenting() -> bool:
		return drains > 0

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 0
	MainScript.boot_win_animation_override = 0
	AppState.test_unlock_all = true
	await process_frame
	_timeline()
	_empty_entries()
	_reduced_effects()
	_one_shot_finish()
	_win_entries()
	_card_pack_presenter()
	await _input_lock()
	await _x2_visibility()
	await _x2_granted_once()
	await _x2_not_granted()
	await _hold_pauses_during_ad()
	await _x2_only_scrub_bucks()
	await _no_ads_and_test_mode()
	await _routing_all_sources()
	await _card_pack_handoff()
	_presenter_source_clean()
	_cleanup()
	_done()

# ------------------------------------------------------------ presenter (fake Home) ----

func _fake() -> FakeHome:
	var h := FakeHome.new()
	h.size = Vector2(1080, 1920)
	get_root().add_child(h)
	var spots := {"ScrubBucksChip": Vector2(820, 40), "ProfileBotParts": Vector2(40, 40), "ProfileCard": Vector2(40, 140), "HeartsChip": Vector2(820, 140)}
	for n in spots:
		var b := Button.new()
		b.name = n
		b.position = spots[n]
		b.size = Vector2(200, 80)
		h.add_child(b)
		h.regions[n] = b
	return h

func _reveal(h: FakeHome):
	var r = RewardReveal.new(h)
	r.manual_clock = true
	return r

func _two() -> Array:
	return [{"kind": "scrub_bucks", "n": 40, "from": 100, "to": 140, "target": "ScrubBucksChip"},
		{"kind": "bot_parts", "n": 2, "from": 3, "to": 5, "target": "ProfileBotParts"}]

func _copies_visible(r) -> int:
	var n := 0
	for b in r.get_bursts():
		for c in b.copies:
			n += 1 if c.visible else 0
	return n

func _timeline() -> void:
	print("[timeline on a fake clock]")
	var h := _fake()
	var r = _reveal(h)
	var done: Array = []
	r.completed.connect(func(k): done.append(k))
	_ok(RewardReveal.HOLD_S == 1.5 and RewardReveal.APPEAR_S <= 0.12, "HOLD_S == 1.5, APPEAR_S %.2f <= 0.12" % RewardReveal.APPEAR_S)
	_ok(r.show_rewards(_two(), "tl", {}), "two entries shown")
	var heroes: Array = r.get_bursts().map(func(b): return b.hero)
	r.advance(0.06)
	_ok(heroes[0].modulate.a > 0.0 and is_equal_approx(heroes[0].modulate.a, heroes[1].modulate.a), "both entries fade in in the same step (a=%.2f / %.2f)" % [heroes[0].modulate.a, heroes[1].modulate.a])
	r.advance(0.06)
	_ok(heroes[0].modulate.a == 1.0 and heroes[1].modulate.a == 1.0 and heroes.all(func(x): return x.get_node("Icon").visible and x.get_node("Amount").visible), "both fully shown at t = 0.12")
	_ok(is_equal_approx(r.fly_at(), RewardReveal.APPEAR_S + RewardReveal.HOLD_S), "flight starts exactly HOLD_S after the reveal is fully shown (%.2f s)" % r.fly_at())
	r.advance(1.49)
	_ok(_copies_visible(r) == 0 and r.is_running() and h.last("scrub_bucks") == 100, "hold 1.49 s: no flight copy, counter at the start value")
	r.advance(0.02)
	_ok(_copies_visible(r) >= 1, "after the 1.5 s hold the first copies fly (%d visible)" % _copies_visible(r))
	_ok(done.is_empty(), "not completed during the flight")
	for _i in range(40):
		r.advance(0.05)
	_ok(done == ["tl"] and not r.is_running() and r.get_layer() == null, "completed once after hold + flight, layer freed")
	_ok(h.last("scrub_bucks") == 140 and h.last("bot_parts") == 5, "counters land exactly on the final values")
	h.free()
	_completed["timeline"] = true

func _empty_entries() -> void:
	print("[zero entries]")
	var h := _fake()
	var r = _reveal(h)
	var done: Array = []
	r.completed.connect(func(k): done.append(k))
	_ok(not r.show_rewards([], "e1", {}) and not r.show_rewards([{"kind": "scrub_bucks", "n": 0, "from": 1, "to": 1, "target": "ScrubBucksChip"}], "e2", {}), "empty / zero-amount entries refused")
	_ok(not r.is_running() and r.get_layer() == null and h.get_child_count() == 4 and done.is_empty(), "nothing shown, no lock layer, no completion pending")
	h.free()
	_completed["empty_entries"] = true

func _reduced_effects() -> void:
	print("[Reduced Effects]")
	var h := _fake()
	var r = _reveal(h)
	var done: Array = []
	r.completed.connect(func(k): done.append(k))
	r.show_rewards(_two(), "red", {"reduced": true})
	var copies := 0
	for b in r.get_bursts():
		copies += b.copies.size()
	_ok(r.get_layer() != null and r.get_layer().mouse_filter == Control.MOUSE_FILTER_STOP and r.get_bursts()[0].hero.modulate.a == 1.0, "reveal visible at once, input locked")
	_ok(copies == 0, "zero flying copies")
	r.advance(1.0)
	_ok(r.is_running() and h.last("scrub_bucks") == 100, "still holding at 1.0 s")
	r.advance(RewardReveal.HOLD_S + RewardReveal.APPEAR_S - 1.0 + 0.001)
	_ok(done == ["red"] and r.get_layer() == null, "completed right after the 1.5 s hold, lock freed")
	_ok(h.last("scrub_bucks") == 140 and h.last("bot_parts") == 5, "counters at the final values")
	h.free()
	_completed["reduced_effects"] = true

func _one_shot_finish() -> void:
	print("[one-shot per key, finish()]")
	var h := _fake()
	var r = _reveal(h)
	var done: Array = []
	r.completed.connect(func(k): done.append(k))
	_ok(r.show_rewards(_two(), "k1", {}) and not r.show_rewards(_two(), "k1", {}), "same key twice: second refused")
	r.finish()
	_ok(done == ["k1"] and r.get_layer() == null and not r.is_running(), "finish() completes once and frees the lock")
	_ok(h.last("scrub_bucks") == 140 and h.last("bot_parts") == 5, "finish() lands the final values")
	_ok(not r.show_rewards(_two(), "k1", {}) and r.has_played("k1"), "a finished key never replays")
	r.show_rewards(_two(), "k2", {})
	_ok(r.show_rewards([{"kind": "hearts", "n": 1, "target": "HeartsChip"}], "k3", {}) and r.current_key() == "k2", "a request during a reveal queues behind it")
	r.finish()
	_ok(r.current_key() == "k3" and done == ["k1", "k2"], "the queued reveal starts when the first ends")
	r.finish()
	_ok(done == ["k1", "k2", "k3"] and not r.is_running(), "queue drained")
	h.free()
	_completed["one_shot_finish"] = true

func _win_entries() -> void:
	print("[win entries from the receipt]")
	var rc := {"status": "WON", "wallet_delta": {"scrub_bucks": 40, "bot_parts": 1}, "cards_delta": 2,
		"reveal_queue": [{"kind": "win_streak", "from": 1, "to": 2}, {"kind": "gift_meter", "from": 3, "to": 5}],
		"gift_meter": {"cycles_before": 0, "cycles_after": 0}, "streak": {"before": 1, "after": 2}}
	var vm := {"ok": true, "scrub_bucks": 540, "bot_parts": 4}
	var p: Array = HomeRewardFlight.plan(rc, vm)
	_ok(p.map(func(e): return e["kind"]) == ["scrub_bucks", "bot_parts", "gift_meter", "collection_cards"], "SB, Bot Parts, Gift Meter, cards %s" % str(p.map(func(e): return e["kind"])))
	_ok(p[0]["n"] == 40 and p[0]["from"] == 500 and p[0]["to"] == 540 and p[2]["n"] == 2 and p[3]["n"] == 2, "amounts from the committed receipt")
	_ok(not p.any(func(e): return String(e["target"]).contains("Streak") or e["kind"] == "win_streak"), "no win-streak target (SB-TF-03)")
	_ok(HomeRewardFlight.plan({"status": "LOST", "wallet_delta": {"scrub_bucks": 40}}, vm).is_empty(), "LOST shows nothing")
	_completed["win_entries"] = true

func _card_pack_presenter() -> void:
	print("[card pack grows, never flies]")
	var h := _fake()
	var r = _reveal(h)
	var entries: Array = RewardReveal.entries_for({"standard_card_packs": 1, "scrub_bucks": 20}, {"ok": true, "scrub_bucks": 120, "bot_parts": 0})
	_ok(entries.map(func(e): return e["kind"]) == ["scrub_bucks", "standard_card_packs"], "entries %s" % str(entries.map(func(e): return e["kind"])))
	r.show_rewards(entries, "pk", {})
	var packs: Array = r.get_pack_heroes()
	_ok(packs.size() == 1 and r.get_bursts().size() == 1 and r.get_bursts()[0].kind == "scrub_bucks", "the pack is a grow hero, not a flight burst")
	r.advance(RewardReveal.APPEAR_S)
	var s0: float = packs[0].get_node("Icon").scale.x
	r.advance(RewardReveal.HOLD_S - 0.01)
	var s1: float = packs[0].get_node("Icon").scale.x
	_ok(is_equal_approx(s0, 1.0) and s1 > 1.3, "pack grows during the hold (%.2f -> %.2f)" % [s0, s1])
	r.advance(0.02)
	_ok(not packs[0].visible and packs[0].get_child_count() == 2, "after the hold the pack hands over (hidden, no copies)")
	h.free()

# ------------------------------------------------------------ app root cases ----

func _input_lock() -> void:
	print("[input lock over Home + Back]")
	var root = await _boot(_uniq("lock"))
	var home = root.get_home()
	var hits := {"n": 0}
	home.get_region("ProfileButton").pressed.connect(func(): hits["n"] += 1)
	_ok(root.request_reward_reveal("tasks", {"scrub_bucks": 75}, "tasks:lock"), "a Tasks reward reveal on Home")
	var r = home.get_reward_flight()
	r.manual_clock = true
	var layer: Control = r.get_layer()
	_ok(layer.mouse_filter == Control.MOUSE_FILTER_STOP and layer.get_global_rect().encloses(home.get_global_rect()) and layer.get_parent() is CanvasLayer and (layer.get_parent() as CanvasLayer).layer > root.get_modal_stack().layer, "full-rect STOP layer above the ModalStack")
	for t in [0.0, 1.0, 0.6]:
		r.advance(t)
		await _tap(home.get_region("ProfileButton"))
	_ok(hits["n"] == 0 and root.get_modal_stack().depth() == 0, "taps at t = 0 / 1.0 / 1.6 do nothing")
	_ok(root.handle_back() == "none" and r.is_running(), "Back ignored during the reveal")
	for _i in range(40):
		r.advance(0.05)
	_ok(not r.is_running() and r.get_layer() == null, "completed, lock freed")
	await _frames(2)
	await _tap(home.get_region("ProfileButton"))
	_ok(hits["n"] == 1, "the same tap works after the reveal")
	_shutdown(root)
	_completed["input_lock"] = true

func _win_rc(sb: int, status := "WON") -> Dictionary:
	return {"status": status, "wallet_delta": {"scrub_bucks": sb}, "cards_delta": 2, "reveal_queue": []}

func _x2_visibility() -> void:
	print("[x2 button visibility]")
	var root = await _boot(_uniq("vis"))
	var home = root.get_home()
	var ads := MockAds.new()
	root.get_app_state().economy.ads.set_provider(ads)
	var r = home.get_reward_flight()
	r.manual_clock = true
	_ok(home.play_reward_flight(_win_rc(30), "win:a1:L1") and r.get_double_button() != null and r.get_double_button().visible, "WON, SB > 0, ad ready: x2 shown")
	_ok(r.get_double_button().text == UiText.t("REVEAL_WATCH_X2"), "button text %s" % r.get_double_button().text)
	r.advance(RewardReveal.APPEAR_S + RewardReveal.HOLD_S + 0.01)
	_ok(r.get_double_button() == null or not r.get_double_button().visible, "button gone when the hold ends")
	r.finish()
	_ok(not home.play_reward_flight(_win_rc(30, "LOST"), "win:a2:L1") and r.get_double_button() == null, "LOST: nothing shown, no x2")
	home.play_reward_flight(_win_rc(0), "win:a3:L1")
	_ok(r.is_running() and r.get_double_button() == null, "0 SB: no x2")
	r.finish()
	root.request_reward_reveal("daily", {"scrub_bucks": 50}, "daily:x")
	_ok(r.is_running() and r.get_double_button() == null, "non-win source: no x2")
	r.finish()
	ads.ready = false
	home.play_reward_flight(_win_rc(30), "win:a4:L1")
	_ok(r.is_running() and r.get_double_button() == null, "provider unavailable: no x2")
	r.finish()
	_shutdown(root)
	_completed["x2_visibility"] = true

func _x2_granted_once() -> void:
	print("[x2 granted exactly once]")
	var path := _uniq("grant")
	var root = await _boot(path)
	var app = root.get_app_state()
	var home = root.get_home()
	var ads := MockAds.new()
	app.economy.ads.set_provider(ads)
	var r = home.get_reward_flight()
	r.manual_clock = true
	var sb0: int = app.economy.wallet.scrub_bucks()
	home.play_reward_flight(_win_rc(30), "win:a1:L1")
	r.advance(0.5)
	r.get_double_button().pressed.emit()
	_ok(ads.requests.size() == 1 and ads.requests[0][0] == "rewarded_win_double" and r.is_ad_pending() and r.get_double_button() == null, "tap -> one rewarded request (placement rewarded_win_double), button gone")
	ads.deliver_last({"outcome": "completed", "verified": true})
	_ok(app.economy.wallet.scrub_bucks() == sb0 + 30 and app.economy.reward.already_applied("win_double:win:a1:L1"), "verified completion: +30 SB once under win_double:win:a1:L1")
	var amount: Label = r.get_bursts()[0].hero.get_node("Amount")
	_ok(amount.text == "+" + UiText.num(60) and not r.is_ad_pending(), "reveal shows the doubled +60")
	r._on_double()
	var again: Dictionary = ads.deliver_last({"outcome": "completed", "verified": true})
	_ok(ads.requests.size() == 1 and not bool(again.get("ok", false)) and app.economy.wallet.scrub_bucks() == sb0 + 30, "second tap / duplicate callback grant nothing (%s)" % String(again.get("reason", "")))
	_ok(not app.actions.win_double_available("win:a1:L1", _win_rc(30)) and not bool(app.actions.start_win_double("win:a1:L1", _win_rc(30)).get("ok", false)), "the same win cannot be doubled twice")
	for _i in range(60):
		r.advance(0.05)
	_ok(_chip(home) == UiText.num(app.economy.wallet.scrub_bucks()), "flight counts to the doubled wallet %s" % _chip(home))
	app.request_save()
	_shutdown(root, false)
	var app2 = AppState.new(path)
	_ok(app2.economy.reward.already_applied("win_double:win:a1:L1") and app2.economy.wallet.scrub_bucks() == sb0 + 30, "reload keeps the tx and the doubled wallet")
	var ads2 := MockAds.new()
	app2.economy.ads.set_provider(ads2)
	var s2: Dictionary = app2.actions.start_win_double("win:a1:L1", _win_rc(30))
	_ok(not bool(s2.get("ok", false)) and ads2.requests.is_empty() and app2.economy.wallet.scrub_bucks() == sb0 + 30, "after reload a second attempt grants nothing (%s)" % String(s2.get("reason", "")))
	MainScript.boot_save_path_override = ""
	_completed["x2_granted_once"] = true

func _x2_not_granted() -> void:
	print("[x2 not granted: cancelled / failed / unverified / verified missing / timeout]")
	var root = await _boot(_uniq("nogrant"))
	var app = root.get_app_state()
	var home = root.get_home()
	var ads := MockAds.new()
	app.economy.ads.set_provider(ads)
	var r = home.get_reward_flight()
	r.manual_clock = true
	var cases := [["cancelled", {"outcome": "cancelled"}], ["failed", {"outcome": "failed"}],
		["unverified", {"outcome": "completed", "verified": false}], ["verified missing", {"outcome": "completed"}], ["timeout", null]]
	var i := 0
	for c in cases:
		i += 1
		var sb0: int = app.economy.wallet.scrub_bucks()
		var tx0: int = app.economy.reward.applied_transaction_count()
		home.play_reward_flight(_win_rc(30), "win:a%d:L2" % i)
		r.advance(0.3)
		r.get_double_button().pressed.emit()
		if c[1] == null:
			r.advance(RewardReveal.AD_TIMEOUT_S + 0.1)
		else:
			ads.deliver_last(c[1])
		var late: Dictionary = ads.deliver_last({"outcome": "completed", "verified": true}) if c[1] == null else {}
		_ok(app.economy.wallet.scrub_bucks() == sb0 and app.economy.reward.applied_transaction_count() == tx0 and not bool(late.get("ok", false)), "%s: wallet / ledger unchanged" % c[0])
		_ok(not r.is_ad_pending() and is_equal_approx(r.elapsed(), r.fly_at()) and r.get_double_button() == null, "%s: flight starts at once, button removed" % c[0])
		_ok((r.get_bursts()[0].hero.get_node("Amount") as Label).text == "+30", "%s: normal amount" % c[0])
		r.finish()
	_shutdown(root)
	_completed["x2_not_granted"] = true

func _hold_pauses_during_ad() -> void:
	print("[the hold pauses while the ad plays]")
	var root = await _boot(_uniq("pause"))
	var app = root.get_app_state()
	var home = root.get_home()
	var ads := MockAds.new()
	app.economy.ads.set_provider(ads)
	var r = home.get_reward_flight()
	r.manual_clock = true
	home.play_reward_flight(_win_rc(30), "win:a1:L3")
	r.advance(RewardReveal.APPEAR_S + 0.5)
	r.get_double_button().pressed.emit()
	var t0: float = r.elapsed()
	for _i in range(20):
		r.advance(1.0)   # 20 s of ad
	_ok(is_equal_approx(r.elapsed(), t0) and r.is_running() and _copies(r) == 0, "20 s of ad: clock stands still at %.2f, nothing flies" % r.elapsed())
	ads.deliver_last({"outcome": "completed", "verified": true})
	_ok(is_equal_approx(r.fly_at() - r.elapsed(), 1.0), "granted: the remaining hold (1.0 s) continues")
	r.advance(0.99)
	_ok(_copies(r) == 0, "still holding 0.99 s later")
	r.advance(0.02)
	_ok(_copies(r) >= 1, "then the flight starts")
	r.finish()
	_shutdown(root)
	_completed["hold_pauses_during_ad"] = true

func _x2_only_scrub_bucks() -> void:
	print("[x2 only doubles Scrub Bucks]")
	var root = await _boot(_uniq("only"))
	var app = root.get_app_state()
	var eco = app.economy
	var home = root.get_home()
	var ads := MockAds.new()
	eco.ads.set_provider(ads)
	var r = home.get_reward_flight()
	r.manual_clock = true
	var before := _econ(eco)
	home.play_reward_flight(_win_rc(30), "win:a1:L4")
	var n_cards: int = r.get_bursts()[1].n
	r.get_double_button().pressed.emit()
	ads.deliver_last({"outcome": "completed", "verified": true})
	var after := _econ(eco)
	_ok(after["sb"] == before["sb"] + 30, "SB +30 (one extra copy of the win's SB)")
	for k in ["parts", "gift", "cards", "streak", "hearts", "plays"]:
		_ok(after[k] == before[k], "%s unchanged (%s)" % [k, str(after[k])])
	_ok(r.get_bursts()[1].kind == "collection_cards" and r.get_bursts()[1].n == n_cards, "the cards entry keeps its amount (+%d)" % n_cards)
	r.finish()
	_shutdown(root)
	_completed["x2_only_scrub_bucks"] = true

func _no_ads_and_test_mode() -> void:
	print("[No Ads keeps rewarded x2; test mode is the same path]")
	var root = await _boot(_uniq("noads"))
	var app = root.get_app_state()
	var eco = app.economy
	var home = root.get_home()
	var ads := MockAds.new()
	eco.ads.set_provider(ads)
	eco.store.grant_no_ads()
	_ok(eco.store.no_ads() and eco.store.ads_allowed("rewarded") and not eco.ads.allowed("banner"), "No Ads owned: banner off, rewarded allowed")
	var r = home.get_reward_flight()
	r.manual_clock = true
	var sb0: int = eco.wallet.scrub_bucks()
	home.play_reward_flight(_win_rc(25), "win:a1:L5")
	_ok(r.get_double_button() != null, "x2 offered under No Ads")
	r.get_double_button().pressed.emit()
	ads.deliver_last({"outcome": "completed", "verified": true})
	_ok(eco.wallet.scrub_bucks() == sb0 + 25, "x2 granted under No Ads")
	r.finish()
	var src := FileAccess.get_file_as_string("res://scripts/ui/components/reward_reveal.gd") + FileAccess.get_file_as_string("res://scripts/ui/home/home_screen.gd")
	_ok(not src.contains("test_mode") and not src.contains("ads_test"), "no ad-test-mode special case in the reveal / Home x2 path")
	_shutdown(root)
	_completed["no_ads_and_test_mode"] = true

func _routing_all_sources() -> void:
	print("[every source -> request_reward_reveal once per committed claim]")
	var root = await _boot(_uniq("route"), 5000)
	root.packs = null   # earned packs open (and commit) on their own; keep the per-step economy diff to the claim
	var app = root.get_app_state()
	var eco = app.economy
	var acts = app.actions
	var home = root.get_home()
	var r = home.get_reward_flight()
	r.manual_clock = true
	var ads := MockAds.new()
	eco.ads.set_provider(ads)
	var steps := []
	# win (the real app-root win entry with a committed receipt)
	steps.append(["win", func(): root._start_win_rewards({"receipt": _win_rc(30), "attempt": 7, "level": 1}); return {"ok": true}])
	steps.append(["daily", func(): return acts.claim_daily_login()])
	steps.append(["tasks", func():
		eco.daily.mark_task_done(0)
		return acts.claim_daily_task(0)])
	steps.append(["gift_meter", func():
		var occ: Array = eco.gift.add_streak_sb("tf05", 10)
		for o in occ:
			eco.meta_ui.mark_seen("gift:" + String(o["id"]))
		return acts.claim_gift(String(occ[0]["id"])) if not occ.is_empty() else {"ok": false}])
	steps.append(["events", func():
		_event_config(eco)
		eco.events.on_progression_terminal(true, false)
		return acts.claim_event_milestone("wk_tf05", 0)])
	steps.append(["rewarded_ads", func(): return acts.claim_rewarded_daily_free()])
	steps.append(["shop", func(): return acts.buy_booster_charge("random")])
	# verified rewarded video (booster product) and a real-money SB pack delivered by the store
	steps.append(["rewarded_ads", func():
		acts.start_rewarded("booster:random")
		return ads.deliver_last({"outcome": "completed", "verified": true})])
	steps.append(["shop", func(): return eco.store.deliver({"product_id": "scrubbucks_100", "token": "tf05_tok", "outcome": "purchased"})])
	steps.append(["collection", func():
		var ids: Array = eco.collection.all_card_ids().filter(func(c): return eco.collection.card_set(c) == 1)
		for c in ids:
			eco.collection.add_card(c)
		return {"ok": eco.reward.already_applied("collection_set:1")}])
	for st in steps:
		var src: String = st[0]
		var n0: int = root.reveal_log.size()
		var r0 := _econ(eco)
		var res: Dictionary = (st[1] as Callable).call()
		var r1 := _econ(eco)
		var mine: Array = root.reveal_log.slice(n0).filter(func(e): return e[0] == src)
		_ok(bool(res.get("ok", false)) and mine.size() == 1 and bool(mine[0][2]) and root.reveal_log.size() - n0 == 1 and r.is_running(), "%s: committed claim -> exactly one reveal %s" % [src, str(root.reveal_log.slice(n0))])
		r.finish()
		await _frames(2)
		root.get_modal_stack().clear("test")
		_ok(_econ(eco) == r1, "%s: the reveal changed no economy value" % src)
		if src == "tasks":
			_ok(r1["sb"] == r0["sb"] + int(res.get("sb", -1)), "tasks: wallet = claim result (+%d)" % int(res.get("sb", -1)))
	var ui_files: Array = []
	_collect("res://scripts/ui", ui_files)
	var bad: Array = []
	for f in ui_files:
		var t := FileAccess.get_file_as_string(f)
		for needle in [".grant(", ".credit(", ".debit(", "RewardGrantService."]:
			if t.contains(needle):
				bad.append("%s %s" % [f.get_file(), needle])
		if t.contains("RewardFlightLayer") and not f.ends_with("reward_reveal.gd"):
			bad.append(f.get_file() + " builds its own flight")
	_ok(bad.is_empty(), "no UI script grants / touches the wallet or builds its own flight %s" % str(bad))
	_shutdown(root)
	_completed["routing_all_sources"] = true

func _card_pack_handoff() -> void:
	print("[card pack -> the earned-pack flow once]")
	var root = await _boot(_uniq("pack"))
	var fake := FakePacks.new()
	root.packs = fake
	var r = root.get_home().get_reward_flight()
	r.manual_clock = true
	root.request_reward_reveal("gift_meter", {"standard_card_packs": 1}, "gift:pack")
	_ok(r.get_pack_heroes().size() == 1 and r.get_bursts().is_empty(), "pack shown as a grow hero, no coin-style flight")
	await _frames(3)
	_ok(fake.drains == 0, "no pack opens while the reveal runs")
	r.advance(RewardReveal.APPEAR_S + RewardReveal.HOLD_S + 0.01)
	_ok(not r.is_running(), "a pack-only reveal ends with the hold")
	await _frames(3)
	_ok(fake.drains == 1, "packs.drain() observed once (%d)" % fake.drains)
	root.packs = null
	_shutdown(root)
	_completed["card_pack_handoff"] = true

func _presenter_source_clean() -> void:
	print("[presenter source]")
	var t := FileAccess.get_file_as_string("res://scripts/ui/components/reward_reveal.gd")
	var bad: Array = []
	for needle in ["wallet", "RewardGrantService", ".grant(", "save", "request_save", "create_timer"]:
		if t.contains(needle):
			bad.append(needle)
	_ok(bad.is_empty(), "reward_reveal.gd has no wallet / grant / save / wall-clock timer %s" % str(bad))
	_completed["presenter_source_clean"] = true

# ---------------------------------------------------------------- helpers ----

func _econ(eco) -> Dictionary:
	return {"sb": eco.wallet.scrub_bucks(), "parts": eco.wallet.bot_parts(), "gift": eco.gift.snapshot(),
		"cards": eco.collection.snapshot(), "streak": eco.streak.streak(), "hearts": eco.hearts.hearts(), "plays": eco.ads.plays()}

func _copies(r) -> int:
	return _copies_visible(r)

func _event_config(eco) -> void:
	var cfg := {"schema": "scrubbots.events.v1", "version": 1,
		"approved_reward_types": ["scrub_bucks", "bot_parts", "standard_card_packs", "premium_card_packs", "random_booster_charges", "selected_booster_charges"],
		"weekly_events": [{"id": "wk_tf05", "start_ts": int(Time.get_unix_time_from_system()) - 3600, "unclaimed_on_expiry": "forfeit",
			"milestones": [{"target": 1, "reward": {"scrub_bucks": 50}}]}], "first_try_cleanup": null}
	var path := "user://sb_tf05_events_%d.json" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	eco.events.load_config(path)

func _collect(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_collect(dir + "/" + d, out)

func _boot(path: String, sb := 0):
	var seed = AppState.new(path)
	for o in seed.economy.gift.add_streak_sb("test_seed", 1):
		seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
	if sb > 0:
		seed.economy.reward.grant("test_seed_sb", {"scrub_bucks": sb})
	seed.request_save()
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	root.get_modal_stack().clear("test")
	return root

func _tap(c: Control) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = get_root().get_final_transform() * c.get_global_rect().get_center()
		e.global_position = e.position
		get_root().push_input(e)
		await process_frame

func _chip(home) -> String:
	return String(home.get_region("ScrubBucksChip").value_label.text)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _shutdown(root, reset := true) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	if reset:
		MainScript.boot_save_path_override = ""

func _uniq(tag: String) -> String:
	var p := "user://sb_tf05_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_opening_override = -1
	MainScript.boot_level_intro_override = -1
	MainScript.boot_win_animation_override = -1
	MainScript.boot_save_path_override = ""
	AppState.test_unlock_all = false
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

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-TF-05 reward reveal evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
