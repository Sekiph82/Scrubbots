extends SceneTree
## M28-C002-C003-R01 V02 — five-finding remediation evidence.
##   1 timed 2x auto-starts every new gameplay while its wall-clock time remains;
##   2 WAITING / ACTIVE words are gone from the five/six-slot row;
##   3 railway-first Scrubbot routing (leave the rail at the perimeter point nearest the target);
##   4 dynamic logical-pixel grid + subtle bevel (presentation only);
##   5 Home uses exactly assets/ui/final/home/background/home_background.png.
## Real app root (main.tscn) with an injected wall clock for 1/2/5, real routing / board classes
## for 3/4. Cases 4's rendered-pixel checks need a GPU: tests/tools/board_grid_probe.gd.
##
## Run: godot --headless --path . -s res://tests/m28_c002_c003_r01_remediation.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomeScreenScript = preload("res://scripts/ui/home/home_screen.gd")
## Injected clock origin = the real wall clock at start: SaveService validates candidates in a scratch
## graph that reads the REAL clock, so a far-future injected origin would not round-trip a save.
var T0 := int(Time.get_unix_time_from_system()) - 100000
const HOME_BG := "res://assets/ui/final/home/background/home_background.png"
const HOME_BG_SHA := "9d5db29513d25ad5c0932840c08027be0198d0cd85dc758a69e09e800c7aabe2"

