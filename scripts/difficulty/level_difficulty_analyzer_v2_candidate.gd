extends RefCounted
## LevelDifficultyAnalyzerV2Candidate — preload
## (res://scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd).
##
## M53-C002 CANDIDATE (not production authority until owner adoption after audit).
## Offline QA tooling only; no shipping script references it.
##
## Differences from V1 (which is preserved unchanged for provenance):
##   - No oracle/solver trace enters any Challenge component. Decision-state metrics come
##     from a deterministic family of non-adversarial reference policies (RR, GREEDY,
##     ACCESS) replayed through the real ProofKernel; the primary value of every component
##     is the median over that ensemble. Tie-break variants (RR_REV, GREEDY_HI, ACCESS_HI)
##     measure robustness; a bounded STRESS policy feeds Frustration diagnostics only.
##   - U is colour-aware (same-colour closure waves under production access) instead of the
##     V1 colour-agnostic peel, which on fully ACTIVE rectangles is pure geometry.
##   - B ignores states with a single legal front (column exhaustion is not a bottleneck);
##     S's single-colour term only counts states demanding >= 2 colours.
##   - A is progress-interval weighted; A/U/R are normalized with anchors derived by rule
##     from the independent calibration corpus (tests/fixtures/difficulty_calibration).
## W, C, all weights and TargetChallenge lanes are read unchanged from the locked V1 files.

const V1 = preload("res://scripts/difficulty/level_difficulty_analyzer_v1.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ChallengeScoreModelV1 = preload("res://scripts/difficulty/challenge_score_model_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")

const CONFIG_PATH := "res://data/config/level_difficulty_analysis_v2_candidate.json"
const EXPECTED_SCHEMA := "scrubbots-level-difficulty-analysis/v2-candidate"
const ANCHOR_KEYS := ["A_lo", "A_hi", "U_p95_hi", "U_mean_hi", "R_len_lo", "R_len_hi",
	"R_detour_lo", "R_detour_hi", "R_turn_lo", "R_turn_hi"]
const MAX_DECISIONS := 2000

var _cfg: Dictionary = {}
var _score_cfg: Dictionary = {}
var _v1 = null
var _model = null
var _prog = null
var _error := ""

func _init(config_path: String = CONFIG_PATH) -> void:
	_cfg = V1._read_json(config_path)
	if _cfg.get("schema", "") != EXPECTED_SCHEMA:
		_error = "v2 candidate config missing/unexpected schema"
		return
	_score_cfg = V1._read_json(V1.SCORE_MODEL_PATH)
	_v1 = V1.new()
	_model = ChallengeScoreModelV1.new()
	_prog = DifficultyProgressionV1.new()
	if not _v1.is_ok() or not _model.is_ok() or not _prog.is_ok():
		_error = "model load failed"

func is_ok() -> bool:
	return _error.is_empty()

func get_error() -> String:
	return _error

func config() -> Dictionary:
	return _cfg

func primary_ensemble() -> Array:
	return _cfg["policies"]["primaryEnsemble"]

const FAMILIES := {"RR": ["RR", "RR_REV"], "GREEDY": ["GREEDY", "GREEDY_HI"], "ACCESS": ["ACCESS", "ACCESS_HI"]}

func all_policies() -> Array:
	var out: Array = primary_ensemble().duplicate()
	out.append(String(_cfg["policies"]["stress"]))
	return out

func anchors() -> Dictionary:
	var a = _cfg.get("calibratedAnchors", null)
	return a["values"] if typeof(a) == TYPE_DICTIONARY else {}

func provenance() -> Dictionary:
	return {"analyzerVersion": String(_cfg["analyzerVersion"]), "analysisConfig": CONFIG_PATH,
		"analysisConfigVersion": int(_cfg["version"]), "status": String(_cfg["status"]),
		"scoreModelVersion": _model.model_version(),
		"progressionModelVersion": int(V1._read_json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH).get("version", 0)),
		"freeze": _cfg.get("freeze", null)}

