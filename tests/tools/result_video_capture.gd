extends SceneTree
## SB-VIDEO-001/002 evidence: the real ResultsScreen in a 1080x2160 SubViewport, WIN and LOSE,
## two frames each while the keyed video plays (BG01 behind the Results dim).
## Run: godot --path . --rendering-driver opengl3 -s res://tests/tools/result_video_capture.gd -- <out dir>
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2160)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("#202533")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(bg)
	var res = ResultsScreen.new()
	vp.add_child(res)
	await process_frame
	var won := {"status": "WON", "level": 12, "attempt": 1, "robot_id": "scrubby", "continue": {"available": true, "next_level": 13},
		"receipt": {"status": "WON", "reveal_queue": [{"kind": "first_clear_sb", "amount": 25}, {"kind": "bot_parts", "amount": 5}]}}
	var lost := {"status": "LOST", "level": 12, "attempt": 2, "robot_id": "scrubby", "continue": {"available": false},
		"receipt": {"status": "LOST", "hearts": {"before": 5, "after": 4}, "streak": {"before": 3, "after": 0}}}
	for pair in [["win", won], ["lose", lost]]:
		res.show_model(pair[1])
		res.finish_reveal()
		var shots := 0
		var t0 := Time.get_ticks_msec()
		for at in [1.6, 4.2]:
			while (Time.get_ticks_msec() - t0) / 1000.0 < at:
				await process_frame
			await RenderingServer.frame_post_draw
			var v = res.get_result_video()
			print(pair[0], " t=", at, " video=", v != null and v.is_playing(), " pos=", v.stream_position if v != null else -1.0)
			vp.get_texture().get_image().save_png("%s/results_%s_%d_1080x2160.png" % [out, pair[0], shots])
			shots += 1
	quit(0)
