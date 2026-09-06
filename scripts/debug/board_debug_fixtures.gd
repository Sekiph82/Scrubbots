extends RefCounted
## BoardDebugFixtures — preload this script
## (res://scripts/debug/board_debug_fixtures.gd) rather than relying on
## global class_name lookup; see scripts/data/level_validator.gd for why.
##
## Deterministic level/board generation for renderer development and manual
## QA. Two sources:
##   1. Synthetic Stripes — in-memory (no file), a small multi-hue placeholder
##      palette so ACTIVE source colors and transparent CLEARED holes can be
##      judged across distinct hues.
##   2. Real Artwork — owner-authorized debug fixtures loaded DIRECTLY from
##      `data/debug/board_renderer_fixtures/level_0NN.json` (M10-C001), which
##      reference the owner-locked global palette
##      `data/palettes/scrubbots_palette_v1.json` (C01..C15). These are
##      TEST/debug/manual-QA fixtures only — never production catalog content
##      (see docs/03_LEVEL_DATA_SPEC.md "Fixtures" and docs/08_PIXEL_ART_PALETTE_RULES.md).

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Synthetic-Stripes placeholder hues — deliberately NOT the owner-locked
## production palette (that now lives in data/palettes/scrubbots_palette_v1.json
## and is used by the Real Artwork fixtures below).
const PALETTE := ["#E5484D", "#3B82F6", "#22C55E", "#F5C518", "#A855F7"]

const GLOBAL_PALETTE_PATH := "res://data/palettes/scrubbots_palette_v1.json"

