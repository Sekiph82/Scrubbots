extends SceneTree
## M28-C002-C003 final popup-inclusive Gameplay V02 evidence (SB-M28-C002-019).
## Real app root (main.tscn), real frontier launch (Level 2, owner supply plan), real
## ProductionGameplayHost / GameplayScreen and the ONE app ModalStack. Every popup is opened
## by a ROUTED pointer tap (SubViewport.push_input) on the visible Gameplay V02 control
## (booster row / 2x box / Pause box) and every popup choice (target chip, offer) likewise.
## Economy setup (SB balance, owned +1 Slot charge) only through canonical services on a
## temp save; nothing is composed externally.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/gameplay_v02_final_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const PHONE := Vector2i(1080, 2160)
## [file stem, size, scenario, expected top popup id ("" = none)]
const SHOTS := [
	["final_fresh_level", PHONE, "fresh", ""],
	["final_active_cleaning", PHONE, "cleaning", ""],
	["final_five_slots_occupied", PHONE, "five", ""],
	["final_sixth_slot_active", PHONE, "sixth", ""],
	["final_booster_acquire_open", PHONE, "booster:plus_one_slot", "booster_plus_one_slot"],
	["final_selector_or_tornado_picker_open", PHONE, "picker:selector", "booster_selector"],
	["final_tornado_picker_open", PHONE, "picker:tornado", "booster_tornado"],
	["final_pause_open", PHONE, "pause", "pause"],
	["final_2x_acquire_open", PHONE, "speed", "speed_acquire"],
	["final_timed_2x_active", PHONE, "timed", ""],
	["final_sixth_slot_booster_acquire_open", PHONE, "sixth_popup", "booster_tornado"],
	["final_short_phone_booster_acquire_open", Vector2i(1080, 1920), "picker:tornado", "booster_tornado"],
	["final_short_phone_2x_acquire_open", Vector2i(1080, 1920), "speed", "speed_acquire"],
	["final_tall_phone_cleaning", Vector2i(1290, 2796), "cleaning", ""],
	["final_tall_phone_pause_open", Vector2i(1290, 2796), "pause", "pause"],
	["final_tablet_2x_acquire_open", Vector2i(1536, 2048), "speed", "speed_acquire"],
	["final_tablet_booster_acquire_open", Vector2i(1536, 2048), "picker:selector", "booster_selector"],
	# Responsive matrix, popup-inclusive (one representative state per remaining size).
	["matrix_1170_booster_acquire_open", Vector2i(1170, 2532), "picker:tornado", "booster_tornado"],
	["matrix_1080x2400_sixth_slot_popup", Vector2i(1080, 2400), "sixth_popup", "booster_tornado"],
	["matrix_1440_2x_acquire_open", Vector2i(1440, 3200), "speed", "speed_acquire"],
	["matrix_1440_pause_open", Vector2i(1440, 3200), "pause", "pause"],
]

var _bad := 0
var _sub: SubViewport

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://gameplay_v02_final"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	_sub.push_input(e)

func _tap(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	_mouse(p, true)
	await process_frame
	_mouse(p, false)
	for _i in range(3):
		await process_frame

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var sc: String = shot[2]
	var save_path := "user://gameplay_v02_final_%d.save" % Time.get_ticks_usec()
	var now := [1_900_000_000]
	MainScript.boot_clock_override = func(): return now[0]
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.transparent_bg = false
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = save_path
	var root = MainScene.instantiate()
	_sub.add_child(root)
	await process_frame
	var app = root.get_app_state()
	var eco = app.economy
	app.progression.debug_set_current_level(2)
	root.play_current_frontier()
	for _i in range(3):
		await process_frame
	var h = root.get_gameplay_host()
	var s = h.get_screen()
	var stack = root.get_modal_stack()
	h.get_runtime().set_process(false)
	var w = eco.wallet
	if w.scrub_bucks() < 5000:
		w.credit("scrub_bucks", 5000 - w.scrub_bucks())
	h._refresh_hud()
	var note := ""
	match sc:
		"fresh":
			pass
		"cleaning":
			note = _drive_until_agents(h, 3)
		"five":
			note = _fill_slots(h, 5)
		"sixth", "sixth_popup":
			eco.boosters.add_charges("plus_one_slot", 1)
			h._refresh_hud()
			await _tap(s.get_booster_button("plus_one_slot"))   # owned charge: charge-first
			note = "plus_one=%s " % str(h.last_booster_request.get("ok")) + _fill_slots(h, 6)
			if sc == "sixth_popup":
				await _tap(s.get_booster_button("tornado"))
		"pause":
			note = _drive_until_agents(h, 2)
			await _tap(s.get_pause_button())
		"speed":
			note = _drive_until_agents(h, 2)
			await _tap(s.get_speed_button())
		"timed":
			await _tap(s.get_speed_button())
			await _tap(h.get_speed_acquisition_popup().get_offer_button("timed_900"))
			note = _drive_until_agents(h, 3)
			now[0] += 47   # wall clock passes: the box must read below 15:00
		_:
			if sc.begins_with("picker"):
				# Selector needs an empty slot to be legal: keep slots free, agents moving.
				note = _fill_slots(h, 2)
				for _i in range(20):
					h.get_runtime().tick(0.05)
			else:
				note = _drive_until_agents(h, 2)
			await _tap(s.get_booster_button(sc.split(":")[1]))
			if sc.begins_with("picker"):
				var f = stack.top().find_child("Targets", true, false)
				if f.get_child_count() == 0:
					_bad += 1
					print("REJECTED no picker targets ", shot[0])
				else:
					await _tap(f.get_child(mini(1, f.get_child_count() - 1)))
				note += " chips=%d target=%s" % [f.get_child_count(), str(stack.top().context.get("target"))]
	for _i in range(10):
		await process_frame
	h._refresh_hud()
	await process_frame
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	var want: String = shot[3]
	var top = stack.top()
	var ok: bool = not h.get_completion().is_terminal()
	ok = ok and (top.popup_id == want and top.text_fits() if want != "" else stack.depth() == 0)
	if not ok:
		_bad += 1
		print("REJECTED ", path, " stack=", stack.ids())
	else:
		var img := _sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " stack=", stack.ids(), " shell=", s.get_shell_id(),
			" slots=", s.get_five_slot_strip().get_slot_count(), " speed=", s.get_speed_mode(), "/", s.get_speed_label(),
			" sb=", w.scrub_bucks(), " ", note)
	root.free()
	_sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
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
		occupied = h.get_slots().snapshot().filter(func(x): return bool(x.get("occupied", false))).size()
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
		if h.get_completion().is_terminal():
			break
	return "activations=%d moving=%d" % [i, _moving(h)]

func _moving(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n
