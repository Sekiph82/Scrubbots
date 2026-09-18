extends SceneTree
## M27-C001 V01 — 59x59 solver scale/performance evidence (SB-M27-024 / master audit §M).
## Deterministic, headless. Proves the proof engine runs a real 59x59 board (production cell
## ceiling, 3481 cells) with a BOUNDED search and a compact canonical state key — no
## unbounded search, no rendered-pixel snapshots in the key.
##
## Two fixtures:
##   (1) SOLVABLE within bound: a real ring-enclosure region on a 59x59 board proven SOLVED,
##       reporting visited / memo hits / frontier peak / elapsed / canonical key size.
##   (2) A DELIBERATELY bounded stress fixture that returns UNKNOWN_BOUND (a valid proof
##       outcome for an intentionally bounded stress, NEVER production acceptance, NEVER
##       mislabeled DEADLOCK).
##
## Run: godot --headless --path . -s res://tests/m27_scale_59.gd  (exit 0 on success)

const LevelData = preload("res://scripts/data/level_data.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const N := 59

var _fail := 0

func _pal(n: int) -> PackedStringArray:
	var p := PackedStringArray()
	for i in range(n):
		p.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	return p

## A 59x59 LevelData whose colors form a `size`x`size` ring-enclosure block anchored at
## (ox,oy): ring = gate color, interior = inner color; everything else color0 (kept CLEARED
## by the active mask). Returns [level, active_mask, gate_count, inner_count].
func _ring_region(size: int, ox: int, oy: int, inner: int, gate: int) -> Array:
	var cells := PackedInt32Array(); cells.resize(N * N); cells.fill(0)
	var active := PackedByteArray(); active.resize(N * N); active.fill(ProofState.CLEARED_BYTE)
	var gc := 0
	var ic := 0
	for ry in range(size):
		for rx in range(size):
			var idx: int = (oy + ry) * N + (ox + rx)
			var is_ring: bool = (rx == 0 or ry == 0 or rx == size - 1 or ry == size - 1)
			cells[idx] = gate if is_ring else inner
			active[idx] = ProofState.ACTIVE_BYTE
			if is_ring: gc += 1
			else: ic += 1
	var lvl = LevelData.new(1, "m27_59", "m27_59", "TEST", N, N, _pal(4), cells)
	return [lvl, active, gc, ic]

func _state(lvl, active: PackedByteArray, cols_spec: Array):
	var e = BatchSupplyEngine.create(3, 3)
	var cols: Array = []
	var gi := 0
	for spec in cols_spec:
		var q: Array = []
		for cc in spec:
			q.append(ColorBatch.make("S%03d" % gi, cc[0], cc[1], 4)); gi += 1
		cols.append(q)
	e.load_columns(cols)
	var s = ProofState.from_level_and_supply(lvl, e)
	s.active = active.duplicate()
	return s

func _initialize() -> void:
	var solver = SolvabilitySolver.new()

	# (1) Solvable ring region on a 59x59 board. 7x7 ring: gate=24, interior 5x5=25.
	var rr = _ring_region(7, 3, 3, 0, 1)
	var lvl = rr[0]; var active = rr[1]; var gate_n = rr[2]; var inner_n = rr[3]
	var s1 = _state(lvl, active, [[[1, gate_n]], [[0, inner_n]], []])
	var key_len: int = s1.canonical_key().length()
	var active0: int = s1.active_count()
	var t0 := Time.get_ticks_msec()
	var r: Dictionary = solver.solve(s1, {"max_visited": 100000, "max_depth": 200})
	var ms := Time.get_ticks_msec() - t0
	print("SCALE59_SOLVE board=%dx%d cells=%d active=%d status=%s decisions=%d visited=%d memo_hits=%d frontier_peak=%d elapsed_ms=%d key_bytes=%d trace_hash=%d" % [
		N, N, N * N, active0, r["status"], int(r["decisions"]), int(r["visited"]), int(r["memo_hits"]),
		int(r["frontier_peak"]), ms, key_len, int(r.get("trace_hash", 0))])
	_ok(r["status"] == SolvabilitySolver.SOLVED, "59x59 ring-enclosure region proven SOLVED within bound")
	_ok(key_len <= N * N + 256, "canonical state key is compact (~cell-count bytes, no pixel/scene snapshot): %d bytes" % key_len)
	var rep: Dictionary = solver.replay(s1, r["trace"])
	_ok(rep["ok"] and rep["solved"], "59x59 solution replays to completion")

	# (2) Deliberately bounded stress -> UNKNOWN_BOUND (never DEADLOCK). A larger 11x11 ring
	# region with a many-batch supply, capped at a tiny visited bound.
	var rr2 = _ring_region(11, 20, 20, 0, 1)
	var lvl2 = rr2[0]; var active2 = rr2[1]; var gate2 = rr2[2]; var inner2 = rr2[3]
	# Split into several batches so the search has real breadth, then bound it hard.
	var s2 = _state(lvl2, active2, [
		[[1, gate2 / 2], [1, gate2 - gate2 / 2]],
		[[0, inner2 / 2], [0, inner2 - inner2 / 2]], []])
	var t1 := Time.get_ticks_msec()
	var r2: Dictionary = solver.solve(s2, {"max_visited": 3, "max_depth": 200})
	var ms2 := Time.get_ticks_msec() - t1
	print("SCALE59_STRESS active=%d status=%s visited=%d memo_hits=%d frontier_peak=%d elapsed_ms=%d reason=%s" % [
		s2.active_count(), r2["status"], int(r2["visited"]), int(r2["memo_hits"]), int(r2["frontier_peak"]), ms2, r2["reason"]])
	_ok(r2["status"] == SolvabilitySolver.UNKNOWN_BOUND, "deliberately bounded 59x59 stress returns UNKNOWN_BOUND")
	_ok(r2["status"] != SolvabilitySolver.DEADLOCK, "bounded stress is NEVER mislabeled DEADLOCK")
	_ok(int(r2["visited"]) <= 4, "bounded search stopped promptly at the state-count bound (no unbounded search)")

	_done()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M27 59x59 scale: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
