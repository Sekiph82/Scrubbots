extends SceneTree
## M43-C004-C001 — Fail / Retry / Need a Hand evidence (SB-M43-050..062).
## Real app root (main.tscn) with an injected wall clock, real ProductionGameplayHost +
## GameplayScreen on catalog level 2, the ONE ModalStack / AcquisitionFlow / ShopHandoff,
## the canonical AppState economy + save + FailureAssistanceService, and the test-double
## rewarded provider on the provider-neutral seam (production default stays unavailable).
##
## Run: godot --headless --path . -s res://tests/m43_c004_c001_fail_need_a_hand.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const FailureAssistanceService = preload("res://scripts/economy/failure_assistance_service.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000
const LEVEL := 2
const PRICES := {"plus_one_slot": 500, "random": 350, "selector": 500, "tornado": 750}

var EXPECTED_CASES := [
	"t01_lost_one_heart", "t02_retry_no_second_heart", "t03_home_no_second_loss", "t04_zero_heart_retry_life",
	"t05_fail_no_victory_replay_ad", "t06_fail_committed_truth", "t07_fail1_no_assist", "t08_fail2_no_assist",
	"t09_fail3_due_once", "t10_fail4_suppressed", "t11_win_reset", "t12_level_change_reset", "t13_replay_excluded",
	"t14_two_distinct", "t15_meaningful_next_start", "t16_deterministic", "t17_fail_closed", "t18_two_cards",
	"t19_t20_t21_per_card_ctas", "t22_no_shared_cta", "t23_no_no_thanks", "t24_x_zero_mutation", "t25_back_equals_x",
	"t26_canonical_prices", "t27_buy_one_charge", "t28_insufficient_shop", "t29_ad_grants_card_charge",
	"t30_ad_no_grant", "t31_ad_duplicate_background", "t32_one_card_unavailable", "t33_owned_charge_first",
	"t34_no_terminal_execution", "t35_modal_isolation", "t36_rapid_taps", "t37_lifecycle_20", "t38_responsive",
	"t39_reduced_effects_parity", "config_and_events", "production_provider_unavailable", "perf_third_failure_levels_1_10",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _host
var _prov
var _events: Array = []

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _t01_t02_t03_t04()
	await _t05_t06()
	await _counter_cases()
	await _t11_win_reset()
	await _t12_level_change_reset()
	await _t13_replay_excluded()
	await _recommendation_cases()
	await _t17_fail_closed()
	await _card_cases()
	await _dismissal_cases()
	await _buy_cases()
	await _rewarded_cases()
	await _t33_owned_charge_first()
	await _t34_no_terminal_execution()
	await _t35_t36()
	await _t37_lifecycle_20()
	await _t38_responsive()
	await _t39_reduced_effects_parity()
	_config_and_events()
	await _production_provider_unavailable()
	await _perf_third_failure()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot_play(level: int = LEVEL, size: Vector2i = Vector2i(1080, 2160), double := true) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43c004_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	if double:
		_prov = ProviderDouble.new()
		_eco().rewarded.set_provider(_prov)
	_events = []
	_assist().assistance_event.connect(func(k, d): _events.append([k, d]))
	_set_frontier(level)
	_set_hearts(5)
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

func _assist():
	return _root.get_app_state().assist

func _nav():
	return _root.get_navigation()

func _stack():
	return _root.get_modal_stack()

func _acq():
	return _root.get_acquisition()

func _res():
	return _root.get_results_screen()

func _nah():
	return _acq().find_open("need_a_hand")

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

## Canonical (saveable) frontier: levels 1..n-1 completed.
func _set_frontier(n: int) -> void:
	_root.get_app_state().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": n, "completed": range(1, n)})

func _set_hearts(n: int) -> void:
	_eco().hearts.import_snapshot({"hearts": n, "anchor": _now[0]})

func _set_sb(n: int) -> void:
	var w = _eco().wallet
	var cur: int = w.scrub_bucks()
	if cur > n:
		w.debit("scrub_bucks", cur - n)
	elif cur < n:
		w.credit("scrub_bucks", n - cur)

func _press(p, id: String) -> void:
	p.get_action_button(id).pressed.emit()

func _first_action() -> bool:
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			return true
	return false

## One authoritative terminal LOST through the real completion signal (host economy +
## save + assistance first, then the app root's Results route).
func _lose() -> void:
	_host.get_completion().terminal_reached.emit(&"LOST", {})
	await _settle()

## From Fail: close any popup, transaction-safe Retry (same host), back to GAMEPLAY.
func _retry() -> bool:
	_stack().clear("t")
	await _settle()
	if _eco().hearts.hearts() == 0:
		_set_hearts(5)   # fixture: Hearts are not under test here (t04 covers the gate)
	var ok: bool = _root.retry_from_results()
	await _settle()
	return ok

## Fail `n` times in a row on the current host (retrying between failures).
func _fail_times(n: int) -> void:
	for i in range(n):
		if _nav().current() == R.RESULTS:
			await _retry()
		await _lose()

func _econ_snap() -> Dictionary:
	return {"sb": _eco().wallet.scrub_bucks(), "hearts": _eco().hearts.hearts(), "streak": _eco().streak.streak(),
		"boosters": _eco().boosters.snapshot(), "applied": _eco().reward.applied_transaction_count()}

func _board_snap() -> Array:
	var b = _host.get_board()
	var out: Array = []
	for i in range(b.get_cell_count()):
		out.append(b.get_cell_state(i))
	return [out, _host.get_supply().debug_snapshot(), _host.get_slots().snapshot()]

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _picks(offer: Dictionary) -> Array:
	return (offer.get("picks", []) as Array).map(func(p): return p["id"])

func _card(p, id: String) -> Control:
	return p.find_child("Card_" + id, true, false)

func _buttons_in(n: Node) -> Array:
	return n.find_children("*", "Button", true, false).filter(func(b): return not b.is_queued_for_deletion())

func _visible_buttons(n: Node) -> Array:
	return _buttons_in(n).filter(func(b): return b.is_visible_in_tree())

## Third due failure on a fresh app -> Need a Hand open. Returns the popup.
func _third_failure(sb := 5000):
	await _boot_play()
	_set_sb(sb)
	await _fail_times(3)
	return _nah()

# ============================================================ terminal / retry ====

func _t01_t02_t03_t04() -> void:
	print("[01 LOST consumes exactly one Heart]")
	await _boot_play()
	_ok(_first_action(), "first real action armed (gameplay started)")
	var h0: int = _eco().hearts.hearts()
	await _lose()
	var rc: Dictionary = _host.get_terminal_receipt()
	_ok(_eco().hearts.hearts() == h0 - 1 and rc["hearts"] == {"before": h0, "after": h0 - 1} and _nav().current() == R.RESULTS, "LOST: %d -> %d Hearts, receipt matches, Fail shown" % [h0, h0 - 1])
	_ok(not _eco().streak.gameplay_started(), "terminal LOST cleared the attempt's gameplay-started flag")
	_complete("t01_lost_one_heart")

	print("[02 Retry after LOST consumes no second Heart / no second streak reset]")
	var st0: int = _eco().streak.streak()
	_ok(await _retry() and _nav().current() == R.GAMEPLAY, "Retry: transaction-safe restore, back to GAMEPLAY")
	_ok(_eco().hearts.hearts() == h0 - 1 and _eco().streak.streak() == st0, "one LOST + Retry: Hearts changed exactly once total (%d -> %d)" % [h0, _eco().hearts.hearts()])
	_ok(_host.get_terminal_receipt().is_empty() and not _host.get_completion().is_terminal(), "fresh attempt: receipt cleared, PLAYING")
	_complete("t02_retry_no_second_heart")

	print("[03 Home after LOST applies no second loss]")
	await _lose()
	var after_loss := _econ_snap()
	_res().get_home_button().pressed.emit()
	await _settle()
	_ok(_nav().current() == R.HOME and _econ_snap() == after_loss, "Fail Home: HOME, Hearts/streak/SB/charges unchanged")
	_complete("t03_home_no_second_loss")

	print("[04 0 Hearts -> Retry opens Life]")
	await _boot_play()
	_set_hearts(1)
	await _lose()
	var attempt: int = _nav().attempt_id()
	_ok(_eco().hearts.hearts() == 0, "terminal loss left 0 Hearts")
	_res().get_primary_button().pressed.emit()
	await _settle()
	_ok(_stack().ids() == ["life"] and _nav().current() == R.RESULTS and _nav().attempt_id() == attempt and _eco().hearts.hearts() == 0,
		"Retry at 0 Hearts: canonical Life popup, no retry, nothing consumed")
	_complete("t04_zero_heart_retry_life")

func _t05_t06() -> void:
	print("[05 Fail: production family, no Victory / Replay / ad CTA]")
	await _boot_play()
	_eco().streak.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 4, "processed": [1]})
	var h0: int = _eco().hearts.hearts()
	await _lose()
	var res = _res()
	_ok(res.visible and not res.is_victory_layout() and res.theme != null, "Fail uses the production family theme, not the Victory layout")
	_ok(res.get_robot().texture != null and res.get_robot().texture.resource_path == ResultsScreen.FAIL_ROBOT_ART
		and res.get_emblem().texture.resource_path == ResultsScreen.FAIL_EMBLEM_ART, "existing approved help Scrubby + fail emblem")
	var tex_paths: Array = res.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture != null).map(func(t): return t.texture.resource_path)
	_ok(not tex_paths.has(ResultsScreen.ROBOT_ART) and not tex_paths.has(ResultsScreen.EMBLEM_ART), "no Victory art anywhere on Fail")
	var texts: Array = _visible_buttons(res).map(func(b): return b.text)
	_ok(texts == [UiText.t("RESULTS_RETRY"), UiText.t("RESULTS_HOME")], "exactly Retry (primary) + Home: %s" % str(texts))
	var joined := " ".join(texts).to_upper()
	_ok(joined.find("REPLAY") == -1 and joined.find("AD") == -1 and joined.find("WATCH") == -1, "no Replay, no ad CTA")
	_ok(res.get_primary_button().size.y >= UiTokens.TOUCH_MIN and res.get_home_button().size.y >= UiTokens.TOUCH_MIN, "touch targets >= %d" % UiTokens.TOUCH_MIN)
	_complete("t05_fail_no_victory_replay_ad")

	print("[06 Fail reads committed loss truth]")
	var rc: Dictionary = _host.get_terminal_receipt()
	var rows: Array = res.shown_row_texts()
	_ok(rows == [UiText.t("FAIL_HEARTS", [h0, h0 - 1]), UiText.t("FAIL_STREAK_RESET", [4])] and rc["streak"] == {"before": 4, "after": 0},
		"rows = receipt: %s" % str(rows))
	_ok(res.find_child("LevelLabel", true, false).text == UiText.t("RESULTS_LEVEL", [LEVEL]) and res.find_child("Title", true, false).text == UiText.t("RESULTS_LOST"), "LEVEL FAILED + live level")
	var snap := _econ_snap()
	for _i in range(3):
		res.show_model(res.get_model())
	_ok(_econ_snap() == snap and res.shown_row_texts() == rows, "re-showing Fail mutates nothing")
	_ok(ResultsScreen.loss_rows({"status": "WON", "hearts": {"before": 5, "after": 5}}).is_empty(), "loss rows only from a LOST receipt")
	_complete("t06_fail_committed_truth")

