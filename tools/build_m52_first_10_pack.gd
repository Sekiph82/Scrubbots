extends SceneTree
## M52-C001 First 10 Level Pack — reproducible headless build + authoritative solve.
##
## For each owner-locked Level 2..10 source this tool:
##   1. builds LevelData/preview/metadata through the canonical
##      ProductionArtLevelBuilder (exact pixels, ascending canonical C-ID palette);
##   2. proves the built level SOLVED with the canonical GenerationGate /
##      SolvabilitySolver at the runtime supply configuration
##      (ProductionGameplayHost: gen_seed 1, 3 FIFO columns, 3 VISIBLE rows —
##      preview_depth is presentation depth only; total FIFO depth is uncapped and
##      the solver reasons over every hidden batch);
##   3. replays the emitted trace against a fresh runtime-identical supply and
##      requires exact completion;
##   4. writes the machine-readable pack evidence sidecar.
##
## Level 1 (Hazard Bot) is only hashed/solved for evidence — never rebuilt.
## The production catalog is NOT written by this tool.
##
## Usage:
##   godot --headless --path . -s res://tools/build_m52_first_10_pack.gd [-- --overwrite] [--only=<id>]
##
## --only=<id> builds/solves one level and refreshes its solve cache (no evidence
## write) so levels can be proven in parallel processes. A cached solve is reused
## only for byte-identical LevelData and an identical solver configuration.
##
## Deterministic: identical sources reproduce byte-identical outputs and report
## UNCHANGED. Exits 1 on any source/build/solver/replay failure.

