extends SceneTree
## SB-PHONE-2026-11-12-D — board background is BG01 and no board cell sits under the frame.
## Owner phone (Galaxy A10, Level 20): the top C08 Dark Blue row was nearly invisible. Root
## cause: CLEARED holes and the board edge showed the baked shell's blue field and the bright
## aperture bevel the outer cells of a >31-cell board overhang (C08 vs bevel 1.07:1), instead
## of BG01 Midnight Slate (CLAUDE.md §7/§8). BoardPresentation now puts one BG01 rect exactly
## under the board rect.
##
## Run: godot --headless --path . -s res://tests/board_bg01_backdrop.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")

const SIZES := [Vector2i(720, 1520), Vector2i(1080, 2400), Vector2i(1170, 2532)]
## Baked frame tube: centreline (Shell rail) to inner metal edge, measured on the 5slot_3col
## master (x 76.5 -> 100, 811 -> 787; y 210 -> 234, 960.5 -> 936).
const FRAME_HALF := 24.0

var EXPECTED_CASES := ["bg01_is_palette_background", "levels_20_30_backdrop_and_frame", "envelope_59x59_backdrop_and_frame", "cleared_shows_backdrop"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_bg01_is_palette_background()
	for lv in [20, 30]:
		for size in SIZES:
			await _host_case(lv, size)
	_completed["levels_20_30_backdrop_and_frame"] = true
	for size in SIZES:
		await _fixture_case(size)
	_completed["envelope_59x59_backdrop_and_frame"] = true
	_cleared_shows_backdrop()
	_done()

func _bg01_is_palette_background() -> void:
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	var rgb: Array = pal["gameplayBackground"]["rgb"]
	_ok(pal["gameplayBackground"]["id"] == "BG01" and BoardPresentation.BG01 == Color8(int(rgb[0]), int(rgb[1]), int(rgb[2])), "BoardPresentation.BG01 == palette V3 gameplayBackground BG01 #202533")
	_completed["bg01_is_palette_background"] = true

func _host_case(lv: int, size: Vector2i) -> void:
	var save_path := "user://board_bg01_%d.save" % Time.get_ticks_usec()
	var sub := _viewport(size)
	var app = AppState.new(save_path)
	app.progression.debug_set_current_level(lv)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	h.build()
	await process_frame
	await process_frame
	_check(h.get_screen(), "L%d %dx%d" % [lv, size.x, size.y])
	h.free()
	sub.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))

func _fixture_case(size: Vector2i) -> void:
	var sub := _viewport(size)
	var lvl = BoardDebugFixtures.make_level(59, 59)
	var scr = GameplayScreen.new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(BoardDebugFixtures.make_board(59, 59), lvl.palette, [], BatchSupplyGenerator.generate(lvl, 3, 3, 5).player_snapshot())
	await process_frame
	await process_frame
	_check(scr, "59x59 %dx%d" % [size.x, size.y])
	scr.free()
	sub.queue_free()
	await process_frame

func _viewport(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	return sub

func _check(s, label: String) -> void:
	var p = s.get_presentation()
	var bg: ColorRect = p.get_background()
	var board: Rect2 = s.get_board_rect()
	var bg_rect: Rect2 = bg.get_global_transform() * Rect2(Vector2.ZERO, bg.size)
	var renderer_index: int = p.get_renderer().get_index()
	_ok(bg.color == BoardPresentation.BG01 and bg.visible and bg.get_index() == 0 and renderer_index > 0
		and bg.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: one BG01 BoardBackground drawn first (under renderer index %d), ignores input" % [label, renderer_index])
	_ok(_near(bg_rect, board), "%s: backdrop rect %s == board rect %s" % [label, str(bg_rect), str(board)])
	var inner: Rect2 = s.ref_rect_to_global(Shell.rail_rect(s.get_shell_id())).grow(-FRAME_HALF * s.get_shell_scale())
	_ok(board.size.x > 0.0 and inner.encloses(board), "%s: board %s fully inside the frame's inner edge %s (no cell under the frame)" % [label, str(board), str(inner)])
	var bgs := 0
	for c in p.get_children():
		if c is ColorRect:
			bgs += 1
	_ok(bgs == 1, "%s: exactly one backdrop node (never per cell)" % label)

func _near(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < 0.5 and a.end.distance_to(b.end) < 0.5

## The renderer still draws CLEARED at alpha 0 (the hole shows the BG01 backdrop, no substitute).
func _cleared_shows_backdrop() -> void:
	var board = BoardDebugFixtures.make_board(24, 24)
	var lvl = BoardDebugFixtures.make_level(24, 24)
	var p = BoardPresentation.new()
	get_root().add_child(p)
	p.configure(board, lvl.palette, Vector2(480, 480))
	board.set_cell_state(0, BoardState.CellState.CLEARED)
	p.get_renderer().refresh_all()
	_ok(p.get_renderer().get_pixel_color(0, 0).a == 0.0 and p.get_background().color == BoardPresentation.BG01
		and p.get_background().size == p.get_renderer().size, "CLEARED cell alpha 0 over a renderer-sized BG01 backdrop")
	p.free()
	_completed["cleared_shows_backdrop"] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("Board BG01 backdrop evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
