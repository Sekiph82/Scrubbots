extends SceneTree
## M33-C001 V02 — audio runtime evidence (owner audio decision V02, 2026-09-24). Proves the
## presentation-only audio wiring without relying on human audibility (owner F6 re-listening
## owns final mix approval):
##   - Master/Music/SFX buses exist; Music/SFX route through Master;
##   - AudioSettingsService volumes map to bus mute/volume independently (M41 toggles are
##     covered by tests/m41_settings.gd);
##   - NO sound on assignment_dispatched (no observer, no dispatch pool, no dispatch voice);
##   - cleaning is backed by dispatch.wav on the LIVE player nodes (cleaning.wav unreferenced);
##   - every cleaning voice is hard-stopped at CLEANING_MAX_SEC (<= the M31/M32 visual cue
##     lifetimes) with a fade before the cut; the clear is never delayed;
##   - lower cleaning concurrency (cap 3) with deterministic suppression, fixed node count;
##   - completion once per WON attempt; LOST/ERROR silent; Retry stops stale cleaning AND
##     completion voices and re-arms completion;
##   - no movement stream/player/loop among SFX;
##   - V03 approved gameplay music: exact asset identity (SHA-256, OGG Vorbis stereo 44.1 kHz,
##     137.153379 s), auto-discovered, looping, PLAYING on normal gameplay entry;
##   - MusicController: Music bus, looping, idempotent start, OWNER_MUSIC_SELECTION_REQUIRED
##     only without a track, start count stays 1 across real gameplay + 2x + Retry, stopped at
##     scene exit;
##   - real production stack at 1x AND 2x with interleaved realtime voice ageing (clutter
##     stress): bounded active voices, no voice older than the bound.
##
## Expected/completed case ledger (AL-091): a sub-test that aborts on a SCRIPT ERROR never
## reaches _complete() and fails the run even if no _ok() failed.
##
## Run: godot --headless --path . -s res://tests/m33_audio_runtime.gd
## Exits 0 on success, 1 on any failure.

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const GameplayAudioController = preload("res://scripts/audio/gameplay_audio_controller.gd")
const MusicController = preload("res://scripts/audio/music_controller.gd")
const CleaningEffectsController = preload("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
const ScrubbotRetireEchoController = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const DISPATCH_WAV := "res://assets/audio/sfx/dispatch.wav"
const CLEANING_WAV := "res://assets/audio/sfx/cleaning.wav"
const COMPLETION_WAV := "res://assets/audio/sfx/completion.wav"

const MUSIC_PATH := "res://assets/audio/music/background_loop.ogg"
const MUSIC_SHA256 := "8c94897ea022924bb32c1e8384fd0b73ea21863f522c4d1dd682ca773ef9ae2a"
const MUSIC_BYTES := 2686777
const MUSIC_SECONDS := 137.153379

const DT := 1.0
const FRAME := 1.0 / 60.0
const MAX_TICKS := 80000

const EXPECTED_CASES := [
	"bus_layout", "settings_service", "bus_routing_independence", "controller_unit",
	"cleaning_tail_bound", "retry_cleanup_unit", "approved_music_asset", "music_controller_unit",
	"real_stack_1x", "real_stack_2x",
]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_bus_layout()
	_settings_service()
	_bus_routing_independence()
	await _controller_unit()
	await _cleaning_tail_bound()
	await _retry_cleanup_unit()
	_approved_music_asset()
	await _music_controller_unit()
	await _real_stack(false)
	await _real_stack(true)
	_done()

# ------------------------------------------------------------- bus layout ----

func _bus_layout() -> void:
	print("[bus layout]")
	var m := AudioServer.get_bus_index(AudioSettingsService.BUS_MASTER)
	var mu := AudioServer.get_bus_index(AudioSettingsService.BUS_MUSIC)
	var s := AudioServer.get_bus_index(AudioSettingsService.BUS_SFX)
	_ok(m >= 0 and mu >= 0 and s >= 0, "Master/Music/SFX buses exist")
	_ok(mu >= 0 and String(AudioServer.get_bus_send(mu)) == AudioSettingsService.BUS_MASTER, "Music routes to Master")
	_ok(s >= 0 and String(AudioServer.get_bus_send(s)) == AudioSettingsService.BUS_MASTER, "SFX routes to Master")
	_complete("bus_layout")

# ------------------------------------------------------- settings service ----

func _settings_service() -> void:
	print("[settings service]")
	var svc = AudioSettingsService.new("user://m33_v02_unused.cfg")
	svc.set_master_volume(0.5)
	svc.set_music_volume(0.25)
	svc.set_sfx_volume(0.75)
	_ok(is_equal_approx(svc.get_master_volume(), 0.5) and is_equal_approx(svc.get_music_volume(), 0.25) and is_equal_approx(svc.get_sfx_volume(), 0.75), "independent set/get")
	var sfx := AudioServer.get_bus_index("SFX")
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(sfx), linear_to_db(0.75)) and not AudioServer.is_bus_mute(sfx), "sfx bus dB == linear_to_db(0.75), unmuted")
	svc.set_sfx_volume(0.0)
	_ok(AudioServer.is_bus_mute(sfx), "sfx 0.0 mutes the bus")
	svc.set_sfx_volume(0.6)
	_ok(not AudioServer.is_bus_mute(sfx), "sfx >0 unmutes the bus")
	svc.set_master_volume(NAN)
	_ok(is_equal_approx(svc.get_master_volume(), 1.0), "NaN volume falls back to neutral default")
	svc.set_master_volume(2.0)
	_ok(is_equal_approx(svc.get_master_volume(), 1.0), "over-range clamps")
	_neutral()
	_complete("settings_service")

