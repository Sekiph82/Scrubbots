extends RefCounted
## SaveService — preload
## (res://scripts/save/save_service.gd).
##
## The ONE canonical versioned save lifecycle. It owns no gameplay/economy truth:
## it collects immutable snapshots from the runtime services (M33 audio, M34
## haptics, M37 progression, M38/M39 economy) and applies validated snapshots
## back through their narrow import APIs.
##
## Write is crash-resistant: serialize -> temp file -> validate temp -> back up
## the last good save -> replace. A failed write never corrupts the last valid
## save. Load is a transaction: read -> parse -> migrate -> validate the FULL
## candidate on a scratch service graph -> only then apply to live services; if
## any stage fails the live state is captured and restored exactly.
##
## Test paths are injected; production defaults live under user://.

const SCHEMA := "scrubbots.save"
const VERSION := 1

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")

var _path: String
var _audio: AudioSettingsService
var _haptics: HapticsSettingsService
var _progression: LevelProgressionService
var _economy: EconomyServices
## Test-only fault injector: Callable(stage:String) -> bool; true forces failure.
var _fault: Callable = Callable()
## Legacy M33 audio cfg path for the one-time migration (injectable for test
## isolation so tests never read the owner's real user:// settings).
var _legacy_audio_path: String = AudioSettingsService.DEFAULT_CONFIG_PATH

func _init(path: String, audio, haptics, progression, economy) -> void:
	_path = path
	_audio = audio
	_haptics = haptics
	_progression = progression
	_economy = economy

func set_legacy_audio_path(p: String) -> void:
	_legacy_audio_path = p

func set_fault_injector(f: Callable) -> void:
	_fault = f

func _faulted(stage: String) -> bool:
	return _fault.is_valid() and bool(_fault.call(stage))

func _backup_path() -> String:
	return _path + ".bak"

func _temp_path() -> String:
	return _path + ".tmp"

# --------------------------------------------------------------- collect ----

func collect() -> Dictionary:
	return {
		"schema": SCHEMA,
		"version": VERSION,
		"settings": {
			"audio": {
				"master": _audio.get_master_volume(),
				"music": _audio.get_music_volume(),
				"sfx": _audio.get_sfx_volume(),
			},
			"haptics": _haptics.snapshot(),
		},
		"progression": _progression.snapshot(),
		"economy": _economy.snapshot(),
	}

# --------------------------------------------------------------- validate ----

## Structural + semantic validation of a full candidate. Does NOT mutate live
## state — it dry-runs the section imports on a scratch service graph.
func validate_candidate(cand) -> Dictionary:
	if typeof(cand) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "not_object"}
	if cand.get("schema", "") != SCHEMA:
		return {"ok": false, "reason": "bad_schema"}
	var ver = cand.get("version", null)
	if typeof(ver) != TYPE_INT and typeof(ver) != TYPE_FLOAT:
		return {"ok": false, "reason": "bad_version_type"}
	if int(ver) > VERSION:
		return {"ok": false, "reason": "future_schema"}   # fail closed, no downgrade
	# Settings shape.
	var settings = cand.get("settings", {})
	if typeof(settings) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "bad_settings"}
	var audio = settings.get("audio", {})
	if typeof(audio) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "bad_audio"}
	for k in ["master", "music", "sfx"]:
		var v = audio.get(k, 1.0)
		if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
			return {"ok": false, "reason": "audio_%s_type" % k}
		if is_nan(v) or is_inf(v) or v < 0.0 or v > 1.0:
			return {"ok": false, "reason": "audio_%s_range" % k}
	# Removed economies must not appear as authoritative economy state.
	var economy = cand.get("economy", {})
	if typeof(economy) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "bad_economy"}
	for banned in ["stars", "star_currency", "event_points", "profile_xp"]:
		if economy.has(banned):
			return {"ok": false, "reason": "removed_economy_%s" % banned}
	# Dry-run: import into scratch services; any failure => invalid candidate.
	var scratch = EconomyServices.new()
	if not scratch.import_snapshot(economy):
		return {"ok": false, "reason": "economy_import"}
	var scratch_prog = LevelProgressionService.new()
	if not scratch_prog.import_snapshot(cand.get("progression", {})):
		return {"ok": false, "reason": "progression_import"}
	var scratch_hap = HapticsSettingsService.new("user://__scratch_haptics.cfg")
	scratch_hap.import_snapshot(settings.get("haptics", {}))
	return {"ok": true}

# --------------------------------------------------------------- migration ----

