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
	var tex := _player.get_video_texture()
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
	cleanup()
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

func get_video_rect() -> Rect2:
	return Rect2(_player.position, _player.size)
