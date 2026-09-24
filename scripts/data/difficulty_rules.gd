extends RefCounted
## DifficultyRules — preload this script
## (res://scripts/data/difficulty_rules.gd) rather than relying on global
## class_name lookup; see level_validator.gd for why.
##
## SINGLE SOURCE OF TRUTH for the official SCRUBBOTS production difficulty
## legality under the OWNER-LOCKED 2026-09-12 Difficulty V1 decision:
##   - the four production classes are EASY/MEDIUM/HARD/VERY_HARD;
##   - the production board envelope is 20..59 per dimension, rectangular
##     allowed (width and height each independently in [20,59]);
##   - CLASS IS NOT DERIVED FROM DIMENSIONS. A 24x24 board may be VERY_HARD;
##     a 38x38 board may be EASY. See docs/09_DIFFICULTY_PROGRESSION... and
##     coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md.
##
## The old class=dimension bands (EASY 20..29 / MEDIUM 30..39 / HARD 40..49 /
## VERY_HARD 50..59) are RETIRED as production legality. They survive ONLY as
## `LEGACY_M21_BANDS` for the explicitly-named M21 historical compatibility
## seam and offline M21-style content tooling — they are NOT the current
## production acceptance gate (see ProductionLevelValidator, migrated in
## M36 V02).
##
## TEST is a distinct, non-production identifier for development/engine
## fixtures. TEST content is never valid production content and must never
## enter the production catalog.

const TEST_DIFFICULTY := "TEST"

## The four owner-locked production difficulty classes (class != dimension).
const PRODUCTION_CLASSES := ["EASY", "MEDIUM", "HARD", "VERY_HARD"]

## Production board envelope (per dimension, rectangular allowed).
const ENVELOPE_MIN := 20
const ENVELOPE_MAX := 59

## LEGACY-ONLY, NOT production truth. Retained for the named M21 compatibility
## seam and offline M21-style builders. Do not use this to accept/reject
## general production catalog entries.
const LEGACY_M21_BANDS := {
	"EASY": {"min": 20, "max": 29},
	"MEDIUM": {"min": 30, "max": 39},
	"HARD": {"min": 40, "max": 49},
	"VERY_HARD": {"min": 50, "max": 59},
}
## Back-compat alias for the retired name (offline tooling still imports it).
const BANDS := LEGACY_M21_BANDS

static func is_production_difficulty(difficulty_id: String) -> bool:
	return PRODUCTION_CLASSES.has(difficulty_id)

static func production_difficulty_ids() -> Array:
	return PRODUCTION_CLASSES.duplicate()

## Current production dimension legality: each dimension independently within
## the 20..59 envelope. Rectangular allowed; class plays no part.
static func is_within_production_envelope(width: int, height: int) -> bool:
	return (width >= ENVELOPE_MIN and width <= ENVELOPE_MAX
		and height >= ENVELOPE_MIN and height <= ENVELOPE_MAX)

# ------------------------------------------------------- LEGACY M21 seam ----
# The following are LEGACY helpers for the named M21 compatibility path only.
# They are NOT the production acceptance gate (Difficulty V1, 2026-09-12).

## Returns null if difficulty_id is not a known legacy band.
static func get_band(difficulty_id: String):
	return LEGACY_M21_BANDS.get(difficulty_id, null)

static func legacy_m21_within_band(difficulty_id: String, width: int, height: int) -> bool:
	var band = get_band(difficulty_id)
	if band == null:
		return false
	return width >= band.min and width <= band.max and height >= band.min and height <= band.max

## Deprecated alias kept for offline tooling; routes to the legacy seam.
static func is_within_band(difficulty_id: String, width: int, height: int) -> bool:
	return legacy_m21_within_band(difficulty_id, width, height)
