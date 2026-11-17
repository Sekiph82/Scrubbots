extends SceneTree
## SB-EV02-003/004/008/009/013/014 — Events V02 in the real app root (main.tscn, injected
## clock, throw-away saves): Level 29 locked / Level 30 unlocked on fresh and pre-V02 saves
## (Home tab, deep link, details, tutorial, join, claim, host receipts), the host's
## authoritative receipt (pixels by canonical color reconcile), the Events page (3..5 live
## cards by event id, upcoming previews icon-only), details for all 24 events (join + one real
## claim), all 72 tutorial states in English and Turkish on the REAL level board, Reduced
## Effects, and the no-extra-gameplay boundary.
##
## Run: godot --headless --path . -s res://tests/ev02_events_ui.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

var EXPECTED_CASES := [
	"u01_gate_l29_l30", "u02_host_receipt", "u03_events_page", "u04_details_24", "u05_tutorials_72", "u06_no_extra_gameplay",
]

var _fail := 0
var _completed := {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [0]

func _initialize() -> void:
	await process_frame
	var rt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))
	_now[0] = int(rt["schedule"]["epoch_utc"]) + 3600
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	await _u01()
	await _u02()
	await _u03()
	await _u04()
	await _u05()
	_u06()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _u01() -> void:
	print("[u01 Events Level 30 gate on fresh + pre-V02 saves: tab, deep link, details, tutorial, join, claim, receipts]")
	for frontier in [1, 29, 30]:
		await _boot_at("u01_%d" % frontier, frontier, false)
		var app = _root.get_app_state()
		var ev = app.economy.events_v02
		var iid: String = ev.scheduled(_now[0], _now[0] + 1)[0]["iid"]
		var open: bool = frontier >= 30
		_ok(app.feature_unlocked("events") == open, "frontier %d: Events %s" % [frontier, "unlocked" if open else "locked"])
		_ok((_root.open_deep_link("events") == "events") == open, "frontier %d: deep link %s" % [frontier, "opens Events" if open else "lands on Home"])
		_root.get_modal_stack().clear("test")
		_ok((EventsV02Ui.open_details(_root.get_modal_stack(), app, iid) != null) == open, "frontier %d: details %s" % [frontier, "open" if open else "refused"])
		_root.get_modal_stack().clear("test")
		_ok((EventTutorial.open(_root.get_modal_stack(), app, iid) != null) == open, "frontier %d: tutorial %s" % [frontier, "opens" if open else "refused"])
		_root.get_modal_stack().clear("test")
		var j: Dictionary = app.actions.join_event(iid)
		var c: Dictionary = app.actions.claim_event_reward(iid, "m0")
		_ok(j["ok"] == open and (open or (j["reason"] == "locked" and c["reason"] == "locked")), "frontier %d: join %s, claim %s" % [frontier, j.get("reason", "ok"), c.get("reason", "ok")])
		var m: Dictionary = app.actions.mark_event_tutorial_seen("scrub_sprint")
		_ok(m["ok"] == open, "frontier %d: tutorial-seen write gated" % frontier)
	# pre-V02 save: the economy section is absent -> fresh V02 state, same gate
	await _boot_at("u01_old", 30, true)
	var app2 = _root.get_app_state()
	_ok(app2.feature_unlocked("events") and app2.economy.events_v02.snapshot()["instances"].is_empty(), "save without an events_v02 section loads fresh and unlocked at frontier 30")
	# a win at frontier 29 (which makes the frontier 30) is not credited retroactively
	await _boot_at("u01_win29", 29, false)
	var app3 = _root.get_app_state()
	await _win(29)
	_ok(app3.progression.current_level() == 30 and app3.economy.events_v02.snapshot()["receipts"].is_empty(), "the Level 29 win that unlocks Events sends no event receipt")
	_complete("u01_gate_l29_l30")

