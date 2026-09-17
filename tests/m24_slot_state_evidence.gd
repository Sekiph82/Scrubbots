extends SceneTree
## M24-C001 V01 — slot-state + lifecycle/accounting evidence. Gameplay-domain only.
## Proves five EMPTY initial slots, rightmost-empty placement with no shifting,
## duplicate-color independence, detached queries, counter invariants, the committed
## work ledger (commit/resolve/rollback), WAITING/ACTIVE, and true completion/freeing.
##
## Run: godot --headless --path . -s res://tests/m24_slot_state_evidence.gd

const Eng = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const Sup = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CB = preload("res://scripts/gameplay/supply/color_batch.gd")

var _fail := 0

func _initialize() -> void:
	var e = Eng.new()
	# Five EMPTY.
	var empty := e.get_slot_count() == 5
	for i in range(5):
		if not e.is_empty(i) or e.get_state(i) != "EMPTY":
			empty = false
	_ok(empty, "five slots exist and all start EMPTY")
	_ok(Eng.SLOT_COUNT == 5, "slot count is a locked constant")

	# Placement fills rightmost-empty; occupied never shift.
	var s = Sup.create(5, 3)
	s.load_columns([
		[CB.make("P0", 0, 2, 8)], [CB.make("P1", 1, 2, 8)], [CB.make("P2", 2, 2, 8)],
		[CB.make("P3", 3, 2, 8)], [CB.make("P4", 4, 2, 8)]])
	var order := []
	for c in range(3):
		order.append(e.select_front_batch(s, c)["slot"])
	print("M24 placement order (3 fills):", order)
	_ok(order == [4, 3, 2], "rightmost-empty placement 4,3,2")
	_ok(e.is_empty(0) and e.is_empty(1) and e.is_occupied(2) and e.is_occupied(3) and e.is_occupied(4), "holes 0,1 remain; no shifting")

	# Detached snapshot isolation.
	var snap = e.snapshot()
	snap[4]["remaining_to_clear"] = -999
	_ok(e.get_remaining(4) == 2, "snapshot mutation cannot mutate engine")

	# Invariant + accounting ledger on slot 4 (count 2).
	_ok(e.commit_work(4, "W1") and e.commit_work(4, "W2"), "commit to capacity")
	_ok(not e.commit_work(4, "W3"), "over-commit rejected")
	_ok(e.get_committed(4) == 2 and e.get_remaining(4) == 2 and e.get_capacity(4) == 0, "0<=committed<=remaining<=initial; capacity 0")
	_ok(e.rollback_work("W2"), "rollback one")
	_ok(e.get_committed(4) == 1 and e.get_remaining(4) == 2, "rollback lowers only committed")
	_ok(e.resolve_clear("W1"), "resolve one")
	_ok(e.get_committed(4) == 0 and e.get_remaining(4) == 1, "resolve lowers committed AND remaining")

	# WAITING/ACTIVE.
	_ok(e.set_claimable_work_available(4, false) and e.get_state(4) == "WAITING", "ACTIVE->WAITING on no claimable work")
	_ok(e.set_claimable_work_available(4, true) and e.get_state(4) == "ACTIVE", "WAITING->ACTIVE on authoritative availability")

	# True completion frees exactly this slot; neighbors unchanged.
	var seq3 := e.get_placement_sequence(3)
	_ok(e.commit_work(4, "W4") and e.resolve_clear("W4"), "resolve final unit")
	_ok(e.is_empty(4) and e.get_state(4) == "EMPTY", "slot freed to EMPTY at remaining==0 && committed==0")
	_ok(e.get_placement_sequence(3) == seq3 and e.is_occupied(3) and e.is_occupied(2), "neighbors did not shift after free")

	# Duplicate colors independent.
	var e2 = Eng.new()
	var s2 = Sup.create(3, 3)
	s2.load_columns([[CB.make("G8", 3, 8, 16)], [CB.make("G9", 3, 9, 16)], [CB.make("G7", 3, 7, 16)]])
	e2.select_front_batch(s2, 0); e2.select_front_batch(s2, 1); e2.select_front_batch(s2, 2)
	_ok(e2.get_color_id(4) == 3 and e2.get_color_id(3) == 3 and e2.get_color_id(2) == 3, "same color in three slots")
	_ok(e2.get_initial_count(4) == 8 and e2.get_initial_count(3) == 9 and e2.get_initial_count(2) == 7, "independent counts, no merge/pool")

	_done()

func _ok(c: bool, m: String) -> void:
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done() -> void:
	print("M24 slot-state evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