# ============================================================ assistance counter ====

func _counter_cases() -> void:
	print("[07-10 same-level failure counter]")
	await _boot_play()
	await _fail_times(1)
	_ok(_assist().state()["count"] == 1 and not _host.get_assistance_offer()["due"] and _nah() == null, "fail 1: no assistance")
	_complete("t07_fail1_no_assist")
	await _fail_times(1)
	_ok(_assist().state()["count"] == 2 and not _host.get_assistance_offer()["due"] and _nah() == null, "fail 2: no assistance")
	_complete("t08_fail2_no_assist")
	await _fail_times(1)
	var nah = _nah()
	_ok(_assist().state()["count"] == 3 and _host.get_assistance_offer()["due"] and nah != null and _stack().ids() == ["need_a_hand"], "fail 3: Need a Hand due + open over Fail")
	_ok(_events.filter(func(e): return e[0] == "assistance_due").size() == 1 and _events.filter(func(e): return e[0] == "assistance_shown").size() == 1, "due + shown events exactly once")
	_res().show_model(_res().get_model())
	_ok(_stack().depth() == 1, "re-showing Fail does not reopen it")
	_complete("t09_fail3_due_once")
	for n in [4, 5, 6]:
		await _fail_times(1)
		_ok(_assist().state()["count"] == n and not _host.get_assistance_offer()["due"] and _nah() == null, "fail %d: suppressed (V1 once until reset)" % n)
	_ok(_events.filter(func(e): return e[0] == "assistance_suppressed").size() == 3, "suppression recorded for 4/5/6")
	_complete("t10_fail4_suppressed")

