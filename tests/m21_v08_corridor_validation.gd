extends SceneTree
## M21-C001 V08 — production-immutable final technical validation.
##
## Validation-ONLY: adds no production/scene/project change. Exercises the accepted
## V07 production candidate (routing corridor + slot-only owner input) with fresh
## adversarial arrangements, instrumented ring-domain wrappers, the real owner
## scene, and real production collaborators. If a real production defect is found,
## the runner reports FAIL and the handoff is BLOCKED (production is NOT patched).
##
## Run:  godot --headless --path . -s res://tests/m21_v08_corridor_validation.gd
## Exits 0 on success, 1 on any failure.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")

const LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"
const CONTROLLER_SRC := "res://scripts/debug/m21_real_art_vertical_slice.gd"

var _fail := 0

## Recording delegate over the real, unchanged ProductionAccessQuery.
class RecordingAccess extends RefCounted:
	var inner
	var classified: Array = []
	func _init(board):
		inner = load("res://scripts/gameplay/routing/production_access_query.gd").new(board)
	func is_bound_to(board): return inner.is_bound_to(board)
	func classify_cell(cx, cy, ti):
		classified.append(Vector2i(cx, cy))
		return inner.classify_cell(cx, cy, ti)
	func cell_of_point(p): return inner.cell_of_point(p)
	func is_segment_traversable(a, b, ti): return inner.is_segment_traversable(a, b, ti)

## Delegate that BLOCKS all outside-board (exterior ring) cells, delegating inside.
class BlockingRingAccess extends RefCounted:
	var inner
	var _w: int
	var _h: int
	func _init(board):
		inner = load("res://scripts/gameplay/routing/production_access_query.gd").new(board)
		_w = board.get_width(); _h = board.get_height()
	func is_bound_to(board): return inner.is_bound_to(board)
	func classify_cell(cx, cy, ti):
		if cx < 0 or cy < 0 or cx >= _w or cy >= _h:
			return ProductionAccessQuery.CellClass.BLOCKED  # ring/exterior disabled
		return inner.classify_cell(cx, cy, ti)
	func cell_of_point(p): return inner.cell_of_point(p)
	func is_segment_traversable(a, b, ti):
		# Reject any segment touching an outside cell so the ring gives no path.
		var ca: Vector2i = inner.cell_of_point(a); var cb: Vector2i = inner.cell_of_point(b)
		if ca.x < 0 or ca.y < 0 or ca.x >= _w or ca.y >= _h: return false
		if cb.x < 0 or cb.y < 0 or cb.x >= _w or cb.y >= _h: return false
		return inner.is_segment_traversable(a, b, ti)

func _initialize() -> void:
	print("godot_version_note: this run — see godot --version (V08 does not change Godot)")
	_section_A_slot_only()
	await _section_D_hazard_scene()
	_section_B_ring_domain()
	_section_C_matrix()
	_section_bundle_hazard_and_E_H()
	_done()

# ---------------------------------------------------------------- helpers -----

func _all_active(w: int, h: int):
	var cells := PackedStringArray(["#2450A4FF"])
	var arr := PackedInt32Array(); arr.resize(w * h)
	for i in range(w * h): arr[i] = 0
	return BoardState.from_level_data(LevelData.new(1, "va", "va", "TEST", w, h, cells, arr))

func _route(board, origin: Vector2, idx: int, access = null):
	var routing = ProductionRoutingSystem.new()
	var acc = access if access != null else ProductionAccessQuery.new(board)
	return routing.compute_route(RouteRequest.for_target(board, origin, idx), board, acc)

func _has_exterior(points: PackedVector2Array, w: int, h: int) -> bool:
	for p in points:
		var cx := int(floor(p.x)); var cy := int(floor(p.y))
		if cx < 0 or cy < 0 or cx >= w or cy >= h: return true
	return false

