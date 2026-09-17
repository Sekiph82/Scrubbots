extends SceneTree
## M24-C001 V01 — canonical BLUE 8 / BLUE 14 / BLUE 12 fixture (SB-M24-028). Three
## distinct same-color batches fed through the real M23 transactional front-selection
## path occupy three distinct slots and evolve independently. No merge/pool/reorder.
## Slot/accounting only — no target pixels assigned (that is M25).
##
## Run: godot --headless --path . -s res://tests/m24_blue_fixture_evidence.gd

const Eng = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const Sup = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const CB = preload("res://scripts/gameplay/supply/color_batch.gd")

const BLUE := 3   # canonical integer palette color id (same for all three batches)

var _fail := 0

func _initialize() -> void:
	var e = Eng.new()
	var s = Sup.create(3, 3)
	s.load_columns([
		[CB.make("BLUE_8", BLUE, 8, 16)],
		[CB.make("BLUE_14", BLUE, 14, 16)],
		[CB.make("BLUE_12", BLUE, 12, 16)]])
	var r0 := e.select_front_batch(s, 0)
	var r1 := e.select_front_batch(s, 1)
	var r2 := e.select_front_batch(s, 2)
	print("BLUE_8 ->", r0["slot"], " BLUE_14 ->", r1["slot"], " BLUE_12 ->", r2["slot"])
	_ok(r0["slot"] == 4 and r1["slot"] == 3 and r2["slot"] == 2, "deterministic rightmost-empty: slots 4,3,2")
	_ok(e.get_batch_id(4) == "BLUE_8" and e.get_batch_id(3) == "BLUE_14" and e.get_batch_id(2) == "BLUE_12", "distinct batch identities")
	_ok(e.get_color_id(4) == BLUE and e.get_color_id(3) == BLUE and e.get_color_id(2) == BLUE, "all same color, three slots (no color collapse)")
	_ok(e.get_initial_count(4) == 8 and e.get_initial_count(3) == 14 and e.get_initial_count(2) == 12, "independent initial counts 8/14/12")

	# Independent evolution: work on BLUE_14 (slot 3) only.
	_ok(e.commit_work(3, "BW1") and e.commit_work(3, "BW2"), "commit two work units on BLUE_14")
	_ok(e.resolve_clear("BW1"), "resolve one on BLUE_14")
	_ok(e.get_remaining(3) == 13 and e.get_committed(3) == 1, "BLUE_14 evolves independently (rem 13, committed 1)")
	_ok(e.get_remaining(4) == 8 and e.get_committed(4) == 0, "BLUE_8 untouched")
	_ok(e.get_remaining(2) == 12 and e.get_committed(2) == 0, "BLUE_12 untouched")

	# Detached query cannot cross-mutate siblings.
	var snap = e.snapshot()
	snap[4]["initial_count"] = 1
	snap[2]["remaining_to_clear"] = 0
	_ok(e.get_initial_count(4) == 8 and e.get_remaining(2) == 12, "detached queries cannot cross-mutate siblings")

	_done()

func _ok(c: bool, m: String) -> void:
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done() -> void:
	print("M24 BLUE 8/14/12 fixture evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
