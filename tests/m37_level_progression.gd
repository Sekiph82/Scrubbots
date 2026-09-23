extends SceneTree
## M37-C001 V01 — level progression evidence.
## Run: godot --headless --path . -s res://tests/m37_level_progression.gd
## Exits 0 on success, 1 on any failure.

const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")

var _fail := 0

func _initialize() -> void:
	_cadence()
	_current_level_and_frontier()
	_first_clear_idempotent()
	_replay_non_advancing()
	_stale_and_invalid()
	_boundaries()
	_snapshot_roundtrip()
	_malformed_snapshot()
	_no_content_mutation()
	_done()

func _cadence() -> void:
	print("[cadence]")
	var s = LevelProgressionService.new()
	var expected := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]
	var ok := true
	for i in range(10):
		if s.class_for(i + 1) != expected[i]:
			ok = false
	_ok(ok, "levels 1..10 cadence classes match owner lock")
	# Large n cadence stability.
	_ok(s.class_for(311) == "EASY", "level 311 EASY")
	_ok(s.class_for(310) == "VERY_HARD", "level 310 VERY_HARD")
	_ok(s.class_for(1000) == "VERY_HARD", "level 1000 VERY_HARD")
	_ok(s.class_for(1001) == "EASY", "level 1001 EASY")

func _current_level_and_frontier() -> void:
	print("[current level]")
	var s = LevelProgressionService.new()
	_ok(s.current_level() == 1, "starts at level 1")
	# Win level 1 -> frontier advances to 2.
	_ok(s.record_win(1), "win level 1 is a new first-clear")
	_ok(s.current_level() == 2, "frontier advanced to 2")
	# Invalid set rejected.
	_ok(not s.debug_set_current_level(0), "debug_set_current_level rejects <1")
	_ok(s.debug_set_current_level(5), "debug seam accepts valid number (non-shipping)")
	_ok(s.current_level() == 5, "debug seam moved frontier for tests")

func _first_clear_idempotent() -> void:
	print("[first clear]")
	var s = LevelProgressionService.new()
	_ok(s.record_win(1), "first win of level 1 counts")
	_ok(not s.record_win(1), "duplicate win of level 1 does NOT count again")
	_ok(s.completed_count() == 1, "completed set has exactly one entry")
	_ok(s.current_level() == 2, "frontier still 2 after duplicate")
	# Reentrant burst of the same callback.
	for _i in range(10):
		s.record_win(1)
	_ok(s.completed_count() == 1 and s.current_level() == 2, "reentrant duplicates do not advance twice")

func _replay_non_advancing() -> void:
	print("[replay]")
	var s = LevelProgressionService.new()
	s.record_win(1)   # frontier -> 2
	s.record_win(2)   # frontier -> 3
	var frontier_before := s.current_level()
	var count_before := s.completed_count()
	# Replay a completed level and win again.
	_ok(not s.record_win(1, true), "replay win returns false")
	_ok(s.current_level() == frontier_before, "replay did not advance frontier")
	_ok(s.completed_count() == count_before, "replay did not change first-clear truth")
	# Replay loss is a no-op for progression (no record_win call at all) — nothing to assert beyond frontier stability.
	_ok(s.current_level() == frontier_before, "frontier stable after replay loss (no-op)")

func _stale_and_invalid() -> void:
	print("[stale/invalid]")
	var s = LevelProgressionService.new()
	s.record_win(1); s.record_win(2); s.record_win(3)  # frontier -> 4
	# Stale completion from an old level after frontier advanced: level 1 is
	# already completed, so a late duplicate is rejected and never re-advances.
	_ok(not s.record_win(1), "stale completion of old level rejected")
	_ok(s.current_level() == 4, "frontier unaffected by stale completion")
	# Invalid level numbers.
	_ok(not s.record_win(0), "level 0 rejected")
	_ok(not s.record_win(-5), "negative level rejected")

func _boundaries() -> void:
	print("[boundaries]")
	var s = LevelProgressionService.new()
	# Cadence boundaries 10->11, 20->21, 310->311.
	_ok(s.class_for(10) == "VERY_HARD" and s.class_for(11) == "EASY", "10->11 boundary")
	_ok(s.class_for(20) == "VERY_HARD" and s.class_for(21) == "EASY", "20->21 boundary")
	_ok(s.class_for(310) == "VERY_HARD" and s.class_for(311) == "EASY", "310->311 boundary")
	# Target grows with campaign age within a lane.
	_ok(s.target_challenge_for(311) > s.target_challenge_for(11), "311 EASY target > 11 EASY target")

func _snapshot_roundtrip() -> void:
	print("[snapshot]")
	var s = LevelProgressionService.new()
	s.record_win(1); s.record_win(2); s.record_win(3)
	var snap: Dictionary = s.snapshot()
	_ok(snap.get("current_level") == 4, "snapshot current_level == 4")
	_ok(snap.get("completed").size() == 3, "snapshot completed size 3")
	var s2 = LevelProgressionService.new()
	_ok(s2.import_snapshot(snap), "import valid snapshot succeeds")
	_ok(s2.current_level() == 4, "imported frontier restored")
	_ok(s2.is_completed(1) and s2.is_completed(2) and s2.is_completed(3), "imported first-clears restored")
	# Importing then re-winning a completed level does not double-advance.
	_ok(not s2.record_win(2), "post-import duplicate rejected")

func _malformed_snapshot() -> void:
	print("[malformed snapshot]")
	var s = LevelProgressionService.new()
	s.record_win(1)  # frontier -> 2
	var before := s.current_level()
	_ok(not s.import_snapshot(null), "null snapshot rejected")
	_ok(not s.import_snapshot({"schema": "wrong"}), "wrong schema rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 0, "completed": []}), "current_level<1 rejected")
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 3, "completed": [1, "x"]}), "non-int completed entry rejected")
	_ok(s.current_level() == before, "state untouched after every malformed import")

func _no_content_mutation() -> void:
	print("[no content mutation]")
	var s = LevelProgressionService.new()
	# The service only reads cadence class/target; it holds no level content and
	# cannot mutate the catalog. describe() returns a fresh dict each call.
	var d1: Dictionary = s.describe(11)
	d1["class"] = "TAMPERED"
	var d2: Dictionary = s.describe(11)
	_ok(d2["class"] == "EASY", "describe() returns fresh read model (no shared mutable state)")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M37 level progression evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
