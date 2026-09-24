extends SceneTree
## M39-C001 V01 Phase C — booster inventory, slot capacity, transactional
## booster application with fault injection.
## Run: godot --headless --path . -s res://tests/m39c_boosters.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const SlotCapacityAuthority = preload("res://scripts/economy/slot_capacity_authority.gd")
const BoosterService = preload("res://scripts/economy/booster_service.gd")

var _fail := 0

func _initialize() -> void:
	_inventory_charge_first_then_sb()
	_no_fifth_booster()
	_capacity_5_6()
	_plus_one()
	_random_safety()
	_selector()
	_tornado_rollback()
	_done()

func _mk() -> Array:
	var c = EconomyConfig.new()
	var w = EconomyWallet.new(10000)
	var inv = BoosterInventory.new(w, c)
	return [c, w, inv]

func _inventory_charge_first_then_sb() -> void:
	print("[charge-first]")
	var m = _mk()
	var w = m[1]; var inv = m[2]
	inv.add_charges(BoosterInventory.RANDOM, 1)
	var r1 = inv.reserve(BoosterInventory.RANDOM)
	_ok(r1["ok"] and r1["paid_with"] == "charge", "uses charge first")
	_ok(inv.charges(BoosterInventory.RANDOM) == 0, "charge consumed")
	var before = w.scrub_bucks()
	var r2 = inv.reserve(BoosterInventory.RANDOM)
	_ok(r2["ok"] and r2["paid_with"] == "sb" and w.scrub_bucks() == before - 350, "falls back to SB (350)")
	# Refund path.
	inv.refund(BoosterInventory.RANDOM, r2)
	_ok(w.scrub_bucks() == before, "SB refunded on failure")
	inv.refund(BoosterInventory.RANDOM, r1)
	_ok(inv.charges(BoosterInventory.RANDOM) == 1, "charge refunded on failure")

func _no_fifth_booster() -> void:
	print("[no 5th]")
	var m = _mk()
	var inv = m[2]
	_ok(inv.is_booster("tornado") and not inv.is_booster("mega"), "only the four canonical boosters")
	_ok(BoosterInventory.BOOSTERS.size() == 4, "exactly four boosters")
	_ok(not inv.reserve("mega")["ok"], "unknown booster reserve rejected")

func _capacity_5_6() -> void:
	print("[capacity]")
	var cap = SlotCapacityAuthority.new()
	_ok(cap.active_capacity() == 5, "baseline 5")
	_ok(cap.activate_plus_one() and cap.active_capacity() == 6, "activate -> 6")
	_ok(not cap.activate_plus_one(), "cannot activate twice in one attempt")
	_ok(cap.active_capacity() == 6, "still 6, never 7")
	cap.begin_new_attempt()
	_ok(cap.active_capacity() == 5, "new attempt back to 5")
	_ok(cap.can_activate_plus_one(), "+1 re-armed for new attempt")

func _plus_one() -> void:
	print("[+1 slot]")
	var m = _mk()
	var w = m[1]; var inv = m[2]
	var svc = BoosterService.new(inv)
	var cap = SlotCapacityAuthority.new()
	var before = w.scrub_bucks()
	var r = svc.apply_plus_one_slot(cap)
	_ok(r["ok"] and cap.active_capacity() == 6 and w.scrub_bucks() == before - 500, "+1 slot costs 500 SB -> capacity 6")
	# Second activation same attempt refused, no charge.
	var bal = w.scrub_bucks()
	var r2 = svc.apply_plus_one_slot(cap)
	_ok(not r2["ok"] and w.scrub_bucks() == bal, "second +1 same attempt refused, no charge")

func _random_safety() -> void:
	print("[random]")
	var m = _mk()
	var w = m[1]; var inv = m[2]
	var svc = BoosterService.new(inv)
	# Unsafe proposal: no charge, no SB, no reorder.
	var before = w.scrub_bucks()
	var unsafe_adapter = _RandomAdapter.new(false, true)
	var r = svc.apply_random(unsafe_adapter)
	_ok(not r["ok"] and r["reason"] == "not_solver_safe", "unsafe random rejected")
	_ok(w.scrub_bucks() == before and not unsafe_adapter.committed, "unsafe: no SB, no reorder")
	# Safe proposal commits and charges.
	var safe_adapter = _RandomAdapter.new(true, true)
	var r2 = svc.apply_random(safe_adapter)
	_ok(r2["ok"] and safe_adapter.committed and w.scrub_bucks() == before - 350, "safe random commits + charges 350")
	# Safe but commit fails at apply: rollback + refund.
	var bal = w.scrub_bucks()
	var fail_adapter = _RandomAdapter.new(true, false)
	var r3 = svc.apply_random(fail_adapter)
	_ok(not r3["ok"] and not fail_adapter.committed and w.scrub_bucks() == bal, "commit failure applies nothing + refunds")

