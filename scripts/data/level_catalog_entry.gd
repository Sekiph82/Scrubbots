extends RefCounted
## LevelCatalogEntry — preload
## (res://scripts/data/level_catalog_entry.gd).
## Immutable per-entry read model surfaced by LevelCatalog. Consumers get IDs,
## explicit order, difficulty (M36 Difficulty V1 token), dimensions, and a
## preview reference. Consumers never mutate the source catalog.

var id: String
var order: int
var level_path: String
var metadata_path: String
var preview_path: String
var difficulty: String
var width: int
var height: int
var preview_exists: bool
## Owner supply plan (M52-C001). Empty => the level uses the M23 generator candidate
## (Level 1 historical path). Non-empty => runtime MUST load exactly this plan.
var supply_plan_path: String = ""

## Deep value copy — LevelCatalog returns copies so consumers can never mutate
## the canonical internal entry objects (F-M35-001).
func duplicate() -> RefCounted:
	var e = get_script().new()
	e.id = id
	e.order = order
	e.level_path = level_path
	e.metadata_path = metadata_path
	e.preview_path = preview_path
	e.difficulty = difficulty
	e.width = width
	e.height = height
	e.preview_exists = preview_exists
	e.supply_plan_path = supply_plan_path
	return e