# =========================================================================== measure ==

## Measure raw, anchor-free facts: colour stats, colour-aware unlock waves and one run per
## policy. `make_engine` returns a fresh loaded BatchSupplyEngine per call.
## `fixed_paths` (optional, diagnostics only) = {name: [columns]} replayed as extra runs.
func measure(level, make_engine: Callable, fixed_paths: Dictionary = {}) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var out := {"ok": false, "dims": {"width": level.width, "height": level.height},
		"color": V1.color_stats(level), "unlock": unlock_waves(level), "runs": {}}
	for p in all_policies():
		out["runs"][p] = run_policy(level, make_engine.call(), p)
	for name in fixed_paths:
		out["runs"][name] = run_policy(level, make_engine.call(), name, fixed_paths[name])
	var ok: bool = int(out["unlock"]["unreachableCells"]) == 0
	for p in primary_ensemble():
		var r: Dictionary = out["runs"][p]
		ok = ok and int(r["routeFailures"]) == 0
	out["ok"] = ok
	out["timing"] = {"totalMs": Time.get_ticks_msec() - t0}
	return out

## Colour-aware unlock waves through production access (see config U definition).
func unlock_waves(level) -> Dictionary:
	var board = BoardState.from_level_data(level)
	var w: int = board.get_width()
	var h: int = board.get_height()
	var n: int = board.get_cell_count()
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var origin: Vector2 = ProofKernel.new()._origin_for_slot(ProofState.SLOT_COUNT - 1, w, h)
	var waves := PackedInt32Array()
	waves.resize(n)
	waves.fill(-1)
	var remaining := n
	var wave := 0
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	while remaining > 0:
		var access = ProductionTargetAccess.new(routing, raccess, board, origin)
		var wave_batch: Array = []
		for i in range(n):
			if waves[i] == -1 and access.is_targetable(i):
				wave_batch.append(i)
		if wave_batch.is_empty():
			break
		while not wave_batch.is_empty():
			for i in wave_batch:
				waves[i] = wave
				board.set_cell_state(i, BoardState.CellState.CLEARED)
			remaining -= wave_batch.size()
			# Same-colour closure: candidates adjacent to this wave_batch, same colour.
			var cand := {}
			for i in wave_batch:
				var p := Vector2i(i % w, i / w)
				for d in dirs:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
						continue
					var j: int = q.y * w + q.x
					if waves[j] == -1 and level.cells[j] == level.cells[i]:
						cand[j] = true
			var keys: Array = cand.keys()
			keys.sort()
			access = ProductionTargetAccess.new(routing, raccess, board, origin)
			var nxt: Array = []
			for j in keys:
				if access.is_targetable(j):
					nxt.append(j)
			wave_batch = nxt
		wave += 1
	var vals: Array = []
	var hist: Array = []
	hist.resize(wave)
	hist.fill(0)
	var tot := 0
	for v in waves:
		if v >= 0:
			vals.append(v)
			hist[v] += 1
			tot += v
	vals.sort()
	var p95: int = vals[maxi(0, int(ceil(0.95 * vals.size())) - 1)] if not vals.is_empty() else 0
	var chars := PackedStringArray()
	for v in waves:
		chars.append("?" if v < 0 else "0123456789abcdefghijklmnopqrstuvwxyz"[mini(v, 35)])
	return {"waveCount": wave, "maxWave": wave - 1, "meanWave": float(tot) / maxf(1.0, float(vals.size())),
		"p95Wave": p95, "lockedFraction": 1.0 - float(hist[0] if wave > 0 else 0) / float(n),
		"histogram": hist, "unreachableCells": n - vals.size(), "perCellWaves": "".join(chars)}

