extends RefCounted
## CompletionEvaluator — M30 read-only gameplay-domain completion truth (SB-M30-001..004).
## Preload this script (res://scripts/gameplay/completion/completion_evaluator.gd); do not
## rely on global class_name (AL-001).
##
## PURE read-only. It never mutates any engine and owns NO win/lose POLICY latch — that is
## the CompletionController's job. It only reports the current terminal truth of one attempt
## from the accepted M20/M23-M27 engines, using:
##   - BoardState ACTIVE count (M14);
##   - M26 AutoDispatchScheduler live assignment count + fatal flag;
##   - ScrubbotDispatcher live agent count (M19);
##   - M25 BatchTargetClaimEngine live claim count;
##   - ReservationState reservation count;
##   - M24 FiveSlotBatchEngine live committed-work count;
##   - the REAL M27 DeadlockClassifier over live runtime state.
##
## Owner rules (OWNER_WIN_LOSE_RETRY_DECISION_V01):
##   WON  — board fully cleared AND every in-flight/transaction authority is quiescent AND
##          no pending authenticated-clear transaction remains.
##   LOST — gameplay quiescent (no live in-flight progress) AND the real M27 classifier
##          proves DEADLOCK. Never on WAITING/STALLED/PROGRESSABLE/UNKNOWN_BOUND, supply or
##          slot fullness alone, a temporary no-target state, or a live in-flight Scrubbot.
##   ERROR — cross-engine inconsistency / M26 fatal bookkeeping: fail closed, NOT a LOSE.
##   PLAYING — anything else (nonterminal).
##
## The expensive M27 proof is invoked ONLY at a quiescent boundary with no live in-flight
## work that already guarantees possible progress — the CompletionController additionally
## dirty/event-gates it so idle frames never re-run it (audit §G).

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const DeadlockClassifier = preload("res://scripts/gameplay/solver/deadlock_classifier.gd")

const PLAYING := &"PLAYING"
const WON := &"WON"
const LOST := &"LOST"
const ERROR := &"ERROR"

var _classifier = null

## `classifier` defaults to the REAL M27 DeadlockClassifier (no duplicated solver logic in
## M30). The optional injection seam exists ONLY so the evaluator's terminal-mapping policy
## (only DEADLOCK -> LOST; every other status -> nonterminal) can be proven in isolation and
## so a future owner-approved classifier can be swapped in — production always uses the real
## M27 classifier.
func _init(classifier = null) -> void:
	_classifier = classifier if classifier != null else DeadlockClassifier.new()

func get_classifier():
	return _classifier

## True exactly when every accepted authority is fully quiescent: no scheduler assignment,
## no live dispatcher agent, no live M25 claim, no reservation, no live M24 committed work.
## This is the shared precondition for a WIN latch and for even attempting a LOSE proof —
## no legitimate in-flight work may be discarded to reach a result.
func is_quiescent(scheduler, dispatcher, claim, reservations, slots) -> bool:
	if scheduler.live_assignment_count() != 0:
		return false
	if dispatcher.get_active_count() != 0:
		return false
	if claim.live_claim_count() != 0:
		return false
	if reservations.get_reservation_count() != 0:
		return false
	if slots.live_work_count() != 0:
		return false
	return true

## The five live production transaction cardinalities that must agree at a stable evaluation
## boundary (M26 assignment == M19 agent == M25 claim == reservation == M24 committed work).
## A healthy in-flight transaction holds exactly one of each; all-zero is quiescent. Returned
## as an ordered array so callers can test all-zero / all-equal / drift.
func transaction_cardinalities(scheduler, dispatcher, claim, reservations, slots) -> Array:
	return [scheduler.live_assignment_count(), dispatcher.get_active_count(),
		claim.live_claim_count(), reservations.get_reservation_count(), slots.live_work_count()]

## Full cross-engine consistency guard (F-M30-V01-001). A surfaced M26 fatal state OR ANY
## cardinality drift across the five authorities is fail-closed ERROR — never a LOSE and never
## an indefinite PLAYING. All-zero (quiescent) and all-equal-positive (N legitimate in-flight
## transactions) are the only consistent shapes.
func has_fatal_inconsistency(scheduler, dispatcher, claim, reservations, slots) -> bool:
	if scheduler.has_method("is_fatal") and scheduler.is_fatal():
		return true
	var counts: Array = transaction_cardinalities(scheduler, dispatcher, claim, reservations, slots)
	for i in range(1, counts.size()):
		if counts[i] != counts[0]:
			return true
	return false

## Cheap WIN test (no M27 proof). WON requires a fully cleared board AND full quiescence —
## the board reaching zero while a final robot is still travelling is NOT quiescent, so this
## cannot fire early on the last robot's departure.
func is_won(board, scheduler, dispatcher, claim, reservations, slots) -> bool:
	if board.count_cells_by_state(BoardState.CellState.ACTIVE) != 0:
		return false
	return is_quiescent(scheduler, dispatcher, claim, reservations, slots)

## Full read-only evaluation. `allow_deadlock_proof` lets the controller dirty/event-gate the
## expensive M27 proof: when false the evaluator will report PLAYING instead of running the
## proof (never a false WIN/ERROR — those are cheap and always evaluated). Returns a detached
## dict {status, reason, classifier?}.
func evaluate(board, scheduler, dispatcher, claim, reservations, slots, level, supply,
		allow_deadlock_proof: bool) -> Dictionary:
	# Fail closed FIRST: a cross-engine inconsistency / fatal bookkeeping is a diagnostic
	# ERROR, never silently reclassified as WIN or LOSE and never left indefinitely PLAYING.
	if has_fatal_inconsistency(scheduler, dispatcher, claim, reservations, slots):
		return {"status": ERROR, "reason": "cross_engine_inconsistency"}
	# Consistent now: the five cardinalities are all-zero (quiescent) or all-equal-positive
	# (legitimate in-flight work). Cheap WIN (quiescent + board empty).
	if is_won(board, scheduler, dispatcher, claim, reservations, slots):
		return {"status": WON, "reason": "board_cleared_and_quiescent"}
	# Equal-positive cardinalities -> legitimate in-flight work, nonterminal. No LOSE proof
	# while progress may still be in flight (owner: a live assignment / in-flight Scrubbot
	# prevents loss).
	if not is_quiescent(scheduler, dispatcher, claim, reservations, slots):
		return {"status": PLAYING, "reason": "in_flight_work"}
	# Quiescent but board not empty. Only NOW may a LOSE proof run — and only when the
	# controller's dirty/event gate permits it (audit §G: no unconditional per-frame proof).
	if not allow_deadlock_proof:
		return {"status": PLAYING, "reason": "deadlock_proof_gated"}
	var c: Dictionary = _classifier.classify_runtime(level, board, supply, slots, 0)
	var st = c.get("status", DeadlockClassifier.UNKNOWN_BOUND)
	if st == DeadlockClassifier.DEADLOCK:
		return {"status": LOST, "reason": "m27_deadlock_at_quiescence", "classifier": c}
	# COMPLETED here would mean board empty (already handled as WON). Every other status —
	# PROGRESSABLE / STALLED / UNKNOWN_BOUND — is explicitly NOT a loss.
	return {"status": PLAYING, "reason": "m27_%s" % String(st).to_lower(), "classifier": c}
