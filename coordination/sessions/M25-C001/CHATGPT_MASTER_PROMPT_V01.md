# M25-C001 V01 — MASTER IMPLEMENTATION PROMPT

Milestone: `M25 — Batch Target Claim Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Execution mode: CONTINUOUS, ALL WORK PACKAGES, NO INTERMEDIATE HANDOFF
Actor: Claude
Auditor: ChatGPT

## 0. Read first

Before coding, read:

1. root `TASKS.md` M25 section;
2. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`;
3. `coordination/sessions/M24-C001/CHATGPT_AUDIT_V02.md`;
4. `coordination/sessions/M25-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`;
5. accepted production code for M24 FiveSlotBatchEngine, TargetSelector, ReservationState, ProductionTargetAccess, ProductionRoutingSystem and CompleteClearingLoop.

Root `TASKS.md` is **read-only** for Claude.

## 1. Objective

Implement **all `SB-M25-001..032`** as one coherent Batch Target Claim Engine program.

M25 answers:

> Given currently occupied M24 batches and the current BoardState/routing truth, which exact live batch owns which exact currently-targetable pixel reservation?

M25 does **not** answer:

- when to automatically schedule every future robot;
- how to animate/spawn Scrubbots;
- whether the level is globally solvable.

Those remain M26/M27.

## 2. Locked gameplay rules

Preserve these owner rules exactly:

- no future blocked/unreachable pixel is pre-owned;
- only currently production-targetable matching ACTIVE pixels may be claimed;
- ReservationState remains the live target reservation authority;
- TargetSelector remains the target-choice authority and preserves bottom-most then left-most ordering;
- duplicate-color batches remain independent;
- same-color arbitration is oldest M24 placement sequence first;
- oldest batch keeps receiving work while it has dispatch capacity;
- only when its capacity is exhausted may work spill to the next same-color batch;
- one target can belong to only one live claim/robot assignment;
- M24 `remaining_to_clear` does not decrease merely because a claim exists;
- accepted claim increments M24 `committed` exactly once using the exact M25 claim/work identity;
- route/spawn failure before robot creation must roll back reservation + claim + M24 committed count with zero quota loss;
- authenticated clear finalization decrements M24 remaining/committed exactly once;
- no target, no claim; no valid claim, later M26 must spawn no robot.

## 3. Architecture constraints

Prefer a new gameplay-domain class such as:

`res://scripts/gameplay/targeting/batch_target_claim_engine.gd`

and, if useful, a small immutable/detached claim value type.

Do not put M25 truth into UI Nodes.

The engine must maintain one narrow session-scoped claim ledger. Every live entry must map one M24 batch/slot to one ReservationState reservation and one M24 committed work identity.

Do not create another board reservation map that competes with ReservationState. A ledger record may mirror exact reservation identity for bookkeeping, but ReservationState remains authoritative for whether a target is live-owned.

## 4. Existing-authority integration

Use the existing production systems, not replacements:

- `FiveSlotBatchEngine` for slot/batch/counters/placement sequence;
- `TargetSelector` for WHAT target is selected;
- `ReservationState` for live target ownership;
- `ProductionTargetAccess` + ProductionRoutingSystem + RouteValidator for current production targetability;
- BoardState for ACTIVE/CLEARED truth;
- CompleteClearingLoop remains the authenticated board-clear authority.

M25 may consume slot-scoped production access objects prepared by the caller/future scheduler. Do not guess slot screen coordinates or add a second reachability algorithm.

## 5. Claim transaction

Implement a transactionally safe accepted-claim path.

Expected semantics:

1. determine the oldest same-color occupied M24 batch with capacity;
2. obtain/use the production targetability object for that chosen slot;
3. mint a unique reservation-owner identity + claim/work identity;
4. ask TargetSelector to select-and-reserve one target;
5. if no target, create no claim and move the selected batch to WAITING when appropriate;
6. if a target is reserved, activate/confirm the batch ACTIVE;
7. commit exactly one M24 work unit using the exact claim/work identity;
8. if M24 commit fails, release exactly the new reservation and restore lifecycle prestate;
9. only then publish the claim ledger record;
10. return a detached claim result.

No half-claim may survive.

## 6. Rollback before spawn

