extends RefCounted
## GenerationGate — M27 generation-time acceptance & deterministic retry (SB-M27-016..018).
## Preload this script (res://scripts/gameplay/solver/generation_gate.gd); do not rely on
## global class_name.
##
## Orchestration layer around M23 candidate generation. It NEVER mutates M23's authority
## semantics to make candidates easier (audit §G): it asks the accepted
## BatchSupplyGenerator for a deterministic candidate from a derived attempt seed, proves
## it with the SolvabilitySolver, and accepts the FIRST candidate the solver proves SOLVED.
## DEADLOCK / UNKNOWN_BOUND / malformed candidates are rejected and generation retries with
## the next deterministic attempt seed, up to a configured attempt bound. Exact per-color
## conservation is verified (not assumed) on every candidate. Identical inputs reproduce an
## identical accepted/rejected sequence and identical accepted attempt (SB-M27-018).

const LevelData = preload("res://scripts/data/level_data.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const MALFORMED := &"MALFORMED"
const CONSERVATION_VIOLATION := &"CONSERVATION_VIOLATION"

## Deterministic odd multiplier for attempt-seed derivation (fixed constant; no wall clock,
## no global RNG). derive(base, attempt) is a pure function so reruns are bit-identical.
const _SEED_MULT := 2654435761

var _solver = null

func _init() -> void:
	_solver = SolvabilitySolver.new()

## Deterministic effective attempt seed. Pure function of (base_seed, attempt).
static func derive_seed(base_seed: int, attempt: int) -> int:
	return base_seed + attempt * _SEED_MULT

## Generate + prove + accept. Returns a detached report:
##   {base_seed, column_count, preview_depth, max_attempts, accepted (or null), attempts:[
##     {attempt, effective_seed, outcome, visited, conservation_ok, decisions?, trace_hash?}]}
## accepted (when present): {attempt, effective_seed, engine, trace, trace_hash,
##   trace_summary, visited, decisions}.
func generate_accepted(level, column_count: int, preview_depth: int, base_seed: int,
		max_attempts: int, config: Dictionary = {}) -> Dictionary:
	var report := {"base_seed": base_seed, "column_count": column_count,
		"preview_depth": preview_depth, "max_attempts": max_attempts,
		"accepted": null, "attempts": []}
	if not (level is LevelData) or max_attempts <= 0:
		return report
	var totals := BatchSupplyGenerator.color_totals(level)
	for attempt in range(max_attempts):
		var eff := derive_seed(base_seed, attempt)
		var rec := {"attempt": attempt, "effective_seed": eff, "outcome": MALFORMED,
			"visited": 0, "conservation_ok": false}
		var engine = BatchSupplyGenerator.generate(level, column_count, preview_depth, eff)
		if engine == null:
			report["attempts"].append(rec)
			continue
		rec["conservation_ok"] = _conservation_ok(totals, engine)
		if not rec["conservation_ok"]:
			rec["outcome"] = CONSERVATION_VIOLATION
			report["attempts"].append(rec)
			continue
		var proof = ProofState.from_level_and_supply(level, engine)
		if proof == null:
			report["attempts"].append(rec)
			continue
		var res: Dictionary = _solver.solve(proof, config)
		rec["outcome"] = res["status"]
		rec["visited"] = int(res["visited"])
		if res["status"] == SolvabilitySolver.SOLVED:
			rec["decisions"] = int(res["decisions"])
			rec["trace_hash"] = int(res["trace_hash"])
			report["attempts"].append(rec)
			report["accepted"] = {"attempt": attempt, "effective_seed": eff, "engine": engine,
				"trace": res["trace"], "trace_hash": int(res["trace_hash"]),
				"trace_summary": res["trace_summary"], "visited": int(res["visited"]),
				"decisions": int(res["decisions"])}
			break
		report["attempts"].append(rec)
	return report

## Exact per-color conservation: the generated candidate's total robot_count per color must
## equal the level's per-color logical-cell totals (OWNER_BATCH_GAMEPLAY_CORE_DECISION §4/6).
func _conservation_ok(totals: Dictionary, engine) -> bool:
	var sums: Dictionary = {}
	var dbg: Dictionary = engine.debug_snapshot()
	for col in dbg["columns"]:
		for b in col:
			var c := int(b["color_id"])
			sums[c] = int(sums.get(c, 0)) + int(b["robot_count"])
	if sums.size() != totals.size():
		return false
	for c in totals:
		if int(sums.get(c, -1)) != int(totals[c]):
			return false
	return true
