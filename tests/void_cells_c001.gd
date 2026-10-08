extends SceneTree
## VOID-CELLS-C001 — transparent artwork pixels as first-class VOID cells (ADR-030,
## owner decision 2026-10-08; D1 VOID renders exactly like CLEARED, D2 production
## artwork >= 200 cells and >= 25% of W*H).
##
## Direct assertions against the real stack: LevelLoader/LevelValidator,
## ProductionLevelValidator, BoardState, ColorCandidateIndex, BoardRenderer,
## BatchSupplyGenerator/SupplyPlanLoader, ProofState/ProofKernel/SolvabilitySolver,
## ProductionTargetAccess (via the analyzer peel), LevelDifficultyAnalyzerV1,
## ProductionArtLevelBuilder, ScrubpackV1 and the live ProductionGameplayHost WIN path.
##
## Run: godot --headless --path . -s res://tests/void_cells_c001.gd
## Exits 0 on success, 1 on any failure.

const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const LevelDifficultyAnalyzerV1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const ScrubpackV1 = preload("res://scripts/content_runtime/scrubpack_v1.gd")
const ScrubpackFixture = preload("res://tests/support/scrubpack_fixture.gd")
const StrictJson = preload("res://scripts/content_runtime/strict_json.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

## Canonical palette V3 C01..C04 (opaque #RRGGBBFF).
const HEX := {"C01": "#FF4500FF", "C02": "#FFA800FF", "C03": "#FFD635FF", "C04": "#00CC78FF"}
const V := -1
const SOLVE_CFG := {"max_visited": 200000, "max_depth": 400}

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_v1_levels_unchanged()
	_loader_rules()
	_production_d2()
	_board_and_candidates()
	_renderer_d1()
	_supply_conservation()
	_reachability_fixtures()
	_corridor_only_solvable()
	_solver_and_analyzer_all_fixtures()
	_builder_transparent_pixels()
	_scrubpack_v2()
	await _runtime_win()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ------

## 20x20 TEST level from f(x, y) -> palette index or V. Version 2 iff any VOID.
func _fixture(id: String, cids: Array, f: Callable, w: int = 20, h: int = 20) -> Dictionary:
	var cells: Array = []
	var has_void := false
	for y in range(h):
		for x in range(w):
			var c: int = f.call(x, y)
			has_void = has_void or c == V
			cells.append(c)
	var pal: Array = []
	for cid in cids:
		pal.append(HEX[cid])
	return {"version": 2 if has_void else 1, "id": id, "name": id, "difficulty": "TEST",
		"width": w, "height": h, "palette": pal, "cells": cells}

func _load(d: Dictionary):
	var r = LevelLoader.load_from_text(JSON.stringify(d), d["id"])
	_ok(r.is_ok(), "%s loads (%s)" % [d["id"], str(r.errors)])
	return r.level_data if r.is_ok() else null

## Ring: 3-cell VOID frame around 14x14 two-colour stripes.
func _ring() -> Dictionary:
	return _fixture("void_ring", ["C01", "C02"], func(x, y):
		if x < 3 or y < 3 or x > 16 or y > 16:
			return V
		return 0 if x < 10 else 1)

## Enclosed hole: full artwork with a sealed 4x4 VOID hole in the middle.
func _hole() -> Dictionary:
	return _fixture("void_hole", ["C01", "C02", "C03"], func(x, y):
		if x >= 8 and x <= 11 and y >= 8 and y <= 11:
			return V
		return (x / 7) % 3)

## VOID touching the border: left five columns VOID.
func _border() -> Dictionary:
	return _fixture("void_border", ["C01", "C02"], func(x, y):
		if x < 5:
			return V
		return 0 if y < 10 else 1)

## VOID-only rows and columns: rows 0..1 and column 19 VOID.
func _rows_cols() -> Dictionary:
	return _fixture("void_rows_cols", ["C01", "C02", "C03"], func(x, y):
		if y < 2 or x == 19:
			return V
		return (y / 6) % 3)

## Corridor: C02 4x4 block sealed inside C01, reached only through a 1-wide VOID corridor
## (x=9, y=12..19) when `with_corridor`; otherwise the corridor cells are C01.
func _corridor(with_corridor: bool) -> Dictionary:
	return _fixture("void_corridor" if with_corridor else "void_corridor_filled", ["C01", "C02"], func(x, y):
		if x >= 8 and x <= 11 and y >= 8 and y <= 11:
			return 1
		if with_corridor and x == 9 and y >= 12:
			return V
		return 0)

## Plan for _corridor: every column has five C02 batches in FRONT (more than five slots can
## hold), so without access to C02 the five slots jam before any C01 can be placed.
func _corridor_plan(lvl) -> Dictionary:
	var c01: int = lvl.get_artwork_cell_count() - 16
	var cols: Array = []
	var n := 0
	var c02_sizes := [[1, 1, 1, 1, 2], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1]]
	var c01_split := [c01 / 3, c01 / 3, c01 - 2 * (c01 / 3)]
	for k in range(3):
		var q: Array = []
		for r in c02_sizes[k]:
			n += 1
			q.append({"batchId": "K%02d" % n, "cid": "C02", "robots": r})
		var left: int = c01_split[k]
		while left > 0:
			var take: int = mini(left, 40)
			n += 1
			q.append({"batchId": "K%02d" % n, "cid": "C01", "robots": take})
			left -= take
		cols.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": lvl.id, "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 40, "ownerInput": "void-c001",
		"intendedColumnClicks": [], "columns": cols}

