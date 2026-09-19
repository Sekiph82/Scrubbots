extends RefCounted
## RetryCoordinator — M30 transaction-safe same-puzzle Retry gate (SB-M30-007). Preload this
## script (res://scripts/gameplay/completion/retry_coordinator.gd); do not rely on global
## class_name (AL-001).
##
## Hardens the provisional M29 ProductionGameplayHost.reset_session() into a real Retry path
## (OWNER_WIN_LOSE_RETRY_DECISION_V01 §6). The accepted M26 scheduler teardown is the FIRST
## destructive gameplay teardown gate:
##
##   - preflight the scheduler reset;
##   - if scheduler.reset() fails, is deferred, remains pending, reports a prior failed
##     teardown, or is fatal -> Retry FAILS CLOSED and NOTHING else is reset (no M23 supply,
##     no M24 slots, no BoardState, no speed, no terminal result touched — no half-old /
##     half-new attempt);
##   - only on a proven-clean teardown does it restore ONE coherent fresh attempt, in place,
##     reusing the same bound engine instances so no stale pre-retry callback can reach a new
##     BoardState instance.
##
## The M26 reset itself is transaction-safe and generation-safe (it rolls every live claim
## back all-or-nothing, frees agents, and advances a monotonic generation so stale arrivals
## after Retry match no assignment). This coordinator NEVER weakens it to make retry easier —
## it only reads its return contract.
##
## Static + bundle-driven so the exact same gate runs for the production host and for a
## failure-injection test that supplies a scheduler double whose reset() fails.

## Attempt a transaction-safe Retry over `bundle`. Required keys:
##   scheduler        — M26 AutoDispatchScheduler (reset()/last_reset_succeeded()/
##                       is_reset_pending()/is_fatal())
##   slots            — M24 FiveSlotBatchEngine (reset())
##   supply           — M23 BatchSupplyEngine (reset())
##   board            — BoardState (restore_all_active())
##   candidate_index  — ColorCandidateIndex (rebuild()/is_bound_to()/count_candidates()/get_color_ids())
##   runtime          — ProductionRuntimeController (reset_runtime())
##   input            — ProductionInputController (set_terminal_stopped(false))
##   completion       — CompletionController (reset_attempt())
##   clearing_loop    — CompleteClearingLoop (M20 attempt-observation reset seam, F-M30-V01-003)
## Optional keys:
##   renderer         — BoardRenderer (refresh_all() + is_bound_to(board)); optional
##   on_restored      — Callable invoked after a successful restore (e.g. UI snapshot sync); optional
##
## Returns true iff the FULL restore bundle preflighted, the teardown gate passed AND the
## fresh attempt was fully restored + candidate coherence verified; false (with ZERO side
## effects when the failure is at/ before the gate) otherwise. Never returns true on a failed
## candidate rebuild/coherence verification.
static func attempt(bundle: Dictionary) -> bool:
	var scheduler = bundle.get("scheduler")
	if scheduler == null:
		return false
	# --- PREFLIGHT (before ANY destructive teardown, F-M30-V01-002) ----------------------
	# Validate every required restore collaborator + method + exact-board binding BEFORE the
	# first destructive M26 gate, so a malformed/missing/incoherent restore dependency is
	# discovered while the old attempt is still fully intact (never a half-torn attempt).
	if not _preflight(bundle):
		return false  # nothing mutated, scheduler.reset NOT called
	var board = bundle["board"]
	# --- FIRST destructive gate: M26 scheduler teardown must prove clean in THIS call ---
	if not _scheduler_reset_clean(scheduler):
		return false
	# --- Gate passed: restore ONE coherent fresh attempt (in place) ---------------------
	# M24 slots emptied, M23 supply rebuilt to the EXACT initial candidate (deterministic
	# reset -> same batch ids/colors/counts/order), board repainted fully ACTIVE. Claims/
	# reservations/agents/committed work were already rolled back inside the scheduler teardown.
	bundle["slots"].reset()
	bundle["supply"].reset()
	board.restore_all_active()
	# M20 attempt-scoped observation state (cleared_count / last_outcome) is zeroed ONLY now,
	# after the M26 teardown gate has safely completed (F-M30-V01-003). Historical reset()
	# semantics are untouched.
	bundle["clearing_loop"].reset_attempt_observation()
	# Candidate index rebuild is a REQUIRED postcondition (F-M30-V01-002): a failed rebuild,
	# a lost board binding, or a candidate population that does not reflect the fully ACTIVE
	# board means the fresh attempt is NOT coherent -> never report Retry success.
	if not _rebuild_candidate_coherent(bundle["candidate_index"], board):
		return false
	var renderer = bundle.get("renderer")
	if renderer != null and renderer.has_method("refresh_all"):
		renderer.refresh_all()
	# Runtime back to a live 1x attempt (clears speed 2x, user pause, system suspension AND
	# the M30 terminal stop), input terminal gate cleared, scheduler unpaused, and the
	# terminal result back to PLAYING with a fresh exact-once latch.
	bundle["runtime"].reset_runtime()
	bundle["input"].set_terminal_stopped(false)
	if scheduler.has_method("resume"):
		scheduler.resume()
	bundle["completion"].reset_attempt()
	var on_restored = bundle.get("on_restored")
	if on_restored is Callable and on_restored.is_valid():
		on_restored.call()
	return true

