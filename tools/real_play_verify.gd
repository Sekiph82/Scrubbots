extends SceneTree
## SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE real-play verification (model real_play_v1, see
## scripts/gameplay/solver/real_play_driver.gd). Plays every selected production level
## (catalog order) through the real ProductionGameplayHost under the human policy at dt 1/30,
## 1/60 and 1/120 and prints one line per level.
##
## --regen: for each level whose current clicks fail at any dt, run the real-play search and
## rewrite ONLY the plan's intendedColumnClicks array (text splice: every other byte stays),
## or for a level without a plan record the searched clicks in provenance; re-verify; then
## write data/levels/supply/real_play_provenance_v1.json (sorted keys, stable bytes). Without
## --regen nothing is written. A level with no winning column order (EXHAUSTED or budget hit)
## is never edited: its search stats print and the exit code is 1 (owner question).
##
## Run: godot --headless --path . -s res://tools/real_play_verify.gd -- [--levels 11,12|all] [--regen]

const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var regen := args.has("--regen")
	var sel := "all"
	var li := args.find("--levels")
	if li != -1 and li + 1 < args.size():
		sel = args[li + 1]
	var cat = LevelCatalog.new()
	if not cat.load_manifest().ok:
		print("REAL PLAY VERIFY: FAIL (production catalog invalid)")
		quit(1)
		return
	var prov := RealPlayDriver.load_provenance()
	var fail := 0
	var count := 0
	for e in cat.get_entries_ordered():
		if sel != "all" and not Array(sel.split(",")).has(str(e.order)) and not Array(sel.split(",")).has(e.id):
			continue
		count += 1
		var clicks := RealPlayDriver.clicks_for(e.id, e.supply_plan_path, prov)
		var v: Dictionary = await RealPlayDriver.verify(get_root(), e.id, clicks)
		var search := {}
		if not v["won"] and regen:
			var plan: Array = clicks if not String(e.supply_plan_path).is_empty() else []
			search = await RealPlayDriver.search(get_root(), e.id, plan)
			search["original"] = clicks
			print("SEARCH L%d %s %s nodes=%d/%d robust=%s" % [e.order, e.id, search["status"], int(search["nodes"]), RealPlayDriver.NODE_BUDGET, str(search.get("robust", false))])
			if search["status"] == "SOLVED":
				var old_sha := RealPlayDriver.plan_sha256(e.supply_plan_path) if not String(e.supply_plan_path).is_empty() else ""
				if not String(e.supply_plan_path).is_empty():
					_write_clicks(e.supply_plan_path, search["clicks"])
				clicks = RealPlayDriver.clicks_for(e.id, e.supply_plan_path, {e.id: {"clicks": search["clicks"]}})
				v = await RealPlayDriver.verify(get_root(), e.id, clicks)
				prov[e.id] = _record(e, clicks, v, search, prov.get(e.id, {}), old_sha, search["robust"])
		elif v["won"] and regen:
			prov[e.id] = _record(e, clicks, v, {}, prov.get(e.id, {}), "", bool(prov.get(e.id, {}).get("robust", true)))
		print(_line(e, clicks, v))
		if not v["won"]:
			fail += 1
			if not search.is_empty() and search["status"] != "SOLVED":
				print("UNWINNABLE L%d %s: %s (owner question; nothing edited)" % [e.order, e.id, str(search)])
	if regen:
		_write_provenance(cat, prov)
	print("REAL PLAY VERIFY: %s (%d levels, %d not WON)" % ["PASS" if fail == 0 else "FAIL", count, fail])
	quit(0 if fail == 0 else 1)

func _line(e, clicks: Array, v: Dictionary) -> String:
	var r: Dictionary = v["results"]
	var s := "LEVEL L%d %s plan=%d clicks" % [e.order, e.id, clicks.size()]
	for label in ["1/60", "1/30", "1/120"]:
		var x: Dictionary = r[label]
		s += " %dfps %s" % [int(label.split("/")[1]), "WON" if x.get("won", false) else "NOT_WON(stuck=%s placed=%d active=%d %s)" % [str(x.get("stuck")), int(x.get("clicks_placed", 0)), int(x.get("final", {}).get("active", -1)), str(x.get("rejected", x.get("error", "")))]]
		if label == "1/60":
			s += " frames=%d" % int(x.get("frames", 0))
	return s

