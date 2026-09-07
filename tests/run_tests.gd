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
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const LevelBatchImporter = preload("res://scripts/tools/level_batch_importer.gd")
const GameplaySession = preload("res://scripts/gameplay/session/gameplay_session.gd")
const SlotState = preload("res://scripts/gameplay/slots/slot_state.gd")
const SlotSystem = preload("res://scripts/gameplay/slots/slot_system.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const AccessQueryDouble = preload("res://tests/support/access_query_double.gd")
const CandidateIndexDouble = preload("res://tests/support/candidate_index_double.gd")
# M16 — RoutingSystem interface / route contract.
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const RoutingSystem = preload("res://scripts/gameplay/routing/routing_system.gd")
const RouteDebugOverlay = preload("res://scripts/debug/route_debug_overlay.gd")
const RouteAccessQueryDouble = preload("res://tests/support/route_access_query_double.gd")
const RouteNonBoolAccessQueryDouble = preload("res://tests/support/route_nonbool_access_double.gd")
const PartialBoardDouble = preload("res://tests/support/partial_board_double.gd")
const RouteFakeStraight = preload("res://tests/support/route_fake_straight.gd")
const RouteFakeRelay = preload("res://tests/support/route_fake_relay.gd")
# M17 — EXPERIMENTAL routing prototype lab.
const PrototypeAccessQuery = preload("res://scripts/gameplay/routing/prototypes/prototype_access_query.gd")
const DirectRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/direct_route_prototype.gd")
const GridRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/grid_route_prototype.gd")
const OrganizedRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/organized_route_prototype.gd")
const RouteMetrics = preload("res://scripts/gameplay/routing/prototypes/route_metrics.gd")
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")
# M17-C002 — owner-selected PRODUCTION routing (Organized/curved + grid backbone).
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
# M18 — lightweight Scrubbot agent (consumes a finished route; no selection/routing).
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
# M19 — Scrubbot dispatcher (orchestration: select+reserve -> route -> spawn one).
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const DispatchResult = preload("res://scripts/gameplay/dispatch/dispatch_result.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const DispatchRoutingDouble = preload("res://tests/support/dispatch_routing_double.gd")

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
	_run_board_renderer_active_cleared_tests()
	_run_board_renderer_real_fixture_tests()
	_run_board_renderer_canvas_embed_tests()
	_run_debug_scene_fixture_change_smoke()
	_run_board_renderer_geometry_tests()
	_run_board_renderer_pixel_tests()
	_run_board_renderer_performance_sanity()
	_run_importer_tests()
	_run_batch_importer_tests()
	_run_gameplay_session_tests()
	_run_slot_system_tests()
	_run_color_candidate_index_tests()
	_run_color_candidate_index_benchmark()
	_run_reservation_state_tests()
	_run_reservation_state_integration_tests()
	_run_reservation_state_performance()
	_run_target_selector_tests()
	_run_target_selector_simultaneous_tests()
	_run_target_selector_strict_v02_tests()
	_run_target_selector_benchmark()
	_run_route_request_tests()
	_run_route_result_tests()
	_run_route_validator_tests()
	_run_routing_system_swappability_tests()
	_run_routing_no_retarget_tests()
	_run_route_debug_overlay_tests()
	_run_route_coordinate_scale_tests()
	# M17 — routing prototype lab.
	_run_m17_prototype_contract_tests()
	_run_m17_direct_tests()
	_run_m17_grid_tests()
	_run_m17_organized_tests()
	_run_m17_metrics_tests()
	_run_m17_scale_tests()
	_run_m17_lab_scene_smoke()
	# M17-C002 — production routing promotion.
	_run_m17c002_production_routing_tests()
	# M18 — lightweight Scrubbot agent.
	_run_m18_agent_tests()
	_run_m18_agent_lifecycle_reentry_tests()
	_run_m18_multisegment_movement_tests()
	_run_m18_agent_stress_tests()
	_run_m18_agent_debug_scene_smoke()
	# M19 — dispatcher orchestration.
	_run_m19_dispatcher_tests()
	_run_m19_dispatcher_production_tests()
	_run_m19_dispatcher_stress_tests()
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
	_check_eq(board.count_cells_by_state(BoardState.CellState.ACTIVE), 20, "new board fully ACTIVE")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 0, "new board has no CLEARED cells")

	var target_index = board.get_cell_index(2, 2)
	var mutate_ok = board.set_cell_state(target_index, BoardState.CellState.CLEARED)
	_check(mutate_ok, "valid mutation reports success")
	_check_eq(board.get_cell_state(target_index), BoardState.CellState.CLEARED, "mutated cell reads back CLEARED")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 1, "exactly one CLEARED cell after single mutation")
	_check_eq(board.count_cells_by_state(BoardState.CellState.ACTIVE), 19, "remaining cells still ACTIVE")

	var neighbor_index = board.get_cell_index(3, 2)
	_check_eq(board.get_cell_state(neighbor_index), BoardState.CellState.ACTIVE, "cleaning one cell does not affect neighbor")

	var invalid_mutate = board.set_cell_state(-1, BoardState.CellState.CLEARED)
	_check_eq(invalid_mutate, false, "invalid mutation fails safely")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 1, "failed mutation does not change counts")

func _run_independence_tests() -> void:
	var level := _load_fixture("res://data/levels/test_40x40.json")
	if level == null:
		return
	var board_a := BoardState.from_level_data(level)
	var board_b := BoardState.from_level_data(level)
	board_a.set_cell_state(0, BoardState.CellState.CLEARED)
	_check_eq(board_a.get_cell_state(0), BoardState.CellState.CLEARED, "board A mutated as expected")
	_check_eq(board_b.get_cell_state(0), BoardState.CellState.ACTIVE, "board B unaffected by board A mutation (no shared state)")

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

	var mutate_ok = board.set_cell_state(board.get_cell_index(29, 29), BoardState.CellState.CLEARED)
	_check(mutate_ok, "59x59 center-cell mutation succeeds")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 1, "59x59 exactly one CLEARED cell after single mutation")
	_check_eq(board.count_cells_by_state(BoardState.CellState.ACTIVE), 3480, "59x59 remaining 3480 cells still ACTIVE")

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

	var active_count := 0
	for i in iterations:
		active_count = board.count_cells_by_state(BoardState.CellState.ACTIVE)
	var t3 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		var pos = board.get_cell_position(i)
		board.get_cell_index(pos.x, pos.y)
	var t4 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEARED)
	var t5 := Time.get_ticks_usec()

	_check_eq(board.get_cell_count(), 2500, "performance sanity operates on 50x50 (2500 cells)")
	_check_eq(active_count, 2500, "performance sanity read ACTIVE count before mutation pass")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 2500, "bulk mutation cleaned all cells")

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

	var active_count := 0
	for i in iterations:
		active_count = board.count_cells_by_state(BoardState.CellState.ACTIVE)
	var t3 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		var pos = board.get_cell_position(i)
		board.get_cell_index(pos.x, pos.y)
	var t4 := Time.get_ticks_usec()

	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEARED)
	var t5 := Time.get_ticks_usec()

	_check_eq(board.get_cell_count(), 3481, "performance sanity operates on 59x59 (3481 cells, current maximum)")
	_check_eq(active_count, 3481, "performance sanity read ACTIVE count before mutation pass")
	_check_eq(board.count_cells_by_state(BoardState.CellState.CLEARED), 3481, "bulk mutation cleaned all cells")

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

## ACTIVE/CLEARED renderer color law (ADR-012, owner decision META-C004),
## replacing the removed A/B/C dirty-preset transform tests. Proves the
## renderer draws ACTIVE cells as the exact source palette color (opaque) and
## CLEARED cells as fully transparent (alpha 0) — never a black/gray/palette
## substitute — directly from rendered pixel readback (AL-002/AL-018).
func _run_board_renderer_active_cleared_tests() -> void:
	# 5x1 board, one ACTIVE cell per fixture palette hue + a CLEARED probe.
	var palette := PackedStringArray(["#E5484D", "#3B82F6", "#22C55E", "#F5C518", "#A855F7"])
	var cells := PackedInt32Array([0, 1, 2, 3, 4])
	var level := LevelData.new(1, "active_cleared_test", "t", "TEST", 5, 1, palette, cells)
	var board := BoardState.from_level_data(level)

	var renderer = BoardRenderer.new()
	renderer.configure(board, palette, Vector2(500, 100))

	# All cells start ACTIVE -> each renders its own source palette color, opaque.
	for i in 5:
		var src := Color.html(palette[i])
		var px := renderer.get_pixel_color(i, 0)
		_check(_colors_close(px, src, 0.01), "ACTIVE cell %d renders exact source palette color (within 8-bit quantization)" % i)
		_check(absf(px.a - 1.0) <= 0.01, "ACTIVE cell %d is opaque (alpha == 1)" % i)

	# Clear cell 2; it must become fully transparent, NOT black/gray/palette.
	board.set_cell_state(2, BoardState.CellState.CLEARED)
	renderer.update_cells([2])
	var cleared_px := renderer.get_pixel_color(2, 0)
	_check(absf(cleared_px.a - 0.0) <= 0.01, "CLEARED cell alpha is zero (transparent hole)")
	_check(not _colors_close(cleared_px, Color(0, 0, 0, 1), 0.01), "CLEARED pixel is not opaque black")
	_check(not _colors_close(cleared_px, Color(0.5, 0.5, 0.5, 1), 0.01), "CLEARED pixel is not opaque gray")
	_check(not _colors_close(cleared_px, Color.html(palette[2]), 0.01), "CLEARED pixel is not the (opaque) source palette color")

	# Neighbors stay ACTIVE + opaque source color (clearing is isolated).
	_check(_colors_close(renderer.get_pixel_color(1, 0), Color.html(palette[1]), 0.01), "neighbor cell 1 still ACTIVE source color after clearing cell 2")
	_check(absf(renderer.get_pixel_color(1, 0).a - 1.0) <= 0.01, "neighbor cell 1 still opaque")

	renderer.free()

## M10-C001: owner-authorized Real Artwork debug fixtures are loaded DIRECTLY
## from data/debug/board_renderer_fixtures/*.json (no OCR/regeneration) and
## validated against their own declared metadata; VOID stays background under
## every state pattern; ACTIVE/CLEARED semantics hold; palette subsets are
## legal ascending C01..C16. These are TEST/debug/manual-QA fixtures only.
func _run_board_renderer_real_fixture_tests() -> void:
	print("---- M10-C001: Real Artwork debug fixtures ----")
	var suffix_hex := BoardDebugFixtures.load_global_palette_hex_by_suffix()
	# M10-C001 V06: canonical palette is now v2 = 16 colors (C16 Pure Black).
	_check(suffix_hex.size() == 16, "global palette v2 exposes 16 C-IDs (got %d)" % suffix_hex.size())
	_check(str(suffix_hex.get(6, "")).to_lower() == "#42c7d9", "C06 maps to Cyan #42C7D9 (Level 010 blue recolor source)")
	_check(str(suffix_hex.get(16, "")).to_lower() == "#000000", "C16 is Pure Black #000000 (V06 owner-locked addition)")
	_check(not suffix_hex.has(17), "no C17 in canonical palette (16-color legality)")

	# C01..C15 values are unchanged from historical palette v1 (v2 only appends C16).
	var v1 = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v1.json"))
	var v1_hex := {}
	if typeof(v1) == TYPE_DICTIONARY and v1.has("colors"):
		for c in v1.colors:
			v1_hex[str(c.get("id", ""))] = str(c.get("hex", "")).to_lower()
	_check(v1_hex.size() == 15, "historical palette v1 preserved with 15 colors (got %d)" % v1_hex.size())
	for n in range(1, 16):
		var cid := "C%02d" % n
		_check(v1_hex.get(cid, "") == str(suffix_hex.get(n, "")).to_lower(), "%s unchanged between palette v1 and v2" % cid)

	var fixtures := [
		"res://data/debug/board_renderer_fixtures/level_007.json",
		"res://data/debug/board_renderer_fixtures/level_010.json",
		"res://data/debug/board_renderer_fixtures/level_013.json",
	]
	for path in fixtures:
		# Independently re-parse the JSON so the test compares the loader's
		# LevelData/mask against the raw file, not against itself.
		var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
		_check(typeof(raw) == TYPE_DICTIONARY, "%s parses as JSON object" % path)
		var loaded: Dictionary = BoardDebugFixtures.load_real_fixture(path)
		_check(loaded.ok, "%s loads: %s" % [path, loaded.get("error", "")])
		if not loaded.ok:
			continue
		var level = loaded.level
		var w: int = int(raw.width)
		var h: int = int(raw.height)
		_check_eq(level.width, w, "%s width matches JSON" % path)
		_check_eq(level.height, h, "%s height matches JSON" % path)
		_check_eq(level.get_cell_count(), w * h, "%s cell count == w*h" % path)
		_check_eq(loaded.void_mask.size(), w * h, "%s void_mask sized to grid" % path)

		# Palette subset: ascending, legal C01..C16, matches JSON subset.
		var subset_ids: Array = loaded.palette_subset_ids
		var ascending := true
		for k in range(1, subset_ids.size()):
			if String(subset_ids[k]) <= String(subset_ids[k - 1]):
				ascending = false
		_check(ascending, "%s palette subset is ascending C-ID" % path)
		for id_str in subset_ids:
			var suffix := int(String(id_str).substr(1))
			_check(suffix >= 1 and suffix <= 16, "%s subset id %s is legal C01..C16" % [path, id_str])
		_check_eq(level.palette.size(), subset_ids.size(), "%s LevelData palette size == subset size" % path)

		# VOID count and artwork count vs JSON.
		var void_cells := 0
		for m in loaded.void_mask:
			if m == 1:
				void_cells += 1
		_check_eq(void_cells, int(raw.void_count), "%s VOID count matches JSON" % path)
		_check_eq(w * h - void_cells, int(raw.artwork_cell_count), "%s artwork cell count matches JSON" % path)

		# Per-color counts: recount artwork cells by mapped subset color and
		# compare to JSON color_counts (keyed by C-ID).
		var counts_by_cid: Dictionary = {}
		var board_pre = BoardState.from_level_data(level)
		for i in level.get_cell_count():
			if loaded.void_mask[i] == 1:
				continue
			var cid: String = String(subset_ids[board_pre.get_color_id(i)])
			counts_by_cid[cid] = int(counts_by_cid.get(cid, 0)) + 1
		var json_counts: Dictionary = raw.color_counts
		_check_eq(counts_by_cid.size(), json_counts.size(), "%s number of used colors matches JSON" % path)
		for cid in json_counts:
			_check_eq(int(counts_by_cid.get(cid, -1)), int(json_counts[cid]), "%s count for %s matches JSON" % [path, cid])

		# BG01 is #202533 and is NOT a logical cell palette color.
		_check(loaded.background_hex.to_lower() == "#202533", "%s background is BG01 #202533" % path)
		for hex in level.palette:
			_check(String(hex).to_lower() != "#202533", "%s BG01 is never inserted into the logical palette" % path)

		# ALL ACTIVE: every artwork cell ACTIVE, every VOID cell CLEARED.
		var board = BoardState.from_level_data(level)
		BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.ALL_ACTIVE, loaded.void_mask)
		var active_ct := 0
		var void_active := 0
		for i in board.get_cell_count():
			var st: int = board.get_cell_state(i)
			if loaded.void_mask[i] == 1:
				if st == BoardState.CellState.ACTIVE:
					void_active += 1
			elif st == BoardState.CellState.ACTIVE:
				active_ct += 1
		_check_eq(active_ct, int(raw.artwork_cell_count), "%s ALL_ACTIVE activates exactly the artwork cells" % path)
		_check_eq(void_active, 0, "%s ALL_ACTIVE never activates a VOID cell" % path)

		# ALL CLEARED: no cell ACTIVE (artwork transparent, VOID still background).
		BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.ALL_CLEARED, loaded.void_mask)
		var any_active := false
		for i in board.get_cell_count():
			if board.get_cell_state(i) == BoardState.CellState.ACTIVE:
				any_active = true
				break
		_check(not any_active, "%s ALL_CLEARED leaves no ACTIVE cell" % path)

		# CHECKER: VOID cells must STILL never become ACTIVE.
		BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.CHECKER, loaded.void_mask)
		var checker_void_active := 0
		for i in board.get_cell_count():
			if loaded.void_mask[i] == 1 and board.get_cell_state(i) == BoardState.CellState.ACTIVE:
				checker_void_active += 1
		_check_eq(checker_void_active, 0, "%s VOID never colored under CHECKER pattern" % path)

		# Renderer draws it with zero child Nodes (no per-cell architecture).
		var renderer = BoardRenderer.new()
		renderer.configure(board, level.palette, Vector2(1080, 1080))
		_check_eq(renderer.get_child_count(), 0, "%s BoardRenderer has zero child Nodes" % path)
		renderer.free()

	# Level 010 specifically preserves the owner blue-family recolor.
	var l010: Dictionary = BoardDebugFixtures.load_real_fixture("res://data/debug/board_renderer_fixtures/level_010.json")
	if l010.ok:
		for cid in ["C06", "C07", "C08"]:
			_check(l010.palette_subset_ids.has(cid), "Level 010 subset includes blue-family %s" % cid)
		_check(not l010.palette_subset_ids.has("C04"), "Level 010 no longer uses green C04 (recolored to blues)")
	print("  M10-C001 real-artwork fixture tests complete")

## M10-C001 V05: Real Artwork source matrices are IMMUTABLE bounding matrices,
## embedded (centered, VOID-padded) into a selected debug canvas. The source is
## never scaled/cropped/resampled: artwork count and color mapping are
## invariant across every valid canvas; too-small canvases are rejected, not
## cropped; source + padding VOID never become ACTIVE.
func _run_board_renderer_canvas_embed_tests() -> void:
	print("---- M10-C001 V05: Real Artwork variable-canvas embedding ----")

	# fixture path -> [source_w, source_h, artwork, [ [canvas_w, canvas_h, off_x, off_y], ... ] ]
	var cases := {
		"res://data/debug/board_renderer_fixtures/level_007.json":
			[27, 24, 542, [[30, 30, 1, 3], [59, 59, 16, 17]]],
		"res://data/debug/board_renderer_fixtures/level_010.json":
			[49, 50, 2450, [[50, 50, 0, 0], [59, 59, 5, 4]]],
		"res://data/debug/board_renderer_fixtures/level_013.json":
			[28, 31, 375, [[39, 39, 5, 4], [59, 59, 15, 14]]],
	}

	for path in cases:
		var spec: Array = cases[path]
		var sw: int = spec[0]
		var sh: int = spec[1]
		var artwork: int = spec[2]
		var canvases: Array = spec[3]

		# Source JSON matrix is unchanged (re-parsed independently).
		var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
		_check_eq(int(raw.width), sw, "%s source width unchanged" % path)
		_check_eq(int(raw.height), sh, "%s source height unchanged" % path)

		var source: Dictionary = BoardDebugFixtures.load_real_fixture(path)
		_check(source.ok, "%s source loads" % path)
		_check_eq(int(source.source_width), sw, "%s source_width" % path)
		_check_eq(int(source.source_height), sh, "%s source_height" % path)
		_check_eq(int(source.artwork_cell_count), artwork, "%s source artwork count" % path)

		# Baseline per-color counts at source size, mapped C-ID -> count.
		var subset: Array = source.palette_subset_ids
		var base_counts := _count_artwork_by_cid(source.level, source.void_mask, subset)

		# Too-small canvas is rejected (never crops).
		var too_small: Dictionary = BoardDebugFixtures.embed_real_fixture_in_canvas(source, sw - 1, sh)
		_check(not too_small.ok, "%s canvas narrower than source is rejected (no crop)" % path)
		var too_small2: Dictionary = BoardDebugFixtures.embed_real_fixture_in_canvas(source, sw, sh - 1)
		_check(not too_small2.ok, "%s canvas shorter than source is rejected (no crop)" % path)

		for cv in canvases:
			var cw: int = cv[0]
			var ch: int = cv[1]
			var ox: int = cv[2]
			var oy: int = cv[3]
			var emb: Dictionary = BoardDebugFixtures.embed_real_fixture_in_canvas(source, cw, ch)
			_check(emb.ok, "%s embeds into %dx%d" % [path, cw, ch])
			if not emb.ok:
				continue
			_check_eq(emb.level.width, cw, "%s canvas width %d" % [path, cw])
			_check_eq(emb.level.height, ch, "%s canvas height %d" % [path, ch])
			_check_eq(int(emb.offset_x), ox, "%s offset_x at %dx%d" % [path, cw, ch])
			_check_eq(int(emb.offset_y), oy, "%s offset_y at %dx%d" % [path, cw, ch])
			# Artwork count invariant; debug VOID = canvas cells - artwork.
			var void_ct := 0
			for m in emb.void_mask:
				if m == 1:
					void_ct += 1
			_check_eq(cw * ch - void_ct, artwork, "%s artwork count invariant at %dx%d" % [path, cw, ch])
			_check_eq(void_ct, cw * ch - artwork, "%s debug VOID count at %dx%d" % [path, cw, ch])

			# Per-color mapping invariant across canvas sizes.
			var emb_counts := _count_artwork_by_cid(emb.level, emb.void_mask, subset)
			_check_eq(emb_counts, base_counts, "%s per-color counts invariant at %dx%d" % [path, cw, ch])

			# ALL_ACTIVE activates exactly the artwork cells; VOID never active.
			var board = BoardState.from_level_data(emb.level)
			BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.ALL_ACTIVE, emb.void_mask)
			var active_ct := 0
			var void_active := 0
			for i in board.get_cell_count():
				var st: int = board.get_cell_state(i)
				if emb.void_mask[i] == 1:
					if st == BoardState.CellState.ACTIVE:
						void_active += 1
				elif st == BoardState.CellState.ACTIVE:
					active_ct += 1
			_check_eq(active_ct, artwork, "%s ALL_ACTIVE activates only artwork at %dx%d" % [path, cw, ch])
			_check_eq(void_active, 0, "%s ALL_ACTIVE never activates VOID at %dx%d" % [path, cw, ch])

			# CHECKER never activates any VOID (source or padding).
			BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.CHECKER, emb.void_mask)
			var checker_void_active := 0
			for i in board.get_cell_count():
				if emb.void_mask[i] == 1 and board.get_cell_state(i) == BoardState.CellState.ACTIVE:
					checker_void_active += 1
			_check_eq(checker_void_active, 0, "%s CHECKER never activates VOID at %dx%d" % [path, cw, ch])

			# ALL_CLEARED activates none.
			BoardDebugFixtures.apply_pattern_masked(board, BoardDebugFixtures.StatePattern.ALL_CLEARED, emb.void_mask)
			var any_active := false
			for i in board.get_cell_count():
				if board.get_cell_state(i) == BoardState.CellState.ACTIVE:
					any_active = true
					break
			_check(not any_active, "%s ALL_CLEARED activates none at %dx%d" % [path, cw, ch])

			# BG01 + no per-cell Nodes.
			_check(emb.background_hex.to_lower() == "#202533", "%s BG01 #202533 at %dx%d" % [path, cw, ch])
			var renderer = BoardRenderer.new()
			renderer.configure(board, emb.level.palette, Vector2(1080, 1080))
			_check_eq(renderer.get_child_count(), 0, "%s zero child Nodes at %dx%d" % [path, cw, ch])
			renderer.free()

	print("  M10-C001 V05 variable-canvas embedding tests complete")

