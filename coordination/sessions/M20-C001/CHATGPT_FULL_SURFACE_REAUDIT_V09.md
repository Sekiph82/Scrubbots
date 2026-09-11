# M20-C001 — Final Exact-Evidence Whole-Sprint Freeze V09

Status: **FINAL_EVIDENCE_ONLY_REQUIRED / PRODUCTION_IMMUTABLE / FINDING_SET_FROZEN**

Authority:
- repository-root `TASKS.md` as sole live tracker;
- `coordination/AUDIT_POLICY.md`, including the owner-locked whole-sprint two-pass rule;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V08.md`.

## Locked production baseline

Accepted clearing-loop blob:
`06391839523cbc27e88a4b3ef12b730012cd45fa`

Accepted dispatcher blob:
`eee10149e4f116af6706beec832042352bf3a6dd`

V09 MUST NOT commit any `scripts/**` change. If a V09 test exposes a production defect, stop BLOCKED and do not fix production.

Temporary sensitivity mutations are permitted only after the V09 tracker start push, one at a time, never committed, and must restore byte-for-byte to the blobs above before final validation.

## Why V09 exists

V08 exposed no production defect. Its final closure was blocked because several auditor-authored tests did not directly assert every property claimed by the V08 freeze/criteria.

V09 is NOT another implementation correction. It is one final exact-evidence pass that closes all known direct-observability gaps together.

## Frozen gap A — M20 owner-claim lifecycle exactness

Fresh claim arrangement must prove:
1. attach a benign diagnostic `assignment_arrived` observer BEFORE any M20 loop claims the dispatcher;
2. first CompleteClearingLoop still binds/claims successfully;
3. second different live loop fails bind;
4. second loop explicitly remains unbound, adds no M20 transaction callback, has zero clear attribution and cannot activate/reset canonical state;
5. first loop remains coherent and clears exactly once;
6. snapshot BoardState before claim/reset-only operations and prove those operations alone do not mutate it;
7. first loop reset while alive does not release/transfer the claim;
8. first loop remains usable after its reset;
9. second loop remains rejected after owner reset;
10. frame-aware: after the owner loop is genuinely GC'd, prove its exact M20 transaction callback is absent and the WeakRef does not keep the loop alive;
11. a fresh loop then binds and adds exactly one M20 transaction callback while the benign diagnostic observer remains independent.

## Frozen gap B — activation boundary exact detached snapshots

Create reusable detached snapshot helpers that ACTUALLY compare every claimed field.

Before every ordinary invalid/no-work activation snapshot:
- all BoardState cell states;
- dispatcher active count;
- dispatcher next owner id;
- exact reservation target->owner map AND count;
- all five slot tuples: palette id, available, active.

After each call assert exact equality for every applicable field.

Independently cover:
- slot -1;
- slot 5;
- non-int slot;
- unavailable slot;
- origin NaN x;
- origin NaN y;
- origin +INF;
- origin -INF;
- speed NaN;
- speed +INF;
- speed -INF;
- speed 0;
- speed negative;
- absent-color/no-target;
- fully enclosed matching candidate/no-work.

Also fresh/directly cover:
- nested activation -> REENTRANT;
- activation while arrival drain is active -> REENTRANT;
- reset during activation preflight -> RESETTING;
- reset inside M19 dispatch -> RESETTING, never stale SUCCESS;
- post-dispatch M20 coherence loss -> COHERENCE_FAILED.

For downstream reset/coherence cases where M19 legitimately consumed an owner token before the abort, explicitly prove monotonic/no-reuse rather than incorrectly requiring an unchanged next-owner counter.

## Frozen gap C — arrival-preflight exact-invariant matrix

Use fresh real ARRIVED-but-unconsumed assignments and inject through M20's arrival boundary.

### Forged identity cases
Independently run wrong owner, wrong target, wrong color, wrong source agent and unknown owner. For EACH case prove immediately after the failed preflight:
- `PREFLIGHT_REJECTED`;
- BoardState unchanged;
- cleared_count unchanged;
- exact real reservation still exists in BOTH directions;
- dispatcher real assignment still exists/pending;
- raw target candidate remains present when BoardState remains ACTIVE;
- at least one unrelated cell/candidate/reservation sentinel is unchanged where applicable.

Do not reuse one accumulated case state if doing so can hide mutation; use fresh arrangement per case or restore/prove exact prestate.

### Missing / replacement / foreign dependency cases
Freshly cover:
- missing reservation;
- same-board original `(T,O)` replaced by exact `T->O2`;
- ReservationState rebound to foreign board with a foreign replacement reservation;
- ColorCandidateIndex rebound to foreign board;
- ColorCandidateIndex `rebind(null)` neutralized/unbound;
- target already externally CLEARED;
- configured renderer rebound to a foreign board AFTER a real assignment exists but BEFORE arrival;
- configured renderer queued/dead after a real assignment exists but before arrival;
- stale replay after reset;
- duplicate current owner+agent;
- duplicate queued owner+agent isolated from the distinct-arrival FIFO case.

For replacement/foreign reservation cases assert the replacement/foreign pair survives the failed M20 preflight BEFORE reset and, where reset is then invoked, survives pair-narrow reset afterward.

For candidate drift/unbound cases assert exact reservation + dispatcher assignment remain held until explicit cleanup and cleared_count remains unchanged.

For failed-preflight cleanup prove no orphan agent remains after the authorized reset/frame cleanup.

## Frozen gap D — exact SB-M20-001..014 final ledger

V09 must contain one clearly named final ledger section with direct exact assertions.

### SB-M20-001
Healthy real-production sequence proves:
- target CLEARED;
- target absent from raw candidate bucket;
- ProductionAccessQuery OPEN;
- `get_owner(target) == -1`;
- `get_target_for_owner(owner) == -1`;
- dispatcher owner absent;
- agent queued for deletion;
- configured renderer alpha 0.

### SB-M20-002
For BOTH absent-color and enclosed matching target:
- NO_REACHABLE_TARGET;
- zero new active agent;
- zero reservation;
- zero BoardState clear/mutation.

### SB-M20-003
Continue to run the frame-aware queue_free smoke proving finalized agent actually becomes invalid and no orphan child remains. No-return remains explicit.

### SB-M20-004..006
- true 1x1 clear + exhaustion;
- one-color repeated clear to exhaustion;
- multi-color clears using corresponding slots AND direct proof that unrelated other-color raw candidate truth remains correct after each relevant clear.

### SB-M20-007
Five in-flight assignments prove:
- five unique owner IDs;
- five distinct targets;
- each pair exact in BOTH directions;
- resolving one preserves the other four exact pairs in BOTH directions;
- all five eventually finalize;
- final dispatcher active count = 0;
- final reservation count = 0.

### SB-M20-008..013
Fresh Easy, Medium, Hard, Very Hard, 59x59 and valid rectangular paths remain.

For 59x59 prove exactly the intended target changes state in the M20 operation; do not claim renderer/GPU performance from headless timing.

### SB-M20-014 / AL-028 / rapid
- direct desync matrix from gap C;
- B is explicitly proven unreachable before A clears;
- first REAL activation clears A;
- second REAL activation selects/routes B;
- B's exact reservation pair is directly proven before arrival;
- B arrival clears/finalizes;
- rapid >=25 sequential clear cycles;
- reset with multiple in-flight assignments leaves BoardState/candidate truth unchanged while active/reservation state is cleaned;
- five-slot palette/available/active tuples are snapshot before and after representative ordinary success and failure and remain unchanged.

## Frozen gap E — final rollback/reset/contention direct matrix

The V09 auditor-authored section must freshly/directly cover:
- candidate mutate-before-false with exact pre/post tuple verification;
- reservation mutate-before-false with exact pre/post reservation map verification;
- candidate true-without-postcondition;
- reservation true-without-postcondition;
- unrelated same-color candidate loss -> restored exact membership or explicit ROLLBACK_FAILED, never silent loss;
- unrelated different-color candidate preservation on healthy clear;
- reservation identity swap -> exact owner-map proof detects it;
- missing-current-pair reset does not fabricate/delete unrelated reservation;
- healthy pair-narrow reset preserves unrelated reservation;
- foreign-board replacement survives reset;
- same-board owner replacement survives reset;
- reset during candidate phase;
- reset during reservation phase;
- duplicate current arrival;
- duplicate queued arrival;
- distinct nested arrival FIFO;
- post-dispatch generation/reset barrier;
- reset re-entry remains safe;
- owner counter monotonic/no reuse.

Production exact-category gates remain read-only. Use only test harness seams already authorized; do not widen production dependency categories.

## Frozen gap F — criteria/log traceability

`CLAUDE_LOG_V09.md` must contain an explicit evidence table mapping:
- G-V08-01 owner claim;
- G-V08-02 activation snapshots;
- G-V08-03 arrival preflight;
- G-V08-04 task ledger;
- G-V08-05 rollback/reset;
- G-V08-06 traceability;
to named test functions/assertion groups and actual results.

It must explicitly distinguish:
- source/static evidence;
- root-suite runtime evidence;
- frame-smoke runtime evidence;
- sensitivity evidence.

## Sensitivity S1-S6 — rerun after exact-evidence fixes

Run one at a time after V09 start push, never commit, restore before next:

S1 consumer claim bypass -> exact V09 second-loop ownership test fails.
S2 agent_parent presence regressed to equality/null -> truly-freed parent test fails.
S3 renderer presence regressed to equality/null -> truly-freed renderer test fails.
S4 post-dispatch generation barrier weakened -> reset-inside-dispatch exact test fails.
S5 exact owner-map proof weakened -> identity-swap exact test fails.
S6 pair-narrow reset weakened to owner-wide -> foreign/same-board replacement preservation test fails.

Record exact failing assertion names/messages. Reverify both locked production blobs after every restoration and before final suite.

## Documentation

`docs/02_TECH_ARCHITECTURE.md` V08 correction is accepted. V09 must not perform drive-by documentation changes. Historical audit/prompt evidence is read-only.

## V09 allowed committed files

Allowed:
- root `TASKS.md` lifecycle fields only;
- `tests/run_tests.gd`;
- a narrow V09 frame-aware smoke if genuinely needed;
- narrow existing/new `tests/support/**` only if required for exact validation and production trust boundaries remain unchanged;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V09.md`.

Forbidden committed changes:
- ALL `scripts/**`;
- current docs unless ChatGPT later explicitly authorizes a concrete documentation defect;
- prior CHATGPT audit/prompt/criteria artifacts;
- historical tracker files.

## Final validation

Record separately:
- `godot --version`;
- full root suite exact checks/failures/result;
- `tests/m20_queue_free_smoke.gd`;
- `tests/m20_v04_lifecycle_smoke.gd`;
- `tests/m20_v05_lifecycle_smoke.gd`;
- `tests/m20_v07_lifecycle_smoke.gd`;
- `tests/m20_v08_lifecycle_smoke.gd`;
- any V09 frame smoke;
- literal final grep/inspection for `SCRIPT ERROR` and `Parse Error` in each relevant final output;
- `git diff --check`;
- exact changed-file list;
- exact final production blobs;
- committed `scripts/**` diff vs `e189ee8` empty;
- tracker final state.

## Closure disposition

V09 is intended to be the last evidence-only gate.

If all frozen evidence gaps above close, all sensitivity mutations are load-bearing, full validation is green, production remains byte-identical to the accepted V07 blobs, and no production defect is exposed, ChatGPT may issue:

`AUDITED_PASS / STRICT_V2_FINAL_CLOSURE`

and close SB-M20-001..014.

If a production defect is exposed, STOP without fixing it and return:

`BLOCKED / V09_VALIDATION_EXPOSED_PRODUCTION_DEFECT`.
