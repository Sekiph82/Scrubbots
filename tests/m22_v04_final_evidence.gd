extends SceneTree
## M22-C001 V04 — final validation-only evidence (closes the four frozen V03
## direct-evidence residuals). PRODUCTION-IMMUTABLE: this script reads/exercises the
## accepted V03 production behavior and persists direct runtime evidence; it changes
## no production source or scene.
##
## Residuals closed:
##  - F-M22-V03-EVIDENCE-001: persist all five real post-layout global SlotCell
##    anchors AND their independently mapped board-local starts.
##  - F-M22-V03-EVIDENCE-002: prove the all-aligned-blocked target produces NO side
##    effect through the REAL selection/dispatch/clearing authority chain
##    (no agent, no reservation, no dispatcher assignment, board unchanged, no
##    silent substitution).
##  - F-M22-V03-EVIDENCE-003: (satisfied by CLAUDE_LOG_V04.md literal commands.)
##  - F-M22-V03-EVIDENCE-004: print exact runtime route point arrays.
##
## Run: godot --headless --path . -s res://tests/m22_v04_final_evidence.gd
## Exits 0 on success, 1 on any failure. If direct observation reveals a production
## mismatch, this fails (the operator then stops BLOCKED without patching production).

const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

var _fail := 0

func _initialize() -> void:
	await _section_anchors_and_c08(Vector2i(1080, 2160))
	await _section_relayout(Vector2i(1290, 2796))
	await _section_all_blocked_lifecycle()
	_section_route_arrays()
	_done()

# --------------------------------------------------------------- helpers --

func _all_active_board(w: int, h: int, fill: int, palette_size: int):
	var cells: Array = []
	cells.resize(w * h)
	for i in range(w * h):
		cells[i] = fill
	var pal := PackedStringArray()
	for i in range(palette_size):
		pal.append("#%02x0000" % (16 + i))
	var level := LevelData.new(1, "v04", "v04", "TEST", w, h, pal, PackedInt32Array(cells))
	return BoardState.from_level_data(level)

func _rail(board, start: Vector2, idx: int) -> RefCounted:
	var routing = ProductionRoutingSystem.new()
	var access = ProductionAccessQuery.new(board)
	return routing.compute_route(RouteRequest.for_target(board, start, idx), board, access)

func _rail_seg_side(a: Vector2, b: Vector2, geom) -> int:
	var e := 0.001
	if absf(a.y - geom.bottom_y()) < e and absf(b.y - geom.bottom_y()) < e: return 0
	if absf(a.x - geom.left_x()) < e and absf(b.x - geom.left_x()) < e: return 1
	if absf(a.x - geom.right_x()) < e and absf(b.x - geom.right_x()) < e: return 2
	if absf(a.y - geom.top_y()) < e and absf(b.y - geom.top_y()) < e: return 3
	return -1

func _rail_is_corner(p: Vector2, geom) -> bool:
	for c in geom.corners():
		if p.distance_to(c) < 0.001: return true
	return false

## connector + canonical-centreline rail + one orthogonal aligned approach.
func _assert_rail_domain(pts: PackedVector2Array, geom, label: String) -> void:
	var n := pts.size()
	if n < 3:
		_ok(false, "%s: >=3 points" % label); return
	_ok(absf(pts[1].y - geom.bottom_y()) < 0.001, "%s: connector enters BOTTOM rail first" % label)
	var prev_side := -1
	var all_on := true
	var corners_ok := true
	for i in range(1, n - 2):
		var side := _rail_seg_side(pts[i], pts[i + 1], geom)
		if side == -1: all_on = false
		if prev_side != -1 and side != -1 and side != prev_side and not _rail_is_corner(pts[i], geom):
			corners_ok = false
		prev_side = side
	_ok(all_on, "%s: every rail-travel segment lies on a canonical centreline" % label)
	_ok(corners_ok, "%s: rail side changes only at exact corners" % label)
	var fa: Vector2 = pts[n - 1] - pts[n - 2]
	_ok(absf(fa.x) < 0.001 or absf(fa.y) < 0.001, "%s: final approach strictly orthogonal" % label)

