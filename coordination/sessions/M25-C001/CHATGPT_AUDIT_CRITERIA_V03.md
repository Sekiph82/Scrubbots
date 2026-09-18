# M25-C001 V03 — Exact Work-Tuple Binding Audit Criteria

Milestone: `M25 — Batch Target Claim Engine`
Cycle: `M25-C001 V03`
Repository: `Sekiph82/Scrubbots`
Actor: Claude
Auditor: ChatGPT
Prior audit: `coordination/sessions/M25-C001/CHATGPT_AUDIT_V02.md`

## Verdict policy

V03 passes only if `F-M25-V02-STRICT-001` is closed in production code and direct adversarial evidence, with all V01/V02 accepted behavior and M24/M23/M22 regressions preserved.

No M26 or M27 implementation.

## 1. Exact M24 tuple identity

M25 must be able to prove that a live claim's M24 work identity is bound to the exact tuple recorded in the M25 ledger:

- exact claim/work ID;
- exact slot index;
- exact batch_id.

A work ID being merely live and internally coherent somewhere in M24 is insufficient.

Preferred minimal seam:

`FiveSlotBatchEngine.is_work_bound_to(work_id, expected_slot, expected_batch_id)`

This seam must be read-only and return true only if:
- work_id exists;
- its engine-owned record slot equals expected_slot;
- its engine-owned record batch_id equals expected_batch_id;
- expected_slot is still occupied by expected_batch_id.

Do not expose mutable ledger storage.

## 2. M25 rollback preflight

Before `rollback_claim` mutates M24 or ReservationState, require:
- exact ReservationState target <-> owner pair;
- exact M24 work <-> claim slot/batch tuple.

A redirected work ID must fail closed.

## 3. M25 finalize preflight

Before `M24.resolve_clear(claim_id)`, require exact M24 work <-> claim slot/batch tuple in addition to existing authenticated-clear postconditions.

A redirected work ID must never decrement another batch's counters.

## 4. M25 reset / teardown preflight

Every live claim must pass exact ReservationState pair and exact M24 work slot/batch binding before reset cleans anything.

If one claim's work ID has been redirected to a different slot/batch:
- reset returns false;
- no claim ledger entries are erased;
- no healthy M24 work is rolled back;
- no reservation is released;
- unrelated ReservationState owners remain untouched.

## 5. Required redirected-work adversarial fixture

Create two occupied same-color batches with distinct batch IDs, A older than B.

1. Create claim C for A.
2. Record A slot/batch, target/owner and counters.
3. Externally call `M24.rollback_work(C)`.
4. Externally call `M24.commit_work(B_slot, C)`.
5. Confirm M24 now contains C as internally coherent work for B, while M25 ledger still records A.
6. `rollback_claim(C)` must fail closed.
7. Reservation pair stays intact.
8. M25 claim ledger stays intact.
9. B committed count is unchanged by the failed M25 call.
10. Stage clear postconditions and call `finalize_clear(C)`; it must fail closed and must not decrement B remaining/committed.
11. In a separate fixture with redirected work plus at least one healthy claim, `reset()` must fail closed before mutating either claim.

This exact redirect case must be in the root test suite or dedicated evidence run.

## 6. Healthy behavior preserved

Re-prove:
- healthy rollback exact;
- healthy authenticated finalize exact;
- healthy multi-claim reset exact;
- stale reset identities stay invalid;
- owner 0 collision does not stall;
- failed M24 commit restores lifecycle;
- strict access gate;
- session-stable binding;
- BLUE 8/14/12 FIFO/spill/opening;
- rectangular + 59x59.

## 7. Governance

- root TASKS.md read-only for Claude;
- implementation commit(s) first;
- `CLAUDE_LOG_V03.md` separate final commit;
- log MUST include explicit safe-sync SHA, implementation SHA(s), final implementation SHA, changed files and direct evidence;
- zero image credits;
- no M26/M27.

## 8. Validation

Run/report:
- full root suite;
- all M25 V01/V02 dedicated evidence;
- new V03 exact-work-tuple evidence;
- M24 V01/V02 evidence;
- M23 V01/V02/V03 evidence;
- M22 V07/V06 representative evidence;
- M21 real-art/V10;
- representative M20 lifecycle/queue-free;
- git diff --check.

## 9. Closure

If V03 passes, ChatGPT may close all `SB-M25-001..032` together and advance to M26 Auto Dispatch Scheduler.
