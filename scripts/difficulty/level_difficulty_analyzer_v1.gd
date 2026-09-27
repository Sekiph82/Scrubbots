extends RefCounted
## LevelDifficultyAnalyzerV1 — preload
## (res://scripts/difficulty/level_difficulty_analyzer_v1.gd).
##
## M53-C001: the canonical real-level Difficulty V1 analyzer. OFFLINE QA TOOLING ONLY —
## no shipping runtime script preloads it (asserted by tests/m53_first10_difficulty.gd).
##
## Two stages, deliberately separated:
##   measure(level, supply_engine, columns) — the expensive part. Replays a reference
##     path (ordered legal column placements) through the REAL ProofKernel (M23 supply,
##     M24 slots, M25 claims, TargetSelector, production routing/access), observing every
##     exact-slot claim through the kernel's read-only observer seam, and samples every
##     quiescent decision state with ProductionTargetAccess. Also runs the colour-agnostic
##     reachability peel with the same production access truth. Returns RAW measurements
##     only — no normalization, no anchors.
##   score(raw, level_number, anchors) — pure and cheap. Normalizes raw measurements with
##     the versioned Stage-A anchors (data/config/level_difficulty_analysis_v1.json) and
##     the locked component weights/formulas (data/config/difficulty_score_model_v1.json,
##     ChallengeScoreModelV1), producing [W,C,A,U,B,R,S], D, target/delta/window, Session
##     Load and the provisional Frustration record. Re-scoring with other anchors is how
##     sensitivity is reported; nothing is hand-tuned per level.
##
## It owns no routing law: every reachability/route fact comes from ProductionTargetAccess
## / ProductionRoutingSystem / RouteValidator. It never mutates LevelData, source art,
## supply plans or any file.

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const ChallengeScoreModelV1 = preload("res://scripts/difficulty/challenge_score_model_v1.gd")
const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")

const DEFAULT_CONFIG_PATH := "res://data/config/level_difficulty_analysis_v1.json"
const EXPECTED_SCHEMA := "scrubbots-level-difficulty-analysis/v1"
const SCORE_MODEL_PATH := "res://data/config/difficulty_score_model_v1.json"

const WINDOW_IN := "IN_DEFAULT_WINDOW"
const WINDOW_SOFT := "OUTSIDE_DEFAULT_WITHIN_HARD_LIMIT"
const WINDOW_OUT := "OUTSIDE_HARD_LIMIT"

var _cfg: Dictionary = {}
var _score_cfg: Dictionary = {}
var _model = null
var _prog = null
var _error := ""

func _init(config_path: String = DEFAULT_CONFIG_PATH) -> void:
	_cfg = _read_json(config_path)
	if _cfg.get("schema", "") != EXPECTED_SCHEMA or int(_cfg.get("version", 0)) != 1:
		_error = "analysis config missing/unexpected schema: %s" % config_path
		return
	_score_cfg = _read_json(SCORE_MODEL_PATH)
	_model = ChallengeScoreModelV1.new()
	_prog = DifficultyProgressionV1.new()
	if not _model.is_ok() or not _prog.is_ok():
		_error = "score/progression model failed to load"

func is_ok() -> bool:
	return _error.is_empty()

func get_error() -> String:
	return _error

func config() -> Dictionary:
	return _cfg

func default_anchors() -> Dictionary:
	var out := {}
	var a: Dictionary = _cfg.get("anchors", {})
	for k in a:
		out[k] = float(a[k]["value"])
	return out

func provenance() -> Dictionary:
	return {
		"analyzerVersion": String(_cfg.get("analyzerVersion", "")),
		"analysisConfig": DEFAULT_CONFIG_PATH,
		"analysisConfigVersion": int(_cfg.get("version", 0)),
		"calibrationStage": String(_cfg.get("calibrationStage", "")),
		"scoreModelSchema": ChallengeScoreModelV1.EXPECTED_SCHEMA,
		"scoreModelVersion": _model.model_version(),
		"progressionModelSchema": DifficultyProgressionV1.EXPECTED_SCHEMA,
		"progressionModelVersion": int(_read_json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH).get("version", 0)),
		"solver": "res://scripts/gameplay/solver/solvability_solver.gd",
		"kernel": "res://scripts/gameplay/solver/proof_kernel.gd",
		"routing": "res://scripts/gameplay/routing/production_routing_system.gd",
		"access": "res://scripts/gameplay/dispatch/production_target_access.gd",
	}

