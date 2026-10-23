extends RefCounted
## FeatureUnlocks — preload (res://scripts/progression/feature_unlocks.gd).
##
## SB-M44-010/011/031 — strict reader of the owner feature unlock table
## data/config/feature_unlocks_v1.json (feature id -> campaign level). A feature is unlocked
## iff the save is grandfathered or frontier >= its level. Unlike FtueConfig this FAILS OPEN:
## a missing / malformed file (ok:false) or an id not in the table never locks anything, since
## a broken config must not strand a player behind locks. UI asks AppState.feature_unlocked().

const PATH := "res://data/config/feature_unlocks_v1.json"
const SCHEMA := "scrubbots.feature_unlocks.v1"
const VERSION := 1

var cfg: Dictionary = {"ok": false, "reason": "not_loaded", "unlocks": {}}

func load_config(path: String = PATH) -> Dictionary:
	cfg = validate(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else _bad("missing")
	return cfg

static func validate(d) -> Dictionary:
	if typeof(d) != TYPE_DICTIONARY or str(d.get("schema")) != SCHEMA or not _is_int(d.get("version")) or int(d["version"]) != VERSION:
		return _bad("schema")
	if typeof(d.get("unlocks")) != TYPE_DICTIONARY or (d["unlocks"] as Dictionary).is_empty():
		return _bad("unlocks")
	var unlocks := {}
	for id in d["unlocks"]:
		var v = d["unlocks"][id]
		if typeof(id) != TYPE_STRING or String(id).is_empty() or not _is_int(v) or int(v) < 1:
			return _bad("unlocks")
		unlocks[String(id)] = int(v)
	return {"ok": true, "reason": "", "version": VERSION, "unlocks": unlocks}

## Campaign level that unlocks `feature_id`; 1 for an id not in the table (or a bad config).
func unlock_level(feature_id: String) -> int:
	return int(cfg["unlocks"].get(feature_id, 1))

func is_unlocked(feature_id: String, frontier_level: int, grandfathered: bool) -> bool:
	return grandfathered or frontier_level >= unlock_level(feature_id)

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "unlocks": {}}

static func _is_int(v) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