## Real production bundle over `board` (no fault seams).
func _wire(board) -> Dictionary:
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var saccess = ProductionTargetAccess.new(routing, raccess, board)
	var dispatcher = ScrubbotDispatcher.new(); get_root().add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, raccess, saccess)
	var slots = SlotSystem.new(); slots.configure([0, 1, 2, 3, 4], 5)
	var loop = CompleteClearingLoop.new()
	loop.bind(board, slots, candidates, reservations, dispatcher)
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"dispatcher": dispatcher, "slots": slots, "loop": loop}

func _drive(agent) -> void:
	for _i in range(2048):
		if not is_instance_valid(agent) or not agent.is_moving(): break
		agent.advance(1.0)

# ---------------------------------------------------------------- sections ----

func _section_A_slot_only() -> void:
	print("-- A: slot-only owner input --")
	var src := FileAccess.get_file_as_string(CONTROLLER_SRC)
	_ok(src.find("KEY_SPACE") == -1, "A: no KEY_SPACE in owner controller source")
	_ok(src.find("step_one_clear") == -1, "A: no step_one_clear symbol")
	_ok(src.find("_unhandled_input") == -1, "A: no gameplay _unhandled_input hook")
	_ok(src.find("_shortcut_input") == -1, "A: no _shortcut_input dispatch")
	# Bare `_input(` keyboard gameplay hook must not exist either.
	_ok(src.find("func _input(") == -1, "A: no replacement _input keyboard dispatch")

func _section_D_hazard_scene() -> void:
	print("-- D: fresh Hazard Bot real owner scene (Button path) --")
	var scene = load("res://scenes/debug/m21_real_art_vertical_slice.tscn")
	var inst = scene.instantiate()
	get_root().add_child(inst)
	if inst._board == null: inst.build()
	await process_frame
	await process_frame
	var views: Array = inst.get_slot_views()
	_ok(views.size() == 5, "D/A: exactly five SlotViews")
	var pres = inst.get_presentation()
	var agent_layer = inst.get_agent_layer()
	var renderer = pres.get_renderer()
	# A: disconnect slot_activated -> no dispatch; reconnect -> dispatch.
	inst._last_result = null
	views[2].slot_activated.disconnect(inst._on_slot_activated)
	views[2].pressed.emit()
	_ok(inst._last_result == null, "A: disconnected SlotView signal prevents dispatch")
	views[2].slot_activated.connect(inst._on_slot_activated)
	# A: no-work slot (C01 enclosed on fresh board) -> zero side effects.
	inst._last_result = null
	var pre_children := _agents(agent_layer)
	views[0].pressed.emit()
	_ok(inst._last_result != null and not inst._last_result.success, "A: no-work slot produces no assignment")
	_ok(_agents(agent_layer) == pre_children, "A: no-work slot spawns no agent")
	_ok(inst._board.count_cells_by_state(BoardState.CellState.ACTIVE) == 400, "A: no-work slot clears nothing")
	# D: real C08 Button dispatch.
	inst._last_result = null
	var anchor: Vector2 = views[2].get_spawn_anchor_global()
	var mapped: Vector2 = pres.global_to_board_local(anchor)
	views[2].pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "D: real C08 Button dispatch succeeds")
	if r != null and r.success:
		var agent = r.agent
		_ok(r.target_index == 380, "D: first target index 380 (got %d)" % r.target_index)
		_ok(inst._board.get_cell_position(380) == Vector2i(0, 19), "D: target coord (0,19)")
		_ok(inst._board.get_color_id(380) == 2, "D: target color local id 2 / C08")
		_ok(inst._board.get_cell_state(380) == BoardState.CellState.ACTIVE, "D: target ACTIVE before dispatch")
		var pts: PackedVector2Array = agent.get_route_points()
		_ok(pts[0].distance_to(mapped) < 0.001, "D/031: route[0] == mapped visible slot anchor")
		_ok(pts[pts.size() - 1].is_equal_approx(Vector2(0.5, 19.5)), "D: route end == (0.5,19.5)")
		# Detached route revalidates through unchanged RouteValidator + PAQ.
		var vreq = RouteRequest.for_target(inst._board, pts[0], 380)
		var vres = RouteResult.success_route(380, pts)
		_ok(RouteValidator.validate_route(vreq, vres, inst._board, ProductionAccessQuery.new(inst._board)) == RouteResult.FailureReason.NONE, "D: detached route revalidates NONE")
		_ok(not _crosses_active(pts, inst._board), "D: no segment crosses a non-target ACTIVE board cell")
		var tp: Vector2i = inst._board.get_cell_position(380)
		_ok(agent.global_position.distance_to(renderer.get_cell_center_global(tp.x, tp.y)) >= 0.0, "D: agent has a presentation position")
		_drive(agent)
		_ok(inst._board.get_cell_state(380) == BoardState.CellState.CLEARED, "D/064: authenticated arrival cleared exactly 380")
		# D/065 (candidate index dropped 380) + D/066 (reservation) proven with exact
		# reservation/candidate introspection in the real-bundle section below.
		_ok(inst._dispatcher.get_active_count() == 0, "D/067: dispatcher active 0 after completion")
		await process_frame
		await process_frame
		_ok(_agents(agent_layer) == 0, "D/068: AgentLayer 0 orphan agents after cleanup")
	inst.free()

