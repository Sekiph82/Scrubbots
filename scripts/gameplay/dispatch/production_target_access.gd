extends RefCounted
## ProductionTargetAccess — preload this script
## (res://scripts/gameplay/dispatch/production_target_access.gd) rather than
## relying on global class_name lookup (AL-001 / ADR-009).
##
## M19 — the PRODUCTION reachability/access truth TargetSelector consumes
## (its injected access_query, exposing is_targetable(index)). TargetSelector
## must never assume a raw color candidate is reachable (AL-028); it asks this.
##
## Single source of reachability truth: the SAME ProductionRoutingSystem that
## will later actually move the bot. is_targetable(index) is true iff production
## routing can compute a valid route from the current slot origin to that target
## AND that route is RouteValidator-clean for the exact request/board/access. This
## deliberately avoids a second, independently-drifting reachability BFS — if
## routing can reach it validly, it is targetable; if not, it is not.
##
## strict-v2 (F-M19-STRICT-002): fail closed for malformed construction or
## dependencies (non-BoardState board, malformed routing system/access, non-finite
## origin, invalid index, malformed/mismatched/geometrically-invalid route). A
## success is memoized ONLY after RouteValidator accepts it. A FAILED probe clears
## any stale memo, set_origin clears the memo, and consume_route is ONE-SHOT (it
## returns the winning route once, then clears it).
##
## Reachability depends on WHERE the bot leaves from, so the dispatcher calls
## set_origin() with the slot origin before each dispatch's selection pass. This
## owns NO selection, NO reservation, and NEVER mutates BoardState. It never
## exposes its board/routing references (only a read-only identity coherence query).

const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")

var _routing_system
var _routing_access
var _board
var _origin: Vector2 = Vector2.ZERO
## Memo of the most recent successful probe (winning target reuse).
var _last_index: int = -1
var _last_route = null
## M52-C001-R01 exact-safe reachability prefilter (outside/rail starts only), materialised
## per board state (M25-C003 S1-A):
##   reach[i] = 1  CLEARED cell 4-connected through CLEARED cells to a perimeter CLEARED
##                 cell, i.e. a cell the Railroad V1 interior Dijkstra can stand on;
##   touch[i] = 1  i is a perimeter cell (direct rail ingress) OR 4-adjacent to a reach
##                 cell — the exact M52 necessary condition for a Railroad V1 route to end
##                 at i. touch[i] == 0 => compute_route(i) is NO_ROUTE (never a success).
## Both are rebuilt whenever the BoardState revision moves; a lookup is then O(1).
var _reach_mask: PackedByteArray = PackedByteArray()
var _touch_mask: PackedByteArray = PackedByteArray()
var _reach_revision: int = -1
var _mask_board_id: int = 0
## Shared across access instances (all lanes of one board state probe the same masks):
## keyed by the EXACT BoardState instance id + its monotonic revision, so a mask is never
## reused for a different board or a different lifecycle state (restore bumps revision).
## Single slot: at most one board state's masks are retained (bounded, never grows).
static var _shared_board_id: int = 0
static var _shared_revision: int = -1
static var _shared_mask: PackedByteArray = PackedByteArray()
static var _shared_touch: PackedByteArray = PackedByteArray()
## Diagnostic counter of mask builds (tests prove same-revision sharing / invalidation).
static var mask_build_count: int = 0
## Cached "prefilter supported for this board + origin" decision, recomputed whenever the
## origin value differs from the one it was computed for (NaN never matches -> recomputed,
## and stays unsupported).
var _support_origin: Vector2 = Vector2(NAN, NAN)
var _supported: bool = false

func _init(routing_system, routing_access, board, origin: Vector2 = Vector2.ZERO) -> void:
	_routing_system = routing_system
	_routing_access = routing_access
	_board = board
	_origin = origin

## Read-only exact-identity coherence query (F-M19-STRICT-001). Proves this access
## adapter carries the EXACT board/routing_system/routing_access bundle the
## dispatcher expects (reference identity, not merely compatible shapes), so a
## mismatched/mixed bundle is rejected upstream. Never exposes the references.
func is_coherent_with(board, routing_system, routing_access) -> bool:
	return _board != null and _board == board \
		and _routing_system != null and _routing_system == routing_system \
		and _routing_access != null and _routing_access == routing_access

