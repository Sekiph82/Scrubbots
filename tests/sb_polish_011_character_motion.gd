extends SceneTree
## SB-POLISH-011 V1 — CharacterMotion (scripts/ui/feel/character_motion.gd) on the existing robot
## art, and its WON / LOST Results wiring:
##   every mode moves the character and every mode ends on the static pose (stop / ready end);
##   ready < 1 s; win loop sparkles with ONE emitter that stop() removes; a replay never stacks;
##   Reduced = static, no material, no node; Results WON / LOST play, hidden stops, a re-show of
##   the same terminal skips the intro, repeated Results leave no extra nodes, CLEAN NEXT stays
##   live and the robot never takes input.
## SB-VIDEO-001/002 — Scrubby's Results play the keyed WIN / LOSE video once (one decoder, freed on
##   hide / finish, still held after), Reduced = keyed still only, other robots and a failing video
##   keep the pose + CharacterMotion (the CharacterMotion cases above use a non-Scrubby robot).
##
## Run: godot --headless --path . -s res://tests/sb_polish_011_character_motion.gd

const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")

var EXPECTED_CASES := [
	"modes_move", "ready_under_1s", "win_loop_sparkle", "replay_no_stack", "reduced_static",
	"results_won_lost", "results_hidden_stops", "results_reshow_skips_intro", "results_no_node_growth",
	"results_input_live", "video_scrubby_win_lose", "video_reduced_still", "video_other_robot",
	"video_fail_fallback", "video_freed_on_hide", "video_finish_holds_still",
]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	await _modes_move()
	await _ready_under_1s()
	await _win_loop_sparkle()
	_replay_no_stack()
	_reduced_static()
	await _results()
	await _video()
	_done()

func _char() -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/ui/final/popups/victory/victory_scrubby_pose.png")
	t.size = Vector2(340, 340)
	get_root().add_child(t)
	return t

static func _offset(c: Control) -> Vector2:
	return (c.material as ShaderMaterial).get_shader_parameter("offset") if c.material is ShaderMaterial else Vector2.ZERO

static func _static(c: Control) -> bool:
	return c.scale == Vector2.ONE and c.rotation == 0.0 and c.modulate.a == 1.0 and _offset(c) == Vector2.ZERO

func _wait(s: float) -> void:
	await create_timer(s).timeout

# ------------------------------------------------------------------ cases ----

func _modes_move() -> void:
	for mode in CharacterMotion.MODES:
		var c := _char()
		CharacterMotion.play(c, mode, false)
		await _wait(0.2)
		_ok(CharacterMotion.is_playing(c) and not _static(c) and c.pivot_offset_ratio == Vector2(0.5, 1.0), "%s: moving at 0.2 s (scale %s rot %.3f off %s)" % [mode, c.scale, c.rotation, _offset(c)])
		CharacterMotion.stop(c)
		_ok(_static(c) and not CharacterMotion.is_playing(c), "%s: stop() = static pose" % mode)
		c.free()
	_complete("modes_move")

func _ready_under_1s() -> void:
	_ok(CharacterMotion.READY_S < 1.0, "ready total %.2f s < 1 s" % CharacterMotion.READY_S)
	var c := _char()
	CharacterMotion.play(c, "ready", false)
	await _wait(CharacterMotion.READY_S + 0.15)
	_ok(not CharacterMotion.is_playing(c) and _static(c), "ready finished on the static pose before 1 s")
	c.free()
	_complete("ready_under_1s")

func _win_loop_sparkle() -> void:
	var c := _char()
	Engine.time_scale = 4.0
	CharacterMotion.play(c, "win", false)
	await _wait(0.82 + 2.0 * 2 + 0.1)   # intro + two loop cycles (scaled time)
	Engine.time_scale = 1.0
	var sparks := c.get_children().filter(func(n): return n.name == "Sparkle")
	_ok(CharacterMotion.is_playing(c) and sparks.size() == 1 and sparks[0] is CPUParticles2D, "win loop: still looping, exactly one Sparkle emitter after 2 cycles")
	CharacterMotion.stop(c)
	_ok(_static(c) and c.get_child_count() == 0, "stop(): static pose, Sparkle removed")
	c.free()
	_complete("win_loop_sparkle")

