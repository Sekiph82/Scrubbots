extends SceneTree
## M33-C001 V01 — audio runtime evidence. Proves the M33 presentation-only audio
## infrastructure without relying on human audibility (owner F6 owns final listening):
##   - Master/Music/SFX buses exist and Music/SFX route through Master;
##   - AudioSettingsService independent set/get, 0.0 mute, clamp, persistence round-trip,
##     missing/corrupt safe defaults, isolated test config path;
##   - dispatch audio fires once per committed dispatch and never on a failed dispatch;
##   - cleaning audio fires once per authenticated clear; completion audio fires once on WON
##     and re-arms after Retry; LOST/ERROR play nothing;
##   - bounded voice pools: burst beyond cap suppresses deterministically, node count fixed,
##     active never exceeds cap;
##   - real production-stack flow at 1x AND 2x keeps canonical pitch and stays bounded;
##   - no movement stream/player/loop is created.
##
## Run: godot --headless --path . -s res://tests/m33_audio_runtime.gd
## Exits 0 on success, 1 on any failure.

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const GameplayAudioController = preload("res://scripts/audio/gameplay_audio_controller.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	_bus_layout()
	_settings_service()
	await _controller_unit()
	_dispatch_failure_emits_nothing()
	await _real_stack(false)   # 1x real committed flow + Retry re-arm
	await _real_stack(true)    # 2x density, canonical pitch, bounded
	_done()

# ------------------------------------------------------------- bus layout ----

func _bus_layout() -> void:
	print("[bus/settings]")
	var m := AudioServer.get_bus_index(AudioSettingsService.BUS_MASTER)
	var mu := AudioServer.get_bus_index(AudioSettingsService.BUS_MUSIC)
	var s := AudioServer.get_bus_index(AudioSettingsService.BUS_SFX)
	_ok(m >= 0, "Master bus exists")
	_ok(mu >= 0, "Music bus exists")
	_ok(s >= 0, "SFX bus exists")
	_ok(mu >= 0 and String(AudioServer.get_bus_send(mu)) == AudioSettingsService.BUS_MASTER, "Music routes to Master")
	_ok(s >= 0 and String(AudioServer.get_bus_send(s)) == AudioSettingsService.BUS_MASTER, "SFX routes to Master")

# ------------------------------------------------------- settings service ----

func _settings_service() -> void:
	var path := "user://m33_test_audio_%d.cfg" % (Time.get_ticks_usec())
	_remove_user_file(path)
	var svc = AudioSettingsService.new(path)

	# Independent set/get + AudioServer mapping.
	svc.set_master_volume(0.5)
	svc.set_music_volume(0.25)
	svc.set_sfx_volume(0.75)
	_ok(is_equal_approx(svc.get_master_volume(), 0.5), "master set/get independent")
	_ok(is_equal_approx(svc.get_music_volume(), 0.25), "music set/get independent")
	_ok(is_equal_approx(svc.get_sfx_volume(), 0.75), "sfx set/get independent")
	var sfx_idx := AudioServer.get_bus_index(AudioSettingsService.BUS_SFX)
	_ok(sfx_idx >= 0 and not AudioServer.is_bus_mute(sfx_idx), "sfx bus unmuted at >0 volume")
	_ok(sfx_idx >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), linear_to_db(0.75)), "sfx bus dB == linear_to_db(0.75)")

	# 0.0 mutes deterministically.
	svc.set_sfx_volume(0.0)
	_ok(sfx_idx >= 0 and AudioServer.is_bus_mute(sfx_idx), "sfx volume 0.0 mutes the bus")
	svc.set_sfx_volume(1.0)
	_ok(sfx_idx >= 0 and not AudioServer.is_bus_mute(sfx_idx), "sfx volume >0 unmutes the bus")

	# Out-of-range clamp + NaN safety.
	svc.set_master_volume(2.0)
	_ok(is_equal_approx(svc.get_master_volume(), 1.0), "over-range clamps to 1.0")
	svc.set_master_volume(-1.0)
	_ok(is_equal_approx(svc.get_master_volume(), 0.0), "under-range clamps to 0.0")
	svc.set_master_volume(NAN)
	_ok(is_equal_approx(svc.get_master_volume(), 1.0), "NaN falls back to neutral default")

	# Persistence round-trip through an isolated test path.
	svc.set_master_volume(0.4)
	svc.set_music_volume(0.6)
	svc.set_sfx_volume(0.8)
	_ok(svc.save(), "save() writes the isolated test config")
	var svc2 = AudioSettingsService.new(path)
	_ok(svc2.load(), "load() reads an existing config")
	_ok(is_equal_approx(svc2.get_master_volume(), 0.4), "persisted master reloads")
	_ok(is_equal_approx(svc2.get_music_volume(), 0.6), "persisted music reloads")
	_ok(is_equal_approx(svc2.get_sfx_volume(), 0.8), "persisted sfx reloads")

	# Missing file -> defaults, never blocks.
	var missing := "user://m33_test_missing_%d.cfg" % (Time.get_ticks_usec())
	_remove_user_file(missing)
	var svc3 = AudioSettingsService.new(missing)
	_ok(not svc3.load(), "missing config load() returns false")
	_ok(is_equal_approx(svc3.get_master_volume(), 1.0) and is_equal_approx(svc3.get_music_volume(), 1.0) and is_equal_approx(svc3.get_sfx_volume(), 1.0), "missing config -> full-neutral defaults")

	# Corrupt file -> defaults, never blocks.
	var corrupt := "user://m33_test_corrupt_%d.cfg" % (Time.get_ticks_usec())
	_write_user_file(corrupt, "[[[not a valid section]]]\n== = broken ][ = =\n%%%")
	var svc4 = AudioSettingsService.new(corrupt)
	_ok(not svc4.load(), "corrupt config load() returns false")
	_ok(is_equal_approx(svc4.get_master_volume(), 1.0), "corrupt config -> neutral defaults (never blocks startup)")

	# Out-of-range persisted value is clamped on load.
	var ranged := "user://m33_test_ranged_%d.cfg" % (Time.get_ticks_usec())
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", 5.0)
	cfg.set_value("audio", "music", -3.0)
	cfg.set_value("audio", "sfx", "garbage")
	cfg.save(ranged)
	var svc5 = AudioSettingsService.new(ranged)
	svc5.load()
	_ok(is_equal_approx(svc5.get_master_volume(), 1.0), "persisted over-range master clamps to 1.0")
	_ok(is_equal_approx(svc5.get_music_volume(), 0.0), "persisted under-range music clamps to 0.0")
	_ok(is_equal_approx(svc5.get_sfx_volume(), 1.0), "persisted non-numeric sfx falls back to default")

	_remove_user_file(path)
	_remove_user_file(missing)
	_remove_user_file(corrupt)
	_remove_user_file(ranged)
	# Restore neutral buses for the remaining tests.
	AudioSettingsService.new().load()

