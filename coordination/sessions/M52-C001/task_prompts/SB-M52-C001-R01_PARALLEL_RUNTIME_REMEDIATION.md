# SB-M52-C001-R01 — PARALLEL RUNTIME REMEDIATION

Status: READY FOR CLAUDE
Date: 2026-09-26
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M52-C001/OWNER_PLAYTEST_FINDINGS_V01.md`
4. `coordination/OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01.md`
5. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
6. `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
7. `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`
8. current M52 owner supply plans/evidence
9. M24/M25/M26/M27 runtime + solver code
10. current M39 economy/speed entitlement code
11. current M30 completion/deadlock code
12. current gameplay UI slot/speed controls

Do NOT edit root `TASKS.md`. ChatGPT owns tracker updates after audit.

## Mission

Remediate the owner-blocking gameplay feel issues before M53:

1. make each occupied slot an independent dispatch lane;
2. support a deterministic parallel dispatch wave of up to 5/6 Scrubbys per cadence;
3. ensure slot count visibly decrements on successful dispatch/departure, not target clear;
4. eliminate the silent 2x button no-op by routing no-entitlement input into the real acquisition flow;
5. profile and remove the observed Level 2 micro-stutters without weakening gameplay correctness;
6. re-prove the First 10 content/runtime after the engine behavior change.

This is a real production-engine change. Do not patch presentation to fake concurrency.

## A. Baseline and reproduction

Before changing code:

- sync main;
- record baseline HEAD;
- run focused M24–M30, M39, M40, M42 and M52 suites;
- run root regression;
- reproduce Level 2 through the real AppState/catalog/host path;
- place five 30-count C08/BLUE batches into the five slots using the accepted Apple plan or an exact deterministic fixture;
- capture baseline evidence showing the current same-color serialization;
- capture current 2x no-entitlement behavior;
- instrument recurring frame/runtime spikes around the owner-observed stutter.

Store evidence under:
`coordination/sessions/M52-C001/remediation/R01/evidence/`

## B. M25 exact slot-claim seam

Add a production-quality slot-specific claim path.

Requirements:
- claim exact `slot_index`, not "oldest batch of this color";
- slot must be occupied and have dispatch capacity;
- derive color and batch identity from M24, never caller UI data;
- use that slot's exact `ProductionTargetAccess`;
- reserve one unique target through existing TargetSelector/ReservationState;
- commit exactly one opaque M24 work identity;
- preserve rollback/finalize exact identity guarantees;
- no target => WAITING for that slot only;
- malformed/foreign access => fail closed.

Keep legacy color-facing methods only if still needed for historical tests/API compatibility; production scheduling must use the slot-specific authority.

## C. M26 parallel cadence wave

Replace the global one-assignment cadence policy with one deterministic dispatch wave.

At one cadence event:
- enumerate eligible occupied slots ordered by placement sequence, physical slot index tie-break;
- attempt at most one new assignment from each eligible slot;
- baseline wave can create 0..5 agents;
- +1 Slot wave can create 0..6;
- one failure/waiting slot must not abort healthy sibling slots;
- same-color sibling slots are independent;
- each accepted target/reservation/claim/agent remains unique;
- no slot gets two assignments in the same wave;
- no uncontrolled recursive burst;
- pause/reset/focus/terminal safety remains exact.

Replace global `_waiting_colors` semantics with per-slot waiting or an equivalently correct slot-specific mechanism.

The exact owner acceptance fixture:
- five occupied BLUE/C08 batches;
- each initial count 30;
- at least five legal targets;
- one wave;
- exactly five live assignments;
- each assignment comes from a different occupied slot/batch;
- every target unique;
- every batch display count becomes 29 before any of those five targets clears.

## D. Counter semantics

Do NOT weaken M24 accounting.

Keep:
- remaining_to_clear decremented on authenticated clear only;
- committed increment on exact accepted work;
- rollback committed on pre-clear cancellation/failure.

Player-facing count must remain `remaining - committed`.

Prove with a real runtime test:
1. place a 30 batch;
2. dispatch one Scrubby;
3. before its target clears, snapshot slot/UI;
4. assert authoritative remaining=30, committed=1, displayed count=29;
5. after clear: remaining=29, committed=0, displayed count stays 29;
6. rollback-before-clear restores display count to 30.

For the five-BLUE fixture, assert all five counters go 30 -> 29 in the same cadence wave.

## E. 2x interaction

Current engine speed factor behavior is retained.

Fix the shipping UI behavior:

- entitled + currently 1x => press -> 2x;
- entitled + currently 2x => press -> 1x;
- no manual entitlement + press => open functional 2x acquisition popup, never silent no-op.

