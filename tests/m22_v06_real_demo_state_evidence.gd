extends SceneTree
## M22-C001 V06 — final REAL-DEMO validation-only evidence (closes
## F-M22-V05-EVIDENCE-001). PRODUCTION-IMMUTABLE: reads/exercises accepted V03
## production behavior (baseline 8ded358) and persists direct state observations;
## changes no production source or scene.
##
## Unlike V05 section A, this proves C08 ReservationState + dispatcher + agent
## cleanup on the ACTUAL laid-out m22_slot_demo.tscn instance via the REAL C08
## Button signal path, inspecting the EXACT objects owned by that demo transaction:
##   - ReservationState  = inst._loop._reservations  (bound inside the demo loop)
##   - dispatcher        = inst._dispatcher
##   - AgentLayer        = inst.get_agent_layer()
## No parallel ReservationState/ScrubbotDispatcher/CompleteClearingLoop is built.
##
## Run: godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd
## Exits 0 on success, 1 on any failure. On a production mismatch it fails (operator
## then stops BLOCKED without patching production).

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

var _fail := 0

func _initialize() -> void:
	await _run()
	_done()

func _agent_children(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent:
			n += 1
	return n

func _run() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var inst = load("res://scenes/demo/m22_slot_demo.tscn").instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame
	await process_frame

	var panel = inst.get_panel()
	_ok(panel != null and panel.get_slot_cells().size() == 5, "exactly five actual SlotCell/Button instances after layout")

	# The EXACT demo-owned authority objects — not a rebuilt chain.
	var reservations = inst._loop._reservations
	var dispatcher = inst._dispatcher
	var agent_layer = inst.get_agent_layer()
	_ok(reservations != null, "obtained exact demo ReservationState via inst._loop._reservations")
	_ok(dispatcher == inst._dispatcher, "obtained exact demo dispatcher via inst._dispatcher")

	var res_before: int = reservations.get_reservation_count()
	var disp_before: int = dispatcher.get_active_count()
	var agents_before: int = _agent_children(agent_layer)
	print("V06_PRE res_count=%d disp_active=%d agents=%d" % [res_before, disp_before, agents_before])

	# Real laid-out C08 Button signal path -> _on_slot_activated -> request_slot.
	inst._last_result = null
	panel.get_cell(2).pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "real C08 Button activation dispatches")
	if r == null or not r.success:
		inst.free(); sub.free(); return
	var owner_id: int = r.owner_id
	var tgt: int = r.target_index
	var agent = r.agent
	_ok(tgt == 380 and inst._board.get_cell_position(380) == Vector2i(0, 19), "C08 naturally selects 380/(0,19)")

	# In-flight, on the exact demo objects.
	var if_owner: int = reservations.get_owner(380)
	var if_t4o: int = reservations.get_target_for_owner(owner_id)
	var if_has: bool = dispatcher.has_owner(owner_id)
	var if_disp_t4o: int = dispatcher.get_target_for_owner(owner_id)
	var if_agent_match: bool = dispatcher.get_agent_for_owner(owner_id) == agent
	print("V06_INFLIGHT owner_id=%d target=%d res.get_owner(380)=%d res.get_target_for_owner(owner)=%d disp.has_owner=%s disp.get_target_for_owner=%d disp.agent_matches=%s" % [
		owner_id, tgt, if_owner, if_t4o, str(if_has), if_disp_t4o, str(if_agent_match)])
	_ok(if_owner == owner_id, "in-flight demo ReservationState get_owner(380) == owner_id")
	_ok(if_t4o == 380, "in-flight demo ReservationState get_target_for_owner(owner_id) == 380")
	_ok(if_has, "in-flight demo dispatcher has_owner(owner_id) == true")
	_ok(if_disp_t4o == 380, "in-flight demo dispatcher get_target_for_owner(owner_id) == 380")
	_ok(if_agent_match, "in-flight demo dispatcher get_agent_for_owner(owner_id) == exact real Button agent")

	# Drive the exact Button-created agent to authenticated arrival (accepted path
	# used by prior tests: the agent's own advance(); the loop/dispatcher perform
	# the authenticated arrival + clear + release on completion).
	for _i in range(1024):
		if not is_instance_valid(agent) or not agent.is_moving():
			break
		agent.advance(1.0)
	await process_frame
	await process_frame

	var post_cleared: bool = inst._board.get_cell_state(380) == BoardState.CellState.CLEARED
	var post_count: int = reservations.get_reservation_count()
	var post_owner: int = reservations.get_owner(380)
	var post_t4o: int = reservations.get_target_for_owner(owner_id)
	var post_active: int = dispatcher.get_active_count()
	var post_has: bool = dispatcher.has_owner(owner_id)
	var post_disp_t4o: int = dispatcher.get_target_for_owner(owner_id)
	var post_agent = dispatcher.get_agent_for_owner(owner_id)
	var post_agents: int = _agent_children(agent_layer)
	print("V06_POST cleared_380=%s res_count=%d/%d get_owner(380)=%d res.t4o(owner)=%d disp_active=%d/%d has_owner=%s disp.t4o=%d agent_null=%s agents=%d" % [
		str(post_cleared), post_count, res_before, post_owner, post_t4o, post_active, disp_before,
		str(post_has), post_disp_t4o, str(post_agent == null), post_agents])
	_ok(post_cleared, "authenticated arrival cleared exactly demo target 380")
	_ok(post_count == res_before, "demo ReservationState count returned to pre-dispatch baseline")
	_ok(post_owner == -1, "demo ReservationState get_owner(380) == -1 after arrival")
	_ok(post_t4o == -1, "demo ReservationState get_target_for_owner(owner_id) == -1 after arrival")
	_ok(post_active == disp_before, "demo dispatcher active count returned to baseline")
	_ok(not post_has, "demo dispatcher has_owner(owner_id) == false after arrival")
	_ok(post_disp_t4o == -1, "demo dispatcher get_target_for_owner(owner_id) == -1 after arrival")
	_ok(post_agent == null, "demo dispatcher get_agent_for_owner(owner_id) == null after arrival")
	_ok(post_agents == 0, "zero ScrubbotAgent remain in the real demo AgentLayer after deferred cleanup")

	inst.free()
	sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 V06 real-demo state evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
