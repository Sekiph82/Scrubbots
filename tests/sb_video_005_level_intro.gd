extends SceneTree
## SB-VIDEO-005 — Level Intro overlay (scripts/ui/level_intro_overlay.gd) and its app wiring:
##   the overlay shows "LEVEL N" over ONE keyed Scrubby video decoder; a tap closes it at once and
##   is consumed (a Control underneath never sees it); finishing / skipping frees the decoder and
##   then the overlay; Reduced Effects / no video = keyed still + CharacterMotion `ready`, no
##   VideoStreamPlayer; the app root shows it on PLAY and RETRY of the started level, never over a
##   live FTUE coachmark, and never for an injected test save path unless forced on.
##
## Run: godot --headless --path . -s res://tests/sb_video_005_level_intro.gd

const LevelIntroOverlay = preload("res://scripts/ui/level_intro_overlay.gd")
const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

var EXPECTED_CASES := [
	"video_level_label", "tap_skips_consumed", "finish_frees", "reduced_still", "no_video_fallback",
	"app_play_retry", "app_off_for_test_save", "app_not_over_coachmark",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _video_level_label()
	await _tap_skips_consumed()
	await _finish_frees()
	await _reduced_still()
	await _no_video_fallback()
	await _app_play_retry()
	await _app_off_for_test_save()
	await _app_not_over_coachmark()
	_cleanup()
	_done()

func _overlay(level: int, reduced := false, no_video := false):
	var o = LevelIntroOverlay.new()
	o.level = level
	o.reduced = reduced
	if no_video:
		o.video = null
	get_root().add_child(o)
	return o

func _players(n: Node) -> int:
	return n.find_children("*", "VideoStreamPlayer", true, false).size()

# ------------------------------------------------------------------ cases ----

func _video_level_label() -> void:
	var o = _overlay(27)
	await process_frame
	var v: VideoStreamPlayer = o.get_video_player()
	_ok((o.get_node("Dim") as ColorRect) != null and o.mouse_filter == Control.MOUSE_FILTER_STOP, "dim scrim, overlay stops input")
	_ok(o.find_child("LevelLabel", true, false).text == "LEVEL 27", "LEVEL N label shows the started level")
	_ok(v != null and v.is_playing() and v.stream.resource_path == LevelIntroOverlay.VIDEO and (v.material as ShaderMaterial).shader == LevelIntroOverlay.CHROMA_KEY and _players(o) == 1, "one keyed intro video playing")
	_ok(v.mouse_filter == Control.MOUSE_FILTER_IGNORE and o.find_child("Robot", true, false).self_modulate.a == 0.0, "video ignores input, still hidden under it")
	o.free()
	_complete("video_level_label")

func _tap_skips_consumed() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	get_root().add_child(sub)
	var under := Control.new()
	under.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(under)
	var hits := [0]
	under.gui_input.connect(func(e): if e is InputEventMouseButton: hits[0] += 1)
	var o = LevelIntroOverlay.new()
	o.level = 3
	sub.add_child(o)
	await process_frame
	_tap(sub, true)
	await process_frame
	_ok(o.is_closing() and o.get_video_player() == null and _players(o) == 0, "tap closes at once and frees the decoder")
	_tap(sub, false)
	await process_frame
	_ok(hits[0] == 0, "the skipping tap (press + release) never reaches the Control underneath (%d)" % hits[0])
	await create_timer(LevelIntroOverlay.FADE_S + 0.15).timeout
	_ok(not is_instance_valid(o), "overlay freed after the fade")
	_tap(sub, true)
	await process_frame
	_tap(sub, false)
	await process_frame
	_ok(hits[0] == 2, "after the overlay is gone, taps reach the board again (%d)" % hits[0])
	sub.free()
	_complete("tap_skips_consumed")

func _tap(sub: SubViewport, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = Vector2(540, 1080)
	ev.global_position = ev.position
	sub.push_input(ev)

func _finish_frees() -> void:
	var o = _overlay(5)
	await process_frame
	Engine.time_scale = 8.0
	var t := 0.0
	while is_instance_valid(o) and t < 8.0:
		await process_frame
		t += 1.0 / 60.0
	Engine.time_scale = 1.0
	_ok(not is_instance_valid(o), "video end -> fade -> overlay and decoder freed (%.2f s at 8x)" % t)
	_complete("finish_frees")

func _reduced_still() -> void:
	var o = _overlay(9, true)
	await process_frame
	var robot: TextureRect = o.find_child("Robot", true, false)
	_ok(_players(o) == 0 and o.get_video_player() == null, "Reduced: no VideoStreamPlayer")
	_ok(robot.texture.resource_path == LevelIntroOverlay.STILL and robot.self_modulate.a == 1.0 and CharacterMotion.is_playing(robot), "Reduced: keyed still with the ready bounce")
	await create_timer(LevelIntroOverlay.REDUCED_HOLD_S + LevelIntroOverlay.FADE_S + 0.2).timeout
	_ok(not is_instance_valid(o), "Reduced: fades and frees itself after the hold")
	_complete("reduced_still")

func _no_video_fallback() -> void:
	var o = _overlay(4, false, true)
	await process_frame
	_ok(_players(o) == 0 and CharacterMotion.is_playing(o.find_child("Robot", true, false)), "no / failed video: Reduced path (still + bounce, no decoder)")
	o.free()
	var bad := VideoStreamTheora.new()
	bad.file = "res://tests/__missing_video__.ogv"
	o = LevelIntroOverlay.new()
	o.video = bad
	get_root().add_child(o)
	await process_frame
	_ok(_players(o) == 0 and CharacterMotion.is_playing(o.find_child("Robot", true, false)), "unplayable video: Reduced path, no decoder left")
	o.free()
	_complete("no_video_fallback")

func _app_play_retry() -> void:
	MainScript.boot_level_intro_override = 1
	var root = await _boot_main(_uniq("on"))
	var nav = root.get_navigation()
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	var intro = h.get_node_or_null("LevelIntro")
	_ok(intro != null and h.get_child(h.get_child_count() - 1) == intro, "PLAY: Level Intro on top of the gameplay host")
	_ok(intro != null and intro.find_child("LevelLabel", true, false).text == "LEVEL %d" % int(h.progression_level), "PLAY: label is the launched level (%d)" % int(h.progression_level))
	intro.close()
	await create_timer(LevelIntroOverlay.FADE_S + 0.15).timeout
	_ok(h.get_node_or_null("LevelIntro") == null, "closed intro leaves the host")
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"LOST", {})
	_ok(root.retry_from_results() and nav.current() == NavigationController.Route.GAMEPLAY, "RETRY accepted")
	_ok(h.get_node_or_null("LevelIntro") != null, "RETRY: the intro shows again")
	_shutdown(root)
	_complete("app_play_retry")

func _app_off_for_test_save() -> void:
	MainScript.boot_level_intro_override = -1
	var root = await _boot_main(_uniq("auto"))
	root.play_current_frontier()
	await process_frame
	_ok(not root.level_intro_enabled and root.get_gameplay_host().get_node_or_null("LevelIntro") == null, "auto + injected test save path: no intro (gameplay suites unaffected)")
	_shutdown(root)
	_complete("app_off_for_test_save")

func _app_not_over_coachmark() -> void:
	MainScript.boot_level_intro_override = 1
	MainScript.boot_ftue_override = 1
	var root = await _boot_main(_uniq("ftue"))
	root.play_current_frontier()
	await process_frame
	_ok(root.get_coachmarks().is_showing() and root.get_gameplay_host().get_node_or_null("LevelIntro") == null, "fresh L1 with its FTUE coachmark up: no intro")
	_shutdown(root)
	MainScript.boot_ftue_override = -1
	MainScript.boot_level_intro_override = -1
	_complete("app_not_over_coachmark")

# ---------------------------------------------------------------- helpers ----

func _boot_main(path: String):
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""

func _uniq(tag: String) -> String:
	var p := "user://sbvideo005_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS ", msg)
	else:
		_fail += 1
		print("  FAIL ", msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			_fail += 1
			print("  FAIL missing case ", c)
	print("SB-VIDEO-005 level intro: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
