extends SceneTree
## M43-C010 / C012 runtime evidence: Profile, Achievements, Events (empty + configured test
## event), Notifications preferences, Welcome Back, Home badges in the real app root
## (opening skipped). Needs a rendering driver:
##   godot --path . -s res://tests/tools/meta_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://meta_snapshots"
	for sz in SIZES:
		await _run(sz, sz == SIZES[1])
	print("META_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, all_states: bool) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var path := "user://meta_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	var app = root.get_app_state()
	var st = root.get_modal_stack()
	st.clear("evidence")
	for n in range(1, 4):
		app.progression.record_win(n)
	ProfileScreens.open_profile(st, app)
	await _draw(6)
	_shot(sub, root, "1_profile", size)
	if all_states:
		st.top()._on_action("achievements")
		await _draw(6)
		_shot(sub, root, "2_achievements", size)
		st.clear("evidence")
		ProfileScreens.open_events(st, app)
		await _draw(6)
		_shot(sub, root, "3_events_empty", size)
		st.clear("evidence")
		var cfg := {"schema": "scrubbots.events.v1", "approved_reward_types": ["scrub_bucks", "bot_parts", "standard_card_packs"],
			"weekly_events": [{"id": "evidence_wk", "start_ts": int(Time.get_unix_time_from_system()) - 7200, "unclaimed_on_expiry": "forfeit",
				"milestones": [{"target": 2, "reward": {"scrub_bucks": 50}}, {"target": 5, "reward": {"bot_parts": 1}}]}],
			"first_try_cleanup": {"id": "evidence_ft", "levels": 5, "reward": {"standard_card_packs": 1}}}
		var cp := "user://meta_ev_events.json"
		var f := FileAccess.open(cp, FileAccess.WRITE)
		f.store_string(JSON.stringify(cfg))
		f.close()
		app.economy.events.load_config(cp)
		app.economy.events.on_progression_terminal(true, true)
		app.economy.events.on_progression_terminal(true, true)
		ProfileScreens.open_events(st, app)
		await _draw(6)
		_shot(sub, root, "4_events_test_config", size)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(cp))
		st.clear("evidence")
		ProfileScreens.open_notifications(st, app)
		await _draw(6)
		_shot(sub, root, "5_notifications", size)
		st.clear("evidence")
		ProfileScreens.open_comeback(st, app)
		await _draw(6)
		_shot(sub, root, "6_welcome_back", size)
		st.clear("evidence")
		app.economy.daily.mark_task_done(0)
		app.economy.wallet.credit("bot_parts", 250)
		root.get_home().refresh()
		await _draw(4)
		var p := "%s/7_home_badges_%dx%d.png" % [_out, size.x, size.y]
		print("SNAPSHOT ", p, " err=", sub.get_texture().get_image().save_png(p))
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

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
