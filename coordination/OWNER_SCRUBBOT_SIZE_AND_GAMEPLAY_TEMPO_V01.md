# OWNER DECISION — SCRUBBOT APPARENT SIZE + GAMEPLAY TEMPO V01

Date: 2026-09-29
Status: OWNER-LOCKED / QUEUED
Repository: Sekiph82/Scrubbots

This decision defines two separate follow-up tasks. Neither is part of the currently running M28-C002-C003-R01 V02 remediation.

## 1. Board-resolution-independent Scrubbot apparent size

### Problem

Current gameplay Scrubbot rendering uses:

`ScrubbotVisual.BODY_SPAN_CELLS = 2.4`

Because that value is expressed in logical board cells, apparent screen size changes with board resolution:

- 20x20 -> visually larger
- 32x32 -> reference/current common appearance
- 38x38 -> smaller
- 59x59 -> much smaller
- a future 100x100 board would make the same 2.4-cell visual far too small

### Owner rule

Gameplay Scrubbots must keep approximately the SAME apparent screen size regardless of logical board dimensions.

Use the current owner-accepted 32x32 / 2.4-cell appearance as the reference target.

The implementation must compensate presentation scale for actual rendered logical-cell size rather than keep a constant cell-span.

Conceptually:

- 32-cell reference axis -> 2.4 cells
- 20-cell equivalent -> about 1.5 cells for the same apparent screen span
- 38-cell equivalent -> about 2.85 cells
- 59-cell equivalent -> about 4.425 cells
- 100-cell future-equivalent -> about 7.5 cells

The production implementation should derive this from presentation geometry / actual cell-to-screen scale, not from a hardcoded lookup table.

For rectangular boards, use the real rendered cell scale / board presentation geometry so aspect ratio does not create inconsistent character size.

### Important invariants

This is PRESENTATION ONLY.

Do not alter:
- agent authoritative position;
- route points;
- target selection;
- reservations/claims;
- movement distance;
- clear timing/truth;
- board hit testing;
- BoardState;
- solver;
- current supported board-dimension validity envelope.

Do not expand production level validity to 100x100 as part of this task. The sizing formula must simply be future-proof and not assume 59 is a permanent maximum.

Responsive device scaling may still scale the whole gameplay presentation appropriately. "Same size" means board-resolution independent on a given presentation/viewport, not raw identical pixels across physically different device viewports.

### Validation

Prove apparent-size consistency at minimum with:
- 20x20
- 32x32
- 38x38
- 59x59
- one synthetic future-size scaling calculation/fixture equivalent to 100x100 without changing the production level envelope
- rectangular board representative

Fresh screenshots/evidence required.

## 2. Gameplay tempo retune

### Current production truth

Current Scrubbot base travel:

`ScrubbotAgent.DEFAULT_SPEED = 6.0` board-local cells / second.

GameplaySpeedAuthority:
- 1x factor = 1.0
- 2x factor = 2.0
- base dispatch cadence = 0.5 s
- 2x cadence = 0.25 s

ProductionRuntimeController applies the same temporal factor to agent travel and scheduler cadence.

Therefore current effective tempo is:

- current 1x: travel 6 cells/s, cadence 0.5 s
- current 2x: travel 12 cells/s, cadence 0.25 s

### New owner rule

Increase the normal gameplay baseline to 1.5 times the old baseline while preserving the user-facing semantic that the 2x button is exactly twice the NEW normal speed.

New required effective tempo:

- NEW 1x = OLD 1.5x
  - Scrubbot travel: 9 cells/s
  - dispatch cadence: 1/3 s ~= 0.333333 s
- NEW 2x = exactly 2.0 times NEW 1x = OLD 3.0x
  - Scrubbot travel: 18 cells/s
  - dispatch cadence: 1/6 s ~= 0.166667 s

The UI remains labelled 1x and 2x. "2x" means 2x relative to the new normal baseline, not 2x relative to the historical pre-retune baseline.

### Implementation rule

Do not fake this by changing only the sprite travel speed while leaving dispatch cadence at the old baseline.

Retune the canonical base tempo so the whole production gameplay clock remains coherent:
- agent travel;
- scheduler cadence;
- current and future spawned agents;
- pause/resume;
- manual/timed 2x;
- M23 free automatic 2x.

Do not use Engine.time_scale.

### Preserve

Do not change:
- 2x entitlement prices/durations;
- timed entitlement wall-clock behavior;
- paid/current-level entitlement scope;
- M23 exhausted-supply free auto-2x semantics;
- target order;
- routing;
- claims/reservations;
- batch accounting;
- clear identity;
- win/loss truth;
- economy.

### Performance / stability gate

The faster cadence must not create:
- dispatch storms;
- duplicate waves;
- multi-lane same-frame regressions;
- reservation conflicts;
- missed/duplicate clears;
- frame-hitch catch-up bursts.

Validate at 1x and 2x with five and six slots, dense routing, representative 59x59 content, and existing runtime/performance regressions.

Because a six-lane wave is serviced one lane per frame, explicitly verify the faster 0.166667 s 2x cadence under representative 30/60 fps timing and preserve bounded-wave/backlog behavior.

## 3. Sequencing

These are separate follow-up tasks after the active M28 V02 cycle.

Recommended order:

1. current M28-C002-C003-R01 V02 + owner replay
2. M28-C002-C004 Color / Batch Tile Visual Polish
3. M29-C002 Gameplay Tempo Retune
4. M32-C002 Board-Resolution-Independent Scrubbot Apparent Size
5. SB-M39-053 clock-boundary test stability
6. SB-M42-034 Home Scrubby Runtime Animation
7. resume existing M43/meta roadmap

No implementation prompt is opened until each task becomes current through the normal ChatGPT prompt/audit cycle.
