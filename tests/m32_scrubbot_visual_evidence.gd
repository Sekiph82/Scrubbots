extends SceneTree
## M32-C001 V01 — Scrubbot final-visuals evidence. Proves the canonical Scrubby travel
## visual attaches as a presentation-only child, that movement/route/progress truth is
## byte-identical with the visual enabled vs a plain agent, that the arrival/disappearance
## echo is a detached presentation-only observer of the authoritative committed clear, and
## that Retry leaves zero stale bot/echo. Presentation-only: never mutates gameplay truth.
##
## Run: godot --headless --path . -s res://tests/m32_scrubbot_visual_evidence.gd
## Exits 0 on success, 1 on any failure.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const ScrubbotRetireEchoController = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

var _fail := 0

func _initialize() -> void:
	await _unit_visual_attach_and_share()
	await _unit_movement_separation()
	_unit_echo_geometry_toggle_cap()
	await _integration_real_stack()
	_done()

func _board(w: int, h: int):
	var cells := PackedInt32Array(); cells.resize(w * h); cells.fill(0)
	var lvl = LevelData.new(1, "m32", "m32", "TEST", w, h, PackedStringArray(["#101010"]), cells)
	return BoardState.from_level_data(lvl)

# --- ScrubbotVisual: attaches, renders canonical body, suppresses circle, shares texture --
func _unit_visual_attach_and_share() -> void:
	var a := ScrubbotAgent.new()
	var v := ScrubbotVisual.new()
	a.add_child(v)
	a.set_process(false)
	get_root().add_child(a)   # entering the tree fires ScrubbotVisual._ready (next frame).
	await process_frame
	v.set_process(false)
	_ok(v.has_body(), "ScrubbotVisual builds a canonical Scrubby body sprite from the owner asset")
	_ok(v.get_body_texture() != null, "canonical gameplay texture loaded")
	_ok(a.is_visual_present(), "attached visual suppresses the agent debug-circle fallback")

	# A second visual shares the SAME cached texture object (no per-agent decode).
	var a2 := ScrubbotAgent.new()
	var v2 := ScrubbotVisual.new()
	a2.add_child(v2)
	a2.set_process(false)
	get_root().add_child(a2)
	await process_frame
	v2.set_process(false)
	_ok(v.get_body_texture() != null and v.get_body_texture() == v2.get_body_texture(),
		"canonical texture is shared across visuals, not decoded per bot")

	a.free(); a2.free()

# --- movement separation: the visual never moves the authoritative agent position ---------
func _unit_movement_separation() -> void:
	var board = _board(8, 8)
	var start := RouteRequest.center_of_index(board, 0)   # (0.5, 0.5)
	var target_index := 30                                # x=6,y=3 -> (6.5,3.5)
	var req = RouteRequest.for_target(board, start, target_index)
	_ok(req != null, "built a real route request")
	var pts := PackedVector2Array([req.start_position, req.target_position])
	# Two agents, identical assignment. One carries a live animating visual; the other is bare.
	var a_vis := ScrubbotAgent.new()
	var vis := ScrubbotVisual.new()
	a_vis.add_child(vis)
	a_vis.set_process(false)
	get_root().add_child(a_vis)
	var a_bare := ScrubbotAgent.new()
	a_bare.set_process(false)
	get_root().add_child(a_bare)
	await process_frame   # let ScrubbotVisual._ready build the body sprite.
	vis.set_process(false)

	_ok(a_vis.assign(1, 0, req, RouteResult.success_route(target_index, pts), 6.0), "visual agent assigned")
	_ok(a_bare.assign(1, 0, req, RouteResult.success_route(target_index, pts), 6.0), "bare agent assigned")

	var identical := true
	var body_moved := false
	for _step in range(40):
		a_vis.advance(0.05)
		a_bare.advance(0.05)
		vis.animate(0.05)   # local presentation animation runs alongside
		if not a_vis.get_local_position().is_equal_approx(a_bare.get_local_position()):
			identical = false
		if absf(a_vis.get_progress() - a_bare.get_progress()) > 1e-6:
			identical = false
		# The visual's own body sprite IS animating in local space (proof motion is present).
		if vis.has_body() and vis.get_child(0).position != Vector2.ZERO:
			body_moved = true
	_ok(identical, "agent position identical with an animating visual vs a bare agent")
	_ok(absf(a_vis.get_progress() - a_bare.get_progress()) < 1e-6, "route progress identical (visual vs bare)")
	_ok(a_vis.has_arrived() and a_bare.has_arrived(), "both agents reach exact one-shot completion")
	_ok(a_vis.get_local_position().is_equal_approx(req.target_position), "visual agent snapped to the exact endpoint")
	_ok(body_moved, "the visual body sprite animated locally (bob/lean/squash) without moving the agent")

	a_vis.free(); a_bare.free()

