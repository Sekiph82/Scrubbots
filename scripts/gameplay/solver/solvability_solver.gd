extends RefCounted
## SolvabilitySolver — M27 deterministic legal-choice search (SB-M27-013..015, 019, 020).
## Preload this script (res://scripts/gameplay/solver/solvability_solver.gd); do not rely
## on global class_name.
##
## Branches over LEGAL player front-batch selections only (never Row2/Row3/hidden batches,
## never an internal reachability shortcut) using the ProofKernel to apply each transition
## through the accepted M23/M24/M25/routing semantics. Player placement is the ONLY choice
## point: per-slot parallel dispatch waves, target selection and clearing are all
## forced/deterministic inside the kernel (M52-C001-R01 wave kernel; see ProofKernel for the
## exact proof/runtime timing relationship), and clearing is monotonic, so exhaustively
## branching over which column front to place next is a complete search of player choices.
##
## Deterministic DFS: ascending column action order, canonical-state memoization, explicit
## max-visited-states and max-depth bounds. SOLVED only at exact canonical completion.
## Bound exhaustion => UNKNOWN_BOUND (never DEADLOCK). Full exhaustion with no success =>
## DEADLOCK (proven no legal future completion/progress within the reachable state space).
## A deterministic replayable solution trace is emitted for SOLVED.

const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")

# Stable result statuses / reason codes (deterministic, UI-agnostic).
const SOLVED := &"SOLVED"
const DEADLOCK := &"DEADLOCK"
const UNKNOWN_BOUND := &"UNKNOWN_BOUND"
const PROGRESS_FOUND := &"PROGRESS_FOUND"

# Search goals.
const GOAL_SOLVE := &"solve"        # success == exact canonical completion
const GOAL_PROGRESS := &"progress"  # success == any authenticated clear vs the root

# Default deterministic bounds (state-count/depth are authoritative for tests/replays;
# no wall-clock affects classification). Callers may override per search.
const DEFAULT_MAX_VISITED := 200000
const DEFAULT_MAX_DEPTH := 400

var _kernel = null
## M46 RM005 oracle switch (tests only): true restores the pre-RM005 progress search — a full
## dispatch cascade for every child and a second root quiesce. Same verdict and counters.
var full_progress_cascade := false

func _init() -> void:
	_kernel = ProofKernel.new()

## Prove generation-time solvability of `initial_state`. Returns a detached result dict:
##   {status, visited, memo_hits, frontier_peak, max_depth_reached, decisions,
##    root_active, reason, trace, trace_hash, trace_summary}
## trace/trace_hash present only for SOLVED.
func solve(initial_state, config: Dictionary = {}) -> Dictionary:
	return _search(initial_state, GOAL_SOLVE, config)

## Progress search for the runtime classifier: is ANY legal future authenticated clear
## reachable from `root_state`? Returns the same shape with status in
## {PROGRESS_FOUND, DEADLOCK, UNKNOWN_BOUND}.
## `root_quiescent`: the caller already quiesced `root_state` with zero clears (the classifier),
## so the root quiesce here would rebuild the same engines to read back the same state.
func search_progress(root_state, config: Dictionary = {}, root_quiescent: bool = false) -> Dictionary:
	return _search(root_state, GOAL_PROGRESS, config, root_quiescent and not full_progress_cascade)

## M46 R06: stop this solver's searches for good (an off-frame booster proof being cancelled
## from the main thread). Every later search returns UNKNOWN_BOUND time_budget_exhausted.
func cancel() -> void:
	_kernel.cancelled = true

func _search(input_state, goal: StringName, config: Dictionary, root_quiescent: bool = false) -> Dictionary:
	# The kernel shares the cutoff for exactly this search (a single placement can run a whole
	# dispatch-to-quiescence cascade), and never keeps it afterwards.
	_kernel.deadline_usec = int(config.get("deadline_usec", 0))
	var r := _search_bounded(input_state, goal, config, root_quiescent)
	_kernel.deadline_usec = 0
	return r

