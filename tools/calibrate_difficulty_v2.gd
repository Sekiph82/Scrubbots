extends SceneTree
## M53-C002 — Difficulty V2-candidate calibration corpus, anchor freeze and First 10 holdout.
##
## Stages (each is a separate invocation, in this order):
##   -- --build-corpus         write QA-only fixtures + manifest (tests/fixtures/difficulty_calibration)
##   -- --measure=<fixture>    solvability proof + V2 raw measurement of one fixture
##   -- --calibrate            derive anchors by rule from the corpus ONLY, freeze the V2 config,
##                             score the corpus and check every declared ordinal relationship
##   -- --holdout=<level_id>   (requires a frozen config) V2 raw measurement of one First 10 level
##   -- --holdout-merge        score the First 10 holdout, compare with V1, write matrix
##
## The calibration stage never opens any First 10 file. Holdout stages refuse to run unless
## the config freeze hash matches the corpus evidence. Nothing here writes production content.

const V2 = preload("res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd")
const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
## SB-M53-C002-R01-001 R02: platform-independent evidence serialization (no C-runtime printf).
const Canon = preload("res://tools/m53_canonical_json.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const Tool1 = preload("res://tools/analyze_m53_first10.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const FIXTURE_DIR := "res://tests/fixtures/difficulty_calibration"
const MANIFEST_PATH := "res://tests/fixtures/difficulty_calibration/corpus_manifest_v1.json"
const EVIDENCE_DIR := "res://coordination/sessions/M53-C002/evidence"
const CORPUS_RAW_DIR := "res://coordination/sessions/M53-C002/evidence/corpus_raw"
const HOLDOUT_RAW_DIR := "res://coordination/sessions/M53-C002/evidence/holdout_raw"
const CORPUS_EVIDENCE := "res://coordination/sessions/M53-C002/evidence/calibration_corpus_v1.json"
const HOLDOUT_EVIDENCE := "res://coordination/sessions/M53-C002/evidence/difficulty_v2_candidate_first10.json"
const MATRIX_PATH := "res://coordination/sessions/M53-C002/DIFFICULTY_CALIBRATION_MATRIX_V01.md"
const V1_FIRST10 := "res://coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json"
const MAX_BATCH := 30

## Declared corpus (intent is fixed here, before any measurement).
const FIXTURES := [
	{"id": "flow_stripes3_20", "family": "FLOW_SIZE", "axis": "W", "size": 20, "shape": "stripes", "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "flow_stripes3_24", "family": "FLOW_SIZE", "axis": "W", "size": 24, "shape": "stripes", "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "flow_stripes3_32", "family": "FLOW_SIZE", "axis": "W", "size": 32, "shape": "stripes", "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "flow_stripes3_40", "family": "FLOW_SIZE", "axis": "W", "size": 40, "shape": "stripes", "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "flow_stripes3_48", "family": "FLOW_SIZE", "axis": "W", "size": 48, "shape": "stripes", "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "color_stripes6_24", "family": "COLOR_EXPLORATORY", "axis": "C", "size": 24, "shape": "stripes", "colors": ["C01", "C03", "C04", "C07", "C08", "C10"], "supply": "layer_rr"},
	{"id": "color_stripes12_24", "family": "COLOR_EXPLORATORY", "axis": "C", "size": 24, "shape": "stripes", "colors": ["C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C14"], "supply": "layer_rr"},
	{"id": "color_skew6_24", "family": "COLOR_EXPLORATORY", "axis": "C", "size": 24, "shape": "skew", "colors": ["C08", "C01", "C03", "C04", "C07", "C10"], "supply": "layer_rr"},
	{"id": "color_m3_24", "family": "COLOR", "axis": "C", "size": 24, "shape": "pattern12", "pattern": [0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2], "colors": ["C01", "C04", "C08"], "supply": "layer_rr"},
	{"id": "color_m6_24", "family": "COLOR", "axis": "C", "size": 24, "shape": "pattern12", "pattern": [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5], "colors": ["C01", "C03", "C04", "C07", "C08", "C10"], "supply": "layer_rr"},
	{"id": "color_m12_24", "family": "COLOR", "axis": "C", "size": 24, "shape": "pattern12", "pattern": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "colors": ["C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C14"], "supply": "layer_rr"},
	{"id": "color_m6skew_24", "family": "COLOR", "axis": "C", "size": 24, "shape": "pattern12", "pattern": [0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 1], "colors": ["C08", "C01", "C03", "C04", "C07", "C10"], "supply": "layer_rr"},
	{"id": "access_band3_24", "family": "ACCESSIBILITY", "axis": "A", "size": 24, "shape": "band", "colors": ["C01", "C07", "C03"], "supply": "color_first", "order": ["C01", "C07", "C03"]},
	{"id": "access_shafts3_24", "family": "ACCESSIBILITY", "axis": "A", "size": 24, "shape": "shafts", "colors": ["C01", "C07", "C03"], "supply": "color_first", "order": ["C01", "C07", "C03"]},
	{"id": "access_halves3_24", "family": "ACCESSIBILITY_EXPLORATORY", "axis": "A", "size": 24, "shape": "halves", "colors": ["C01", "C07", "C03"], "supply": "layer_rr"},
	{"id": "access_comb3_24", "family": "ACCESSIBILITY_EXPLORATORY", "axis": "A", "size": 24, "shape": "comb", "colors": ["C01", "C07", "C03"], "supply": "layer_rr"},
	{"id": "access_stripes4_24", "family": "ACCESSIBILITY_EXPLORATORY", "axis": "A", "size": 24, "shape": "stripes", "colors": ["C01", "C03", "C04", "C07"], "supply": "layer_rr"},
	{"id": "access_mosaic4_24", "family": "ACCESSIBILITY_EXPLORATORY", "axis": "A", "size": 24, "shape": "mosaic", "colors": ["C01", "C03", "C04", "C07"], "supply": "layer_rr"},
	{"id": "unlock_shallow_24", "family": "UNLOCK", "axis": "U", "size": 24, "shape": "shallow", "colors": ["C08", "C01", "C03"], "supply": "layer_rr"},
	{"id": "unlock_deep_24", "family": "UNLOCK", "axis": "U", "size": 24, "shape": "rings", "ring": 2, "colors": ["C08", "C01", "C03"], "supply": "layer_rr"},
	{"id": "route_straight_24", "family": "ROUTE", "axis": "R", "size": 24, "shape": "open_block", "colors": ["C07", "C14", "C03"], "supply": "color_first", "order": ["C07", "C14", "C03"]},
	{"id": "route_maze_24", "family": "ROUTE", "axis": "R", "size": 24, "shape": "maze", "colors": ["C07", "C14", "C03"], "supply": "color_first", "order": ["C07", "C14", "C03"]},
	{"id": "bottleneck_low_24", "family": "BOTTLENECK", "axis": "B", "size": 24, "shape": "rings", "ring": 4, "colors": ["C08", "C01", "C03"], "supply": "layer_rr"},
	{"id": "bottleneck_high_24", "family": "BOTTLENECK", "axis": "B", "size": 24, "shape": "rings", "ring": 4, "colors": ["C08", "C01", "C03"], "supply": "layer_split"},
	{"id": "slot_low_24", "family": "SLOT", "axis": "S", "size": 24, "shape": "slot_rings", "colors": ["C01", "C04", "C03"], "supply": "layer_rr"},
	{"id": "slot_high_24", "family": "SLOT", "axis": "S", "size": 24, "shape": "slot_rings", "colors": ["C01", "C04", "C03"], "supply": "straddle30"},
	{"id": "compact_hard_20", "family": "COMPACT_HARD", "axis": "D", "size": 20, "shape": "rings", "ring": 2, "colors": ["C08", "C01", "C03"], "supply": "layer_split"},
]

## Declared ordinal expectations: harder > easier on `axis` (a vector component, "W",
## "SL" = Session Load, or "D" alone) and, when requireD, also on Challenge D.
const PAIRS := [
	{"harder": "color_stripes6_24", "easier": "flow_stripes3_24", "axis": "C", "requireD": true, "why": "more balanced colours, same geometry"},
	{"harder": "color_stripes12_24", "easier": "color_stripes6_24", "axis": "C", "requireD": true, "why": "12 vs 6 balanced colours, same geometry"},
	{"harder": "color_stripes6_24", "easier": "color_skew6_24", "axis": "C", "requireD": true, "why": "same 6 colours, balanced vs one dominant"},
	{"harder": "access_shafts3_24", "easier": "access_band3_24", "axis": "A", "requireD": true, "why": "same colours/cell counts, both border-touching (unlock wave 0): eight 1-wide shafts expose ~8 targets at a time vs a solid band exposing a whole edge"},
	{"harder": "unlock_deep_24", "easier": "unlock_shallow_24", "axis": "U", "requireD": true, "why": "six alternating rings vs one outer band"},
	{"harder": "route_maze_24", "easier": "route_straight_24", "axis": "R", "requireD": true, "why": "serpentine single-entrance corridor vs open block"},
	{"harder": "bottleneck_high_24", "easier": "bottleneck_low_24", "axis": "B", "requireD": true, "why": "same board; outer layer only in column 1, inner layers only in columns 2-3"},
	{"harder": "slot_high_24", "easier": "slot_low_24", "axis": "S", "requireD": true, "why": "same board; 30-robot batches straddle rings and wait vs ring-aligned batches"},
	{"harder": "flow_stripes3_48", "easier": "flow_stripes3_20", "axis": "W", "requireD": false, "why": "workload grows with cells"},
	{"harder": "flow_stripes3_48", "easier": "flow_stripes3_20", "axis": "SL", "requireD": false, "why": "session load grows with cells"},
	{"harder": "compact_hard_20", "easier": "flow_stripes3_48", "axis": "D", "requireD": true, "why": "a compact 20x20 fortress/bottleneck is harder than a 48x48 flow board (size does not dictate class)"},
	{"harder": "color_m6_24", "easier": "color_m3_24", "axis": "C", "requireD": true, "why": "identical 12 two-wide stripes; 6 vs 3 balanced colours"},
	{"harder": "color_m12_24", "easier": "color_m6_24", "axis": "C", "requireD": true, "why": "identical 12 two-wide stripes; 12 vs 6 balanced colours"},
	{"harder": "color_m6_24", "easier": "color_m6skew_24", "axis": "C", "requireD": false, "why": "identical 12 two-wide stripes, 6 colours; balanced vs one colour on half the stripes", "dExpectationWithdrawn": "pre-freeze dry run: putting one colour on six narrow stripes also raises accessibility scarcity (A), so D is not expected to follow C for this pair; only the C ordering is claimed"},
]

## Hypotheses declared in the first corpus draft and WITHDRAWN before the freeze because the
## measured mechanics contradicted them (kept in the corpus and reported, never scored as pass/fail).
const WITHDRAWN_PAIRS := [
	{"harder": "unlock_deep_24", "easier": "color_stripes12_24", "axis": "D",
		"reason": "first-draft hypothesis treated color_stripes12_24 as a flow board. Its twelve 2-wide stripes each expose ~4 targets per 29-robot batch, so it is also an accessibility-scarcity board (A ~0.8): the pair confounded colour count with stripe width. Replaced by the geometry-matched colour family (color_m*) and the colourCountAlone family check."},
	{"harder": "access_comb3_24", "easier": "access_halves3_24", "axis": "A",
		"reason": "first-draft hypothesis. Under 30-robot batches both expose >= a batch of targets almost every state (per-batch A ~0 for both); clearing one comb frees the whole neighbouring comb, so interleaving increases, not decreases, exposure. Replaced by band vs shafts."},
	{"harder": "access_mosaic4_24", "easier": "access_stripes4_24", "axis": "A",
		"reason": "first-draft hypothesis. The 3x3 mosaic exposes a tile of every colour along the whole border and each clear exposes new tiles, while 6-wide stripes expose a single narrow frontier; measured scarcity is lower for the mosaic. The mosaic raises U (colour layers), not A."},
]

## Family checks (declared): flow-size D spread < smallest cycle-0 lane gap (40 - 22 = 18)
## and every flow fixture below the MEDIUM target 40.
const FLOW_SPREAD_LIMIT := 18.0
const FLOW_MAX_D := 40.0
## Colour count alone (revision 2, declared before freeze): 3-colour fixtures must span more
## than one lane gap (18) and at least one must score above the 12-colour matched fixture.
const COLOR_ALONE_SPAN := 18.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var code := 1
	for a in args:
		var s := String(a)
		if s == "--build-corpus":
			code = build_corpus()
		elif s.begins_with("--measure="):
			code = measure_fixture(s.substr(10))
		elif s == "--calibrate":
			code = calibrate(args.has("--refreeze"))
		elif s.begins_with("--holdout="):
			code = holdout_one(s.substr(10))
		elif s == "--holdout-merge":
			code = holdout_merge()
	quit(code)

# ============================================================================ corpus ==

static func fixture_level_path(id: String) -> String:
	return "%s/%s.level.json" % [FIXTURE_DIR, id]

static func fixture_supply_path(id: String) -> String:
	return "%s/%s.supply.json" % [FIXTURE_DIR, id]

static func spec_for(id: String) -> Dictionary:
	for f in FIXTURES:
		if f["id"] == id:
			return f
	return {}

## Colour (C-ID) at (x, y) for a fixture shape.
static func cid_at(spec: Dictionary, x: int, y: int) -> String:
	var n: int = spec["size"]
	var c: Array = spec["colors"]
	var d: int = mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
	match String(spec["shape"]):
		"stripes":
			return c[x * c.size() / n]
		"pattern12":
			return c[int(spec["pattern"][x * 12 / n])]
		"skew":
			return c[0] if x < n - 5 else c[1 + x - (n - 5)]
		"halves":
			if x >= n - 2 and y <= 1:
				return c[2]
			return c[0] if x < n / 2 else c[1]
		"comb":
			if x >= n - 2 and y >= n - 2:
				return c[2]
			if x == 0:
				return c[0]
			if x == n - 1:
				return c[1]
			return c[0] if (y / 2) % 2 == 0 else c[1]
		"mosaic":
			return c[(x / 3 + 2 * (y / 3)) % 4]
		"band", "shafts":
			if x >= n - 2 and y >= n - 2:
				return c[2]
			if y > n - 3:
				return c[1]
			if String(spec["shape"]) == "band":
				return c[0] if x < 8 else c[1]
			return c[0] if x % 3 == 1 else c[1]
		"shallow":
			if d < 4:
				return c[0]
			return c[1] if x < n / 2 else c[2]
		"rings":
			return c[(d / int(spec["ring"])) % c.size()]
		"slot_rings":
			if d >= 9:
				return c[2]
			return c[(d / 3) % 2]
		"maze", "open_block":
			if x >= n - 2 and y <= 1:
				return c[2]
			if String(spec["shape"]) == "open_block":
				return c[1] if (x == 0 or x == n - 1 or y == 0) else c[0]
			if y == n - 1:
				return c[0] if x == 1 else c[1]
			if x == 0 or x == n - 1 or y == 0:
				return c[1]
			if y % 2 == 1:
				return c[0]
			var k: int = y / 2
			var gap: int = 1 if k % 2 == 1 else n - 2
			return c[0] if x == gap else c[1]
	return c[0]

## Grid colour layers (0-1 BFS: border region 0, +1 per colour change). Supply design only.
static func grid_layers(w: int, h: int, cells: PackedInt32Array) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(w * h)
	dist.fill(1 << 30)
	var cur: Array = []
	for i in range(w * h):
		var x: int = i % w
		var y: int = i / w
		if x == 0 or y == 0 or x == w - 1 or y == h - 1:
			dist[i] = 0
			cur.append(i)
	var nxt: Array = []
	var level := 0
	while not cur.is_empty():
		while not cur.is_empty():
			var u: int = cur.pop_back()
			if dist[u] != level:
				continue
			for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
				var nx: int = u % w + d.x
				var ny: int = u / w + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var v: int = ny * w + nx
				var cost: int = 0 if cells[v] == cells[u] else 1
				if level + cost < dist[v]:
					dist[v] = level + cost
					(cur if cost == 0 else nxt).append(v)
		cur = nxt
		nxt = []
		level += 1
	return dist

static func _chunks(n: int) -> Array:
	var k: int = int(ceil(float(n) / float(MAX_BATCH)))
	var out: Array = []
	for i in range(k):
		out.append(n / k + (1 if i < n % k else 0))
	return out

## Build the fixture's supply columns: Array[3] of Array[{cid, robots}].
static func build_supply(spec: Dictionary, w: int, h: int, cells: PackedInt32Array, cids: Array) -> Array:
	var layers := grid_layers(w, h, cells)
	var batches: Array = []   # {cid, robots, layer}
	var strat := String(spec["supply"])
	if strat == "straddle30":
		for li in range(cids.size()):
			var idx: Array = []
			for i in range(cells.size()):
				if cells[i] == li:
					idx.append(i)
			idx.sort_custom(func(a, b): return layers[a] < layers[b] or (layers[a] == layers[b] and a < b))
			var s := 0
			while s < idx.size():
				var e: int = mini(s + MAX_BATCH, idx.size())
				batches.append({"cid": cids[li], "robots": e - s, "layer": layers[idx[s]]})
				s = e
		# Colour-first 30-robot batching: colours ordered by their outermost layer, each
		# colour's chunks in layer order — inner chunks of an outer colour must wait.
		var cmin := {}
		for b in batches:
			cmin[b["cid"]] = mini(int(cmin.get(b["cid"], 1 << 30)), int(b["layer"]))
		batches.sort_custom(func(a, b):
			if cmin[a["cid"]] != cmin[b["cid"]]:
				return cmin[a["cid"]] < cmin[b["cid"]]
			if a["cid"] != b["cid"]:
				return String(a["cid"]) < String(b["cid"])
			return a["layer"] < b["layer"])
	else:
		var groups := {}
		for i in range(cells.size()):
			var key: Array = [layers[i], cids[cells[i]]] if strat != "color_first" else [(spec["order"] as Array).find(cids[cells[i]]), cids[cells[i]]]
			var ks := "%04d|%s" % [key[0], key[1]]
			groups[ks] = int(groups.get(ks, 0)) + 1
		var keys: Array = groups.keys()
		keys.sort()
		for ks in keys:
			var parts: PackedStringArray = String(ks).split("|")
			for r in _chunks(int(groups[ks])):
				batches.append({"cid": parts[1], "robots": r, "layer": int(parts[0])})
	var cols: Array = [[], [], []]
	if strat == "layer_split":
		var alt := 1
		for b in batches:
			if int(b["layer"]) == 0:
				cols[0].append(b)
			else:
				cols[alt].append(b)
				alt = 3 - alt
	else:
		for i in range(batches.size()):
			cols[i % 3].append(batches[i])
	return cols

func build_corpus() -> int:
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
	var manifest_fx: Array = []
	for spec in FIXTURES:
		var n: int = spec["size"]
		var used := {}
		var grid: Array = []
		for y in range(n):
			for x in range(n):
				var cid := cid_at(spec, x, y)
				grid.append(cid)
				used[cid] = true
		var cids: Array = used.keys()
		cids.sort()
		var cells := PackedInt32Array()
		for cid in grid:
			cells.append(cids.find(cid))
		var palette: Array = []
		for cid in cids:
			palette.append(auth["cid_to_hex"][cid])
		var level := {"version": 1, "id": "calib_%s" % spec["id"], "name": "Calibration %s" % spec["id"],
			"difficulty": "TEST", "width": n, "height": n, "palette": palette, "cells": Array(cells)}
		var cols := build_supply(spec, n, n, cells, cids)
		var plan_cols: Array = []
		var bi := 0
		for c in range(3):
			var q: Array = []
			for b in cols[c]:
				bi += 1
				q.append({"batchId": "%s-%03d" % [spec["id"], bi], "cid": b["cid"], "robots": b["robots"]})
			plan_cols.append(q)
		var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "qaOnly": true,
			"columnCount": 3, "visiblePreviewDepth": 3, "maxRobotsPerBatch": MAX_BATCH,
			"supplyStrategy": spec["supply"], "columns": plan_cols}
		_write(fixture_level_path(spec["id"]), JSON.stringify(level) + "\n")
		_write(fixture_supply_path(spec["id"]), JSON.stringify(plan, "\t") + "\n")
		var m: Dictionary = spec.duplicate(true)
		m["levelPath"] = fixture_level_path(spec["id"])
		m["supplyPath"] = fixture_supply_path(spec["id"])
		m["usedColors"] = cids
		m["batches"] = bi
		manifest_fx.append(m)
	var manifest := {"schema": "scrubbots.m53.difficulty_calibration_corpus.v1", "version": 1, "qaOnly": true,
		"note": "QA-only calibration fixtures. Never production catalog content. Intent and ordinal expectations were declared before any measurement.",
		"fixtures": manifest_fx, "ordinalPairs": PAIRS, "withdrawnPairs": WITHDRAWN_PAIRS,
		"familyChecks": {"flowSizeSpreadLimitD": FLOW_SPREAD_LIMIT, "flowMaxD": FLOW_MAX_D,
			"reason": "board size alone must not move D across the smallest cycle-0 lane gap (EASY 22 -> MEDIUM 40 = 18) nor lift a flow board to the MEDIUM target"}}
	_write(MANIFEST_PATH, JSON.stringify(manifest, "\t") + "\n")
	print("CORPUS_BUILT fixtures=%d" % FIXTURES.size())
	return 0

static func load_fixture(id: String):
	return LevelLoader.load_from_path(fixture_level_path(id)).level_data

func measure_fixture(id: String) -> int:
	var spec := spec_for(id)
	var lvl = load_fixture(id)
	if spec.is_empty() or lvl == null:
		printerr("FIXTURE_MISSING %s" % id)
		return 1
	var make := func(): return SupplyPlanLoader.load_engine(fixture_supply_path(id), lvl)["engine"]
	var eng0 = make.call()
	if eng0 == null:
		printerr("SUPPLY_FAIL %s %s" % [id, SupplyPlanLoader.load_engine(fixture_supply_path(id), lvl)["error"]])
		return 1
	var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, eng0))
	var an = V2.new()
	var raw: Dictionary = an.measure(lvl, make)
	var out := {"schema": "scrubbots.m53.v2_raw.v1", "fixtureId": id, "levelSha256": Pack.content_sha256(fixture_level_path(id)),
		"supplySha256": Pack.content_sha256(fixture_supply_path(id)),
		"solvability": {"status": String(sol["status"]), "visited": sol["visited"], "decisions": sol["decisions"],
			"traceHash": sol.get("trace_hash", null)}, "raw": raw}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CORPUS_RAW_DIR))
	_write("%s/%s_raw.json" % [CORPUS_RAW_DIR, id], Canon.file_text(out))
	var comp := ""
	for p in raw["runs"]:
		comp += "%s:%s " % [p, "ok" if raw["runs"][p]["completed"] else "STOP(%s@%.2f)" % [raw["runs"][p]["stopReason"], raw["runs"][p]["finalProgress"]]]
	print("MEASURED_FIXTURE %s solver=%s ok=%s %s %dms" % [id, sol["status"], raw["ok"], comp, int(raw["timing"]["totalMs"])])
	return 0 if raw["ok"] and sol["status"] == SolvabilitySolver.SOLVED else 1

