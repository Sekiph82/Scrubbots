# M25-C004 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `eb16c2f1e082f9c2449e4ac98840a6f68f483126`
Parent: `7e1c2b4f75a079272cffb48e1c47c3d05d2bda9f`
Prompt: `coordination/sessions/M25-C004/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M25-C004/CHATGPT_AUDIT_CRITERIA_V01.md`
Task: `SB-M25-035`

## Verdict

**AUDITED_PASS / RETURN_TO_M29_OWNER_TEMPO_PLAYTEST**

S2 exact-equivalent Railroad acceleration is accepted.

The optimized production route is point-for-point identical to the frozen pre-S2 `aadc5725...` baseline across the submitted broad differential matrix, while the real laid-out 59x59 route hotspot is reduced well below the required performance gates.

SB-M25-035 is CLOSED.

SB-M29-010 may now return to the OWNER feel/playtest gate.

## A. Frozen baseline oracle

**PASS.**

`tests/support/m25_c004_railroad_baseline.gd` is explicitly marked test-only and identifies:

`aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`

as its frozen pre-S2 source.

The file is not part of the shipping runtime path.

The differential suite uses this frozen script as its reference implementation.

## B. Point-for-point route identity

**PASS.**

Submitted differential report:

- total comparisons: **48,202**;
- successes compared: 37,902;
- failures compared: 10,300;
- route points compared: 228,983;
- diffs: **0**.

Equality checks include:
- success;
- failure reason;
- target index;
- point count;
- `PackedVector2Array.to_byte_array()` equality.

Therefore route-point equality is byte-exact, not merely geometric/visual equivalence.

## C. Differential breadth

**PASS.**

Coverage includes:

- production levels 1..10;
- 20x20, 32x32, 38x38, 59x59 and rectangular boards;
- 477 generated board states;
- ring peel, random, rooms/corridors, stripes, horizontal bands, sparse late-game, checkerboard, bottom-up peel, open/walled areas;
- six production-like slot origins;
- top/left/right/corner outside origins;
- inside-board debug origins;
- equal-weight mode;
- multiple other tuning values;
- canonical and noncanonical access objects;
- board subclass;
- near-tie/corridor tie cases.

Mutation checks prove the suite is load-bearing:

- remove per-layer sort -> 179 diffs;
- reverse side priority -> 7 diffs;
- disable near-tie guard -> 18 diffs.

## D. Railway-first / tie-break preservation

**PASS.**

The fast path is gated to the canonical production configuration and reconstructs the same minimum-interior-step route under the existing ranking rules.

The generic baseline path remains in production as fallback.

The exact near-tie guard is load-bearing and returns to generic Dijkstra when the layered ordering cannot safely reproduce the epsilon-sensitive baseline ordering.

No owner route-choice rule is changed.

## E. Equal-weight / noncanonical fallback

**PASS.**

Fast path requires:

- exact `ProductionAccessQuery`;
- exact `BoardState`;
- `interior_step_cost == INTERIOR_STEP_COST`.

Therefore:

- `TOTAL_TRAVEL_COST = 1.0` uses generic Dijkstra;
- other tunings use generic Dijkstra;
- access subclasses/wrappers use generic Dijkstra;
- board subclass uses generic Dijkstra;
- inside-board starts remain on the pre-existing interior planner;
- near-tie guard trips use generic Dijkstra.

Differential coverage reports 22,633 generic-path comparisons with zero diffs.

## F. Real-host gameplay truth

**PASS.**

Full laid-out 59x59 evidence at 1x and 2x confirms:

- all 3,481 dispatch routes match frozen baseline point-for-point;
- same dispatch sequence;
- same authenticated clear sequence;
- same final board;
- 3481/3481 cleared;
- WON;
- no duplicate dispatch;
- no duplicate clear;
- zero residual live work/claims/reservations;
- failed route probes: 0;
- compute_route <=1/lane;
- one lane/frame preserved.

## G. S1 preservation

**PASS.**

