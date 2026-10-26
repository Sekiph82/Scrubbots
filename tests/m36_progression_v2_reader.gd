extends SceneTree
## SB-M36-016 — progression v2 reader.
## Run: godot --headless --path . -s res://tests/m36_progression_v2_reader.gd
## Exits 0 on success, 1 on any failure.
##
## Proves:
##   - DifficultyProgressionV1 reads schema v1 and v2; any other schema (v3, none) still fails;
##   - level 311 EASY > level 11 EASY under both readers (values from the reader itself);
##   - CLAUDE.md 11.1 cadence for 1/10/11/111/300/310/311/1000/1001/1010, readers agree;
##   - recovery guards and challengeTolerance come from the loaded file;
##   - LevelDifficultyAnalyzerV2 defaults to v1 progression and, given V2_CONFIG_PATH, scores
##     its targetChallenge from the v2 lanes;
##   - v1/v2 progression and v2 model/analysis configs keep their sha256 pins.

const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const AnalyzerV2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const RAW := "res://coordination/sessions/M53-C002/evidence/holdout_raw/level_002_apple_raw.json"
const NS := [1, 10, 11, 111, 300, 310, 311, 1000, 1001, 1010]
const CLASSES := ["EASY", "VERY_HARD", "EASY", "EASY", "VERY_HARD", "VERY_HARD", "EASY", "VERY_HARD", "EASY", "VERY_HARD"]
const SLOTS := [1, 10, 1, 1, 10, 10, 1, 10, 1, 10]
## LF-normalised sha256 (Pack.content_sha256), pinned by SB-M36-013.
const FROZEN := {
	"res://data/config/level_progression_v1.json": "fe967a7867c8bb3a163cd08b6770dc71f148a4c31c64b025a917bdcab5118efd",
	"res://data/config/difficulty_score_model_v2.json": "efa5dd36d35423d8a3873a4020ba9ea46a0fee5cc934c187f3ca1191cb0155d9",
	"res://data/config/level_difficulty_analysis_v2.json": "84e7e5f98064df60ac09975e1bf8cf273bf1e8e52f3d367770d69c99a8c678e5",
}

var _cases := 0
var _fail := 0

func _initialize() -> void:
	var p1 = DifficultyProgressionV1.new()
	var p2 = DifficultyProgressionV1.new(DifficultyProgressionV1.V2_CONFIG_PATH)
	_s01_load(p1, p2)
	if p1.is_ok() and p2.is_ok():
		_s02_targets(p1, p2)
		_s03_cadence(p1, p2)
		_s04_guards(p1, p2)
		_s05_analyzer(p1, p2)
	_s06_frozen()
	_done()

func _s01_load(p1, p2) -> void:
	print("[s01 load]")
	_ok(p1.is_ok() and p1.model_version() == 1, "v1 reader ok, version 1")
	_ok(p2.is_ok() and p2.model_version() == 2, "v2 reader ok, version 2 (%s)" % p2.get_error())
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DifficultyProgressionV1.V2_CONFIG_PATH))
	data["schema"] = "scrubbots-level-progression/v3"
	var bad = _reader_for(data, "user://m36_progression_v3.json")
	_ok(not bad.is_ok() and bad.get_error() == "unexpected schema", "schema v3 rejected")
	data.erase("schema")
	bad = _reader_for(data, "user://m36_progression_none.json")
	_ok(not bad.is_ok() and bad.get_error() == "unexpected schema", "missing schema rejected")

func _s02_targets(p1, p2) -> void:
	print("[s02 targets]")
	var want := 13.8 + 9.0 * (1.0 - exp(-31.0 / 20.0))
	_ok(is_equal_approx(p2.target_challenge_for(311), want), "v2 target(311) = %.4f (want %.4f)" % [p2.target_challenge_for(311), want])
	_ok(p2.target_challenge_for(311) > p2.target_challenge_for(11), "v2 311 EASY %.2f > 11 EASY %.2f" % [p2.target_challenge_for(311), p2.target_challenge_for(11)])
	_ok(is_equal_approx(p1.target_challenge_for(311), 20.0 + 14.0 * (1.0 - exp(-31.0 / 20.0))), "v1 target(311) = 20+14P")
	_ok(p1.target_challenge_for(311) > p1.target_challenge_for(11), "v1 311 EASY %.2f > 11 EASY %.2f" % [p1.target_challenge_for(311), p1.target_challenge_for(11)])