## Music 0 silences only Music; SFX 0 only SFX; Master 0 silences Master (all audio routes
## through it). Asserted on the actual AudioServer buses.
func _bus_routing_independence() -> void:
	print("[bus routing independence]")
	var svc = AudioSettingsService.new("user://m33_v02_unused.cfg")
	var m := AudioServer.get_bus_index("Master")
	var mu := AudioServer.get_bus_index("Music")
	var s := AudioServer.get_bus_index("SFX")
	svc.set_music_volume(0.0)
	_ok(AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(s) and not AudioServer.is_bus_mute(m), "Music 0 mutes only Music")
	svc.set_music_volume(1.0)
	svc.set_sfx_volume(0.0)
	_ok(AudioServer.is_bus_mute(s) and not AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(m), "SFX 0 mutes only SFX")
	svc.set_sfx_volume(1.0)
	svc.set_master_volume(0.0)
	_ok(AudioServer.is_bus_mute(m), "Master 0 mutes Master")
	_ok(String(AudioServer.get_bus_send(mu)) == "Master" and String(AudioServer.get_bus_send(s)) == "Master", "Music and SFX both feed Master (Master 0 silences all)")
	svc.set_master_volume(1.0)
	_neutral()
	_complete("bus_routing_independence")

# ----------------------------------------------------- controller unit ----

