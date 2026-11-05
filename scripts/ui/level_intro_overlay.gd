extends Control
## LevelIntroOverlay — preload (res://scripts/ui/level_intro_overlay.gd).
##
## SB-VIDEO-005 — the Level Intro: a dim scrim with "LEVEL N" over the owner's keyed Scrubby
## "ready" Flow video (assets/ui/final/gameplay/videos/PROVENANCE.md), centred on the screen.
## The video plays once, then the overlay fades out (FADE_S) and frees itself and its decoder.
## Any tap skips at once (fade) and is consumed here, so it never reaches the board / supply;
## the overlay is the only thing blocking gameplay input and only while it exists.
## Reduced Effects, or a video that fails to start: no decoder, the keyed still with the
## CharacterMotion `ready` bounce for REDUCED_HOLD_S, then the same fade.
## Presentation only: no gameplay, timer, economy or save state is read or written.

const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const CHROMA_KEY := preload("res://scripts/ui/feel/chroma_key_magenta.gdshader")
const VIDEO := "res://assets/ui/final/gameplay/videos/level_start_scrubby.ogv"
const STILL := "res://assets/ui/final/gameplay/videos/level_start_scrubby_still.png"
const REDUCED_HOLD_S := 0.8
const FADE_S := 0.25
const ROBOT_WIDTH := 0.62   ## of the overlay width

var level := 1
var reduced := false
## Injectable for tests: null = the Reduced path (still + bounce, no decoder).
var video: VideoStream = load(VIDEO)
var _robot: TextureRect
var _player: VideoStreamPlayer = null
var _closing := false

func _ready() -> void:
	name = "LevelIntro"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UiTokens.SPACE_LG)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var label := Label.new()
	label.name = "LevelLabel"
	label.text = UiText.t("LEVEL_INTRO", [level])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiTokens.FONT_HERO)
	col.add_child(label)
	var still := load(STILL) as Texture2D
	_robot = TextureRect.new()
	_robot.name = "Robot"
	_robot.texture = still
	_robot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_robot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_robot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := get_viewport_rect().size.x * ROBOT_WIDTH
	_robot.custom_minimum_size = Vector2(w, w * still.get_height() / still.get_width())
	_robot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_robot)
	if reduced or not _start_video():
		CharacterMotion.play(_robot, "ready", false)
		create_tween().tween_interval(REDUCED_HOLD_S).finished.connect(close)

## One keyed VideoStreamPlayer over the still (hidden while it plays), as in ResultsScreen.
func _start_video() -> bool:
	if video == null:
		return false
	_player = VideoStreamPlayer.new()
	_player.name = "IntroVideo"
	_player.expand = true
	_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.material = ShaderMaterial.new()
	(_player.material as ShaderMaterial).shader = CHROMA_KEY
	_player.stream = video
	_robot.add_child(_player)
	_player.finished.connect(close, CONNECT_DEFERRED)
	_player.play()
	if not _player.is_playing() or _player.get_stream_length() <= 0.0:
		_free_player()
		return false
	_robot.self_modulate.a = 0.0
	return true

func _free_player() -> void:
	_robot.self_modulate.a = 1.0
	if _player == null:
		return
	_player.stop()
	_robot.remove_child(_player)
	_player.queue_free()
	_player = null

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()
	accept_event()

## Free the decoder (the keyed still holds: frame 0 ~ last frame), fade out, free the overlay.
func close() -> void:
	if _closing:
		return
	_closing = true
	_free_player()
	CharacterMotion.stop(_robot)
	create_tween().tween_property(self, "modulate:a", 0.0, FADE_S).finished.connect(queue_free)

func get_video_player() -> VideoStreamPlayer:
	return _player

func is_closing() -> bool:
	return _closing
