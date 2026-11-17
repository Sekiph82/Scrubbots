extends SceneTree
## SB-M57-014..016 + SB-M57-022 — the real provider adapters (Play Billing, StoreKit inappstore,
## AdMob) driven by fake native backends with the plugins' method / signal / event shapes (no
## SDK, no network, no purchase): editor / headless boots keep the null providers; a purchase
## grants once only on a PURCHASED state and is consumed / finished after the grant; cancel /
## failure / pending grant nothing; launch re-delivery and restore; AdMob waits for UMP consent
## (+ ATT on iOS) before loading anything, a rewarded view grants once only after the earned
## reward, a failed view grants nothing, interstitial / banner follow AdService.
##
## Run: godot --headless --path . -s res://tests/m57_native_providers.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const StoreProvider = preload("res://scripts/economy/store_provider.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const PlayBillingStoreProvider = preload("res://scripts/economy/play_billing_store_provider.gd")
const AppStoreProvider = preload("res://scripts/economy/app_store_provider.gd")
const AdmobAdProvider = preload("res://scripts/economy/admob_ad_provider.gd")

var EXPECTED_CASES := [
	"n01_headless_null_providers", "n02_play_purchase_grants_once", "n03_play_cancel_fail_pending",
	"n04_play_launch_and_restore", "n05_appstore_purchase_finish_restore", "n06_admob_consent_before_ads",
	"n07_admob_rewarded_grants_once", "n08_admob_interstitial_banner", "n09_admob_real_ids_release_only",
]

## GodotGooglePlayBilling singleton double (method names + signals of plugin 3.3.0).
class FakePlay extends RefCounted:
	signal connected
	signal disconnected
	signal query_product_details_response(response: Dictionary)
	signal query_purchases_response(response: Dictionary)
	signal on_purchase_updated(response: Dictionary)
	var calls: Array = []
	var owned: Array = []   ## what queryPurchases reports
	var launch_code := 0
	func initPlugin() -> void:
		calls.append("init")
	func startConnection() -> void:
		calls.append("start")
	func queryProductDetails(ids: PackedStringArray, type: String) -> void:
		calls.append("details:" + type)
		var out: Array = []
		for id in ids:
			out.append({"product_id": id, "one_time_purchase_offer_details_list": [{"formatted_price": "₺%d,99" % id.length()}]})
		query_product_details_response.emit({"response_code": 0, "product_details": out})
	func queryPurchases(type: String, _subs: bool) -> void:
		calls.append("purchases:" + type)
		query_purchases_response.emit({"response_code": launch_code, "purchases": owned})
	func purchase(id: String, _option: String, _offer: String, _personal: bool) -> Dictionary:
		calls.append("purchase:" + id)
		return {"response_code": 0}
	func consumePurchase(token: String) -> void:
		calls.append("consume:" + token)
	func acknowledgePurchase(token: String) -> void:
		calls.append("ack:" + token)

static func play_purchase(id: String, token: String, state: int, acked := false) -> Dictionary:
	return {"product_ids": PackedStringArray([id]), "purchase_token": token, "purchase_state": state, "is_acknowledged": acked}

## InAppStore singleton double (godot-ios-plugins inappstore event queue).
class FakeAppStore extends RefCounted:
	var calls: Array = []
	var events: Array = []
	var auto_finish := true
	func set_auto_finish_transaction(b: bool) -> void:
		auto_finish = b
	func request_product_info(p: Dictionary) -> int:
		calls.append("info")
		events.append({"type": "product_info", "result": "ok", "ids": p["product_ids"],
			"localized_prices": PackedStringArray(Array(p["product_ids"]).map(func(_id): return "US$0.99"))})
		return OK
	func purchase(p: Dictionary) -> int:
		calls.append("purchase:" + String(p["product_id"]))
		return OK
	func restore_purchases() -> int:
		calls.append("restore")
		return OK
	func finish_transaction(id: String) -> void:
		calls.append("finish:" + id)
	func get_pending_event_count() -> int:
		return events.size()
	func pop_pending_event() -> Dictionary:
		return events.pop_front()

