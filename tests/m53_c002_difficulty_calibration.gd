extends SceneTree
## M53-C002 — Difficulty V2-candidate calibration: direct assertions.
##
## Covers (prompt section E + audit criteria): locked V1 files untouched; V2 is a separate
## candidate (V1 analyzer/config/evidence preserved); the corpus is QA-only and outside the
## production catalog; config frozen and its sha256 bound to the corpus evidence and every
## holdout raw record; anchors re-derive by rule from the corpus raw records alone;
## deterministic re-measurement (fresh run == committed raw); W..S finite and bounded;
## every declared ordinal pair and family check re-scores PASS; primary D does not depend
## on the oracle trace (diagnostic runs removed -> identical D, analyzer never calls the
## solver); policy spread reported and robustness re-derived; stress never enters primary;
## holdout recovery uses actual V2 D; First 10 content bound to M52 bytes; owner rating sheet
## blank; no shipping dependency.
##
## Run: godot --headless --path . -s res://tests/m53_c002_difficulty_calibration.gd

const V2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const Cal = preload("res://tools/calibrate_difficulty_v2.gd")
const Tool1 = preload("res://tools/analyze_m53_first10.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")

const WEIGHTS := {"W": 0.10, "C": 0.15, "A": 0.20, "U": 0.20, "B": 0.15, "R": 0.10, "S": 0.10}
const TARGETS := [20.0, 22.0, 40.0, 19.0, 58.0, 18.0, 21.0, 42.0, 19.0, 76.0]

var _fail := 0
var _an = null
var _corpus: Dictionary = {}
var _hold: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_an = V2.new()
	_corpus = V1._read_json(Cal.CORPUS_EVIDENCE)
	_hold = V1._read_json(Cal.HOLDOUT_EVIDENCE)
	var before := _content_hashes()
	_locked_and_versioned()
	_freeze_discipline()
	_anchor_rederivation()
	_corpus_rescore_pairs_families()
	_bounds_all()
	_oracle_independence()
	_policy_spread_and_robustness()
	_holdout()
	_fresh_determinism()
	_rating_sheet()
	_no_runtime_dependency()
	_ok(before == _content_hashes(), "no production content / plan / catalog / locked config mutated during the suite")
	_done()

# --- locked files / versioning ------------------------------------------------------------
func _locked_and_versioned() -> void:
	print("[locked + versioned]")
	_ok(_an.is_ok(), "V2 candidate loads %s" % _an.get_error())
	var cfg: Dictionary = _an.config()
	_ok(cfg["schema"] == V2.EXPECTED_SCHEMA and int(cfg["version"]) == 2 and cfg["status"] == "CANDIDATE_NOT_PRODUCTION_AUTHORITY",
		"V2 config is a separate candidate (not production authority)")
	var sm: Dictionary = V1._read_json(V1.SCORE_MODEL_PATH)
	var w: Dictionary = sm["challengeScore"]["weights"]
	_ok(w["workload"] == 0.10 and w["colorComplexity"] == 0.15 and w["accessibilityScarcity"] == 0.20 and w["unlockDepth"] == 0.20
		and w["bottleneckPressure"] == 0.15 and w["routeComplexity"] == 0.10 and w["slotColorPressure"] == 0.10 and int(sm["version"]) == 1,
		"difficulty_score_model_v1.json weights unchanged")
	var prog = DifficultyProgressionV1.new()
	var ok := true
	for n in range(1, 11):
		ok = ok and is_equal_approx(prog.target_challenge_for(n), TARGETS[n - 1])
	_ok(ok, "level_progression_v1.json targets unchanged (20,22,40,19,58,18,21,42,19,76)")
	var v1cfg: Dictionary = V1._read_json(V1.DEFAULT_CONFIG_PATH)
	_ok(v1cfg["analyzerVersion"] == "m53-level-difficulty-analyzer/v1" and v1cfg["calibrationStage"] == "STAGE_A_PROVISIONAL",
		"V1 analysis config preserved")
	_ok(FileAccess.file_exists(Tool1.DIFF_PATH) and FileAccess.file_exists(Tool1.QA_PATH), "M53-C001 V1 evidence preserved")

