extends SceneTree
## SB-POLISH-011 V1 character motion stills (two moments per surface, 1080x2160). WIN / LOSE /
## Need a Hand: the real app root (main.tscn) on an isolated temp save, catalog level 2, the
## real terminal signal (the host commits the terminal as in production); Need a Hand is the
## real third-failure offer. Level Intro has no live screen yet (SB-M43-170), so its `ready`
## motion is shown in a labelled HARNESS: the existing level_intro frame + normal emblem with
## the help pose, nothing else.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/character_motion_capture.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")

const PHONE := Vector2i(1080, 2160)
const MODE := {"won": "win", "lost": "lose", "nah": "help", "intro": "ready"}
## [scenario, [seconds after the motion starts, file stem] ...]
const SHOTS := [
	["won", [[0.30, "win_1_jump"], [1.45, "win_2_bob_sparkle"]]],
	["lost", [[0.55, "lose_1_droop"], [0.98, "lose_2_hopeful_hop"]]],
	["nah", [[0.12, "need_a_hand_1_slide_in"], [0.56, "need_a_hand_2_wave"]]],
	["intro", [[0.14, "harness_level_intro_1_squash_hop"], [0.24, "harness_level_intro_2_ready_peak"]]],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://character_motion"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var sc: String = shot[0]
	var sub := SubViewport.new()
	sub.size = PHONE
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var save_path := "user://character_motion_%d.save" % Time.get_ticks_usec()
	var root = null
	var target: Control = null
	if sc == "intro":
		target = _intro_harness(sub)
	else:
		MainScript.boot_save_path_override = save_path
		root = MainScene.instantiate()
		sub.add_child(root)
		await process_frame
		var app = root.get_app_state()
		var eco = app.economy
		eco.rewarded.set_provider(ProviderDouble.new())
		app.progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 2, "completed": [1]})
		eco.hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})
		root.play_current_frontier()
		await process_frame
		var h = root.get_gameplay_host()
		h.get_runtime().set_process(false)
		var fails := 3 if sc == "nah" else 1
		for i in range(fails):
			if i > 0:
				root.get_modal_stack().clear("t")
				root.retry_from_results()
				await process_frame
			h.get_completion().terminal_reached.emit(&"WON" if sc == "won" else &"LOST", {})
		var p = root.get_acquisition().find_open("need_a_hand")
		target = p.get_content().find_child("Scrubby", true, false) if sc == "nah" and p != null else root.get_results_screen().get_robot()
	# The real flow already started the motion; let the screen settle, then restart the SAME
	# motion at t = 0 so each still sits at an exact, repeatable moment.
	for _i in range(10):
		await process_frame
	if target != null:
		CharacterMotion.play(target, MODE[sc], false)
	var at := 0.0
	for moment in shot[1]:
		if target != null:
			at = _seek(target, at, moment[0])
		for _i in range(3):   # let the sparkle particles draw a few frames (motion stays frozen)
			await RenderingServer.frame_post_draw
		var path := "%s/%s_%dx%d.png" % [out_dir, moment[1], PHONE.x, PHONE.y]
		if target == null or not target.has_meta(CharacterMotion.META):
			_bad += 1
			print("REJECTED ", path, " (no live motion)")
			continue
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " t=%.2f s scale=%s rot=%.3f" % [at, target.scale, target.rotation])
	if root != null:
		root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))

## Deterministic time: freeze the live motion tween(s) and step them from `from` to `to` seconds
## after the motion started (the intro -> loop hand-off re-reads the live tween each step).
func _seek(c: Control, from: float, to: float) -> float:
	var t := from
	while t < to - 0.0001:
		var tw: Tween = c.get_meta(CharacterMotion.META) if c.has_meta(CharacterMotion.META) else null
		if tw == null or not tw.is_valid():
			break
		tw.pause()
		var d := minf(1.0 / 120.0, to - t)
		tw.custom_step(d)
		t += d
	if c.has_meta(CharacterMotion.META):
		(c.get_meta(CharacterMotion.META) as Tween).pause()
	return t

## HARNESS only (no live Level Intro screen): existing intro frame + emblem + help pose.
func _intro_harness(sub: SubViewport) -> Control:
	var bg := ColorRect.new()
	bg.color = Color("#202533")
	bg.size = Vector2(PHONE)
	sub.add_child(bg)
	var frame := TextureRect.new()
	frame.texture = load("res://assets/ui/final/popups/level_intro/level_intro_frame.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.position = Vector2(90, 760)
	frame.size = Vector2(900, 900)
	bg.add_child(frame)
	var emblem := TextureRect.new()
	emblem.texture = load("res://assets/ui/final/popups/level_intro/normal_level_emblem.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.position = Vector2(420, 1040)
	emblem.size = Vector2(240, 240)
	bg.add_child(emblem)
	var bot := TextureRect.new()
	bot.texture = load("res://assets/ui/final/popups/help/help_scrubby_pose.png")
	bot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bot.position = Vector2(370, 440)
	bot.size = Vector2(340, 340)
	bg.add_child(bot)
	return bot
