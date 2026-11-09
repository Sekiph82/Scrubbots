extends SceneTree
## SB-VIDEO-010 evidence: the shipping Robot Unlock ceremony on a real ModalStack over BG01
## (1080x1920 SubViewport), one robot per key colour (moppy magenta, bubbles green, clippy blue):
## one frame mid-video and one after it finished (the keyed last frame held). No save is touched.
## Run: godot --path . --rendering-driver opengl3 -s res://tests/tools/robot_unlock_video_capture.gd -- <out dir>
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await process_frame   # a decoder started before the first frame does not play
	for id in ["moppy", "bubbles", "clippy"]:
		var sub := SubViewport.new()
		sub.size = Vector2i(1080, 1920)
		sub.disable_3d = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(sub)
		var bg := ColorRect.new()
		bg.color = Color(0.125, 0.145, 0.2)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		sub.add_child(bg)
		var stack = ModalStack.new()
		sub.add_child(stack)
		var p = MetaCeremonies.build({"key": "robot:" + id, "kind": "robot_unlock", "robot_id": id, "parts_left": 37,
			"active_robot": "scrubby"})
		stack.push(p)
		MetaCeremonies.start_motion(p)
		var t0 := Time.get_ticks_msec()
		for at in [4.0, 9.0]:
			while (Time.get_ticks_msec() - t0) / 1000.0 < at:
				await process_frame
			await RenderingServer.frame_post_draw
			var playing: bool = p.find_child("HeroVideo", true, false) != null
			var path := "%s/robot_%s_%s_1080x1920.png" % [out, id, "video" if playing else "held"]
			print("t=", at, " video=", playing, " ", path, " err=", sub.get_texture().get_image().save_png(path))
		sub.free()
		await process_frame
	quit(0)
