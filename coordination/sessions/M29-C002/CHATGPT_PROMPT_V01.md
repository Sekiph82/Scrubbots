# M29-C002 — GAMEPLAY TEMPO RETUNE — IMPLEMENTATION PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Status: READY FOR CLAUDE
Task: `SB-M29-010`

Owner authority:
`coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md`

Related speed semantics:
- `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
- `coordination/OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01.md`

Previous task M28-C002-C004 is CLOSED / OWNER PASS.

Do not edit root `TASKS.md`.

## Mission

Retune the canonical production gameplay tempo so normal gameplay is 1.5 times faster than the historical baseline, while preserving the user-facing `1x / 2x` semantic.

Historical production baseline:

- Scrubbot travel at 1x: **6.0 board-local cells/s**
- Scrubbot travel at 2x: **12.0 cells/s**
- scheduler cadence at 1x: **0.5 s**
- scheduler cadence at 2x: **0.25 s**

New owner-locked baseline:

- NEW 1x = OLD 1.5x
  - travel: **9.0 cells/s**
  - scheduler cadence: **1/3 s = 0.333333... s**
- NEW 2x = exactly 2x NEW 1x = OLD 3.0x
  - travel: **18.0 cells/s**
  - scheduler cadence: **1/6 s = 0.166666... s**

The UI remains labelled `1x` and `2x`.

Do NOT add a 1.5x or 3x user-facing mode.

## Current code seams to inspect

At prompt creation, current main contains:

- `ScrubbotAgent.DEFAULT_SPEED = 6.0`
- `ScrubbotDispatcher.DEFAULT_SPEED = 6.0`
- `GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL = 0.5`
- `GameplaySpeedAuthority.FACTOR_1X = 1.0`
- `GameplaySpeedAuthority.FACTOR_2X = 2.0`
- `ProductionRuntimeController` advances agents using `delta * factor()`
- cadence uses `base_interval / factor()`
- production wave servicing is bounded by:
  - `MAX_STEPS_PER_FRAME = 1`
  - `MAX_LANES_PER_FRAME = 1`

Verify actual current main before editing.

## Required architecture

### A. Canonical travel baseline

Set the canonical default Scrubbot travel speed to:

`9.0 board-local cells / second`

Avoid duplicate drift between Agent and Dispatcher.

Preferred:
- `ScrubbotAgent.DEFAULT_SPEED := 9.0`
- make Dispatcher default derive from the Agent constant, e.g. `ScrubbotAgent.DEFAULT_SPEED`, rather than carrying a second independent numeric 9.0 constant.

If an equivalent single-source approach is cleaner, use it.

Do not silently change explicit custom-speed test/debug call sites.

### B. Canonical cadence baseline

Set the speed authority's normal cadence baseline to mathematically represent:

`1.0 / 3.0 seconds`

Do not use a rounded `0.33` if it creates avoidable drift.

2x must remain:

`base_interval / 2 = 1.0 / 6.0 seconds`

### C. Preserve speed factors

Keep:
- 1x factor = 1.0
- 2x factor = 2.0

Do not implement this retune by making 1x factor 1.5 and 2x factor 3.0 while leaving old base constants hidden underneath. The new normal itself is the baseline.

This keeps the meaning of `factor()` simple and preserves all entitlement/UI semantics.

### D. No Engine.time_scale

Continue using the explicit gameplay clock.

Do not use or modify `Engine.time_scale`.

## Critical frame-budget rule

Do NOT sacrifice the accepted one-lane-per-frame scheduler safety rule just to force nominal cadence under low FPS.

Keep:

`MAX_LANES_PER_FRAME = 1`

and the existing bounded-wave/backlog behavior unless an independently safer equivalent is proven.

Important consequence to test/document:

- 60 FPS, six lanes: a full six-lane wave can be serviced in ~0.10 s, below the new 2x cadence of ~0.1667 s.
- 30 FPS, six lanes: a full six-lane wave takes ~0.20 s, slightly longer than nominal 2x cadence.

At 30 FPS + 6 lanes, the runtime may therefore become **wave-service limited** to roughly 0.20 s between full new-wave starts.

This is ACCEPTABLE.

Do not queue overlapping waves, create catch-up bursts, or raise the lane budget to 2 merely to chase the nominal 0.1667 s.

The safety invariant wins:
- one current wave at a time;
- one lane serviced per frame;
- no backlog storm;
- deterministic claims/order.

## Preserve all gameplay truth

The retune changes only temporal pacing.

Do not change:

- M23 FIFO/front-only supply;
- M24 placement/quota/accounting;
- M25 claims/reservations/FIFO arbitration;
- TargetSelector target ordering;
- railway-first route geometry;
- route identity;
- no-ghost rules;
- authenticated clear semantics;
- completion/win/loss truth;
- solver/deadlock;
- economy prices;
- timed 2x durations/prices;
- current-level 2x price/scope;
- Heart/booster rules;
- M23 free auto-2x trigger;
- timed-2x cross-level behavior;
- pause semantics.

## Entitlement semantics to preserve

The new faster baseline must work with every existing 2x authority:

1. manual paid/current-level 2x;
2. timed 15m/30m/60m 2x;
3. timed cross-level/relaunch auto-start;
4. free M23 supply-exhausted auto-2x.

All four produce the same runtime factor `2.0` relative to the NEW baseline.

No price or entitlement rule changes.

## Required focused tests

Create a new focused M29-C002 tempo-retune suite.

It must prove at minimum:

### 1. Canonical constants / single source

- Scrubbot default travel baseline is 9.0;
- dispatcher production default resolves to that same canonical value;
- no stale independent production `6.0` default remains in Agent/Dispatcher speed authority path;
- cadence base = 1/3 s;
- factor values remain 1.0 and 2.0.

### 2. Effective travel

Using a long enough deterministic route:

- NEW 1x travels 9.0 cells in 1.0 gameplay second;
- NEW 2x travels 18.0 cells in 1.0 gameplay second;
- ratio exactly 2:1 within numeric tolerance;
- current agents react to switching;
- future agents created after switching use the same new baseline;
- pause freezes movement exactly;
- resume preserves selected speed.

Do not rely only on checking constants.

### 3. Cadence timing

With a deterministic scheduler probe:

- 1x cadence event period = 1/3 s;
- 2x cadence event period = 1/6 s;
- ratio exactly 2:1;
- no duplicate same-frame wave;
- no unbounded catch-up after a large delta/hitch;
- placement wake behavior remains intentionally immediate only for the placed lane.

### 4. 30 FPS / 60 FPS bounded-wave stress

Test five and six-slot production-like lane counts.

At 60 FPS:
- 6-lane wave completes before the next 2x nominal cadence;
- no overlap/backlog storm.

At 30 FPS:
- 6-lane wave is allowed to remain service-limited to ~0.20 s;
- still one lane/frame;
- no second wave starts until the pending wave completes;
- accumulated cadence backlog is bounded/dropped according to current runtime contract;
- no claims/reservations are duplicated.

Do NOT fail the test merely because the full six-lane wave cannot physically finish in 1/6 s at 30 FPS.

### 5. Truth equivalence

Run equivalent deterministic gameplay at:
- new 1x;
- new 2x.

Prove same:
- selected targets;
- assignment order;
- clear identity;
- final board state;
- remaining/committed accounting;
- reservation cleanup;
- win result.

Only wall-clock/gameplay-time completion duration may differ.

### 6. Existing speed authorities

Prove:
- current-level 2x produces effective 18 cells/s;
- timed 2x new level/retry/relaunch starts at effective 18 cells/s while entitlement remains;
- timed expiry falls back to effective 9 cells/s unless M23 free auto-2x owns 2x;
- M23 supply exhaustion produces effective 18 cells/s for free;
- manual 1x during timed entitlement remains effective 9 cells/s for that attempt until the next authoritative new-attempt default reapplies timed 2x.

### 7. Reset

A reset without an active timed entitlement restores new 1x:
- factor 1.0;
- 9 cells/s;
- 1/3 s cadence.

## Required regression gate

Run at minimum:

- new M29-C002 focused suite;
- existing M29 speed authority/input/presentation suites;
- M28 gameplay presentation suites;
- M30 completion/retry;
- M39 economy/timed/current-level/+1 Slot integration;
- M40–M43 relevant gameplay/modal/economy integration;
- M52 lane/wave/supply suites;
- M55 long-session/performance;
- routing/clearing/solver truth suites;
- root suite;
- `git diff --check`.

Existing known unrelated baseline failures must be identified exactly.

## Performance evidence

Because this raises event frequency and travel completion frequency, provide explicit runtime/performance evidence for:

- 5 slots at new 1x/2x;
- 6 slots at new 1x/2x;
- representative dense / 59x59 workload;
- 30 FPS and 60 FPS synthetic fixed-delta cases;
- no lane backlog storm;
- no duplicate clear;
- no frame-budget invariant regression.

Do not optimize by weakening correctness.

## Documentation

Update stale comments/docs in modified speed/runtime files that still state the old `6 / 12 cells/s` or `0.5 / 0.25 s` production baseline.

Preserve historical audit documents unchanged.

Do not rewrite old evidence as if it had been produced under the new tempo.

## Evidence outputs

Create under:

`coordination/sessions/M29-C002/evidence/`

At minimum:

- a machine-readable/text tempo measurement report with:
  - travel distance per 1 s at 1x and 2x;
  - cadence intervals;
  - five/six slot 30/60 FPS wave timing;
  - backlog maximum;
  - duplicate assignment/clear count;
- representative real-host trace for 1x and 2x;
- 59x59 stress summary.

A video is optional; numeric runtime evidence is mandatory.

## Governance

Do not edit root `TASKS.md`.

Preserve owner/local untracked files.

No destructive reset/clean/force push.

## Required outputs

Create:

- `coordination/sessions/M29-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M29-C002/IMPLEMENTATION_MATRIX_V01.md`
- evidence directory.

Commit/push to `main`.

Return:
1. final SHA;
2. exact production constants/seams changed;
3. focused test results;
4. regression summary;
5. performance/30-60 FPS evidence links;
6. any owner playtest item still required.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M29-C002 GAMEPLAY TEMPO RETUNE V01`
