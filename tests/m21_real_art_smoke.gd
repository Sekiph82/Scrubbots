extends SceneTree
## M21-C001 V01 — dedicated real-art full-level smoke (frame/queue-free evidence).
##
## The synchronous root runner cannot prove deferred agent destruction across real
## SceneTree frames. This headless smoke loads the COMMITTED real Level Data,
## builds a full REAL production gameplay bundle (no M20 fault seams), and runs the
## whole 400-cell "Hazard Bot" board to completion through the real
## CompleteClearingLoop, then proves the exact final state, renderer transparency,
## and no-orphan cleanup after frames, and records CPU/headless timing. The
## reference composite is generated separately by
## res://tools/build_m21_reference_composite.gd (F-M21-STRICT-004).
##
## Automation here is TEST/DEBUG orchestration only — it adds no autoplay, refill,
## queue, cooldown, scoring, or progression to production gameplay.
##
## Run:  godot --headless --path . -s res://tests/m21_real_art_smoke.gd
## Exits 0 on success, 1 on any failure.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const SOURCE_PATH := "res://assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png"
const BG01 := Color8(32, 37, 51, 255)
const EXPECTED_COUNTS := {0: 30, 1: 5, 2: 298, 3: 11, 4: 56}  # local index -> count

func _initialize() -> void:
	var lr = LevelLoader.load_from_path(LEVEL_PATH)
	if not lr.is_ok():
		_done(false, "level load failed: %s" % str(lr.errors)); return
	var lvl = lr.level_data
	var board = BoardState.from_level_data(lvl)
	var w: int = board.get_width(); var h: int = board.get_height()

	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var dispatcher = ScrubbotDispatcher.new(); root.add_child(dispatcher)
	if not dispatcher.bind(board, selector, reservations, routing, routing_access, select_access):
		_done(false, "dispatcher bind failed"); return
	var renderer = BoardRenderer.new(); root.add_child(renderer)
	renderer.configure(board, lvl.palette, Vector2(400, 400))

	# Five slots against the five local palette identities (index i -> palette i).
	var slots = SlotSystem.new()
	var cfg = slots.configure([0, 1, 2, 3, 4], lvl.palette.size())
	if not cfg["ok"]:
		_done(false, "slot configure failed: %s" % str(cfg)); return
	for i in range(5):
		if slots.get_slot_palette_id(i) != i:
			_done(false, "slot %d palette identity mismatch" % i); return

	var loop = CompleteClearingLoop.new()
	if not loop.bind(board, slots, candidates, reservations, dispatcher, renderer):
		_done(false, "loop bind failed"); return

	# Initial renderer must equal the approved source at EVERY logical coordinate.
	var src := Image.new()
	if src.load(SOURCE_PATH) != OK:
		_done(false, "source load failed"); return
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			if renderer.get_pixel_color(x, y) != src.get_pixel(x, y):
				_done(false, "initial renderer mismatch at %d,%d" % [x, y]); return

	# --- full real-art run -------------------------------------------------
	var cheap: Array = [Vector2(-1.5, h * 0.5), Vector2(w + 1.5, h * 0.5),
		Vector2(w * 0.5, -1.5), Vector2(w * 0.5, h + 1.5),
		Vector2(-1.5, -1.5), Vector2(w + 1.5, -1.5), Vector2(-1.5, h + 1.5), Vector2(w + 1.5, h + 1.5)]
	var full: Array = []
	for y in h:
		full.append(Vector2(-1.5, float(y) + 0.5)); full.append(Vector2(w + 1.5, float(y) + 0.5))
	for x in w:
		full.append(Vector2(float(x) + 0.5, -1.5)); full.append(Vector2(float(x) + 0.5, h + 1.5))
	var slot_order := [2, 0, 1, 3, 4]  # C08 (perimeter/frame) first
	var colors_cleared := {}

	var t0 := Time.get_ticks_usec()
	var cleared := 0
	var guard := 0
	while cleared < 400 and guard < 6000:
		guard += 1
		var idx := _try_round(loop, slot_order, cheap, board, colors_cleared)
		if idx == -1:
			idx = _try_round(loop, slot_order, full, board, colors_cleared)
		if idx == -1:
			_done(false, "deadlock at cleared=%d (active=%d)" % [cleared, board.count_cells_by_state(BoardState.CellState.ACTIVE)]); return
		cleared += 1
	var elapsed_s := float(Time.get_ticks_usec() - t0) / 1000000.0

	# --- exact final assertions -------------------------------------------
	if loop.get_cleared_count() != 400:
		_done(false, "loop cleared_count=%d" % loop.get_cleared_count()); return
	if board.count_cells_by_state(BoardState.CellState.CLEARED) != 400:
		_done(false, "board CLEARED=%d" % board.count_cells_by_state(BoardState.CellState.CLEARED)); return
	if board.count_cells_by_state(BoardState.CellState.ACTIVE) != 0:
		_done(false, "board ACTIVE=%d" % board.count_cells_by_state(BoardState.CellState.ACTIVE)); return
	for ci in range(5):
		if candidates.count_candidates(ci, null) != 0:
			_done(false, "candidate bucket %d not empty" % ci); return
	if colors_cleared.size() != 5:
		_done(false, "not all 5 colors cleared: %s" % str(colors_cleared.keys())); return
	if reservations.get_reservation_count() != 0:
		_done(false, "reservations=%d" % reservations.get_reservation_count()); return
	if dispatcher.get_active_count() != 0:
		_done(false, "dispatcher active=%d" % dispatcher.get_active_count()); return

	# Renderer: every logical pixel transparent; BG01 never a cell color.
	for y in h:
		for x in w:
			if renderer.get_pixel_color(x, y).a != 0.0:
				_done(false, "renderer pixel %d,%d not alpha 0" % [x, y]); return
	for entry in lvl.palette:
		if String(entry).to_upper().begins_with("#202533"):
			_done(false, "BG01 leaked into LevelData palette"); return

	# --- frame/queue-free cleanup -----------------------------------------
	await process_frame
	await process_frame
	var orphans := 0
	for c in dispatcher.get_children():
		if c is ScrubbotAgent:
			orphans += 1
	if orphans != 0:
		_done(false, "%d orphan ScrubbotAgent under dispatcher after frames" % orphans); return
	if dispatcher.get_child_count() != 0:
		_done(false, "dispatcher child count=%d after frames" % dispatcher.get_child_count()); return

	# NOTE: the reference composite is produced by the dedicated reproducible
	# generator res://tools/build_m21_reference_composite.gd (F-M21-STRICT-004), not
	# by this smoke, so there is a single deterministic source of that evidence.
	print("M21 real-art smoke: clears=%d elapsed_cpu_s=%.3f guard_iters=%d colors_cleared=%d" % [
		cleared, elapsed_s, guard, colors_cleared.size()])
	print("M21 headless-timing note: %.3fs is CPU/headless wall time, NOT a mobile FPS/GPU claim (AL-003)." % elapsed_s)
	_done(true, "full 400-cell real-art run cleared; final state + renderer transparency + no-orphan verified")

func _try_round(loop, slot_order, origins, board, colors_cleared) -> int:
	for slot_id in slot_order:
		for origin in origins:
			var r = loop.activate_slot(slot_id, origin, 6.0)
			if r.success:
				var color: int = board.get_color_id(r.target_index)
				for _i in range(256):
					if not r.agent.is_moving():
						break
					r.agent.advance(1.0)
				colors_cleared[color] = true
				return r.target_index
	return -1

func _done(success: bool, msg: String) -> void:
	print("M21 real-art smoke: %s — %s" % ["PASS" if success else "FAIL", msg])
	quit(0 if success else 1)
