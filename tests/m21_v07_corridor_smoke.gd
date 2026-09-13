extends SceneTree
## M21-C001 V07 — real owner-scene exterior-corridor smoke (Hazard Bot (0,19)/380).
##
## Frame-aware proof that, after the one-cell exterior routing corridor correction,
## clicking the visible C08 slot on the fresh Hazard Bot selects the far-left bottom
## target (0,19)/index 380 and the real Scrubbot travels the bottom exterior ring to
## it (no tunnelling through ACTIVE bottom-row art), then subsequent C08 clears
## advance left-to-right (381, 382, ...). Slot-click only (SPACE dispatch removed).
##
## Run:  godot --headless --path . -s res://tests/m21_v07_corridor_smoke.gd
## Exits 0 on success, 1 on any failure.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
var _fail := 0

func _initialize() -> void:
	var scene = load("res://scenes/debug/m21_real_art_vertical_slice.tscn")
	var inst = scene.instantiate()
	get_root().add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame

	# SPACE gameplay dispatch must be gone (F-M21-OWNER-001).
	_ok(not inst.has_method("step_one_clear"), "step_one_clear() removed (slot-only interaction)")
	_ok(not inst.has_method("_unhandled_input"), "_unhandled_input SPACE handler removed")

	var pres = inst.get_presentation()
	var agent_layer = inst.get_agent_layer()
	var renderer = pres.get_renderer()
	var views: Array = inst.get_slot_views()
	var slot_id := 2  # C08

	var anchor: Vector2 = views[slot_id].get_spawn_anchor_global()
	var mapped: Vector2 = pres.global_to_board_local(anchor)

	# Real Button/SlotView signal path (not SPACE, not direct request_slot).
	inst._last_result = null
	views[slot_id].pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "visible C08 slot click dispatches a real assignment")
	if r != null and r.success:
		var agent = r.agent
		_ok(r.target_index == 380, "first C08 target index == 380 (got %d)" % r.target_index)
		var tpos: Vector2i = inst._board.get_cell_position(r.target_index)
		_ok(tpos == Vector2i(0, 19), "first C08 target coord == (0,19) (got %s)" % str(tpos))
		_ok(inst._board.get_color_id(r.target_index) == 2, "target color local palette id == 2 (C08)")
		_ok(agent.get_parent() == agent_layer, "agent is AgentLayer child")
		var pts: PackedVector2Array = agent.get_route_points()
		_ok(pts[0].distance_to(mapped) < 0.001, "route point 0 == mapped slot origin")
		_ok(pts[pts.size() - 1].is_equal_approx(Vector2(0.5, 19.5)), "route final point == centre of (0,19)")
		_ok(_has_bottom_ring_point(pts), "route traverses the bottom exterior ring (y>=20 exterior point)")
		_ok(not _crosses_active_bottom_row(pts, inst._board), "route does not cross intervening ACTIVE bottom-row cells")
		print("V07_TUPLE anchor=%s mapped=%s spawn_origin=%s target=%d coord=%s route=%s" % [
			str(anchor), str(mapped), str(agent.spawn_origin), r.target_index, str(tpos), str(pts)])
		# Drive to authenticated arrival (test orchestration); M20 clears exactly 380.
		for _i in range(1024):
			if not is_instance_valid(agent) or not agent.is_moving():
				break
			agent.advance(1.0)
		_ok(inst._board.get_cell_state(380) == 1, "authenticated M20 arrival cleared exactly index 380 (CLEARED)")
		await process_frame
		await process_frame
		_ok(_agent_children(agent_layer) == 0, "AgentLayer no orphan agents after cleanup")

	# Deterministic left-to-right progression along the bottom row (serial).
	var expected := [381, 382, 383]
	var got := []
	for want in expected:
		inst._last_result = null
		views[slot_id].pressed.emit()
		var rr = inst._last_result
		if rr != null and rr.success:
			got.append(rr.target_index)
			for _i in range(1024):
				if not is_instance_valid(rr.agent) or not rr.agent.is_moving():
					break
				rr.agent.advance(1.0)
			await process_frame
	_ok(got == expected, "subsequent C08 clears advance left-to-right along bottom row: got %s expected %s" % [str(got), str(expected)])

	inst.free()
	_done()

func _has_bottom_ring_point(points: PackedVector2Array) -> bool:
	for p in points:
		if int(floor(p.y)) >= 20:  # board is 20 tall -> y=20 is the bottom exterior ring
			return true
	return false

func _crosses_active_bottom_row(points: PackedVector2Array, board) -> bool:
	# A raw route-point (not the final arrival) sitting inside an ACTIVE bottom-row
	# cell would indicate tunnelling. The final point is the target arrival itself.
	for i in range(points.size() - 1):
		var p := points[i]
		var cx := int(floor(p.x)); var cy := int(floor(p.y))
		if cy == 19 and cx >= 0 and cx < 20:
			var idx: int = board.get_cell_index(cx, cy)
			if board.get_cell_state(idx) == 0:  # ACTIVE
				return true
	return false

func _agent_children(layer) -> int:
	var n := 0
	for c in layer.get_children():
		if c is ScrubbotAgent:
			n += 1
	return n

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M21 V07 corridor smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