# =========================================================================== measure ==

## Replay `columns` (0-based legal column placements) from the initial state of
## `level` + `supply_engine` and return raw measurements:
##   {ok, error, color, peel, colorLayers, path, states, routes, placements, timing}
## `expected` (optional) = solver trace records {column, clears, active_after}; any
## divergence from them fails the measurement (determinism / trace binding).
func measure(level, supply_engine, columns: Array, expected: Array = []) -> Dictionary:
	if not is_ok():
		return {"ok": false, "error": _error}
	if not (level is LevelData):
		return {"ok": false, "error": "not LevelData"}
	var t0 := Time.get_ticks_msec()
	var out := {"ok": false, "error": ""}
	out["dims"] = {"width": level.width, "height": level.height}
	out["color"] = color_stats(level)
	var tp := Time.get_ticks_msec()
	out["peel"] = peel_waves(level)
	var peel_ms := Time.get_ticks_msec() - tp
	out["colorLayers"] = color_layer_depth(level)
	var initial = ProofState.from_level_and_supply(level, supply_engine)
	if initial == null:
		out["error"] = "ProofState build failed"
		return out
	var kernel = ProofKernel.new()
	var obs := RouteObserver.new()
	kernel.observer = obs
	var q: Dictionary = kernel.quiesce(initial)
	if not q.get("ok", false):
		out["error"] = "initial quiesce failed"
		return out
	var state = q["state"]
	var states: Array = []
	var placements: Array = []
	var placement_ms: Array = []
	var cells: int = level.get_cell_count()
	for i in range(columns.size()):
		var col: int = int(columns[i])
		var legal: Array = state.legal_action_columns()
		if not legal.has(col):
			out["error"] = "step %d: column %d not legal (legal %s)" % [i, col, str(legal)]
			return out
		states.append(_decision_state(level, kernel, state, cells))
		obs.begin_placement()
		var tk := Time.get_ticks_msec()
		var r: Dictionary = kernel.apply_placement(state, col)
		placement_ms.append(Time.get_ticks_msec() - tk)
		if not r.get("ok", false):
			out["error"] = "step %d: placement failed %s" % [i, str(r.get("error"))]
			return out
		var st = r["state"]
		var rec := {"step": i, "column": col, "color": int(r["placed"]["color"]),
			"robots": int(r["placed"]["count"]), "slot": int(r["placed_slot"]),
			"clears": int(r["clears"]), "activeAfter": st.active_count(),
			"waves": obs.placement_waves, "lastWaveMaxRoute": obs.last_wave_max_len}
		if i < expected.size():
			var e: Dictionary = expected[i]
			if int(e["column"]) != col or int(e["clears"]) != rec["clears"] or int(e["active_after"]) != rec["activeAfter"]:
				out["error"] = "step %d diverged from the expected trace" % i
				return out
		placements.append(rec)
		state = st
	# Chosen-column productivity must agree with the kernel's actual clears.
	var mismatch := 0
	for i in range(states.size()):
		var chosen: bool = false
		for f in states[i]["fronts"]:
			if int(f["column"]) == int(placements[i]["column"]):
				chosen = bool(f["productive"])
		if chosen != (int(placements[i]["clears"]) > 0) and _no_waiting(states[i]):
			mismatch += 1
	out["path"] = {"steps": columns.size(), "solved": state.is_solved(),
		"finalActive": state.active_count(), "totalClears": obs.routes.size(),
		"routeFailures": obs.failures, "productivityMismatches": mismatch,
		"dispatchWaves": obs.total_waves, "maxParallelClaims": obs.max_claims_in_wave}
	out["states"] = states
	out["routes"] = obs.route_summary()
	out["placements"] = placements
	var pm_total := 0
	var pm_max := 0
	for v in placement_ms:
		pm_total += int(v)
		pm_max = maxi(pm_max, int(v))
	out["timing"] = {"totalMs": Time.get_ticks_msec() - t0, "peelMs": peel_ms,
		"kernelPlacementMeanMs": float(pm_total) / maxf(1.0, float(placement_ms.size())),
		"kernelPlacementMaxMs": pm_max, "routeComputeMaxMs": obs.max_route_ms,
		"routeComputeMeanMs": obs.route_ms_total / maxf(1.0, float(obs.routes.size()))}
	out["ok"] = state.is_solved() and obs.failures == 0 and mismatch == 0
	if not out["ok"]:
		out["error"] = "path not solved / route failures %d / productivity mismatches %d" % [obs.failures, mismatch]
	return out

