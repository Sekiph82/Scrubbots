extends RefCounted
## StoreService — preload (res://scripts/economy/store_service.gd).
##
## SB-M57-012/013 + SB-M43-084 — the ONE authority that turns a real-money store result into
## a grant. Products come from data/config/store_products_v1.json (bad config = no products,
## fail closed). The provider (StoreProvider; shipping default = the unavailable base class)
## only talks to the store; every grant goes through the canonical RewardGrantService under
## tx id "store:<purchase token>", whose applied-tx set is persisted by the M40 save, so a
## duplicate callback, a relaunch re-delivery or an imported save can never grant twice.
##
##   SB pack (consumable)   +N Scrub Bucks, then acknowledge(token, consume = true)
##   No Ads (non-consumable) persistent entitlement: ads_allowed("banner"/"interstitial") is
##                           false, ads_allowed("rewarded") stays true (owner 2026-10-22)
##
## Only outcome "purchased" with a token commits. Every purchased delivery (new grant or
## duplicate re-delivery) is saved before the store is acknowledged; a failed save leaves the
## purchase unacknowledged so the store re-delivers it.
## restore() re-applies the No Ads entitlement only (consumables are never restored).
## Prices are only the store's localized strings (price_text); this service never formats one.

const StoreProvider = preload("res://scripts/economy/store_provider.gd")

signal prices_changed
signal resolved(product_id: String, result: Dictionary)
signal restored(result: Dictionary)

const CONFIG_PATH := "res://data/config/store_products_v1.json"
const TX_PREFIX := "store:"
const NO_ADS := "no_ads"
const PURCHASED := "purchased"
## RewardGrantService resource registered by EconomyServices.
const RES_NO_ADS := "store_no_ads"

var _reward
var _provider
var _save_cb: Callable = Callable()
var _products: Dictionary = {}   ## id -> config entry (ordered as the config)
var _prices: Dictionary = {}     ## id -> localized price string from the provider
var _pending: Dictionary = {}    ## product id -> true while its purchase sheet is open
var _no_ads := false

func _init(reward, provider = null, config_path: String = CONFIG_PATH) -> void:
	_reward = reward
	_provider = provider if provider != null else StoreProvider.new()
	_load(config_path)

func _load(path: String) -> void:
	var cfg = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(cfg) != TYPE_DICTIONARY or typeof(cfg.get("products")) != TYPE_ARRAY:
		return
	var out := {}
	for p in cfg["products"]:
		if typeof(p) != TYPE_DICTIONARY or typeof(p.get("id")) != TYPE_STRING or String(p["id"]).is_empty() or out.has(p["id"]):
			return
		var ok: bool = (p.get("kind") == "consumable" and typeof(p.get("scrub_bucks")) == TYPE_FLOAT and int(p["scrub_bucks"]) > 0) \
			or (p.get("kind") == "non_consumable" and p.get("entitlement") == NO_ADS)
		if not ok:
			return
		out[String(p["id"])] = p
	_products = out

func set_provider(p) -> void:
	_provider = p if p != null else StoreProvider.new()
	_prices.clear()
	_pending.clear()
	prices_changed.emit()

func get_provider():
	return _provider

func bind_save(cb: Callable) -> void:
	_save_cb = cb

# ------------------------------------------------------------------- catalog ----

func product_ids() -> Array:
	return _products.keys()

func sb_pack_ids() -> Array:
	return _products.keys().filter(func(id): return _products[id]["kind"] == "consumable")

func scrub_bucks_of(id: String) -> int:
	return int(_products[id].get("scrub_bucks", 0)) if _products.has(id) else 0

func is_available() -> bool:
	return _provider != null and _provider.is_available()

## Ask the store for localized prices; prices_changed fires when they arrive.
func refresh_prices() -> void:
	if is_available():
		_provider.query_products(product_ids(), Callable(self, "_on_prices"))

func _on_prices(prices: Dictionary) -> void:
	for id in prices:
		if _products.has(id) and typeof(prices[id]) == TYPE_STRING and not String(prices[id]).is_empty():
			_prices[id] = String(prices[id])
	prices_changed.emit()

