extends SceneTree
## M39-C001 V01 Phase A — config, wallet, rewards, gift meter, robots.
## Run: godot --headless --path . -s res://tests/m39a_economy_core.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const FirstClearRewardService = preload("res://scripts/economy/first_clear_reward_service.gd")
const RobotUnlockService = preload("res://scripts/progression/robot_unlock_service.gd")

var _fail := 0

func _initialize() -> void:
	_config()
	_wallet_domain()
	_atomic_grant_spend()
	_initial_1000_once()
	_first_clear()
	_gift_meter_full_cycle()
	_robot_unlock()
	_done()

func _config() -> void:
	print("[config]")
	var c = EconomyConfig.new()
	_ok(c.is_ok(), "economy config loaded: %s" % c.get_error())
	_ok(c.starting_scrub_bucks() == 1000, "starting SB 1000")
	_ok(c.first_clear_sb("EASY") == 50 and c.first_clear_sb("VERY_HARD") == 150, "first-clear SB table")
	_ok(c.win_streak_sb(1) == 1 and c.win_streak_sb(5) == 100 and c.win_streak_sb(9) == 100, "win streak SB from config")
	_ok(c.robot_unlock_cost() == 250, "robot cost 250")
	# Fail closed on missing file.
	var bad = EconomyConfig.new("res://data/config/does_not_exist.json")
	_ok(not bad.is_ok(), "missing config fails closed")

func _wallet_domain() -> void:
	print("[wallet]")
	var w = EconomyWallet.new(1000)
	_ok(w.scrub_bucks() == 1000, "starts 1000")
	w.credit(EconomyWallet.SCRUB_BUCKS, 50)
	_ok(w.scrub_bucks() == 1050, "credit works")
	_ok(not w.debit(EconomyWallet.SCRUB_BUCKS, 99999), "over-debit rejected")
	_ok(w.scrub_bucks() == 1050, "balance unchanged on failed debit")
	_ok(w.debit(EconomyWallet.SCRUB_BUCKS, 50), "valid debit ok")
	_ok(w.scrub_bucks() == 1000, "balance after debit")
	# Negative credit ignored.
	w.credit(EconomyWallet.SCRUB_BUCKS, -100)
	_ok(w.scrub_bucks() == 1000, "negative credit ignored")

func _atomic_grant_spend() -> void:
	print("[atomic]")
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	_ok(r.grant("t1", {EconomyWallet.SCRUB_BUCKS: 100, EconomyWallet.BOT_PARTS: 2}), "multi-resource grant applied")
	_ok(w.scrub_bucks() == 100 and w.bot_parts() == 2, "both resources credited")
	_ok(not r.grant("t1", {EconomyWallet.SCRUB_BUCKS: 100}), "duplicate tx no-op")
	# Bundle with one unknown resource -> nothing applied (atomic).
	_ok(not r.grant("t2", {EconomyWallet.SCRUB_BUCKS: 50, "unknown": 1}), "bundle with unknown resource fails closed")
	_ok(w.scrub_bucks() == 100, "no partial apply from failed bundle")

func _initial_1000_once() -> void:
	print("[initial 1000]")
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(c.starting_scrub_bucks())
	_ok(w.scrub_bucks() == 1000, "new player exactly 1000")
	# Reload via snapshot import must not re-grant.
	var snap = w.snapshot()
	var w2 = EconomyWallet.new(c.starting_scrub_bucks())  # constructor would grant 1000 again...
	w2.import_snapshot(snap)                                # ...but import overwrites to saved value
	_ok(w2.scrub_bucks() == 1000, "import overrides constructor default (no double grant)")
	# Simulate earned balance persisted, then reload.
	w.credit(EconomyWallet.SCRUB_BUCKS, 500)
	var w3 = EconomyWallet.new(c.starting_scrub_bucks())
	w3.import_snapshot(w.snapshot())
	_ok(w3.scrub_bucks() == 1500, "reload restores earned balance, not another 1000")

func _first_clear() -> void:
	print("[first clear]")
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	var fc = FirstClearRewardService.new(r, c)
	var res = fc.grant_first_clear(1, "EASY")
	_ok(res["applied"] and w.scrub_bucks() == 50 and w.bot_parts() == 1, "EASY first-clear: 50 SB + 1 bot part")
	# Duplicate no farm.
	var res2 = fc.grant_first_clear(1, "EASY")
	_ok(not res2["applied"] and w.scrub_bucks() == 50, "duplicate first-clear no farm")
	# Replay no farm.
	var res3 = fc.grant_first_clear(2, "HARD", true)
	_ok(not res3["applied"] and w.scrub_bucks() == 50, "replay no farm")
	# Different level grants.
	fc.grant_first_clear(2, "HARD")
	_ok(w.scrub_bucks() == 150 and w.bot_parts() == 2, "HARD first-clear adds 100 SB + 1 bot part")

func _gift_meter_full_cycle() -> void:
	print("[gift meter]")
	var c = EconomyConfig.new()
	var g = GiftMeterService.new()
	# A full 0->1000 cycle grants exactly 10 Bot Parts across milestones.
	_ok(g.full_cycle_bot_parts(c) == 10, "full cycle = 10 bot parts (config)")
	# Feed 1000 in one shot: crosses all 5 milestones, completes cycle.
	var newly = g.add_streak_sb("s1", 1000)
	_ok(newly.size() == 5, "single 1000 feed crosses all 5 milestones once")
	_ok(g.cycles_completed() == 1 and g.cycle_progress() == 0, "cycle completed, progress 0")
	# Claim a milestone through the reward service (register test handlers for pack/booster).
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	var packs := [0]
	r.register_handler("standard_card_packs", func(a): packs[0] += a)
	r.register_handler("premium_card_packs", func(a): packs[0] += a)
	r.register_handler("random_booster_charges", func(_a): pass)
	r.register_handler("selected_booster_charges", func(_a): pass)
	r.register_handler("guaranteed_new_cards", func(_a): pass)
	r.register_handler("guaranteed_new_fallback_sb", func(a): w.credit(EconomyWallet.SCRUB_BUCKS, a))
	var occ_id := "gift_ms:c0:m10"
	var claim = g.claim(occ_id, r, c)
	_ok(claim["ok"], "claim milestone 10 ok")
	_ok(w.bot_parts() == 1 and packs[0] == 1, "milestone 10 grants 1 bot part + 1 standard pack")
	# Double-claim is a no-op.
	var claim2 = g.claim(occ_id, r, c)
	_ok(not claim2["ok"], "double-claim rejected")

func _robot_unlock() -> void:
	print("[robot unlock]")
	var w = EconomyWallet.new(0)
	var ru = RobotUnlockService.new(w, 250, "scrubby")
	_ok(ru.is_unlocked("scrubby"), "scrubby unlocked at start")
	_ok(not ru.is_unlocked("robot_2"), "robot_2 locked")
	var res = ru.unlock("robot_2")
	_ok(not res["ok"] and res["reason"] == "insufficient_parts", "cannot unlock without parts")
	w.credit(EconomyWallet.BOT_PARTS, 300)
	res = ru.unlock("robot_2")
	_ok(res["ok"] and w.bot_parts() == 50, "unlock spends 250, overflow 50 preserved")
	_ok(ru.is_unlocked("robot_2"), "robot_2 now unlocked")
	# Idempotent: re-unlock spends nothing.
	res = ru.unlock("robot_2")
	_ok(not res["ok"] and w.bot_parts() == 50, "re-unlock spends nothing")
	# Never negative.
	_ok(w.bot_parts() >= 0, "bot parts never negative")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 Phase A evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
