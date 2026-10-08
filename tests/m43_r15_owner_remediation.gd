extends SceneTree
## M43-C015R — owner runtime review remediation V01 (SB-M43-R15-001..003).
##   r*: Rewarded Ads daily five-slot track (authority + real app UI + Home CTA geometry);
##   g*: Settings visual-family remediation (behaviour unchanged);
##   d*: Daily Rewards containment across the owner viewport matrix.
## Real app root (main.tscn) with injected clock + local day where a surface is involved. The
## rewarded-video provider double below exists ONLY in this test (never in production).
##
## Run: godot --headless --path . -s res://tests/m43_r15_owner_remediation.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const RewardedDailyService = preload("res://scripts/economy/rewarded_daily_service.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")

## Physical owner matrix -> logical canvas under project stretch canvas_items / expand (base
## 1080x2160): the real app renders every window size at this logical size.
const PHYSICAL := [Vector2i(683, 1366), Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1080, 2160),
	Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var EXPECTED_CASES := [
	"r01_config_seeded_from_daily", "r02_free_slot_once_per_day", "r03_production_provider_unavailable",
	"r04_verified_ad_only", "r05_provider_refused", "r06_forward_day_reset", "r07_rollback_no_farm",
	"r08_relaunch_idempotent", "r09_existing_rewarded_unchanged", "r10_popup_real_ui", "r11_home_cta_geometry",
	"r12_rewarded_ads_icon_family",
	"g01_settings_visual_family", "g02_settings_behaviour_unchanged", "g03_settings_contained_matrix",
	"d01_daily_no_floating_hero", "d02_daily_contained_matrix", "d03_daily_claim_unchanged",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

## Test-only rewarded provider: available per flag; holds deliveries until the test fires them.
class TestProvider extends RewardedAdProvider:
	var available := true
	var accept := true
	var requests: Array = []      ## [placement, token]
	var _deliver := {}            ## token -> Callable
	func is_available(_placement: String) -> bool:
		return available
	func request(placement: String, token: String, deliver: Callable) -> bool:
		if not accept:
			return false
		requests.append([placement, token])
		_deliver[token] = deliver
		return true
	func fire(token: String, outcome: String, verified = true) -> Dictionary:
		return _deliver[token].call(token, {"outcome": outcome, "verified": verified})

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	_r01(); _r02(); _r03(); _r04(); _r05(); _r06(); _r07(); _r08(); _r09()
	await _r10(); await _r11(); await _r12()
	await _g01(); await _g02(); await _g03()
	await _d01(); await _d02(); await _d03()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------ R15-001 ----

func _app(tag: String) -> Object:
	return AppState.new(_tmp_path(tag), func(): return _now[0], func(): return _day[0])

func _r01() -> void:
	print("[r01 five config bundles seeded 1:1 from Daily D1..D5; distinct versioned file; fail closed]")
	var b := RewardedDailyService.load_bundles(RewardedDailyService.PATH)
	var econ: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/economy_rewards_v1.json"))
	var same := b.size() == 5
	for d in range(1, 6):
		same = same and JSON.stringify(b.get(d, {})) == JSON.stringify(_ints(econ["daily"]["login_rewards"][str(d)]))
	_ok(same, "slot n bundle == Daily D(n) bundle for n = 1..5 %s" % str(b))
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RewardedDailyService.PATH))
	_ok(cfg["schema"] == "scrubbots.rewarded_daily.v1" and int(cfg["version"]) == 1 and not cfg["slots"][0]["requires_ad"] and cfg["slots"].slice(1).all(func(e): return e["requires_ad"]), "schema v1; slot 1 no ad, slots 2-5 ad")
	var bad := {
		"four slots": {"schema": RewardedDailyService.SCHEMA, "version": 1, "slots": cfg["slots"].slice(0, 4)},
		"slot 1 requires ad": _mut(cfg, func(c): c["slots"][0]["requires_ad"] = true),
		"slot 3 free": _mut(cfg, func(c): c["slots"][2]["requires_ad"] = false),
		"unknown resource": _mut(cfg, func(c): c["slots"][1]["reward"] = {"gems": 5}),
		"zero amount": _mut(cfg, func(c): c["slots"][0]["reward"] = {"scrub_bucks": 0}),
		"duplicate slot": _mut(cfg, func(c): c["slots"][4]["slot"] = 4),
		"future version": _mut(cfg, func(c): c["version"] = 2),
	}
	var rejected: Array = []
	for k in bad:
		if RewardedDailyService.load_bundles(_write_json("bad", bad[k])).is_empty():
			rejected.append(k)
	_ok(rejected.size() == bad.size(), "malformed configs disable the track %s" % str(rejected))
	_complete("r01_config_seeded_from_daily")

