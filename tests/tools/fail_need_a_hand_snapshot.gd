extends SceneTree
## M43-C004-C001 Fail / Need a Hand evidence snapshots. Real app root (main.tscn), real
## gameplay host on catalog level 2, the ONE ModalStack + AcquisitionFlow. Failures are the
## real terminal signal; economy state is set only through canonical services on a temp
## save; "rewarded available" uses the TEST provider double (production stays unavailable).
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/fail_need_a_hand_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")

const PHONE := Vector2i(1080, 2160)
const SHORT := Vector2i(1080, 1920)
const TABLET := Vector2i(1536, 2048)
## [stem, size, failures, scenario]
const SHOTS := [
	["fail_reference_phone", PHONE, 1, "fail"],
	["fail_short_phone", SHORT, 1, "fail"],
	["fail_phone_1170", Vector2i(1170, 2532), 1, "fail"],
	["fail_tablet", TABLET, 1, "fail"],
	["need_a_hand_third_failure_2buy_2watch", PHONE, 3, "nah"],
	["need_a_hand_short_phone", SHORT, 3, "nah"],
	["need_a_hand_phone_1170", Vector2i(1170, 2532), 3, "nah"],
	["need_a_hand_phone_1290", Vector2i(1290, 2796), 3, "nah"],
	["need_a_hand_tablet", TABLET, 3, "nah"],
	["need_a_hand_one_card_rewarded_unavailable", PHONE, 3, "nah_one_novideo"],
	["need_a_hand_production_provider_unavailable", PHONE, 3, "nah_prod"],
	["need_a_hand_rewarded_loading", PHONE, 3, "nah_loading"],
	["need_a_hand_insufficient_sb", PHONE, 3, "nah_insufficient"],
	["need_a_hand_shop_handoff", PHONE, 3, "nah_shop"],
	["need_a_hand_owned_charge", PHONE, 3, "nah_owned"],
	["need_a_hand_after_buy", PHONE, 3, "nah_bought"],
	["fail_after_need_a_hand_closed", PHONE, 3, "nah_closed"],
	["zero_heart_retry_life", PHONE, 1, "zero_heart"],
	["fail_reduced_effects", PHONE, 1, "fail_reduced"],
	["need_a_hand_reduced_effects", PHONE, 3, "nah_reduced"],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://fail_nah_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var sc: String = shot[3]
	var save_path := "user://fail_nah_snapshot_%d.save" % Time.get_ticks_usec()
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
	if sc != "nah_prod":
		eco.rewarded.set_provider(prov)
	if sc.ends_with("reduced"):
		app.set_reduced_effects(true)
	app.progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 2, "completed": [1]})
	eco.hearts.import_snapshot({"hearts": 5, "anchor": int(Time.get_unix_time_from_system())})
	eco.streak.import_snapshot({"schema": "scrubbots.winstreak.v1", "streak": 3, "processed": [1]})
	if sc == "nah_owned":
		eco.boosters.add_charges("tornado", 1)
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	for col in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(col).get("ok", false):
			break
	for _i in range(20):
		h.get_runtime().tick(0.05)
	if sc == "zero_heart":
		eco.hearts.import_snapshot({"hearts": 1, "anchor": int(Time.get_unix_time_from_system()) - 200})
	var acq = root.get_acquisition()
	var stack = root.get_modal_stack()
	for i in range(int(shot[2])):
		if i > 0:
			stack.clear("t")
			root.retry_from_results()
			await process_frame
		h.get_completion().terminal_reached.emit(&"LOST", {})
		await process_frame
	var p = acq.find_open("need_a_hand")
	var ids: Array = p.context["boosters"] if p != null else []
	match sc:
		"nah_one_novideo":
			prov.per_placement[RewardedGrantService.placement("booster:" + ids[0])] = false
			acq._refresh_nah(p)
		"nah_loading":
			p.get_action_button("watch:" + ids[0]).pressed.emit()
		"nah_insufficient", "nah_shop":
			eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks() - 200)
			acq._refresh_nah(p)
			p.get_action_button("buy:" + ids[0]).pressed.emit()
			if sc == "nah_shop":
				stack.top().get_action_button("shop").pressed.emit()
		"nah_bought":
			eco.wallet.credit("scrub_bucks", 1000)
			p.get_action_button("buy:" + ids[1]).pressed.emit()
		"nah_closed":
			p.get_close_button().pressed.emit()
		"zero_heart":
			root.get_results_screen().get_primary_button().pressed.emit()
	for _i in range(12):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	var vp := Rect2(Vector2.ZERO, Vector2(size))
	var res = root.get_results_screen()
	var fits: bool = res.visible and vp.encloses(res.get_panel().get_global_rect()) and vp.encloses(res.get_robot().get_global_rect())
	for c in stack.get_child(0).get_children():
		fits = fits and c.text_fits()
	if sc.begins_with("nah") and sc != "nah_closed":
		fits = fits and p != null
	if not fits:
		_bad += 1
		print("REJECTED ", path, " stack=", stack.ids())
	else:
		var img := sub.get_texture().get_image()
		print("SNAPSHOT ", path, " err=", img.save_png(path), " stack=", stack.ids(), " picks=", ids,
			" hearts=", eco.hearts.hearts(), " sb=", eco.wallet.scrub_bucks(), " charges=", eco.boosters.snapshot())
	root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