# --- freeze ------------------------------------------------------------------------------------
func _freeze_discipline() -> void:
	print("[freeze discipline]")
	var cfg: Dictionary = _an.config()
	_ok(cfg["freeze"] != null and bool(cfg["freeze"]["frozen"]) and cfg["calibratedAnchors"] != null
		and cfg["calibratedAnchors"]["firstTenRead"] == false, "V2 config frozen with corpus-derived anchors (firstTenRead false)")
	var sha := Pack.content_sha256(V2.CONFIG_PATH)
	_ok(sha == String(_corpus["frozenConfigSha256"]), "config sha256 == corpus evidence frozen sha (%s)" % sha.left(12))
	_ok(bool(_corpus["calibrationPass"]) and _corpus["firstTenRead"] == false, "calibration passed without reading the First 10")
	_ok(String(cfg["calibratedAnchors"]["corpusManifestSha256"]) == Pack.content_sha256(Cal.MANIFEST_PATH), "anchors bound to the current corpus manifest")
	for spec in Tool1.LEVELS:
		var r: Dictionary = V1._read_json("%s/%s_raw.json" % [Cal.HOLDOUT_RAW_DIR, spec["id"]])
		_ok(String(r.get("frozenConfigSha256", "")) == sha, "L%d holdout measured against the frozen config" % int(spec["order"]))
	_ok(String(_hold["frozenConfigSha256"]) == sha, "holdout evidence scored with the frozen config")
	_ok(Cal.frozen_ok()["ok"], "tool freeze gate accepts the committed state")

# --- anchors re-derive from corpus only -------------------------------------------------------
func _anchor_rederivation() -> void:
	print("[anchor re-derivation]")
	var raws := {}
	for spec in Cal.FIXTURES:
		raws[spec["id"]] = V1._read_json("%s/%s_raw.json" % [Cal.CORPUS_RAW_DIR, spec["id"]])
	var d: Dictionary = Cal.derive_anchors(_an, raws)
	var frozen: Dictionary = _an.anchors()
	for k in V2.ANCHOR_KEYS:
		_ok(absf(float(d["values"][k]) - float(frozen[k])) < 1e-9, "anchor %s = %.4f re-derives by rule from corpus raw" % [k, float(frozen[k])])
	for spec in Cal.FIXTURES:
		var r: Dictionary = raws[spec["id"]]
		_ok(r["solvability"]["status"] == "SOLVED" and r["levelSha256"] == Pack.content_sha256(Cal.fixture_level_path(spec["id"]))
			and r["supplySha256"] == Pack.content_sha256(Cal.fixture_supply_path(spec["id"])),
			"%s: SOLVED, raw bound to current fixture + supply bytes" % spec["id"])

