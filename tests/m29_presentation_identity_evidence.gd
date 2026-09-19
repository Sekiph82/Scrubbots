extends SceneTree
## M29-C001 V03 — BoardPresentation identity evidence (F-M29-MANUAL-001, criteria §1-§6).
##
## Proves the production presentation-node identity is stable across responsive relayout:
## the SAME BoardRenderer and AgentLayer the M29 runtime binds M20/dispatcher to remain
## the exact instances on screen after any number of relayouts/resizes, so authoritative
## clears and live agents never become invisible behind a duplicated renderer/layer.
##
## Run: godot --headless --path . -s res://tests/m29_presentation_identity_evidence.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

var _fail := 0
var _sub

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	var host = await _make_host(Vector2i(1080, 2160))
	if host == null:
		return
	var screen = host.get_screen()
	var pres = screen.get_presentation()
	var r0 = pres.get_renderer()
	var l0 = pres.get_agent_layer()
	var strip = screen.get_five_slot_strip()
	_ok(r0 != null and l0 != null, "presentation has a renderer + agent layer after build")
	_ok(_renderer_count(pres) == 1, "exactly one BoardRenderer child at build")
	_ok(_agentlayer_count(pres) == 1, "exactly one AgentLayer child at build")

	# Spawn a real in-flight agent, advance it partway deterministically (runtime process
	# disabled), then capture its identity/progress.
	host.get_runtime().set_process(false)
	var supply = host.get_supply()
	var slots = host.get_slots()
	var input = host.get_input_controller()
	var runtime = host.get_runtime()
	for _r in range(5):
		if slots.rightmost_empty_index() == -1:
			break
		if supply.get_front(0) != null:
			input.activate_front(0)
	# Drive with a SMALL delta until at least one agent is moving, then advance a little
	# more so the captured agent stays mid-flight (does not arrive+free) across the resize.
	for _t in range(400):
		runtime.tick(0.1)
		if _moving_agent(l0) != null:
			break
	for _t in range(5):
		runtime.tick(0.1)
	var agent = _moving_agent(l0)
	_ok(agent != null, "a real ScrubbotAgent is in flight in the agent layer")
	if agent == null:
		return
	var prog_before: float = agent.get_progress()
	var origin_before: Vector2 = host.get_origin_provider().origin_for_slot(0)

	# --- resize / relayout transition to the owner's embedded viewport size ---
	_sub.size = Vector2i(683, 1366)
	await process_frame
	await process_frame
	screen.relayout()
	await process_frame
	await process_frame

	# §1/§2 identity preserved.
	_ok(pres.get_renderer() == r0, "renderer identity unchanged across relayout/resize")
	_ok(pres.get_agent_layer() == l0, "agent layer identity unchanged across relayout/resize")
	_ok(_renderer_count(pres) == 1, "still exactly one BoardRenderer child after relayout")
	_ok(_agentlayer_count(pres) == 1, "still exactly one AgentLayer child after relayout")
	# §4 live agent survives.
	_ok(is_instance_valid(agent), "in-flight agent instance survives relayout")
	_ok(agent.get_parent() == l0, "in-flight agent keeps the same parent AgentLayer")
	_ok(is_equal_approx(agent.get_progress(), prog_before), "agent route/progress truth survives relayout (%.4f)" % agent.get_progress())
	# dispatcher binding still equals the CURRENT visible AgentLayer (M20 renderer is r0,
	# proven == current by the renderer-identity assertion above).
	_ok(host.get_dispatcher()._agent_parent == pres.get_agent_layer(), "dispatcher AgentLayer == current visible AgentLayer")
	# V02 exact visible slot-origin mapping still correct after resize.
	var expected0: Vector2 = pres.global_to_board_local(strip.get_slot_anchor_global(0))
	_ok(host.get_origin_provider().origin_for_slot(0).is_equal_approx(expected0), "V02 exact visible slot-origin mapping preserved after resize")
	_ok(not host.get_origin_provider().origin_for_slot(0).is_equal_approx(origin_before), "origin moved with the responsive layout")

	# §5 visible clear coherence AFTER relayout: drive to an authenticated clear and prove
	# the CURRENT visible renderer's pixel is transparent.
	var loop = host.get_clearing_loop()
	var cleared_cell: Array = [-1]
	var rec := func(_o, target_index, _c, _a): cleared_cell[0] = target_index
	loop.authenticated_clear.connect(rec)
	for _t in range(4000):
		if slots.rightmost_empty_index() != -1 and supply.get_front(0) != null:
			input.activate_front(0)
		runtime.tick(1.0)
		if cleared_cell[0] != -1:
			break
	loop.authenticated_clear.disconnect(rec)
	_ok(cleared_cell[0] != -1, "an authenticated clear occurred after relayout")
	if cleared_cell[0] != -1:
		var board = host.get_board()
		_ok(board.get_cell_state(cleared_cell[0]) == BoardState.CellState.CLEARED, "BoardState cell is CLEARED")
		var x: int = cleared_cell[0] % board.get_width()
		var y: int = cleared_cell[0] / board.get_width()
		_ok(pres.get_renderer().get_pixel_color(x, y).a == 0.0, "the CURRENT visible renderer's cleared pixel alpha is 0")

	_sub.free()

func _make_host(size: Vector2i):
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	return host

func _renderer_count(node) -> int:
	var n := 0
	for c in node.get_children():
		if c is BoardRenderer:
			n += 1
	return n

func _agentlayer_count(node) -> int:
	var n := 0
	for c in node.get_children():
		if c.name == "AgentLayer":
			n += 1
	return n

func _moving_agent(layer):
	for c in layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return c
	return null

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 presentation identity evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
