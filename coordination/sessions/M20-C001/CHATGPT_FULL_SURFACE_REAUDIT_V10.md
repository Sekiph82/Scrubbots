# M20-C001 — Final Closure-Only Evidence Freeze V10

Status: **VALIDATION_ONLY / PRODUCTION_IMMUTABLE / FINAL_RESIDUAL_SET_FROZEN**

Authority:
- root `TASKS.md` only;
- `coordination/AUDIT_POLICY.md`, including owner-locked whole-sprint two-pass rules;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V09.md`.

## Locked production

CompleteClearingLoop blob:
`06391839523cbc27e88a4b3ef12b730012cd45fa`

ScrubbotDispatcher blob:
`eee10149e4f116af6706beec832042352bf3a6dd`

Committed changes under `scripts/**` are forbidden.

## Why V10 exists

V09 found no production defect and materially closed the V08 evidence gaps. The independent 279-criterion reconciliation found six residual direct-observability gaps where V09 test labels/log claims were broader than the exact assertion actually present. V10 is not a new implementation cycle. It is the one batched closure-only reconciliation pass for all six known gaps.

## Frozen set

### G-V09-01 — claim/reset actual usability + claim-only state preservation

Fresh arrangement with at least two reachable targets:
1. diagnostic listener exists before first M20 bind;
2. owner loop binds and clears target A;
3. capture detached BoardState + exact reservation map/count;
4. owner loop `reset()`;
5. snapshots unchanged by reset when no active work exists;
6. second different loop still cannot claim;
7. original owner loop performs a SECOND real `activate_slot()`/arrival and clears B;
8. cleared_count advances exactly by one more;
9. claim remains single-owner throughout.

### G-V09-02 — activation serialization exactness

Fresh direct cases:
- nested activation during activation preflight -> REENTRANT;
- record owner counter before outer call and prove exactly one owner token total is consumed by successful outer dispatch, never a second token for rejected nested activation;
- create real assignment A, enter its arrival transaction through a candidate/reservation harness hook, and call `activate_slot()` for another slot while `_draining` is active;
- that inner activation must return REENTRANT and create no second active assignment, reservation, or owner token from the inner request;
- outer arrival completes/rolls back according to the arranged healthy case and the loop remains usable.

### G-V09-03 — exact failed-preflight preservation matrix

Table-driven fresh cases for:
- missing reservation;
- candidate rebind(foreign);
- candidate rebind(null);
- externally CLEARED target;
- renderer foreign after assignment before arrival;
- renderer queued after assignment before arrival;
- truly-freed configured renderer before arrival (frame smoke).

For every applicable case directly assert:
- expected rejection/no-clear outcome;
- cleared_count unchanged;
- original BoardState state as arranged;
- exact reservation `target->owner` AND `owner->target` when the pair should remain;
- dispatcher owner still pending when preflight must hold the assignment;
- raw target candidate remains present when target is still ACTIVE and candidate layer is healthy;
- unrelated sentinel truth remains unchanged where arranged.

After an authorized reset of one failed-preflight held assignment, frame smoke must prove the agent is actually destroyed and no orphan child remains.

### G-V09-04 — exact ledger identity

SB-M20-007:
- after first arrival directly prove BOTH first pair directions are absent;
- prove the other four remain exact in BOTH directions;
- then finalize all five.

SB-M20-008..013:
- for Easy/Medium/Hard/Very Hard/59x59/rectangular, record expected target index;
- successful M20 sequence;
- directly assert expected target is CLEARED;
- assert total CLEARED delta is exactly +1.

### G-V09-05 — detached exact rollback prestate

Candidate mutate-before-false fresh arrangement with unrelated same-color and different-color cells:
- snapshot full BoardState states;
- snapshot relevant candidate buckets detached;
- snapshot exact reservation map/count;
- snapshot dispatcher active/owner identity;
- run fault;
- require CANDIDATE_ROLLBACK or explicit ROLLBACK_FAILED;
- on CANDIDATE_ROLLBACK every snapshot must match exactly.

Reservation mutate-before-false fresh arrangement with at least one unrelated reservation:
- snapshot full target->owner map/count and owner->target reverse identity for every arranged pair;
- snapshot BoardState and dispatcher identities;
- run fault;
- require RESERVATION_ROLLBACK or ROLLBACK_FAILED;
- on RESERVATION_ROLLBACK every snapshot must match exactly.

### G-V09-06 — failed-preflight cleanup/no-orphan + final mapping

Frame-aware case:
- produce a real assignment;
- force a preflight failure that intentionally leaves assignment/reservation held;
- call authorized loop reset;
- process real SceneTree frames;
- prove agent invalid/freed;
- prove no orphan child;
- prove only the original assignment/pair was cleaned.

`CLAUDE_LOG_V10.md` must include a G-V09-01..06 evidence table with exact assertion names/results.

## Already accepted, do not broaden scope

Do not redesign or retest from scratch merely for volume:
- production source remains locked;
- V09 ordinary invalid/no-work exact snapshots accepted;
- V09 forged identity five accepted;
- agent_parent and renderer category/liveness laws accepted;
- T->O2/foreign reservation survival accepted;
- SB-M20-001..006 accepted;
- AL-028 B-unreachable and second real activation accepted;
- rapid/reset-multiple accepted;
- S1-S6 load-bearing sensitivity accepted.

V10 may rerun all regressions but should add only the narrow assertions above.

## Final validation

After V10 tests exist:
- verify production blobs unchanged;
- full root suite;
- queue_free smoke;
- V04/V05/V07/V08/V09 lifecycle smokes;
- new V10 smoke if created;
- inspect literal SCRIPT ERROR / Parse Error;
- `git diff --check`;
- exact changed files;
- committed scripts diff vs `e189ee8` must be empty.

No new sensitivity mutation is required because V10 changes no production mechanism and V09 already executed S1-S6 against the locked blobs. If Claude chooses to rerun sensitivity, it must remain temporary/restored/uncommitted.

## Closure disposition

If G-V09-01..06 all pass, production remains exact, and no production defect appears, ChatGPT may issue `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` and close SB-M20-001..014.

If any new test exposes a production defect, STOP `BLOCKED / V10_VALIDATION_EXPOSED_PRODUCTION_DEFECT`; do not fix production.