func _agent_children(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _board_state_snapshot(board) -> PackedInt32Array:
	var snap := PackedInt32Array()
	for i in range(board.get_cell_count()):
		snap.append(board.get_cell_state(i))
	return snap

# ---------------------------------------- B/C: anchors + real C08 transaction --

func _mapped_anchor(inst, sid: int) -> Vector2:
	return inst.get_presentation().global_to_board_local(inst.get_panel().get_cell(sid).get_spawn_anchor_global())

func _section_anchors_and_c08(size: Vector2i) -> void:
	var sub := SubViewport.new(); sub.size = size; sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var inst = load("res://scenes/demo/m22_slot_demo.tscn").instantiate()
	sub.add_child(inst)
	if inst._board == null: inst.build()
	await process_frame
	await process_frame
	await process_frame

	var panel = inst.get_panel()
	_ok(panel.get_slot_cells().size() == 5, "B %s: exactly five SlotCell/Button after layout" % str(size))
	var geom = ScrubRailGeometry.new(inst._board.get_width(), inst._board.get_height())
	var mapped: Array = []
	print("V04_ANCHORS viewport=%s" % str(size))
	for sid in range(5):
		var g: Vector2 = panel.get_cell(sid).get_spawn_anchor_global()
		var m: Vector2 = inst.get_presentation().global_to_board_local(g)
		mapped.append(m)
		print("  SLOT %d global_anchor=%s mapped_start=%s" % [sid, str(g), str(m)])
	var distinct := true
	for i in range(5):
		for j in range(i + 1, 5):
			if mapped[i].distance_to(mapped[j]) < 0.001: distinct = false
	_ok(distinct, "B: five mapped starts distinct + one-to-one with slot ids")

	# Real C08 transaction on a fresh scene.
	inst.reset_presentation()
	var pre_active: int = inst._dispatcher.get_active_count()
	inst._last_result = null
	panel.get_cell(2).pressed.emit()
	var r2 = inst._last_result
	_ok(r2 != null and r2.success, "C: real C08 Button dispatches")
	if r2 != null and r2.success:
		_ok(r2.target_index == 380 and inst._board.get_cell_position(380) == Vector2i(0, 19), "C: C08 naturally selects 380/(0,19)")
		var pts: PackedVector2Array = r2.agent.get_route_points()
		print("V04_C08 global_anchor=%s mapped_start=%s route=%s" % [str(panel.get_cell(2).get_spawn_anchor_global()), str(mapped[2]), str(pts)])
		_ok(pts[0].distance_to(mapped[2]) < 0.001, "C: route point 0 == independently mapped slot-2 anchor")
		_ok(pts[1].distance_to(geom.bottom_entry(mapped[2].x)) < 0.001, "C: route point 1 == bottom_entry(mapped.x)")
		_ok(pts[0].distance_to(pts[1]) > 0.001, "C: connector travel is non-zero (no teleport)")
		_ok(pts[pts.size() - 1].is_equal_approx(Vector2(0.5, 19.5)), "C: final approach reaches target centre (0.5,19.5)")
		_assert_rail_domain(pts, geom, "C C08")
		# Authenticated arrival clears exactly 380; assignment cleanup observed.
		for _i in range(512):
			if not is_instance_valid(r2.agent) or not r2.agent.is_moving(): break
			r2.agent.advance(1.0)
		await process_frame
		await process_frame
		_ok(inst._board.get_cell_state(380) == BoardState.CellState.CLEARED, "C: authenticated arrival cleared exactly target 380")
		_ok(inst._dispatcher.get_active_count() == pre_active, "C: dispatcher assignment cleaned up after arrival")
		_ok(_agent_children(inst.get_agent_layer()) == 0, "C: no ScrubbotAgent remains after deferred cleanup")
	inst.free(); sub.free()

func _section_relayout(size: Vector2i) -> void:
	var sub := SubViewport.new(); sub.size = size; sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var inst = load("res://scenes/demo/m22_slot_demo.tscn").instantiate()
	sub.add_child(inst)
	if inst._board == null: inst.build()
	await process_frame
	await process_frame
	var geom = ScrubRailGeometry.new(inst._board.get_width(), inst._board.get_height())
	var g_before: Vector2 = inst.get_panel().get_cell(2).get_spawn_anchor_global()
	var m_before: Vector2 = _mapped_anchor(inst, 2)
	inst.get_panel().position += Vector2(53.0, 41.0)
	await process_frame
	await process_frame
	var g_after: Vector2 = inst.get_panel().get_cell(2).get_spawn_anchor_global()
	var m_after: Vector2 = _mapped_anchor(inst, 2)
	_ok(g_after.distance_to(g_before) > 0.001, "D-relayout %s: moved panel changes measured global anchor" % str(size))
	inst.reset_presentation(); inst._last_result = null
	inst.get_panel().get_cell(2).pressed.emit()
	var r2 = inst._last_result
	_ok(r2 != null and r2.success, "D-relayout: C08 dispatches after relayout")
	if r2 != null and r2.success:
		var pts: PackedVector2Array = r2.agent.get_route_points()
		print("V04_RELAYOUT viewport=%s global_before=%s global_after=%s mapped_after=%s route0=%s" % [str(size), str(g_before), str(g_after), str(m_after), str(pts[0])])
		_ok(pts[0].distance_to(m_after) < 0.001, "D-relayout: route point 0 tracks NEW mapped anchor")
		_ok(pts[0].distance_to(m_before) > 0.001, "D-relayout: route point 0 is not the stale prior anchor")
		_ok(r2.target_index == 380, "D-relayout: C08 still naturally selects 380")
	inst.free(); sub.free()

# --------------------------- D: all-aligned-blocked full-lifecycle (real chain) --

func _section_all_blocked_lifecycle() -> void:
	# Board: every cell color 1 ACTIVE except an ISOLATED color-0 target at (10,10),
	# so slot 0 (color 0) has exactly one candidate whose four aligned rail approaches
	# are all blocked by non-target ACTIVE cells -> not targetable.
	var w := 20; var h := 20
	var board = _all_active_board(w, h, 1, 5)
	var tgt: int = board.get_cell_index(10, 10)
	board.set_cell_state(tgt, BoardState.CellState.ACTIVE)
	# recolor (10,10) to color 0 via a fresh LevelData rebuild (isolated same-color).
	var cells: Array = []
	cells.resize(w * h)
	for i in range(w * h): cells[i] = 1
	cells[tgt] = 0
	var pal := PackedStringArray(["#E5484D", "#3B82F6", "#22C55E", "#F5C518", "#A855F7"])
	var level := LevelData.new(1, "v04blk", "v04blk", "TEST", w, h, pal, PackedInt32Array(cells))
	board = BoardState.from_level_data(level)
	tgt = board.get_cell_index(10, 10)

	# Real production authority chain.
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var agent_layer := Node2D.new(); get_root().add_child(agent_layer)
	var dispatcher = ScrubbotDispatcher.new(); get_root().add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access, agent_layer)
	var slots = SlotSystem.new(); slots.configure([0, 1, 2, 3, 4], pal.size())
	var loop = CompleteClearingLoop.new()
	loop.bind(board, slots, candidates, reservations, dispatcher, null)

	# Pre-activation snapshot + target legality.
	_ok(board.get_color_id(tgt) == 0, "D-blocked: target (10,10) is color 0 (slot 0 match)")
	_ok(board.get_cell_state(tgt) == BoardState.CellState.ACTIVE, "D-blocked: target ACTIVE before activation")
	_ok(not reservations.is_reserved(tgt), "D-blocked: target unreserved before activation")
	var direct = _rail(board, Vector2(10.0, float(h) + 1.0), tgt)
	_ok(not direct.success and direct.failure_reason == RouteResult.FailureReason.NO_ROUTE, "D-blocked: target not targetable (all aligned approaches blocked, NO_ROUTE)")
	var snap_before := _board_state_snapshot(board)
	var res_before := reservations.get_reservation_count()
	var disp_before := dispatcher.get_active_count()
	var active_before = board.count_cells_by_state(BoardState.CellState.ACTIVE)

	# Activate slot 0 through the REAL loop from a below-board start.
	var r = loop.activate_slot(0, Vector2(10.0, float(h) + 1.0), 6.0)
	await process_frame
	await process_frame

	_ok(r != null and not r.success, "D-blocked: activation fails cleanly (no successful assignment)")
	_ok(reservations.get_reservation_count() == res_before and res_before == 0, "D-blocked: ReservationState count unchanged (0)")
	_ok(not reservations.is_reserved(tgt) and reservations.get_owner(tgt) == -1, "D-blocked: no target->owner reservation mapping appears")
	_ok(dispatcher.get_active_count() == disp_before and disp_before == 0, "D-blocked: dispatcher active-assignment count unchanged (0)")
	_ok(_board_state_snapshot(board) == snap_before, "D-blocked: BoardState identical before/after (no cell cleared)")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == active_before, "D-blocked: no target substituted/cleared (ACTIVE count unchanged)")
	_ok(board.get_cell_state(tgt) == BoardState.CellState.ACTIVE, "D-blocked: the blocked target itself remains ACTIVE")
	_ok(_agent_children(agent_layer) == 0, "D-blocked: no ScrubbotAgent spawned (AgentLayer empty after cleanup)")
	print("V04_ALLBLOCKED target_idx=%d coord=(10,10) color=0 result_success=%s reason=%s res_count=%d disp_active=%d active_cells_before=%d after=%d" % [
		tgt, str(r.success if r != null else false), str(r.failure_reason if r != null else "null"),
		reservations.get_reservation_count(), dispatcher.get_active_count(), active_before, board.count_cells_by_state(BoardState.CellState.ACTIVE)])

	dispatcher.free(); agent_layer.free()

