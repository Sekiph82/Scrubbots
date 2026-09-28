extends RefCounted
## RewardedGrantService — preload (res://scripts/economy/rewarded_grant_service.gd).
##
## M43-C003 (SB-M43-034/035/040..044) — the ONE authority that turns a rewarded-video
## result into a grant. It adds no second ledger: every grant goes through the canonical
## RewardGrantService under tx id "rewarded:<token>", whose applied-tx set is persisted by
## the M40 save, so a duplicate / late / relaunched callback can never re-grant.
##
## Products (owner-approved V1 only; no rewarded 2x):
##   "heart"              +1 Heart (fails closed if Hearts are full at commit time)
##   "booster:<id>"       +1 charge of one of the four canonical boosters
##
## Flow: start(product) -> provider.request(...) -> resolve(token, result) exactly once.
## Only outcome "completed" with verified == true commits. Cancel / skip / fail / timeout /
## unverified / unknown token / duplicate grant nothing. A committed grant requests the
## durable save boundary before `resolved` is emitted, so UI shows success only after
## commit. Pending tokens are session-local; an unresolved token after relaunch is unknown.

const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

signal resolved(token: String, product: String, result: Dictionary)

const HEART := "heart"
const COMPLETED := "completed"
const TX_PREFIX := "rewarded:"
## Reward resources registered on RewardGrantService by EconomyServices.
const RES_HEART := "rewarded_heart"
const RES_BOOSTER_PREFIX := "booster_charge_"

var _reward
var _hearts
var _provider
var _save_cb: Callable = Callable()
var _pending: Dictionary = {}    ## token -> product (unresolved this session)
var _closed: Dictionary = {}     ## token -> final result (resolved/abandoned this session)
var _seq := 0

func _init(reward, hearts, provider = null) -> void:
	_reward = reward
	_hearts = hearts
	_provider = provider if provider != null else RewardedAdProvider.new()

func set_provider(p) -> void:
	_provider = p if p != null else RewardedAdProvider.new()

func get_provider():
	return _provider

func bind_save(cb: Callable) -> void:
	_save_cb = cb

static func products() -> Array:
	var out: Array = [HEART]
	for b in BoosterInventory.BOOSTERS:
		out.append("booster:" + b)
	return out

static func booster_product(id: String) -> String:
	return "booster:" + id

## Logical placement key handed to the provider (M57 maps it to a real placement id).
static func placement(product: String) -> String:
	return "rewarded_" + product.replace(":", "_")

static func rewards_for(product: String) -> Dictionary:
	if product == HEART:
		return {RES_HEART: 1}
	if product.begins_with("booster:") and BoosterInventory.BOOSTERS.has(product.substr(8)):
		return {RES_BOOSTER_PREFIX + product.substr(8): 1}
	return {}

func is_known(product: String) -> bool:
	return not rewards_for(product).is_empty()

## May this product be offered right now (provider policy + product state)?
func can_start(product: String) -> Dictionary:
	if not is_known(product):
		return {"ok": false, "reason": "unknown_product"}
	if _provider == null or not _provider.is_available(placement(product)):
		return {"ok": false, "reason": "unavailable"}
	if _pending.values().has(product):
		return {"ok": false, "reason": "pending"}
	if product == HEART and _hearts.hearts() >= _hearts.max_hearts():
		return {"ok": false, "reason": "already_full"}
	return {"ok": true}

func is_available(product: String) -> bool:
	return bool(can_start(product).get("ok", false))

## Begin one rewarded request. `token` may be a provider-assigned transaction id; empty =
## a fresh session-unique token. Returns {ok, token, product} or {ok:false, reason}.
## A provider may deliver synchronously; result_for(token) then already holds the result.
func start(product: String, token: String = "") -> Dictionary:
	var c := can_start(product)
	if not c["ok"]:
		return c
	if token.is_empty():
		_seq += 1
		token = "rw_%s_%d_%d" % [product.replace(":", "_"), int(Time.get_unix_time_from_system()), _seq]
	if _pending.has(token) or _closed.has(token) or _reward.already_applied(TX_PREFIX + token):
		return {"ok": false, "reason": "duplicate_token"}
	_pending[token] = product
	if not _provider.request(placement(product), token, Callable(self, "resolve")):
		_pending.erase(token)
		_closed[token] = {"ok": false, "reason": "provider_refused", "product": product, "token": token}
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true, "token": token, "product": product}

## Provider callback. Exactly-once per token; see header for the commit rule.
func resolve(token: String, result: Dictionary) -> Dictionary:
	if not _pending.has(token):
		var dup: bool = _closed.has(token) or _reward.already_applied(TX_PREFIX + token)
		return {"ok": false, "reason": "duplicate" if dup else "unknown_token", "token": token}
	var product: String = _pending[token]
	_pending.erase(token)
	var outcome := String(result.get("outcome", ""))
	var verified = result.get("verified", false)
	var out: Dictionary
	if outcome != COMPLETED:
		out = {"ok": false, "reason": outcome if not outcome.is_empty() else "failed"}
	elif not (verified is bool and verified):
		out = {"ok": false, "reason": "unverified"}
	elif product == HEART and _hearts.hearts() >= _hearts.max_hearts():
		out = {"ok": false, "reason": "already_full"}
	elif not _reward.grant(TX_PREFIX + token, rewards_for(product)):
		out = {"ok": false, "reason": "duplicate"}
	else:
		out = {"ok": true}
		if _save_cb.is_valid():
			out["save"] = _save_cb.call()
	out["product"] = product
	out["token"] = token
	_closed[token] = out
	resolved.emit(token, product, out.duplicate(true))
	return out

## UI safety timeout / dismissal: close an unresolved request as a non-grant. A later
## provider callback for it is then a duplicate and grants nothing.
func abandon(token: String, reason: String = "timeout") -> Dictionary:
	if not _pending.has(token):
		return {"ok": false, "reason": "not_pending"}
	return resolve(token, {"outcome": reason})

func is_pending(token: String) -> bool:
	return _pending.has(token)

func pending_count() -> int:
	return _pending.size()

func result_for(token: String) -> Dictionary:
	return (_closed.get(token, {}) as Dictionary).duplicate(true)