func _t11_win_reset() -> void:
	print("[11 progression win resets]")
	var s := FailureAssistanceService.new()
	for st in ["LOST", "LOST", "WON", "LOST", "LOST"]:
		s.record_terminal(5, st, true)
	_ok(s.state()["count"] == 2 and not s.state()["due"], "service: LOST LOST WON LOST LOST -> count 2")
	_ok(s.record_terminal(5, "LOST", true)["due"], "next LOST is the new third -> due")
	await _boot_play()
	await _fail_times(2)
	await _retry()
	_host.get_completion().terminal_reached.emit(&"WON", {})
	await _settle()
	_ok(_assist().state()["count"] == 0 and _events.any(func(e): return e[0] == "reset_win"), "real progression WON on the host resets the count")
	_complete("t11_win_reset")

func _t12_level_change_reset() -> void:
	print("[12 progression level change resets]")
	var s := FailureAssistanceService.new()
	s.record_terminal(5, "LOST", true)
	s.record_terminal(5, "LOST", true)
	var r := s.record_terminal(6, "LOST", true)
	_ok(r["count"] == 1 and r["level"] == 6 and not r["due"], "service: 2 fails on L5 then L6 -> count 1")
	await _boot_play()
	await _fail_times(2)
	_set_frontier(3)
	_res().get_home_button().pressed.emit()
	await _settle()
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_ok(_host.progression_level == 3 and _assist().state()["count"] == 0 and _events.any(func(e): return e[0] == "reset_level_change"), "new level attempt resets (event)")
	await _fail_times(1)
	_ok(_assist().state()["count"] == 1 and _nah() == null, "first failure on the new level counts 1")
	_complete("t12_level_change_reset")

func _t13_replay_excluded() -> void:
	print("[13 replay / non-frontier failures excluded]")
	var s := FailureAssistanceService.new()
	s.record_terminal(5, "LOST", true)
	var r := s.record_terminal(5, "LOST", false)
	_ok(not r["counted"] and s.state()["count"] == 1, "service: replay LOST not counted")
	await _boot_play()
	await _fail_times(2)
	_set_frontier(LEVEL + 1)   # level 2 is now a replay
	await _retry()
	await _lose()
	_ok(not _host.is_progression_attempt() and _assist().state()["count"] == 2 and _nah() == null
		and _events.any(func(e): return e[0] == "excluded_non_progression"), "replay failure: count stays 2, no Need a Hand")
	_set_frontier(LEVEL)
	await _fail_times(1)
	_ok(_assist().state()["count"] == 3 and _nah() != null, "back on the frontier: the next failure is the third")
	_complete("t13_replay_excluded")

# ============================================================ recommendations ======

