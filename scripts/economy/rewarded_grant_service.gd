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
##
## M43-C015R (SB-M43-R15-001): Rewarded Ads daily slots 2..5 ("daily_slot:<n>") reuse this
## exact flow. The caller (RewardedDailyService) supplies the configured bundle and the local
## day; the grant is committed under the DETERMINISTIC economy id "daily_rewarded:<day>:<n>"
## (never the provider token), so a second request / duplicate / late callback for an already
## granted slot grants nothing. Placement "rewarded_daily_slot_<n>". Heart / booster products
## are unchanged.

const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

signal resolved(token: String, product: String, result: Dictionary)

const HEART := "heart"
const DAILY_PRODUCT_PREFIX := "daily_slot:"
const DAILY_TX_PREFIX := "daily_rewarded:"
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
var _grants: Dictionary = {}    ## token -> {tx, rewards} for daily-slot requests (session-local)

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

static func daily_product(slot: int) -> String:
	return DAILY_PRODUCT_PREFIX + str(slot)

static func daily_tx(day: int, slot: int) -> String:
	return "%s%d:%d" % [DAILY_TX_PREFIX, day, slot]

## Rewarded daily slot `slot` (2..5) may be requested right now (provider + state)?
func can_start_daily(day: int, slot: int) -> Dictionary:
	if slot < 2 or slot > 5:
		return {"ok": false, "reason": "unknown_product"}
	if _reward.already_applied(daily_tx(day, slot)):
		return {"ok": false, "reason": "already_claimed"}
	if _provider == null or not _provider.is_available(placement(daily_product(slot))):
		return {"ok": false, "reason": "unavailable"}
	if _pending.values().has(daily_product(slot)):
		return {"ok": false, "reason": "pending"}
	return {"ok": true}

## Begin one rewarded request for daily slot `slot` on local day `day`, granting `rewards`
## (the configured bundle) under daily_tx(day, slot) only on a verified completion.
func start_daily_slot(day: int, slot: int, rewards: Dictionary, token: String = "") -> Dictionary:
	var c := can_start_daily(day, slot)
	if not c["ok"]:
		return c
	if rewards.is_empty():
		return {"ok": false, "reason": "unknown_product"}
	var product := daily_product(slot)
	if token.is_empty():
		_seq += 1
		token = "rw_daily_%d_%d_%d" % [slot, int(Time.get_unix_time_from_system()), _seq]
	if _pending.has(token) or _closed.has(token) or _reward.already_applied(TX_PREFIX + token):
		return {"ok": false, "reason": "duplicate_token"}
	_pending[token] = product
	_grants[token] = {"tx": daily_tx(day, slot), "rewards": rewards.duplicate(true)}
	if not _provider.request(placement(product), token, Callable(self, "resolve")):
		_pending.erase(token)
		_grants.erase(token)
		_closed[token] = {"ok": false, "reason": "provider_refused", "product": product, "token": token}
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true, "token": token, "product": product, "tx": daily_tx(day, slot)}

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
	var daily_grant: Dictionary = _grants.get(token, {})
	_grants.erase(token)
	var tx: String = String(daily_grant["tx"]) if not daily_grant.is_empty() else TX_PREFIX + token
	var rewards: Dictionary = daily_grant["rewards"] if not daily_grant.is_empty() else rewards_for(product)
	var outcome := String(result.get("outcome", ""))
	var verified = result.get("verified", false)
	var out: Dictionary
	if outcome != COMPLETED:
		out = {"ok": false, "reason": outcome if not outcome.is_empty() else "failed"}
	elif not (verified is bool and verified):
		out = {"ok": false, "reason": "unverified"}
	elif product == HEART and _hearts.hearts() >= _hearts.max_hearts():
		out = {"ok": false, "reason": "already_full"}
	elif not _reward.grant(tx, rewards):
		out = {"ok": false, "reason": "duplicate"}
	else:
		out = {"ok": true}
		if _save_cb.is_valid():
			out["save"] = _save_cb.call()
	out["product"] = product
	out["token"] = token
	if not daily_grant.is_empty():
		out["tx"] = tx
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
