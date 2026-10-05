extends SceneTree
## M43-C007 runtime evidence: real app root, Collection reached through the real authorities
## (add_card -> set reward). Album at every viewport; set detail (NEW / EXTRAS / not found), card
## detail and Cards Exchange at 1080x2160. Needs a rendering driver:
##   godot --path . -s res://tests/tools/collection_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://collection_snapshots"
	for sz in SIZES:
		await _run(sz, sz == SIZES[1])
	print("COLLECTION_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, all_states: bool) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var path := "user://collection_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	var app = root.get_app_state()
	var e = app.economy
	for k in range(9):
		e.collection.add_card("s1_c%d" % k)
	for cid in ["s2_c0", "s2_c0", "s2_c0", "s2_c4", "s2_c8", "s3_c1", "s3_c1"]:
		e.collection.add_card(cid)
	var st = root.get_modal_stack()
	CollectionScreen.open_album(st, app)
	await _draw(6)
	_shot(sub, st, "1_album", size)
	if all_states:
		CollectionScreen.open_set(st, app, 2)
		await _draw(6)
		_shot(sub, st, "2_set_detail_new_extras_notfound", size)
		CollectionScreen.open_card(st, app, "s2_c0")
		await _draw(6)
		_shot(sub, st, "3_card_detail", size)
		st.top().close("evidence")
		st.top().close("evidence")
		await _draw(2)
		CollectionScreen.open_exchange(st, app)
		await _draw(6)
		_shot(sub, st, "4_cards_exchange", size)
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

func _shot(sub: SubViewport, st, key: String, size: Vector2i) -> void:
	var top = st.top()
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
