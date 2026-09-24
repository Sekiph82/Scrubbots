extends SceneTree
## M39-C001 V03 — full frozen finding set F-M39-V02-001..016 (except -033 device
## gate). Independent adversarial coverage over the REAL services. Isolated user://
## temp paths only. Run:
## godot --headless --path . -s res://tests/m39_v03_full_surface.gd

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const HeartService = preload("res://scripts/economy/heart_service.gd")
const SpeedEntitlementService = preload("res://scripts/economy/speed_entitlement_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const DailyService = preload("res://scripts/economy/daily_service.gd")
const RobotUnlockService = preload("res://scripts/progression/robot_unlock_service.gd")

var _fail := 0
var _t := [10_000_000]
var _day := [1000]

func _clock() -> int: return _t[0]
func _localday() -> int: return _day[0]

func _initialize() -> void:
	_wallet_canonical()                # F-M39-V02-013
	_reward_gift_booster_canonical()   # F-M39-V02-012
	_heart_speed_domains()             # F-M39-V02-016
	_collection_coherence()            # F-M39-V02-010
	_robot_ids()                       # audit spec
	_config_strict()                   # F-M39-V02-011
	_daily_local_and_atomic()          # F-M39-V02-009/015
	_done()

# --- F-M39-V02-013: wallet resource ids ---
func _wallet_canonical() -> void:
	print("[wallet canonical resources]")
	var w = EconomyWallet.new(0)
	w.credit(EconomyWallet.SCRUB_BUCKS, 100)
	_ok(w.scrub_bucks() == 100, "canonical scrub_bucks credited")
	# Unknown/removed resources are silently refused (not created).
	w.credit("stars", 999)
	_ok(w.get_balance("stars") == 0, "'stars' cannot be created via credit")
	w.credit("event_points", 5)
	_ok(w.get_balance("event_points") == 0, "'event_points' cannot be created via credit")
	_ok(not w.debit("stars", 1), "debit unknown resource refused")
	# Snapshot never surfaces removed keys.
	var snap = w.snapshot()
	_ok(not snap.has("stars") and not snap.has("event_points"), "snapshot only exposes canonical resource keys")

# --- F-M39-V02-012: reward/gift/booster snapshot canonical shape ---
func _reward_gift_booster_canonical() -> void:
	print("[reward/gift/booster canonical]")
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	# Applied ids: non-empty unique strings.
	_ok(not r.import_snapshot({"applied": [""], "wallet": {"scrub_bucks": 0, "bot_parts": 0}}), "empty applied id rejected")
	_ok(not r.import_snapshot({"applied": [123], "wallet": {"scrub_bucks": 0, "bot_parts": 0}}), "non-string applied id rejected")
	_ok(not r.import_snapshot({"applied": ["a", "a"], "wallet": {"scrub_bucks": 0, "bot_parts": 0}}), "duplicate applied id rejected")
	_ok(r.import_snapshot({"applied": ["tx1", "tx2"], "wallet": {"scrub_bucks": 0, "bot_parts": 0}}), "canonical applied ids accepted")

	# Gift meter canonical queue shape.
	var g = GiftMeterService.new()
	var bad = {"cycle_progress": 100, "total_progress": 100, "cycles_completed": 0,
		"gift_bar_queue": ["not_a_dict"], "applied": []}
	_ok(not g.import_snapshot(bad), "malformed queue element rejected")
	# Invalid milestone.
	bad = {"cycle_progress": 100, "total_progress": 100, "cycles_completed": 0,
		"gift_bar_queue": [{"id": "x", "cycle": 0, "milestone": 42, "claimed": false}], "applied": []}
	_ok(not g.import_snapshot(bad), "milestone outside {10,50,250,500,1000} rejected")
	# Duplicate ids.
	bad = {"cycle_progress": 100, "total_progress": 100, "cycles_completed": 0,
		"gift_bar_queue": [{"id": "x", "cycle": 0, "milestone": 10, "claimed": false},
		                    {"id": "x", "cycle": 0, "milestone": 50, "claimed": false}], "applied": []}
	_ok(not g.import_snapshot(bad), "duplicate queue id rejected")
	# Coherence: total != cycle_max*cycles + cycle_progress.
	bad = {"cycle_progress": 100, "total_progress": 999, "cycles_completed": 0,
		"gift_bar_queue": [], "applied": []}
	_ok(not g.import_snapshot(bad), "incoherent total_progress rejected")
	# Canonical accepted.
	var good = {"cycle_progress": 100, "total_progress": 100, "cycles_completed": 0,
		"gift_bar_queue": [{"id": "gift_ms:c0:m10", "cycle": 0, "milestone": 10, "claimed": false}],
		"applied": ["gift:L1"]}
	_ok(g.import_snapshot(good), "canonical gift snapshot accepted")

	# BoosterInventory: reject unknown fifth booster key.
	var c = EconomyConfig.new()
	var bi = BoosterInventory.new(w, c)
	_ok(not bi.import_snapshot({"plus_one_slot": 0, "random": 0, "selector": 0, "tornado": 0, "mega": 1}),
		"unknown fifth booster key rejected")
	_ok(bi.import_snapshot({"plus_one_slot": 0, "random": 1, "selector": 0, "tornado": 0}),
		"exactly-four canonical keys accepted")

# --- F-M39-V02-016: heart/speed sentinel domains ---
func _heart_speed_domains() -> void:
	print("[heart/speed sentinel domains]")
	var w = EconomyWallet.new(1000)
	var c = EconomyConfig.new()
	var h = HeartService.new(w, c, Callable(self, "_clock"))
	# Negative anchor rejected.
	_ok(not h.import_snapshot({"hearts": 5, "anchor": -1}), "negative heart anchor rejected")
	_ok(h.import_snapshot({"hearts": 5, "anchor": 0}), "zero anchor accepted")
	var se = SpeedEntitlementService.new(w, c, Callable(self, "_clock"))
	_ok(se.import_snapshot({"entitled_level": -1, "timed_expiry": 0}), "sentinel -1 accepted")
	_ok(se.import_snapshot({"entitled_level": 5, "timed_expiry": 0}), "valid level accepted")
	_ok(not se.import_snapshot({"entitled_level": 0, "timed_expiry": 0}), "entitled_level 0 rejected (noncanonical)")
	_ok(not se.import_snapshot({"entitled_level": -5, "timed_expiry": 0}), "other negatives rejected")

# --- F-M39-V02-010: collection claimed coherence ---
func _collection_coherence() -> void:
	print("[collection claimed coherence]")
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	r.register_handler("standard_card_packs", func(_a): pass)
	r.register_handler("random_booster_charges", func(_a): pass)
	var c = EconomyConfig.new()
	var inv = CollectionInventory.new(c, r)
	# claimed set 1 without owning any card 1 -> rejected.
	_ok(not inv.import_snapshot({"owned": {}, "set_reward_claimed": [1], "master_claimed": false}),
		"claimed set with 0/9 owned rejected")
	# claimed set 1 with 9/9 owned -> accepted.
	var full = {}
	for i in range(9): full["s1_c%d" % i] = 1
	_ok(inv.import_snapshot({"owned": full, "set_reward_claimed": [1], "master_claimed": false}),
		"claimed set with 9/9 owned accepted")
	# master_claimed=true without all 15 sets -> rejected.
	_ok(not inv.import_snapshot({"owned": full, "set_reward_claimed": [1], "master_claimed": true}),
		"master_claimed without all 15 sets rejected")

func _robot_ids() -> void:
	print("[robot ids]")
	var w = EconomyWallet.new(0)
	var ru = RobotUnlockService.new(w, 250, "scrubby")
	_ok(not ru.import_snapshot({"unlocked": [""]}), "empty robot id rejected")
	_ok(not ru.import_snapshot({"unlocked": [123]}), "non-string robot id rejected")
	_ok(not ru.import_snapshot({"unlocked": ["a", "a"]}), "duplicate robot id rejected")
	_ok(ru.import_snapshot({"unlocked": ["robot_2"]}), "canonical unlocked list accepted")
	_ok(ru.is_unlocked("scrubby"), "scrubby remains canonical initial")

func _config_strict() -> void:
	print("[config strict schema type]")
	# The production config passes.
	var c = EconomyConfig.new()
	_ok(c.is_ok(), "production config ok: %s" % c.get_error())
	# 2.9 must fail (F-M39-V02-011): write a bad copy and load it.
	var path := "user://__m39v3_badcfg_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema_version": 2.9, "currency": {}, "first_clear_sb": {},
		"win_streak": {}, "gift_meter": {}, "bot_parts": {}, "hearts": {}, "speed_2x": {},
		"boosters": {}, "daily": {}, "collection": {}, "cards_exchange": {}, "removed_systems": []}))
	f.close()
	var bad = EconomyConfig.new(path)
	_ok(not bad.is_ok() and bad.get_error().find("schema_version") != -1, "fractional schema_version rejected: %s" % bad.get_error())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _daily_local_and_atomic() -> void:
	print("[daily local + atomic]")
	_t[0] = 5_000_000
	_day[0] = 1000
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	r.register_handler("standard_card_packs", func(_a): pass)
	r.register_handler("random_booster_charges", func(_a): pass)
	var c = EconomyConfig.new()
	var d = DailyService.new(c, r, Callable(self, "_clock"), Callable(self, "_localday"))
	# D1
	var r1 = d.claim_login()
	_ok(r1["ok"] and r1["day"] == 1 and d.streak() == 1, "day1 login")
	# Next local day -> streak 2. Unix seconds may not have moved a whole day.
	_day[0] += 1; _t[0] += 3600
	_ok(d.claim_login()["ok"] and d.streak() == 2, "day2 login via local-day provider")
	# Rollback the local day and clock -> refuse (never duplicate).
	_day[0] -= 1; _t[0] -= 999999
	_ok(not d.claim_login()["ok"], "rolled-back day refused")
	# Tasks reset by local day regardless of login order.
	_day[0] += 5; _t[0] += 5 * 86400
	d.mark_task_done(0)
	_ok(d.tasks_done_count() == 1, "new day task recorded")
	# Simulate a further day cross before login -> tasks reset.
	_day[0] += 1
	_ok(d.tasks_done_count() == 0, "prior-day task completion does not leak into next day")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 V03 full-surface evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