const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const GenerationGate = preload("res://scripts/gameplay/solver/generation_gate.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const EVIDENCE_PATH := "res://data/levels/catalog/first_10_pack_evidence_v1.json"
const EVIDENCE_SCHEMA := "scrubbots.first_10_pack_evidence.v1"
const SOLVE_CACHE_DIR := "user://m52_first_10_solve_cache"

## Runtime supply authority: ProductionGameplayHost (gen_seed=1, column_count=3,
## preview_depth=3). GenerationGate retries deterministic attempt seeds
## derive_seed(1, attempt) up to MAX_ATTEMPTS as bounded diagnostic evidence, but a
## level PASSES only when the accepted seed is the one the runtime actually plays
## (1): no runtime plumbing exists to deliver any other proven candidate.
const BASE_SEED := 1
const COLUMN_COUNT := 3
const PREVIEW_DEPTH := 3
const MAX_ATTEMPTS := 64
const SLOT_CAPACITY := 5
## SolvabilitySolver defaults (unchanged; recorded for provenance).
const SOLVER_CONFIG := {"max_visited": SolvabilitySolver.DEFAULT_MAX_VISITED,
	"max_depth": SolvabilitySolver.DEFAULT_MAX_DEPTH}

const LEVEL_1 := {"order": 1, "id": "m21_level_001_hazard_bot", "name": "Hazard Bot",
	"difficulty": "EASY",
	"source": "res://assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png"}

const PACK := [
	{"order": 2, "id": "level_002_apple", "name": "Apple", "difficulty": "EASY",
		"source": "res://assets/art/levels/source/easy/level_002_apple_32x32.png"},
	{"order": 3, "id": "level_003_palm_tree", "name": "Palm Tree", "difficulty": "MEDIUM",
		"source": "res://assets/art/levels/source/medium/level_003_palm_tree_38x38.png"},
	{"order": 4, "id": "level_004_orange_cat", "name": "Orange Cat", "difficulty": "EASY",
		"source": "res://assets/art/levels/source/easy/level_004_orange_cat_32x32.png"},
	{"order": 5, "id": "level_005_party_toucan", "name": "Party Toucan", "difficulty": "HARD",
		"source": "res://assets/art/levels/source/hard/level_005_party_toucan_33x33.png"},
	{"order": 6, "id": "level_006_chicken", "name": "Chicken", "difficulty": "EASY",
		"source": "res://assets/art/levels/source/easy/level_006_chicken_32x32.png"},
	{"order": 7, "id": "level_007_pigeon", "name": "Pigeon", "difficulty": "EASY",
		"source": "res://assets/art/levels/source/easy/level_007_pigeon_32x32.png"},
	{"order": 8, "id": "level_008_butterfly", "name": "Butterfly", "difficulty": "MEDIUM",
		"source": "res://assets/art/levels/source/medium/level_008_butterfly_32x32.png"},
	{"order": 9, "id": "level_009_frog", "name": "Frog", "difficulty": "EASY",
		"source": "res://assets/art/levels/source/easy/level_009_frog_32x32.png"},
	{"order": 10, "id": "level_010_ice_cube", "name": "Ice Cube", "difficulty": "VERY_HARD",
		"source": "res://assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png"},
]

static func level_path(id: String) -> String:
	return "res://data/levels/%s.json" % id

static func metadata_path(id: String) -> String:
	return "res://data/levels/metadata/%s.metadata.json" % id

static func preview_path(id: String) -> String:
	return "res://assets/art/levels/previews/%s.png" % id

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var overwrite := args.has("--overwrite")
	var only := ""
	for a in args:
		if String(a).begins_with("--only="):
			only = String(a).substr("--only=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOLVE_CACHE_DIR))
	var failures := 0
	var levels: Array = []
	for spec in [LEVEL_1] + PACK:
		if not only.is_empty() and spec["id"] != only:
			continue
		if int(spec["order"]) > 1:
			var r = ProductionArtLevelBuilder.build(spec["source"], spec["id"], spec["name"],
				spec["difficulty"], level_path(spec["id"]), preview_path(spec["id"]),
				metadata_path(spec["id"]), overwrite)
			if not r.is_ok():
				for e in r.errors:
					printerr("BUILD_FAIL %s: %s" % [spec["id"], e])
				failures += 1
				continue
			print("BUILD %s level=%s preview=%s metadata=%s" % [spec["id"],
				"WRITTEN" if r.output_written else "UNCHANGED",
				"WRITTEN" if r.preview_written else "UNCHANGED",
				"WRITTEN" if r.metadata_written else "UNCHANGED"])
		var rec := _record(spec)
		if not rec["pass"]:
			failures += 1
		levels.append(rec)
	if failures > 0:
		printerr("M52_PACK_FAIL failures=%d (evidence not written)" % failures)
		quit(1)
		return
	if not only.is_empty():
		print("M52_ONLY_OK %s" % only)
		quit(0)
		return
	var evidence := {
		"schema": EVIDENCE_SCHEMA,
		"version": 1,
		"sprint": "M52-C001",
		"builderVersion": ProductionArtLevelBuilder.BUILDER_VERSION,
		"paletteAuthority": ProductionArtLevelBuilder.PALETTE_AUTHORITY_PATH,
		"solverAuthority": solver_authority(),
		"difficultyAnalysis": {
			"status": "NOT_AVAILABLE_M52",
			"note": "No canonical real-level Challenge/SessionLoad/Frustration analyzer exists in the shipping repo; full per-level Difficulty V1 evidence is an M53 QA gate. Class tokens are owner-locked campaign labels.",
		},
		"levels": levels,
	}
	var text := JSON.stringify(evidence, "\t") + "\n"
	var existing := FileAccess.get_file_as_string(EVIDENCE_PATH) if FileAccess.file_exists(EVIDENCE_PATH) else ""
	if existing.replace("\r\n", "\n") == text:
		print("EVIDENCE UNCHANGED ", EVIDENCE_PATH)
	elif ProductionArtLevelBuilder._write_text(
			ProductionArtLevelBuilder._resolve_physical(EVIDENCE_PATH), text) == OK:
		print("EVIDENCE WRITTEN ", EVIDENCE_PATH)
	else:
		printerr("EVIDENCE_WRITE_FAIL")
		quit(1)
		return
	print("M52_PACK_OK levels=%d" % levels.size())
	quit(0)

static func solver_authority() -> Dictionary:
	return {
		"gate": "res://scripts/gameplay/solver/generation_gate.gd",
		"solver": "res://scripts/gameplay/solver/solvability_solver.gd",
		"runtimeSupplyAuthority": "res://scripts/gameplay/runtime/production_gameplay_host.gd",
		"baseSeed": BASE_SEED,
		"columnCount": COLUMN_COUNT,
		"visiblePreviewDepth": PREVIEW_DEPTH,
		"previewDepthSemantics": "player-facing visible rows only; total FIFO depth per column is not capped",
		"slotCapacity": SLOT_CAPACITY,
		"maxAttempts": MAX_ATTEMPTS,
		"maxVisited": SOLVER_CONFIG["max_visited"],
		"maxDepth": SOLVER_CONFIG["max_depth"],
	}

## Evidence record for one campaign level (Level 1 is read, never rebuilt).
func _record(spec: Dictionary) -> Dictionary:
	var id: String = spec["id"]
	var lp := level_path(id)
	var mp := metadata_path(id)
	var pp := preview_path(id)
	var rec := {"order": spec["order"], "id": id, "name": spec["name"],
		"difficulty": spec["difficulty"], "sourcePath": spec["source"],
		"sourceGitBlobSha1": ProductionArtLevelBuilder._git_blob_sha1_file(spec["source"]),
		"sourceSha256": ProductionArtLevelBuilder._sha256_file(spec["source"]),
		"levelPath": lp, "levelSha256": content_sha256(lp),
		"metadataPath": mp, "metadataSha256": content_sha256(mp),
		"previewPath": pp, "previewSha256": ProductionArtLevelBuilder._sha256_file(pp),
		"challengeScore": "NOT_AVAILABLE_M52", "sessionLoad": "NOT_AVAILABLE_M52",
		"frustrationRisk": "NOT_AVAILABLE_M52", "pass": false}
	var lr = LevelLoader.load_from_path(lp)
	if not lr.is_ok():
		printerr("LOAD_FAIL %s: %s" % [id, str(lr.errors)])
		return rec
	var lvl = lr.level_data
	rec["width"] = lvl.width
	rec["height"] = lvl.height
	rec["cellCount"] = lvl.get_cell_count()
	var meta = JSON.parse_string(FileAccess.get_file_as_string(mp))
	rec["usedColorIds"] = meta["normalizedColorOrder"]
	rec["usedColorCount"] = int(meta["usedColorCount"])
	rec["cellReferenceCounts"] = meta["cellReferenceCounts"]
	rec["difficultyMatchesOwnerLock"] = lvl.difficulty == spec["difficulty"]
	rec["productionValidation"] = "PASS" if ProductionLevelValidator.validate(lvl).is_ok() else "FAIL"
	rec["sourceReconstructionEqual"] = reconstruction_equal(spec["source"], lvl)
	rec["previewReconstructionEqual"] = reconstruction_equal(pp, lvl)
	rec["metadataSourceMatches"] = String(meta["sourcePath"]) == spec["source"] \
		and String(meta["sourceSha256"]) == rec["sourceSha256"]
	var solve := _cached_or_solve(id, rec["levelSha256"], lvl)
	rec.merge(solve, true)
	rec["pass"] = rec["difficultyMatchesOwnerLock"] and rec["productionValidation"] == "PASS" \
		and rec["sourceReconstructionEqual"] and rec["previewReconstructionEqual"] \
		and rec["metadataSourceMatches"] \
		and int(rec["usedColorCount"]) >= 3 and int(rec["usedColorCount"]) <= 12 \
		and solve.get("solverStatus", "") == String(SolvabilitySolver.SOLVED) \
		and solve.get("conservationOk", false) and solve.get("replaySolved", false) \
		and int(solve.get("acceptedSeed", -1)) == BASE_SEED \
		and solve.get("fullQueueConsumed", false) and solve.get("proofStateHoldsFullQueue", false)
	print("RECORD %s status=%s pass=%s" % [id, solve.get("solverStatus", "?"), rec["pass"]])
	return rec

## Solver results are expensive (real routing per clear). A cached result is
## reused only when produced for byte-identical LevelData AND the identical solver
## configuration. maxAttempts is the one exception: the gate stops at the first
## SOLVED attempt, so a cached SOLVED at attempt a is identical for any bound > a.
## Anything else (failure, different config/level bytes) is solved now.
func _cached_or_solve(id: String, level_sha: String, lvl) -> Dictionary:
	var cache_path := "%s/%s.json" % [SOLVE_CACHE_DIR, id]
	if FileAccess.file_exists(cache_path):
		var c = JSON.parse_string(FileAccess.get_file_as_string(cache_path))
		if typeof(c) == TYPE_DICTIONARY and c.get("levelSha256", "") == level_sha \
				and _auth_key(c.get("solverAuthority", {})) == _auth_key(solver_authority()) \
				and c.get("solve", {}).get("solverStatus", "") == String(SolvabilitySolver.SOLVED) \
				and int(c["solve"]["acceptedAttempt"]) < MAX_ATTEMPTS:
			print("SOLVE_CACHE_HIT %s" % id)
			return c["solve"]
	var solve := _solve(id, lvl)
	# Round-trip through JSON so fresh and cached records are type-identical.
	solve = JSON.parse_string(JSON.stringify(solve))
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"levelSha256": level_sha,
			"solverAuthority": solver_authority(), "solve": solve}, "\t"))
		f.close()
	return solve

