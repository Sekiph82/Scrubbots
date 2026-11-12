extends SceneTree
## SB-PHONE-2026-11-12-E evidence captures (NOT shipping): the REAL app root (main.tscn) in TR in a
## SubViewport at the logical size a 720x1520 phone gets (1080x2280, canvas_items stretch), saved
## at 720x1520; a real Level 1 WON with the shipping win animation:
##   01 the end of the win animation over the board, 02 Home mid reward flight, 03 Home after the
##   flight (no milestone), 04 the first ceremony on Home (Gift 10 crossed by the win).
## Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/win_home_capture.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var _out := ""
var _root = null
var _sub: SubViewport
var _tmp: Array = []
const LOGICAL := Vector2i(1080, 2280)
const PHONE := Vector2i(720, 1520)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://win_home_capture"
	DirAccess.make_dir_recursive_absolute(_out if _out.is_absolute_path() and not _out.begins_with("user://") else ProjectSettings.globalize_path(_out))
	UiText.locale = "tr"
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 0
	MainScript.boot_win_animation_override = 1
	_run.call_deferred()

func _run() -> void:
	# A: Gift 1 -> 2 crosses no milestone: animation end, mid flight, after the flight.
	await _boot(0)
	await _win()
	var nav = _root.get_navigation()
	var t0 := Time.get_ticks_msec()
	var shot_end := false
	while nav.current() != 2 and Time.get_ticks_msec() - t0 < 20000:   # Route.HOME
		var v = _root.get_win_overlay().get_video_player() if _root.get_win_overlay() != null else null
		if not shot_end and v != null and v.get_stream_position() >= v.get_stream_length() - 0.6:
			await _shot("01_win_animation_end")
			shot_end = true
		await process_frame
	var seq = _root.get_home().get_reward_flight()._seq
	while seq.is_running() and seq.current_step() < 4:   # the 2nd reward (Bot Parts) is in the air
		await process_frame
	await create_timer(0.3).timeout
	await _shot("02_home_mid_flyin")
	while _root.get_home().is_reward_flight_running():
		await process_frame
	await create_timer(0.5).timeout
	await _shot("03_home_after_flyin")
	_shutdown()
	# B: Gift 9 -> 10: the Gift milestone ceremony opens on Home after the flight.
	await _boot(8)
	await _win()
	_root.handle_back()   # skip the animation (A already shows it)
	while _root.get_home().is_reward_flight_running():
		await process_frame
	await create_timer(1.6).timeout
	print("ceremony on top: %s" % str(_root.get_modal_stack().top().popup_id if _root.get_modal_stack().top() != null else "none"))
	await _shot("04_home_first_ceremony")
	_shutdown()
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	quit(0)

func _boot(gift_extra: int) -> void:
	var path := "user://win_home_capture_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var seed = AppState.new(path)
	for o in seed.economy.gift.add_streak_sb("capture_seed", 1 + gift_extra):
		seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
	seed.request_save()
	MainScript.boot_save_path_override = path
	_sub = SubViewport.new()
	_sub.size = LOGICAL
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await create_timer(1.0).timeout

## Level 1 played to its real WON (front clicks + runtime ticks; the completion controller latches it).
func _win() -> void:
	_root.play_current_frontier()
	await process_frame
	var h = _root.get_gameplay_host()
	var rt = h.get_runtime()
	rt.set_process(false)
	for _i in range(80000):
		if h.get_completion().is_terminal():
			break
		if h.get_slots().rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
				if h.get_input_controller().activate_front(col).get("ok", false):
					break
		rt.tick(1.0)
	await process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _sub.get_texture().get_image()
	img.resize(PHONE.x, PHONE.y, Image.INTERPOLATE_LANCZOS)
	var p := _out.path_join(name + ".png")
	img.save_png(p)
	print("captured %s %dx%d" % [p, img.get_width(), img.get_height()])

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
