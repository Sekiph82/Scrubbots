extends SceneTree
## M22-C001 V05 — final validation-only direct-state evidence.
## PRODUCTION-IMMUTABLE: reads/exercises accepted V03 production behavior
## (baseline 8ded358) and persists direct ReservationState/dispatcher/route-choice
## observations. Changes no production source or scene.
##
## Closes the three frozen V04 findings:
##  - F-M22-V04-EVIDENCE-001: C08 authenticated-arrival ReservationState + dispatcher
##    cleanup, inspected directly in both directions (pre / in-flight / post).
##  - F-M22-V04-EVIDENCE-002: all-aligned-blocked reverse-map + dispatcher-map
##    absence + owner-id counter non-advance, inspected directly.
##  - F-M22-V04-EVIDENCE-003: shortest / tie-break route choice independently
##    measured from ScrubRailGeometry + ProductionAccessQuery candidate legality and
##    exact total lengths, then compared to production selection.
##
## Section A rebuilds the SAME production authority chain the M22 demo builds (same
## classes, same real level, same CompleteClearingLoop.activate_slot path a real
## SlotCell Button triggers) because production is immutable and exposes no
## ReservationState accessor; the demo Button->anchor->route path is already proven
## in V04/connector evidence.
##
## Run: godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd
## Exits 0 on success, 1 on any failure. On a production mismatch it fails (operator
## then stops BLOCKED without patching production).

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
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
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

const LEVEL_PATH = "res://data/levels/m21_level_001_hazard_bot.json"
const SIDE_NAMES = ["BOTTOM", "LEFT", "RIGHT", "TOP"]

var _fail = 0

func _initialize() -> void:
	await _section_a_c08_cleanup()
	await _section_b_all_blocked_maps()
	_section_cd_candidate_measurement()
	_section_e_fingerprint()
	_done()

# --------------------------------------------------------------- helpers --

func _all_active_board(w: int, h: int, fill: int, palette_size: int):
	var cells: Array = []
	cells.resize(w * h)
	for i in range(w * h):
		cells[i] = fill
	var pal = PackedStringArray()
	for i in range(palette_size):
		pal.append("#%02x0000" % (16 + i))
	return BoardState.from_level_data(LevelData.new(1, "v05", "v05", "TEST", w, h, pal, PackedInt32Array(cells)))

func _agent_children(layer) -> int:
	var n = 0
	for c in layer.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _state_vector(board) -> PackedInt32Array:
	var v = PackedInt32Array()
	for i in range(board.get_cell_count()):
		v.append(board.get_cell_state(i))
	return v

## Total production-equivalent polyline length for an aligned side, or -1 if the
## final approach is illegal under authoritative access truth. Mirrors production
## assembly (start -> bottom_entry -> canonical rail_path -> exit -> target) using
## ScrubRailGeometry + ProductionAccessQuery ONLY (no production policy copy).
func _side_candidate(geom, access, board, start: Vector2, idx: int, side: int) -> float:
	var tc: Vector2 = RouteRequest.center_of_index(board, idx)
	var exit_pt: Vector2 = geom.exit_point(side, tc)
	var v = access.is_segment_traversable(exit_pt, tc, idx)
	if typeof(v) != TYPE_BOOL or not v:
		return -1.0
	var entry: Vector2 = geom.bottom_entry(start.x)
	var rp: Dictionary = geom.rail_path(entry, exit_pt)
	return start.distance_to(entry) + float(rp["dist"]) + exit_pt.distance_to(tc)

func _production_exit_side(geom, route_points: PackedVector2Array) -> int:
	var e = route_points[route_points.size() - 2]
	if absf(e.y - geom.bottom_y()) < 0.001: return 0
	if absf(e.x - geom.left_x()) < 0.001: return 1
	if absf(e.x - geom.right_x()) < 0.001: return 2
	if absf(e.y - geom.top_y()) < 0.001: return 3
	return -1

# ---------------------------- A: C08 authenticated-arrival reservation cleanup --

func _build_real_chain(board) -> Dictionary:
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var agent_layer = Node2D.new(); get_root().add_child(agent_layer)
	var dispatcher = ScrubbotDispatcher.new(); get_root().add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access, agent_layer)
	return {"reservations": reservations, "candidates": candidates, "dispatcher": dispatcher, "agent_layer": agent_layer}

