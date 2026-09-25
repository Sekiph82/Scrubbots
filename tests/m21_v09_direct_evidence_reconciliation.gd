extends SceneTree
## M21-C001 V09 — production-immutable final direct-evidence reconciliation.
##
## Closes the five frozen V08 direct-evidence gaps G-V08-01..05 on the EXACT required
## surfaces: the real owner scene + real visible SlotView Button path + real
## production collaborators, with exact-equality assertions (whole-board changed-index
## sets, candidate-set deltas, reservation/assignment lifecycle, slot active
## presentation, reset snapshots). Adds no production/scene/project change.
##
## Observation notes (no production hooks added; the accepted owner scene exposes no
## ReservationState getter):
##  - candidate sets are recomputed INDEPENDENTLY from the scene's real BoardState via
##    a fresh ColorCandidateIndex (same board -> same candidate truth);
##  - reservation/assignment lifecycle is observed via the authoritative
##    ScrubbotDispatcher owner->target map (M19 keeps it in lockstep with
##    ReservationState; that lockstep is proven exhaustively by the M15/M19/M20 strict
##    suites in the root run).
##
## Run:  godot --headless --path . -s res://tests/m21_v09_direct_evidence_reconciliation.gd
## Exits 0 on success, 1 on any failure. If accepted production is genuinely
## defective, this reports FAIL and the handoff is BLOCKED (production NOT patched).

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const SCENE := "res://scenes/debug/m21_real_art_vertical_slice.tscn"
var _fail := 0

## Recording delegate over the real, unchanged ProductionAccessQuery (domain probe).
class _RecAccess extends RefCounted:
	var inner
	var seen: Array = []
	func _init(board):
		inner = load("res://scripts/gameplay/routing/production_access_query.gd").new(board)
	func is_bound_to(board): return inner.is_bound_to(board)
	func classify_cell(cx, cy, ti):
		seen.append(Vector2i(cx, cy))
		return inner.classify_cell(cx, cy, ti)
	func cell_of_point(p): return inner.cell_of_point(p)
	func is_segment_traversable(a, b, ti): return inner.is_segment_traversable(a, b, ti)

func _initialize() -> void:
	await _gap_A_nowork()
	_gap_B_corner()
	await _gap_C_first_clear()
	await _gap_D_rapid3()
	await _gap_E_reset()
	_done()

# ---------------------------------------------------------------- helpers -----

func _fresh_scene():
	var inst = load(SCENE).instantiate()
	get_root().add_child(inst)
	if inst._board == null: inst.build()
	await process_frame
	await process_frame
	return inst

func _states(board) -> PackedByteArray:
	var out := PackedByteArray(); out.resize(board.get_cell_count())
	for i in range(board.get_cell_count()):
		out[i] = board.get_cell_state(i)
	return out

func _changed(before: PackedByteArray, after: PackedByteArray) -> Array:
	var out: Array = []
	for i in range(before.size()):
		if before[i] != after[i]: out.append(i)
	return out

## Independent C08 candidate set (indices), recomputed from the scene's real board.
func _c08(board) -> Array:
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var a: Array = ci.get_candidates(2, null)
	a.sort()
	return a

