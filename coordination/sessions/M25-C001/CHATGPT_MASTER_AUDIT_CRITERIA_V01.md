# M25-C001 V01 — Master Strict Audit Criteria

Milestone: `M25 — Batch Target Claim Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Auditor: ChatGPT
Upstream accepted milestones: M23 Batch Supply Engine, M24 Five-Slot Batch Engine
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`

## 0. Verdict policy

M25 passes only if **all `SB-M25-001..032` are implemented and directly evidenced** while preserving the already accepted M24 accounting contract, ReservationState, TargetSelector WHAT policy, ProductionTargetAccess/ProductionRoutingSystem reachability truth, and M20 authenticated clear authority.

M25 owns batch-to-target claim arbitration and claim bookkeeping. It does **not** own automatic robot scheduling/spawn (M26) or solvability/deadlock search (M27).

Passing existing tests alone is not sufficient. ChatGPT will inspect production code, transaction order, rollback behavior, same-color FIFO arbitration, reservation uniqueness, waiting behavior, reset cleanup, and direct real-routing evidence.

## 1. Governance

- Work only in `Sekiph82/Scrubbots` `main`.
- Safe sync; preserve owner-local/untracked work.
- Root `TASKS.md` is read-only for Claude.
- Zero image-generation credits.
- Do not implement M26 or M27.
- Do not rewrite accepted M23/M24 engines except for a narrowly justified compatibility seam that is impossible to implement externally; any such change must be explicitly documented and fully regressed.
- Do not weaken or replace BoardState, ColorCandidateIndex, ReservationState, TargetSelector, ProductionTargetAccess, ProductionRoutingSystem, Dispatcher, ScrubbotAgent, or CompleteClearingLoop.

## 2. Production architecture boundary — SB-M25-001..003

Create one session-scoped gameplay-domain Batch Target Claim service/ledger with narrow APIs and detached read-only snapshots.

Every live claim record must include at least:

- stable claim/work identity;
- M24 `batch_id`;
- M24 slot index;
- batch placement sequence;
- canonical runtime color ID;
- target index and canonical target coordinate;
- ReservationState integer owner/assignment identity;
- live claim lifecycle/status sufficient for exact rollback/finalization.

The claim ledger is **not** a second reservation authority. ReservationState remains the authoritative live target->owner and owner->target mapping.

The M24 `claim_id`/work identity must be the exact opaque work identity committed into FiveSlotBatchEngine so M24 `committed` reflects live claims one-for-one.

## 3. Exact dependency/coherence binding

The claim engine must bind to one coherent production bundle at minimum:

- canonical BoardState;
- accepted FiveSlotBatchEngine;
- TargetSelector bound to that same board + ReservationState;
- ReservationState bound to that same board.

Production claim calls must consume the canonical production reachability truth, not an invented second BFS or all-true shortcut. The access object used for a selected slot must be a real/coherent `ProductionTargetAccess` or an equivalently strict production adapter whose targetability derives from ProductionRoutingSystem + RouteValidator for that board.

M25 may accept slot-scoped access inputs prepared by the future scheduler/layout layer. M25 must not guess UI coordinates or create a contradictory slot-origin model.

Mixed-board/mixed-reservation/malformed dependencies fail closed with zero claim, zero M24 commit, and zero reservation mutation.

## 4. Eligible targets only — SB-M25-004..005, 012

A live claim may be created only for a target that is simultaneously:

- valid BoardState index;
- ACTIVE;
- matching the batch color;
- currently unreserved;
- currently production-targetable from the selected slot's supplied production access truth.

Blocked/unreachable future targets must never be pre-owned or entered into the claim ledger.

TargetSelector must remain the WHAT authority and preserve its owner-locked order among eligible candidates:

1. bottom-most;
2. left-most;
3. deterministic index tie-break.

Do not duplicate TargetSelector sorting in a second claim-specific target picker.

## 5. Same-color batch arbitration — SB-M25-006..010

Multiple occupied same-color M24 batches are legal and independent.

For a claim request of color C:

1. collect only occupied M24 batches of C with dispatch capacity > 0;
2. order by `placement_sequence` oldest first;
3. select the oldest capacity-bearing batch;
4. request one target through TargetSelector using that selected slot's production access truth.

Do not skip an older same-color batch merely to consume from a newer batch while the older batch still has dispatch capacity under the declared owner rule.

When the oldest batch has zero dispatch capacity, the next oldest same-color batch may receive additional work.

Arbitration must be deterministic across reset/replay fixtures.

Different colors are independent except for the globally shared ReservationState uniqueness.

## 6. Atomic logical claim transaction — SB-M25-013..018

One accepted claim must atomically establish all of the following logical facts:

