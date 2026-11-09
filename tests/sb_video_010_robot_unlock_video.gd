extends SceneTree
## SB-VIDEO-010 — Robot Unlock ceremony signature video (scripts/ui/ceremony/meta_ceremonies.gd):
##   every roster robot id maps to its own keyed Flow video + keyed last-frame still under
##   robots/unlock_videos/ and to the shader for its background (magenta / green / blue).
##   FULL effects: start_motion plays ONE video in the hero slot (static roster art hidden under
##   it, hero 400x480) and then holds the keyed last frame; EQUIP / KEEP stay usable while it plays;
##   finishing or closing frees the decoder. Reduced Effects, a missing or failing stream = the
##   static roster art exactly as before, no VideoStreamPlayer.
##
## Run: godot --headless --path . -s res://tests/sb_video_010_robot_unlock_video.gd

const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

const KEYS := {"bubbles": "green", "polly": "green", "clippy": "blue"}   # every other robot: magenta
const STATIC_SIZE := Vector2(330, 396)

var EXPECTED_CASES := [
	"ids_map_streams", "full_plays", "reduced_static", "buttons_usable", "finish_holds_last_frame",
	"close_frees_decoder", "failure_fallback",
]

var _fail := 0
var _completed: Dictionary = {}
var _stack

func _initialize() -> void:
	_stack = ModalStack.new()
	get_root().add_child(_stack)
	await process_frame
	_ids_map_streams()
	await _full_plays()
	await _reduced_static()
	await _buttons_usable()
	await _finish_holds_last_frame()
	await _close_frees_decoder()
	await _failure_fallback()
	_done()

## Open one robot unlock ceremony on the stack (CeremonyPresenter order: push, then start_motion).
func _open(id: String, reduced := false):
	var p = MetaCeremonies.build({"key": "robot:" + id, "kind": "robot_unlock", "robot_id": id, "parts_left": 37,
		"active_robot": "scrubby"}, reduced)
	_stack.push(p)
	MetaCeremonies.start_motion(p)
	await process_frame
	return p

func _players(n: Node) -> Array:
	return n.find_children("*", "VideoStreamPlayer", true, false)

func _hero(p) -> TextureRect:
	return p.find_child("HeroArt", true, false)

func _shader(id: String) -> Shader:
	return {"green": MetaCeremonies.CHROMA_KEY_GREEN, "blue": MetaCeremonies.CHROMA_KEY_BLUE}.get(KEYS.get(id, ""), MetaCeremonies.CHROMA_KEY_MAGENTA)

func _shut(p) -> void:
	if is_instance_valid(p):
		p.close("test")
	await process_frame
	await process_frame

# ------------------------------------------------------------------ cases ----

func _ids_map_streams() -> void:
	var ids := RobotRoster.ids()
	_ok(ids.size() == 10, "roster has 10 robots (%d)" % ids.size())
	for id in ids:
		var base := MetaCeremonies.ROBOT_VIDEO_DIR + String(id) + "_unlock"
		var s = load(base + ".ogv") if ResourceLoader.exists(base + ".ogv") else null
		var still = load(base + "_still.png") if ResourceLoader.exists(base + "_still.png") else null
		_ok(s is VideoStreamTheora, "%s: %s.ogv is a Theora stream" % [id, base])
		_ok(still is Texture2D and still.get_size() == Vector2(480, 576), "%s: keyed 480x576 last-frame still" % id)
	_ok(MetaCeremonies.CHROMA_KEY_BLUE.code.contains("c.b - max(c.r, c.g)") and MetaCeremonies.CHROMA_KEY_GREEN != MetaCeremonies.CHROMA_KEY_BLUE, "blue key shader keys B - max(R, G)")
	_complete("ids_map_streams")

