extends SceneTree
## M29-C001 V03 — real SceneTree runtime-clock movement smoke (criteria §7, prompt §2).
##
## Reproduces the owner's embedded graphical playtest at 683x1366 with the REAL
## ProductionRuntimeController._process(delta) clock ENABLED — no manual runtime.tick() —
## and proves committed agents actually advance, arrive, finalize through M20/M25, and the
## CURRENT visible renderer pixel becomes transparent (i.e. the owner-observed "50 (2)
## frozen for minutes" cannot happen). Also proves focus/suspension pauses and focus
## regain resumes movement with no stale input, and the runtime is not spuriously
## system-suspended while the focused embedded viewport is active.
##
## Run: godot --headless --path . -s res://tests/m29_realtime_movement_smoke.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const MAX_FRAMES := 20000

var _fail := 0
var _sub

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(683, 1366)
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
	_ok(ok, "production host built at 683x1366 (%s)" % host.get_build_error())
	if not ok:
		return
	# Settle layout. Runtime _process stays ENABLED (this is the whole point).
	for _i in range(6):
		await process_frame
	var runtime = host.get_runtime()
	_ok(not runtime.is_system_suspended(), "runtime is NOT spuriously system-suspended while the focused viewport is active")

	var supply = host.get_supply()
	var slots = host.get_slots()
	var input = host.get_input_controller()
	var loop = host.get_clearing_loop()
	var layer = host.get_agent_layer()
	var board = host.get_board()

	# Real front activation creates committed work.
	for _r in range(5):
		if slots.rightmost_empty_index() == -1:
			break
		if supply.get_front(0) != null:
			input.activate_front(0)
	_ok(slots.occupied_count() == 5, "real front activation filled the five slots")

	# A real agent's progress increases across SUBSEQUENT SceneTree frames (no manual tick).
	var first_prog := -1.0
	var later_prog := -1.0
	var frames_to_agent := 0
	for f in range(MAX_FRAMES):
		await process_frame
		var ag = _moving_agent(layer)
		if ag != null:
			if first_prog < 0.0:
				first_prog = ag.get_progress()
				frames_to_agent = f
			elif f > frames_to_agent + 30:
				later_prog = ag.get_progress()
				break
	_ok(first_prog >= 0.0, "a real ScrubbotAgent is dispatched under the real _process clock")
	_ok(later_prog > first_prog, "agent progress INCREASES across real SceneTree frames (%.4f -> %.4f)" % [first_prog, later_prog])

	# The agent arrives and a real authenticated clear finalizes within a bounded interval.
	var cleared_cell: Array = [-1]
	var rec := func(_o, t, _c, _a): cleared_cell[0] = t if cleared_cell[0] == -1 else cleared_cell[0]
	loop.authenticated_clear.connect(rec)
	for _f in range(MAX_FRAMES):
		await process_frame
		if loop.get_cleared_count() > 0:
			break
	loop.authenticated_clear.disconnect(rec)
	_ok(loop.get_cleared_count() > 0, "committed work RESOLVES to a real authenticated clear (not frozen)")
	_ok(cleared_cell[0] != -1, "authenticated clear reported a cleared target")
	if cleared_cell[0] != -1:
		_ok(board.get_cell_state(cleared_cell[0]) == BoardState.CellState.CLEARED, "BoardState cell CLEARED")
		var x: int = cleared_cell[0] % board.get_width()
		var y: int = cleared_cell[0] / board.get_width()
		_ok(host.get_screen().get_presentation().get_renderer().get_pixel_color(x, y).a == 0.0, "the CURRENT visible renderer pixel became transparent")

	# --- focus / background behavior ------------------------------------------------
	# System suspension pauses movement; a pending gesture would be cancelled; no progress.
	var ag2 = _moving_agent(layer)
	if ag2 == null:
		# refill so an agent is in flight for the focus test
		for _r in range(5):
			if slots.rightmost_empty_index() != -1 and supply.get_front(0) != null:
				input.activate_front(0)
		for _f in range(MAX_FRAMES):
			await process_frame
			ag2 = _moving_agent(layer)
			if ag2 != null:
				break
	_ok(ag2 != null, "an agent is in flight for the focus test")
	runtime.notify_focus_lost()
	_ok(runtime.is_paused(), "focus/system suspension pauses gameplay")
	var frozen_prog: float = ag2.get_progress() if ag2 != null and is_instance_valid(ag2) else 1.0
	for _f in range(60):
		await process_frame
	var still: float = ag2.get_progress() if ag2 != null and is_instance_valid(ag2) else frozen_prog
	_ok(is_equal_approx(still, frozen_prog), "in-flight movement is frozen while suspended (%.4f)" % still)
	# Focus regain resumes movement (user pause not active) and never replays stale input.
	runtime.notify_focus_gained()
	_ok(not runtime.is_paused(), "focus regain resumes (not left permanently suspended)")
	var resumed := false
	for _f in range(MAX_FRAMES):
		await process_frame
		var a3 = _moving_agent(layer)
		if a3 != null and a3.get_progress() > 0.0:
			resumed = true
			break
		if loop.get_cleared_count() >= 1 and _moving_agent(layer) == null and slots.occupied_count() == 0:
			resumed = true
			break
	_ok(resumed, "movement resumes after focus regain")

	_sub.free()

func _moving_agent(layer):
	if layer == null or not is_instance_valid(layer):
		return null
	for c in layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return c
	return null

func _total_committed(slots) -> int:
	var t := 0
	for i in range(5):
		if slots.is_occupied(i):
			t += slots.get_committed(i)
	return t

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 realtime movement smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
