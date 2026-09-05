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
const PaletteColors = preload("res://scripts/data/palette_colors.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const DirtyCleanPresets = preload("res://scripts/gameplay/board/dirty_clean_presets.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const LevelBatchImporter = preload("res://scripts/tools/level_batch_importer.gd")
const GameplaySession = preload("res://scripts/gameplay/session/gameplay_session.gd")
const SlotState = preload("res://scripts/gameplay/slots/slot_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const EligibleTargetIndex = preload("res://scripts/gameplay/routing/eligible_target_index.gd")

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
	_run_palette_colors_tests()
	_run_dirty_clean_transform_tests()
	_run_board_renderer_geometry_tests()
	_run_board_renderer_pixel_tests()
	_run_board_renderer_performance_sanity()
	_run_importer_tests()
	_run_batch_importer_tests()
	_run_gameplay_session_tests()
	_run_slot_system_tests()
	_run_eligible_target_index_tests()
	_run_eligible_target_index_benchmark()
	_print_summary()
	quit(0 if _failures.is_empty() else 1)

# ---------------------------------------------------------------- helpers --

func _check(condition: bool, description: String) -> void:
	_total += 1
	if not condition:
		_failures.append(description)

func _check_eq(actual, expected, description: String) -> void:
	_check(actual == expected, "%s (expected %s, got %s)" % [description, str(expected), str(actual)])

## Renderer pixel readback goes through an 8-bit-per-channel Image, so exact
## float equality (Color.is_equal_approx's ~1e-5 epsilon) is the wrong tool
## for comparing a rendered pixel against an independently-computed float
## Color — use this looser, quantization-aware comparison instead.
func _colors_close(a: Color, b: Color, tolerance: float) -> bool:
	return (
		absf(a.r - b.r) <= tolerance and
		absf(a.g - b.g) <= tolerance and
		absf(a.b - b.b) <= tolerance and
		absf(a.a - b.a) <= tolerance
	)

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

## ---------------------------------------------------------- M06: renderer --

func _run_palette_colors_tests() -> void:
	var result = PaletteColors.parse(PackedStringArray(["#ff0000", "#00ff00"]))
	_check(result.is_ok(), "well-formed palette parses without errors")
	_check_eq(result.colors.size(), 2, "palette parse produces one Color per entry")
	_check(result.colors[0].is_equal_approx(Color(1, 0, 0)), "palette entry 0 parses to red")
	_check(result.colors[1].is_equal_approx(Color(0, 1, 0)), "palette entry 1 parses to green")

	var bad_result = PaletteColors.parse(PackedStringArray(["not-a-color"]))
	_check(not bad_result.is_ok(), "malformed palette entry reported as an error")
	_check_eq(bad_result.colors.size(), 1, "malformed entry still produces a fallback color (doesn't abort parsing)")

	_check(result.colors[0].is_equal_approx(PaletteColors.parse(PackedStringArray(["#ff0000"])).colors[0]), "palette parsing is deterministic")

func _run_dirty_clean_transform_tests() -> void:
	var base := Color.html("#ff0000") # pure red: s=1.0, v=1.0
	var base_s := base.s
	var base_v := base.v

	var dirty_a := DirtyCleanPresets.apply_dirty(base, "A")
	var dirty_b := DirtyCleanPresets.apply_dirty(base, "B")
	var dirty_c := DirtyCleanPresets.apply_dirty(base, "C")

	_check(not dirty_a.is_equal_approx(base), "DIRTY preset A differs from CLEAN (base) color")
	_check(not dirty_b.is_equal_approx(base), "DIRTY preset B differs from CLEAN (base) color")
	_check(not dirty_c.is_equal_approx(base), "DIRTY preset C differs from CLEAN (base) color")

	_check(not dirty_a.is_equal_approx(dirty_b), "preset A differs from preset B (preset switching has an effect)")
	_check(not dirty_b.is_equal_approx(dirty_c), "preset B differs from preset C")
	_check(not dirty_a.is_equal_approx(dirty_c), "preset A differs from preset C")

	for entry in [["A", dirty_a], ["B", dirty_b], ["C", dirty_c]]:
		var name = entry[0]
		var color: Color = entry[1]
		_check(color.s < base_s, "preset %s reduces saturation relative to CLEAN" % name)
		_check(color.v < base_v, "preset %s reduces value/brightness relative to CLEAN (not saturation alone)" % name)
		_check(absf(color.h - base.h) < 0.001, "preset %s preserves hue (color family stays recognizable)" % name)

	_check_eq(base.s, base_s, "applying DIRTY transforms does not mutate the original base Color")
	_check_eq(base.v, base_v, "applying DIRTY transforms does not mutate the original base Color (value)")

func _run_board_renderer_geometry_tests() -> void:
	var sizes: Array[Vector2i] = [
		Vector2i(20, 20), Vector2i(29, 29), Vector2i(20, 27),
		Vector2i(30, 30), Vector2i(39, 39), Vector2i(34, 39),
		Vector2i(40, 40), Vector2i(49, 49), Vector2i(48, 41),
		Vector2i(50, 50), Vector2i(59, 59), Vector2i(53, 59),
	]
	var available := Vector2(1000, 1400)
	for size: Vector2i in sizes:
		var w := size.x
		var h := size.y
		var level = BoardDebugFixtures.make_level(w, h)
		var board = BoardState.from_level_data(level)
		var renderer = BoardRenderer.new()
		renderer.configure(board, level.palette, available)

		var expected_cell_size: float = max(floor(min(available.x / float(w), available.y / float(h))), 1.0)
		_check_eq(renderer.get_cell_size(), expected_cell_size, "%dx%d cell_size matches fit-to-available formula" % [w, h])

		var expected_pixel_size := Vector2(w * expected_cell_size, h * expected_cell_size)
		_check(renderer.get_board_pixel_size().is_equal_approx(expected_pixel_size), "%dx%d board pixel size == width/height * cell_size" % [w, h])

		var top_left := renderer.get_cell_center_local(0, 0)
		var bottom_right := renderer.get_cell_center_local(w - 1, h - 1)
		_check(top_left.x >= 0 and top_left.y >= 0, "%dx%d (0,0) cell center is inside board bounds (>= 0)" % [w, h])
		_check(bottom_right.x <= expected_pixel_size.x and bottom_right.y <= expected_pixel_size.y, "%dx%d final-cell center does not overflow board bounds" % [w, h])

		_check_eq(renderer.get_child_count(), 0, "%dx%d BoardRenderer has zero child Nodes (no per-cell architecture)" % [w, h])

		renderer.free()

func _run_board_renderer_pixel_tests() -> void:
	# 2x1 board: both cells same palette color id, cell 0 CLEAN, cell 1 DIRTY.
	var palette := PackedStringArray(["#3B82F6"])
	var cells := PackedInt32Array([0, 0])
	var level := LevelData.new(1, "renderer_pixel_test", "t", "TEST", 2, 1, palette, cells)
	var board := BoardState.from_level_data(level)
	board.set_cell_state(0, BoardState.CellState.CLEAN)
	board.set_cell_state(1, BoardState.CellState.DIRTY)

	var states_before: Array = [board.get_cell_state(0), board.get_cell_state(1)]

	var renderer = BoardRenderer.new()
	renderer.configure(board, palette, Vector2(200, 200))
	renderer.set_dirty_preset("A")

	var base_color := Color.html("#3B82F6")

	# Renderer output is read back through an 8-bit-per-channel Image, so it
	# necessarily differs slightly (quantization, ~1/255 per channel) from an
	# independently-computed float Color — comparing to a precomputed exact
	# value would be the brittle float-equality test the test strategy
	# warns against (docs/06_TEST_STRATEGY.md). Test the meaningful contract
	# instead: CLEAN matches the source color (within quantization), and
	# DIRTY vs CLEAN differ with the right HSV relationship.
	var clean_pixel := renderer.get_pixel_color(0, 0)
	var dirty_pixel := renderer.get_pixel_color(1, 0)

	_check(_colors_close(clean_pixel, base_color, 0.01), "CLEAN cell renders the original source palette color, unmodified (within 8-bit quantization)")
	_check(not _colors_close(dirty_pixel, clean_pixel, 0.01), "DIRTY and CLEAN cells of the same source color render visibly differently")
	_check(dirty_pixel.s < clean_pixel.s, "DIRTY pixel has lower saturation than CLEAN (readback matches the preset contract)")
	_check(dirty_pixel.v < clean_pixel.v, "DIRTY pixel has lower value/brightness than CLEAN (not saturation alone)")
	_check(absf(dirty_pixel.h - clean_pixel.h) < 0.01, "DIRTY pixel preserves CLEAN's hue (color family stays recognizable)")

	# update_cells(): clean the dirty cell without a full refresh_all().
	board.set_cell_state(1, BoardState.CellState.CLEAN)
	renderer.update_cells([1])
	_check(_colors_close(renderer.get_pixel_color(1, 0), base_color, 0.01), "update_cells() reflects a single cell's state change without a full rebuild")

	var states_after: Array = [board.get_cell_state(0), board.get_cell_state(1)]
	_check_eq(states_after, [BoardState.CellState.CLEAN, BoardState.CellState.CLEAN], "BoardState reflects the test's own mutation (sanity)")
	_check(states_before[0] == BoardState.CellState.CLEAN, "BoardRenderer.configure()/refresh_all() did not mutate BoardState (cell 0 unchanged)")

	renderer.free()

func _run_board_renderer_performance_sanity() -> void:
	var sizes: Array[Vector2i] = [Vector2i(40, 40), Vector2i(50, 50), Vector2i(59, 59), Vector2i(53, 59)]
	for size: Vector2i in sizes:
		var w := size.x
		var h := size.y
		var level = BoardDebugFixtures.make_level(w, h)
		var board = BoardState.from_level_data(level)
		var renderer = BoardRenderer.new()

		var t0 := Time.get_ticks_usec()
		renderer.configure(board, level.palette, Vector2(1080, 1080))
		var t1 := Time.get_ticks_usec()

		var iterations := 20
		for i in iterations:
			renderer.refresh_all()
		var t2 := Time.get_ticks_usec()

		for i in iterations:
			renderer.update_cells([0, board.get_cell_count() - 1])
		var t3 := Time.get_ticks_usec()

		print("---- BoardRenderer performance sanity (%dx%d = %d cells) ----" % [w, h, w * h])
		print("  configure() (setup + first full render): %.3f ms" % ((t1 - t0) / 1000.0))
		print("  refresh_all() x%d: %.3f ms total, %.4f ms/call" % [iterations, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / iterations])
		print("  update_cells([2 cells]) x%d: %.3f ms total, %.4f ms/call" % [iterations, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / iterations])

		_check_eq(renderer.get_child_count(), 0, "%dx%d renderer still has zero children after repeated refresh/update" % [w, h])
		renderer.free()

func _run_importer_tests() -> void:
	var test_dir := "user://test_importer/"
	DirAccess.make_dir_recursive_absolute(test_dir)

	# --- helper: save a test PNG to disk ---
	var _save_png := func(img: Image, name: String) -> String:
		var path := test_dir + name
		img.save_png(path)
		return path

	# ---- 1. 3x2 non-square with transparency + 3 opaque colors (4 total) ----
	var img_3x2 := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	# Row 0: red, green, transparent
	# Row 1: blue, red, green  (repeated colors in separated positions)
	var c_red := Color(0.9, 0.2, 0.1, 1.0)
	var c_green := Color(0.1, 0.8, 0.2, 1.0)
	var c_trans := Color(0, 0, 0, 0)
	var c_blue := Color(0.1, 0.2, 0.9, 1.0)
	img_3x2.set_pixel(0, 0, c_red)
	img_3x2.set_pixel(1, 0, c_green)
	img_3x2.set_pixel(2, 0, c_trans)
	img_3x2.set_pixel(0, 1, c_blue)
	img_3x2.set_pixel(1, 1, c_red)
	img_3x2.set_pixel(2, 1, c_green)
	var path_3x2: String = _save_png.call(img_3x2, "test_3x2.png")

	var req_3x2 := LevelImporter.ImportRequest.new(
		path_3x2, "imp_3x2", "Importer 3x2", "TEST",
		test_dir + "imp_3x2.json",
		test_dir + "imp_3x2_preview.png",
		test_dir + "imp_3x2_meta.json"
	)
	var res_3x2 := LevelImporter.run_import(req_3x2)
	_check(res_3x2.is_ok(), "3x2 import succeeds")
	_check_eq(res_3x2.level_data.width, 3, "3x2 import width")
	_check_eq(res_3x2.level_data.height, 2, "3x2 import height")
	_check_eq(res_3x2.level_data.get_cell_count(), 6, "3x2 import cell count")
	_check_eq(res_3x2.level_data.difficulty, "TEST", "3x2 import difficulty")

	# Palette order must be first-seen: red(0), green(1), transparent(2), blue(3)
	_check_eq(res_3x2.level_data.palette.size(), 4, "3x2 palette count")
	# Cell [0,0]=red=0, [1,0]=green=1, [2,0]=trans=2, [0,1]=blue=3, [1,1]=red=0, [2,1]=green=1
	_check_eq(res_3x2.level_data.cells[0], 0, "3x2 cell[0,0] = palette 0 (red, first-seen)")
	_check_eq(res_3x2.level_data.cells[1], 1, "3x2 cell[1,0] = palette 1 (green)")
	_check_eq(res_3x2.level_data.cells[2], 2, "3x2 cell[2,0] = palette 2 (transparent)")
	_check_eq(res_3x2.level_data.cells[3], 3, "3x2 cell[0,1] = palette 3 (blue)")
	_check_eq(res_3x2.level_data.cells[4], 0, "3x2 cell[1,1] = palette 0 (red reuse)")
	_check_eq(res_3x2.level_data.cells[5], 1, "3x2 cell[2,1] = palette 1 (green reuse)")

	# Verify output files written
	_check(res_3x2.output_written, "3x2 output JSON written")
	_check(res_3x2.preview_written, "3x2 preview PNG written")
	_check(res_3x2.metadata_written, "3x2 metadata JSON written")
	_check(FileAccess.file_exists(req_3x2.output_path), "3x2 output file exists")
	_check(FileAccess.file_exists(req_3x2.preview_path), "3x2 preview file exists")

	# Verify structural validation of generated level data
	var load_result := LevelLoader.load_from_path(req_3x2.output_path)
	_check(load_result.is_ok(), "3x2 generated JSON passes LevelValidator")

	# ---- 2. Pixel-perfect reconstruction (3x2) ----
	var recon_3x2 := LevelImporter.reconstruct_image(res_3x2.level_data)
	_check(recon_3x2 != null, "3x2 reconstruction succeeds")
	if recon_3x2 != null:
		_check_eq(recon_3x2.get_width(), 3, "3x2 reconstruction width")
		_check_eq(recon_3x2.get_height(), 2, "3x2 reconstruction height")
		_check_eq(recon_3x2.get_format(), Image.FORMAT_RGBA8, "3x2 reconstruction format")
		# Reload source from disk to compare raw bytes
		var src_reload := Image.new()
		src_reload.load(path_3x2)
		if src_reload.get_format() != Image.FORMAT_RGBA8:
			src_reload.convert(Image.FORMAT_RGBA8)
		_check_eq(recon_3x2.get_data(), src_reload.get_data(), "3x2 reconstruction raw RGBA8 bytes match source")

	# ---- 3. Deterministic rerun (same input = same output) ----
	var req_3x2_rerun := LevelImporter.ImportRequest.new(
		path_3x2, "imp_3x2", "Importer 3x2", "TEST",
		test_dir + "imp_3x2.json", "", "", false
	)
	var res_3x2_rerun := LevelImporter.run_import(req_3x2_rerun)
	_check(res_3x2_rerun.is_ok(), "3x2 rerun import succeeds")
	_check(res_3x2_rerun.output_unchanged, "3x2 rerun detects UNCHANGED (no meaningless diff)")

	# ---- 4. Rectangular production-band (20x27 EASY) ----
	var img_20x27 := LevelImporter.generate_test_png(20, 27, 5, true, false)
	var path_20x27: String = _save_png.call(img_20x27, "test_20x27.png")
	var req_20x27 := LevelImporter.ImportRequest.new(
		path_20x27, "imp_20x27", "Importer 20x27", "EASY",
		test_dir + "imp_20x27.json", test_dir + "imp_20x27_preview.png"
	)
	var res_20x27 := LevelImporter.run_import(req_20x27)
	_check(res_20x27.is_ok(), "20x27 EASY import succeeds")
	_check_eq(res_20x27.level_data.width, 20, "20x27 import width exact")
	_check_eq(res_20x27.level_data.height, 27, "20x27 import height exact")
	_check_eq(res_20x27.level_data.difficulty, "EASY", "20x27 import difficulty")
	# Production validation
	var prod_20x27 := ProductionLevelValidator.validate(res_20x27.level_data)
	_check(prod_20x27.is_ok(), "20x27 EASY passes production validator")
	# Structural validation
	var load_20x27 := LevelLoader.load_from_path(req_20x27.output_path)
	_check(load_20x27.is_ok(), "20x27 generated JSON passes LevelValidator")

	# Reconstruction round-trip
	var recon_20x27 := LevelImporter.reconstruct_image(res_20x27.level_data)
	_check(recon_20x27 != null, "20x27 reconstruction succeeds")
	if recon_20x27 != null:
		var src_20x27 := Image.new()
		src_20x27.load(path_20x27)
		if src_20x27.get_format() != Image.FORMAT_RGBA8:
			src_20x27.convert(Image.FORMAT_RGBA8)
		_check_eq(recon_20x27.get_data(), src_20x27.get_data(), "20x27 reconstruction raw RGBA8 bytes match")

	# Deterministic rerun
	var req_20x27_rerun := LevelImporter.ImportRequest.new(
		path_20x27, "imp_20x27", "Importer 20x27", "EASY",
		test_dir + "imp_20x27.json", "", "", false
	)
	var res_20x27_rerun := LevelImporter.run_import(req_20x27_rerun)
	_check(res_20x27_rerun.is_ok(), "20x27 rerun succeeds")
	_check(res_20x27_rerun.output_unchanged, "20x27 rerun UNCHANGED")

	# ---- 5. 59x59 maximum (VERY_HARD) ----
	var img_59x59 := LevelImporter.generate_test_png(59, 59, 8, true, false)
	var path_59x59: String = _save_png.call(img_59x59, "test_59x59.png")
	var req_59x59 := LevelImporter.ImportRequest.new(
		path_59x59, "imp_59x59", "Importer 59x59", "VERY_HARD",
		test_dir + "imp_59x59.json"
	)
	var res_59x59 := LevelImporter.run_import(req_59x59)
	_check(res_59x59.is_ok(), "59x59 VERY_HARD import succeeds")
	_check_eq(res_59x59.level_data.width, 59, "59x59 import width")
	_check_eq(res_59x59.level_data.height, 59, "59x59 import height")
	_check_eq(res_59x59.level_data.get_cell_count(), 3481, "59x59 cell count")
	var prod_59x59 := ProductionLevelValidator.validate(res_59x59.level_data)
	_check(prod_59x59.is_ok(), "59x59 passes production validator")

	# Reconstruction
	var recon_59x59 := LevelImporter.reconstruct_image(res_59x59.level_data)
	_check(recon_59x59 != null, "59x59 reconstruction succeeds")
	if recon_59x59 != null:
		var src_59x59 := Image.new()
		src_59x59.load(path_59x59)
		if src_59x59.get_format() != Image.FORMAT_RGBA8:
			src_59x59.convert(Image.FORMAT_RGBA8)
		_check_eq(recon_59x59.get_data(), src_59x59.get_data(), "59x59 reconstruction raw RGBA8 bytes match")

	# ---- 6. Semi-transparent alpha pixel round-trip ----
	var img_alpha := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img_alpha.set_pixel(0, 0, Color(1.0, 0.0, 0.0, 1.0))
	img_alpha.set_pixel(1, 0, Color(0.0, 1.0, 0.0, 0.0))
	img_alpha.set_pixel(0, 1, Color(0.0, 0.0, 1.0, 0.5))
	img_alpha.set_pixel(1, 1, Color(1.0, 1.0, 0.0, 1.0))
	var path_alpha: String = _save_png.call(img_alpha, "test_alpha.png")
	var req_alpha := LevelImporter.ImportRequest.new(
		path_alpha, "imp_alpha", "Alpha Test", "TEST",
		test_dir + "imp_alpha.json"
	)
	var res_alpha := LevelImporter.run_import(req_alpha)
	_check(res_alpha.is_ok(), "alpha import succeeds")
	var recon_alpha := LevelImporter.reconstruct_image(res_alpha.level_data)
	if recon_alpha != null:
		var src_alpha := Image.new()
		src_alpha.load(path_alpha)
		if src_alpha.get_format() != Image.FORMAT_RGBA8:
			src_alpha.convert(Image.FORMAT_RGBA8)
		_check_eq(recon_alpha.get_data(), src_alpha.get_data(), "alpha pixels round-trip exactly (including semi-transparent)")

	# ---- 7. Performance sanity at 59x59 ----
	var t0 := Time.get_ticks_usec()
	var _perf_res := LevelImporter.run_import(LevelImporter.ImportRequest.new(
		path_59x59, "perf_59x59", "Perf 59x59", "VERY_HARD",
		test_dir + "perf_59x59.json", "", "", true
	))
	var t1 := Time.get_ticks_usec()
	var recon_t0 := Time.get_ticks_usec()
	var _perf_recon := LevelImporter.reconstruct_image(_perf_res.level_data)
	var recon_t1 := Time.get_ticks_usec()
	print("---- LevelImporter performance sanity (59x59 = 3481 cells) ----")
	print("  full import (load+extract+validate+write): %.3f ms" % ((t1 - t0) / 1000.0))
	print("  reconstruction: %.3f ms" % ((recon_t1 - recon_t0) / 1000.0))

	# ---- NEGATIVE TESTS ----

	# Missing input file
	var req_missing := LevelImporter.ImportRequest.new(
		"user://nonexistent.png", "bad", "Bad", "TEST", test_dir + "bad.json"
	)
	var res_missing := LevelImporter.run_import(req_missing)
	_check(not res_missing.is_ok(), "missing file import fails")
	_check(res_missing.errors[0].find("Could not load") >= 0, "missing file error is actionable")

	# Unsupported extension (try loading a JSON as image)
	var dummy_path := test_dir + "dummy.txt"
	var df := FileAccess.open(dummy_path, FileAccess.WRITE)
	if df: df.store_string("not an image"); df.close()
	var req_bad_ext := LevelImporter.ImportRequest.new(
		dummy_path, "bad_ext", "Bad Ext", "TEST", test_dir + "bad_ext.json"
	)
	var res_bad_ext := LevelImporter.run_import(req_bad_ext)
	_check(not res_bad_ext.is_ok(), "non-image file import fails")

	# Empty level ID
	var req_no_id := LevelImporter.ImportRequest.new(
		path_3x2, "", "Name", "TEST", test_dir + "no_id.json"
	)
	_check(not LevelImporter.run_import(req_no_id).is_ok(), "empty level_id rejected")

	# Empty display name
	var req_no_name := LevelImporter.ImportRequest.new(
		path_3x2, "id", "", "TEST", test_dir + "no_name.json"
	)
	_check(not LevelImporter.run_import(req_no_name).is_ok(), "empty display_name rejected")

	# Unknown difficulty
	var req_bad_diff := LevelImporter.ImportRequest.new(
		path_3x2, "id", "Name", "EXTREME", test_dir + "bad_diff.json"
	)
	_check(not LevelImporter.run_import(req_bad_diff).is_ok(), "unknown difficulty rejected")

	# TEST rejected by production validator
	var test_level = res_3x2.level_data
	var prod_test := ProductionLevelValidator.validate(test_level)
	_check(not prod_test.is_ok(), "TEST level rejected by production validator")

	# Production dimensions outside requested band (3x2 with EASY)
	var req_wrong_band := LevelImporter.ImportRequest.new(
		path_3x2, "wrong", "Wrong", "EASY", test_dir + "wrong_band.json"
	)
	_check(not LevelImporter.run_import(req_wrong_band).is_ok(), "3x2 with EASY rejected (outside band)")

	# Auto-difficulty tests
	_check_eq(LevelImporter.auto_difficulty(20, 29), "EASY", "auto_difficulty 20x29 = EASY")
	_check_eq(LevelImporter.auto_difficulty(35, 35), "MEDIUM", "auto_difficulty 35x35 = MEDIUM")
	_check_eq(LevelImporter.auto_difficulty(59, 50), "VERY_HARD", "auto_difficulty 59x50 = VERY_HARD")
	_check_eq(LevelImporter.auto_difficulty(3, 2), "", "auto_difficulty 3x2 = empty (out of band)")
	_check_eq(LevelImporter.auto_difficulty(19, 20), "", "auto_difficulty 19x20 = empty (cross-band)")

	# Overwrite safety: existing file, overwrite=false, content differs
	var clash_path := test_dir + "clash.json"
	var cf := FileAccess.open(clash_path, FileAccess.WRITE)
	if cf: cf.store_string("different content"); cf.close()
	var req_clash := LevelImporter.ImportRequest.new(
		path_3x2, "clash", "Clash", "TEST", clash_path, "", "", false
	)
	_check(not LevelImporter.run_import(req_clash).is_ok(), "overwrite safety rejects collision")

	# Overwrite=true works
	var req_overwrite := LevelImporter.ImportRequest.new(
		path_3x2, "clash", "Clash", "TEST", clash_path, "", "", true
	)
	_check(LevelImporter.run_import(req_overwrite).is_ok(), "overwrite=true succeeds on collision")

	# ---- F-M09-001: PATH ALIAS SAFETY ----
	var src_bytes_before := FileAccess.get_file_as_bytes(path_3x2)

	# output == source, overwrite=false
	var req_alias_1 := LevelImporter.ImportRequest.new(
		path_3x2, "alias1", "Alias", "TEST", path_3x2, "", "", false
	)
	_check(not LevelImporter.run_import(req_alias_1).is_ok(), "output==source overwrite=false rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after output alias attempt (ow=false)")

	# output == source, overwrite=true (source must STILL be immutable)
	var req_alias_2 := LevelImporter.ImportRequest.new(
		path_3x2, "alias2", "Alias", "TEST", path_3x2, "", "", true
	)
	_check(not LevelImporter.run_import(req_alias_2).is_ok(), "output==source overwrite=true rejected (source immutable)")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after output alias attempt (ow=true)")

	# preview == source
	var req_alias_3 := LevelImporter.ImportRequest.new(
		path_3x2, "alias3", "Alias", "TEST", test_dir + "alias3.json", path_3x2, "", false
	)
	_check(not LevelImporter.run_import(req_alias_3).is_ok(), "preview==source rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after preview alias")

	# metadata == source
	var req_alias_4 := LevelImporter.ImportRequest.new(
		path_3x2, "alias4", "Alias", "TEST", test_dir + "alias4.json", "", path_3x2, false
	)
	_check(not LevelImporter.run_import(req_alias_4).is_ok(), "metadata==source rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after metadata alias")

	# output == preview
	var shared_path := test_dir + "shared_out_prev.json"
	var req_alias_5 := LevelImporter.ImportRequest.new(
		path_3x2, "alias5", "Alias", "TEST", shared_path, shared_path, "", false
	)
	_check(not LevelImporter.run_import(req_alias_5).is_ok(), "output==preview rejected")

	# output == metadata
	var req_alias_6 := LevelImporter.ImportRequest.new(
		path_3x2, "alias6", "Alias", "TEST", shared_path, "", shared_path, false
	)
	_check(not LevelImporter.run_import(req_alias_6).is_ok(), "output==metadata rejected")

	# preview == metadata
	var req_alias_7 := LevelImporter.ImportRequest.new(
		path_3x2, "alias7", "Alias", "TEST", test_dir + "alias7.json", shared_path, shared_path, false
	)
	_check(not LevelImporter.run_import(req_alias_7).is_ok(), "preview==metadata rejected")

	# ---- F-M09-005: FILESYSTEM IDENTITY NORMALIZATION (equivalent-path aliases) ----
	# AL-013: cosmetic string normalization is not enough — dot segments and
	# relative-vs-absolute equivalents must resolve to the same identity.

	# 1. source vs "./" equivalent output path, overwrite=false
	var dotslash_alias_path: String = test_dir + "./test_3x2.png"
	var req_dotslash := LevelImporter.ImportRequest.new(
		path_3x2, "dotslash", "DotSlash", "TEST", dotslash_alias_path, "", "", false
	)
	_check(not LevelImporter.run_import(req_dotslash).is_ok(), "output=='./' equivalent of source rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after './' equivalent alias attempt")

	# 2. source vs "subdir/../" equivalent output path, overwrite=false
	var dotdot_alias_path: String = test_dir + "subdir/../test_3x2.png"
	var req_dotdot := LevelImporter.ImportRequest.new(
		path_3x2, "dotdot", "DotDot", "TEST", dotdot_alias_path, "", "", false
	)
	_check(not LevelImporter.run_import(req_dotdot).is_ok(), "output=='subdir/../' equivalent of source rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after 'subdir/../' equivalent alias attempt")

	# 3. equivalent relative-vs-absolute identity: absolute globalized form of the
	#    user:// source path used as output_path (no scheme, is_absolute_path()==true)
	var abs_path_3x2: String = ProjectSettings.globalize_path(path_3x2)
	var req_abs_alias := LevelImporter.ImportRequest.new(
		path_3x2, "absalias", "AbsAlias", "TEST", abs_path_3x2, "", "", false
	)
	_check(not LevelImporter.run_import(req_abs_alias).is_ok(), "absolute-form output alias of user:// source rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after absolute-form alias attempt")

	# 4. destination-to-destination alias via different dot-segment syntax
	var d2d_out: String = test_dir + "d2d_out.json"
	var d2d_preview_alias: String = test_dir + "subdir/../d2d_out.json"
	var req_d2d := LevelImporter.ImportRequest.new(
		path_3x2, "d2d", "D2D", "TEST", d2d_out, d2d_preview_alias, "", false
	)
	_check(not LevelImporter.run_import(req_d2d).is_ok(), "output vs preview dot-segment-equivalent destination alias rejected")
	_check(not FileAccess.file_exists(d2d_out), "no destination write occurred for dot-segment destination alias")

	# 5. overwrite=true on an equivalent source alias must still be rejected
	var req_dotslash_ow := LevelImporter.ImportRequest.new(
		path_3x2, "dotslash_ow", "DotSlashOw", "TEST", dotslash_alias_path, "", "", true
	)
	_check(not LevelImporter.run_import(req_dotslash_ow).is_ok(), "overwrite=true on './' equivalent source alias still rejected")
	_check_eq(FileAccess.get_file_as_bytes(path_3x2), src_bytes_before, "source unchanged after overwrite=true equivalent alias attempt")

	# 6. legitimate pair of distinct normalized paths still succeeds (guard is
	#    not simply rejecting every path containing a dot segment)
	var legit_distinct_alias: String = test_dir + "subdir/../legit_distinct.json"
	var legit_distinct_simplified: String = test_dir + "legit_distinct.json"
	var req_legit := LevelImporter.ImportRequest.new(
		path_3x2, "legit_distinct", "LegitDistinct", "TEST", legit_distinct_alias, "", "", false
	)
	_check(LevelImporter.run_import(req_legit).is_ok(), "distinct dot-segment output path (not aliasing anything) still succeeds")
	_check(FileAccess.file_exists(legit_distinct_simplified), "distinct dot-segment output written at its simplified location")

	# ---- F-M09-002: PREVIEW/METADATA OVERWRITE SAFETY ----
	# existing different preview, overwrite=false
	var diff_prev_path := test_dir + "diff_preview.png"
	var diff_prev_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	diff_prev_img.set_pixel(0, 0, Color.WHITE)
	diff_prev_img.save_png(diff_prev_path)
	var req_prev_clash := LevelImporter.ImportRequest.new(
		path_3x2, "prev_clash", "PrevClash", "TEST",
		test_dir + "prev_clash.json", diff_prev_path, "", false
	)
	_check(not LevelImporter.run_import(req_prev_clash).is_ok(), "existing different preview, overwrite=false rejected")
	# Level JSON should NOT have been written (preflight catches preview first)
	_check(not FileAccess.file_exists(test_dir + "prev_clash.json"), "Level JSON not written when preview preflight fails")

	# existing different metadata, overwrite=false
	var diff_meta_path := test_dir + "diff_meta.json"
	var dmf := FileAccess.open(diff_meta_path, FileAccess.WRITE)
	if dmf: dmf.store_string("{\"different\": true}"); dmf.close()
	var req_meta_clash := LevelImporter.ImportRequest.new(
		path_3x2, "meta_clash", "MetaClash", "TEST",
		test_dir + "meta_clash.json", "", diff_meta_path, false
	)
	_check(not LevelImporter.run_import(req_meta_clash).is_ok(), "existing different metadata, overwrite=false rejected")
	_check(not FileAccess.file_exists(test_dir + "meta_clash.json"), "Level JSON not written when metadata preflight fails")

	# existing identical preview → unchanged
	var ident_prev_path := test_dir + "ident_preview.png"
	var ident_req_1 := LevelImporter.ImportRequest.new(
		path_3x2, "ident_prev", "IdentPrev", "TEST",
		test_dir + "ident_prev.json", ident_prev_path, "", true
	)
	var ident_res_1 := LevelImporter.run_import(ident_req_1)
	_check(ident_res_1.is_ok(), "initial import for identical-preview test")
	var ident_req_2 := LevelImporter.ImportRequest.new(
		path_3x2, "ident_prev", "IdentPrev", "TEST",
		test_dir + "ident_prev.json", ident_prev_path, "", false
	)
	var ident_res_2 := LevelImporter.run_import(ident_req_2)
	_check(ident_res_2.is_ok(), "identical preview rerun succeeds")
	_check(ident_res_2.preview_unchanged, "identical preview detected as unchanged")
	_check(ident_res_2.output_unchanged, "identical output detected as unchanged on same rerun")

	# existing identical metadata → unchanged
	var ident_meta_path := test_dir + "ident_meta_sidecar.json"
	var ident_req_3 := LevelImporter.ImportRequest.new(
		path_3x2, "ident_meta", "IdentMeta", "TEST",
		test_dir + "ident_meta_out.json", "", ident_meta_path, true
	)
	var ident_res_3 := LevelImporter.run_import(ident_req_3)
	_check(ident_res_3.is_ok(), "initial import for identical-metadata test")
	var ident_req_4 := LevelImporter.ImportRequest.new(
		path_3x2, "ident_meta", "IdentMeta", "TEST",
		test_dir + "ident_meta_out.json", "", ident_meta_path, false
	)
	var ident_res_4 := LevelImporter.run_import(ident_req_4)
	_check(ident_res_4.is_ok(), "identical metadata rerun succeeds")
	_check(ident_res_4.metadata_unchanged, "identical metadata detected as unchanged")

	# overwrite=true replaces distinct derived artifacts
	var ow_prev_path := test_dir + "ow_preview.png"
	var ow_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	ow_img.set_pixel(0, 0, Color.BLACK)
	ow_img.save_png(ow_prev_path)
	var req_ow_all := LevelImporter.ImportRequest.new(
		path_3x2, "ow_all", "OwAll", "TEST",
		test_dir + "ow_all.json", ow_prev_path, test_dir + "ow_meta.json", true
	)
	var res_ow_all := LevelImporter.run_import(req_ow_all)
	_check(res_ow_all.is_ok(), "overwrite=true replaces all derived artifacts")
	_check(res_ow_all.preview_written, "overwrite=true preview written")

	# ---- F-M09-003: PNG-ONLY FORMAT GATE ----
	# Valid JPEG (runtime-generated) rejected as unsupported format
	var jpeg_path := test_dir + "test_img.jpg"
	var jpeg_img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	jpeg_img.set_pixel(0, 0, Color.RED)
	jpeg_img.set_pixel(1, 0, Color.GREEN)
	jpeg_img.set_pixel(0, 1, Color.BLUE)
	jpeg_img.set_pixel(1, 1, Color.WHITE)
	jpeg_img.save_jpg(jpeg_path)
	var req_jpeg := LevelImporter.ImportRequest.new(
		jpeg_path, "jpeg_test", "JPEG Test", "TEST", test_dir + "jpeg.json"
	)
	var res_jpeg := LevelImporter.run_import(req_jpeg)
	_check(not res_jpeg.is_ok(), "valid JPEG rejected (unsupported format)")
	_check(res_jpeg.errors[0].find("Unsupported source format") >= 0, "JPEG error is unsupported-format, not corrupt")

	# Corrupt .png content
	var corrupt_png_path := test_dir + "corrupt.png"
	var cpf := FileAccess.open(corrupt_png_path, FileAccess.WRITE)
	if cpf: cpf.store_string("not a valid PNG file"); cpf.close()
	var req_corrupt := LevelImporter.ImportRequest.new(
		corrupt_png_path, "corrupt_test", "Corrupt", "TEST", test_dir + "corrupt.json"
	)
	var res_corrupt := LevelImporter.run_import(req_corrupt)
	_check(not res_corrupt.is_ok(), "corrupt .png rejected")
	_check(res_corrupt.errors[0].find("Could not load") >= 0, "corrupt .png error is load failure, not format")

	# .PNG case variant accepted
	var png_upper_path := test_dir + "TEST_UPPER.PNG"
	img_3x2.save_png(png_upper_path)
	var req_upper := LevelImporter.ImportRequest.new(
		png_upper_path, "upper_png", "Upper PNG", "TEST", test_dir + "upper.json"
	)
	_check(LevelImporter.run_import(req_upper).is_ok(), ".PNG uppercase extension accepted")

	# ---- F-M09-004: RECONSTRUCTION SAFETY ----
	# Short cells
	var bad_level_short := LevelData.new(1, "bad", "Bad", "TEST", 3, 2, PackedStringArray(["#FF0000FF"]), PackedInt32Array([0, 0]))
	_check(LevelImporter.reconstruct_image(bad_level_short) == null, "reconstruction rejects short cells without crash")

	# Out-of-range palette ID
	var bad_level_pid := LevelData.new(1, "bad", "Bad", "TEST", 2, 1, PackedStringArray(["#FF0000FF"]), PackedInt32Array([0, 5]))
	_check(LevelImporter.reconstruct_image(bad_level_pid) == null, "reconstruction rejects out-of-range palette ID")

	# Invalid palette string
	var bad_level_hex := LevelData.new(1, "bad", "Bad", "TEST", 1, 1, PackedStringArray(["not_a_color"]), PackedInt32Array([0]))
	_check(LevelImporter.reconstruct_image(bad_level_hex) == null, "reconstruction rejects invalid palette string")

	# Zero dimensions
	var bad_level_dim := LevelData.new(1, "bad", "Bad", "TEST", 0, 1, PackedStringArray(["#FF0000FF"]), PackedInt32Array([]))
	_check(LevelImporter.reconstruct_image(bad_level_dim) == null, "reconstruction rejects zero width")

	# Null level
	_check(LevelImporter.reconstruct_image(null) == null, "reconstruction rejects null level")

	# ---- cleanup test dir ----
	var dir := DirAccess.open(test_dir)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while not fname.is_empty():
			if not dir.current_is_dir():
				dir.remove(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(test_dir)

func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while not fname.is_empty():
		if fname != "." and fname != "..":
			var full: String = path.path_join(fname)
			if dir.current_is_dir():
				_remove_dir_recursive(full)
			else:
				dir.remove(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

func _run_batch_importer_tests() -> void:
	var root := "user://test_batch_importer/"
	DirAccess.make_dir_recursive_absolute(root)

	var _write_text_file := func(path: String, text: String) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()

	var _write_json := func(path: String, dict: Dictionary) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(dict, "\t"))
		f.close()

	var _write_manifest := func(path: String, items: Array) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"items": items}))
		f.close()

	var _make_level_dict := func(id: String) -> Dictionary:
		return {
			"version": 1, "id": id, "name": id, "difficulty": "TEST",
			"width": 1, "height": 1, "palette": ["#FF0000FF"], "cells": [0],
		}

	var _verify_reconstruction := func(output_path: String, source_img: Image) -> bool:
		var load_res := LevelLoader.load_from_path(output_path)
		if not load_res.is_ok():
			return false
		var recon: Image = LevelImporter.reconstruct_image(load_res.level_data)
		if recon == null:
			return false
		if recon.get_width() != source_img.get_width() or recon.get_height() != source_img.get_height():
			return false
		return recon.get_data() == source_img.get_data()

	# ---- deterministic TEST-generated source PNGs (no owner art) ----
	var tiny_img: Image = LevelImporter.generate_test_png(3, 2, 4, true, false)
	tiny_img.save_png(root + "tiny.png")
	var rect_img: Image = LevelImporter.generate_test_png(20, 27, 6, true, false)
	rect_img.save_png(root + "rect.png")
	var max_img: Image = LevelImporter.generate_test_png(59, 59, 8, true, true)
	max_img.save_png(root + "max.png")

	# LevelImporter (like FileAccess.open()) does not auto-create parent
	# directories — same contract as the single-item importer. Pre-create
	# every output directory these tests target.
	for sub in ["out_happy", "out_dup", "out_alias", "out_cross", "out_later",
			"out_malformed", "out_empty", "out_missing", "out_jpeg", "out_corrupt", "out_perf",
			"out_dirtype"]:
		DirAccess.make_dir_recursive_absolute(root + sub + "/")

	# ==== HAPPY PATH ====
	var out_happy := root + "out_happy/"
	var manifest_happy_items := [
		{"source": root + "tiny.png", "id": "batch_tiny", "name": "Batch Tiny", "difficulty": "TEST", "output": out_happy + "batch_tiny.json"},
		{"source": root + "rect.png", "id": "batch_rect", "name": "Batch Rect", "difficulty": "EASY", "output": out_happy + "batch_rect.json"},
		{"source": root + "max.png", "id": "batch_max", "name": "Batch Max", "difficulty": "VERY_HARD", "output": out_happy + "batch_max.json"},
	]
	var manifest_happy_path := root + "manifest_happy.json"
	_write_manifest.call(manifest_happy_path, manifest_happy_items)

	# 2. validation-only succeeds, writes nothing
	var res_val := LevelBatchImporter.run_batch(manifest_happy_path, out_happy, false)
	_check(res_val.is_ok(), "batch happy-path validation-only succeeds")
	_check_eq(res_val.written_count(), 0, "validation-only written_count is 0")
	_check(not FileAccess.file_exists(out_happy + "batch_tiny.json"), "validation-only creates no final output (tiny)")
	_check(not FileAccess.file_exists(out_happy + "batch_rect.json"), "validation-only creates no final output (rect)")
	_check(not FileAccess.file_exists(out_happy + "batch_max.json"), "validation-only creates no final output (max)")

	# 3. commit mode imports all items correctly
	var res_commit := LevelBatchImporter.run_batch(manifest_happy_path, out_happy, true)
	_check(res_commit.is_ok(), "batch happy-path commit succeeds")
	_check(res_commit.committed, "commit flag set true")
	_check_eq(res_commit.written_count(), 3, "commit writes all 3 items")
	_check(FileAccess.file_exists(out_happy + "batch_tiny.json"), "tiny output written")
	_check(FileAccess.file_exists(out_happy + "batch_rect.json"), "rect output written")
	_check(FileAccess.file_exists(out_happy + "batch_max.json"), "max output written")

	# 4 + 9. re-running unchanged batch reports unchanged/no meaningless writes;
	# same logical ID at same canonical catalog output is allowed re-import,
	# not a "different file" conflict (AC-M09B-009).
	var res_rerun := LevelBatchImporter.run_batch(manifest_happy_path, out_happy, true)
	_check(res_rerun.is_ok(), "batch rerun unchanged still ok (same-entry re-import semantics)")
	_check_eq(res_rerun.unchanged_count(), 3, "rerun reports all 3 unchanged")
	_check_eq(res_rerun.written_count(), 0, "rerun writes nothing new")
	for item in res_rerun.items:
		_check(item.batch_errors.is_empty(), "rerun item '%s' has no batch-level conflict errors" % item.id)

	# 5. per-item reconstructed raw RGBA8 equality
	_check(_verify_reconstruction.call(out_happy + "batch_tiny.json", tiny_img), "batch tiny reconstruction raw-byte match")
	_check(_verify_reconstruction.call(out_happy + "batch_rect.json", rect_img), "batch rect (20x27) reconstruction raw-byte match")
	_check(_verify_reconstruction.call(out_happy + "batch_max.json", max_img), "batch max (59x59) reconstruction raw-byte match")

	# ==== DUPLICATE ID SAFETY ====

	# 6. duplicate ID inside one manifest fails before writes
	var out_dup := root + "out_dup/"
	var manifest_dup_items := [
		{"source": root + "tiny.png", "id": "dupe", "name": "D1", "difficulty": "TEST", "output": out_dup + "d1.json"},
		{"source": root + "rect.png", "id": "dupe", "name": "D2", "difficulty": "EASY", "output": out_dup + "d2.json"},
	]
	var manifest_dup_path := root + "manifest_dup.json"
	_write_manifest.call(manifest_dup_path, manifest_dup_items)
	var res_dup := LevelBatchImporter.run_batch(manifest_dup_path, out_dup, true)
	_check(not res_dup.is_ok(), "duplicate id within manifest rejected")
	_check(not res_dup.committed, "duplicate id within manifest: nothing committed")
	_check(not FileAccess.file_exists(out_dup + "d1.json"), "duplicate-id item 0 not written")
	_check(not FileAccess.file_exists(out_dup + "d2.json"), "duplicate-id item 1 not written")
	_check(res_dup.items[0].all_errors()[0].find("Duplicate id") >= 0, "duplicate-id error names the duplicate specifically")

	# 7. duplicate ID against a different existing catalog file fails before writes
	var cat_diff := root + "catalog_diff/"
	DirAccess.make_dir_recursive_absolute(cat_diff)
	_write_json.call(cat_diff + "existing.json", _make_level_dict.call("taken_id"))
	var manifest_steal_items := [
		{"source": root + "tiny.png", "id": "taken_id", "name": "Steal", "difficulty": "TEST", "output": cat_diff + "steal_out.json"},
	]
	var manifest_steal_path := root + "manifest_steal.json"
	_write_manifest.call(manifest_steal_path, manifest_steal_items)
	var res_steal := LevelBatchImporter.run_batch(manifest_steal_path, cat_diff, true)
	_check(not res_steal.is_ok(), "duplicate id against different existing catalog file rejected")
	_check(not FileAccess.file_exists(cat_diff + "steal_out.json"), "id-theft attempt writes nothing")
	_check(res_steal.items[0].all_errors()[0].find("already belongs to a different catalog file") >= 0, "id-theft error names the conflict specifically")

	# 8. existing catalog containing two files with the same declared ID is detected/reported
	var cat_ambig := root + "catalog_ambiguous/"
	DirAccess.make_dir_recursive_absolute(cat_ambig)
	_write_json.call(cat_ambig + "first.json", _make_level_dict.call("ambiguous_id"))
	_write_json.call(cat_ambig + "second.json", _make_level_dict.call("ambiguous_id"))
	var manifest_scan_items := [
		{"source": root + "tiny.png", "id": "unrelated_scan_id", "name": "Scan", "difficulty": "TEST", "output": cat_ambig + "scan_out.json"},
	]
	var manifest_scan_path := root + "manifest_scan.json"
	_write_manifest.call(manifest_scan_path, manifest_scan_items)
	var res_scan := LevelBatchImporter.run_batch(manifest_scan_path, cat_ambig, false)
	_check_eq(res_scan.catalog_duplicate_ids.size(), 1, "existing catalog duplicate detected")
	if res_scan.catalog_duplicate_ids.size() == 1:
		_check_eq(res_scan.catalog_duplicate_ids[0]["id"], "ambiguous_id", "catalog duplicate reports the correct id")
		_check_eq(res_scan.catalog_duplicate_ids[0]["paths"].size(), 2, "catalog duplicate reports both paths")

	# 10. overwrite=true does not permit a different file to steal an existing ID
	var manifest_steal_ow_items := [
		{"source": root + "tiny.png", "id": "taken_id", "name": "Steal2", "difficulty": "TEST", "output": cat_diff + "steal_out2.json", "overwrite": true},
	]
	var manifest_steal_ow_path := root + "manifest_steal_ow.json"
	_write_manifest.call(manifest_steal_ow_path, manifest_steal_ow_items)
	var res_steal_ow := LevelBatchImporter.run_batch(manifest_steal_ow_path, cat_diff, true)
	_check(not res_steal_ow.is_ok(), "overwrite=true still cannot steal an existing id from a different catalog file")
	_check(not FileAccess.file_exists(cat_diff + "steal_out2.json"), "overwrite id-theft attempt writes nothing")

	# ==== PATH/OUTPUT SAFETY ====

	# 11. two batch items targeting canonically equivalent output paths fail before writes
	var out_alias := root + "out_alias/"
	var manifest_alias_items := [
		{"source": root + "tiny.png", "id": "alias_a", "name": "AliasA", "difficulty": "TEST", "output": out_alias + "shared.json"},
		{"source": root + "rect.png", "id": "alias_b", "name": "AliasB", "difficulty": "EASY", "output": out_alias + "subdir/../shared.json"},
	]
	var manifest_alias_path := root + "manifest_alias.json"
	_write_manifest.call(manifest_alias_path, manifest_alias_items)
	var res_alias := LevelBatchImporter.run_batch(manifest_alias_path, out_alias, true)
	_check(not res_alias.is_ok(), "cross-item equivalent-path (subdir/../) output alias rejected")
	_check(not FileAccess.file_exists(out_alias + "shared.json"), "cross-item output alias writes nothing")

	# 12. cross-item preview/metadata/output collisions are detected, not only within one request
	var out_cross := root + "out_cross/"
	var manifest_cross_items := [
		{"source": root + "tiny.png", "id": "cross_a", "name": "CrossA", "difficulty": "TEST", "output": out_cross + "a_out.json", "preview": out_cross + "shared_prev.png"},
		{"source": root + "rect.png", "id": "cross_b", "name": "CrossB", "difficulty": "EASY", "output": out_cross + "shared_prev.png"},
	]
	var manifest_cross_path := root + "manifest_cross.json"
	_write_manifest.call(manifest_cross_path, manifest_cross_items)
	var res_cross := LevelBatchImporter.run_batch(manifest_cross_path, out_cross, true)
	_check(not res_cross.is_ok(), "cross-item preview-vs-output collision rejected")
	_check(not FileAccess.file_exists(out_cross + "a_out.json"), "cross-item collision writes nothing (item a)")
	_check(not FileAccess.file_exists(out_cross + "shared_prev.png"), "cross-item collision writes nothing (shared path)")

	# 13. a source path from one item cannot alias a write destination from another item
	var out_srcalias := root + "out_srcalias/"
	DirAccess.make_dir_recursive_absolute(out_srcalias)
	var shared_source_path := out_srcalias + "shared_file.png"
	tiny_img.save_png(shared_source_path)
	var shared_source_bytes_before := FileAccess.get_file_as_bytes(shared_source_path)
	var manifest_srcalias_items := [
		{"source": shared_source_path, "id": "srcalias_a", "name": "SrcAliasA", "difficulty": "TEST", "output": out_srcalias + "a_out.json"},
		{"source": root + "rect.png", "id": "srcalias_b", "name": "SrcAliasB", "difficulty": "EASY", "output": shared_source_path},
	]
	var manifest_srcalias_path := root + "manifest_srcalias.json"
	_write_manifest.call(manifest_srcalias_path, manifest_srcalias_items)
	var res_srcalias := LevelBatchImporter.run_batch(manifest_srcalias_path, out_srcalias, true)
	_check(not res_srcalias.is_ok(), "item source aliasing another item's destination rejected")
	_check_eq(FileAccess.get_file_as_bytes(shared_source_path), shared_source_bytes_before, "aliased source file bytes unchanged")

	# 14. with a failing later item, earlier final artifacts are not written during preflight
	var out_later := root + "out_later/"
	var manifest_later_items := [
		{"source": root + "tiny.png", "id": "later_ok", "name": "LaterOK", "difficulty": "TEST", "output": out_later + "ok_out.json"},
		{"source": root + "nonexistent_source.png", "id": "later_bad", "name": "LaterBad", "difficulty": "TEST", "output": out_later + "bad_out.json"},
	]
	var manifest_later_path := root + "manifest_later.json"
	_write_manifest.call(manifest_later_path, manifest_later_items)
	var res_later := LevelBatchImporter.run_batch(manifest_later_path, out_later, true)
	_check(not res_later.is_ok(), "batch with a failing later item is not ok")
	_check(not FileAccess.file_exists(out_later + "ok_out.json"), "earlier valid item not committed when a later item fails preflight")
	_check(res_later.items[0].is_ok(), "earlier item individually preflights clean (isolates which item actually failed)")
	_check(not res_later.items[1].is_ok(), "later item is correctly identified as the failing one")

	# ==== INVALID INPUT / CATALOG ====

	# 15. malformed manifest
	var manifest_malformed_path := root + "manifest_malformed.json"
	_write_text_file.call(manifest_malformed_path, "{ not valid json ][")
	var res_malformed := LevelBatchImporter.run_batch(manifest_malformed_path, root + "out_malformed/", false)
	_check(not res_malformed.is_ok(), "malformed manifest JSON rejected")
	_check(res_malformed.manifest_errors.size() > 0, "malformed manifest produces manifest_errors")
	if res_malformed.manifest_errors.size() > 0:
		_check(res_malformed.manifest_errors[0].find("malformed JSON") >= 0, "malformed manifest error names JSON parse failure specifically")

	# 16. empty manifest
	var manifest_empty_path := root + "manifest_empty.json"
	_write_manifest.call(manifest_empty_path, [])
	var res_empty := LevelBatchImporter.run_batch(manifest_empty_path, root + "out_empty/", false)
	_check(not res_empty.is_ok(), "empty manifest rejected")
	_check(res_empty.manifest_errors.size() > 0, "empty manifest produces manifest_errors")
	if res_empty.manifest_errors.size() > 0:
		_check(res_empty.manifest_errors[0].find("empty") >= 0, "empty manifest error names the empty items array specifically")

	# 17. missing required item field
	var manifest_missing_items := [
		{"source": root + "tiny.png", "id": "missing_field", "name": "Missing", "output": root + "out_missing/mf.json"},
	]
	var manifest_missing_path := root + "manifest_missing.json"
	_write_manifest.call(manifest_missing_path, manifest_missing_items)
	var res_missing := LevelBatchImporter.run_batch(manifest_missing_path, root + "out_missing/", false)
	_check(not res_missing.is_ok(), "missing required item field rejected")
	_check(res_missing.items[0].all_errors()[0].find("difficulty") >= 0, "missing-field error names the specific missing field")

	# 18. valid non-PNG source (JPEG) — reuses single-import PNG-only gate
	var out_jpeg := root + "out_jpeg/"
	var jpeg_path := root + "batch_test.jpg"
	var jpeg_img: Image = LevelImporter.generate_test_png(2, 2, 4, false, false)
	jpeg_img.save_jpg(jpeg_path)
	var manifest_jpeg_items := [
		{"source": jpeg_path, "id": "jpeg_item", "name": "Jpeg", "difficulty": "TEST", "output": out_jpeg + "jpeg_out.json"},
	]
	var manifest_jpeg_path := root + "manifest_jpeg.json"
	_write_manifest.call(manifest_jpeg_path, manifest_jpeg_items)
	var res_jpeg_batch := LevelBatchImporter.run_batch(manifest_jpeg_path, out_jpeg, false)
	_check(not res_jpeg_batch.is_ok(), "valid non-PNG (JPEG) source rejected via reused single-import PNG gate")
	_check(res_jpeg_batch.items[0].all_errors()[0].find("Unsupported source format") >= 0, "JPEG rejection names unsupported-format, distinct from corruption")

	# 19. corrupt PNG
	var corrupt_png_path := root + "batch_corrupt.png"
	_write_text_file.call(corrupt_png_path, "not a valid PNG file")
	var manifest_corrupt_items := [
		{"source": corrupt_png_path, "id": "corrupt_item", "name": "Corrupt", "difficulty": "TEST", "output": root + "out_corrupt/c_out.json"},
	]
	var manifest_corrupt_path := root + "manifest_corrupt.json"
	_write_manifest.call(manifest_corrupt_path, manifest_corrupt_items)
	var res_corrupt_batch := LevelBatchImporter.run_batch(manifest_corrupt_path, root + "out_corrupt/", false)
	_check(not res_corrupt_batch.is_ok(), "corrupt PNG source rejected")
	_check(res_corrupt_batch.items[0].all_errors()[0].find("Could not load") >= 0, "corrupt PNG error is load failure, distinct from format rejection")

	# 20. malformed catalog Level Data JSON (JSON parse failure)
	var cat_malformed_json := root + "catalog_malformed_json/"
	DirAccess.make_dir_recursive_absolute(cat_malformed_json)
	_write_text_file.call(cat_malformed_json + "broken.json", "{ this is not valid json ]")
	var manifest_scan2_items := [
		{"source": root + "tiny.png", "id": "scan2_id", "name": "Scan2", "difficulty": "TEST", "output": cat_malformed_json + "scan2_out.json"},
	]
	var manifest_scan2_path := root + "manifest_scan2.json"
	_write_manifest.call(manifest_scan2_path, manifest_scan2_items)
	var res_scan2 := LevelBatchImporter.run_batch(manifest_scan2_path, cat_malformed_json, false)
	_check_eq(res_scan2.catalog_malformed.size(), 1, "malformed catalog JSON reported, not silently ignored")
	if res_scan2.catalog_malformed.size() == 1:
		_check(res_scan2.catalog_malformed[0]["errors"][0].find("malformed JSON") >= 0, "malformed catalog JSON error names JSON parse failure specifically")

	# 21. structurally invalid catalog Level Data (valid JSON, missing required fields) —
	# must be distinguishable from #20's JSON-parse failure (AL-011 specificity)
	var cat_struct_invalid := root + "catalog_struct_invalid/"
	DirAccess.make_dir_recursive_absolute(cat_struct_invalid)
	_write_json.call(cat_struct_invalid + "incomplete.json", {"version": 1, "id": "incomplete_id"})
	var manifest_scan3_items := [
		{"source": root + "tiny.png", "id": "scan3_id", "name": "Scan3", "difficulty": "TEST", "output": cat_struct_invalid + "scan3_out.json"},
	]
	var manifest_scan3_path := root + "manifest_scan3.json"
	_write_manifest.call(manifest_scan3_path, manifest_scan3_items)
	var res_scan3 := LevelBatchImporter.run_batch(manifest_scan3_path, cat_struct_invalid, false)
	_check_eq(res_scan3.catalog_malformed.size(), 1, "structurally invalid catalog Level Data reported")
	if res_scan3.catalog_malformed.size() == 1:
		var struct_errors: Array = res_scan3.catalog_malformed[0]["errors"]
		_check(struct_errors.size() > 0, "structural-invalidity produces specific field errors")
		_check(struct_errors[0].find("malformed JSON") < 0, "structural-invalidity error is distinct from JSON-parse-failure (AL-011)")

	# ==== V02 CORRECTION: CATALOG HEALTH INVALIDATES OVERALL VALIDATION (F-M09B-004) ====
	# Existing catalog corruption unrelated to the requested item must still
	# fail the WHOLE batch's is_ok(), not remain merely informational.
	_check(not res_scan.is_ok(), "existing catalog duplicate ID (unrelated to requested item) makes overall validation fail")
	_check(not res_scan2.is_ok(), "malformed catalog JSON (unrelated to requested item) makes overall validation fail")
	_check(not res_scan3.is_ok(), "structurally invalid catalog entry (unrelated to requested item) makes overall validation fail")

	# ==== V02 CORRECTION: DESTINATION-PARENT-DIRECTORY PREFLIGHT (F-M09B-001) ====
	var out_parent_ok := root + "out_parent_ok/"
	DirAccess.make_dir_recursive_absolute(out_parent_ok)

	# 1. later item has a missing Level JSON parent; earlier item has a valid parent
	var manifest_parent1_items := [
		{"source": root + "tiny.png", "id": "parent1_ok", "name": "Parent1OK", "difficulty": "TEST", "output": out_parent_ok + "ok.json"},
		{"source": root + "rect.png", "id": "parent1_bad", "name": "Parent1Bad", "difficulty": "EASY", "output": root + "out_parent_missing_output/nope.json"},
	]
	var manifest_parent1_path := root + "manifest_parent1.json"
	_write_manifest.call(manifest_parent1_path, manifest_parent1_items)
	var res_parent1 := LevelBatchImporter.run_batch(manifest_parent1_path, out_parent_ok, true)
	_check(not res_parent1.is_ok(), "missing Level JSON parent directory blocks whole batch")
	_check(not FileAccess.file_exists(out_parent_ok + "ok.json"), "earlier item with a valid parent is not written when a later item's parent is missing")
	_check(res_parent1.items[1].all_errors().size() > 0, "the item with the missing parent reports a specific error")

	# 2. missing preview parent blocks whole batch before writes
	var manifest_parent2_items := [
		{"source": root + "tiny.png", "id": "parent2_ok", "name": "Parent2OK", "difficulty": "TEST", "output": out_parent_ok + "p2ok.json"},
		{"source": root + "rect.png", "id": "parent2_bad", "name": "Parent2Bad", "difficulty": "EASY", "output": out_parent_ok + "p2bad.json", "preview": root + "out_parent_missing_preview/p.png"},
	]
	var manifest_parent2_path := root + "manifest_parent2.json"
	_write_manifest.call(manifest_parent2_path, manifest_parent2_items)
	var res_parent2 := LevelBatchImporter.run_batch(manifest_parent2_path, out_parent_ok, true)
	_check(not res_parent2.is_ok(), "missing preview parent directory blocks whole batch")
	_check(not FileAccess.file_exists(out_parent_ok + "p2ok.json"), "earlier item not written when a later item's preview parent is missing")

	# 3. missing metadata parent blocks whole batch before writes
	var manifest_parent3_items := [
		{"source": root + "tiny.png", "id": "parent3_ok", "name": "Parent3OK", "difficulty": "TEST", "output": out_parent_ok + "p3ok.json"},
		{"source": root + "rect.png", "id": "parent3_bad", "name": "Parent3Bad", "difficulty": "EASY", "output": out_parent_ok + "p3bad.json", "metadata": root + "out_parent_missing_metadata/m.json"},
	]
	var manifest_parent3_path := root + "manifest_parent3.json"
	_write_manifest.call(manifest_parent3_path, manifest_parent3_items)
	var res_parent3 := LevelBatchImporter.run_batch(manifest_parent3_path, out_parent_ok, true)
	_check(not res_parent3.is_ok(), "missing metadata parent directory blocks whole batch")
	_check(not FileAccess.file_exists(out_parent_ok + "p3ok.json"), "earlier item not written when a later item's metadata parent is missing")

	# 4. validation-only missing-parent case creates neither directory nor final file
	var res_parent4 := LevelBatchImporter.run_batch(manifest_parent1_path, out_parent_ok, false)
	_check(not res_parent4.is_ok(), "validation-only also reports missing-parent failure")
	_check(not DirAccess.dir_exists_absolute(root + "out_parent_missing_output"), "validation-only does not create the missing parent directory")
	_check(not FileAccess.file_exists(out_parent_ok + "ok.json"), "validation-only writes nothing even for the item with a valid parent")

	# ==== V02 CORRECTION: CATALOG ROOT FAIL-CLOSED (F-M09B-002) ====
	var manifest_catroot_items := [
		{"source": root + "tiny.png", "id": "catroot_item", "name": "CatRoot", "difficulty": "TEST", "output": out_parent_ok + "catroot_out.json"},
	]
	var manifest_catroot_path := root + "manifest_catroot.json"
	_write_manifest.call(manifest_catroot_path, manifest_catroot_items)

	# 5. missing catalog root
	var missing_catalog_root := root + "does_not_exist_catalog/"
	var res_missing_root := LevelBatchImporter.run_batch(manifest_catroot_path, missing_catalog_root, false)
	_check(not res_missing_root.is_ok(), "missing catalog root fails the whole batch")
	_check(not res_missing_root.catalog_root_valid, "missing catalog root reported as invalid")
	_check(res_missing_root.catalog_root_error.length() > 0, "missing catalog root produces an actionable error message")

	# 6. catalog root that is a file, not a directory
	var file_as_catalog_root := root + "file_as_catalog_root.txt"
	_write_text_file.call(file_as_catalog_root, "not a directory")
	var res_file_root := LevelBatchImporter.run_batch(manifest_catroot_path, file_as_catalog_root, false)
	_check(not res_file_root.is_ok(), "non-directory catalog root fails the whole batch")
	_check(not res_file_root.catalog_root_valid, "non-directory catalog root reported as invalid")

	# ==== V02 CORRECTION: BIDIRECTIONAL CATALOG PATH OWNERSHIP (F-M09B-003) ====
	var cat_ownership := root + "catalog_ownership/"
	DirAccess.make_dir_recursive_absolute(cat_ownership)
	_write_json.call(cat_ownership + "old_entry.json", _make_level_dict.call("old_id"))
	var old_entry_bytes_before := FileAccess.get_file_as_bytes(cat_ownership + "old_entry.json")

	# 10. different id targeting the SAME existing catalog path, overwrite=true -> rejected
	var manifest_takeover_items := [
		{"source": root + "tiny.png", "id": "new_id", "name": "Takeover", "difficulty": "TEST", "output": cat_ownership + "old_entry.json", "overwrite": true},
	]
	var manifest_takeover_path := root + "manifest_takeover.json"
	_write_manifest.call(manifest_takeover_path, manifest_takeover_items)
	var res_takeover := LevelBatchImporter.run_batch(manifest_takeover_path, cat_ownership, true)
	_check(not res_takeover.is_ok(), "different id cannot take over an existing catalog path even with overwrite=true")
	_check_eq(FileAccess.get_file_as_bytes(cat_ownership + "old_entry.json"), old_entry_bytes_before, "existing catalog file bytes unchanged after takeover attempt")

	# 11. same file + same declared id + same canonical output -> normal unchanged/overwrite semantics apply
	var manifest_sameentry_items := [
		{"source": root + "tiny.png", "id": "old_id", "name": "SameEntry", "difficulty": "TEST", "output": cat_ownership + "old_entry.json", "overwrite": true},
	]
	var manifest_sameentry_path := root + "manifest_sameentry.json"
	_write_manifest.call(manifest_sameentry_path, manifest_sameentry_items)
	var res_sameentry := LevelBatchImporter.run_batch(manifest_sameentry_path, cat_ownership, true)
	_check(res_sameentry.is_ok(), "same id at its own existing canonical catalog path is not treated as ownership theft")

	# 12. requested output aliases a MALFORMED catalog file -> fail closed
	_write_text_file.call(cat_ownership + "broken_entry.json", "{ not valid json ]")
	var broken_entry_bytes_before := FileAccess.get_file_as_bytes(cat_ownership + "broken_entry.json")
	var manifest_malformed_takeover_items := [
		{"source": root + "tiny.png", "id": "whatever_id", "name": "MalformedTakeover", "difficulty": "TEST", "output": cat_ownership + "broken_entry.json", "overwrite": true},
	]
	var manifest_malformed_takeover_path := root + "manifest_malformed_takeover.json"
	_write_manifest.call(manifest_malformed_takeover_path, manifest_malformed_takeover_items)
	var res_malformed_takeover := LevelBatchImporter.run_batch(manifest_malformed_takeover_path, cat_ownership, true)
	_check(not res_malformed_takeover.is_ok(), "output aliasing a malformed catalog file fails closed")
	_check_eq(FileAccess.get_file_as_bytes(cat_ownership + "broken_entry.json"), broken_entry_bytes_before, "malformed catalog file bytes unchanged after takeover attempt")

	# ==== V02 CORRECTION: MANIFEST OPTIONAL FIELD TYPE VALIDATION (F-M09B-005) ====
	var out_schema := root + "out_schema/"
	DirAccess.make_dir_recursive_absolute(out_schema)

	# 13. preview: 42 -> clean schema error
	var manifest_bad_preview_items := [
		{"source": root + "tiny.png", "id": "bad_preview", "name": "BadPreview", "difficulty": "TEST", "output": out_schema + "bp_out.json", "preview": 42},
	]
	var manifest_bad_preview_path := root + "manifest_bad_preview.json"
	_write_manifest.call(manifest_bad_preview_path, manifest_bad_preview_items)
	var res_bad_preview := LevelBatchImporter.run_batch(manifest_bad_preview_path, out_schema, true)
	_check(not res_bad_preview.is_ok(), "preview: 42 rejected as a schema error")
	_check(res_bad_preview.items[0].all_errors()[0].find("preview") >= 0, "preview type error names the field specifically")
	_check(not FileAccess.file_exists(out_schema + "bp_out.json"), "preview type error writes nothing")

	# 14. metadata: {} -> clean schema error
	var manifest_bad_metadata_items := [
		{"source": root + "tiny.png", "id": "bad_metadata", "name": "BadMetadata", "difficulty": "TEST", "output": out_schema + "bm_out.json", "metadata": {}},
	]
	var manifest_bad_metadata_path := root + "manifest_bad_metadata.json"
	_write_manifest.call(manifest_bad_metadata_path, manifest_bad_metadata_items)
	var res_bad_metadata := LevelBatchImporter.run_batch(manifest_bad_metadata_path, out_schema, true)
	_check(not res_bad_metadata.is_ok(), "metadata: {} rejected as a schema error")
	_check(res_bad_metadata.items[0].all_errors()[0].find("metadata") >= 0, "metadata type error names the field specifically")
	_check(not FileAccess.file_exists(out_schema + "bm_out.json"), "metadata type error writes nothing")

	# 15. overwrite: "yes" -> clean schema error
	var manifest_bad_overwrite_items := [
		{"source": root + "tiny.png", "id": "bad_overwrite", "name": "BadOverwrite", "difficulty": "TEST", "output": out_schema + "bo_out.json", "overwrite": "yes"},
	]
	var manifest_bad_overwrite_path := root + "manifest_bad_overwrite.json"
	_write_manifest.call(manifest_bad_overwrite_path, manifest_bad_overwrite_items)
	var res_bad_overwrite := LevelBatchImporter.run_batch(manifest_bad_overwrite_path, out_schema, true)
	_check(not res_bad_overwrite.is_ok(), "overwrite: 'yes' rejected as a schema error")
	_check(res_bad_overwrite.items[0].all_errors()[0].find("overwrite") >= 0, "overwrite type error names the field specifically")
	_check(not FileAccess.file_exists(out_schema + "bo_out.json"), "overwrite type error writes nothing")

	# ==== V03 CORRECTION: DESTINATION-TYPE PREFLIGHT (F-M09B-006 / AL-017) ====
	# An existing directory at the final destination path (not just the parent)
	# must be rejected before any commit write. All tests use valid parents,
	# valid catalog, valid manifest — the directory-type itself is the reason.
	var out_dirtype := root + "out_dirtype/"

	# Create directories AT the destination paths (simulating "someone named
	# a directory the same as the intended output file").
	DirAccess.make_dir_recursive_absolute(out_dirtype + "level_as_dir.json")
	DirAccess.make_dir_recursive_absolute(out_dirtype + "preview_as_dir.png")
	DirAccess.make_dir_recursive_absolute(out_dirtype + "meta_as_dir.json")

	# 1. Later item output is an existing directory — batch fails, earlier item unwritten
	var manifest_dt1_items := [
		{"source": root + "tiny.png", "id": "dt1_ok", "name": "DT1OK", "difficulty": "TEST", "output": out_dirtype + "dt1_ok.json"},
		{"source": root + "rect.png", "id": "dt1_bad", "name": "DT1Bad", "difficulty": "EASY", "output": out_dirtype + "level_as_dir.json"},
	]
	var manifest_dt1_path := root + "manifest_dt1.json"
	_write_manifest.call(manifest_dt1_path, manifest_dt1_items)
	var res_dt1 := LevelBatchImporter.run_batch(manifest_dt1_path, out_dirtype, true)
	_check(not res_dt1.is_ok(), "output destination that is an existing directory blocks whole batch")
	_check(not FileAccess.file_exists(out_dirtype + "dt1_ok.json"), "earlier valid item remains unwritten when later item output is a directory")
	var dt1_err: Array[String] = res_dt1.items[1].all_errors()
	_check(dt1_err.size() > 0 and dt1_err[0].find("existing directory") >= 0, "error message identifies output destination type")

	# 2. Preview path is an existing directory — batch fails before any write
	var manifest_dt2_items := [
		{"source": root + "tiny.png", "id": "dt2_prev", "name": "DT2Prev", "difficulty": "TEST", "output": out_dirtype + "dt2_prev.json", "preview": out_dirtype + "preview_as_dir.png"},
	]
	var manifest_dt2_path := root + "manifest_dt2.json"
	_write_manifest.call(manifest_dt2_path, manifest_dt2_items)
	var res_dt2 := LevelBatchImporter.run_batch(manifest_dt2_path, out_dirtype, true)
	_check(not res_dt2.is_ok(), "preview destination that is an existing directory blocks batch")
	_check(not FileAccess.file_exists(out_dirtype + "dt2_prev.json"), "no file written when preview is a directory")

	# 3. Metadata path is an existing directory — batch fails before any write
	var manifest_dt3_items := [
		{"source": root + "tiny.png", "id": "dt3_meta", "name": "DT3Meta", "difficulty": "TEST", "output": out_dirtype + "dt3_meta.json", "metadata": out_dirtype + "meta_as_dir.json"},
	]
	var manifest_dt3_path := root + "manifest_dt3.json"
	_write_manifest.call(manifest_dt3_path, manifest_dt3_items)
	var res_dt3 := LevelBatchImporter.run_batch(manifest_dt3_path, out_dirtype, true)
	_check(not res_dt3.is_ok(), "metadata destination that is an existing directory blocks batch")
	_check(not FileAccess.file_exists(out_dirtype + "dt3_meta.json"), "no file written when metadata is a directory")

	# 4. Validation-only with a directory destination — fails, creates/removes nothing
	var pre_dt4_dir_exists := DirAccess.dir_exists_absolute(out_dirtype + "level_as_dir.json")
	var res_dt4 := LevelBatchImporter.run_batch(manifest_dt1_path, out_dirtype, false)
	_check(not res_dt4.is_ok(), "validation-only also rejects directory destination")
	_check(DirAccess.dir_exists_absolute(out_dirtype + "level_as_dir.json") == pre_dt4_dir_exists, "validation-only does not remove or modify the existing directory")
	_check(not FileAccess.file_exists(out_dirtype + "dt1_ok.json"), "validation-only writes nothing")

	# 5. overwrite=true still rejects existing directory as output
	var manifest_dt5_items := [
		{"source": root + "tiny.png", "id": "dt5_ow", "name": "DT5OW", "difficulty": "TEST", "output": out_dirtype + "level_as_dir.json", "overwrite": true},
	]
	var manifest_dt5_path := root + "manifest_dt5.json"
	_write_manifest.call(manifest_dt5_path, manifest_dt5_items)
	var res_dt5 := LevelBatchImporter.run_batch(manifest_dt5_path, out_dirtype, true)
	_check(not res_dt5.is_ok(), "overwrite=true cannot turn a directory into a file target")

	# 6. Existing regular Level JSON file — unchanged/overwrite semantics still work
	# Use a clean catalog directory (no directory-named-as-json entries that
	# would make the catalog scan report malformed entries).
	var out_dirtype_clean := root + "out_dirtype_clean/"
	DirAccess.make_dir_recursive_absolute(out_dirtype_clean)
	var manifest_dt6_items := [
		{"source": root + "tiny.png", "id": "dt6_reg", "name": "DT6Reg", "difficulty": "TEST", "output": out_dirtype_clean + "dt6_regular.json"},
	]
	var manifest_dt6_path := root + "manifest_dt6.json"
	_write_manifest.call(manifest_dt6_path, manifest_dt6_items)
	var res_dt6_first := LevelBatchImporter.run_batch(manifest_dt6_path, out_dirtype_clean, true)
	_check(res_dt6_first.is_ok(), "first commit of a regular-file output succeeds")
	_check(res_dt6_first.items[0].import_result.output_written, "regular file written on first import")
	var res_dt6_rerun := LevelBatchImporter.run_batch(manifest_dt6_path, out_dirtype_clean, true)
	_check(res_dt6_rerun.is_ok(), "rerun of identical regular-file import succeeds")
	_check(res_dt6_rerun.items[0].import_result.output_unchanged, "regular file detected as unchanged on rerun")

	# 7. Existing regular preview/metadata — audited unchanged/overwrite behavior preserved
	# Write preview/metadata to a subdirectory so the catalog scan (flat)
	# does not pick up the metadata sidecar as a malformed level entry.
	var dt7_sidecar_dir := out_dirtype_clean + "sidecar/"
	DirAccess.make_dir_recursive_absolute(dt7_sidecar_dir)
	var manifest_dt7_items := [
		{"source": root + "tiny.png", "id": "dt7_art", "name": "DT7Art", "difficulty": "TEST", "output": out_dirtype_clean + "dt7_art.json", "preview": dt7_sidecar_dir + "dt7_art_preview.png", "metadata": dt7_sidecar_dir + "dt7_art_meta.json"},
	]
	var manifest_dt7_path := root + "manifest_dt7.json"
	_write_manifest.call(manifest_dt7_path, manifest_dt7_items)
	var res_dt7_first := LevelBatchImporter.run_batch(manifest_dt7_path, out_dirtype_clean, true)
	_check(res_dt7_first.is_ok(), "first commit with regular preview+metadata succeeds")
	_check(res_dt7_first.items[0].import_result.preview_written, "regular preview written on first import")
	_check(res_dt7_first.items[0].import_result.metadata_written, "regular metadata written on first import")
	var res_dt7_rerun := LevelBatchImporter.run_batch(manifest_dt7_path, out_dirtype_clean, true)
	_check(res_dt7_rerun.is_ok(), "rerun of regular preview+metadata import succeeds")
	_check(res_dt7_rerun.items[0].import_result.preview_unchanged, "regular preview detected as unchanged on rerun")
	_check(res_dt7_rerun.items[0].import_result.metadata_unchanged, "regular metadata detected as unchanged on rerun")

	# ---- performance sanity (batch of 3 including 59x59, informational only) ----
	var perf_out := root + "out_perf/"
	var perf_items := [
		{"source": root + "tiny.png", "id": "perf_tiny", "name": "PerfTiny", "difficulty": "TEST", "output": perf_out + "perf_tiny.json"},
		{"source": root + "rect.png", "id": "perf_rect", "name": "PerfRect", "difficulty": "EASY", "output": perf_out + "perf_rect.json"},
		{"source": root + "max.png", "id": "perf_max", "name": "PerfMax", "difficulty": "VERY_HARD", "output": perf_out + "perf_max.json"},
	]
	var perf_manifest_path := root + "manifest_perf.json"
	_write_manifest.call(perf_manifest_path, perf_items)
	var perf_t0 := Time.get_ticks_usec()
	var res_perf := LevelBatchImporter.run_batch(perf_manifest_path, perf_out, true)
	var perf_t1 := Time.get_ticks_usec()
	print("---- LevelBatchImporter performance sanity (3 items incl. 59x59) ----")
	print("  commit batch (preflight + write): %.3f ms" % ((perf_t1 - perf_t0) / 1000.0))
	_check(res_perf.is_ok(), "performance-sanity batch commit succeeds")

	# ---- cleanup ----
	_remove_dir_recursive(root)

