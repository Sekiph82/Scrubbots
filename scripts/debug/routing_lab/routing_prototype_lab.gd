extends Control
## RoutingPrototypeLab — M17 debug-only Routing Prototype Lab. Preload it
## (AL-001). Composed from Godot Control containers (hard rule 46). It lets the
## owner switch between the three EXPERIMENTAL prototypes (Direct / Grid-aware /
## Organized-curved) on the same scenario and compare neutral metrics WITHOUT
## editing source code.
##
## It NEVER selects a target (targets come from RoutingLabScenarios, outside
## routing), never mutates production gameplay, and promotes no prototype. The
## owner design gate for the final movement language stays open.

const PrototypeAccessQuery = preload("res://scripts/gameplay/routing/prototypes/prototype_access_query.gd")
const DirectRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/direct_route_prototype.gd")
const GridRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/grid_route_prototype.gd")
const OrganizedRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/organized_route_prototype.gd")
const RouteMetrics = preload("res://scripts/gameplay/routing/prototypes/route_metrics.gd")
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RoutingLabOverlay = preload("res://scripts/debug/routing_lab/routing_lab_overlay.gd")

const STRATEGY_NAMES: Array[String] = ["Direct", "Grid-aware", "Organized/curved"]
const SCENARIO_IDS: Array[String] = ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8"]
const BOT_COUNTS: Array[int] = [1, 5, 10, 25, 100]

var _strategy_option: OptionButton
var _scenario_option: OptionButton
var _botcount_option: OptionButton
var _routes_check: CheckBox
var _rounding_check: CheckBox
var _s4clear_check: CheckBox
var _rebuild_button: Button
var _info_label: RichTextLabel
var _overlay: RoutingLabOverlay
var _overlay_host: Control

