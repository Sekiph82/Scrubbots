extends SceneTree
## SB-VIDEO-009 / SB-POLISH-011B — New region (World Transition shell) and Need a Hand helper
## videos (scripts/ui/ceremony/meta_ceremonies.gd, scripts/ui/popup/acquisition_flow.gd):
##   FULL effects: ONE magenta-keyed Scrubby video plays (over the world art in the world unlock
##   ceremony; in place of the CharacterMotion `help` tween on the Need a Hand helper when the
##   helper is Scrubby), then the keyed last frame is held; the CTAs stay usable; finishing or
##   closing the popup frees the decoder. Reduced Effects, a missing or failing stream, or (Need a
##   Hand) another active robot = today's behaviour exactly, no VideoStreamPlayer. Nothing granted.
##
## Run: godot --headless --path . -s res://tests/sb_video_009_polish_011b_region_need_a_hand_video.gd

const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const AcquisitionFlow = preload("res://scripts/ui/popup/acquisition_flow.gd")
const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

const WORLD_ART := "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"
const OFFER := {"show": true, "level": 3, "picks": [{"id": "tornado"}, {"id": "random"}]}

var EXPECTED_CASES := [
	"region_full_plays", "region_finish_and_close", "region_static_paths",
	"nah_full_plays", "nah_finish_and_close", "nah_static_paths", "nah_other_robot",
]

var _fail := 0
var _completed: Dictionary = {}
var _stack
var _region_video: VideoStream
var _nah_video: VideoStream
var _sub: SubViewport
var _root = null
var _save := ""

func _initialize() -> void:
	_region_video = MetaCeremonies.region_video
	_nah_video = AcquisitionFlow.need_a_hand_video
	_stack = ModalStack.new()
	get_root().add_child(_stack)
	await process_frame
	await _region_full_plays()
	await _region_finish_and_close()
	await _region_static_paths()
	await _boot()
	await _nah_full_plays()
	await _nah_finish_and_close()
	await _nah_static_paths()
	await _nah_other_robot()
	_shutdown()
	_done()

func _players(n: Node) -> Array:
	return n.find_children("*", "VideoStreamPlayer", true, false)

func _shut(p) -> void:
	p.close("test")
	await process_frame
	await process_frame

# ------------------------------------------------------------- new region ----

## Open one world unlock ceremony on the stack (CeremonyPresenter order: push, then start_motion).
func _open_region(reduced := false):
	var p = MetaCeremonies.build({"key": "world:world_01", "kind": "world_unlock", "world_id": "world_01",
		"title": "WHISPERING PARK", "subtitle": "World 01", "art": WORLD_ART}, reduced)
	_stack.push(p)
	MetaCeremonies.start_motion(p)
	await process_frame
	return p

func _region_full_plays() -> void:
	var p = await _open_region()
	var v: Array = _players(p)
	_ok(v.size() == 1 and v[0].is_playing() and v[0].stream == MetaCeremonies.region_video, "world unlock plays the new region video (one decoder)")
	var m := v[0].material as ShaderMaterial if v.size() == 1 else null
	_ok(m != null and m.shader == MetaCeremonies.CHROMA_KEY_MAGENTA and [null, 0.0].has(m.get_shader_parameter("edge_fade")) and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "magenta-keyed, no edge fade, ignores input")
	var slot: Control = p.find_child("WorldArtSlot", true, false)
	var r: TextureRect = slot.get_node("RegionHero")
	var art: TextureRect = slot.get_node("WorldArt")
	_ok(art.texture.resource_path == WORLD_ART and art.self_modulate.a == 1.0, "world art stays visible under the video")
	_ok(r.self_modulate.a == 0.0 and r.texture.resource_path == MetaCeremonies.REGION_VIDEO_DIR + "new_region_scrubby_still.png" and r.mouse_filter == Control.MOUSE_FILTER_IGNORE, "overlay holds the keyed last frame, hidden while playing, ignores input")
	var b: Button = p.get_action_button("continue")
	_ok(p.find_child("WorldBody", true, false).is_visible_in_tree() and b.is_visible_in_tree() and not b.disabled, "text and CONTINUE usable while the video plays")
	var closed := [""]
	p.closed.connect(func(c): closed[0] = c)
	b.pressed.emit()
	await process_frame
	await process_frame
	_ok(closed[0] == "action:continue" and not is_instance_valid(p), "CONTINUE closes the ceremony mid-video")
	_complete("region_full_plays")

func _region_finish_and_close() -> void:
	var p = await _open_region()
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	var r: TextureRect = p.find_child("RegionHero", true, false)
	_ok(not is_instance_valid(v) and _players(p).is_empty(), "finishing frees the decoder")
	_ok(r.self_modulate.a == 1.0 and r.texture.resource_path == MetaCeremonies.REGION_VIDEO_DIR + "new_region_scrubby_still.png", "Scrubby's keyed ready pose held over the world art")
	_ok(p.is_open() and p.get_action_button("continue").is_visible_in_tree(), "popup stays open with its CTA")
	await _shut(p)
	p = await _open_region()
	v = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree(), "closing mid-video takes the decoder out of the tree")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("region_finish_and_close")

