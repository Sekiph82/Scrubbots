extends SceneTree
## SB-M36-013 — lane anchor corpus builder (QA-only TEST fixtures; never production content).
##
##   godot --headless --path . -s res://tools/build_difficulty_anchors.gd
##
## Writes tests/fixtures/difficulty_anchors/<id>.level.json + <id>.supply.json for every
## declared fixture and anchor_manifest_v1.json. Every fixture is designed from the score
## component rules (docs/09, docs/10, level_difficulty_analysis_v2.json definitions) for its
## lane, declared here before any Challenge measurement. Geometry and supply are pure
## functions of the declaration (no seeds, no time), so a rerun yields identical bytes.
## Each fixture must load legally and be SOLVED by the canonical solver, or the build fails.
## Supply strategies reuse tools/calibrate_difficulty_v2.gd build_supply.

const Calib = preload("res://tools/calibrate_difficulty_v2.gd")
const Canon = preload("res://tools/m53_canonical_json.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const FIXTURE_DIR := "res://tests/fixtures/difficulty_anchors"
const MANIFEST_PATH := "res://tests/fixtures/difficulty_anchors/anchor_manifest_v1.json"
const LANES := ["EASY", "MEDIUM", "HARD", "VERY_HARD"]
## Colour index i of a fixture uses PALETTE[i] (canonical C01..C16 only, <= 12 per fixture).
const PALETTE := ["C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C14"]

## Shapes (colour index at x, y; d = distance to the nearest border):
##   vstripes / hbands          k equal stripes, every colour touches the border
##   tiles(tile, mul)           square tiles, colour (tx + mul*ty) % k
##   frame(t)                   border frame of width t in colour 0, interior vertical stripes 1..k-1
##   shafts(nb)                 nb wide base stripes; every x%3==1 column is a 1-wide shaft of colour nb + (x/3)%(k-nb)
##   rings(rw, ns)              concentric rings of width rw split into ns sectors (1/2/4), colour (ring*ns + sector) % k
##   maze(nc)                   serpentine 1-wide corridor entered only at the bottom-left; corridor colours 0..nc-1 in
##                              path order (bottom first), walls colours nc..k-1 by row
## Supply strategies (Calib.build_supply): layer_rr (unlock-layer order, round robin), color_first (declared colour
## order), layer_split (border layer alone in column 1, inner layers alternate columns 2/3), straddle30 (colour-first
## 30-robot chunks that straddle layers and must wait in slots).
const FIXTURES := [
	# ---------------------------------------------------------------- EASY
	{"id": "easy_vstripes3_24", "lane": "EASY", "w": 24, "h": 24, "shape": "vstripes", "k": 3, "supply": "layer_rr",
		"profile": {"W": "low", "C": "low", "A": "low", "U": "low", "B": "low", "R": "low", "S": "low"},
		"rationale": "Minimum structure: three balanced border-touching stripes, so every batch finds a full frontier (A low), every cell is in unlock wave 0 (U low) and unlock-ordered round-robin supply leaves every column productive (B, S low)."},
	{"id": "easy_hbands4_24x28", "lane": "EASY", "w": 24, "h": 28, "shape": "hbands", "k": 4, "supply": "layer_rr",
		"profile": {"W": "low", "C": "low", "A": "low", "U": "low", "B": "low", "R": "low", "S": "low"},
		"rationale": "Four horizontal bands on a rectangular board: each band touches both side borders, so access stays open and unlock is one wave; one more colour than the stripes fixture raises colour complexity slightly."},
	{"id": "easy_tiles4_24", "lane": "EASY", "w": 24, "h": 24, "shape": "tiles", "tile": 12, "mul": 2, "k": 4, "supply": "layer_rr",
		"profile": {"W": "low", "C": "low", "A": "low", "U": "low", "B": "low", "R": "low", "S": "low"},
		"rationale": "Four large quadrant tiles, each touching two borders: many simultaneous targets per colour and a single unlock wave; four balanced colours give low-moderate colour complexity."},
	{"id": "easy_frame5_24", "lane": "EASY", "w": 24, "h": 24, "shape": "frame", "t": 2, "k": 5, "supply": "layer_rr",
		"profile": {"W": "low", "C": "mid", "A": "low", "U": "low", "B": "low", "R": "low", "S": "low"},
		"rationale": "A 2-wide border frame encloses four interior stripes: a shallow one-layer unlock (U low-moderate) with wide frontiers once the frame clears; five colours sit at the top of the EASY colour range."},
	{"id": "easy_rings4_24", "lane": "EASY", "w": 24, "h": 24, "shape": "rings", "rw": 6, "ns": 2, "k": 4, "supply": "layer_rr",
		"profile": {"W": "low", "C": "low", "A": "low", "U": "mid", "B": "low", "R": "low", "S": "low"},
		"rationale": "Two wide 6-cell rings split into halves: the inner ring opens only after the outer ring (one extra unlock layer) but every layer exposes a long frontier, so access and choice stay easy; the upper edge of the EASY design range."},
	# -------------------------------------------------------------- MEDIUM
	{"id": "med_rings6q_24", "lane": "MEDIUM", "w": 24, "h": 24, "shape": "rings", "rw": 4, "ns": 4, "k": 6, "supply": "layer_rr",
		"profile": {"W": "low", "C": "mid", "A": "mid", "U": "mid", "B": "low", "R": "low", "S": "mid"},
		"rationale": "Three 4-wide rings split into quadrants with six colours: moderate enclosure (three unlock layers) and four colours per layer, so batches of one colour reach only a quarter of the open frontier (moderate A and S)."},
	{"id": "med_rings6h_24", "lane": "MEDIUM", "w": 24, "h": 24, "shape": "rings", "rw": 3, "ns": 2, "k": 6, "supply": "layer_rr",
		"profile": {"W": "low", "C": "mid", "A": "mid", "U": "mid", "B": "low", "R": "low", "S": "low"},
		"rationale": "Four 3-wide rings split into halves with six colours: one more unlock layer than the quadrant rings with only two colours per layer, so enclosure rises while colour/slot pressure stays moderate."},
	{"id": "med_shafts6_24", "lane": "MEDIUM", "w": 24, "h": 24, "shape": "shafts", "nb": 3, "k": 6, "supply": "layer_rr",
		"profile": {"W": "low", "C": "mid", "A": "high", "U": "low", "B": "low", "R": "low", "S": "mid"},
		"rationale": "Three base stripes cut by 1-wide vertical shafts of three further colours: everything touches the border (U low) but each shaft exposes only two end cells to a whole batch, so accessibility scarcity is the main pressure."},
	{"id": "med_tiles7_24", "lane": "MEDIUM", "w": 24, "h": 24, "shape": "tiles", "tile": 6, "mul": 3, "k": 7, "supply": "layer_rr",
		"profile": {"W": "low", "C": "mid", "A": "mid", "U": "mid", "B": "low", "R": "low", "S": "mid"},
		"rationale": "A 4x4 grid of 6-cell tiles in seven colours: the four centre tiles are enclosed by one colour change (moderate unlock depth) and seven interleaved colours spread demand across many small frontiers."},
	{"id": "med_rings8q_straddle_28", "lane": "MEDIUM", "w": 28, "h": 28, "shape": "rings", "rw": 4, "ns": 4, "k": 8, "supply": "straddle30",
		"profile": {"W": "mid", "C": "mid", "A": "mid", "U": "mid", "B": "mid", "R": "low", "S": "high"},
		"rationale": "Four 4-wide quadrant rings in eight colours with colour-first 30-robot chunks that straddle layers: moderate enclosure plus slot pressure from batches that wait for inner layers; the upper edge of the MEDIUM design range."},
	# ---------------------------------------------------------------- HARD
	{"id": "hard_rings8h_24", "lane": "HARD", "w": 24, "h": 24, "shape": "rings", "rw": 2, "ns": 2, "k": 8, "supply": "layer_rr",
		"profile": {"W": "low", "C": "high", "A": "mid", "U": "high", "B": "low", "R": "mid", "S": "mid"},
		"rationale": "Six 2-wide half-rings in eight colours: a deep six-layer unlock chain where each layer has two colours, with layer-ordered supply so the chain, not the queue, carries the difficulty."},
	{"id": "hard_rings9q_split_24", "lane": "HARD", "w": 24, "h": 24, "shape": "rings", "rw": 3, "ns": 4, "k": 9, "supply": "layer_split",
		"profile": {"W": "low", "C": "high", "A": "mid", "U": "high", "B": "high", "R": "mid", "S": "mid"},
		"rationale": "Four 3-wide quadrant rings in nine colours with the border layer alone in column 1: early decisions have one productive column (bottlenecks) on top of a four-layer unlock chain."},
	{"id": "hard_maze8_24", "lane": "HARD", "w": 24, "h": 24, "shape": "maze", "nc": 4, "k": 8, "supply": "color_first",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "mid", "R": "high", "S": "mid"},
		"rationale": "A serpentine 1-wide corridor with one entrance, coloured in four path-ordered segments and demanded first: robots follow long winding routes (R high) to a narrow two-cell frontier (A high) before the eight-colour walls open."},
	{"id": "hard_rings10h_26", "lane": "HARD", "w": 26, "h": 26, "shape": "rings", "rw": 2, "ns": 2, "k": 10, "supply": "layer_rr",
		"profile": {"W": "mid", "C": "high", "A": "mid", "U": "high", "B": "low", "R": "mid", "S": "mid"},
		"rationale": "Seven 2-wide half-rings in ten colours on a 26 board: the deepest layered chain of the HARD set with ten colours, but layer-ordered supply keeps bottlenecks low."},
	{"id": "hard_tiles9_split_24", "lane": "HARD", "w": 24, "h": 24, "shape": "tiles", "tile": 4, "mul": 4, "k": 9, "supply": "layer_split",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "mid"},
		"rationale": "A 6x6 grid of 4-cell tiles in nine interleaved colours with the border layer isolated in column 1: many small enclosed tiles give a deep unlock and small frontiers, and the split supply forces single-column decisions early."},
	# ----------------------------------------------------------- VERY_HARD
	{"id": "vh_rings12h_split_24", "lane": "VERY_HARD", "w": 24, "h": 24, "shape": "rings", "rw": 2, "ns": 2, "k": 12, "supply": "layer_split",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "high"},
		"rationale": "Six 2-wide half-rings in twelve colours (every layer two new colours) with the border layer alone in column 1: deep enclosure, maximum colour count and forced single-column choices."},
	{"id": "vh_rings11h_straddle_24", "lane": "VERY_HARD", "w": 24, "h": 24, "shape": "rings", "rw": 2, "ns": 2, "k": 11, "supply": "straddle30",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "mid", "R": "mid", "S": "high"},
		"rationale": "Six 2-wide half-rings in eleven colours with colour-first chunks that straddle layers: deep enclosure plus slots held by batches whose targets are still enclosed (slot/colour pressure)."},
	{"id": "vh_maze10_24", "lane": "VERY_HARD", "w": 24, "h": 24, "shape": "maze", "nc": 5, "k": 10, "supply": "color_first",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "high", "S": "high"},
		"rationale": "A single-entrance serpentine corridor in five path-ordered colours demanded before five wall colours: long routes, a two-cell frontier and colour-first supply where most offered batches cannot progress."},
	{"id": "vh_rings10h_r1_split_24", "lane": "VERY_HARD", "w": 24, "h": 24, "shape": "rings", "rw": 1, "ns": 2, "k": 10, "supply": "layer_split",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "high"},
		"rationale": "Twelve 1-wide half-rings in ten colours with the border layer isolated: a twelve-layer unlock chain where each layer is a narrow frontier, and split supply forcing choices."},
	{"id": "vh_rings12q_split_26", "lane": "VERY_HARD", "w": 26, "h": 26, "shape": "rings", "rw": 2, "ns": 4, "k": 12, "supply": "layer_split",
		"profile": {"W": "mid", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "high"},
		"rationale": "Seven 2-wide quadrant rings in twelve colours on a 26 board: four colours per layer split the frontier into quarters, a seven-layer chain, and border-isolated split supply."},
	# ------------------------------------------------------------- EXTREME (ceiling probes, never in a lane median)
	{"id": "x_rings12q_r1_split_24", "lane": "EXTREME", "w": 24, "h": 24, "shape": "rings", "rw": 1, "ns": 4, "k": 12, "supply": "layer_split",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "high"},
		"rationale": "Ceiling probe: twelve 1-wide rings split into quadrants over twelve colours, so each layer is a narrow frontier shared by four colours, behind a twelve-layer unlock chain with border-isolated split supply."},
	{"id": "x_rings12q_straddle_24", "lane": "EXTREME", "w": 24, "h": 24, "shape": "rings", "rw": 2, "ns": 4, "k": 12, "supply": "straddle30",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "mid", "S": "high"},
		"rationale": "Ceiling probe: six 2-wide quadrant rings over twelve colours with colour-first chunks that straddle layers, maximising slots held by batches with no reachable target behind a deep unlock chain."},
	{"id": "x_maze12_24", "lane": "EXTREME", "w": 24, "h": 24, "shape": "maze", "nc": 6, "k": 12, "supply": "color_first",
		"profile": {"W": "low", "C": "high", "A": "high", "U": "high", "B": "high", "R": "high", "S": "high"},
		"rationale": "Ceiling probe: single-entrance serpentine corridor in six path-ordered colours demanded before six wall colours: maximum route length/detour/turns, a two-cell frontier and forced single-column decisions."},
	{"id": "x_rings12q_r1_split_28", "lane": "EXTREME", "w": 28, "h": 28, "shape": "rings", "rw": 1, "ns": 4, "k": 12, "supply": "layer_split",
		"profile": {"W": "mid", "C": "high", "A": "high", "U": "high", "B": "high", "R": "high", "S": "high"},
		"rationale": "Ceiling probe: fourteen 1-wide quadrant rings over twelve colours on a 28 board, the deepest enclosure chain in the set with border-isolated split supply."},
]

