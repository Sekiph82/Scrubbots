# 06 — Test Strategy

No third-party testing framework is introduced in this prompt. Godot 4.7
supports headless execution (`--headless`) which is the intended backbone
for command-line-runnable checks as the project grows. This document
describes the *plan*; most of these tests do not exist yet.

## Categories and planned checks

### Project boot
- Project opens/parses without error in headless mode.
- Main scene loads without error.
- No broken resource paths reported by the engine.

### Level data validation
- A loaded level has exactly `grid_width == 40` and `grid_height == 40`.
- A loaded level's `cells` array has exactly `1600` entries.
- Every value in `cells` is a valid palette id present in that level's
  `palette` (no out-of-range/dangling color references).
- `format_version` is a supported value.

### Slot state correctness
- Exactly the configured number of slots exist (currently 5).
- A slot's assigned color id is always a valid palette id for the current
  level.

### Target eligibility / dispatch
- A Scrubbot is never dispatched from a slot when `TargetSelector` reports
  no valid target for that slot's color (locked rule from
  `docs/01_GAMEPLAY_SPEC.md`).
- `TargetSelector` never returns a target cell that is already cleaned or
  otherwise unavailable.

### Routing result validity
- A `RoutingSystem` result always terminates at the target cell assigned by
  `TargetSelector` (the two systems must agree on the endpoint even though
  they are implemented separately).
- A routing result does not reference cells outside the 40×40 grid.

### Cleanup / win / reward
- Reaching a target cell transitions it to cleaned exactly once (idempotent
  completion, no double-clean).
- Win detection matches whatever win condition is finalized in M9.
- Win-streak reward mapping matches the locked table exactly:
  `1->1, 2->5, 3->10, 4->25, 5+->100` (regression test against the known-
  wrong mapping documented in `docs/01_GAMEPLAY_SPEC.md` is valuable here).

### Save data
- Saved/loaded round-trip preserves streak count and currency exactly.

### Performance sanity checks
- Board State construction/update for 1,600 cells stays within a defined
  budget (concrete numbers TBD once M1/M3 exist) and does not allocate one
  Node per cell (structural check, not just timing).

## How these should eventually run

Prefer tests invokable from the command line via headless Godot
(`godot --headless --path . -s <test_script>.gd` or a small custom test
runner script under `tests/`), so they can run without opening the editor
and can later be wired into CI if desired. `tools/run_headless.ps1`
(created in this prompt) is the starting point for headless invocation.

## Explicitly out of scope for this prompt

No tests are implemented yet — there is no board, level loader, slot system,
target selector, or routing system to test. This document exists so testing
is designed alongside the architecture rather than bolted on later.
