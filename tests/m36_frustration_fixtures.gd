extends SceneTree
## SB-M36-017 — opt-in `difficulty_playtest.gd --frustration --fixtures` path.
## Run: godot --headless --path . -s res://tests/m36_frustration_fixtures.gd
## Exits 0 on success, 1 on any failure.
##
## Runs the tool as a subprocess at 1 run/profile on one EASY anchor fixture and checks the new
## output, that no default playtest/frustration output is written or touched, and the argument
## guards (the default path is reached only without --fixtures).

const Pack = preload("res://tools/build_m52_first_10_pack.gd")
const Playtest = preload("res://tools/difficulty_playtest.gd")

const FIXTURE := "easy_vstripes3_24"
const OUT := Playtest.OUT_DIR_FIXTURES + "/frustration_" + FIXTURE + "_r1.json"
const DEFAULT_OUTPUTS := [Playtest.OUT_PATH, Playtest.OUT_PATH_V2, Playtest.OUT_PATH_V2_PROG_V2,
	Playtest.OUT_PATH_FRUSTRATION, Playtest.OUT_PATH_FRUSTRATION_MD]

var _cases := 0
var _fail := 0

func _initialize() -> void:
	var before := _default_state()
	var r := _tool(["--frustration", "--runs", "1", "--fixtures", FIXTURE])
	_ok(r["code"] == 0 and r["out"].contains("FRUSTRATION_FIXTURES OK levels=1"), "fixtures run exits 0 (%d)" % r["code"])
	var d = JSON.parse_string(FileAccess.get_file_as_string(OUT)) if FileAccess.file_exists(OUT) else null
	_ok(d is Dictionary, "writes %s" % OUT)
	if d is Dictionary:
		var lv: Dictionary = d["levels"][0]
		var res: Dictionary = lv["result"]
		_ok(d["task"] == "SB-M36-017" and d["status"] == "PROVISIONAL_SIMULATED_HUMAN", "task/status labels")
		_ok(lv["id"] == FIXTURE and int(res["slot"]) == 1 and int(res["runsPerProfile"]) == 1, "EASY anchor -> slot 1, 1 run/profile")
		_ok(res["perProfile"].keys().size() == 3 and res["F"] != null and float(res["F"]) >= 0.0 and float(res["F"]) <= 100.0, "3 profiles, F in 0..100 (%s)" % str(res["F"]))
		_ok(float(res["sessionLoad"]) > 0.0 and res["inputs"]["choiceOpacity"] != null, "Session Load / opacity from committed raw")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT))
	_ok(_default_state() == before, "default playtest/frustration outputs untouched")
	_ok(_tool(["--fixtures", FIXTURE])["code"] == 1, "--fixtures without --frustration -> exit 1")
	_ok(_tool(["--frustration", "--runs", "1", "--fixtures", "no_such_fixture"])["code"] == 1, "unknown fixture -> exit 1")
	_ok(_tool(["--model", "v1", "--frustration", "--fixtures", FIXTURE])["code"] == 1, "--model v1 still rejected before --fixtures")
	_ok(_default_state() == before, "default outputs still untouched after guard runs")
	print("M36_FRUSTRATION_FIXTURES %s (%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases, _fail])
	quit(0 if _fail == 0 else 1)

func _default_state() -> Array:
	var s: Array = []
	for p in DEFAULT_OUTPUTS:
		s.append([p, Pack.content_sha256(p) if FileAccess.file_exists(p) else "", FileAccess.get_modified_time(p)])
	return s

func _tool(args: Array) -> Dictionary:
	var out: Array = []
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://tools/difficulty_playtest.gd", "--"]
	a.append_array(args)
	var code := OS.execute(OS.get_executable_path(), a, out, true)
	return {"code": code, "out": "\n".join(out)}

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if cond:
		print("  ok   %s" % msg)
	else:
		_fail += 1
		print("  FAIL %s" % msg)