## Replay one policy (or a fixed column path) through the real ProofKernel.
func run_policy(level, engine, policy: String, fixed: Array = []) -> Dictionary:
	var cells: int = level.get_cell_count()
	var kernel = ProofKernel.new()
	var obs = V1.RouteObserver.new()
	kernel.observer = obs
	var q: Dictionary = kernel.quiesce(ProofState.from_level_and_supply(level, engine))
	var state = q["state"]
	var states: Array = []
	var placements: Array = []
	var last := -1
	var i := 0
	var stop_reason := "solved"
	while not state.is_solved():
		if i >= MAX_DECISIONS:
			stop_reason = "decision_bound"
			break
		if state.legal_action_columns().is_empty():
			stop_reason = "no_legal_placement"
			break
		if not fixed.is_empty() and i >= fixed.size():
			stop_reason = "fixed_path_ended"
			break
		var st: Dictionary = _v1._decision_state(level, kernel, state, cells)
		var col: int = int(fixed[i]) if not fixed.is_empty() else choose(policy, st, last, state.column_count)
		st["legal"] = (st["fronts"] as Array).size()
		st["chosen"] = col
		obs.begin_placement()
		var r: Dictionary = kernel.apply_placement(state, col)
		if not r.get("ok", false):
			stop_reason = "placement_rejected"
			break
		placements.append({"column": col, "clears": int(r["clears"]), "waves": obs.placement_waves,
			"lastWaveMaxRoute": obs.last_wave_max_len})
		states.append(st)
		state = r["state"]
		last = col
		i += 1
	return {"policy": policy, "completed": state.is_solved(), "stopReason": stop_reason,
		"finalProgress": 1.0 - float(state.active_count()) / float(cells), "decisions": states.size(),
		"states": states, "placements": placements, "routes": obs.route_summary(),
		"routeFailures": obs.failures}

## Deterministic policy choice over the sampled decision state.
static func choose(policy: String, st: Dictionary, last: int, ncols: int) -> int:
	var fronts: Array = st["fronts"]
	var pool: Array = []
	if policy != "STRESS":
		for f in fronts:
			if bool(f["productive"]):
				pool.append(f)
	if pool.is_empty():
		pool = fronts
	var by_col := {}
	for f in pool:
		by_col[int(f["column"])] = f
	match policy:
		"RR", "RR_REV":
			for k in range(1, ncols + 1):
				var c: int = posmod(last + k, ncols) if policy == "RR" else posmod(last - k, ncols)
				if last < 0 and policy == "RR_REV":
					c = posmod(ncols - k, ncols)
				if by_col.has(c):
					return c
		"STRESS":
			var best = null
			for f in pool:
				if best == null or int(f["reachable"]) < int(best["reachable"]):
					best = f
			return int(best["column"])
	var hi_tie: bool = policy.ends_with("_HI")
	var best_f = null
	var best_key := []
	for f in pool:
		var reach := float(f["reachable"])
		var key: Array
		if policy.begins_with("ACCESS"):
			key = [minf(reach, float(f["robots"])) / float(f["robots"]), reach]
		else:
			key = [reach]
		if best_f == null or _key_gt(key, best_key) or (key == best_key and hi_tie):
			best_f = f
			best_key = key
	return int(best_f["column"])

static func _key_gt(a: Array, b: Array) -> bool:
	for i in range(a.size()):
		if a[i] != b[i]:
			return a[i] > b[i]
	return false

# ============================================================================= score ==