func _controller_unit() -> void:
	print("[controller unit]")
	var ac = GameplayAudioController.new()
	get_root().add_child(ac)
	await process_frame

	_ok(not ac.has_method("_on_assignment_dispatched") and not ac.has_method("request_dispatch"), "controller has no dispatch observer/seam")
	_ok(not ("DISPATCH" in GameplayAudioController.Category), "no DISPATCH voice category exists")
	var paths: Array = ac.get_stream_paths()
	_ok(paths == [DISPATCH_WAV, COMPLETION_WAV], "streams == [dispatch.wav (cleaning), completion.wav]")
	_ok(not paths.has(CLEANING_WAV), "old long cleaning.wav is not referenced")
	_ok(ac.get_category_stream_path(GameplayAudioController.Category.CLEANING) == DISPATCH_WAV, "LIVE cleaning players load dispatch.wav")
	_ok(ac.get_category_stream_path(GameplayAudioController.Category.COMPLETION) == COMPLETION_WAV, "LIVE completion player loads completion.wav")
	var players := 0
	var bus_ok := true
	var loop := false
	var movement := false
	for c in ac.get_children():
		if c is AudioStreamPlayer:
			players += 1
			bus_ok = bus_ok and c.bus == "SFX"
			if c.stream is AudioStreamWAV and c.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
				loop = true
			if c.stream != null and c.stream.resource_path.to_lower().find("movement") != -1:
				movement = true
	var total_cap := GameplayAudioController.CLEANING_VOICES + GameplayAudioController.COMPLETION_VOICES
	_ok(players == total_cap and ac.get_allocated_voice_count() == total_cap, "exactly %d SFX players (cleaning %d + completion 1)" % [total_cap, GameplayAudioController.CLEANING_VOICES])
	_ok(GameplayAudioController.CLEANING_VOICES < 8, "cleaning cap lowered from V01's 8 (now %d)" % GameplayAudioController.CLEANING_VOICES)
	_ok(bus_ok, "every SFX player routes to the SFX bus")
	_ok(not loop and not movement, "no looping / movement SFX stream")

	# Completion latch.
	ac._on_terminal_reached(&"LOST", {})
	ac._on_terminal_reached(&"ERROR", {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 0, "LOST/ERROR play no completion")
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 1, "WON plays completion exactly once per attempt")

	# Burst beyond the cap -> deterministic suppression, fixed nodes.
	var cap: int = ac.get_voice_cap(GameplayAudioController.Category.CLEANING)
	for _i in range(cap + 10):
		ac.request_cleaning()
	var cd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
	_ok(cd["played"] == cap and cd["suppressed"] == 10 and cd["peak"] == cap, "burst: played == cap, overflow suppressed")
	_ok(ac.get_allocated_voice_count() == total_cap, "node count unchanged after burst")
	var pitch_ok := true
	for c in ac.get_children():
		if c is AudioStreamPlayer and not is_equal_approx(c.pitch_scale, 1.0):
			pitch_ok = false
	_ok(pitch_ok, "all voices keep pitch_scale 1.0")
	ac.free()
	_complete("controller_unit")

# --------------------------------------------------- cleaning tail bound ----

func _cleaning_tail_bound() -> void:
	print("[cleaning tail bound]")
	var bound := GameplayAudioController.CLEANING_MAX_SEC
	_ok(bound > 0.0 and bound <= ScrubbotRetireEchoController.LIFETIME and bound <= CleaningEffectsController.NORMAL_LIFETIME, "cleaning bound %.2fs <= retire echo %.2fs and cleaning FX %.2fs" % [bound, ScrubbotRetireEchoController.LIFETIME, CleaningEffectsController.NORMAL_LIFETIME])
	var src: AudioStream = load(DISPATCH_WAV)
	_ok(src.get_length() > bound, "source dispatch.wav (%.2fs) is longer than the bound, so the cut is load-bearing" % src.get_length())
	var ac = GameplayAudioController.new()
	get_root().add_child(ac)
	await process_frame
	ac.set_process(false)   # deterministic time: drive advance_voices() manually.
	var p: AudioStreamPlayer = _cleaning_player(ac)
	_ok(ac.request_cleaning(), "cleaning voice starts")
	_ok(p.playing, "cleaning player is actually playing after the request")
	var base_db: float = p.volume_db
	var t := 0.0
	var faded := false
	var max_age := 0.0
	var alive_at_bound_minus := false
	while t < bound + 0.2:
		ac.advance_voices(0.01)
		t += 0.01
		max_age = maxf(max_age, ac.get_max_voice_age(GameplayAudioController.Category.CLEANING))
		if p.playing and p.volume_db < base_db - 1.0:
			faded = true
		if t < bound - 0.02 and ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 1:
			alive_at_bound_minus = true
	_ok(alive_at_bound_minus, "voice is audible before the bound (not cut instantly)")
	_ok(faded, "voice fades before the cut (no click)")
	_ok(not p.playing, "player is STOPPED after the bound (no tail)")
	_ok(ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 0, "voice released after the bound")
	_ok(max_age <= bound + 0.0001, "no voice ever aged past the bound (max %.3f)" % max_age)
	_ok(ac.get_diagnostics(GameplayAudioController.Category.CLEANING)["cut"] == 1, "cut counter == 1")
	_ok(is_equal_approx(p.volume_db, base_db), "volume restored for voice reuse")
	# Non-finite / negative delta is ignored (voice still alive, bound still counts real time).
	ac.request_cleaning()
	ac.advance_voices(NAN)
	ac.advance_voices(INF)
	ac.advance_voices(-1.0)
	_ok(ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 1 and ac.get_max_voice_age(GameplayAudioController.Category.CLEANING) == 0.0, "NaN/INF/negative delta ignored")
	# Completion is NOT bounded (natural one-shot end).
	_ok(ac.get_voice_max_sec(GameplayAudioController.Category.COMPLETION) <= 0.0, "completion voice has no tail cut")
	ac.free()
	_complete("cleaning_tail_bound")

