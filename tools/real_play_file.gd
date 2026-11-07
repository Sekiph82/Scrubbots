extends SceneTree
## SB-STUDIO-REAL-PLAY-GATE file mode of the real-play check (model real_play_v1, see
## scripts/gameplay/solver/real_play_driver.gd): verifies a level JSON + supply-plan JSON that
## live OUTSIDE the repo (the Level Factory Studio's release-pool gate) through the same real
## ProductionGameplayHost path as the catalog at the canonical 1/60 simulation step, without
## registering anything in LevelCatalog. --search explores supply-column sequences only at
## 1/60 and freshly replays the exact winning sequence. Writes only --out; never edits inputs.
##
## Verdicts / exit codes: WON_CANONICAL 0; LOST, SEARCH_EXHAUSTED, SEARCH_BUDGET 1;
## INVALID_INPUT 2. The last stdout line is always "REAL_PLAY_RESULT <compact JSON>"
## (schema scrubbots.real_play_file_result.v2).
##
## Run: godot --headless --path <ScrubBots repo> -s res://tools/real_play_file.gd -- --level-file <abs level.json> --plan-file <abs plan.json> [--search] [--out <abs result.json>]

const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const USAGE := "godot --headless --path <ScrubBots repo> -s res://tools/real_play_file.gd -- --level-file <abs level.json> --plan-file <abs plan.json> [--search] [--source-sha256 <sha256>] [--out <abs result.json>]"
const SCHEMA := "scrubbots.real_play_file_result.v2"
const MARKER := "REAL_PLAY_RESULT "
const EXIT := {"WON_CANONICAL": 0, "LOST": 1, "SEARCH_EXHAUSTED": 1, "SEARCH_BUDGET": 1, "INVALID_INPUT": 2}
const VALUE_ARGS := ["--level-file", "--plan-file", "--out", "--source-sha256"]

var _out_path := ""

func _initialize() -> void:
	await process_frame
	var res := {
		"schema": SCHEMA, "model": RealPlayDriver.MODEL, "mode": "canonical_60hz", "canonicalDt": "1/60",
		"runId": "real-play-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()],
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"verdict": "INVALID_INPUT", "exitCode": 2,
		"searched": false, "levelFile": null, "planFile": null, "levelId": null, "planSha256": null,
		"levelSha256": null, "gameCommit": _game_commit(), "sourceSha256": null, "planClicks": [], "perDt": {}, "search": null,
		"searchedClicks": null, "error": null,
	}
	var err: String = await _run(res)
	if not err.is_empty():
		res["verdict"] = "INVALID_INPUT"
		res["error"] = err
		if err.begins_with("usage:"):
			print("Usage: " + USAGE)
	res["exitCode"] = EXIT[res["verdict"]]
	if not _out_path.is_empty():
		var f := FileAccess.open(_out_path, FileAccess.WRITE)
		if f == null:
			res["verdict"] = "INVALID_INPUT"
			res["exitCode"] = 2
			res["error"] = "--out not writable: %s (error %d)" % [_out_path, FileAccess.get_open_error()]
		else:
			f.store_string(JSON.stringify(res, "\t", true) + "\n")
			f.close()
	print(MARKER + JSON.stringify(res, "", true))
	quit(res["exitCode"])

