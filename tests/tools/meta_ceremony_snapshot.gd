extends SceneTree
## M43 master runtime evidence: the SHIPPING meta ceremonies (MetaCeremonies) on a real
## ModalStack over BG01, built from events derived by CeremonyEvents on a real AppState whose
## state was reached through the real authorities (add_card -> set / Master reward, ...).
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/meta_ceremony_snapshot.gd -- <out_dir> [kind,kind,...]
## Every capture is checked: frame inside the viewport, every Label fits its width.

const AppState = preload("res://scripts/app/app_state.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const INSETS := [0, 96, 0, 64]

var _bad := 0
var _out := ""
var _tmp: Array = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://meta_ceremony_snapshots"
	var kinds: Array = Array(args[1].split(",")) if args.size() > 1 else ["set_complete"]
	DirAccess.make_dir_recursive_absolute(_out if _out.is_absolute_path() else ProjectSettings.globalize_path(_out))
	var events := _events()
	for kind in kinds:
		var ev: Dictionary = events.get(kind, {})
		if ev.is_empty():
			_reject("no committed event for kind " + kind)
			continue
		for reduced in [false, true]:
			for sz in (SIZES if not reduced else [SIZES[0]]):
				await _capture(ev, reduced, sz)
	print("META_CEREMONY_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	quit(1 if _bad > 0 else 0)

## One committed event per kind, reached through the real authorities on a temp save.
func _events() -> Dictionary:
	var path := "user://meta_ceremony_evidence_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var app = AppState.new(path)
	for k in range(9):
		app.economy.collection.add_card("s6_c%d" % k)
	var out := {}
	for e in CeremonyEvents.events(app.economy):
		if not out.has(e["kind"]):
			out[e["kind"]] = e
	# Robot: the next canonical robot unlocked through the real facade (Bot Parts spent once).
	app.economy.wallet.credit("bot_parts", 287)
	app.actions.unlock_next_robot()
	# Master: every set completed through the real authority (exactly-once Master grant).
	for n in range(1, 16):
		for k in range(9):
			if app.economy.collection.owned("s%d_c%d" % [n, k]) == 0:
				app.economy.collection.add_card("s%d_c%d" % [n, k])
	for e in CeremonyEvents.events(app.economy):
		if not out.has(e["kind"]):
			out[e["kind"]] = e
	return out

func _capture(ev: Dictionary, reduced: bool, size: Vector2i) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.125, 0.145, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)
	var stack = ModalStack.new()
	sub.add_child(stack)
	stack.set_synthetic_safe_insets(INSETS[0], INSETS[1], INSETS[2], INSETS[3])
	var p = MetaCeremonies.build(ev, reduced)
	stack.push(p)
	if not reduced:
		MetaCeremonies.start_motion(p)
	for _i in range(8):
		await RenderingServer.frame_post_draw
	var path := "%s/%s_%s_%dx%d.png" % [_out, String(ev["kind"]), "REDUCED" if reduced else "FULL", size.x, size.y]
	var bad := _problem(p, Rect2(Vector2.ZERO, Vector2(size)))
	if not bad.is_empty():
		_reject("%s: %s" % [path, bad])
	print("SNAPSHOT ", path, " err=", sub.get_texture().get_image().save_png(path))
	sub.free()
	await process_frame

func _problem(p, view: Rect2) -> String:
	if not view.grow(1.0).encloses(p.get_frame_rect()):
		return "frame outside viewport %s" % str(p.get_frame_rect())
	for l in p.find_children("*", "Label", true, false):
		if l.is_visible_in_tree() and l.autowrap_mode == TextServer.AUTOWRAP_OFF and l.get_minimum_size().x > l.size.x + 0.5:
			return "label %s overflows" % l.name
	if not p.text_fits():
		return "BasePopup.text_fits() false"
	return ""

func _reject(msg: String) -> void:
	_bad += 1
	print("REJECTED ", msg)
