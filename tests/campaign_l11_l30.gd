extends SceneTree
## SB-CAMPAIGN-L11-L30 — 20 Level Factory Studio release-pool levels as campaign L11..L30
## (owner 2026-10-30; imported by tools/import_release_pool_levels.py):
##   - catalog: exactly 30 entries, orders 1..30, L1..L10 unchanged, L11..L30 in the locked order;
##   - levels: load + LevelValidator + ProductionLevelValidator, square 20..59, palette V3
##     C01..C16 ascending, 3..12 colours, VOID only in version 2, cadence class per slot;
##   - provenance: metadata binds the release-pool entry (digest, owner candidate, sha256s) and
##     matches the level (colour counts, VOID count); preview pixels == the level cells;
##   - win: each plan loads fail-closed, its intendedColumnClicks are non-empty and legal (every
##     click pops a front batch, every batch is clicked) and the Studio SOLVED + replay WIN
##     evidence is in metadata. WON under real play is asserted by tests/real_play_levels.gd
##     (SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE): a regenerated plan need not be ProofKernel-legal;
##   - frontier: fresh profile resolves L1..L30 in order, L31 is CONTENT_MISSING, and feature
##     unlocks follow the owner table up to L30.
## Never boots main.tscn: AppState on temp user:// paths.
##
## Run: godot --headless --path . -s res://tests/campaign_l11_l30.gd

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const AppState = preload("res://scripts/app/app_state.gd")

const FIRST_TEN := ["m21_level_001_hazard_bot", "level_002_apple", "level_003_palm_tree", "level_004_orange_cat",
	"level_005_party_toucan", "level_006_chicken", "level_007_pigeon", "level_008_butterfly", "level_009_frog",
	"level_010_ice_cube"]
const NEW_LEVELS := ["level_011_duckling", "level_012_ladybug", "level_013_goldfish", "level_014_goose",
	"level_015_octopus", "level_016_teddy_bear", "level_017_ninja", "level_018_wizard", "level_019_whale",
	"level_020_detective", "level_021_bunny", "level_022_crab", "level_023_bumblebee", "level_024_chef",
	"level_025_knight", "level_026_sheep", "level_027_black_cat", "level_028_squirrel", "level_029_turtle",
	"level_030_clown"]

var EXPECTED_CASES := ["catalog", "levels", "provenance", "win", "frontier"]

var _fail := 0
var _completed: Dictionary = {}
var _cat
var _cids: Dictionary = {}   # "#RRGGBB" -> C-ID

func _initialize() -> void:
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_cids[String(c["hex"]).to_upper()] = String(c["id"])
	_catalog()
	_levels()
	_provenance()
	_win()
	_frontier()
	_done()

func _new_entries() -> Array:
	return _cat.get_entries_ordered().slice(10)

func _level(e):
	return LevelLoader.load_from_path(e.level_path).level_data

func _catalog() -> void:
	print("[catalog]")
	_cat = LevelCatalog.new()
	var r = _cat.load_manifest()
	_ok(r.ok, "production catalog validates %s" % r.summary())
	var ids: Array = []
	var orders: Array = []
	for e in _cat.get_entries_ordered():
		ids.append(e.id)
		orders.append(e.order)
	_ok(_cat.size() == 30 and ids == FIRST_TEN + NEW_LEVELS and orders == range(1, 31), "30 entries, orders 1..30, ids in order")
	for e in _new_entries():
		_ok(e.supply_plan_path == "res://data/levels/supply/%s_supply_v1.json" % e.id and e.preview_exists
			and e.metadata_path == "res://data/levels/metadata/%s.metadata.json" % e.id, "%s: plan, preview and metadata paths" % e.id)
	_completed["catalog"] = true

func _levels() -> void:
	print("[levels]")
	var prog = LevelProgressionService.new()
	for e in _new_entries():
		var lr = LevelLoader.load_from_path(e.level_path)
		if not lr.is_ok():
			_ok(false, "%s loads: %s" % [e.id, str(lr.errors)])
			continue
		var lv = lr.level_data
		_ok(ProductionLevelValidator.validate(lv).is_ok(), "%s: ProductionLevelValidator" % e.id)
		_ok(lv.width == lv.height and lv.width >= 20 and lv.width <= 59, "%s: square %dx%d inside 20..59" % [e.id, lv.width, lv.height])
		var ids: Array = []
		var opaque := true
		for hex in lv.palette:
			opaque = opaque and String(hex).to_upper().ends_with("FF")
			ids.append(_cids.get(String(hex).substr(0, 7).to_upper(), "?"))
		var sorted_ids := ids.duplicate()
		sorted_ids.sort()
		_ok(opaque and not ids.has("?") and ids == sorted_ids and ids.size() >= 3 and ids.size() <= 12,
			"%s: %d opaque canonical colours ascending %s" % [e.id, ids.size(), str(ids)])
		var voids: int = lv.get_void_cell_count()
		_ok((voids > 0) == (lv.version == LevelData.FORMAT_VERSION_VOID), "%s: version %d with %d VOID" % [e.id, lv.version, voids])
		_ok(lv.difficulty == prog.class_for(e.order), "%s: class %s == cadence slot %d" % [e.id, lv.difficulty, e.order])
	_completed["levels"] = true

