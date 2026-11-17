extends SceneTree
## SB-STORE-LISTING-2026-11-17 store screenshots (NOT shipping): the REAL app root (main.tscn with a
## throw-away save, never the user save), GPU-rendered at one store size in one language:
##   1 Home (level 15), 2 Collection album, 3 Robots, 4 Level 15 mid-level (after the real Level
##   Intro video has finished), 5 the end of the real win animation of that level.
## One size + language per process (a second main.tscn in one run can render an empty texture).
## Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/store_screens_capture.gd -- --out <dir> --size 1080x1920 --lang en

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const LevelIntroOverlay = preload("res://scripts/ui/level_intro_overlay.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")

const LEVEL := 15

var _out := ""
var _size := Vector2i(1080, 1920)
var _lang := "en"
var _sub: SubViewport
var _root = null
var _save := ""
var _clicks: Array = []
var _taken := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	if DisplayServer.get_name() == "headless" or i < 0 or i + 1 >= args.size():
		print("capture: NOT_RUN (needs a rendering driver and --out <dir>)")
		quit(1)
		return
	_out = args[i + 1]
	var s := args.find("--size")
	if s >= 0:
		var wh: PackedStringArray = args[s + 1].split("x")
		_size = Vector2i(int(wh[0]), int(wh[1]))
	var l := args.find("--lang")
	if l >= 0:
		_lang = args[l + 1]
	DirAccess.make_dir_recursive_absolute(_out)
	AppStateScript.test_unlock_all = true
	MainScript.boot_opening_override = 0
	MainScript.boot_ftue_override = 0
	MainScript.boot_level_intro_override = 1   # the real Level Intro despite the temp save
	MainScript.boot_win_animation_override = 1
	_run.call_deferred()

func _run() -> void:
	_save = "user://store_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	_sub = SubViewport.new()
	_sub.size = _size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await create_timer(1.0).timeout
	var app = _root.get_app_state()
	app.set_language(_lang)
	app.set_reduced_effects(false)   # the full videos, not the reduced stills
	# A believable mid-campaign player: level 15, some currency, a few robots and cards.
	app.progression.debug_set_current_level(LEVEL)
	var e = app.economy
	e.wallet.credit("scrub_bucks", 640)
	e.wallet.credit("bot_parts", 250 * 3)
	for _k in range(3):
		app.actions.unlock_next_robot()
	for id in ["scrubby", "moppy", "bubbles", "spark"]:
		e.meta_ui.mark_seen("robot:" + id)
	for cid in ["s1_c0", "s1_c1", "s1_c2", "s1_c4", "s1_c5", "s1_c7", "s2_c0", "s2_c3", "s2_c8", "s3_c1"]:
		e.collection.add_card(cid)
	await _close_modals()
	_root.get_home().refresh()
	await create_timer(1.5).timeout
	await _close_modals()
	await _shot("1_home")
	var st = _root.get_modal_stack()
	CollectionScreen.open_album(st, app)
	await create_timer(0.8).timeout
	await _shot("2_collection")
	await _close_modals()
	RobotsScreen.open(st, app, _root.ceremonies)
	await create_timer(0.8).timeout
	await _shot("3_robots")
	await _close_modals()
	await _play_and_win()
	_root.free()
	_sub.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))
	quit(0)

func _play_and_win() -> void:
	_root.play_current_frontier()
	await _frames(4)
	var h = _root.get_gameplay_host()
	await _wait_intro_gone(h)
	var rt = h.get_runtime()
	var lvl = h.get_level()
	var cells: int = lvl.width * lvl.height
	# The level's verified real-play click order (tools/real_play_verify.gd) under the human
	# policy, until ~45% is cleared; then the bots keep travelling in real time for the shot.
	var cat = LevelCatalog.new()
	cat.load_manifest()
	var e = cat.get_entries_ordered()[LEVEL - 1]
	_clicks = RealPlayDriver.clicks_for(e.id, e.supply_plan_path, RealPlayDriver.load_provenance())
	rt.set_process(false)
	rt.reset_runtime()
	for _i in range(80000):
		if h.get_clearing_loop().get_cleared_count() >= int(cells * 0.45):
			break
		_fill(h)
		rt.tick(RealPlayDriver.CANONICAL_DT)
	rt.set_process(true)
	await create_timer(0.5).timeout
	await _shot("4_gameplay")
	rt.set_process(false)
	for _i in range(400000):
		if h.get_completion().is_terminal():
			break
		_fill(h)
		rt.tick(RealPlayDriver.CANONICAL_DT)
	print("terminal won=%s" % str(h.get_completion().is_won()))
	await process_frame
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		var w = _root.get_win_overlay()
		var v = w.get_video_player() if w != null else null
		if v != null and v.get_stream_length() > 0.0 and v.get_stream_position() >= v.get_stream_length() - 0.6:
			await _shot("5_win")
			return
		await process_frame
	print("capture: FAIL win animation not seen")
	quit(1)

## Human policy: place the next planned column whenever a slot is free.
func _fill(h) -> void:
	while h.get_slots().rightmost_empty_index() != -1 and _taken < _clicks.size():
		if not h.get_input_controller().activate_front(int(_clicks[_taken]) - 1).get("ok", false):
			return
		_taken += 1

## Real finish state: the overlay frees itself after its video `finished` + fade.
func _wait_intro_gone(host) -> void:
	var intro = null
	for _i in range(30):
		for c in host.get_children():
			if c.get_script() == LevelIntroOverlay:
				intro = c
		if intro != null:
			break
		await process_frame
	if intro == null:
		print("capture: FAIL no Level Intro overlay appeared")
		quit(1)
		return
	var vp = intro.get_video_player()
	print("intro video playing=%s length=%.2f s" % [str(vp != null and vp.is_playing()), vp.get_stream_length() if vp != null else 0.0])
	while is_instance_valid(intro) and intro.is_inside_tree():
		await process_frame
	print("intro finished")

func _close_modals() -> void:
	var st = _root.get_modal_stack()
	while st.top() != null:
		st.top().close("store_capture")
		await _frames(2)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _sub.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)   # stores reject alpha in screenshots
	var p := _out.path_join("%s_%s_%dx%d.png" % [_lang, name, _size.x, _size.y])
	img.save_png(p)
	print("captured %s" % p)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
