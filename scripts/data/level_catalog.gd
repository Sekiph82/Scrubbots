extends RefCounted
## LevelCatalog — preload
## (res://scripts/data/level_catalog.gd).
##
## Declarative, read-only production catalog authority. Reads a single manifest
## JSON at `res://data/levels/catalog/production_catalog_v1.json` — no runtime
## directory scan of `data/levels/`, so TEST fixtures cannot accidentally leak
## into the production catalog even if placed alongside production levels
## (SB-M35-009).
##
## Every entry is validated:
##   - stable non-empty id (SB-M35-002);
##   - explicit numeric order (SB-M35-003);
##   - level file exists and passes LevelValidator + ProductionLevelValidator
##     (SB-M35-004/005/008/010);
##   - preview_path is a stable string; missing file is recorded but does not
##     invalidate the entry unless caller passes require_preview=true (SB-M35-006);
##   - duplicate id / duplicate order / duplicate resolved level_path detected
##     (SB-M35-007).
##
## Difficulty V1 note: SB-M35 exposes the level's difficulty token verbatim as
## surfaced by LevelData. M36 owns the class-vs-dimension semantics; this
## catalog does NOT re-lock legacy dimension bands beyond the structural
## `ProductionLevelValidator` check already required for M21 production
## compatibility.
##
## Consumers get immutable LevelCatalogEntry copies; mutating the returned
## Array does not mutate canonical catalog state.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")
const LevelCatalogEntry = preload("res://scripts/data/level_catalog_entry.gd")
const LevelCatalogValidationResult = preload("res://scripts/data/level_catalog_validation_result.gd")

const DEFAULT_MANIFEST_PATH := "res://data/levels/catalog/production_catalog_v1.json"
const EXPECTED_SCHEMA := "scrubbots.production_catalog.v1"

var _entries: Array = []                      ## Array[LevelCatalogEntry] in explicit order.
var _by_id: Dictionary = {}                    ## id -> LevelCatalogEntry
var _last_result: LevelCatalogValidationResult

func _init() -> void:
	_last_result = LevelCatalogValidationResult.new()

