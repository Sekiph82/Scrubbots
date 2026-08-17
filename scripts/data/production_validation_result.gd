extends RefCounted
## ProductionValidationResult — preload this script
## (res://scripts/data/production_validation_result.gd) rather than relying
## on global class_name lookup; see level_validator.gd for why.
##
## Result of checking whether a structurally-valid LevelData is legal as
## PRODUCTION SCRUBBOTS content (see ProductionLevelValidator). Distinct
## from LevelValidationResult, which answers a different question
## ("is this Level Data V1 internally valid at all?").

var errors: Array[String] = []

func is_ok() -> bool:
	return errors.is_empty()

func add_error(message: String) -> void:
	errors.append(message)
