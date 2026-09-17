# M24-C001 V01 — Master Strict Audit Criteria

Milestone: `M24 — Five-Slot Batch Engine`
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude
Auditor: ChatGPT
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
Upstream accepted milestone: `M23 — Batch Supply Engine`

## 0. Verdict policy

M24 passes only if **all `SB-M24-001..SB-M24-030` are implemented and directly evidenced** while M25 target-claim policy, M26 robot dispatch/routing, and M27 solvability/deadlock remain unimplemented.

Passing existing tests alone is not sufficient. The final state machine, transactional M23 handoff, counter invariants, lifecycle transitions, reset behavior, and adversarial invalid-input paths must all be inspected in production code and exercised directly.

Claude must execute every M24 work package in order without waiting for owner/auditor approval between packages. Intermediate failures must be fixed and re-tested before moving on. Stop early only for a genuine owner-policy ambiguity that cannot be resolved from `TASKS.md`, the owner decision, or this criteria document.

## 1. Governance

- Work only in `Sekiph82/Scrubbots` `main`.
- Safe sync; preserve all owner-local/untracked work.
- Root `TASKS.md` is read-only for Claude.
- Zero image-generation credits.
- Do not start M25, M26, or M27 implementation.
- Preserve accepted M23 Batch Supply Engine behavior and all M22 routing/clearing contracts.
- Do not rewrite TargetSelector, ReservationState, ProductionTargetAccess, ProductionRoutingSystem, Dispatcher, ScrubbotAgent, CompleteClearingLoop, BoardState, or ColorCandidateIndex.
- Historical `SlotSystem` direct-color behavior may remain for historical M21/M22 regression fixtures, but it is not production M24 truth.

## 2. Production M24 architecture boundary

M24 owns five-slot **batch state and accounting**, not target selection or robots.

Required production roles:

1. a gameplay-domain `SlotBatchState` value/state object, independent of UI Controls;
2. a `FiveSlotBatchEngine` (name may differ) owning exactly five slot states;
3. a transactional integration seam to accepted M23 `BatchSupplyEngine`;
4. opaque committed-work accounting seams for future M25/M26 use;
5. WAITING/ACTIVE state-update seams driven by authoritative future claimability notifications, without implementing M25 target arbitration itself;
6. detached read-only snapshot/query APIs for future UI/save/replay.

M24 must **not** choose target pixels, call TargetSelector, reserve pixels, calculate routes, spawn Scrubbots, or claim that a level is solvable.

## 3. Exactly five slots / initial state — SB-M24-001..005

Directly prove:

- exactly five gameplay batch slots exist;
- all five start `EMPTY`;
- slot count cannot be configured to 4, 6, or another number;
- `SlotBatchState` is gameplay-domain data, not a presentation Node/Control;
- occupied state contains at least: `batch_id`, canonical color ID, `initial_count`, `remaining_to_clear`, `committed`, placement sequence, lifecycle state;
- lifecycle supports at minimum `EMPTY`, `ACTIVE`, `WAITING`;
- EMPTY slots expose no stale batch/color/count identity;
- malformed state construction fails closed.

## 4. Placement and M23 transaction atomicity — SB-M24-006..011, 023, 027

Production placement contract:

`player selects M23 front batch -> M24 finds rightmost EMPTY slot -> M24 accepts atomically -> M23 transaction commits -> batch appears in exactly one slot`

Required:

- destination slot is never supplied by the player-facing production API;
- rightmost EMPTY slot is chosen deterministically;
- occupied slots never shift/reorder/compact;
- holes remain holes until filled by later selections;
- full five-slot state rejects new selection with zero slot mutation;
- on full/rejected placement, M23 column does not advance and the same batch remains selectable;
- on accepted placement, exactly one supply front is consumed and exactly one slot changes EMPTY -> ACTIVE;
- no accepted placement may duplicate one batch into two slots;
- no rejected placement may leave a ghost slot state;
- rapid repeated requests serialize/fail closed so one M23 transaction cannot double-advance or double-insert;
- a newly freed slot is eligible under the same rightmost-empty rule.

The cross-engine handoff must have no fallible/re-entrant step after supply consumption that could lose a batch. If M23 commit can fail, M24 must preserve/restore its pre-placement state exactly.

## 5. Duplicate colors and stable batch identity — SB-M24-012..013

Directly prove:

- multiple occupied slots may share one color ID;
- same-color batches remain separate identities and counters;
- no automatic merge, quota pooling, reorder, or color-based collapse occurs;
- the canonical `BLUE 8`, `BLUE 14`, `BLUE 12` fixture can occupy three distinct slots simultaneously;
- each retains its own `batch_id`, initial count, remaining count, committed ledger, and placement sequence.

## 6. Counter invariants / capacity — SB-M24-014..018

Always enforce:

`0 <= committed <= remaining_to_clear <= initial_count`

and

`dispatch_capacity = remaining_to_clear - committed`

M24 does not own targets or dispatch, so committed work must be represented by an **opaque future-assignment/work identity** owned by M24 only for accounting. The identity must be unique per live commitment and must not contain/claim target-policy authority.

Required accounting semantics:

- player selection does not decrement `remaining_to_clear`;
- merely asking about targetability does not decrement it;
- future target claim, route calculation, or robot spawn must not decrement it;
- registering one future committed work unit increases `committed` by exactly one if capacity exists;
- duplicate commitment identity fails closed;
- commitment beyond capacity fails closed;
- successful authenticated resolution of one previously committed work identity decreases `remaining_to_clear` by exactly one and decreases `committed` by exactly one;
- rollback/cancel of one previously committed work identity decreases `committed` by exactly one and leaves `remaining_to_clear` unchanged;
- random/unregistered/wrong-slot/wrong-batch completion identity cannot decrement either counter;
- double resolve and resolve-after-rollback fail closed;
- invalid actions never violate the invariant.

### M24 authentication boundary

Because M25/M26 are not implemented yet, M24 must not fabricate target/route/robot authority. For M24, "authenticated" means a completion/rollback can affect counters only for an **exact live work identity previously committed by this slot engine**. Future M26 will connect real dispatcher/clearing authority to this seam. Tests may use a narrow harness to drive the seam, but production M24 must not expose a method that lets arbitrary color/count calls decrement work without such a prior commitment identity.

## 7. Completion / freeing — SB-M24-019..020, 023

A batch is complete only when:

- `remaining_to_clear == 0`, and
- `committed == 0`.

Required:

- reaching remaining zero while committed is nonzero must not free the slot;
- completing the final committed unit so both reach zero frees the slot deterministically;
- freeing clears all batch-specific mutable state and returns the slot to exact EMPTY truth;
- no adjacent occupied slot shifts;
- the freed hole can accept the next supply selection under the ordinary rightmost-empty rule.

## 8. WAITING / ACTIVE semantics — SB-M24-021..022

M24 must model WAITING without implementing M25 target arbitration.

Required contract:

- an occupied batch with remaining quota and no currently claimable matching work may transition ACTIVE -> WAITING;
- WAITING never discards/merges/decrements the batch;
- an authoritative **claimability notification/query result supplied by the future claim layer** may cause WAITING -> ACTIVE automatically, with no player re-selection;
- ACTIVE/WAITING transitions never mutate M23 queues or remaining/committed counts;
- EMPTY cannot become WAITING;
- completed batches cannot re-enter WAITING;
- M24 itself must not scan/own target pixels or create target claims.

A small claimability-provider seam/test double is acceptable. It must remain clearly separated from M25 policy.

## 9. Read-only queries / pause / reset — SB-M24-024..026

Required:

- public slot snapshots are detached; mutating returned structures cannot mutate engine truth;
- queries expose occupancy/state/counts/identity needed by presentation but not mutable internal arrays/maps;
- pause/resume causes no slot/batch/counter/ordering mutation;
- reset clears all five slots to exact EMPTY;
- reset clears live work identities, placement sequence/transient state, WAITING/ACTIVE flags, and any pending placement transaction state;
- pre-reset work identities cannot resolve after reset;
- M23 supply reset is **not silently owned by M24** unless a clearly documented session-level caller invokes both. M24's own reset scope must be explicit.

## 10. Canonical BLUE fixture — SB-M24-028

Provide a direct regression fixture with distinct batch identities:

- `BLUE 8`
- `BLUE 14`
- `BLUE 12`

Place them through the real M23 -> M24 transactional selection path, not by mutating slot internals directly.

Prove:

- they occupy distinct slots;
- rightmost-empty order is deterministic;
- same color does not merge them;
- each counter evolves independently when work identities are committed/resolved/rolled back.

This fixture is about slot/accounting behavior only. Do not assign target pixels in M24.

## 11. Five-full rejection -> completion -> refill cycle — SB-M24-029