func _all_fixtures() -> Array:
	return [_ring(), _hole(), _border(), _rows_cols(), _corridor(true)]

# ------------------------------------------------------------- v1 unchanged -------
func _v1_levels_unchanged() -> void:
	print("[v1 levels: no VOID semantics leak]")
	var dir := DirAccess.open("res://data/levels")
	var n := 0
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var r = LevelLoader.load_from_path("res://data/levels/" + f)
		if not r.is_ok():
			continue
		var lvl = r.level_data
		n += 1
		var board = BoardState.from_level_data(lvl)
		var totals := BatchSupplyGenerator.color_totals(lvl)
		var sum := 0
		for c in totals:
			sum += int(totals[c])
		_ok(lvl.version == 1 and lvl.get_void_cell_count() == 0 and lvl.get_artwork_cell_count() == lvl.get_cell_count()
			and board.count_cells_by_state(BoardState.CellState.ACTIVE) == lvl.get_cell_count()
			and board.get_artwork_cell_count() == lvl.get_cell_count() and sum == lvl.get_cell_count(),
			"%s: version 1, zero VOID, every cell ACTIVE, supply total == cell count" % f)
	_ok(n >= 10, "checked every committed level (%d)" % n)
	# A version-1 LevelData whose cell is -1 is NOT void-aware anywhere (no silent VOID).
	var bad := LevelData.new(1, "x", "x", "TEST", 20, 20, PackedStringArray([HEX["C01"]]), _filled(400, 0))
	bad.cells[0] = -1
	_ok(not bad.is_void(0) and bad.get_artwork_cell_count() == 400 and BatchSupplyGenerator.color_totals(bad).is_empty(),
		"v1 LevelData with -1 is never treated as VOID (supply fails closed)")

func _filled(n: int, v: int) -> PackedInt32Array:
	var a := PackedInt32Array()
	a.resize(n)
	a.fill(v)
	return a