Provide a narrow `rollback_claim`/equivalent for future M26 route/spawn failure.

It must remove exactly one live claim, release exactly its ReservationState pair, roll back exactly its M24 committed work identity, keep remaining quota unchanged, and leave unrelated claims/reservations untouched.

No route calculation or robot spawn belongs in M25.

## 7. Authenticated-clear finalization

Provide a narrow post-clear accounting hook for a claim that has already passed the authoritative clear pipeline.

Do not replace M20 authentication.

Require exact live claim identity and canonical postconditions, including target CLEARED and the claim reservation already resolved. Then call M24's exact work-resolution API once and erase the claim.

Wrong/random/double/stale claim finalization must fail closed and never double-decrement quota.

## 8. WAITING and target opening

If the oldest capacity-bearing batch of a color currently has no claimable target, put it into M24 WAITING without discarding it.

Provide an authoritative BoardState-clear/reconsideration seam for future M26 to wake/retry relevant waiting work. Do not poll UI state and do not implement an automatic dispatch loop.

A target that becomes reachable later must be assigned only after that opening exists in authoritative gameplay state.

## 9. Required BLUE fixture

Through the real M23 -> M24 path, create:

- BLUE 8
- BLUE 14
- BLUE 12

Then prove M25 behavior:

- BLUE 8 is oldest and receives new blue claims while it has capacity;
- no target is duplicated between the three batches;
- when BLUE 8's dispatch capacity reaches zero through live claims, additional blue claims spill to BLUE 14;
- BLUE 12 remains later until older same-color capacity is exhausted;
- when zero blue target is currently targetable, none is pre-owned;
- when one blue target later opens, it is claimed then, by the oldest capacity-bearing blue batch.

## 10. Required scale fixtures

Exercise:

- same-color races under rapid repeated claim attempts;
- different-color simultaneous live claims;
- rectangular board;
- 59x59 board;
- multiple occupied slots, including duplicate colors;
- reset/teardown with several live claims and one unrelated ReservationState owner.

Use real production targetability/routing semantics for closure evidence.

## 11. Work packages

Execute all five files in order and **do not stop for owner/auditor approval between them**:

1. `M25_WORK_PACKAGE_01_CLAIM_MODEL_AND_BINDING.md`
2. `M25_WORK_PACKAGE_02_FIFO_ARBITRATION_AND_ATOMIC_CLAIM.md`
3. `M25_WORK_PACKAGE_03_ROLLBACK_CLEAR_WAITING_AND_RESET.md`
4. `M25_WORK_PACKAGE_04_BLUE_OPENING_AND_RACE_EVIDENCE.md`
5. `M25_WORK_PACKAGE_05_SCALE_REGRESSION_AND_CLOSURE.md`

Run focused tests after each package. Fix failures and continue.

Stop early only for a genuine owner-policy ambiguity not answered by TASKS/owner decision/master criteria.

## 12. Scope prohibitions

Do not implement M26:

- no automatic per-frame scheduler;
- no Scrubbot spawning;
- no route-to-agent handoff;
- no dispatch pacing/fairness loop;
- no whole-batch autonomous execution.

Do not implement M27:

- no level solver;
- no deadlock search/classification;
- no generated-supply acceptance/retry loop.

Do not modify root `TASKS.md`.

## 13. Validation

Meet every item in:

`coordination/sessions/M25-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

At the end run the full root suite and all required dedicated evidence scripts. Preserve M24/M23/M22/M21/M20 regressions.

## 14. Commit / handoff protocol

You may use focused implementation commits, but do not stop between packages.

After every `SB-M25-001..032` item is implemented and validation is green:

1. push implementation commit(s);
2. write `coordination/sessions/M25-C001/CLAUDE_LOG_V01.md` in a separate final documentation commit;
3. map all 32 M25 tasks to code + direct test evidence;
4. include exact root-suite count/failures and all dedicated command exit codes;
5. state `root TASKS.md modified = NO`;
6. state `M26/M27 implementation = NO`;
7. state `image-generation credits spent = 0`;
8. return only:
   - `AWAITING_AUDIT`
   - final implementation SHA
   - direct GitHub URL to `CLAUDE_LOG_V01.md`.
