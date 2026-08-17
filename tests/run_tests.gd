extends SceneTree
## Headless test runner for the variable-size board + level data core
## (Prompt 02) and official difficulty-band production validation
## (Prompt 03). Run with:
##   godot --headless --path . -s res://tests/run_tests.gd
## Exits 0 on all-pass, 1 on any failure. No third-party test framework —
## see docs/06_TEST_STRATEGY.md.
##
## Uses explicit preload() rather than global class_name lookup — see
## scripts/data/level_validator.gd for why.
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelValidationResult = preload("res://scripts/data/level_validation_result.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")

var _total: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	_run_dimension_tests()
	_run_index_conversion_tests()
	_run_invalid_coordinate_tests()
	_run_level_validation_tests()
	_run_board_state_tests()
	_run_independence_tests()
	_run_production_difficulty_tests()
	_run_max_board_tests()
	_run_performance_sanity()
	_run_performance_sanity_59x59()
	_print_summary()
	quit(0 if _failures.is_empty() else 1)

# ---------------------------------------------------------------- helpers --

func _check(condition: bool, description: String) -> void:
	_total += 1
	if not condition:
		_failures.append(description)

func _check_eq(actual, expected, description: String) -> void:
	_check(actual == expected, "%s (expected %s, got %s)" % [description, str(expected), str(actual)])

func _load_fixture(path: String) -> LevelData:
	var result: LevelValidationResult = LevelLoader.load_from_path(path)
	if not result.is_ok():
		_failures.append("fixture %s failed to load: %s" % [path, str(result.errors)])
		_total += 1
		return null
	return result.level_data

# --------------------------------------------------------------- sections --

func _run_dimension_tests() -> void:
	var lvl40 := _load_fixture("res://data/levels/test_40x40.json")
	if lvl40 != null:
		_check_eq(lvl40.width, 40, "40x40 fixture width")
		_check_eq(lvl40.height, 40, "40x40 fixture height")
		_check_eq(lvl40.get_cell_count(), 1600, "40x40 fixture cell_count")

	var lvl50 := _load_fixture("res://data/levels/test_50x50.json")
	if lvl50 != null:
		_check_eq(lvl50.width, 50, "50x50 fixture width")
		_check_eq(lvl50.height, 50, "50x50 fixture height")
		_check_eq(lvl50.get_cell_count(), 2500, "50x50 fixture cell_count")

	var lvl3x2 := _load_fixture("res://data/levels/test_3x2.json")
	if lvl3x2 != null:
		_check_eq(lvl3x2.width, 3, "3x2 fixture width")
		_check_eq(lvl3x2.height, 2, "3x2 fixture height")
		_check_eq(lvl3x2.get_cell_count(), 6, "3x2 fixture cell_count (generic-size proof)")

	var lvl59 := _load_fixture("res://data/levels/test_59x59.json")
	if lvl59 != null:
		_check_eq(lvl59.width, 59, "59x59 fixture width")
		_check_eq(lvl59.height, 59, "59x59 fixture height")
		_check_eq(lvl59.get_cell_count(), 3481, "59x59 fixture cell_count (current production maximum)")

func _run_index_conversion_tests() -> void:
	var sizes: Array[Vector2i] = [Vector2i(40, 40), Vector2i(50, 50), Vector2i(3, 2), Vector2i(59, 59)]
	for size: Vector2i in sizes:
		var w: int = size.x
		var h: int = size.y
		var board = _make_blank_board(w, h)
		var coords := [
			Vector2i(0, 0),
			Vector2i(w - 1, 0),
			Vector2i(0, h - 1),
			Vector2i(w - 1, h - 1),
			Vector2i(w / 2, h / 2),
		]
		for coord in coords:
			var index = board.get_cell_index(coord.x, coord.y)
			_check(index >= 0, "%dx%d index for %s should be valid" % [w, h, coord])
			var back = board.get_cell_position(index)
			_check_eq(back, coord, "%dx%d round-trip for %s" % [w, h, coord])
		# Explicit formula check: index = y * width + x.
		_check_eq(board.get_cell_index(1, 1), h_index_formula(1, 1, w), "%dx%d index formula at (1,1)" % [w, h])

