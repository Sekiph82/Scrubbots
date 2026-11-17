extends "res://scripts/economy/store_provider.gd"
## PlayBillingStoreProvider — preload (res://scripts/economy/play_billing_store_provider.gd).
##
## SB-M57-014..016 Android: the StoreProvider contract over the official GodotGooglePlayBilling
## plugin (godot-sdk-integrations/godot-google-play-billing 3.3.0, MIT; Android singleton
## "GodotGooglePlayBilling", added to Gradle exports by the CI workflow input billing_ads).
## main.gd installs it only when that singleton exists; editor / desktop / headless keep the
## null StoreProvider. Tests drive it with a fake backend that has the same methods + signals.
##
##   connect at launch, then queryPurchases: every PURCHASED purchase not yet acknowledged
##   (a consumable not consumed, or a No Ads not acknowledged) is delivered again, so a grant
##   interrupted by a crash completes; StoreService grants each token once (tx store:<token>).
##   purchase_state PURCHASED -> "purchased" (the only granting outcome); PENDING -> "pending"
##   (nothing granted; Play sends PURCHASED later through on_purchase_updated).
##   USER_CANCELED -> "cancelled"; any other error -> "failed".
##   acknowledge(token, consume): SB pack -> consumePurchase; No Ads -> acknowledgePurchase.

const NATIVE := "GodotGooglePlayBilling"
const INAPP := "inapp"
## BillingClient.BillingResponseCode / PurchaseState of the plugin.
const RESPONSE_OK := 0
const USER_CANCELED := 1
const STATE_PURCHASED := 1
const STATE_PENDING := 2

var _b
var _deliver: Callable
var _connected := false
var _prices_cb := Callable()
var _restore_cb := Callable()
var _buying := ""            ## product id of the open purchase sheet
var _acknowledged := {}      ## purchase token -> true when Play already reports it acknowledged

## backend: the plugin singleton; deliver: StoreService.deliver (unfinished purchases at launch).
func _init(backend, deliver: Callable) -> void:
	_b = backend
	_deliver = deliver
	_b.connect("connected", _on_connected)
	_b.connect("disconnected", _on_disconnected)
	_b.connect("query_product_details_response", _on_product_details)
	_b.connect("query_purchases_response", _on_purchases)
	_b.connect("on_purchase_updated", _on_purchase_updated)
	_b.initPlugin()
	_b.startConnection()

func is_available() -> bool:
	return _connected

func query_products(ids: Array, deliver: Callable) -> bool:
	if not _connected:
		return false
	_prices_cb = deliver
	_b.queryProductDetails(PackedStringArray(ids), INAPP)
	return true

func purchase(product_id: String, deliver: Callable) -> bool:
	if not _connected:
		return false
	var r: Dictionary = _b.purchase(product_id, "", "", false)
	if int(r.get("response_code", -1)) != RESPONSE_OK:
		return false
	_buying = product_id
	_deliver = deliver
	return true

func restore(deliver: Callable) -> bool:
	if not _connected:
		return false
	_restore_cb = deliver
	_b.queryPurchases(INAPP, false)
	return true

func acknowledge(token: String, consume: bool) -> void:
	if consume:
		_b.consumePurchase(token)
	elif not _acknowledged.has(token):
		_acknowledged[token] = true
		_b.acknowledgePurchase(token)

func _on_connected() -> void:
	_connected = true
	_b.queryPurchases(INAPP, false)

func _on_disconnected() -> void:
	_connected = false
	_b.startConnection()

func _on_product_details(r: Dictionary) -> void:
	if int(r.get("response_code", -1)) != RESPONSE_OK or not _prices_cb.is_valid():
		return
	var prices := {}
	for d in r.get("product_details", []):
		var offers = d.get("one_time_purchase_offer_details_list")
		if offers is Array and not offers.is_empty():
			prices[String(d.get("product_id", ""))] = String(offers[0].get("formatted_price", ""))
	_prices_cb.call(prices)

## Launch reconciliation and Restore share queryPurchases.
func _on_purchases(r: Dictionary) -> void:
	if int(r.get("response_code", -1)) != RESPONSE_OK:
		if _restore_cb.is_valid():
			var cb := _restore_cb
			_restore_cb = Callable()
			cb.call([])
		return
	var owned: Array = []
	for p in r.get("purchases", []):
		if int(p.get("purchase_state", 0)) != STATE_PURCHASED:
			continue
		owned.append({"product_id": _product_of(p), "token": String(p.get("purchase_token", ""))})
		if bool(p.get("is_acknowledged", false)):
			_acknowledged[String(p.get("purchase_token", ""))] = true
		else:
			_deliver_purchase(p)
	if _restore_cb.is_valid():
		var cb := _restore_cb
		_restore_cb = Callable()
		cb.call(owned)

func _on_purchase_updated(r: Dictionary) -> void:
	var code := int(r.get("response_code", -1))
	var id := _buying
	_buying = ""
	if code == RESPONSE_OK:
		for p in r.get("purchases", []):
			_deliver_purchase(p)
	elif not id.is_empty():
		_deliver.call({"product_id": id, "token": "", "outcome": "cancelled" if code == USER_CANCELED else "failed"})

func _deliver_purchase(p: Dictionary) -> void:
	var state := int(p.get("purchase_state", 0))
	if state != STATE_PURCHASED and state != STATE_PENDING:
		return
	_deliver.call({"product_id": _product_of(p), "token": String(p.get("purchase_token", "")),
		"outcome": "purchased" if state == STATE_PURCHASED else "pending"})

static func _product_of(p: Dictionary) -> String:
	var ids = p.get("product_ids", [])
	return String(ids[0]) if ids.size() > 0 else ""