- TargetSelector selected and ReservationState reserved exactly one target for a new unique owner identity;
- exact batch/slot ownership is recorded in the M25 claim ledger;
- FiveSlotBatchEngine `commit_work(slot, claim_id)` increments that batch's `committed` exactly once;
- `remaining_to_clear` is unchanged;
- one target belongs to exactly one live claim and one reservation owner.

No accepted claim may exist in only one or two of these layers.

Recommended safe order:

1. choose batch by M24 placement sequence/capacity;
2. mint deterministic unique reservation-owner/claim identity;
3. TargetSelector `select_and_reserve`;
4. if no target, create no claim and mark the chosen batch WAITING as appropriate;
5. if reserved, restore/confirm batch ACTIVE;
6. `M24.commit_work(slot, claim_id)`;
7. if M24 commit fails, release exactly the new reservation and restore any lifecycle state changed by this attempt;
8. only after both reservation + M24 commit are proven, publish the claim ledger entry.

Equivalent order is acceptable only if rollback is exact and directly proven.

## 7. Uniqueness — SB-M25-014..015

Directly prove:

- one target index can never appear in two live claim records;
- ReservationState agrees with every live claim's target/owner pair;
- one claim identity maps to one slot/batch/target only;
- one batch cannot create duplicate live claims to the same target;
- competing same-color requests serialize deterministically;
- different-color claims cannot steal an already reserved target.

## 8. Zero-capacity / accounting — SB-M25-016..018, 025

A batch with capacity 0 cannot receive another claim.

M25 must never decrement `remaining_to_clear` merely for selection/reservation/claim creation.

Each accepted claim increases M24 `committed` exactly once via one exact claim/work identity.

A slot/batch cannot complete while any live claim/work remains committed. M24 completion remains authoritative on `remaining==0 && committed==0`.

## 9. Route/spawn failure rollback seam — SB-M25-019

M26 is not implemented yet, so M25 must provide a narrow rollback API for a future route/spawn failure **before robot spawn**.

Given an exact live claim:

- release exactly its ReservationState target/owner pair;
- roll back exactly its M24 committed work identity;
- erase exactly that claim ledger entry;
- leave `remaining_to_clear` unchanged;
- consume zero batch quota;
- create/spawn no robot;
- do not disturb any unrelated reservation, claim, slot, or color.

The rollback must be transactionally safe. If one canonical mutation fails, either the operation fails before any mutation or verified compensation restores the exact pre-call tuple. No half-release claim/reservation state is acceptable.

M25 must not calculate routes or spawn agents. Tests may label this path `route_failure_rollback`, but the failure is injected as a future-M26 reason only.

## 10. Authenticated clear finalization — SB-M25-020..023

M25 must expose a narrow post-clear finalization seam for the exact live claim.

M25 does not replace CompleteClearingLoop authentication. The finalization seam must require exact claim identity plus canonical postconditions compatible with an already-authenticated clear, at minimum:

- claim exists and exact slot/batch/target/owner identity matches engine-owned record;
- BoardState target is now CLEARED;
- the claim's ReservationState ownership has already been resolved/released by the authoritative clear pipeline;
- the same claim has not already been finalized/rolled back.

Only then may M25 call `M24.resolve_clear(claim_id)` and erase the live claim.

Successful finalization decrements M24 `remaining_to_clear` and `committed` exactly once through M24. M25 itself must not manually edit those counters.

Stale, wrong-target, wrong-owner, already-cleared-without-matching-claim, duplicate finalization, or random claim identity must fail closed with zero additional quota loss.

A robot/assignment may never be silently retargeted to a different claim target.

## 11. Reset / teardown — SB-M25-024

M25 reset/session teardown must safely clean every live claim:

- release every exact ReservationState pair still owned by M25 claims;
- roll back every still-live M24 work identity when M24 is still in the corresponding pre-clear state;
- clear the claim ledger and transient arbitration state;
- invalidate stale claim identities;
- leave no claim/reservation leak.

Document required session teardown order between M25 and M24. Prefer M25 claim cleanup before M24 reset so committed work can be rolled back coherently.

Reset must be re-entry safe and must not erase unrelated ReservationState owners.

## 12. WAITING / authoritative board-change reevaluation — SB-M25-026..027

When the selected oldest batch has remaining quota/capacity but no currently claimable matching target, M25 must transition it to M24 WAITING without discarding it.

M25 must not poll presentation/UI state.

Provide a gameplay-domain board-change/clear notification or reevaluation seam so a future scheduler can reconsider waiting colors after authoritative BoardState clears. The seam must use production targetability, not visual state.

When a later target becomes claimable, the same-color FIFO rule still applies and the relevant WAITING batch becomes ACTIVE as part of successful claim acceptance.

Do not implement the M26 automatic scheduling loop here.