func _agents(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _drive(agent) -> void:
	for _i in range(2048):
		if not is_instance_valid(agent) or not agent.is_moving(): break
		agent.advance(1.0)

# ------------------------------------------------------------- gap A ----------

func _gap_A_nowork() -> void:
	print("-- G-V08-01: no-work real Button zero side effects --")
	var inst = await _fresh_scene()
	var board = inst._board
	# C01 (slot 0) is enclosed on the fresh board -> no reachable work.
	var st0 := _states(board)
	var c08_0 := _c08(board)
	var c01_0 = _c08_generic(board, 0)
	var da0: int = inst._dispatcher.get_active_count()
	var al0 := _agents(inst.get_agent_layer())
	inst._last_result = null
	inst.get_slot_views()[0].pressed.emit()
	var r = inst._last_result
	_ok(r != null and not r.success, "A: no-work slot Button yields a legitimate no-work result")
	_ok(_states(board) == st0, "A: BoardState state vector byte-identical after no-work click")
	_ok(_c08(board) == c08_0 and _c08_generic(board, 0) == c01_0, "A: candidate sets unchanged after no-work click")
	_ok(inst._dispatcher.get_active_count() == da0, "A: dispatcher active count unchanged (zero reservation side effect)")
	_ok(inst._dispatcher.get_active_count() == 0 and inst._assignments.is_empty(), "A: no assignment/reservation created")
	_ok(_agents(inst.get_agent_layer()) == al0, "A: no agent spawned")
	inst.free()

func _c08_generic(board, color: int) -> Array:
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var a: Array = ci.get_candidates(color, null); a.sort(); return a

# ------------------------------------------------------------- gap B ----------

func _gap_B_corner() -> void:
	print("-- G-V08-02: distinct adjacent-side corner evidence --")
	var w := 20; var h := 20
	var board = _all_active(w, h)
	# Origin BELOW mid, target TOP-mid: the interior is all ACTIVE, so reaching the
	# top-middle perimeter cell from below forces the route to round a corner and
	# traverse a full vertical side AND the top side — two distinct adjacent
	# non-corner sides. (Route VERTICES collapse collinear mid-side cells, so the
	# proof inspects the cells each segment CROSSES, not just the vertices.)
	var origin := Vector2(10.5, float(h) + 1.5)
	var target: int = board.get_cell_index(10, 0)  # top-middle perimeter
	var routing = ProductionRoutingSystem.new()
	var access = ProductionAccessQuery.new(board)
	var req = RouteRequest.for_target(board, origin, target)
	var res = routing.compute_route(req, board, access)
	_ok(res.success, "B: below-mid -> top-mid corner route succeeds")
	if res.success:
		_ok(RouteValidator.validate_route(req, res, board, access) == RouteResult.FailureReason.NONE, "B: corner route revalidates NONE")
		var pts: PackedVector2Array = res.get_points()
		var crossed := _crossed_cells(pts)
		var left_noncorner := false   # x == -1 and 0<=y<=h-1
		var right_noncorner := false  # x == w  and 0<=y<=h-1
		var top_noncorner := false    # y == -1 and 0<=x<=w-1
		for c in crossed:
			if c.x == -1 and c.y >= 0 and c.y <= h - 1: left_noncorner = true
			if c.x == w and c.y >= 0 and c.y <= h - 1: right_noncorner = true
			if c.y == -1 and c.x >= 0 and c.x <= w - 1: top_noncorner = true
		# It rounds either the left or the right corner up to the top; require the TOP
		# side plus ONE distinct adjacent vertical side (corner cells excluded).
		_ok(top_noncorner, "B: route crosses a TOP-side NON-corner ring cell (y=-1, 0<=x<=%d)" % (w - 1))
		_ok(left_noncorner or right_noncorner, "B: route crosses a distinct adjacent vertical-side NON-corner ring cell (left x=-1 or right x=%d)" % w)
		# Planner classification domain never exceeds the one-cell ring (recording delegate).
		var rec = _RecAccess.new(board)
		var rr = ProductionRoutingSystem.new().compute_route(RouteRequest.for_target(board, origin, target), board, rec)
		var within := true
		for c in rec.seen:
			if c.x < -1 or c.y < -1 or c.x > w or c.y > h: within = false
		_ok(rr.success and within, "B: planner classification stays within the one-cell ring domain")
		print("  B route vertices = %s" % str(_vertex_cells(pts)))

func _all_active(w: int, h: int):
	var pal := PackedStringArray(["#2450A4FF"])
	var arr := PackedInt32Array(); arr.resize(w * h)
	for i in range(w * h): arr[i] = 0
	return BoardState.from_level_data(LevelData.new(1, "va", "va", "TEST", w, h, pal, arr))

## Cells geometrically crossed by the polyline (dense sample). Detached set.
func _crossed_cells(pts: PackedVector2Array) -> Array:
	var seen := {}
	for i in range(pts.size() - 1):
		var a := pts[i]; var b := pts[i + 1]
		var steps := int(ceil(a.distance_to(b) * 8.0)) + 1
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var p := a.lerp(b, t)
			seen[Vector2i(int(floor(p.x)), int(floor(p.y)))] = true
	return seen.keys()

func _vertex_cells(pts: PackedVector2Array) -> Array:
	var out: Array = []
	for p in pts:
		out.append(Vector2i(int(floor(p.x)), int(floor(p.y))))
	return out

# ------------------------------------------------------------- gap C ----------

func _gap_C_first_clear() -> void:
	print("-- G-V08-03: first C08 real Button exact transaction --")
	var inst = await _fresh_scene()
	var board = inst._board
	var pres = inst.get_presentation()
	var views: Array = inst.get_slot_views()
	var st0 := _states(board)
	var c08_0 := _c08(board)
	var anchor: Vector2 = views[2].get_spawn_anchor_global()
	var mapped: Vector2 = pres.global_to_board_local(anchor)
	inst._last_result = null
	views[2].pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "C: real C08 Button dispatch succeeds")
	if r != null and r.success:
		var owner: int = r.owner_id
		var agent = r.agent
		_ok(r.target_index == 380 and board.get_cell_position(380) == Vector2i(0, 19), "C: target 380 == (0,19)")
		_ok(agent.get_route_points()[0].distance_to(mapped) < 0.001, "C: route[0] == mapped visible slot anchor")
		# In-flight authoritative owner->target assignment (reservation lockstep).
		_ok(inst._dispatcher.has_owner(owner) and inst._dispatcher.get_target_for_owner(owner) == 380, "C: in-flight dispatcher owner->target == 380")
		_drive(agent)
		await process_frame
		await process_frame
		_ok(_changed(st0, _states(board)) == [380], "C: whole-board changed-index set is EXACTLY [380]")
		var c08_1 := _c08(board)
		_ok(_minus(c08_0, c08_1) == [380] and _minus(c08_1, c08_0) == [], "C: C08 candidate set = pre minus exactly {380}")
		_ok(not inst._dispatcher.has_owner(owner) and inst._dispatcher.get_active_count() == 0, "C: assignment pair gone; dispatcher active 0 after clear")
		_ok(_agents(inst.get_agent_layer()) == 0, "C: AgentLayer 0 orphan agents after cleanup")
	inst.free()