func _recommendation_cases() -> void:
	print("[14-16 recommendations]")
	await _third_failure()
	var offer: Dictionary = _host.get_assistance_offer()
	var ids := _picks(offer)
	_ok(offer["show"] and ids.size() == 2 and ids[0] != ids[1] and PRICES.has(ids[0]) and PRICES.has(ids[1]), "exactly 2 distinct canonical boosters: %s" % str(ids))
	_complete("t14_two_distinct")
	var leg: Dictionary = _host.next_start_legality()
	_ok(bool(leg[ids[0]]) and bool(leg[ids[1]]), "both proved legal on the next canonical start-state: %s" % str(leg))
	var b0 := _board_snap()
	_host.next_start_legality()
	_ok(_board_snap() == b0, "next-start proofs never touch the terminal board/supply/slots")
	_complete("t15_meaningful_next_start")
	var ctx: Dictionary = _host.terminal_context()
	var a: Dictionary = _assist().recommend(_host.next_start_prover(), ctx)
	var b: Dictionary = _assist().recommend(_host.next_start_prover(), ctx)
	_ok(a == b and _picks(a) == ids, "same input -> same pair/order")
	await _third_failure()
	_ok(_picks(_host.get_assistance_offer()) == ids, "a fresh app on the same level picks the same pair/order")
	var stub := func(id): return true
	var r1: Dictionary = _assist().recommend(stub, {"slots_full": true, "dominant_color": false, "supply_remaining": false})
	var r2: Dictionary = _assist().recommend(stub, {"slots_full": false, "dominant_color": true, "supply_remaining": false})
	_ok(_picks(r1) == ["plus_one_slot", "selector"] and _picks(r2)[0] == "tornado", "context ranks deterministically (slots_full -> +1 Slot; dominant colour -> Tornado)")
	_complete("t16_deterministic")

func _t17_fail_closed() -> void:
	print("[17 fewer than two meaningful -> fail closed]")
	var only_one := func(id): return id == "tornado"
	var r: Dictionary = _assist().recommend(only_one, {})
	_ok(not r["ok"] and r["picks"].is_empty() and r["reason"] == "insufficient_meaningful", "service: one legal booster -> no recommendation")
	_ok(_acq().open_need_a_hand({"show": true, "picks": [{"id": "tornado"}]}) == null
		and _acq().open_need_a_hand({"show": true, "picks": [{"id": "tornado"}, {"id": "tornado"}]}) == null
		and _acq().open_need_a_hand({"show": true, "picks": [{"id": "tornado"}, {"id": "fifth"}]}) == null
		and _acq().open_need_a_hand({"show": false, "picks": [{"id": "tornado"}, {"id": "random"}]}) == null, "popup refuses anything but two distinct canonical boosters")
	await _boot_play()
	await _fail_times(2)
	_host.supply_plan_path = "res://data/missing_plan_for_c004.json"   # next start-state unprovable
	await _fail_times(1)
	var offer: Dictionary = _host.get_assistance_offer()
	_ok(offer["due"] and not offer["show"] and offer["reason"] == "insufficient_meaningful" and _nah() == null
		and _events.any(func(e): return e[0] == "assistance_fail_closed"), "third failure without two proofs: no Need a Hand, reason recorded")
	_ok(_res().visible and not _res().get_primary_button().disabled and await _retry(), "Fail / Retry stay usable")
	_complete("t17_fail_closed")

# ============================================================ Need a Hand UI ======

func _card_cases() -> void:
	print("[18-23 Need a Hand cards]")
	var p = await _third_failure()
	var ids: Array = p.context["boosters"]
	var cards: Array = p.find_children("Card_*", "", true, false)
	_ok(cards.size() == 2 and _card(p, ids[0]) != null and _card(p, ids[1]) != null, "exactly two booster cards")
	for c in cards:
		_ok(c.find_child("Icon", true, false).texture != null and c.find_child("Name", true, false).text != "" and c.find_child("Benefit", true, false).text != ""
			and c.find_child("Owned", true, false).text == UiText.t("NAH_OWNED", [0]), "%s: icon / name / benefit / owned 0" % c.name)
	_complete("t18_two_cards")
	var buys := 0
	var watches := 0
	for id in ids:
		var vis: Array = _visible_buttons(_card(p, id))
		var buy = vis.filter(func(b): return b.text == UiText.t("NAH_BUY", [UiText.num(PRICES[id])]))
		var watch = vis.filter(func(b): return b.text == UiText.t("NAH_WATCH"))
		_ok(buy.size() == 1 and watch.size() == 1 and vis.size() == 2, "%s card: its own BUY · %d SB + its own WATCH AD" % [id, PRICES[id]])
		buys += buy.size()
		watches += watch.size()
	_ok(buys == 2 and watches == 2, "two zero-charge cards -> 2 BUY + 2 WATCH AD")
	_complete("t19_t20_t21_per_card_ctas")
	var footer_btns: Array = _buttons_in(p.find_child("Footer", true, false))
	var action_ids: Array = p.get_action_ids()
	action_ids.sort()
	var want := ["buy:" + ids[0], "buy:" + ids[1], "watch:" + ids[0], "watch:" + ids[1]]
	want.sort()
	var owned_ok := true
	for aid in action_ids:
		owned_ok = owned_ok and _card(p, aid.split(":")[1]).is_ancestor_of(p.get_action_button(aid))
	_ok(footer_btns.is_empty() and action_ids == want and owned_ok, "no shared CTA: every action lives inside its own card %s" % str(action_ids))
	_complete("t22_no_shared_cta")
	var all_text := " ".join(_buttons_in(p).map(func(b): return b.text.to_upper()))
	_ok(all_text.find("THANKS") == -1 and p.get_close_button().visible and p.dismissible, "no NO THANKS; top-right X present")
	var x: Rect2 = p.get_close_button().get_global_rect()
	var fr: Rect2 = p.get_frame_rect()
	_ok(x.get_center().x > fr.get_center().x + fr.size.x * 0.3 and x.get_center().y < fr.position.y + fr.size.y * 0.2, "X sits top-right of the frame")
	_ok(p.find_child("NoGuarantee", true, false).text == UiText.t("NAH_NO_GUARANTEE"), "no guarantee-of-win claim")
	_complete("t23_no_no_thanks")