## Read-only board-coherence query for the M25 claim trust boundary (M25-C001 V02 seam).
## NON-MUTATING: true iff this access adapter carries the EXACT bound BoardState instance
## (reference identity, not merely equal dimensions), so the M25 claim path can reject a
## foreign-board ProductionTargetAccess without learning routing internals. Never exposes
## the board reference. Adds no reachability policy — pure identity check.
func is_bound_to_board(board) -> bool:
	return _board != null and _board == board

## Point subsequent reachability probes at a new slot origin. Clears the memo so
## a route from a previous origin can never be reused for a different dispatch.
func set_origin(origin: Vector2) -> void:
	_origin = origin
	_clear_memo()

func is_targetable(index: int) -> bool:
	# Exact-safe prefilter (M52-C001-R01): a Railroad V1 route can only end at `index` if
	# it is a perimeter cell (direct rail ingress) or 4-adjacent to an OPEN cell that is
	# 4-connected to a perimeter OPEN ingress cell — exactly the graph the production
	# Dijkstra searches. Failing that necessary condition means compute_route would return
	# NO_ROUTE anyway, so skipping it cannot change any verdict; it only removes the
	# full perimeter-scan + Dijkstra per sealed candidate (the Level 2 stutter source).
	if not _could_reach(index):
		_clear_memo()
		return false
	if _probe(index):
		return true
	# A failed probe must not leave a stale successful memo queryable.
	_clear_memo()
	return false

## Compute + validate a route to `index` from the current origin, memoizing the
## RouteResult ONLY on a RouteValidator-clean success. Fail closed (no fault) for
## every malformed dependency/argument.
func _probe(index: int) -> bool:
	if not (_board is BoardState):
		return false
	if typeof(_routing_system) != TYPE_OBJECT or not _routing_system.has_method("compute_route"):
		return false
	if _routing_access == null:
		return false
	if not (is_finite(_origin.x) and is_finite(_origin.y)):
		return false
	var req = RouteRequest.for_target(_board, _origin, index)
	if req == null:
		return false
	var tp := RuntimePerfProbe.now()
	var r = _routing_system.compute_route(req, _board, _routing_access)
	RuntimePerfProbe.add("access_compute_route", tp)
	# ONE shared validation path: a real RouteResult, success, exact target, and
	# access-clean geometry. Malformed/mismatched/invalid -> not targetable.
	var tv := RuntimePerfProbe.now()
	var verdict = RouteValidator.validate_route(req, r, _board, _routing_access)
	RuntimePerfProbe.add("access_validate", tv)
	if verdict != RouteResult.FailureReason.NONE:
		return false
	_last_index = index
	_last_route = r
	return true

## The memoized RouteResult for `index` if it was the last successful probe, else
## null. ONE-SHOT (F-M19-STRICT-002): returning the winning route clears the memo,
## so a second consume without a new successful probe returns null. Lets the
## dispatcher skip a redundant recompute for the winner exactly once.
func consume_route(index: int):
	if index == _last_index and _last_route != null:
		var r = _last_route
		_clear_memo()
		return r
	return null

## Optional conservative necessary-condition capability (M25-C003 S1-B), consumed by
## TargetSelector BEFORE its strict per-candidate body. Opaque to the selector:
##   false -> `index` is mathematically NOT targetable for this access state (the exact M52
##            necessary condition fails, so compute_route would be NO_ROUTE). Mirrors the
##            observable side effect of is_targetable()'s false path (memo cleared).
##   true  -> MAY be targetable; the caller must still run the authoritative is_targetable().
##   null  -> unsupported here (invalid board/index, non-finite origin, or an inside-board
##            debug start that uses the interior planner): the caller must not filter.
## Never a success verdict.
func prefilter_maybe_targetable(index: int) -> Variant:
	if _origin != _support_origin:
		_support_origin = _origin
		_supported = _board is BoardState and _outside_origin()
	if not _supported:
		return null
	# Hot path: this instance's masks are current for its (fixed) board's revision.
	if _reach_revision != _board.get_revision() or _mask_board_id == 0:
		if not _ensure_masks():
			return null
	if index < 0 or index >= _touch_mask.size():
		return null   # invalid index (touch size == W*H): unsupported, never false
	if _touch_mask[index] == 1:
		return true
	_clear_memo()
	return false

