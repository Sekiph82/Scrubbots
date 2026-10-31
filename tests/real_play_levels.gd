extends SceneTree
## SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE — shippability gate: every production catalog level
## is played through the REAL ProductionGameplayHost under the human policy
## (scripts/gameplay/solver/real_play_driver.gd, model real_play_v1) and must reach WON.
##   - levels: every catalog entry's clicks at the canonical dt 1/60 -> WON, ACTIVE 0, supply
##     exhausted, slots empty, no rejected click;
##   - fps_sensitivity: the same clicks at dt 1/30 and 1/120 for the regenerated levels plus
##     L18 and L20 (all 30 at three dts would not fit the CI per-suite timeout; every level's
##     three-dt WON is recorded by tools/real_play_verify.gd in provenance verifiedDts);
##   - provenance: every catalog entry has a real_play_provenance_v1 record, status WON, its
##     planSha256 == the current plan file, regenerated exactly when the plan differs from
##     originalPlanSha256 (a level added without running tools/real_play_verify.gd fails here);
##   - determinism: L22 played twice gives the identical cleared-cell sequence;
##   - search_negative: the pre-regeneration L22 clicks get stuck under real play, and the
##     real-play search finds a winning order for them.
## Bare host via an AppState frontier on temp user:// saves; never boots main.tscn.
##
## Run: godot --headless --path . -s res://tests/real_play_levels.gd

