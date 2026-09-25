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
const IntDomain = preload("res://scripts/economy/int_domain.gd")

## M41 V01 settings.audio on/off keys (optional for pre-M41 saves, default ON).
const AUDIO_TOGGLE_KEYS := ["master_on", "music_on", "sfx_on"]

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
			"audio": _audio.snapshot(),
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
	var ver = IntDomain.exact_int(cand.get("version", null))
	if ver == null:
		return {"ok": false, "reason": "bad_version_type"}   # fractional/NaN/non-int
	if ver > VERSION:
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
	# M41 V01 channel toggles. Absent (a save written before M41) => ON; present but not an
	# exact bool => the whole candidate fails closed (AL-083: no silent normalization).
	for k in AUDIO_TOGGLE_KEYS:
		if audio.has(k) and typeof(audio[k]) != TYPE_BOOL:
			return {"ok": false, "reason": "audio_%s_type" % k}
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
	# Strict haptics validation (F-M40-V02-006): a corrupt canonical
	# `settings.haptics` invalidates the whole candidate rather than being
	# silently normalized to the safe default.
	var scratch_hap = HapticsSettingsService.new("user://__scratch_haptics.cfg")
	if not scratch_hap.strict_import_snapshot(settings.get("haptics", {})):
		return {"ok": false, "reason": "haptics_malformed"}
	return {"ok": true}

# --------------------------------------------------------------- migration ----

## Deterministic migration to the current VERSION. Fills missing Economy V1
## fields with safe defaults WITHOUT double-granting (defaults are neutral
## empty state, never re-initialization rewards). Future versions are refused by
## validate_candidate before this runs.
func migrate(cand: Dictionary) -> Dictionary:
	# Reject malformed version before any coercion (F-M40-V02-003): 0.5 / "0" /
	# NaN / INF must never be int()-coerced into a valid older version. The load
	# path calls validate_candidate() before migrate so this is a defensive
	# double-check; direct callers get the same fail-closed guarantee (returns
	# the input untouched, so validate_candidate later rejects it).
	var v = IntDomain.exact_int(cand.get("version", null))
	if v == null:
		return cand
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
	_apply_audio_toggles(audio)
	# strict_import_snapshot is guaranteed to succeed here — validate_candidate
	# rejected malformed haptics upstream.
	_haptics.strict_import_snapshot(settings.get("haptics", {}))
	var ok := _progression.import_snapshot(cand.get("progression", {})) and _economy.import_snapshot(cand.get("economy", {}))
	if not ok:
		# Restore exactly.
		_progression.import_snapshot(backup["progression"])
		_economy.import_snapshot(backup["economy"])
		var ba = backup["settings"]["audio"]
		_audio.set_master_volume(ba["master"]); _audio.set_music_volume(ba["music"]); _audio.set_sfx_volume(ba["sfx"])
		_apply_audio_toggles(ba)
		_haptics.import_snapshot(backup["settings"]["haptics"])
		return false
	return true

## Apply validated M41 toggles (validate_candidate already rejected non-bool values).
func _apply_audio_toggles(audio: Dictionary) -> void:
	_audio.set_master_enabled(bool(audio.get("master_on", true)))
	_audio.set_music_enabled(bool(audio.get("music_on", true)))
	_audio.set_sfx_enabled(bool(audio.get("sfx_on", true)))

# --------------------------------------------------------------- save ----

## Safe write lifecycle (M40 V02, F-M40-001/002/003):
##   1. serialize + write TEMP; validate TEMP by reading it back.
##   2. refuse if the existing primary is a FUTURE schema (never overwrite it).
##   3. rotate backup ONLY from a fully VALIDATED existing primary — a corrupt/
##      unvalidated primary never poisons the last-known-good backup.
##   4. replace the primary by RENAMING the validated temp over it (near-atomic;
##      the primary path is freed first so the rename cannot leave a truncated
##      primary). Every I/O result is checked. On a replace failure the previous
##      primary/backup are left intact.
## Returns {ok, reason}.
func save() -> Dictionary:
	var cand := collect()
	var text := JSON.stringify(cand)

	# 1. temp write + validate.
	if _faulted("temp_write") or not _write_file(_temp_path(), text):
		_remove(_temp_path())
		return {"ok": false, "reason": "temp_write_failed"}
	if _faulted("temp_validate"):
		_remove(_temp_path())
		return {"ok": false, "reason": "temp_invalid"}
	var reread = _read_json(_temp_path())
	if reread == null or not validate_candidate(reread).get("ok", false):
		_remove(_temp_path())
		return {"ok": false, "reason": "temp_invalid"}

	# 2. never overwrite a future-schema primary.
	if FileAccess.file_exists(_path):
		var existing = _read_json(_path)
		if typeof(existing) == TYPE_DICTIONARY and existing.get("schema", "") == SCHEMA:
			var ev = IntDomain.exact_int(existing.get("version", null))
			if ev != null and ev > VERSION:
				_remove(_temp_path())
				return {"ok": false, "reason": "would_overwrite_future_schema"}

	# 3. rotate backup ONLY from a validated primary.
	if FileAccess.file_exists(_path):
		var current = _read_json(_path)
		var primary_valid := false
		if typeof(current) == TYPE_DICTIONARY:
			primary_valid = bool(validate_candidate(migrate(current.duplicate(true))).get("ok", false))
		if _faulted("backup_rotate"):
			_remove(_temp_path())
			return {"ok": false, "reason": "backup_rotate_failed"}
		if primary_valid:
			# Move the validated primary into backup (replacing the old backup).
			_remove(_backup_path())
			if not _rename(_path, _backup_path()):
				_remove(_temp_path())
				return {"ok": false, "reason": "backup_rotate_failed"}
		else:
			# Corrupt/unvalidated primary: preserve the good backup, discard the
			# corrupt primary so the rename target is free.
			_remove(_path)

	# 4. near-atomic replace: rename validated temp over the (now free) primary.
	if _faulted("primary_replace"):
		# Leave temp for diagnosis-free cleanup; primary/backup untouched.
		_remove(_temp_path())
		return {"ok": false, "reason": "replace_failed"}
	if not _rename(_temp_path(), _path):
		_remove(_temp_path())
		return {"ok": false, "reason": "replace_failed"}
	return {"ok": true}

# --------------------------------------------------------------- load ----

## Read primary; on any failure fall back to backup; if both fail, new-player
## defaults. A FUTURE-schema primary with no compatible backup returns an
## explicit unsupported result (ok:false, source:"future_schema") and does NOT
## start a fresh profile — so a later save cannot auto-overwrite the future save
## (F-M40-003). Returns {ok, source} where source is primary/backup/defaults or,
## on the unsupported path, {ok:false, source:"future_schema"}.
func load() -> Dictionary:
	var primary := _try_load_path(_path)
	if primary.get("ok", false):
		return {"ok": true, "source": "primary"}
	var backup := _try_load_path(_backup_path())
	if backup.get("ok", false):
		return {"ok": true, "source": "backup"}
	# No usable save from either slot. If the primary is a future schema, refuse
	# explicitly and preserve it (never auto-overwrite via a fresh profile).
	if primary.get("reason", "") == "future_schema":
		return {"ok": false, "source": "future_schema"}
	# Otherwise: new-player defaults; one-time legacy audio cfg migration if present.
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

## Rename (near-atomic replace). Returns true on success. The caller frees the
## destination path first so the rename never has to overwrite an existing file
## (portable across platforms whose rename() refuses an existing destination).
func _rename(from_path: String, to_path: String) -> bool:
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(from_path),
		ProjectSettings.globalize_path(to_path)) == OK