## Admob node double (godot-admob v7.0 Admob.gd methods + signals).
class FakeAdmob extends RefCounted:
	signal consent_info_updated
	signal consent_info_update_failed(e)
	signal consent_form_loaded
	signal consent_form_failed_to_load(e)
	signal consent_form_dismissed(e)
	signal tracking_authorization_granted
	signal tracking_authorization_denied
	signal initialization_completed(s)
	signal banner_ad_loaded(a, r)
	signal interstitial_ad_loaded(a, r)
	signal interstitial_ad_failed_to_load(a, e)
	signal interstitial_ad_failed_to_show_full_screen_content(a, e)
	signal interstitial_ad_dismissed_full_screen_content(a)
	signal rewarded_ad_loaded(a, r)
	signal rewarded_ad_failed_to_load(a, e)
	signal rewarded_ad_user_earned_reward(a, r)
	signal rewarded_ad_dismissed_full_screen_content(a)
	signal rewarded_ad_failed_to_show_full_screen_content(a, e)
	class Consent:
		var s := ""
		func to_status_string() -> String:
			return s
	var banner_position := 0
	var is_real := false
	var android_real_banner_id := ""
	var android_real_interstitial_id := ""
	var android_real_rewarded_id := ""
	var ios_real_banner_id := ""
	var ios_real_interstitial_id := ""
	var ios_real_rewarded_id := ""
	var banner_anchor_to_safe_area := false
	var remove_interstitial_ads_after_displayed := false
	var consent := "REQUIRED"
	var form := true
	var calls: Array = []
	func update_consent_info() -> void:
		calls.append("consent_info")
	func get_consent_status():
		var c := Consent.new()
		c.s = consent
		return c
	func is_consent_form_available() -> bool:
		return form
	func load_consent_form() -> void:
		calls.append("load_form")
	func show_consent_form() -> void:
		calls.append("show_form")
	func request_tracking_authorization() -> void:
		calls.append("att")
	func initialize() -> void:
		calls.append("initialize")
	func load_banner_ad() -> void:
		calls.append("load_banner")
	func show_banner_ad() -> void:
		calls.append("show_banner")
	func hide_banner_ad() -> void:
		calls.append("hide_banner")
	func load_interstitial_ad() -> void:
		calls.append("load_interstitial")
	func show_interstitial_ad() -> void:
		calls.append("show_interstitial")
	func load_rewarded_ad() -> void:
		calls.append("load_rewarded")
	func show_rewarded_ad() -> void:
		calls.append("show_rewarded")
	func ads_calls() -> Array:
		return calls.filter(func(c): return c.begins_with("load_banner") or c.begins_with("load_inter") or c.begins_with("load_rew") or c.begins_with("show_banner") or c.begins_with("show_inter") or c.begins_with("show_rew"))

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _n01()
	_n02()
	_n03()
	_n04()
	_n05()
	_n06()
	_n07()
	_n08()
	_n09()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _n01() -> void:
	print("[n01 editor / headless: no native singleton -> null providers, all suites keep mocks]")
	_ok(not Engine.has_singleton(PlayBillingStoreProvider.NATIVE) and not Engine.has_singleton(AppStoreProvider.NATIVE) and not Engine.has_singleton(AdmobAdProvider.NATIVE), "no GodotGooglePlayBilling / InAppStore / AdmobPlugin singleton here")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	get_root().add_child(sub)
	var path := "user://m57_native_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await process_frame
	var e = root.get_app_state().economy
	_ok(e.store.get_provider().get_script() == StoreProvider and not e.store.is_available(), "real app boot: store provider = null StoreProvider (unavailable)")
	_ok(e.ads.get_provider().get_script() == AdProvider and e.rewarded.get_provider() == e.ads.get_provider(), "real app boot: ad provider = null AdProvider, shared with rewarded")
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	_complete("n01_headless_null_providers")

func _play_store() -> Array:
	var e := EconomyServices.new()
	var b := FakePlay.new()
	var saves := [0]
	e.store.bind_save(func(): saves[0] += 1; return {"ok": true})
	e.store.set_provider(PlayBillingStoreProvider.new(b, Callable(e.store, "deliver")))
	return [e, b, saves]

