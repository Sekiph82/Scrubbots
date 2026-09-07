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

## Narrow duck-typed BoardState surface M13 consumes. A dependency must be an
## Object exposing ALL of these before we call any of them (F-M13-STRICT-001).
## Duck-typed, not `is BoardState`, so a compatible test double/spy still binds.
const _REQUIRED_BOARD_API := ["get_cell_count", "is_valid_index", "get_cell_state", "get_color_id"]

## Bind to a BoardState and build the color index from its current ACTIVE cells.
## Fails closed (false, unbound, empty) for null, a Variant lacking the narrow
## board API, or any malformed dependency truth discovered during the
## transactional build. A malformed bind after valid state neutralizes the prior
## binding so no stale/malformed dependency remains usable (F-M13-STRICT-001).
func bind(board) -> bool:
	if board == null:
		return false
	if not _has_board_api(board):
		_neutralize()
		return false
	var built = _scan(board)
	if built == null:
		_neutralize()
		return false
	_board = board
	_buckets = built
	_bound = true
	return true

## Discard any prior board/index, then bind to a fresh board. Explicit
## destructive fresh-board replacement path. Returns false and leaves the index
## cleared+unbound for null or malformed input.
func rebind(board) -> bool:
	_neutralize()
	return bind(board)

## Full rebuild from current BoardState truth. No-op false if unbound. Fails
## closed and neutralizes if the board now yields malformed/unknown truth, so no
## stale or partially-rebuilt buckets are ever exposed (F-M13-STRICT-002).
func rebuild() -> bool:
	if not _bound or _board == null:
		return false
	var built = _scan(_board)
	if built == null:
		_neutralize()
		return false
	_buckets = built
	return true

## Synchronize one cell after a BoardState mutation. ACTIVE -> present in its
## color bucket exactly once; CLEARED -> absent. Returns false for unbound use
## or an invalid index, without corrupting existing buckets. An unknown/
## noncanonical cell state is NOT silently treated as CLEARED: it fails closed
## and neutralizes the cache so no stale/unknown membership is asserted as
## canonical truth (F-M13-STRICT-002).
func sync_cell(index: int) -> bool:
	if not _bound or _board == null:
		return false
	if not _board.is_valid_index(index):
		return false
	var state = _board.get_cell_state(index)
	if typeof(state) != TYPE_INT:
		return false
	if state == BoardState.CellState.ACTIVE:
		var color_id = _board.get_color_id(index)
		if typeof(color_id) != TYPE_INT or color_id < 0:
			return false
		_bucket_add(color_id, index)
		return true
	if state == BoardState.CellState.CLEARED:
		var color_id = _board.get_color_id(index)
		if typeof(color_id) != TYPE_INT or color_id < 0:
			return false
		_bucket_remove(color_id, index)
		return true
	# Unknown/noncanonical state -> fail closed, invalidate cache.
	_neutralize()
	return false

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
	# null is the intentional no-exclusion contract (documented, tested).
	if excluded == null:
		return bucket.duplicate()
	# Unsupported exclusion container -> fail closed, cache untouched.
	if not _is_supported_exclusion(excluded):
		return []
	if excluded.is_empty():
		return bucket.duplicate()
	var exc: Dictionary = _to_int_set(excluded)
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
	if excluded == null:
		return true
	if not _is_supported_exclusion(excluded):
		return false
	if excluded.is_empty():
		return true
	var exc: Dictionary = _to_int_set(excluded)
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

## Exact-identity board coherence check (strict-v2, F-M15-STRICT-002). Returns
## true only when this index is bound to the SAME BoardState INSTANCE (reference
## identity — not merely equal dimensions/content), false when unbound. It never
## exposes the internal board reference; a caller can only ask "are you bound to
## THIS board?", never obtain the board.
func is_bound_to(board) -> bool:
	return _bound and _board != null and _board == board

## Color ids that currently have at least one ACTIVE candidate (unordered).
## Detached.
func get_color_ids() -> Array:
	if not _bound:
		return []
	return _buckets.keys()

# ------------------------------------------------------------- internals --

## True only for an Object exposing the whole narrow board API. Guards against
## faulting when a non-Object Variant (int/String/Vector2) is passed as a board.
func _has_board_api(board) -> bool:
	if not (board is Object):
		return false
	for m in _REQUIRED_BOARD_API:
		if not board.has_method(m):
			return false
	return true

## Neutralize to a safe unbound/empty state. Used on every fail-closed path so
## no malformed/stale/partial dependency truth can remain queryable.
func _neutralize() -> void:
	_board = null
	_buckets = {}
	_bound = false

## Transactional build. Scans the board into a LOCAL buckets Dictionary and
## returns it only if every scanned index yields canonical truth:
##   - get_cell_count is a non-negative int;
##   - each index is valid per dependency truth;
##   - each cell state is exactly ACTIVE or CLEARED (unknown -> fail);
##   - each ACTIVE cell's color id is an int >= 0.
## Returns null on any malformed value, so the caller never commits partial
## buckets or faults on a bad return type. Ascending iteration keeps buckets
## row-major without sorting.
func _scan(board):
	var count = board.get_cell_count()
	if typeof(count) != TYPE_INT or count < 0:
		return null
	var buckets: Dictionary = {}
	for i in count:
		var valid = board.is_valid_index(i)
		if typeof(valid) != TYPE_BOOL or not valid:
			return null
		var state = board.get_cell_state(i)
		if typeof(state) != TYPE_INT:
			return null
		if state == BoardState.CellState.ACTIVE:
			var color_id = board.get_color_id(i)
			if typeof(color_id) != TYPE_INT or color_id < 0:
				return null
			if not buckets.has(color_id):
				buckets[color_id] = []
			buckets[color_id].append(i)
		elif state != BoardState.CellState.CLEARED:
			return null # unknown/noncanonical state -> fail closed, no partial commit
	return buckets

## Supported caller-exclusion containers: Array, PackedInt32Array, Dictionary
## (keys as excluded indices). Everything else fails closed. null is handled by
## callers as the intentional no-exclusion contract before reaching here.
func _is_supported_exclusion(excluded) -> bool:
	var t := typeof(excluded)
	return t == TYPE_ARRAY or t == TYPE_PACKED_INT32_ARRAY or t == TYPE_DICTIONARY

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

## Build an integer-only exclusion set. Only TYPE_INT entries exclude, so a
## float 2.0 or String "2" can never exclude integer candidate index 2. For a
## Dictionary, integer KEYS define exclusions and values are ignored. Duplicate
## and out-of-range ints are harmless (set membership / no bucket match).
func _to_int_set(excluded) -> Dictionary:
	var s: Dictionary = {}
	var entries = excluded.keys() if typeof(excluded) == TYPE_DICTIONARY else excluded
	for it in entries:
		if typeof(it) == TYPE_INT:
			s[it] = true
	return s