func _r02() -> void:
	print("[r02 slot 1: no ad, exactly once per local day, separate from Daily login]")
	var a = _app("r02")
	var e = a.economy
	var sb0: int = e.wallet.scrub_bucks()
	var gift0 := JSON.stringify(e.gift.snapshot())
	var orders0 := JSON.stringify(e.orders.snapshot())
	_ok(e.rewarded_daily.states() == ["ready_free", "locked_sequence", "locked_sequence", "locked_sequence", "locked_sequence"], "fresh day: slot 1 ready, slots 2-5 locked in sequence (R15-001-R01)")
	var r: Dictionary = a.actions.claim_rewarded_daily_free()
	_ok(r["ok"] and e.wallet.scrub_bucks() == sb0 + 100 and e.reward.already_applied("daily_rewarded:%d:1" % _day[0]), "slot 1 -> +100 SB under daily_rewarded:<day>:1")
	_ok(not a.actions.claim_rewarded_daily_free()["ok"] and e.wallet.scrub_bucks() == sb0 + 100 and e.rewarded_daily.slot_state(1) == "claimed", "second claim refused; CLAIMED")
	_ok(e.daily.streak() == 0 and not e.daily.claimed_today() and e.daily.next_claim_cycle_day() == 1, "Daily login streak / claim untouched")
	_ok(JSON.stringify(e.gift.snapshot()) == gift0 and JSON.stringify(e.orders.snapshot()) == orders0, "Gift Meter + Daily Scrub Orders untouched")
	a.actions.claim_daily_login()
	_ok(e.daily.streak() == 1 and e.rewarded_daily.slot_state(1) == "claimed", "Daily login still claims independently")
	_complete("r02_free_slot_once_per_day")

func _r03() -> void:
	print("[r03 production default provider stays honestly unavailable: nothing granted]")
	var a = _app("r03")
	var e = a.economy
	_ok(e.rewarded.get_provider().get_script() == RewardedAdProvider, "default provider = base RewardedAdProvider (M57 not wired)")
	a.actions.claim_rewarded_daily_free()
	var applied0: int = e.reward.applied_transaction_count()
	var reasons: Array = []
	for slot in range(2, 6):
		reasons.append(String(a.actions.start_rewarded_daily(slot)["reason"]))
	_ok(reasons == ["unavailable", "locked_sequence", "locked_sequence", "locked_sequence"] and e.reward.applied_transaction_count() == applied0, "after slot 1: slot 2 refused as unavailable, 3-5 locked in sequence; nothing granted %s" % str(reasons))
	_ok(e.rewarded_daily.states() == ["claimed", "ad_unavailable", "locked_sequence", "locked_sequence", "locked_sequence"], "production: slot 2 NO VIDEO, later slots locked")
	_complete("r03_production_provider_unavailable")

func _r04() -> void:
	print("[r04 slots 2-5: grant only on completed + verified; every other outcome grants nothing]")
	var a = _app("r04")
	var e = a.economy
	var tp := TestProvider.new()
	e.rewarded.set_provider(tp)
	_ok(e.rewarded_daily.states() == ["ready_free", "locked_sequence", "locked_sequence", "locked_sequence", "locked_sequence"], "test provider, fresh day: only slot 1 actionable")
	a.actions.claim_rewarded_daily_free()
	_ok(e.rewarded_daily.states() == ["claimed", "ready_ad", "locked_sequence", "locked_sequence", "locked_sequence"], "after slot 1: only slot 2 WATCH AD")
	var applied0: int = e.reward.applied_transaction_count()
	var wallet0 := JSON.stringify(e.reward.snapshot()["wallet"])
	var bad := [["cancelled", true], ["skipped", true], ["failed", true], ["timeout", true], ["completed", false], ["completed", "true"], ["", true]]
	var ok_all := true
	for o in bad:
		var s: Dictionary = a.actions.start_rewarded_daily(2)
		var res: Dictionary = tp.fire(String(s["token"]), o[0], o[1])
		ok_all = ok_all and not res["ok"] and e.reward.applied_transaction_count() == applied0
	_ok(ok_all and JSON.stringify(e.reward.snapshot()["wallet"]) == wallet0 and e.rewarded_daily.slot_state(2) == "ready_ad" and e.rewarded_daily.slot_state(3) == "locked_sequence", "cancel / skip / fail / timeout / unverified / string-verified / empty -> nothing granted, no advance")
	for slot in [2, 3]:
		tp.fire(String(a.actions.start_rewarded_daily(slot)["token"]), "completed", true)
	var s4: Dictionary = a.actions.start_rewarded_daily(4)
	_ok(e.rewarded_daily.slot_state(4) == "pending" and not a.actions.start_rewarded_daily(4)["ok"], "pending slot cannot start twice")
	_ok(tp.requests[-1][0] == "rewarded_daily_slot_4" and String(s4["token"]) != String(s4["tx"]) and String(s4["tx"]) == "daily_rewarded:%d:4" % _day[0], "placement rewarded_daily_slot_4; provider token != economy tx")
	var sb0: int = e.wallet.scrub_bucks()
	var r: Dictionary = tp.fire(String(s4["token"]), "completed", true)
	_ok(r["ok"] and e.wallet.scrub_bucks() == sb0 + 250 and e.reward.already_applied("daily_rewarded:%d:4" % _day[0]) and not e.reward.already_applied("rewarded:" + String(s4["token"])), "verified completion -> slot 4 bundle under daily_rewarded:<day>:4 only")
	_ok(not tp.fire(String(s4["token"]), "completed", true)["ok"] and e.wallet.scrub_bucks() == sb0 + 250, "duplicate callback grants nothing")
	_ok(a.actions.start_rewarded_daily(4)["reason"] == "already_claimed" and e.rewarded_daily.slot_state(4) == "claimed", "a second request for a granted slot is refused")
	var s5: Dictionary = a.actions.start_rewarded_daily(5)
	e.rewarded.abandon(String(s5["token"]), "timeout")
	var late: Dictionary = tp.fire(String(s5["token"]), "completed", true)
	_ok(not late["ok"] and late["reason"] == "duplicate" and not e.reward.already_applied("daily_rewarded:%d:5" % _day[0]) and e.rewarded_daily.slot_state(5) == "ready_ad", "UI timeout abandons; late callback grants nothing; slot stays available")
	_ok(not e.rewarded.resolve("never-issued", {"outcome": "completed", "verified": true})["ok"], "unknown token grants nothing")
	tp.fire(String(a.actions.start_rewarded_daily(5)["token"]), "completed", true)
	_ok(e.rewarded_daily.states() == ["claimed", "claimed", "claimed", "claimed", "claimed"], "each slot exactly once, in order")
	_complete("r04_verified_ad_only")

