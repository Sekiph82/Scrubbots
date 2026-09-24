extends SceneTree
## M37-C001 V02 — strict-v2 adversarial progression validation.
## Validation-first: exercises every V02 criterion against the real
## LevelProgressionService. Run:
## godot --headless --path . -s res://tests/m37_v02_strict.gd

const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")

var _fail := 0

func _initialize() -> void:
	_duplicate_and_reentrant()
	_stale_and_future()
	_replay()
	_import_then_replay()
	_malformed_and_fractional()
	_duplicate_completed_ids()
	_boundaries_and_large()
	_failed_import_unchanged()
	_no_content_mutation()
	_done()

func _duplicate_and_reentrant() -> void:
	print("[duplicate/reentrant]")
	var s = LevelProgressionService.new()
	_ok(s.record_win(1), "first win of level 1 counts")
	_ok(not s.record_win(1), "same win twice does not re-count")
	for _i in range(8):
		s.record_win(1)
	_ok(s.completed_count() == 1 and s.current_level() == 2, "reentrant duplicates never double-advance")

func _stale_and_future() -> void:
	print("[stale/future]")
	var s = LevelProgressionService.new()
	s.record_win(1); s.record_win(2); s.record_win(3)   # frontier 4
	_ok(not s.record_win(1), "stale lower-level completion rejected (already complete)")
	_ok(s.current_level() == 4, "frontier unaffected by stale completion")
	# Future level out of order: recorded as a first-clear but the frontier does
	# NOT jump (frontier only advances when clearing the current frontier level).
	_ok(s.record_win(99), "out-of-order future level records a first-clear")
	_ok(s.current_level() == 4, "future completion does not jump the frontier")
	_ok(s.is_completed(99), "future level marked completed")

func _replay() -> void:
	print("[replay]")
	var s = LevelProgressionService.new()
	s.record_win(1)                       # frontier 2
	_ok(not s.record_win(2, true), "replay win returns false")
	_ok(s.current_level() == 2 and s.completed_count() == 1, "replay win advances nothing")
	# Replay loss is a no-op (no record_win call); frontier stable.
	_ok(s.current_level() == 2, "replay loss is a no-op")

func _import_then_replay() -> void:
	print("[import then replay]")
	var s = LevelProgressionService.new()
	s.record_win(1); s.record_win(2)      # frontier 3
	var snap = s.snapshot()
	var s2 = LevelProgressionService.new()
	_ok(s2.import_snapshot(snap), "valid snapshot imports")
	_ok(not s2.record_win(1), "replay of a prior completion after import does not re-advance")
	_ok(s2.current_level() == 3, "imported frontier intact after replay attempt")

func _malformed_and_fractional() -> void:
	print("[malformed/fractional]")
	var s = LevelProgressionService.new()
	s.record_win(1)                       # frontier 2
	var before = s.current_level()
	_ok(not s.import_snapshot(null), "null rejected")
	_ok(not s.import_snapshot({"schema": "wrong", "current_level": 3, "completed": []}), "wrong schema rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 0, "completed": []}), "current_level < 1 rejected")
	# Fractional / non-finite where integer required must fail closed.
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 3.5, "completed": []}), "fractional current_level fails closed")
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 3, "completed": [1, 2.5]}), "fractional completed entry fails closed")
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 3, "completed": [1, "x"]}), "non-numeric completed entry rejected")
	_ok(s.current_level() == before, "state unchanged after every malformed import")

func _duplicate_completed_ids() -> void:
	print("[duplicate completed ids]")
	var s = LevelProgressionService.new()
	s.record_win(1)
	var before = s.current_level()
	# A duplicate id in a loaded snapshot indicates corruption (snapshot() never
	# emits duplicates) and must fail closed.
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 3, "completed": [1, 1, 2]}), "duplicate completed ids fail closed")
	_ok(s.current_level() == before, "state unchanged after duplicate-id import")

func _boundaries_and_large() -> void:
	print("[boundaries/large]")
	var s = LevelProgressionService.new()
	_ok(s.class_for(10) == "VERY_HARD" and s.class_for(11) == "EASY", "10->11 boundary")
	_ok(s.class_for(20) == "VERY_HARD" and s.class_for(21) == "EASY", "20->21 boundary")
	_ok(s.class_for(310) == "VERY_HARD" and s.class_for(311) == "EASY", "310->311 boundary")
	_ok(s.class_for(1000000) == "VERY_HARD", "very large level number stable (1e6 slot 10)")
	_ok(s.target_challenge_for(1000000) >= 0.0 and s.target_challenge_for(1000000) <= 100.0, "large-n target finite/in-range")

func _failed_import_unchanged() -> void:
	print("[failed import unchanged]")
	var s = LevelProgressionService.new()
	s.record_win(1); s.record_win(2); s.record_win(3)   # frontier 4, completed {1,2,3}
	var snap_before = s.snapshot()
	# A malformed import must leave the EXACT pre-import state.
	s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 7, "completed": [1, 2, 3.5]})
	var snap_after = s.snapshot()
	_ok(JSON.stringify(snap_before) == JSON.stringify(snap_after), "failed import leaves exact pre-import snapshot")

func _no_content_mutation() -> void:
	print("[no content mutation]")
	var s = LevelProgressionService.new()
	var d1 = s.describe(11)
	d1["class"] = "TAMPERED"
	var d2 = s.describe(11)
	_ok(d2["class"] == "EASY", "describe() returns a fresh read model; no shared mutable content")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M37 V02 strict validation: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
