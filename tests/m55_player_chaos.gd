extends SceneTree
## M55 player-experience chaos (SB-M55-018..025) against the REAL app root (main.tscn in a
## 1080x2160 SubViewport, throw-away saves, injected wall clock + local day, the test-double
## rewarded provider on the provider-neutral seam). Rows:
##   018 popup / purchase / reward / ceremony button spam      019 background during flows
##   020 three losses with restart / exit mixtures              021 BottomNav churn 200x
##   022 huge inventories                                       023 timer expiry under clock jumps
##   024 offline / online flapping of the network seams         025 presentation-plugin chaos
## Every case asserts: no economy drift (each grant / spend exactly once, presentation changes
## no authority truth), no stuck modal / input lock, and no Node / orphan / tween / Spark emitter /
## video decoder / authority-listener leak (steady state: a repeated lap of the same workload must
## end exactly where the first lap ended).
## 024 network seams: the build has NO network-status seam. The only network-capable seams are the
## remote content transport (disabled by config, TRANSPORT_* failures fall back to builtin / LKG)
## and the rewarded-video provider (production = unavailable until M57). Shop / Events / Ranks /
## cloud save are local-authority only (CloudSave defines an envelope, no transport is wired), so
## 024 flaps those two seams while the Shop / Events / Ranks / Rewarded surfaces are open.
## 025 FAULT arm: the spy Spark throws on every burst; each throw prints the documented
## "SCRIPT ERROR: ... 'explode' in base 'Nil'." line (labelled EXPECTED_FAULT_INJECTION) and is
## the only script error this suite may produce.
##
## Run: godot --headless --path . -s res://tests/m55_player_chaos.gd   (~4 min, local only;
##      `-- <case id> ...` runs only those cases)

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000
const DAY0 := 22000

class FaultySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	var calls := 0
	func burst(_p, _o = {}) -> void:
		calls += 1
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, labelled in the log)
	func at(_n, _o = {}) -> void:
		pass
	func clear() -> void:
		pass

## Remote content transport that flips offline / online (online = a manifest the runtime rejects,
## so nothing can ever be installed: only the failure handling is exercised).
class FlapTransport extends RefCounted:
	var online := false
	var calls := 0
	func fetch_manifest() -> Dictionary:
		calls += 1
		if not online:
			return {"ok": false, "reason": "TRANSPORT_OFFLINE", "bytes": PackedByteArray()}
		return {"ok": true, "reason": "", "bytes": "{\"schema\": \"not-a-manifest\"}".to_utf8_buffer()}
	func fetch_object(_k, _p, _m) -> Dictionary:
		return {"ok": false, "reason": "TRANSPORT_OFFLINE"}

const EXPECTED_CASES := ["018_popup_spam", "018_purchase_reward_spam", "018_ceremony_pack_spam",
	"019_bg_gameplay", "019_bg_results_video", "019_bg_rewarded_purchase", "019_bg_pack_robot",
	"020_triple_loss", "021_nav_churn", "022_huge_inventory", "023_timer_expiry", "024_flapping",
	"025_plugin_chaos"]