func _n02() -> void:
	print("[n02 Play: query -> purchase -> PURCHASED grants once, consumed after the save]")
	var e := EconomyServices.new()
	var b := FakePlay.new()
	var saves := [0]
	e.store.bind_save(func(): saves[0] += 1; return {"ok": true})
	e.store.set_provider(PlayBillingStoreProvider.new(b, Callable(e.store, "deliver")))
	_ok(b.calls == ["init", "start"] and not e.store.is_available(), "init + startConnection; unavailable until connected")
	b.connected.emit()
	_ok(e.store.is_available() and b.calls[-1] == "purchases:inapp", "connected -> available, launch queryPurchases")
	e.store.refresh_prices()
	_ok(e.store.price_text("scrubbucks_550") == "₺14,99" and b.calls.has("details:inapp"), "localized price = the store's formatted_price verbatim")
	var sb0: int = e.wallet.scrub_bucks()
	_ok(e.store.purchase("scrubbucks_550")["ok"] and b.calls[-1] == "purchase:scrubbucks_550", "purchase sheet started")
	var upd := {"response_code": 0, "purchases": [play_purchase("scrubbucks_550", "gpa.1", PlayBillingStoreProvider.STATE_PURCHASED)]}
	b.on_purchase_updated.emit(upd)
	_ok(e.wallet.scrub_bucks() == sb0 + 550 and saves[0] == 1 and b.calls[-1] == "consume:gpa.1", "PURCHASED -> +550 SB, saved, then consumePurchase")
	b.on_purchase_updated.emit(upd)
	_ok(e.wallet.scrub_bucks() == sb0 + 550 and e.reward.already_applied("store:gpa.1"), "duplicate update -> no second grant (tx store:gpa.1)")
	_ok(e.store.purchase("no_ads")["ok"], "No Ads purchase started")
	b.on_purchase_updated.emit({"response_code": 0, "purchases": [play_purchase("no_ads", "gpa.2", PlayBillingStoreProvider.STATE_PURCHASED)]})
	_ok(e.store.no_ads() and b.calls[-1] == "ack:gpa.2" and not b.calls.has("consume:gpa.2"), "No Ads -> entitlement, acknowledgePurchase (never consumed)")
	_complete("n02_play_purchase_grants_once")

func _n03() -> void:
	print("[n03 Play: cancel / error / pending grant nothing; pending then PURCHASED grants once]")
	var t := _play_store()
	var e = t[0]
	var b: FakePlay = t[1]
	b.connected.emit()
	e.store.refresh_prices()
	var sb0: int = e.wallet.scrub_bucks()
	var n0: int = e.reward.applied_transaction_count()
	var got: Array = []
	e.store.resolved.connect(func(_id, r): got.append(r))
	e.store.purchase("scrubbucks_100")
	b.on_purchase_updated.emit({"response_code": PlayBillingStoreProvider.USER_CANCELED})
	_ok(got[-1]["reason"] == "cancelled" and e.store.can_purchase("scrubbucks_100")["ok"], "USER_CANCELED -> cancelled, sheet closed")
	e.store.purchase("scrubbucks_100")
	b.on_purchase_updated.emit({"response_code": 6})
	_ok(got[-1]["reason"] == "failed", "ERROR -> failed")
	e.store.purchase("scrubbucks_100")
	b.on_purchase_updated.emit({"response_code": 0, "purchases": [play_purchase("scrubbucks_100", "gpa.p", PlayBillingStoreProvider.STATE_PENDING)]})
	_ok(got[-1]["reason"] == "pending" and e.wallet.scrub_bucks() == sb0 and e.reward.applied_transaction_count() == n0 and not b.calls.has("consume:gpa.p"), "PENDING -> nothing granted, not consumed")
	b.on_purchase_updated.emit({"response_code": 0, "purchases": [play_purchase("scrubbucks_100", "gpa.p", PlayBillingStoreProvider.STATE_PURCHASED)]})
	_ok(e.wallet.scrub_bucks() == sb0 + 100 and b.calls[-1] == "consume:gpa.p", "Play later reports PURCHASED -> +100 once, consumed")
	b.on_purchase_updated.emit({"response_code": 0, "purchases": [play_purchase("scrubbucks_100", "gpa.p", PlayBillingStoreProvider.STATE_PURCHASED)]})
	_ok(e.wallet.scrub_bucks() == sb0 + 100, "repeat -> still once")
	_complete("n03_play_cancel_fail_pending")

