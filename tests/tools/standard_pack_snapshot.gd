extends SceneTree
## M43-C005-C006 (SB-M43-064) V02 runtime evidence of the SHIPPING StandardPackCeremony:
## real ModalStack + ceremony over a BG01 backdrop, committed fixture models only, and real
## player taps delivered through SubViewport.push_input (both gates observable). Needs a
## rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/standard_pack_snapshot.gd -- <out_dir>
## Writes the 01..09 state shots (1080x1920), a Reduced Effects sequence, the AWAIT_ROUTE
## state at every required viewport, and an ordered evidence timeline sheet (evidence only).

const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")

const REF := Vector2i(1080, 1920)
const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const INSETS := [0, 96, 0, 64]

var _bad := 0
var _out := ""
var _timeline: Array = []   ## [name, Image]
var _runtime_frames: Dictionary = {}   ## V03: bound pack frame -> stage crop captured at runtime

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://standard_pack_snapshots"
	DirAccess.make_dir_recursive_absolute(_out if _out.is_absolute_path() else ProjectSettings.globalize_path(_out))
	# V03: one real capture per bound opening frame 01..09 after Tap 1 (FULL), + contact sheet.
	var beats := {}
	for k in range(1, 10):
		beats["F%02d_runtime_frame_%02d" % [k, k]] = (func(f): return func(p): return p.phase() == "OPENING" and p.pack_frame == f and p.frame_history().size() == f).call(k)
	await _flow(Fx.mixed("ev_beats"), false, beats)
	_runtime_sheet()
	# Full owner flow, mixed pack (NEW / DUPLICATE / NEW), 1080x1920.
	await _flow(Fx.mixed("ev_mixed"), false, {
		"01_pack_idle": func(p): return p.phase() == "IDLE",
		"02_opening_mid": func(p): return p.pack_frame == 5,
		"03_opening_late_cards_emerging": func(p): return p.pack_frame == 9 and p.get_card_views()[1].emerge > 0.2 and p.get_card_views()[1].emerge < 0.9,
		"04_three_card_hold": func(p): return p.get_stage().modulate.a == 0.0 and not p.get_destinations_layer().visible,
		"06_mixed_pre_route": func(p): return p.phase() == "AWAIT_ROUTE",
		"07_new_card_to_collection": func(p): return p.get_card_views()[0].route > 0.35 and p.get_card_views()[0].route < 0.7,
		"08_duplicate_card_to_exchange": func(p): return p.get_card_views()[1].route > 0.35 and p.get_card_views()[1].route < 0.7,
		"09_complete": func(_p): return false,   # captured from the closed signal
	})
	# Destinations visible with a repeated-duplicate pack (NEW, DUPLICATE 2, DUPLICATE 5).
	await _flow(Fx.repeat("ev_repeat"), false, {
		"05_destinations_visible": func(p): return p.phase() == "AWAIT_ROUTE",
		"10_repeat_duplicate_to_exchange": func(p): return p.get_card_views()[2].route > 0.35 and p.get_card_views()[2].route < 0.7,
	})
	# Reduced Effects: same two taps, frame 09 only, fades + short moves.
	await _flow(Fx.mixed("ev_reduced"), true, {
		"R1_reduced_pack_idle": func(p): return p.phase() == "IDLE",
		"R2_reduced_opening_frame09": func(p): return p.phase() == "OPENING" and p.pack_frame == 9,
		"R3_reduced_destinations_visible": func(p): return p.phase() == "AWAIT_ROUTE",
		"R4_reduced_routing": func(p): return p.phase() == "ROUTING" and p.get_card_views()[0].route > 0.2 and p.get_card_views()[0].route < 0.9,
		"R5_reduced_complete": func(_p): return false,
	})
	for sz in SIZES:
		await _flow(Fx.mixed("ev_size_%d" % sz.y), false, {"V_destinations_%dx%d" % [sz.x, sz.y]: func(p): return p.phase() == "AWAIT_ROUTE"}, sz, false)
	_sheet()
	quit(1 if _bad > 0 else 0)

## Mount, then run the real flow: tap 1 at IDLE, tap 2 at AWAIT_ROUTE (each only after its
## shot is captured), capturing each named state the first frame its predicate holds.
func _flow(model: Dictionary, reduced: bool, shots: Dictionary, size: Vector2i = REF, timeline := true) -> void:
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
	stack.set_synthetic_safe_insets(INSETS[0], INSETS[1], INSETS[2], INSETS[3])
	var p = StandardPackCeremony.create(model, reduced)["popup"]
	var info := {}
	p.closed.connect(func(reason): info.merge({"closed": reason, "frames": p.frame_history(), "routes": p.route_log(), "arrivals": p.arrivals(), "phase": p.phase()}))
	stack.push(p)
	var pending: Array = shots.keys()
	var taps := 0
	for _f in range(900):
		await RenderingServer.frame_post_draw
		if info.has("closed"):   # the popup is closed and freed by the ModalStack
			for k in pending.duplicate():
				if k.contains("complete"):
					_capture(sub, k, null, timeline)
					pending.erase(k)
			break
		for k in pending.duplicate():
			if shots[k].call(p):
				_capture(sub, k, p, timeline)
				pending.erase(k)
		var idle_done: bool = not pending.any(func(k): return k.contains("idle"))
		var dest_done: bool = not pending.any(func(k): return k.contains("pre_route") or k.contains("destinations"))
		if pending.is_empty():
			break
		if p.phase() == "IDLE" and idle_done:
			await _frames(20)   # the idle pack waits: nothing auto-starts
			if p.phase() != "IDLE":
				_reject("auto-start without a tap")
			_tap(sub, size)
			taps += 1
		elif p.phase() == "AWAIT_ROUTE" and dest_done:
			await _frames(20)   # the cards wait: nothing auto-routes
			if p.phase() != "AWAIT_ROUTE":
				_reject("auto-route without a tap")
			_tap(sub, size)
			taps += 1
	if not pending.is_empty():
		_reject("states never reached: %s" % str(pending))
	if not info.has("closed"):
		info = {"closed": "", "frames": p.frame_history(), "routes": p.route_log(), "arrivals": p.arrivals(), "phase": p.phase()}
	print("FLOW %s reduced=%s taps=%d %s" % [model["presentation_id"], reduced, taps, str(info)])
	sub.free()
	await process_frame