var _fail := 0
var _completed := {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _prov
var _now := [T0]
var _day := [DAY0]
var _players: Array = []    ## WeakRef VideoStreamPlayer
var _emitters: Array = []   ## WeakRef Spark emitters
var _max_playing := 0

func _initialize() -> void:
	AppState.test_unlock_all = true
	MainScript.boot_opening_override = 0
	MainScript.boot_ftue_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	node_added.connect(_on_node_added)
	process_frame.connect(_probe)
	await process_frame
	var t0 := Time.get_ticks_msec()
	var only := OS.get_cmdline_user_args()   # debugging: `-- 021_nav_churn` runs that case only
	for c in EXPECTED_CASES:
		if only.is_empty() or only.has(c):
			var t := Time.get_ticks_msec()
			await _run(c)
			print("    (%s: %d ms)" % [c, Time.get_ticks_msec() - t])
	_shutdown()
	_cleanup()
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	_ok(missing.is_empty() or not only.is_empty(), "case ledger: every expected case completed %s" % str(missing))
	print("M55 PLAYER CHAOS (%d ms): %s" % [Time.get_ticks_msec() - t0, "PASS" if _fail == 0 else "FAIL (%d)" % _fail])
	quit(0 if _fail == 0 else 1)

func _run(c: String) -> void:
	match c:
		"018_popup_spam": await _popup_spam()
		"018_purchase_reward_spam": await _purchase_spam()
		"018_ceremony_pack_spam": await _ceremony_pack_spam()
		"019_bg_gameplay": await _bg_gameplay()
		"019_bg_results_video": await _bg_results_video()
		"019_bg_rewarded_purchase": await _bg_rewarded_purchase()
		"019_bg_pack_robot": await _bg_pack_robot()
		"020_triple_loss": await _triple_loss()
		"021_nav_churn": await _nav_churn()
		"022_huge_inventory": await _huge_inventory()
		"023_timer_expiry": await _timer_expiry()
		"024_flapping": await _flapping()
		"025_plugin_chaos": await _plugin_chaos()

# ------------------------------------------------------------------ probes ----

func _on_node_added(n: Node) -> void:
	if n is VideoStreamPlayer:
		_players.append(weakref(n))
	elif n.get_parent() != null and n.get_parent().name == FeedbackAdapter.SPARK_POOL:
		_emitters.append(weakref(n))

func _probe() -> void:
	_max_playing = maxi(_max_playing, _playing())

func _playing() -> int:
	var n := 0
	for w in _players:
		var v = w.get_ref()
		if v != null and v.is_inside_tree() and v.is_playing():
			n += 1
	return n

func _live_emitters() -> int:
	return _emitters.filter(func(w): return w.get_ref() != null).size()

## Leak / lock sample at a quiet HOME (feel adapter owns nothing, popups freed).
func _sample() -> Dictionary:
	var app = _app()
	var nav = _nav()
	return {
		"nodes": _sub.find_children("*", "", true, false).size(),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"tweens": get_processed_tweens().size(),
		"owned": _root.feel.owned_count(), "emitters": _live_emitters(), "decoders": _playing(),
		"depth": _stack().depth(), "modal": _root.get_home().is_modal_active(), "route": nav.current(),
		"settings": nav.is_settings_open(), "hosts": _root.find_children("GameplayHost", "", true, false).size(),
		"listeners": [app.effects.changed.get_connections().size(), nav.route_changed.get_connections().size(),
			nav.settings_changed.get_connections().size(), app.actions.action_committed.get_connections().size(),
			_e().rewarded.resolved.get_connections().size(), _stack().top_changed.get_connections().size(),
			_stack().modal_changed.get_connections().size()],
	}

## Settle at HOME: wait for a streak of frames with no adapter-owned work (one deadline).
func _quiet() -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var streak := 0
	while streak < 12 and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
		streak = streak + 1 if _root.feel.owned_count() == 0 else 0
	await _frames(3)
	return _sample()

## Unlocked HOME: no popup, no Settings, no Home modal flag, HOME route, no host.
func _free_home(s: Dictionary, tag: String) -> void:
	_ok(s["depth"] == 0 and not s["modal"] and s["route"] == R.HOME and not s["settings"] and s["hosts"] == 0,
		"%s: back at an unlocked HOME (depth %d %s, modal %s, route %d, settings %s, hosts %d)" % [tag, s["depth"], str(_stack().ids()), str(s["modal"]), s["route"], str(s["settings"]), s["hosts"]])

## Steady state: the second lap of the same workload ends exactly where the first ended. [] = no leak.
static func leak_violations(a: Dictionary, b: Dictionary) -> Array:
	var v: Array = []
	if b["nodes"] != a["nodes"]:
		v.append("nodes %d -> %d" % [a["nodes"], b["nodes"]])
	if b["orphans"] > a["orphans"]:
		v.append("orphans %d -> %d" % [a["orphans"], b["orphans"]])
	if b["tweens"] > a["tweens"]:
		v.append("tweens %d -> %d" % [a["tweens"], b["tweens"]])
	if b["listeners"] != a["listeners"]:
		v.append("listeners %s -> %s" % [str(a["listeners"]), str(b["listeners"])])
	for k in ["owned", "emitters", "decoders"]:
		if b[k] != 0:
			v.append("%s %d" % [k, b[k]])
	return v

func _no_leak(a: Dictionary, b: Dictionary, tag: String) -> void:
	var v := leak_violations(a, b)
	_ok(v.is_empty(), "%s: no leak lap 2 vs lap 1 (nodes %d, orphans %d, tweens %d, listeners %s; no adapter work / Spark emitter / decoder left) %s" % [tag, b["nodes"], b["orphans"], b["tweens"], str(b["listeners"]), str(v)])
	# Rule sensitivity: each kind of growth over the real lap-1 sample is caught.
	for k in ["nodes", "orphans", "tweens", "owned", "emitters", "decoders"]:
		var g := a.duplicate(true)
		g[k] = int(g[k]) + 1
		if leak_violations(a, g).size() != 1:
			_ok(false, "%s: leak rule misses +1 %s" % [tag, k])
	var gl := a.duplicate(true)
	gl["listeners"] = (gl["listeners"] as Array).map(func(x): return x + 1)
	_ok(leak_violations(a, gl).size() == 1, "%s: leak rule fails on +1 node / orphan / tween / adapter work / emitter / decoder / listener" % tag)

# ------------------------------------------------------------------- boot ----

func _boot(frontier: int = 1, sb: int = 0) -> void:
	_shutdown()
	await _frames(2)
	_players.clear()
	_emitters.clear()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _uniq("boot")
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(10)
	_prov = ProviderDouble.new()
	_e().rewarded.set_provider(_prov)
	_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": frontier, "completed": range(1, frontier)})
	_e().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	if sb > 0:
		_e().wallet.credit(EconomyWallet.SCRUB_BUCKS, sb)
	_root.get_home().refresh()
	await _drain_all()

## Acknowledge / close whatever the app put on the stack (boot ceremonies, What's New, ...).
func _drain_all() -> void:
	var t0 := Time.get_ticks_msec()   # SB-PHONE-2026-11-12-E: a win's reward flight lands first
	while _root.get_home().is_reward_flight_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	for _i in range(60):
		await _frames(3)
		var p = _top()
		if p == null:
			return
		if String(p.popup_id).begins_with("ceremony_") and not p.get_action_ids().is_empty():
			p.get_action_button(p.get_action_ids()[0]).pressed.emit()
		elif p.has_method("tap") and p.has_method("phase"):
			await _drive_pack(p)
		else:
			p.close("test")

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

## Background / foreground cycle as the OS delivers it (pause + focus loss, then back).
func _bg_cycle(frames: int = 4) -> void:
	get_root().propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	await _frames(frames)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await _frames(2)

## Real taps on a pack ceremony until it closes (tap spam per frame when `spam` > 1).
func _drive_pack(p, spam: int = 1, mid: Callable = Callable()) -> String:
	var opening := 0
	var mid_done := false
	for _f in range(3000):
		if not is_instance_valid(p) or p.is_closed():
			await _frames(3)
			return ""
		match p.phase():
			"IDLE", "AWAIT_ROUTE":
				for _k in range(spam):
					p.tap()
			"OPENING":
				if not mid_done and mid.is_valid():
					mid_done = true
					await mid.call()
				opening += 1
				if opening == 30:
					for _k in range(spam):
						p.tap()
		await process_frame
	return "pack ceremony did not close (%s)" % p.phase()

## Real-play driver state for one host: the owner plan clicks (or the first accepted front).
func _driver(host) -> Dictionary:
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	host.get_runtime().set_process(false)
	return {"host": host, "clicks": clicks, "i": 0}

## One frame: place the next plan click when a slot is free, then tick.
func _step(d: Dictionary, dt: float) -> void:
	var host = d["host"]
	var input = host.get_input_controller()
	if host.get_slots().rightmost_empty_index() != -1:
		if not (d["clicks"] as Array).is_empty():
			if int(d["i"]) < d["clicks"].size() and input.activate_front(int(d["clicks"][d["i"]]) - 1).get("ok", false):
				d["i"] += 1
		else:
			for col in range(host.get_supply().get_column_count()):
				if input.activate_front(col).get("ok", false):
					break
	host.get_runtime().tick(dt)

## Play the host to its terminal with 1 s ticks (real WON for L1).
func _play_out(host, d: Dictionary = {}) -> String:
	if d.is_empty():
		d = _driver(host)
	for _g in range(200000):
		if host.get_completion().is_terminal():
			break
		_step(d, 1.0)
	return String(host.get_completion().get_state())

func _moving(host) -> int:
	var n := 0
	for c in host.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n

# ================================================================ SB-M55-018 ====

func _popup_spam() -> void:
	print("[018 spam open / close on every Home destination popup]")
	await _boot(1, 50000)
	var lap: Array = []
	for rep in range(2):
		var bad: Array = []
		for id in MainScript.APP_SHORTCUTS + ["events", "robots", "leaderboard", "life", "scrub_bucks"]:
			for _k in range(12):
				_open(id)
			var opened: Array = _stack().ids()
			if opened.size() != 1:
				bad.append([id, "open", opened])
			await _frames(2)
			var p = _top()
			if p != null:
				for _k in range(12):
					p.get_close_button().pressed.emit()
					_root.handle_back()
			await _frames(3)
			if _stack().depth() != 0:
				bad.append([id, "close", _stack().ids()])
				_stack().clear("test")
		# Settings overlay: 12 opens, 12 backs.
		for _k in range(12):
			_root.get_home().settings_requested.emit()
		var s_open: bool = _nav().is_settings_open()
		for _k in range(12):
			_root.handle_back()
		await _frames(3)
		if not s_open or _nav().is_settings_open():
			bad.append(["settings", s_open])
		_ok(bad.is_empty(), "lap %d: 12 same-frame opens -> exactly one popup; 12 close / back taps -> none left %s" % [rep + 1, str(bad)])
		lap.append(await _quiet())
		_free_home(lap[rep], "018 popup spam lap %d" % (rep + 1))
	_no_leak(lap[0], lap[1], "018 popup spam")
	_completed["018_popup_spam"] = true

func _open(id: String) -> void:
	var home = _root.get_home()
	match id:
		"events", "robots", "leaderboard":
			(home.find_child("Nav_" + id, true, false) as Button).pressed.emit()
		"life":
			home.hearts_purchase_requested.emit()
		"scrub_bucks":
			home.scrub_bucks_purchase_requested.emit()
		_:
			home._shortcut_pressed(id)

func _purchase_spam() -> void:
	print("[018 spam purchase / reward buttons: Life, Shop confirm, Daily claim, Rewarded Ads, Exchange]")
	await _boot(1, 50000)
	var e = _e()
	var cfg = e.config
	for _i in range(3):
		e.hearts.consume()
	# Life +1 Heart: 20 same-frame taps.
	var sb0: int = e.wallet.scrub_bucks()
	var p = _root.open_life("chaos")
	for _k in range(20):
		p.get_action_button("heart_plus_one").pressed.emit()
	_ok(e.hearts.hearts() == 3 and e.wallet.scrub_bucks() == sb0 - int(cfg.hearts_plus_one_sb()),
		"Life: 20 same-frame +1 taps -> one Heart, one charge (%d SB)" % int(cfg.hearts_plus_one_sb()))
	await create_timer(0.45).timeout   # past the rearm guard: the next tap is a NEW purchase
	for _k in range(20):
		p.get_action_button("heart_refill").pressed.emit()
	_ok(e.hearts.hearts() == e.hearts.max_hearts() and e.wallet.scrub_bucks() == sb0 - int(cfg.hearts_plus_one_sb()) - 2 * int(cfg.hearts_full_refill_sb_per_missing()),
		"Life: 20 refill taps -> one refill of the 2 missing Hearts")
	p.close("test")
	await _frames(3)
	# Shop: 20 taps on one buy row -> one confirm; 20 confirm taps -> one purchase.
	var sb1: int = e.wallet.scrub_bucks()
	var ch0: int = e.boosters.charges(BoosterInventory.TORNADO)
	_open("shop")
	var shop = _top()
	for _k in range(20):
		shop.get_action_button("buy:booster:tornado").pressed.emit()
	var ids: Array = _stack().ids()
	_ok(ids == ["shop", "shop_confirm"], "Shop: 20 buy taps -> exactly one confirmation %s" % str(ids))
	var conf = _top()
	for _k in range(20):
		conf.get_action_button("confirm").pressed.emit()
	await _frames(2)
	_ok(e.boosters.charges(BoosterInventory.TORNADO) == ch0 + 1 and e.wallet.scrub_bucks() == sb1 - int(cfg.booster_price(BoosterInventory.TORNADO)),
		"Shop: 20 confirm taps -> one Tornado charge, one debit")
	_stack().clear("test")
	await _frames(3)
	# Daily login claim: 20 taps -> one claim + one celebration.
	var tx0: int = e.reward.applied_transaction_count()
	_open("daily")
	var daily = _top()
	for _k in range(20):
		daily.get_action_button("claim").pressed.emit()
	await _frames(2)
	_ok(e.daily.claimed_today() and e.reward.applied_transaction_count() == tx0 + 1 and _stack().ids() == ["daily_login", "ceremony_daily"],
		"Daily: 20 claim taps -> one claim, one celebration %s" % str(_stack().ids()))
	var cel = _top()
	for _k in range(10):
		cel.get_action_button("ok").pressed.emit()
	await _frames(2)
	for _k in range(20):
		daily.get_action_button("claim").pressed.emit()
	_ok(e.reward.applied_transaction_count() == tx0 + 1 and _stack().ids() == ["daily_login"], "Daily: 20 more taps after the claim grant nothing")
	_stack().clear("test")
	await _frames(3)
	# Rewarded Ads: free slot 20 taps -> one grant; watch slot 20 taps -> one request; delivered twice -> one grant.
	_open("rewarded_ads")
	var ra = _top()
	var tx1: int = e.reward.applied_transaction_count()
	for _k in range(20):
		ra.get_action_button("slot:1").pressed.emit()
	_ok(e.reward.applied_transaction_count() == tx1 + 1, "Rewarded Ads: 20 free-slot taps -> one grant")
	await create_timer(0.45).timeout
	var req0: int = _prov.requests.size()
	for _k in range(20):
		ra.get_action_button("slot:2").pressed.emit()
	_ok(_prov.requests.size() == req0 + 1 and ra.is_busy(), "Rewarded Ads: 20 watch taps -> one provider request, popup busy")
	var tok: String = _prov.last_token()
	for _k in range(3):
		_prov.deliver(tok, {"outcome": "completed", "verified": true})
	_ok(e.reward.applied_transaction_count() == tx1 + 2 and not ra.is_busy(), "Rewarded Ads: 3 duplicate deliveries -> one grant, popup usable")
	_stack().clear("test")
	await _frames(3)
	# Exchange-all inside Collection: 20 taps -> one exchange.
	var ids_c: Array = e.collection.all_card_ids()
	for i in range(6):
		e.collection.add_copies(ids_c[i], 3)
	var sb2: int = e.wallet.scrub_bucks()
	var tx2: int = e.reward.applied_transaction_count()
	var oks := 0
	for _k in range(20):
		if _app().actions.exchange_all_extras().get("ok", false):
			oks += 1
	_ok(oks == 1 and e.wallet.scrub_bucks() > sb2 and e.reward.applied_transaction_count() == tx2 + 1, "Exchange-all: 20 taps -> one exchange")
	await _drain_all()   # the earned pack (Rewarded Ads bundle) presents on the quiet Home
	_free_home(await _quiet(), "018 purchase spam")
	_completed["018_purchase_reward_spam"] = true

func _ceremony_pack_spam() -> void:
	print("[018 spam ceremony CTAs, shortcuts over a ceremony, Gift claim and pack taps]")
	await _boot(1, 1000)
	var e = _e()
	var occ: Array = e.gift.add_streak_sb("streak:chaos:gift", 10)
	var truth0 := _truth(["meta_ui"])
	_root.request_home_ceremonies()
	await _frames(4)
	var shown: Array = []
	var over_bad := 0
	for _i in range(20):
		var p = _top()
		if p == null:
			break
		if not String(p.popup_id).begins_with("ceremony_"):
			break
		shown.append(String(p.popup_id) + ":" + str(p.get_instance_id()))
		# Hostile taps behind / over the ceremony: shortcuts, nav, Heart +.
		var d0: int = _stack().depth()
		for id in ["shop", "collection", "events", "robots"]:
			_open(id)
		if _stack().depth() != d0:
			over_bad += 1
		var cta: Button = p.get_action_button(p.get_action_ids()[0])
		for _k in range(20):
			cta.pressed.emit()
		await _frames(4)
	_ok(shown.size() >= 2 and over_bad == 0, "%d gift ceremonies shown one at a time; shortcuts / nav over a ceremony opened nothing" % shown.size())
	var uniq := {}
	for s in shown:
		uniq[s] = true
	_ok(uniq.size() == shown.size() and _top() == null, "20 CTA taps per ceremony acknowledged each exactly once; none left")
	_ok(_truth(["meta_ui"]) == truth0, "ceremonies changed no authority truth (only the presentation ledger)")
	# Gift Bar claim spam -> one claim, one earned pack ceremony; pack tap spam -> one commit.
	var m10 := ""
	for o in occ:
		if int(o["milestone"]) == 10:
			m10 = String(o["id"])
	var copies0 := _copies()
	_open("gift_bar")
	var gb = _top()
	await create_timer(0.45).timeout
	for _k in range(20):
		gb.get_action_button("gift:" + m10).pressed.emit()
	await _frames(4)
	var pk = _top()
	_ok(pk != null and String(pk.popup_id) == "standard_pack" and _stack().depth() == 2, "Gift claim x20 -> one standard pack ceremony over the Gift Bar %s" % str(_stack().ids()))
	if pk != null and String(pk.popup_id) == "standard_pack":
		var why := await _drive_pack(pk, 25)
		_ok(why.is_empty(), "pack tapped 25x per frame through open / reveal / route closes %s" % why)
	_ok(_copies() == copies0 + 3 and e.pending_packs.size() == 0, "exactly one pack committed: +3 cards (%d), no pending pack" % (_copies() - copies0))
	_stack().clear("test")
	await _drain_all()
	_free_home(await _quiet(), "018 ceremony spam")
	_completed["018_ceremony_pack_spam"] = true

func _copies() -> int:
	var n := 0
	for id in _e().collection.all_card_ids():
		n += _e().collection.owned(id)
	return n

# ================================================================ SB-M55-019 ====

func _bg_gameplay() -> void:
	print("[019 background / foreground mid-gameplay with bots in flight (L1), then WON once]")
	await _boot(1)
	var lap: Array = []
	for rep in range(2):
		_ok(_root.play_current_frontier().get("ok", false), "lap %d: PLAY" % (rep + 1))
		await _frames(2)
		var host = _root.get_gameplay_host()
		var d := _driver(host)
		var terminals: Array = []
		host.get_completion().terminal_reached.connect(func(s, _d): terminals.append(String(s)))
		for _i in range(600):
			if _moving(host) > 0:
				break
			_step(d, 1.0 / 30.0)
		var moving := _moving(host)
		get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
		var frozen: bool = host.get_runtime().is_paused()
		for _i in range(60):
			host.get_runtime().tick(1.0 / 30.0)
		await _bg_cycle()
		_ok(moving > 0 and frozen and not host.get_runtime().is_paused(), "lap %d: %d bots in flight; background suspended, foreground resumed" % [rep + 1, moving])
		var sb0: int = _e().wallet.scrub_bucks()
		var tp := Time.get_ticks_msec()
		var st := _play_out(host, d)
		print("    lap %d: play-out %d ms, %d clicks" % [rep + 1, Time.get_ticks_msec() - tp, d["i"]])
		await _frames(4)
		_ok(st == "WON" and terminals == ["WON"] and _nav().current() == R.HOME, "lap %d: attempt reached one WON -> Home (SB-PHONE-2026-11-12-E) %s" % [rep + 1, str(terminals)])
		var sb1: int = _e().wallet.scrub_bucks()
		_ok((sb1 > sb0) == (rep == 0), "lap %d: first-clear reward granted once per level (lap 2 = repeat clear, no reward)" % (rep + 1))
		await _bg_cycle()
		_ok(_e().wallet.scrub_bucks() == sb1 and terminals.size() == 1, "lap %d: background over the win's Home grants nothing more" % (rep + 1))
		await _drain_all()
		lap.append(await _quiet())
		_free_home(lap[rep], "019 gameplay lap %d" % (rep + 1))
		# Lap 2 replays L1 (a non-progression replay: no reward, same workload shape).
		_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 1, "completed": []})
	_no_leak(lap[0], lap[1], "019 gameplay")
	_completed["019_bg_gameplay"] = true

