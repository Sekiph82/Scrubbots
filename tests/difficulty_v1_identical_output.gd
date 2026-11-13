extends SceneTree
## SB-PERF-DIFF-2026-11-13 — Difficulty V1 / ProofKernel identical-output regression.
##
## The analyzer and kernel were optimized for speed; their output must stay byte-identical.
## For every level of a set this recomputes, on the same inputs:
##   - LevelDifficultyAnalyzerV1.measure() (every field except the volatile `timing`),
##   - LevelDifficultyAnalyzerV1.score(),
##   - a fresh ProofKernel replay of the same column path (clears, active_after, placed,
##     placed_slot and the ACTIVE mask after every step),
##   - for the anchor fixtures and Level 1, the SolvabilitySolver status / visited / trace / hash,
## serializes each through the canonical JSON authority (tools/m53_canonical_json.gd) and
## compares its SHA-256 with the golden digests committed in GOLDEN_FMT. The golden digests
## were written by this script from the unoptimized code (commit 5d19621c). A further case checks
## the verdict-only ProductionTargetAccess mode against the full route probe cell by cell.
##
## Sets: campaign (the 30 catalog levels; intended clicks, L1 its seed-1 solver trace),
## anchors (tests/fixtures/difficulty_anchors, solver trace), factory (two 56x56 Level
## Factory levels). CI runs the CI_ONLY subset; the full sets take ~15 min locally.
##
## Run:   godot --headless --path . -s res://tests/difficulty_v1_identical_output.gd [-- --sets=campaign,anchors,factory]
## Write: ... -- --write --sets=...   (only from code whose output is the reference)
## Debug: ... -- --dump=<absolute dir>   (writes every canonical record for diffing)
##        ... -- --only=<id>,<id>          (subset of the selected sets)

const Analyzer = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Canon = preload("res://tools/m53_canonical_json.gd")
const Anchors = preload("res://tools/build_difficulty_anchors.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")

## One golden file per set: golden_<set>.json.
const GOLDEN_FMT := "res://tests/fixtures/difficulty_v1_identical/golden_%s.json"
const FACTORY_DIR := "res://tests/fixtures/difficulty_v1_identical/factory"
const FACTORY := ["LF-000147", "LF-000148"]
## The default (CI) run: a fast subset (two campaign levels incl. Level 1's solver trace, two
## anchors) plus the verdict-only equivalence case. Full local run: --sets=campaign,anchors,factory.
const CI_SETS := ["campaign", "anchors"]
const CI_ONLY := ["m21_level_001_hazard_bot", "level_014_goose", "hard_maze8_24", "x_rings12q_r1_split_24"]
const EXPECTED := {"campaign": 30, "anchors": 24, "factory": 2}

var _fail := 0
var _cases := 0

func _initialize() -> void:
	var sets = null
	var write := false
	var dump := ""
	var only = null
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--sets="):
			sets = Array(s.substr(7).split(","))
		elif s == "--write":
			write = true
		elif s.begins_with("--dump="):
			dump = s.substr(7)
		elif s.begins_with("--only="):
			only = Array(s.substr(7).split(","))
	if only == null:
		only = CI_ONLY if sets == null else []
	if sets == null:
		sets = CI_SETS
	var an = Analyzer.new()
	_ok(an.is_ok(), "analyzer loads %s" % an.get_error())
	if not write:
		_verdict_equivalence()
	for set_name in sets:
		var levels: Dictionary = Analyzer._read_json(GOLDEN_FMT % set_name).get("levels", {})
		var inputs := _inputs(set_name)
		_ok(inputs.size() == int(EXPECTED.get(set_name, -1)) and (write or levels.size() == inputs.size()),
			"%s set has %d levels, %d golden records" % [set_name, inputs.size(), levels.size()])
		for inp in inputs:
			if not only.is_empty() and not only.has(inp["id"]):
				continue
			var key: String = "%s/%s" % [set_name, inp["id"]]
			var t0 := Time.get_ticks_msec()
			var rec := _record(an, inp)
			var dig := {}
			for part in rec:
				dig[part] = Canon.stringify(rec[part], "").sha256_text()
			if not dump.is_empty():
				DirAccess.make_dir_recursive_absolute(dump)
				var f := FileAccess.open("%s/%s_%s.json" % [dump, set_name, inp["id"]], FileAccess.WRITE)
				f.store_string(Canon.file_text(rec))
				f.close()
			var dt := Time.get_ticks_msec() - t0
			if write:
				levels[key] = dig
				print("  wrote %s (%d ms)" % [key, dt])
			else:
				_ok(levels.get(key, {}) == dig, "%s identical %s (%d ms)" % [key, _diff(levels.get(key, {}), dig), dt])
		if write:
			var f := FileAccess.open(GOLDEN_FMT % set_name, FileAccess.WRITE)
			f.store_string(Canon.file_text({"schema": "scrubbots.difficulty_v1_identical_output.v1",
				"note": "SHA-256 of canonical JSON records written from the unoptimized analyzer/kernel (5d19621c)",
				"levels": levels}))
			f.close()
	_done()