## The store's localized price string, "" when the store has not priced it (= unavailable).
func price_text(id: String) -> String:
	return String(_prices.get(id, "")) if is_available() else ""

# ------------------------------------------------------------------ purchase ----

## {ok} when `id` may be bought right now, else {ok:false, reason}.
func can_purchase(id: String) -> Dictionary:
	if not _products.has(id):
		return {"ok": false, "reason": "unknown_product"}
	if price_text(id).is_empty():
		return {"ok": false, "reason": "unavailable"}
	if id == NO_ADS and _no_ads:
		return {"ok": false, "reason": "owned"}
	if _pending.has(id):
		return {"ok": false, "reason": "pending"}
	return {"ok": true}

## Open the store purchase sheet. The result arrives through deliver() / `resolved`.
func purchase(id: String) -> Dictionary:
	var c := can_purchase(id)
	if not c["ok"]:
		return c
	_pending[id] = true
	if not _provider.purchase(id, Callable(self, "deliver")):
		_pending.erase(id)
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true, "product_id": id}

## Provider callback (also used for unfinished purchases the store re-delivers at launch).
func deliver(r: Dictionary) -> Dictionary:
	var id := String(r.get("product_id", ""))
	var token := String(r.get("token", ""))
	var outcome := String(r.get("outcome", ""))
	_pending.erase(id)
	var out: Dictionary
	if not _products.has(id):
		out = {"ok": false, "reason": "unknown_product"}
	elif outcome != PURCHASED:
		out = {"ok": false, "reason": outcome if not outcome.is_empty() else "failed"}
	elif token.is_empty():
		out = {"ok": false, "reason": "no_token"}
	else:
		var rewards := {RES_NO_ADS: 1} if id == NO_ADS else {"scrub_bucks": scrub_bucks_of(id)}
		out = {"ok": true} if _reward.grant(TX_PREFIX + token, rewards) else {"ok": false, "reason": "duplicate"}
		# A duplicate may be the re-delivery after a failed save: save again before acknowledging.
		var saved := true
		if _save_cb.is_valid():
			out["save"] = _save_cb.call()
			saved = bool(out["save"].get("ok", false))
		if saved:
			_provider.acknowledge(token, id != NO_ADS)
	out["product_id"] = id
	out["token"] = token
	resolved.emit(id, out.duplicate(true))
	return out

## Restore purchases: re-applies the No Ads entitlement only. Result through `restored`.
func restore() -> Dictionary:
	if not is_available():
		return {"ok": false, "reason": "unavailable"}
	if not _provider.restore(Callable(self, "_on_restore")):
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true}

func _on_restore(owned: Array) -> Dictionary:
	var n := 0
	for p in owned:
		if typeof(p) == TYPE_DICTIONARY and String(p.get("product_id", "")) == NO_ADS and not String(p.get("token", "")).is_empty():
			_reward.grant(TX_PREFIX + String(p["token"]), {RES_NO_ADS: 1})
			_no_ads = true
			n += 1
	var out := {"ok": true, "restored": n}
	if n > 0 and _save_cb.is_valid():
		out["save"] = _save_cb.call()
	restored.emit(out.duplicate(true))
	return out

# --------------------------------------------------------------- entitlement ----

## RES_NO_ADS grant handler (EconomyServices registers it).
func grant_no_ads() -> void:
	_no_ads = true

func no_ads() -> bool:
	return _no_ads

## THE ad-decision seam: may an ad of `kind` ("banner" | "interstitial" | "rewarded") show?
## No Ads removes the bottom banner and the every-5-plays interstitials; rewarded videos are
## player-requested and stay. (No ad provider is built yet; Home's banner slot reads this.)
func ads_allowed(kind: String) -> bool:
	return kind == "rewarded" or not _no_ads

func snapshot() -> Dictionary:
	return {"no_ads": _no_ads}

## Absent (null) = a save from before the store existed (no entitlement); present = strict.
func import_snapshot(s) -> bool:
	if s == null:
		_no_ads = false
		return true
	if typeof(s) != TYPE_DICTIONARY or typeof(s.get("no_ads")) != TYPE_BOOL:
		return false
	_no_ads = s["no_ads"]
	return true