# -------------------------------------------------------------- loader rules -------
func _loader_rules() -> void:
	print("[loader / validator]")
	var ring := _ring()
	var lvl = _load(ring)
	_ok(lvl != null and lvl.version == 2 and lvl.get_void_cell_count() == 400 - 196 and lvl.get_artwork_cell_count() == 196,
		"v2 ring loads: 204 VOID, 196 artwork")
	var v1 := ring.duplicate(true)
	v1["version"] = 1
	_reject(v1, "requires version 2", "-1 in a version-1 file rejected")
	var v2none := _fixture("v2none", ["C01"], func(_x, _y): return 0)
	v2none["version"] = 2
	_reject(v2none, "requires at least one VOID", "version 2 without VOID rejected")
	var allv := _fixture("allv", ["C01"], func(_x, _y): return V)
	_reject(allv, "every cell is VOID", "all-VOID level rejected")
	var m2 := ring.duplicate(true)
	m2["cells"][0] = -2
	_reject(m2, "exceeds palette size", "-2 (not VOID) rejected")
	var semi := ring.duplicate(true)
	semi["cells"][50] = 0.5
	_reject(semi, "not an integer palette id", "fractional (semi-transparent) value rejected")
	var str_cell := ring.duplicate(true)
	str_cell["cells"][51] = "transparent"
	_reject(str_cell, "not an integer palette id", "string cell value rejected")
	var v3 := ring.duplicate(true)
	v3["version"] = 3
	_reject(v3, "unsupported version", "version 3 rejected")

func _reject(d: Dictionary, needle: String, msg: String) -> void:
	var r = LevelLoader.load_from_text(JSON.stringify(d), d["id"])
	_ok(not r.is_ok() and str(r.errors).find(needle) != -1, "%s (%s)" % [msg, str(r.errors).left(160)])

# ------------------------------------------------------------- D2 production -------
func _production_d2() -> void:
	print("[D2 minimum artwork]")
	# 20x20: 199 artwork < 200 -> reject; 200 artwork -> accept.
	var a199 = _art_level(20, 20, 199)
	var a200 = _art_level(20, 20, 200)
	_ok(not ProductionLevelValidator.validate(a199).is_ok(), "20x20 with 199 artwork cells rejected (< 200)")
	_ok(ProductionLevelValidator.validate(a200).is_ok(), "20x20 with 200 artwork cells accepted")
	# 40x40 = 1600: 399 artwork (< 25% = 400) rejected even though >= 200; 400 accepted.
	_ok(not ProductionLevelValidator.validate(_art_level(40, 40, 399)).is_ok(), "40x40 with 399 artwork (< 25%) rejected")
	_ok(ProductionLevelValidator.validate(_art_level(40, 40, 400)).is_ok(), "40x40 with 400 artwork (== 25%) accepted")
	# Envelope unchanged: 19 / 60 still rejected regardless of VOID.
	_ok(not ProductionLevelValidator.validate(_art_level(19, 40, 500)).is_ok(), "envelope 20..59 still enforced")

func _art_level(w: int, h: int, art: int):
	var cells := _filled(w * h, V)
	for i in range(art):
		cells[i] = i % 3
	return LevelData.new(2, "d2_%dx%d_%d" % [w, h, art], "d2", "EASY", w, h,
		PackedStringArray([HEX["C01"], HEX["C02"], HEX["C03"]]), cells)

# ------------------------------------------------------ board + candidates ------
func _board_and_candidates() -> void:
	print("[BoardState / ColorCandidateIndex]")
	var lvl = _load(_hole())
	var board = BoardState.from_level_data(lvl)
	var hole_i: int = 9 * 20 + 9
	_ok(board.is_void(hole_i) and board.get_cell_state(hole_i) == BoardState.CellState.CLEARED and board.get_color_id(hole_i) == -1,
		"VOID starts CLEARED with no colour")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == 384 and board.get_artwork_cell_count() == 384,
		"ACTIVE == artwork == 384 at start")
	_ok(not board.set_cell_state(hole_i, BoardState.CellState.ACTIVE) and board.get_cell_state(hole_i) == BoardState.CellState.CLEARED,
		"VOID can never be made ACTIVE")
	_ok(board.set_cell_state(hole_i, BoardState.CellState.CLEARED), "CLEARED write on VOID is an idempotent no-op")
	var ci = ColorCandidateIndex.create()
	_ok(ci.bind(board), "candidate index binds a VOID board")
	var total := 0
	for c in ci.get_color_ids():
		total += ci.count_candidates(c)
		_ok(not ci.get_candidates(c).has(hole_i), "colour %d candidates never include VOID" % c)
	_ok(total == 384 and not ci.get_color_ids().has(-1), "candidate population == artwork, no -1 bucket")
	_ok(ci.sync_cell(hole_i) and ci.is_bound_to(board), "sync_cell on VOID is a healthy no-op (no neutralize)")
	board.set_cell_state(0, BoardState.CellState.CLEARED)
	board.restore_all_active()
	_ok(board.get_cell_state(hole_i) == BoardState.CellState.CLEARED and board.get_cell_state(0) == BoardState.CellState.ACTIVE
		and board.count_cells_by_state(BoardState.CellState.ACTIVE) == 384, "restore_all_active (Retry) keeps VOID CLEARED")