func _u02() -> void:
	print("[u02 host receipt: committed first clear -> pixels by canonical C-id, reconciled, deduped by attempt]")
	await _boot_at("u02", 30, false)
	var app = _root.get_app_state()
	var ev = app.economy.events_v02
	for a in ev.scheduled(_now[0], _now[0] + 1):
		app.actions.join_event(a["iid"])
	await _play(30)
	var host = _root.get_gameplay_host()
	var board = host._board
	for i in range(board.get_cell_count()):
		if not board.is_void(i):
			board.set_cell_state(i, BoardState.CellState.CLEARED)
	var r: Dictionary = host._event_receipt(true, true)
	var sum := 0
	var keys_ok := true
	for cid in r["cleaned_pixels_by_color"]:
		sum += int(r["cleaned_pixels_by_color"][cid])
		keys_ok = keys_ok and host._level.palette.has(cid)
	_ok(r["cleaned_active_pixels"] == board.get_artwork_cell_count() and sum == r["cleaned_active_pixels"] and keys_ok and EventsV02.valid_receipt(r), "fully cleaned level %d: %d artwork pixels by palette C-id %s" % [30, r["cleaned_active_pixels"], str(r["cleaned_pixels_by_color"].keys())])
	host._drive_economy_terminal(CompletionEvaluator.WON)
	var snap: Dictionary = ev.snapshot()
	_ok(snap["receipts"] == ["L30:a1"], "the committed win produced exactly one receipt %s" % str(snap["receipts"]))
	var counted := 0
	for iid in snap["instances"]:
		counted += 1 if int(snap["instances"][iid]["progress"]) > 0 or int(snap["instances"][iid]["best"]) > 0 else 0
	_ok(counted >= 1, "%d joined active event(s) advanced from the real terminal" % counted)
	host._drive_economy_terminal(CompletionEvaluator.WON)
	_ok(ev.snapshot()["receipts"] == ["L30:a1"] and ev.snapshot()["instances"] == snap["instances"], "a duplicate terminal adds nothing")
	await _win(30)   # replay of a cleared level: not a progression attempt
	_ok(ev.snapshot()["receipts"] == ["L30:a1"], "replaying a cleared level sends no receipt")
	_complete("u02_host_receipt")

func _u03() -> void:
	print("[u03 Events page: 3..5 live cards by event id, upcoming icon-only, details + first-visit tutorial]")
	var ev0 = EventsV02.new(func(): return _now[0])
	var t5: int = _now[0]
	while ev0.scheduled(t5, t5 + 1).size() != 5:
		t5 += 3600
	for t in [_now[0], t5]:
		_now[0] = t
		await _boot_at("u03_%d" % t, 30, false)
		var app = _root.get_app_state()
		var p = ProfileScreens.open_events(_root.get_modal_stack(), app)
		await _frames(2)
		var live: Array = p.find_children("EventV2_*", "PanelContainer", true, false).filter(func(c): return c.get_meta("phase") == "active")
		var up: Array = p.find_children("EventV2_*", "PanelContainer", true, false).filter(func(c): return c.get_meta("phase") == "upcoming")
		var heroes_ok := live.all(func(c): return c.find_child("EventHero", true, false).texture != null and not c.find_child("EventHero", true, false).get_meta("art_fallback"))
		_ok(live.size() == app.economy.events_v02.active_count() and live.size() >= 3 and live.size() <= 5 and heroes_ok, "%d active cards (service %d), each with its own hero art" % [live.size(), app.economy.events_v02.active_count()])
		_ok(up.all(func(c): return c.find_child("EventHero", true, false) == null and c.find_child("EventIcon", true, false).texture != null), "%d upcoming previews: icon only (no extra hero texture)" % up.size())
		_ok(live.all(func(c): return c.name == "EventV2_" + String(c.get_meta("iid")).get_slice(":", 0)), "cards named and drawn by event id")
	var p = _root.get_modal_stack().top()
	var first: Control = p.find_children("EventV2_*", "PanelContainer", true, false)[0]
	var iid := String(first.get_meta("iid"))
	p._on_action("ev2:" + iid)
	await _frames(2)
	var st = _root.get_modal_stack()
	_ok(_top_id() == "event_tutorial" and st.depth() == 3, "DETAILS opens the details with its tutorial on top (first visit)")
	for a in ["tut_next", "tut_next", "tut_close"]:   # a step tap latches the popup until rearm
		st.top().rearm()
		st.top()._on_action(a)
	await _frames(2)
	_ok(_top_id() == "event_details", "GOT IT returns to the details")
	st.top()._on_action("close")
	await _frames(2)
	p.rearm()
	p._on_action("ev2:" + iid)
	await _frames(2)
	_ok(_top_id() == "event_details", "second visit: no automatic tutorial (seen flag saved)")
	_complete("u03_events_page")

