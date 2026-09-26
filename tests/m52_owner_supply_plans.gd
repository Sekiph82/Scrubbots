extends SceneTree
## M52-C001 owner batch integration — direct assertions for the owner supply plans
## (data/levels/supply/*_supply_v1.json) and the shipping SupplyPlanLoader seam.
##
## Covers: plan == owner markdown (exact queues + intended clicks + provenance hash);
## global Cxx -> local palette mapping (never Cxx == index); fail-closed loader on
## malformed/missing/adversarial plans; per-level queue exactness, hidden FIFO depth > 3,
## max batch <= 30, per-color + grand conservation; recorded canonical SOLVED evidence
## re-validated by replaying the solver trace here; the owner intended click sequence
## replayed through the real ProofKernel; ProductionGameplayHost starting each level
## with the exact plan queues (3 visible rows, hidden depth kept) and reaching WON via
## production input; catalog/resolver propagation + fail-closed; Level 1 unchanged.
##
## Run: godot --headless --path . -s res://tests/m52_owner_supply_plans.gd

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const PLAN_LEVELS := ["level_002_apple", "level_003_palm_tree", "level_004_orange_cat", "level_005_party_toucan",
	"level_006_chicken", "level_007_pigeon", "level_008_butterfly", "level_009_frog",
	"level_010_ice_cube"]
const EVIDENCE_DIR := "res://coordination/sessions/M52-C001/evidence/owner_plans"

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_mapping_seam()
	_fail_closed()
	for id in PLAN_LEVELS:
		_plan_matches_owner_markdown(id)
		_plan_static(id)
		_solver_evidence(id)
	for id in PLAN_LEVELS:
		await _runtime(id)
	_catalog_and_resolver()
	await _level_1_unchanged()
	_cleanup()
	_done()

static func plan_path(id: String) -> String:
	return "res://data/levels/supply/%s_supply_v1.json" % id

func _level(id: String):
	return LevelLoader.load_from_path(Pack.level_path(id)).level_data

# --- Cxx global -> local palette mapping ---------------------------------------
func _mapping_seam() -> void:
	print("[Cxx -> local palette mapping]")
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	for id in PLAN_LEVELS:
		var lvl = _level(id)
		var m: Dictionary = SupplyPlanLoader.cid_to_local_map(lvl)["map"]
		var ok: bool = m.size() == lvl.palette.size()
		for cid in m:
			ok = ok and String(lvl.palette[m[cid]]).to_upper() == auth["cid_to_hex"][cid]
		_ok(ok, "%s: every Cxx maps to the local palette entry with the identical color (%s)" % [id, str(m)])
	var ice: Dictionary = SupplyPlanLoader.cid_to_local_map(_level("level_010_ice_cube"))["map"]
	_ok(ice["C08"] == 5 and ice["C16"] == 9 and ice["C02"] == 0, "Ice Cube: C08->5, C16->9, C02->0 (global id is NOT the local index)")
	var pigeon: Dictionary = SupplyPlanLoader.cid_to_local_map(_level("level_007_pigeon"))["map"]
	_ok(pigeon["C08"] == 1 and not pigeon.has("C02"), "Pigeon: C08->1; C02 absent from its palette")

# --- adversarial / fail-closed ---------------------------------------------------
func _fail_closed() -> void:
	print("[loader fail-closed]")
	var lvl = _level("level_010_ice_cube")
	var good: Dictionary = SupplyPlanLoader.load_plan(plan_path("level_010_ice_cube"))["plan"]
	_ok(SupplyPlanLoader.build_engine(good, lvl)["ok"], "baseline plan loads")
	_ok(not SupplyPlanLoader.load_engine("res://data/levels/supply/does_not_exist.json", lvl)["ok"], "missing plan file fails closed")
	var bad_json := _write_tmp("bad", "{ not json")
	_ok(not SupplyPlanLoader.load_engine(bad_json, lvl)["ok"], "malformed JSON fails closed")
	var cases := {
		"wrong schema": func(p): p["schema"] = "x",
		"levelId mismatch": func(p): p["levelId"] = "level_009_frog",
		"two columns": func(p): p["columns"].pop_back(),
		"preview depth 4": func(p): p["visiblePreviewDepth"] = 4,
		"batch 31": func(p): p["columns"][0][0]["robots"] = 31,
		"batch 0": func(p): p["columns"][0][0]["robots"] = 0,
		"fractional batch": func(p): p["columns"][0][0]["robots"] = 29.5,
		"conservation -1": func(p): p["columns"][0][0]["robots"] = 29,
		"Cxx absent from level palette": func(p): p["columns"][0][0]["cid"] = "C01",
		"off-palette Cxx": func(p): p["columns"][0][0]["cid"] = "C99",
		"duplicate batchId": func(p): p["columns"][1][0]["batchId"] = p["columns"][0][0]["batchId"],
		"maxRobotsPerBatch 31": func(p): p["maxRobotsPerBatch"] = 31,
	}
	for name in cases:
		var p = JSON.parse_string(JSON.stringify(good))
		cases[name].call(p)
		var r: Dictionary
		if name == "wrong schema":
			r = SupplyPlanLoader.load_engine(_write_tmp("schema", JSON.stringify(p)), lvl)
		else:
			r = SupplyPlanLoader.build_engine(p, lvl)
		_ok(not r["ok"] and not r.has("engine"), "%s fails closed (%s)" % [name, r.get("error", "")])
	# Owner Level 002 Apple V01 layout vs the committed Apple LevelData (known blocker).
	var apple = _level("level_002_apple")
	var apple_plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "level_002_apple",
		"columnCount": 3, "visiblePreviewDepth": 3, "maxRobotsPerBatch": 30,
		"columns": [[{"batchId": "a", "cid": "C16", "robots": 30}], [{"batchId": "b", "cid": "C08", "robots": 30}], [{"batchId": "c", "cid": "C01", "robots": 30}]]}
	_ok(not SupplyPlanLoader.build_engine(apple_plan, apple)["ok"], "C16 plan against Apple (no C16 in its palette) fails closed")

