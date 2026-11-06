extends SceneTree
## SB-UI-VIS-006 / SB-UI-031 — cheap re-check of the pixel QA (`tools/ui_vis_006_asset_qa.py`,
## `docs/ui_vis_006_asset_qa.csv`). For every PNG row of the CSV: the .import stays lossless
## (compress/mode=0), without mipmaps, with fix_alpha_border on and premult_alpha off; and for
## every UI texture with a measured drawn rect, the imported size (source PNG, process/size_limit
## applied) is not below the drawn rect on the fitting axis (max(imp_w / drawn_w, imp_h / drawn_h)
## >= 1, no upscaling on screen). The rows the report already records as under-res (res=FAIL:
## video stills at video resolution, owner-locked gameplay shells, Home background) are known
## defects listed in docs/UI_VIS_006_ASSET_QA.md and may not drop below their recorded ratio;
## every other row must stay >= 1x. Fails if a
## limit is lowered or a source PNG is swapped for a smaller one.
## Run: godot --headless --path . -s res://tests/ui_vis_006_asset_qa.gd

const CSV := "res://docs/ui_vis_006_asset_qa.csv"
const REQUIRED := {"compress/mode": 0, "mipmaps/generate": false, "process/fix_alpha_border": true, "process/premult_alpha": false}

var _fail := 0

func _initialize() -> void:
	var f := FileAccess.open(CSV, FileAccess.READ)
	_ok(f != null, "%s readable" % CSV)
	if f == null:
		return _done()
	var head := f.get_csv_line()
	var pngs := 0
	var drawn := 0
	var bad_import: Array = []
	var under: Array = []
	var known := 0
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() != head.size():
			continue
		var row := {}
		for i in head.size():
			row[head[i]] = line[i]
		var path := "res://" + String(row["path"])
		if not path.ends_with(".png"):
			continue
		pngs += 1
		var c := ConfigFile.new()
		if c.load(path + ".import") != OK:
			bad_import.append(path + " (no .import)")
			continue
		for k in REQUIRED:
			if c.get_value("params", k, REQUIRED[k]) != REQUIRED[k]:
				bad_import.append("%s %s=%s" % [path, k, str(c.get_value("params", k))])
		if String(row["drawn_w"]) == "":
			continue
		drawn += 1
		var size := _png_size(path)
		var limit := int(c.get_value("params", "process/size_limit", 0))
		var s := float(limit) / maxf(size.x, size.y) if limit > 0 and limit < maxf(size.x, size.y) else 1.0
		var ratio := maxf(roundf(size.x * s) / float(row["drawn_w"]), roundf(size.y * s) / float(row["drawn_h"]))
		# A known under-res row may not get worse than recorded; every other row stays >= 1x.
		var floor_ratio := float(row["res_ratio"]) - 0.01 if row["res"] == "FAIL" else 1.0
		known += int(row["res"] == "FAIL")
		if ratio < floor_ratio:
			under.append("%s %.2fx of %sx%s drawn" % [path, ratio, row["drawn_w"], row["drawn_h"]])
	_ok(pngs > 400, "CSV lists %d PNGs" % pngs)
	_ok(drawn > 150, "%d PNGs have a measured drawn size" % drawn)
	_ok(bad_import.is_empty(), "imports lossless, no mipmaps, fix_alpha_border, no premult %s" % str(bad_import.slice(0, 5)))
	_ok(under.is_empty(), "no texture imported below its drawn rect %s" % str(under.slice(0, 5)))
	print("  (%d known under-res rows recorded in the report)" % known)
	_done()

func _png_size(path: String) -> Vector2:
	var b := FileAccess.get_file_as_bytes(path).slice(16, 24)
	if b.size() < 8:
		return Vector2.ZERO
	b.reverse()   # IHDR width / height are big-endian
	return Vector2(b.decode_u32(4), b.decode_u32(0))

func _done() -> void:
	print("UI-VIS-006 ASSET QA: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	print("  %s: %s" % ["ok" if cond else "FAIL", msg])
	if not cond:
		_fail += 1
