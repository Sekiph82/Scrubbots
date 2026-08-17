extends RefCounted
## PaletteColors — preload this script (res://scripts/data/palette_colors.gd)
## rather than relying on global class_name lookup; see level_validator.gd
## for why.
##
## Single, well-defined conversion path from LevelData palette strings
## (e.g. "#E5484D") to Godot Color. Used by BoardRenderer. Parsing happens
## once per loaded level/board, not per frame — callers cache the resulting
## PaletteParseResult.colors array.

const PaletteParseResult = preload("res://scripts/data/palette_parse_result.gd")

## A malformed entry does not abort parsing of the rest of the palette —
## it is recorded as an error and a visible fallback (opaque magenta) is
## used in its place, so a single bad palette entry doesn't prevent
## inspecting/testing the rest of a level.
const FALLBACK_COLOR := Color(1.0, 0.0, 1.0, 1.0)

static func parse(palette: PackedStringArray) -> PaletteParseResult:
	var result := PaletteParseResult.new()
	for i in palette.size():
		var hex: String = palette[i]
		if not Color.html_is_valid(hex):
			result.add_error("Palette entry %d ('%s') is not a valid color string" % [i, hex])
			result.colors.append(FALLBACK_COLOR)
		else:
			result.colors.append(Color.html(hex))
	return result
