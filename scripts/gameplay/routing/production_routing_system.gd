extends "res://scripts/gameplay/routing/routing_system.gd"
## ProductionRoutingSystem — owner-selected PRODUCTION routing (M17-C002,
## OWNER_MOVEMENT_DECISION_V01 "OWNER_SELECTS_ORGANIZED"). Preload it (AL-001).
## Subclasses the M16 RoutingSystem contract (ADR-024): answers HOW for the
## already-assigned target only. Never selects WHAT, never retargets, never calls
## TargetSelector, never mutates BoardState or ReservationState.
##
## Owner-selected architecture (ADR-025):
##   backbone  = deterministic grid-aware planner (valid reachability + orthogonal
##               path). COMPLETE exterior reachability — no correctness-affecting
##               entry cap (M17-C002 V03 F-M17-STRICT-001) — plus direct final
##               arrival to a perimeter target (F-M17-STRICT-008).
##   language  = organized/curved post-process (bounded shortcut + controlled
##               corner rounding). Conservative production defaults.
##
## Hardened boundary (V03 F-M17-STRICT-003..007,009):
##   - the request must be a real RouteRequest before any field is read;
##   - the access_query must be an object exposing the COMPLETE seam
##     (is_segment_traversable, classify_cell, cell_of_point, is_bound_to) and
##     return the correct types; every returned verdict is validated before trust;
##   - the access must be exact-bound to the same board (is_bound_to);
##   - EVERY used planning edge is confirmed traversable by segment access truth
##     (not inferred from cell class alone);
##   - the post-process is self-validating: each stage keeps the last route that
##     passes the shared RouteValidator, and the returned success is
##     RouteValidator-clean INSIDE compute_route — never a success the external
##     validator would reject;
##   - invalid tuning (non-finite/negative) degrades safely, never producing
##     non-finite success points.
##
## Production is independent of the experimental M17 prototypes (kept only for the
## diagnostic lab). Direct straight routing is debug-only, never production.

const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")

## Deterministic 4-neighbour order: up, right, down, left.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

const _COLLINEAR_EPS := 0.0001

## --- Conservative production movement-language defaults (ADR-025) ---
var max_shortcut_span: int = 2
var corner_radius: float = 0.25
var corner_samples: int = 3
var enable_rounding: bool = true

func compute_route(request, board, access_query) -> RefCounted:
	# F-006: require a real RouteRequest BEFORE reading any field (a scalar/junk
	# Variant must not fault). RouteValidator reads request fields, so guard first.
	if not (request is RouteRequest):
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var idx: int = request.target_index

	var req_reason: StringName = RouteValidator.validate_request(request, board)
	if req_reason != RouteResult.FailureReason.NONE:
		return RouteResult.failure(req_reason, idx)

	# F-004/F-005/F-006: object-shaped access + complete seam + correct return
	# types + exact board coherence, all before any route work.
	if not _access_seam_valid(access_query, board, idx):
		return RouteResult.failure(RouteResult.FailureReason.MISSING_ACCESS_QUERY, idx)

	# Backbone: complete deterministic grid-aware reachability/path.
	var cell_path: Array = _bfs_cell_path(request, board, access_query)
	var target_center: Vector2 = RouteRequest.center_of_index(board, idx)
	if cell_path.is_empty():
		# F-008: direct final arrival to a (e.g. perimeter) target when the
		# straight exterior segment is itself valid and no cell path exists.
		if _seg_true(access_query, request.start_position, target_center, idx):
			cell_path = [board.get_cell_position(idx)]
		else:
			return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	var raw := PackedVector2Array()
	raw.append(request.start_position)
	for c in cell_path:
		raw.append(Vector2(float(c.x) + 0.5, float(c.y) + 0.5))

	# F-003: the raw backbone route must itself be RouteValidator-clean.
	if not _whole_route_valid(request, raw, board, access_query):
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	# Self-validating organized/curved post-process. Each stage advances only to a
	# candidate that passes WHOLE-route validation; otherwise it keeps the prior
	# valid route (F-003/§6). Invalid tuning degrades safely (F-009/§7).
	var best: PackedVector2Array = raw
	var c1 := _remove_collinear(best)
	if _whole_route_valid(request, c1, board, access_query):
		best = c1
	var c2 := _bounded_shortcut(best, access_query, idx)
	if _whole_route_valid(request, c2, board, access_query):
		best = c2
	if enable_rounding:
		var c3 := _round_corners(best, access_query, idx)
		if _whole_route_valid(request, c3, board, access_query):
			best = c3

	return RouteResult.success_route(idx, best)

