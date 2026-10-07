extends RefCounted
## CompositeLevelCatalog — preload (res://scripts/content_runtime/composite_level_catalog.gd).
##
## Read model over the builtin LevelCatalog + the verified active remote set (CP04-009).
## Same consumer surface as LevelCatalog (get_entries_ordered / get_entry_by_id / size)
## and the same deep-copy guarantee. The builtin catalog keeps its own res:// confinement
## and explicit orders untouched; remote levels get the V1 campaign order: the manifest
## `levels` array order, appended right after the highest builtin order. A remote ID that
## collides (casefold) with a builtin ID drops the WHOLE remote set (fail closed; builtin
## levels can never be overridden).

const LevelCatalogEntry = preload("res://scripts/data/level_catalog_entry.gd")

var _entries: Array = []
var _by_id: Dictionary = {}
var remote_rejected := ""

func _init(builtin_catalog, remote_levels: Array = []) -> void:
	var max_order := 0
	var fold := {}
	for e in builtin_catalog.get_entries_ordered():
		_entries.append(e)
		_by_id[e.id] = e
		max_order = maxi(max_order, int(e.order))
		fold[String(e.id).to_lower()] = true
	var remote: Array = []
	for r in remote_levels:
		if fold.has(String(r["id"]).to_lower()):
			remote_rejected = "BUILTIN_ID_COLLISION"
			return
		fold[String(r["id"]).to_lower()] = true
		var e := LevelCatalogEntry.new()
		e.id = r["id"]
		e.order = max_order + 1 + remote.size()
		e.level_path = r["level_path"]
		e.metadata_path = r["metadata_path"]
		e.preview_path = ""        # .scrubpack V1 carries no preview; placeholder behaviour applies
		e.preview_exists = true    # same as a builtin entry with an empty preview_path
		e.difficulty = r["difficulty"]
		e.width = int(r["width"])
		e.height = int(r["height"])
		e.supply_plan_path = r["supply_plan_path"]
		remote.append(e)
	for e in remote:
		_entries.append(e)
		_by_id[e.id] = e

func get_entries_ordered() -> Array:
	var out: Array = []
	for e in _entries:
		out.append(e.duplicate())
	return out

func get_entry_by_id(id: String):
	var e = _by_id.get(id, null)
	return e.duplicate() if e != null else null

func size() -> int:
	return _entries.size()
