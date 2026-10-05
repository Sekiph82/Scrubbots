extends SceneTree
## M43-C005R runtime evidence: the real Home with the Gift Meter fed through the real
## GiftMeterService to several values; full screen + a 2x crop of the Gift Meter assembly.
## Needs a rendering driver:  godot --path . -s res://tests/tools/gift_micro_progress_snapshot.gd -- <out_dir>

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")

const VALUES := [7, 61, 330, 780]
const SIZES := [Vector2i(1080, 2160), Vector2i(1536, 2048)]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://gift_micro"
	for sz in SIZES:
		for v in VALUES:
			var path := "user://gift_micro_ev_%d.save" % Time.get_ticks_usec()
			var app = AppState.new(path)
			app.economy.gift.add_streak_sb("ev", v)
			var sub := SubViewport.new()
			sub.size = sz
			sub.disable_3d = true
			sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			get_root().add_child(sub)
			var home = HomeScreenScene.instantiate()
			sub.add_child(home)
			home.bind(app)
			for _i in range(6):
				await RenderingServer.frame_post_draw
			home.refresh()
			for _i in range(4):
				await RenderingServer.frame_post_draw
			var img := sub.get_texture().get_image()
			var p := "%s/home_gift_%d_%dx%d.png" % [out, v, sz.x, sz.y]
			print("SNAPSHOT ", p, " err=", img.save_png(p), " model=", home.get_region("GiftTickOverlay").get_model())
			var r: Rect2 = home.get_region("GiftMeter").get_global_rect()
			var crop := img.get_region(Rect2i(r))
			crop.resize(int(r.size.x), int(r.size.y))
			print("SNAPSHOT ", "%s/gift_meter_crop_%d_%dx%d.png" % [out, v, sz.x, sz.y], " err=", crop.save_png("%s/gift_meter_crop_%d_%dx%d.png" % [out, v, sz.x, sz.y]))
			sub.free()
			for suffix in ["", ".bak", ".tmp"]:
				if FileAccess.file_exists(path + suffix):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	quit(0)