func _initialize() -> void:
	quit(build())

static func fixture_level_path(id: String) -> String:
	return "%s/%s.level.json" % [FIXTURE_DIR, id]

static func fixture_supply_path(id: String) -> String:
	return "%s/%s.supply.json" % [FIXTURE_DIR, id]

static func spec_for(id: String) -> Dictionary:
	for f in FIXTURES:
		if f["id"] == id:
			return f
	return {}

## Colour index (0..k-1) at (x, y) for a declared shape.
static func color_index(spec: Dictionary, x: int, y: int) -> int:
	var w: int = spec["w"]
	var h: int = spec["h"]
	var k: int = spec["k"]
	var d: int = mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
	match String(spec["shape"]):
		"vstripes":
			return x * k / w
		"hbands":
			return y * k / h
		"tiles":
			var t: int = spec["tile"]
			return (x / t + int(spec["mul"]) * (y / t)) % k
		"frame":
			var t: int = spec["t"]
			if d < t:
				return 0
			return 1 + (x - t) * (k - 1) / (w - 2 * t)
		"shafts":
			var nb: int = spec["nb"]
			if x % 3 == 1:
				return nb + (x / 3) % (k - nb)
			return x * nb / w
		"rings":
			var ns: int = spec["ns"]
			var s := 0
			if ns == 2:
				s = 0 if x < w / 2 else 1
			elif ns == 4:
				s = (0 if x < w / 2 else 1) + (0 if y < h / 2 else 2)
			return (d / int(spec["rw"]) * ns + s) % k
		"maze":
			# Rows y odd are corridor, rows y even are walls with one gap (alternating ends);
			# border columns/top row are walls; the bottom row is wall except the entrance x == 1.
			var nc: int = spec["nc"]
			var nw: int = k - nc
			var rows: int = (h - 1) / 2
			var wall: int = nc + (y / 2) % nw
			if y == h - 1:
				return path_color(1, y, h, nc, rows) if x == 1 else wall
			if x == 0 or x == w - 1 or y == 0:
				return wall
			if y % 2 == 1:
				return path_color(x, y, h, nc, rows)
			var gap: int = 1 if (y / 2) % 2 == 1 else w - 2
			return path_color(x, y, h, nc, rows) if x == gap else wall
	return 0

