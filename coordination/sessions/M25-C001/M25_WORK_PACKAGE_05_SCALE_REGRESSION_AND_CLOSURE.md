# M25 Work Package 05 — Scale, Regression and Closure

Covers primarily: `SB-M25-031..032` and final closure of all `SB-M25-001..032`.

## Objective

Stress the completed M25 claim engine against production-sized boards and the full accepted gameplay stack, then produce exact audit evidence.

## A. Rectangular fixture

Create at least one non-square production-valid board with five occupied M24 slots including duplicate colors.

Using production access/routing truth, prove:

- same-color placement-sequence arbitration;
- unique target reservations;
- TargetSelector priority preserved;
- different colors coexist;
- rollback and authenticated-clear finalization affect only exact claims;
- WAITING and later re-evaluation work after board changes.

## B. 59x59 fixture

Run a 59x59 production-bound board with five occupied slots and duplicate colors.

Record:

- board cell count;
- number of claim attempts;
- accepted live claims;
- ReservationState count;
- deterministic claim order;
- reset cleanup result;
- performance sanity observation.

Do not invent an arbitrary milliseconds pass/fail threshold. Verify no obvious O(board) scan is added to the fixed five-slot batch arbitration itself beyond existing candidate/targetability/routing operations.

## C. Leak / stale / reset matrix

Directly test:

- multiple live claims reset to zero M25 claims;
- every M25-owned reservation released;
- unrelated ReservationState owner survives reset;
- M24 committed work rolled back for pre-clear live claims;
- stale old claim IDs cannot rollback/finalize after reset;
- double rollback/finalize fail closed;
- wrong/random claim IDs fail closed;
- repeated reset is safe;
- no target appears twice in live claim ledger;
- no ReservationState pair lacks its matching M25 claim among M25-owned owners;
- no M25 live claim lacks its matching M24 committed work.

## D. Full regression

Run all master-criteria validation commands, including:

- full `tests/run_tests.gd`;
- all dedicated M25 evidence;
- all M24 V01/V02 dedicated evidence;
- M23 V01/V02/V03;
- M22 V07 + V06/V05/V04/V03;
- M21 real-art smoke + V10 reservation evidence;
- representative M20 authenticated clear/lifecycle/queue-free evidence;
- `git diff --check`.

Fix regressions before handoff.

## E. Final SB-M25 ledger

In `CLAUDE_LOG_V01.md`, include a table for **every `SB-M25-001..032`** with:

- production file/function;
- direct test/evidence;
- PASS result.

Also include:

- safe-sync start SHA;
- all implementation SHAs in order;
- final implementation SHA;
- changed-file list;
- exact same-color arbitration trace;
- exact BLUE 8/14/12 trace;
- exact pre-opening/post-opening trace;
- rollback trace;
- authenticated-clear finalization trace;
- reset/leak trace;
- rectangular/59x59 traces;
- root-suite total/failures;
- `root TASKS.md modified = NO`;
- `M26/M27 implementation = NO`;
- `image-generation credits spent = 0`;
- final `AWAITING_AUDIT`.

Push implementation first. Push the log separately afterward.