## Anchor-free raw components of one policy run.
func run_components(run: Dictionary, dims: Dictionary, cells: int) -> Dictionary:
	var states: Array = run["states"]
	var prio: float = float(_score_cfg["accessibilityScarcity"]["priorityProgressFraction"])
	var early: float = float(_cfg["fixedParameters"]["accessibilityEarlyWeight"])
	var low_thr: int = int(_score_cfg["bottleneckPressure"]["lowChoiceThreshold"])
	var wsum := 0.0
	var asum := 0.0
	var uni := 0.0
	var considered := 0
	var forced := 0
	var low := 0
	var streak := 0
	var best := 0
	var stuck := 0
	var single := 0
	var imb_num := 0.0
	var imb_den := 0.0
	var legal_total := 0
	var nonprod := 0
	for t in range(states.size()):
		var st: Dictionary = states[t]
		var p0: float = float(st["progress"])
		var p1: float = float(states[t + 1]["progress"]) if t + 1 < states.size() else float(run["finalProgress"])
		# Demand-relative accessibility, per offered/occupied batch: need = min(raw of its
		# colour, its robots); got = min(reachable of its colour, need).
		var seen := {}
		var prod_colors := {}
		var need_n := 0
		var got_n := 0
		for f in (st["fronts"] as Array) + (st["occupied"] as Array):
			var c := int(f["color"])
			if int(f["reachable"]) > 0:
				prod_colors[c] = true
			var need: int = mini(int(f["raw"]), int(f["robots"] if f.has("robots") else f["remaining"]))
			need_n += need
			got_n += mini(int(f["reachable"]), need)
			seen[c] = f
		var rem: Array = []
		for c in seen:
			rem.append(float(seen[c]["raw"]))
		var at: float = 1.0 - float(got_n) / float(maxi(need_n, 1))
		# Remaining-work imbalance across the demanded colours (1 - normalized entropy).
		if rem.size() >= 2:
			var tot := 0.0
			for v in rem:
				tot += v
			var hh := 0.0
			for v in rem:
				if v > 0.0:
					hh -= (v / tot) * log(v / tot)
			imb_num += 1.0 - hh / log(float(rem.size()))
		imb_den += 1.0
		var wt: float = maxf(p1 - p0, 0.0) * (early if p0 < prio else 1.0)
		wsum += wt
		asum += wt * at
		uni += at
		var legal: int = (st["fronts"] as Array).size()
		var prod := 0
		for f in st["fronts"]:
			legal_total += 1
			if bool(f["productive"]):
				prod += 1
			else:
				nonprod += 1
		if legal >= 2:
			considered += 1
			if prod <= 1:
				forced += 1
				streak += 1
				best = maxi(best, streak)
			else:
				streak = 0
			if prod <= low_thr and prod < legal:
				low += 1
		else:
			streak = 0
		for o in st["occupied"]:
			if int(o["reachable"]) == 0:
				stuck += 1
				break
		if seen.size() >= 2 and prod_colors.size() == 1:
			single += 1
	var nd: int = maxi(states.size(), 1)
	var nc: int = maxi(considered, 1)
	var bp: Dictionary = _score_cfg["bottleneckPressure"]
	var low_f := float(low) / float(nc)
	var forced_f := float(forced) / float(nc)
	var streak_n := float(best) / float(nc)
	var B: float = float(bp["lowChoiceFractionWeight"]) * low_f + float(bp["forcedFractionWeight"]) * forced_f \
		+ float(bp["forcedStreakWeight"]) * streak_n
	var sp: Dictionary = _score_cfg["slotColorPressure"]
	var stuck_f := float(stuck) / float(nd)
	var single_f := float(single) / float(nd)
	var imb: float = imb_num / imb_den if imb_den > 0.0 else 0.0
	var S: float = float(sp["noWorkSlotFractionWeight"]) * stuck_f + float(sp["singleProductiveSlotFractionWeight"]) * single_f \
		+ float(sp["colorDemandImbalanceWeight"]) * imb
	var routes: Dictionary = run["routes"]
	var diag: float = sqrt(float(int(dims["width"]) * int(dims["width"]) + int(dims["height"]) * int(dims["height"])))
	var rt: Dictionary = _cfg["runtimeConstants"]
	var duration := 0.0
	for p in run["placements"]:
		duration += float(p["waves"]) * float(rt["baseCadenceSeconds"]) + float(p["lastWaveMaxRoute"]) / float(rt["botSpeedCellsPerSecond"])
	return {
		"A_raw": asum / wsum if wsum > 0.0 else uni / float(nd),
		"B": clampf(B, 0.0, 1.0), "B_lowChoice": low_f, "B_forced": forced_f, "B_streakNorm": streak_n,
		"B_consideredStates": considered,
		"S": clampf(S, 0.0, 1.0), "S_noWork": stuck_f, "S_singleColor": single_f, "S_imbalance": imb,
		"R_len": float(routes["meanLength"]) / diag, "R_detour": float(routes["meanDetour"]),
		"R_turn": float(routes["meanTurns"]),
		"dispatches": int(routes["count"]), "routeSeconds": float(routes["totalLength"]) / float(rt["botSpeedCellsPerSecond"]),
		"decisions": int(run["decisions"]), "durationProxySeconds": duration,
		"nonProductiveLegalFraction": float(nonprod) / float(maxi(legal_total, 1)),
		"completed": bool(run["completed"]), "finalProgress": float(run["finalProgress"]),
	}

