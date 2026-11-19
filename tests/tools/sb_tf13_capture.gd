extends SceneTree
## SB-TF-13 owner evidence (GPU, windowed; throw-away saves only, the real save is never touched):
##   home_<w>x<h>.png              Home with the 0.98x activity buttons (live events at frontier 30);
##   event_details_<w>x<h>.png     an event screen: whole board artwork, JOIN above the banner;
##   event_tutorial_<w>x<h>.png    its walkthrough step 1 (one X, Continue + n / N above the banner);
##   gameplay_<w>x<h>.png          level 19 (whale: C07 / C08 / C16 cells) on the #4A3258 floor, the
##                                 shell full width, half the artwork cleared;
## at the iPhone 1179x2556 (1080x2341 logical canvas, notch 170 / home bar 93 synthetic insets, the
## banner area drawn where the provider banner sits) and 1080x1920; saved at half the physical size.
## Run (rendering driver, NOT --headless):
##   godot --path <worktree> -s res://tests/tools/sb_tf13_capture.gd -- --out <dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

## [logical canvas, physical size, top inset, bottom inset]
const CASES := [[Vector2i(1080, 2341), Vector2i(1179, 2556), 170, 93], [Vector2i(1080, 1920), Vector2i(1080, 1920), 0, 0]]
const LEVEL := "res://data/levels/level_019_whale.json"

var _out := ""
var _now := [0]

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("sb_tf13 capture: NOT_RUN (needs a rendering driver)")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	_out = ProjectSettings.globalize_path(args[i + 1])
	DirAccess.make_dir_recursive_absolute(_out)
	AppStateScript.test_unlock_all = true
	_now[0] = int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"]) + 3600
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	for c in CASES:
		await _app_shots(c)
		await _gameplay_shot(c)
	MainScript.boot_save_path_override = ""
	print("SB_TF13_CAPTURES DONE")
	quit(0)

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _app_shots(c: Array) -> void:
	var vp: Vector2i = c[0]
	var path := "user://sb_tf13_cap_%d.save" % Time.get_ticks_usec()
	var sub := _sub(vp)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _draw(6)
	var app = root.get_app_state()
	var st = root.get_modal_stack()
	st.clear("evidence")
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	root.get_home().get_node("SafeAreaRoot").set_synthetic_insets(0, c[2], 0, c[3])
	root.get_home().refresh()
	await _draw(8)
	_shot(sub, c, "home")
	var x: Dictionary = ev.scheduled(_now[0], _now[0] + 1)[0]
	var d = EventsV02Ui.open_details(st, app, x["iid"], false)
	d.set_synthetic_insets(0, c[2], 0, c[3])
	await _draw(8)
	_shot(sub, c, "event_details")
	var t = EventTutorial.open(st, app, x["iid"])
	t.set_synthetic_insets(0, c[2], 0, c[3])
	await _draw(10)
	_shot(sub, c, "event_tutorial")
	root.free()
	sub.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _gameplay_shot(c: Array) -> void:
	var sub := _sub(c[0])
	var lvl = LevelLoader.load_from_path(LEVEL).level_data
	var board = BoardState.from_level_data(lvl)
	var half: int = board.get_artwork_cell_count() / 2
	var n := 0
	for i in range(board.get_cell_count()):
		if n < half and not board.is_void(i):
			board.set_cell_state(i, BoardState.CellState.CLEARED)
			n += 1
	var scr = GameplayScreen.new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(board, lvl.palette, [], BatchSupplyGenerator.generate(lvl, 4, 3, 5).player_snapshot())
	scr.set_synthetic_safe_insets(0, c[2], 0, c[3])
	await _draw(10)
	_shot(sub, c, "gameplay")
	sub.free()

## The provider banner is native (not in the canvas): its reserved area is outlined so the
## evidence shows what it would cover. Saved at half the physical size.
func _shot(sub: SubViewport, c: Array, tag: String) -> void:
	var vp: Vector2i = c[0]
	var img: Image = sub.get_texture().get_image()
	var h := int(HomeStyle.ad_slot_height(vp.x))
	var y0: int = vp.y - int(c[3]) - h
	for x in range(vp.x):
		for y in [y0, y0 + 1, y0 + 2, vp.y - int(c[3]) - 1]:
			img.set_pixel(x, y, Color(1, 0.1, 0.1))
	var phys: Vector2i = c[1]
	img.resize(phys.x / 2, phys.y / 2, Image.INTERPOLATE_LANCZOS)
	var p := _out.path_join("%s_%dx%d.png" % [tag, phys.x, phys.y])
	img.save_png(p)
	print("wrote ", p)

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw
