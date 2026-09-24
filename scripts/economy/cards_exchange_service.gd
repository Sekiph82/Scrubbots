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
	if _reward.already_applied(tx_id):
		return {"ok": false, "reason": "duplicate"}
	# Atomic (F-M39-007): remove the copies FIRST (the fallible, gating step). Only
	# on a confirmed removal do we credit SB. If the credit then fails, roll the
	# removal back so neither side is left half-applied — never SB without cards.
	if not _inventory.remove_copies(card_id, count, _protected):
		return {"ok": false, "reason": "removal_failed"}
	if not _reward.grant(tx_id, {EconomyWallet.SCRUB_BUCKS: value}):
		_inventory.add_copies(card_id, count)   # rollback the removal
		return {"ok": false, "reason": "grant_failed"}
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
	# Atomic: remove every planned extra FIRST (each gated); on any removal
	# failure, roll back the removals already done and grant nothing. Only when
	# all removals succeed do we credit; if the credit fails, roll back all.
	var removed: Dictionary = {}
	for cid in plan.keys():
		if not _inventory.remove_copies(cid, plan[cid], _protected):
			for done in removed.keys():
				_inventory.add_copies(done, removed[done])
			return {"ok": false, "reason": "removal_failed"}
		removed[cid] = plan[cid]
	if not _reward.grant(tx_id, {EconomyWallet.SCRUB_BUCKS: total}):
		for cid in removed.keys():
			_inventory.add_copies(cid, removed[cid])
		return {"ok": false, "reason": "grant_failed"}
	return {"ok": true, "sb": total, "exchanged": plan}

func next_tx_id(prefix: String = "exch") -> String:
	_tx_counter += 1
	return "%s:%d" % [prefix, _tx_counter]
