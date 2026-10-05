extends SceneTree
## M43-C006 runtime evidence: the real Shop destination in the real app root (opening skipped).
## States: default, insufficient-SB return context, confirm, success feedback, scrolled to the
## gated Scrub Bucks / No Ads entries. Needs a rendering driver:
##   godot --path . -s res://tests/tools/shop_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://shop_snapshots"
	for sz in SIZES:
		await _run(sz, sz == SIZES[1])
	print("SHOP_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, all_states: bool) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var path := "user://shop_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	var st = root.get_modal_stack()
	root.get_acquisition().open_shop({"source": "evidence"})
	await _draw(6)
	_shot(sub, root, "1_shop_default", size)
	if all_states:
		var shop = ShopScreen.of(st.top())
		var list: ScrollContainer = st.top().find_child("ShopList", true, false)
		list.scroll_vertical = 100000
		await _draw(4)
		_shot(sub, root, "2_shop_store_gated_entries", size)
		st.top().close("evidence")
		await _draw(2)
		root.get_app_state().economy.wallet.debit("scrub_bucks", root.get_app_state().economy.wallet.scrub_bucks() - 120)
		root.get_app_state().economy.hearts.consume()
		root.get_acquisition().open_shop({"source": "life", "item_label": "+1 Heart", "price_sb": 500, "product": "heart_plus_one"})
		await _draw(6)
		_shot(sub, root, "3_shop_return_context_insufficient", size)
		st.top().close("evidence")
		await _draw(2)
		root.get_app_state().economy.wallet.credit("scrub_bucks", 2000)
		root.get_acquisition().open_shop({"source": "evidence"})
		await _draw(4)
		st.top()._on_action("buy:booster:random")
		await _draw(4)
		_shot(sub, root, "4_shop_confirm", size)
		st.top()._on_action("confirm")
		await _draw(4)
		_shot(sub, root, "5_shop_success_feedback", size)
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