## When an occupied WAITING slot exists, a placement's clears can come from that slot's
## revival rather than the placed batch, so the chosen-column cross-check only applies to
## states with no occupied slot.
func _no_waiting(st: Dictionary) -> bool:
	return (st["occupied"] as Array).is_empty()

## Colour counts, Shannon entropy (nats) and normalized entropy.
static func color_stats(level) -> Dictionary:
	var counts := {}
	for c in level.cells:
		counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var n: int = level.cells.size()
	var h := 0.0
	var keys: Array = counts.keys()
	keys.sort()
	var dist := {}
	for k in keys:
		var p: float = float(counts[k]) / float(n)
		h -= p * log(p)
		dist[String(level.palette[k]).to_upper()] = int(counts[k])
	var m: int = keys.size()
	var hn: float = h / log(float(m)) if m > 1 else 0.0
	return {"usedColors": m, "cells": n, "frequencyByHex": dist, "entropyNats": h,
		"normalizedEntropy": hn}

## Colour-agnostic earliest reachability wave per cell under canonical ACTIVE-blocker /
## CLEARED-open semantics, using the PRODUCTION access truth (ProductionTargetAccess from
## the canonical rightmost-slot origin). Wave k = cells targetable once every wave < k
## cell is CLEARED. Any cell never targetable is a routing/access pathology.
func peel_waves(level) -> Dictionary:
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
	while remaining > 0:
		var access = ProductionTargetAccess.new(routing, raccess, board, origin)
		var hit: Array = []
		for i in range(n):
			if waves[i] == -1 and access.is_targetable(i):
				hit.append(i)
		if hit.is_empty():
			break
		for i in hit:
			waves[i] = wave
			board.set_cell_state(i, BoardState.CellState.CLEARED)
		remaining -= hit.size()
		wave += 1
	var sorted: Array = []
	var hist: Array = []
	hist.resize(wave)
	hist.fill(0)
	var total := 0
	var chars := PackedStringArray()
	for i in range(n):
		var v: int = waves[i]
		chars.append("?" if v < 0 else "0123456789abcdefghijklmnopqrstuvwxyz"[mini(v, 35)])
		if v >= 0:
			sorted.append(v)
			hist[v] += 1
			total += v
	sorted.sort()
	var p95: int = sorted[maxi(0, int(ceil(0.95 * sorted.size())) - 1)] if not sorted.is_empty() else 0
	# Geometric reference: on a fully ACTIVE rectangle the peel should equal the distance
	# to the nearest edge. Recorded as a routing sanity check, not used in scoring.
	var geometric_mismatch := 0
	for i in range(n):
		var x: int = i % w
		var y: int = i / w
		if waves[i] != mini(mini(x, y), mini(w - 1 - x, h - 1 - y)):
			geometric_mismatch += 1
	return {"waveCount": wave, "maxWave": wave - 1, "meanWave": float(total) / maxf(1.0, float(sorted.size())),
		"p95Wave": p95, "initiallyLockedFraction": 1.0 - float(hist[0] if wave > 0 else 0) / float(n),
		"histogram": hist, "unreachableCells": n - sorted.size(),
		"geometricMismatchCells": geometric_mismatch, "perCellWaves": "".join(chars)}