func _selector() -> void:
	print("[selector]")
	var m = _mk()
	var w = m[1]; var inv = m[2]
	var svc = BoosterService.new(inv)
	var adapter = _SelectorAdapter.new(["b1", "b2"], true)
	# Not eligible -> no charge.
	var before = w.scrub_bucks()
	var r = svc.apply_selector(adapter, "b9")
	_ok(not r["ok"] and w.scrub_bucks() == before, "ineligible batch: no charge")
	# Eligible extract commits + charges 500.
	var r2 = svc.apply_selector(adapter, "b1")
	_ok(r2["ok"] and adapter.extracted == "b1" and w.scrub_bucks() == before - 500, "selector extracts + charges 500")
	# Extract failure rolls back + refunds.
	var bal = w.scrub_bucks()
	var adapter2 = _SelectorAdapter.new(["b3"], false)
	var r3 = svc.apply_selector(adapter2, "b3")
	_ok(not r3["ok"] and adapter2.extracted == "" and w.scrub_bucks() == bal, "extract failure applies nothing + refunds")

func _tornado_rollback() -> void:
	print("[tornado]")
	var m = _mk()
	var w = m[1]; var inv = m[2]
	var svc = BoosterService.new(inv)
	# Color not present -> no charge.
	var before = w.scrub_bucks()
	var a0 = _TornadoAdapter.new(["C01"], -1)
	_ok(not svc.apply_tornado(a0, "C09")["ok"] and w.scrub_bucks() == before, "absent color: no charge")
	# All 5 stages succeed -> committed + charged 750.
	var a1 = _TornadoAdapter.new(["C01"], -1)
	var r = svc.apply_tornado(a1, "C01")
	_ok(r["ok"] and a1.applied_count == 5 and w.scrub_bucks() == before - 750, "tornado 5-stage commit + charge 750")
	# Fault injected at each stage: V03 runner rolls back the failing stage itself
	# too (F-M39-V02-005), then unwinds earlier successes. The fake adapter's
	# rollback only decrements if that stage actually applied, so net mutation
	# always ends at 0 regardless of which stage failed.
	for fail_stage in range(5):
		var mm = _mk()
		var ww = mm[1]; var ii = mm[2]
		var ss = BoosterService.new(ii)
		var a = _TornadoAdapter.new(["C01"], fail_stage)
		var start = ww.scrub_bucks()
		var rr = ss.apply_tornado(a, "C01")
		_ok(not rr["ok"], "tornado fails at stage %d" % fail_stage)
		_ok(a.rolled_back_count == fail_stage, "stage %d: %d prior stages rolled back" % [fail_stage, fail_stage])
		_ok(ww.scrub_bucks() == start, "stage %d: no charge on rollback" % fail_stage)
		_ok(a.net_applied() == 0, "stage %d: no net system mutation after rollback" % fail_stage)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 Phase C evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

# ----------------------------------------------------------- fake adapters ----

class _RandomAdapter:
	var _safe: bool
	var _commit_ok: bool
	var committed := false
	var rolled_back := false
	func _init(safe: bool, commit_ok: bool) -> void:
		_safe = safe
		_commit_ok = commit_ok
	func propose_random_reorder() -> Dictionary:
		return {
			"safe": _safe,
			"commit": func():
				if _commit_ok:
					committed = true
					return true
				return false,
			"rollback": func(): rolled_back = true,
		}

class _SelectorAdapter:
	var _eligible: Array
	var _extract_ok: bool
	var extracted := ""
	var rolled_back := false
	func _init(eligible: Array, extract_ok: bool) -> void:
		_eligible = eligible
		_extract_ok = extract_ok
	func eligible_safe_batches() -> Array:
		return _eligible
	func extract_batch(batch_id) -> Dictionary:
		return {
			"apply": func():
				if _extract_ok:
					extracted = batch_id
					return true
				return false,
			"rollback": func(): rolled_back = true,
		}

## Models the 5-system tornado reconciliation (supply/slots/claims/agents/solver).
## `fail_at` is the stage index that fails (-1 = all succeed).
## Per-stage `_applied` flag: rollback only decrements when its own apply ran, so
## the V03 failing-stage rollback on a non-mutating stage is a safe no-op.
class _TornadoAdapter:
	var _colors: Array
	var _fail_at: int
	var _applied: Array = [false, false, false, false, false]
	var applied_count := 0
	var rolled_back_count := 0
	func _init(colors: Array, fail_at: int) -> void:
		_colors = colors
		_fail_at = fail_at
	func present_colors() -> Array:
		return _colors
	func net_applied() -> int:
		return applied_count - rolled_back_count
	func tornado_stages(_color) -> Array:
		var stages: Array = []
		for i in range(5):
			var idx := i
			stages.append({
				"apply": func():
					if idx == _fail_at:
						return false
					_applied[idx] = true
					applied_count += 1
					return true,
				"rollback": func():
					if _applied[idx]:
						_applied[idx] = false
						rolled_back_count += 1,
			})
		return stages
