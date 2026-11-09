extends SceneTree
## SB-M50-018 flash capture: renders the native gameplay effects with the highest flash
## potential (BoosterVfx tornado / plus_one_slot / random / selector and five simultaneous
## batch pops) frame by frame at 60 fps on the REAL gameplay screen (L1, 1080x2400, throw-away
## save, FULL effects) and writes one PNG folder per effect for tools/flash_audit.py.
## Needs a rendering driver (run WITHOUT --headless). Local only.
##
## Run: godot --path . -s res://tools/flash_capture.gd -- --out <abs dir>
##      python tools/flash_audit.py --fps 60 <abs dir>/*

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")

const FPS := 60.0
const SIZE := Vector2i(1080, 2400)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	if DisplayServer.get_name() == "headless" or i < 0 or i + 1 >= args.size():
		print("flash capture: NOT_RUN (needs a rendering driver and --out <dir>)")
		quit(1)
		return
	var out := args[i + 1]
	AppStateScript.test_unlock_all = true
	MainScript.boot_opening_override = 0
	var save := "user://m50_flash_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = save
	var sub := SubViewport.new()
	sub.size = SIZE
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(8)
	root.get_app_state().set_reduced_effects(false)
	root.play_current_frontier()
	await _frames(30)
	var host = root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var s = host.get_screen()
	var vfx = s._booster_vfx
	var tiles: Array = s._supply_tiles(func(_b): return true)
	var slots: Array = s.get_five_slot_strip().get_slot_views()
	var cid := 0
	var tornado: Dictionary = s.capture_booster_fx("tornado", cid)
	var runs := {
		"tornado": func(): vfx.play("tornado", tornado),
		"plus_one_slot": func(): vfx.play("plus_one_slot", {"slot_rect": slots[slots.size() - 1].get_global_rect()}),
		"random": func(): vfx.play("random", {"tiles": tiles, "colors": tiles.map(func(t): return t["color"])}),
		"selector": func(): vfx.play("selector", {"src_rect": tiles[0]["rect"], "dst_rect": slots[0].get_global_rect(), "color": tiles[0]["color"]}),
		"batch_pops_x5": func():
			for v in slots:
				vfx.pop_batch(v.get_global_rect(), tiles[0]["color"]),
	}
	for k in runs:
		var dir: String = out.path_join(k)
		DirAccess.make_dir_recursive_absolute(dir)
		vfx.set_process(false)
		(runs[k] as Callable).call()
		var n := int(ceil(maxf(vfx.pop_duration(), 0.9) * FPS)) + 6
		for f in range(n):
			vfx._process(1.0 / FPS)
			vfx.set_process(false)   # only the manual 1/60 step advances it
			await RenderingServer.frame_post_draw
			sub.get_texture().get_image().save_png(dir.path_join("%04d.png" % f))
		vfx.stop()
		vfx.clear_pops()
		print("    %s: %d frames -> %s" % [k, n, dir])
	root.free()
	sub.free()
	AppStateScript.test_unlock_all = false
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for sfx in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save + sfx):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save + sfx))
	print("flash capture: DONE")
	quit(0)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
