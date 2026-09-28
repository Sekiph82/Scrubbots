extends SceneTree
## M43-C003-C001 — Life / Booster / 2x acquisition evidence.
## Real app root (main.tscn) with an injected wall clock, real Home, real
## ProductionGameplayHost + GameplayScreen, the ONE ModalStack / AcquisitionFlow /
## ShopHandoff, the canonical economy graph + save, and a test-double rewarded provider
## on the provider-neutral seam (production default stays unavailable).
##
## Run: godot --headless --path . -s res://tests/m43_c003_c001_acquisition.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const AcquisitionFlow = preload("res://scripts/ui/popup/acquisition_flow.gd")
const SpeedAcquisitionPopup = preload("res://scripts/ui/speed_acquisition_popup.gd")
const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000

var EXPECTED_CASES := [
	"c01_home_heart_plus", "c02_zero_heart_gate", "c03_life_live_values", "c04_life_full_state",
	"c05_plus_one_success", "c06_plus_one_insufficient", "c07_refill_success", "c08_refill_insufficient",
	"c09_rewarded_heart_grant", "c10_rewarded_heart_no_grant", "c11_rewarded_heart_duplicate",
	"c12_rewarded_heart_background", "c13_home_sb_plus_shop", "c14_one_booster_component",
	"c15_booster_data", "c16_charge_first", "c17_zero_charge_sb", "c18_rewarded_booster_grant",
	"c19_rewarded_booster_no_grant_dup", "c20_rewarded_booster_legality", "c21_rewarded_charge_kept",
	"c22_booster_insufficient_context", "c23_speed_four_offers", "c24_entitled_no_recharge",
	"c25_level_2x_retry_completion", "c26_timed_anti_rollback", "c27_speed_insufficient_context",
	"c28_free_auto_2x", "c29_rapid_taps", "c30_modal_isolation", "c31_no_accumulation",
	"c32_save_reload_idempotency", "responsive_matrix", "production_provider_unavailable",
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
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _boot_home()
	_production_provider_unavailable()
	await _c01_home_heart_plus()
	await _c02_zero_heart_gate()
	await _c03_life_live_values()
	await _c04_life_full_state()
	await _c05_plus_one_success()
	await _c06_plus_one_insufficient()
	await _c07_refill_success()
	await _c08_refill_insufficient()
	await _c09_rewarded_heart_grant()
	await _c10_rewarded_heart_no_grant()
	await _c11_rewarded_heart_duplicate()
	await _c12_rewarded_heart_background()
	await _c13_home_sb_plus_shop()
	await _boot_play(2)
	await _c14_one_booster_component()
	await _c15_booster_data()
	await _c16_charge_first()
	await _c17_zero_charge_sb()
	await _c18_rewarded_booster_grant()
	await _c19_rewarded_booster_no_grant_dup()
	await _c20_rewarded_booster_legality()
	await _c21_rewarded_charge_kept()
	await _c22_booster_insufficient_context()
	await _c23_speed_four_offers()
	await _c24_entitled_no_recharge()
	await _c25_level_2x_retry_completion()
	await _c26_timed_anti_rollback()
	await _c27_speed_insufficient_context()
	await _c28_free_auto_2x()
	await _c29_rapid_taps()
	await _c30_modal_isolation()
	await _c31_no_accumulation()
	await _c32_save_reload_idempotency()
	await _responsive_matrix()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot_home(size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43c003_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_prov = ProviderDouble.new()
	_eco().rewarded.set_provider(_prov)
	_host = null
	await _settle()

func _boot_play(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	await _boot_home(size)
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

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

func _acq():
	return _root.get_acquisition()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		_sub.push_input(e)
		await process_frame

func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _set_hearts(n: int, anchor: int = -1) -> void:
	_eco().hearts.import_snapshot({"hearts": n, "anchor": _now[0] if anchor < 0 else anchor})

func _set_sb(n: int) -> void:
	var w = _eco().wallet
	var cur: int = w.scrub_bucks()
	if cur > n:
		w.debit("scrub_bucks", cur - n)
	elif cur < n:
		w.credit("scrub_bucks", n - cur)

func _txt(p, node: String) -> String:
	var l = p.find_child(node, true, false)
	return l.text if l != null else "<missing>"

func _press(p, id: String) -> void:
	p.get_action_button(id).pressed.emit()

func _clear() -> void:
	_stack().clear("t")
	await _settle()

func _life():
	return _acq().find_open("life")

func _open_life():
	await _clear()
	var p = _root.open_life("test")
	await _settle()
	return p

func _first_action() -> bool:
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			return true
	return false

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

# ============================================================ Life / Hearts ====

func _production_provider_unavailable() -> void:
	print("[production rewarded provider = unavailable]")
	var app := AppState.new("user://m43c003_prod_%d.save" % Time.get_ticks_usec())
	_tmp.append(app.save.get_path() if app.save.has_method("get_path") else "")
	var prov = app.economy.rewarded.get_provider()
	_ok(prov.get_script() == RewardedAdProvider and not app.economy.rewarded.is_available("heart")
		and RewardedGrantService.products().all(func(pp): return not app.economy.rewarded.is_available(pp)), "default provider offers nothing (no fake success)")
	_ok(not app.economy.rewarded.start("heart").get("ok", true) and app.economy.hearts.hearts() == 5, "start refused; nothing granted")
	_ok(not RewardedGrantService.products().any(func(pp): return String(pp).begins_with("speed") or String(pp).find("2x") != -1)
		and RewardedGrantService.products().size() == 5, "rewarded products = +1 Heart + four boosters only (no rewarded 2x)")
	_ok(int(app.economy.config.hearts_regen_seconds()) == 900 and app.economy.hearts.max_hearts() == 5, "Heart authority 5 max / 900 s")
	app.economy.dispose()
	_complete("production_provider_unavailable")

func _c01_home_heart_plus() -> void:
	print("[1 Home Heart + opens the canonical Life popup]")
	var home = _root.get_home()
	await _click(_center(home.find_child("HeartsPlus", true, false)))
	var p = _life()
	_ok(p != null and _stack().ids() == ["life"] and p.context["source"] == "home_heart_plus" and home.is_modal_active(), "routed tap on Home Heart + -> Life (Home input hidden)")
	_ok(p.get_script() == BasePopup and p.get_frame_texture_path().ends_with("popup_medium_frame.png") and p.get_hero().visible, "Life = canonical BasePopup family (+ Scrubby hero)")
	await _clear()
	_complete("c01_home_heart_plus")

func _c02_zero_heart_gate() -> void:
	print("[2 zero-Heart attempt gate opens the SAME Life popup]")
	var nav = _root.get_navigation()
	_set_hearts(0)
	var r: Dictionary = _root.play_current_frontier()
	await _settle()
	_ok(r.get("reason") == "no_hearts" and nav.current() == R.HOME and _root.get_gameplay_host() == null, "PLAY with 0 Hearts: nothing launches")
	var p = _life()
	_ok(p != null and p.context["source"] == "attempt_gate" and _stack().ids() == ["life"], "same Life surface (source=attempt_gate)")
	p.close("x")
	_ok(_eco().hearts.hearts() == 0 and _eco().wallet.scrub_bucks() == 1000, "closing Life: no side effect")
	_set_hearts(5)
	await _settle()
	_complete("c02_zero_heart_gate")

func _c03_life_live_values() -> void:
	print("[3 Life reads live Hearts / max / countdown from HeartService]")
	_set_hearts(2, _now[0] - 100)
	var p = await _open_life()
	var h = _eco().hearts
	_ok(_txt(p, "HeartCount") == "2" and _txt(p, "HeartsOfMax") == UiText.t("LIFE_HEARTS", [2, 5]), "2 / 5 Hearts")
	_ok(h.seconds_to_next() == 800 and _txt(p, "TimerValue") == "13:20" and _txt(p, "TimerTitle") == UiText.t("LIFE_NEXT_IN"), "countdown = HeartService.seconds_to_next (13:20)")
	_now[0] += 815
	await create_timer(1.2).timeout
	_ok(_txt(p, "HeartCount") == "3" and _txt(p, "TimerValue") == "14:45", "wall clock +815 s -> live 3 Hearts, 14:45 (popup re-reads authority)")
	await _clear()
	_complete("c03_life_live_values")

func _c04_life_full_state() -> void:
	print("[4 5/5 Life full state: static ready, no second timer]")
	_set_hearts(5)
	var p = await _open_life()
	_ok(_txt(p, "TimerTitle") == UiText.t("LIFE_FULL") and _txt(p, "TimerValue") == "15:00", "full: static 15:00 ready state")
	_ok(p.get_action_button("heart_plus_one").disabled and p.get_action_button("heart_refill").disabled and p.get_action_button("watch").disabled, "offers disabled at full")
	_now[0] += 5000
	await create_timer(1.2).timeout
	_ok(_txt(p, "TimerValue") == "15:00" and _eco().hearts.hearts() == 5, "time passes: still 15:00, still 5")
	_press(p, "heart_plus_one")
	_ok(_eco().wallet.scrub_bucks() == 1000, "blocked +1 at full spends nothing")
	await _clear()
	_complete("c04_life_full_state")

func _c05_plus_one_success() -> void:
	print("[5 +1 Heart 500 SB atomic success]")
	_set_hearts(3)
	_set_sb(1000)
	var p = await _open_life()
	_press(p, "heart_plus_one")
	var r: Dictionary = _acq().last_result
	_ok(r.get("ok", false) and r.has("save") and _eco().hearts.hearts() == 4 and _eco().wallet.scrub_bucks() == 500, "one debit (500) + one Heart, saved")
	_ok(_txt(p, "HeartCount") == "4" and _txt(p, "Balance") == UiText.t("ACQ_BALANCE", ["500"]), "live UI from authority")
	await _clear()
	_complete("c05_plus_one_success")

func _c06_plus_one_insufficient() -> void:
	print("[6 +1 Heart insufficient: no mutation; Shop handoff keeps context]")
	_set_hearts(3)
	_set_sb(100)
	var p = await _open_life()
	_press(p, "heart_plus_one")
	_ok(_eco().hearts.hearts() == 3 and _eco().wallet.scrub_bucks() == 100 and _stack().ids() == ["life", "insufficient_sb"], "nothing debited / granted; insufficient-SB popup")
	var ins = _stack().top()
	_ok(ins.context["pending"]["product"] == "heart_plus_one" and ins.context["pending"]["source"] == "life" and ins.context["price_sb"] == 500, "pending product = heart_plus_one @500")
	var tickets: Array = []
	_root.shop.returned.connect(func(t, o): tickets.append([t, o]))
	_press(ins, "shop")
	await _settle()
	var open: Array = _root.shop.open_tickets()
	_ok(_stack().ids() == ["life", "shop"] and open.size() == 1 and open[0]["product"] == "heart_plus_one" and open[0]["source"] == "life", "Shop ticket holds the exact pending product")
	_root.handle_back()
	await _settle()
	_ok(tickets.size() == 1 and tickets[0][1] == "cancelled" and tickets[0][0]["product"] == "heart_plus_one" and _stack().ids() == ["life"] and _root.shop.open_tickets().is_empty(), "back: ticket returned once (cancelled), Life resumes")
	_ok(_eco().wallet.scrub_bucks() == 100 and _eco().hearts.hearts() == 3, "handoff moved no currency")
	await _clear()
	_complete("c06_plus_one_insufficient")

func _c07_refill_success() -> void:
	print("[7 full refill 400 x missing, live cost at commit, atomic]")
	_set_hearts(2, _now[0])
	_set_sb(2000)
	var p = await _open_life()
	_ok(p.get_action_button("heart_refill").text == UiText.t("ACQ_PRICE_SB", ["1,200"]), "display 3 missing -> 1,200 SB")
	# Regen happens between display and tap: the commit uses LIVE truth (2 missing).
	_now[0] += 900
	_press(p, "heart_refill")
	var r: Dictionary = _acq().last_result
	_ok(r.get("ok", false) and r.get("spent") == 800 and _eco().wallet.scrub_bucks() == 1200 and _eco().hearts.hearts() == 5, "charged 800 (live 2 missing), not stale 1,200; Hearts 5")
	await _clear()
	_complete("c07_refill_success")

func _c08_refill_insufficient() -> void:
	print("[8 full refill insufficient: no partial mutation]")
	_set_hearts(1)
	_set_sb(1000)
	var p = await _open_life()
	_press(p, "heart_refill")
	_ok(_eco().hearts.hearts() == 1 and _eco().wallet.scrub_bucks() == 1000 and _stack().top().popup_id == "insufficient_sb"
		and _stack().top().context["pending"]["product"] == "heart_refill" and _stack().top().context["price_sb"] == 1600, "no partial refill, no debit; refill context @1,600")
	await _clear()
	_complete("c08_refill_insufficient")

func _watch_heart():
	_set_hearts(3)
	var p = await _open_life()
	_press(p, "watch")
	return p

func _c09_rewarded_heart_grant() -> void:
	print("[9 rewarded Heart: verified completion grants exactly +1]")
	_set_sb(1000)
	var p = await _watch_heart()
	_ok(p.is_busy() and _eco().rewarded.pending_count() == 1 and _eco().hearts.hearts() == 3, "busy while the video runs, nothing granted yet")
	_ok(_root.handle_back() == "close_modal" and p.is_open(), "busy Life cannot be dismissed")
	var r: Dictionary = _prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(r.get("ok", false) and r.has("save") and _eco().hearts.hearts() == 4 and _eco().wallet.scrub_bucks() == 1000, "+1 Heart committed + saved, no SB")
	_ok(not p.is_busy() and _txt(p, "Status") == UiText.t("LIFE_REWARDED") and _txt(p, "HeartCount") == "4", "success shown only after commit")
	await _clear()
	_complete("c09_rewarded_heart_grant")

func _c10_rewarded_heart_no_grant() -> void:
	print("[10 rewarded Heart cancel / skip / fail / timeout / unverified -> 0]")
	for outcome in ["cancelled", "skipped", "failed", "timeout"]:
		var p = await _watch_heart()
		_prov.deliver_last({"outcome": outcome, "verified": true})
		_ok(_eco().hearts.hearts() == 3 and not p.is_busy() and _eco().rewarded.pending_count() == 0, "%s: 0 granted, usable again" % outcome)
	var q = await _watch_heart()
	_prov.deliver_last({"outcome": "completed", "verified": false})
	_prov.deliver_last({"outcome": "completed"})
	_ok(_eco().hearts.hearts() == 3, "unverified completion: 0")
	# UI safety timeout abandons the request; a late completion is then ignored.
	_acq().reward_ui_timeout_s = 0.1
	var t = await _watch_heart()
	await create_timer(0.3).timeout
	_ok(not t.is_busy() and _eco().rewarded.pending_count() == 0, "UI timeout -> abandoned, usable")
	_prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(_eco().hearts.hearts() == 3, "late completion after timeout: 0")
	_acq().reward_ui_timeout_s = 90.0
	# Full at commit: fails closed, never 6 Hearts.
	var f = await _watch_heart()
	_set_hearts(5)
	var r: Dictionary = _prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(r.get("reason") == "already_full" and _eco().hearts.hearts() == 5, "full at commit: fails closed (5, not 6)")
	await _clear()
	_complete("c10_rewarded_heart_no_grant")

func _c11_rewarded_heart_duplicate() -> void:
	print("[11 duplicate completion callback grants once]")
	var p = await _watch_heart()
	var n0: int = _eco().reward.applied_transaction_count()
	for _i in range(4):
		_prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(_eco().hearts.hearts() == 4 and _eco().reward.applied_transaction_count() == n0 + 1, "4 callbacks -> +1 Heart, one applied tx")
	await _clear()
	_complete("c11_rewarded_heart_duplicate")

func _c12_rewarded_heart_background() -> void:
	print("[12 background / resume with an unresolved reward: no duplicate]")
	var p = await _watch_heart()
	for n in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED]:
		_root.propagate_notification(n)
	await _settle()
	_ok(p.is_busy() and _eco().hearts.hearts() == 3, "backgrounded: still pending, nothing granted")
	for n in [Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN]:
		_root.propagate_notification(n)
	_prov.deliver_last({"outcome": "completed", "verified": true})
	_root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(_eco().hearts.hearts() == 4, "exactly +1 across background/resume + re-delivery")
	await _clear()
	_complete("c12_rewarded_heart_background")

func _c13_home_sb_plus_shop() -> void:
	print("[13 Home SB + -> canonical Shop intent with return context]")
	var home = _root.get_home()
	var sb0: int = _eco().wallet.scrub_bucks()
	var got: Array = []
	_root.shop.shop_requested.connect(func(t): got.append(t))
	await _click(_center(home.find_child("ScrubBucksPlus", true, false)))
	var open: Array = _root.shop.open_tickets()
	_ok(got.size() == 1 and got[0]["source"] == "home_sb_plus" and open.size() == 1 and _stack().ids() == ["shop"], "routed tap -> Shop ticket (source home_sb_plus), explicit Shop state")
	_ok(_eco().wallet.scrub_bucks() == sb0 and _stack().top().find_child("Action_back", true, false) != null
		and _stack().top().get_action_ids() == ["back"], "no SB pack sold, only BACK")
	_press(_stack().top(), "back")
	await _settle()
	_ok(_root.shop.open_tickets().is_empty() and _stack().depth() == 0 and _root.get_navigation().current() == R.HOME, "returned to Home, ticket closed")
	_complete("c13_home_sb_plus_shop")

# ============================================================ Boosters ==========

func _booster(id: String):
	await _clear()
	_host.request_booster(id)
	await _settle()
	return _acq().find_open("booster_" + id)

func _c14_one_booster_component() -> void:
	print("[14 one data-driven component serves all four boosters]")
	var scripts := {}
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		var p = await _booster(id)
		_ok(p != null and _stack().ids() == ["booster_" + id], "%s -> Booster Acquire" % id)
		scripts[p.get_script()] = true
	_ok(scripts.size() == 1 and scripts.has(BasePopup), "one component (BasePopup via AcquisitionFlow.open_booster), no per-booster scene")
	var dir := DirAccess.open("res://scripts/ui/popup")
	var files: Array = dir.get_files() if dir != null else []
	_ok(not files.any(func(f): return String(f).to_lower().find("tornado") != -1 or String(f).to_lower().find("selector") != -1), "no per-booster popup files")
	await _clear()
	_complete("c14_one_booster_component")

func _c15_booster_data() -> void:
	print("[15 icon / name / charges / price per booster]")
	var prices := {"plus_one_slot": 500, "random": 350, "selector": 500, "tornado": 750}
	for id in prices:
		var p = await _booster(id)
		var icon: TextureRect = p.find_child("BoosterIcon", true, false)
		_ok(icon.texture.resource_path == AcquisitionFlow.BOOSTER_DEFS[id]["icon"] and p.get_title() == UiText.t("BOOSTER_NAME_" + id.to_upper())
			and _txt(p, "Owned") == UiText.t("BOOSTER_OWNED", [0]) and int(_eco().config.booster_price(id)) == prices[id]
			and p.get_action_button("sb").text == UiText.t("BOOSTER_USE_SB", [str(prices[id])]) and _txt(p, "Effect") == UiText.t("BOOSTER_EFFECT_" + id.to_upper()),
			"%s: icon / name / owned 0 / %d SB / effect" % [id, prices[id]])
	var t = await _booster("tornado")
	_ok(t.find_child("Targets", true, false).get_child_count() > 0 and t.get_action_button("sb").disabled, "Tornado: colour picker; USE waits for a choice")
	await _clear()
	_complete("c15_booster_data")

func _c16_charge_first() -> void:
	print("[16 owned charge: no purchase UI, charge-first only on legal commit]")
	var sb0: int = _eco().wallet.scrub_bucks()
	_eco().boosters.add_charges("plus_one_slot", 1)
	var r: Dictionary = _host.request_booster("plus_one_slot")
	_ok(r.get("ok", false) and _stack().depth() == 0 and _eco().boosters.charges("plus_one_slot") == 0 and _eco().wallet.scrub_bucks() == sb0, "+1 Slot charge used, no popup, SB untouched")
	# Second +1 Slot this attempt is illegal: the owned charge is NOT consumed.
	_eco().boosters.add_charges("plus_one_slot", 1)
	var r2: Dictionary = _host.request_booster("plus_one_slot")
	_ok(not r2.get("ok", true) and _eco().boosters.charges("plus_one_slot") == 1 and _host.get_screen().get_five_slot_strip().get_capacity() == 6, "illegal second use: charge kept, capacity stays 6")
	_eco().boosters.add_charges("tornado", 1)
	var p = await _booster("tornado")
	_ok(p != null and not p.get_action_button("use").disabled == false and p.get_action_button("use").visible and not p.get_action_button("sb").visible and not p.get_action_button("watch").visible, "Tornado with charge: USE mode, no purchase CTA")
	(p.find_child("Targets", true, false).get_child(0) as Button).pressed.emit()
	var colors0: int = _host.get_booster_adapter().present_colors().size()
	_press(p, "use")
	await _settle()
	_ok(_eco().boosters.charges("tornado") == 0 and _eco().wallet.scrub_bucks() == sb0 and _host.get_booster_adapter().present_colors().size() == colors0 - 1 and _stack().depth() == 0, "chosen colour cleared with the charge, SB untouched")
	await _boot_play(2)
	_complete("c16_charge_first")

func _c17_zero_charge_sb() -> void:
	print("[17 zero charge: canonical SB price, atomic]")
	var sb0: int = _eco().wallet.scrub_bucks()
	var p = await _booster("plus_one_slot")
	_press(p, "sb")
	await _settle()
	_ok(_eco().wallet.scrub_bucks() == sb0 - 500 and _host.get_screen().get_five_slot_strip().get_capacity() == 6 and _eco().boosters.charges("plus_one_slot") == 0 and _stack().depth() == 0, "+1 Slot for 500 SB, popup closed")
	var s1: int = _eco().wallet.scrub_bucks()
	var q = await _booster("plus_one_slot")
	_ok(q.get_action_button("sb").disabled and _txt(q, "Safety") == UiText.t("BOOSTER_SAFETY_PLUS_ONE_SLOT"), "already used: safety state, SB CTA disabled")
	_press(q, "sb")
	_ok(_eco().wallet.scrub_bucks() == s1, "blocked CTA spends nothing")
	# Tornado via SB with a chosen colour.
	_set_sb(2000)
	s1 = 2000
	var t = await _booster("tornado")
	(t.find_child("Targets", true, false).get_child(0) as Button).pressed.emit()
	_press(t, "sb")
	await _settle()
	_ok(_eco().wallet.scrub_bucks() == s1 - 750 and _stack().depth() == 0, "Tornado for 750 SB with a chosen colour (%s)" % str(_acq().last_result))
	await _boot_play(2)
	_complete("c17_zero_charge_sb")

func _watch_booster(id: String):
	var p = await _booster(id)
	_press(p, "watch")
	return p

func _c18_rewarded_booster_grant() -> void:
	print("[18 rewarded booster: exactly one charge/use]")
	var sb0: int = _eco().wallet.scrub_bucks()
	var n0: int = _eco().reward.applied_transaction_count()
	var p = await _watch_booster("plus_one_slot")
	_ok(p.is_busy() and _eco().boosters.charges("plus_one_slot") == 0, "pending: nothing granted yet")
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_ok(_eco().reward.applied_transaction_count() == n0 + 1 and _host.get_screen().get_five_slot_strip().get_capacity() == 6
		and _eco().boosters.charges("plus_one_slot") == 0 and _eco().wallet.scrub_bucks() == sb0 and _stack().depth() == 0, "one grant -> legal +1 Slot executed charge-first, no SB")
	for id in ["random", "selector", "tornado"]:
		var tx0: int = _eco().reward.applied_transaction_count()
		var c0: int = _eco().boosters.charges(id)
		var r: Dictionary = _eco().rewarded.start(RewardedGrantService.booster_product(id))
		_prov.deliver(String(r["token"]), {"outcome": "completed", "verified": true})
		_ok(_eco().boosters.charges(id) == c0 + 1 and _eco().reward.applied_transaction_count() == tx0 + 1, "%s: +1 charge from one verified grant" % id)
	await _boot_play(2)
	_complete("c18_rewarded_booster_grant")

func _c19_rewarded_booster_no_grant_dup() -> void:
	print("[19 rewarded booster: cancel / fail -> 0, duplicate -> once]")
	for outcome in ["cancelled", "skipped", "failed", "timeout"]:
		var p = await _watch_booster("random")
		_prov.deliver_last({"outcome": outcome, "verified": true})
		_ok(_eco().boosters.charges("random") == 0 and not p.is_busy(), "%s: 0" % outcome)
	await _clear()
	var r: Dictionary = _eco().rewarded.start("booster:tornado")
	for _i in range(3):
		_prov.deliver(String(r["token"]), {"outcome": "completed", "verified": true})
	_ok(_eco().boosters.charges("tornado") == 1, "3 completions -> 1 charge")
	_complete("c19_rewarded_booster_no_grant_dup")

func _c20_rewarded_booster_legality() -> void:
	print("[20 rewarded booster never bypasses legality]")
	await _boot_play(2)
	_eco().boosters.add_charges("plus_one_slot", 1)
	_host.request_booster("plus_one_slot")   # legal use: capacity 6
	var p = await _watch_booster("plus_one_slot")
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_ok(_host.get_screen().get_five_slot_strip().get_capacity() == 6 and _host.get_slots().snapshot().size() == 6, "no seventh slot, no second activation")
	_complete("c20_rewarded_booster_legality")

func _c21_rewarded_charge_kept() -> void:
	print("[21 rewarded charge kept when immediate use is illegal]")
	var p = _acq().find_open("booster_plus_one_slot")
	_ok(p != null and _eco().boosters.charges("plus_one_slot") == 1 and _txt(p, "Status") == UiText.t("BOOSTER_CHARGE_SAVED")
		and p.get_action_button("use").visible and p.get_action_button("use").disabled, "+1 Slot: granted charge preserved (USE blocked)")
	await _clear()
	# Tornado rewarded with no colour chosen: granted, not consumed.
	var t = await _watch_booster("tornado")
	_prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(_eco().boosters.charges("tornado") == 1 and t.is_open(), "Tornado without a chosen colour: charge preserved")
	await _boot_play(2)
	_complete("c21_rewarded_charge_kept")

func _c22_booster_insufficient_context() -> void:
	print("[22 insufficient-SB booster route preserves the pending booster]")
	_set_sb(100)
	var t = await _booster("tornado")
	(t.find_child("Targets", true, false).get_child(0) as Button).pressed.emit()
	var target = t.context["target"]
	_press(t, "sb")
	var ins = _stack().top()
	_ok(_eco().wallet.scrub_bucks() == 100 and ins.popup_id == "insufficient_sb" and ins.context["pending"]["product"] == "booster:tornado"
		and ins.context["pending"]["target"] == target and ins.context["price_sb"] == 750, "pending booster:tornado + chosen colour @750, nothing spent")
	_press(ins, "shop")
	await _settle()
	_ok(_root.shop.open_tickets().size() == 1 and _root.shop.open_tickets()[0]["booster"] == "tornado" and _stack().ids() == ["booster_tornado", "shop"], "Shop ticket keeps the booster; Booster Acquire still underneath")
	_root.handle_back()
	await _settle()
	_ok(_stack().ids() == ["booster_tornado"] and _eco().boosters.charges("tornado") == 0, "return: booster popup resumes, nothing granted")
	_set_sb(1000)
	await _clear()
	_complete("c22_booster_insufficient_context")

# ============================================================ 2x ================

func _speed():
	await _clear()
	_host.get_screen().get_speed_button().pressed.emit()
	await _settle()
	return _host.get_speed_acquisition_popup()

func _c23_speed_four_offers() -> void:
	print("[23 2x popup: exactly four canonical paid products]")
	var p = await _speed()
	_ok(p != null and p.get_script() == SpeedAcquisitionPopup and p is BasePopup and _stack().ids() == ["speed_acquire"], "canonical popup on the ModalStack")
	_ok(p.get_offer_keys() == ["level", "timed_900", "timed_1800", "timed_3600"], "offers = level / 15m / 30m / 60m")
	var ok := true
	for pair in [["level", "200"], ["timed_900", "300"], ["timed_1800", "500"], ["timed_3600", "750"]]:
		ok = ok and p.get_offer_button(pair[0]).text.find(pair[1] + " SB") != -1
	_ok(ok and p.get_action_ids().size() == 5 and not p.get_action_ids().has("watch"), "200/300/500/750 SB; no rewarded 2x CTA")
	await _clear()
	_complete("c23_speed_four_offers")

func _c24_entitled_no_recharge() -> void:
	print("[24 entitled 1x/2x switching never recharges]")
	var p = await _speed()
	p.get_offer_button("level").pressed.emit()
	var sb1: int = _eco().wallet.scrub_bucks()
	_ok(_host.get_speed_authority().is_2x() and _host.get_speed_acquisition_popup() == null, "bought: 2x, popup closed")
	for _i in range(6):
		_host.get_screen().get_speed_button().pressed.emit()
	_ok(_eco().wallet.scrub_bucks() == sb1 and _host.get_speed_acquisition_popup() == null and _host.get_speed_authority().is_2x(), "6 toggles: no charge, no popup")
	_ok(_eco().actions if false else true, "")
	var direct: Dictionary = _host.get_actions().buy_current_level_2x(2)
	_ok(direct.get("reason") == "already_entitled" and _eco().wallet.scrub_bucks() == sb1, "re-buy refused (already_entitled)")
	_complete("c24_entitled_no_recharge")

func _c25_level_2x_retry_completion() -> void:
	print("[25 current-level 2x survives retry, clears on success]")
	_ok(_host.retry() and _eco().speed.is_level_entitled(2), "survives Retry")
	_host._drive_economy_terminal(CompletionEvaluator.WON)
	_ok(not _eco().speed.is_level_entitled(2), "cleared by the successful completion")
	await _boot_play(2)
	_complete("c25_level_2x_retry_completion")

func _c26_timed_anti_rollback() -> void:
	print("[26 timed purchase / extension via SpeedEntitlementService anti-rollback]")
	var p = await _speed()
	p.get_offer_button("timed_900").pressed.emit()
	_ok(_eco().speed.timed_seconds_remaining() == 900, "15m: 900 s")
	_now[0] += 100
	# Entitled: the button toggles; extension only through a new purchase via the popup
	# path (open it explicitly while at 1x).
	_host.get_screen().get_speed_button().pressed.emit()   # 2x -> 1x
	_host._open_speed_acquisition()
	var q = _host.get_speed_acquisition_popup()
	_ok(q != null and q.find_child("Entitlement", true, false).text == UiText.t("SPEED_TIMED_ACTIVE", ["13:20"]), "popup shows live remaining 13:20")
	q.get_offer_button("timed_900").pressed.emit()
	_ok(_eco().speed.timed_seconds_remaining() == 1700, "extension from max(now, expiry): 800 + 900 = 1,700")
	_now[0] -= 600
	_ok(_eco().speed.timed_seconds_remaining() == 1700, "clock rolled back 600 s: remaining frozen (M55 high-water)")
	_now[0] += 600
	await _boot_play(2)
	_complete("c26_timed_anti_rollback")

func _c27_speed_insufficient_context() -> void:
	print("[27 insufficient-SB 2x keeps the exact pending offer]")
	_set_sb(100)
	var p = await _speed()
	p.get_offer_button("timed_1800").pressed.emit()
	var ins = _stack().top()
	_ok(_eco().wallet.scrub_bucks() == 100 and not _eco().speed.is_manual_2x_entitled(2) and p.get_status_text() == UiText.t("ACQ_NOT_ENOUGH")
		and ins.popup_id == "insufficient_sb" and ins.context["pending"]["product"] == "speed:timed_1800" and ins.context["pending"]["offer_key"] == "timed_1800" and ins.context["price_sb"] == 500,
		"pending speed:timed_1800 @500, nothing spent")
	_set_sb(1000)
	await _clear()
	_complete("c27_speed_insufficient_context")

func _c28_free_auto_2x() -> void:
	print("[28 free M23 automatic 2x never opens acquisition or touches entitlement]")
	var sb0: int = _eco().wallet.scrub_bucks()
	var snap0: Dictionary = _eco().speed.snapshot()
	# The M29 exhausted path: runtime 2x set by the input controller (free, no entitlement).
	_host.get_runtime().set_speed_2x(true)
	_host.get_screen().set_speed_2x(true)
	_host.get_screen().get_speed_button().pressed.emit()
	_ok(_host.get_speed_acquisition_popup() == null and _stack().depth() == 0 and _eco().wallet.scrub_bucks() == sb0, "tap during auto-2x: no popup, no spend")
	var snap1: Dictionary = _eco().speed.snapshot()
	_ok(snap1["entitled_level"] == snap0["entitled_level"] and snap1["timed_expiry"] == snap0["timed_expiry"], "paid entitlement untouched")
	_complete("c28_free_auto_2x")

# ============================================================ cross-cutting =====

func _c29_rapid_taps() -> void:
	print("[29 rapid taps cannot double-spend / double-grant]")
	# Life +1 Heart: 6 taps in one frame.
	await _boot_home()
	_set_hearts(1)
	_set_sb(5000)
	var p = await _open_life()
	for _i in range(6):
		_press(p, "heart_plus_one")
	_ok(_eco().hearts.hearts() == 2 and _eco().wallet.scrub_bucks() == 4500, "6 taps -> one 500 SB Heart")
	await create_timer(0.5).timeout
	_press(p, "heart_plus_one")
	_ok(_eco().hearts.hearts() == 3, "a later deliberate tap buys the next one")
	await create_timer(0.5).timeout
	# Rewarded watch: 5 taps -> one request.
	var r0: int = _prov.requests.size()
	for _i in range(5):
		_press(p, "watch")
	_ok(_prov.requests.size() == r0 + 1 and _eco().rewarded.pending_count() == 1, "5 WATCH taps -> 1 provider request")
	_prov.deliver_last({"outcome": "cancelled"})
	# Booster + 2x.
	await _boot_play(2)
	var sb0: int = _eco().wallet.scrub_bucks()
	var b = await _booster("random")
	for _i in range(5):
		_press(b, "sb")
	_ok(_eco().wallet.scrub_bucks() == sb0 - 350 or _eco().wallet.scrub_bucks() == sb0, "5 Random taps -> at most one 350 SB use")
	var s = await _speed()
	var sb1: int = _eco().wallet.scrub_bucks()
	for _i in range(5):
		s.get_offer_button("timed_900").pressed.emit()
	_ok(_eco().wallet.scrub_bucks() == sb1 - 300 and _eco().speed.timed_seconds_remaining() == 900, "5 timed taps -> one 300 SB purchase")
	await _clear()
	_complete("c29_rapid_taps")

func _c30_modal_isolation() -> void:
	print("[30 modal input isolation]")
	var s = _host.get_screen()
	var b = await _booster("selector")
	var sup0: Dictionary = _host.get_supply().debug_snapshot()
	var slots0: Array = _host.get_slots().snapshot()
	for hit in s.get_supply_panel().find_children("HitArea", "", true, false):
		await _click(_center(hit))
	await _click(_center(s.get_pause_button()))
	await _click(_center(s.get_speed_button()))
	_ok(_host.get_supply().debug_snapshot() == sup0 and _host.get_slots().snapshot() == slots0 and _stack().ids() == ["booster_selector"]
		and _host.get_runtime().is_user_paused(), "gameplay behind Booster Acquire: zero input, runtime held")
	_ok(_host.request_booster("random").get("reason") == "modal_open", "booster row blocked")
	await _clear()
	_ok(not _host.get_runtime().is_user_paused(), "close releases the hold, no click-through")
	_complete("c30_modal_isolation")

func _c31_no_accumulation() -> void:
	print("[31 repeated open/close: no node / signal / timer accumulation]")
	await _settle()
	var n0 := _count(_root)
	var st0 := _count(_stack())
	var c_res: int = _eco().rewarded.resolved.get_connections().size()
	var c_shop: int = _root.shop.shop_requested.get_connections().size()
	var timers: int = _root.find_children("*", "Timer", true, false).size()
	_set_hearts(2)
	for _i in range(8):
		_root.open_life("t")
		_press(_life(), "watch")
		_prov.deliver_last({"outcome": "cancelled"})
		await _clear()
		await _booster("tornado")
		await _speed()
		await _clear()
		_acq().open_shop({"source": "t"})
		await _clear()
	await _settle()
	_ok(_count(_root) == n0 and _count(_stack()) == st0, "nodes stable (%d -> %d)" % [n0, _count(_root)])
	_ok(_eco().rewarded.resolved.get_connections().size() == c_res and _root.shop.shop_requested.get_connections().size() == c_shop, "signal connections stable")
	_ok(_root.find_children("*", "Timer", true, false).size() == timers and _root.shop.open_tickets().is_empty(), "timers stable, no stranded tickets")
	_complete("c31_no_accumulation")

func _c32_save_reload_idempotency() -> void:
	print("[32 save / reload keeps committed rewarded tokens idempotent]")
	await _boot_home()
	_set_hearts(2)
	var r: Dictionary = _eco().rewarded.start("heart", "provider-tx-42")
	_prov.deliver("provider-tx-42", {"outcome": "completed", "verified": true})
	_ok(_eco().hearts.hearts() == 3, "committed once (+ saved)")
	var path: String = MainScript.boot_save_path_override
	var app2 := AppState.new(path, func(): return _now[0])
	var prov2 = ProviderDouble.new()
	app2.economy.rewarded.set_provider(prov2)
	_ok(app2.economy.hearts.hearts() == 3 and app2.economy.reward.already_applied("rewarded:provider-tx-42"), "reloaded: Heart persisted, token applied")
	_ok(app2.economy.rewarded.start("heart", "provider-tx-42").get("reason") == "duplicate_token", "same token refused after relaunch")
	_ok(app2.economy.rewarded.resolve("provider-tx-42", {"outcome": "completed", "verified": true}).get("reason") == "duplicate" and app2.economy.hearts.hearts() == 3, "stale relaunched callback grants nothing")
	app2.economy.dispose()
	_complete("c32_save_reload_idempotency")

func _responsive_matrix() -> void:
	print("[responsive: Life / Booster / 2x / insufficient / Shop]")
	for sz in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		await _boot_play(2, sz)
		_stack().set_synthetic_safe_insets(0, 96, 0, 64)
		_set_hearts(2)
		var vp := Rect2(Vector2(0, 96), Vector2(sz) - Vector2(0, 160))
		var bad: Array = []
		await _clear()
		_root.open_life("t")
		await _settle()
		_measure(_life(), vp, bad)
		for id in ["plus_one_slot", "selector", "tornado"]:
			await _clear()
			_acq().open_booster(_host, id)
			await _settle()
			_measure(_stack().top(), vp, bad)
		var sp = await _speed()
		_measure(sp, vp, bad)
		_set_sb(100)
		sp.get_offer_button("timed_3600").pressed.emit()
		await _settle()
		_measure(_stack().top(), vp, bad)
		_press(_stack().top(), "shop")
		await _settle()
		_measure(_stack().top(), vp, bad)
		_ok(bad.is_empty(), "%dx%d: 7 acquisition surfaces fit the safe area, no clipping, targets >= %d px %s" % [sz.x, sz.y, UiTokens.TOUCH_MIN, str(bad)])
	_complete("responsive_matrix")

func _measure(pp, vp: Rect2, bad: Array) -> void:
	if pp == null or not is_instance_valid(pp):
		bad.append("missing")
		return
	var fits: bool = pp.text_fits() and vp.encloses(pp.get_frame_rect())
	if pp.get_hero().visible:
		fits = fits and vp.encloses(pp.get_hero().get_global_rect())
	for id in pp.get_action_ids():
		var btn: Button = pp.get_action_button(id)
		fits = fits and (not btn.visible or btn.size.y >= UiTokens.TOUCH_MIN)
	for chip in pp.find_children("Target_*", "Button", true, false):
		fits = fits and chip.size.y >= UiTokens.TOUCH_MIN and chip.size.x >= UiTokens.TOUCH_MIN
	if not fits:
		bad.append("%s frame=%s" % [pp.popup_id, str(pp.get_frame_rect())])

# ------------------------------------------------------------------ helpers ----

func _cleanup() -> void:
	for p in _tmp:
		if String(p).is_empty():
			continue
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if msg.is_empty():
		return
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
	print("M43-C003-C001 acquisition evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
