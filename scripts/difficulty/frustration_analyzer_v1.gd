extends RefCounted
## FrustrationAnalyzerV1 — preload
## (res://scripts/difficulty/frustration_analyzer_v1.gd).
##
## SB-M36-015 Frustration Risk inputs (docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md sections 4-5).
## Offline QA tooling only; no shipping script references it, it never touches saves or telemetry.
##
## HUMAN_BR: a bounded-rational simulated-human dispatch policy (perception mu, slip epsilon,
## softmax tau, Hick-Hyman think time) replayed through the real ProofKernel via the v2
## analyzer's `run_policy` chooser hook. A fixed offline population of three profiles
## (PRIOR_UNCALIBRATED, data/config/frustration_analysis_v1.json) gives retry_risk and
## late_failure; a per-slot Session Load budget (PROXY) gives session_overrun; choice_opacity is
## the v2 ensemble proxy. F uses the frustrationRisk weights of the v2 score model (read only)
## and is labelled PROVISIONAL_SIMULATED_HUMAN. Profiles are never selected per player
## (CLAUDE.md 11.5).
##
## The v2 analyzer instance is injected by the caller (tools/difficulty_playtest.gd, tests).

const CONFIG_PATH := "res://data/config/frustration_analysis_v1.json"
const EXPECTED_SCHEMA := "scrubbots-frustration-analysis/v1"
const ANALYZER_VERSION := "m36-frustration-analyzer/v1"
const F_STATUS := "PROVISIONAL_SIMULATED_HUMAN"
const INPUT_ORDER := ["retryRisk", "sessionOverrun", "lateFailure", "choiceOpacity"]
const WON := "WON"
const LOST := "LOST"
const INCONCLUSIVE := "INCONCLUSIVE"

var _cfg: Dictionary = {}
var _v2 = null
var _weights: Dictionary = {}
var _score_model_path := ""
var _error := ""

func _init(v2_analyzer, config_path: String = CONFIG_PATH) -> void:
	_cfg = _read_json(config_path)
	if _cfg.get("schema", "") != EXPECTED_SCHEMA:
		_error = "frustration config missing/unexpected schema"
		return
	_v2 = v2_analyzer
	if _v2 == null or not _v2.is_ok():
		_error = "v2 analyzer not loaded"
		return
	if int(_cfg["decisionBound"]) != int(_v2.get_script().MAX_DECISIONS):
		_error = "decisionBound differs from the v2 analyzer MAX_DECISIONS"
		return
	_score_model_path = String(_v2.provenance()["scoreModelConfig"])
	_weights = _read_json(_score_model_path)["frustrationRisk"]["weights"]

func is_ok() -> bool:
	return _error.is_empty()

func get_error() -> String:
	return _error

func config() -> Dictionary:
	return _cfg

func weights() -> Dictionary:
	return _weights

func score_model_path() -> String:
	return _score_model_path

## Deterministic seed of one attempt (config seedFormula).
func seed_for(level_id: String, profile: String, run_index: int) -> int:
	return hash("%s|%s|%d|%s" % [level_id, profile, run_index, str(int(_cfg["version"]))])

## Session Load budget of a cadence slot 1..10 (PROXY); -1 when unknown.
func budget_for_slot(slot: int) -> float:
	var by: Dictionary = _cfg["sessionLoadBudget"]["bySlot"]
	return float(by[str(slot)]) if by.has(str(slot)) else -1.0

## clamp((SL - budget) / budget, 0, 1); null when the Session Load or the slot budget is missing.
func session_overrun(session_load, slot: int):
	var b := budget_for_slot(slot)
	if session_load == null or b <= 0.0 or not is_finite(float(session_load)):
		return null
	return clampf((float(session_load) - b) / b, 0.0, 1.0)

# ============================================================================ attempt ==

