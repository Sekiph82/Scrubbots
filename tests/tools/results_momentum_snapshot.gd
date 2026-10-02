extends SceneTree
## M43-C001R-C001 Results momentum / Cleaning Journey evidence snapshots. Real app root
## (main.tscn), real catalog levels, real terminal WON (economy commits in the host before
## Results), real Home. Progression is set canonically (levels 1..N-1 completed) on a temp
## save. Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/results_momentum_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")

const PHONE := Vector2i(1080, 2160)
const SHORT := Vector2i(1080, 1920)
const TABLET := Vector2i(1536, 2048)
## [stem, size, where ("results"|"home"), level (won level / home frontier), scenario]
const SHOTS := [
	["results_L2_won_journey_next_cleanup", PHONE, "results", 2, ""],
	["results_L4_next_L5_mini_boss", PHONE, "results", 4, ""],
	["results_L5_mini_boss_complete", PHONE, "results", 5, ""],
	["results_L9_next_L10_boss", PHONE, "results", 9, ""],
	["results_L10_cycle_complete_L11_coming_soon", PHONE, "results", 10, ""],
	["results_L4_short_phone", SHORT, "results", 4, ""],
	["results_L4_phone_1170", Vector2i(1170, 2532), "results", 4, ""],
	["results_L4_phone_1290", Vector2i(1290, 2796), "results", 4, ""],
	["results_L4_tablet", TABLET, "results", 4, ""],
	["results_L10_short_phone", SHORT, "results", 10, ""],
	["results_L2_reduced_effects", PHONE, "results", 2, "reduced"],
	["results_L2_ceremony_barrier_held", PHONE, "results", 2, "barrier"],
	["results_L2_ceremony_barrier_released", PHONE, "results", 2, "barrier_released"],
	["home_frontier_6_mid_cycle", PHONE, "home", 6, ""],
	["home_frontier_1_new_player", PHONE, "home", 1, ""],
	["home_frontier_10_boss_current", PHONE, "home", 10, ""],
	["home_frontier_11_new_cycle", PHONE, "home", 11, ""],
	["home_frontier_6_short_phone", SHORT, "home", 6, ""],
	["home_frontier_6_phone_1170", Vector2i(1170, 2532), "home", 6, ""],
	["home_frontier_6_phone_1290", Vector2i(1290, 2796), "home", 6, ""],
	["home_frontier_6_tablet", TABLET, "home", 6, ""],
	["home_frontier_6_reduced_effects", PHONE, "home", 6, "reduced"],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://results_momentum_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var level: int = shot[3]
	var sc: String = shot[4]
	var save_path := "user://momentum_snapshot_%d.save" % Time.get_ticks_usec()
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = save_path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await process_frame
	var app = root.get_app_state()
	if sc == "reduced":
		app.set_reduced_effects(true)
	app.progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": level, "completed": range(1, level)})
	app.economy.hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})
	var ok := true
	if shot[2] == "results":
		root.play_current_frontier()
		await process_frame
		var h = root.get_gameplay_host()
		h.get_runtime().set_process(false)
		h.get_completion().terminal_reached.emit(&"WON", {})
		await process_frame
		var res = root.get_results_screen()
		if sc.begins_with("barrier"):
			res.set_ceremony_barrier("c005_candidate", true)
			if sc == "barrier_released":
				for _i in range(4):
					await process_frame
				res.set_ceremony_barrier("c005_candidate", false)
		for _i in range(90):   # let the presentation reveal finish naturally (~1.5 s)
			await process_frame
		res.finish_reveal()
		var vp := Rect2(Vector2.ZERO, Vector2(size))
		ok = res.visible and vp.encloses(res.get_panel().get_global_rect()) and vp.encloses(res.get_robot().get_global_rect())
	else:
		root.get_home().refresh()
		for _i in range(12):
			await process_frame
		var strip = root.get_home().get_journey_strip()
		ok = strip != null and strip.visible and Rect2(Vector2.ZERO, Vector2(size)).encloses(strip.get_global_rect())
	for _i in range(6):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	if not ok:
		_bad += 1
		print("REJECTED ", path)
	else:
		var img := sub.get_texture().get_image()
		var res2 = root.get_results_screen()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " frontier=", app.progression.current_level(),
			" teaser=", res2.get_teaser_image().texture.region if res2.visible and res2.get_teaser_image().texture != null else "-")
	root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