## Topology signature: minimum number of colour regions a path from outside must cross to
## reach each cell (0-1 BFS; entering a cell costs 1 when its colour differs from the
## previous cell, the outside counts as a distinct colour). Pure LevelData, no routing;
## novelty/topology evidence only.
static func color_layer_depth(level) -> Dictionary:
	var w: int = level.width
	var h: int = level.height
	var n: int = w * h
	var dist := PackedInt32Array()
	dist.resize(n)
	dist.fill(1 << 30)
	var dq: Array = []
	for i in range(n):
		var x: int = i % w
		var y: int = i / w
		if x == 0 or y == 0 or x == w - 1 or y == h - 1:
			dist[i] = 1
			dq.append(i)
	# Dial's algorithm with buckets (costs are 0/1) — deterministic.
	var buckets: Array = [dq, []]
	var cur := 1
	while true:
		var bucket: Array = buckets[0]
		if bucket.is_empty():
			if (buckets[1] as Array).is_empty():
				break
			buckets = [buckets[1], []]
			cur += 1
			continue
		var u: int = bucket.pop_back()
		if dist[u] != cur:
			continue
		var ux: int = u % w
		var uy: int = u / w
		for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx: int = ux + d.x
			var ny: int = uy + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var v: int = ny * w + nx
			var cost: int = 0 if level.cells[v] == level.cells[u] else 1
			if dist[u] + cost < dist[v]:
				dist[v] = dist[u] + cost
				(buckets[cost] as Array).append(v)
	var mx := 0
	var tot := 0
	for v in dist:
		mx = maxi(mx, v)
		tot += v
	return {"maxLayers": mx, "meanLayers": float(tot) / float(n)}

## Sample one quiescent decision state with production access truth.
func _decision_state(level, kernel, state, cells: int) -> Dictionary:
	var board = BoardState.from_level_data(level)
	for i in range(state.active.size()):
		if state.active[i] == ProofState.CLEARED_BYTE:
			board.set_cell_state(i, BoardState.CellState.CLEARED)
	var w: int = board.get_width()
	var h: int = board.get_height()
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var place_slot := -1
	for i in range(state.slots.size() - 1, -1, -1):
		if state.slots[i] == null:
			place_slot = i
			break
	var raw_by_color := {}
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) == BoardState.CellState.ACTIVE:
			var c: int = board.get_color_id(i)
			raw_by_color[c] = int(raw_by_color.get(c, 0)) + 1
	var reach_cache := {}
	var fronts: Array = []
	for col in state.legal_action_columns():
		var b: Dictionary = state.supply[col][0]
		var c: int = int(b["color"])
		var reach: int = _reach(board, routing, raccess, kernel, place_slot, w, h, state.capacity, c, reach_cache)
		fronts.append({"column": col, "color": c, "robots": int(b["count"]),
			"raw": int(raw_by_color.get(c, 0)), "reachable": reach, "productive": reach > 0})
	var occupied: Array = []
	for i in range(state.slots.size()):
		var sd = state.slots[i]
		if sd == null:
			continue
		var c: int = int(sd["color"])
		occupied.append({"slot": i, "color": c, "remaining": int(sd["remaining"]),
			"raw": int(raw_by_color.get(c, 0)),
			"reachable": _reach(board, routing, raccess, kernel, i, w, h, state.capacity, c, reach_cache)})
	return {"active": state.active_count(), "progress": 1.0 - float(state.active_count()) / float(cells),
		"placementSlot": place_slot, "fronts": fronts, "occupied": occupied}

func _reach(board, routing, raccess, kernel, slot: int, w: int, h: int, cap: int, color: int, cache: Dictionary) -> int:
	var key := "%d:%d" % [slot, color]
	if cache.has(key):
		return int(cache[key])
	var origin: Vector2 = kernel._origin_for_slot(maxi(slot, 0), w, h, cap)
	var access = ProductionTargetAccess.new(routing, raccess, board, origin)
	var n := 0
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) == BoardState.CellState.ACTIVE and board.get_color_id(i) == color \
				and access.is_targetable(i):
			n += 1
	cache[key] = n
	return n

# ============================================================================= score ==

