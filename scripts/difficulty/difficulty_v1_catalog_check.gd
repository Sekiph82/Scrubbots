extends RefCounted
## DifficultyV1CatalogCheck — preload
## (res://scripts/difficulty/difficulty_v1_catalog_check.gd).
##
## SB-M36-002 — validates that the M35 production catalog is compatible with
## Difficulty V1 WITHOUT re-locking obsolete class=dimension semantics:
##   - each entry's difficulty is a known class token (EASY/MEDIUM/HARD/VERY_HARD);
##   - each entry's width/height fall inside the production board envelope from
##     `level_progression_v1.json` (20..59, rectangular allowed);
##   - class is NOT derived from dimensions — this checker never asserts that a
##     given class implies a given dimension band;
##   - TEST fixtures are rejected (delegated to the catalog itself).
##
## This is a clearly isolated Difficulty V1 compatibility seam. The legacy
## dimension-band `ProductionLevelValidator` still runs inside the catalog for
## M21 structural compatibility, but it no longer defines player-facing class.

const KNOWN_CLASSES := ["EASY", "MEDIUM", "HARD", "VERY_HARD"]

var _min_dim := 20
var _max_dim := 59

func _init(progression_config_path: String = "res://data/config/level_progression_v1.json") -> void:
	var f := FileAccess.open(progression_config_path, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			var env = data.get("productionBoardEnvelope", {})
			_min_dim = int(env.get("minWidth", 20))
			_max_dim = int(env.get("maxWidth", 59))
	f.close()

## catalog: a loaded LevelCatalog. Returns {ok: bool, errors: [String]}.
func validate_catalog(catalog) -> Dictionary:
	var errors: Array = []
	for entry in catalog.get_entries_ordered():
		if not KNOWN_CLASSES.has(entry.difficulty):
			errors.append("%s: unknown Difficulty V1 class '%s'" % [entry.id, entry.difficulty])
		if entry.width < _min_dim or entry.width > _max_dim:
			errors.append("%s: width %d outside envelope %d..%d" % [entry.id, entry.width, _min_dim, _max_dim])
		if entry.height < _min_dim or entry.height > _max_dim:
			errors.append("%s: height %d outside envelope %d..%d" % [entry.id, entry.height, _min_dim, _max_dim])
	return {"ok": errors.is_empty(), "errors": errors}
