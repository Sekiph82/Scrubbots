extends SceneTree
## SB-M36-015 — Frustration Risk inputs (HUMAN_BR population + Session Load budget).
## Run: godot --headless --path . -s res://tests/m36_frustration_v1.gd
## Exits 0 on success, 1 on any failure.
##
## Tests 1-10 of docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md section 5 on small fixtures
## (corpus 20x20/24x24 + shipped L1) with reduced runs per profile; no shipped-level sweep.
## Monotonicity and discrimination are reported honestly: a miss is printed as FINDING and
## only finiteness is asserted (profiles are PRIOR_UNCALIBRATED and never tuned to pass).

const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const FrustrationAnalyzerV1 = preload("res://scripts/difficulty/frustration_analyzer_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")
const Playtest = preload("res://tools/difficulty_playtest.gd")

const FIXTURE_DIR := "res://tests/fixtures/difficulty_calibration"
## Committed M53-C002 v2 raw measurement per corpus fixture (seven-policy ensemble), scored here
## with the unchanged v2 analyzer for Session Load and choice opacity instead of re-measuring.
const CORPUS_RAW := "res://coordination/sessions/M53-C002/evidence/corpus_raw/%s_raw.json"
const L1_ID := "m21_level_001_hazard_bot"
## Fixtures for monotonicity / discrimination / F (cadence slot 1 declared for the corpus).
const MEASURED := ["compact_hard_20", "flow_stripes3_20", "bottleneck_low_24", "bottleneck_high_24"]
## Declared before measuring (proposal section 5 test 4): harder >= easier on retryRisk.
const PAIRS := [["compact_hard_20", "flow_stripes3_20"], ["bottleneck_high_24", "bottleneck_low_24"]]
const RUNS := 2
const SMOKE_RUNS := 2
## sha256 (LF-normalised) of `git show main:<path>` before SB-M36-015.
const MAIN_SHA := {
	"res://data/config/difficulty_score_model_v1.json": "b8310c9d3fbbb6b0b43b8afdd4c7b08ae9cfd8d77ba355a37a9dae791db64b27",
	"res://data/config/difficulty_score_model_v2.json": "efa5dd36d35423d8a3873a4020ba9ea46a0fee5cc934c187f3ca1191cb0155d9",
	"res://data/config/level_difficulty_analysis_v1.json": "a0b0236e408836dd69dce42682d4e055c428dc88d354c621733de39f68ae9fe5",
	"res://data/config/level_difficulty_analysis_v2.json": "84e7e5f98064df60ac09975e1bf8cf273bf1e8e52f3d367770d69c99a8c678e5",
	"res://data/config/level_progression_v1.json": "fe967a7867c8bb3a163cd08b6770dc71f148a4c31c64b025a917bdcab5118efd",
	"res://data/config/level_progression_v2.json": "2909e6fc4295e756084be07b716e45bc2411613c658fc31a505ee075c626002a",
}
const RESULT_KEYS := ["analyzerVersion", "configVersion", "scoreModelConfig", "weights", "status", "levelId",
	"slot", "runsPerProfile", "sessionLoad", "sessionLoadBudget", "perProfile", "population", "inputs", "F",
	"FStatus", "missingInput", "attempts"]
const PROFILE_KEYS := ["clearRate", "clearRateWilson95", "won", "lost", "inconclusive", "lateFailure",
	"lateFailureLostCount", "nearMiss", "deadPlacementsPerAttempt", "noTargetWaitFraction", "attemptSecondsProxy"]
const POP_KEYS := ["clearRate", "retryRisk", "lateFailure", "nearMiss", "deadPlacementsPerAttempt",
	"noTargetWaitFraction", "heartsPerClear", "expectedAttemptsPerClear", "pOutOfHeartsBeforeClear",
	"attemptSecondsProxy"]

