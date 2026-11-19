extends SceneTree
## SB-TF-10 owner-review captures (GPU, windowed; never main.tscn, no save touched):
##   layout_5slot_<4|5>col_<w>x<h>.png  a real GameplayScreen with a mid-clear 32x32 board (the
##   BOARD_FLOOR shows through the CLEARED holes) and the booster row under the Supply panel,
##   at 720x1520 and 1170x2532, 4- and 5-column Supply.
## Run (rendering driver, NOT --headless):
##   godot --path <worktree> -s res://tests/tools/gameplay_layout_capture.gd -- --out <dir>

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")

const SIZES := [Vector2i(720, 1520), Vector2i(1170, 2532)]
const SIDE := 32

var _out := ""

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("gameplay layout capture: NOT_RUN (needs a rendering driver)")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	if i < 0 or i + 1 >= args.size():
		print("gameplay layout capture: usage -- --out <dir>")
		quit(1)
		return
	_out = ProjectSettings.globalize_path(args[i + 1])
	DirAccess.make_dir_recursive_absolute(_out)
	for size in SIZES:
		for cols in [4, 5]:
			var img := await _shot(size, cols)
			var p := _out.path_join("layout_5slot_%dcol_%dx%d.png" % [cols, size.x, size.y])
			img.save_png(p)
			print("wrote %s (%dx%d)" % [p, img.get_width(), img.get_height()])
	quit(0)

## One GameplayScreen frame: a 32x32 board with every cell in a diagonal band CLEARED.
func _shot(size: Vector2i, cols: int) -> Image:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var lvl = BoardDebugFixtures.make_level(SIDE, SIDE)
	var board = BoardDebugFixtures.make_board(SIDE, SIDE)
	for y in range(SIDE):
		for x in range(SIDE):
			if (x + y) % 11 < 5 or (x > 8 and x < 20 and y > 10 and y < 22):
				board.set_cell_state(y * SIDE + x, BoardState.CellState.CLEARED)
	var scr = GameplayScreen.new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(board, lvl.palette, [], BatchSupplyGenerator.generate(lvl, cols, 3, 5).player_snapshot())
	for _i in range(8):
		await process_frame
	var img: Image = sub.get_texture().get_image()
	sub.queue_free()
	await process_frame
	return img
