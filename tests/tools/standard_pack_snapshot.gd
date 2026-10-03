extends SceneTree
## M43-C005-C006 (SB-M43-064) runtime evidence of the SHIPPING StandardPackCeremony (not the
## preview harness): real ModalStack + BasePopup family over a BG01 backdrop, committed
## fixture model only. Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/standard_pack_snapshot.gd -- <out_dir>
## Writes final-state shots per viewport, a Reduced Effects shot and an ordered strip of the
## real opening beats 01..09 + final faces captured while the sequencer runs.

const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://standard_pack_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	for sz in SIZES:
		await _final_shot(out_dir, sz, false, Fx.mixed("snap_%d" % sz.y))
	await _final_shot(out_dir, Vector2i(1080, 2160), true, Fx.mixed("snap_reduced"))
	await _final_shot(out_dir, Vector2i(1080, 2160), false, Fx.repeat("snap_repeat"), "_repeat")
	await _strip(out_dir, Vector2i(1080, 2160))
	quit(1 if _bad > 0 else 0)

func _mount(size: Vector2i, model: Dictionary, reduced: bool) -> Array:
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
	var p = StandardPackCeremony.create(model, reduced)["popup"]
	stack.push(p)
	return [sub, p]

func _final_shot(out_dir: String, size: Vector2i, reduced: bool, model: Dictionary, tag: String = "") -> void:
	var m := _mount(size, model, reduced)
	var sub: SubViewport = m[0]
	var p = m[1]
	for _i in range(240):
		if not p.is_presenting():
			break
		await process_frame
	for _i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var fits: bool = p.text_fits() and Rect2(Vector2(0, 96), Vector2(size) - Vector2(0, 160)).encloses(p.get_frame_rect())
	var path := "%s/standard_pack%s%s_%dx%d.png" % [out_dir, tag, "_reduced_effects" if reduced else "", size.x, size.y]
	if not fits or p.is_presenting():
		_bad += 1
		print("REJECTED ", path, " frame=", p.get_frame_rect(), " presenting=", p.is_presenting())
	else:
		print("SNAPSHOT ", path, " err=", sub.get_texture().get_image().save_png(path), " frame=", p.get_frame_rect())
	sub.free()
	await process_frame

## Capture the popup frame each time a new pack beat is bound, then the final faces.
func _strip(out_dir: String, size: Vector2i) -> void:
	var m := _mount(size, Fx.mixed("snap_strip"), false)
	var sub: SubViewport = m[0]
	var p = m[1]
	var panels: Array = []
	var seen := 0
	for _i in range(600):
		await RenderingServer.frame_post_draw
		var hist: Array = p.frame_history()
		if hist.size() > seen:
			seen = hist.size()
			panels.append([str(hist.back()), sub.get_texture().get_image().get_region(Rect2i(p.get_frame_rect()))])
		if not p.is_presenting():
			break
	for _i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	panels.append(["final", sub.get_texture().get_image().get_region(Rect2i(p.get_frame_rect()))])
	var labels: Array = panels.map(func(x): return x[0])
	print("STRIP beats ", labels)
	if labels != ["1", "2", "3", "4", "5", "6", "7", "8", "9", "final"]:
		_bad += 1
		print("REJECTED strip: beats not exactly 01..09 + final")
	var w := 360
	var h := int(round(w * float(panels[0][1].get_height()) / panels[0][1].get_width()))
	var sheet := Image.create(w * 5 + 6 * 12, h * 2 + 3 * 12, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.07, 0.08, 0.1))
	for i in range(panels.size()):
		var im: Image = panels[i][1]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(12 + (i % 5) * (w + 12), 12 + (i / 5) * (h + 12)))
	var path := "%s/standard_pack_opening_strip_%dx%d.png" % [out_dir, size.x, size.y]
	print("SNAPSHOT ", path, " err=", sheet.save_png(path))
	sub.free()
	await process_frame
