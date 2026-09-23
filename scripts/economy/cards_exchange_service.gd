extends RefCounted
## CardsExchangeService — preload
## (res://scripts/economy/cards_exchange_service.gd).
##
## Exchanges only card copies ABOVE the protected first copy (SB-M39-048/050).
## Values by rarity (SB-M39-049): Common 25 / Rare 75 / Epic 200 / Legendary 500.
## Per-card and EXCHANGE-ALL-EXTRAS are atomic: owned count never drops below the
## protected minimum (1). SB is credited through RewardGrantService with a stable
## transaction id per exchange so a duplicate/reentrant callback cannot double-pay.
##
## Cards Exchange NEVER feeds the Gift Meter (owner §4 / SB-M39-014).

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")

var _inventory: CollectionInventory
var _reward
var _config
var _protected: int
var _tx_counter := 0

func _init(inventory: CollectionInventory, reward, config) -> void:
	_inventory = inventory
	_reward = reward
	_config = config
	_protected = config.cards_exchange_protected_copies()

func exchangeable(card_id: String) -> int:
	return max(_inventory.owned(card_id) - _protected, 0)

func card_value(card_id: String) -> int:
	return _config.cards_exchange_value(_inventory.card_rarity(card_id))

## Exchange `count` extra copies of one card for SB. Atomic: refuses if it would
## drop below the protected copy. `tx_id` makes it idempotent.
func exchange_card(card_id: String, count: int, tx_id: String) -> Dictionary:
	if count <= 0:
		return {"ok": false, "reason": "invalid_count"}
	if exchangeable(card_id) < count:
		return {"ok": false, "reason": "not_enough_extras"}
	var value := card_value(card_id) * count
	# Remove copies first (state), then credit; if the grant is a duplicate tx we
	# must not remove again — so guard on the reward idempotency.
	if _reward.already_applied(tx_id):
		return {"ok": false, "reason": "duplicate"}
	# Atomic: credit via reward service, then decrement owned.
	if not _reward.grant(tx_id, {EconomyWallet.SCRUB_BUCKS: value}):
		return {"ok": false, "reason": "grant_failed"}
	_inventory.remove_copies(card_id, count, _protected)
	return {"ok": true, "sb": value, "card_id": card_id, "count": count}

## Exchange ALL extras across the whole collection in one atomic transaction.
func exchange_all_extras(tx_id: String) -> Dictionary:
	if _reward.already_applied(tx_id):
		return {"ok": false, "reason": "duplicate"}
	var total := 0
	var plan: Dictionary = {}   ## card_id -> count
	for cid in _inventory.all_card_ids():
		var extra := exchangeable(cid)
		if extra > 0:
			plan[cid] = extra
			total += card_value(cid) * extra
	if total <= 0:
		return {"ok": false, "reason": "nothing_to_exchange"}
	if not _reward.grant(tx_id, {EconomyWallet.SCRUB_BUCKS: total}):
		return {"ok": false, "reason": "grant_failed"}
	for cid in plan.keys():
		_inventory.remove_copies(cid, plan[cid], _protected)
	return {"ok": true, "sb": total, "exchanged": plan}

func next_tx_id(prefix: String = "exch") -> String:
	_tx_counter += 1
	return "%s:%d" % [prefix, _tx_counter]
