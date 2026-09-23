extends RefCounted
## RobotUnlockService — preload
## (res://scripts/progression/robot_unlock_service.gd).
##
## Owner decision §5: Scrubby unlocked at start; every later robot costs exactly
## 250 Bot Parts; overflow preserved; Bot Parts are never purchasable with SB.
## Spends Bot Parts from the canonical EconomyWallet. Never lets Bot Parts go
## negative. Read-only next-robot progress seam (SB-M39-016).

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

var _wallet: EconomyWallet
var _cost: int
var _initial_robot: String
var _unlocked: Dictionary = {}       ## robot_id -> true

func _init(wallet: EconomyWallet, cost: int = 250, initial_robot_id: String = "scrubby") -> void:
	_wallet = wallet
	_cost = cost
	_initial_robot = initial_robot_id
	_unlocked[_initial_robot] = true

func is_unlocked(robot_id: String) -> bool:
	return _unlocked.has(robot_id)

func unlocked_count() -> int:
	return _unlocked.size()

func unlock_cost() -> int:
	return _cost

## Attempt to unlock `robot_id` by spending exactly `_cost` Bot Parts. Atomic:
## checks funds before mutation; on insufficient parts nothing changes. Returns
## {ok, reason, remaining_parts}. Idempotent: unlocking an already-unlocked robot
## returns ok=false reason="already_unlocked" and spends nothing.
func unlock(robot_id: String) -> Dictionary:
	if _unlocked.has(robot_id):
		return {"ok": false, "reason": "already_unlocked", "remaining_parts": _wallet.bot_parts()}
	if not _wallet.debit(EconomyWallet.BOT_PARTS, _cost):
		return {"ok": false, "reason": "insufficient_parts", "remaining_parts": _wallet.bot_parts()}
	_unlocked[robot_id] = true
	return {"ok": true, "reason": "unlocked", "remaining_parts": _wallet.bot_parts()}

## Read-only progress toward the next robot given current Bot Parts (overflow
## preserved: parts beyond a multiple of cost carry forward).
func next_robot_progress() -> Dictionary:
	var parts := _wallet.bot_parts()
	return {
		"parts": parts,
		"cost": _cost,
		"progress_fraction": clampf(float(parts) / float(_cost), 0.0, 1.0),
		"can_unlock": parts >= _cost,
	}

func snapshot() -> Dictionary:
	return {"unlocked": _unlocked.keys(), "cost": _cost, "initial_robot": _initial_robot}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var raw = s.get("unlocked", null)
	if typeof(raw) != TYPE_ARRAY:
		return false
	var new_unlocked: Dictionary = {}
	for r in raw:
		new_unlocked[String(r)] = true
	# Initial robot is always unlocked regardless of snapshot content.
	new_unlocked[_initial_robot] = true
	_unlocked = new_unlocked
	return true