# --- plan == owner markdown ------------------------------------------------------
func _plan_matches_owner_markdown(id: String) -> void:
	print("[%s plan == owner input]" % id)
	var plan: Dictionary = SupplyPlanLoader.load_plan(plan_path(id))["plan"]
	var md_path := "res://" + String(plan["ownerInput"])
	var md := FileAccess.get_file_as_string(md_path).replace("\r\n", "\n")
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(md.to_utf8_buffer())
	_ok(ctx.finish().hex_encode() == plan["ownerInputSha256"], "owner input hash matches recorded provenance")
	var col_re := RegEx.create_from_string("### Column (\\d)[^\\n]*\\n+```text\\n([\\s\\S]*?)```")
	var md_cols: Array = []
	for m in col_re.search_all(md):
		var q: Array = []
		for line in m.get_string(2).strip_edges().split("\n"):
			var parts := line.strip_edges().split(" ")
			var cb := parts[1].split("-")
			q.append([cb[0], int(cb[1])])
		md_cols.append(q)
	var plan_cols: Array = []
	for col in plan["columns"]:
		var q: Array = []
		for b in col:
			q.append([String(b["cid"]), int(b["robots"])])
		plan_cols.append(q)
	_ok(md_cols.size() == 3 and md_cols == plan_cols, "plan columns == owner markdown columns exactly (order, color, count)")
	var click_re := RegEx.create_from_string("## Intended column-click sequence[\\s\\S]*?```text\\n([\\s\\S]*?)```")
	var cm := click_re.search(md)
	var md_clicks: Array = []
	for ch in cm.get_string(1):
		if ch >= "1" and ch <= "3":
			md_clicks.append(int(ch))
	var plan_clicks: Array = []
	for c in plan["intendedColumnClicks"]:
		plan_clicks.append(int(c))
	_ok(md_clicks == plan_clicks, "plan intended clicks == owner markdown (%d clicks)" % md_clicks.size())

# --- static queue checks -------------------------------------------------------------
func _plan_static(id: String) -> void:
	print("[%s static]" % id)
	var lvl = _level(id)
	var r := SupplyPlanLoader.load_engine(plan_path(id), lvl)
	_ok(r["ok"], "plan loads through shipping loader %s" % r["error"])
	if not r["ok"]:
		return
	var eng = r["engine"]
	var dbg: Dictionary = eng.debug_snapshot()
	_ok(int(dbg["column_count"]) == 3 and int(dbg["preview_depth"]) == 3, "3 FIFO columns, preview depth 3")
	var max_len := 0
	var max_b := 0
	var sums := {}
	var batches := 0
	for col in dbg["columns"]:
		max_len = maxi(max_len, col.size())
		for b in col:
			max_b = maxi(max_b, int(b["robot_count"]))
			sums[int(b["color_id"])] = int(sums.get(int(b["color_id"]), 0)) + int(b["robot_count"])
			batches += 1
	_ok(max_len > 3, "hidden FIFO depth preserved (deepest column %d > 3 visible rows)" % max_len)
	_ok(max_b <= 30, "max batch %d <= 30" % max_b)
	_ok(sums == BatchSupplyGenerator.color_totals(lvl), "per-color conservation exact")
	var grand := 0
	for c in sums:
		grand += int(sums[c])
	_ok(grand == lvl.get_cell_count(), "grand total %d == cells" % grand)
	var ps = ProofState.from_level_and_supply(lvl, eng)
	var ps_total := 0
	for q in ps.supply:
		ps_total += q.size()
	_ok(ps_total == batches, "solver ProofState holds all %d batches (hidden rows included)" % batches)

