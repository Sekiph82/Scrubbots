extends SceneTree
## SB-CAMPAIGN-L31-L200 — 170 owner release-pool levels as campaign L31..L200 (owner 2026-11-17;
## imported by tools/import_release_pool_levels.py --batch l31-l200). Fast data checks only: the
## per-level real play is the import gate (tools/real_play_gate_l31_l200.json), not re-run here.
##   - catalog: exactly 200 entries, orders 1..200, L31..L200 ids in the locked order with plan,
##     preview and metadata paths;
##   - levels: load + LevelValidator + ProductionLevelValidator, square inside 20..59, palette V3
##     C01..C16 ascending, 3..12 colours, VOID only in version 2, >= 200 non-VOID cells, class ==
##     cadence slot class;
##   - provenance: metadata binds the release-pool entry, the cells digest equals the recorded
##     source digest, colour/VOID counts match, preview pixels == cells;
##   - gate: every level has a WON_CANONICAL real-play gate row whose level and plan sha256 equal
##     the committed files, and a WON real_play_provenance_v1 record;
##   - frontier: fresh profile resolves L1..L200 in order, frontier 201 is CONTENT_MISSING, L151
##     enters world 2 and RANKS opens at L40.
## Never boots main.tscn: AppState on temp user:// paths.
##
## Run: godot --headless --path . -s res://tests/campaign_l31_l200.gd

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const WorldService = preload("res://scripts/progression/world_service.gd")