const MEDIAN_KEYS := ["A_raw", "B", "B_lowChoice", "B_forced", "B_streakNorm", "S", "S_noWork", "S_singleColor",
	"S_imbalance", "R_len", "R_detour", "R_turn", "dispatches", "routeSeconds", "decisions",
	"durationProxySeconds", "nonProductiveLegalFraction"]

## Component-wise aggregate (config aggregateStatistic: mean or median) over the named runs (anchor free).
func aggregate(raw: Dictionary, names: Array) -> Dictionary:
	var comps: Array = []
	var cells: int = int(raw["color"]["cells"])
	for n in names:
		comps.append(run_components(raw["runs"][n], raw["dims"], cells))
	var out := {}
	for k in MEDIAN_KEYS:
		var vals: Array = []
		for c in comps:
			vals.append(float(c[k]))
		out[k] = _median(vals) if String(_cfg["policies"].get("aggregateStatistic", "median")) == "median" else _mean(vals)
	return out

static func _mean(vals: Array) -> float:
	var t := 0.0
	for v in vals:
		t += float(v)
	return t / float(maxi(vals.size(), 1))

static func _median(vals: Array) -> float:
	var v := vals.duplicate()
	v.sort()
	var n: int = v.size()
	if n == 0:
		return 0.0
	return v[n / 2] if n % 2 == 1 else 0.5 * (v[n / 2 - 1] + v[n / 2])

## Normalize an aggregate into the V1-weighted vector and D (anchors required).
func vector_from(agg: Dictionary, raw: Dictionary, anc: Dictionary) -> Dictionary:
	var col: Dictionary = raw["color"]
	var un: Dictionary = raw["unlock"]
	var ud: Dictionary = _score_cfg["unlockDepth"]
	var rc: Dictionary = _score_cfg["routeComplexity"]
	var W: float = _model.workload_submetric(int(col["cells"]))
	var C: float = _model.color_submetric(int(col["usedColors"]), float(col["normalizedEntropy"]))
	var A: float = _lin(float(agg["A_raw"]), float(anc["A_lo"]), float(anc["A_hi"]))
	var U: float = float(ud["p95Weight"]) * _lin(float(un["p95Wave"]), 0.0, float(anc["U_p95_hi"])) \
		+ float(ud["meanWeight"]) * _lin(float(un["meanWave"]), 0.0, float(anc["U_mean_hi"])) \
		+ float(ud["initiallyLockedFractionWeight"]) * clampf(float(un["lockedFraction"]), 0.0, 1.0)
	var R: float = float(rc["averageRouteLengthWeight"]) * _lin(float(agg["R_len"]), float(anc["R_len_lo"]), float(anc["R_len_hi"])) \
		+ float(rc["averageDetourWeight"]) * _lin(float(agg["R_detour"]), float(anc["R_detour_lo"]), float(anc["R_detour_hi"])) \
		+ float(rc["averageTurnWeight"]) * _lin(float(agg["R_turn"]), float(anc["R_turn_lo"]), float(anc["R_turn_hi"]))
	var vec := {"W": _c01(W), "C": _c01(C), "A": _c01(A), "U": _c01(U), "B": _c01(float(agg["B"])),
		"R": _c01(R), "S": _c01(float(agg["S"]))}
	var fp: Dictionary = _cfg["fixedParameters"]
	var load_in := {"actions": _c01(float(agg["dispatches"]) / float(fp["sessionActionsReference"])),
		"routeTime": _c01(float(agg["routeSeconds"]) / float(fp["sessionRouteTimeReferenceSeconds"])),
		"decisionCount": _c01(float(agg["decisions"]) / float(fp["sessionDecisionReference"]))}
	return {"vector": vec, "D": _model.challenge_score(vec), "sessionLoad": _model.session_load(load_in),
		"sessionInputs": load_in}