# --- canonical solver evidence (re-validated) -----------------------------------------
func _solver_evidence(id: String) -> void:
	print("[%s solver evidence]" % id)
	var ev = JSON.parse_string(FileAccess.get_file_as_string("%s/%s_verification.json" % [EVIDENCE_DIR, id]))
	_ok(typeof(ev) == TYPE_DICTIONARY and bool(ev.get("pass", false)), "verification evidence present and PASS")
	if typeof(ev) != TYPE_DICTIONARY or not ev.has("solver"):
		return
	_ok(ev["planSha256"] == Pack.content_sha256(plan_path(id)) and ev["levelSha256"] == Pack.content_sha256(Pack.level_path(id)), "evidence bound to current plan + LevelData bytes")
	var sol: Dictionary = ev["solver"]
	_ok(sol["status"] == "SOLVED" and bool(sol["fullQueueConsumed"]), "canonical SolvabilitySolver: SOLVED, full queue consumed (visited %d, decisions %d)" % [int(sol["visited"]), int(sol["decisions"])])
	_ok(bool(ev["intendedSequence"]["pass"]) and int(ev["intendedSequence"]["finalActive"]) == 0 and ev["intendedSequence"]["supplyExhausted"] and ev["intendedSequence"]["slotsEmpty"], "recorded owner intended sequence: ACTIVE 0, supply exhausted, slots empty")
	# Replay the recorded solver trace here against a fresh plan-loaded state.
	var lvl = _level(id)
	var eng = SupplyPlanLoader.load_engine(plan_path(id), lvl)["engine"]
	var trace: Array = sol["trace"]
	_ok(SolvabilitySolver._trace_hash(trace) == int(sol["traceHash"]), "recorded trace re-hashes to %d" % int(sol["traceHash"]))
	var rep: Dictionary = SolvabilitySolver.new().replay(ProofState.from_level_and_supply(lvl, eng), trace)
	_ok(rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0, "solver trace replays to exact completion (%d steps)" % int(rep["steps"]))
	# Owner intended clicks through the real kernel, re-run here.
	var k = ProofKernel.new()
	var st = k.quiesce(ProofState.from_level_and_supply(lvl, eng))["state"]
	var legal := true
	for c in ev["intendedSequence"]["clicks"]:
		var col := int(c) - 1
		if not st.legal_action_columns().has(col):
			legal = false
			break
		st = k.apply_placement(st, col)["state"]
	_ok(legal and st.active_count() == 0 and st.is_supply_exhausted() and st.occupied_slot_count() == 0, "owner intended clicks replay: all legal, ACTIVE 0, supply exhausted, slots empty")

# --- production runtime --------------------------------------------------------------------
func _runtime(id: String) -> void:
	print("[%s production runtime]" % id)
	# Shipping path: AppState frontier -> production catalog -> resolver -> host.
	var order := PLAN_LEVELS.find(id) + 2
	var app = AppState.new(_uniq("rt_%s" % id))
	for n in range(1, order):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "host builds from AppState frontier %d %s" % [order, h.get_build_error()])
	if not h.is_built():
		h.free()
		return
	_ok(h.launch_entry_id == id and h.progression_level == order and h.supply_plan_path == plan_path(id), "frontier %d resolved to %s with its owner plan" % [order, h.launch_entry_id])
	var lvl = _level(id)
	var expected = SupplyPlanLoader.load_engine(plan_path(id), lvl)["engine"].debug_snapshot()["columns"]
	var supply = h.get_supply()
	_ok(JSON.stringify(supply.debug_snapshot()["columns"]) == JSON.stringify(expected), "runtime supply == accepted owner queues before any click")
	var visible_ok := true
	var hidden_ok := false
	var snap: Array = supply.player_snapshot()
	for c in range(3):
		visible_ok = visible_ok and supply.get_preview(c).size() <= 3 and int(snap[c]["remaining"]) == expected[c].size()
		hidden_ok = hidden_ok or expected[c].size() > 3
	_ok(visible_ok and hidden_ok, "player sees <= 3 rows per column; authoritative queue keeps hidden depth")
	var plan: Dictionary = SupplyPlanLoader.load_plan(plan_path(id))["plan"]
	var won := await _play_clicks(h, plan["intendedColumnClicks"])
	_ok(won, "owner click sequence via production input -> WON, board clear, supply exhausted, slots empty")
	h.free()

