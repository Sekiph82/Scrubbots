extends RefCounted
## M17-C002 V03 sensitivity double (F-M17-STRICT-003 / §5). Wraps a real
## ProductionAccessQuery and reports exactly ONE directed orthogonal edge
## (from_center -> to_center) as NOT traversable, delegating everything else. All
## cells otherwise report their true class. Proves the planner asks segment
## access truth for EVERY used edge, not just cell class. Preload it (AL-001).

const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")

var _inner
var _blk_from: Vector2
var _blk_to: Vector2
## Directly observed: set true if the blocked edge was ever queried.
var blocked_edge_queried: bool = false

func _init(board, blocked_from: Vector2, blocked_to: Vector2) -> void:
	_inner = ProductionAccessQuery.new(board)
	_blk_from = blocked_from
	_blk_to = blocked_to

func is_bound_to(board) -> bool:
	return _inner.is_bound_to(board)

func classify_cell(cx: int, cy: int, target_index: int) -> int:
	return _inner.classify_cell(cx, cy, target_index)

func cell_of_point(p: Vector2) -> Vector2i:
	return _inner.cell_of_point(p)

func is_segment_traversable(from_position: Vector2, to_position: Vector2, target_index: int) -> bool:
	if from_position.is_equal_approx(_blk_from) and to_position.is_equal_approx(_blk_to):
		blocked_edge_queried = true
		return false
	return _inner.is_segment_traversable(from_position, to_position, target_index)
