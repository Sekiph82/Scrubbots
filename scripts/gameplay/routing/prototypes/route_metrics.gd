extends RefCounted
## RouteMetrics — M17 deterministic, algorithm-agnostic comparison utilities.
## Preload it (AL-001). Stateless: only static functions. It measures already-
## computed RouteResults/point sets; it never computes a route, never selects a
## target, never mutates BoardState/ReservationState.
##
## Every metric definition is explicit so comparisons are neutral and
## reproducible (the owner, not these numbers, picks the movement language).

## ---- Route distance --------------------------------------------------------

## Polyline length: sum of consecutive segment lengths (board-local cell units).
static func route_distance(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

## Distance stats over a set of SUCCESSFUL routes (Array of PackedVector2Array).
## Returns {count, total, mean, median}.
static func distance_stats(route_points: Array) -> Dictionary:
	var lengths: Array = []
	var total: float = 0.0
	for pts in route_points:
		var d: float = route_distance(pts)
		lengths.append(d)
		total += d
	var count: int = lengths.size()
	var mean: float = (total / count) if count > 0 else 0.0
	lengths.sort()
	var median: float = 0.0
	if count > 0:
		if count % 2 == 1:
			median = lengths[count / 2]
		else:
			median = (lengths[count / 2 - 1] + lengths[count / 2]) * 0.5
	return {"count": count, "total": total, "mean": mean, "median": median}

## ---- Path crossings --------------------------------------------------------

## Signed orientation of (a,b,c). >0 CCW, <0 CW, 0 collinear.
static func _orient(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

## PROPER segment intersection only: interiors cross transversally. Shared
## endpoints (touching) and collinear overlap return false — endpoints are
## handled by policy below and collinear overlap is counted as congestion, not
## crossings.
static func segments_properly_cross(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	var o1: float = _orient(p1, p2, p3)
	var o2: float = _orient(p1, p2, p4)
	var o3: float = _orient(p3, p4, p1)
	var o4: float = _orient(p3, p4, p2)
	# Any zero => collinear or endpoint-touch => not a proper crossing.
	if o1 == 0.0 or o2 == 0.0 or o3 == 0.0 or o4 == 0.0:
		return false
	return (o1 > 0.0) != (o2 > 0.0) and (o3 > 0.0) != (o4 > 0.0)

## Count proper interior crossings BETWEEN DISTINCT routes (pairwise i<j).
## Policy (explicit): shared start/end endpoints do NOT count; proper interior
## segment intersections DO; collinear overlap is NOT counted here (see
## congestion). Self-crossings within one route are out of scope for this metric.
static func crossing_count(route_points: Array) -> int:
	var crossings: int = 0
	for a in range(route_points.size()):
		var ra: PackedVector2Array = route_points[a]
		for b in range(a + 1, route_points.size()):
			var rb: PackedVector2Array = route_points[b]
			for i in range(ra.size() - 1):
				for j in range(rb.size() - 1):
					if segments_properly_cross(ra[i], ra[i + 1], rb[j], rb[j + 1]):
						crossings += 1
	return crossings

## ---- Congestion / overlap --------------------------------------------------

## Cells a polyline passes through, sampled at `step` and floored to cell coords.
static func route_cells(points: PackedVector2Array, step: float = 0.25) -> Dictionary:
	var cells: Dictionary = {}
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length: float = a.distance_to(b)
		var n: int = int(ceil(length / step))
		if n < 1:
			n = 1
		for k in range(n + 1):
			var t: float = float(k) / float(n)
			var p: Vector2 = a + (b - a) * t
			cells[Vector2i(int(floor(p.x)), int(floor(p.y)))] = true
	return cells

## Congestion proxy over a route set. Explicit definitions:
##   occupied_buckets  = distinct cells touched by >=1 route;
##   max_overlap       = max number of DISTINCT routes sharing one cell;
##   total_repeated    = sum over cells of max(0, distinct_routes_in_cell - 1)
##                       (total "extra" corridor sharing beyond the first user).
static func congestion(route_points: Array, step: float = 0.25) -> Dictionary:
	var usage: Dictionary = {} # Vector2i -> route count
	for pts in route_points:
		var cells: Dictionary = route_cells(pts, step)
		for c in cells.keys():
			usage[c] = int(usage.get(c, 0)) + 1
	var max_overlap: int = 0
	var total_repeated: int = 0
	for c in usage.keys():
		var u: int = usage[c]
		if u > max_overlap:
			max_overlap = u
		total_repeated += maxi(0, u - 1)
	return {
		"occupied_buckets": usage.size(),
		"max_overlap": max_overlap,
		"total_repeated": total_repeated,
	}

## ---- CPU cost --------------------------------------------------------------

## Measure ROUTE-COMPUTATION CPU time only (Time.get_ticks_usec). Runs each
## request `samples` times through the strategy. Reports CPU only — NO FPS/GPU
## claim. success/failure counts are from one representative pass.
static func cpu_benchmark(strategy, requests: Array, board, access_query, samples: int = 1) -> Dictionary:
	var success: int = 0
	var failure: int = 0
	var calls: int = 0
	var start_us: int = Time.get_ticks_usec()
	for s in range(samples):
		for req in requests:
			var res = strategy.compute_route(req, board, access_query)
			calls += 1
			if s == 0:
				if res.success:
					success += 1
				else:
					failure += 1
	var total_us: int = Time.get_ticks_usec() - start_us
	var mean_us: float = (float(total_us) / float(calls)) if calls > 0 else 0.0
	return {
		"calls": calls,
		"success": success,
		"failure": failure,
		"total_us": total_us,
		"mean_us": mean_us,
		"samples": samples,
		"request_count": requests.size(),
	}

## ---- Determinism -----------------------------------------------------------

## Exact (bit-for-bit) equality of two point sequences.
static func points_equal(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

## Compare two aligned route sets exactly. Returns {identical, first_diff_index}.
static func route_sets_identical(set_a: Array, set_b: Array) -> Dictionary:
	if set_a.size() != set_b.size():
		return {"identical": false, "first_diff_index": -1}
	for i in range(set_a.size()):
		if not points_equal(set_a[i], set_b[i]):
			return {"identical": false, "first_diff_index": i}
	return {"identical": true, "first_diff_index": -1}