func _run_gameplay_session_tests() -> void:
	var test_dir := "user://test_session/"
	DirAccess.make_dir_recursive_absolute(test_dir)

	var _write_json := func(path: String, dict: Dictionary) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(dict, "\t"))
		f.close()

	# ---- write temp level fixtures ----
	var rect_cells_arr: Array = []
	for i in 540:
		rect_cells_arr.append(i % 3)
	var rect_dict := {
		"version": 1, "id": "test_rect_20x27", "name": "Rect 20x27 Session Test",
		"difficulty": "EASY", "width": 20, "height": 27,
		"palette": ["#FF0000FF", "#00FF00FF", "#0000FFFF"],
		"cells": rect_cells_arr,
	}
	var rect_path := test_dir + "rect_20x27.json"
	_write_json.call(rect_path, rect_dict)

	var malformed_path := test_dir + "malformed.json"
	var mf := FileAccess.open(malformed_path, FileAccess.WRITE)
	mf.store_string("{ not valid json ][")
	mf.close()

	var path_3x2 := "res://data/levels/test_3x2.json"
	var path_59x59 := "res://data/levels/test_59x59.json"

	# ==== 1. New session starts UNINITIALIZED ====
	var s := GameplaySession.new()
	_check_eq(s.get_state(), GameplaySession.State.UNINITIALIZED, "M11-01: new session starts UNINITIALIZED")
	_check(s.get_level_data() == null, "M11-01: new session has null level_data")
	_check(s.get_board_state() == null, "M11-01: new session has null board_state")

	# ==== 2. Valid TEST 3x2 loads to READY ====
	var r2 := s.load_level(path_3x2)
	_check(r2.ok, "M11-02: 3x2 load succeeds")
	_check_eq(s.get_state(), GameplaySession.State.READY, "M11-02: state is READY after load")
	_check(s.get_level_data() != null, "M11-02: level_data not null")
	_check(s.get_board_state() != null, "M11-02: board_state not null")

	# ==== 3. Valid rectangular production-band fixture loads to READY ====
	var s3 := GameplaySession.new()
	var r3 := s3.load_level(rect_path)
	_check(r3.ok, "M11-03: rectangular 20x27 EASY load succeeds")
	_check_eq(s3.get_state(), GameplaySession.State.READY, "M11-03: state is READY")
	_check_eq(s3.get_level_data().width, 20, "M11-03: width 20")
	_check_eq(s3.get_level_data().height, 27, "M11-03: height 27")

	# ==== 4. 59x59 fixture loads to READY ====
	var s4 := GameplaySession.new()
	var r4 := s4.load_level(path_59x59)
	_check(r4.ok, "M11-04: 59x59 load succeeds")
	_check_eq(s4.get_state(), GameplaySession.State.READY, "M11-04: state is READY")
	_check_eq(s4.get_level_data().width, 59, "M11-04: width 59")
	_check_eq(s4.get_level_data().height, 59, "M11-04: height 59")

	# ==== 5. Missing path fails, stays UNINITIALIZED ====
	var s5 := GameplaySession.new()
	var r5 := s5.load_level("res://data/levels/nonexistent_level.json")
	_check(not r5.ok, "M11-05: missing path fails")
	_check_eq(r5.error, "load_failed", "M11-05: error is load_failed")
	_check_eq(s5.get_state(), GameplaySession.State.UNINITIALIZED, "M11-05: stays UNINITIALIZED")
	_check(s5.get_level_data() == null, "M11-05: level_data still null")
	_check(s5.get_board_state() == null, "M11-05: board_state still null")

	# ==== 6. Malformed level data fails cleanly ====
	var s6 := GameplaySession.new()
	var r6 := s6.load_level(malformed_path)
	_check(not r6.ok, "M11-06: malformed data fails")
	_check_eq(s6.get_state(), GameplaySession.State.UNINITIALIZED, "M11-06: stays UNINITIALIZED")

	# ==== 7. Failed replacement load preserves valid session ====
	var s7 := GameplaySession.new()
	s7.load_level(path_3x2)
	var ld_before = s7.get_level_data()
	var bs_before = s7.get_board_state()
	_check_eq(s7.get_state(), GameplaySession.State.READY, "M11-07: starts READY")
	var r7 := s7.load_level("res://data/levels/nonexistent.json")
	_check(not r7.ok, "M11-07: replacement load fails")
	_check_eq(s7.get_state(), GameplaySession.State.READY, "M11-07: state still READY")
	_check(s7.get_level_data() == ld_before, "M11-07: level_data unchanged")
	_check(s7.get_board_state() == bs_before, "M11-07: board_state unchanged")

	# ==== 8. BoardState matches level dimensions ====
	_check_eq(s.get_board_state().get_width(), 3, "M11-08: board width matches level")
	_check_eq(s.get_board_state().get_height(), 2, "M11-08: board height matches level")
	_check_eq(s.get_board_state().get_cell_count(), 6, "M11-08: board cell_count matches level")

	# ==== 9. LevelData unchanged after BoardState mutation ====
	var s9 := GameplaySession.new()
	s9.load_level(path_3x2)
	var ld9 = s9.get_level_data()
	var cells_before = ld9.cells.duplicate()
	s9.get_board_state().set_cell_state(0, BoardState.CellState.CLEAN)
	_check_eq(ld9.cells, cells_before, "M11-09: LevelData cells unchanged after BoardState mutation")
	_check_eq(ld9.width, 3, "M11-09: LevelData width unchanged")

	# ==== 10. Reset creates fresh BoardState ====
	var s10 := GameplaySession.new()
	s10.load_level(path_3x2)
	s10.start()
	var bs10_pre = s10.get_board_state()
	s10.get_board_state().set_cell_state(0, BoardState.CellState.CLEAN)
	s10.reset()
	_check(s10.get_board_state() != bs10_pre, "M11-10: reset creates new BoardState object (not same reference)")

	# ==== 11. Reset restores all cells DIRTY ====
	_check_eq(s10.get_board_state().get_cell_state(0), BoardState.CellState.DIRTY, "M11-11: cell 0 DIRTY after reset")
	var all_dirty := true
	for i in s10.get_board_state().get_cell_count():
		if s10.get_board_state().get_cell_state(i) != BoardState.CellState.DIRTY:
			all_dirty = false
			break
	_check(all_dirty, "M11-11: all cells DIRTY after reset")

	# ==== 12. Reset preserves dimensions/color IDs ====
	_check_eq(s10.get_board_state().get_width(), 3, "M11-12: width preserved after reset")
	_check_eq(s10.get_board_state().get_height(), 2, "M11-12: height preserved after reset")
	_check_eq(s10.get_board_state().get_cell_count(), 6, "M11-12: cell_count preserved after reset")

	# ==== 13. Independent sessions don't share mutable BoardState ====
	var sa := GameplaySession.new()
	var sb := GameplaySession.new()
	sa.load_level(path_3x2)
	sb.load_level(path_3x2)
	sa.get_board_state().set_cell_state(0, BoardState.CellState.CLEAN)
	_check_eq(sb.get_board_state().get_cell_state(0), BoardState.CellState.DIRTY, "M11-13: independent sessions don't share BoardState")

	# ==== 14. READY -> ACTIVE succeeds ====
	var s14 := GameplaySession.new()
	s14.load_level(path_3x2)
	var r14 := s14.start()
	_check(r14.ok, "M11-14: start() succeeds from READY")
	_check_eq(s14.get_state(), GameplaySession.State.ACTIVE, "M11-14: state is ACTIVE")

	# ==== 15. ACTIVE -> PAUSED succeeds ====
	var r15 := s14.pause()
	_check(r15.ok, "M11-15: pause() succeeds from ACTIVE")
	_check_eq(s14.get_state(), GameplaySession.State.PAUSED, "M11-15: state is PAUSED")

	# ==== 16. PAUSED -> ACTIVE resume succeeds ====
	var r16 := s14.resume()
	_check(r16.ok, "M11-16: resume() succeeds from PAUSED")
	_check_eq(s14.get_state(), GameplaySession.State.ACTIVE, "M11-16: state is ACTIVE after resume")

	# ==== 17. Invalid transitions fail without state mutation ====
	var s17 := GameplaySession.new()
	# start from UNINITIALIZED
	var r17a := s17.start()
	_check(not r17a.ok, "M11-17: start from UNINITIALIZED fails")
	_check_eq(r17a.error, "invalid_transition", "M11-17: error is invalid_transition")
	_check_eq(s17.get_state(), GameplaySession.State.UNINITIALIZED, "M11-17: state unchanged after invalid start")
	# pause from READY
	s17.load_level(path_3x2)
	var r17b := s17.pause()
	_check(not r17b.ok, "M11-17: pause from READY fails")
	_check_eq(s17.get_state(), GameplaySession.State.READY, "M11-17: state unchanged after invalid pause")
	# resume from READY
	var r17c := s17.resume()
	_check(not r17c.ok, "M11-17: resume from READY fails")
	_check_eq(s17.get_state(), GameplaySession.State.READY, "M11-17: state unchanged after invalid resume")
	# complete from READY
	var r17d := s17.complete()
	_check(not r17d.ok, "M11-17: complete from READY fails")
	_check_eq(s17.get_state(), GameplaySession.State.READY, "M11-17: state unchanged after invalid complete")
	# resume from ACTIVE
	s17.start()
	var r17e := s17.resume()
	_check(not r17e.ok, "M11-17: resume from ACTIVE fails")
	_check_eq(s17.get_state(), GameplaySession.State.ACTIVE, "M11-17: state unchanged after invalid resume from ACTIVE")
	# start from ACTIVE
	var r17f := s17.start()
	_check(not r17f.ok, "M11-17: start from ACTIVE fails")
	_check_eq(s17.get_state(), GameplaySession.State.ACTIVE, "M11-17: state unchanged after invalid start from ACTIVE")

	# ==== 18. Reset from READY/ACTIVE/PAUSED/COMPLETED ====
	# Reset from READY
	var s18 := GameplaySession.new()
	s18.load_level(path_3x2)
	var r18a := s18.reset()
	_check(r18a.ok, "M11-18: reset from READY ok")
	_check_eq(s18.get_state(), GameplaySession.State.READY, "M11-18: READY after reset from READY")
	# Reset from ACTIVE
	s18.start()
	var r18b := s18.reset()
	_check(r18b.ok, "M11-18: reset from ACTIVE ok")
	_check_eq(s18.get_state(), GameplaySession.State.READY, "M11-18: READY after reset from ACTIVE")
	# Reset from PAUSED
	s18.start()
	s18.pause()
	var r18c := s18.reset()
	_check(r18c.ok, "M11-18: reset from PAUSED ok")
	_check_eq(s18.get_state(), GameplaySession.State.READY, "M11-18: READY after reset from PAUSED")
	# Reset from COMPLETED
	s18.start()
	s18.complete()
	var r18d := s18.reset()
	_check(r18d.ok, "M11-18: reset from COMPLETED ok")
	_check_eq(s18.get_state(), GameplaySession.State.READY, "M11-18: READY after reset from COMPLETED")
	# Reset from UNINITIALIZED fails
	var s18u := GameplaySession.new()
	var r18u := s18u.reset()
	_check(not r18u.ok, "M11-18: reset from UNINITIALIZED fails")
	_check_eq(s18u.get_state(), GameplaySession.State.UNINITIALIZED, "M11-18: stays UNINITIALIZED after invalid reset")

	# ==== 19. Explicit completion from ACTIVE ====
	var s19 := GameplaySession.new()
	s19.load_level(path_3x2)
	s19.start()
	var r19 := s19.complete()
	_check(r19.ok, "M11-19: complete() from ACTIVE succeeds")
	_check_eq(s19.get_state(), GameplaySession.State.COMPLETED, "M11-19: state is COMPLETED")

	# ==== 20. Repeated completion is deterministic and non-corrupting ====
	var r20 := s19.complete()
	_check(not r20.ok, "M11-20: repeated complete() fails (already COMPLETED)")
	_check_eq(r20.error, "invalid_transition", "M11-20: error is invalid_transition")
	_check_eq(s19.get_state(), GameplaySession.State.COMPLETED, "M11-20: state still COMPLETED (non-corrupting)")

	# ==== 21. Manual cell cleaning does not auto-complete ====
	var s21 := GameplaySession.new()
	s21.load_level(path_3x2)
	s21.start()
	for i in s21.get_board_state().get_cell_count():
		s21.get_board_state().set_cell_state(i, BoardState.CellState.CLEAN)
	_check_eq(s21.get_board_state().count_cells_by_state(BoardState.CellState.DIRTY), 0, "M11-21: all cells are CLEAN")
	_check_eq(s21.get_state(), GameplaySession.State.ACTIVE, "M11-21: session still ACTIVE (no auto-complete)")

	# ==== 22-26. Renderer seam ====
	var s22 := GameplaySession.new()
	var renderer := BoardRenderer.new()

	# 22. Bind renderer before load — no crash, renderer not configured
	s22.bind_renderer(renderer, Vector2(800, 600))
	_check_eq(s22.get_state(), GameplaySession.State.UNINITIALIZED, "M11-22: bind before load keeps UNINITIALIZED")

	# Load, renderer should auto-configure
	s22.load_level(path_3x2)
	_check_eq(s22.get_state(), GameplaySession.State.READY, "M11-22: READY after load with bound renderer")

	# 23. Renderer pixel output follows session-owned BoardState (F-M11-001)
	_check_eq(renderer.get_cell_size() > 0, true, "M11-23: renderer configured (cell_size > 0)")
	var board_pixel_size := renderer.get_board_pixel_size()
	_check(board_pixel_size.x > 0 and board_pixel_size.y > 0, "M11-23: renderer has non-zero board pixel size")
	var ld23 = s22.get_level_data()
	var base23 := Color.html(ld23.palette[s22.get_board_state().get_color_id(0)])
	var dirty23 := DirtyCleanPresets.apply_dirty(base23, DirtyCleanPresets.DEFAULT_PRESET_NAME)
	var px23_before := renderer.get_pixel_color(0, 0)
	_check(_colors_close(px23_before, dirty23, 0.01), "M11-23: pixel (0,0) shows DIRTY color before mutation")
	s22.get_board_state().set_cell_state(0, BoardState.CellState.CLEAN)
	renderer.update_cells([0])
	var px23_after := renderer.get_pixel_color(0, 0)
	_check(_colors_close(px23_after, base23, 0.01), "M11-23: pixel (0,0) shows CLEAN palette color after mutation via session BoardState")
	_check(not _colors_close(px23_before, px23_after, 0.01), "M11-23: DIRTY and CLEAN pixels differ — renderer reads session-owned BoardState")

	# 24. Reset: renderer follows NEW BoardState, not stale old one (F-M11-001)
	s22.start()
	var old_board24 = s22.get_board_state()
	s22.reset()
	var new_board24 = s22.get_board_state()
	_check_eq(s22.get_state(), GameplaySession.State.READY, "M11-24: READY after reset")
	_check(old_board24 != new_board24, "M11-24: reset created a different BoardState object")
	_check_eq(new_board24.get_cell_state(0), BoardState.CellState.DIRTY, "M11-24: new board cell 0 is DIRTY")
	old_board24.set_cell_state(0, BoardState.CellState.CLEAN)
	renderer.update_cells([0])
	var px24 := renderer.get_pixel_color(0, 0)
	var dirty24 := DirtyCleanPresets.apply_dirty(base23, DirtyCleanPresets.DEFAULT_PRESET_NAME)
	_check(_colors_close(px24, dirty24, 0.01), "M11-24: pixel follows NEW BoardState (DIRTY), not stale old (CLEAN)")
	_check(not _colors_close(px24, base23, 0.01), "M11-24: pixel is NOT the CLEAN color from stale old BoardState")

	# 25. Rectangular board geometry correct
	var s25 := GameplaySession.new()
	var renderer25 := BoardRenderer.new()
	s25.bind_renderer(renderer25, Vector2(800, 600))
	s25.load_level(rect_path)
	var bp25 := renderer25.get_board_pixel_size()
	_check(bp25.x > 0 and bp25.y > 0, "M11-25: rectangular renderer has non-zero board pixel size")
	# Board is 20x27 — pixel height should be >= pixel width (portrait)
	var cell_size_25 := renderer25.get_cell_size()
	_check_eq(cell_size_25 > 0, true, "M11-25: rectangular cell_size > 0")
	_check(bp25.y >= bp25.x, "M11-25: 20x27 board pixel size is portrait-like (height >= width)")
	renderer25.free()

	# 26. 59x59 renderer remains single node
	var s26 := GameplaySession.new()
	var renderer26 := BoardRenderer.new()
	s26.bind_renderer(renderer26, Vector2(1080, 1080))
	s26.load_level(path_59x59)
	_check_eq(renderer26.get_child_count(), 0, "M11-26: 59x59 renderer has zero child Nodes")
	_check_eq(renderer26.get_cell_size() > 0, true, "M11-26: 59x59 renderer configured")
	renderer26.free()

	# ==== 27. No slot/target/routing/agent implementation created ====
	# Placeholder .gitkeep directories may exist from prior architecture planning;
	# verify no GDScript implementation files were introduced.
	_check(not FileAccess.file_exists("res://scripts/gameplay/slots/slot_manager.gd"), "M11-27: no slot implementation")
	_check(not FileAccess.file_exists("res://scripts/gameplay/routing/routing_system.gd"), "M11-27: no routing implementation")
	_check(not DirAccess.dir_exists_absolute("res://scripts/gameplay/agents"), "M11-27: no agents directory")
	_check(not FileAccess.file_exists("res://scripts/gameplay/target/target_selector.gd"), "M11-27: no target implementation")

	# ==== 28. No win/lose/timer/move-limit rule ====
	# Verify session class has no timer/move/lose properties
	var s28 := GameplaySession.new()
	_check(not s28.has_method("check_win"), "M11-28: no check_win method")
	_check(not s28.has_method("check_lose"), "M11-28: no check_lose method")
	_check(not s28.has_method("get_timer"), "M11-28: no get_timer method")
	_check(not s28.has_method("get_moves"), "M11-28: no get_moves method")
	_check(not s28.has_method("get_move_limit"), "M11-28: no get_move_limit method")

	# ==== 29. Prior checks remain green (verified by running entire suite) ====
	# (implicit — all test functions run together, _print_summary reports total)

	# ---- performance sanity: 59x59 load/reset ----
	var s_perf := GameplaySession.new()
	var t0 := Time.get_ticks_usec()
	s_perf.load_level(path_59x59)
	var t1 := Time.get_ticks_usec()
	s_perf.start()
	s_perf.reset()
	var t2 := Time.get_ticks_usec()
	print("---- GameplaySession performance sanity (59x59) ----")
	print("  load_level: %.3f ms" % ((t1 - t0) / 1000.0))
	print("  reset: %.3f ms" % ((t2 - t1) / 1000.0))

	# ---- cleanup ----
	renderer.free()
	var dir := DirAccess.open(test_dir)
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while not fname.is_empty():
			if not dir.current_is_dir():
				dir.remove(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(test_dir)

func _run_slot_system_tests() -> void:
	print("---- M12: SlotSystem / SlotState tests ----")

	# M12-01: construct exactly five slots
	var sys := SlotSystem.new()
	_check_eq(sys.get_slot_count(), 5, "M12-01 slot count is 5")
	_check(sys is RefCounted, "M12-01 SlotSystem is RefCounted")
	_check(not sys.has_method("get_parent"), "M12-01 SlotSystem has no Node ancestry")

	# M12-02: deterministic stable slot IDs 0..4 (scalar query, no internal leak)
	for i in 5:
		_check_eq(sys.get_slot_id(i), i, "M12-02 slot %d has ID %d" % [i, i])

	# M12-03: valid palette assignment for all five
	var r := sys.configure([0, 1, 2, 3, 4], 8)
	_check(r.ok, "M12-03 valid palette config succeeds")
	_check(sys.is_configured(), "M12-03 system reports configured")
	for i in 5:
		_check_eq(sys.get_slot_palette_id(i), i, "M12-03 slot %d palette_id=%d" % [i, i])

	# Identity stability after configure
	for i in 5:
		_check_eq(sys.get_slot_id(i), i, "M12-04 slot %d ID stable after config" % i)

	# M12-04: duplicate valid palette IDs with small palette
	var sys2 := SlotSystem.new()
	var r2 := sys2.configure([0, 0, 1, 1, 0], 2)
	_check(r2.ok, "M12-04 duplicate palette IDs accepted")
	_check_eq(sys2.get_slot_palette_id(0), 0, "M12-04 slot 0 palette=0")
	_check_eq(sys2.get_slot_palette_id(1), 0, "M12-04 slot 1 palette=0")
	_check_eq(sys2.get_slot_palette_id(2), 1, "M12-04 slot 2 palette=1")
	_check_eq(sys2.get_slot_palette_id(3), 1, "M12-04 slot 3 palette=1")
	_check_eq(sys2.get_slot_palette_id(4), 0, "M12-04 slot 4 palette=0")
	# palette-based lookup
	var by0 := sys2.get_slots_by_palette_id(0)
	_check_eq(by0.size(), 3, "M12-04 palette 0 has 3 slots")
	var by1 := sys2.get_slots_by_palette_id(1)
	_check_eq(by1.size(), 2, "M12-04 palette 1 has 2 slots")

	# M12-05: availability query/change on one slot, others unchanged
	var sys3 := SlotSystem.new()
	sys3.configure([0, 1, 2, 3, 4], 5)
	for i in 5:
		_check(sys3.is_slot_available(i), "M12-05 slot %d default available" % i)
	sys3.set_slot_available(2, false)
	_check(not sys3.is_slot_available(2), "M12-05 slot 2 now unavailable")
	for i in [0, 1, 3, 4]:
		_check(sys3.is_slot_available(i), "M12-05 slot %d still available" % i)
	sys3.set_slot_available(2, true)
	_check(sys3.is_slot_available(2), "M12-05 slot 2 restored available")

	# M12-06: activity query/change on one slot, others unchanged
	for i in 5:
		_check(not sys3.is_slot_active(i), "M12-06 slot %d default inactive" % i)
	sys3.set_slot_active(1, true)
	_check(sys3.is_slot_active(1), "M12-06 slot 1 now active")
	for i in [0, 2, 3, 4]:
		_check(not sys3.is_slot_active(i), "M12-06 slot %d still inactive" % i)
	sys3.set_slot_active(1, false)
	_check(not sys3.is_slot_active(1), "M12-06 slot 1 restored inactive")

	# M12-07: availability and activity are independent
	sys3.set_slot_available(0, false)
	sys3.set_slot_active(0, true)
	_check(not sys3.is_slot_available(0), "M12-07 slot 0 unavailable")
	_check(sys3.is_slot_active(0), "M12-07 slot 0 active despite unavailable")
	sys3.set_slot_active(0, false)
	sys3.set_slot_available(0, true)
	_check(sys3.is_slot_available(0), "M12-07 slot 0 available restored")
	_check(not sys3.is_slot_active(0), "M12-07 slot 0 inactive restored")

	# M12-08: wrong number of palette assignments rejected
	var sys4 := SlotSystem.new()
	var r4 := sys4.configure([0, 1, 2, 3], 5)
	_check(not r4.ok, "M12-08 four assignments rejected")
	_check_eq(r4.error, "wrong_count", "M12-08 error is wrong_count")
	var r4b := sys4.configure([0, 1, 2, 3, 4, 5], 8)
	_check(not r4b.ok, "M12-08 six assignments rejected")
	var r4c := sys4.configure([], 5)
	_check(not r4c.ok, "M12-08 empty assignments rejected")

	# M12-09: negative palette ID rejected
	var sys5 := SlotSystem.new()
	var r5 := sys5.configure([0, 1, -1, 3, 4], 5)
	_check(not r5.ok, "M12-09 negative palette ID rejected")
	_check_eq(r5.error, "invalid_palette_id", "M12-09 error is invalid_palette_id")

	# M12-10: palette ID >= palette_size rejected
	var sys6 := SlotSystem.new()
	var r6 := sys6.configure([0, 1, 2, 3, 5], 5)
	_check(not r6.ok, "M12-10 palette ID=5 with size=5 rejected")
	_check_eq(r6.error, "palette_id_out_of_range", "M12-10 error is palette_id_out_of_range")
	var r6b := sys6.configure([0, 1, 2, 3, 99], 5)
	_check(not r6b.ok, "M12-10 palette ID=99 rejected")

	# M12-11: negative slot ID rejected
	var rn := sys.set_slot_available(-1, false)
	_check(not rn.ok, "M12-11 negative slot ID availability rejected")
	var rn2 := sys.set_slot_active(-1, true)
	_check(not rn2.ok, "M12-11 negative slot ID activity rejected")
	_check_eq(sys.get_slot_id(-1), -1, "M12-11 get_slot_id(-1) returns -1")
	_check_eq(sys.get_slot_palette_id(-1), -1, "M12-11 get_slot_palette_id(-1) returns -1")

	# M12-12: slot ID >= 5 rejected
	var ro := sys.set_slot_available(5, false)
	_check(not ro.ok, "M12-12 slot ID=5 availability rejected")
	var ro2 := sys.set_slot_active(5, true)
	_check(not ro2.ok, "M12-12 slot ID=5 activity rejected")
	_check_eq(sys.get_slot_id(5), -1, "M12-12 get_slot_id(5) returns -1")
	_check_eq(sys.get_slot_palette_id(5), -1, "M12-12 get_slot_palette_id(5) returns -1")
	var ro3 := sys.set_slot_available(100, false)
	_check(not ro3.ok, "M12-12 slot ID=100 rejected")

	# M12-13: failed reconfiguration preserves prior valid state
	var sys7 := SlotSystem.new()
	sys7.configure([0, 1, 2, 3, 4], 8)
	# verify baseline
	for i in 5:
		_check_eq(sys7.get_slot_palette_id(i), i, "M12-13 baseline slot %d palette=%d" % [i, i])
	# attempt invalid reconfig
	var r7 := sys7.configure([0, 1, 2, -1, 4], 8)
	_check(not r7.ok, "M12-13 invalid reconfig fails")
	_check(sys7.is_configured(), "M12-13 still configured after failed reconfig")
	for i in 5:
		_check_eq(sys7.get_slot_palette_id(i), i, "M12-13 slot %d preserved after failed reconfig" % i)
	# attempt wrong count reconfig
	var r7b := sys7.configure([0, 1, 2], 8)
	_check(not r7b.ok, "M12-13 wrong count reconfig fails")
	for i in 5:
		_check_eq(sys7.get_slot_palette_id(i), i, "M12-13 slot %d preserved after wrong count" % i)

	# M12-14: invalid mutation preserves prior state
	sys7.set_slot_available(2, false)
	sys7.set_slot_active(3, true)
	var rm := sys7.set_slot_available(-1, true)
	_check(not rm.ok, "M12-14 invalid mutation rejected")
	_check(not sys7.is_slot_available(2), "M12-14 slot 2 still unavailable after invalid mutation")
	_check(sys7.is_slot_active(3), "M12-14 slot 3 still active after invalid mutation")

	# M12-15: query API does not permit structural count mutation
	_check_eq(sys7.get_slot_count(), 5, "M12-15 count is 5 after all operations")
	# no add/remove methods exist — structural invariant holds by API design

	# M12-16: model uses no UI/scene hierarchy
	_check(not sys7.has_method("get_parent"), "M12-16 SlotSystem has no Node ancestry")

	# M12-17: no dispatch/target/routing/agent behavior
	# verified by API inspection: SlotSystem has no dispatch/target/route methods
	_check(not sys7.has_method("dispatch"), "M12-17 no dispatch method")
	_check(not sys7.has_method("select_target"), "M12-17 no select_target method")
	_check(not sys7.has_method("route"), "M12-17 no route method")
	_check(not sys7.has_method("spawn_agent"), "M12-17 no spawn_agent method")

	# M12-18: F-M12-001 bypass regression — get_slot() must not exist (AL-020)
	_check(not sys.has_method("get_slot"), "M12-18 get_slot removed from public API")
	# All public query methods return scalars, not mutable internal objects
	var query_result_id = sys.get_slot_id(0)
	_check(query_result_id is int, "M12-18 get_slot_id returns scalar int")
	var query_result_pid = sys.get_slot_palette_id(0)
	_check(query_result_pid is int, "M12-18 get_slot_palette_id returns scalar int")
	var query_result_avail = sys.is_slot_available(0)
	_check(query_result_avail is bool, "M12-18 is_slot_available returns scalar bool")
	var query_result_active = sys.is_slot_active(0)
	_check(query_result_active is bool, "M12-18 is_slot_active returns scalar bool")
	# Verify no public method returns an object with set_palette_id
	_check(not (query_result_id is Object), "M12-18 ID query is not Object")
	_check(not (query_result_pid is Object), "M12-18 palette query is not Object")
	# Palette can only change through validated configure()
	sys.configure([0, 1, 2, 3, 4], 8)
	_check_eq(sys.get_slot_palette_id(0), 0, "M12-18 palette 0 via configure")
	# No way to write palette_id=999 without going through configure validation
	var bypass_attempt := sys.configure([999, 1, 2, 3, 4], 8)
	_check(not bypass_attempt.ok, "M12-18 palette 999 rejected by configure")
	_check_eq(sys.get_slot_palette_id(0), 0, "M12-18 palette 0 unchanged after rejected bypass")

	print("  M12 slot system tests complete")

## ------------------------------------------------- M13: eligible index --

## Builds a BoardState with an explicit color layout (bypassing JSON) so M13
## tests can control exactly which colors sit at which indices.
func _make_colored_board(width: int, height: int, color_ids: Array):
	var palette := PackedStringArray()
	var max_color := 0
	for c in color_ids:
		if c > max_color:
			max_color = c
	for i in (max_color + 1):
		palette.append("#000000")
	var cells := PackedInt32Array(color_ids)
	var level := LevelData.new(1, "m13", "m13", "TEST", width, height, palette, cells)
	return BoardState.from_level_data(level)

func _run_eligible_target_index_tests() -> void:
	print("---- M13: EligibleTargetIndex tests ----")
	var DIRTY := BoardState.CellState.DIRTY
	var CLEAN := BoardState.CellState.CLEAN

	# Layout (3x2, row-major indices):
	#   0:c0  1:c1  2:c0
	#   3:c1  4:c0  5:c2
	# color 0 -> [0,2,4], color 1 -> [1,3], color 2 -> [5]
	var layout := [0, 1, 0, 1, 0, 2]

	# --- T1: unbound index returns safe empty/no-work ---
	var idx0 = EligibleTargetIndex.create()
	_check_eq(idx0.is_bound(), false, "M13-01 fresh index is unbound")
	_check_eq(idx0.get_eligible(0), [], "M13-01 unbound get_eligible returns empty")
	_check_eq(idx0.has_work(0), false, "M13-01 unbound has_work is false")
	_check_eq(idx0.bind(null), false, "M13-01 bind(null) rejected")
	_check_eq(idx0.is_bound(), false, "M13-01 still unbound after bind(null)")

	# --- T2: initial build groups all DIRTY cells by color ---
	var board = _make_colored_board(3, 2, layout)
	var idx = EligibleTargetIndex.create()
	_check(idx.bind(board), "M13-02 bind to board succeeds")
	_check(idx.is_bound(), "M13-02 index bound after bind")
	_check_eq(idx.get_eligible(0), [0, 2, 4], "M13-02 color 0 grouped as [0,2,4]")
	_check_eq(idx.get_eligible(1), [1, 3], "M13-02 color 1 grouped as [1,3]")
	_check_eq(idx.get_eligible(2), [5], "M13-02 color 2 grouped as [5]")

	# --- T3: queries return only the requested color ---
	for i in idx.get_eligible(0):
		_check_eq(board.get_color_id(i), 0, "M13-03 every color-0 result has color 0")
	for i in idx.get_eligible(1):
		_check_eq(board.get_color_id(i), 1, "M13-03 every color-1 result has color 1")

	# --- T4: results contain only valid indices ---
	for i in idx.get_eligible(0):
		_check(board.is_valid_index(i), "M13-04 color-0 result index %d valid" % i)

	# --- T5: CLEAN cell + sync removes it ---
	board.set_cell_state(2, CLEAN)
	_check(idx.sync_cell(2), "M13-05 sync of cleaned cell succeeds")
	_check_eq(idx.get_eligible(0), [0, 4], "M13-05 cleaned cell 2 removed from color 0")

	# --- T6: DIRTY restoration + sync adds it back once (no duplicate) ---
	board.set_cell_state(2, DIRTY)
	_check(idx.sync_cell(2), "M13-06 sync of re-dirtied cell succeeds")
	_check_eq(idx.get_eligible(0), [0, 2, 4], "M13-06 re-dirtied cell 2 restored in row-major order")
	# double-sync must not duplicate
	idx.sync_cell(2)
	_check_eq(idx.get_eligible(0), [0, 2, 4], "M13-06 repeated sync does not duplicate index")

	# --- T7: mutating one color does not corrupt another bucket ---
	board.set_cell_state(1, CLEAN)
	idx.sync_cell(1)
	_check_eq(idx.get_eligible(1), [3], "M13-07 color 1 loses cell 1")
	_check_eq(idx.get_eligible(0), [0, 2, 4], "M13-07 color 0 bucket unaffected")
	_check_eq(idx.get_eligible(2), [5], "M13-07 color 2 bucket unaffected")
	# restore for later tests
	board.set_cell_state(1, DIRTY)
	idx.sync_cell(1)

	# --- T8: invalid sync index fails without corrupting state ---
	_check_eq(idx.sync_cell(-1), false, "M13-08 sync(-1) rejected")
	_check_eq(idx.sync_cell(999), false, "M13-08 sync(out-of-range) rejected")
	_check_eq(idx.get_eligible(0), [0, 2, 4], "M13-08 buckets intact after invalid sync")
	_check_eq(idx.get_eligible(1), [1, 3], "M13-08 color 1 intact after invalid sync")

	# --- T9: full rebuild after multiple changes matches board truth ---
	board.set_cell_state(0, CLEAN)
	board.set_cell_state(5, CLEAN)
	_check(idx.rebuild(), "M13-09 rebuild succeeds")
	_check_eq(idx.get_eligible(0), [2, 4], "M13-09 rebuild reflects cleaned cell 0")
	_check_eq(idx.get_eligible(2), [], "M13-09 rebuild reflects exhausted color 2")
	# color 2 exhausted -> not even a key
	_check(not idx.get_color_ids().has(2), "M13-09 exhausted color 2 has no bucket key")

	# --- T10: rebind to fresh board discards stale candidates ---
	var fresh = _make_colored_board(2, 1, [7, 7]) # indices 0,1 both color 7
	_check(idx.rebind(fresh), "M13-10 rebind to fresh board succeeds")
	_check_eq(idx.get_eligible(0), [], "M13-10 stale color 0 gone after rebind")
	_check_eq(idx.get_eligible(7), [0, 1], "M13-10 fresh board color 7 present")
	_check_eq(idx.get_color_ids().size(), 1, "M13-10 only fresh board colors present")

	# --- T11 & T12: no-work query present vs exhausted ---
	var board2 = _make_colored_board(3, 2, layout)
	var idx2 = EligibleTargetIndex.create()
	idx2.bind(board2)
	_check_eq(idx2.has_work(0), true, "M13-11 has_work true when color 0 has eligible cells")
	_check_eq(idx2.has_work(2), true, "M13-11 has_work true when color 2 has one cell")
	_check_eq(idx2.has_work(99), false, "M13-12 has_work false for a color with no cells")
	# exhaust color 2
	board2.set_cell_state(5, CLEAN)
	idx2.sync_cell(5)
	_check_eq(idx2.has_work(2), false, "M13-12 has_work false after color 2 exhausted")
	_check_eq(idx2.get_eligible(2), [], "M13-12 get_eligible empty after exhaustion")

	# --- T13 & T14: last-target then clean -> no-work ---
	# color 2 already exhausted; use a single-cell color to test last-target
	var board3 = _make_colored_board(2, 1, [3, 4])
	var idx3 = EligibleTargetIndex.create()
	idx3.bind(board3)
	_check_eq(idx3.get_eligible(3), [0], "M13-13 last-target color 3 returns exactly one candidate")
	_check_eq(idx3.has_work(3), true, "M13-13 has_work true for last target")
	board3.set_cell_state(0, CLEAN)
	idx3.sync_cell(0)
	_check_eq(idx3.has_work(3), false, "M13-14 cleaning last target produces no-work")
	_check_eq(idx3.get_eligible(3), [], "M13-14 last target gone from eligible")

	# --- T15: caller-supplied reserved/excluded target is omitted ---
	_check_eq(idx2.get_eligible(0, [2]), [0, 4], "M13-15 excluded index 2 omitted from color 0")
	_check_eq(idx2.get_eligible(0, [0, 4]), [2], "M13-15 multiple exclusions honored")

	# --- T16: reserving/excluding the only target -> no-work ---
	_check_eq(idx3.has_work(4, [1]), false, "M13-16 excluding only color-4 target yields no-work")
	_check_eq(idx3.get_eligible(4, [1]), [], "M13-16 excluded only target yields empty")

	# --- T17: removing exclusion re-exposes DIRTY target w/o stored state ---
	_check_eq(idx3.get_eligible(4, []), [1], "M13-17 without exclusion the DIRTY target is visible again")
	_check_eq(idx3.has_work(4), true, "M13-17 has_work true again once exclusion dropped")

	# --- T18: reservation filter does not mutate cached membership ---
	var before = idx2.get_eligible(0)
	idx2.get_eligible(0, [0, 2, 4]) # fully-excluded query
	idx2.has_work(0, [0, 2, 4])
	_check_eq(idx2.get_eligible(0), before, "M13-18 exclusion query left internal bucket unchanged")

	# --- T19: returned collection cannot mutate internal truth ---
	var leaked = idx2.get_eligible(0)
	leaked.append(99999)
	leaked.clear()
	_check_eq(idx2.get_eligible(0), [0, 2, 4], "M13-19 mutating returned array does not affect index")

	# --- T20: deterministic ordering stable across remove/re-add/rebuild ---
	var board4 = _make_colored_board(3, 3, [0, 0, 0, 0, 0, 0, 0, 0, 0]) # all color 0
	var idx4 = EligibleTargetIndex.create()
	idx4.bind(board4)
	_check_eq(idx4.get_eligible(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 initial row-major order")
	board4.set_cell_state(4, CLEAN); idx4.sync_cell(4)
	board4.set_cell_state(4, DIRTY); idx4.sync_cell(4)
	_check_eq(idx4.get_eligible(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 order stable after remove+re-add")
	idx4.rebuild()
	_check_eq(idx4.get_eligible(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 order stable after rebuild")

	# --- T21: 59x59 / 3481-cell correctness ---
	var big_cells := PackedInt32Array()
	big_cells.resize(3481)
	for i in 3481:
		big_cells[i] = i % 5 # 5 palette colors, deterministic spread
	var big_board = _make_colored_board(59, 59, Array(big_cells))
	var big_idx = EligibleTargetIndex.create()
	big_idx.bind(big_board)
	# independent recount from board truth
	var expected_counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	for i in 3481:
		expected_counts[i % 5] += 1
	var total_indexed := 0
	for c in 5:
		var got: int = big_idx.get_eligible(c).size()
		_check_eq(got, expected_counts[c], "M13-21 59x59 color %d count matches board truth" % c)
		total_indexed += got
	_check_eq(total_indexed, 3481, "M13-21 59x59 all 3481 DIRTY cells indexed exactly once")
	# each bucket strictly ascending (row-major determinism at scale)
	var asc_ok := true
	for c in 5:
		var b: Array = big_idx.get_eligible(c)
		for k in range(1, b.size()):
			if b[k] <= b[k - 1]:
				asc_ok = false
				break
	_check(asc_ok, "M13-21 59x59 every bucket strictly ascending (deterministic)")
	# clean one whole color via sync, verify has_work flips
	for i in 3481:
		if i % 5 == 3:
			big_board.set_cell_state(i, CLEAN)
			big_idx.sync_cell(i)
	_check_eq(big_idx.has_work(3), false, "M13-21 59x59 color 3 no-work after full clean via sync")
	_check_eq(big_idx.has_work(0), true, "M13-21 59x59 other colors still have work")

	# --- T22: rectangular-board correctness (5x3) ---
	# indices row-major; color = 0 on even index, 1 on odd
	var rect_cells := []
	for i in 15:
		rect_cells.append(i % 2)
	var rect_board = _make_colored_board(5, 3, rect_cells)
	var rect_idx = EligibleTargetIndex.create()
	rect_idx.bind(rect_board)
	_check_eq(rect_idx.get_eligible(0), [0, 2, 4, 6, 8, 10, 12, 14], "M13-22 rectangular even indices color 0")
	_check_eq(rect_idx.get_eligible(1), [1, 3, 5, 7, 9, 11, 13], "M13-22 rectangular odd indices color 1")

	# --- T23 (F-M13-001 corrected): steady-state queries touch ZERO BoardState
	# traversal APIs. Spy counts get_cell_count / is_valid_index / get_color_id /
	# get_cell_state; build may scan, but repeated get_eligible/has_work/
	# count_eligible must add zero traversal reads across ALL those APIs — so a
	# future `for i in board.get_cell_count(): board.get_color_id(i)` regression
	# is caught even if it never calls get_cell_state().
	var spy = load("res://tests/support/board_state_scan_spy.gd").new()
	spy.setup([0, 1, 0, 1, 0, 2], 3, 2)
	var idx5 = EligibleTargetIndex.create()
	idx5.bind(spy) # build performs the one allowed scan
	var build_reads: int = spy.traversal_reads()
	_check(spy.count_get_cell_state >= 6, "M13-23 build scanned cell states (>= cell count)")
	_check(build_reads >= 6, "M13-23 build registered board traversal reads")

	# item 16: repeated get_eligible adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_eligible(0)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x get_eligible added zero BoardState traversal reads")

	# item 17: repeated has_work adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.has_work(1)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x has_work added zero BoardState traversal reads")

	# item 18: repeated count_eligible adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.count_eligible(0)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x count_eligible added zero BoardState traversal reads")

	# item 19: absent-color query adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_eligible(99)
		idx5.has_work(99)
		idx5.count_eligible(99)
	_check_eq(spy.traversal_reads(), 0, "M13-23 absent-color queries added zero BoardState traversal reads")

	# item 20: exclusion-filtered query adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_eligible(0, [0, 4])
		idx5.has_work(0, [0, 2, 4])
		idx5.count_eligible(0, [2])
	_check_eq(spy.traversal_reads(), 0, "M13-23 exclusion-filtered queries added zero BoardState traversal reads")

	# item 21: per-API breakdown proves no single traversal API moved
	_check_eq(spy.count_get_cell_count, 0, "M13-23 zero get_cell_count during steady-state queries")
	_check_eq(spy.count_is_valid_index, 0, "M13-23 zero is_valid_index during steady-state queries")
	_check_eq(spy.count_get_color_id, 0, "M13-23 zero get_color_id during steady-state queries (catches color-loop regression)")
	_check_eq(spy.count_get_cell_state, 0, "M13-23 zero get_cell_state during steady-state queries")

	# item 21 sensitivity: a naive color-loop query WOULD move the counter,
	# proving the observability is not vacuous.
	spy.reset_counters()
	var naive_hits := 0
	for i in spy.get_cell_count():
		if spy.get_color_id(i) == 0 and spy.get_cell_state(i) == BoardState.CellState.DIRTY:
			naive_hits += 1
	_check(spy.traversal_reads() > 0, "M13-23 sensitivity: a full-board color loop DOES move the traversal counter")
	_check_eq(naive_hits, 3, "M13-23 sensitivity: naive loop found the 3 color-0 DIRTY cells")

	_run_m13_v02_formal_validation()
	print("  M13 EligibleTargetIndex tests complete")

## M13-C001 V02 formal validation of reopened SB-M13-006..010, filling the
## coverage gaps the V02 prompt/criteria enumerate beyond the V01 tests above.
func _run_m13_v02_formal_validation() -> void:
	var DIRTY := BoardState.CellState.DIRTY
	var CLEAN := BoardState.CellState.CLEAN

	# --- SB-M13-006 reservation/exclusion robustness ---
	# 3x2: color 0 -> [0,2,4], color 1 -> [1,3], color 2 -> [5]
	var b = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2])
	var ix = EligibleTargetIndex.create()
	ix.bind(b)
	# duplicate excluded indices
	_check_eq(ix.get_eligible(0, [2, 2, 2]), [0, 4], "M13V2-006 duplicate exclusion index handled once")
	# invalid negative / out-of-range exclusions have no effect
	_check_eq(ix.get_eligible(0, [-1, 999, -50]), [0, 2, 4], "M13V2-006 invalid exclusion indices ignored")
	# mix of valid + invalid
	_check_eq(ix.get_eligible(0, [-1, 2, 999]), [0, 4], "M13V2-006 mixed valid/invalid exclusion filters only valid")
	# cross-color exclusion cannot corrupt requested color
	_check_eq(ix.get_eligible(0, [1, 3, 5]), [0, 2, 4], "M13V2-006 excluding other colors' indices leaves color 0 intact")
	_check_eq(ix.get_eligible(1, [0, 4]), [1, 3], "M13V2-006 excluding color-0 indices leaves color 1 intact")
	# exclusion query does not mutate cache
	var snap = ix.get_eligible(0)
	ix.get_eligible(0, [0, 2, 4])
	ix.has_work(0, [0, 2, 4])
	ix.count_eligible(0, [0])
	_check_eq(ix.get_eligible(0), snap, "M13V2-006 exclusion queries did not mutate cached bucket")
	# Dictionary-like caller set supported (keys are indices)
	_check_eq(ix.get_eligible(0, {2: true, 4: true}), [0], "M13V2-006 Dictionary exclusion set supported")
	_check_eq(ix.has_work(0, {0: true, 2: true, 4: true}), false, "M13V2-006 Dictionary exclusion of all targets -> no work")
	# confirm no persistent reservation state: BoardState enum unchanged, no leak
	_check(not ("RESERVED" in BoardState.CellState), "M13V2-006 BoardState.CellState has no RESERVED")
	_check(not ix.has_method("reserve"), "M13V2-006 index has no reserve() ownership method")
	_check(not ix.has_method("release"), "M13V2-006 index has no release() method")

	# --- SB-M13-007 no-work query full matrix ---
	_check_eq(ix.has_work(0), true, "M13V2-007 present color has work")
	_check_eq(ix.has_work(99), false, "M13V2-007 absent color has no work")
	_check_eq(ix.has_work(0, [0, 2, 4]), false, "M13V2-007 all-excluded -> no work")
	_check_eq(ix.has_work(0, [0, 2]), true, "M13V2-007 partial exclusion still has work")
	var unbound = EligibleTargetIndex.create()
	_check_eq(unbound.has_work(0), false, "M13V2-007 unbound index reports no work")
	_check_eq(unbound.count_eligible(0), 0, "M13V2-007 unbound count is zero")

	# --- SB-M13-008 exhausted color: incremental sync AND full rebuild paths ---
	# incremental: clean color 2's only cell
	b.set_cell_state(5, CLEAN)
	ix.sync_cell(5)
	_check_eq(ix.has_work(2), false, "M13V2-008 incremental: exhausted color no work")
	_check_eq(ix.get_eligible(2), [], "M13V2-008 incremental: exhausted color empty")
	_check(not ix.get_color_ids().has(2), "M13V2-008 incremental: exhausted color key absent")
	# full rebuild path: clean all of color 1 in BoardState WITHOUT per-cell sync
	b.set_cell_state(1, CLEAN)
	b.set_cell_state(3, CLEAN)
	ix.rebuild()
	_check_eq(ix.has_work(1), false, "M13V2-008 rebuild: exhausted color 1 no work")
	_check_eq(ix.get_eligible(1), [], "M13V2-008 rebuild: exhausted color 1 empty")
	_check(not ix.get_color_ids().has(1), "M13V2-008 rebuild: exhausted color 1 key absent")
	_check_eq(ix.get_eligible(0), [0, 2, 4], "M13V2-008 rebuild: surviving color 0 intact and matches board truth")

	# --- SB-M13-009 last-target lifecycle ---
	var lb = _make_colored_board(2, 1, [3, 4])
	var lix = EligibleTargetIndex.create()
	lix.bind(lb)
	_check_eq(lix.get_eligible(3), [0], "M13V2-009 exactly one candidate for color 3")
	_check_eq(lix.has_work(3), true, "M13V2-009 last target has work")
	_check_eq(lix.has_work(3, [0]), false, "M13V2-009 excluding only target -> no work")
	_check_eq(lix.has_work(3, []), true, "M13V2-009 dropping exclusion re-exposes target")
	lb.set_cell_state(0, CLEAN)
	lix.sync_cell(0)
	_check_eq(lix.has_work(3), false, "M13V2-009 clean last target + sync -> no work")
	_check_eq(lix.get_eligible(3), [], "M13V2-009 candidate list empty after last target cleaned")

	# --- SB-M13-010 3,481-cell exclusion filter at scale + non-mutation ---
	var big_cells := PackedInt32Array()
	big_cells.resize(3481)
	for i in 3481:
		big_cells[i] = i % 5
	var bb = _make_colored_board(59, 59, Array(big_cells))
	var bix = EligibleTargetIndex.create()
	bix.bind(bb)
	var color0_full: Array = bix.get_eligible(0)
	# exclude the first 10 color-0 indices
	var excl := color0_full.slice(0, 10)
	var filtered: Array = bix.get_eligible(0, excl)
	_check_eq(filtered.size(), color0_full.size() - 10, "M13V2-010 scale exclusion removes exactly the excluded candidates")
	_check_eq(bix.get_eligible(0), color0_full, "M13V2-010 scale exclusion did not mutate cached membership")

	# --- detached get_color_ids result cannot mutate internal truth ---
	var keys = bix.get_color_ids()
	keys.clear()
	_check_eq(bix.get_color_ids().size(), 5, "M13V2 detached get_color_ids: mutating result does not clear internal keys")

## 3481-cell build/rebuild + repeated-query benchmark. CPU/index evidence only
## (AL-003) — no FPS/GPU claim, no hardware-specific pass/fail threshold. The
## behavioral gate is M13-21/M13-23 above; these numbers are informational.
func _run_eligible_target_index_benchmark() -> void:
	var cells := PackedInt32Array()
	cells.resize(3481)
	for i in 3481:
		cells[i] = i % 5
	var board = _make_colored_board(59, 59, Array(cells))

	var build_iters := 50
	var t0 := Time.get_ticks_usec()
	var idx
	for i in build_iters:
		idx = EligibleTargetIndex.create()
		idx.bind(board)
	var t1 := Time.get_ticks_usec()

	var rebuild_iters := 50
	for i in rebuild_iters:
		idx.rebuild()
	var t2 := Time.get_ticks_usec()

	# Repeated steady-state color queries — the case the index exists to speed up.
	var query_iters := 5000
	var sink := 0
	for i in query_iters:
		sink += idx.get_eligible(i % 5).size()
	var t3 := Time.get_ticks_usec()

	# Naive full-scan baseline (benchmark harness only, NOT production code):
	# what a per-query full board rescan would cost for the same queries.
	var naive_sink := 0
	for i in query_iters:
		var color := i % 5
		var c := 0
		for j in board.get_cell_count():
			if board.get_cell_state(j) == BoardState.CellState.DIRTY and board.get_color_id(j) == color:
				c += 1
		naive_sink += c
	var t4 := Time.get_ticks_usec()

	print("---- M13 EligibleTargetIndex benchmark (59x59 = 3481 cells) ----")
	print("  bind/build x%d: %.3f ms total, %.4f ms/build" % [build_iters, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / build_iters])
	print("  rebuild x%d: %.3f ms total, %.4f ms/rebuild" % [rebuild_iters, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / rebuild_iters])
	print("  indexed get_eligible x%d: %.3f ms total, %.5f ms/query" % [query_iters, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / query_iters])
	print("  naive full-scan baseline x%d: %.3f ms total, %.5f ms/query" % [query_iters, (t4 - t3) / 1000.0, (t4 - t3) / 1000.0 / query_iters])
	print("  (CPU/index timing only — not an FPS/GPU claim; informational, no hardware threshold)")
	print("  (query sink=%d naive sink=%d — must match, prevents dead-code elimination)" % [sink, naive_sink])
	_check_eq(sink, naive_sink, "M13 benchmark indexed and naive query results agree (correctness under load)")

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