func _bg_results_video() -> void:
	print("[019 background / focus loss during the win's Home reward flight, resize, refresh]")
	await _boot(1)
	_root.play_current_frontier()
	await _frames(2)
	var st := _play_out(_root.get_gameplay_host())
	var home = _root.get_home()
	await _frames(2)
	var truth0 := _truth()
	var log0: int = _root.feel.dispatch_log().size()
	var revealing: bool = home.is_reward_flight_running()
	await _bg_cycle(6)
	_sub.size = Vector2i(1536, 2048)
	await _frames(4)
	_sub.size = Vector2i(1080, 2160)
	await _bg_cycle(6)
	for _f in range(900):
		if not home.is_reward_flight_running():
			break
		await process_frame
	_ok(st == "WON" and revealing and not home.is_reward_flight_running(), "WON -> Home: the reward flight was running at background and completed after resume")
	_ok(_truth() == truth0, "background / resize during the flight changed no authority truth")
	var keys: Array = _root.feel.dispatch_log().map(func(x): return String(x[1])).filter(func(k): return not k.is_empty())
	var dup: Array = keys.filter(func(k): return keys.count(k) > 1)
	_ok(dup.is_empty() and _root.feel.dispatch_log().size() >= log0, "no one-shot feel key replayed by background / resize %s" % str(dup))
	_ok(_max_playing <= 1, "at most one video decoder playing at any frame (max %d)" % _max_playing)
	await _drain_all()
	var s := await _quiet()
	_free_home(s, "019 win Home")
	_ok(s["decoders"] == 0 and s["emitters"] == 0, "videos and reward bursts released at HOME")
	_completed["019_bg_results_video"] = true