# ======================================================================== calibrate ==

static func _corpus_raw(id: String) -> Dictionary:
	return V1._read_json("%s/%s_raw.json" % [CORPUS_RAW_DIR, id])

static func derive_anchors(an, raws: Dictionary) -> Dictionary:
	var flow_a: Array = []
	var flow_len: Array = []
	var flow_det: Array = []
	var flow_turn: Array = []
	var dist := {"A_raw": [], "U_p95": [], "U_mean": [], "R_len": [], "R_detour": [], "R_turn": []}
	for spec in FIXTURES:
		var raw: Dictionary = raws[spec["id"]]["raw"]
		var agg: Dictionary = an.aggregate(raw, an.primary_ensemble())
		dist["A_raw"].append([spec["id"], agg["A_raw"]])
		dist["U_p95"].append([spec["id"], float(raw["unlock"]["p95Wave"])])
		dist["U_mean"].append([spec["id"], float(raw["unlock"]["meanWave"])])
		dist["R_len"].append([spec["id"], agg["R_len"]])
		dist["R_detour"].append([spec["id"], agg["R_detour"]])
		dist["R_turn"].append([spec["id"], agg["R_turn"]])
		if spec["family"] == "FLOW_SIZE":
			flow_a.append(agg["A_raw"])
			flow_len.append(agg["R_len"])
			flow_det.append(agg["R_detour"])
			flow_turn.append(agg["R_turn"])
	var mx := func(key: String) -> float:
		var m := -1e9
		for e in dist[key]:
			m = maxf(m, float(e[1]))
		return m
	var values := {"A_lo": V2._median(flow_a), "A_hi": mx.call("A_raw"),
		"U_p95_hi": mx.call("U_p95"), "U_mean_hi": mx.call("U_mean"),
		"R_len_lo": V2._median(flow_len), "R_len_hi": mx.call("R_len"),
		"R_detour_lo": V2._median(flow_det), "R_detour_hi": mx.call("R_detour"),
		"R_turn_lo": V2._median(flow_turn), "R_turn_hi": mx.call("R_turn")}
	return {"values": values, "rawDistributions": dist}