func _replay_no_stack() -> void:
	var c := _char()
	CharacterMotion.play(c, "win", false)
	var first: Tween = c.get_meta(CharacterMotion.META)
	CharacterMotion.play(c, "lose", false)
	_ok(not first.is_valid() and CharacterMotion.is_playing(c), "a replay kills the previous motion (one live tween)")
	CharacterMotion.stop(c)
	c.free()
	_complete("replay_no_stack")

func _reduced_static() -> void:
	for mode in CharacterMotion.MODES:
		var c := _char()
		CharacterMotion.play(c, mode, true)
		_ok(not CharacterMotion.is_playing(c) and _static(c) and c.material == null and c.get_child_count() == 0, "%s Reduced: static, no material, no node" % mode)
		c.free()
	var out := TextureRect.new()
	CharacterMotion.play(out, "win", false)
	_ok(not CharacterMotion.is_playing(out), "outside the tree: nothing starts")
	out.free()
	_complete("reduced_static")

func _model(status: String, attempt: int, reduced := false, robot := "spark") -> Dictionary:
	return {"status": status, "level": 3, "attempt": attempt, "receipt": {}, "continue": {"available": true, "next_level": 4}, "reduced_effects": reduced, "robot_id": robot}

func _results() -> void:
	var res = ResultsScreen.new()
	get_root().add_child(res)
	await process_frame
	var robot: TextureRect = res.get_robot()
	res.show_model(_model("WON", 1))
	await _wait(0.15)
	_ok(CharacterMotion.is_playing(robot) and robot.scale.y < 1.0, "WON: intro crouch running (scale %s)" % robot.scale)
	res.show_model(_model("LOST", 2))
	await _wait(0.2)
	_ok(CharacterMotion.is_playing(robot) and robot.scale.y < 1.0 and robot.rotation < 0.0, "LOST: droop running (scale %s rot %.3f)" % [robot.scale, robot.rotation])
	res.show_model(_model("WON", 3, true))
	await _wait(0.2)
	_ok(not CharacterMotion.is_playing(robot) and _static(robot), "Reduced Effects model: static robot")
	res.show_model(_model("ERROR", 4))
	_ok(not CharacterMotion.is_playing(robot) and _static(robot), "ERROR fallback: no motion")
	_complete("results_won_lost")

	res.show_model(_model("WON", 5))
	await _wait(0.1)
	res.visible = false
	_ok(not CharacterMotion.is_playing(robot) and _static(robot) and robot.get_node_or_null("Sparkle") == null, "hidden Results: robot stopped on the static pose")
	_complete("results_hidden_stops")

	res.visible = true
	res.show_model(_model("WON", 5))   # same terminal re-shown (e.g. Continue re-arm)
	await _wait(0.15)
	_ok(CharacterMotion.is_playing(robot) and robot.scale.y >= 1.0, "re-show of the same terminal: idle bob, no second jump (scale %s)" % robot.scale)
	_complete("results_reshow_skips_intro")

	res.visible = false
	await process_frame
	var base := _count(res)
	Engine.time_scale = 4.0
	for i in range(4):
		res.visible = true
		res.show_model(_model("WON", 10 + i))
		await _wait(3.0)   # intro + a sparkle cycle (scaled time)
		res.visible = false
		await process_frame
	Engine.time_scale = 1.0
	_ok(_count(res) == base, "4 WON Results with sparkles, then hidden: node count %d == %d" % [_count(res), base])
	_complete("results_no_node_growth")

	res.visible = true
	res.show_model(_model("WON", 20))
	await process_frame
	var got := [0]
	res.continue_requested.connect(func(_a): got[0] += 1)
	var primary: Button = res.get_primary_button()
	_ok(CharacterMotion.is_playing(robot) and robot.mouse_filter == Control.MOUSE_FILTER_IGNORE and not primary.disabled, "during the intro: robot ignores input, CLEAN NEXT enabled")
	primary.pressed.emit()
	_ok(got[0] == 1, "CLEAN NEXT accepted mid-animation")
	_complete("results_input_live")
	res.free()

