extends SceneTree
## M35-C001 V01 — production level catalog evidence.
## Run: godot --headless --path . -s res://tests/m35_level_catalog.gd
## Exits 0 on success, 1 on any failure.
##
## Covers the adversarial matrix from the audit criteria:
##   - production catalog loads and exposes M21 production level
##   - empty catalog
##   - duplicate id / duplicate order / path alias duplicate
##   - missing level file
##   - malformed level JSON
##   - TEST-difficulty fixture insertion (must be rejected on canonical field)
##   - unknown difficulty token
##   - rectangular support boundary
##   - batch validation determinism
##   - catalog mutation returns a copy (does not mutate canonical entries)

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

var _fail := 0

func _initialize() -> void:
	_production_catalog_loads()
	_empty_catalog()
	_duplicate_id()
	_duplicate_order()
	_path_alias_duplicate()
	_missing_level_file()
	_malformed_level_json()
	_test_fixture_insertion()
	_unknown_difficulty()
	_rectangular_boundary()
	_batch_validation_determinism()
	_mutation_returns_copy()
	_done()

# --- helpers ---

func _write_json(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _minimal_valid_level(id: String, difficulty: String = "EASY", width: int = 20, height: int = 20) -> Dictionary:
	var cells: Array = []
	for _i in range(width * height):
		cells.append(0)
	return {
		"version": 1,
		"id": id,
		"name": id,
		"difficulty": difficulty,
		"width": width,
		"height": height,
		"palette": ["C01"],
		"cells": cells,
	}

func _tmp(base: String) -> String:
	return "user://m35_%s_%d.json" % [base, Time.get_ticks_usec()]

## Level files referenced as level_path must be res:// (the production catalog
## confines level_path to the res:// root since M35 V02). res:// is writable in
## a headless-from-source dev run.
func _res_tmp(base: String) -> String:
	return "res://m35_lvl_%s_%d.json" % [base, Time.get_ticks_usec()]

# --- cases ---

func _production_catalog_loads() -> void:
	print("[production]")
	var c = LevelCatalog.new()
	var r = c.load_manifest()
	_ok(r.ok, "production catalog ok: %s" % r.summary())
	_ok(c.size() >= 1, "at least one production entry (%d)" % c.size())
	var e = c.get_entry_by_id("m21_level_001_hazard_bot")
	_ok(e != null, "M21 hazard-bot entry present")
	if e != null:
		_ok(e.width == 20 and e.height == 20, "M21 dims 20x20")
		_ok(e.difficulty == "EASY", "M21 difficulty EASY exposed verbatim")
		_ok(e.preview_exists, "M21 preview file present")
	# Batch revalidation is deterministic.
	var r2 = c.validate_all()
	_ok(r2.ok, "batch validation reruns ok")

func _empty_catalog() -> void:
	print("[empty]")
	var path := _tmp("empty")
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": []})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(r.ok, "empty catalog is legal")
	_ok(c.size() == 0, "empty catalog has 0 entries")
	_remove(path)

func _duplicate_id() -> void:
	print("[dup id]")
	# Two entries with the same id fail closed.
	var path := _tmp("dup_id")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [
			{"id": "m21_level_001_hazard_bot", "order": 1, "level_path": "res://data/levels/m21_level_001_hazard_bot.json"},
			{"id": "m21_level_001_hazard_bot", "order": 2, "level_path": "res://data/levels/m21_level_001_hazard_bot.json"},
		],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "duplicate id fails closed")
	_remove(path)

func _duplicate_order() -> void:
	print("[dup order]")
	var path := _tmp("dup_order")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [
			{"id": "a", "order": 1, "level_path": "res://data/levels/m21_level_001_hazard_bot.json"},
			{"id": "b", "order": 1, "level_path": "res://data/levels/m21_level_001_hazard_bot.json"},
		],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "duplicate order fails closed")
	_remove(path)

func _path_alias_duplicate() -> void:
	print("[path alias]")
	var path := _tmp("path_alias")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [
			{"id": "a", "order": 1, "level_path": "res://data/levels/m21_level_001_hazard_bot.json"},
			{"id": "b", "order": 2, "level_path": "res://data/levels/./m21_level_001_hazard_bot.json"},
		],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "aliased duplicate level_path fails closed")
	_remove(path)

func _missing_level_file() -> void:
	print("[missing]")
	var path := _tmp("missing")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [{"id": "phantom", "order": 1, "level_path": "res://data/levels/does_not_exist.json"}],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "missing level file fails closed")
	_remove(path)

func _malformed_level_json() -> void:
	print("[malformed]")
	var bad_level := _res_tmp("bad")
	_write_text(bad_level, "{{ not json")
	var path := _tmp("bad_ref")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [{"id": "malformed", "order": 1, "level_path": bad_level}],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "malformed level JSON fails closed")
	_remove(bad_level)
	_remove(path)

func _test_fixture_insertion() -> void:
	print("[test fixture]")
	# Author a level file with canonical difficulty=TEST and insert it into the
	# catalog. It must be rejected on the CANONICAL field, not filename.
	var lvl := _res_tmp("test_fixture")
	_write_json(lvl, _minimal_valid_level("test_inserted", "TEST"))
	var path := _tmp("test_manifest")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [{"id": "test_inserted", "order": 1, "level_path": lvl}],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "TEST fixture rejected in production catalog")
	_remove(lvl)
	_remove(path)

func _unknown_difficulty() -> void:
	print("[unknown difficulty]")
	var lvl := _res_tmp("unk_diff")
	_write_json(lvl, _minimal_valid_level("unk_diff", "SUPER"))
	var path := _tmp("unk_manifest")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [{"id": "unk_diff", "order": 1, "level_path": lvl}],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "unknown difficulty fails closed")
	_remove(lvl)
	_remove(path)

func _rectangular_boundary() -> void:
	print("[rect]")
	# A rectangular 24x28 EASY level is within the 20..59 production envelope
	# (Difficulty V1). This proves rectangular support in the catalog read model.
	var lvl := _res_tmp("rect")
	_write_json(lvl, _minimal_valid_level("rect_easy", "EASY", 24, 28))
	var path := _tmp("rect_manifest")
	_write_json(path, {
		"schema": "scrubbots.production_catalog.v1",
		"entries": [{"id": "rect_easy", "order": 1, "level_path": lvl}],
	})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(r.ok, "rectangular EASY 24x28 accepted: %s" % r.summary())
	if r.ok:
		var e = c.get_entry_by_id("rect_easy")
		_ok(e != null and e.width == 24 and e.height == 28, "dims exposed as 24x28")
	_remove(lvl)
	_remove(path)

func _batch_validation_determinism() -> void:
	print("[batch determinism]")
	var c = LevelCatalog.new()
	c.load_manifest()
	var r1 = c.validate_all()
	var r2 = c.validate_all()
	_ok(r1.ok == r2.ok, "batch validation is deterministic on repeat")

func _mutation_returns_copy() -> void:
	print("[copy]")
	var c = LevelCatalog.new()
	c.load_manifest()
	var arr = c.get_entries_ordered()
	var before := c.size()
	arr.clear()
	_ok(c.size() == before, "clearing returned array does not mutate catalog")

# --- utilities ---

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M35 level catalog evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
