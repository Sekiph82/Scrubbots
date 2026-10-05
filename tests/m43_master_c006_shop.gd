extends SceneTree
## M43 master — Lane C006 Shop destination (SB-M43-078..089).
## Real app root (main.tscn) + real AppState / facade / ModalStack / ShopHandoff / AcquisitionFlow.
##
## Run: godot --headless --path . -s res://tests/m43_master_c006_shop.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const AppState = preload("res://scripts/app/app_state.gd")

var EXPECTED_CASES := [
	"s01_entries_open_shop", "s02_live_values_no_baked", "s03_buy_commits_through_facade", "s04_cancel_spends_nothing",
	"s05_insufficient_blocked", "s06_hearts_states", "s07_real_money_and_no_ads_gated", "s08_return_context",
	"s09_rapid_taps_single_spend", "s10_failure_feedback_after_authority", "s11_lifecycle_no_duplicate",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	await _s01()
	await _s02()
	await _s03()
	await _s04()
	await _s05()
	await _s06()
	await _s07()
	await _s08()
	await _s09()
	await _s10()
	await _s11()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _s01() -> void:
	print("[s01 Home SHOP panel and SB + open the real Shop]")
	await _boot("s01")
	(_root.get_home().get_region("Shortcut_shop") as Button).pressed.emit()
	await _frames(2)
	_ok(_top_id() == "shop" and ShopScreen.of(_top()) != null, "SHOP panel -> Shop destination")
	_top().close("test")
	await _frames(2)
	_root.get_home().scrub_bucks_purchase_requested.emit()
	await _frames(2)
	_ok(_top_id() == "shop" and String(_top().context.get("source", "")) == "home_sb_plus", "Home SB + -> same Shop (source kept)")
	_complete("s01_entries_open_shop")

func _s02() -> void:
	print("[s02 every value live from the authorities, no baked price]")
	await _boot("s02")
	var s = await _open_shop()
	var e = _eco()
	_ok(_txt("SbValue") == "%s SB" % UiText.num(e.wallet.scrub_bucks()) and _txt("HeartValue") == UiText.t("LIFE_HEARTS", [e.hearts.hearts(), e.hearts.max_hearts()]), "wallet + Hearts")
	var prices := {}
	for p in ["booster:plus_one_slot", "booster:random", "booster:selector", "booster:tornado", "speed:900", "speed:1800", "speed:3600"]:
		prices[p] = int(s.offer(p)["price"])
	_ok(prices == {"booster:plus_one_slot": 500, "booster:random": 350, "booster:selector": 500, "booster:tornado": 750, "speed:900": 300, "speed:1800": 500, "speed:3600": 750}, "prices == economy config %s" % str(prices))
	_ok(_top().get_action_button("buy:booster:random").text == "350 SB", "button label from the live offer")
	e.boosters.add_charges("random", 2)
	s.refresh()
	_ok(_detail("Item_booster_random") == "Owned: 2", "owned charges re-read live")
	_complete("s02_live_values_no_baked")

func _s03() -> void:
	print("[s03 confirm -> facade commit (debit + grant + save) -> feedback]")
	await _boot("s03")
	var s = await _open_shop()
	var e = _eco()
	var sb0: int = e.wallet.scrub_bucks()
	_tap("buy:booster:random")
	await _frames(1)
	_ok(_top_id() == "shop_confirm" and e.wallet.scrub_bucks() == sb0, "confirm first; nothing spent yet")
	_tap("confirm")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 - 350 and e.boosters.charges("random") == 1 and _top_id() == "feedback_success", "350 SB debited, +1 Random charge, success feedback after the commit")
	var re = AppState.new(MainScript.boot_save_path_override)
	_ok(re.economy.boosters.charges("random") == 1 and re.economy.wallet.scrub_bucks() == sb0 - 350, "committed through the canonical save")
	_ok(s.purchase_log().size() == 1 and bool(s.purchase_log()[0][1]["ok"]), "one committed purchase recorded")
	_complete("s03_buy_commits_through_facade")

func _s04() -> void:
	print("[s04 cancel spends nothing and re-arms the Shop]")
	await _boot("s04")
	var s = await _open_shop()
	var sb0: int = _eco().wallet.scrub_bucks()
	_tap("buy:booster:tornado")
	await _frames(1)
	_tap("cancel")
	await _frames(1)
	await create_timer(0.5).timeout
	_ok(_eco().wallet.scrub_bucks() == sb0 and _top_id() == "shop" and not _top().is_latched() and s.purchase_log().is_empty(), "nothing spent; Shop usable again")
	_complete("s04_cancel_spends_nothing")

func _s05() -> void:
	print("[s05 insufficient SB: blocked with the honest shortfall]")
	await _boot("s05")
	_eco().wallet.debit("scrub_bucks", _eco().wallet.scrub_bucks() - 100)
	var s = await _open_shop()
	_ok(_detail("Item_booster_tornado") == "Need 650 more SB" and bool(_top().get_action_button("buy:booster:tornado").disabled), "Tornado blocked, needs 650 more")
	_tap("buy:booster:tornado")
	await _frames(1)
	_ok(_top_id() == "shop" and _eco().wallet.scrub_bucks() == 100, "tap does nothing")
	_complete("s05_insufficient_blocked")

