extends SceneTree
## M38-C001 V02 — strict-v2 adversarial Win Streak validation.
## Independent from the V01 happy-path suite. Uses exact state snapshots before/
## after every rejected operation.
## Run: godot --headless --path . -s res://tests/m38_v02_strict.gd

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const WinStreakService = preload("res://scripts/economy/win_streak_service.gd")

var _fail := 0

func _initialize() -> void:
	_duplicate_reentrant()
	_stale_prior_level()
	_replay_isolation()
	_reset_matrix()
	_boundaries_exact_state()
	_reward_failure_no_mutation()
	_gift_idempotent()
	_snapshot_then_replay()
	_malformed_fractional_snapshot()
	_large_valid_streak()
	_done()

func _fresh() -> WinStreakService:
	var w = EconomyWallet.new(1000)
	var r = RewardGrantService.new(w)
	var g = GiftMeterService.new()
	return WinStreakService.new(r, g)

## Exact economy state fingerprint for before/after comparison.
func _state(s: WinStreakService) -> String:
	var w = s.reward_service().wallet()
	return JSON.stringify({
		"streak": s.streak(),
		"sb": w.scrub_bucks(),
		"bp": w.bot_parts(),
		"gift_total": s.gift_service().total_progress(),
		"gift_cycle": s.gift_service().cycle_progress(),
	})

func _duplicate_reentrant() -> void:
	print("[duplicate/reentrant]")
	var s = _fresh()
	_ok(s.process_first_clear_win(1)["applied"], "first-clear win applied")
	var before = _state(s)
	for _i in range(10):
		s.process_first_clear_win(1)
	_ok(_state(s) == before, "duplicate/reentrant first-clear leaves exact state unchanged")

func _stale_prior_level() -> void:
	print("[stale prior level]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2); s.process_first_clear_win(3)
	var before = _state(s)
	_ok(not s.process_first_clear_win(1)["applied"], "stale prior-level callback rejected")
	_ok(_state(s) == before, "stale callback leaves exact state unchanged")

func _replay_isolation() -> void:
	print("[replay isolation]")
	var s = _fresh()
	s.process_first_clear_win(1)
	var before = _state(s)
	_ok(not s.process_first_clear_win(2, true)["applied"], "replay win not applied")
	_ok(_state(s) == before, "replay win leaves exact state unchanged")

func _reset_matrix() -> void:
	print("[reset matrix]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2)
	_ok(s.streak() == 2, "streak 2")
	s.on_progression_loss()
	_ok(s.streak() == 0, "progression loss -> 0")
	# restart-after-action resets; pre-action-exit does not.
	s.process_first_clear_win(3)      # streak 1
	s.on_gameplay_started(); s.on_restart()
	_ok(s.streak() == 0, "restart after real gameplay -> 0")
	s.process_first_clear_win(4)      # streak 1
	s.on_pre_action_exit()
	_ok(s.streak() == 1, "pre-action exit preserves streak")

func _boundaries_exact_state() -> void:
	print("[4->5, 5->6, 9->10 exact]")
	var s = _fresh()
	var w = s.reward_service().wallet()
	# Win levels 1..4 (streak SB 1+5+10+25=41, no bot part yet).
	for n in range(1, 5):
		s.process_first_clear_win(n)
	_ok(w.scrub_bucks() == 1000 + 41 and w.bot_parts() == 0, "after 4: SB +41, 0 bot parts")
	# 4->5: +100 SB, +1 bot part (multiple of 5).
	s.process_first_clear_win(5)
	_ok(w.scrub_bucks() == 1000 + 141 and w.bot_parts() == 1, "4->5: +100 SB, +1 bot part")
	# 5->6: +100 SB, no bot part.
	s.process_first_clear_win(6)
	_ok(w.scrub_bucks() == 1000 + 241 and w.bot_parts() == 1, "5->6: +100 SB, still 1 bot part")
	# 6..9 then 9->10: +100 SB each; bot part again at 10.
	for n in range(7, 11):
		s.process_first_clear_win(n)
	_ok(w.bot_parts() == 2, "9->10 crossing grants a second bot part")

func _reward_failure_no_mutation() -> void:
	print("[reward failure -> no mutation]")
	var w = EconomyWallet.new(1000)
	var g = GiftMeterService.new()
	var fake = _FakeReward.new(w)   # grant() always fails, not already_applied
	var s = WinStreakService.new(fake, g)
	var before_streak = s.streak()
	var before_sb = w.scrub_bucks()
	var r = s.process_first_clear_win(1)
	_ok(not r["applied"] and r["reason"] == "reward_failed", "reward grant failure reported")
	_ok(s.streak() == before_streak, "streak not advanced on reward failure")
	_ok(w.scrub_bucks() == before_sb, "wallet unchanged on reward failure")
	_ok(g.total_progress() == 0, "gift meter not fed on reward failure")
	# The level is NOT marked processed, so a later good attempt can still win it.
	var s2 = _fresh()
	_ok(s2.process_first_clear_win(1)["applied"], "level 1 still winnable on a healthy service")

func _gift_idempotent() -> void:
	print("[gift idempotent]")
	var s = _fresh()
	s.process_first_clear_win(1)   # gift fed once (tx gift:L1)
	var before = s.gift_service().total_progress()
	# Re-feeding the same tx id is a no-op at the gift meter.
	s.gift_service().add_streak_sb("gift:L1", 999)
	_ok(s.gift_service().total_progress() == before, "duplicate gift tx does not double-advance")

func _snapshot_then_replay() -> void:
	print("[snapshot then replay]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2)
	var snap = s.snapshot()
	var s2 = _fresh()
	_ok(s2.import_snapshot(snap), "snapshot imports")
	var before = _state(s2)
	_ok(not s2.process_first_clear_win(1)["applied"], "replay of processed level after import rejected")
	_ok(_state(s2) == before, "post-import replay leaves exact state unchanged")

func _malformed_fractional_snapshot() -> void:
	print("[malformed/fractional]")
	var s = _fresh()
	s.process_first_clear_win(1)
	var before = _state(s)
	_ok(not s.import_snapshot(null), "null rejected")
	_ok(not s.import_snapshot({"schema": "wrong", "streak": 3, "processed": []}), "wrong schema rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": -3, "processed": []}), "negative streak rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 3.5, "processed": []}), "fractional streak fails closed")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 3, "processed": [1, 2.5]}), "fractional processed entry fails closed")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 3, "processed": [1, 1]}), "duplicate processed id fails closed")
	_ok(_state(s) == before, "state unchanged after every malformed import")

func _large_valid_streak() -> void:
	print("[large valid streak]")
	var s = _fresh()
	_ok(s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 100000, "processed": [1, 2, 3]}), "large valid streak imports")
	_ok(s.streak() == 100000, "large streak restored")
	_ok(WinStreakService.streak_sb_for(100000) == 100, "large streak still maps to 100 SB")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M38 V02 strict validation: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

## Fake reward whose grant() always fails and is never "already applied" — used
## to prove the WinStreakService reward-failure rollback (no economy mutation).
class _FakeReward:
	var _w
	func _init(w) -> void:
		_w = w
	func wallet():
		return _w
	func grant(_tx, _rewards) -> bool:
		return false
	func already_applied(_tx) -> bool:
		return false
