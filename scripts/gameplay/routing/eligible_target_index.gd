extends RefCounted
## EligibleTargetIndex — preload this script
## (res://scripts/gameplay/routing/eligible_target_index.gd) rather than
## relying on global class_name lookup (AL-001).
##
## M13 — Eligible Target Index `[PERFORMANCE]`. The color-grouped query/cache
## layer that answers ONE question:
##
##   Which currently eligible DIRTY cells exist for a given palette/color?
##
## Eligibility (M13 definition, docs/02_TECH_ARCHITECTURE.md / M13-C001 prompt):
##   valid index AND DIRTY AND matching color AND not caller-excluded/reserved.
## No route/reachability/blocker rule is part of eligibility.
##
## This class is TARGETING DATA ONLY. It is NOT:
##   - TargetSelector (M15) — it does not choose WHICH cell a bot cleans;
##   - RoutingSystem (M16+) — it does not decide HOW a bot travels;
##   - Reservation state (M14) — it does not own/store/atomically manage
##     reservations. Callers pass a reserved/excluded index set per query;
##     nothing about it is retained.
## The "routing/" folder name does not authorize any of the above.
##
## Indexing is owned by BoardState (index = y*width + x). This class never
## re-derives that formula; it uses BoardState's index/color/state APIs.
##
## Steady-state color queries read a prebuilt per-color bucket instead of
## rescanning every board cell, so repeated queries do not cost a full
## get_cell_count() scan. Buckets stay in ascending index order (row-major),
## so query results are deterministic.

## Explicit preload rather than global class_name lookup — AL-001.
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Bound board (RefCounted BoardState) or null when unbound.
var _board = null
## color_id (int) -> Array[int] of DIRTY cell indices, kept sorted ascending.
## Only colors with at least one DIRTY cell have an entry.
var _buckets: Dictionary = {}
var _bound: bool = false

## Matches the from_level_data() convention: returns the real instance, typed
## as RefCounted because self-referential static typing is unreliable headless.
static func create() -> RefCounted:
	return load("res://scripts/gameplay/routing/eligible_target_index.gd").new()

## Bind to a BoardState and build the color index from its current DIRTY cells.
## Returns false (and stays unbound) for a null board.
func bind(board) -> bool:
	if board == null:
		return false
	_board = board
	_bound = true
	_rebuild_internal()
	return true

## Discard any prior board/index, then bind to a fresh board. Prevents stale
## candidates from an old board leaking into the new one. Returns false and
## leaves the index cleared+unbound if the new board is null.
func rebind(board) -> bool:
	_board = null
	_buckets.clear()
	_bound = false
	return bind(board)

## Full rebuild from current BoardState truth. No-op false if unbound.
func rebuild() -> bool:
	if not _bound or _board == null:
		return false
	_rebuild_internal()
	return true

## Synchronize one cell after a BoardState mutation. DIRTY -> present in its
## color bucket exactly once; CLEAN -> absent. Returns false for unbound use or
## an invalid index, without corrupting existing buckets.
func sync_cell(index: int) -> bool:
	if not _bound or _board == null:
		return false
	if not _board.is_valid_index(index):
		return false
	var color_id: int = _board.get_color_id(index)
	var state: int = _board.get_cell_state(index)
	if state == BoardState.CellState.DIRTY:
		_bucket_add(color_id, index)
	else:
		_bucket_remove(color_id, index)
	return true

## Detached, row-major-ordered list of eligible DIRTY indices for a color,
## minus any caller-supplied reserved/excluded indices. Returns a fresh Array
## every call — mutating it cannot affect cached truth. Empty when unbound,
## when the color has no DIRTY cells, or when all are excluded.
func get_eligible(color_id: int, excluded = []) -> Array:
	if not _bound:
		return []
	if not _buckets.has(color_id):
		return []
	var bucket: Array = _buckets[color_id]
	if excluded == null or excluded.is_empty():
		return bucket.duplicate()
	var exc: Dictionary = _to_set(excluded)
	var result: Array = []
	for idx in bucket:
		if not exc.has(idx):
			result.append(idx)
	return result

## Cheap has-work check for a color without materializing the full list.
## Honors the same caller-supplied reserved/excluded set. False when unbound.
func has_work(color_id: int, excluded = []) -> bool:
	if not _bound:
		return false
	if not _buckets.has(color_id):
		return false
	var bucket: Array = _buckets[color_id]
	if bucket.is_empty():
		return false
	if excluded == null or excluded.is_empty():
		return true
	var exc: Dictionary = _to_set(excluded)
	for idx in bucket:
		if not exc.has(idx):
			return true
	return false

## Count of eligible DIRTY cells for a color (excluded set honored). 0 unbound.
func count_eligible(color_id: int, excluded = []) -> int:
	return get_eligible(color_id, excluded).size()

func is_bound() -> bool:
	return _bound

## Color ids that currently have at least one DIRTY cell (unordered). Detached.
func get_color_ids() -> Array:
	if not _bound:
		return []
	return _buckets.keys()

# ------------------------------------------------------------- internals --

func _rebuild_internal() -> void:
	_buckets.clear()
	var count: int = _board.get_cell_count()
	# Ascending index iteration keeps every bucket row-major without sorting.
	for i in count:
		if _board.get_cell_state(i) == BoardState.CellState.DIRTY:
			var color_id: int = _board.get_color_id(i)
			if not _buckets.has(color_id):
				_buckets[color_id] = []
			_buckets[color_id].append(i)

func _bucket_add(color_id: int, index: int) -> void:
	if not _buckets.has(color_id):
		_buckets[color_id] = [index]
		return
	var bucket: Array = _buckets[color_id]
	var pos: int = bucket.bsearch(index)
	if pos < bucket.size() and bucket[pos] == index:
		return # already present — no duplicate
	bucket.insert(pos, index)

func _bucket_remove(color_id: int, index: int) -> void:
	if not _buckets.has(color_id):
		return
	var bucket: Array = _buckets[color_id]
	var pos: int = bucket.bsearch(index)
	if pos < bucket.size() and bucket[pos] == index:
		bucket.remove_at(pos)
		if bucket.is_empty():
			_buckets.erase(color_id)

func _to_set(items) -> Dictionary:
	var s: Dictionary = {}
	for it in items:
		s[it] = true
	return s