func _minus(a: Array, b: Array) -> Array:
	var s := {}
	for x in b: s[x] = true
	var out: Array = []
	for x in a:
		if not s.has(x): out.append(x)
	return out

# ------------------------------------------------------------- gap D ----------

func _gap_D_rapid3() -> void:
	print("-- G-V08-04: rapid x3 real C08 Button + active presentation --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	var st0 := _states(board)
	var c08_0 := _c08(board)
	var results: Array = []
	for _i in range(3):
		inst._last_result = null
		views[2].pressed.emit()
		results.append(inst._last_result)
	var ok3: bool = results.size() == 3 and results[0] != null and results[0].success and results[1] != null and results[1].success and results[2] != null and results[2].success
	_ok(ok3, "D: three rapid real C08 Button presses all dispatch")
	if ok3:
		var tids := [results[0].target_index, results[1].target_index, results[2].target_index]
		_ok(tids == [380, 381, 382], "D: targets 380,381,382 in order (got %s)" % str(tids))
		var owners := {}
		var bidir := true
		for rr in results:
			owners[rr.owner_id] = true
			if inst._dispatcher.get_target_for_owner(rr.owner_id) != rr.target_index: bidir = false
		_ok(owners.size() == 3, "D: unique owner ids")
		_ok(bidir, "D: in-flight dispatcher owner->target exact for all three")
		_ok(views[2].is_active_visual(), "D: C08 SlotView active while assignments in flight")
		# finish first -> still active
		_drive(results[0].agent); await process_frame
		_ok(views[2].is_active_visual(), "D: slot still active after first arrival (2 in flight)")
		# finish second -> still active
		_drive(results[1].agent); await process_frame
		_ok(views[2].is_active_visual(), "D: slot still active after second arrival (1 in flight)")
		# finish third -> inactive
		_drive(results[2].agent); await process_frame; await process_frame
		_ok(not views[2].is_active_visual(), "D: slot returns inactive after final arrival")
		_ok(_changed(st0, _states(board)) == [380, 381, 382], "D: whole-board delta EXACTLY {380,381,382}")
		var c08_1 := _c08(board)
		_ok(_minus(c08_0, c08_1) == [380, 381, 382] and _minus(c08_1, c08_0) == [], "D: C08 candidate set loses exactly those three")
		_ok(inst._dispatcher.get_active_count() == 0 and _agents(inst.get_agent_layer()) == 0, "D: dispatcher + AgentLayer clean")
	inst.free()

# ------------------------------------------------------------- gap E ----------

func _gap_E_reset() -> void:
	print("-- G-V08-05: reset-in-flight through fresh real scene --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	inst._last_result = null; views[2].pressed.emit(); var a1 = inst._last_result
	inst._last_result = null; views[2].pressed.emit(); var a2 = inst._last_result
	_ok(a1 != null and a1.success and a2 != null and a2.success, "E: two real C08 Button presses dispatched")
	if a1 != null and a1.success and a2 != null and a2.success:
		var t1: int = a1.target_index; var t2: int = a2.target_index
		var st_pre := _states(board)
		var c08_pre := _c08(board)
		_ok(inst._dispatcher.get_active_count() == 2, "E: dispatcher active 2 pre-reset")
		_ok(inst._dispatcher.get_target_for_owner(a1.owner_id) == t1 and inst._dispatcher.get_target_for_owner(a2.owner_id) == t2, "E: exact pre-reset owner->target pairs")
		_ok(_agents(inst.get_agent_layer()) == 2, "E: 2 AgentLayer agents pre-reset")
		inst.reset_presentation()  # canonical bound CompleteClearingLoop.reset()
		_ok(inst._dispatcher.get_active_count() == 0, "E: dispatcher active 0 after reset")
		_ok(not inst._dispatcher.has_owner(a1.owner_id) and not inst._dispatcher.has_owner(a2.owner_id), "E: old owner assignments absent after reset")
		_ok(_states(board) == st_pre, "E: BoardState state vector identical after reset")
		_ok(board.get_cell_state(t1) == BoardState.CellState.ACTIVE and board.get_cell_state(t2) == BoardState.CellState.ACTIVE, "E: in-flight targets remain ACTIVE")
		_ok(_c08(board) == c08_pre, "E: C08 candidate set coherent/unchanged after reset")
		await process_frame
		await process_frame
		_ok(_agents(inst.get_agent_layer()) == 0, "E: no orphan agents after deferred frames")
		inst._last_result = null; views[2].pressed.emit(); var a3 = inst._last_result
		_ok(a3 != null and a3.success and a3.target_index == 380, "E: fresh post-reset C08 Button selects 380/(0,19)")
	inst.free()

# --------------------------------------------------------------- report -------

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M21 V09 direct-evidence reconciliation: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
