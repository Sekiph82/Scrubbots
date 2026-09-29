## M25-C004 TEST-ONLY work-counting replica of the frozen pre-S2 Railroad oracle (same algorithm and tie-break as
## tests/support/m25_c004_railroad_baseline.gd; counters added around the Dijkstra). Its results are re-verified
## against the oracle by tests/m25_c004_host_truth.gd. Never loaded by shipping runtime.
## M25-C004 FROZEN PRE-S2 RAILROAD ORACLE — TEST ONLY, NEVER LOADED BY SHIPPING RUNTIME.
## Verbatim copy of scripts/gameplay/routing/production_routing_system.gd at commit
## aadc57253d45dcd6b71ca8cc1b00b7a7684e0574 (header comment lines only added). Do NOT edit
## to make a new implementation pass; it is the differential ground truth.
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
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Route-choice tolerance for "shortest legal total rail route" comparison.
const _RAIL_LEN_EPS := 0.0001

## RAILWAY-FIRST cost model (M28-C002-C003-R01 V02, owner finding 3). Travel on the rail
## and the ingress bridge cost 1.0 per logical cell; every interior board step costs
## INTERIOR_STEP_COST. It is deliberately larger than the longest possible rail loop
## (2 * (59 + 5) + 2 * (59 + 5) = 256 cells), so the Dijkstra is LEXICOGRAPHIC: first
## minimise the number of steps through the pixel-art board (= leave the rail at the
## perimeter point closest to the target; when the target's own column / row is open this
## is the aligned exit and the final leg is one straight line), then minimise rail
## distance, then the deterministic side / scan tie-break. Before this, a rail unit and an
## interior unit cost the same, so an equal-length staircase through the artwork tied with
## "follow the rail" and the BOTTOM-first tie-break always won: bots left the connector at
## once and crossed the board.
const INTERIOR_STEP_COST := 1000.0
## Equal-weight cost (rail unit == interior unit): the shortest TOTAL legal travel. Used by the
## difficulty analyzers, whose route-complexity metrics are defined on that basis.
const TOTAL_TRAVEL_COST := 1.0

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
## Interior-step weight of the railroad Dijkstra. Production default = INTERIOR_STEP_COST
## (railway-first). Tests set 1.0 to reproduce the pre-V02 equal-weight behaviour and prove
## that ONLY the travel path changes, never the assigned target / claim identity.
var interior_step_cost: float = INTERIOR_STEP_COST
var wc := {}

func _wc_reset() -> void:
	wc = {"sources": 0, "pushes": 0, "pops": 0, "stale_pops": 0, "neighbor_checks": 0, "state_reads": 0, "relaxations": 0, "max_heap": 0, "snapshots": 0}

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

	# Scrubbot Railroad V1 (OWNER_SCRUBBOT_RAILROAD_DECISION_V01): EVERY current
	# production OUTSIDE start travels on the railroad. The exact M21 adjacent
	# one-cell ring (x=-1 / x=W / y=-1 / y=H) is fully superseded as a production
	# exterior movement lane (M22-C001 V03, F-M22-V02-STRICT-001) — it is no longer
	# constructed or searched anywhere below. Real SlotCell starts sit below the
	# board and route exact-anchor → BOTTOM connector → rail-only travel → aligned
	# exit → assigned target; top/left/right outside starts use the same
	# rail-compatible policy (bottom connector) or fail closed via access truth.
	# Only a genuine INSIDE-board start (debug/test) reaches the interior planner
	# below, which no longer touches any exterior ring.
	if _is_outside_start(request, board):
		return _railroad_route(request, board, access_query)

	# Interior debug/test backbone (INSIDE-board starts only): deterministic
	# grid-aware reachability/path. No exterior ring is seeded or traversed.
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

# ------------------------------------------- Scrubbot Railroad V1 (HOW) --
# Owner-locked exterior travel: clicked-slot start → bottom-rail connector →
# rail-only travel (corners only) → aligned orthogonal exit → assigned target.
# Consumes the single-source ScrubRailGeometry; never retargets; every returned
# route is RouteValidator-clean under the same authoritative access truth. The
# generic collinear/shortcut/rounding post-process is intentionally NOT applied
# here so it can never turn a rail route into a diagonal free-space shortcut
# (criteria M22-V02-074/075).

## Any start whose cell lies OUTSIDE the board (below/top/left/right). All such
## current production starts route on the railroad; the obsolete adjacent ring is
## never used. Only genuine inside-board starts fall through to the interior
## debug/test planner.
func _is_outside_start(request, board) -> bool:
	var sp: Vector2 = request.start_position
	var cx: int = int(floor(sp.x))
	var cy: int = int(floor(sp.y))
	return cx < 0 or cy < 0 or cx >= board.get_width() or cy >= board.get_height()

