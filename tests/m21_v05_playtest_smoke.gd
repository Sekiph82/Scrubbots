extends SceneTree
## M21-C001 V05 — frame-aware owner-playtest presentation smoke.
##
## The synchronous root runner cannot lay out Controls or resolve deferred
## queue_free(). This smoke boots the real owner-playable scene, awaits real frames
## so SlotView geometry is laid out, and proves the frozen-finding corrections that
## require true frame/layout/global-coordinate behavior:
##  - F-M21-V04-002: each visible SlotView anchor maps through BoardPresentation/
##    AgentLayer into board-local route space; the real agent's spawn_origin and
##    global start match the clicked slot's visible anchor; route ends at the
##    renderer target-cell center; per-slot mapping + sensitivity.
##  - F-M21-V04-001 scene-frame proof: a dispatched agent stays visibly in flight
##    for a nonzero interval (self-driven only, no controller double-drive).
##  - F-M21-V04-004: tall portrait sanity; AgentLayer no-orphan after authenticated
##    arrival + deferred cleanup and after reset.
##
## Run:  godot --headless --path . -s res://tests/m21_v05_playtest_smoke.gd
## Exits 0 on success, 1 on any failure.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

var _fail := 0

func _initialize() -> void:
	var scene = load("res://scenes/debug/m21_real_art_vertical_slice.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame  # ensure Control layout has run

	var pres = inst.get_presentation()
	var agent_layer = inst.get_agent_layer()
	var renderer = pres.get_renderer()
	var views: Array = inst.get_slot_views()
	_ok(views.size() == 5, "five SlotViews present")

	# Per-slot anchor mapping round-trip (layout-derived), all five slots (crit 80).
	var anchors := []
	for i in range(views.size()):
		var anchor: Vector2 = views[i].get_spawn_anchor_global()
		anchors.append(anchor)
		var bl: Vector2 = pres.global_to_board_local(anchor)
		var back: Vector2 = pres.board_local_to_global(bl)
		_ok(anchor.distance_to(back) < 0.5, "slot %d anchor<->board-local mapping round-trips" % i)
	# Distinct slots have distinct anchors (crit 86 sensitivity: slot N != slot M).
	_ok(anchors[0].distance_to(anchors[4]) > 1.0, "distinct slots have distinct visible anchors")

	# Real C08 activation: agent spawn_origin/global-start match the clicked slot
	# anchor; route starts at the mapped board-local point (crit 75/76/77).
	var r = inst.request_slot(2)
	_ok(r != null and r.success, "visible C08 activation dispatches a real agent")
	if r != null and r.success:
		var agent = r.agent
		var mapped: Vector2 = pres.global_to_board_local(views[2].get_spawn_anchor_global())
		_ok(agent.spawn_origin.distance_to(mapped) < 0.001, "agent.spawn_origin == mapped board-local slot anchor")
		_ok(agent.get_parent() == agent_layer, "agent is an AgentLayer child")
		_ok(agent.global_position.distance_to(views[2].get_spawn_anchor_global()) < 1.0, "agent global start == visible slot anchor global")
		var pts: PackedVector2Array = agent.get_route_points()
		_ok(pts.size() >= 2 and pts[0].distance_to(mapped) < 0.001, "route first point == mapped board-local start")
		# Scene-frame proof (F-001): after real frames with ONLY self-drive, the agent
		# is still in flight on this long route (not teleported by a second driver).
		await process_frame
		_ok(agent.is_moving(), "agent still in flight after a real frame (single self-mover, no double-drive)")
		# Drive to arrival (test-driven) then prove renderer target-center alignment.
		for _i in range(512):
			if not is_instance_valid(agent) or not agent.is_moving():
				break
			agent.advance(1.0)
		var tpos: Vector2i = inst._board.get_cell_position(r.target_index)
		if is_instance_valid(agent):
			_ok(agent.global_position.distance_to(renderer.get_cell_center_global(tpos.x, tpos.y)) < 1.0, "arrived agent global == BoardRenderer target-cell center")
		# AgentLayer no-orphan after deferred cleanup (crit 133/134).
		await process_frame
		await process_frame
		_ok(_agent_children(agent_layer) == 0, "AgentLayer has no orphan ScrubbotAgent after arrival + frames")

	# Sensitivity: move a SlotView; its mapped start must change (crit 84).
	var before_map: Vector2 = pres.global_to_board_local(views[0].get_spawn_anchor_global())
	views[0].position += Vector2(37, 0)
	var after_map: Vector2 = pres.global_to_board_local(views[0].get_spawn_anchor_global())
	_ok(before_map.distance_to(after_map) > 0.01, "moving SlotView geometry changes the mapped board-local start (not a constant)")

	# Reset no-orphan (crit 110/135).
	inst.reset_presentation()
	await process_frame
	await process_frame
	_ok(_agent_children(agent_layer) == 0, "AgentLayer empty after reset + frames")
	var any_active := false
	for v in views:
		if v.is_active_visual(): any_active = true
	_ok(not any_active, "all slot active visuals false after reset")

	# Tall portrait sanity (crit 122-125): 1080x2400 containment + board not covered.
	var vp := Vector2(1080, 2400)
	var contained := true
	for v in views:
		var gr := Rect2(v.global_position, v.size)
		if gr.position.x < 0 or gr.position.y < 0 or gr.end.x > vp.x or gr.end.y > vp.y:
			contained = false
	_ok(contained, "tall 1080x2400: all five slot rects within content bounds")
	var slotbar = inst.get_node_or_null("SlotBar")
	_ok(slotbar != null and slotbar.position.y > (inst.BOARD_ORIGIN.y + inst.BOARD_DISPLAY.y), "tall portrait: slot bar is below the board, not covering it")

	inst.free()
	_done()

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
	print("M21 V05 playtest smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