func _r05() -> void:
	print("[r05 provider refusal / unavailable mid-session grants nothing]")
	var a = _app("r05")
	var e = a.economy
	var tp := TestProvider.new()
	tp.accept = false
	e.rewarded.set_provider(tp)
	a.actions.claim_rewarded_daily_free()
	var applied0: int = e.reward.applied_transaction_count()
	_ok(a.actions.start_rewarded_daily(2)["reason"] == "provider_refused" and e.reward.applied_transaction_count() == applied0 and e.rewarded_daily.slot_state(3) == "locked_sequence", "provider refused -> nothing, no advance")
	tp.accept = true
	tp.available = false
	_ok(e.rewarded_daily.slot_state(2) == "ad_unavailable" and a.actions.start_rewarded_daily(2)["reason"] == "unavailable", "provider unavailable -> NO VIDEO, refused")
	_complete("r05_provider_refused")

func _r06() -> void:
	print("[r06 forward local day: all five again, new deterministic ids]")
	var a = _app("r06")
	var e = a.economy
	var tp := TestProvider.new()
	e.rewarded.set_provider(tp)
	var d0: int = _day[0]
	a.actions.claim_rewarded_daily_free()
	tp.fire(String(a.actions.start_rewarded_daily(2)["token"]), "completed", true)
	_day[0] += 1
	_now[0] += 86400
	_ok(e.rewarded_daily.states() == ["ready_free", "locked_sequence", "locked_sequence", "locked_sequence", "locked_sequence"], "next local day: fresh track back at slot 1")
	a.actions.claim_rewarded_daily_free()
	_ok(e.reward.already_applied("daily_rewarded:%d:1" % d0) and e.reward.already_applied("daily_rewarded:%d:1" % (d0 + 1)), "day D and D+1 ids both kept")
	_day[0] = d0
	_now[0] -= 86400
	_complete("r06_forward_day_reset")

func _r07() -> void:
	print("[r07 clock / local-day rollback never reopens or farms a prior day]")
	var a = _app("r07")
	var e = a.economy
	var tp := TestProvider.new()
	e.rewarded.set_provider(tp)
	var d0: int = _day[0]
	_day[0] = d0 + 1
	a.actions.claim_rewarded_daily_free()
	_day[0] = d0
	_ok(e.rewarded_daily.rollback_locked() and e.rewarded_daily.states().all(func(s): return s == "locked_rollback"), "rolled back to D: every slot locked")
	var sb: int = e.wallet.scrub_bucks()
	_ok(a.actions.claim_rewarded_daily_free()["reason"] == "clock_rollback" and a.actions.start_rewarded_daily(3)["reason"] == "clock_rollback" and e.wallet.scrub_bucks() == sb and tp.requests.is_empty(), "free claim + ad refused, no request sent, nothing granted")
	_day[0] = d0 - 5
	_ok(not a.actions.claim_rewarded_daily_free()["ok"], "deeper rollback still refused")
	_day[0] = d0 + 1
	_ok(e.rewarded_daily.states() == ["claimed", "ready_ad", "locked_sequence", "locked_sequence", "locked_sequence"], "back at D+1: claimed stays claimed, slot 2 next, later slots locked")
	_day[0] = d0
	_complete("r07_rollback_no_farm")

func _r08() -> void:
	print("[r08 relaunch: granted slots stay granted, high-water survives, no section / migration]")
	var path := _tmp_path("r08")
	var a := AppState.new(path, func(): return _now[0], func(): return _day[0])
	var tp := TestProvider.new()
	a.economy.rewarded.set_provider(tp)
	_day[0] += 3
	a.actions.claim_rewarded_daily_free()
	for slot in [2, 3]:
		tp.fire(String(a.actions.start_rewarded_daily(slot)["token"]), "completed", true)
	a.request_save()
	var snap := JSON.stringify(a.economy.snapshot())
	_ok(not a.economy.snapshot().has("rewarded_daily"), "no new economy save section (state = canonical reward ledger)")
	var b := AppState.new(path, func(): return _now[0], func(): return _day[0])
	b.economy.rewarded.set_provider(TestProvider.new())
	_ok(b.economy.rewarded_daily.states() == ["claimed", "claimed", "claimed", "ready_ad", "locked_sequence"] and not b.actions.claim_rewarded_daily_free()["ok"] and b.actions.start_rewarded_daily(3)["reason"] == "already_claimed" and b.actions.start_rewarded_daily(5)["reason"] == "locked_sequence", "relaunch: slots 1-3 claimed, slot 4 next, slot 5 locked, cannot re-grant")
	_day[0] -= 3
	_ok(b.economy.rewarded_daily.rollback_locked(), "relaunch with the day rolled back: still locked")
	var old = JSON.parse_string(snap)
	_ok(typeof(old) == TYPE_DICTIONARY and not old.has("rewarded_daily"), "old saves need no migration (absent ids = fresh track)")
	_complete("r08_relaunch_idempotent")

