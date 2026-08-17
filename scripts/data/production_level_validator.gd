extends RefCounted
## ProductionLevelValidator — preload this script
## (res://scripts/data/production_level_validator.gd) rather than relying
## on global class_name lookup; see level_validator.gd for why.
##
## Answers a DIFFERENT question than LevelValidator:
##   LevelValidator            -> "Is this Level Data V1 internally valid?"
##                                 (structural validation — generic, never
##                                 difficulty-aware, never rejects TEST)
##   ProductionLevelValidator  -> "Is this structurally-valid level legal
##                                 as PRODUCTION SCRUBBOTS content?"
##                                 (difficulty-band-aware; rejects TEST and
##                                 unknown difficulties)
##
## Input is a LevelData that has ALREADY passed LevelValidator — this class
## does not re-check structural correctness (version, palette bounds, cell
## count, etc.). It only checks difficulty/dimension legality. See
## docs/03_LEVEL_DATA_SPEC.md and docs/05_TECH_DECISIONS.md ADR-010.

const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")
const ProductionValidationResult = preload("res://scripts/data/production_validation_result.gd")

static func validate(level) -> ProductionValidationResult:
	var result := ProductionValidationResult.new()

	if level.difficulty == DifficultyRules.TEST_DIFFICULTY:
		result.add_error(
			"Level %s: difficulty TEST is a development fixture and is not valid production content" %
			level.id
		)
		return result

	var band = DifficultyRules.get_band(level.difficulty)
	if band == null:
		result.add_error(
			"Level %s: unknown production difficulty '%s' (expected one of: %s)" %
			[level.id, level.difficulty, ", ".join(DifficultyRules.production_difficulty_ids())]
		)
		return result

	if not DifficultyRules.is_within_band(level.difficulty, level.width, level.height):
		result.add_error(
			"Level %s: difficulty %s requires width and height in range %d..%d; received width=%d height=%d" %
			[level.id, level.difficulty, band.min, band.max, level.width, level.height]
		)

	return result