# ------------------------------------------------------------- renderer D1 -------
func _renderer_d1() -> void:
	print("[D1 renderer: VOID == CLEARED]")
	var lvl = _load(_ring())
	var board = BoardState.from_level_data(lvl)
	var r = BoardRenderer.new()
	r.configure(board, lvl.palette, Vector2(400, 400))
	var center := 10 * 20 + 10
	board.set_cell_state(center, BoardState.CellState.CLEARED)
	r.update_cells([center])
	_ok(r.get_pixel_color(0, 0) == BoardRenderer.CLEARED_COLOR and r.get_pixel_color(10, 10) == BoardRenderer.CLEARED_COLOR,
		"VOID pixel == CLEARED pixel (transparent, BG01 shows through; shader draws no grid on alpha 0)")
	_ok(r.get_pixel_color(3, 3).a == 1.0, "artwork pixel stays opaque")
	r.free()

# ---------------------------------------------------------- supply conservation ---
func _supply_conservation() -> void:
	print("[supply conservation]")
	var lvl = _load(_corridor(true))
	var totals := BatchSupplyGenerator.color_totals(lvl)
	_ok(totals.size() == 2 and int(totals[0]) + int(totals[1]) == lvl.get_artwork_cell_count() and not totals.has(-1),
		"color_totals over artwork only (%s)" % str(totals))
	var plan := _corridor_plan(lvl)
	var ok: Dictionary = SupplyPlanLoader.build_engine(plan, lvl)
	_ok(ok["ok"], "plan == artwork totals accepted %s" % ok.get("error", ""))
	var over := plan.duplicate(true)
	over["columns"][2][-1]["robots"] = int(over["columns"][2][-1]["robots"]) + lvl.get_void_cell_count()
	var bad: Dictionary = SupplyPlanLoader.build_engine(over, lvl)
	_ok(not bad["ok"], "plan that also pays for VOID cells (grand == W*H) rejected: %s" % bad.get("error", ""))
	var gen = BatchSupplyGenerator.generate(lvl, 3, 3, 7)
	var sum := 0
	for col in gen.debug_snapshot()["columns"]:
		for b in col:
			sum += int(b["robot_count"])
	_ok(sum == lvl.get_artwork_cell_count(), "generated supply robots == artwork cells (%d)" % sum)