func _r09() -> void:
	print("[r09 Heart / booster rewarded products unchanged]")
	_ok(RewardedGrantService.products() == ["heart", "booster:plus_one_slot", "booster:random", "booster:selector", "booster:tornado"], "product list unchanged %s" % str(RewardedGrantService.products()))
	var a = _app("r09")
	var e = a.economy
	var tp := TestProvider.new()
	e.rewarded.set_provider(tp)
	var s: Dictionary = a.actions.start_rewarded("booster:tornado")
	var c0: int = e.boosters.charges("tornado")
	tp.fire(String(s["token"]), "completed", true)
	_ok(e.boosters.charges("tornado") == c0 + 1 and e.reward.already_applied("rewarded:" + String(s["token"])), "booster grant still under rewarded:<token>")
	_ok(tp.requests[-1][0] == "rewarded_booster_tornado", "booster placement unchanged")
	_complete("r09_existing_rewarded_unchanged")

func _r10() -> void:
	print("[r10 real app: Home REWARDED ADS -> popup; free claim; NO VIDEO in production; verified ad (TEST provider)]")
	await _boot("r10")
	var a = _root.get_app_state()
	var e = a.economy
	var home = _root.get_home()
	var cta: Button = home.get_region("RewardedAdsButton")
	_ok(cta != null and not cta.disabled and cta.get_parent() == home.get_region("Shortcut_collection"), "REWARDED ADS CTA live, attached under COLLECTION")
	_ok(_names(home.get_region("RightShortcutColumn")) == ["Shortcut_tasks", "Shortcut_daily"] and _names(home.get_region("LeftShortcutColumn")) == ["Shortcut_shop", "Shortcut_collection"], "four primary panels unchanged")
	cta.pressed.emit()
	await _frames(2)
	var p = _root.get_modal_stack().top()
	_ok(p != null and String(p.popup_id) == "rewarded_ads" and p.get_title() == UiText.t("RADS_TITLE") and p.get_frame_kind() == "large", "REWARDED ADS popup in the BasePopup family")
	var texts_ok := true
	for slot in range(1, 6):
		var row: Control = p.find_child("Slot_%d" % slot, true, false)
		texts_ok = texts_ok and row != null and (row.find_child("RewardText", true, false) as Label).text == UiText.reward_text(e.rewarded_daily.reward_for(slot))
	_ok(texts_ok and p.find_child("Slots", true, false).get_child_count() == 5, "exactly five rows; each reward text = config")
	_ok(_btn(p, 1) == UiText.t("POPUP_CLAIM") and not p.get_action_button("slot:1").disabled and range(2, 6).all(func(s): return _btn(p, s) == UiText.t("RADS_LOCKED") and p.get_action_button("slot:%d" % s).disabled), "fresh day: CLAIM + four disabled LOCKED (sequential)")
	var sb0: int = e.wallet.scrub_bucks()
	p.get_action_button("slot:1").pressed.emit()
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 100 and _btn(p, 1) == UiText.t("RADS_CLAIMED") and p.get_action_button("slot:1").disabled and (p.find_child("Note", true, false) as Label).text == UiText.t("RADS_GRANTED", [UiText.reward_text({"scrub_bucks": 100})]), "CLAIM -> +100 SB, CLAIMED, collected note")
	_ok(_btn(p, 2) == UiText.t("RADS_NO_VIDEO") and p.get_action_button("slot:2").disabled and range(3, 6).all(func(s): return _btn(p, s) == UiText.t("RADS_LOCKED") and p.get_action_button("slot:%d" % s).disabled), "production after CLAIM: slot 2 NO VIDEO, slots 3-5 LOCKED")
	var tp := TestProvider.new()
	e.rewarded.set_provider(tp)
	await create_timer(0.5).timeout
	p.close("test")
	await _frames(2)
	cta.pressed.emit()
	await _frames(2)
	p = _root.get_modal_stack().top()
	_ok(_btn(p, 2) == UiText.t("RADS_WATCH") and not p.get_action_button("slot:2").disabled and range(3, 6).all(func(s): return _btn(p, s) == UiText.t("RADS_LOCKED") and p.get_action_button("slot:%d" % s).disabled), "TEST provider injected: slot 2 WATCH AD, slots 3-5 LOCKED")
	_ok((p.find_child("Slot_4", true, false).find_child("State", true, false) as Label).text == UiText.t("RADS_STATE_NEXT", [3]), "locked row reads 'Unlocks after reward 3'")
	p.get_action_button("slot:2").pressed.emit()
	await _frames(2)
	var tok := String(tp.requests[-1][1])
	_ok(p.is_busy() and (p.find_child("Slot_2", true, false) as Control).get_meta("state") == "pending" and (p.find_child("Slot_3", true, false) as Control).get_meta("state") == "locked_sequence", "pending slot 2: busy, slot 3 stays locked")
	tp.fire(tok, "cancelled", true)
	await _frames(2)
	_ok(not p.is_busy() and not e.reward.already_applied("daily_rewarded:%d:2" % _day[0]) and (p.find_child("Note", true, false) as Label).text.begins_with(UiText.t("REWARDED_NO_GRANT", [""]).strip_edges()) and _btn(p, 2) == UiText.t("RADS_WATCH") and _btn(p, 3) == UiText.t("RADS_LOCKED"), "cancel -> No reward, slot 2 still WATCH AD, slot 3 still LOCKED")
	await create_timer(0.5).timeout
	p.get_action_button("slot:2").pressed.emit()
	await _frames(2)
	tp.fire(String(tp.requests[-1][1]), "completed", true)
	await _frames(4)
	# M43-C005F-PHASE2-R01: slot 2's reward is a Standard Card Pack, so the earned pack now opens
	# in the shipping pack ceremony over Rewarded Ads; finishing it returns to this popup.
	var pk = _root.get_modal_stack().top()
	_ok(pk != null and String(pk.popup_id) == "standard_pack" and String(pk.get_model()["presentation_id"]).begins_with("earned:daily_rewarded:"), "slot 2 Standard Card Pack opens the earned-pack ceremony")
	pk.tap()
	for _i in range(1500):
		if pk.phase() == "AWAIT_ROUTE":
			break
		await process_frame
	pk.tap()
	for _i in range(1500):
		if not is_instance_valid(pk) or pk.is_closed():
			break
		await process_frame
	await _frames(3)
	_ok(_root.get_modal_stack().top() == p and e.pending_packs.size() == 0, "pack completed + acknowledged; back on Rewarded Ads")
	_ok(_btn(p, 2) == UiText.t("RADS_CLAIMED") and _btn(p, 3) == UiText.t("RADS_WATCH") and not p.get_action_button("slot:3").disabled and _btn(p, 4) == UiText.t("RADS_LOCKED"), "verified slot 2 -> CLAIMED; slot 3 unlocks (only)")
	await create_timer(0.5).timeout
	p.get_action_button("slot:3").pressed.emit()
	await _frames(2)
	tp.fire(String(tp.requests[-1][1]), "completed", true)
	await _frames(2)
	_ok(e.boosters.charges("random") == 1 and _btn(p, 3) == UiText.t("RADS_CLAIMED") and e.reward.already_applied("daily_rewarded:%d:3" % _day[0]), "verified completion -> Random Booster x1 granted, CLAIMED")
	_complete("r10_popup_real_ui")

