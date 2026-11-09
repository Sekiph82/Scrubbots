extends SceneTree
## SB-M57-012 / SB-M57-013 / SB-M43-081 / SB-M43-084 (provider-independent part) — real-money
## store seam with a MockProvider (no SDK, no network): SB packs grant exactly once per purchase
## token (double callback, relaunch, imported save), cancel / failure grant nothing, the No Ads
## entitlement persists, removes banner + interstitials only and is restored, the shipping null
## provider shows UNAVAILABLE and grants nothing, and no price string is ever hand-formatted.
##
## Run: godot --headless --path . -s res://tests/m57_store_products.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const StoreService = preload("res://scripts/economy/store_service.gd")
const StoreProvider = preload("res://scripts/economy/store_provider.gd")
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")

var EXPECTED_CASES := [
	"c01_config_owner_products", "c02_null_provider_unavailable", "c03_pack_grants_once",
	"c04_cancel_fail_grant_nothing", "c05_no_ads_entitlement", "c06_restore_no_ads_only",
	"c07_save_failure_no_ack", "c08_shop_mock_provider", "c09_no_hand_formatted_prices",
]

## Test double: records every call; purchases resolve only when the test calls finish().
class MockProvider extends StoreProvider:
	var available := true
	var prices := {"scrubbucks_100": "US$0.99", "scrubbucks_550": "₺179,99", "scrubbucks_1200": "9,99 €",
		"scrubbucks_2600": "US$19.99", "scrubbucks_7000": "US$49.99", "no_ads": "₺179,99"}
	var owned: Array = []
	var started: Array = []
	var acks: Array = []
	var _deliver: Callable
	func is_available() -> bool:
		return available
	func query_products(ids: Array, deliver: Callable) -> bool:
		var out := {}
		for id in ids:
			if prices.has(id):
				out[id] = prices[id]
		deliver.call(out)
		return true
	func purchase(id: String, deliver: Callable) -> bool:
		started.append(id)
		_deliver = deliver
		return true
	func finish(id: String, token: String, outcome: String = "purchased") -> Dictionary:
		return _deliver.call({"product_id": id, "token": token, "outcome": outcome})
	func restore(deliver: Callable) -> bool:
		deliver.call(owned)
		return true
	func acknowledge(token: String, consume: bool) -> void:
		acks.append([token, consume])

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	_c01()
	_c02()
	_c03()
	_c04()
	_c05()
	_c06()
	_c07()
	await _c08()
	_c09()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _c01() -> void:
	print("[c01 store_products_v1.json = the owner 2026-10-22 products]")
	var s := StoreService.new(EconomyServices.new().reward)
	var packs := {}
	for id in s.sb_pack_ids():
		packs[id] = s.scrub_bucks_of(id)
	_ok(packs == {"scrubbucks_100": 100, "scrubbucks_550": 550, "scrubbucks_1200": 1200, "scrubbucks_2600": 2600, "scrubbucks_7000": 7000}, "five SB packs, ids scrubbucks_<n> %s" % str(packs))
	_ok(s.product_ids() == ["scrubbucks_100", "scrubbucks_550", "scrubbucks_1200", "scrubbucks_2600", "scrubbucks_7000", "no_ads"], "No Ads product id no_ads, config order kept")
	var bad := "user://m57_bad_store.json"
	_tmp.append(bad)
	var f := FileAccess.open(bad, FileAccess.WRITE)
	f.store_string('{"products": [{"id": "scrubbucks_100", "kind": "consumable", "scrub_bucks": -5}]}')
	f.close()
	_ok(StoreService.new(EconomyServices.new().reward, null, bad).product_ids().is_empty() and StoreService.new(EconomyServices.new().reward, null, "user://missing.json").product_ids().is_empty(), "bad / missing config fails closed (no products)")
	_complete("c01_config_owner_products")

