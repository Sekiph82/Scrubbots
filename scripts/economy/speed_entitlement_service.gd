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
##
## Anti-rollback (M55-C002, coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md): timed 2x
## fails closed on backward device-clock movement. Every read observes the wall clock
## into a persisted, non-decreasing high-water mark; timed truth is computed against
## effective time = max(wall clock, high-water). A backward jump therefore freezes the
## countdown (remaining never increases, an expired entitlement never revives); normal
## forward movement still expires it. Only an explicit purchase extends the expiry.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

var _wallet: EconomyWallet
var _current_level_price: int
var _timed_products: Dictionary = {}   ## seconds -> price_sb
var _clock: Callable

var _entitled_level: int = -1          ## current-level entitlement target (-1 none).
var _timed_expiry: int = 0             ## absolute wall-clock expiry (0 = none).
var _clock_high_water: int = 0         ## highest wall-clock value observed (M55-C002).

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

## Effective (non-decreasing) time: observes the wall clock into the high-water mark.
func _effective_now() -> int:
	_clock_high_water = maxi(_clock_high_water, maxi(_now(), 0))
	return _clock_high_water

## Read-only view of the persisted anti-rollback guard (tests/diagnostics).
func clock_high_water() -> int:
	return _clock_high_water

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

## Read-only: is the CURRENT-LEVEL entitlement held for `level` (timed ignored)?
func is_level_entitled(level: int) -> bool:
	return level >= 1 and _entitled_level == level

# --- timed 2x ---

func purchase_timed(seconds: int) -> Dictionary:
	if not _timed_products.has(seconds):
		return {"ok": false, "reason": "unknown_product"}
	var price: int = _timed_products[seconds]
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, price):
		return {"ok": false, "reason": "insufficient_sb"}
	var base: int = max(_effective_now(), _timed_expiry)
	_timed_expiry = base + seconds
	return {"ok": true, "spent": price, "expiry": _timed_expiry}

func timed_seconds_remaining() -> int:
	return max(_timed_expiry - _effective_now(), 0)

# --- manual gate ---

## True if a MANUAL 2x is entitled for `current_level` right now. This does NOT
## consider the free automatic endgame 2x, which is independent.
func is_manual_2x_entitled(current_level: int) -> bool:
	if _entitled_level == current_level and current_level >= 1:
		return true
	return _effective_now() < _timed_expiry

func snapshot() -> Dictionary:
	return {"entitled_level": _entitled_level, "timed_expiry": _timed_expiry,
		"clock_high_water": _effective_now()}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var lvl = IntDomain.exact_int(s.get("entitled_level", -1))
	var exp = IntDomain.nonneg_int(s.get("timed_expiry", 0))
	if lvl == null or exp == null:
		return false
	# M55-C002 guard. Present => strict non-negative exact int, else fail closed.
	# Absent (legacy save) => initialized at this upgraded import boundary from the only
	# observable clock state, the current wall clock (no invented history).
	var hw = 0
	if s.has("clock_high_water"):
		hw = IntDomain.nonneg_int(s["clock_high_water"])
		if hw == null:
			return false
	# Canonical sentinel domain (M39 V03, F-M39-V02-016): exactly -1 or >= 1.
	# Anything else (0, other negatives) is noncanonical and fails closed.
	if lvl != -1 and lvl < 1:
		return false
	_entitled_level = lvl
	_timed_expiry = exp
	_clock_high_water = hw
	_effective_now()
	return true
