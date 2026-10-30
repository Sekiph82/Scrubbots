extends SceneTree
## SB-M43-122 — RANKS tab = personal rank ladder (owner 2026-10-31, "personal rank").
## PersonalRank data + helper, the live BottomNav tab on the real app root, the screen
## reflecting the save, the L40 gate on a fresh FTUE profile, read-only, no network.
##
## Run: godot --headless --path . -s res://tests/m43_personal_ranks.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const PersonalRank = preload("res://scripts/progression/personal_rank.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

var EXPECTED_CASES := [
	"p01_data_valid", "p02_invalid_fail_closed", "p03_for_cleared_boundaries", "p04_tab_live_opens_closes",
	"p05_screen_matches_save", "p06_fresh_profile_gate", "p07_read_only", "p08_no_network",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	_p01()
	_p02()
	_p03()
	await _p04()
	await _p05()
	await _p06()
	await _p07()
	_p08()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _p01() -> void:
	print("[p01 personal_ranks_v1.json loads: ascending integer tiers, first 0]")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PersonalRank.PATH))
	_ok(d["schema"] == PersonalRank.SCHEMA and int(d["version"]) == 1 and d["metric"] == "campaign_levels_cleared", "schema / version 1 / metric")
	var t := PersonalRank.load_tiers()
	var asc := true
	for i in range(1, t.size()):
		asc = asc and int(t[i]["min_cleared"]) > int(t[i - 1]["min_cleared"])
	_ok(t.size() == d["tiers"].size() and t.size() >= 2 and int(t[0]["min_cleared"]) == 0 and asc, "%d tiers, strictly ascending, first 0" % t.size())
	_ok(t.all(func(x): return UiText.EN.has(x["name_key"])), "every tier name is a UiText key")
	_complete("p01_data_valid")

func _p02() -> void:
	print("[p02 corrupted / unsorted table fails closed, never crashes]")
	var ok := {"schema": PersonalRank.SCHEMA, "version": 1, "metric": "campaign_levels_cleared",
		"tiers": [{"id": "a", "name_key": "RANK_BRONZE", "min_cleared": 0}, {"id": "b", "name_key": "RANK_SILVER", "min_cleared": 5}]}
	_ok(not PersonalRank.load_tiers(_write(JSON.stringify(ok))).is_empty(), "control table loads")
	var bad := []
	for mut in ["unsorted", "first_not_zero", "dup", "fraction", "string_min", "metric", "schema", "empty"]:
		var c: Dictionary = ok.duplicate(true)
		match mut:
			"unsorted": c["tiers"][1]["min_cleared"] = 0
			"first_not_zero": c["tiers"][0]["min_cleared"] = 1
			"dup": c["tiers"][1]["id"] = "a"
			"fraction": c["tiers"][1]["min_cleared"] = 5.5
			"string_min": c["tiers"][1]["min_cleared"] = "5"
			"metric": c["metric"] = "xp"
			"schema": c["schema"] = "x"
			"empty": c["tiers"] = []
		bad.append(_write(JSON.stringify(c)))
	bad.append(_write("{not json"))
	bad.append("user://__missing_personal_ranks.json")
	_ok(bad.all(func(p): return PersonalRank.load_tiers(p).is_empty() and PersonalRank.for_cleared(10, p).is_empty()), "%d bad tables -> [] / {}" % bad.size())
	_complete("p02_invalid_fail_closed")

func _p03() -> void:
	print("[p03 for_cleared: 0, thresholds, threshold-1, above top, negative]")
	var t := PersonalRank.load_tiers()
	var r0 := PersonalRank.for_cleared(0)
	_ok(r0["index"] == 0 and r0["id"] == t[0]["id"] and r0["next_id"] == t[1]["id"] and r0["into"] == 0 and r0["span"] == int(t[1]["min_cleared"]), "0 -> first tier %s" % str(r0))
	var good := true
	for i in range(1, t.size()):
		var m := int(t[i]["min_cleared"])
		var at := PersonalRank.for_cleared(m)
		var below := PersonalRank.for_cleared(m - 1)
		good = good and at["index"] == i and at["into"] == 0 and below["index"] == i - 1 and below["into"] == below["span"] - 1
	_ok(good, "exact threshold -> that tier with into 0; threshold-1 -> previous tier, one short")
	var top := PersonalRank.for_cleared(100000)
	_ok(top["index"] == t.size() - 1 and top["next_id"] == "" and top["next_min"] == -1 and top["span"] == 0, "far above top -> top tier, no next, no span %s" % str(top))
	_ok(PersonalRank.for_cleared(-5) == r0, "-5 clamps to the first tier")
	_complete("p03_for_cleared_boundaries")

func _p04() -> void:
	print("[p04 real app root: RANKS tab live, opens 'ranks', close returns HOME]")
	await _boot("p04", -1)
	var b: Button = _root.get_home().get_region("Nav_leaderboard")
	_ok(not b.disabled and b.tooltip_text == "" and b.text == UiText.t("HOME_NAV_LEADERBOARD"), "grandfathered save: RANKS enabled, no tooltip")
	b.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "ranks" and _top().find_child("Title", true, false) != null, "press -> ranks popup")
	_root.get_modal_stack().top()._on_action("close")
	await _frames(3)
	_ok(_root.get_modal_stack().depth() == 0 and _root.get_navigation().current() == NavigationController.Route.HOME, "close -> HOME, no modal")
	_complete("p04_tab_live_opens_closes")

