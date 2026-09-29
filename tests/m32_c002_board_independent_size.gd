extends SceneTree
## M32-C002 V01 — board-resolution-independent Scrubbot apparent size (SB-M32-UI-012).
##
##   s0 REAL production GameplayScreen at ONE fixed viewport (1080x2160): production levels 1/2/3
##      (20x20 / 32x32 / 38x38) + TEST 59x59, width/height-limited rectangles and synthetic 100x100
##      -> measured displayed body footprint within +-3% of the 32x32 reference (screen seam:
##      reference = display cell a 32x32 board gets from the SAME rail fit in the SAME region).
##   s1 geometry-derived formula: on ONE available presentation rect the live local body span
##      = 2.4 * reference_32_cell_size / actual_rendered_cell_size (BoardPresentation seam), for
##      20/32/38/59, width- and height-limited rectangles and a TEST-only synthetic 100x100; a
##      generic sweep over many (w, h, rect) proves it follows geometry, not a size table.
##   s2 32x32 reference lock: compensation exactly 1.0, local span exactly 2.4 cells.
##   s3 apparent size: MEASURED global body footprint (sprite global transform x texture) of
##      every board within +-3% of the 32x32 reference (it is in fact exact).
##   s4 live relayout on a REAL laid-out production host: same agent instance, route, progress
##      and position survive a viewport resize; the body re-sizes; movement continues to arrival.
##   s5 presentation-only differential: compensated visual under a relaid-out presentation vs
##      bare agent -> identical position / progress / arrival / completion count / endpoint.
##   s6 retire echo: same compensation, echo/live = 2.1/2.4, exact cell centre, lifetime /
##      shrink / cap unchanged, mid-echo relayout rescales.
##   s7 performance: 59x59 + 30 live visuals, shared texture, bounded relayout cost, no object
##      growth, no per-frame work beyond an O(1) generation compare.
##
## Run: godot --headless --path . -s res://tests/m32_c002_board_independent_size.gd [-- <report.json>]

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RetireEcho = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const REF_SPAN := 2.4
const ECHO_REF_SPAN := 2.1

var _fail := 0
var _checks := 0
var _report := {}
var _tmp: Array = []
var _rect := Vector2.ZERO   # real production board rect at 1080x2160

