extends SceneTree
## M39-C001 V01 Phase D — daily, collection, packs, exchange.
## Run: godot --headless --path . -s res://tests/m39d_daily_collection.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const CardPackService = preload("res://scripts/collection/card_pack_service.gd")
const CardsExchangeService = preload("res://scripts/economy/cards_exchange_service.gd")
const DailyService = preload("res://scripts/economy/daily_service.gd")

var _fail := 0
var _t := [1_000_000]

func _clock() -> int:
	return _t[0]

func _initialize() -> void:
	_collection_shape()
	_set_and_master_rewards()
	_totals_proof()
	_packs()
	_exchange()
	_daily_login()
	_daily_tasks()
	_daily_calendar_safety()
	_done()

func _mk_reward() -> Array:
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	# Register card-pack / booster handlers so gift/daily bundles never fail.
	r.register_handler("standard_card_packs", func(_a): pass)
	r.register_handler("premium_card_packs", func(_a): pass)
	r.register_handler("random_booster_charges", func(_a): pass)
	r.register_handler("selected_booster_charges", func(_a): pass)
	r.register_handler("guaranteed_new_cards", func(_a): pass)
	return [c, w, r]

func _collection_shape() -> void:
	print("[collection shape]")
	var m = _mk_reward()
	var inv = CollectionInventory.new(m[0], m[2])
	_ok(inv.all_card_ids().size() == 15 * 9, "15x9 = 135 cards in catalog")
	# First copy protected: owned starts 0, add 1 -> 1.
	var cid = inv.all_card_ids()[0]
	inv.add_card(cid)
	_ok(inv.owned(cid) == 1, "owned increments")
	_ok(not inv.is_set_complete(99), "unknown set not complete")

func _complete_set(inv, set_no: int) -> void:
	for cid in inv.all_card_ids():
		if inv.card_rarity(cid) != "" and cid.begins_with("s%d_" % set_no):
			if inv.owned(cid) < 1:
				inv.add_card(cid)

func _set_and_master_rewards() -> void:
	print("[set + master]")
	var m = _mk_reward()
	var w = m[1]; var inv = CollectionInventory.new(m[0], m[2])
	# Complete set 1 -> 350 SB + 5 bot parts, once.
	_complete_set(inv, 1)
	_ok(inv.is_set_complete(1), "set 1 complete")
	_ok(w.scrub_bucks() == 350 and w.bot_parts() == 5, "set 1 reward 350 SB + 5 bot parts once")
	# Re-adding a card in a completed set does not re-grant.
	var before_sb = w.scrub_bucks()
	inv.add_card("s1_c0")
	_ok(w.scrub_bucks() == before_sb, "duplicate card in complete set does not re-grant")

func _totals_proof() -> void:
	print("[totals]")
	var m = _mk_reward()
	var w = m[1]; var inv = CollectionInventory.new(m[0], m[2])
	# Complete ALL 15 sets.
	for s in range(1, 16):
		_complete_set(inv, s)
	_ok(inv.completed_set_count() == 15, "all 15 sets complete")
	# 15 set milestones = 13350 SB + 147 bot parts; + master 2500/20 = 15850/167.
	_ok(w.scrub_bucks() == 15850, "total SB incl master = 15850 (got %d)" % w.scrub_bucks())
	_ok(w.bot_parts() == 167, "total bot parts incl master = 167 (got %d)" % w.bot_parts())
	# Master granted exactly once: re-add a card, no change.
	var sb = w.scrub_bucks()
	inv.add_card("s1_c0")
	_ok(w.scrub_bucks() == sb, "master not re-granted")

func _packs() -> void:
	print("[packs]")
	var m = _mk_reward()
	var inv = CollectionInventory.new(m[0], m[2])
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	var packs = CardPackService.new(inv, rng)
	var std = packs.open_standard()
	_ok(std.size() == 3, "standard pack = 3 draws")
	var prem = packs.open_premium()
	_ok(prem.size() == 5, "premium pack = 5 draws")
	# Premium guarantees >=1 rare-or-better.
	var has_rare := false
	for cid in prem:
		if inv.card_rarity(cid) != "COMMON":
			has_rare = true
	_ok(has_rare, "premium pack has >=1 rare-or-better")
	# Deterministic RNG: same seed -> same draws.
	var inv2 = CollectionInventory.new(m[0], m[2])
	var rng2 = RandomNumberGenerator.new(); rng2.seed = 999
	var p1 = CardPackService.new(inv2, rng2).open_standard()
	var inv3 = CollectionInventory.new(m[0], m[2])
	var rng3 = RandomNumberGenerator.new(); rng3.seed = 999
	var p2 = CardPackService.new(inv3, rng3).open_standard()
	_ok(p1 == p2, "same seed -> identical draws (deterministic test RNG)")

