extends SceneTree
## M43-C003-C001 acquisition evidence snapshots. Real app root (main.tscn), real Home /
## gameplay, the ONE ModalStack + AcquisitionFlow. Economy state set only through the
## canonical services on a temp save; "rewarded available" uses the TEST provider double
## on the provider-neutral seam (production stays unavailable).
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/acquisition_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")

const PHONE := Vector2i(1080, 2160)
## [stem, size, where ("home"|"play"), scenario]
const SHOTS := [
	["life_partial_rewarded_available", PHONE, "home", "life_partial"],
	["life_full_5of5", PHONE, "home", "life_full"],
	["life_insufficient_sb", PHONE, "home", "life_insufficient"],
	["life_rewarded_unavailable", PHONE, "home", "life_no_video"],
	["life_rewarded_loading", PHONE, "home", "life_watching"],
	["life_zero_heart_gate", PHONE, "home", "life_gate"],
	["shop_handoff_from_home_sb_plus", PHONE, "home", "shop_home"],
	["booster_plus_one_slot", PHONE, "play", "b:plus_one_slot"],
	["booster_random", PHONE, "play", "b:random"],
	["booster_selector", PHONE, "play", "b:selector"],
	["booster_tornado", PHONE, "play", "b:tornado"],
	["booster_tornado_rewarded_unavailable", PHONE, "play", "b_novideo:tornado"],
	["booster_selector_owned_use_mode", PHONE, "play", "b_owned:selector"],
	["booster_plus_one_slot_already_used", PHONE, "play", "b_used:plus_one_slot"],
	["booster_insufficient_sb", PHONE, "play", "b_insufficient:tornado"],
	["booster_shop_handoff", PHONE, "play", "b_shop:tornado"],
	["speed_no_entitlement", PHONE, "play", "speed"],
	["speed_timed_active", PHONE, "play", "speed_timed"],
	["speed_insufficient_sb", PHONE, "play", "speed_insufficient"],
	["life_short_phone", Vector2i(1080, 1920), "home", "life_partial"],
	["booster_selector_short_phone", Vector2i(1080, 1920), "play", "b:selector"],
	["speed_short_phone", Vector2i(1080, 1920), "play", "speed"],
	["life_phone_1170", Vector2i(1170, 2532), "home", "life_partial"],
	["booster_tornado_phone_1290", Vector2i(1290, 2796), "play", "b:tornado"],
	["life_tablet", Vector2i(1536, 2048), "home", "life_partial"],
	["booster_tornado_tablet", Vector2i(1536, 2048), "play", "b:tornado"],
	["speed_tablet", Vector2i(1536, 2048), "play", "speed_timed"],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://acquisition_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var save_path := "user://acq_snapshot_%d.save" % Time.get_ticks_usec()
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = save_path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await process_frame
	var app = root.get_app_state()
	var eco = app.economy
	var prov = ProviderDouble.new()
	eco.rewarded.set_provider(prov)
	var acq = root.get_acquisition()
	var stack = root.get_modal_stack()
	var h = null
	if shot[2] == "play":
		app.progression.debug_set_current_level(2)
		root.play_current_frontier()
		await process_frame
		h = root.get_gameplay_host()
		h.get_runtime().set_process(false)
		for col in range(h.get_supply().get_column_count()):
			if h.get_input_controller().activate_front(col).get("ok", false):
				break
		for _i in range(20):
			h.get_runtime().tick(0.05)
	var sc: String = shot[3]
	var now := int(Time.get_unix_time_from_system())
	if sc.begins_with("life"):
		eco.hearts.import_snapshot({"hearts": 5 if sc == "life_full" else (0 if sc == "life_gate" else 2), "anchor": now - 198})
		if sc == "life_no_video":
			prov.available = false
		if sc == "life_gate":
			root.play_current_frontier()
		else:
			root.open_life("home_heart_plus")
		if sc == "life_insufficient":
			eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks() - 120)
			acq.find_open("life").get_action_button("heart_plus_one").pressed.emit()
		elif sc == "life_watching":
			acq.find_open("life").get_action_button("watch").pressed.emit()
	elif sc == "shop_home":
		root.get_home().scrub_bucks_purchase_requested.emit()
	elif sc.begins_with("b"):
		var id: String = sc.split(":")[1]
		var mode: String = sc.split(":")[0]
		if mode == "b_novideo":
			prov.available = false
		if mode == "b_owned":
			eco.boosters.add_charges(id, 2)
		if mode == "b_used":
			eco.boosters.add_charges(id, 1)
			h.request_booster(id)
		acq.open_booster(h, id)
		var p = stack.top()
		if p.find_child("Targets", true, false) != null and p.find_child("Targets", true, false).get_child_count() > 1:
			(p.find_child("Targets", true, false).get_child(1) as Button).pressed.emit()
		if mode == "b_insufficient" or mode == "b_shop":
			eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks() - 200)
			p.get_action_button("sb").pressed.emit()
			if mode == "b_shop":
				stack.top().get_action_button("shop").pressed.emit()
	elif sc.begins_with("speed"):
		if sc == "speed_timed":
			eco.wallet.credit("scrub_bucks", 1000)
			eco.speed.purchase_timed(900)
			h._open_speed_acquisition()
		else:
			h.get_screen().get_speed_button().pressed.emit()
		if sc == "speed_insufficient":
			eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks() - 150)
			h.get_speed_acquisition_popup().refresh(h.speed_state())
			h.get_speed_acquisition_popup().get_offer_button("timed_1800").pressed.emit()
	if root.get_home() != null and root.get_home().visible:
		root.get_home().refresh()
	for _i in range(12):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	var fits: bool = stack.depth() > 0
	for c in stack.get_child(0).get_children():
		fits = fits and c.text_fits()
	if not fits:
		_bad += 1
		print("REJECTED ", path, " stack=", stack.ids())
	else:
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " stack=", stack.ids(), " top_frame=", stack.top().get_frame_kind(),
			" hearts=", eco.hearts.hearts(), " sb=", eco.wallet.scrub_bucks())
	root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
