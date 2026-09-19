extends SceneTree
## M31-C001 V01 — Cleaning-effects evidence (event / geometry / toggle / concurrency /
## reduced / retry). Presentation-only: proves the cue observer never mutates gameplay
## truth, maps to the exact cleared cell, honours the toggle + finite concurrency cap,
## and leaves nothing stale after a successful Retry.
##
## Run: godot --headless --path . -s res://tests/m31_cleaning_effects_evidence.gd
## Exits 0 on success, 1 on any failure.

const CleaningEffectsController = preload("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")

var _fail := 0

func _initialize() -> void:
	_unit_geometry_and_event()
	_unit_toggle()
	_unit_concurrency()
	_unit_reduced()
	_unit_aging_and_reset()
	await _integration_real_stack()
	_done()

# --- a small rectangular board with distinct width != height (geometry rigor) --------------
func _board(w: int, h: int):
	var cells := PackedInt32Array(); cells.resize(w * h); cells.fill(0)
	var lvl = LevelData.new(1, "m31", "m31", "TEST", w, h, PackedStringArray(["#101010"]), cells)
	return BoardState.from_level_data(lvl)

func _make_controller(board):
	var layer := Node2D.new()
	get_root().add_child(layer)
	var c = CleaningEffectsController.new()
	get_root().add_child(c)
	c.set_process(false)   # drive aging deterministically via age()
	c.bind(layer, board)
	return {"c": c, "layer": layer}

func _unit_geometry_and_event() -> void:
	var board = _board(6, 4)   # 6x4, index = y*6 + x
	var h = _make_controller(board)
	var c = h["c"]; var layer = h["layer"]
	_ok(c.is_bound(), "controller binds to a real fx layer + board")

	# index 15 -> x=3, y=2 -> center (3.5, 2.5) in cell units.
	_ok(c.request_effect(15), "one committed clear -> one requested cue")
	_ok(c.get_active_count() == 1, "exactly one active cue after one request")
	_ok(layer.get_child_count() == 1, "exactly one fx node created in the layer")
	var container = layer.get_child(0)
	_ok(container.position.is_equal_approx(Vector2(3.5, 2.5)), "cue centered on the exact cleared cell (%s)" % str(container.position))

	# out-of-range index -> no cue, no gameplay side effect.
	_ok(not c.request_effect(9999), "out-of-range index requests no cue")
	_ok(c.get_active_count() == 1, "invalid request created no extra cue")
	_teardown(h)

func _unit_toggle() -> void:
	var board = _board(5, 5)
	var h = _make_controller(board)
	var c = h["c"]; var layer = h["layer"]
	c.request_effect(0); c.request_effect(1)
	_ok(c.get_active_count() == 2, "two cues active before disable")
	c.set_effects_enabled(false)
	_ok(not c.is_effects_enabled(), "toggle reports disabled")
	_ok(c.get_active_count() == 0 and layer.get_child_count() == 0, "disable deterministically clears active cues")
	_ok(not c.request_effect(2), "disabled -> zero NEW cues")
	_ok(c.get_active_count() == 0, "still zero cues while disabled")
	c.set_effects_enabled(true)
	_ok(c.request_effect(3), "re-enabled -> later clears may show a cue")
	_teardown(h)

func _unit_concurrency() -> void:
	var board = _board(20, 20)   # 400 cells: plenty above the cap
	var h = _make_controller(board)
	var c = h["c"]; var layer = h["layer"]
	var cap: int = CleaningEffectsController.MAX_ACTIVE_EFFECTS
	var accepted := 0
	for i in range(cap * 3):     # burst far beyond the cap
		if c.request_effect(i):
			accepted += 1
	_ok(c.get_active_count() == cap, "active cues never exceed the cap (%d)" % cap)
	_ok(layer.get_child_count() == cap, "layer holds at most cap fx nodes (no unbounded queue)")
	_ok(accepted == cap, "exactly cap requests accepted, the rest suppressed")
	_ok(c.get_suppressed_count() == cap * 3 - cap, "suppressed counter is exact (%d)" % c.get_suppressed_count())
	_ok(c.get_peak_active() == cap, "peak active == cap")
	_teardown(h)