func _u04() -> void:
	print("[u04 details for all 24 events: art, goal, CPU note, live state, reward steps, JOIN; one real claim]")
	await _boot_at("u04", 30, false)
	var app = _root.get_app_state()
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	var epoch: int = int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	var cycle: Array = ev.scheduled(epoch, epoch + 672 * 3600)
	cycle.sort_custom(func(a, b): return a["start"] < b["start"])   # the service clock never runs backwards
	for x in cycle:
		var id := String(x["id"])
		_now[0] = maxi(_now[0], int(x["start"]) + 7200)
		_root.get_modal_stack().clear("test")
		var d = EventsV02Ui.open_details(_root.get_modal_stack(), app, x["iid"])
		await _frames(1)
		var v: Dictionary = ev.view(x["iid"])
		var hero: TextureRect = d.find_child("EventHero", true, false)
		var rival := EventsV02Ui.RIVAL_KINDS.has(v["kind"])
		var ok: bool = hero.texture != null and _txt(d, "Goal") == EventsV02Ui.goal(v) and (d.find_child("CpuNote", true, false) != null) == rival \
			and d.find_children("Step_*", "", true, false).size() == v["steps"].size() and d.get_action_button("join").visible
		var cpu_rows := d.find_children("Rival_*", "", true, false)
		ok = ok and cpu_rows.all(func(r): return _txt(r, "Name").ends_with(UiText.t("EV2_CPU")))
		d._on_action("join")
		await _frames(1)
		_ok(ok and ev.view(x["iid"])["joined"] and not d.get_action_button("join").visible, "%s: hero, goal, %s, %d reward steps, JOIN -> joined" % [id, "CPU-labelled standings" if rival else "solo", v["steps"].size()])
	var w: Dictionary = cycle.filter(func(a): return a["id"] == "scrub_season_pass")[0]   # 28 days: still active
	for n in range(3):
		ev.on_receipt({"receipt_id": "u04:%d" % n, "level": 31 + n, "won": true, "first_attempt": true, "boosters_used": 0,
			"cleaned_active_pixels": 10, "cleaned_pixels_by_color": {"C01": 10}, "completed_at_utc": _now[0]}, true)
	_root.get_modal_stack().clear("test")
	var d2 = EventsV02Ui.open_details(_root.get_modal_stack(), app, w["iid"])
	await _frames(1)
	var sb0: int = app.economy.wallet.scrub_bucks()
	d2._on_action("rw:m0")
	d2._on_action("rw:m0")
	await _frames(1)
	_ok(app.economy.wallet.scrub_bucks() == sb0 + 50 and _txt(d2.find_child("Step_m0", true, false), "State") == UiText.t("ACH_DONE"), "Season Pass 3 levels: CLAIM pays 50 SB once, row shows done")
	_complete("u04_details_24")

func _u05() -> void:
	print("[u05 72 tutorial states x EN/TR: hero/icon/robot, REAL board, gain + live diagram, reward path; Reduced Effects]")
	await _boot_at("u05", 30, false)
	var app = _root.get_app_state()
	var ev = app.economy.events_v02
	var lvl = LevelLoader.load_from_path(EventTutorial.LEVEL).level_data
	var epoch: int = int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	var states := {}
	for lang in ["en", "tr"]:
		UiText.locale = lang
		var good := 0
		for id in ev.event_ids():
			var x: Dictionary = ev.scheduled(epoch, epoch + 672 * 3600).filter(func(a): return a["id"] == id)[0]
			_root.get_modal_stack().clear("test")
			var p = EventTutorial.open(_root.get_modal_stack(), app, x["iid"])
			for step in range(1, 4):
				EventTutorial.show_step(p, app, step)
				await _frames(1)
				var st: Dictionary = p.get_meta("state")
				var focus: Control = p.find_child({"hero": "HeroBlock", "board": "BoardBlock", "rewards": "RewardBlock"}[st["focus"]], true, false)
				var ok: bool = focus != null and focus.get_meta("focus", false) and _txt(p.find_child("Bubble", true, false), "Text").begins_with(String(st["bubble"]))
				match step:
					1:
						var robot: TextureRect = p.find_child("Robot", true, false)
						ok = ok and p.find_child("EventHero", true, false).texture != null and p.find_child("EventIcon", true, false).texture != null \
							and robot.texture != null and EventsV02.ROBOTS.has(robot.get_meta("robot"))
					2:
						var b = p.find_child("Board", true, false)
						var rb = b.get("_board")
						ok = ok and b.get_script() == BoardRenderer and b.texture != null and rb.get_width() == lvl.width and rb.get_height() == lvl.height \
							and rb.count_cells_by_state(BoardState.CellState.CLEARED) == rb.get_artwork_cell_count() / 2 + lvl.get_void_cell_count() \
							and _txt(p, "Gain") == st["gain"] and p.find_child("Meter", true, false) != null
					3:
						ok = ok and p.find_child("RewardPath", true, false).get_child_count() == ev.view(x["iid"])["steps"].size() \
							and p.get_action_button("tut_join").visible == bool(st["join"]) and p.find_child("WhenPill", true, false) != null
				ok = ok and p.text_fits()
				states["%s:%s:%d" % [lang, id, step]] = "|".join([st["bubble"], st.get("gain", ""), "|".join(st.get("lines", [])), JSON.stringify(st.get("rewards", []))])
				if ok:
					good += 1
				else:
					_ok(false, "%s %s step %d state broken" % [lang, id, step])
		_ok(good == 72, "%s: %d/72 tutorial states render (one component, per-event data)" % [lang, good])
	UiText.locale = "en"
	var distinct := {}
	for k in states:
		if k.begins_with("en:"):
			distinct[states[k]] = true
	_ok(distinct.size() == 72, "all 72 English states carry event-specific content (%d distinct)" % distinct.size())
	var tr_diff := 0
	for k in states:
		if k.begins_with("en:") and states[k] != states["tr:" + k.substr(3)]:
			tr_diff += 1
	_ok(tr_diff == 72, "every Turkish state has its own copy (%d/72 differ from English)" % tr_diff)
	var x2: Dictionary = ev.scheduled(_now[0], _now[0] + 1)[0]
	_root.get_modal_stack().clear("test")
	var p2 = EventTutorial.open(_root.get_modal_stack(), app, x2["iid"])
	EventTutorial.show_step(p2, app, 2)
	var animated: bool = p2.find_child("Meter", true, false).get_meta("animated")
	app.effects.set_reduced(true)
	EventTutorial.show_step(p2, app, 2)
	var reduced: bool = p2.find_child("Meter", true, false).get_meta("animated")
	app.effects.set_reduced(false)
	_ok(animated and not reduced, "the step-2 meter animates normally and jumps under Reduced Effects")
	_complete("u05_tutorials_72")

