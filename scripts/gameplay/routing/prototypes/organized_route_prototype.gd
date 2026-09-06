extends "res://scripts/gameplay/routing/routing_system.gd"
## OrganizedRoutePrototype — M17 Prototype C. EXPERIMENTAL organized/curved
## movement-language candidate. Preload it (AL-001). Subclasses RoutingSystem
## (M16 contract). It never invents target truth: it post-processes a VALID
## grid-aware path, so it cannot route where the grid prototype could not.
##
## Deterministic post-process pipeline (all steps validated through the injected
## access truth; any invalid simplification/curve is discarded, never accepted):
##   1. compute a valid grid-aware source path (GridRoutePrototype);
##   2. remove redundant collinear points;
##   3. greedy deterministic shortcut / string-pull — connect the farthest later
##      vertex whose straight segment is accepted by access truth (invalid
##      shortcuts are skipped, falling back to a shorter valid step);
##   4. optional deterministic corner rounding — replace each sharp interior
##      corner with a quadratic-bezier arc bulging toward the corner; the arc's
##      interior segments are validated and the corner falls back to sharp if any
##      arc segment is rejected. Connecting segments are sub-segments of already
##      valid path segments, so they stay valid by construction.
##
## This is an EXPERIMENTAL candidate. The final curvature amount is NOT
## production law — the owner design gate picks the movement language. Lab
## parameters are exposed so the owner can see exactly what produced the shape.

const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const GridRoutePrototype = preload("res://scripts/gameplay/routing/prototypes/grid_route_prototype.gd")

## Exposed experimental parameters (shown in the lab).
var enable_shortcut: bool = true
var enable_rounding: bool = true
## Corner cut length in cell units (clamped to half of each adjacent segment).
var corner_radius: float = 0.35
## Interior samples per rounded corner (arc smoothness).
var corner_samples: int = 3

const _COLLINEAR_EPS := 0.0001

func compute_route(request, board, access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var idx: int = request.target_index
	# Source truth: a valid grid-aware path. If the grid prototype cannot route,
	# neither can this one (no invented target truth) — propagate its failure.
	var grid := GridRoutePrototype.new()
	var grid_res = grid.compute_route(request, board, access_query)
	if not grid_res.success:
		return grid_res
	var pts: PackedVector2Array = grid_res.get_points()

	pts = _remove_collinear(pts)
	if enable_shortcut:
		pts = _greedy_shortcut(pts, access_query, idx)
	if enable_rounding:
		pts = _round_corners(pts, access_query, idx)
	return RouteResult.success_route(idx, pts)

## Drop a middle point when prev,mid,next are collinear (redundant).
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

## Greedy string-pull: from each point, jump to the farthest later point whose
## straight segment is traversable. Invalid shortcuts are skipped (falls back to
## the next-shorter candidate, guaranteeing progress). Deterministic.
func _greedy_shortcut(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var out := PackedVector2Array([points[0]])
	var i: int = 0
	var last: int = points.size() - 1
	while i < last:
		var next: int = i + 1
		# Scan from farthest to nearest; take the first (largest) valid jump.
		for j in range(last, i + 1, -1):
			if access_query.is_segment_traversable(points[i], points[j], idx):
				next = j
				break
		out.append(points[next])
		i = next
	return out

## Replace sharp interior corners with quadratic-bezier arcs (bulging toward the
## corner). Arc interior segments are validated; a corner falls back to sharp if
## any arc segment is rejected. Endpoints are never moved.
func _round_corners(points: PackedVector2Array, access_query, idx: int) -> PackedVector2Array:
	if points.size() <= 2 or corner_samples < 1:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var a: Vector2 = points[i - 1]
		var v: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var la: float = a.distance_to(v)
		var lb: float = v.distance_to(b)
		var cut: float = minf(corner_radius, minf(la * 0.5, lb * 0.5))
		if cut <= _COLLINEAR_EPS:
			out.append(v)
			continue
		var p1: Vector2 = v + (a - v).normalized() * cut
		var p2: Vector2 = v + (b - v).normalized() * cut
		# Build the arc: P1, interior bezier samples, P2.
		var arc := PackedVector2Array([p1])
		for k in range(1, corner_samples + 1):
			var t: float = float(k) / float(corner_samples + 1)
			var omt: float = 1.0 - t
			var pt: Vector2 = p1 * (omt * omt) + v * (2.0 * omt * t) + p2 * (t * t)
			arc.append(pt)
		arc.append(p2)
		# Validate every interior arc segment through access truth.
		var arc_ok: bool = true
		for s in range(arc.size() - 1):
			if not access_query.is_segment_traversable(arc[s], arc[s + 1], idx):
				arc_ok = false
				break
		if arc_ok:
			for pt in arc:
				out.append(pt)
		else:
			out.append(v) # fall back to the sharp corner (never accept invalid)
	out.append(points[points.size() - 1])
	return out