# ------------------------------------------------------------- reachability -------
func _reachability_fixtures() -> void:
	print("[reachability law: VOID is open space, never a teleport]")
	var an = LevelDifficultyAnalyzerV1.new()
	_ok(an.is_ok(), "analyzer loads")
	# Ring: VOID frame touches the border, so the artwork's outer ring is wave 0.
	var ring = _load(_ring())
	var pr: Dictionary = an.peel_waves(ring)
	var waves: String = pr["perCellWaves"]
	_ok(waves[0] == "." and waves[3 * 20 + 3] == "0" and waves[3 * 20 + 9] == "0" and int(pr["unreachableCells"]) == 0,
		"ring: VOID '.', artwork edge next to border-connected VOID is wave 0")
	_ok(waves[4 * 20 + 4] == "1", "ring: one step inside the artwork is wave 1")
	# Hole: sealed VOID gives NO shortcut — the cell right above it peels at its geometric depth.
	var hole = _load(_hole())
	var ph: Dictionary = an.peel_waves(hole)
	var hw: String = ph["perCellWaves"]
	_ok(hw[7 * 20 + 9] == "7" and int(ph["geometricMismatchCells"]) == 0 and int(ph["unreachableCells"]) == 0,
		"hole: cell adjacent to the sealed hole peels at geometric depth 7 (no teleport)")
	# Border VOID: column 5 (first artwork column) is wave 0 on every row.
	var border = _load(_border())
	var bw: String = an.peel_waves(border)["perCellWaves"]
	var col5 := true
	for y in range(20):
		col5 = col5 and bw[y * 20 + 5] == "0"
	_ok(col5, "border: every artwork cell touching the VOID strip is wave 0")
	# VOID rows/cols: row 2 and column 18 are wave 0.
	var rc = _load(_rows_cols())
	var rw: String = an.peel_waves(rc)["perCellWaves"]
	_ok(rw[2 * 20 + 9] == "0" and rw[10 * 20 + 18] == "0" and rw[10 * 20 + 9] != "0", "rows/cols: artwork next to VOID rows/columns is wave 0, interior is not")
	# Corridor: the C02 block's bottom cell above the corridor is wave 0.
	var cor = _load(_corridor(true))
	var cw: String = an.peel_waves(cor)["perCellWaves"]
	var filled = _load(_corridor(false))
	var fw: String = an.peel_waves(filled)["perCellWaves"]
	_ok(cw[11 * 20 + 9] == "0" and fw[11 * 20 + 9] == "8", "corridor: block cell wave 0 via VOID corridor (8 without it)")
	# Colour layers: VOID is free, entering artwork from VOID costs one layer.
	var lr: Dictionary = LevelDifficultyAnalyzerV1.color_layer_depth(ring)
	_ok(int(lr["maxLayers"]) == 1, "ring colour layers: each stripe is one layer from the open VOID (max %d)" % int(lr["maxLayers"]))

# ------------------------------------------------------ corridor-only solvable ----
func _corridor_only_solvable() -> void:
	print("[solvable ONLY because a VOID corridor exists]")
	var cor = _load(_corridor(true))
	var filled = _load(_corridor(false))
	var e1: Dictionary = SupplyPlanLoader.build_engine(_corridor_plan(cor), cor)
	var e0: Dictionary = SupplyPlanLoader.build_engine(_corridor_plan(filled), filled)
	_ok(e1["ok"] and e0["ok"], "both corridor plans conserve exactly")
	var solver = SolvabilitySolver.new()
	var r1: Dictionary = solver.solve(ProofState.from_level_and_supply(cor, e1["engine"]), SOLVE_CFG)
	var r0: Dictionary = solver.solve(ProofState.from_level_and_supply(filled, e0["engine"]), SOLVE_CFG)
	_ok(r1["status"] == SolvabilitySolver.SOLVED, "with VOID corridor: SOLVED (%s)" % r1["status"])
	_ok(r0["status"] == SolvabilitySolver.DEADLOCK, "corridor filled with artwork: DEADLOCK (%s)" % r0["status"])