## A provenance record. A previously regenerated plan that is unchanged keeps its original
## (pre-regeneration) evidence; a fresh regeneration records `old_sha` and the old clicks.
func _record(e, clicks: Array, v: Dictionary, search: Dictionary, prev: Dictionary, old_sha: String, robust: bool) -> Dictionary:
	var has_plan := not String(e.supply_plan_path).is_empty()
	var sha := RealPlayDriver.plan_sha256(e.supply_plan_path) if has_plan else ""
	var rec := {
		"levelId": e.id,
		"order": e.order,
		"planSha256": sha if has_plan else null,
		"model": RealPlayDriver.MODEL,
		"canonicalDt": RealPlayDriver.dt_label(RealPlayDriver.CANONICAL_DT),
		"verifiedDts": RealPlayDriver.SENSITIVITY_DTS.map(func(dt): return RealPlayDriver.dt_label(dt)),
		"status": "WON" if v["won"] else "NOT_WON",
		"framesAtCanonical": int(v["results"][RealPlayDriver.dt_label(RealPlayDriver.CANONICAL_DT)].get("frames", 0)),
		"clicks": clicks if has_plan or not clicks.is_empty() else null,
		"regenerated": false,
		"searchNodes": 0,
		"nodeBudget": RealPlayDriver.NODE_BUDGET,
		"robust": robust,
	}
	if not search.is_empty():
		rec["searchNodes"] = int(search["nodes"])
		if has_plan:
			var again: bool = prev.get("regenerated", false) and prev.get("planSha256", "") == old_sha
			rec["regenerated"] = true
			rec["originalPlanSha256"] = prev["originalPlanSha256"] if again else old_sha
			rec["originalIntendedColumnClicks"] = _ints(prev["originalIntendedColumnClicks"] if again else search["original"])
	elif prev.get("regenerated", false) and prev.get("planSha256", "") == sha:
		rec["regenerated"] = true
		rec["originalPlanSha256"] = prev["originalPlanSha256"]
		rec["originalIntendedColumnClicks"] = _ints(prev["originalIntendedColumnClicks"])
		rec["searchNodes"] = int(prev["searchNodes"])
	elif not has_plan and prev.has("searchNodes"):
		rec["searchNodes"] = int(prev["searchNodes"])
	return rec

## JSON numbers parse as floats; keep ints so a re-run writes identical bytes.
func _ints(a: Array) -> Array:
	return a.map(func(c): return int(c))

## Whole-number floats -> int, recursively (records carried over from the parsed file).
func _whole(v):
	if v is float and v == floorf(v):
		return int(v)
	if v is Array:
		return v.map(func(x): return _whole(x))
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _whole(v[k])
		return out
	return v

## Replace only the intendedColumnClicks array text (same tab layout as the importer's
## json.dumps(indent="\t"), the file's own line endings); every other byte is untouched.
func _write_clicks(path: String, clicks: Array) -> void:
	var text := FileAccess.get_file_as_string(path)
	var eol := "\r\n" if text.contains("\r\n") else "\n"
	var items: Array = []
	for c in clicks:
		items.append("\t\t%d" % int(c))
	var re := RegEx.create_from_string("\"intendedColumnClicks\": \\[[^\\]]*\\]")
	var out := re.sub(text, "\"intendedColumnClicks\": [" + eol + (("," + eol).join(items)) + eol + "\t]")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(out)
	f.close()

func _write_provenance(cat, prov: Dictionary) -> void:
	var records: Array = []
	for e in cat.get_entries_ordered():
		if prov.has(e.id):
			records.append(_whole(prov[e.id]))
	var text := JSON.stringify({"schema": RealPlayDriver.PROVENANCE_SCHEMA, "model": RealPlayDriver.MODEL, "records": records}, "\t", true) + "\n"
	var path := RealPlayDriver.PROVENANCE_PATH
	if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path).replace("\r\n", "\n") == text:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
