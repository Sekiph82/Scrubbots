extends SceneTree
## M23-C001 V02 — Batch Supply hardening evidence (F-M23-V01-STRICT-001..005).
## Gameplay-domain only. Prints a compact structured trace proving, directly:
##   001 a forged real-class BatchSelectionTransaction carrying a LIVE token id cannot
##       commit/cancel/redirect a legitimate open transaction;
##   002 a real but corrupted/blank ColorBatch is rejected at the load boundary and the
##       prior candidate is preserved;
##   003 reset() restores queue + seed + palette after metadata mutation, and pre-reset
##       transactions become invalid;
##   004 malformed/foreign LevelData fails closed (no candidate, no runtime error);
##   005 the real 59x59 fixture conserves EVERY source color total exactly.
##
## Run: godot --headless --path . -s res://tests/m23_v02_hardening_evidence.gd
## Exits 0 on success, 1 on any failure.

const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const BatchSelectionTransaction = preload("res://scripts/gameplay/supply/batch_selection_transaction.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

var _fail := 0

func _initialize() -> void:
	_f001_forged_transaction()
	_f002_malformed_load()
	_f003_reset_truth()
	_f004_malformed_leveldata()
	_f005_59x59_per_color()
	_done()

# --- F-001 ---------------------------------------------------------------------
func _f001_forged_transaction() -> void:
	print("---- F-001 forged transaction identity ----")
	var e = BatchSupplyEngine.create(3, 3)
	e.load_columns([
		[ColorBatch.make("A0", 0, 1, 5), ColorBatch.make("A1", 0, 2, 5)],
		[ColorBatch.make("B0", 1, 1, 5), ColorBatch.make("B1", 1, 2, 5)],
		[ColorBatch.make("C0", 2, 1, 5)],
	])
	var before := str(e.debug_snapshot())
	var a = e.begin_front_selection(0)
	var b = e.begin_front_selection(1)
	var forged = BatchSelectionTransaction.new(a.get_token_id(), a.get_column(), a.get_front_batch_id(), a.get_front_batch())
	print("F001 A.token=%d B.token=%d forged.token=%d (same as A)" % [a.get_token_id(), b.get_token_id(), forged.get_token_id()])
	_ok(not e.commit(forged), "forged same-class object with A's live id cannot commit")
	_ok(not e.cancel(forged), "forged object cannot cancel A")
	_ok(not e.has_open_transaction(forged), "forged object not reported as owning A")
	_ok(e.has_open_transaction(a), "legitimate A still open")
	_ok(str(e.debug_snapshot()) == before, "no column mutated by forged commit/cancel")
	# redirect via field mutation
	a._token_id = b.get_token_id()
	a._column = b.get_column()
	_ok(not e.commit(a), "field-mutated A cannot redirect to B (identity mismatch)")
	_ok(str(e.debug_snapshot()) == before, "redirect attempt changed nothing")
	_ok(e.commit(b), "original B still commits after all attacks")
	print("F001 after B commit: col1 front=%s col0 front=%s" % [e.get_front(1).get_batch_id(), e.get_front(0).get_batch_id()])
	_ok(e.get_front(1).get_batch_id() == "B1" and e.get_front(0).get_batch_id() == "A0", "B advanced one; column 0 untouched")

# --- F-002 ---------------------------------------------------------------------
func _f002_malformed_load() -> void:
	print("---- F-002 malformed ColorBatch load boundary ----")
	var e = BatchSupplyEngine.create(3, 3)
	e.load_candidate([[ColorBatch.make("G0", 0, 3, 5)], [], []], 1, 5)
	var good := str(e.debug_snapshot())
	var raw = ColorBatch.new()
	_ok(not e.load_columns([[raw], [], []]), "blank directly-instantiated ColorBatch rejected")
	var neg = ColorBatch.make("H0", 0, 3, 5); neg._color_id = -7
	_ok(not e.load_columns([[neg], [], []]), "post-hoc negative color_id rejected")
	var zero = ColorBatch.make("H1", 0, 3, 5); zero._robot_count = 0
	_ok(not e.load_columns([[zero], [], []]), "post-hoc zero robot_count rejected")
	var emptyid = ColorBatch.make("H2", 0, 3, 5); emptyid._batch_id = ""
	_ok(not e.load_columns([[emptyid], [], []]), "post-hoc empty batch_id rejected")
	_ok(not e.load_candidate([[ColorBatch.make("H3", 4, 3, 5)], [], []], 1, 3), "color_id >= known palette size rejected")
	_ok(str(e.debug_snapshot()) == good, "prior candidate preserved after every failed load")

# --- F-003 ---------------------------------------------------------------------
func _f003_reset_truth() -> void:
	print("---- F-003 reset restores queue + seed + palette ----")
	var lvl = _level(4, 4, [0,0,0, 1,1, 2,2,2,2, 3,3,3, 4,4,4,4], 5)
	var e = BatchSupplyGenerator.generate(lvl, 3, 3, 7)
	var initial := str(e.debug_snapshot())
	print("F003 committed seed=%d palette=%d" % [e.get_seed(), e.get_palette_size()])
	e.set_seed(999999); e.set_palette_size(2)
	e.commit(e.begin_front_selection(0))
	var stale = e.begin_front_selection(1)
	print("F003 after mutate+commit seed=%d palette=%d" % [e.get_seed(), e.get_palette_size()])
	e.reset()
	print("F003 after reset seed=%d palette=%d" % [e.get_seed(), e.get_palette_size()])
	_ok(str(e.debug_snapshot()) == initial, "reset restores exact queue + seed + palette snapshot")
	_ok(e.get_seed() == 7 and e.get_palette_size() == 5, "reset restored original metadata")
	_ok(not e.commit(stale), "pre-reset transaction invalid after reset")

# --- F-004 ---------------------------------------------------------------------
func _f004_malformed_leveldata() -> void:
	print("---- F-004 strict LevelData validation ----")
	_ok(BatchSupplyGenerator.color_totals(null).is_empty(), "null -> {}")
	_ok(BatchSupplyGenerator.color_totals(RefCounted.new()).is_empty(), "foreign RefCounted -> {}")
	_ok(BatchSupplyGenerator.generate(RefCounted.new(), 3, 3, 1) == null, "foreign source generate -> null")
	var nopal = LevelData.new(1, "x", "x", "TEST", 2, 2, PackedStringArray(), PackedInt32Array([0,0,0,0]))
	_ok(BatchSupplyGenerator.color_totals(nopal).is_empty(), "empty palette -> {}")
	var oob = _level(2, 2, [0,1,5,0], 3)
	_ok(BatchSupplyGenerator.color_totals(oob).is_empty(), "out-of-range cell id -> {}")
	var mismatch = LevelData.new(1, "x", "x", "TEST", 4, 4, PackedStringArray(["#111","#222"]), PackedInt32Array([0,1,0]))
	_ok(BatchSupplyGenerator.color_totals(mismatch).is_empty(), "cells.size != get_cell_count() -> {}")
	_ok(BatchSupplyGenerator.generate(mismatch, 3, 3, 1) == null, "cell-count mismatch generate -> null")
	var zero = LevelData.new(1, "x", "x", "TEST", 0, 0, PackedStringArray(["#111"]), PackedInt32Array())
	_ok(BatchSupplyGenerator.color_totals(zero).is_empty(), "zero dimensions -> {}")
	var ok = BatchSupplyGenerator.generate(_level(3, 2, [0,1,2, 2,1,0], 3), 3, 3, 3)
	_ok(ok != null, "valid rectangular LevelData still generates")

# --- F-005 ---------------------------------------------------------------------
func _f005_59x59_per_color() -> void:
	print("---- F-005 direct 59x59 per-color conservation ----")
	var cells := []
	for i in range(59 * 59):
		cells.append(i % 3)
	var lvl = _level(59, 59, cells, 3)
	var src := BatchSupplyGenerator.color_totals(lvl)
	var t0 := Time.get_ticks_msec()
	var e = BatchSupplyGenerator.generate(lvl, 5, 3, 11)
	var e2 = BatchSupplyGenerator.generate(lvl, 5, 3, 11)
	var ms := Time.get_ticks_msec() - t0
	var gen := {}
	for q in e.debug_snapshot()["columns"]:
		for d in q:
			gen[d["color_id"]] = int(gen.get(d["color_id"], 0)) + int(d["robot_count"])
	print("M23_59x59_SOURCE %s" % str(src))
	print("M23_59x59_GENERATED %s" % str(gen))
	var per_color := src.size() == 3
	for c in src.keys():
		var eq: bool = int(gen.get(c, 0)) == int(src[c])
		print("  color %d: source=%d generated=%d %s" % [c, int(src[c]), int(gen.get(c,0)), "ok" if eq else "MISMATCH"])
		if not eq:
			per_color = false
	_ok(per_color, "each 59x59 source color total equals generated quota")
	_ok(str(e.debug_snapshot()) == str(e2.debug_snapshot()), "same seed reproduces identical 59x59 layout")
	print("M23_PERF 59x59 x2 generate = %d ms" % ms)

func _level(w: int, h: int, cells: Array, palette_size: int):
	var pal := PackedStringArray()
	for i in range(palette_size):
		pal.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	return LevelData.new(1, "m23v02", "m23v02", "TEST", w, h, pal, PackedInt32Array(cells))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M23 V02 hardening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
