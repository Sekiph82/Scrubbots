extends SceneTree
## SB-M54-032 / SB-M43-136..141 / SB-M43-073 — the owner world table (2026-10-22: 20 named worlds
## x 150 levels = 3000; a world ends at its last level, the next starts after), WorldService over
## every level 1..3000, and the live World Transition trigger: once at L150 -> L151 (catalog
## injected: only 30 levels ship), never with the shipped catalog, idempotent across relaunch and
## cloud-save import, grants nothing, Ranks / Events unchanged.
##
## Run: godot --headless --path . -s res://tests/m54_world_regression.gd

const AppState = preload("res://scripts/app/app_state.gd")
const WorldService = preload("res://scripts/progression/world_service.gd")
const CeremonyPresenter = preload("res://scripts/ui/ceremony/ceremony_presenter.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const PersonalRank = preload("res://scripts/progression/personal_rank.gd")
const CloudSave = preload("res://scripts/save/cloud_save.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const OWNER_NAMES := ["Whispering Park", "Bubble District", "Neon Sewers", "Crystal Laundry", "Toxic Docks",
	"Clockwork Carnival", "Rustwood Railway", "Frostbyte Factory", "Midnight Metro", "Sunken Harbor",
	"Ember Foundry", "Mosslight Ruins", "Candy Circuit", "Stormglass Heights", "Phantom Museum",
	"Moonbeam Observatory", "Steamcloud Summit", "Prism Powerplant", "Shadowbyte Citadel", "Grimeheart Core"]

var EXPECTED_CASES := [
	"r01_owner_table_verbatim", "r02_invalid_fail_closed", "r03_every_level_1_3000", "r04_progress_next_states",
	"r05_names_en_tr", "r06_ceremony_once_at_l150", "r07_relaunch_import_idempotent",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	_r01()
	_r02()
	_r03()
	_r04()
	_r05()
	await _r06()
	await _r07()
	_sub.free()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _r01() -> void:
	print("[r01 worlds_v1.json = the owner table on SB-M43-136, verbatim]")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WorldService.PATH))
	_ok(d["schema"] == WorldService.SCHEMA and int(d["version"]) == 1 and int(d["first_level"]) == 1 and int(d["last_level"]) == 3000, "schema / version 1 / levels 1..3000")
	var ws := WorldService.load_worlds()
	var ok := ws.size() == 20
	for i in range(ws.size()):
		ok = ok and ws[i]["id"] == "world_%02d" % (i + 1) and ws[i]["number"] == i + 1 and ws[i]["name"] == OWNER_NAMES[i] \
			and ws[i]["first"] == i * 150 + 1 and ws[i]["last"] == (i + 1) * 150
	_ok(ok, "20 worlds, owner names, ranges 1-150 .. 2851-3000")
	var m = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_manifests/world10_sunken_harbor_v1.json"))["world"]
	var w10 := WorldService.world_by_id("world_10")
	_ok(w10["name"] == m["name"] and w10["first"] == int(m["firstLevel"]) and w10["last"] == int(m["lastLevel"]), "World 10 Sunken Harbor 1351-1500 == factory 107 art manifest")
	var fb := String(WorldService.load_table()["fallback_art"])
	_ok(ResourceLoader.exists(ws[0]["art"]) and ResourceLoader.exists(fb) and ws.slice(1).all(func(w): return w["art"] == ""), "World 01 real art; worlds 2-20 no art yet -> World 01 fallback (exists)")
	_complete("r01_owner_table_verbatim")

func _r02() -> void:
	print("[r02 gap / overlap / short coverage / bad fields fail closed]")
	var good: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WorldService.PATH))
	_ok(WorldService.load_worlds(_write(JSON.stringify(good))).size() == 20, "control copy loads")
	var bad := []
	for mut in ["gap", "overlap", "short", "start_2", "dup_id", "number", "no_name", "art_int", "fraction", "schema", "empty"]:
		var c: Dictionary = good.duplicate(true)
		match mut:
			"gap": c["worlds"][5]["first"] = 752
			"overlap": c["worlds"][1]["first"] = 150
			"short": c["worlds"][19]["last"] = 2999
			"start_2": c["worlds"][0]["first"] = 2
			"dup_id": c["worlds"][3]["id"] = "world_01"
			"number": c["worlds"][4]["number"] = 7
			"no_name": c["worlds"][2]["name"] = ""
			"art_int": c["worlds"][2]["art"] = 3
			"fraction": c["worlds"][0]["last"] = 150.5
			"schema": c["schema"] = "x"
			"empty": c["worlds"] = []
		bad.append(_write(JSON.stringify(c)))
	bad.append(_write("{not json"))
	bad.append("user://__missing_worlds.json")
	_ok(bad.all(func(p): return WorldService.load_worlds(p).is_empty()), "%d bad tables -> []" % bad.size())
	_ok(WorldService.world_for_level(5, []).is_empty() and WorldService.states(5, []).is_empty(), "no table -> no world, no states")
	_complete("r02_invalid_fail_closed")

