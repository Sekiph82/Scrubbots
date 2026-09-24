extends SceneTree
## M35-C001 V02 — catalog hardening evidence (F-M35-001/003/004 + F-M35-002
## revalidated after M36 V02).
## Run: godot --headless --path . -s res://tests/m35_v02_hardening.gd

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

var _fail := 0

func _initialize() -> void:
	_immutable_entries()
	_strict_integer_order()
	_path_canonicalization()
	_difficulty_v1_acceptance()
	_test_rejected_and_m21_valid()
	_done()

func _write_json(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _tmp(base: String) -> String:
	# Manifest files live under user:// (load_manifest reads any path).
	return "user://m35v2_%s_%d.json" % [base, Time.get_ticks_usec()]

func _res_tmp(base: String) -> String:
	# Level files must be res:// (production catalog confines level_path to the
	# res:// root). res:// is writable in a headless-from-source dev run.
	return "res://m35v2_lvl_%s_%d.json" % [base, Time.get_ticks_usec()]

func _level(id: String, difficulty: String, w: int, h: int) -> Dictionary:
	var cells: Array = []
	for _i in range(w * h):
		cells.append(0)
	return {"version": 1, "id": id, "name": id, "difficulty": difficulty, "width": w, "height": h, "palette": ["C01"], "cells": cells}

func _immutable_entries() -> void:
	print("[immutable entries]")
	var c = LevelCatalog.new()
	c.load_manifest()  # production manifest (M21)
	# F-M35-001: mutate a returned entry, re-fetch, assert canonical unchanged.
	var e = c.get_entry_by_id("m21_level_001_hazard_bot")
	_ok(e != null, "entry present")
	var orig_width = e.width
	var orig_id = e.id
	e.width = 999
	e.id = "TAMPERED"
	e.order = -42
	var e2 = c.get_entry_by_id("m21_level_001_hazard_bot")
	_ok(e2.width == orig_width and e2.id == orig_id and e2.order != -42, "mutating a returned entry does not corrupt canonical read model")
	# Array view entries are also copies.
	var arr = c.get_entries_ordered()
	if arr.size() > 0:
		arr[0].difficulty = "HACKED"
	var e3 = c.get_entry_by_id("m21_level_001_hazard_bot")
	_ok(e3.difficulty != "HACKED", "mutating an ordered-view entry does not corrupt canonical read model")

func _strict_integer_order() -> void:
	print("[strict int order]")
	# Fractional order fails closed.
	var lvl := _res_tmp("ord")
	_write_json(lvl, _level("ord_lvl", "EASY", 20, 20))
	var path := _tmp("ord_manifest")
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "ord_lvl", "order": 1.5, "level_path": lvl},
	]})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(not r.ok, "fractional order 1.5 fails closed")
	# Exact integer order accepted.
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "ord_lvl", "order": 1, "level_path": lvl},
	]})
	var c2 = LevelCatalog.new()
	_ok(c2.load_manifest(path).ok, "exact integer order accepted")
	_remove(lvl); _remove(path)

func _path_canonicalization() -> void:
	print("[path canonicalization]")
	var lvl := "res://data/levels/m21_level_001_hazard_bot.json"
	# Alias via ".." that resolves to the same file must collide.
	var path := _tmp("alias")
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "a", "order": 1, "level_path": lvl},
		{"id": "b", "order": 2, "level_path": "res://data/levels/metadata/../m21_level_001_hazard_bot.json"},
	]})
	var c = LevelCatalog.new()
	_ok(not c.load_manifest(path).ok, "dot-dot alias to same file collides (fails closed)")
	# Path escaping above res:// root fails closed.
	var esc := _tmp("escape")
	_write_json(esc, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "x", "order": 1, "level_path": "res://../secret.json"},
	]})
	var c2 = LevelCatalog.new()
	_ok(not c2.load_manifest(esc).ok, "path escaping above root fails closed")
	# Non-res:// path fails closed.
	var np := _tmp("nonres")
	_write_json(np, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "y", "order": 1, "level_path": "user://foo.json"},
	]})
	var c3 = LevelCatalog.new()
	_ok(not c3.load_manifest(np).ok, "non-res:// path fails closed")
	_remove(path); _remove(esc); _remove(np)

func _difficulty_v1_acceptance() -> void:
	print("[difficulty V1 acceptance]")
	# F-M35-002 revalidated after M36 V02: class-independent-of-dimension entries
	# now enter the production catalog.
	var boss := _res_tmp("boss"); _write_json(boss, _level("compact_boss", "VERY_HARD", 24, 24))
	var relief := _res_tmp("relief"); _write_json(relief, _level("large_relief", "EASY", 38, 38))
	var path := _tmp("dv1_manifest")
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "compact_boss", "order": 1, "level_path": boss},
		{"id": "large_relief", "order": 2, "level_path": relief},
	]})
	var c = LevelCatalog.new()
	var r = c.load_manifest(path)
	_ok(r.ok, "24x24 VERY_HARD + 38x38 EASY enter production catalog: %s" % r.summary())
	_ok(c.get_entry_by_id("compact_boss").difficulty == "VERY_HARD", "compact boss surfaced VERY_HARD")
	_ok(c.get_entry_by_id("large_relief").width == 38, "large relief surfaced 38 wide")
	_remove(boss); _remove(relief); _remove(path)

func _test_rejected_and_m21_valid() -> void:
	print("[TEST rejected + M21 valid]")
	# TEST still rejected.
	var t := _res_tmp("test"); _write_json(t, _level("test_ins", "TEST", 24, 24))
	var path := _tmp("test_manifest")
	_write_json(path, {"schema": "scrubbots.production_catalog.v1", "entries": [
		{"id": "test_ins", "order": 1, "level_path": t},
	]})
	var c = LevelCatalog.new()
	_ok(not c.load_manifest(path).ok, "TEST fixture still rejected")
	_remove(t); _remove(path)
	# M21 production entry still valid.
	var c2 = LevelCatalog.new()
	_ok(c2.load_manifest().ok and c2.get_entry_by_id("m21_level_001_hazard_bot") != null, "M21 production entry still valid")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M35 V02 hardening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