enum StatePattern {
	ALL_ACTIVE,
	ALL_CLEARED,
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

## Applies a deterministic ACTIVE/CLEARED pattern to an already-built
## BoardState, in place. CLEARED cells render transparent (background shows
## through); ACTIVE cells render their source palette color.
static func apply_pattern(board: BoardState, pattern: int) -> void:
	var w: int = board.get_width()
	var h: int = board.get_height()
	for y in h:
		for x in w:
			var index: int = board.get_cell_index(x, y)
			var cleared: bool
			match pattern:
				StatePattern.ALL_ACTIVE:
					cleared = false
				StatePattern.ALL_CLEARED:
					cleared = true
				StatePattern.HALF_SPLIT:
					cleared = x >= w / 2
				StatePattern.CHECKER:
					cleared = (x + y) % 2 == 0
				_:
					cleared = false
			board.set_cell_state(index, BoardState.CellState.CLEARED if cleared else BoardState.CellState.ACTIVE)

# ------------------------------------------------- Real Artwork fixtures --

## Maps a C-ID numeric suffix (1..15) to its owner-locked hex, from
## scrubbots_palette_v1.json. Returns {} on load/parse failure.
static func load_global_palette_hex_by_suffix() -> Dictionary:
	var out: Dictionary = {}
	if not FileAccess.file_exists(GLOBAL_PALETTE_PATH):
		return out
	var text := FileAccess.get_file_as_string(GLOBAL_PALETTE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("colors"):
		return out
	for c in parsed.colors:
		var id_str: String = str(c.get("id", ""))
		if id_str.begins_with("C"):
			var suffix := int(id_str.substr(1))
			out[suffix] = str(c.get("hex", ""))
	return out

## Loads one owner-authorized Real Artwork debug fixture JSON directly (no
## OCR/regeneration; the JSON grid is the source of truth). Builds a TEST
## LevelData whose palette is the fixture's C-ID subset (ascending) mapped to
## global hex, plus a VOID mask. VOID cells (JSON value 0) carry a placeholder
## color id and are always treated as background — never ACTIVE artwork.
##
## Returns a Dictionary:
##   ok, error,
##   level (LevelData), void_mask (PackedByteArray, 1 = VOID),
##   fixture_id, display_name, width, height,
##   background_hex, palette_subset_ids (Array[String] ascending),
##   color_counts (Dictionary C-ID -> int, from JSON),
##   void_count, artwork_cell_count.
static func load_real_fixture(path: String) -> Dictionary:
	var fail := func(msg: String) -> Dictionary: return {"ok": false, "error": msg}
	if not FileAccess.file_exists(path):
		return fail.call("fixture not found: %s" % path)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return fail.call("fixture JSON is not an object: %s" % path)
	var width: int = int(parsed.get("width", 0))
	var height: int = int(parsed.get("height", 0))
	var grid = parsed.get("color_id_array", null)
	if width <= 0 or height <= 0 or typeof(grid) != TYPE_ARRAY or grid.size() != height:
		return fail.call("fixture dimensions/grid mismatch: %s" % path)

	var suffix_hex := load_global_palette_hex_by_suffix()
	if suffix_hex.is_empty():
		return fail.call("global palette could not be loaded")

	# Ascending C-ID subset actually referenced by the grid (validated below).
	var subset_ids: Array = []
	for id_str in parsed.get("palette_subset_ids", []):
		subset_ids.append(str(id_str))
	subset_ids.sort()
	var suffix_to_subset_index: Dictionary = {}
	var palette := PackedStringArray()
	for id_str in subset_ids:
		var suffix := int(String(id_str).substr(1))
		if not suffix_hex.has(suffix):
			return fail.call("subset id %s not in global palette" % id_str)
		suffix_to_subset_index[suffix] = palette.size()
		palette.append(suffix_hex[suffix])
	if palette.is_empty():
		# All-VOID would be degenerate; every real fixture has artwork.
		palette.append("#000000")

	var cells := PackedInt32Array()
	cells.resize(width * height)
	var void_mask := PackedByteArray()
	void_mask.resize(width * height)
	for y in height:
		var row = grid[y]
		if typeof(row) != TYPE_ARRAY or row.size() != width:
			return fail.call("row %d width mismatch in %s" % [y, path])
		for x in width:
			var v := int(row[x])
			var i := y * width + x
			if v == 0:
				void_mask[i] = 1
				cells[i] = 0 # placeholder; VOID is never rendered as a color
			else:
				if not suffix_to_subset_index.has(v):
					return fail.call("cell value %d at (%d,%d) not in palette subset in %s" % [v, x, y, path])
				void_mask[i] = 0
				cells[i] = suffix_to_subset_index[v]

	var fixture_id: String = str(parsed.get("fixture_id", "real_fixture"))
	var display_name: String = str(parsed.get("display_name", fixture_id))
	var bg: Dictionary = parsed.get("background", {})
	var level := LevelData.new(1, fixture_id, display_name, "TEST", width, height, palette, cells)
	return {
		"ok": true,
		"error": "",
		"level": level,
		"void_mask": void_mask,
		"fixture_id": fixture_id,
		"display_name": display_name,
		"width": width,
		"height": height,
		# Explicit source-matrix dimensions. These are the IMMUTABLE source
		# artwork bounding matrix, NOT a canvas size. Use
		# embed_real_fixture_in_canvas() to place this source into a debug canvas.
		"source_width": width,
		"source_height": height,
		"palette": palette,
		"background_hex": str(bg.get("hex", "#202533")),
		"palette_subset_ids": subset_ids,
		"color_counts": parsed.get("color_counts", {}),
		"void_count": int(parsed.get("void_count", 0)),
		"artwork_cell_count": int(parsed.get("artwork_cell_count", 0)),
	}

## Debug-only embedding: place an UNCHANGED source fixture (from
## load_real_fixture) centered inside a larger debug canvas using VOID padding
## only. The source matrix is never scaled, resampled, stretched, cropped,
## repainted or regenerated — every source square stays exactly one logical
## cell; source VOID stays VOID; all padding around it is debug VOID.
##
## Valid only when canvas_w >= source_width and canvas_h >= source_height.
## Center offset = floor((canvas - source) / 2).
##
## Returns a Dictionary:
##   ok, error,
##   level (LevelData at canvas size), void_mask (PackedByteArray, 1 = VOID),
##   fixture_id, display_name,
##   source_width, source_height, canvas_width, canvas_height,
##   offset_x, offset_y,
##   background_hex, palette_subset_ids, color_counts,
##   artwork_cell_count (== source), void_count (canvas cells - artwork).
static func embed_real_fixture_in_canvas(source: Dictionary, canvas_w: int, canvas_h: int) -> Dictionary:
	var fail := func(msg: String) -> Dictionary: return {"ok": false, "error": msg}
	if source == null or not source.get("ok", false):
		return fail.call("invalid source fixture")
	var sw: int = int(source.source_width)
	var sh: int = int(source.source_height)
	if canvas_w < sw or canvas_h < sh:
		return fail.call("canvas %dx%d too small for source %dx%d" % [canvas_w, canvas_h, sw, sh])

	var offset_x: int = int(floor((canvas_w - sw) / 2.0))
	var offset_y: int = int(floor((canvas_h - sh) / 2.0))

	var src_level = source.level
	var src_void: PackedByteArray = source.void_mask
	var palette: PackedStringArray = source.palette

	var cells := PackedInt32Array()
	cells.resize(canvas_w * canvas_h)
	var void_mask := PackedByteArray()
	void_mask.resize(canvas_w * canvas_h)
	# Whole canvas starts as debug VOID (placeholder color id 0).
	void_mask.fill(1)
	# Copy the unchanged source matrix into the centered window.
	for sy in sh:
		for sx in sw:
			var s_i := sy * sw + sx
			var d_i := (offset_y + sy) * canvas_w + (offset_x + sx)
			if src_void[s_i] == 1:
				# source VOID stays VOID
				continue
			void_mask[d_i] = 0
			cells[d_i] = src_level.cells[s_i]

	var artwork := int(source.artwork_cell_count)
	var level := LevelData.new(
		1, str(source.fixture_id) + "_canvas_%dx%d" % [canvas_w, canvas_h],
		str(source.display_name), "TEST", canvas_w, canvas_h, palette, cells
	)
	return {
		"ok": true,
		"error": "",
		"level": level,
		"void_mask": void_mask,
		"fixture_id": source.fixture_id,
		"display_name": source.display_name,
		"source_width": sw,
		"source_height": sh,
		"canvas_width": canvas_w,
		"canvas_height": canvas_h,
		"offset_x": offset_x,
		"offset_y": offset_y,
		"background_hex": source.background_hex,
		"palette_subset_ids": source.palette_subset_ids,
		"color_counts": source.color_counts,
		"artwork_cell_count": artwork,
		"void_count": canvas_w * canvas_h - artwork,
	}

## Applies an ACTIVE/CLEARED pattern only to artwork cells; VOID cells
## (void_mask[i] == 1) are forced CLEARED so the debug background (BG01) shows
## through and they are never mutated into ACTIVE artwork.
static func apply_pattern_masked(board: BoardState, pattern: int, void_mask: PackedByteArray) -> void:
	var w: int = board.get_width()
	var h: int = board.get_height()
	for y in h:
		for x in w:
			var index: int = board.get_cell_index(x, y)
			if index < void_mask.size() and void_mask[index] == 1:
				board.set_cell_state(index, BoardState.CellState.CLEARED)
				continue
			var cleared: bool
			match pattern:
				StatePattern.ALL_ACTIVE:
					cleared = false
				StatePattern.ALL_CLEARED:
					cleared = true
				StatePattern.HALF_SPLIT:
					cleared = x >= w / 2
				StatePattern.CHECKER:
					cleared = (x + y) % 2 == 0
				_:
					cleared = false
			board.set_cell_state(index, BoardState.CellState.CLEARED if cleared else BoardState.CellState.ACTIVE)
