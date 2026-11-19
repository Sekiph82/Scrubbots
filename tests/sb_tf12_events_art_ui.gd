extends SceneTree
## SB-TF-12 (owner 2026-11-19) — native Events art + coach-mark tutorials for all 24 events, in the
## real app root (main.tscn, injected clock, throw-away saves at frontier 30):
##   t01 data: events_v02_tutorials.json covers the 24 service events, steps 1..N with known targets,
##       EN + TR bubble / button text (last = Start / Başla), no reference-PNG field; titles = UiText;
##   t02 assets: one scene + icon (256 px) + listed props per event, all present, lossy import, small;
##       the tutorial storyboard PNGs are never shipped;
##   t03 details x 24 x EN/TR: every texture present (no art_fallback), native title ribbon text,
##       every coach section of the event visible;
##   t04 tutorials x 24 x EN/TR: step count == data, every step focuses its target (visible, on
##       screen, the frame on its real rect), bubble + button text from data in the locale, and the
##       bubble never covers the focused target or any section header / title text;
##   t05 lazy art: the Events page loads scenes only for live cards, details only its own scene;
##       the (i) rules popup carries the long rule text and replays the walkthrough.
##
## Run: godot --headless --path . -s res://tests/sb_tf12_events_art_ui.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")

const TARGETS := ["hero", "board", "team", "ranking", "map", "progress", "rewards", "timer", "start_button"]
const ART_BUDGET := 4 * 1024 * 1024   ## added scenes + props + icons source bytes

var EXPECTED_CASES := ["t01_data", "t02_assets", "t03_details_24", "t04_tutorials_24", "t05_lazy_art"]

var _fail := 0
var _completed := {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [0]
var _epoch := 0

func _initialize() -> void:
	await process_frame
	_epoch = int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	_t01()
	_t02()
	await _t03_t04()
	await _t05()
	UiText.locale = "en"
	_shutdown()
	_cleanup()
	_done()

func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(EventsV02Ui.TUTORIALS))["events"]

func _t01() -> void:
	print("[t01 tutorial data: 24 events, steps 1..N, known targets, EN + TR text, titles]")
	var d := _data()
	var ids: Array = EventsV02.new(func(): return 0).event_ids()
	_ok(d.size() == 24 and ids.size() == 24 and ids.all(func(i): return d.has(i)), "24 events, the same ids as the service")
	var total := 0
	for id in ids:
		var steps: Array = d[id]["steps"]
		var ok := steps.size() >= 6 and steps.size() <= 10
		for i in range(steps.size()):
			var s: Dictionary = steps[i]
			ok = ok and int(s["step"]) == i + 1 and TARGETS.has(s["target"]) and not s.has("source")
			for f in ["bubble_en", "bubble_tr", "button_en", "button_tr"]:
				ok = ok and not String(s.get(f, "")).is_empty()
			ok = ok and s["bubble_en"] != s["bubble_tr"]
			var last := i == steps.size() - 1
			ok = ok and s["button_en"] == ("Start" if last else "Continue") and s["button_tr"] == ("Başla" if last else "Devam")
		total += steps.size()
		var key := "EV2_NAME_" + String(id).to_upper()
		ok = ok and UiText.EN[key] == d[id]["title_en"] and UiTextTr.TR[key] == d[id]["title_tr"]
		_ok(ok, "%s: %d steps, targets %s, EN/TR text, title %s / %s" % [id, steps.size(), str(steps.map(func(x): return x["target"])), d[id]["title_en"], d[id]["title_tr"]])
	_ok(total == 172, "%d coach-mark steps in total" % total)
	_complete("t01_data")