func _bg_rewarded_purchase() -> void:
	print("[019 background with a rewarded video pending and a purchase confirmation open]")
	await _boot(1, 5000)
	var e = _e()
	e.hearts.consume()
	e.hearts.consume()
	var p = _root.open_life("chaos")
	p.get_action_button("watch").pressed.emit()
	var tok: String = _prov.last_token()
	_ok(p.is_busy() and e.rewarded.is_pending(tok), "Life watch: provider request pending, popup busy")
	await _bg_cycle()
	await _bg_cycle()
	_ok(p.is_open() and p.is_busy() and e.hearts.hearts() == 3, "background / foreground: popup still pending, nothing granted yet")
	_prov.deliver(tok, {"outcome": "completed", "verified": true})
	_prov.deliver(tok, {"outcome": "completed", "verified": true})
	_ok(e.hearts.hearts() == 4 and not p.is_busy(), "delivery after resume: exactly one Heart; duplicate ignored; popup usable")
	var app2 = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(app2.economy.hearts.hearts() == 4, "the rewarded grant is durable (relaunch reads 4 Hearts)")
	p.close("test")
	await _frames(3)
	# Purchase confirmation open across background: still there, confirm buys once.
	_open("shop")
	_top().get_action_button("buy:booster:selector").pressed.emit()
	var conf = _top()
	var sb0: int = e.wallet.scrub_bucks()
	var ch0: int = e.boosters.charges(BoosterInventory.SELECTOR)
	await _bg_cycle()
	_ok(_stack().ids() == ["shop", "shop_confirm"] and conf.is_top() and e.wallet.scrub_bucks() == sb0, "confirmation survives background untouched (no spend)")
	conf.get_action_button("confirm").pressed.emit()
	await _bg_cycle()
	_ok(e.boosters.charges(BoosterInventory.SELECTOR) == ch0 + 1 and e.wallet.scrub_bucks() == sb0 - int(e.config.booster_price(BoosterInventory.SELECTOR)),
		"confirm after resume: one Selector, one debit; background after it changes nothing")
	var app3 = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(app3.economy.wallet.scrub_bucks() == e.wallet.scrub_bucks() and app3.economy.boosters.charges(BoosterInventory.SELECTOR) == ch0 + 1,
		"background flush persisted the purchase exactly (no cloud transport exists: the local save is the sync boundary)")
	_stack().clear("test")
	_free_home(await _quiet(), "019 rewarded / purchase")
	_completed["019_bg_rewarded_purchase"] = true

