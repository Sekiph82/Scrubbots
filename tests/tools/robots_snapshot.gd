extends SceneTree
## M43-C008 runtime evidence: the real Robots destination in the real app root (opening skipped).
## States: fresh roster (Scrubby active, Moppy next), unlockable with overflow, scrolled roster
## with every robot unlocked, locked detail, Home profile with another active robot.
## Needs a rendering driver:
##   godot --path . -s res://tests/tools/robots_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://robots_snapshots"
	for sz in SIZES:
		await _run(sz, sz == SIZES[1])
	print("ROBOTS_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, all_states: bool) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var path := "user://robots_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	var app = root.get_app_state()
	var st = root.get_modal_stack()
	app.economy.wallet.credit("bot_parts", 120)
	RobotsScreen.open(st, app, root.ceremonies)
	await _draw(6)
	_shot(sub, root, "1_robots_fresh", size)
	if all_states:
		app.economy.wallet.credit("bot_parts", 180)
		RobotsScreen.refresh(st.top(), app.economy)
		await _draw(4)
		_shot(sub, root, "2_robots_unlockable_overflow", size)
		st.top()._on_action("robot:bubbles")
		await _draw(6)
		_shot(sub, root, "3_robot_locked_detail", size)
		st.top().close("evidence")
		await _draw(2)
		st.top().close("evidence")
		await _draw(2)
		app.economy.wallet.credit("bot_parts", 250 * 8)
		for _i in range(9):
			app.actions.unlock_next_robot()
		for id in RobotRoster.ids():
			app.economy.meta_ui.mark_seen("robot:" + id)
		app.actions.equip_robot("moppy")
		await _frames(2)
		while st.top() != null:
			st.top().close("evidence")
			await _frames(1)
		root.get_home().refresh()
		await _draw(4)
		_shot_home(sub, "4_home_active_moppy", size)
		RobotsScreen.open(st, app, root.ceremonies)
		await _draw(4)
		(st.top().find_child("RobotList", true, false) as ScrollContainer).scroll_vertical = 100000
		await _draw(4)
		_shot(sub, root, "5_robots_all_unlocked_scrolled", size)
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

func _shot(sub: SubViewport, root, key: String, size: Vector2i) -> void:
	var top = root.get_modal_stack().top()
	var p := "%s/%s_%dx%d.png" % [_out, key, size.x, size.y]
	if top == null or not Rect2(Vector2.ZERO, Vector2(size)).grow(1.0).encloses(top.get_frame_rect()) or not top.text_fits():
		_bad += 1
		print("REJECTED ", p)
	print("SNAPSHOT ", p, " err=", sub.get_texture().get_image().save_png(p))

func _shot_home(sub: SubViewport, key: String, size: Vector2i) -> void:
	var p := "%s/%s_%dx%d.png" % [_out, key, size.x, size.y]
	print("SNAPSHOT ", p, " err=", sub.get_texture().get_image().save_png(p))

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