func _ready() -> void:
	if _info_label == null:
		_build_ui()
	_rebuild()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 8; root.offset_top = 8; root.offset_right = -8; root.offset_bottom = -8
	add_child(root)

	var controls := HBoxContainer.new()
	root.add_child(controls)

	_strategy_option = OptionButton.new()
	for s in STRATEGY_NAMES:
		_strategy_option.add_item(s)
	_strategy_option.select(0)
	_strategy_option.item_selected.connect(func(_i): _rebuild())
	controls.add_child(_labeled("Strategy", _strategy_option))

	_scenario_option = OptionButton.new()
	for id in SCENARIO_IDS:
		_scenario_option.add_item(id)
	_scenario_option.select(0)
	_scenario_option.item_selected.connect(func(_i): _rebuild())
	controls.add_child(_labeled("Scenario", _scenario_option))

	_botcount_option = OptionButton.new()
	for c in BOT_COUNTS:
		_botcount_option.add_item(str(c))
	_botcount_option.select(2) # 10
	_botcount_option.item_selected.connect(func(_i): _rebuild())
	controls.add_child(_labeled("Bots", _botcount_option))

	_routes_check = CheckBox.new()
	_routes_check.text = "Show routes"
	_routes_check.button_pressed = true
	_routes_check.toggled.connect(func(_p): _rebuild())
	controls.add_child(_routes_check)

	_rounding_check = CheckBox.new()
	_rounding_check.text = "Curved rounding"
	_rounding_check.button_pressed = true
	_rounding_check.toggled.connect(func(_p): _rebuild())
	controls.add_child(_rounding_check)

	_s4clear_check = CheckBox.new()
	_s4clear_check.text = "Apply S4 clear"
	_s4clear_check.button_pressed = false
	_s4clear_check.toggled.connect(func(_p): _rebuild())
	controls.add_child(_s4clear_check)

	_rebuild_button = Button.new()
	_rebuild_button.text = "Rebuild"
	_rebuild_button.pressed.connect(_rebuild)
	controls.add_child(_rebuild_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_overlay_host = Control.new()
	_overlay_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay_host.clip_contents = true
	body.add_child(_overlay_host)

	_overlay = RoutingLabOverlay.new()
	_overlay_host.add_child(_overlay)

	_info_label = RichTextLabel.new()
	_info_label.custom_minimum_size = Vector2(360, 0)
	_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_label.bbcode_enabled = false
	body.add_child(_info_label)

func _labeled(text: String, control: Control) -> Control:
	var box := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = text
	box.add_child(lbl)
	box.add_child(control)
	return box

func _build_scenario(id: String, count: int) -> Dictionary:
	match id:
		"S1": return RoutingLabScenarios.make_s1()
		"S2": return RoutingLabScenarios.make_s2()
		"S3": return RoutingLabScenarios.make_s3()
		"S4": return RoutingLabScenarios.make_s4()
		"S5": return RoutingLabScenarios.make_s5(count)
		"S6": return RoutingLabScenarios.make_s6(count)
		"S7": return RoutingLabScenarios.make_s7(count)
		"S8": return RoutingLabScenarios.make_s8(count)
	return RoutingLabScenarios.make_s1()

func _make_strategy(index: int):
	match index:
		0: return DirectRoutePrototype.new()
		1: return GridRoutePrototype.new()
		2:
			var org := OrganizedRoutePrototype.new()
			org.enable_rounding = _rounding_check.button_pressed if _rounding_check != null else true
			return org
	return DirectRoutePrototype.new()

## Recompute a route set for the current selections and refresh the display.
## Public so a headless smoke test can drive it deterministically.
func _rebuild() -> void:
	var strat_idx: int = _strategy_option.selected
	var id: String = SCENARIO_IDS[_scenario_option.selected]
	var count: int = BOT_COUNTS[_botcount_option.selected]
	var scenario := _build_scenario(id, count)
	var board = scenario["board"]
	var targets: Array = scenario["targets"]
	var origins: Array = scenario["origins"]

	if _s4clear_check != null and _s4clear_check.button_pressed and scenario.has("clear_after"):
		for idx in scenario["clear_after"]:
			board.set_cell_state(int(idx), 1) # CLEARED

	var access = PrototypeAccessQuery.new(board)
	var requests: Array = RoutingLabScenarios.build_requests(board, targets, origins)
	var strategy = _make_strategy(strat_idx)

	# Compute pass 1 (record all results, empty points on failure for alignment).
	var all_pts_1: Array = []
	var success_pts: Array = []
	var success: int = 0
	var no_route: int = 0
	var other_fail: int = 0
	var validated: int = 0
	for req in requests:
		var res = strategy.compute_route(req, board, access)
		if res.success:
			var pts: PackedVector2Array = res.get_points()
			all_pts_1.append(pts)
			success_pts.append(pts)
			success += 1
			# Confirm each success passes the shared M16 validator.
			if RouteValidator.validate_route(req, res, board, access) == RouteResult.FailureReason.NONE:
				validated += 1
		else:
			all_pts_1.append(PackedVector2Array())
			if res.failure_reason == RouteResult.FailureReason.NO_ROUTE:
				no_route += 1
			else:
				other_fail += 1

	# Determinism: recompute and compare exact points.
	var all_pts_2: Array = []
	for req in requests:
		var res2 = strategy.compute_route(req, board, access)
		all_pts_2.append(res2.get_points() if res2.success else PackedVector2Array())
	var det: Dictionary = RouteMetrics.route_sets_identical(all_pts_1, all_pts_2)

	var dist: Dictionary = RouteMetrics.distance_stats(success_pts)
	var cross: int = RouteMetrics.crossing_count(success_pts)
	var cong: Dictionary = RouteMetrics.congestion(success_pts)
	var cpu: Dictionary = RouteMetrics.cpu_benchmark(strategy, requests, board, access, 3)

	# Overlay data.
	var target_cells: Dictionary = {}
	for t in targets:
		var p: Vector2i = board.get_cell_position(int(t))
		target_cells[p] = true
	_overlay.show_routes = _routes_check.button_pressed if _routes_check != null else true
	_overlay.set_data(board, target_cells, success_pts)
	var host_size: Vector2 = _overlay_host.size if _overlay_host != null else Vector2(600, 600)
	if host_size.x < 50:
		host_size = Vector2(600, 600)
	_overlay.fit_to(host_size)

	_info_label.text = _format_info(
		strat_idx, scenario, count, requests.size(),
		success, no_route, other_fail, validated,
		dist, cross, cong, cpu, det)

func _format_info(strat_idx: int, scenario: Dictionary, count: int, req_n: int,
		success: int, no_route: int, other_fail: int, validated: int,
		dist: Dictionary, cross: int, cong: Dictionary, cpu: Dictionary, det: Dictionary) -> String:
	var board = scenario["board"]
	var lines: Array = []
	lines.append("STRATEGY: %s" % STRATEGY_NAMES[strat_idx])
	if strat_idx == 2:
		var rounding: bool = _rounding_check.button_pressed if _rounding_check != null else true
		lines.append("  params: rounding=%s radius=0.35 samples=3 shortcut=on" % ("on" if rounding else "off"))
	lines.append("SCENARIO: %s — %s" % [scenario["id"], scenario["name"]])
	lines.append("  %s" % scenario.get("notes", ""))
	lines.append("  board: %dx%d  bots(sel): %d" % [board.get_width(), board.get_height(), count])
	lines.append("")
	lines.append("ROUTES: requests=%d" % req_n)
	lines.append("  success=%d  no_route=%d  other_fail=%d" % [success, no_route, other_fail])
	lines.append("  validated(shared RouteValidator)=%d/%d" % [validated, success])
	lines.append("")
	lines.append("DISTANCE (cell units):")
	lines.append("  count=%d total=%.2f mean=%.2f median=%.2f" % [dist["count"], dist["total"], dist["mean"], dist["median"]])
	lines.append("CROSSINGS (proper, shared endpoints excluded): %d" % cross)
	lines.append("CONGESTION:")
	lines.append("  occupied=%d max_overlap=%d total_repeated=%d" % [cong["occupied_buckets"], cong["max_overlap"], cong["total_repeated"]])
	lines.append("CPU (route computation only, no FPS/GPU):")
	lines.append("  calls=%d total_us=%d mean_us=%.2f (samples=%d)" % [cpu["calls"], cpu["total_us"], cpu["mean_us"], cpu["samples"]])
	lines.append("DETERMINISM: identical=%s" % str(det["identical"]))
	lines.append("")
	lines.append("Neutral comparison only — no winner declared.")
	lines.append("Owner picks the final movement language.")
	return "\n".join(lines)
