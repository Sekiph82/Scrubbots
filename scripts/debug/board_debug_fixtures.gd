extends RefCounted
## BoardDebugFixtures — preload this script
## (res://scripts/debug/board_debug_fixtures.gd) rather than relying on
## global class_name lookup; see scripts/data/level_validator.gd for why.
##
## Deterministic, in-memory (no JSON file needed) level/board generation for
## renderer development and testing. Uses a small multi-hue palette
## (red/green/blue/yellow/magenta) specifically so DIRTY/CLEAN color-family
## recognizability can be visually judged across distinct hues — this is a
## TEST/DEV fixture generator, never production art (see
## docs/03_LEVEL_DATA_SPEC.md "Fixtures").

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## A handful of saturated, recognizable hues -- deliberately not the
## project's real palette (none exists yet; see tasks.md Visual Reference
## System, AWAITING OWNER ASSET).
const PALETTE := ["#E5484D", "#3B82F6", "#22C55E", "#F5C518", "#A855F7"]

enum StatePattern {
	ALL_DIRTY,
	ALL_CLEAN,
	HALF_SPLIT,
	CHECKER,
}

## Builds an in-memory LevelData with a horizontal-band pattern cycling
## through PALETTE, sized width x height. difficulty is always "TEST" —
## these are never production content.
static func make_level(width: int, height: int, level_id: String = "") -> LevelData:
	var id: String = level_id if not level_id.is_empty() else "debug_%dx%d" % [width, height]
	var palette := PackedStringArray(PALETTE)
	var cells := PackedInt32Array()
	cells.resize(width * height)
	for y in height:
		var palette_id: int = y % palette.size()
		for x in width:
			cells[y * width + x] = palette_id
	return LevelData.new(1, id, id, "TEST", width, height, palette, cells)

static func make_board(width: int, height: int) -> BoardState:
	return BoardState.from_level_data(make_level(width, height))

## Applies a deterministic DIRTY/CLEAN pattern to an already-built
## BoardState, in place.
static func apply_pattern(board: BoardState, pattern: int) -> void:
	var w: int = board.get_width()
	var h: int = board.get_height()
	for y in h:
		for x in w:
			var index: int = board.get_cell_index(x, y)
			var clean: bool
			match pattern:
				StatePattern.ALL_DIRTY:
					clean = false
				StatePattern.ALL_CLEAN:
					clean = true
				StatePattern.HALF_SPLIT:
					clean = x >= w / 2
				StatePattern.CHECKER:
					clean = (x + y) % 2 == 0
				_:
					clean = false
			board.set_cell_state(index, BoardState.CellState.CLEAN if clean else BoardState.CellState.DIRTY)