func _r11() -> void:
	print("[r11 Home CTA contained and collision-free across the owner viewport matrix]")
	for phys in PHYSICAL:
		var lv := _logical(phys)
		await _boot("r11", lv)
		var home = _root.get_home()
		var cta: Rect2 = home.get_region("RewardedAdsButton").get_global_rect()
		var vp := Rect2(Vector2.ZERO, Vector2(lv))
		var others := {}
		for n in ["PlayButton", "GiftMeter", "BottomNav", "WinStreakRewardTrack", "Shortcut_daily", "Shortcut_tasks", "Shortcut_shop", "Shortcut_collection", "TopCurrencyHUD"]:
			others[n] = (home.get_region(n) as Control).get_global_rect()
		var strip: Control = home.get_region("HomeJourneyStrip")
		others["HomeJourneyStrip"] = strip.get_global_rect()
		var hits: Array = []
		for n in others:
			if cta.intersects(others[n]):
				hits.append(n)
		var icon: Rect2 = (home.get_region("ShortcutIcon_rewarded_ads") as Control).get_global_rect()
		for n in others:
			if icon.intersects(others[n]):
				hits.append("icon/" + n)
		for bot in home._world["helper_bot_rects"]:
			var br := Rect2(home.global_position + home.world_to_screen(bot.position), bot.size * home._world_scale)
			if cta.intersects(br) or icon.intersects(br):
				hits.append("helper_bot")
		_ok(vp.encloses(cta) and vp.encloses(icon) and hits.is_empty() and cta.size.y >= 88.0 - 0.5, "%s (logical %s): card %s + icon inside viewport, >= 88 px, no overlap %s" % [phys, lv, cta, hits])
		var col: Rect2 = others["Shortcut_collection"]
		_ok(cta.size.is_equal_approx(col.size) and cta.size.is_equal_approx(others["Shortcut_shop"].size) and is_equal_approx(cta.position.x, col.position.x) and cta.position.y > col.end.y, "%s: owner placement - under COLLECTION, same size / x as COLLECTION and SHOP (%s vs %s)" % [phys, cta, col])
		var opaque := _scrubby_opaque_in(home, [cta, icon])
		_ok(opaque == 0, "%s: no opaque Scrubby pose pixel under the card or icon (%d)" % [phys, opaque])
	_complete("r11_home_cta_geometry")

