extends SceneTree
## SB-VIDEO-007 / SB-VIDEO-008 — Collection SET COMPLETE ceremony and Welcome back (comeback)
## hero videos (scripts/ui/ceremony/meta_ceremonies.gd, scripts/ui/profile/profile_screens.gd):
##   FULL effects: ONE magenta-keyed video plays in the hero slot (set badge with a soft edge fade;
##   Scrubby on the comeback screen when Scrubby is the active robot), the static art hidden under
##   it and replaced by the keyed last frame it holds afterwards; the CTA stays usable; finishing or
##   closing the popup frees the decoder. Reduced Effects, another robot (comeback), a missing or
##   failing stream = the static hero exactly as before, no VideoStreamPlayer. Nothing granted.
##
## Run: godot --headless --path . -s res://tests/sb_video_007_008_set_complete_welcome_video.gd

const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

var EXPECTED_CASES := [
	"set_full_plays", "set_reduced_static", "set_finish_holds_last_frame", "set_close_frees_decoder",
	"set_failure_fallback", "welcome_full_plays", "welcome_finish_and_close", "welcome_static_paths",
]

var _fail := 0
var _completed: Dictionary = {}
var _stack
var _set_video: VideoStream
var _welcome_video: VideoStream
var _sub: SubViewport
var _root = null
var _save := ""

func _initialize() -> void:
	_set_video = MetaCeremonies.set_video
	_welcome_video = ProfileScreens.welcome_video
	_stack = ModalStack.new()
	get_root().add_child(_stack)
	await process_frame
	await _set_full_plays()
	await _set_reduced_static()
	await _set_finish_holds_last_frame()
	await _set_close_frees_decoder()
	await _set_failure_fallback()
	await _boot()
	await _welcome_full_plays()
	await _welcome_finish_and_close()
	await _welcome_static_paths()
	_shutdown()
	_done()

## Open one set-complete ceremony on the stack (CeremonyPresenter order: push, then start_motion).
func _open_set(reduced := false):
	var p = MetaCeremonies.build({"key": "set:t1", "kind": "set_complete", "set": 1, "name": "Test",
		"rewards": {"scrub_bucks": 100, "bot_parts": 2}}, reduced)
	_stack.push(p)
	MetaCeremonies.start_motion(p)
	await process_frame
	return p

func _players(n: Node) -> Array:
	return n.find_children("*", "VideoStreamPlayer", true, false)

func _hero(p) -> TextureRect:
	return p.find_child("HeroArt", true, false)

func _shut(p) -> void:
	p.close("test")
	await process_frame
	await process_frame

# ------------------------------------------------------------- set complete ----

func _set_full_plays() -> void:
	var p = await _open_set()
	var v: Array = _players(p)
	_ok(v.size() == 1 and v[0].is_playing() and v[0].stream == MetaCeremonies.set_video, "set complete plays the badge video (one decoder)")
	var m := v[0].material as ShaderMaterial if v.size() == 1 else null
	_ok(m != null and m.shader == MetaCeremonies.CHROMA_KEY_MAGENTA and is_equal_approx(float(m.get_shader_parameter("edge_fade")), 0.06) and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "magenta-keyed with the 6 % edge fade, ignores input")
	var h := _hero(p)
	_ok(h.self_modulate.a == 0.0 and h.texture.resource_path == MetaCeremonies.SET_VIDEO_DIR + "set_complete_badge_still.png" and h.custom_minimum_size == MetaCeremonies.SET_VIDEO_SIZE, "static emblem hidden; hero holds the keyed last frame at the video size")
	var b: Button = p.get_action_button("continue")
	_ok(p.find_child("SetCards", true, false).is_visible_in_tree() and p.find_child("RewardRows", true, false).is_visible_in_tree() and b.is_visible_in_tree() and not b.disabled, "cards, rewards and CONTINUE usable while the video plays")
	var closed := [""]
	p.closed.connect(func(r): closed[0] = r)
	b.pressed.emit()
	await process_frame
	await process_frame
	_ok(closed[0] == "action:continue" and not is_instance_valid(p), "CONTINUE closes the ceremony mid-video")
	_complete("set_full_plays")

func _set_reduced_static() -> void:
	var p = await _open_set(true)
	var h := _hero(p)
	_ok(_players(p).is_empty(), "Reduced: no VideoStreamPlayer")
	_ok(h.texture.resource_path == MetaCeremonies.ART["set_complete"] and h.self_modulate.a == 1.0 and h.custom_minimum_size == Vector2(230, 230), "Reduced: static emblem exactly as before")
	await _shut(p)
	_complete("set_reduced_static")

func _set_finish_holds_last_frame() -> void:
	var p = await _open_set()
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	var h := _hero(p)
	_ok(not is_instance_valid(v) and _players(p).is_empty(), "finishing frees the decoder")
	_ok(h.self_modulate.a == 1.0 and h.texture.resource_path == MetaCeremonies.SET_VIDEO_DIR + "set_complete_badge_still.png", "hero holds the keyed last frame (glowing badge)")
	_ok(p.is_open() and p.get_action_button("continue").is_visible_in_tree(), "popup stays open with its CTA")
	await _shut(p)
	_complete("set_finish_holds_last_frame")

