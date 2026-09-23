extends RefCounted
## SpeedEntitlementService — preload
## (res://scripts/economy/speed_entitlement_service.gd).
##
## Owns 2x PURCHASE ENTITLEMENTS only — it is separate from the gameplay
## GameplaySpeedAuthority (which owns the live speed factor). Two entitlement
## kinds (owner §):
##   - current-level 2x: 200 SB, bound to a progression level, survives retries
##     of that same level until a successful completion clears it;
##   - timed 2x: 15m/300, 30m/500, 60m/750, ABSOLUTE wall clock; a new purchase
##     extends expiry from max(now, current_expiry).
##
## The free automatic M23-exhausted endgame 2x is entitlement-INDEPENDENT and
## never charged/refunded/extended here (SB-M39-028): this service is only asked
## about MANUAL 2x. Wall clock is injected for deterministic tests; never uses
## gameplay delta / Engine.time_scale.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

var _wallet: EconomyWallet
var _current_level_price: int
var _timed_products: Dictionary = {}   ## seconds -> price_sb
var _clock: Callable

var _entitled_level: int = -1          ## current-level entitlement target (-1 none).
var _timed_expiry: int = 0             ## absolute wall-clock expiry (0 = none).

func _init(wallet: EconomyWallet, config, clock: Callable = Callable()) -> void:
	_wallet = wallet
	_current_level_price = config.speed_current_level_sb()
	for p in config.speed_timed_products():
		_timed_products[int(p.get("seconds", 0))] = int(p.get("sb", 0))
	_clock = clock if clock.is_valid() else Callable(self, "_default_clock")

func _default_clock() -> int:
	return int(Time.get_unix_time_from_system())

func _now() -> int:
	return int(_clock.call())

# --- current-level 2x ---

func purchase_current_level(level: int) -> Dictionary:
	if level < 1:
		return {"ok": false, "reason": "invalid_level"}
	if _entitled_level == level:
		return {"ok": false, "reason": "already_entitled"}
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, _current_level_price):
		return {"ok": false, "reason": "insufficient_sb"}
	_entitled_level = level
	return {"ok": true, "spent": _current_level_price}

## Clear current-level entitlement on successful completion of that level. A
## retry (non-success) does NOT clear it, so the entitlement survives retries.
func on_level_completed(level: int, success: bool) -> void:
	if success and _entitled_level == level:
		_entitled_level = -1

# --- timed 2x ---

func purchase_timed(seconds: int) -> Dictionary:
	if not _timed_products.has(seconds):
		return {"ok": false, "reason": "unknown_product"}
	var price: int = _timed_products[seconds]
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, price):
		return {"ok": false, "reason": "insufficient_sb"}
	var base: int = max(_now(), _timed_expiry)
	_timed_expiry = base + seconds
	return {"ok": true, "spent": price, "expiry": _timed_expiry}

func timed_seconds_remaining() -> int:
	return max(_timed_expiry - _now(), 0)

# --- manual gate ---

## True if a MANUAL 2x is entitled for `current_level` right now. This does NOT
## consider the free automatic endgame 2x, which is independent.
func is_manual_2x_entitled(current_level: int) -> bool:
	if _entitled_level == current_level and current_level >= 1:
		return true
	return _now() < _timed_expiry

func snapshot() -> Dictionary:
	return {"entitled_level": _entitled_level, "timed_expiry": _timed_expiry}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var lvl = s.get("entitled_level", -1)
	var exp = s.get("timed_expiry", 0)
	if typeof(lvl) != TYPE_INT and typeof(lvl) != TYPE_FLOAT:
		return false
	if typeof(exp) != TYPE_INT and typeof(exp) != TYPE_FLOAT:
		return false
	if int(exp) < 0:
		return false
	_entitled_level = int(lvl)
	_timed_expiry = int(exp)
	return true