func _s06() -> void:
	print("[s06 Hearts: full -> unavailable; missing -> +1 500 / refill 400 each]")
	await _boot("s06")
	var s = await _open_shop()
	_ok(s.offer("heart_plus_one")["reason"] == "hearts_full" and s.offer("heart_refill")["reason"] == "hearts_full" and _detail("Item_heart_plus_one") == UiText.t("LIFE_FULL"), "full Hearts: both unavailable")
	_eco().hearts.consume()
	_eco().hearts.consume()
	s.refresh()
	_ok(s.offer("heart_plus_one")["price"] == 500 and s.offer("heart_refill")["price"] == 800 and not _top().get_action_button("buy:heart_refill").disabled, "2 missing: +1 = 500, refill = 800")
	var h0: int = _eco().hearts.hearts()
	_tap("buy:heart_refill")
	await _frames(1)
	_tap("confirm")
	await _frames(2)
	_ok(_eco().hearts.hearts() == _eco().hearts.max_hearts() and h0 < _eco().hearts.max_hearts(), "refill committed through HeartService")
	_complete("s06_hearts_states")

func _s07() -> void:
	print("[s07 real-money packs + No Ads: present, explicitly gated by M57]")
	await _boot("s07")
	var s = await _open_shop()
	_ok(_top().get_action_button("buy:sb_pack").disabled and _top().get_action_button("buy:no_ads").disabled and _detail("Item_sb_pack") == UiText.t("SHOP_STORE_LATER") and _detail("Item_no_ads") == UiText.t("SHOP_STORE_LATER"), "both disabled with an honest store-later state")
	var words := " ".join(_top().find_children("*", "Label", true, false).map(func(l): return l.text.to_lower()))
	_ok(not words.contains("gem") and not words.contains("star") and not words.contains("coin") and not words.contains("$"), "one SB economy: no second currency, no cash price")
	var src := FileAccess.get_file_as_string("res://scripts/ui/shop/shop_screen.gd")
	_ok(not src.contains("wallet.debit") and not src.contains("wallet.credit") and not src.contains(".purchase_") and not src.contains("rewarded.") and not src.contains("start_rewarded"), "Shop never mutates balances or calls a provider directly")
	_complete("s07_real_money_and_no_ads_gated")

func _s08() -> void:
	print("[s08 insufficient-SB handoff keeps the exact return context]")
	await _boot("s08")
	_eco().hearts.consume()
	_eco().wallet.debit("scrub_bucks", _eco().wallet.scrub_bucks() - 10)
	var life = _root.open_life("test")
	await _frames(2)
	var acq = _root.get_acquisition()
	acq.open_insufficient({"item_label": "+1 Heart", "price_sb": 500, "balance_sb": 10, "product": "heart_plus_one", "source": "life"})
	await _frames(1)
	_tap("shop")
	await _frames(2)
	var returned: Array = []
	_root.shop.returned.connect(func(t, o): returned.append([t.get("product", ""), t.get("price_sb", 0), o]))
	_ok(_top_id() == "shop" and _txt("PendingProduct") == UiText.t("SHOP_FOR", ["+1 Heart", "500"]) and _top().get_action_button("back").text == "BACK TO +1 Heart", "Shop states the pending product")
	_tap("back")
	await _frames(2)
	_ok(returned == [["heart_plus_one", 500, "cancelled"]] and _top() == life and life.is_open(), "ticket finished with its exact context; Life popup is back on top")
	_complete("s08_return_context")

func _s09() -> void:
	print("[s09 rapid taps never double-spend]")
	await _boot("s09")
	var s = await _open_shop()
	var sb0: int = _eco().wallet.scrub_bucks()
	for _i in range(5):
		_tap("buy:booster:random")
	await _frames(1)
	_ok(_root.get_modal_stack().ids().count("shop_confirm") == 1, "one confirm for 5 taps")
	for _i in range(5):
		_tap("confirm")
	await _frames(2)
	_ok(_eco().wallet.scrub_bucks() == sb0 - 350 and _eco().boosters.charges("random") == 1 and s.purchase_log().size() == 1, "exactly one purchase")
	_complete("s09_rapid_taps_single_spend")

func _s10() -> void:
	print("[s10 failure is reported only from the authority result; nothing celebrated]")
	await _boot("s10")
	var s = await _open_shop()
	_tap("buy:booster:tornado")
	await _frames(1)
	_eco().wallet.debit("scrub_bucks", _eco().wallet.scrub_bucks() - 20)   # balance drops while confirming
	_tap("confirm")
	await _frames(2)
	_ok(_top_id() == "feedback_failure" and _eco().wallet.scrub_bucks() == 20 and _eco().boosters.charges("tornado") == 0, "facade refused: failure feedback, nothing spent, nothing granted")
	_complete("s10_failure_feedback_after_authority")

func _s11() -> void:
	print("[s11 background/resume while confirming: no purchase, no duplicate]")
	await _boot("s11")
	var s = await _open_shop()
	var sb0: int = _eco().wallet.scrub_bucks()
	_tap("buy:booster:selector")
	await _frames(1)
	_root.flush_lifecycle("application_paused")
	_root.flush_lifecycle("focus_out")
	await _frames(1)
	_ok(_top_id() == "shop_confirm" and _eco().wallet.scrub_bucks() == sb0 and s.purchase_log().is_empty(), "lifecycle flush neither buys nor duplicates")
	_tap("confirm")
	await _frames(2)
	_ok(_eco().wallet.scrub_bucks() == sb0 - 500 and s.purchase_log().size() == 1, "the one confirmed purchase still commits once")
	_complete("s11_lifecycle_no_duplicate")

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43master_c006_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _open_shop():
	_root.get_acquisition().open_shop({"source": "test"})
	await _frames(2)
	return ShopScreen.of(_top())

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _txt(n: String) -> String:
	var l = _top().find_child(n, true, false)
	return l.text if l is Label else ""

func _detail(card: String) -> String:
	var c = _top().find_child(card, true, false)
	return (c.find_child("Detail", true, false) as Label).text if c != null else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
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
	print("M43 master C006 Shop evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
