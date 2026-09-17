extends RefCounted
## BatchSupplyEngine — M23 deterministic FIFO batch-supply data engine. Preload this
## script (res://scripts/gameplay/supply/batch_supply_engine.gd). Gameplay-domain
## only: NO Control/UI/BoardRenderer dependency, NO target selection, NO
## ReservationState/routing/dispatch/clearing. It owns supply data + queue semantics
## and a transactional front-selection handoff for the future M24 slot engine
## (OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01 §2/§5).
##
## Exactly 3/4/5 independent FIFO columns (index 0 = front). Preview depth 3 or 4;
## player-facing queries never reveal deeper hidden batches. Front-only selection is
## transactional: begin does not pop; commit removes exactly the selected front of
## exactly its column; cancel/stale/double/cross-column/forged commits fail closed.

const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchSelectionTransaction = preload("res://scripts/gameplay/supply/batch_selection_transaction.gd")

const MIN_COLUMNS := 3
const MAX_COLUMNS := 5
const MIN_PREVIEW := 3
const MAX_PREVIEW := 4

var _column_count: int = 0
var _preview_depth: int = 0
var _columns: Array = []            # Array[Array[ColorBatch]] — engine-owned
var _initial: Array = []            # Array[Array[Dictionary]] — for exact reset
var _open_tokens: Dictionary = {}   # token_id -> {"column": int, "front_id": String}
var _next_token_id: int = 1
var _seed: int = 0
var _palette_size: int = -1

## Fail-closed factory. column_count in [3,5], preview_depth in [3,4]; else null.
static func create(column_count, preview_depth) -> RefCounted:
	if typeof(column_count) != TYPE_INT or column_count < MIN_COLUMNS or column_count > MAX_COLUMNS:
		return null
	if typeof(preview_depth) != TYPE_INT or preview_depth < MIN_PREVIEW or preview_depth > MAX_PREVIEW:
		return null
	var e = load("res://scripts/gameplay/supply/batch_supply_engine.gd").new()
	e._column_count = column_count
	e._preview_depth = preview_depth
	e._columns = []
	for _i in range(column_count):
		e._columns.append([])
	e._initial = e._snapshot_initial(e._columns)
	return e

## Install a candidate layout. Fail-closed + no partial mutation: builds into a temp
## and only commits it when the WHOLE layout validates (right column count, every
## entry a real ColorBatch, no empty/duplicate batch_id). Engine keeps its own copies.
func load_columns(cols) -> bool:
	if typeof(cols) != TYPE_ARRAY or cols.size() != _column_count:
		return false
	var seen := {}
	var built: Array = []
	for col in cols:
		if typeof(col) != TYPE_ARRAY:
			return false
		var q: Array = []
		for b in col:
			if not (b is ColorBatch):
				return false
			var bid: String = b.get_batch_id()
			if bid.is_empty() or seen.has(bid):
				return false
			seen[bid] = true
			q.append(b.duplicate_batch())
		built.append(q)
	_columns = built
	_initial = _snapshot_initial(built)
	_open_tokens.clear()
	return true

func set_seed(seed: int) -> void:
	_seed = seed

func set_palette_size(palette_size: int) -> void:
	_palette_size = palette_size

func get_seed() -> int:
	return _seed

func get_column_count() -> int:
	return _column_count

func get_preview_depth() -> int:
	return _preview_depth

func _valid_column(column) -> bool:
	return typeof(column) == TYPE_INT and column >= 0 and column < _column_count

# ------------------------------------------------- player-facing queries --

## Detached copy of the front batch of `column`, or null when empty/invalid.
func get_front(column):
	if not _valid_column(column) or _columns[column].is_empty():
		return null
	return _columns[column][0].duplicate_batch()

## Detached copies of up to preview_depth visible rows (front first). Never reveals
## deeper hidden batches.
func get_preview(column) -> Array:
	var out: Array = []
	if not _valid_column(column):
		return out
	var q: Array = _columns[column]
	var n: int = mini(_preview_depth, q.size())
	for i in range(n):
		out.append(q[i].duplicate_batch())
	return out

