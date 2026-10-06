extends SceneTree
## SB-M43-R15-004 owner evidence from the real app root (opening skipped): live Home with all five
## entries (SHOP / COLLECTION / TASKS / DAILY + the auxiliary REWARDED ADS card with the
## owner-approved HOME-122 icon) and the REWARDED ADS popup opened by tapping that card.
## Rendered at the stretch-expand logical canvas, saved at the physical owner size.
##   godot --path . --rendering-driver opengl3 -s res://tests/tools/r15_004_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const R15Snapshot = preload("res://tests/tools/r15_snapshot.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://r15_004_snapshots"
	DirAccess.make_dir_recursive_absolute(out)
	var n := 0
	for phys in [Vector2i(683, 1366), Vector2i(1080, 2160)]:
		var sub := SubViewport.new()
		sub.size = R15Snapshot.logical(phys)
		sub.disable_3d = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(sub)
		MainScript.boot_save_path_override = "user://r15_004_ev_%d.save" % Time.get_ticks_usec()
		MainScript.boot_opening_override = 0
		var root = MainScene.instantiate()
		sub.add_child(root)
		for _i in range(8):
			await process_frame
		root.get_modal_stack().clear("evidence")
		for _i in range(4):
			await process_frame
		await _shot(sub, phys, "%s/1_home_rewarded_ads_icon_%dx%d.png" % [out, phys.x, phys.y])
		root.get_home().get_region("RewardedAdsButton").pressed.emit()
		for _i in range(4):
			await process_frame
		await _shot(sub, phys, "%s/2_rewarded_ads_popup_from_icon_%dx%d.png" % [out, phys.x, phys.y])
		n += 2
		root.free()
		sub.free()
	print("R15_004_EVIDENCE %d frames -> %s" % [n, out])
	quit()

func _shot(sub: SubViewport, phys: Vector2i, path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := sub.get_texture().get_image()
	if img.get_size() != phys:
		img.resize(phys.x, phys.y, Image.INTERPOLATE_LANCZOS)
	img.save_png(path)
