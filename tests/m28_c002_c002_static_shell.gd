extends SceneTree
## M28-C002-C002 — static master shell evidence (OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01).
## Real ProductionGameplayHost / GameplayScreen on real AppState + real levels:
##   Level 2/3 (owner supply plans, 3 columns) through the real app root, and Level 1 with
##   the M23 generator at 4 / 5 columns (the only 4/5-column source today).
##
## Run: godot --headless --path . -s res://tests/m28_c002_c002_static_shell.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const MATRIX := [
	Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400),
	Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048),
]
## Baked obsolete-instruction bounding box measured on the masters (must be covered).
const BAKED_TEXT := Rect2(37, 1200, 150, 117)

var EXPECTED_CASES := [
	"masters_locked", "shell_selection_matrix", "no_duplicate_chrome", "board_on_baked_rail",
	"agents_on_baked_rail", "slot_overlays_align", "six_slot_switch", "supply_align_345",
	"front_only_input", "profile_dynamic_only", "pause_2x_boxes", "timed_2x_wallclock",
	"boosters_and_ad_region", "bubble_text_masked", "responsive_transform", "no_accumulation",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [1_800_000_000]
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_masters_locked()
	await _shell_selection_matrix()
	await _boot_main(2)
	_no_duplicate_chrome()
	await _board_on_baked_rail()
	await _agents_on_baked_rail()
	await _slot_overlays_align()
	await _six_slot_switch()
	await _supply_align_345()
	await _front_only_input()
	_profile_dynamic_only()
	await _pause_2x_boxes()
	await _timed_2x_wallclock()
	_boosters_and_ad_region()
	_bubble_text_masked()
	await _responsive_transform()
	await _no_accumulation()
	_shutdown()
	MainScript.boot_clock_override = Callable()
	MainScript.boot_opening_override = -1
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _new_sub(size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)

func _boot_main(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_new_sub(size)
	var path := "user://m28c002b_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

## Real host on Level 1 content with the M23 generator at `cols` columns (4/5-col source).
func _boot_gen(cols: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_new_sub(size)
	var path := "user://m28c002b_g%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var app = AppState.new(path, func(): return _now[0])
	app.progression.debug_set_current_level(1)
	_host = ProductionGameplayHost.new()
	_host.app_state = app
	_host.auto_build = false
	_host.column_count = cols
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(_host)
	_host.build()
	await _settle()
	_host.get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	elif _host != null and is_instance_valid(_host):
		_host.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _screen():
	return _host.get_screen()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _resize(size: Vector2i) -> void:
	_sub.size = size
	await _settle()

## Allowed error when a reference coordinate is carried through the uniform transform.
func _tol(extra_ref: float = 0.0) -> float:
	return 1.5 + extra_ref * _screen().get_shell_scale()

func _near(a: Rect2, b: Rect2, tol: float) -> bool:
	return a.position.distance_to(b.position) <= tol and (a.end).distance_to(b.end) <= tol

# ------------------------------------------------------------------ cases ----

func _masters_locked() -> void:
	print("[six locked masters]")
	var ok := true
	for id in Shell.SHA256:
		var p := Shell.texture_path(id)
		ok = ok and FileAccess.get_sha256(p) == Shell.SHA256[id]
	_ok(ok and Shell.SHA256.size() == 6, "all six committed masters match the owner-locked SHA-256")
	var dims := true
	for id in Shell.SHA256:
		var img := Image.load_from_file(ProjectSettings.globalize_path(Shell.texture_path(id)))
		dims = dims and img != null and img.get_size() == Vector2i(887, 1774)
	_ok(dims, "all six are 887x1774")
	_ok(FileAccess.file_exists("res://assets/ui/final/gameplay/master/scrubbots_gameplay_master.png"), "historical scrubbots_gameplay_master.png preserved")
	_complete("masters_locked")

## columns (3/4/5, authoritative supply) x capacity (5/6, authoritative strip) -> shell.
func _shell_selection_matrix() -> void:
	print("[shell selection matrix]")
	_new_sub(Vector2i(1080, 2160))
	var lvl = BoardDebugFixtures.make_level(24, 24)
	var ok := true
	for cols in [3, 4, 5]:
		var scr = GameplayScreen.new()
		_sub.add_child(scr)
		var sup = BatchSupplyGenerator.generate(lvl, cols, 3, 5)
		scr.configure(BoardDebugFixtures.make_board(24, 24), lvl.palette, [], sup.player_snapshot())
		await process_frame
		var a: String = scr.get_shell_id()
		var ta: String = scr.get_shell_texture_path()
		scr.get_five_slot_strip().set_capacity(6)
		scr.refresh_slot_snapshot([])
		var b: String = scr.get_shell_id()
		var tb: String = scr.get_shell_texture_path()
		scr.get_five_slot_strip().set_capacity(5)
		scr.refresh_slot_snapshot([])
		var c: String = scr.get_shell_id()
		ok = ok and a == "5slot_%dcol" % cols and b == "6slot_%dcol" % cols and c == a
		ok = ok and ta == Shell.texture_path(a) and tb == Shell.texture_path(b)
		print("    %d cols: %s -> %s -> %s" % [cols, a, b, c])
		scr.free()
	_ok(ok, "3/4/5 columns x 5/6 capacity select exactly 5slot_Ncol / 6slot_Ncol and back")
	var bad = GameplayScreen.new()
	_sub.add_child(bad)
	var two := [{"front": null, "preview": [], "remaining": 0}, {"front": null, "preview": [], "remaining": 0}]
	bad.configure(BoardDebugFixtures.make_board(24, 24), lvl.palette, [], two)
	await process_frame
	_ok(bad.get_shell_id() == "" and bad.get_shell_error() != "" and bad.get_shell_texture_path() == "", "unsupported column count fails closed (no shell)")
	bad.free()
	_complete("shell_selection_matrix")

func _no_duplicate_chrome() -> void:
	print("[no duplicate chrome]")
	var s = _screen()
	_ok(s.get_shell_id() == "5slot_3col", "Level 2 (3-col owner plan) uses the 5slot_3col master")
	_ok(not s.get_rail_view().visible, "no second visible Railway (rail view kept only as geometry)")
	var views: Array = s.get_five_slot_strip().get_slot_views()
	_ok(views.all(func(v): return v.is_shell_mode() and v.get_theme_stylebox("panel") is StyleBoxEmpty), "empty slots draw no frame (baked frames show)")
	var sp = s.get_supply_panel()
	_ok(sp.is_shell_mode(), "supply in shell mode (tiles over baked cells)")
	_ok(not (s.get_node("SafeAreaRoot") if s.has_node("SafeAreaRoot") else s).find_children("*", "Panel", true, false).any(func(p): return p.name == "ProfileChip" or p.name == "SlotTray" or p.name == "SupplyTray"), "no native profile / slot-tray / supply-tray chrome")
	var tex_nodes: Array = s.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture != null and t.is_visible_in_tree())
	var names: Array = tex_nodes.map(func(t): return String(t.name))
	_ok(names.count("GameplayShell") == 1 and not names.has("VictoryRobot") and tex_nodes.all(func(t): return ["GameplayShell", "BoardRenderer", "Portrait", "Icon", "SelectedRing", "UnavailableOverlay"].has(String(t.name))),
		"only the shell + live overlays carry textures %s" % str(names))
	var pb = s.get_pause_button()
	_ok(pb.get_theme_stylebox("normal") is StyleBoxEmpty, "Pause adds no outer chrome over the baked box")
	_complete("no_duplicate_chrome")

## The runtime ScrubRailGeometry loop lands on the baked Railway (First 10 square boards).
func _board_on_baked_rail() -> void:
	print("[board / runtime rail on baked rail]")
	for lv in [1, 2, 3, 5]:
		for size in [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
			await _boot_main(lv, size)
			var s = _screen()
			var b = _host.get_board()
			var g = ScrubRailGeometry.new(b.get_width(), b.get_height())
			var id: String = s.get_shell_id()
			var baked: Rect2 = s.ref_rect_to_global(Shell.rail_rect(id))
			var tl: Vector2 = s.board_local_to_global(Vector2(g.left_x(), g.top_y()))
			var br: Vector2 = s.board_local_to_global(Vector2(g.right_x(), g.bottom_y()))
			var cell: float = s.get_cell_size()
			var tol: float = maxf(cell * 0.4, 6.0)
			var err := maxf(maxf(absf(tl.x - baked.position.x), absf(tl.y - baked.position.y)), maxf(absf(br.x - baked.end.x), absf(br.y - baked.end.y)))
			_ok(err <= tol, "L%d %dx%d %dx%d board: runtime rail centrelines within %.1f px of baked rail (max err %.1f, cell %d)" % [lv, size.x, size.y, b.get_width(), b.get_height(), tol, err, int(cell)])
			var board: Rect2 = s.get_board_rect()
			_ok(baked.grow(-cell * 2.2).encloses(board) and absf(board.size.x / board.size.y - float(b.get_width()) / b.get_height()) < 0.01, "   board inside the rail with >= 2 cells clearance, aspect kept")
	await _boot_main(2)
	_complete("board_on_baked_rail")

func _clicks() -> Array:
	return SupplyPlanLoader.load_plan(_host.supply_plan_path)["plan"]["intendedColumnClicks"] if not String(_host.supply_plan_path).is_empty() else []

## Real moving agents on the bottom rail / connectors sit on the baked art.
func _agents_on_baked_rail() -> void:
	print("[agents on baked rail]")
	var s = _screen()
	var clicks := _clicks()
	var i := 0
	var best := {"rail": 0, "conn": 0, "rail_err": 0.0, "conn_err": 0.0}
	var g = ScrubRailGeometry.new(_host.get_board().get_width(), _host.get_board().get_height())
	var baked_bottom: float = s.ref_to_global(Vector2(0, Shell.SHELLS["5slot_3col"]["rail"]["bottom"])).y
	var cx: Array = Shell.SHELLS["5slot_3col"]["connector_x"].map(func(x): return s.ref_to_global(Vector2(x, 0)).x)
	for frame in range(600):
		if _host.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
			if _host.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
		_host.get_runtime().tick(0.05)
		for a in _host.get_agent_layer().get_children():
			if not (a is ScrubbotAgent and a.is_moving()):
				continue
			var p: Vector2 = a.position
			var gp: Vector2 = s.board_local_to_global(p)
			if absf(p.y - g.bottom_y()) < 0.01:
				best["rail"] += 1
				best["rail_err"] = maxf(best["rail_err"], absf(gp.y - baked_bottom))
			elif p.y > g.bottom_y() + 0.6:
				best["conn"] += 1
				var dx := 1e9
				for x in cx:
					dx = minf(dx, absf(gp.x - x))
				best["conn_err"] = maxf(best["conn_err"], dx)
	var tol: float = maxf(s.get_cell_size() * 0.4, 6.0)
	_ok(best["rail"] > 20 and best["rail_err"] <= tol, "agents on the bottom rail ride the baked rail (%d samples, max %.1f px)" % [best["rail"], best["rail_err"]])
	_ok(best["conn"] > 20 and best["conn_err"] <= 6.0 * s.get_shell_scale() + 2.0, "agents on connectors ride the baked connectors (%d samples, max %.1f px)" % [best["conn"], best["conn_err"]])
	await _boot_main(2)
	_complete("agents_on_baked_rail")

func _slot_overlays_align() -> void:
	print("[slot overlays align]")
	var s = _screen()
	var id: String = s.get_shell_id()
	var views: Array = s.get_five_slot_strip().get_slot_views()
	var refs: Array = Shell.slot_rects(id)
	var ok := views.size() == refs.size()
	for k in range(views.size()):
		ok = ok and _near(views[k].get_global_rect(), s.ref_rect_to_global(refs[k]), _tol())
	_ok(ok, "5 live slot overlays exactly on the 5 baked slot frames")
	var segs: Array = s.get_connector_segments()
	var cx: Array = Shell.SHELLS[id]["connector_x"]
	var c_ok := segs.size() == 5
	for k in range(segs.size()):
		var gx: float = s.board_local_to_global(segs[k][0]).x
		c_ok = c_ok and absf(gx - s.ref_to_global(Vector2(cx[k], 0)).x) <= 6.0 * s.get_shell_scale() + 1.5
		c_ok = c_ok and segs[k][0].is_equal_approx(_host.get_origin_provider().origin_for_slot(k))
	_ok(c_ok, "runtime route origins (origin_for_slot) sit on the baked connectors")
	_complete("slot_overlays_align")

## +1 Slot -> matching 6-slot master; retry -> 5-slot; no drawn sixth slot; state intact.
func _six_slot_switch() -> void:
	print("[5 -> 6 -> 5 shell switching]")
	for cols in [3, 4, 5]:
		if cols == 3:
			await _boot_main(2)
		else:
			await _boot_gen(cols)
		var s = _screen()
		var eco = _host.get_economy()
		_host.get_input_controller().activate_front(0)
		var board0: int = _host.get_board().count_cells_by_state(0)
		var supply0: Array = _host.get_supply().player_snapshot()
		var slots0: Array = _host.get_slots().snapshot()
		var n0 := _count(s)
		var ok := true
		for cycle in range(3):
			eco.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
			var r: Dictionary = _host.request_booster(BoosterInventory.PLUS_ONE_SLOT)
			await _settle()
			var six_ok: bool = r.get("ok", false) and s.get_shell_id() == "6slot_%dcol" % cols and s.get_five_slot_strip().get_slot_count() == 6
			var views: Array = s.get_five_slot_strip().get_slot_views()
			var refs: Array = Shell.slot_rects(s.get_shell_id())
			for k in range(6):
				six_ok = six_ok and _near(views[k].get_global_rect(), s.ref_rect_to_global(refs[k]), _tol())
			six_ok = six_ok and s.get_connector_segments().size() == 6 and not s.get_rail_view().visible
			six_ok = six_ok and _host.get_supply().player_snapshot() == supply0 and _host.get_slots().snapshot().slice(0, 5) == slots0
			six_ok = six_ok and _host.get_board().count_cells_by_state(0) == board0
			_host.retry()
			await _settle()
			var five_ok: bool = s.get_shell_id() == "5slot_%dcol" % cols and s.get_five_slot_strip().get_slot_count() == 5
			ok = ok and six_ok and five_ok
			_host.get_input_controller().activate_front(0)
			supply0 = _host.get_supply().player_snapshot()
			slots0 = _host.get_slots().snapshot()
			board0 = _host.get_board().count_cells_by_state(0)
		await _settle()
		_ok(ok, "%d cols: +1 Slot -> 6slot_%dcol with 6 overlays on 6 baked frames (no drawn slot/connector), gameplay state intact; retry -> 5slot_%dcol; x3" % [cols, cols, cols])
		_ok(_count(s) == n0, "   node count stable over 3 switch cycles (%d -> %d)" % [n0, _count(s)])
	await _boot_main(2)
	_complete("six_slot_switch")

func _supply_align_345() -> void:
	print("[supply 3/4/5 alignment]")
	for cols in [3, 4, 5]:
		if cols == 3:
			await _boot_main(2)
		else:
			await _boot_gen(cols)
		var s = _screen()
		var sp = s.get_supply_panel()
		var id: String = s.get_shell_id()
		var ok: bool = sp.get_column_count() == cols
		var worst := 0.0
		for c in range(cols):
			var rows: Array = sp.get_column_row_panels(c)
			for r in range(3):
				var got: Rect2 = rows[r].get_global_rect()
				var want: Rect2 = s.ref_rect_to_global(Shell.supply_cell(id, c, r))
				worst = maxf(worst, maxf(got.position.distance_to(want.position), got.end.distance_to(want.end)))
		ok = ok and worst <= 3.0 * s.get_shell_scale() + 1.5
		_ok(ok, "%s: %dx3 live tiles / hitboxes on the baked cells (max err %.1f px)" % [id, cols, worst])
	await _boot_main(2)
	_complete("supply_align_345")

func _front_only_input() -> void:
	print("[front-only input]")
	var sp = _screen().get_supply_panel()
	var ok: bool = sp.is_front_input_enabled()
	for c in range(sp.get_column_count()):
		var rows: Array = sp.get_column_row_panels(c)
		ok = ok and rows[0].mouse_filter == Control.MOUSE_FILTER_STOP
		for r in [1, 2]:
			ok = ok and rows[r].mouse_filter == Control.MOUSE_FILTER_IGNORE and rows[r].gui_input.get_connections().is_empty()
	_ok(ok, "only front cells receive input; preview cells IGNORE")
	var got := [-1]
	var cb := func(c): got[0] = c
	sp.front_batch_activated.connect(cb)
	var front = sp.get_column_row_panels(1)[0]
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		front.gui_input.emit(e)
	sp.front_batch_activated.disconnect(cb)
	_ok(got[0] == 1 and _host.get_slots().snapshot().filter(func(x): return bool(x.get("occupied", false))).size() >= 1, "front press/release -> activation -> real placement")
	var s = _screen()
	var views: Array = s.get_five_slot_strip().get_slot_views()
	_ok(views.all(func(v): return not (v is Button) and v.mouse_filter == Control.MOUSE_FILTER_IGNORE), "slots are not destination buttons")
	_complete("front_only_input")

func _profile_dynamic_only() -> void:
	print("[profile dynamic only]")
	var s = _screen()
	var prof: Control = s.get_node("SafeAreaRoot/MarginContainer/Content/ScreenContent/TopRegion/ProfileChip") if s.has_node("SafeAreaRoot/MarginContainer/Content/ScreenContent/TopRegion/ProfileChip") else s.find_child("ProfileChip", true, false)
	var kids: Array = prof.get_children().map(func(c): return String(c.name))
	_ok(kids == ["Portrait", "ProfileName", "ProfileLevel", "BotPartsBar", "BotPartsText"], "profile holds only portrait / name / Level / Bot Parts %s" % str(kids))
	var p: Dictionary = _host.get_economy().robots.next_robot_progress()
	_ok(s.get_profile_level_text() == "Level 2" and s.get_profile_parts_text() == "%d/%d" % [p["parts"], p["cost"]], "live Level + Bot Parts from canonical services")
	_ok(s.ref_rect_to_global(Shell.rect(Shell.PROFILE)).encloses(s.get_profile_rect().grow(-1.0)), "profile overlay inside the baked profile frame")
	_complete("profile_dynamic_only")

func _pause_2x_boxes() -> void:
	print("[Pause / 2x in baked boxes]")
	var s = _screen()
	_ok(_near(s.get_pause_rect(), s.ref_rect_to_global(Shell.rect(Shell.PAUSE)), _tol()) and _near(s.get_speed_control_rect(), s.ref_rect_to_global(Shell.rect(Shell.SPEED)), _tol()), "Pause / 2x hit areas = baked boxes")
	_ok(s.get_pause_rect().size.y >= UiTokens.TOUCH_MIN and s.get_speed_control_rect().size.y >= UiTokens.TOUCH_MIN, "Pause / 2x >= touch minimum")
	s.get_pause_button().pressed.emit()
	_ok(_host.get_runtime().is_user_paused() and s.is_paused_visual(), "Pause keeps runtime pause behaviour")
	s.get_pause_button().pressed.emit()
	_ok(not _host.get_runtime().is_user_paused(), "resume")
	_complete("pause_2x_boxes")

func _timed_2x_wallclock() -> void:
	print("[timed 2x wall clock]")
	var s = _screen()
	var eco = _host.get_economy()
	eco.wallet.credit("scrub_bucks", 1000)
	s.get_speed_button().pressed.emit()
	_host.get_speed_acquisition_popup().get_offer_button("timed_900").pressed.emit()
	_ok(s.get_speed_mode() == "timed" and s.get_speed_label() == "15:00", "timed purchase -> 15:00 in the baked 2x box")
	_now[0] += 62
	_host._refresh_hud()
	_ok(s.get_speed_label() == "13:58", "+62 s wall clock -> 13:58")
	_now[0] -= 600
	_host._refresh_hud()
	_ok(s.get_speed_label() == "13:58", "rollback frozen (anti-rollback)")
	_now[0] += 600
	s.get_speed_button().pressed.emit()
	_host.get_runtime().set_speed_2x(true)
	s.set_speed_2x(true)
	_now[0] += 5000
	_host._refresh_hud()
	_ok(s.get_speed_mode() == "auto" and s.get_speed_label() == "2x", "after expiry with free auto-2x: distinct auto state")
	_complete("timed_2x_wallclock")

func _boosters_and_ad_region() -> void:
	print("[boosters + ad region]")
	var s = _screen()
	var shell: Rect2 = s.get_shell_rect()
	var ad: Rect2 = s.get_ad_region_rect()
	var row: Rect2 = s.get_booster_row_rect()
	_ok(s.get_booster_count() == 4 and s.get_booster_ids() == ["plus_one_slot", "random", "selector", "tornado"], "exactly four canonical boosters")
	_ok(s.has_ad_region() and _near(ad, s.ref_rect_to_global(Shell.rect(Shell.AD)), _tol()) and ad.end.y <= shell.end.y + 1.0, "reserved ad region at the bottom of the shell")
	_ok(row.end.y <= ad.position.y + 1.0 and row.position.y >= s.get_supply_panel_rect().end.y, "boosters above the ad region, below the supply")
	_ok(not s.has_ad_placeholder(), "legacy C001-era bottom Pause/ad/speed row absent")
	_complete("boosters_and_ad_region")

func _bubble_text_masked() -> void:
	print("[obsolete bubble text masked]")
	var s = _screen()
	var mask: Panel = s.get_bubble_mask()
	var sb := mask.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(mask.is_visible_in_tree() and sb != null and sb.bg_color.a == 1.0 and sb.bg_color == Shell.BUBBLE_FILL, "opaque mask in the bubble's own fill colour")
	_ok(mask.get_global_rect().encloses(s.ref_rect_to_global(BAKED_TEXT)), "mask covers the whole baked instruction")
	_ok(mask.get_children().is_empty() and s.find_children("*", "Label", true, false).all(func(l): return String(l.text).to_lower().find("tap on") == -1), "bubble left blank; no tutorial copy invented")
	_complete("bubble_text_masked")

func _responsive_transform() -> void:
	print("[responsive transform]")
	for size in MATRIX:
		await _resize(size)
		var s = _screen()
		var sh: Rect2 = s.get_shell_node_rect()   # the REAL shell TextureRect on screen
		var safe: Rect2 = s.get_safe_rect()
		var ok: bool = absf(sh.size.x / sh.size.y - 0.5) < 0.002 and safe.grow(1.0).encloses(sh)
		ok = ok and _near(sh, s.get_shell_rect(), 1.0)   # image and overlays share one transform
		ok = ok and (absf(sh.size.x - safe.size.x) < 1.5 or absf(sh.size.y - safe.size.y) < 1.5)
		ok = ok and _near(s.get_pause_rect(), s.ref_rect_to_global(Shell.rect(Shell.PAUSE)), _tol())
		# Booster row keeps its reference band after shrinking from a larger size.
		ok = ok and _near(s.get_booster_row_rect(), s.ref_rect_to_global(Shell.rect(Shell.BOOSTERS)), _tol())
		var v0: Rect2 = s.get_five_slot_strip().get_slot_views()[0].get_global_rect()
		ok = ok and _near(v0, s.ref_rect_to_global(Shell.slot_rects(s.get_shell_id())[0]), _tol())
		var f0: Rect2 = s.get_supply_panel().get_column_row_panels(0)[0].get_global_rect()
		ok = ok and _near(f0, s.ref_rect_to_global(Shell.supply_cell(s.get_shell_id(), 0, 0)), 3.0 * s.get_shell_scale() + 1.5)
		var rt := 0.0
		for p in [Vector2i(0, 0), Vector2i(31, 31), Vector2i(16, 9)]:
			rt = maxf(rt, s.global_to_board_local(s.cell_center_to_global(p.x, p.y)).distance_to(Vector2(p.x + 0.5, p.y + 0.5)))
		_ok(ok and rt < 1e-3, "%dx%d: uniform 1:2 aspect-fit (scale %.3f) inside safe rect; overlays follow the same transform; coord round-trip %.6f" % [size.x, size.y, s.get_shell_scale(), rt])
	var s2 = _screen()
	await _resize(Vector2i(1170, 2532))
	s2.set_synthetic_safe_insets(0, 141, 0, 102)
	await _settle()
	var inner := Rect2(0, 141, 1170, 2532 - 141 - 102)
	_ok(inner.grow(1.0).encloses(s2.get_shell_rect()) and inner.encloses(s2.get_pause_rect()) and inner.encloses(s2.get_booster_row_rect()), "notch 141 / gesture 102: whole shell + controls inside the safe rect")
	s2.set_synthetic_safe_insets(0, 0, 0, 0)
	await _resize(Vector2i(1080, 2160))
	_complete("responsive_transform")

func _no_accumulation() -> void:
	print("[no accumulation]")
	var s = _screen()
	await _settle()
	var n0 := _count(s)
	var c0: int = s.booster_pressed.get_connections().size()
	for _i in range(5):
		_host.retry()
		await _settle()
	_ok(_count(s) == n0 and s.booster_pressed.get_connections().size() == c0 and _host.find_children("HudTimer", "Timer", false, false).size() == 1, "5 retries: nodes %d -> %d, no signal/timer growth" % [n0, _count(s)])
	_complete("no_accumulation")

# ------------------------------------------------------------------ helpers ----

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M28-C002-C002 static master shell evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
