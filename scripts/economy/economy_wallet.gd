extends RefCounted
## EconomyWallet — preload
## (res://scripts/economy/economy_wallet.gd).
##
## Narrow canonical soft-currency + Bot Parts ledger. M38 foundation; M39 extends
## it (Hearts, boosters, cards etc. are their own services, NOT wallet balances).
## Balances are non-negative integers. Only RewardGrantService (and, in M39, the
## explicit spend services) mutate it — UI never mutates the wallet directly.

const IntDomain = preload("res://scripts/economy/int_domain.gd")

const SCRUB_BUCKS := "scrub_bucks"
const BOT_PARTS := "bot_parts"

var _balances: Dictionary = {}

func _init(starting_scrub_bucks: int = 0) -> void:
	_balances[SCRUB_BUCKS] = max(starting_scrub_bucks, 0)
	_balances[BOT_PARTS] = 0

func get_balance(resource: String) -> int:
	return int(_balances.get(resource, 0))

func scrub_bucks() -> int:
	return get_balance(SCRUB_BUCKS)

func bot_parts() -> int:
	return get_balance(BOT_PARTS)

## Credit a non-negative amount. Returns the new balance. Negative amounts are
## rejected (spends go through debit, not credit).
func credit(resource: String, amount: int) -> int:
	if amount < 0:
		return get_balance(resource)
	_balances[resource] = get_balance(resource) + amount
	return _balances[resource]

## Debit a non-negative amount. Atomic and fail-closed: if the balance is
## insufficient (would go negative) nothing changes and it returns false. Used
## by the explicit M39 spend services (robot unlock, hearts, boosters, speed).
func debit(resource: String, amount: int) -> bool:
	if amount < 0:
		return false
	if get_balance(resource) < amount:
		return false
	_balances[resource] = get_balance(resource) - amount
	return true

func snapshot() -> Dictionary:
	return {"scrub_bucks": scrub_bucks(), "bot_parts": bot_parts()}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var sb = IntDomain.nonneg_int(s.get("scrub_bucks", null))
	var bp = IntDomain.nonneg_int(s.get("bot_parts", null))
	if sb == null or bp == null:
		return false
	_balances[SCRUB_BUCKS] = sb
	_balances[BOT_PARTS] = bp
	return true
