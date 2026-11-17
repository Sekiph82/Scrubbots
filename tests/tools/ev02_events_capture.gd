extends SceneTree
## SB-EV02-013 owner evidence: real-app captures of the V02 Events page (top + scrolled), three
## details (the first three live events) and three tutorials (all
## three steps of Golden Brush Championship / Color Scrub Rush / Sparkling Streak), English and
## Turkish, at 720x1520 and 1170x2532. Throw-away save at frontier 30 (durable record_win
## fixture), injected clock at an instant with 5 active events. Each shot renders the logical canvas
## the 1080x2160 canvas_items/expand stretch gives that phone, saved scaled to the physical size.
## Needs a rendering driver:
##   godot --path . -s res://tests/tools/ev02_events_capture.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const SIZES := [Vector2i(720, 1520), Vector2i(1170, 2532)]
const TUTORIALS := ["golden_brush_championship", "color_scrub_rush", "sparkling_streak"]

var _out := ""
var _bad := 0
var _now := [0]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://ev02_captures"
	DirAccess.make_dir_recursive_absolute(_out)
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	for lang in ["en", "tr"]:
		for sz in SIZES:
			await _run(sz, lang)
	print("EV02_CAPTURES %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, lang: String) -> void:
	var probe := EventsV02.new(func(): return _now[0])
	var epoch := int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	_now[0] = epoch + 3600
	while probe.scheduled(_now[0], _now[0] + 1).size() != 5:
		_now[0] += 3600
	_now[0] += 5 * 3600
	var path := "user://ev02_cap_%d.save" % Time.get_ticks_usec()
	var a = AppStateScript.new(path, MainScript.boot_clock_override, Callable())
	for n in range(1, 30):
		a.progression.record_win(n)
	a.set_language(lang)   # saved choice: the whole app (HUD too) boots in this language
	a.flush()
	var sub := SubViewport.new()
	sub.size = _logical(size)
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
	st.clear("evidence")
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	for x in ev.scheduled(_now[0], _now[0] + 1):
		ev.join(x["iid"], true)
	for i in range(4):   # evidence fixture: four committed-style first clears so progress is visible
		ev.on_receipt({"receipt_id": "cap:%d" % i, "level": 30 + i, "won": true, "first_attempt": i != 2, "boosters_used": 0,
			"cleaned_active_pixels": 800, "cleaned_pixels_by_color": {"C01": 300, "C04": 300, "C09": 200}, "completed_at_utc": _now[0]}, true)
		_now[0] += 1800
	var tag := "%s_%dx%d" % [lang, size.x, size.y]
	var p = ProfileScreens.open_events(st, app)
	await _draw(6)
	_shot(sub, st, "01_events_page_" + tag, size)
	var scroll: ScrollContainer = p.find_child("EventScroll", true, false)
	scroll.scroll_vertical = 100000
	await _draw(4)
	_shot(sub, st, "02_events_page_scrolled_" + tag, size)
	var n := 3
	var live: Array = ev.scheduled(_now[0], _now[0] + 1).map(func(x): return x["id"])
	var rank := {"competitive": 0, "team": 1}   # one competitive, one team, then solo
	live.sort_custom(func(x, y): return int(rank.get(ev.def(x)["family"], 2)) < int(rank.get(ev.def(y)["family"], 2)))
	for id in live.slice(0, 3):   # three live events (their standings / team / milestones move)
		st.clear("evidence")
		EventsV02Ui.open_details(st, app, _iid(ev, id))
		await _draw(6)
		_shot(sub, st, "%02d_details_%s_%s" % [n, id, tag], size)
		n += 1
	for id in TUTORIALS:
		st.clear("evidence")
		var t = EventTutorial.open(st, app, _iid(ev, id))
		for step in range(1, 4):
			EventTutorial.show_step(t, app, step)
			await _draw(6)
			_shot(sub, st, "%02d_tutorial_%s_step%d_%s" % [n, id, step, tag], size)
			n += 1
	UiText.locale = "en"
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

## The instance of `id` live (or else nearest) at the capture clock.
func _iid(ev, id: String) -> String:
	for x in ev.scheduled(_now[0] - 672 * 3600, _now[0] + 672 * 3600):
		if x["id"] == id and int(x["end"]) > _now[0]:
			return x["iid"]
	return ""

func _shot(sub: SubViewport, st, key: String, phys: Vector2i) -> void:
	var top = st.top()
	var p := "%s/%s.png" % [_out, key]
	if top == null or not Rect2(Vector2.ZERO, Vector2(sub.size)).grow(1.0).encloses(top.get_frame_rect()) or not top.text_fits():
		_bad += 1
		print("REJECTED ", p)
	var img := sub.get_texture().get_image()
	img.resize(phys.x, phys.y, Image.INTERPOLATE_LANCZOS)
	print("SNAPSHOT ", p, " err=", img.save_png(p))

## The canvas the project stretch (1080x2160, canvas_items / expand) gives a phone (as m49).
static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
