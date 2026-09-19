extends SceneTree
## M31-C001 V01 — 59x59 / high-clear-density stress + allocation evidence
## (SB-M31-008/009, prompt §13). Deterministic, headless. Drives cleaning-cue bursts
## substantially beyond the concurrency cap at the production board ceiling, at both a
## 1x and a denser 2x event rate, and records:
##   - max active instances (must equal the cap under saturation, never exceed it);
##   - suppressed (dropped) cue count (fail-open, no unbounded queue);
##   - spawn+age wall time (the pooling decision input);
##   - whether pooling was required.
##
## Pooling decision (SB-M31-007): the simplest bounded no-pool version is measured here.
## The cap bounds live nodes to MAX_ACTIVE_EFFECTS regardless of burst size, so allocate/
## free churn per frame is bounded by the cap, not the burst. The measured cost stays well
## under a 16ms mobile frame budget for the whole burst, so NO pool is added. See
## coordination/sessions/M31-C001/CLAUDE_LOG_V01.md.
##
## Run: godot --headless --path . -s res://tests/m31_scale_59_effects.gd
## Exits 0 on success, 1 on any failure.

const CleaningEffectsController = preload("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

const N := 59
const FRAMES := 240          # ~4s of frames
const CLEARS_PER_FRAME := 40 # far above the cap -> forced suppression every frame

var _fail := 0

func _board_59():
	var cells := PackedInt32Array(); cells.resize(N * N); cells.fill(0)
	var lvl = LevelData.new(1, "m31_59", "m31_59", "TEST", N, N, PackedStringArray(["#101010"]), cells)
	return BoardState.from_level_data(lvl)

func _initialize() -> void:
	_stress("1x", 1.0 / 60.0)
	_stress("2x", 1.0 / 120.0)   # denser event rate: half the frame delta, twice the overlap
	_done()

func _stress(label: String, dt: float) -> void:
	var board = _board_59()
	var layer := Node2D.new()
	get_root().add_child(layer)
	var c = CleaningEffectsController.new()
	get_root().add_child(c)
	c.set_process(false)   # drive aging deterministically
	c.bind(layer, board)

	var count: int = board.get_cell_count()
	var cap: int = CleaningEffectsController.MAX_ACTIVE_EFFECTS
	var max_active := 0
	var idx := 0
	var t0 := Time.get_ticks_usec()
	for _f in range(FRAMES):
		for _k in range(CLEARS_PER_FRAME):
			c.request_effect(idx % count)
			idx += 1
		if c.get_active_count() > max_active:
			max_active = c.get_active_count()
		# live-node invariant every frame: never exceed the cap.
		if c.get_active_count() > cap:
			_ok(false, "%s: active EXCEEDED cap mid-run (%d > %d)" % [label, c.get_active_count(), cap])
		c.age(dt)
	var elapsed_ms := float(Time.get_ticks_usec() - t0) / 1000.0

	var total_requested := FRAMES * CLEARS_PER_FRAME
	print("M31_PERF %s: 59x59 frames=%d req=%d cap=%d peak=%d suppressed=%d spawn+age=%.2f ms (%.4f ms/frame)"
		% [label, FRAMES, total_requested, cap, c.get_peak_active(), c.get_suppressed_count(),
		elapsed_ms, elapsed_ms / float(FRAMES)])

	_ok(max_active <= cap, "%s: max active (%d) never exceeds the cap (%d)" % [label, max_active, cap])
	_ok(c.get_peak_active() == cap, "%s: saturating burst drives peak to the cap" % label)
	_ok(c.get_suppressed_count() > 0, "%s: over-cap cues are suppressed (fail-open, no queue)" % label)
	_ok(layer.get_child_count() <= cap, "%s: layer never holds more than cap live nodes" % label)
	# Bounded work: a 16ms mobile frame budget is never threatened by the fx layer alone.
	_ok(elapsed_ms / float(FRAMES) < 16.0, "%s: per-frame spawn+age stays under a 16ms budget" % label)

	# Drain: aging past the lifetime frees everything (no leak / no stranded node).
	for _d in range(30):
		c.age(CleaningEffectsController.NORMAL_LIFETIME)
	_ok(c.get_active_count() == 0 and layer.get_child_count() == 0, "%s: all cues drain to zero after lifetime" % label)

	c.free()
	layer.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M31 59x59 effects stress: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
