extends SceneTree
## SB-M57-014..016 + SB-M57-022 — the real provider adapters (Play Billing, StoreKit inappstore,
## AdMob) driven by fake native backends with the plugins' method / signal / event shapes (no
## SDK, no network, no purchase): editor / headless boots keep the null providers; a purchase
## grants once only on a PURCHASED state and is consumed / finished after the grant; cancel /
## failure / pending grant nothing; launch re-delivery and restore; AdMob waits for UMP consent
## (+ ATT on iOS) before loading anything, a rewarded view grants once only after the earned
## reward, a failed view grants nothing, interstitial / banner follow AdService.
## SB-TF-01: the store's error text / code reaches StoreService.resolved and the Shop failure
## text; failed / partial product queries are logged with no price; failed ad loads retry with
## a bounded backoff; an unavailable / failed rewarded video has a player-facing text.
## SB-TF-07: the App Open ad (plugin v7.0 load_app_open_ad / show_app_open_ad + app_open_ad_*
## signals) loads only after the SDK is ready, is single use and reloads after it closes, retries
## a failed load at 5 s, uses the TEST unit unless the release ids file carries an app_open id.
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
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := [
	"n01_headless_null_providers", "n02_play_purchase_grants_once", "n03_play_cancel_fail_pending",
	"n04_play_launch_and_restore", "n05_appstore_purchase_finish_restore", "n06_admob_consent_before_ads",
	"n07_admob_rewarded_grants_once", "n08_admob_interstitial_banner", "n09_admob_real_ids_release_only",
	"n10_store_error_detail_reaches_resolved", "n11_product_query_diagnostics", "n12_admob_load_retry_bounded",
	"n13_rewarded_unavailable_text", "n14_shop_failure_detail_text",
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
	var info_errors := 0                       ## next N product requests fail (SKRequest didFailWithError)
	var invalid := PackedStringArray()         ## ids StoreKit reports in invalid_ids
	var purchase_code := OK
	func set_auto_finish_transaction(b: bool) -> void:
		auto_finish = b
	func request_product_info(p: Dictionary) -> int:
		calls.append("info")
		if info_errors > 0:
			info_errors -= 1
			events.append({"type": "product_info", "result": "error", "error": "Cannot connect to iTunes Store"})
			return OK
		var ids := PackedStringArray(Array(p["product_ids"]).filter(func(id): return not invalid.has(id)))
		events.append({"type": "product_info", "result": "ok", "ids": ids, "invalid_ids": invalid,
			"localized_prices": PackedStringArray(Array(ids).map(func(_id): return "US$0.99"))})
		return OK
	func purchase(p: Dictionary) -> int:
		calls.append("purchase:" + String(p["product_id"]))
		return purchase_code
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
	signal app_open_ad_loaded(a, r)
	signal app_open_ad_failed_to_load(a, e)
	signal app_open_ad_failed_to_show_full_screen_content(a, e)
	signal app_open_ad_dismissed_full_screen_content(a)
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
	var android_real_app_open_id := ""
	var ios_real_app_open_id := ""
	var android_debug_app_open_id := "ca-app-pub-3940256099942544/9257395921"   ## plugin v7.0 demo unit
	var auto_show_on_resume := true
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
	func load_app_open_ad() -> void:
		calls.append("load_app_open")
	func show_app_open_ad() -> void:
		calls.append("show_app_open")
	func ads_calls() -> Array:
		return calls.filter(func(c): return c.begins_with("load_banner") or c.begins_with("load_inter") or c.begins_with("load_rew") or c.begins_with("show_banner") or c.begins_with("show_inter") or c.begins_with("show_rew"))

## godot-admob LoadAdError double (get_code / get_message).
class FakeAdError extends RefCounted:
	func get_code() -> int:
		return 3
	func get_message() -> String:
		return "No fill."

## ModalStack double for ShopScreen._feedback.
class FakeStack extends RefCounted:
	var pushed: Array = []
	func push(p) -> bool:
		pushed.append(p)
		return true

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
	_n10()
	_n11()
	_n12()
	_n13()
	_n14()
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
	_ok(n.calls.count("load_app_open") == 1 and n.calls.find("load_app_open") > n.calls.find("initialize") and not n.auto_show_on_resume, "SB-TF-07: App Open loaded once, only after the SDK init; never auto-shown on resume")
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

## `sched` collects the provider's [delay_s, callback] retry requests (fake timer).
func _ready_admob(e, sched: Array = []) -> FakeAdmob:
	var n := FakeAdmob.new()
	var p := AdmobAdProvider.new(n, false)
	p.schedule = func(d: float, cb: Callable): sched.append([d, cb])
	e.ads.set_provider(p)
	p.start()
	n.consent = "NOT_REQUIRED"
	n.consent_info_updated.emit()
	n.initialization_completed.emit(null)
	return n

func _n07() -> void:
	print("[n07 AdMob rewarded: earned reward + close grants once; close without it / failure grant nothing]")
	var e := EconomyServices.new()
	var sched: Array = []
	var n := _ready_admob(e, sched)
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
	_ok(not e.rewarded.is_available("booster:tornado") and n.calls[-1] == "load_rewarded" and sched.size() == 1, "load failure -> not offered, one backoff reload scheduled")
	_complete("n07_admob_rewarded_grants_once")

func _n08() -> void:
	print("[n08 AdMob interstitial / banner follow AdService]")
	var e := EconomyServices.new()
	var sched: Array = []
	var n := _ready_admob(e, sched)
	for _i in range(5):
		e.ads.on_play_finished(10)
	_ok(not e.ads.try_interstitial() and e.ads.interstitial_due() and not n.calls.has("show_interstitial"), "due but not loaded -> not shown, stays due")
	n.interstitial_ad_loaded.emit(null, null)
	_ok(e.ads.try_interstitial() and n.calls[-1] == "show_interstitial" and not e.ads.interstitial_due(), "loaded -> shown at the transition, cadence restarts")
	n.interstitial_ad_dismissed_full_screen_content.emit(null)
	_ok(n.calls[-1] == "load_interstitial", "closed -> next one loading")
	n.interstitial_ad_failed_to_load.emit(null, FakeAdError.new())
	var loads: int = n.calls.count("load_interstitial")
	for _i in range(5):
		e.ads.on_play_finished(10)
	_ok(not e.ads.try_interstitial() and n.calls.count("load_interstitial") == loads and sched.size() == 1 and sched[0][0] == 5.0, "failed load -> not shown; one 5 s backoff reload scheduled, no immediate reload")
	sched[0][1].call()
	_ok(n.calls.count("load_interstitial") == loads + 1, "backoff timer fires -> interstitial reloads")
	_ok(n.calls.count("load_banner") == 1 and not n.calls.has("show_banner"), "banner requested once, not shown before it loads")
	n.banner_ad_loaded.emit(null, null)
	_ok(n.calls[-1] == "show_banner", "banner loaded -> shown")
	_ok(e.reward.grant("store:tokNA", {"store_no_ads": 1}) and e.store.no_ads(), "No Ads bought")
	e.ads.update_banner()
	_ok(n.calls[-1] == "hide_banner", "No Ads -> banner hidden")
	for _i in range(10):
		e.ads.on_play_finished(10)
	n.interstitial_ad_loaded.emit(null, null)
	_ok(not e.ads.try_interstitial() and n.calls.count("show_interstitial") == 1, "No Ads -> no interstitial even when one is loaded")
	# SB-TF-07 App Open through the same provider.
	var a := FakeAdmob.new()
	var ap := AdmobAdProvider.new(a, false)
	var asched: Array = []
	ap.schedule = func(d: float, cb: Callable): asched.append([d, cb])
	_ok(not ap.show_app_open("app_open_launch") and not a.calls.has("load_app_open"), "App Open before the SDK: not shown, nothing loaded")
	ap.start()
	a.consent = "NOT_REQUIRED"
	a.consent_info_updated.emit()
	a.initialization_completed.emit(null)
	_ok(not ap.show_app_open("app_open_launch") and not a.calls.has("show_app_open"), "SDK ready, App Open still loading -> false")
	a.app_open_ad_loaded.emit(null, null)
	_ok(ap.show_app_open("app_open_launch") and a.calls[-1] == "show_app_open", "loaded -> show_app_open_ad, true")
	_ok(not ap.show_app_open("app_open_launch") and a.calls.count("show_app_open") == 1, "single use: a second show before a reload -> false")
	var l0: int = a.calls.count("load_app_open")
	a.app_open_ad_dismissed_full_screen_content.emit(null)
	_ok(a.calls.count("load_app_open") == l0 + 1, "closed -> the next App Open loading")
	a.app_open_ad_failed_to_load.emit(null, FakeAdError.new())
	_ok(asched.size() == 1 and asched[0][0] == 5.0 and not ap.show_app_open("app_open_launch"), "failed App Open load -> one 5 s backoff reload, not shown")
	asched[0][1].call()
	_ok(a.calls.count("load_app_open") == l0 + 2, "backoff timer fires -> App Open reloads")
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
	var t := FakeAdmob.new()
	AdmobAdProvider.new(t, true, "user://m57_native_absent_ids.gd")
	_ok(not t.is_real and t.ios_real_rewarded_id == "", "ads_test_mode build (no ids file written) -> is_real never set, Google TEST units")
	_ok(not n.is_real and n.android_real_app_open_id == "" and n.android_debug_app_open_id == "ca-app-pub-3940256099942544/9257395921", "SB-TF-07: test build -> App Open from the Google TEST unit")
	var ao := FakeAdmob.new()
	var aop := AdmobAdProvider.new(ao, false, path)
	aop.start()
	ao.consent = "NOT_REQUIRED"
	ao.consent_info_updated.emit()
	ao.initialization_completed.emit(null)
	_ok(ao.is_real and ao.android_real_app_open_id == "" and not ao.calls.has("load_app_open") and not aop.show_app_open("app_open_launch") and not ao.calls.has("load_app_open"),
		"real-id build without an app_open id -> App Open never loaded or shown")
	_ok(FileAccess.get_file_as_string("res://scripts/economy/admob_ad_provider.gd").contains('print("ADS_APP_OPEN_NO_ID")'), "that build logs ADS_APP_OPEN_NO_ID")
	var path2 := "user://m57_native_real_ids_ao_%d.gd" % Time.get_ticks_usec()
	_tmp.append(path2)
	var f2 := FileAccess.open(path2, FileAccess.WRITE)
	f2.store_string('const IDS := {"banner": "B", "interstitial": "I", "rewarded": "R", "app_open": "O"}')
	f2.close()
	var ar := FakeAdmob.new()
	AdmobAdProvider.new(ar, true, path2)
	_ok(ar.is_real and ar.ios_real_app_open_id == "O" and ar.android_real_app_open_id == "", "release file with app_open on iOS -> ios real App Open id")
	_complete("n09_admob_real_ids_release_only")

func _n10() -> void:
	print("[n10 SB-TF-01 store error text / code reaches StoreService.resolved; product purchasable again]")
	var e := EconomyServices.new()
	var b := FakeAppStore.new()
	var p := AppStoreProvider.new(b, Callable(e.store, "deliver"))
	e.store.set_provider(p)
	e.store.refresh_prices()
	p.poll()
	var got: Array = []
	e.store.resolved.connect(func(_id, r): got.append(r))
	var sb0: int = e.wallet.scrub_bucks()
	var n0: int = e.reward.applied_transaction_count()
	_ok(e.store.purchase("scrubbucks_100")["ok"] and not e.store.can_purchase("scrubbucks_100")["ok"], "purchase sheet open -> product pending")
	b.events.append({"type": "purchase", "result": "error", "product_id": "scrubbucks_100", "error": "Cannot connect to iTunes Store", "error_code": 0, "type_code": 2})
	p.poll()
	var r: Dictionary = got[-1] if not got.is_empty() else {}
	_ok(r.get("ok") == false and r.get("reason") == "failed" and String(r.get("error", "")) == "0: Cannot connect to iTunes Store", "error event -> resolved ok=false, reason=failed, error='<code>: <message>' %s" % str(r))
	_ok(e.wallet.scrub_bucks() == sb0 and e.reward.applied_transaction_count() == n0 and e.store.can_purchase("scrubbucks_100")["ok"], "nothing granted; _pending cleared -> purchasable again")
	b.events.append({"type": "purchase", "result": "error", "product_id": "scrubbucks_100", "error": "Payment sheet failed"})
	e.store.purchase("scrubbucks_100")
	p.poll()
	_ok(String(got[-1].get("error", "")) == "Payment sheet failed", "the pinned plugin sends no code -> error is the message alone")
	b.purchase_code = ERR_INVALID_PARAMETER
	var rr: Dictionary = e.store.purchase("scrubbucks_550")
	_ok(rr["reason"] == "provider_refused" and String(rr.get("error", "")) == "%d: purchase refused" % ERR_INVALID_PARAMETER and e.store.can_purchase("scrubbucks_550")["ok"], "StoreKit refuses (product not loaded) -> provider_refused with the Error code, purchasable again")
	var t := _play_store()
	var pe = t[0]
	var pb: FakePlay = t[1]
	pb.connected.emit()
	pe.store.refresh_prices()
	var pg: Array = []
	pe.store.resolved.connect(func(_id, x): pg.append(x))
	pe.store.purchase("scrubbucks_100")
	pb.on_purchase_updated.emit({"response_code": 6, "debug_message": "Server error"})
	_ok(pg[-1]["reason"] == "failed" and pg[-1].get("error") == "6: Server error", "Play ERROR -> error '<response_code>: <debug_message>'")
	pe.store.purchase("scrubbucks_100")
	pb.on_purchase_updated.emit({"response_code": PlayBillingStoreProvider.USER_CANCELED, "debug_message": "User canceled"})
	_ok(pg[-1]["reason"] == "cancelled" and not pg[-1].has("error"), "Play cancel unchanged (no error detail)")
	_complete("n10_store_error_detail_reaches_resolved")

func _n11() -> void:
	print("[n11 SB-TF-01 product query diagnostics: invalid_ids / error logged, no price; one retry]")
	var e := EconomyServices.new()
	var b := FakeAppStore.new()
	b.invalid = PackedStringArray(["scrubbucks_100"])
	var p := AppStoreProvider.new(b, Callable(e.store, "deliver"))
	e.store.set_provider(p)
	e.store.refresh_prices()
	p.poll()
	_ok(e.store.price_text("scrubbucks_100") == "" and e.store.price_text("scrubbucks_550") == "US$0.99", "invalid id -> no price for it, the others priced")
	_ok(p.last_error == "unknown to App Store Connect" and not e.store.can_purchase("scrubbucks_100")["ok"], "STORE_INVALID_IDS recorded (last_error); the unpriced product cannot be bought")
	var e2 := EconomyServices.new()
	var b2 := FakeAppStore.new()
	b2.info_errors = 1
	var p2 := AppStoreProvider.new(b2, Callable(e2.store, "deliver"))
	e2.store.set_provider(p2)
	e2.store.refresh_prices()
	p2.poll()
	_ok(p2.last_error == "Cannot connect to iTunes Store" and b2.calls.count("info") == 2, "product_info error -> STORE_ERROR recorded, retried once")
	p2.poll()
	_ok(e2.store.price_text("scrubbucks_100") == "US$0.99", "the retry prices the products")
	var e3 := EconomyServices.new()
	var b3 := FakeAppStore.new()
	b3.info_errors = 5
	var p3 := AppStoreProvider.new(b3, Callable(e3.store, "deliver"))
	e3.store.set_provider(p3)
	e3.store.refresh_prices()
	p3.poll()
	p3.poll()
	p3.poll()
	_ok(b3.calls.count("info") == 2 and e3.store.price_text("scrubbucks_100") == "", "repeated errors -> exactly one retry (no polling loop), still no price")
	var t := _play_store()
	t[1].connected.emit()
	t[1].query_product_details_response.emit({"response_code": 0, "product_details": [], "unfetched_products": [{"product_id": "no_ads"}]})
	_ok(t[0].store.get_provider().last_error == "unknown to Play Console", "Play unfetched_products -> STORE_INVALID_IDS recorded")
	_complete("n11_product_query_diagnostics")

func _n12() -> void:
	print("[n12 SB-TF-01 AdMob load retry: 5 / 15 / 45 s, max 3 in a row, reset on a load]")
	var e := EconomyServices.new()
	var sched: Array = []
	var n := _ready_admob(e, sched)
	var loads := func(): return n.calls.count("load_rewarded")
	for i in range(3):
		n.rewarded_ad_failed_to_load.emit(null, FakeAdError.new())
		_ok(not e.rewarded.is_available("heart") and sched.size() == i + 1, "failure %d -> not available, retry %d scheduled" % [i + 1, i + 1])
		var l0: int = loads.call()
		sched[-1][1].call()
		_ok(loads.call() == l0 + 1, "retry %d timer -> one reload" % (i + 1))
	_ok(sched.map(func(s): return s[0]) == [5.0, 15.0, 45.0], "increasing delays 5 / 15 / 45 s")
	n.rewarded_ad_failed_to_load.emit(null, FakeAdError.new())
	_ok(sched.size() == 3, "4th failure in a row -> no further automatic retry")
	var l1: int = loads.call()
	_ok(not e.rewarded.is_available("heart") and loads.call() == l1 + 1, "after the cap: the next availability check reloads lazily (as before)")
	n.rewarded_ad_loaded.emit(null, null)
	_ok(e.rewarded.get_provider().is_available("x"), "loaded -> is_available true")
	n.rewarded_ad_failed_to_load.emit(null, FakeAdError.new())
	_ok(sched.size() == 4 and sched[-1][0] == 5.0, "counter reset by the load -> next failure retries at 5 s again")
	_complete("n12_admob_load_retry_bounded")

func _n13() -> void:
	print("[n13 SB-TF-01 rewarded unavailable / failed -> player-facing text]")
	var e := EconomyServices.new()
	var n := _ready_admob(e)
	n.rewarded_ad_failed_to_load.emit(null, FakeAdError.new())
	var r: Dictionary = e.rewarded.start(RewardedGrantService.booster_product("tornado"))
	_ok(not r["ok"] and r["reason"] == "unavailable", "no video loaded -> start refused with reason unavailable")
	_ok(RewardedAdsScreen._reason_text(r["reason"]) == UiText.t("REWARDED_UNAVAILABLE_NOTE") and not UiText.t("REWARDED_UNAVAILABLE_NOTE").is_empty(), "Rewarded Ads screen shows REWARDED_UNAVAILABLE_NOTE")
	_ok(RewardedAdsScreen._reason_text("failed") == UiText.t("REWARDED_NO_GRANT", [UiText.t("REWARDED_REASON_FAILED")]), "failed show -> REWARDED_NO_GRANT + REWARDED_REASON_FAILED")
	var src := FileAccess.get_file_as_string("res://scripts/ui/popup/acquisition_flow.gd")
	_ok(src.contains('_status(p, UiText.t("REWARDED_UNAVAILABLE_NOTE"))') and src.count("REWARDED_UNAVAILABLE_NOTE") >= 3, "Heart / Need a Hand / booster popups carry the unavailable note (booster CTA no longer silently hidden)")
	_complete("n13_rewarded_unavailable_text")

func _n14() -> void:
	print("[n14 SB-TF-01 Shop failure text: store detail appended when present, plain otherwise (EN + TR)]")
	var s = ShopScreen.new()
	var st := FakeStack.new()
	s._stack = st
	s._economy = EconomyServices.new()
	var body := func(i: int) -> String: return (st.pushed[i].get_content().get_node("Body") as Label).text
	s._feedback("store:scrubbucks_100", {"ok": false, "reason": "failed", "error": "0: Cannot connect to iTunes Store"})
	_ok(body.call(0) == "The purchase didn't go through. (0: Cannot connect to iTunes Store)", "EN detail: %s" % body.call(0))
	s._feedback("store:scrubbucks_100", {"ok": false, "reason": "failed"})
	_ok(body.call(1) == UiText.t("SHOP_STORE_FAILED") and not body.call(1).contains("("), "empty detail -> plain SHOP_STORE_FAILED")
	s._feedback("store:scrubbucks_100", {"ok": false, "reason": "pending", "error": "x"})
	_ok(body.call(2) == UiText.t("SHOP_STORE_PENDING"), "pending unchanged")
	UiText.locale = "tr"
	s._feedback("store:scrubbucks_100", {"ok": false, "reason": "provider_refused", "error": "2: purchase refused"})
	s._feedback("store:scrubbucks_100", {"ok": false, "reason": "failed", "error": ""})
	var tr3: String = body.call(3)
	var tr4: String = body.call(4)
	UiText.locale = "en"
	_ok(tr3 == "Satın alma tamamlanmadı. (2: purchase refused)" and tr4 == "Satın alma tamamlanmadı.", "TR detail + TR plain")
	for fb in st.pushed:
		fb.free()
	_complete("n14_shop_failure_detail_text")

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