func calibrate(refreeze: bool) -> int:
	var cfg_text := FileAccess.get_file_as_string(V2.CONFIG_PATH)
	var cfg: Dictionary = JSON.parse_string(cfg_text)
	if cfg.get("freeze", null) != null and not refreeze:
		printerr("CONFIG_ALREADY_FROZEN (use --refreeze only before any holdout measurement exists)")
		return 1
	if refreeze and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(HOLDOUT_RAW_DIR)):
		printerr("REFREEZE_REFUSED: holdout measurements already exist")
		return 1
	var raws := {}
	for spec in FIXTURES:
		var r := _corpus_raw(spec["id"])
		if r.is_empty() or r["solvability"]["status"] != "SOLVED" or r["levelSha256"] != Pack.content_sha256(fixture_level_path(spec["id"])):
			printerr("CORPUS_RAW_INVALID %s" % spec["id"])
			return 1
		raws[spec["id"]] = r
	var an = V2.new()
	var derived := derive_anchors(an, raws)
	cfg["calibratedAnchors"] = {"values": derived["values"], "rules": cfg["anchorRules"],
		"derivedFrom": MANIFEST_PATH, "corpusManifestSha256": Pack.content_sha256(MANIFEST_PATH),
		"firstTenRead": false}
	cfg["freeze"] = {"frozen": true, "frozenBy": "tools/calibrate_difficulty_v2.gd --calibrate", "date": "2026-09-27",
		"rule": "No V2 candidate change after this point; First 10 holdout is measured and scored only against this exact file (sha256 recorded in calibration_corpus_v1.json)."}
	_write(V2.CONFIG_PATH, Canon.file_text(cfg))
	var cfg_sha := Pack.content_sha256(V2.CONFIG_PATH)
	an = V2.new()
	var scored := {}
	for spec in FIXTURES:
		scored[spec["id"]] = an.score(raws[spec["id"]]["raw"])
	var pair_results := check_pairs(scored)
	var fam := family_checks(scored)
	var sens := anchor_sensitivity(an, raws)
	var all_ok := true
	for p in pair_results:
		all_ok = all_ok and bool(p["pass"])
	for k in fam:
		all_ok = all_ok and bool(fam[k]["pass"])
	var robust_ok := true
	var fixtures_out: Array = []
	for spec in FIXTURES:
		var s: Dictionary = scored[spec["id"]]
		robust_ok = robust_ok and bool(s["robustness"]["pass"])
		fixtures_out.append({"id": spec["id"], "family": spec["family"], "intendedAxis": spec["axis"], "size": spec["size"],
			"usedColors": (spec["colors"] as Array).size(), "supply": spec["supply"],
			"solvability": raws[spec["id"]]["solvability"], "levelSha256": raws[spec["id"]]["levelSha256"],
			"supplySha256": raws[spec["id"]]["supplySha256"],
			"vector": s["vector"], "challengeScore": s["challengeScore"], "sessionLoad": s["sessionLoad"],
			"unlock": s["unlock"], "aggregateRaw": s["aggregateRaw"], "policySpread": s["policySpread"],
			"robustness": s["robustness"], "frustration": s["frustration"], "profile": s["profile"]})
	var ev := {"schema": "scrubbots.m53.calibration_corpus_evidence.v1", "version": 1, "sprint": "M53-C002",
		"analyzer": an.provenance(), "frozenConfigSha256": cfg_sha,
		"corpusManifestSha256": Pack.content_sha256(MANIFEST_PATH),
		"anchors": {"values": derived["values"], "rules": cfg["anchorRules"], "rawDistributions": derived["rawDistributions"]},
		"anchorSensitivity": sens, "ordinalPairs": pair_results, "familyChecks": fam,
		"policyRobustness": {"toleranceD": cfg["policies"]["robustnessToleranceD"], "allFixturesWithinTolerance": robust_ok},
		"calibrationPass": all_ok and robust_ok, "firstTenRead": false, "fixtures": fixtures_out}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_DIR))
	_write(CORPUS_EVIDENCE, Canon.file_text(ev))
	for p in pair_results:
		print("PAIR %s > %s on %s: axis %s D %s -> %s" % [p["harder"], p["easier"], p["axis"], p["axisPass"], p["dPass"], "PASS" if p["pass"] else "FAIL"])
	for k in fam:
		print("FAMILY %s: %s %s" % [k, "PASS" if fam[k]["pass"] else "FAIL", str(fam[k])])
	print("CALIBRATED config_sha=%s pairs_ok=%s robust_ok=%s" % [cfg_sha, all_ok, robust_ok])
	return 0 if all_ok and robust_ok else 2

