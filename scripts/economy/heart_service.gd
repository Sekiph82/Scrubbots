extends RefCounted
## HeartService — preload
## (res://scripts/economy/heart_service.gd).
##
## Owner §: Hearts are attempt capacity (max 5), regen 1 per 1800 real-world
## seconds using an ABSOLUTE wall clock (offline/menu/background/closed-app time
## all count). Never uses gameplay delta or Engine.time_scale.
##
## The wall clock is injected (`_clock`) so tests are deterministic. Regen is
## computed lazily on query/mutation by accruing elapsed intervals since an
## anchor timestamp — bounded work, no per-frame polling. Clock rollback is
## resisted: a backwards clock accrues nothing and never moves the anchor back.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

var _max: int
var _regen_seconds: int
var _plus_one_sb: int
var _refill_sb_per_missing: int
var _wallet: EconomyWallet
var _clock: Callable

var _hearts: int
var _anchor: int          ## wall-clock time the current regen interval started.

func _init(wallet: EconomyWallet, config, clock: Callable = Callable()) -> void:
	_wallet = wallet
	_max = config.hearts_max()
	_regen_seconds = config.hearts_regen_seconds()
	_plus_one_sb = config.hearts_plus_one_sb()
	_refill_sb_per_missing = config.hearts_full_refill_sb_per_missing()
	_clock = clock if clock.is_valid() else Callable(self, "_default_clock")
	_hearts = _max
	_anchor = _now()

func _default_clock() -> int:
	return int(Time.get_unix_time_from_system())

func _now() -> int:
	return int(_clock.call())

func _accrue() -> void:
	if _hearts >= _max:
		_anchor = _now()
		return
	var now := _now()
	var elapsed := now - _anchor
	if elapsed <= 0:
		return  # clock rollback / no time passed: accrue nothing, keep anchor.
	var gained := int(elapsed / _regen_seconds)
	if gained <= 0:
		return
	_hearts = min(_max, _hearts + gained)
	_anchor += gained * _regen_seconds
	if _hearts >= _max:
		_anchor = now

func hearts() -> int:
	_accrue()
	return _hearts

func max_hearts() -> int:
	return _max

## Seconds until the next heart regens (0 if full).
func seconds_to_next() -> int:
	_accrue()
	if _hearts >= _max:
		return 0
	var remaining := _regen_seconds - (_now() - _anchor)
	return max(remaining, 0)

## Consume one heart (progression loss or restart-after-gameplay). Returns true
## if a heart was consumed. Starts the regen anchor at consume time if we were
## full. Fail-closed at 0.
func consume() -> bool:
	_accrue()
	if _hearts <= 0:
		return false
	var was_full := _hearts >= _max
	_hearts -= 1
	if was_full:
		_anchor = _now()
	return true

## +1 Heart for 500 SB. Atomic: no charge if already full or funds insufficient.
func purchase_plus_one() -> Dictionary:
	_accrue()
	if _hearts >= _max:
		return {"ok": false, "reason": "already_full"}
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, _plus_one_sb):
		return {"ok": false, "reason": "insufficient_sb"}
	_hearts += 1
	if _hearts >= _max:
		_anchor = _now()
	return {"ok": true, "hearts": _hearts, "spent": _plus_one_sb}

## Full refill = 400 SB per missing heart. Atomic.
func purchase_full_refill() -> Dictionary:
	_accrue()
	var missing := _max - _hearts
	if missing <= 0:
		return {"ok": false, "reason": "already_full"}
	var cost := missing * _refill_sb_per_missing
	if not _wallet.debit(EconomyWallet.SCRUB_BUCKS, cost):
		return {"ok": false, "reason": "insufficient_sb"}
	_hearts = _max
	_anchor = _now()
	return {"ok": true, "hearts": _hearts, "spent": cost}

func snapshot() -> Dictionary:
	# Persist hearts + anchor as absolute wall-clock so relaunch continues regen.
	_accrue()
	return {"hearts": _hearts, "anchor": _anchor}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var h = s.get("hearts", null)
	var a = s.get("anchor", null)
	if typeof(h) != TYPE_INT and typeof(h) != TYPE_FLOAT:
		return false
	if typeof(a) != TYPE_INT and typeof(a) != TYPE_FLOAT:
		return false
	var hi := int(h)
	if hi < 0 or hi > _max:
		return false
	_hearts = hi
	_anchor = int(a)
	return true
