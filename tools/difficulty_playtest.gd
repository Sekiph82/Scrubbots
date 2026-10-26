extends SceneTree
## SB-M36-005 — simulated difficulty playtest of the shipped production catalog (offline tool).
##
##   godot --headless --path . -s res://tools/difficulty_playtest.gd [-- --model v1|v2] [--committed-measure]
##
## Thin runner over the existing Difficulty V1 tooling; it adds no scoring logic. For every
## catalog entry it runs a FRESH SolvabilitySolver solve, replays the oracle trace through
## LevelDifficultyAnalyzerV1.measure (or, with --committed-measure, reuses the committed M53
## raw record when its trace hash equals the fresh one; labelled per level), scores it with
## the versioned model, and flags anomalies mechanically. Writes
## coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json and prints
## the report table. Read-only with respect to all content and configs.
##
## SB-M36-012: `--model v2` (the default) scores with LevelDifficultyAnalyzerV2 instead: six
## non-oracle policies measured per level (the fresh solver trace is replayed only as the
## ORACLE_DIAGNOSTIC run; --committed-measure reuses the committed M53-C002 holdout raw when
## LevelData sha and trace hash match) and writes
## coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json. `--model v1`
## reproduces the SB-M36-005 run and file unchanged.
##
## SB-M36-016: `--progression v2` (requires `--model v2`) reads lane targets, recovery guards and
## challengeTolerance from level_progression_v2.json and writes playtest_v2_progression_v2.json
## beside playtest_v2.json; `--progression v1` (the default) leaves every output unchanged.
##
## SB-M36-014: `recovery.componentChecks` (additive) reports, per recovery guard pair, the
## component rules of docs/DIFFICULTY_RECOVERY_SEQUENCING_PROPOSAL_V1.md section 4 rules 2-3 on
## the actual vectors: recovery A <= peak A, B <= peak B, not above on both B and U, Session Load
## strictly below the peak. Reported only; they add no anomalies.
##
## SB-M36-015: `--frustration [--runs N]` (requires `--model v2`, opt-in) additionally runs the
## FrustrationAnalyzerV1 HUMAN_BR population (3 PRIOR_UNCALIBRATED profiles x runsPerProfile,
## default 32 from frustration_analysis_v1.json; `--runs N` overrides it) on every level, using
## that level's v2 Session Load, slot budget (PROXY) and choice-opacity proxy, and writes
## frustration_v1.json + frustration_v1.md beside playtest_v2.json (per-level F labelled
## PROVISIONAL_SIMULATED_HUMAN, the four inputs, diagnostics, wall time). Slow: about 5.6 h for
## the 10 shipped levels at 32 runs (proposal section 4.7); run it in the background. Without
## `--frustration` every output file and stdout line is unchanged.

const Tool = preload("res://tools/analyze_m53_first10.gd")
const Analyzer = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")
const FrustrationAnalyzerV1 = preload("res://scripts/difficulty/frustration_analyzer_v1.gd")

const OUT_DIR := "res://coordination/sessions/FACTORY/044-m36-005-difficulty-playtest"
const OUT_PATH := OUT_DIR + "/playtest_v1.json"
const OUT_DIR_V2 := "res://coordination/sessions/FACTORY/046-difficulty-model-v2"
const OUT_PATH_V2 := OUT_DIR_V2 + "/playtest_v2.json"
const OUT_PATH_V2_PROG_V2 := OUT_DIR_V2 + "/playtest_v2_progression_v2.json"
const OUT_PATH_FRUSTRATION := OUT_DIR_V2 + "/frustration_v1.json"
const OUT_PATH_FRUSTRATION_MD := OUT_DIR_V2 + "/frustration_v1.md"
const V2_COMMITTED_RAW := "res://coordination/sessions/M53-C002/evidence/holdout_raw/%s_raw.json"
## CLAUDE.md 11.1 owner-locked cadence, independent of the config (rule CADENCE).
const CADENCE_11_1 := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]
## docs/10 vocabulary: never collapse UNSOLVABLE and INCONCLUSIVE.
const SOLVER_STATUS := {"SOLVED": "SOLVED", "DEADLOCK": "UNSOLVABLE", "UNKNOWN_BOUND": "INCONCLUSIVE"}

