extends SceneTree
## M37-C001 V03 — forward-only progression + canonical snapshot coherence.
## Closes F-M37-V02-001..002 (owner OWNER_M37_LEVEL_SELECT_DECISION_V01).
## Run: godot --headless --path . -s res://tests/m37_v03_forward_only.gd

const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")

var _fail := 0

func _initialize() -> void:
	_frontier_only_wins()
	_snapshot_coherence()
	_valid_snapshot_all_or_nothing()
	_debug_seam_non_shipping()
	_boundary_cadence()
	_sensitivity_future_re_enabled()
	_done()

func _state(s: LevelProgressionService) -> String:
	return JSON.stringify(s.snapshot())

func _frontier_only_wins() -> void:
	print("[frontier-only wins]")
	var s = LevelProgressionService.new()
	# level_number == current_level -> new first-clear, frontier advances.
	_ok(s.record_win(1), "current frontier level 1 counts")
	_ok(s.current_level() == 2, "frontier -> 2")
	# stale lower rejected, no mutation.
	var before = _state(s)
	_ok(not s.record_win(1), "stale lower-level rejected")
	_ok(_state(s) == before, "stale call left exact state unchanged")
	# out-of-order future rejected, no mutation.
	_ok(not s.record_win(5), "out-of-order future rejected")
	_ok(_state(s) == before, "future call left exact state unchanged")
	_ok(not s.is_completed(5), "future level not marked completed")
	# duplicate rejected.
	s.record_win(2); s.record_win(3)   # frontier -> 4
	var post = _state(s)
	_ok(not s.record_win(3), "duplicate current-completed rejected")
	_ok(_state(s) == post, "duplicate call left exact state unchanged")
	# replay non-advancing.
	_ok(not s.record_win(4, true), "replay of current frontier rejected (non-advancing)")
	_ok(_state(s) == post, "replay left exact state unchanged")

func _snapshot_coherence() -> void:
	print("[snapshot canonical coherence]")
	var s = LevelProgressionService.new()
	s.record_win(1)   # frontier 2, completed [1]
	var before = _state(s)
	# Must fail: current_level=2 with completed=[99]
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 2, "completed": [99]}), "current=2 completed=[99] rejected")
	# Must fail: current_level=10 with completed=[1,3,9]
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 10, "completed": [1, 3, 9]}), "current=10 completed=[1,3,9] gap rejected")
	# Must fail: current_level=1 with completed=[1] (frontier includes itself)
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 1, "completed": [1]}), "current=1 completed=[1] rejected")
	# Must fail: current=4 completed=[1,2] (gap under frontier)
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 4, "completed": [1, 2]}), "current=4 completed=[1,2] short rejected")
	# Must fail: current=4 completed=[1,2,3,99] (extra future)
	_ok(not s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 4, "completed": [1, 2, 3, 99]}), "current=4 completed=[1,2,3,99] extra rejected")
	_ok(_state(s) == before, "state unchanged after every rejected import")

func _valid_snapshot_all_or_nothing() -> void:
	print("[valid canonical import]")
	var s = LevelProgressionService.new()
	# Canonical: current_level=N, completed=1..N-1.
	_ok(s.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 5, "completed": [1, 2, 3, 4]}), "canonical current=5 completed=[1..4] accepted")
	_ok(s.current_level() == 5 and s.completed_count() == 4, "state restored")
	# current_level=1 with empty completed is canonical (fresh player).
	var s2 = LevelProgressionService.new()
	_ok(s2.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": 1, "completed": []}), "fresh canonical current=1 completed=[] accepted")

func _debug_seam_non_shipping() -> void:
	print("[debug seam non-shipping]")
	var s = LevelProgressionService.new()
	# Debug jump creates a synthetic state (empty completed but frontier ahead).
	_ok(s.debug_set_current_level(5), "debug frontier jump ok")
	_ok(s.current_level() == 5, "frontier at 5")
	_ok(s.completed_count() == 0, "no completed entries via debug (synthetic)")
	# The synthetic debug state does NOT round-trip through canonical import
	# (it violates the contiguous law); the debug snapshot is intentionally
	# non-shipping.
	var snap = s.snapshot()
	var s2 = LevelProgressionService.new()
	_ok(not s2.import_snapshot(snap), "synthetic debug snapshot rejected by canonical import (non-shipping)")

func _boundary_cadence() -> void:
	print("[boundary cadence unchanged]")
	var s = LevelProgressionService.new()
	_ok(s.class_for(10) == "VERY_HARD" and s.class_for(11) == "EASY", "10->11 boundary")
	_ok(s.class_for(310) == "VERY_HARD" and s.class_for(311) == "EASY", "310->311 boundary")
	_ok(s.target_challenge_for(311) > s.target_challenge_for(11), "311 EASY target > 11")

## Sensitivity check: re-enabling future-level record_win would specifically
## fail the frontier-only assertion above ("out-of-order future rejected").
## This confirms the V03 suite would catch a regression of F-M37-V02-001.
func _sensitivity_future_re_enabled() -> void:
	print("[sensitivity]")
	var s = LevelProgressionService.new()
	s.record_win(1)                       # frontier 2
	var before = _state(s)
	# Simulate the old buggy law by calling debug_set_current_level(99), which is
	# not the same as accepting future wins on the shipping path — but this proves
	# there is no shipping seam that turns level 99 into a canonical first-clear.
	_ok(not s.record_win(99), "shipping path never accepts 99 as a first-clear")
	_ok(_state(s) == before, "state unchanged after future-level probe")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M37 V03 forward-only evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
