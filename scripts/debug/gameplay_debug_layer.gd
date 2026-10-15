extends Node2D
## GameplayDebugLayer — preload (res://scripts/debug/gameplay_debug_layer.gd).
##
## M45 (SB-M45-012..014) — DEVELOPER-ONLY board overlay: ONE Node2D placed in board-local
## cell space (the AgentLayer transform: 1 unit = 1 cell), never one node per cell. Draws, from
## existing state only:
##   - the cell grid ((W+1)+(H+1) lines);
##   - reserved-target markers at ReservationState.get_reserved_indices() cell centres;
##   - every live ScrubbotAgent's assigned route (get_route_points(), already board-local).
## It computes no target or route and mutates nothing. build_draw_model() is static so
## the content is testable headless.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

var show_grid := true
var show_targets := true
var show_routes := true
var _host = null
var _model: Dictionary = {"grid": [], "targets": [], "routes": []}

func _ready() -> void:
	name = "GameplayDebugLayer"
	z_index = 50

func bind(host) -> void:
	_host = host
	refresh()

## Pure draw description for `host` (empty lists when the host is not built).
static func build_draw_model(host, grid := true, targets := true, routes := true) -> Dictionary:
	var out := {"grid": [], "targets": [], "routes": []}
	if host == null or not is_instance_valid(host) or not host.is_built():
		return out
	var b = host.get_board()
	var w: int = b.get_width()
	var h: int = b.get_height()
	if grid:
		for x in range(w + 1):
			out["grid"].append([Vector2(x, 0), Vector2(x, h)])
		for y in range(h + 1):
			out["grid"].append([Vector2(0, y), Vector2(w, y)])
	if targets and host.get_reservations() != null:
		for idx in host.get_reservations().get_reserved_indices():
			var c: Vector2i = b.get_cell_position(idx)
			out["targets"].append({"index": idx, "center": Vector2(c.x + 0.5, c.y + 0.5)})
	if routes:
		var layer = host.get_agent_layer()
		if layer != null:
			for a in layer.get_children():
				if a is ScrubbotAgent and a.get_route_points().size() >= 2:
					out["routes"].append({"owner_id": a.owner_id, "points": a.get_route_points()})
	return out

func get_draw_model() -> Dictionary:
	return _model.duplicate(true)

func refresh() -> void:
	_model = build_draw_model(_host, show_grid, show_targets, show_routes)
	var layer = _host.get_agent_layer() if _host != null and is_instance_valid(_host) and _host.is_built() else null
	if layer != null:
		transform = layer.transform   # same origin + cell scale as the agents
	queue_redraw()

func _draw() -> void:
	var px := 1.0 / maxf(absf(scale.x), 0.0001)   # ~1 screen pixel in cell units
	for seg in _model["grid"]:
		draw_line(seg[0], seg[1], Color(1, 1, 1, 0.25), px)
	for t in _model["targets"]:
		draw_arc(t["center"], 0.42, 0.0, TAU, 16, Color(1.0, 0.25, 0.85), 2.0 * px)
	for r in _model["routes"]:
		draw_polyline(r["points"], Color(0.2, 1.0, 0.4, 0.9), 2.0 * px)
