extends RefCounted
## DeadlockClassifier — M27 read-only runtime classifier (SB-M27-025..033). Preload this
## script (res://scripts/gameplay/solver/deadlock_classifier.gd); do not rely on global
## class_name.
##
## Read-only classification over current gameplay-domain state with NO UI/lose-screen
## coupling (audit §H). It never mutates the runtime; it reconstructs a detached ProofState
## and reasons with the same ProofKernel/SolvabilitySolver used at generation time, so
## classification is deterministic and identical on reset/replay (SB-M27-033).
##
## Statuses (stable, deterministic reason codes):
##  - COMPLETED     : board fully cleared, nothing left.
##  - PROGRESSABLE  : immediate authenticated progress exists (live M26 in-flight OR a
##                    currently claimable target).
##  - STALLED       : no immediate progress, but a legal future front-batch placement
##                    sequence can produce authenticated progress (temporarily waiting).
##  - DEADLOCK      : PROVEN no legal future action sequence can produce further progress.
##  - UNKNOWN_BOUND : proof bounds exhausted before a verdict (NEVER reported as DEADLOCK).
##
## Never DEADLOCK while: M26 has a valid in-flight assignment; immediate claimable work
## exists; an empty slot + a legal supply front can lead to progress; a WAITING target can
## open from legal scheduled clearing; or the bounded search returns UNKNOWN_BOUND.

const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const COMPLETED := &"COMPLETED"
const PROGRESSABLE := &"PROGRESSABLE"
const STALLED := &"STALLED"
const DEADLOCK := &"DEADLOCK"
const UNKNOWN_BOUND := &"UNKNOWN_BOUND"

var _kernel = null
var _solver = null

func _init() -> void:
	_kernel = ProofKernel.new()
	_solver = SolvabilitySolver.new()

## Classify a detached ProofState plus the current M26 in-flight assignment count.
## `inflight_count` > 0 short-circuits to PROGRESSABLE without any search (a valid in-flight
## robot can still reach an authenticated clear). Returns a detached result dict:
##   {status, reason, visited, memo_hits, frontier_peak, max_depth_reached, decisions,
##    immediate_clears, root_active}
func classify(state, inflight_count: int = 0, config: Dictionary = {}) -> Dictionary:
	if inflight_count > 0:
		return {"status": PROGRESSABLE, "reason": "m26_inflight_progress", "visited": 0,
			"memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0, "decisions": 0,
			"immediate_clears": 0, "root_active": -1}
	# Quiesce the current state: any immediately-claimable target clears here.
	var q: Dictionary = _kernel.quiesce(state)
	if not q.get("ok", false):
		return {"status": UNKNOWN_BOUND, "reason": "kernel_build_failed", "visited": 0,
			"memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0, "decisions": 0,
			"immediate_clears": 0, "root_active": -1}
	var immediate_clears: int = int(q["clears"])
	var s1 = q["state"]
	var root_active: int = s1.active_count()
	if immediate_clears > 0:
		# Immediate authenticated progress was available -> never deadlock.
		return {"status": PROGRESSABLE, "reason": "immediate_claimable_work",
			"visited": 0, "memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0,
			"decisions": 0, "immediate_clears": immediate_clears, "root_active": root_active}
	if s1.is_solved():
		return {"status": COMPLETED, "reason": "board_fully_cleared", "visited": 0,
			"memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0, "decisions": 0,
			"immediate_clears": 0, "root_active": root_active}
	# No immediate progress. Search whether ANY legal future placement sequence unlocks a
	# clear. STALLED (recoverable) vs DEADLOCK (proven) vs UNKNOWN_BOUND (bounded out).
	var r: Dictionary = _solver.search_progress(s1, config)
	var status: StringName = DEADLOCK
	var reason: String = r.get("reason", "")
	match r["status"]:
		SolvabilitySolver.PROGRESS_FOUND:
			status = STALLED
			reason = "legal_future_placement_unlocks_progress"
		SolvabilitySolver.UNKNOWN_BOUND:
			status = UNKNOWN_BOUND
		SolvabilitySolver.DEADLOCK:
			status = DEADLOCK
			reason = "no_legal_future_progress_proven"
	return {"status": status, "reason": reason, "visited": int(r["visited"]),
		"memo_hits": int(r["memo_hits"]), "frontier_peak": int(r["frontier_peak"]),
		"max_depth_reached": int(r["max_depth_reached"]), "decisions": int(r["decisions"]),
		"immediate_clears": 0, "root_active": root_active}

## Convenience: classify directly from live runtime engines.
func classify_runtime(level, board, supply_engine, slots_engine, inflight_count: int = 0,
		config: Dictionary = {}) -> Dictionary:
	var state = ProofState.from_runtime(level, board, supply_engine, slots_engine)
	if state == null:
		return {"status": UNKNOWN_BOUND, "reason": "runtime_reconstruct_failed", "visited": 0,
			"memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0, "decisions": 0,
			"immediate_clears": 0, "root_active": -1}
	return classify(state, inflight_count, config)
