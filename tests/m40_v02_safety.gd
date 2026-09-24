extends SceneTree
## M40-C001 V02 — save-system safety & bootstrap remediation (F-M40-001..007).
## Isolated user:// test paths only. Run:
## godot --headless --path . -s res://tests/m40_v02_safety.gd

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	_atomic_replace_and_backup_protection()
	_future_schema_block()
	_fractional_schema_rejected()
	_fault_injection_preserves_last_good()
	await _bootstrap_lifecycle()
	_cleanup()
	_done()

func _uniq(tag: String) -> String:
	var p := "user://m40v2_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _graph(path: String) -> Dictionary:
	var audio = AudioSettingsService.new("user://__m40v2_a_%d.cfg" % Time.get_ticks_usec())
	var hap = HapticsSettingsService.new("user://__m40v2_h_%d.cfg" % Time.get_ticks_usec())
	var prog = LevelProgressionService.new()
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var econ = EconomyServices.new(EconomyServices.EconomyConfig.DEFAULT_PATH, Callable(), rng)
	var svc = SaveService.new(path, audio, hap, prog, econ)
	svc.set_legacy_audio_path("user://__m40v2_nolegacy_%d.cfg" % Time.get_ticks_usec())
	return {"svc": svc, "econ": econ, "prog": prog}

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(text); f.close()
	_tmp.append(path)

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return ""
	var t := f.get_as_text(); f.close(); return t

func _atomic_replace_and_backup_protection() -> void:
	print("[atomic replace + backup protection F-M40-001/002]")
	var path := _uniq("rot")
	var g = _graph(path)
	g["prog"].record_win(1)             # frontier 2
	_ok(g["svc"].save()["ok"], "save v1 ok")
	g["prog"].record_win(2)             # frontier 3
	_ok(g["svc"].save()["ok"], "save v2 ok (backup rotated from validated primary)")
	# Corrupt the primary, then save v3. The corrupt primary must NOT poison the
	# good backup; primary is replaced by the validated temp.
	_write(path, "{ corrupt primary")
	g["prog"].record_win(3)             # frontier 4
	_ok(g["svc"].save()["ok"], "save v3 ok despite corrupt primary")
	# Backup must still be a VALID save (the last-known-good v1, since v2's rotate
	# happened before corruption and v3 refused to rotate the corrupt primary).
	var gb = _graph(path)
	var loaded = gb["svc"].load()
	_ok(loaded["source"] == "primary", "v3 primary loads after replacement")
	_ok(gb["prog"].current_level() == 4, "primary is the v3 state (frontier 4)")
	# The backup file is still valid JSON (not poisoned by the corrupt primary).
	var bak := _read(path + ".bak")
	var json := JSON.new()
	_ok(bak != "" and json.parse(bak) == OK, "backup remains valid (not poisoned by corrupt primary)")

func _future_schema_block() -> void:
	print("[future schema block F-M40-003]")
	var path := _uniq("future")
	_write(path, JSON.stringify({"schema": "scrubbots.save", "version": 999,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": {}, "economy": {}}))
	var g = _graph(path)
	var r = g["svc"].load()
	_ok(not r["ok"] and r["source"] == "future_schema", "future schema -> explicit unsupported (not defaults)")
	# A subsequent save must REFUSE to overwrite the future-schema primary.
	var sr = g["svc"].save()
	_ok(not sr["ok"] and sr["reason"] == "would_overwrite_future_schema", "save refuses to overwrite future schema")
	var raw := _read(path)
	_ok(raw.find("999") != -1, "future-schema file preserved on disk")

func _fractional_schema_rejected() -> void:
	print("[fractional schema/state F-M40-004]")
	var path := _uniq("frac")
	# Fractional schema version rejected -> not loaded as primary.
	_write(path, JSON.stringify({"schema": "scrubbots.save", "version": 1.5,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": {}, "economy": {}}))
	var g = _graph(path)
	var r = g["svc"].load()
	_ok(r["source"] == "defaults", "fractional schema version rejected -> defaults (no backup)")

func _fault_injection_preserves_last_good() -> void:
	print("[fault injection preserves last-good F-M40-002]")
	for stage in ["temp_write", "temp_validate", "backup_rotate", "primary_replace"]:
		var path := _uniq("fault_%s" % stage)
		var g = _graph(path)
		g["prog"].record_win(1)
		_ok(g["svc"].save()["ok"], "%s: baseline save ok" % stage)
		var primary_before = _read(path)
		g["prog"].record_win(2)
		g["svc"].set_fault_injector(func(s): return s == stage)
		var r = g["svc"].save()
		_ok(not r["ok"], "%s: faulted save reported failure" % stage)
		g["svc"].set_fault_injector(Callable())
		# The previous valid primary must be intact and loadable.
		var gb = _graph(path)
		var loaded = gb["svc"].load()
		_ok(loaded["ok"] and (loaded["source"] == "primary" or loaded["source"] == "backup"), "%s: a valid save survived the fault" % stage)
		_ok(gb["prog"].current_level() == 2, "%s: last valid state (frontier 2) recovered" % stage)

func _bootstrap_lifecycle() -> void:
	print("[bootstrap lifecycle F-M40-006]")
	var path := _uniq("boot")
	# First host: fresh (no save). Drives to WON -> terminal save writes the file.
	var h1 = await _make_host(path)
	if h1 == null:
		return
	_ok(h1.get_save() != null, "host owns one canonical SaveService when save_path set")
	var sb0 = h1.get_economy().wallet.scrub_bucks()
	_drain(h1)
	_ok(h1.get_completion().is_won(), "first host reaches WON")
	_ok(FileAccess.file_exists(path), "terminal save wrote the canonical file (defined boundary)")
	var sb1 = h1.get_economy().wallet.scrub_bucks()
	_ok(sb1 == sb0 + 51, "WON economy applied (first-clear 50 + streak 1)")
	_free_host(h1)
	# Second host with the SAME save_path: LOAD occurs at build, before gameplay
	# consumes economy -> persisted SB/progression are authoritative from frame 0.
	var h2 = await _make_host(path)
	if h2 == null:
		return
	_ok(h2.get_economy().wallet.scrub_bucks() == sb1, "second host loaded persisted SB before consumption")
	_ok(h2.get_progression().current_level() == 2, "second host loaded persisted progression frontier")
	_free_host(h2)

# --- host driver ---

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(DT)
			if h.get_completion().is_terminal():
				break
			runtime.tick(DT)
			break

func _make_host(path: String):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.save_path = path
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(host) -> void:
	if host == null:
		return
	var sub = host.get_meta("sub") if host.has_meta("sub") else null
	if sub != null and is_instance_valid(sub):
		sub.free()

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _cleanup() -> void:
	for p in _tmp:
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
	print("M40 V02 safety evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