## Build the Railroad V1 route for the already-assigned target
## (OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01, M22-C001 V07).
##
##   clicked slot → BOTTOM connector → rail-only exterior travel (corners only) →
##   a legal rail ingress into an OPEN/CLEARED perimeter cell → orthogonal
##   four-neighbour interior path (90° turns allowed) through OPEN/CLEARED cells →
##   assigned ACTIVE target as final arrival.
##
## The rail departure need NOT be aligned with the target. A single deterministic
## Dijkstra minimises total legal route cost = connector + rail travel + ingress
## bridge + INTERIOR_STEP_COST x interior orthogonal steps (railway-first: fewest board
## steps first, see the constant), so is_targetable() becomes true whenever any
## such legal route exists. Equal total: side priority BOTTOM → LEFT → RIGHT → TOP,
## then a stable same-side ingress order (ascending perimeter scan index), then a
## fixed 4-neighbour interior expansion order — all deterministic. Interior movement
## is inside-board only; exterior stays rail-only (the superseded M21 adjacent ring
## is never revived). Uses ScrubRailGeometry + the authoritative ProductionAccessQuery
## seam; the returned route is RouteValidator-clean.
func _railroad_route(request, board, access_query) -> RefCounted:
	_wc_reset()
	var idx: int = request.target_index
	var w: int = board.get_width()
	var h: int = board.get_height()
	var geom = ScrubRailGeometry.new(w, h)
	if not geom.is_valid():
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)
	var start: Vector2 = request.start_position
	var target_cell: Vector2i = board.get_cell_position(idx)
	var target_center: Vector2 = RouteRequest.center_of_index(board, idx)
	var entry: Vector2 = geom.bottom_entry(start.x)
	var connector_len: float = start.distance_to(entry)

	# --- legal rail ingress sources: OPEN/CLEARED (or target) perimeter cells whose
	# orthogonal rail→cell bridge is access-legal. side priority BOTTOM,LEFT,RIGHT,TOP.
	var tp_src := RuntimePerfProbe.now()
	# Canonical-access fast path (exact-equivalent, M52-C001-R01): for the EXACT production
	# ProductionAccessQuery, the orthogonal rail->perimeter-cell bridge crosses only exterior
	# (OPEN) cells and that perimeter cell, with no corner crossing, so the segment verdict
	# equals the (already required) non-BLOCKED class of the cell. Other access objects keep
	# the full segment confirmation. rail_dist == rail_path(...)["dist"] without polyline.
	var fast: bool = access_query.get_script() == ProductionAccessQuery
	var sources: Array = []  # each: {cell:int, rp:Vector2, side:int, seq:int, cost0:float}
	var _add_source := func(cx: int, cy: int, rp: Vector2, side: int, seq: int) -> void:
		if cx < 0 or cy < 0 or cx >= w or cy >= h:
			return
		var cc := Vector2(float(cx) + 0.5, float(cy) + 0.5)
		if _classify(access_query, cx, cy, idx) == ProductionAccessQuery.CellClass.BLOCKED:
			return
		if not fast and not _seg_true(access_query, rp, cc, idx):
			return
		var rail_dist: float = geom.rail_dist(entry, rp)
		var cost0: float = connector_len + rail_dist + rp.distance_to(cc)
		sources.append({"cell": cy * w + cx, "rp": rp, "side": side, "seq": seq, "cost0": cost0})
	for x in range(w):  # BOTTOM (side 0)
		_add_source.call(x, h - 1, Vector2(float(x) + 0.5, geom.bottom_y()), 0, x)
	for y in range(h):  # LEFT (side 1)
		_add_source.call(0, y, Vector2(geom.left_x(), float(y) + 0.5), 1, y)
	for y in range(h):  # RIGHT (side 2)
		_add_source.call(w - 1, y, Vector2(geom.right_x(), float(y) + 0.5), 2, y)
	for x in range(w):  # TOP (side 3)
		_add_source.call(x, 0, Vector2(float(x) + 0.5, geom.top_y()), 3, x)
	RuntimePerfProbe.add("route_sources", tp_src)
	wc["sources"] = sources.size()
	if sources.is_empty():
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	var target_lin: int = target_cell.y * w + target_cell.x
	# Fast fail (perf + correctness): the target is reachable only if it can be
	# ENTERED as a final cell — from an adjacent OPEN interior cell, or by a direct
	# rail ingress at the target's own perimeter cell. If neither holds it is
	# enclosed; skip the interior Dijkstra entirely.
	var touchable := false
	for d in NEIGHBORS:
		var ax: int = target_cell.x + d.x
		var ay: int = target_cell.y + d.y
		if ax < 0 or ay < 0 or ax >= w or ay >= h:
			continue
		if _classify(access_query, ax, ay, idx) == ProductionAccessQuery.CellClass.OPEN \
				and _seg_true(access_query, Vector2(float(ax) + 0.5, float(ay) + 0.5), target_center, idx):
			touchable = true
			break
	if not touchable:
		for s in sources:
			if s["cell"] == target_lin:
				touchable = true
				break
	if not touchable:
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	# --- deterministic Dijkstra: sources seed board cells with their rail cost0;
	# interior edges cost 1.0 (unit orthogonal step). Tie-break on (cost, side, seq).
	# M52-C001-R01 perf (exact-equivalent): flat packed per-cell arrays instead of
	# Dictionaries (INF == "not yet reached"), identical relax/tie-break logic.
	var n_cells: int = w * h
	var dist := PackedFloat64Array()
	dist.resize(n_cells)
	dist.fill(INF)
	var side_of := PackedInt32Array()
	side_of.resize(n_cells)
	var seq_of := PackedInt32Array()
	seq_of.resize(n_cells)
	var parent := PackedInt32Array()   # predecessor cell (-1 at an ingress source)
	parent.resize(n_cells)
	var src_rp: Dictionary = {}   # cell -> ingress rail point (only at source cells)
	# Packed binary heap (M52-C001-R01 perf). Keys (cost, side, seq, cell) are a strict
	# total order, so pop order is identical to the former Array-entry heap.
	var hq := _PackedHeap.new()
	for s in sources:
		var c: int = s["cell"]
		var better = dist[c] == INF or s["cost0"] < dist[c] - _RAIL_LEN_EPS \
			or (absf(s["cost0"] - dist[c]) <= _RAIL_LEN_EPS and _rank_lt(s["side"], s["seq"], side_of[c], seq_of[c]))
		if better:
			dist[c] = s["cost0"]; side_of[c] = s["side"]; seq_of[c] = s["seq"]
			parent[c] = -1; src_rp[c] = s["rp"]
			hq.push(s["cost0"], s["side"], s["seq"], c)
			wc["pushes"] += 1
			wc["max_heap"] = maxi(wc["max_heap"], hq.n)

	# Canonical-access fast path (exact-equivalent, M52-C001-R01). For the EXACT production
	# ProductionAccessQuery (script identity — never a subclass/double), an interior edge is
	# an axis-aligned unit step between adjacent cell centres from an OPEN cell: its
	# supercover crosses only those two cells and no corner, so is_segment_traversable is
	# exactly "neighbour enterable" = neighbour CLEARED, or the target on arrival. The
	# classification is read straight from BoardState (classify_cell's own rule). Any other
	# access object keeps the full classify + segment confirmation per edge.
	var tp_dij := RuntimePerfProbe.now()
	var found := false
	while not hq.is_empty():
		var top_cost: float = hq.pop()
		var u: int = hq.last_cell
		wc["pops"] += 1
		if top_cost > dist[u] + _RAIL_LEN_EPS:
			wc["stale_pops"] += 1
			continue  # stale
		if u == target_lin:
			found = true
			break
		var ux: int = u % w
		var uy: int = u / w
		var uc := Vector2(float(ux) + 0.5, float(uy) + 0.5)
		for d in NEIGHBORS:
			var nx: int = ux + d.x
			var ny: int = uy + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var nlin: int = ny * w + nx
			wc["neighbor_checks"] += 1
			var is_target := (nlin == target_lin)
			# Intermediate cells must be OPEN; the target is enterable only as final.
			if fast:
				if not is_target:
					wc["state_reads"] += 1
				if not is_target and board.get_cell_state(nlin) != BoardState.CellState.CLEARED:
					continue
			else:
				if not is_target and _classify(access_query, nx, ny, idx) != ProductionAccessQuery.CellClass.OPEN:
					continue
				var nc := Vector2(float(nx) + 0.5, float(ny) + 0.5)
				if not _seg_true(access_query, uc, nc, idx):
					continue
			var ncost: float = dist[u] + interior_step_cost
			var relax = dist[nlin] == INF or ncost < dist[nlin] - _RAIL_LEN_EPS \
				or (absf(ncost - dist[nlin]) <= _RAIL_LEN_EPS and _rank_lt(side_of[u], seq_of[u], side_of[nlin], seq_of[nlin]))
			if relax:
				dist[nlin] = ncost; side_of[nlin] = side_of[u]; seq_of[nlin] = seq_of[u]
				parent[nlin] = u
				hq.push(ncost, side_of[u], seq_of[u], nlin)
				wc["relaxations"] += 1
				wc["pushes"] += 1
				wc["max_heap"] = maxi(wc["max_heap"], hq.n)
	RuntimePerfProbe.add("route_dijkstra", tp_dij)
	if not found:
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)

	# --- reconstruct: interior cell chain (source → … → target), then prepend the
	# rail portion (connector + rail corners + ingress rail point).
	var chain: Array = []
	var cur: int = target_lin
	while cur != -1:
		chain.push_front(cur)
		cur = parent[cur]
	var src_cell: int = chain[0]
	var pts := PackedVector2Array()
	pts.append(start)
	pts.append(entry)
	for wp in geom.rail_path(entry, src_rp[src_cell])["points"]:
		pts.append(wp)
	pts.append(src_rp[src_cell])
	for lin in chain:
		pts.append(Vector2(float(lin % w) + 0.5, float(lin / w) + 0.5))
	pts = _dedup_points(pts)
	# Collinear collapse only (never a diagonal-introducing shortcut) so straight
	# runs stay compact; every segment remains axis-aligned.
	pts = _remove_collinear(pts)
	var tp_val := RuntimePerfProbe.now()
	var valid := _whole_route_valid(request, pts, board, access_query)
	RuntimePerfProbe.add("route_validate", tp_val)
	if not valid:
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)
	return RouteResult.success_route(idx, pts)

