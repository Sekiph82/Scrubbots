extends SceneTree
## SB-M36-013 — lane anchor calibration evidence.
## Run: godot --headless --path . -s res://tests/m36_anchor_calibration.gd
## Exits 0 on success, 1 on any failure.
##
## Proves:
##   - anchor manifest: >= 5 fixtures per lane, >= 4 EXTREME probes, rationale/profile per
##     fixture, no rationale refers to shipped levels or ratings;
##   - no anchor id/path appears in production data (catalog, campaign, levels);
##   - fixture bytes match the manifest sha256, in-memory regeneration is byte-equal, every
##     fixture loads legally (TEST, version 1) with <= 12 canonical colours;
##   - anchors_v2.json is bound to the current v2 config/score/manifest sha256, every fixture
##     SOLVED, D finite in [0,100];
##   - the decision rule is recomputed here from anchors_v2.json (medians, step 1/2/3) and
##     matches the recorded outcome and the repo state (progression v2 exists iff RESCALE,
##     with the exact derived numbers); the doc states the rule, medians and outcome;
##   - v1 progression and v2 model/analysis configs are byte-identical to main;
##   - level 311 EASY > level 11 EASY and the cadence classes hold under the chosen lane file.

const Builder = preload("res://tools/build_difficulty_anchors.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const ANCHORS_V2 := "res://coordination/sessions/FACTORY/050-m36-013-anchor-calibration/anchors_v2.json"
const PROGRESSION_V2 := "res://data/config/level_progression_v2.json"
const DOC := "res://docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md"
const LANES := ["EASY", "MEDIUM", "HARD", "VERY_HARD"]
const T := {"EASY": 20.0, "MEDIUM": 40.0, "HARD": 58.0, "VERY_HARD": 76.0}
const TOL := 5.0
## LF-normalised sha256 (Pack.content_sha256) of the files on main at dec7dbee.
const FROZEN := {
	"res://data/config/level_progression_v1.json": "fe967a7867c8bb3a163cd08b6770dc71f148a4c31c64b025a917bdcab5118efd",
	"res://data/config/difficulty_score_model_v2.json": "efa5dd36d35423d8a3873a4020ba9ea46a0fee5cc934c187f3ca1191cb0155d9",
	"res://data/config/level_difficulty_analysis_v2.json": "84e7e5f98064df60ac09975e1bf8cf273bf1e8e52f3d367770d69c99a8c678e5",
}
const CADENCE := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]

var _cases := 0
var _fail := 0

func _initialize() -> void:
	var man := _json(Builder.MANIFEST_PATH)
	_s01_manifest(man)
	_s02_not_production(man)
	_s03_fixtures(man)
	var ev := _s04_evidence(man)
	if not ev.is_empty():
		_s05_decision(ev)
	_s06_frozen()
	_s07_lane_file()
	_done()

func _s01_manifest(man: Dictionary) -> void:
	print("[s01 manifest]")
	var fx: Array = man.get("fixtures", [])
	var counts := {"EASY": 0, "MEDIUM": 0, "HARD": 0, "VERY_HARD": 0, "EXTREME": 0}
	var re := RegEx.create_from_string("(?i)(\\bL\\s?([1-9]|10)\\b|first\\s+(10|ten)|rating|shipped|owner)")
	var clean := true
	var described := true
	for f in fx:
		counts[f["lane"]] = int(counts.get(f["lane"], 0)) + 1
		clean = clean and re.search(String(f["rationale"])) == null
		described = described and String(f["rationale"]).length() > 40 and (f["profile"] as Dictionary).size() == 7
	for l in LANES:
		_ok(counts[l] >= 5, "lane %s has >= 5 anchors (%d)" % [l, counts[l]])
	_ok(counts["EXTREME"] >= 4, ">= 4 EXTREME probes (%d)" % counts["EXTREME"])
	_ok(fx.size() == Builder.FIXTURES.size(), "manifest lists every declared fixture (%d)" % fx.size())
	_ok(clean, "no rationale mentions L1..L10 / first 10 / ratings / shipped levels")
	_ok(described, "every fixture has a rationale and a 7-component intended profile")

