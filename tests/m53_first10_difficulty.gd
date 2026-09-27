extends SceneTree
## M53-C001 — First 10 real-level QA + Difficulty V1: direct assertions.
##
## Covers: analyzer/config/model versions and locked coefficients; cadence target
## computation; mechanical acceptance-window classification; evidence schema for all ten
## levels; exact D formula re-derived from each recorded vector with the literal V1
## weights; W..S in [0,1]; every committed raw record re-scores to the committed evidence;
## a FRESH Level 1 measurement reproduces the committed raw record (determinism) through
## the real ProofKernel/production routing (observer non-mutating: per-step clears equal a
## plain SolvabilitySolver replay); no shipping script depends on the analyzer; no content
## file is mutated and all content stays bound to the M52-accepted bytes; every static M53
## QA gate re-runs PASS; recovery checks use actual D; Frustration is provisional.
##
## Run: godot --headless --path . -s res://tests/m53_first10_difficulty.gd

const Analyzer = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const Tool = preload("res://tools/analyze_m53_first10.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const TARGETS := [20.0, 22.0, 40.0, 19.0, 58.0, 18.0, 21.0, 42.0, 19.0, 76.0]
const CLASSES := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]
const WEIGHTS := {"W": 0.10, "C": 0.15, "A": 0.20, "U": 0.20, "B": 0.15, "R": 0.10, "S": 0.10}

var _fail := 0
var _analyzer = null
var _diff: Dictionary = {}
var _qa: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_analyzer = Analyzer.new()
	_diff = Analyzer._read_json(Tool.DIFF_PATH)
	_qa = Analyzer._read_json(Tool.QA_PATH)
	var before := _content_hashes()
	_versions()
	_targets_and_windows()
	_schema()
	_formula_and_bounds()
	_rescore_committed_raw()
	_fresh_level1_determinism()
	_no_runtime_dependency()
	_static_gates()
	_recovery_and_frustration()
	var after := _content_hashes()
	_ok(before == after, "no content file mutated by analysis/QA (%d files hashed)" % before.size())
	_bound_to_m52()
	_done()

# --- versions / locked coefficients ---------------------------------------------
func _versions() -> void:
	print("[versions]")
	_ok(_analyzer.is_ok(), "analyzer loads %s" % _analyzer.get_error())
	var cfg: Dictionary = _analyzer.config()
	_ok(cfg["schema"] == "scrubbots-level-difficulty-analysis/v1" and int(cfg["version"]) == 1
		and cfg["analyzerVersion"] == "m53-level-difficulty-analyzer/v1" and cfg["calibrationStage"] == "STAGE_A_PROVISIONAL",
		"analysis config v1, analyzer v1, STAGE_A_PROVISIONAL")
	var p: Dictionary = _analyzer.provenance()
	_ok(int(p["scoreModelVersion"]) == 1 and int(p["progressionModelVersion"]) == 1, "score/progression model version 1")
	var sm: Dictionary = Analyzer._read_json(Analyzer.SCORE_MODEL_PATH)
	var w: Dictionary = sm["challengeScore"]["weights"]
	_ok(w["workload"] == 0.10 and w["colorComplexity"] == 0.15 and w["accessibilityScarcity"] == 0.20
		and w["unlockDepth"] == 0.20 and w["bottleneckPressure"] == 0.15 and w["routeComplexity"] == 0.10
		and w["slotColorPressure"] == 0.10, "locked D weights unchanged in difficulty_score_model_v1.json")
	_ok(sm["unlockDepth"]["p95Weight"] == 0.55 and sm["bottleneckPressure"]["forcedFractionWeight"] == 0.40
		and sm["slotColorPressure"]["noWorkSlotFractionWeight"] == 0.40 and sm["sessionLoad"]["weights"]["actions"] == 0.50,
		"locked component weights unchanged")
	_ok(_canon(_diff.get("analysisConfig", {})) == _canon(cfg) and _canon(_diff.get("provenance", {})) == _canon(p),
		"evidence records the exact analysis config + model provenance")

# --- targets / windows ------------------------------------------------------------
func _targets_and_windows() -> void:
	print("[targets + windows]")
	var prog = DifficultyProgressionV1.new()
	for n in range(1, 11):
		_ok(is_equal_approx(prog.target_challenge_for(n), TARGETS[n - 1]) and prog.class_for(n) == CLASSES[n - 1],
			"L%d target %.0f class %s" % [n, TARGETS[n - 1], CLASSES[n - 1]])
	var cases := [[0.0, Analyzer.WINDOW_IN], [3.5, Analyzer.WINDOW_IN], [-3.5, Analyzer.WINDOW_IN],
		[3.51, Analyzer.WINDOW_SOFT], [-5.0, Analyzer.WINDOW_SOFT], [5.01, Analyzer.WINDOW_OUT], [-40.0, Analyzer.WINDOW_OUT]]
	for c in cases:
		_ok(_analyzer.classify_window(c[0]) == c[1], "delta %+.2f -> %s" % [c[0], c[1]])