func _initialize() -> void:
	await process_frame
	_rect = Vector2(800, 820)   # generic standalone presentation rect (s1-s3, s5-s7)
	_report["standalone_rect"] = [_rect.x, _rect.y]
	await _s0_real_screen()
	_s1_formula()
	_s2_reference_lock()
	_s3_apparent_size()
	await _s4_live_relayout()
	_s5_differential()
	_s6_echo()
	_s7_performance()
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(JSON.stringify(_report, "  "))
		f.close()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("M32-C002 BOARD-INDEPENDENT SIZE: %s (%d checks, %d failed)" % ["PASS" if _fail == 0 else "FAIL", _checks, _fail])
	quit(0 if _fail == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	print("  %s: %s" % ["ok" if cond else "FAIL", msg])
	if not cond:
		_fail += 1

# ------------------------------------------------------------------ helpers ----
func _board(w: int, h: int, tag: String = "m32c002"):
	var cells := PackedInt32Array()
	for y in range(h):
		for x in range(w):
			cells.append((x * 6 / w + y) % 6)
	return BoardState.from_level_data(LevelData.new(1, "%s_%dx%d" % [tag, w, h], tag, "TEST", w, h, PackedStringArray(HEX), cells))

## Standalone presentation (same node types as production) + one live visual on an agent.
func _presentation(board, rect: Vector2) -> Dictionary:
	var p = BoardPresentation.new()
	get_root().add_child(p)
	p.configure(board, board_palette(board), rect)
	var a = ScrubbotAgent.new()
	var v = ScrubbotVisual.new()
	a.add_child(v)
	p.get_agent_layer().add_child(a)
	a.position = Vector2(board.get_width() * 0.5, board.get_height() * 0.5)
	v.set_process(false)
	return {"p": p, "a": a, "v": v}

func board_palette(_board) -> PackedStringArray:
	return PackedStringArray(HEX)

## MEASURED displayed longest body dimension in global (canvas) pixels, at the body's base
## pose (the restrained bob/squash animation is neutralised for the measurement only).
func _displayed_span(v) -> float:
	var body: Sprite2D = v.get_child(0)
	body.scale = v._base_scale
	body.rotation = 0.0
	var tex: Vector2 = body.texture.get_size()
	var gt: Transform2D = body.get_global_transform()
	return maxf(tex.x * gt.x.length(), tex.y * gt.y.length())

func _free(d: Dictionary) -> void:
	d["p"].free()

# ---------------------------------------------------------------- s1 / s2 / s3 --
func _cases() -> Array:
	return [[20, 20], [32, 32], [38, 38], [59, 59], [59, 24], [24, 59], [40, 24], [24, 40], [100, 100]]

func _s1_formula() -> void:
	print("[s1 geometry-derived formula]")
	var rows: Array = []
	for c in _cases():
		var b = _board(c[0], c[1])
		var d := _presentation(b, _rect)
		var p = d["p"]
		var cs: float = p.get_cell_size()
		var ref: float = maxf(floor(minf(_rect.x / 32.0, _rect.y / 32.0)), 1.0)
		var want: float = REF_SPAN * ref / cs
		var got: float = d["v"].get_local_body_span_cells()
		var limit := "width" if _rect.x / c[0] < _rect.y / c[1] else ("height" if _rect.x / c[0] > _rect.y / c[1] else "square-fit")
		_ok(is_equal_approx(p.get_reference_cell_size(), ref) and is_equal_approx(got, want),
			"%dx%d: cell %.0f px, ref32 %.0f px, compensation %.4f, local span %.4f cells (= 2.4*ref/cell %.4f; naive 2.4*N/32 %.3f) [%s-limited]" % [
				c[0], c[1], cs, ref, p.get_scrubbot_size_compensation(), got, want, 2.4 * maxf(c[0], c[1]) / 32.0, limit])
		rows.append({"board": "%dx%d" % c, "available_rect": [_rect.x, _rect.y], "cell_px": cs, "reference_32_cell_px": ref,
			"compensation": p.get_scrubbot_size_compensation(), "local_body_span_cells": got, "naive_span_cells": 2.4 * maxf(c[0], c[1]) / 32.0,
			"limited_by": limit, "synthetic_test_only": c[0] > 59 or c[1] > 59})
		_free(d)
	_report["s1_rows"] = rows
	# Generic sweep: many sizes x rects -> local span always equals the geometry formula, and the
	# SAME board gets DIFFERENT local spans on different rects (it cannot be a board-size table).
	var sweep := 0
	var bad := 0
	var spans20 := {}
	for rect in [_rect, Vector2(700, 900), Vector2(1400, 1000), Vector2(333, 517)]:
		for w in range(20, 60, 6):
			for h in range(20, 60, 9):
				var b2 = _board(w, h)
				var p2 = BoardPresentation.new()
				get_root().add_child(p2)
				p2.configure(b2, PackedStringArray(HEX), rect)
				var ref2: float = maxf(floor(minf(rect.x / 32.0, rect.y / 32.0)), 1.0)
				var cs2: float = maxf(floor(minf(rect.x / w, rect.y / h)), 1.0)
				sweep += 1
				if not is_equal_approx(p2.get_scrubbot_size_compensation(), ref2 / cs2) or not is_equal_approx(p2.get_cell_size(), cs2):
					bad += 1
				if w == 20 and h == 20:
					spans20[str(rect)] = REF_SPAN * p2.get_scrubbot_size_compensation()
				p2.free()
	var distinct := {}
	for k in spans20:
		distinct[snappedf(spans20[k], 0.0001)] = true
	_ok(bad == 0, "sweep: %d (w, h, rect) presentations, compensation == floor-ref / floor-cell every time (%d mismatches)" % [sweep, bad])
	_ok(distinct.size() >= 2, "20x20 local span depends on presentation geometry, not a size table: %s" % str(spans20))
	_report["s1_sweep"] = {"presentations": sweep, "mismatches": bad, "span_20x20_by_rect": spans20}

func _s2_reference_lock() -> void:
	print("[s2 32x32 reference lock]")
	for rect in [_rect, Vector2(1000, 1000), Vector2(640, 900)]:
		var d := _presentation(_board(32, 32), rect)
		var p = d["p"]
		_ok(p.get_scrubbot_size_compensation() == 1.0 and d["v"].get_local_body_span_cells() == REF_SPAN
			and is_equal_approx(_displayed_span(d["v"]), REF_SPAN * p.get_cell_size()),
			"rect %s: 32x32 compensation exactly 1.0, local span exactly 2.4 cells, displayed %.2f px = 2.4 x %.0f px cell" % [str(rect), _displayed_span(d["v"]), p.get_cell_size()])
		_free(d)
	_ok(ScrubbotVisual.BODY_SPAN_CELLS == 2.4 and RetireEcho.ECHO_SPAN_CELLS == 2.1, "owner reference constants unchanged (2.4 body / 2.1 echo)")

func _s3_apparent_size() -> void:
	print("[s3 measured apparent size vs 32x32 reference]")
	var ref_d := _presentation(_board(32, 32), _rect)
	var ref_px: float = _displayed_span(ref_d["v"])
	_free(ref_d)
	var rows: Array = []
	for c in _cases():
		var d := _presentation(_board(c[0], c[1]), _rect)
		var px: float = _displayed_span(d["v"])
		var delta: float = (px - ref_px) / ref_px * 100.0
		var old_px: float = REF_SPAN * d["p"].get_cell_size()   # pre-C002 constant 2.4-cell look
		_ok(absf(delta) <= 3.0, "%dx%d: displayed body %.2f px vs 32x32 %.2f px (delta %+.3f%%; pre-C002 would be %.1f px, %+.1f%%)" % [
			c[0], c[1], px, ref_px, delta, old_px, (old_px - ref_px) / ref_px * 100.0])
		rows.append({"board": "%dx%d" % c, "displayed_body_px": px, "reference_px": ref_px, "delta_pct": delta,
			"pre_c002_px": old_px, "pre_c002_delta_pct": (old_px - ref_px) / ref_px * 100.0})
		_free(d)
	_report["s3_rows"] = rows

# --------------------------------------------------------- s0 real screen ------
func _host_cases() -> Array:
	return [["32x32 production L2 apple (REFERENCE)", "res://data/levels/level_002_apple.json"],
		["20x20 production L1 hazard bot", "res://data/levels/m21_level_001_hazard_bot.json"],
		["38x38 production L3 palm tree", "res://data/levels/level_003_palm_tree.json"],
		["59x59 TEST stripe", _level_json(59, 59, "m32c002_59")],
		["59x40 TEST rect (width-limited)", _level_json(59, 40, "m32c002_59x40")],
		["24x40 TEST rect (height-limited)", _level_json(24, 40, "m32c002_24x40")],
		["100x100 TEST synthetic (not production; screen-only)", "SYNTH100"]]

## Displayed px expected from the presentation seam: 2.4 x reference display cell x the
## presentation parent's global scale (the screen's own shell transform, same for every board).
func _expected_px(pres, span: float = REF_SPAN) -> float:
	return span * pres.get_reference_cell_size() * pres.get_parent().get_global_transform().x.length()

func _s0_real_screen() -> void:
	print("[s0 real production GameplayScreen @1080x2160]")
	var rows: Array = []
	var ref_px := -1.0
	for c in _host_cases():
		var synth: bool = c[1] is String and c[1] == "SYNTH100"
		var h = await _host("res://data/levels/level_002_apple.json" if synth else c[1], Vector2i(1080, 2160))
		if not h.has_meta("built"):
			_ok(false, "%s: host build" % c[0])
			h.get_meta("sub").free()
			continue
		var b = h.get_board()
		if synth:
			# 100x100 is outside the production envelope (the dispatcher refuses it, and it is NOT
			# expanded here). Test-only: re-configure the SAME real GameplayScreen with a detached
			# synthetic 100x100 BoardState — presentation only, the runtime is never ticked.
			b = _board(100, 100, "m32c002_synth100")
			h.get_screen().configure(b, PackedStringArray(HEX), h.get_slots().snapshot(), h.get_supply().player_snapshot())
			await _settle(h)
		var pres = h.get_screen().get_presentation()
		var a = ScrubbotAgent.new()
		var v = ScrubbotVisual.new()
		a.add_child(v)
		pres.get_agent_layer().add_child(a)
		a.position = Vector2(b.get_width() * 0.5, b.get_height() * 0.5)
		v.set_process(false)
		var px: float = _displayed_span(v)
		if ref_px < 0.0:
			ref_px = px
		var pscale: float = pres.scale.x
		var display_cell: float = pres.get_cell_size() * pscale
		var parent_k: float = pres.get_parent().get_global_transform().x.length()
		var old_px: float = REF_SPAN * display_cell * parent_k
		var delta: float = (px - ref_px) / ref_px * 100.0
		_ok(absf(delta) <= 3.0 and is_equal_approx(px, _expected_px(pres)),
			"%s %dx%d: renderer cell %.0f x scale %.4f = display cell %.3f; ref32 display cell %.3f; compensation %.4f; local span %.4f cells; body %.2f px vs ref %.2f (delta %+.3f%%; pre-C002 %.1f px, %+.1f%%)" % [
				c[0], b.get_width(), b.get_height(), pres.get_cell_size(), pscale, display_cell, pres.get_reference_cell_size(),
				pres.get_scrubbot_size_compensation(), v.get_local_body_span_cells(), px, ref_px, delta, old_px, (old_px - ref_px) / ref_px * 100.0])
		rows.append({"case": c[0], "board": [b.get_width(), b.get_height()], "viewport": [1080, 2160],
			"renderer_cell_px": pres.get_cell_size(), "presentation_scale": pscale, "display_cell_px": display_cell,
			"reference_32_display_cell_px": pres.get_reference_cell_size(), "compensation": pres.get_scrubbot_size_compensation(),
			"local_body_span_cells": v.get_local_body_span_cells(), "shell_scale": parent_k, "displayed_body_px": px,
			"reference_body_px": ref_px, "delta_pct": delta, "pre_c002_body_px": old_px,
			"echo_span_px": _expected_px(pres, ECHO_REF_SPAN)})
		h.get_meta("sub").free()
	_report["s0_real_screen_1080x2160"] = rows

# ------------------------------------------------------------ s4 live relayout --
func _s4_live_relayout() -> void:
	print("[s4 live relayout on a real laid-out production host]")
	var h = await _host("res://data/levels/level_003_palm_tree.json", Vector2i(1080, 2160))
	var sub: SubViewport = h.get_meta("sub")
	var rt = h.get_runtime()
	var agent = null
	for _i in range(600):
		if h.get_slots().rightmost_empty_index() != -1 and not h.get_supply().is_exhausted():
			if h.get_input_controller().activate_front(0).get("ok", false):
				continue
		rt.tick(1.0 / 60.0)
		for a in h.get_screen().get_presentation().get_agent_layer().get_children():
			if a is ScrubbotAgent and a.is_moving() and a.get_progress() > 0.05 and a.get_progress() < 0.4:
				agent = a
				break
		if agent != null:
			break
	_ok(agent != null, "a live Scrubbot is moving on the 38x38 host")
	if agent == null:
		h.get_meta("sub").free()
		return
	var v = null
	for ch in agent.get_children():
		if ch is ScrubbotVisual:
			v = ch
	var pres = h.get_screen().get_presentation()
	var id_before: int = agent.get_instance_id()
	var route_before: PackedVector2Array = agent.get_route_points()
	var prog_before: float = agent.get_progress()
	var pos_before: Vector2 = agent.position
	var tex_before = v.get_body_texture()
	var gen_before: int = pres.get_presentation_generation()
	var px_before: float = _displayed_span(v)
	var exp_before: float = _expected_px(pres)
	var ref_before: float = pres.get_reference_cell_size()
	var cell_before: float = pres.get_cell_size()
	var rect_before: Vector2 = pres.get_available_size()
	var span_before: float = v.get_local_body_span_cells()
	# Responsive relayout: resize the real viewport (tablet) and relayout; the gameplay runtime is
	# not ticked meanwhile, so any truth change would come from relayout itself.
	sub.size = Vector2i(1536, 2048)
	await _settle(h)
	await process_frame   # the visual's own _process sees the generation bump
	_ok(v.get_size_compensation() == pres.get_scrubbot_size_compensation(), "live visual picked up the new compensation through its own frame update (%.4f)" % v.get_size_compensation())
	var px_after: float = _displayed_span(v)
	var exp_after: float = _expected_px(pres)
	var ref_after: float = pres.get_reference_cell_size()
	var rows := {"before": {"viewport": [1080, 2160], "rect": [rect_before.x, rect_before.y], "cell_px": cell_before, "ref32_px": ref_before,
		"local_span_cells": span_before, "displayed_px": px_before}}
	rows["after"] = {"viewport": [1536, 2048], "rect": [pres.get_available_size().x, pres.get_available_size().y], "cell_px": pres.get_cell_size(),
		"ref32_px": ref_after, "local_span_cells": v.get_local_body_span_cells(), "displayed_px": px_after}
	_ok(pres.get_presentation_generation() > gen_before and ref_after != ref_before,
		"relayout bumped presentation generation (%d -> %d) and reference cell (%.0f -> %.0f px)" % [gen_before, pres.get_presentation_generation(), ref_before, ref_after])
	_ok(is_instance_valid(agent) and agent.get_instance_id() == id_before and agent.get_parent() == pres.get_agent_layer(), "same agent instance survives relayout (no recreation)")
	_ok(agent.get_route_points() == route_before and agent.get_progress() == prog_before and agent.position == pos_before and agent.is_moving(),
		"route (%d pts), progress %.4f and board-local position %s unchanged by relayout" % [route_before.size(), prog_before, str(pos_before)])
	_ok(is_equal_approx(px_after, exp_after) and is_equal_approx(px_before, exp_before) and not is_equal_approx(px_before, px_after),
		"body re-sized live: %.2f px (ref32 display cell %.3f) -> %.2f px (ref32 display cell %.3f), local span %.4f -> %.4f cells" % [px_before, ref_before, px_after, ref_after, span_before, v.get_local_body_span_cells()])
	_ok(v.get_body_texture() == tex_before and v.get_body_texture() == ScrubbotVisual._shared_texture_for_echo(), "no texture reload (same shared texture object)")
	# Continue movement to arrival.
	var arrived := false
	for _i in range(1200):
		rt.tick(1.0 / 60.0)
		if not is_instance_valid(agent) or agent.has_arrived():
			arrived = true
			break
	_ok(arrived, "the same agent continues after relayout and arrives")
	rows["before"]["displayed_px"] = px_before
	rows["after"]["displayed_px"] = px_after
	_report["s4"] = rows
	h.get_meta("sub").free()

# -------------------------------------------------------- s5 differential ------
func _s5_differential() -> void:
	print("[s5 presentation-only differential]")
	var b = _board(59, 59, "m32c002_s5")
	for x in range(59):
		b.set_cell_state(58 * 59 + x, BoardState.CellState.CLEARED)
		b.set_cell_state(57 * 59 + x, BoardState.CellState.CLEARED)
	var target: int = 56 * 59 + 30
	var routing = ProductionRoutingSystem.new()
	var req = RouteRequest.for_target(b, Vector2(12.3, 72.78), target)
	var route = routing.compute_route(req, b, ProductionAccessQuery.new(b))
	_ok(route.success, "59x59 route available (%d points)" % route.point_count())
	var d := _presentation(b, _rect)
	var a1 = d["a"]
	d["v"].set_process(true)
	var bare_parent := Node2D.new()
	get_root().add_child(bare_parent)
	var a2 = ScrubbotAgent.new()
	bare_parent.add_child(a2)
	var done := [0, 0]
	a1.agent_completed.connect(func(_o, _t, _c): done[0] += 1)
	a2.agent_completed.connect(func(_o, _t, _c): done[1] += 1)
	_ok(a1.assign(1, 0, req, route, 18.0) and a2.assign(1, 0, req, route, 18.0), "same assignment (18 cells/s 2x tempo) on both agents")
	a1.set_process(false)
	a2.set_process(false)
	var same := true
	var steps := 0
	var rects := [_rect, Vector2(1536, 1300), Vector2(700, 900)]
	while steps < 2000 and not (a1.has_arrived() and a2.has_arrived()):
		steps += 1
		if steps % 40 == 0:
			d["p"].configure(b, PackedStringArray(HEX), rects[(steps / 40) % rects.size()])   # live relayouts
		d["v"].animate(1.0 / 60.0)
		a1.advance(1.0 / 60.0)
		a2.advance(1.0 / 60.0)
		same = same and a1.position == a2.position and a1.get_progress() == a2.get_progress() and a1.get_state() == a2.get_state()
	_ok(same and a1.has_arrived() and a2.has_arrived(), "%d frames with %d live relayouts: compensated-visual agent == bare agent (position/progress/state bit-identical)" % [steps, steps / 40])
	_ok(done == [1, 1] and a1.position == a2.position and a1.position == req.target_position, "completion count 1/1, identical exact endpoint %s" % str(a1.position))
	_report["s5"] = {"frames": steps, "relayouts": steps / 40, "identical": same, "completions": done}
	bare_parent.free()
	_free(d)

# ----------------------------------------------------------------- s6 echo -----
func _s6_echo() -> void:
	print("[s6 retire echo consistency]")
	var rows: Array = []
	var ref_echo := -1.0
	for c in [[32, 32], [20, 20], [38, 38], [59, 59], [59, 24], [100, 100]]:
		var b = _board(c[0], c[1])
		var d := _presentation(b, _rect)
		var fx = RetireEcho.new()
		get_root().add_child(fx)
		fx.set_process(false)
		fx.bind(d["p"].get_retire_fx_layer(), b)
		var idx: int = (c[1] / 3) * c[0] + c[0] / 4
		_ok(fx.request_echo(idx), "%dx%d echo spawned" % c)
		var e: Sprite2D = fx._active[0]["node"]
		var tex: Vector2 = e.texture.get_size()
		var gt: Transform2D = e.get_global_transform()
		var echo_px: float = maxf(tex.x * gt.x.length(), tex.y * gt.y.length())
		var live_px: float = _displayed_span(d["v"])
		if ref_echo < 0.0:
			ref_echo = echo_px
		var pos: Vector2i = b.get_cell_position(idx)
		_ok(absf(echo_px / live_px - ECHO_REF_SPAN / REF_SPAN) < 1e-4 and absf(echo_px - ref_echo) / ref_echo <= 0.03
			and e.position == Vector2(pos.x + 0.5, pos.y + 0.5) and e.texture == ScrubbotVisual._shared_texture_for_echo(),
			"%dx%d: echo %.2f px (32x32 %.2f), live %.2f px, ratio %.4f (2.1/2.4 = %.4f), at exact cell centre" % [c[0], c[1], echo_px, ref_echo, live_px, echo_px / live_px, ECHO_REF_SPAN / REF_SPAN])
		# Aging: shrink/fade unchanged; a mid-echo relayout rescales with the same seam.
		var base: Vector2 = fx._active[0]["base"]
		fx.age(RetireEcho.LIFETIME * 0.5)
		_ok(e.scale.is_equal_approx(base * (1.0 - RetireEcho.SHRINK * 0.5)) and is_equal_approx(e.modulate.a, 0.5), "%dx%d half-life: shrink %.2f and fade 0.5 unchanged" % [c[0], c[1], 1.0 - RetireEcho.SHRINK * 0.5])
		d["p"].configure(b, PackedStringArray(HEX), Vector2(700, 900))
		fx.age(0.0)
		var gt2: Transform2D = e.get_global_transform()
		var echo_px2: float = maxf(tex.x * gt2.x.length(), tex.y * gt2.y.length()) / (1.0 - RetireEcho.SHRINK * 0.5)
		var ref2: float = maxf(floor(minf(700.0 / 32.0, 900.0 / 32.0)), 1.0)
		_ok(is_equal_approx(echo_px2, ECHO_REF_SPAN * ref2), "%dx%d: mid-echo relayout -> echo %.2f px = 2.1 x new ref %.0f px" % [c[0], c[1], echo_px2, ref2])
		fx.age(RetireEcho.LIFETIME)
		_ok(fx.get_active_count() == 0, "%dx%d echo expires on the unchanged lifetime" % c)
		rows.append({"board": "%dx%d" % c, "echo_px": echo_px, "live_px": live_px, "ratio": echo_px / live_px, "compensation": fx.get_size_compensation()})
		fx.free()
		_free(d)
	# Cap unchanged.
	var b2 = _board(59, 59)
	var d2 := _presentation(b2, _rect)
	var fx2 = RetireEcho.new()
	get_root().add_child(fx2)
	fx2.set_process(false)
	fx2.bind(d2["p"].get_retire_fx_layer(), b2)
	for i in range(20):
		fx2.request_echo(i)
	_ok(fx2.get_active_count() == 16 and fx2.get_suppressed_count() == 4 and RetireEcho.MAX_ACTIVE_ECHOES == 16 and RetireEcho.LIFETIME == 0.28 and RetireEcho.SHRINK == 0.5,
		"cap 16 / lifetime 0.28 s / shrink 0.5 unchanged (20 requests -> 16 active, 4 suppressed)")
	fx2.free()
	_free(d2)
	_report["s6_rows"] = rows

# ---------------------------------------------------------- s7 performance -----
func _s7_performance() -> void:
	print("[s7 performance: 59x59, 30 live visuals]")
	var b = _board(59, 59)
	var p = BoardPresentation.new()
	get_root().add_child(p)
	p.configure(b, PackedStringArray(HEX), _rect)
	var vis: Array = []
	for i in range(30):
		var a = ScrubbotAgent.new()
		var v = ScrubbotVisual.new()
		a.add_child(v)
		p.get_agent_layer().add_child(a)
		a.position = Vector2(2 + i, 30)
		v.set_process(false)
		vis.append(v)
	var shared := vis.all(func(v): return v.get_body_texture() == vis[0].get_body_texture())
	_ok(shared, "30 visuals share ONE texture object")
	for _i in range(60):
		for v in vis:
			v.animate(1.0 / 60.0)
	var obj0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var t0 := Time.get_ticks_usec()
	for _i in range(600):
		for v in vis:
			v.animate(1.0 / 60.0)
	var steady_us: float = float(Time.get_ticks_usec() - t0) / 600.0
	var obj1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	_ok(obj1 == obj0, "600 frames x 30 visuals: object count stable (%d -> %d), no per-frame allocation of nodes/resources" % [obj0, obj1])
	var worst_relayout_us := 0.0
	var rects := [Vector2(700, 900), Vector2(1400, 1000), _rect]
	for r in rects:
		p.configure(b, PackedStringArray(HEX), r)
		var t1 := Time.get_ticks_usec()
		for v in vis:
			v.animate(1.0 / 60.0)   # first frame after relayout: 30 O(1) recomputes
		worst_relayout_us = maxf(worst_relayout_us, float(Time.get_ticks_usec() - t1))
	var ref: float = maxf(floor(minf(_rect.x / 32.0, _rect.y / 32.0)), 1.0)
	var all_ok := vis.all(func(v): return is_equal_approx(v.get_local_body_span_cells(), REF_SPAN * ref / p.get_cell_size()))
	_ok(all_ok, "after 3 relayouts every live visual carries the current compensation")
	_ok(steady_us < 2000.0 and worst_relayout_us < 2000.0, "steady animate %.1f us/frame for 30 visuals; first frame after relayout %.1f us (bounded)" % [steady_us, worst_relayout_us])
	_report["s7"] = {"visuals": 30, "steady_us_per_frame": steady_us, "worst_post_relayout_frame_us": worst_relayout_us, "object_count": [obj0, obj1]}
	p.free()

# ------------------------------------------------------------- host helpers ----
func _level_json(w: int, hh: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(hh):
		for x in range(w):
			cells.append(x * 6 / w)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": hh, "palette": HEX, "cells": cells}

func _host(lvl, vp: Vector2i):
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	var path: String = ""
	if lvl is String:
		path = lvl
	else:
		path = "user://m32c002_%d.json" % Time.get_ticks_usec()
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(lvl))
		f.close()
		_tmp.append(path)
	h.level_path = path
	var sub := SubViewport.new()
	sub.size = vp
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	h.set_meta("sub", sub)
	await process_frame
	await process_frame
	var built: bool = h.build()
	_ok(built, "host builds %s %s" % [path.get_file(), h.get_build_error()])
	if not built:
		return h
	h.set_meta("built", true)
	await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame
