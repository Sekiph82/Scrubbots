extends SceneTree
## SB-VIDEO-003/004 evidence: the real Standard / Premium ceremonies in a 1080x2160 SubViewport,
## Flow video mid-play, then the native reveal after the flash (the video plays to its end).
## Run: godot --path . --rendering-driver opengl3 -s res://tests/tools/pack_video_capture.gd -- <out dir>
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")
const PFx = preload("res://tests/support/premium_pack_fixtures.gd")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2160)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var stack = ModalStack.new()
	vp.add_child(stack)
	stack.set_synthetic_safe_insets(0, 96, 0, 64)
	for kind in ["standard", "premium"]:
		var p = StandardPackCeremony.create(Fx.mixed("cap_std"))["popup"] if kind == "standard" else PremiumPackCeremony.create_premium(PFx.mixed("cap_prem"))["popup"]
		stack.push(p)
		for _i in range(5):
			await process_frame
		p.tap()
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 3500:
			await process_frame
		await RenderingServer.frame_post_draw
		var v = p.get_video_player()
		print(kind, " mid: video=", v != null and v.is_playing(), " pos=", v.stream_position if v != null else -1.0)
		vp.get_texture().get_image().save_png("%s/pack_%s_0_video_1080x2160.png" % [out, kind])
		while p.phase() != "AWAIT_ROUTE":
			await process_frame
		t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 400:
			await process_frame
		await RenderingServer.frame_post_draw
		print(kind, " reveal: phase=", p.phase(), " decoders=", p.find_children("*", "VideoStreamPlayer", true, false).size())
		vp.get_texture().get_image().save_png("%s/pack_%s_1_reveal_1080x2160.png" % [out, kind])
		p.close("capture")
		await process_frame
	quit(0)
