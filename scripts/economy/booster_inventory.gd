extends RefCounted
## BoosterInventory — preload
## (res://scripts/economy/booster_inventory.gd).
##
## Exactly FOUR canonical boosters (owner §): +1 Slot, Random, Selector,
## Tornado. Holds charge counters and implements the charge-first-then-SB
## activation rule: if a charge is available it is consumed; otherwise the SB
## price is debited from the wallet. There is no fifth booster — unknown ids are
## rejected. Activation is atomic: a failed SB debit consumes nothing.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const PLUS_ONE_SLOT := "plus_one_slot"
const RANDOM := "random"
const SELECTOR := "selector"
const TORNADO := "tornado"
const BOOSTERS := [PLUS_ONE_SLOT, RANDOM, SELECTOR, TORNADO]

var _wallet: EconomyWallet
var _config
var _charges: Dictionary = {}
## Player-selected booster charges granted (e.g. Gift Meter 500/1000, Daily D5)
## that the player later redeems onto a chosen booster. Modeled as a pending
## pool so we do not silently pick a booster for the player.
var _pending_selected: int = 0

func _init(wallet: EconomyWallet, config) -> void:
	_wallet = wallet
	_config = config
	for b in BOOSTERS:
		_charges[b] = 0

func is_booster(id: String) -> bool:
	return BOOSTERS.has(id)

func charges(id: String) -> int:
	return int(_charges.get(id, 0))

func add_charges(id: String, n: int) -> bool:
	if not is_booster(id) or n < 0:
		return false
	_charges[id] = charges(id) + n
	return true

## Reserve one activation of `id`: consume a charge if available, else debit SB.
## Returns {ok, paid_with} where paid_with is "charge" or "sb". Fail-closed and
## atomic on insufficient funds. Does NOT apply the booster effect — the caller
## (BoosterService) applies the effect and calls refund() if the effect fails.
func reserve(id: String) -> Dictionary:
	if not is_booster(id):
		return {"ok": false, "reason": "unknown_booster"}
	if charges(id) > 0:
		_charges[id] = charges(id) - 1
		return {"ok": true, "paid_with": "charge"}
	var price := int(_config.booster_price(id))
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, price):
		return {"ok": false, "reason": "insufficient_sb"}
	return {"ok": true, "paid_with": "sb", "price": price}

## Refund a reservation when the booster effect fails (atomicity).
func refund(id: String, reservation: Dictionary) -> void:
	if not reservation.get("ok", false):
		return
	if reservation.get("paid_with") == "charge":
		_charges[id] = charges(id) + 1
	elif reservation.get("paid_with") == "sb":
		_wallet.credit(EconomyWallet.SCRUB_BUCKS, int(reservation.get("price", 0)))

## Grant `n` player-selected charges to the pending pool.
func add_pending_selected(n: int) -> void:
	if n > 0:
		_pending_selected += n

func pending_selected() -> int:
	return _pending_selected

## Redeem one pending selected charge onto a chosen booster.
func redeem_selected(id: String) -> bool:
	if _pending_selected <= 0 or not is_booster(id):
		return false
	_pending_selected -= 1
	_charges[id] = charges(id) + 1
	return true

func snapshot() -> Dictionary:
	var d := _charges.duplicate()
	d["_pending_selected"] = _pending_selected
	return d

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var new_charges: Dictionary = {}
	for b in BOOSTERS:
		var v = IntDomain.nonneg_int(s.get(b, 0))
		if v == null:
			return false
		new_charges[b] = v
	var ps = IntDomain.nonneg_int(s.get("_pending_selected", 0))
	if ps == null:
		return false
	_charges = new_charges
	_pending_selected = ps
	return true
