# M29-C002 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-29
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited implementation: `8787d38dba65a084e6169ea8e8ccc623ab63e0ae`
Parent: `0bccc1b2e1b622f2f8fe23fa6a073caa58e81f51`
Prompt: `coordination/sessions/M29-C002/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M29-C002/CHATGPT_AUDIT_CRITERIA_V01.md`
Task: `SB-M29-010`

## Verdict

**FUNCTIONAL_AUDIT_PASS / PERFORMANCE_GATE_BLOCKED**

The gameplay-tempo retune itself is technically correct:

- canonical 1x travel = 9 cells/s;
- canonical 2x travel = 18 cells/s;
- canonical 1x cadence = 1/3 s;
- canonical 2x cadence = 1/6 s;
- 1x/2x factors remain 1.0 / 2.0;
- one-lane-per-frame safety remains intact;
- entitlement/reset/pause behavior remains coherent;
- no new gameplay-truth regression is demonstrated by the focused suite.

However, audit criterion H cannot be closed because the required dense 59x59 evidence exposes a severe synchronous M25 target-selection main-thread stall.

SB-M29-010 remains OPEN.

Owner tempo playtest is DEFERRED until the performance blocker is investigated and a truth-preserving mitigation path is approved.

## A. Canonical baseline

**PASS.**

Direct production diff:

- `ScrubbotAgent.DEFAULT_SPEED = 9.0`;
- `ScrubbotDispatcher.DEFAULT_SPEED` derives from the Agent constant;
- `AutoDispatchScheduler.DEFAULT_SPEED` derives from Dispatcher;
- `CompleteClearingLoop.DEFAULT_SPEED` derives from Dispatcher;
- `GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL = 1.0 / 3.0`;
- factors remain 1.0 / 2.0;
- no `Engine.time_scale` use.

This closes the duplicate-default risk that would otherwise have left real host agents at the historical 6.0.

## B. Effective travel / cadence

**PASS.**

Focused evidence measures:

- 60 FPS: 1x 9.0000 cells/s; 2x 18.0000 cells/s;
- 30 FPS: 1x 9.0000 cells/s; 2x 18.0000 cells/s;
- ratio = 2.00000;
- cadence = 0.333333 s / 0.166667 s.

Already-moving and future agents are covered.

Pause/resume is covered.

## C. Frame-budget safety

**PASS.**

`MAX_LANES_PER_FRAME = 1` remains unchanged.

Focused wave probe confirms:

- no overlapping wave;
- max one lane/frame;
- backlog bounded to <= one cadence interval;
- six lanes at 30 FPS + 2x are service-limited to 0.20 s, as explicitly permitted by the prompt;
- no catch-up storm is introduced.

## D. Gameplay truth / existing authorities

**PASS with a documented discrete-frame nuance.**

Tempo-normalized deterministic runs preserve assignment order, target identity, clear order, slot accounting, final board and WON result.

Same-60-FPS-clock runs preserve final cleared set and WON truth, but not identical event order. This is consistent with the already-owner-accepted one-lane-per-frame frame budget: changing temporal factor changes where arrival/cadence events fall relative to frame boundaries. The decision policy itself is unchanged.

Existing authorities are measured at:
- current-level paid 2x -> 18 cells/s;
- timed new level / retry / relaunch -> 18;
- manual 1x during timed -> 9;
- expiry -> 9 unless M23 owns free 2x;
- M23 free 2x -> 18.

Prices/durations/scopes are unchanged.

## E. Legacy Hazard smoke harness correction

**PASS.**

The old harness used `DT = 1.0`, effectively a 1 FPS simulation. At the new 9 cells/s base, many routes complete in one tick and the one-lane-per-frame cap dominates the comparison.

The implementation changes the test harness to 60 FPS and resets the deterministic runtime clock after layout frames.

No production code is changed for this issue.

No assertion is removed or weakened.

Repeated reruns pass.

## F. Regression / governance

**PASS except the performance gate below.**

Submitted:
- root: 5323/5323 PASS;
- M28/M29/M30/M39/M40-M43/M52/M55 relevant suites PASS;
- M55 long-session PASS;
- known M21 v08/v09 baseline findings unchanged;
- root `TASKS.md` not edited by Claude;
- `git diff --check` clean.

## G. 59x59 performance blocker

**BLOCKING INVESTIGATION REQUIRED.**

The required real-host dense 59x59 window reports synchronous per-lane stalls in the M25 target-selection path:

Examples from submitted evidence:

- 5 slots / 1x / 60 FPS: target-selection max ~873 ms;
- 5 slots / 2x / 60 FPS: ~1047 ms;
- 6 slots / 2x / 60 FPS: ~2529 ms;
- 6 slots / 1x / 30 FPS: ~3192 ms;
- 6 slots / 2x / 30 FPS: ~3369 ms.

Historical-tempo same-harness runs also exhibit ~2350 ms max stalls.

RuntimePerfProbe attributes the spike to repeated target-selection reachability/route probes; per-route-probe cost itself is broadly similar between historical and new tempo in same-harness comparisons.

Therefore:

1. the expensive scan is pre-existing, not invented by the retune;
2. the new faster cadence increases how frequently production attempts lanes, so the pathological path can be encountered more often;
3. this is a user-visible frame-freeze risk on a board size the project explicitly claims to support;
4. criterion H ("no major performance regression caused by higher tempo") cannot be accepted merely because the underlying algorithm predates this cycle.

## H. Required next action

Open a separate investigation-only task:

`SB-M25-033 — Bound 59x59 target-selection scan cost`

The first cycle is PROPOSAL ONLY:
- reproduce;
- instrument per-lane probe counts;
- identify the exact repeated work;
- propose a bounded truth-preserving mitigation;
- prove how exact bottom-most/left-most target choice and WHAT/HOW separation would remain unchanged;
- do not edit gameplay code.

Only after ChatGPT audits the proposal will an implementation remediation be authorized.

## Final

**FUNCTIONAL_AUDIT_PASS / PERFORMANCE_GATE_BLOCKED**

M29 tempo code remains in `main`.
SB-M29-010 remains OPEN.
Owner feel-playtest waits until the M25 performance blocker is resolved or explicitly dispositioned.
