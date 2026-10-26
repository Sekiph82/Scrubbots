extends SceneTree
## SB-M36-013 — measure the lane anchor corpus with LevelDifficultyAnalyzerV2 (unchanged) and
## apply the lane decision rule declared in docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md.
##
##   godot --headless --path . -s res://tools/measure_difficulty_anchors.gd -- --measure=<fixture id>
##   godot --headless --path . -s res://tools/measure_difficulty_anchors.gd -- --merge
##
## --measure: solver proof + v2 raw measurement of one fixture (slow; one invocation per fixture).
## --merge:   score every raw record, compute lane medians / ceiling / decision and write
##            coordination/sessions/FACTORY/050-m36-013-anchor-calibration/anchors_v2.json; on a
##            RESCALE outcome also data/config/level_progression_v2.json. Reads no shipped level.

const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const Builder = preload("res://tools/build_difficulty_anchors.gd")
const Calib = preload("res://tools/calibrate_difficulty_v2.gd")
const Canon = preload("res://tools/m53_canonical_json.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const OUT_DIR := "res://coordination/sessions/FACTORY/050-m36-013-anchor-calibration"
const RAW_DIR := OUT_DIR + "/anchors_raw"
const OUT_PATH := OUT_DIR + "/anchors_v2.json"
const PROGRESSION_V2_PATH := "res://data/config/level_progression_v2.json"
const RULE_VERSION := "sb-m36-013-anchor-lane-rule/v1"
## Decision rule constants (Requirement 5, fixed before measurement).
const V1_BASE := {"EASY": 20.0, "MEDIUM": 40.0, "HARD": 58.0, "VERY_HARD": 76.0}
const TOL := 5.0
const MIN_IN_BAND := 4

func _initialize() -> void:
	var code := 1
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--measure="):
			code = measure_one(s.substr(10))
		elif s == "--merge":
			code = merge()
	quit(code)

static func raw_path(id: String) -> String:
	return "%s/%s_raw.json" % [RAW_DIR, id]

func measure_one(id: String) -> int:
	if Builder.spec_for(id).is_empty():
		printerr("FIXTURE_UNKNOWN %s" % id)
		return 1
	var lp := Builder.fixture_level_path(id)
	var sp := Builder.fixture_supply_path(id)
	var lvl = LevelLoader.load_from_path(lp).level_data
	if lvl == null:
		printerr("FIXTURE_INVALID %s" % id)
		return 1
	var make := func(): return SupplyPlanLoader.load_engine(sp, lvl)["engine"]
	var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, make.call()))
	var raw: Dictionary = AnalyzerV2.new().measure(lvl, make)
	var out := {"schema": "scrubbots.m36.anchor_v2_raw.v1", "fixtureId": id, "levelSha256": Pack.content_sha256(lp),
		"supplySha256": Pack.content_sha256(sp), "analysisConfigSha256": Pack.content_sha256(AnalyzerV2.CONFIG_PATH),
		"solvability": {"status": String(sol["status"]), "visited": sol["visited"], "traceHash": sol.get("trace_hash", null)},
		"raw": raw}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RAW_DIR))
	Calib._write(raw_path(id), Canon.file_text(out))
	print("MEASURED_ANCHOR %s solver=%s ok=%s %dms" % [id, sol["status"], raw["ok"], int(raw["timing"]["totalMs"])])
	return 0 if raw["ok"] and sol["status"] == SolvabilitySolver.SOLVED else 1

static func _round1(v: float) -> float:
	return round(v * 10.0) / 10.0

## Requirement 5 decision rule over [{lane, D}] rows. Pure; the suite recomputes it independently.
static func decide(rows: Array, best_extreme_d: float) -> Dictionary:
	var ds := {"EASY": [], "MEDIUM": [], "HARD": [], "VERY_HARD": []}
	for r in rows:
		if ds.has(r["lane"]):
			ds[r["lane"]].append(float(r["D"]))
	var med := {}
	for l in ds:
		med[l] = AnalyzerV2._median(ds[l])
	var mono: bool = med["EASY"] < med["MEDIUM"] and med["MEDIUM"] < med["HARD"] and med["HARD"] < med["VERY_HARD"]
	var out := {"ruleVersion": RULE_VERSION, "medians": med, "step1Monotonic": mono, "tolerance": TOL}
	if not mono:
		out["outcome"] = "MODEL_FINDING"
		out["finding"] = "MODEL FINDING: lane ordering not monotonic on anchors"
		return out
	var holds := {}
	var all_hold := true
	for l in ds:
		var t: float = V1_BASE[l]
		var inband := 0
		for d in ds[l]:
			if absf(float(d) - t) <= 2.0 * TOL:
				inband += 1
		var h: bool = absf(float(med[l]) - t) <= TOL and inband >= MIN_IN_BAND
		holds[l] = {"median": med[l], "v1Base": t, "medianDelta": float(med[l]) - t, "anchorsWithin2Tol": inband, "holds": h}
		all_hold = all_hold and h
	out["step2LaneHolds"] = holds
	if all_hold:
		out["outcome"] = "KEEP"
		return out
	var s: float = (float(med["VERY_HARD"]) - float(med["EASY"])) / (76.0 - 20.0)
	out["outcome"] = "RESCALE"
	out["scale"] = s
	out["ceilingCheck"] = {"bestExtremeD": best_extreme_d}
	return out

