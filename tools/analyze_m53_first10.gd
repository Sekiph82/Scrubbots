extends SceneTree
## M53-C001 — First 10 real-level QA + Difficulty V1 evidence (offline tool).
##
## Stage 1 (measure, expensive; one process per level so levels run in parallel):
##   godot --headless --path . -s res://tools/analyze_m53_first10.gd -- --only=<level_id>
## replays the canonical reference path(s) through LevelDifficultyAnalyzerV1.measure and
## writes coordination/sessions/M53-C001/evidence/raw/<id>_raw_v1.json.
##
## Stage 2 (merge, cheap, deterministic from the committed raw files):
##   godot --headless --path . -s res://tools/analyze_m53_first10.gd
## runs every static M53 QA gate, scores each raw record with the versioned model,
## computes sensitivity / recovery / novelty and writes:
##   coordination/sessions/M53-C001/evidence/first10_level_qa_v1.json
##   coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json
##   coordination/sessions/M53-C001/FIRST10_M53_MATRIX_V01.md
##
## Read-only with respect to all content: LevelData, metadata, previews, source art,
## supply plans and the catalog are only read and hashed.

const Analyzer = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const EVIDENCE_DIR := "res://coordination/sessions/M53-C001/evidence"
const RAW_DIR := "res://coordination/sessions/M53-C001/evidence/raw"
const QA_PATH := "res://coordination/sessions/M53-C001/evidence/first10_level_qa_v1.json"
const DIFF_PATH := "res://coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json"
const MATRIX_PATH := "res://coordination/sessions/M53-C001/FIRST10_M53_MATRIX_V01.md"
const M52_PLAN_EVIDENCE := "res://coordination/sessions/M52-C001/evidence/owner_plans/%s_verification.json"
const M52_L1_EVIDENCE := "res://coordination/sessions/M52-C001/evidence/solve_m21_level_001_hazard_bot.json"
const RAW_SCHEMA := "scrubbots.m53.level_raw_measurement.v1"