func _set_close_frees_decoder() -> void:
	var p = await _open_set()
	var v: VideoStreamPlayer = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree(), "closing the popup takes the decoder out of the tree")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("set_close_frees_decoder")

func _set_failure_fallback() -> void:
	var broken := VideoStreamTheora.new()
	broken.file = "res://assets/ui/final/rewards/set_complete_video/missing.ogv"
	for injected in [null, broken]:
		MetaCeremonies.set_video = injected
		var p = await _open_set()
		var h := _hero(p)
		var tag := "null" if injected == null else "broken"
		_ok(_players(p).is_empty() and p.find_child("HeroVideoBox", true, false) == null, "%s stream: no decoder left" % tag)
		_ok(h.texture.resource_path == MetaCeremonies.ART["set_complete"] and h.self_modulate.a == 1.0 and h.custom_minimum_size == Vector2(230, 230), "%s stream: static emblem exactly as before" % tag)
		await _shut(p)
	MetaCeremonies.set_video = _set_video
	_complete("set_failure_fallback")

# ------------------------------------------------------------- welcome back ----

## Real app root on a throw-away save (never the owner's save).
func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_save = "user://sb_video_008_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	for _i in range(4):
		await process_frame
	var top = _root.get_modal_stack().top()
	while top != null:   # first-run popups: not part of this suite
		top.close("test")
		await process_frame
		await process_frame
		top = _root.get_modal_stack().top()

func _open_welcome():
	var p = ProfileScreens.open_comeback(_root.get_modal_stack(), _root.get_app_state())
	await process_frame
	return p

func _welcome_full_plays() -> void:
	var app = _root.get_app_state()
	var sb0: int = app.economy.wallet.scrub_bucks()
	_ok(app.economy.robots.active_robot() == "scrubby" and not app.effects.is_reduced(), "fixture: Scrubby active, FULL effects")
	var p = await _open_welcome()
	var v: Array = _players(p)
	_ok(v.size() == 1 and v[0].is_playing() and v[0].stream == ProfileScreens.welcome_video, "welcome back plays the Scrubby video (one decoder)")
	_ok(v.size() == 1 and (v[0].material as ShaderMaterial).shader == MetaCeremonies.CHROMA_KEY_MAGENTA and [null, 0.0].has((v[0].material as ShaderMaterial).get_shader_parameter("edge_fade")) and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "magenta-keyed, no edge fade, ignores input")
	var h: TextureRect = p.get_hero()
	_ok(h.self_modulate.a == 0.0 and h.texture.resource_path == ProfileScreens.WELCOME_VIDEO_DIR + "welcome_back_scrubby_still.png" and h.custom_minimum_size == ProfileScreens.WELCOME_VIDEO_SIZE, "help pose hidden; hero holds the keyed last frame at the video size")
	var b: Button = p.get_action_button("ok")
	_ok(p.find_child("Hearts", true, false).is_visible_in_tree() and b.is_visible_in_tree() and not b.disabled, "summary lines and CONTINUE usable while the video plays")
	b.pressed.emit()
	await process_frame
	await process_frame
	_ok(not is_instance_valid(p) and _root.get_modal_stack().top() == null, "CONTINUE closes the welcome screen mid-video")
	_ok(app.economy.wallet.scrub_bucks() == sb0, "nothing granted")
	_complete("welcome_full_plays")

func _welcome_finish_and_close() -> void:
	var p = await _open_welcome()
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	_ok(not is_instance_valid(v) and _players(p).is_empty() and p.get_hero().self_modulate.a == 1.0, "finishing frees the decoder; keyed last frame held")
	await _shut(p)
	p = await _open_welcome()
	v = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree(), "closing mid-video takes the decoder out of the tree")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("welcome_finish_and_close")

func _welcome_static_paths() -> void:
	var app = _root.get_app_state()
	var pose := RobotRoster.asset("scrubby", "help_pose")
	var static_ok := func(p, tag: String) -> void:
		var h: TextureRect = p.get_hero()
		_ok(_players(p).is_empty() and p.find_child("HeroVideoBox", true, false) == null, "%s: no VideoStreamPlayer" % tag)
		_ok(h.texture.resource_path == pose and h.self_modulate.a == 1.0 and h.custom_minimum_size == Vector2(220, 220), "%s: static help pose exactly as before" % tag)
	app.set_reduced_effects(true)
	var p = await _open_welcome()
	static_ok.call(p, "Reduced")
	await _shut(p)
	app.set_reduced_effects(false)
	var broken := VideoStreamTheora.new()
	broken.file = "res://assets/ui/final/popups/welcome_video/missing.ogv"
	for injected in [null, broken]:
		ProfileScreens.welcome_video = injected
		p = await _open_welcome()
		static_ok.call(p, "null stream" if injected == null else "broken stream")
		await _shut(p)
	ProfileScreens.welcome_video = _welcome_video
	_complete("welcome_static_paths")

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	MainScript.boot_save_path_override = ""
	_stack.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))

# -------------------------------------------------------------------- harness ----

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS ", msg)
	else:
		_fail += 1
		print("  FAIL ", msg)

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			_fail += 1
			print("  FAIL missing case ", c)
	print("SB-VIDEO-007/008 set complete + welcome back video: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