const RealPlayDriver = preload("res://scripts/gameplay/solver/real_play_driver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

## L22 intendedColumnClicks as imported from the Studio (ProofKernel-legal, LOST under real play).
const OLD_L22 := [1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 3, 3, 5, 5, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5]
const L22 := "level_022_crab"

var EXPECTED_CASES := ["levels", "fps_sensitivity", "provenance", "determinism", "search_negative"]

var _fail := 0
var _completed: Dictionary = {}
var _entries: Array = []
var _prov: Dictionary = {}

func _initialize() -> void:
	await process_frame
	var cat = LevelCatalog.new()
	var lr = cat.load_manifest()
	_ok(lr.ok, "production catalog validates %s" % lr.summary())
	_entries = cat.get_entries_ordered()
	_prov = RealPlayDriver.load_provenance()
	await _levels()
	await _fps_sensitivity()
	_provenance()
	await _determinism()
	await _search_negative()
	_done()

func _levels() -> void:
	print("[levels: %d catalog levels, human policy, dt 1/60]" % _entries.size())
	for e in _entries:
		var clicks := RealPlayDriver.clicks_for(e.id, e.supply_plan_path, _prov)
		var r: Dictionary = await RealPlayDriver.play_level(get_root(), e.id, clicks, RealPlayDriver.CANONICAL_DT)
		var f: Dictionary = r.get("final", {})
		_ok(r.get("won", false) and int(f.get("active", -1)) == 0 and f.get("supply_exhausted", false) and f.get("slots_empty", false)
			and r.get("rejected", {}).is_empty() and (r.get("clicks_placed", -1) == clicks.size() or clicks.is_empty()),
			"L%d %s: %s -> WON at 1/60 in %d frames %s" % [e.order, e.id, ("%d plan clicks" % clicks.size()) if not clicks.is_empty() else ("%d first-front clicks (no plan)" % int(r.get("clicks_placed", 0))), int(r.get("frames", 0)), "" if r.get("won", false) else str(r.get("final", r.get("error", "")))])
	_completed["levels"] = true

func _fps_sensitivity() -> void:
	var subset: Array = _entries.filter(func(e): return e.order == 18 or e.order == 20 or bool(_prov.get(e.id, {}).get("regenerated", false)))
	print("[fps_sensitivity: dt 1/30 and 1/120 for the regenerated levels + L18 + L20 (%s); all levels' three-dt WON is in provenance]" % str(subset.map(func(e): return "L%d" % e.order)))
	for e in subset:
		var clicks := RealPlayDriver.clicks_for(e.id, e.supply_plan_path, _prov)
		for dt in [1.0 / 30.0, 1.0 / 120.0]:
			var r: Dictionary = await RealPlayDriver.play_level(get_root(), e.id, clicks, dt)
			_ok(r.get("won", false) and r.get("rejected", {}).is_empty(), "L%d %s: WON at %s (%d frames)" % [e.order, e.id, RealPlayDriver.dt_label(dt), int(r.get("frames", 0))])
	_completed["fps_sensitivity"] = true

func _provenance() -> void:
	print("[provenance: %s]" % RealPlayDriver.PROVENANCE_PATH)
	var regenerated: Array = []
	for e in _entries:
		var rec: Dictionary = _prov.get(e.id, {})
		var has_plan := not String(e.supply_plan_path).is_empty()
		var sha = RealPlayDriver.plan_sha256(e.supply_plan_path) if has_plan else null
		_ok(not rec.is_empty() and rec.get("status", "") == "WON" and rec.get("planSha256") == sha and rec.get("model", "") == RealPlayDriver.MODEL
			and rec.get("canonicalDt", "") == "1/60" and rec.get("verifiedDts", []) == ["1/30", "1/60", "1/120"]
			and (rec.get("clicks") if rec.get("clicks") is Array else []).map(func(c): return int(c)) == RealPlayDriver.clicks_for(e.id, e.supply_plan_path, _prov),
			"L%d %s: record WON, model %s, planSha256 == plan file %s" % [e.order, e.id, RealPlayDriver.MODEL, str(sha).left(12)])
		var changed: bool = has_plan and rec.has("originalPlanSha256") and rec["originalPlanSha256"] != sha
		_ok(bool(rec.get("regenerated", false)) == changed and (not changed or rec.get("originalIntendedColumnClicks", []).size() > 0),
			"L%d: regenerated == %s (plan differs from originalPlanSha256; old clicks kept)" % [e.order, str(changed)])
		if changed:
			regenerated.append("L%d" % e.order)
	print("    regenerated plans: %s" % str(regenerated))
	_completed["provenance"] = true

func _determinism() -> void:
	print("[determinism: %s twice at 1/60]" % L22)
	var e = _entry(L22)
	var clicks := RealPlayDriver.clicks_for(e.id, e.supply_plan_path, _prov)
	var a: Dictionary = await RealPlayDriver.play_level(get_root(), L22, clicks)
	var b: Dictionary = await RealPlayDriver.play_level(get_root(), L22, clicks)
	var ha := _hash(a["cleared_sequence"])
	var hb := _hash(b["cleared_sequence"])
	print("    cleared_sequence sha256 run 1 %s, run 2 %s (%d clears)" % [ha, hb, a["cleared_sequence"].size()])
	_ok(a["cleared_sequence"] == b["cleared_sequence"] and ha == hb and a["frames"] == b["frames"] and a["won"], "identical cleared_sequence and frame count across two runs")
	_completed["determinism"] = true

func _search_negative() -> void:
	print("[search_negative: pre-regeneration L22 clicks]")
	var old: Dictionary = await RealPlayDriver.play_level(get_root(), L22, OLD_L22)
	_ok(not old["won"] and old["stuck"], "old L22 clicks are NOT WON under real play: stuck after click %d/%d, %d ACTIVE left (%s)" % [int(old["clicks_placed"]), OLD_L22.size(), int(old["final"]["active"]), old["final"]["terminal"]])
	var s: Dictionary = await RealPlayDriver.search(get_root(), L22, OLD_L22)
	_ok(s["status"] == "SOLVED" and s.get("robust", false) and s["clicks"] != OLD_L22,
		"search from the old clicks: %s in %d nodes (budget %d), WON at 1/30, 1/60 and 1/120 (%d canonical-only wins rejected)" % [s["status"], int(s["nodes"]), RealPlayDriver.NODE_BUDGET, int(s.get("robust_rejects", 0))])
	_completed["search_negative"] = true

func _entry(id: String):
	for e in _entries:
		if e.id == id:
			return e
	return null

func _hash(seq: Array) -> String:
	return JSON.stringify(seq).sha256_text()

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
	print("REAL PLAY LEVELS: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