func _s02_not_production(man: Dictionary) -> void:
	print("[s02 not production content]")
	var hits: Array = []
	var needles: Array = ["difficulty_anchors"]
	for f in man.get("fixtures", []):
		needles.append("anchor_" + String(f["id"]))
	for p in _files("res://data", [".json", ".tres", ".gd"]):
		var text := FileAccess.get_file_as_string(p)
		for n in needles:
			if text.contains(n):
				hits.append("%s:%s" % [p, n])
	_ok(hits.is_empty(), "no anchor id/path in res://data (catalog, campaign, levels) %s" % str(hits))
	var levels_dir := DirAccess.open("res://data/levels")
	_ok(levels_dir != null and not levels_dir.dir_exists("difficulty_anchors"), "no anchor directory under res://data/levels")

func _s03_fixtures(man: Dictionary) -> void:
	print("[s03 fixtures legal + deterministic]")
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	var canon := RegEx.create_from_string("^C(0[1-9]|1[0-6])$")
	for f in man.get("fixtures", []):
		var id: String = f["id"]
		var lp: String = f["levelPath"]
		var sp: String = f["supplyPath"]
		_ok(Pack.content_sha256(lp) == f["levelSha256"] and Pack.content_sha256(sp) == f["supplySha256"], "%s bytes match manifest sha256" % id)
		var t: Dictionary = Builder.fixture_texts(Builder.spec_for(id), auth)
		_ok(_lf(lp) == t["level"] and _lf(sp) == t["supply"], "%s regenerates byte-equal" % id)
		var lr = LevelLoader.load_from_path(lp)
		var lvl: Dictionary = _json(lp)
		var used: Array = f["usedColors"]
		var canon_ok := true
		for c in used:
			canon_ok = canon_ok and canon.search(String(c)) != null
		_ok(lr.is_ok() and int(lvl["version"]) == 1 and lvl["difficulty"] == "TEST" and used.size() <= 12 and used.size() >= 3 and canon_ok
			and (lvl["palette"] as Array).size() == used.size(), "%s legal, TEST v1, %d canonical colours" % [id, used.size()])

func _s04_evidence(man: Dictionary) -> Dictionary:
	print("[s04 anchors_v2.json]")
	var ev := _json(ANCHORS_V2)
	_ok(not ev.is_empty(), "anchors_v2.json exists")
	if ev.is_empty():
		return {}
	_ok(ev["analysisConfig"]["sha256"] == Pack.content_sha256(AnalyzerV2.CONFIG_PATH), "bound to current analysis config sha256")
	_ok(ev["scoreModelConfig"]["sha256"] == Pack.content_sha256(AnalyzerV2.SCORE_MODEL_PATH), "bound to current score model sha256")
	_ok(ev["anchorManifest"]["sha256"] == Pack.content_sha256(Builder.MANIFEST_PATH), "bound to current anchor manifest sha256")
	var by_id := {}
	for f in man["fixtures"]:
		by_id[f["id"]] = f
	var rows: Array = ev["fixtures"]
	_ok(rows.size() == by_id.size(), "one record per manifest fixture (%d)" % rows.size())
	var solved := true
	var bound := true
	var finite := true
	for r in rows:
		var f: Dictionary = by_id.get(r["id"], {})
		solved = solved and r["solver"] == "SOLVED"
		bound = bound and not f.is_empty() and r["levelSha256"] == f["levelSha256"] and r["supplySha256"] == f["supplySha256"] and r["lane"] == f["lane"]
		var d: float = r["D"]
		finite = finite and not is_nan(d) and not is_inf(d) and d >= 0.0 and d <= 100.0
		for k in r["vector"]:
			finite = finite and float(r["vector"][k]) >= 0.0 and float(r["vector"][k]) <= 1.0
	_ok(solved, "every fixture SOLVED")
	_ok(bound, "every record bound to its fixture sha256 and lane")
	_ok(finite, "every D finite in [0,100], every component in [0,1]")
	return ev

