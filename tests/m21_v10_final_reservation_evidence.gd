extends SceneTree
## M21-C001 V10 — production-immutable final ReservationState/scene direct-evidence
## reconciliation.
##
## Closes the frozen V09 residuals F-M21-V09-EVIDENCE-001/002 by observing the EXACT
## live ReservationState object already bound into the real owner scene's real
## CompleteClearingLoop (read-only introspection of the existing `_loop._reservations`
## field — no production hook/getter is added), and by adding the exact scene-state
## assertions V09 left implicit:
##  - exactly five SlotViews on a fresh scene;
##  - reservation evidence taken from ReservationState.get_reservation_count() /
##    get_owner(target) / get_target_for_owner(owner) (NOT the dispatcher proxy);
##  - dispatcher proven bound to the same board + same ReservationState via the
##    existing ScrubbotDispatcher.is_bound_to(board, reservation_state);
##  - AgentLayer 3 -> 2 -> 1 -> 0 real-child lifecycle across rapid x3;
##  - reset-in-flight: exact targets 380,381 + unique owners + captured agent
##    instance identities, reservation count/pairs pre/post, no orphan identity.
##
## Run:  godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd
## Exits 0 on success, 1 on any failure. If the exact ReservationState observation
## exposes a genuine production mismatch, this reports FAIL and the handoff is BLOCKED
## (production is NOT patched).

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const SCENE := "res://scenes/debug/m21_real_art_vertical_slice.tscn"
var _fail := 0

func _initialize() -> void:
	await _a_nowork()
	await _b_first_clear()
	await _c_rapid3()
	await _d_reset()
	_done()

# ---------------------------------------------------------------- helpers -----

func _fresh_scene():
	var inst = load(SCENE).instantiate()
	get_root().add_child(inst)
	if inst._board == null: inst.build()
	await process_frame
	await process_frame
	return inst

## The EXACT live ReservationState bound into the real scene's real loop.
func _reservations(inst):
	return inst._loop._reservations

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

func _c08(board) -> Array:
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var a: Array = ci.get_candidates(2, null); a.sort(); return a

func _c_generic(board, color: int) -> Array:
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var a: Array = ci.get_candidates(color, null); a.sort(); return a

func _minus(a: Array, b: Array) -> Array:
	var s := {}
	for x in b: s[x] = true
	var out: Array = []
	for x in a:
		if not s.has(x): out.append(x)
	return out