# ------------------------------------------------------- seam / validation --

## Object-shaped access exposing the full seam with correct return types, and
## exact-bound to `board`. Any deviation -> fail closed (false).
func _access_seam_valid(access_query, board, idx: int) -> bool:
	if typeof(access_query) != TYPE_OBJECT:
		return false
	for m in ["is_segment_traversable", "classify_cell", "cell_of_point", "is_bound_to"]:
		if not access_query.has_method(m):
			return false
	# Exact board coherence (F-005): reject same-size different board / unbound.
	var bound = access_query.is_bound_to(board)
	if typeof(bound) != TYPE_BOOL or not bound:
		return false
	# Return-type probes (F-004): classify_cell -> canonical int, cell_of_point ->
	# Vector2i, is_segment_traversable -> bool.
	var c0 = access_query.classify_cell(0, 0, idx)
	if typeof(c0) != TYPE_INT:
		return false
	if not (c0 == ProductionAccessQuery.CellClass.OPEN \
			or c0 == ProductionAccessQuery.CellClass.BLOCKED \
			or c0 == ProductionAccessQuery.CellClass.TARGET):
		return false
	if typeof(access_query.cell_of_point(Vector2(0.5, 0.5))) != TYPE_VECTOR2I:
		return false
	if typeof(access_query.is_segment_traversable(Vector2(-9, -9), Vector2(-9, -9), idx)) != TYPE_BOOL:
		return false
	return true

## classify verdict, validated. Bad type/value -> BLOCKED (fail closed).
func _classify(access_query, cx: int, cy: int, idx: int) -> int:
	var c = access_query.classify_cell(cx, cy, idx)
	if typeof(c) != TYPE_INT:
		return ProductionAccessQuery.CellClass.BLOCKED
	if c == ProductionAccessQuery.CellClass.OPEN or c == ProductionAccessQuery.CellClass.TARGET:
		return c
	return ProductionAccessQuery.CellClass.BLOCKED

## segment verdict, validated. True ONLY on an actual bool true.
func _seg_true(access_query, a: Vector2, b: Vector2, idx: int) -> bool:
	var v = access_query.is_segment_traversable(a, b, idx)
	return typeof(v) == TYPE_BOOL and v

## Whole-route validation through the shared M16 RouteValidator.
func _whole_route_valid(request, points: PackedVector2Array, board, access_query) -> bool:
	if points.size() < 2:
		return false
	var candidate = RouteResult.success_route(request.target_index, points)
	return RouteValidator.validate_route(request, candidate, board, access_query) == RouteResult.FailureReason.NONE

# ------------------------------------------------------- grid-aware backbone --