## Requirement 5 recomputed independently from the recorded per-fixture D values.
func _s05_decision(ev: Dictionary) -> void:
	print("[s05 decision rule]")
	var ds := {"EASY": [], "MEDIUM": [], "HARD": [], "VERY_HARD": []}
	var best_x := -1.0
	for r in ev["fixtures"]:
		if r["lane"] == "EXTREME":
			best_x = maxf(best_x, float(r["D"]))
		else:
			ds[r["lane"]].append(float(r["D"]))
	var med := {}
	for l in LANES:
		var v: Array = ds[l].duplicate()
		v.sort()
		var n: int = v.size()
		med[l] = v[n / 2] if n % 2 == 1 else 0.5 * (v[n / 2 - 1] + v[n / 2])
		_ok(is_equal_approx(float(med[l]), float(ev["decision"]["medians"][l])), "median %s %.3f matches evidence" % [l, med[l]])
	_ok(is_equal_approx(best_x, float(ev["ceiling"]["bestExtremeD"])), "ceiling = best EXTREME D %.3f" % best_x)
	var mono: bool = med["EASY"] < med["MEDIUM"] and med["MEDIUM"] < med["HARD"] and med["HARD"] < med["VERY_HARD"]
	var outcome := "MODEL_FINDING"
	if mono:
		outcome = "KEEP"
		for l in LANES:
			var inband := 0
			for d in ds[l]:
				if absf(float(d) - T[l]) <= 2.0 * TOL:
					inband += 1
			if absf(float(med[l]) - T[l]) > TOL or inband < 4:
				outcome = "RESCALE"
	_ok(outcome == ev["decision"]["outcome"], "recomputed outcome %s equals recorded outcome" % outcome)
	var doc := FileAccess.get_file_as_string(DOC)
	for phrase in ["Let `M_L` be the median D of the 5+ non-EXTREME anchors of lane L",
			"Step 1 (monotonic test, always): `M_EASY < M_MEDIUM < M_HARD < M_VERY_HARD`",
			"lane L \"holds\" if `|M_L - T_L| <= tol` AND at least 4 of its anchors lie within `T_L +/- 2*tol`",
			"Scale `s = (M_VERY_HARD - M_EASY) / (76 - 20)`"]:
		_ok(doc.contains(phrase), "doc states rule: %s" % phrase.left(48))
	_ok(doc.contains("Outcome: **%s**" % outcome), "doc records outcome %s" % outcome)
	for l in LANES:
		_ok(doc.contains("| %s | %.2f |" % [l, med[l]]), "doc lists median %s %.2f" % [l, med[l]])
	_ok(doc.contains("Informational: shipped L1..L10 under the decided lanes"), "doc has the labelled informational section")
	var has_v2 := FileAccess.file_exists(PROGRESSION_V2)
	_ok(has_v2 == (outcome == "RESCALE"), "level_progression_v2.json exists iff RESCALE (exists=%s)" % has_v2)
	if outcome == "MODEL_FINDING":
		_ok(doc.contains("MODEL FINDING: lane ordering not monotonic on anchors"), "doc records the monotonic model finding")
		_ok(FileAccess.get_file_as_string("res://TASKS.md").contains("MODEL FINDING: lane ordering not monotonic on anchors"), "TASKS.md records the finding")
	else:
		_ok(mono, "lane medians strictly monotonic")
	if outcome == "RESCALE" and has_v2:
		var v1 := _json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH)
		var p := _json(PROGRESSION_V2)
		var s: float = (float(med["VERY_HARD"]) - float(med["EASY"])) / 56.0
		var exact: bool = p["schema"] == "scrubbots-level-progression/v2" and int(p["version"]) == 2 and is_equal_approx(float(p["calibration"]["scale"]), s)
		for l in LANES:
			exact = exact and float(p["lanes"][l]["base"]) == _r1(med[l]) and float(p["lanes"][l]["growth"]) == _r1(float(v1["lanes"][l]["growth"]) * s)
		for i in range(v1["recoveryGuards"].size()):
			exact = exact and float(p["recoveryGuards"][i]["minimumChallengeDrop"]) == _r1(float(v1["recoveryGuards"][i]["minimumChallengeDrop"]) * s)
		for k in v1["challengeTolerance"]:
			var want: float = _r1(float(v1["challengeTolerance"][k]) * s) if s < 1.0 else float(v1["challengeTolerance"][k])
			exact = exact and float(p["challengeTolerance"][k]) == want
		for k in ["cadenceLength", "cadence", "progression", "productionBoardEnvelope", "productionColorRules"]:
			exact = exact and JSON.stringify(p[k]) == JSON.stringify(v1[k])
		_ok(exact, "progression v2 numbers equal the rule applied to anchors_v2.json (s=%.4f)" % s)
		_ok(p["calibration"]["anchorManifestSha256"] == Pack.content_sha256(Builder.MANIFEST_PATH)
			and p["calibration"]["analysisConfigSha256"] == Pack.content_sha256(AnalyzerV2.CONFIG_PATH), "calibration block bound to manifest/config sha256")
		var cap: float = float(p["lanes"]["VERY_HARD"]["base"]) + float(p["lanes"]["VERY_HARD"]["growth"])
		_ok(cap <= best_x or doc.contains("CEILING FINDING"), "VERY_HARD base+growth %.1f <= ceiling %.2f or ceiling finding documented" % [cap, best_x])

