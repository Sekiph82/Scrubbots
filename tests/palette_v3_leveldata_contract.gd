extends SceneTree
## PALETTE-V3-C001 V01 — palette V3 / Level Data V1 contract regression.
##
## Palette authority version and Level Data schema version are separate concepts:
##   - canonical palette = scrubbots-global-palette/v3, version 3;
##   - Level Data schema = LevelData.FORMAT_VERSION == 1 (LevelLoader accepts exactly 1).
## Proves the shipped Hazard Bot keeps v3 colors with schema version 1, loads through
## LevelLoader, uses only canonical v3 colors, and that ProductionArtLevelBuilder emits
## Level Data version 1 (never the palette version) from the real source art.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/palette_v3_leveldata_contract.gd

const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")

const PALETTE_V3 := "res://data/palettes/scrubbots_palette_v3.json"
const PALETTE_V2 := "res://data/palettes/scrubbots_palette_v2.json"
const HAZARD := "res://data/levels/m21_level_001_hazard_bot.json"
const HAZARD_SOURCE := "res://assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png"
const WS := "user://palette_v3_contract"

const EXPECTED_CASES := [
	"palette_authority_v3", "hazard_schema_v1", "hazard_loads", "hazard_colors_in_v3",
	"builder_emits_format_v1", "fake_v2_rejected",
]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	var v3 := _palette_authority_v3()
	_hazard_schema_v1()
	_hazard_loads()
	_hazard_colors_in_v3(v3)
	_builder_emits_format_v1()
	_fake_v2_rejected()
	_done()

func _json(path: String):
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return j.get_data()

func _palette_authority_v3() -> Dictionary:
	print("[palette authority v3]")
	var pal = _json(PALETTE_V3)
	_ok(typeof(pal) == TYPE_DICTIONARY, "palette v3 JSON parses")
	if typeof(pal) != TYPE_DICTIONARY:
		return {}
	_ok(pal.get("schema") == "scrubbots-global-palette/v3", "palette schema is scrubbots-global-palette/v3")
	_ok(int(pal.get("version", 0)) == 3 and float(pal.get("version")) == 3.0, "palette version is 3")
	var colors: Array = pal.get("colors", [])
	var hexes := {}
	var ids_ok := colors.size() == 16
	for i in range(colors.size()):
		ids_ok = ids_ok and colors[i]["id"] == "C%02d" % (i + 1)
		hexes[String(colors[i]["hex"]).to_upper()] = colors[i]["id"]
	_ok(ids_ok and hexes.size() == 16, "palette v3 has 16 unique colors C01..C16 in order")
	_ok(ProductionArtLevelBuilder.PALETTE_AUTHORITY_PATH == PALETTE_V3, "builder palette authority is v3")
	_ok(FileAccess.file_exists(PALETTE_V2), "historical palette v2 file is preserved")
	_ok(LevelData.FORMAT_VERSION == 1, "LevelData.FORMAT_VERSION stays 1 (palette v3 != Level Data v3)")
	_complete("palette_authority_v3")
	return hexes

func _hazard_schema_v1() -> void:
	print("[hazard schema v1]")
	var lv = _json(HAZARD)
	_ok(typeof(lv) == TYPE_DICTIONARY, "Hazard Bot JSON parses")
	_ok(typeof(lv) == TYPE_DICTIONARY and float(lv.get("version", -1)) == 1.0, "Hazard Bot Level Data version is 1")
	_ok(typeof(lv) == TYPE_DICTIONARY and lv.get("id") == "m21_level_001_hazard_bot" and int(lv.get("width")) == 20 and int(lv.get("height")) == 20 and (lv.get("cells") as Array).size() == 400, "id / 20x20 / 400 cells preserved")
	_complete("hazard_schema_v1")

func _hazard_loads() -> void:
	print("[hazard loads]")
	var r = LevelLoader.load_from_path(HAZARD)
	_ok(r.is_ok(), "LevelLoader loads Hazard Bot (errors: %s)" % str(r.errors))
	if r.is_ok():
		_ok(r.level_data.version == 1 and r.level_data.get_cell_count() == 400, "loaded LevelData version 1, 400 cells")
	_complete("hazard_loads")

func _hazard_colors_in_v3(v3: Dictionary) -> void:
	print("[hazard colors in v3]")
	var lv = _json(HAZARD)
	var palette: Array = lv.get("palette", []) if typeof(lv) == TYPE_DICTIONARY else []
	var cids: Array = []
	var all_in := palette.size() > 0
	for h in palette:
		var hex := String(h).to_upper()
		_ok(hex.length() == 9 and hex.ends_with("FF"), "%s is opaque RRGGBBFF" % hex)
		var cid = v3.get(hex.substr(0, 7), null)
		if cid == null:
			all_in = false
			_ok(false, "%s is not a palette v3 color" % hex)
		else:
			cids.append(cid)
	_ok(all_in, "every Hazard Bot local palette color belongs to palette v3 (%s)" % str(cids))
	var sorted_cids := cids.duplicate()
	sorted_cids.sort()
	_ok(cids == sorted_cids, "local palette ordered by ascending C-ID")
	_ok(palette == ["#FF4500FF", "#FFD635FF", "#2450A4FF", "#9C6926FF", "#000000FF"], "Alpix-aligned v3 colors kept (not reverted to v2)")
	_complete("hazard_colors_in_v3")

func _builder_emits_format_v1() -> void:
	print("[builder emits format v1]")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WS))
	var out := WS + "/level.json"
	var prev := WS + "/preview.png"
	var meta := WS + "/meta.json"
	var b = ProductionArtLevelBuilder.build(HAZARD_SOURCE, "m21_level_001_hazard_bot", "Hazard Bot", "EASY", out, prev, meta, true)
	_ok(b.is_ok(), "builder builds Hazard Bot from the real source art (errors: %s)" % str(b.errors))
	if b.is_ok():
		_ok(b.normalize.level_data.version == LevelData.FORMAT_VERSION and b.normalize.level_data.version == 1, "normalized LevelData.version == FORMAT_VERSION == 1")
		var j := JSON.new()
		_ok(j.parse(b.level_json_text) == OK and float(j.get_data().get("version")) == 1.0, "builder JSON output has \"version\": 1, not palette version 3")
		var committed = _json(HAZARD)
		var built = j.get_data()
		_ok(built.get("palette") == committed.get("palette") and built.get("cells") == committed.get("cells"), "builder output palette+cells == committed Hazard Bot (committed data is exact v3 build)")
		_ok(String(b.metadata_dict.get("paletteAuthority", "")) == PALETTE_V3, "builder metadata paletteAuthority is v3")
	for p in [out, prev, meta]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_complete("builder_emits_format_v1")

## Guard against "fixing" by widening the loader: a level declaring version 2 must still fail.
func _fake_v2_rejected() -> void:
	print("[fake v2 rejected]")
	var lv = _json(HAZARD)
	lv["version"] = 2
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WS))
	var p := WS + "/fake_v2.json"
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(JSON.stringify(lv))
	f.close()
	var r = LevelLoader.load_from_path(p)
	_ok(not r.is_ok() and str(r.errors).find("unsupported version") != -1, "undefined Level Data V2 is rejected by LevelLoader")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_complete("fake_v2_rejected")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("Palette V3 / LevelData V1 cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("Palette V3 / LevelData V1 contract: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
