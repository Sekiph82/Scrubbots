# M29-C002 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT
Task: `SB-M29-010`

Owner authority:
`coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md`

Expected verdict if clean:

`AUDITED_PASS / OWNER TEMPO PLAYTEST REQUIRED`

## A. Canonical baseline — BLOCKING

PASS requires:

- normal Scrubbot production travel baseline = 9.0 cells/s;
- production dispatcher uses the same canonical travel baseline rather than an independently drifting old 6.0;
- normal cadence baseline = exactly/semantically 1/3 s;
- 1x factor remains 1.0;
- 2x factor remains 2.0;
- 2x cadence = 1/6 s;
- no `Engine.time_scale`.

FAIL for hiding old baseline under factor 1.5/3.0 while pretending the user-facing factor is unchanged.

## B. Effective tempo — BLOCKING

Direct runtime proof must show:

- 1x effective travel = 9 cells/s;
- 2x effective travel = 18 cells/s;
- 2x / 1x ratio = 2;
- 1x cadence = 1/3 s;
- 2x cadence = 1/6 s.

Constants alone are insufficient.

## C. Current/future agents + pause

PASS requires:

- already-moving agents react correctly to 1x/2x switch;
- newly spawned agents inherit the canonical 9 cells/s base;
- pause freezes travel/cadence;
- resume preserves selected speed.

## D. Frame-budget safety

PASS requires `MAX_LANES_PER_FRAME = 1` or a proven equivalent one-lane/frame safety invariant.

At 60 FPS + six lanes:
- no overlapping wave;
- no storm;
- nominal 2x cadence is serviceable.

At 30 FPS + six lanes:
- it is acceptable for full-wave throughput to be service-limited to ~0.20 s;
- no test should demand impossible six-lane completion in 1/6 s;
- no second wave starts while previous lanes remain;
- backlog remains bounded/dropped;
- no duplicate claim/clear.

FAIL for raising lane-per-frame budget solely to chase nominal cadence without an explicit separate owner decision.

## E. Gameplay truth equivalence

PASS requires 1x and 2x to produce identical deterministic gameplay truth:

- target assignment/order;
- routes/target identity;
- claims/reservations;
- clears;
- quota/accounting;
- final board state;
- completion result.

Only timing may differ.

## F. Existing 2x authorities preserved

PASS requires:

- paid current-level 2x -> new effective 18 cells/s;
- timed 2x -> new effective 18 cells/s;
- cross-level/relaunch timed auto-start still works;
- manual 1x during active timed entitlement -> new effective 9 cells/s for current attempt;
- timed expiry -> 9 cells/s unless M23 free auto-2x is active;
- M23 supply-exhausted auto-2x -> 18 cells/s;
- prices/durations/scopes unchanged.

## G. Reset

Without timed entitlement:

- reset/new attempt factor = 1.0;
- travel = 9 cells/s;
- cadence = 1/3 s.

## H. Performance / 59x59

PASS requires representative dense/59x59 evidence showing:

- no dispatch storm;
- no runaway pending-wave backlog;
- no duplicate clears;
- no correctness regression;
- no major performance regression caused by the higher tempo.

M55 long-session must pass.

## I. Regression / governance

FAIL if Claude edits root `TASKS.md`.

Required relevant suites:
- M29;
- M28;
- M30;
- M39;
- M40–M43;
- M52;
- M55;
- routing/clearing/solver;
- root suite;
- `git diff --check`.

Only previously documented unrelated baseline failures may remain, with exact signatures.

## J. Documentation

PASS requires current production comments/docs touched by this feature to stop claiming old 6/12 cells/s or 0.5/0.25 cadence as current production truth.

Historical audit/evidence files must remain historical.

## K. Owner gate

Technical PASS does not close SB-M29-010.

Owner playtest checks only gameplay feel:

1. new 1x feels appropriately faster than the old normal;
2. new 2x feels like exactly twice the new normal, not an uncontrolled jump;
3. no visible dispatch burst/stutter at five/six occupied slots.

Only owner acceptance closes SB-M29-010.