func _u06() -> void:
	print("[u06 no extra gameplay: events code never drives the gameplay pipeline or level data]")
	var forbidden := ["dispatch", "TargetSelector", "RoutingSystem", "solver", "Scrubbot", "record_win", "play_current_frontier", "res://data/levels/catalog"]
	for path in ["res://scripts/economy/events_v02_service.gd", "res://scripts/ui/events/events_v02_ui.gd", "res://scripts/ui/events/event_tutorial.gd"]:
		var src := FileAccess.get_file_as_string(path)
		var hits: Array = forbidden.filter(func(w): return src.contains(w))
		_ok(hits.is_empty(), "%s touches no gameplay system %s" % [path.get_file(), str(hits)])
	var tut := FileAccess.get_file_as_string("res://scripts/ui/events/event_tutorial.gd")
	_ok(tut.count("set_cell_state") == 1 and tut.contains("BoardState.from_level_data"), "the tutorial clears cells only on its own fresh BoardState copy")
	var host := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/production_gameplay_host.gd")
	var at := host.find("func _event_receipt(")
	var body := host.substr(at, host.find("\nfunc ", at + 1) - at)
	_ok(at > 0 and not body.contains("set_cell_state") and not body.contains("_runtime") and body.contains("get_cell_state"), "the host receipt only reads the board")
	_complete("u06_no_extra_gameplay")

# ---------------------------------------------------------------- helpers ----

## Boot the real app on a throw-away save whose frontier is `frontier` (durable record_win
## fixture). `strip_v02`: remove the events_v02 economy section (a pre-V02 save).
func _boot_at(tag: String, frontier: int, strip_v02: bool) -> void:
	_shutdown()
	var path := "user://ev02_ui_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var a = AppStateScript.new(path, MainScript.boot_clock_override, Callable())
	for n in range(1, frontier):
		a.progression.record_win(n)
	a.flush()
	if strip_v02:
		var f := FileAccess.open(path, FileAccess.READ)
		var txt := f.get_as_text()
		f.close()
		var d = JSON.parse_string(txt)
		var stripped := _strip(d)
		_ok(stripped, "fixture: events_v02 section removed from the save file")
		f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(d))
		f.close()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")

## Removes every "events_v02" key in a parsed save (wherever the economy section nests it).
func _strip(d) -> bool:
	var hit := false
	if typeof(d) == TYPE_DICTIONARY:
		if d.has("events_v02"):
			d.erase("events_v02")
			hit = true
		for k in d:
			hit = _strip(d[k]) or hit
	return hit

func _win(level: int) -> void:
	await _play(level)
	_root.get_gameplay_host()._drive_economy_terminal(CompletionEvaluator.WON)

func _play(level: int) -> void:
	_root.get_modal_stack().clear("test")
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(4)
	_root.get_gameplay_host().get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top_id() -> String:
	var t = _root.get_modal_stack().top()
	return String(t.popup_id) if t != null else ""

func _txt(p, n: String) -> String:
	var l = p.find_child(n, true, false) if p != null else null
	return l.text if l is Label else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(id: String) -> void:
	_completed[id] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("EV02 events UI evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