## Complete deterministic multi-source BFS. Exterior entries = ALL perimeter OPEN
## cells with a valid start->centre bridge (nearest-first order for deterministic
## path preference; NO correctness-affecting cap), plus the start's own cell if
## inside and open. Every enqueued edge is confirmed by segment access truth.
func _bfs_cell_path(request, board, access_query) -> Array:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var idx: int = request.target_index
	var target_cell: Vector2i = board.get_cell_position(idx)
	var target_center := Vector2(float(target_cell.x) + 0.5, float(target_cell.y) + 0.5)

	var parent: Dictionary = {}
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	var START := Vector2i(-2147483647, -2147483647)

	var start_cell: Vector2i = _start_cell(request, access_query)
	var _try_entry := func(cx: int, cy: int) -> void:
		var cell := Vector2i(cx, cy)
		if visited.has(cell):
			return
		if _classify(access_query, cx, cy, idx) != ProductionAccessQuery.CellClass.OPEN:
			return
		var center := Vector2(float(cx) + 0.5, float(cy) + 0.5)
		if not _seg_true(access_query, request.start_position, center, idx):
			return
		visited[cell] = true
		parent[cell] = START
		queue.append(cell)

	if _inside(start_cell, w, h) and _classify(access_query, start_cell.x, start_cell.y, idx) == ProductionAccessQuery.CellClass.OPEN:
		_try_entry.call(start_cell.x, start_cell.y)
	# ALL perimeter cells, nearest-first (deterministic), NO cap.
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
		var c: Vector2i = entry["c"]
		_try_entry.call(c.x, c.y)

	if queue.is_empty():
		return []

	var head: int = 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		var cur_center := Vector2(float(cur.x) + 0.5, float(cur.y) + 0.5)
		# Arrival: target reachable as the final step (segment access confirmed).
		for d in NEIGHBORS:
			if cur + d == target_cell and _seg_true(access_query, cur_center, target_center, idx):
				parent[target_cell] = cur
				return _reconstruct(parent, target_cell, START)
		for d in NEIGHBORS:
			var n := cur + d
			if not _inside(n, w, h) or visited.has(n):
				continue
			if _classify(access_query, n.x, n.y, idx) != ProductionAccessQuery.CellClass.OPEN:
				continue
			# F-M17-STRICT-003/§5: the edge itself must obey segment access truth,
			# not merely the destination cell class.
			var n_center := Vector2(float(n.x) + 0.5, float(n.y) + 0.5)
			if not _seg_true(access_query, cur_center, n_center, idx):
				continue
			visited[n] = true
			parent[n] = cur
			queue.append(n)
	return []

func _start_cell(request, access_query) -> Vector2i:
	var p = access_query.cell_of_point(request.start_position)
	if typeof(p) == TYPE_VECTOR2I:
		return p
	return Vector2i(int(floor(request.start_position.x)), int(floor(request.start_position.y)))

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

## Bounded shortcut span (sanitized). span <= 1 -> no shortcut (F-009).
func _safe_span() -> int:
	return max_shortcut_span if max_shortcut_span > 1 else 1

func _bounded_shortcut(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	var span: int = _safe_span()
	if points.size() <= 2 or span <= 1:
		return points
	var out := PackedVector2Array([points[0]])
	var i: int = 0
	var last: int = points.size() - 1
	while i < last:
		var next: int = i + 1
		var limit: int = mini(last, i + span)
		for j in range(limit, i + 1, -1):
			if _seg_true(access_query, points[i], points[j], idx):
				next = j
				break
		out.append(points[next])
		i = next
	return out

## Corner radius / samples sanitized: non-finite/negative radius or samples < 1
## -> keep the sharp corner (never generate non-finite points) (F-009).
func _safe_radius() -> float:
	if is_finite(corner_radius) and corner_radius > 0.0:
		return corner_radius
	return 0.0

func _round_corners(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	var radius: float = _safe_radius()
	if points.size() <= 2 or corner_samples < 1 or radius <= 0.0:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var a: Vector2 = points[i - 1]
		var v: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var cut: float = minf(radius, minf(a.distance_to(v) * 0.5, v.distance_to(b) * 0.5))
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
			if not _seg_true(access_query, arc[s], arc[s + 1], idx):
				arc_ok = false
				break
		if arc_ok:
			for pt in arc:
				out.append(pt)
		else:
			out.append(v)
	out.append(points[points.size() - 1])
	return out