func _provenance() -> void:
	print("[provenance]")
	for e in _new_entries():
		var lv = _level(e)
		var md = JSON.parse_string(FileAccess.get_file_as_string(e.metadata_path))
		var rp = md.get("releasePool", {})
		_ok(String(rp.get("candidateId", "")).begins_with("candidate-owner-") and rp.get("derivation", "") == "EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE"
			and String(rp.get("entryDigest", "")).length() == 64 and String(rp.get("ownerSourceSha256", "")).length() == 64
			and String(rp.get("levelSha256", "")).length() == 64 and String(rp.get("supplyPlanSha256", "")).length() == 64
			and rp.get("artworkSha256", "") == md.get("sourceSha256", "-")
			and rp.get("studioSolverStatus", "") == "SOLVED" and rp.get("studioReplay", "") == "WIN", "%s: release-pool provenance (Studio SOLVED + replay WIN) %s" % [e.id, String(rp.get("candidateId", "")).left(40)])
		var counts := {}
		for c in lv.cells:
			if c != LevelData.VOID_CELL:
				var cid: String = _cids[String(lv.palette[c]).substr(0, 7).to_upper()]
				counts[cid] = int(counts.get(cid, 0)) + 1
		var md_counts := {}
		for k in md["cellReferenceCounts"]:
			md_counts[k] = int(md["cellReferenceCounts"][k])
		_ok(md_counts == counts and int(md.get("voidCellCount", 0)) == lv.get_void_cell_count() and md["difficulty"] == lv.difficulty,
			"%s: metadata matches the level cells" % e.id)
		var img := Image.load_from_file(e.preview_path)
		var same: bool = img != null and img.get_width() == lv.width and img.get_height() == lv.height
		if same:
			for i in lv.cells.size():
				var px := img.get_pixel(i % lv.width, i / lv.width)
				var want := Color(0, 0, 0, 0) if lv.cells[i] == LevelData.VOID_CELL else Color.html(lv.palette[lv.cells[i]])
				if px.to_rgba32() != want.to_rgba32() and not (want.a8 == 0 and px.a8 == 0):
					same = false
					break
		_ok(same, "%s: preview pixels == level cells" % e.id)
	_completed["provenance"] = true

func _win() -> void:
	print("[win]")
	for e in _new_entries():
		var lv = _level(e)
		var res: Dictionary = SupplyPlanLoader.load_engine(e.supply_plan_path, lv)
		if not res["ok"]:
			_ok(false, "%s: plan loads: %s" % [e.id, res["error"]])
			continue
		var plan = JSON.parse_string(FileAccess.get_file_as_string(e.supply_plan_path))
		var left: Array = []
		for col in plan["columns"]:
			left.append(col.size())
		var clicks: Array = plan["intendedColumnClicks"]
		var legal := not clicks.is_empty()
		for c in clicks:
			var col := int(c) - 1
			legal = legal and col >= 0 and col < left.size() and left[col] > 0
			if not legal:
				break
			left[col] -= 1
		var rp = JSON.parse_string(FileAccess.get_file_as_string(e.metadata_path)).get("releasePool", {})
		_ok(legal and left.all(func(n): return n == 0) and rp.get("studioSolverStatus", "") == "SOLVED" and rp.get("studioReplay", "") == "WIN",
			"%s: %d legal clicks consume every batch; Studio evidence SOLVED + replay WIN" % [e.id, clicks.size()])
	_completed["win"] = true

func _frontier() -> void:
	print("[frontier]")
	var root := "user://campaign_l11_l30_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var app = AppState.new(root + "/save.json", Callable(), Callable(), root + "/content")
	app.economy.ftue.mark_new()
	var all := FIRST_TEN + NEW_LEVELS
	var order_ok := true
	for n in range(1, 31):
		var r: Dictionary = GameplayLaunchResolver.resolve(app)
		if not (r["ok"] and int(r["level"]) == n and r["entry_id"] == all[n - 1]):
			order_ok = false
			print("  frontier %d -> %s" % [n, str(r)])
		_ok(app.feature_unlocked("collection") == (n >= 20) and app.feature_unlocked("card_packs") == (n >= 20)
			and app.feature_unlocked("robots") == (n >= 25) and app.feature_unlocked("events") == (n >= 30),
			"frontier %d: collection/card_packs/robots/events unlock per owner table" % n)
		app.progression.record_win(n)
	_ok(order_ok, "fresh profile resolves L1..L30 to the catalog entries in order")
	_ok(GameplayLaunchResolver.resolve(app)["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "frontier 31 -> CONTENT_MISSING (end of builtin catalog)")
	_ok(app.feature_unlocked("achievements") == false and app.feature_unlock_level("achievements") == 35, "achievements (L35) still locked at frontier 31")
	_completed["frontier"] = true
	_remove_tree(ProjectSettings.globalize_path(root))

func _remove_tree(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_remove_tree(dir.path_join(sub))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("CAMPAIGN L11-L30 evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
