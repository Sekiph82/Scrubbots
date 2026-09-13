extends SceneTree
## M21-C001 V06 — genuine tall-layout (1080x2400) validation-only smoke.
##
## Closes the frozen V05 evidence residual R-V05-TALL-001: V05 only compared the
## default-layout rects against a local Vector2(1080,2400) constant; it never
## established/observed a real second 1080x2400 layout configuration.
##
## This smoke establishes a REAL second layout configuration by hosting the owner
## scene inside a SubViewport whose size is set to 1080x2400 (a reliable headless
## Godot mechanism that drives real Control layout and does not touch project.godot),
## directly observes that the SubViewport size actually became 1080x2400 (distinct
## from the canonical 1080x2160 default), awaits layout frames, and re-proves the
## visible-slot-anchor -> BoardPresentation.global_to_board_local -> real
## ScrubbotAgent start / route / arrival / cleanup chain under that tall config.
##
## Validation-only: it changes no production/presentation source. Movement is the
## agent's own; the smoke drives arrival via advance() as test orchestration only.
##
## Run:  godot --headless --path . -s res://tests/m21_v06_tall_layout_smoke.gd
## Exits 0 on success, 1 on any failure.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const REFERENCE_SIZE := Vector2i(1080, 2160)   # canonical default (project.godot)
const TALL_SIZE := Vector2i(1080, 2400)        # genuine second configuration

var _fail := 0

func _initialize() -> void:
	var default_root_size: Vector2i = get_root().size
	print("reference/default root size observed: %s (canonical %s)" % [str(default_root_size), str(REFERENCE_SIZE)])

	# Establish a REAL second 1080x2400 layout configuration via a SubViewport.
	var sub := SubViewport.new()
	sub.size = TALL_SIZE
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)

	var scene = load("res://scenes/debug/m21_real_art_vertical_slice.tscn")
	var inst = scene.instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	await process_frame
	await process_frame

	# Directly observe the actual configuration used for Control layout (crit 35/36).
	# Sensitivity: if the tall step were removed this would not equal TALL_SIZE.
	_ok(sub.size == TALL_SIZE, "SubViewport layout size is genuinely 1080x2400 (observed %s)" % str(sub.size))
	_ok(sub.size != REFERENCE_SIZE, "tall config is distinct from the canonical 1080x2160 default")
	var tall_bounds := Vector2(float(sub.size.x), float(sub.size.y))

	var pres = inst.get_presentation()
	var agent_layer = inst.get_agent_layer()
	var renderer = pres.get_renderer()
	var views: Array = inst.get_slot_views()
	_ok(views.size() == 5, "exactly five SlotViews under the tall config")

	# All five laid-out slot rects within the actual tall content bounds (crit 43/44).
	var contained := true
	for v in views:
		var gr := Rect2(v.global_position, v.size)
		if gr.position.x < 0 or gr.position.y < 0 or gr.end.x > tall_bounds.x or gr.end.y > tall_bounds.y:
			contained = false
	_ok(contained, "all five slot rects within the actual 1080x2400 bounds")

	# Board region visible; slot bar does not cover it (crit 46/47).
	var board_bottom: float = inst.BOARD_ORIGIN.y + inst.BOARD_DISPLAY.y
	var slotbar = inst.get_node_or_null("SlotBar")
	_ok(slotbar != null and slotbar.position.y > board_bottom, "slot bar sits below the board (no overlap) under tall config")
	_ok(board_bottom <= tall_bounds.y, "board region fits within tall bounds")

	# Anchor -> board-local -> real agent-start chain under the genuine tall layout.
	var slot_id := 2  # C08 reachable on fresh Hazard Bot
	var anchor_global: Vector2 = views[slot_id].get_spawn_anchor_global()
	var mapped: Vector2 = pres.global_to_board_local(anchor_global)
	inst._last_result = null
	# Real Button signal chain (crit 54): pressed -> _on_pressed -> slot_activated ->
	# scene handler -> real CompleteClearingLoop.
	views[slot_id].pressed.emit()
	var r = inst._last_result
	_ok(r != null and r.success, "tall-config visible-slot Button path dispatches a real assignment")
	var agent = null
	var target_index := -1
	var owner_id := -1
	if r != null and r.success:
		agent = r.agent
		target_index = r.target_index
		owner_id = r.owner_id
		_ok(inst._board.get_color_id(target_index) == slot_id, "activated color == slot palette id (C08)")
		_ok(agent.get_parent() == agent_layer, "real agent is an AgentLayer child")
		_ok(agent.spawn_origin.distance_to(mapped) < 0.001, "agent.spawn_origin == mapped tall-layout anchor")
		_ok(agent.global_position.distance_to(anchor_global) < 1.0, "agent initial global == tall visible slot anchor")
		var pts: PackedVector2Array = agent.get_route_points()
		_ok(pts.size() >= 2 and pts[0].distance_to(mapped) < 0.001, "route first point == mapped board-local start")
		var tpos: Vector2i = inst._board.get_cell_position(target_index)
		# Drive to authenticated arrival (test orchestration); M20 clears.
		for _i in range(512):
			if not is_instance_valid(agent) or not agent.is_moving():
				break
			agent.advance(1.0)
		if is_instance_valid(agent):
			_ok(agent.global_position.distance_to(renderer.get_cell_center_global(tpos.x, tpos.y)) < 1.0, "arrival global == BoardRenderer target-cell center (tall)")
		_ok(inst._board.get_cell_state(target_index) == 1, "authenticated M20 arrival cleared exactly the selected target (CLEARED)")
		await process_frame
		await process_frame
		_ok(_agent_children(agent_layer) == 0, "AgentLayer has zero ScrubbotAgent children after deferred cleanup (tall)")
		# Concrete tuple for the log.
		print("TALL_TUPLE ref=%s tall=%s slot=%d color_pid=%d anchor_global=%s mapped_local=%s spawn_origin=%s route0=%s owner=%d target=%d coord=%s agent_init_global=%s cell_center_global=%s cleanup_children=%d" % [
			str(REFERENCE_SIZE), str(sub.size), slot_id, slot_id, str(anchor_global), str(mapped),
			str(agent.spawn_origin if is_instance_valid(agent) else mapped), str(pts[0]), owner_id,
			target_index, str(inst._board.get_cell_position(target_index)),
			str(anchor_global), str(renderer.get_cell_center_global(inst._board.get_cell_position(target_index).x, inst._board.get_cell_position(target_index).y)),
			_agent_children(agent_layer)])

	inst.free()
	sub.free()
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
	print("M21 V06 tall-layout smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