func _bg_pack_robot() -> void:
	print("[019 background mid pack reveal and over the Robot Unlock ceremony]")
	await _boot(25, 0)
	var e = _e()
	var occ: Array = e.gift.add_streak_sb("streak:chaos:bg", 10)
	await _drain_all_ceremonies_only()
	var copies0 := _copies()
	_open("gift_bar")
	await create_timer(0.45).timeout
	_top().get_action_button("gift:" + String(occ.filter(func(o): return int(o["milestone"]) == 10)[0]["id"])).pressed.emit()
	await _frames(4)
	var pk = _top()
	var why := "no pack"
	if pk != null and String(pk.popup_id) == "standard_pack":
		why = await _drive_pack(pk, 1, func():
			await _bg_cycle(6)
			await _bg_cycle(2))
	_ok(why.is_empty() and _copies() == copies0 + 3 and e.pending_packs.size() == 0, "pack backgrounded twice mid-OPENING still closes with exactly one commit (+%d cards) %s" % [_copies() - copies0, why])
	_stack().clear("test")
	await _frames(3)
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	var parts0: int = e.wallet.bot_parts()
	_ok(_app().actions.unlock_next_robot().get("ok", false), "Robot unlock committed")
	var parts1: int = e.wallet.bot_parts()
	_root.request_home_ceremonies()
	await _frames(4)
	var cer = _top()
	var robot_open: bool = cer != null and String(cer.popup_id) == "ceremony_robot_unlock"
	await _bg_cycle()
	await _bg_cycle()
	_ok(robot_open and _top() == cer and cer.is_open(), "Robot Unlock ceremony survives two background cycles on top")
	await _drain_all()
	_ok(e.robots.active_robot() == "moppy" and e.wallet.bot_parts() == parts1 and parts1 < parts0, "unlock debited once, ceremony equip applied, nothing replayed")
	_free_home(await _quiet(), "019 pack / robot")
	_completed["019_bg_pack_robot"] = true

func _drain_all_ceremonies_only() -> void:
	_root.request_home_ceremonies()
	await _frames(4)
	for _i in range(30):
		var p = _top()
		if p == null or not String(p.popup_id).begins_with("ceremony_"):
			return
		p.get_action_button(p.get_action_ids()[0]).pressed.emit()
		await _frames(4)

# ================================================================ SB-M55-020 ====

func _triple_loss() -> void:
	print("[020 three losses in a row with restart / exit mixtures -> Need a Hand exactly once]")
	await _boot(2, 5000)
	var e = _e()
	var assist = _app().assist
	var trig: int = assist.trigger
	_ok(trig == 3, "configured trigger is 3 failures")
	var shown := [0]
	_stack().top_changed.connect(func(p): if p != null and String(p.popup_id) == "need_a_hand": shown[0] += 1)
	var hearts0: int = e.hearts.hearts()
	# Loss 1 (duplicate terminal emits) -> Retry from Results.
	_root.play_current_frontier()
	await _frames(3)
	var host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	host.get_input_controller().activate_front(0)
	host.get_completion().terminal_reached.emit(&"LOST", {})
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(3)
	_ok(assist.state()["count"] == 1 and e.hearts.hearts() == hearts0 - 1 and shown[0] == 0, "loss 1 (terminal emitted twice): count 1, one Heart, no Need a Hand")
	var retries := 0
	for _k in range(5):
		if _root.retry_from_results():
			retries += 1
	await _frames(3)
	_ok(retries == 1 and _nav().current() == R.GAMEPLAY and e.hearts.hearts() == hearts0 - 1, "5 rapid Retry taps -> one Retry, no second Heart")
	# Pre-action back exit + re-PLAY in between (neither counts).
	_ok(_root.handle_back() == "home", "pre-action back exits to HOME")
	await _frames(3)
	_root.play_current_frontier()
	await _frames(3)
	host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	host.get_input_controller().activate_front(0)
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(3)
	_ok(assist.state()["count"] == 2 and shown[0] == 0, "loss 2 after a retry + pre-action exit: count 2, still no Need a Hand")
	# Exit to Home via Results, re-PLAY the same frontier, post-action Pause -> Home (exit, no count), PLAY, loss 3.
	_root.get_results_screen().get_home_button().pressed.emit()
	await _frames(3)
	_root.play_current_frontier()
	await _frames(3)
	host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	host.get_input_controller().activate_front(0)
	var ex: Dictionary = host.exit_to_home()
	_root._on_gameplay_home_requested(ex, host)
	await _frames(3)
	_ok(_nav().current() == R.HOME and assist.state()["count"] == 2, "post-action Pause -> Home is an exit, not a failure (count 2)")
	_root.play_current_frontier()
	await _frames(3)
	host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	host.get_input_controller().activate_front(0)
	host.get_completion().terminal_reached.emit(&"LOST", {})
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(4)
	var nah = _root.get_acquisition().find_open("need_a_hand")
	_ok(assist.state()["count"] == 3 and nah != null and shown[0] == 1, "loss 3: Need a Hand opened exactly once (%d)" % shown[0])
	await _bg_cycle()
	_root.get_results_screen().show_model(_root.get_results_screen().get_model())
	_ok(shown[0] == 1 and _stack().depth() == 1, "background + Results re-show do not reopen Need a Hand")
	_root.handle_back()
	await _frames(3)
	for _k in range(5):
		_root.retry_from_results()
	await _frames(3)
	host = _root.get_gameplay_host()
	host.get_input_controller().activate_front(0)
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(4)
	_ok(assist.state()["count"] == 4 and shown[0] == 1, "loss 4 is suppressed (no second Need a Hand)")
	_ok(e.hearts.hearts() >= 0 and hearts0 - e.hearts.hearts() == mini(hearts0, 5), "Hearts: 4 losses + 1 post-action exit consumed exactly %d (capped at 0)" % mini(hearts0, 5))
	_stack().clear("test")
	_nav().go(R.HOME, {"via": "test"})
	_free_home(await _quiet(), "020 losses")
	_completed["020_triple_loss"] = true

# ================================================================ SB-M55-021 ====

