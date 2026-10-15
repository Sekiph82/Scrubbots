extends SceneTree
## M50-BOARD owner-review capture (evidence only, never UI). Renders through the REAL app root
## (main.tscn, throw-away save): production L7 pigeon gameplay with per-cell board symbols, the
## same L7 with the board magnifier held, and a 59x59 16-colour board (GameplayScreen) with and
## without the magnifier. Needs a rendering driver (run WITHOUT --headless); small JPGs into <out_dir>:
##   godot --path . -s res://tests/tools/m50_board_symbol_capture.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

const SIZE := Vector2i(1080, 2160)
var _out := "user://"
var _save := ""

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0].trim_suffix("/") + "/"
	MainScript.boot_opening_override = 0
	_save = "user://m50b_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	var sub := _sub(SIZE)
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(10)
	root.get_app_state().progression.debug_set_current_level(7)
	root.play_current_frontier()
	await _frames(12)
	var host = root.get_gameplay_host()
	if host != null:
		host.get_runtime().set_process(false)
		var scr = host.get_screen()
		_shot(sub, "m50b_l7_board_symbols")
		_crop(sub, scr.get_board_rect(), "m50b_l7_board_crop")
		_hold(sub, scr.cell_center_to_global(14, 12), true)
		await _frames(4)
		_shot(sub, "m50b_l7_magnifier")
		_hold(sub, scr.cell_center_to_global(14, 12), false)
	root.free()
	sub.free()
	# 59x59 = 3,481 cells, all 16 canonical colours (no shipped level is this dense yet).
	var pal_json = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	var pal := PackedStringArray()
	for c in pal_json["colors"]:
		pal.append(String(c["hex"]))
	var cells := PackedInt32Array()
	cells.resize(59 * 59)
	for y in range(59):
		for x in range(59):
			cells[y * 59 + x] = int(floor(sqrt(float((x - 29) * (x - 29) + (y - 29) * (y - 29))) / 2.2) + x / 9) % 16
	var board := BoardState.from_level_data(LevelData.new(1, "m50b_59", "m50b", "TEST", 59, 59, pal, cells))
	for i in range(0, 59 * 59, 7):
		board.set_cell_state(i, BoardState.CellState.CLEARED)
	var s2 := _sub(SIZE)
	var scr2 = GameplayScreen.new()
	scr2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s2.add_child(scr2)
	var supply: Array = []
	for c in range(5):
		var pv: Array = []
		for r in range(3):
			pv.append({"color_id": (c * 3 + r) % 16, "robot_count": 12 + c * 7 + r})
		supply.append({"front": pv[0], "preview": pv, "remaining": 9})
	scr2.configure(board, pal, [], supply)
	await _frames(8)
	_shot(s2, "m50b_59x59_board_symbols")
	_crop(s2, scr2.get_board_rect(), "m50b_59x59_board_crop")
	_hold(s2, scr2.cell_center_to_global(30, 30), true)
	await _frames(4)
	_shot(s2, "m50b_59x59_magnifier")
	_hold(s2, scr2.cell_center_to_global(30, 30), false)
	s2.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))
	quit(0)

func _hold(sub: SubViewport, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	e.global_position = at
	sub.push_input(e)

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _shot(sub: SubViewport, stem: String, scale: float = 0.5) -> void:
	var img := sub.get_texture().get_image()
	if scale != 1.0:
		img.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	_save_jpg(img, stem)

## Full-resolution crop of the board (symbols are judged at real pixel size).
func _crop(sub: SubViewport, r: Rect2, stem: String) -> void:
	var img := sub.get_texture().get_image().get_region(Rect2i(r.position.floor(), r.size.ceil()))
	_save_jpg(img, stem)

func _save_jpg(img: Image, stem: String) -> void:
	var path := _out + stem + ".jpg"
	img.save_jpg(path, 0.85)
	print("saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])

## Frames plus real time (transitions are time-based), then a finished draw before readback.
func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
