extends Node2D
## ScrubbotAgent debug scene controller (M18, SB-M18 visual debug).
##
## Minimal, throwaway visual harness for the lightweight ScrubbotAgent: it
## builds ONE real production route (S2 detour) and watches a single agent walk
## it. This is NOT final Scrubbot art (M27) — a plain debug marker only.
##
## Presentation boundary demo: the agent moves in board-local cell units; this
## scene puts it under a scaled container Node2D so board-local units become
## screen pixels HERE, not inside the agent.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RoutingLabScenarios = preload("res://scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")

const CELL_PX := 14.0

var agent
var completed := false
var _container: Node2D
var _label: Label
var _route_points: PackedVector2Array

func _ready() -> void:
	build()

## Public so the headless smoke test can drive it without pumping frames.
func build() -> void:
	var s2 := RoutingLabScenarios.make_s2()
	var board = s2["board"]
	var access = ProductionAccessQuery.new(board)
	var req = RoutingLabScenarios.build_requests(board, s2["targets"], s2["origins"])[0]
	var route = ProductionRoutingSystem.new().compute_route(req, board, access)
	_route_points = route.get_points()

	_container = Node2D.new()
	_container.position = Vector2(140.0, 90.0)
	_container.scale = Vector2(CELL_PX, CELL_PX)
	add_child(_container)

	agent = ScrubbotAgent.new()
	agent.agent_completed.connect(_on_completed)
	_container.add_child(agent)
	agent.assign(0, 3, req, route, 6.0)

	_label = Label.new()
	_label.position = Vector2(16.0, 12.0)
	add_child(_label)
	_update_label()
	queue_redraw()

func _process(_dt: float) -> void:
	_update_label()

## Draw the route polyline (board-local) under the same scaled container frame
## so the agent's path is visible behind the marker.
func _draw() -> void:
	if _route_points.size() < 2 or _container == null:
		return
	var xf := Transform2D().scaled(_container.scale)
	xf.origin = _container.position
	var prev := xf * _route_points[0]
	for i in range(1, _route_points.size()):
		var cur := xf * _route_points[i]
		draw_line(prev, cur, Color(0.3, 0.35, 0.45), 2.0)
		prev = cur

func _update_label() -> void:
	if agent == null or _label == null:
		return
	_label.text = "ScrubbotAgent debug — board-local movement, container scaled to px\nstate=%d  progress=%.2f  completed=%s" % [agent.get_state(), agent.get_progress(), str(completed)]

func _on_completed(_o: int, _t: int, _c: int) -> void:
	completed = true