# ----------------------------------------------------- controller unit ----

func _controller_unit() -> void:
	print("[controller]")
	var ac = GameplayAudioController.new()
	get_root().add_child(ac)
	await process_frame

	# No movement audio: exactly the three canonical one-shots, none a movement stream.
	var paths: Array = ac.get_stream_paths()
	_ok(paths.size() == 3, "controller references exactly three canonical streams")
	var movement := false
	for p in paths:
		if String(p).to_lower().find("movement") != -1:
			movement = true
	_ok(not movement, "no canonical stream is a movement stream")
	var total_cap := GameplayAudioController.DISPATCH_VOICES + GameplayAudioController.CLEANING_VOICES + GameplayAudioController.COMPLETION_VOICES
	_ok(ac.get_allocated_voice_count() == total_cap, "allocated voice nodes == sum of caps (%d)" % total_cap)
	# No looping player exists (a loop would be a movement-style continuous sound).
	var any_loop := false
	for c in ac.get_children():
		if c is AudioStreamPlayer and c.stream is AudioStreamWAV and c.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			any_loop = true
	_ok(not any_loop, "no audio player uses a looping stream")

	# Completion latch: WON once per attempt; LOST/ERROR play nothing; Retry re-arms.
	ac._on_terminal_reached(&"LOST", {})
	ac._on_terminal_reached(&"ERROR", {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 0, "LOST/ERROR play no completion sound")
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.completion_played_this_attempt(), "WON latches completion for the attempt")
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 1, "WON plays completion exactly once")
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 1, "repeated WON does not duplicate completion")
	ac.reset_for_new_attempt()
	_ok(not ac.completion_played_this_attempt(), "Retry re-arms the completion latch")
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 2, "a later fresh WON plays completion again")

	# Cleaning burst beyond cap -> deterministic suppression, fixed node count, bounded active.
	var cap := ac.get_voice_cap(GameplayAudioController.Category.CLEANING)
	var burst := cap + 12
	for _i in range(burst):
		ac.request_cleaning()
	var cd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
	_ok(cd["requests"] == burst, "cleaning burst counted %d requests" % burst)
	_ok(cd["played"] == cap, "cleaning played == cap (%d)" % cap)
	_ok(cd["suppressed"] == burst - cap, "cleaning suppressed == overflow (%d)" % (burst - cap))
	_ok(cd["active"] <= cap and cd["peak"] == cap, "cleaning active/peak never exceed cap")
	_ok(ac.get_allocated_voice_count() == total_cap, "node count unchanged after burst (no unbounded allocation)")
	# After releasing voices a new request plays again (bounded reuse, not permanent lockout).
	ac.debug_release_all()
	_ok(ac.request_cleaning(), "a freed voice plays again after release")

	# Dispatch burst also bounded.
	var dcap := ac.get_voice_cap(GameplayAudioController.Category.DISPATCH)
	ac.debug_release_all()
	for _i in range(dcap + 6):
		ac.request_dispatch()
	var dd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.DISPATCH)
	_ok(dd["played"] == dcap and dd["suppressed"] == 6, "dispatch burst bounded to cap %d" % dcap)

	# Canonical pitch unchanged.
	var pitch_ok := true
	for c in ac.get_children():
		if c is AudioStreamPlayer and not is_equal_approx(c.pitch_scale, 1.0):
			pitch_ok = false
	_ok(pitch_ok, "all voices keep normal pitch (pitch_scale == 1.0)")

	print("  DIAG cleaning: %s" % str(cd))
	print("  DIAG dispatch: %s" % str(dd))
	ac.free()

