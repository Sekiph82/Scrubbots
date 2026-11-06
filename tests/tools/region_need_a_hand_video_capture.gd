extends SceneTree
## SB-VIDEO-009 / SB-POLISH-011B evidence (1080x1920 SubViewport, BG01): the World Transition shell
## (world unlock ceremony, fixture World 01 entry: no live world event exists) on a real ModalStack,
## and the real Need a Hand popup on the app root booted on a throw-away save; one frame mid-video
## and one after it finished (the keyed last frame held).
## Run: godot --path . --rendering-driver opengl3 -s res://tests/tools/region_need_a_hand_video_capture.gd -- <out dir>
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await process_frame   # a decoder started before the first frame does not play
	var sub := _sub()
	var stack = ModalStack.new()
	sub.add_child(stack)
	var p = MetaCeremonies.build({"key": "world:capture", "kind": "world_unlock", "world_id": "world_01", "title": "WHISPERING PARK",
		"subtitle": "World 01", "art": "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"})
	stack.push(p)
	MetaCeremonies.start_motion(p)
	await _shots(sub, p, out, "new_region", [4.2, 9.0])
	sub.free()
	sub = _sub()
	var save := "user://region_nah_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = save
	var root = MainScene.instantiate()
	sub.add_child(root)
	for _i in range(6):
		await process_frame
	while root.get_modal_stack().top() != null:
		root.get_modal_stack().top().close("capture")
		await process_frame
		await process_frame
	p = root.get_acquisition().open_need_a_hand({"show": true, "level": 3, "picks": [{"id": "tornado"}, {"id": "random"}]})
	await _shots(sub, p, out, "need_a_hand", [5.3, 9.0])
	sub.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save + suffix))
	quit(0)

func _sub() -> SubViewport:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 1920)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.125, 0.145, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)
	return sub

func _shots(sub: SubViewport, p, out: String, tag: String, times: Array) -> void:
	var t0 := Time.get_ticks_msec()
	for at in times:
		while (Time.get_ticks_msec() - t0) / 1000.0 < at:
			await process_frame
		await RenderingServer.frame_post_draw
		var playing: bool = p.find_child("HeroVideo", true, false) != null
		var path := "%s/%s_%s_1080x1920.png" % [out, tag, "video" if playing else "held"]
		print("t=", at, " video=", playing, " ", path, " err=", sub.get_texture().get_image().save_png(path))