func _n04() -> void:
	print("[n04 Play: launch re-delivers unfinished purchases; restore re-applies No Ads only]")
	var t := _play_store()
	var e = t[0]
	var b: FakePlay = t[1]
	b.owned = [play_purchase("scrubbucks_1200", "gpa.u", PlayBillingStoreProvider.STATE_PURCHASED),
		play_purchase("no_ads", "gpa.n", PlayBillingStoreProvider.STATE_PURCHASED, true),
		play_purchase("scrubbucks_100", "gpa.w", PlayBillingStoreProvider.STATE_PENDING)]
	var sb0: int = e.wallet.scrub_bucks()
	b.connected.emit()
	_ok(e.wallet.scrub_bucks() == sb0 + 1200 and b.calls.has("consume:gpa.u"), "unconsumed PURCHASED pack at launch -> granted + consumed")
	_ok(not e.store.no_ads() and not b.calls.has("ack:gpa.n") and not e.reward.already_applied("store:gpa.w"), "acknowledged No Ads not re-delivered; pending not granted")
	var restored: Array = []
	e.store.restored.connect(func(r): restored.append(r))
	_ok(e.store.restore()["ok"] and restored[-1]["restored"] == 1 and e.store.no_ads(), "Restore -> No Ads entitlement back")
	_ok(e.wallet.scrub_bucks() == sb0 + 1200 and not b.calls.has("ack:gpa.n"), "restore grants no SB again; already-acknowledged No Ads is not re-acknowledged")
	b.owned = [play_purchase("no_ads", "gpa.x", PlayBillingStoreProvider.STATE_PURCHASED)]
	var t2 := _play_store()
	t2[1].owned = b.owned
	t2[1].connected.emit()
	_ok(t2[0].store.no_ads() and t2[1].calls.count("ack:gpa.x") == 1, "unacknowledged No Ads at launch -> entitlement + one acknowledgePurchase")
	var t3 := _play_store()
	t3[1].launch_code = 6
	t3[1].connected.emit()
	var r3: Array = []
	t3[0].store.restored.connect(func(r): r3.append(r))
	t3[0].store.restore()
	_ok(r3[-1]["restored"] == 0 and not t3[0].store.no_ads(), "store error on restore -> nothing restored")
	_complete("n04_play_launch_and_restore")

func _n05() -> void:
	print("[n05 StoreKit: auto-finish off, purchase grants once then finishes, restore]")
	var e := EconomyServices.new()
	var b := FakeAppStore.new()
	var p := AppStoreProvider.new(b, Callable(e.store, "deliver"))
	e.store.set_provider(p)
	_ok(not b.auto_finish and e.store.is_available(), "set_auto_finish_transaction(false)")
	b.events.append({"type": "purchase", "result": "ok", "product_id": "scrubbucks_2600", "transaction_id": "2000001"})
	var sb0: int = e.wallet.scrub_bucks()
	p.poll()
	_ok(e.wallet.scrub_bucks() == sb0 + 2600 and b.calls[-1] == "finish:scrubbucks_2600", "unfinished transaction at launch -> +2600, then finish_transaction")
	e.store.refresh_prices()
	p.poll()
	_ok(e.store.price_text("scrubbucks_100") == "US$0.99", "product_info localized price verbatim")
	_ok(e.store.purchase("scrubbucks_100")["ok"] and b.calls[-1] == "purchase:scrubbucks_100", "purchase started")
	var got: Array = []
	e.store.resolved.connect(func(_id, r): got.append(r))
	b.events.append({"type": "purchase", "result": "progress", "product_id": "scrubbucks_100", "type_code": 0})
	p.poll()
	_ok(got.is_empty(), "Purchasing progress -> nothing delivered")
	b.events.append({"type": "purchase", "result": "progress", "product_id": "scrubbucks_100", "type_code": AppStoreProvider.STATE_DEFERRED})
	p.poll()
	_ok(got[-1]["reason"] == "pending" and e.wallet.scrub_bucks() == sb0 + 2600, "Deferred (Ask to Buy) -> pending, nothing granted")
	e.store.purchase("scrubbucks_100")
	b.events.append({"type": "purchase", "result": "error", "product_id": "scrubbucks_100", "error": "cancelled"})
	p.poll()
	_ok(got[-1]["reason"] == "failed" and e.wallet.scrub_bucks() == sb0 + 2600, "error -> failed, nothing")
	e.store.purchase("scrubbucks_100")
	var ev := {"type": "purchase", "result": "ok", "product_id": "scrubbucks_100", "transaction_id": "2000002"}
	b.events.append(ev)
	b.events.append(ev.duplicate())
	p.poll()
	_ok(e.wallet.scrub_bucks() == sb0 + 2700 and b.calls.count("finish:scrubbucks_100") == 2, "same transaction twice -> +100 once; finished after each saved delivery")
	b.events.append({"type": "restore", "result": "ok", "product_id": "no_ads", "transaction_id": "2000003"})
	b.events.append({"type": "restore", "result": "completed"})
	var restored: Array = []
	e.store.restored.connect(func(r): restored.append(r))
	_ok(e.store.restore()["ok"] and b.calls[-1] == "restore", "restore_purchases started")
	p.poll()
	_ok(restored.size() == 1 and restored[0]["restored"] == 1 and e.store.no_ads() and e.wallet.scrub_bucks() == sb0 + 2700, "restore events -> No Ads only")
	_complete("n05_appstore_purchase_finish_restore")

