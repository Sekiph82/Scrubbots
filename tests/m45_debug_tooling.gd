extends SceneTree
## M45 Debug Tooling (SB-M45-001..018) — evidence against the REAL ProductionGameplayHost
## inside the developer harness scenes/debug/m45_debug_gameplay.tscn (no AppState, private
## economy, no save), stepped deterministically through ProductionRuntimeController.tick().
##
## Run: godot --headless --path . -s res://tests/m45_debug_tooling.gd

const HarnessScene = preload("res://scenes/debug/m45_debug_gameplay.tscn")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const GameplayDebugOverlay = preload("res://scripts/debug/gameplay_debug_overlay.gd")
const GameplayDebugLayer = preload("res://scripts/debug/gameplay_debug_layer.gd")
const GameplayDebugModel = preload("res://scripts/debug/gameplay_debug_model.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

var EXPECTED_CASES := [
	"d01_model_matches_engine", "d02_live_targets_routes_grid", "d03_read_only",
	"d04_toggles_real_effects_switch", "d05_instant_reset", "d06_level_switcher",
	"d07_release_gate_not_in_app", "d08_single_node_largest_level",
]

var _fail := 0
var _completed: Dictionary = {}
var _sub: SubViewport
var _h = null
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _boot()
	_d01()
	_d02()
	_d03()
	_d04()
	_d05()
	_d06()
	await _d07()
	_d08()
	_shutdown()
	_done()

# ------------------------------------------------------------------ cases ----

func _d01() -> void:
	print("[d01 model == live engine values (L1)]")
	var host = _h.get_host()
	var ov = _h.get_overlay()
	ov.refresh()
	var m: Dictionary = ov.get_model()
	var b = host.get_board()
	var e = _h.get_catalog().get_entry_by_id(_h.get_entry_id())
	_ok(bool(m["built"]) and String(m["level_id"]) == String(e.id) and String(m["difficulty"]) == String(e.difficulty), "level id / difficulty from the catalog entry %s %s" % [m["level_id"], m["difficulty"]])
	_ok(int(m["width"]) == b.get_width() and int(m["height"]) == b.get_height() and int(m["cells"]) == b.get_cell_count() and int(m["artwork_cells"]) == b.get_artwork_cell_count(), "dimensions / cell counts")
	_ok(int(m["active"]) == b.count_cells_by_state(BoardState.CellState.ACTIVE) and int(m["cleared"]) == b.count_cells_by_state(BoardState.CellState.CLEARED), "ACTIVE / CLEARED counts")
	_ok(int(m["reserved"]) == host.get_reservations().get_reservation_count() and int(m["active_bots"]) == host.get_dispatcher().get_active_count(), "reserved / active bots")
	_ok(is_finite(float(m["fps"])) and float(m["fps"]) >= 0.0 and is_finite(float(m["frame_ms"])) and float(m["frame_ms"]) >= 0.0, "FPS / frame time finite")
	_ok(ov.get_text() == GameplayDebugModel.to_text(m) and ov.get_text().contains(String(e.id)), "HUD text shows the model")
	_complete("d01_model_matches_engine")

func _d02() -> void:
	print("[d02 live: target markers == reserved cells, one route per live agent, grid lines]")
	var host = _h.get_host()
	var ov = _h.get_overlay()
	var ok_dispatch := _drive_until_bots(host)
	ov.refresh()
	var m: Dictionary = ov.get_model()
	var dm: Dictionary = ov.get_debug_layer().get_draw_model()
	var reserved: Array = Array(host.get_reservations().get_reserved_indices())
	reserved.sort()
	var marked: Array = dm["targets"].map(func(t): return int(t["index"]))
	marked.sort()
	_ok(ok_dispatch and int(m["active_bots"]) > 0 and int(m["reserved"]) == reserved.size(), "real dispatch observed: bots %d, reserved %d" % [int(m["active_bots"]), int(m["reserved"])])
	_ok(marked == reserved and not marked.is_empty(), "markers exactly the reserved target cells %s" % str(marked))
	var b = host.get_board()
	var centers_ok := true
	for t in dm["targets"]:
		var c: Vector2i = b.get_cell_position(int(t["index"]))
		centers_ok = centers_ok and (t["center"] as Vector2).is_equal_approx(Vector2(c.x + 0.5, c.y + 0.5))
	_ok(centers_ok, "markers at cell centres (board-local)")
	var agents := 0
	for a in host.get_agent_layer().get_children():
		if a.has_method("get_route_points") and a.get_route_points().size() >= 2:
			agents += 1
	_ok(dm["routes"].size() == agents and agents > 0, "one route per live routed agent (%d)" % agents)
	_ok(dm["grid"].size() == (b.get_width() + 1) + (b.get_height() + 1), "grid lines (W+1)+(H+1)")
	_ok(ov.get_debug_layer().transform == host.get_agent_layer().transform and ov.get_debug_layer().get_parent() == host.get_agent_layer().get_parent(), "debug layer shares the agents' board-local transform")
	_complete("d02_live_targets_routes_grid")

func _d03() -> void:
	print("[d03 overlay is read-only]")
	var host = _h.get_host()
	var ov = _h.get_overlay()
	var b = host.get_board()
	var pre := [b.get_revision(), JSON.stringify(host.get_slots().snapshot()), JSON.stringify(host.get_supply().player_snapshot()),
		JSON.stringify(host.get_economy().snapshot()), host.get_reservations().get_reservation_count(), host.get_dispatcher().get_active_count()]
	for _i in range(5):
		ov.refresh()
		ov.get_debug_layer().refresh()
		GameplayDebugLayer.build_draw_model(host)
		GameplayDebugModel.capture(host, {})
	var post := [b.get_revision(), JSON.stringify(host.get_slots().snapshot()), JSON.stringify(host.get_supply().player_snapshot()),
		JSON.stringify(host.get_economy().snapshot()), host.get_reservations().get_reservation_count(), host.get_dispatcher().get_active_count()]
	_ok(pre == post, "board revision / slots / supply / economy / reservations / agents unchanged")
	_complete("d03_read_only")

func _d04() -> void:
	print("[d04 toggles: real cleaning-effects switch; layer content toggles]")
	var host = _h.get_host()
	var ov = _h.get_overlay()
	ov.get_toggle("effects").button_pressed = false
	_ok(not host.get_cleaning_fx().is_effects_enabled(), "EFFECTS off -> CleaningEffectsController disabled")
	ov.get_toggle("effects").button_pressed = true
	_ok(host.get_cleaning_fx().is_effects_enabled(), "EFFECTS on again")
	ov.get_toggle("targets").button_pressed = false
	ov.get_toggle("grid").button_pressed = false
	ov.get_toggle("routes").button_pressed = false
	var dm: Dictionary = ov.get_debug_layer().get_draw_model()
	_ok(dm["targets"].is_empty() and dm["grid"].is_empty() and dm["routes"].is_empty(), "markers / grid / routes off")
	for id in ["targets", "grid", "routes"]:
		ov.get_toggle(id).button_pressed = true
	_ok(not ov.get_debug_layer().get_draw_model()["grid"].is_empty(), "back on")
	_complete("d04_toggles_real_effects_switch")

func _d05() -> void:
	print("[d05 instant reset = existing transaction-safe Retry]")
	var host = _h.get_host()
	for _i in range(60):
		host.get_runtime().tick(0.1)
	var ok: bool = _h.instant_reset()
	var m: Dictionary = _h.get_overlay().get_model()
	var b = host.get_board()
	_ok(ok and _h.get_host() == host, "Retry accepted on the same host")
	_ok(int(m["active"]) == b.get_artwork_cell_count() and int(m["cleared"]) == b.get_cell_count() - b.get_artwork_cell_count() and int(m["reserved"]) == 0 and int(m["active_bots"]) == 0, "fresh attempt: all artwork ACTIVE, no reservation / bot %s" % GameplayDebugModel.to_text(m).replace("\n", " | "))
	_complete("d05_instant_reset")

func _d06() -> void:
	print("[d06 level switcher rebuilds a fresh host from the catalog entry]")
	var old = _h.get_host()
	var e = _h.get_catalog().get_entry_by_id("level_002_apple")
	_ok(_h.load_entry("level_002_apple"), "switch to level_002_apple")
	var host = _h.get_host()
	var m: Dictionary = _h.get_overlay().get_model()
	_ok(host != old and host.is_built() and String(m["level_id"]) == "level_002_apple" and int(m["width"]) == int(e.width) and int(m["height"]) == int(e.height), "model = new level %dx%d" % [int(m["width"]), int(m["height"])])
	var hosts := 0
	for c in _h.get_children():
		if c.has_method("get_board"):
			hosts += 1
	_ok(hosts == 1 and host.supply_plan_path == String(e.supply_plan_path), "exactly one host; entry SupplyPlan used")
	_ok(not _h.load_entry("no_such_level") and _h.get_host() == host, "unknown id refused, current host kept")
	_complete("d06_level_switcher")

func _d07() -> void:
	print("[d07 release gate; nothing in the shipping app]")
	_ok(not GameplayDebugOverlay.is_allowed(func(f): return f == "template") and GameplayDebugOverlay.is_allowed(func(_f): return false), "template builds: denied; dev runs: allowed")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	get_root().add_child(sub)
	var path := "user://m45_app_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	for _i in range(4):
		await process_frame
	root.play_current_frontier()
	for _i in range(6):
		await process_frame
	var found: Array = root.find_children("GameplayDebug*", "", true, false)
	_ok(root.get_gameplay_host() != null and found.is_empty(), "real app gameplay: no debug overlay / layer node")
	var refs := 0
	for f in ["res://scripts/app/main.gd", "res://scripts/gameplay/runtime/production_gameplay_host.gd", "res://scripts/ui/gameplay_screen.gd", "res://scripts/ui/home/home_screen.gd"]:
		if FileAccess.get_file_as_string(f).contains("gameplay_debug"):
			refs += 1
	_ok(refs == 0, "no shipping script references the debug tooling")
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	_complete("d07_release_gate_not_in_app")

func _d08() -> void:
	print("[d08 one debug node regardless of board size (largest catalog level)]")
	var best = null
	for e in _h.get_catalog().get_entries_ordered():
		if best == null or int(e.width) * int(e.height) > int(best.width) * int(best.height):
			best = e
	_ok(_h.load_entry(String(best.id)), "loaded largest level %s %dx%d" % [best.id, int(best.width), int(best.height)])
	var layer = _h.get_overlay().get_debug_layer()
	_ok(layer is Node2D and layer.get_child_count() == 0 and layer.get_draw_model()["grid"].size() == int(best.width) + int(best.height) + 2, "single Node2D, no per-cell nodes; %d grid lines" % layer.get_draw_model()["grid"].size())
	_complete("d08_single_node_largest_level")

# ------------------------------------------------------------------ helpers ----

func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_h = HarnessScene.instantiate()
	_sub.add_child(_h)
	for _i in range(4):
		await process_frame
	_h.get_host().get_runtime().set_process(false)

## Place real front batches (same loop as m55_long_session._drive) and step the real runtime
## until bots are out (bounded). Diagnostics are printed when no dispatch is observed.
func _drive_until_bots(host) -> bool:
	var rt = host.get_runtime()
	rt.set_process(false)
	var input = host.get_input_controller()
	var log: Array = []
	for _round in range(10):
		if host.get_slots().rightmost_empty_index() != -1:
			for col in range(host.get_supply().get_column_count()):
				var r: Dictionary = input.activate_front(col)
				log.append("%d:%s:%s" % [col, str(r.get("ok", false)), str(r.get("error", ""))])
				if bool(r.get("ok", false)):
					break
		for _i in range(20):
			rt.tick(0.1)
			if host.get_dispatcher().get_active_count() > 0 and host.get_reservations().get_reservation_count() > 0:
				return true
	var occupied: int = host.get_slots().snapshot().filter(func(s): return bool(s.get("occupied", false))).size()
	print("    diag: activations %s paused=%s terminal=%s occupied_slots=%d bound=%s" % [str(log), str(rt.is_paused()), str(host.get_completion().is_terminal()), occupied, str(rt.is_bound())])
	return false

func _shutdown() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_sub = null
	_h = null

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
	print("M45 debug tooling evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