func _t02() -> void:
	print("[t02 shipped art: scene + icon + props per event, lossy import, small; no storyboard PNG]")
	var d := _data()
	var bytes := 0
	var ok_all := true
	for id in d:
		var paths: Array = [EventsV02Ui.SCENE % id, EventsV02Ui.ICON % id]
		for n in d[id]["props"]:
			paths.append(EventsV02Ui.PROP % [id, n])
		for p in paths:
			var tex = load(p) if ResourceLoader.exists(p) else null
			var lossy: bool = p.ends_with(".png") or FileAccess.get_file_as_string(p + ".import").contains("compress/mode=1")
			if tex == null or not lossy:
				ok_all = false
				_ok(false, "%s missing or not lossy" % p)
				continue
			bytes += FileAccess.get_file_as_bytes(p).size()
		for k in ["panel", "accent"]:
			ok_all = ok_all and Color.html_is_valid(String(d[id][k]))
		var icon: Texture2D = load(EventsV02Ui.ICON % id)
		var scene: Texture2D = load(EventsV02Ui.SCENE % id)
		ok_all = ok_all and icon.get_width() == 256 and scene.get_width() == 640
	for k in ["logo", "laurel", "flag_left", "flag_right", "sparkle_left", "sparkle_right", "star"]:
		var kp: String = EventsV02Ui.KIT % k
		var kt = load(kp) if ResourceLoader.exists(kp) else null
		ok_all = ok_all and kt != null and FileAccess.get_file_as_string(kp + ".import").contains("compress/mode=1")
		bytes += FileAccess.get_file_as_bytes(kp).size()
	_ok(ok_all, "every event has its 640 px scene, 256 px icon, listed props and sampled colours; 7 shared kit pieces (all lossy)")
	_ok(bytes < ART_BUDGET, "added Events art %.2f MiB (< %.0f MiB)" % [bytes / 1048576.0, ART_BUDGET / 1048576.0])
	var shipped := _files("res://assets/ui/final/events")
	_ok(not shipped.any(func(f): return f.get_file().begins_with("tutorial_") or f.get_file() == "background.png"), "no tutorial storyboard / raw kit PNG shipped (%d files)" % shipped.size())
	_complete("t02_assets")

func _t03_t04() -> void:
	print("[t03/t04 all 24 events x EN/TR: details art + sections; every coach-mark step on its real target]")
	var d := _data()
	for lang in ["en", "tr"]:
		_now[0] = _epoch + 3600
		await _boot("t03_" + lang)
		UiText.locale = lang
		var app = _root.get_app_state()
		var ev = app.economy.events_v02
		for id in ev.event_ids():
			ev.mark_tutorial_seen(id)
		var cycle: Array = ev.scheduled(_epoch, _epoch + 672 * 3600)
		cycle.sort_custom(func(a, b): return a["start"] < b["start"])   # the service clock never runs backwards
		var seen := {}
		var det_ok := 0
		var steps_ok := 0
		var steps_all := 0
		for x in cycle:
			var id := String(x["id"])
			if seen.has(id):
				continue
			seen[id] = true
			_now[0] = maxi(_now[0], int(x["start"]) + 7200)
			var st = _root.get_modal_stack()
			st.clear("test")
			var p = EventsV02Ui.open_details(st, app, x["iid"])
			await _frames(2)
			var v: Dictionary = ev.view(x["iid"])
			var arts: Array = p.find_children("*", "TextureRect", true, false).filter(func(t): return t.is_visible_in_tree())
			var missing: Array = arts.filter(func(t): return t.texture == null).map(func(t): return String(t.name))
			var keys: Array = EventsV02Ui.sections(v)
			var absent: Array = keys.filter(func(k): return EventsV02Ui.target(p, k) == null or not EventsV02Ui.target(p, k).is_visible_in_tree())
			var ribbon: Label = p.find_child("TitleRibbon", true, false).get_node("Title")
			var bg: TextureRect = p.find_child("EventBackground", true, false)
			if missing.is_empty() and absent.is_empty() and ribbon.text == d[id]["title_" + lang] and bg.texture.resource_path == EventsV02Ui.SCENE % id:
				det_ok += 1
			else:
				_ok(false, "%s %s details: missing art %s, absent sections %s, title '%s'" % [lang, id, str(missing), str(absent), ribbon.text])
			var t = EventTutorial.open(st, app, x["iid"])
			var steps: Array = d[id]["steps"]
			if st.ids() != ["event_details", "event_tutorial"] or EventTutorial.steps(id).size() != steps.size():
				_ok(false, "%s %s: walkthrough not over its details" % [lang, id])
			for i in range(steps.size()):
				steps_all += 1
				EventTutorial.show_step(t, app, i + 1)
				await _frames(3)
				var target: Control = EventsV02Ui.target(p, String(steps[i]["target"]))
				var coach = t.get_node("Coach")
				var ok: bool = target != null and target.is_visible_in_tree() and target.size.y > 0.0 \
					and coach.hole.position.distance_to(target.get_global_rect().position - coach.global_position) < 1.0 \
					and Rect2(Vector2.ZERO, coach.size).encloses(coach.hole) \
					and _txt(t, "Text") == String(steps[i]["bubble_" + lang]) and t.get_action_button("tut_next").text == String(steps[i]["button_" + lang]) \
					and _txt(t, "StepText") == "%s / %s" % [UiText.num(i + 1), UiText.num(steps.size())] \
					and _bubble_clear(coach)
				if ok:
					steps_ok += 1
				else:
					_ok(false, "%s %s step %d (%s) not focused / wrong text" % [lang, id, i + 1, steps[i]["target"]])
			if t.get_meta("step") != steps.size():
				_ok(false, "%s %s: walkthrough ended early" % [lang, id])
		_ok(det_ok == 24, "%s: %d/24 details screens with every texture, the native title and all coach sections" % [lang, det_ok])
		_ok(steps_ok == steps_all and steps_all == 172, "%s: %d/%d coach-mark steps focus their real visible target with the %s data text" % [lang, steps_ok, steps_all, lang.to_upper()])
	UiText.locale = "en"
	_complete("t03_details_24")
	_complete("t04_tutorials_24")