## One HUMAN_BR decision maker; `choose` is the v2 run_policy chooser hook.
class HumanBR:
	extends RefCounted
	var rng := RandomNumberGenerator.new()
	var tau := 0.0
	var epsilon := 0.0
	var mu := 0.0
	var t0 := 0.0
	var t1 := 0.0
	var think_seconds := 0.0

	func _init(params: Dictionary, seed_value: int) -> void:
		rng.seed = seed_value
		tau = float(params["tau"])
		epsilon = float(params["epsilon"])
		mu = float(params["mu"])
		t0 = float(params.get("t0", 0.0))
		t1 = float(params.get("t1", 0.0))

	func choose(st: Dictionary, _last: int, _ncols: int) -> int:
		var fronts: Array = st["fronts"]
		think_seconds += t0 + t1 * log(1.0 + float(fronts.size())) / log(2.0)
		# Perception draw per legal front, in column order.
		var perceived := {}
		for f in fronts:
			perceived[int(f["column"])] = int(f["raw"]) if rng.randf() < mu else int(f["reachable"])
		var pool: Array = []
		for f in fronts:
			if bool(f["productive"]):
				pool.append(f)
		if pool.is_empty():
			pool = fronts
		if rng.randf() < epsilon:
			return int(fronts[rng.randi_range(0, fronts.size() - 1)]["column"])
		var util: Array = []
		for f in pool:
			util.append(minf(float(perceived[int(f["column"])]), float(f["robots"])) / float(f["robots"]))
		if tau <= 0.0:
			# Argmax on [utility, reachable], ties to the lowest column (= ACCESS when mu = 0).
			var bi := 0
			for k in range(1, pool.size()):
				if util[k] > util[bi] or (util[k] == util[bi] and int(pool[k]["reachable"]) > int(pool[bi]["reachable"])):
					bi = k
			return int(pool[bi]["column"])
		var umax: float = util.max()
		var w: Array = []
		var tot := 0.0
		for u in util:
			var e := exp((float(u) - umax) / tau)
			w.append(e)
			tot += e
		var r := rng.randf() * tot
		for k in range(pool.size()):
			r -= float(w[k])
			if r < 0.0:
				return int(pool[k]["column"])
		return int(pool[pool.size() - 1]["column"])

## One simulated attempt through the real ProofKernel. `params` = {tau, epsilon, mu, t0, t1}.
func run_attempt(level, engine, level_id: String, profile: String, params: Dictionary, run_index: int) -> Dictionary:
	var seed_value := seed_for(level_id, profile, run_index)
	var h := HumanBR.new(params, seed_value)
	var r: Dictionary = _v2.run_policy(level, engine, "HUMAN_BR", [], h.choose)
	var cols: Array = []
	for p in r["placements"]:
		cols.append(int(p["column"]))
	var dead := 0
	var waits := 0
	for st in r["states"]:
		for f in st["fronts"]:
			if int(f["column"]) == int(st["chosen"]) and not bool(f["productive"]):
				dead += 1
		var occ: Array = st["occupied"]
		var all_zero := not occ.is_empty()
		for o in occ:
			all_zero = all_zero and int(o["reachable"]) == 0
		if all_zero:
			waits += 1
	var outcome := INCONCLUSIVE
	if bool(r["completed"]):
		outcome = WON
	elif String(r["stopReason"]) == "no_legal_placement":
		outcome = LOST
	var route_s: float = float(r["routes"]["totalLength"]) / float(_cfg["botSpeedCellsPerSecond"])
	return {"runIndex": run_index, "seed": seed_value, "outcome": outcome, "stopReason": r["stopReason"],
		"finalProgress": float(r["finalProgress"]), "decisions": int(r["decisions"]),
		"placementHash": str(cols).hash(), "columns": cols, "deadPlacements": dead, "noTargetWaits": waits,
		"thinkSeconds": h.think_seconds, "attemptSecondsProxy": h.think_seconds + route_s}

# ========================================================================= aggregate ==

## Pure aggregate of one profile's attempt list (crafted lists allowed; no engine).
func aggregate_attempts(attempts: Array) -> Dictionary:
	var late_thr: float = float(_cfg["lateFailureProgressGreaterThan"])
	var near_thr: float = float(_cfg["nearMissProgressAtLeast"])
	var won := 0
	var lost := 0
	var inc := 0
	var late := 0
	var near := 0
	var dead := 0
	var waits := 0
	var decisions := 0
	var secs: Array = []
	for a in attempts:
		match String(a["outcome"]):
			WON:
				won += 1
			LOST:
				lost += 1
				if float(a["finalProgress"]) > late_thr:
					late += 1
				if float(a["finalProgress"]) >= near_thr:
					near += 1
			_:
				inc += 1
		dead += int(a.get("deadPlacements", 0))
		waits += int(a.get("noTargetWaits", 0))
		decisions += int(a.get("decisions", 0))
		secs.append(float(a.get("attemptSecondsProxy", 0.0)))
	var n := won + lost
	var cr = float(won) / float(n) if n > 0 else null
	return {"attempts": attempts.size(), "won": won, "lost": lost, "inconclusive": inc,
		"clearRate": cr, "clearRateWilson95": wilson95(won, n),
		"lateFailure": float(late) / float(lost) if lost > 0 else 0.0, "lateFailureLostCount": lost,
		"nearMiss": float(near) / float(lost) if lost > 0 else 0.0,
		"deadPlacementsPerAttempt": float(dead) / float(maxi(attempts.size(), 1)),
		"noTargetWaitFraction": float(waits) / float(maxi(decisions, 1)),
		"attemptSecondsProxy": _median(secs)}