## 13. Canonical BLUE 8 / 14 / 12 — SB-M25-028..030

Use the accepted real M23->M24 placement path to create three simultaneous blue batches:

- BLUE 8
- BLUE 14
- BLUE 12

Directly prove:

- the three remain distinct batch identities/slots;
- when blue work is available, the oldest placement receives claims while it has capacity;
- the same target is never shared by the three;
- if the oldest batch capacity is exhausted by live claims, additional targets spill deterministically to the next batch;
- if no blue target is currently targetable, no blue target is pre-owned;
- after an authoritative board change opens one blue target, that target is claimed **at opening/reconsideration time**, not before;
- the newly opened target goes to the oldest same-color batch with available capacity.

Include rapid/simultaneous claim attempts and prove deterministic serialization.

## 14. Rectangular / 59x59 stress — SB-M25-031

Run five occupied slots with duplicate colors on:

- at least one rectangular board;
- one 59x59 board.

Use production BoardState + production targetability/routing semantics. Prove uniqueness, bounded reservation/claim counts, deterministic same-color order, and no board-size-coupled O(board) work in the fixed-size slot arbitration layer beyond the already accepted target/routing queries.

Record performance sanity without inventing arbitrary timing thresholds.

## 15. Regression matrix — SB-M25-032

Headless tests must cover at minimum:

- malformed/mixed dependency bind;
- invalid color / no matching batch;
- zero capacity;
- no currently targetable pixel;
- blocked future pixel not pre-claimed;
- duplicate colors;
- oldest placement wins;
- capacity spill to next same-color batch;
- TargetSelector bottom-most/left-most order preserved;
- same target contention;
- claim-id / reservation-owner uniqueness;
- M24 commit failure after reservation with exact rollback;
- route-failure rollback seam;
- wrong/random claim rollback;
- successful authenticated-clear finalization;
- double/stale finalization;
- reset with multiple live claims;
- unrelated ReservationState owner survives M25 reset;
- newly opened target assignment timing;
- deterministic reset/replay order;
- rectangular board;
- 59x59 board.

## 16. Re-entrancy / transaction safety

Any M25 operation that invokes an external collaborator capable of synchronous callbacks must be guarded against re-entry/state drift. Nested claim/reset/rollback/finalize attempts must fail closed or be deterministically deferred.

No callback may leave:

- reservation without M24 committed work;
- M24 committed work without reservation/claim;
- duplicate ledger entry;
- wrong-batch claim;
- lost unrelated reservation.

Use adversarial test seams where necessary, but do not widen production dependency categories merely to facilitate tests.

## 17. Continuous work packages

Execute in order without waiting for owner/auditor approval between packages:

1. `M25_WORK_PACKAGE_01_CLAIM_MODEL_AND_BINDING.md`
2. `M25_WORK_PACKAGE_02_FIFO_ARBITRATION_AND_ATOMIC_CLAIM.md`
3. `M25_WORK_PACKAGE_03_ROLLBACK_CLEAR_WAITING_AND_RESET.md`
4. `M25_WORK_PACKAGE_04_BLUE_OPENING_AND_RACE_EVIDENCE.md`
5. `M25_WORK_PACKAGE_05_SCALE_REGRESSION_AND_CLOSURE.md`

Fix focused failures and continue automatically until all M25 tasks are implemented or a genuine owner-policy ambiguity is found.

## 18. Required final validation

At minimum run/report:

- `godot --version`;
- full `tests/run_tests.gd`;
- dedicated M25 claim-model/atomicity evidence;
- dedicated same-color FIFO/BLUE evidence;
- dedicated rollback + authenticated-clear + reset evidence;
- newly-opened-target evidence;
- rectangular + 59x59 M25 evidence;
- all M24 V01/V02 dedicated evidence;
- M23 V01/V02/V03 evidence;
- M22 V07 interior-turn + V06/V05/V04/V03 evidence;
- M21 real-art smoke + M21 V10 reservation evidence;
- representative M20 authenticated-clear/lifecycle/queue-free evidence;
- `git diff --check`.

Report exact root-suite checks, failures, and exit codes.

## 19. Final log protocol

After all five packages are complete and green:

1. record safe-sync start SHA;
2. record implementation commit SHA(s) in order;
3. identify final implementation SHA;
4. push implementation first;
5. create `coordination/sessions/M25-C001/CLAUDE_LOG_V01.md` in a separate final documentation commit;
6. map every `SB-M25-001..032` to production code + direct evidence;
7. state `root TASKS.md modified = NO`;
8. state `M26/M27 implementation = NO`;
9. state `image-generation credits spent = 0`;
10. finish `AWAITING_AUDIT`.

## 20. Closure

M25 closes only after independent ChatGPT audit. Do not begin M26 implementation before that audit.