## Corridor colour: corridor rows numbered from the bottom entrance, split into nc contiguous segments.
static func path_color(_x: int, y: int, h: int, nc: int, rows: int) -> int:
	var j: int = clampi((h - 1 - y) / 2, 0, rows - 1)
	return j * nc / rows

## Level + supply text for one fixture (pure; used by the build and the determinism test).
static func fixture_texts(spec: Dictionary, auth: Dictionary) -> Dictionary:
	var w: int = spec["w"]
	var h: int = spec["h"]
	var used := {}
	var grid: Array = []
	for y in range(h):
		for x in range(w):
			var cid: String = PALETTE[color_index(spec, x, y)]
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
	var level := {"version": 1, "id": "anchor_%s" % spec["id"], "name": "Anchor %s" % spec["id"],
		"difficulty": "TEST", "width": w, "height": h, "palette": palette, "cells": Array(cells)}
	var sspec: Dictionary = {"supply": spec["supply"]}
	if spec["supply"] == "color_first":
		# Corridor colours in path order, then wall colours (maze); otherwise colour index order.
		var order: Array = []
		for i in range(int(spec["k"])):
			order.append(PALETTE[i])
		sspec["order"] = order
	var cols: Array = Calib.build_supply(sspec, w, h, cells, cids)
	var plan_cols: Array = []
	var bi := 0
	for c in range(3):
		var q: Array = []
		for b in cols[c]:
			bi += 1
			q.append({"batchId": "%s-%03d" % [spec["id"], bi], "cid": b["cid"], "robots": b["robots"]})
		plan_cols.append(q)
	var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "qaOnly": true,
		"columnCount": 3, "visiblePreviewDepth": 3, "maxRobotsPerBatch": Calib.MAX_BATCH,
		"supplyStrategy": spec["supply"], "columns": plan_cols}
	return {"level": JSON.stringify(level) + "\n", "supply": JSON.stringify(plan, "\t") + "\n",
		"usedColors": cids, "batches": bi}

