extends SceneTree
## M24-C001 V01 — five-full -> reject -> complete -> refill cycle (SB-M24-029). Drives
## the full end-to-end state machine through the real M23 -> M24 path: fill five slots,
## reject the sixth with exact state preservation, complete one slot to EMPTY without
## shifting neighbors, then refill the freed hole with the previously rejected front,
## advancing the originating supply column exactly once.
##
## Run: godot --headless --path . -s res://tests/m24_five_full_refill_evidence.gd

const Eng = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const Sup = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CB = preload("res://scripts/gameplay/supply/color_batch.gd")

var _fail := 0

func _initialize() -> void:
	var e = Eng.new()
	var s = Sup.create(5, 3)
	# Column 0 has a second batch (G0) behind F0 for the refill; count 1 batches complete fast.
	s.load_columns([
		[CB.make("F0", 0, 1, 5), CB.make("G0", 0, 3, 5)],
		[CB.make("F1", 1, 1, 5)], [CB.make("F2", 2, 2, 5)],
		[CB.make("F3", 3, 1, 5)], [CB.make("F4", 4, 1, 5)]])

	# 1-2: fill all five slots.
	var order := []
	for c in range(5):
		order.append(e.select_front_batch(s, c)["slot"])
	print("fill order:", order)
	_ok(order == [4, 3, 2, 1, 0], "five front selections fill 4,3,2,1,0")
	_ok(e.is_full(), "engine full")

	# 3-5: snapshot; sixth selection rejected; state preserved; sixth batch still front.
	var slot_snap := str(e.snapshot())
	var sup_snap := str(s.debug_snapshot())
	var g0_front: String = s.get_front(0).get_batch_id()
	var rej := e.select_front_batch(s, 0)
	_ok(not rej["ok"] and rej["error"] == "slots_full", "sixth selection rejected")
	_ok(str(e.snapshot()) == slot_snap, "slot state exactly preserved on rejection")
	_ok(str(s.debug_snapshot()) == sup_snap and s.get_front(0).get_batch_id() == g0_front, "supply exactly preserved; G0 still front")

	# 6-8: complete slot 2 (F2, count 2) via legitimate committed-work accounting.
	_ok(e.commit_work(2, "K1") and e.commit_work(2, "K2"), "commit F2's two work units")
	_ok(not e.is_empty(2), "F2 not freed while work outstanding")
	_ok(e.resolve_clear("K1"), "resolve first F2 unit")
	_ok(e.get_remaining(2) == 1 and not e.is_empty(2), "F2 not freed while remaining>0")
	_ok(e.resolve_clear("K2"), "resolve final F2 unit")
	_ok(e.is_empty(2) and e.get_state(2) == "EMPTY", "slot 2 becomes EMPTY at completion")
	_ok(e.is_occupied(0) and e.is_occupied(1) and e.is_occupied(3) and e.is_occupied(4), "neighbors did not shift")

	# 9-11: retry the previously rejected front; fills the rightmost EMPTY hole (2);
	# originating column advances exactly once.
	_ok(e.rightmost_empty_index() == 2, "rightmost empty is the freed hole (2)")
	var g0_rem: int = s.get_remaining(0)
	var refill := e.select_front_batch(s, 0)
	_ok(refill["ok"] and refill["slot"] == 2 and e.get_batch_id(2) == "G0", "refill fills freed hole with G0")
	_ok(s.get_remaining(0) == g0_rem - 1, "originating column advanced exactly once on successful retry")

	# 12: invariants still hold everywhere.
	var inv := true
	for i in range(5):
		if e.is_occupied(i):
			var c: int = e.get_committed(i)
			var rc: int = e.get_remaining(i)
			var ic: int = e.get_initial_count(i)
			if not (0 <= c and c <= rc and rc <= ic):
				inv = false
	_ok(inv, "all slot invariants hold after full cycle")
	_ok(e.is_full(), "engine full again after refill")

	_done()

func _ok(c: bool, m: String) -> void:
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done() -> void:
	print("M24 five-full/refill evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