## Normalize raw measurements into the V1 vector and every derived value. Pure.
func score(raw: Dictionary, level_number: int, anchors: Dictionary = {}) -> Dictionary:
	var a := default_anchors()
	for k in anchors:
		a[k] = float(anchors[k])
	var sc: Dictionary = _score_cfg
	var col: Dictionary = raw["color"]
	var cells: int = int(col["cells"])
	var states: Array = raw["states"]
	var routes: Dictionary = raw["routes"]
	# W / C — locked model functions.
	var W: float = _model.workload_submetric(cells)
	var C: float = _model.color_submetric(int(col["usedColors"]), float(col["normalizedEntropy"]))
	# A — progress-weighted accessibility scarcity.
	var prio: float = float(sc["accessibilityScarcity"]["priorityProgressFraction"])
	var wsum := 0.0
	var asum := 0.0
	var a_samples: Array = []
	for st in states:
		var raw_n := 0
		var reach_n := 0
		var seen := {}
		for f in (st["fronts"] as Array) + (st["occupied"] as Array):
			if seen.has(int(f["color"])):
				continue
			seen[int(f["color"])] = true
			raw_n += int(f["raw"])
			reach_n += int(f["reachable"])
		var at: float = 1.0 - float(reach_n) / float(maxi(raw_n, 1))
		var wt: float = a["accessibilityEarlyWeight"] if float(st["progress"]) < prio else 1.0
		wsum += wt
		asum += wt * at
		a_samples.append({"progress": st["progress"], "raw": raw_n, "reachable": reach_n, "A_t": at, "weight": wt})
	var A: float = asum / wsum if wsum > 0.0 else 0.0
	# U — unlock depth.
	var peel: Dictionary = raw["peel"]
	var ud: Dictionary = sc["unlockDepth"]
	var p95n := _c01(float(peel["p95Wave"]) / a["unlockReferenceWave"])
	var meann := _c01(float(peel["meanWave"]) / a["unlockReferenceWave"])
	var U: float = float(ud["p95Weight"]) * p95n + float(ud["meanWeight"]) * meann \
		+ float(ud["initiallyLockedFractionWeight"]) * _c01(float(peel["initiallyLockedFraction"]))
	# B — bottleneck pressure.
	var bp: Dictionary = sc["bottleneckPressure"]
	var low_thr: int = int(bp["lowChoiceThreshold"])
	var low := 0
	var forced := 0
	var zero := 0
	var streak := 0
	var best := 0
	var alts_total := 0
	var legal_total := 0
	var nonprod_total := 0
	var productive_hist := {}
	for st in states:
		var prod := 0
		var alts := 0
		for f in st["fronts"]:
			legal_total += 1
			if bool(f["productive"]):
				prod += 1
				alts += int(f["reachable"])
			else:
				nonprod_total += 1
		alts_total += alts
		productive_hist[str(prod)] = int(productive_hist.get(str(prod), 0)) + 1
		if prod <= low_thr:
			low += 1
		if prod == 0:
			zero += 1
		if prod == 1:
			forced += 1
			streak += 1
			best = maxi(best, streak)
		else:
			streak = 0
	var nd: int = maxi(states.size(), 1)
	var low_f := float(low) / float(nd)
	var forced_f := float(forced) / float(nd)
	var streak_n := _c01(float(best) / float(nd))
	var B: float = float(bp["lowChoiceFractionWeight"]) * low_f + float(bp["forcedFractionWeight"]) * forced_f \
		+ float(bp["forcedStreakWeight"]) * streak_n
	# R — route complexity.
	var rc: Dictionary = sc["routeComplexity"]
	var dims := _dims(raw)
	var diag: float = sqrt(float(dims.x * dims.x + dims.y * dims.y))
	var len_norm := _c01((float(routes["meanLength"]) / diag) / a["routeLengthReferenceDiagonals"])
	var det_norm := _c01((float(routes["meanDetour"]) - 1.0) / (a["routeDetourReference"] - 1.0))
	var turn_norm := _c01(float(routes["meanTurns"]) / a["routeTurnReference"])
	var R: float = float(rc["averageRouteLengthWeight"]) * len_norm + float(rc["averageDetourWeight"]) * det_norm \
		+ float(rc["averageTurnWeight"]) * turn_norm
	# S — slot / colour pressure.
	var sp: Dictionary = sc["slotColorPressure"]
	var nowork := 0
	var single := 0
	var imb_num := 0.0
	var imb_den := 0.0
	for st in states:
		var stuck := false
		for o in st["occupied"]:
			if int(o["reachable"]) == 0:
				stuck = true
		if stuck:
			nowork += 1
		var prog_colors := {}
		for f in (st["fronts"] as Array) + (st["occupied"] as Array):
			if int(f["reachable"]) > 0:
				prog_colors[int(f["color"])] = true
		if prog_colors.size() == 1:
			single += 1
		for f in st["fronts"]:
			var robots: float = float(f["robots"])
			imb_num += robots * _c01(1.0 - float(f["reachable"]) / robots)
			imb_den += robots
	var nowork_f := float(nowork) / float(nd)
	var single_f := float(single) / float(nd)
	var imb: float = imb_num / imb_den if imb_den > 0.0 else 0.0
	var S: float = float(sp["noWorkSlotFractionWeight"]) * nowork_f + float(sp["singleProductiveSlotFractionWeight"]) * single_f \
		+ float(sp["colorDemandImbalanceWeight"]) * imb
	var vec := {"W": _c01(W), "C": _c01(C), "A": _c01(A), "U": _c01(U), "B": _c01(B), "R": _c01(R), "S": _c01(S)}
	var D: float = _model.challenge_score(vec)
	var target: float = _prog.target_challenge_for(level_number)
	var delta: float = D - target
	# Session Load.
	var rt: Dictionary = _cfg["runtimeConstants"]
	var speed: float = float(rt["botSpeedCellsPerSecond"])
	var cadence: float = float(rt["baseCadenceSeconds"])
	var dispatches: int = int(raw["path"]["totalClears"])
	var route_seconds: float = float(routes["totalLength"]) / speed
	var decisions: int = states.size()
	var duration := 0.0
	for p in raw["placements"]:
		duration += float(p["waves"]) * cadence + float(p["lastWaveMaxRoute"]) / speed
	var load_in := {"actions": _c01(float(dispatches) / a["sessionActionsReference"]),
		"routeTime": _c01(route_seconds / a["sessionRouteTimeReferenceSeconds"]),
		"decisionCount": _c01(float(decisions) / a["sessionDecisionReference"])}
	var session_load: float = _model.session_load(load_in)
	# Frustration Risk — provisional; only choice opacity is supported.
	var nonprod_f := float(nonprod_total) / float(maxi(legal_total, 1))
	var opacity := _c01(0.5 * vec["B"] + 0.5 * nonprod_f)
	var fw: Dictionary = sc["frustrationRisk"]["weights"]
	var frustration := {"status": "PROVISIONAL_STAGE_A", "scalar": null,
		"scalarNote": "No Frustration Risk scalar is claimed: 85% of the V1 weight (retryRisk, sessionOverrun, lateFailure) has no trustworthy supporting simulation or owner budget.",
		"components": {
			"retryRisk": {"status": "UNSUPPORTED", "reason": "no trustworthy simulated-human policy; solver success is not a human first-attempt clear probability"},
			"sessionOverrun": {"status": "UNSUPPORTED", "reason": "no owner-locked per-slot Session Load budget exists"},
			"lateFailure": {"status": "UNSUPPORTED", "reason": "no failing-simulation population exists"},
			"choiceOpacity": {"status": "SUPPORTED_PROXY", "value": opacity,
				"inputs": {"B": vec["B"], "nonProductiveLegalChoiceFraction": nonprod_f}}},
		"supportedLowerBoundContribution": 100.0 * float(fw["choiceOpacity"]) * opacity}
	var window := classify_window(delta)
	return {
		"vector": vec, "vectorOrder": ChallengeScoreModelV1.VECTOR_ORDER,
		"challengeScore": D, "targetChallenge": target, "signedDelta": delta, "absoluteDelta": absf(delta),
		"acceptanceWindow": window, "anchorsUsed": a,
		"supporting": {
			"W": {"activeCells": cells, "dispatches": dispatches, "routeDistanceTotal": routes["totalLength"],
				"cellTransform": "sqrt", "W": vec["W"]},
			"C": {"usedColors": col["usedColors"], "frequencyByHex": col["frequencyByHex"],
				"normalizedEntropy": col["normalizedEntropy"],
				"countNorm": _c01((float(col["usedColors"]) - 3.0) / 9.0), "C": vec["C"]},
			"A": {"samples": a_samples, "priorityProgressFraction": prio, "A": vec["A"]},
			"U": {"meanWave": peel["meanWave"], "p95Wave": peel["p95Wave"], "maxWave": peel["maxWave"],
				"initiallyLockedFraction": peel["initiallyLockedFraction"], "p95Norm": p95n, "meanNorm": meann,
				"U": vec["U"]},
			"B": {"decisionStates": states.size(), "productiveActionHistogram": productive_hist,
				"reachableAlternativesTotal": alts_total, "lowChoiceFraction": low_f, "forcedFraction": forced_f,
				"zeroProductiveStates": zero, "longestForcedStreak": best, "forcedStreakNorm": streak_n, "B": vec["B"]},
			"R": {"meanLength": routes["meanLength"], "boardDiagonal": diag, "meanDetour": routes["meanDetour"],
				"meanTurns": routes["meanTurns"], "lengthVariance": routes["lengthVariance"],
				"lengthNorm": len_norm, "detourNorm": det_norm, "turnNorm": turn_norm, "R": vec["R"]},
			"S": {"noWorkSlotFraction": nowork_f, "singleProductiveSlotFraction": single_f,
				"colorDemandImbalance": imb, "S": vec["S"]},
		},
		"sessionLoad": {"value": session_load, "status": "PROVISIONAL_STAGE_A",
			"actionsNorm": load_in["actions"], "routeTimeNorm": load_in["routeTime"],
			"decisionCountNorm": load_in["decisionCount"], "dispatches": dispatches,
			"routeTravelSeconds": route_seconds, "decisions": decisions,
			"estimatedAttemptSecondsProxy": duration,
			"proxyNote": "kernel wait-for-quiescence timing at 1x; not a calibrated human time"},
		"frustrationRisk": frustration,
		"profile": profile(vec),
	}