func _region_static_paths() -> void:
	var static_ok := func(p, tag: String) -> void:
		var slot: Control = p.find_child("WorldArtSlot", true, false)
		_ok(_players(p).is_empty() and slot.get_child_count() == 1 and slot.get_node("WorldArt").texture.resource_path == WORLD_ART, "%s: world art alone, no video node" % tag)
	var p = await _open_region(true)
	static_ok.call(p, "Reduced")
	await _shut(p)
	var broken := VideoStreamTheora.new()
	broken.file = MetaCeremonies.REGION_VIDEO_DIR + "missing.ogv"
	for injected in [null, broken]:
		MetaCeremonies.region_video = injected
		p = await _open_region()
		static_ok.call(p, "null stream" if injected == null else "broken stream")
		await _shut(p)
	MetaCeremonies.region_video = _region_video
	_complete("region_static_paths")

# ------------------------------------------------------------ Need a Hand ----

## Real app root on a throw-away save (never the owner's save).
func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_save = "user://sb_video_009_%d.save" % Time.get_ticks_usec()
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

func _open_nah(reduced := false):
	var p = _root.get_acquisition().open_need_a_hand(OFFER, reduced)
	await process_frame
	return p

func _helper(p) -> TextureRect:
	return p.get_content().find_child("Scrubby", true, false)

func _nah_full_plays() -> void:
	var app = _root.get_app_state()
	var sb0: int = app.economy.wallet.scrub_bucks()
	_ok(app.economy.robots.active_robot() == "scrubby", "fixture: Scrubby active")
	var p = await _open_nah()
	var v: Array = _players(p)
	var h := _helper(p)
	_ok(v.size() == 1 and v[0].is_playing() and v[0].stream == AcquisitionFlow.need_a_hand_video, "Need a Hand plays the Scrubby video (one decoder)")
	_ok(v.size() == 1 and (v[0].material as ShaderMaterial).shader == MetaCeremonies.CHROMA_KEY_MAGENTA and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "magenta-keyed, ignores input")
	_ok(not CharacterMotion.is_playing(h) and h.material == null, "no CharacterMotion help tween while the video plays")
	_ok(h.self_modulate.a == 0.0 and h.texture.resource_path == AcquisitionFlow.NAH_VIDEO_DIR + "need_a_hand_scrubby_still.png" and h.custom_minimum_size == AcquisitionFlow.NAH_VIDEO_SIZE, "help pose hidden; helper holds the keyed last frame at the video size")
	var ok_buttons := true
	for id in ["tornado", "random"]:
		var b: Button = p.get_action_button("buy:" + id)
		ok_buttons = ok_buttons and b != null and b.is_visible_in_tree() and not b.disabled
	_ok(ok_buttons and p.find_child("Card_tornado", true, false).is_visible_in_tree(), "booster cards and BUY buttons usable while the video plays (WATCH follows the ad provider, unchanged)")
	p.close("test")
	await process_frame
	await process_frame
	_ok(not is_instance_valid(p) and _root.get_modal_stack().top() == null, "close mid-video closes Need a Hand")
	_ok(app.economy.wallet.scrub_bucks() == sb0, "nothing granted")
	_complete("nah_full_plays")

func _nah_finish_and_close() -> void:
	var p = await _open_nah()
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	var h := _helper(p)
	_ok(not is_instance_valid(v) and _players(p).is_empty() and h.self_modulate.a == 1.0 and h.texture.resource_path == AcquisitionFlow.NAH_VIDEO_DIR + "need_a_hand_scrubby_still.png", "finishing frees the decoder; keyed start pose held")
	await _shut(p)
	p = await _open_nah()
	v = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree(), "closing mid-video takes the decoder out of the tree")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("nah_finish_and_close")

## Today's behaviour: the static help pose at 120x132; FULL slides in + waves, Reduced is still.
func _tween_ok(p, pose: String, reduced: bool, tag: String) -> void:
	var h := _helper(p)
	_ok(_players(p).is_empty() and p.find_child("HeroVideoBox", true, false) == null, "%s: no VideoStreamPlayer" % tag)
	_ok(h.texture.resource_path == pose and h.self_modulate.a == 1.0 and h.custom_minimum_size == Vector2(120, 132), "%s: static help pose exactly as before" % tag)
	_ok(CharacterMotion.is_playing(h) != reduced, "%s: CharacterMotion help tween %s" % [tag, "off" if reduced else "plays"])

func _nah_static_paths() -> void:
	var p = await _open_nah(true)
	_tween_ok(p, AcquisitionFlow.LIFE_HERO_ART, true, "Reduced")
	await _shut(p)
	var broken := VideoStreamTheora.new()
	broken.file = AcquisitionFlow.NAH_VIDEO_DIR + "missing.ogv"
	for injected in [null, broken]:
		AcquisitionFlow.need_a_hand_video = injected
		p = await _open_nah()
		_tween_ok(p, AcquisitionFlow.LIFE_HERO_ART, false, "null stream" if injected == null else "broken stream")
		await _shut(p)
	AcquisitionFlow.need_a_hand_video = _nah_video
	_complete("nah_static_paths")

func _nah_other_robot() -> void:
	var robots = _root.get_app_state().economy.robots
	_ok(robots.import_snapshot({"unlocked": ["scrubby", "atlas"], "active": "atlas"}) and robots.active_robot() == "atlas", "fixture: Atlas active (throw-away save)")
	var p = await _open_nah()
	_tween_ok(p, RobotRoster.asset("atlas", "help_pose"), false, "Atlas helper")
	await _shut(p)
	robots.set_active("scrubby")
	_complete("nah_other_robot")

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
	print("SB-VIDEO-009/SB-POLISH-011B new region + Need a Hand video: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