func _s06_frozen() -> void:
	print("[s06 v1 progression + v2 configs untouched]")
	for p in FROZEN:
		_ok(Pack.content_sha256(p) == FROZEN[p], "%s sha256 equals main" % p)

func _s07_lane_file() -> void:
	print("[s07 chosen lane file]")
	var path: String = PROGRESSION_V2 if FileAccess.file_exists(PROGRESSION_V2) else DifficultyProgressionV1.DEFAULT_CONFIG_PATH
	var cfg := _json(path)
	var classes_ok := true
	for n in range(1, 1011):
		classes_ok = classes_ok and cfg["cadence"][(n - 1) % 10]["class"] == CADENCE[(n - 1) % 10]
	_ok(classes_ok, "%s cadence classes repeat the locked 10-slot cadence for 1..1010" % path)
	var t311 := _target(cfg, 311)
	var t11 := _target(cfg, 11)
	_ok(t311 > t11, "level 311 EASY target %.2f > level 11 EASY target %.2f" % [t311, t11])
	if path == DifficultyProgressionV1.DEFAULT_CONFIG_PATH:
		var prog = DifficultyProgressionV1.new()
		_ok(is_equal_approx(prog.target_challenge_for(311), t311) and is_equal_approx(prog.target_challenge_for(11), t11), "targets equal DifficultyProgressionV1")
	for n in [1, 10, 11, 111, 300, 310, 311, 1000, 1001, 1010]:
		var t: float = _target(cfg, n)
		_ok(not is_nan(t) and t >= 0.0 and t <= 100.0, "target(%d) %.2f finite in [0,100]" % [n, t])

## target(n) = base + growth * (1 - exp(-k/tau)) + modifier, clamped 0..100 (DifficultyProgressionV1 form).
static func _target(cfg: Dictionary, n: int) -> float:
	var slot: Dictionary = cfg["cadence"][(n - 1) % 10]
	var lane: Dictionary = cfg["lanes"][slot["class"]]
	var p: float = 1.0 - exp(-float((n - 1) / 10) / float(cfg["progression"]["tauCycles"]))
	return clampf(float(lane["base"]) + float(lane["growth"]) * p + float(slot["modifier"]), 0.0, 100.0)

static func _r1(v: float) -> float:
	return round(v * 10.0) / 10.0

static func _lf(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("\r\n", "\n")

static func _files(dir: String, exts: Array) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		for e in exts:
			if f.ends_with(e):
				out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_files(dir.path_join(sub), exts))
	return out

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
	print("M36 anchor calibration: %s (%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases, _fail])
	quit(0 if _fail == 0 else 1)