func get_remaining(column) -> int:
	if not _valid_column(column):
		return 0
	return _columns[column].size()

func is_column_exhausted(column) -> bool:
	return _valid_column(column) and _columns[column].is_empty()

func is_exhausted() -> bool:
	for q in _columns:
		if not q.is_empty():
			return false
	return true

## Player-facing detached snapshot: per column {front, preview(<=depth), remaining}.
## Hidden depth beyond preview is represented only as a remaining COUNT, never contents.
func player_snapshot() -> Array:
	var out: Array = []
	for c in range(_column_count):
		var q: Array = _columns[c]
		var front = null if q.is_empty() else q[0].to_dict()
		var preview: Array = []
		for i in range(mini(_preview_depth, q.size())):
			preview.append(q[i].to_dict())
		out.append({"front": front, "preview": preview, "remaining": q.size()})
	return out

## Non-player-facing FULL detached snapshot for tests/save/replay/debug only.
func debug_snapshot() -> Dictionary:
	var cols: Array = []
	for q in _columns:
		var qd: Array = []
		for b in q:
			qd.append(b.to_dict())
		cols.append(qd)
	return {"seed": _seed, "column_count": _column_count, "preview_depth": _preview_depth,
		"palette_size": _palette_size, "columns": cols}

# ------------------------------------------------- transactional selection --

## Begin a two-phase selection of the current front of `column`. Does NOT pop.
## Returns a BatchSelectionTransaction, or null if column invalid/empty.
func begin_front_selection(column):
	if not _valid_column(column) or _columns[column].is_empty():
		return null
	var front = _columns[column][0]
	var tid: int = _next_token_id
	_next_token_id += 1
	_open_tokens[tid] = {"column": column, "front_id": front.get_batch_id()}
	return BatchSelectionTransaction.new(tid, column, front.get_batch_id(), front.duplicate_batch())

## Commit: remove exactly the selected front of exactly its column. Fails closed for
## a malformed/forged token, a consumed/unknown token, or a front that has since
## changed (another commit or a reset). Advances only the originating column.
func commit(tx) -> bool:
	if not (tx is BatchSelectionTransaction):
		return false
	var tid: int = tx.get_token_id()
	if not _open_tokens.has(tid):
		return false
	var rec: Dictionary = _open_tokens[tid]
	var col: int = rec["column"]
	if not _valid_column(col) or _columns[col].is_empty() \
			or _columns[col][0].get_batch_id() != rec["front_id"]:
		_open_tokens.erase(tid)  # stale front — consume the token, change nothing
		return false
	_columns[col].remove_at(0)
	_open_tokens.erase(tid)
	return true

## Cancel: leave every column unchanged. Consumes the token if valid; harmless
## otherwise (fails closed to false).
func cancel(tx) -> bool:
	if not (tx is BatchSelectionTransaction):
		return false
	var tid: int = tx.get_token_id()
	if not _open_tokens.has(tid):
		return false
	_open_tokens.erase(tid)
	return true

func has_open_transaction(tx) -> bool:
	return tx is BatchSelectionTransaction and _open_tokens.has(tx.get_token_id())

# --------------------------------------------------------------- reset --

## Restore the exact initial candidate layout; invalidate every outstanding token.
## Does not regenerate a different layout.
func reset() -> void:
	_open_tokens.clear()
	_columns = _rebuild_from_initial()

func _snapshot_initial(cols: Array) -> Array:
	var out: Array = []
	for q in cols:
		var qd: Array = []
		for b in q:
			qd.append(b.to_dict())
		out.append(qd)
	return out

func _rebuild_from_initial() -> Array:
	var out: Array = []
	for qd in _initial:
		var q: Array = []
		for d in qd:
			q.append(ColorBatch.make(d["batch_id"], d["color_id"], d["robot_count"]))
		out.append(q)
	return out
