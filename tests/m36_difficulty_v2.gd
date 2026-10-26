extends SceneTree
## SB-M36-012 — difficulty score model v2 evidence (owner decision B, 2026-10-26).
## Run: godot --headless --path . -s res://tests/m36_difficulty_v2.gd
## Exits 0 on success, 1 on any failure.
##
## Proves:
##   - v1 configs, the frozen M53-C002 candidate config and level_progression_v1.json are
##     byte-identical to main (LF-normalised sha256 captured from main);
##   - v2 model: schema/version 2, locked weights exactly, formula/vector order as v1,
##     every `changes` entry has component/before/after/reason;
##   - D finite and in [0,100] for extreme/NaN/inf inputs through the v2 model and for the
##     10 recomputed levels; v2 D re-derives from the stored vector;
##   - lane targets are model-independent (level 311 EASY > level 11 EASY);
##   - anti-overfit: anchors from the corpus only (firstTenRead false, same manifest sha);
##   - playtest_v2.json is bound to the current v2 config bytes, all 10 levels SOLVED;
##   - no shipping script/scene references the v2 analyzer or configs (offline only);
##   - Spearman vs owner ratings, cadence order and recovery guards are computed and
##     reported (shortfalls informational, documented under "Honest shortfall").

const ChallengeScoreModelV1 = preload("res://scripts/difficulty/challenge_score_model_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const V2_MODEL := "res://data/config/difficulty_score_model_v2.json"
const V1_MODEL := "res://data/config/difficulty_score_model_v1.json"
const CANDIDATE_CFG := "res://data/config/level_difficulty_analysis_v2_candidate.json"
const CORPUS_MANIFEST := "res://tests/fixtures/difficulty_calibration/corpus_manifest_v1.json"
const PLAYTEST_V2 := "res://coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json"
const DOC := "res://docs/DIFFICULTY_MODEL_V2_CALIBRATION.md"
## LF-normalised sha256 (Pack.content_sha256) of the files on main at 4baf3e63.
const FROZEN := {
	"res://data/config/difficulty_score_model_v1.json": "b8310c9d3fbbb6b0b43b8afdd4c7b08ae9cfd8d77ba355a37a9dae791db64b27",
	"res://data/config/level_difficulty_analysis_v1.json": "a0b0236e408836dd69dce42682d4e055c428dc88d354c621733de39f68ae9fe5",
	"res://data/config/level_difficulty_analysis_v2_candidate.json": "7dc96a0de14d385cdda1f4c13caad9c34abd82629413552ec5d197b28f530fc5",
	"res://data/config/level_progression_v1.json": "fe967a7867c8bb3a163cd08b6770dc71f148a4c31c64b025a917bdcab5118efd",
}
const LOCKED_WEIGHTS := {"workload": 0.10, "colorComplexity": 0.15, "accessibilityScarcity": 0.20,
	"unlockDepth": 0.20, "bottleneckPressure": 0.15, "routeComplexity": 0.10, "slotColorPressure": 0.10}
## coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md, L1..L10 perceived difficulty.
const OWNER_RATINGS := [6, 3, 6, 3, 5, 3, 3, 5, 3, 5]
const CANDIDATE_RANK_CORR := 0.64

var _cases := 0
var _fail := 0

func _initialize() -> void:
	_s01_v1_untouched()
	_s02_v2_model_config()
	_s03_challenge_bounds()
	_s04_targets_model_independent()
	_s05_anti_overfit()
	_s11_offline_only()
	var pt := _s06_playtest_v2()
	if not pt.is_empty():
		_s07_rank_correlation(pt)
		_s08_cadence_order(pt)
		_s09_recovery(pt)
		_s10_unlock_not_board_size(pt)
	_done()

func _s01_v1_untouched() -> void:
	print("[s01 v1 + candidate + progression untouched]")
	for p in FROZEN:
		_ok(Pack.content_sha256(p) == FROZEN[p], "%s sha256 equals main" % p)

func _s02_v2_model_config() -> void:
	print("[s02 v2 model config]")
	var v2 := _json(V2_MODEL)
	var v1 := _json(V1_MODEL)
	_ok(v2.get("schema", "") == "scrubbots-difficulty-score-model/v2" and int(v2.get("version", 0)) == 2, "schema .../v2, version 2")
	var w: Dictionary = v2["challengeScore"]["weights"]
	var exact := w.size() == LOCKED_WEIGHTS.size()
	var total := 0.0
	for k in LOCKED_WEIGHTS:
		exact = exact and w.has(k) and float(w[k]) == float(LOCKED_WEIGHTS[k])
		total += float(w.get(k, 0.0))
	_ok(exact, "weights equal the locked 0.10/0.15/0.20/0.20/0.15/0.10/0.10 exactly")
	_ok(is_equal_approx(total, 1.0), "weights sum to 1.0 (%.6f)" % total)
	_ok(v2["challengeScore"]["formula"] == v1["challengeScore"]["formula"] and v2["challengeVectorOrder"] == v1["challengeVectorOrder"],
		"formula string and challengeVectorOrder unchanged from v1")
	_ok(bool(v2["modelRules"]["publishedLevelStoresModelVersion"]), "publishedLevelStoresModelVersion true")
	_ok(String(v2.get("supersedesNothing", "")).length() > 0, "supersedesNothing note present")
	var changes: Array = v2.get("changes", [])
	var keyed := not changes.is_empty()
	for c in changes:
		for k in ["component", "before", "after", "reason"]:
			keyed = keyed and String(c.get(k, "")).length() > 0
	_ok(keyed, "changes array non-empty, every entry has component/before/after/reason (%d)" % changes.size())
	var m2 = ChallengeScoreModelV1.new(V2_MODEL)
	_ok(m2.is_ok() and m2.model_version() == 2 and m2.provenance()["model_schema"] == "scrubbots-difficulty-score-model/v2",
		"ChallengeScoreModelV1 reads v2 when given its path explicitly")
	var m1 = ChallengeScoreModelV1.new()
	_ok(m1.is_ok() and m1.model_version() == 1 and m1.provenance()["model_schema"] == ChallengeScoreModelV1.EXPECTED_SCHEMA,
		"default constructor still loads v1")

func _s03_challenge_bounds() -> void:
	print("[s03 challenge bounds through v2]")
	var m = ChallengeScoreModelV1.new(V2_MODEL)
	_ok(is_equal_approx(m.challenge_score({}), 0.0), "empty vector -> 0")
	var ones := {"W": 1, "C": 1, "A": 1, "U": 1, "B": 1, "R": 1, "S": 1}
	_ok(is_equal_approx(m.challenge_score(ones), 100.0), "all-ones vector -> 100")
	for vec in [{"W": 5.0, "C": -3.0, "A": NAN, "U": INF, "B": 0.5, "R": 2.0, "S": -1.0},
			{"W": INF, "C": INF, "A": INF, "U": INF, "B": INF, "R": INF, "S": INF},
			{"W": -INF, "C": NAN, "A": -INF, "U": NAN, "B": -INF, "R": NAN, "S": -INF}]:
		var d: float = m.challenge_score(vec)
		_ok(is_finite(d) and d >= 0.0 and d <= 100.0, "extreme/NaN/inf inputs clamp to finite [0,100] (%.2f)" % d)

func _s04_targets_model_independent() -> void:
	print("[s04 lane targets independent of model version]")
	var p = DifficultyProgressionV1.new()
	var t11: float = p.target_challenge_for(11)
	var t311: float = p.target_challenge_for(311)
	_ok(p.class_for(11) == "EASY" and p.class_for(311) == "EASY" and t311 > t11,
		"level 311 EASY target (%.2f) > level 11 EASY target (%.2f)" % [t311, t11])

func _s05_anti_overfit() -> void:
	print("[s05 v2 analyzer + anti-overfit]")
	var an = AnalyzerV2.new()
	_ok(an.is_ok(), "LevelDifficultyAnalyzerV2 loads: %s" % an.get_error())
	if not an.is_ok():
		return
	var prov: Dictionary = an.provenance()
	_ok(int(prov["scoreModelVersion"]) == 2 and prov["scoreModelConfig"] == V2_MODEL, "analyzer scores with model v2")
	var ca: Dictionary = an.config()["calibratedAnchors"]
	var cand: Dictionary = _json(CANDIDATE_CFG)["calibratedAnchors"]
	_ok(ca["firstTenRead"] == false, "anchor derivation records firstTenRead false")
	_ok(ca["corpusManifestSha256"] == cand["corpusManifestSha256"], "corpus manifest sha256 equals the candidate's")
	_ok(Pack.content_sha256(CORPUS_MANIFEST) == ca["corpusManifestSha256"], "corpus manifest on disk matches the recorded sha256")
	_ok(ca["values"] == cand["values"], "anchors are the corpus-derived candidate anchors, unchanged")

func _s06_playtest_v2() -> Dictionary:
	print("[s06 playtest_v2.json]")
	var pt := _json(PLAYTEST_V2)
	_ok(not pt.is_empty(), "playtest_v2.json parses")
	if pt.is_empty():
		return {}
	_ok(int(pt["modelVersion"]) == 2, "top-level modelVersion 2")
	_ok(pt["scoreModelConfig"]["sha256"] == Pack.content_sha256(AnalyzerV2.SCORE_MODEL_PATH)
		and pt["analysisConfig"]["sha256"] == Pack.content_sha256(AnalyzerV2.CONFIG_PATH),
		"score-model and analysis-config sha256 match the current v2 files")
	var levels: Array = pt["levels"]
	_ok(levels.size() == 10, "10 level records")
	var m = ChallengeScoreModelV1.new(V2_MODEL)
	var all_ok := levels.size() == 10
	for r in levels:
		var d := float(r["challengeScore"])
		var ok: bool = int(r["modelVersion"]) == 2 and r["solver"]["status"] == "SOLVED" and is_finite(d) \
			and d >= 0.0 and d <= 100.0 and is_equal_approx(m.challenge_score(r["vector"]), d)
		if not ok:
			print("  level %s: modelVersion %s solver %s D %s" % [r["order"], r["modelVersion"], r["solver"]["status"], d])
		all_ok = all_ok and ok
	_ok(all_ok, "every level: modelVersion 2, SOLVED, D finite in [0,100] and equal to the v2 model on its vector")
	return pt

func _s07_rank_correlation(pt: Dictionary) -> void:
	print("[s07 rank correlation vs owner ratings]")
	var d: Array = []
	for r in pt["levels"]:
		d.append(float(r["challengeScore"]))
	var rho := spearman(d, OWNER_RATINGS)
	print("  Spearman(v2 D, owner ratings) = %+.4f (v1 +0.27, candidate +0.64)" % rho)
	_ok(is_finite(rho), "rank correlation computed")
	_ok(is_equal_approx(spearman([1.0, 2.0, 3.0, 4.0], [1, 2, 2, 4]), 0.9486832980505138), "Spearman uses average ranks for ties")
	if rho < CANDIDATE_RANK_CORR:
		print("  RANK_CORR_BELOW_CANDIDATE %+.4f" % rho)
		_ok(_doc_has("Honest shortfall"), "doc reports the shortfall under 'Honest shortfall'")

func _s08_cadence_order(pt: Dictionary) -> void:
	print("[s08 cadence class order]")
	var sums := {}
	var counts := {}
	var max_slot := 0
	var max_d := -1.0
	for r in pt["levels"]:
		var c: String = r["class"]
		sums[c] = float(sums.get(c, 0.0)) + float(r["challengeScore"])
		counts[c] = int(counts.get(c, 0)) + 1
		if float(r["challengeScore"]) > max_d:
			max_d = float(r["challengeScore"])
			max_slot = int(r["slot"])
	var mean := func(c: String) -> float: return sums[c] / counts[c]
	var e: float = mean.call("EASY")
	var m: float = mean.call("MEDIUM")
	var h: float = mean.call("HARD")
	var v: float = mean.call("VERY_HARD")
	print("  mean D EASY %.2f, MEDIUM %.2f, HARD %.2f, VERY_HARD %.2f; cycle max slot %d" % [e, m, h, v, max_slot])
	if e < m and m < h and h < v and max_slot == 10:
		_ok(true, "EASY < MEDIUM < HARD < VERY_HARD and slot 10 is the cycle maximum")
	else:
		print("  CADENCE_ORDER_PARTIAL E<M %s, M<H %s, H<VH %s, max slot 10 %s" % [e < m, m < h, h < v, max_slot == 10])
		_ok(_doc_has("Honest shortfall"), "doc reports the cadence shortfall under 'Honest shortfall'")

func _s09_recovery(pt: Dictionary) -> void:
	print("[s09 recovery guards]")
	_ok(pt.has("recovery"), "recovery key present")
	if not pt.has("recovery"):
		return
	var d := {}
	for r in pt["levels"]:
		d[int(r["order"])] = float(r["challengeScore"])
	var seen: Array = []
	var consistent := true
	for g in pt["recovery"]["guards"]:
		var a := int(g["fromLevel"])
		var b := int(g["toLevel"])
		seen.append("%d->%d" % [a, b])
		var drop: float = d[a] - d[b]
		consistent = consistent and is_equal_approx(float(g["actualFrom"]), d[a]) and is_equal_approx(float(g["actualTo"]), d[b]) \
			and is_equal_approx(float(g["actualDrop"]), drop) and bool(g["pass"]) == (drop >= float(g["designMinimumDrop"]))
		print("  guard %d->%d drop %.2f (min %.0f): %s" % [a, b, drop, float(g["designMinimumDrop"]), "pass" if g["pass"] else "miss"])
	_ok(seen == ["3->4", "5->6", "8->9"], "guards 3->4, 5->6, 8->9 reported")
	_ok(consistent, "guards internally consistent with the level D values")

func _s10_unlock_not_board_size(pt: Dictionary) -> void:
	print("[s10 U is not a pure function of board size]")
	var u32 := {}
	for r in pt["levels"]:
		if int(r["width"]) == 32 and int(r["height"]) == 32:
			u32["%.6f" % float(r["vector"]["U"])] = true
	_ok(u32.size() > 1, "U differs across the 32x32 full-rectangle levels (%d distinct values)" % u32.size())

func _s11_offline_only() -> void:
	print("[s11 v2 stays offline]")
	var hits: Array = []
	_scan("res://scripts", hits)
	_scan("res://scenes", hits)
	hits.erase("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
	_ok(hits.is_empty(), "no shipping script/scene references the v2 analyzer or v2 configs %s" % str(hits))

func _scan(dir: String, hits: Array) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			var p := "%s/%s" % [dir, f]
			var t := FileAccess.get_file_as_string(p)
			if t.contains("level_difficulty_analyzer_v2.gd") or t.contains("difficulty_score_model_v2") or t.contains("level_difficulty_analysis_v2.json"):
				hits.append(p)
	for sub in da.get_directories():
		_scan("%s/%s" % [dir, sub], hits)

## Spearman rank correlation with average ranks for ties.
static func spearman(a: Array, b: Array) -> float:
	var ra := _ranks(a)
	var rb := _ranks(b)
	var n := ra.size()
	var ma := 0.0
	var mb := 0.0
	for i in range(n):
		ma += ra[i] / n
		mb += rb[i] / n
	var num := 0.0
	var da := 0.0
	var db := 0.0
	for i in range(n):
		num += (ra[i] - ma) * (rb[i] - mb)
		da += (ra[i] - ma) * (ra[i] - ma)
		db += (rb[i] - mb) * (rb[i] - mb)
	return num / sqrt(da * db) if da > 0.0 and db > 0.0 else NAN

static func _ranks(x: Array) -> Array:
	var idx: Array = range(x.size())
	idx.sort_custom(func(i, j): return float(x[i]) < float(x[j]))
	var r: Array = []
	r.resize(x.size())
	var i := 0
	while i < idx.size():
		var j := i
		while j + 1 < idx.size() and float(x[idx[j + 1]]) == float(x[idx[i]]):
			j += 1
		for k in range(i, j + 1):
			r[idx[k]] = (i + j) / 2.0 + 1.0
		i = j + 1
	return r

func _doc_has(text: String) -> bool:
	return FileAccess.get_file_as_string(DOC).contains(text)

static func _json(path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	if _fail == 0:
		print("M36 DIFFICULTY V2 PASS")
	print("M36 difficulty V2 evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases - _fail, _cases, _fail])
	quit(0 if _fail == 0 else 1)