## Owner-locked First 10 (OWNER_M52_C001_FIRST_10_LEVEL_PACK_DECISION_V01).
const LEVELS := [
	{"order": 1, "id": "m21_level_001_hazard_bot", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png"},
	{"order": 2, "id": "level_002_apple", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/level_002_apple_32x32.png"},
	{"order": 3, "id": "level_003_palm_tree", "class": "MEDIUM",
		"source": "res://assets/art/levels/source/medium/level_003_palm_tree_38x38.png"},
	{"order": 4, "id": "level_004_orange_cat", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/level_004_orange_cat_32x32.png"},
	{"order": 5, "id": "level_005_party_toucan", "class": "HARD",
		"source": "res://assets/art/levels/source/hard/level_005_party_toucan_33x33.png"},
	{"order": 6, "id": "level_006_chicken", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/level_006_chicken_32x32.png"},
	{"order": 7, "id": "level_007_pigeon", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/level_007_pigeon_32x32.png"},
	{"order": 8, "id": "level_008_butterfly", "class": "MEDIUM",
		"source": "res://assets/art/levels/source/medium/level_008_butterfly_32x32.png"},
	{"order": 9, "id": "level_009_frog", "class": "EASY",
		"source": "res://assets/art/levels/source/easy/level_009_frog_32x32.png"},
	{"order": 10, "id": "level_010_ice_cube", "class": "VERY_HARD",
		"source": "res://assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png"},
]

func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--only="):
			only = String(a).substr("--only=".length())
	if not only.is_empty():
		quit(measure_one(only))
	else:
		quit(merge())

static func raw_path(id: String) -> String:
	return "%s/%s_raw_v1.json" % [RAW_DIR, id]

static func spec_for(id: String) -> Dictionary:
	for s in LEVELS:
		if s["id"] == id:
			return s
	return {}

static func load_level(id: String):
	return LevelLoader.load_from_path(Pack.level_path(id)).level_data

## Canonical reference inputs for a level: the runtime supply engine, the canonical
## SolvabilitySolver trace (hash-verified against the M52 accepted evidence) and, where an
## owner plan exists, the owner intended click path. Returns {ok, error, ...}.
static func reference_inputs(id: String, lvl) -> Dictionary:
	if id == "m21_level_001_hazard_bot":
		var ev: Dictionary = Analyzer._read_json(M52_L1_EVIDENCE)
		var eng = BatchSupplyGenerator.generate(lvl, 3, 3, 1)
		var res: Dictionary = SolvabilitySolver.new().solve(ProofState.from_level_and_supply(lvl, eng))
		if res["status"] != SolvabilitySolver.SOLVED or int(res["trace_hash"]) != int(ev["solve"]["traceHash"]):
			return {"ok": false, "error": "Level 1 solver trace does not reproduce the M52 hash"}
		return {"ok": true, "supplyAuthority": "BatchSupplyGenerator seed 1 / 3 columns / 3 visible rows (historical Level 1 path)",
			"make_engine": func(): return BatchSupplyGenerator.generate(lvl, 3, 3, 1),
			"trace": res["trace"], "traceHash": int(res["trace_hash"]),
			"traceSource": "SolvabilitySolver.solve re-run (visited %d); hash == M52 evidence" % int(res["visited"]),
			"ownerClicks": []}
	var ev2: Dictionary = Analyzer._read_json(M52_PLAN_EVIDENCE % id)
	var plan_path: String = "res://data/levels/supply/%s_supply_v1.json" % id
	if ev2.get("planSha256", "") != Pack.content_sha256(plan_path) or ev2.get("levelSha256", "") != Pack.content_sha256(Pack.level_path(id)):
		return {"ok": false, "error": "M52 evidence no longer bound to current plan/LevelData bytes"}
	var trace: Array = ev2["solver"]["trace"]
	if SolvabilitySolver._trace_hash(trace) != int(ev2["solver"]["traceHash"]):
		return {"ok": false, "error": "recorded solver trace hash mismatch"}
	var clicks: Array = []
	for c in SupplyPlanLoader.load_plan(plan_path)["plan"]["intendedColumnClicks"]:
		clicks.append(int(c) - 1)
	return {"ok": true, "supplyAuthority": "SupplyPlanLoader %s" % plan_path,
		"make_engine": func(): return SupplyPlanLoader.load_engine(plan_path, lvl)["engine"],
		"trace": trace, "traceHash": int(ev2["solver"]["traceHash"]),
		"traceSource": "M52 owner-plan verification evidence (hash-verified; replayed step-exact here)",
		"ownerClicks": clicks}

# ============================================================================ measure ==

func measure_one(id: String) -> int:
	var spec := spec_for(id)
	if spec.is_empty():
		printerr("UNKNOWN_LEVEL %s" % id)
		return 1
	var analyzer = Analyzer.new()
	if not analyzer.is_ok():
		printerr("ANALYZER_FAIL %s" % analyzer.get_error())
		return 1
	var lvl = load_level(id)
	var ref := reference_inputs(id, lvl)
	if not ref["ok"]:
		printerr("REFERENCE_FAIL %s: %s" % [id, ref["error"]])
		return 1
	var cols: Array = []
	for t in ref["trace"]:
		cols.append(int(t["column"]))
	var primary: Dictionary = analyzer.measure(lvl, ref["make_engine"].call(), cols, ref["trace"])
	if not primary["ok"]:
		printerr("MEASURE_FAIL %s: %s" % [id, primary["error"]])
		return 1
	var out := {"schema": RAW_SCHEMA, "version": 1, "levelId": id, "order": spec["order"],
		"levelSha256": Pack.content_sha256(Pack.level_path(id)),
		"provenance": analyzer.provenance(), "supplyAuthority": ref["supplyAuthority"],
		"referencePath": {"policy": "ORACLE_SOLVER_TRACE", "traceHash": ref["traceHash"],
			"traceSource": ref["traceSource"], "columns": cols, "raw": primary}}
	if not (ref["ownerClicks"] as Array).is_empty():
		var owner: Dictionary = analyzer.measure(lvl, ref["make_engine"].call(), ref["ownerClicks"])
		if not owner["ok"]:
			printerr("OWNER_PATH_FAIL %s: %s" % [id, owner["error"]])
			return 1
		out["ownerPath"] = {"policy": "OWNER_INTENDED_CLICKS", "columns": ref["ownerClicks"], "raw": owner}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RAW_DIR))
	var ok := _write(raw_path(id), JSON.stringify(out, "\t", false) + "\n")
	print("MEASURED %s D-inputs ok; primary %d ms%s" % [id, int(primary["timing"]["totalMs"]),
		"" if ok else " (WRITE FAILED)"])
	return 0 if ok else 1

# ============================================================================== merge ==

func merge() -> int:
	var analyzer = Analyzer.new()
	var prog = DifficultyProgressionV1.new()
	if not analyzer.is_ok() or not prog.is_ok():
		printerr("MODEL_LOAD_FAIL")
		return 1
	var cat = LevelCatalog.new()
	var cat_ok: bool = cat.load_manifest().ok
	var entries: Array = cat.get_entries_ordered() if cat_ok else []
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	var qa_levels: Array = []
	var diff_levels: Array = []
	var missing: Array = []
	var seen_ids := {}
	for spec in LEVELS:
		var id: String = spec["id"]
		var n: int = spec["order"]
		if not FileAccess.file_exists(raw_path(id)):
			missing.append(id)
			continue
		var raw: Dictionary = Analyzer._read_json(raw_path(id))
		var lvl = load_level(id)
		var entry = entries[n - 1] if entries.size() >= n else null
		var gates := static_gates(spec, lvl, entry, auth, raw, prog, seen_ids)
		var all_pass := true
		for g in gates:
			all_pass = all_pass and bool(g["pass"])
		var primary: Dictionary = analyzer.score(raw["referencePath"]["raw"], n)
		var rec := {"order": n, "id": id, "class": prog.class_for(n), "slot": prog.slot_for(n),
			"role": prog.role_for(n), "noveltyTarget": prog.novelty_target_for(n),
			"width": lvl.width, "height": lvl.height, "palette": _cids(lvl, auth),
			"levelSha256": raw["levelSha256"], "provenance": raw["provenance"],
			"supplyAuthority": raw["supplyAuthority"],
			"referencePath": {"policy": raw["referencePath"]["policy"], "traceHash": raw["referencePath"]["traceHash"],
				"traceSource": raw["referencePath"]["traceSource"], "decisions": (raw["referencePath"]["columns"] as Array).size(),
				"path": raw["referencePath"]["raw"]["path"]},
			"vector": primary["vector"], "challengeScore": primary["challengeScore"],
			"targetChallenge": primary["targetChallenge"], "signedDelta": primary["signedDelta"],
			"absoluteDelta": primary["absoluteDelta"], "acceptanceWindow": primary["acceptanceWindow"],
			"supporting": primary["supporting"], "sessionLoad": primary["sessionLoad"],
			"frustrationRisk": primary["frustrationRisk"], "profile": primary["profile"],
			"noveltySignatureInputs": {"colorLayers": raw["referencePath"]["raw"]["colorLayers"],
				"peelHistogram": raw["referencePath"]["raw"]["peel"]["histogram"],
				"routeMeanLength": raw["referencePath"]["raw"]["routes"]["meanLength"],
				"aspectRatio": float(lvl.width) / float(lvl.height),
				"artCategory": "NOT_DEFINED (no canonical art taxonomy exists)",
				"sourceFamily": "owner_original_art"},
			"sensitivity": sensitivity(analyzer, raw["referencePath"]["raw"], n)}
		if raw.has("ownerPath"):
			var os: Dictionary = analyzer.score(raw["ownerPath"]["raw"], n)
			rec["ownerPathSensitivity"] = {"policy": "OWNER_INTENDED_CLICKS", "vector": os["vector"],
				"challengeScore": os["challengeScore"], "signedDelta": os["signedDelta"],
				"acceptanceWindow": os["acceptanceWindow"], "sessionLoad": os["sessionLoad"]["value"],
				"decisions": (raw["ownerPath"]["columns"] as Array).size(),
				"path": raw["ownerPath"]["raw"]["path"]}
		else:
			rec["ownerPathSensitivity"] = {"policy": "NONE", "note": "Level 1 has no owner supply plan (historical generator path)"}
		var fit_ok: bool = primary["acceptanceWindow"] == Analyzer.WINDOW_IN
		rec["staticQa"] = "PASS" if all_pass else "FAIL"
		rec["m53Verdict"] = "QA_FAIL" if not all_pass else ("PASS" if fit_ok else "TUNING_REQUIRED")
		diff_levels.append(rec)
		qa_levels.append({"order": n, "id": id, "gates": gates, "staticQa": rec["staticQa"],
			"timing": raw["referencePath"]["raw"]["timing"]})
	if not missing.is_empty():
		printerr("RAW_MISSING %s" % str(missing))
		return 1
	_novelty(diff_levels)
	var recovery := recovery_checks(diff_levels, prog)
	for r in recovery["guards"]:
		if not bool(r["pass"]):
			for rec in diff_levels:
				if int(rec["order"]) == int(r["toLevel"]) and rec["m53Verdict"] == "PASS":
					rec["m53Verdict"] = "TUNING_REQUIRED"
	var tuning: Array = []
	var qa_fail: Array = []
	for rec in diff_levels:
		if rec["m53Verdict"] == "TUNING_REQUIRED":
			tuning.append(rec["id"])
		elif rec["m53Verdict"] == "QA_FAIL":
			qa_fail.append(rec["id"])
	var summary := {"levels": diff_levels.size(), "staticQaPass": diff_levels.size() - qa_fail.size(),
		"inDefaultWindow": diff_levels.size() - _count_window(diff_levels, false),
		"tuningRequired": tuning, "qaFail": qa_fail,
		"overall": "PASS" if tuning.is_empty() and qa_fail.is_empty() else ("QA_FAIL" if not qa_fail.is_empty() else "TUNING_REQUIRED")}
	var diff := {"schema": "scrubbots.m53.first10_difficulty.v1", "version": 1, "sprint": "M53-C001",
		"provenance": analyzer.provenance(), "analysisConfig": analyzer.config(),
		"summary": summary, "recovery": recovery, "levels": diff_levels}
	var qa := {"schema": "scrubbots.m53.first10_level_qa.v1", "version": 1, "sprint": "M53-C001",
		"catalogValid": cat_ok, "levels": qa_levels,
		"protectedBehaviorSuites": ["tests/m52_owner_supply_plans.gd", "tests/m52_r01_parallel_runtime.gd",
			"tests/m52_r02_early_slot_release.gd"],
		"note": "Runtime WON 9/9 (Levels 2-10), frontier 11 CONTENT_MISSING, R01/R02 behavior and runtime performance are proven by the protected suites above (re-run for M53; see CLAUDE_LOG_V01.md)."}
	var ok := _write(DIFF_PATH, JSON.stringify(diff, "\t", false) + "\n")
	ok = _write(QA_PATH, JSON.stringify(qa, "\t", false) + "\n") and ok
	ok = _write(MATRIX_PATH, matrix_md(diff_levels, qa_levels, recovery, summary)) and ok
	print("M53_MERGE %s overall=%s tuning=%s qaFail=%s" % ["OK" if ok else "WRITE_FAIL", summary["overall"],
		str(tuning), str(qa_fail)])
	return 0 if ok else 1

static func _count_window(levels: Array, in_window: bool) -> int:
	var n := 0
	for r in levels:
		if (r["acceptanceWindow"] == Analyzer.WINDOW_IN) == in_window:
			n += 1
	return n

static func _cids(lvl, auth) -> Array:
	var hex_to_cid := {}
	for cid in auth["cid_to_hex"]:
		hex_to_cid[auth["cid_to_hex"][cid]] = cid
	var out: Array = []
	for hx in lvl.palette:
		out.append(hex_to_cid.get(_hex8(hx), "INVALID"))
	return out

static func _hex8(hx: String) -> String:
	var h := hx.to_upper()
	return h + "FF" if h.length() == 7 else h

# ===================================================================== static QA ==

static func static_gates(spec: Dictionary, lvl, entry, auth, raw: Dictionary, prog, seen_ids: Dictionary) -> Array:
	var g: Array = []
	var id: String = spec["id"]
	var n: int = spec["order"]
	var add := func(name: String, ok: bool, ev) -> void: g.append({"gate": name, "pass": ok, "evidence": ev})
	var meta: Dictionary = Analyzer._read_json(Pack.metadata_path(id))
	# Dimensions / envelope.
	add.call("legal_dimensions_envelope", lvl.width >= 20 and lvl.width <= 59 and lvl.height >= 20 and lvl.height <= 59,
		"%dx%d within 20..59" % [lvl.width, lvl.height])
	# Class token.
	add.call("owner_locked_class_token", lvl.difficulty == spec["class"] and prog.class_for(n) == spec["class"]
		and meta.get("difficulty", "") == spec["class"] and entry != null and entry.difficulty == spec["class"],
		"LevelData/metadata/catalog/cadence all %s" % spec["class"])
	# Canonical palette, ascending C-ID, no duplicates.
	var cids := _cids(lvl, auth)
	var ascending := true
	for i in range(1, cids.size()):
		ascending = ascending and String(cids[i - 1]) < String(cids[i])
	add.call("canonical_palette_c01_c16", not cids.has("INVALID") and ascending, "palette %s" % str(cids))
	# Used colors == palette, 3..12.
	var used := {}
	var bad_ids := 0
	for c in lvl.cells:
		if c < 0 or c >= lvl.palette.size():
			bad_ids += 1
		else:
			used[c] = true
	add.call("used_color_count_3_12", used.size() == lvl.palette.size() and used.size() >= 3 and used.size() <= 12,
		"%d used of %d palette entries" % [used.size(), lvl.palette.size()])
	add.call("exact_cell_count", lvl.cells.size() == lvl.width * lvl.height and lvl.get_cell_count() == lvl.width * lvl.height
		and int(meta.get("cellCount", -1)) == lvl.width * lvl.height, "%d cells" % lvl.cells.size())
	add.call("no_invalid_palette_ids", bad_ids == 0, "%d invalid cell palette ids" % bad_ids)
	# Source reconstruction / interpolation.
	var src := Image.new()
	var src_ok := src.load(spec["source"]) == OK
	var alpha_ok := src_ok
	if src_ok:
		src.convert(Image.FORMAT_RGBA8)
		var data := src.get_data()
		for i in range(3, data.size(), 4):
			if data[i] != 255:
				alpha_ok = false
				break
	add.call("source_reconstruction_exact", Pack.reconstruction_equal(spec["source"], lvl),
		"LevelImporter.reconstruct_image(LevelData) == source RGBA8 bytes")
	add.call("no_unintended_interpolation", src_ok and alpha_ok and src.get_width() == lvl.width and src.get_height() == lvl.height,
		"source %dx%d == board, all alpha 255, 1 source pixel = 1 cell; exact byte equality above excludes resampling" % [src.get_width() if src_ok else -1, src.get_height() if src_ok else -1])
	add.call("cleared_transparency_render", _render_check(lvl), "BoardRenderer: every ACTIVE pixel == palette opaque; CLEARED cells alpha 0; NEAREST filter")
	# Solvability / routing.
	var path: Dictionary = raw["referencePath"]["raw"]["path"]
	var owner_ok := true
	if raw.has("ownerPath"):
		owner_ok = bool(raw["ownerPath"]["raw"]["path"]["solved"])
	add.call("canonical_solvability", bool(path["solved"]) and int(path["finalActive"]) == 0 and owner_ok,
		"reference trace %d replayed step-exact to SOLVED (hash %d)%s" % [int(path["steps"]), int(raw["referencePath"]["traceHash"]),
		"; owner intended path SOLVED" if raw.has("ownerPath") else ""])
	var peel: Dictionary = raw["referencePath"]["raw"]["peel"]
	add.call("routing_access_sanity", int(peel["unreachableCells"]) == 0 and int(path["routeFailures"]) == 0
		and int(path["productivityMismatches"]) == 0 and int(path["totalClears"]) == lvl.get_cell_count(),
		{"unreachableCellsInPeel": peel["unreachableCells"], "routeValidatorFailures": path["routeFailures"],
			"analyzerVsKernelProductivityMismatches": path["productivityMismatches"],
			"claimsWithValidatedRoutes": path["totalClears"], "peelGeometricMismatchCells": peel["geometricMismatchCells"]})
	var tm: Dictionary = raw["referencePath"]["raw"]["timing"]
	add.call("performance_sanity", int(tm["kernelPlacementMaxMs"]) < 30000 and int(tm["routeComputeMaxMs"]) < 1000,
		{"headlessKernelPlacementMeanMs": tm["kernelPlacementMeanMs"], "headlessKernelPlacementMaxMs": tm["kernelPlacementMaxMs"],
			"headlessRouteComputeMaxMs": tm["routeComputeMaxMs"], "headlessRouteComputeMeanMs": tm["routeComputeMeanMs"],
			"bounds": "offline sanity bounds: placement < 30000 ms, single route < 1000 ms; runtime frame performance is proven by m52_r01_parallel_runtime"})
	# Preview.
	add.call("preview_exact", Pack.reconstruction_equal(Pack.preview_path(id), lvl) and entry != null
		and entry.preview_path == Pack.preview_path(id) and meta.get("previewPath", "") == Pack.preview_path(id),
		"preview %s == LevelData reconstruction; catalog/metadata point to it" % Pack.preview_path(id))
	# ID / catalog.
	var unique: bool = not seen_ids.has(id)
	seen_ids[id] = true
	add.call("unique_stable_id", unique and lvl.id == id, "LevelData.id %s" % lvl.id)
	add.call("catalog_order", entry != null and entry.id == id and entry.order == n and entry.level_path == Pack.level_path(id),
		"catalog order %d -> %s" % [n, entry.id if entry != null else "MISSING"])
	# Provenance.
	var counts := {}
	for c in lvl.cells:
		counts[cids[c]] = int(counts.get(cids[c], 0)) + 1
	var m52_level_sha := ""
	if n == 1:
		m52_level_sha = String(Analyzer._read_json(M52_L1_EVIDENCE).get("levelSha256", ""))
	else:
		m52_level_sha = String(Analyzer._read_json(M52_PLAN_EVIDENCE % id).get("levelSha256", ""))
	var meta_counts := {}
	for k in meta.get("cellReferenceCounts", {}):
		meta_counts[k] = int(meta["cellReferenceCounts"][k])
	var prov := {"sourcePathMatchesOwnerLock": meta.get("sourcePath", "") == spec["source"],
		"sourceSha256Matches": meta.get("sourceSha256", "") == ProductionArtLevelBuilder._sha256_file(spec["source"]),
		"sourceGitBlobSha1Matches": meta.get("sourceGitBlobSha1", "") == ProductionArtLevelBuilder._git_blob_sha1_file(spec["source"]),
		"cellReferenceCountsMatch": JSON.stringify(meta_counts, "", true) == JSON.stringify(counts, "", true),
		"rawBoundToCurrentLevelData": raw["levelSha256"] == Pack.content_sha256(Pack.level_path(id)),
		"levelSha256BoundToM52Acceptance": raw["levelSha256"] == m52_level_sha}
	var prov_ok := true
	for k in prov:
		prov_ok = prov_ok and bool(prov[k])
	prov["sourcePath"] = spec["source"]
	prov["sourceSha256"] = meta.get("sourceSha256", "")
	prov["levelSha256"] = raw["levelSha256"]
	add.call("source_metadata_provenance", prov_ok, prov)
	if n == 1:
		add.call("level1_historical_generator_path", entry != null and entry.supply_plan_path == ""
			and not raw.has("ownerPath") and String(raw["supplyAuthority"]).begins_with("BatchSupplyGenerator seed 1"),
			"catalog order 1 has no supply plan; reference supply = M23 generator seed 1; solver trace hash == M52")
	else:
		var plan_path: String = "res://data/levels/supply/%s_supply_v1.json" % id
		var plan: Dictionary = SupplyPlanLoader.load_plan(plan_path).get("plan", {})
		var ev: Dictionary = Analyzer._read_json(M52_PLAN_EVIDENCE % id)
		var md := FileAccess.get_file_as_string("res://" + String(plan.get("ownerInput", ""))).replace("\r\n", "\n")
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(md.to_utf8_buffer())
		add.call("owner_supply_plan_provenance", entry != null and entry.supply_plan_path == plan_path
			and plan.get("levelId", "") == id and ctx.finish().hex_encode() == plan.get("ownerInputSha256", "")
			and Pack.content_sha256(plan_path) == ev.get("planSha256", ""),
			{"planPath": plan_path, "planSha256": Pack.content_sha256(plan_path), "boundToM52Evidence": Pack.content_sha256(plan_path) == ev.get("planSha256", ""),
				"ownerInput": plan.get("ownerInput", "")})
	return g

## Headless BoardRenderer check: ACTIVE -> exact opaque palette color; CLEARED -> alpha 0;
## nearest-neighbour filtering (no interpolation between logical cells).
static func _render_check(lvl) -> bool:
	var board = BoardState.from_level_data(lvl)
	var r = BoardRenderer.new()
	r.configure(board, lvl.palette, Vector2(lvl.width * 8, lvl.height * 8))
	var ok: bool = r.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	var cleared: Array = []
	for i in range(0, board.get_cell_count(), 7):
		board.set_cell_state(i, BoardState.CellState.CLEARED)
		cleared.append(i)
	r.update_cells(cleared)
	var pal: Array = []
	for hx in lvl.palette:
		pal.append(Color.html(hx))
	for i in range(board.get_cell_count()):
		var p: Vector2i = board.get_cell_position(i)
		var c: Color = r.get_pixel_color(p.x, p.y)
		if i % 7 == 0:
			ok = ok and c.a8 == 0
		else:
			var e: Color = pal[lvl.cells[i]]
			ok = ok and c.a8 == 255 and c.r8 == e.r8 and c.g8 == e.g8 and c.b8 == e.b8
	r.free()
	return ok

# ====================================================== sensitivity / recovery / novelty ==

static func sensitivity(analyzer, raw: Dictionary, n: int) -> Dictionary:
	var base: Dictionary = analyzer.default_anchors()
	var factors: Array = analyzer.config()["sensitivity"]["factors"]
	var rows: Array = []
	var dmin := 1000.0
	var dmax := -1000.0
	var smin := 1000.0
	var smax := -1000.0
	var windows := {}
	for k in base:
		for f in factors:
			var s: Dictionary = analyzer.score(raw, n, {k: float(base[k]) * float(f)})
			rows.append({"anchor": k, "factor": f, "value": float(base[k]) * float(f),
				"challengeScore": s["challengeScore"], "sessionLoad": s["sessionLoad"]["value"],
				"acceptanceWindow": s["acceptanceWindow"]})
			dmin = minf(dmin, s["challengeScore"])
			dmax = maxf(dmax, s["challengeScore"])
			smin = minf(smin, s["sessionLoad"]["value"])
			smax = maxf(smax, s["sessionLoad"]["value"])
			windows[s["acceptanceWindow"]] = true
	return {"challengeRange": [dmin, dmax], "sessionLoadRange": [smin, smax],
		"windowsReached": windows.keys(), "variants": rows}

static func recovery_checks(levels: Array, prog) -> Dictionary:
	var d := {}
	var sl := {}
	for r in levels:
		d[int(r["order"])] = float(r["challengeScore"])
		sl[int(r["order"])] = float(r["sessionLoad"]["value"])
	var guards: Array = []
	for g in prog.recovery_guards():
		if not g.has("toSlot"):
			continue
		var a: int = int(g["fromSlot"])
		var b: int = int(g["toSlot"])
		var drop: float = d[a] - d[b]
		guards.append({"fromLevel": a, "toLevel": b, "actualFrom": d[a], "actualTo": d[b], "actualDrop": drop,
			"designMinimumDrop": float(g["minimumChallengeDrop"]), "targetDrop": prog.target_challenge_for(a) - prog.target_challenge_for(b),
			"lowerThanPeak": drop > 0.0, "pass": drop >= float(g["minimumChallengeDrop"]),
			"sessionLoadDrop": sl[a] - sl[b]})
	var boss := 10
	var boss_max := true
	for k in d:
		if k != 10 and d[k] >= d[10]:
			boss_max = false
	var ranked: Array = d.keys()
	ranked.sort_custom(func(x, y): return d[x] > d[y])
	return {"guards": guards, "boss": {"level": boss, "actualD": d[boss], "isCycleMaximum": boss_max,
			"rankByActualD": ranked.find(boss) + 1, "actualOrderDescending": ranked},
		"note": "Computed from ACTUAL analyzed D, never target D. The 10 -> next-cycle-1 guard needs Level 11 (CONTENT_MISSING) and is not evaluated."}

static func _novelty(levels: Array) -> void:
	for i in range(levels.size()):
		var best := -1.0
		var best_id := ""
		var best_parts := {}
		for j in range(i):
			var s: Dictionary = Analyzer.similarity(levels[i], levels[j])
			if s["combined"] > best:
				best = s["combined"]
				best_id = levels[j]["id"]
				best_parts = s
		var r: Dictionary = levels[i]
		r["novelty"] = {"nearestPriorLevel": best_id if i > 0 else "NONE (first level)",
			"nearestPriorSimilarity": best_parts if i > 0 else {},
			"novelty": 1.0 - best if i > 0 else 1.0,
			"noveltyTarget": r["noveltyTarget"],
			"meetsNoveltyTarget": (1.0 - best if i > 0 else 1.0) >= float(r["noveltyTarget"]),
			"status": "INFORMATIONAL_STAGE_A (provisional similarity; no art taxonomy)"}

# ============================================================================= matrix ==

static func _f(v, d: int = 1) -> String:
	return ("%." + str(d) + "f") % float(v)

func matrix_md(levels: Array, qa: Array, recovery: Dictionary, summary: Dictionary) -> String:
	var L: PackedStringArray = PackedStringArray()
	L.append("# M53-C001 — FIRST 10 M53 MATRIX V01")
	L.append("")
	L.append("Status: GENERATED EVIDENCE (tools/analyze_m53_first10.gd merge) — awaiting ChatGPT audit")
	L.append("Analyzer: `scripts/difficulty/level_difficulty_analyzer_v1.gd` (m53-level-difficulty-analyzer/v1), score model v1, progression model v1, analysis config v1 (STAGE_A_PROVISIONAL anchors).")
	L.append("Reference path: canonical SolvabilitySolver trace replayed step-exact through ProofKernel; owner intended click path shown as sensitivity.")
	L.append("")
	L.append("Overall: **%s** — in default ±3.5 window: %d/10; static QA PASS: %d/10; TUNING_REQUIRED: %s" % [summary["overall"],
		int(summary["inDefaultWindow"]), int(summary["staticQaPass"]), ", ".join(PackedStringArray(summary["tuningRequired"])) if not (summary["tuningRequired"] as Array).is_empty() else "none"])
	L.append("")
	L.append("| Level | ID | Class | Target D | Actual D | Delta | W | C | A | U | B | R | S | Session Load | Frustration | Solver | Runtime provenance | M53 QA verdict |")
	L.append("|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|")
	for r in levels:
		var v: Dictionary = r["vector"]
		L.append("| %d | `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | **%s** |" % [
			r["order"], r["id"], r["class"], _f(r["targetChallenge"]), _f(r["challengeScore"], 2), ("%+.2f" % float(r["signedDelta"])),
			_f(v["W"], 3), _f(v["C"], 3), _f(v["A"], 3), _f(v["U"], 3), _f(v["B"], 3), _f(v["R"], 3), _f(v["S"], 3),
			_f(r["sessionLoad"]["value"], 1), "PROVISIONAL_STAGE_A (no scalar)",
			"SOLVED, %d steps, trace %d" % [int(r["referencePath"]["decisions"]), int(r["referencePath"]["traceHash"])],
			"generator seed 1 (L1 historical)" if int(r["order"]) == 1 else "owner plan v1",
			"%s (static %s, %s)" % [r["m53Verdict"], r["staticQa"], r["acceptanceWindow"]]])
	L.append("")
	L.append("## Sensitivity")
	L.append("")
	L.append("| Level | D (solver path) | D (owner click path) | D range over provisional anchors ×0.5/×2 | Session Load range | Est. attempt s (proxy) | Profile | Nearest prior (combined sim) |")
	L.append("|---:|---:|---:|---|---|---:|---|---|")
	for r in levels:
		var sen: Dictionary = r["sensitivity"]
		var od = r["ownerPathSensitivity"].get("challengeScore", null)
		L.append("| %d | %s | %s | %s–%s | %s–%s | %s | %s | %s |" % [r["order"], _f(r["challengeScore"], 2),
			"n/a" if od == null else _f(od, 2), _f(sen["challengeRange"][0], 2), _f(sen["challengeRange"][1], 2),
			_f(sen["sessionLoadRange"][0]), _f(sen["sessionLoadRange"][1]), _f(r["sessionLoad"]["estimatedAttemptSecondsProxy"], 0),
			r["profile"]["dominant"], "%s (%s)" % [r["novelty"]["nearestPriorLevel"], _f(r["novelty"]["nearestPriorSimilarity"].get("combined", 0.0), 3)] if int(r["order"]) > 1 else "—"])
	L.append("")
	L.append("## Recovery cadence (actual D)")
	L.append("")
	L.append("| From → To | Actual D from → to | Actual drop | Design min drop | Target drop | Lower than peak | Guard |")
	L.append("|---|---|---:|---:|---:|---|---|")
	for g in recovery["guards"]:
		L.append("| L%d → L%d | %s → %s | %s | %s | %s | %s | %s |" % [g["fromLevel"], g["toLevel"], _f(g["actualFrom"], 2), _f(g["actualTo"], 2),
			_f(g["actualDrop"], 2), _f(g["designMinimumDrop"]), _f(g["targetDrop"]), "yes" if g["lowerThanPeak"] else "NO (inverted)",
			"PASS" if g["pass"] else "FAIL"])
	var b: Dictionary = recovery["boss"]
	L.append("")
	L.append("L10 boss: actual D %s, rank %d of 10 by actual D, cycle maximum: %s." % [_f(b["actualD"], 2), int(b["rankByActualD"]), "yes" if b["isCycleMaximum"] else "NO"])
	L.append("")
	L.append("## Static QA gates")
	L.append("")
	var names: Array = []
	for g in qa[0]["gates"]:
		names.append(g["gate"])
	for g in qa[1]["gates"]:
		if not names.has(g["gate"]):
			names.append(g["gate"])
	var head := "| Gate |"
	var sep := "|---|"
	for q in qa:
		head += " L%d |" % int(q["order"])
		sep += "---|"
	L.append(head)
	L.append(sep)
	for nm in names:
		var row := "| %s |" % nm
		for q in qa:
			var cell := " n/a |"
			for g in q["gates"]:
				if g["gate"] == nm:
					cell = " %s |" % ("PASS" if g["pass"] else "**FAIL**")
			row += cell
		L.append(row)
	L.append("")
	L.append("Frustration Risk: PROVISIONAL_STAGE_A for every level — only the choice-opacity proxy is supported; retry risk (simulated human clear rate), session overrun (no owner slot budget) and late failure (no failing-simulation population) are UNSUPPORTED, so no scalar is claimed. Solver success is not a human first-attempt clear probability.")
	L.append("")
	L.append("Machine-readable authority: `evidence/first10_difficulty_v1.json`, `evidence/first10_level_qa_v1.json`, raw replay measurements `evidence/raw/<id>_raw_v1.json`.")
	return "\n".join(L) + "\n"

static func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("WRITE_FAIL %s" % path)
		return false
	f.store_string(text)
	f.close()
	return true
