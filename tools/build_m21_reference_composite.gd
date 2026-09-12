extends SceneTree
## Reproducible generator for the M21-C001 headless reference composite
## (F-M21-STRICT-004). Rebuilds
## `coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png` from the COMMITTED
## M21 LevelData through the real BoardRenderer over owner-locked BG01 — it never
## reads the existing composite as source truth.
##
## Three deterministic panels, left to right, each 20x20 scaled x8 with a 4px BG01
## gap: INITIAL (all ACTIVE artwork) -> PARTIAL (top half rows CLEARED) -> FINAL
## (all CLEARED). CLEARED cells composite as BG01 so ACTIVE artwork vs cleared
## transparency is visually distinguishable. Deterministic: a second run produces
## byte-identical output and reports UNCHANGED.
##
## This is HEADLESS EVIDENCE, not a real-device screenshot or FPS/GPU proof (AL-003).
## It implements no production UI.
##
## Usage:
##   godot --headless --path . -s res://tools/build_m21_reference_composite.gd [-- --overwrite]

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const OUT := "res://coordination/sessions/M21-C001/M21_REFERENCE_COMPOSITE.png"
const BG01 := Color8(32, 37, 51, 255)
const SCALE := 8
const GAP := 4

func _initialize() -> void:
	var overwrite := OS.get_cmdline_user_args().has("--overwrite")
	var lr = LevelLoader.load_from_path(LEVEL_PATH)
	if not lr.is_ok():
		printerr("ERROR: could not load %s: %s" % [LEVEL_PATH, str(lr.errors)])
		quit(1); return
	var lvl = lr.level_data
	var board = BoardState.from_level_data(lvl)
	var w: int = board.get_width(); var h: int = board.get_height()
	var renderer = BoardRenderer.new()
	root.add_child(renderer)
	renderer.configure(board, lvl.palette, Vector2(w * SCALE, h * SCALE))

	var initial := _snapshot(renderer, w, h)
	# PARTIAL: deterministically clear the top half rows.
	for y in range(h / 2):
		for x in w:
			board.set_cell_state(board.get_cell_index(x, y), BoardState.CellState.CLEARED)
	renderer.refresh_all()
	var partial := _snapshot(renderer, w, h)
	# FINAL: clear the rest.
	for y in range(h / 2, h):
		for x in w:
			board.set_cell_state(board.get_cell_index(x, y), BoardState.CellState.CLEARED)
	renderer.refresh_all()
	var final := _snapshot(renderer, w, h)

	var pw := w * SCALE
	var ph := h * SCALE
	var total_w := pw * 3 + GAP * 2
	var out := Image.create(total_w, ph, false, Image.FORMAT_RGBA8)
	out.fill(BG01)
	_blit(out, initial, 0)
	_blit(out, partial, pw + GAP)
	_blit(out, final, (pw + GAP) * 2)

	var real := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(real.get_base_dir())
	var new_bytes := out.save_png_to_buffer()
	var status := "WRITTEN"
	if FileAccess.file_exists(OUT) and not overwrite:
		var existing := Image.new()
		if existing.load(OUT) == OK:
			if existing.get_format() != Image.FORMAT_RGBA8:
				existing.convert(Image.FORMAT_RGBA8)
			if existing.get_width() == out.get_width() and existing.get_height() == out.get_height() and existing.get_data() == out.get_data():
				status = "UNCHANGED"
	if status == "WRITTEN":
		out.save_png(OUT)
	print("COMPOSITE: %s %s" % [status, OUT])
	print("dimensions: %dx%d panels=3 order=initial|partial|final scale=%d gap=%d" % [total_w, ph, SCALE, GAP])
	print("headless evidence composite (NOT a device screenshot / FPS/GPU proof)")
	quit(0)

## RGBA8 image of the current renderer composited over opaque BG01.
func _snapshot(renderer, w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c: Color = renderer.get_pixel_color(x, y)
			img.set_pixel(x, y, BG01 if c.a <= 0.0 else c)
	return img

func _blit(dst: Image, src: Image, x_off: int) -> void:
	var w := src.get_width(); var h := src.get_height()
	for y in h:
		for x in w:
			var c: Color = src.get_pixel(x, y)
			for dy in SCALE:
				for dx in SCALE:
					dst.set_pixel(x_off + x * SCALE + dx, y * SCALE + dy, c)
