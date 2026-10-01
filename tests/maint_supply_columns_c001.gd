extends SceneTree
## MAINT-SUPPLY-COLUMNS-C001 — 3/4/5 supply columns, preview depth exactly 3.
## Owner decision: coordination/OWNER_SUPPLY_COLUMNS_3_4_5_PREVIEW3_V01.md.
## Small deterministic TEST fixtures (user://, never production): vertical stripes that
## each touch the bottom row, so every placement order is solvable and the suite tests
## the column contract, not solver performance. Baseline five slots throughout.
##
## Run: godot --headless --path . -s res://tests/maint_supply_columns_c001.gd

const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")

const HEXES := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF"]   # C01..C05
const CIDS := ["C01", "C02", "C03", "C04", "C05"]
const OWNER_LEVELS := ["level_002_apple", "level_003_palm_tree", "level_004_orange_cat",
	"level_005_party_toucan", "level_006_chicken", "level_007_pigeon", "level_008_butterfly",
	"level_009_frog", "level_010_ice_cube"]

var EXPECTED_CASES := [
	"legacy_owner_plans", "accept_3_4_5", "reject_columns", "preview_depth",
	"array_mismatch", "uncapped_batch", "conservation", "solve_replay",
	"panel_rows", "host_runtime",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _stripes_path := ""
var _stripes

func _initialize() -> void:
	# 10x4 stripes, 2 wide each: C01..C05, 8 cells per color, 40 cells.
	var cells: Array = []
	for y in range(4):
		for x in range(10):
			cells.append(x / 2)
	_stripes_path = _write("lvl", JSON.stringify({"version": 1, "id": "maint_cols_stripes",
		"name": "Supply Columns Stripes", "difficulty": "TEST", "width": 10, "height": 4,
		"palette": HEXES, "cells": cells}))
	_stripes = LevelLoader.load_from_path(_stripes_path).level_data
	_legacy()
	_accept()
	_reject_columns()
	_preview()
	_array_mismatch()
	_uncapped()
	_conservation()
	_solve_replay()
	await _panel()
	await _host()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_done()

# ---------------------------------------------------------------- fixtures ----

## Plan for the stripes level: `layout` = one array per column of [color index, robots].
func _plan(layout: Array, column_count := -1, depth := 3, level_id := "maint_cols_stripes") -> Dictionary:
	var cols: Array = []
	var n := 0
	for col in layout:
		var q: Array = []
		for b in col:
			n += 1
			q.append({"batchId": "B%02d" % n, "cid": CIDS[b[0]], "robots": b[1]})
		cols.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level_id,
		"columnCount": layout.size() if column_count < 0 else column_count,
		"visiblePreviewDepth": depth, "maxRobotsPerBatch": 64, "intendedColumnClicks": [], "columns": cols}

func _layout(columns: int) -> Array:
	match columns:
		2: return [[[0, 8], [1, 8], [2, 8]], [[3, 8], [4, 8]]]
		3: return [[[0, 8], [3, 8]], [[1, 8], [4, 8]], [[2, 8]]]
		4: return [[[0, 8]], [[1, 8], [4, 4]], [[2, 8]], [[3, 8], [4, 4]]]
		5: return [[[0, 8]], [[1, 8]], [[2, 4], [2, 4]], [[3, 8]], [[4, 8]]]
		6: return [[[0, 8]], [[1, 8]], [[2, 8]], [[3, 8]], [[4, 4]], [[4, 4]]]
	return []

func _build(plan: Dictionary, level = null) -> Dictionary:
	return SupplyPlanLoader.build_engine(plan, _stripes if level == null else level)

# ------------------------------------------------------------------- cases ----

func _legacy() -> void:
	print("[legacy owner plans 2..10]")
	for id in OWNER_LEVELS:
		var lvl = LevelLoader.load_from_path("res://data/levels/%s.json" % id).level_data
		var path := "res://data/levels/supply/%s_supply_v1.json" % id
		var r := SupplyPlanLoader.load_engine(path, lvl)
		_ok(r["ok"] and int(r["plan"]["columnCount"]) == 3 and r["engine"].get_column_count() == 3 and r["engine"].get_preview_depth() == 3, "%s: unchanged 3-column owner plan loads (3 cols / depth 3) %s" % [id, r.get("error", "")])
	_complete("legacy_owner_plans")