# --- schema -----------------------------------------------------------------------
func _schema() -> void:
	print("[evidence schema]")
	_ok(_diff.get("schema", "") == "scrubbots.m53.first10_difficulty.v1" and _qa.get("schema", "") == "scrubbots.m53.first10_level_qa.v1",
		"evidence schemas present")
	var levels: Array = _diff.get("levels", [])
	_ok(levels.size() == 10, "10 difficulty records")
	var sup_keys := {"W": ["activeCells", "dispatches", "routeDistanceTotal", "W"],
		"C": ["usedColors", "frequencyByHex", "normalizedEntropy", "countNorm", "C"],
		"A": ["samples", "A"], "U": ["meanWave", "p95Wave", "initiallyLockedFraction", "U"],
		"B": ["decisionStates", "productiveActionHistogram", "reachableAlternativesTotal", "lowChoiceFraction",
			"forcedFraction", "longestForcedStreak", "B"],
		"R": ["meanLength", "boardDiagonal", "meanDetour", "meanTurns", "lengthVariance", "R"],
		"S": ["noWorkSlotFraction", "singleProductiveSlotFraction", "colorDemandImbalance", "S"]}
	for i in range(levels.size()):
		var r: Dictionary = levels[i]
		var ok: bool = int(r["order"]) == i + 1 and r["id"] == Tool.LEVELS[i]["id"] and r["class"] == CLASSES[i]
		for k in sup_keys:
			for f in sup_keys[k]:
				ok = ok and r["supporting"][k].has(f)
		for f in ["actionsNorm", "routeTimeNorm", "decisionCountNorm", "estimatedAttemptSecondsProxy", "value"]:
			ok = ok and r["sessionLoad"].has(f)
		for f in ["novelty", "profile", "sensitivity", "ownerPathSensitivity", "referencePath", "m53Verdict", "staticQa"]:
			ok = ok and r.has(f)
		_ok(ok, "L%d %s: full record schema" % [i + 1, r["id"]])

# --- formula / bounds ---------------------------------------------------------------
func _formula_and_bounds() -> void:
	print("[formula + bounds]")
	for r in _diff.get("levels", []):
		var v: Dictionary = r["vector"]
		var d := 0.0
		var bounded := true
		for k in WEIGHTS:
			var x: float = float(v[k])
			bounded = bounded and is_finite(x) and x >= 0.0 and x <= 1.0
			d += WEIGHTS[k] * x
		d *= 100.0
		_ok(bounded, "L%d W..S all finite in [0,1] %s" % [int(r["order"]), str(v)])
		_ok(absf(d - float(r["challengeScore"])) < 1e-9, "L%d D == 100*(.10W+.15C+.20A+.20U+.15B+.10R+.10S) = %.4f" % [int(r["order"]), d])
		var t: float = TARGETS[int(r["order"]) - 1]
		_ok(float(r["targetChallenge"]) == t and absf(float(r["signedDelta"]) - (d - t)) < 1e-9
			and absf(float(r["absoluteDelta"]) - absf(d - t)) < 1e-9
			and r["acceptanceWindow"] == _analyzer.classify_window(d - t),
			"L%d target/delta/window mechanical (%s)" % [int(r["order"]), r["acceptanceWindow"]])
		var sl: float = float(r["sessionLoad"]["value"])
		_ok(sl >= 0.0 and sl <= 100.0 and absf(sl - 100.0 * (0.5 * float(r["sessionLoad"]["actionsNorm"]) + 0.3 * float(r["sessionLoad"]["routeTimeNorm"])
			+ 0.2 * float(r["sessionLoad"]["decisionCountNorm"]))) < 1e-9, "L%d Session Load formula exact (%.2f)" % [int(r["order"]), sl])
		var fin: bool = r["m53Verdict"] == ("PASS" if r["acceptanceWindow"] == Analyzer.WINDOW_IN and r["staticQa"] == "PASS" else r["m53Verdict"])
		_ok(fin and (r["acceptanceWindow"] == Analyzer.WINDOW_IN or r["m53Verdict"] != "PASS"),
			"L%d out-of-window level is never PASS (%s)" % [int(r["order"]), r["m53Verdict"]])