func h_index_formula(x: int, y: int, width: int) -> int:
	return y * width + x

func _run_invalid_coordinate_tests() -> void:
	var board = _make_blank_board(40, 40)
	_check_eq(board.is_valid_coordinate(-1, 0), false, "negative x rejected")
	_check_eq(board.is_valid_coordinate(0, -1), false, "negative y rejected")
	_check_eq(board.is_valid_coordinate(40, 0), false, "x >= width rejected")
	_check_eq(board.is_valid_coordinate(0, 40), false, "y >= height rejected")
	_check_eq(board.is_valid_index(-1), false, "negative index rejected")
	_check_eq(board.is_valid_index(1600), false, "index >= cell_count rejected")
	_check_eq(board.get_cell_index(-1, 0), -1, "get_cell_index returns -1 for invalid coordinate")
	_check_eq(board.get_cell_position(-1), Vector2i(-1, -1), "get_cell_position returns (-1,-1) for invalid index")

func _run_level_validation_tests() -> void:
	var base := {
		"version": 1, "id": "t", "name": "T", "difficulty": "TEST",
		"width": 2, "height": 2, "palette": ["#000", "#111"], "cells": [0, 1, 1, 0],
	}

	# Missing version.
	var d1 := base.duplicate(true)
	d1.erase("version")
	_check(not LevelValidator.validate(d1, "t").is_ok(), "missing version rejected")

	# Unsupported version.
	var d2 := base.duplicate(true)
	d2["version"] = 99
	_check(not LevelValidator.validate(d2, "t").is_ok(), "unsupported version rejected")

	# width <= 0.
	var d3 := base.duplicate(true)
	d3["width"] = 0
	_check(not LevelValidator.validate(d3, "t").is_ok(), "width <= 0 rejected")

	# height <= 0.
	var d4 := base.duplicate(true)
	d4["height"] = -5
	_check(not LevelValidator.validate(d4, "t").is_ok(), "height <= 0 rejected")

	# Wrong cell array length.
	var d5 := base.duplicate(true)
	d5["cells"] = [0, 1, 1]
	_check(not LevelValidator.validate(d5, "t").is_ok(), "wrong cell array length rejected")

	# Empty palette.
	var d6 := base.duplicate(true)
	d6["palette"] = []
	_check(not LevelValidator.validate(d6, "t").is_ok(), "empty palette rejected")

	# Palette id out of range.
	var d7 := base.duplicate(true)
	d7["cells"] = [0, 1, 2, 0]
	_check(not LevelValidator.validate(d7, "t").is_ok(), "out-of-range palette id rejected")

	# Malformed JSON text.
	var malformed_result := LevelLoader.load_from_text("{ not valid json", "malformed_test")
	_check(not malformed_result.is_ok(), "malformed JSON rejected")

	# Valid data still accepted (sanity check the negative tests aren't vacuous).
	_check(LevelValidator.validate(base, "t").is_ok(), "valid base level accepted")

func _run_board_state_tests() -> void:
	var board = _make_blank_board(5, 4)
	_check_eq(board.count_cells_by_state(BoardState.CellState.DIRTY), 20, "new board fully DIRTY")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 0, "new board has no CLEAN cells")

	var target_index = board.get_cell_index(2, 2)
	var mutate_ok = board.set_cell_state(target_index, BoardState.CellState.CLEAN)
	_check(mutate_ok, "valid mutation reports success")
	_check_eq(board.get_cell_state(target_index), BoardState.CellState.CLEAN, "mutated cell reads back CLEAN")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 1, "exactly one CLEAN cell after single mutation")
	_check_eq(board.count_cells_by_state(BoardState.CellState.DIRTY), 19, "remaining cells still DIRTY")

	var neighbor_index = board.get_cell_index(3, 2)
	_check_eq(board.get_cell_state(neighbor_index), BoardState.CellState.DIRTY, "cleaning one cell does not affect neighbor")

	var invalid_mutate = board.set_cell_state(-1, BoardState.CellState.CLEAN)
	_check_eq(invalid_mutate, false, "invalid mutation fails safely")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 1, "failed mutation does not change counts")

