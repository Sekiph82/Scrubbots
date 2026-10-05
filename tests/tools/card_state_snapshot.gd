extends SceneTree
## M43-C005-C009 (SB-M43-067) runtime evidence: first-new-card celebration + duplicate counts in
## the SHIPPING Standard / Premium ceremonies (real ModalStack, committed fixture models, real
## player taps through SubViewport.push_input). Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/card_state_snapshot.gd -- <out_dir>
## Every capture is layout-checked (cards inside the safe layer, no card/card, card/destination
## or card/hint overlap, card texts fit the card width); any problem is REJECTED.

const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const SFx = preload("res://tests/support/standard_pack_fixtures.gd")
const PFx = preload("res://tests/support/premium_pack_fixtures.gd")

const REF := Vector2i(1080, 1920)
const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const INSETS := [0, 96, 0, 64]

var _bad := 0
var _out := ""
var _sheet_imgs: Array = []   ## [name, Image]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://card_state_snapshots"
	DirAccess.make_dir_recursive_absolute(_out if _out.is_absolute_path() else ProjectSettings.globalize_path(_out))
	var celebrating := func(p): return p.phase() == "OPENING" and p.celebration > 0.18 and p.celebration < 0.40
	var hold := func(p): return p.phase() == "AWAIT_ROUTE"
	# Standard
	await _flow("std", SFx.mixed("ev_std_mixed"), false, {"S1_std_mixed_new_celebration": celebrating, "S2_std_mixed_hold_first_copy_extras_destinations": hold})
	await _flow("std", SFx.triple("ev_std_triple"), false, {"S3_std_repeat_first_copy_x1_x2": hold})
	await _flow("std", SFx.all_duplicate("ev_std_dup"), false, {"S4_std_all_duplicate_extras": hold})
	await _flow("std", SFx.all_new("ev_std_new"), false, {"S5_std_all_new_celebration": celebrating, "S6_std_all_new_hold": hold})
	# Premium
	await _flow("prem", PFx.mixed("ev_prem_mixed"), false, {"P1_prem_mixed_new_celebration": celebrating, "P2_prem_mixed_hold_3plus2": hold})
	await _flow("prem", PFx.all_duplicate("ev_prem_dup"), false, {"P3_prem_duplicate_heavy_extras": hold})
	await _flow("prem", PFx.all_new("ev_prem_new"), false, {"P4_prem_all_new_celebration_overlap": func(p): return p.phase() == "OPENING" and p.celebration > 0.45 and p.celebration < 0.65, "P5_prem_all_new_hold": hold})
	await _flow("prem", PFx.repeat("ev_prem_rep"), false, {"P6_prem_repeat_first_copy_x1_x4": hold})
	# Reduced Effects
	await _flow("std", SFx.mixed("ev_std_red"), true, {"R1_std_reduced_cards_in": func(p): return p.phase() == "OPENING" and p.get_card_views()[2].emerge > 0.4, "R2_std_reduced_hold": hold})
	await _flow("prem", PFx.mixed("ev_prem_red"), true, {"R3_prem_reduced_cards_in": func(p): return p.phase() == "OPENING" and p.get_card_views()[4].emerge > 0.4, "R4_prem_reduced_hold": hold})
	# Viewport matrix (final readable hold)
	for sz in SIZES:
		await _flow("std", SFx.mixed("ev_std_%d" % sz.y), false, {"V_std_mixed_hold": hold}, sz, false)
		await _flow("prem", PFx.mixed("ev_prem_%d" % sz.y), false, {"V_prem_mixed_hold": hold}, sz, false)
		await _flow("prem", PFx.all_duplicate("ev_premdup_%d" % sz.y), false, {"V_prem_duplicate_heavy_hold": hold}, sz, false)
	_sheet()
	print("CARD_STATE_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _flow(kind: String, model: Dictionary, reduced: bool, shots: Dictionary, size: Vector2i = REF, sheet := true) -> void:
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
	var r: Dictionary = StandardPackCeremony.create(model, reduced) if kind == "std" else PremiumPackCeremony.create_premium(model, reduced)
	var p = r["popup"]
	stack.push(p)
	var pending: Array = shots.keys()
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline and not pending.is_empty():
		await RenderingServer.frame_post_draw
		for k in pending.duplicate():
			if shots[k].call(p):
				_capture(sub, k, p, sheet)
				pending.erase(k)
		if p.phase() == "IDLE":
			await _frames(10)
			_tap(sub, size)
	if not pending.is_empty():
		_reject("%s: states never reached %s" % [model["presentation_id"], str(pending)])
	print("FLOW %s reduced=%s texts=%s" % [model["presentation_id"], reduced, str(p.get_card_views().map(func(cv): return [_text(cv, "State"), _text(cv, "Copies")]))])
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

func _capture(sub: SubViewport, key: String, p, sheet: bool) -> void:
	var img := sub.get_texture().get_image()
	var path := "%s/%s_%dx%d.png" % [_out, key, sub.size.x, sub.size.y]
	var bad := _layout_problem(p)
	if not bad.is_empty():
		_reject("%s: %s" % [path, bad])
	print("SNAPSHOT ", path, " err=", img.save_png(path), " phase=", p.phase(), " celebration=%.2f" % p.celebration)
	if sheet:
		_sheet_imgs.append([key, img])

func _layout_problem(p) -> String:
	var safe: Rect2 = p.get_layer().get_global_rect().grow(1.0)
	var cvs: Array = p.get_card_views().filter(func(cv): return cv.is_visible_in_tree())
	for a in range(cvs.size()):
		var r: Rect2 = cvs[a].get_global_rect()
		if not safe.encloses(r):
			return "%s outside safe area" % cvs[a].name
		for b in range(a + 1, cvs.size()):
			if r.intersects(cvs[b].get_global_rect()):
				return "cards %s / %s overlap" % [cvs[a].name, cvs[b].name]
		if p.get_destinations_layer().visible:
			for k in ["collection", "exchange"]:
				var d: Control = p.get_destination(k)
				if r.intersects(d.get_global_rect()) or r.intersects(d.get_node("Label").get_global_rect()):
					return "%s overlaps %s" % [cvs[a].name, k]
		if p.get_hint().is_visible_in_tree() and r.intersects(p.get_hint().get_global_rect()):
			return "%s overlaps the hint" % cvs[a].name
		for n in ["Name", "Copies", "State", "Rarity"]:
			var c: Control = cvs[a].find_child(n, true, false)
			if c.get_minimum_size().x > cvs[a].size.x + 0.5:
				return "%s %s wider than the card" % [cvs[a].name, n]
	return ""

func _text(node: Node, n: String) -> String:
	var c := node.find_child(n, true, false)
	if c is Label:
		return c.text
	return (c.get_node("Text") as Label).text if c != null else ""

func _sheet() -> void:
	var w := 270
	var h := 480
	var cols := 5
	var rows := int(ceil(_sheet_imgs.size() / float(cols)))
	var sheet := Image.create(cols * (w + 12) + 12, rows * (h + 40) + 12, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.95, 0.95, 0.95))
	for i in range(_sheet_imgs.size()):
		var im: Image = _sheet_imgs[i][1]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(12 + (i % cols) * (w + 12), 12 + (i / cols) * (h + 40)))
	var path := "%s/CARD_STATE_V01_EVIDENCE_SHEET.png" % _out
	print("SHEET order ", _sheet_imgs.map(func(t): return t[0]))
	print("SNAPSHOT ", path, " err=", sheet.save_png(path))

func _reject(msg: String) -> void:
	_bad += 1
	print("REJECTED ", msg)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
