extends "res://scripts/economy/store_provider.gd"
## AppStoreProvider — preload (res://scripts/economy/app_store_provider.gd).
##
## SB-M57-014..016 iOS: the StoreProvider contract over StoreKit through the official
## godot-ios-plugins "inappstore" plugin (godot-sdk-integrations/godot-ios-plugins, MIT; iOS
## singleton "InAppStore", built from pinned source for Godot 4.7.2 by the CI workflow input
## billing_ads). main.gd installs it only when that singleton exists and calls poll() on a timer
## (the plugin queues events). Tests drive it with a fake backend that has the same methods.
##
##   auto-finish is OFF: a purchased transaction stays in the StoreKit queue until
##   acknowledge() finishes it after StoreService saved the grant, so StoreKit re-delivers an
##   interrupted purchase at the next launch; the transaction id is the purchase token.
##   purchase "ok" -> "purchased"; "error" -> "failed"; "progress" deferred (Ask to Buy) ->
##   "pending". restore() collects the "restore" events until "completed".

const NATIVE := "InAppStore"
## SKPaymentTransactionStateDeferred (the plugin's type_code).
const STATE_DEFERRED := 4

var _b
var _deliver: Callable
var _prices_cb := Callable()
var _restore_cb := Callable()
var _restored: Array = []
var _tx := {}   ## transaction id -> product id, until finished

## backend: the plugin singleton; deliver: StoreService.deliver (unfinished purchases at launch).
func _init(backend, deliver: Callable) -> void:
	_b = backend
	_deliver = deliver
	_b.set_auto_finish_transaction(false)

func is_available() -> bool:
	return true

func query_products(ids: Array, deliver: Callable) -> bool:
	_prices_cb = deliver
	return _b.request_product_info({"product_ids": PackedStringArray(ids)}) == OK

func purchase(product_id: String, deliver: Callable) -> bool:
	_deliver = deliver
	return _b.purchase({"product_id": product_id}) == OK

func restore(deliver: Callable) -> bool:
	_restore_cb = deliver
	_restored = []
	return _b.restore_purchases() == OK

func acknowledge(token: String, _consume: bool) -> void:
	if _tx.has(token):
		_b.finish_transaction(_tx[token])
		_tx.erase(token)

## Drain the plugin's event queue (main.gd timer).
func poll() -> void:
	while _b.get_pending_event_count() > 0:
		_on_event(_b.pop_pending_event())

func _on_event(e: Dictionary) -> void:
	var type := String(e.get("type", ""))
	var result := String(e.get("result", ""))
	var id := String(e.get("product_id", ""))
	match type:
		"product_info":
			if result == "ok" and _prices_cb.is_valid():
				var prices := {}
				var ids: PackedStringArray = e.get("ids", PackedStringArray())
				var texts: PackedStringArray = e.get("localized_prices", PackedStringArray())
				for i in range(mini(ids.size(), texts.size())):
					prices[ids[i]] = texts[i]
				_prices_cb.call(prices)
		"purchase":
			if result == "ok":
				var token := String(e.get("transaction_id", ""))
				_tx[token] = id
				_deliver.call({"product_id": id, "token": token, "outcome": "purchased"})
			elif result == "error":
				_deliver.call({"product_id": id, "token": "", "outcome": "failed"})
			elif result == "progress" and int(e.get("type_code", -1)) == STATE_DEFERRED:
				_deliver.call({"product_id": id, "token": "", "outcome": "pending"})
		"restore":
			if result == "ok":
				_restored.append({"product_id": id, "token": String(e.get("transaction_id", ""))})
			elif _restore_cb.is_valid():
				var cb := _restore_cb
				_restore_cb = Callable()
				cb.call(_restored)
