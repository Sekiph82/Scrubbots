extends SceneTree
## SB-M43-R15-001-R01 — Rewarded Ads sequential unlock (owner lock 2026-10-06):
##   Slot 1 CLAIM -> Slot 2 WATCH AD -> verified grant unlocks Slot 3 -> ... -> Slot 5.
## Future slots can never start early; no-grant outcomes never advance; the position is
## derived from the canonical reward ledger (relaunch-safe), resets on a forward local day and
## stays behind the existing rollback/high-water lock. Real AppState / facade / services and
## the real app popup; the provider double below exists ONLY in this test.
##
## Run: godot --headless --path . -s res://tests/m43_r15_001_r01_sequential_unlock.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const L := "locked_sequence"

var EXPECTED_CASES := [
	"s01_fresh_day_only_slot1", "s02_chain_unlocks_one_at_a_time", "s03_bypass_fails_before_provider",
	"s04_no_grant_outcomes_do_not_advance", "s05_pending_keeps_future_locked", "s06_duplicate_late_no_double_advance",
	"s07_relaunch_reconstructs_position", "s08_forward_day_resets", "s09_rollback_still_fail_closed",
	"s10_legacy_partial_ledger_no_skip", "s11_heart_booster_unchanged", "s12_other_economy_untouched",
	"s13_real_popup_locked_rows", "s14_home_cta_no_badge",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

class TestProvider extends RewardedAdProvider:
	var available := true
	var accept := true
	var requests: Array = []      ## [placement, token]
	var _deliver := {}
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
	_s01(); _s02(); _s03(); _s04(); _s05(); _s06(); _s07(); _s08(); _s09(); _s10(); _s11(); _s12()
	await _s13(); await _s14()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _app(tag: String, path: String = ""):
	return AppState.new(path if not path.is_empty() else _tmp_path(tag), func(): return _now[0], func(): return _day[0])

func _with_provider(a) -> TestProvider:
	var tp := TestProvider.new()
	a.economy.rewarded.set_provider(tp)
	return tp

## Verified completion of the current ad slot through the real facade.
func _watch_ok(a, tp: TestProvider, slot: int) -> bool:
	var s: Dictionary = a.actions.start_rewarded_daily(slot)
	if not bool(s.get("ok", false)):
		return false
	return bool(tp.fire(String(s["token"]), "completed", true).get("ok", false))

func _expect(slot_claimed: int) -> Array:
	## Exact sequential state vector once slots 1..slot_claimed are granted (TEST provider).
	var out: Array = []
	for s in range(1, 6):
		if s <= slot_claimed:
			out.append("claimed")
		elif s == slot_claimed + 1:
			out.append("ready_free" if s == 1 else "ready_ad")
		else:
			out.append(L)
	return out

func _tx(slot: int, day: int = -1) -> String:
	return "daily_rewarded:%d:%d" % [_day[0] if day == -1 else day, slot]

# -------------------------------------------------------------------- cases ----

func _s01() -> void:
	print("[s01 fresh local day: only slot 1 actionable]")
	var a = _app("s01")
	var tp := _with_provider(a)
	var rd = a.economy.rewarded_daily
	_ok(rd.states() == ["ready_free", L, L, L, L] and rd.current_slot() == 1, "fresh day: slot 1 CLAIM, slots 2-5 locked_sequence %s" % str(rd.states()))
	var reasons: Array = []
	for slot in range(2, 6):
		reasons.append(String(a.actions.start_rewarded_daily(slot)["reason"]))
	_ok(reasons == [L, L, L, L] and tp.requests.is_empty(), "slots 2-5 cannot start before slot 1 (no provider request) %s" % str(reasons))
	_complete("s01_fresh_day_only_slot1")

func _s02() -> void:
	print("[s02 each grant unlocks exactly the next slot]")
	var a = _app("s02")
	var tp := _with_provider(a)
	var rd = a.economy.rewarded_daily
	var r: Dictionary = a.actions.claim_rewarded_daily_free()
	_ok(r["ok"] and rd.states() == _expect(1) and rd.current_slot() == 2, "slot 1 claim unlocks only slot 2 %s" % str(rd.states()))
	for slot in range(2, 6):
		var before: int = tp.requests.size()
		var jumps_refused := true
		for later in range(slot + 1, 6):
			jumps_refused = jumps_refused and a.actions.start_rewarded_daily(later)["reason"] == L
		_ok(jumps_refused and tp.requests.size() == before, "at slot %d: every later slot refused before provider" % slot)
		_ok(_watch_ok(a, tp, slot) and a.economy.reward.already_applied(_tx(slot)), "slot %d verified grant under %s" % [slot, _tx(slot)])
		_ok(rd.states() == _expect(slot) and rd.current_slot() == slot + 1, "slot %d grant unlocks only slot %d %s" % [slot, slot + 1, str(rd.states())])
	_ok(rd.states() == ["claimed", "claimed", "claimed", "claimed", "claimed"] and rd.current_slot() == 6, "slot 5 grant completes the day")
	_ok(not a.actions.claim_rewarded_daily_free()["ok"] and range(2, 6).all(func(s): return a.actions.start_rewarded_daily(s)["reason"] == "already_claimed"), "completed day: nothing more to start")
	_complete("s02_chain_unlocks_one_at_a_time")

func _s03() -> void:
	print("[s03 future-slot bypass fails closed before any provider request]")
	var a = _app("s03")
	var tp := _with_provider(a)
	var e = a.economy
	a.actions.claim_rewarded_daily_free()
	var applied0: int = e.reward.applied_transaction_count()
	var via_service: Array = []
	var via_grant: Array = []
	var via_can: Array = []
	for slot in [3, 4, 5]:
		via_service.append(String(e.rewarded_daily.start_ad(slot)["reason"]))
		via_grant.append(String(e.rewarded.start_daily_slot(_day[0], slot, e.rewarded_daily.reward_for(slot))["reason"]))
		via_can.append(String(e.rewarded.can_start_daily(_day[0], slot)["reason"]))
	_ok(via_service == [L, L, L], "RewardedDailyService.start_ad(3/4/5) refused %s" % str(via_service))
	_ok(via_grant == [L, L, L] and via_can == [L, L, L], "RewardedGrantService.start_daily_slot / can_start_daily(3/4/5) refused %s %s" % [str(via_grant), str(via_can)])
	_ok(tp.requests.is_empty() and e.rewarded.pending_count() == 0 and e.reward.applied_transaction_count() == applied0, "no provider request, nothing pending, nothing granted")
	_ok(a.actions.start_rewarded_daily(0)["reason"] == "unknown_product" and a.actions.start_rewarded_daily(6)["reason"] == "unknown_product", "out-of-range slots still unknown_product")
	_complete("s03_bypass_fails_before_provider")

func _s04() -> void:
	print("[s04 no-grant outcomes never advance the sequence]")
	var a = _app("s04")
	var tp := _with_provider(a)
	var e = a.economy
	var rd = e.rewarded_daily
	a.actions.claim_rewarded_daily_free()
	var held := func() -> bool:
		return rd.states() == _expect(1) and rd.current_slot() == 2 and not e.reward.already_applied(_tx(2))
	var outcomes := [["cancelled", true], ["skipped", true], ["failed", true], ["timeout", true],
		["completed", false], ["completed", "true"], ["", true]]
	for o in outcomes:
		var s: Dictionary = a.actions.start_rewarded_daily(2)
		var res: Dictionary = tp.fire(String(s["token"]), o[0], o[1])
		_ok(not res["ok"] and held.call(), "outcome %s / verified %s -> no grant, slot 3 still locked" % [o[0], str(o[1])])
	var ab: Dictionary = a.actions.start_rewarded_daily(2)
	e.rewarded.abandon(String(ab["token"]), "timeout")
	_ok(held.call(), "abandoned (UI timeout) -> no advance")
	_ok(not e.rewarded.resolve("never-issued", {"outcome": "completed", "verified": true})["ok"] and held.call(), "unknown token -> no advance")
	tp.accept = false
	_ok(a.actions.start_rewarded_daily(2)["reason"] == "provider_refused" and held.call(), "provider refusal -> no advance")
	tp.accept = true
	tp.available = false
	_ok(a.actions.start_rewarded_daily(2)["reason"] == "unavailable" and rd.slot_state(2) == "ad_unavailable" and rd.slot_state(3) == L and rd.current_slot() == 2, "provider unavailable -> NO VIDEO on slot 2, slot 3 still locked")
	tp.available = true
	_ok(_watch_ok(a, tp, 2) and rd.states() == _expect(2), "a later verified completion still unlocks exactly slot 3")
	_complete("s04_no_grant_outcomes_do_not_advance")

func _s05() -> void:
	print("[s05 a pending current slot keeps every future slot locked]")
	var a = _app("s05")
	var tp := _with_provider(a)
	var rd = a.economy.rewarded_daily
	a.actions.claim_rewarded_daily_free()
	_watch_ok(a, tp, 2)
	var s3: Dictionary = a.actions.start_rewarded_daily(3)
	var n: int = tp.requests.size()
	_ok(s3["ok"] and rd.states() == ["claimed", "claimed", "pending", L, L], "pending slot 3: slots 4-5 locked %s" % str(rd.states()))
	_ok(a.actions.start_rewarded_daily(4)["reason"] == L and a.actions.start_rewarded_daily(3)["reason"] == "pending" and tp.requests.size() == n, "slot 4 refused, slot 3 not startable twice, no new request")
	tp.fire(String(s3["token"]), "completed", true)
	_ok(rd.states() == _expect(3), "after the verified grant slot 4 unlocks")
	_complete("s05_pending_keeps_future_locked")

func _s06() -> void:
	print("[s06 duplicate / late callbacks cannot double-advance]")
	var a = _app("s06")
	var tp := _with_provider(a)
	var e = a.economy
	var rd = e.rewarded_daily
	a.actions.claim_rewarded_daily_free()
	var s2: Dictionary = a.actions.start_rewarded_daily(2)
	tp.fire(String(s2["token"]), "completed", true)
	var applied: int = e.reward.applied_transaction_count()
	var dup: Dictionary = tp.fire(String(s2["token"]), "completed", true)
	_ok(not dup["ok"] and dup["reason"] == "duplicate" and rd.current_slot() == 3 and rd.slot_state(4) == L and e.reward.applied_transaction_count() == applied, "duplicate slot-2 callback: still at slot 3, slot 4 locked")
	var s3: Dictionary = a.actions.start_rewarded_daily(3)
	e.rewarded.abandon(String(s3["token"]), "timeout")
	var late: Dictionary = tp.fire(String(s3["token"]), "completed", true)
	_ok(not late["ok"] and rd.current_slot() == 3 and not e.reward.already_applied(_tx(3)), "late callback after abandon: no grant, no advance")
	# A request started on day D and verified after the day rolls forward grants D only.
	var d0: int = _day[0]
	var s3b: Dictionary = a.actions.start_rewarded_daily(3)
	_day[0] = d0 + 1
	_now[0] += 86400
	var cross: Dictionary = tp.fire(String(s3b["token"]), "completed", true)
	_ok(cross["ok"] and e.reward.already_applied(_tx(3, d0)) and not e.reward.already_applied(_tx(3)), "verified across midnight: grants day D slot 3 only")
	_ok(rd.states() == ["ready_free", L, L, L, L], "new day D+1 untouched: back at slot 1")
	_day[0] = d0
	_now[0] -= 86400
	_ok(rd.current_slot() == 4, "day D position advanced exactly once (to slot 4)")
	_complete("s06_duplicate_late_no_double_advance")

func _s07() -> void:
	print("[s07 relaunch reconstructs the exact sequential position from the durable ledger]")
	var path := _tmp_path("s07")
	var a = _app("s07", path)
	var tp := _with_provider(a)
	a.actions.claim_rewarded_daily_free()
	_watch_ok(a, tp, 2)
	_watch_ok(a, tp, 3)
	var pend: Dictionary = a.actions.start_rewarded_daily(4)
	_ok(pend["ok"], "slot 4 pending at shutdown")
	a.request_save()
	_ok(not a.economy.snapshot().has("rewarded_daily") and not a.economy.snapshot()["reward"].has("rewarded_daily"), "no second progress ledger / save section")
	var b = _app("s07", path)
	var tp2 := _with_provider(b)
	var rd = b.economy.rewarded_daily
	_ok(rd.states() == _expect(3) and rd.current_slot() == 4, "relaunch: slots 1-3 claimed, slot 4 next, slot 5 locked %s" % str(rd.states()))
	_ok(b.actions.start_rewarded_daily(5)["reason"] == L and tp2.requests.is_empty(), "relaunch: slot 5 still refused before provider")
	_ok(not b.economy.reward.already_applied(_tx(4)), "pre-relaunch pending slot 4 never granted (session-local pending dropped)")
	_ok(_watch_ok(b, tp2, 4) and rd.states() == _expect(4), "relaunched slot 4 verified -> slot 5 unlocks")
	_complete("s07_relaunch_reconstructs_position")

func _s08() -> void:
	print("[s08 forward local day restarts at slot 1]")
	var a = _app("s08")
	var tp := _with_provider(a)
	var rd = a.economy.rewarded_daily
	a.actions.claim_rewarded_daily_free()
	for slot in range(2, 6):
		_watch_ok(a, tp, slot)
	_ok(rd.current_slot() == 6, "day D complete")
	var d0: int = _day[0]
	_day[0] = d0 + 1
	_now[0] += 86400
	_ok(rd.states() == ["ready_free", L, L, L, L] and rd.current_slot() == 1 and a.actions.start_rewarded_daily(2)["reason"] == L, "day D+1: back to slot 1, slot 2 locked")
	a.actions.claim_rewarded_daily_free()
	_ok(rd.states() == _expect(1) and a.economy.reward.already_applied(_tx(1, d0)) and a.economy.reward.already_applied(_tx(1)), "D+1 slot 1 under a new deterministic id; D ids kept")
	_day[0] = d0
	_now[0] -= 86400
	_complete("s08_forward_day_resets")

func _s09() -> void:
	print("[s09 rollback / high-water protection still fail closed, cannot reopen or skip]")
	var a = _app("s09")
	var tp := _with_provider(a)
	var rd = a.economy.rewarded_daily
	var d0: int = _day[0]
	a.actions.claim_rewarded_daily_free()            # day D slot 1
	_day[0] = d0 + 1
	a.actions.claim_rewarded_daily_free()            # day D+1 slot 1
	_watch_ok(a, tp, 2)                              # day D+1 slot 2 -> high-water D+1
	_day[0] = d0
	var n: int = tp.requests.size()
	_ok(rd.rollback_locked() and rd.states().all(func(s): return s == "claimed" or s == "locked_rollback"), "rolled back to D: nothing actionable %s" % str(rd.states()))
	_ok(range(2, 6).all(func(s): return a.actions.start_rewarded_daily(s)["reason"] == "clock_rollback") and not a.actions.claim_rewarded_daily_free()["ok"] and tp.requests.size() == n, "every slot refused on rollback, no request")
	_day[0] = d0 + 1
	_ok(rd.states() == _expect(2) and rd.current_slot() == 3, "back at D+1: exact position (slot 3) preserved, not reopened or skipped")
	_day[0] = d0
	_complete("s09_rollback_still_fail_closed")

func _s10() -> void:
	print("[s10 a legacy partial ledger (old parallel rule) cannot reopen or skip]")
	var a = _app("s10")
	var tp := _with_provider(a)
	var e = a.economy
	var rd = e.rewarded_daily
	e.reward.grant(_tx(1), rd.reward_for(1))
	e.reward.grant(_tx(4), rd.reward_for(4))     # slot 4 granted out of order under the superseded rule
	_ok(rd.states() == ["claimed", "ready_ad", L, "claimed", L] and rd.current_slot() == 2, "legacy {1,4}: slot 2 current, 3 + 5 locked, 4 stays claimed %s" % str(rd.states()))
	_watch_ok(a, tp, 2)
	_ok(rd.states() == ["claimed", "claimed", "ready_ad", "claimed", L], "slot 2 -> slot 3 next")
	_watch_ok(a, tp, 3)
	_ok(rd.states() == ["claimed", "claimed", "claimed", "claimed", "ready_ad"] and a.actions.start_rewarded_daily(4)["reason"] == "already_claimed", "slot 3 -> slot 5 next; slot 4 never re-granted")
	_complete("s10_legacy_partial_ledger_no_skip")

func _s11() -> void:
	print("[s11 Heart / booster rewarded products unchanged and independent of the daily track]")
	var a = _app("s11")
	var tp := _with_provider(a)
	var e = a.economy
	_ok(e.rewarded_daily.current_slot() == 1, "daily track still at slot 1")
	var c0: int = e.boosters.charges("random")
	var s: Dictionary = a.actions.start_rewarded("booster:random")
	tp.fire(String(s["token"]), "completed", true)
	_ok(e.boosters.charges("random") == c0 + 1 and e.reward.already_applied("rewarded:" + String(s["token"])) and tp.requests[-1][0] == "rewarded_booster_random", "booster rewarded grant under rewarded:<token>, placement unchanged")
	_ok(e.rewarded_daily.current_slot() == 1, "booster video does not advance the daily track")
	if e.hearts.hearts() >= e.hearts.max_hearts():
		_ok(e.rewarded.can_start("heart")["reason"] == "already_full", "heart product still refuses when Hearts are full")
	else:
		_ok(e.rewarded.can_start("heart")["ok"], "heart product still startable below max")
	_complete("s11_heart_booster_unchanged")

func _s12() -> void:
	print("[s12 Daily login / Daily Scrub Orders / Gift / Hearts / 2x untouched by the full track]")
	var a = _app("s12")
	var tp := _with_provider(a)
	var e = a.economy
	# "collection" is excluded on purpose: the slot 2/4/5 card-pack bundles open immediately into
	# the Collection (pre-existing M39 grant-and-resolve semantics), the intended reward effect.
	var keep := ["gift", "streak", "robots", "hearts", "speed", "daily", "daily_orders", "records", "events", "return", "notifications", "pack_pity", "pack_receipts"]
	var before := {}
	for k in keep:
		before[k] = JSON.stringify(e.snapshot()[k])
	a.actions.claim_rewarded_daily_free()
	for slot in range(2, 6):
		_watch_ok(a, tp, slot)
	var changed: Array = []
	for k in keep:
		if JSON.stringify(e.snapshot()[k]) != before[k]:
			changed.append(k)
	_ok(changed.is_empty(), "sections outside the rewarded-daily grants unchanged %s" % str(changed))
	_ok(e.daily.streak() == 0 and not e.daily.claimed_today(), "Daily login streak / claim untouched")
	_complete("s12_other_economy_untouched")

func _s13() -> void:
	print("[s13 real popup: future rows visibly non-actionable; pressing them requests nothing]")
	await _boot("s13")
	var a = _root.get_app_state()
	var tp := _with_provider(a)
	var home = _root.get_home()
	home.get_region("RewardedAdsButton").pressed.emit()
	await _frames(2)
	var p = _root.get_modal_stack().top()
	_ok(p != null and String(p.popup_id) == "rewarded_ads" and p.find_child("Slots", true, false).get_child_count() == 5, "popup with exactly five rows")
	var locked_ok := true
	for s in range(2, 6):
		var row: Control = p.find_child("Slot_%d" % s, true, false)
		locked_ok = locked_ok and row.get_meta("state") == L and p.get_action_button("slot:%d" % s).disabled \
			and p.get_action_button("slot:%d" % s).text == UiText.t("RADS_LOCKED") \
			and (row.find_child("State", true, false) as Label).text == UiText.t("RADS_STATE_NEXT", [s - 1]) \
			and (row.find_child("RewardText", true, false) as Label).text == UiText.reward_text(a.economy.rewarded_daily.reward_for(s))
	_ok(locked_ok, "slots 2-5: LOCKED, disabled, 'Unlocks after reward n-1', reward text still shown")
	for s in range(2, 6):
		p.get_action_button("slot:%d" % s).pressed.emit()
		await _frames(1)
	_ok(tp.requests.is_empty() and a.economy.rewarded.pending_count() == 0, "pressing locked rows sends no provider request")
	p.get_action_button("slot:1").pressed.emit()
	await _frames(2)
	await create_timer(0.5).timeout   # popup re-arms its CTAs shortly after a committed claim
	_ok(p.get_action_button("slot:2").text == UiText.t("RADS_WATCH") and not p.get_action_button("slot:2").disabled and range(3, 6).all(func(s): return p.get_action_button("slot:%d" % s).text == UiText.t("RADS_LOCKED")), "after CLAIM only slot 2 becomes WATCH AD")
	_complete("s13_real_popup_locked_rows")

func _s14() -> void:
	print("[s14 Home CTA placement unchanged; no Home badge for Rewarded Ads]")
	await _boot("s14")
	var a = _root.get_app_state()
	var home = _root.get_home()
	var cta: Button = home.get_region("RewardedAdsButton")
	var col: Rect2 = (home.get_region("Shortcut_collection") as Control).get_global_rect()
	var r: Rect2 = cta.get_global_rect()
	_ok(cta.get_parent() == home.get_region("Shortcut_collection") and r.size.is_equal_approx(col.size) and is_equal_approx(r.position.x, col.position.x) and r.position.y > col.end.y, "CTA still under COLLECTION at the same size / x (%s vs %s)" % [r, col])
	var badges: Dictionary = HomeBadges.compute(a)
	# Superseded by the M47-FAMILY-APK-TOUCH-R01 owner decision (OWNER_DEVICE_FEEDBACK_V02): the CTA now
	# carries a red "1" while the ONE sequential frontier slot is actionable; the CTA geometry above is unchanged.
	var rd = a.economy.rewarded_daily
	var actionable := ["ready_free", "ready_ad"].has(rd.slot_state(rd.current_slot()))
	_ok(badges.has("rewarded_ads") and int(badges["rewarded_ads"]) == (1 if actionable else 0) and cta.get("badge").visible == actionable,
		"HomeBadges rewarded_ads follows the sequential frontier (%s, %s) %s" % [rd.slot_state(rd.current_slot()), str(actionable), str(badges)])
	_complete("s14_home_cta_no_badge")

# ------------------------------------------------------------------- infra -----

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
	var path := "user://m43_r15_r01_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
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
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += missing.size()
		print("  FAIL: cases not completed %s" % str(missing))
	print("SB-M43-R15-001-R01 sequential unlock: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
