extends SceneTree
## M43-C005-C001 ceremony visual-master evidence (PREVIEW HARNESS ONLY). Real BasePopup /
## ModalStack family over a BG01 backdrop, fixture data only: no AppState, no save, no
## economy. Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/ceremony_preview/ceremony_snapshot.gd -- <out_dir> [key,key,...]

const CC = preload("res://tests/tools/ceremony_preview/ceremony_candidates.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")

const REF := Vector2i(1080, 2160)
const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://ceremony_snapshots"
	var only: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray()   # optional key filter
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	var t := CC.truth()
	var fx := {
		"standard_pack": CC.standard_pack_fixture(t),
		"premium_pack": CC.premium_pack_fixture(t),
		"set_complete": CC.set_complete_fixture(t, 6),
		"master_complete": CC.master_fixture(t),
		"robot_unlock": CC.robot_fixture("Moppy"),
		"gift_250": CC.gift_fixture(t, 250),
		"gift_500": CC.gift_fixture(t, 500),
		"gift_1000": CC.gift_fixture(t, 1000),
		"feature_unlock": CC.feature_fixture(),
		"world_shell": CC.world_shell_fixture(),
		"generic_1": {"title": "DAILY REWARD", "rewards": {"scrub_bucks": 50}},
		"generic_4": {"title": "TASKS 3/3 COMPLETE", "rewards": {"scrub_bucks": 150, "bot_parts": 2, "standard_card_packs": 1, "random_any_booster_charges": 1}},
	}
	var shots: Array = []
	for k in ["standard_pack", "premium_pack", "set_complete", "master_complete", "robot_unlock", "gift_250", "gift_500", "gift_1000", "feature_unlock", "world_shell", "generic_1", "generic_4"]:
		shots.append([k, REF, false])
	shots.append(["premium_pack", REF, true])
	shots.append(["robot_unlock", REF, true])
	shots.append(["gift_500", REF, true])
	shots.append(["gift_1000", REF, true])
	for sz in SIZES:
		if sz != REF:
			for k in ["premium_pack", "robot_unlock", "gift_500", "gift_1000", "master_complete"]:
				shots.append([k, sz, false])
	for s in shots:
		if only.is_empty() or s[0] in only:
			await _shot(out_dir, s, fx, t)
	quit(1 if _bad > 0 else 0)

static func kind_of(key: String) -> String:
	if key.begins_with("gift_"):
		return "gift_milestone"
	if key.begins_with("generic_"):
		return "generic_reward"
	return key

func _shot(out_dir: String, s: Array, fx: Dictionary, _t: Dictionary) -> void:
	var key: String = s[0]
	var size: Vector2i = s[1]
	var reduced: bool = s[2]
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.125, 0.145, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)
	var stack = ModalStack.new()
	sub.add_child(stack)
	stack.set_synthetic_safe_insets(0, 96, 0, 64)
	var p = CC.build(kind_of(key), fx[key], reduced)
	stack.push(p)
	CC.start_motion(p)
	for _i in range(90 if not reduced else 8):   # let flips / settle finish (~1.5 s)
		await process_frame
	var fits: bool = p.text_fits() and Rect2(Vector2(0, 96), Vector2(size) - Vector2(0, 160)).encloses(p.get_frame_rect())
	var path := "%s/%s%s_%dx%d.png" % [out_dir, key, "_reduced_effects" if reduced else "", size.x, size.y]
	if not fits:
		_bad += 1
		print("REJECTED ", path, " frame=", p.get_frame_rect())
	else:
		print("SNAPSHOT ", path, " err=", sub.get_texture().get_image().save_png(path))
	sub.free()
	await process_frame
