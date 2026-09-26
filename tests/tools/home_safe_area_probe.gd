extends SceneTree
## M42 V07 runtime safe-area probe (windowed; NOT headless). Renders the real Home in the
## ROOT window (project stretch settings apply; no synthetic insets), logs the raw
## DisplayServer probe, what the pre-V07 conversion would have produced, the applied V07
## margins and the Home ad/nav rects, and saves a screenshot.
##   godot --path . --resolution 683x1366 -s res://tests/tools/home_safe_area_probe.gd -- <out_dir> [simulate_pre_v07]
## `simulate_pre_v07` additionally applies the measured pre-V07 margins as synthetic insets
## and saves `home_windows_pre_v07_simulated.png` (before/after evidence).

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const SafeAreaRootScript = preload("res://scripts/ui/safe_area_root.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://home_safe_area_probe"
	DirAccess.make_dir_recursive_absolute(out_dir)
	await process_frame
	var save_path := "user://home_safe_area_probe_%d.save" % Time.get_ticks_usec()
	var home = HomeScreenScene.instantiate()
	get_root().add_child(home)
	home.bind(AppState.new(save_path))
	for _i in range(20):
		await process_frame
	var vp: Vector2 = home.get_viewport_rect().size
	var probe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	var old_margins: Array = SafeAreaRootScript.margins_from_probe(probe, screen, vp)
	var lines: Array = [
		"os=%s" % OS.get_name(),
		"window_size=%s" % str(DisplayServer.window_get_size()),
		"screen_size=%s" % str(screen),
		"display_safe_area_probe=%s" % str(probe),
		"logical_viewport=%s" % str(vp),
		"uses_runtime_display_safe_area=%s" % str(SafeAreaRootScript.uses_runtime_display_safe_area(OS.get_name())),
		"pre_v07_margins_ltrb=%s" % str(old_margins),
		"v07_applied_margins_ltrb=%s" % str(home.get_region("SafeAreaRoot").get_applied_margins()),
		"ad_banner_slot=%s" % str(home.get_region("AdBannerSlot").get_global_rect()),
		"bottom_nav=%s" % str(home.get_region("BottomNav").get_global_rect()),
		"play=%s" % str(home.get_region("PlayButton").get_global_rect()),
		"world_transform=%s" % str(home.get_world_transform()),
	]
	for l in lines:
		print("PROBE ", l)
	var f := FileAccess.open(out_dir + "/runtime_probe.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	var img := get_root().get_texture().get_image()
	img.save_png(out_dir + "/home_windows_runtime.png")
	print("PROBE screenshot=", img.get_size())
	if args.has("simulate_pre_v07"):
		home.get_region("SafeAreaRoot").set_synthetic_insets(old_margins[0], old_margins[1], old_margins[2], old_margins[3])
		for _i in range(10):
			await process_frame
		get_root().get_texture().get_image().save_png(out_dir + "/home_windows_pre_v07_simulated.png")
		print("PROBE pre_v07_simulated ad_banner_slot=", home.get_region("AdBannerSlot").get_global_rect())
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit(0)
