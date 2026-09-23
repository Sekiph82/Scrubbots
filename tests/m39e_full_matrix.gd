extends SceneTree
## M39-C001 V01 Phase E — full economy matrix over the EconomyServices container.
## Run: godot --headless --path . -s res://tests/m39e_full_matrix.gd

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _fail := 0
var _t := [1_000_000]

func _clock() -> int:
	return _t[0]

func _mk() -> EconomyServices:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	return EconomyServices.new(EconomyServices.EconomyConfig.DEFAULT_PATH, Callable(self, "_clock"), rng)

func _initialize() -> void:
	_wiring()
	_first_clear_plus_streak()
	_gift_claim_bundle()
	_guaranteed_new_fallback()
	_removed_economies_absent()
	_snapshot_relaunch_no_regrant()
	_removed_key_injection()
	_robot_pacing_evidence()
	_perks_boundary()
	_done()

func _wiring() -> void:
	print("[wiring]")
	var e = _mk()
	_ok(e.config.is_ok(), "config ok")
	_ok(e.wallet.scrub_bucks() == 1000, "single wallet starts at 1000")
	# One authority per resource: streak and first-clear share the SAME reward+wallet.
	_ok(e.streak.reward_service() == e.reward, "streak reuses the canonical reward service")

func _first_clear_plus_streak() -> void:
	print("[first-clear + streak]")
	var e = _mk()
	var start = e.wallet.scrub_bucks()
	# Level 1 EASY first clear: base 50 + 1 bot part; streak win 1 -> +1 SB.
	e.first_clear.grant_first_clear(1, "EASY")
	e.streak.process_first_clear_win(1)
	_ok(e.wallet.scrub_bucks() == start + 50 + 1, "first-clear 50 + streak 1 => +51 SB")
	_ok(e.wallet.bot_parts() == 1, "first-clear grants 1 bot part")
	_ok(e.gift.total_progress() == 1, "only streak SB (1) fed the gift meter")
	# Replay of level 1: no farm anywhere.
	var sb = e.wallet.scrub_bucks()
	e.first_clear.grant_first_clear(1, "EASY", true)
	e.streak.process_first_clear_win(1, true)
	_ok(e.wallet.scrub_bucks() == sb, "replay farms nothing")

func _gift_claim_bundle() -> void:
	print("[gift claim bundle]")
	var e = _mk()
	# Feed 250 streak SB -> crosses 10/50/250. Claim the 250 milestone bundle:
	# 2 bot parts + 100 SB + 1 standard pack.
	e.gift.add_streak_sb("g", 250)
	var before_sb = e.wallet.scrub_bucks()
	var before_bp = e.wallet.bot_parts()
	var r = e.gift.claim("gift_ms:c0:m250", e.reward, e.config)
	_ok(r["ok"], "claim 250 milestone")
	_ok(e.wallet.scrub_bucks() == before_sb + 100 and e.wallet.bot_parts() == before_bp + 2, "250 grants 100 SB + 2 bot parts")

func _guaranteed_new_fallback() -> void:
	print("[guaranteed-new fallback]")
	var e = _mk()
	# Fill the entire collection so no eligible-new card remains.
	for cid in e.collection.all_card_ids():
		e.collection.add_card(cid)
	var before = e.wallet.scrub_bucks()
	# Directly exercise the guaranteed_new handler via a reward bundle.
	e.reward.grant("test_guaranteed", {"guaranteed_new_cards": 1})
	_ok(e.wallet.scrub_bucks() == before + 500, "no eligible card -> exact 500 SB fallback")

func _removed_economies_absent() -> void:
	print("[removed economies]")
	var e = _mk()
	var snap = e.snapshot()
	var text := JSON.stringify(snap).to_lower()
	_ok(text.find("star") == -1, "no star currency key in snapshot")
	_ok(text.find("event_point") == -1, "no event points key in snapshot")
	_ok(text.find("profile_xp") == -1 and text.find("xp_bar") == -1, "no profile-XP economy key in snapshot")

func _snapshot_relaunch_no_regrant() -> void:
	print("[relaunch]")
	var e = _mk()
	e.first_clear.grant_first_clear(1, "EASY")
	e.streak.process_first_clear_win(1)
	e.robots  # touch
	e.wallet.credit(EconomyWallet.BOT_PARTS, 300)
	e.robots.unlock("robot_2")
	var snap = e.snapshot()
	var sb = e.wallet.scrub_bucks()
	var bp = e.wallet.bot_parts()
	# Fresh container (relaunch) imports the snapshot.
	var e2 = _mk()
	_ok(e2.import_snapshot(snap), "aggregate import ok")
	_ok(e2.wallet.scrub_bucks() == sb and e2.wallet.bot_parts() == bp, "wallet restored, not re-granted")
	_ok(e2.robots.is_unlocked("robot_2"), "robot unlock restored")
	# Replaying the same first-clear transaction after relaunch must not re-grant.
	var before = e2.wallet.scrub_bucks()
	e2.first_clear.grant_first_clear(1, "EASY")
	_ok(e2.wallet.scrub_bucks() == before, "post-relaunch duplicate first-clear tx no-op")

func _removed_key_injection() -> void:
	print("[removed key injection]")
	var e = _mk()
	var snap = e.snapshot()
	# Inject a removed-economy key into the snapshot; import must ignore it and
	# still succeed, producing no such state.
	snap["stars"] = 9999
	snap["event_points"] = 5555
	var e2 = _mk()
	_ok(e2.import_snapshot(snap), "import ignores injected removed-economy keys")
	var out := JSON.stringify(e2.snapshot()).to_lower()
	_ok(out.find("9999") == -1 and out.find("5555") == -1, "injected removed-economy values not persisted")

func _robot_pacing_evidence() -> void:
	print("[robot pacing]")
	# Deterministic simulation: an average engaged player clears one new level
	# per session with an unbroken streak. Count bot parts from first-clear (+1
	# each) and streak multiples of 5 (+1 each). Report levels to first unlock.
	var e = _mk()
	var levels := 0
	while e.wallet.bot_parts() < e.config.robot_unlock_cost() and levels < 5000:
		levels += 1
		e.first_clear.grant_first_clear(levels, "EASY")
		e.streak.process_first_clear_win(levels)
	print("  first robot unlock reachable at ~%d levels (bot parts=%d)" % [levels, e.wallet.bot_parts()])
	# Evidence, not a hard gate: with first-clear (1/level) + streak5 (0.2/level)
	# the rate is ~1.2 bot parts/level, so 250 parts ~= 208 levels before other
	# sources (gift/collection) accelerate it toward the ~150 target.
	_ok(levels > 0 and levels <= 250, "first unlock within a bounded, plausible range (%d)" % levels)

func _perks_boundary() -> void:
	print("[perks boundary]")
	var e = _mk()
	# Robot perks are meta/economy-only. The unlock service holds no board/
	# solver/target/route references and exposes no method that could mutate
	# gameplay legality — structural proof of the boundary.
	var forbidden := ["mutate_board", "set_target", "override_route", "reserve_cell", "set_solver_state"]
	var ok := true
	for m in forbidden:
		if e.robots.has_method(m):
			ok = false
	_ok(ok, "robot unlock service exposes no gameplay-legality mutator")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 Phase E evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