# ------------------------------------------- solver + analyzer on every fixture ----
func _solver_and_analyzer_all_fixtures() -> void:
	print("[solver SOLVED + replay + determinism + Difficulty V1 score]")
	var an = LevelDifficultyAnalyzerV1.new()
	var solver = SolvabilitySolver.new()
	for d in _all_fixtures():
		var lvl = _load(d)
		var eng = SupplyPlanLoader.build_engine(_corridor_plan(lvl), lvl)["engine"] if d["id"] == "void_corridor" \
			else BatchSupplyGenerator.generate(lvl, 3, 3, 1)
		var ps = ProofState.from_level_and_supply(lvl, eng)
		_ok(ps.active_count() == lvl.get_artwork_cell_count(), "%s: initial proof state ACTIVE == artwork" % d["id"])
		var key_a: String = ps.canonical_key()
		var key_b: String = ProofState.from_level_and_supply(_load(d), eng).canonical_key()
		_ok(key_a == key_b and key_a.substr(0, 1) == ("0" if lvl.is_void(0) else "1"), "%s: canonical key stable, VOID encoded CLEARED" % d["id"])
		var r: Dictionary = solver.solve(ps, SOLVE_CFG)
		_ok(r["status"] == SolvabilitySolver.SOLVED, "%s: SOLVED (%s)" % [d["id"], r["status"]])
		if r["status"] != SolvabilitySolver.SOLVED:
			continue
		var rep: Dictionary = solver.replay(ps, r["trace"])
		_ok(rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0, "%s: trace replays to completion" % d["id"])
		var r2: Dictionary = solver.solve(ps, SOLVE_CFG)
		_ok(int(r2["trace_hash"]) == int(r["trace_hash"]) and int(r2["visited"]) == int(r["visited"]), "%s: deterministic re-solve" % d["id"])
		var cols: Array = []
		for rec in r["trace"]:
			cols.append(int(rec["column"]))
		var raw: Dictionary = an.measure(lvl, eng, cols, r["trace"])
		_ok(raw["ok"], "%s: analyzer measure ok %s" % [d["id"], raw.get("error", "")])
		if not raw["ok"]:
			continue
		var sc: Dictionary = an.score(raw, 1)
		var D: float = float(sc["challengeScore"])
		_ok(is_finite(D) and D >= 0.0 and D <= 100.0, "%s: Difficulty V1 challenge score finite 0..100 (%.2f)" % [d["id"], D])
		_ok(int(raw["color"]["cells"]) == lvl.get_artwork_cell_count() and int(raw["color"]["voidCells"]) == lvl.get_void_cell_count()
			and int(sc["supporting"]["W"]["activeCells"]) == lvl.get_artwork_cell_count(), "%s: W/C measured over artwork only" % d["id"])
		_ok(sc.has("void") and int(sc["void"]["voidCells"]) == lvl.get_void_cell_count(), "%s: VOID presence recorded in score provenance" % d["id"])
		var raw2: Dictionary = an.measure(lvl, eng, cols, r["trace"])
		raw2.erase("timing")
		var raw1 := raw.duplicate(true)
		raw1.erase("timing")
		_ok(JSON.stringify(raw1) == JSON.stringify(raw2), "%s: analyzer measurement deterministic" % d["id"])

