extends SceneTree
## M38-C001 V01 — win streak evidence.
## Run: godot --headless --path . -s res://tests/m38_win_streak.gd
## Exits 0 on success, 1 on any failure.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const WinStreakService = preload("res://scripts/economy/win_streak_service.gd")

var _fail := 0

func _initialize() -> void:
	_mapping()
	_reward_path_and_wallet()
	_bot_part_multiples_of_5()
	_gift_meter_source_isolation()
	_gift_meter_rollover()
	_duplicate_and_reentrant()
	_replay_isolation()
	_reset_semantics()
	_stale_and_invalid()
	_reward_service_idempotent()
	_snapshot_import()
	_malformed_snapshot()
	_done()

func _fresh() -> WinStreakService:
	var wallet = EconomyWallet.new(1000)
	var reward = RewardGrantService.new(wallet)
	var gift = GiftMeterService.new()
	return WinStreakService.new(reward, gift)

func _mapping() -> void:
	print("[mapping]")
	_ok(WinStreakService.streak_sb_for(1) == 1, "1 -> 1 SB")
	_ok(WinStreakService.streak_sb_for(2) == 5, "2 -> 5 SB")
	_ok(WinStreakService.streak_sb_for(3) == 10, "3 -> 10 SB")
	_ok(WinStreakService.streak_sb_for(4) == 25, "4 -> 25 SB")
	_ok(WinStreakService.streak_sb_for(5) == 100, "5 -> 100 SB")
	_ok(WinStreakService.streak_sb_for(6) == 100, "6 -> 100 SB")
	_ok(WinStreakService.streak_sb_for(50) == 100, "50 -> 100 SB")
	_ok(WinStreakService.streak_sb_for(0) == 0, "0 -> 0 SB")

func _reward_path_and_wallet() -> void:
	print("[reward path]")
	var s = _fresh()
	var wallet = s.reward_service().wallet()
	var start := wallet.scrub_bucks()
	# Win levels 1..4: streak SB 1,5,10,25 = 41 total.
	s.process_first_clear_win(1)
	s.process_first_clear_win(2)
	s.process_first_clear_win(3)
	s.process_first_clear_win(4)
	_ok(wallet.scrub_bucks() == start + 41, "SB credited via RewardGrantService (1+5+10+25=41)")
	_ok(s.streak() == 4, "streak == 4")

func _bot_part_multiples_of_5() -> void:
	print("[bot part x5]")
	var s = _fresh()
	var wallet = s.reward_service().wallet()
	for n in range(1, 11):
		s.process_first_clear_win(n)
	# Bot parts granted at streak 5 and 10 -> 2 total.
	_ok(wallet.bot_parts() == 2, "bot parts at streak 5 and 10 == 2 (got %d)" % wallet.bot_parts())
	# No bot part at non-multiples: streak 4 gave none.
	var s2 = _fresh()
	s2.process_first_clear_win(1); s2.process_first_clear_win(2); s2.process_first_clear_win(3); s2.process_first_clear_win(4)
	_ok(s2.reward_service().wallet().bot_parts() == 0, "no bot part before streak 5")

func _gift_meter_source_isolation() -> void:
	print("[gift source]")
	var s = _fresh()
	var gift = s.gift_service()
	# streak SB 1+5+10 across wins 1..3 feeds gift meter.
	s.process_first_clear_win(1); s.process_first_clear_win(2); s.process_first_clear_win(3)
	_ok(gift.total_progress() == 16, "gift meter fed streak SB only (1+5+10=16)")
	# A direct wallet-style grant (non-streak) must NOT touch gift meter: grant
	# base SB through reward service directly, gift total unchanged.
	s.reward_service().grant("base:L1", {EconomyWallet.SCRUB_BUCKS: 50})
	_ok(gift.total_progress() == 16, "non-streak grant did not advance gift meter")

func _gift_meter_rollover() -> void:
	print("[gift rollover]")
	var gift = GiftMeterService.new()
	# 950 then +100 -> crosses 1000, cycle completes, next cycle at 50.
	gift.add_streak_sb("a", 950)
	var newly = gift.add_streak_sb("b", 100)
	_ok(gift.cycles_completed() == 1, "cycle completed at 1000")
	_ok(gift.cycle_progress() == 50, "overflow rolled to 50")
	var crossed_1000 := false
	for occ in newly:
		if occ["milestone"] == 1000:
			crossed_1000 = true
	_ok(crossed_1000, "1000 milestone queued on crossing")
	# A single large feed crossing multiple milestones queues each once.
	var gift2 = GiftMeterService.new()
	var n2 = gift2.add_streak_sb("x", 300)   # crosses 10, 50, 250
	_ok(n2.size() == 3, "single feed crossing 10/50/250 queues 3 milestones")