func _search_bounded(input_state, goal: StringName, config: Dictionary, root_quiescent: bool = false) -> Dictionary:
	var max_visited: int = int(config.get("max_visited", DEFAULT_MAX_VISITED))
	var max_depth: int = int(config.get("max_depth", DEFAULT_MAX_DEPTH))
	# Optional wall-clock cutoff (M46, owner 2026-10-16): only the runtime booster safety proofs
	# pass it, so a player action can never freeze the game. Absent (the default, generation and
	# every deterministic test/replay path) = no wall-clock influence at all. Hitting it is an
	# UNKNOWN_BOUND, never a DEADLOCK, so callers fail closed without claiming anything.
	# (_search set it on the kernel; read through _kernel._out_of_time() so an R06 cancel lands.)
	# Normalize the root to a quiescent state (apply any immediately-claimable clears)
	# through the real kernel, so the search space is exactly quiescent decision points.
	var q: Dictionary = {"ok": true, "state": input_state} if root_quiescent else _kernel.quiesce(input_state)
	if not q.get("ok", false):
		var why := "time_budget_exhausted" if q.get("error", "") == "time_budget_exhausted" else "kernel_build_failed"
		return {"status": UNKNOWN_BOUND, "reason": why, "visited": 0,
			"memo_hits": 0, "frontier_peak": 0, "max_depth_reached": 0, "decisions": 0,
			"root_active": -1}
	var root = q["state"]
	# M46 RM005 (progress search only, same verdict and counters):
	#  - children are DEFERRED: pushed as {parent, actions, column} in the same order and
	#    placed only when popped, so siblings behind a PROGRESS_FOUND are never built. A
	#    placement the real M24 transaction rejects is then skipped at its pop instead of at
	#    the parent's expansion; that can only differ in frontier_peak / a max_visited edge for
	#    malformed or incoherent states (never a DEADLOCK: the verdict order is unchanged);
	#  - a child that clears anything is popped as PROGRESS_FOUND before it is ever expanded or
	#    memo-compared (its board is below root_active, so its key can never be in `visited`),
	#    and the progress result carries no trace, so its cascade stops at the first clearing
	#    wave. 0-clear children are quiescent after that same single wave either way.
	var probe: bool = goal == GOAL_PROGRESS and not full_progress_cascade
	var root_active: int = root.active_count()
	var visited: Dictionary = {}
	var memo_hits := 0
	var frontier_peak := 0
	var max_depth_reached := 0
	var bound_hit := false
	# Stack entries: {"state":ProofState, "actions":Array}. actions is the ordered legal
	# player selection trace to reach this state.
	var stack: Array = [{"state": root, "actions": []}]
	while not stack.is_empty():
		frontier_peak = maxi(frontier_peak, stack.size())
		if visited.size() >= max_visited:
			return _result(UNKNOWN_BOUND, "max_visited_exhausted", visited.size(), memo_hits,
				frontier_peak, max_depth_reached, root_active, [])
		if _kernel._out_of_time():
			return _result(UNKNOWN_BOUND, "time_budget_exhausted", visited.size(), memo_hits,
				frontier_peak, max_depth_reached, root_active, [])
		var node: Dictionary = stack.pop_back()
		if node.has("column"):
			var rp: Dictionary = _kernel.apply_placement(node["parent"], node["column"], true)
			if not rp.get("ok", false):
				if rp.get("error", "") == "time_budget_exhausted":
					return _result(UNKNOWN_BOUND, "time_budget_exhausted", visited.size(), memo_hits,
						frontier_peak, max_depth_reached, root_active, [])
				continue
			node = {"state": rp["state"], "actions": node["actions"] + [{"column": node["column"],
				"placed": rp["placed"], "clears": int(rp["clears"]), "active_after": rp["state"].active_count()}]}
		var state = node["state"]
		var actions: Array = node["actions"]
		var key: String = state.canonical_key()
		if visited.has(key):
			memo_hits += 1
			continue
		visited[key] = true
		max_depth_reached = maxi(max_depth_reached, actions.size())
		if goal == GOAL_SOLVE and state.is_solved():
			return _result(SOLVED, "complete", visited.size(), memo_hits, frontier_peak,
				max_depth_reached, root_active, actions)
		if goal == GOAL_PROGRESS and state.active_count() < root_active:
			return _result(PROGRESS_FOUND, "progress", visited.size(), memo_hits,
				frontier_peak, max_depth_reached, root_active, actions)
		if actions.size() >= max_depth:
			bound_hit = true
			continue
		# Expand legal player front selections in ascending column order. Push reversed so
		# the ascending order is explored first (deterministic DFS).
		var cols: Array = state.legal_action_columns()
		if probe:
			for i in range(cols.size() - 1, -1, -1):
				stack.push_back({"parent": state, "actions": actions, "column": cols[i]})
			continue
		var children: Array = []
		for c in cols:
			if _kernel._out_of_time():
				return _result(UNKNOWN_BOUND, "time_budget_exhausted", visited.size(), memo_hits,
					frontier_peak, max_depth_reached, root_active, [])
			var r: Dictionary = _kernel.apply_placement(state, c)
			if not r.get("ok", false):
				if r.get("error", "") == "time_budget_exhausted":
					return _result(UNKNOWN_BOUND, "time_budget_exhausted", visited.size(), memo_hits,
						frontier_peak, max_depth_reached, root_active, [])
				continue
			var child = r["state"]
			var rec := {"column": c, "placed": r["placed"], "clears": int(r["clears"]),
				"active_after": child.active_count()}
			children.append({"state": child, "actions": actions + [rec]})
		for i in range(children.size() - 1, -1, -1):
			stack.push_back(children[i])
	# Frontier fully exhausted within bounds.
	if bound_hit:
		return _result(UNKNOWN_BOUND, "depth_bound_exhausted", visited.size(), memo_hits,
			frontier_peak, max_depth_reached, root_active, [])
	return _result(DEADLOCK, "no_legal_future_completion" if goal == GOAL_SOLVE
			else "no_legal_future_progress",
		visited.size(), memo_hits, frontier_peak, max_depth_reached, root_active, [])

