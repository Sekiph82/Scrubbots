extends Control
## WinOverlay — preload (res://scripts/ui/win_overlay.gd).
##
## SB-PHONE-2026-11-12-E (owner 2026-11-12: "no popup or button in between") — the level-complete
## animation over the finished board, then Home. A light scrim keeps the board visible; "LEVEL
## COMPLETE" over the active robot's existing win animation: Scrubby plays the keyed WIN Flow
## video once (SB-VIDEO-001, assets/ui/final/popups/videos/PROVENANCE.md), another robot (or a
## video that fails to start) its approved victory pose with CharacterMotion `win` for HOLD_S;
## the app feel adapter adds the WIN confetti (one-shot `feel_key`). Reduced Effects: the still /
## pose, no decoder, for REDUCED_HOLD_S. Then `finished` fires once and the app root goes Home.
## Taps are consumed (the finished board takes no input) but do not skip; only Back skips
## (main.gd handle_back -> close()). Presentation only: rewards were committed by the host's
## terminal before this exists; nothing here reads or writes game state.

signal finished

const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const CHROMA_KEY := preload("res://scripts/ui/feel/chroma_key_magenta.gdshader")
const SCRUBBY_ID := "scrubby"
const VIDEO := "res://assets/ui/final/popups/videos/result_scrubby_win.ogv"
const STILL := "res://assets/ui/final/popups/videos/result_scrubby_win_still.png"
const POSE := "res://assets/ui/final/popups/victory/victory_scrubby_pose.png"
const HOLD_S := 2.0
const REDUCED_HOLD_S := 1.0
const ROBOT_WIDTH := 0.62   ## of the overlay width

var reduced := false
var robot_id := ""
var feel = null
var feel_key := ""
## Injectable for tests: null = the pose / still path (no decoder).
var video: VideoStream = load(VIDEO)
var _robot: TextureRect
var _player: VideoStreamPlayer = null
var _closed := false

func _ready() -> void:
	name = "WinOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.35)
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
	label.name = "TitleLabel"
	label.text = UiText.t("RESULTS_WON")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiTokens.FONT_HERO)
	col.add_child(label)
	var scrubby := robot_id.is_empty() or robot_id == SCRUBBY_ID
	var tex := load(STILL if scrubby else RobotRoster.asset(robot_id, "victory_pose")) as Texture2D
	if tex == null:
		tex = load(POSE)
	_robot = TextureRect.new()
	_robot.name = "Robot"
	_robot.texture = tex
	_robot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_robot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_robot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := get_viewport_rect().size.x * ROBOT_WIDTH
	_robot.custom_minimum_size = Vector2(w, w * tex.get_height() / tex.get_width())
	_robot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_robot)
	if feel != null and not feel_key.is_empty():
		feel.play("WIN", _robot, feel_key)
	if reduced or not scrubby or not _start_video():
		CharacterMotion.play(_robot, "win", reduced)
		create_tween().tween_interval(REDUCED_HOLD_S if reduced else HOLD_S).finished.connect(close)

## One keyed VideoStreamPlayer over the still (hidden while it plays), as in LevelIntroOverlay.
func _start_video() -> bool:
	if video == null:
		return false
	_player = VideoStreamPlayer.new()
	_player.name = "WinVideo"
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
	accept_event()

## End the animation once: free the decoder and emit `finished` (the app root goes Home, which
## releases the gameplay host and this overlay with it).
func close() -> void:
	if _closed:
		return
	_closed = true
	_free_player()
	CharacterMotion.stop(_robot)
	finished.emit()

func get_video_player() -> VideoStreamPlayer:
	return _player

func is_closed() -> bool:
	return _closed