func _tap(sub: SubViewport, size: Vector2i) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(size) * Vector2(0.5, 0.82)
	ev.global_position = ev.position
	ev.pressed = true
	sub.push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	sub.push_input(up)

func _capture(sub: SubViewport, key: String, p, timeline: bool) -> void:
	var img := sub.get_texture().get_image()
	var bad := "" if p == null else _layout_problem(p)
	var path := "%s/%s_%dx%d.png" % [_out, key, sub.size.x, sub.size.y]
	if not bad.is_empty():
		_reject("%s: %s" % [path, bad])
	print("SNAPSHOT ", path, " err=", img.save_png(path), " phase=", "CLOSED" if p == null else p.phase(), " frame=", -1 if p == null else p.pack_frame)
	if timeline:
		_timeline.append([key, img])
	if key.begins_with("F0") and p != null:
		_runtime_frames[p.pack_frame] = [p.get_stage().texture.resource_path.get_file(), img.get_region(Rect2i(p.get_stage().get_global_rect()))]

## Visible ceremony controls stay inside the safe layer; destinations never cover a card in
## the row; the pack is never visible once destinations show.
func _layout_problem(p) -> String:
	var safe: Rect2 = p.get_layer().get_global_rect().grow(1.0)
	var items: Array = [p.get_hint(), p.get_layer().get_node("Title")]
	if p.get_destinations_layer().visible:
		for k in ["collection", "exchange"]:
			items.append(p.get_destination(k))
			items.append(p.get_destination(k).get_node("Label"))
		if p.get_stage().is_visible_in_tree() and p.get_stage().modulate.a > 0.0:
			return "pack visible with destinations"
	for c in items:
		if c.is_visible_in_tree() and not safe.encloses(c.get_global_rect()):
			return "%s outside safe area %s" % [c.name, str(c.get_global_rect())]
		if c is Label and c.is_visible_in_tree() and c.get_minimum_size().x > c.size.x + 0.5:
			return "%s text wider than its rect (%d > %d)" % [c.name, int(c.get_minimum_size().x), int(c.size.x)]
	if p.phase() == "AWAIT_ROUTE":
		for cv in p.get_card_views():
			var r: Rect2 = cv.get_global_rect()
			if not safe.encloses(r):
				return "%s outside safe area" % cv.name
			for k in ["collection", "exchange"]:
				var d: Control = p.get_destination(k)
				if r.intersects(d.get_global_rect()) or r.intersects(d.get_node("Label").get_global_rect()):
					return "%s overlaps %s" % [cv.name, k]
	return ""

## Evidence-only 3x3 sheet of the runtime captures of bound frames 01..09 (stage crops).
func _runtime_sheet() -> void:
	var keys: Array = _runtime_frames.keys()
	keys.sort()
	if keys != range(1, 10):
		_reject("runtime capture missing frames: %s" % str(keys))
		return
	var w := 300
	var h := 450
	var sheet := Image.create(3 * (w + 12) + 12, 3 * (h + 12) + 12, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.95, 0.95, 0.95))
	for i in range(9):
		var im: Image = _runtime_frames[i + 1][1]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(12 + (i % 3) * (w + 12), 12 + (i / 3) * (h + 12)))
	var path := "%s/STANDARD_RUNTIME_01_09_V03_CONTACT_SHEET.png" % _out
	print("RUNTIME frames ", keys.map(func(k): return "%02d=%s" % [k, _runtime_frames[k][0]]))
	print("SNAPSHOT ", path, " err=", sheet.save_png(path))

func _sheet() -> void:
	_timeline.sort_custom(func(a, b): return String(a[0]) < String(b[0]))
	var w := 270
	var h := 480
	var cols := 5
	var rows := int(ceil(_timeline.size() / float(cols)))
	var sheet := Image.create(cols * (w + 12) + 12, rows * (h + 12) + 12, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.95, 0.95, 0.95))
	for i in range(_timeline.size()):
		var im: Image = _timeline[i][1]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(12 + (i % cols) * (w + 12), 12 + (i / cols) * (h + 12)))
	var path := "%s/V02_evidence_timeline_EVIDENCE_ONLY.png" % _out
	print("TIMELINE order ", _timeline.map(func(t): return t[0]))
	print("SNAPSHOT ", path, " err=", sheet.save_png(path))

func _reject(msg: String) -> void:
	_bad += 1
	print("REJECTED ", msg)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