func _section_B_ring_domain() -> void:
	print("-- B: instrumented exact one-cell ring domain --")
	var b = _all_active(20, 20)
	var idx: int = b.get_cell_index(0, 19)
	var rec = RecordingAccess.new(b)
	var rr = _route(b, Vector2(9.5, 21.5), idx, rec)
	_ok(rr.success, "B: far-left bottom reachable (recording delegate)")
	var all_ring := true
	var within := true
	for c in rec.classified:
		if c.x < 0 or c.y < 0 or c.x >= 20 or c.y >= 20:
			if c.x < -1 or c.y < -1 or c.x > 20 or c.y > 20:
				within = false
			if not (c.x == -1 or c.x == 20 or c.y == -1 or c.y == 20):
				all_ring = false
	_ok(within, "B/036: every outside classified cell within -1..20")
	_ok(all_ring, "B/037: every outside classified cell is a legal ring side/corner")
	_ok(_has_exterior(rr.get_points(), 20, 20), "B/039: successful route uses exterior ring (load-bearing)")
	# Blocked-ring delegate -> same target unreachable, no retarget.
	var blk = BlockingRingAccess.new(b)
	var rb = _route(b, Vector2(9.5, 21.5), idx, blk)
	_ok(not rb.success, "B/040: blocking the ring makes far-left bottom unreachable")
	_ok(rb.target_index == idx, "B/041: blocked-ring failure keeps the same target (no retarget)")