# --- committed raw re-scores to the committed evidence -------------------------------
func _rescore_committed_raw() -> void:
	print("[re-score committed raw]")
	for r in _diff.get("levels", []):
		var raw: Dictionary = Analyzer._read_json(Tool.raw_path(r["id"]))
		var s: Dictionary = _analyzer.score(raw["referencePath"]["raw"], int(r["order"]))
		var same := absf(float(s["challengeScore"]) - float(r["challengeScore"])) < 1e-9
		for k in WEIGHTS:
			same = same and absf(float(s["vector"][k]) - float(r["vector"][k])) < 1e-9
		_ok(same and raw["levelSha256"] == Pack.content_sha256(Pack.level_path(r["id"])),
			"L%d raw measurement re-scores to committed vector/D and is bound to current LevelData" % int(r["order"]))

# --- fresh Level 1 measurement: determinism + production kernel reuse ----------------
func _fresh_level1_determinism() -> void:
	print("[fresh Level 1 measurement]")
	var id := "m21_level_001_hazard_bot"
	var lvl = Tool.load_level(id)
	var ref: Dictionary = Tool.reference_inputs(id, lvl)
	_ok(ref["ok"], "Level 1 solver trace reproduces the M52 hash")
	var cols: Array = []
	for t in ref["trace"]:
		cols.append(int(t["column"]))
	var m1: Dictionary = _analyzer.measure(lvl, ref["make_engine"].call(), cols, ref["trace"])
	var m2: Dictionary = _analyzer.measure(lvl, ref["make_engine"].call(), cols, ref["trace"])
	_ok(m1["ok"] and m2["ok"], "two fresh measurements succeed")
	var a := _norm(m1)
	var b := _norm(m2)
	var committed := _norm(Analyzer._read_json(Tool.raw_path(id))["referencePath"]["raw"])
	_ok(a == b, "analyzer determinism: two runs byte-identical (timing excluded)")
	_ok(a == committed, "fresh run == committed raw evidence (timing excluded)")
	_ok(int(m1["path"]["totalClears"]) == lvl.get_cell_count() and int(m1["path"]["routeFailures"]) == 0,
		"every one of %d claims has a production route that passes RouteValidator" % lvl.get_cell_count())
	# Observer is read-only: a plain kernel/solver replay gives identical per-step clears.
	var rep: Dictionary = SolvabilitySolver.new().replay(ProofState.from_level_and_supply(lvl, ref["make_engine"].call()), ref["trace"])
	var clears_equal: bool = rep["ok"] and rep["solved"]
	for i in range(m1["placements"].size()):
		clears_equal = clears_equal and int(m1["placements"][i]["clears"]) == int(ref["trace"][i]["clears"])
	_ok(clears_equal, "observed kernel == plain SolvabilitySolver.replay step-for-step (observer non-mutating)")
	_ok(ProofKernel.new().observer == null, "ProofKernel observer defaults to null (gameplay/solver paths unobserved)")
	# Colour stats exact on a known distribution.
	var cs: Dictionary = Analyzer.color_stats(lvl)
	var h := 0.0
	for c in [30, 5, 298, 11, 56]:
		var p := float(c) / 400.0
		h -= p * log(p)
	_ok(int(cs["usedColors"]) == 5 and absf(float(cs["normalizedEntropy"]) - h / log(5.0)) < 1e-12, "normalized Shannon entropy exact for Level 1 counts")

## JSON round-trip so int/float representation differences never mask equality.
func _canon(v) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(v)), "", true)

func _norm(raw: Dictionary) -> String:
	var d: Dictionary = JSON.parse_string(JSON.stringify(raw))
	d.erase("timing")
	return JSON.stringify(d, "", true)