func _dismissal_cases() -> void:
	print("[24-25 X / Back: zero mutation]")
	var p = await _third_failure()
	var e0 := _econ_snap()
	var a0: Dictionary = _assist().state()
	var b0 := _board_snap()
	var attempt: int = _nav().attempt_id()
	p.get_close_button().pressed.emit()
	await _settle()
	_ok(_nah() == null and _stack().depth() == 0, "X closes Need a Hand")
	_ok(_econ_snap() == e0 and _assist().state() == a0 and _board_snap() == b0 and _nav().current() == R.RESULTS and _nav().attempt_id() == attempt,
		"X: no spend / grant / counter change / auto-Retry")
	_ok(_res().visible and not _res().get_primary_button().disabled, "returns to a usable Fail")
	_complete("t24_x_zero_mutation")
	_acq().open_need_a_hand(_host.get_assistance_offer())
	await _settle()
	_ok(_root.handle_back() == "close_modal", "Back consumed by the popup")
	await _settle()
	_ok(_nah() == null and _nav().current() == R.RESULTS and _econ_snap() == e0 and _assist().state() == a0, "Back == X (no leak to Results Back -> Home)")
	_acq().open_need_a_hand(_host.get_assistance_offer())
	await _settle()
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	_sub.push_input(esc)
	await _settle()
	_ok(_nah() == null and _nav().current() == R.RESULTS and _econ_snap() == e0, "Escape == X")
	_complete("t25_back_equals_x")

func _buy_cases() -> void:
	print("[26-28 SB purchase per card]")
	await _boot_play()
	var cfg = _eco().config
	var price_ok := true
	for id in PRICES:
		price_ok = price_ok and int(cfg.booster_price(id)) == PRICES[id]
	_ok(price_ok, "EconomyConfig prices = 500 / 350 / 500 / 750")
	var p = await _third_failure(2000)
	var ids: Array = p.context["boosters"]
	for id in ids:
		_ok(p.get_action_button("buy:" + id).text == UiText.t("NAH_BUY", [UiText.num(PRICES[id])]), "%s BUY shows canonical %d SB" % [id, PRICES[id]])
	_complete("t26_canonical_prices")
	var commits: Array = []
	_root.get_app_state().actions.action_committed.connect(func(a, r): commits.append([a, r]))
	var id0: String = ids[0]
	var other: int = _eco().boosters.charges(ids[1])
	_press(p, "buy:" + id0)
	_ok(_eco().boosters.charges(id0) == 1 and _eco().boosters.charges(ids[1]) == other and _eco().wallet.scrub_bucks() == 2000 - PRICES[id0], "enough SB: -%d SB, exactly +1 %s charge" % [PRICES[id0], id0])
	_ok(commits.size() == 1 and commits[0][0] == "buy_booster_charge" and bool(commits[0][1]["save"]["ok"]), "committed once + saved once")
	var app2 := AppState.new(MainScript.boot_save_path_override, func(): return _now[0])
	_ok(app2.economy.boosters.charges(id0) == 1 and app2.economy.wallet.scrub_bucks() == 2000 - PRICES[id0], "persisted charge + debit")
	app2.economy.dispose()
	_ok(_eco().boosters.buy_charge("fifth_booster")["reason"] == "unknown_booster" and _eco().wallet.scrub_bucks() == 2000 - PRICES[id0], "unknown booster id: nothing moves")
	_complete("t27_buy_one_charge")
	await create_timer(0.5).timeout
	var id1: String = ids[1]
	_set_sb(100)
	var e0 := _econ_snap()
	_press(p, "buy:" + id1)
	await _settle()
	var ins = _stack().top()
	_ok(_econ_snap() == e0 and ins.popup_id == "insufficient_sb" and ins.context["pending"]["product"] == "booster:" + id1
		and ins.context["pending"]["source"] == "need_a_hand" and ins.context["pending"]["booster"] == id1 and ins.context["price_sb"] == PRICES[id1],
		"insufficient: no debit / grant, pending booster:%s @%d" % [id1, PRICES[id1]])
	_press(ins, "shop")
	await _settle()
	var t: Dictionary = _root.shop.open_tickets()[0] if _root.shop.open_tickets().size() == 1 else {}
	_ok(t.get("booster") == id1 and t.get("source") == "need_a_hand" and t.get("level") == LEVEL and _stack().ids() == ["need_a_hand", "shop"], "Shop ticket keeps exact booster/price/return context; Need a Hand underneath")
	_root.handle_back()
	await _settle()
	_ok(_stack().ids() == ["need_a_hand"] and _econ_snap() == e0, "return from Shop: Need a Hand resumes, nothing moved")
	_complete("t28_insufficient_shop")