func _video() -> void:
	var res = ResultsScreen.new()
	get_root().add_child(res)
	await process_frame
	var robot: TextureRect = res.get_robot()
	var slot: Control = robot.get_parent()
	res.show_model(_model("WON", 1, false, ""))
	await process_frame
	var slot_size: Vector2 = slot.size
	var v: VideoStreamPlayer = res.get_result_video()
	_ok(v != null and v.is_playing() and v.stream.resource_path == ResultsScreen.WIN_VIDEO and (v.material as ShaderMaterial).shader == ResultsScreen.CHROMA_KEY, "Scrubby WON: keyed WIN video playing")
	_ok(robot.texture.resource_path == ResultsScreen.WIN_STILL and robot.self_modulate.a == 0.0 and not CharacterMotion.is_playing(robot), "Scrubby WON: still bound under the video, no tween")
	_ok(_players(res) == 1 and v.mouse_filter == Control.MOUSE_FILTER_IGNORE and not res.get_primary_button().disabled, "one decoder, ignores input, CLEAN NEXT live")
	res.show_model(_model("LOST", 2, false, "scrubby"))
	await process_frame
	v = res.get_result_video()
	_ok(v != null and v.is_playing() and v.stream.resource_path == ResultsScreen.LOSE_VIDEO and robot.texture.resource_path == ResultsScreen.LOSE_STILL, "Scrubby LOST: keyed LOSE video playing")
	_ok(_players(res) == 1 and slot.size == slot_size, "LOST after WON: still one decoder, robot slot rect unchanged (%s)" % slot.size)
	_complete("video_scrubby_win_lose")

	res.show_model(_model("WON", 3, true, ""))
	await process_frame
	_ok(res.get_result_video() == null and _players(res) == 0 and robot.texture.resource_path == ResultsScreen.WIN_STILL and robot.self_modulate.a == 1.0 and _static(robot) and not CharacterMotion.is_playing(robot), "Reduced Effects: keyed still only, no decoder, no tween")
	_complete("video_reduced_still")

	res.show_model(_model("WON", 4, false, "spark"))
	await _wait(0.15)
	_ok(res.get_result_video() == null and _players(res) == 0 and robot.texture.resource_path.contains("/victory/robots/") and CharacterMotion.is_playing(robot), "other robot: approved pose + CharacterMotion, no video")
	_complete("video_other_robot")

	var still: Texture2D = load(ResultsScreen.WIN_STILL)
	var bad := VideoStreamTheora.new()
	bad.file = "res://tests/__missing_video__.ogv"
	_ok(not res._start_video(null, still) and not res._start_video(bad, still) and res.get_result_video() == null and _players(res) == 0 and robot.self_modulate.a == 1.0, "unloadable / unplayable video: refused, no decoder left, robot visible (caller keeps the tween)")
	_complete("video_fail_fallback")

	res.show_model(_model("WON", 5, false, ""))
	await process_frame
	res.visible = false
	await process_frame
	_ok(res.get_result_video() == null and _players(res) == 0 and robot.self_modulate.a == 1.0, "hidden Results: decoder stopped and freed")
	res.visible = true
	res.show_model(_model("WON", 5, false, ""))
	await process_frame
	_ok(res.get_result_video() == null and robot.texture.resource_path == ResultsScreen.WIN_STILL, "re-show of the same terminal: still only, the video is not replayed")
	_complete("video_freed_on_hide")

	res.show_model(_model("LOST", 6, false, ""))
	Engine.time_scale = 8.0
	var t := 0.0
	while res.get_result_video() != null and t < 3.0:
		await process_frame
		t += 1.0 / 60.0
	await process_frame
	Engine.time_scale = 1.0
	_ok(res.get_result_video() == null and _players(res) == 0 and robot.texture.resource_path == ResultsScreen.LOSE_STILL and robot.self_modulate.a == 1.0, "video finished: decoder freed, keyed LOSE still held")
	_complete("video_finish_holds_still")
	res.free()

func _players(n: Node) -> int:
	return n.find_children("*", "VideoStreamPlayer", true, false).size()

func _count(n: Node) -> int:
	var k := 1
	for c in n.get_children():
		k += _count(c)
	return k

# --------------------------------------------------------------- reporting ----

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
	print("SB-POLISH-011 character motion: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