static func axis_value(s: Dictionary, axis: String) -> float:
	if axis == "SL":
		return float(s["sessionLoad"])
	if axis == "D":
		return float(s["challengeScore"])
	return float(s["vector"][axis])

static func check_pairs(scored: Dictionary) -> Array:
	var out: Array = []
	for p in PAIRS:
		var h: Dictionary = scored[p["harder"]]
		var e: Dictionary = scored[p["easier"]]
		var ax_ok: bool = axis_value(h, p["axis"]) > axis_value(e, p["axis"])
		var d_ok: bool = (not bool(p["requireD"])) or float(h["challengeScore"]) > float(e["challengeScore"])
		out.append({"harder": p["harder"], "easier": p["easier"], "axis": p["axis"], "why": p["why"],
			"harderAxis": axis_value(h, p["axis"]), "easierAxis": axis_value(e, p["axis"]),
			"harderD": h["challengeScore"], "easierD": e["challengeScore"], "requireD": p["requireD"],
			"axisPass": ax_ok, "dPass": d_ok, "pass": ax_ok and d_ok})
	return out

static func family_checks(scored: Dictionary) -> Dictionary:
	var ds: Array = []
	for spec in FIXTURES:
		if spec["family"] == "FLOW_SIZE":
			ds.append(float(scored[spec["id"]]["challengeScore"]))
	var spread: float = ds.max() - ds.min()
	var three: Array = []
	var best3 := ""
	for spec in FIXTURES:
		if (spec["colors"] as Array).size() == 3:
			var d3: float = scored[spec["id"]]["challengeScore"]
			three.append(d3)
			if best3 == "" or d3 > float(scored[best3]["challengeScore"]):
				best3 = spec["id"]
	var d12: float = scored["color_m12_24"]["challengeScore"]
	return {"flowSizeSpread": {"values": ds, "spread": spread, "limit": FLOW_SPREAD_LIMIT, "pass": spread < FLOW_SPREAD_LIMIT},
		"flowBelowMedium": {"max": ds.max(), "limit": FLOW_MAX_D, "pass": ds.max() < FLOW_MAX_D},
		"colourCountAlone": {"threeColourSpan": three.max() - three.min(), "spanLimit": COLOR_ALONE_SPAN,
			"highestThreeColour": best3, "highestThreeColourD": three.max(), "twelveColourMatchedD": d12,
			"pass": three.max() - three.min() > COLOR_ALONE_SPAN and three.max() > d12}}

