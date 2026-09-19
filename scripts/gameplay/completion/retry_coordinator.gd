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
##   candidate_index  — ColorCandidateIndex (rebuild())
##   runtime          — ProductionRuntimeController (reset_runtime())
##   input            — ProductionInputController (set_terminal_stopped(false))
##   completion       — CompletionController (reset_attempt())
## Optional keys:
##   renderer         — BoardRenderer (refresh_all()) to repaint the full original artwork
##   on_restored      — Callable invoked after a successful restore (e.g. UI snapshot sync)
##
## Returns true iff the teardown gate passed AND the fresh attempt was fully restored;
## false (with ZERO restore side effects) when the gate fails closed.
static func attempt(bundle: Dictionary) -> bool:
	var scheduler = bundle.get("scheduler")
	if scheduler == null:
		return false
	# --- FIRST destructive gate: M26 scheduler teardown must prove clean in THIS call ---
	if not _scheduler_reset_clean(scheduler):
		return false
	# --- Gate passed: restore ONE coherent fresh attempt (in place) ---------------------
	# M24 slots emptied, M23 supply rebuilt to the EXACT initial candidate (deterministic
	# reset -> same batch ids/colors/counts/order), board repainted fully ACTIVE, candidate
	# index rebuilt against the restored board. Claims/reservations/agents/committed work
	# were already rolled back inside the scheduler teardown above.
	bundle["slots"].reset()
	bundle["supply"].reset()
	bundle["board"].restore_all_active()
	bundle["candidate_index"].rebuild()
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
