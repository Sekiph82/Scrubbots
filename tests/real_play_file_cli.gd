extends SceneTree
## SB-STUDIO-REAL-PLAY-GATE — file mode of the real-play check (tools/real_play_file.gd), run
## as a subprocess exactly as the Level Factory Studio runs it, on copies of the current L22
## level + plan under an absolute dir outside the repo (globalized user://):
##   - valid: current clicks -> exit 0 WON_ROBUST at 1/30, 1/60, 1/120; --out == stdout JSON;
##   - lost: the pre-080 L22 clicks -> exit 1 LOST with the stuck click and slot state;
##   - search: the same with --search -> exit 0 WON_ROBUST + robust searchedClicks, which win
##     at every dt when written into a plan copy and re-run without --search;
##   - invalid: malformed level, wrong levelId, missing/empty clicks, relative / res:// /
##     missing paths, unknown arg, --out inside the repo -> exit 2 INVALID_INPUT + error;
##   - no_repo_writes: git status --porcelain identical before/after every run;
##   - catalog_regression: catalog play of L22 still WON and identical to an in-process
##     file-source play (shared host path); LevelCatalog entry count unchanged.
## Never boots main.tscn.
##
## Run: godot --headless --path . -s res://tests/real_play_file_cli.gd

const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

## L22 intendedColumnClicks as imported from the Studio (== provenance originalIntendedColumnClicks).
const OLD_L22 := [1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 3, 3, 5, 5, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5]
const L22 := "level_022_crab"
const LEVEL_SRC := "res://data/levels/level_022_crab.json"
const PLAN_SRC := "res://data/levels/supply/level_022_crab_supply_v1.json"
const MARKER := "REAL_PLAY_RESULT "

var EXPECTED_CASES := ["valid", "lost", "search", "invalid", "no_repo_writes", "catalog_regression"]

var _fail := 0
var _completed: Dictionary = {}
var _repo := ""
var _dir := ""
var _level := ""
var _plan := ""

func _initialize() -> void:
	await process_frame
	_repo = ProjectSettings.globalize_path("res://").trim_suffix("/")
	_dir = ProjectSettings.globalize_path("user://real_play_file_cli")
	DirAccess.make_dir_recursive_absolute(_dir)
	_level = _write("level.json", FileAccess.get_file_as_string(LEVEL_SRC))
	_plan = _write("plan.json", FileAccess.get_file_as_string(PLAN_SRC))
	var cat_before := _catalog_count()
	var git_before := _git_status()
	_valid()
	_lost()
	_search()
	_invalid()
	_ok(_git_status() == git_before, "git status --porcelain identical before and after every file-mode run")
	_ok(not FileAccess.file_exists(_repo + "/real_play_file_cli_out.json"), "the in-repo --out target was never created")
	_completed["no_repo_writes"] = true
	await _catalog_regression(cat_before)
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir + "/" + f)
	DirAccess.remove_absolute(_dir)
	_done()

func _valid() -> void:
	print("[valid: current L22 level + plan copies]")
	var out := _dir + "/valid_out.json"
	var r := _cli(["--level-file", _level, "--plan-file", _plan, "--out", out])
	var j: Dictionary = r["json"]
	var per: Dictionary = j.get("perDt", {})
	_ok(r["exit"] == 0 and j.get("verdict") == "WON_ROBUST" and j.get("exitCode") == 0, "exit 0, WON_ROBUST (%s)" % str(j.get("verdict")))
	_ok(per.keys().size() == 3 and ["1/30", "1/60", "1/120"].all(func(k): return per.has(k) and per[k]["won"] == true), "perDt 1/30, 1/60, 1/120 all won")
	var file = JSON.parse_string(FileAccess.get_file_as_string(out)) if FileAccess.file_exists(out) else null
	_ok(file is Dictionary and file == j, "--out file parses and equals the REAL_PLAY_RESULT stdout JSON")
	_ok(j.get("planSha256") == RealPlayDriver.plan_sha256(_plan) and j.get("levelSha256") == RealPlayDriver.plan_sha256(_level), "planSha256/levelSha256 == RealPlayDriver.plan_sha256 of the copies")
	_ok(j.get("model") == "real_play_v1" and j.get("schema") == "scrubbots.real_play_file_result.v1" and j.get("levelId") == L22 and j.get("searched") == false and j.get("error") == null, "model, schema, levelId, searched false, error null")
	_ok(String(j.get("gameCommit", "")).length() == 40, "gameCommit is a git sha (%s)" % str(j.get("gameCommit")))
	_ok(not RegEx.create_from_string("\\d\\.0[,\\]}]").search(r["line"]), "ints stay ints in the result line")
	_completed["valid"] = true