# --- pairs / families ---------------------------------------------------------------------------
func _corpus_rescore_pairs_families() -> void:
	print("[corpus ordinal pairs + families]")
	var scored := {}
	for spec in Cal.FIXTURES:
		var r: Dictionary = V1._read_json("%s/%s_raw.json" % [Cal.CORPUS_RAW_DIR, spec["id"]])
		scored[spec["id"]] = _an.score(r["raw"])
	for p in Cal.check_pairs(scored):
		_ok(bool(p["pass"]), "%s > %s on %s (%.3f > %.3f; D %.2f > %.2f)" % [p["harder"], p["easier"], p["axis"],
			float(p["harderAxis"]), float(p["easierAxis"]), float(p["harderD"]), float(p["easierD"])])
	var fam: Dictionary = Cal.family_checks(scored)
	_ok(bool(fam["flowSizeSpread"]["pass"]), "board size alone: flow 20..48 D spread %.2f < 18" % float(fam["flowSizeSpread"]["spread"]))
	_ok(bool(fam["flowBelowMedium"]["pass"]), "board size alone: every flow board D < MEDIUM target 40 (max %.2f)" % float(fam["flowBelowMedium"]["max"]))
	# Colour count alone does not determine D: a 3-colour fixture above the 12-colour one.
	var c12: float = scored["color_stripes12_24"]["challengeScore"]
	var three_above: Array = []
	for spec in Cal.FIXTURES:
		if (spec["colors"] as Array).size() == 3 and float(scored[spec["id"]]["challengeScore"]) > c12:
			three_above.append(spec["id"])
	_ok(not three_above.is_empty(), "colour count alone: 3-colour fixtures %s score above the 12-colour stripes (%.2f)" % [str(three_above), c12])
	_ok(float(scored["compact_hard_20"]["challengeScore"]) > float(scored["flow_stripes3_48"]["challengeScore"]),
		"compact 20x20 fixture harder than 48x48 flow fixture")
	# Evidence matches the re-score.
	var same := true
	for f in _corpus["fixtures"]:
		same = same and absf(float(f["challengeScore"]) - float(scored[f["id"]]["challengeScore"])) < 1e-9
	_ok(same, "committed corpus evidence == re-score from committed raw")

# --- bounds ------------------------------------------------------------------------------------
func _bounds_all() -> void:
	print("[bounds + formula]")
	var recs: Array = []
	for f in _corpus["fixtures"]:
		recs.append([f["id"], f["vector"], f["challengeScore"]])
	for l in _hold.get("levels", []):
		recs.append([l["id"], l["v2Candidate"]["vector"], l["v2Candidate"]["challengeScore"]])
	for r in recs:
		var d := 0.0
		var ok := true
		for k in WEIGHTS:
			var x := float(r[1][k])
			ok = ok and is_finite(x) and x >= 0.0 and x <= 1.0
			d += WEIGHTS[k] * x
		_ok(ok and absf(100.0 * d - float(r[2])) < 1e-9, "%s: W..S in [0,1], D = locked V1 formula (%.2f)" % [r[0], float(r[2])])

