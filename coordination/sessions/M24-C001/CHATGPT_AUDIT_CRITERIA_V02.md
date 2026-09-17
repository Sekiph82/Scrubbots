# M24-C001 V02 — Strict Audit Criteria

Cycle: `M24-C001 V02`
Milestone: `M24 — Five-Slot Batch Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Auditor: ChatGPT
Prior audit: `coordination/sessions/M24-C001/CHATGPT_AUDIT_V01.md`
Master criteria: `coordination/sessions/M24-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

## 0. Verdict policy

V02 passes only if both V01 findings are closed in real production code and direct adversarial tests, while all previously passing M24 behaviors and historical regressions remain green.

No M25/M26/M27 implementation may begin.

## 1. Governance

- Work only in `Sekiph82/Scrubbots` `main`.
- Safe sync; preserve owner-local work.
- Root `TASKS.md` is read-only for Claude.
- Implementation commit(s) first, `CLAUDE_LOG_V02.md` separately afterward.
- Zero image-generation credits.
- Preserve M23 Batch Supply Engine and protected M22/M21/M20 systems.

## 2. Global M24 mutation serialization during supply placement

When `FiveSlotBatchEngine` has entered a supply-placement transaction and may call external M23 code, no other public M24 state-mutating operation may mutate engine truth until that placement transaction has cleanly unwound.

At minimum cover:

- nested `select_front_batch`;
- `commit_work`;
- `resolve_clear`;
- `rollback_work`;
- `set_claimable_work_available`;
- `reset`;
- any other public method that mutates slot, counter, work-ledger, placement-sequence, pause/transient transaction state.

A nested mutation may either:

1. fail closed immediately with zero state change; or
2. be deterministically deferred, provided the design proves no M23/M24 split-brain and no stale-target placement.

The implementation must not clear/reopen the active placement guard from inside a nested reset/mutation.

## 3. Required reset-during-placement adversarial proof

Create a controlled M23 test seam/subclass that synchronously calls back into the M24 engine from `begin_front_selection()` while the outer `select_front_batch()` transaction is active.

The callback must attempt, at minimum:

1. `reset()`;
2. a nested `select_front_batch()` after the reset attempt;
3. one accounting mutation (`commit_work`, `resolve_clear`, or `rollback_work`) against a pre-existing occupied slot where the action would otherwise be legal;
4. one lifecycle mutation (`set_claimable_work_available`) against a pre-existing occupied slot where the action would otherwise be legal.

Directly prove:

- reset attempt does not reopen the transaction guard;
- nested select remains rejected;
- accounting mutation is rejected/deferred with no counter/ledger change;
- lifecycle mutation is rejected/deferred with no state change;
- slot occupancy, rightmost-empty result, placement sequence and live-work ledger remain coherent;
- outer placement follows the declared policy deterministically;
- if outer placement succeeds, it uses the correct rightmost EMPTY slot from a stable serialized state;
- if outer placement aborts, M23 front and M24 state obey the declared rollback/abort contract;
- exactly zero ghost insertion / double advance / split-brain occurs.

If reset is declared fail-closed while busy, make that observable/testable. If it is deferred, prove the deferred reset cannot run between M23 consumption and M24 placement in a way that loses the batch.

## 4. Re-entrancy from the M23 commit call

Do not assume only `begin_front_selection()` can re-enter. The production boundary must remain safe if a test seam invokes an M24 mutation synchronously from the M23 `commit(tx)` call as well.

Provide at least one direct commit-callback adversarial test. The test need not simulate a malicious lying M23 result, but it must prove that an M24 reset/accounting/lifecycle mutation cannot alter M24 truth while the outer commit boundary is active.

## 5. Direct failed/stale M23 commit evidence

Drive the production `supply_commit_failed` branch directly.

Required proof:

- a valid authentic M23 transaction is obtained;
- the corresponding M23 commit is made to fail deterministically through a narrow test seam or stale-front construction;
- `FiveSlotBatchEngine.select_front_batch()` reports failure and does not place the batch;
- complete M24 prestate is preserved: all five slots, lifecycle states, counts, placement sequence and live-work ledger;
- no ghost occupied slot appears;
- no placement-sequence increment occurs;
- no unrelated M24 state changes.

If the stale construction legitimately advances M23 because a separate M23 actor consumed the front, document that explicitly. Do not claim M23 byte-equality in that case. M24 exact-prestate remains mandatory.

## 6. Preserve M24 ordinary contracts

All V01 passing behavior remains required:

- exactly five initially EMPTY slots;
- rightmost-empty placement;
- no slot choice by player;
- no shifting/compaction;
- full-five atomic rejection;
- independent same-color batches;
- BLUE 8/14/12 fixture;
- stable batch identity;
- `0 <= committed <= remaining <= initial`;
- capacity calculation;
- live-work duplicate/unknown/double failure;
- resolve decrements remaining + committed exactly once;
- rollback decrements committed only;
- true completion frees only the completed slot;
- WAITING/ACTIVE semantics;
- detached snapshots;
- pause/resume ordinary state preservation;
- reset ordinary behavior + pre-reset work invalidation;
- five-full -> complete -> refill cycle;
- deterministic replay;
- M23 transaction authenticity and supply behavior preserved.

## 7. Lifecycle-state hardening

While modifying serialization, inspect `SlotBatchState.set_state()`.

Engine-owned slot state must never become a string outside:

- `EMPTY`
- `ACTIVE`
- `WAITING`

Preferred correction: replace/narrow the arbitrary public setter with validated lifecycle transition operations or make the existing setter fail closed for unsupported states. Add direct tests for invalid state names. Do not introduce M25 claim policy.

This item closes the V01 non-blocking observation and prevents future misuse; it is part of V02 acceptance once the state file is touched.

## 8. Scope boundary

Do not implement:

- M25 Batch Target Claim Engine;
- target pixel ownership/arbitration;
- ReservationState replacement;
- M26 auto dispatch/spawn/route logic;
- M27 solvability/deadlock search;
- production UI integration.

## 9. Required validation

Run at minimum:

- `godot --version`;
- full `tests/run_tests.gd`;
- all four V01 M24 evidence scripts;
- new V02 mutation-serialization evidence;
- new failed/stale M23 commit evidence (may be in same V02 script if clear);
- M23 V01/V02/V03 evidence;
- M22 V03-V06 evidence;
- M21 real-art smoke;
- M21 V10 reservation evidence;
- representative M20 lifecycle/queue-free smoke;
- `git diff --check`.

Report exact check count/failures/exits.

## 10. Required V02 log

`coordination/sessions/M24-C001/CLAUDE_LOG_V02.md` must include:

- safe-sync start SHA;
- every implementation SHA in order and final implementation SHA;
- changed-file list;
- exact mutation-serialization design;
- direct begin-callback reset/nested-select/accounting/lifecycle trace;
- direct commit-callback re-entry trace;
- direct failed/stale M23 commit trace;
- mapping of `F-M24-V01-STRICT-001` and `002` to production code + tests;
- confirmation that all `SB-M24-001..030` evidence remains green;
- exact full-suite count/failure count;
- `root TASKS.md modified = NO`;
- `M25-M27 implementation = NO`;
- `image-generation credits spent = 0`;
- final `AWAITING_AUDIT`.

## 11. Closure

If V02 closes both findings and preserves every M24 contract, ChatGPT may mark `SB-M24-001..030` DONE and advance the canonical tracker to M25. Otherwise M24 remains open.
