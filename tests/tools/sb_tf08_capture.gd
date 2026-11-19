extends SceneTree
## SB-TF-08 owner captures: Achievements (claimable on top) and the Collection album with READ ALL,
## EN and TR, on the real app root (main.tscn) with a temp save (never the canonical one).
## Fixture: one card -> first_discovery claimed; Gift + Daily task ledger -> gift_hunter / first_order
## claimable; 3 owned unseen cards in sets 1-2. Needs a rendering driver (no --headless):
##   godot --path . -s res://tests/tools/sb_tf08_capture.gd -- <out_dir> [WxH]

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://sb_tf08_captures"
	var size := Vector2i(1080, 2160)
	if args.size() > 1:
		size = Vector2i(int(args[1].split("x")[0]), int(args[1].split("x")[1]))
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	preload("res://scripts/app/app_state.gd").test_unlock_all = true
	MainScript.boot_clock_override = func(): return 1790000000
	MainScript.boot_opening_override = 0   # no opening cinematic over the capture
	MainScript.boot_local_day_override = func(): return 20000
	var saves: Array = []
	for loc in ["en", "tr"]:
		UiText.locale = loc
		var save := "user://sb_tf08_capture_%s_%d.save" % [loc, Time.get_ticks_usec()]
		saves.append(save)
		MainScript.boot_save_path_override = save
		var sub := SubViewport.new()
		sub.size = size
		sub.disable_3d = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(sub)
		var root = MainScene.instantiate()
		sub.add_child(root)
		await _frames(6)
		root.get_modal_stack().clear("capture")
		var app = root.get_app_state()
		var e = app.economy
		e.collection.add_card("s1_c0")
		app.actions.claim_achievement(app, "first_discovery")
		e.reward.grant("gift_ms:capture", {"scrub_bucks": 1})
		e.reward.grant("daily_task:capture", {"scrub_bucks": 1})
		e.meta_ui.mark_seen("card:s1_c0")
		for c in ["s1_c1", "s1_c2", "s2_c0"]:
			e.collection.add_card(c)
		root.get_home().get_region("SafeAreaRoot").set_synthetic_insets(0, 0, 0, 0)
		await _frames(4)
		var p = ProfileScreens.open_achievements(root.get_modal_stack(), app)
		await _frames(12)
		_save(sub, "%s/achievements_%s.png" % [out_dir, loc])
		p.close()
		await _frames(4)
		p = CollectionScreen.open_album(root.get_modal_stack(), app)
		await _frames(12)
		_save(sub, "%s/collection_read_all_%s.png" % [out_dir, loc])
		p._on_action("read_all")
		await _frames(12)
		_save(sub, "%s/collection_after_read_all_%s.png" % [out_dir, loc])
		root.free()
		sub.free()
		await _frames(2)
	for save in saves:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(save + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(save + suffix))
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	UiText.locale = "en"
	quit(0)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _save(sub: SubViewport, path: String) -> void:
	var img := sub.get_texture().get_image()
	print("CAPTURE ", path, " err=", img.save_png(path), " size=", img.get_size())
