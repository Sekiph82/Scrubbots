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
