extends SceneTree
## M40-C001 V01 — versioned save system evidence.
## Run: godot --headless --path . -s res://tests/m40_save_system.gd
## All tests use isolated user:// test paths; the owner's real save/settings are
## never touched.

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const SaveService = preload("res://scripts/save/save_service.gd")

var _fail := 0
var _t := [10_000_000]
var _tmpfiles: Array = []

func _clock() -> int:
	return _t[0]

func _uniq(tag: String) -> String:
	var p := "user://m40_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmpfiles.append(p)
	return p

func _graph(save_path: String) -> Dictionary:
	var audio = AudioSettingsService.new("user://__m40_audio_%d.cfg" % Time.get_ticks_usec())
	var haptics = HapticsSettingsService.new("user://__m40_hap_%d.cfg" % Time.get_ticks_usec())
	var prog = LevelProgressionService.new()
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	var econ = EconomyServices.new(EconomyServices.EconomyConfig.DEFAULT_PATH, Callable(self, "_clock"), rng)
	var svc = SaveService.new(save_path, audio, haptics, prog, econ)
	svc.set_legacy_audio_path("user://__m40_no_legacy_%d.cfg" % Time.get_ticks_usec())
	return {"svc": svc, "audio": audio, "haptics": haptics, "prog": prog, "econ": econ}

func _initialize() -> void:
	_missing_save_defaults()
	_round_trip()
	_save_twice_load_twice()
	_crash_before_replace()
	_corrupt_primary_valid_backup()
	_corrupt_both()
	_future_schema_refused()
	_older_schema_migrated()
	_missing_economy_fields()
	_stale_tx_after_reload()
	_wallclock_across_relaunch()
	_daily_duplicate_resistance()
	_removed_economy_rejected()
	_cleanup()
	_done()

func _missing_save_defaults() -> void:
	print("[missing save]")
	var path := _uniq("missing")
	var g = _graph(path)
	var r = g["svc"].load()
	_ok(r["ok"] and r["source"] == "defaults", "no save -> defaults")
	_ok(g["econ"].wallet.scrub_bucks() == 1000, "new player has 1000 SB")
	_ok(g["econ"].robots.is_unlocked("scrubby"), "scrubby unlocked")
	# Loading repeatedly does not re-grant.
	g["svc"].load()
	_ok(g["econ"].wallet.scrub_bucks() == 1000, "repeat load does not regrant 1000")

func _round_trip() -> void:
	print("[round trip]")
	var path := _uniq("rt")
	var g = _graph(path)
	var econ = g["econ"]; var prog = g["prog"]
	# Mutate a broad slice of canonical state.
	prog.record_win(1); prog.record_win(2)                       # frontier 3
	econ.first_clear.grant_first_clear(1, "EASY")
	econ.streak.process_first_clear_win(1)                       # streak 1, +1 SB
	econ.wallet.credit(EconomyWallet.BOT_PARTS, 300); econ.robots.unlock("robot_2")
	econ.boosters.add_charges("tornado", 3)
	econ.collection.add_card("s1_c0"); econ.collection.add_card("s1_c0")  # 2 copies
	g["audio"].set_master_volume(0.4); g["audio"].set_sfx_volume(0.2)
	g["haptics"].set_enabled(false)
	var save_r = g["svc"].save()
	_ok(save_r["ok"], "save ok: %s" % str(save_r))
	# Fresh graph loads.
	var g2 = _graph(path)
	var r = g2["svc"].load()
	_ok(r["ok"] and r["source"] == "primary", "load from primary")
	_ok(g2["prog"].current_level() == 3, "progression frontier restored")
	_ok(g2["econ"].robots.is_unlocked("robot_2"), "robot unlock restored")
	_ok(g2["econ"].boosters.charges("tornado") == 3, "booster charges restored")
	_ok(g2["econ"].collection.owned("s1_c0") == 2, "card counts restored")
	_ok(is_equal_approx(g2["audio"].get_master_volume(), 0.4), "audio master restored")
	_ok(not g2["haptics"].is_enabled(), "haptics toggle restored")

