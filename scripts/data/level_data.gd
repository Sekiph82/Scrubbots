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
##
## VOID cells (ADR-030, owner decision 2026-10-08): a transparent source pixel
## is a VOID cell, encoded as VOID_CELL (-1) in `cells`. VOID is not artwork:
## no colour, never a candidate, never needs a robot, starts the level as open
## (CLEARED-equivalent) space. -1 is legal ONLY in FORMAT_VERSION_VOID (2)
## files; version-1 files are unchanged (every cell is a palette index).

const FORMAT_VERSION := 1
## Level Data version that permits VOID cells. Emitted only when a level
## actually contains VOID; void-free levels keep FORMAT_VERSION.
const FORMAT_VERSION_VOID := 2
const VOID_CELL := -1

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

## True only for a version-2 level whose cell is VOID_CELL.
func is_void(index: int) -> bool:
	return version == FORMAT_VERSION_VOID and cells[index] == VOID_CELL

func get_void_cell_count() -> int:
	if version != FORMAT_VERSION_VOID:
		return 0
	return cells.count(VOID_CELL)

## Artwork (non-VOID) cell count: what robots must clear. == get_cell_count()
## for every version-1 level.
func get_artwork_cell_count() -> int:
	return get_cell_count() - get_void_cell_count()