const GATE_REPORT := "res://tools/real_play_gate_l31_l200.json"
const NEW_LEVELS := [
	"level_031_cricket", "level_032_longhorn_beetle", "level_033_fire_jellyfish", "level_034_stag_beetle", "level_035_mop_bucket",
	"level_036_lobster", "level_037_weevil", "level_038_scarab", "level_039_mantis", "level_040_sweeper_bot",
	"level_041_spirit_stag", "level_042_drone", "level_043_storm_cloud", "level_044_sea_dragon", "level_045_dark_drake",
	"level_046_rose_wasp", "level_047_claw_bot", "level_048_robo_hound", "level_049_spider", "level_050_jade_knight",
	"level_051_dragonfly", "level_052_orchid_mantis", "level_053_rhino_beetle", "level_054_lava_salamander", "level_055_swamp_slime",
	"level_056_moon_jellyfish", "level_057_shrimp", "level_058_centaur", "level_059_fawn", "level_060_roller_bot",
	"level_061_scorpion", "level_062_hornet", "level_063_sea_serpent", "level_064_amber_dragonfly", "level_065_robo_piranha",
	"level_066_skeleton", "level_067_golden_stag_beetle", "level_068_seahorse", "level_069_fire_spirit", "level_070_fire_drake",
	"level_071_speckled_weevil", "level_072_moth", "level_073_sentry_eye", "level_074_firefly", "level_075_repair_bot",
	"level_076_spirit_bird", "level_077_stick_mantis", "level_078_azure_dragonfly", "level_079_forest_spirit", "level_080_pufferfish",
	"level_081_jewel_beetle", "level_082_anglerfish", "level_083_shadow_wolf", "level_084_tiger_bug", "level_085_nautilus",
	"level_086_shadow_wisp", "level_087_flying_fish", "level_088_lava_spider", "level_089_isopod", "level_090_fire_tortoise",
	"level_091_smoky_lobster", "level_092_tiger_moth", "level_093_clownfish", "level_094_fire_dragon", "level_095_bell_mushroom",
	"level_096_bronze_beetle", "level_097_star_spirit", "level_098_ghost", "level_099_goblin", "level_100_larva",
	"level_101_painted_beetle", "level_102_shark", "level_103_fishfolk", "level_104_arctic_fox", "level_105_hover_bot",
	"level_106_wasp", "level_107_fire_fairy", "level_108_zombie", "level_109_bubble_spirit", "level_110_geode_beast",
	"level_111_mist_spirit", "level_112_crayfish", "level_113_teal_scarab", "level_114_starfish", "level_115_magma_golem",
	"level_116_phoenix", "level_117_white_wolf", "level_118_water_spirit", "level_119_ember_stag", "level_120_drill_bot",
	"level_121_fire_imp", "level_122_brazier", "level_123_sky_shark", "level_124_dung_beetle", "level_125_blue_slime",
	"level_126_sprout", "level_127_pine_tree", "level_128_roadrunner", "level_129_hoopoe", "level_130_moss_monster",
	"level_131_ember_stump", "level_132_spider_bot", "level_133_manta_ray", "level_134_leafy_sea_dragon", "level_135_grim_reaper",
	"level_136_water_serpent", "level_137_dryad", "level_138_scrub_racer", "level_139_glow_firefly", "level_140_tank_bot",
	"level_141_diving_beetle", "level_142_red_wasp", "level_143_frost_stag", "level_144_swamp_dragon", "level_145_mushroom",
	"level_146_lantern_ghost", "level_147_flame_lizard", "level_148_blue_jay", "level_149_robo_beetle", "level_150_mimic",
	"level_151_sunbird", "level_152_night_beetle", "level_153_glider_fish", "level_154_stalactite", "level_155_skull_druid",
	"level_156_sun_spirit", "level_157_tv_bot", "level_158_bog_slime", "level_159_swamp_tree", "level_160_sphinx",
	"level_161_radio_bot", "level_162_shadow_mage", "level_163_grub", "level_164_tesla_coil", "level_165_monitor_bot",
	"level_166_moss_wolf", "level_167_ice_dragonfly", "level_168_fire_golem", "level_169_glue_bottle", "level_170_lamp_bot",
	"level_171_parrot", "level_172_teal_ghost", "level_173_unicorn", "level_174_emerald_beetle", "level_175_wave_spirit",
	"level_176_mandrake", "level_177_harbor_seal", "level_178_mop_bot", "level_179_gremlin", "level_180_dome_bot",
	"level_181_lightning_spirit", "level_182_red_demon", "level_183_flower_spirit", "level_184_cyclops", "level_185_washer_bot",
	"level_186_cactus", "level_187_pixie", "level_188_jade_scarab", "level_189_rock_monster", "level_190_crawler_bot",
	"level_191_frost_wraith", "level_192_merman", "level_193_spray_bottle", "level_194_ent", "level_195_clay_golem",
	"level_196_sea_star", "level_197_eye_bot", "level_198_goo_ghoul", "level_199_seal", "level_200_sea_wyrm",
]

var EXPECTED_CASES := ["catalog", "levels", "provenance", "gate", "frontier"]

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
	_gate()
	_frontier()
	_done()

func _new_entries() -> Array:
	return _cat.get_entries_ordered().slice(30, 200)  # L31..L200 only; later releases follow

func _level(e):
	return LevelLoader.load_from_path(e.level_path).level_data

func _catalog() -> void:
	print("[catalog]")
	_cat = LevelCatalog.new()
	var r = _cat.load_manifest()
	_ok(r.ok, "production catalog validates %s" % r.summary())
	var orders: Array = _cat.get_entries_ordered().map(func(e): return e.order)
	var ids: Array = _new_entries().map(func(e): return e.id)
	_ok(_cat.size() >= 200 and orders == range(1, _cat.size() + 1) and ids == NEW_LEVELS, "orders 1..N contiguous, L31..L200 ids in order")
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
		_ok((voids > 0) == (lv.version == LevelData.FORMAT_VERSION_VOID) and lv.cells.size() - voids >= 200,
			"%s: version %d, %d VOID, %d artwork cells (>= 200)" % [e.id, lv.version, voids, lv.cells.size() - voids])
		_ok(lv.difficulty == prog.class_for(e.order), "%s: class %s == cadence slot %d" % [e.id, lv.difficulty, e.order])
	_completed["levels"] = true

