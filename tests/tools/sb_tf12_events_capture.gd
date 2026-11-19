extends SceneTree
## SB-TF-12 owner evidence: real-app captures (1170x2532 phone, the 1080x2337 logical canvas the
## project stretch gives it, saved scaled to the physical size) of the Events page, the details
## screen of all 24 events (one instance of each, the service clock walking the 28-day cycle) and
## every coach-mark step of the events named on the command line. Throw-away save at frontier 30
## (durable record_win fixture); the real save is never touched. Needs a rendering driver:
##   godot --path . -s res://tests/tools/sb_tf12_events_capture.gd -- <out_dir> <en|tr> [event_id ...|all]

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const PHYS := Vector2i(1170, 2532)
const LOGICAL := Vector2i(1080, 2337)

var _now := [0]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var lang: String = args[1]
	var tut: Array = Array(args.slice(2))
	DirAccess.make_dir_recursive_absolute(out)
	var epoch := int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	_now[0] = epoch + 3600
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	var path := "user://sb_tf12_cap_%d.save" % Time.get_ticks_usec()
	var a = AppStateScript.new(path, MainScript.boot_clock_override, Callable())
	for n in range(1, 30):
		a.progression.record_win(n)
	a.set_language(lang)
	a.flush()
	var sub := SubViewport.new()
	sub.size = LOGICAL
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	UiText.locale = lang
	var app = root.get_app_state()
	var st = root.get_modal_stack()
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	st.clear("evidence")
	ProfileScreens.open_events(st, app)
	await _draw(6)
	_shot(sub, "%s/events_page_%s.png" % [out, lang])
	var cycle: Array = ev.scheduled(epoch, epoch + 672 * 3600)
	cycle.sort_custom(func(x, y): return x["start"] < y["start"])   # the service clock never runs backwards
	var seen := {}
	for x in cycle:
		var id := String(x["id"])
		if seen.has(id):
			continue
		seen[id] = true
		_now[0] = maxi(_now[0], int(x["start"]) + 7200)
		ev.join(x["iid"], true)
		for i in range(3):   # evidence fixture: committed-style first clears so progress is visible
			ev.on_receipt({"receipt_id": "cap:%s:%d" % [id, i], "level": 30 + i, "won": true, "first_attempt": true, "boosters_used": 0,
				"cleaned_active_pixels": 400, "cleaned_pixels_by_color": {"C01": 150, "C04": 150, "C09": 100}, "completed_at_utc": _now[0]}, true)
		_now[0] += 600
		st.clear("evidence")
		var d = EventsV02Ui.open_details(st, app, x["iid"], false)
		await _draw(8)
		_shot(sub, "%s/details_%s_%s.png" % [out, id, lang])
		if tut.has(id) or tut.has("all"):
			var t = EventTutorial.open(st, app, x["iid"])
			for step in range(1, EventTutorial.steps(id).size() + 1):
				EventTutorial.show_step(t, app, step)
				await _draw(8)
				_shot(sub, "%s/tutorial_%s_%02d_%s.png" % [out, id, step, lang])
	UiText.locale = "en"
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("SB_TF12_CAPTURES DONE")
	quit(0)

func _shot(sub: SubViewport, p: String) -> void:
	var img := sub.get_texture().get_image()
	img.resize(PHYS.x, PHYS.y, Image.INTERPOLATE_LANCZOS)
	print("SNAPSHOT ", p, " err=", img.save_png(p))

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