## Validate, verify, optionally search. Returns "" or the INVALID_INPUT error text.
func _run(res: Dictionary) -> String:
	var args := {}
	var argv := OS.get_cmdline_user_args()
	var i := 0
	while i < argv.size():
		var a: String = argv[i]
		if a != "--search" and a != "--canonical-only" and not VALUE_ARGS.has(a):
			return "usage: unknown argument %s" % a
		if args.has(a):
			return "usage: duplicate argument %s" % a
		if a == "--search" or a == "--canonical-only":
			args[a] = true
		elif i + 1 >= argv.size() or String(argv[i + 1]).begins_with("--"):
			return "usage: %s needs a value" % a
		else:
			i += 1
			args[a] = argv[i]
		i += 1
	if not args.has("--level-file") or not args.has("--plan-file"):
		return "usage: --level-file and --plan-file are required"
	var level_file: String = args["--level-file"]
	var plan_file: String = args["--plan-file"]
	res["levelFile"] = level_file
	res["planFile"] = plan_file
	if args.has("--out"):
		var e := _out_error(args["--out"])
		if not e.is_empty():
			return e
		_out_path = args["--out"]
	for p in [level_file, plan_file]:
		var e := _path_error(p)
		if not e.is_empty():
			return e
	res["levelSha256"] = RealPlayDriver.plan_sha256(level_file)
	res["planSha256"] = RealPlayDriver.plan_sha256(plan_file)
	if args.has("--source-sha256"):
		var source_sha := String(args["--source-sha256"])
		if not RegEx.create_from_string("^[0-9a-f]{64}$").search(source_sha):
			return "--source-sha256 must be a lowercase SHA-256 digest"
		res["sourceSha256"] = source_sha
	var lr = LevelLoader.load_from_path(level_file)
	if not lr.is_ok():
		return "level rejected: %s" % "; ".join(lr.errors)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(plan_file)) != OK:
		return "plan malformed JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()]
	var pr := SupplyPlanLoader.load_engine(plan_file, lr.level_data)
	if not pr["ok"]:
		return "plan rejected: %s" % pr["error"]
	res["levelId"] = String(pr["plan"]["levelId"])
	var raw = pr["plan"].get("intendedColumnClicks", null)
	if not (raw is Array) or raw.is_empty():
		return "plan has no intendedColumnClicks (a non-empty array of ints is required)"
	var clicks: Array = []
	for c in raw:
		if not (c is int or (c is float and c == floorf(c))):
			return "intendedColumnClicks has a non-integer entry %s" % str(c)
		clicks.append(int(c))
	res["planClicks"] = clicks
	var src := {"level_path": level_file, "supply_plan_path": plan_file}
	var v: Dictionary = await RealPlayDriver.verify(get_root(), src, clicks)
	var canonical_result: Dictionary = v["results"][RealPlayDriver.CANONICAL_DT_LABEL]
	if canonical_result.has("error"):
		return "host build failed: %s" % canonical_result["error"]
	res["perDt"][RealPlayDriver.CANONICAL_DT_LABEL] = _dt_result(canonical_result)
	res["verdict"] = "WON_CANONICAL" if v["won"] else "LOST"
	if args.has("--search") and not v["won"]:
		var s: Dictionary = await RealPlayDriver.search(get_root(), src, clicks)
		res["searched"] = true
		res["search"] = {"status": s["status"], "nodes": int(s["nodes"]), "nodeBudget": int(s.get("node_budget", RealPlayDriver.NODE_BUDGET)),
			"canonicalWin": bool(s.get("canonical_win", false))}
		if s["status"] == "SOLVED":
			res["searchedClicks"] = s["clicks"].map(func(c): return int(c))
			# Search nodes are disposable. Rebuild a fresh ProductionGameplayHost and replay
			# the exact selected sequence before declaring a canonical solver WIN.
			var replay: Dictionary = await RealPlayDriver.play_level(get_root(), src, res["searchedClicks"])
			if replay.has("error"):
				return "fresh-host replay failed: %s" % replay["error"]
			res["perDt"][RealPlayDriver.CANONICAL_DT_LABEL] = _dt_result(replay)
			res["search"]["canonicalWin"] = bool(replay.get("won", false))
			res["verdict"] = "WON_CANONICAL" if replay.get("won", false) else "LOST"
		else:
			res["verdict"] = s["status"]
	return ""

func _dt_result(r: Dictionary) -> Dictionary:
	var won: bool = r["won"]
	var f: Dictionary = r["final"]
	return {
		"won": won, "frames": int(r["frames"]), "clicksPlaced": int(r["clicks_placed"]), "stuck": bool(r["stuck"]),
		"stuckClickIndex": null if won else int(r["clicks_placed"]),
		"final": {"activeRobots": int(f["active"]), "boardResidue": int(f["board_residue"]), "targetsCleared": won,
			"supplyExhausted": f["supply_exhausted"], "slotsEmpty": f["slots_empty"], "terminal": f["terminal"]},
		"slots": null if won else r["slots"],
		"rejected": null if r["rejected"].is_empty() else r["rejected"],
	}

## Absolute filesystem path only (no res:// / user://), existing and readable.
func _path_error(p: String) -> String:
	if p.begins_with("res://") or p.begins_with("user://"):
		return "path must be an absolute filesystem path, not %s" % p
	if not p.is_absolute_path():
		return "path is not absolute: %s" % p
	if not FileAccess.file_exists(p):
		return "file missing: %s" % p
	if FileAccess.open(p, FileAccess.READ) == null:
		return "file unreadable: %s (error %d)" % [p, FileAccess.get_open_error()]
	return ""

## --out: absolute, outside the repo, parent dir present.
func _out_error(p: String) -> String:
	if p.begins_with("res://") or p.begins_with("user://") or not p.is_absolute_path():
		return "--out must be an absolute filesystem path: %s" % p
	var repo := _norm(ProjectSettings.globalize_path("res://"))
	if (_norm(p) + "/").begins_with(repo + "/"):
		return "--out is inside the repo: %s" % p
	if not DirAccess.dir_exists_absolute(p.get_base_dir()):
		return "--out parent directory missing: %s" % p.get_base_dir()
	return ""

func _norm(p: String) -> String:
	return p.replace("\\", "/").simplify_path().trim_suffix("/").to_lower()

func _game_commit() -> String:
	var out: Array = []
	if OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], out) != 0 or out.is_empty():
		return "unknown"
	var sha := String(out[0]).strip_edges()
	return sha if sha.length() == 40 else "unknown"
