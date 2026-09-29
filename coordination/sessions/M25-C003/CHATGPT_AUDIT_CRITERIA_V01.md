# M25-C003 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT
Task: `SB-M25-034`

Expected verdict if clean:

`AUDITED_PASS / PERF_REMEASURE_DECISION_REQUIRED`

## A. S0 laid-out harness — BLOCKING

PASS requires production-performance 59x59 evidence to use a real laid-out viewport/host.

Every measured slot origin must be finite and outside the board, normally below the bottom edge.

The old UNLAID geometry may remain only as explicit historical/artifact evidence.

FAIL if performance conclusions still rely on board-internal slot origins.

## B. Touch-mask exactness — BLOCKING

The materialized O(1) mask must be exactly equivalent to the prior necessary-condition semantics for outside origins.

PASS requires broad differential proof across sizes, revisions and states.

Zero false negatives.

Inside-board origin must not use the outside-origin filter.

## C. WHAT/HOW separation — BLOCKING

TargetSelector may consume only an opaque conservative necessary-condition capability from access truth.

FAIL if TargetSelector:
- computes rail/CLEARED topology;
- owns reachability mask construction;
- chooses a different target for speed;
- substitutes nearest/cheapest target.

Canonical bottom-most/left-most order remains exact.

## D. Optional capability fallback — BLOCKING

Missing, unsupported or malformed prefilter capability must preserve the prior full strict selector path.

A `true` prefilter answer is never sufficient for selection; the existing authoritative `is_targetable()` must still run.

A `false` answer may only skip a mathematically impossible candidate.

Strict/adversarial access doubles must preserve prior behavior.

## E. Transaction/coherence truth

PASS requires unchanged:
- reservation atomicity;
- owner/target proof;
- re-entrancy;
- bind generation checks;
- rollback;
- same-color FIFO;
- no ghost;
- WAITING/no-target semantics.

## F. Filtered vs baseline identity — BLOCKING

Using the same selector with canonical prefilter vs test wrapper hiding the capability, require:

- same selected target;
- same no-target result;
- same ReservationState;
- same dispatch target/color sequence;
- same final board/completion.

Full laid-out 59x59 must clear 3481/3481 and match baseline sequence.

## G. Work-count bounds — BLOCKING

On real laid-out outside-origin 59x59:

- compute_route <= 1 per lane;
- failed route probes = 0;
- impossible candidates do not enter strict reservation/coherence body;
- strict-body iterations bounded by touchable candidates + winner allowance;
- touch lookup O(1) after build;
- mask/cache state bounded and revision-keyed.

## H. Revision/identity invalidation

PASS requires:
- board revision change invalidates/rebuilds;
- restore/retry invalidates;
- different BoardState identity never reuses mask;
- same board+revision may share safely.

## I. Scheduler / tempo isolation

PASS requires:
- one lane/frame unchanged;
- 9/18 cells/s and 1/3 / 1/6 cadence unchanged;
- no M29 entitlement/economy change.

## J. Timing / remaining hotspot

Report clean laid-out before/after:
- selector scan excluding route;
- route Dijkstra;
- frame p99/max.

S1 timing target:
- selector scan excluding route p99 <= 3 ms.

Timing alone is not a correctness failure if hard bounds pass and machine noise is explained.

Audit must explicitly decide after remeasurement whether the remaining Dijkstra hotspot:
- blocks M29 owner tempo playtest and requires S2; or
- becomes a separate non-blocking routing-performance follow-up.

## K. Regression / governance

FAIL if Claude edits `TASKS.md`.

Required relevant regressions:
- M15/M19/M25/M26;
- M29 exact-origin + tempo;
- M30/M39/M52/M55;
- railroad/routing;
- root suite;
- `git diff --check`.

No implementation of S2 or D2 is authorized in this cycle.