## SB-M36-015 opt-in frustration run (null = off).
var _frustration = null
var _frustration_runs := -1
var _frustration_levels: Array = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--model")
	var model: String = args[i + 1] if i >= 0 and i + 1 < args.size() else "v2"
	if not model in ["v1", "v2"]:
		printerr("UNKNOWN_MODEL %s (use --model v1|v2)" % model)
		quit(1)
		return
	var j := args.find("--progression")
	var progression: String = args[j + 1] if j >= 0 and j + 1 < args.size() else "v1"
	if not progression in ["v1", "v2"]:
		printerr("UNKNOWN_PROGRESSION %s (use --progression v1|v2)" % progression)
		quit(1)
		return
	if progression == "v2" and model != "v2":
		printerr("UNKNOWN_PROGRESSION v2 needs --model v2 (the v1 analyzer is frozen on progression v1)")
		quit(1)
		return
	if args.has("--frustration"):
		if model != "v2":
			printerr("FRUSTRATION needs --model v2")
			quit(1)
			return
		var k := args.find("--runs")
		_frustration_runs = int(args[k + 1]) if k >= 0 and k + 1 < args.size() else -1
	quit(run(args.has("--committed-measure"), model, progression, args.has("--frustration")))

func run(committed_measure: bool, model: String = "v2", progression: String = "v1", frustration: bool = false) -> int:
	var v2 := model == "v2"
	var prog_path: String = DifficultyProgressionV1.V2_CONFIG_PATH if progression == "v2" else DifficultyProgressionV1.DEFAULT_CONFIG_PATH
	var analyzer = AnalyzerV2.new(AnalyzerV2.CONFIG_PATH, prog_path) if v2 else Analyzer.new()
	var prog = DifficultyProgressionV1.new(prog_path)
	var cat = LevelCatalog.new()
	if not analyzer.is_ok() or not prog.is_ok() or not cat.load_manifest().ok:
		printerr("LOAD_FAIL analyzer/progression/catalog")
		return 1
	if frustration:
		_frustration = FrustrationAnalyzerV1.new(analyzer)
		if not _frustration.is_ok():
			printerr("LOAD_FAIL frustration %s" % _frustration.get_error())
			return 1
	var levels: Array = []
	for entry in cat.get_entries_ordered():
		var rec := level_record_v2(entry, analyzer, prog, committed_measure) if v2 else level_record(entry, analyzer, prog, committed_measure)
		if rec.is_empty():
			return 1
		levels.append(rec)
	var for_guards: Array = []
	for r in levels:
		for_guards.append({"order": r["order"], "challengeScore": r["challengeScore"], "sessionLoad": {"value": r["sessionLoad"]}})
	var recovery: Dictionary = Tool.recovery_checks(for_guards, prog)
	recovery["componentChecks"] = recovery_component_checks(levels, recovery["guards"])
	var anomalies := find_anomalies(levels, recovery, analyzer)
	var tol: Dictionary = prog.challenge_tolerance()
	var provenance: Dictionary = analyzer.provenance()
	if progression == "v2":
		provenance["progressionConfig"] = prog_path
	var score_cfg: String = AnalyzerV2.SCORE_MODEL_PATH if v2 else Analyzer.SCORE_MODEL_PATH
	var analysis_cfg: String = AnalyzerV2.CONFIG_PATH if v2 else Analyzer.DEFAULT_CONFIG_PATH
	var out := {"schema": "scrubbots.m36.difficulty_playtest.v1", "version": 1, "task": "SB-M36-005",
		"generatedBy": "res://tools/difficulty_playtest.gd", "catalog": LevelCatalog.DEFAULT_MANIFEST_PATH,
		"provenance": provenance, "challengeTolerance": tol,
		"measureMode": "committed_raw_if_trace_equal" if committed_measure else "fresh",
		"recovery": recovery, "levels": levels, "anomalies": anomalies}
	if v2:
		# The v1 file keeps its SB-M36-005 shape; only v2 carries the model/config keys.
		out = {"schema": "scrubbots.m36.difficulty_playtest.v2", "version": 2, "task": "SB-M36-012",
			"generatedBy": "res://tools/difficulty_playtest.gd", "catalog": LevelCatalog.DEFAULT_MANIFEST_PATH,
			"modelVersion": 2, "scoreModelConfig": {"path": score_cfg, "sha256": Pack.content_sha256(score_cfg)},
			"analysisConfig": {"path": analysis_cfg, "sha256": Pack.content_sha256(analysis_cfg)},
			"sha256Note": "Pack.content_sha256: sha256 of the JSON text with CRLF normalised to LF",
			"provenance": provenance, "challengeTolerance": tol,
			"measureMode": out["measureMode"], "recovery": recovery, "levels": levels, "anomalies": anomalies}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR_V2 if v2 else OUT_DIR))
	var out_path: String = OUT_PATH_V2_PROG_V2 if progression == "v2" else (OUT_PATH_V2 if v2 else OUT_PATH)
	if not Tool._write(out_path, JSON.stringify(out, "\t", false) + "\n"):
		return 1
	print("MODEL modelVersion=%d scoreModel=%s sha256=%s analysisConfig=%s sha256=%s" % [2 if v2 else 1,
		score_cfg, Pack.content_sha256(score_cfg), analysis_cfg, Pack.content_sha256(analysis_cfg)])
	print(table_v2_md(levels) if v2 else table_md(levels))
	print("DIFFICULTY_PLAYTEST OK levels=%d anomalies=%d" % [levels.size(), anomalies.size()])
	if _frustration != null:
		return write_frustration()
	return 0

