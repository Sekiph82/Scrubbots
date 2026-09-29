# M25-C004 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT
Task: `SB-M25-035`

Expected verdict if clean:

`AUDITED_PASS / RETURN_TO_M29_OWNER_TEMPO_PLAYTEST`

## A. Frozen baseline oracle — BLOCKING

PASS requires a test-only pre-S2 Railroad oracle sourced from commit:

`aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`

It must not be loaded by shipping runtime.

FAIL if the oracle is modified to mirror the new implementation after differences appear.

## B. Point-for-point route identity — BLOCKING

Across the required broad matrix, optimized vs frozen baseline must match:

- success/failure;
- failure reason;
- target index;
- point count;
- every route point, same order and coordinates.

Require >=10,000 deterministic comparisons with zero diffs unless the audit verifies an even stronger exhaustive equivalent matrix.

"Same target" or "same route length" is insufficient.

## C. Railway-first / tie-break preservation — BLOCKING

Preserve exactly:

- minimum interior-step priority;
- connector + rail + ingress secondary cost;
- BOTTOM -> LEFT -> RIGHT -> TOP;
- same-side sequence;
- deterministic interior tie behavior;
- same rail exit;
- same returned collinear-collapse result.

## D. Equal-weight / noncanonical fallback — BLOCKING

`interior_step_cost = TOTAL_TRAVEL_COST` must remain exact.

If S2 uses a specialized production fast path, preconditions must be explicit.

Noncanonical access objects and inside-board/debug paths must preserve the generic baseline semantics unless separately proven exact.

## E. Gameplay truth

Full laid-out 59x59 requires:

- identical actual route points per dispatch;
- identical dispatch target/color sequence;
- identical clear sequence;
- identical final board;
- 3481/3481;
- WON;
- zero duplicates;
- zero residue.

## F. S1 preservation

PASS requires:

- selector scan excl route p99 <=3 ms;
- compute_route <=1/lane;
- failed route probes =0;
- no TargetSelector/ProductionTargetAccess truth regression.

## G. Performance — BLOCKING

Clean same-session 59x59 baseline vs optimized:

- route_dijkstra p99 <=8 ms;
- frame p99 <=20 ms;
- >=50% p99 route-time reduction;
- route-caused frame max <=33.3 ms.

If absolute timing is contaminated, rerun clean.

If point identity passes but performance misses, verdict is FAIL/BLOCKED, not PASS.

## H. Work-count explanation

Evidence must explain why it is faster using work counters or equivalent exact instrumentation.

No unbounded cache.

Any cache/pre-pass must be keyed/invalidate correctly by board identity/revision and routing mode.

## I. Tempo/scheduler isolation

M29 remains:
- 9 / 18 cells/s;
- 1/3 / 1/6 s cadence;
- one lane/frame.

No entitlement/economy change.

## J. Regression / governance

FAIL if Claude edits `TASKS.md`.

Required relevant regressions:
- M15/M19;
- M22;
- M25/M26/M27;
- M28 railway-first;
- M29;
- M30;
- M36/M53 equal-weight/difficulty;
- M39;
- M52;
- M55;
- root;
- `git diff --check`.

Only known historical m21_v08/v09 baseline signatures may remain.

## K. M29 disposition

If A-J PASS:

`AUDITED_PASS / RETURN_TO_M29_OWNER_TEMPO_PLAYTEST`

Then ChatGPT moves SB-M29-010 back to OWNER for feel/playtest:
1. new 1x feel;
2. new 2x feel;
3. visible burst/stutter check on dense 5/6-slot play.

If S2 performance fails, M29 remains blocked.
