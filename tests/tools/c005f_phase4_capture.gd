extends SceneTree
## M43-C005F-PHASE4 runtime evidence (NOT shipping): the REAL app (main.tscn) with the real
## plugins, at 1080x2160 and 1536x2048, FULL and REDUCED, through shipping paths only:
##   Home (cold boot baseline) -> PLAY -> Level 1 driven to its REAL WON terminal (supply-plan
##   clicks + runtime ticks; CompletionController latches it) -> Results (F010 bridge) -> Results
##   HOME -> Home (F012 frontier + streak micro) -> 10 refreshes (no replay); and a LOST terminal
##   through the real completion signal -> Fail Results. Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/c005f_phase4_capture.gd
## Output: coordination/sessions/M43-C005F-PHASE4/evidence/*.jpg (+ .gdignore) and feel logs.

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE4/evidence"
const SIZES := [Vector2i(1080, 2160), Vector2i(1536, 2048)]

var _sub: SubViewport
var _root = null
var _tmp: Array = []
var _tag := ""

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var gi := FileAccess.open(OUT + "/.gdignore", FileAccess.WRITE)
	gi.close()
	MainScript.boot_opening_override = 0   # Home directly (the opening cinematic is not under test)
	_run.call_deferred()

func _run() -> void:
	await _boot(SIZES[0], false)   # warm-up (one-time startup work of the first app boot)
	for size in SIZES:
		for reduced in [false, true]:
			_tag = "%dx%d_%s" % [size.x, size.y, "reduced" if reduced else "full"]
			await _won_flow(size, reduced)
			await _lost_flow(size, reduced)
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	quit(0)

func _won_flow(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	await create_timer(0.6).timeout
	await _shot("03_home_before_progression")
	_root.play_current_frontier()
	await _frames(6)
	await _drive_real_won()
	await _frames(2)   # F010 SMALL spark in flight (FULL; ~0.1 s into its <= 0.32 s fading life), Results shown
	await _shot("01_won_terminal_results")
	print("%s 01 WON: bridge=%s" % [_tag, str(_keys("c005f010:"))])
	await create_timer(1.2).timeout
	_root.get_results_screen().get_home_button().pressed.emit()
	await create_timer(0.15).timeout   # F012 frontier bump mid-flight (FULL)
	await _shot("04_home_after_frontier_change")
	await create_timer(0.3).timeout    # serialized second delta (Win Streak) mid-flight
	await _shot("04b_home_after_streak_marker")
	await create_timer(0.8).timeout
	for _i in range(10):
		_root.get_home().refresh()
	await create_timer(0.4).timeout
	await _shot("05_home_same_state_after_10_refreshes")
	print("%s 04/05 Home micro log=%s" % [_tag, str(_root.get_home().get_micro_feel().feel_log())])

func _lost_flow(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	for col in range(host.get_supply().get_column_count()):
		if host.get_input_controller().activate_front(col).get("ok", false):
			break
	await create_timer(0.4).timeout
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await create_timer(0.3).timeout
	await _shot("02_lost_terminal_results")
	print("%s 02 LOST: bridge=%s status=%s" % [_tag, str(_keys("c005f010:")), String(_root.get_navigation().last_payload().get("status", ""))])

func _drive_real_won() -> void:
	var host = _root.get_gameplay_host()
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	var rt = host.get_runtime()
	rt.set_process(false)
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var i := 0
	var frames := 0
	while frames < 200000 and not host.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(host.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(1.0)
		frames += 1
		if frames % 40 == 0:
			await process_frame   # keep real frame deltas short, so the terminal's feel plays in real time

func _keys(prefix: String) -> Array:
	return _root.feel.dispatch_log().filter(func(r): return String(r[1]).begins_with(prefix)).map(func(r): return [r[0], r[1]])

func _boot(size: Vector2i, reduced: bool) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var p := "user://c005f_p4_capture_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(8)
	_root.get_app_state().set_reduced_effects(reduced)
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_sub.get_texture().get_image().save_jpg(ProjectSettings.globalize_path("%s/%s_%s.jpg" % [OUT, _tag, name]), 0.88)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