## SB-M36-015: per-level HUMAN_BR population result (only with --frustration).
func frustration_level(id: String, n: int, lvl, make_engine: Callable, slot: int, s: Dictionary) -> void:
	var t0 := Time.get_ticks_msec()
	var r: Dictionary = _frustration.analyze(lvl, make_engine, id, slot, s["sessionLoad"],
		s["frustration"]["components"]["choiceOpacity"]["value"], _frustration_runs)
	var ms := Time.get_ticks_msec() - t0
	print("FRUSTRATION %s F=%s %d ms" % [id, str(r["F"]), ms])
	_frustration_levels.append({"order": n, "id": id, "wallMs": ms, "result": r})

func write_frustration() -> int:
	var total := 0
	for r in _frustration_levels:
		total += int(r["wallMs"])
	var out := {"schema": "scrubbots.m36.frustration_playtest.v1", "task": "SB-M36-015",
		"generatedBy": "res://tools/difficulty_playtest.gd --frustration",
		"config": {"path": FrustrationAnalyzerV1.CONFIG_PATH, "sha256": Pack.content_sha256(FrustrationAnalyzerV1.CONFIG_PATH)},
		"status": "PROVISIONAL_SIMULATED_HUMAN", "totalWallMs": total, "levels": _frustration_levels}
	if not Tool._write(OUT_PATH_FRUSTRATION, FrustrationAnalyzerV1.to_json(out)):
		return 1
	var md := "# Frustration Risk (SB-M36-015, PROVISIONAL_SIMULATED_HUMAN, profiles PRIOR_UNCALIBRATED, budget PROXY)

" 		+ frustration_table_md(_frustration_levels) + "

Total wall time: %.1f s
" % (float(total) / 1000.0)
	if not Tool._write(OUT_PATH_FRUSTRATION_MD, md):
		return 1
	print(frustration_table_md(_frustration_levels))
	print("FRUSTRATION OK levels=%d wallMs=%d" % [_frustration_levels.size(), total])
	return 0