func _retry_cleanup_unit() -> void:
	print("[retry cleanup unit]")
	var ac = GameplayAudioController.new()
	get_root().add_child(ac)
	await process_frame
	ac.set_process(false)
	for _i in range(3):
		ac.request_cleaning()
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 3 and ac.get_active_voice_count(GameplayAudioController.Category.COMPLETION) == 1, "stale cleaning + completion voices active before Retry")
	ac.reset_for_new_attempt()
	var any_playing := false
	for c in ac.get_children():
		if c is AudioStreamPlayer and c.playing:
			any_playing = true
	_ok(not any_playing, "Retry stops every SFX player (no stale tail)")
	_ok(ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 0 and ac.get_active_voice_count(GameplayAudioController.Category.COMPLETION) == 0, "Retry releases all voices")
	_ok(not ac.completion_played_this_attempt(), "Retry re-arms completion")
	ac._on_terminal_reached(GameplayAudioController.WON, {})
	_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 2, "fresh WON after Retry plays completion again")
	ac.free()
	_complete("retry_cleanup_unit")

# ------------------------------------------------------ music controller ----

## V03: the owner-approved Pixel Polish Parade loop, byte-exact (no transcode/replace).
func _approved_music_asset() -> void:
	print("[approved music asset]")
	var path := MusicController.APPROVED_TRACK_PATH
	_ok(path == MUSIC_PATH, "controller track path is %s" % MUSIC_PATH)
	_ok(FileAccess.file_exists(path), "approved OGG exists")
	_ok(FileAccess.get_sha256(path) == MUSIC_SHA256, "SHA-256 == approved %s" % MUSIC_SHA256)
	var bytes := FileAccess.get_file_as_bytes(path)
	_ok(bytes.size() == MUSIC_BYTES, "file size %d bytes" % bytes.size())
	# Vorbis identification header: channels / sample rate; last Ogg page granule = frames.
	var id := _find(bytes, PackedByteArray([0x01, 0x76, 0x6f, 0x72, 0x62, 0x69, 0x73]), 0)
	_ok(id >= 0, "Ogg Vorbis identification header present")
	if id >= 0:
		_ok(bytes[id + 11] == 2, "2 channels (stereo)")
		_ok(bytes.decode_u32(id + 12) == 44100, "44.1 kHz")
	var last := _rfind_oggs(bytes)
	var frames := bytes.decode_s64(last + 6) if last >= 0 else -1
	_ok(frames == 6048464 and absf(float(frames) / 44100.0 - MUSIC_SECONDS) < 0.000001, "container duration %.6f s == 137.153379 s" % (float(frames) / 44100.0))
	var s = load(path)
	_ok(s is AudioStreamOggVorbis, "Godot imports it as AudioStreamOggVorbis")
	_ok(s != null and absf(s.get_length() - MUSIC_SECONDS) < 0.01, "Godot stream length %.6f within 10 ms" % (s.get_length() if s else -1.0))
	var extra: Array = []
	for f in DirAccess.get_files_at("res://assets/audio/music"):
		if not (f in [".gitkeep", "background_loop.ogg", "background_loop.ogg.import"]):
			extra.append(f)
	_ok(extra.is_empty(), "no other/replacement music file in assets/audio/music %s" % str(extra))
	_complete("approved_music_asset")