func _r03() -> void:
	print("[r03 world_for_level for every n in 1..3000]")
	var ws := WorldService.load_worlds()
	var wrong: Array = []
	for n in range(1, 3001):
		var w := WorldService.world_for_level(n, ws)
		if w.is_empty() or w["number"] != (n - 1) / 150 + 1 or n < w["first"] or n > w["last"]:
			wrong.append(n)
	_ok(wrong.is_empty(), "3000 levels map to world floor((n-1)/150)+1 %s" % str(wrong.slice(0, 5)))
	_ok(WorldService.world_for_level(150)["id"] == "world_01" and WorldService.world_for_level(151)["id"] == "world_02", "150 / 151 -> World 01 / World 02")
	_ok(WorldService.world_for_level(2850)["id"] == "world_19" and WorldService.world_for_level(2851)["id"] == "world_20" and WorldService.world_for_level(3000)["id"] == "world_20", "2850 / 2851 / 3000 -> 19 / 20 / 20")
	_ok(WorldService.world_for_level(0).is_empty() and WorldService.world_for_level(-1).is_empty() and WorldService.world_for_level(3001).is_empty(), "0 / -1 / 3001 -> no world")
	_complete("r03_every_level_1_3000")

func _r04() -> void:
	print("[r04 progress / complete / next / states]")
	var chain := true
	var w := WorldService.world_by_id("world_01")
	for i in range(19):
		var nx := WorldService.next_world(w["id"])
		chain = chain and nx["number"] == w["number"] + 1 and nx["first"] == w["last"] + 1
		w = nx
	_ok(chain and WorldService.next_world("world_20").is_empty() and WorldService.next_world("world_99").is_empty(), "next_world chains 1..20, none after 20 / unknown")
	_ok(not WorldService.is_world_complete("world_01", 150) and WorldService.is_world_complete("world_01", 151) and not WorldService.is_world_complete("world_20", 3000) and WorldService.is_world_complete("world_20", 3001), "complete once the frontier passes the last level")
	_ok(WorldService.progress("world_02", 1) == {"cleared": 0, "total": 150} and WorldService.progress("world_02", 226) == {"cleared": 75, "total": 150} and WorldService.progress("world_02", 999) == {"cleared": 150, "total": 150}, "progress clamped 0..150")
	var st := WorldService.states(151)
	_ok(st.size() == 20 and st["world_01"] == "completed" and st["world_02"] == "current" and st["world_03"] == "locked" and WorldService.states(1)["world_01"] == "current", "locked / current / completed")
	_complete("r04_progress_next_states")

func _r05() -> void:
	print("[r05 names: EN = data, TR = UiTextTr.DATA WORLD_NAME_<n>]")
	var ws := WorldService.load_worlds()
	_ok(ws.all(func(w): return UiText.data("WORLD_NAME_%d" % w["number"], w["name"]) == w["name"]), "EN: data names")
	UiText.locale = "tr"
	var tr: Array = ws.map(func(w): return UiText.data("WORLD_NAME_%d" % w["number"], w["name"]))
	UiText.locale = "en"
	_ok(tr[0] == "Fısıltılı Park" and tr[9] == "Batık Liman" and tr.all(func(s): return not String(s).is_empty()) and not tr.any(func(s): return OWNER_NAMES.has(s)), "TR: 20 Turkish names %s" % str(tr.slice(0, 3)))
	_complete("r05_names_en_tr")