func _rewarded_cases() -> void:
	print("[29-31 rewarded per card]")
	var p = await _third_failure()
	var ids: Array = p.context["boosters"]
	var e0 := _econ_snap()
	_press(p, "watch:" + ids[1])
	_ok(p.is_busy() and _prov.requests.back()[0] == RewardedGrantService.placement("booster:" + ids[1]) and _eco().boosters.charges(ids[1]) == 0, "WATCH AD on card B requests exactly booster:%s; nothing granted yet" % ids[1])
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_ok(_eco().boosters.charges(ids[1]) == 1 and _eco().boosters.charges(ids[0]) == 0 and _eco().wallet.scrub_bucks() == e0["sb"]
		and p.is_open() and not p.is_busy(), "verified completion: exactly +1 %s charge, other card untouched, no SB" % ids[1])
	_ok(not _visible_buttons(_card(p, ids[1])).size() and _visible_buttons(_card(p, ids[0])).size() == 2, "card B flips to OWNED; card A keeps both CTAs")
	_complete("t29_ad_grants_card_charge")
	for outcome in [{"outcome": "cancelled"}, {"outcome": "skipped"}, {"outcome": "failed"}, {"outcome": "timeout"}, {"outcome": "completed", "verified": false}, {"outcome": "completed"}]:
		_press(p, "watch:" + ids[0])
		_prov.deliver_last(outcome)
		await _settle()
		_ok(_eco().boosters.charges(ids[0]) == 0 and not p.is_busy(), "%s: 0 charges" % str(outcome))
	_press(p, "watch:" + ids[0])
	p.get_node("PendingTimeout").timeout.emit()   # UI safety timeout abandons
	_prov.deliver_last({"outcome": "completed", "verified": true})
	_ok(_eco().boosters.charges(ids[0]) == 0, "late completion after UI timeout: 0")
	_complete("t30_ad_no_grant")
	await create_timer(0.5).timeout
	_press(p, "watch:" + ids[0])
	var tok: String = _prov.last_token()
	_root.flush_lifecycle("application_paused")
	_root.flush_lifecycle("focus_out")
	for _i in range(3):
		_prov.deliver(tok, {"outcome": "completed", "verified": true})
	_root.flush_lifecycle("application_paused")
	_prov.deliver(tok, {"outcome": "completed", "verified": true})
	await _settle()
	_ok(_eco().boosters.charges(ids[0]) == 1, "background/resume + 4 duplicate completions -> exactly one charge")
	var app2 := AppState.new(MainScript.boot_save_path_override, func(): return _now[0])
	_ok(app2.economy.reward.already_applied("rewarded:" + tok) and app2.economy.boosters.charges(ids[0]) == 1, "grant saved with its token (relaunch-safe)")
	app2.economy.dispose()
	_complete("t31_ad_duplicate_background")

	print("[32 one card unavailable keeps the other card's ad]")
	await _boot_play()
	_set_sb(5000)
	await _fail_times(3)
	p = _nah()
	ids = p.context["boosters"]
	_prov.per_placement[RewardedGrantService.placement("booster:" + ids[0])] = false
	_acq()._refresh_nah(p)
	_ok(p.get_action_button("watch:" + ids[0]).visible and p.get_action_button("watch:" + ids[0]).disabled
		and _card(p, ids[0]).find_child("Note", true, false).text == UiText.t("NAH_AD_UNAVAILABLE"), "card A: WATCH AD shown, disabled, 'No video right now'")
	_ok(not p.get_action_button("watch:" + ids[1]).disabled and not p.get_action_button("buy:" + ids[0]).disabled, "card B ad and card A BUY stay enabled")
	_press(p, "watch:" + ids[1])
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_ok(_eco().boosters.charges(ids[1]) == 1 and _eco().boosters.charges(ids[0]) == 0, "card B ad grants independently")
	_complete("t32_one_card_unavailable")

func _t33_owned_charge_first() -> void:
	print("[33 owned charge: charge-first card]")
	await _boot_play()
	await _fail_times(2)
	# The pair is deterministic for this level: own a charge of the first pick in advance.
	var pick0: String = _picks(_assist().recommend(_host.next_start_prover(), _host.terminal_context()))[0]
	_eco().boosters.add_charges(pick0, 2)
	await _fail_times(1)
	var p = _nah()
	var ids: Array = p.context["boosters"]
	_ok(ids[0] == pick0, "recommended booster %s is owned" % pick0)
	_ok(_visible_buttons(_card(p, pick0)).is_empty() and _card(p, pick0).find_child("Owned", true, false).text == UiText.t("NAH_OWNED", [2])
		and _card(p, pick0).find_child("Note", true, false).text == UiText.t("NAH_OWNED_READY"), "owned card: OWNED x2 / ready, no BUY / WATCH pressure")
	_ok(_visible_buttons(_card(p, ids[1])).size() == 2, "zero-charge card keeps BUY + WATCH AD")
	_complete("t33_owned_charge_first")