func _nav_churn() -> void:
	print("[021 BottomNav churn 2 x 200 while badges / rewards update]")
	await _boot(30, 1000)
	var home = _root.get_home()
	var e = _e()
	var tabs := ["events", "robots", "leaderboard", "settings", "home"]
	var cards: Array = e.collection.all_card_ids()
	var lap: Array = []
	for rep in range(2):
		var bad: Array = []
		for i in range(200):
			var id: String = tabs[i % tabs.size()]
			var b: Button = home.find_child("SettingsButton" if id == "settings" else "Nav_" + id, true, false)
			for _k in range(3):
				b.pressed.emit()
			# Badges / rewards change underneath (wallet, cards = Collection badge, a robot's parts).
			e.wallet.credit(EconomyWallet.SCRUB_BUCKS, 1)
			e.collection.add_copies(cards[(i + rep * 200) % cards.size()], 1)
			home.refresh()
			var want := 0 if id == "home" or id == "settings" else 1
			if _stack().depth() != want or (id == "settings") != _nav().is_settings_open():
				bad.append([i, id, _stack().ids(), _nav().is_settings_open()])
			if i % 10 == 0:
				await process_frame
			_root.handle_back()
			if _stack().depth() != 0 or _nav().is_settings_open():
				bad.append([i, id, "after back", _stack().ids()])
				_stack().clear("test")
		await _drain_all()
		_ok(bad.is_empty(), "lap %d: 200 tab switches (3 taps each) -> one destination each, back closes it %s" % [rep + 1, str(bad.slice(0, 4))])
		lap.append(await _quiet())
		_free_home(lap[rep], "021 lap %d" % (rep + 1))
	_no_leak(lap[0], lap[1], "021 BottomNav churn")
	_completed["021_nav_churn"] = true

# ================================================================ SB-M55-022 ====

func _huge_inventory() -> void:
	print("[022 huge inventories: SB / Bot Parts / boosters / every card x999]")
	await _boot(30, 1000)
	var e = _e()
	var surfaces := ["shop", "collection", "profile", "robots", "daily", "tasks", "gift_bar", "rewarded_ads", "events", "leaderboard"]
	var base_fit := await _fit_report(surfaces)
	e.wallet.credit(EconomyWallet.SCRUB_BUCKS, 999_999_000)
	e.wallet.credit(EconomyWallet.BOT_PARTS, 9_999_999)
	for b in BoosterInventory.BOOSTERS:
		e.boosters.add_charges(b, 9_999)
	for id in e.collection.all_card_ids():
		e.collection.add_copies(id, 999)
	_root.get_home().refresh()
	await _frames(3)
	var huge_fit := await _fit_report(surfaces)
	var grew: Array = []
	for k in huge_fit:
		for n in huge_fit[k]:
			if not (base_fit.get(k, []) as Array).has(n):
				grew.append("%s/%s" % [k, n])
	_ok(grew.is_empty(), "huge values add no clipped / off-screen label on Home or any destination popup %s" % str(grew))
	# Collection churn: album -> every set -> card -> back, 2 laps; memory must settle.
	var lap: Array = []
	for rep in range(2):
		var t0 := Time.get_ticks_msec()
		for _r in range(3):
			_open("collection")
			var album = _top()
			for n in range(1, 16):
				album.get_action_button("set:%d" % n).pressed.emit()
				var set_p = _top()
				if set_p != null and String(set_p.popup_id) == "collection_set":
					var ids: Array = set_p.get_action_ids().filter(func(a): return String(a).begins_with("card:"))
					if not ids.is_empty():
						set_p.get_action_button(ids[0]).pressed.emit()
						await process_frame
						_stack().close_top("test")
					set_p.close("test")
				await process_frame
				album.rearm()
			album.close("test")
			await _frames(2)
		var s := await _quiet()
		s["static_mem"] = int(Performance.get_monitor(Performance.MEMORY_STATIC))
		s["textures"] = int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
		s["ms"] = Time.get_ticks_msec() - t0
		lap.append(s)
		_free_home(s, "022 lap %d" % (rep + 1))
	print("    collection laps: %s" % str(lap.map(func(x): return [x["nodes"], x["static_mem"], x["textures"], x["ms"]])))
	_no_leak(lap[0], lap[1], "022 Collection churn")
	_ok(lap[1]["static_mem"] - lap[0]["static_mem"] <= 4 * 1024 * 1024 and lap[1]["textures"] <= lap[0]["textures"] + 1024 * 1024,
		"static memory (+%d B) and texture memory (+%d B) settle across Collection laps" % [lap[1]["static_mem"] - lap[0]["static_mem"], lap[1]["textures"] - lap[0]["textures"]])
	_ok(lap[1]["ms"] < 20000, "3 x 15 sets with 999-copy cards render in %d ms" % lap[1]["ms"])
	# Exchange-all on the huge inventory: one exchange, exact SB, int stays exact.
	var expected := 0
	for id in e.collection.all_card_ids():
		expected += (e.collection.owned(id) - 1) * e.exchange.card_value(id)
	var sb0: int = e.wallet.scrub_bucks()
	var oks := 0
	for _k in range(10):
		if _app().actions.exchange_all_extras().get("ok", false):
			oks += 1
	_ok(oks == 1 and e.wallet.scrub_bucks() == sb0 + expected, "Exchange-all on ~%d extras: one exchange, +%d SB exactly" % [e.collection.all_card_ids().size() * 999, expected])
	_completed["022_huge_inventory"] = true

## Per surface: names of visible labels that are clipped or leave the viewport.
func _fit_report(surfaces: Array) -> Dictionary:
	var out := {"home": _overflow(_root.get_home())}
	for id in surfaces:
		_open(id)
		await _frames(3)
		var p = _top()
		out[id] = _overflow(p) if p != null else ["<not opened>"]
		_stack().clear("test")
		await _frames(2)
	return out

func _overflow(n: Node) -> Array:
	var vp := Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(1.0)
	var bad: Array = []
	for l in n.find_children("*", "Label", true, false):
		var lb := l as Label
		if not lb.is_visible_in_tree() or lb.text.is_empty() or lb.clip_text or lb.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			continue
		var m := lb.get_minimum_size()
		var clipped: bool = lb.autowrap_mode == TextServer.AUTOWRAP_OFF and m.x > lb.size.x + 0.5
		var scrolled := false
		var a := lb.get_parent()
		while a != null and a != n and not scrolled:
			scrolled = a is ScrollContainer
			a = a.get_parent()
		# Scrolled rows may sit below the fold by design; they must still never clip.
		if clipped or (not scrolled and not vp.encloses(lb.get_global_rect())):
			bad.append(String(lb.get_path()).get_file() + "@" + String(lb.get_parent().name))
	return bad

# ================================================================ SB-M55-023 ====

