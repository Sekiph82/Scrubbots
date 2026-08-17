extends RefCounted
## PaletteParseResult — preload this script
## (res://scripts/data/palette_parse_result.gd) rather than relying on
## global class_name lookup; see level_validator.gd for why.
##
## Result of converting a LevelData palette (array of hex color strings)
## into Godot Colors. Never crashes on malformed input — callers check
## is_ok() and read errors for specific diagnostics.

var colors: Array[Color] = []
var errors: Array[String] = []

func is_ok() -> bool:
	return errors.is_empty()

func add_error(message: String) -> void:
	errors.append(message)
