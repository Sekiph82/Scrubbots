extends SceneTree
## M39-C003 (SB-M39-054) presentation evidence (TOOL ONLY): renders the SHIPPING Gift 50
## ceremony and the earned ScrubBox popup with the real config, no AppState / save / economy
## mutation. Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/random_any_booster_evidence.gd -- <out_dir>

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")

const SIZE := Vector2i(1080, 1920)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://m39_c003_evidence"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var cfg := EconomyConfig.new()
	var gift := func(stack): return stack.push(MetaCeremonies.gift_milestone({"milestone": 50, "cycle_max": cfg.gift_meter_cycle_max(), "rewards": cfg.gift_meter_milestone(50), "key": "gift:gift_ms:c0:m50"}, true))
	var box := func(stack): return DailyScreens.open_scrubbox(stack, null, {"ok": true, "random_any_booster_charges": cfg.daily_config()["all_tasks_random_any_booster_charges"]}) != null
	await _shot(out_dir + "/gift_50_mystery_booster.png", gift)
	await _shot(out_dir + "/scrubbox_mystery_booster.png", box)
	quit(0)

func _shot(path: String, open: Callable) -> void:
	var sub := SubViewport.new()
	sub.size = SIZE
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.125, 0.145, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)
	var stack = ModalStack.new()
	sub.add_child(stack)
	stack.set_synthetic_safe_insets(0, 96, 0, 64)
	var ok: bool = open.call(stack)
	for _i in range(60):
		await process_frame
	print("EVIDENCE ", path, " opened=", ok, " err=", sub.get_texture().get_image().save_png(path))
	sub.free()
	await process_frame