# -------------------------------------------------- builder: transparent -> VOID ---
func _builder_transparent_pixels() -> void:
	print("[ProductionArtLevelBuilder: alpha 0 -> VOID, alpha 1..254 rejected]")
	# Raw first-seen import shape: transparent pixels are a palette entry with alpha 0.
	var raw_cells := PackedInt32Array()
	for y in range(20):
		for x in range(20):
			raw_cells.append(0 if (x < 2 or y < 2) else 1 + (x % 3))
	var pal := PackedStringArray(["#12345600", HEX["C01"], HEX["C02"], HEX["C03"]])
	var raw := LevelData.new(1, "void_build", "Void Build", "EASY", 20, 20, pal, raw_cells)
	var n = ProductionArtLevelBuilder.normalize_from_level_data(raw, "EASY")
	_ok(n.is_ok(), "transparent pixels normalize %s" % str(n.errors))
	if n.is_ok():
		var lvl = n.level_data
		_ok(lvl.version == 2 and n.void_cell_count == 76 and lvl.get_void_cell_count() == 76 and lvl.palette.size() == 3
			and lvl.cells[0] == V and lvl.cells[2 * 20 + 2] >= 0, "output: version 2, 76 VOID cells, palette only the 3 used colours")
		var img: Image = LevelImporter.reconstruct_image(lvl)
		_ok(img != null and img.get_pixel(0, 0).a8 == 0 and img.get_pixel(5, 5).a8 == 255, "preview reconstruction: VOID transparent, artwork opaque")
		var md: Dictionary = ProductionArtLevelBuilder._build_metadata("res://project.godot", lvl, n, "out.json", "prev.png")
		_ok(int(md["cellCount"]) == 400 and int(md["artworkCellCount"]) == 324 and int(md["voidCellCount"]) == 76,
			"metadata: cellCount 400, artworkCellCount 324, voidCellCount 76")
	var semi := LevelData.new(1, "semi", "Semi", "EASY", 20, 20,
		PackedStringArray(["#FF450080", HEX["C01"], HEX["C02"], HEX["C03"]]), raw_cells)
	var ns = ProductionArtLevelBuilder.normalize_from_level_data(semi, "EASY")
	_ok(not ns.is_ok() and str(ns.errors).find("alpha 128") != -1, "semi-transparent pixel rejected (never filled, never VOID)")
	var no_void := LevelData.new(1, "opaque", "Opaque", "EASY", 20, 20,
		PackedStringArray([HEX["C04"], HEX["C01"], HEX["C02"], HEX["C03"]]), raw_cells)
	var nv = ProductionArtLevelBuilder.normalize_from_level_data(no_void, "EASY")
	_ok(nv.is_ok() and nv.level_data.version == 1 and nv.void_cell_count == 0, "fully opaque art still builds version 1")
	# D2 through the builder: 20x20 with only 120 artwork cells is rejected.
	var sparse := PackedInt32Array()
	for i in range(400):
		sparse.append(1 + (i % 3) if i < 120 else 0)
	var nsp = ProductionArtLevelBuilder.normalize_from_level_data(LevelData.new(1, "sparse", "Sparse", "EASY", 20, 20, pal, sparse), "EASY")
	_ok(not nsp.is_ok() and str(nsp.errors).find("non-VOID") != -1, "builder output violating D2 rejected")

# ------------------------------------------------------------ scrubpack v2 ---------
func _scrubpack_v2() -> void:
	print("[ScrubpackV1: remote version-2 VOID level]")
	var files: Dictionary = ScrubpackFixture.level_files("void_l011", "level_002_apple")
	var lv = _strict(files["level"])
	var pl = _strict(files["supply_plan"])
	var level = LevelLoader.load_from_text(files["level"].get_string_from_utf8(), "apple").level_data
	var cid := String(pl["columns"][0][0]["cid"])
	var local: int = int(SupplyPlanLoader.cid_to_local_map(level)["map"][cid])
	var k := 3
	var done := 0
	for i in range(lv["cells"].size()):
		if done < k and int(lv["cells"][i]) == local:
			lv["cells"][i] = -1
			done += 1
	lv["version"] = 2
	pl["columns"][0][0]["robots"] = int(pl["columns"][0][0]["robots"]) - k
	var md = _strict(files["metadata"])
	md["artworkCellCount"] = int(md["cellCount"]) - k
	md["voidCellCount"] = k
	var ok := _triplet(lv, pl, md)
	_ok(ok["ok"], "v2 VOID level + conserving plan + artwork metadata accepted (%s)" % ok.get("reason", ""))
	var lv1 = lv.duplicate(true)
	lv1["version"] = 1
	_ok(_triplet(lv1, pl, md)["reason"] == "LEVEL_INVALID_PAYLOAD", "-1 in a version-1 remote level rejected")
	var md_bad = md.duplicate(true)
	md_bad["artworkCellCount"] = int(md["cellCount"])
	_ok(_triplet(lv, pl, md_bad)["reason"] == "METADATA_IDENTITY_MISMATCH", "wrong artworkCellCount rejected")
	var pl_bad = pl.duplicate(true)
	pl_bad["columns"][0][0]["robots"] = int(pl_bad["columns"][0][0]["robots"]) + k
	_ok(_triplet(lv, pl_bad, md)["reason"] == "SUPPLY_PLAN_INVALID", "plan paying for VOID cells rejected")

