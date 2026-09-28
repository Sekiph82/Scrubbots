extends SceneTree
## Deterministic Results snapshot harness (M43-C001B owner visual review evidence).
## Renders the REAL app root (scenes/app/main.tscn) inside a SubViewport on an isolated
## temp save, plays the real frontier level to a real terminal (the host commits the
## economy exactly as in production) and captures the Results screen over the board.
## WON levels are driven with the existing owner-approved supply-plan click sequence
## (`intendedColumnClicks`), exactly as tests/m55_long_session.gd does — no solver.
## A shot whose terminal status differs from the one requested is NOT saved; the run
## exits 1 so a wrong-state image can never become evidence.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/results_snapshot.gd -- <out_dir>
## Output goes to <out_dir> only (never to approved art paths).

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

## [file stem, size, frontier level, streak levels pre-seeded, reduced effects, terminal]
const SHOTS := [
	["won_L3_typical", Vector2i(1080, 1920), 3, [1, 2], false, "WON"],
	["won_L3_typical", Vector2i(1080, 2160), 3, [1, 2], false, "WON"],
	["won_L3_typical", Vector2i(1080, 2400), 3, [1, 2], false, "WON"],
	["won_L10_no_next_content", Vector2i(1080, 1920), 10, [1, 2, 3, 4], false, "WON"],
	["won_L3_reduced_effects_static", Vector2i(1080, 2160), 3, [1, 2], true, "WON"],
	["lost_L1_technical_fallback", Vector2i(1080, 2160), 1, [], false, "LOST"],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://results_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var save_path := "user://results_snapshot_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = save_path
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var root = MainScene.instantiate()
	sub.add_child(root)
	await process_frame
	var app = root.get_app_state()
	# Representative, deterministic state on the temp save only.
	for n in shot[3]:
		app.economy.streak.process_first_clear_win(n)
	app.progression.debug_set_current_level(shot[2])
	app.set_reduced_effects(shot[4])
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	var clicks := 0
	if shot[5] == "WON":
		clicks = _drive(h)
	else:
		h.get_completion().terminal_reached.emit(&"LOST", {})
	var res = root.get_results_screen()
	if not shot[4]:
		res.finish_reveal()   # capture the final state of the ordered reveal
	for _i in range(8):
		await process_frame
	var status := String(res.get_payload().get("status", ""))
	var won_ok: bool = shot[5] != "WON" or (h.get_completion().is_won() and h.get_board().count_cells_by_state(0) == 0)
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	if status != shot[5] or not won_ok or root.get_navigation().route_name() != "RESULTS":
		_bad += 1
		print("REJECTED ", path, " wanted=", shot[5], " got=", status, " board_active=", h.get_board().count_cells_by_state(0))
	else:
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " status=", status, " level=", h.progression_level,
			" owner_clicks=", clicks, " victory=", res.is_victory_layout(), " next=", res.get_model().get("continue", {}),
			" rows=", res.shown_row_texts())
	root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))

## Same driver as tests/m55_long_session.gd `_drive`: owner intendedColumnClicks where the
## level has an owner supply plan, otherwise (Level 1, M23 generator) greedy fronts.
## Returns the number of owner clicks applied.
func _drive(h) -> int:
	var clicks: Array = []
	if not String(h.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	var rt = h.get_runtime()
	var input = h.get_input_controller()
	var slots = h.get_slots()
	var i := 0
	var frames := 0
	while frames < 200000 and not h.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(h.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(1.0)
		frames += 1
	return i