## Opaque (alpha > 0.1) pixels of Scrubby's Home pose art that fall under any of `rects`,
## sampled on a 6 px grid in screen space through the TextureRect's stretch-scale mapping.
func _scrubby_opaque_in(home, rects: Array) -> int:
	var art: TextureRect = home.get_region("Art_scrubby")
	var img := Image.load_from_file(ProjectSettings.globalize_path(art.texture.resource_path))
	var ar := art.get_global_rect()
	var n := 0
	for r in rects:
		var o: Rect2 = (r as Rect2).intersection(ar)
		if o.size.x <= 0.0 or o.size.y <= 0.0:
			continue
		var y := o.position.y
		while y < o.end.y:
			var x := o.position.x
			while x < o.end.x:
				var u := (Vector2(x, y) - ar.position) / ar.size
				var px := Vector2i(clampi(int(u.x * img.get_width()), 0, img.get_width() - 1), clampi(int(u.y * img.get_height()), 0, img.get_height() - 1))
				if img.get_pixelv(px).a > 0.1:
					n += 1
				x += 6.0
			y += 6.0
	return n

func _r12() -> void:
	print("[r12 R15-004: Rewarded Ads uses the Home shortcut family + the owner-approved HOME-122 icon]")
	await _boot("r12")
	var home = _root.get_home()
	var ra: Button = home.get_region("RewardedAdsButton")
	var daily: Button = home.get_region("Shortcut_daily")
	_ok(ra.get_script() == daily.get_script() and ra.get_parent() == home.get_region("Shortcut_collection") and ra.find_children("*", "", true, false).all(func(c): return not String(c.name).contains("Triangle")), "same UiShortcutButton component, attached under COLLECTION; no native play triangle")
	var a_sb: StyleBoxFlat = ra.get_theme_stylebox("normal")
	var d_sb: StyleBoxFlat = daily.get_theme_stylebox("normal")
	_ok(a_sb.bg_color == d_sb.bg_color and a_sb.border_color == d_sb.border_color and a_sb.bg_color != Color(0.337, 0.769, 0.169), "same cyan/blue light glass panel as DAILY (green CTA body gone)")
	var fnt: Font = ra.get_theme_font("font")
	var tw: float = fnt.get_string_size(ra.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ra.get_theme_font_size("font_size")).x
	var nsb: StyleBox = ra.get_theme_stylebox("normal")
	_ok(ra.label_band == daily.label_band and ra.autowrap_mode == TextServer.AUTOWRAP_OFF and tw <= ra.size.x - nsb.get_margin(SIDE_LEFT) - nsb.get_margin(SIDE_RIGHT), "one-line label in the standard band fits the panel (%.0f px text)" % tw)
	_ok(ra.text == "REWARDED ADS" and ra.get_theme_color("font_color") == daily.get_theme_color("font_color") and ra.get_theme_color("font_outline_color") == daily.get_theme_color("font_outline_color") and ra.get_theme_constant("outline_size") == daily.get_theme_constant("outline_size"), "code-rendered REWARDED ADS label, same white / navy-outline treatment")
	var path := "res://assets/ui/final/home/shortcuts/icon_shortcut_rewarded_ads.png"
	var b = home.get_art_binder()
	var icon: TextureRect = home.get_region("ShortcutIcon_rewarded_ads")
	_ok(b.state("icon_shortcut_rewarded_ads") == "APPROVED_BOUND" and icon.texture != null and icon.texture.resource_path == path and icon.is_visible_in_tree(), "HOME-122 APPROVED_BOUND and presented on ShortcutIcon_rewarded_ads")
	_ok(FileAccess.get_sha256(path) == "ce96e09aaf97db5ed171c7da15e2c8afccc46d4408a1cc64bc0521db89a96c8b", "owner master bytes = the owner-confirmed pin")
	var row := {}
	for r in home.get_presentation_accounting():
		if r["id"] == "HOME-122":
			row = r
	_ok(row.get("mode") == "STATIC" and row.get("slug") == "icon_shortcut_rewarded_ads" and row["nodes"][0]["texture"] != null, "presentation accounting: HOME-122 STATIC on the Rewarded Ads icon")
	var four := {"shop": "471416cbb6ab7100c0404170a15f49e250b61a03d713b7ec162e8571343864ef", "collection": "bde7a0442a016c272897e2487a85c2895f4883afbffd07efd5126a54c9d05872",
		"tasks": "711df18c7df43f3ebc036ac2c3486216334d0a4b403264650a40f5cb22658a00", "daily": "a01e49ac28f8665443a3c11d9ee2b6f806b5649d4b1456167c36bef7d2044ad7"}
	_ok(four.keys().all(func(k): return FileAccess.get_sha256("res://assets/ui/final/home/shortcuts/icon_shortcut_%s.png" % k) == four[k]), "SHOP / COLLECTION / TASKS / DAILY icons byte-identical")
	var intents: Array = []
	home.shortcut_requested.connect(func(id): intents.append(id))
	ra.pressed.emit()
	await _frames(2)
	_ok(intents == ["rewarded_ads"] and String(_root.get_modal_stack().top().popup_id) == "rewarded_ads", "tap -> exactly one rewarded_ads intent -> REWARDED ADS popup")
	_complete("r12_rewarded_ads_icon_family")

# ------------------------------------------------------------ R15-002 ----

func _open_settings(tag: String, size: Vector2i = Vector2i(1080, 2160)):
	await _boot(tag, size)
	_root.open_settings()
	await _frames(3)
	return _root.get_settings_panel()

## Frame-inner rect: the FrameBox rect minus its patch insets (the cream content area).
func _inner(frame: Control) -> Rect2:
	var i: Array = frame._insets()
	var r := Rect2(frame.global_position, frame.size)
	return Rect2(r.position + Vector2(i[0], i[1]), r.size - Vector2(i[0] + i[2], i[1] + i[3]))