func _run_independence_tests() -> void:
	var level := _load_fixture("res://data/levels/test_40x40.json")
	if level == null:
		return
	var board_a := BoardState.from_level_data(level)
	var board_b := BoardState.from_level_data(level)
	board_a.set_cell_state(0, BoardState.CellState.CLEAN)
	_check_eq(board_a.get_cell_state(0), BoardState.CellState.CLEAN, "board A mutated as expected")
	_check_eq(board_b.get_cell_state(0), BoardState.CellState.DIRTY, "board B unaffected by board A mutation (no shared state)")

## Production difficulty/dimension validation — DifficultyRules and
## ProductionLevelValidator. Distinct from _run_level_validation_tests(),
## which only tests generic structural validity (LevelValidator).
func _run_production_difficulty_tests() -> void:
	# --- Easy: 20..29 ---
	_check(ProductionLevelValidator.validate(_make_level("easy_min", "EASY", 20, 20)).is_ok(), "Easy 20x20 (min) PASS -> cell_count %d" % 400)
	_check(ProductionLevelValidator.validate(_make_level("easy_max", "EASY", 29, 29)).is_ok(), "Easy 29x29 (max) PASS -> cell_count %d" % 841)
	_check(ProductionLevelValidator.validate(_make_level("easy_rect", "EASY", 20, 27)).is_ok(), "Easy 20x27 (rectangular) PASS -> cell_count %d" % 540)

	# --- Medium: 30..39 ---
	_check(ProductionLevelValidator.validate(_make_level("medium_min", "MEDIUM", 30, 30)).is_ok(), "Medium 30x30 (min) PASS -> cell_count %d" % 900)
	_check(ProductionLevelValidator.validate(_make_level("medium_max", "MEDIUM", 39, 39)).is_ok(), "Medium 39x39 (max) PASS -> cell_count %d" % 1521)
	_check(ProductionLevelValidator.validate(_make_level("medium_rect", "MEDIUM", 34, 39)).is_ok(), "Medium 34x39 (rectangular) PASS -> cell_count %d" % 1326)

	# --- Hard: 40..49 ---
	_check(ProductionLevelValidator.validate(_make_level("hard_min", "HARD", 40, 40)).is_ok(), "Hard 40x40 (min) PASS -> cell_count %d" % 1600)
	_check(ProductionLevelValidator.validate(_make_level("hard_max", "HARD", 49, 49)).is_ok(), "Hard 49x49 (max) PASS -> cell_count %d" % 2401)
	_check(ProductionLevelValidator.validate(_make_level("hard_rect", "HARD", 48, 41)).is_ok(), "Hard 48x41 (rectangular) PASS -> cell_count %d" % 1968)

	# --- Very Hard: 50..59 ---
	_check(ProductionLevelValidator.validate(_make_level("veryhard_min", "VERY_HARD", 50, 50)).is_ok(), "Very Hard 50x50 (min) PASS -> cell_count %d" % 2500)
	_check(ProductionLevelValidator.validate(_make_level("veryhard_max", "VERY_HARD", 59, 59)).is_ok(), "Very Hard 59x59 (max, current maximum) PASS -> cell_count %d" % 3481)
	_check(ProductionLevelValidator.validate(_make_level("veryhard_rect", "VERY_HARD", 53, 59)).is_ok(), "Very Hard 53x59 (rectangular) PASS -> cell_count %d" % 3127)

	# --- Cross-band (upper) rejection ---
	_check(not ProductionLevelValidator.validate(_make_level("easy_bad_upper", "EASY", 20, 30)).is_ok(), "Easy 20x30 rejected (height out of band)")
	_check(not ProductionLevelValidator.validate(_make_level("medium_bad_upper", "MEDIUM", 39, 40)).is_ok(), "Medium 39x40 rejected (height out of band)")
	_check(not ProductionLevelValidator.validate(_make_level("hard_bad_upper", "HARD", 49, 50)).is_ok(), "Hard 49x50 rejected (height out of band)")
	_check(not ProductionLevelValidator.validate(_make_level("veryhard_bad_upper", "VERY_HARD", 49, 59)).is_ok(), "Very Hard 49x59 rejected (width out of band)")

	# --- Cross-band (lower) rejection ---
	_check(not ProductionLevelValidator.validate(_make_level("easy_bad_lower", "EASY", 19, 20)).is_ok(), "Easy 19x20 rejected (width below band)")
	_check(not ProductionLevelValidator.validate(_make_level("medium_bad_lower", "MEDIUM", 29, 30)).is_ok(), "Medium 29x30 rejected (width below band)")
	_check(not ProductionLevelValidator.validate(_make_level("hard_bad_lower", "HARD", 39, 40)).is_ok(), "Hard 39x40 rejected (width below band)")
	_check(not ProductionLevelValidator.validate(_make_level("veryhard_bad_lower", "VERY_HARD", 49, 50)).is_ok(), "Very Hard 49x50 rejected (width below band)")

	# --- Unknown production difficulty ---
	var unknown_result = ProductionLevelValidator.validate(_make_level("mystery", "IMPOSSIBLE", 40, 40))
	_check(not unknown_result.is_ok(), "unknown difficulty 'IMPOSSIBLE' rejected, not silently accepted as any known band")

	# --- TEST vs. production distinction (core of this phase) ---
	var test_level = _load_fixture("res://data/levels/test_3x2.json")
	if test_level != null:
		_check_eq(test_level.difficulty, "TEST", "3x2 fixture is difficulty TEST")
		# Structurally valid and loads fine (generic engine proof)...
		var board = BoardState.from_level_data(test_level)
		_check_eq(board.get_cell_count(), 6, "3x2 TEST fixture still works structurally via BoardState")
		# ...but is explicitly rejected as production content.
		var prod_result = ProductionLevelValidator.validate(test_level)
		_check(not prod_result.is_ok(), "3x2 TEST fixture rejected by ProductionLevelValidator (TEST is not production-legal)")
		var same_dims_as_easy = _make_level("would_be_easy_if_test_werent_test", "EASY", 20, 20)
		_check(ProductionLevelValidator.validate(same_dims_as_easy).is_ok(), "sanity: identical validator logic accepts a real EASY level (difficulty is the deciding factor, not some hidden dimension rule)")

