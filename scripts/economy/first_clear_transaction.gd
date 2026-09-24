extends RefCounted
## FirstClearTransaction — preload (res://scripts/economy/first_clear_transaction.gd).
##
## Atomic new-frontier WON coordinator (M39 V04, F-M39-V03-004). One transaction:
##   1. LevelProgressionService.record_win (forward-only authority; stale/future/
##      replay rejects here with ZERO mutation and nothing else runs);
##   2. base first-clear reward (SB by class + Bot Part);
##   3. Win Streak advance (+ streak SB, Gift Meter feed, milestone Bot Part);
##   4. current-level 2x entitlement completion.
## Snapshot/rollback boundary: the exact progression + full EconomyServices
## snapshot (wallet, Bot Parts, RewardGrant applied tx set, streak, Gift Meter,
## entitlement, ...) is captured before step 1 and re-imported if any later step
## fails, so a failure leaves no partial commit.
##
## `fault` is a test-only seam: fault(stage) -> true forces a failure AFTER that
## stage mutated. Stages: "progression", "first_clear", "streak", "entitlement".

static func commit(progression, economy, level_number: int, fault: Callable = Callable()) -> Dictionary:
	var pre_prog: Dictionary = progression.snapshot()
	var pre_econ: Dictionary = economy.snapshot()
	if not progression.record_win(level_number):
		return {"ok": false, "reason": "not_frontier"}   # zero mutation by contract
	var failed := ""
	if _hit(fault, "progression"):
		failed = "progression"
	if failed == "":
		var cls: String = progression.class_for(level_number)
		var fc: Dictionary = economy.first_clear.grant_first_clear(level_number, cls)
		if not bool(fc.get("applied", false)) or _hit(fault, "first_clear"):
			failed = "first_clear"
	if failed == "":
		var st: Dictionary = economy.streak.process_first_clear_win(level_number)
		if not bool(st.get("applied", false)) or _hit(fault, "streak"):
			failed = "streak"
	if failed == "":
		economy.speed.on_level_completed(level_number, true)
		if _hit(fault, "entitlement"):
			failed = "entitlement"
	if failed != "":
		var rolled: bool = progression.import_snapshot(pre_prog) and economy.import_snapshot(pre_econ)
		return {"ok": false, "reason": "rolled_back", "stage": failed, "restored": rolled}
	return {"ok": true}

static func _hit(fault: Callable, stage: String) -> bool:
	return fault.is_valid() and bool(fault.call(stage))