func _music_controller_unit() -> void:
	print("[music controller unit]")
	var mc = MusicController.new()
	_ok(mc.has_track() and mc.get_track_source_path() == MUSIC_PATH, "controller auto-discovers the approved OGG")
	_ok(mc.get_track() is AudioStreamOggVorbis and mc.is_looping() and mc.get_track().loop == true, "controller OGG track loop == true")
	_ok((load(MUSIC_PATH) as AudioStreamOggVorbis).loop == false, "shared imported resource not mutated (loop set on a duplicate)")
	get_root().add_child(mc)
	await process_frame
	_ok(mc.get_status() == MusicController.STATUS_PLAYING and mc.get_start_count() == 1, "entering the tree starts the approved loop once (PLAYING)")
	_ok(mc.get_player().bus == "Music", "music player routes to the Music bus")
	mc.set_track(null)
	_ok(mc.get_status() == MusicController.STATUS_OWNER_MUSIC_SELECTION_REQUIRED and not mc.is_playing(), "no track -> OWNER_MUSIC_SELECTION_REQUIRED, silent")
	_ok(not mc.start() and not mc.is_playing(), "no track -> start() refuses, nothing plays")
	var w := _test_loop_stream()
	mc.set_track(w)
	_ok(w.loop_mode == AudioStreamWAV.LOOP_DISABLED, "the injected source resource is not mutated")
	_ok(mc.is_looping(), "controller track is looping")
	_ok(mc.start() and mc.is_playing(), "start() plays the loop")
	var c0: int = mc.get_start_count()
	mc.start()
	mc.start()
	_ok(mc.get_start_count() == c0, "repeated start() never restarts the track")
	_ok(mc.get_status() == MusicController.STATUS_PLAYING, "status PLAYING")
	mc.stop()
	_ok(not mc.is_playing() and mc.get_status() == MusicController.STATUS_STOPPED, "explicit stop() stops at the lifecycle boundary")
	mc.start()
	_ok(mc.is_playing(), "restart after an explicit stop works")
	get_root().remove_child(mc)
	_ok(not mc.is_playing(), "leaving the tree stops the music")
	mc.free()
	_complete("music_controller_unit")

# --------------------------------------------------------- real stack ----

func _real_stack(two_x: bool) -> void:
	var tag := "2x" if two_x else "1x"
	print("[real stack %s]" % tag)
	var h = await _make_host(0)
	if h == null:
		return
	var ac = h.get_audio_controller()
	var mc = h.get_music_controller()
	ac.set_process(false)   # ageing is interleaved below at realistic frame time.
	_ok(mc != null and mc.get_player().bus == "Music", "%s: host owns a Music-bus MusicController" % tag)
	_ok(mc.has_track() and mc.get_track_source_path() == MUSIC_PATH and mc.is_looping(), "%s: production host music = approved looping OGG" % tag)
	_ok(mc.get_status() == MusicController.STATUS_PLAYING and mc.get_start_count() == 1, "%s: music PLAYING on normal gameplay entry, started once" % tag)

	# No audio observer on assignment_dispatched.
	var disp = h.get_dispatcher()
	var audio_on_dispatch := 0
	for conn in disp.assignment_dispatched.get_connections():
		var obj = (conn["callable"] as Callable).get_object()
		if obj == ac or obj == mc or obj == h.get_haptics_controller():
			audio_on_dispatch += 1
	_ok(audio_on_dispatch == 0, "%s: no audio/haptics observer on assignment_dispatched" % tag)
	var committed := [0]
	disp.assignment_dispatched.connect(func(_o, _t, _c, _a): committed[0] += 1)
	var initial_active: int = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	h.get_audio_settings().set_master_volume(0.0)
	if two_x:
		_ok(h.get_runtime().toggle_speed(), "%s: speed toggled to 2x" % tag)

	var stats := _drain(h, ac)
	_ok(h.get_completion().is_won(), "%s: real stack reaches WON" % tag)
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "%s: board fully cleared" % tag)
	var cd: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
	var comp: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)
	_ok(committed[0] > 0, "%s: committed dispatches occurred (%d)" % [tag, committed[0]])
	_ok(cd["requests"] == h.get_clearing_loop().get_cleared_count() and cd["requests"] == initial_active, "%s: one cleaning request per committed clear (%d)" % [tag, initial_active])
	_ok(cd["requests"] + comp["requests"] == initial_active + 1, "%s: total SFX requests == clears + 1 WON (no dispatch sound)" % tag)
	_ok(comp["played"] == 1, "%s: completion once on WON" % tag)
	_ok(stats["max_active"] <= GameplayAudioController.CLEANING_VOICES, "%s: clutter stress active <= cap (max %d)" % [tag, stats["max_active"]])
	_ok(stats["max_age"] <= GameplayAudioController.CLEANING_MAX_SEC + 0.0001, "%s: no cleaning voice outlived the bound (max %.3f)" % [tag, stats["max_age"]])
	_ok(cd["cut"] > 0, "%s: the bound actually cut voices in the real flow (%d)" % [tag, cd["cut"]])
	_ok(ac.get_allocated_voice_count() == GameplayAudioController.CLEANING_VOICES + GameplayAudioController.COMPLETION_VOICES, "%s: fixed SFX node count" % tag)
	_ok(mc.is_playing() and mc.get_start_count() == 1, "%s: music kept looping through the whole run, never restarted" % tag)
	print("  DIAG %s cleaning: %s stress: %s" % [tag, str(cd), str(stats)])

	if not two_x:
		_ok(h.retry(), "%s: transaction-safe retry succeeds" % tag)
		_ok(ac.get_active_voice_count(GameplayAudioController.Category.CLEANING) == 0 and ac.get_active_voice_count(GameplayAudioController.Category.COMPLETION) == 0, "%s: Retry left no stale cleaning/completion voice" % tag)
		_ok(mc.is_playing() and mc.get_start_count() == 1, "%s: Retry does not restart the music" % tag)
		_drain(h, ac)
		_ok(h.get_completion().is_won(), "%s: fresh attempt WON" % tag)
		_ok(ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)["played"] == 2, "%s: fresh WON plays completion again" % tag)
		_ok(mc.get_start_count() == 1, "%s: music still never restarted" % tag)
	var sub = h.get_meta("sub")
	get_root().remove_child(sub)   # explicit scene lifecycle boundary
	_ok(is_instance_valid(mc) and not mc.is_playing(), "%s: scene exit stops the music" % tag)
	sub.free()
	_neutral()
	_complete("real_stack_2x" if two_x else "real_stack_1x")

