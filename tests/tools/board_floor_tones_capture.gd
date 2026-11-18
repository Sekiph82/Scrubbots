extends SceneTree
## SB-TF-04 owner-review captures (GPU, windowed; never main.tscn, no save touched):
##   floor_tones_side_by_side.png  the same mid-clear 32x32 board in a real GameplayScreen at
##                                 1080x2400, once per BoardPresentation.BOARD_FLOOR_TONES entry,
##                                 four panels left to right labelled "TONE i #hex";
##   layout_<cap>slot_<cols>col_1080x2400.png  the six shells with the selected tone.
## The owner picks a tone; selecting it = changing BoardPresentation.BOARD_FLOOR_TONE.
## Run (rendering driver, NOT --headless):
##   godot --path <worktree> -s res://tests/tools/board_floor_tones_capture.gd [-- --out <dir>]

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")

const SIZE := Vector2i(1080, 2400)
const SIDE := 32
const PANEL_W := 540
const LABEL_H := 72

var _out := "res://factory/jobs/184-tf04-gameplay-layout/evidence"

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("board floor tones capture: NOT_RUN (needs a rendering driver)")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	if i >= 0 and i + 1 < args.size():
		_out = args[i + 1]
	_out = ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(_out)
	var panels: Array = []
	for tone in BoardPresentation.BOARD_FLOOR_TONES:
		panels.append(await _shot(4, 5, tone))
	_save(await _sheet(panels), "floor_tones_side_by_side.png")
	var tone0: Color = BoardPresentation.BOARD_FLOOR_TONES[BoardPresentation.BOARD_FLOOR_TONE]
	for cap in [5, 6]:
		for cols in [3, 4, 5]:
			_save(await _shot(cols, cap, tone0), "layout_%dslot_%dcol_%dx%d.png" % [cap, cols, SIZE.x, SIZE.y])
	quit(0)

## One GameplayScreen frame: a 32x32 board with every cell in a diagonal band CLEARED.
func _shot(cols: int, cap: int, tone: Color) -> Image:
	var sub := SubViewport.new()
	sub.size = SIZE
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
	if cap == 6:
		scr.get_five_slot_strip().set_capacity(6)
		scr.refresh_slot_snapshot([])
	scr.get_presentation().get_background().color = tone   # capture only; runtime reads the const
	await _frames(8)
	var img: Image = sub.get_texture().get_image()
	print("captured %s tone %s" % [scr.get_shell_id(), tone.to_html(false)])
	sub.queue_free()
	await _frames(2)
	return img

## Four half-size panels side by side, each with a "TONE i #hex" caption above it.
func _sheet(panels: Array) -> Image:
	var ph := int(SIZE.y * PANEL_W / float(SIZE.x))
	var sub := SubViewport.new()
	sub.size = Vector2i(PANEL_W * panels.size(), ph + LABEL_H)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.size = Vector2(sub.size)
	sub.add_child(bg)
	for k in range(panels.size()):
		var img: Image = panels[k]
		img.resize(PANEL_W, ph, Image.INTERPOLATE_LANCZOS)
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.position = Vector2(k * PANEL_W, LABEL_H)
		tr.size = Vector2(PANEL_W, ph)
		sub.add_child(tr)
		var tone: Color = BoardPresentation.BOARD_FLOOR_TONES[k]
		var l := Label.new()
		l.text = "TONE %d  #%s%s" % [k, tone.to_html(false).to_upper(), "  (selected)" if k == BoardPresentation.BOARD_FLOOR_TONE else ""]
		l.add_theme_font_size_override("font_size", 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(k * PANEL_W, 0)
		l.size = Vector2(PANEL_W, LABEL_H)
		sub.add_child(l)
	await _frames(6)
	var out: Image = sub.get_texture().get_image()
	sub.queue_free()
	return out

func _save(img: Image, name: String) -> void:
	var p := _out.path_join(name)
	img.save_png(p)
	print("wrote %s (%dx%d)" % [p, img.get_width(), img.get_height()])

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
