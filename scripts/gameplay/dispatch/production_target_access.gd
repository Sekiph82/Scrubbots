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
## M52-C001-R01 exact-safe reachability prefilter (outside/rail starts only). 1 = CLEARED
## cell 4-connected through CLEARED cells to a perimeter CLEARED cell, i.e. a cell the
## Railroad V1 interior Dijkstra can stand on. Rebuilt whenever BoardState revision moves.
var _reach_mask: PackedByteArray = PackedByteArray()
var _reach_revision: int = -1
## Shared across access instances (all lanes of one wave probe the same board state):
## keyed by the EXACT BoardState instance id + its monotonic revision, so a mask is never
## reused for a different board or a different lifecycle state (restore bumps revision).
static var _shared_board_id: int = 0
static var _shared_revision: int = -1
static var _shared_mask: PackedByteArray = PackedByteArray()

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

func _could_reach(index: int) -> bool:
	if not (_board is BoardState) or not _board.is_valid_index(index):
		return true  # let _probe fail closed with its own checks
	if not (is_finite(_origin.x) and is_finite(_origin.y)):
		return true
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	var ox: int = int(floor(_origin.x))
	var oy: int = int(floor(_origin.y))
	if ox >= 0 and oy >= 0 and ox < w and oy < h:
		return true  # inside-board (debug) starts use the interior planner: no prefilter
	var pos: Vector2i = _board.get_cell_position(index)
	if pos.x == 0 or pos.y == 0 or pos.x == w - 1 or pos.y == h - 1:
		return true
	if _reach_revision != _board.get_revision() or _reach_mask.size() != w * h:
		if _shared_board_id == _board.get_instance_id() and _shared_revision == _board.get_revision() 				and _shared_mask.size() == w * h:
			_reach_mask = _shared_mask
			_reach_revision = _shared_revision
		else:
			_build_reach_mask(w, h)
			_shared_board_id = _board.get_instance_id()
			_shared_revision = _reach_revision
			_shared_mask = _reach_mask
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var nx: int = pos.x + d.x
		var ny: int = pos.y + d.y
		if nx >= 0 and ny >= 0 and nx < w and ny < h and _reach_mask[ny * w + nx] == 1:
			return true
	return false

func _build_reach_mask(w: int, h: int) -> void:
	_reach_mask = PackedByteArray()
	_reach_mask.resize(w * h)
	var stack: PackedInt32Array = PackedInt32Array()
	for y in range(h):
		for x in range(w):
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				var i: int = y * w + x
				if _board.get_cell_state(i) == BoardState.CellState.CLEARED and _reach_mask[i] == 0:
					_reach_mask[i] = 1
					stack.append(i)
	while not stack.is_empty():
		var u: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var ux: int = u % w
		var uy: int = u / w
		for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx: int = ux + d.x
			var ny: int = uy + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var n: int = ny * w + nx
			if _reach_mask[n] == 0 and _board.get_cell_state(n) == BoardState.CellState.CLEARED:
				_reach_mask[n] = 1
				stack.append(n)
	_reach_revision = _board.get_revision()

func _clear_memo() -> void:
	_last_index = -1
	_last_route = null
