extends RefCounted
## LevelValidationResult — preload this script
## (res://scripts/data/level_validation_result.gd) rather than relying on
## global class_name lookup; see level_validator.gd.
## Result of validating/loading one level. Never crashes on bad input —
## callers check is_ok() and read errors for specific diagnostics.

## Explicit preload rather than global class_name lookup — see
## scripts/data/level_validator.gd for why.
const LevelData = preload("res://scripts/data/level_data.gd")

var errors: Array[String] = []
var level_data: LevelData = null

func is_ok() -> bool:
	return errors.is_empty() and level_data != null

func add_error(message: String) -> void:
	errors.append(message)