## Click each owner column through ProductionInputController, letting the real runtime
## run to quiescence between clicks (same serial order the proof kernel uses).
func _play_clicks(h, clicks: Array) -> bool:
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	runtime.set_process(false)
	var scheduler = h.get_scheduler()
	var slots = h.get_slots()
	var supply = h.get_supply()
	for c in clicks:
		var r: Dictionary = input.activate_front(int(c) - 1)
		if not r.get("ok", false):
			print("    click %d rejected: %s" % [int(c), str(r)])
			return false
		for _i in range(20000):
			runtime.tick(1.0)
			if scheduler.live_assignment_count() == 0 and not _any_moving(h.get_agent_layer()) and slots.rightmost_empty_index() != -1:
				break
	for _i in range(200):
		if h.get_completion().is_terminal():
			break
		runtime.tick(1.0)
	return h.get_completion().is_won() and h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == 0 \
		and supply.is_exhausted() and slots.rightmost_empty_index() != -1 and _slots_empty(slots)

func _slots_empty(slots) -> bool:
	for s in slots.snapshot():
		if bool(s["occupied"]):
			return false
	return true

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for ch in agent_layer.get_children():
		if ch.has_method("is_moving") and ch.is_moving():
			return true
	return false

# --- catalog / resolver ------------------------------------------------------------------------
func _catalog_and_resolver() -> void:
	print("[catalog + resolver]")
	var cat = LevelCatalog.new()
	var lr = cat.load_manifest()
	_ok(lr.ok, "production catalog validates (plans loaded fail-closed) %s" % lr.summary())
	var got: Array = cat.get_entries_ordered()
	var expect_ids: Array = ["m21_level_001_hazard_bot"] + PLAN_LEVELS
	var ids: Array = []
	var orders: Array = []
	for e in got:
		ids.append(e.id)
		orders.append(e.order)
	_ok(got.size() == 10 and ids == expect_ids and orders == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "production catalog is exactly orders 1..10 -> %s" % str(ids))
	for e in got:
		var want := "" if e.order == 1 else plan_path(e.id)
		_ok(e.supply_plan_path == want, "order %d plan path '%s'" % [e.order, e.supply_plan_path])
	var app = AppState.new(_uniq("res"))
	for n in range(1, 11):
		var r: Dictionary = GameplayLaunchResolver.resolve(app)
		_ok(r["ok"] and int(r["level"]) == n and r["entry_id"] == expect_ids[n - 1], "frontier %d -> %s" % [n, r.get("entry_id", r.get("reason"))])
		app.progression.record_win(n)
	_ok(GameplayLaunchResolver.resolve(app)["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "frontier 11 -> CONTENT_MISSING")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(LevelCatalog.DEFAULT_MANIFEST_PATH))["entries"]
	# fail-closed catalog entries
	var bad := entries.duplicate(true)
	bad[1]["supply_plan_path"] = "res://data/levels/supply/missing.json"
	_ok(not LevelCatalog.new().load_manifest(_write_tmp("cat_bad1", JSON.stringify({"schema": LevelCatalog.EXPECTED_SCHEMA, "entries": bad}))).ok, "missing plan file invalidates the catalog")
	bad = entries.duplicate(true)
	bad[1]["supply_plan_path"] = plan_path("level_004_orange_cat")
	_ok(not LevelCatalog.new().load_manifest(_write_tmp("cat_bad2", JSON.stringify({"schema": LevelCatalog.EXPECTED_SCHEMA, "entries": bad}))).ok, "plan for another level invalidates the catalog")
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = Pack.level_path("level_003_palm_tree")
	h.supply_plan_path = "res://data/levels/supply/missing.json"
	get_root().add_child(h)
	_ok(not h.build() and h.get_build_error().begins_with("supply_plan_invalid"), "host with a missing plan fails closed (no generated fallback)")
	h.free()

# --- Level 1 regression -----------------------------------------------------------------------
func _level_1_unchanged() -> void:
	print("[level 1 unchanged]")
	var cat = LevelCatalog.new()
	_ok(cat.load_manifest().ok, "production catalog valid")
	var e1 = cat.get_entries_ordered()[0]
	_ok(e1.order == 1 and e1.id == "m21_level_001_hazard_bot" and e1.supply_plan_path == "", "production order 1 = Hazard Bot, no supply plan")
	var app = AppState.new(_uniq("l1"))
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "Level 1 builds through AppState path")
	var lvl = LevelLoader.load_from_path(e1.level_path).level_data
	var gen = BatchSupplyGenerator.generate(lvl, 3, 3, 1)
	_ok(JSON.stringify(h.get_supply().debug_snapshot()) == JSON.stringify(gen.debug_snapshot()), "Level 1 supply == M23 generator seed 1 candidate (unchanged)")
	h.free()
	await process_frame

func _write_tmp(tag: String, text: String) -> String:
	var p := "user://m52_plans_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _uniq(tag: String) -> String:
	var p := "user://m52_plans_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	if _fail == 0:
		print("M52 OWNER SUPPLY PLANS: PASS")
		quit(0)
	else:
		print("M52 OWNER SUPPLY PLANS: FAIL (%d)" % _fail)
		quit(1)