func _t34_no_terminal_execution() -> void:
	print("[34 acquisition never executes a booster on the terminal board]")
	await _boot_play()
	_set_sb(5000)
	await _fail_times(2)
	await _retry()
	_first_action()
	for _i in range(20):
		_host.get_runtime().tick(0.05)
	await _lose()
	var p = _nah()
	var ids: Array = p.context["boosters"]
	var b0 := _board_snap()
	var req0: Dictionary = _host.last_booster_request.duplicate(true)
	var cap0: int = _host.get_screen().get_five_slot_strip().get_capacity()
	_press(p, "buy:" + ids[0])
	await create_timer(0.5).timeout   # the non-closing BUY latches the popup until re-armed
	_press(p, "watch:" + ids[1])
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _settle()
	_ok(_eco().boosters.charges(ids[0]) == 1 and _eco().boosters.charges(ids[1]) == 1, "both charges saved")
	_ok(_board_snap() == b0 and _host.last_booster_request == req0 and _host.get_screen().get_five_slot_strip().get_capacity() == cap0
		and not _eco().capacity.plus_one_active(), "terminal board / supply / slots / capacity untouched; no booster executed")
	await _retry()
	var cap_before: int = _host.get_screen().get_five_slot_strip().get_capacity()
	var used := false
	for id in ids:
		if id == "plus_one_slot" or id == "random":
			var r: Dictionary = _host.request_booster(id)
			used = used or bool(r.get("ok", false))
	_ok(cap_before == 5, "Retry starts a fresh five-slot attempt")
	if ids.has("plus_one_slot") or ids.has("random"):
		_ok(used, "saved charge is used on the next attempt through the canonical gameplay path")
	_complete("t34_no_terminal_execution")

func _t35_t36() -> void:
	print("[35 modal isolation over Fail]")
	var p = await _third_failure()
	var e0 := _econ_snap()
	var attempt: int = _nav().attempt_id()
	await _click(_res().get_primary_button().get_global_rect().get_center())
	await _click(_res().get_home_button().get_global_rect().get_center())
	_ok(_nav().current() == R.RESULTS and _nav().attempt_id() == attempt and _econ_snap() == e0 and _stack().ids() == ["need_a_hand"], "clicks on Fail behind Need a Hand do nothing")
	_ok(p.is_top() and _stack().depth() == 1, "Need a Hand is the one input owner")
	_complete("t35_modal_isolation")

	print("[36 rapid taps]")
	var ids: Array = p.context["boosters"]
	_set_sb(5000)
	for _i in range(6):
		_press(p, "buy:" + ids[0])
	_ok(_eco().boosters.charges(ids[0]) == 1 and _eco().wallet.scrub_bucks() == 5000 - PRICES[ids[0]], "6 BUY taps in one frame -> one purchase")
	await create_timer(0.5).timeout
	var r0: int = _prov.requests.size()
	for _i in range(5):
		_press(p, "watch:" + ids[1])
	_ok(_prov.requests.size() == r0 + 1 and _eco().rewarded.pending_count() == 1, "5 WATCH taps -> 1 provider request")
	p.get_close_button().pressed.emit()
	_ok(p.is_open() and p.is_busy(), "X refused while the video is pending (C003 busy safety)")
	_prov.deliver_last({"outcome": "cancelled"})
	await _settle()
	_complete("t36_rapid_taps")

func _t37_lifecycle_20() -> void:
	print("[37 20 Fail -> Need a Hand -> close cycles]")
	await _boot_play()
	_assist().repeat_every = 1   # test seam: every failure from the 3rd on is due
	await _fail_times(3)
	_nah().get_close_button().pressed.emit()
	await _settle()
	var n0 := _count(_root)
	var c_res: int = _eco().rewarded.resolved.get_connections().size()
	var c_modal: int = _stack().modal_changed.get_connections().size()
	var timers: int = _root.find_children("*", "Timer", true, false).size()
	var opened := 0
	for _i in range(20):
		_set_hearts(5)
		await _retry()
		await _lose()
		if _nah() != null:
			opened += 1
			_nah().get_close_button().pressed.emit()
		await _settle()
	await _settle()
	_ok(opened == 20, "20 cycles opened Need a Hand 20 times")
	_ok(_count(_root) == n0, "nodes stable (%d -> %d)" % [n0, _count(_root)])
	_ok(_eco().rewarded.resolved.get_connections().size() == c_res and _stack().modal_changed.get_connections().size() == c_modal
		and _root.find_children("*", "Timer", true, false).size() == timers, "signal connections + timers stable")
	_complete("t37_lifecycle_20")

