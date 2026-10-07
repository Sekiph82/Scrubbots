extends SceneTree
## SB-M53-C002-R01-001 R02 attribution check (QA-only, read-only).
## Re-scores a raw set with a given V2 config using the CURRENT analyzer code and writes the
## derived numbers at full precision, so the report can show:
##   old raw + old config  -> reproduces the OLD committed derived evidence (code unchanged), and
##   new raw + new config  -> reproduces the NEW committed derived evidence exactly;
## hence every derived delta comes only from the recovered raw precision.
##   godot --headless --path . -s res://tests/tools/m53_c002_refreeze_rescore.gd -- <config.json> <corpus_raw_dir> <holdout_raw_dir> <out.json>

const V2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const Cal = preload("res://tools/calibrate_difficulty_v2.gd")
const Tool1 = preload("res://tools/analyze_m53_first10.gd")
const Canon = preload("res://tools/m53_canonical_json.gd")

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var an = V2.new(a[0])
	var corpus := {}
	for spec in Cal.FIXTURES:
		var s: Dictionary = an.score(V1._read_json("%s/%s_raw.json" % [a[1], spec["id"]])["raw"])
		corpus[spec["id"]] = {"challengeScore": s["challengeScore"], "sessionLoad": s["sessionLoad"], "vector": s["vector"]}
	var hold := {}
	for spec in Tool1.LEVELS:
		var s: Dictionary = an.score(V1._read_json("%s/%s_raw.json" % [a[2], spec["id"]])["raw"], int(spec["order"]))
		hold[spec["id"]] = {"challengeScore": s["challengeScore"], "sessionLoad": s["sessionLoad"], "signedDelta": s["signedDelta"], "vector": s["vector"]}
	var f := FileAccess.open(a[3], FileAccess.WRITE)
	f.store_string(Canon.file_text({"config": a[0], "corpus": corpus, "holdout": hold}))
	f.close()
	print("RESCORED ", a[3])
	quit()