# --------------------------------------------------------------- host driver ----

## Drain with realistic presentation time: each gameplay tick also ages voices by one 60 fps
## frame (clutter stress). Returns the max simultaneous active cleaning voices / max age.
func _drain(h, ac) -> Dictionary:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	var max_active := 0
	var max_age := 0.0
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		max_active = maxi(max_active, ac.get_active_voice_count(GameplayAudioController.Category.CLEANING))
		max_age = maxf(max_age, ac.get_max_voice_age(GameplayAudioController.Category.CLEANING))
		ac.advance_voices(FRAME)
		max_age = maxf(max_age, ac.get_max_voice_age(GameplayAudioController.Category.CLEANING))
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(DT)
			if h.get_completion().is_terminal():
				break
			runtime.tick(DT)
			break
	return {"max_active": max_active, "max_age": max_age}

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
		get_root().remove_child(sub)
		sub.free()

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

# ------------------------------------------------------------- utilities ----

func _cleaning_player(ac) -> AudioStreamPlayer:
	for c in ac.get_children():
		if c is AudioStreamPlayer and c.stream != null and c.stream.resource_path == DISPATCH_WAV:
			return c
	return null

func _find(hay: PackedByteArray, needle: PackedByteArray, from: int) -> int:
	for i in range(from, hay.size() - needle.size()):
		var hit := true
		for k in range(needle.size()):
			if hay[i + k] != needle[k]:
				hit = false
				break
		if hit:
			return i
	return -1

func _rfind_oggs(b: PackedByteArray) -> int:
	for i in range(b.size() - 4, -1, -1):
		if b[i] == 0x4f and b[i + 1] == 0x67 and b[i + 2] == 0x67 and b[i + 3] == 0x53:
			return i
	return -1

## A 1 s silent 16-bit test stream (NOT a music asset) — proves loop/lifecycle wiring only.
func _test_loop_stream() -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050
	var d := PackedByteArray()
	d.resize(44100)
	w.data = d
	return w

## Neutral buses for the next case (no file I/O).
func _neutral() -> void:
	var n = AudioSettingsService.new("user://m33_v02_unused.cfg")
	n.apply_all()

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M33 V03 cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M33 audio runtime evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
