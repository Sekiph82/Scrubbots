extends RefCounted
## HapticsSettingsService — preload
## (res://scripts/haptics/haptics_settings_service.gd).
##
## Narrow persistence for the M34 haptics enable/disable toggle. Persistence UI
## belongs to M41; this is only the config seam that M40 will snapshot/import.
## Uses ConfigFile at an isolated path so tests can round-trip safely.

const DEFAULT_PATH := "user://haptics_settings.cfg"
const SECTION := "haptics"
const KEY_ENABLED := "enabled"

var _path: String
var _enabled: bool = true

func _init(p_path: String = DEFAULT_PATH) -> void:
	_path = p_path

func is_enabled() -> bool:
	return _enabled

func set_enabled(v: bool) -> void:
	_enabled = v

func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_ENABLED, _enabled)
	return cfg.save(_path) == OK

func load() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(_path) != OK:
		return false
	var v = cfg.get_value(SECTION, KEY_ENABLED, true)
	if typeof(v) == TYPE_BOOL:
		_enabled = v
	else:
		_enabled = true
	return true

func snapshot() -> Dictionary:
	return {"enabled": _enabled}

## Idempotent import; unknown/malformed inputs fall back to safe default.
## Kept for M33 back-compat.
func import_snapshot(s: Dictionary) -> void:
	var v = s.get("enabled", true)
	_enabled = bool(v) if typeof(v) == TYPE_BOOL else true

## Strict canonical import (M40 V03, F-M40-V02-006): returns true only when the
## snapshot is a Dictionary with an explicit boolean `enabled`. Any other shape
## fails closed so a corrupt canonical save invalidates the whole candidate
## instead of silently normalizing to the safe default.
func strict_import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	if not s.has("enabled"):
		return false
	var v = s["enabled"]
	if typeof(v) != TYPE_BOOL:
		return false
	_enabled = v
	return true

func get_path() -> String:
	return _path