func _save_twice_load_twice() -> void:
	print("[save/load twice]")
	var path := _uniq("twice")
	var g = _graph(path)
	g["prog"].record_win(1)
	g["econ"].streak.process_first_clear_win(1)
	_ok(g["svc"].save()["ok"], "first save ok")
	_ok(g["svc"].save()["ok"], "second save ok (idempotent write)")
	var g2 = _graph(path)
	g2["svc"].load()
	var streak_after_load = g2["econ"].streak.streak()
	g2["svc"].load()
	_ok(g2["econ"].streak.streak() == streak_after_load, "double load does not advance streak")

func _crash_before_replace() -> void:
	print("[crash before replace]")
	var path := _uniq("crash")
	var g = _graph(path)
	g["prog"].record_win(1)
	_ok(g["svc"].save()["ok"], "initial good save")
	# Now inject a replace failure on the next save.
	g["prog"].record_win(2)
	g["svc"].set_fault_injector(func(stage): return stage == "primary_replace")
	var r = g["svc"].save()
	_ok(not r["ok"] and r["reason"] == "replace_failed", "replace fault reported")
	# Primary still holds the previous good save (frontier 2, i.e. one win).
	g["svc"].set_fault_injector(Callable())
	var g2 = _graph(path)
	g2["svc"].load()
	_ok(g2["prog"].current_level() == 2, "last valid save intact after failed replace")

func _corrupt_primary_valid_backup() -> void:
	print("[corrupt primary/backup ok]")
	var path := _uniq("corrupt1")
	var g = _graph(path)
	g["prog"].record_win(1)
	g["svc"].save()                       # primary v1
	g["prog"].record_win(2)
	g["svc"].save()                       # primary v2, backup = v1
	# Corrupt the primary.
	_write(path, "{ this is not valid json ")
	var g2 = _graph(path)
	var r = g2["svc"].load()
	_ok(r["ok"] and r["source"] == "backup", "recovers from backup")
	_ok(g2["prog"].current_level() == 2, "backup holds the prior good state")

func _corrupt_both() -> void:
	print("[corrupt both]")
	var path := _uniq("corrupt2")
	var g = _graph(path)
	g["prog"].record_win(1); g["svc"].save(); g["prog"].record_win(2); g["svc"].save()
	_write(path, "garbage")
	_write(path + ".bak", "also garbage")
	var g2 = _graph(path)
	var r = g2["svc"].load()
	_ok(r["ok"] and r["source"] == "defaults", "both corrupt -> safe defaults")
	_ok(g2["econ"].wallet.scrub_bucks() == 1000, "safe defaults are new-player state")

func _future_schema_refused() -> void:
	print("[future schema]")
	var path := _uniq("future")
	_write(path, JSON.stringify({"schema": "scrubbots.save", "version": 999, "settings": {"audio": {}}, "economy": {}, "progression": {}}))
	var g = _graph(path)
	var r = g["svc"].load()
	# M40 V02 (F-M40-003): future schema with no compatible backup returns an
	# explicit unsupported result — NOT a fresh-profile defaults fall-through.
	_ok(not r["ok"] and r["source"] == "future_schema", "future schema -> explicit unsupported (no downgrade)")
	var raw = _read(path)
	_ok(raw.find("999") != -1, "future save left on disk, not silently downgraded")

func _older_schema_migrated() -> void:
	print("[older schema]")
	var path := _uniq("older")
	# A version-0 save missing sections migrates to current with safe defaults.
	_write(path, JSON.stringify({"schema": "scrubbots.save", "version": 0}))
	var g = _graph(path)
	var r = g["svc"].load()
	_ok(r["ok"] and r["source"] == "primary", "older schema migrated + loaded")
	_ok(g["prog"].current_level() == 1, "migrated progression default frontier 1")
	_ok(g["econ"].wallet.scrub_bucks() == 1000, "migrated economy safe default (no double grant)")