# ------------------------------------------------ failed dispatch emits nothing ----

func _dispatch_failure_emits_nothing() -> void:
	print("[dispatch failure]")
	# An UNBOUND dispatcher.dispatch() fails and must emit assignment_dispatched zero times,
	# so a controller observing it requests no dispatch audio.
	var disp = ScrubbotDispatcher.new()
	get_root().add_child(disp)
	var ac = GameplayAudioController.new()
	get_root().add_child(ac)
	disp.assignment_dispatched.connect(ac._on_assignment_dispatched)
	var r = disp.dispatch(0, Vector2.ZERO, 6.0)
	_ok(not r.success, "unbound dispatch() returns a failure result")
	_ok(ac.get_diagnostics(GameplayAudioController.Category.DISPATCH)["requests"] == 0, "failed dispatch emits no dispatch-audio request")
	disp.free()
	ac.free()

# --------------------------------------------------------- real stack ----

func _real_stack(two_x: bool) -> void:
	var tag := "2x" if two_x else "1x"
	print("[real stack %s]" % tag)
	var h = await _make_host(0)
	if h == null:
		return
	var ac = h.get_audio_controller()
	_ok(ac != null, "%s: host exposes the audio controller" % tag)
	# Independent committed-dispatch spy on the SAME authoritative signal.
	var committed := [0]
	h.get_dispatcher().assignment_dispatched.connect(func(_o, _t, _c, _a): committed[0] += 1)
	var initial_active: int = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)

	# Volume changes must not affect gameplay truth: mute everything before the run.
	h.get_audio_settings().set_master_volume(0.0)

	if two_x:
		_ok(h.get_runtime().toggle_speed(), "%s: speed authority toggled to 2x" % tag)

	_drain(h)
	_ok(h.get_completion().is_won(), "%s: real stack reaches WON (audio never blocks gameplay)" % tag)
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "%s: board fully cleared with audio muted" % tag)

	var dd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.DISPATCH)
	var cd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
	var comp: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)
	# Dispatch audio is 1:1 with committed dispatch.
	_ok(committed[0] > 0, "%s: at least one committed dispatch occurred" % tag)
	_ok(dd["requests"] == committed[0], "%s: dispatch-audio requests == committed dispatches (1:1)" % tag)
	# Cleaning audio is one request per committed authenticated clear.
	_ok(cd["requests"] == h.get_clearing_loop().get_cleared_count(), "%s: cleaning-audio requests == committed clears" % tag)
	_ok(cd["requests"] == initial_active, "%s: cleaning requests == cleared cells (%d)" % [tag, initial_active])
	# Completion audio once on WON.
	_ok(comp["played"] == 1, "%s: completion audio played exactly once on WON" % tag)
	# Bounded under the real flow.
	var total_cap := GameplayAudioController.DISPATCH_VOICES + GameplayAudioController.CLEANING_VOICES + GameplayAudioController.COMPLETION_VOICES
	_ok(ac.get_allocated_voice_count() == total_cap, "%s: voice node count stays fixed under real flow" % tag)
	_ok(cd["peak"] <= cd["cap"] and dd["peak"] <= dd["cap"], "%s: peak active never exceeds caps" % tag)
	# Canonical pitch unchanged at this speed.
	var pitch_ok := true
	for c in ac.get_children():
		if c is AudioStreamPlayer and not is_equal_approx(c.pitch_scale, 1.0):
			pitch_ok = false
	_ok(pitch_ok, "%s: canonical one-shots keep normal pitch (no 2x pitch shift)" % tag)
	print("  DIAG %s dispatch: %s" % [tag, str(dd)])
	print("  DIAG %s cleaning: %s" % [tag, str(cd)])
	print("  DIAG %s completion: %s" % [tag, str(comp)])

	# Retry re-arms the completion latch: a fresh WON plays completion again.
	if not two_x:
		_ok(h.retry(), "%s: transaction-safe retry succeeds" % tag)
		_ok(not ac.completion_played_this_attempt(), "%s: Retry re-armed the completion latch" % tag)
		_drain(h)
		_ok(h.get_completion().is_won(), "%s: restored attempt reaches a fresh WON" % tag)
		_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 2, "%s: fresh WON plays completion again" % tag)

	_free_host(h)

# --------------------------------------------------------------- host driver ----

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
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

func _make_host(drop: int):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.qa_supply_drop_last = drop
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (drop=%d) (%s)" % [drop, host.get_build_error()])
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

# ------------------------------------------------------------- utilities ----

func _write_user_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()

func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M33 audio runtime evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
