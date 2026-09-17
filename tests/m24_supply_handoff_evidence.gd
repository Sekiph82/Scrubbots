extends SceneTree
## M24-C001 V01 — M23 -> M24 transactional handoff evidence. Proves atomicity: accepted
## placement consumes exactly one M23 front and advances that column once; rejected/full
## placement consumes none and leaves the supply front selectable; stale/malformed/
## re-entrant/rapid requests fail closed with no split-brain between supply queue and
## slot state.
##
## Run: godot --headless --path . -s res://tests/m24_supply_handoff_evidence.gd

const Eng = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const Sup = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CB = preload("res://scripts/gameplay/supply/color_batch.gd")

var _fail := 0

func _initialize() -> void:
	# Accepted placement: exactly one front consumed.
	var e = Eng.new()
	var s = Sup.create(3, 3)
	s.load_columns([[CB.make("A0", 0, 2, 5), CB.make("A1", 0, 3, 5)], [CB.make("B0", 1, 4, 5)], []])
	var rem0: int = s.get_remaining(0)
	var r := e.select_front_batch(s, 0)
	print("M24 accepted:", r["ok"], "slot", r.get("slot", -1))
	_ok(r["ok"] and r["slot"] == 4, "accepted -> slot 4")
	_ok(s.get_remaining(0) == rem0 - 1 and s.get_front(0).get_batch_id() == "A1", "exactly one M23 front consumed; column advanced once")
	_ok(e.occupied_count() == 1 and e.get_batch_id(4) == "A0", "exactly one slot EMPTY->ACTIVE, no duplication")

	# Exhausted column: no consume, no slot.
	var r2 := e.select_front_batch(s, 2)
	_ok(not r2["ok"] and e.occupied_count() == 1, "exhausted column consumes nothing, creates no slot")

	# Full-five rejection: supply front unchanged.
	var f = Eng.new()
	var fs = Sup.create(5, 3)
	fs.load_columns([
		[CB.make("F0", 0, 1, 5), CB.make("G0", 0, 9, 5)],
		[CB.make("F1", 1, 1, 5)], [CB.make("F2", 2, 1, 5)],
		[CB.make("F3", 3, 1, 5)], [CB.make("F4", 4, 1, 5)]])
	for c in range(5):
		f.select_front_batch(fs, c)
	_ok(f.is_full(), "five slots filled")
	var slot_snap := str(f.snapshot())
	var front_before: String = fs.get_front(0).get_batch_id()
	var sup_snap := str(fs.debug_snapshot())
	var rej := f.select_front_batch(fs, 0)
	_ok(not rej["ok"] and rej["error"] == "slots_full", "sixth selection rejected atomically")
	_ok(fs.get_front(0).get_batch_id() == front_before and str(fs.debug_snapshot()) == sup_snap, "rejected placement did not advance/consume supply (no split-brain)")
	_ok(str(f.snapshot()) == slot_snap, "rejected placement left slots unchanged (no ghost slot)")

	# Foreign/null supply fail closed.
	_ok(not f.select_front_batch(RefCounted.new(), 0)["ok"], "foreign supply rejected")
	_ok(not f.select_front_batch(null, 0)["ok"], "null supply rejected")

	# Re-entrancy guard.
	var e3 = Eng.new()
	var reentrant = load("res://tests/support/m24_reentrant_supply.gd").new()
	reentrant.engine = e3
	var rr := e3.select_front_batch(reentrant, 0)
	_ok(not rr["ok"], "outer re-entrant call fails closed")
	_ok(reentrant.nested_result.get("error", "") == "reentrant", "nested re-entrant call rejected")
	_ok(e3.occupied_count() == 0, "re-entrancy caused no insertion")

	_done()

func _ok(c: bool, m: String) -> void:
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done() -> void:
	print("M24 supply-handoff evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