# --- retire echo: geometry, toggle, cap, aging, reset (mirrors the M31 observer pattern) ---
func _unit_echo_geometry_toggle_cap() -> void:
	var board = _board(6, 4)   # 6x4, index = y*6 + x
	var layer := Node2D.new()
	get_root().add_child(layer)
	var c = ScrubbotRetireEchoController.new()
	get_root().add_child(c)
	c.set_process(false)
	_ok(c.bind(layer, board), "echo controller binds to a real retire layer + board")

	_ok(c.request_echo(15), "one committed clear -> one requested echo")   # x=3,y=2 -> (3.5,2.5)
	_ok(c.get_active_count() == 1 and layer.get_child_count() == 1, "exactly one echo node created")
	_ok(layer.get_child(0).position.is_equal_approx(Vector2(3.5, 2.5)), "echo centered on the exact cleared cell")
	_ok(not c.request_echo(9999), "out-of-range index requests no echo")

	# Toggle off -> zero new + clears active; on -> resumes.
	c.set_enabled(false)
	_ok(not c.is_enabled() and c.get_active_count() == 0 and layer.get_child_count() == 0, "disable clears + blocks echoes")
	_ok(not c.request_echo(0), "disabled -> zero new echoes")
	c.set_enabled(true)

	# Concurrency cap: burst far beyond it, never exceed, exact suppression count.
	var cap: int = ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES
	var accepted := 0
	for i in range(cap * 3):
		if c.request_echo(i % board.get_cell_count()):
			accepted += 1
	_ok(c.get_active_count() == cap and layer.get_child_count() == cap, "echoes never exceed the cap (%d)" % cap)
	_ok(accepted == cap and c.get_peak_active() == cap, "exactly cap accepted; peak == cap; no unbounded queue")

	# Aging frees expired echoes; reset zeroes everything.
	c.age(ScrubbotRetireEchoController.LIFETIME)
	_ok(c.get_active_count() == 0 and layer.get_child_count() == 0, "echoes freed after their lifetime elapses")
	c.request_echo(1); c.request_echo(2)
	c.reset_for_new_attempt()
	_ok(c.get_active_count() == 0 and c.get_peak_active() == 0 and c.get_suppressed_count() == 0,
		"reset_for_new_attempt clears echoes + zeroes counters")

	c.free(); layer.free()