## Verdict-only ProductionTargetAccess (ProofKernel / analyzer) == the full route probe, cell by
## cell, for several slot origins on sampled states of a VOID level and a maze anchor.
func _verdict_equivalence() -> void:
	var cases: Array = []
	for inp in _inputs("campaign"):
		if inp["id"] == "level_011_duckling":
			cases.append(inp)
	for inp in _inputs("anchors"):
		if inp["id"] == "hard_maze8_24":
			var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(inp["level"], inp["make"].call()))
			inp["cols"] = sol["trace"].map(func(t): return int(t["column"]))
			cases.append(inp)
	var checked := 0
	var positive := 0
	var mismatches := 0
	for inp in cases:
		var kernel = ProofKernel.new()
		var state = kernel.quiesce(ProofState.from_level_and_supply(inp["level"], inp["make"].call()))["state"]
		var cols: Array = inp["cols"]
		for step in range(cols.size() + 1):
			if step % 5 == 0:
				var board = BoardState.from_level_data(inp["level"])
				for i in range(state.active.size()):
					if state.active[i] == ProofState.CLEARED_BYTE:
						board.set_cell_state(i, BoardState.CellState.CLEARED)
				var routing = ProductionRoutingSystem.new()
				routing.interior_step_cost = ProductionRoutingSystem.TOTAL_TRAVEL_COST
				var raccess = ProductionAccessQuery.new(board)
				for slot in [0, ProofState.SLOT_COUNT - 1]:
					var origin: Vector2 = kernel._origin_for_slot(slot, board.get_width(), board.get_height())
					var fast = ProductionTargetAccess.new(routing, raccess, board, origin)
					fast.verdict_only = true
					var full = ProductionTargetAccess.new(routing, raccess, board, origin)
					for i in range(board.get_cell_count()):
						var v: bool = fast.is_targetable(i)
						checked += 1
						positive += int(v)
						if v != full.is_targetable(i):
							mismatches += 1
			if step == cols.size():
				break
			var r: Dictionary = kernel.apply_placement(state, int(cols[step]))
			if not r.get("ok", false):
				break
			state = r["state"]
	_ok(cases.size() == 2 and checked > 10000 and positive > 1000 and mismatches == 0,
		"verdict-only is_targetable == full route probe on %d cells (%d targetable, %d mismatches)" % [checked, positive, mismatches])

func _diff(want: Dictionary, got: Dictionary) -> String:
	if want.is_empty():
		return "(no golden)"
	var bad: Array = []
	for k in got:
		if want.get(k, "") != got[k]:
			bad.append(k)
	return "" if bad.is_empty() and want.size() == got.size() else "(differs: %s)" % ",".join(bad)