# --- oracle independence --------------------------------------------------------------------------
func _oracle_independence() -> void:
	print("[oracle independence]")
	var src := FileAccess.get_file_as_string("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
	_ok(not src.contains("solvability_solver") and not src.contains("SolvabilitySolver"), "V2 analyzer never loads or calls the solver")
	for spec in Tool1.LEVELS:
		var r: Dictionary = V1._read_json("%s/%s_raw.json" % [Cal.HOLDOUT_RAW_DIR, spec["id"]])
		var full: float = _an.score(r["raw"], int(spec["order"]))["challengeScore"]
		var stripped: Dictionary = JSON.parse_string(JSON.stringify(r["raw"]))
		stripped["runs"].erase("ORACLE_DIAGNOSTIC")
		stripped["runs"].erase("OWNER_DIAGNOSTIC")
		var alt: Dictionary = JSON.parse_string(JSON.stringify(r["raw"]))
		# Swap in the owner path (or nothing) as if it were a different oracle trace: primary must not move.
		if alt["runs"].has("OWNER_DIAGNOSTIC"):
			alt["runs"]["ORACLE_DIAGNOSTIC"] = alt["runs"]["OWNER_DIAGNOSTIC"]
		_ok(absf(_an.score(stripped, int(spec["order"]))["challengeScore"] - full) < 1e-12
			and absf(_an.score(alt, int(spec["order"]))["challengeScore"] - full) < 1e-12,
			"L%d primary D identical without / with a different oracle trace (%.2f)" % [int(spec["order"]), full])
		# Stress never enters primary.
		var no_stress: Dictionary = JSON.parse_string(JSON.stringify(r["raw"]))
		no_stress["runs"]["STRESS"] = no_stress["runs"]["RR"]
		_ok(absf(_an.score(no_stress, int(spec["order"]))["vector"]["B"] - _an.score(r["raw"], int(spec["order"]))["vector"]["B"]) < 1e-12,
			"L%d STRESS run does not affect primary components" % int(spec["order"]))

# --- spread / robustness -------------------------------------------------------------------------
func _policy_spread_and_robustness() -> void:
	print("[policy spread + robustness]")
	var tol := float(_an.config()["policies"]["robustnessToleranceD"])
	_ok(is_equal_approx(tol, 1.75), "robustness tolerance declared 1.75 D (half the +/-3.5 window)")
	for f in _corpus["fixtures"]:
		var pp: Dictionary = f["policySpread"]["perPolicy"]
		var ok: bool = pp.has("RR") and pp.has("GREEDY") and pp.has("ACCESS") and pp.has("RR_REV") and pp.has("GREEDY_HI") \
			and pp.has("ACCESS_HI") and pp.has("STRESS")
		_ok(ok and bool(f["robustness"]["pass"]), "%s: all 7 policies reported; replace-one/all-variant max dev %.3f <= %.2f"
			% [f["id"], float(f["robustness"]["maxDeviation"]), tol])

# --- holdout ----------------------------------------------------------------------------------------
func _holdout() -> void:
	print("[holdout]")
	var levels: Array = _hold.get("levels", [])
	_ok(levels.size() == 10, "10 holdout records")
	var v1: Dictionary = V1._read_json(Tool1.DIFF_PATH)
	var d := {}
	for i in range(levels.size()):
		var l: Dictionary = levels[i]
		var c: Dictionary = l["v2Candidate"]
		var n := i + 1
		d[n] = float(c["challengeScore"])
		var r: Dictionary = V1._read_json("%s/%s_raw.json" % [Cal.HOLDOUT_RAW_DIR, l["id"]])
		var s: Dictionary = _an.score(r["raw"], n)
		_ok(absf(float(s["challengeScore"]) - d[n]) < 1e-9 and float(c["targetChallenge"]) == TARGETS[i]
			and absf(float(c["signedDelta"]) - (d[n] - TARGETS[i])) < 1e-9 and c["acceptanceWindow"] == V1.new().classify_window(d[n] - TARGETS[i])
			and r["levelSha256"] == Pack.content_sha256(Pack.level_path(l["id"])),
			"L%d V2 D %.2f re-scores; target/delta/window mechanical (%s); bound to current LevelData" % [n, d[n], c["acceptanceWindow"]])
		_ok(absf(float(l["v1StageA"]["challengeScore"]) - float(v1["levels"][i]["challengeScore"])) < 1e-12, "L%d V1 D copied unchanged from C001" % n)
		var mx := 0.0
		for v in l["robustness"]["variants"]:
			mx = maxf(mx, absf(float(v["deviation"])))
		_ok(absf(mx - float(l["robustness"]["maxDeviation"])) < 1e-12 and bool(l["robustness"]["pass"]) == (mx <= 1.75),
			"L%d robustness honestly reported (max dev %.3f, %s)" % [n, mx, "within" if mx <= 1.75 else "OUTSIDE"])
		var f: Dictionary = l["frustration"]
		_ok(f["status"] == "PROVISIONAL_STAGE_A" and f["scalar"] == null and f["components"]["retryRisk"]["status"] == "UNSUPPORTED",
			"L%d Frustration provisional, no scalar" % n)
	for g in _hold["recovery"]["guards"]:
		var a: int = int(g["fromLevel"])
		var b: int = int(g["toLevel"])
		_ok(absf(float(g["actualDrop"]) - (d[a] - d[b])) < 1e-9 and bool(g["pass"]) == (d[a] - d[b] >= float(g["designMinimumDrop"])),
			"L%d->L%d guard from actual V2 D (drop %.2f, %s)" % [a, b, d[a] - d[b], "PASS" if g["pass"] else "FAIL"])

# --- determinism --------------------------------------------------------------------------------------
func _fresh_determinism() -> void:
	print("[fresh determinism]")
	var id := "flow_stripes3_20"
	var lvl = Cal.load_fixture(id)
	var make := func(): return SupplyPlanLoader.load_engine(Cal.fixture_supply_path(id), lvl)["engine"]
	var a := _norm(_an.measure(lvl, make))
	var b := _norm(_an.measure(lvl, make))
	var committed := _norm(V1._read_json("%s/%s_raw.json" % [Cal.CORPUS_RAW_DIR, id])["raw"])
	_ok(a == b, "V2 measurement deterministic across two fresh runs (timing excluded)")
	_ok(a == committed, "fresh run == committed corpus raw (timing excluded)")

func _norm(raw: Dictionary) -> String:
	var d: Dictionary = JSON.parse_string(JSON.stringify(raw))
	d.erase("timing")
	return JSON.stringify(d, "", true)

# --- rating sheet ------------------------------------------------------------------------------------
func _rating_sheet() -> void:
	print("[owner rating sheet]")
	var t := FileAccess.get_file_as_string("res://coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATING_SHEET_V01.md")
	var rows := 0
	var blank := true
	for line in t.split("\n"):
		if line.begins_with("| ") and line.contains("`") and line.split("|").size() >= 12:
			rows += 1
			var cells := line.split("|")
			for i in range(4, 11):
				blank = blank and String(cells[i]).strip_edges().is_empty()
	_ok(rows == 10 and blank, "owner rating sheet has 10 level rows and no filled-in ratings")

# --- no dependency ------------------------------------------------------------------------------------
func _no_runtime_dependency() -> void:
	print("[no runtime dependency]")
	var hits: Array = []
	_scan("res://scripts", hits)
	_scan("res://scenes", hits)
	hits.erase("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
	_ok(hits.is_empty(), "no shipping script/scene references the V2 candidate or calibration tool %s" % str(hits))
	var cat = LevelCatalog.new()
	var ok: bool = cat.load_manifest().ok and cat.get_entries_ordered().size() == 10
	for e in cat.get_entries_ordered():
		ok = ok and not String(e.id).begins_with("calib_") and not String(e.level_path).contains("difficulty_calibration")
	_ok(ok, "calibration fixtures never enter the production catalog (still exactly the First 10)")

func _scan(dir: String, hits: Array) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			var p := "%s/%s" % [dir, f]
			var t := FileAccess.get_file_as_string(p)
			if t.contains("level_difficulty_analyzer_v2_candidate") or t.contains("calibrate_difficulty_v2") or t.contains("difficulty_calibration"):
				hits.append(p)
	for sub in da.get_directories():
		_scan("%s/%s" % [dir, sub], hits)

func _content_hashes() -> Dictionary:
	var h := {}
	for spec in Tool1.LEVELS:
		var id: String = spec["id"]
		for p in [spec["source"], Pack.level_path(id), Pack.metadata_path(id), Pack.preview_path(id)]:
			h[p] = Pack.content_sha256(p)
		if int(spec["order"]) > 1:
			var pp := "res://data/levels/supply/%s_supply_v1.json" % id
			h[pp] = Pack.content_sha256(pp)
	for p in [LevelCatalog.DEFAULT_MANIFEST_PATH, V1.SCORE_MODEL_PATH, DifficultyProgressionV1.DEFAULT_CONFIG_PATH, V1.DEFAULT_CONFIG_PATH, V2.CONFIG_PATH]:
		h[p] = Pack.content_sha256(p)
	return h

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	if _fail == 0:
		print("M53-C002 DIFFICULTY CALIBRATION: PASS")
		quit(0)
	else:
		print("M53-C002 DIFFICULTY CALIBRATION: FAIL (%d)" % _fail)
		quit(1)