## Full candidate score for a measured level/fixture. level_number <= 0 -> no target.
func score(raw: Dictionary, level_number: int = 0, anchor_override: Dictionary = {}) -> Dictionary:
	var anc: Dictionary = anchors().duplicate()
	for k in anchor_override:
		anc[k] = anchor_override[k]
	var prim := primary_ensemble()
	var agg := aggregate(raw, prim)
	var main := vector_from(agg, raw, anc)
	# Per-policy spread (reported separately).
	var per_policy := {}
	for p in raw["runs"]:
		var v := vector_from(aggregate(raw, [p]), raw, anc)
		per_policy[p] = {"D": v["D"], "vector": v["vector"], "completed": raw["runs"][p]["completed"],
			"finalProgress": raw["runs"][p]["finalProgress"], "decisions": raw["runs"][p]["decisions"]}
	var ens_d: Array = []
	for p in prim:
		ens_d.append(float(per_policy[p]["D"]))
	# Robustness gate: leave-one-out (6) and tie-break-uniform variants (each family's two
	# members both replaced by one of them, 6). Leave-family-out = strategy spread (reported).
	var robust: Array = []
	var max_dev := 0.0
	var variants_list: Array = []
	for p in prim:
		var names: Array = prim.duplicate()
		names.erase(p)
		variants_list.append({"kind": "leave_one_out", "label": "-" + p, "names": names})
	for fam in FAMILIES:
		for m in FAMILIES[fam]:
			var names2: Array = []
			for p in prim:
				names2.append(m if (FAMILIES[fam] as Array).has(p) else p)
			variants_list.append({"kind": "tie_break_uniform", "label": "%s->%s" % [fam, m], "names": names2})
	for v in variants_list:
		var d: float = vector_from(aggregate(raw, v["names"]), raw, anc)["D"]
		robust.append({"kind": v["kind"], "variant": v["label"], "D": d, "deviation": d - main["D"]})
		max_dev = maxf(max_dev, absf(d - main["D"]))
	var family_spread: Array = []
	var fam_max := 0.0
	for fam in FAMILIES:
		var names3: Array = []
		for p in prim:
			if not (FAMILIES[fam] as Array).has(p):
				names3.append(p)
		var d3: float = vector_from(aggregate(raw, names3), raw, anc)["D"]
		family_spread.append({"withoutFamily": fam, "D": d3, "deviation": d3 - main["D"]})
		fam_max = maxf(fam_max, absf(d3 - main["D"]))
	var fam_only := {}
	for fam in FAMILIES:
		fam_only[fam] = vector_from(aggregate(raw, FAMILIES[fam]), raw, anc)["D"]
	var halves := {}
	for half in [["RR", "GREEDY", "ACCESS"], ["RR_REV", "GREEDY_HI", "ACCESS_HI"]]:
		halves[",".join(PackedStringArray(half))] = vector_from(aggregate(raw, half), raw, anc)["D"]
	var tol: float = float(_cfg["policies"]["robustnessToleranceD"])
	var out := {
		"vector": main["vector"], "challengeScore": main["D"], "sessionLoad": main["sessionLoad"],
		"sessionInputs": main["sessionInputs"], "aggregateRaw": agg,
		"unlock": {"p95Wave": raw["unlock"]["p95Wave"], "meanWave": raw["unlock"]["meanWave"],
			"maxWave": raw["unlock"]["maxWave"], "lockedFraction": raw["unlock"]["lockedFraction"]},
		"policySpread": {"perPolicy": per_policy, "primaryEnsembleDRange": [ens_d.min(), ens_d.max()],
			"allPolicyDRange": _range_d(per_policy)},
		"robustness": {"toleranceD": tol, "variants": robust, "maxDeviation": max_dev, "pass": max_dev <= tol,
			"tieBreakHalvesD": halves},
		"strategyFamilySpread": {"leaveFamilyOut": family_spread, "maxLeaveFamilyOutDeviation": fam_max,
			"familyOnlyD": fam_only, "note": "genuine strategy differences between valid policy families; reported, not gated"},
		"frustration": frustration(raw, agg, main["vector"]),
		"profile": V1.profile(main["vector"]),
		"anchorsUsed": anc,
	}
	if level_number > 0:
		var target: float = _prog.target_challenge_for(level_number)
		out["targetChallenge"] = target
		out["signedDelta"] = main["D"] - target
		out["absoluteDelta"] = absf(main["D"] - target)
		out["acceptanceWindow"] = _v1.classify_window(main["D"] - target)
	return out