## Each anchor x0.8 / x1.25 (one at a time): do the declared ordinal relationships and
## family checks still hold? (Informational; reported, not used to choose anchors.)
static func anchor_sensitivity(an, raws: Dictionary) -> Array:
	var rows: Array = []
	var base: Dictionary = an.anchors()
	for k in V2.ANCHOR_KEYS:
		for f in [0.8, 1.25]:
			var scored := {}
			for spec in FIXTURES:
				scored[spec["id"]] = an.score(raws[spec["id"]]["raw"], 0, {k: float(base[k]) * f})
			var pr := check_pairs(scored)
			var fails: Array = []
			for p in pr:
				if not p["pass"]:
					fails.append("%s>%s" % [p["harder"], p["easier"]])
			var fam := family_checks(scored)
			rows.append({"anchor": k, "factor": f, "pairFailures": fails,
				"familyPass": fam["flowSizeSpread"]["pass"] and fam["flowBelowMedium"]["pass"] and fam["colourCountAlone"]["pass"]})
	return rows

# ========================================================================== holdout ==

static func frozen_ok() -> Dictionary:
	var cfg: Dictionary = V1._read_json(V2.CONFIG_PATH)
	var ev: Dictionary = V1._read_json(CORPUS_EVIDENCE)
	if cfg.get("freeze", null) == null or ev.is_empty():
		return {"ok": false, "error": "V2 config not frozen / corpus evidence missing"}
	if Pack.content_sha256(V2.CONFIG_PATH) != String(ev["frozenConfigSha256"]):
		return {"ok": false, "error": "V2 config changed after freeze"}
	if not bool(ev["calibrationPass"]):
		return {"ok": false, "error": "calibration did not pass"}
	return {"ok": true}

