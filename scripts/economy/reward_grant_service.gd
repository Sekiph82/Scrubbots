extends RefCounted
## RewardGrantService — preload
## (res://scripts/economy/reward_grant_service.gd).
##
## Canonical, idempotent, atomic multi-resource reward grant authority. This is
## the ONLY path that credits rewards; callers never mutate the wallet directly.
## M38 creates this foundation at its final M39 path; M39 EXTENDS it (registers
## more resource handlers such as booster charges / card packs), it must not
## create a duplicate authority.
##
## Idempotency: every grant carries a stable transaction id. A repeated/reentrant
## grant with a known id is a no-op and returns false. This makes duplicate WON /
## duplicate first-clear callbacks safe.
##
## Atomicity: a grant either applies EVERY resource in the reward dict or none.
## If any resource has no registered handler, the whole grant is rejected
## (fail-closed) so no partial economy state is produced.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

var _wallet: EconomyWallet
var _handlers: Dictionary = {}       ## resource(String) -> Callable(amount:int)
var _applied: Dictionary = {}        ## tx_id(String) -> rewards(Dictionary) actually applied.

func _init(wallet: EconomyWallet = null) -> void:
	_wallet = wallet if wallet != null else EconomyWallet.new()
	# Default canonical handlers for the two wallet resources.
	register_handler(EconomyWallet.SCRUB_BUCKS, func(amount): _wallet.credit(EconomyWallet.SCRUB_BUCKS, amount))
	register_handler(EconomyWallet.BOT_PARTS, func(amount): _wallet.credit(EconomyWallet.BOT_PARTS, amount))

func wallet() -> EconomyWallet:
	return _wallet

## M39 extension seam: register a handler for a new resource type.
func register_handler(resource: String, handler: Callable) -> void:
	_handlers[resource] = handler

func has_handler(resource: String) -> bool:
	return _handlers.has(resource)

func already_applied(tx_id: String) -> bool:
	return _applied.has(tx_id)

## Grant `rewards` ({resource: amount}) under a stable `tx_id`.
## Returns true only if this call newly applied the grant.
## Fail-closed: unknown resource or negative amount -> nothing applied.
func grant(tx_id: String, rewards: Dictionary) -> bool:
	if tx_id.is_empty():
		return false
	if _applied.has(tx_id):
		return false
	# Validate everything BEFORE mutating (atomicity).
	for resource in rewards.keys():
		if not _handlers.has(resource):
			return false
		var amount = rewards[resource]
		if typeof(amount) != TYPE_INT and typeof(amount) != TYPE_FLOAT:
			return false
		if int(amount) < 0:
			return false
	# Apply.
	for resource in rewards.keys():
		var amount := int(rewards[resource])
		_handlers[resource].call(amount)
	_applied[tx_id] = rewards.duplicate()
	return true

func applied_transaction_count() -> int:
	return _applied.size()

func snapshot() -> Dictionary:
	# Persist applied tx ids so a reloaded session cannot re-grant.
	return {
		"applied": _applied.keys(),
		"wallet": _wallet.snapshot(),
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var applied_raw = s.get("applied", [])
	if typeof(applied_raw) != TYPE_ARRAY:
		return false
	var wallet_ok := true
	if s.has("wallet"):
		wallet_ok = _wallet.import_snapshot(s["wallet"])
	if not wallet_ok:
		return false
	var new_applied: Dictionary = {}
	for tx in applied_raw:
		new_applied[String(tx)] = {}
	_applied = new_applied
	return true
