extends RefCounted
## EffectsSettingsService — preload
## (res://scripts/settings/effects_settings_service.gd).
##
## M41-C002 (SB-M41-005) — canonical Reduced Effects setting. Owns ONE durable bool,
## persisted only through the M40 SaveService (`settings.effects.reduced`); no side file.
## Default OFF (accepted M31 normal presentation). Presentation-only: the value drives
## CleaningEffectsController.set_reduced_effects() and nothing else. `changed` lets an
## already-built gameplay host apply the value live.

signal changed(reduced: bool)

var _reduced: bool = false

func is_reduced() -> bool:
	return _reduced

func set_reduced(on: bool) -> void:
	if on == _reduced:
		return
	_reduced = on
	changed.emit(_reduced)

func snapshot() -> Dictionary:
	return {"reduced": _reduced}

## Strict canonical import: a Dictionary with an exact bool `reduced`, else false and no
## mutation (the caller rejects the whole save candidate).
func strict_import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or not s.has("reduced") or typeof(s["reduced"]) != TYPE_BOOL:
		return false
	set_reduced(s["reduced"])
	return true