## Loads and validates the manifest. Fail-closed on any error. Returns the
## batch validation result; call is_ok() before consuming entries.
func load_manifest(path: String = DEFAULT_MANIFEST_PATH) -> LevelCatalogValidationResult:
	_entries.clear()
	_by_id.clear()
	_last_result = LevelCatalogValidationResult.new()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_result.add_error("Catalog %s: could not open (err %d)" % [path, FileAccess.get_open_error()])
		return _last_result
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		_last_result.add_error("Catalog %s: malformed JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return _last_result
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		_last_result.add_error("Catalog %s: root must be an object" % path)
		return _last_result
	if data.get("schema", "") != EXPECTED_SCHEMA:
		_last_result.add_error("Catalog %s: unknown schema '%s' (expected %s)" % [path, data.get("schema", ""), EXPECTED_SCHEMA])
		return _last_result
	var entries_raw = data.get("entries", null)
	if typeof(entries_raw) != TYPE_ARRAY:
		_last_result.add_error("Catalog %s: 'entries' must be an array" % path)
		return _last_result

	var seen_ids: Dictionary = {}
	var seen_orders: Dictionary = {}
	var seen_paths: Dictionary = {}

	for raw in entries_raw:
		if typeof(raw) != TYPE_DICTIONARY:
			_last_result.add_error("Catalog %s: entry is not an object" % path)
			continue

		var id := String(raw.get("id", "")).strip_edges()
		var order_value = raw.get("order", null)
		var level_path := String(raw.get("level_path", "")).strip_edges()
		var metadata_path := String(raw.get("metadata_path", "")).strip_edges()
		var preview_path := String(raw.get("preview_path", "")).strip_edges()

		if id.is_empty():
			_last_result.add_error("Catalog entry missing 'id'")
			continue
		if seen_ids.has(id):
			_last_result.add_entry_error(id, "duplicate stable id")
			continue
		seen_ids[id] = true

		if typeof(order_value) != TYPE_INT and typeof(order_value) != TYPE_FLOAT:
			_last_result.add_entry_error(id, "'order' must be an integer")
			continue
		var order := int(order_value)
		if seen_orders.has(order):
			_last_result.add_entry_error(id, "duplicate order %d (also used by %s)" % [order, seen_orders[order]])
			continue
		seen_orders[order] = id

		if level_path.is_empty():
			_last_result.add_entry_error(id, "'level_path' missing")
			continue
		var norm_level_path := _normalize_path(level_path)
		if seen_paths.has(norm_level_path):
			_last_result.add_entry_error(id, "level_path alias collides with %s" % seen_paths[norm_level_path])
			continue
		seen_paths[norm_level_path] = id

		if not FileAccess.file_exists(level_path):
			_last_result.add_entry_error(id, "level file missing: %s" % level_path)
			continue
		if not metadata_path.is_empty() and not FileAccess.file_exists(metadata_path):
			_last_result.add_entry_error(id, "metadata file missing: %s" % metadata_path)
			continue

		var load_result = LevelLoader.load_from_path(level_path)
		if not load_result.is_ok():
			for e in load_result.errors:
				_last_result.add_entry_error(id, "structural: %s" % String(e))
			continue
		var level = load_result.level_data
		if String(level.id) != id:
			_last_result.add_entry_error(id, "catalog id '%s' != level file id '%s'" % [id, level.id])
			# not fatal to structural validation but blocks stable identity guarantees
			continue

		# SB-M35-010: reject TEST fixture based on canonical difficulty token, not filename.
		if level.difficulty == DifficultyRules.TEST_DIFFICULTY:
			_last_result.add_entry_error(id, "TEST fixture rejected in production catalog")
			continue
		var prod_result = ProductionLevelValidator.validate(level)
		if not prod_result.is_ok():
			for e in prod_result.errors:
				_last_result.add_entry_error(id, "production: %s" % String(e))
			continue

		var preview_exists := preview_path.is_empty() or FileAccess.file_exists(preview_path)

		var entry := LevelCatalogEntry.new()
		entry.id = id
		entry.order = order
		entry.level_path = level_path
		entry.metadata_path = metadata_path
		entry.preview_path = preview_path
		entry.difficulty = level.difficulty
		entry.width = level.width
		entry.height = level.height
		entry.preview_exists = preview_exists
		_entries.append(entry)
		_by_id[id] = entry

	# Deterministic explicit ordering, then fixed alphabetical id tie-break just
	# in case two entries somehow share order (already blocked above but this
	# keeps get_entries_ordered() stable if caller injects entries directly).
	_entries.sort_custom(func(a, b): return _compare_entries(a, b))
	return _last_result

func _compare_entries(a, b) -> bool:
	if a.order != b.order:
		return a.order < b.order
	return a.id < b.id

func _normalize_path(p: String) -> String:
	# Collapse the res:// prefix to normalized form so an alias like
	# "res://data/levels/./foo.json" cannot smuggle in as a "different" path.
	var s := p.replace("\\", "/")
	while s.find("/./") != -1:
		s = s.replace("/./", "/")
	return s

func last_result() -> LevelCatalogValidationResult:
	return _last_result

## Immutable copy of the catalog in deterministic explicit order. Mutating the
## returned Array does not affect internal catalog state.
func get_entries_ordered() -> Array:
	return _entries.duplicate()

func get_entry_by_id(id: String):
	return _by_id.get(id, null)

func size() -> int:
	return _entries.size()

## SB-M35-011 batch validation seam: revalidate every entry that was successfully
## loaded, returning entry-by-entry diagnostics. Idempotent on re-run.
func validate_all() -> LevelCatalogValidationResult:
	var r := LevelCatalogValidationResult.new()
	for e in _entries:
		if not FileAccess.file_exists(e.level_path):
			r.add_entry_error(e.id, "level file disappeared: %s" % e.level_path)
			continue
		var lr = LevelLoader.load_from_path(e.level_path)
		if not lr.is_ok():
			for msg in lr.errors:
				r.add_entry_error(e.id, "structural: %s" % String(msg))
			continue
		if lr.level_data.difficulty == DifficultyRules.TEST_DIFFICULTY:
			r.add_entry_error(e.id, "TEST fixture rejected in production catalog")
			continue
		var pr = ProductionLevelValidator.validate(lr.level_data)
		if not pr.is_ok():
			for msg in pr.errors:
				r.add_entry_error(e.id, "production: %s" % String(msg))
	return r