func _accept() -> void:
	print("[accept 3 / 4 / 5]")
	for n in [3, 4, 5]:
		var r := _build(_plan(_layout(n)))
		_ok(r["ok"] and r["engine"].get_column_count() == n and r["engine"].get_preview_depth() == 3 and (r["queue_lengths"] as Array).size() == n, "%d-column plan accepted; engine created with %d columns / depth 3 %s" % [n, n, r.get("error", "")])
		if r["ok"]:
			var dbg: Dictionary = r["engine"].debug_snapshot()
			var order: Array = []
			for col in dbg["columns"]:
				for b in col:
					order.append(String(b["batch_id"]))
			var expected: Array = []
			for col in _plan(_layout(n))["columns"]:
				for b in col:
					expected.append(String(b["batchId"]))
			_ok(order == expected, "%d-column plan: FIFO order + batch identity preserved %s" % [n, str(order)])
			var colors_ok := true
			for col in dbg["columns"]:
				for b in col:
					colors_ok = colors_ok and _stripes.palette[int(b["color_id"])].to_upper().begins_with(HEXES[CIDS.find(_cid_of(r, b))])
			_ok(colors_ok, "%d-column plan: Cxx -> local palette mapping exact" % n)
	_complete("accept_3_4_5")

func _cid_of(r: Dictionary, b: Dictionary) -> String:
	for cid in r["cid_to_local"]:
		if int(r["cid_to_local"][cid]) == int(b["color_id"]):
			return cid
	return ""

func _reject_columns() -> void:
	print("[reject column counts]")
	for n in [2, 6]:
		var r := _build(_plan(_layout(n)))
		_ok(not r["ok"] and not r.has("engine"), "%d-column plan rejected (%s)" % [n, r.get("error", "")])
	for bad in [0, -1, 3.5, "4", null]:
		var p := _plan(_layout(4))
		p["columnCount"] = bad
		var r := _build(p)
		_ok(not r["ok"], "columnCount %s rejected (must be exact integer)" % str(bad))
	var p4 := _plan(_layout(4))
	p4["columnCount"] = 4.0   # JSON numbers parse as float; integral float is the same integer
	_ok(_build(p4)["ok"], "columnCount 4.0 (JSON integral number) accepted as 4")
	_complete("reject_columns")

func _preview() -> void:
	print("[preview depth]")
	for n in [3, 4, 5]:
		for d in [2, 4]:
			var r := _build(_plan(_layout(n), -1, d))
			_ok(not r["ok"], "%d columns / preview depth %d rejected (%s)" % [n, d, r.get("error", "")])
		_ok(_build(_plan(_layout(n), -1, 3))["ok"], "%d columns / preview depth 3 accepted" % n)
	_complete("preview_depth")

func _array_mismatch() -> void:
	print("[columns array length mismatch]")
	for spec in [[4, 3], [4, 5], [5, 4], [3, 4], [5, 3]]:
		var r := _build(_plan(_layout(spec[1]), spec[0]))
		_ok(not r["ok"], "declared %d / array %d rejected (%s)" % [spec[0], spec[1], r.get("error", "")])
	_complete("array_mismatch")

func _uncapped() -> void:
	print("[uncapped robots per batch]")
	# 8x6: C01 36 cells (x < 6), C02 12 cells.
	var cells: Array = []
	for y in range(6):
		for x in range(8):
			cells.append(0 if x < 6 else 1)
	var lvl = LevelLoader.load_from_path(_write("big", JSON.stringify({"version": 1, "id": "maint_cols_big",
		"name": "Supply Columns Big Batch", "difficulty": "TEST", "width": 8, "height": 6,
		"palette": HEXES.slice(0, 2), "cells": cells}))).level_data
	for layout in [[[[0, 31]], [[0, 5]], [[1, 6]], [[1, 6]]], [[[0, 31]], [[0, 5]], [[1, 4]], [[1, 4]], [[1, 4]]]]:
		var r := _build(_plan(layout, -1, 3, "maint_cols_big"), lvl)
		_ok(r["ok"], "%d-column plan with a 31-robot batch accepted (no global cap) %s" % [layout.size(), r.get("error", "")])
	var p := _plan([[[0, 31]], [[0, 5]], [[1, 6]], [[1, 6]]], -1, 3, "maint_cols_big")
	p["maxRobotsPerBatch"] = 30
	_ok(not _build(p, lvl)["ok"], "per-plan maxRobotsPerBatch metadata bound still enforced")
	_complete("uncapped_batch")

