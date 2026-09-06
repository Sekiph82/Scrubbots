extends "res://scripts/gameplay/routing/routing_system.gd"
## ProductionRoutingSystem — the owner-selected PRODUCTION routing (M17-C002,
## OWNER_MOVEMENT_DECISION_V01 "OWNER_SELECTS_ORGANIZED"). Preload it (AL-001).
## Subclasses the M16 RoutingSystem contract (ADR-024): answers HOW for the
## already-assigned target only. Never selects WHAT, never retargets, never calls
## TargetSelector, never mutates BoardState or ReservationState.
##
## Owner-selected architecture (ADR-025):
##   backbone  = deterministic grid-aware planner (establishes valid
##               reachability + a valid orthogonal path);
##   language  = organized/curved post-process on that valid path (movement
##               language), which NEVER invents reachability — every emitted
##               segment is re-checked through the injected access truth, and any
##               shortcut/curve that fails falls back to the last valid section.
##
## This lives in PRODUCTION scope (outside prototypes/). It does not import the
## experimental M17 prototype scripts; those remain only for the diagnostic lab.
##
## Conservative production defaults (owner tuning preference): bounded local
## shortcuts (not board-spanning diagonals) and a smaller corner radius than the
## experimental Organized prototype, so dense scenes read as controlled bends
## rather than a chaotic diagonal web. Route validity is never sacrificed for
## aesthetics.
##
## The injected access_query must expose classify_cell/cell_of_point (the cell
## topology seam) plus the M16 is_segment_traversable — ProductionAccessQuery
## satisfies this. RouteValidator independently re-checks every emitted segment.

const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")

## Deterministic 4-neighbour order: up, right, down, left.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

## Cap on exterior entry cells (nearest-first). Bounds bridge-scan cost.
const MAX_ENTRIES := 12

const _COLLINEAR_EPS := 0.0001

## --- Conservative production movement-language defaults (ADR-025) ---
## Maximum vertices a shortcut may skip ahead. Bounded so shortcuts smooth local
## zig-zags without collapsing the path into long board-spanning diagonals.
## (The experimental Organized prototype used an UNBOUNDED greedy shortcut.)
var max_shortcut_span: int = 2
## Corner cut length in cell units (clamped to half of each adjacent segment).
## Smaller than the experimental prototype's 0.35 for controlled, readable curves.
var corner_radius: float = 0.25
## Interior samples per rounded corner.
var corner_samples: int = 3
## Rounding is part of the selected movement language; on by default.
var enable_rounding: bool = true