func _duplicate_and_reentrant() -> void:
	print("[duplicate]")
	var s = _fresh()
	var wallet = s.reward_service().wallet()
	var start := wallet.scrub_bucks()
	var r1 = s.process_first_clear_win(1)
	_ok(r1["applied"], "first win applied")
	# Duplicate WON for same level.
	var r2 = s.process_first_clear_win(1)
	_ok(not r2["applied"] and r2["reason"] == "duplicate", "duplicate win rejected")
	# Reentrant burst.
	for _i in range(10):
		s.process_first_clear_win(1)
	_ok(s.streak() == 1, "streak still 1 after duplicates")
	_ok(wallet.scrub_bucks() == start + 1, "SB granted exactly once (1)")

func _replay_isolation() -> void:
	print("[replay]")
	var s = _fresh()
	var wallet = s.reward_service().wallet()
	s.process_first_clear_win(1)   # streak 1
	var start := wallet.scrub_bucks()
	var gift_before := s.gift_service().total_progress()
	var r = s.process_first_clear_win(2, true)  # replay
	_ok(not r["applied"] and r["reason"] == "replay", "replay win not applied")
	_ok(s.streak() == 1, "replay did not advance streak")
	_ok(wallet.scrub_bucks() == start, "replay granted no SB")
	_ok(s.gift_service().total_progress() == gift_before, "replay did not feed gift meter")

func _reset_semantics() -> void:
	print("[reset]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2)
	_ok(s.streak() == 2, "streak 2 before loss")
	s.on_progression_loss()
	_ok(s.streak() == 0, "progression loss resets to 0")
	# Restart after real gameplay resets; pre-action does not.
	s.process_first_clear_win(3)   # streak 1 (level 3 first-clear)
	s.on_gameplay_started()
	s.on_restart()
	_ok(s.streak() == 0, "restart after gameplay resets streak")
	# Pre-action exit leaves streak intact.
	s.process_first_clear_win(4)   # streak 1
	s.on_pre_action_exit()
	_ok(s.streak() == 1, "pre-action exit does not reset streak")

func _stale_and_invalid() -> void:
	print("[stale/invalid]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2); s.process_first_clear_win(3)
	# Stale old-level WON after advancing: level 1 already processed.
	var r = s.process_first_clear_win(1)
	_ok(not r["applied"], "stale old-level WON rejected")
	_ok(s.streak() == 3, "streak unaffected by stale WON")
	# Invalid level.
	_ok(not s.process_first_clear_win(0)["applied"], "level 0 rejected")
	_ok(not s.process_first_clear_win(-1)["applied"], "negative level rejected")

func _reward_service_idempotent() -> void:
	print("[reward idempotent]")
	var wallet = EconomyWallet.new(0)
	var reward = RewardGrantService.new(wallet)
	_ok(reward.grant("tx1", {EconomyWallet.SCRUB_BUCKS: 100}), "grant tx1 applied")
	_ok(not reward.grant("tx1", {EconomyWallet.SCRUB_BUCKS: 100}), "duplicate tx1 no-op")
	_ok(wallet.scrub_bucks() == 100, "wallet credited once")
	# Unknown resource -> fail closed, nothing applied (atomic).
	_ok(not reward.grant("tx2", {"gold_coins": 5}), "unknown resource fails closed")
	_ok(wallet.scrub_bucks() == 100, "no partial apply on unknown resource")
	# Negative amount rejected.
	_ok(not reward.grant("tx3", {EconomyWallet.SCRUB_BUCKS: -5}), "negative amount rejected")

func _snapshot_import() -> void:
	print("[snapshot]")
	var s = _fresh()
	s.process_first_clear_win(1); s.process_first_clear_win(2); s.process_first_clear_win(3)
	var snap: Dictionary = s.snapshot()
	_ok(snap["streak"] == 3, "snapshot streak 3")
	# Import into a fresh service; duplicate transaction replay must not re-grant.
	var s2 = _fresh()
	_ok(s2.import_snapshot(snap), "import ok")
	_ok(s2.streak() == 3, "imported streak restored")
	# A processed level cannot re-grant after import.
	var r = s2.process_first_clear_win(1)
	_ok(not r["applied"], "processed level rejected after import")

func _malformed_snapshot() -> void:
	print("[malformed]")
	var s = _fresh()
	s.process_first_clear_win(1)
	var before := s.streak()
	_ok(not s.import_snapshot(null), "null rejected")
	_ok(not s.import_snapshot({"schema": "x", "streak": 5, "processed": []}), "wrong schema rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": -3, "processed": []}), "negative streak rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 999999999, "processed": [0]}), "invalid processed entry rejected")
	_ok(s.streak() == before, "state untouched after malformed imports")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M38 win streak evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