func _t05() -> void:
	print("[t05 lazy art: scenes only for live cards / the open details]")
	_now[0] = _epoch + 3600
	await _boot("t05")
	var app = _root.get_app_state()
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	var st = _root.get_modal_stack()
	var page = ProfileScreens.open_events(st, app)
	await _frames(2)
	var scenes: Array = page.find_children("EventScene", "TextureRect", true, false)
	_ok(scenes.size() == ev.active_count() and scenes.size() <= 5, "Events page: %d scene textures for %d live events" % [scenes.size(), ev.active_count()])
	var x: Dictionary = ev.scheduled(_now[0], _now[0] + 1)[0]
	var d = EventsV02Ui.open_details(st, app, x["iid"])
	await _frames(2)
	var paths: Array = d.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture != null).map(func(t): return t.texture.resource_path)
	var other: Array = paths.filter(func(p): return p.contains("/events/scenes/") and p != EventsV02Ui.SCENE % x["id"])
	_ok(other.is_empty() and paths.has(EventsV02Ui.SCENE % x["id"]), "details: only its own scene is loaded (%d textures)" % paths.size())
	_ok(not paths.any(func(p): return p.contains("/events/heroes/")), "the details screen needs no hero PNG")
	d.rearm()
	d._on_action("how")
	await _frames(2)
	var info = st.top()
	var v: Dictionary = ev.view(x["iid"])
	_ok(info.popup_id == "event_info" and _txt(info, "Rule_0") == EventsV02Ui.goal(v), "(i) opens the rules popup with the full goal text")
	info._on_action("tutorial")
	await _frames(2)
	_ok(st.ids() == ["events", "event_details", "event_tutorial"], "rules -> HOW IT WORKS replays the walkthrough over the details %s" % str(st.ids()))
	_complete("t05_lazy_art")

# ---------------------------------------------------------------- helpers ----

## The bubble (coach space) intersects neither the focused rect nor an on-screen header / title label.
func _bubble_clear(coach) -> bool:
	var b: Control = coach.get_node("Bubble")
	var r := Rect2(b.position, b.size)
	if r.intersects(coach.hole):
		return false
	return not coach.header_rects().any(func(x): return (x as Rect2).intersects(r))

func _files(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		out.append(dir + "/" + f)
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir + "/" + sub))
	return out

func _boot(tag: String) -> void:
	_shutdown()
	var path := "user://sb_tf12_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var a = AppStateScript.new(path, MainScript.boot_clock_override, Callable())
	for n in range(1, 30):
		a.progression.record_win(n)
	a.flush()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

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
	print("SB-TF-12 events art/tutorial evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
