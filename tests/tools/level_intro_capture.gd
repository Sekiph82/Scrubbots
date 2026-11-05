extends SceneTree
## SB-VIDEO-005 evidence: the real app root (temp save) in a 1080x2160 SubViewport, PLAY the
## frontier, two frames of the Level Intro over the live board while the keyed video plays.
## Run: godot --path . --rendering-driver opengl3 -s res://tests/tools/level_intro_capture.gd -- <out dir>
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var save := "user://sbvideo005_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = save
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 1
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2160)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var root = MainScene.instantiate()
	vp.add_child(root)
	await process_frame
	root.play_current_frontier()
	var t0 := Time.get_ticks_msec()
	var shot := 0
	for at in [1.0, 2.4]:
		while (Time.get_ticks_msec() - t0) / 1000.0 < at:
			await process_frame
		await RenderingServer.frame_post_draw
		var intro = root.get_gameplay_host().get_node_or_null("LevelIntro")
		print("t=", at, " intro=", intro != null, " video=", intro != null and intro.get_video_player() != null)
		vp.get_texture().get_image().save_png("%s/level_intro_%d_1080x2160.png" % [out, shot])
		shot += 1
	root.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save + suffix))
	quit(0)
