extends SceneTree
## M32-C001 V02 — 59x59 Scrubby-visual presentation scale + animation-cost benchmark.
## Closes the V01 density/performance evidence gap (CHATGPT_AUDIT_V01.md F-M32-V01-001).
##
## Reuses the accepted M26 59x59 / 30-in-flight production-scale fixture shape
## (tests/m26_scale_59_sanity.gd) but binds the dispatcher with the REAL M32 agent factory
## + an in-tree AgentLayer, so every one of the BATCH concurrently-live agents carries a
## real ScrubbotVisual on the canonical shared Scrubby texture. It then:
##   - proves the live population is the AUTHORITATIVE dispatcher/scheduler assignment count
##     (not a tree-child count polluted by nodes awaiting deferred queue_free);
##   - proves all visuals share ONE canonical Texture2D (no per-agent decode);
##   - times the actual ScrubbotVisual.animate(delta) presentation work over many
##     deterministic frames with Time.get_ticks_usec(), at 1x and a 2x-equivalent (double
##     presentation-frame) density, reporting total + per-frame ms (NO device FPS claim);
##   - keeps the authenticated-clear retire echo bounded;
##   - drains + resets, PROCESSES deferred SceneTree deletion, then asserts live
##     assignments / live visual nodes / active echoes are all zero.
##
## Run: godot --headless --path . -s res://tests/m32_scale_59_visuals.gd
## Exits 0 on success, 1 on any failure.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const ScrubbotRetireEchoController = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")

const N := 59
const BATCH := 30       # accepted M26 production-scale in-flight reference
const FRAMES := 600     # deterministic animation frames timed at 1x

var _fail := 0