## Lexicographic (side, seq) priority: lower side (BOTTOM<LEFT<RIGHT<TOP) then lower
## scan index wins. Used only to break EXACTLY-equal total-length ties deterministically.
func _rank_lt(side_a: int, seq_a: int, side_b: int, seq_b: int) -> bool:
	if side_a != side_b:
		return side_a < side_b
	return seq_a < seq_b

# --- tiny binary min-heap of [cost, side, seq, cell]; ordering cost,side,seq,cell.
## Allocation-free binary min-heap over parallel packed arrays, ordered by
## (cost, side, seq, cell) lexicographically — the same strict total order as _heap_less.
class _PackedHeap:
	var cost := PackedFloat64Array()
	var side := PackedInt32Array()
	var seq := PackedInt32Array()
	var cell := PackedInt32Array()
	var n: int = 0
	var last_cell: int = -1

	func is_empty() -> bool:
		return n == 0

	func _less(i: int, j: int) -> bool:
		if cost[i] != cost[j]:
			return cost[i] < cost[j]
		if side[i] != side[j]:
			return side[i] < side[j]
		if seq[i] != seq[j]:
			return seq[i] < seq[j]
		return cell[i] < cell[j]

	func _swap(i: int, j: int) -> void:
		var tc: float = cost[i]; cost[i] = cost[j]; cost[j] = tc
		var ts: int = side[i]; side[i] = side[j]; side[j] = ts
		var tq: int = seq[i]; seq[i] = seq[j]; seq[j] = tq
		var tl: int = cell[i]; cell[i] = cell[j]; cell[j] = tl

	func push(c: float, sd: int, sq: int, cl: int) -> void:
		if n == cost.size():
			var cap: int = maxi(64, n * 2)
			cost.resize(cap); side.resize(cap); seq.resize(cap); cell.resize(cap)
		cost[n] = c; side[n] = sd; seq[n] = sq; cell[n] = cl
		var i: int = n
		n += 1
		while i > 0:
			var p: int = (i - 1) / 2
			if _less(i, p):
				_swap(i, p)
				i = p
			else:
				break

	## Pops the minimum; returns its cost and leaves its cell in last_cell.
	func pop() -> float:
		var top_cost: float = cost[0]
		last_cell = cell[0]
		n -= 1
		if n > 0:
			cost[0] = cost[n]; side[0] = side[n]; seq[0] = seq[n]; cell[0] = cell[n]
			var i: int = 0
			while true:
				var l: int = 2 * i + 1
				var r: int = l + 1
				var sm: int = i
				if l < n and _less(l, sm):
					sm = l
				if r < n and _less(r, sm):
					sm = r
				if sm == i:
					break
				_swap(sm, i)
				i = sm
		return top_cost

## Drop consecutive near-duplicate points (an exit that coincides with the entry
## or a corner) so no zero-length segment reaches the validator.
func _dedup_points(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 1:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		if points[i].distance_to(out[out.size() - 1]) > _COLLINEAR_EPS:
			out.append(points[i])
	return out

func _polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

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
	# NOTE (M22-C001 V03, F-M22-V02-STRICT-001): the obsolete M21 one-cell exterior
	# ring band is NOT seeded here. Outside starts route on the railroad (handled in
	# compute_route); this interior planner only reaches genuine inside-board
	# debug/test starts and searches inside-board cells only.

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
			# Interior planner: traverse INSIDE-board cells only. No exterior ring
			# is searched (superseded by Railroad V1; F-M22-V02-STRICT-001).
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