func _result(status: StringName, reason: String, visited: int, memo_hits: int,
		frontier_peak: int, max_depth_reached: int, root_active: int, actions: Array) -> Dictionary:
	var out := {"status": status, "reason": reason, "visited": visited, "memo_hits": memo_hits,
		"frontier_peak": frontier_peak, "max_depth_reached": max_depth_reached,
		"decisions": actions.size(), "root_active": root_active}
	if status == SOLVED:
		out["trace"] = actions
		out["trace_summary"] = _trace_summary(actions)
		out["trace_hash"] = _trace_hash(actions)
	return out

# ------------------------------------------------------------- trace utils -----

## Deterministic compact summary of a solution trace: the ordered legal player selections
## with the placed batch and per-step clears. Debug/QA only — never a player-facing API.
static func _trace_summary(actions: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for a in actions:
		parts.append("c%d:C%d#%d/%dclr" % [int(a["column"]), int(a["placed"]["color"]),
			int(a["placed"]["count"]), int(a["clears"])])
	return "|".join(parts)

## Stable 32-bit hash of the deterministic trace summary (Godot String.hash is stable).
static func _trace_hash(actions: Array) -> int:
	return _trace_summary(actions).hash()

## Replay a SOLVED trace against a fresh initial ProofState and reproduce completion.
## Returns {ok, solved, final_active, steps, diverged_at}. Deterministic: identical level/
## supply/trace reproduce identical completion (audit §F).
func replay(initial_state, trace: Array) -> Dictionary:
	var q: Dictionary = _kernel.quiesce(initial_state)
	if not q.get("ok", false):
		return {"ok": false, "solved": false, "final_active": -1, "steps": 0, "diverged_at": -1}
	var state = q["state"]
	var step := 0
	for a in trace:
		var col: int = int(a["column"])
		var r: Dictionary = _kernel.apply_placement(state, col)
		if not r.get("ok", false):
			return {"ok": false, "solved": false, "final_active": state.active_count(),
				"steps": step, "diverged_at": step}
		# The replayed step must match the recorded per-step clears/active (determinism).
		if int(r["clears"]) != int(a["clears"]) or r["state"].active_count() != int(a["active_after"]):
			return {"ok": false, "solved": false, "final_active": r["state"].active_count(),
				"steps": step, "diverged_at": step}
		state = r["state"]
		step += 1
	return {"ok": true, "solved": state.is_solved(), "final_active": state.active_count(),
		"steps": step, "diverged_at": -1}

# ----------------------------------------------------- greedy (non-branching) --

## Deterministic GREEDY driver: always place the first legal column front, never
## backtrack. Used ONLY to demonstrate that a naive fixed order can fail where the real
## branching search succeeds (audit §E / WP02 "greedy-first fails but alternate solves").
func solve_greedy(initial_state) -> Dictionary:
	var q: Dictionary = _kernel.quiesce(initial_state)
	if not q.get("ok", false):
		return {"solved": false, "steps": 0, "active": -1}
	var state = q["state"]
	var steps := 0
	var guard := DEFAULT_MAX_DEPTH
	while guard > 0 and not state.is_solved():
		guard -= 1
		var cols: Array = state.legal_action_columns()
		if cols.is_empty():
			break
		var r: Dictionary = _kernel.apply_placement(state, cols[0])
		if not r.get("ok", false):
			break
		state = r["state"]
		steps += 1
	return {"solved": state.is_solved(), "steps": steps, "active": state.active_count()}
