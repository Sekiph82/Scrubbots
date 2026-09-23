extends RefCounted
## BoosterService — preload
## (res://scripts/economy/booster_service.gd).
##
## Applies the four boosters against the live gameplay engine through a
## duck-typed ENGINE ADAPTER, so the transaction/rollback/solver-safety contract
## is testable without the audited engine and cannot bypass the solver.
##
## Contract (owner §, SB-M39-030/034..040):
##   - +1 Slot: SlotCapacityAuthority upgrade 5->6 (per attempt, once).
##   - Random: reorders ONLY remaining unselected batches; committed ONLY if the
##     deterministic solver proves >=3 legal non-deadlocking front selections.
##     Unsafe -> no charge, no SB, no reorder.
##   - Selector: atomically extracts one solver-safe remaining batch into the
##     rightmost EMPTY slot; full capacity / unsafe choice consumes nothing.
##   - Tornado: multi-system atomic purge (supply/slots/claims/agents/solver);
##     ANY stage failure rolls back every touched system and consumes no
##     charge/SB.
##
## Charge-first-then-SB reservation happens ONLY after the safety pre-checks
## pass, and is refunded if the committed effect fails (atomicity).

const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _inventory: BoosterInventory

func _init(inventory: BoosterInventory) -> void:
	_inventory = inventory

## Generic multi-stage transaction. `stages` is an Array of dicts, each:
##   {"apply": Callable() -> bool, "rollback": Callable() -> void}
## Applies in order; on the first failure rolls back all previously-applied
## stages in reverse. Returns true iff every stage applied.
func _run_transaction(stages: Array) -> bool:
	var applied: Array = []
	for stage in stages:
		var ok = false
		var apply: Callable = stage.get("apply", Callable())
		if apply.is_valid():
			ok = bool(apply.call())
		if not ok:
			for i in range(applied.size() - 1, -1, -1):
				var rb: Callable = applied[i].get("rollback", Callable())
				if rb.is_valid():
					rb.call()
			return false
		applied.append(stage)
	return true

# ------------------------------------------------------------ +1 Slot ----

func apply_plus_one_slot(capacity_authority) -> Dictionary:
	if not capacity_authority.can_activate_plus_one():
		return {"ok": false, "reason": "already_max_or_used"}
	var res := _inventory.reserve(BoosterInventory.PLUS_ONE_SLOT)
	if not res.get("ok", false):
		return {"ok": false, "reason": res.get("reason", "reserve_failed")}
	if not capacity_authority.activate_plus_one():
		_inventory.refund(BoosterInventory.PLUS_ONE_SLOT, res)
		return {"ok": false, "reason": "activate_failed"}
	return {"ok": true, "paid_with": res.get("paid_with"), "capacity": capacity_authority.active_capacity()}

# ------------------------------------------------------------ Random ----

## adapter.propose_random_reorder() -> {safe, commit:Callable->bool, rollback:Callable}
func apply_random(adapter) -> Dictionary:
	var proposal: Dictionary = adapter.propose_random_reorder()
	if not proposal.get("safe", false):
		return {"ok": false, "reason": "not_solver_safe"}   # no charge, no reorder
	var res := _inventory.reserve(BoosterInventory.RANDOM)
	if not res.get("ok", false):
		return {"ok": false, "reason": res.get("reason", "reserve_failed")}
	var ok := _run_transaction([{"apply": proposal.get("commit"), "rollback": proposal.get("rollback")}])
	if not ok:
		_inventory.refund(BoosterInventory.RANDOM, res)
		return {"ok": false, "reason": "commit_failed"}
	return {"ok": true, "paid_with": res.get("paid_with")}

# ------------------------------------------------------------ Selector ----

## adapter.eligible_safe_batches() -> Array of batch ids
## adapter.extract_batch(batch_id) -> {ok, apply:Callable->bool, rollback:Callable}
func apply_selector(adapter, batch_id) -> Dictionary:
	var eligible: Array = adapter.eligible_safe_batches()
	if not eligible.has(batch_id):
		return {"ok": false, "reason": "not_eligible"}   # unsafe/full -> no charge
	var res := _inventory.reserve(BoosterInventory.SELECTOR)
	if not res.get("ok", false):
		return {"ok": false, "reason": res.get("reason", "reserve_failed")}
	var extraction: Dictionary = adapter.extract_batch(batch_id)
	var ok := _run_transaction([{"apply": extraction.get("apply"), "rollback": extraction.get("rollback")}])
	if not ok:
		_inventory.refund(BoosterInventory.SELECTOR, res)
		return {"ok": false, "reason": "extract_failed"}
	return {"ok": true, "paid_with": res.get("paid_with")}

# ------------------------------------------------------------ Tornado ----

## adapter.present_colors() -> Array
## adapter.tornado_stages(color) -> Array of {apply:Callable->bool, rollback:Callable}
##   staged across supply/slots/claims/agents/solver reconciliation.
func apply_tornado(adapter, color) -> Dictionary:
	if not adapter.present_colors().has(color):
		return {"ok": false, "reason": "color_not_present"}
	var res := _inventory.reserve(BoosterInventory.TORNADO)
	if not res.get("ok", false):
		return {"ok": false, "reason": res.get("reason", "reserve_failed")}
	var stages: Array = adapter.tornado_stages(color)
	var ok := _run_transaction(stages)
	if not ok:
		# All touched systems already rolled back by _run_transaction.
		_inventory.refund(BoosterInventory.TORNADO, res)
		return {"ok": false, "reason": "rolled_back"}
	return {"ok": true, "paid_with": res.get("paid_with")}