func _run_max_board_tests() -> void:
	var level = _load_fixture("res://data/levels/test_59x59.json")
	if level == null:
		return
	var board = BoardState.from_level_data(level)
	_check_eq(board.get_width(), 59, "59x59 BoardState width")
	_check_eq(board.get_height(), 59, "59x59 BoardState height")
	_check_eq(board.get_cell_count(), 3481, "59x59 BoardState cell_count")

	var corners: Array[Vector2i] = [Vector2i(0, 0), Vector2i(58, 0), Vector2i(0, 58), Vector2i(58, 58), Vector2i(29, 29)]
	for corner: Vector2i in corners:
		var index = board.get_cell_index(corner.x, corner.y)
		_check(board.is_valid_index(index), "59x59 corner %s produces a valid index" % corner)
		_check_eq(board.get_cell_position(index), corner, "59x59 corner %s round-trips through index" % corner)

	var mutate_ok = board.set_cell_state(board.get_cell_index(29, 29), BoardState.CellState.CLEAN)
	_check(mutate_ok, "59x59 center-cell mutation succeeds")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 1, "59x59 exactly one CLEAN cell after single mutation")
	_check_eq(board.count_cells_by_state(BoardState.CellState.DIRTY), 3480, "59x59 remaining 3480 cells still DIRTY")