func holdout_one(id: String) -> int:
	var fz := frozen_ok()
	if not fz["ok"]:
		printerr("HOLDOUT_REFUSED %s" % fz["error"])
		return 1
	var lvl = Tool1.load_level(id)
	var ref: Dictionary = Tool1.reference_inputs(id, lvl)
	if not ref["ok"]:
		printerr("REFERENCE_FAIL %s" % ref["error"])
		return 1
	var oracle: Array = []
	for t in ref["trace"]:
		oracle.append(int(t["column"]))
	var fixed := {"ORACLE_DIAGNOSTIC": oracle}
	if not (ref["ownerClicks"] as Array).is_empty():
		fixed["OWNER_DIAGNOSTIC"] = ref["ownerClicks"]
	var an = V2.new()
	var raw: Dictionary = an.measure(lvl, ref["make_engine"], fixed)
	var out := {"schema": "scrubbots.m53.v2_raw.v1", "levelId": id, "levelSha256": Pack.content_sha256(Pack.level_path(id)),
		"frozenConfigSha256": Pack.content_sha256(V2.CONFIG_PATH), "supplyAuthority": ref["supplyAuthority"],
		"solvability": {"status": "SOLVED", "traceHash": ref["traceHash"], "traceSource": ref["traceSource"],
			"note": "oracle trace used ONLY as solvability provenance and as the ORACLE_DIAGNOSTIC run; never in primary D"},
		"raw": raw}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(HOLDOUT_RAW_DIR))
	_write("%s/%s_raw.json" % [HOLDOUT_RAW_DIR, id], Canon.file_text(out))
	print("MEASURED_HOLDOUT %s ok=%s %dms" % [id, raw["ok"], int(raw["timing"]["totalMs"])])
	return 0 if raw["ok"] else 1

