extends SceneTree
## M43-C005F-PHASE3 — Meta Rewards + Acquisition Feel (SB-M43-C005F-006 / -008 / -009).
## Everything runs in the REAL app (main.tscn, 1080x2160 SubViewport) through shipping seams:
##   s*: F006 Collection set / Master ceremonies (CeremonyPresenter) -> REWARD / MAJOR_REWARD once;
##   d*: F008 Gift milestone ceremony, Gift claim, Daily login, Tasks, earned ScrubBox, no-spam;
##   a*: F009 Heart / Booster-charge / rewarded / gameplay booster-use success-only feel;
##   b*: boundary - adapter-only plugin access, no authority / durable state, Reduced = zero work.
## Plugin work is observed through FeedbackAdapter's test seam (spy backends) and its log.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase3_meta_rewards_acquisition.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")

class SpyGff extends RefCounted:
	var plays: Array = []
	func play(n, t, _o = {}) -> void:
		plays.append([n, t])
	func stop_all(_t = null) -> void:
		pass
	func get_effect_names() -> Array:
		return ["punch_scale"]

class SpySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	var bursts: Array = []   ## [preset-ish amount, lifetime]
	func burst(_pos, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func at(_n, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func clear() -> void:
		pass

class FaultySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	func burst(_p, _o = {}) -> void:
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see test log)
	func at(_n, _o = {}) -> void:
		pass
	func clear() -> void:
		pass

var EXPECTED_CASES := [
	"s01_set_complete_reward_once", "s02_master_major_reward_once", "s03_set_reduced_zero_plugin_work",
	"d01_gift_milestones_from_shown_events", "d02_gift_claim_after_commit_pack_serial", "d03_daily_login_committed_only",
	"d04_tasks_small_scrubbox_major_once", "d05_no_spam_refresh_reopen_resize",
	"a01_heart_purchase_success_only", "a02_booster_charge_success_only", "a03_rewarded_verified_only_once",
	"a04_plugins_missing_or_throwing", "a05_gameplay_booster_use",
	"b01_static_boundary", "b02_reduced_zero_plugin_work_claims",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _gff: SpyGff
var _spark: SpySpark
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _s01(); await _s02(); await _s03()
	await _d01(); await _d02(); await _d03(); await _d04(); await _d05()
	await _a01(); await _a02(); await _a03(); await _a04(); await _a05()
	_b01(); await _b02()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://c005f_p3_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _uniq(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	_spy()

func _spy() -> void:
	_gff = SpyGff.new()
	_spark = SpySpark.new()
	_root.feel.set_backends_for_test(_gff, _spark)

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

## SB-M39-054: the ScrubBox grants one charge of a random one of the four boosters.
func _all_charges() -> int:
	return ["plus_one_slot", "random", "selector", "tornado"].reduce(func(s, b): return s + _e().boosters.charges(b), 0)

func _e():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _log(child: String = "") -> Array:
	return _root.get_meta_reward_feel().feel_log().filter(func(r): return child.is_empty() or r[0] == child)

## Press an action button of the top popup once it is armed, then let the app react.
func _press(id: String, p = null) -> void:
	var pp = p if p != null else _top()
	await create_timer(0.45).timeout   # popups re-arm their CTAs shortly after open / an action
	pp.get_action_button(id).pressed.emit()
	await _frames(14)

func _econ() -> String:
	return JSON.stringify(_e().snapshot())

func _complete_set(n: int) -> void:
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if _e().collection.owned(cid) == 0:
			_e().collection.add_card(cid)

# ---------------------------------------------------------------- F006 ----

func _s01() -> void:
	print("[s01 F006 Set Complete: one REWARD request keyed by the canonical ceremony event]")
	await _boot("s01")
	_complete_set(1)
	var econ := _econ()
	_root.request_home_ceremonies()
	await _frames(14)
	var p = _top()
	_ok(p != null and String(p.popup_id) == "ceremony_set_complete", "shipping Set Complete ceremony on the app ModalStack")
	_ok(_log("F006") == [["F006", "REWARD", "c005f006:set:1", "HeroArt"]], "exactly one REWARD request on the hero, key c005f006:set:1 %s" % str(_log("F006")))
	_ok(_spark.bursts == [8] and _gff.plays.is_empty(), "plugin work: one pickup burst of 8 (REWARD ceiling); GFF never on a Control %s" % str(_spark.bursts))
	_ok(_econ() == econ, "economy byte-identical after the feel (rewards / Collection / acknowledgement untouched)")
	# repeats: pending(), drain(), Home refresh, resize, close without acknowledgement + re-show.
	_root.get_ceremonies().pending()
	_root.get_ceremonies().drain("home")
	_root.get_home().refresh()
	_sub.size = Vector2i(1536, 2048)
	await _frames(14)
	_sub.size = Vector2i(1080, 2160)
	await _frames(14)
	p.close("clear")   # a stack clear leaves the event pending -> shown again at the next drain
	await _frames(2)
	_root.request_home_ceremonies()
	await _frames(14)
	var shown: Array = _root.get_ceremonies().presented_log().filter(func(r): return r[0] == "set:1")
	_ok(shown.size() == 2 and _log("F006").size() == 1 and _spark.bursts == [8], "re-shown ceremony (2 presentations) never celebrates twice")
	await _press("continue")
	_ok(_e().meta_ui.seen_keys().has("set:1") and _log("F006").size() == 1, "acknowledged by its own CTA (authority unchanged); still one request")
	_complete("s01_set_complete_reward_once")

func _s02() -> void:
	print("[s02 F006 Master Collection: one MAJOR_REWARD, stronger than a set, below WIN]")
	await _boot("s02")
	var sb0: int = _e().wallet.scrub_bucks()
	for n in range(1, 16):
		_complete_set(n)
	for ev in CeremonyEvents.pending(_e(), _e().meta_ui):
		if String(ev["kind"]) != "master_complete":
			_e().meta_ui.mark_seen(String(ev["key"]))
	var econ := _econ()
	_root.request_home_ceremonies()
	await _frames(14)
	_ok(_top() != null and String(_top().popup_id) == "ceremony_master_complete", "shipping Master Collection ceremony")
	_ok(_log("F006") == [["F006", "MAJOR_REWARD", "c005f006:master", "HeroArt"]], "exactly one MAJOR_REWARD request, key c005f006:master")
	_ok(_spark.bursts == [14] and 8 < 14 and 14 < FeedbackAdapter.PARTICLE_CEILING["WIN"], "capped confetti 14 > set 8, < WIN 18")
	_ok(_econ() == econ and _e().wallet.scrub_bucks() - sb0 >= 2500, "economy unchanged by feel; Master +2500 SB came from the grant, once")
	_root.get_ceremonies().drain("home")
	_root.get_home().refresh()
	await _frames(14)
	_ok(_log("F006").size() == 1, "drain / refresh repeats: no second request")
	_complete("s02_master_major_reward_once")

func _s03() -> void:
	print("[s03 F006 Reduced: same ceremony truth, key consumed, zero plugin work, no settle]")
	await _boot("s03")
	_root.get_app_state().set_reduced_effects(true)
	_complete_set(2)
	_root.request_home_ceremonies()
	await _frames(14)
	var p = _top()
	var hero: Control = p.find_child("HeroArt", true, false)
	await create_timer(0.35).timeout
	_ok(_root.feel.has_played("c005f006:set:2") and _log("F006").size() == 1, "presentation key consumed under Reduced")
	_ok(_spark.bursts.is_empty() and _gff.plays.is_empty() and _root.feel.owned_count() == 0, "zero plugin work")
	_ok(hero.scale == Vector2.ONE and p.find_child("RewardRows", true, false).get_child_count() > 0 and p.find_child("Progress", true, false) != null, "static final state: no settle, reward rows + 9 / 9 readable")
	_root.get_app_state().set_reduced_effects(false)
	p.close("clear")
	await _frames(2)
	_root.request_home_ceremonies()
	await _frames(14)
	_ok(_log("F006").size() == 1 and _spark.bursts.is_empty(), "REDUCED -> FULL + re-show never replays it")
	_complete("s03_set_reduced_zero_plugin_work")

# ---------------------------------------------------------------- F008 ----

func _d01() -> void:
	print("[d01 F008 Gift milestones: only from shown canonical events; 1000 = MAJOR_REWARD]")
	await _boot("d01")
	var occ: Array = _e().gift.add_streak_sb("streak:p3:d01", 1000)
	_ok(occ.size() == 5 and _log("F008").is_empty(), "5 milestones reached; nothing celebrated before a ceremony is shown")
	_root.request_home_ceremonies()
	await _frames(14)
	for _i in range(5):
		var p = _top()
		if p == null or String(p.popup_id).begins_with("ceremony_gift") == false:
			break
		await _press("continue", p)
		await _frames(14)
	var got: Array = _log("F008").map(func(r): return r[1])
	_ok(got == ["REWARD", "REWARD", "REWARD", "REWARD", "MAJOR_REWARD"], "intents per milestone %s" % str(got))
	_ok(_log("F008").all(func(r): return String(r[2]).begins_with("c005f008:") and r[3] == "HeroArt"), "keys from the ceremony event key, hero target")
	_ok(_e().gift.gift_bar_queue().all(func(o): return not bool(o.get("claimed", false))) and _e().pending_packs.size() == 0, "feel claims nothing (all 5 still unclaimed in the Gift Bar)")
	_complete("d01_gift_milestones_from_shown_events")

func _d02() -> void:
	print("[d02 F008 Gift claim: feel only after action_committed; pack ceremony stays serial]")
	await _boot("d02")
	var occ: Array = _e().gift.add_streak_sb("streak:p3:d02", 10)
	_root.request_home_ceremonies()
	await _frames(14)
	await _close_ceremony_continue()
	var id := String(occ[0]["id"])
	_root._on_home_shortcut("gift_bar")
	await _frames(2)
	_ok(_log("F008").filter(func(r): return String(r[2]).contains("gift_claim")).is_empty(), "opening the Gift Bar: no claim feel")
	await _press("gift:" + id)
	var claims: Array = _log("F008").filter(func(r): return String(r[2]).contains("gift_claim"))
	_ok(claims == [["F008", "REWARD", "c005f008:gift_claim:" + id, "Hero"]], "one REWARD after the committed claim, keyed by the occurrence id")
	var p = _top()
	_ok(p != null and String(p.popup_id) == "standard_pack", "the earned Standard pack still opens after the claim (PackPresenter order unchanged)")
	var r: Dictionary = _root.get_app_state().actions.claim_gift(id)
	await _frames(14)
	_ok(not r["ok"] and _log("F008").filter(func(x): return String(x[2]).contains("gift_claim")).size() == 1, "duplicate claim refused (%s): zero feel" % r.get("reason", ""))
	p.tap()
	for _i in range(1500):
		if not is_instance_valid(p) or p.phase() == "AWAIT_ROUTE":
			break
		await process_frame
	p.tap()
	for _i in range(1500):
		if not is_instance_valid(p) or p.is_closed():
			break
		await process_frame
	await _frames(14)
	_ok(_e().pending_packs.size() == 0 and String(_top().popup_id) == "gift_bar", "pack opened, acknowledged; back on the Gift Bar")
	_complete("d02_gift_claim_after_commit_pack_serial")

func _close_ceremony_continue() -> void:
	for _i in range(6):
		var p = _top()
		if p == null or not String(p.popup_id).begins_with("ceremony_"):
			return
		await _press("continue", p)
		await _frames(14)

func _d03() -> void:
	print("[d03 F008 Daily login: after the committed claim only; refusals / rollback silent]")
	await _boot("d03")
	_root._on_home_shortcut("daily")
	await _frames(2)
	_ok(_log("F008").is_empty(), "opening Daily: no feel")
	await _press("claim")
	var p = _top()
	_ok(p != null and String(p.popup_id) == "ceremony_daily", "the claim's reward celebration popup")
	_ok(_log("F008") == [["F008", "REWARD", "c005f008:daily_login:%d" % _day[0], "Hero"]], "one REWARD on its hero, key = canonical local-day tx")
	var r: Dictionary = _root.get_app_state().actions.claim_daily_login()
	await _frames(14)
	_ok(not r["ok"] and _log("F008").size() == 1, "same-day claim refused (%s): zero feel" % r.get("reason", ""))
	await _press("ok", p)
	_top().close("test")
	await _frames(2)
	_root._on_home_shortcut("daily")
	await _frames(14)
	_ok(_log("F008").size() == 1, "reopening Daily: no replay")
	_top().close("test")
	_day[0] += 1
	_now[0] -= 100000   # the device clock went backwards
	r = _root.get_app_state().actions.claim_daily_login()
	await _frames(14)
	_ok(not r["ok"] and String(r["reason"]) == "clock_rollback" and _log("F008").size() == 1, "clock rollback refusal: zero feel")
	_day[0] -= 1
	_now[0] += 100000
	_complete("d03_daily_login_committed_only")

func _d04() -> void:
	print("[d04 F008 Tasks: SMALL per task (no confetti); earned ScrubBox: one MAJOR_REWARD]")
	await _boot("d04")
	for i in range(3):
		_e().daily.mark_task_done(i)
	_root._on_home_shortcut("tasks")
	await _frames(2)
	for i in range(3):
		await _press("task:%d" % i)
	var tasks: Array = _log("F008")
	_ok(tasks.size() == 3 and tasks.all(func(r): return r[1] == "SMALL") and tasks[0][2] == "c005f008:daily_task:%d:0" % _day[0] and tasks[2][3] == "Task_2", "3 claims -> 3 SMALL on the task rows, canonical tx keys")
	_ok(_spark.bursts == [4, 4, 4], "no confetti per task (spark 4 each) %s" % str(_spark.bursts))
	var rb0: int = _all_charges()
	await _press("scrubbox")
	var p = _top()
	_ok(p != null and String(p.popup_id) == "ceremony_scrubbox", "the shipping earned ScrubBox opened after the committed all-3 claim")
	var box: Array = _log("F008").filter(func(r): return r[1] == "MAJOR_REWARD")
	_ok(box == [["F008", "MAJOR_REWARD", "c005f008:daily_all_tasks:%d" % _day[0], "Hero"]] and _spark.bursts.back() == 14, "one MAJOR_REWARD on the ScrubBox hero (confetti 14)")
	_ok(_all_charges() == rb0 + 1, "exactly the one Mystery Booster charge (any of the four)")
	var r: Dictionary = _root.get_app_state().actions.claim_daily_all_tasks()
	await _frames(14)
	_ok(not r["ok"] and _log("F008").size() == 4, "second ScrubBox claim refused: no second box, no feel")
	await _press("ok", p)
	await _frames(14)
	_ok(_log("F008").size() == 4, "back on Tasks after the box: no replay")
	_complete("d04_tasks_small_scrubbox_major_once")

func _d05() -> void:
	print("[d05 F008 no spam: Home refresh / reopen / resize / unrelated popup / back = zero feel]")
	var n0: int = _root.feel.dispatch_log().size()
	var b0: int = _spark.bursts.size()
	_top().close("test")
	await _frames(2)
	for _i in range(3):
		_root.get_home().refresh()
	for dest in ["daily", "gift_bar", "tasks"]:
		_root._on_home_shortcut(dest)
		await _frames(14)
		_root.handle_back()
		await _frames(14)
	_root.open_life("test")
	await _frames(14)
	_root.handle_back()
	_sub.size = Vector2i(1536, 2048)
	await _frames(14)
	_sub.size = Vector2i(1080, 2160)
	_root.request_home_ceremonies()
	_root.request_earned_packs()
	await _frames(14)
	_ok(_root.feel.dispatch_log().size() == n0 and _spark.bursts.size() == b0, "no new feel request / plugin work (%d requests)" % n0)
	_complete("d05_no_spam_refresh_reopen_resize")

# ---------------------------------------------------------------- F009 ----

func _a01() -> void:
	print("[a01 F009 Heart purchase: one confirmation per commit; failures silent]")
	await _boot("a01")
	var e = _e()
	e.wallet.credit("scrub_bucks", 20000)
	for _i in range(3):
		e.hearts.consume()
	var p = _root.open_life("test")
	await _frames(2)
	var h0: int = e.hearts.hearts()
	await _press("heart_plus_one", p)
	_ok(e.hearts.hearts() == h0 + 1 and _log("F009") == [["F009", "SMALL", "", "Heart"]], "Heart +1 committed -> one SMALL on the Life heart")
	await _press("heart_refill", p)
	_ok(e.hearts.hearts() == e.hearts.max_hearts() and _log("F009").size() == 2 and _log("F009")[1][1] == "REWARD", "full refill committed -> one REWARD")
	var r: Dictionary = _root.get_app_state().actions.buy_heart()
	await _frames(14)
	_ok(not r["ok"] and _log("F009").size() == 2, "already full refused: zero feel")
	e.hearts.consume()
	e.wallet.debit("scrub_bucks", e.wallet.scrub_bucks())
	await create_timer(1.1).timeout   # the Life popup's live 1 s refresh unblocks +1 (no longer full)
	await _press("heart_plus_one", p)
	_ok(String(_root.get_acquisition().last_result.get("reason", "")) == "insufficient_sb" and _log("F009").size() == 2 and _spark.bursts.size() == 2, "insufficient SB: zero feel")
	_complete("a01_heart_purchase_success_only")

func _a02() -> void:
	print("[a02 F009 Need a Hand BUY charge: one confirmation on success; insufficient silent]")
	await _boot("a02")
	var e = _e()
	var p = _root.get_acquisition().open_need_a_hand({"show": true, "level": 1, "picks": [{"id": "tornado"}, {"id": "selector"}]})
	await _frames(2)
	e.wallet.credit("scrub_bucks", int(e.config.booster_price("tornado")))
	await _press("buy:tornado", p)
	_ok(e.boosters.charges("tornado") == 1 and _log("F009") == [["F009", "SMALL", "", "Card_tornado"]], "charge committed -> one SMALL on its card")
	e.wallet.debit("scrub_bucks", e.wallet.scrub_bucks())
	await _press("buy:selector", p)
	_ok(e.boosters.charges("selector") == 0 and _log("F009").size() == 1, "insufficient SB (%s): no charge, zero feel" % _root.get_acquisition().last_result.get("reason", ""))
	_complete("a02_booster_charge_success_only")

func _a03() -> void:
	print("[a03 F009 rewarded: verified success once per token; fail / cancel / unverified / timeout / duplicate silent]")
	await _boot("a03")
	var e = _e()
	var prov = ProviderDouble.new()
	e.rewarded.set_provider(prov)
	e.hearts.consume()
	e.hearts.consume()
	var p = _root.open_life("test")
	await _frames(2)
	for outcome in [{"outcome": "failed"}, {"outcome": "cancelled"}, {"outcome": "completed", "verified": false}]:
		await _press("watch", p)
		prov.deliver_last(outcome)
		await _frames(14)
	await _press("watch", p)
	var tk: String = prov.last_token()
	e.rewarded.abandon(tk, "timeout")
	await _frames(14)
	_ok(_log("F009").is_empty() and e.hearts.hearts() == e.hearts.max_hearts() - 2, "failed / cancelled / unverified / timeout: zero feel, no Heart")
	await _press("watch", p)
	tk = prov.last_token()
	prov.deliver_last({"outcome": "completed", "verified": true})
	await _frames(14)
	_ok(_log("F009") == [["F009", "REWARD", "c005f009:rewarded:" + tk, "Heart"]] and e.hearts.hearts() == e.hearts.max_hearts() - 1, "verified grant -> one REWARD keyed by the rewarded token")
	var dup: Dictionary = prov.deliver(tk, {"outcome": "completed", "verified": true})
	await _frames(14)
	_ok(not dup["ok"] and _log("F009").size() == 1 and e.hearts.hearts() == e.hearts.max_hearts() - 1, "duplicate provider callback (%s): no grant, no feel" % dup.get("reason", ""))
	p.close("test")
	var nah = _root.get_acquisition().open_need_a_hand({"show": true, "level": 1, "picks": [{"id": "tornado"}, {"id": "selector"}]})
	await _frames(2)
	await _press("watch:tornado", nah)
	var tk2: String = prov.last_token()
	prov.deliver_last({"outcome": "completed", "verified": true})
	await _frames(14)
	_ok(_log("F009").size() == 2 and _log("F009")[1] == ["F009", "REWARD", "c005f009:rewarded:" + tk2, "Card_tornado"] and e.boosters.charges("tornado") == 1, "rewarded booster charge -> one REWARD on its Need a Hand card")
	_complete("a03_rewarded_verified_only_once")

func _a04() -> void:
	print("[a04 F009 plugins missing / throwing: the authority result is unchanged]")
	await _boot("a04")
	var e = _e()
	e.wallet.credit("scrub_bucks", 20000)
	e.hearts.consume()
	e.hearts.consume()
	_root.feel.set_backends_for_test(null, null)
	var h0: int = e.hearts.hearts()
	var r: Dictionary = _root.get_app_state().actions.buy_heart()
	await _frames(14)
	_ok(r["ok"] and e.hearts.hearts() == h0 + 1, "plugins missing: Heart +1 committed exactly")
	_root.feel.set_backends_for_test(null, FaultySpark.new())
	_root.open_life("test")
	await _frames(2)
	print("  EXPECTED_FAULT_INJECTION: one SCRIPT ERROR ('explode' on null) follows, raised inside a spy plugin")
	r = _root.get_app_state().actions.buy_heart()
	await _frames(14)
	_ok(r["ok"] and e.hearts.hearts() == h0 + 2 and _top() != null and String(_top().popup_id) == "life", "plugin throws: Heart +1 committed exactly; Life popup still live")
	_complete("a04_plugins_missing_or_throwing")

func _a05() -> void:
	print("[a05 F009 gameplay booster use: one SMALL on the HUD booster after the committed use]")
	await _boot("a05")
	var e = _e()
	var lr: Dictionary = _root.play_current_frontier()
	await _frames(8)
	var host = _root.get_gameplay_host()
	_ok(lr["ok"] and host != null, "real gameplay host launched")
	e.boosters.add_charges("plus_one_slot", 1)
	var r: Dictionary = host.execute_booster("plus_one_slot")
	await _frames(14)
	_ok(r["ok"] and _log("F009") == [["F009", "SMALL", "", "Booster_plus_one_slot"]], "+1 Slot committed -> one SMALL on its HUD button %s" % str(r))
	var bad: Dictionary = host.execute_booster("selector", null)
	await _frames(14)
	_ok(not bad["ok"] and _log("F009").size() == 1, "illegal use (%s): zero feel" % bad.get("reason", ""))
	_complete("a05_gameplay_booster_use")

# ---------------------------------------------------------------- boundary ----

const PLUGIN_WORDS := ["GameFeelFlow", "\"Spark\"", "/root/Spark", "Spark.", "GFFUtil", "addons/game_feel_flow", "addons/saltmire_spark"]
const NO_AUTHORITY := [".grant(", "request_save", ".save(", "nav.", ".go(", "mark_seen", "claim_gift(", "claim_daily_login(",
	"claim_daily_task(", "claim_daily_all_tasks(", "buy_heart(", "refill_hearts(", "buy_charge(", "buy_booster_charge(",
	".resolve(", "abandon(", "start_rewarded", "execute_booster", "set_reduced", "snapshot", "FileAccess", "ConfigFile",
	"camera", "flash", "freeze", "time_scale", "clear()"]

func _b01() -> void:
	print("[b01 static boundary: adapter-only plugin access, no authority, no durable feel state]")
	var src := FileAccess.get_file_as_string("res://scripts/ui/feel/meta_reward_feel.gd")
	var code := "\n".join(Array(src.split("\n")).filter(func(l): return not String(l).strip_edges().begins_with("#")))
	_ok(PLUGIN_WORDS.all(func(w): return not src.contains(w)), "coordinator never names a plugin")
	var hits: Array = NO_AUTHORITY.filter(func(w): return code.contains(w))
	_ok(hits.is_empty(), "coordinator calls no grant / claim / save / navigation / provider / settings API %s" % str(hits))
	_ok(code.contains("_feel.play(") and code.count(".play(") == 1, "its only effect call is FeedbackAdapter.play")
	var offenders: Array = []
	for f in _gd("res://scripts"):
		if f == "res://scripts/ui/feel/feedback_adapter.gd":
			continue
		var s := FileAccess.get_file_as_string(f)
		if PLUGIN_WORDS.any(func(w): return s.contains(w)):
			offenders.append(f)
	_ok(offenders.is_empty(), "no production script outside FeedbackAdapter names a plugin %s" % str(offenders))
	var main := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_ok(main.count("MetaRewardFeel.new()") == 1, "one production coordinator (main.gd)")
	_complete("b01_static_boundary")

func _b02() -> void:
	print("[b02 Reduced: committed claims consume their keys with zero plugin work]")
	await _boot("b02")
	_root.get_app_state().set_reduced_effects(true)
	for i in range(3):
		_e().daily.mark_task_done(i)
	_root._on_home_shortcut("tasks")
	await _frames(2)
	await _press("task:0")
	await _press("scrubbox")
	await create_timer(0.5).timeout
	var hero: Control = _top().get_hero()
	_ok(_root.feel.has_played("c005f008:daily_all_tasks:%d" % _day[0]) and _log("F008").size() == 2, "task + ScrubBox keys consumed")
	_ok(_spark.bursts.is_empty() and _gff.plays.is_empty() and _root.feel.owned_count() == 0 and hero.scale == Vector2.ONE, "zero plugin work, no settle; ScrubBox static and readable")
	_complete("b02_reduced_zero_plugin_work_claims")

func _gd(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sd in d.get_directories():
		out += _gd(dir + "/" + sd)
	return out

# ------------------------------------------------------------------ harness ----

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(id: String) -> void:
	_completed[id] = true

func _done() -> void:
	var missing := EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for m in missing:
		_fail += 1
		print("  FAIL: case did not complete: " + m)
	print("M43-C005F-PHASE3 meta rewards + acquisition feel: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
