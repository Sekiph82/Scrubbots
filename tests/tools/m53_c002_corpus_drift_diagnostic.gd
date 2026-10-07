extends SceneTree
## SB-M53-C002-R01-001 diagnostic (QA-only, never shipped; changes nothing).
## For each corpus fixture: a fresh V2 measurement vs the committed corpus raw, normalized
## EXACTLY like tests/m53_c002_difficulty_calibration.gd `_norm` (JSON round trip, only the
## volatile `timing` removed). Every differing leaf records the committed text, the fresh text
## and the fresh value's exact double (var_to_str), so the float->text step can be checked.
##   godot --headless --path . -s res://tests/tools/m53_c002_corpus_drift_diagnostic.gd -- <out.json> [fixture ...]
## No fixture list = the whole committed corpus.

const Cal = preload("res://tools/calibrate_difficulty_v2.gd")
const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const V2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

var _diffs: Array = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0]
	var ids: Array = args.slice(1)
	if ids.is_empty():
		for f in DirAccess.get_files_at(Cal.CORPUS_RAW_DIR):
			if f.ends_with("_raw.json"):
				ids.append(f.trim_suffix("_raw.json"))
		ids.sort()
	var report := {"schema": "scrubbots.m53.c002_r01.corpus_drift_diagnostic.v1", "engine": Engine.get_version_info()["string"],
		"os": OS.get_name(), "normalization": "JSON round trip; key 'timing' removed (identical to the test _norm)", "fixtures": {}}
	for id in ids:
		_diffs = []
		var lvl = Cal.load_fixture(id)
		var make := func(): return SupplyPlanLoader.load_engine(Cal.fixture_supply_path(id), lvl)["engine"]
		var exact: Dictionary = V2.new().measure(lvl, make)
		var fresh: Dictionary = JSON.parse_string(JSON.stringify(exact))
		var committed: Dictionary = JSON.parse_string(JSON.stringify(V1._read_json("%s/%s_raw.json" % [Cal.CORPUS_RAW_DIR, id])["raw"]))
		fresh.erase("timing")
		committed.erase("timing")
		_walk("raw", committed, fresh, exact)
		report["fixtures"][id] = _diffs
		print("FIXTURE %s diffs=%d %s" % [id, _diffs.size(), JSON.stringify(_diffs).left(300)])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t") + "\n")
	f.close()
	print("WROTE ", out_path)
	quit()

func _walk(path: String, a, b, ex) -> void:
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		var keys := {}
		for k in a:
			keys[k] = true
		for k in b:
			keys[k] = true
		var ks: Array = keys.keys()
		ks.sort()
		for k in ks:
			if not a.has(k) or not b.has(k):
				_diffs.append({"path": "%s/%s" % [path, k], "kind": "key_presence", "in_committed": a.has(k), "in_fresh": b.has(k)})
			else:
				_walk("%s/%s" % [path, k], a[k], b[k], ex[k] if typeof(ex) == TYPE_DICTIONARY and ex.has(k) else null)
	elif typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		if a.size() != b.size():
			_diffs.append({"path": path, "kind": "array_length", "committed": a.size(), "fresh": b.size()})
		for i in mini(a.size(), b.size()):
			_walk("%s[%d]" % [path, i], a[i], b[i], ex[i] if typeof(ex) == TYPE_ARRAY and i < ex.size() else null)
	elif JSON.stringify(a) != JSON.stringify(b):
		_diffs.append({"path": path, "kind": "value", "committed_text": JSON.stringify(a), "fresh_text": JSON.stringify(b), "fresh_exact": var_to_str(ex)})