func _agents(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent: n += 1
	return n

func _drive(agent) -> void:
	for _i in range(2048):
		if not is_instance_valid(agent) or not agent.is_moving(): break
		agent.advance(1.0)

## Baseline proof that the object under observation is the exact live one.
func _prove_live_reservation(inst, resv) -> void:
	_ok(resv != null, "live ReservationState object obtained from _loop._reservations")
	_ok(resv.is_bound_to(inst._board), "ReservationState bound to the scene's exact board")
	_ok(inst._dispatcher.is_bound_to(inst._board, resv), "dispatcher bound to the SAME board + SAME ReservationState")

# ------------------------------------------------------------- A: no-work -----

func _a_nowork() -> void:
	print("-- V10 A: no-work real Button, exact ReservationState zero side effect --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	_ok(views.size() == 5, "A: exactly five SlotViews on fresh scene")
	var resv = _reservations(inst)
	_prove_live_reservation(inst, resv)
	var st0 := _states(board)
	var c08_0 := _c08(board)
	var c01_0 := _c_generic(board, 0)
	var da0: int = inst._dispatcher.get_active_count()
	var al0 := _agents(inst.get_agent_layer())
	_ok(resv.get_reservation_count() == 0, "A: ReservationState count 0 before no-work click")
	# Slot 0 (C01) is enclosed on the fresh board -> no reachable work.
	inst._last_result = null
	views[0].pressed.emit()
	var r = inst._last_result
	_ok(r != null and not r.success, "A: no-work slot Button yields a legitimate no-work result")
	_ok(resv.get_reservation_count() == 0, "A: ReservationState count remains exactly 0 after no-work click")
	_ok(_states(board) == st0, "A: BoardState state vector byte-identical after no-work click")
	_ok(_c08(board) == c08_0 and _c_generic(board, 0) == c01_0, "A: candidate sets unchanged after no-work click")
	_ok(inst._dispatcher.get_active_count() == da0 and inst._dispatcher.get_active_count() == 0, "A: dispatcher active 0 unchanged")
	_ok(_agents(inst.get_agent_layer()) == al0 and _agents(inst.get_agent_layer()) == 0, "A: AgentLayer 0 unchanged")
	inst.free()

# ---------------------------------------------------- B: first C08 lifecycle --

func _b_first_clear() -> void:
	print("-- V10 B: first C08 real Button, exact ReservationState pair lifecycle --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	var resv = _reservations(inst)
	_prove_live_reservation(inst, resv)
	var st0 := _states(board)
	var c08_0 := _c08(board)
	inst._last_result = null
	views[2].pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "B: real C08 Button dispatch succeeds")
	if r != null and r.success:
		var owner: int = r.owner_id
		var agent = r.agent
		_ok(r.target_index == 380 and board.get_cell_position(380) == Vector2i(0, 19), "B: target 380 == (0,19)")
		# In-flight, direct on the exact ReservationState.
		_ok(resv.get_owner(380) == owner, "B: ReservationState get_owner(380) == owner in flight")
		_ok(resv.get_target_for_owner(owner) == 380, "B: ReservationState get_target_for_owner(owner) == 380 in flight")
		_ok(resv.get_reservation_count() == 1, "B: ReservationState count == 1 in flight")
		_drive(agent)
		await process_frame
		await process_frame
		_ok(resv.get_owner(380) == -1 and resv.get_target_for_owner(owner) == -1, "B: both ReservationState mappings absent after clear")
		_ok(resv.get_reservation_count() == 0, "B: ReservationState count == 0 after clear")
		_ok(_changed(st0, _states(board)) == [380], "B: whole-board changed-index set EXACTLY [380]")
		var c08_1 := _c08(board)
		_ok(_minus(c08_0, c08_1) == [380] and _minus(c08_1, c08_0) == [], "B: C08 candidate set = pre minus exactly {380}")
		_ok(inst._dispatcher.get_active_count() == 0 and _agents(inst.get_agent_layer()) == 0, "B: dispatcher + AgentLayer clean")
	inst.free()

# ------------------------------------------------------ C: rapid x3 lifecycle --

func _c_rapid3() -> void:
	print("-- V10 C: rapid x3 real C08 Button, exact ReservationState + AgentLayer 3->0 --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	var layer = inst.get_agent_layer()
	var resv = _reservations(inst)
	_prove_live_reservation(inst, resv)
	var st0 := _states(board)
	var c08_0 := _c08(board)
	var results: Array = []
	for _i in range(3):
		inst._last_result = null
		views[2].pressed.emit()
		results.append(inst._last_result)
	var ok3: bool = results.size() == 3 and results[0] != null and results[0].success and results[1] != null and results[1].success and results[2] != null and results[2].success
	_ok(ok3, "C: three rapid real C08 Button presses all dispatch")
	if ok3:
		var tids := [results[0].target_index, results[1].target_index, results[2].target_index]
		_ok(tids == [380, 381, 382], "C: targets 380,381,382 in order (got %s)" % str(tids))
		var owners := {}
		for rr in results: owners[rr.owner_id] = true
		_ok(owners.size() == 3, "C: unique owner ids")
		_ok(resv.get_reservation_count() == 3, "C: ReservationState count == 3 in flight")
		var all_pairs := true
		for rr in results:
			if resv.get_owner(rr.target_index) != rr.owner_id: all_pairs = false
			if resv.get_target_for_owner(rr.owner_id) != rr.target_index: all_pairs = false
		_ok(all_pairs, "C: all three exact bidirectional ReservationState pairs in flight")
		_ok(_agents(layer) == 3, "C: AgentLayer contains exactly 3 real ScrubbotAgent children")
		_ok(views[2].is_active_visual(), "C: C08 SlotView active while assignments in flight")
		# finish first
		_drive(results[0].agent); await process_frame
		_ok(resv.get_reservation_count() == 2, "C: count 2 after first arrival")
		_ok(resv.get_owner(380) == -1 and resv.get_target_for_owner(results[0].owner_id) == -1, "C: first pair absent after first arrival")
		_ok(resv.get_owner(381) == results[1].owner_id and resv.get_owner(382) == results[2].owner_id, "C: other two pairs intact after first arrival")
		_ok(_agents(layer) == 2, "C: AgentLayer exactly 2 after first arrival")
		_ok(views[2].is_active_visual(), "C: slot active after first arrival")
		# finish second
		_drive(results[1].agent); await process_frame
		_ok(resv.get_reservation_count() == 1, "C: count 1 after second arrival")
		_ok(resv.get_owner(381) == -1 and resv.get_owner(382) == results[2].owner_id, "C: second pair absent, third intact after second arrival")
		_ok(_agents(layer) == 1, "C: AgentLayer exactly 1 after second arrival")
		_ok(views[2].is_active_visual(), "C: slot active after second arrival")
		# finish third
		_drive(results[2].agent); await process_frame; await process_frame
		_ok(resv.get_reservation_count() == 0, "C: count 0 after final arrival")
		_ok(resv.get_owner(382) == -1, "C: third pair absent after final arrival")
		_ok(_agents(layer) == 0, "C: AgentLayer 0 after deferred cleanup")
		_ok(not views[2].is_active_visual(), "C: slot returns idle after final arrival")
		_ok(_changed(st0, _states(board)) == [380, 381, 382], "C: whole-board delta EXACTLY {380,381,382}")
		var c08_1 := _c08(board)
		_ok(_minus(c08_0, c08_1) == [380, 381, 382] and _minus(c08_1, c08_0) == [], "C: C08 candidate set loses exactly those three")
	inst.free()

# ---------------------------------------------------------- D: reset in flight -

func _d_reset() -> void:
	print("-- V10 D: reset-in-flight, exact ReservationState + agent identities --")
	var inst = await _fresh_scene()
	var board = inst._board
	var views: Array = inst.get_slot_views()
	var layer = inst.get_agent_layer()
	var resv = _reservations(inst)
	_prove_live_reservation(inst, resv)
	inst._last_result = null; views[2].pressed.emit(); var a1 = inst._last_result
	inst._last_result = null; views[2].pressed.emit(); var a2 = inst._last_result
	_ok(a1 != null and a1.success and a2 != null and a2.success, "D: two real C08 Button presses dispatched")
	if a1 != null and a1.success and a2 != null and a2.success:
		var t1: int = a1.target_index; var t2: int = a2.target_index
		_ok(t1 == 380 and t2 == 381, "D: targets are exactly 380,381 (got %d,%d)" % [t1, t2])
		_ok(a1.owner_id != a2.owner_id, "D: unique owner ids")
		var id1: int = a1.agent.get_instance_id()
		var id2: int = a2.agent.get_instance_id()
		_ok(id1 != id2, "D: two distinct agent instance identities captured")
		var layer_ids := {}
		for c in layer.get_children():
			if c is ScrubbotAgent: layer_ids[c.get_instance_id()] = true
		_ok(layer_ids.size() == 2 and layer_ids.has(id1) and layer_ids.has(id2), "D: AgentLayer contains exactly those two agents")
		var st_pre := _states(board)
		var c08_pre := _c08(board)
		_ok(resv.get_reservation_count() == 2, "D: ReservationState count == 2 pre-reset")
		_ok(resv.get_owner(t1) == a1.owner_id and resv.get_target_for_owner(a1.owner_id) == t1, "D: exact pair 1 pre-reset")
		_ok(resv.get_owner(t2) == a2.owner_id and resv.get_target_for_owner(a2.owner_id) == t2, "D: exact pair 2 pre-reset")
		inst.reset_presentation()  # canonical bound CompleteClearingLoop.reset()
		_ok(resv.get_reservation_count() == 0, "D: ReservationState count == 0 after reset")
		_ok(resv.get_owner(t1) == -1 and resv.get_target_for_owner(a1.owner_id) == -1, "D: old pair 1 absent after reset")
		_ok(resv.get_owner(t2) == -1 and resv.get_target_for_owner(a2.owner_id) == -1, "D: old pair 2 absent after reset")
		_ok(inst._dispatcher.get_active_count() == 0, "D: dispatcher active 0 after reset")
		_ok(_states(board) == st_pre, "D: BoardState state vector identical after reset")
		_ok(board.get_cell_state(t1) == BoardState.CellState.ACTIVE and board.get_cell_state(t2) == BoardState.CellState.ACTIVE, "D: in-flight targets remain ACTIVE")
		_ok(_c08(board) == c08_pre, "D: C08 candidate set unchanged/coherent after reset")
		await process_frame
		await process_frame
		var remain := {}
		for c in layer.get_children():
			if c is ScrubbotAgent: remain[c.get_instance_id()] = true
		_ok(not remain.has(id1) and not remain.has(id2) and _agents(layer) == 0, "D: neither captured agent identity remains; AgentLayer 0")
		inst._last_result = null; views[2].pressed.emit(); var a3 = inst._last_result
		_ok(a3 != null and a3.success and a3.target_index == 380 and board.get_cell_position(380) == Vector2i(0, 19), "D: fresh post-reset C08 Button selects 380/(0,19)")
	inst.free()

# --------------------------------------------------------------- report -------

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M21 V10 final reservation evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
