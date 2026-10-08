extends RefCounted
## PendingPackQueue — preload (res://scripts/collection/pending_pack_queue.gd).
##
## M43-C005F-PHASE2-R01 — the durable FIFO of EARNED card packs that the player has been granted
## but not yet finished opening. A RewardGrantService grant carrying `standard_card_packs` /
## `premium_card_packs` ENQUEUES here (EconomyServices handler) instead of drawing; the pack is
## drawn exactly once later by PackCommitTransaction under the entry id, and the entry is only
## removed (acknowledged) after the shipping pack ceremony completed and its receipt exists.
##
##   entry = {id, kind}   id = "earned:<parent reward tx>:<kind>:<ordinal>"  (stable, unique)
##
## The entry id IS the pack transaction / presentation id, so a commit that already happened
## (app killed mid-ceremony) is replayed from its durable receipt, never redrawn.
## Snapshot {version: 1, entries: [{id, kind}, ...]} in FIFO order; strict all-or-nothing import.
## Data only: it never draws, grants or touches Collection.

const IntDomain = preload("res://scripts/economy/int_domain.gd")

const VERSION := 1
const KINDS := ["standard", "premium"]
const ID_PREFIX := "earned:"

var _entries: Array = []   ## [{id, kind}] FIFO

static func entry_id(parent_tx: String, kind: String, ordinal: int) -> String:
	return "%s%s:%s:%d" % [ID_PREFIX, parent_tx, kind, ordinal]

## Enqueue `count` packs of `kind` for the reward transaction `parent_tx`. All-or-nothing:
## refuses (false, no change) a bad kind / count / parent id or any id already queued.
func enqueue(parent_tx: String, kind: String, count: int) -> bool:
	if parent_tx.is_empty() or parent_tx != parent_tx.strip_edges() or not KINDS.has(kind) or count < 0:
		return false
	var add: Array = []
	for i in range(count):
		var id := entry_id(parent_tx, kind, i)
		if has(id):
			return false
		add.append({"id": id, "kind": kind})
	_entries.append_array(add)
	return true

func has(id: String) -> bool:
	return _entries.any(func(e): return e["id"] == id)

## Oldest pending entry ({} when empty).
func front() -> Dictionary:
	return (_entries[0] as Dictionary).duplicate() if not _entries.is_empty() else {}

func entries() -> Array:
	return _entries.duplicate(true)

func size() -> int:
	return _entries.size()

func count_of(kind: String) -> int:
	return _entries.filter(func(e): return e["kind"] == kind).size()

## Acknowledge (remove) one entry. False when unknown.
func remove(id: String) -> bool:
	for i in range(_entries.size()):
		if _entries[i]["id"] == id:
			_entries.remove_at(i)
			return true
	return false

func snapshot() -> Dictionary:
	return {"version": VERSION, "entries": _entries.duplicate(true)}

static func empty_snapshot() -> Dictionary:
	return {"version": VERSION, "entries": []}

## Strict: exactly {version, entries}; each entry exactly {id, kind} with a supported kind and a
## non-empty, trimmed, "earned:"-prefixed, unique id. Anything else fails closed (no change).
func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or s.size() != 2 or not s.has("version") or not s.has("entries"):
		return false
	if IntDomain.exact_int(s["version"]) != VERSION or typeof(s["entries"]) != TYPE_ARRAY:
		return false
	var seen := {}
	var out: Array = []
	for e in s["entries"]:
		if typeof(e) != TYPE_DICTIONARY or e.size() != 2 or not e.has("id") or not e.has("kind"):
			return false
		if typeof(e["id"]) != TYPE_STRING or typeof(e["kind"]) != TYPE_STRING:
			return false
		var id := String(e["id"])
		if id.is_empty() or id != id.strip_edges() or not id.begins_with(ID_PREFIX) or seen.has(id) or not KINDS.has(e["kind"]):
			return false
		seen[id] = true
		out.append({"id": id, "kind": String(e["kind"])})
	_entries = out
	return true