func _timer_expiry() -> void:
	print("[023 Heart / timed 2x / Daily / Event / comeback timers expire while their screens are open]")
	await _boot(2, 20000)
	var e = _e()
	# Hearts: Life popup open across +899 / +1 / rollback.
	e.hearts.consume()
	e.hearts.consume()
	var life = _root.open_life("chaos")
	var tick: Timer = life.find_child("LiveRefresh", true, false)
	_now[0] += 899
	tick.timeout.emit()
	var tv: Label = life.find_child("TimerValue", true, false)
	_ok(e.hearts.hearts() == 3 and tv.text == "00:01", "Life open: +899 s shows 00:01, still 3 Hearts")
	_now[0] += 1
	tick.timeout.emit()
	_ok(e.hearts.hearts() == 4 and (life.find_child("HeartCount", true, false) as Label).text == "4", "Life open: +1 s regenerates exactly one Heart, popup shows 4")
	_now[0] -= 3600
	tick.timeout.emit()
	_ok(e.hearts.hearts() == 4, "clock rolled back 1 h with Life open: no Heart gained or lost")
	_now[0] += 3600
	life.close("test")
	await _frames(2)
	# Timed 2x in gameplay: expires on the HUD tick; rollback keeps it expired.
	_ok(_app().actions.buy_timed_2x(900).get("ok", false), "timed 2x (15 min) bought")
	_root.play_current_frontier()
	await _frames(3)
	var host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var hud: Timer = host.find_child("HudTimer", true, false)
	hud.timeout.emit()
	var scr = host.get_screen()
	_ok(scr.get_speed_mode() == "timed" and host.get_runtime().is_2x(), "gameplay starts at timed 2x")
	_now[0] += 901
	hud.timeout.emit()
	_ok(scr.get_speed_mode() != "timed" and not host.get_runtime().is_2x() and e.speed.timed_seconds_remaining() == 0, "+901 s mid-level: timed 2x expired on the HUD tick, gameplay back to 1x")
	_now[0] -= 5000
	hud.timeout.emit()
	_ok(e.speed.timed_seconds_remaining() == 0 and scr.get_speed_mode() != "timed", "clock rolled back 5000 s: expired 2x stays expired")
	_now[0] += 5000
	_ok(_root.handle_back() == "home", "pre-action exit")
	await _frames(3)
	# Shop open while a timed 2x expires: refresh shows no active timer, buying again works once.
	_app().actions.buy_timed_2x(900)
	_open("shop")
	var shop = _top()
	var detail: Label = shop.find_child("Item_speed_900", true, false).find_child("Detail", true, false)
	var active_txt := detail.text
	_now[0] += 900
	await create_timer(0.45).timeout
	shop.get_action_button("buy:speed:900").pressed.emit()
	var conf = _top()
	var sb0: int = e.wallet.scrub_bucks()
	conf.get_action_button("confirm").pressed.emit()
	await _frames(2)
	_ok(not active_txt.is_empty() and e.speed.timed_seconds_remaining() == 900 and e.wallet.scrub_bucks() < sb0,
		"Shop open across expiry: next purchase starts a fresh 900 s (not stacked on the expired one)")
	_stack().clear("test")
	await _frames(2)
	# Daily rollover with the Daily popup open: stale view, exactly one claim per local day.
	_open("daily")
	var daily = _top()
	daily.get_action_button("claim").pressed.emit()
	await _frames(2)
	_stack().close_top("test")
	var tx0: int = e.reward.applied_transaction_count()
	_day[0] += 1
	await create_timer(0.45).timeout
	for _k in range(10):
		daily.get_action_button("claim").pressed.emit()
	_ok(e.reward.applied_transaction_count() == tx0, "Daily open across midnight: the stale view stays CLAIMED and grants nothing")
	_stack().clear("test")
	await _frames(2)
	_open("daily")
	daily = _top()
	for _k in range(10):
		daily.get_action_button("claim").pressed.emit()
	await _frames(2)
	_ok(e.reward.applied_transaction_count() == tx0 + 1, "reopened after midnight: the new day's claim commits exactly once")
	_stack().clear("test")
	_day[0] -= 1
	_open("daily")
	_ok(_top().get_action_button("claim").disabled, "local day rolled back: nothing claimable again")
	_stack().clear("test")
	_day[0] += 1
	await _drain_all()   # the Day-2 bundle's earned pack presents on the quiet Home
	# Weekly event expiring with the Events screen open (fixture config, forfeit policy).
	var ev_path := _write_event_fixture(_now[0] - 7 * 86400 + 30)
	e.events.load_config(ev_path)
	e.events.import_snapshot({"version": 1, "weekly": {"chaos_week": {"progress": 5, "claimed": []}}, "first_try": {}})
	_open("events")
	var evp = _top()
	var claim_b: Button = evp.get_action_button("ev:chaos_week:0")
	_ok(claim_b != null and not claim_b.disabled, "Events open: milestone claimable before expiry %s %s" % [str(_stack().ids()), str(e.events.list())])
	_now[0] += 60
	var tx1: int = e.reward.applied_transaction_count()
	for _k in range(10):
		claim_b.pressed.emit()
	await _frames(2)
	_ok(e.reward.applied_transaction_count() == tx1 and e.events.list().is_empty(), "stale claim after expiry (forfeit) grants nothing; event no longer listed")
	_ok(evp.find_child("EmptyCard", true, false) != null, "Events screen refreshed to the empty state")
	_stack().clear("test")
	e.events.load_config("res://data/config/events_v1.json")
	await _frames(2)
	# Comeback window: 49 h absence while the Shop is open -> summary once, after the Shop closes.
	_open("shop")
	get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_now[0] += 49 * 3600
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	await _frames(3)
	_ok(_stack().ids() == ["shop"] and e.returns.summary_due(), "49 h absence: window opened, summary waits behind the open Shop")
	_stack().clear("test")
	await _frames(4)
	var shown_cb: bool = _top() != null and String(_top().popup_id) == "comeback"
	await _drain_all()
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	_root.request_home_ceremonies()
	await _frames(4)
	_ok(shown_cb and _top() == null, "comeback summary shown once; a second resume / drain shows nothing")
	_free_home(await _quiet(), "023 timers")
	_completed["023_timer_expiry"] = true

func _write_event_fixture(start_ts: int) -> String:
	var p := "user://m55_chaos_events_%d.json" % Time.get_ticks_usec()
	_tmp.append(p)
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.events.v1", "version": 1,
		"approved_reward_types": ["scrub_bucks", "bot_parts"],
		"weekly_events": [{"id": "chaos_week", "start_ts": start_ts, "unclaimed_on_expiry": "forfeit",
			"milestones": [{"target": 3, "reward": {"scrub_bucks": 50}}]}], "first_try_cleanup": null}))
	f.close()
	return p

# ================================================================ SB-M55-024 ====