## [{id, level, make (Callable -> engine), cols, trace, solve(bool), number}]
func _inputs(set_name: String) -> Array:
	var out: Array = []
	if set_name == "campaign":
		var cat = LevelCatalog.new()
		cat.load_manifest()
		for e in cat.get_entries_ordered():
			var lvl = LevelLoader.load_from_path(e.level_path).level_data
			if e.supply_plan_path.is_empty():
				# Level 1: the historical seed-1 generated supply + its solver trace.
				out.append({"id": e.id, "level": lvl, "number": e.order, "solve": true,
					"make": func(): return BatchSupplyGenerator.generate(lvl, 3, 3, 1)})
			else:
				out.append(_plan_input(e.id, lvl, e.supply_plan_path, e.order))
	elif set_name == "anchors":
		for f in Anchors.FIXTURES:
			var id: String = f["id"]
			var lvl = LevelLoader.load_from_path(Anchors.fixture_level_path(id)).level_data
			var sp := Anchors.fixture_supply_path(id)
			out.append({"id": id, "level": lvl, "number": 1, "solve": true,
				"make": func(): return SupplyPlanLoader.load_engine(sp, lvl)["engine"]})
	elif set_name == "factory":
		for id in FACTORY:
			var lvl = LevelLoader.load_from_path("%s/%s.level.json" % [FACTORY_DIR, id]).level_data
			out.append(_plan_input(id, lvl, "%s/%s.supply.json" % [FACTORY_DIR, id], 1))
	return out

func _plan_input(id: String, lvl, plan_path: String, number: int) -> Dictionary:
	var cols: Array = []
	for c in SupplyPlanLoader.load_plan(plan_path)["plan"]["intendedColumnClicks"]:
		cols.append(int(c) - 1)
	return {"id": id, "level": lvl, "number": number, "solve": false, "cols": cols,
		"make": func(): return SupplyPlanLoader.load_engine(plan_path, lvl)["engine"]}

func _record(an, inp: Dictionary) -> Dictionary:
	var lvl = inp["level"]
	var rec := {}
	var cols: Array = inp.get("cols", [])
	var trace: Array = []
	if inp["solve"]:
		var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, inp["make"].call()))
		trace = sol.get("trace", [])
		rec["solver"] = {"status": String(sol["status"]), "visited": sol.get("visited"),
			"traceHash": sol.get("trace_hash"), "trace": trace}
		cols = []
		for t in trace:
			cols.append(int(t["column"]))
	rec["kernel"] = _kernel_replay(lvl, inp["make"].call(), cols)
	# A plan that is not legal under kernel timing (L20, L30) is measured up to its last legal
	# placement, so its decision states and score are still covered.
	var steps: Array = rec["kernel"].get("steps", [])
	if not steps.is_empty() and not steps[-1]["ok"]:
		cols = cols.slice(0, steps.size() - 1)
	var raw: Dictionary = an.measure(lvl, inp["make"].call(), cols, trace)
	raw.erase("timing")
	rec["measure"] = raw
	rec["score"] = an.score(raw, int(inp["number"])) if raw.has("states") else {}
	return rec

## Fresh kernel (no observer) replay of `cols`; stops at the first failed placement.
func _kernel_replay(lvl, engine, cols: Array) -> Dictionary:
	var kernel = ProofKernel.new()
	var q: Dictionary = kernel.quiesce(ProofState.from_level_and_supply(lvl, engine))
	if not q.get("ok", false):
		return {"quiesce": false}
	var state = q["state"]
	var steps: Array = []
	for col in cols:
		var r: Dictionary = kernel.apply_placement(state, int(col))
		if not r.get("ok", false):
			steps.append({"column": col, "ok": false, "error": String(r.get("error", ""))})
			break
		state = r["state"]
		steps.append({"column": col, "ok": true, "clears": r["clears"], "active_after": state.active_count(),
			"placed_slot": r["placed_slot"], "placed": r["placed"], "activeSha": state.active.hex_encode().sha256_text()})
	return {"initialClears": q["clears"], "initialActive": q["state"].active_count(), "steps": steps,
		"solved": state.is_solved()}

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var line := "Difficulty V1 identical output: %s (%d/%d cases, %d fail)" % [
		"PASS" if _fail == 0 else "FAIL", _cases - _fail, _cases, _fail]
	print(line)
	quit(0 if _fail == 0 else 1)