Functional popup must use live Godot UI and existing production actions:
- current level: 200 SB;
- 15m: 300 SB;
- 30m: 500 SB;
- 60m: 750 SB;
- Cancel/close.

On successful purchase:
- durable save via `ProductionActionFacade`;
- immediately set gameplay to 2x;
- update button state;
- timed remaining/entitlement truth remains authoritative.

On insufficient SB / cancel / failure:
- no spend;
- no entitlement;
- speed unchanged;
- visible error/unavailable feedback.

Do not invent a final art style. Mark this as functional production UI pending M43 visual master/polish.

Free authoritative supply-exhausted auto-2x remains unchanged and must still work without purchase.

## F. Stutter investigation/remediation

Add bounded debug/perf instrumentation sufficient to attribute main-thread spikes.

Measure at minimum:
- M26 dispatch-wave total;
- per-slot M25 claim;
- target selection;
- routing;
- dispatcher spawn;
- agent drive/arrival;
- renderer update;
- completion `on_tick`;
- M27 classifier/proof;
- UI snapshot sync.

Use Level 2 production runtime at both 1x and 2x.

Do not accept "probably fixed".

Identify the dominant cause in the log. Then implement the smallest safe correction.

If M27 deadlock proof is running in an interactive hot path, preserve exact terminal correctness while removing unnecessary repeated heavy proof from active play. If routing/renderer/etc. is dominant, fix that subsystem instead. No behavior-changing shortcut without tests.

Performance acceptance:
- no recurring owner-visible hitch in the Level 2 production sequence;
- no unbounded per-frame catch-up;
- no frame performs an accidental multi-wave storm;
- report before/after timing evidence, with hardware/run context.

## G. M27 proof/runtime consistency

Review `ProofKernel`, `DeadlockClassifier`, `SolvabilitySolver` and comments/tests.

The old proof kernel explicitly documents color-serialized M26 equivalence. That wording/behavior may no longer be true.

Update the proof model or provide a rigorous conservative linearization.

Required guarantees:
- no production level is admitted solely by a proof schedule impossible under the new runtime;
- parallel reservations/slot origins are represented correctly enough to prevent false SOLVED;
- runtime DEADLOCK cannot be introduced by stale old arbitration assumptions.

Re-run canonical First 10 proof/replay evidence after the change.

## H. Required focused tests

Create/update focused tests covering at minimum:

- five same-color 30-count slots -> first cadence wave produces five live agents, one per slot;
- 5 different colors -> one per eligible slot in same wave;
- one WAITING slot does not block siblings;
- unique target/reservation/claim/agent identities;
- no slot gets two new assignments per wave;
- +1 Slot allows six lanes and never seven;
- departure-time display count;
- rollback restores display count;
- pause freezes waves/travel;
- focus suspend/resume safe;
- Retry/reset cancels/cleans all live parallel assignments transaction-safely;
- Tornado selected-color cancellation with multiple same-color in-flight agents remains coherent;
- terminal cardinality checks support N concurrent assignments;
- 2x doubles travel and halves wave cadence;
- no-entitlement 2x opens purchase flow;
- successful current-level/timed purchase activates 2x and persists correctly;
- cancel/insufficient SB spends nothing;
- free supply-exhausted auto-2x still works;
- M52 Levels 2–10 still load exact owner queues;
- every owner click sequence still reaches WON through production runtime;
- Level 1 remains unchanged;
- frontier 11 remains CONTENT_MISSING.

## I. Regression

Run relevant historical suites from M23 through M42 plus:
- current `tests/m52_owner_supply_plans.gd`;
- new R01 focused suite(s);
- root `tests/run_tests.gd`;
- `git diff --check`.

Existing accepted tests that encode the now-superseded "one assignment globally per cadence" or "oldest same-color batch monopolizes dispatch" rule must be updated honestly, not bypassed.

No new SCRIPT ERROR or unexplained engine ERROR.

## J. Deliverables

Commit and push to main.

Create:
`coordination/sessions/M52-C001/remediation/R01/CLAUDE_LOG_V01.md`

Log must include:
- baseline/final SHA;
- exact changed rule surfaces;
- five-BLUE before/after evidence;
- counter departure evidence;
- 2x acquisition evidence;
- stutter root cause;
- before/after performance timings;
- solver/proof consistency decision;
- First 10 re-proof/replay/runtime results;
- all tests;
- git status.

Final handoff label:

`AWAITING_CHATGPT_AUDIT / M52-C001-R01 PARALLEL RUNTIME REMEDIATION`

Do not edit TASKS.md.