func _t38_responsive() -> void:
	print("[38 responsive matrix: Fail + Need a Hand]")
	for sz in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		await _boot_play(LEVEL, sz)
		_stack().set_synthetic_safe_insets(0, 96, 0, 64)
		var vp := Rect2(Vector2.ZERO, Vector2(sz))
		var safe := Rect2(Vector2(0, 96), Vector2(sz) - Vector2(0, 160))
		await _fail_times(3)
		await _settle()
		var bad: Array = []
		var res = _res()
		for c in [res.get_panel(), res.get_robot(), res.get_primary_button(), res.get_home_button()]:
			if not vp.encloses(c.get_global_rect()):
				bad.append("fail:" + c.name)
		for b in [res.get_primary_button(), res.get_home_button()]:
			if b.size.y < UiTokens.TOUCH_MIN:
				bad.append("fail_touch:" + b.name)
		var p = _nah()
		if p == null:
			bad.append("no_need_a_hand")
		else:
			if not (p.text_fits() and safe.encloses(p.get_frame_rect())):
				bad.append("frame %s" % str(p.get_frame_rect()))
			var fr: Rect2 = p.get_frame_rect()
			for id in p.context["boosters"]:
				if not fr.encloses(_card(p, id).get_global_rect()):
					bad.append("card " + id)
			var n_vis := 0
			for aid in p.get_action_ids():
				var b: Button = p.get_action_button(aid)
				if b.visible:
					n_vis += 1
					if b.size.y < UiTokens.TOUCH_MIN or b.get_combined_minimum_size().x > b.size.x + 0.5 or not fr.encloses(b.get_global_rect()):
						bad.append("cta " + aid)
			if n_vis != 4:
				bad.append("ctas=%d" % n_vis)
			var x: Button = p.get_close_button()
			if not (x.visible and safe.encloses(x.get_global_rect()) and x.size.y >= UiTokens.TOUCH_MIN):
				bad.append("x")
		_ok(bad.is_empty(), "%dx%d: Fail + Need a Hand (2 cards, 2 BUY + 2 WATCH AD, X) fit, targets >= %d %s" % [sz.x, sz.y, UiTokens.TOUCH_MIN, str(bad)])
	_complete("t38_responsive")

func _t39_reduced_effects_parity() -> void:
	print("[39 Reduced Effects: logic parity]")
	await _boot_play()
	await _fail_times(3)
	var normal: Dictionary = _host.get_assistance_offer()
	var normal_rows: Array = _res().shown_row_texts()
	await _boot_play()
	_root.get_app_state().set_reduced_effects(true)
	await _fail_times(3)
	var reduced: Dictionary = _host.get_assistance_offer()
	_ok(reduced == normal and _nah() != null, "same counter / offer / popup with Reduced Effects")
	_ok(_res().shown_row_texts() == normal_rows and _res().get_reward_lines_node().get_children().all(func(c): return c.modulate.a == 1.0), "Fail rows identical and shown immediately")
	_complete("t39_reduced_effects_parity")

func _config_and_events() -> void:
	print("[config versioned + analytics seam]")
	var s := FailureAssistanceService.new()
	_ok(s.config_ok and s.trigger == 3 and s.repeat_every == 0 and s.count == 2 and s.fallback_order.size() == 4, "failure_assistance_v1.json: trigger 3, repeat 0 (once until reset), 2 picks")
	var bad := FailureAssistanceService.new("res://data/config/does_not_exist.json")
	var r: Dictionary = bad.record_terminal(4, "LOST", true)
	bad.record_terminal(4, "LOST", true)
	r = bad.record_terminal(4, "LOST", true)
	_ok(not bad.config_ok and not r["due"] and not bad.recommend(func(_i): return true, {})["ok"], "missing config fails closed (never due, no recommendation)")
	var kinds: Array = []
	s.assistance_event.connect(func(k, _d): kinds.append(k))
	for st in ["LOST", "LOST", "LOST", "LOST"]:
		s.record_terminal(9, st, true)
	s.record_terminal(9, "LOST", false)
	s.record_terminal(9, "WON", true)
	_ok(kinds == ["failure_counted", "failure_counted", "failure_counted", "assistance_due", "failure_counted", "assistance_suppressed", "excluded_non_progression", "reset_win"], "event seam: %s" % str(kinds))
	_complete("config_and_events")

func _production_provider_unavailable() -> void:
	print("[production provider: WATCH AD shown but unavailable, no fake grant]")
	await _boot_play(LEVEL, Vector2i(1080, 2160), false)
	await _fail_times(3)
	var p = _nah()
	var ok := p != null
	if ok:
		for id in p.context["boosters"]:
			ok = ok and p.get_action_button("watch:" + id).visible and p.get_action_button("watch:" + id).disabled
		_press(p, "watch:" + p.context["boosters"][0])
		ok = ok and _eco().rewarded.pending_count() == 0
	_ok(ok, "default provider: both WATCH AD controls present + disabled, nothing requested")
	_complete("production_provider_unavailable")

## Headless CPU timing of the synchronous third-failure terminal (economy + save +
## assistance decision + Results + Need a Hand build) on every shipped catalog level, plus
## the all-four proof cost as a diagnostic. Not device/GPU evidence.
func _perf_third_failure() -> void:
	print("[perf: third-failure terminal, catalog levels 1..10]")
	var rows: Array = []
	var ok := true
	for lvl in range(1, 11):
		await _boot_play(lvl)
		await _fail_times(2)
		await _retry()
		var t0 := Time.get_ticks_usec()
		_host.get_completion().terminal_reached.emit(&"LOST", {})
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		await _settle()
		var offer: Dictionary = _host.get_assistance_offer()
		var t1 := Time.get_ticks_usec()
		_host.next_start_legality()
		var all_ms := (Time.get_ticks_usec() - t1) / 1000.0
		ok = ok and offer["show"] and _nah() != null and ms < 1500.0
		rows.append("L%d %dx%d terminal=%.0fms picks=%s (all-four proofs %.0fms)" % [lvl, _host.get_level().width, _host.get_level().height, ms, str(_picks(offer)), all_ms])
	for r in rows:
		print("    " + r)
	_ok(ok, "all 10 levels: two-card offer, third-failure terminal < 1500 ms headless")
	_complete("perf_third_failure_levels_1_10")

# ------------------------------------------------------------------ helpers ----

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
	print("M43-C004-C001 fail / need-a-hand evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
