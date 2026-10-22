extends RefCounted
## EffectsSettingsService — preload
## (res://scripts/settings/effects_settings_service.gd).
##
## M41-C002 (SB-M41-005) — canonical Reduced Effects setting. Owns durable presentation bools,
## persisted only through the M40 SaveService (`settings.effects`); no side file.
## Reduced Effects default OFF (accepted M31 normal presentation). Presentation-only: the value
## drives CleaningEffectsController.set_reduced_effects() and nothing else. `changed` lets an
## already-built gameplay host apply the value live.
##
## M50-BOARD (SB-M50-002, owner 2026-10-15): COLOR SYMBOLS (`settings.effects.color_symbols`).
## SB-M50-OPTIN-001 (owner 2026-10-22): opt-in, default OFF. Optional in a save (absent => OFF);
## present but not an exact bool => the whole candidate is rejected. snapshot() also writes the
## marker `color_symbols_optin: true`; a stored `color_symbols` is the player's choice only when
## that marker is exactly true, so every pre-marker save (the old default stored true) is migrated to OFF once.
## A present non-bool marker rejects the candidate.
## Drives ColorSymbols.set_enabled (board cells, Supply/Slots, booster chips) via
## `color_symbols_changed`; it never touches gameplay state.

signal changed(reduced: bool)
signal color_symbols_changed(on: bool)

var _reduced: bool = false
var _color_symbols: bool = false

func is_reduced() -> bool:
	return _reduced

func set_reduced(on: bool) -> void:
	if on == _reduced:
		return
	_reduced = on
	changed.emit(_reduced)

func is_color_symbols() -> bool:
	return _color_symbols

func set_color_symbols(on: bool) -> void:
	if on == _color_symbols:
		return
	_color_symbols = on
	color_symbols_changed.emit(_color_symbols)

func snapshot() -> Dictionary:
	return {"reduced": _reduced, "color_symbols": _color_symbols, "color_symbols_optin": true}

## Strict canonical import: a Dictionary with an exact bool `reduced` (and, when present, an
## exact bool `color_symbols` / `color_symbols_optin`), else false and no mutation (the caller
## rejects the whole save candidate).
func strict_import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or not s.has("reduced") or typeof(s["reduced"]) != TYPE_BOOL:
		return false
	if s.has("color_symbols") and typeof(s["color_symbols"]) != TYPE_BOOL:
		return false
	if s.has("color_symbols_optin") and typeof(s["color_symbols_optin"]) != TYPE_BOOL:
		return false
	set_reduced(s["reduced"])
	set_color_symbols(s.get("color_symbols", false) and s.get("color_symbols_optin", false))
	return true