var EXPECTED_CASES := [
	"t01_timed_next_level_2x", "t02_relaunch_2x", "t03_manual_1x_free_next_level_2x",
	"t04_expiry_new_level_1x", "t04b_expiry_mid_level", "t05_level_2x_no_leak",
	"t06_free_auto_2x_independent", "t07_retry_keeps_timed_2x", "t07b_countdown_matches_factor",
	"s01_no_waiting_active_text", "s02_state_still_distinct",
	"r01_regions_nearest_exit", "r02_no_diagonals_on_board", "r03_legacy_cut_through",
	"r04_blocked_aligned_exit", "r05_corner_targets", "r06_target_identity",
	"g01_dynamic_grid_dims", "g02_presentation_only", "g03_no_ghost_after_clear",
	"g04_no_node_explosion", "h01_home_uses_exact_asset", "h02_no_stale_background", "h03_live_ui_intact",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [0]
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	_now[0] = T0
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _timed_2x()
	await _timed_expiry_and_scope()
	await _slot_labels()
	_routing_regions()
	_routing_blocked_and_corner()
	await _routing_identity()
	_grid()
	await _home()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot(level: int, path: String = "", size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	if path.is_empty():
		path = "user://m28r01_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	if level > 0:
		_root.get_app_state().progression.debug_set_current_level(level)
		_root.get_app_state().economy.wallet.credit("scrub_bucks", 5000)
		await _play()

func _play() -> void:
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _eco():
	return _root.get_app_state().economy

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	_sub.push_input(e)

func _click_c(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	_mouse(p, true)
	await process_frame
	_mouse(p, false)
	await _settle()

## Level -> Results (real terminal path) -> Continue: returns the NEW host.
func _win_and_continue() -> void:
	_host.get_completion().terminal_reached.emit(&"WON", {})
	await _settle()
	var r: Dictionary = _root.continue_from_results()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	if not r.get("ok", false):
		print("  (continue refused: %s)" % str(r))

func _speed_ok(want_2x: bool, label: String) -> void:
	var s = _host.get_screen()
	var rt = _host.get_runtime()
	var factor: float = _host.get_speed_authority().factor()
	_ok(_host.get_speed_authority().is_2x() == want_2x and is_equal_approx(factor, 2.0 if want_2x else 1.0) and is_equal_approx(rt.get_speed_factor() if rt.has_method("get_speed_factor") else factor, factor),
		"%s: live speed factor %.1f" % [label, factor])
	_ok(s.get_speed_state() == ("2x" if want_2x else "1x"), "%s: HUD speed state agrees (%s)" % [label, s.get_speed_state()])

func _buy_timed_15() -> void:
	var s = _host.get_screen()
	await _click_c(s.get_speed_button())
	await _click_c(_host.get_speed_acquisition_popup().get_offer_button("timed_900"))

func _clicks(h) -> Array:
	if String(h.supply_plan_path).is_empty():
		return []
	return SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]

## Drive owner-plan activations + ticks until the supply is exhausted (still mid-level).
func _drive_to_exhausted(h) -> bool:
	var clicks := _clicks(h)
	var rt = h.get_runtime()
	var i := 0
	for _f in range(20000):
		if h.get_supply().is_exhausted():
			return true
		if h.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
			if h.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
		rt.tick(0.05)
		if h.get_completion().is_terminal():
			return false
	return false

# ============================================================ 1 timed 2x ========

func _timed_2x() -> void:
	print("[1 timed 2x auto-starts every new gameplay]")
	var path := "user://m28r01_timed_%d.save" % Time.get_ticks_usec()
	_now[0] = T0
	# Real progression (level 1 -> 2 -> 3 through terminal WON + Continue) so the save round-trips.
	await _boot(0, path)
	_eco().wallet.credit("scrub_bucks", 5000)
	await _play()
	_speed_ok(false, "no entitlement: fresh level starts 1x")
	await _buy_timed_15()
	var sb: int = _eco().wallet.scrub_bucks()
	_speed_ok(true, "timed purchase: current level 2x")
	# Level 1 -> WON -> Results -> time passes -> Continue -> Level 2.
	_now[0] += 200
	await _win_and_continue()
	_ok(int(_host.progression_level) == 2, "continued to level 2 (%d)" % int(_host.progression_level))
	_speed_ok(true, "T1 the next level after a timed purchase starts 2x")
	_ok(_eco().speed.timed_seconds_remaining() == 700 and _host.get_screen().get_speed_mode() == "timed" and _host.get_screen().get_speed_label() == "11:40",
		"countdown kept running through Results (700 s left, box reads 11:40)")
	_ok(_eco().wallet.scrub_bucks() >= sb, "auto-start cost nothing")
	_complete("t01_timed_next_level_2x")
	_complete("t07b_countdown_matches_factor")

	# T3 manual 1x is free; the next NEW level is 2x again while time remains.
	var sb1: int = _eco().wallet.scrub_bucks()
	await _click_c(_host.get_screen().get_speed_button())
	_speed_ok(false, "T3 manual 1x on level 2")
	_ok(_eco().wallet.scrub_bucks() == sb1 and _host.get_speed_acquisition_popup() == null, "manual 1x cost nothing, no popup")
	await _win_and_continue()
	_speed_ok(true, "T3 next new level (3) is back on the default 2x")
	_complete("t03_manual_1x_free_next_level_2x")

	# T7 Retry keeps the timed default too.
	await _click_c(_host.get_screen().get_speed_button())
	_speed_ok(false, "manual 1x again on level 3")
	_ok(_host.retry(), "Retry restores the attempt")
	_speed_ok(true, "T7 new attempt of the same level restarts at the timed default 2x")
	_complete("t07_retry_keeps_timed_2x")

	# T2 app relaunch while the entitlement remains.
	var fl: Dictionary = _root.flush_lifecycle("test")
	_ok(fl.get("ok", false), "save flushed before the relaunch (%s)" % str(fl))
	var rem_before: int = _eco().speed.timed_seconds_remaining()
	_shutdown()
	_now[0] += 60
	await _boot(0, path)
	_ok(_eco().speed.timed_seconds_remaining() == rem_before - 60 and rem_before > 0, "relaunch: timed entitlement persisted and kept counting (%d s)" % _eco().speed.timed_seconds_remaining())
	await _play()
	_speed_ok(true, "T2 first gameplay after relaunch starts 2x")
	_complete("t02_relaunch_2x")

	# T4 expired -> new gameplay 1x.
	_shutdown()
	_now[0] += 5000
	await _boot(0, path)
	_ok(_eco().speed.timed_seconds_remaining() == 0, "timed entitlement expired")
	await _play()
	_speed_ok(false, "T4 new gameplay after expiry starts 1x")
	_ok(_host.get_screen().get_speed_mode() == "off", "HUD shows no timed state")
	_complete("t04_expiry_new_level_1x")

# ============================================================ 1b mid-level / scoping =

func _timed_expiry_and_scope() -> void:
	print("[1b mid-level expiry, level scope, free auto-2x]")
	# Mid-level expiry drops a PAID 2x (not exhausted)...
	_now[0] = T0
	await _boot(2)
	await _buy_timed_15()
	_speed_ok(true, "timed 2x running")
	_now[0] += 901
	_host._refresh_hud()
	_speed_ok(false, "T4b timed 2x expired mid-level: paid 2x no longer holds the level at 2x")
	_complete("t04b_expiry_mid_level")
	# ...but not once the free M23 auto-2x owns the speed.
	_now[0] = T0
	await _boot(2)
	await _buy_timed_15()
	var exhausted := _drive_to_exhausted(_host)
	_ok(exhausted and _host.get_speed_authority().is_2x(), "supply exhausted: free auto-2x active (%s)" % str(exhausted))
	_now[0] += 901
	_host._refresh_hud()
	_ok(_host.get_speed_authority().is_2x() and _host.get_screen().get_speed_mode() == "auto",
		"T4b expiry while the free M23 auto-2x is active: speed stays 2x, HUD shows the free-auto state")
	# T6 free auto-2x is independent of any entitlement, and never leaks into the next level.
	_now[0] = T0
	await _boot(2)
	_ok(not _eco().speed.is_manual_2x_entitled(2), "no entitlement of any kind")
	var sb0: int = _eco().wallet.scrub_bucks()
	var ex2 := _drive_to_exhausted(_host)
	_ok(ex2 and _host.get_speed_authority().is_2x() and _eco().wallet.scrub_bucks() == sb0 and _host.get_speed_acquisition_popup() == null,
		"T6 free M23 auto-2x with no entitlement: 2x, no SB, no popup")
	await _win_and_continue()
	_speed_ok(false, "T6 next level starts 1x again (auto-2x never becomes a default)")
	_complete("t06_free_auto_2x_independent")
	# T5 current-level 2x (200 SB) is level-scoped: no leak to the next level, no auto-start on it.
	_now[0] = T0
	await _boot(2)
	await _click_c(_host.get_screen().get_speed_button())
	await _click_c(_host.get_speed_acquisition_popup().get_offer_button("level"))
	_speed_ok(true, "current-level 2x bought on level 2")
	_ok(_eco().speed.is_level_entitled(2) and _eco().speed.timed_seconds_remaining() == 0, "level entitlement only (no timed)")
	await _win_and_continue()
	_ok(int(_host.progression_level) == 3 and not _eco().speed.is_manual_2x_entitled(3) and not _eco().speed.is_level_entitled(3), "level entitlement cleared by the win, none for level 3")
	_speed_ok(false, "T5 level 3 starts 1x (current-level 2x did not leak)")
	_complete("t05_level_2x_no_leak")

# ============================================================ 2 slot labels =====

func _texts(node: Node) -> Array:
	var out: Array = []
	for c in node.find_children("*", "", true, false):
		if c is Label:
			out.append((c as Label).text)
		elif c is Button:
			out.append((c as Button).text)
	return out

func _slot_labels() -> void:
	print("[2 WAITING / ACTIVE words removed from the slot row]")
	await _boot(2)
	var s = _host.get_screen()
	var strip = s.get_five_slot_strip()
	var clicks := _clicks(_host)
	var i := 0
	while _host.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
		if _host.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
			i += 1
	_host.get_runtime().tick(0.05)
	await _settle()
	var occupied: int = _host.get_slots().snapshot().filter(func(x): return bool(x.get("occupied", false))).size()
	var bad: Array = []
	for t in _texts(strip):
		var u := String(t).to_upper()
		if u.find("WAITING") != -1 or u.find("ACTIVE") != -1:
			bad.append(t)
	var wholescreen: Array = _texts(s).filter(func(t): return String(t).to_upper().find("WAITING") != -1 or String(t).to_upper().find("ACTIVE") != -1)
	_ok(occupied >= 3 and bad.is_empty() and wholescreen.is_empty(), "S1 five-slot row (%d occupied): no WAITING/ACTIVE text; whole gameplay screen too %s" % [occupied, str(wholescreen)])
	var texts_empty := true
	for v in strip.get_slot_views():
		texts_empty = texts_empty and v.get_state_text() == ""
	_ok(texts_empty, "every slot view's state-text label is empty")
	# temporary sixth slot shares the component
	_eco().boosters.add_charges("plus_one_slot", 1)
	_host.request_booster("plus_one_slot")
	await _settle()
	var six: Array = _texts(strip).filter(func(t): return String(t).to_upper().find("WAITING") != -1 or String(t).to_upper().find("ACTIVE") != -1)
	_ok(strip.get_capacity() == 6 and six.is_empty(), "S1 sixth slot: capacity 6, no WAITING/ACTIVE text")
	var counts_ok := true
	for v in strip.get_slot_views():
		if v.is_occupied_view():
			counts_ok = counts_ok and v.get_count_label_text() == str(v.get_display_count()) and v.get_display_count() > 0
	_ok(counts_ok, "robot counts still shown on occupied slots")
	_complete("s01_no_waiting_active_text")
	# Distinct visual state without the words.
	var a := BatchSlotView.new()
	a.set_shell_mode(true)
	a.bind_snapshot({"state": "ACTIVE", "occupied": true, "remaining_to_clear": 12, "committed": 2}, Color(0.2, 0.7, 0.3))
	var w := BatchSlotView.new()
	w.set_shell_mode(true)
	w.bind_snapshot({"state": "WAITING", "occupied": true, "remaining_to_clear": 12, "committed": 2}, Color(0.2, 0.7, 0.3))
	var sa := a.get_theme_stylebox("panel") as StyleBoxFlat
	var sw := w.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(a.get_state() == "ACTIVE" and w.get_state() == "WAITING" and a.get_state_text() == "" and w.get_state_text() == "" and a.get_display_count() == 10,
		"slot truth unchanged (state ACTIVE/WAITING, count 12-2=10) with no words")
	_ok(sa != null and sw != null and sa.border_color != sw.border_color and sa.border_width_left != sw.border_width_left, "ACTIVE and WAITING remain visually distinct by border colour/width")
	a.free()
	w.free()
	_complete("s02_state_still_distinct")

# ============================================================ 3 routing =========

## Board fully CLEARED except `active` cells (all ACTIVE cells except the target are blocked).
func _open_board(w: int, h: int, active: Array = []) -> BoardState:
	var b := BoardDebugFixtures.make_board(w, h)
	for i in range(w * h):
		b.set_cell_state(i, BoardState.CellState.CLEARED)
	for c in active:
		b.set_cell_state(b.get_cell_index(c.x, c.y), BoardState.CellState.ACTIVE)
	return b

func _route(b: BoardState, start: Vector2, t: Vector2i, cost: float = -1.0) -> RefCounted:
	# The target cell is ACTIVE (final arrival); everything else is per the board.
	b.set_cell_state(b.get_cell_index(t.x, t.y), BoardState.CellState.ACTIVE)
	var rs := ProductionRoutingSystem.new()
	if cost > 0.0:
		rs.interior_step_cost = cost
	var req = RouteRequest.for_target(b, start, b.get_cell_index(t.x, t.y))
	var res = rs.compute_route(req, b, ProductionAccessQuery.new(b))
	var ok_valid: bool = res.success and RouteValidator.validate_route(req, res, b, ProductionAccessQuery.new(b)) == RouteResult.FailureReason.NONE
	res.set_meta("valid", ok_valid)
	return res

## Length of the polyline clipped to the board rectangle [0,W]x[0,H] (axis-aligned segments).
func _inside_len(pts: PackedVector2Array, w: int, h: int) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		var a := pts[i]
		var c := pts[i + 1]
		if absf(a.x - c.x) < 0.0001:
			if a.x > 0.0 and a.x < float(w):
				var lo := clampf(minf(a.y, c.y), 0.0, float(h))
				var hi := clampf(maxf(a.y, c.y), 0.0, float(h))
				total += hi - lo
		else:
			if a.y > 0.0 and a.y < float(h):
				var lo2 := clampf(minf(a.x, c.x), 0.0, float(w))
				var hi2 := clampf(maxf(a.x, c.x), 0.0, float(w))
				total += hi2 - lo2
	return total

func _all_axis_aligned(pts: PackedVector2Array) -> bool:
	for i in range(pts.size() - 1):
		if absf(pts[i].x - pts[i + 1].x) > 0.0001 and absf(pts[i].y - pts[i + 1].y) > 0.0001:
			return false
	return true

## First point where the polyline enters the board rectangle (board-boundary crossing).
func _entry_crossing(pts: PackedVector2Array, w: int, h: int) -> Vector2:
	for i in range(pts.size() - 1):
		var a := pts[i]
		var c := pts[i + 1]
		var a_in := a.x > 0.0 and a.x < float(w) and a.y > 0.0 and a.y < float(h)
		var c_in := c.x > 0.0 and c.x < float(w) and c.y > 0.0 and c.y < float(h)
		if not a_in and c_in:
			if absf(a.x - c.x) < 0.0001:
				return Vector2(a.x, 0.0 if a.y < 0.0 else float(h))
			return Vector2(0.0 if a.x < 0.0 else float(w), a.y)
	return Vector2(INF, INF)

## Independent oracle for a fully open board: lexicographic (interior steps, rail distance,
## side priority BOTTOM/LEFT/RIGHT/TOP) over the four aligned exits.
func _expected_exit(w: int, h: int, start: Vector2, t: Vector2i) -> Dictionary:
	var g := ScrubRailGeometry.new(w, h)
	var entry := g.bottom_entry(start.x)
	var sides := [
		{"side": 0, "d": h - 1 - t.y, "rp": Vector2(float(t.x) + 0.5, g.bottom_y()), "cross": Vector2(float(t.x) + 0.5, float(h))},
		{"side": 1, "d": t.x, "rp": Vector2(g.left_x(), float(t.y) + 0.5), "cross": Vector2(0.0, float(t.y) + 0.5)},
		{"side": 2, "d": w - 1 - t.x, "rp": Vector2(g.right_x(), float(t.y) + 0.5), "cross": Vector2(float(w), float(t.y) + 0.5)},
		{"side": 3, "d": t.y, "rp": Vector2(float(t.x) + 0.5, g.top_y()), "cross": Vector2(float(t.x) + 0.5, 0.0)},
	]
	var best: Dictionary = sides[0]
	best["rail"] = g.rail_dist(entry, best["rp"])
	for s in sides.slice(1):
		s["rail"] = g.rail_dist(entry, s["rp"])
		if s["d"] < best["d"] or (s["d"] == best["d"] and s["rail"] < best["rail"] - 0.0001):
			best = s
	return best

func _routing_regions() -> void:
	print("[3 railway-first: exit at the perimeter point nearest the target]")
	var w := 40
	var h := 40
	var starts := [Vector2(5.5, float(h) + 3.6), Vector2(33.5, float(h) + 3.6), Vector2(20.5, float(h) + 3.6)]
	var targets := {
		"left": Vector2i(3, 20), "right": Vector2i(36, 22), "top": Vector2i(18, 4), "bottom": Vector2i(25, 35),
		"deep left": Vector2i(9, 14), "deep top": Vector2i(30, 8), "deep bottom": Vector2i(12, 29),
	}
	var bad_exit: Array = []
	var bad_len: Array = []
	var bad_diag: Array = []
	var bad_valid: Array = []
	var n := 0
	for st in starts:
		for k in targets:
			var t: Vector2i = targets[k]
			var b := _open_board(w, h)
			var res = _route(b, st, t)
			n += 1
			if not res.success or not bool(res.get_meta("valid")):
				bad_valid.append("%s@%s" % [k, str(st)])
				continue
			var pts: PackedVector2Array = res.get_points()
			var want := _expected_exit(w, h, st, t)
			var cross := _entry_crossing(pts, w, h)
			if cross.distance_to(want["cross"]) > 0.001:
				bad_exit.append("%s@%s got %s want %s" % [k, str(st), str(cross), str(want["cross"])])
			var inside := _inside_len(pts, w, h)
			if absf(inside - (0.5 + float(want["d"]))) > 0.001:
				bad_len.append("%s@%s inside %.2f want %.2f" % [k, str(st), inside, 0.5 + float(want["d"])])
			if not _all_axis_aligned(pts):
				bad_diag.append(k)
			if pts[pts.size() - 1].distance_to(RouteRequest.center_of_index(b, b.get_cell_index(t.x, t.y))) > 0.001:
				bad_valid.append(k + ":end")
	_ok(bad_valid.is_empty(), "R1 %d routes are valid and end on the assigned target %s" % [n, str(bad_valid)])
	_ok(bad_exit.is_empty(), "R1 every route enters the board at the aligned perimeter point nearest the target (left / right / top / bottom / deep) %s" % str(bad_exit))
	_ok(bad_len.is_empty(), "R1 board-interior travel == 0.5 + nearest-edge distance (only the short final leg crosses the board) %s" % str(bad_len))
	_complete("r01_regions_nearest_exit")
	_ok(bad_diag.is_empty(), "R2 no diagonal/free-space segment anywhere: axis-aligned rail + straight final leg %s" % str(bad_diag))
	_complete("r02_no_diagonals_on_board")
	# The old equal-weight behaviour crossed the artwork; railway-first never does worse and improves.
	var strictly := 0
	var worse: Array = []
	var new_sum := 0.0
	var old_sum := 0.0
	for st in starts:
		for k in targets:
			var t: Vector2i = targets[k]
			var rn = _route(_open_board(w, h), st, t)
			var ro = _route(_open_board(w, h), st, t, 1.0)
			var ln := _inside_len(rn.get_points(), w, h)
			var lo := _inside_len(ro.get_points(), w, h)
			new_sum += ln
			old_sum += lo
			if ln > lo + 0.001:
				worse.append(k)
			if ln < lo - 0.5:
				strictly += 1
	_ok(worse.is_empty() and strictly >= 6 and new_sum < old_sum * 0.6, "R3 vs the pre-V02 equal-weight route: never more board travel, %d of %d strictly less; total inside-board length %.0f vs %.0f cells" % [strictly, starts.size() * targets.size(), new_sum, old_sum])
	_complete("r03_legacy_cut_through")

func _routing_blocked_and_corner() -> void:
	print("[3b blocked aligned exit + corner-adjacent targets]")
	var w := 30
	var h := 30
	# Aligned left ingress (0,15)+(1,15) blocked: the nearest OPEN perimeter cell wins.
	var block := [Vector2i(0, 15), Vector2i(1, 15)]
	var b := _open_board(w, h, block)
	var t := Vector2i(3, 15)
	var start := Vector2(4.5, float(h) + 3.6)
	var res = _route(b, start, t)
	# Independent BFS oracle: steps from the target through OPEN cells to the nearest open perimeter cell.
	var best := 1 << 30
	var dist := {}
	var q: Array = [t]
	dist[t] = 0
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c != t and (c.x == 0 or c.y == 0 or c.x == w - 1 or c.y == h - 1):
			best = mini(best, int(dist[c]))
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = c + d
			if nb.x < 0 or nb.y < 0 or nb.x >= w or nb.y >= h or dist.has(nb):
				continue
			if b.get_cell_state(b.get_cell_index(nb.x, nb.y)) != BoardState.CellState.CLEARED:
				continue
			dist[nb] = int(dist[c]) + 1
			q.append(nb)
	if b.get_cell_state(b.get_cell_index(t.x, t.y)) == BoardState.CellState.ACTIVE and (t.x == 0 or t.y == 0 or t.x == w - 1 or t.y == h - 1):
		best = 0
	var inside := _inside_len(res.get_points(), w, h)
	_ok(res.success and bool(res.get_meta("valid")) and absf(inside - (0.5 + float(best))) < 0.001 and _all_axis_aligned(res.get_points()),
		"R4 blocked aligned exit: legal route, board travel = 0.5 + %d (BFS oracle), axis-aligned (%.2f)" % [best, inside])
	_complete("r04_blocked_aligned_exit")
	# Corner-adjacent targets on every corner (open board).
	var bad: Array = []
	for corner in [Vector2i(1, 1), Vector2i(w - 2, 1), Vector2i(1, h - 2), Vector2i(w - 2, h - 2), Vector2i(0, 0), Vector2i(w - 1, h - 1), Vector2i(0, h - 1), Vector2i(w - 1, 0)]:
		for st in [Vector2(3.5, float(h) + 3.6), Vector2(26.5, float(h) + 3.6)]:
			var bb := _open_board(w, h)
			var r = _route(bb, st, corner)
			if not r.success or not bool(r.get_meta("valid")):
				bad.append("%s invalid" % str(corner))
				continue
			var want := _expected_exit(w, h, st, corner)
			var ins := _inside_len(r.get_points(), w, h)
			if absf(ins - (0.5 + float(want["d"]))) > 0.001 or not _all_axis_aligned(r.get_points()):
				bad.append("%s inside %.2f want %.2f" % [str(corner), ins, 0.5 + float(want["d"])])
			elif float(want["d"]) > 1.0:
				bad.append("%s nearest edge distance %d (expected <= 1)" % [str(corner), want["d"]])
	_ok(bad.is_empty(), "R5 corner / corner-adjacent targets: perimeter exit at most one cell from the target, no cut-through %s" % str(bad))
	_complete("r05_corner_targets")

## Real host: first-wave targets/claims identical under legacy vs railway-first travel, then a full drain.
func _wave(cost: float) -> Dictionary:
	_now[0] = T0
	await _boot(2)
	_host._routing.interior_step_cost = cost
	var clicks := _clicks(_host)
	var i := 0
	while _host.get_slots().rightmost_empty_index() != -1 and i < clicks.size():
		if _host.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
			i += 1
	var clears: Array = []
	_host.get_clearing_loop().authenticated_clear.connect(func(_o, t, c, _a): clears.append([int(t), int(c)]))
	var rt = _host.get_runtime()
	var agents: Array = []
	var seen := {}
	var w: int = _host.get_board().get_width()
	var h: int = _host.get_board().get_height()
	for _f in range(400):
		rt.tick(0.05)
		for a in _host.get_agent_layer().get_children():
			if a is ScrubbotAgent and not seen.has(a.get_instance_id()) and a.get_route_points().size() >= 2:
				seen[a.get_instance_id()] = true
				var pts: PackedVector2Array = a.get_route_points()
				agents.append({"end": Vector2i(int(floor(pts[pts.size() - 1].x)), int(floor(pts[pts.size() - 1].y))), "inside": _inside_len(pts, w, h), "diag": not _all_axis_aligned(pts)})
		if agents.size() >= 5 and not clears.is_empty():
			break
	var res_count: int = _host.get_reservations().get_reservation_count()
	# Full drain (real scheduler / input / claim path) to the terminal result.
	var supply = _host.get_supply()
	for _f in range(80000):
		if _host.get_slots().rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					_host.get_input_controller().activate_front(col)
					break
		rt.tick(1.0)
		if _host.get_completion().is_terminal():
			break
	var active_left: int = _host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	var cells: int = _host.get_board().get_cell_count()
	return {"agents": agents, "clears": clears, "won": _host.get_completion().is_won(), "active_left": active_left, "cells": cells,
		"reservations_at_wave": res_count, "reservations_end": _host.get_reservations().get_reservation_count()}

func _routing_identity() -> void:
	print("[3c travel path changes; target / claim / clear identity does not]")
	var legacy: Dictionary = await _wave(1.0)
	var fresh: Dictionary = await _wave(ProductionRoutingSystem.INTERIOR_STEP_COST)
	var la: Array = legacy["agents"]
	var fa: Array = fresh["agents"]
	var m := mini(la.size(), fa.size())
	_ok(m >= 5, "both runs spawned a first wave (%d / %d agents)" % [la.size(), fa.size()])
	var same := true
	for i in range(m):
		same = same and la[i]["end"] == fa[i]["end"]
	_ok(same, "R6 the first %d spawned Scrubbots are assigned the SAME target cells in the same order (route cost never changes WHAT)" % m)
	var diag_new := fa.any(func(a): return a["diag"])
	var ins_new := 0.0
	var ins_old := 0.0
	for i in range(m):
		ins_new += float(fa[i]["inside"])
		ins_old += float(la[i]["inside"])
	_ok(not diag_new and ins_new <= ins_old + 0.001, "wave routes are axis-aligned; board travel %.1f vs %.1f cells (never more than before)" % [ins_new, ins_old])
	var ce: Array = fresh["clears"].map(func(x): return x[0])
	var cl: Array = legacy["clears"].map(func(x): return x[0])
	var uniq := {}
	for t in ce:
		uniq[t] = true
	_ok(fresh["won"] and legacy["won"] and fresh["active_left"] == 0 and legacy["active_left"] == 0, "both runs finish WON with the whole board CLEARED (solver / completion truth intact)")
	_ok(ce.size() == uniq.size() and ce.size() == fresh["cells"] and cl.size() == legacy["cells"], "every cell cleared exactly once (%d / %d) in both runs" % [ce.size(), fresh["cells"]])
	var ident := true
	var a_sorted: Array = fresh["clears"].duplicate()
	var b_sorted: Array = legacy["clears"].duplicate()
	a_sorted.sort()
	b_sorted.sort()
	ident = a_sorted == b_sorted
	_ok(ident and fresh["reservations_end"] == 0 and legacy["reservations_end"] == 0, "identical (target, colour) clear sets; zero reservations left (claim/reservation conservation)")
	_complete("r06_target_identity")

# ============================================================ 4 grid ============

func _grid() -> void:
	print("[4 dynamic pixel grid / bevel]")
	var dims := [Vector2i(20, 20), Vector2i(32, 32), Vector2i(38, 38), Vector2i(59, 59), Vector2i(20, 59), Vector2i(59, 20), Vector2i(3, 2)]
	var last_alpha := 2.0
	var alphas: Array = []
	var ok_dims := true
	var ok_shader := true
	for d in dims:
		var board := BoardDebugFixtures.make_board(d.x, d.y)
		var r := BoardRenderer.new()
		r.configure(board, PackedStringArray(BoardDebugFixtures.PALETTE), Vector2(d.x * 20.0, d.y * 20.0))
		var m := r.get_grid_material()
		ok_dims = ok_dims and m != null and m.get_shader_parameter("grid_size") == Vector2(float(d.x), float(d.y))
		alphas.append([d, m.get_shader_parameter("gutter_alpha") if m != null else -1.0, m.get_shader_parameter("bevel_strength") if m != null else -1.0])
		r.free()
	var code: String = load("res://scripts/gameplay/board/board_pixel_grid.gdshader").code
	ok_shader = code.find("uniform vec2 grid_size") != -1 and code.find("sampler2D") == -1 and code.find("TEXTURE") != -1
	_ok(ok_dims, "G1 grid_size uniform == the real logical width x height for %d different dimensions (incl. rectangular 20x59 / 59x20)" % dims.size())
	_ok(ok_shader, "G1 shader has no fixed mask texture (only the renderer's own texture + grid_size)")
	var mono := true
	var a20: float = alphas[0][1]
	var a59: float = alphas[3][1]
	mono = a20 > a59 and float(alphas[0][2]) > float(alphas[3][2]) and float(alphas[1][1]) < a20 and float(alphas[1][1]) > a59
	_ok(mono, "G1 line/bevel strength adapts to resolution (20x20 %.2f/%.2f > 32x32 > 59x59 %.2f/%.2f)" % [a20, alphas[0][2], a59, alphas[3][2]])
	_complete("g01_dynamic_grid_dims")
	# Presentation only: palette colours, ACTIVE/CLEARED truth and cell geometry untouched.
	var board := BoardDebugFixtures.make_board(24, 18)
	var pal := PackedStringArray(BoardDebugFixtures.PALETTE)
	var plain := BoardRenderer.new()
	plain.set_grid_enabled(false)
	plain.configure(board, pal, Vector2(24 * 16.0, 18 * 16.0))
	var styled := BoardRenderer.new()
	styled.configure(board, pal, Vector2(24 * 16.0, 18 * 16.0))
	var same_px := true
	var same_geo := plain.get_cell_size() == styled.get_cell_size() and plain.get_board_pixel_size() == styled.get_board_pixel_size()
	for y in range(18):
		for x in range(24):
			same_px = same_px and plain.get_pixel_color(x, y) == styled.get_pixel_color(x, y)
			same_geo = same_geo and plain.get_cell_center_local(x, y) == styled.get_cell_center_local(x, y) and plain.get_cell_center_global(x, y) == styled.get_cell_center_global(x, y)
	_ok(plain.get_grid_material() == null and styled.get_grid_material() != null and same_px and same_geo, "G2 grid on vs off: identical palette pixels, cell size, board size and every cell centre (target/hit coordinates unchanged)")
	_complete("g02_presentation_only")
	# Clearing repaints the cell transparent; the shader alpha-gates on that cell's own texel.
	var idx := board.get_cell_index(5, 7)
	board.set_cell_state(idx, BoardState.CellState.CLEARED)
	styled.update_cells([idx])
	_ok(styled.get_pixel_color(5, 7).a == 0.0 and styled.get_pixel_color(6, 7).a == 1.0 and styled.get_grid_material() != null and load("res://scripts/gameplay/board/board_pixel_grid.gdshader").code.find("base.a < 0.5") != -1,
		"G3 CLEARED cell texel is alpha 0 and the shader emits fully transparent for it (no ghost grid/tile); neighbours untouched. Rendered-pixel proof: tests/tools/board_grid_probe.gd")
	_complete("g03_no_ghost_after_clear")
	var big := BoardRenderer.new()
	big.configure(BoardDebugFixtures.make_board(59, 59), pal, Vector2(59 * 12.0, 59 * 12.0))
	get_root().add_child(big)
	var nodes := big.find_children("*", "", true, false).size()
	_ok(nodes == 0 and big.get_child_count() == 0, "G4 59x59 board (3481 cells): still ONE TextureRect, %d child nodes (no per-cell nodes)" % nodes)
	big.queue_free()
	plain.free()
	styled.free()
	_complete("g04_no_node_explosion")

# ============================================================ 5 Home ============

func _home() -> void:
	print("[5 Home background = the owner-selected home_background.png]")
	await _boot(0)
	var home = _root.get_home()
	await _settle()
	var wb: TextureRect = home.get_region("WorldBackground")
	var tex: Texture2D = wb.texture
	_ok(FileAccess.get_sha256(HOME_BG) == HOME_BG_SHA and tex != null and tex.resource_path == HOME_BG and tex.get_width() == 940 and tex.get_height() == 1672,
		"H1 WorldBackground renders exactly %s (940x1672, sha256 matches the owner-selected file)" % HOME_BG)
	var binder := HomeArtBinder.new()
	_ok(binder.state("home_background_whispering_park") == "APPROVED_BOUND" and binder.texture("home_background_whispering_park") == tex, "H1 the bound texture is the manifest-approved HOME-121 entry")
	var world: Dictionary = home.get_world()
	_ok(world["background_slug"] == "home_background_whispering_park" and world["canvas"] == Vector2(940, 1672), "H1 catalog world_01 -> home_background_whispering_park @ 940x1672")
	_ok(absf(wb.size.x / wb.size.y - 940.0 / 1672.0) < 0.001, "H1 drawn at the image's own aspect (uniform scale, never stretched)")
	_complete("h01_home_uses_exact_asset")
	# No stale background: nothing else draws the old world / layered backgrounds.
	var drawn: Array = []
	for n in home.find_children("*", "TextureRect", true, false):
		var t: Texture2D = (n as TextureRect).texture
		if t != null and (n as CanvasItem).is_visible_in_tree():
			drawn.append(t.resource_path)
	var stale: Array = drawn.filter(func(p): return String(p).find("worlds/world_01") != -1 or String(p).find("home_bg_") != -1)
	var count_bg: int = drawn.count(HOME_BG)
	_ok(stale.is_empty() and count_bg == 1, "H2 the new background is drawn once; no old world / layered background texture is visible (%d, stale %s)" % [count_bg, str(stale)])
	var wb_index: int = wb.get_index()
	var bgnode: Node = home.get_region("Background")
	_ok(bgnode.get_child(0) == wb or bgnode.get_child(0).name == "WorldBackground", "H2 the background is the bottom-most world layer")
	_complete("h02_no_stale_background")
	# Live UI intact.
	var names := ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily", "Nav_events", "Nav_robots", "Nav_home", "Nav_leaderboard", "Nav_settings", "GiftMeter", "ScrubBucksChip"]
	var missing: Array = []
	for n in names:
		if home.get_region(n) == null:
			missing.append(n)
	var play: Button = home.get_region("PlayButton")
	_ok(missing.is_empty() and play != null and not play.disabled and home.get_region("Art_scrubby").texture != null, "H3 PLAY, 4 shortcuts, 5 nav buttons, Gift Meter, currency chip and Scrubby are live native nodes %s" % str(missing))
	var baked_ui := 0
	for p in drawn:
		if String(p).find("play_button") != -1 and String(p) != "res://assets/ui/final/home/play_cta/play_button_frame.png":
			baked_ui += 1
	_ok(baked_ui == 0, "H3 no live UI is baked into the background layer")
	_complete("h03_live_ui_intact")

# ------------------------------------------------------------------ helpers ----

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if msg.is_empty():
		return
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
	print("M28-C002-C003-R01 five-finding remediation: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