func _lost() -> void:
	print("[lost: pre-080 L22 clicks]")
	var plan := _write("plan_old.json", _splice_clicks(FileAccess.get_file_as_string(PLAN_SRC), OLD_L22))
	var r := _cli(["--level-file", _level, "--plan-file", plan])
	var j: Dictionary = r["json"]
	var d: Dictionary = j.get("perDt", {}).get("1/60", {})
	var idx = d.get("stuckClickIndex")
	_ok(r["exit"] == 1 and j.get("verdict") == "LOST" and j.get("exitCode") == 1, "exit 1, LOST (%s)" % str(j.get("verdict")))
	_ok(idx is float and idx == floorf(idx) and idx >= 1 and idx <= OLD_L22.size() and d.get("won") == false and d.get("stuck") == true,
		"1/60 stuck after click %s/%d" % [str(idx), OLD_L22.size()])
	_ok(d.get("slots") is Array and d["slots"].size() == 5, "slot state reported at the stop")
	_ok(j.get("searchedClicks") == null and j.get("search") == null and j.get("searched") == false and j.get("planClicks") == OLD_L22.map(func(c): return float(c)), "no search, planClicks == old clicks")
	_completed["lost"] = true

func _search() -> void:
	print("[search: pre-080 L22 clicks with --search]")
	var plan := _dir + "/plan_old.json"
	var r := _cli(["--level-file", _level, "--plan-file", plan, "--search"])
	var j: Dictionary = r["json"]
	var sc = j.get("searchedClicks")
	var s = j.get("search")
	_ok(r["exit"] == 0 and j.get("verdict") == "WON_ROBUST" and j.get("searched") == true, "exit 0, WON_ROBUST, searched (%s)" % str(j.get("verdict")))
	_ok(sc is Array and not sc.is_empty() and sc.all(func(c): return c is float and c == floorf(c)), "searchedClicks non-empty ints")
	_ok(s is Dictionary and s.get("status") == "SOLVED" and s.get("robust") == true and s.get("nodeBudget") == RealPlayDriver.NODE_BUDGET, "search SOLVED robust in %s nodes" % str(s.get("nodes") if s is Dictionary else null))
	if sc is Array:
		var fixed := _write("plan_searched.json", _splice_clicks(FileAccess.get_file_as_string(PLAN_SRC), sc))
		var r2 := _cli(["--level-file", _level, "--plan-file", fixed])
		_ok(r2["exit"] == 0 and r2["json"].get("verdict") == "WON_ROBUST", "searched clicks re-run without --search: exit 0 WON_ROBUST")
	_completed["search"] = true

