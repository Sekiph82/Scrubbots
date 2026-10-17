# M46-RM-002 | ChatGPT Audit Criteria V01
Applies to independent adversarial validation of R02–R07, especially R06 worker proof and R07 rewarded/FTUE. Source tree `76e4aff8` before audit-only commits, not misleading master HEAD. All actual test execution by Claude = E1/E2, subject to subsequent ChatGPT E3 source/test re-audit.

| Criterion | Mandatory direct evidence and fail condition |
|---|---|
| RM002-01 | Explicit real-host 59x59 legal+illegal Random/Selector/Tornado/+1 slot, 5/6 slots, open/close/retry, target reservation, board/supply/cell conservation, owner wallet isolation; precise ledger before/after. |
| RM002-02 | Proved Random or Selector safe iff exact current eligibility under actual DeadlockClassifier at a quiet state; 92-batch equivalence where relevant, plus malformed/null fail-closed; error vs timeout distinguished. |
| RM002-03 | Every proof-relevant state mutation (board rev, supply order, slot remaining/WAITING/sequence, capacity change) invalidates stale cached results unless a documented equivalent future proof state is established by a convincing direct test. |
| RM002-04 | Re-entry/concurrent requests for same/different booster cause at most one active worker, no recursive settle spuriously restarts new worker, cancel on close/retry/exit bounded and leaves zero jobs. Force actual worker-in-progress before cancellation tests; include crash/null result path. |
| RM002-05 | 400ms sync fallback and 5s worker budget: timeout returns not-proven without any SB/charge spend; same-state cached timeout no repeated freeze, change after real move can retry; partial Selector displays *only* proven safe target chips. No silent cap change. |
| RM002-06 | Earned rewarded grant commits once independently from proof; may be consumed only on positive proof once; before-proof/after-proof/timeout/cancel/popup-close/scene-exit/duplicate callback leave receipt count and charges as owner contract; no target-requiring auto-use. |
| RM002-07 | FTUE L2 real A+B steps behave without main-thread legality, show neutral Checking copy, update after proof, Skip Tips/terminal/route/modal/exit stable. No new worker while host exiting, no stale signal or misleading "not now" on pending. |
| RM002-08 | Scratch slot exactly reconstructs remaining, WAITING and placement order, malformed refuses; `free_slot_if_idle` fails for partial/waiting and never creates ghost batch; sensitivity no false PASS via skipped column or early abort. |
| RM002-09 | Direct negative controls: stale cache-key bypass, WAITING loss, double grant, late auto-use after popup close, re-enabled main-thread legality. Each causes assertion failure *for that invariant*, original source/test restored before final run. If a mutation cannot safely be run, mark NOT_RUN with rationale. |
| RM002-10 | Owner dirty `main.tscn` controlled: read-only parity/diff and what tests actually exercised documented, no owner files changed; if provenance unprovable mark BLOCKED not PASS. |
| RM002-11 | CPU/worker/UX performance measured with separately attributed proof, popup build, settle+auto-use and thread-cancel costs; no device/GPU claim and no false aggregate PASS on incomplete-ledger subsets. |
| RM002-12 | Actual executed test paths are counted and reported; no script error or incomplete coroutine can be presented as success, no setup condition silently skips false-positive tests. |
| RM002-13 | Need-a-Hand deterministic proof untouched, no silent new owner product decision, R06 O1/O2/O3 defaults unchanged, Actions cost-freeze and workflow guards unchanged. |
| RM002-14 | Claude writes implementation/log only and ends AWAITING_AUDIT; root TASKS and independent verdicts are ChatGPT-owned. All E3/OWNER gates remain reserved. |

Audit must show source interfaces, canonical state, upstream/downstream, matching test and negative-control run, precise commit. A discovered true prod defect triggers stop and whole-sprint re-audit, not a standalone fix prompt. No CI/actions or paid cloud allowed.