func _could_reach(index: int) -> bool:
	# Unsupported (null) -> probe; let _probe fail closed with its own checks.
	return prefilter_maybe_targetable(index) != false

func _outside_origin() -> bool:
	if not (is_finite(_origin.x) and is_finite(_origin.y)):
		return false
	var ox: int = int(floor(_origin.x))
	var oy: int = int(floor(_origin.y))
	# Inside-board (debug) starts use the interior planner: no prefilter.
	return not (ox >= 0 and oy >= 0 and ox < _board.get_width() and oy < _board.get_height())

## Make the reach/touch masks current for the exact bound board + revision: reuse this
## instance's, adopt the shared single-slot cache, or rebuild. False if the board has no
## cells (nothing to filter).
func _ensure_masks() -> bool:
	var n: int = _board.get_width() * _board.get_height()
	if n <= 0:
		return false
	var bid: int = _board.get_instance_id()
	var rev: int = _board.get_revision()
	if _mask_board_id == bid and _reach_revision == rev and _touch_mask.size() == n:
		return true
	if _shared_board_id == bid and _shared_revision == rev and _shared_touch.size() == n and _shared_mask.size() == n:
		_reach_mask = _shared_mask
		_touch_mask = _shared_touch
	else:
		_build_masks(_board.get_width(), _board.get_height())
		_shared_board_id = bid
		_shared_revision = rev
		_shared_mask = _reach_mask
		_shared_touch = _touch_mask
	_mask_board_id = bid
	_reach_revision = rev
	return true

func _build_masks(w: int, h: int) -> void:
	mask_build_count += 1
	var n: int = w * h
	var tb := RuntimePerfProbe.now()
	# One detached bulk read of the lifecycle bytes, then a local flood (no per-cell calls).
	var st: PackedByteArray = _board.get_cell_states_copy()
	var cleared: int = BoardState.CellState.CLEARED
	_reach_mask = PackedByteArray()
	_reach_mask.resize(n)
	var stack: PackedInt32Array = PackedInt32Array()
	for y in range(h):
		for x in range(w):
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				var i: int = y * w + x
				if st[i] == cleared and _reach_mask[i] == 0:
					_reach_mask[i] = 1
					stack.append(i)
	while not stack.is_empty():
		var u: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var ux: int = u % w
		if u >= w and _reach_mask[u - w] == 0 and st[u - w] == cleared:
			_reach_mask[u - w] = 1
			stack.append(u - w)
		if ux < w - 1 and _reach_mask[u + 1] == 0 and st[u + 1] == cleared:
			_reach_mask[u + 1] = 1
			stack.append(u + 1)
		if u + w < n and _reach_mask[u + w] == 0 and st[u + w] == cleared:
			_reach_mask[u + w] = 1
			stack.append(u + w)
		if ux > 0 and _reach_mask[u - 1] == 0 and st[u - 1] == cleared:
			_reach_mask[u - 1] = 1
			stack.append(u - 1)
	# touch = perimeter OR 4-adjacent to a reach cell (the former per-call _could_reach rule).
	_touch_mask = PackedByteArray()
	_touch_mask.resize(n)
	for x in range(w):
		_touch_mask[x] = 1
		_touch_mask[n - w + x] = 1
	for y in range(1, h - 1):
		var row: int = y * w
		_touch_mask[row] = 1
		_touch_mask[row + w - 1] = 1
		for i in range(row + 1, row + w - 1):
			if _reach_mask[i - w] == 1 or _reach_mask[i + 1] == 1 or _reach_mask[i + w] == 1 or _reach_mask[i - 1] == 1:
				_touch_mask[i] = 1
	RuntimePerfProbe.add("access_mask_build", tb)

func _clear_memo() -> void:
	_last_index = -1
	_last_route = null