func _n06() -> void:
	print("[n06 AdMob: UMP consent first, then ATT (iOS), then the SDK; nothing loads before]")
	var n := FakeAdmob.new()
	var p := AdmobAdProvider.new(n, true)
	_ok(n.banner_position == AdmobAdProvider.POSITION_BOTTOM and n.banner_anchor_to_safe_area and n.remove_interstitial_ads_after_displayed, "bottom banner in the safe area; single-use interstitials")
	var e := EconomyServices.new()
	e.ads.set_provider(p)
	p.start()
	_ok(n.calls == ["consent_info"] and n.ads_calls().is_empty(), "start -> update_consent_info only")
	n.consent_info_updated.emit()
	n.consent_form_loaded.emit()
	_ok(n.calls == ["consent_info", "load_form", "show_form"], "status REQUIRED -> consent form loaded and shown")
	n.consent_form_dismissed.emit(null)
	_ok(n.calls[-1] == "att" and not n.calls.has("initialize") and n.ads_calls().is_empty(), "iOS: form closed -> ATT prompt, still no SDK / ad")
	_ok(not e.rewarded.is_available("heart") and not e.ads.try_interstitial(), "before the SDK: no rewarded, no interstitial")
	n.tracking_authorization_denied.emit()
	_ok(n.calls[-1] == "initialize", "ATT answered (denied) -> initialize")
	n.initialization_completed.emit(null)
	_ok(n.calls.has("load_interstitial") and n.calls.has("load_rewarded") and n.calls.has("load_banner"), "SDK ready -> loads interstitial, rewarded and the wanted banner")
	var n2 := FakeAdmob.new()
	n2.consent = "OBTAINED"
	var p2 := AdmobAdProvider.new(n2, false)
	p2.start()
	n2.consent_info_updated.emit()
	_ok(n2.calls == ["consent_info", "initialize"], "Android, consent already obtained -> no form, no ATT, initialize")
	var n3 := FakeAdmob.new()
	AdmobAdProvider.new(n3, false).start()
	n3.consent_info_update_failed.emit(null)
	_ok(n3.calls == ["consent_info", "initialize"], "consent info error -> SDK still initialized (it applies the stored consent)")
	_complete("n06_admob_consent_before_ads")

func _ready_admob(e) -> FakeAdmob:
	var n := FakeAdmob.new()
	var p := AdmobAdProvider.new(n, false)
	e.ads.set_provider(p)
	p.start()
	n.consent = "NOT_REQUIRED"
	n.consent_info_updated.emit()
	n.initialization_completed.emit(null)
	return n

func _n07() -> void:
	print("[n07 AdMob rewarded: earned reward + close grants once; close without it / failure grant nothing]")
	var e := EconomyServices.new()
	var n := _ready_admob(e)
	_ok(not e.rewarded.is_available("booster:tornado"), "no rewarded loaded yet -> not offered")
	n.rewarded_ad_loaded.emit(null, null)
	_ok(e.rewarded.is_available("booster:tornado"), "loaded -> offered")
	var c0: int = e.boosters.charges("tornado")
	var s: Dictionary = e.rewarded.start("booster:tornado")
	_ok(s["ok"] and n.calls[-1] == "show_rewarded" and not e.rewarded.is_available("booster:tornado"), "start -> show_rewarded_ad; no second offer while it is up")
	n.rewarded_ad_user_earned_reward.emit(null, null)
	_ok(e.boosters.charges("tornado") == c0, "earned reward alone grants nothing until the ad closes")
	n.rewarded_ad_dismissed_full_screen_content.emit(null)
	_ok(e.boosters.charges("tornado") == c0 + 1 and e.reward.already_applied("rewarded:" + String(s["token"])), "earned + closed -> +1 charge under rewarded:<token>")
	n.rewarded_ad_dismissed_full_screen_content.emit(null)
	_ok(e.boosters.charges("tornado") == c0 + 1 and n.calls[-1] == "load_rewarded", "duplicate close -> nothing; next video loading")
	n.rewarded_ad_loaded.emit(null, null)
	var s2: Dictionary = e.rewarded.start("booster:tornado")
	n.rewarded_ad_dismissed_full_screen_content.emit(null)
	_ok(e.rewarded.result_for(s2["token"])["reason"] == "cancelled" and e.boosters.charges("tornado") == c0 + 1, "closed early (no reward) -> cancelled, nothing")
	n.rewarded_ad_loaded.emit(null, null)
	var s3: Dictionary = e.rewarded.start("booster:tornado")
	n.rewarded_ad_user_earned_reward.emit(null, null)
	n.rewarded_ad_failed_to_show_full_screen_content.emit(null, null)
	_ok(e.rewarded.result_for(s3["token"])["reason"] == "failed" and e.boosters.charges("tornado") == c0 + 1, "failed to show -> failed, nothing")
	n.rewarded_ad_failed_to_load.emit(null, null)
	_ok(not e.rewarded.is_available("booster:tornado") and n.calls[-1] == "load_rewarded", "load failure -> not offered, the next check reloads")
	_complete("n07_admob_rewarded_grants_once")

