extends RefCounted
## ColorCandidateIndex — preload this script
## (res://scripts/gameplay/targeting/color_candidate_index.gd) rather than
## relying on global class_name lookup (AL-001).
##
## M13 — Color Candidate Index `[PERFORMANCE]`. The color-grouped query/cache
## layer that answers ONE narrow question:
##
##   Which currently ACTIVE cells match a given palette/color — as RAW color
##   candidates?
##
## Candidate contract (docs/02_TECH_ARCHITECTURE.md / META-C004 owner rule):
##   valid index AND ACTIVE AND matching color AND not caller-excluded/reserved.
##
## A raw color candidate is NOT a reachable/targetable final target. A matching
## ACTIVE cell can still be fully enclosed by other ACTIVE cells with no legal
## access path (AL-028). Reachability is a SEPARATE downstream concern; this
## index proves color membership only and never claims reachability.
##
## This class is CANDIDATE DATA ONLY. It is NOT:
##   - Reachability/access truth — it does not filter blocked/unreachable cells;
##   - TargetSelector (M15) — it does not choose WHICH cell a bot cleans;
##   - RoutingSystem (M16+) — it does not decide HOW a bot travels;
##   - Reservation state (M14) — it does not own/store/atomically manage
##     reservations. Callers pass a reserved/excluded index set per query;
##     nothing about it is retained.
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
## color_id (int) -> Array[int] of ACTIVE cell indices, kept sorted ascending.
## Only colors with at least one ACTIVE cell have an entry.
var _buckets: Dictionary = {}
var _bound: bool = false

## Matches the from_level_data() convention: returns the real instance, typed
## as RefCounted because self-referential static typing is unreliable headless.
static func create() -> RefCounted:
	return load("res://scripts/gameplay/targeting/color_candidate_index.gd").new()

## Bind to a BoardState and build the color index from its current ACTIVE cells.
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

## Synchronize one cell after a BoardState mutation. ACTIVE -> present in its
## color bucket exactly once; CLEARED -> absent. Returns false for unbound use
## or an invalid index, without corrupting existing buckets.
func sync_cell(index: int) -> bool:
	if not _bound or _board == null:
		return false
	if not _board.is_valid_index(index):
		return false
	var color_id: int = _board.get_color_id(index)
	var state: int = _board.get_cell_state(index)
	if state == BoardState.CellState.ACTIVE:
		_bucket_add(color_id, index)
	else:
		_bucket_remove(color_id, index)
	return true

## Detached, row-major-ordered list of raw ACTIVE color candidates for a color,
## minus any caller-supplied reserved/excluded indices. Returns a fresh Array
## every call — mutating it cannot affect cached truth. Empty when unbound,
## when the color has no ACTIVE cells, or when all are excluded. These are RAW
## color candidates, NOT proven reachable/targetable final targets.
func get_candidates(color_id: int, excluded = []) -> Array:
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

## Cheap has-candidate check for a color without materializing the full list.
## Honors the same caller-supplied reserved/excluded set. False when unbound.
## True only means a raw color candidate exists — never that one is reachable.
func has_candidates(color_id: int, excluded = []) -> bool:
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

## Count of raw ACTIVE color candidates for a color (excluded set honored).
## 0 when unbound.
func count_candidates(color_id: int, excluded = []) -> int:
	return get_candidates(color_id, excluded).size()

func is_bound() -> bool:
	return _bound

## Color ids that currently have at least one ACTIVE candidate (unordered).
## Detached.
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
		if _board.get_cell_state(i) == BoardState.CellState.ACTIVE:
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