static func _range_d(pp: Dictionary) -> Array:
	var lo := 1e9
	var hi := -1e9
	for k in pp:
		lo = minf(lo, float(pp[k]["D"]))
		hi = maxf(hi, float(pp[k]["D"]))
	return [lo, hi]

func frustration(raw: Dictionary, agg: Dictionary, vec: Dictionary) -> Dictionary:
	var s: Dictionary = raw["runs"][String(_cfg["policies"]["stress"])]
	var dead := 0
	for st in s["states"]:
		for f in st["fronts"]:
			if int(f["column"]) == int(st["chosen"]) and not bool(f["productive"]):
				dead += 1
	var opacity := _c01(0.5 * float(vec["B"]) + 0.5 * float(agg["nonProductiveLegalFraction"]))
	var prim_complete := 0
	for p in primary_ensemble():
		if bool(raw["runs"][p]["completed"]):
			prim_complete += 1
	return {"status": "PROVISIONAL_STAGE_A", "scalar": null,
		"components": {
			"retryRisk": {"status": "UNSUPPORTED", "reason": "no trustworthy simulated-human policy; policy/solver completion is not a human clear rate"},
			"sessionOverrun": {"status": "UNSUPPORTED", "reason": "no owner per-slot Session Load budget"},
			"lateFailure": {"status": "DIAGNOSTIC_ONLY", "stressCompleted": s["completed"], "stressStopReason": s["stopReason"],
				"stressFailureProgress": null if s["completed"] else s["finalProgress"],
				"stressLateFailure": (not s["completed"]) and float(s["finalProgress"]) > 0.70},
			"choiceOpacity": {"status": "SUPPORTED_PROXY", "value": opacity}},
		"stressDeadPlacements": dead, "stressDecisions": s["decisions"],
		"primaryPoliciesCompleted": "%d/%d" % [prim_complete, primary_ensemble().size()]}

static func _lin(v: float, lo: float, hi: float) -> float:
	if hi <= lo:
		return 0.0 if v <= lo else 1.0
	return clampf((v - lo) / (hi - lo), 0.0, 1.0)

static func _c01(v: float) -> float:
	if is_nan(v) or is_inf(v):
		return 0.0
	return clampf(v, 0.0, 1.0)
