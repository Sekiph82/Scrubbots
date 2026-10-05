extends SceneTree
## M43 master (SB-M43-013) runtime evidence: the REAL app root reaches a real WON terminal whose
## committed streak SB crosses Gift Meter 10 (seeded at 9 through GiftMeterService); Results
## holds CLEAN NEXT + teaser behind the ceremony barrier, the Gift ceremony opens after the
## reward reveal, and CONTINUE releases the barrier. Needs a rendering driver:
##   godot --path . -s res://tests/tools/results_ceremony_snapshot.gd -- <out_dir>

const AppState = preload("res://scripts/app/app_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

const SIZES := [Vector2i(1080, 2160), Vector2i(1080, 1920)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://results_ceremony_snapshots"
	for sz in SIZES:
		await _run(sz)
	print("RESULTS_CEREMONY_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i) -> void:
	var path := "user://results_ceremony_ev_%d.save" % Time.get_ticks_usec()
	var seed = AppState.new(path)
	seed.economy.gift.add_streak_sb("evidence_seed", 9)
	seed.request_save()
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(4)
	root.play_current_frontier()
	await _frames(4)
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	var res = root.get_results_screen()
	await _frames(3)
	_shot(sub, "1_results_held_by_barrier", size, res.has_ceremony_barrier() and not res.get_next_cleanup_panel().visible)
	res.finish_reveal()
	var top = null
	for _i in range(30):
		await RenderingServer.frame_post_draw
		top = root.get_modal_stack().top()
		if top != null:
			break
	for _i in range(6):
		await RenderingServer.frame_post_draw
	_shot(sub, "2_gift_ceremony_over_results", size, top != null and String(top.context.get("ceremony_key", "")) == "gift:gift_ms:c0:m10")
	if top != null:
		top._on_action("continue")
	for _i in range(8):
		await RenderingServer.frame_post_draw
	_shot(sub, "3_barrier_released_clean_next", size, not res.has_ceremony_barrier() and res.get_next_cleanup_panel().visible)
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

func _shot(sub: SubViewport, key: String, size: Vector2i, ok: bool) -> void:
	var p := "%s/%s_%dx%d.png" % [_out, key, size.x, size.y]
	if not ok:
		_bad += 1
		print("REJECTED state check failed for ", p)
	print("SNAPSHOT ", p, " err=", sub.get_texture().get_image().save_png(p))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