func _section_a_c08_cleanup() -> void:
	print("== V05 A: C08 authenticated-arrival reservation/dispatcher cleanup ==")
	var res = LevelLoader.load_from_path(LEVEL_PATH)
	if not res.is_ok():
		_ok(false, "A: real Hazard Bot level loads"); return
	var lvl = res.level_data
	var board = BoardState.from_level_data(lvl)
	var chain = _build_real_chain(board)
	var reservations = chain["reservations"]
	var dispatcher = chain["dispatcher"]
	var agent_layer = chain["agent_layer"]
	var slots = SlotSystem.new(); slots.configure([0, 1, 2, 3, 4], lvl.palette.size())
	var loop = CompleteClearingLoop.new()
	loop.bind(board, slots, chain["candidates"], reservations, dispatcher, null)

	var res_before = reservations.get_reservation_count()
	var disp_before = dispatcher.get_active_count()
	# C08 = slot 2; below-board start -> railroad; TargetSelector -> 380/(0,19).
	var r = loop.activate_slot(2, Vector2(9.222222, 24.0), 6.0)
	_ok(r != null and r.success, "A: C08 activation dispatches")
	if r == null or not r.success:
		dispatcher.free(); agent_layer.free(); return
	var owner_id: int = r.owner_id
	var tgt: int = r.target_index
	var agent = r.agent
	_ok(tgt == 380 and board.get_cell_position(380) == Vector2i(0, 19), "A: C08 naturally selects 380/(0,19)")
	# In-flight direct inspection (both directions).
	var if_get_owner = reservations.get_owner(380)
	var if_res_t4o = reservations.get_target_for_owner(owner_id)
	var if_has = dispatcher.has_owner(owner_id)
	var if_disp_t4o = dispatcher.get_target_for_owner(owner_id)
	var if_agent_match = dispatcher.get_agent_for_owner(owner_id) == agent
	print("A_INFLIGHT owner_id=%d res.get_owner(380)=%d res.get_target_for_owner=%d disp.has_owner=%s disp.get_target_for_owner=%d disp.agent_matches=%s" % [
		owner_id, if_get_owner, if_res_t4o, str(if_has), if_disp_t4o, str(if_agent_match)])
	_ok(if_get_owner == owner_id, "A: in-flight get_owner(380) == owner_id")
	_ok(if_res_t4o == 380, "A: in-flight get_target_for_owner(owner) == 380")
	_ok(if_has, "A: in-flight dispatcher has_owner")
	_ok(if_disp_t4o == 380, "A: in-flight dispatcher get_target_for_owner == 380")
	_ok(if_agent_match, "A: in-flight dispatcher get_agent_for_owner == exact agent")
	# Drive authenticated arrival.
	for _i in range(1024):
		if not is_instance_valid(agent) or not agent.is_moving(): break
		agent.advance(1.0)
	await process_frame
	await process_frame
	var post_get_owner = reservations.get_owner(380)
	var post_res_t4o = reservations.get_target_for_owner(owner_id)
	var post_count = reservations.get_reservation_count()
	var post_has = dispatcher.has_owner(owner_id)
	var post_disp_t4o = dispatcher.get_target_for_owner(owner_id)
	var post_agent = dispatcher.get_agent_for_owner(owner_id)
	var post_active = dispatcher.get_active_count()
	var cleared = board.get_cell_state(380) == BoardState.CellState.CLEARED
	print("A_POST cleared_380=%s res_count=%d/%d get_owner(380)=%d res.t4o(owner)=%d disp_active=%d/%d has_owner=%s disp.t4o=%d agent_null=%s agents=%d" % [
		str(cleared), post_count, res_before, post_get_owner, post_res_t4o, post_active, disp_before,
		str(post_has), post_disp_t4o, str(post_agent == null), _agent_children(agent_layer)])
	_ok(cleared, "A: authenticated arrival cleared exactly target 380")
	_ok(post_count == res_before, "A: reservation count returned to baseline")
	_ok(post_get_owner == -1, "A: get_owner(380) == -1 after arrival")
	_ok(post_res_t4o == -1, "A: get_target_for_owner(owner) == -1 after arrival")
	_ok(post_active == disp_before, "A: dispatcher active count returned to baseline")
	_ok(not post_has, "A: dispatcher has_owner == false after arrival")
	_ok(post_disp_t4o == -1, "A: dispatcher get_target_for_owner == -1 after arrival")
	_ok(post_agent == null, "A: dispatcher get_agent_for_owner == null after arrival")
	_ok(_agent_children(agent_layer) == 0, "A: zero ScrubbotAgent remain after deferred cleanup")
	dispatcher.free(); agent_layer.free()


# ---------------------------- B: all-aligned-blocked reverse-map / dispatcher-map --