func _missing_economy_fields() -> void:
	print("[missing economy fields]")
	var path := _uniq("partial")
	# Valid current-schema save but economy has only a wallet, missing others.
	_write(path, JSON.stringify({
		"schema": "scrubbots.save", "version": 1,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": {"schema": "scrubbots.progression.v1", "current_level": 5, "completed": [1,2,3,4]},
		"economy": {"reward": {"applied": [], "wallet": {"scrub_bucks": 777, "bot_parts": 3}}},
	}))
	var g = _graph(path)
	var r = g["svc"].load()
	_ok(r["ok"], "partial economy loads")
	_ok(g["econ"].wallet.scrub_bucks() == 777 and g["econ"].wallet.bot_parts() == 3, "present fields restored")
	_ok(g["prog"].current_level() == 5, "progression restored")
	# Missing sections default safely (no Stars invented).
	_ok(g["econ"].boosters.charges("random") == 0, "missing booster section -> safe default 0")

func _stale_tx_after_reload() -> void:
	print("[stale tx]")
	var path := _uniq("stale")
	var g = _graph(path)
	g["prog"].record_win(1)
	g["econ"].first_clear.grant_first_clear(1, "EASY")
	g["econ"].streak.process_first_clear_win(1)
	g["svc"].save()
	var g2 = _graph(path)
	g2["svc"].load()
	var sb = g2["econ"].wallet.scrub_bucks()
	# Replay the SAME first-clear + streak transactions after reload: no re-grant.
	g2["econ"].first_clear.grant_first_clear(1, "EASY")
	g2["econ"].streak.process_first_clear_win(1)
	_ok(g2["econ"].wallet.scrub_bucks() == sb, "stale transaction replay after reload grants nothing")

func _wallclock_across_relaunch() -> void:
	print("[wall clock relaunch]")
	var path := _uniq("clock")
	_t[0] = 20_000_000
	var g = _graph(path)
	# Consume 3 hearts, buy timed 2x, then save.
	g["econ"].hearts.consume(); g["econ"].hearts.consume(); g["econ"].hearts.consume()
	g["econ"].speed.purchase_timed(1800)
	g["svc"].save()
	var hearts_at_save = g["econ"].hearts.hearts()
	# Relaunch 1 hour later (2 regens) into a fresh graph sharing the same clock.
	_t[0] += 3600
	var g2 = _graph(path)
	g2["svc"].load()
	_ok(g2["econ"].hearts.hearts() == hearts_at_save + 2, "heart regen continues across relaunch by wall clock")
	_ok(g2["econ"].speed.timed_seconds_remaining() >= 0, "timed 2x expiry survives relaunch")
	# Large forward jump caps hearts at max, never overflows.
	_t[0] += 3600 * 100
	_ok(g2["econ"].hearts.hearts() == g2["econ"].hearts.max_hearts(), "huge forward jump caps hearts at max")
	# Clock rollback does not refill/duplicate.
	_t[0] -= 3600 * 1000
	_ok(g2["econ"].hearts.hearts() == g2["econ"].hearts.max_hearts(), "rollback does not corrupt hearts")

func _daily_duplicate_resistance() -> void:
	print("[daily relaunch]")
	var path := _uniq("daily")
	_t[0] = 400 * 86400 + 3600
	var g = _graph(path)
	g["econ"].daily.claim_login()
	g["svc"].save()
	# Relaunch same day: claim must be refused (anti-rollback record survives).
	var g2 = _graph(path)
	g2["svc"].load()
	_ok(not g2["econ"].daily.claim_login()["ok"], "same-day login refused after relaunch")

func _removed_economy_rejected() -> void:
	print("[removed economy rejected]")
	var path := _uniq("removed")
	_write(path, JSON.stringify({
		"schema": "scrubbots.save", "version": 1,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": {}, "economy": {"stars": 500},
	}))
	var g = _graph(path)
	var r = g["svc"].load()
	# Economy has a removed-economy field -> candidate invalid -> defaults.
	_ok(r["source"] == "defaults", "removed-economy field rejected -> defaults")

# --- utils ---

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(text); f.close()
	_tmpfiles.append(path)

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return ""
	var t := f.get_as_text(); f.close(); return t

func _cleanup() -> void:
	for p in _tmpfiles:
		for q in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(q):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(q))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M40 save system evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
