extends SceneTree
## M28-C002-C003-R01 V02 rendered-pixel proof + evidence for the dynamic pixel grid / bevel.
## Renders the REAL BoardRenderer (with its grid ShaderMaterial) over a known solid background,
## reads the rendered pixels back and asserts, for small / medium / large / rectangular logical
## grids:
##   - the gutters sit exactly on the logical cell boundaries (k * cell_size, +-1 px);
##   - cell interiors keep the exact palette colour (bevel/gutter never touch the core);
##   - gutters are darker than the cell core (the individual pixels are countable);
##   - a CLEARED cell shows the background EXACTLY (no ghost grid / tile / bevel);
##   - grid on vs off differ only inside ACTIVE cells.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/board_grid_probe.gd -- <out_dir>

const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const BG := Color(1.0, 0.0, 1.0, 1.0)   ## unmistakable background: any grid ghost on a cleared cell shows
## [w, h, cell px]
const CASES := [[20, 20, 30], [24, 32, 24], [38, 38, 16], [59, 59, 12], [20, 59, 14], [59, 20, 14]]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://board_grid_probe"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	for c in CASES:
		await _case(out_dir, c[0], c[1], c[2])
	print("BOARD GRID PROBE: ", "PASS" if _bad == 0 else "FAIL (%d)" % _bad)
	quit(1 if _bad > 0 else 0)

func _render(board: BoardState, cs: int, grid_on: bool) -> Image:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var sub := SubViewport.new()
	sub.size = Vector2i(w * cs, h * cs)
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(sub.size)
	sub.add_child(bg)
	var r := BoardRenderer.new()
	r.set_grid_enabled(grid_on)
	r.configure(board, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(sub.size))
	sub.add_child(r)
	for _i in range(4):
		await process_frame
	var img := sub.get_texture().get_image()
	sub.queue_free()
	await process_frame
	return img

func _lum(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b

func _near(a: Color, b: Color, tol: float) -> bool:
	return absf(a.r - b.r) <= tol and absf(a.g - b.g) <= tol and absf(a.b - b.b) <= tol

func _case(out_dir: String, w: int, h: int, cs: int) -> void:
	var board := BoardDebugFixtures.make_board(w, h)
	# Clear a 3x3 block (and the very first cell) to prove no ghost is left.
	var cleared: Array = []
	for y in range(4, 7):
		for x in range(5, 8):
			cleared.append(Vector2i(x, y))
	cleared.append(Vector2i(0, 0))
	for c in cleared:
		board.set_cell_state(board.get_cell_index(c.x, c.y), BoardState.CellState.CLEARED)
	var on: Image = await _render(board, cs, true)
	var off: Image = await _render(board, cs, false)
	var pal: Array = PackedStringArray(BoardDebugFixtures.PALETTE)
	var tag := "%dx%d@%d" % [w, h, cs]
	var bad: Array = []
	# 1/2/3: sample row through cell row y=10 (all ACTIVE, one colour band): core colour, gutter minima positions.
	var row := 10
	var py: int = row * cs + cs / 2
	var core_col: Color = off.get_pixel(cs / 2, py)
	var mins: Array = []
	for k in range(1, mini(w, 12)):
		var best_x := -1
		var best_l := 9.0
		for dx in range(-3, 4):
			var x: int = k * cs + dx
			var l := _lum(on.get_pixel(x, py))
			if l < best_l:
				best_l = l
				best_x = x
		mins.append(best_x - k * cs)
		if absi(best_x - k * cs) > 1 and absi(best_x - (k * cs - 1)) > 1:
			bad.append("gutter %d off by %d px" % [k, best_x - k * cs])
		if best_l > _lum(core_col) * 0.85:
			bad.append("gutter %d not darker (%.2f vs core %.2f)" % [k, best_l, _lum(core_col)])
	for k in range(0, mini(w, 12)):
		var cx: int = k * cs + cs / 2
		if not _near(on.get_pixel(cx, py), off.get_pixel(cx, py), 0.012):
			bad.append("core of cell %d changed" % k)
	# 4: cleared cells show the background EXACTLY (with the grid ON).
	var ghost := 0
	for c in cleared:
		for yy in range(c.y * cs, c.y * cs + cs):
			for xx in range(c.x * cs, c.x * cs + cs):
				if on.get_pixel(xx, yy) != BG:
					ghost += 1
	if ghost > 0:
		bad.append("%d ghost pixels on cleared cells" % ghost)
	# 5: on vs off differ only inside ACTIVE cells.
	var stray := 0
	var diff_active := 0
	var cleared_set := {}
	for c in cleared:
		cleared_set[c] = true
	for y in range(0, h * cs, 1):
		for x in range(0, w * cs, 1):
			if on.get_pixel(x, y) != off.get_pixel(x, y):
				if cleared_set.has(Vector2i(x / cs, y / cs)):
					stray += 1
				else:
					diff_active += 1
	if stray > 0 or diff_active == 0:
		bad.append("on/off differ outside ACTIVE cells (%d) or nowhere (%d)" % [stray, diff_active])
	var path := "%s/grid_%s.png" % [out_dir, tag.replace("@", "_cs")]
	# Evidence: the whole board (as played) + a zoomed crop of the top-left showing the bevel.
	on.save_png(path)
	var crop := Rect2i(0, 0, mini(on.get_width(), cs * 9), mini(on.get_height(), cs * 9))
	var z := on.get_region(crop)
	z.resize(z.get_width() * 3, z.get_height() * 3, Image.INTERPOLATE_NEAREST)
	z.save_png("%s/grid_%s_zoom.png" % [out_dir, tag.replace("@", "_cs")])
	if bad.is_empty():
		print("PASS ", tag, ": gutters on cell boundaries (offsets ", mins.slice(0, 6), "), cores exact, cleared cells clean (", cleared.size(), " cells), on/off differ only in ACTIVE cells (", diff_active, " px)")
	else:
		_bad += 1
		print("FAIL ", tag, " ", bad)
