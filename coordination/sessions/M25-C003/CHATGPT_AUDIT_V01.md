# M25-C003 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`
Parent: `ed61b1eba0fe1a2d708cf5cb6a04d30f534e2082`
Prompt: `coordination/sessions/M25-C003/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M25-C003/CHATGPT_AUDIT_CRITERIA_V01.md`
Task: `SB-M25-034`

## Verdict

**AUDITED_PASS / S2_ROUTING_PERF_REQUIRED_BEFORE_M29_OWNER_PLAYTEST**

S0 + S1 are accepted.

The implementation fixes the contaminated 59x59 performance harness and introduces an exact-safe, order-preserving target prefilter that materially reduces the real WHAT-side scan cost without changing target choice, reservation truth, dispatch order, or gameplay completion.

However, the remaining winning-route Railroad Dijkstra still exceeds a 60 FPS frame budget by a material margin on the full laid-out 59x59 reproduction.

Therefore:

- SB-M25-034 is CLOSED;
- SB-M29-010 remains OPEN;
- owner tempo feel-playtest remains deferred;
- open a separate exact-equivalent S2 routing-performance cycle;
- after S2, remeasure full laid-out 59x59 and then decide M29 owner playtest/closure.

## A. S0 laid-out harness

**PASS.**

The M29-C002 s8 performance fixture now:

- uses a real 1080x2160 SubViewport;
- settles frames before/after build and relayout;
- re-settles after +1 Slot;
- disables runtime auto processing before measurement;
- resets deterministic runtime cadence phase;
- asserts every measured slot origin is finite and outside/below the board.

Evidence reports all 59x59 slot origins around:

`y = 72.75 / 72.78`

for a board height of 59.

The prior UNLAID y=0 geometry remains historical evidence only.

This closes the original false multi-second performance conclusion caused by board-internal origins.

## B. Touch-mask exactness

**PASS.**

`ProductionTargetAccess` now materializes:

- `reach`: perimeter-connected CLEARED cells;
- `touch`: perimeter cells OR cells adjacent to `reach`.

The mask remains owned by the access layer, not TargetSelector.

The focused suite compares the materialized predicate against the pre-C003 necessary-condition implementation across:

- 16 boards;
- 288 board states;
- 2,094,180 index checks;
- 20x20, 32x32, 33x33, 38x38, rectangular and 59x59;
- first-10 production levels;
- multiple outside origins;
- restore/retry states.

Result:

- mismatches: 0;
- false negatives: 0.

Inside-board, non-finite and invalid-index cases return unsupported/null rather than unsafe false.

## C. WHAT/HOW separation

**PASS.**

TargetSelector does not:

- inspect rail geometry;
- inspect CLEARED topology;
- build a mask;
- compute route cost;
- reorder candidates.

It only asks the existing access object whether an optional conservative necessary condition returns exact bool false.

Canonical order remains:

bottom-most -> left-most -> index.

A bool true is never treated as success; the existing authoritative `is_targetable()` path still runs.

This preserves WHAT/HOW separation.

## D. Optional capability fallback / strict behavior

**PASS.**

The selector:

- checks optional capability presence;
- skips only exact TYPE_BOOL false;
- missing capability -> old full path;
- malformed return -> old full path;
- true -> old full path.

Focused adversarial coverage includes:
- missing capability;
- malformed values;
- always-true capability;
- a false on the would-be winner;
- prefilter callbacks attempting reservation/rebind/re-entrant selection.

Existing M15/M19 strict behavior remains intact.

## E. Transaction/coherence truth

**PASS.**

For candidates that reach the strict body, the original sequence remains unchanged:

- board validity/state/color;
- reservation read;
- coherence checks;
- authoritative is_targetable;
- owner re-check;
- reserve;
- exact ownership proof;
- rollback.

No claim/reservation production file changed.

No scheduler or batch-accounting semantics changed.

## F. Filtered vs unfiltered identity

**PASS.**

Focused differential evidence:

- 3,744 selection transactions;
- 1,048 no-target results;
- 0 winner differences;
- 0 no-target differences;
- 0 ReservationState differences.

Full laid-out 59x59:

- prefilter path;
- capability-hidden baseline path;
- plain production path

all produce:

