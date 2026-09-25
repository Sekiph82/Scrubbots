extends Node
## MusicController — preload this script
## (res://scripts/audio/music_controller.gd); do not rely on global class_name (AL-001).
##
## M33 V02 — reusable looping background-music controller on the `Music` bus
## (owner audio decision V02 §5). PRESENTATION-ONLY: it observes no gameplay event and
## owns no gameplay truth. It owns exactly ONE AudioStreamPlayer that plays one looping
## track continuously; it is started once when entering the tree and is stopped only at an
## explicit lifecycle boundary (stop() or leaving the tree). Dispatch, clear, terminal,
## Retry and speed changes never restart it.
##
## Volume is NOT owned here: the Music bus volume/mute comes from the canonical
## AudioSettingsService (Master and Music user settings), so Music 0 silences only music and
## SFX 0 never touches it.
##
## Track: owner-approved "Pixel Polish Parade" seamless loop (owner decision V03,
## 2026-09-25) at APPROVED_TRACK_PATH — OGG Vorbis, stereo 44.1 kHz, 137.153379 s,
## SHA-256 8c94897e...f9ae2a. Auto-discovered in _init and looped in code (import params are
## left at defaults; the imported resource itself is never mutated). If the file is ever
## missing the controller stays idle with status OWNER_MUSIC_SELECTION_REQUIRED. The Workshop
## track is a separate future selection and is NOT played here.

const MUSIC_BUS := "Music"
const APPROVED_TRACK_PATH := "res://assets/audio/music/background_loop.ogg"

const STATUS_PLAYING := &"PLAYING"
const STATUS_STOPPED := &"STOPPED"
const STATUS_OWNER_MUSIC_SELECTION_REQUIRED := &"OWNER_MUSIC_SELECTION_REQUIRED"

var _player: AudioStreamPlayer
var _track: AudioStream = null
var _start_count: int = 0
var _stopped_explicitly: bool = false
var _track_source_path: String = ""

func _init() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = MUSIC_BUS
	_player.autoplay = false
	# Fallback loop for stream types without a loop flag: a natural end restarts playback
	# (never counted as a new start; the track simply continues looping).
	_player.finished.connect(_on_finished)
	add_child(_player)
	if ResourceLoader.exists(APPROVED_TRACK_PATH):
		_track = _as_looping(load(APPROVED_TRACK_PATH))
		_track_source_path = APPROVED_TRACK_PATH if _track != null else ""

## Auto-start on gameplay entry. _ready (not _enter_tree): the child player is only inside the
## tree once the parent is ready — a play() from the parent's _enter_tree is refused by Godot.
func _ready() -> void:
	if not _stopped_explicitly:
		start()

## Re-entering the tree after a removal resumes once the child player is back in the tree.
func _enter_tree() -> void:
	if is_node_ready() and not _stopped_explicitly:
		start.call_deferred()

func _exit_tree() -> void:
	if _player.playing:
		_player.stop()

## Replace the track (test/owner-approval seam). Restarts playback only if already started.
func set_track(stream: AudioStream) -> void:
	var was_playing := _player.playing
	_track = _as_looping(stream)
	_track_source_path = stream.resource_path if stream != null else ""
	if was_playing:
		_player.stop()
	_player.stream = _track
	if was_playing and _track != null:
		_start_count += 1
		_player.play()

## Start the loop if a track exists and it is not already playing. Idempotent: calling it
## while playing never restarts the track.
func start() -> bool:
	_stopped_explicitly = false
	if _track == null:
		return false
	if _player.playing:
		return true
	_player.stream = _track
	_start_count += 1
	_player.play()
	return true

## Explicit lifecycle stop (scene/app boundary).
func stop() -> void:
	_stopped_explicitly = true
	if _player.playing:
		_player.stop()

func _on_finished() -> void:
	if not _stopped_explicitly and _track != null and is_inside_tree():
		_player.play()

## Mark the stream as looping without mutating the shared imported resource.
static func _as_looping(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null
	var s: AudioStream = stream.duplicate()
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		# loop_end is in frames; derive it from the stream length when unset.
		if w.loop_end <= 0:
			w.loop_end = int(w.get_length() * w.mix_rate)
	elif "loop" in s:
		s.set("loop", true)
	return s

# ------------------------------------------------------------- diagnostics ----

func get_status() -> StringName:
	if _track == null:
		return STATUS_OWNER_MUSIC_SELECTION_REQUIRED
	return STATUS_PLAYING if _player.playing else STATUS_STOPPED

func is_playing() -> bool:
	return _player.playing

func has_track() -> bool:
	return _track != null

## Number of times playback was (re)started from the beginning. Stays 1 across a normal
## gameplay session — the "never restarts on minor events" evidence.
func get_start_count() -> int:
	return _start_count

## Resource path of the source stream behind the current track ("" when none/generated).
func get_track_source_path() -> String:
	return _track_source_path

func get_track() -> AudioStream:
	return _track

func get_player() -> AudioStreamPlayer:
	return _player

func is_looping() -> bool:
	if _track == null:
		return false
	if _track is AudioStreamWAV:
		return (_track as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
	return "loop" in _track and bool(_track.get("loop"))