func _r06() -> void:
	print("[r06 L150 first clear -> World 02 ceremony once; nothing on the shipped catalog; grants nothing]")
	var app = _app("r06")
	var pr = _presenter(app)
	_win_to(app, 150)
	_set_catalog(app, 151)
	_ok(pr.world_events().is_empty(), "frontier 150 (World 01): no world event")
	_win_to(app, 151)
	app._catalog_orders = []
	_ok(not app.catalog_has_level(151) and pr.world_events().is_empty(), "shipped catalog (%d levels): L151 absent -> nothing triggers" % app._catalog_orders.size())
	_set_catalog(app, 151)
	var ev: Array = pr.world_events()
	_ok(ev.size() == 1 and ev[0]["key"] == "world:world_02" and ev[0]["title"] == "Bubble District" and ev[0]["subtitle"] == UiText.t("HOME_AREA_NUMBER", [2]) and ev[0]["art"] == WorldService.load_table()["fallback_art"], "one event: Bubble District, AREA 2, World 01 fallback art %s" % str(ev))
	var before := _truth(app)
	_ok(pr.drain("test"), "presenter opens it")
	await _frames(2)
	var p = pr.current()
	_ok(p != null and p.popup_id == "ceremony_world_unlock" and p.get_title() == "Bubble District" and p.find_child("WorldArt", true, false) != null, "World Transition popup, title + art")
	p._on_action(p.get_action_ids()[0])
	await _frames(2)
	_ok(app.economy.meta_ui.is_seen("world:world_02") and pr.world_events().is_empty() and not pr.drain("again"), "acknowledged; never pending again")
	_ok(_truth(app) == before, "economy (minus the ack), progression, personal rank and events unchanged")
	_complete("r06_ceremony_once_at_l150")

func _r07() -> void:
	print("[r07 relaunch / cloud import idempotent; an import far ahead shows only the current world]")
	var a = _app("r07a")
	_win_to(a, 151)
	a.request_save()
	var unacked := CloudSave.envelope(a.save, "dev-a", 1, 1000)
	var re = AppState.new(a.save._path)
	_set_catalog(re, 151)
	var pr = _presenter(re)
	_ok(_keys(pr) == ["world:world_02"], "relaunch before CONTINUE: still pending once")
	pr.drain("test")
	await _frames(2)
	pr.current()._on_action(pr.current().get_action_ids()[0])
	await _frames(2)
	var re2 = AppState.new(a.save._path)
	_set_catalog(re2, 151)
	_ok(re2.progression.current_level() == 151 and _keys(_presenter(re2)).is_empty(), "relaunch after CONTINUE: nothing")
	var acked := CloudSave.envelope(re2.save, "dev-a", 2, 1001, unacked)
	var b = _app("r07b")
	_ok(bool(CloudSave.restore(b.save, acked)["ok"]), "import of the acknowledged save")
	_set_catalog(b, 151)
	_ok(_keys(_presenter(b)).is_empty(), "imported acknowledged save: nothing replayed")
	var c = _app("r07c")
	CloudSave.restore(c.save, unacked)
	_set_catalog(c, 151)
	_ok(_keys(_presenter(c)) == ["world:world_02"], "imported unacknowledged save: pending once")
	var far = _app("r07d")
	_win_to(far, 301)
	_set_catalog(far, 301)
	_ok(_keys(_presenter(far)) == ["world:world_03"], "frontier 301 with no acks: only World 03, no World 02 backlog")
	_complete("r07_relaunch_import_idempotent")

# ------------------------------------------------------------------ helpers ----

func _app(tag: String):
	var path := "user://m54_world_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var app = AppState.new(path)
	app.request_save()
	return app

func _presenter(app):
	var pr = CeremonyPresenter.new()
	pr.bind(_stack, app)
	return pr

## Clears forward to frontier `n` through the real first-clear rule.
func _win_to(app, n: int) -> void:
	while app.progression.current_level() < n:
		app.progression.record_win(app.progression.current_level())

## Test seam: a playable catalog of levels 1..n (only 30 levels ship today).
func _set_catalog(app, n: int) -> void:
	app._catalog_orders = range(1, n + 1)

func _keys(pr) -> Array:
	return pr.pending().map(func(e): return e["key"])

func _truth(app) -> Dictionary:
	var s: Dictionary = app.economy.snapshot()
	s.erase("meta_ui")
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return {"econ": s, "events": app.economy.events.snapshot(), "progression": app.progression.snapshot(),
		"rank": PersonalRank.for_cleared(app.progression.completed_count())}

func _write(s: String) -> String:
	var path := "user://m54_world_table_%d.json" % Time.get_ticks_usec()
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	return path

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", "_analytics.json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		if p.ends_with(".save") and FileAccess.file_exists(p.get_basename() + "_analytics.json"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p.get_basename() + "_analytics.json"))

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
	print("M54 world regression evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
