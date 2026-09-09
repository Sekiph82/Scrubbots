extends RefCounted
## RouteAccessQueryDouble — M16 test double for the injected segment access truth
## the route validator consumes. Preload it (AL-001).
##
## It lets a test:
##   - declare specific segments (from -> to) blocked or open;
##   - directly observe the exact sequence of segment queries, the target_index
##     supplied, and the verdict returned (AL-018 direct observability — not a
##     proxy assertion like "the boolean result was false").
##
## Fail-closed by convention: unknown segments use `default_traversable`, default
## false, so a test must explicitly open the segments its route needs.

## Ordered log of every query: {from, to, target_index, verdict}.
var query_log: Array = []
## Blocked segments keyed by canonical segment key -> true.
var _blocked: Dictionary = {}
## Explicitly opened segments keyed by canonical segment key -> true.
var _open: Dictionary = {}
var default_traversable: bool = false
## Optional exact-identity board binding, so this double can also stand in as a
## dispatcher routing_access (which requires is_bound_to). null = unbound.
var bound_board = null

## Bind this double to a board for exact-identity coherence checks.
func bind_board(board) -> void:
	bound_board = board

## Exact-identity coherence (dispatcher routing_access seam). False when unbound
## or when a different board instance is supplied.
func is_bound_to(board) -> bool:
	return bound_board != null and board == bound_board

static func _key(a: Vector2, b: Vector2) -> String:
	return "%.4f,%.4f->%.4f,%.4f" % [a.x, a.y, b.x, b.y]

## Mark a single directed segment open.
func open_segment(from_position: Vector2, to_position: Vector2) -> void:
	_open[_key(from_position, to_position)] = true

## Mark a single directed segment blocked (wins over open/default).
func block_segment(from_position: Vector2, to_position: Vector2) -> void:
	_blocked[_key(from_position, to_position)] = true

## Open every consecutive segment of a polyline (both a whole route helper).
func open_polyline(points: PackedVector2Array) -> void:
	for i in range(points.size() - 1):
		open_segment(points[i], points[i + 1])

func is_segment_traversable(from_position: Vector2, to_position: Vector2, target_index: int) -> bool:
	var k := _key(from_position, to_position)
	var verdict: bool
	if _blocked.has(k):
		verdict = false
	elif _open.has(k):
		verdict = true
	else:
		verdict = default_traversable
	query_log.append({
		"from": from_position,
		"to": to_position,
		"target_index": target_index,
		"verdict": verdict,
	})
	return verdict

func total_queries() -> int:
	return query_log.size()

func reset_observations() -> void:
	query_log.clear()
