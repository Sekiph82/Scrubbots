# M31-C001 — Owner F6 Acceptance V01

Date: 2026-09-20  
Milestone: `M31 — Cleaning Effects`  
Scene: `res://scenes/debug/m31_cleaning_fx_playtest.tscn`

## Owner-observed runtime results

The owner manually executed the dedicated M31 F6 production playtest and accepted the following behavior:

1. Cleaning FX are visible on real gameplay clears.
2. `FX ON/OFF` works: OFF suppresses cleaning visuals while gameplay continues; ON restores them.
3. `BURST` produces multiple puff + sparkle cues at different cells without blocking gameplay.
4. `AUTO-SOLVE` works through the real production stack.
5. `SPEED 1x/2x` works and the cleaning FX remain visually acceptable at both rates.
6. `REDUCED ON/OFF` works and visibly changes the cue to the lighter reduced-effects presentation.
7. `RETRY` clears stale active cleaning FX and starts a fresh attempt correctly.
8. No concrete visual placement, stale-FX, toggle, reduced-mode, retry, or high-density regression was reported during the owner gate.

Pause was also observed working in the playtest, although pause itself is not an M31 closure requirement.

## Owner verdict

`OWNER_F6_PASS / M31 CLEANING EFFECTS ACCEPTED`

The owner visual gate required by M31 is satisfied. M31 may be closed once the independent code audit is recorded.