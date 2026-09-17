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
##
## Transaction authenticity (M23 V02, F-M23-V01-STRICT-001): an open transaction is
## bound to the EXACT RefCounted instance minted by begin_front_selection(). commit,
## cancel and has_open_transaction require reference identity, not just a matching
## numeric token id. A freshly constructed same-class object carrying a live token id
## — or a token whose fields were mutated to another live id — fails closed.
##
## Candidate metadata (M23 V02, F-M23-V01-STRICT-003): seed + palette size + column
## order are established together by an atomic candidate-load seam and snapshotted
## together, so reset() restores the full committed initial truth.

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
# Authoritative open-transaction map keyed by the engine-known runtime instance id of
# the minted transaction object (get_instance_id() — immutable, not caller-mutable).
# Each record is engine-owned truth: {"token_id": int, "column": int,
# "front_id": String, "object": BatchSelectionTransaction}. The submitted object's
# visible _token_id/_column/_front_batch_id/detached front are informational snapshots
# only and are NEVER read for authority or for locating/mutating engine state.
var _open_tokens: Dictionary = {}   # instance_id -> record (above)
var _next_token_id: int = 1
var _seed: int = 0
var _palette_size: int = -1
# Committed initial candidate metadata (snapshotted together with _initial columns).
var _initial_seed: int = 0
var _initial_palette_size: int = -1

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
	e._initial_seed = e._seed
	e._initial_palette_size = e._palette_size
	return e

## Atomic candidate load: establishes queue + seed + palette size together and
## snapshots them together as the committed initial truth. Fail-closed with NO partial
## mutation: builds into a temp and only commits when the WHOLE candidate validates.
## Every batch value is revalidated at this trust boundary (is ColorBatch is not proof
## on its own — underscore fields are not language-private in GDScript).
func load_candidate(cols, seed, palette_size) -> bool:
	if typeof(seed) != TYPE_INT:
		return false
	if typeof(palette_size) != TYPE_INT:
		return false
	var built = _build_columns(cols, palette_size)
	if built == null:
		return false
	_columns = built
	_seed = seed
	_palette_size = palette_size
	_initial = _snapshot_initial(built)
	_initial_seed = seed
	_initial_palette_size = palette_size
	_open_tokens.clear()
	return true

## Install a candidate layout, keeping current seed/palette metadata. Fail-closed +
## no partial mutation. Retained for direct-layout callers; generators should use
## load_candidate() so metadata is committed atomically with the queue.
func load_columns(cols) -> bool:
	return load_candidate(cols, _seed, _palette_size)

## Build engine-owned validated column copies from `cols`, or null on any violation.
## Revalidates each batch's observable value (non-empty unique id, color_id >= 0,
## robot_count > 0, and color_id < palette_size when palette_size >= 0). No engine
## state is touched here — the caller commits only on a non-null return.
func _build_columns(cols, palette_size):
	if typeof(cols) != TYPE_ARRAY or cols.size() != _column_count:
		return null
	var seen := {}
	var built: Array = []
	for col in cols:
		if typeof(col) != TYPE_ARRAY:
			return null
		var q: Array = []
		for b in col:
			if not (b is ColorBatch):
				return null
			var bid = b.get_batch_id()
			if typeof(bid) != TYPE_STRING or (bid as String).is_empty() or seen.has(bid):
				return null
			var cid = b.get_color_id()
			if typeof(cid) != TYPE_INT or cid < 0:
				return null
			if palette_size >= 0 and cid >= palette_size:
				return null
			var rc = b.get_robot_count()
			if typeof(rc) != TYPE_INT or rc <= 0:
				return null
			seen[bid] = true
			q.append(b.duplicate_batch())
		built.append(q)
	return built

func set_seed(seed: int) -> void:
	_seed = seed

func set_palette_size(palette_size: int) -> void:
	_palette_size = palette_size

func get_seed() -> int:
	return _seed

func get_palette_size() -> int:
	return _palette_size

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
## Returns a BatchSelectionTransaction, or null if column invalid/empty. The engine
## records the object under its immutable runtime instance id, so only that exact
## minted object authenticates later — regardless of any later field mutation on it.
func begin_front_selection(column):
	if not _valid_column(column) or _columns[column].is_empty():
		return null
	var front = _columns[column][0]
	var tid: int = _next_token_id
	_next_token_id += 1
	var tx = BatchSelectionTransaction.new(tid, column, front.get_batch_id(), front.duplicate_batch())
	# Key by engine-known runtime identity — NOT by the caller-mutable token id.
	_open_tokens[tx.get_instance_id()] = {"token_id": tid, "column": column,
		"front_id": front.get_batch_id(), "object": tx}
	return tx

## Resolve `tx` to its authentic engine-owned open record, or {} otherwise. Authority
## is the immutable runtime instance id of the exact minted object — a value the caller
## cannot forge or mutate. A forged same-class object (fresh instance) has a different
## instance id and is absent from the map; the authentic object stays recognized even
## after its visible _token_id/_column/_front_batch_id/front snapshot are mutated,
## because none of those fields is read here.
func _authentic_record(tx) -> Dictionary:
	if not (tx is BatchSelectionTransaction):
		return {}
	var iid: int = tx.get_instance_id()
	if not _open_tokens.has(iid):
		return {}
	return _open_tokens[iid]

## Commit: remove exactly the selected front of exactly the ORIGINAL column recorded at
## begin time (engine-owned record, never the object's mutable fields). Fails closed for
## a malformed/forged/consumed object or a front that has since changed (another commit
## or a reset). Advances only the originating column.
func commit(tx) -> bool:
	var rec: Dictionary = _authentic_record(tx)
	if rec.is_empty():
		return false
	var iid: int = tx.get_instance_id()
	var col: int = rec["column"]
	if not _valid_column(col) or _columns[col].is_empty() \
			or _columns[col][0].get_batch_id() != rec["front_id"]:
		_open_tokens.erase(iid)  # stale front — consume the token, change nothing
		return false
	_columns[col].remove_at(0)
	_open_tokens.erase(iid)
	return true

## Cancel: leave every column unchanged. Consumes the token only when the submitted
## object is the exact authentic minted instance; a forged/foreign object fails closed
## to false and never releases the legitimate open token.
func cancel(tx) -> bool:
	var rec: Dictionary = _authentic_record(tx)
	if rec.is_empty():
		return false
	_open_tokens.erase(tx.get_instance_id())
	return true

## True only for the exact authentic minted instance (by engine-owned runtime identity).
## A forged same-class object copying another transaction's visible fields is NOT
## reported as owning it.
func has_open_transaction(tx) -> bool:
	return not _authentic_record(tx).is_empty()

# --------------------------------------------------------------- reset --

## Restore the exact initial committed candidate — queue/order, seed, palette size —
## and invalidate every outstanding token. Does not regenerate a different layout.
func reset() -> void:
	_open_tokens.clear()
	_columns = _rebuild_from_initial()
	_seed = _initial_seed
	_palette_size = _initial_palette_size

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
