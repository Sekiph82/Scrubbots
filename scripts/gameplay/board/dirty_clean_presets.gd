extends RefCounted
## DirtyCleanPresets — preload this script
## (res://scripts/gameplay/board/dirty_clean_presets.gd) rather than relying
## on global class_name lookup; see scripts/data/level_validator.gd for why.
##
## Centralized, configurable DIRTY visual transform. CLEAN always displays
## the original LevelData palette color unmodified — this script only
## exists to answer "what does DIRTY look like." See tasks.md M10 and
## docs/05_TECH_DECISIONS.md (renderer ADR) for the readability rationale:
## the transform MUST vary both saturation and value/brightness, never
## saturation alone, or the distinction disappears at small (59x59) cell
## sizes.
##
## NONE of these numeric values are locked/approved. Three presets exist so
## the project owner can compare them at native gameplay scale (see
## scenes/debug/board_renderer_debug.tscn) before any final visual
## direction is chosen — see the DESIGN GATE note in tasks.md M10.

const DEFAULT_PRESET_NAME := "B"

## preset id -> {saturation_factor, value_factor}, both multiplied onto the
## base color's HSV s/v. Kept < 1.0 for both so DIRTY always both desaturates
## AND darkens relative to CLEAN, per the readability requirement.
const PRESETS := {
	"A": {"label": "Strong darken / moderate-strong desaturate", "saturation_factor": 0.35, "value_factor": 0.45},
	"B": {"label": "Medium darken / medium desaturate", "saturation_factor": 0.55, "value_factor": 0.65},
	"C": {"label": "Light darken / strong desaturate", "saturation_factor": 0.25, "value_factor": 0.75},
}

static func preset_names() -> Array:
	return PRESETS.keys()

static func get_preset(preset_name: String) -> Dictionary:
	return PRESETS.get(preset_name, PRESETS[DEFAULT_PRESET_NAME])

## Returns a NEW Color — never mutates the base Color (Color is a value
## type in GDScript, so this is structurally guaranteed, not just a
## convention).
static func apply_dirty(base_color: Color, preset_name: String) -> Color:
	var preset: Dictionary = get_preset(preset_name)
	var h: float = base_color.h
	var s: float = clampf(base_color.s * float(preset.saturation_factor), 0.0, 1.0)
	var v: float = clampf(base_color.v * float(preset.value_factor), 0.0, 1.0)
	return Color.from_hsv(h, s, v, base_color.a)