The prior target-prefilter improvement remains intact.

Primary clean session:

- 2x scan excl route p99: ~1.33 ms;
- 1x scan excl route p99: ~1.32 ms.

M25-C003 standalone on final code reports approximately:
- 2x scan p99 1.52 ms;
- 1x scan p99 1.54 ms.

Thus the <=3 ms S1 target remains satisfied in the clean gate session.

A separate slow-machine session shows the selector scan >3 ms for both oracle and optimized paths while the entire machine is ~2.5x slower. This does not indicate an S2 regression because the same-session baseline and optimized scan times move together and S2 does not touch selector scan code.

## H. Performance gate

**PASS by large margin.**

Primary clean same-session A/B:

### 2x

- route_dijkstra p99: ~24.76 ms -> **0.252 ms**;
- winner-route p99: ~26.67 ms -> **0.515 ms**;
- frame p99: ~29.3 ms -> **4.68 ms max across optimized rounds**;
- optimized frame max: <=6.97 ms.

### 1x

- route_dijkstra p99: ~24.63 ms -> **0.252 ms**;
- winner-route p99: ~26.60 ms -> **0.506 ms**;
- frame p99: ~27.4 ms -> **4.08 ms**;
- optimized frame max: <=5.92 ms.

Route-time p99 reduction is approximately **99%** at both speeds.

Required gates:

- route_dijkstra p99 <=8 ms: PASS;
- frame p99 <=20 ms: PASS;
- >=50% p99 route reduction: PASS;
- route-caused frame max <=33.3 ms: PASS.

Even the separately reported slow clean session keeps S2 route/frame gates within limits.

## I. Work-count explanation

**PASS.**

The optimized layered search materially reduces work rather than hiding time.

Per route, frozen Dijkstra approximately:

- mean heap pops 1186.6;
- p99 heap pops 3172;
- mean neighbour checks 4572;
- p99 neighbour checks 12459.

Optimized layered path approximately:

- one board snapshot;
- mean reverse BFS expansion 150 cells;
- p99 reverse expansion 880;
- mean critical ingress sources ~1.02;
- mean forward sweep ~12 cells.

Reported baseline-pop / optimized-work ratio is roughly:
- mean 31.5x;
- p99 174x.

No cross-call route cache is introduced.

## J. Tempo / scheduler isolation

**PASS.**

M29 tempo remains:

- 1x = 9 cells/s;
- 2x = 18 cells/s;
- cadence = 1/3 s / 1/6 s;
- one lane/frame.

No TargetSelector, claim/reservation, economy, entitlement or scheduler semantic change is present in the S2 production scope.

## K. Regression / governance

**PASS.**

Submitted:

- 115 suites;
- 113 exit 0;
- root 5323/5323 PASS;
- M25-C003 focused PASS;
- M29-C002 tempo PASS;
- M25-C004 differential PASS;
- M25-C004 host truth PASS;
- M55 long session PASS;
- git diff --check clean.

Only non-zero suites:

- `m21_v08_corridor_validation`;
- `m21_v09_direct_evidence_reconciliation`.

These match the documented historical baseline signatures.

Claude did not edit root `TASKS.md`.

## M29 disposition

All technical performance blockers discovered during M29-C002 are now resolved or correctly reclassified:

1. original multi-second 59x59 stall:
   - caused by UNLAID harness geometry;
   - corrected by S0;

2. WHAT-side candidate scan:
   - reduced by S1;
   - clean-session p99 below 3 ms;

3. HOW-side Railroad route:
   - reduced by S2;
   - clean-session p99 ~0.25 ms;
   - point-for-point identity preserved.

Therefore SB-M29-010 returns to OWNER for final gameplay feel/playtest.

Owner only needs to judge:

1. new 1x pacing;
2. new 2x pacing;
3. whether dense 5/6-slot gameplay feels visually smooth, with no obvious dispatch burst/stutter.

## Final

**AUDITED_PASS / RETURN_TO_M29_OWNER_TEMPO_PLAYTEST**
