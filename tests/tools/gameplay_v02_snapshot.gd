extends SceneTree
## Deterministic Gameplay V02 static-master-shell snapshot harness (M28-C002-C002 evidence).
##
## Two production paths:
##   "main"  — the REAL app root (scenes/app/main.tscn): frontier launch through the catalog,
##             driven with the owner-approved supply-plan clicks (`intendedColumnClicks`,
##             same driver as tests/m55_long_session.gd). All First 10 levels are 3-column.
##   "host"  — a real ProductionGameplayHost on a real AppState, Level 1 content, with the
##             M23 BatchSupplyGenerator `column_count` = 4 or 5: the only way to exercise the
##             4/5-column shells today (no First 10 level uses 4/5 columns). No level content
##             or supply plan is changed; no solver; greedy fronts only.
## Economy setup (+1 Slot charge / SB for timed 2x) goes through canonical services on the
## temp save only; the real host controls are then used.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

## [stem, size, path, level, columns(host path), scenario]
const SHOTS := [
	["c002_5slot_3col_L2_fresh", Vector2i(1080, 2160), "main", 2, 0, "fresh"],
	["c002_5slot_4col_L1gen_fresh", Vector2i(1080, 2160), "host", 1, 4, "fresh"],
	["c002_5slot_5col_L1gen_fresh", Vector2i(1080, 2160), "host", 1, 5, "fresh"],
	["c002_6slot_3col_L2_plus_one", Vector2i(1080, 2160), "main", 2, 0, "sixth_slot"],
	["c002_6slot_4col_L1gen_plus_one", Vector2i(1080, 2160), "host", 1, 4, "sixth_slot"],
	["c002_6slot_5col_L1gen_plus_one", Vector2i(1080, 2160), "host", 1, 5, "sixth_slot"],
	["c002_5slot_3col_L2_active_cleaning", Vector2i(1080, 2160), "main", 2, 0, "cleaning"],
	["c002_5slot_3col_L2_five_slots_occupied", Vector2i(1080, 2160), "main", 2, 0, "five_slots"],
	["c002_5slot_3col_L2_timed_2x", Vector2i(1080, 2160), "main", 2, 0, "timed_2x"],
	["c002_5slot_3col_L3_tall_phone", Vector2i(1290, 2796), "main", 3, 0, "cleaning"],
	["c002_5slot_3col_L3_short_phone", Vector2i(1080, 1920), "main", 3, 0, "cleaning"],
	["c002_5slot_3col_L1_tablet", Vector2i(1536, 2048), "main", 1, 0, "fresh"],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://gameplay_v02_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var save_path := "user://gameplay_v02_snapshot_%d.save" % Time.get_ticks_usec()
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var root = null
	var h = null
	var app = null
	if shot[2] == "main":
		MainScript.boot_save_path_override = save_path
		root = MainScene.instantiate()
		sub.add_child(root)
		await process_frame
		app = root.get_app_state()
		app.progression.debug_set_current_level(shot[3])
		root.play_current_frontier()
		await process_frame
		h = root.get_gameplay_host()
	else:
		app = AppState.new(save_path)
		app.progression.debug_set_current_level(shot[3])
		h = ProductionGameplayHost.new()
		h.app_state = app
		h.auto_build = false
		h.column_count = shot[4]
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		sub.add_child(h)
		h.build()
		await process_frame
	h.get_runtime().set_process(false)
	var note := ""
	match shot[5]:
		"cleaning":
			note = _drive_until_agents(h, 3)
		"five_slots":
			note = _fill_slots(h, 5)
		"sixth_slot":
			app.economy.boosters.add_charges("plus_one_slot", 1)
			var r: Dictionary = h.request_booster("plus_one_slot")
			note = "plus_one=%s " % str(r.get("ok")) + _fill_slots(h, 6)
		"timed_2x":
			app.economy.wallet.credit("scrub_bucks", 1000)
			h.get_screen().get_speed_button().pressed.emit()
			h.get_speed_acquisition_popup().get_offer_button("timed_900").pressed.emit()
			note = _drive_until_agents(h, 2)
			OS.delay_msec(2100)   # real wall clock passes: label must read below 15:00
	for _i in range(10):
		await process_frame
	h._refresh_hud()
	await process_frame
	var screen = h.get_screen()
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	var want: String = shot[0].split("_")[1] + "_" + shot[0].split("_")[2]
	if h.get_completion().is_terminal() or screen.get_shell_id() != want:
		_bad += 1
		print("REJECTED ", path, " shell=", screen.get_shell_id(), " want=", want)
	else:
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " shell=", screen.get_shell_id(), " level=", h.progression_level,
			" cols=", screen.get_supply_panel().get_column_count(), " slots=", screen.get_five_slot_strip().get_slot_count(),
			" speed=", screen.get_speed_mode(), "/", screen.get_speed_label(), " ", note)
	if root != null:
		root.free()
	else:
		h.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))

func _clicks(h) -> Array:
	if String(h.supply_plan_path).is_empty():
		return []
	return SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]

## One activation: next owner click, or (no plan) the first live front.
func _activate(h, clicks: Array, i: int) -> bool:
	var input = h.get_input_controller()
	if not clicks.is_empty():
		return i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false)
	for col in range(h.get_supply().get_column_count()):
		if input.activate_front(col).get("ok", false):
			return true
	return false

func _fill_slots(h, n: int) -> String:
	var clicks := _clicks(h)
	var i := 0
	var occupied := 0
	while occupied < n and h.get_slots().rightmost_empty_index() != -1:
		if not _activate(h, clicks, i):
			break
		i += 1
		occupied = h.get_slots().snapshot().filter(func(s): return bool(s.get("occupied", false))).size()
	return "activations=%d occupied=%d" % [i, occupied]

func _drive_until_agents(h, want: int) -> String:
	var clicks := _clicks(h)
	var rt = h.get_runtime()
	var i := 0
	for frame in range(4000):
		if h.get_slots().rightmost_empty_index() != -1 and _activate(h, clicks, i):
			i += 1
		rt.tick(0.05)
		if frame > 40 and _moving(h) >= want:
			break
	return "activations=%d moving=%d" % [i, _moving(h)]

func _moving(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n
