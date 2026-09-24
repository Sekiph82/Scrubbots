extends RefCounted
## AppState — preload
## (res://scripts/app/app_state.gd).
##
## App-level canonical composition root for durable state (M40 V03,
## F-M40-V02-001). Owns exactly ONE instance of each canonical service graph
## used by the shipping runtime:
##   - AudioSettingsService (M33)
##   - HapticsSettingsService (M34)
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
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")

const CANONICAL_SAVE_PATH := "user://scrubbots_save.dat"

var audio: AudioSettingsService
var haptics: HapticsSettingsService
var progression: LevelProgressionService
var economy: EconomyServices
var save: SaveService
var load_result: Dictionary = {}
var is_blocked: bool = false

## clock/local_day are test seams. Production passes neither: the shipping graph
## injects the real OS local-calendar provider explicitly (F-M39-V03-002).
func _init(save_path: String = CANONICAL_SAVE_PATH, clock: Callable = Callable(), local_day: Callable = Callable()) -> void:
	audio = AudioSettingsService.new()
	haptics = HapticsSettingsService.new()
	progression = LevelProgressionService.new()
	var day_provider: Callable = local_day if local_day.is_valid() else LocalCalendar.system_provider()
	economy = EconomyServices.new(EconomyConfig.DEFAULT_PATH, clock, null, day_provider)
	save = SaveService.new(save_path, audio, haptics, progression, economy)
	load_result = save.load()
	is_blocked = not bool(load_result.get("ok", false)) and String(load_result.get("source", "")) == "future_schema"

## True when the app must not proceed to gameplay against fresh defaults
## (F-M40-V02-002/-008: future/unsupported schema case).
func blocked_reason() -> String:
	return String(load_result.get("source", ""))

## Marks durable meta state dirty for later coalesced save. Non-per-frame save
## coordinator (F-M40-V02-008): callers request a save at defined lifecycle
## boundaries (purchase, claim, unlock, terminal, background/quit). This
## minimal implementation flushes immediately — a coalescing timer belongs to
## M41 UI/app layer and does not change the observable behavior.
func request_save() -> Dictionary:
	return save.save()