func _dims(raw: Dictionary) -> Vector2i:
	return Vector2i(int(raw["dims"]["width"]), int(raw["dims"]["height"]))

## Mechanical acceptance-window classification from level_progression_v1.json.
func classify_window(delta: float) -> String:
	var tol: Dictionary = _read_json(DifficultyProgressionV1.DEFAULT_CONFIG_PATH)["challengeTolerance"]
	var d := absf(delta)
	if d <= float(tol["defaultPlusMinus"]):
		return WINDOW_IN
	if d <= float(tol["neverForceLabelOutsidePlusMinus"]):
		return WINDOW_SOFT
	return WINDOW_OUT

## Dominant analysis profile (doc 09 section 5); sequencing evidence, not a mechanic.
static func profile(v: Dictionary) -> Dictionary:
	var s := {
		"FLOW": 1.0 - (v["A"] + v["U"] + v["B"]) / 3.0,
		"COLOR": (v["C"] + v["S"]) / 2.0,
		"FORTRESS": (v["U"] + v["B"]) / 2.0,
		"ROUTE": (v["R"] + v["A"]) / 2.0,
		"MARATHON": v["W"] - (v["B"] + v["U"]) / 2.0,
	}
	var names: Array = ["FLOW", "COLOR", "FORTRESS", "ROUTE", "MARATHON"]
	names.sort_custom(func(x, y): return s[x] > s[y] or (s[x] == s[y] and x < y))
	var dominant: String = names[0]
	if s[names[0]] - s[names[1]] < 0.05:
		dominant = "BALANCED"
	return {"dominant": dominant, "scores": s, "runnerUp": names[1]}

