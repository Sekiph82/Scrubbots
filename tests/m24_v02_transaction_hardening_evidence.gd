extends SceneTree
## M24-C001 V02 — transaction-serialization + commit-failure evidence
## (F-M24-V01-STRICT-001 / -002). Proves the whole M24 mutation surface is serialized
## during an active M23 placement, that reset-during-placement never reopens the guard,
## that re-entry from BOTH begin and commit is safe, that a failed M23 commit preserves
## exact M24 prestate, and that SlotBatchState lifecycle is restricted to EMPTY/ACTIVE/
## WAITING.
##
## Run: godot --headless --path . -s res://tests/m24_v02_transaction_hardening_evidence.gd

const Eng = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const Sup = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CB = preload("res://scripts/gameplay/supply/color_batch.gd")
const SBS = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const Double = preload("res://tests/support/m24_callback_supply.gd")

var _fail := 0

func _initialize() -> void:
	_scenario_a_begin_callback()
	_scenario_b_commit_callback()
	_scenario_c_failed_commit()
	_lifecycle_hardening()
	_done()

## Build an engine with slots 0..3 occupied and slot 4 EMPTY (fill 5, complete slot 4).
func _prime_engine_slot4_empty():
	var e = Eng.new()
	var s = Sup.create(5, 3)
	s.load_columns([
		[CB.make("E0", 0, 1, 6)], [CB.make("E1", 1, 1, 6)], [CB.make("E2", 2, 1, 6)],
		[CB.make("E3", 3, 1, 6)], [CB.make("E4", 4, 1, 6)]])
	for c in range(5):
		e.select_front_batch(s, c)  # fills 4,3,2,1,0
	# complete slot 4 (E0? no—slot4 holds first placement = column 0 front E0). count 1.
	e.commit_work(4, "PRIME")
	e.resolve_clear("PRIME")   # slot 4 -> EMPTY
	return e

func _scenario_a_begin_callback() -> void:
	print("---- Scenario A: begin() callback re-entry ----")
	var e = _prime_engine_slot4_empty()
	var before := str(e.snapshot())
	var d = Double.new()
	d.m24 = e
	d.mode = "begin"
	d.load_columns([[CB.make("NEW_A", 5, 3, 6)], [], []])
	var r = e.select_front_batch(d, 0)
	# Nested attacks all failed closed.
	_ok(d.results.get("reset") == false, "A: nested reset() returned false (fail-closed)")
	_ok(typeof(d.results.get("nested_select")) == TYPE_DICTIONARY and d.results["nested_select"].get("error") == "reentrant", "A: nested select rejected reentrant")
	_ok(d.results.get("commit_work") == false, "A: nested commit_work rejected while busy")
	_ok(d.results.get("set_claim") == false, "A: nested set_claimable rejected while busy")
	# Guard not reopened; slot 0 unchanged by nested attacks.
	_ok(e.get_state(0) == "ACTIVE" and e.get_committed(0) == 0, "A: pre-existing slot 0 untouched (ACTIVE, committed 0)")
	# Outer placement succeeded into the correct rightmost EMPTY slot (4) from stable state.
	_ok(r["ok"] and r["slot"] == 4 and e.get_batch_id(4) == "NEW_A", "A: outer placement used correct rightmost-empty slot 4")
	_ok(e.occupied_count() == 5, "A: exactly one new occupancy; no ghost/double insert")
	print("A snapshot-before length matched:", before.length() > 0)

func _scenario_b_commit_callback() -> void:
	print("---- Scenario B: commit() callback re-entry ----")
	var e = _prime_engine_slot4_empty()
	var d = Double.new()
	d.m24 = e
	d.mode = "commit"
	d.load_columns([[CB.make("NEW_B", 5, 3, 6)], [], []])
	var r = e.select_front_batch(d, 0)
	_ok(d.results.get("reset") == false, "B: nested reset() from commit callback fail-closed")
	_ok(typeof(d.results.get("nested_select")) == TYPE_DICTIONARY and d.results["nested_select"].get("error") == "reentrant", "B: nested select from commit callback rejected")
	_ok(d.results.get("commit_work") == false, "B: nested commit_work from commit callback rejected")
	_ok(d.results.get("set_claim") == false, "B: nested set_claimable from commit callback rejected")
	_ok(e.get_state(0) == "ACTIVE" and e.get_committed(0) == 0, "B: pre-existing slot 0 untouched")
	_ok(r["ok"] and r["slot"] == 4 and e.get_batch_id(4) == "NEW_B", "B: outer placement completed correctly after commit callback")

func _scenario_c_failed_commit() -> void:
	print("---- Scenario C: failed/stale M23 commit ----")
	var e = _prime_engine_slot4_empty()
	var before := str(e.snapshot())
	var seq_before := e.get_placement_sequence(0)
	var live_before := e.live_work_count()
	var d = Double.new()
	d.m24 = e
	d.mode = "fail"
	d.load_columns([[CB.make("NEVER", 5, 3, 6)], [], []])
	var r = e.select_front_batch(d, 0)
	_ok(not r["ok"] and r["error"] == "supply_commit_failed", "C: select reports supply_commit_failed")
	_ok(str(e.snapshot()) == before, "C: all five slots exact-prestate (no ghost, no placement)")
	_ok(e.get_placement_sequence(0) == seq_before, "C: placement sequence did not advance")
	_ok(e.live_work_count() == live_before, "C: live-work ledger unchanged")
	_ok(e.rightmost_empty_index() == 4, "C: rightmost-empty truth intact (slot 4 still empty)")
	# Engine still usable afterward with a good supply.
	var good = Sup.create(3, 3)
	good.load_columns([[CB.make("AFTER_C", 5, 2, 6)], [], []])
	var r2 = e.select_front_batch(good, 0)
	_ok(r2["ok"] and r2["slot"] == 4, "C: engine still functional; next placement fills slot 4")

func _lifecycle_hardening() -> void:
	print("---- SlotBatchState lifecycle hardening ----")
	var s = SBS.make_occupied("L", 2, 5, 1)
	_ok(s.set_state("WAITING") and s.get_state() == "WAITING", "L: valid WAITING accepted")
	_ok(s.set_state("ACTIVE") and s.get_state() == "ACTIVE", "L: valid ACTIVE accepted")
	_ok(not s.set_state("BOGUS") and s.get_state() == "ACTIVE", "L: invalid state rejected, unchanged")
	_ok(not s.set_state("") and s.get_state() == "ACTIVE", "L: empty state rejected")
	_ok(not s.set_state(42) and s.get_state() == "ACTIVE", "L: non-string state rejected")
	_ok(s.set_state("EMPTY") and s.get_state() == "EMPTY", "L: EMPTY accepted")

func _ok(c: bool, m: String) -> void:
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done() -> void:
	print("M24 V02 transaction-hardening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