func build() -> int:
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
	var manifest_fx: Array = []
	var counts := {"EASY": 0, "MEDIUM": 0, "HARD": 0, "VERY_HARD": 0, "EXTREME": 0}
	var ok := true
	for spec in FIXTURES:
		var id: String = spec["id"]
		var t := fixture_texts(spec, auth)
		Calib._write(fixture_level_path(id), t["level"])
		Calib._write(fixture_supply_path(id), t["supply"])
		var lr = LevelLoader.load_from_path(fixture_level_path(id))
		if not lr.is_ok():
			printerr("LEVEL_INVALID %s %s" % [id, str(lr.errors)])
			ok = false
			continue
		var se: Dictionary = SupplyPlanLoader.load_engine(fixture_supply_path(id), lr.level_data)
		if not se["ok"]:
			printerr("SUPPLY_INVALID %s %s" % [id, se["error"]])
			ok = false
			continue
		var sol: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lr.level_data, se["engine"]))
		print("ANCHOR %s lane=%s colours=%d batches=%d solver=%s visited=%d" % [id, spec["lane"], (t["usedColors"] as Array).size(),
			t["batches"], sol["status"], int(sol["visited"])])
		if sol["status"] != SolvabilitySolver.SOLVED:
			ok = false
			continue
		counts[spec["lane"]] += 1
		var m: Dictionary = spec.duplicate(true)
		m["levelPath"] = fixture_level_path(id)
		m["supplyPath"] = fixture_supply_path(id)
		m["levelSha256"] = Pack.content_sha256(fixture_level_path(id))
		m["supplySha256"] = Pack.content_sha256(fixture_supply_path(id))
		m["usedColors"] = t["usedColors"]
		m["batches"] = t["batches"]
		m["solver"] = {"status": String(sol["status"]), "visited": int(sol["visited"])}
		manifest_fx.append(m)
	if not ok:
		printerr("ANCHORS_FAILED (every fixture must be legal and SOLVED)")
		return 1
	var manifest := {"schema": "scrubbots.m36.difficulty_anchor_corpus.v1", "version": 1, "qaOnly": true, "task": "SB-M36-013",
		"note": "QA-only lane anchor fixtures designed from the score component rules. Never production catalog or campaign content. Declared before any Challenge measurement.",
		"generatedBy": "res://tools/build_difficulty_anchors.gd", "laneCounts": counts, "fixtures": manifest_fx}
	Calib._write(MANIFEST_PATH, Canon.file_text(manifest))
	var per_lane_min: int = mini(mini(counts["EASY"], counts["MEDIUM"]), mini(counts["HARD"], counts["VERY_HARD"]))
	print("ANCHORS_BUILT lanes=4 perLaneMin>=%d extreme>=%d" % [per_lane_min, counts["EXTREME"]])
	return 0