## Combined similarity between two level records (see config operationalDefinitions).
static func similarity(a: Dictionary, b: Dictionary) -> Dictionary:
	var dv := 0.0
	for k in ChallengeScoreModelV1.VECTOR_ORDER:
		dv += pow(float(a["vector"][k]) - float(b["vector"][k]), 2.0)
	var vec_sim: float = 1.0 - sqrt(dv) / sqrt(7.0)
	var pa: Array = a["palette"]
	var pb: Array = b["palette"]
	var inter := 0
	for c in pa:
		if pb.has(c):
			inter += 1
	var union: int = pa.size() + pb.size() - inter
	var pal_sim: float = float(inter) / float(maxi(union, 1))
	var area_a: float = float(a["width"] * a["height"])
	var area_b: float = float(b["width"] * b["height"])
	var dim_sim: float = 1.0 if (a["width"] == b["width"] and a["height"] == b["height"]) else minf(area_a, area_b) / maxf(area_a, area_b)
	return {"vector": vec_sim, "palette": pal_sim, "dimensions": dim_sim,
		"combined": (vec_sim + pal_sim + dim_sim) / 3.0}

static func _c01(v: float) -> float:
	if is_nan(v) or is_inf(v):
		return 0.0
	return clampf(v, 0.0, 1.0)

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if typeof(d) == TYPE_DICTIONARY else {}

