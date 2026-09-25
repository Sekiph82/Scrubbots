extends RefCounted
## AppState — preload
## (res://scripts/app/app_state.gd).
##
## App-level canonical composition root for durable state (M40 V03,
## F-M40-V02-001). Owns exactly ONE instance of each canonical service graph
## used by the shipping runtime:
##   - AudioSettingsService (M33)
##   - HapticsSettingsService (M34)
##   - EffectsSettingsService (M41-C002 Reduced Effects)
##   - LevelProgressionService (M37)
##   - EconomyServices (M39)
##   - SaveService (M40) — bound to the above, using the canonical save path.
##
## ProductionGameplayHost consumes this graph instead of creating a second
## progression/economy/settings authority. Tests inject an isolated instance
## via a temp save path so no real user:// files are touched.
##
## Bootstrap policy (F-M40-V02-002/-008):
##   1. build the graph;
##   2. call SaveService.load();
##   3. `load_result` records {ok, source, reason?} for the runtime to consult;
##   4. if source == "future_schema", `is_blocked` is true and the app must
##      refuse to run normal gameplay (host halts build).

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const ProductionActionFacade = preload("res://scripts/economy/production_action_facade.gd")

const CANONICAL_SAVE_PATH := "user://scrubbots_save.dat"

var audio: AudioSettingsService
var haptics: HapticsSettingsService
## M41-C002 canonical Reduced Effects setting (default OFF).
var effects: EffectsSettingsService
var progression: LevelProgressionService
var economy: EconomyServices
var save: SaveService
var load_result: Dictionary = {}
var is_blocked: bool = false
## App-wide economy action facade (menus/Home; no gameplay host). Committed
## actions save through request_save (M40 V04, F-M40-V03-003).
var actions: ProductionActionFacade
var _dirty: bool = false

## clock/local_day are test seams. Production passes neither: the shipping graph
## injects the real OS local-calendar provider explicitly (F-M39-V03-002).
func _init(save_path: String = CANONICAL_SAVE_PATH, clock: Callable = Callable(), local_day: Callable = Callable()) -> void:
	audio = AudioSettingsService.new()
	haptics = HapticsSettingsService.new()
	effects = EffectsSettingsService.new()
	progression = LevelProgressionService.new()
	var day_provider: Callable = local_day if local_day.is_valid() else LocalCalendar.system_provider()
	economy = EconomyServices.new(EconomyConfig.DEFAULT_PATH, clock, null, day_provider)
	save = SaveService.new(save_path, audio, haptics, progression, economy, effects)
	load_result = save.load()
	is_blocked = not bool(load_result.get("ok", false)) and String(load_result.get("source", "")) == "future_schema"
	actions = ProductionActionFacade.new(economy, null, Callable(self, "request_save"))

## True when the app must not proceed to gameplay against fresh defaults
## (F-M40-V02-002/-008: future/unsupported schema case).
func blocked_reason() -> String:
	return String(load_result.get("source", ""))

## Canonical durable save (M40 V04). Called by the action facade after every
## committed durable action, by the gameplay host at its save boundaries and by
## flush(). Never writes while blocked (future-schema save is preserved).
func request_save() -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	var r: Dictionary = save.save()
	if r.get("ok", false):
		_dirty = false
	return r

## Mark in-memory durable state as pending (no write). Flushed at the next
## lifecycle boundary. Not per-frame.
func mark_dirty() -> void:
	_dirty = true

func is_dirty() -> bool:
	return _dirty

## Lifecycle flush (background/pause, focus loss, close/quit). Writes the
## canonical save once; lifecycle events are rare, so this also captures any
## state a caller forgot to mark dirty. Refused while blocked.
func flush() -> Dictionary:
	return request_save()

# ----------------------------------------------------- settings actions ----
# Settings mutate only through these app actions, which persist canonically.

func set_haptics_enabled(enabled: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	haptics.set_enabled(enabled)
	return request_save()

## M41 V01 live audio actions. `bus` is "master" | "music" | "sfx". The value applies to
## the AudioServer immediately. persist=false (slider drag in progress) only marks the state
## dirty; the Settings UI saves on drag end / close and the app lifecycle flush covers the
## rest. Unknown bus => rejected, nothing mutated.
func set_audio_volume(bus: String, value: float, persist: bool = true) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	match bus:
		"master": audio.set_master_volume(value)
		"music": audio.set_music_volume(value)
		"sfx": audio.set_sfx_volume(value)
		_: return {"ok": false, "reason": "unknown_bus"}
	if not persist:
		mark_dirty()
		return {"ok": true, "pending": true}
	return request_save()

## M41 V01 channel ON/OFF (OFF mutes, keeps the slider value). Applies live and persists.
func set_audio_enabled(bus: String, on: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	match bus:
		"master": audio.set_master_enabled(on)
		"music": audio.set_music_enabled(on)
		"sfx": audio.set_sfx_enabled(on)
		_: return {"ok": false, "reason": "unknown_bus"}
	return request_save()

## Save only when a deferred settings change is pending (Settings drag end / close).
func flush_if_dirty() -> Dictionary:
	if not _dirty:
		return {"ok": true, "skipped": true}
	return request_save()

## M41-C002 Reduced Effects: applies live (service `changed` -> gameplay cleaning FX) and
## persists canonically. Refused while blocked.
func set_reduced_effects(on: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	effects.set_reduced(on)
	return request_save()

func set_volumes(master: float, music: float, sfx: float) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	audio.set_master_volume(master)
	audio.set_music_volume(music)
	audio.set_sfx_volume(sfx)
	return request_save()
