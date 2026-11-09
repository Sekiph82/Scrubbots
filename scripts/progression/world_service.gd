extends RefCounted
## WorldService — preload (res://scripts/progression/world_service.gd).
##
## SB-M43-136..141 (owner 2026-10-22): the campaign world table, data/config/worlds_v1.json:
## 20 named worlds x 150 levels = 3000. A world ends at its last campaign level and the next
## starts at the following level. Pure and read-only: the current world is DERIVED from the
## progression frontier on every read (never saved), so nothing can desynchronize from the
## campaign. A malformed table (gap, overlap, not covering first_level..last_level) fails
## closed to []. Presentation/meta only: no solver, board or level data is read here.

const PATH := "res://data/config/worlds_v1.json"
const SCHEMA := "scrubbots.worlds.v1"

static var _cache := {}   ## path -> validated table (res:// never changes at runtime)

## {worlds: [{id, number, name, first, last, art}], fallback_art}; worlds [] when invalid.
static func load_table(path: String = PATH) -> Dictionary:
	if not _cache.has(path):
		_cache[path] = _parse(path)
	return _cache[path]

static func load_worlds(path: String = PATH) -> Array:
	return load_table(path)["worlds"]

static func _parse(path: String) -> Dictionary:
	var bad := {"worlds": [], "fallback_art": ""}
	if not FileAccess.file_exists(path):
		return bad
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK:
		return bad
	var d = j.data
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or typeof(d.get("worlds")) != TYPE_ARRAY \
			or typeof(d.get("fallback_art")) != TYPE_STRING or not _is_int(d.get("first_level")) or not _is_int(d.get("last_level")):
		return bad
	var out: Array = []
	var ids := {}
	var next := int(d["first_level"])
	for w in d["worlds"]:
		if typeof(w) != TYPE_DICTIONARY or typeof(w.get("id")) != TYPE_STRING or ids.has(w["id"]) \
				or typeof(w.get("name")) != TYPE_STRING or String(w["name"]).is_empty() \
				or not _is_int(w.get("number")) or int(w["number"]) != out.size() + 1 \
				or not _is_int(w.get("first")) or not _is_int(w.get("last")) \
				or int(w["first"]) != next or int(w["last"]) < int(w["first"]) \
				or not (w.get("art") == null or typeof(w.get("art")) == TYPE_STRING):
			return bad
		ids[w["id"]] = true
		next = int(w["last"]) + 1
		out.append({"id": String(w["id"]), "number": int(w["number"]), "name": String(w["name"]),
			"first": int(w["first"]), "last": int(w["last"]), "art": String(w["art"]) if w["art"] != null else ""})
	if out.is_empty() or int(d["first_level"]) != 1 or next != int(d["last_level"]) + 1:
		return bad
	return {"worlds": out, "fallback_art": String(d["fallback_art"])}

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and float(v) == floorf(float(v))

## The world containing campaign level `n`, or {} outside the table.
static func world_for_level(n: int, worlds: Array = load_worlds()) -> Dictionary:
	for w in worlds:
		if n >= int(w["first"]) and n <= int(w["last"]):
			return w
	return {}

static func world_by_id(id: String, worlds: Array = load_worlds()) -> Dictionary:
	for w in worlds:
		if w["id"] == id:
			return w
	return {}

## The world after `id`, or {} for the last world / an unknown id.
static func next_world(id: String, worlds: Array = load_worlds()) -> Dictionary:
	var w := world_by_id(id, worlds)
	return world_for_level(int(w["last"]) + 1, worlds) if not w.is_empty() else {}

## A world is complete once the frontier has passed its last level (forward-only campaign).
static func is_world_complete(id: String, frontier: int, worlds: Array = load_worlds()) -> bool:
	var w := world_by_id(id, worlds)
	return not w.is_empty() and frontier > int(w["last"])

## Levels of world `id` behind the frontier: {cleared, total} (cleared clamped to 0..total).
static func progress(id: String, frontier: int, worlds: Array = load_worlds()) -> Dictionary:
	var w := world_by_id(id, worlds)
	if w.is_empty():
		return {}
	var total := int(w["last"]) - int(w["first"]) + 1
	return {"cleared": clampi(frontier - int(w["first"]), 0, total), "total": total}

## "locked" | "current" | "completed" per world id for a frontier.
static func states(frontier: int, worlds: Array = load_worlds()) -> Dictionary:
	var out := {}
	for w in worlds:
		out[w["id"]] = "completed" if frontier > int(w["last"]) else ("current" if frontier >= int(w["first"]) else "locked")
	return out