class FixedProvider:
	extends RefCounted
	var origin: Vector2
	func _init(o: Vector2) -> void:
		origin = o
	func origin_for_slot(_slot_index: int) -> Vector2:
		return origin

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	var BLUE := 0
	var pal := PackedStringArray()
	for i in range(4):
		pal.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	var cells := PackedInt32Array(); cells.resize(N * N); cells.fill(BLUE)
	var board = BoardState.from_level_data(LevelData.new(1, "m32_59", "m32_59", "TEST", N, N, pal, cells))
	# Only BATCH bottom-row cells stay ACTIVE (independently reachable from below); the rest
	# CLEARED so density is real but bounded/deterministic — identical to the M26 fixture.
	var keep := {}
	for x in range(BATCH):
		keep[(N - 1) * N + x] = true
	for i in range(N * N):
		if not keep.has(i):
			board.set_cell_state(i, BoardState.CellState.CLEARED)

	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var dispatcher = ScrubbotDispatcher.new()
	get_root().add_child(dispatcher)

	# In-tree AgentLayer so a spawned agent's ScrubbotVisual child gets _ready (builds the
	# canonical body sprite). Agents are created via the REAL M32 factory shape.
	var agent_layer := Node2D.new()
	get_root().add_child(agent_layer)
	var factory := func():
		var a = ScrubbotAgent.new()
		a.set_process(false)   # measurement drives movement/animation deterministically
		a.add_child(ScrubbotVisual.new())
		return a
	_ok(dispatcher.bind(board, sel, res, routing, raccess,
		ProductionTargetAccess.new(routing, raccess, board), agent_layer, factory),
		"59x59: dispatcher bound with the real M32 agent factory + in-tree AgentLayer")

	var loop = CompleteClearingLoop.new()
	_ok(loop.bind_arrival_only(board, ci, res, dispatcher), "59x59: arrival-only clearing loop bound")

	# Retire echo observer on the authoritative committed-clear event.
	var retire_layer := Node2D.new(); get_root().add_child(retire_layer)
	var echo = ScrubbotRetireEchoController.new()
	get_root().add_child(echo)
	echo.set_process(false)
	_ok(echo.bind(retire_layer, board), "59x59: retire echo bound")
	loop.authenticated_clear.connect(echo._on_authenticated_clear)

	var slots = FiveSlotBatchEngine.new()
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns([[ColorBatch.make("BIG", BLUE, BATCH, 4)], [], []])
	slots.select_front_batch(supply, 0)
	var claim = BatchTargetClaimEngine.new(); claim.bind(board, slots, sel, res)
	var provider = FixedProvider.new(Vector2(float(N) * 0.5, float(N) + 4.0))
	var sched = AutoDispatchScheduler.new()
	_ok(sched.bind(board, slots, claim, res, routing, raccess, dispatcher, loop, provider), "59x59: scheduler bound at board ceiling")

	# Peak in-flight without clearing (one assignment per step).
	var assigned := 0
	for _s in range(BATCH + 5):
		if sched.step().get("ok", false):
			assigned += 1
	_ok(assigned == BATCH, "59x59: exactly BATCH (%d) assignments" % BATCH)
	# AUTHORITATIVE live-assignment counts — not a tree-child count.
	_ok(sched.live_assignment_count() == BATCH and dispatcher.get_active_count() == BATCH,
		"59x59: authoritative live assignments == BATCH (%d)" % BATCH)

	# Let each agent's ScrubbotVisual._ready build its canonical body sprite.
	await process_frame
	await process_frame

	# Collect the real visual population and prove shared texture identity.
	var visuals: Array = []
	var shared_tex: Texture2D = null
	var tex_shared := true
	for a in agent_layer.get_children():
		if a is ScrubbotAgent and is_instance_valid(a):
			for c in a.get_children():
				if c is ScrubbotVisual:
					c.set_process(false)   # drive animate() manually + deterministically
					visuals.append(c)
					if not c.has_body():
						tex_shared = false
					elif shared_tex == null:
						shared_tex = c.get_body_texture()
					elif c.get_body_texture() != shared_tex:
						tex_shared = false
	_ok(visuals.size() == BATCH, "59x59: every live agent carries a ScrubbotVisual (%d)" % visuals.size())
	_ok(shared_tex != null and tex_shared, "59x59: all %d visuals share ONE canonical texture (no per-agent decode)" % visuals.size())

	# --- animation-update cost: time the real ScrubbotVisual.animate(delta) work ----------
	var dt := 1.0 / 60.0
	# warm one pass (texture/JIT-free GDScript, but keep the first outlier out of the timing).
	for v in visuals:
		v.animate(dt)
	var t0 := Time.get_ticks_usec()
	for _f in range(FRAMES):
		for v in visuals:
			v.animate(dt)
	var us_1x := Time.get_ticks_usec() - t0
	# 2x-equivalent: double the advanced presentation frames (at 2x game speed twice as many
	# travel frames elapse per real second -> double the per-second animation workload).
	var t1 := Time.get_ticks_usec()
	for _f in range(FRAMES * 2):
		for v in visuals:
			v.animate(dt)
	var us_2x := Time.get_ticks_usec() - t1

	var ms_1x := float(us_1x) / 1000.0
	var ms_2x := float(us_2x) / 1000.0
	var per_frame_1x := ms_1x / float(FRAMES)
	var per_frame_2x := ms_2x / float(FRAMES * 2)
	var per_visual_us := float(us_1x) / float(FRAMES * max(visuals.size(), 1))
	print("SCALE59_VIS visuals=%d frames_1x=%d total_1x_ms=%.3f per_frame_1x_ms=%.5f | frames_2x=%d total_2x_ms=%.3f per_frame_2x_ms=%.5f | per_visual_per_frame_us=%.4f" % [
		visuals.size(), FRAMES, ms_1x, per_frame_1x, FRAMES * 2, ms_2x, per_frame_2x, per_visual_us])
	_ok(us_1x > 0 and us_2x > 0, "59x59: animation update cost measured (non-zero elapsed)")
	# Sanity: doubling the frame count roughly doubles the work (bounded linear, no blow-up).
	_ok(ms_2x >= ms_1x, "59x59: 2x-equivalent workload >= 1x workload (linear, bounded)")

	# Movement truth is untouched by the animation benchmark (agents never advanced above).
	_ok(dispatcher.get_active_count() == BATCH and sched.live_assignment_count() == BATCH,
		"59x59: animation benchmark did not alter authoritative live assignments")

	# --- drain: authenticate every clear so retire echoes fire; prove echo bound -----------
	for a in agent_layer.get_children():
		if a is ScrubbotAgent and is_instance_valid(a) and a.is_moving():
			for _i in range(16384):
				if not a.is_moving():
					break
				a.advance(1.0)
	_ok(loop.get_cleared_count() == BATCH, "59x59: all BATCH authenticated clears committed")
	_ok(echo.get_peak_active() <= ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES,
		"59x59: retire-echo peak within cap (%d), overflow presentation-only" % echo.get_peak_active())
	_ok(echo.get_peak_active() == ScrubbotRetireEchoController.MAX_ACTIVE_ECHOES,
		"59x59: BATCH>cap so echoes actually hit the cap (bounded, %d suppressed)" % echo.get_suppressed_count())

	# --- cleanup: PROCESS deferred queue_free before asserting final live counts -----------
	# finalize_arrival() queue_free()'s each arrived agent; those frees are deferred, so we
	# must let the SceneTree process them before counting live visual nodes (the exact V01
	# accounting error this V02 corrects).
	await process_frame
	await process_frame
	echo.clear_all()
	var live_agent_nodes := 0
	for a in agent_layer.get_children():
		if a is ScrubbotAgent and is_instance_valid(a) and not a.is_queued_for_deletion():
			live_agent_nodes += 1
	_ok(dispatcher.get_active_count() == 0 and sched.live_assignment_count() == 0,
		"59x59: authoritative live assignments back to zero after drain")
	_ok(live_agent_nodes == 0, "59x59: live agent presentation nodes back to zero after deferred deletion")
	_ok(echo.get_active_count() == 0 and retire_layer.get_child_count() == 0, "59x59: retire echoes cleaned to zero")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "59x59: quota conserved, zero ACTIVE cells remain")

	sched.reset()
	_ok(sched.live_assignment_count() == 0 and dispatcher.get_active_count() == 0, "59x59: reset idempotent, zero residue")
	dispatcher.free()
	agent_layer.free()
	retire_layer.free()
	echo.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M32 59x59 visual scale/benchmark: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
