extends SceneTree
## M39-C001 V01 Phase B — Hearts + 2x entitlements (injected wall clock).
## Run: godot --headless --path . -s res://tests/m39b_hearts_speed.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const HeartService = preload("res://scripts/economy/heart_service.gd")
const SpeedEntitlementService = preload("res://scripts/economy/speed_entitlement_service.gd")

var _fail := 0
var _t := [1_000_000]   # mutable injected clock

func _clock() -> int:
	return _t[0]

func _advance(seconds: int) -> void:
	_t[0] += seconds

func _initialize() -> void:
	_hearts_regen()
	_hearts_consume_and_purchase()
	_hearts_clock_rollback()
	_speed_current_level()
	_speed_timed()
	_speed_free_auto_independent()
	_done()

func _hearts_regen() -> void:
	print("[hearts regen]")
	_t[0] = 1_000_000
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var h = HeartService.new(w, c, Callable(self, "_clock"))
	_ok(h.hearts() == 5, "starts at max 5")
	_ok(c.hearts_regen_seconds() == 900, "owner V06: canonical regen interval 900 s (15 min)")
	_ok(h.seconds_to_next() == 0, "full: no pending regen")
	# One consume from full -> 4, countdown starts at the full 900 s interval.
	h.consume()
	_ok(h.hearts() == 4 and h.seconds_to_next() == 900, "consume from full -> 4, seconds_to_next 900 (%d)" % h.seconds_to_next())
	_advance(899)
	_ok(h.hearts() == 4 and h.seconds_to_next() == 1, "+899 s: no regen yet, 1 s left")
	_advance(1)
	_ok(h.hearts() == 5 and h.seconds_to_next() == 0, "+900 s: one Heart regenerated, full again")
	# Consume 3 -> 2. Regen 1 per 900 s, each missing Heart on its own interval.
	h.consume(); h.consume(); h.consume()
	_ok(h.hearts() == 2, "after 3 consumes -> 2")
	_advance(900)
	_ok(h.hearts() == 3 and h.seconds_to_next() == 900, "one regen after 900 s; next interval restarts at 900")
	_advance(450)
	_ok(h.hearts() == 3 and h.seconds_to_next() == 450, "mid-interval: 450 s left")
	_advance(450 + 900)
	_ok(h.hearts() == 5, "two more regens (900 s each) cap at max 5")
	# At full the anchor tracks now, so no overflow.
	_advance(900 * 20)
	_ok(h.hearts() == 5, "no overflow past max after long offline")
	# Offline burst: 3 missing Hearts and 2700 s away (app closed) -> all back.
	h.consume(); h.consume(); h.consume()
	_advance(2700)
	_ok(h.hearts() == 5, "offline wall-clock time regenerates 3 Hearts in 3 x 900 s")

func _hearts_consume_and_purchase() -> void:
	print("[hearts purchase]")
	_t[0] = 2_000_000
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var h = HeartService.new(w, c, Callable(self, "_clock"))
	h.consume(); h.consume()   # 5 -> 3
	var before := w.scrub_bucks()
	var r = h.purchase_plus_one()
	_ok(r["ok"] and h.hearts() == 4 and w.scrub_bucks() == before - 500, "+1 heart costs 500 SB")
	# Full refill: missing 1 -> 400.
	var r2 = h.purchase_full_refill()
	_ok(r2["ok"] and h.hearts() == 5 and w.scrub_bucks() == before - 500 - 400, "full refill 400/missing")
	# At full, purchases refused, no charge.
	var bal := w.scrub_bucks()
	_ok(not h.purchase_plus_one()["ok"] and w.scrub_bucks() == bal, "no +1 at full, no charge")
	_ok(not h.purchase_full_refill()["ok"] and w.scrub_bucks() == bal, "no refill at full, no charge")
	# Insufficient funds: atomic no-charge.
	var poor = EconomyWallet.new(100)
	var hp = HeartService.new(poor, c, Callable(self, "_clock"))
	hp.consume()
	_ok(not hp.purchase_plus_one()["ok"] and poor.scrub_bucks() == 100, "insufficient SB: no heart, no charge")

func _hearts_clock_rollback() -> void:
	print("[hearts rollback]")
	_t[0] = 3_000_000
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var h = HeartService.new(w, c, Callable(self, "_clock"))
	h.consume()   # 4
	# Roll clock BACKWARD: no regen, no anchor corruption.
	_t[0] -= 100000
	_ok(h.hearts() == 4, "clock rollback does not regen")
	# Forward again normally still regens (one 900 s interval after the consume).
	_t[0] = 3_000_000 + 900
	_ok(h.hearts() == 5, "forward time after rollback regens normally")

func _speed_current_level() -> void:
	print("[speed current level]")
	_t[0] = 4_000_000
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var se = SpeedEntitlementService.new(w, c, Callable(self, "_clock"))
	var r = se.purchase_current_level(11)
	_ok(r["ok"] and w.scrub_bucks() == 10000 - 200, "current-level 2x costs 200 SB")
	_ok(se.is_manual_2x_entitled(11), "entitled on level 11")
	_ok(not se.is_manual_2x_entitled(12), "not entitled on a different level")
	# Survives a retry (non-success) of the same level.
	se.on_level_completed(11, false)
	_ok(se.is_manual_2x_entitled(11), "entitlement survives a failed retry")
	# Cleared on success.
	se.on_level_completed(11, true)
	_ok(not se.is_manual_2x_entitled(11), "entitlement cleared on success")

func _speed_timed() -> void:
	print("[speed timed]")
	_t[0] = 5_000_000
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var se = SpeedEntitlementService.new(w, c, Callable(self, "_clock"))
	# Unknown product rejected.
	_ok(not se.purchase_timed(123)["ok"], "unknown timed product rejected")
	# 15m/300.
	var r = se.purchase_timed(900)
	_ok(r["ok"] and w.scrub_bucks() == 10000 - 300, "15m timed costs 300 SB")
	_ok(se.is_manual_2x_entitled(999), "timed 2x entitles regardless of level")
	# Extends from current expiry: buy another 30m -> remaining ~ 900+1800.
	se.purchase_timed(1800)
	_ok(se.timed_seconds_remaining() == 900 + 1800, "purchase extends from current expiry")
	# Expires by absolute wall clock.
	_advance(900 + 1800 + 1)
	_ok(not se.is_manual_2x_entitled(999), "timed 2x expires by wall clock")
	# Buying after expiry extends from now (not stale expiry).
	se.purchase_timed(900)
	_ok(se.timed_seconds_remaining() == 900, "post-expiry purchase extends from now")

func _speed_free_auto_independent() -> void:
	print("[free auto 2x]")
	# The manual gate is the only thing this service governs. The free auto
	# endgame 2x is not charged/extended here; with no entitlement, manual gate
	# is closed, which does not affect the independent free auto path.
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(0)
	var se = SpeedEntitlementService.new(w, c, Callable(self, "_clock"))
	_ok(not se.is_manual_2x_entitled(1), "no manual entitlement without purchase")
	_ok(w.scrub_bucks() == 0, "free auto path never touches wallet via this service")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 Phase B evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