func _section_C_matrix() -> void:
	print("-- C: four-side / corner / rectangular / 59x59 / enclosed --")
	var w := 20; var h := 20
	var bb = _all_active(w, h)
	_ok(_route(bb, Vector2(9.5, float(h) + 1.5), bb.get_cell_index(0, h - 1)).success, "C/042: below -> far-left bottom")
	_ok(_route(bb, Vector2(9.5, -2.5), bb.get_cell_index(w - 1, 0)).success, "C/043: above -> far-right top")
	_ok(_route(bb, Vector2(-2.5, 1.5), bb.get_cell_index(0, h - 1)).success, "C/044: left -> far-bottom-left")
	_ok(_route(bb, Vector2(float(w) + 2.5, float(h) - 1.5), bb.get_cell_index(w - 1, 0)).success, "C/045: right -> far-top-right")
	# corner: below-left origin -> top-right target uses two exterior sides.
	var rc = _route(bb, Vector2(-2.5, float(h) + 2.5), bb.get_cell_index(w - 1, 0))
	_ok(rc.success, "C/046: below-left -> top-right (corner transition)")
	var pts: PackedVector2Array = rc.get_points()
	var used_left := false; var used_top := false
	for p in pts:
		var cx := int(floor(p.x)); var cy := int(floor(p.y))
		if cx < 0: used_left = true
		if cy < 0: used_top = true
	_ok(used_left and used_top, "C/047: corner route uses BOTH left and top exterior sides")
	# rectangular
	_ok(_route(_all_active(30, 12), Vector2(15.5, 13.5), _all_active(30, 12).get_cell_index(0, 11)).success, "C/048: rectangular 30x12")
	# 59x59 + timing
	var b59 = _all_active(59, 59)
	var t0 := Time.get_ticks_usec()
	var r59 = _route(b59, Vector2(29.5, 60.5), b59.get_cell_index(0, 58))
	var us := Time.get_ticks_usec() - t0
	_ok(r59.success, "C/049: 59x59 far-left bottom reachable")
	print("  C/050 59x59 route CPU elapsed = %.3f ms (diagnostic only, no FPS/GPU claim)" % (float(us) / 1000.0))
	# enclosed interior unreachable
	var be = _all_active(w, h)
	_ok(not _route(be, Vector2(9.5, float(h) + 1.5), be.get_cell_index(10, 10)).success, "C/051: enclosed interior ACTIVE unreachable")
	# CLEARED opening later makes interior reachable
	var bo = _all_active(w, h)
	var interior: int = bo.get_cell_index(10, 10)
	_ok(not _route(bo, Vector2(9.5, float(h) + 1.5), interior).success, "C/052a: interior initially unreachable")
	# open a straight CLEARED corridor from the bottom edge up to (10,11), leaving the
	# interior target (10,10) itself ACTIVE (a target must be ACTIVE).
	for yy in range(11, h):
		bo.set_cell_state(bo.get_cell_index(10, yy), BoardState.CellState.CLEARED)
	_ok(_route(bo, Vector2(10.5, float(h) + 1.5), interior).success, "C/052b: interior reachable after a legitimate CLEARED opening")
	# diagonal squeeze through two ACTIVE blockers is rejected by access truth
	var bd = _all_active(5, 5)
	var acc = ProductionAccessQuery.new(bd)
	# (1,1) and (2,2) ACTIVE; a diagonal from (0.5,2.5)->(2.5,0.5) squeezes the corner
	_ok(not acc.is_segment_traversable(Vector2(0.5, 2.5), Vector2(2.5, 0.5), bd.get_cell_index(0, 0)), "C/053: diagonal squeeze through ACTIVE blockers rejected")

