extends RefCounted
## DifficultyRules — preload this script
## (res://scripts/data/difficulty_rules.gd) rather than relying on global
## class_name lookup; see level_validator.gd for why.
##
## SINGLE SOURCE OF TRUTH for the official SCRUBBOTS production
## difficulty/board-dimension bands. See docs/05_TECH_DECISIONS.md ADR-010
## and tasks.md §8.3. Do not duplicate these ranges anywhere else — anything
## that needs them (validators, tests, future content tooling) calls into
## this script.
##
## Width and height are checked independently against the SAME band (both
## must fall in [min, max]) — this is what makes rectangular boards valid
## while still rejecting cross-band dimensions. width == height is never
## assumed or required.
##
## TEST is a distinct, non-production identifier for development/engine
## fixtures (e.g. the 3x2 generic-size fixture). It intentionally has no
## band here — TEST content is never dimension-checked as production and
## must never enter the production catalog (see ProductionLevelValidator).

const TEST_DIFFICULTY := "TEST"

## difficulty id -> {min, max} applied to BOTH width and height.
const BANDS := {
	"EASY": {"min": 20, "max": 29},
	"MEDIUM": {"min": 30, "max": 39},
	"HARD": {"min": 40, "max": 49},
	"VERY_HARD": {"min": 50, "max": 59},
}

static func is_production_difficulty(difficulty_id: String) -> bool:
	return BANDS.has(difficulty_id)

## Returns null if difficulty_id is not a known production difficulty.
static func get_band(difficulty_id: String):
	return BANDS.get(difficulty_id, null)

static func production_difficulty_ids() -> Array:
	return BANDS.keys()

static func is_within_band(difficulty_id: String, width: int, height: int) -> bool:
	var band = get_band(difficulty_id)
	if band == null:
		return false
	return width >= band.min and width <= band.max and height >= band.min and height <= band.max