# --- real production stack: canonical bots, committed-clear echo, retry hygiene ------------
func _integration_real_stack() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	if not host.build():
		_ok(false, "integration: host build (%s)" % host.get_build_error())
		sub.free(); return
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)

	var echo = host.get_retire_echo()
	_ok(echo != null and echo.is_bound(), "integration: retire echo bound to the real presentation")
	var pres = host.get_screen().get_presentation()
	var retire_layer0 = pres.get_retire_fx_layer()
	_ok(retire_layer0 != null, "integration: presentation exposes a RetireFxLayer")
	var agent_layer = host.get_agent_layer()

	var clears := [0]
	var last_cell := [-1]
	host.get_clearing_loop().authenticated_clear.connect(func(_o, ti, _c, _a):
		clears[0] += 1; last_cell[0] = ti)

	var slots = host.get_slots()
	var supply = host.get_supply()
	var input = host.get_input_controller()
	var runtime = host.get_runtime()
	var board = host.get_board()
	var active_before_all: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)

	# Drive until a live agent exists so we can inspect its canonical visual.
	var saw_canonical_agent := false
	var shared_tex = null
	var tex_shared := true
	for _t in range(200):
		if slots.rightmost_empty_index() != -1 and supply.get_front(0) != null:
			input.activate_front(0)
		runtime.tick(1.0)
		for ch in agent_layer.get_children():
			if ch is ScrubbotAgent and is_instance_valid(ch):
				saw_canonical_agent = true
				# No debug circle in the normal production path: the visual took over.
				if not ch.is_visual_present():
					saw_canonical_agent = false
				var vc = null
				for cc in ch.get_children():
					if cc is ScrubbotVisual:
						vc = cc
				if vc == null or not vc.has_body():
					saw_canonical_agent = false
				elif shared_tex == null:
					shared_tex = vc.get_body_texture()
				elif vc.get_body_texture() != shared_tex:
					tex_shared = false
		if clears[0] >= 1:
			break
	_ok(saw_canonical_agent, "integration: a live production agent carries a canonical Scrubby visual (no debug circle)")
	_ok(tex_shared, "integration: all live bots share one canonical texture (no per-bot decode)")
	_ok(clears[0] >= 1, "integration: at least one authenticated clear fired")

	# A disappearance echo sits at the exact committed-cleared cell (not yet aged: process off).
	if clears[0] >= 1 and last_cell[0] >= 0:
		var pos: Vector2i = board.get_cell_position(last_cell[0])
		var found := false
		for ch in retire_layer0.get_children():
			if ch.position.is_equal_approx(Vector2(pos.x + 0.5, pos.y + 0.5)):
				found = true
		_ok(found, "integration: a retire echo sits at the exact committed-cleared cell (authoritative event source)")
	_ok(echo.get_peak_active() <= ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES, "integration: peak echoes within cap")

	# RetireFxLayer identity survives a representative small-phone relayout.
	sub.size = Vector2i(683, 1366)
	await process_frame
	host.get_screen().relayout()
	await process_frame
	_ok(pres.get_retire_fx_layer() == retire_layer0, "integration: RetireFxLayer identity survives relayout (agent presentation not stranded)")

	# Toggling the echo never changes gameplay truth: clears keep advancing while echo is OFF.
	echo.set_enabled(false)
	var cleared_before: int = host.get_clearing_loop().get_cleared_count()
	for _t in range(400):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col); break
		runtime.tick(1.0)
		if host.get_clearing_loop().get_cleared_count() > cleared_before:
			break
	_ok(host.get_clearing_loop().get_cleared_count() > cleared_before, "integration: clears continue with echo disabled")
	_ok(echo.get_active_count() == 0, "integration: echo disabled produced zero active echoes")
	echo.set_enabled(true)

	# --- density measurement (§10/§14): peak live Scrubby visuals + echo peak at 1x and 2x.
	# Presentation-only measurement on the real production stack; no device-FPS is invented.
	var peak_agents_1x := 0
	echo.reset_for_new_attempt()
	for _t in range(300):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col); break
		runtime.tick(1.0)
		var live := 0
		for ch in agent_layer.get_children():
			if ch is ScrubbotAgent and is_instance_valid(ch):
				live += 1
		peak_agents_1x = max(peak_agents_1x, live)
	var echo_peak_1x: int = echo.get_peak_active()
	runtime.toggle_speed()   # 2x
	var peak_agents_2x := 0
	echo.reset_for_new_attempt()
	for _t in range(300):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col); break
		runtime.tick(1.0)
		var live2 := 0
		for ch in agent_layer.get_children():
			if ch is ScrubbotAgent and is_instance_valid(ch):
				live2 += 1
		peak_agents_2x = max(peak_agents_2x, live2)
	var echo_peak_2x: int = echo.get_peak_active()
	print("  MEASURED density: peak live visuals 1x=%d 2x=%d | echo peak 1x=%d 2x=%d | echo cap=%d" % [
		peak_agents_1x, peak_agents_2x, echo_peak_1x, echo_peak_2x, ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES])
	_ok(echo_peak_1x <= ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES
		and echo_peak_2x <= ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES,
		"density: echo peak stays within the cap at 1x and 2x (bounded, no unbounded queue)")
	runtime.toggle_speed()   # back to 1x for retry

	# Retry hygiene: seed echoes, retry, prove nothing stale remains + counters reset.
	echo.request_echo(0); echo.request_echo(1)
	_ok(echo.get_active_count() > 0, "integration: echoes seeded before retry")
	_ok(host.retry(), "integration: retry succeeds")
	_ok(echo.get_active_count() == 0 and retire_layer0.get_child_count() == 0, "integration: retry cleared stale echoes")
	_ok(echo.get_peak_active() == 0 and echo.get_suppressed_count() == 0, "integration: retry reset echo counters")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == active_before_all, "integration: retry restored full ACTIVE board")

	sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M32 scrubbot-visual evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