# --- no runtime dependency --------------------------------------------------------------
func _no_runtime_dependency() -> void:
	print("[no runtime dependency]")
	var hits: Array = []
	_scan("res://scripts", hits)
	_scan("res://scenes", hits)
	hits.erase("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
	# M53-C002 offline V2-candidate analyzer builds on V1 (preloads it); it is QA tooling too.
	hits.erase("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
	_ok(hits.is_empty(), "no shipping script/scene references the analyzer or M53 tool %s" % str(hits))

func _scan(dir: String, hits: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			var p := "%s/%s" % [dir, f]
			var t := FileAccess.get_file_as_string(p)
			if t.contains("level_difficulty_analyzer_v1") or t.contains("analyze_m53_first10"):
				hits.append(p)
	for sub in d.get_directories():
		_scan("%s/%s" % [dir, sub], hits)

# --- static QA gates ----------------------------------------------------------------------
func _static_gates() -> void:
	print("[static M53 QA gates]")
	var cat = LevelCatalog.new()
	_ok(cat.load_manifest().ok, "production catalog valid")
	var entries: Array = cat.get_entries_ordered()
	_ok(entries.size() == 10, "catalog holds exactly orders 1..10")
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	var prog = DifficultyProgressionV1.new()
	var seen := {}
	var qa_levels: Array = _qa.get("levels", [])
	for spec in Tool.LEVELS:
		var id: String = spec["id"]
		var n: int = spec["order"]
		var raw: Dictionary = Analyzer._read_json(Tool.raw_path(id))
		var gates: Array = Tool.static_gates(spec, Tool.load_level(id), entries[n - 1], auth, raw, prog, seen)
		var names: Array = []
		for g in gates:
			names.append(g["gate"])
			_ok(bool(g["pass"]), "L%d %s" % [n, g["gate"]])
		var committed: Array = []
		for g in qa_levels[n - 1]["gates"]:
			committed.append(g["gate"])
		_ok(names == committed and names.size() >= 17, "L%d committed QA evidence lists the same %d gates" % [n, names.size()])

# --- recovery / frustration ------------------------------------------------------------------
func _recovery_and_frustration() -> void:
	print("[recovery + frustration]")
	var d := {}
	for r in _diff.get("levels", []):
		d[int(r["order"])] = float(r["challengeScore"])
		var f: Dictionary = r["frustrationRisk"]
		_ok(f["status"] == "PROVISIONAL_STAGE_A" and f["scalar"] == null
			and f["components"]["retryRisk"]["status"] == "UNSUPPORTED"
			and f["components"]["sessionOverrun"]["status"] == "UNSUPPORTED"
			and f["components"]["lateFailure"]["status"] == "UNSUPPORTED",
			"L%d Frustration provisional, no scalar, human clear-rate UNSUPPORTED" % int(r["order"]))
	var guards: Array = _diff["recovery"]["guards"]
	_ok(guards.size() == 3, "three in-cycle recovery guards (3->4, 5->6, 8->9)")
	for g in guards:
		var a: int = int(g["fromLevel"])
		var b: int = int(g["toLevel"])
		_ok(float(g["actualFrom"]) == d[a] and float(g["actualTo"]) == d[b] and absf(float(g["actualDrop"]) - (d[a] - d[b])) < 1e-9
			and bool(g["pass"]) == (d[a] - d[b] >= float(g["designMinimumDrop"])),
			"L%d->L%d guard uses ACTUAL D (drop %.2f, %s)" % [a, b, d[a] - d[b], "PASS" if g["pass"] else "FAIL"])
		if not bool(g["pass"]):
			var to_rec: Dictionary = _diff["levels"][b - 1]
			_ok(to_rec["m53Verdict"] != "PASS", "L%d recovery failure is not reported PASS" % b)
	var boss_max := true
	for k in d:
		if k != 10 and d[k] >= d[10]:
			boss_max = false
	_ok(bool(_diff["recovery"]["boss"]["isCycleMaximum"]) == boss_max, "L10 boss relationship reported from actual D (max: %s)" % str(boss_max))

# --- content hashes ----------------------------------------------------------------------------
func _content_hashes() -> Dictionary:
	var h := {}
	for spec in Tool.LEVELS:
		var id: String = spec["id"]
		for p in [spec["source"], Pack.level_path(id), Pack.metadata_path(id), Pack.preview_path(id)]:
			h[p] = Pack.content_sha256(p)
		if int(spec["order"]) > 1:
			var pp := "res://data/levels/supply/%s_supply_v1.json" % id
			h[pp] = Pack.content_sha256(pp)
	h[LevelCatalog.DEFAULT_MANIFEST_PATH] = Pack.content_sha256(LevelCatalog.DEFAULT_MANIFEST_PATH)
	return h

func _bound_to_m52() -> void:
	print("[bound to M52 acceptance]")
	for spec in Tool.LEVELS:
		var id: String = spec["id"]
		var ev: Dictionary = Analyzer._read_json(Tool.M52_L1_EVIDENCE if int(spec["order"]) == 1 else Tool.M52_PLAN_EVIDENCE % id)
		var ok: bool = ev.get("levelSha256", "") == Pack.content_sha256(Pack.level_path(id))
		if int(spec["order"]) > 1:
			ok = ok and ev.get("planSha256", "") == Pack.content_sha256("res://data/levels/supply/%s_supply_v1.json" % id)
		_ok(ok, "L%d LevelData%s bytes == M52 owner-accepted evidence" % [int(spec["order"]), "" if int(spec["order"]) == 1 else " + supply plan"])

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	if _fail == 0:
		print("M53 FIRST10 DIFFICULTY: PASS")
		quit(0)
	else:
		print("M53 FIRST10 DIFFICULTY: FAIL (%d)" % _fail)
		quit(1)