func _invalid() -> void:
	print("[invalid inputs -> exit 2 INVALID_INPUT]")
	var plan_text := FileAccess.get_file_as_string(PLAN_SRC)
	var bad_level := _write("bad_level.json", "{\"id\": \"level_022_crab\", not json")
	var wrong_id := _write("plan_wrong_id.json", plan_text.replace("\"levelId\": \"%s\"" % L22, "\"levelId\": \"level_999_nope\""))
	var no_clicks := _write("plan_no_clicks.json", plan_text.replace("\"intendedColumnClicks\"", "\"notIntendedColumnClicks\""))
	var empty_clicks := _write("plan_empty_clicks.json", _splice_clicks(plan_text, []))
	var cases := {
		"malformed level JSON": ["--level-file", bad_level, "--plan-file", _plan],
		"plan levelId mismatch": ["--level-file", _level, "--plan-file", wrong_id],
		"plan without intendedColumnClicks": ["--level-file", _level, "--plan-file", no_clicks],
		"plan with empty intendedColumnClicks": ["--level-file", _level, "--plan-file", empty_clicks],
		"relative path": ["--level-file", "data/levels/level_022_crab.json", "--plan-file", _plan],
		"res:// path": ["--level-file", LEVEL_SRC, "--plan-file", _plan],
		"nonexistent file": ["--level-file", _dir + "/missing.json", "--plan-file", _plan],
		"unknown argument": ["--level-file", _level, "--plan-file", _plan, "--regen"],
		"--out inside the repo": ["--level-file", _level, "--plan-file", _plan, "--out", _repo + "/real_play_file_cli_out.json"],
	}
	for name in cases:
		var r := _cli(cases[name])
		var j: Dictionary = r["json"]
		_ok(r["exit"] == 2 and j.get("verdict") == "INVALID_INPUT" and j.get("exitCode") == 2 and String(j.get("error", "")).length() > 0 and r["clean"],
			"%s: exit %d %s (%s)" % [name, r["exit"], str(j.get("verdict")), str(j.get("error"))])
	_completed["invalid"] = true

func _catalog_regression(cat_before: int) -> void:
	print("[catalog_regression: %s catalog vs in-process file source]" % L22)
	var clicks := RealPlayDriver.clicks_for(L22, PLAN_SRC, {})
	var a: Dictionary = await RealPlayDriver.play_level(get_root(), L22, clicks)
	var b: Dictionary = await RealPlayDriver.play_level(get_root(), {"level_path": _level, "supply_plan_path": _plan}, clicks)
	_ok(a.get("won", false) and a.get("rejected", {}).is_empty(), "catalog play_level(%s) WON at 1/60 in %d frames" % [L22, int(a.get("frames", 0))])
	_ok(b.get("won", false) and b["frames"] == a["frames"] and b["cleared_sequence"] == a["cleared_sequence"], "file-source play identical to catalog play (frames, cleared sequence)")
	_ok(_catalog_count() == cat_before and cat_before > 0, "LevelCatalog entry count unchanged (%d)" % cat_before)
	_completed["catalog_regression"] = true

## Run the tool as a subprocess. {exit, json, line, clean}.
func _cli(args: Array) -> Dictionary:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", _repo, "-s", "res://tools/real_play_file.gd", "--"] + args, out, true)
	var text: String = "\n".join(out)
	var line := ""
	for l in text.split("\n"):
		if l.begins_with(MARKER):
			line = l.strip_edges()
	var j = JSON.parse_string(line.trim_prefix(MARKER)) if not line.is_empty() else null
	var clean := not (text.contains("SCRIPT ERROR") or text.contains("Parse Error") or text.contains("Program crashed"))
	if j == null or not clean:
		print("    subprocess output:\n%s" % text)
	return {"exit": code, "json": j if j is Dictionary else {}, "line": line, "clean": clean}

## Replace only the intendedColumnClicks array text.
func _splice_clicks(text: String, clicks: Array) -> String:
	var items := ", ".join(clicks.map(func(c): return str(int(c))))
	return RegEx.create_from_string("\"intendedColumnClicks\": \\[[^\\]]*\\]").sub(text, "\"intendedColumnClicks\": [%s]" % items)

func _write(name: String, text: String) -> String:
	var p := _dir + "/" + name
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return p

func _catalog_count() -> int:
	var cat = LevelCatalog.new()
	return cat.get_entries_ordered().size() if cat.load_manifest().ok else -1

func _git_status() -> String:
	var out: Array = []
	OS.execute("git", ["-C", _repo, "status", "--porcelain"], out)
	return "\n".join(out)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("REAL PLAY FILE CLI: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