## Remote payloads are integer-strict: parse with the runtime StrictJson so ints stay ints.
func _strict(bytes: PackedByteArray):
	return StrictJson.parse(bytes, 1 << 20, 32, 65536, 8192)["value"]

func _triplet(lv, pl, md) -> Dictionary:
	return ScrubpackV1.validate_level_triplet("void_l011", {"level": JSON.stringify(lv).to_utf8_buffer(),
		"supply_plan": JSON.stringify(pl).to_utf8_buffer(), "metadata": JSON.stringify(md).to_utf8_buffer()})

# ---------------------------------------------------------- live runtime WIN ------
func _runtime_win() -> void:
	print("[live ProductionGameplayHost: WIN with VOID present]")
	for spec in [["void_corridor", _corridor(true)], ["void_hole", _hole()]]:
		var d: Dictionary = spec[1]
		var lvl = _load(d)
		var plan: Dictionary = _corridor_plan(lvl) if spec[0] == "void_corridor" else _plan_from_engine(lvl, BatchSupplyGenerator.generate(lvl, 3, 3, 1))
		var eng = SupplyPlanLoader.build_engine(plan, lvl)["engine"]
		var r: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, eng), SOLVE_CFG)
		if r["status"] != SolvabilitySolver.SOLVED:
			_ok(false, "%s: solver trace needed for the runtime replay" % spec[0])
			continue
		var h = _host(d, plan)
		if h == null:
			continue
		var board = h.get_board()
		_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == lvl.get_artwork_cell_count(), "%s: runtime board starts with artwork ACTIVE, VOID open" % spec[0])
		for rec in r["trace"]:
			_ok(h.get_input_controller().activate_front(int(rec["column"])).get("ok", false), "%s: traced column %d accepted" % [spec[0], int(rec["column"])])
			_settle(h)
			if h.get_completion().is_terminal():
				break
		_settle(h)
		_ok(h.get_completion().is_won(), "%s: WIN latches with VOID cells present" % spec[0])
		_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == 0 and board.count_cells_by_state(BoardState.CellState.CLEARED) == board.get_cell_count(),
			"%s: every artwork cell cleared; VOID still CLEARED" % spec[0])
		h.free()

func _settle(h) -> void:
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	var settled := 0
	for _i in range(20000):
		rt.tick(1.0 / 30.0)
		if h.get_completion().is_terminal():
			return
		if sch.live_assignment_count() == 0 and not sch.has_pending_lanes():
			settled += 1
			if settled >= 40:
				return
		else:
			settled = 0

func _host(level_dict: Dictionary, plan: Dictionary):
	var lp := _write("lvl", JSON.stringify(level_dict))
	var pp := _write("plan", JSON.stringify(plan))
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	get_root().add_child(h)
	var ok: bool = h.build()
	_ok(ok, "fixture host builds %s" % h.get_build_error())
	if not ok:
		h.free()
		return null
	h.get_runtime().set_process(false)
	return h

func _plan_from_engine(lvl, eng) -> Dictionary:
	var local_to_cid := {}
	var m: Dictionary = SupplyPlanLoader.cid_to_local_map(lvl)["map"]
	for cid in m:
		local_to_cid[int(m[cid])] = cid
	var cols: Array = []
	var mx := 1
	for col in eng.debug_snapshot()["columns"]:
		var q: Array = []
		for b in col:
			q.append({"batchId": String(b["batch_id"]), "cid": local_to_cid[int(b["color_id"])], "robots": int(b["robot_count"])})
			mx = maxi(mx, int(b["robot_count"]))
		cols.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": lvl.id, "columnCount": cols.size(),
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": mx, "ownerInput": "void-c001",
		"intendedColumnClicks": [], "columns": cols}

# ------------------------------------------------------------------- infra --------
func _write(tag: String, text: String) -> String:
	var p := "user://void_c001_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("VOID-CELLS-C001: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