## M10-C001 V07: runtime smoke that actually instantiates the debug scene and
## EXECUTES the Real Artwork fixture-change path (`_on_fixture_changed()`),
## including the Size-validity logic that previously called the nonexistent
## `OptionButton.get_item_disabled()` and crashed at runtime under Godot 4.7.1.
## Scene parsing alone did not catch it; this drives the deferred logic.
func _run_debug_scene_fixture_change_smoke() -> void:
	print("---- M10-C001 V07: debug-scene fixture-change runtime smoke ----")
	var scene = load("res://scenes/debug/board_renderer_debug.tscn")
	_check(scene != null, "V07 smoke: debug scene resource loads")
	if scene == null:
		return
	var inst = scene.instantiate() # _ready() runs _build_ui() on add_child
	_check(inst != null, "V07 smoke: debug scene instantiates")
	root.add_child(inst)
	# In a headless `-s` SceneTree, _ready() may not fire synchronously during
	# _initialize() (no processed frame). Build the UI deterministically if it
	# has not run yet — this still exercises the real _build_ui/_on_fixture_changed
	# code, just driven explicitly.
	if inst._qa_region == null:
		inst._build_ui()
	# Give the root the 1080×2160 reference viewport so _refresh() derives the
	# canonical QA region and runs the full embed/render path.
	inst.size = Vector2(1080, 2160)

	# Real Artwork fixture indices in FIXTURE_OPTIONS: 1=007, 2=010, 3=013.
	# Selecting + driving _on_fixture_changed() executes the exact API path that
	# threw 'Nonexistent function get_item_disabled' before this fix.
	inst._fixture_option.select(1) # Level 007 (source 27x24)
	inst._on_fixture_changed()
	# Size-validity logic ran without a runtime error and a valid size is active.
	_check(inst._size_option.selected >= 0, "V07 smoke: 007 fixture-change selected a valid size")
	_check(not inst._size_option.is_item_disabled(inst._size_option.selected), "V07 smoke: selected size is enabled (contains source)")
	# 007 source 27x24: 20x20 (idx0) too small -> disabled; 30x30 (idx3) and
	# 59x59 (idx10) valid.
	_check(inst._size_option.is_item_disabled(0), "V07 smoke: 20x20 disabled for 007 (too small)")
	_check(not inst._size_option.is_item_disabled(3), "V07 smoke: 30x30 valid for 007")
	_check(not inst._size_option.is_item_disabled(10), "V07 smoke: 59x59 valid for 007")
	# Drive the two owner-checked canvases explicitly through the change path.
	inst._size_option.select(3) # 30x30
	inst._refresh()
	_check(inst._info_label.text.find("source=27x24") >= 0, "V07 smoke: 007 renders source 27x24 (30x30 canvas) without error")
	_check(inst._info_label.text.find("canvas=30x30") >= 0, "V07 smoke: 007 canvas is 30x30")
	_check(inst._renderer.get_child_count() == 0, "V07 smoke: no per-cell Nodes at 30x30")
	# V08: board fits inside the canonical QA region (available_size = QA size),
	# centered, board pixels never exceeding the QA rect.
	var qa: Rect2 = inst.qa_region_rect(Vector2(1080, 2160))
	# Canonical rect at the 1080×2160 reference resolves to ≈ x=16,y=213,w=1028,h=1147.
	_check(absf(qa.position.x - 16) <= 1.0, "V08: QA x ≈ 16 at 1080x2160 (got %.0f)" % qa.position.x)
	_check(absf(qa.position.y - 213) <= 1.0, "V08: QA y ≈ 213 at 1080x2160 (got %.0f)" % qa.position.y)
	_check(absf(qa.size.x - 1028) <= 1.0, "V08: QA w ≈ 1028 at 1080x2160 (got %.0f)" % qa.size.x)
	_check(absf(qa.size.y - 1147) <= 1.0, "V08: QA h ≈ 1147 at 1080x2160 (got %.0f)" % qa.size.y)
	# Region derives from owner normalized ratios (13/887,175/1774,844/887,942/1774);
	# the resolved rect above proves those ratios.
	_check(absf(inst._qa_region.size.x - qa.size.x) <= 1.0 and absf(inst._qa_region.size.y - qa.size.y) <= 1.0, "V08 smoke: QA region sized to canonical rect")
	var bpx: Vector2 = inst._renderer.get_board_pixel_size()
	_check(bpx.x <= inst._qa_region.size.x + 0.5 and bpx.y <= inst._qa_region.size.y + 0.5, "V08 smoke: 30x30 board fits inside QA region")
	inst._size_option.select(10) # 59x59
	inst._refresh()
	_check(inst._info_label.text.find("canvas=59x59") >= 0, "V07 smoke: 007 canvas is 59x59")
	_check(inst._info_label.text.find("QA=1028x1147") >= 0, "V08 smoke: info reports canonical QA region 1028x1147")
	_check(inst._renderer.get_child_count() == 0, "V07 smoke: no per-cell Nodes at 59x59")
	var bpx59: Vector2 = inst._renderer.get_board_pixel_size()
	_check(bpx59.x <= inst._qa_region.size.x + 0.5 and bpx59.y <= inst._qa_region.size.y + 0.5, "V08 smoke: 59x59 board fits inside QA region")

	# Switching to a taller fixture recomputes validity (013 source 28x31 needs
	# height >= 31, so 30x30 becomes invalid).
	inst._fixture_option.select(3) # Level 013 (source 28x31)
	inst._on_fixture_changed()
	_check(inst._size_option.is_item_disabled(3), "V07 smoke: 30x30 disabled for 013 (height 31 > 30)")
	_check(not inst._size_option.is_item_disabled(inst._size_option.selected), "V07 smoke: 013 snapped to a valid size")

	# Synthetic Stripes re-enables all sizes.
	inst._fixture_option.select(0)
	inst._on_fixture_changed()
	_check(not inst._size_option.is_item_disabled(0), "V07 smoke: Synthetic Stripes re-enables 20x20")

	inst.free()
	print("  M10-C001 V07 fixture-change runtime smoke complete")

## Counts artwork cells (void_mask==0) grouped by mapped C-ID string, using the
## level's subset-index color ids.
func _count_artwork_by_cid(level, void_mask, subset: Array) -> Dictionary:
	var out: Dictionary = {}
	var board = BoardState.from_level_data(level)
	for i in level.get_cell_count():
		if void_mask[i] == 1:
			continue
		var cid: String = String(subset[board.get_color_id(i)])
		out[cid] = int(out.get(cid, 0)) + 1
	return out

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
	# 2x1 board, both cells the same palette color id; both start ACTIVE.
	var palette := PackedStringArray(["#3B82F6"])
	var cells := PackedInt32Array([0, 0])
	var level := LevelData.new(1, "renderer_pixel_test", "t", "TEST", 2, 1, palette, cells)
	var board := BoardState.from_level_data(level)

	var states_before: Array = [board.get_cell_state(0), board.get_cell_state(1)]

	var renderer = BoardRenderer.new()
	renderer.configure(board, palette, Vector2(200, 200))

	var base_color := Color.html("#3B82F6")

	# Renderer output is read back through an 8-bit-per-channel Image, so it
	# necessarily differs slightly (quantization, ~1/255 per channel) from an
	# independently-computed float Color — comparing to a precomputed exact
	# value would be the brittle float-equality test the test strategy warns
	# against (docs/06_TEST_STRATEGY.md). Test the meaningful contract instead:
	# ACTIVE renders the source color opaque; CLEARED renders alpha 0.
	var active0 := renderer.get_pixel_color(0, 0)
	var active1 := renderer.get_pixel_color(1, 0)
	_check(_colors_close(active0, base_color, 0.01), "ACTIVE cell renders the original source palette color, unmodified (within 8-bit quantization)")
	_check(absf(active0.a - 1.0) <= 0.01, "ACTIVE cell is opaque")
	_check(_colors_close(active1, active0, 0.01), "both ACTIVE cells of the same source color render identically")

	# update_cells(): clear cell 1 without a full refresh_all().
	board.set_cell_state(1, BoardState.CellState.CLEARED)
	renderer.update_cells([1])
	var cleared1 := renderer.get_pixel_color(1, 0)
	_check(absf(cleared1.a - 0.0) <= 0.01, "update_cells() makes the CLEARED cell transparent (alpha 0) without a full rebuild")
	_check(not _colors_close(cleared1, active0, 0.01), "CLEARED pixel differs from the ACTIVE source color")
	# cell 0 still ACTIVE, unchanged.
	_check(_colors_close(renderer.get_pixel_color(0, 0), base_color, 0.01), "untouched ACTIVE cell 0 still renders its source color")

	var states_after: Array = [board.get_cell_state(0), board.get_cell_state(1)]
	_check_eq(states_after, [BoardState.CellState.ACTIVE, BoardState.CellState.CLEARED], "BoardState reflects the test's own mutation (sanity)")
	_check(states_before[0] == BoardState.CellState.ACTIVE, "BoardRenderer.configure()/refresh_all() did not mutate BoardState (cell 0 unchanged)")
	_check(states_before[1] == BoardState.CellState.ACTIVE, "fresh board cell 1 started ACTIVE (renderer never mutated it)")

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
	s9.get_board_state().set_cell_state(0, BoardState.CellState.CLEARED)
	_check_eq(ld9.cells, cells_before, "M11-09: LevelData cells unchanged after BoardState mutation")
	_check_eq(ld9.width, 3, "M11-09: LevelData width unchanged")

	# ==== 10. Reset creates fresh BoardState ====
	var s10 := GameplaySession.new()
	s10.load_level(path_3x2)
	s10.start()
	var bs10_pre = s10.get_board_state()
	s10.get_board_state().set_cell_state(0, BoardState.CellState.CLEARED)
	s10.reset()
	_check(s10.get_board_state() != bs10_pre, "M11-10: reset creates new BoardState object (not same reference)")

	# ==== 11. Reset restores all cells ACTIVE ====
	_check_eq(s10.get_board_state().get_cell_state(0), BoardState.CellState.ACTIVE, "M11-11: cell 0 ACTIVE after reset")
	var all_active := true
	for i in s10.get_board_state().get_cell_count():
		if s10.get_board_state().get_cell_state(i) != BoardState.CellState.ACTIVE:
			all_active = false
			break
	_check(all_active, "M11-11: all cells ACTIVE after reset")

	# ==== 12. Reset preserves dimensions/color IDs ====
	_check_eq(s10.get_board_state().get_width(), 3, "M11-12: width preserved after reset")
	_check_eq(s10.get_board_state().get_height(), 2, "M11-12: height preserved after reset")
	_check_eq(s10.get_board_state().get_cell_count(), 6, "M11-12: cell_count preserved after reset")

	# ==== 13. Independent sessions don't share mutable BoardState ====
	var sa := GameplaySession.new()
	var sb := GameplaySession.new()
	sa.load_level(path_3x2)
	sb.load_level(path_3x2)
	sa.get_board_state().set_cell_state(0, BoardState.CellState.CLEARED)
	_check_eq(sb.get_board_state().get_cell_state(0), BoardState.CellState.ACTIVE, "M11-13: independent sessions don't share BoardState")

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
		s21.get_board_state().set_cell_state(i, BoardState.CellState.CLEARED)
	_check_eq(s21.get_board_state().count_cells_by_state(BoardState.CellState.ACTIVE), 0, "M11-21: all cells are CLEARED")
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
	var px23_before := renderer.get_pixel_color(0, 0)
	_check(_colors_close(px23_before, base23, 0.01), "M11-23: pixel (0,0) shows ACTIVE source palette color before clearing")
	_check(absf(px23_before.a - 1.0) <= 0.01, "M11-23: ACTIVE pixel (0,0) is opaque before clearing")
	s22.get_board_state().set_cell_state(0, BoardState.CellState.CLEARED)
	renderer.update_cells([0])
	var px23_after := renderer.get_pixel_color(0, 0)
	_check(absf(px23_after.a - 0.0) <= 0.01, "M11-23: pixel (0,0) is transparent (alpha 0) after clearing via session BoardState")
	_check(not _colors_close(px23_before, px23_after, 0.01), "M11-23: ACTIVE and CLEARED pixels differ — renderer reads session-owned BoardState")

	# 24. Reset: renderer follows NEW BoardState, not stale old one (F-M11-001)
	s22.start()
	var old_board24 = s22.get_board_state()
	s22.reset()
	var new_board24 = s22.get_board_state()
	_check_eq(s22.get_state(), GameplaySession.State.READY, "M11-24: READY after reset")
	_check(old_board24 != new_board24, "M11-24: reset created a different BoardState object")
	_check_eq(new_board24.get_cell_state(0), BoardState.CellState.ACTIVE, "M11-24: new board cell 0 is ACTIVE")
	# Clear cell 0 on the STALE old board; the renderer must ignore it and
	# follow the session's NEW all-ACTIVE board.
	old_board24.set_cell_state(0, BoardState.CellState.CLEARED)
	renderer.update_cells([0])
	var px24 := renderer.get_pixel_color(0, 0)
	_check(_colors_close(px24, base23, 0.01), "M11-24: pixel follows NEW BoardState (ACTIVE source color), not stale old (CLEARED)")
	_check(absf(px24.a - 1.0) <= 0.01, "M11-24: pixel is opaque — NOT the transparent CLEARED cell from stale old BoardState")

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
	# M16-C001 supersedes the original M11-era "no routing implementation" guard:
	# M16 legitimately introduces the RoutingSystem CONTRACT (interface only, no
	# M17 path algorithm). Assert the contract file now exists rather than absent.
	_check(FileAccess.file_exists("res://scripts/gameplay/routing/routing_system.gd"), "M16-C001: RoutingSystem contract now exists (supersedes M11-27 routing guard)")
	# M18-C001 supersedes the original M11-era "no agents directory" guard: M18
	# legitimately introduces the lightweight ScrubbotAgent (movement only — it
	# consumes a finished route, selects/reserves/routes nothing). Assert the
	# agent file now exists rather than absent.
	_check(FileAccess.file_exists("res://scripts/gameplay/agents/scrubbot_agent.gd"), "M18-C001: ScrubbotAgent now exists (supersedes M11-27 agent guard)")
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

## ------------------------------------------------- M13: color candidate index --

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