static func _auth_key(auth: Dictionary) -> String:
	var a: Dictionary = JSON.parse_string(JSON.stringify(auth))
	a.erase("maxAttempts")
	return JSON.stringify(a, "", true)

func _solve(id: String, lvl) -> Dictionary:
	var out := {}
	var gate = GenerationGate.new()
	var t0 := Time.get_ticks_msec()
	var rep: Dictionary = gate.generate_accepted(lvl, COLUMN_COUNT, PREVIEW_DEPTH, BASE_SEED,
		MAX_ATTEMPTS, SOLVER_CONFIG)
	var elapsed := Time.get_ticks_msec() - t0
	var attempts: Array = []
	for a in rep["attempts"]:
		attempts.append({"attempt": a["attempt"], "effectiveSeed": a["effective_seed"],
			"outcome": String(a["outcome"]), "visited": a["visited"],
			"conservationOk": a["conservation_ok"]})
	out["solverAttempts"] = attempts
	var acc = rep["accepted"]
	if acc == null:
		out["solverStatus"] = String(attempts[-1]["outcome"]) if not attempts.is_empty() else "MALFORMED"
		printerr("SOLVE_FAIL %s: %s (elapsed_ms=%d)" % [id, str(attempts), elapsed])
		return out
	out["solverStatus"] = String(SolvabilitySolver.SOLVED)
	out["acceptedAttempt"] = int(acc["attempt"])
	out["acceptedSeed"] = int(acc["effective_seed"])
	out["visitedStates"] = int(acc["visited"])
	out["decisions"] = int(acc["decisions"])
	out["traceHash"] = int(acc["trace_hash"])
	out["traceSummary"] = String(acc["trace_summary"])
	out["conservationOk"] = bool(rep["attempts"][-1]["conservation_ok"])
	# Full hidden FIFO layout of the accepted candidate (visible depth 3 is NOT a cap).
	var layout: Array = []
	var lengths: Array = []
	var hidden: Array = []
	var total_batches := 0
	for col in acc["engine"].debug_snapshot()["columns"]:
		var q: Array = []
		for b in col:
			q.append({"batchId": String(b["batch_id"]), "colorIndex": int(b["color_id"]),
				"robots": int(b["robot_count"])})
		layout.append(q)
		lengths.append(q.size())
		hidden.append(maxi(0, q.size() - PREVIEW_DEPTH))
		total_batches += q.size()
	out["queueLengths"] = lengths
	out["hiddenBatchesBeyondVisibleRows"] = hidden
	out["totalBatches"] = total_batches
	out["queueLayout"] = layout
	# The solver's root ProofState (non-player snapshot) must hold every hidden batch.
	var fresh = BatchSupplyGenerator.generate(lvl, COLUMN_COUNT, PREVIEW_DEPTH, int(acc["effective_seed"]))
	var ps = ProofState.from_level_and_supply(lvl, fresh)
	var ps_lengths: Array = []
	for q in ps.supply:
		ps_lengths.append(q.size())
	out["proofStateQueueLengths"] = ps_lengths
	out["proofStateHoldsFullQueue"] = ps_lengths == lengths
	# Every batch consumed by a legal front selection == the complete queue was consumed.
	out["fullQueueConsumed"] = int(acc["decisions"]) == total_batches
	var replay: Dictionary = SolvabilitySolver.new().replay(ps, acc["trace"])
	out["replaySolved"] = bool(replay["ok"]) and bool(replay["solved"]) and int(replay["final_active"]) == 0
	out["replaySteps"] = int(replay["steps"])
	print("SOLVE %s status=SOLVED attempt=%d seed=%d visited=%d decisions=%d batches=%d queues=%s trace_hash=%d replay=%s elapsed_ms=%d" % [
		id, out["acceptedAttempt"], out["acceptedSeed"], out["visitedStates"], out["decisions"],
		total_batches, str(lengths), out["traceHash"], out["replaySolved"], elapsed])
	return out

## Decoded image at `path` (RGBA8) == reconstruction of the final LevelData.
static func reconstruction_equal(path: String, lvl) -> bool:
	var src := Image.new()
	if src.load(path) != OK:
		return false
	src.convert(Image.FORMAT_RGBA8)
	var img = LevelImporter.reconstruct_image(lvl)
	return img != null and src.get_width() == img.get_width() and src.get_height() == img.get_height() \
		and src.get_data() == img.get_data()

## SHA-256 of a file's canonical content: JSON text is hashed with CRLF folded to
## LF (== the git blob content, independent of core.autocrlf checkout); binary
## files (PNG) are hashed raw.
static func content_sha256(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".json"):
		bytes = FileAccess.get_file_as_string(path).replace("\r\n", "\n").to_utf8_buffer()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()
