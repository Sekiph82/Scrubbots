extends SceneTree
## SB-M36-005 — simulated difficulty playtest of the shipped production catalog (offline tool).
##
##   godot --headless --path . -s res://tools/difficulty_playtest.gd [-- --committed-measure]
##
## Thin runner over the existing Difficulty V1 tooling; it adds no scoring logic. For every
## catalog entry it runs a FRESH SolvabilitySolver solve, replays the oracle trace through
## LevelDifficultyAnalyzerV1.measure (or, with --committed-measure, reuses the committed M53
## raw record when its trace hash equals the fresh one; labelled per level), scores it with
## the versioned model, and flags anomalies mechanically. Writes
## coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json and prints
## the report table. Read-only with respect to all content and configs.

const Tool = preload("res://tools/analyze_m53_first10.gd")
const Analyzer = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const OUT_DIR := "res://coordination/sessions/FACTORY/044-m36-005-difficulty-playtest"
const OUT_PATH := OUT_DIR + "/playtest_v1.json"
## CLAUDE.md 11.1 owner-locked cadence, independent of the config (rule CADENCE).
const CADENCE_11_1 := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]
## docs/10 vocabulary: never collapse UNSOLVABLE and INCONCLUSIVE.
const SOLVER_STATUS := {"SOLVED": "SOLVED", "DEADLOCK": "UNSOLVABLE", "UNKNOWN_BOUND": "INCONCLUSIVE"}

func _initialize() -> void:
	quit(run(OS.get_cmdline_user_args().has("--committed-measure")))

func run(committed_measure: bool) -> int:
	var analyzer = Analyzer.new()
	var prog = DifficultyProgressionV1.new()
	var cat = LevelCatalog.new()
	if not analyzer.is_ok() or not prog.is_ok() or not cat.load_manifest().ok:
		printerr("LOAD_FAIL analyzer/progression/catalog")
		return 1
	var levels: Array = []
	for entry in cat.get_entries_ordered():
		var rec := level_record(entry, analyzer, prog, committed_measure)
		if rec.is_empty():
			return 1
		levels.append(rec)
	var for_guards: Array = []
	for r in levels:
		for_guards.append({"order": r["order"], "challengeScore": r["challengeScore"], "sessionLoad": {"value": r["sessionLoad"]}})
	var recovery: Dictionary = Tool.recovery_checks(for_guards, prog)
	var anomalies := find_anomalies(levels, recovery, analyzer)
	var tol: Dictionary = Analyzer._read_json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH)["challengeTolerance"]
	var out := {"schema": "scrubbots.m36.difficulty_playtest.v1", "version": 1, "task": "SB-M36-005",
		"generatedBy": "res://tools/difficulty_playtest.gd", "catalog": LevelCatalog.DEFAULT_MANIFEST_PATH,
		"provenance": analyzer.provenance(), "challengeTolerance": tol,
		"measureMode": "committed_raw_if_trace_equal" if committed_measure else "fresh",
		"recovery": recovery, "levels": levels, "anomalies": anomalies}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if not Tool._write(OUT_PATH, JSON.stringify(out, "\t", false) + "\n"):
		return 1
	print(table_md(levels))
	print("DIFFICULTY_PLAYTEST OK levels=%d anomalies=%d" % [levels.size(), anomalies.size()])
	return 0

func level_record(entry, analyzer, prog, committed_measure: bool) -> Dictionary:
	var id: String = entry.id
	var n: int = entry.order
	var lvl = LevelLoader.load_from_path(entry.level_path).level_data
	var ref: Dictionary = Tool.reference_inputs(id, lvl)
	if not ref["ok"]:
		printerr("REFERENCE_FAIL %s: %s" % [id, ref["error"]])
		return {}
	var t0 := Time.get_ticks_msec()
	var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, ref["make_engine"].call()))
	var solver_ms := Time.get_ticks_msec() - t0
	var status: String = SOLVER_STATUS.get(String(sol["status"]), String(sol["status"]))
	# The fresh solver trace is the oracle path; an unsolved level falls back to the
	# committed reference trace so its structure can still be measured.
	var trace: Array = sol["trace"] if status == "SOLVED" else ref["trace"]
	var trace_hash: int = SolvabilitySolver._trace_hash(trace)
	var cols: Array = []
	for t in trace:
		cols.append(int(t["column"]))
	var raw: Dictionary = {}
	var source := "fresh"
	if committed_measure and FileAccess.file_exists(Tool.raw_path(id)):
		var c: Dictionary = Analyzer._read_json(Tool.raw_path(id))
		if int(c["referencePath"]["traceHash"]) == trace_hash and c["levelSha256"] == Pack.content_sha256(entry.level_path):
			raw = c["referencePath"]["raw"]
			source = "committed_raw"
	if raw.is_empty():
		raw = analyzer.measure(lvl, ref["make_engine"].call(), cols, trace)
		if not raw.has("path"):
			printerr("MEASURE_FAIL %s: %s" % [id, raw["error"]])
			return {}
	var s: Dictionary = analyzer.score(raw, n)
	var p: Dictionary = raw["path"]
	print("PLAYTESTED %s solver=%s %d ms measure=%s %d ms" % [id, status, solver_ms, source, int(raw["timing"]["totalMs"])])
	return {"order": n, "id": id, "width": lvl.width, "height": lvl.height,
		"class": prog.class_for(n), "declaredClass": entry.difficulty, "slot": prog.slot_for(n),
		"challengeScore": s["challengeScore"], "vector": s["vector"], "targetChallenge": s["targetChallenge"],
		"signedDelta": s["signedDelta"], "acceptanceWindow": s["acceptanceWindow"],
		"sessionLoad": s["sessionLoad"]["value"], "sessionLoadStatus": s["sessionLoad"]["status"],
		"frustrationRisk": {"status": s["frustrationRisk"]["status"], "scalar": s["frustrationRisk"]["scalar"],
			"choiceOpacityProxy": s["frustrationRisk"]["components"]["choiceOpacity"]["value"]},
		"solver": {"status": status, "rawStatus": String(sol["status"]), "visited": int(sol["visited"]),
			"ms": solver_ms, "traceHash": trace_hash, "traceEqualsCommittedReference": trace_hash == int(ref["traceHash"])},
		"dispatches": int(p["totalClears"]), "decisions": int(p["steps"]), "dispatchWaves": int(p["dispatchWaves"]),
		"routeFailures": int(p["routeFailures"]), "solved": bool(p["solved"]), "finalActive": int(p["finalActive"]),
		"measureMs": int(raw["timing"]["totalMs"]), "source": source}