func _c02() -> void:
	print("[c02 shipping null provider: UNAVAILABLE, nothing granted]")
	var e := EconomyServices.new()
	var st = e.store
	var sb0: int = e.wallet.scrub_bucks()
	st.refresh_prices()
	_ok(st.get_provider().get_script() == StoreProvider and not st.is_available(), "default provider is the null StoreProvider")
	var all_gated := true
	for id in st.product_ids():
		all_gated = all_gated and st.price_text(id) == "" and st.can_purchase(id)["reason"] == "unavailable" and st.purchase(id)["reason"] == "unavailable"
	_ok(all_gated, "every product: no price, can_purchase/purchase = unavailable")
	_ok(st.restore()["reason"] == "unavailable", "restore unavailable")
	_ok(e.wallet.scrub_bucks() == sb0 and not st.no_ads() and st.ads_allowed("banner") and st.ads_allowed("interstitial"), "nothing granted, ads unchanged")
	_complete("c02_null_provider_unavailable")

func _c03() -> void:
	print("[c03 SB pack grants once per purchase token]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.store.set_provider(m)
	e.store.refresh_prices()
	var sb0: int = e.wallet.scrub_bucks()
	_ok(e.store.price_text("scrubbucks_550") == "₺179,99", "price = the provider's localized string verbatim")
	_ok(e.store.purchase("scrubbucks_550")["ok"] and m.started == ["scrubbucks_550"] and e.wallet.scrub_bucks() == sb0, "purchase opens the store sheet, nothing granted yet")
	_ok(e.store.can_purchase("scrubbucks_550")["reason"] == "pending", "same product blocked while its sheet is open (rapid taps)")
	var r: Dictionary = m.finish("scrubbucks_550", "tokA")
	_ok(r["ok"] and e.wallet.scrub_bucks() == sb0 + 550 and e.reward.already_applied("store:tokA") and m.acks == [["tokA", true]], "purchased -> +550 SB under tx store:tokA, consumed")
	var r2: Dictionary = m.finish("scrubbucks_550", "tokA")
	_ok(not r2["ok"] and r2["reason"] == "duplicate" and e.wallet.scrub_bucks() == sb0 + 550 and m.acks.size() == 2, "double callback: no second grant (re-acknowledged)")
	var snap: Dictionary = e.snapshot()
	var e2 := EconomyServices.new()
	_ok(e2.import_snapshot(snap) and e2.wallet.scrub_bucks() == sb0 + 550, "relaunch: imported save holds the grant")
	var m2 := MockProvider.new()
	e2.store.set_provider(m2)
	var r3: Dictionary = e2.store.deliver({"product_id": "scrubbucks_550", "token": "tokA", "outcome": "purchased"})
	_ok(not r3["ok"] and e2.wallet.scrub_bucks() == sb0 + 550 and m2.acks == [["tokA", true]], "relaunch re-delivery of the same token: no grant, acknowledged")
	var r4: Dictionary = e2.store.deliver({"product_id": "scrubbucks_7000", "token": "tokB", "outcome": "purchased"})
	_ok(r4["ok"] and e2.wallet.scrub_bucks() == sb0 + 550 + 7000, "a new token grants its own pack")
	_complete("c03_pack_grants_once")

func _c04() -> void:
	print("[c04 cancelled / failed / pending / bad results grant nothing]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.store.set_provider(m)
	e.store.refresh_prices()
	var sb0: int = e.wallet.scrub_bucks()
	var n0: int = e.reward.applied_transaction_count()
	for outcome in ["cancelled", "failed", "pending", ""]:
		e.store.purchase("scrubbucks_100")
		var r: Dictionary = m.finish("scrubbucks_100", "tok_" + outcome, outcome)
		_ok(not r["ok"] and r["reason"] == (outcome if outcome != "" else "failed"), "outcome '%s' -> %s" % [outcome, r["reason"]])
	_ok(not e.store.deliver({"product_id": "scrubbucks_100", "token": "", "outcome": "purchased"})["ok"], "purchased without token refused")
	_ok(not e.store.deliver({"product_id": "gems_9999", "token": "tokX", "outcome": "purchased"})["ok"], "unknown product refused")
	_ok(e.wallet.scrub_bucks() == sb0 and e.reward.applied_transaction_count() == n0 and m.acks.is_empty() and not e.store.no_ads(), "no SB, no ledger entry, nothing acknowledged")
	_ok(e.store.can_purchase("scrubbucks_100")["ok"], "after a cancel the pack can be bought again")
	_complete("c04_cancel_fail_grant_nothing")

func _c05() -> void:
	print("[c05 No Ads: persistent entitlement, banner + interstitial off, rewarded stays]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.store.set_provider(m)
	e.store.refresh_prices()
	var sb0: int = e.wallet.scrub_bucks()
	e.store.purchase("no_ads")
	_ok(m.finish("no_ads", "tokN")["ok"] and e.store.no_ads() and m.acks == [["tokN", false]], "No Ads granted, acknowledged as non-consumable")
	_ok(not e.store.ads_allowed("banner") and not e.store.ads_allowed("interstitial") and e.store.ads_allowed("rewarded"), "banner + interstitial removed, rewarded videos stay")
	_ok(e.wallet.scrub_bucks() == sb0 and e.store.can_purchase("no_ads")["reason"] == "owned", "no SB granted; No Ads cannot be bought twice")
	var e2 := EconomyServices.new()
	_ok(e2.import_snapshot(e.snapshot()) and e2.store.no_ads(), "entitlement persists through save/import")
	var old: Dictionary = e.snapshot()
	old.erase("store")
	var e3 := EconomyServices.new()
	_ok(e3.import_snapshot(old) and not e3.store.no_ads(), "a pre-store save (no section) imports without the entitlement")
	var bad: Dictionary = e.snapshot()
	bad["store"] = {"no_ads": 1}
	_ok(not e2.import_snapshot(bad) and e2.store.no_ads(), "malformed store section fails closed (state unchanged)")
	_complete("c05_no_ads_entitlement")

func _c06() -> void:
	print("[c06 Restore re-applies the non-consumable No Ads only]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	m.owned = [{"product_id": "scrubbucks_2600", "token": "tokP"}, {"product_id": "no_ads", "token": "tokN"}]
	e.store.set_provider(m)
	var sb0: int = e.wallet.scrub_bucks()
	var got: Array = []
	e.store.restored.connect(func(r): got.append(r))
	_ok(e.store.restore()["ok"] and got.size() == 1 and int(got[0]["restored"]) == 1, "restore result: one product restored")
	_ok(e.store.no_ads() and e.wallet.scrub_bucks() == sb0 and not e.reward.already_applied("store:tokP"), "No Ads back on a fresh profile; the SB pack is not re-granted")
	e.store.restore()
	_ok(e.store.no_ads() and e.wallet.scrub_bucks() == sb0, "second restore idempotent")
	m.owned = []
	e.store.restore()
	_ok(int(got[-1]["restored"]) == 0, "nothing owned -> restored 0")
	_complete("c06_restore_no_ads_only")

func _c07() -> void:
	print("[c07 grant is saved before the store is acknowledged]")
	var e := EconomyServices.new()
	var m := MockProvider.new()
	e.store.set_provider(m)
	e.store.refresh_prices()
	e.store.bind_save(func(): return {"ok": false, "reason": "disk"})
	e.store.purchase("scrubbucks_100")
	var r: Dictionary = m.finish("scrubbucks_100", "tokS")
	var sb1: int = e.wallet.scrub_bucks()
	_ok(r["ok"] and m.acks.is_empty() and sb1 == EconomyServices.new().wallet.scrub_bucks() + 100, "save failed -> purchase left unacknowledged (store re-delivers it)")
	var saves := [0]
	e.store.bind_save(func():
		saves[0] += 1
		return {"ok": false, "reason": "disk"})
	var r2: Dictionary = e.store.deliver({"product_id": "scrubbucks_100", "token": "tokS", "outcome": "purchased"})
	_ok(r2["reason"] == "duplicate" and saves[0] == 1 and m.acks.is_empty() and e.wallet.scrub_bucks() == sb1, "duplicate re-delivery with a failing save: save retried, still NOT acknowledged, no second grant")
	e.store.bind_save(func():
		saves[0] += 1
		return {"ok": true})
	var r3: Dictionary = e.store.deliver({"product_id": "scrubbucks_100", "token": "tokS", "outcome": "purchased"})
	_ok(r3["reason"] == "duplicate" and saves[0] == 2 and m.acks == [["tokS", true]] and e.wallet.scrub_bucks() == sb1, "later re-delivery with a successful save: acknowledged, no second grant")
	e.store.deliver({"product_id": "scrubbucks_100", "token": "tokS", "outcome": "cancelled"})
	_ok(saves[0] == 2 and m.acks.size() == 1, "a non-purchased delivery never saves or acknowledges")
	_complete("c07_save_failure_no_ack")

func _c08() -> void:
	print("[c08 Shop with a MockProvider: localized prices, buy, No Ads, restore, Home banner]")
	await _boot("c08")
	var app = _root.get_app_state()
	var e = app.economy
	var m := MockProvider.new()
	e.store.set_provider(m)
	_ok(_root.get_home().is_ad_slot_enabled(), "Home banner slot on before No Ads")
	_root.get_acquisition().open_shop({"source": "test"})
	await _frames(2)
	var shop = _top()
	_ok(ShopScreen.of(shop) != null, "Shop open")
	var labels := true
	for id in m.prices:
		var b: Button = shop.get_action_button("buy:store:" + id)
		labels = labels and b != null and b.text == m.prices[id] and not b.disabled
	_ok(labels, "every store button shows the provider's localized string verbatim and is enabled")
	var card = shop.find_child("Item_store_scrubbucks_1200", true, false)
	_ok(card != null and (card.find_child("Title", true, false) as Label).text == UiText.t("SHOP_SB_PACK_ITEM", [UiText.num(1200)]), "pack title from UiText")
	_ok(not shop.get_action_button("restore").disabled, "RESTORE PURCHASES enabled with a store")
	var sb0: int = e.wallet.scrub_bucks()
	shop._on_action("buy:store:scrubbucks_1200")
	await _frames(2)
	_ok(m.started == ["scrubbucks_1200"] and e.wallet.scrub_bucks() == sb0 and _top() == shop, "tap opens the store sheet only (no SB confirm, no grant yet)")
	m.finish("scrubbucks_1200", "tokUI")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 1200 and String(_top().popup_id) == "feedback_success", "store result -> +1200 SB, success feedback after commit")
	_ok(AppStateScript.new(_tmp[-1]).economy.wallet.scrub_bucks() == sb0 + 1200, "grant hit the canonical save (reloaded save holds it)")
	_top().close("test")
	await _frames(2)
	m.finish("scrubbucks_1200", "tokUI")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 1200 and _top() == shop, "duplicate callback: silent, no grant")
	shop._on_action("buy:store:scrubbucks_100")
	m.finish("scrubbucks_100", "tokC", "cancelled")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 1200 and _top() == shop, "cancel: silent, nothing granted")
	shop._on_action("buy:store:no_ads")
	m.finish("no_ads", "tokNA")
	await _frames(2)
	_top().close("test")
	await _frames(2)
	var na: Button = shop.get_action_button("buy:store:no_ads")
	var na_card = shop.find_child("Item_store_no_ads", true, false)
	_ok(e.store.no_ads() and na.disabled and na.text == UiText.t("SHOP_OWNED") and (na_card.find_child("Detail", true, false) as Label).text == UiText.t("SHOP_NO_ADS_OWNED"), "No Ads card shows OWNED")
	_ok(not _root.get_home().is_ad_slot_enabled(), "Home bottom banner slot collapsed by the entitlement")
	shop._on_action("restore")
	await _frames(2)
	_ok(String(_top().popup_id) == "feedback_success", "restore -> feedback")
	_top().close("test")
	await _frames(2)
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("c08_shop_mock_provider")

func _c09() -> void:
	print("[c09 guard: no hand-formatted price strings]")
	var re := RegEx.new()
	re.compile("\\$|USD|usd|€|₺|%\\.2f|reference_usd|price_usd")
	var hits: Array = []
	for f in ["res://scripts/ui/shop/shop_screen.gd", "res://scripts/economy/store_service.gd", "res://scripts/economy/store_provider.gd", "res://scripts/ui/popup/acquisition_flow.gd", "res://scripts/ui/ui_text.gd", "res://scripts/ui/ui_text_tr.gd"]:
		for line in FileAccess.get_file_as_string(f).split("\n"):
			if not line.strip_edges().begins_with("#") and re.search(line) != null:
				hits.append("%s: %s" % [f.get_file(), line.strip_edges()])
	_ok(hits.is_empty(), "no currency symbol / USD / price format in store UI + service code %s" % str(hits))
	var src := FileAccess.get_file_as_string("res://scripts/ui/shop/shop_screen.gd")
	_ok(src.contains("price_text"), "store buttons read StoreService.price_text")
	_complete("c09_no_hand_formatted_prices")

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m57_store_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

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
	print("M57 store products evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