## Wilson 95% score interval of k successes in n trials; null when n = 0.
static func wilson95(k: int, n: int):
	if n <= 0:
		return null
	var z := 1.96
	var p := float(k) / float(n)
	var den := 1.0 + z * z / float(n)
	var mid := (p + z * z / (2.0 * float(n))) / den
	var half := z * sqrt(p * (1.0 - p) / float(n) + z * z / (4.0 * float(n) * float(n))) / den
	return [clampf(mid - half, 0.0, 1.0), clampf(mid + half, 0.0, 1.0)]

const WEIGHTED_KEYS := ["clearRate", "lateFailure", "nearMiss", "deadPlacementsPerAttempt",
	"noTargetWaitFraction", "attemptSecondsProxy"]

## Population-weighted values over profiles with a clear rate (profile weights renormalized).
func population(per_profile: Dictionary) -> Dictionary:
	var wsum := 0.0
	for name in per_profile:
		if per_profile[name]["clearRate"] != null:
			wsum += float(_cfg["profiles"][name]["weight"])
	var out := {}
	for k in WEIGHTED_KEYS:
		out[k] = null
		if wsum <= 0.0:
			continue
		var v := 0.0
		for name in per_profile:
			if per_profile[name]["clearRate"] != null:
				v += float(_cfg["profiles"][name]["weight"]) / wsum * float(per_profile[name][k])
		out[k] = v
	var cr = out["clearRate"]
	out["retryRisk"] = 1.0 - float(cr) if cr != null else null
	out["expectedAttemptsPerClear"] = 1.0 / float(cr) if cr != null and float(cr) > 0.0 else null
	out["heartsPerClear"] = 1.0 / float(cr) - 1.0 if cr != null and float(cr) > 0.0 else null
	out["pOutOfHeartsBeforeClear"] = pow(1.0 - float(cr), float(_cfg["heartsMax"])) if cr != null else null
	out["profileWeightSum"] = wsum
	return out

## F = 100 * sum(w * input) with v2 score-model weights; null naming the first missing input.
func f_score(inputs: Dictionary) -> Dictionary:
	var f := 0.0
	for k in INPUT_ORDER:
		var v = inputs.get(k, null)
		if v == null or not (typeof(v) in [TYPE_FLOAT, TYPE_INT]) or not is_finite(float(v)):
			return {"F": null, "status": F_STATUS, "missingInput": k}
		f += float(_weights[k]) * float(v)
	return {"F": 100.0 * f, "status": F_STATUS, "missingInput": null}

# ========================================================================== analyze ==

## Full HUMAN_BR population run of one level. `make_engine` returns a fresh supply engine.
## `session_load` and `choice_opacity` come from the v2 score of the same level; `slot` is the
## cadence slot 1..10. `runs` < 0 uses the config runsPerProfile; `profiles` empty = all.
func analyze(level, make_engine: Callable, level_id: String, slot: int, session_load, choice_opacity,
		runs: int = -1, profiles: Array = []) -> Dictionary:
	var n_runs: int = runs if runs >= 0 else int(_cfg["runsPerProfile"])
	var names: Array = profiles if not profiles.is_empty() else _cfg["profileOrder"]
	var per := {}
	var detail := {}
	for name in names:
		var attempts: Array = []
		for ri in range(n_runs):
			var a := run_attempt(level, make_engine.call(), level_id, name, _cfg["profiles"][name], ri)
			a.erase("columns")
			attempts.append(a)
		per[name] = aggregate_attempts(attempts)
		detail[name] = attempts
	var pop := population(per)
	var inputs := {"retryRisk": pop["retryRisk"], "sessionOverrun": session_overrun(session_load, slot),
		"lateFailure": pop["lateFailure"], "choiceOpacity": choice_opacity}
	var f := f_score(inputs)
	return {"analyzerVersion": ANALYZER_VERSION, "config": CONFIG_PATH, "configVersion": int(_cfg["version"]),
		"scoreModelConfig": _score_model_path, "weights": _weights, "status": _cfg["status"],
		"levelId": level_id, "slot": slot, "runsPerProfile": n_runs, "profiles": names,
		"sessionLoad": session_load, "sessionLoadBudget": budget_for_slot(slot),
		"perProfile": per, "population": pop, "inputs": inputs,
		"F": f["F"], "FStatus": f["status"], "missingInput": f["missingInput"], "attempts": detail}

## Deterministic serialization (sorted keys).
static func to_json(result: Dictionary) -> String:
	return JSON.stringify(result, "\t", true) + "\n"

static func _median(vals: Array) -> float:
	var v := vals.duplicate()
	v.sort()
	var n: int = v.size()
	if n == 0:
		return 0.0
	return v[n / 2] if n % 2 == 1 else 0.5 * (v[n / 2 - 1] + v[n / 2])

static func _read_json(path: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}