## Deterministic migration to the current VERSION. Fills missing Economy V1
## fields with safe defaults WITHOUT double-granting (defaults are neutral
## empty state, never re-initialization rewards). Future versions are refused by
## validate_candidate before this runs.
func migrate(cand: Dictionary) -> Dictionary:
	var v := int(cand.get("version", 0))
	# v == VERSION: nothing to do.
	# v < VERSION: apply each step in order. (Only one version so far, so this is
	# the extension point; missing sections are backfilled to safe empties.)
	if v < VERSION:
		if not cand.has("economy"):
			cand["economy"] = {}
		if not cand.has("progression"):
			cand["progression"] = {"schema": "scrubbots.progression.v1", "current_level": 1, "completed": []}
		if not cand.has("settings"):
			cand["settings"] = {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}}
		cand["version"] = VERSION
	return cand

# --------------------------------------------------------------- apply ----

## Apply a validated candidate to the LIVE services atomically. Captures the
## live snapshot first; on any failure restores it exactly.
func _apply(cand: Dictionary) -> bool:
	var backup := collect()   # exact live state before applying.
	var settings = cand.get("settings", {})
	var audio = settings.get("audio", {})
	_audio.set_master_volume(float(audio.get("master", 1.0)))
	_audio.set_music_volume(float(audio.get("music", 1.0)))
	_audio.set_sfx_volume(float(audio.get("sfx", 1.0)))
	_haptics.import_snapshot(settings.get("haptics", {}))
	var ok := _progression.import_snapshot(cand.get("progression", {})) and _economy.import_snapshot(cand.get("economy", {}))
	if not ok:
		# Restore exactly.
		_progression.import_snapshot(backup["progression"])
		_economy.import_snapshot(backup["economy"])
		var ba = backup["settings"]["audio"]
		_audio.set_master_volume(ba["master"]); _audio.set_music_volume(ba["music"]); _audio.set_sfx_volume(ba["sfx"])
		_haptics.import_snapshot(backup["settings"]["haptics"])
		return false
	return true

# --------------------------------------------------------------- save ----

## Serialize -> temp -> validate temp -> backup -> replace. Returns {ok, reason}.
func save() -> Dictionary:
	var cand := collect()
	var text := JSON.stringify(cand)
	# 1. write temp
	if _faulted("temp_write"):
		return {"ok": false, "reason": "temp_write_failed"}
	if not _write_file(_temp_path(), text):
		return {"ok": false, "reason": "temp_write_failed"}
	# 2. validate temp by reading it back
	var reread = _read_json(_temp_path())
	if reread == null or validate_candidate(reread).get("ok", false) == false:
		_remove(_temp_path())
		return {"ok": false, "reason": "temp_invalid"}
	# 3. back up the last good primary (if any) before destructive replace
	if FileAccess.file_exists(_path):
		var prev := _read_text(_path)
		if prev != "":
			_write_file(_backup_path(), prev)
	# 4. replace primary
	if _faulted("replace"):
		# Leave primary + backup untouched; temp discarded.
		_remove(_temp_path())
		return {"ok": false, "reason": "replace_failed"}
	if not _write_file(_path, text):
		return {"ok": false, "reason": "replace_failed"}
	_remove(_temp_path())
	return {"ok": true}

# --------------------------------------------------------------- load ----

## Read primary; on any failure fall back to backup; if both fail, new-player
## defaults (services stay at their construction defaults). Returns
## {ok, source} where source is primary/backup/defaults.
func load() -> Dictionary:
	var primary := _try_load_path(_path)
	if primary.get("ok", false):
		return {"ok": true, "source": "primary"}
	var backup := _try_load_path(_backup_path())
	if backup.get("ok", false):
		return {"ok": true, "source": "backup"}
	# No usable save: one-time legacy audio cfg migration if present.
	_maybe_migrate_legacy_audio()
	return {"ok": true, "source": "defaults"}

func _try_load_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "missing"}
	var cand = _read_json(path)
	if cand == null:
		return {"ok": false, "reason": "parse"}
	if typeof(cand) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "not_object"}
	cand = migrate(cand)
	var v := validate_candidate(cand)
	if not v.get("ok", false):
		return {"ok": false, "reason": v.get("reason")}
	if not _apply(cand):
		return {"ok": false, "reason": "apply_failed"}
	return {"ok": true}

## One-time compatibility: if a legacy M33 user://audio_settings.cfg exists and
## no canonical save was loaded, pull its values into the live audio service so
## they are captured into the next canonical save. Kept as a clearly separated
## one-shot path — no two files silently overwrite the same setting.
func _maybe_migrate_legacy_audio() -> void:
	if FileAccess.file_exists(_legacy_audio_path):
		var legacy = AudioSettingsService.new(_legacy_audio_path)
		if legacy.load():
			_audio.set_master_volume(legacy.get_master_volume())
			_audio.set_music_volume(legacy.get_music_volume())
			_audio.set_sfx_volume(legacy.get_sfx_volume())

# --------------------------------------------------------------- io utils ----

func _write_file(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true

func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _read_json(path: String):
	var t := _read_text(path)
	if t == "":
		return null
	var json := JSON.new()
	if json.parse(t) != OK:
		return null
	return json.get_data()

func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