func compute_route(request, board, access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var idx: int = request.target_index
	var req_reason: StringName = RouteValidator.validate_request(request, board)
	if req_reason != RouteResult.FailureReason.NONE:
		return RouteResult.failure(req_reason, idx)
	if access_query == null or not access_query.has_method("is_segment_traversable") \
			or not access_query.has_method("classify_cell"):
		return RouteResult.failure(RouteResult.FailureReason.MISSING_ACCESS_QUERY, idx)

	# Backbone: deterministic grid-aware reachability/path.
	var cell_path: Array = _bfs_cell_path(request, board, access_query)
	if cell_path.is_empty():
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	var pts := PackedVector2Array()
	pts.append(request.start_position)
	for c in cell_path:
		pts.append(Vector2(float(c.x) + 0.5, float(c.y) + 0.5))

	# Movement language: organized/curved post-process (validity-preserving).
	pts = _remove_collinear(pts)
	pts = _bounded_shortcut(pts, access_query, idx)
	if enable_rounding:
		pts = _round_corners(pts, access_query, idx)
	return RouteResult.success_route(idx, pts)

# ------------------------------------------------------- grid-aware backbone --

func _bfs_cell_path(request, board, access_query) -> Array:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var idx: int = request.target_index
	var target_cell: Vector2i = board.get_cell_position(idx)
	var target_center := Vector2(float(target_cell.x) + 0.5, float(target_cell.y) + 0.5)

	var classify := func(cx: int, cy: int) -> int:
		return access_query.classify_cell(cx, cy, idx)

	var parent: Dictionary = {}
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	var START := Vector2i(-2147483647, -2147483647)

	var start_cell: Vector2i = access_query.cell_of_point(request.start_position)
	var _try_entry := func(cx: int, cy: int) -> void:
		var cell := Vector2i(cx, cy)
		if visited.has(cell):
			return
		if classify.call(cx, cy) != ProductionAccessQuery.CellClass.OPEN:
			return
		var center := Vector2(float(cx) + 0.5, float(cy) + 0.5)
		if not access_query.is_segment_traversable(request.start_position, center, idx):
			return
		visited[cell] = true
		parent[cell] = START
		queue.append(cell)

	if _inside(start_cell, w, h) and classify.call(start_cell.x, start_cell.y) == ProductionAccessQuery.CellClass.OPEN:
		_try_entry.call(start_cell.x, start_cell.y)
	# Nearest-first, capped exterior perimeter bridge (deterministic).
	var perim: Array = []
	for y in h:
		for x in w:
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				var center := Vector2(float(x) + 0.5, float(y) + 0.5)
				perim.append({"c": Vector2i(x, y), "d": request.start_position.distance_squared_to(center)})
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

	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for d in NEIGHBORS:
			if cur + d == target_cell:
				var cur_center := Vector2(float(cur.x) + 0.5, float(cur.y) + 0.5)
				if access_query.is_segment_traversable(cur_center, target_center, idx):
					parent[target_cell] = cur
					return _reconstruct(parent, target_cell, START)
		for d in NEIGHBORS:
			var n := cur + d
			if not _inside(n, w, h) or visited.has(n):
				continue
			if classify.call(n.x, n.y) != ProductionAccessQuery.CellClass.OPEN:
				continue
			visited[n] = true
			parent[n] = cur
			queue.append(n)
	return []

func _inside(c: Vector2i, w: int, h: int) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h

func _reconstruct(parent: Dictionary, goal: Vector2i, start_sentinel: Vector2i) -> Array:
	var path: Array = []
	var cur: Vector2i = goal
	while cur != start_sentinel:
		path.push_front(cur)
		cur = parent[cur]
	return path

# ------------------------------------------- organized/curved movement layer --

func _remove_collinear(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var a: Vector2 = out[out.size() - 1]
		var m: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var cross: float = (m.x - a.x) * (b.y - a.y) - (m.y - a.y) * (b.x - a.x)
		if absf(cross) > _COLLINEAR_EPS:
			out.append(m)
	out.append(points[points.size() - 1])
	return out

## Conservative shortcut: from each point, jump to the farthest valid point
## within a BOUNDED span (max_shortcut_span vertices ahead). Bounding the span is
## what keeps production readable — it removes local zig-zags without producing
## long board-spanning diagonals. Invalid jumps are skipped (progress guaranteed).
func _bounded_shortcut(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	if points.size() <= 2 or max_shortcut_span <= 1:
		return points
	var out := PackedVector2Array([points[0]])
	var i: int = 0
	var last: int = points.size() - 1
	while i < last:
		var next: int = i + 1
		var limit: int = mini(last, i + max_shortcut_span)
		for j in range(limit, i + 1, -1):
			if access_query.is_segment_traversable(points[i], points[j], idx):
				next = j
				break
		out.append(points[next])
		i = next
	return out

## Replace sharp interior corners with quadratic-bezier arcs bulging toward the
## corner. Arc interior segments are validated; a corner falls back to sharp if
## any arc segment is rejected. Endpoints are never moved. Connecting segments are
## sub-segments of already-valid path segments, so they stay valid.
func _round_corners(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	if points.size() <= 2 or corner_samples < 1:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var a: Vector2 = points[i - 1]
		var v: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var cut: float = minf(corner_radius, minf(a.distance_to(v) * 0.5, v.distance_to(b) * 0.5))
		if cut <= _COLLINEAR_EPS:
			out.append(v)
			continue
		var p1: Vector2 = v + (a - v).normalized() * cut
		var p2: Vector2 = v + (b - v).normalized() * cut
		var arc := PackedVector2Array([p1])
		for k in range(1, corner_samples + 1):
			var t: float = float(k) / float(corner_samples + 1)
			var omt: float = 1.0 - t
			arc.append(p1 * (omt * omt) + v * (2.0 * omt * t) + p2 * (t * t))
		arc.append(p2)
		var arc_ok: bool = true
		for s in range(arc.size() - 1):
			if not access_query.is_segment_traversable(arc[s], arc[s + 1], idx):
				arc_ok = false
				break
		if arc_ok:
			for pt in arc:
				out.append(pt)
		else:
			out.append(v)
	out.append(points[points.size() - 1])
	return out