func _conservation() -> void:
	print("[conservation]")
	for n in [4, 5]:
		var color := _plan(_layout(n))
		color["columns"][0][0]["robots"] = 7
		_ok(not _build(color)["ok"], "%d columns: per-color conservation mismatch rejected" % n)
		var swap := _plan(_layout(n))
		swap["columns"][0][0]["robots"] = 7
		swap["columns"][1][0]["robots"] = 9   # grand total kept, colors off
		_ok(not _build(swap)["ok"], "%d columns: per-color mismatch with equal grand total rejected" % n)
		var extra := _plan(_layout(n))
		extra["columns"][n - 1].append({"batchId": "X1", "cid": "C01", "robots": 1})
		_ok(not _build(extra)["ok"], "%d columns: grand-total surplus rejected" % n)
		var dup := _plan(_layout(n))
		dup["columns"][n - 1][0]["batchId"] = dup["columns"][0][0]["batchId"]
		_ok(not _build(dup)["ok"], "%d columns: duplicate batchId rejected" % n)
		var off := _plan(_layout(n))
		off["columns"][0][0]["cid"] = "C09"
		_ok(not _build(off)["ok"], "%d columns: Cxx absent from level palette rejected" % n)
	_complete("conservation")

func _solve_replay() -> void:
	print("[real SolvabilitySolver solve + replay]")
	for n in [3, 4, 5]:
		var r := _build(_plan(_layout(n)))
		var st = ProofState.from_level_and_supply(_stripes, r["engine"])
		_ok(st.column_count == n and st.capacity == FiveSlotBatchEngine.SLOT_COUNT and st.capacity == 5, "%d columns: solver state sees %d columns, baseline 5 slots" % [n, st.column_count])
		var sol: Dictionary = SolvabilitySolver.new().solve(st)
		_ok(sol["status"] == "SOLVED", "%d columns: solve SOLVED (visited %d)" % [n, int(sol["visited"])])
		var cols_used := {}
		for a in sol.get("trace", []):
			cols_used[int(a["column"])] = true
		_ok(cols_used.keys().max() == n - 1, "%d columns: trace uses column index %d" % [n, n - 1])
		var fresh = ProofState.from_level_and_supply(_stripes, _build(_plan(_layout(n)))["engine"])
		var rep: Dictionary = SolvabilitySolver.new().replay(fresh, sol.get("trace", []))
		_ok(rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0, "%d columns: replay reaches solved (%d steps)" % [n, int(rep["steps"])])
	_complete("solve_replay")

func _panel() -> void:
	print("[BatchSupplyPanel 3 / 4 / 5]")
	var panel = BatchSupplyPanel.new()
	get_root().add_child(panel)
	await process_frame
	for n in [3, 4, 5, 3]:
		var eng = _build(_plan(_layout(n)))["engine"]
		panel.bind_player_snapshot(eng.player_snapshot())
		await process_frame
		var rows_ok := true
		for c in range(n):
			rows_ok = rows_ok and panel.get_column_row_panels(c).size() == 3
		_ok(panel.get_column_count() == n and panel.get_visible_row_count() == 3 and rows_ok, "panel renders %d columns x exactly 3 visible rows" % n)
	panel.free()
	await process_frame
	_complete("panel_rows")

func _host() -> void:
	print("[production host 4 / 5 columns, baseline 5 slots]")
	for n in [4, 5]:
		var h = ProductionGameplayHost.new()
		h.auto_build = false
		h.level_path = _stripes_path
		var plan_path := _write("plan%d" % n, JSON.stringify(_plan(_layout(n))))
		h.supply_plan_path = plan_path
		get_root().add_child(h)
		_ok(h.build(), "%d-column plan builds the real host %s" % [n, h.get_build_error()])
		var sup = h.get_supply()
		var slots = h.get_slots()
		_ok(sup != null and sup.get_column_count() == n and sup.get_preview_depth() == 3, "%d columns: host supply %d cols / depth 3" % [n, sup.get_column_count() if sup else -1])
		_ok(slots != null and slots.get_slot_count() == FiveSlotBatchEngine.SLOT_COUNT, "%d columns: baseline five slots (no +1 Slot) (%d)" % [n, slots.get_slot_count() if slots else -1])
		h.queue_free()
		await process_frame
		# QA deadlock rebuild keeps the plan's column count (was the host's 3 export).
		var q = ProductionGameplayHost.new()
		q.auto_build = false
		q.level_path = _stripes_path
		q.supply_plan_path = plan_path
		q.qa_supply_drop_last = 1
		get_root().add_child(q)
		_ok(q.build() and q.get_supply().get_column_count() == n, "%d columns: QA drop-last rebuild keeps %d columns %s" % [n, n, q.get_build_error()])
		q.queue_free()
		await process_frame
	_complete("host_runtime")

# ----------------------------------------------------------------- helpers ----

func _write(tag: String, text: String) -> String:
	var p := "user://maint_cols_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fail += 1
		print("  FAIL: ", msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: ", missing)
	print("maint_supply_columns_c001: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