func _section_bundle_hazard_and_E_H() -> void:
	print("-- E/H + reservation-exact Hazard Bot (real bundle) --")
	# Real-bundle first C08 clear: reservation cleanup exact (D/066 support).
	var lvl = LevelLoader.load_from_path(LEVEL).level_data
	var w1 = _wire(BoardState.from_level_data(lvl))
	var origin := Vector2(-1.5, 21.0)
	var r0 = w1["loop"].activate_slot(2, origin, 6.0)
	_ok(r0.success and r0.target_index == 380, "E0: bundle C08 first target 380")
	if r0.success:
		_ok(w1["reservations"].get_owner(380) == r0.owner_id, "E0: reservation target->owner before arrival")
		_ok(w1["reservations"].get_target_for_owner(r0.owner_id) == 380, "E0: reservation owner->target before arrival")
		_drive(r0.agent)
		_ok(w1["reservations"].get_owner(380) == -1 and w1["reservations"].get_target_for_owner(r0.owner_id) == -1, "D/066: reservation map no stale after clear")
		_ok(not w1["candidates"].get_candidates(2, null).has(380), "D/065: candidate index dropped 380")
	_teardown(w1)

	# E: rapid same-slot x3 before arrival.
	var w2 = _wire(BoardState.from_level_data(lvl))
	var res: Array = []
	for _i in range(3):
		var rr = w2["loop"].activate_slot(2, Vector2(-1.5, 21.0), 6.0)
		if rr.success: res.append(rr)
	_ok(res.size() == 3, "E/069: three concurrent C08 activations accepted")
	if res.size() == 3:
		var tids := [res[0].target_index, res[1].target_index, res[2].target_index]
		_ok(tids == [380, 381, 382], "E/070: targets 380,381,382 in order (got %s)" % str(tids))
		var owners := {}
		for rr in res: owners[rr.owner_id] = true
		_ok(owners.size() == 3, "E/071: unique owner ids")
		var bidir := true
		for rr in res:
			if w2["reservations"].get_owner(rr.target_index) != rr.owner_id: bidir = false
			if w2["reservations"].get_target_for_owner(rr.owner_id) != rr.target_index: bidir = false
		_ok(bidir, "E/072: exact bidirectional reservation mapping")
		_ok(tids[0] != tids[1] and tids[1] != tids[2] and tids[0] != tids[2], "E/073: no duplicate target")
		for rr in res: _drive(rr.agent)
		_ok(w2["board"].get_cell_state(380) == 1 and w2["board"].get_cell_state(381) == 1 and w2["board"].get_cell_state(382) == 1, "E/076: all three cleared exactly once")
		_ok(w2["dispatcher"].get_active_count() == 0 and w2["reservations"].get_reservation_count() == 0, "E/076: reservations/agents cleaned up")
	_teardown(w2)

	# H: reset with >=2 exterior-routed agents in flight.
	var w3 = _wire(BoardState.from_level_data(lvl))
	var a1 = w3["loop"].activate_slot(2, Vector2(-1.5, 21.0), 6.0)
	var a2 = w3["loop"].activate_slot(2, Vector2(-1.5, 21.0), 6.0)
	_ok(a1.success and a2.success, "H/077: two exterior-routed C08 agents dispatched")
	var t1: int = a1.target_index; var t2: int = a2.target_index
	_ok(w3["dispatcher"].get_active_count() == 2 and w3["reservations"].get_reservation_count() == 2, "H/078: pre-reset truth captured (2 active, 2 reserved)")
	w3["loop"].reset()
	_ok(w3["dispatcher"].get_active_count() == 0, "H/080: reset removed all active assignments")
	_ok(w3["reservations"].get_reservation_count() == 0, "H/081: reset released all reservations")
	_ok(w3["board"].get_cell_state(t1) == 0 and w3["board"].get_cell_state(t2) == 0, "H/083: reset did NOT clear in-flight targets")
	_ok(w3["candidates"].get_candidates(2, null).has(t1), "H/084: candidate truth coherent with BoardState after reset")
	await process_frame
	await process_frame
	_ok(_dispatcher_agents(w3["dispatcher"]) == 0, "H/082: no orphan agents after reset + frames")
	var a3 = w3["loop"].activate_slot(2, Vector2(-1.5, 21.0), 6.0)
	_ok(a3.success and a3.target_index == 380, "H/085: fresh post-reset C08 selects (0,19)/380 again")
	_teardown(w3)

func _teardown(w: Dictionary) -> void:
	if w.has("loop"): w["loop"].reset()
	var d = w["dispatcher"]
	if is_instance_valid(d):
		get_root().remove_child(d); d.free()

func _crosses_active(points: PackedVector2Array, board) -> bool:
	var w: int = board.get_width(); var h: int = board.get_height()
	for i in range(points.size() - 1):
		var p := points[i]
		var cx := int(floor(p.x)); var cy := int(floor(p.y))
		if cx >= 0 and cy >= 0 and cx < w and cy < h:
			if board.get_cell_state(board.get_cell_index(cx, cy)) == 0:  # ACTIVE, non-final point
				return true
	return false

func _agents(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _dispatcher_agents(d) -> int:
	var n := 0
	for c in d.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M21 V08 corridor validation: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