func _s03_cadence(p1, p2) -> void:
	print("[s03 cadence]")
	for i in NS.size():
		var n: int = NS[i]
		for p in [p1, p2]:
			_ok(p.class_for(n) == CLASSES[i] and p.slot_for(n) == SLOTS[i], "n=%d %s slot %d" % [n, p.class_for(n), p.slot_for(n)])
		_ok(p1.class_for(n) == p2.class_for(n) and p1.slot_for(n) == p2.slot_for(n) and p1.role_for(n) == p2.role_for(n)
			and p1.novelty_target_for(n) == p2.novelty_target_for(n), "n=%d readers agree on class/slot/role/novelty" % n)

func _s04_guards(p1, p2) -> void:
	print("[s04 guards + tolerance]")
	_ok(_approx(_drops(p2), [9.6, 12.8, 9.6, 22.4]), "v2 minimum drops %s" % str(_drops(p2)))
	_ok(_approx(_drops(p1), [15.0, 20.0, 15.0, 35.0]), "v1 minimum drops %s" % str(_drops(p1)))
	_ok(_approx(_tol(p2), [2.2, 1.3, 3.2]), "v2 tolerance %s" % str(_tol(p2)))
	_ok(_approx(_tol(p1), [3.5, 2.0, 5.0]), "v1 tolerance %s" % str(_tol(p1)))

func _s05_analyzer(p1, p2) -> void:
	print("[s05 analyzer]")
	var a1 = AnalyzerV2.new()
	var a2 = AnalyzerV2.new(AnalyzerV2.CONFIG_PATH, DifficultyProgressionV1.V2_CONFIG_PATH)
	_ok(a1.is_ok() and int(a1.provenance()["progressionModelVersion"]) == 1, "default analyzer reads progression v1")
	_ok(a2.is_ok() and int(a2.provenance()["progressionModelVersion"]) == 2, "v2-progression analyzer reads progression v2")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RAW))["raw"]
	var t1: float = a1.score(raw, 311)["targetChallenge"]
	var t2: float = a2.score(raw, 311)["targetChallenge"]
	_ok(t1 == p1.target_challenge_for(311), "v1 analyzer target(311) %.4f = v1 reader" % t1)
	_ok(t2 == p2.target_challenge_for(311), "v2 analyzer target(311) %.4f = v2 reader" % t2)
	_ok(t1 != t2, "analyzer target differs between progressions")
	var v1 = AnalyzerV2.V1.new()
	_ok(v1.classify_window(3.0) == AnalyzerV2.V1.WINDOW_IN and v1.classify_window(3.0, p1.challenge_tolerance()) == AnalyzerV2.V1.WINDOW_IN,
		"delta 3.0 IN_DEFAULT_WINDOW under v1 tolerance")
	_ok(v1.classify_window(3.0, p2.challenge_tolerance()) == AnalyzerV2.V1.WINDOW_SOFT, "delta 3.0 SOFT under v2 tolerance")
	_ok(v1.classify_window(3.3, p2.challenge_tolerance()) == AnalyzerV2.V1.WINDOW_OUT, "delta 3.3 OUT under v2 tolerance")
	var s2: Dictionary = a2.score(raw, 311)
	_ok(s2["acceptanceWindow"] == v1.classify_window(s2["signedDelta"], p2.challenge_tolerance()), "v2 analyzer window %s uses v2 tolerance (delta %.2f)" % [s2["acceptanceWindow"], s2["signedDelta"]])
	var s1: Dictionary = a1.score(raw, 311)
	_ok(s1["acceptanceWindow"] == v1.classify_window(s1["signedDelta"]), "default analyzer window unchanged")

func _s06_frozen() -> void:
	print("[s06 frozen]")
	for path in FROZEN:
		_ok(Pack.content_sha256(path) == FROZEN[path], "%s unchanged" % path)

func _drops(p) -> Array:
	var out: Array = []
	for g in p.recovery_guards():
		out.append(float(g["minimumChallengeDrop"]))
	return out

func _tol(p) -> Array:
	var t: Dictionary = p.challenge_tolerance()
	return [float(t.get("defaultPlusMinus", -1)), float(t.get("preferredWhenPoolIsLarge", -1)), float(t.get("neverForceLabelOutsidePlusMinus", -1))]

static func _approx(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not is_equal_approx(float(a[i]), float(b[i])):
			return false
	return true

func _reader_for(data: Dictionary, path: String):
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	return DifficultyProgressionV1.new(path)

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M36 progression v2 reader: %s (%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases, _fail])
	quit(0 if _fail == 0 else 1)