func _n08() -> void:
	print("[n08 AdMob interstitial / banner follow AdService]")
	var e := EconomyServices.new()
	var n := _ready_admob(e)
	for _i in range(5):
		e.ads.on_play_finished()
	_ok(not e.ads.try_interstitial() and e.ads.interstitial_due() and not n.calls.has("show_interstitial"), "due but not loaded -> not shown, stays due")
	n.interstitial_ad_loaded.emit(null, null)
	_ok(e.ads.try_interstitial() and n.calls[-1] == "show_interstitial" and not e.ads.interstitial_due(), "loaded -> shown at the transition, cadence restarts")
	n.interstitial_ad_dismissed_full_screen_content.emit(null)
	_ok(n.calls[-1] == "load_interstitial", "closed -> next one loading")
	n.interstitial_ad_failed_to_load.emit(null, null)
	for _i in range(5):
		e.ads.on_play_finished()
	_ok(not e.ads.try_interstitial() and n.calls[-1] == "load_interstitial", "failed load -> retried at the next due transition")
	_ok(n.calls.count("load_banner") == 1 and not n.calls.has("show_banner"), "banner requested once, not shown before it loads")
	n.banner_ad_loaded.emit(null, null)
	_ok(n.calls[-1] == "show_banner", "banner loaded -> shown")
	_ok(e.reward.grant("store:tokNA", {"store_no_ads": 1}) and e.store.no_ads(), "No Ads bought")
	e.ads.update_banner()
	_ok(n.calls[-1] == "hide_banner", "No Ads -> banner hidden")
	for _i in range(10):
		e.ads.on_play_finished()
	n.interstitial_ad_loaded.emit(null, null)
	_ok(not e.ads.try_interstitial() and n.calls.count("show_interstitial") == 1, "No Ads -> no interstitial even when one is loaded")
	_complete("n08_admob_interstitial_banner")

func _n09() -> void:
	print("[n09 real AdMob ids only from the CI-generated release file; otherwise TEST ids]")
	var n := FakeAdmob.new()
	AdmobAdProvider.new(n, false)
	_ok(not ResourceLoader.exists(AdmobAdProvider.REAL_IDS) and not n.is_real and n.android_real_banner_id == "", "no generated file (every debug / test build) -> is_real false, Google TEST units")
	var path := "user://m57_native_real_ids_%d.gd" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string('const IDS := {"banner": "B", "interstitial": "I", "rewarded": "R"}')
	f.close()
	var a := FakeAdmob.new()
	AdmobAdProvider.new(a, false, path)
	_ok(a.is_real and [a.android_real_banner_id, a.android_real_interstitial_id, a.android_real_rewarded_id] == ["B", "I", "R"] and a.ios_real_banner_id == "", "release file on Android -> is_real + android real unit ids")
	var i := FakeAdmob.new()
	AdmobAdProvider.new(i, true, path)
	_ok(i.is_real and [i.ios_real_banner_id, i.ios_real_interstitial_id, i.ios_real_rewarded_id] == ["B", "I", "R"] and i.android_real_banner_id == "", "release file on iOS -> is_real + ios real unit ids")
	_complete("n09_admob_real_ids_release_only")

# ------------------------------------------------------------------ helpers ----

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		for extra in ["_analytics.json", "_cloud.json"]:
			var f: String = p.get_basename() + extra
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
	print("M57 native providers evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