# ==================================================================== route observer ==

## Read-only ProofKernel observer: recomputes each claim's production route from the
## claim's own slot origin on the claim-time board (identical inputs to the selector's
## winning probe) and validates it with RouteValidator. Never mutates the live bundle.
class RouteObserver:
	extends RefCounted
	var routes: Array = []
	var failures := 0
	var total_waves := 0
	var max_claims_in_wave := 0
	var placement_waves := 0
	var last_wave_max_len := 0.0
	var _wave_max_len := 0.0
	var max_route_ms := 0
	var route_ms_total := 0.0

	func begin_placement() -> void:
		placement_waves = 0
		last_wave_max_len = 0.0

	func on_claim(live: Dictionary, slot: int, origin: Vector2, claim: Dictionary) -> void:
		var target: int = int(claim["target"])
		var t0 := Time.get_ticks_msec()
		var req = RouteRequest.for_target(live.board, origin, target)
		var r = live.routing.compute_route(req, live.board, live.raccess)
		var dt := Time.get_ticks_msec() - t0
		max_route_ms = maxi(max_route_ms, dt)
		route_ms_total += float(dt)
		if req == null or RouteValidator.validate_route(req, r, live.board, live.raccess) != RouteResult.FailureReason.NONE:
			failures += 1
			return
		var pts: PackedVector2Array = r.get_points()
		var length := 0.0
		var turns := 0.0
		var prev_dir := Vector2.ZERO
		for i in range(1, pts.size()):
			var seg: Vector2 = pts[i] - pts[i - 1]
			var sl: float = seg.length()
			if sl < 0.000001:
				continue
			length += sl
			var d: Vector2 = seg / sl
			if prev_dir != Vector2.ZERO:
				turns += absf(prev_dir.angle_to(d))
			prev_dir = d
		var center: Vector2 = RouteRequest.center_of_index(live.board, target)
		var straight: float = maxf(origin.distance_to(center), 0.000001)
		routes.append({"slot": slot, "length": length, "straight": straight,
			"detour": length / straight, "turns": turns / (PI / 2.0)})
		_wave_max_len = maxf(_wave_max_len, length)

	func on_wave(_live: Dictionary, _lanes: Array, claims: Array) -> void:
		if claims.is_empty():
			return
		total_waves += 1
		placement_waves += 1
		max_claims_in_wave = maxi(max_claims_in_wave, claims.size())
		last_wave_max_len = _wave_max_len
		_wave_max_len = 0.0

	func route_summary() -> Dictionary:
		var n: int = routes.size()
		var tl := 0.0
		var td := 0.0
		var tt := 0.0
		for r in routes:
			tl += float(r["length"])
			td += float(r["detour"])
			tt += float(r["turns"])
		var mean_len: float = tl / float(maxi(n, 1))
		var var_len := 0.0
		for r in routes:
			var_len += pow(float(r["length"]) - mean_len, 2.0)
		return {"count": n, "totalLength": tl, "meanLength": mean_len,
			"lengthVariance": var_len / float(maxi(n, 1)),
			"meanDetour": td / float(maxi(n, 1)), "meanTurns": tt / float(maxi(n, 1))}