static func frustration_table_md(rows: Array) -> String:
	var g := func(x, fmt: String = "%.3f") -> String: return "null" if x == null else fmt % float(x)
	var L := PackedStringArray()
	L.append("| # | Level | Slot | Runs | F | retryRisk | sessionOverrun (SL/budget) | lateFailure (LOST) | choiceOpacity | clearRate N/C/S | Inconclusive | nearMiss | Dead/attempt | No-target wait | Hearts/clear | Attempt s (PROXY) | Wall s |")
	L.append("|---:|---|---:|---:|---:|---:|---|---|---:|---|---:|---:|---:|---:|---:|---:|---:|")
	for row in rows:
		var r: Dictionary = row["result"]
		var p: Dictionary = r["population"]
		var pp: Dictionary = r["perProfile"]
		var crs := PackedStringArray()
		var inc := 0
		var lost := 0
		for name in r["profiles"]:
			crs.append(g.call(pp[name]["clearRate"], "%.2f"))
			inc += int(pp[name]["inconclusive"])
			lost += int(pp[name]["lost"])
		L.append("| %d | `%s` | %d | %d | %s | %s | %s (%.1f/%.0f) | %s (%d) | %s | %s | %d | %s | %s | %s | %s | %s | %.1f |" % [
			row["order"], row["id"], r["slot"], r["runsPerProfile"], g.call(r["F"], "%.1f"), g.call(r["inputs"]["retryRisk"]),
			g.call(r["inputs"]["sessionOverrun"]), float(r["sessionLoad"]), float(r["sessionLoadBudget"]),
			g.call(r["inputs"]["lateFailure"]), lost, g.call(r["inputs"]["choiceOpacity"]), "/".join(crs), inc,
			g.call(p["nearMiss"]), g.call(p["deadPlacementsPerAttempt"], "%.2f"), g.call(p["noTargetWaitFraction"]),
			g.call(p["heartsPerClear"], "%.2f"), g.call(p["attemptSecondsProxy"], "%.0f"), float(row["wallMs"]) / 1000.0])
	return "
".join(L)

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