# ----------------------------------------- E: exact runtime route point arrays --

func _section_route_arrays() -> void:
	var geom20 = ScrubRailGeometry.new(20, 20)
	var b = _all_active_board(20, 20, 0, 1)
	var start := Vector2(10.0, 21.0)

	# far-left/bottom
	var far_bl = _rail(b, start, b.get_cell_index(0, 19))
	print("V04_ROUTE far_left_bottom board=20x20 start=%s target=380/(0,19) exit=BOTTOM points=%s" % [str(start), str(far_bl.get_points())])
	if far_bl.success: _assert_rail_domain(far_bl.get_points(), geom20, "E far-left-bottom")

	# true far-right/top
	var far_tr = _rail(b, start, b.get_cell_index(19, 0))
	print("V04_ROUTE far_right_top board=20x20 start=%s target=(19,0) points=%s" % [str(start), str(far_tr.get_points())])
	if far_tr.success:
		var e2: Vector2 = far_tr.get_points()[far_tr.get_points().size() - 2]
		var exit_side := "RIGHT" if absf(e2.x - geom20.right_x()) < 0.001 else ("TOP" if absf(e2.y - geom20.top_y()) < 0.001 else "?")
		print("V04_ROUTE far_right_top chosen_exit=%s" % exit_side)
		_assert_rail_domain(far_tr.get_points(), geom20, "E far-right-top")

	# two-side blocked-preferred-exit fallback (left-edge interior target (0,5))
	var two_side = _rail(b, start, b.get_cell_index(0, 5))
	print("V04_ROUTE two_side_fallback board=20x20 start=%s target=(0,5) same_target_retained=%s points=%s" % [str(start), str(two_side.target_index == b.get_cell_index(0, 5)), str(two_side.get_points())])
	if two_side.success: _assert_rail_domain(two_side.get_points(), geom20, "E two-side")

	# shortest-legal-route (right-side start, both BOTTOM+LEFT legal, BOTTOM shorter)
	var shortest = _rail(b, Vector2(18.0, 21.0), b.get_cell_index(0, 19))
	var sp = shortest.get_points()
	var s_exit := "BOTTOM" if absf(sp[sp.size() - 2].y - geom20.bottom_y()) < 0.001 else "OTHER"
	print("V04_ROUTE shortest board=20x20 start=(18,21) target=380/(0,19) chosen_exit=%s points=%s" % [s_exit, str(sp)])

	# equal-distance tie-break on 21x21 (col 10 centre == loop midpoint) -> LEFT
	var tw := 21; var th := 21
	var bt = _all_active_board(tw, th, 0, 1)
	for x in range(tw):
		if x != 10: bt.set_cell_state(bt.get_cell_index(x, 10), BoardState.CellState.CLEARED)
	var tie = _rail(bt, Vector2(10.5, float(th) + 1.0), bt.get_cell_index(10, 10))
	var tp = tie.get_points()
	var geomTie = ScrubRailGeometry.new(tw, th)
	var tie_left := false
	for p in tp:
		if absf(p.x - geomTie.left_x()) < 0.001: tie_left = true
	print("V04_ROUTE tiebreak board=21x21 start=(10.5,22) target=(10,10) competing=LEFT,RIGHT chosen=%s points=%s" % ["LEFT" if tie_left else "RIGHT/OTHER", str(tp)])
	_ok(tie_left, "E tie-break: equal-distance chose LEFT (BOTTOM->LEFT->RIGHT->TOP)")

	# all-aligned-blocked NO_ROUTE (enclosed color match on all-active board)
	var blk = _rail(b, start, b.get_cell_index(10, 10))
	print("V04_ROUTE all_blocked board=20x20 target_idx=%d/(10,10) success=%s reason=%s retained_target=%d" % [b.get_cell_index(10, 10), str(blk.success), str(blk.failure_reason), blk.target_index])
	_ok(not blk.success and blk.failure_reason == RouteResult.FailureReason.NO_ROUTE and blk.target_index == b.get_cell_index(10, 10), "E all-blocked: NO_ROUTE, retained target")

	# rectangular 40x24 (both in 20..59)
	var brc = _all_active_board(40, 24, 0, 1)
	var rect = _rail(brc, Vector2(20.0, 25.0), brc.get_cell_index(0, 23))
	print("V04_ROUTE rectangular board=40x24 start=(20,25) target=(0,23) points=%s" % str(rect.get_points()))
	if rect.success: _assert_rail_domain(rect.get_points(), ScrubRailGeometry.new(40, 24), "E rectangular-40x24")

	# 59x59
	var b59 = _all_active_board(59, 59, 0, 1)
	var r59 = _rail(b59, Vector2(29.0, 60.0), b59.get_cell_index(0, 58))
	print("V04_ROUTE board=59x59 start=(29,60) target=(0,58) points=%s" % str(r59.get_points()))
	if r59.success: _assert_rail_domain(r59.get_points(), ScrubRailGeometry.new(59, 59), "E 59x59")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 V04 final evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