func _section_b_all_blocked_maps() -> void:
	print("== V05 B: all-aligned-blocked reverse-map / dispatcher-map absence ==")
	var w = 20; var h = 20
	var cells: Array = []; cells.resize(w * h)
	for i in range(w * h): cells[i] = 1
	var tgt_pre = 10 * w + 10  # (10,10)
	cells[tgt_pre] = 0
	var pal = PackedStringArray(["#E5484D", "#3B82F6", "#22C55E", "#F5C518", "#A855F7"])
	var board = BoardState.from_level_data(LevelData.new(1, "v05b", "v05b", "TEST", w, h, pal, PackedInt32Array(cells)))
	var tgt = board.get_cell_index(10, 10)
	var chain = _build_real_chain(board)
	var reservations = chain["reservations"]
	var dispatcher = chain["dispatcher"]
	var agent_layer = chain["agent_layer"]
	var slots = SlotSystem.new(); slots.configure([0, 1, 2, 3, 4], pal.size())
	var loop = CompleteClearingLoop.new()
	loop.bind(board, slots, chain["candidates"], reservations, dispatcher, null)

	var pending_owner = dispatcher.peek_next_owner_id()
	var snap_before = _state_vector(board)
	var res_before = reservations.get_reservation_count()
	var disp_before = dispatcher.get_active_count()
	# Pre-activation both-direction absence.
	print("B_PRE pending_owner=%d res.get_owner(tgt)=%d res.t4o(pending)=%d disp.has(pending)=%s disp.t4o(pending)=%d res_count=%d disp_active=%d" % [
		pending_owner, reservations.get_owner(tgt), reservations.get_target_for_owner(pending_owner),
		str(dispatcher.has_owner(pending_owner)), dispatcher.get_target_for_owner(pending_owner), res_before, disp_before])
	_ok(board.get_color_id(tgt) == 0 and board.get_cell_state(tgt) == BoardState.CellState.ACTIVE, "B: isolated color-0 target ACTIVE")
	_ok(reservations.get_owner(tgt) == -1 and reservations.get_target_for_owner(pending_owner) == -1, "B: pre-activation both reservation directions absent")

	var r = loop.activate_slot(0, Vector2(10.0, float(h) + 1.0), 6.0)
	await process_frame
	await process_frame

	var pending_after = dispatcher.peek_next_owner_id()
	print("B_POST result_success=%s reason=%s res.get_owner(tgt)=%d res.t4o(pending)=%d disp.has(pending)=%s disp.t4o(pending)=%d disp.agent(pending)_null=%s res_count=%d disp_active=%d pending_after=%d agents=%d board_identical=%s target_active=%s" % [
		str(r.success if r != null else false), str(r.failure_reason if r != null else "null"),
		reservations.get_owner(tgt), reservations.get_target_for_owner(pending_owner),
		str(dispatcher.has_owner(pending_owner)), dispatcher.get_target_for_owner(pending_owner),
		str(dispatcher.get_agent_for_owner(pending_owner) == null),
		reservations.get_reservation_count(), dispatcher.get_active_count(), pending_after,
		_agent_children(agent_layer), str(_state_vector(board) == snap_before),
		str(board.get_cell_state(tgt) == BoardState.CellState.ACTIVE)])
	_ok(r != null and not r.success, "B: activation fails cleanly (no assignment/agent)")
	_ok(reservations.get_owner(tgt) == -1, "B: target->owner absent after activation")
	_ok(reservations.get_target_for_owner(pending_owner) == -1, "B: pending-owner->target absent after activation")
	_ok(not dispatcher.has_owner(pending_owner), "B: dispatcher has no pending owner")
	_ok(dispatcher.get_target_for_owner(pending_owner) == -1, "B: dispatcher pending-owner target == -1")
	_ok(dispatcher.get_agent_for_owner(pending_owner) == null, "B: dispatcher pending-owner agent == null")
	_ok(reservations.get_reservation_count() == res_before, "B: reservation count unchanged")
	_ok(dispatcher.get_active_count() == disp_before, "B: dispatcher active count unchanged")
	_ok(pending_after == pending_owner, "B: owner-id counter did not advance on NO_REACHABLE_TARGET")
	_ok(_state_vector(board) == snap_before, "B: BoardState identical; no alternate clear")
	_ok(_agent_children(agent_layer) == 0, "B: no ScrubbotAgent spawned")
	dispatcher.free(); agent_layer.free()

# ------------------------------- C/D: shortest + tie-break candidate measurement --