## v2: D comes from the six-policy ensemble; the fresh solver trace is the SOLVED evidence and
## is replayed only as the ORACLE_DIAGNOSTIC run, which supplies the route/solved fields.
func level_record_v2(entry, analyzer, prog, committed_measure: bool) -> Dictionary:
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
	var trace: Array = sol["trace"] if status == "SOLVED" else ref["trace"]
	var trace_hash: int = SolvabilitySolver._trace_hash(trace)
	var raw: Dictionary = {}
	var source := "fresh"
	if committed_measure and FileAccess.file_exists(V2_COMMITTED_RAW % id):
		var c: Dictionary = Analyzer._read_json(V2_COMMITTED_RAW % id)
		if int(c["solvability"]["traceHash"]) == trace_hash and c["levelSha256"] == Pack.content_sha256(entry.level_path):
			raw = c["raw"]
			source = "committed_raw"
	if raw.is_empty():
		var cols: Array = []
		for t in trace:
			cols.append(int(t["column"]))
		var fixed := {"ORACLE_DIAGNOSTIC": cols}
		if not (ref["ownerClicks"] as Array).is_empty():
			fixed["OWNER_DIAGNOSTIC"] = ref["ownerClicks"]
		raw = analyzer.measure(lvl, ref["make_engine"], fixed)
	var s: Dictionary = analyzer.score(raw, n)
	if _frustration != null:
		frustration_level(id, n, lvl, ref["make_engine"], prog.slot_for(n), s)
	var o: Dictionary = raw["runs"]["ORACLE_DIAGNOSTIC"]
	print("PLAYTESTED %s model=v2 solver=%s %d ms measure=%s %d ms" % [id, status, solver_ms, source, int(raw["timing"]["totalMs"])])
	return {"order": n, "id": id, "modelVersion": 2, "width": lvl.width, "height": lvl.height,
		"class": prog.class_for(n), "declaredClass": entry.difficulty, "slot": prog.slot_for(n),
		"challengeScore": s["challengeScore"], "vector": s["vector"], "targetChallenge": s["targetChallenge"],
		"signedDelta": s["signedDelta"], "acceptanceWindow": s["acceptanceWindow"],
		"sessionLoad": s["sessionLoad"], "unlock": s["unlock"],
		"frustrationRisk": {"status": s["frustration"]["status"], "scalar": s["frustration"]["scalar"],
			"choiceOpacityProxy": s["frustration"]["components"]["choiceOpacity"]["value"]},
		"policies": {"primaryEnsembleDRange": s["policySpread"]["primaryEnsembleDRange"],
			"primaryPoliciesCompleted": s["frustration"]["primaryPoliciesCompleted"],
			"robustnessPass": s["robustness"]["pass"], "robustnessMaxDeviation": s["robustness"]["maxDeviation"],
			"oracleDiagnosticD": s["policySpread"]["perPolicy"]["ORACLE_DIAGNOSTIC"]["D"]},
		"solver": {"status": status, "rawStatus": String(sol["status"]), "visited": int(sol["visited"]),
			"ms": solver_ms, "traceHash": trace_hash, "traceEqualsCommittedReference": trace_hash == int(ref["traceHash"])},
		"measureOk": bool(raw["ok"]), "routeFailures": int(o["routeFailures"]), "solved": bool(o["completed"]),
		"finalActive": int(round((1.0 - float(o["finalProgress"])) * float(lvl.get_cell_count()))),
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

## SB-M36-014: peak (fromLevel) vs recovery (toLevel) on actual A, B, U and Session Load.
static func recovery_component_checks(levels: Array, pairs: Array) -> Array:
	var by_order := {}
	for r in levels:
		by_order[int(r["order"])] = r
	var out: Array = []
	for g in pairs:
		var peak: Dictionary = by_order[int(g["fromLevel"])]
		var rec: Dictionary = by_order[int(g["toLevel"])]
		var pa: float = peak["vector"]["A"]
		var ra: float = rec["vector"]["A"]
		var pb: float = peak["vector"]["B"]
		var rb: float = rec["vector"]["B"]
		var pu: float = peak["vector"]["U"]
		var ru: float = rec["vector"]["U"]
		var psl: float = peak["sessionLoad"]
		var rsl: float = rec["sessionLoad"]
		var c := {"fromLevel": int(g["fromLevel"]), "toLevel": int(g["toLevel"]),
			"peakA": pa, "recoveryA": ra, "peakB": pb, "recoveryB": rb, "peakU": pu, "recoveryU": ru,
			"peakSessionLoad": psl, "recoverySessionLoad": rsl,
			"aNotAbovePeak": ra <= pa, "bNotAbovePeak": rb <= pb,
			"notAboveOnBothBAndU": not (rb > pb and ru > pu), "sessionLoadBelowPeak": rsl < psl}
		c["pass"] = c["aNotAbovePeak"] and c["bNotAbovePeak"] and c["notAboveOnBothBAndU"] and c["sessionLoadBelowPeak"]
		out.append(c)
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

static func table_v2_md(levels: Array) -> String:
	var L := PackedStringArray()
	L.append("| # | Level | WxH | Class | Slot | Model | D | Target | Delta | Window | W | C | A | U | B | R | S | Session Load | U p95/mean | Policy D range | Robust | Solver | Visited | Solver ms | Measure ms | Source |")
	L.append("|---:|---|---|---|---:|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|---|")
	for r in levels:
		var v: Dictionary = r["vector"]
		var pr: Array = r["policies"]["primaryEnsembleDRange"]
		L.append("| %d | `%s` | %dx%d | %s | %d | v%d | %.1f | %.0f | %+.1f | %s | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.1f | %d/%.2f | %.1f-%.1f | %s | %s | %d | %d | %d | %s |" % [
			r["order"], r["id"], r["width"], r["height"], r["class"], r["slot"], r["modelVersion"], r["challengeScore"],
			r["targetChallenge"], r["signedDelta"], r["acceptanceWindow"], v["W"], v["C"], v["A"], v["U"], v["B"], v["R"], v["S"],
			r["sessionLoad"], int(r["unlock"]["p95Wave"]), float(r["unlock"]["meanWave"]), pr[0], pr[1],
			"PASS" if r["policies"]["robustnessPass"] else "FAIL", r["solver"]["status"], r["solver"]["visited"],
			r["solver"]["ms"], r["measureMs"], r["source"]])
	return "\n".join(L)