func _provenance() -> void:
	print("[provenance]")
	for e in _new_entries():
		var lv = _level(e)
		var md = JSON.parse_string(FileAccess.get_file_as_string(e.metadata_path))
		var rp = md.get("releasePool", {})
		var digest := ",".join(Array(lv.cells).map(func(c): return str(int(c)))).sha256_text()
		_ok(String(rp.get("candidateId", "")).begins_with("candidate-owner-") and rp.get("derivation", "") == "EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE"
			and String(rp.get("entryDigest", "")).length() == 64 and String(rp.get("ownerSourceSha256", "")).length() == 64
			and String(rp.get("supplyPlanSha256", "")).length() == 64 and rp.get("artworkSha256", "") == md.get("sourceSha256", "-")
			and rp.get("studioSolverStatus", "") == "WON_CANONICAL" and rp.get("studioReplay", "") == "WON_CANONICAL"
			and md.get("builderVersion", "") == "SB-CAMPAIGN-L31-L200/release-pool-import/v1",
			"%s: release-pool provenance %s" % [e.id, String(rp.get("candidateId", "")).left(40)])
		_ok(rp.get("cellsSha256", "") == digest, "%s: cells digest == recorded source digest %s" % [e.id, digest.left(12)])
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

func _gate() -> void:
	print("[gate: %s]" % GATE_REPORT)
	var rows := {}
	var report = JSON.parse_string(FileAccess.get_file_as_string(GATE_REPORT))
	for row in (report.get("levels", []) if report is Dictionary else []):
		rows[String(row["levelId"])] = row
	var prov := RealPlayDriver.load_provenance()
	for e in _new_entries():
		var row: Dictionary = rows.get(e.id, {})
		var rec: Dictionary = prov.get(e.id, {})
		var plan_sha := RealPlayDriver.plan_sha256(e.supply_plan_path)
		_ok(row.get("verdict", "") == "WON_CANONICAL" and int(row.get("order", 0)) == e.order and int(row.get("frames", 0)) > 0
			and row.get("planSha256", "") == plan_sha and row.get("levelSha256", "") == RealPlayDriver.plan_sha256(e.level_path)
			and String(row.get("gameCommit", "")).length() == 40,
			"L%d %s: gate WON_CANONICAL in %d frames on %s, level + plan sha256 == files" % [e.order, e.id, int(row.get("frames", 0)), String(row.get("gameCommit", "")).left(8)])
		_ok(rec.get("status", "") == "WON" and rec.get("planSha256", "") == plan_sha, "L%d: provenance record WON for the current plan" % e.order)
	_completed["gate"] = true

func _frontier() -> void:
	print("[frontier]")
	var root := "user://campaign_l31_l200_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var app = AppState.new(root + "/save.json", Callable(), Callable(), root + "/content")
	app.economy.ftue.mark_new()
	var all: Array = _cat.get_entries_ordered().map(func(e): return e.id)
	var order_ok := true
	for n in range(1, all.size() + 1):
		var r: Dictionary = GameplayLaunchResolver.resolve(app)
		if not (r["ok"] and int(r["level"]) == n and r["entry_id"] == all[n - 1]):
			order_ok = false
			print("  frontier %d -> %s" % [n, str(r)])
		if n == 39 or n == 40:
			_ok(app.feature_unlocked("ranks") == (n == 40), "frontier %d: RANKS unlocked == %s" % [n, str(n == 40)])
		app.progression.record_win(n)
	_ok(order_ok, "fresh profile resolves every catalog level to its entry in order")
	_ok(GameplayLaunchResolver.resolve(app)["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "frontier after the last catalog level -> CONTENT_MISSING (end of builtin catalog)")
	_ok(int(WorldService.world_for_level(150)["number"]) == 1 and int(WorldService.world_for_level(151)["number"]) == 2
		and int(WorldService.world_for_level(200)["number"]) == 2, "worlds_v1: L150 world 1, L151..L200 world 2")
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
	print("CAMPAIGN L31-L200 evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
