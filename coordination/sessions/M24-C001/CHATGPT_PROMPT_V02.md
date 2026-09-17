# M24-C001 V02 — Claude Remediation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M24 — Five-Slot Batch Engine`
Cycle: `M24-C001 V02`

Read first, in order:

1. root `TASKS.md` — read only, never modify;
2. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
3. `coordination/sessions/M24-C001/CHATGPT_AUDIT_V01.md`;
4. `coordination/sessions/M24-C001/CHATGPT_AUDIT_CRITERIA_V02.md`;
5. `coordination/sessions/M24-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
6. current M24 production files and all V01 evidence/tests.

## Goal

Close the two remaining M24 V01 findings without redesigning the accepted ordinary-path Five-Slot Batch Engine.

The key defect is that `_busy` currently blocks only nested `select_front_batch()` while other M24 mutators, especially `reset()`, may execute synchronously during the external M23 placement call. `reset()` currently also sets `_busy=false` from inside the active outer placement, reopening the transaction guard.

V02 must make the full M24 mutation boundary serialized and add the missing direct M23 commit-failure/stale evidence.

## Required production correction

Implement one coherent transaction/mutation policy across the entire M24 public mutation surface.

While a supply placement is active, no nested public M24 mutator may alter slot/counter/work-ledger/lifecycle/placement-sequence/transient truth.

Cover at least:

- `select_front_batch`;
- `commit_work`;
- `resolve_clear`;
- `rollback_work`;
- `set_claimable_work_available`;
- `reset`;
- pause/resume or any other method that mutates M24 state.

A nested call may fail closed or be deterministically deferred, but the contract must be explicit and directly tested.

### Reset rule

Do not allow a reset invoked from inside a placement callback to clear/reopen the active placement transaction.

A simple acceptable design is a single engine-owned mutation guard where reset returns/records failure while busy and leaves every field untouched. A generation/deferred design is also acceptable only if you can prove no M23/M24 split-brain. Prefer the smallest robust design.

If you change `reset()` to return a boolean success/failure result, preserve ordinary callers and tests appropriately. Do not make M24 silently own M23 reset.

### Re-entry from both external calls

Test synchronous re-entry from:

1. `begin_front_selection()`;
2. `commit(tx)`.

Do not assume commit cannot be a callback boundary merely because production M23 normally does not call M24.

## Required direct adversarial scenario A — begin callback

Build/extend a narrow M23 test double. During outer M24 `select_front_batch()` -> M23 `begin_front_selection()` callback, attempt:

1. M24 reset;
2. immediately after that, another nested `select_front_batch()`;
3. a legal `commit_work()` or `resolve_clear()` against a pre-existing slot;
4. a legal `set_claimable_work_available()` transition against a pre-existing slot.

Prove all nested mutations fail/defer according to the declared policy and mutate nothing while the outer placement transaction is active.

Prove the outer transaction then either:

- succeeds using the correct rightmost EMPTY slot from unchanged serialized state, or
- aborts with a documented fail-closed result and no supply/slot split-brain.

## Required direct adversarial scenario B — commit callback

Add a narrow M23 test seam where outer M24 calls `supply.commit(tx)` and the test seam synchronously attempts at least reset + one other M24 mutation.

Prove those nested mutations cannot alter M24 truth and cannot reopen the placement guard before the outer call unwinds.

## Required direct scenario C — failed/stale M23 commit

Drive `FiveSlotBatchEngine` through a valid begin followed by deterministic `commit(tx) == false`.

Acceptable approaches:

- make the selected M23 transaction stale through a narrow test seam before calling the real M23 commit;
- or use a tightly scoped test double that returns a valid authentic transaction but forces commit failure without modifying M24.

Then prove:

- result error is `supply_commit_failed` or the stable equivalent;
- no slot changes;
- no ghost batch appears;
- placement sequence does not advance;
- live-work ledger/counters/lifecycle are exact-prestate;
- unrelated M24 state is unchanged.

If a stale construction advances M23 due to a separate legitimate M23 transaction, document that separately rather than claiming M23 byte-equality.

## SlotBatchState hardening

While touching the lifecycle code, remove or harden the arbitrary `set_state(String)` seam.

Engine-owned states must be restricted to `EMPTY`, `ACTIVE`, `WAITING`. Prefer validated transition methods or a fail-closed state setter returning bool. Add direct invalid-state tests.

Do not add target arbitration or M25 logic.

## Preserve all accepted V01 behavior

Do not regress:

- exactly five initially EMPTY slots;
- rightmost-empty automatic placement;
- no player slot choice;
- no shifting/compaction;
- full-five atomic rejection;
- same-color independence;
- BLUE 8/14/12;
- stable batch IDs;
- counter invariants/capacity;
- live-work accounting;
- completion/freeing;
- WAITING/ACTIVE ordinary behavior;
- detached snapshots;
- pause/resume;
- ordinary reset;
- five-full completion/refill cycle;
- deterministic replay;
- all accepted M23/M22/M21/M20 regressions.

## Scope prohibition

Do NOT implement:

- M25 Batch Target Claim Engine;
- target pixel ownership/arbitration;
- ReservationState changes;
- M26 Auto Dispatch Scheduler;
- Scrubbot spawning/routing changes;
- M27 Solvability/Deadlock Engine;
- production UI.

Do not modify root `TASKS.md`.

## Validation

Run everything required by `CHATGPT_AUDIT_CRITERIA_V02.md`, including the full root suite, all M24 V01 evidence, new V02 adversarial evidence, M23 V01/V02/V03, M22 V03-V06, M21 real-art + V10 reservation, M20 representative tests, and `git diff --check`.

## Git / handoff

1. Safe-sync `main`; preserve owner-local/untracked work.
2. Keep root `TASKS.md` untouched.
3. Make focused implementation/test commit(s) and push them first.
4. Only after implementation is pushed, create `coordination/sessions/M24-C001/CLAUDE_LOG_V02.md` in a separate final commit.
5. The log must satisfy V02 criteria §10 exactly.
6. Finish with `AWAITING_AUDIT`.

Return only:

- `AWAITING_AUDIT`
- final implementation SHA
- direct GitHub URL to `CLAUDE_LOG_V02.md`