func holdout_merge() -> int:
	var fz := frozen_ok()
	if not fz["ok"]:
		printerr("HOLDOUT_REFUSED %s" % fz["error"])
		return 1
	var an = V2.new()
	var prog = DifficultyProgressionV1.new()
	var v1: Dictionary = V1._read_json(V1_FIRST10)
	var levels: Array = []
	for spec in Tool1.LEVELS:
		var id: String = spec["id"]
		var n: int = spec["order"]
		var r: Dictionary = V1._read_json("%s/%s_raw.json" % [HOLDOUT_RAW_DIR, id])
		if r.is_empty():
			printerr("HOLDOUT_RAW_MISSING %s" % id)
			return 1
		var s: Dictionary = an.score(r["raw"], n)
		var v1r: Dictionary = v1["levels"][n - 1]
		var diag := {}
		for name in ["ORACLE_DIAGNOSTIC", "OWNER_DIAGNOSTIC"]:
			if s["policySpread"]["perPolicy"].has(name):
				diag[name] = s["policySpread"]["perPolicy"][name]["D"]
		var hsens: Array = []
		var base: Dictionary = an.anchors()
		var dmin := 1e9
		var dmax := -1e9
		for k in V2.ANCHOR_KEYS:
			for f in [0.8, 1.25]:
				var d: float = an.score(r["raw"], n, {k: float(base[k]) * f})["challengeScore"]
				dmin = minf(dmin, d)
				dmax = maxf(dmax, d)
		levels.append({"order": n, "id": id, "class": prog.class_for(n), "role": prog.role_for(n),
			"levelSha256": r["levelSha256"], "frozenConfigSha256": r["frozenConfigSha256"],
			"v1StageA": {"challengeScore": v1r["challengeScore"], "vector": v1r["vector"], "acceptanceWindow": v1r["acceptanceWindow"],
				"sessionLoad": v1r["sessionLoad"]["value"]},
			"v2Candidate": {"challengeScore": s["challengeScore"], "vector": s["vector"], "targetChallenge": s["targetChallenge"],
				"signedDelta": s["signedDelta"], "absoluteDelta": s["absoluteDelta"], "acceptanceWindow": s["acceptanceWindow"],
				"sessionLoad": s["sessionLoad"], "sessionInputs": s["sessionInputs"], "unlock": s["unlock"],
				"aggregateRaw": s["aggregateRaw"], "profile": s["profile"]},
			"policySpread": s["policySpread"], "robustness": s["robustness"], "strategyFamilySpread": s["strategyFamilySpread"],
			"diagnosticPathsD": diag,
			"anchorSensitivityDRange": [dmin, dmax], "frustration": s["frustration"],
			"verdict": "FITS_TARGET_WINDOW" if s["acceptanceWindow"] == V1.WINDOW_IN else "MISSES_TARGET_WINDOW"})
	var rec := Tool1.recovery_checks(_as_v1_shape(levels), prog)
	var summary := {"inDefaultWindow": 0, "missing": [], "robustnessPassAll": true}
	for l in levels:
		if l["v2Candidate"]["acceptanceWindow"] == V1.WINDOW_IN:
			summary["inDefaultWindow"] += 1
		else:
			summary["missing"].append(l["id"])
		summary["robustnessPassAll"] = summary["robustnessPassAll"] and bool(l["robustness"]["pass"])
	# Corpus strategy-family spread (re-scored from the committed corpus raw with the frozen
	# config; reporting only - calibration evidence itself is not rewritten).
	var corpus_fam := {}
	for spec in FIXTURES:
		var cs: Dictionary = an.score(_corpus_raw(spec["id"])["raw"])
		corpus_fam[spec["id"]] = {"maxLeaveFamilyOutDeviation": cs["strategyFamilySpread"]["maxLeaveFamilyOutDeviation"],
			"familyOnlyD": cs["strategyFamilySpread"]["familyOnlyD"], "gatedMaxDeviation": cs["robustness"]["maxDeviation"]}
	var out := {"schema": "scrubbots.m53.first10_difficulty_v2_candidate.v1", "version": 1, "sprint": "M53-C002",
		"status": "CANDIDATE_HOLDOUT_EVALUATION (not production authority)", "analyzer": an.provenance(),
		"frozenConfigSha256": Pack.content_sha256(V2.CONFIG_PATH), "summary": summary, "recovery": rec,
		"corpusStrategyFamilySpread": corpus_fam, "levels": levels}
	_write(HOLDOUT_EVIDENCE, Canon.file_text(out))
	_write(MATRIX_PATH, matrix_md(levels, rec, summary, V1._read_json(CORPUS_EVIDENCE), corpus_fam))
	print("HOLDOUT_MERGED inWindow=%d missing=%s robustAll=%s" % [summary["inDefaultWindow"], str(summary["missing"]), summary["robustnessPassAll"]])
	return 0

static func _as_v1_shape(levels: Array) -> Array:
	var out: Array = []
	for l in levels:
		out.append({"order": l["order"], "challengeScore": l["v2Candidate"]["challengeScore"],
			"sessionLoad": {"value": l["v2Candidate"]["sessionLoad"]}})
	return out

static func _f(v, d: int = 2) -> String:
	return ("%." + str(d) + "f") % float(v)