## Preflight the entire restore bundle BEFORE the destructive M26 gate (F-M30-V01-002). Fails
## closed (false, no mutation) on a missing/dead object, a missing required method, a candidate
## index not bound to the exact production board, a supplied renderer not bound to that exact
## board, or a supplied-but-invalid restore callback.
static func _preflight(bundle: Dictionary) -> bool:
	var board = bundle.get("board")
	if not _obj_with(board, ["restore_all_active", "count_cells_by_state"]):
		return false
	if not _obj_with(bundle.get("slots"), ["reset"]):
		return false
	if not _obj_with(bundle.get("supply"), ["reset"]):
		return false
	if not _obj_with(bundle.get("runtime"), ["reset_runtime"]):
		return false
	if not _obj_with(bundle.get("input"), ["set_terminal_stopped"]):
		return false
	if not _obj_with(bundle.get("completion"), ["reset_attempt"]):
		return false
	if not _obj_with(bundle.get("clearing_loop"), ["reset_attempt_observation"]):
		return false
	# Candidate index must exist, expose rebuild()/is_bound_to(), AND currently be bound to the
	# exact production board (so the post-teardown rebuild targets the right board).
	var ci = bundle.get("candidate_index")
	if not _obj_with(ci, ["rebuild", "is_bound_to", "count_candidates", "get_color_ids"]):
		return false
	if not _bool_true(ci.is_bound_to(board)):
		return false
	# Optional renderer: when supplied it must be coherent/bound to the exact board.
	var renderer = bundle.get("renderer")
	if renderer != null:
		if not _obj_with(renderer, ["refresh_all", "is_bound_to"]):
			return false
		if not _bool_true(renderer.is_bound_to(board)):
			return false
	# Optional restore callback: when SUPPLIED (a non-empty Callable) it must be valid. A null
	# or empty Callable() means "no callback" and is fine.
	var on_restored = bundle.get("on_restored")
	if on_restored is Callable and not on_restored.is_null() and not on_restored.is_valid():
		return false
	return true

## Rebuild the candidate index and verify coherence against the restored full-ACTIVE board
## (F-M30-V01-002): rebuild() must succeed, the index must still be bound to the exact board,
## and the total candidate population must equal the board's ACTIVE cell count (every ACTIVE
## cell is a candidate for its own color on a freshly restored board). Never weakens M13
## fail-closed semantics — it only requires them to hold.
static func _rebuild_candidate_coherent(ci, board) -> bool:
	if not _bool_true(ci.rebuild()):
		return false
	if not _bool_true(ci.is_bound_to(board)):
		return false
	var total := 0
	for color in ci.get_color_ids():
		total += ci.count_candidates(color)
	return total == board.count_cells_by_state(0)  # 0 == BoardState.CellState.ACTIVE

static func _obj_with(obj, methods: Array) -> bool:
	if obj == null or typeof(obj) != TYPE_OBJECT:
		return false
	for m in methods:
		if not obj.has_method(m):
			return false
	return true

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true

## The teardown gate. True ONLY when the scheduler proves a clean teardown completed in this
## call: reset() returned true, nothing is left pending/deferred, the recorded outcome is
## success, and no fatal state remains.
static func _scheduler_reset_clean(scheduler) -> bool:
	if not (scheduler.reset() == true):
		return false
	if scheduler.has_method("is_reset_pending") and scheduler.is_reset_pending():
		return false
	if scheduler.has_method("last_reset_succeeded") and not scheduler.last_reset_succeeded():
		return false
	if scheduler.has_method("is_fatal") and scheduler.is_fatal():
		return false
	return true