func find_anomalies(levels: Array, recovery: Dictionary, analyzer) -> Array:
	var out: Array = []
	var by_order := {}
	for r in levels:
		by_order[int(r["order"])] = r
		var n: int = r["order"]
		var base := {"order": n, "id": r["id"], "challengeScore": r["challengeScore"]}
		var cadence_class: String = CADENCE_11_1[(n - 1) % 10]
		if r["declaredClass"] != cadence_class:
			out.append(_with(base, {"rule": "CADENCE", "declaredClass": r["declaredClass"], "expectedClass": cadence_class}))
		if r["declaredClass"] != r["class"]:
			out.append(_with(base, {"rule": "BOUNDARY", "declaredClass": r["declaredClass"], "configClass": r["class"]}))
		if r["acceptanceWindow"] != Analyzer.WINDOW_IN:
			out.append(_with(base, {"rule": "LANE_MISS",
				"severity": "SOFT" if r["acceptanceWindow"] == Analyzer.WINDOW_SOFT else "OUT_OF_HARD_LIMIT",
				"targetChallenge": r["targetChallenge"], "signedDelta": r["signedDelta"]}))
		if r["solver"]["status"] != "SOLVED":
			out.append(_with(base, {"rule": "SOLVER", "status": r["solver"]["status"]}))
		if int(r["routeFailures"]) > 0 or not bool(r["solved"]) or int(r["finalActive"]) > 0:
			out.append(_with(base, {"rule": "ROUTE", "routeFailures": r["routeFailures"],
				"solved": r["solved"], "finalActive": r["finalActive"]}))
	for g in recovery["guards"]:
		if not bool(g["pass"]):
			var to: Dictionary = by_order[int(g["toLevel"])]
			out.append({"rule": "RECOVERY", "order": to["order"], "id": to["id"], "challengeScore": to["challengeScore"],
				"fromOrder": g["fromLevel"], "fromId": by_order[int(g["fromLevel"])]["id"], "fromChallengeScore": g["actualFrom"],
				"actualDrop": g["actualDrop"], "designMinimumDrop": g["designMinimumDrop"]})
	# No config defines a long/high-friction threshold (docs/11 section 8 is relative), so
	# the pack median of each axis is the threshold.
	var med_d := _median(levels, "challengeScore")
	var med_s := _median(levels, "sessionLoad")
	for i in range(1, levels.size()):
		var a: Dictionary = levels[i - 1]
		var b: Dictionary = levels[i]
		if a["challengeScore"] > med_d and a["sessionLoad"] > med_s and b["challengeScore"] > med_d and b["sessionLoad"] > med_s:
			out.append({"rule": "LONG_HIGH_FRICTION", "order": b["order"], "id": b["id"], "challengeScore": b["challengeScore"],
				"sessionLoad": b["sessionLoad"], "previousOrder": a["order"], "previousId": a["id"],
				"previousChallengeScore": a["challengeScore"], "previousSessionLoad": a["sessionLoad"],
				"medianChallengeScore": med_d, "medianSessionLoad": med_s})
	return out

static func _with(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := a.duplicate()
	d.merge(b)
	return d

static func _median(levels: Array, key: String) -> float:
	var v: Array = []
	for r in levels:
		v.append(float(r[key]))
	v.sort()
	var m: int = v.size() / 2
	return v[m] if v.size() % 2 == 1 else (v[m - 1] + v[m]) / 2.0

static func table_md(levels: Array) -> String:
	var f := func(x, d: int = 3) -> String: return ("%." + str(d) + "f") % float(x)
	var L := PackedStringArray()
	L.append("| # | Level | WxH | Class | Slot | D | Target | Delta | Window | W | C | A | U | B | R | S | Session Load | Frustration | Solver | Visited | Solver ms | Dispatches | Decisions | Waves | Route fails | Measure ms | Source |")
	L.append("|---:|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---|")
	for r in levels:
		var v: Dictionary = r["vector"]
		L.append("| %d | `%s` | %dx%d | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %d | %d | %d | %d | %d | %d | %d | %s |" % [
			r["order"], r["id"], r["width"], r["height"], r["class"], r["slot"], f.call(r["challengeScore"], 1),
			f.call(r["targetChallenge"], 0), "%+.1f" % float(r["signedDelta"]), r["acceptanceWindow"],
			f.call(v["W"]), f.call(v["C"]), f.call(v["A"]), f.call(v["U"]), f.call(v["B"]), f.call(v["R"]), f.call(v["S"]),
			f.call(r["sessionLoad"], 1), "%s (scalar null)" % r["frustrationRisk"]["status"] if r["frustrationRisk"]["scalar"] == null else str(r["frustrationRisk"]["scalar"]),
			r["solver"]["status"], r["solver"]["visited"], r["solver"]["ms"], r["dispatches"], r["decisions"],
			r["dispatchWaves"], r["routeFailures"], r["measureMs"], r["source"]])
	return "\n".join(L)
