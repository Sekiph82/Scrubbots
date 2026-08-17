extends RefCounted
## LevelData — preload this script (res://scripts/data/level_data.gd) rather
## than relying on global class_name lookup; see level_validator.gd.
## Immutable parsed representation of a level source file (Level Data Spec
## Version 1, see docs/03_LEVEL_DATA_SPEC.md). Describes what a level IS.
## Runtime progress lives in BoardState, never here — see
## docs/02_TECH_ARCHITECTURE.md ("LevelData vs. BoardState").
##
## Board dimensions are level-defined; cell_count is always derived as
## width * height (never a separately-trusted stored field). See ADR-008
## in docs/05_TECH_DECISIONS.md.

const FORMAT_VERSION := 1

var version: int
var id: String
var display_name: String
var difficulty: String
var width: int
var height: int
var palette: PackedStringArray
## Flat, row-major palette-id-per-cell array. index = y * width + x.
var cells: PackedInt32Array

func _init(
	p_version: int,
	p_id: String,
	p_display_name: String,
	p_difficulty: String,
	p_width: int,
	p_height: int,
	p_palette: PackedStringArray,
	p_cells: PackedInt32Array
) -> void:
	version = p_version
	id = p_id
	display_name = p_display_name
	difficulty = p_difficulty
	width = p_width
	height = p_height
	palette = p_palette
	cells = p_cells

func get_cell_count() -> int:
	return width * height