func _measure_and_report(board, start: Vector2, idx: int, label: String) -> void:
	var geom = ScrubRailGeometry.new(board.get_width(), board.get_height())
	var access = ProductionAccessQuery.new(board)
	var legal: Array = []  # [side, length]
	for side in [0, 1, 2, 3]:  # BOTTOM, LEFT, RIGHT, TOP
		var L = _side_candidate(geom, access, board, start, idx, side)
		var legal_str = ("len=%.4f" % L) if L >= 0.0 else "ILLEGAL"
		print("  %s candidate %s: %s" % [label, SIDE_NAMES[side], legal_str])
		if L >= 0.0:
			legal.append([side, L])
	_ok(legal.size() >= 2, "%s: at least two legal aligned candidates" % label)
	# Production choice.
	var routing = ProductionRoutingSystem.new()
	var prod = routing.compute_route(RouteRequest.for_target(board, start, idx), board, access)
	_ok(prod.success, "%s: production route succeeds" % label)
	var chosen = _production_exit_side(geom, prod.get_points())
	# Minimum by length, tie-break BOTTOM->LEFT->RIGHT->TOP (side index order).
	var min_len = INF
	for e in legal:
		if e[1] < min_len - 0.0001: min_len = e[1]
	var expected = -1
	for side in [0, 1, 2, 3]:
		for e in legal:
			if e[0] == side and e[1] <= min_len + 0.0001:
				expected = side
				break
		if expected != -1: break
	print("  %s production_chosen=%s expected(min+tiebreak)=%s route=%s" % [label, SIDE_NAMES[chosen], SIDE_NAMES[expected] if expected >= 0 else "?", str(prod.get_points())])
	_ok(chosen == expected, "%s: production selected the min-length first-priority legal side" % label)

func _section_cd_candidate_measurement() -> void:
	print("== V05 C: shortest-route candidate measurement (board=20x20, start=(18,21), target=380/(0,19)) ==")
	var b = _all_active_board(20, 20, 0, 1)
	_measure_and_report(b, Vector2(18.0, 21.0), b.get_cell_index(0, 19), "C shortest")

	print("== V05 D: equal-distance tie-break measurement (board=21x21, start=(10.5,22), target=(10,10)) ==")
	var tw = 21; var th = 21
	var bt = _all_active_board(tw, th, 0, 1)
	for x in range(tw):
		if x != 10: bt.set_cell_state(bt.get_cell_index(x, 10), BoardState.CellState.CLEARED)
	var idx = bt.get_cell_index(10, 10)
	var geom = ScrubRailGeometry.new(tw, th)
	var access = ProductionAccessQuery.new(bt)
	var start = Vector2(10.5, float(th) + 1.0)
	var lens: Dictionary = {}
	for side in [0, 1, 2, 3]:
		lens[side] = _side_candidate(geom, access, bt, start, idx, side)
	print("  D lengths BOTTOM=%s LEFT=%.4f RIGHT=%.4f TOP=%s" % [
		("ILLEGAL" if lens[0] < 0 else "%.4f" % lens[0]), lens[1], lens[2],
		("ILLEGAL" if lens[3] < 0 else "%.4f" % lens[3])])
	_ok(lens[1] >= 0.0 and lens[2] >= 0.0, "D: LEFT and RIGHT both legal")
	_ok(absf(lens[1] - lens[2]) <= 0.0001, "D: LEFT and RIGHT total lengths equal within 0.0001")
	_ok(lens[0] < 0.0 and lens[3] < 0.0, "D: higher/lower-priority BOTTOM and TOP are ILLEGAL (cannot outrank the tie)")
	_measure_and_report(bt, start, idx, "D tiebreak")

# ------------------------------------- E: direct all-blocked mutation fingerprint --

func _section_e_fingerprint() -> void:
	print("== V05 E: direct all-blocked compute_route mutation fingerprint ==")
	var b = _all_active_board(20, 20, 0, 1)
	var idx = b.get_cell_index(10, 10)
	var access = ProductionAccessQuery.new(b)
	var before = _state_vector(b)
	var fp_before = str(before).sha256_text()
	var routing = ProductionRoutingSystem.new()
	var r = routing.compute_route(RouteRequest.for_target(b, Vector2(10.0, 21.0), idx), b, access)
	var after = _state_vector(b)
	var fp_after = str(after).sha256_text()
	print("E_FINGERPRINT cells=%d fp_before=%s fp_after=%s success=%s reason=%s retained_target=%d" % [
		b.get_cell_count(), fp_before, fp_after, str(r.success), str(r.failure_reason), r.target_index])
	_ok(not r.success and r.failure_reason == RouteResult.FailureReason.NO_ROUTE, "E: direct all-blocked routing is NO_ROUTE")
	_ok(r.target_index == idx, "E: retained target index")
	_ok(fp_before == fp_after and before == after, "E: BoardState SHA-256 fingerprint identical before/after")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 V05 final state evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