var _cases := 0
var _fail := 0
var _v2 = null
var _fa = null

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	_v2 = AnalyzerV2.new()
	_fa = FrustrationAnalyzerV1.new(_v2)
	_ok(_v2.is_ok() and _fa.is_ok(), "analyzers load %s" % _fa.get_error())
	if _fa.is_ok():
		var l1 := _l1()
		_s01_determinism(l1)
		_s02_degenerate(l1)
		var results := _s03_monotonicity()
		_s04_discrimination(results)
		_s05_aggregator()
		_s06_overrun()
		_s07_f(results)
		_s08_provenance(results)
		_s09_boundary()
		_s10_smoke(l1)
	print("wall %d ms" % (Time.get_ticks_msec() - t0))
	print("M36_FRUSTRATION_V1 %s (%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases, _fail])
	quit(0 if _fail == 0 else 1)

func _l1() -> Dictionary:
	var lvl = LevelLoader.load_from_path(Pack.level_path(L1_ID)).level_data
	return {"id": L1_ID, "lvl": lvl, "make": func(): return BatchSupplyGenerator.generate(lvl, 3, 3, 1)}

func _fixture(id: String) -> Dictionary:
	var lvl = LevelLoader.load_from_path("%s/%s.level.json" % [FIXTURE_DIR, id]).level_data
	var sp := "%s/%s.supply.json" % [FIXTURE_DIR, id]
	return {"id": id, "lvl": lvl, "make": func(): return SupplyPlanLoader.load_engine(sp, lvl)["engine"]}

func _s01_determinism(l1: Dictionary) -> void:
	print("[s01 determinism]")
	var fx := _fixture("compact_hard_20")
	var prof: Dictionary = _fa.config()["profiles"]["NOVICE"]
	var a: Dictionary = _fa.run_attempt(fx["lvl"], fx["make"].call(), fx["id"], "NOVICE", prof, 0)
	var b: Dictionary = _fa.run_attempt(fx["lvl"], fx["make"].call(), fx["id"], "NOVICE", prof, 0)
	_ok(a["placementHash"] == b["placementHash"] and a["columns"] == b["columns"], "same seed twice -> identical placement hash %d" % a["placementHash"])
	var c: Dictionary = _fa.run_attempt(fx["lvl"], fx["make"].call(), fx["id"], "NOVICE", prof, 1)
	_ok(a["seed"] != c["seed"], "run indexes 0/1 have different seeds")
	var diverged: bool = a["placementHash"] != c["placementHash"]
	if not diverged:
		var d: Dictionary = _fa.run_attempt(l1["lvl"], l1["make"].call(), l1["id"], "NOVICE", prof, 0)
		var e: Dictionary = _fa.run_attempt(l1["lvl"], l1["make"].call(), l1["id"], "NOVICE", prof, 1)
		diverged = d["placementHash"] != e["placementHash"]
	_ok(diverged, "two run indexes diverge on at least one fixture")
	var j1 := FrustrationAnalyzerV1.to_json(_fa.analyze(l1["lvl"], l1["make"], l1["id"], 1, 7.5, 0.2, 1))
	var j2 := FrustrationAnalyzerV1.to_json(_fa.analyze(l1["lvl"], l1["make"], l1["id"], 1, 7.5, 0.2, 1))
	_ok(j1 == j2 and j1.length() > 100, "1-level reduced run twice serializes byte-identical (%d bytes)" % j1.length())

func _s02_degenerate(l1: Dictionary) -> void:
	print("[s02 degenerate HUMAN_BR == ACCESS]")
	var argmax := {"tau": 0.0, "epsilon": 0.0, "mu": 0.0, "t0": 0.0, "t1": 0.0}
	for fx in [l1, _fixture("compact_hard_20"), _fixture("flow_stripes3_20"), _fixture("bottleneck_low_24")]:
		var acc: Dictionary = _v2.run_policy(fx["lvl"], fx["make"].call(), "ACCESS")
		var cols: Array = []
		for p in acc["placements"]:
			cols.append(int(p["column"]))
		var h: Dictionary = _fa.run_attempt(fx["lvl"], fx["make"].call(), fx["id"], "DEGENERATE", argmax, 0)
		_ok(h["columns"] == cols and cols.size() > 0, "%s: %d columns equal ACCESS" % [fx["id"], cols.size()])
		if fx["id"] != L1_ID:
			var committed: Array = []
			for p in _corpus_raw(fx["id"])["runs"]["ACCESS"]["placements"]:
				committed.append(int(p["column"]))
			_ok(committed == cols, "%s: committed corpus raw ACCESS path equals the fresh run" % fx["id"])

func _s03_monotonicity() -> Dictionary:
	print("[s03 skill monotonicity, %d runs/profile]" % RUNS)
	var out := {}
	for id in MEASURED:
		var fx := _fixture(id)
		var s: Dictionary = _v2.score(_corpus_raw(id))
		var opacity: float = s["frustration"]["components"]["choiceOpacity"]["value"]
		var r: Dictionary = _fa.analyze(fx["lvl"], fx["make"], id, 1, s["sessionLoad"], opacity, RUNS)
		out[id] = r
		var pp: Dictionary = r["perProfile"]
		var n = pp["NOVICE"]["clearRate"]
		var c = pp["CASUAL"]["clearRate"]
		var k = pp["SKILLED"]["clearRate"]
		var msg := "%s clearRate NOVICE=%s CASUAL=%s SKILLED=%s retryRisk=%s F=%s" % [id, n, c, k,
			r["population"]["retryRisk"], r["F"]]
		if n != null and c != null and k != null and k >= c and c >= n:
			_ok(true, msg)
		else:
			print("  FINDING (monotonicity miss, reported not tuned): %s" % msg)
			_ok(_finite01(n) and _finite01(c) and _finite01(k), "%s clear rates finite" % id)
	return out

func _s04_discrimination(results: Dictionary) -> void:
	print("[s04 discrimination (declared pairs)]")
	for pair in PAIRS:
		var hi = results[pair[0]]["population"]["retryRisk"]
		var lo = results[pair[1]]["population"]["retryRisk"]
		var msg := "retryRisk(%s)=%s >= retryRisk(%s)=%s" % [pair[0], hi, pair[1], lo]
		if _finite01(hi) and _finite01(lo) and float(hi) >= float(lo):
			_ok(true, msg)
		else:
			print("  FINDING (declared pair failed, reported not tuned): %s" % msg)
			_ok(_finite01(hi) and _finite01(lo), "%s / %s retryRisk finite" % pair)

func _s05_aggregator() -> void:
	print("[s05 aggregator units]")
	var agg: Dictionary = _fa.aggregate_attempts([_run("LOST", 0.70), _run("LOST", 0.71), _run("WON", 1.0),
		_run("INCONCLUSIVE", 0.5), _run("LOST", 0.90), _run("LOST", 0.89)])
	_ok(agg["lost"] == 4 and is_equal_approx(agg["lateFailure"], 3.0 / 4.0), "late: 0.70 not late, 0.71/0.89/0.90 late (3/4)")
	_ok(is_equal_approx(agg["nearMiss"], 1.0 / 4.0), "near miss: 0.90 yes, 0.89 no (1/4)")
	_ok(agg["inconclusive"] == 1 and is_equal_approx(agg["clearRate"], 1.0 / 5.0), "INCONCLUSIVE excluded from clearRate (1/5) and counted (1)")
	var lw: Array = agg["clearRateWilson95"]
	_ok(lw[0] >= 0.0 and lw[1] <= 1.0 and lw[0] <= agg["clearRate"] and agg["clearRate"] <= lw[1], "Wilson %s contains 0.2" % str(lw))
	var none: Dictionary = _fa.aggregate_attempts([_run("WON", 1.0), _run("WON", 1.0), _run("INCONCLUSIVE", 0.3)])
	_ok(none["lateFailure"] == 0.0 and none["lateFailureLostCount"] == 0 and none["nearMiss"] == 0.0, "no LOST -> lateFailure 0, LOST count 0")
	_ok(none["clearRate"] == 1.0 and none["clearRateWilson95"][1] == 1.0 and none["clearRateWilson95"][0] < 1.0, "all WON -> clearRate 1, Wilson upper 1")
	var only_inc: Dictionary = _fa.aggregate_attempts([_run("INCONCLUSIVE", 0.3)])
	_ok(only_inc["clearRate"] == null and only_inc["clearRateWilson95"] == null, "only INCONCLUSIVE -> clearRate null")
	for k in [0, 1, 7, 20]:
		var w = FrustrationAnalyzerV1.wilson95(k, 20)
		var p := float(k) / 20.0
		_ok(w[0] >= 0.0 and w[1] <= 1.0 and w[0] <= p and p <= w[1], "Wilson(%d/20) %s within 0..1, contains %.2f" % [k, str(w), p])

func _run(outcome: String, progress: float) -> Dictionary:
	return {"outcome": outcome, "finalProgress": progress, "decisions": 10, "deadPlacements": 0,
		"noTargetWaits": 0, "attemptSecondsProxy": 1.0}

func _s06_overrun() -> void:
	print("[s06 session overrun]")
	var want := [26, 26, 36, 22, 40, 22, 26, 36, 22, 48]
	var got: Array = []
	for slot in range(1, 11):
		got.append(int(_fa.budget_for_slot(slot)))
	_ok(got == want, "budget by slot 1..10 = %s" % str(got))
	for slot in range(1, 11):
		var b: float = want[slot - 1]
		_ok(_fa.session_overrun(b, slot) == 0.0 and _fa.session_overrun(0.5 * b, slot) == 0.0
			and is_equal_approx(_fa.session_overrun(1.5 * b, slot), 0.5) and _fa.session_overrun(2.0 * b, slot) == 1.0
			and _fa.session_overrun(3.0 * b, slot) == 1.0, "slot %d: 0 at/below budget, 0.5 at 1.5x, 1 at 2x and 3x" % slot)
	_ok(_fa.session_overrun(null, 1) == null and _fa.session_overrun(30.0, 0) == null, "missing Session Load or slot -> null")

func _s07_f(results: Dictionary) -> void:
	print("[s07 F]")
	var w: Dictionary = _fa.weights()
	_ok(_fa.score_model_path() == "res://data/config/difficulty_score_model_v2.json"
		and w["retryRisk"] == 0.35 and w["sessionOverrun"] == 0.30 and w["lateFailure"] == 0.20
		and w["choiceOpacity"] == 0.15, "weights read from difficulty_score_model_v2.json = 0.35/0.30/0.20/0.15")
	for id in results:
		var f = results[id]["F"]
		_ok(f != null and is_finite(float(f)) and float(f) >= 0.0 and float(f) <= 100.0, "%s F=%s finite in 0..100" % [id, f])
	var full := {"retryRisk": 0.5, "sessionOverrun": 0.2, "lateFailure": 0.4, "choiceOpacity": 0.3}
	_ok(is_equal_approx(_fa.f_score(full)["F"], 100.0 * (0.35 * 0.5 + 0.30 * 0.2 + 0.20 * 0.4 + 0.15 * 0.3)), "F formula")
	for k in FrustrationAnalyzerV1.INPUT_ORDER:
		var inp := full.duplicate()
		inp.erase(k)
		var r: Dictionary = _fa.f_score(inp)
		_ok(r["F"] == null and r["missingInput"] == k and r["status"] == "PROVISIONAL_SIMULATED_HUMAN", "F null without %s (names it)" % k)

func _s08_provenance(results: Dictionary) -> void:
	print("[s08 provenance]")
	for p in MAIN_SHA:
		_ok(Pack.content_sha256(p) == MAIN_SHA[p], "%s byte-identical to main" % p.get_file())
	var r: Dictionary = results[MEASURED[0]]
	var seeds_ok := true
	for name in r["attempts"]:
		for a in r["attempts"][name]:
			seeds_ok = seeds_ok and a["seed"] == _fa.seed_for(r["levelId"], name, a["runIndex"])
	_ok(r["analyzerVersion"] == "m36-frustration-analyzer/v1" and r["configVersion"] == 1 and seeds_ok
		and r["status"]["profiles"] == "PRIOR_UNCALIBRATED", "output carries analyzer version, config version and per-attempt seeds")

func _s09_boundary() -> void:
	print("[s09 boundary]")
	var hits: Array = []
	_scan("res://", hits)
	_ok(hits.is_empty(), "no script outside scripts/difficulty/ and no .tscn references frustration_analyzer_v1 %s" % str(hits))
	_ok(not FileAccess.get_file_as_string("res://scripts/difficulty/frustration_analyzer_v1.gd").contains("user://"), "analyzer has no user://")

## Every .tscn under res:// plus every .gd under res://scripts except scripts/difficulty/.
func _scan(dir: String, hits: Array) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		var p := dir.path_join(f)
		var script: bool = f.ends_with(".gd") and p.begins_with("res://scripts/") and not p.begins_with("res://scripts/difficulty/")
		if (script or f.ends_with(".tscn")) and FileAccess.get_file_as_string(p).contains("frustration_analyzer_v1"):
			hits.append(p)
	for sub in da.get_directories():
		if not sub.begins_with("."):
			_scan(dir.path_join(sub), hits)

func _s10_smoke(l1: Dictionary) -> void:
	print("[s10 smoke: L1, %d runs/profile]" % SMOKE_RUNS)
	var r: Dictionary = _fa.analyze(l1["lvl"], l1["make"], l1["id"], 1, 7.5, 0.2, SMOKE_RUNS)
	var missing: Array = []
	for k in RESULT_KEYS:
		if not r.has(k):
			missing.append(k)
	for name in ["NOVICE", "CASUAL", "SKILLED"]:
		for k in PROFILE_KEYS:
			if not r["perProfile"][name].has(k):
				missing.append("%s.%s" % [name, k])
		if (r["attempts"][name] as Array).size() != SMOKE_RUNS:
			missing.append("%s attempts" % name)
	for k in POP_KEYS:
		if not r["population"].has(k):
			missing.append("population.%s" % k)
	for k in FrustrationAnalyzerV1.INPUT_ORDER:
		if not r["inputs"].has(k):
			missing.append("inputs.%s" % k)
	_ok(missing.is_empty(), "L1 output has every required field %s (F=%s, retryRisk=%s)" % [str(missing), r["F"], r["population"]["retryRisk"]])
	var table: String = Playtest.frustration_table_md([{"order": 1, "id": l1["id"], "wallMs": 1000, "result": r}])
	_ok(table.split("
").size() == 3 and table.contains("`%s`" % L1_ID), "playtest --frustration markdown row renders for L1")
	var pp: Dictionary = r["perProfile"]
	var msg := "L1 clearRate NOVICE=%s CASUAL=%s SKILLED=%s" % [pp["NOVICE"]["clearRate"], pp["CASUAL"]["clearRate"], pp["SKILLED"]["clearRate"]]
	if _finite01(pp["NOVICE"]["clearRate"]) and _finite01(pp["CASUAL"]["clearRate"]) and _finite01(pp["SKILLED"]["clearRate"]) 			and pp["SKILLED"]["clearRate"] >= pp["CASUAL"]["clearRate"] and pp["CASUAL"]["clearRate"] >= pp["NOVICE"]["clearRate"]:
		_ok(true, msg + " (monotonic, informational)")
	else:
		print("  FINDING (L1 monotonicity miss at %d runs, reported not tuned): %s" % [SMOKE_RUNS, msg])

static func _corpus_raw(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CORPUS_RAW % id))["raw"]

static func _finite01(v) -> bool:
	return v != null and is_finite(float(v)) and float(v) >= 0.0 and float(v) <= 1.0

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
