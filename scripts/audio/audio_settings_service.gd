extends RefCounted
## AudioSettingsService — preload this script
## (res://scripts/audio/audio_settings_service.gd); do not rely on global class_name (AL-001).
##
## M33 (SB-M33-002..004, SB-M33-010) — the narrow, reusable audio volume + persistence
## seam. It owns ONLY user-facing normalized volume for the Master/Music/SFX buses,
## maps them safely onto the Godot AudioServer bus volume/mute, and persists them under
## a user-data ConfigFile. It holds NO gameplay state and never reads or mutates board,
## reservation, dispatch, clearing, completion or progression truth (owner audio decision:
## audio is presentation-only). M41 Settings UI will later consume this — M33 does not
## build that UI.
##
## Volume model: a stable normalized 0.0..1.0 per bus. 0.0 mutes the bus (deterministic
## silence); >0 unmutes and sets volume_db = linear_to_db(value). Inputs are clamped, so
## NaN / out-of-range never reach the AudioServer. A missing bus (no bus layout loaded) is
## a safe no-op, never a crash.
##
## Persistence: ConfigFile at `user://audio_settings.cfg` (or an injected test path). A
## missing or corrupt file loads full-neutral defaults (1.0) and never blocks startup.
## Saving/loading audio settings touches only this file — never gameplay/progression saves.

const DEFAULT_CONFIG_PATH := "user://audio_settings.cfg"
const CONFIG_SECTION := "audio"
const CONFIG_VERSION := 1

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const DEFAULT_VOLUME := 1.0

var _config_path: String = DEFAULT_CONFIG_PATH
## Normalized current values (authoritative in-memory truth; the AudioServer mirrors them).
var _master: float = DEFAULT_VOLUME
var _music: float = DEFAULT_VOLUME
var _sfx: float = DEFAULT_VOLUME

## `config_path` lets tests inject an isolated file so real owner settings are never
## overwritten. Omit for the production `user://audio_settings.cfg`.
func _init(config_path: String = DEFAULT_CONFIG_PATH) -> void:
	if config_path != "":
		_config_path = config_path

func get_config_path() -> String:
	return _config_path

# -------------------------------------------------------------- read-only ----

func get_master_volume() -> float:
	return _master

func get_music_volume() -> float:
	return _music

func get_sfx_volume() -> float:
	return _sfx

# ------------------------------------------------------------------- set ----

## Set + apply normalized Master volume (clamped 0..1). Applies to the AudioServer bus.
func set_master_volume(value: float) -> void:
	_master = _clamp01(value)
	_apply_bus(BUS_MASTER, _master)

func set_music_volume(value: float) -> void:
	_music = _clamp01(value)
	_apply_bus(BUS_MUSIC, _music)

func set_sfx_volume(value: float) -> void:
	_sfx = _clamp01(value)
	_apply_bus(BUS_SFX, _sfx)

## Push the current in-memory values onto the AudioServer buses (e.g. right after load or
## after a bus layout becomes available). Idempotent.
func apply_all() -> void:
	_apply_bus(BUS_MASTER, _master)
	_apply_bus(BUS_MUSIC, _music)
	_apply_bus(BUS_SFX, _sfx)

# ------------------------------------------------------- persistence ----

## Persist the three normalized volumes. Returns true on a successful write. Only this
## config file is touched — never gameplay/progression state.
func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(CONFIG_SECTION, "version", CONFIG_VERSION)
	cfg.set_value(CONFIG_SECTION, "master", _master)
	cfg.set_value(CONFIG_SECTION, "music", _music)
	cfg.set_value(CONFIG_SECTION, "sfx", _sfx)
	return cfg.save(_config_path) == OK

## Load the three normalized volumes and apply them to the buses. A missing or corrupt
## file loads full-neutral defaults; any malformed/out-of-range field is clamped/defaulted.
## Never blocks startup. Returns true when an existing file parsed cleanly, false when
## defaults were used (missing/corrupt) — a caller may ignore the return.
func load() -> bool:
	var cfg := ConfigFile.new()
	var err := cfg.load(_config_path)
	if err != OK:
		# Missing or corrupt file -> safe full-neutral defaults, applied to the buses.
		_master = DEFAULT_VOLUME
		_music = DEFAULT_VOLUME
		_sfx = DEFAULT_VOLUME
		apply_all()
		return false
	_master = _read_norm(cfg, "master")
	_music = _read_norm(cfg, "music")
	_sfx = _read_norm(cfg, "sfx")
	apply_all()
	return true

# ------------------------------------------------------------- internals ----

## Read one normalized value, tolerating a missing key or a non-numeric/out-of-range
## stored value. Any int/float is clamped; anything else falls back to the neutral default.
func _read_norm(cfg: ConfigFile, key: String) -> float:
	var raw = cfg.get_value(CONFIG_SECTION, key, DEFAULT_VOLUME)
	if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
		return DEFAULT_VOLUME
	return _clamp01(float(raw))

## Clamp to 0..1; a NaN (which fails every comparison) is coerced to the neutral default
## so a poisoned value can never reach the AudioServer.
static func _clamp01(value: float) -> float:
	if not is_finite(value):
		return DEFAULT_VOLUME
	return clampf(value, 0.0, 1.0)

## Map one normalized value onto a named bus: 0.0 -> mute (deterministic silence),
## >0 -> unmute + volume_db = linear_to_db(value). A missing bus is a safe no-op.
static func _apply_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