func _run_performance_sanity() -> void:
	var level := _load_fixture("res://data/levels/test_50x50.json")
	if level == null:
		return
	var iterations := 50

	var t0 := Time.get_ticks_usec()
	var board
	for i in iterations:
		board = BoardState.from_level_data(level)
	var t1 := Time.get_ticks_usec()

	var sum := 0
	for i in iterations:
		for c in board.get_cell_count():
			sum += board.get_color_id(c)
	var t2 := Time.get_ticks_usec()

	var dirty_count := 0
	for i in iterations:
		dirty_count = board.count_cells_by_state(BoardState.CellState.DIRTY)
	var t3 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		var pos = board.get_cell_position(i)
		board.get_cell_index(pos.x, pos.y)
	var t4 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEAN)
	var t5 := Time.get_ticks_usec()

	_check_eq(board.get_cell_count(), 2500, "performance sanity operates on 50x50 (2500 cells)")
	_check_eq(dirty_count, 2500, "performance sanity read DIRTY count before mutation pass")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 2500, "bulk mutation cleaned all cells")

	print("---- performance sanity (50x50 = 2500 cells, %d iterations where applicable) ----" % iterations)
	print("  construct BoardState.from_level_data x%d: %.3f ms total, %.4f ms/iter" % [iterations, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / iterations])
	print("  read all cells x%d passes: %.3f ms total, %.4f ms/pass" % [iterations, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / iterations])
	print("  count_cells_by_state x%d: %.3f ms total, %.4f ms/call" % [iterations, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / iterations])
	print("  coordinate<->index round trip over all cells: %.3f ms" % ((t4 - t3) / 1000.0))
	print("  set_cell_state over all cells (bulk clean): %.3f ms" % ((t5 - t4) / 1000.0))
	print("  (sum-of-color-ids sink value: %d — prevents dead-code elimination of the read loop)" % sum)

## Extends performance sanity to the CURRENT production maximum (59x59 =
## 3481 cells), per this phase's requirement. The 50x50 benchmark above is
## kept as-is for regression continuity, not replaced.
func _run_performance_sanity_59x59() -> void:
	var level := _load_fixture("res://data/levels/test_59x59.json")
	if level == null:
		return
	var iterations := 50

	var t0 := Time.get_ticks_usec()
	var board
	for i in iterations:
		board = BoardState.from_level_data(level)
	var t1 := Time.get_ticks_usec()

	var sum := 0
	for i in iterations:
		for c in board.get_cell_count():
			sum += board.get_color_id(c)
	var t2 := Time.get_ticks_usec()

	var dirty_count := 0
	for i in iterations:
		dirty_count = board.count_cells_by_state(BoardState.CellState.DIRTY)
	var t3 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		var pos = board.get_cell_position(i)
		board.get_cell_index(pos.x, pos.y)
	var t4 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEAN)
	var t5 := Time.get_ticks_usec()

	_check_eq(board.get_cell_count(), 3481, "performance sanity operates on 59x59 (3481 cells, current maximum)")
	_check_eq(dirty_count, 3481, "performance sanity read DIRTY count before mutation pass")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEAN), 3481, "bulk mutation cleaned all cells")

	print("---- performance sanity (59x59 = 3481 cells, CURRENT MAXIMUM, %d iterations where applicable) ----" % iterations)
	print("  construct BoardState.from_level_data x%d: %.3f ms total, %.4f ms/iter" % [iterations, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / iterations])
	print("  read all cells x%d passes: %.3f ms total, %.4f ms/pass" % [iterations, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / iterations])
	print("  count_cells_by_state x%d: %.3f ms total, %.4f ms/call" % [iterations, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / iterations])
	print("  coordinate<->index round trip over all cells: %.3f ms" % ((t4 - t3) / 1000.0))
	print("  set_cell_state over all cells (bulk clean): %.3f ms" % ((t5 - t4) / 1000.0))
	print("  (sum-of-color-ids sink value: %d — prevents dead-code elimination of the read loop)" % sum)

func _make_blank_board(width: int, height: int):
	var level = _make_level("blank_%dx%d" % [width, height], "TEST", width, height)
	return BoardState.from_level_data(level)

## Builds an in-memory LevelData directly (bypassing JSON) for testing
## DifficultyRules/ProductionLevelValidator logic against many width/height/
## difficulty combinations without needing one fixture file per combination.
## Cell content is irrelevant to these tests, so cells are filled with a
## single valid palette id.
func _make_level(id: String, difficulty: String, width: int, height: int) -> LevelData:
	var palette := PackedStringArray(["#000000"])
	var cells := PackedInt32Array()
	cells.resize(width * height)
	return LevelData.new(1, id, id, difficulty, width, height, palette, cells)

func _print_summary() -> void:
	print("")
	print("==== SCRUBBOTS test summary ====")
	print("Total checks: %d" % _total)
	print("Failures: %d" % _failures.size())
	if _failures.is_empty():
		print("RESULT: ALL PASS")
	else:
		print("RESULT: FAIL")
		for f in _failures:
			print("  - FAIL: %s" % f)
