extends SceneTree
## Deterministic Gameplay V02 snapshot harness (M28-C002-C001 owner visual review evidence).
## Renders the REAL app root (scenes/app/main.tscn) inside a SubViewport on an isolated
## temp save, launches the real frontier level through the production path and drives it
## with the existing owner-approved supply-plan click sequence (`intendedColumnClicks`,
## same driver as tests/m55_long_session.gd) — no solver, no new solution.
## Economy setup for the +1 Slot / timed-2x shots goes through canonical services on the
## temp save only (a granted charge / credited SB), then the real host controls are used.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

## [stem, size, frontier, scenario]
const SHOTS := [
	["v02_L2_fresh", Vector2i(1080, 2160), 2, "fresh"],
	["v02_L2_active_cleaning", Vector2i(1080, 2160), 2, "cleaning"],
	["v02_L2_five_slots_occupied", Vector2i(1080, 2160), 2, "five_slots"],
	["v02_L2_sixth_slot", Vector2i(1080, 2160), 2, "sixth_slot"],
	["v02_L2_timed_2x_countdown", Vector2i(1080, 2160), 2, "timed_2x"],
	["v02_L3_tall_phone", Vector2i(1290, 2796), 3, "cleaning"],
	["v02_L3_short_phone", Vector2i(1080, 1920), 3, "cleaning"],
	["v02_L1_fresh_tablet", Vector2i(1536, 2048), 1, "fresh"],
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
	app.progression.debug_set_current_level(shot[2])
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	var scen: String = shot[3]
	var note := ""
	match scen:
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
			for _i in range(3):
				await process_frame
			note = _drive_until_agents(h, 2)
			# Real wall-clock time passes (the entitlement is absolute wall clock): the
			# captured label must be below the purchased 15:00.
			OS.delay_msec(2100)
	for _i in range(10):
		await process_frame
	h._refresh_hud()
	await process_frame
	var screen = h.get_screen()
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	if root.get_navigation().route_name() != "GAMEPLAY" or h.get_completion().is_terminal():
		_bad += 1
		print("REJECTED ", path, " route=", root.get_navigation().route_name())
	else:
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " level=", h.progression_level,
			" slots=", screen.get_five_slot_strip().get_slot_count(), " connectors=", screen.get_connector_segments().size(),
			" speed=", screen.get_speed_mode(), "/", screen.get_speed_label(), " ", note)
	root.free()
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

## Owner-plan activations only (no ticks) until `n` slots are occupied.
func _fill_slots(h, n: int) -> String:
	var clicks := _clicks(h)
	var input = h.get_input_controller()
	var i := 0
	var occupied := 0
	while i < clicks.size() and occupied < n:
		if h.get_slots().rightmost_empty_index() == -1:
			break
		if input.activate_front(int(clicks[i]) - 1).get("ok", false):
			i += 1
		else:
			break
		occupied = h.get_slots().snapshot().filter(func(s): return bool(s.get("occupied", false))).size()
	return "owner_clicks=%d occupied=%d" % [i, occupied]

## Owner-plan play with small real ticks until at least `want` Scrubbots are travelling.
func _drive_until_agents(h, want: int) -> String:
	var clicks := _clicks(h)
	var input = h.get_input_controller()
	var rt = h.get_runtime()
	var i := 0
	for frame in range(4000):
		if h.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
			if input.activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
		rt.tick(0.05)
		if frame > 40 and _moving(h) >= want:
			break
	return "owner_clicks=%d moving=%d" % [i, _moving(h)]

func _moving(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n
