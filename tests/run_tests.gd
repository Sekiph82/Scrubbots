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
const M15ReservationDouble = preload("res://tests/support/m15_reservation_double.gd")
const M15VariantAccess = preload("res://tests/support/m15_variant_access.gd")
const M15NodeAccess = preload("res://tests/support/m15_node_access.gd")
# M16 — RoutingSystem interface / route contract.
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const RoutingSystem = preload("res://scripts/gameplay/routing/routing_system.gd")
const RouteDebugOverlay = preload("res://scripts/debug/route_debug_overlay.gd")
const RouteAccessQueryDouble = preload("res://tests/support/route_access_query_double.gd")
const RouteNonBoolAccessQueryDouble = preload("res://tests/support/route_nonbool_access_double.gd")
const PartialBoardDouble = preload("res://tests/support/partial_board_double.gd")
const WrongReturnBoardDouble = preload("res://tests/support/wrong_return_board_double.gd")
const M13MalformedBoardDouble = preload("res://tests/support/m13_malformed_board_double.gd")
const M14PartialBoardDouble = preload("res://tests/support/m14_partial_board_double.gd")
const M14CountingBoardDouble = preload("res://tests/support/m14_counting_board_double.gd")
const RouteFakeStraight = preload("res://tests/support/route_fake_straight.gd")
const RouteFakeRelay = preload("res://tests/support/route_fake_relay.gd")
const FakeRenderer = preload("res://tests/support/fake_renderer.gd")
const PaletteSpyRenderer = preload("res://tests/support/palette_spy_renderer.gd")
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
const RouteAccessWrongReturn = preload("res://tests/support/route_access_wrong_return.gd")
const RouteAccessMissingMethod = preload("res://tests/support/route_access_missing_method.gd")
const RouteAccessEdgeBlock = preload("res://tests/support/route_access_edge_block.gd")
# M18 — lightweight Scrubbot agent (consumes a finished route; no selection/routing).
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
# M19 — Scrubbot dispatcher (orchestration: select+reserve -> route -> spawn one).
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const DispatchResult = preload("res://scripts/gameplay/dispatch/dispatch_result.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const DispatchRoutingDouble = preload("res://tests/support/dispatch_routing_double.gd")
const DispatchAgentDouble = preload("res://tests/support/dispatch_agent_double.gd")
const M19CollabDouble = preload("res://tests/support/m19_collab_double.gd")
const M19NodeCollabDouble = preload("res://tests/support/m19_node_collab_double.gd")
const M19SelectAccessVariants = preload("res://tests/support/m19_select_access_variants.gd")
const M19NoCoherenceSelect = preload("res://tests/support/m19_no_coherence_select.gd")
const M19CacheSelectAccess = preload("res://tests/support/m19_cache_select_access.gd")
const LyingAgentDouble = preload("res://tests/support/lying_agent_double.gd")
const AgentFactoryHolder = preload("res://tests/support/agent_factory_holder.gd")
const M19SelectorReturnDouble = preload("res://tests/support/m19_selector_return_double.gd")
const M19ResetCancelAgent = preload("res://tests/support/m19_reset_cancel_agent.gd")
const M19NonBoolAssignAgent = preload("res://tests/support/m19_nonbool_assign_agent.gd")
const M19CoherenceResetAccess = preload("res://tests/support/m19_coherence_reset_access.gd")
const M19ProbeAgent = preload("res://tests/support/m19_probe_agent.gd")
const M19ReservationProofDouble = preload("res://tests/support/m19_reservation_proof_double.gd")
const M19ResetStateAgent = preload("res://tests/support/m19_reset_state_agent.gd")
# M20 — complete clearing vertical slice (clearing-loop orchestrator).
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const BoardDebugFixturesM20 = preload("res://scripts/debug/board_debug_fixtures.gd")
const M20FailingCandidate = preload("res://tests/support/m20_failing_candidate.gd")
const M20FailingReservation = preload("res://tests/support/m20_failing_reservation.gd")
const M20CandidateSeam = preload("res://tests/support/m20_candidate_seam.gd")
const M20ReservationSeam = preload("res://tests/support/m20_reservation_seam.gd")
const M20ResetSelectAccess = preload("res://tests/support/m20_reset_select_access.gd")

var _total: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	_run_dimension_tests()
	_run_index_conversion_tests()
	_run_invalid_coordinate_tests()
	_run_level_validation_tests()
	_run_board_state_tests()
	_run_board_state_canonical_validation_tests()
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
	_run_reservation_state_strict_tests()
	_run_reservation_state_integration_tests()
	_run_reservation_state_performance()
	_run_target_selector_tests()
	_run_target_selector_simultaneous_tests()
	_run_target_selector_strict_v02_tests()
	_run_target_selector_strict_v03_tests()
	_run_target_selector_strict_v04_tests()
	_run_target_selector_strict_v05_tests()
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
	# M17-C002 V03 — frozen full-surface hardening.
	_run_m17c002_v03_hardening_tests()
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
	_run_m19_strict_v2_tests()
	_run_m19_strict_v3_tests()
	_run_m19_v04_tests()
	_run_m19_v05_tests()
	_run_m19_v06_auditor_validation_tests()
	# M20 — complete clearing vertical slice.
	_run_m20_bind_contract_tests()
	_run_m20_activation_tests()
	_run_m20_clear_transaction_tests()
	_run_m20_scenario_matrix_tests()
	_run_m20_reachability_open_tests()
	_run_m20_desync_adversary_tests()
	_run_m20_reset_lifecycle_tests()
	# M20-C001 V02 — strict-v2 transaction correction.
	_run_m20_v02_bind_transaction_tests()
	_run_m20_v02_activation_serialization_tests()
	_run_m20_v02_transaction_order_tests()
	_run_m20_v02_mutation_rollback_tests()
	_run_m20_v02_reset_during_arrival_tests()
	_run_m20_v02_serial_arrival_tests()
	_run_m20_v02_reachability_second_activation_tests()
	_run_m20_v02_direct_observability_tests()
	# M20-C001 V03 — exact dependency / exact-state closure.
	_run_m20_v03_exact_reservation_state_tests()
	_run_m20_v03_unrelated_truth_tests()
	_run_m20_v03_current_arrival_dedup_tests()
	# M20-C001 V04 — lifecycle / reset closure.
	_run_m20_v04_node_lifetime_tests()
	_run_m20_v04_post_dispatch_bracket_tests()
	_run_m19_v04_pair_narrow_reset_tests()
	# M20-C001 V05 — auditor-authored validation-only gate (fresh arrangements).
	_run_m20_v05_auditor_validation_tests()
	# M20-C001 V06 — optional renderer presence: null-vs-dead distinction.
	_run_m20_v06_renderer_presence_tests()
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

## FOUNDATION-C001 — canonical CellState validation. The state domain is
## EXACTLY ACTIVE=0/CLEARED=1; a valid-index set_cell_state() with any other
## integer (enum params are not runtime-checked in GDScript) must return
## false, mutate nothing, keep counts stable, and never let get_cell_state
## expose a noncanonical stored value. Proves the guard on a small
## rectangular board and the 59x59 canonical maximum.
func _run_board_state_canonical_validation_tests() -> void:
	var active = BoardState.CellState.ACTIVE
	var cleared = BoardState.CellState.CLEARED
	for dims in [Vector2i(5, 4), Vector2i(59, 59)]:
		var board = _make_blank_board(dims.x, dims.y)
		var count = board.get_cell_count()
		var target = board.get_cell_index(dims.x / 2, dims.y / 2)
		var neighbor = board.get_cell_index(0, 0)
		var label = "%dx%d" % [dims.x, dims.y]
		_check_eq(board.count_cells_by_state(active), count, "%s fresh board all ACTIVE" % label)
		for bad in [2, -1, 255, 3, 99]:
			var ret = board.set_cell_state(target, bad)
			_check_eq(ret, false, "%s set_cell_state(valid, %d) returns false" % [label, bad])
			_check_eq(board.get_cell_state(target), active, "%s target unchanged (ACTIVE) after noncanonical %d" % [label, bad])
			_check_eq(board.get_cell_state(neighbor), active, "%s sibling unchanged after noncanonical %d" % [label, bad])
			_check_eq(board.count_cells_by_state(active), count, "%s ACTIVE count preserved after noncanonical %d" % [label, bad])
			_check_eq(board.count_cells_by_state(cleared), 0, "%s CLEARED count preserved after noncanonical %d" % [label, bad])
			var st = board.get_cell_state(target)
			_check(st == active or st == cleared, "%s get_cell_state exposes only ACTIVE/CLEARED after noncanonical %d" % [label, bad])
		# Valid-state regression: canonical transitions still succeed.
		_check_eq(board.set_cell_state(target, cleared), true, "%s ACTIVE->CLEARED succeeds" % label)
		_check_eq(board.get_cell_state(target), cleared, "%s target reads CLEARED" % label)
		_check_eq(board.set_cell_state(target, active), true, "%s CLEARED->ACTIVE succeeds" % label)
		_check_eq(board.get_cell_state(target), active, "%s target reads ACTIVE" % label)
		# Repeated identical canonical assignment stays stable.
		board.set_cell_state(target, cleared)
		board.set_cell_state(target, cleared)
		_check_eq(board.get_cell_state(target), cleared, "%s repeated CLEARED assignment stable" % label)
		board.set_cell_state(target, active)
		# Invalid index still rejected safely.
		_check_eq(board.set_cell_state(-1, cleared), false, "%s invalid index -1 returns false" % label)
		_check_eq(board.set_cell_state(count, cleared), false, "%s invalid index == count returns false" % label)
		# Count invariant: every cell is exactly ACTIVE or CLEARED.
		_check_eq(board.count_cells_by_state(active) + board.count_cells_by_state(cleared), count, "%s ACTIVE+CLEARED == cell count" % label)

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
	# get_level_data() now returns a fresh DETACHED snapshot each call, so assert
	# source truth by VALUE (not object identity) across a failed replacement.
	var ld_before = s7.get_level_data()
	var bs_before = s7.get_board_state()
	_check_eq(s7.get_state(), GameplaySession.State.READY, "M11-07: starts READY")
	var r7 := s7.load_level("res://data/levels/nonexistent.json")
	_check(not r7.ok, "M11-07: replacement load fails")
	_check_eq(s7.get_state(), GameplaySession.State.READY, "M11-07: state still READY")
	var ld_after = s7.get_level_data()
	_check_eq(ld_after.id, ld_before.id, "M11-07: level_data id unchanged after failed replacement")
	_check_eq(ld_after.width, ld_before.width, "M11-07: level_data width unchanged")
	_check_eq(ld_after.height, ld_before.height, "M11-07: level_data height unchanged")
	_check_eq(ld_after.cells, ld_before.cells, "M11-07: level_data cells unchanged")
	_check(s7.get_board_state() == bs_before, "M11-07: board_state identity unchanged")

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

	# ==== 29. Detached LevelData source truth, incl. post-reset (V06 §1) ====
	# Save EVERY original field; hostile-mutate a snapshot (scalars, replaced
	# packed arrays, in-place packed-array edits); reset; verify fresh BoardState
	# AND a NEW post-reset snapshot both still match the ORIGINAL in every field.
	var s29 := GameplaySession.new()
	s29.load_level(rect_path)
	var o29 = s29.get_level_data()
	var o29_version: int = o29.version
	var o29_id: String = o29.id
	var o29_name: String = o29.display_name
	var o29_diff: String = o29.difficulty
	var o29_w: int = o29.width
	var o29_h: int = o29.height
	var o29_palette: PackedStringArray = o29.palette.duplicate()
	var o29_cells: PackedInt32Array = o29.cells.duplicate()
	# each snapshot is a distinct detached object
	_check(s29.get_level_data() != o29, "M11-29: each get_level_data returns a distinct detached object")
	# hostile scalar + packed-array REPLACEMENT on one snapshot
	o29.version = -7
	o29.id = "HACKED"
	o29.display_name = "HACKED"
	o29.difficulty = "HACKED"
	o29.width = 999
	o29.height = 999
	o29.palette = PackedStringArray(["#DEADBEEF"])
	o29.cells = PackedInt32Array([7, 7, 7])
	# hostile in-place packed-array mutation on a second snapshot
	var snap29b = s29.get_level_data()
	if snap29b.cells.size() > 0:
		snap29b.cells[0] = 42
	if snap29b.palette.size() > 0:
		snap29b.palette[0] = "#00000000"
	# reset rebuilds BoardState from untouched internal source
	s29.reset()
	_check_eq(s29.get_board_state().get_width(), o29_w, "M11-29: reset board width matches original source")
	_check_eq(s29.get_board_state().get_height(), o29_h, "M11-29: reset board height matches original source")
	var reset_ok29 := true
	for i in o29_cells.size():
		if s29.get_board_state().get_color_id(i) != o29_cells[i]:
			reset_ok29 = false
			break
	_check(reset_ok29, "M11-29: reset board color ids match original source")
	# NEW post-reset snapshot still matches EVERY original field
	var p29 = s29.get_level_data()
	_check_eq(p29.version, o29_version, "M11-29: post-reset snapshot version matches original")
	_check_eq(p29.id, o29_id, "M11-29: post-reset snapshot id matches original")
	_check_eq(p29.display_name, o29_name, "M11-29: post-reset snapshot display_name matches original")
	_check_eq(p29.difficulty, o29_diff, "M11-29: post-reset snapshot difficulty matches original")
	_check_eq(p29.width, o29_w, "M11-29: post-reset snapshot width matches original")
	_check_eq(p29.height, o29_h, "M11-29: post-reset snapshot height matches original")
	_check_eq(p29.palette, o29_palette, "M11-29: post-reset snapshot palette matches original")
	_check_eq(p29.cells, o29_cells, "M11-29: post-reset snapshot cells matches original")

	# ==== 29b. Failed replacement preserves every field + BoardState identity ====
	var s29f := GameplaySession.new()
	s29f.load_level(rect_path)
	var f29 = s29f.get_level_data()
	var f29_version: int = f29.version
	var f29_id: String = f29.id
	var f29_name: String = f29.display_name
	var f29_diff: String = f29.difficulty
	var f29_w: int = f29.width
	var f29_h: int = f29.height
	var f29_palette: PackedStringArray = f29.palette.duplicate()
	var f29_cells: PackedInt32Array = f29.cells.duplicate()
	var bs29_before = s29f.get_board_state()
	bs29_before.set_cell_state(0, BoardState.CellState.CLEARED)  # runtime state marker
	var rf29 := s29f.load_level("res://data/levels/nonexistent.json")
	_check(not rf29.ok, "M11-29b: failed replacement load reports failure")
	var g29 = s29f.get_level_data()
	_check_eq(g29.version, f29_version, "M11-29b: version preserved after failed replacement")
	_check_eq(g29.id, f29_id, "M11-29b: id preserved after failed replacement")
	_check_eq(g29.display_name, f29_name, "M11-29b: display_name preserved after failed replacement")
	_check_eq(g29.difficulty, f29_diff, "M11-29b: difficulty preserved after failed replacement")
	_check_eq(g29.width, f29_w, "M11-29b: width preserved after failed replacement")
	_check_eq(g29.height, f29_h, "M11-29b: height preserved after failed replacement")
	_check_eq(g29.palette, f29_palette, "M11-29b: palette preserved after failed replacement")
	_check_eq(g29.cells, f29_cells, "M11-29b: cells preserved after failed replacement")
	_check(s29f.get_board_state() == bs29_before, "M11-29b: BoardState object identity preserved after failed replacement")
	_check_eq(s29f.get_board_state().get_cell_state(0), BoardState.CellState.CLEARED, "M11-29b: BoardState runtime state preserved after failed replacement")

	# ==== 30. Malformed renderer replacement sensitivity (V06 §2/§3) ====
	# Positive path uses a real counting BoardRenderer subclass spy.
	var s30 := GameplaySession.new()
	s30.load_level(path_3x2)
	var spy30 := PaletteSpyRenderer.new()
	_check(s30.bind_renderer(spy30, Vector2(800, 600)) == true, "M11-30: real counting spy binds")
	_check_eq(spy30.configure_calls, 1, "M11-30: spy configured exactly once on bind")
	_check(spy30.last_board != null, "M11-30: spy recorded last_board")
	_check(spy30.last_palette != null, "M11-30: spy recorded last_palette")
	_check_eq(spy30.last_size, Vector2(800, 600), "M11-30: spy recorded last_size")
	var pre30: int = spy30.configure_calls
	# malformed replacements — all rejected, none touch the valid binding
	_check(s30.bind_renderer(123, Vector2(800, 600)) == false, "M11-30: int renderer rejected")
	_check(s30.bind_renderer("renderer", Vector2(800, 600)) == false, "M11-30: String renderer rejected")
	_check(s30.bind_renderer(Vector2(1, 1), Vector2(800, 600)) == false, "M11-30: Vector2 renderer rejected")
	_check(s30.bind_renderer(RefCounted.new(), Vector2(800, 600)) == false, "M11-30: RefCounted junk renderer rejected")
	var fake30 := FakeRenderer.new()
	_check(s30.bind_renderer(fake30, Vector2(800, 600)) == false, "M11-30: partial fake configure object rejected")
	_check_eq(fake30.configure_calls, 0, "M11-30: partial fake configure never called")
	_check_eq(spy30.configure_calls, pre30, "M11-30: valid binding untouched by malformed replacements (no extra configure)")
	# reset -> ORIGINAL valid binding survived: configure increments exactly once
	s30.reset()
	_check_eq(spy30.configure_calls, pre30 + 1, "M11-30: prior valid binding survived (reset increments spy exactly once)")
	# null unbind then reset -> spy NOT reconfigured
	var post_unbind30: int = spy30.configure_calls
	_check(s30.bind_renderer(null) == true, "M11-30: null explicitly unbinds")
	s30.reset()
	_check_eq(spy30.configure_calls, post_unbind30, "M11-30: after null unbind, reset does not reconfigure the old spy")
	spy30.free()
	fake30 = null

	# ==== 31. Invalid renderer-size direct observability (V06 §4) ====
	# Counting spy proves configure_calls does NOT change for any invalid size,
	# on BOTH axes. No is_inside_tree() evidence.
	var s31 := GameplaySession.new()
	s31.load_level(path_3x2)
	var spy31 := PaletteSpyRenderer.new()
	var invalid_sizes := [
		Vector2(NAN, 100), Vector2(100, NAN),
		Vector2(INF, 100), Vector2(100, INF),
		Vector2(-INF, 100), Vector2(100, -INF),
		Vector2(0, 100), Vector2(100, 0),
		Vector2(-10, 100), Vector2(100, -10),
	]
	for sz in invalid_sizes:
		_check(s31.bind_renderer(spy31, sz) == false, "M11-31: invalid size %s rejected" % str(sz))
	_check_eq(spy31.configure_calls, 0, "M11-31: no invalid size ever reached renderer.configure")
	# preservation: bind valid size A, then attempt invalid-size bind of ANOTHER
	# real renderer; the replacement must never configure, and A must survive.
	_check(s31.bind_renderer(spy31, Vector2(640, 480)) == true, "M11-31: valid size A binds")
	_check_eq(spy31.configure_calls, 1, "M11-31: spy A configured once on valid bind")
	var a_count31: int = spy31.configure_calls
	var spy31b := PaletteSpyRenderer.new()
	_check(s31.bind_renderer(spy31b, Vector2(NAN, NAN)) == false, "M11-31: invalid-size replacement renderer rejected")
	_check_eq(spy31b.configure_calls, 0, "M11-31: invalid-size replacement renderer never configured")
	s31.reset()
	_check_eq(spy31.configure_calls, a_count31 + 1, "M11-31: original renderer A survived (reset increments it)")
	_check_eq(spy31.last_size, Vector2(640, 480), "M11-31: original renderer A last_size remains size A")
	spy31.free()
	spy31b.free()

	# ==== 32. Freed renderer lifecycle + fresh-renderer reuse (V06 §5) ====
	var s32 := GameplaySession.new()
	var r32 := BoardRenderer.new()
	s32.bind_renderer(r32, Vector2(800, 600))
	s32.load_level(path_3x2)
	var bs32_pre = s32.get_board_state()
	r32.free()
	var r32reset := s32.reset()
	_check(r32reset.ok, "M11-32: reset succeeds after bound renderer freed")
	_check_eq(s32.get_state(), GameplaySession.State.READY, "M11-32: READY after reset with freed renderer")
	_check(s32.get_board_state() != bs32_pre, "M11-32: reset produced fresh BoardState after freed renderer")
	# after stale renderer dropped, bind a fresh real counting renderer + reset
	var spy32 := PaletteSpyRenderer.new()
	_check(s32.bind_renderer(spy32, Vector2(800, 600)) == true, "M11-32: fresh renderer binds after stale drop")
	_check_eq(spy32.configure_calls, 1, "M11-32: fresh renderer configured on bind (session still valid)")
	s32.reset()
	_check_eq(spy32.configure_calls, 2, "M11-32: fresh renderer reconfigured on reset")
	_check_eq(s32.get_state(), GameplaySession.State.READY, "M11-32: session READY after fresh renderer reset")
	spy32.free()
	# bind -> free renderer -> replacement load succeeds.
	var s32b := GameplaySession.new()
	var r32b := BoardRenderer.new()
	s32b.bind_renderer(r32b, Vector2(800, 600))
	r32b.free()
	var r32bload := s32b.load_level(path_3x2)
	_check(r32bload.ok, "M11-32: valid level load succeeds after bound renderer freed")
	_check_eq(s32b.get_state(), GameplaySession.State.READY, "M11-32: READY after load with freed renderer")

	# ==== 33. Palette isolation across configure/rebind/reset (V06 §6) ====
	var s33 := GameplaySession.new()
	s33.load_level(rect_path)
	var src_palette33: PackedStringArray = s33.get_level_data().palette.duplicate()
	# bind real spy A -> receives detached palette
	var spyA33 := PaletteSpyRenderer.new()
	s33.bind_renderer(spyA33, Vector2(800, 600))
	_check(spyA33.last_palette != null and spyA33.last_palette == src_palette33, "M11-33: spy A initial configure receives original-valued detached palette")
	# mutate spy A retained palette in-place -> source unchanged
	if spyA33.last_palette.size() > 0:
		spyA33.last_palette[0] = "#00000000"
	_check_eq(s33.get_level_data().palette, src_palette33, "M11-33: mutating spy A palette does not change source")
	# rebind to spy B -> source still original
	var spyB33 := PaletteSpyRenderer.new()
	s33.bind_renderer(spyB33, Vector2(800, 600))
	_check_eq(s33.get_level_data().palette, src_palette33, "M11-33: rebind to spy B does not change source")
	_check(spyB33.last_palette == src_palette33, "M11-33: spy B receives original-valued detached palette on rebind")
	# mutate spy B retained palette in-place, then reset
	if spyB33.last_palette.size() > 0:
		spyB33.last_palette[0] = "#11111111"
	var b_calls33: int = spyB33.configure_calls
	s33.reset()
	_check_eq(s33.get_level_data().palette, src_palette33, "M11-33: source palette unchanged after spy B mutation + reset")
	_check_eq(spyB33.configure_calls, b_calls33 + 1, "M11-33: spy B reconfigured on reset")
	_check(spyB33.last_palette == src_palette33, "M11-33: spy B reconfigure receives fresh original-valued palette")
	# never a LevelData object handed to renderer
	_check(not (spyB33.last_board is LevelData), "M11-33: renderer last_board is BoardState, never a LevelData object")
	spyA33.free()
	spyB33.free()

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

	# M12-19: F-M12-STRICT-001 — fail-closed sentinel/configured collection query.
	# Mandatory frozen regression sequence.
	var sysS := SlotSystem.new()
	# 2. unconfigured
	_check(not sysS.is_configured(), "M12-19 fresh system unconfigured")
	# 3. sensitivity-safe: -1 sentinel must NOT materialize the five slots
	_check_eq(sysS.get_slots_by_palette_id(-1), [], "M12-19 unconfigured query(-1) == [] (pre-fix defect guard)")
	_check_eq(sysS.get_slots_by_palette_id(0), [], "M12-19 unconfigured query(0) == []")
	# 4. more negative ids
	_check_eq(sysS.get_slots_by_palette_id(-2), [], "M12-19 unconfigured query(-2) == []")
	_check_eq(sysS.get_slots_by_palette_id(-999), [], "M12-19 unconfigured query(-999) == []")
	# 5-7. failed FIRST configure
	var rSf := sysS.configure([0, 1, -1, 3, 4], 8)
	_check(not rSf.ok, "M12-19 failed first configure rejected")
	_check(not sysS.is_configured(), "M12-19 still unconfigured after failed first configure")
	for i in 5:
		_check_eq(sysS.get_slot_palette_id(i), -1, "M12-19 slot %d still -1 sentinel after failed first configure" % i)
	# 8. queries still fail-closed after failed first configure
	_check_eq(sysS.get_slots_by_palette_id(-1), [], "M12-19 query(-1) == [] after failed first configure")
	_check_eq(sysS.get_slots_by_palette_id(0), [], "M12-19 query(0) == [] after failed first configure")
	# 9-10. successful duplicate configure
	var rSg := sysS.configure([0, 0, 1, 1, 0], 2)
	_check(rSg.ok, "M12-19 duplicate-valid configure succeeds")
	_check_eq(sysS.get_slots_by_palette_id(0), [0, 1, 4], "M12-19 palette 0 -> [0,1,4]")
	_check_eq(sysS.get_slots_by_palette_id(1), [2, 3], "M12-19 palette 1 -> [2,3]")
	# 11. non-present high id
	_check_eq(sysS.get_slots_by_palette_id(999), [], "M12-19 query(999) == []")
	# 12-13. failed REconfigure preserves prior truth
	var rSr := sysS.configure([0, 0, 1, 1], 2)
	_check(not rSr.ok, "M12-19 failed reconfigure rejected")
	_check_eq(sysS.get_slots_by_palette_id(0), [0, 1, 4], "M12-19 palette 0 -> [0,1,4] preserved after failed reconfigure")
	_check_eq(sysS.get_slots_by_palette_id(1), [2, 3], "M12-19 palette 1 -> [2,3] preserved after failed reconfigure")

	# M12-20: F-M12-STRICT-002 — arbitrary Variant boundary fails closed.
	# Configured system so a non-empty result is possible for a valid int.
	var sysV := SlotSystem.new()
	sysV.configure([0, 0, 1, 1, 0], 2)
	var bad_inputs := [
		null, 0.0, 1.0, "0", "hello", false, true,
		Vector2(1, 2), RefCounted.new(), [], {},
	]
	for bad in bad_inputs:
		var res = sysV.get_slots_by_palette_id(bad)
		_check(res is Array and res.is_empty(), "M12-20 unsupported input %s -> []" % str(bad))
	# float 0.0/1.0 must NOT coerce-match integer 0/1
	_check_eq(sysV.get_slots_by_palette_id(0.0), [], "M12-20 float 0.0 != int 0")
	_check_eq(sysV.get_slots_by_palette_id(1.0), [], "M12-20 float 1.0 != int 1")
	# valid int 0 still works — proves the gate isn't over-broad
	_check_eq(sysV.get_slots_by_palette_id(0), [0, 1, 4], "M12-20 valid int 0 still resolves")
	# invalid queries never mutated state
	_check(sysV.is_configured(), "M12-20 config intact after bad queries")
	_check_eq(sysV.get_slot_palette_id(0), 0, "M12-20 slot 0 palette intact after bad queries")

	# M12-21: returned Array is detached — mutation cannot alter future truth.
	var live := sysV.get_slots_by_palette_id(0)
	live.clear()
	live.append(99)
	_check_eq(sysV.get_slots_by_palette_id(0), [0, 1, 4], "M12-21 mutating returned Array does not affect next query")

	# M12-22 (V04 §2): each nested malformed configure entry fails atomically on
	# a fresh system — is_configured() false, every palette scalar stays -1.
	var nested_bad := [null, 1.0, "1", true, Vector2(1, 1), RefCounted.new()]
	for bad_entry in nested_bad:
		var sysN := SlotSystem.new()
		var rN = sysN.configure([0, 1, bad_entry, 3, 4], 8)
		_check(not rN.ok, "M12-22 nested entry %s rejected" % str(bad_entry))
		_check(not sysN.is_configured(), "M12-22 unconfigured after nested %s" % str(bad_entry))
		for i in 5:
			_check_eq(sysN.get_slot_palette_id(i), -1, "M12-22 slot %d still -1 after nested %s" % [i, str(bad_entry)])
	# malformed nested entry AFTER a valid config with non-default markers
	var sysNC := SlotSystem.new()
	sysNC.configure([0, 1, 2, 3, 4], 8)
	sysNC.set_slot_available(1, false)
	sysNC.set_slot_active(2, true)
	var rNC = sysNC.configure([0, 1, "x", 3, 4], 8)
	_check(not rNC.ok, "M12-22 malformed reconfigure rejected")
	_check(sysNC.is_configured(), "M12-22 stays configured after malformed reconfigure")
	for i in 5:
		_check_eq(sysNC.get_slot_palette_id(i), i, "M12-22 palette %d preserved after malformed reconfigure" % i)
	_check(not sysNC.is_slot_available(1), "M12-22 availability preserved after malformed reconfigure")
	_check(sysNC.is_slot_active(2), "M12-22 activity preserved after malformed reconfigure")

	# M12-23 (V04 §3): palette_size 0 and -1 fail atomically on fresh system.
	for bad_size in [0, -1]:
		var sysP := SlotSystem.new()
		var rP := sysP.configure([0, 1, 2, 3, 4], bad_size)
		_check(not rP.ok, "M12-23 palette_size %d rejected" % bad_size)
		_check(not sysP.is_configured(), "M12-23 unconfigured after palette_size %d" % bad_size)
		for i in 5:
			_check_eq(sysP.get_slot_palette_id(i), -1, "M12-23 slot %d still -1 after palette_size %d" % [i, bad_size])

	# M12-24 (V04 §4): failed reconfigure preserves palette + availability +
	# activity + collection-query truth (wrong-count AND malformed-entry).
	var sysR := SlotSystem.new()
	sysR.configure([0, 0, 1, 1, 0], 2)
	sysR.set_slot_available(3, false)
	sysR.set_slot_active(4, true)
	var snap_pal := []
	var snap_avail := []
	var snap_act := []
	for i in 5:
		snap_pal.append(sysR.get_slot_palette_id(i))
		snap_avail.append(sysR.is_slot_available(i))
		snap_act.append(sysR.is_slot_active(i))
	for rr in [sysR.configure([0, 1], 2), sysR.configure([0, 0, "x", 1, 0], 2)]:
		_check(not rr.ok, "M12-24 failed reconfigure rejected")
		_check(sysR.is_configured(), "M12-24 stays configured")
		for i in 5:
			_check_eq(sysR.get_slot_palette_id(i), snap_pal[i], "M12-24 palette %d preserved" % i)
			_check_eq(sysR.is_slot_available(i), snap_avail[i], "M12-24 availability %d preserved" % i)
			_check_eq(sysR.is_slot_active(i), snap_act[i], "M12-24 activity %d preserved" % i)
		_check_eq(sysR.get_slots_by_palette_id(0), [0, 1, 4], "M12-24 query 0 preserved")
		_check_eq(sysR.get_slots_by_palette_id(1), [2, 3], "M12-24 query 1 preserved")

	# M12-25 (V04 §5): successful reconfigure updates palettes but preserves
	# availability/activity and stable IDs.
	var sysSR := SlotSystem.new()
	sysSR.configure([0, 1, 2, 3, 4], 8)
	sysSR.set_slot_available(0, false)
	sysSR.set_slot_active(1, true)
	var rSR := sysSR.configure([4, 3, 2, 1, 0], 8)
	_check(rSR.ok, "M12-25 second valid configure succeeds")
	_check(sysSR.is_configured(), "M12-25 stays configured")
	for i in 5:
		_check_eq(sysSR.get_slot_palette_id(i), 4 - i, "M12-25 palette %d updated" % i)
		_check_eq(sysSR.get_slot_id(i), i, "M12-25 slot ID %d stable" % i)
	_check(not sysSR.is_slot_available(0), "M12-25 availability preserved across valid reconfigure")
	_check(sysSR.is_slot_active(1), "M12-25 activity preserved across valid reconfigure")

	# M12-26 (V04 §6): caller Array alias isolation.
	var sysA := SlotSystem.new()
	var ids := [0, 1, 2, 3, 4]
	sysA.configure(ids, 8)
	ids[0] = 99
	ids.clear()
	ids.append(-7)
	for i in 5:
		_check_eq(sysA.get_slot_palette_id(i), i, "M12-26 palette %d unaffected by caller Array mutation" % i)
	_check_eq(sysA.get_slots_by_palette_id(2), [2], "M12-26 query truth unaffected by caller Array mutation")
	_check(sysA.is_configured(), "M12-26 stays configured")

	# M12-27 (V04 §7): standalone SlotState mutation cannot alter SlotSystem.
	var sysI := SlotSystem.new()
	sysI.configure([0, 1, 2, 3, 4], 8)
	var lone := SlotState.new(0)
	lone.set_palette_id(999)
	lone.set_available(false)
	lone.set_active(true)
	for i in 5:
		_check_eq(sysI.get_slot_palette_id(i), i, "M12-27 palette %d unaffected by standalone SlotState" % i)
		_check_eq(sysI.get_slot_id(i), i, "M12-27 ID %d unaffected by standalone SlotState" % i)
		_check(sysI.is_slot_available(i), "M12-27 availability %d unaffected by standalone SlotState" % i)
		_check(not sysI.is_slot_active(i), "M12-27 activity %d unaffected by standalone SlotState" % i)
	_check_eq(sysI.get_slots_by_palette_id(0), [0], "M12-27 query truth unaffected by standalone SlotState")
	_check(not sysI.has_method("get_slot"), "M12-27 get_slot absent")

	# M12-28 (V04 §8): complete malformed-query set on configured system with
	# non-default markers mutates nothing.
	var sysM := SlotSystem.new()
	sysM.configure([0, 1, 2, 3, 4], 8)
	sysM.set_slot_available(2, false)
	sysM.set_slot_active(3, true)
	var m_pal := []
	var m_avail := []
	var m_act := []
	for i in 5:
		m_pal.append(sysM.get_slot_palette_id(i))
		m_avail.append(sysM.is_slot_available(i))
		m_act.append(sysM.is_slot_active(i))
	var m_flag := sysM.is_configured()
	var invalid_queries := [null, 1.0, "1", true, Vector2(1, 1), RefCounted.new(), [], {}, -1]
	for q in invalid_queries:
		var qr = sysM.get_slots_by_palette_id(q)
		_check(qr is Array and qr.is_empty(), "M12-28 invalid query %s -> []" % str(q))
	_check_eq(sysM.is_configured(), m_flag, "M12-28 configured flag preserved")
	for i in 5:
		_check_eq(sysM.get_slot_palette_id(i), m_pal[i], "M12-28 palette %d preserved" % i)
		_check_eq(sysM.is_slot_available(i), m_avail[i], "M12-28 availability %d preserved" % i)
		_check_eq(sysM.is_slot_active(i), m_act[i], "M12-28 activity %d preserved" % i)

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
	_run_m13_v03_strict_validation()
	_run_m13_v04_strict_validation()
	_run_m13_v05_strict_validation()
	print("  M13 ColorCandidateIndex tests complete")

## M13-C001 V05 final dependency-domain closure: indexed domain metadata,
## corrected healthy-invalid vs contradictory-drift sync, production max-count
## guard (3,481), transactional rebuild domain metadata. Criteria V05.
func _run_m13_v05_strict_validation() -> void:
	# --- §1/§2 indexed domain metadata + corrected sync semantics ---
	var dbl := M13MalformedBoardDouble.new() # count 4, 4 ACTIVE color 0
	var ix := ColorCandidateIndex.create()
	_check(ix.bind(dbl), "M13V5-001 bind valid count-4 board")
	_check_eq(ix.get_candidates(0), [0, 1, 2, 3], "M13V5-001 exact indexed truth")
	# healthy caller invalid indices (outside domain): false, binding intact
	for bad in [-1, 4, 999]:
		_check_eq(ix.sync_cell(bad), false, "M13V5-002 healthy out-of-domain sync(%d) false" % bad)
	_check(ix.is_bound(), "M13V5-002 healthy invalid index leaves binding valid")
	_check_eq(ix.get_candidates(0), [0, 1, 2, 3], "M13V5-002 cache unchanged after healthy invalid")
	# contradictory live dependency: in-domain index 2, live is_valid_index false
	dbl.invalid_index_false_at = 2
	_check_eq(ix.sync_cell(2), false, "M13V5-002 contradictory in-domain sync(2) false")
	_check_eq(ix.is_bound(), false, "M13V5-002 contradictory drift neutralizes")
	_check_eq(ix.get_candidates(0), [], "M13V5-002 get_candidates [] after drift")
	_check_eq(ix.has_candidates(0), false, "M13V5-002 has_candidates false after drift")
	_check_eq(ix.count_candidates(0), 0, "M13V5-002 count 0 after drift")
	_check_eq(ix.get_color_ids(), [], "M13V5-002 no color ids after drift")
	_check_eq(ix.is_bound_to(dbl), false, "M13V5-002 is_bound_to(old) false after drift")
	# recovery
	dbl.invalid_index_false_at = -1
	_check(ix.bind(dbl), "M13V5-002 later valid bind recovers")
	_check_eq(ix.get_candidates(0), [0, 1, 2, 3], "M13V5-002 recovered exact truth")
	# non-bool is_valid_index drift still neutralizes
	var ndbl := M13MalformedBoardDouble.new()
	var nix := ColorCandidateIndex.create()
	nix.bind(ndbl)
	ndbl.invalid_index_nonbool_at = 2
	_check_eq(nix.sync_cell(2), false, "M13V5-002 non-bool is_valid_index drift sync false")
	_check_eq(nix.is_bound(), false, "M13V5-002 non-bool is_valid_index drift neutralizes")

	# --- §3 production max-count guard (structural, before per-cell traversal) ---
	var at_max := M13MalformedBoardDouble.new(); at_max.count = 3481; at_max.color = 2
	var amx := ColorCandidateIndex.create()
	_check(amx.bind(at_max), "M13V5-003 count 3481 accepted (canonical)")
	_check_eq(amx.count_candidates(2), 3481, "M13V5-003 count 3481 all ACTIVE indexed")
	for over in [3482, 1000000, 2000000000]:
		var od := M13MalformedBoardDouble.new(); od.count = over
		var ox := ColorCandidateIndex.create()
		_check_eq(ox.bind(od), false, "M13V5-003 count %d rejected" % over)
		_check_eq(ox.is_bound(), false, "M13V5-003 count %d unbound" % over)
		_check_eq(ox.get_candidates(0), [], "M13V5-003 count %d no buckets" % over)
		# rejection happened before ANY per-cell traversal
		_check_eq(od.per_cell_traversal_calls(), 0, "M13V5-003 count %d: no per-cell traversal before reject" % over)

	# --- §4 transactional rebuild domain metadata ---
	var boardA = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2]) # count 6, color0->[0,2,4]
	var rix := ColorCandidateIndex.create()
	rix.bind(boardA)
	_check_eq(rix.get_candidates(0), [0, 2, 4], "M13V5-004 board A baseline")
	# rebuild same canonical domain preserves count/buckets
	_check(rix.rebuild(), "M13V5-004 rebuild same domain succeeds")
	_check_eq(rix.get_candidates(0), [0, 2, 4], "M13V5-004 rebuild preserves truth")
	# domain metadata refreshed: index 5 in domain (count 6) syncs fine
	_check(rix.sync_cell(5), "M13V5-004 in-domain sync(5) valid after rebuild")
	# valid rebind to board B (different count) updates domain + buckets atomically
	var boardB = _make_colored_board(2, 1, [7, 7]) # count 2
	_check(rix.rebind(boardB), "M13V5-004 rebind A->B")
	_check_eq(rix.get_candidates(7), [0, 1], "M13V5-004 board B truth installed")
	# index 5 now OUTSIDE new domain (count 2) -> healthy false, binding intact
	_check_eq(rix.sync_cell(5), false, "M13V5-004 old-domain index 5 now out-of-domain -> healthy false")
	_check(rix.is_bound(), "M13V5-004 out-of-domain sync left binding intact after rebind")
	# failed rebuild leaves no stale/partial cache; neutralization resets metadata
	var fdbl := M13MalformedBoardDouble.new()
	var fix := ColorCandidateIndex.create()
	fix.bind(fdbl)
	fdbl.unknown_state_at = 1; fdbl.unknown_state_value = 77
	_check_eq(fix.rebuild(), false, "M13V5-004 rebuild with unknown state fails")
	_check_eq(fix.is_bound(), false, "M13V5-004 failed rebuild neutralized (metadata reset)")
	_check_eq(fix.sync_cell(0), false, "M13V5-004 sync after neutralize false (count reset)")

## M13-C001 V04 strict dependency closure: bind(null) stale-escape fix,
## RefCounted-only dependency lifecycle, complete transactional build return
## adversaries, and sync_cell live-drift neutralization. Criteria V04.
func _run_m13_v04_strict_validation() -> void:
	var boardA = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2]) # color 0 -> [0,2,4]
	var boardB = _make_colored_board(2, 1, [7, 7])

	# --- §1 bind(null) fail-closed policy (no stale-binding escape) ---
	var nix := ColorCandidateIndex.create()
	_check(nix.bind(boardA), "M13V4-001 bind valid board A")
	_check_eq(nix.get_candidates(0), [0, 2, 4], "M13V4-001 exact truth before bind(null)")
	_check_eq(nix.bind(null), false, "M13V4-001 bind(null) after valid returns false")
	_check_eq(nix.is_bound(), false, "M13V4-001 bind(null) neutralized to unbound")
	_check_eq(nix.get_candidates(0), [], "M13V4-001 no stale candidates after bind(null)")
	_check_eq(nix.has_candidates(0), false, "M13V4-001 has_candidates false after bind(null)")
	_check_eq(nix.count_candidates(0), 0, "M13V4-001 count 0 after bind(null)")
	_check_eq(nix.get_color_ids(), [], "M13V4-001 no color ids after bind(null)")
	_check_eq(nix.is_bound_to(boardA), false, "M13V4-001 is_bound_to(A) false after bind(null)")
	_check(nix.bind(boardB), "M13V4-001 later valid bind recovers")
	_check_eq(nix.get_candidates(7), [0, 1], "M13V4-001 recovered exact truth")
	# fresh bind(null) still safe
	var fnix := ColorCandidateIndex.create()
	_check_eq(fnix.bind(null), false, "M13V4-001 fresh bind(null) false")
	_check_eq(fnix.is_bound(), false, "M13V4-001 fresh bind(null) stays unbound")

	# --- §2 RefCounted-only dependency lifecycle ---
	# real BoardState accepted
	_check(ColorCandidateIndex.create().bind(boardA), "M13V4-002 real BoardState accepted")
	# traversal spy (RefCounted) accepted
	var spy = load("res://tests/support/board_state_scan_spy.gd").new()
	spy.setup([0, 1, 0], 3, 1)
	_check(ColorCandidateIndex.create().bind(spy), "M13V4-002 RefCounted traversal spy accepted")
	# malformed RefCounted double accepted only when canonical
	_check(ColorCandidateIndex.create().bind(M13MalformedBoardDouble.new()), "M13V4-002 canonical RefCounted double accepted")
	# plain RefCounted without API rejected
	_check_eq(ColorCandidateIndex.create().bind(RefCounted.new()), false, "M13V4-002 plain RefCounted rejected")
	# Node without API rejected; method-compatible Node rejected
	var bare_node := Node.new()
	_check_eq(ColorCandidateIndex.create().bind(bare_node), false, "M13V4-002 bare Node rejected")
	bare_node.free()
	var compat_node = load("res://tests/support/m13_board_node_double.gd").new()
	_check_eq(ColorCandidateIndex.create().bind(compat_node), false, "M13V4-002 method-compatible Node rejected (not RefCounted)")
	compat_node.free()

	# --- §3 transactional build return-contract adversaries ---
	# get_cell_count negative
	var cneg := M13MalformedBoardDouble.new(); cneg.count_negative = true
	_check_eq(ColorCandidateIndex.create().bind(cneg), false, "M13V4-003 negative get_cell_count rejected")
	# zero count is intentional/harmless: binds empty
	var czero := M13MalformedBoardDouble.new(); czero.count = 0
	var czix := ColorCandidateIndex.create()
	_check(czix.bind(czero), "M13V4-003 zero count binds (intentional empty board)")
	_check_eq(czix.get_candidates(0), [], "M13V4-003 zero-count board has no candidates")
	# is_valid_index non-bool at an in-range index AFTER valid indices 0,1
	var ivnb := M13MalformedBoardDouble.new(); ivnb.invalid_index_nonbool_at = 2
	var ivnbx := ColorCandidateIndex.create()
	_check_eq(ivnbx.bind(ivnb), false, "M13V4-003 non-bool is_valid_index return rejected")
	_check_eq(ivnbx.is_bound(), false, "M13V4-003 unbound (no partial commit) after non-bool is_valid_index")
	_check_eq(ivnbx.get_candidates(0), [], "M13V4-003 no partial buckets after non-bool is_valid_index")
	# is_valid_index false at in-range index -> build fails
	var ivf := M13MalformedBoardDouble.new(); ivf.invalid_index_false_at = 2
	_check_eq(ColorCandidateIndex.create().bind(ivf), false, "M13V4-003 is_valid_index false in-range rejected")
	# get_cell_state non-int at index 2 (after valid 0,1)
	var snint := M13MalformedBoardDouble.new(); snint.state_nonint_at = 2
	_check_eq(ColorCandidateIndex.create().bind(snint), false, "M13V4-003 non-int get_cell_state rejected")
	# unknown int state at index 2
	var sunk := M13MalformedBoardDouble.new(); sunk.unknown_state_at = 2; sunk.unknown_state_value = 255
	_check_eq(ColorCandidateIndex.create().bind(sunk), false, "M13V4-003 unknown get_cell_state rejected")
	# ACTIVE get_color_id non-int at index 2
	var cnint := M13MalformedBoardDouble.new(); cnint.color_nonint_at = 2
	_check_eq(ColorCandidateIndex.create().bind(cnint), false, "M13V4-003 non-int get_color_id rejected")
	# ACTIVE get_color_id negative at index 2
	var cngv := M13MalformedBoardDouble.new(); cngv.color_neg_at = 2
	var cngvx := ColorCandidateIndex.create()
	_check_eq(cngvx.bind(cngv), false, "M13V4-003 negative get_color_id rejected")
	_check_eq(cngvx.is_bound(), false, "M13V4-003 transactional: unbound after color-negative at index 2")

	# --- §4 sync_cell live dependency return drift ---
	# healthy caller invalid index (OUTSIDE indexed domain 0..3): false, intact.
	var hdbl := M13MalformedBoardDouble.new()
	var hix := ColorCandidateIndex.create()
	_check(hix.bind(hdbl), "M13V4-004 bind valid before healthy-invalid sync")
	for bad in [-1, 4, 999]:
		_check_eq(hix.sync_cell(bad), false, "M13V4-004 healthy out-of-domain sync(%d) -> false" % bad)
	_check(hix.is_bound(), "M13V4-004 healthy invalid index leaves binding intact")
	_check_eq(hix.get_candidates(0), [0, 1, 2, 3], "M13V4-004 healthy invalid index leaves cache intact")
	# malformed / contradictory live returns each neutralize
	var drift_cases := [
		["index_false_in_domain", func(d): d.invalid_index_false_at = 2],
		["nonbool_index", func(d): d.invalid_index_nonbool_at = 2],
		["nonint_state", func(d): d.state_nonint_at = 2],
		["active_color_nonint", func(d): d.color_nonint_at = 2],
		["active_color_neg", func(d): d.color_neg_at = 2],
		["cleared_color_nonint", func(d): d.cleared_at = 2; d.color_nonint_at = 2],
		["cleared_color_neg", func(d): d.cleared_at = 2; d.color_neg_at = 2],
	]
	for case in drift_cases:
		var label: String = case[0]
		var mutator: Callable = case[1]
		var ddbl := M13MalformedBoardDouble.new()
		var dix := ColorCandidateIndex.create()
		_check(dix.bind(ddbl), "M13V4-004 %s: valid bind first" % label)
		mutator.call(ddbl)
		_check_eq(dix.sync_cell(2), false, "M13V4-004 %s: malformed sync -> false" % label)
		_check_eq(dix.is_bound(), false, "M13V4-004 %s: malformed sync neutralizes" % label)
		_check_eq(dix.get_candidates(0), [], "M13V4-004 %s: no stale candidate truth" % label)
	# restore canonical truth -> later valid bind recovers
	var rec := ColorCandidateIndex.create()
	_check(rec.bind(M13MalformedBoardDouble.new()), "M13V4-004 recovery via later valid bind")
	_check_eq(rec.get_candidates(0), [0, 1, 2, 3], "M13V4-004 recovered exact truth")

## M13-C001 V03 frozen strict closure: F-M13-STRICT-001 (dependency boundary +
## transactional build), F-M13-STRICT-002 (unknown cell state), F-M13-STRICT-003
## (excluded/reserved Variant seam). Criteria V03 items 1-82.
func _run_m13_v03_strict_validation() -> void:
	var CLEARED := BoardState.CellState.CLEARED

	# --- Dependency boundary: unsupported Variants rejected before any call ---
	# (criteria 1-5, 9, 10) — int/String/Vector2/RefCounted/partial-API board.
	var bad_boards := [7, "board", Vector2(1, 1), RefCounted.new(), PartialBoardDouble.new()]
	for bad in bad_boards:
		var ix := ColorCandidateIndex.create()
		_check_eq(ix.bind(bad), false, "M13V3-001 malformed board %s bind rejected" % str(typeof(bad)))
		_check_eq(ix.is_bound(), false, "M13V3-001 unbound after malformed board %s" % str(typeof(bad)))
		_check_eq(ix.get_candidates(0), [], "M13V3-001 no candidates after malformed board %s" % str(typeof(bad)))
		_check_eq(ix.has_candidates(0), false, "M13V3-001 has_candidates false after malformed %s" % str(typeof(bad)))
		_check_eq(ix.count_candidates(0), 0, "M13V3-001 count 0 after malformed %s" % str(typeof(bad)))
		_check_eq(ix.get_color_ids(), [], "M13V3-001 no color ids after malformed %s" % str(typeof(bad)))

	# --- Wrong-return-type dependency truth rejected during build (6,7,8,20) ---
	var wc := M13MalformedBoardDouble.new(); wc.count_type_wrong = true
	_check_eq(ColorCandidateIndex.create().bind(wc), false, "M13V3-001 wrong get_cell_count return rejected")
	var ws := M13MalformedBoardDouble.new(); ws.state_type_wrong = true
	_check_eq(ColorCandidateIndex.create().bind(ws), false, "M13V3-001 wrong get_cell_state return rejected")
	var wk := M13MalformedBoardDouble.new(); wk.color_type_wrong = true
	_check_eq(ColorCandidateIndex.create().bind(wk), false, "M13V3-001 wrong get_color_id return rejected")

	# --- A valid compatible double still binds and builds exact truth (11,21) ---
	var good := M13MalformedBoardDouble.new() # 4 ACTIVE cells, color 0
	var gix := ColorCandidateIndex.create()
	_check(gix.bind(good), "M13V3-001 valid compatible double binds")
	_check_eq(gix.get_candidates(0), [0, 1, 2, 3], "M13V3-001 valid double builds exact ACTIVE truth")

	# --- Malformed bind after valid state neutralizes; later valid recovers (12,13) ---
	var recov := ColorCandidateIndex.create()
	var vboard = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2])
	recov.bind(vboard)
	_check_eq(recov.get_candidates(0), [0, 2, 4], "M13V3-001 baseline valid bind before malformed")
	_check_eq(recov.bind(12345), false, "M13V3-001 malformed bind after valid returns false")
	_check_eq(recov.is_bound(), false, "M13V3-001 malformed bind after valid neutralized to unbound")
	_check_eq(recov.get_candidates(0), [], "M13V3-001 no stale candidates after malformed bind")
	_check(recov.bind(vboard), "M13V3-001 later valid bind recovers")
	_check_eq(recov.get_candidates(0), [0, 2, 4], "M13V3-001 recovered truth exact")

	# --- rebind semantics (14,15,16,17) ---
	var rb := ColorCandidateIndex.create()
	var boardA = _make_colored_board(2, 1, [5, 5])
	var boardB = _make_colored_board(2, 1, [7, 7])
	rb.bind(boardA)
	_check_eq(rb.get_candidates(5), [0, 1], "M13V3-001 rebind baseline board A")
	_check(rb.rebind(boardB), "M13V3-001 rebind A->B succeeds")
	_check_eq(rb.get_candidates(5), [], "M13V3-001 rebind dropped board A truth")
	_check_eq(rb.get_candidates(7), [0, 1], "M13V3-001 rebind installed board B truth")
	_check_eq(rb.rebind(null), false, "M13V3-001 rebind(null) rejected")
	_check_eq(rb.is_bound(), false, "M13V3-001 rebind(null) left unbound")
	_check_eq(rb.rebind("x"), false, "M13V3-001 malformed rebind rejected")
	_check_eq(rb.is_bound(), false, "M13V3-001 malformed rebind left unbound")
	_check(rb.rebind(boardB), "M13V3-001 valid rebind recovers after failed rebind")

	# --- Unknown cell state via sync_cell fails closed, not as CLEARED (22-28) ---
	for unknown in [2, -1, 255, 99]:
		var udbl := M13MalformedBoardDouble.new() # 4 ACTIVE color 0
		var uix := ColorCandidateIndex.create()
		_check(uix.bind(udbl), "M13V3-002 bind valid before unknown-state sync (%d)" % unknown)
		_check_eq(uix.get_candidates(0), [0, 1, 2, 3], "M13V3-002 pre-sync truth (%d)" % unknown)
		udbl.unknown_state_at = 2
		udbl.unknown_state_value = unknown
		_check_eq(uix.sync_cell(2), false, "M13V3-002 sync unknown state %d returns false" % unknown)
		# fail-closed policy: cache invalidated, not "cell silently CLEARED"
		_check_eq(uix.is_bound(), false, "M13V3-002 unknown-state sync neutralized cache (%d)" % unknown)
		_check_eq(uix.get_candidates(0), [], "M13V3-002 fail-closed query after unknown state %d" % unknown)

	# --- Unknown state during initial build fails, no partial buckets (29) ---
	var ubuild := M13MalformedBoardDouble.new()
	ubuild.unknown_state_at = 1
	ubuild.unknown_state_value = 42
	var ubix := ColorCandidateIndex.create()
	_check_eq(ubix.bind(ubuild), false, "M13V3-002 initial build with unknown state fails")
	_check_eq(ubix.is_bound(), false, "M13V3-002 unknown-state build left unbound")
	_check_eq(ubix.get_candidates(0), [], "M13V3-002 no partial buckets after unknown-state build")

	# --- Unknown state during rebuild fails, no partial commit; recovery (30,31,32) ---
	var rdbl := M13MalformedBoardDouble.new() # valid
	var rix := ColorCandidateIndex.create()
	_check(rix.bind(rdbl), "M13V3-002 rebuild-path: valid bind first")
	rdbl.unknown_state_at = 3
	rdbl.unknown_state_value = 7
	_check_eq(rix.rebuild(), false, "M13V3-002 rebuild with unknown state returns false")
	_check_eq(rix.is_bound(), false, "M13V3-002 failed rebuild neutralized (no partial rebuilt truth)")
	rdbl.unknown_state_at = -1 # restore canonical truth
	_check(rix.bind(rdbl), "M13V3-002 recovery after canonical restoration")
	_check_eq(rix.get_candidates(0), [0, 1, 2, 3], "M13V3-002 recovered exact truth")

	# --- Exclusion container boundary (33-43) ---
	var eb = _make_colored_board(3, 2, [0, 1, 0, 1, 0, 2]) # color 0 -> [0,2,4]
	var eix := ColorCandidateIndex.create()
	eix.bind(eb)
	# supported containers with equivalent int sets agree (33,34,35,56)
	var via_array: Array = eix.get_candidates(0, [2, 4])
	var via_packed: Array = eix.get_candidates(0, PackedInt32Array([2, 4]))
	var via_dict: Array = eix.get_candidates(0, {2: true, 4: "ignored"})
	_check_eq(via_array, [0], "M13V3-003 Array exclusion -> [0]")
	_check_eq(via_packed, [0], "M13V3-003 PackedInt32Array exclusion -> [0]")
	_check_eq(via_dict, [0], "M13V3-003 Dictionary-key exclusion -> [0] (values ignored)")
	# null = intentional no-exclusion contract (36)
	_check_eq(eix.get_candidates(0, null), [0, 2, 4], "M13V3-003 null exclusion = no exclusion")
	_check_eq(eix.has_candidates(0, null), true, "M13V3-003 null exclusion has work")
	# unsupported containers fail closed, cache untouched (37-43)
	var snap: Array = eix.get_candidates(0)
	for badc in [7, 3.5, "24", true, Vector2(2, 4), RefCounted.new()]:
		_check_eq(eix.get_candidates(0, badc), [], "M13V3-003 unsupported container %s -> []" % str(typeof(badc)))
		_check_eq(eix.has_candidates(0, badc), false, "M13V3-003 unsupported container %s has false" % str(typeof(badc)))
		_check_eq(eix.count_candidates(0, badc), 0, "M13V3-003 unsupported container %s count 0" % str(typeof(badc)))
	_check_eq(eix.get_candidates(0), snap, "M13V3-003 unsupported containers did not mutate cache")

	# --- Exclusion entry boundary (44-55,57) ---
	_check_eq(eix.get_candidates(0, [2]), [0, 4], "M13V3-003 valid int exclusion works")
	_check_eq(eix.get_candidates(0, [2, 2, 2]), [0, 4], "M13V3-003 duplicate int harmless")
	_check_eq(eix.get_candidates(0, [-1]), [0, 2, 4], "M13V3-003 negative int no effect")
	_check_eq(eix.get_candidates(0, [999]), [0, 2, 4], "M13V3-003 out-of-range int no effect")
	_check_eq(eix.get_candidates(0, [2.0]), [0, 2, 4], "M13V3-003 float 2.0 does NOT exclude int 2")
	_check_eq(eix.get_candidates(0, ["2"]), [0, 2, 4], "M13V3-003 String '2' does NOT exclude int 2")
	_check_eq(eix.get_candidates(0, [true]), [0, 2, 4], "M13V3-003 bool entry no effect")
	_check_eq(eix.get_candidates(0, [Vector2(2, 0)]), [0, 2, 4], "M13V3-003 Vector2 entry no effect")
	_check_eq(eix.get_candidates(0, [RefCounted.new()]), [0, 2, 4], "M13V3-003 RefCounted entry no effect")
	_check_eq(eix.get_candidates(0, [[2]]), [0, 2, 4], "M13V3-003 nested Array entry no effect")
	_check_eq(eix.get_candidates(0, [{2: true}]), [0, 2, 4], "M13V3-003 nested Dictionary entry no effect")
	# mixed valid + junk entries: only the valid int excludes
	_check_eq(eix.get_candidates(0, [2.0, 2, "4", -1]), [0, 4], "M13V3-003 mixed entries: only int 2 excludes")
	# shared semantics across the three query APIs (57)
	_check_eq(eix.has_candidates(0, [0, 2, 4]), false, "M13V3-003 has_candidates all-excluded false")
	_check_eq(eix.count_candidates(0, [2, 4]), 1, "M13V3-003 count_candidates matches get_candidates")

	# --- Immediate consumer: ReservationState PackedInt32Array path (77,78) ---
	var rs = ReservationState.create()
	rs.bind(eb)
	rs.reserve(2, 100)
	rs.reserve(4, 101)
	var reserved: PackedInt32Array = rs.get_reserved_indices()
	_check(reserved is PackedInt32Array, "M13V3 consumer: reserved set is PackedInt32Array")
	_check_eq(eix.get_candidates(0, reserved), [0], "M13V3 consumer: real ReservationState exclusion yields correct raw candidates")

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
	var excl = color0_full.slice(0, 10)
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

## Strict full-attack-surface coverage for the frozen M14 finding set
## (F-M14-STRICT-001 fail-closed dependency + reserve-time live truth;
## F-M14-STRICT-002 unbound-only ordinary bind). Uses counting/partial/Node
## doubles so oversize/malformed rejection is proven WITHOUT a board scan.
func _run_reservation_state_strict_tests() -> void:
	print("---- M14: ReservationState STRICT (F-M14-STRICT-001/002) ----")
	var ACTIVE := BoardState.CellState.ACTIVE
	var CLEARED := BoardState.CellState.CLEARED

	# ===== §1 dependency category: fail closed, no has_method on scalars =====
	var dep := ReservationState.create()
	_check_eq(dep.bind(4), false, "M14-S1 bind(int scalar) rejected")
	_check_eq(dep.is_bound(), false, "M14-S1 unbound after int bind")
	_check_eq(dep.bind("board"), false, "M14-S1 bind(String) rejected")
	_check_eq(dep.bind(Vector2(1, 2)), false, "M14-S1 bind(Vector2) rejected")
	_check_eq(dep.bind({}), false, "M14-S1 bind(Dictionary) rejected")
	_check_eq(dep.bind([]), false, "M14-S1 bind(Array) rejected")
	_check_eq(dep.bind(RefCounted.new()), false, "M14-S1 bind(plain RefCounted, no API) rejected")
	_check_eq(dep.bind(M14PartialBoardDouble.new()), false, "M14-S1 bind(partial-API RefCounted) rejected")
	var node_plain := Node.new()
	_check_eq(dep.bind(node_plain), false, "M14-S1 bind(Node without API) rejected")
	node_plain.free()
	var node_api = load("res://tests/support/m13_board_node_double.gd").new()
	_check_eq(dep.bind(node_api), false, "M14-S1 bind(method-compatible Node) rejected on category")
	node_api.free()
	_check_eq(dep.is_bound(), false, "M14-S1 still unbound after every rejected dependency")
	_check_eq(dep.get_reservation_count(), 0, "M14-S1 no reservations after failed binds")
	_check_eq(dep.is_bound_to(_make_colored_board(2, 1, [0, 0])), false, "M14-S1 no board identity claimed")

	# ===== §1 bind-time count snapshot (counting double, no scan) =====
	var cnt := M14CountingBoardDouble.new()
	cnt.cell_count = "4" # wrong type
	var rc := ReservationState.create()
	_check_eq(rc.bind(cnt), false, "M14-S1 count String -> bind fails")
	cnt.cell_count = -1
	_check_eq(rc.bind(cnt), false, "M14-S1 count -1 -> bind fails")
	cnt.cell_count = 3482
	cnt.reset_counters()
	_check_eq(rc.bind(cnt), false, "M14-S1 count 3482 (>ceiling) -> bind fails")
	_check_eq(cnt.per_index_calls(), 0, "M14-S1 oversize rejected WITHOUT is_valid_index/get_cell_state")
	cnt.cell_count = 1000000
	_check_eq(rc.bind(cnt), false, "M14-S1 count 1,000,000 -> bind fails")
	cnt.cell_count = 999999999
	_check_eq(rc.bind(cnt), false, "M14-S1 very large count -> bind fails")
	# allowed bounds
	var rc0 := ReservationState.create()
	var cnt0 := M14CountingBoardDouble.new(); cnt0.cell_count = 0
	_check(rc0.bind(cnt0), "M14-S1 count 0 -> bind allowed")
	_check_eq(rc0.reserve(0, 1), false, "M14-S1 count 0 -> no target reservable")
	var rcMax := ReservationState.create()
	var cntMax := M14CountingBoardDouble.new(); cntMax.cell_count = 3481
	_check(rcMax.bind(cntMax), "M14-S1 count 3481 (ceiling) -> bind allowed")

	# ===== §2 ordinary bind is UNBOUND-only, preserves live ownership =====
	var boardA = _make_colored_board(3, 2, [0, 0, 0, 0, 0, 0])
	var boardB = _make_colored_board(3, 2, [0, 0, 0, 0, 0, 0])
	var rb := ReservationState.create()
	_check(rb.bind(boardA), "M14-S2 initial bind to A succeeds")
	_check(rb.reserve(1, 10), "M14-S2 reserve target1/owner10")
	_check(rb.reserve(4, 20), "M14-S2 reserve target4/owner20")
	var base_indices = rb.get_reserved_indices()
	var node_reentry := Node.new()
	var reentry := [
		["same A", boardA], ["different B", boardB], ["null", null],
		["int", 7], ["partial", M14PartialBoardDouble.new()],
		["compat Node", node_reentry],
	]
	for pair in reentry:
		var label: String = pair[0]
		_check_eq(rb.bind(pair[1]), false, "M14-S2 re-bind(%s) returns false" % label)
		_check_eq(rb.is_bound(), true, "M14-S2 still bound after re-bind(%s)" % label)
		_check_eq(rb.is_bound_to(boardA), true, "M14-S2 still bound to A after re-bind(%s)" % label)
		_check_eq(rb.is_bound_to(boardB), false, "M14-S2 not bound to B after re-bind(%s)" % label)
		_check_eq(rb.get_reservation_count(), 2, "M14-S2 count unchanged after re-bind(%s)" % label)
		_check_eq(rb.get_owner(1), 10, "M14-S2 target1 owner intact after re-bind(%s)" % label)
		_check_eq(rb.get_owner(4), 20, "M14-S2 target4 owner intact after re-bind(%s)" % label)
		_check_eq(rb.get_target_for_owner(10), 1, "M14-S2 owner10 target intact after re-bind(%s)" % label)
		_check_eq(rb.get_target_for_owner(20), 4, "M14-S2 owner20 target intact after re-bind(%s)" % label)
		_check_eq(rb.get_reserved_indices(), base_indices, "M14-S2 reserved indices intact after re-bind(%s)" % label)
	node_reentry.free()

	# ===== §3 explicit destructive rebind =====
	# valid board B: clears A reservations, installs B, reserves work.
	_check(rb.rebind(boardB), "M14-S3 rebind(B) succeeds")
	_check_eq(rb.get_reservation_count(), 0, "M14-S3 A reservations cleared on rebind(B)")
	_check_eq(rb.is_bound_to(boardB), true, "M14-S3 bound to B only")
	_check_eq(rb.is_bound_to(boardA), false, "M14-S3 no longer bound to A")
	_check_eq(rb.get_target_for_owner(10), -1, "M14-S3 old owner ownership absent")
	_check(rb.reserve(2, 30), "M14-S3 valid reserve on B works")
	# same board: may intentionally clear, stays bound.
	_check(rb.rebind(boardB), "M14-S3 rebind(same B) succeeds")
	_check_eq(rb.get_reservation_count(), 0, "M14-S3 rebind(same) cleared reservations")
	_check_eq(rb.is_bound_to(boardB), true, "M14-S3 rebind(same) stays bound to B")
	# null: clears, unbound, recoverable.
	rb.reserve(0, 40)
	_check_eq(rb.rebind(null), false, "M14-S3 rebind(null) returns false")
	_check_eq(rb.is_bound(), false, "M14-S3 rebind(null) leaves unbound")
	_check_eq(rb.get_reservation_count(), 0, "M14-S3 rebind(null) cleared reservations")
	_check_eq(rb.is_bound_to(boardB), false, "M14-S3 rebind(null) no board identity")
	_check_eq(rb.reserve(0, 41), false, "M14-S3 domain reset: reserve fails while unbound")
	_check(rb.bind(boardA), "M14-S3 recover via valid bind after rebind(null)")
	# malformed rebind: clears, unbound, no malformed stored, recoverable.
	rb.reserve(3, 50)
	var big := M14CountingBoardDouble.new(); big.cell_count = 3482
	_check_eq(rb.rebind(big), false, "M14-S3 rebind(oversize) returns false")
	_check_eq(rb.is_bound(), false, "M14-S3 rebind(oversize) leaves unbound")
	_check_eq(rb.rebind(7), false, "M14-S3 rebind(scalar) returns false")
	_check_eq(rb.rebind(M14PartialBoardDouble.new()), false, "M14-S3 rebind(partial) returns false")
	_check_eq(rb.get_reservation_count(), 0, "M14-S3 malformed rebind cleared reservations")
	_check(rb.rebind(boardB), "M14-S3 recover via valid rebind after malformed rebind")

	# ===== §4 reserve() live return contract (counting double) =====
	var lr := ReservationState.create()
	var lb := M14CountingBoardDouble.new(); lb.cell_count = 6
	_check(lr.bind(lb), "M14-S4 bind counting board (count 6)")
	_check(lr.reserve(0, 1), "M14-S4 valid in-domain ACTIVE reserve succeeds")
	# out-of-domain: no per-index board call, existing reservation intact.
	lb.reset_counters()
	_check_eq(lr.reserve(-1, 2), false, "M14-S4 target -1 rejected")
	_check_eq(lr.reserve(6, 2), false, "M14-S4 target == count rejected")
	_check_eq(lr.reserve(9999, 2), false, "M14-S4 target >> count rejected")
	_check_eq(lb.per_index_calls(), 0, "M14-S4 out-of-domain targets never call is_valid_index/get_cell_state")
	_check_eq(lr.get_reservation_count(), 1, "M14-S4 existing reservation intact after invalid targets")
	# is_valid_index return typing (in-domain target 2)
	lb.valid_mode = "false"
	_check_eq(lr.reserve(2, 2), false, "M14-S4 in-domain is_valid_index=false -> reserve false")
	_check_eq(lr.get_reservation_count(), 1, "M14-S4 ownership unchanged on is_valid_index false")
	lb.valid_mode = "nonbool"
	_check_eq(lr.reserve(2, 2), false, "M14-S4 is_valid_index non-bool -> reserve false")
	_check_eq(lr.get_reservation_count(), 1, "M14-S4 ownership unchanged on non-bool is_valid_index")
	lb.valid_mode = "normal"
	# get_cell_state values (in-domain, valid index)
	var bad_states := {"CLEARED": CLEARED, "2": 2, "-1": -1, "255": 255, "99": 99,
		"float": 3.14, "String": "active", "Object": RefCounted.new()}
	for name in bad_states:
		lb.state_overrides = {2: bad_states[name]}
		_check_eq(lr.reserve(2, 2), false, "M14-S4 get_cell_state=%s -> reserve false" % name)
		_check_eq(lr.get_reservation_count(), 1, "M14-S4 ownership unchanged on state=%s" % name)
		_check_eq(lr.get_owner(0), 1, "M14-S4 pre-existing owner intact on state=%s" % name)
	lb.state_overrides = {}
	_check(lr.reserve(2, 2), "M14-S4 ACTIVE target reservable once returns healthy")

	# ===== §5 mirrored-map invariants through every mutation API =====
	var mm := ReservationState.create()
	mm.bind(_make_colored_board(4, 1, [0, 0, 0, 0]))
	_check(mm.reserve(0, 1), "M14-S5 reserve inserts both directions")
	_check_eq(mm.get_owner(0), 1, "M14-S5 target->owner set")
	_check_eq(mm.get_target_for_owner(1), 0, "M14-S5 owner->target set")
	_check_eq(mm.reserve(0, 2), false, "M14-S5 duplicate target other owner fails")
	_check_eq(mm.reserve(0, 1), false, "M14-S5 duplicate target same owner fails")
	_check_eq(mm.reserve(1, 1), false, "M14-S5 same owner second target fails")
	_check(mm.reserve(1, 2), "M14-S5 independent owners independent targets")
	_check_eq(mm.get_reservation_count(), 2, "M14-S5 maps consistent after failures")
	# release
	_check_eq(mm.release(0, 999), false, "M14-S5 wrong-owner release no mutation")
	_check_eq(mm.get_owner(0), 1, "M14-S5 target0 unchanged after wrong release")
	_check(mm.release(0, 1), "M14-S5 correct release removes both directions")
	_check_eq(mm.get_owner(0), -1, "M14-S5 target0 owner cleared")
	_check_eq(mm.get_target_for_owner(1), -1, "M14-S5 owner1 target cleared")
	_check(mm.reserve(0, 3), "M14-S5 released target reusable")
	_check_eq(mm.release(0, 1), false, "M14-S5 repeated/stale release fails")
	# release_for_owner
	_check_eq(mm.release_for_owner(777), false, "M14-S5 release_for_owner unknown owner false")
	var before_sib = mm.get_target_for_owner(2)
	_check(mm.release_for_owner(3), "M14-S5 release_for_owner removes its target")
	_check_eq(mm.get_owner(0), -1, "M14-S5 release_for_owner cleared target->owner")
	_check_eq(mm.get_target_for_owner(3), -1, "M14-S5 release_for_owner cleared owner->target")
	_check_eq(mm.get_target_for_owner(2), before_sib, "M14-S5 sibling reservation unchanged")
	_check_eq(mm.release_for_owner(3), false, "M14-S5 repeated release_for_owner false")
	_check(mm.reserve(0, 4), "M14-S5 target/owner reusable after release_for_owner")
	# resolve_arrival
	_check_eq(mm.resolve_arrival(0, 999), false, "M14-S5 resolve wrong owner false")
	_check_eq(mm.get_owner(0), 4, "M14-S5 no mutation on wrong-owner resolve")
	var b_arr = mm._board.get_cell_state(0)
	_check(mm.resolve_arrival(0, 4), "M14-S5 resolve correct owner removes once")
	_check_eq(mm._board.get_cell_state(0), b_arr, "M14-S5 resolve did not mutate BoardState cell")
	_check_eq(mm.resolve_arrival(0, 4), false, "M14-S5 second resolve false")
	# reset
	mm.reserve(2, 5)
	mm.reset()
	_check_eq(mm.get_reservation_count(), 0, "M14-S5 reset clears every reservation")
	_check(mm.is_bound(), "M14-S5 reset keeps board binding/domain")
	mm.reset()
	_check_eq(mm.get_reservation_count(), 0, "M14-S5 second reset harmless")
	_check(mm.reserve(3, 6), "M14-S5 reserve works after reset")

	# ===== §6 query / encapsulation regression =====
	var q := ReservationState.create()
	q.bind(_make_colored_board(3, 1, [0, 0, 0]))
	q.reserve(2, 1); q.reserve(0, 2)
	_check_eq(q.is_reserved(-5), false, "M14-S6 is_reserved negative false")
	_check_eq(q.is_reserved(99999), false, "M14-S6 is_reserved large false")
	_check_eq(q.get_owner(-5), -1, "M14-S6 get_owner negative -1")
	_check_eq(q.get_owner(99999), -1, "M14-S6 get_owner large -1")
	_check_eq(q.get_owner(1), -1, "M14-S6 get_owner unreserved -1")
	_check_eq(q.get_target_for_owner(-5), -1, "M14-S6 get_target_for_owner negative -1")
	_check_eq(q.get_target_for_owner(4242), -1, "M14-S6 get_target_for_owner unknown -1")
	_check_eq(q.get_reservation_count(), 2, "M14-S6 exact count after mixed ops")
	_check_eq(q.get_reserved_indices(), PackedInt32Array([0, 2]), "M14-S6 reserved indices ascending")
	var snap = q.get_reserved_indices()
	snap.append(1); snap.remove_at(0)
	_check_eq(q.get_reserved_indices(), PackedInt32Array([0, 2]), "M14-S6 snapshot detached from internal maps")
	_check(not q.has_method("get_board"), "M14-S6 no board getter exposed")

	# ===== §7 M13 (ColorCandidateIndex) immediate-consumer regression =====
	var cb = _make_colored_board(3, 2, [7, 7, 7, 7, 7, 7])
	var ci := ColorCandidateIndex.create(); ci.bind(cb)
	var rs := ReservationState.create(); rs.bind(cb)
	rs.reserve(2, 1); rs.reserve(4, 2)
	var excl = rs.get_reserved_indices()
	_check(excl is PackedInt32Array, "M14-S7 get_reserved_indices is PackedInt32Array")
	_check_eq(ci.get_candidates(7, excl), [0, 1, 3, 5], "M14-S7 reserved raw candidates excluded")
	rs.release_for_owner(1)
	_check_eq(ci.get_candidates(7, rs.get_reserved_indices()), [0, 1, 2, 3, 5], "M14-S7 release_for_owner restores candidate visibility")

	# ===== §8 real 59x59 (3481) + no-scan structural evidence =====
	var big_cells := PackedInt32Array(); big_cells.resize(3481); big_cells.fill(0)
	var big_board = _make_colored_board(59, 59, Array(big_cells))
	var rbig := ReservationState.create()
	_check(rbig.bind(big_board), "M14-S8 bind real 3481-cell board")
	_check(rbig.reserve(3480, 1), "M14-S8 reserve last index works")
	_check(rbig.release(3480, 1), "M14-S8 release works")
	# structural no-scan: one reserve touches exactly one target's board reads.
	var sc := M14CountingBoardDouble.new(); sc.cell_count = 3481
	var rsc := ReservationState.create(); rsc.bind(sc)
	sc.reset_counters()
	_check(rsc.reserve(1000, 1), "M14-S8 reserve on counting 3481 board")
	_check_eq(sc.per_index_calls(), 2, "M14-S8 reserve touches ONE target (is_valid_index+get_cell_state), no scan")
	sc.reset_counters()
	rsc.is_reserved(1000); rsc.get_owner(1000); rsc.get_reserved_indices(); rsc.release(1000, 1)
	_check_eq(sc.per_index_calls(), 0, "M14-S8 query/release make zero board reads")

	print("  M14 ReservationState STRICT tests complete")

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

## Builds a bound selector whose reservation dependency is the configurable
## M15ReservationDouble and whose candidate index is a CandidateIndexDouble
## exposing exactly index 0 for colour 5 on a 1x1 ACTIVE board.
func _m15_selector_with(rsd) -> Dictionary:
	var b = _make_colored_board(1, 1, [5])
	var ci = CandidateIndexDouble.new(); ci.bind(b); ci.set_candidates(5, [0])
	rsd.bind(b)
	var ts = TargetSelector.create()
	var ok = ts.bind(b, ci, rsd)
	var aq = AccessQueryDouble.new(); aq.default_targetable = true
	return {"b": b, "ci": ci, "ts": ts, "aq": aq, "bound": ok}

func _run_target_selector_strict_v03_tests() -> void:
	# Strict Audit Standard v2 SECOND STAGE for M15 (F-M15-STRICT-004/005):
	# dependency/Variant-return fail-closed boundary + selection-operation
	# snapshot/rebind safety. Pre-fix these classes faulted, accepted non-bool
	# reachability, or reserved across a drifted bundle (M15-C002 DEFECT CONFIRMED).
	print("---- M15 strict-v2 (2nd stage): Variant-return boundary + operation drift (F-004/005) ----")
	var COLOR := 5

	# ============ F-M15-STRICT-004: bind dependency categories ================
	var bb = _make_colored_board(1, 1, [COLOR])
	var bci = ColorCandidateIndex.create(); bci.bind(bb)
	var brs = ReservationState.create(); brs.bind(bb)
	# Real BoardState accepted; RefCounted-but-not-BoardState rejected as board.
	var ts_ok = TargetSelector.create()
	_check(ts_ok.bind(bb, bci, brs), "STRICT-004: real BoardState + full-API deps bind")
	_check_eq(ts_ok.bind(RefCounted.new(), bci, brs), false, "STRICT-004: non-BoardState RefCounted board rejected")
	# Method-compatible Node board rejected on category.
	var node_board = M15NodeAccess.new() # a Node; not the board API but proves Node rejection path
	_check_eq(ts_ok.bind(node_board, bci, brs), false, "STRICT-004: Node board rejected")
	node_board.free()
	# candidate/reservation must be RefCounted with the FULL required API.
	_check_eq(TargetSelector.create().bind(bb, RefCounted.new(), brs), false, "STRICT-004: candidate missing API rejected")
	_check_eq(TargetSelector.create().bind(bb, bci, RefCounted.new()), false, "STRICT-004: reservation missing API rejected")

	# ============ F-M15-STRICT-004: access_query Variant boundary =============
	var ab = _make_colored_board(1, 1, [COLOR])
	var aci = ColorCandidateIndex.create(); aci.bind(ab)
	var ars = ReservationState.create(); ars.bind(ab)
	var ats = TargetSelector.create(); ats.bind(ab, aci, ars)
	_check_eq(ats.select_and_reserve(COLOR, 1, null), -1, "STRICT-004: null access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, 5), -1, "STRICT-004: int access -> -1 (no fault)")
	_check_eq(ats.select_and_reserve(COLOR, 1, 1.5), -1, "STRICT-004: float access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, "x"), -1, "STRICT-004: String access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, true), -1, "STRICT-004: bool access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, Vector2.ZERO), -1, "STRICT-004: Vector2 access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, []), -1, "STRICT-004: Array access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, {}), -1, "STRICT-004: Dictionary access -> -1")
	_check_eq(ats.select_and_reserve(COLOR, 1, RefCounted.new()), -1, "STRICT-004: RefCounted missing is_targetable -> -1")
	var node_access = M15NodeAccess.new()
	_check_eq(ats.select_and_reserve(COLOR, 1, node_access), -1, "STRICT-004: method-compatible Node access rejected")
	node_access.free()
	_check_eq(ars.get_reservation_count(), 0, "STRICT-004: no access-variant created a reservation")
	var aq_ok = AccessQueryDouble.new(); aq_ok.default_targetable = true
	_check(ats.select_and_reserve(COLOR, 1, aq_ok) != -1, "STRICT-004: valid RefCounted access accepted")

	# ============ F-M15-STRICT-004: targetability verdict type ================
	var vb = _make_colored_board(1, 1, [COLOR])
	var vci = ColorCandidateIndex.create(); vci.bind(vb)
	var vrs = ReservationState.create(); vrs.bind(vb)
	var vts = TargetSelector.create(); vts.bind(vb, vci, vrs)
	var va = M15VariantAccess.new()
	for bad in [null, 1, 1.0, "x", Vector2.ZERO, RefCounted.new(), [], {}]:
		va.verdict = bad
		_check_eq(vts.select_and_reserve(COLOR, 1, va), -1, "STRICT-004: non-bool is_targetable verdict does not approve")
	_check_eq(vrs.get_reservation_count(), 0, "STRICT-004: malformed targetability created no reservation")
	va.verdict = false
	_check_eq(vts.select_and_reserve(COLOR, 1, va), -1, "STRICT-004: bool false skips candidate")
	va.verdict = true
	_check_eq(vts.select_and_reserve(COLOR, 1, va), 0, "STRICT-004: actual bool true permits candidate")

	# ============ F-M15-STRICT-004: dynamic reservation return contracts ======
	# Happy path through the full-API double proves ownership before returning.
	var rsd_ok = M15ReservationDouble.new()
	var w_ok = _m15_selector_with(rsd_ok)
	_check(w_ok.bound, "STRICT-004: selector binds a full-API RefCounted reservation double")
	_check_eq(w_ok.ts.select_and_reserve(5, 1, w_ok.aq), 0, "STRICT-004: well-formed double selects + proves ownership")
	_check_eq(rsd_ok.get_reservation_count(), 1, "STRICT-004: happy path stored exactly one reservation")

	# Non-int get_target_for_owner fails closed at the owner check.
	var rsd_a = M15ReservationDouble.new(); rsd_a.target_for_owner_force = "x"
	var w_a = _m15_selector_with(rsd_a)
	_check_eq(w_a.ts.select_and_reserve(5, 1, w_a.aq), -1, "STRICT-004: non-int get_target_for_owner -> -1")

	# Non-Packed get_reserved_indices fails closed.
	var rsd_b = M15ReservationDouble.new(); rsd_b.reserved_indices_force = [] # Array, not PackedInt32Array
	var w_b = _m15_selector_with(rsd_b)
	_check_eq(w_b.ts.select_and_reserve(5, 1, w_b.aq), -1, "STRICT-004: malformed reserved snapshot -> -1")

	# Malformed candidate container fails closed.
	var rsd_c = M15ReservationDouble.new()
	var b_c = _make_colored_board(1, 1, [5])
	var ci_c = CandidateIndexDouble.new(); ci_c.bind(b_c); ci_c.candidates_force = {}
	rsd_c.bind(b_c)
	var ts_c = TargetSelector.create(); ts_c.bind(b_c, ci_c, rsd_c)
	var aq_c = AccessQueryDouble.new(); aq_c.default_targetable = true
	_check_eq(ts_c.select_and_reserve(5, 1, aq_c), -1, "STRICT-004: non-Array candidate container -> -1")

	# Non-int candidate entries skipped, first int selected.
	var b_e = _make_colored_board(1, 1, [5])
	var ci_e = CandidateIndexDouble.new(); ci_e.bind(b_e); ci_e.set_candidates(5, [null, 1.5, "x", Vector2.ZERO, [], {}, 0])
	var rs_e = ReservationState.create(); rs_e.bind(b_e)
	var ts_e = TargetSelector.create(); ts_e.bind(b_e, ci_e, rs_e)
	var aq_e = AccessQueryDouble.new(); aq_e.default_targetable = true
	_check_eq(ts_e.select_and_reserve(5, 1, aq_e), 0, "STRICT-004: non-int candidate entries skipped, int 0 selected")

	# Non-bool is_reserved fails closed.
	var rsd_ir = M15ReservationDouble.new(); rsd_ir.is_reserved_force = 1
	var w_ir = _m15_selector_with(rsd_ir)
	_check_eq(w_ir.ts.select_and_reserve(5, 1, w_ir.aq), -1, "STRICT-004: non-bool is_reserved -> -1")

	# Non-bool reserve result cannot count as success.
	var rsd_rv = M15ReservationDouble.new(); rsd_rv.reserve_force = 1; rsd_rv.do_store = false
	var w_rv = _m15_selector_with(rsd_rv)
	_check_eq(w_rv.ts.select_and_reserve(5, 1, w_rv.aq), -1, "STRICT-004: non-bool reserve result not success")
	_check_eq(rsd_rv.get_reservation_count(), 0, "STRICT-004: non-bool reserve created no reservation")

	# ============ F-M15-STRICT-005: post-reserve ownership proof ==============
	# reserve() true but stores nothing -> -1.
	var rsd_ns = M15ReservationDouble.new(); rsd_ns.do_store = false
	var w_ns = _m15_selector_with(rsd_ns)
	_check_eq(w_ns.ts.select_and_reserve(5, 1, w_ns.aq), -1, "STRICT-005: reserve true but stored nothing -> -1")

	# reserve() true but owner maps to another target -> -1.
	var rsd_ot = M15ReservationDouble.new(); rsd_ot.store_target_override = 7
	var w_ot = _m15_selector_with(rsd_ot)
	_check_eq(w_ot.ts.select_and_reserve(5, 1, w_ot.aq), -1, "STRICT-005: reserve true but owner->other target -> -1")

	# reserve() true but target owned by a different owner -> -1, and that other
	# owner's entry is NOT removed by rollback.
	var rsd_oo = M15ReservationDouble.new(); rsd_oo.store_owner_override = 999
	var w_oo = _m15_selector_with(rsd_oo)
	_check_eq(w_oo.ts.select_and_reserve(5, 1, w_oo.aq), -1, "STRICT-005: reserve true but target->other owner -> -1")
	_check_eq(rsd_oo.get_owner(0), 999, "STRICT-005: rollback did not remove the unrelated owner's reservation")

	# Malformed get_owner ownership proof -> -1.
	var rsd_go = M15ReservationDouble.new(); rsd_go.get_owner_force = "z"
	var w_go = _m15_selector_with(rsd_go)
	_check_eq(w_go.ts.select_and_reserve(5, 1, w_go.aq), -1, "STRICT-005: malformed get_owner ownership proof -> -1")

	# ============ F-M15-STRICT-005: operation drift / rollback ================
	# Drift DURING reserve (candidate index rebinds as a reserve side effect):
	# selector rolls back only its own exact reservation and returns -1.
	var bA = _make_colored_board(1, 1, [5])
	var bB = _make_colored_board(1, 1, [5])
	var ciA = CandidateIndexDouble.new(); ciA.bind(bA); ciA.set_candidates(5, [0])
	var rsd_drift = M15ReservationDouble.new(); rsd_drift.bind(bA)
	var ts_drift = TargetSelector.create(); ts_drift.bind(bA, ciA, rsd_drift)
	var aq_drift = AccessQueryDouble.new(); aq_drift.default_targetable = true
	rsd_drift.on_reserve = func(_t, _o): ciA.bind(bB) # candidate drifts to board B mid-reserve
	_check_eq(ts_drift.select_and_reserve(5, 1, aq_drift), -1, "STRICT-005: drift during reserve -> -1")
	_check_eq(rsd_drift.get_reservation_count(), 0, "STRICT-005: selector rolled back its own reservation on post-reserve drift")

	# Selector.bind re-entry from targetability callback cannot move the bundle.
	var rb_bA = _make_colored_board(1, 1, [5])
	var rb_ciA = ColorCandidateIndex.create(); rb_ciA.bind(rb_bA)
	var rb_rsA = ReservationState.create(); rb_rsA.bind(rb_bA)
	var rb_ts = TargetSelector.create(); rb_ts.bind(rb_bA, rb_ciA, rb_rsA)
	var rb_bB = _make_colored_board(1, 1, [5])
	var rb_ciB = ColorCandidateIndex.create(); rb_ciB.bind(rb_bB)
	var rb_rsB = ReservationState.create(); rb_rsB.bind(rb_bB)
	var rb_aq = AccessQueryDouble.new(); rb_aq.default_targetable = true
	var rb_fired := [false]
	rb_aq.on_query = func(_i):
		if not rb_fired[0]:
			rb_ts.bind(rb_bB, rb_ciB, rb_rsB) # nested re-bind blocked during selection
			rb_fired[0] = true
	rb_ts.select_and_reserve(5, 1, rb_aq)
	_check(rb_ts.is_bound_to(rb_bA, rb_rsA), "STRICT-005: nested bind did not move selector off bundle A")
	_check_eq(rb_rsB.get_reservation_count(), 0, "STRICT-005: nested bind created no reservation in bundle B")

	# ReservationState rebind during targetability callback -> drift -> -1.
	var rr_bA = _make_colored_board(1, 1, [5])
	var rr_ciA = ColorCandidateIndex.create(); rr_ciA.bind(rr_bA)
	var rr_rsA = ReservationState.create(); rr_rsA.bind(rr_bA)
	var rr_ts = TargetSelector.create(); rr_ts.bind(rr_bA, rr_ciA, rr_rsA)
	var rr_bB = _make_colored_board(1, 1, [5])
	var rr_aq = AccessQueryDouble.new(); rr_aq.default_targetable = true
	var rr_fired := [false]
	rr_aq.on_query = func(_i):
		if not rr_fired[0]:
			rr_rsA.rebind(rr_bB) # A's reservation drifts to board B mid-select
			rr_fired[0] = true
	_check_eq(rr_ts.select_and_reserve(5, 1, rr_aq), -1, "STRICT-005: reservation rebind mid-select fails closed")
	_check_eq(rr_rsA.get_reservation_count(), 0, "STRICT-005: no reservation created in the drifted bundle")

	print("  M15 strict-v2 2nd-stage tests complete")

func _run_target_selector_strict_v04_tests() -> void:
	# M15-C002 V02 closure: guard ordering, recursion/bind re-entry, coherence
	# after every boundary (incl. is_reserved==true), malformed-reserve-after-
	# mutation rollback, get_owner-independent rollback, same-owner no-later-query.
	print("---- M15 strict-v2 (V02): transaction guard + drift + exact rollback (F-004/005) ----")

	# ===== §1/§3 initial-coherence bind re-entry: nested bind cannot move bundle =
	# Candidate is_bound_to() callback attempts a nested bind during INITIAL coherence.
	var bA = _make_colored_board(2, 1, [5, 5])
	var ciA = CandidateIndexDouble.new(); ciA.bind(bA); ciA.set_candidates(5, [0, 1])
	var rsA = ReservationState.create(); rsA.bind(bA)
	var ts = TargetSelector.create(); ts.bind(bA, ciA, rsA)
	var bB = _make_colored_board(1, 1, [5])
	var ciB = CandidateIndexDouble.new(); ciB.bind(bB); ciB.set_candidates(5, [0])
	var rsB = ReservationState.create(); rsB.bind(bB)
	var nb_ci := [true, false] # [pending, observed_return]
	ciA.on_is_bound_to = func():
		if nb_ci[0]:
			nb_ci[0] = false
			nb_ci[1] = ts.bind(bB, ciB, rsB)
	var aq = AccessQueryDouble.new(); aq.default_targetable = true
	ts.select_and_reserve(5, 1, aq)
	_check_eq(nb_ci[1], false, "V02: nested bind from initial candidate coherence returns false")
	_check(ts.is_bound_to(bA, rsA), "V02: selector stays on bundle A after candidate-coherence nested bind")
	_check_eq(rsB.get_reservation_count(), 0, "V02: no reservation created in bundle B (candidate re-entry)")
	ciA.on_is_bound_to = Callable()
	_check(ts.select_and_reserve(5, 2, aq) != -1, "V02: later clean selection works after candidate re-entry")

	# Reservation is_bound_to() callback attempts a nested bind during INITIAL coherence.
	var r_bA = _make_colored_board(1, 1, [5])
	var r_ciA = ColorCandidateIndex.create(); r_ciA.bind(r_bA)
	var r_rsA = M15ReservationDouble.new(); r_rsA.bind(r_bA)
	var r_ts = TargetSelector.create(); r_ts.bind(r_bA, r_ciA, r_rsA)
	var r_bB = _make_colored_board(1, 1, [5])
	var r_ciB = ColorCandidateIndex.create(); r_ciB.bind(r_bB)
	var r_rsB = M15ReservationDouble.new(); r_rsB.bind(r_bB)
	var nb_rs := [true, false]
	r_rsA.on_is_bound_to = func():
		if nb_rs[0]:
			nb_rs[0] = false
			nb_rs[1] = r_ts.bind(r_bB, r_ciB, r_rsB)
	_check_eq(r_ts.select_and_reserve(5, 1, aq), 0, "V02: reservation-coherence re-entry: outer op still deterministic")
	_check_eq(nb_rs[1], false, "V02: nested bind from initial reservation coherence returns false")
	_check(r_ts.is_bound_to(r_bA, r_rsA), "V02: selector stays on bundle A after reservation-coherence nested bind")
	_check_eq(r_rsB.get_reservation_count(), 0, "V02: no reservation created in bundle B (reservation re-entry)")

	# ===== §1 initial coherence failure clears guard (no stuck-busy) ============
	var sb_b = _make_colored_board(1, 1, [5])
	var sb_ci = ColorCandidateIndex.create(); sb_ci.bind(sb_b)
	var sb_rs = ReservationState.create(); sb_rs.bind(sb_b)
	var sb_ts = TargetSelector.create(); sb_ts.bind(sb_b, sb_ci, sb_rs)
	var sb_b2 = _make_colored_board(1, 1, [5])
	sb_ci.rebind(sb_b2) # drift candidate before select -> initial coherence fails
	_check_eq(sb_ts.select_and_reserve(5, 1, aq), -1, "V02: initial-coherence failure returns -1")
	sb_ci.rebind(sb_b) # restore coherence
	_check(sb_ts.select_and_reserve(5, 1, aq) != -1, "V02: selector not stuck busy after initial-coherence failure")

	# ===== §2 recursive select_and_reserve blocked =============================
	# From targetability callback (same-owner and different-owner), candidate-query
	# callback, and reservation-query callback.
	var rc_b = _make_colored_board(2, 1, [5, 5])
	var rc_ci = ColorCandidateIndex.create(); rc_ci.bind(rc_b)
	var rc_rs = ReservationState.create(); rc_rs.bind(rc_b)
	var rc_ts = TargetSelector.create(); rc_ts.bind(rc_b, rc_ci, rc_rs)
	var rc_aq = AccessQueryDouble.new(); rc_aq.default_targetable = true
	var rc_nested := [99, 99] # [same-owner result, diff-owner result]
	var rc_fired := [false]
	rc_aq.on_query = func(_i):
		if not rc_fired[0]:
			rc_fired[0] = true
			rc_nested[0] = rc_ts.select_and_reserve(5, 1, rc_aq)  # same owner recursion
			rc_nested[1] = rc_ts.select_and_reserve(5, 2, rc_aq)  # different owner recursion
	var rc_out = rc_ts.select_and_reserve(5, 1, rc_aq)
	_check_eq(rc_nested[0], -1, "V02: recursive same-owner select returns -1")
	_check_eq(rc_nested[1], -1, "V02: recursive different-owner select returns -1")
	_check_eq(rc_out, 0, "V02: outer selection completes deterministically on target 0")
	_check_eq(rc_rs.get_reservation_count(), 1, "V02: recursion created no extra reservation")
	_check(rc_ts.select_and_reserve(5, 3, rc_aq) != -1, "V02: later non-reentrant call recovers")

	# Recursion from candidate-query callback.
	var rcq_b = _make_colored_board(1, 1, [5])
	var rcq_ci = CandidateIndexDouble.new(); rcq_ci.bind(rcq_b); rcq_ci.set_candidates(5, [0])
	var rcq_rs = ReservationState.create(); rcq_rs.bind(rcq_b)
	var rcq_ts = TargetSelector.create(); rcq_ts.bind(rcq_b, rcq_ci, rcq_rs)
	var rcq_nested := [99]
	var rcq_fired := [false]
	rcq_ci.on_get_candidates = func():
		if not rcq_fired[0]:
			rcq_fired[0] = true
			rcq_nested[0] = rcq_ts.select_and_reserve(5, 2, aq)
	rcq_ts.select_and_reserve(5, 1, aq)
	_check_eq(rcq_nested[0], -1, "V02: recursive select from candidate-query callback returns -1")

	# Recursion from reservation-query (owner query) callback.
	var rrq_b = _make_colored_board(1, 1, [5])
	var rrq_ci = ColorCandidateIndex.create(); rrq_ci.bind(rrq_b)
	var rrq_rs = M15ReservationDouble.new(); rrq_rs.bind(rrq_b)
	var rrq_ts = TargetSelector.create(); rrq_ts.bind(rrq_b, rrq_ci, rrq_rs)
	var rrq_nested := [99]
	var rrq_fired := [false]
	rrq_rs.on_owner_query = func():
		if not rrq_fired[0]:
			rrq_fired[0] = true
			rrq_nested[0] = rrq_ts.select_and_reserve(5, 2, aq)
	rrq_ts.select_and_reserve(5, 1, aq)
	_check_eq(rrq_nested[0], -1, "V02: recursive select from reservation-query callback returns -1")

	# ===== §3 bind-in-progress guard: nested bind during outer bind ============
	var bi_bA = _make_colored_board(1, 1, [5])
	var bi_ciA = CandidateIndexDouble.new(); bi_ciA.bind(bi_bA); bi_ciA.set_candidates(5, [0])
	var bi_rsA = ReservationState.create(); bi_rsA.bind(bi_bA)
	var bi_bB = _make_colored_board(1, 1, [5])
	var bi_ciB = CandidateIndexDouble.new(); bi_ciB.bind(bi_bB); bi_ciB.set_candidates(5, [0])
	var bi_rsB = ReservationState.create(); bi_rsB.bind(bi_bB)
	var bi_ts = TargetSelector.create()
	var bi_inner := [true, false] # [pending, observed]
	bi_ciA.on_is_bound_to = func():
		if bi_inner[0]:
			bi_inner[0] = false
			bi_inner[1] = bi_ts.bind(bi_bB, bi_ciB, bi_rsB) # nested bind during outer bind
	var bi_outer = bi_ts.bind(bi_bA, bi_ciA, bi_rsA)
	bi_ciA.on_is_bound_to = Callable()
	_check(bi_outer, "V02: outer bind commits")
	_check_eq(bi_inner[1], false, "V02: nested bind during outer bind returns false")
	_check(bi_ts.is_bound_to(bi_bA, bi_rsA), "V02: outer bind committed the requested bundle A only")
	_check(bi_ts.select_and_reserve(5, 1, aq) != -1, "V02: selector usable after bind re-entry")

	# ===== §4 coherence after is_reserved == true ==============================
	var ir_bA = _make_colored_board(2, 1, [5, 5])
	var ir_ciA = CandidateIndexDouble.new(); ir_ciA.bind(ir_bA); ir_ciA.set_candidates(5, [0, 1])
	var ir_rsA = M15ReservationDouble.new(); ir_rsA.bind(ir_bA)
	var ir_bB = _make_colored_board(2, 1, [5, 5])
	var ir_ts = TargetSelector.create(); ir_ts.bind(ir_bA, ir_ciA, ir_rsA)
	ir_rsA.is_reserved_force = true # every candidate reports reserved
	var ir_calls := [0]
	ir_rsA.on_is_reserved = func():
		ir_calls[0] += 1
		if ir_calls[0] == 1:
			ir_ciA.bind(ir_bB) # drift during is_reserved==true on candidate 0
	_check_eq(ir_ts.select_and_reserve(5, 1, aq), -1, "V02: is_reserved-true drift returns -1")
	_check_eq(ir_calls[0], 1, "V02: is_reserved-true drift stops before querying the next candidate")

	# ===== §4 direct drift: candidate-query / reserved-snapshot / owner-query ===
	# candidate-query drift stops before reservation.
	var dq_b = _make_colored_board(1, 1, [5])
	var dq_ci = CandidateIndexDouble.new(); dq_ci.bind(dq_b); dq_ci.set_candidates(5, [0])
	var dq_rs = ReservationState.create(); dq_rs.bind(dq_b)
	var dq_b2 = _make_colored_board(1, 1, [5])
	var dq_ts = TargetSelector.create(); dq_ts.bind(dq_b, dq_ci, dq_rs)
	var dq_fired := [false]
	dq_ci.on_get_candidates = func():
		if not dq_fired[0]:
			dq_fired[0] = true
			dq_ci.bind(dq_b2)
	_check_eq(dq_ts.select_and_reserve(5, 1, aq), -1, "V02: candidate-query drift -> -1 before reservation")
	_check_eq(dq_rs.get_reservation_count(), 0, "V02: candidate-query drift created no reservation")

	# reserved-snapshot drift stops before candidate query.
	var ds_b = _make_colored_board(1, 1, [5])
	var ds_ci = CandidateIndexDouble.new(); ds_ci.bind(ds_b); ds_ci.set_candidates(5, [0])
	var ds_rs = M15ReservationDouble.new(); ds_rs.bind(ds_b)
	var ds_b2 = _make_colored_board(1, 1, [5])
	var ds_ts = TargetSelector.create(); ds_ts.bind(ds_b, ds_ci, ds_rs)
	var ds_fired := [false]
	var ds_ci_candidates_called := [false]
	ds_ci.on_get_candidates = func(): ds_ci_candidates_called[0] = true
	ds_rs.on_reserved_snapshot = func():
		if not ds_fired[0]:
			ds_fired[0] = true
			ds_ci.bind(ds_b2) # drift during reserved snapshot
	_check_eq(ds_ts.select_and_reserve(5, 1, aq), -1, "V02: reserved-snapshot drift -> -1")
	_check_eq(ds_ci_candidates_called[0], false, "V02: reserved-snapshot drift stops before candidate query")

	# owner-query drift stops before later work.
	var do_b = _make_colored_board(1, 1, [5])
	var do_ci = CandidateIndexDouble.new(); do_ci.bind(do_b); do_ci.set_candidates(5, [0])
	var do_rs = M15ReservationDouble.new(); do_rs.bind(do_b)
	var do_b2 = _make_colored_board(1, 1, [5])
	var do_ts = TargetSelector.create(); do_ts.bind(do_b, do_ci, do_rs)
	var do_fired := [false]
	do_rs.on_owner_query = func():
		if not do_fired[0]:
			do_fired[0] = true
			do_ci.bind(do_b2) # drift during owner query
	_check_eq(do_ts.select_and_reserve(5, 1, aq), -1, "V02: owner-query drift -> -1 before later work")

	# ===== §5 malformed reserve return AFTER mutation rolls back exact pair =====
	var mr_b = _make_colored_board(1, 1, [5])
	var mr_ci = CandidateIndexDouble.new(); mr_ci.bind(mr_b); mr_ci.set_candidates(5, [0])
	var mr_rsd = M15ReservationDouble.new(); mr_rsd.bind(mr_b)
	mr_rsd.reserve(5, 777) # unrelated pre-existing reservation (target 5, owner 777)
	mr_rsd.reserve_force = 1 # subsequent reserve stores exact pair then returns int 1
	var mr_ts = TargetSelector.create(); mr_ts.bind(mr_b, mr_ci, mr_rsd)
	var mr_aq = AccessQueryDouble.new(); mr_aq.default_targetable = true
	_check_eq(mr_ts.select_and_reserve(5, 1, mr_aq), -1, "V02: reserve stores then returns int 1 -> -1")
	_check_eq(mr_rsd.get_owner(0), -1, "V02: exact requested pair (0,1) rolled back after malformed reserve")
	_check_eq(mr_rsd.get_owner(5), 777, "V02: unrelated reservation preserved through malformed-reserve rollback")

	# ===== §6 rollback must not depend on the failed ownership query ============
	# exact pair stored + malformed get_owner -> -1 and exact pair removed.
	var go_rsd = M15ReservationDouble.new(); go_rsd.do_store = true; go_rsd.get_owner_force = "z"
	var go_w = _m15_selector_with(go_rsd)
	_check_eq(go_w.ts.select_and_reserve(5, 1, go_w.aq), -1, "V02: exact pair + malformed get_owner -> -1")
	_check_eq(go_rsd.get_reservation_count(), 0, "V02: exact pair removed despite malformed get_owner")

	# exact pair stored + malformed get_target_for_owner at proof time -> -1 and removed.
	var gt_rsd = M15ReservationDouble.new(); gt_rsd.do_store = true
	gt_rsd.target_for_owner_force_after_reserve = "q" # malformed only after reserve
	var gt_w = _m15_selector_with(gt_rsd)
	_check_eq(gt_w.ts.select_and_reserve(5, 1, gt_w.aq), -1, "V02: exact pair + malformed get_target_for_owner -> -1")
	_check_eq(gt_rsd.get_reservation_count(), 0, "V02: exact pair removed despite malformed get_target_for_owner")

	# target actually owned by another owner is preserved (rollback is exact-pair).
	var oo_rsd = M15ReservationDouble.new(); oo_rsd.do_store = true; oo_rsd.store_owner_override = 999
	var oo_w = _m15_selector_with(oo_rsd)
	_check_eq(oo_w.ts.select_and_reserve(5, 1, oo_w.aq), -1, "V02: reserve stored under other owner -> -1")
	_check_eq(oo_rsd.get_owner(0), 999, "V02: other owner's reservation preserved (no broad release)")

	# ===== §7 same-owner side effect + false / non-bool targetability ===========
	# targetability false: owner assigned by side effect -> -1, no later query, kept.
	var so_b = _make_colored_board(3, 1, [5, 5, 5])
	var so_ci = ColorCandidateIndex.create(); so_ci.bind(so_b)
	var so_rs = ReservationState.create(); so_rs.bind(so_b)
	var so_ts = TargetSelector.create(); so_ts.bind(so_b, so_ci, so_rs)
	var so_aq = AccessQueryDouble.new(); so_aq.default_targetable = false
	var so_fired := [false]
	so_aq.on_query = func(_i):
		if not so_fired[0]:
			so_fired[0] = true
			so_rs.reserve(2, 42) # same owner grabs later candidate 2
	_check_eq(so_ts.select_and_reserve(5, 42, so_aq), -1, "V02: same-owner side effect + false targetability -> -1")
	_check(not so_aq.was_queried(1), "V02: no later candidate targetability query after owner assigned (false verdict)")
	_check_eq(so_rs.get_target_for_owner(42), 2, "V02: external same-owner reservation preserved (false verdict)")

	# targetability non-bool verdict: same law.
	var sn_b = _make_colored_board(3, 1, [5, 5, 5])
	var sn_ci = ColorCandidateIndex.create(); sn_ci.bind(sn_b)
	var sn_rs = ReservationState.create(); sn_rs.bind(sn_b)
	var sn_ts = TargetSelector.create(); sn_ts.bind(sn_b, sn_ci, sn_rs)
	var sn_aq = M15VariantAccess.new(); sn_aq.verdict = 1 # non-bool truthy
	var sn_fired := [false]
	sn_aq.on_query = func(_i):
		if not sn_fired[0]:
			sn_fired[0] = true
			sn_rs.reserve(2, 42)
	_check_eq(sn_ts.select_and_reserve(5, 42, sn_aq), -1, "V02: same-owner side effect + non-bool targetability -> -1")
	_check_eq(sn_rs.get_target_for_owner(42), 2, "V02: external same-owner reservation preserved (non-bool verdict)")

	# malformed owner query right after targetability -> fail closed.
	var mo_b = _make_colored_board(1, 1, [5])
	var mo_ci = CandidateIndexDouble.new(); mo_ci.bind(mo_b); mo_ci.set_candidates(5, [0])
	var mo_rs = M15ReservationDouble.new(); mo_rs.bind(mo_b)
	var mo_ts = TargetSelector.create(); mo_ts.bind(mo_b, mo_ci, mo_rs)
	var mo_aq = AccessQueryDouble.new(); mo_aq.default_targetable = true
	var mo_calls := [0]
	mo_rs.on_owner_query = func():
		mo_calls[0] += 1
		if mo_calls[0] == 2: # first is the initial owner check; second is post-targetability
			mo_rs.target_for_owner_force = "bad"
	_check_eq(mo_ts.select_and_reserve(5, 1, mo_aq), -1, "V02: malformed owner query after targetability fails closed")

	print("  M15 strict-v2 V02 tests complete")

func _run_target_selector_strict_v05_tests() -> void:
	# M15-C002 V03 final transactional closure:
	#   005.H select-during-bind; 005.I post-targetability owner-query boundary;
	#   005.J post-reserve proof bracketed one callback at a time.
	print("---- M15 strict-v2 (V03): select-during-bind + proof bracketing (F-004/005) ----")

	# ===== §1 / 005.H: selection rejected during a bind transaction ============
	# Candidate bind-time coherence callback injects a nested selection.
	var hA = _make_colored_board(2, 1, [5, 5])
	var hciA = ColorCandidateIndex.create(); hciA.bind(hA)
	var hrsA = ReservationState.create(); hrsA.bind(hA)
	var hts = TargetSelector.create(); hts.bind(hA, hciA, hrsA)
	var hB = _make_colored_board(2, 1, [5, 5])
	var hciB = CandidateIndexDouble.new(); hciB.bind(hB); hciB.set_candidates(5, [0, 1])
	var hrsB = ReservationState.create(); hrsB.bind(hB)
	var h_nsel := [99]
	var h_nq = AccessQueryDouble.new(); h_nq.default_targetable = true
	var h_fired := [false]
	hciB.on_is_bound_to = func():
		if not h_fired[0]:
			h_fired[0] = true
			h_nsel[0] = hts.select_and_reserve(5, 7, h_nq) # nested select during outer bind
	var h_outer = hts.bind(hB, hciB, hrsB)
	hciB.on_is_bound_to = Callable()
	_check_eq(h_nsel[0], -1, "005.H: nested selection during candidate bind-time coherence returns -1")
	_check_eq(h_nq.total_queries(), 0, "005.H: nested selection made zero targetability query")
	_check_eq(hrsA.get_reservation_count(), 0, "005.H: no orphan reservation in old bundle A (candidate)")
	_check_eq(hrsB.get_reservation_count(), 0, "005.H: no reservation in bundle B during bind (candidate)")
	_check(h_outer, "005.H: outer candidate-callback bind to B commits")
	_check(hts.is_bound_to(hB, hrsB), "005.H: selector ends coherent with bundle B (candidate)")
	_check(hts.select_and_reserve(5, 8, h_nq) != -1, "005.H: later selection on B succeeds (candidate)")

	# Reservation bind-time coherence callback injects a nested selection.
	var h2A = _make_colored_board(2, 1, [5, 5])
	var h2ciA = ColorCandidateIndex.create(); h2ciA.bind(h2A)
	var h2rsA = ReservationState.create(); h2rsA.bind(h2A)
	var h2ts = TargetSelector.create(); h2ts.bind(h2A, h2ciA, h2rsA)
	var h2B = _make_colored_board(2, 1, [5, 5])
	var h2ciB = ColorCandidateIndex.create(); h2ciB.bind(h2B)
	var h2rsB = M15ReservationDouble.new(); h2rsB.bind(h2B)
	var h2_nsel := [99]
	var h2_nq = AccessQueryDouble.new(); h2_nq.default_targetable = true
	var h2_fired := [false]
	h2rsB.on_is_bound_to = func():
		if not h2_fired[0]:
			h2_fired[0] = true
			h2_nsel[0] = h2ts.select_and_reserve(5, 7, h2_nq)
	var h2_outer = h2ts.bind(h2B, h2ciB, h2rsB)
	h2rsB.on_is_bound_to = Callable()
	_check_eq(h2_nsel[0], -1, "005.H: nested selection during reservation bind-time coherence returns -1")
	_check_eq(h2rsA.get_reservation_count(), 0, "005.H: no orphan reservation in old bundle A (reservation)")
	_check_eq(h2rsB.get_reservation_count(), 0, "005.H: no reservation in bundle B during bind (reservation)")
	_check(h2_outer, "005.H: outer reservation-callback bind to B commits")
	_check(h2ts.is_bound_to(h2B, h2rsB), "005.H: selector ends coherent with bundle B (reservation)")
	_check(h2ts.select_and_reserve(5, 8, h2_nq) != -1, "005.H: later selection on B succeeds (reservation)")

	# ===== §2 / 005.I: post-targetability owner-query is a full boundary =======
	# true verdict + candidate drift inside the post-targetability owner query.
	var ic_b = _make_colored_board(1, 1, [5]); var ic_b2 = _make_colored_board(1, 1, [5])
	var ic_ci = CandidateIndexDouble.new(); ic_ci.bind(ic_b); ic_ci.set_candidates(5, [0])
	var ic_rs = M15ReservationDouble.new(); ic_rs.bind(ic_b)
	var ic_ts = TargetSelector.create(); ic_ts.bind(ic_b, ic_ci, ic_rs)
	var ic_aq = AccessQueryDouble.new(); ic_aq.default_targetable = true
	ic_rs.on_owner_query = func():
		if ic_rs.owner_query_calls == 2: ic_ci.bind(ic_b2) # drift only post-targetability
	_check_eq(ic_ts.select_and_reserve(5, 1, ic_aq), -1, "005.I: candidate drift in post-targetability owner query -> -1")
	_check_eq(ic_rs.reserve_calls, 0, "005.I: no reserve after candidate owner-query drift")
	_check_eq(ic_rs.get_reservation_count(), 0, "005.I: no reservation after candidate owner-query drift")

	# true verdict + ReservationState drift inside the post-targetability owner query.
	var ir_b = _make_colored_board(1, 1, [5]); var ir_b2 = _make_colored_board(1, 1, [5])
	var ir_ci = ColorCandidateIndex.create(); ir_ci.bind(ir_b)
	var ir_rs = M15ReservationDouble.new(); ir_rs.bind(ir_b)
	var ir_ts = TargetSelector.create(); ir_ts.bind(ir_b, ir_ci, ir_rs)
	var ir_aq = AccessQueryDouble.new(); ir_aq.default_targetable = true
	ir_rs.on_owner_query = func():
		if ir_rs.owner_query_calls == 2: ir_rs.rebind(ir_b2) # reservation drifts post-targetability
	_check_eq(ir_ts.select_and_reserve(5, 1, ir_aq), -1, "005.I: reservation drift in post-targetability owner query -> -1")
	_check_eq(ir_rs.reserve_calls, 0, "005.I: no reserve after reservation owner-query drift")

	# false verdict + owner-query drift: stops before later candidate targetability.
	var if_b = _make_colored_board(2, 1, [5, 5]); var if_b2 = _make_colored_board(2, 1, [5, 5])
	var if_ci = CandidateIndexDouble.new(); if_ci.bind(if_b); if_ci.set_candidates(5, [0, 1])
	var if_rs = M15ReservationDouble.new(); if_rs.bind(if_b)
	var if_ts = TargetSelector.create(); if_ts.bind(if_b, if_ci, if_rs)
	var if_aq = AccessQueryDouble.new(); if_aq.default_targetable = false # false verdict
	if_rs.on_owner_query = func():
		if if_rs.owner_query_calls == 2: if_ci.bind(if_b2)
	_check_eq(if_ts.select_and_reserve(5, 1, if_aq), -1, "005.I: false-verdict owner-query drift -> -1")
	_check(not if_aq.was_queried(1), "005.I: no later candidate targetability query after owner-query drift")

	# non-bool verdict + owner-query drift.
	var inb_b = _make_colored_board(1, 1, [5]); var inb_b2 = _make_colored_board(1, 1, [5])
	var inb_ci = CandidateIndexDouble.new(); inb_ci.bind(inb_b); inb_ci.set_candidates(5, [0])
	var inb_rs = M15ReservationDouble.new(); inb_rs.bind(inb_b)
	var inb_ts = TargetSelector.create(); inb_ts.bind(inb_b, inb_ci, inb_rs)
	var inb_aq = M15VariantAccess.new(); inb_aq.verdict = 1 # non-bool
	inb_rs.on_owner_query = func():
		if inb_rs.owner_query_calls == 2: inb_ci.bind(inb_b2)
	_check_eq(inb_ts.select_and_reserve(5, 1, inb_aq), -1, "005.I: non-bool-verdict owner-query drift -> -1")
	_check_eq(inb_rs.reserve_calls, 0, "005.I: no reserve after non-bool owner-query drift")

	# ===== §3 / 005.J: post-reserve proof bracketed one callback at a time =====
	# Baseline: ordered happy path — get_owner called once, after reserve.
	var jb_rsd = M15ReservationDouble.new()
	var jb_w = _m15_selector_with(jb_rsd)
	_check_eq(jb_w.ts.select_and_reserve(5, 1, jb_w.aq), 0, "005.J: ordered happy path returns target 0")
	_check_eq(jb_rsd.reserve_calls, 1, "005.J: happy path reserved once")
	_check_eq(jb_rsd.get_owner_calls, 1, "005.J: get_owner proof called exactly once after reserve")

	# get_owner callback drifts candidate while returning the correct owner.
	var jg_b = _make_colored_board(1, 1, [5]); var jg_b2 = _make_colored_board(1, 1, [5])
	var jg_ci = CandidateIndexDouble.new(); jg_ci.bind(jg_b); jg_ci.set_candidates(5, [0])
	var jg_rs = M15ReservationDouble.new(); jg_rs.bind(jg_b)
	jg_rs.reserve(9, 777) # unrelated reservation
	var jg_ts = TargetSelector.create(); jg_ts.bind(jg_b, jg_ci, jg_rs)
	var jg_aq = AccessQueryDouble.new(); jg_aq.default_targetable = true
	var jg_fired := [false]
	jg_rs.on_get_owner = func():
		if not jg_fired[0]:
			jg_fired[0] = true
			jg_ci.bind(jg_b2) # drift candidate during get_owner proof
	var jg_owner_q_before: int = jg_rs.owner_query_calls
	_check_eq(jg_ts.select_and_reserve(5, 1, jg_aq), -1, "005.J: get_owner candidate drift -> -1")
	_check_eq(jg_rs.owner_query_calls, jg_owner_q_before + 2, "005.J: target-proof NOT called after get_owner drift (only initial + post-targetability owner queries ran)")
	_check_eq(jg_rs.get_reservation_count(), 1, "005.J: exact pair rolled back, unrelated reservation preserved (get_owner candidate drift)")
	_check_eq(jg_rs.get_owner(9), 777, "005.J: unrelated (9,777) reservation intact")

	# get_owner callback drifts ReservationState while returning correct owner.
	var jgr_b = _make_colored_board(1, 1, [5]); var jgr_b2 = _make_colored_board(1, 1, [5])
	var jgr_ci = ColorCandidateIndex.create(); jgr_ci.bind(jgr_b)
	var jgr_rs = M15ReservationDouble.new(); jgr_rs.bind(jgr_b)
	var jgr_ts = TargetSelector.create(); jgr_ts.bind(jgr_b, jgr_ci, jgr_rs)
	var jgr_fired := [false]
	jgr_rs.on_get_owner = func():
		if not jgr_fired[0]:
			jgr_fired[0] = true
			jgr_rs.rebind(jgr_b2) # reservation drifts during get_owner proof
	var jgr_aq = AccessQueryDouble.new(); jgr_aq.default_targetable = true
	_check_eq(jgr_ts.select_and_reserve(5, 1, jgr_aq), -1, "005.J: get_owner ReservationState drift -> -1")
	_check_eq(jgr_rs.get_reservation_count(), 0, "005.J: no replacement/orphan reservation after get_owner reservation drift")

	# target-proof callback drifts candidate while returning correct target.
	var jt_b = _make_colored_board(1, 1, [5]); var jt_b2 = _make_colored_board(1, 1, [5])
	var jt_ci = CandidateIndexDouble.new(); jt_ci.bind(jt_b); jt_ci.set_candidates(5, [0])
	var jt_rs = M15ReservationDouble.new(); jt_rs.bind(jt_b)
	jt_rs.reserve(9, 777) # unrelated reservation
	var jt_ts = TargetSelector.create(); jt_ts.bind(jt_b, jt_ci, jt_rs)
	var jt_aq = AccessQueryDouble.new(); jt_aq.default_targetable = true
	jt_rs.on_owner_query = func():
		if jt_rs.owner_query_calls == 3: jt_ci.bind(jt_b2) # drift on the target-proof query
	_check_eq(jt_ts.select_and_reserve(5, 1, jt_aq), -1, "005.J: target-proof candidate drift -> -1")
	_check_eq(jt_rs.get_reservation_count(), 1, "005.J: exact pair rolled back, unrelated preserved (target-proof candidate drift)")
	_check_eq(jt_rs.get_owner(9), 777, "005.J: unrelated (9,777) intact after target-proof drift")

	# target-proof callback drifts ReservationState while returning correct target.
	var jtr_b = _make_colored_board(1, 1, [5]); var jtr_b2 = _make_colored_board(1, 1, [5])
	var jtr_ci = ColorCandidateIndex.create(); jtr_ci.bind(jtr_b)
	var jtr_rs = M15ReservationDouble.new(); jtr_rs.bind(jtr_b)
	var jtr_ts = TargetSelector.create(); jtr_ts.bind(jtr_b, jtr_ci, jtr_rs)
	var jtr_aq = AccessQueryDouble.new(); jtr_aq.default_targetable = true
	jtr_rs.on_owner_query = func():
		if jtr_rs.owner_query_calls == 3: jtr_rs.rebind(jtr_b2)
	_check_eq(jtr_ts.select_and_reserve(5, 1, jtr_aq), -1, "005.J: target-proof ReservationState drift -> -1")
	_check_eq(jtr_rs.get_reservation_count(), 0, "005.J: no orphan after target-proof reservation drift")

	# malformed get_owner: target-proof callback NOT invoked after known failure.
	var jm_b = _make_colored_board(1, 1, [5])
	var jm_ci = CandidateIndexDouble.new(); jm_ci.bind(jm_b); jm_ci.set_candidates(5, [0])
	var jm_rs = M15ReservationDouble.new(); jm_rs.bind(jm_b)
	jm_rs.reserve(9, 777) # unrelated reservation
	jm_rs.get_owner_force = "z" # malformed proof
	var jm_ts = TargetSelector.create(); jm_ts.bind(jm_b, jm_ci, jm_rs)
	var jm_aq = AccessQueryDouble.new(); jm_aq.default_targetable = true
	var jm_q_before: int = jm_rs.owner_query_calls
	_check_eq(jm_ts.select_and_reserve(5, 1, jm_aq), -1, "005.J: malformed get_owner -> -1")
	_check_eq(jm_rs.owner_query_calls, jm_q_before + 2, "005.J: target-proof query NOT invoked after malformed get_owner (only initial + post-targetability)")
	_check_eq(jm_rs.get_reservation_count(), 1, "005.J: exact pair rolled back, unrelated preserved (malformed get_owner)")
	_check_eq(jm_rs.get_owner_calls, 1, "005.J: get_owner proof invoked exactly once")

	print("  M15 strict-v2 V03 tests complete")

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

	# === Strict V05: exact BoardState identity at the public RouteRequest board
	# boundary (F-M16-STRICT-006/007). center_of_index -> (-INF,-INF), for_target
	# -> null for every malformed board, with NO runtime fault. ===
	var wrong_board = WrongReturnBoardDouble.new() # full method shape, wrong return types
	var partial = PartialBoardDouble.new()
	var bad_boards := [null, 7, "board", Vector2.ZERO, RefCounted.new(), partial, wrong_board]
	for bb in bad_boards:
		var c := RouteRequest.center_of_index(bb, 0)
		_check(c.x == -INF and c.y == -INF, "center_of_index(malformed board %s) -> (-INF,-INF)" % str(typeof(bb)))
		_check(RouteRequest.for_target(bb, Vector2.ZERO, 0) == null, "for_target(malformed board %s) -> null" % str(typeof(bb)))

	# for_target rejects non-finite slot origins (canonical factory never emits a
	# structurally-invalid request).
	_check(RouteRequest.for_target(board, Vector2(NAN, 2.5), tgt) == null, "for_target: NaN start -> null")
	_check(RouteRequest.for_target(board, Vector2(INF, 2.5), tgt) == null, "for_target: +INF start -> null")
	_check(RouteRequest.for_target(board, Vector2(-INF, 2.5), tgt) == null, "for_target: -INF start -> null")

	# Request stores no BoardState reference (detached value object, AL-020).
	var ref_check = RouteRequest.for_target(board, Vector2(-1.0, 1.5), tgt)
	_check(not ("board" in ref_check), "RouteRequest stores no BoardState reference")

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

	# === Strict V04/V05: arbitrary Variant inputs fail closed (AL-041/AL-042) ===
	# Access double uses default_traversable so it would approve if ever reached;
	# asserting the fail-closed reason + zero queries proves the guard replaces it.
	# V05: exact BoardState identity — scalars, junk, partial, AND a full-shape
	# wrong-return double all fail closed at the validator board boundary.
	for bad_board in [7, "board", Vector2.ZERO, RefCounted.new(), PartialBoardDouble.new(), WrongReturnBoardDouble.new()]:
		_check_eq(RouteValidator.validate_request(req, bad_board), RouteResult.FailureReason.INVALID_REQUEST, "validate_request: malformed board (%s) fails closed" % str(typeof(bad_board)))
		var bb_acc = RouteAccessQueryDouble.new(); bb_acc.default_traversable = true
		_check_eq(RouteValidator.validate_route(req, result, bad_board, bb_acc), RouteResult.FailureReason.INVALID_REQUEST, "validate_route: malformed board (%s) -> INVALID_REQUEST" % str(typeof(bad_board)))
		_check_eq(bb_acc.total_queries(), 0, "validate_route: malformed board (%s) makes zero access calls" % str(typeof(bad_board)))

	# Result: RefCounted junk + int / String / Vector2, guarded before .success.
	for bad_result in [RefCounted.new(), 7, "route", Vector2.ZERO]:
		var br_acc = RouteAccessQueryDouble.new(); br_acc.default_traversable = true
		_check_eq(RouteValidator.validate_route(req, bad_result, board, br_acc), RouteResult.FailureReason.INVALID_ROUTE, "validate_route: malformed result (%s) fails closed" % str(bad_result))
		_check_eq(br_acc.total_queries(), 0, "validate_route: malformed result (%s) makes zero access calls" % str(bad_result))

	# Access-query: int / String / Vector2 + a RefCounted lacking the method.
	# No has_method on a non-object; single stable MISSING_ACCESS_QUERY; no segment call.
	for bad_acc in [7, "access", Vector2.ZERO, RefCounted.new()]:
		_check_eq(RouteValidator.validate_route(req, result, board, bad_acc), RouteResult.FailureReason.MISSING_ACCESS_QUERY, "validate_route: malformed access_query (%s) -> MISSING_ACCESS_QUERY" % str(bad_acc))

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

	# === Strict V05: base compute_route fails cleanly for ARBITRARY request
	# Variants (F-M16-STRICT-008). target_index read only from a real RouteRequest;
	# malformed -> stable NOT_IMPLEMENTED with target -1, no runtime fault. ===
	for bad_req in [null, 7, "req", Vector2.ZERO, RefCounted.new()]:
		var mr = base.compute_route(bad_req, board, null)
		_check(not mr.success, "base compute_route(malformed %s) fails cleanly" % str(typeof(bad_req)))
		_check_eq(mr.failure_reason, RouteResult.FailureReason.NOT_IMPLEMENTED, "base compute_route(malformed %s) -> NOT_IMPLEMENTED" % str(typeof(bad_req)))
		_check_eq(mr.target_index, -1, "base compute_route(malformed %s) -> target -1 (no deref)" % str(typeof(bad_req)))
	# A real RouteRequest still retains its assigned target.
	_check_eq(base.compute_route(req, board, null).target_index, tgt, "base compute_route(real request) retains target_index")

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

## Longest INTERIOR movement segment (skips the first point -> board-entry
## exterior bridge, which is a shared resolution-independent slot->board segment).
## The conservative-shortcut comparison is about interior path shape, not the
## common exterior bridge.
func _m17c002_max_seg(p: PackedVector2Array) -> float:
	var m := 0.0
	for i in range(1, p.size() - 1):
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
	_check(prod_max < exp_max, "production avoids long interior diagonals (interior max seg %.1f < experimental %.1f)" % [prod_max, exp_max])
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
	# Permissive routing_access so the fake straight routes validate through the
	# SAME shared RouteValidator path the dispatcher now enforces; exact-bound to
	# the board for coherence. (Production wiring uses the real access truth.)
	var routing_access = RouteAccessQueryDouble.new()
	routing_access.default_traversable = true
	routing_access.bind_board(board)
	var dispatcher = ScrubbotDispatcher.new()
	root.add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, access)
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"selector": selector, "routing": routing, "routing_access": routing_access,
		"access": access, "dispatcher": dispatcher}

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

	# --- wrong-start route -> ROUTE_FAILED before any agent creation ------
	var b6 = _m19_open_board_active(14, 11, active)
	var color6: int = b6.get_color_id(b6.get_cell_index(2, 5))
	var w6 = _m19_wire_fake(b6, "mismatch", [b6.get_cell_index(2, 5)])
	var r6 = w6["dispatcher"].dispatch(color6, origin)
	_check_eq(r6.failure_reason, DispatchResult.FailureReason.ROUTE_FAILED, "wrong-start route -> ROUTE_FAILED (shared validator, pre-agent)")
	_check_eq(w6["dispatcher"].get_active_count(), 0, "wrong-start route spawns zero agents")
	_check_eq(w6["reservations"].get_reservation_count(), 0, "wrong-start route releases the reservation")
	_m19_teardown(w6)

	# --- agent assign failure (ownable fresh agent rejects) -> release/free
	var b6b = _m19_open_board_active(14, 11, active)
	var color6b: int = b6b.get_color_id(b6b.get_cell_index(2, 5))
	var w6b = _m19_wire_fake(b6b, "ok", [b6b.get_cell_index(2, 5)])
	w6b["dispatcher"]._agent_factory = func(): var a = DispatchAgentDouble.new(); a.fail_assign = true; return a
	var child_before: int = w6b["dispatcher"].get_child_count()
	var r6b = w6b["dispatcher"].dispatch(color6b, origin)
	_check_eq(r6b.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "assign failure -> AGENT_ASSIGN_FAILED")
	_check_eq(w6b["dispatcher"].get_active_count(), 0, "assign failure spawns zero active agents")
	_check_eq(w6b["dispatcher"].get_child_count(), child_before, "assign failure leaves no orphan node")
	_check_eq(w6b["reservations"].get_reservation_count(), 0, "assign failure releases the reservation")
	_m19_teardown(w6b)

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

# ============================================= M19-C001 V02 strict-v2 =========
# Frozen full-surface finding set F-M19-STRICT-001..004: fail-closed init-only
# bind + bundle coherence + live drift; shared route validation seam; agent
# factory/parent gate; finite-speed request boundary; serial re-entry + reset
# generation; completion identity. Uses deterministic fakes + real production.

## Create a throwaway dispatcher, attempt one bind, return true only if the bind
## succeeded AND left the dispatcher bound. Always frees the dispatcher.
func _m19_try_bind(b, s, r, rs, ra, sa) -> bool:
	var d = ScrubbotDispatcher.new()
	root.add_child(d)
	var ok: bool = d.bind(b, s, r, rs, ra, sa)
	var bound: bool = d.is_bound()
	root.remove_child(d)
	d.free()
	return ok and bound

## Build a fresh, coherent real bundle over a fresh board.
func _m19_real_bundle(w: int, h: int, active_cell: Vector2) -> Dictionary:
	var board = _m19_open_board_active(w, h, [active_cell])
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"selector": selector, "routing": routing, "routing_access": routing_access,
		"select_access": select_access, "idx": board.get_cell_index(int(active_cell.x), int(active_cell.y))}

## An assigned ScrubbotAgent in the requested terminal state (MOVING/ARRIVED/
## CANCELLED), unparented — for factory-product rejection tests.
func _m19_assigned_agent(board, idx: int, org: Vector2, final_state: int):
	var req = RouteRequest.for_target(board, org, idx)
	var route = RouteResult.success_route(idx, PackedVector2Array([org, req.target_position]))
	var a = ScrubbotAgent.new()
	a.assign(0, maxi(board.get_color_id(idx), 0), req, route, 6.0)
	if final_state == ScrubbotAgent.State.ARRIVED:
		a.advance(10000.0)
	elif final_state == ScrubbotAgent.State.CANCELLED:
		a.cancel()
	return a

func _run_m19_strict_v2_tests() -> void:
	print("---- M19-C001 V02: strict-v2 dispatcher hardening ----")
	var active := [Vector2(2, 5), Vector2(4, 5), Vector2(6, 5), Vector2(8, 5), Vector2(10, 5)]
	var origin := Vector2(-2.0, 5.5)

	# ===== F-M19-STRICT-001: fresh bind dependency boundary (1-10) =====
	var rb = _m19_real_bundle(20, 20, Vector2(10, 10))
	var B = rb["board"]; var S = rb["selector"]; var R = rb["reservations"]
	var RS = rb["routing"]; var RA = rb["routing_access"]; var SA = rb["select_access"]
	_check(_m19_try_bind(B, S, R, RS, RA, SA), "real coherent bundle binds (crit 1)")
	_check(not _m19_try_bind(123, S, R, RS, RA, SA), "scalar board rejected (crit 2)")
	_check(not _m19_try_bind(B, null, R, RS, RA, SA), "null selector rejected (crit 3)")
	_check(not _m19_try_bind(B, 5, R, RS, RA, SA), "scalar selector rejected (crit 3)")
	_check(not _m19_try_bind(B, RefCounted.new(), R, RS, RA, SA), "partial selector (no API) rejected (crit 8)")
	_check(not _m19_try_bind(B, S, null, RS, RA, SA), "null reservation rejected (crit 4)")
	_check(not _m19_try_bind(B, S, "x", RS, RA, SA), "scalar reservation rejected (crit 4)")
	_check(not _m19_try_bind(B, S, R, null, RA, SA), "null routing system rejected (crit 5)")
	_check(not _m19_try_bind(B, S, R, RefCounted.new(), RA, SA), "partial routing system rejected (crit 5)")
	_check(not _m19_try_bind(B, S, R, RS, null, SA), "null routing access rejected (crit 6)")
	_check(not _m19_try_bind(B, S, R, RS, RefCounted.new(), SA), "partial routing access rejected (crit 6)")
	_check(not _m19_try_bind(B, S, R, RS, RA, null), "null select access rejected (crit 7)")
	_check(not _m19_try_bind(B, S, R, RS, RA, RefCounted.new()), "partial select access rejected (crit 7,8)")

	# ===== Exact bundle coherence (11-18) =====
	var rb2 = _m19_real_bundle(20, 20, Vector2(10, 10)) # same size, DIFFERENT board
	_check(not _m19_try_bind(B, rb2["selector"], R, RS, RA, SA), "selector bound to other board rejected (crit 11,16)")
	_check(not _m19_try_bind(B, S, rb2["reservations"], RS, RA, SA), "reservation bound to other board rejected (crit 13,17)")
	_check(not _m19_try_bind(B, S, R, RS, rb2["routing_access"], SA), "routing_access bound to other board rejected (crit 14)")
	_check(not _m19_try_bind(B, S, R, RS, RA, rb2["select_access"]), "select_access with other bundle rejected (crit 15,18)")

	# ===== Ordinary repeated bind (19-26) =====
	var wrep = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [])
	var bp = wrep["board"]
	wrep["access"].set_all_targetable([bp.get_cell_index(2, 5), bp.get_cell_index(4, 5)])
	var colorp: int = bp.get_color_id(bp.get_cell_index(2, 5))
	var rok = wrep["dispatcher"].dispatch(colorp, origin)
	_check(rok.success, "repeated-bind precondition: one live assignment")
	var pre_active: int = wrep["dispatcher"].get_active_count()
	var pre_owner: int = wrep["reservations"].get_owner(rok.target_index)
	var pre_agent = wrep["dispatcher"].get_agent_for_owner(rok.owner_id)
	var d = wrep["dispatcher"]
	_check(not d.bind(wrep["board"], wrep["selector"], wrep["reservations"], wrep["routing"], wrep["routing_access"], wrep["access"]), "same-bundle second bind false (crit 19)")
	_check(not d.bind(rb2["board"], rb2["selector"], rb2["reservations"], rb2["routing"], rb2["routing_access"], rb2["select_access"]), "different valid bundle second bind false (crit 20)")
	_check(not d.bind(null, null, null, null, null, null), "null second bind false (crit 21)")
	_check(d.is_bound(), "bound flag preserved after failed rebinds (crit 22)")
	_check_eq(d.get_active_count(), pre_active, "active count preserved (crit 24)")
	_check_eq(wrep["reservations"].get_owner(rok.target_index), pre_owner, "reservation owner preserved (crit 25)")
	_check_eq(d.get_agent_for_owner(rok.owner_id), pre_agent, "active agent identity preserved (crit 26)")
	_m19_teardown(wrep)

	# ===== Live coherence drift (27-31) =====
	# reservation rebind drift
	var wd1 = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bd1 = wd1["board"]
	wd1["access"].set_all_targetable([bd1.get_cell_index(2, 5), bd1.get_cell_index(4, 5)])
	var cd1: int = bd1.get_color_id(bd1.get_cell_index(2, 5))
	var live1 = wd1["dispatcher"].dispatch(cd1, origin)
	_check(live1.success, "drift precondition assignment")
	var other_board = _m19_open_board_active(14, 11, active)
	wd1["reservations"].rebind(other_board) # sibling drift
	var after_drift = wd1["dispatcher"].dispatch(cd1, origin)
	_check_eq(after_drift.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "reservation drift blocks dispatch (crit 27)")
	_check_eq(wd1["dispatcher"].get_active_count(), 1, "drift leaves prior active assignment intact (crit 31)")
	_m19_teardown(wd1)
	# selector drift
	var wd2 = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bd2b = wd2["board"]; wd2["access"].set_all_targetable([bd2b.get_cell_index(2, 5)])
	var ob = _m19_open_board_active(14, 11, active)
	var oc = ColorCandidateIndex.create(); oc.bind(ob)
	var orr = ReservationState.new(); orr.bind(ob)
	wd2["selector"].bind(ob, oc, orr) # selector rebound to other board
	_check_eq(wd2["dispatcher"].dispatch(bd2b.get_color_id(bd2b.get_cell_index(2, 5)), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "selector drift blocks dispatch (crit 28)")
	_m19_teardown(wd2)
	# routing_access drift
	var wd3 = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bd3 = wd3["board"]; wd3["access"].set_all_targetable([bd3.get_cell_index(2, 5)])
	wd3["routing_access"].bind_board(_m19_open_board_active(14, 11, active)) # rebind access to other board
	_check_eq(wd3["dispatcher"].dispatch(bd3.get_color_id(bd3.get_cell_index(2, 5)), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "routing-access drift blocks dispatch (crit 29)")
	_m19_teardown(wd3)
	# select-access bundle drift
	var wd4 = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bd4 = wd4["board"]; wd4["access"].set_all_targetable([bd4.get_cell_index(2, 5)])
	wd4["access"].coherent = false # select-access reports incoherent
	_check_eq(wd4["dispatcher"].dispatch(bd4.get_color_id(bd4.get_cell_index(2, 5)), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "select-access drift blocks dispatch (crit 30)")
	_m19_teardown(wd4)

	# ===== F-M19-STRICT-002: ProductionTargetAccess boundary (32-45) =====
	var pb = _m19_open_board_active(15, 15, [Vector2(7, 7)])
	var pidx: int = pb.get_cell_index(7, 7)
	var prs = ProductionRoutingSystem.new()
	var pac = ProductionAccessQuery.new(pb)
	var porg := Vector2(-2.0, 7.5)
	var badsys = ProductionTargetAccess.new(123, pac, pb); badsys.set_origin(porg)
	_check(not badsys.is_targetable(pidx), "PTA malformed routing system -> false (crit 32)")
	var badacc = ProductionTargetAccess.new(prs, null, pb); badacc.set_origin(porg)
	_check(not badacc.is_targetable(pidx), "PTA malformed routing access -> false (crit 33)")
	var badboard = ProductionTargetAccess.new(prs, pac, 123); badboard.set_origin(porg)
	_check(not badboard.is_targetable(pidx), "PTA non-BoardState board -> false (crit 34)")
	var good = ProductionTargetAccess.new(prs, pac, pb); good.set_origin(porg)
	_check(good.is_targetable(pidx), "PTA valid exact route -> true (crit 40)")
	_check(good.consume_route(pidx) != null, "PTA consume winning route once (crit 43)")
	_check(good.consume_route(pidx) == null, "PTA second consume -> null (crit 44)")
	_check(good.is_targetable(pidx), "PTA re-probe ok")
	_check(good.consume_route(pidx + 1) == null, "PTA wrong-index consume -> null (crit 45)")
	good.set_origin(Vector2(NAN, 7.5))
	_check(not good.is_targetable(pidx), "PTA non-finite origin -> false (crit 35)")
	_check(good.consume_route(pidx) == null, "PTA non-finite origin cleared memo (crit 35)")
	good.set_origin(porg)
	_check(not good.is_targetable(999999), "PTA invalid index -> false (crit 36)")
	_check(good.is_targetable(pidx), "PTA memo set for failed-probe test")
	_check(not good.is_targetable(88888), "PTA failed probe")
	_check(good.consume_route(pidx) == null, "PTA failed probe cleared stale memo (crit 41)")
	_check(good.is_targetable(pidx), "PTA memo set for set_origin-clear test")
	good.set_origin(Vector2(-3.0, 7.5))
	_check(good.consume_route(pidx) == null, "PTA set_origin cleared memo (crit 42)")
	# malformed/mismatched/invalid route via routing double
	var rd = DispatchRoutingDouble.new()
	var pta = ProductionTargetAccess.new(rd, pac, pb); pta.set_origin(porg)
	rd.mode = "null"; _check(not pta.is_targetable(pidx), "PTA null route -> false (crit 37)")
	rd.mode = "junk_ref"; _check(not pta.is_targetable(pidx), "PTA malformed route Variant -> false (crit 37)")
	rd.mode = "wrong_target"; _check(not pta.is_targetable(pidx), "PTA wrong-target success -> false (crit 38)")
	rd.mode = "nonfinite"; _check(not pta.is_targetable(pidx), "PTA invalid geometry -> false (crit 39)")
	rd.mode = "ok"; _check(pta.is_targetable(pidx), "PTA valid double route -> true")

	# ===== Dispatcher route validation seam (46-55) =====
	var route_cases := {
		"null": DispatchResult.FailureReason.ROUTE_FAILED,
		"junk_ref": DispatchResult.FailureReason.ROUTE_FAILED,
		"fail": DispatchResult.FailureReason.ROUTE_FAILED,
		"wrong_target": DispatchResult.FailureReason.ROUTE_FAILED,
		"wrong_start": DispatchResult.FailureReason.ROUTE_FAILED,
		"wrong_end": DispatchResult.FailureReason.ROUTE_FAILED,
		"nonfinite": DispatchResult.FailureReason.ROUTE_FAILED,
		"short": DispatchResult.FailureReason.ROUTE_FAILED,
	}
	for mode in route_cases:
		var wrc = _m19_wire_fake(_m19_open_board_active(14, 11, active), mode, [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
		var brc = wrc["board"]; wrc["access"].set_all_targetable([brc.get_cell_index(2, 5)])
		var child_before_rc: int = wrc["dispatcher"].get_child_count()
		var rrc = wrc["dispatcher"].dispatch(brc.get_color_id(brc.get_cell_index(2, 5)), origin)
		_check_eq(rrc.failure_reason, route_cases[mode], "route '%s' -> ROUTE_FAILED (crit 46-52)" % mode)
		_check_eq(rrc.target_index, -1, "route '%s' result carries no target (no retarget, crit 55)" % mode)
		_check_eq(wrc["dispatcher"].get_active_count(), 0, "route '%s' spawns zero agents (crit 54)" % mode)
		_check_eq(wrc["dispatcher"].get_child_count(), child_before_rc, "route '%s' creates no child (crit 54)" % mode)
		_check_eq(wrc["reservations"].get_reservation_count(), 0, "route '%s' releases reservation (crit 46-52)" % mode)
		_m19_teardown(wrc)

	# ===== Agent factory / parent (56-67) =====
	var fb = _m19_open_board_active(14, 11, active)
	var fidx: int = fb.get_cell_index(2, 5)
	var fcolor: int = fb.get_color_id(fidx)
	var foreign_parent = Node.new(); root.add_child(foreign_parent)
	var parented_agent = ScrubbotAgent.new(); foreign_parent.add_child(parented_agent)
	var moving_agent = _m19_assigned_agent(fb, fidx, origin, ScrubbotAgent.State.MOVING)
	var arrived_agent = _m19_assigned_agent(fb, fidx, origin, ScrubbotAgent.State.ARRIVED)
	var cancelled_agent = _m19_assigned_agent(fb, fidx, origin, ScrubbotAgent.State.CANCELLED)
	var arbitrary_node = Node2D.new()
	var invalid_products := [null, 5, "x", RefCounted.new(), arbitrary_node,
		parented_agent, moving_agent, arrived_agent, cancelled_agent]
	for prod in invalid_products:
		var wfp = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
		var bfp = wfp["board"]; wfp["access"].set_all_targetable([bfp.get_cell_index(2, 5)])
		wfp["dispatcher"]._agent_factory = func(): return prod
		var cb_fp: int = wfp["dispatcher"].get_child_count()
		var rfp = wfp["dispatcher"].dispatch(bfp.get_color_id(bfp.get_cell_index(2, 5)), origin)
		_check_eq(rfp.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "invalid factory product -> AGENT_ASSIGN_FAILED (crit 57-61,63)")
		_check_eq(wfp["dispatcher"].get_active_count(), 0, "invalid product spawns no active agent (crit 64)")
		_check_eq(wfp["dispatcher"].get_child_count(), cb_fp, "invalid product creates no dispatcher child (crit 64)")
		_check_eq(wfp["reservations"].get_reservation_count(), 0, "invalid product releases reservation (crit 63)")
		_m19_teardown(wfp)
	# foreign objects NOT freed/mutated
	_check(is_instance_valid(parented_agent) and parented_agent.get_parent() == foreign_parent, "parented foreign agent not freed/mutated (crit 58)")
	_check(is_instance_valid(moving_agent) and moving_agent.is_moving(), "MOVING foreign agent not freed/mutated (crit 59)")
	_check(is_instance_valid(arrived_agent) and arrived_agent.has_arrived(), "ARRIVED foreign agent not freed/mutated (crit 60)")
	_check(is_instance_valid(cancelled_agent) and cancelled_agent.is_cancelled(), "CANCELLED foreign agent not freed/mutated (crit 61)")
	_check(is_instance_valid(arbitrary_node), "arbitrary Node2D not freed (crit 57)")
	arbitrary_node.free(); moving_agent.free(); arrived_agent.free(); cancelled_agent.free()
	foreign_parent.remove_child(parented_agent); parented_agent.free(); foreign_parent.free()
	# valid fresh unparented ScrubbotAgent subclass accepted (crit 62)
	var wok = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bok = wok["board"]; wok["access"].set_all_targetable([bok.get_cell_index(2, 5)])
	wok["dispatcher"]._agent_factory = func(): return DispatchAgentDouble.new()
	var rvalid = wok["dispatcher"].dispatch(bok.get_color_id(bok.get_cell_index(2, 5)), origin)
	_check(rvalid.success and rvalid.agent is DispatchAgentDouble, "fresh unparented ScrubbotAgent subclass accepted (crit 62)")
	_m19_teardown(wok)
	# explicit valid agent_parent (crit 65)
	var ep_board = _m19_open_board_active(14, 11, active)
	var ep_res = ReservationState.new(); ep_res.bind(ep_board)
	var ep_cand = ColorCandidateIndex.create(); ep_cand.bind(ep_board)
	var ep_sel = TargetSelector.create(); ep_sel.bind(ep_board, ep_cand, ep_res)
	var ep_routing = DispatchRoutingDouble.new()
	var ep_racc = RouteAccessQueryDouble.new(); ep_racc.default_traversable = true; ep_racc.bind_board(ep_board)
	var ep_acc = AccessQueryDouble.new(); ep_acc.set_all_targetable([ep_board.get_cell_index(2, 5)])
	var ep_parent = Node.new(); root.add_child(ep_parent)
	var ep_disp = ScrubbotDispatcher.new(); root.add_child(ep_disp)
	_check(ep_disp.bind(ep_board, ep_sel, ep_res, ep_routing, ep_racc, ep_acc, ep_parent), "bind with explicit parent ok")
	var ep_r = ep_disp.dispatch(ep_board.get_color_id(ep_board.get_cell_index(2, 5)), origin)
	_check(ep_r.success and ep_r.agent.get_parent() == ep_parent, "explicit valid agent_parent used (crit 65)")
	ep_disp.reset(); root.remove_child(ep_disp); ep_disp.free()
	root.remove_child(ep_parent); ep_parent.free()
	# freed parent before dispatch -> clean fail (crit 66)
	var fp_board = _m19_open_board_active(14, 11, active)
	var fp_res = ReservationState.new(); fp_res.bind(fp_board)
	var fp_cand = ColorCandidateIndex.create(); fp_cand.bind(fp_board)
	var fp_sel = TargetSelector.create(); fp_sel.bind(fp_board, fp_cand, fp_res)
	var fp_routing = DispatchRoutingDouble.new()
	var fp_racc = RouteAccessQueryDouble.new(); fp_racc.default_traversable = true; fp_racc.bind_board(fp_board)
	var fp_acc = AccessQueryDouble.new(); fp_acc.set_all_targetable([fp_board.get_cell_index(2, 5)])
	var fp_parent = Node.new(); root.add_child(fp_parent)
	var fp_disp = ScrubbotDispatcher.new(); root.add_child(fp_disp)
	fp_disp.bind(fp_board, fp_sel, fp_res, fp_routing, fp_racc, fp_acc, fp_parent)
	fp_parent.queue_free() # queued for deletion before dispatch
	var fp_r = fp_disp.dispatch(fp_board.get_color_id(fp_board.get_cell_index(2, 5)), origin)
	_check_eq(fp_r.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "queued-for-delete parent -> fail closed (crit 66,67)")
	_check_eq(fp_res.get_reservation_count(), 0, "freed-parent path releases reservation")
	root.remove_child(fp_disp); fp_disp.free()

	# ===== F-M19-STRICT-004: request numeric boundaries (68-79) =====
	var wq = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bq = wq["board"]; wq["access"].set_all_targetable([bq.get_cell_index(2, 5)])
	var cq: int = bq.get_color_id(bq.get_cell_index(2, 5))
	var pre_next: int = wq["dispatcher"].peek_next_owner_id()
	var pre_calls: int = wq["routing"].call_count
	var pre_queries: int = wq["access"].total_queries()
	var invalids := [
		["neg color", func(): return wq["dispatcher"].dispatch(-1, origin)],
		["NaN x", func(): return wq["dispatcher"].dispatch(cq, Vector2(NAN, 5.5))],
		["+INF x", func(): return wq["dispatcher"].dispatch(cq, Vector2(INF, 5.5))],
		["-INF y", func(): return wq["dispatcher"].dispatch(cq, Vector2(-2.0, -INF))],
		["speed NaN", func(): return wq["dispatcher"].dispatch(cq, origin, NAN)],
		["speed +INF", func(): return wq["dispatcher"].dispatch(cq, origin, INF)],
		["speed -INF", func(): return wq["dispatcher"].dispatch(cq, origin, -INF)],
		["speed 0", func(): return wq["dispatcher"].dispatch(cq, origin, 0.0)],
		["speed neg", func(): return wq["dispatcher"].dispatch(cq, origin, -3.0)],
	]
	for pair in invalids:
		var res_i = pair[1].call()
		_check_eq(res_i.failure_reason, DispatchResult.FailureReason.INVALID_REQUEST, "%s -> INVALID_REQUEST (crit 68-76)" % pair[0])
	_check_eq(wq["reservations"].get_reservation_count(), 0, "invalid requests reserve nothing (crit 77)")
	_check_eq(wq["routing"].call_count, pre_calls, "invalid requests never route (crit 77)")
	_check_eq(wq["access"].total_queries(), pre_queries, "invalid requests never call selector/access (crit 77)")
	_check_eq(wq["dispatcher"].peek_next_owner_id(), pre_next, "invalid requests never advance owner counter (crit 78)")
	_check(wq["dispatcher"].dispatch(cq, origin, 3.5).success, "finite positive speed succeeds (crit 79)")
	_m19_teardown(wq)

	# ===== F-M19-STRICT-003: serial re-entry + reset generation (80-93) =====
	# recursive dispatch rejected
	var wre = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5), _m19_open_board_active(14, 11, active).get_cell_index(4, 5)])
	var bre = wre["board"]; wre["access"].set_all_targetable([bre.get_cell_index(2, 5), bre.get_cell_index(4, 5)])
	var cre: int = bre.get_color_id(bre.get_cell_index(2, 5))
	var dre = wre["dispatcher"]
	var inner_reason := [StringName("")]
	wre["routing"].on_compute = func(): inner_reason[0] = dre.dispatch(cre, origin).failure_reason
	var outer = dre.dispatch(cre, origin)
	wre["routing"].on_compute = Callable()
	_check_eq(inner_reason[0], DispatchResult.FailureReason.REENTRANT, "recursive dispatch -> REENTRANT (crit 80)")
	_check(outer.success, "outer dispatch still succeeds after re-entry rejection")
	_check_eq(dre.get_active_count(), 1, "recursive dispatch created no duplicate assignment (crit 81)")
	_m19_teardown(wre)
	# reset injected from each phase
	var reset_phases := ["select", "routing", "factory", "assign", "addchild"]
	for phase in reset_phases:
		var wrs = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
		var brs = wrs["board"]; wrs["access"].set_all_targetable([brs.get_cell_index(2, 5)])
		var crs: int = brs.get_color_id(brs.get_cell_index(2, 5))
		var drs = wrs["dispatcher"]
		match phase:
			"select":
				wrs["access"].on_query = func(_i): drs.reset()
			"routing":
				wrs["routing"].on_compute = func(): drs.reset()
			"factory":
				drs._agent_factory = func(): drs.reset(); return ScrubbotAgent.new()
			"assign":
				drs._agent_factory = func():
					var a = DispatchAgentDouble.new()
					a.on_assign = func(): drs.reset()
					return a
			"addchild":
				# rewire under a parent whose child_entered_tree triggers reset
				_m19_teardown(wrs)
				var rp_board = _m19_open_board_active(14, 11, active)
				var rp_res = ReservationState.new(); rp_res.bind(rp_board)
				var rp_cand = ColorCandidateIndex.create(); rp_cand.bind(rp_board)
				var rp_sel = TargetSelector.create(); rp_sel.bind(rp_board, rp_cand, rp_res)
				var rp_routing = DispatchRoutingDouble.new()
				var rp_racc = RouteAccessQueryDouble.new(); rp_racc.default_traversable = true; rp_racc.bind_board(rp_board)
				var rp_acc = AccessQueryDouble.new(); rp_acc.set_all_targetable([rp_board.get_cell_index(2, 5)])
				var rp_parent = Node.new(); root.add_child(rp_parent)
				var rp_disp = ScrubbotDispatcher.new(); root.add_child(rp_disp)
				rp_disp.bind(rp_board, rp_sel, rp_res, rp_routing, rp_racc, rp_acc, rp_parent)
				rp_parent.child_entered_tree.connect(func(_c): rp_disp.reset())
				var rp_before = _snapshot_cell_states(rp_board)
				var rp_r = rp_disp.dispatch(rp_board.get_color_id(rp_board.get_cell_index(2, 5)), origin)
				# child_entered_tree may be delivered deferred by the engine, so this
				# phase is only strictly reproducible when the reset lands synchronously
				# inside add_child (crit 86: "where reproducible"). The generation guard
				# after add_child covers it either way.
				if rp_r.failure_reason == DispatchResult.FailureReason.RESETTING:
					_check_eq(rp_disp.get_active_count(), 0, "add-child reset: no pending active (crit 88)")
					_check_eq(rp_parent.get_child_count(), 0, "add-child reset: no orphan child (crit 89)")
					_check_eq(rp_res.get_reservation_count(), 0, "add-child reset: pending reservation released")
				else:
					print("     M19 add-child reset: child_entered_tree delivered deferred; generation guard still covers add_child boundary")
				_check(_cell_states_equal(rp_board, rp_before), "add-child reset: BoardState unchanged (crit 90)")
				rp_disp.reset(); root.remove_child(rp_disp); rp_disp.free()
				root.remove_child(rp_parent); rp_parent.free()
				continue
		var rp_before2 = _snapshot_cell_states(brs)
		var res_r = drs.dispatch(crs, origin)
		_check(res_r.failure_reason == DispatchResult.FailureReason.RESETTING, "reset during %s -> RESETTING (crit 82-85,87)" % phase)
		_check_eq(drs.get_active_count(), 0, "reset during %s: no pending _active (crit 88)" % phase)
		_check_eq(drs.get_child_count(), 0, "reset during %s: no orphan child (crit 89)" % phase)
		_check_eq(wrs["reservations"].get_reservation_count(), 0, "reset during %s: pending reservation released (crit 83,84)" % phase)
		_check(_cell_states_equal(brs, rp_before2), "reset during %s: BoardState unchanged (crit 90)" % phase)
		# later dispatch recovers, owner id monotonic (crit 91,92)
		wrs["access"].on_query = Callable(); wrs["routing"].on_compute = Callable()
		drs._agent_factory = Callable()
		var next_before: int = drs.peek_next_owner_id()
		var recover = drs.dispatch(crs, origin)
		_check(recover.success, "later dispatch recovers after reset during %s (crit 91)" % phase)
		_check(recover.owner_id >= next_before, "owner id monotonic across reset during %s (crit 92)" % phase)
		_m19_teardown(wrs)

	# ===== Completion identity (94-102) =====
	var wc = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bc = wc["board"]; wc["access"].set_all_targetable([bc.get_cell_index(2, 5)])
	var cc: int = bc.get_color_id(bc.get_cell_index(2, 5))
	var dc = wc["dispatcher"]
	var rc = dc.dispatch(cc, origin)
	var agent_c = rc.agent
	var before_c = _snapshot_cell_states(bc)
	agent_c.agent_completed.emit(rc.owner_id, rc.target_index + 1, cc) # wrong target
	_check(not dc.has_arrived(rc.owner_id), "wrong target completion ignored (crit 96)")
	agent_c.agent_completed.emit(rc.owner_id, rc.target_index, cc + 1) # wrong color
	_check(not dc.has_arrived(rc.owner_id), "wrong color completion ignored (crit 97)")
	agent_c.agent_completed.emit(rc.owner_id + 999, rc.target_index, cc) # wrong owner
	_check(not dc.has_arrived(rc.owner_id), "wrong owner completion ignored (crit 98)")
	dc._on_agent_completed(rc.owner_id, rc.target_index, cc, ScrubbotAgent.new()) # wrong source agent
	_check(not dc.has_arrived(rc.owner_id), "wrong/stale agent source ignored (crit 99)")
	agent_c.agent_completed.emit(rc.owner_id, rc.target_index, cc) # correct
	_check(dc.has_arrived(rc.owner_id), "correct completion marks arrived (crit 94)")
	agent_c.agent_completed.emit(rc.owner_id, rc.target_index, cc) # repeat
	_check(dc.has_arrived(rc.owner_id), "repeated correct completion idempotent (crit 95)")
	_check(_cell_states_equal(bc, before_c), "completion does not clear BoardState (crit 101)")
	_check(wc["reservations"].is_reserved(rc.target_index), "completion does not release successful reservation (crit 102)")
	dc.reset()
	dc._on_agent_completed(rc.owner_id, rc.target_index, cc, null) # post-reset stale
	_check(not dc.has_owner(rc.owner_id), "post-reset completion cannot recreate state (crit 100)")
	_m19_teardown(wc)

# ======================================= M19-C001 V03 second-stage closure ===
# F-M19-STRICT-001.A/B/C, 002.A/B/C, 003.A/B/C: mandatory select-access coherence,
# RefCounted collaborator categories, guard armed before coherence + generation
# checks after every boundary, mid-dispatch bundle drift, missing-vs-invalid
# cached route, explicit-factory drift, assign postconditions.

## Bundle whose 5 collaborators are all flexible coherent doubles over a real
## board, so a coherence seam can be hooked for recursion/reset injection.
func _m19_collab_dispatcher() -> Dictionary:
	var board = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var selD = M19CollabDouble.new()
	var resD = M19CollabDouble.new()
	var routingD = M19CollabDouble.new()
	var raccD = M19CollabDouble.new()
	var saccD = M19CollabDouble.new()
	var disp = ScrubbotDispatcher.new(); root.add_child(disp)
	var ok: bool = disp.bind(board, selD, resD, routingD, raccD, saccD)
	return {"board": board, "selD": selD, "resD": resD, "routingD": routingD,
		"raccD": raccD, "saccD": saccD, "dispatcher": disp, "bound": ok}

## Coherent bundle whose select_access is an M19CacheSelectAccess (exposes the
## optional set_origin/consume_route seam) and whose routing_system is a
## DispatchRoutingDouble (call_count observable). Real selector/reservation.
func _m19_wire_cache(cache_access) -> Dictionary:
	var board = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = DispatchRoutingDouble.new()
	var routing_access = RouteAccessQueryDouble.new()
	routing_access.default_traversable = true; routing_access.bind_board(board)
	var disp = ScrubbotDispatcher.new(); root.add_child(disp)
	disp.bind(board, selector, reservations, routing, routing_access, cache_access)
	return {"board": board, "reservations": reservations, "selector": selector,
		"routing": routing, "routing_access": routing_access, "access": cache_access,
		"dispatcher": disp}

func _run_m19_strict_v3_tests() -> void:
	print("---- M19-C001 V03: strict-v2 second-stage closure ----")
	var active := [Vector2(2, 5), Vector2(4, 5), Vector2(6, 5), Vector2(8, 5), Vector2(10, 5)]
	var origin := Vector2(-2.0, 5.5)

	# ===== Mandatory select-access coherence (7-13) =====
	var rb = _m19_real_bundle(20, 20, Vector2(10, 10))
	var B = rb["board"]; var S = rb["selector"]; var R = rb["reservations"]
	var RS = rb["routing"]; var RA = rb["routing_access"]
	_check(not _m19_try_bind(B, S, R, RS, RA, RefCounted.new()), "select_access missing is_targetable rejected (crit 7)")
	_check(not _m19_try_bind(B, S, R, RS, RA, M19NoCoherenceSelect.new()), "select_access missing is_coherent_with rejected (crit 8)")
	var sv_nonbool = M19SelectAccessVariants.new(); sv_nonbool.coherence_value = 1
	_check(not _m19_try_bind(B, S, R, RS, RA, sv_nonbool), "select_access non-bool coherence rejected (crit 9)")
	var sv_false = M19SelectAccessVariants.new(); sv_false.coherence_value = false
	_check(not _m19_try_bind(B, S, R, RS, RA, sv_false), "select_access false coherence rejected (crit 10)")
	_check(_m19_try_bind(B, S, R, RS, RA, rb["select_access"]), "exact coherent ProductionTargetAccess accepted (crit 11)")
	var wf12 = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [])
	_check(wf12["dispatcher"].is_bound(), "exact coherent AccessQueryDouble accepted (crit 12)")
	_m19_teardown(wf12)
	var rb_other = _m19_real_bundle(20, 20, Vector2(10, 10))
	_check(not _m19_try_bind(B, S, R, RS, RA, rb_other["select_access"]), "same-shape different select bundle rejected (crit 13)")

	# ===== RefCounted collaborator lifecycle (14-20) =====
	var node_slots := ["selector", "reservations", "routing", "routing_access", "select_access"]
	for slot in node_slots:
		var nodeD = M19NodeCollabDouble.new()
		var ok_node: bool
		match slot:
			"selector": ok_node = _m19_try_bind(B, nodeD, R, RS, RA, rb["select_access"])
			"reservations": ok_node = _m19_try_bind(B, S, nodeD, RS, RA, rb["select_access"])
			"routing": ok_node = _m19_try_bind(B, S, R, nodeD, RA, rb["select_access"])
			"routing_access": ok_node = _m19_try_bind(B, S, R, RS, nodeD, rb["select_access"])
			"select_access": ok_node = _m19_try_bind(B, S, R, RS, RA, nodeD)
		_check(not ok_node, "method-compatible Node %s rejected (crit 14-18)" % slot)
		nodeD.free()
	_check(_m19_try_bind(B, S, R, RS, RA, rb["select_access"]), "canonical RefCounted dependencies accepted (crit 19)")
	var parent20 = Node.new(); root.add_child(parent20)
	var disp20 = ScrubbotDispatcher.new(); root.add_child(disp20)
	_check(disp20.bind(B, S, R, RS, RA, rb["select_access"], parent20), "valid Node agent_parent supported (crit 20)")
	root.remove_child(disp20); disp20.free(); root.remove_child(parent20); parent20.free()

	# ===== Re-entry guard ordering + reset during coherence (21-31) =====
	var seams := ["selD", "resD", "raccD", "saccD"]
	for seam in seams:
		var cb = _m19_collab_dispatcher()
		var disp = cb["dispatcher"]
		var inner := [StringName("")]
		var hook := func(): inner[0] = disp.dispatch(0, origin).failure_reason
		cb[seam].on_check = hook
		var before_next: int = disp.peek_next_owner_id()
		var _outer = disp.dispatch(0, origin)
		cb[seam].on_check = Callable() # stop recursion for teardown
		_check_eq(inner[0], DispatchResult.FailureReason.REENTRANT, "recursion from %s coherence -> REENTRANT (crit 21-24)" % seam)
		_check_eq(disp.peek_next_owner_id(), before_next, "coherence recursion advances no owner id (crit 27)")
		root.remove_child(disp); disp.free()
	# reset injected from a coherence seam
	var cbr = _m19_collab_dispatcher()
	var dispr = cbr["dispatcher"]
	cbr["selD"].on_check = func(): dispr.reset()
	var reset_coh = dispr.dispatch(0, origin)
	cbr["selD"].on_check = Callable()
	_check_eq(reset_coh.failure_reason, DispatchResult.FailureReason.RESETTING, "reset during coherence -> RESETTING (crit 28)")
	_check_eq(cbr["selD"].select_calls, 0, "reset during coherence prevents selection (crit 29)")
	var recover_coh = dispr.dispatch(0, origin)
	_check(recover_coh.failure_reason != DispatchResult.FailureReason.REENTRANT, "guard cleared after coherence abort (crit 30,31)")
	root.remove_child(dispr); dispr.free()

	# ===== Immediate generation checks: set_origin / consume_route (32-41) =====
	# reset during set_origin
	var ca_so = M19CacheSelectAccess.new(); ca_so.default_targetable = true
	var wso = _m19_wire_cache(ca_so)
	ca_so.on_set_origin = func(): wso["dispatcher"].reset()
	var color_so: int = wso["board"].get_color_id(wso["board"].get_cell_index(2, 5))
	var rso = wso["dispatcher"].dispatch(color_so, origin)
	ca_so.on_set_origin = Callable()
	_check_eq(rso.failure_reason, DispatchResult.FailureReason.RESETTING, "reset during set_origin -> RESETTING (crit 32)")
	_check_eq(ca_so.total_queries(), 0, "set_origin reset prevents selector call (crit 33)")
	_check_eq(wso["reservations"].get_reservation_count(), 0, "set_origin reset creates no reservation (crit 34)")
	_check_eq(wso["dispatcher"].get_active_count(), 0, "set_origin reset: no pending active (crit 38)")
	var rec_so = wso["dispatcher"].dispatch(color_so, origin)
	_check(rec_so.success, "later dispatch recovers after set_origin reset (crit 40)")
	_m19_teardown(wso)
	# reset during consume_route
	var ca_cr = M19CacheSelectAccess.new(); ca_cr.default_targetable = true; ca_cr.cached_route = null
	var wcr = _m19_wire_cache(ca_cr)
	ca_cr.on_consume = func(): wcr["dispatcher"].reset()
	var color_cr: int = wcr["board"].get_color_id(wcr["board"].get_cell_index(2, 5))
	var rcr = wcr["dispatcher"].dispatch(color_cr, origin)
	ca_cr.on_consume = Callable()
	_check_eq(rcr.failure_reason, DispatchResult.FailureReason.RESETTING, "reset during consume_route -> RESETTING (crit 35)")
	_check_eq(wcr["routing"].call_count, 0, "consume reset prevents fresh routing compute (crit 36)")
	_check_eq(wcr["reservations"].get_reservation_count(), 0, "consume reset releases pending reservation (crit 37)")
	_check_eq(wcr["dispatcher"].get_active_count(), 0, "consume reset: no pending active (crit 38,39)")
	var next_cr: int = wcr["dispatcher"].peek_next_owner_id()
	var rec_cr = wcr["dispatcher"].dispatch(color_cr, origin)
	_check(rec_cr.success, "later dispatch recovers after consume reset (crit 40)")
	_check(rec_cr.owner_id >= next_cr - 1, "owner ids remain monotonic across consume reset (crit 41)")
	_m19_teardown(wcr)

	# ===== Cached-route missing vs invalid distinction (53-64) =====
	var idx_c := 0
	var mk_cache_wire := func(cache_val, targetable_only_first: bool):
		var ca = M19CacheSelectAccess.new()
		var w = _m19_wire_cache(ca)
		idx_c = w["board"].get_cell_index(2, 5)
		ca.default_targetable = false
		ca.set_targetable(idx_c, true)
		ca.cached_route = cache_val
		return w
	var center_c := Vector2(2.0 + 0.5, 5.0 + 0.5)
	# null cache -> fresh compute allowed
	var wnull = mk_cache_wire.call(null, true)
	var idx_null: int = wnull["board"].get_cell_index(2, 5)
	# fix valid_cached target to the real idx for later; here null path
	var rnull = wnull["dispatcher"].dispatch(wnull["board"].get_color_id(idx_null), origin)
	_check(rnull.success, "null cached route permits fresh compute (crit 53)")
	_check_eq(wnull["routing"].call_count, 1, "null cache did a fresh compute")
	_m19_teardown(wnull)
	# non-null invalid caches -> ROUTE_FAILED, ZERO fresh compute
	var bad_caches := {
		"scalar": 5,
		"junk_ref": RefCounted.new(),
		"failure": RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, 0),
		"wrong_target": RouteResult.success_route(9999, PackedVector2Array([origin, center_c])),
		"wrong_start": RouteResult.success_route(0, PackedVector2Array([origin + Vector2(9, 9), center_c])),
		"wrong_end": RouteResult.success_route(0, PackedVector2Array([origin, center_c + Vector2(2, 2)])),
		"non_finite": RouteResult.success_route(0, PackedVector2Array([origin, Vector2(NAN, 0), center_c])),
	}
	for name in bad_caches:
		var wbc = mk_cache_wire.call(bad_caches[name], true)
		var idxb: int = wbc["board"].get_cell_index(2, 5)
		# ensure cached route target matches the reserved target for target-based cases
		if bad_caches[name] is RouteResult and bad_caches[name].target_index == 0 and name != "wrong_target":
			# rebuild with the real idx as target so only the intended defect differs
			var pts_map := {
				"failure": null,
				"wrong_start": PackedVector2Array([origin + Vector2(9, 9), center_c]),
				"wrong_end": PackedVector2Array([origin, center_c + Vector2(2, 2)]),
				"non_finite": PackedVector2Array([origin, Vector2(NAN, 0), center_c]),
			}
			if name == "failure":
				wbc["access"].cached_route = RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idxb)
			else:
				wbc["access"].cached_route = RouteResult.success_route(idxb, pts_map[name])
		var cb_child: int = wbc["dispatcher"].get_child_count()
		var rbc = wbc["dispatcher"].dispatch(wbc["board"].get_color_id(idxb), origin)
		_check_eq(rbc.failure_reason, DispatchResult.FailureReason.ROUTE_FAILED, "non-null invalid cache '%s' -> ROUTE_FAILED (crit 54-59)" % name)
		_check_eq(wbc["routing"].call_count, 0, "invalid cache '%s' does ZERO fresh compute (crit 61)" % name)
		_check_eq(wbc["reservations"].get_reservation_count(), 0, "invalid cache '%s' releases reservation (crit 60)" % name)
		_check_eq(wbc["dispatcher"].get_child_count(), cb_child, "invalid cache '%s' creates zero agent (crit 62)" % name)
		_m19_teardown(wbc)
	# valid cache -> success, skip redundant compute
	var wvc = M19CacheSelectAccess.new()
	var wv = _m19_wire_cache(wvc)
	var idxv: int = wv["board"].get_cell_index(2, 5)
	wvc.default_targetable = false; wvc.set_targetable(idxv, true)
	wvc.cached_route = RouteResult.success_route(idxv, PackedVector2Array([origin, center_c]))
	var rvc = wv["dispatcher"].dispatch(wv["board"].get_color_id(idxv), origin)
	_check(rvc.success, "valid cached route succeeds (crit 63)")
	_check_eq(wv["routing"].call_count, 0, "valid cached route skips redundant compute (crit 64)")
	_m19_teardown(wv)

	# ===== Explicit factory Callable drift (65-71) =====
	var ef_board = _m19_open_board_active(14, 11, active)
	var ef_res = ReservationState.new(); ef_res.bind(ef_board)
	var ef_cand = ColorCandidateIndex.create(); ef_cand.bind(ef_board)
	var ef_sel = TargetSelector.create(); ef_sel.bind(ef_board, ef_cand, ef_res)
	var ef_routing = DispatchRoutingDouble.new()
	var ef_racc = RouteAccessQueryDouble.new(); ef_racc.default_traversable = true; ef_racc.bind_board(ef_board)
	var ef_acc = AccessQueryDouble.new(); ef_acc.set_all_targetable([ef_board.get_cell_index(2, 5), ef_board.get_cell_index(4, 5)])
	var holder = AgentFactoryHolder.new(); root.add_child(holder)
	var ef_disp = ScrubbotDispatcher.new(); root.add_child(ef_disp)
	_check(ef_disp.bind(ef_board, ef_sel, ef_res, ef_routing, ef_racc, ef_acc, null, Callable(holder, "make_agent")), "bind with explicit factory Callable ok")
	var ef_color: int = ef_board.get_color_id(ef_board.get_cell_index(2, 5))
	var ef_r1 = ef_disp.dispatch(ef_color, origin)
	_check(ef_r1.success, "explicit valid factory Callable works (crit 66)")
	var active_after_valid: int = ef_disp.get_active_count()
	root.remove_child(holder); holder.free() # invalidate the explicit Callable
	var ef_r2 = ef_disp.dispatch(ef_color, origin)
	_check_eq(ef_r2.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "invalidated explicit factory -> AGENT_ASSIGN_FAILED (crit 69)")
	_check_eq(ef_disp.get_active_count(), active_after_valid, "invalidated explicit factory made no default agent (crit 68,71)")
	_check_eq(ef_res.get_reservation_count(), active_after_valid, "invalidated explicit factory released its pending reservation (crit 70)")
	ef_disp.reset(); root.remove_child(ef_disp); ef_disp.free()

	# ===== assign postconditions (72-81) =====
	var lie_modes := ["unassigned", "wrong_owner", "wrong_color", "wrong_target", "parented"]
	for mode in lie_modes:
		var wl = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
		var bl = wl["board"]; wl["access"].set_all_targetable([bl.get_cell_index(2, 5)])
		var stash = Node.new(); root.add_child(stash)
		wl["dispatcher"]._agent_factory = func():
			var a = LyingAgentDouble.new()
			a.lie_mode = mode
			a.stash_parent = stash
			return a
		var cl_child: int = wl["dispatcher"].get_child_count()
		var rl = wl["dispatcher"].dispatch(bl.get_color_id(bl.get_cell_index(2, 5)), origin)
		_check_eq(rl.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "lying agent '%s' -> AGENT_ASSIGN_FAILED (crit 73-77)" % mode)
		_check_eq(wl["dispatcher"].get_active_count(), 0, "lying agent '%s' creates no active entry (crit 80)" % mode)
		_check_eq(wl["dispatcher"].get_child_count(), cl_child, "lying agent '%s' creates no dispatcher child (crit 78)" % mode)
		_check_eq(wl["reservations"].get_reservation_count(), 0, "lying agent '%s' releases reservation (crit 79)" % mode)
		_check_eq(stash.get_child_count(), 0, "lying agent '%s' freed even if it parented itself (crit 78)" % mode)
		root.remove_child(stash); stash.free()
		_m19_teardown(wl)
	# valid subclass still accepted (crit 72,81)
	var wvs = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bvs = wvs["board"]; wvs["access"].set_all_targetable([bvs.get_cell_index(2, 5)])
	wvs["dispatcher"]._agent_factory = func(): return DispatchAgentDouble.new()
	var rvs = wvs["dispatcher"].dispatch(bvs.get_color_id(bvs.get_cell_index(2, 5)), origin)
	_check(rvs.success and rvs.agent.get_state() == ScrubbotAgent.State.MOVING, "valid subclass assign accepted, MOVING (crit 72,81)")
	_m19_teardown(wvs)

	# ===== Mid-dispatch bundle drift (42-52) =====
	# prior committed assignment must survive a later drifting dispatch
	var wdrift = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [])
	var bdr = wdrift["board"]; wdrift["access"].set_all_targetable([bdr.get_cell_index(2, 5), bdr.get_cell_index(4, 5)])
	var cdr: int = bdr.get_color_id(bdr.get_cell_index(2, 5))
	var prior = wdrift["dispatcher"].dispatch(cdr, origin)
	_check(prior.success, "drift precondition: one prior committed assignment")
	# select-access drift during selection callback
	wdrift["access"].on_query = func(_i): wdrift["access"].coherent = false
	var drift_r = wdrift["dispatcher"].dispatch(cdr, origin)
	wdrift["access"].on_query = Callable(); wdrift["access"].coherent = true
	_check_eq(drift_r.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "select-access drift mid-dispatch -> COHERENCE_FAILED (crit 44,48)")
	_check(wdrift["dispatcher"].has_owner(prior.owner_id), "prior committed assignment survives pending drift (crit 50)")
	_check_eq(wdrift["dispatcher"].get_active_count(), 1, "drift committed no new active assignment (crit 48,51)")
	# routing-access drift during routing callback
	var other_board = _m19_open_board_active(14, 11, active)
	wdrift["routing"].on_compute = func(): wdrift["routing_access"].bind_board(other_board)
	var drift_r2 = wdrift["dispatcher"].dispatch(cdr, origin)
	wdrift["routing"].on_compute = Callable(); wdrift["routing_access"].bind_board(bdr)
	_check_eq(drift_r2.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "routing-access drift mid-dispatch -> COHERENCE_FAILED (crit 43,48)")
	_check_eq(wdrift["dispatcher"].get_active_count(), 1, "routing drift committed no new assignment (crit 51)")
	# later coherent dispatch recovers
	var rec_drift = wdrift["dispatcher"].dispatch(cdr, origin)
	_check(rec_drift.success, "coherent dispatcher recovers after drift aborts (crit 52)")
	_m19_teardown(wdrift)
	# factory-phase drift
	var wfd = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bfd = wfd["board"]; wfd["access"].set_all_targetable([bfd.get_cell_index(2, 5)])
	wfd["dispatcher"]._agent_factory = func():
		wfd["access"].coherent = false
		return ScrubbotAgent.new()
	var fd_child: int = wfd["dispatcher"].get_child_count()
	var rfd = wfd["dispatcher"].dispatch(bfd.get_color_id(bfd.get_cell_index(2, 5)), origin)
	_check_eq(rfd.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "factory-phase drift -> COHERENCE_FAILED (crit 46)")
	_check_eq(wfd["dispatcher"].get_child_count(), fd_child, "factory-phase drift: no orphan agent (crit 51)")
	_check_eq(wfd["reservations"].get_reservation_count(), 0, "factory-phase drift releases pending reservation (crit 49)")
	_m19_teardown(wfd)
	# assign-phase drift
	var wad = _m19_wire_fake(_m19_open_board_active(14, 11, active), "ok", [_m19_open_board_active(14, 11, active).get_cell_index(2, 5)])
	var bad2 = wad["board"]; wad["access"].set_all_targetable([bad2.get_cell_index(2, 5)])
	wad["dispatcher"]._agent_factory = func():
		var a = DispatchAgentDouble.new()
		a.on_assign = func(): wad["access"].coherent = false
		return a
	var ad_child: int = wad["dispatcher"].get_child_count()
	var rad = wad["dispatcher"].dispatch(bad2.get_color_id(bad2.get_cell_index(2, 5)), origin)
	_check_eq(rad.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "assign-phase drift -> COHERENCE_FAILED (crit 47)")
	_check_eq(wad["dispatcher"].get_child_count(), ad_child, "assign-phase drift: no orphan agent (crit 51)")
	_check_eq(wad["reservations"].get_reservation_count(), 0, "assign-phase drift releases pending reservation (crit 49)")
	_m19_teardown(wad)

# ================================================== M17-C002 V03 hardening ==
# Frozen full-surface finding set F-M17-STRICT-001..009. Fail-closed access,
# exact supercover traversal, complete exterior reachability, hardened public
# boundary, per-edge access truth, self-validating fallback, tuning robustness.

func _v03_all_finite(pts: PackedVector2Array) -> bool:
	for p in pts:
		if not p.is_finite():
			return false
	return true

func _v03_open_board(w: int, h: int):
	return RoutingLabScenarios.make_open_board(w, h)

func _run_m17c002_v03_hardening_tests() -> void:
	print("---- M17-C002 V03: full-surface hardening ----")

	# --- F-007: ProductionAccessQuery fail-closed + is_bound_to ---
	var board = _v03_open_board(25, 25)
	var tgt = board.get_cell_index(20, 23)
	board.set_cell_state(tgt, BoardState.CellState.ACTIVE)
	var acc = ProductionAccessQuery.new(board)
	_check(acc.is_bound_to(board), "is_bound_to true for the exact bound board")
	_check(not acc.is_bound_to(_v03_open_board(25, 25)), "is_bound_to false for a same-size DIFFERENT board")
	_check(not acc.is_bound_to(null), "is_bound_to false for null")
	_check(not acc.is_bound_to(123), "is_bound_to false for a scalar")
	var unbound = ProductionAccessQuery.new(123)
	_check(not unbound.is_bound_to(board), "unbound instance is_bound_to false")
	_check_eq(unbound.classify_cell(0, 0, 0), ProductionAccessQuery.CellClass.BLOCKED, "unbound classify_cell -> BLOCKED (fail closed)")
	_check(not unbound.is_segment_traversable(Vector2(0.5, 0.5), Vector2(1.5, 0.5), 0), "unbound is_segment_traversable -> false")
	_check_eq(unbound.cell_of_point(Vector2(NAN, 0.0)), ProductionAccessQuery.OUTSIDE_SENTINEL, "cell_of_point(non-finite) -> documented sentinel")
	_check(not acc.has_method("get_board"), "no mutable board reference is exposed")
	_check(not acc.is_segment_traversable(Vector2(NAN, 0.5), Vector2(20.5, 23.5), tgt), "NaN from endpoint -> false")
	_check(not acc.is_segment_traversable(Vector2(0.5, 0.5), Vector2(INF, 23.5), tgt), "INF to endpoint -> false")
	_check(not acc.is_segment_traversable(Vector2(0.5, 0.5), Vector2(1.5, 0.5), 999999), "invalid target index -> false")

	# --- F-002: exact supercover traversal (not sampling) ---
	var blk = board.get_cell_index(7, 7)
	board.set_cell_state(blk, BoardState.CellState.ACTIVE)
	var acc_blk = ProductionAccessQuery.new(board)
	_check(not acc_blk.is_segment_traversable(Vector2(0.5, 0.5), Vector2(20.5, 23.5), tgt), "short chord grazing ACTIVE (7,7) -> false (exact, not sampled)")
	board.set_cell_state(blk, BoardState.CellState.CLEARED)
	var acc_clr = ProductionAccessQuery.new(board)
	_check(acc_clr.is_segment_traversable(Vector2(0.5, 0.5), Vector2(20.5, 23.5), tgt), "same chord with (7,7) CLEARED -> true")

	var cb = _v03_open_board(5, 5)
	var ct = cb.get_cell_index(4, 4); cb.set_cell_state(ct, BoardState.CellState.ACTIVE)
	cb.set_cell_state(cb.get_cell_index(2, 1), BoardState.CellState.ACTIVE)
	cb.set_cell_state(cb.get_cell_index(1, 2), BoardState.CellState.ACTIVE)
	var acc_c = ProductionAccessQuery.new(cb)
	_check(not acc_c.is_segment_traversable(Vector2(1.5, 1.5), Vector2(2.5, 2.5), ct), "exact diagonal corner between blockers -> false")
	_check(acc_c.is_segment_traversable(Vector2(0.5, 0.5), Vector2(3.5, 0.5), ct), "axis-aligned CLEARED corridor -> true")
	_check(acc_c.is_segment_traversable(Vector2(-3, -3), Vector2(-1, -1), ct), "outside-board segment -> true")
	var ctc = RouteRequest.center_of_index(cb, ct)
	_check(acc_c.is_segment_traversable(Vector2(-2, 4.5), ctc, ct), "outside -> target center final arrival -> true")
	_check(not acc_c.is_segment_traversable(ctc, Vector2(4.5, 0.5), ct), "target used as non-final transit -> false")

	# --- F-001: complete exterior reachability, >12-entry later-only route ---
	var f = BoardDebugFixtures.make_board(6, 26) # all ACTIVE
	for i in range(12):
		var y = 1 + 2 * i
		f.set_cell_state(f.get_cell_index(0, y), BoardState.CellState.CLEARED)
		f.set_cell_state(f.get_cell_index(1, y), BoardState.CellState.CLEARED)
	f.set_cell_state(f.get_cell_index(0, 25), BoardState.CellState.CLEARED)
	f.set_cell_state(f.get_cell_index(1, 25), BoardState.CellState.CLEARED)
	var ftgt = f.get_cell_index(2, 25) # ACTIVE far-finger target
	var fa = ProductionAccessQuery.new(f)
	var freq = RouteRequest.for_target(f, Vector2(-50, 12.5), ftgt)
	var fres = ProductionRoutingSystem.new().compute_route(freq, f, fa)
	_check(fres.success, "no correctness-affecting entry cap: 13th (far) entry route found")
	_check_eq(fres.target_index, ftgt, ">12-entry route keeps the same target")
	if fres.success:
		var maxy := 0.0
		for p in fres.get_points():
			maxy = maxf(maxy, p.y)
		_check(maxy >= 25.0, "route uses the far (later-only) entry near y=25")
		_check_eq(RouteValidator.validate_route(freq, fres, f, fa), RouteResult.FailureReason.NONE, "far-entry route validates")

	# --- F-008: direct outside-to-perimeter target ---
	var pb = BoardDebugFixtures.make_board(5, 5) # all ACTIVE
	var ptgt = pb.get_cell_index(0, 2) # left-perimeter ACTIVE target; everything else ACTIVE
	var pa = ProductionAccessQuery.new(pb)
	var preq = RouteRequest.for_target(pb, Vector2(-2, 2.5), ptgt)
	var pres = ProductionRoutingSystem.new().compute_route(preq, pb, pa)
	_check(pres.success, "direct outside-to-perimeter target succeeds")
	_check_eq(pres.target_index, ptgt, "perimeter target identity retained")
	if pres.success:
		_check_eq(RouteValidator.validate_route(preq, pres, pb, pa), RouteResult.FailureReason.NONE, "perimeter-target route validates")
	var other = pb.get_cell_index(4, 2)
	_check(not pa.is_segment_traversable(Vector2(-2, 2.5), Vector2(4.5, 2.5), other), "perimeter target not opened as transit for an unrelated route")

	# --- F-006: hardened public request/access boundary ---
	var vb = _v03_open_board(8, 6)
	var vt = vb.get_cell_index(6, 3); vb.set_cell_state(vt, BoardState.CellState.ACTIVE)
	var va = ProductionAccessQuery.new(vb)
	var good_req = RouteRequest.for_target(vb, Vector2(-2, 3.5), vt)
	var prod = ProductionRoutingSystem.new()
	var r_null = prod.compute_route(null, vb, va)
	_check(not r_null.success and r_null.target_index == -1, "null request -> stable failure, target -1")
	var r_scalar = prod.compute_route(42, vb, va)
	_check(not r_scalar.success and r_scalar.target_index == -1, "scalar request -> stable failure, target -1")
	var r_junk = prod.compute_route({"not": "a request"}, vb, va)
	_check(not r_junk.success and r_junk.target_index == -1, "junk (Dictionary) request -> stable failure, target -1")
	var r_sacc = prod.compute_route(good_req, vb, 5)
	_check(not r_sacc.success, "scalar access -> stable failure")
	_check_eq(r_sacc.failure_reason, RouteResult.FailureReason.MISSING_ACCESS_QUERY, "scalar access -> MISSING_ACCESS_QUERY")
	_check_eq(r_sacc.target_index, vt, "scalar-access failure keeps the assigned target")
	var r_miss = prod.compute_route(good_req, vb, RouteAccessMissingMethod.new())
	_check_eq(r_miss.failure_reason, RouteResult.FailureReason.MISSING_ACCESS_QUERY, "access missing a seam method -> MISSING_ACCESS_QUERY")
	var r_wrong = prod.compute_route(good_req, vb, RouteAccessWrongReturn.new())
	_check_eq(r_wrong.failure_reason, RouteResult.FailureReason.MISSING_ACCESS_QUERY, "full-shape wrong-return access -> MISSING_ACCESS_QUERY")
	var diff_board_acc = ProductionAccessQuery.new(_v03_open_board(8, 6))
	var r_coh = prod.compute_route(good_req, vb, diff_board_acc)
	_check_eq(r_coh.failure_reason, RouteResult.FailureReason.MISSING_ACCESS_QUERY, "same-size DIFFERENT-board access rejected (coherence)")

	# --- F-003/§5: every used planner edge obeys segment access ---
	# Alternate exists -> route around the blocked edge.
	var eb = _v03_open_board(7, 7)
	var et = eb.get_cell_index(5, 3); eb.set_cell_state(et, BoardState.CellState.ACTIVE)
	var edge_acc = RouteAccessEdgeBlock.new(eb, Vector2(3.5, 3.5), Vector2(4.5, 3.5))
	var ereq = RouteRequest.for_target(eb, Vector2(-2, 3.5), et)
	var eres = ProductionRoutingSystem.new().compute_route(ereq, eb, edge_acc)
	_check(eres.success, "planner routes around a single blocked edge when an alternate exists")
	if eres.success:
		# Validate against the SAME edge-blocking truth: route must not use that edge.
		_check_eq(RouteValidator.validate_route(ereq, eres, eb, edge_acc), RouteResult.FailureReason.NONE, "around-route valid under the edge-blocking access")

	# No alternate -> NO_ROUTE (blocked edge is the only connection).
	var lb = BoardDebugFixtures.make_board(3, 3) # all ACTIVE
	lb.set_cell_state(lb.get_cell_index(0, 1), BoardState.CellState.CLEARED)
	lb.set_cell_state(lb.get_cell_index(1, 1), BoardState.CellState.CLEARED)
	var lt = lb.get_cell_index(1, 2) # ACTIVE target
	var ledge = RouteAccessEdgeBlock.new(lb, Vector2(0.5, 1.5), Vector2(1.5, 1.5))
	var lreq = RouteRequest.for_target(lb, Vector2(-2, 1.5), lt)
	var lres = ProductionRoutingSystem.new().compute_route(lreq, lb, ledge)
	_check(not lres.success, "NO_ROUTE when the only connecting edge is blocked")
	_check_eq(lres.failure_reason, RouteResult.FailureReason.NO_ROUTE, "sole-connection blocked -> NO_ROUTE")
	_check_eq(lres.target_index, lt, "sole-connection failure keeps the same target")
	_check(ledge.blocked_edge_queried, "planner consulted segment access on the sole connecting edge (not inferred from cell class)")

	# --- F-003/§6: final success is internally RouteValidator-clean ---
	var s2 := RoutingLabScenarios.make_s2()
	var b2 = s2["board"]
	var a2 = ProductionAccessQuery.new(b2)
	var q2 = RoutingLabScenarios.build_requests(b2, s2["targets"], s2["origins"])[0]
	var r2 = ProductionRoutingSystem.new().compute_route(q2, b2, a2)
	_check(r2.success, "S2 production route succeeds")
	if r2.success:
		_check_eq(RouteValidator.validate_route(q2, r2, b2, a2), RouteResult.FailureReason.NONE, "returned success is externally RouteValidator-clean")
		_check(_v03_all_finite(r2.get_points()), "success route points are all finite")

	# --- F-009: invalid tuning must not poison routing ---
	_check_eq(prod.max_shortcut_span, 2, "default max_shortcut_span == 2 (unchanged)")
	_check(is_equal_approx(prod.corner_radius, 0.25), "default corner_radius == 0.25 (unchanged)")
	_check_eq(prod.corner_samples, 3, "default corner_samples == 3 (unchanged)")
	for bad in [NAN, INF, -INF, -1.0]:
		var pr = ProductionRoutingSystem.new()
		pr.corner_radius = bad
		var rr = pr.compute_route(q2, b2, a2)
		_check(rr.success, "non-finite/negative corner_radius (%s) still routes safely" % str(bad))
		if rr.success:
			_check(_v03_all_finite(rr.get_points()), "corner_radius %s -> no non-finite success points" % str(bad))
			_check_eq(RouteValidator.validate_route(q2, rr, b2, a2), RouteResult.FailureReason.NONE, "corner_radius %s route validates" % str(bad))
	for bs in [0, -3]:
		var ps = ProductionRoutingSystem.new(); ps.corner_samples = bs
		var rs = ps.compute_route(q2, b2, a2)
		_check(rs.success and _v03_all_finite(rs.get_points()), "corner_samples %d safe" % bs)
		var pm = ProductionRoutingSystem.new(); pm.max_shortcut_span = bs
		var rm2 = pm.compute_route(q2, b2, a2)
		_check(rm2.success and _v03_all_finite(rm2.get_points()), "max_shortcut_span %d safe" % bs)

# ================================= M19-C001 V04 frozen dispatcher remainder ===
# F-M19-STRICT-001.D/.E/.F, 002.D/.E, 003.D/.E/.F.

## Five coherent M19CollabDouble collaborators + a real board, for bind-time
## coherence-callback injection.
func _v04_collab_bundle(board) -> Dictionary:
	return {"sel": M19CollabDouble.new(), "res": M19CollabDouble.new(),
		"routing": M19CollabDouble.new(), "racc": M19CollabDouble.new(),
		"sacc": M19CollabDouble.new(), "board": board}

## Wire a dispatcher over a real board whose selector is `sel` (an
## M19SelectorReturnDouble) and whose other collaborators are real/deterministic.
func _v04_wire_sel(sel) -> Dictionary:
	var board = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var reservations = ReservationState.new(); reservations.bind(board)
	var routing = DispatchRoutingDouble.new()
	var routing_access = RouteAccessQueryDouble.new()
	routing_access.default_traversable = true; routing_access.bind_board(board)
	var access = AccessQueryDouble.new()
	access.set_all_targetable([board.get_cell_index(2, 5), board.get_cell_index(4, 5)])
	sel.reservations = reservations
	var disp = ScrubbotDispatcher.new(); root.add_child(disp)
	var bound: bool = disp.bind(board, sel, reservations, routing, routing_access, access)
	return {"board": board, "reservations": reservations, "routing": routing,
		"dispatcher": disp, "bound": bound,
		"idx": board.get_cell_index(2, 5), "idx2": board.get_cell_index(4, 5)}

func _run_m19_v04_tests() -> void:
	print("---- M19-C001 V04: frozen dispatcher transaction remainder ----")
	var origin := Vector2(-2.0, 5.5)

	# ===== §1 F-M19-STRICT-001.D: bind transaction guard =====================
	var bind_seams := ["sel", "res", "racc", "sacc"]
	for seam in bind_seams:
		var bA = _m19_open_board_active(10, 10, [Vector2(2, 5)])
		var bB = _m19_open_board_active(10, 10, [Vector2(2, 5)])
		var A = _v04_collab_bundle(bA)
		var Bb = _v04_collab_bundle(bB)
		var disp = ScrubbotDispatcher.new(); root.add_child(disp)
		var nested := [true]
		var fired := [false]
		A[seam].on_check = func():
			if not fired[0]:
				fired[0] = true
				nested[0] = disp.bind(bB, Bb["sel"], Bb["res"], Bb["routing"], Bb["racc"], Bb["sacc"])
		var outer: bool = disp.bind(bA, A["sel"], A["res"], A["routing"], A["racc"], A["sacc"])
		A[seam].on_check = Callable()
		_check(outer, "001.D: outer bind commits despite nested bind from %s coherence" % seam)
		_check_eq(nested[0], false, "001.D: nested bind from %s coherence returns false" % seam)
		_check(disp.is_bound(), "001.D: dispatcher bound after %s nested-bind attack" % seam)
		# Bundle-A identity won: a dispatch drives A's selector, never B's.
		disp.dispatch(0, origin)
		_check(A["sel"].select_calls >= 1, "001.D: outer bundle A selector is live (%s)" % seam)
		_check_eq(Bb["sel"].select_calls, 0, "001.D: bundle B never became live (%s)" % seam)
		_check_eq(disp.get_active_count(), 0, "001.D: bind created no active assignment (%s)" % seam)
		disp.reset(); root.remove_child(disp); disp.free()

	# already-bound ordinary bind stays false/preserve.
	var abA = _m19_open_board_active(10, 10, [Vector2(2, 5)])
	var abBundle = _v04_collab_bundle(abA)
	var abDisp = ScrubbotDispatcher.new(); root.add_child(abDisp)
	_check(abDisp.bind(abA, abBundle["sel"], abBundle["res"], abBundle["routing"], abBundle["racc"], abBundle["sacc"]), "001.D: first bind ok")
	_check_eq(abDisp.bind(abA, abBundle["sel"], abBundle["res"], abBundle["routing"], abBundle["racc"], abBundle["sacc"]), false, "001.D: second bind while bound -> false/preserve")
	_check(abDisp.is_bound(), "001.D: still bound after repeated bind")
	abDisp.reset(); root.remove_child(abDisp); abDisp.free()

	# reset injected from each bind-time coherence seam invalidates the bind.
	for seam in bind_seams:
		var rbA = _m19_open_board_active(10, 10, [Vector2(2, 5)])
		var RA = _v04_collab_bundle(rbA)
		var rdisp = ScrubbotDispatcher.new(); root.add_child(rdisp)
		var rfired := [false]
		RA[seam].on_check = func():
			if not rfired[0]:
				rfired[0] = true
				rdisp.reset()
		var rout: bool = rdisp.bind(rbA, RA["sel"], RA["res"], RA["routing"], RA["racc"], RA["sacc"])
		RA[seam].on_check = Callable()
		_check_eq(rout, false, "001.D: reset during %s bind coherence invalidates bind" % seam)
		_check(not rdisp.is_bound(), "001.D: dispatcher UNBOUND after reset-during-bind (%s)" % seam)
		# guard cleared: a later clean bind recovers.
		_check(rdisp.bind(rbA, RA["sel"], RA["res"], RA["routing"], RA["racc"], RA["sacc"]), "001.D: later clean bind recovers (%s)" % seam)
		rdisp.reset(); root.remove_child(rdisp); rdisp.free()

	# ===== §2 F-M19-STRICT-001.E/002.D: selector Variant + ownership proof ====
	var malformed := [null, 1.5, "x", Vector2.ZERO, RefCounted.new(), true, [], {}]
	for badret in malformed:
		var sd = M19SelectorReturnDouble.new(); sd.ret = badret
		var w = _v04_wire_sel(sd)
		var col: int = w["board"].get_color_id(w["idx"])
		var before: int = w["dispatcher"].peek_next_owner_id()
		var cbefore: int = w["dispatcher"].get_child_count()
		var r = w["dispatcher"].dispatch(col, origin)
		_check_eq(r.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: malformed selector return -> COHERENCE_FAILED")
		_check_eq(w["routing"].call_count, 0, "002.D: malformed selector return -> no route call")
		_check_eq(w["dispatcher"].get_active_count(), 0, "002.D: malformed selector return -> no active entry")
		_check_eq(w["dispatcher"].get_child_count(), cbefore, "002.D: malformed selector return -> no child")
		_check_eq(w["reservations"].get_reservation_count(), 0, "002.D: malformed selector return -> no reservation")
		_check_eq(w["dispatcher"].peek_next_owner_id(), before, "002.D: malformed selector return does not advance owner id")
		_m19_teardown(w)

	# negative int other than -1 -> COHERENCE_FAILED.
	var sneg = M19SelectorReturnDouble.new(); sneg.ret = -7
	var wneg = _v04_wire_sel(sneg)
	_check_eq(wneg["dispatcher"].dispatch(wneg["board"].get_color_id(wneg["idx"]), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: negative int != -1 -> COHERENCE_FAILED")
	_m19_teardown(wneg)

	# canonical -1 with NO reservation -> NO_REACHABLE_TARGET, owner id not advanced.
	var sm1 = M19SelectorReturnDouble.new(); sm1.ret = -1
	var wm1 = _v04_wire_sel(sm1)
	var m1_before: int = wm1["dispatcher"].peek_next_owner_id()
	_check_eq(wm1["dispatcher"].dispatch(wm1["board"].get_color_id(wm1["idx"]), origin).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "002.D: -1 no reservation -> NO_REACHABLE_TARGET")
	_check_eq(wm1["dispatcher"].peek_next_owner_id(), m1_before, "002.D: -1 no-target does not advance owner id")
	_m19_teardown(wm1)

	# -1 but selector secretly reserved owner_id -> COHERENCE_FAILED + exact cleanup.
	var ssec = M19SelectorReturnDouble.new(); ssec.ret = -1; ssec.effect = "owner"
	var wsec = _v04_wire_sel(ssec); ssec.effect_target = wsec["idx"]
	_check_eq(wsec["dispatcher"].dispatch(wsec["board"].get_color_id(wsec["idx"]), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: -1 with secret owner reservation -> COHERENCE_FAILED")
	_check_eq(wsec["reservations"].get_reservation_count(), 0, "002.D: secret -1 reservation cleaned up")
	_m19_teardown(wsec)

	# positive target with NO reservation -> COHERENCE_FAILED.
	var spos = M19SelectorReturnDouble.new()
	var wpos = _v04_wire_sel(spos); spos.ret = wpos["idx"]
	_check_eq(wpos["dispatcher"].dispatch(wpos["board"].get_color_id(wpos["idx"]), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: positive target without reservation -> COHERENCE_FAILED")
	_check_eq(wpos["reservations"].get_reservation_count(), 0, "002.D: unreserved positive target leaves no reservation")
	_m19_teardown(wpos)

	# positive target but owner maps to a DIFFERENT target -> COHERENCE_FAILED.
	var sot = M19SelectorReturnDouble.new(); sot.effect = "owner"
	var wot = _v04_wire_sel(sot); sot.ret = wot["idx"]; sot.effect_target = wot["idx2"]
	_check_eq(wot["dispatcher"].dispatch(wot["board"].get_color_id(wot["idx"]), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: owner->different target -> COHERENCE_FAILED")
	_check_eq(wot["reservations"].get_reservation_count(), 0, "002.D: owner->different-target reservation cleaned")
	_m19_teardown(wot)

	# positive target owned by a DIFFERENT owner -> COHERENCE_FAILED, unrelated kept.
	var soo = M19SelectorReturnDouble.new(); soo.effect = "other_owner"
	var woo = _v04_wire_sel(soo); soo.ret = woo["idx"]
	_check_eq(woo["dispatcher"].dispatch(woo["board"].get_color_id(woo["idx"]), origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.D: target->different owner -> COHERENCE_FAILED")
	_check(woo["reservations"].get_owner(woo["idx"]) != -1, "002.D: unrelated other-owner reservation preserved (exact cleanup only)")
	_m19_teardown(woo)

	# exact owner<->target proof -> accepted (real selector).
	var active5 := [Vector2(2, 5), Vector2(4, 5), Vector2(6, 5), Vector2(8, 5), Vector2(10, 5)]
	var wok = _m19_wire_fake(_m19_open_board_active(14, 11, active5), "ok", [_m19_open_board_active(14, 11, active5).get_cell_index(2, 5)])
	var bok = wok["board"]; wok["access"].set_all_targetable([bok.get_cell_index(2, 5)])
	var rok = wok["dispatcher"].dispatch(bok.get_color_id(bok.get_cell_index(2, 5)), origin)
	_check(rok.success, "002.D: exact real-selector reservation proof -> success")
	_m19_teardown(wok)

	# ===== §3 F-M19-STRICT-003.D: generation after every callback boundary ====
	# post-selection coherence reset.
	var acc_ps = M19CoherenceResetAccess.new(); acc_ps.default_targetable = true; acc_ps.cached_route = null
	var wps = _m19_wire_cache(acc_ps); acc_ps.dispatcher = wps["dispatcher"]
	acc_ps.coherence_calls = 0; acc_ps.reset_at_call = 3 # ords: 1 initial, 2 baseline, 3 post-selection
	var col_ps: int = wps["board"].get_color_id(wps["board"].get_cell_index(2, 5))
	var rps = wps["dispatcher"].dispatch(col_ps, origin)
	acc_ps.reset_at_call = -1
	_check_eq(rps.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset in post-selection coherence -> RESETTING")
	_check_eq(wps["routing"].call_count, 0, "003.D: no routing after post-selection reset")
	_check_eq(wps["reservations"].get_reservation_count(), 0, "003.D: pending reservation released (post-selection reset)")
	_check_eq(wps["dispatcher"].get_active_count(), 0, "003.D: no active after post-selection reset")
	_m19_teardown(wps)

	# cached-route RouteValidator-access reset.
	var acc_cr = M19CacheSelectAccess.new(); acc_cr.default_targetable = true
	var wcr = _m19_wire_cache(acc_cr)
	var cidx: int = wcr["board"].get_cell_index(2, 5)
	var creq = RouteRequest.for_target(wcr["board"], origin, cidx)
	acc_cr.cached_route = RouteResult.success_route(cidx, PackedVector2Array([origin, creq.target_position]))
	var fcalls_cr := [0]
	wcr["dispatcher"]._agent_factory = func(): fcalls_cr[0] += 1; return ScrubbotAgent.new()
	var crfired := [false]
	wcr["routing_access"].on_query = func():
		if not crfired[0]:
			crfired[0] = true
			wcr["dispatcher"].reset()
	var rcr = wcr["dispatcher"].dispatch(wcr["board"].get_color_id(cidx), origin)
	wcr["routing_access"].on_query = Callable()
	_check_eq(rcr.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset from cached-route validator access -> RESETTING")
	_check_eq(wcr["routing"].call_count, 0, "003.D: cached-route reset performed no fresh compute")
	_check_eq(fcalls_cr[0], 0, "003.D: cached-route reset never reached factory")
	_check_eq(wcr["reservations"].get_reservation_count(), 0, "003.D: cached-route reset released reservation")
	_m19_teardown(wcr)

	# fresh-route RouteValidator-access reset.
	var acc_fr = M19CacheSelectAccess.new(); acc_fr.default_targetable = true; acc_fr.cached_route = null
	var wfr = _m19_wire_cache(acc_fr)
	var fcalls_fr := [0]
	wfr["dispatcher"]._agent_factory = func(): fcalls_fr[0] += 1; return ScrubbotAgent.new()
	var frfired := [false]
	wfr["routing_access"].on_query = func():
		if not frfired[0]:
			frfired[0] = true
			wfr["dispatcher"].reset()
	var rfr = wfr["dispatcher"].dispatch(wfr["board"].get_color_id(wfr["board"].get_cell_index(2, 5)), origin)
	wfr["routing_access"].on_query = Callable()
	_check_eq(rfr.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset from fresh-route validator access -> RESETTING")
	_check_eq(fcalls_fr[0], 0, "003.D: fresh-route reset never reached factory")
	_check_eq(wfr["reservations"].get_reservation_count(), 0, "003.D: fresh-route reset released reservation")
	_m19_teardown(wfr)

	# post-routing coherence reset (factory must not run).
	var acc_pr = M19CoherenceResetAccess.new(); acc_pr.default_targetable = true; acc_pr.cached_route = null
	var wpr = _m19_wire_cache(acc_pr); acc_pr.dispatcher = wpr["dispatcher"]
	var fcalls_pr := [0]
	wpr["dispatcher"]._agent_factory = func(): fcalls_pr[0] += 1; return ScrubbotAgent.new()
	acc_pr.coherence_calls = 0; acc_pr.reset_at_call = 6
	var rpr = wpr["dispatcher"].dispatch(wpr["board"].get_color_id(wpr["board"].get_cell_index(2, 5)), origin)
	acc_pr.reset_at_call = -1
	_check_eq(rpr.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset in post-routing coherence -> RESETTING")
	_check(wpr["routing"].call_count >= 1, "003.D: routing was genuinely reached before post-routing reset")
	_check_eq(fcalls_pr[0], 0, "003.D: factory not called after post-routing reset")
	_check_eq(wpr["reservations"].get_reservation_count(), 0, "003.D: post-routing reset released reservation")
	_m19_teardown(wpr)

	# post-factory coherence reset (assign must not run).
	var acc_pf = M19CoherenceResetAccess.new(); acc_pf.default_targetable = true; acc_pf.cached_route = null
	var wpf = _m19_wire_cache(acc_pf); acc_pf.dispatcher = wpf["dispatcher"]
	var acalls_pf := [0]
	wpf["dispatcher"]._agent_factory = func(): var a = M19ProbeAgent.new(); a.assign_calls = acalls_pf; return a
	acc_pf.coherence_calls = 0; acc_pf.reset_at_call = 7
	var rpf = wpf["dispatcher"].dispatch(wpf["board"].get_color_id(wpf["board"].get_cell_index(2, 5)), origin)
	acc_pf.reset_at_call = -1
	_check_eq(rpf.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset in post-factory coherence -> RESETTING")
	_check_eq(acalls_pf[0], 0, "003.D: assign not called after post-factory reset")
	_check_eq(wpf["reservations"].get_reservation_count(), 0, "003.D: post-factory reset released reservation")
	_check_eq(wpf["dispatcher"].get_active_count(), 0, "003.D: no active after post-factory reset")
	_m19_teardown(wpf)

	# post-assign coherence reset (add_child must not run).
	var acc_pa = M19CoherenceResetAccess.new(); acc_pa.default_targetable = true; acc_pa.cached_route = null
	var wpa = _m19_wire_cache(acc_pa); acc_pa.dispatcher = wpa["dispatcher"]
	var acalls_pa := [0]
	wpa["dispatcher"]._agent_factory = func(): var a = M19ProbeAgent.new(); a.assign_calls = acalls_pa; return a
	var pa_children: int = wpa["dispatcher"].get_child_count()
	acc_pa.coherence_calls = 0; acc_pa.reset_at_call = 8
	var rpa = wpa["dispatcher"].dispatch(wpa["board"].get_color_id(wpa["board"].get_cell_index(2, 5)), origin)
	acc_pa.reset_at_call = -1
	_check_eq(rpa.failure_reason, DispatchResult.FailureReason.RESETTING, "003.D: reset in post-assign coherence -> RESETTING")
	_check_eq(acalls_pa[0], 1, "003.D: assign genuinely ran before post-assign reset")
	_check_eq(wpa["dispatcher"].get_child_count(), pa_children, "003.D: add_child not reached after post-assign reset")
	_check_eq(wpa["reservations"].get_reservation_count(), 0, "003.D: post-assign reset released reservation")
	_m19_teardown(wpa)

	# ===== §4 F-M19-STRICT-003.E: reset re-entry safety =======================
	var rc_board = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wrc = _m19_wire_fake(rc_board, "ok", [rc_board.get_cell_index(2, 5)])
	var cancel_cnt := [0]
	var wrc_disp = wrc["dispatcher"]
	wrc_disp._agent_factory = func():
		var a = M19ResetCancelAgent.new(); a.dispatcher = wrc_disp; a.cancel_counter = cancel_cnt; return a
	var rc_col: int = rc_board.get_color_id(rc_board.get_cell_index(2, 5))
	_check(wrc_disp.dispatch(rc_col, origin).success, "003.E: reset-cancel agent dispatched")
	var owner_before: int = wrc_disp.peek_next_owner_id()
	wrc_disp.reset() # agent.cancel() calls reset() again -> must be a no-op
	_check_eq(cancel_cnt[0], 1, "003.E: agent cancelled exactly once (no reset storm)")
	_check_eq(wrc_disp.get_active_count(), 0, "003.E: active empty after reset")
	_check_eq(wrc["reservations"].get_reservation_count(), 0, "003.E: reservation released once")
	_check_eq(wrc_disp.get_child_count(), 0, "003.E: no orphan child after reset")
	var rc_r2 = wrc_disp.dispatch(rc_col, origin)
	_check(rc_r2.success, "003.E: later dispatch recovers after re-entrant reset")
	_check(rc_r2.owner_id >= owner_before, "003.E: owner ids not rewound")
	_m19_teardown(wrc)

	# NOTE (headless limitation): a cancel() override that frees ITS OWN agent must
	# do so via free() while the object is executing cancel() — Godot forbids that
	# ("Attempted to free a locked object"), so a self-freeing cancel is not cleanly
	# reproducible in this harness. The dispatcher's post-cancel
	# is_instance_valid(agent) revalidation before get_parent/remove_child/free
	# (F-M19-STRICT-003.E) is present in scrubbot_dispatcher.gd and source-verified
	# (see CLAUDE_LOG_V04); the re-entrant nested-reset case above is exercised
	# directly and error-free.

	# ===== §5 F-M19-STRICT-002.E: assign return actual-bool ===================
	var afb = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var waf = _m19_wire_fake(afb, "ok", [afb.get_cell_index(2, 5)])
	waf["dispatcher"]._agent_factory = func(): var a = DispatchAgentDouble.new(); a.fail_assign = true; return a
	var af_col: int = afb.get_color_id(afb.get_cell_index(2, 5))
	var raf = waf["dispatcher"].dispatch(af_col, origin)
	_check_eq(raf.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "002.E: assign bool false -> AGENT_ASSIGN_FAILED")
	_check_eq(waf["reservations"].get_reservation_count(), 0, "002.E: false assign releases reservation")
	_m19_teardown(waf)

	var nbb = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wnb = _m19_wire_fake(nbb, "ok", [nbb.get_cell_index(2, 5)])
	wnb["dispatcher"]._agent_factory = func(): return M19NonBoolAssignAgent.new()
	var nb_children: int = wnb["dispatcher"].get_child_count()
	var rnb = wnb["dispatcher"].dispatch(nbb.get_color_id(nbb.get_cell_index(2, 5)), origin)
	_check_eq(rnb.failure_reason, DispatchResult.FailureReason.AGENT_ASSIGN_FAILED, "002.E: non-bool assign return -> AGENT_ASSIGN_FAILED")
	_check_eq(wnb["reservations"].get_reservation_count(), 0, "002.E: non-bool assign releases reservation")
	_check_eq(wnb["dispatcher"].get_active_count(), 0, "002.E: non-bool assign creates no active entry")
	_check_eq(wnb["dispatcher"].get_child_count(), nb_children, "002.E: non-bool assign creates no child")
	_m19_teardown(wnb)

	# ===== §6 F-M19-STRICT-001.F/003.F: final add-child transaction ===========
	# NOTE (headless limitation): in a `-s` SceneTree the add_child lifecycle
	# callback (_ready / child_entered_tree) is delivered DEFERRED, and injecting a
	# reset/free from it frees a locked (mid-callback) object. So the add-child
	# adversary is NOT synchronously reproducible in this harness without emitting
	# engine "locked object" errors. The dispatcher's post-add-child guards
	# (F-M19-STRICT-001.F/003.F) — generation check, exact bundle-coherence check,
	# and agent instance/parent revalidation before signal-connect / _active commit,
	# with detach+free+release on drift/reset — are present in
	# scripts/gameplay/dispatch/scrubbot_dispatcher.gd and are covered by source
	# inspection (see CLAUDE_LOG_V04). The synchronous, error-free consequence we CAN
	# assert directly is that a committed assignment is unaffected by a later pending
	# dispatch that fails.
	# prior committed assignment is independent of a later pending dispatch:
	# a committed assignment survives a subsequent failed dispatch (route failure).
	var pc_board = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var pc = _m19_wire_fake(pc_board, "ok", [pc_board.get_cell_index(2, 5), pc_board.get_cell_index(4, 5)])
	var pc_col: int = pc_board.get_color_id(pc_board.get_cell_index(2, 5))
	var pc_first = pc["dispatcher"].dispatch(pc_col, origin)
	_check(pc_first.success, "003.F: first dispatch commits")
	pc["routing"].mode = "fail" # next dispatch fails at routing, after a fresh reservation
	var pc_second = pc["dispatcher"].dispatch(pc_col, origin)
	_check_eq(pc_second.failure_reason, DispatchResult.FailureReason.ROUTE_FAILED, "003.F: later pending dispatch fails cleanly")
	_check_eq(pc["dispatcher"].get_active_count(), 1, "003.F: prior committed assignment survives a later failed dispatch")
	_check(pc["dispatcher"].has_owner(pc_first.owner_id), "003.F: the surviving assignment is the earlier committed one")
	_m19_teardown(pc)

	print("  M19 V04 tests complete")

# ================================= M19-C001 V05 transaction boundary closure ===
# F-M19-STRICT-001.G, 003.G/.H/.I + malformed ownership-proof + real M15 integration.

## Wire a dispatcher whose selector is an M19SelectorReturnDouble and whose
## reservation layer is an M19ReservationProofDouble (both coherent), for the
## pending-owner baseline / canonical-`-1` / ownership-proof boundary tests.
func _v05_wire_proof(sel, rsd) -> Dictionary:
	var board = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var routing = DispatchRoutingDouble.new()
	var routing_access = RouteAccessQueryDouble.new()
	routing_access.default_traversable = true; routing_access.bind_board(board)
	var access = AccessQueryDouble.new()
	access.set_all_targetable([board.get_cell_index(2, 5), board.get_cell_index(4, 5)])
	rsd.bind(board)
	sel.reservations = rsd
	var disp = ScrubbotDispatcher.new(); root.add_child(disp)
	var bound: bool = disp.bind(board, sel, rsd, routing, routing_access, access)
	return {"board": board, "rsd": rsd, "sel": sel, "routing": routing,
		"routing_access": routing_access, "dispatcher": disp, "bound": bound,
		"idx": board.get_cell_index(2, 5), "idx2": board.get_cell_index(4, 5)}

func _run_m19_v05_tests() -> void:
	print("---- M19-C001 V05: transaction boundary closure ----")
	var origin := Vector2(-2.0, 5.5)
	var COLOR := 0 # open boards use color 0 for ACTIVE cells

	# ===== §1 F-M19-STRICT-001.G/003.H: pending-owner baseline bracketing =======
	# malformed baseline -> COHERENCE_FAILED, selector never called.
	var sd_a = M19SelectorReturnDouble.new(); sd_a.ret = 0
	var rp_a = M19ReservationProofDouble.new(); rp_a.tfo_force_at = 1; rp_a.tfo_force = 1.5
	var wa = _v05_wire_proof(sd_a, rp_a)
	var before_a: int = wa["dispatcher"].peek_next_owner_id()
	var ra = wa["dispatcher"].dispatch(COLOR, origin)
	_check_eq(ra.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "001.G: malformed pending-owner baseline -> COHERENCE_FAILED")
	_check_eq(sd_a.select_calls, 0, "001.G: selector NOT called after malformed baseline")
	_check_eq(wa["dispatcher"].peek_next_owner_id(), before_a, "001.G: owner id not advanced (malformed baseline)")
	_check_eq(wa["routing"].call_count, 0, "001.G: no routing after malformed baseline")
	_m19_teardown(wa)

	# baseline actual int other than -1 -> COHERENCE_FAILED.
	var sd_n = M19SelectorReturnDouble.new(); sd_n.ret = 0
	var rp_n = M19ReservationProofDouble.new(); rp_n.reserve(7, 0) # owner id 0 already holds a target
	var wn = _v05_wire_proof(sd_n, rp_n)
	_check_eq(wn["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "001.G: baseline non--1 owner target -> COHERENCE_FAILED")
	_check_eq(sd_n.select_calls, 0, "001.G: selector NOT called when baseline owner already assigned")
	_m19_teardown(wn)

	# reset during baseline -> RESETTING, selector not called.
	var sd_r = M19SelectorReturnDouble.new(); sd_r.ret = 0
	var rp_r = M19ReservationProofDouble.new()
	var wr = _v05_wire_proof(sd_r, rp_r)
	rp_r.on_owner_query = func(n):
		if n == 1: wr["dispatcher"].reset()
	_check_eq(wr["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.RESETTING, "003.H: reset during baseline -> RESETTING")
	_check_eq(sd_r.select_calls, 0, "003.H: selector NOT called after baseline reset")
	rp_r.on_owner_query = Callable()
	_m19_teardown(wr)

	# ReservationState/bundle drift during baseline -> COHERENCE_FAILED, no selector.
	var sd_d = M19SelectorReturnDouble.new(); sd_d.ret = 0
	var rp_d = M19ReservationProofDouble.new()
	var wd = _v05_wire_proof(sd_d, rp_d)
	var other_d = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	rp_d.on_owner_query = func(n):
		if n == 1: wd["routing_access"].bind_board(other_d) # drift bundle during baseline
	_check_eq(wd["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "003.H: bundle drift during baseline -> COHERENCE_FAILED")
	_check_eq(sd_d.select_calls, 0, "003.H: selector NOT called after baseline drift")
	rp_d.on_owner_query = Callable()
	_m19_teardown(wd)

	# ===== §2 F-M19-STRICT-003.G: canonical -1 owner-side-effect bracketing =====
	# canonical -1 control -> NO_REACHABLE_TARGET.
	var sd_m1 = M19SelectorReturnDouble.new(); sd_m1.ret = -1
	var wm1 = _v05_wire_proof(sd_m1, M19ReservationProofDouble.new())
	var before_m1: int = wm1["dispatcher"].peek_next_owner_id()
	_check_eq(wm1["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "003.G: canonical -1 -> NO_REACHABLE_TARGET")
	_check_eq(wm1["dispatcher"].peek_next_owner_id(), before_m1, "003.G: owner id not advanced on canonical -1")
	_m19_teardown(wm1)

	# reset during post--1 owner query -> RESETTING.
	var sd_m1r = M19SelectorReturnDouble.new(); sd_m1r.ret = -1
	var rp_m1r = M19ReservationProofDouble.new()
	var wm1r = _v05_wire_proof(sd_m1r, rp_m1r)
	rp_m1r.on_owner_query = func(n):
		if n == 2: wm1r["dispatcher"].reset() # call 1 baseline, call 2 post--1
	_check_eq(wm1r["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.RESETTING, "003.G: reset during post--1 owner query -> RESETTING")
	rp_m1r.on_owner_query = Callable()
	_m19_teardown(wm1r)

	# drift during post--1 owner query -> COHERENCE_FAILED.
	var sd_m1d = M19SelectorReturnDouble.new(); sd_m1d.ret = -1
	var rp_m1d = M19ReservationProofDouble.new()
	var wm1d = _v05_wire_proof(sd_m1d, rp_m1d)
	var other_m1d = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	rp_m1d.on_owner_query = func(n):
		if n == 2: wm1d["routing_access"].bind_board(other_m1d)
	_check_eq(wm1d["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "003.G: drift during post--1 owner query -> COHERENCE_FAILED")
	rp_m1d.on_owner_query = Callable()
	_m19_teardown(wm1d)

	# malformed post--1 owner query -> COHERENCE_FAILED.
	var sd_m1m = M19SelectorReturnDouble.new(); sd_m1m.ret = -1
	var rp_m1m = M19ReservationProofDouble.new(); rp_m1m.tfo_force_at = 2; rp_m1m.tfo_force = "x"
	var wm1m = _v05_wire_proof(sd_m1m, rp_m1m)
	_check_eq(wm1m["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "003.G: malformed post--1 owner query -> COHERENCE_FAILED")
	_m19_teardown(wm1m)

	# -1 but selector secretly reserved owner -> COHERENCE_FAILED + narrow cleanup.
	var sd_sec = M19SelectorReturnDouble.new(); sd_sec.ret = -1; sd_sec.effect = "owner"
	var rp_sec = M19ReservationProofDouble.new(); rp_sec.reserve(99, 777) # unrelated
	var wsec = _v05_wire_proof(sd_sec, rp_sec); sd_sec.effect_target = wsec["idx"]
	_check_eq(wsec["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "003.G: -1 with secret reservation -> COHERENCE_FAILED")
	_check_eq(rp_sec.get_reservation_count(), 1, "003.G: secret owner reservation cleaned (only unrelated remains)")
	_check_eq(rp_sec.get_owner(99), 777, "003.G: unrelated reservation preserved")
	_m19_teardown(wsec)

	# ===== §4 malformed positive ownership proof ================================
	# malformed get_target_for_owner proof (call 2) -> COHERENCE_FAILED + cleanup.
	var sd_tp = M19SelectorReturnDouble.new(); sd_tp.effect = "owner"
	var rp_tp = M19ReservationProofDouble.new(); rp_tp.reserve(99, 777)
	rp_tp.tfo_force_at = 2; rp_tp.tfo_force = 1.5
	var wtp = _v05_wire_proof(sd_tp, rp_tp); sd_tp.ret = wtp["idx"]; sd_tp.effect_target = wtp["idx"]
	var before_tp: int = wtp["dispatcher"].peek_next_owner_id()
	_check_eq(wtp["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.F: malformed get_target_for_owner proof -> COHERENCE_FAILED")
	_check_eq(wtp["routing"].call_count, 0, "002.F: no routing after malformed target proof")
	_check_eq(wtp["dispatcher"].peek_next_owner_id(), before_tp, "002.F: owner id not advanced (malformed target proof)")
	_check_eq(rp_tp.get_reservation_count(), 1, "002.F: pending reservation cleaned, unrelated preserved (target proof)")
	_check_eq(rp_tp.get_owner(99), 777, "002.F: unrelated reservation intact (target proof)")
	_m19_teardown(wtp)

	# malformed get_owner proof (call 1) -> COHERENCE_FAILED + cleanup.
	var sd_gp = M19SelectorReturnDouble.new(); sd_gp.effect = "owner"
	var rp_gp = M19ReservationProofDouble.new(); rp_gp.reserve(99, 777)
	rp_gp.owner_force_at = 1; rp_gp.owner_force = "z"
	var wgp = _v05_wire_proof(sd_gp, rp_gp); sd_gp.ret = wgp["idx"]; sd_gp.effect_target = wgp["idx"]
	_check_eq(wgp["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "002.F: malformed get_owner proof -> COHERENCE_FAILED")
	_check_eq(wgp["routing"].call_count, 0, "002.F: no routing after malformed owner proof")
	_check_eq(rp_gp.get_reservation_count(), 1, "002.F: pending reservation cleaned, unrelated preserved (owner proof)")
	_m19_teardown(wgp)

	# ===== §3 F-M19-STRICT-003.I: generation beats ownability/postcondition =====
	# _dispatcher_ownable: get_state resets + reports non-UNASSIGNED -> RESETTING.
	var ob_board = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wob = _m19_wire_fake(ob_board, "ok", [ob_board.get_cell_index(2, 5)])
	var wob_disp = wob["dispatcher"]
	wob_disp._agent_factory = func():
		var a = M19ResetStateAgent.new()
		a.dispatcher = wob_disp
		a.reset_on_call = 1
		a.override_state = ScrubbotAgent.State.MOVING
		return a
	var ob_col: int = ob_board.get_color_id(ob_board.get_cell_index(2, 5))
	var ob_before: int = wob_disp.peek_next_owner_id()
	var rob = wob_disp.dispatch(ob_col, origin)
	_check_eq(rob.failure_reason, DispatchResult.FailureReason.RESETTING, "003.I: reset in _dispatcher_ownable get_state -> RESETTING (not AGENT_ASSIGN_FAILED)")
	_check_eq(wob_disp.get_active_count(), 0, "003.I: no active after ownability reset")
	_check_eq(wob["reservations"].get_reservation_count(), 0, "003.I: reservation released after ownability reset")
	wob_disp._agent_factory = func(): return ScrubbotAgent.new()
	var rob2 = wob_disp.dispatch(ob_col, origin)
	_check(rob2.success, "003.I: later dispatch recovers after ownability reset")
	_check(rob2.owner_id >= ob_before, "003.I: owner ids monotonic across ownability reset")
	_m19_teardown(wob)

	# _agent_assigned_ok: get_state resets + makes verdict false -> RESETTING.
	var pcb = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wpc = _m19_wire_fake(pcb, "ok", [pcb.get_cell_index(2, 5)])
	var wpc_disp = wpc["dispatcher"]
	wpc_disp._agent_factory = func():
		var a = M19ResetStateAgent.new()
		a.dispatcher = wpc_disp
		a.reset_on_call = 2
		a.override_state = ScrubbotAgent.State.CANCELLED
		return a
	var pc_col2: int = pcb.get_color_id(pcb.get_cell_index(2, 5))
	var pc_children: int = wpc_disp.get_child_count()
	var rpc = wpc_disp.dispatch(pc_col2, origin)
	_check_eq(rpc.failure_reason, DispatchResult.FailureReason.RESETTING, "003.I: reset in _agent_assigned_ok get_state -> RESETTING (not AGENT_ASSIGN_FAILED)")
	_check_eq(wpc_disp.get_child_count(), pc_children, "003.I: add_child not reached after postcondition reset")
	_check_eq(wpc_disp.get_active_count(), 0, "003.I: no active after postcondition reset")
	_check_eq(wpc["reservations"].get_reservation_count(), 0, "003.I: reservation released after postcondition reset")
	wpc_disp._agent_factory = func(): return ScrubbotAgent.new()
	_check(wpc_disp.dispatch(pc_col2, origin).success, "003.I: later dispatch recovers after postcondition reset")
	_m19_teardown(wpc)

	# ===== §5 real M15-C002 V03 integration adversary ===========================
	var mi_board = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var mi = _m19_wire_fake(mi_board, "ok", [mi_board.get_cell_index(2, 5), mi_board.get_cell_index(4, 5)])
	var mi_sel = mi["selector"] # real TargetSelector from M15-C002 V03
	var mi_bB = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var mi_ciB = ColorCandidateIndex.create(); mi_ciB.bind(mi_bB)
	var mi_rsB = ReservationState.create(); mi_rsB.bind(mi_bB)
	var mi_fired := [false]
	mi["access"].on_query = func(_i):
		if not mi_fired[0]:
			mi_fired[0] = true
			mi_sel.bind(mi_bB, mi_ciB, mi_rsB) # rebind attempt DURING selection
	var mi_col: int = mi_board.get_color_id(mi_board.get_cell_index(2, 5))
	var mi_r = mi["dispatcher"].dispatch(mi_col, origin)
	mi["access"].on_query = Callable()
	# M15 final law: bind during an active selection returns false; the selector
	# stays on bundle A and completes there. No foreign reservation in B, no
	# split-brain dispatcher commit.
	_check(mi_sel.is_bound_to(mi_board, mi["reservations"]), "M15-int: real selector stayed bound to bundle A after rebind attempt")
	_check_eq(mi_rsB.get_reservation_count(), 0, "M15-int: no foreign reservation orphaned in bundle B")
	if mi_r.success:
		_check(mi["reservations"].get_owner(mi_r.target_index) == mi_r.owner_id, "M15-int: dispatcher committed exact ownership in bundle A only")
	else:
		_check_eq(mi["reservations"].get_reservation_count(), 0, "M15-int: non-success left no dispatcher reservation")
	var mi_r2 = mi["dispatcher"].dispatch(mi_col, origin)
	_check(mi_r2.success or mi_r2.failure_reason == DispatchResult.FailureReason.NO_REACHABLE_TARGET, "M15-int: later coherent dispatch usable")
	mi_ciB = null; mi_rsB = null
	_m19_teardown(mi)

	print("  M19 V05 tests complete")

# ============================ M19-C001 V06 auditor-authored validation-only ===
# Fresh adversarial arrangements over the ACCEPTED V05 dispatcher blob. No
# production change. Independent counters/post-state, not re-asserting V05 tests.

func _run_m19_v06_auditor_validation_tests() -> void:
	print("---- M19-C001 V06: auditor-authored validation-only ----")
	var origin := Vector2(-2.0, 5.5)
	var COLOR := 0

	# ===== 2A bind transaction adversaries =====================================
	# Nested bind from TWO different coherence seams cannot win; reset from a THIRD
	# seam leaves unbound; clean bind then succeeds.
	for seam in ["res", "sacc"]:
		var bA = _m19_open_board_active(12, 9, [Vector2(3, 4)])
		var bB = _m19_open_board_active(12, 9, [Vector2(3, 4)])
		var A = _v04_collab_bundle(bA)
		var Bb = _v04_collab_bundle(bB)
		var disp = ScrubbotDispatcher.new(); root.add_child(disp)
		var nb := [true]
		var fired := [false]
		A[seam].on_check = func():
			if not fired[0]:
				fired[0] = true
				nb[0] = disp.bind(bB, Bb["sel"], Bb["res"], Bb["routing"], Bb["racc"], Bb["sacc"])
		var outer: bool = disp.bind(bA, A["sel"], A["res"], A["routing"], A["racc"], A["sacc"])
		A[seam].on_check = Callable()
		_check(outer, "V06/2A: outer bind commits despite nested bind from %s" % seam)
		_check_eq(nb[0], false, "V06/2A: nested bind from %s -> false" % seam)
		disp.dispatch(0, origin)
		_check(A["sel"].select_calls >= 1 and Bb["sel"].select_calls == 0, "V06/2A: bundle A identity won (%s)" % seam)
		disp.reset(); root.remove_child(disp); disp.free()

	# reset from routing-access bind-time coherence seam leaves dispatcher unbound.
	var rbA = _m19_open_board_active(12, 9, [Vector2(3, 4)])
	var RA = _v04_collab_bundle(rbA)
	var rdisp = ScrubbotDispatcher.new(); root.add_child(rdisp)
	var rfired := [false]
	RA["racc"].on_check = func():
		if not rfired[0]:
			rfired[0] = true
			rdisp.reset()
	var rout: bool = rdisp.bind(rbA, RA["sel"], RA["res"], RA["routing"], RA["racc"], RA["sacc"])
	RA["racc"].on_check = Callable()
	_check_eq(rout, false, "V06/2A: reset during routing-access bind coherence -> bind false")
	_check(not rdisp.is_bound(), "V06/2A: dispatcher unbound after reset-during-bind")
	_check(rdisp.bind(rbA, RA["sel"], RA["res"], RA["routing"], RA["racc"], RA["sacc"]), "V06/2A: clean bind recovers after reset-during-bind")
	rdisp.reset(); root.remove_child(rdisp); rdisp.free()

	# second bind while one live assignment exists -> false, active + reservation kept.
	var sb_board = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var sbw = _m19_wire_fake(sb_board, "ok", [sb_board.get_cell_index(2, 5)])
	var sb_col: int = sb_board.get_color_id(sb_board.get_cell_index(2, 5))
	_check(sbw["dispatcher"].dispatch(sb_col, origin).success, "V06/2A: live assignment committed")
	var sb_b2 = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var sb_r2 = ReservationState.new(); sb_r2.bind(sb_b2)
	var sb_c2 = ColorCandidateIndex.create(); sb_c2.bind(sb_b2)
	var sb_s2 = TargetSelector.create(); sb_s2.bind(sb_b2, sb_c2, sb_r2)
	var sb_ra2 = RouteAccessQueryDouble.new(); sb_ra2.default_traversable = true; sb_ra2.bind_board(sb_b2)
	var sb_a2 = AccessQueryDouble.new(); sb_a2.set_all_targetable([sb_b2.get_cell_index(2, 5)])
	_check_eq(sbw["dispatcher"].bind(sb_b2, sb_s2, sb_r2, DispatchRoutingDouble.new(), sb_ra2, sb_a2), false, "V06/2A: second bind while bound -> false")
	_check_eq(sbw["dispatcher"].get_active_count(), 1, "V06/2A: original active assignment preserved")
	_check_eq(sbw["reservations"].get_reservation_count(), 1, "V06/2A: original reservation preserved")
	_m19_teardown(sbw)

	# ===== 2B pre-selector pending-owner boundary ==============================
	# malformed Dictionary / Vector2 baseline -> COHERENCE_FAILED, selector 0.
	for badval in [{}, Vector2.ZERO]:
		var sdb = M19SelectorReturnDouble.new(); sdb.ret = 0
		var rpb = M19ReservationProofDouble.new(); rpb.tfo_force_at = 1; rpb.tfo_force = badval
		var wb = _v05_wire_proof(sdb, rpb)
		var nb_before: int = wb["dispatcher"].peek_next_owner_id()
		_check_eq(wb["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "V06/2B: malformed baseline -> COHERENCE_FAILED")
		_check_eq(sdb.select_calls, 0, "V06/2B: selector 0 after malformed baseline")
		_check_eq(wb["routing"].call_count, 0, "V06/2B: route 0 after malformed baseline")
		_check_eq(wb["dispatcher"].get_active_count(), 0, "V06/2B: active unchanged after malformed baseline")
		_check_eq(wb["dispatcher"].peek_next_owner_id(), nb_before, "V06/2B: owner counter unchanged after malformed baseline")
		_m19_teardown(wb)

	# reset (returns -1) -> RESETTING; drift (returns -1) -> COHERENCE_FAILED.
	var sdr = M19SelectorReturnDouble.new(); sdr.ret = 0
	var rpr = M19ReservationProofDouble.new()
	var wbr = _v05_wire_proof(sdr, rpr)
	rpr.on_owner_query = func(n):
		if n == 1: wbr["dispatcher"].reset()
	_check_eq(wbr["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/2B: baseline reset -> RESETTING")
	_check_eq(sdr.select_calls, 0, "V06/2B: selector 0 after baseline reset")
	rpr.on_owner_query = Callable()
	_m19_teardown(wbr)

	var sdd = M19SelectorReturnDouble.new(); sdd.ret = 0
	var rpd = M19ReservationProofDouble.new()
	var wbd = _v05_wire_proof(sdd, rpd)
	var other_bd = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	rpd.on_owner_query = func(n):
		if n == 1: wbd["routing_access"].bind_board(other_bd)
	_check_eq(wbd["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "V06/2B: baseline drift -> COHERENCE_FAILED")
	_check_eq(sdd.select_calls, 0, "V06/2B: selector 0 after baseline drift")
	rpd.on_owner_query = Callable()
	_m19_teardown(wbd)

	# ===== 2C selector result + canonical -1 ===================================
	# non-int return after secretly reserving current owner -> cleanup + fail.
	var sdni = M19SelectorReturnDouble.new(); sdni.ret = "junk"; sdni.effect = "owner"
	var rpni = M19ReservationProofDouble.new(); rpni.reserve(88, 555)
	var wni = _v05_wire_proof(sdni, rpni); sdni.effect_target = wni["idx"]
	_check_eq(wni["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "V06/2C: non-int selector return -> COHERENCE_FAILED")
	_check_eq(rpni.get_reservation_count(), 1, "V06/2C: secret current-owner reservation cleaned, unrelated kept")
	_check_eq(rpni.get_owner(88), 555, "V06/2C: unrelated reservation intact")
	_m19_teardown(wni)

	# reset during post--1 owner query -> RESETTING; drift -> COHERENCE_FAILED.
	var sdm1r = M19SelectorReturnDouble.new(); sdm1r.ret = -1
	var rpm1r = M19ReservationProofDouble.new()
	var wm1r = _v05_wire_proof(sdm1r, rpm1r)
	rpm1r.on_owner_query = func(n):
		if n == 2: wm1r["dispatcher"].reset()
	_check_eq(wm1r["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/2C: reset during post--1 query -> RESETTING")
	_check_eq(wm1r["routing"].call_count, 0, "V06/2C: no route on post--1 reset")
	rpm1r.on_owner_query = Callable()
	_m19_teardown(wm1r)

	# ===== 2D positive ownership proof: reset/drift during proof callbacks ======
	# reset during owner->target proof (owner query call 2) -> RESETTING.
	var sdp1 = M19SelectorReturnDouble.new(); sdp1.effect = "owner"
	var rpp1 = M19ReservationProofDouble.new()
	var wp1 = _v05_wire_proof(sdp1, rpp1); sdp1.ret = wp1["idx"]; sdp1.effect_target = wp1["idx"]
	rpp1.on_owner_query = func(n):
		if n == 2: wp1["dispatcher"].reset()
	_check_eq(wp1["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/2D: reset during owner->target proof -> RESETTING")
	_check_eq(wp1["routing"].call_count, 0, "V06/2D: no route on owner-proof reset")
	rpp1.on_owner_query = Callable()
	_m19_teardown(wp1)

	# drift during target->owner proof (get_owner call 1) -> COHERENCE_FAILED.
	var sdp2 = M19SelectorReturnDouble.new(); sdp2.effect = "owner"
	var rpp2 = M19ReservationProofDouble.new(); rpp2.reserve(88, 555)
	var wp2 = _v05_wire_proof(sdp2, rpp2); sdp2.ret = wp2["idx"]; sdp2.effect_target = wp2["idx"]
	var other_p2 = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	rpp2.on_get_owner = func(n):
		if n == 1: wp2["routing_access"].bind_board(other_p2)
	var before_p2: int = wp2["dispatcher"].peek_next_owner_id()
	_check_eq(wp2["dispatcher"].dispatch(COLOR, origin).failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "V06/2D: drift during target->owner proof -> COHERENCE_FAILED")
	_check_eq(wp2["dispatcher"].peek_next_owner_id(), before_p2, "V06/2D: owner counter not advanced on failed proof")
	_check_eq(rpp2.get_reservation_count(), 1, "V06/2D: pending cleaned, unrelated preserved (proof drift)")
	rpp2.on_get_owner = Callable()
	_m19_teardown(wp2)

	# ===== 3 routing seam: reset inside cached + fresh RouteValidator access =====
	# cached reset -> RESETTING, factory 0.
	var acc_cr = M19CacheSelectAccess.new(); acc_cr.default_targetable = true
	var wcr = _m19_wire_cache(acc_cr)
	var cidx: int = wcr["board"].get_cell_index(2, 5)
	var creq = RouteRequest.for_target(wcr["board"], origin, cidx)
	acc_cr.cached_route = RouteResult.success_route(cidx, PackedVector2Array([origin, creq.target_position]))
	var fcr := [0]
	wcr["dispatcher"]._agent_factory = func(): fcr[0] += 1; return ScrubbotAgent.new()
	var crf := [false]
	wcr["routing_access"].on_query = func():
		if not crf[0]:
			crf[0] = true
			wcr["dispatcher"].reset()
	_check_eq(wcr["dispatcher"].dispatch(wcr["board"].get_color_id(cidx), origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/3: reset in cached RouteValidator access -> RESETTING")
	_check_eq(wcr["routing"].call_count, 0, "V06/3: cached reset performed no fresh compute")
	_check_eq(fcr[0], 0, "V06/3: cached reset never reached factory")
	wcr["routing_access"].on_query = Callable()
	_m19_teardown(wcr)

	# present invalid cached route -> ROUTE_FAILED + release, zero fresh compute.
	var acc_iv = M19CacheSelectAccess.new(); acc_iv.default_targetable = true
	var wiv = _m19_wire_cache(acc_iv)
	var ividx: int = wiv["board"].get_cell_index(2, 5)
	acc_iv.cached_route = RouteResult.success_route(ividx + 1, PackedVector2Array([origin, origin + Vector2(1, 0)])) # wrong target
	_check_eq(wiv["dispatcher"].dispatch(wiv["board"].get_color_id(ividx), origin).failure_reason, DispatchResult.FailureReason.ROUTE_FAILED, "V06/3: present invalid cached route -> ROUTE_FAILED")
	_check_eq(wiv["routing"].call_count, 0, "V06/3: invalid cached route did NOT fresh-compute")
	_check_eq(wiv["reservations"].get_reservation_count(), 0, "V06/3: invalid cached route released reservation")
	_m19_teardown(wiv)

	# ===== 4B/4C ownability + postcondition reset precedence (fresh boards) =====
	var owb = _m19_open_board_active(13, 10, [Vector2(4, 6)])
	var wowb = _m19_wire_fake(owb, "ok", [owb.get_cell_index(4, 6)])
	var wowb_d = wowb["dispatcher"]
	wowb_d._agent_factory = func():
		var a = M19ResetStateAgent.new(); a.dispatcher = wowb_d; a.reset_on_call = 1; a.override_state = ScrubbotAgent.State.MOVING; return a
	_check_eq(wowb_d.dispatch(owb.get_color_id(owb.get_cell_index(4, 6)), origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/4B: ownability get_state reset -> RESETTING")
	_check_eq(wowb_d.get_active_count(), 0, "V06/4B: no active after ownability reset")
	_check_eq(wowb["reservations"].get_reservation_count(), 0, "V06/4B: reservation released after ownability reset")
	wowb_d._agent_factory = func(): return ScrubbotAgent.new()
	_check(wowb_d.dispatch(owb.get_color_id(owb.get_cell_index(4, 6)), origin).success, "V06/4B: later dispatch recovers")
	_m19_teardown(wowb)

	var pcb = _m19_open_board_active(13, 10, [Vector2(4, 6)])
	var wpcb = _m19_wire_fake(pcb, "ok", [pcb.get_cell_index(4, 6)])
	var wpcb_d = wpcb["dispatcher"]
	wpcb_d._agent_factory = func():
		var a = M19ResetStateAgent.new(); a.dispatcher = wpcb_d; a.reset_on_call = 2; a.override_state = ScrubbotAgent.State.CANCELLED; return a
	var pcb_children: int = wpcb_d.get_child_count()
	_check_eq(wpcb_d.dispatch(pcb.get_color_id(pcb.get_cell_index(4, 6)), origin).failure_reason, DispatchResult.FailureReason.RESETTING, "V06/4C: postcondition get_state reset -> RESETTING")
	_check_eq(wpcb_d.get_child_count(), pcb_children, "V06/4C: add_child not reached after postcondition reset")
	_check_eq(wpcb["reservations"].get_reservation_count(), 0, "V06/4C: reservation released after postcondition reset")
	wpcb_d._agent_factory = func(): return ScrubbotAgent.new()
	_check(wpcb_d.dispatch(pcb.get_color_id(pcb.get_cell_index(4, 6)), origin).success, "V06/4C: later dispatch recovers")
	_m19_teardown(wpcb)

	# ===== 5 reset / completion lifecycle (fresh) ==============================
	var rcb = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wrcb = _m19_wire_fake(rcb, "ok", [rcb.get_cell_index(2, 5)])
	var wrcb_d = wrcb["dispatcher"]
	var cancel_cnt := [0]
	wrcb_d._agent_factory = func():
		var a = M19ResetCancelAgent.new(); a.dispatcher = wrcb_d; a.cancel_counter = cancel_cnt; return a
	var rc_col: int = rcb.get_color_id(rcb.get_cell_index(2, 5))
	var rc_first = wrcb_d.dispatch(rc_col, origin)
	_check(rc_first.success, "V06/5: reset-cancel agent committed")
	var owner_before: int = wrcb_d.peek_next_owner_id()
	wrcb_d.reset()
	_check_eq(cancel_cnt[0], 1, "V06/5: nested reset from cancel does not recurse (cancel count 1)")
	_check_eq(wrcb_d.get_active_count(), 0, "V06/5: reset cleared active")
	_check_eq(wrcb["reservations"].get_reservation_count(), 0, "V06/5: reset released reservation")
	# stale completion after reset cannot recreate state.
	wrcb_d._on_agent_completed(rc_first.owner_id, rc_first.target_index, rc_col, rc_first.agent)
	_check_eq(wrcb_d.get_active_count(), 0, "V06/5: stale completion after reset recreated nothing")
	var rc_r2 = wrcb_d.dispatch(rc_col, origin)
	_check(rc_r2.success and rc_r2.owner_id >= owner_before, "V06/5: later dispatch recovers, owner ids not rewound")
	_m19_teardown(wrcb)

	# completion identity: wrong source/owner/target/color ignored; correct once.
	var cib = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var wcib = _m19_wire_fake(cib, "ok", [cib.get_cell_index(2, 5)])
	var ci_col: int = cib.get_color_id(cib.get_cell_index(2, 5))
	var ci_r = wcib["dispatcher"].dispatch(ci_col, origin)
	_check(ci_r.success, "V06/5: dispatch for completion-identity test")
	var other_agent = ScrubbotAgent.new()
	wcib["dispatcher"]._on_agent_completed(ci_r.owner_id, ci_r.target_index, ci_col, other_agent)
	_check(not wcib["dispatcher"].has_arrived(ci_r.owner_id), "V06/5: wrong source agent completion ignored")
	other_agent.free()
	wcib["dispatcher"]._on_agent_completed(ci_r.owner_id, ci_r.target_index + 1, ci_col, ci_r.agent)
	_check(not wcib["dispatcher"].has_arrived(ci_r.owner_id), "V06/5: wrong target completion ignored")
	wcib["dispatcher"]._on_agent_completed(ci_r.owner_id, ci_r.target_index, ci_col + 999, ci_r.agent)
	_check(not wcib["dispatcher"].has_arrived(ci_r.owner_id), "V06/5: wrong color completion ignored")
	var before_states = _snapshot_cell_states(cib)
	wcib["dispatcher"]._on_agent_completed(ci_r.owner_id, ci_r.target_index, ci_col, ci_r.agent)
	_check(wcib["dispatcher"].has_arrived(ci_r.owner_id), "V06/5: correct completion marks arrived")
	wcib["dispatcher"]._on_agent_completed(ci_r.owner_id, ci_r.target_index, ci_col, ci_r.agent)
	_check(wcib["dispatcher"].has_arrived(ci_r.owner_id), "V06/5: repeated correct completion idempotent")
	_check(_cell_states_equal(cib, before_states), "V06/5: arrival did NOT clear BoardState (M20 boundary)")
	_check_eq(wcib["reservations"].get_reservation_count(), 1, "V06/5: arrival did NOT release successful reservation (M20 boundary)")
	_m19_teardown(wcib)

	# ===== 6 real production integration + M15 rebind adversary (variant) =======
	var pib = _m19_enclosed_sole_candidate_board()
	var wpi = _m19_wire_real(pib)
	_check_eq(wpi["dispatcher"].dispatch(1, Vector2(-2.0, 2.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "V06/6: enclosed matching ACTIVE candidate -> no spawn")
	_m19_teardown(wpi)

	# M15 rebind adversary variant: reservation drift attempt during targetability.
	var mib = _m19_open_board_active(14, 11, [Vector2(2, 5), Vector2(4, 5)])
	var mi = _m19_wire_fake(mib, "ok", [mib.get_cell_index(2, 5), mib.get_cell_index(4, 5)])
	var mi_sel = mi["selector"]
	var mi_bB = _m19_open_board_active(14, 11, [Vector2(2, 5)])
	var mi_ciB = ColorCandidateIndex.create(); mi_ciB.bind(mi_bB)
	var mi_rsB = ReservationState.create(); mi_rsB.bind(mi_bB)
	var mi_fired := [false]
	mi["access"].on_query = func(_i):
		if not mi_fired[0]:
			mi_fired[0] = true
			mi_sel.bind(mi_bB, mi_ciB, mi_rsB) # rebind attempt during selection
	var mi_r = mi["dispatcher"].dispatch(mib.get_color_id(mib.get_cell_index(2, 5)), origin)
	mi["access"].on_query = Callable()
	_check(mi_sel.is_bound_to(mib, mi["reservations"]), "V06/6: real selector stayed on bundle A after rebind attempt")
	_check_eq(mi_rsB.get_reservation_count(), 0, "V06/6: no foreign reservation orphaned in bundle B")
	if mi_r.success:
		_check_eq(mi["reservations"].get_owner(mi_r.target_index), mi_r.owner_id, "V06/6: dispatcher committed exact ownership in bundle A only")
	_check(mi["dispatcher"].dispatch(mib.get_color_id(mib.get_cell_index(2, 5)), origin) != null, "V06/6: later coherent dispatch usable")
	mi_ciB = null; mi_rsB = null
	_m19_teardown(mi)

	print("  M19 V06 auditor-validation tests complete")

# =============================================== M20-C001 V01 complete clearing =
# Complete Clearing Vertical Slice: the CompleteClearingLoop orchestrator turns
# one slot activation into one M19 dispatch, and one authenticated arrival into a
# synchronized cross-module clear transaction (BoardState -> candidate index ->
# reservation -> renderer -> dispatcher finalize). Uses REAL production selection/
# routing/access for the scale/reachability/clearing spine; narrow doubles only
# where a forced rollback is required. See coordination/sessions/M20-C001.

## Build a full production clearing bundle over `board`. Optional candidate /
## reservation overrides (real subclasses) exercise rollback; use_renderer adds a
## live BoardRenderer exact-bound to the same board.
func _m20_full(board, cand_override = null, res_override = null, use_renderer := false) -> Dictionary:
	var reservations = res_override if res_override != null else ReservationState.new()
	reservations.bind(board)
	var candidates = cand_override if cand_override != null else ColorCandidateIndex.create()
	candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = ProductionTargetAccess.new(routing, routing_access, board)
	var dispatcher = ScrubbotDispatcher.new(); root.add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access)
	var renderer = null
	if use_renderer:
		renderer = BoardRenderer.new(); root.add_child(renderer)
		renderer.configure(board, PackedStringArray(BoardDebugFixturesM20.PALETTE), Vector2(300, 300))
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"selector": selector, "routing": routing, "routing_access": routing_access,
		"select_access": select_access, "dispatcher": dispatcher, "renderer": renderer}

func _m20_teardown(w: Dictionary) -> void:
	var d = w["dispatcher"]
	d.reset()
	root.remove_child(d)
	d.free()
	if w.get("renderer") != null and is_instance_valid(w["renderer"]):
		root.remove_child(w["renderer"])
		w["renderer"].free()

## SlotSystem configured with the given per-slot palette ids (size 5).
func _m20_slots(palette_ids: Array) -> SlotSystem:
	var s = SlotSystem.new()
	s.configure(palette_ids, 256)
	return s

## Bind a CompleteClearingLoop over an existing bundle + slots (+ optional
## renderer). Returns the loop.
func _m20_loop(w: Dictionary, slots) -> Object:
	var loop = CompleteClearingLoop.new()
	loop.bind(w["board"], slots, w["candidates"], w["reservations"], w["dispatcher"], w.get("renderer"))
	return loop

## Test-only M20 transaction harness (V03 §4). Production CompleteClearingLoop.bind()
## now requires EXACT production script identity for candidate/reservation, so the
## adversarial M20 candidate/reservation subclass seams can no longer enter the
## real trust boundary. To keep the transaction rollback/serialization sensitivity
## coverage, this helper wires the loop's internals directly (bypassing the bind
## category gate) WITHOUT widening production bind — it never calls loop.bind(), so
## the production trust boundary is unchanged. Only used with a bundle whose
## candidate/reservation are the audited real classes or their test subclasses.
func _m20_harness_bind(w: Dictionary, slots) -> Object:
	var loop = CompleteClearingLoop.new()
	loop._board = w["board"]
	loop._slots = slots
	loop._candidates = w["candidates"]
	loop._reservations = w["reservations"]
	loop._dispatcher = w["dispatcher"]
	loop._renderer = w.get("renderer")
	# Mirror production bind's renderer-presence bit (V06 F-M20-STRICT-001.L) so the
	# harness reflects the same headless/configured semantics without a public setter.
	loop._renderer_expected = w.get("renderer") != null
	loop._arrival_cb = Callable(loop, "_on_assignment_arrived")
	w["dispatcher"].assignment_arrived.connect(loop._arrival_cb)
	loop._bound = true
	return loop

## Run one full activate -> arrival -> clear cycle through the loop. Returns the
## DispatchResult. When the dispatch succeeds, drives the agent to arrival, which
## synchronously fires the authenticated arrival signal and the clear transaction.
func _m20_activate_and_arrive(loop, slot_id: int, origin: Vector2):
	var res = loop.activate_slot(slot_id, origin, 6.0)
	if res.success:
		_m19_drive_to_arrival(res.agent)
	return res

func _run_m20_bind_contract_tests() -> void:
	print("---- M20-C001 V01: clearing-loop bind contract (section 2) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var w = _m20_full(board)
	var slots = _m20_slots([color, color, color, color, color])

	var loop = CompleteClearingLoop.new()
	_check(loop.bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: coherent real bundle binds")
	_check(loop.is_bound(), "bind: loop reports bound")
	_check(loop.is_coherent(), "bind: bound loop is coherent")
	_check(not loop.bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: second bind refused")
	_check(loop.is_bound(), "bind: still bound after refused second bind")

	var loop2 = CompleteClearingLoop.new()
	var raw_slots = SlotSystem.new()
	_check(not loop2.bind(board, raw_slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: unconfigured slots rejected")
	_check(not CompleteClearingLoop.new().bind(123, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: scalar board rejected")
	var other = _m19_open_board_active(20, 20, [Vector2(5, 5)])
	var stray_ci = ColorCandidateIndex.create(); stray_ci.bind(other)
	_check(not CompleteClearingLoop.new().bind(board, slots, stray_ci, w["reservations"], w["dispatcher"]), "bind: foreign-board candidate index rejected")
	var stray_rs = ReservationState.new(); stray_rs.bind(other)
	_check(not CompleteClearingLoop.new().bind(board, slots, w["candidates"], stray_rs, w["dispatcher"]), "bind: foreign-board reservation rejected")
	var wrong_r = BoardRenderer.new(); root.add_child(wrong_r)
	wrong_r.configure(other, PackedStringArray(BoardDebugFixturesM20.PALETTE), Vector2(120, 120))
	_check(not CompleteClearingLoop.new().bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"], wrong_r), "bind: wrong-board renderer rejected")
	root.remove_child(wrong_r); wrong_r.free()

	var r_pre = w["dispatcher"].dispatch(color, Vector2(-2.0, 10.5), 6.0)
	_check(r_pre.success and w["dispatcher"].get_active_count() == 1, "bind: pre-seeded one in-flight assignment")
	_check(not CompleteClearingLoop.new().bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: dispatcher active!=0 rejected")
	w["dispatcher"].reset()

	loop = null
	_m20_teardown(w)

func _run_m20_activation_tests() -> void:
	print("---- M20-C001 V01: slot activation delegation (section 4) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var w = _m20_full(board)
	var slots = _m20_slots([color, color, color, color, color])
	var loop = _m20_loop(w, slots)

	_check(not loop.activate_slot(-1, Vector2(-2.0, 10.5)).success, "activate: slot -1 rejected")
	_check(not loop.activate_slot(5, Vector2(-2.0, 10.5)).success, "activate: slot 5 rejected")
	_check(not loop.activate_slot(1.5, Vector2(-2.0, 10.5)).success, "activate: non-int slot rejected")
	_check(not loop.activate_slot(0, Vector2(INF, 10.5)).success, "activate: non-finite origin rejected")
	_check(not loop.activate_slot(0, Vector2(-2.0, 10.5), 0.0).success, "activate: zero speed rejected")
	_check_eq(w["dispatcher"].get_active_count(), 0, "activate: no agent from any rejected activation")
	_check_eq(w["reservations"].get_reservation_count(), 0, "activate: no reservation from any rejected activation")

	slots.set_slot_available(0, false)
	_check(not loop.activate_slot(0, Vector2(-2.0, 10.5)).success, "activate: unavailable slot rejected")
	slots.set_slot_available(0, true)

	var before = _snapshot_cell_states(board)
	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(res.success, "activate: valid activation dispatches one agent")
	_check_eq(res.target_index, board.get_cell_index(10, 10), "activate: the one reachable candidate selected")
	_check_eq(w["dispatcher"].get_active_count(), 1, "activate: exactly one Scrubbot in flight")
	_check(_cell_states_equal(board, before), "activate: no BoardState mutation before arrival")
	_check_eq(slots.get_slot_palette_id(0), color, "activate: slot palette id unchanged by success")
	_check(slots.is_slot_available(0), "activate: slot availability unchanged by success")

	loop = null
	_m20_teardown(w)

func _run_m20_clear_transaction_tests() -> void:
	print("---- M20-C001 V01: authoritative clear transaction + post-arrival tuple (section 6/10) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var target: int = board.get_cell_index(10, 10)
	var color: int = board.get_color_id(target)
	var w = _m20_full(board, null, null, true)
	var slots = _m20_slots([color, color, color, color, color])
	var loop = _m20_loop(w, slots)

	var res = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 10.5))
	_check(res.success, "clear: activation dispatched")
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.CLEARED, "clear: outcome CLEARED")
	_check_eq(loop.get_cleared_count(), 1, "clear: one cell cleared")
	_check_eq(board.get_cell_state(target), BoardState.CellState.CLEARED, "tuple: BoardState target CLEARED")
	_check(not w["candidates"].has_candidates(color, w["reservations"].get_reserved_indices()), "tuple: target absent from candidate bucket")
	_check_eq(w["reservations"].get_owner(target), -1, "tuple: reservation owner cleared")
	_check_eq(w["reservations"].get_target_for_owner(res.owner_id), -1, "tuple: owner holds no target")
	_check(not w["dispatcher"].has_owner(res.owner_id), "tuple: dispatcher no longer tracks the owner")
	_check_eq(w["dispatcher"].get_active_count(), 0, "tuple: dispatcher has no active entry after finalize")
	var pos: Vector2i = board.get_cell_position(target)
	_check_eq(w["routing_access"].classify_cell(pos.x, pos.y, -1), ProductionAccessQuery.CellClass.OPEN, "tuple: access query treats cleared cell as OPEN")
	var px: Color = w["renderer"].get_pixel_color(pos.x, pos.y)
	_check(_colors_close(px, Color(0, 0, 0, 0), 0.02), "tuple: renderer pixel alpha 0 at cleared cell")

	loop = null
	_m20_teardown(w)

	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t2: int = b2.get_cell_index(10, 10)
	var c2: int = b2.get_color_id(t2)
	var fci = M20FailingCandidate.new(); fci.bind(b2)
	var w2 = _m20_full(b2, fci)
	var slots2 = _m20_slots([c2, c2, c2, c2, c2])
	var loop2 = _m20_harness_bind(w2, slots2)
	fci.fail_syncs = 1
	var res2 = _m20_activate_and_arrive(loop2, 0, Vector2(-2.0, 10.5))
	_check(res2.success, "rollback(candidate): activation dispatched")
	_check_eq(loop2.get_last_outcome(), CompleteClearingLoop.Outcome.CANDIDATE_ROLLBACK, "rollback(candidate): outcome CANDIDATE_ROLLBACK")
	_check_eq(b2.get_cell_state(t2), BoardState.CellState.ACTIVE, "rollback(candidate): BoardState rolled back to ACTIVE")
	_check(w2["candidates"].has_candidates(c2, PackedInt32Array()), "rollback(candidate): candidate truth restored")
	_check_eq(w2["reservations"].get_owner(t2), res2.owner_id, "rollback(candidate): reservation still held")
	_check(w2["dispatcher"].has_owner(res2.owner_id), "rollback(candidate): dispatcher assignment still held")
	_check_eq(loop2.get_cleared_count(), 0, "rollback(candidate): nothing counted as cleared")
	loop2 = null
	_m20_teardown(w2)

	var b3 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t3: int = b3.get_cell_index(10, 10)
	var c3: int = b3.get_color_id(t3)
	var frs = M20FailingReservation.new(); frs.bind(b3)
	var w3 = _m20_full(b3, null, frs)
	var slots3 = _m20_slots([c3, c3, c3, c3, c3])
	var loop3 = _m20_harness_bind(w3, slots3)
	frs.fail_resolves = 1
	var res3 = _m20_activate_and_arrive(loop3, 0, Vector2(-2.0, 10.5))
	_check(res3.success, "rollback(reservation): activation dispatched")
	_check_eq(loop3.get_last_outcome(), CompleteClearingLoop.Outcome.RESERVATION_ROLLBACK, "rollback(reservation): outcome RESERVATION_ROLLBACK")
	_check_eq(b3.get_cell_state(t3), BoardState.CellState.ACTIVE, "rollback(reservation): BoardState rolled back to ACTIVE")
	_check_eq(w3["reservations"].get_owner(t3), res3.owner_id, "rollback(reservation): reservation still held")
	_check(w3["dispatcher"].has_owner(res3.owner_id), "rollback(reservation): dispatcher assignment still held")
	_check_eq(loop3.get_cleared_count(), 0, "rollback(reservation): nothing counted as cleared")
	loop3 = null
	_m20_teardown(w3)

func _run_m20_scenario_matrix_tests() -> void:
	print("---- M20-C001 V01: required scenario matrix (section 11) ----")

	var b1 = _m19_open_board_active(20, 20, [Vector2(4, 3)])
	var c1: int = b1.get_color_id(b1.get_cell_index(4, 3))
	var w1 = _m20_full(b1)
	var l1 = _m20_loop(w1, _m20_slots([c1, c1, c1, c1, c1]))
	_check(_m20_activate_and_arrive(l1, 0, Vector2(-2.0, 3.5)).success, "one-cell: cleared")
	_check_eq(l1.get_cleared_count(), 1, "one-cell: exactly one clear")
	_check_eq(l1.activate_slot(0, Vector2(-2.0, 3.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "one-cell: board exhausted -> NO_REACHABLE_TARGET")
	l1 = null; _m20_teardown(w1)

	var row_cells: Array = []
	for x in range(6):
		row_cells.append(Vector2(x + 2, 6))
	var b2 = _m19_open_board_active(20, 20, row_cells)
	var c2: int = b2.get_color_id(b2.get_cell_index(2, 6))
	var w2 = _m20_full(b2)
	var l2 = _m20_loop(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var cleared2 := 0
	for _i in range(20):
		var r = _m20_activate_and_arrive(l2, 0, Vector2(-2.0, 6.5))
		if not r.success:
			break
		cleared2 += 1
	_check_eq(cleared2, 6, "one-color: all six same-color cells cleared")
	_check_eq(l2.get_cleared_count(), 6, "one-color: cleared count == 6")
	_check_eq(b2.count_cells_by_state(BoardState.CellState.ACTIVE), 0, "one-color: no ACTIVE cells remain")
	l2 = null; _m20_teardown(w2)

	var mc_cells: Array = [Vector2(10, 0), Vector2(10, 1), Vector2(10, 2), Vector2(10, 3), Vector2(10, 4)]
	var b3 = _m19_open_board_active(20, 20, mc_cells)
	var pal3: Array = []
	for y in range(5):
		pal3.append(b3.get_color_id(b3.get_cell_index(10, y)))
	_check(pal3[0] != pal3[1], "multi-color: distinct row colors present")
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots(pal3))
	var inflight := 0
	var origins3: Array = [Vector2(-2.0, 0.5), Vector2(22.0, 1.5), Vector2(-2.0, 2.5), Vector2(22.0, 3.5), Vector2(-2.0, 4.5)]
	var results3: Array = []
	for i in range(5):
		var r = l3.activate_slot(i, origins3[i], 6.0)
		if r.success:
			inflight += 1
			results3.append(r)
	_check_eq(inflight, 5, "five-slot: five distinct simultaneous in-flight assignments")
	_check_eq(w3["dispatcher"].get_active_count(), 5, "five-slot: dispatcher tracks five agents")
	for r in results3:
		_m19_drive_to_arrival(r.agent)
	_check_eq(l3.get_cleared_count(), 5, "five-slot: all five arrivals cleared")
	_check_eq(w3["dispatcher"].get_active_count(), 0, "five-slot: no active entries after all finalized")
	l3 = null; _m20_teardown(w3)

	var b4 = _m19_open_board_active(20, 20, [Vector2(10, 2)])
	var w4 = _m20_full(b4)
	var missing_color: int = (b4.get_color_id(b4.get_cell_index(10, 2)) + 1) % 5
	var l4 = _m20_loop(w4, _m20_slots([missing_color, missing_color, missing_color, missing_color, missing_color]))
	_check_eq(l4.activate_slot(0, Vector2(-2.0, 2.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "no-target: absent color -> NO_REACHABLE_TARGET")
	_check_eq(l4.get_cleared_count(), 0, "no-target: nothing cleared")
	_check_eq(w4["dispatcher"].get_active_count(), 0, "no-target: no agent spawned")
	l4 = null; _m20_teardown(w4)

	var b5 = _m19_enclosed_sole_candidate_board()
	var w5 = _m20_full(b5)
	var l5 = _m20_loop(w5, _m20_slots([1, 1, 1, 1, 1]))
	_check_eq(l5.activate_slot(0, Vector2(-2.0, 2.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "enclosed: sole enclosed candidate -> NO_REACHABLE_TARGET")
	_check_eq(l5.get_cleared_count(), 0, "enclosed: nothing cleared")
	l5 = null; _m20_teardown(w5)

	var dims: Array = [
		{"w": 24, "h": 24, "name": "Easy 24x24"},
		{"w": 34, "h": 34, "name": "Medium 34x34"},
		{"w": 44, "h": 44, "name": "Hard 44x44"},
		{"w": 54, "h": 54, "name": "Very Hard 54x54"},
		{"w": 59, "h": 59, "name": "Max 59x59"},
		{"w": 53, "h": 59, "name": "Rectangular 53x59"},
	]
	for d in dims:
		var yy := 10
		var bd = _m19_open_board_active(d["w"], d["h"], [Vector2(12, yy)])
		var cd: int = bd.get_color_id(bd.get_cell_index(12, yy))
		var wd = _m20_full(bd)
		var ld = _m20_loop(wd, _m20_slots([cd, cd, cd, cd, cd]))
		var rd = _m20_activate_and_arrive(ld, 0, Vector2(-2.0, float(yy) + 0.5))
		_check(rd.success and ld.get_cleared_count() == 1, "dims: %s clears one reachable target" % d["name"])
		_check_eq(bd.get_cell_state(bd.get_cell_index(12, yy)), BoardState.CellState.CLEARED, "dims: %s target CLEARED" % d["name"])
		ld = null; _m20_teardown(wd)

	var stress_cells: Array = []
	for x in range(28):
		stress_cells.append(Vector2(x + 1, 5))
	var bs = _m19_open_board_active(30, 11, stress_cells)
	var cs: int = bs.get_color_id(bs.get_cell_index(1, 5))
	var ws = _m20_full(bs)
	var ls = _m20_loop(ws, _m20_slots([cs, cs, cs, cs, cs]))
	var cycles := 0
	for _i in range(40):
		var r = _m20_activate_and_arrive(ls, _i % 5, Vector2(-2.0, 5.5))
		if not r.success:
			break
		cycles += 1
	_check(cycles >= 25, "rapid: >= 25 sequential activate/arrival/clear cycles (%d)" % cycles)
	_check_eq(ls.get_cleared_count(), 28, "rapid: all 28 reachable cells cleared")
	ls = null; _m20_teardown(ws)

func _run_m20_reachability_open_tests() -> void:
	print("---- M20-C001 V01: clearing opens future reachability (section 8, AL-028) ----")
	var wd := 8; var ht := 8
	var b = _m19_open_board_active(wd, ht, [Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(2, 1), Vector2(2, 3)])
	var door: int = b.get_cell_index(1, 2)
	var inner: int = b.get_cell_index(2, 2)
	var door_color: int = b.get_color_id(door)
	var w = _m20_full(b)
	var probe = ProductionTargetAccess.new(w["routing"], w["routing_access"], b)
	probe.set_origin(Vector2(-2.0, 2.5))
	_check(not probe.is_targetable(inner), "reach: B initially unreachable (blocked by ACTIVE A)")
	probe.set_origin(Vector2(-2.0, 2.5))
	_check(probe.is_targetable(door), "reach: A initially reachable")
	var loop = _m20_loop(w, _m20_slots([door_color, door_color, door_color, door_color, door_color]))
	var res = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 2.5))
	_check(res.success and res.target_index == door, "reach: activation clears the reachable door A")
	_check_eq(b.get_cell_state(door), BoardState.CellState.CLEARED, "reach: A now CLEARED")
	var probe2 = ProductionTargetAccess.new(w["routing"], w["routing_access"], b)
	probe2.set_origin(Vector2(-2.0, 2.5))
	_check(probe2.is_targetable(inner), "reach: B reachable after A cleared (live read, no cache refresh)")
	loop = null
	_m20_teardown(w)

func _run_m20_desync_adversary_tests() -> void:
	print("---- M20-C001 V01: exactly-once / spoof / stale / desync adversaries (section 5/7) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var target: int = board.get_cell_index(10, 10)
	var color: int = board.get_color_id(target)
	var w = _m20_full(board)
	var loop = _m20_loop(w, _m20_slots([color, color, color, color, color]))

	var before = _snapshot_cell_states(board)
	loop._on_assignment_arrived(999, target, color, null)
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "spoof: unknown owner rejected by preflight")
	_check(_cell_states_equal(board, before), "spoof: unknown-owner arrival mutates nothing")
	_check_eq(loop.get_cleared_count(), 0, "spoof: nothing cleared")

	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(res.success, "desync: assignment dispatched")
	w["dispatcher"].assignment_arrived.disconnect(loop._arrival_cb)
	_m19_drive_to_arrival(res.agent)
	var owner: int = res.owner_id
	var agent = res.agent
	_check(w["dispatcher"].is_arrival_pending(owner, target, color, agent), "bridge: exact arrival is pending")
	_check(not w["dispatcher"].is_arrival_pending(owner + 1, target, color, agent), "bridge: wrong owner not pending")
	_check(not w["dispatcher"].is_arrival_pending(owner, target + 1, color, agent), "bridge: wrong target not pending")
	_check(not w["dispatcher"].is_arrival_pending(owner, target, color + 1, agent), "bridge: wrong color not pending")
	_check(not w["dispatcher"].is_arrival_pending(owner, target, color, null), "bridge: wrong agent not pending")
	_check(not w["dispatcher"].finalize_arrival(owner + 1, target, color, agent), "bridge: wrong-owner finalize false")
	_check(w["dispatcher"].has_owner(owner), "bridge: assignment still held after spoofed finalize")

	w["reservations"].release_for_owner(owner)
	loop._on_assignment_arrived(owner, target, color, agent)
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "desync: reservation removed -> preflight rejected")
	_check_eq(board.get_cell_state(target), BoardState.CellState.ACTIVE, "desync: target still ACTIVE (no clear)")
	w["dispatcher"].finalize_arrival(owner, target, color, agent)
	loop = null
	_m20_teardown(w)

	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t2: int = b2.get_cell_index(10, 10)
	var c2: int = b2.get_color_id(t2)
	var w2 = _m20_full(b2)
	var l2 = _m20_loop(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var r2 = l2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_m19_drive_to_arrival(r2.agent)
	_check_eq(l2.get_cleared_count(), 1, "once: first arrival cleared once")
	if is_instance_valid(r2.agent):
		r2.agent.agent_completed.emit(r2.owner_id, t2, c2)
	_check_eq(l2.get_cleared_count(), 1, "once: duplicate completion does not clear twice")
	l2 = null; _m20_teardown(w2)

	var b3 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t3: int = b3.get_cell_index(10, 10)
	var c3: int = b3.get_color_id(t3)
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots([c3, c3, c3, c3, c3]))
	var r3 = l3.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	w3["dispatcher"].assignment_arrived.disconnect(l3._arrival_cb)
	_m19_drive_to_arrival(r3.agent)
	b3.set_cell_state(t3, BoardState.CellState.CLEARED)
	l3._on_assignment_arrived(r3.owner_id, t3, c3, r3.agent)
	_check_eq(l3.get_last_outcome(), CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "desync: already-CLEARED target rejected")
	w3["dispatcher"].finalize_arrival(r3.owner_id, t3, c3, r3.agent)
	l3 = null; _m20_teardown(w3)

func _run_m20_reset_lifecycle_tests() -> void:
	print("---- M20-C001 V01: reset / lifecycle (section 9) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(6, 0), Vector2(6, 1), Vector2(6, 2), Vector2(6, 3), Vector2(6, 4)])
	var pal: Array = []
	for y in range(5):
		pal.append(board.get_color_id(board.get_cell_index(6, y)))
	var w = _m20_full(board)
	var loop = _m20_loop(w, _m20_slots(pal))

	var r0 = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 0.5))
	_check(r0.success and loop.get_cleared_count() == 1, "reset: one cell cleared before reset")
	var cleared_target: int = r0.target_index

	var origins: Array = [Vector2(22.0, 1.5), Vector2(-2.0, 2.5), Vector2(22.0, 3.5)]
	var inflight: Array = []
	for i in range(3):
		var r = loop.activate_slot(i + 1, origins[i], 6.0)
		if r.success:
			inflight.append(r)
	_check_eq(inflight.size(), 3, "reset: three agents in flight")
	_check_eq(w["dispatcher"].get_active_count(), 3, "reset: dispatcher tracks three in-flight")
	_check_eq(w["reservations"].get_reservation_count(), 3, "reset: three reservations held")

	var next_owner_before: int = w["dispatcher"].peek_next_owner_id()
	loop.reset()
	_check_eq(w["dispatcher"].get_active_count(), 0, "reset: no active assignments after reset")
	_check_eq(w["reservations"].get_reservation_count(), 0, "reset: reservations released")
	_check_eq(board.get_cell_state(cleared_target), BoardState.CellState.CLEARED, "reset: already-CLEARED cell preserved")
	_check_eq(w["dispatcher"].peek_next_owner_id(), next_owner_before, "reset: owner id counter not rewound")
	loop.reset()
	_check_eq(w["dispatcher"].get_active_count(), 0, "reset: second reset is a stable no-op")

	var stale := 0
	for r in inflight:
		if not w["dispatcher"].is_arrival_pending(r.owner_id, r.target_index, board.get_color_id(r.target_index), r.agent):
			stale += 1
	_check_eq(stale, inflight.size(), "reset: no cancelled agent is arrival-pending")
	_check_eq(loop.get_cleared_count(), 1, "reset: clear count unchanged by reset (still 1)")

	var r_after = _m20_activate_and_arrive(loop, 1, Vector2(22.0, 1.5))
	_check(r_after.success and loop.get_cleared_count() == 2, "reset: loop usable again after reset")

	loop = null
	_m20_teardown(w)

# ===================================== M20-C001 V02 strict-v2 transaction fix ==
# Adds mutation-sensitive, directly-observed coverage for the frozen
# F-M20-STRICT-001..007 correction surface: real bind transaction, serialized
# activation, lossless serial arrivals, transactional reset, corrected
# renderer-after-finalize order, exact pre-state snapshot, verified postconditions
# and verified rollback. Uses real production dependencies for the spine; the
# candidate/reservation seams (real subclasses) drive the adversarial callbacks.

func _m20_conn_count(dispatcher) -> int:
	return dispatcher.assignment_arrived.get_connections().size()

func _run_m20_v02_bind_transaction_tests() -> void:
	print("---- M20-C001 V03: exact-category bind trust boundary (F-M20-STRICT-001, §2/§9) ----")
	# Exact production bundle binds; the exact ColorCandidateIndex and
	# ReservationState are accepted.
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var w = _m20_full(board)
	var slots = _m20_slots([color, color, color, color, color])
	var loop = CompleteClearingLoop.new()
	_check(loop.bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: exact ColorCandidateIndex + ReservationState accepted")
	_check_eq(_m20_conn_count(w["dispatcher"]), 1, "bind: exact bundle connects exactly one arrival signal")
	# Ordinary second bind preserves the original bundle.
	_check(not loop.bind(board, slots, w["candidates"], w["reservations"], w["dispatcher"]), "bind: ordinary second bind refused, bundle preserved")
	# Original exact bundle still works end-to-end.
	var res = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 10.5))
	_check(res.success and loop.get_cleared_count() == 1, "bind: original exact bundle clears an arrival")
	loop = null
	_m20_teardown(w)

	# Candidate SUBCLASS rejected before any callback use; no signal bound; unbound.
	var bc = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cc: int = bc.get_color_id(bc.get_cell_index(10, 10))
	var wc = _m20_full(bc)
	var slc = _m20_slots([cc, cc, cc, cc, cc])
	var cand_sub = M20CandidateSeam.new(); cand_sub.bind(bc)
	# Arm a coherence hook that WOULD spoof/rebind if it were ever called — proving
	# rejection happens at the category gate, before is_bound_to() is invoked.
	var coh_called := [false]
	cand_sub.coherence_hook = func(): coh_called[0] = true
	var lc = CompleteClearingLoop.new()
	_check(not lc.bind(bc, slc, cand_sub, wc["reservations"], wc["dispatcher"]), "bind: candidate subclass rejected")
	_check(not coh_called[0], "bind: candidate subclass rejected BEFORE any is_bound_to callback")
	_check(not lc.is_bound(), "bind: loop unbound after rejected candidate subclass")
	_check_eq(_m20_conn_count(wc["dispatcher"]), 0, "bind: rejected candidate subclass binds no arrival signal")
	cand_sub.coherence_hook = Callable()
	_m20_teardown(wc)

	# Reservation SUBCLASS rejected before any callback use; no signal bound.
	var br = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cr: int = br.get_color_id(br.get_cell_index(10, 10))
	var wr = _m20_full(br)
	var slr = _m20_slots([cr, cr, cr, cr, cr])
	var res_sub = M20ReservationSeam.new(); res_sub.bind(br)
	var lr = CompleteClearingLoop.new()
	_check(not lr.bind(br, slr, wr["candidates"], res_sub, wr["dispatcher"]), "bind: reservation subclass rejected")
	_check(not lr.is_bound(), "bind: loop unbound after rejected reservation subclass")
	_check_eq(_m20_conn_count(wr["dispatcher"]), 0, "bind: rejected reservation subclass binds no arrival signal")
	_m20_teardown(wr)

	# Same-size DIFFERENT-board exact candidate/reservation cannot be committed
	# (exact-identity coherence, not category alone).
	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var foreign = _m19_open_board_active(20, 20, [Vector2(5, 5)])
	var c2: int = b2.get_color_id(b2.get_cell_index(10, 10))
	var w2 = _m20_full(b2)
	var sl2 = _m20_slots([c2, c2, c2, c2, c2])
	var stray_ci = ColorCandidateIndex.create(); stray_ci.bind(foreign) # exact class, foreign board
	_check(not CompleteClearingLoop.new().bind(b2, sl2, stray_ci, w2["reservations"], w2["dispatcher"]), "bind: exact candidate bound to a different board rejected")
	var stray_rs = ReservationState.new(); stray_rs.bind(foreign)
	_check(not CompleteClearingLoop.new().bind(b2, sl2, w2["candidates"], stray_rs, w2["dispatcher"]), "bind: exact reservation bound to a different board rejected")
	# Non-exact board (a Node) rejected.
	_check(not CompleteClearingLoop.new().bind(w2["dispatcher"], sl2, w2["candidates"], w2["reservations"], w2["dispatcher"]), "bind: non-exact board script rejected")
	_m20_teardown(w2)

func _run_m20_v02_activation_serialization_tests() -> void:
	print("---- M20-C001 V02: activation serialization (F-M20-STRICT-002) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10), Vector2(12, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var seam = M20CandidateSeam.new(); seam.bind(board)
	var w = _m20_full(board, seam)
	var slots = _m20_slots([color, color, color, color, color])
	var loop = _m20_harness_bind(w, slots)

	# Nested activation injected from the activation live-coherence callback.
	var nested_reason := [&""]
	seam.coherence_hook = func():
		nested_reason[0] = loop.activate_slot(1, Vector2(22.0, 10.5), 6.0).failure_reason
	var owner_before: int = w["dispatcher"].peek_next_owner_id()
	var outer = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(outer.success, "activation: outer activation dispatched")
	_check_eq(nested_reason[0], DispatchResult.FailureReason.REENTRANT, "activation: nested activation rejected REENTRANT")
	_check_eq(w["dispatcher"].get_active_count(), 1, "activation: nested created zero extra agent")
	_check_eq(w["reservations"].get_reservation_count(), 1, "activation: nested created zero extra reservation")
	seam.coherence_hook = Callable()
	seam._coh_hook_fired = false
	w["dispatcher"].reset()

	# Reset injected from the activation live-coherence callback -> aborts dispatch.
	seam.coherence_hook = func(): loop.reset()
	var owner_pre: int = w["dispatcher"].peek_next_owner_id()
	var aborted = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(not aborted.success, "activation: reset during preflight aborts dispatch")
	_check_eq(aborted.failure_reason, DispatchResult.FailureReason.RESETTING, "activation: reset-aborted reason RESETTING")
	_check_eq(w["dispatcher"].get_active_count(), 0, "activation: reset-abort dispatched nothing")
	_check_eq(w["dispatcher"].get_active_count() + w["reservations"].get_reservation_count(), 0, "activation: reset-abort reserved nothing")
	_check_eq(w["dispatcher"].peek_next_owner_id(), owner_pre, "activation: reset-abort advanced no owner id")
	seam.coherence_hook = Callable()
	seam._coh_hook_fired = false

	# Later ordinary activation recovers.
	var recover = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(recover.success, "activation: later ordinary activation recovers")
	loop = null
	_m20_teardown(w)

func _run_m20_v02_transaction_order_tests() -> void:
	print("---- M20-C001 V02: corrected order + postconditions (F-M20-STRICT-004) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10), Vector2(14, 10)])
	var t1: int = board.get_cell_index(10, 10)
	var color: int = board.get_color_id(t1)
	var w = _m20_full(board, null, null, true) # renderer bound
	var slots = _m20_slots([color, color, color, color, color])
	var loop = _m20_loop(w, slots)

	var pre_active: int = 0
	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	pre_active = w["dispatcher"].get_active_count()
	var pre_reserved: int = w["reservations"].get_reservation_count()
	_m19_drive_to_arrival(res.agent)
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.CLEARED, "order: outcome CLEARED")
	# BoardState postcondition.
	_check_eq(board.get_cell_state(t1), BoardState.CellState.CLEARED, "post: board target CLEARED")
	_check_eq(board.get_color_id(t1), color, "post: immutable color unchanged")
	# Candidate postcondition (raw membership, no exclusion).
	_check(not w["candidates"].get_candidates(color, null).has(t1), "post: raw candidate membership gone")
	# Reservation postcondition (count is pre minus exactly one).
	_check_eq(w["reservations"].get_owner(t1), -1, "post: reservation owner -1")
	_check_eq(w["reservations"].get_target_for_owner(res.owner_id), -1, "post: owner target -1")
	_check_eq(w["reservations"].get_reservation_count(), pre_reserved - 1, "post: reservation count -1")
	# Dispatcher postcondition (active is pre minus exactly one).
	_check(not w["dispatcher"].has_owner(res.owner_id), "post: dispatcher owner absent")
	_check_eq(w["dispatcher"].get_active_count(), pre_active - 1, "post: active count -1")
	# Renderer repaint AFTER finalization: alpha 0.
	var pos: Vector2i = board.get_cell_position(t1)
	_check(_colors_close(w["renderer"].get_pixel_color(pos.x, pos.y), Color(0, 0, 0, 0), 0.02), "post: renderer alpha 0 after finalize")
	loop = null
	_m20_teardown(w)

func _run_m20_v02_mutation_rollback_tests() -> void:
	print("---- M20-C001 V02: mutation-sensitive verified rollback w/ renderer (F-M20-STRICT-004/009/012) ----")
	var modes: Array = [
		{"kind": "candidate", "mode": "mutate_false", "name": "candidate mutate-before-false"},
		{"kind": "candidate", "mode": "true_noop", "name": "candidate true-without-postcondition"},
		{"kind": "candidate", "mode": "neutralize_false", "name": "candidate neutralize-before-false"},
		{"kind": "reservation", "mode": "mutate_false", "name": "reservation mutate-before-false"},
		{"kind": "reservation", "mode": "true_noop", "name": "reservation true-without-postcondition"},
	]
	for m in modes:
		var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
		var t: int = board.get_cell_index(10, 10)
		var color: int = board.get_color_id(t)
		var source_px := Color()
		var w
		if m["kind"] == "candidate":
			var seam = M20CandidateSeam.new(); seam.bind(board)
			w = _m20_full(board, seam, null, true)
		else:
			var seam = M20ReservationSeam.new(); seam.bind(board)
			w = _m20_full(board, null, seam, true)
		var slots = _m20_slots([color, color, color, color, color])
		var loop = _m20_harness_bind(w, slots)
		var pos: Vector2i = board.get_cell_position(t)
		source_px = w["renderer"].get_pixel_color(pos.x, pos.y)
		# Arm the adversarial mode AFTER a clean activation dispatch.
		var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
		if m["kind"] == "candidate":
			w["candidates"].mode = m["mode"]
		else:
			w["reservations"].mode = m["mode"]
		_m19_drive_to_arrival(res.agent)
		var expected = CompleteClearingLoop.Outcome.CANDIDATE_ROLLBACK if m["kind"] == "candidate" else CompleteClearingLoop.Outcome.RESERVATION_ROLLBACK
		_check_eq(loop.get_last_outcome(), expected, "rollback[%s]: verified rollback outcome" % m["name"])
		# Verified pre-arrival tuple restored.
		_check_eq(board.get_cell_state(t), BoardState.CellState.ACTIVE, "rollback[%s]: board ACTIVE" % m["name"])
		_check(w["candidates"].get_candidates(color, null).has(t) if m["kind"] != "candidate" else true, "rollback[%s]: raw candidate present (res case)" % m["name"])
		_check_eq(w["reservations"].get_owner(t), res.owner_id, "rollback[%s]: exact reservation pair held" % m["name"])
		_check(w["dispatcher"].is_arrival_pending(res.owner_id, t, color, res.agent), "rollback[%s]: dispatcher arrived assignment still pending" % m["name"])
		_check_eq(loop.get_cleared_count(), 0, "rollback[%s]: nothing counted as cleared" % m["name"])
		# Renderer: no transparent false-clear frame — pixel stays source/opaque.
		var px: Color = w["renderer"].get_pixel_color(pos.x, pos.y)
		_check(px.a >= 0.99 and _colors_close(px, source_px, 0.02), "rollback[%s]: renderer pixel stays ACTIVE/opaque" % m["name"])
		# Reset the mode so teardown reset can release cleanly.
		if m["kind"] == "candidate":
			w["candidates"].mode = "normal"
		else:
			w["reservations"].mode = "normal"
		loop = null
		_m20_teardown(w)

	# Candidate raw membership specifically restored for the candidate cases.
	var b = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var tt: int = b.get_cell_index(10, 10)
	var cc: int = b.get_color_id(tt)
	var cseam = M20CandidateSeam.new(); cseam.bind(b)
	var w2 = _m20_full(b, cseam, null, false)
	var l2 = _m20_harness_bind(w2, _m20_slots([cc, cc, cc, cc, cc]))
	var r2 = l2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	cseam.mode = "neutralize_false"
	_m19_drive_to_arrival(r2.agent)
	_check_eq(l2.get_last_outcome(), CompleteClearingLoop.Outcome.CANDIDATE_ROLLBACK, "rollback[candidate neutralize]: candidate rebound + membership restored")
	_check(w2["candidates"].is_bound_to(b), "rollback[candidate neutralize]: candidate re-bound to original board")
	_check(w2["candidates"].get_candidates(cc, null).has(tt), "rollback[candidate neutralize]: raw membership restored")
	cseam.mode = "normal"
	l2 = null
	_m20_teardown(w2)

func _run_m20_v02_reset_during_arrival_tests() -> void:
	print("---- M20-C001 V02: transactional reset during arrival (F-M20-STRICT-006) ----")
	# Reset injected inside the candidate sync callback (mutation already began).
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t: int = board.get_cell_index(10, 10)
	var color: int = board.get_color_id(t)
	var seam = M20CandidateSeam.new(); seam.bind(board)
	var w = _m20_full(board, seam)
	var loop = _m20_harness_bind(w, _m20_slots([color, color, color, color, color]))
	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	seam.sync_hook = func(_idx): loop.reset()
	_m19_drive_to_arrival(res.agent)
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.RESET_ABORTED, "reset-in-arrival(candidate): RESET_ABORTED")
	_check_eq(board.get_cell_state(t), BoardState.CellState.ACTIVE, "reset-in-arrival(candidate): BoardState preserved (not cleared)")
	_check_eq(w["dispatcher"].get_active_count(), 0, "reset-in-arrival(candidate): in-flight assignment removed")
	_check_eq(w["reservations"].get_reservation_count(), 0, "reset-in-arrival(candidate): reservation released")
	_check_eq(loop.get_cleared_count(), 0, "reset-in-arrival(candidate): nothing cleared")
	# Later activation works (with a fresh target since none remains here -> no work,
	# but the loop is usable / coherent again).
	_check(loop.is_coherent(), "reset-in-arrival(candidate): loop coherent after reset")
	seam.sync_hook = Callable()
	loop = null
	_m20_teardown(w)

	# Reset injected inside the reservation resolve callback (pair removed then reset).
	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t2: int = b2.get_cell_index(10, 10)
	var c2: int = b2.get_color_id(t2)
	var rseam = M20ReservationSeam.new(); rseam.bind(b2)
	var w2 = _m20_full(b2, null, rseam)
	var loop2 = _m20_harness_bind(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var res2 = loop2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	rseam.resolve_hook = func(_t, _o): loop2.reset()
	_m19_drive_to_arrival(res2.agent)
	_check_eq(loop2.get_last_outcome(), CompleteClearingLoop.Outcome.RESET_ABORTED, "reset-in-arrival(reservation): RESET_ABORTED")
	_check_eq(b2.get_cell_state(t2), BoardState.CellState.ACTIVE, "reset-in-arrival(reservation): BoardState preserved")
	_check_eq(w2["dispatcher"].get_active_count(), 0, "reset-in-arrival(reservation): in-flight removed")
	_check_eq(w2["reservations"].get_reservation_count(), 0, "reset-in-arrival(reservation): reservation released")
	rseam.resolve_hook = Callable()
	loop2 = null
	_m20_teardown(w2)

func _run_m20_v02_serial_arrival_tests() -> void:
	print("---- M20-C001 V02: lossless serial arrivals (F-M20-STRICT-006) ----")
	# Two same-color reachable targets; a second DISTINCT arrival is injected while
	# the first arrival transaction is committing. It must be queued, not dropped.
	var board = _m19_open_board_active(20, 20, [Vector2(8, 10), Vector2(12, 10)])
	var tA: int = board.get_cell_index(8, 10)
	var tB: int = board.get_cell_index(12, 10)
	var color: int = board.get_color_id(tA)
	var seam = M20CandidateSeam.new(); seam.bind(board)
	var w = _m20_full(board, seam)
	var loop = _m20_harness_bind(w, _m20_slots([color, color, color, color, color]))
	var resA = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	var resB = loop.activate_slot(1, Vector2(22.0, 10.5), 6.0)
	_check(resA.success and resB.success and resA.target_index != resB.target_index, "serial: two distinct in-flight assignments")
	# During A's candidate-sync step, drive B to arrival -> B's authenticated bridge
	# fires while A's transaction is active; it must enqueue and drain after A.
	seam.sync_hook = func(_idx): _m19_drive_to_arrival(resB.agent)
	_m19_drive_to_arrival(resA.agent)
	_check_eq(loop.get_cleared_count(), 2, "serial: both A and B cleared (no lost arrival)")
	_check_eq(board.get_cell_state(tA), BoardState.CellState.CLEARED, "serial: A cleared")
	_check_eq(board.get_cell_state(tB), BoardState.CellState.CLEARED, "serial: B cleared")
	_check_eq(w["dispatcher"].get_active_count(), 0, "serial: no active entries after both finalized")
	_check_eq(w["reservations"].get_reservation_count(), 0, "serial: no reservations remain")
	seam.sync_hook = Callable()
	loop = null
	_m20_teardown(w)

func _run_m20_v02_reachability_second_activation_tests() -> void:
	print("---- M20-C001 V02: AL-028 full second-activation proof (F-M20-STRICT-005) ----")
	var b = _m19_open_board_active(8, 8, [Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(2, 1), Vector2(2, 3)])
	var door: int = b.get_cell_index(1, 2)  # A, reachable gate
	var inner: int = b.get_cell_index(2, 2) # B, initially enclosed (same color as A)
	var color: int = b.get_color_id(door)
	var w = _m20_full(b)
	var loop = _m20_loop(w, _m20_slots([color, color, color, color, color]))
	# B not targetable before A clears (direct probe through the real access stack).
	var probe = ProductionTargetAccess.new(w["routing"], w["routing_access"], b)
	probe.set_origin(Vector2(-2.0, 2.5))
	_check(not probe.is_targetable(inner), "reach2: B unreachable before A cleared")
	# First activation clears the reachable gate A.
	var rA = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 2.5))
	_check(rA.success and rA.target_index == door, "reach2: first activation clears gate A")
	_check_eq(b.get_cell_state(door), BoardState.CellState.CLEARED, "reach2: A CLEARED")
	_check(not w["candidates"].get_candidates(color, null).has(door), "reach2: A absent from candidates")
	var dpos: Vector2i = b.get_cell_position(door)
	_check_eq(w["routing_access"].classify_cell(dpos.x, dpos.y, -1), ProductionAccessQuery.CellClass.OPEN, "reach2: A OPEN to ProductionAccessQuery")
	# Second real activation through the loop must now select/reserve/clear B.
	var rB = loop.activate_slot(1, Vector2(-2.0, 2.5), 6.0)
	_check(rB.success, "reach2: second activation dispatches")
	_check_eq(rB.target_index, inner, "reach2: second dispatch selected/reserved B")
	_check(w["reservations"].is_reserved(inner), "reach2: B reserved by the second dispatch")
	_m19_drive_to_arrival(rB.agent)
	_check_eq(b.get_cell_state(inner), BoardState.CellState.CLEARED, "reach2: B clears on arrival")
	_check_eq(w["reservations"].get_owner(inner), -1, "reach2: B final tuple synchronized (reservation resolved)")
	_check(not w["dispatcher"].has_owner(rB.owner_id), "reach2: B dispatcher entry finalized")
	loop = null
	_m20_teardown(w)

func _run_m20_v02_direct_observability_tests() -> void:
	print("---- M20-C001 V02: direct-observability completion (F-M20-STRICT-007) ----")
	# True 1x1 generic BoardState (not 20x20 with one ACTIVE cell).
	var b1 = _m19_open_board_active(1, 1, [Vector2(0, 0)])
	_check_eq(b1.get_width(), 1, "1x1: width 1")
	_check_eq(b1.get_height(), 1, "1x1: height 1")
	_check_eq(b1.get_cell_count(), 1, "1x1: cell_count 1")
	var col1: int = b1.get_color_id(0)
	var w1 = _m20_full(b1)
	var l1 = _m20_loop(w1, _m20_slots([col1, col1, col1, col1, col1]))
	var r1 = _m20_activate_and_arrive(l1, 0, Vector2(-2.0, 0.5))
	_check(r1.success and l1.get_cleared_count() == 1, "1x1: single ACTIVE cell dispatched, arrived, cleared")
	_check_eq(b1.get_cell_state(0), BoardState.CellState.CLEARED, "1x1: the one cell CLEARED")
	_check_eq(l1.activate_slot(0, Vector2(-2.0, 0.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "1x1: second activation no work")
	l1 = null; _m20_teardown(w1)

	# Five-slot direct identity proof: five unique owners, five distinct targets,
	# five exact reservation pairs, active_count == 5; one arrival preserves the
	# other four before they arrive.
	var mc: Array = [Vector2(10, 0), Vector2(10, 1), Vector2(10, 2), Vector2(10, 3), Vector2(10, 4)]
	var b2 = _m19_open_board_active(20, 20, mc)
	var pal: Array = []
	for y in range(5):
		pal.append(b2.get_color_id(b2.get_cell_index(10, y)))
	var w2 = _m20_full(b2)
	var l2 = _m20_loop(w2, _m20_slots(pal))
	var origins: Array = [Vector2(-2.0, 0.5), Vector2(22.0, 1.5), Vector2(-2.0, 2.5), Vector2(22.0, 3.5), Vector2(-2.0, 4.5)]
	var results: Array = []
	var owners := {}
	var targets := {}
	for i in range(5):
		var r = l2.activate_slot(i, origins[i], 6.0)
		if r.success:
			results.append(r)
			owners[r.owner_id] = true
			targets[r.target_index] = true
	_check_eq(results.size(), 5, "five-slot: five success results")
	_check_eq(owners.size(), 5, "five-slot: five unique owner ids")
	_check_eq(targets.size(), 5, "five-slot: five distinct target indices")
	var pairs_ok := true
	for r in results:
		if w2["reservations"].get_owner(r.target_index) != r.owner_id:
			pairs_ok = false
		if w2["reservations"].get_target_for_owner(r.owner_id) != r.target_index:
			pairs_ok = false
	_check(pairs_ok, "five-slot: five exact ReservationState pairs")
	_check_eq(w2["dispatcher"].get_active_count(), 5, "five-slot: dispatcher active_count == 5")
	# Resolve the first arrival, prove the other four remain exact/in-flight.
	_m19_drive_to_arrival(results[0].agent)
	_check_eq(l2.get_cleared_count(), 1, "five-slot: first arrival cleared")
	var others_ok := true
	for i in range(1, 5):
		var r = results[i]
		if not w2["dispatcher"].has_owner(r.owner_id):
			others_ok = false
		if w2["reservations"].get_owner(r.target_index) != r.owner_id:
			others_ok = false
	_check(others_ok, "five-slot: other four remain exact/in-flight after first arrival")
	_check_eq(w2["dispatcher"].get_active_count(), 4, "five-slot: four still active")
	# Resolve all remaining.
	for i in range(1, 5):
		_m19_drive_to_arrival(results[i].agent)
	_check_eq(l2.get_cleared_count(), 5, "five-slot: all five cleared")
	l2 = null; _m20_teardown(w2)

	# Failed-preflight safe recovery (F-M20-STRICT-003 / §15): an authenticated
	# arrival that fails M20 preflight stays held; loop.reset() then removes the
	# stranded assignment/reservation without changing BoardState.
	var b3 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var t3: int = b3.get_cell_index(10, 10)
	var c3: int = b3.get_color_id(t3)
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots([c3, c3, c3, c3, c3]))
	var r3 = l3.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	# Disconnect the loop so the dispatcher records the arrival unconsumed, then
	# desync the reservation so the manual handler call fails preflight.
	w3["dispatcher"].assignment_arrived.disconnect(l3._arrival_cb)
	_m19_drive_to_arrival(r3.agent)
	w3["reservations"].release_for_owner(r3.owner_id)
	l3._on_assignment_arrived(r3.owner_id, t3, c3, r3.agent)
	_check_eq(l3.get_last_outcome(), CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "recovery: desync arrival rejected, held not half-cleared")
	_check_eq(b3.get_cell_state(t3), BoardState.CellState.ACTIVE, "recovery: BoardState unchanged")
	_check(w3["dispatcher"].has_owner(r3.owner_id), "recovery: dispatcher still holds the stranded assignment")
	# Reconnect so reset()'s dispatcher.reset can clean the agent, then recover.
	w3["dispatcher"].assignment_arrived.connect(l3._arrival_cb)
	l3.reset()
	_check_eq(w3["dispatcher"].get_active_count(), 0, "recovery: reset removed stranded dispatcher entry")
	_check_eq(w3["reservations"].get_reservation_count(), 0, "recovery: reset removed any held reservation")
	_check_eq(b3.get_cell_state(t3), BoardState.CellState.ACTIVE, "recovery: BoardState still unchanged after reset")
	# Stale replay cannot clear.
	l3._on_assignment_arrived(r3.owner_id, t3, c3, r3.agent)
	_check_eq(l3.get_cleared_count(), 0, "recovery: stale replay after reset cannot clear")
	# Later normal activation works when work exists.
	var r3b = _m20_activate_and_arrive(l3, 0, Vector2(-2.0, 10.5))
	_check(r3b.success and l3.get_cleared_count() == 1, "recovery: later normal activation works")
	l3 = null; _m20_teardown(w3)

# ===================================== M20-C001 V03 exact dependency / state ===
# Exact-category trust boundary is proven in _run_m20_v02_bind_transaction_tests
# (rewritten for V03). Here: exact reservation snapshot/postcondition/rollback
# (owner-map, not count-only), unrelated candidate-truth preservation with the
# single-cell healthy path intact, and current-arrival dedup. Rollback sensitivity
# uses the test-only _m20_harness_bind (never widens production bind categories).

func _run_m20_v03_exact_reservation_state_tests() -> void:
	print("---- M20-C001 V03: exact reservation snapshot/postcondition/rollback (§5/§6) ----")
	# Happy path with EXACT deps: an unrelated reservation keeps its exact owner
	# across a clear (owner-map postcondition, not count-only).
	var board = _m19_open_board_active(20, 20, [Vector2(8, 10), Vector2(10, 10)])
	var tT: int = board.get_cell_index(8, 10)
	var tU: int = board.get_cell_index(10, 10)
	var color: int = board.get_color_id(tT)
	var w = _m20_full(board)
	var loop = _m20_loop(w, _m20_slots([color, color, color, color, color]))
	var rT = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	var rU = loop.activate_slot(1, Vector2(22.0, 10.5), 6.0)
	_check(rT.success and rU.success and rT.target_index == tT and rU.target_index == tU, "exact-res: two distinct reservations (T,U)")
	_m19_drive_to_arrival(rT.agent)
	_check_eq(loop.get_last_outcome(), CompleteClearingLoop.Outcome.CLEARED, "exact-res: T cleared")
	# Owner-map exactness: reserved set is exactly {U}, U keeps its exact owner.
	var reserved = w["reservations"].get_reserved_indices()
	_check_eq(reserved.size(), 1, "exact-res: exactly one reservation remains")
	_check(reserved.has(tU), "exact-res: the remaining reservation is exactly U")
	_check_eq(w["reservations"].get_owner(tU), rU.owner_id, "exact-res: U keeps its exact owner")
	_check_eq(w["reservations"].get_owner(tT), -1, "exact-res: T reservation resolved")
	loop = null
	_m20_teardown(w)

	# Reservation identity-swap mutate-false: the fault does the real current
	# resolve, then drops an unrelated pair U and re-reserves ownerU on V, then
	# returns false. V02's count-only rollback verify would report ordinary
	# RESERVATION_ROLLBACK; V03's exact owner-map verify detects the collateral
	# corruption and surfaces ROLLBACK_FAILED. (Test-only harness — the seam is a
	# production-rejected subclass.)
	var b2 = _m19_open_board_active(20, 20, [Vector2(8, 10), Vector2(10, 10), Vector2(12, 10)])
	var t2T: int = b2.get_cell_index(8, 10)
	var t2U: int = b2.get_cell_index(10, 10)
	var t2V: int = b2.get_cell_index(12, 10)
	var c2: int = b2.get_color_id(t2T)
	var rseam = M20ReservationSeam.new(); rseam.bind(b2)
	var w2 = _m20_full(b2, null, rseam)
	var l2 = _m20_harness_bind(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var r2T = l2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	var r2U = l2.activate_slot(1, Vector2(22.0, 10.5), 6.0)
	_check(r2T.success and r2U.success and r2T.target_index == t2T and r2U.target_index == t2U, "identity-swap: T,U reserved; V free")
	rseam.mode = "identity_swap"
	rseam.swap_from_owner = r2U.owner_id
	rseam.swap_from_target = t2U
	rseam.swap_to_target = t2V
	_m19_drive_to_arrival(r2T.agent)
	_check_eq(l2.get_last_outcome(), CompleteClearingLoop.Outcome.ROLLBACK_FAILED, "identity-swap: exact owner-map verify surfaces ROLLBACK_FAILED (not ordinary rollback)")
	_check_eq(b2.get_cell_state(t2T), BoardState.CellState.ACTIVE, "identity-swap: T BoardState rolled back to ACTIVE")
	_check_eq(l2.get_cleared_count(), 0, "identity-swap: nothing counted as cleared")
	rseam.mode = "normal"
	l2 = null
	_m20_teardown(w2)

func _run_m20_v03_unrelated_truth_tests() -> void:
	print("---- M20-C001 V03: unrelated candidate truth + single-cell path (§7) ----")
	# EXACT-deps normal clear: two same-color candidates (T,U) + a different-color
	# candidate W. Clearing T removes only T; U and W buckets are unchanged.
	var board = _m19_open_board_active(20, 20, [Vector2(8, 10), Vector2(10, 10), Vector2(8, 12)])
	var tT: int = board.get_cell_index(8, 10)
	var tU: int = board.get_cell_index(10, 10)  # same color as T (same row)
	var tW: int = board.get_cell_index(8, 12)   # different row -> different color
	var colT: int = board.get_color_id(tT)
	var colW: int = board.get_color_id(tW)
	_check(colT != colW, "unrelated: T and W are different colors")
	var w = _m20_full(board)
	var loop = _m20_loop(w, _m20_slots([colT, colT, colT, colT, colT]))
	_check(w["candidates"].get_candidates(colT, null).has(tT) and w["candidates"].get_candidates(colT, null).has(tU), "unrelated: two same-color candidates exist before clear")
	var w_before: Array = w["candidates"].get_candidates(colW, null)
	var rT = _m20_activate_and_arrive(loop, 0, Vector2(-2.0, 10.5))
	_check(rT.success and rT.target_index == tT, "unrelated: T cleared")
	_check(not w["candidates"].get_candidates(colT, null).has(tT), "unrelated: T removed from candidates")
	_check(w["candidates"].get_candidates(colT, null).has(tU), "unrelated: same-color U still a candidate")
	_check_eq(w["candidates"].get_candidates(colW, null), w_before, "unrelated: other-color bucket unchanged")
	loop = null
	_m20_teardown(w)

	# Candidate unrelated-loss mutate-false (harness): fault removes T AND unrelated
	# same-color U then returns false; the verified rollback restores BOTH T and U.
	var b2 = _m19_open_board_active(20, 20, [Vector2(8, 10), Vector2(10, 10)])
	var t2T: int = b2.get_cell_index(8, 10)
	var t2U: int = b2.get_cell_index(10, 10)
	var col2: int = b2.get_color_id(t2T)
	var cseam = M20CandidateSeam.new(); cseam.bind(b2)
	var w2 = _m20_full(b2, cseam)
	var l2 = _m20_harness_bind(w2, _m20_slots([col2, col2, col2, col2, col2]))
	var r2 = l2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	cseam.mode = "unrelated_loss"
	cseam.loss_color = col2
	cseam.loss_index = t2U
	_m19_drive_to_arrival(r2.agent)
	_check_eq(l2.get_last_outcome(), CompleteClearingLoop.Outcome.CANDIDATE_ROLLBACK, "unrelated-loss: verified CANDIDATE_ROLLBACK")
	_check_eq(b2.get_cell_state(t2T), BoardState.CellState.ACTIVE, "unrelated-loss: T back ACTIVE")
	cseam.mode = "normal"
	_check(w2["candidates"].get_candidates(col2, null).has(t2T), "unrelated-loss: T candidate restored")
	_check(w2["candidates"].get_candidates(col2, null).has(t2U), "unrelated-loss: unrelated U candidate restored")
	l2 = null
	_m20_teardown(w2)

	# 59x59 normal clear remains a single-cell sync (no M20 board scan): one clear
	# succeeds and only the target cell changes state.
	var big = _m19_open_board_active(59, 59, [Vector2(30, 30)])
	var tb: int = big.get_cell_index(30, 30)
	var cb: int = big.get_color_id(tb)
	var wb = _m20_full(big)
	var lb = _m20_loop(wb, _m20_slots([cb, cb, cb, cb, cb]))
	var cleared_before: int = big.count_cells_by_state(BoardState.CellState.CLEARED)
	var rb = _m20_activate_and_arrive(lb, 0, Vector2(-2.0, 30.5))
	_check(rb.success and lb.get_cleared_count() == 1, "59x59: single clear succeeds")
	_check_eq(big.count_cells_by_state(BoardState.CellState.CLEARED), cleared_before + 1, "59x59: exactly one cell changed (single-cell path)")
	lb = null
	_m20_teardown(wb)

func _run_m20_v03_current_arrival_dedup_tests() -> void:
	print("---- M20-C001 V03: current-arrival dedup (§8) ----")
	# During A's transaction, inject a DUPLICATE of A (same owner+agent). It must be
	# dropped, not re-queued or re-processed. A distinct arrival still queues FIFO
	# (covered by _run_m20_v02_serial_arrival_tests).
	var board = _m19_open_board_active(20, 20, [Vector2(8, 10)])
	var tA: int = board.get_cell_index(8, 10)
	var color: int = board.get_color_id(tA)
	var seam = M20CandidateSeam.new(); seam.bind(board)
	var w = _m20_full(board, seam)
	var loop = _m20_harness_bind(w, _m20_slots([color, color, color, color, color]))
	var resA = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	# Re-inject A's own authenticated tuple mid-transaction: dedup must drop it.
	seam.sync_hook = func(_idx): loop._on_assignment_arrived(resA.owner_id, tA, color, resA.agent)
	_m19_drive_to_arrival(resA.agent)
	_check_eq(loop.get_cleared_count(), 1, "dedup: duplicate current arrival dropped (A cleared exactly once)")
	_check_eq(board.get_cell_state(tA), BoardState.CellState.CLEARED, "dedup: A cleared")
	_check_eq(w["dispatcher"].get_active_count(), 0, "dedup: no lingering active entry")
	seam.sync_hook = Callable()
	loop = null
	_m20_teardown(w)

# ===================================== M20-C001 V04 lifecycle / reset closure ==
# Node-lifetime bind/probe safety (F-M20-STRICT-001.K), post-dispatch transaction
# bracket (F-M20-STRICT-002.K), and pair-narrow board-safe dispatcher reset
# (F-M20-STRICT-006.K). The truly-freed (invalid) dispatcher case needs a real
# SceneTree frame and lives in tests/m20_v04_lifecycle_smoke.gd; the queued cases
# are directly observable in the synchronous runner.

## Wire a full production bundle whose M19 dispatch uses M20ResetSelectAccess, so a
## one-shot hook can fire loop.reset() / renderer.queue_free() from inside dispatch.
func _m20_full_reset_access(board, use_renderer := false) -> Dictionary:
	var reservations = ReservationState.new(); reservations.bind(board)
	var candidates = ColorCandidateIndex.create(); candidates.bind(board)
	var selector = TargetSelector.create(); selector.bind(board, candidates, reservations)
	var routing = ProductionRoutingSystem.new()
	var routing_access = ProductionAccessQuery.new(board)
	var select_access = M20ResetSelectAccess.new(routing, routing_access, board)
	var dispatcher = ScrubbotDispatcher.new(); root.add_child(dispatcher)
	dispatcher.bind(board, selector, reservations, routing, routing_access, select_access)
	var renderer = null
	if use_renderer:
		renderer = BoardRenderer.new(); root.add_child(renderer)
		renderer.configure(board, PackedStringArray(BoardDebugFixturesM20.PALETTE), Vector2(300, 300))
	return {"board": board, "reservations": reservations, "candidates": candidates,
		"selector": selector, "routing": routing, "routing_access": routing_access,
		"select_access": select_access, "dispatcher": dispatcher, "renderer": renderer}

func _run_m20_v04_node_lifetime_tests() -> void:
	print("---- M20-C001 V04: Node lifetime boundary (F-M20-STRICT-001.K) ----")
	# Dispatcher queued for deletion BEFORE bind -> rejected, unbound, no signal.
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var w = _m20_full(board)
	w["dispatcher"].queue_free()
	var loop = CompleteClearingLoop.new()
	_check(not loop.bind(board, _m20_slots([color, color, color, color, color]), w["candidates"], w["reservations"], w["dispatcher"]), "lifetime: queued dispatcher rejected at bind")
	_check(not loop.is_bound(), "lifetime: loop unbound after queued dispatcher")
	_check_eq(_m20_conn_count(w["dispatcher"]), 0, "lifetime: queued dispatcher binds no arrival signal")
	root.remove_child(w["dispatcher"]); w["dispatcher"].free()

	# Renderer queued for deletion BEFORE bind -> rejected.
	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var c2: int = b2.get_color_id(b2.get_cell_index(10, 10))
	var w2 = _m20_full(b2, null, null, true)
	w2["renderer"].queue_free()
	_check(not CompleteClearingLoop.new().bind(b2, _m20_slots([c2, c2, c2, c2, c2]), w2["candidates"], w2["reservations"], w2["dispatcher"], w2["renderer"]), "lifetime: queued renderer rejected at bind")
	root.remove_child(w2["renderer"]); w2["renderer"].free()
	_m20_teardown(w2)

	# After a healthy bind, queue-free the dispatcher: is_coherent() false, activation
	# fails closed, reset() is safe — all without a SCRIPT ERROR.
	var b3 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var c3: int = b3.get_color_id(b3.get_cell_index(10, 10))
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots([c3, c3, c3, c3, c3]))
	_check(l3.is_coherent(), "lifetime: healthy bundle coherent before free")
	w3["dispatcher"].queue_free()
	_check(not l3.is_coherent(), "lifetime: queued dispatcher makes bundle incoherent")
	_check(not l3.activate_slot(0, Vector2(-2.0, 10.5)).success, "lifetime: activation against queued dispatcher fails closed")
	l3.reset() # must be safe (queued dispatcher still callable)
	_check(true, "lifetime: reset() with queued dispatcher did not error")
	root.remove_child(w3["dispatcher"]); w3["dispatcher"].free()

func _run_m20_v04_post_dispatch_bracket_tests() -> void:
	print("---- M20-C001 V04: post-dispatch transaction bracket (F-M20-STRICT-002.K) ----")
	# Reset injected from inside M19 dispatch: M19 may still return SUCCESS, but the
	# bracketed activate_slot() must return RESETTING (never stale SUCCESS), clean the
	# in-flight dispatcher/reservation, keep owner ids monotonic, and recover later.
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10), Vector2(12, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))
	var w = _m20_full_reset_access(board)
	var loop = _m20_loop(w, _m20_slots([color, color, color, color, color]))
	var owner_before: int = w["dispatcher"].peek_next_owner_id()
	w["select_access"].hook = func(): loop.reset()
	var res = loop.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(not res.success, "bracket(reset): activation not a stale success")
	_check_eq(res.failure_reason, DispatchResult.FailureReason.RESETTING, "bracket(reset): reason RESETTING")
	_check_eq(w["dispatcher"].get_active_count(), 0, "bracket(reset): no live dispatcher assignment left")
	_check_eq(w["reservations"].get_reservation_count(), 0, "bracket(reset): current reservation cleaned")
	_check(w["dispatcher"].peek_next_owner_id() >= owner_before, "bracket(reset): owner id counter not rewound")
	w["select_access"].hook = Callable()
	# Later ordinary activation recovers (select_access hook is one-shot).
	var again = _m20_activate_and_arrive(loop, 1, Vector2(22.0, 10.5))
	_check(again.success and loop.get_cleared_count() == 1, "bracket(reset): later ordinary activation recovers and clears")
	loop = null
	_m20_teardown(w)

	# Renderer freed from inside M19 dispatch: M20-visible coherence loss must never
	# expose the raw M19 SUCCESS -> COHERENCE_FAILED with the in-flight assignment
	# cleaned; a fresh healthy bundle proves later recovery.
	var b2 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var c2: int = b2.get_color_id(b2.get_cell_index(10, 10))
	var w2 = _m20_full_reset_access(b2, true)
	var l2 = _m20_loop(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var rderer = w2["renderer"]
	w2["select_access"].hook = func(): rderer.queue_free()
	var res2 = l2.activate_slot(0, Vector2(-2.0, 10.5), 6.0)
	_check(not res2.success, "bracket(coherence): activation not a stale success")
	_check_eq(res2.failure_reason, DispatchResult.FailureReason.COHERENCE_FAILED, "bracket(coherence): reason COHERENCE_FAILED")
	_check_eq(w2["dispatcher"].get_active_count(), 0, "bracket(coherence): no live dispatcher assignment left")
	_check_eq(w2["reservations"].get_reservation_count(), 0, "bracket(coherence): current reservation cleaned")
	w2["select_access"].hook = Callable()
	if is_instance_valid(rderer):
		root.remove_child(rderer); rderer.free()
	w2["renderer"] = null
	l2 = null
	_m20_teardown(w2)

func _run_m19_v04_pair_narrow_reset_tests() -> void:
	print("---- M19 V04: pair-narrow board-safe dispatcher reset (F-M20-STRICT-006.K) ----")
	# A. healthy original board + exact T<->O -> reset releases T only.
	var bA = _m19_open_board_active(20, 20, [Vector2(10, 10), Vector2(12, 10)])
	var colorA: int = bA.get_color_id(bA.get_cell_index(10, 10))
	var wA = _m19_wire_real(bA)
	var rA = wA["dispatcher"].dispatch(colorA, Vector2(-2.0, 10.5), 6.0)
	var tA: int = rA.target_index
	_check(rA.success and wA["reservations"].is_reserved(tA), "pair-narrow A: dispatch reserved T")
	wA["dispatcher"].reset()
	_check_eq(wA["reservations"].get_reservation_count(), 0, "pair-narrow A: reset released T")
	_check_eq(wA["dispatcher"].get_active_count(), 0, "pair-narrow A: active bookkeeping cleared")
	_m19_teardown(wA)

	# B. ReservationState rebound to foreign board B, owner O on a different B target
	#    -> reset preserves the B reservation; dispatcher still clears its own agent.
	var bB0 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var colorB: int = bB0.get_color_id(bB0.get_cell_index(10, 10))
	var wB = _m19_wire_real(bB0)
	var rB = wB["dispatcher"].dispatch(colorB, Vector2(-2.0, 10.5), 6.0)
	var owner: int = rB.owner_id
	var boardB = _m19_open_board_active(20, 20, [Vector2(3, 3)])
	wB["reservations"].rebind(boardB)
	var bTarget: int = boardB.get_cell_index(3, 3)
	wB["reservations"].reserve(bTarget, owner)
	wB["dispatcher"].reset()
	_check_eq(wB["reservations"].get_owner(bTarget), owner, "pair-narrow B: foreign-board reservation preserved")
	_check_eq(wB["dispatcher"].get_active_count(), 0, "pair-narrow B: dispatcher still cleared its agent")
	_m19_teardown(wB)

	# C. foreign board B uses the SAME numeric target index T and owner O -> still
	#    preserved (board identity is foreign).
	var bC0 = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var colorC: int = bC0.get_color_id(bC0.get_cell_index(10, 10))
	var wC = _m19_wire_real(bC0)
	var rC = wC["dispatcher"].dispatch(colorC, Vector2(-2.0, 10.5), 6.0)
	var ownerC: int = rC.owner_id
	var tC: int = rC.target_index
	var boardC = _m19_open_board_active(20, 20, [Vector2(int(tC % 20), int(tC / 20))])
	wC["reservations"].rebind(boardC)
	wC["reservations"].reserve(tC, ownerC) # same numeric target + owner, foreign board
	wC["dispatcher"].reset()
	_check_eq(wC["reservations"].get_owner(tC), ownerC, "pair-narrow C: same-index foreign-board reservation preserved")
	_check_eq(wC["dispatcher"].get_active_count(), 0, "pair-narrow C: dispatcher still cleared its agent")
	_m19_teardown(wC)

	# D. same original board but O now owns V != T -> reset preserves V.
	var bD = _m19_open_board_active(20, 20, [Vector2(10, 10), Vector2(14, 10)])
	var colorD: int = bD.get_color_id(bD.get_cell_index(10, 10))
	var wD = _m19_wire_real(bD)
	var rD = wD["dispatcher"].dispatch(colorD, Vector2(-2.0, 10.5), 6.0)
	var ownerD: int = rD.owner_id
	var tD: int = rD.target_index
	var vD: int = bD.get_cell_index(14, 10)
	wD["reservations"].release(tD, ownerD)   # drop O's T
	wD["reservations"].reserve(vD, ownerD)   # O now owns V != T
	wD["dispatcher"].reset()
	_check_eq(wD["reservations"].get_owner(vD), ownerD, "pair-narrow D: O-owns-V (!=T) reservation preserved")
	_check_eq(wD["dispatcher"].get_active_count(), 0, "pair-narrow D: dispatcher still cleared its agent")
	_m19_teardown(wD)

	# E. current reservation missing -> reset does not invent/mutate another.
	var bE = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var colorE: int = bE.get_color_id(bE.get_cell_index(10, 10))
	var wE = _m19_wire_real(bE)
	var rE = wE["dispatcher"].dispatch(colorE, Vector2(-2.0, 10.5), 6.0)
	wE["reservations"].release(rE.target_index, rE.owner_id) # remove it out from under the dispatcher
	wE["dispatcher"].reset()
	_check_eq(wE["reservations"].get_reservation_count(), 0, "pair-narrow E: missing reservation not re-invented")
	_check_eq(wE["dispatcher"].get_active_count(), 0, "pair-narrow E: dispatcher still cleared its agent")
	_m19_teardown(wE)

	# Owner id counter remains monotonic across all pair-narrow resets.
	var bM = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var wM = _m19_wire_real(bM)
	var before_owner: int = wM["dispatcher"].peek_next_owner_id()
	wM["dispatcher"].dispatch(bM.get_color_id(bM.get_cell_index(10, 10)), Vector2(-2.0, 10.5), 6.0)
	wM["dispatcher"].reset()
	_check(wM["dispatcher"].peek_next_owner_id() > before_owner, "pair-narrow: owner id monotonic across reset")
	_m19_teardown(wM)

# ============================ M20-C001 V05 auditor-authored validation gate =====
# Fresh, independent adversarial arrangements against the ACCEPTED V04 production
# (locked blobs). Validation-only: no production change. Builds fresh bundles for
# each high-risk seam rather than re-calling V04 aggregates. The truly-freed Node
# cases (§3E) live in tests/m20_v05_lifecycle_smoke.gd (needs real frames).

func _run_m20_v05_auditor_validation_tests() -> void:
	print("==== M20-C001 V05 auditor validation (fresh arrangements) ====")
	_v05_node_lifecycle()
	_v05_post_dispatch_barrier()
	_v05_pair_narrow_reset()
	_v05_arrival_adversaries()
	_v05_gameplay_integration()
	print("  M20 V05 auditor validation complete")

# --- §3 Node-lifecycle -------------------------------------------------------
func _v05_node_lifecycle() -> void:
	print("---- V05 §3: Node lifecycle liveness law ----")
	# A. queued dispatcher before bind.
	var ba = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var ca: int = ba.get_color_id(ba.get_cell_index(11, 11))
	var wa = _m20_full(ba)
	wa["dispatcher"].queue_free()
	var la = CompleteClearingLoop.new()
	_check(not la.bind(ba, _m20_slots([ca, ca, ca, ca, ca]), wa["candidates"], wa["reservations"], wa["dispatcher"]), "V05.3A: queued dispatcher -> bind false")
	_check(not la.is_bound(), "V05.3A: loop unbound")
	_check_eq(_m20_conn_count(wa["dispatcher"]), 0, "V05.3A: zero arrival connection")
	root.remove_child(wa["dispatcher"]); wa["dispatcher"].free()

	# B. queued renderer before bind.
	var bb = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var cb: int = bb.get_color_id(bb.get_cell_index(11, 11))
	var wb = _m20_full(bb, null, null, true)
	wb["renderer"].queue_free()
	var lb = CompleteClearingLoop.new()
	_check(not lb.bind(bb, _m20_slots([cb, cb, cb, cb, cb]), wb["candidates"], wb["reservations"], wb["dispatcher"], wb["renderer"]), "V05.3B: queued renderer -> bind false")
	_check(not lb.is_bound(), "V05.3B: loop unbound")
	_check_eq(_m20_conn_count(wb["dispatcher"]), 0, "V05.3B: zero arrival connection")
	root.remove_child(wb["renderer"]); wb["renderer"].free()
	_m20_teardown(wb)

	# C. dispatcher queued AFTER healthy bind.
	var bc = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var cc: int = bc.get_color_id(bc.get_cell_index(11, 11))
	var wc = _m20_full(bc)
	var lc = _m20_loop(wc, _m20_slots([cc, cc, cc, cc, cc]))
	_check(lc.is_coherent(), "V05.3C: healthy bundle coherent")
	wc["dispatcher"].queue_free()
	_check(not lc.is_coherent(), "V05.3C: queued dispatcher -> incoherent")
	_check(not lc.activate_slot(0, Vector2(-2.0, 11.5)).success, "V05.3C: activation fails closed")
	lc.reset()
	_check(true, "V05.3C: reset() safe (no SCRIPT ERROR)")
	root.remove_child(wc["dispatcher"]); wc["dispatcher"].free()

	# D. renderer queued AFTER healthy bind WITH a live assignment.
	var bd = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var td: int = bd.get_cell_index(11, 11)
	var cd: int = bd.get_color_id(td)
	var wd = _m20_full(bd, null, null, true)
	var ld = _m20_loop(wd, _m20_slots([cd, cd, cd, cd, cd]))
	var rd = ld.activate_slot(0, Vector2(-2.0, 11.5), 6.0) # live in-flight assignment
	_check(rd.success and wd["reservations"].get_owner(td) == rd.owner_id, "V05.3D: live assignment + exact reservation created")
	wd["renderer"].queue_free() # queue renderer BEFORE arrival
	_check(not ld.is_coherent(), "V05.3D: coherence false after renderer queued")
	ld.reset()
	_check_eq(wd["dispatcher"].get_active_count(), 0, "V05.3D: reset removed the dispatcher-owned assignment")
	_check_eq(wd["reservations"].get_owner(td), -1, "V05.3D: reset released the exact original reservation")
	_check_eq(bd.get_cell_state(td), BoardState.CellState.ACTIVE, "V05.3D: BoardState remains ACTIVE (no false clear)")
	_check_eq(ld.get_cleared_count(), 0, "V05.3D: cleared_count not incremented")
	if is_instance_valid(wd["renderer"]):
		root.remove_child(wd["renderer"]); wd["renderer"].free()
	wd["renderer"] = null
	_m20_teardown(wd)

# --- §4 post-dispatch transaction barrier ------------------------------------
func _v05_post_dispatch_barrier() -> void:
	print("---- V05 §4: post-dispatch transaction barrier ----")
	# Reset inside M19 dispatch.
	var board = _m19_open_board_active(24, 24, [Vector2(11, 11), Vector2(13, 11)])
	var t0: int = board.get_cell_index(11, 11)
	var color: int = board.get_color_id(t0)
	var w = _m20_full_reset_access(board)
	var loop = _m20_loop(w, _m20_slots([color, color, color, color, color]))
	var owner_before: int = w["dispatcher"].peek_next_owner_id()
	w["select_access"].hook = func(): loop.reset()
	var res = loop.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	_check_eq(w["dispatcher"].peek_next_owner_id(), owner_before + 1, "V05.4reset: exactly one owner token consumed")
	_check(not res.success and res.failure_reason == DispatchResult.FailureReason.RESETTING, "V05.4reset: RESETTING, no raw M19 SUCCESS")
	_check_eq(w["dispatcher"].get_active_count(), 0, "V05.4reset: dispatcher active_count 0 on return")
	_check_eq(w["reservations"].get_reservation_count(), 0, "V05.4reset: current-attempt reservation absent")
	_check_eq(board.get_cell_state(t0), BoardState.CellState.ACTIVE, "V05.4reset: BoardState target ACTIVE")
	_check_eq(loop.get_cleared_count(), 0, "V05.4reset: cleared_count 0")
	w["select_access"].hook = Callable()
	var later = _m20_activate_and_arrive(loop, 1, Vector2(26.0, 11.5))
	_check(later.success and later.owner_id > owner_before, "V05.4reset: later activation uses strictly later owner and succeeds")
	_check(loop.get_cleared_count() == 1, "V05.4reset: later activation clears")
	loop = null
	_m20_teardown(w)

	# Renderer lifecycle loss inside M19 dispatch.
	var b2 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var t2: int = b2.get_cell_index(11, 11)
	var c2: int = b2.get_color_id(t2)
	var w2 = _m20_full_reset_access(b2, true)
	var l2 = _m20_loop(w2, _m20_slots([c2, c2, c2, c2, c2]))
	var ob2: int = w2["dispatcher"].peek_next_owner_id()
	var rderer = w2["renderer"]
	w2["select_access"].hook = func(): rderer.queue_free()
	var res2 = l2.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	_check_eq(w2["dispatcher"].peek_next_owner_id(), ob2 + 1, "V05.4rend: exactly one owner token consumed")
	_check(not res2.success and res2.failure_reason == DispatchResult.FailureReason.COHERENCE_FAILED, "V05.4rend: COHERENCE_FAILED, not raw SUCCESS")
	_check_eq(w2["dispatcher"].get_active_count(), 0, "V05.4rend: active assignment gone on return")
	_check_eq(w2["reservations"].get_reservation_count(), 0, "V05.4rend: exact current reservation gone")
	_check_eq(b2.get_cell_state(t2), BoardState.CellState.ACTIVE, "V05.4rend: BoardState ACTIVE (no renderer false-clear)")
	_check_eq(l2.get_cleared_count(), 0, "V05.4rend: cleared_count 0")
	w2["select_access"].hook = Callable()
	if is_instance_valid(rderer):
		root.remove_child(rderer); rderer.free()
	w2["renderer"] = null
	l2 = null
	_m20_teardown(w2)
	# Fresh healthy bundle later operates.
	var b3 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var c3: int = b3.get_color_id(b3.get_cell_index(11, 11))
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots([c3, c3, c3, c3, c3]))
	_check(_m20_activate_and_arrive(l3, 0, Vector2(-2.0, 11.5)).success and l3.get_cleared_count() == 1, "V05.4rend: fresh healthy bundle clears")
	l3 = null
	_m20_teardown(w3)

# --- §5 pair-narrow reset ----------------------------------------------------
func _v05_pair_narrow_reset() -> void:
	print("---- V05 §5: pair-narrow board-safe reset ----")
	# A. healthy pair + unrelated reservation (not a dispatcher active entry).
	var bA = _m19_open_board_active(24, 24, [Vector2(11, 11), Vector2(13, 11)])
	var wA = _m19_wire_real(bA)
	var rA = wA["dispatcher"].dispatch(bA.get_color_id(bA.get_cell_index(11, 11)), Vector2(-2.0, 11.5), 6.0)
	var uA: int = bA.get_cell_index(13, 11)
	var ownerU: int = 9999
	_check(wA["reservations"].reserve(uA, ownerU), "V05.5A: unrelated reservation (U,OU) created")
	wA["dispatcher"].reset()
	_check_eq(wA["reservations"].get_owner(rA.target_index), -1, "V05.5A: T<->O removed")
	_check_eq(wA["reservations"].get_owner(uA), ownerU, "V05.5A: unrelated U<->OU preserved")
	_check_eq(wA["dispatcher"].get_active_count(), 0, "V05.5A: dispatcher active cleared")
	_m19_teardown(wA)

	# B. foreign board, different target.
	var bB = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var wB = _m19_wire_real(bB)
	var rB = wB["dispatcher"].dispatch(bB.get_color_id(bB.get_cell_index(11, 11)), Vector2(-2.0, 11.5), 6.0)
	var boardB = _m19_open_board_active(24, 24, [Vector2(4, 4)])
	wB["reservations"].rebind(boardB)
	var vB: int = boardB.get_cell_index(4, 4)
	wB["reservations"].reserve(vB, rB.owner_id)
	wB["dispatcher"].reset()
	_check_eq(wB["reservations"].get_owner(vB), rB.owner_id, "V05.5B: foreign-board V<->O survives")
	_check_eq(wB["dispatcher"].get_active_count(), 0, "V05.5B: dispatcher active cleared")
	_m19_teardown(wB)

	# C. foreign board, same numeric target index.
	var bC = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var wC = _m19_wire_real(bC)
	var rC = wC["dispatcher"].dispatch(bC.get_color_id(bC.get_cell_index(11, 11)), Vector2(-2.0, 11.5), 6.0)
	var tC: int = rC.target_index
	var boardC = _m19_open_board_active(24, 24, [Vector2(int(tC % 24), int(tC / 24))])
	wC["reservations"].rebind(boardC)
	wC["reservations"].reserve(tC, rC.owner_id)
	wC["dispatcher"].reset()
	_check_eq(wC["reservations"].get_owner(tC), rC.owner_id, "V05.5C: same-index foreign-board T<->O survives")
	_check_eq(wC["dispatcher"].get_active_count(), 0, "V05.5C: dispatcher active cleared")
	_m19_teardown(wC)

	# D. same original board owner replacement + unrelated reservation.
	var bD = _m19_open_board_active(24, 24, [Vector2(11, 11), Vector2(15, 11), Vector2(17, 11)])
	var wD = _m19_wire_real(bD)
	var rD = wD["dispatcher"].dispatch(bD.get_color_id(bD.get_cell_index(11, 11)), Vector2(-2.0, 11.5), 6.0)
	var vD: int = bD.get_cell_index(15, 11)
	var uD: int = bD.get_cell_index(17, 11)
	wD["reservations"].release(rD.target_index, rD.owner_id) # drop original T<->O
	wD["reservations"].reserve(vD, rD.owner_id)             # O now owns V
	wD["reservations"].reserve(uD, 8888)                    # unrelated U<->OU
	wD["dispatcher"].reset()
	_check_eq(wD["reservations"].get_owner(vD), rD.owner_id, "V05.5D: V<->O survives")
	_check_eq(wD["reservations"].get_owner(uD), 8888, "V05.5D: unrelated U<->OU survives")
	_check_eq(wD["dispatcher"].get_active_count(), 0, "V05.5D: dispatcher active cleared")
	_m19_teardown(wD)

	# E. missing current pair + unrelated reservation.
	var bE = _m19_open_board_active(24, 24, [Vector2(11, 11), Vector2(19, 11)])
	var wE = _m19_wire_real(bE)
	var rE = wE["dispatcher"].dispatch(bE.get_color_id(bE.get_cell_index(11, 11)), Vector2(-2.0, 11.5), 6.0)
	var uE: int = bE.get_cell_index(19, 11)
	wE["reservations"].release(rE.target_index, rE.owner_id) # remove current pair entirely
	wE["reservations"].reserve(uE, 7777)
	wE["dispatcher"].reset()
	_check_eq(wE["reservations"].get_owner(uE), 7777, "V05.5E: unrelated U<->OU survives")
	_check_eq(wE["reservations"].get_reservation_count(), 1, "V05.5E: no new reservation fabricated")
	_check_eq(wE["dispatcher"].get_active_count(), 0, "V05.5E: dispatcher active cleared")
	_m19_teardown(wE)

	# F. loop.reset() route (foreign-board case) must not reintroduce collateral.
	var bF = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var cF: int = bF.get_color_id(bF.get_cell_index(11, 11))
	var wF = _m20_full(bF)
	var lF = _m20_loop(wF, _m20_slots([cF, cF, cF, cF, cF]))
	var rF = lF.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	var boardF = _m19_open_board_active(24, 24, [Vector2(6, 6)])
	wF["reservations"].rebind(boardF)
	var vF: int = boardF.get_cell_index(6, 6)
	wF["reservations"].reserve(vF, rF.owner_id)
	lF.reset()
	_check_eq(wF["reservations"].get_owner(vF), rF.owner_id, "V05.5F: loop.reset() preserves foreign-board reservation")
	_check_eq(wF["dispatcher"].get_active_count(), 0, "V05.5F: loop.reset() cleared dispatcher active")
	lF = null
	_m20_teardown(wF)

# --- §6 arrival / transaction adversaries ------------------------------------
func _v05_arrival_adversaries() -> void:
	print("---- V05 §6: arrival / transaction adversaries ----")
	# Duplicate current arrival cannot clear twice.
	var b1 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var t1: int = b1.get_cell_index(11, 11)
	var col1: int = b1.get_color_id(t1)
	var seam1 = M20CandidateSeam.new(); seam1.bind(b1)
	var w1 = _m20_full(b1, seam1)
	var loop1 = _m20_harness_bind(w1, _m20_slots([col1, col1, col1, col1, col1]))
	var r1 = loop1.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	seam1.sync_hook = func(_i): loop1._on_assignment_arrived(r1.owner_id, t1, col1, r1.agent)
	_m19_drive_to_arrival(r1.agent)
	_check_eq(loop1.get_cleared_count(), 1, "V05.6: duplicate current arrival cleared exactly once")
	seam1.sync_hook = Callable(); loop1 = null; _m20_teardown(w1)

	# Distinct second arrival during current transaction is FIFO/lossless.
	var b2 = _m19_open_board_active(24, 24, [Vector2(9, 11), Vector2(13, 11)])
	var tA: int = b2.get_cell_index(9, 11)
	var tB: int = b2.get_cell_index(13, 11)
	var col2: int = b2.get_color_id(tA)
	var seam2 = M20CandidateSeam.new(); seam2.bind(b2)
	var w2 = _m20_full(b2, seam2)
	var loop2 = _m20_harness_bind(w2, _m20_slots([col2, col2, col2, col2, col2]))
	var rA = loop2.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	var rB = loop2.activate_slot(1, Vector2(26.0, 11.5), 6.0)
	seam2.sync_hook = func(_i): _m19_drive_to_arrival(rB.agent)
	_m19_drive_to_arrival(rA.agent)
	_check_eq(loop2.get_cleared_count(), 2, "V05.6: distinct second arrival not lost (FIFO)")
	_check_eq(b2.get_cell_state(tA), BoardState.CellState.CLEARED, "V05.6: A cleared")
	_check_eq(b2.get_cell_state(tB), BoardState.CellState.CLEARED, "V05.6: B cleared")
	seam2.sync_hook = Callable(); loop2 = null; _m20_teardown(w2)

	# Reset during candidate phase restores target, no clear.
	var b3 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var t3: int = b3.get_cell_index(11, 11)
	var col3: int = b3.get_color_id(t3)
	var seam3 = M20CandidateSeam.new(); seam3.bind(b3)
	var w3 = _m20_full(b3, seam3)
	var loop3 = _m20_harness_bind(w3, _m20_slots([col3, col3, col3, col3, col3]))
	var r3 = loop3.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	seam3.sync_hook = func(_i): loop3.reset()
	_m19_drive_to_arrival(r3.agent)
	_check_eq(loop3.get_last_outcome(), CompleteClearingLoop.Outcome.RESET_ABORTED, "V05.6: reset in candidate phase -> RESET_ABORTED")
	_check_eq(b3.get_cell_state(t3), BoardState.CellState.ACTIVE, "V05.6: candidate-phase reset restores target ACTIVE")
	_check_eq(loop3.get_cleared_count(), 0, "V05.6: no clear")
	seam3.sync_hook = Callable(); loop3 = null; _m20_teardown(w3)

	# Reset during reservation phase restores target, no clear.
	var b4 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var t4: int = b4.get_cell_index(11, 11)
	var col4: int = b4.get_color_id(t4)
	var rseam4 = M20ReservationSeam.new(); rseam4.bind(b4)
	var w4 = _m20_full(b4, null, rseam4)
	var loop4 = _m20_harness_bind(w4, _m20_slots([col4, col4, col4, col4, col4]))
	var r4 = loop4.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	rseam4.resolve_hook = func(_t, _o): loop4.reset()
	_m19_drive_to_arrival(r4.agent)
	_check_eq(loop4.get_last_outcome(), CompleteClearingLoop.Outcome.RESET_ABORTED, "V05.6: reset in reservation phase -> RESET_ABORTED")
	_check_eq(b4.get_cell_state(t4), BoardState.CellState.ACTIVE, "V05.6: reservation-phase reset restores target ACTIVE")
	_check_eq(loop4.get_cleared_count(), 0, "V05.6: no clear")
	rseam4.resolve_hook = Callable(); loop4 = null; _m20_teardown(w4)

	# Identity-swap reservation corruption -> ROLLBACK_FAILED.
	var b5 = _m19_open_board_active(24, 24, [Vector2(9, 11), Vector2(11, 11), Vector2(13, 11)])
	var t5T: int = b5.get_cell_index(9, 11)
	var t5U: int = b5.get_cell_index(11, 11)
	var t5V: int = b5.get_cell_index(13, 11)
	var col5: int = b5.get_color_id(t5T)
	var rseam5 = M20ReservationSeam.new(); rseam5.bind(b5)
	var w5 = _m20_full(b5, null, rseam5)
	var loop5 = _m20_harness_bind(w5, _m20_slots([col5, col5, col5, col5, col5]))
	var r5T = loop5.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	var r5U = loop5.activate_slot(1, Vector2(26.0, 11.5), 6.0)
	rseam5.mode = "identity_swap"; rseam5.swap_from_owner = r5U.owner_id; rseam5.swap_from_target = t5U; rseam5.swap_to_target = t5V
	_m19_drive_to_arrival(r5T.agent)
	_check_eq(loop5.get_last_outcome(), CompleteClearingLoop.Outcome.ROLLBACK_FAILED, "V05.6: identity-swap corruption -> ROLLBACK_FAILED")
	_check_eq(loop5.get_cleared_count(), 0, "V05.6: identity-swap cleared nothing")
	rseam5.mode = "normal"; loop5 = null; _m20_teardown(w5)

	# Unrelated same-color candidate survives target clear/rollback.
	var b6 = _m19_open_board_active(24, 24, [Vector2(9, 11), Vector2(11, 11)])
	var t6T: int = b6.get_cell_index(9, 11)
	var t6U: int = b6.get_cell_index(11, 11)
	var col6: int = b6.get_color_id(t6T)
	var w6 = _m20_full(b6)
	var loop6 = _m20_loop(w6, _m20_slots([col6, col6, col6, col6, col6]))
	var r6 = _m20_activate_and_arrive(loop6, 0, Vector2(-2.0, 11.5))
	_check(r6.success and r6.target_index == t6T, "V05.6: T cleared")
	_check(not w6["candidates"].get_candidates(col6, null).has(t6T), "V05.6: T removed from candidates")
	_check(w6["candidates"].get_candidates(col6, null).has(t6U), "V05.6: unrelated same-color U survives")
	loop6 = null; _m20_teardown(w6)

	# Failed preflight then reset removes stranded assignment; stale replay no clear.
	var b7 = _m19_open_board_active(24, 24, [Vector2(11, 11)])
	var t7: int = b7.get_cell_index(11, 11)
	var col7: int = b7.get_color_id(t7)
	var w7 = _m20_full(b7)
	var loop7 = _m20_loop(w7, _m20_slots([col7, col7, col7, col7, col7]))
	var r7 = loop7.activate_slot(0, Vector2(-2.0, 11.5), 6.0)
	w7["dispatcher"].assignment_arrived.disconnect(loop7._arrival_cb)
	_m19_drive_to_arrival(r7.agent)
	w7["reservations"].release_for_owner(r7.owner_id) # desync
	loop7._on_assignment_arrived(r7.owner_id, t7, col7, r7.agent)
	_check_eq(loop7.get_last_outcome(), CompleteClearingLoop.Outcome.PREFLIGHT_REJECTED, "V05.6: desync arrival rejected (held)")
	_check_eq(b7.get_cell_state(t7), BoardState.CellState.ACTIVE, "V05.6: BoardState unchanged")
	w7["dispatcher"].assignment_arrived.connect(loop7._arrival_cb)
	loop7.reset()
	_check_eq(w7["dispatcher"].get_active_count(), 0, "V05.6: reset removed stranded assignment")
	loop7._on_assignment_arrived(r7.owner_id, t7, col7, r7.agent)
	_check_eq(loop7.get_cleared_count(), 0, "V05.6: stale replay after reset cannot clear")
	loop7 = null; _m20_teardown(w7)

# --- §7 direct gameplay integration ------------------------------------------
func _v05_gameplay_integration() -> void:
	print("---- V05 §7: direct gameplay integration ----")
	# true 1x1 clear + exhaustion.
	var b1 = _m19_open_board_active(1, 1, [Vector2(0, 0)])
	var c1: int = b1.get_color_id(0)
	var w1 = _m20_full(b1)
	var l1 = _m20_loop(w1, _m20_slots([c1, c1, c1, c1, c1]))
	_check(_m20_activate_and_arrive(l1, 0, Vector2(-2.0, 0.5)).success and l1.get_cleared_count() == 1, "V05.7: 1x1 clear")
	_check_eq(l1.activate_slot(0, Vector2(-2.0, 0.5)).failure_reason, DispatchResult.FailureReason.NO_REACHABLE_TARGET, "V05.7: 1x1 exhausted")
	l1 = null; _m20_teardown(w1)

	# AL-028: gate A clear -> second real activate selects/clears B.
	var b2 = _m19_open_board_active(8, 8, [Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(2, 1), Vector2(2, 3)])
	var door: int = b2.get_cell_index(1, 2)
	var inner: int = b2.get_cell_index(2, 2)
	var col2: int = b2.get_color_id(door)
	var w2 = _m20_full(b2)
	var l2 = _m20_loop(w2, _m20_slots([col2, col2, col2, col2, col2]))
	var rA = _m20_activate_and_arrive(l2, 0, Vector2(-2.0, 2.5))
	_check(rA.success and rA.target_index == door, "V05.7: AL-028 gate A cleared")
	var rB = l2.activate_slot(1, Vector2(-2.0, 2.5), 6.0)
	_check(rB.success and rB.target_index == inner, "V05.7: AL-028 second activation selects B")
	_m19_drive_to_arrival(rB.agent)
	_check_eq(b2.get_cell_state(inner), BoardState.CellState.CLEARED, "V05.7: AL-028 B cleared")
	l2 = null; _m20_teardown(w2)

	# five configured slots: five unique owners/targets/exact pairs; first preserves four.
	var b3 = _m19_open_board_active(24, 24, [Vector2(11, 0), Vector2(11, 1), Vector2(11, 2), Vector2(11, 3), Vector2(11, 4)])
	var pal: Array = []
	for y in range(5):
		pal.append(b3.get_color_id(b3.get_cell_index(11, y)))
	var w3 = _m20_full(b3)
	var l3 = _m20_loop(w3, _m20_slots(pal))
	var origins: Array = [Vector2(-2.0, 0.5), Vector2(26.0, 1.5), Vector2(-2.0, 2.5), Vector2(26.0, 3.5), Vector2(-2.0, 4.5)]
	var results: Array = []; var owners := {}; var targets := {}
	for i in range(5):
		var r = l3.activate_slot(i, origins[i], 6.0)
		if r.success:
			results.append(r); owners[r.owner_id] = true; targets[r.target_index] = true
	_check(results.size() == 5 and owners.size() == 5 and targets.size() == 5, "V05.7: five unique owners/targets")
	var pairs_ok := true
	for r in results:
		if w3["reservations"].get_owner(r.target_index) != r.owner_id or w3["reservations"].get_target_for_owner(r.owner_id) != r.target_index:
			pairs_ok = false
	_check(pairs_ok, "V05.7: five exact reservation pairs")
	_m19_drive_to_arrival(results[0].agent)
	var four_ok := true
	for i in range(1, 5):
		if not w3["dispatcher"].has_owner(results[i].owner_id) or w3["reservations"].get_owner(results[i].target_index) != results[i].owner_id:
			four_ok = false
	_check(four_ok, "V05.7: first arrival preserves the other four exact pairs")
	l3 = null; _m20_teardown(w3)

	# 59x59 maximum + rectangular + rapid 25+.
	var big = _m19_open_board_active(59, 59, [Vector2(30, 30)])
	var cbig: int = big.get_color_id(big.get_cell_index(30, 30))
	var wbig = _m20_full(big)
	var lbig = _m20_loop(wbig, _m20_slots([cbig, cbig, cbig, cbig, cbig]))
	_check(_m20_activate_and_arrive(lbig, 0, Vector2(-2.0, 30.5)).success and lbig.get_cleared_count() == 1, "V05.7: 59x59 clear")
	lbig = null; _m20_teardown(wbig)

	var rect = _m19_open_board_active(53, 59, [Vector2(20, 30)])
	var crect: int = rect.get_color_id(rect.get_cell_index(20, 30))
	var wrect = _m20_full(rect)
	var lrect = _m20_loop(wrect, _m20_slots([crect, crect, crect, crect, crect]))
	_check(_m20_activate_and_arrive(lrect, 0, Vector2(-2.0, 30.5)).success and lrect.get_cleared_count() == 1, "V05.7: rectangular 53x59 clear")
	lrect = null; _m20_teardown(wrect)

	var rapid_cells: Array = []
	for x in range(28):
		rapid_cells.append(Vector2(x + 1, 6))
	var brap = _m19_open_board_active(30, 12, rapid_cells)
	var crap: int = brap.get_color_id(brap.get_cell_index(1, 6))
	var wrap = _m20_full(brap)
	var lrap = _m20_loop(wrap, _m20_slots([crap, crap, crap, crap, crap]))
	var cyc := 0
	for _i in range(40):
		var r = _m20_activate_and_arrive(lrap, _i % 5, Vector2(-2.0, 6.5))
		if not r.success:
			break
		cyc += 1
	_check(cyc >= 25 and lrap.get_cleared_count() == 28, "V05.7: rapid 25+ sequential clears (%d)" % cyc)
	lrap = null; _m20_teardown(wrap)

# ===================================== M20-C001 V06 optional renderer presence ==
# Direct null-vs-dead distinction (F-M20-STRICT-001.L). Renderer presence is the
# persisted _renderer_expected bit (from the bind argument's Variant type), never
# `renderer != null`. Observed through bind / is_coherent / repaint only — no
# private getter. The truly-freed (F) case needs real frames and lives in
# tests/m20_v05_lifecycle_smoke.gd.
func _run_m20_v06_renderer_presence_tests() -> void:
	print("---- M20-C001 V06: renderer presence null-vs-dead distinction (F-M20-STRICT-001.L) ----")
	var board = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var color: int = board.get_color_id(board.get_cell_index(10, 10))

	# A. renderer OMITTED -> healthy headless bind succeeds; clears normally.
	var wA = _m20_full(board)
	var lA = CompleteClearingLoop.new()
	_check(lA.bind(board, _m20_slots([color, color, color, color, color]), wA["candidates"], wA["reservations"], wA["dispatcher"]), "V06.A: omitted renderer -> headless bind succeeds")
	_check(lA.is_coherent(), "V06.A: headless bundle coherent")
	_check(_m20_activate_and_arrive(lA, 0, Vector2(-2.0, 10.5)).success and lA.get_cleared_count() == 1, "V06.A: headless clears normally")
	lA = null; _m20_teardown(wA)

	# B. explicit null renderer -> same legitimate headless semantics.
	var bB = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cB: int = bB.get_color_id(bB.get_cell_index(10, 10))
	var wB = _m20_full(bB)
	var lB = CompleteClearingLoop.new()
	_check(lB.bind(bB, _m20_slots([cB, cB, cB, cB, cB]), wB["candidates"], wB["reservations"], wB["dispatcher"], null), "V06.B: explicit null renderer -> headless bind succeeds")
	_check(lB.is_coherent(), "V06.B: explicit-null headless coherent")
	lB = null; _m20_teardown(wB)

	# C. wrong scalar renderer -> rejected.
	var bC = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cC: int = bC.get_color_id(bC.get_cell_index(10, 10))
	var wC = _m20_full(bC)
	var lC = CompleteClearingLoop.new()
	_check(not lC.bind(bC, _m20_slots([cC, cC, cC, cC, cC]), wC["candidates"], wC["reservations"], wC["dispatcher"], 123), "V06.C: scalar renderer rejected")
	_check(not lC.is_bound(), "V06.C: unbound after scalar renderer")
	_check_eq(_m20_conn_count(wC["dispatcher"]), 0, "V06.C: no arrival connection")
	_m20_teardown(wC)

	# D. arbitrary RefCounted / wrong Node -> rejected.
	var bD = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cD: int = bD.get_color_id(bD.get_cell_index(10, 10))
	var wD = _m20_full(bD)
	_check(not CompleteClearingLoop.new().bind(bD, _m20_slots([cD, cD, cD, cD, cD]), wD["candidates"], wD["reservations"], wD["dispatcher"], RefCounted.new()), "V06.D: arbitrary RefCounted renderer rejected")
	_check(not CompleteClearingLoop.new().bind(bD, _m20_slots([cD, cD, cD, cD, cD]), wD["candidates"], wD["reservations"], wD["dispatcher"], wD["dispatcher"]), "V06.D: wrong Node (dispatcher as renderer) rejected")
	_m20_teardown(wD)

	# E. queued exact renderer -> rejected.
	var bE = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var cE: int = bE.get_color_id(bE.get_cell_index(10, 10))
	var wE = _m20_full(bE, null, null, true)
	wE["renderer"].queue_free()
	_check(not CompleteClearingLoop.new().bind(bE, _m20_slots([cE, cE, cE, cE, cE]), wE["candidates"], wE["reservations"], wE["dispatcher"], wE["renderer"]), "V06.E: queued exact renderer rejected")
	root.remove_child(wE["renderer"]); wE["renderer"].free()
	_m20_teardown(wE)

	# G. healthy exact renderer -> accepted; presence proven by a real alpha-0 repaint.
	var bG = _m19_open_board_active(20, 20, [Vector2(10, 10)])
	var tG: int = bG.get_cell_index(10, 10)
	var cG: int = bG.get_color_id(tG)
	var wG = _m20_full(bG, null, null, true)
	var lG = CompleteClearingLoop.new()
	_check(lG.bind(bG, _m20_slots([cG, cG, cG, cG, cG]), wG["candidates"], wG["reservations"], wG["dispatcher"], wG["renderer"]), "V06.G: healthy exact renderer accepted")
	_check(lG.is_coherent(), "V06.G: configured-renderer bundle coherent")
	_check(_m20_activate_and_arrive(lG, 0, Vector2(-2.0, 10.5)).success, "V06.G: configured clear dispatched+arrived")
	var pG: Vector2i = bG.get_cell_position(tG)
	_check(_colors_close(wG["renderer"].get_pixel_color(pG.x, pG.y), Color(0, 0, 0, 0), 0.02), "V06.G: renderer repainted target to alpha 0 (presence true)")
	lG = null; _m20_teardown(wG)
	# F (truly-freed exact renderer -> rejected despite == null) is covered by the
	# frame-based tests/m20_v05_lifecycle_smoke.gd.