func _unit_reduced() -> void:
	var board = _board(20, 20)
	var h = _make_controller(board)
	var c = h["c"]; var layer = h["layer"]
	# normal cue: puff + sparkle (2 sprites).
	c.request_effect(0)
	_ok(layer.get_child(0).get_child_count() == 2, "normal cue = puff + sparkle")
	c.reset_for_new_attempt()
	# reduced cue: single sprite + lower cap.
	c.set_reduced_effects(true)
	_ok(c.is_reduced_effects(), "reduced mode reports on")
	c.request_effect(0)
	_ok(layer.get_child(0).get_child_count() == 1, "reduced cue = single sprite")
	var rcap: int = CleaningEffectsController.REDUCED_MAX_ACTIVE
	for i in range(rcap * 3):
		c.request_effect(i)
	_ok(c.get_active_count() == rcap, "reduced mode uses the lower cap (%d)" % rcap)
	_teardown(h)

func _unit_aging_and_reset() -> void:
	var board = _board(10, 10)
	var h = _make_controller(board)
	var c = h["c"]; var layer = h["layer"]
	c.request_effect(0)
	_ok(c.get_active_count() == 1, "one cue before aging")
	c.age(0.01)
	_ok(c.get_active_count() == 1, "cue survives a small age step")
	c.age(CleaningEffectsController.NORMAL_LIFETIME)
	_ok(c.get_active_count() == 0 and layer.get_child_count() == 0, "cue is freed after its lifetime elapses")
	# diagnostics reset on a fresh attempt.
	c.request_effect(1); c.request_effect(2)
	c.reset_for_new_attempt()
	_ok(c.get_active_count() == 0 and c.get_peak_active() == 0 and c.get_suppressed_count() == 0,
		"reset_for_new_attempt clears cues + zeroes peak/suppressed")
	_teardown(h)

# --- real production stack: 1:1 event mapping, identity, gameplay non-mutation, retry -----
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

	var fx = host.get_cleaning_fx()
	_ok(fx != null and fx.is_bound(), "integration: cleaning fx bound to the real presentation")
	var pres = host.get_screen().get_presentation()
	var fx_layer0 = pres.get_cleaning_fx_layer()
	_ok(fx_layer0 != null, "integration: presentation exposes a CleaningFxLayer")

	# Count authenticated clears vs cues requested (enabled, below cap) -> exact 1:1.
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
	for _t in range(200):
		if slots.rightmost_empty_index() != -1 and supply.get_front(0) != null:
			input.activate_front(0)
		runtime.tick(1.0)
		if clears[0] >= 1:
			break
	_ok(clears[0] >= 1, "integration: at least one authenticated clear fired")
	# A cue was placed at the exact cleared cell (fx not yet aged: process disabled).
	if clears[0] >= 1 and last_cell[0] >= 0:
		var pos: Vector2i = board.get_cell_position(last_cell[0])
		var found := false
		for ch in fx_layer0.get_children():
			if ch.position.is_equal_approx(Vector2(pos.x + 0.5, pos.y + 0.5)):
				found = true
		_ok(found, "integration: a cue sits at the exact cleared cell center")
	# Peak cues never exceeded the cap through real play.
	_ok(fx.get_peak_active() <= CleaningEffectsController.MAX_ACTIVE_EFFECTS, "integration: peak cues within cap")

	# Identity stability: relayout does not recreate the CleaningFxLayer.
	sub.size = Vector2i(683, 1366)
	await process_frame
	host.get_screen().relayout()
	await process_frame
	_ok(pres.get_cleaning_fx_layer() == fx_layer0, "integration: CleaningFxLayer identity survives relayout")

	# Toggling FX never changes gameplay truth: clears keep advancing while FX is OFF.
	fx.set_effects_enabled(false)
	var cleared_before: int = host.get_clearing_loop().get_cleared_count()
	for _t in range(400):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col); break
		runtime.tick(1.0)
		if host.get_clearing_loop().get_cleared_count() > cleared_before:
			break
	_ok(host.get_clearing_loop().get_cleared_count() > cleared_before, "integration: clears continue with FX disabled")
	_ok(fx.get_active_count() == 0, "integration: FX disabled produced zero active cues")
	fx.set_effects_enabled(true)

	# Retry hygiene: seed cues, retry, prove nothing stale remains + counters reset.
	fx.request_effect(0); fx.request_effect(1)
	_ok(fx.get_active_count() > 0, "integration: cues seeded before retry")
	_ok(host.retry(), "integration: retry succeeds")
	_ok(fx.get_active_count() == 0 and fx_layer0.get_child_count() == 0, "integration: retry cleared stale cues")
	_ok(fx.get_peak_active() == 0 and fx.get_suppressed_count() == 0, "integration: retry reset fx counters")
	# Board fully ACTIVE again == retry restored gameplay, unaffected by fx.
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == active_before_all, "integration: retry restored full ACTIVE board")

	sub.free()

func _teardown(h) -> void:
	h["c"].free()
	h["layer"].free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M31 cleaning-effects evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
