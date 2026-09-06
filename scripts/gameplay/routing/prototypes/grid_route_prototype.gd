extends "res://scripts/gameplay/routing/routing_system.gd"
## GridRoutePrototype — M17 Prototype B. EXPERIMENTAL grid-aware route.
## Preload it (AL-001). Subclasses RoutingSystem (M16 contract): it answers HOW
## for the already-assigned target only, never WHAT. It never retargets, never
## calls TargetSelector, never mutates BoardState or ReservationState.
##
## EXPERIMENTAL topology (documented, NOT canonical — the owner design gate picks
## the final movement language):
##   - orthogonal 4-neighbour movement on the board-local cell-center lattice;
##   - non-target ACTIVE cells block; CLEARED cells are open;
##   - the assigned ACTIVE target is allowed ONLY as the final endpoint;
##   - outside-board slot origins enter through an explicit exterior bridge:
##     the start connects to every board-perimeter OPEN cell whose straight
##     bridge segment (start -> perimeter cell center) is accepted by the
##     injected access truth. The bridge is NOT hidden — it is a real, validated
##     route segment and is exercised by tests.
##   - deterministic neighbour order (up, right, down, left) and deterministic
##     multi-source order (ascending cell index) so identical BoardState +
##     RouteRequest always yield identical points.
##
## Pathfinding is a plain deterministic BFS (fewest in-board cell steps). BFS is
## enough for an experimental prototype and gives full control over tie-breaks;
## it is deliberately not AStarGrid2D (whose internal tie-breaks are opaque).
##
## The injected access_query must expose the experimental cell-topology seam
## `classify_cell(cx, cy, target_index)` (PrototypeAccessQuery) in addition to
## the M16 `is_segment_traversable`. RouteValidator independently re-checks every
## emitted segment through is_segment_traversable, so a success always passes the
## shared validator.

const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const PrototypeAccessQuery = preload("res://scripts/gameplay/routing/prototypes/prototype_access_query.gd")

## Deterministic 4-neighbour order: up, right, down, left.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

## Cap on exterior entry cells (nearest-first). Bounds the bridge-scan cost so
## the CPU metric reflects pathfinding, not perimeter scanning.
const MAX_ENTRIES := 12

func compute_route(request, board, access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var idx: int = request.target_index
	var req_reason: StringName = RouteValidator.validate_request(request, board)
	if req_reason != RouteResult.FailureReason.NONE:
		return RouteResult.failure(req_reason, idx)
	if access_query == null or not access_query.has_method("is_segment_traversable"):
		return RouteResult.failure(RouteResult.FailureReason.MISSING_ACCESS_QUERY, idx)

	var cell_path: Array = _bfs_cell_path(request, board, access_query)
	if cell_path.is_empty():
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	# Build board-local points: start origin, then each cell center.
	var points := PackedVector2Array()
	points.append(request.start_position)
	for c in cell_path:
		points.append(Vector2(float(c.x) + 0.5, float(c.y) + 0.5))
	return RouteResult.success_route(idx, points)

## Deterministic multi-source BFS from validated exterior entry cells to the
## target cell. Returns the cell path (Array[Vector2i]) ending at the target
## cell, or [] on no route.
func _bfs_cell_path(request, board, access_query) -> Array:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var idx: int = request.target_index
	var target_cell: Vector2i = board.get_cell_position(idx)
	var target_center := Vector2(float(target_cell.x) + 0.5, float(target_cell.y) + 0.5)

	# classify_cell seam is required for the experimental lattice.
	var classify := func(cx: int, cy: int) -> int:
		return access_query.classify_cell(cx, cy, idx)

	# Exterior entries: perimeter OPEN cells reachable by a straight bridge from
	# start, plus the start's own cell if it is inside and open.
	var parent: Dictionary = {} # Vector2i -> Vector2i (or start sentinel)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	var START := Vector2i(-2147483647, -2147483647) # sentinel: bridged from origin

	var start_cell: Vector2i
	if access_query.has_method("cell_of_point"):
		start_cell = access_query.cell_of_point(request.start_position)
	else:
		start_cell = Vector2i(int(floor(request.start_position.x)), int(floor(request.start_position.y)))
	var _try_entry := func(cx: int, cy: int) -> void:
		var cell := Vector2i(cx, cy)
		if visited.has(cell):
			return
		if classify.call(cx, cy) != PrototypeAccessQuery.CellClass.OPEN:
			return
		var center := Vector2(float(cx) + 0.5, float(cy) + 0.5)
		if not access_query.is_segment_traversable(request.start_position, center, idx):
			return
		visited[cell] = true
		parent[cell] = START
		queue.append(cell)

	if cx_inside(start_cell, w, h) and classify.call(start_cell.x, start_cell.y) == PrototypeAccessQuery.CellClass.OPEN:
		_try_entry.call(start_cell.x, start_cell.y)
	# Perimeter open cells, tried NEAREST-first (by center distance to start, then
	# ascending index for a deterministic tie-break) and capped at MAX_ENTRIES.
	# The bot physically enters at ONE edge cell; a handful of near entries is
	# enough for BFS to detour internally, and this bounds the exterior bridge
	# cost (a full-perimeter straight-bridge scan is O(perimeter * board) and
	# would swamp the CPU metric). Documented experimental exterior model.
	var perim: Array = []
	for y in h:
		for x in w:
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				var c := Vector2i(x, y)
				var center := Vector2(float(x) + 0.5, float(y) + 0.5)
				perim.append({"c": c, "d": request.start_position.distance_squared_to(center)})
	perim.sort_custom(func(a, b):
		if a["d"] != b["d"]:
			return a["d"] < b["d"]
		return (a["c"].y * w + a["c"].x) < (b["c"].y * w + b["c"].x))
	for entry in perim:
		if queue.size() >= MAX_ENTRIES:
			break
		var c: Vector2i = entry["c"]
		_try_entry.call(c.x, c.y)

	if queue.is_empty():
		return []

	# BFS over OPEN cells; the target cell is the goal, enterable from any OPEN
	# orthogonal neighbour as the final step.
	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		# Is the target an orthogonal neighbour? If so, finish.
		for d in NEIGHBORS:
			var n := cur + d
			if n == target_cell:
				# Validate the arrival segment (cur center -> target center).
				var cur_center := Vector2(float(cur.x) + 0.5, float(cur.y) + 0.5)
				if access_query.is_segment_traversable(cur_center, target_center, idx):
					parent[target_cell] = cur
					return _reconstruct(parent, target_cell, START)
		for d in NEIGHBORS:
			var n := cur + d
			if not cx_inside(n, w, h) or visited.has(n):
				continue
			if classify.call(n.x, n.y) != PrototypeAccessQuery.CellClass.OPEN:
				continue
			visited[n] = true
			parent[n] = cur
			queue.append(n)
	return []

func cx_inside(c: Vector2i, w: int, h: int) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h

func _reconstruct(parent: Dictionary, goal: Vector2i, start_sentinel: Vector2i) -> Array:
	var path: Array = []
	var cur: Vector2i = goal
	while cur != start_sentinel:
		path.push_front(cur)
		cur = parent[cur]
	return path