func _run_color_candidate_index_tests() -> void:
	print("---- M13: ColorCandidateIndex tests ----")
	var ACTIVE := BoardState.CellState.ACTIVE
	var CLEARED := BoardState.CellState.CLEARED

	# Layout (3x2, row-major indices):
	#   0:c0  1:c1  2:c0
	#   3:c1  4:c0  5:c2
	# color 0 -> [0,2,4], color 1 -> [1,3], color 2 -> [5]
	var layout := [0, 1, 0, 1, 0, 2]

	# --- T1: unbound index returns safe empty/no-candidate ---
	var idx0 = ColorCandidateIndex.create()
	_check_eq(idx0.is_bound(), false, "M13-01 fresh index is unbound")
	_check_eq(idx0.get_candidates(0), [], "M13-01 unbound get_candidates returns empty")
	_check_eq(idx0.has_candidates(0), false, "M13-01 unbound has_candidates is false")
	_check_eq(idx0.bind(null), false, "M13-01 bind(null) rejected")
	_check_eq(idx0.is_bound(), false, "M13-01 still unbound after bind(null)")

	# --- T2: initial build groups all ACTIVE cells by color ---
	var board = _make_colored_board(3, 2, layout)
	var idx = ColorCandidateIndex.create()
	_check(idx.bind(board), "M13-02 bind to board succeeds")
	_check(idx.is_bound(), "M13-02 index bound after bind")
	_check_eq(idx.get_candidates(0), [0, 2, 4], "M13-02 color 0 grouped as [0,2,4]")
	_check_eq(idx.get_candidates(1), [1, 3], "M13-02 color 1 grouped as [1,3]")
	_check_eq(idx.get_candidates(2), [5], "M13-02 color 2 grouped as [5]")

	# --- T3: queries return only the requested color ---
	for i in idx.get_candidates(0):
		_check_eq(board.get_color_id(i), 0, "M13-03 every color-0 result has color 0")
	for i in idx.get_candidates(1):
		_check_eq(board.get_color_id(i), 1, "M13-03 every color-1 result has color 1")

	# --- T4: results contain only valid indices ---
	for i in idx.get_candidates(0):
		_check(board.is_valid_index(i), "M13-04 color-0 result index %d valid" % i)

	# --- T5: CLEARED cell + sync removes it ---
	board.set_cell_state(2, CLEARED)
	_check(idx.sync_cell(2), "M13-05 sync of cleaned cell succeeds")
	_check_eq(idx.get_candidates(0), [0, 4], "M13-05 cleaned cell 2 removed from color 0")

	# --- T6: ACTIVE restoration + sync adds it back once (no duplicate) ---
	board.set_cell_state(2, ACTIVE)
	_check(idx.sync_cell(2), "M13-06 sync of re-dirtied cell succeeds")
	_check_eq(idx.get_candidates(0), [0, 2, 4], "M13-06 re-dirtied cell 2 restored in row-major order")
	# double-sync must not duplicate
	idx.sync_cell(2)
	_check_eq(idx.get_candidates(0), [0, 2, 4], "M13-06 repeated sync does not duplicate index")

	# --- T7: mutating one color does not corrupt another bucket ---
	board.set_cell_state(1, CLEARED)
	idx.sync_cell(1)
	_check_eq(idx.get_candidates(1), [3], "M13-07 color 1 loses cell 1")
	_check_eq(idx.get_candidates(0), [0, 2, 4], "M13-07 color 0 bucket unaffected")
	_check_eq(idx.get_candidates(2), [5], "M13-07 color 2 bucket unaffected")
	# restore for later tests
	board.set_cell_state(1, ACTIVE)
	idx.sync_cell(1)

	# --- T8: invalid sync index fails without corrupting state ---
	_check_eq(idx.sync_cell(-1), false, "M13-08 sync(-1) rejected")
	_check_eq(idx.sync_cell(999), false, "M13-08 sync(out-of-range) rejected")
	_check_eq(idx.get_candidates(0), [0, 2, 4], "M13-08 buckets intact after invalid sync")
	_check_eq(idx.get_candidates(1), [1, 3], "M13-08 color 1 intact after invalid sync")

	# --- T9: full rebuild after multiple changes matches board truth ---
	board.set_cell_state(0, CLEARED)
	board.set_cell_state(5, CLEARED)
	_check(idx.rebuild(), "M13-09 rebuild succeeds")
	_check_eq(idx.get_candidates(0), [2, 4], "M13-09 rebuild reflects cleaned cell 0")
	_check_eq(idx.get_candidates(2), [], "M13-09 rebuild reflects exhausted color 2")
	# color 2 exhausted -> not even a key
	_check(not idx.get_color_ids().has(2), "M13-09 exhausted color 2 has no bucket key")

	# --- T10: rebind to fresh board discards stale candidates ---
	var fresh = _make_colored_board(2, 1, [7, 7]) # indices 0,1 both color 7
	_check(idx.rebind(fresh), "M13-10 rebind to fresh board succeeds")
	_check_eq(idx.get_candidates(0), [], "M13-10 stale color 0 gone after rebind")
	_check_eq(idx.get_candidates(7), [0, 1], "M13-10 fresh board color 7 present")
	_check_eq(idx.get_color_ids().size(), 1, "M13-10 only fresh board colors present")

	# --- T11 & T12: no-candidate query present vs exhausted ---
	var board2 = _make_colored_board(3, 2, layout)
	var idx2 = ColorCandidateIndex.create()
	idx2.bind(board2)
	_check_eq(idx2.has_candidates(0), true, "M13-11 has_candidates true when color 0 has candidate cells")
	_check_eq(idx2.has_candidates(2), true, "M13-11 has_candidates true when color 2 has one cell")
	_check_eq(idx2.has_candidates(99), false, "M13-12 has_candidates false for a color with no cells")
	# exhaust color 2
	board2.set_cell_state(5, CLEARED)
	idx2.sync_cell(5)
	_check_eq(idx2.has_candidates(2), false, "M13-12 has_candidates false after color 2 exhausted")
	_check_eq(idx2.get_candidates(2), [], "M13-12 get_candidates empty after exhaustion")

	# --- T13 & T14: last-target then clean -> no-candidate ---
	# color 2 already exhausted; use a single-cell color to test last-target
	var board3 = _make_colored_board(2, 1, [3, 4])
	var idx3 = ColorCandidateIndex.create()
	idx3.bind(board3)
	_check_eq(idx3.get_candidates(3), [0], "M13-13 last-target color 3 returns exactly one candidate")
	_check_eq(idx3.has_candidates(3), true, "M13-13 has_candidates true for last target")
	board3.set_cell_state(0, CLEARED)
	idx3.sync_cell(0)
	_check_eq(idx3.has_candidates(3), false, "M13-14 cleaning last target produces no-candidate")
	_check_eq(idx3.get_candidates(3), [], "M13-14 last target gone from candidates")

	# --- T15: caller-supplied reserved/excluded target is omitted ---
	_check_eq(idx2.get_candidates(0, [2]), [0, 4], "M13-15 excluded index 2 omitted from color 0")
	_check_eq(idx2.get_candidates(0, [0, 4]), [2], "M13-15 multiple exclusions honored")

	# --- T16: reserving/excluding the only target -> no-candidate ---
	_check_eq(idx3.has_candidates(4, [1]), false, "M13-16 excluding only color-4 target yields no-candidate")
	_check_eq(idx3.get_candidates(4, [1]), [], "M13-16 excluded only target yields empty")

	# --- T17: removing exclusion re-exposes ACTIVE target w/o stored state ---
	_check_eq(idx3.get_candidates(4, []), [1], "M13-17 without exclusion the ACTIVE target is visible again")
	_check_eq(idx3.has_candidates(4), true, "M13-17 has_candidates true again once exclusion dropped")

	# --- T18: reservation filter does not mutate cached membership ---
	var before = idx2.get_candidates(0)
	idx2.get_candidates(0, [0, 2, 4]) # fully-excluded query
	idx2.has_candidates(0, [0, 2, 4])
	_check_eq(idx2.get_candidates(0), before, "M13-18 exclusion query left internal bucket unchanged")

	# --- T19: returned collection cannot mutate internal truth ---
	var leaked = idx2.get_candidates(0)
	leaked.append(99999)
	leaked.clear()
	_check_eq(idx2.get_candidates(0), [0, 2, 4], "M13-19 mutating returned array does not affect index")

	# --- T20: deterministic ordering stable across remove/re-add/rebuild ---
	var board4 = _make_colored_board(3, 3, [0, 0, 0, 0, 0, 0, 0, 0, 0]) # all color 0
	var idx4 = ColorCandidateIndex.create()
	idx4.bind(board4)
	_check_eq(idx4.get_candidates(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 initial row-major order")
	board4.set_cell_state(4, CLEARED); idx4.sync_cell(4)
	board4.set_cell_state(4, ACTIVE); idx4.sync_cell(4)
	_check_eq(idx4.get_candidates(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 order stable after remove+re-add")
	idx4.rebuild()
	_check_eq(idx4.get_candidates(0), [0, 1, 2, 3, 4, 5, 6, 7, 8], "M13-20 order stable after rebuild")

	# --- T21: 59x59 / 3481-cell correctness ---
	var big_cells := PackedInt32Array()
	big_cells.resize(3481)
	for i in 3481:
		big_cells[i] = i % 5 # 5 palette colors, deterministic spread
	var big_board = _make_colored_board(59, 59, Array(big_cells))
	var big_idx = ColorCandidateIndex.create()
	big_idx.bind(big_board)
	# independent recount from board truth
	var expected_counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	for i in 3481:
		expected_counts[i % 5] += 1
	var total_indexed := 0
	for c in 5:
		var got: int = big_idx.get_candidates(c).size()
		_check_eq(got, expected_counts[c], "M13-21 59x59 color %d count matches board truth" % c)
		total_indexed += got
	_check_eq(total_indexed, 3481, "M13-21 59x59 all 3481 ACTIVE cells indexed exactly once")
	# each bucket strictly ascending (row-major determinism at scale)
	var asc_ok := true
	for c in 5:
		var b: Array = big_idx.get_candidates(c)
		for k in range(1, b.size()):
			if b[k] <= b[k - 1]:
				asc_ok = false
				break
	_check(asc_ok, "M13-21 59x59 every bucket strictly ascending (deterministic)")
	# clean one whole color via sync, verify has_candidates flips
	for i in 3481:
		if i % 5 == 3:
			big_board.set_cell_state(i, CLEARED)
			big_idx.sync_cell(i)
	_check_eq(big_idx.has_candidates(3), false, "M13-21 59x59 color 3 no-candidate after full clean via sync")
	_check_eq(big_idx.has_candidates(0), true, "M13-21 59x59 other colors still have work")

	# --- T22: rectangular-board correctness (5x3) ---
	# indices row-major; color = 0 on even index, 1 on odd
	var rect_cells := []
	for i in 15:
		rect_cells.append(i % 2)
	var rect_board = _make_colored_board(5, 3, rect_cells)
	var rect_idx = ColorCandidateIndex.create()
	rect_idx.bind(rect_board)
	_check_eq(rect_idx.get_candidates(0), [0, 2, 4, 6, 8, 10, 12, 14], "M13-22 rectangular even indices color 0")
	_check_eq(rect_idx.get_candidates(1), [1, 3, 5, 7, 9, 11, 13], "M13-22 rectangular odd indices color 1")

	# --- T23 (F-M13-001 corrected): steady-state queries touch ZERO BoardState
	# traversal APIs. Spy counts get_cell_count / is_valid_index / get_color_id /
	# get_cell_state; build may scan, but repeated get_candidates/has_candidates/
	# count_candidates must add zero traversal reads across ALL those APIs — so a
	# future `for i in board.get_cell_count(): board.get_color_id(i)` regression
	# is caught even if it never calls get_cell_state().
	var spy = load("res://tests/support/board_state_scan_spy.gd").new()
	spy.setup([0, 1, 0, 1, 0, 2], 3, 2)
	var idx5 = ColorCandidateIndex.create()
	idx5.bind(spy) # build performs the one allowed scan
	var build_reads: int = spy.traversal_reads()
	_check(spy.count_get_cell_state >= 6, "M13-23 build scanned cell states (>= cell count)")
	_check(build_reads >= 6, "M13-23 build registered board traversal reads")

	# item 16: repeated get_candidates adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_candidates(0)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x get_candidates added zero BoardState traversal reads")

	# item 17: repeated has_candidates adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.has_candidates(1)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x has_candidates added zero BoardState traversal reads")

	# item 18: repeated count_candidates adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.count_candidates(0)
	_check_eq(spy.traversal_reads(), 0, "M13-23 200x count_candidates added zero BoardState traversal reads")

	# item 19: absent-color query adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_candidates(99)
		idx5.has_candidates(99)
		idx5.count_candidates(99)
	_check_eq(spy.traversal_reads(), 0, "M13-23 absent-color queries added zero BoardState traversal reads")

	# item 20: exclusion-filtered query adds zero traversal
	spy.reset_counters()
	for _q in 200:
		idx5.get_candidates(0, [0, 4])
		idx5.has_candidates(0, [0, 2, 4])
		idx5.count_candidates(0, [2])
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
		if spy.get_color_id(i) == 0 and spy.get_cell_state(i) == BoardState.CellState.ACTIVE:
			naive_hits += 1
	_check(spy.traversal_reads() > 0, "M13-23 sensitivity: a full-board color loop DOES move the traversal counter")
	_check_eq(naive_hits, 3, "M13-23 sensitivity: naive loop found the 3 color-0 ACTIVE cells")

	_run_m13_v02_formal_validation()
	print("  M13 ColorCandidateIndex tests complete")

## M13-C001 V02 formal validation of reopened SB-M13-006..010, filling the
## coverage gaps the V02 prompt/criteria enumerate beyond the V01 tests above.
func _run_m13_v02_formal_validation() -> void:
	var ACTIVE := BoardState.CellState.ACTIVE
	var CLEARED := BoardState.CellState.CLEARED

	# --- SB-M13-006 reservation/exclusion robustness ---
	# 3x2: color 0 -> [0,2,4], color 1 -> [1,3], color 2 -> [5]
	var b = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2])
	var ix = ColorCandidateIndex.create()
	ix.bind(b)
	# duplicate excluded indices
	_check_eq(ix.get_candidates(0, [2, 2, 2]), [0, 4], "M13V2-006 duplicate exclusion index handled once")
	# invalid negative / out-of-range exclusions have no effect
	_check_eq(ix.get_candidates(0, [-1, 999, -50]), [0, 2, 4], "M13V2-006 invalid exclusion indices ignored")
	# mix of valid + invalid
	_check_eq(ix.get_candidates(0, [-1, 2, 999]), [0, 4], "M13V2-006 mixed valid/invalid exclusion filters only valid")
	# cross-color exclusion cannot corrupt requested color
	_check_eq(ix.get_candidates(0, [1, 3, 5]), [0, 2, 4], "M13V2-006 excluding other colors' indices leaves color 0 intact")
	_check_eq(ix.get_candidates(1, [0, 4]), [1, 3], "M13V2-006 excluding color-0 indices leaves color 1 intact")
	# exclusion query does not mutate cache
	var snap = ix.get_candidates(0)
	ix.get_candidates(0, [0, 2, 4])
	ix.has_candidates(0, [0, 2, 4])
	ix.count_candidates(0, [0])
	_check_eq(ix.get_candidates(0), snap, "M13V2-006 exclusion queries did not mutate cached bucket")
	# Dictionary-like caller set supported (keys are indices)
	_check_eq(ix.get_candidates(0, {2: true, 4: true}), [0], "M13V2-006 Dictionary exclusion set supported")
	_check_eq(ix.has_candidates(0, {0: true, 2: true, 4: true}), false, "M13V2-006 Dictionary exclusion of all targets -> no work")
	# confirm no persistent reservation state: BoardState enum unchanged, no leak
	_check(not ("RESERVED" in BoardState.CellState), "M13V2-006 BoardState.CellState has no RESERVED")
	_check(not ix.has_method("reserve"), "M13V2-006 index has no reserve() ownership method")
	_check(not ix.has_method("release"), "M13V2-006 index has no release() method")

	# --- SB-M13-007 no-candidate query full matrix ---
	_check_eq(ix.has_candidates(0), true, "M13V2-007 present color has work")
	_check_eq(ix.has_candidates(99), false, "M13V2-007 absent color has no work")
	_check_eq(ix.has_candidates(0, [0, 2, 4]), false, "M13V2-007 all-excluded -> no work")
	_check_eq(ix.has_candidates(0, [0, 2]), true, "M13V2-007 partial exclusion still has work")
	var unbound = ColorCandidateIndex.create()
	_check_eq(unbound.has_candidates(0), false, "M13V2-007 unbound index reports no work")
	_check_eq(unbound.count_candidates(0), 0, "M13V2-007 unbound count is zero")

	# --- SB-M13-008 exhausted color: incremental sync AND full rebuild paths ---
	# incremental: clean color 2's only cell
	b.set_cell_state(5, CLEARED)
	ix.sync_cell(5)
	_check_eq(ix.has_candidates(2), false, "M13V2-008 incremental: exhausted color no work")
	_check_eq(ix.get_candidates(2), [], "M13V2-008 incremental: exhausted color empty")
	_check(not ix.get_color_ids().has(2), "M13V2-008 incremental: exhausted color key absent")
	# full rebuild path: clean all of color 1 in BoardState WITHOUT per-cell sync
	b.set_cell_state(1, CLEARED)
	b.set_cell_state(3, CLEARED)
	ix.rebuild()
	_check_eq(ix.has_candidates(1), false, "M13V2-008 rebuild: exhausted color 1 no work")
	_check_eq(ix.get_candidates(1), [], "M13V2-008 rebuild: exhausted color 1 empty")
	_check(not ix.get_color_ids().has(1), "M13V2-008 rebuild: exhausted color 1 key absent")
	_check_eq(ix.get_candidates(0), [0, 2, 4], "M13V2-008 rebuild: surviving color 0 intact and matches board truth")

	# --- SB-M13-009 last-target lifecycle ---
	var lb = _make_colored_board(2, 1, [3, 4])
	var lix = ColorCandidateIndex.create()
	lix.bind(lb)
	_check_eq(lix.get_candidates(3), [0], "M13V2-009 exactly one candidate for color 3")
	_check_eq(lix.has_candidates(3), true, "M13V2-009 last target has work")
	_check_eq(lix.has_candidates(3, [0]), false, "M13V2-009 excluding only target -> no work")
	_check_eq(lix.has_candidates(3, []), true, "M13V2-009 dropping exclusion re-exposes target")
	lb.set_cell_state(0, CLEARED)
	lix.sync_cell(0)
	_check_eq(lix.has_candidates(3), false, "M13V2-009 clean last target + sync -> no work")
	_check_eq(lix.get_candidates(3), [], "M13V2-009 candidate list empty after last target cleaned")

	# --- SB-M13-010 3,481-cell exclusion filter at scale + non-mutation ---
	var big_cells := PackedInt32Array()
	big_cells.resize(3481)
	for i in 3481:
		big_cells[i] = i % 5
	var bb = _make_colored_board(59, 59, Array(big_cells))
	var bix = ColorCandidateIndex.create()
	bix.bind(bb)
	var color0_full: Array = bix.get_candidates(0)
	# exclude the first 10 color-0 indices
	var excl := color0_full.slice(0, 10)
	var filtered: Array = bix.get_candidates(0, excl)
	_check_eq(filtered.size(), color0_full.size() - 10, "M13V2-010 scale exclusion removes exactly the excluded candidates")
	_check_eq(bix.get_candidates(0), color0_full, "M13V2-010 scale exclusion did not mutate cached membership")

	# --- detached get_color_ids result cannot mutate internal truth ---
	var keys = bix.get_color_ids()
	keys.clear()
	_check_eq(bix.get_color_ids().size(), 5, "M13V2 detached get_color_ids: mutating result does not clear internal keys")

## 3481-cell build/rebuild + repeated-query benchmark. CPU/index evidence only
## (AL-003) — no FPS/GPU claim, no hardware-specific pass/fail threshold. The
## behavioral gate is M13-21/M13-23 above; these numbers are informational.
func _run_color_candidate_index_benchmark() -> void:
	var cells := PackedInt32Array()
	cells.resize(3481)
	for i in 3481:
		cells[i] = i % 5
	var board = _make_colored_board(59, 59, Array(cells))

	var build_iters := 50
	var t0 := Time.get_ticks_usec()
	var idx
	for i in build_iters:
		idx = ColorCandidateIndex.create()
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
		sink += idx.get_candidates(i % 5).size()
	var t3 := Time.get_ticks_usec()

	# Naive full-scan baseline (benchmark harness only, NOT production code):
	# what a per-query full board rescan would cost for the same queries.
	var naive_sink := 0
	for i in query_iters:
		var color := i % 5
		var c := 0
		for j in board.get_cell_count():
			if board.get_cell_state(j) == BoardState.CellState.ACTIVE and board.get_color_id(j) == color:
				c += 1
		naive_sink += c
	var t4 := Time.get_ticks_usec()

	print("---- M13 ColorCandidateIndex benchmark (59x59 = 3481 cells) ----")
	print("  bind/build x%d: %.3f ms total, %.4f ms/build" % [build_iters, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / build_iters])
	print("  rebuild x%d: %.3f ms total, %.4f ms/rebuild" % [rebuild_iters, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / rebuild_iters])
	print("  indexed get_candidates x%d: %.3f ms total, %.5f ms/query" % [query_iters, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / query_iters])
	print("  naive full-scan baseline x%d: %.3f ms total, %.5f ms/query" % [query_iters, (t4 - t3) / 1000.0, (t4 - t3) / 1000.0 / query_iters])
	print("  (CPU/index timing only — not an FPS/GPU claim; informational, no hardware threshold)")
	print("  (query sink=%d naive sink=%d — must match, prevents dead-code elimination)" % [sink, naive_sink])
	_check_eq(sink, naive_sink, "M13 benchmark indexed and naive query results agree (correctness under load)")

func _run_reservation_state_tests() -> void:
	print("---- M14: ReservationState tests ----")
	var ACTIVE := BoardState.CellState.ACTIVE
	var CLEARED := BoardState.CellState.CLEARED

	# --- create/unbound rejection (criteria 2,3) ---
	var r0 = ReservationState.create()
	_check_eq(r0.is_bound(), false, "M14-01 fresh ReservationState is unbound")
	_check_eq(r0.reserve(0, 0), false, "M14-02 reserve while unbound fails")
	_check_eq(r0.bind(null), false, "M14-02 bind(null) rejected")
	_check_eq(r0.is_bound(), false, "M14-02 still unbound after bind(null)")

	# Board: 3x2, all color 0, all ACTIVE (indices 0..5).
	var board = _make_colored_board(3, 2, [0, 0, 0, 0, 0, 0])
	var r = ReservationState.create()
	_check(r.bind(board), "M14-03 bind to board succeeds")
	_check(r.is_bound(), "M14-03 bound after bind")

	# --- valid ACTIVE reserve succeeds ---
	_check(r.reserve(2, 100), "M14-04 valid ACTIVE reserve succeeds")
	_check_eq(r.is_reserved(2), true, "M14-04 target 2 now reserved")
	_check_eq(r.get_owner(2), 100, "M14-04 owner of target 2 is 100")
	_check_eq(r.get_target_for_owner(100), 2, "M14-04 owner 100 holds target 2")
	_check_eq(r.get_reservation_count(), 1, "M14-04 reservation count is 1")

	# --- invalid index / CLEARED / invalid owner ---
	_check_eq(r.reserve(-1, 101), false, "M14-05 invalid index (-1) reserve fails")
	_check_eq(r.reserve(999, 101), false, "M14-05 out-of-range index reserve fails")
	board.set_cell_state(4, CLEARED)
	_check_eq(r.reserve(4, 101), false, "M14-06 CLEARED target reserve fails")
	board.set_cell_state(4, ACTIVE) # restore
	_check_eq(r.reserve(3, -1), false, "M14-07 invalid owner (-1) reserve fails")
	_check_eq(r.get_reservation_count(), 1, "M14-07 no bad reserve mutated state")

	# --- double reservation by different owner fails ---
	_check_eq(r.reserve(2, 200), false, "M14-08 target 2 double-reserve (other owner) fails")
	_check_eq(r.get_owner(2), 100, "M14-08 target 2 still owned by 100")
	# --- same owner duplicate reserve of same target fails ---
	_check_eq(r.reserve(2, 100), false, "M14-09 same owner duplicate reserve of same target fails")
	# --- same owner cannot reserve a second target ---
	_check_eq(r.reserve(3, 100), false, "M14-10 owner 100 cannot hold a second target")
	_check_eq(r.is_reserved(3), false, "M14-10 target 3 stayed unreserved")

	# --- independent owners reserve different targets ---
	_check(r.reserve(0, 300), "M14-11 owner 300 reserves target 0")
	_check(r.reserve(5, 400), "M14-11 owner 400 reserves target 5")
	_check_eq(r.get_reservation_count(), 3, "M14-11 three independent reservations")

	# --- is_reserved / get_owner / owner->target truth (criteria) ---
	_check_eq(r.is_reserved(1), false, "M14-12 unreserved target 1 -> false")
	_check_eq(r.get_owner(1), -1, "M14-12 unreserved target owner -> -1")
	_check_eq(r.get_target_for_owner(999), -1, "M14-13 unknown owner target -> -1")

	# --- wrong-owner release fails, correct release succeeds ---
	_check_eq(r.release(0, 999), false, "M14-14 wrong-owner release fails")
	_check_eq(r.is_reserved(0), true, "M14-14 target 0 unchanged after wrong-owner release")
	_check(r.release(0, 300), "M14-15 correct owner release succeeds")
	_check_eq(r.is_reserved(0), false, "M14-15 target 0 released")
	_check_eq(r.get_target_for_owner(300), -1, "M14-15 owner 300 holds nothing after release")

	# --- released target reservable again ---
	_check(r.reserve(0, 301), "M14-16 released target 0 reservable again")
	_check_eq(r.get_owner(0), 301, "M14-16 target 0 now owned by 301")

	# --- simulated dispatch-failure lifecycle ---
	# reserve -> (dispatch fails) -> release -> reservable again
	_check(r.reserve(1, 500), "M14-17 reserve target 1 for owner 500")
	_check(r.release(1, 500), "M14-17 dispatch failed -> release target 1")
	_check_eq(r.is_reserved(1), false, "M14-17 target 1 free after dispatch-failure release")
	_check(r.reserve(1, 501), "M14-17 target 1 reservable again after failure")
	r.release(1, 501) # tidy

	# --- reset clears all, keeps binding ---
	r.reset()
	_check_eq(r.get_reservation_count(), 0, "M14-18 reset clears all reservations")
	_check(r.is_bound(), "M14-18 reset keeps board binding")
	_check_eq(r.get_reserved_indices().size(), 0, "M14-18 no reserved indices after reset")

	# --- rebind clears old-board reservations ---
	r.reserve(2, 600)
	var fresh = _make_colored_board(2, 1, [0, 0])
	_check(r.rebind(fresh), "M14-19 rebind to fresh board succeeds")
	_check_eq(r.get_reservation_count(), 0, "M14-19 rebind cleared old-board reservations")
	_check_eq(r.is_reserved(2), false, "M14-19 stale reservation gone after rebind")

	# --- arrival resolution succeeds once; wrong owner / second fail; no board mutation ---
	var board2 = _make_colored_board(3, 1, [0, 0, 0])
	var r2 = ReservationState.create()
	r2.bind(board2)
	_check(r2.reserve(1, 700), "M14-20 reserve target 1 for owner 700")
	_check_eq(r2.resolve_arrival(1, 701), false, "M14-21 wrong-owner arrival resolution fails")
	_check_eq(r2.is_reserved(1), true, "M14-21 target 1 still reserved after wrong-owner arrival")
	var state_before: int = board2.get_cell_state(1)
	_check(r2.resolve_arrival(1, 700), "M14-20 correct arrival resolution succeeds once")
	_check_eq(board2.get_cell_state(1), state_before, "M14-23 resolve_arrival did NOT mutate BoardState cell")
	_check_eq(board2.get_cell_state(1), ACTIVE, "M14-23 target 1 cell still ACTIVE after arrival")
	_check_eq(r2.is_reserved(1), false, "M14-20 reservation removed after arrival")
	_check_eq(r2.resolve_arrival(1, 700), false, "M14-22 second arrival resolution fails")

	# --- detached reserved-index output cannot mutate internal state ---
	var r3 = ReservationState.create()
	r3.bind(_make_colored_board(3, 1, [0, 0, 0]))
	r3.reserve(2, 800)
	r3.reserve(0, 801)
	var snapshot: PackedInt32Array = r3.get_reserved_indices()
	# --- deterministic ascending order ---
	_check_eq(snapshot, PackedInt32Array([0, 2]), "M14-25 reserved indices deterministic ascending")
	snapshot.append(99) # mutate the returned copy
	snapshot.remove_at(0)
	_check_eq(r3.get_reserved_indices(), PackedInt32Array([0, 2]), "M14-24 mutating returned indices does not affect internal state")
	_check_eq(r3.get_reservation_count(), 2, "M14-24 internal reservation count intact")

	# --- no BoardState.CellState.RESERVED exists (criterion 29) ---
	_check(not ("RESERVED" in BoardState.CellState.keys()), "M14-29 no BoardState.CellState.RESERVED")
	_check_eq(BoardState.CellState.keys(), ["ACTIVE", "CLEARED"], "M14-29 CellState remains exactly ACTIVE/CLEARED")

	# --- concurrency / simultaneous-assignment: many owners race one target ---
	var board3 = _make_colored_board(3, 1, [0, 0, 0])
	var r4 = ReservationState.create()
	r4.bind(board3)
	var wins := 0
	for owner in range(1000, 1050):
		if r4.reserve(1, owner):
			wins += 1
	_check_eq(wins, 1, "M14-28 exactly one owner wins a contested target")
	_check_eq(r4.get_reservation_count(), 1, "M14-28 exactly one reservation exists after the race")

	print("  M14 ReservationState tests complete")

func _run_reservation_state_integration_tests() -> void:
	print("---- M14: ReservationState <-> ColorCandidateIndex integration ----")
	# Board 3x2, all color 7, all ACTIVE. Candidates for color 7 = [0..5].
	var board = _make_colored_board(3, 2, [7, 7, 7, 7, 7, 7])
	var idx = ColorCandidateIndex.create()
	idx.bind(board)
	var res = ReservationState.create()
	res.bind(board)

	_check_eq(idx.get_candidates(7), [0, 1, 2, 3, 4, 5], "M14-int candidate baseline is full board")

	# Reserve two targets; candidate index must exclude them ONLY via caller exclusion.
	res.reserve(2, 900)
	res.reserve(4, 901)
	var reserved: PackedInt32Array = res.get_reserved_indices()
	_check_eq(reserved, PackedInt32Array([2, 4]), "M14-26 reserved indices [2,4] ascending")
	_check_eq(idx.get_candidates(7, reserved), [0, 1, 3, 5], "M14-26 reserved cells excluded via caller exclusion")
	_check_eq(idx.has_candidates(7, reserved), true, "M14-26 has_candidates true with some free cells")

	# M13 stays reservation-agnostic: WITHOUT passing exclusions the reserved
	# cells are still returned (index owns no reservation state).
	_check_eq(idx.get_candidates(7), [0, 1, 2, 3, 4, 5], "M14-28b ColorCandidateIndex owns no reservation state")

	# Release makes the ACTIVE candidate visible again.
	res.release(2, 900)
	_check_eq(idx.get_candidates(7, res.get_reserved_indices()), [0, 1, 2, 3, 5], "M14-27 released cell 2 visible again")

	print("  M14 integration tests complete")

func _run_reservation_state_performance() -> void:
	# 59x59 = 3481 cells, all ACTIVE. Reserve/query/release must not full-scan.
	var cells := PackedInt32Array()
	cells.resize(3481)
	for i in 3481:
		cells[i] = 0
	var board = _make_colored_board(59, 59, Array(cells))
	var res = ReservationState.create()
	res.bind(board)

	var reserve_count := 500
	var t0 := Time.get_ticks_usec()
	for i in reserve_count:
		res.reserve(i, i) # target index i, owner id i
	var t1 := Time.get_ticks_usec()
	_check_eq(res.get_reservation_count(), reserve_count, "M14-31 all 500 reservations stored on 3481-cell board")

	var query_iters := 5000
	var hits := 0
	for i in query_iters:
		if res.is_reserved(i % 3481):
			hits += 1
	var t2 := Time.get_ticks_usec()

	for i in reserve_count:
		res.release(i, i)
	var t3 := Time.get_ticks_usec()
	_check_eq(res.get_reservation_count(), 0, "M14-31 all reservations released on 3481-cell board")

	print("---- M14 ReservationState performance (59x59 = 3481 cells) ----")
	print("  reserve x%d: %.3f ms total, %.5f ms/reserve" % [reserve_count, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / reserve_count])
	print("  is_reserved x%d: %.3f ms total, %.6f ms/query" % [query_iters, (t2 - t1) / 1000.0, (t2 - t1) / 1000.0 / query_iters])
	print("  release x%d: %.3f ms total, %.5f ms/release" % [reserve_count, (t3 - t2) / 1000.0, (t3 - t2) / 1000.0 / reserve_count])
	print("  (O(1) dict ops; no per-call full-board scan — CPU timing only, no FPS/GPU claim)")

func _run_target_selector_tests() -> void:
	print("---- M15: TargetSelector tests ----")
	var ACTIVE := BoardState.CellState.ACTIVE
	var CLEARED := BoardState.CellState.CLEARED
	var COLOR := 5

	# --- create/bind (test 1; crit 6,7) ---
	var ts0 = TargetSelector.create()
	_check_eq(ts0.is_bound(), false, "M15-01 fresh TargetSelector is unbound")
	var b0 = _make_colored_board(3, 3, [COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR])
	var ci0 = ColorCandidateIndex.create(); ci0.bind(b0)
	var rs0 = ReservationState.create(); rs0.bind(b0)
	# --- bind rejects null deps (test 2) ---
	_check_eq(ts0.bind(null, ci0, rs0), false, "M15-02 bind(null board) rejected")
	_check_eq(ts0.bind(b0, null, rs0), false, "M15-02 bind(null candidate index) rejected")
	_check_eq(ts0.bind(b0, ci0, null), false, "M15-02 bind(null reservation state) rejected")
	_check_eq(ts0.is_bound(), false, "M15-02 still unbound after failed binds")
	# --- unbound select returns -1 (test 3) ---
	var aq0 = AccessQueryDouble.new(); aq0.default_targetable = true
	_check_eq(ts0.select_and_reserve(COLOR, 100, aq0), -1, "M15-03 unbound select returns -1")

	# Bound selector on a full 3x3 color-5 board, all targetable.
	var ts = TargetSelector.create()
	_check(ts.bind(b0, ci0, rs0), "M15-01 bind with all deps succeeds")
	_check(ts.is_bound(), "M15-01 bound after bind")
	var aq = AccessQueryDouble.new(); aq.default_targetable = true

	# --- fail closed on missing access query (test 16; crit 12) ---
	_check_eq(ts.select_and_reserve(COLOR, 100, null), -1, "M15-16 null access_query fails closed")
	_check_eq(ts.select_and_reserve(COLOR, 100, RefCounted.new()), -1, "M15-16 access_query without is_targetable() fails closed")
	_check_eq(rs0.get_reservation_count(), 0, "M15-16 fail-closed created no reservation")

	# --- invalid owner / color (tests 4,5) ---
	_check_eq(ts.select_and_reserve(COLOR, -1, aq), -1, "M15-05 invalid owner (-1) returns -1")
	_check_eq(ts.select_and_reserve(-1, 100, aq), -1, "M15-04 invalid color (-1) returns -1")
	_check_eq(rs0.get_reservation_count(), 0, "M15-21 invalid call created no reservation")

	# --- deterministic first ascending target + reservation created (tests 6,12; crit 15,26) ---
	var board_before := _snapshot_cell_states(b0)
	var sel = ts.select_and_reserve(COLOR, 100, aq)
	_check_eq(sel, 0, "M15-06 deterministic first ascending candidate (index 0) selected")
	_check_eq(rs0.is_reserved(0), true, "M15-12 reservation actually created for selected target")
	_check_eq(rs0.get_owner(0), 100, "M15-12 selected target owned by requesting owner")
	# --- selector did not mutate BoardState (test 22; crit 33) ---
	_check(_cell_states_equal(b0, board_before), "M15-22 selection did not mutate BoardState cells")

	# --- repeated identical state -> identical index (test 25) ---
	var b_det = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var ci_det = ColorCandidateIndex.create(); ci_det.bind(b_det)
	var rs_det = ReservationState.create(); rs_det.bind(b_det)
	var ts_det = TargetSelector.create(); ts_det.bind(b_det, ci_det, rs_det)
	var aq_det = AccessQueryDouble.new(); aq_det.default_targetable = true
	var first = ts_det.select_and_reserve(COLOR, 1, aq_det)
	rs_det.release_for_owner(1)
	var again = ts_det.select_and_reserve(COLOR, 1, aq_det)
	_check_eq(first, again, "M15-25 identical state produces identical selected index")
	_check_eq(first, 0, "M15-25 identical selection is deterministic first candidate")

	# --- owner already holding a target returns -1 (test 13; crit 27) ---
	_check_eq(ts.select_and_reserve(COLOR, 100, aq), -1, "M15-13 owner already holding target gets -1")

	# --- reserved candidate skipped (test 11; crit 19) ---
	var sel2 = ts.select_and_reserve(COLOR, 101, aq)
	_check_eq(sel2, 1, "M15-11 reserved target 0 skipped; next owner gets target 1")

	# --- after releasing selected reservation, same deterministic target for new owner (test 26) ---
	rs0.release_for_owner(100) # frees target 0
	var sel3 = ts.select_and_reserve(COLOR, 102, aq)
	_check_eq(sel3, 0, "M15-26 released target 0 re-selected deterministically for new owner")

	# --- access-query false candidate skipped; first blocked + later reachable selects later (tests 17,18; crit 20,22) ---
	var b_blk = _make_colored_board(4, 1, [COLOR, COLOR, COLOR, COLOR])
	var ci_blk = ColorCandidateIndex.create(); ci_blk.bind(b_blk)
	var rs_blk = ReservationState.create(); rs_blk.bind(b_blk)
	var ts_blk = TargetSelector.create(); ts_blk.bind(b_blk, ci_blk, rs_blk)
	var aq_blk = AccessQueryDouble.new()
	aq_blk.default_targetable = false
	aq_blk.set_targetable(0, false) # blocked
	aq_blk.set_targetable(1, false) # blocked
	aq_blk.set_targetable(2, true)  # reachable
	aq_blk.set_targetable(3, true)
	var sel_blk = ts_blk.select_and_reserve(COLOR, 200, aq_blk)
	_check_eq(sel_blk, 2, "M15-18 first blocked candidates skipped; first reachable (2) selected")
	# AL-018 direct observability: selector actually consulted access truth in order.
	_check_eq(aq_blk.was_queried(0), true, "M15-18 access query consulted for blocked index 0 (AL-018)")
	_check_eq(aq_blk.was_queried(1), true, "M15-18 access query consulted for blocked index 1 (AL-018)")
	_check_eq(aq_blk.was_queried(2), true, "M15-18 access query consulted for selected index 2 (AL-018)")
	_check_eq(aq_blk.was_queried(3), false, "M15-32 access query NOT called past the selected candidate (bounded iteration)")

	# --- all blocked returns -1 + fully-enclosed AL-028 regression (tests 19,20; crit 21,23) ---
	var b_enc = _make_colored_board(3, 3, [COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR, COLOR])
	var ci_enc = ColorCandidateIndex.create(); ci_enc.bind(b_enc)
	var rs_enc = ReservationState.create(); rs_enc.bind(b_enc)
	var ts_enc = TargetSelector.create(); ts_enc.bind(b_enc, ci_enc, rs_enc)
	# Access truth reports EVERY matching-color ACTIVE cell blocked/unreachable —
	# the M15 stand-in for a fully enclosed candidate with no legal access (AL-028).
	var aq_enc = AccessQueryDouble.new(); aq_enc.default_targetable = false
	_check_eq(ts_enc.select_and_reserve(COLOR, 300, aq_enc), -1, "M15-20 fully-enclosed/all-blocked matching color yields no target (AL-028)")
	_check_eq(rs_enc.get_reservation_count(), 0, "M15-19 all-blocked selection created no reservation")
	_check(aq_enc.total_queries() >= 1, "M15-20 access truth was actually consulted before giving up (AL-018)")

	# --- no candidates returns -1 (test 15; crit 24) ---
	var b_nc = _make_colored_board(2, 1, [COLOR, COLOR])
	var ci_nc = ColorCandidateIndex.create(); ci_nc.bind(b_nc)
	var rs_nc = ReservationState.create(); rs_nc.bind(b_nc)
	var ts_nc = TargetSelector.create(); ts_nc.bind(b_nc, ci_nc, rs_nc)
	var aq_nc = AccessQueryDouble.new(); aq_nc.default_targetable = true
	_check_eq(ts_nc.select_and_reserve(999, 400, aq_nc), -1, "M15-15 color with no candidates returns -1")

	# --- all candidates reserved returns -1 (test 14) ---
	var b_all = _make_colored_board(2, 1, [COLOR, COLOR])
	var ci_all = ColorCandidateIndex.create(); ci_all.bind(b_all)
	var rs_all = ReservationState.create(); rs_all.bind(b_all)
	rs_all.reserve(0, 900); rs_all.reserve(1, 901) # every candidate reserved
	var ts_all = TargetSelector.create(); ts_all.bind(b_all, ci_all, rs_all)
	var aq_all = AccessQueryDouble.new(); aq_all.default_targetable = true
	_check_eq(ts_all.select_and_reserve(COLOR, 902, aq_all), -1, "M15-14 all candidates reserved returns -1")

	# --- stale-candidate defence: wrong-color / CLEARED / invalid never selected (tests 8,9,10; crit 17,18) ---
	# Use a candidate-index DOUBLE to inject raw candidates the real index would
	# never emit, proving TargetSelector's narrow BoardState final-validation.
	var b_stale = _make_colored_board(3, 1, [COLOR, 7, COLOR]) # idx1 is color 7
	b_stale.set_cell_state(2, CLEARED)                          # idx2 CLEARED
	var rs_stale = ReservationState.create(); rs_stale.bind(b_stale)
	var cd = CandidateIndexDouble.new()
	cd.bind(b_stale) # strict-v2: pass the selector's board-coherence gate.
	# Inject: wrong-color idx1, CLEARED idx2, invalid idx99, then the only valid idx0.
	cd.set_candidates(COLOR, [1, 2, 99, 0])
	var ts_stale = TargetSelector.create(); ts_stale.bind(b_stale, cd, rs_stale)
	var aq_stale = AccessQueryDouble.new(); aq_stale.default_targetable = true
	var sel_stale = ts_stale.select_and_reserve(COLOR, 500, aq_stale)
	_check_eq(sel_stale, 0, "M15-08/09/10 stale wrong-color/CLEARED/invalid skipped; valid idx0 selected")
	_check_eq(aq_stale.was_queried(1), false, "M15-08 wrong-color candidate rejected before access query")
	_check_eq(aq_stale.was_queried(2), false, "M15-09 CLEARED candidate rejected before access query")
	_check_eq(aq_stale.was_queried(99), false, "M15-10 invalid candidate rejected before access query")

	# --- selector does not mutate ColorCandidateIndex internal truth (test 23; crit 34) ---
	var b_nm = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var ci_nm = ColorCandidateIndex.create(); ci_nm.bind(b_nm)
	var rs_nm = ReservationState.create(); rs_nm.bind(b_nm)
	var ts_nm = TargetSelector.create(); ts_nm.bind(b_nm, ci_nm, rs_nm)
	var cand_before: Array = ci_nm.get_candidates(COLOR)
	var aq_nm = AccessQueryDouble.new(); aq_nm.default_targetable = true
	ts_nm.select_and_reserve(COLOR, 600, aq_nm)
	_check_eq(ci_nm.get_candidates(COLOR), cand_before, "M15-23 selection did not mutate ColorCandidateIndex candidate truth")

	# --- rectangular board (w != h), row-major ascending selection (test 30; crit 38) ---
	# 5x2: index = y*5 + x. Only some cells are color 5 so ordering across rows matters.
	var b_rect = _make_colored_board(5, 2, [0, COLOR, 0, 0, 0,   0, 0, COLOR, 0, COLOR])
	var ci_rect = ColorCandidateIndex.create(); ci_rect.bind(b_rect)
	var rs_rect = ReservationState.create(); rs_rect.bind(b_rect)
	var ts_rect = TargetSelector.create(); ts_rect.bind(b_rect, ci_rect, rs_rect)
	var aq_rect = AccessQueryDouble.new(); aq_rect.default_targetable = true
	# color-5 cells at row-major indices 1, 7, 9 -> ascending selection order.
	_check_eq(ts_rect.select_and_reserve(COLOR, 700, aq_rect), 1, "M15-30 rectangular board: first color-5 candidate (index 1) selected")
	_check_eq(ts_rect.select_and_reserve(COLOR, 701, aq_rect), 7, "M15-30 rectangular board: second candidate (index 7, next row) selected")
	_check_eq(ts_rect.select_and_reserve(COLOR, 702, aq_rect), 9, "M15-30 rectangular board: third candidate (index 9) selected")

	# --- selector implements no route-generation API (test 24; crit 13,14) ---
	var route_methods := ["generate_route", "route", "find_path", "compute_path", "astar", "get_route", "build_route", "path_to"]
	var no_routing := true
	for m in route_methods:
		if ts.has_method(m):
			no_routing = false
	_check(no_routing, "M15-24 TargetSelector exposes no route-generation/pathfinding API")

	print("  M15 TargetSelector tests complete")

func _run_target_selector_simultaneous_tests() -> void:
	print("---- M15: TargetSelector simultaneous-assignment tests ----")
	var COLOR := 5

	# --- competing owners for ONE reachable target: exactly one wins (test 27; crit 29) ---
	var b1 = _make_colored_board(1, 1, [COLOR])
	var ci1 = ColorCandidateIndex.create(); ci1.bind(b1)
	var rs1 = ReservationState.create(); rs1.bind(b1)
	var ts1 = TargetSelector.create(); ts1.bind(b1, ci1, rs1)
	var aq1 = AccessQueryDouble.new(); aq1.default_targetable = true
	var wins := 0
	for owner in range(1, 20):
		if ts1.select_and_reserve(COLOR, owner, aq1) != -1:
			wins += 1
	_check_eq(wins, 1, "M15-27 exactly one owner wins a single contested target")
	_check_eq(rs1.get_reservation_count(), 1, "M15-27 exactly one reservation exists after the contest")

	# --- multiple candidates: assignments unique and deterministic by call order (test 28; crit 30) ---
	var b2 = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var ci2 = ColorCandidateIndex.create(); ci2.bind(b2)
	var rs2 = ReservationState.create(); rs2.bind(b2)
	var ts2 = TargetSelector.create(); ts2.bind(b2, ci2, rs2)
	var aq2 = AccessQueryDouble.new(); aq2.default_targetable = true
	var a = ts2.select_and_reserve(COLOR, 10, aq2)
	var b = ts2.select_and_reserve(COLOR, 11, aq2)
	var c = ts2.select_and_reserve(COLOR, 12, aq2)
	_check_eq(a, 0, "M15-28 first caller gets ascending target 0")
	_check_eq(b, 1, "M15-28 second caller gets target 1")
	_check_eq(c, 2, "M15-28 third caller gets target 2")
	var uniq := {}
	uniq[a] = true; uniq[b] = true; uniq[c] = true
	_check_eq(uniq.size(), 3, "M15-28 concurrent assignments are unique")
	_check_eq(ts2.select_and_reserve(COLOR, 13, aq2), -1, "M15-28 fourth caller (no free target) gets -1")

	# --- first reserve loses to a competing synchronous assignment; owner continues (test 29; crit 31) ---
	var b3 = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var ci3 = ColorCandidateIndex.create(); ci3.bind(b3)
	var rs3 = ReservationState.create(); rs3.bind(b3)
	var ts3 = TargetSelector.create(); ts3.bind(b3, ci3, rs3)
	var aq3 = AccessQueryDouble.new(); aq3.default_targetable = true
	# Simulate a competing owner grabbing target 0 in the window between the
	# selector's targetable-check and its reserve() attempt: reserve 0 for owner
	# 999 as a side effect of the FIRST access query.
	var grabbed := [false]
	aq3.on_query = func(index):
		if not grabbed[0]:
			rs3.reserve(0, 999)
			grabbed[0] = true
	var sel3 = ts3.select_and_reserve(COLOR, 10, aq3)
	_check_eq(sel3, 1, "M15-29 lost target 0 to a competing assignment; continued to next valid candidate 1")
	_check_eq(rs3.get_owner(0), 999, "M15-29 competing owner holds the contested target 0")
	_check_eq(rs3.get_owner(1), 10, "M15-29 unassigned owner ended up owning the next candidate 1")

	print("  M15 TargetSelector simultaneous-assignment tests complete")

func _run_target_selector_strict_v02_tests() -> void:
	# Strict Audit Standard v2 corrections for M15 (F-M15-STRICT-001/002/003).
	print("---- M15 strict-v2: fail-closed bind, board coherence, same-owner contention ----")
	var COLOR := 5

	# ============ F-M15-STRICT-001: malformed non-null dependency fail-closed ==
	var b = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var ci = ColorCandidateIndex.create(); ci.bind(b)
	var rs = ReservationState.create(); rs.bind(b)

	# A non-null object lacking the narrow required API must be rejected at bind.
	var junk = RefCounted.new() # implements none of the required methods.
	var ts_bad = TargetSelector.create()
	_check_eq(ts_bad.bind(junk, ci, rs), false, "STRICT-001: malformed non-null BoardState rejected")
	_check_eq(ts_bad.is_bound(), false, "STRICT-001: selector stays unbound after malformed board")
	_check_eq(ts_bad.bind(b, junk, rs), false, "STRICT-001: malformed non-null candidate index rejected")
	_check_eq(ts_bad.bind(b, ci, junk), false, "STRICT-001: malformed non-null reservation state rejected")
	# No runtime call escaped: a fully-unbound selector selects nothing safely.
	var aq_bad = AccessQueryDouble.new(); aq_bad.default_targetable = true
	_check_eq(ts_bad.select_and_reserve(COLOR, 1, aq_bad), -1, "STRICT-001: unbound selector selects nothing (no escaped call)")

	# Failed bind after a VALID bind must neutralize the prior refs (stale-unusable).
	var ts_stale = TargetSelector.create()
	_check(ts_stale.bind(b, ci, rs), "STRICT-001: precondition valid bind succeeds")
	_check(ts_stale.select_and_reserve(COLOR, 2, aq_bad) != -1, "STRICT-001: precondition valid selection works")
	_check_eq(ts_stale.bind(junk, ci, rs), false, "STRICT-001: subsequent malformed bind fails")
	_check_eq(ts_stale.is_bound(), false, "STRICT-001: failed re-bind clears bound state")
	_check_eq(ts_stale.select_and_reserve(COLOR, 3, aq_bad), -1, "STRICT-001: stale prior refs are not reusable after failed bind")

	# ============ F-M15-STRICT-002: same-BoardState coherence ==================
	# Two DIFFERENT boards with identical dimensions/content.
	var bA = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var bB = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	_check(bA != bB, "STRICT-002: two same-size boards are distinct instances")

	# is_bound_to is exact identity, returns bool, exposes no board reference.
	var ciA = ColorCandidateIndex.create(); ciA.bind(bA)
	var rsA = ReservationState.create(); rsA.bind(bA)
	_check(ciA.is_bound_to(bA), "STRICT-002: candidate is_bound_to true for its own board")
	_check(not ciA.is_bound_to(bB), "STRICT-002: candidate is_bound_to false for a same-size other board")
	_check(rsA.is_bound_to(bA) and not rsA.is_bound_to(bB), "STRICT-002: reservation is_bound_to is exact identity")
	_check_eq(typeof(ciA.is_bound_to(bA)), TYPE_BOOL, "STRICT-002: coherence API returns a bool")
	_check(not ciA.has_method("get_board"), "STRICT-002: candidate exposes no mutable board getter")
	_check(not rsA.has_method("get_board"), "STRICT-002: reservation exposes no mutable board getter")

	# Mismatched deps at bind time fail closed.
	var ciB = ColorCandidateIndex.create(); ciB.bind(bB)
	var rsB = ReservationState.create(); rsB.bind(bB)
	var ts_mm = TargetSelector.create()
	_check_eq(ts_mm.bind(bA, ciB, rsA), false, "STRICT-002: candidate bound to a different same-size board fails bind")
	_check_eq(ts_mm.bind(bA, ciA, rsB), false, "STRICT-002: reservation bound to a different same-size board fails bind")

	# Post-bind candidate rebind -> selection fails closed (re-checked per call).
	var ci_r = ColorCandidateIndex.create(); ci_r.bind(bA)
	var rs_r = ReservationState.create(); rs_r.bind(bA)
	var ts_r = TargetSelector.create()
	_check(ts_r.bind(bA, ci_r, rs_r), "STRICT-002: valid bind on board A")
	_check(ts_r.select_and_reserve(COLOR, 20, aq_bad) != -1, "STRICT-002: selection works while coherent")
	ci_r.rebind(bB) # sibling rebound to a different board after selector bind.
	_check_eq(ts_r.select_and_reserve(COLOR, 21, aq_bad), -1, "STRICT-002: candidate rebind to board B makes selection fail closed")

	# Post-bind reservation rebind -> selection fails closed.
	var ci_r2 = ColorCandidateIndex.create(); ci_r2.bind(bA)
	var rs_r2 = ReservationState.create(); rs_r2.bind(bA)
	var ts_r2 = TargetSelector.create()
	_check(ts_r2.bind(bA, ci_r2, rs_r2), "STRICT-002: second valid bind on board A")
	rs_r2.rebind(bB)
	_check_eq(ts_r2.select_and_reserve(COLOR, 22, aq_bad), -1, "STRICT-002: reservation rebind to board B makes selection fail closed")

	# ============ F-M15-STRICT-003: SAME-owner contention re-check ============
	var bc = _make_colored_board(3, 1, [COLOR, COLOR, COLOR])
	var cic = ColorCandidateIndex.create(); cic.bind(bc)
	var rsc = ReservationState.create(); rsc.bind(bc)
	var tsc = TargetSelector.create(); tsc.bind(bc, cic, rsc)
	var aqc = AccessQueryDouble.new(); aqc.default_targetable = true
	var OWNER := 42
	# Side effect on the FIRST access query: the SAME owner synchronously acquires
	# ANOTHER valid target (index 1) before the selector's reserve(0) executes.
	var fired := [false]
	aqc.on_query = func(index):
		if not fired[0]:
			rsc.reserve(1, OWNER) # same owner grabs a different valid target.
			fired[0] = true
	var selc = tsc.select_and_reserve(COLOR, OWNER, aqc)
	_check_eq(selc, -1, "STRICT-003: reserve(0) loses because owner already assigned -> clean no-new-target")
	_check(aqc.was_queried(0), "STRICT-003: first candidate was access-queried")
	_check(not aqc.was_queried(1), "STRICT-003: later candidate 1 is NOT queried after owner becomes assigned")
	_check(not aqc.was_queried(2), "STRICT-003: later candidate 2 is NOT queried")
	_check_eq(rsc.get_target_for_owner(OWNER), 1, "STRICT-003: only the side-effect reservation (target 1) is owned by X")
	_check_eq(rsc.get_reservation_count(), 1, "STRICT-003: selector created NO additional reservation")
	_check_eq(rsc.get_owner(0), -1, "STRICT-003: contested target 0 remains unreserved")

	print("  M15 strict-v2 tests complete")

func _run_target_selector_benchmark() -> void:
	# 59x59 = 3481 cells, all color 0, all ACTIVE (test 30 rectangular below; test 31).
	var cells := PackedInt32Array(); cells.resize(3481)
	for i in 3481:
		cells[i] = 0
	var board = _make_colored_board(59, 59, Array(cells))
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var rs = ReservationState.create(); rs.bind(board)
	var ts = TargetSelector.create(); ts.bind(board, ci, rs)

	var candidate_count: int = ci.count_candidates(0)
	_check_eq(candidate_count, 3481, "M15-31 candidate count for tested color on 59x59 board")

	# --- bounded-iteration proof: block a prefix, confirm access queries == prefix+1, NOT full board ---
	var blocked_prefix := 100
	var aq_iter = AccessQueryDouble.new(); aq_iter.default_targetable = true
	for i in blocked_prefix:
		aq_iter.set_targetable(i, false)
	var sel_iter = ts.select_and_reserve(0, 1, aq_iter)
	_check_eq(sel_iter, blocked_prefix, "M15-32 selection skipped %d blocked candidates, chose first reachable" % blocked_prefix)
	_check_eq(aq_iter.total_queries(), blocked_prefix + 1, "M15-40 access queries == blocked prefix + 1 (no full 3481-cell scan)")
	_check(aq_iter.total_queries() < 3481, "M15-40 steady-state selection iterates candidates, not whole board")
	rs.release_for_owner(1)

	# --- repeated first-candidate sample: CPU timing (no FPS/GPU claim) ---
	var aq_fast = AccessQueryDouble.new(); aq_fast.default_targetable = true
	var sample := 500
	var total_queries := 0
	var t0 := Time.get_ticks_usec()
	for i in sample:
		var owner: int = 10000 + i
		ts.select_and_reserve(0, owner, aq_fast)
		rs.release_for_owner(owner)
	var t1 := Time.get_ticks_usec()
	# Each first-candidate select on an all-targetable board issues exactly one
	# access query (returns the lowest free target immediately) -> no full scan.
	total_queries = aq_fast.total_queries()
	_check_eq(total_queries, sample, "M15-32 first-candidate selection issues exactly one access query per call")

	print("---- M15 TargetSelector performance (59x59 = 3481 cells) ----")
	print("  candidate count for tested color: %d" % candidate_count)
	print("  bounded-iteration select (100 blocked prefix): %d access-query calls (chose index %d)" % [blocked_prefix + 1, sel_iter])
	print("  select_and_reserve x%d (first-candidate): %.3f ms total, %.5f ms/select" % [sample, (t1 - t0) / 1000.0, (t1 - t0) / 1000.0 / sample])
	print("  access-query calls over sample: %d (== %d selects, one per call — no per-call full-board scan)" % [total_queries, sample])
	print("  (CPU/selection timing only — not an FPS/GPU claim; iterates color candidates, never all 3481 cells)")

func _snapshot_cell_states(board) -> PackedByteArray:
	var out := PackedByteArray()
	var n: int = board.get_cell_count()
	out.resize(n)
	for i in n:
		out[i] = board.get_cell_state(i)
	return out

func _cell_states_equal(board, snapshot: PackedByteArray) -> bool:
	var n: int = board.get_cell_count()
	if snapshot.size() != n:
		return false
	for i in n:
		if board.get_cell_state(i) != snapshot[i]:
			return false
	return true

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

## ---------------------------------------------------------- M16: routing --
## M16 defines the RoutingSystem CONTRACT (HOW to travel to an already-assigned
## target) — not the M17 path algorithm. These tests prove the input/output
## contracts, board-local coordinate space, injected access seam with direct
## segment observability (AL-018), swappability, no-retarget law, and the
## generic debug visualizer. No AStar/BFS/DFS/curve/collision logic exists here.

## Canonical cell center via BoardState index/position math (test-side helper).
func _center_of(board, index: int) -> Vector2:
	var pos: Vector2i = board.get_cell_position(index)
	return Vector2(float(pos.x) + 0.5, float(pos.y) + 0.5)

func _run_route_request_tests() -> void:
	var board = _make_blank_board(6, 4) # rectangular
	# Slot origin OUTSIDE the board on every side; request must preserve it exactly.
	var origins := {
		"left": Vector2(-3.0, 2.5),
		"right": Vector2(9.0, 1.5),
		"above": Vector2(3.0, -2.0),
		"below": Vector2(2.5, 7.0),
	}
	var tgt = board.get_cell_index(4, 2)
	for name in origins:
		var req = RouteRequest.for_target(board, origins[name], tgt)
		_check(req != null, "RouteRequest.for_target builds for slot origin %s" % name)
		_check(req.start_position.is_equal_approx(origins[name]), "slot origin %s preserved exactly (may lie outside board)" % name)
		_check_eq(req.target_index, tgt, "request keeps assigned target_index (origin %s)" % name)
		_check(req.target_position.is_equal_approx(_center_of(board, tgt)), "target_position is canonical cell center (origin %s)" % name)
		_check_eq(req.board_width, 6, "request board_width from BoardState (origin %s)" % name)
		_check_eq(req.board_height, 4, "request board_height from BoardState (origin %s)" % name)

	# Invalid target index -> null (fail closed).
	_check(RouteRequest.for_target(board, Vector2.ZERO, -1) == null, "for_target(-1) rejected (invalid target index)")
	_check(RouteRequest.for_target(board, Vector2.ZERO, 24) == null, "for_target(cell_count) rejected (invalid target index)")

	# Canonical center via BoardState index/position math (not re-derived here).
	_check(RouteRequest.center_of_index(board, board.get_cell_index(0, 0)).is_equal_approx(Vector2(0.5, 0.5)), "center of (0,0) == (0.5,0.5)")
	_check(RouteRequest.center_of_index(board, board.get_cell_index(5, 3)).is_equal_approx(Vector2(5.5, 3.5)), "center of (5,3) == (5.5,3.5) on 6x4 rect board")
	# One logical cell is 1x1 units: adjacent cell centers differ by exactly 1.0.
	var c_a := RouteRequest.center_of_index(board, board.get_cell_index(1, 1))
	var c_b := RouteRequest.center_of_index(board, board.get_cell_index(2, 1))
	_check(is_equal_approx(c_b.x - c_a.x, 1.0), "one logical cell == 1.0 coordinate unit (adjacent centers differ by 1.0)")

func _run_route_result_tests() -> void:
	var pts := PackedVector2Array([Vector2(-2.0, 0.5), Vector2(4.5, 2.5)])
	var r = RouteResult.success_route(11, pts)
	_check(r.success, "success_route.success == true")
	_check_eq(r.target_index, 11, "success_route keeps target_index")
	_check_eq(r.point_count(), 2, "success_route point_count == 2")
	_check(r.get_points()[0].is_equal_approx(Vector2(-2.0, 0.5)), "success first point preserved")
	_check(r.get_points()[1].is_equal_approx(Vector2(4.5, 2.5)), "success last point preserved")
	_check_eq(r.failure_reason, RouteResult.FailureReason.NONE, "success failure_reason == NONE")

	# Detachment: mutating the caller's array after construction must not leak in.
	pts.append(Vector2(99, 99))
	_check_eq(r.point_count(), 2, "internal points detached from caller's source array (copy-in)")
	# get_points() returns a detached copy each call.
	var got = r.get_points()
	got.append(Vector2(88, 88))
	_check_eq(r.point_count(), 2, "get_points() returns a detached copy (copy-out)")

	# Failure result structure.
	var f = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, 7)
	_check(not f.success, "failure.success == false")
	_check_eq(f.point_count(), 0, "failure points empty")
	_check_eq(f.target_index, 7, "failure retains originally requested target")
	_check_eq(f.failure_reason, RouteResult.FailureReason.NO_ROUTE, "failure reason is explicit/stable")

func _run_route_validator_tests() -> void:
	var board = _make_blank_board(5, 5)
	var tgt = board.get_cell_index(3, 2)
	var start := Vector2(-1.0, 2.5)
	var req = RouteRequest.for_target(board, start, tgt)

	# validate_request: happy path + each rejection.
	_check_eq(RouteValidator.validate_request(req, board), RouteResult.FailureReason.NONE, "validate_request: valid request -> NONE")
	_check_eq(RouteValidator.validate_request(null, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: null request rejected")

	var bad_idx = RouteRequest.for_target(board, start, tgt)
	bad_idx.target_index = 999
	_check_eq(RouteValidator.validate_request(bad_idx, board), RouteResult.FailureReason.INVALID_TARGET, "validate_request: out-of-range target -> INVALID_TARGET")

	# CLEARED target rejected.
	var cleared_board = _make_blank_board(5, 5)
	var creq = RouteRequest.for_target(cleared_board, start, tgt)
	cleared_board.set_cell_state(tgt, BoardState.CellState.CLEARED)
	_check_eq(RouteValidator.validate_request(creq, cleared_board), RouteResult.FailureReason.TARGET_NOT_ACTIVE, "validate_request: CLEARED target -> TARGET_NOT_ACTIVE")

	# target_position drift rejected.
	var drift = RouteRequest.for_target(board, start, tgt)
	drift.target_position = Vector2(0.5, 0.5)
	_check_eq(RouteValidator.validate_request(drift, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: wrong target_position -> INVALID_REQUEST")

	# Board dim mismatch rejected.
	var dim = RouteRequest.for_target(board, start, tgt)
	dim.board_width = 4
	_check_eq(RouteValidator.validate_request(dim, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: board dim mismatch -> INVALID_REQUEST")

	# --- validate_route with injected access truth + direct observability ---
	var straight = RouteFakeStraight.new()
	var result = straight.compute_route(req, board, null)
	var access = RouteAccessQueryDouble.new()
	access.open_polyline(result.get_points()) # open the exact segments this route uses
	_check_eq(RouteValidator.validate_route(req, result, board, access), RouteResult.FailureReason.NONE, "validate_route: open segments -> valid route")
	# AL-018: assert the ACTUAL segment-query sequence, not just the boolean.
	_check_eq(access.total_queries(), 1, "validate_route queried exactly the 1 segment of a 2-point route")
	_check(access.query_log[0]["from"].is_equal_approx(req.start_position), "segment query from == slot origin")
	_check(access.query_log[0]["to"].is_equal_approx(req.target_position), "segment query to == assigned target center")
	_check_eq(access.query_log[0]["target_index"], req.target_index, "segment query carries the assigned target_index (no retarget)")
	_check(access.query_log[0]["verdict"], "segment query verdict observed true for open segment")

	# Missing access query fails closed.
	_check_eq(RouteValidator.validate_route(req, result, board, null), RouteResult.FailureReason.MISSING_ACCESS_QUERY, "validate_route: missing access query -> MISSING_ACCESS_QUERY (fail closed)")

	# Blocked segment invalidates route (non-target ACTIVE blocker semantic).
	var blocked = RouteAccessQueryDouble.new()
	blocked.block_segment(result.get_points()[0], result.get_points()[1])
	_check_eq(RouteValidator.validate_route(req, result, board, blocked), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: blocked segment -> INVALID_ROUTE")

	# Multi-segment: middle blocked invalid; all-open valid (CLEARED/open semantic).
	var relay = RouteFakeRelay.new()
	var rresult = relay.compute_route(req, board, null)
	var rpts = rresult.get_points()
	var mid_open = RouteAccessQueryDouble.new()
	mid_open.open_polyline(rpts)
	_check_eq(RouteValidator.validate_route(req, rresult, board, mid_open), RouteResult.FailureReason.NONE, "validate_route: 3-point route all-open -> valid")
	_check_eq(mid_open.total_queries(), 2, "validate_route queried both segments of a 3-point route")
	var mid_block = RouteAccessQueryDouble.new()
	mid_block.open_segment(rpts[0], rpts[1])
	mid_block.block_segment(rpts[1], rpts[2]) # final approach blocked
	_check_eq(RouteValidator.validate_route(req, rresult, board, mid_block), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: one blocked segment among many -> INVALID_ROUTE")

	# Wrong result target invalidates route.
	var wrong_tgt = RouteResult.success_route(tgt + 1, result.get_points())
	var acc2 = RouteAccessQueryDouble.new(); acc2.open_polyline(result.get_points())
	_check_eq(RouteValidator.validate_route(req, wrong_tgt, board, acc2), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: result target != request target -> INVALID_ROUTE")

	# Wrong start point invalidates route.
	var bad_start = RouteResult.success_route(tgt, PackedVector2Array([Vector2(0.0, 0.0), req.target_position]))
	var acc3 = RouteAccessQueryDouble.new(); acc3.open_polyline(bad_start.get_points())
	_check_eq(RouteValidator.validate_route(req, bad_start, board, acc3), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: start != slot origin -> INVALID_ROUTE")

	# Wrong end point invalidates route.
	var bad_end = RouteResult.success_route(tgt, PackedVector2Array([req.start_position, Vector2(0.5, 0.5)]))
	var acc4 = RouteAccessQueryDouble.new(); acc4.open_polyline(bad_end.get_points())
	_check_eq(RouteValidator.validate_route(req, bad_end, board, acc4), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: end != assigned target center -> INVALID_ROUTE")

	# Too few points invalid.
	var one_pt = RouteResult.success_route(tgt, PackedVector2Array([req.start_position]))
	var acc5 = RouteAccessQueryDouble.new()
	_check_eq(RouteValidator.validate_route(req, one_pt, board, acc5), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: < 2 points -> INVALID_ROUTE")

	# === Strict V02: non-finite request coordinates rejected before geometry/access ===
	var nan_start = RouteRequest.for_target(board, Vector2(NAN, 2.5), tgt)
	_check_eq(RouteValidator.validate_request(nan_start, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: NaN start rejected")
	var pinf_start = RouteRequest.for_target(board, Vector2(INF, 2.5), tgt)
	_check_eq(RouteValidator.validate_request(pinf_start, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: +INF start rejected")
	var ninf_start = RouteRequest.for_target(board, Vector2(-INF, 2.5), tgt)
	_check_eq(RouteValidator.validate_request(ninf_start, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: -INF start rejected")
	var nf_target = RouteRequest.for_target(board, start, tgt)
	nf_target.target_position = Vector2(INF, INF)
	_check_eq(RouteValidator.validate_request(nf_target, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: non-finite target_position rejected")
	# A malformed request fails through validate_route BEFORE any access query.
	var early_acc = RouteAccessQueryDouble.new(); early_acc.default_traversable = true
	var early_route = RouteResult.success_route(tgt, PackedVector2Array([Vector2(NAN, 2.5), req.target_position]))
	_check_eq(RouteValidator.validate_route(nan_start, early_route, board, early_acc), RouteResult.FailureReason.INVALID_REQUEST, "validate_route: non-finite request -> INVALID_REQUEST")
	_check_eq(early_acc.total_queries(), 0, "validate_route: malformed request makes zero access calls")

	# === Strict V02: non-finite intermediate route points rejected, zero access calls ===
	# default_traversable = true so, absent the finite guard, access WOULD approve —
	# proving INVALID_ROUTE + zero queries comes from the structural check, not access.
	var nan_mid = RouteResult.success_route(tgt, PackedVector2Array([req.start_position, Vector2(NAN, NAN), req.target_position]))
	var nan_mid_acc = RouteAccessQueryDouble.new(); nan_mid_acc.default_traversable = true
	_check_eq(RouteValidator.validate_route(req, nan_mid, board, nan_mid_acc), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: NaN intermediate point -> INVALID_ROUTE")
	_check_eq(nan_mid_acc.total_queries(), 0, "validate_route: NaN-point route makes zero access calls")
	var inf_mid = RouteResult.success_route(tgt, PackedVector2Array([req.start_position, Vector2(INF, 3.5), req.target_position]))
	var inf_mid_acc = RouteAccessQueryDouble.new(); inf_mid_acc.default_traversable = true
	_check_eq(RouteValidator.validate_route(req, inf_mid, board, inf_mid_acc), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: INF intermediate point -> INVALID_ROUTE")
	_check_eq(inf_mid_acc.total_queries(), 0, "validate_route: INF-point route makes zero access calls")

	# === Strict V02: success/failure metadata coherence ===
	var contradictory = RouteResult.success_route(tgt, result.get_points())
	contradictory.failure_reason = RouteResult.FailureReason.NO_ROUTE
	var contra_acc = RouteAccessQueryDouble.new(); contra_acc.open_polyline(result.get_points())
	_check_eq(RouteValidator.validate_route(req, contradictory, board, contra_acc), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: success + NO_ROUTE contradiction -> INVALID_ROUTE")

	# Canonical failure structural validation + each contradiction rejected.
	var good_fail = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, tgt)
	_check_eq(RouteValidator.validate_failure_result(req, good_fail), RouteResult.FailureReason.NONE, "validate_failure_result: canonical failure -> NONE")
	var fail_none = RouteResult.failure(RouteResult.FailureReason.NONE, tgt)
	_check_eq(RouteValidator.validate_failure_result(req, fail_none), RouteResult.FailureReason.INVALID_ROUTE, "validate_failure_result: failure + NONE rejected")
	var fail_pts = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, tgt)
	fail_pts._points = PackedVector2Array([req.start_position, req.target_position])
	_check_eq(RouteValidator.validate_failure_result(req, fail_pts), RouteResult.FailureReason.INVALID_ROUTE, "validate_failure_result: failure with points rejected")
	var fail_wrong = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, tgt + 1)
	_check_eq(RouteValidator.validate_failure_result(req, fail_wrong), RouteResult.FailureReason.INVALID_ROUTE, "validate_failure_result: failure with wrong target rejected")
	_check_eq(RouteValidator.validate_failure_result(req, result), RouteResult.FailureReason.INVALID_ROUTE, "validate_failure_result: a success result is not a valid failure")

	# === Strict V02: non-bool access verdict fails closed (no truthiness approval) ===
	for bad_val in [1, "yes", null]:
		var nb = RouteNonBoolAccessQueryDouble.new()
		nb.verdict_value = bad_val
		_check_eq(RouteValidator.validate_route(req, result, board, nb), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: non-bool access verdict (%s) fails closed" % str(bad_val))
		_check(nb.call_count >= 1, "validate_route: non-bool verdict (%s) was actually consulted then rejected" % str(bad_val))

	# === Strict V03: malformed non-null request/board boundary fails closed (AL-040) ===
	# non-null junk must fail closed to a stable reason with NO runtime fault and
	# NO field/method deref past the guard.
	var junk_req = RefCounted.new()
	_check_eq(RouteValidator.validate_request(junk_req, board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: RefCounted junk request fails closed")
	var junk_board = RefCounted.new()
	_check_eq(RouteValidator.validate_request(req, junk_board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: RefCounted junk board fails closed")
	var partial_board = PartialBoardDouble.new()
	_check_eq(RouteValidator.validate_request(req, partial_board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: partial-API board fails closed before missing-method call")

	# Through validate_route: junk request / junk board / partial board ->
	# stable INVALID_REQUEST and ZERO access calls (guard precedes the access loop).
	var jr_acc = RouteAccessQueryDouble.new(); jr_acc.default_traversable = true
	_check_eq(RouteValidator.validate_route(junk_req, result, board, jr_acc), RouteResult.FailureReason.INVALID_REQUEST, "validate_route: junk request -> INVALID_REQUEST")
	_check_eq(jr_acc.total_queries(), 0, "validate_route: junk request makes zero access calls")
	var jb_acc = RouteAccessQueryDouble.new(); jb_acc.default_traversable = true
	_check_eq(RouteValidator.validate_route(req, result, junk_board, jb_acc), RouteResult.FailureReason.INVALID_REQUEST, "validate_route: junk board -> INVALID_REQUEST")
	_check_eq(jb_acc.total_queries(), 0, "validate_route: junk board makes zero access calls")
	var pb_acc = RouteAccessQueryDouble.new(); pb_acc.default_traversable = true
	_check_eq(RouteValidator.validate_route(req, result, partial_board, pb_acc), RouteResult.FailureReason.INVALID_REQUEST, "validate_route: partial-API board -> INVALID_REQUEST")
	_check_eq(pb_acc.total_queries(), 0, "validate_route: partial-API board makes zero access calls")

	# validate_failure_result must not dereference a malformed non-null request.
	var canon_fail = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, tgt)
	_check_eq(RouteValidator.validate_failure_result(junk_req, canon_fail), RouteResult.FailureReason.INVALID_ROUTE, "validate_failure_result: malformed non-null request fails closed (no deref)")
	# Null request keeps its documented semantics (a canonical failure is still NONE).
	_check_eq(RouteValidator.validate_failure_result(null, canon_fail), RouteResult.FailureReason.NONE, "validate_failure_result: null request retains documented semantics")

func _run_routing_system_swappability_tests() -> void:
	var board = _make_blank_board(8, 6)
	var tgt = board.get_cell_index(5, 3)
	var req = RouteRequest.for_target(board, Vector2(-2.0, 3.5), tgt)

	# Base implementation invents NO route: clean NOT_IMPLEMENTED failure.
	var base = RoutingSystem.new()
	var base_res = base.compute_route(req, board, null)
	_check(not base_res.success, "base RoutingSystem fails cleanly (no invented route)")
	_check_eq(base_res.failure_reason, RouteResult.FailureReason.NOT_IMPLEMENTED, "base RoutingSystem -> NOT_IMPLEMENTED")
	_check_eq(base_res.point_count(), 0, "base RoutingSystem failure has empty points")
	_check_eq(base_res.target_index, tgt, "base RoutingSystem failure retains assigned target")

	# Two distinct fakes satisfy the SAME compute_route contract.
	var straight = RouteFakeStraight.new()
	var relay = RouteFakeRelay.new()
	var sres = straight.compute_route(req, board, null)
	var rres = relay.compute_route(req, board, null)
	var acc_s = RouteAccessQueryDouble.new(); acc_s.open_polyline(sres.get_points())
	var acc_r = RouteAccessQueryDouble.new(); acc_r.open_polyline(rres.get_points())
	_check_eq(RouteValidator.validate_route(req, sres, board, acc_s), RouteResult.FailureReason.NONE, "fake straight satisfies routing contract")
	_check_eq(RouteValidator.validate_route(req, rres, board, acc_r), RouteResult.FailureReason.NONE, "fake relay satisfies routing contract")
	_check_eq(sres.point_count(), 2, "straight fake yields 2-point route")
	_check_eq(rres.point_count(), 3, "relay fake yields 3-point route")
	# Route target is always the already-assigned target for every implementation.
	_check_eq(sres.target_index, tgt, "straight fake keeps assigned target")
	_check_eq(rres.target_index, tgt, "relay fake keeps assigned target")

	# Swapping implementation requires NO TargetSelector change: routing objects
	# have no selection API and never reference TargetSelector/ReservationState.
	for impl in [base, straight, relay]:
		_check(impl.has_method("compute_route"), "routing impl exposes compute_route")
		_check(not impl.has_method("select_and_reserve"), "routing impl has NO target-selection method (WHAT stays in TargetSelector)")
		_check(not impl.has_method("reserve"), "routing impl has NO reservation method")
	# TargetSelector class is untouched and still independently functional.
	var sel = TargetSelector.create()
	_check(sel.has_method("select_and_reserve"), "TargetSelector unchanged: still owns select_and_reserve")
	_check(not sel.has_method("compute_route"), "TargetSelector does not gain routing responsibility")

	# No global singleton coupling: independent instances.
	_check(RoutingSystem.new() != RoutingSystem.new(), "RoutingSystem is not a shared singleton (distinct instances)")

func _run_routing_no_retarget_tests() -> void:
	var board = _make_blank_board(7, 7)
	var tgt = board.get_cell_index(4, 4)
	var req = RouteRequest.for_target(board, Vector2(-1.0, 4.5), tgt)

	# A route failure for target X never becomes "pick target Y".
	var base = RoutingSystem.new()
	var before := _snapshot_cell_states(board)
	var res = base.compute_route(req, board, null)
	_check_eq(res.target_index, tgt, "no-route result keeps original target (never retargets)")
	_check_eq(res.point_count(), 0, "no-route result has no route points")
	_check(_cell_states_equal(board, before), "compute_route (failure) does not mutate BoardState")

	# Fakes also never mutate BoardState.
	var s_before := _snapshot_cell_states(board)
	RouteFakeStraight.new().compute_route(req, board, null)
	RouteFakeRelay.new().compute_route(req, board, null)
	_check(_cell_states_equal(board, s_before), "fake routing compute_route does not mutate BoardState")

	# A live ReservationState the routing system has no handle to stays untouched.
	var reservations = ReservationState.new()
	reservations.bind(board)
	_check(reservations.reserve(tgt, 0), "precondition: target reserved for owner 0")
	base.compute_route(req, board, null)
	RouteFakeStraight.new().compute_route(req, board, null)
	_check_eq(reservations.get_owner(tgt), 0, "routing never reserves/releases/retargets an existing reservation")
	_check_eq(reservations.get_target_for_owner(0), tgt, "owner 0 still holds exactly its original target after routing")

func _run_route_debug_overlay_tests() -> void:
	var board = _make_blank_board(6, 6)
	var tgt = board.get_cell_index(2, 4)
	var req = RouteRequest.for_target(board, Vector2(-1.5, 4.5), tgt)
	var success = RouteFakeRelay.new().compute_route(req, board, null)

	# Pure draw-model for a successful route (no live draw context needed).
	var m := RouteDebugOverlay.build_draw_model(success)
	_check(m["success"], "debug model: success route -> success true")
	_check_eq((m["polyline"] as PackedVector2Array).size(), 3, "debug model: polyline mirrors route points")
	_check((m["start"] as Vector2).is_equal_approx(req.start_position), "debug model: start marker == slot origin")
	_check((m["end"] as Vector2).is_equal_approx(req.target_position), "debug model: end marker == assigned target center")
	_check_eq(m["target_index"], tgt, "debug model: carries assigned target_index")

	# Failure / no-route state represented cleanly.
	var fail = RoutingSystem.new().compute_route(req, board, null)
	var fm := RouteDebugOverlay.build_draw_model(fail)
	_check(not fm["success"], "debug model: failure -> success false")
	_check_eq(fm["failure_reason"], RouteResult.FailureReason.NOT_IMPLEMENTED, "debug model: failure reason surfaced for display")
	_check_eq((fm["polyline"] as PackedVector2Array).size(), 0, "debug model: failure has no polyline")
	# Null result also renders as a clean no-route state.
	var nm := RouteDebugOverlay.build_draw_model(null)
	_check(not nm["success"], "debug model: null result -> success false (no crash)")

	# The visualizer consumes RouteResult only and neither computes nor mutates.
	var before := _snapshot_cell_states(board)
	var overlay = RouteDebugOverlay.new()
	root.add_child(overlay) # runtime instantiation smoke (no .tscn needed)
	overlay.set_route(success)
	_check(overlay.get_draw_model()["success"], "overlay runtime smoke: accepts a valid successful route")
	overlay.set_route(fail)
	_check(not overlay.get_draw_model()["success"], "overlay runtime smoke: represents failure state")
	_check(not overlay.has_method("compute_route"), "overlay does not compute routes")
	_check(_cell_states_equal(board, before), "overlay does not mutate BoardState")
	overlay.free()

func _run_route_coordinate_scale_tests() -> void:
	# 59x59 (current production maximum) coordinate contract.
	var big = _make_blank_board(59, 59)
	var corner = big.get_cell_index(58, 58)
	_check(RouteRequest.center_of_index(big, corner).is_equal_approx(Vector2(58.5, 58.5)), "59x59 far corner center == (58.5,58.5)")
	var breq = RouteRequest.for_target(big, Vector2(-5.0, 58.5), corner)
	var bres = RouteFakeStraight.new().compute_route(breq, big, null)
	var bacc = RouteAccessQueryDouble.new(); bacc.open_polyline(bres.get_points())
	_check_eq(RouteValidator.validate_route(breq, bres, big, bacc), RouteResult.FailureReason.NONE, "59x59 full route validates end-to-end")
	# Coordinates are board-local cell units, NOT screen pixels (never 1080x2160).
	_check(bres.get_points()[1].x < 60.0 and bres.get_points()[1].y < 60.0, "59x59 route endpoint is in cell units (< board+1), not pixels")

	# Very Hard rectangular size (53x59) coordinate contract.
	var rect = _make_blank_board(53, 59)
	var rtgt = rect.get_cell_index(52, 58)
	_check(RouteRequest.center_of_index(rect, rtgt).is_equal_approx(Vector2(52.5, 58.5)), "53x59 far corner center == (52.5,58.5)")
	var rreq = RouteRequest.for_target(rect, Vector2(60.0, 30.0), rtgt) # origin outside right
	_check_eq(rreq.board_width, 53, "53x59 request board_width")
	_check_eq(rreq.board_height, 59, "53x59 request board_height")
	var rres = RouteFakeRelay.new().compute_route(rreq, rect, null)
	var racc = RouteAccessQueryDouble.new(); racc.open_polyline(rres.get_points())
	_check_eq(RouteValidator.validate_route(rreq, rres, rect, racc), RouteResult.FailureReason.NONE, "53x59 rectangular full route validates end-to-end")

# ============================================================ M17 routing lab ==
# EXPERIMENTAL prototype/comparison tests. These do NOT select a production
# routing algorithm — the owner movement-language design gate stays open. Every
# successful prototype route is re-checked through the shared M16 RouteValidator.

func _m17_all_segments_open(pts: PackedVector2Array, access, target_index: int) -> bool:
	for i in range(pts.size() - 1):
		if not access.is_segment_traversable(pts[i], pts[i + 1], target_index):
			return false
	return true

func _run_m17_prototype_contract_tests() -> void:
	print("---- M17: prototype contract (behind M16) ----")
	var sc := RoutingLabScenarios.make_s1()
	var board = sc["board"]
	var targets: Array = sc["targets"]
	var origins: Array = sc["origins"]
	var reqs: Array = RoutingLabScenarios.build_requests(board, targets, origins)
	_check(reqs.size() >= 1, "S1 yields at least one request")
	var protos := [DirectRoutePrototype.new(), GridRoutePrototype.new(), OrganizedRoutePrototype.new()]
	var names := ["direct", "grid", "organized"]
	for pi in range(protos.size()):
		var proto = protos[pi]
		var nm: String = names[pi]
		_check(proto.has_method("compute_route"), "%s exposes compute_route (M16 signature)" % nm)
		_check(not proto.has_method("select_and_reserve"), "%s has NO target-selection method" % nm)
		_check(not proto.has_method("reserve"), "%s has NO reservation method" % nm)
		var access = PrototypeAccessQuery.new(board)
		var before := _snapshot_cell_states(board)
		var reservations = ReservationState.new()
		reservations.bind(board)
		var t0: int = reqs[0].target_index
		_check(reservations.reserve(t0, 0), "%s precondition: target reserved for owner 0" % nm)
		var res = proto.compute_route(reqs[0], board, access)
		_check(res.success, "%s routes the S1 target" % nm)
		_check_eq(res.target_index, t0, "%s keeps the assigned target identity" % nm)
		_check(_cell_states_equal(board, before), "%s does not mutate BoardState (no cell cleared)" % nm)
		_check_eq(reservations.get_owner(t0), 0, "%s does not touch ReservationState ownership" % nm)
		if res.success:
			_check_eq(RouteValidator.validate_route(reqs[0], res, board, access), RouteResult.FailureReason.NONE, "%s success passes shared RouteValidator" % nm)

func _run_m17_direct_tests() -> void:
	print("---- M17: direct baseline ----")
	var board = RoutingLabScenarios.make_open_board(10, 7)
	var idx = board.get_cell_index(8, 3)
	board.set_cell_state(idx, BoardState.CellState.ACTIVE)
	var access = PrototypeAccessQuery.new(board)
	var req = RouteRequest.for_target(board, Vector2(-2.0, 3.5), idx)
	var res = DirectRoutePrototype.new().compute_route(req, board, access)
	_check(res.success, "direct succeeds on an open straight segment")
	_check_eq(res.point_count(), 2, "direct route is a single 2-point segment (minimal)")
	_check_eq(RouteValidator.validate_route(req, res, board, access), RouteResult.FailureReason.NONE, "direct open route validates")

	var s2 := RoutingLabScenarios.make_s2()
	var b2 = s2["board"]
	var a2 = PrototypeAccessQuery.new(b2)
	var q2 = RoutingLabScenarios.build_requests(b2, s2["targets"], s2["origins"])[0]
	var r2 = DirectRoutePrototype.new().compute_route(q2, b2, a2)
	_check(not r2.success, "direct fails cleanly when its straight segment is blocked")
	_check_eq(r2.failure_reason, RouteResult.FailureReason.NO_ROUTE, "direct blocked -> NO_ROUTE (specific reason)")
	_check_eq(r2.point_count(), 0, "direct failure has empty route points")
	_check_eq(r2.target_index, q2.target_index, "direct failure retains the assigned target (no retarget)")

func _run_m17_grid_tests() -> void:
	print("---- M17: grid-aware prototype ----")
	var s2 := RoutingLabScenarios.make_s2()
	var b2 = s2["board"]
	var a2 = PrototypeAccessQuery.new(b2)
	var q2 = RoutingLabScenarios.build_requests(b2, s2["targets"], s2["origins"])[0]
	var grid = GridRoutePrototype.new()
	var r2 = grid.compute_route(q2, b2, a2)
	_check(r2.success, "grid finds a detour where the straight segment is blocked")
	var pts2: PackedVector2Array = r2.get_points()
	_check(pts2[0].is_equal_approx(q2.start_position), "grid route starts at the exterior slot origin")
	_check(pts2[pts2.size() - 1].is_equal_approx(q2.target_position), "grid route ends at the assigned target center (final endpoint only)")
	_check(_m17_all_segments_open(pts2, a2, q2.target_index), "every grid segment is accepted by access truth (blockers avoided)")
	_check_eq(RouteValidator.validate_route(q2, r2, b2, a2), RouteResult.FailureReason.NONE, "grid detour validates end-to-end")
	var r2b = GridRoutePrototype.new().compute_route(q2, b2, a2)
	_check(RouteMetrics.points_equal(pts2, r2b.get_points()), "grid is deterministic (identical points on repeat)")

	var s3 := RoutingLabScenarios.make_s3()
	var b3 = s3["board"]
	var a3 = PrototypeAccessQuery.new(b3)
	var q3 = RoutingLabScenarios.build_requests(b3, s3["targets"], s3["origins"])[0]
	var r3 = GridRoutePrototype.new().compute_route(q3, b3, a3)
	_check(not r3.success, "grid returns no route for a fully enclosed target")
	_check_eq(r3.failure_reason, RouteResult.FailureReason.NO_ROUTE, "enclosed target -> NO_ROUTE")
	_check_eq(r3.target_index, q3.target_index, "enclosed failure keeps the SAME target (no silent retarget)")

	var s4 := RoutingLabScenarios.make_s4()
	var b4 = s4["board"]
	var q4 = RoutingLabScenarios.build_requests(b4, s4["targets"], s4["origins"])[0]
	var before4 = GridRoutePrototype.new().compute_route(q4, b4, PrototypeAccessQuery.new(b4))
	_check(not before4.success, "S4 precondition: enclosed target has no route")
	for ci in s4["clear_after"]:
		b4.set_cell_state(int(ci), BoardState.CellState.CLEARED)
	var a4 = PrototypeAccessQuery.new(b4)
	var after4 = GridRoutePrototype.new().compute_route(q4, b4, a4)
	_check(after4.success, "S4: same target routes once prerequisite cells are CLEARED")
	_check_eq(after4.target_index, q4.target_index, "S4: target identity unchanged after opening")
	_check_eq(RouteValidator.validate_route(q4, after4, b4, a4), RouteResult.FailureReason.NONE, "S4 opened route validates")

func _run_m17_organized_tests() -> void:
	print("---- M17: organized/curved prototype ----")
	var s2 := RoutingLabScenarios.make_s2()
	var b2 = s2["board"]
	var a2 = PrototypeAccessQuery.new(b2)
	var q2 = RoutingLabScenarios.build_requests(b2, s2["targets"], s2["origins"])[0]
	var org = OrganizedRoutePrototype.new()
	var res = org.compute_route(q2, b2, a2)
	_check(res.success, "organized produces a route from a valid grid-aware source path")
	var pts: PackedVector2Array = res.get_points()
	_check(_m17_all_segments_open(pts, a2, q2.target_index), "organized: every emitted segment is accepted by access truth (no crossing a blocker)")
	_check_eq(RouteValidator.validate_route(q2, res, b2, a2), RouteResult.FailureReason.NONE, "organized route validates end-to-end")
	_check(pts.size() > 2, "organized kept a valid detour instead of an invalid straight shortcut (fallback held)")
	var res_b = OrganizedRoutePrototype.new().compute_route(q2, b2, a2)
	_check(RouteMetrics.points_equal(pts, res_b.get_points()), "organized is deterministic (identical points on repeat)")
	var s3 := RoutingLabScenarios.make_s3()
	var b3 = s3["board"]
	var a3 = PrototypeAccessQuery.new(b3)
	var q3 = RoutingLabScenarios.build_requests(b3, s3["targets"], s3["origins"])[0]
	var r3 = OrganizedRoutePrototype.new().compute_route(q3, b3, a3)
	_check(not r3.success, "organized returns no route for an enclosed target (no invented path)")
	_check_eq(r3.target_index, q3.target_index, "organized enclosed failure keeps the same target")

func _run_m17_metrics_tests() -> void:
	print("---- M17: comparison metrics ----")
	var poly := PackedVector2Array([Vector2(0, 0), Vector2(3, 0), Vector2(3, 4)])
	_check(is_equal_approx(RouteMetrics.route_distance(poly), 7.0), "route_distance sums segment lengths (3+4=7)")
	var stats := RouteMetrics.distance_stats([poly, PackedVector2Array([Vector2(0, 0), Vector2(1, 0)])])
	_check_eq(stats["count"], 2, "distance_stats counts routes")
	_check(is_equal_approx(stats["total"], 8.0), "distance_stats total = 7+1 = 8")
	_check(is_equal_approx(stats["mean"], 4.0), "distance_stats mean = 4")
	_check(is_equal_approx(stats["median"], 4.0), "distance_stats median of {1,7} = 4")

	var xa := PackedVector2Array([Vector2(0, 0), Vector2(4, 4)])
	var xb := PackedVector2Array([Vector2(0, 4), Vector2(4, 0)])
	_check_eq(RouteMetrics.crossing_count([xa, xb]), 1, "two X routes -> 1 proper crossing")
	var pa := PackedVector2Array([Vector2(0, 0), Vector2(4, 0)])
	var pb := PackedVector2Array([Vector2(0, 1), Vector2(4, 1)])
	_check_eq(RouteMetrics.crossing_count([pa, pb]), 0, "parallel routes -> 0 crossings")
	var sa := PackedVector2Array([Vector2(0, 0), Vector2(4, 1)])
	var sb := PackedVector2Array([Vector2(0, 0), Vector2(4, -1)])
	_check_eq(RouteMetrics.crossing_count([sa, sb]), 0, "shared start endpoint is NOT a crossing")

	var ca := PackedVector2Array([Vector2(0.5, 0.5), Vector2(3.5, 0.5)])
	var cb := PackedVector2Array([Vector2(0.5, 0.5), Vector2(3.5, 0.5)])
	var cong := RouteMetrics.congestion([ca, cb])
	_check_eq(cong["max_overlap"], 2, "congestion max_overlap = 2 when two routes share a corridor")
	_check(cong["total_repeated"] >= 1, "congestion total_repeated > 0 for a shared corridor")
	_check(cong["occupied_buckets"] >= 1, "congestion reports occupied buckets")

	var board = RoutingLabScenarios.make_open_board(8, 6)
	var ti = board.get_cell_index(6, 3); board.set_cell_state(ti, BoardState.CellState.ACTIVE)
	var acc = PrototypeAccessQuery.new(board)
	var rq = [RouteRequest.for_target(board, Vector2(-2.0, 3.5), ti)]
	var cpu := RouteMetrics.cpu_benchmark(DirectRoutePrototype.new(), rq, board, acc, 2)
	_check(cpu.has("total_us") and cpu.has("mean_us"), "cpu_benchmark reports CPU microseconds")
	_check(not cpu.has("fps") and not cpu.has("gpu"), "cpu_benchmark makes NO FPS/GPU claim")
	_check_eq(cpu["success"], 1, "cpu_benchmark separates successful route count")

	var setA := [PackedVector2Array([Vector2(0, 0), Vector2(1, 1)])]
	var setB := [PackedVector2Array([Vector2(0, 0), Vector2(1, 2)])]
	_check(RouteMetrics.route_sets_identical(setA, setA)["identical"], "determinism: identical sets compare identical")
	_check(not RouteMetrics.route_sets_identical(setA, setB)["identical"], "determinism: a changed route is detected")

func _run_m17_scale_tests() -> void:
	print("---- M17: multi-route scale (5/10/25/stress/59x59/rect) ----")
	var cases := [
		{"sc": RoutingLabScenarios.make_s5(5), "n": 5, "w": 30, "h": 30},
		{"sc": RoutingLabScenarios.make_s5(10), "n": 10, "w": 30, "h": 30},
		{"sc": RoutingLabScenarios.make_s5(25), "n": 25, "w": 30, "h": 30},
		{"sc": RoutingLabScenarios.make_s6(50), "n": 50, "w": 40, "h": 40},
		{"sc": RoutingLabScenarios.make_s7(25), "n": 25, "w": 59, "h": 59},
		{"sc": RoutingLabScenarios.make_s8(25), "n": 25, "w": 53, "h": 59},
	]
	for case in cases:
		var sc: Dictionary = case["sc"]
		var board = sc["board"]
		_check_eq(board.get_width(), case["w"], "%s board width %d" % [sc["id"], case["w"]])
		_check_eq(board.get_height(), case["h"], "%s board height %d" % [sc["id"], case["h"]])
		var access = PrototypeAccessQuery.new(board)
		var reqs: Array = RoutingLabScenarios.build_requests(board, sc["targets"], sc["origins"])
		_check(reqs.size() == case["n"], "%s builds %d requests" % [sc["id"], case["n"]])
		var grid = GridRoutePrototype.new()
		var success := 0
		var valid := 0
		for req in reqs:
			var res = grid.compute_route(req, board, access)
			if res.success:
				success += 1
				if RouteValidator.validate_route(req, res, board, access) == RouteResult.FailureReason.NONE:
					valid += 1
		_check(success > 0, "%s: grid produces successful routes (success=%d)" % [sc["id"], success])
		_check_eq(valid, success, "%s: every grid success passes the shared RouteValidator" % sc["id"])

func _run_m17_lab_scene_smoke() -> void:
	print("---- M17: routing prototype lab scene smoke ----")
	var scene = load("res://scenes/debug/routing_prototype_lab.tscn")
	_check(scene != null, "lab scene resource loads")
	if scene == null:
		return
	var inst = scene.instantiate()
	_check(inst != null, "lab scene instantiates")
	root.add_child(inst)
	if inst._info_label == null:
		inst._build_ui()
	_check(not inst.has_method("select_and_reserve"), "lab has NO target-selection method")

	inst._scenario_option.select(0)
	for si in range(3):
		inst._strategy_option.select(si)
		inst._rebuild()
		var txt: String = inst._info_label.text
		_check(txt.find(inst.STRATEGY_NAMES[si]) >= 0, "lab shows strategy '%s' after switch" % inst.STRATEGY_NAMES[si])
		_check(txt.find("success=") >= 0, "lab metric panel reports success counts for '%s'" % inst.STRATEGY_NAMES[si])
		_check(txt.find("CPU") >= 0 and txt.find("no FPS/GPU") >= 0, "lab CPU metric makes no FPS/GPU claim for '%s'" % inst.STRATEGY_NAMES[si])
		_check(txt.find("DETERMINISM: identical=true") >= 0, "lab reports deterministic routes for '%s'" % inst.STRATEGY_NAMES[si])

	inst._scenario_option.select(2)
	inst._strategy_option.select(1)
	inst._rebuild()
	_check(inst._info_label.text.find("no_route=1") >= 0, "lab surfaces the enclosed no-route case (no_route=1)")

	inst._scenario_option.select(4)
	inst._botcount_option.select(2)
	inst._strategy_option.select(1)
	inst._rebuild()
	_check(inst._info_label.text.find("requests=10") >= 0, "lab bot-count selector yields 10 requests for S5")
	inst.queue_free()

# ======================================================= M17-C002 production ==
# Owner-selected production routing (OWNER_MOVEMENT_DECISION_V01): Organized/
# curved movement language on a deterministic grid-aware backbone. Direct stays
# debug/prototype only. Production defaults are more conservative than the M17
# experimental Organized prototype. Production lives outside prototypes/.

func _m17c002_max_seg(p: PackedVector2Array) -> float:
	var m := 0.0
	for i in range(p.size() - 1):
		m = maxf(m, p[i].distance_to(p[i + 1]))
	return m

func _run_m17c002_production_routing_tests() -> void:
	print("---- M17-C002: production routing (organized/curved + grid) ----")
	# Production derives from a valid grid route (S2 detour), validates, and is
	# organized/curved (more than a single straight segment).
	var s2 := RoutingLabScenarios.make_s2()
	var b2 = s2["board"]
	var a2 = ProductionAccessQuery.new(b2)
	var q2 = RoutingLabScenarios.build_requests(b2, s2["targets"], s2["origins"])[0]
	var prod = ProductionRoutingSystem.new()
	var r2 = prod.compute_route(q2, b2, a2)
	_check(r2.success, "production routes the S2 detour (derives from valid grid path)")
	var pts2: PackedVector2Array = r2.get_points()
	_check(pts2.size() > 2, "production route is organized/curved, not a single straight segment")
	_check(_m17_all_segments_open(pts2, a2, q2.target_index), "production: every emitted segment passes access truth (no invalid shortcut)")
	_check_eq(RouteValidator.validate_route(q2, r2, b2, a2), RouteResult.FailureReason.NONE, "production route validates end-to-end")
	_check_eq(r2.target_index, q2.target_index, "production keeps the assigned target identity")

	# Contract signature + no selection/reservation API.
	_check(prod.has_method("compute_route"), "production exposes compute_route (M16 signature)")
	_check(not prod.has_method("select_and_reserve"), "production has NO target-selection method")

	# No BoardState / ReservationState mutation.
	var before := _snapshot_cell_states(b2)
	var reservations = ReservationState.new()
	reservations.bind(b2)
	_check(reservations.reserve(q2.target_index, 0), "precondition: target reserved for owner 0")
	prod.compute_route(q2, b2, a2)
	_check(_cell_states_equal(b2, before), "production does not mutate BoardState")
	_check_eq(reservations.get_owner(q2.target_index), 0, "production does not touch ReservationState ownership")

	# Determinism.
	var r2b = ProductionRoutingSystem.new().compute_route(q2, b2, a2)
	_check(RouteMetrics.points_equal(pts2, r2b.get_points()), "production is deterministic (identical points on repeat)")

	# Blocked interior target -> no route, no retarget.
	var s3 := RoutingLabScenarios.make_s3()
	var b3 = s3["board"]
	var a3 = ProductionAccessQuery.new(b3)
	var q3 = RoutingLabScenarios.build_requests(b3, s3["targets"], s3["origins"])[0]
	var r3 = ProductionRoutingSystem.new().compute_route(q3, b3, a3)
	_check(not r3.success, "production returns no route for a fully enclosed target")
	_check_eq(r3.failure_reason, RouteResult.FailureReason.NO_ROUTE, "enclosed target -> NO_ROUTE")
	_check_eq(r3.target_index, q3.target_index, "enclosed failure keeps the SAME target (no retarget)")

	# Newly-opened-after-clear -> same target routes.
	var s4 := RoutingLabScenarios.make_s4()
	var b4 = s4["board"]
	var q4 = RoutingLabScenarios.build_requests(b4, s4["targets"], s4["origins"])[0]
	var before4 = ProductionRoutingSystem.new().compute_route(q4, b4, ProductionAccessQuery.new(b4))
	_check(not before4.success, "S4 precondition: enclosed target has no route")
	for ci in s4["clear_after"]:
		b4.set_cell_state(int(ci), BoardState.CellState.CLEARED)
	var a4 = ProductionAccessQuery.new(b4)
	var after4 = ProductionRoutingSystem.new().compute_route(q4, b4, a4)
	_check(after4.success, "S4: same target routes once prerequisite cells are CLEARED")
	_check_eq(after4.target_index, q4.target_index, "S4: target identity unchanged after opening")
	_check_eq(RouteValidator.validate_route(q4, after4, b4, a4), RouteResult.FailureReason.NONE, "S4 opened production route validates")

	# Production defaults are more conservative than the experimental Organized
	# prototype defaults: on 59x59 it keeps more of the orthogonal path (more
	# points, >= distance) and avoids long board-spanning diagonals (smaller max
	# segment). Direct evidence, not a claim.
	var s7 := RoutingLabScenarios.make_s7(25)
	var b7 = s7["board"]
	var a7 = ProductionAccessQuery.new(b7)
	var reqs7 = RoutingLabScenarios.build_requests(b7, s7["targets"], s7["origins"])
	var prod_pts := 0; var exp_pts := 0
	var prod_dist := 0.0; var exp_dist := 0.0
	var prod_max := 0.0; var exp_max := 0.0
	var prod_succ := 0; var prod_valid := 0
	var org_exp = OrganizedRoutePrototype.new()
	for req in reqs7:
		var rp = ProductionRoutingSystem.new().compute_route(req, b7, a7)
		var re = org_exp.compute_route(req, b7, a7)
		if rp.success:
			prod_succ += 1
			var pp: PackedVector2Array = rp.get_points()
			prod_pts += pp.size(); prod_dist += RouteMetrics.route_distance(pp); prod_max = maxf(prod_max, _m17c002_max_seg(pp))
			if RouteValidator.validate_route(req, rp, b7, a7) == RouteResult.FailureReason.NONE:
				prod_valid += 1
		if re.success:
			var ep: PackedVector2Array = re.get_points()
			exp_pts += ep.size(); exp_dist += RouteMetrics.route_distance(ep); exp_max = maxf(exp_max, _m17c002_max_seg(ep))
	_check(prod_succ == reqs7.size(), "production solves all 59x59 routes (success=%d)" % prod_succ)
	_check_eq(prod_valid, prod_succ, "every production 59x59 route passes the shared RouteValidator")
	_check(prod_pts > exp_pts, "production keeps MORE points than experimental (less aggressive: %d > %d)" % [prod_pts, exp_pts])
	_check(prod_dist >= exp_dist, "production distance >= experimental (keeps orthogonal path: %.1f >= %.1f)" % [prod_dist, exp_dist])
	_check(prod_max < exp_max, "production avoids long diagonals (max seg %.1f < experimental %.1f)" % [prod_max, exp_max])
	# Production default config is more conservative than the experimental default.
	_check(prod.max_shortcut_span < 2147483647, "production shortcut span is bounded")
	_check(prod.corner_radius < org_exp.corner_radius, "production corner_radius (%.2f) < experimental (%.2f)" % [prod.corner_radius, org_exp.corner_radius])

	# Rectangular Very Hard coverage (53x59).
	var s8 := RoutingLabScenarios.make_s8(25)
	var b8 = s8["board"]
	var a8 = ProductionAccessQuery.new(b8)
	var reqs8 = RoutingLabScenarios.build_requests(b8, s8["targets"], s8["origins"])
	_check_eq(b8.get_width(), 53, "rectangular VH width 53")
	_check_eq(b8.get_height(), 59, "rectangular VH height 59")
	var s8_ok := 0
	for req in reqs8:
		var res = ProductionRoutingSystem.new().compute_route(req, b8, a8)
		if res.success and RouteValidator.validate_route(req, res, b8, a8) == RouteResult.FailureReason.NONE:
			s8_ok += 1
	_check_eq(s8_ok, reqs8.size(), "all rectangular VH production routes validate")

# ============================================================= M18 agent =====
# Lightweight ScrubbotAgent: consumes a finished production route, walks it in
# board-local coordinates, emits completion exactly once, mutates nothing.

## Build a real (request, production route, board) for scenario request `i`.
func _m18_route(scenario: Dictionary, i: int) -> Dictionary:
	var board = scenario["board"]
	var access = ProductionAccessQuery.new(board)
	var reqs: Array = RoutingLabScenarios.build_requests(board, scenario["targets"], scenario["origins"])
	var req = reqs[i]
	var route = ProductionRoutingSystem.new().compute_route(req, board, access)
	return {"board": board, "access": access, "req": req, "route": route}

func _m18_run_to_arrival(agent) -> void:
	# Big deterministic delta; distance-based movement snaps exactly at the end.
	for _i in range(64):
		if not agent.is_moving():
			break
		agent.advance(1.0)

## Assign into a throwaway agent and free it — proves a rejection without
## leaking an unparented Node.
func _m18_reject(a_owner: int, a_color: int, request, result) -> bool:
	var ag = ScrubbotAgent.new()
	var ok: bool = ag.assign(a_owner, a_color, request, result)
	ag.free()
	return not ok

func _run_m18_agent_tests() -> void:
	print("---- M18: lightweight Scrubbot agent ----")
	var s2 := RoutingLabScenarios.make_s2()
	var ctx := _m18_route(s2, 0)
	var board = ctx["board"]
	var req = ctx["req"]
	var route = ctx["route"]
	_check(route.success, "precondition: S2 produces a successful production route")
	var pts: PackedVector2Array = route.get_points()
	_check(pts.size() >= 2, "precondition: route has >=2 points")

	# --- assignment validation (fail closed) ------------------------------
	var a = ScrubbotAgent.new()
	_check(a.assign(0, 3, req, route, 6.0), "valid assignment succeeds")
	_check_eq(a.get_state(), ScrubbotAgent.State.MOVING, "valid assignment -> MOVING")

	_check(_m18_reject(-1, 3, req, route), "invalid owner rejected")
	_check(_m18_reject(0, -1, req, route), "invalid color rejected")

	var bad_target = RouteRequest.new()
	bad_target.target_index = -1
	bad_target.start_position = req.start_position
	bad_target.target_position = req.target_position
	_check(_m18_reject(0, 3, bad_target, route), "invalid target rejected")

	var failed = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, req.target_index)
	_check(_m18_reject(0, 3, req, failed), "failed RouteResult rejected")

	var mismatch = RouteResult.success_route(req.target_index + 777, pts)
	_check(_m18_reject(0, 3, req, mismatch), "route target mismatch rejected")

	var moved_pts := pts.duplicate()
	moved_pts[0] = moved_pts[0] + Vector2(5.0, 5.0)
	var spawn_bad = RouteResult.success_route(req.target_index, moved_pts)
	_check(_m18_reject(0, 3, req, spawn_bad), "spawn origin mismatch rejected")

	# --- assigned data retained ------------------------------------------
	_check_eq(a.color_id, 3, "assigned color retained")
	_check_eq(a.target_index, req.target_index, "assigned target retained")
	_check_eq(a.spawn_origin, req.start_position, "assigned spawn origin retained")
	var detached := a.get_route_points()
	detached[0] = Vector2(999.0, 999.0) # mutate the copy...
	_check(a.get_route_points()[0].is_equal_approx(pts[0]), "detached assigned route retained safely (copy mutation does not leak)")

	# --- movement ---------------------------------------------------------
	_check(a.get_local_position().is_equal_approx(pts[0]), "movement begins at spawn origin")
	a.advance(0.01)
	_check(a.get_progress() > 0.0 and a.get_progress() < 1.0, "small delta advances correctly")

	# Zero delta does not move.
	var before_zero := a.get_local_position()
	var prog_zero := a.get_progress()
	a.advance(0.0)
	_check(a.get_local_position().is_equal_approx(before_zero), "zero delta does not move")
	_check_eq(a.get_progress(), prog_zero, "zero delta leaves progress unchanged")

	# Large delta traverses multiple segments == many small deltas (distance
	# based, not per-frame point skipping).
	var big = ScrubbotAgent.new()
	big.assign(0, 3, req, route, 6.0)
	var small = ScrubbotAgent.new()
	small.assign(0, 3, req, route, 6.0)
	big.advance(0.5)
	for _k in range(50):
		small.advance(0.01) # 50 * 0.01 = 0.5 total
	_check(big.get_local_position().is_equal_approx(small.get_local_position()), "large delta traverses multiple segments correctly (== summed small deltas)")

	# --- arrival ----------------------------------------------------------
	var hits: Array = []
	a.agent_completed.connect(func(o, t, c): hits.append([o, t, c]))
	_m18_run_to_arrival(a)
	_check(a.has_arrived(), "agent reaches ARRIVED")
	_check(a.get_local_position().is_equal_approx(pts[pts.size() - 1]), "route endpoint is reached exactly")
	# Advance again past the end — must not re-emit or move.
	var end_pos := a.get_local_position()
	a.advance(10.0)
	_check(a.get_local_position().is_equal_approx(end_pos), "no return movement after arrival")
	_check_eq(hits.size(), 1, "arrival emitted exactly once")
	if hits.size() == 1:
		_check(hits[0][0] == 0 and hits[0][1] == req.target_index and hits[0][2] == 3, "completion identity is correct (owner/target/color)")

	# --- no BoardState / ReservationState mutation ------------------------
	var s2b := RoutingLabScenarios.make_s2()
	var ctxb := _m18_route(s2b, 0)
	var boardb = ctxb["board"]
	var before_states := _snapshot_cell_states(boardb)
	var reservations = ReservationState.new()
	reservations.bind(boardb)
	reservations.reserve(ctxb["req"].target_index, 0)
	var a2 = ScrubbotAgent.new()
	a2.assign(0, 3, ctxb["req"], ctxb["route"], 6.0)
	_m18_run_to_arrival(a2)
	_check(a2.has_arrived(), "precondition: agent arrived for mutation check")
	_check(_cell_states_equal(boardb, before_states), "BoardState not mutated by agent")
	_check_eq(reservations.get_owner(ctxb["req"].target_index), 0, "ReservationState not mutated by agent")

	# --- no resource-carry / no return / no routing-or-selection API ------
	_check(not a.has_method("get_carried_color"), "no resource-carry state/API (get_carried_color)")
	_check(not a.has_method("get_payload"), "no resource-carry state/API (get_payload)")
	_check(not a.has_method("deliver"), "no slot-delivery API (deliver)")
	_check(not a.has_method("return_to_slot"), "no return-to-slot API")
	_check(not a.has_method("compute_route"), "no route computation call (no compute_route)")
	_check(not a.has_method("select_and_reserve"), "no TargetSelector call (no select_and_reserve)")
	_check(not a.has_method("select_target"), "no TargetSelector call (no select_target)")
	_check(not a.has_method("dispatch") and not a.has_method("dispatch_next"), "no Dispatcher implementation on agent")

	# --- cancel / reset ---------------------------------------------------
	var c = ScrubbotAgent.new()
	c.assign(0, 3, req, route, 6.0)
	c.advance(0.05)
	var cancel_pos := c.get_local_position()
	c.cancel()
	_check(c.is_cancelled(), "cancel sets CANCELLED state")
	c.advance(10.0)
	_check(c.get_local_position().is_equal_approx(cancel_pos), "cancel before arrival stops movement")

	var c2 = ScrubbotAgent.new()
	var c2hits: Array = []
	c2.agent_completed.connect(func(_o, _t, _cc): c2hits.append(1))
	c2.assign(0, 3, req, route, 6.0)
	c2.cancel()
	c2.advance(10.0) # would have arrived if still moving
	_check_eq(c2hits.size(), 0, "cancel prevents later completion")
	_check(not c2.has_arrived(), "cancelled agent never reports ARRIVED")

	c2.cancel(); c2.cancel() # repeated cancel is safe
	_check(c2.is_cancelled() and c2hits.size() == 0, "repeated cancel is safe")

	# --- no orphan nodes --------------------------------------------------
	_check_eq(c.get_child_count(), 0, "cancelled agent owns no child nodes")
	c.free()
	var done = ScrubbotAgent.new()
	done.assign(0, 3, req, route, 6.0)
	_m18_run_to_arrival(done)
	_check_eq(done.get_child_count(), 0, "completed agent owns no child nodes")
	done.free()
	a.free(); a2.free(); big.free(); small.free(); c2.free()

	# --- determinism ------------------------------------------------------
	var d1 = ScrubbotAgent.new(); d1.assign(0, 3, req, route, 6.0)
	var d2 = ScrubbotAgent.new(); d2.assign(0, 3, req, route, 6.0)
	var identical := true
	for _s in range(30):
		d1.advance(0.03); d2.advance(0.03)
		if not d1.get_local_position().is_equal_approx(d2.get_local_position()):
			identical = false
	_check(identical, "deterministic repeated movement for same route/delta sequence")
	d1.free(); d2.free()

	# --- 59x59 + rectangular Very Hard route compatibility ----------------
	var s7 := RoutingLabScenarios.make_s7(9)
	var ctx7 := _m18_route(s7, 0)
	_check(ctx7["route"].success, "precondition: 59x59 production route succeeds")
	var a7 = ScrubbotAgent.new()
	_check(a7.assign(0, 5, ctx7["req"], ctx7["route"], 8.0), "agent accepts 59x59 route (coordinate compatibility)")
	_m18_run_to_arrival(a7)
	_check(a7.has_arrived() and a7.get_local_position().is_equal_approx(ctx7["route"].get_points()[ctx7["route"].point_count() - 1]), "59x59 route reaches exact endpoint")
	a7.free()

	var s8 := RoutingLabScenarios.make_s8(9)
	var ctx8 := _m18_route(s8, 0)
	_check(ctx8["route"].success, "precondition: rectangular VH (53x59) route succeeds")
	var a8 = ScrubbotAgent.new()
	_check(a8.assign(0, 5, ctx8["req"], ctx8["route"], 8.0), "agent accepts rectangular Very Hard route")
	_m18_run_to_arrival(a8)
	_check(a8.has_arrived(), "rectangular Very Hard route completes")
	a8.free()

## Concurrent multi-agent CPU/lifecycle stress. Precomputed valid routes; no
## Dispatcher. Measures CPU/node behaviour only — NO FPS/GPU claim from headless.
func _run_m18_agent_lifecycle_reentry_tests() -> void:
	# F-M18-STRICT-001 / AL-037: ScrubbotAgent is single-use. assign() succeeds
	# ONLY from UNASSIGNED; re-entry while MOVING/ARRIVED/CANCELLED must fail
	# closed and preserve all state, and agent reuse can never emit a second
	# completion. Uses a SECOND independently-valid route so rejection is proven
	# to come from re-entry, not from malformed data.
	print("---- M18: single-use lifecycle re-entry (adversarial) ----")
	var ctxA := _m18_route(RoutingLabScenarios.make_s1(), 0)
	var ctxB := _m18_route(RoutingLabScenarios.make_s1(), 1)
	_check(ctxA["route"].success and ctxB["route"].success, "precondition: two independent valid routes exist")

	# Prove route B is valid on a FRESH agent — so later rejections are pure re-entry.
	var probe = ScrubbotAgent.new()
	_check(probe.assign(1, 4, ctxB["req"], ctxB["route"], 6.0), "the second route assigns on a fresh UNASSIGNED agent (independently valid)")
	probe.free()

	# 1) valid first assign from UNASSIGNED.
	var comp: Array = []
	var a = ScrubbotAgent.new()
	a.agent_completed.connect(func(_o, _t, _c): comp.append(1))
	_check(a.assign(0, 3, ctxA["req"], ctxA["route"], 6.0), "valid first assign succeeds (from UNASSIGNED)")
	_check_eq(a.get_state(), ScrubbotAgent.State.MOVING, "first assign -> MOVING")
	a.advance(0.01) # some progress, still MOVING.

	# Snapshot every field the re-entry must preserve.
	var s_owner: int = a.owner_id
	var s_color: int = a.color_id
	var s_target: int = a.target_index
	var s_spawn: Vector2 = a.spawn_origin
	var s_tpos: Vector2 = a.target_position
	var s_pts: PackedVector2Array = a.get_route_points()
	var s_prog: float = a.get_progress()
	var s_pos: Vector2 = a.get_local_position()

	# 2) valid second assign while MOVING fails.
	_check(not a.assign(1, 4, ctxB["req"], ctxB["route"], 9.0), "valid second assign while MOVING fails (single-use)")
	# 3) MOVING re-entry failure preserves ALL identity/route/progress/position.
	_check_eq(a.get_state(), ScrubbotAgent.State.MOVING, "MOVING re-entry: state preserved")
	_check_eq(a.owner_id, s_owner, "MOVING re-entry: owner_id preserved")
	_check_eq(a.color_id, s_color, "MOVING re-entry: color_id preserved")
	_check_eq(a.target_index, s_target, "MOVING re-entry: target_index preserved")
	_check(a.spawn_origin.is_equal_approx(s_spawn), "MOVING re-entry: spawn_origin preserved")
	_check(a.target_position.is_equal_approx(s_tpos), "MOVING re-entry: target_position preserved")
	_check(_m18_points_equal(a.get_route_points(), s_pts), "MOVING re-entry: route points preserved")
	_check(absf(a.get_progress() - s_prog) < 1e-6, "MOVING re-entry: movement progress preserved")
	_check(a.get_local_position().is_equal_approx(s_pos), "MOVING re-entry: current position preserved")
	_check_eq(comp.size(), 0, "MOVING re-entry: no completion emitted")

	# Drive to arrival: exactly one completion.
	_m18_run_to_arrival(a)
	_check(a.has_arrived(), "agent reaches ARRIVED")
	_check_eq(comp.size(), 1, "exactly one completion on arrival")
	var end_pos: Vector2 = a.get_local_position()

	# 4) valid second assign after ARRIVED fails; 5) ARRIVED truth preserved.
	_check(not a.assign(1, 4, ctxB["req"], ctxB["route"], 9.0), "valid second assign after ARRIVED fails")
	_check(a.has_arrived(), "ARRIVED re-entry: still ARRIVED")
	_check(a.get_local_position().is_equal_approx(end_pos), "ARRIVED re-entry: endpoint position unchanged")
	_check_eq(comp.size(), 1, "ARRIVED re-entry: completion count still 1")
	# 9) reuse cannot create a second completion, even with more advancing.
	a.advance(100.0)
	_check_eq(comp.size(), 1, "agent reuse cannot emit a second completion event")
	a.free()

	# 6) valid second assign after CANCELLED fails; 7) CANCELLED truth preserved.
	var b = ScrubbotAgent.new()
	b.assign(0, 3, ctxA["req"], ctxA["route"], 6.0)
	b.advance(0.05)
	b.cancel()
	var b_pos: Vector2 = b.get_local_position()
	_check(b.is_cancelled(), "cancel of a MOVING agent -> CANCELLED")
	_check(not b.assign(1, 4, ctxB["req"], ctxB["route"], 9.0), "valid second assign after CANCELLED fails")
	_check(b.is_cancelled(), "CANCELLED re-entry: still CANCELLED")
	_check(b.get_local_position().is_equal_approx(b_pos), "CANCELLED re-entry: position unchanged")
	_check_eq(b.owner_id, 0, "CANCELLED re-entry: owner identity unchanged")
	_check_eq(b.color_id, 3, "CANCELLED re-entry: color identity unchanged")
	b.free()

	# 8) cancel after ARRIVED is a no-op (does NOT downgrade ARRIVED).
	var d = ScrubbotAgent.new()
	var dcomp: Array = []
	d.agent_completed.connect(func(_o, _t, _c): dcomp.append(1))
	d.assign(0, 3, ctxA["req"], ctxA["route"], 6.0)
	_m18_run_to_arrival(d)
	_check(d.has_arrived(), "precondition: d ARRIVED")
	d.cancel()
	_check(d.has_arrived(), "cancel after ARRIVED does NOT downgrade ARRIVED")
	_check(not d.is_cancelled(), "ARRIVED agent is not marked CANCELLED by cancel()")
	_check_eq(dcomp.size(), 1, "cancel after ARRIVED does not alter completion truth")
	d.free()

func _run_m18_multisegment_movement_tests() -> void:
	# F-M18-STRICT-002 / AL-038: prove distance-based movement crosses MULTIPLE
	# segment boundaries in ONE advance. Handcrafted route (0,0)->(1,0)->(1,1)->
	# (3,1): seg lengths 1,1,2 (total 4). A single advance of travelled 2.5 must
	# land on the THIRD segment at exactly (1.5,1). This assertion FAILS if the
	# implementation only advances within one segment per call.
	print("---- M18: observable multi-segment movement (handcrafted route) ----")
	var req = RouteRequest.new()
	req.target_index = 0
	req.start_position = Vector2(0, 0)
	req.target_position = Vector2(3, 1)
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(3, 1)])
	var route = RouteResult.success_route(0, pts)
	_check_eq(pts.size(), 4, "handcrafted route has 4 points / 3 segments (>=3)")
	_check(is_equal_approx(pts[0].distance_to(pts[1]), 1.0), "segment 0 length == 1")
	_check(is_equal_approx(pts[1].distance_to(pts[2]), 1.0), "segment 1 length == 1")
	_check(is_equal_approx(pts[2].distance_to(pts[3]), 2.0), "segment 2 length == 2 (total 4)")

	var comp: Array = []
	var a = ScrubbotAgent.new()
	a.agent_completed.connect(func(_o, _t, _c): comp.append(1))
	_check(a.assign(0, 2, req, route, 1.0), "handcrafted multi-segment route assigns (speed 1.0)")

	# One advance -> travelled 2.5: crosses boundary@1.0 (end seg0) AND boundary@2.0
	# (end seg1), lands 0.5 into seg2. Does NOT reach the endpoint (total 4).
	a.advance(2.5)
	_check(a.is_moving(), "still MOVING after a delta that crosses two boundaries (not finished)")
	_check(a.get_local_position().is_equal_approx(Vector2(1.5, 1.0)), "exact position on the THIRD segment (1.5,1) — multi-segment traversal proven")
	_check(absf(a.get_progress() - 0.625) < 1e-5, "exact progress 2.5/4 == 0.625")
	_check_eq(comp.size(), 0, "no completion before reaching the endpoint")

	# Huge delta crosses ALL remaining route and exact-snaps the endpoint once.
	a.advance(100.0)
	_check(a.has_arrived(), "huge delta reaches ARRIVED")
	_check(a.get_local_position().is_equal_approx(Vector2(3, 1)), "huge delta exact-snaps to endpoint (3,1)")
	_check_eq(comp.size(), 1, "completion emits exactly once on the huge-delta finish")
	a.advance(100.0)
	_check_eq(comp.size(), 1, "no second completion after arrival")
	a.free()

## Element-wise point-array equality (is_equal_approx per point) for the
## re-entry preservation checks.
func _m18_points_equal(p: PackedVector2Array, q: PackedVector2Array) -> bool:
	if p.size() != q.size():
		return false
	for i in range(p.size()):
		if not p[i].is_equal_approx(q[i]):
			return false
	return true

func _run_m18_agent_stress_tests() -> void:
	# F-M18-STRICT-003 / AL-036: isolate AGENT-LIFECYCLE cost. Every route is
	# precomputed AND verified successful BEFORE the timer starts; the timed
	# region contains only allocation + signal hookup + assign + deterministic
	# movement-to-completion + free. Route generation is timed separately and
	# labelled. Headless CPU/node behaviour only — no FPS/GPU/mobile-frame claim.
	print("---- M18: agent lifecycle isolation stress (CPU/node only; no FPS/GPU claim) ----")
	for count in [5, 10, 25, 40]:
		var scenario: Dictionary = RoutingLabScenarios.make_s6(count) if count > 25 else RoutingLabScenarios.make_s5(count)
		var board = scenario["board"]
		var access = ProductionAccessQuery.new(board)
		var reqs: Array = RoutingLabScenarios.build_requests(board, scenario["targets"], scenario["origins"])
		var label := "%d-agent" % count if count <= 25 else "stress %d-agent (>25)" % count

		# --- route generation: OUTSIDE the lifecycle timer -------------------
		var routes: Array = []
		var t_routes := Time.get_ticks_usec()
		for req in reqs:
			routes.append(ProductionRoutingSystem.new().compute_route(req, board, access))
		var route_ms := float(Time.get_ticks_usec() - t_routes) / 1000.0
		var routes_ok := 0
		for route in routes:
			if route.success:
				routes_ok += 1
		# Gate: only start lifecycle timing once ALL routes are known-good.
		_check_eq(routes_ok, reqs.size(), "%s: all routes precomputed AND verified successful before timing (%d)" % [label, routes_ok])
		if routes_ok != reqs.size():
			continue

		# --- timed region: agent lifecycle ONLY (routes already ready) -------
		var completions: Array = [] # lambdas capture primitives by value; Array is by-ref.
		var agents: Array = []
		var t0 := Time.get_ticks_usec()
		for i in range(reqs.size()):
			var ag = ScrubbotAgent.new()               # allocation
			ag.agent_completed.connect(func(_o, _t, _c): completions.append(1)) # signal hookup
			ag.assign(0, 4, reqs[i], routes[i], 8.0)   # assign
			root.add_child(ag)
			agents.append(ag)
		# Deterministic movement to completion (shared delta, concurrent).
		for _step in range(80):
			var still := false
			for ag in agents:
				if ag.is_moving():
					ag.advance(1.0)
					still = true
			if not still:
				break
		var arrived := 0
		var orphan_free := true
		for ag in agents:
			if ag.has_arrived():
				arrived += 1
			if ag.get_child_count() != 0:
				orphan_free = false
		for ag in agents:                              # free/cleanup
			ag.free()
		var lifecycle_ms := float(Time.get_ticks_usec() - t0) / 1000.0

		_check_eq(arrived, agents.size(), "%s: all agents reach ARRIVED via deterministic movement" % label)
		_check_eq(completions.size(), agents.size(), "%s: completion signal fired once per agent" % label)
		_check(orphan_free, "%s: no agent owns child/orphan nodes" % label)
		print("     M18 lifecycle-ISOLATED %s: %d agents, alloc+assign+move+free CPU=%.2f ms | route-gen (separate)=%.2f ms (headless CPU only, no FPS/GPU claim)" % [label, agents.size(), lifecycle_ms, route_ms])
	# Pooling decision — wording limited to what this headless lifecycle test shows.
	print("     M18 pooling: NOT added. Isolated headless agent-lifecycle timing")
	print("     (alloc+assign+move+free, routes precomputed) shows no justification")
	print("     for pooling under THIS test. The agent is a childless Node2D with no")
	print("     per-frame allocation. This is headless CPU/node evidence only — not")
	print("     an FPS/GPU/mobile-frame result. Pooling stays deferred to real")
	print("     profiling if future evidence justifies it. (SB-M18-014/015, AL-036)")

func _run_m18_agent_debug_scene_smoke() -> void:
	print("---- M18: agent debug scene smoke ----")
	var scene = load("res://scenes/debug/scrubbot_agent_debug.tscn")
	_check(scene != null, "agent debug scene resource loads")
	if scene == null:
		return
	var inst = scene.instantiate()
	_check(inst != null, "agent debug scene instantiates")
	root.add_child(inst)
	if inst.agent == null:
		inst.build()
	_check(inst.agent != null, "debug scene builds one agent")
	_check(inst.agent.is_moving(), "debug scene agent starts MOVING on a real route")
	for _i in range(64):
		if not inst.agent.is_moving():
			break
		inst.agent.advance(1.0)
	_check(inst.agent.has_arrived(), "debug scene agent completes its route")
	_check(inst.completed, "debug scene received the completion signal")
	inst.free()

# ============================================================= M19 dispatch ===
# ScrubbotDispatcher: orchestration only. One slot/color request -> at most one
# ScrubbotAgent, via select_and_reserve -> route -> assign, with full rollback on
# any failure and no BoardState mutation. These tests use deterministic fakes for
# fault injection; _run_m19_dispatcher_production_tests exercises the real
# production selection+routing pipeline on large boards.

## Open board (all CLEARED) with the given (x,y) cells forced ACTIVE.
func _m19_open_board_active(w: int, h: int, cells: Array) -> Object:
	var board = RoutingLabScenarios.make_open_board(w, h)
	for c in cells:
		board.set_cell_state(board.get_cell_index(int(c.x), int(c.y)), BoardState.CellState.ACTIVE)
	return board

## Wire a dispatcher over `board` with a configurable fake routing system and an
## AccessQueryDouble reachability truth. Returns the pieces for assertions.
func _m19_wire_fake(board, routing_mode: String, targetable: Array) -> Dictionary:
	var reservations = ReservationState.new()
	reservations.bind(board)
	var candidates = ColorCandidateIndex.create()
	candidates.bind(board)
	var selector = TargetSelector.create()
	selector.bind(board, candidates, reservations)
	var routing = DispatchRoutingDouble.new()
	routing.mode = routing_mode
	var access = AccessQueryDouble.new()
	access.set_all_targetable(targetable)
	var dispatcher = ScrubbotDispatcher.new()
	root.add_child(dispatcher)
	# routing_access is opaque to the fake routing; pass a real non-null query.
	dispatcher.bind(board, selector, reservations, routing, ProductionAccessQuery.new(board), access)
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"selector": selector, "routing": routing, "access": access, "dispatcher": dispatcher}

func _m19_teardown(w: Dictionary) -> void:
	var d = w["dispatcher"]
	d.reset()
	root.remove_child(d)
	d.free()

func _m19_drive_to_arrival(agent) -> void:
	for _i in range(128):
		if not agent.is_moving():
			break
		agent.advance(1.0)

func _run_m19_dispatcher_tests() -> void:
	print("---- M19: dispatcher orchestration (deterministic fakes) ----")
	# Five same-color candidates in row 5 (shared color = row-banded palette id).
	var active := [Vector2(2, 5), Vector2(4, 5), Vector2(6, 5), Vector2(8, 5), Vector2(10, 5)]
	var origin := Vector2(-2.0, 5.5)

	# --- happy path: one valid dispatch -----------------------------------
	var b1 = _m19_open_board_active(14, 11, active)
	var color: int = b1.get_color_id(b1.get_cell_index(2, 5))
	var w1 = _m19_wire_fake(b1, "ok", [b1.get_cell_index(2, 5), b1.get_cell_index(4, 5),
		b1.get_cell_index(6, 5), b1.get_cell_index(8, 5), b1.get_cell_index(10, 5)])
	var before1 = _snapshot_cell_states(b1)
	var r1 = w1["dispatcher"].dispatch(color, origin, 6.0)
	_check(r1.success, "valid slot/color request succeeds (SB-M19-001/006)")
	_check_eq(r1.owner_id, 0, "first dispatch owner id is 0 (unique monotonic)")
	_check(r1.agent != null, "successful dispatch returns exactly one agent")
	_check_eq(w1["dispatcher"].get_active_count(), 1, "exactly one agent active after one dispatch")
	_check_eq(r1.agent.owner_id, r1.owner_id, "agent identity: owner id matches")
	_check_eq(r1.agent.color_id, color, "agent identity: color matches request")
	_check_eq(r1.agent.target_index, r1.target_index, "agent identity: target matches reserved target")
	var pts1: PackedVector2Array = r1.agent.get_route_points()
	_check_eq(pts1[pts1.size() - 1], Vector2(b1.get_cell_position(r1.target_index)) + Vector2(0.5, 0.5), "route endpoint equals reserved target centre (route target == reservation)")
	_check_eq(w1["reservations"].get_owner(r1.target_index), r1.owner_id, "target atomically reserved for the dispatch owner")
	_check(_cell_states_equal(b1, before1), "dispatch does not mutate BoardState (SB-M19: no clearing)")
	# Successful reservation stays held after dispatch (M20 resolves it, not M19).
	_check(w1["reservations"].is_reserved(r1.target_index), "successful reservation remains held after dispatch")

	# --- two independent targets -> two unique agents/owners --------------
	var r1b = w1["dispatcher"].dispatch(color, origin, 6.0)
	_check(r1b.success, "second reachable target dispatches independently")
	_check(r1b.owner_id != r1.owner_id, "owner ids are unique across dispatches")
	_check(r1b.target_index != r1.target_index, "duplicate target not assigned twice (distinct target)")
	_check_eq(w1["dispatcher"].get_active_count(), 2, "two independent agents active")

	# --- completion is observed only (no clear, no release) ---------------
	_m19_drive_to_arrival(r1.agent)
	_check(r1.agent.has_arrived(), "dispatched agent reaches its target")
	_check(w1["dispatcher"].has_arrived(r1.owner_id), "dispatcher observes completion (lifecycle only)")
	_check(_cell_states_equal(b1, before1), "agent completion does NOT clear BoardState in M19")
	_check(w1["reservations"].is_reserved(r1.target_index), "agent completion does NOT release the reservation in M19")
	_check_eq(b1.get_cell_state(r1.target_index), BoardState.CellState.ACTIVE, "arrived target cell still ACTIVE (no M20 clearing)")
	_m19_teardown(w1)

	# --- invalid request --------------------------------------------------
	var b2 = _m19_open_board_active(14, 11, active)
	var w2 = _m19_wire_fake(b2, "ok", [b2.get_cell_index(2, 5)])
	var color2: int = b2.get_color_id(b2.get_cell_index(2, 5))
	_check_eq(w2["dispatcher"].dispatch(-1, origin).failure_reason, DispatchResult.FailureReason.INVALID_REQUEST, "negative color -> INVALID_REQUEST")
	_check_eq(w2["dispatcher"].dispatch(color2, Vector2(INF, 0.0)).failure_reason, DispatchResult.FailureReason.INVALID_REQUEST, "non-finite origin -> INVALID_REQUEST")
	_check_eq(w2["dispatcher"].get_active_count(), 0, "invalid requests spawn nothing")
	_check_eq(w2["reservations"].get_reservation_count(), 0, "invalid requests reserve nothing")
	_m19_teardown(w2)

	# --- no raw candidates -> no spawn ------------------------------------
	var b3 = _m19_open_board_active(14, 11, active)
	var w3 = _m19_wire_fake(b3, "ok", [])
	var absent_color := 99
	_check(not w3["candidates"].has_candidates(absent_color), "precondition: color has no raw candidates")
	_check_eq(w3["dispatcher"].dispatch(absent_color, origin).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "no candidates -> NO_REACHABLE_TARGET (no spawn)")
	_check_eq(w3["dispatcher"].get_active_count(), 0, "no candidates -> zero agents")
	_m19_teardown(w3)

	# --- raw candidate exists but unreachable -> no spawn -----------------
	var b4 = _m19_open_board_active(14, 11, active)
	var color4: int = b4.get_color_id(b4.get_cell_index(2, 5))
	var w4 = _m19_wire_fake(b4, "ok", []) # AccessQueryDouble default: nothing targetable.
	_check(w4["candidates"].has_candidates(color4), "precondition: raw candidates DO exist")
	var r4 = w4["dispatcher"].dispatch(color4, origin)
	_check_eq(r4.failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "raw-but-unreachable candidate -> NO_REACHABLE_TARGET")
	_check_eq(w4["dispatcher"].get_active_count(), 0, "unreachable candidate -> zero agents")
	_check_eq(w4["reservations"].get_reservation_count(), 0, "unreachable candidate -> zero reservations")
	_m19_teardown(w4)

	# --- route failure -> release reservation, zero spawn, no retarget ----
	var b5 = _m19_open_board_active(14, 11, active)
	var color5: int = b5.get_color_id(b5.get_cell_index(2, 5))
	var w5 = _m19_wire_fake(b5, "fail", [b5.get_cell_index(2, 5), b5.get_cell_index(4, 5)])
	var r5 = w5["dispatcher"].dispatch(color5, origin)
	_check_eq(r5.failure_reason, DispatchResult.FailureReason.ROUTE_FAILED, "route failure -> ROUTE_FAILED")
	_check_eq(r5.target_index, -1, "route failure result carries no target (no silent retarget)")
	_check_eq(w5["dispatcher"].get_active_count(), 0, "route failure spawns zero agents")
	_check_eq(w5["reservations"].get_reservation_count(), 0, "route failure releases the reservation")
	# Released-after-failure target can dispatch later (flip routing to ok).
	w5["routing"].mode = "ok"
	var r5b = w5["dispatcher"].dispatch(color5, origin)
	_check(r5b.success, "failure-released target is dispatchable again")
	_m19_teardown(w5)

	# --- agent assign failure -> release, free, no orphan -----------------
	var b6 = _m19_open_board_active(14, 11, active)
	var color6: int = b6.get_color_id(b6.get_cell_index(2, 5))
	var w6 = _m19_wire_fake(b6, "mismatch", [b6.get_cell_index(2, 5)])
	var child_before: int = w6["dispatcher"].get_child_count()
	var r6 = w6["dispatcher"].dispatch(color6, origin)
	_check_eq(r6.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "assign failure -> AGENT_ASSIGN_FAILED")
	_check_eq(w6["dispatcher"].get_active_count(), 0, "assign failure spawns zero active agents")
	_check_eq(w6["dispatcher"].get_child_count(), child_before, "assign failure leaves no orphan node")
	_check_eq(w6["reservations"].get_reservation_count(), 0, "assign failure releases the reservation")
	_m19_teardown(w6)

	# --- rapid input: uniqueness preserved, one-by-one --------------------
	var b7 = _m19_open_board_active(14, 11, active)
	var color7: int = b7.get_color_id(b7.get_cell_index(2, 5))
	var w7 = _m19_wire_fake(b7, "ok", [b7.get_cell_index(2, 5), b7.get_cell_index(4, 5),
		b7.get_cell_index(6, 5), b7.get_cell_index(8, 5), b7.get_cell_index(10, 5)])
	var owners := {}
	var targets := {}
	var succ := 0
	for _i in range(12): # more requests than the 5 reachable candidates.
		var rr = w7["dispatcher"].dispatch(color7, origin)
		if rr.success:
			succ += 1
			_check(not owners.has(rr.owner_id), "rapid input: owner id stays unique")
			_check(not targets.has(rr.target_index), "rapid input: target ownership never duplicated")
			owners[rr.owner_id] = true
			targets[rr.target_index] = true
	_check_eq(succ, 5, "rapid input success count equals unique reachable work (5)")
	_check_eq(w7["dispatcher"].get_active_count(), 5, "one-by-one flow: exactly 5 agents from 12 requests")

	# --- reset: cancel agents, release reservations, board untouched ------
	var before7 = _snapshot_cell_states(b7)
	w7["dispatcher"].reset()
	_check_eq(w7["dispatcher"].get_active_count(), 0, "reset cancels/removes all active agents")
	_check_eq(w7["dispatcher"].get_child_count(), 0, "reset leaves no orphan agent nodes")
	_check_eq(w7["reservations"].get_reservation_count(), 0, "reset releases dispatcher-owned reservations")
	_check(_cell_states_equal(b7, before7), "reset does not mutate BoardState")
	var next_before: int = w7["dispatcher"].peek_next_owner_id()
	var r7b = w7["dispatcher"].dispatch(color7, origin)
	_check(r7b.success, "new dispatch works after reset")
	_check(r7b.owner_id >= next_before, "owner id counter stays monotonic across reset (no restart)")
	_m19_teardown(w7)

func _run_m19_dispatcher_production_tests() -> void:
	print("---- M19: dispatcher over REAL production selection+routing ----")
	# Single isolated reachable target -> selected, reserved, routed, spawned.
	var b1 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color1: int = b1.get_color_id(b1.get_cell_index(10, 10))
	var w1 = _m19_wire_real(b1)
	var before1 = _snapshot_cell_states(b1)
	var r1 = w1["dispatcher"].dispatch(color1, Vector2(-2.0, 10.5), 6.0)
	_check(r1.success, "production pipeline: reachable target dispatches one agent")
	_check_eq(r1.target_index, b1.get_cell_index(10, 10), "production: the one reachable candidate is selected")
	_check(r1.agent.get_route_length() > 0.0, "production: a real non-empty route was produced")
	_check(w1["reservations"].is_reserved(r1.target_index), "production: reserved target held after dispatch")
	_check(_cell_states_equal(b1, before1), "production: dispatcher mutates no BoardState cell")
	_m19_teardown(w1)

	# Sole candidate fully enclosed -> unreachable -> no spawn (real routing).
	var b2 = _m19_enclosed_sole_candidate_board()
	var w2 = _m19_wire_real(b2)
	_check_eq(w2["dispatcher"].dispatch(1, Vector2(-2.0, 2.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "production: enclosed sole candidate -> NO_REACHABLE_TARGET")
	_check_eq(w2["dispatcher"].get_active_count(), 0, "production: enclosed candidate spawns nothing")
	_check_eq(w2["reservations"].get_reservation_count(), 0, "production: enclosed candidate reserves nothing")
	_m19_teardown(w2)

	# 59x59 coverage: three reachable same-colour targets, full real pipeline.
	var b3 = _m19_open_board_active(59, 59, [Vector2(10, 30), Vector2(30, 30), Vector2(50, 30)])
	_check_eq(b3.get_width(), 59, "59x59 coverage: width 59")
	_check_eq(b3.get_height(), 59, "59x59 coverage: height 59")
	var color3: int = b3.get_color_id(b3.get_cell_index(10, 30))
	var w3 = _m19_wire_real(b3)
	var before3 = _snapshot_cell_states(b3)
	var succ3 := 0
	var owners3 := {}
	for _i in range(3):
		var rr = w3["dispatcher"].dispatch(color3, Vector2(-2.0, 30.5), 6.0)
		if rr.success:
			succ3 += 1
			owners3[rr.owner_id] = true
	_check_eq(succ3, 3, "59x59: all three reachable targets dispatch")
	_check_eq(owners3.size(), 3, "59x59: three unique owner ids")
	_check_eq(w3["dispatcher"].get_active_count(), 3, "59x59: three agents active")
	_check(_cell_states_equal(b3, before3), "59x59: no BoardState mutation")
	_m19_teardown(w3)

	# Rectangular Very Hard coverage (53x59).
	var b4 = _m19_open_board_active(53, 59, [Vector2(10, 30), Vector2(40, 30)])
	_check_eq(b4.get_width(), 53, "rectangular VH: width 53")
	_check_eq(b4.get_height(), 59, "rectangular VH: height 59")
	var color4: int = b4.get_color_id(b4.get_cell_index(10, 30))
	var w4 = _m19_wire_real(b4)
	var succ4 := 0
	for _i in range(2):
		if w4["dispatcher"].dispatch(color4, Vector2(-2.0, 30.5), 6.0).success:
			succ4 += 1
	_check_eq(succ4, 2, "rectangular VH: both reachable targets dispatch")
	_m19_teardown(w4)

## Wire a dispatcher exactly as production will: real ColorCandidateIndex,
## TargetSelector, ProductionRoutingSystem, ProductionAccessQuery, and the
## routing-backed ProductionTargetAccess reachability truth.
func _m19_wire_real(board) -> Dictionary:
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var dispatcher = ScrubbotDispatcher.new(); root.add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access)
	return {"board": board, "reservations": reservations, "dispatcher": dispatcher}

## 5x5 board where colour 1 has exactly ONE candidate (the centre), fully
## enclosed by ACTIVE colour-0 cells; everything else CLEARED (open exterior).
func _m19_enclosed_sole_candidate_board() -> Object:
	var w := 5; var h := 5
	var palette := PackedStringArray(["A", "B"])
	var cells := PackedInt32Array(); cells.resize(w * h); cells.fill(0)
	cells[2 * w + 2] = 1 # centre is the only colour-1 cell.
	var level = LevelData.new(1, "m19_enclosed", "m19_enclosed", "TEST", w, h, palette, cells)
	var board = BoardState.from_level_data(level)
	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEARED)
	for c in [Vector2i(2, 2), Vector2i(1, 2), Vector2i(3, 2), Vector2i(2, 1), Vector2i(2, 3)]:
		board.set_cell_state(board.get_cell_index(c.x, c.y), BoardState.CellState.ACTIVE)
	return board

func _run_m19_dispatcher_stress_tests() -> void:
	print("---- M19: dispatcher rapid-input stress (CPU/node only; no FPS/GPU claim) ----")
	# 25 same-colour reachable candidates in one row; 30 rapid requests.
	var cells: Array = []
	for x in range(25):
		cells.append(Vector2(x, 5))
	var board = _m19_open_board_active(26, 11, cells)
	var color: int = board.get_color_id(board.get_cell_index(0, 5))
	var targetable: Array = []
	for x in range(25):
		targetable.append(board.get_cell_index(x, 5))
	var w = _m19_wire_fake(board, "ok", targetable)
	var owners := {}
	var targets := {}
	var succ := 0
	var t0 := Time.get_ticks_usec()
	for _i in range(30):
		var rr = w["dispatcher"].dispatch(color, Vector2(-2.0, 5.5), 6.0)
		if rr.success:
			succ += 1
			owners[rr.owner_id] = true
			targets[rr.target_index] = true
	var elapsed_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	_check_eq(succ, 25, "25-request stress: successes equal the 25 unique reachable candidates")
	_check_eq(owners.size(), 25, "25-request stress: all owner ids unique")
	_check_eq(targets.size(), 25, "25-request stress: no duplicate target ownership")
	_check_eq(w["dispatcher"].get_active_count(), 25, "25-request stress: 25 agents active, one per success")
	print("     M19 stress: 30 rapid dispatches (25 reachable), CPU=%.2f ms (headless CPU only, no FPS/GPU claim)" % elapsed_ms)

	# 5-slot concurrent: five reachable candidates dispatched in one burst.
	var cells5: Array = [Vector2(0, 5), Vector2(2, 5), Vector2(4, 5), Vector2(6, 5), Vector2(8, 5)]
	var board5 = _m19_open_board_active(10, 11, cells5)
	var color5: int = board5.get_color_id(board5.get_cell_index(0, 5))
	var tgt5: Array = []
	for x in [0, 2, 4, 6, 8]:
		tgt5.append(board5.get_cell_index(x, 5))
	var w5 = _m19_wire_fake(board5, "ok", tgt5)
	var succ5 := 0
	for _i in range(5):
		if w5["dispatcher"].dispatch(color5, Vector2(-2.0, 5.5), 6.0).success:
			succ5 += 1
	_check_eq(succ5, 5, "5-slot concurrent: all five reachable targets dispatch")
	_check_eq(w5["dispatcher"].get_active_count(), 5, "5-slot concurrent: five unique agents")
	_m19_teardown(w5)
	_m19_teardown(w)
	# Pooling decision (prompt: no pooling unless profiling justifies it).
	print("     M19 pooling: NOT justified — 30 rapid create/assign/attach dispatches")
	print("     completed in a fraction of a ms of CPU; agents are childless Node2Ds")
	print("     with no per-frame allocation. Defer any pooling to real profiling.")