func _full_plays() -> void:
	for id in RobotRoster.ids():   # scrubby is the starter: no ceremony path emits it, the builder still maps it
		var p = await _open(id)
		var v: Array = _players(p)
		_ok(v.size() == 1 and v[0].is_playing() and v[0].stream.resource_path == MetaCeremonies.ROBOT_VIDEO_DIR + id + "_unlock.ogv", "%s plays its own video (one decoder)" % id)
		if v.size() == 1:
			var m := v[0].material as ShaderMaterial
			_ok(m.shader == _shader(id) and m.get_shader_parameter("edge_fade") == MetaCeremonies.ROBOT_VIDEO_EDGE and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: %s key, edge fade, ignores input" % [id, KEYS.get(id, "magenta")])
		var h := _hero(p)
		_ok(h.self_modulate.a == 0.0 and h.texture.resource_path == MetaCeremonies.ROBOT_VIDEO_DIR + id + "_unlock_still.png", "%s: roster art hidden; hero holds the keyed last frame under the video" % id)
		_ok(h.custom_minimum_size == MetaCeremonies.ROBOT_VIDEO_SIZE, "%s: hero sized to the video box" % id)
		await _shut(p)
	_complete("full_plays")

func _reduced_static() -> void:
	for id in ["moppy", "bubbles", "clippy"]:
		var p = await _open(id, true)
		var h := _hero(p)
		_ok(_players(p).is_empty() and not p.find_child("HeroBox", true, false).has_meta("video"), "Reduced %s: no VideoStreamPlayer" % id)
		_ok(h.texture.resource_path == RobotRoster.asset(id, "master") and h.self_modulate.a == 1.0 and h.custom_minimum_size == STATIC_SIZE, "Reduced %s: static roster art exactly as before" % id)
		await _shut(p)
	_complete("reduced_static")

func _buttons_usable() -> void:
	for action in ["equip", "keep"]:
		var p = await _open("polly")
		var closed := [""]
		p.closed.connect(func(r): closed[0] = r)
		var b: Button = p.get_action_button(action)
		_ok(_players(p).size() == 1 and p.find_child("Perk", true, false).is_visible_in_tree(), "perk card shown while the video plays")
		_ok(b.is_visible_in_tree() and not b.disabled, "%s visible and enabled while the video plays" % action.to_upper())
		b.pressed.emit()
		await process_frame
		await process_frame
		_ok(closed[0] == "action:" + action and not is_instance_valid(p), "%s closes the ceremony mid-video" % action.to_upper())
	_complete("buttons_usable")

func _finish_holds_last_frame() -> void:
	var p = await _open("clippy")
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	var h := _hero(p)
	_ok(not is_instance_valid(v) and _players(p).is_empty(), "finishing frees the decoder")
	_ok(h.self_modulate.a == 1.0 and h.texture.resource_path == MetaCeremonies.ROBOT_VIDEO_DIR + "clippy_unlock_still.png", "hero holds the keyed last frame")
	_ok(p.is_open() and p.get_action_button("equip").is_visible_in_tree(), "popup stays open with its CTAs")
	await _shut(p)
	_complete("finish_holds_last_frame")

func _close_frees_decoder() -> void:
	var p = await _open("atlas")
	var v: VideoStreamPlayer = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree() and (v.get_parent().is_queued_for_deletion() or p.is_queued_for_deletion()), "closing the popup takes the decoder out of the tree, queued for free")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("close_frees_decoder")

func _failure_fallback() -> void:
	var broken := VideoStreamTheora.new()
	broken.file = MetaCeremonies.ROBOT_VIDEO_DIR + "missing.ogv"
	for injected in [null, broken]:
		for id in ["spark", "bubbles"]:
			MetaCeremonies.robot_video[id] = injected
			var p = await _open(id)
			var h := _hero(p)
			var tag := "%s stream, %s" % ["null" if injected == null else "broken", id]
			_ok(_players(p).is_empty() and p.find_child("HeroVideoBox", true, false) == null, tag + ": no decoder left")
			_ok(h.texture.resource_path == RobotRoster.asset(id, "master") and h.self_modulate.a == 1.0 and h.custom_minimum_size == STATIC_SIZE, tag + ": static roster art exactly as before")
			await _shut(p)
	MetaCeremonies.robot_video.clear()
	_complete("failure_fallback")

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
	print("SB-VIDEO-010 robot unlock video: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