## level_progression_v2.json content for a RESCALE decision (v1 shape; only lanes/guards/tolerance scale).
static func progression_v2(dec: Dictionary, manifest_sha: String, analysis_sha: String, score_sha: String) -> Dictionary:
	var v1: Dictionary = V1._read_json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH)
	var s: float = dec["scale"]
	var p: Dictionary = v1.duplicate(true)
	p["schema"] = "scrubbots-level-progression/v2"
	p["version"] = 2
	for l in p["lanes"]:
		p["lanes"][l]["base"] = _round1(float(dec["medians"][l]))
		p["lanes"][l]["growth"] = _round1(float(v1["lanes"][l]["growth"]) * s)
	for g in p["recoveryGuards"]:
		g["minimumChallengeDrop"] = _round1(float(g["minimumChallengeDrop"]) * s)
	if s < 1.0:
		for k in p["challengeTolerance"]:
			p["challengeTolerance"][k] = _round1(float(v1["challengeTolerance"][k]) * s)
	p["calibration"] = {"task": "SB-M36-013", "ruleVersion": RULE_VERSION,
		"rule": "docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md section 2",
		"anchorManifestSha256": manifest_sha,
		"measuredMedians": dec["medians"], "scale": s,
		"analysisConfig": AnalyzerV2.CONFIG_PATH, "analysisConfigSha256": analysis_sha,
		"scoreModelConfig": AnalyzerV2.SCORE_MODEL_PATH, "scoreModelConfigSha256": score_sha,
		"evidence": OUT_PATH}
	return p

func merge() -> int:
	var man: Dictionary = V1._read_json(Builder.MANIFEST_PATH)
	var an = AnalyzerV2.new()
	var analysis_sha := Pack.content_sha256(AnalyzerV2.CONFIG_PATH)
	var score_sha := Pack.content_sha256(AnalyzerV2.SCORE_MODEL_PATH)
	var rows: Array = []
	var solved := 0
	var best_x := -1.0
	var best_x_id := ""
	for f in man["fixtures"]:
		var id: String = f["id"]
		var r: Dictionary = V1._read_json(raw_path(id))
		if r.is_empty() or r["levelSha256"] != f["levelSha256"] or r["supplySha256"] != f["supplySha256"] \
				or r["analysisConfigSha256"] != analysis_sha or not bool(r["raw"]["ok"]):
			printerr("RAW_MISSING_OR_STALE %s" % id)
			return 1
		var sc: Dictionary = an.score(r["raw"])
		if String(r["solvability"]["status"]) == "SOLVED":
			solved += 1
		var row := {"id": id, "lane": f["lane"], "w": f["w"], "h": f["h"], "usedColors": (f["usedColors"] as Array).size(),
			"supply": f["supply"], "levelSha256": f["levelSha256"], "supplySha256": f["supplySha256"],
			"solver": r["solvability"]["status"], "D": sc["challengeScore"], "vector": sc["vector"],
			"sessionLoad": sc["sessionLoad"], "unlock": sc["unlock"],
			"policySpread": {"primaryEnsembleDRange": sc["policySpread"]["primaryEnsembleDRange"],
				"allPolicyDRange": sc["policySpread"]["allPolicyDRange"], "robustnessMaxDeviation": sc["robustness"]["maxDeviation"],
				"robustnessPass": sc["robustness"]["pass"], "primaryPoliciesCompleted": sc["frustration"]["primaryPoliciesCompleted"]}}
		rows.append(row)
		if f["lane"] == "EXTREME" and float(row["D"]) > best_x:
			best_x = row["D"]
			best_x_id = id
	var dec := decide(rows, best_x)
	var manifest_sha := Pack.content_sha256(Builder.MANIFEST_PATH)
	if dec["outcome"] == "RESCALE":
		var p := progression_v2(dec, manifest_sha, analysis_sha, score_sha)
		var cap: float = float(p["lanes"]["VERY_HARD"]["base"]) + float(p["lanes"]["VERY_HARD"]["growth"])
		dec["ceilingCheck"]["veryHardBasePlusGrowth"] = cap
		dec["ceilingCheck"]["pass"] = cap <= best_x
		Calib._write(PROGRESSION_V2_PATH, Canon.file_text(p))
	var out := {"schema": "scrubbots.m36.anchor_calibration_v2.v1", "version": 1, "task": "SB-M36-013",
		"generatedBy": "res://tools/measure_difficulty_anchors.gd --merge", "modelVersion": 2,
		"analysisConfig": {"path": AnalyzerV2.CONFIG_PATH, "sha256": analysis_sha},
		"scoreModelConfig": {"path": AnalyzerV2.SCORE_MODEL_PATH, "sha256": score_sha},
		"progressionV1": {"path": DifficultyProgressionV1.DEFAULT_CONFIG_PATH, "sha256": Pack.content_sha256(DifficultyProgressionV1.DEFAULT_CONFIG_PATH)},
		"anchorManifest": {"path": Builder.MANIFEST_PATH, "sha256": manifest_sha},
		"sha256Note": "Pack.content_sha256: sha256 of the JSON text with CRLF normalised to LF",
		"provenance": an.provenance(), "ceiling": {"bestExtremeId": best_x_id, "bestExtremeD": best_x},
		"decision": dec, "fixtures": rows}
	Calib._write(OUT_PATH, Canon.file_text(out))
	for r in rows:
		var v: Dictionary = r["vector"]
		print("ANCHOR_D %s %s D=%.2f W=%.3f C=%.3f A=%.3f U=%.3f B=%.3f R=%.3f S=%.3f SL=%.1f" % [r["id"], r["lane"], r["D"],
			v["W"], v["C"], v["A"], v["U"], v["B"], v["R"], v["S"], r["sessionLoad"]])
	print("MEDIANS %s CEILING %s %.2f" % [str(dec["medians"]), best_x_id, best_x])
	print("DECISION outcome=%s" % dec["outcome"])
	print("ANCHORS_MEASURED fixtures=%d solved=%d" % [rows.size(), solved])
	return 0