- 3481/3481 clears;
- WON;
- identical dispatch target/color sequence;
- identical authenticated clear order;
- identical final board;
- zero duplicate dispatch;
- zero duplicate clear;
- zero residual claims/reservations/agents/live work.

Before-vs-after timing probes also report identical dispatch hashes at 1x and 2x.

## G. Work-count bounds

**PASS.**

Full laid-out 59x59:

- 5177 lanes;
- max candidates/lane: 590;
- max compute_route/lane: 1;
- failed route probes: 0;
- impossible candidates entering strict body: 0;
- strict-body max iterations/lane: 1;
- max lanes/frame: 1.

This is substantially stronger than the required touchable+winner bound.

The selector's strict work is therefore now effectively winner-only on this fixture.

## H. Revision / board identity invalidation

**PASS.**

The reach/touch cache is:

- keyed by exact BoardState instance id + revision;
- a bounded single-slot static cache;
- rebuilt on clear/revision change;
- rebuilt after restore/retry;
- never reused across a different BoardState with the same dimensions/revision number;
- shareable across access instances for the exact same board+revision.

`BoardState.get_cell_states_copy()` returns a detached read-only snapshot and does not mutate authority.

## I. Tempo / scheduler isolation

**PASS.**

M29 tempo remains unchanged:

- 1x travel 9 cells/s;
- 2x travel 18 cells/s;
- 1x cadence 1/3 s;
- 2x cadence 1/6 s;
- one lane/frame unchanged.

Corrected laid-out M29 evidence passes.

No economy/entitlement change.

## J. Timing result

### WHAT-side S1 result

**PASS / target achieved.**

Same-machine before/after:

- 2x scan excl. route p99: 5.62 -> **1.78 ms**;
- 1x scan excl. route p99: 5.90 -> **1.82 ms**.

Focused production timing also reports:

- 2x scan p99: 2.19 ms;
- 1x scan p99: 1.80 ms.

This meets the <=3 ms S1 target.

### Remaining HOW-side hotspot

**BLOCKS M29 owner playtest until S2 is audited.**

The untouched winning-route Railroad Dijkstra remains the dominant cost:

Same-session before/after report:
- 2x Dijkstra p99 ~27.7 ms, max ~39.5 ms;
- 1x Dijkstra p99 ~33.1 ms, max ~57.3 ms;
- frame max ~51.8 ms at 2x;
- frame max ~74.0 ms at 1x.

Focused full-level production evidence similarly reports route/Dijkstra p99 around the high-20/low-30 ms range.

A 60 FPS frame budget is ~16.7 ms.

This is a genuine real-layout runtime cost, not the previous harness artifact.

It is not caused by the tempo retune, but the project explicitly targets dense boards up to 59x59 and the owner intends future larger boards. Leaving a synchronous p99 route cost materially above the frame budget before approving a faster gameplay tempo is not acceptable.

Therefore S2 routing acceleration is required before SB-M29-010 owner feel-playtest.

## K. Regression / governance

**PASS.**

Submitted regression:
- 115 suites;
- 113 exit 0;
- root 5323/5323 PASS;
- M55 long-session PASS;
- M15/M19 strict PASS;
- M25/M26/M29/M30/M39/M52/routing suites PASS;
- git diff --check clean.

Only non-zero suites:
- m21_v08_corridor_validation;
- m21_v09_direct_evidence_reconciliation.

Signatures match the documented historical baseline.

Claude did not edit root `TASKS.md`.

No S2 route optimization or D2 shipping guard was implemented.

## S2 authorization

Open a new cycle for exact-equivalent Railroad route acceleration.

Hard rule:

**The optimized route must be point-for-point identical to the current production route for the same request/board/access state.**

S2 may optimize HOW only.

It must not alter:
- target winner;
- railway-first priority;
- interior-step semantics;
- side/seq tie-break;
- connector;
- rail entry/exit;
- route points;
- claims/reservations;
- gameplay tempo.

The implementation must include a frozen/baseline route oracle or equivalent differential harness that compares current vs optimized route points across broad randomized and real states.

## Final

**AUDITED_PASS / S2_ROUTING_PERF_REQUIRED_BEFORE_M29_OWNER_PLAYTEST**