func _exchange() -> void:
	print("[exchange]")
	var m = _mk_reward()
	var w = m[1]; var inv = CollectionInventory.new(m[0], m[2])
	var ex = CardsExchangeService.new(inv, m[2], m[0])
	var cid = "s1_c0"   # COMMON (profile 4C first)
	_ok(inv.card_rarity(cid) == "COMMON", "s1_c0 is COMMON")
	# One copy -> no extras exchangeable (protected).
	inv.add_card(cid)
	_ok(ex.exchangeable(cid) == 0, "single protected copy not exchangeable")
	# Add 2 more -> 2 extras.
	inv.add_card(cid); inv.add_card(cid)
	_ok(ex.exchangeable(cid) == 2, "two extras exchangeable")
	var before = w.scrub_bucks()
	var r = ex.exchange_card(cid, 2, ex.next_tx_id())
	_ok(r["ok"] and w.scrub_bucks() == before + 50 and inv.owned(cid) == 1, "exchange 2 COMMON -> +50 SB, owned back to protected 1")
	# Never below 1.
	_ok(not ex.exchange_card(cid, 1, ex.next_tx_id())["ok"], "cannot exchange the protected copy")
	# Duplicate tx idempotent.
	inv.add_card(cid); inv.add_card(cid)   # 2 extras again
	var tx := "fixed_tx"
	var r1 = ex.exchange_card(cid, 1, tx)
	var r2 = ex.exchange_card(cid, 1, tx)
	_ok(r1["ok"] and not r2["ok"], "duplicate exchange tx rejected")
	# Exchange all extras atomic.
	inv.add_card(cid); inv.add_card(cid)
	var all = ex.exchange_all_extras("all_tx")
	_ok(all["ok"], "exchange-all-extras ok")
	_ok(inv.owned(cid) == 1, "owned back to protected 1 after exchange-all")

func _daily_login() -> void:
	print("[daily login]")
	_t[0] = 100 * 86400 + 3600   # day 100
	var m = _mk_reward()
	var w = m[1]
	var daily = DailyService.new(m[0], m[2], Callable(self, "_clock"))
	var r = daily.claim_login()
	_ok(r["ok"] and r["day"] == 1 and daily.streak() == 1, "day 1 login")
	_ok(w.scrub_bucks() == 100, "D1 grants 100 SB")
	# Same day: no duplicate.
	_ok(not daily.claim_login()["ok"], "same-day re-claim rejected")
	# Next day -> day 2, streak 2.
	_t[0] += 86400
	var r2 = daily.claim_login()
	_ok(r2["ok"] and r2["day"] == 2 and daily.streak() == 2, "day 2 login, streak 2")

func _daily_tasks() -> void:
	print("[daily tasks]")
	_t[0] = 200 * 86400 + 3600
	var m = _mk_reward()
	var w = m[1]
	var daily = DailyService.new(m[0], m[2], Callable(self, "_clock"))
	daily.claim_login()
	daily.mark_task_done(0); daily.mark_task_done(1); daily.mark_task_done(2)
	_ok(daily.claim_task(0)["sb"] == 75, "task 0 = 75 SB")
	_ok(daily.claim_task(1)["sb"] == 100, "task 1 = 100 SB")
	_ok(daily.claim_task(2)["sb"] == 125, "task 2 = 125 SB")
	# Duplicate task claim rejected.
	_ok(not daily.claim_task(0)["ok"], "duplicate task claim rejected")
	# All-tasks bonus once.
	_ok(daily.claim_all_tasks_bonus()["ok"], "all-tasks bonus granted")
	_ok(not daily.claim_all_tasks_bonus()["ok"], "all-tasks bonus once")

func _daily_calendar_safety() -> void:
	print("[calendar safety]")
	_t[0] = 300 * 86400 + 3600
	var m = _mk_reward()
	var daily = DailyService.new(m[0], m[2], Callable(self, "_clock"))
	daily.claim_login()   # day 300, streak 1
	_t[0] += 86400
	daily.claim_login()   # day 301, streak 2
	# Miss a day: jump 2 days ahead -> streak resets to 1.
	_t[0] += 86400 * 2
	var r = daily.claim_login()
	_ok(r["ok"] and daily.streak() == 1, "missed day resets streak to 1")
	# Clock rollback: going back a day must not duplicate a claim.
	_t[0] -= 86400 * 5
	_ok(not daily.claim_login()["ok"], "clock rollback does not allow a duplicate claim")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 Phase D evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
