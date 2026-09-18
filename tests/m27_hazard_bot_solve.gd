extends SceneTree
## M27-C001 V01 — REAL 20x20 Hazard Bot solvability proof + deterministic trace evidence
## (SB-M27-021 / SB-M27-022 / master audit §K). Headless, deterministic.
##
## Proves the real committed level res://data/levels/m21_level_001_hazard_bot.json has at
## least one solvable generated M23 batch/column layout under the accepted five-slot /
## front-only rules, using the M27 proof engine (real M23/M24/M25/routing semantics reused,
## never a simplified reachability model). Persists the deterministic solution trace, replays
## it to reproduce completion, and proves hidden future batches stay hidden through the
## player-facing M23 query surface even though the solver used the full internal queue.
##
## Run: godot --headless --path . -s res://tests/m27_hazard_bot_solve.gd
## Exits 0 on success, 1 on any failure. Writes the trace to
## user://m27_hazard_bot_solution_trace.json and prints it for the evidence artifact.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const GEN_SEED := 1
const COLUMN_COUNT := 3
const PREVIEW_DEPTH := 3

var _fail := 0

func _initialize() -> void:
	_run()
	_done()

func _run() -> void:
	var res = LevelLoader.load_from_path(LEVEL_PATH)
	_ok(res.is_ok(), "loaded real hazard bot level")
	if not res.is_ok():
		return
	var lvl = res.level_data
	_ok(lvl.width == 20 and lvl.height == 20, "hazard bot is the real 20x20 level (%dx%d)" % [lvl.width, lvl.height])

	# Exact per-color totals from the real level (conservation reference).
	var totals := BatchSupplyGenerator.color_totals(lvl)
	print("HB_TOTALS ", totals)

	# Deterministic generated candidate consistent with the exact per-color totals.
	var eng = BatchSupplyGenerator.generate(lvl, COLUMN_COUNT, PREVIEW_DEPTH, GEN_SEED)
	_ok(eng != null, "deterministic M23 candidate generated (seed=%d, cols=%d)" % [GEN_SEED, COLUMN_COUNT])
	# Conservation: candidate per-color totals == level per-color totals.
	var sums := {}
	var nbatches := 0
	for col in eng.debug_snapshot()["columns"]:
		for b in col:
			sums[int(b["color_id"])] = int(sums.get(int(b["color_id"]), 0)) + int(b["robot_count"])
			nbatches += 1
	_ok(sums == totals, "candidate supply respects EXACT per-color totals (conservation)")

	# Prove solvability.
	var ps = ProofState.from_level_and_supply(lvl, eng)
	var solver = SolvabilitySolver.new()
	var t0 := Time.get_ticks_msec()
	var r: Dictionary = solver.solve(ps, {"max_visited": 200000, "max_depth": 400})
	var elapsed := Time.get_ticks_msec() - t0
	_ok(r["status"] == SolvabilitySolver.SOLVED, "Hazard Bot proven SOLVED under five-slot/front-only rules")
	print("HB_SOLVE status=%s decisions=%d visited=%d memo_hits=%d frontier_peak=%d max_depth=%d elapsed_ms=%d trace_hash=%d" % [
		r["status"], int(r["decisions"]), int(r["visited"]), int(r["memo_hits"]),
		int(r["frontier_peak"]), int(r["max_depth_reached"]), elapsed, int(r["trace_hash"])])
	if r["status"] != SolvabilitySolver.SOLVED:
		return
	# Every decision is a legal front selection; every generated batch is consumed exactly
	# once (front-only, no hidden/preview-row selection).
	_ok(int(r["decisions"]) == nbatches, "solution consumed every batch via legal FRONT selections only (%d decisions == %d batches)" % [int(r["decisions"]), nbatches])
	print("HB_TRACE ", SolvabilitySolver._trace_summary(r["trace"]))

	# Persist the deterministic trace as an evidence artifact.
	var payload := {"level": lvl.id, "gen_seed": GEN_SEED, "column_count": COLUMN_COUNT,
		"preview_depth": PREVIEW_DEPTH, "color_totals": totals, "n_batches": nbatches,
		"status": String(r["status"]), "decisions": int(r["decisions"]),
		"visited": int(r["visited"]), "memo_hits": int(r["memo_hits"]),
		"frontier_peak": int(r["frontier_peak"]), "trace_hash": int(r["trace_hash"]),
		"trace_summary": r["trace_summary"], "trace": r["trace"]}
	var f = FileAccess.open("user://m27_hazard_bot_solution_trace.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "  ")); f.close()
		_ok(true, "solution trace persisted to user://m27_hazard_bot_solution_trace.json")

	# Replay the trace to reproduce completion deterministically.
	var rep: Dictionary = solver.replay(ps, r["trace"])
	_ok(rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0, "trace REPLAYS to full completion (final_active=%d)" % int(rep["final_active"]))
	# Determinism: a second independent solve reproduces the identical trace hash.
	var r2: Dictionary = solver.solve(ps, {"max_visited": 200000, "max_depth": 400})
	_ok(int(r2["trace_hash"]) == int(r["trace_hash"]) and int(r2["visited"]) == int(r["visited"]), "re-solve reproduces identical trace hash + visited (deterministic)")

	# Hidden future batches stay hidden through the player-facing M23 surface, even though the
	# solver used the full internal queue.
	var full_depths := []
	var any_hidden := false
	var snap: Array = eng.player_snapshot()
	for c in range(COLUMN_COUNT):
		var remaining: int = eng.get_remaining(c)
		full_depths.append(remaining)
		_ok(eng.get_preview(c).size() <= PREVIEW_DEPTH, "column %d player preview reveals at most preview_depth rows" % c)
		_ok(int(snap[c]["remaining"]) == remaining and snap[c]["preview"].size() <= PREVIEW_DEPTH, "column %d player snapshot hides depth beyond preview (count-only)" % c)
		if remaining > PREVIEW_DEPTH:
			any_hidden = true
	# The solver's ProofState held the FULL queue for at least one column that the player API
	# only exposes as a remaining count.
	_ok(any_hidden, "at least one column has hidden future batches beyond the player preview")
	var solver_saw_full := false
	for c in range(COLUMN_COUNT):
		if ps.supply[c].size() == eng.get_remaining(c) and ps.supply[c].size() > PREVIEW_DEPTH:
			solver_saw_full = true
	_ok(solver_saw_full, "solver internally knew the FULL hidden queue while the player API kept it hidden")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M27 Hazard Bot solvability: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