Directly exercise:

1. fill all five slots through M23 front selections;
2. sixth selection rejected; supply unchanged;
3. drive one slot through legitimate committed-work accounting to true completion;
4. slot becomes EMPTY without shifting neighbors;
5. retry/select next supply batch;
6. it fills the rightmost currently EMPTY hole;
7. originating supply advances exactly once;
8. all invariants remain true.

## 12. Exhaustive invalid/state-transition tests — SB-M24-030

Headless tests must cover at minimum:

- invalid slot indexes/types;
- malformed batch transaction objects;
- exhausted supply column;
- full slots;
- rightmost-hole selection;
- same-color duplicates;
- duplicate batch ID defense;
- counter underflow/overflow;
- committed > remaining attempts;
- duplicate work identities;
- wrong work identity resolve/rollback;
- double resolve/rollback;
- WAITING transitions from illegal states;
- completion only at remaining=0 and committed=0;
- reset with active/WAITING/committed work;
- rapid repeated placement attempts;
- returned snapshot mutation;
- failed M23 commit or stale supply transaction leaves M24 exact-prestate;
- deterministic replay of the same placement sequence.

## 13. Concurrency / re-entrancy safety

M24 operations are synchronous gameplay-domain transactions. Any public operation that can trigger/call an external collaborator (M23 supply engine or future provider seam) must be guarded against re-entrancy/state drift.

A nested placement/commit/reset that occurs during another placement must fail closed or be deterministically deferred. No partial slot+queue split-brain is acceptable.

Tests must include at least one adversarial callback/test seam if the implementation introduces any callback/provider capable of synchronous re-entry.

## 14. Historical compatibility

Existing historical M21/M22 tests may continue using legacy `SlotSystem` direct-color configuration. Do not delete those fixtures merely because production M24 replaces the future input model.

M24 may add new production classes beside the legacy system. If an existing class is repurposed, all historical regressions must still pass or be narrowly adapted only where owner-locked future behavior explicitly supersedes a historical production assumption.

## 15. Performance / scale

M24 itself is fixed-size O(5) slot state and must remain trivial regardless of board size. Nevertheless run representative rectangular and 59x59 upstream regression/evidence to prove M24 changes did not introduce board-size coupling or regress M23 generation.

## 16. Required continuous work packages

Claude must execute, in order, without waiting for audit between them:

1. `M24_WORK_PACKAGE_01_SLOT_STATE_AND_INVARIANTS.md`
2. `M24_WORK_PACKAGE_02_SUPPLY_TO_SLOT_TRANSACTION.md`
3. `M24_WORK_PACKAGE_03_BATCH_LIFECYCLE_ACCOUNTING.md`
4. `M24_WORK_PACKAGE_04_PAUSE_RESET_AND_FIXTURES.md`
5. `M24_WORK_PACKAGE_05_FINAL_INVARIANT_AND_INTEGRATION_EVIDENCE.md`

Run focused tests after each package and the full root suite at the end. Fix failures before proceeding.

## 17. Required final validation

At minimum:

- `godot --version`
- full `tests/run_tests.gd`
- dedicated M24 production-state evidence script
- dedicated M24 transactional M23 handoff evidence
- BLUE 8/14/12 fixture evidence
- five-full -> completion -> refill evidence
- M23 V01/V02/V03 evidence
- M22 V03-V06 evidence
- M21 real-art full-clear smoke
- M21 V10 reservation evidence
- representative M20 lifecycle/queue-free tests
- `git diff --check`

Report exact check count/failures/exits.

## 18. Final implementation/log protocol

Claude may make focused implementation commits per work package. Do **not** stop for owner/auditor handoff between them.

After every package is complete and the final full regression suite is green:

1. record safe-sync starting SHA;
2. record every implementation commit SHA in order;
3. identify the final implementation SHA;
4. push all implementation commits;
5. create `coordination/sessions/M24-C001/CLAUDE_LOG_V01.md` in a **separate final documentation commit**;
6. log exact `SB-M24-001..030` -> code/test evidence mapping;
7. state `root TASKS.md modified = NO`;
8. state `M25-M27 implementation = NO`;
9. state `image-generation credits spent = 0`;
10. finish `AWAITING_AUDIT`.

## 19. Closure

M24 closes only when ChatGPT independently audits the final implementation and can mark every `SB-M24-001..SB-M24-030` DONE. No M25 implementation may begin before that audit.
