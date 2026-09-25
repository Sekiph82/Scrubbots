extends Control
## OpeningScreen — preload (res://scripts/app/opening_screen.gd).
##
## M42 (SB-M42-028) — dedicated opening-cinematic presentation. Plays the runtime
## Ogg Theora/Vorbis asset (never H.264/MP4) in a VideoStreamPlayer:
##   - portrait-safe, aspect-preserving: the 16:9 video is fitted INSIDE the viewport
##     (letterboxed on a solid background), centered, never stretched or cropped;
##   - deterministic lifecycle: begin() starts once; exactly one terminal signal
##     (`completed` or `failed(reason)`) is emitted per screen; finish/cleanup stops the
##     player and releases the stream; a watchdog guarantees termination even if the
##     platform never reports `finished`;
##   - isolated: it knows nothing about AppState, gameplay, save or economy.

signal completed
signal failed(reason: String)

const OPENING_OGV := "res://assets/brand/opening/scrubbots_opening_720p30.ogv"
## Authoring size of the runtime asset (used until the decoder reports its texture).
const DEFAULT_VIDEO_SIZE := Vector2(1280, 720)
## Watchdog: asset length (15.02 s) + margin. Presentation safety only.
const WATCHDOG_SEC := 20.0
const BACKGROUND := Color(0.0, 0.0, 0.0, 1.0)

var _player: VideoStreamPlayer
var _bg: ColorRect
var _started := false
var _terminal := false
var _elapsed := 0.0
var _stream_path := OPENING_OGV
var _video_size := DEFAULT_VIDEO_SIZE
## SB-M42-032 device instrumentation (presentation diagnostics only; printed once as a
## single "[OPENING_METRICS]" line for logcat/Xcode capture on real devices).
var _t_begin_ms := -1
var _t_first_frame_ms := -1
var _t_end_ms := -1
var _max_frame_gap_ms := 0.0
var _process_frames := 0
var _outcome := ""

func _init() -> void:
	name = "OpeningScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = BACKGROUND
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_player = VideoStreamPlayer.new()
	_player.name = "Video"
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.finished.connect(_on_finished)
	add_child(_player)
	resized.connect(_fit)
	set_process(false)

## Test seam: alternative stream path (e.g. a missing file to prove fail-safe).
func set_stream_path(path: String) -> void:
	if not _started:
		_stream_path = path

## Start playback once. Emits `failed` (deferred) when the stream cannot load/play.
func begin() -> bool:
	if _started:
		return false
	_started = true
	var stream: VideoStream = null
	if ResourceLoader.exists(_stream_path):
		stream = load(_stream_path) as VideoStream
	if stream == null:
		_fail_deferred("stream_unavailable")
		return false
	_t_begin_ms = Time.get_ticks_msec()
	_player.stream = stream
	_player.play()
	_elapsed = 0.0
	set_process(true)
	_fit()
	if not _player.is_playing():
		_fail_deferred("play_failed")
		return false
	return true

func _process(delta: float) -> void:
	if _terminal:
		return
	_elapsed += delta
	_process_frames += 1
	_max_frame_gap_ms = maxf(_max_frame_gap_ms, delta * 1000.0)
	var tex := _player.get_video_texture()
	if _t_first_frame_ms < 0 and tex != null and tex.get_size().x > 0:
		_t_first_frame_ms = Time.get_ticks_msec()
	if tex != null and tex.get_size().x > 0 and tex.get_size() != _video_size:
		_video_size = tex.get_size()
		_fit()
	if _elapsed >= WATCHDOG_SEC:
		_finish(true, "watchdog")

## Letterbox fit: largest rect with the video aspect inside the screen, centered.
func _fit() -> void:
	var area := size if size.x > 0 else get_viewport_rect().size
	if area.x <= 0 or area.y <= 0 or _video_size.x <= 0 or _video_size.y <= 0:
		return
	var scale_f := minf(area.x / _video_size.x, area.y / _video_size.y)
	var fitted := (_video_size * scale_f).floor()
	_player.size = fitted
	_player.position = ((area - fitted) * 0.5).floor()

func _on_finished() -> void:
	_finish(true, "finished")

func _fail_deferred(reason: String) -> void:
	(func(): _finish(false, reason)).call_deferred()

## One terminal outcome per screen; stops playback and releases the stream.
func _finish(ok: bool, reason: String) -> void:
	if _terminal:
		return
	_terminal = true
	_t_end_ms = Time.get_ticks_msec()
	_outcome = ("completed:" if ok else "failed:") + reason
	cleanup()
	print("[OPENING_METRICS] ", JSON.stringify(get_metrics()))
	if ok:
		completed.emit()
	else:
		failed.emit(reason)

## Deterministic cleanup (also called by the owner before freeing).
func cleanup() -> void:
	set_process(false)
	if _player != null:
		if _player.is_playing():
			_player.stop()
		_player.stream = null

func _exit_tree() -> void:
	cleanup()

# ---------------------------------------------------------------- diagnostics --

func is_terminal() -> bool:
	return _terminal

func is_started() -> bool:
	return _started

func get_player() -> VideoStreamPlayer:
	return _player

## Device-validation metrics (SB-M42-032). Latencies in ms; -1 = not observed.
func get_metrics() -> Dictionary:
	return {
		"outcome": _outcome,
		"startup_latency_ms": (_t_first_frame_ms - _t_begin_ms) if (_t_first_frame_ms >= 0 and _t_begin_ms >= 0) else -1,
		"playback_ms": (_t_end_ms - _t_begin_ms) if (_t_end_ms >= 0 and _t_begin_ms >= 0) else -1,
		"max_frame_gap_ms": snappedf(_max_frame_gap_ms, 0.1),
		"process_frames": _process_frames,
		"video_size": [int(_video_size.x), int(_video_size.y)],
		"video_rect": [int(_player.position.x), int(_player.position.y), int(_player.size.x), int(_player.size.y)],
		"screen": [int(size.x), int(size.y)],
		"stream_released": _player.stream == null,
		"platform": OS.get_name(),
		"display": DisplayServer.get_name(),
	}

func get_video_rect() -> Rect2:
	return Rect2(_player.position, _player.size)