func _flapping() -> void:
	print("[024 offline / online flapping: rewarded provider + remote content transport under open surfaces]")
	await _boot(30, 5000)
	var e = _e()
	var content = _app().content
	var ft := FlapTransport.new()
	content.enabled = true
	content.game_version = "1.0.0"
	content.transport = ft
	var launch0: Dictionary = preload("res://scripts/app/gameplay_launch_resolver.gd").resolve(_app())
	var grants := 0
	var completions := 0
	var refreshes := 0
	var status_bad: Array = []
	for id in ["shop", "events", "leaderboard", "rewarded_ads", "life"]:
		e.hearts.import_snapshot({"hearts": 3, "anchor": _now[0]})
		_open(id)
		var p = _top()
		var truth0 := _truth()
		for i in range(30):
			_prov.available = i % 2 == 0
			ft.online = i % 3 == 0
			var r: Dictionary = await content.refresh()
			refreshes += 1
			var want := "failed_using_cache" if ft.online else "offline_using_cache"
			if r.get("ok", false) or String(content.status()["status"]) != want:
				status_bad.append([id, i, r.get("reason", ""), content.status()["status"]])
			var live: Timer = p.find_child("LiveRefresh", true, false)
			if live != null:
				live.timeout.emit()   # the popup's own 1 s redraw re-reads provider availability
			if p.get_action_button("watch") != null and not p.is_busy():
				p.get_action_button("watch").pressed.emit()
				if p.is_busy():
					var tok: String = _prov.last_token()
					var outcome := "completed" if i % 4 == 0 else "failed"
					if outcome == "completed":
						completions += 1
					var before: int = e.hearts.hearts()
					_prov.deliver(tok, {"outcome": outcome, "verified": true})
					if e.hearts.hearts() != before:
						grants += 1
				p.rearm()
			await process_frame
		if id != "life":
			_ok(_truth() == truth0, "%s open through 30 offline / online flips: authority truth unchanged" % id)
		_stack().clear("test")
		await _frames(2)
	_ok(status_bad.is_empty(), "every offline refresh -> offline_using_cache, every online (rejected) one -> failed_using_cache, none activated %s" % str(status_bad.slice(0, 4)))
	_ok(ft.calls == refreshes and preload("res://scripts/app/gameplay_launch_resolver.gd").resolve(_app()) == launch0,
		"%d flapping refreshes: builtin launch truth identical, nothing installed" % refreshes)
	_ok(grants >= 1 and grants == completions, "Life watch under provider flapping: exactly the %d completed+verified deliveries granted (%d)" % [completions, grants])
	_prov.available = true
	content.enabled = false
	content.transport = null
	_ok(_root.flush_lifecycle("test").get("ok", false), "lifecycle flush ok")
	var app2 = AppState.new(MainScript.boot_save_path_override, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(app2.economy.wallet.scrub_bucks() == e.wallet.scrub_bucks() and app2.economy.hearts.hearts() == e.hearts.hearts(), "persisted save matches live state after the flapping session")
	_free_home(await _quiet(), "024 flapping")
	_completed["024_flapping"] = true

# ================================================================ SB-M55-025 ====

func _plugin_chaos() -> void:
	print("[025 presentation-plugin chaos: removed / faulting / absent plugins, Reduced toggles, route churn]")
	await _boot(1)
	var app = _app()
	var spark = get_root().get_node_or_null("Spark")
	var gff = get_root().get_node_or_null("GameFeelFlow")
	_ok(spark != null and gff != null, "both installed plugin autoloads present")
	var lap: Array = []
	for rep in range(2):
		# WON -> Home with real plugins; mid reward flight: Spark removed, Reduced toggled 10x, background.
		_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 1, "completed": []})
		_e().hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
		_root.feel._use_override = false   # real installed plugins
		_root.play_current_frontier()
		await _frames(2)
		var st := _play_out(_root.get_gameplay_host())
		await _frames(3)
		var truth0 := _truth()
		get_root().remove_child(spark)
		for i in range(10):
			app.set_reduced_effects(i % 2 == 0)
			await process_frame
		app.set_reduced_effects(false)
		await _bg_cycle()
		get_root().add_child(spark)
		for _f in range(900):
			if not _root.get_home().is_reward_flight_running():
				break
			await process_frame
		_ok(st == "WON" and _truth() == truth0, "lap %d: Spark removed + 10 Reduced toggles + background mid reward flight: authority truth unchanged" % (rep + 1))
		# Faulting Spark through the Gift ceremonies (labelled injection), then plugins absent.
		await _drain_all()
		var faulty := FaultySpark.new()
		_root.feel.set_backends_for_test(null, faulty)
		print("  EXPECTED_FAULT_INJECTION: 025 lap %d: every Spark burst raises one SCRIPT ERROR ('explode' on null) inside a spy plugin" % (rep + 1))
		var truth1 := _truth(["meta_ui", "gift"])
		_e().gift.add_streak_sb("streak:chaos:plugin:%d" % rep, [10, 15][rep])   # milestones 1/5/10, then 25
		_root.request_home_ceremonies()
		await _frames(3)
		var n_cer := 0
		for _i in range(20):
			var p = _top()
			if p == null or not String(p.popup_id).begins_with("ceremony_"):
				break
			n_cer += 1
			if n_cer == 2:
				_root.feel.set_backends_for_test(null, null)   # plugin vanishes mid-sequence
			p.get_action_button(p.get_action_ids()[0]).pressed.emit()
			await _frames(4)
		_ok(n_cer >= 1 and _truth(["meta_ui", "gift"]) == truth1, "lap %d: %d ceremonies completed with a throwing then absent Spark; truth unchanged (%d faults)" % [rep + 1, n_cer, faulty.calls])
		_root.feel._use_override = false
		# Route churn: PLAY / pre-action back x10 with resize.
		_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 2, "completed": [1]})
		for k in range(10):
			_root.play_current_frontier()
			await process_frame
			_sub.size = Vector2i(1080, 2160) if k % 2 == 0 else Vector2i(1536, 2048)
			_root.handle_back()
			await process_frame
		_sub.size = Vector2i(1080, 2160)
		_stack().clear("test")
		await _drain_all()
		var keys: Array = _root.feel.dispatch_log().map(func(x): return String(x[1])).filter(func(k): return not k.is_empty())
		var dup: Array = keys.filter(func(k): return keys.count(k) > 1)
		_ok(dup.is_empty(), "lap %d: no one-shot celebration key requested twice through the chaos %s" % [rep + 1, str(dup.slice(0, 4))])
		await create_timer(1.5).timeout   # > every DURATION_CEILING_S
		lap.append(await _quiet())
		_free_home(lap[rep], "025 lap %d" % (rep + 1))
	_no_leak(lap[0], lap[1], "025 plugin chaos")
	_ok(spark.is_inside_tree() and get_root().get_node_or_null("Spark") == spark, "Spark autoload restored")
	_completed["025_plugin_chaos"] = true

# ------------------------------------------------------------------ helpers ----

func _app():
	return _root.get_app_state()

func _e():
	return _app().economy

func _nav():
	return _root.get_navigation()

func _stack():
	return _root.get_modal_stack()

func _top():
	return _stack().top()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

## Authority truth: progression + economy sections (wall-clock anchors and `skip` sections excluded).
func _truth(skip: Array = []) -> Dictionary:
	var out := {"progression": JSON.stringify(_app().progression.snapshot())}
	var s: Dictionary = _e().snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	for k in s:
		if not skip.has(String(k)):
			out["economy." + String(k)] = JSON.stringify(s[k])
	return out

func _uniq(tag: String) -> String:
	var p := "user://m55_chaos_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	MainScript.boot_opening_override = -1
	MainScript.boot_ftue_override = -1
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
		_rm_tree(String(p).get_basename() + "_content/")

func _rm_tree(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_rm_tree(dir + sub + "/")
	DirAccess.remove_absolute(dir)

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