func _g01() -> void:
	print("[g01 Settings now uses the M43 popup family (frame, royal plaque, X, cream cards, themed controls)]")
	var panel = await _open_settings("g01")
	var box: Control = panel.find_child("Panel", true, false)
	var frame: Control = panel.find_child("Frame", true, false)
	_ok(box.get_theme_stylebox("panel") is StyleBoxEmpty, "generic dark panel stylebox is gone")
	_ok(frame != null and frame.get_texture_path() == BasePopup.FRAMES["large"]["path"], "canonical large popup frame (BasePopup.FrameBox)")
	var pill: PanelContainer = panel.find_child("TitlePill", true, false)
	var pill_sb = pill.get_theme_stylebox("panel") if pill != null else null
	_ok(pill_sb is StyleBoxFlat and (pill_sb as StyleBoxFlat).bg_color == BasePopup.ROYAL and (panel.find_child("Title", true, false) as Label).text == "SETTINGS", "royal SETTINGS plaque")
	_ok(panel.find_child("CloseX", true, false) is Button and panel.find_child("CloseButton", true, false) is Button, "top-right X + CLOSE")
	var cards := ["Card_Row_master", "Card_Row_music", "Card_Row_sfx", "Card_HapticsToggle", "Card_ReducedEffectsToggle"]
	_ok(cards.all(func(n): var c = panel.find_child(n, true, false); return c != null and (c.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == BasePopup.ROW), "five cream setting cards")
	var t: CheckButton = panel.get_toggle("music")
	_ok(t.get_theme_color("font_color") == BasePopup.INK and t.get_theme_icon("checked") is ImageTexture and panel.get_slider("music").get_theme_stylebox("grabber_area") is StyleBoxFlat, "navy labels, themed switches + sliders")
	_complete("g01_settings_visual_family")

func _g02() -> void:
	print("[g02 Settings behaviour identical: canonical state, live apply, X / CLOSE]")
	var panel = await _open_settings("g02")
	var a = _root.get_app_state()
	panel.get_toggle("sfx").button_pressed = false
	_ok(not a.audio.is_sfx_enabled() and panel.get_value_label("sfx").text == "OFF" and not panel.get_slider("sfx").editable, "SFX toggle -> canonical OFF, slider locked")
	panel.get_toggle("sfx").button_pressed = true
	panel.get_slider("music").value = 0.4
	_ok(is_equal_approx(a.audio.get_music_volume(), 0.4) and panel.get_value_label("music").text == "40%", "Music slider live")
	panel.get_haptics_toggle().button_pressed = false
	_ok(not a.haptics.is_enabled(), "Vibration -> canonical haptics OFF")
	panel.get_reduced_effects_toggle().button_pressed = true
	_ok(a.effects.is_reduced(), "Reduced Effects -> canonical ON")
	(panel.find_child("CloseX", true, false) as Button).pressed.emit()
	await _frames(2)
	_ok(not panel.visible and not _root.get_navigation().is_settings_open(), "X closes through close_panel (nav overlay closed)")
	_root.open_settings()
	await _frames(2)
	_ok(panel.visible and not panel.get_haptics_toggle().button_pressed and panel.get_reduced_effects_toggle().button_pressed and panel.get_value_label("music").text == "40%", "reopen re-syncs from canonical state")
	(panel.find_child("CloseButton", true, false) as Button).pressed.emit()
	await _frames(2)
	_ok(not panel.visible, "CLOSE still closes")
	_complete("g02_settings_behaviour_unchanged")

func _g03() -> void:
	print("[g03 Settings contained, >= 88 px, fonts >= 30 across the owner matrix]")
	for phys in PHYSICAL:
		var lv := _logical(phys)
		var panel = await _open_settings("g03", lv)
		var frame: Control = panel.find_child("Frame", true, false)
		var fr := Rect2(frame.global_position, frame.size)
		var inner := _inner(frame)
		var bad: Array = []
		for n in panel.find_children("*", "", true, false):
			if not (n is Control) or not (n as Control).is_visible_in_tree() or n == frame or (n as Control).is_ancestor_of(frame) or n.name == "Chrome":
				continue
			if not frame.is_ancestor_of(n):
				continue
			if not inner.grow(0.5).encloses((n as Control).get_global_rect()):
				bad.append(String(n.name))
			if (n is BaseButton or n is HSlider) and (n as Control).size.y < SettingsPanel.TOUCH_MIN - 0.5:
				bad.append(String(n.name) + "<88")
			if (n is Label or n is Button) and (n as Control).get_theme_font_size("font_size") < 30:
				bad.append(String(n.name) + "<30pt")
		_ok(Rect2(Vector2(16, 0), Vector2(lv) - Vector2(32, 0)).grow(0.5).encloses(fr) and bad.is_empty(), "%s (logical %s): frame %s inside 16 px gutter; every control inside the cream area, >= 88 px, >= 30 pt %s" % [phys, lv, fr, bad])
	_complete("g03_settings_contained_matrix")

# ------------------------------------------------------------ R15-003 ----

func _open_daily(tag: String, size: Vector2i = Vector2i(1080, 2160), claimed := false):
	await _boot(tag, size)
	_root.get_modal_stack().clear("test")
	if claimed:
		_root.get_app_state().actions.claim_daily_login()
	(_root.get_home().get_region("Shortcut_daily") as Button).pressed.emit()
	await _frames(3)
	return _root.get_modal_stack().top()

func _d01() -> void:
	print("[d01 Daily: no hero floating outside the frame; calendar + flame contained]")
	var p = await _open_daily("d01")
	_ok(String(p.popup_id) == "daily_login" and not p.get_hero().visible, "Daily popup has no floating hero")
	var inner := _inner(p._frame)
	for n in ["Calendar", "Flame", "Streak"]:
		var r: Rect2 = (p.find_child(n, true, false) as Control).get_global_rect()
		_ok(inner.encloses(r), "%s %s inside the frame content %s" % [n, r, inner])
	_complete("d01_daily_no_floating_hero")

func _d02() -> void:
	print("[d02 Daily: every card / check / text / action contained at the owner matrix (683x1366 first)]")
	for phys in PHYSICAL:
		var lv := _logical(phys)
		var p = await _open_daily("d02", lv, true)
		# Stress: every card shows its check and the longest state text.
		for day in range(1, 6):
			var card: Control = p.find_child("Day_%d" % day, true, false)
			(card.find_child("Check", true, false) as Control).modulate.a = 1.0
			(card.find_child("State", true, false) as Label).text = UiText.t("DAILY_CARD_CLAIMED_TODAY")
		await _frames(2)
		var vp := Rect2(Vector2.ZERO, Vector2(lv))
		var fr: Rect2 = p.get_frame_rect()
		var inner := _inner(p._frame)
		var bad: Array = []
		var grid: Rect2 = (p.find_child("Days", true, false) as Control).get_global_rect()
		for n in ["Calendar", "Flame", "Streak", "Days", "Rule"]:
			if not inner.encloses((p.find_child(n, true, false) as Control).get_global_rect()):
				bad.append(n)
		for day in range(1, 6):
			var card: Control = p.find_child("Day_%d" % day, true, false)
			var cr := card.get_global_rect()
			var st: StyleBox = card.get_theme_stylebox("panel")
			var content := Rect2(cr.position + Vector2(st.content_margin_left, st.content_margin_top), cr.size - Vector2(st.content_margin_left + st.content_margin_right, st.content_margin_top + st.content_margin_bottom))
			if not inner.encloses(cr) or cr.size != DailyScreens.DAY_CARD_SIZE:
				bad.append("Day_%d %s" % [day, cr.size])
			for part in ["DayLabel", "RewardText", "State", "Check"]:
				var c: Control = card.find_child(part, true, false)
				if not content.grow(0.5).encloses(c.get_global_rect()):
					bad.append("Day_%d/%s" % [day, part])
				if c is Label and (c as Label).get_minimum_size().y > c.size.y + 0.5:
					bad.append("Day_%d/%s clipped" % [day, part])
		for a in ["claim", "close"]:
			var br: Rect2 = p.get_action_button(a).get_global_rect()
			if br.intersects(grid) or not inner.grow(0.5).encloses(br):
				bad.append("action " + a)
		if (p.find_child("Rule", true, false) as Control).get_global_rect().intersects(grid):
			bad.append("Rule over grid")
		_ok(vp.encloses(fr) and bad.is_empty(), "%s (logical %s): frame %s on screen; everything contained / unclipped / no overlap %s" % [phys, lv, fr, bad])
	_complete("d02_daily_contained_matrix")

func _d03() -> void:
	print("[d03 Daily claim / state / reward truth unchanged by the layout fix]")
	var p = await _open_daily("d03")
	var a = _root.get_app_state()
	var sb0: int = a.economy.wallet.scrub_bucks()
	_ok((p.find_child("Day_1", true, false) as Control).get_meta("state") == "today" and (p.find_child("RewardText", true, false) as Label).text == UiText.reward_text(a.economy.daily.login_reward_for(1)), "D1 today with the configured reward")
	p.get_action_button("claim").pressed.emit()
	await _frames(3)
	_ok(a.economy.wallet.scrub_bucks() == sb0 + 100 and a.economy.daily.streak() == 1 and String(_root.get_modal_stack().top().popup_id) == "ceremony_daily", "CLAIM: +100 SB, streak 1, reward celebration")
	var c1: Control = p.find_child("Day_1", true, false)
	_ok(c1.get_meta("state") == "claimed_today" and (c1.find_child("Check", true, false) as Control).modulate.a == 1.0 and (p.find_child("Day_2", true, false).find_child("Check", true, false) as Control).modulate.a == 0.0, "check shown only on the claimed card")
	_complete("d03_daily_claim_unchanged")

# ------------------------------------------------------------------ helpers ----

func _btn(p, slot: int) -> String:
	return p.get_action_button("slot:%d" % slot).text

static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out

func _mut(cfg: Dictionary, f: Callable) -> Dictionary:
	var c: Dictionary = cfg.duplicate(true)
	f.call(c)
	return c

func _names(c: Node) -> Array:
	var out: Array = []
	for n in c.get_children():
		out.append(String(n.name))
	return out

func _boot(tag: String, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _tmp_path(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _tmp_path(tag: String) -> String:
	var path := "user://m43_r15_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

func _write_json(tag: String, d: Dictionary) -> String:
	var path := "user://m43_r15_%s_%d.json" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return path

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
	print("M43 owner R15 evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