func _p05() -> void:
	print("[p05 shown rank / next line match for_cleared(N) of the save]")
	await _boot("p05", -1)
	var a = _root.get_app_state()
	var t := PersonalRank.load_tiers()
	_ok(_shown(a, t, 0), "0 cleared")
	for n in range(1, int(t[1]["min_cleared"]) + 3):
		a.progression.record_win(n)
	_ok(_shown(a, t, int(t[1]["min_cleared"]) + 2), "%d cleared" % (int(t[1]["min_cleared"]) + 2))
	var top := int(t[-1]["min_cleared"])
	for n in range(int(t[1]["min_cleared"]) + 3, top + 1):
		a.progression.record_win(n)
	_ok(_shown(a, t, top) and _root.get_modal_stack().top().find_child("NextMeter", true, false).bar.ratio == 1.0, "%d cleared: top rank line, full bar" % top)
	_complete("p05_screen_matches_save")

func _p06() -> void:
	print("[p06 fresh FTUE profile: RANKS locked until L40, then live]")
	await _boot("p06", 1)
	var a = _root.get_app_state()
	var h = _root.get_home()
	var b: Button = h.get_region("Nav_leaderboard")
	_ok(a.economy.ftue.is_new_profile() and b.disabled and b.tooltip_text == UiText.t("HOME_UNLOCKS_AT_LEVEL", [a.feature_unlock_level("ranks")]) and a.feature_unlock_level("ranks") == 40, "L1: disabled, 'unlocks at level 40'")
	while a.progression.current_level() < 40:
		a.progression.record_win(a.progression.current_level())
	h.refresh()
	_ok(not b.disabled and b.tooltip_text == "", "L40: enabled, no tooltip")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	b.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "ranks", "L40: press opens ranks")
	_complete("p06_fresh_profile_gate")

func _p07() -> void:
	print("[p07 opening / closing the screen changes no economy or save state]")
	await _boot("p07", -1)
	var a = _root.get_app_state()
	for n in range(1, 31):
		a.progression.record_win(n)
	var eco: Dictionary = a.economy.snapshot()
	var done := int(a.progression.completed_count())
	var lvl := int(a.progression.current_level())
	_root.get_home().get_region("Nav_leaderboard").pressed.emit()
	await _frames(2)
	var opened := _top_id()
	_root.get_modal_stack().top()._on_action("close")
	await _frames(2)
	_ok(opened == "ranks" and a.economy.snapshot() == eco and a.progression.completed_count() == done and a.progression.current_level() == lvl, "snapshot / progression unchanged")
	_complete("p07_read_only")

func _p08() -> void:
	print("[p08 no network / other-player scoring in the ladder code]")
	var src := FileAccess.get_file_as_string("res://scripts/ui/profile/profile_screens.gd")
	var body := src.substr(src.find("static func open_ranks"))
	body = body.substr(0, body.find("\n# ----"))
	var helper := FileAccess.get_file_as_string("res://scripts/progression/personal_rank.gd")
	var hits := []
	for w in ["HTTPRequest", "leaderboard_score", "ranking", "http", "friend"]:
		for pair in [["personal_rank.gd", helper], ["open_ranks", body]]:
			if String(pair[1]).to_lower().contains(w.to_lower()):
				hits.append("%s:%s" % [pair[0], w])
	_ok(body.length() > 200 and hits.is_empty(), "no network / scoring words %s" % str(hits))
	_complete("p08_no_network")

# ------------------------------------------------------------------ helpers ----

## Opens the screen and checks CurrentRank / NextMeter caption / ladder marks against for_cleared(n).
func _shown(a, t: Array, n: int) -> bool:
	_root.get_modal_stack().clear("test")
	var r := PersonalRank.for_cleared(n)
	_root.get_home().get_region("Nav_leaderboard").pressed.emit()
	var p = _top()
	if p == null or p.popup_id != "ranks":
		return false
	var cap: Label = p.find_child("NextMeter", true, false).caption
	var want_next := UiText.t("RANKS_TOP") if r["next_id"] == "" else UiText.t("RANKS_NEXT", [UiText.num(int(r["next_min"]) - n), UiText.t(t[r["index"] + 1]["name_key"])])
	var marks := true
	for i in range(t.size()):
		var c: Control = p.find_child("Tier_" + String(t[i]["id"]), true, false)
		marks = marks and c.get_meta("reached") == (i <= r["index"]) and c.get_meta("current") == (i == r["index"])
	var ok: bool = int(a.progression.completed_count()) == n and _txt(p, "CurrentRank") == UiText.t("RANKS_CURRENT", [UiText.t(r["name_key"])]) \
		and _txt(p, "Cleared") == UiText.t("PROFILE_CLEARED", [UiText.num(n)]) and cap.text == want_next and marks
	print("    n=%d rank=%s next='%s'" % [n, _txt(p, "CurrentRank"), cap.text])
	return ok

func _write(s: String) -> String:
	var path := "user://m43_personal_ranks_%d.json" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	return path

func _boot(tag: String, ftue: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43_personal_ranks_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	MainScript.boot_ftue_override = ftue
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _txt(p, n: String) -> String:
	var l = p.find_child(n, true, false) if p != null else null
	return l.text if l is Label else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_ftue_override = -1
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M43 personal ranks evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
