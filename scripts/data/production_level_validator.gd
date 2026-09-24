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
## count, etc.). It only checks Difficulty V1 production legality:
##   - TEST is rejected (dev fixture, never production);
##   - the class must be one of the four owner-locked production classes;
##   - width and height must each fall in the 20..59 production envelope,
##     rectangular allowed.
## CLASS IS NOT DERIVED FROM DIMENSIONS (owner decision 2026-09-12): a 24x24
## board may be VERY_HARD, a 38x38 board may be EASY. The retired class=dimension
## bands are NOT applied here (migrated in M36 V02, closing F-M36-001). The
## legacy M21 band check, if ever needed, lives behind
## DifficultyRules.legacy_m21_within_band and is not part of this general gate.

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

	if not DifficultyRules.is_production_difficulty(level.difficulty):
		result.add_error(
			"Level %s: unknown production class '%s' (expected one of: %s)" %
			[level.id, level.difficulty, ", ".join(DifficultyRules.production_difficulty_ids())]
		)
		return result

	if not DifficultyRules.is_within_production_envelope(level.width, level.height):
		result.add_error(
			"Level %s: production board envelope is %d..%d per dimension (rectangular allowed); received width=%d height=%d" %
			[level.id, DifficultyRules.ENVELOPE_MIN, DifficultyRules.ENVELOPE_MAX, level.width, level.height]
		)

	return result
