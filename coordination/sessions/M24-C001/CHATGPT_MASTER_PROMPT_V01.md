# M24-C001 V01 — MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M24 — Five-Slot Batch Engine`
Actor: Claude
Auditor: ChatGPT
Execution mode: **continuous, no intermediate handoff**

## Mission

Implement the complete owner-locked M24 Five-Slot Batch Engine and finish **all `SB-M24-001..SB-M24-030`** in one continuous engineering run.

Do not stop after an individual work package to ask for approval. Read and execute every work package in order, fixing regressions as you go. Only stop early if a genuine owner-policy ambiguity remains after reading all canonical documents.

## Canonical inputs

Read before changing code:

1. root `TASKS.md` (read-only)
2. `CLAUDE.md`
3. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
4. `coordination/sessions/M23-C001/CHATGPT_AUDIT_V03.md`
5. `coordination/sessions/M24-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
6. accepted M23 production code under `scripts/gameplay/supply/`
7. historical `scripts/gameplay/slots/slot_system.gd` and `slot_state.gd`
8. `scripts/gameplay/clearing/complete_clearing_loop.gd` only to understand authoritative clear boundaries; do not rewrite it.

Then execute these work packages without waiting:

1. `coordination/sessions/M24-C001/M24_WORK_PACKAGE_01_SLOT_STATE_AND_INVARIANTS.md`
2. `coordination/sessions/M24-C001/M24_WORK_PACKAGE_02_SUPPLY_TO_SLOT_TRANSACTION.md`
3. `coordination/sessions/M24-C001/M24_WORK_PACKAGE_03_BATCH_LIFECYCLE_ACCOUNTING.md`
4. `coordination/sessions/M24-C001/M24_WORK_PACKAGE_04_PAUSE_RESET_AND_FIXTURES.md`
5. `coordination/sessions/M24-C001/M24_WORK_PACKAGE_05_FINAL_INVARIANT_AND_INTEGRATION_EVIDENCE.md`

## Locked production behavior

The player chooses a **front M23 supply batch**, never a destination slot. M24 automatically fills the **rightmost currently EMPTY** of exactly five slots. Occupied slots never shift or compact. Full-five selection rejects atomically and M23 does not advance.

Same-color batches remain separate identities. `BLUE 8`, `BLUE 14`, `BLUE 12` must coexist independently.

Per occupied slot maintain at least:

- `batch_id`
- canonical integer color ID
- `initial_count`
- `remaining_to_clear`
- `committed`
- placement sequence
- state `ACTIVE` or `WAITING`

EMPTY slots contain no stale batch truth.

Invariant:

`0 <= committed <= remaining_to_clear <= initial_count`

Capacity:

`remaining_to_clear - committed`

Do not decrement `remaining_to_clear` on selection, placement, targetability, target claim, route calculation, or robot spawn. It decreases only when a previously committed opaque work identity is resolved as one authenticated successful clear. Rollback of committed work reduces only `committed`.

A batch completes only at `remaining_to_clear == 0 && committed == 0`, then its slot becomes exactly EMPTY.

If remaining work exists but authoritative future claimability says none is currently available, the batch may be WAITING. When authoritative future claimability says matching work became available, WAITING resumes ACTIVE automatically without player re-selection.

## Critical architecture boundary

M24 owns **slot batch state/accounting only**.

Do not implement M25 target arbitration, target pre-ownership, ReservationState replacement, or TargetSelector policy.

Do not implement M26 robot spawning, route calculation, dispatcher scheduling, or `no target + no reservation + no valid route = no robot` logic.

Do not implement M27 solvability/deadlock search.

For M24 committed-work accounting, use opaque live work identities only. They prove that a unit was previously committed to a specific batch/slot; they do not encode target-selection authority. Future M25/M26 will connect real claim/dispatch/clear authority to these seams.

## M23 handoff

Use the accepted M23 transaction API. A downstream rejection must leave the selected supply batch at its original column front. An accepted placement must advance exactly one M23 column exactly once and create exactly one occupied slot.

Treat this cross-engine transaction as a strict atomic boundary. No batch loss, duplicate insertion, ghost slot, or double column advance is acceptable.

## Historical compatibility

Do not delete the historical direct-color `SlotSystem` merely because it is superseded for future production input. M21/M22 evidence must stay green.

Prefer adding a new production `FiveSlotBatchEngine` / `SlotBatchState` beside historical compatibility code unless a narrow, fully regression-safe adaptation is demonstrably cleaner.

## Continuous execution protocol

For each work package:

- inspect relevant current code first;
- implement only that package's scope;
- add direct adversarial headless tests;
- run focused tests;
- fix all failures before moving to the next package;
- make a focused implementation commit if useful;
- continue immediately to the next package without asking the owner or ChatGPT.

At the end run the complete validation matrix in the master audit criteria. Do not author an audit verdict yourself.

## Governance

- Safe-sync GitHub first.
- Preserve owner-local work.
- Never `reset --hard`, `clean -fd`, force-push, or destructively overwrite owner files.
- Root `TASKS.md` is read-only for Claude.
- No M25-M27 implementation.
- Zero image-generation credits.
- Preserve accepted M23 and M22 behavior.

## Final handoff

After all five work packages are complete and every required test is green:

1. push all implementation commits;
2. create `coordination/sessions/M24-C001/CLAUDE_LOG_V01.md` in a separate final documentation commit;
3. include safe-sync start SHA, every implementation SHA, final implementation SHA, changed files, and exact `SB-M24-001..030` evidence mapping;
4. include exact full-suite check/failure count and all dedicated evidence exits;
5. include `root TASKS.md modified = NO`;
6. include `M25-M27 implementation = NO`;
7. include `image-generation credits spent = 0`;
8. return only `AWAITING_AUDIT`, final implementation SHA, and the direct GitHub log URL.