static func matrix_md(levels: Array, rec: Dictionary, summary: Dictionary, corpus: Dictionary, corpus_fam: Dictionary) -> String:
	var L := PackedStringArray()
	L.append("# M53-C002 — DIFFICULTY CALIBRATION MATRIX V01")
	L.append("")
	L.append("Status: GENERATED (tools/calibrate_difficulty_v2.gd) — V2 CANDIDATE, not production authority; awaiting ChatGPT audit and owner decision.")
	L.append("Frozen V2 config sha256: `%s` (frozen before any First 10 measurement)." % corpus["frozenConfigSha256"])
	L.append("")
	L.append("## 1. Calibration corpus (independent, QA-only)")
	L.append("")
	L.append("| Fixture | Family | Axis | Size | Colours | D | W | C | A | U | B | R | S | SL | Policy D range | Gated robust max dev | Strategy-family max dev |")
	L.append("|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|")
	for f in corpus["fixtures"]:
		var v: Dictionary = f["vector"]
		var pr: Array = f["policySpread"]["primaryEnsembleDRange"]
		L.append("| `%s` | %s | %s | %d | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s–%s | %s | %s |" % [f["id"], f["family"], f["intendedAxis"],
			int(f["size"]), int(f["usedColors"]), _f(f["challengeScore"]), _f(v["W"], 3), _f(v["C"], 3), _f(v["A"], 3), _f(v["U"], 3),
			_f(v["B"], 3), _f(v["R"], 3), _f(v["S"], 3), _f(f["sessionLoad"], 1), _f(pr[0]), _f(pr[1]), _f(f["robustness"]["maxDeviation"]),
			_f(corpus_fam[f["id"]]["maxLeaveFamilyOutDeviation"])])
	L.append("")
	L.append("### Ordinal relationships (declared before measurement)")
	L.append("")
	L.append("| Harder | Easier | Axis | Axis harder / easier | D harder / easier | Result |")
	L.append("|---|---|---|---|---|---|")
	for p in corpus["ordinalPairs"]:
		L.append("| `%s` | `%s` | %s | %s / %s | %s / %s | %s |" % [p["harder"], p["easier"], p["axis"], _f(p["harderAxis"], 3), _f(p["easierAxis"], 3),
			_f(p["harderD"]), _f(p["easierD"]), "PASS" if p["pass"] else "**FAIL**"])
	var fc: Dictionary = corpus["familyChecks"]
	L.append("")
	L.append("Flow-size family (20..48): D spread %s (< %s) %s; max D %s (< %s) %s." % [_f(fc["flowSizeSpread"]["spread"]), _f(fc["flowSizeSpread"]["limit"], 0),
		"PASS" if fc["flowSizeSpread"]["pass"] else "FAIL", _f(fc["flowBelowMedium"]["max"]), _f(fc["flowBelowMedium"]["limit"], 0), "PASS" if fc["flowBelowMedium"]["pass"] else "FAIL"])
	L.append("")
	L.append("### Frozen anchors (rule-derived from the corpus only)")
	L.append("")
	L.append("| Anchor | Value | Rule |")
	L.append("|---|---:|---|")
	for k in V2.ANCHOR_KEYS:
		L.append("| %s | %s | %s |" % [k, _f(corpus["anchors"]["values"][k], 4), corpus["anchors"]["rules"][k]])
	L.append("")
	L.append("## 2. First 10 holdout — V1 Stage A vs V2 candidate")
	L.append("")
	L.append("In default ±3.5 window under V2: **%d/10**. Policy robustness within ±%s D on all ten: **%s**." % [int(summary["inDefaultWindow"]),
		_f(levels[0]["robustness"]["toleranceD"]), "yes" if summary["robustnessPassAll"] else "NO"])
	L.append("")
	L.append("| L | ID | Class | Target | V1 D | V2 D | V2 delta | V2 window | W | C | A | U | B | R | S | V2 SL | Policy D range (6 non-adv) | Gated robust max dev | Strategy-family max dev | Oracle / owner path D (diag) | Anchor ±sens D |")
	L.append("|---:|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---|---|")
	for l in levels:
		var c: Dictionary = l["v2Candidate"]
		var v: Dictionary = c["vector"]
		var pp: Dictionary = l["policySpread"]["perPolicy"]
		var lo := 1e9
		var hi := -1e9
		for k in ["RR", "GREEDY", "ACCESS", "RR_REV", "GREEDY_HI", "ACCESS_HI"]:
			lo = minf(lo, float(pp[k]["D"]))
			hi = maxf(hi, float(pp[k]["D"]))
		var dg: Dictionary = l["diagnosticPathsD"]
		L.append("| %d | `%s` | %s | %s | %s | **%s** | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s–%s | %s | %s | %s / %s | %s–%s |" % [l["order"], l["id"], l["class"],
			_f(c["targetChallenge"], 0), _f(l["v1StageA"]["challengeScore"]), _f(c["challengeScore"]), "%+.2f" % float(c["signedDelta"]), c["acceptanceWindow"],
			_f(v["W"], 3), _f(v["C"], 3), _f(v["A"], 3), _f(v["U"], 3), _f(v["B"], 3), _f(v["R"], 3), _f(v["S"], 3), _f(c["sessionLoad"], 1),
			_f(lo), _f(hi), _f(l["robustness"]["maxDeviation"]), _f(l["strategyFamilySpread"]["maxLeaveFamilyOutDeviation"]), _f(dg.get("ORACLE_DIAGNOSTIC", 0.0)), _f(dg["OWNER_DIAGNOSTIC"]) if dg.has("OWNER_DIAGNOSTIC") else "n/a",
			_f(l["anchorSensitivityDRange"][0]), _f(l["anchorSensitivityDRange"][1])])
	L.append("")
	L.append("### Recovery cadence (actual V2 D)")
	L.append("")
	L.append("| From → To | D from → to | Drop | Design min | Guard |")
	L.append("|---|---|---:|---:|---|")
	for g in rec["guards"]:
		L.append("| L%d → L%d | %s → %s | %s | %s | %s |" % [g["fromLevel"], g["toLevel"], _f(g["actualFrom"]), _f(g["actualTo"]), _f(g["actualDrop"]),
			_f(g["designMinimumDrop"], 0), "PASS" if g["pass"] else "FAIL"])
	L.append("")
	L.append("L10 boss: V2 D %s, rank %d of 10, cycle maximum: %s." % [_f(rec["boss"]["actualD"]), int(rec["boss"]["rankByActualD"]), "yes" if rec["boss"]["isCycleMaximum"] else "NO"])
	L.append("")
	L.append("### Stress policy / provisional Frustration")
	L.append("")
	L.append("| L | Stress completed | Stress stop | Failure progress | Dead placements | Choice opacity | Primary policies completed |")
	L.append("|---:|---|---|---:|---:|---:|---|")
	for l in levels:
		var fr: Dictionary = l["frustration"]
		var lf: Dictionary = fr["components"]["lateFailure"]
		L.append("| %d | %s | %s | %s | %d | %s | %s |" % [l["order"], "yes" if lf["stressCompleted"] else "no", lf["stressStopReason"],
			"—" if lf["stressFailureProgress"] == null else _f(lf["stressFailureProgress"]), int(fr["stressDeadPlacements"]),
			_f(fr["components"]["choiceOpacity"]["value"], 3), fr["primaryPoliciesCompleted"]])
	L.append("")
	L.append("Frustration Risk stays PROVISIONAL_STAGE_A with no scalar; retry risk and session overrun remain UNSUPPORTED. Policy completion is not a human clear rate.")
	return "\n".join(L) + "\n"

static func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("WRITE_FAIL %s" % path)
		return false
	f.store_string(text)
	f.close()
	return true
