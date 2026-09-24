extends SceneTree
## M36-C001 V02 — Difficulty V1 production-migration evidence (F-M36-001).
## Proves the GENERAL production validator no longer enforces class=dimension
## bands: class-token + 20..59 envelope only, class independent of dimensions.
## Run: godot --headless --path . -s res://tests/m36_v02_migration.gd

const LevelValidator = preload("res://scripts/data/level_validator.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")

var _fail := 0

func _initialize() -> void:
	_no_class_dimension_rule()
	_envelope_and_class_gate()
	_legacy_isolated()
	_done()

func _level(id: String, difficulty: String, w: int, h: int):
	var cells: Array = []
	for _i in range(w * h):
		cells.append(0)
	var data := {
		"version": 1, "id": id, "name": id, "difficulty": difficulty,
		"width": w, "height": h, "palette": ["C01"], "cells": cells,
	}
	var r = LevelValidator.validate(data, id)
	_ok(r.is_ok(), "%s structurally valid: %s" % [id, ", ".join(r.errors)])
	return r.level_data

func _prod_ok(level) -> bool:
	return ProductionLevelValidator.validate(level).is_ok()

func _no_class_dimension_rule() -> void:
	print("[class != dimension]")
	# 24x24 VERY_HARD — impossible under old bands (VERY_HARD was 50..59), must PASS now.
	_ok(_prod_ok(_level("compact_boss", "VERY_HARD", 24, 24)), "24x24 VERY_HARD is production-legal")
	# 38x38 EASY — impossible under old bands (EASY was 20..29), must PASS now.
	_ok(_prod_ok(_level("large_relief", "EASY", 38, 38)), "38x38 EASY is production-legal")
	# 59x20 MEDIUM rectangular cross-class — PASS.
	_ok(_prod_ok(_level("wide_medium", "MEDIUM", 59, 20)), "59x20 MEDIUM rectangular is production-legal")

func _envelope_and_class_gate() -> void:
	print("[envelope + class]")
	# Below/above envelope fail.
	_ok(not _prod_ok(_level("under_w", "EASY", 19, 24)), "19x24 fails envelope (below 20)")
	_ok(not _prod_ok(_level("over_w", "EASY", 60, 24)), "60x24 fails envelope (above 59)")
	_ok(not _prod_ok(_level("under_h", "HARD", 30, 19)), "30x19 fails envelope (height below 20)")
	# TEST rejected.
	_ok(not _prod_ok(_level("test_fixture", "TEST", 24, 24)), "TEST rejected in production")
	# Unknown class rejected.
	_ok(not _prod_ok(_level("bogus", "SUPER", 30, 30)), "unknown class rejected")
	# Max envelope 59x59 VERY_HARD ok; min 20x20 ok.
	_ok(_prod_ok(_level("max_env", "VERY_HARD", 59, 59)), "59x59 VERY_HARD legal (max envelope)")
	_ok(_prod_ok(_level("min_env", "EASY", 20, 20)), "20x20 EASY legal (min envelope)")

func _legacy_isolated() -> void:
	print("[legacy isolated]")
	# The legacy M21 band check still exists but ONLY behind the named seam; it
	# must NOT be what the general validator uses. Confirm 24x24 VERY_HARD is
	# rejected by the legacy band seam yet accepted by the production validator.
	_ok(not DifficultyRules.legacy_m21_within_band("VERY_HARD", 24, 24), "legacy M21 seam still rejects 24x24 VERY_HARD (isolated)")
	_ok(_prod_ok(_level("compact_boss2", "VERY_HARD", 24, 24)), "general validator accepts it (legacy not applied)")
	_ok(DifficultyRules.ENVELOPE_MIN == 20 and DifficultyRules.ENVELOPE_MAX == 59, "envelope constants 20..59")
	_ok(DifficultyRules.PRODUCTION_CLASSES.size() == 4, "four production classes")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M36 V02 migration evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
