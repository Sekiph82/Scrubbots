extends RefCounted
## SupplyPlanLoader — preload (res://scripts/gameplay/supply/supply_plan_loader.gd).
##
## M52-C001: loads an owner-authored, declarative supply plan
## (`scrubbots.level_supply_plan.v1`, data/levels/supply/*.json) into a real M23
## BatchSupplyEngine through the accepted ColorBatch.make + load_candidate path.
## The plan's three FIFO columns are loaded COMPLETE — every hidden row is real queue
## state; `visiblePreviewDepth` only sets the player-facing preview rows.
##
## Plans name colors by canonical GLOBAL id (C01..C16). Gameplay batches use the
## level's LOCAL palette index, so each Cxx is resolved through the palette authority
## (data/palettes/scrubbots_palette_v3.json) to its hex and then to the single matching
## LevelData.palette entry. Never assumes Cxx == local index.
##
## Fail-closed on: unreadable/malformed JSON, wrong schema/version, level id mismatch,
## column/preview shape != 3/3, unknown/off-palette Cxx, Cxx absent from the level
## palette, duplicate level palette entries, empty/duplicate batch id, robot count
## outside 1..30 (or non-integer), per-color totals != LevelData cell totals, grand
## total != cell count, or engine rejection. No fallback candidate is ever produced.

const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")

const SCHEMA := "scrubbots.level_supply_plan.v1"
const COLUMN_COUNT := 3
const VISIBLE_PREVIEW_DEPTH := 3
const MAX_ROBOTS_PER_BATCH := 30

## Parse a plan file. Returns {ok, error, plan}.
static func load_plan(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": false, "error": "supply plan missing: %s" % path}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "supply plan malformed JSON: %s" % path}
	if parsed.get("schema", "") != SCHEMA or _as_int(parsed.get("version")) != 1:
		return {"ok": false, "error": "supply plan schema/version mismatch: %s" % path}
	return {"ok": true, "error": "", "plan": parsed}

## Global Cxx -> local palette index for `level`. Returns {ok, error, map}.
static func cid_to_local_map(level) -> Dictionary:
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	if auth == null:
		return {"ok": false, "error": "palette authority unavailable"}
	var hex_to_local := {}
	for i in level.palette.size():
		var hex := String(level.palette[i]).to_upper()
		if hex.length() == 7:
			hex += "FF"
		if hex_to_local.has(hex):
			return {"ok": false, "error": "level palette has duplicate color %s" % hex}
		hex_to_local[hex] = i
	var map := {}
	for cid in auth["cid_to_hex"]:
		var hex: String = auth["cid_to_hex"][cid]
		if hex_to_local.has(hex):
			map[cid] = hex_to_local[hex]
	return {"ok": true, "error": "", "map": map}

## Build a loaded engine from a parsed plan for `level`. Returns
## {ok, error, engine, cid_to_local, queue_lengths}.
static func build_engine(plan: Dictionary, level) -> Dictionary:
	var fail := func(msg: String) -> Dictionary: return {"ok": false, "error": msg}
	if level == null or String(plan.get("levelId", "")) != String(level.id):
		return fail.call("plan levelId '%s' != level '%s'" % [plan.get("levelId", ""), level.id if level != null else "null"])
	if _as_int(plan.get("columnCount")) != COLUMN_COUNT or _as_int(plan.get("visiblePreviewDepth")) != VISIBLE_PREVIEW_DEPTH:
		return fail.call("plan must declare %d columns / %d visible rows" % [COLUMN_COUNT, VISIBLE_PREVIEW_DEPTH])
	var mr := _as_int(plan.get("maxRobotsPerBatch"))
	if mr < 1 or mr > MAX_ROBOTS_PER_BATCH:
		return fail.call("maxRobotsPerBatch must be 1..%d" % MAX_ROBOTS_PER_BATCH)
	var m := cid_to_local_map(level)
	if not m["ok"]:
		return fail.call(m["error"])
	var cid_to_local: Dictionary = m["map"]
	var columns = plan.get("columns", null)
	if typeof(columns) != TYPE_ARRAY or columns.size() != COLUMN_COUNT:
		return fail.call("plan columns must be an array of %d FIFO queues" % COLUMN_COUNT)
	var palette_size: int = level.palette.size()
	var ids := {}
	var sums := {}
	var cols: Array = []
	var lengths: Array = []
	for col in columns:
		if typeof(col) != TYPE_ARRAY or col.is_empty():
			return fail.call("every column must be a non-empty array")
		var q: Array = []
		for b in col:
			if typeof(b) != TYPE_DICTIONARY:
				return fail.call("batch entry is not an object")
			var bid := String(b.get("batchId", ""))
			if bid.is_empty() or ids.has(bid):
				return fail.call("empty/duplicate batchId '%s'" % bid)
			ids[bid] = true
			var cid := String(b.get("cid", ""))
			if not cid_to_local.has(cid):
				return fail.call("%s: color %s is not a canonical color of this level's palette" % [bid, cid])
			var n := _as_int(b.get("robots"))
			if n < 1 or n > mr:
				return fail.call("%s: robots %s outside 1..%d" % [bid, str(b.get("robots")), mr])
			var local: int = cid_to_local[cid]
			var batch = ColorBatch.make(bid, local, n, palette_size)
			if batch == null:
				return fail.call("%s: ColorBatch rejected" % bid)
			q.append(batch)
			sums[local] = int(sums.get(local, 0)) + n
		cols.append(q)
		lengths.append(q.size())
	var totals := BatchSupplyGenerator.color_totals(level)
	if totals.is_empty() or sums != totals:
		return fail.call("per-color conservation failed: plan %s != level %s" % [str(sums), str(totals)])
	var grand := 0
	for c in sums:
		grand += int(sums[c])
	if grand != level.get_cell_count():
		return fail.call("grand total %d != cell count %d" % [grand, level.get_cell_count()])
	var engine = BatchSupplyEngine.create(COLUMN_COUNT, VISIBLE_PREVIEW_DEPTH)
	if engine == null or not engine.load_candidate(cols, 0, palette_size):
		return fail.call("BatchSupplyEngine rejected the plan layout")
	return {"ok": true, "error": "", "engine": engine, "cid_to_local": cid_to_local,
		"queue_lengths": lengths}

## load_plan + build_engine.
static func load_engine(path: String, level) -> Dictionary:
	var lp := load_plan(path)
	if not lp["ok"]:
		return lp
	var r := build_engine(lp["plan"], level)
	if r["ok"]:
		r["plan"] = lp["plan"]
	return r

## Exact integer from JSON (int, or finite integral float); -1 otherwise.
static func _as_int(v) -> int:
	if typeof(v) == TYPE_INT:
		return v
	if typeof(v) == TYPE_FLOAT and not is_nan(v) and not is_inf(v) and floor(v) == v:
		return int(v)
	return -1
