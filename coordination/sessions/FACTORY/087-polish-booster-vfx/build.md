STATUS: READY

# Build: SB-POLISH-003 booster activation VFX (+ SB-POLISH-012 slot batch-complete pop)

Acceptance criteria (written by the builder; no spec-writer this job):
1. Tornado: a swirling vortex, and the purged colour's board cells and its supply/slot tiles visibly spiral into it instead of vanishing.
2. +1 Slot: the sixth slot opens with glow, pop and sparkles, and the strip changes smoothly from 5 to 6. This also applies when +1 Slot is used straight from the booster row.
3. Random: a dice-like colour flicker with sparkles over the supply as it re-rolls.
4. Selector: a reticle locks onto the picked batch and flashes, then the batch flies into its slot.
5. SB-POLISH-012 (owner addition): every time a slot's batch finishes and the slot empties, the tile lifts slightly, pops and gives off stars. Slot release timing does not change.
6. Presentation only: gameplay truth, timing and economy are unchanged. Each effect lasts about 0.4-0.9 s. The overlay never takes input. No per-cell board nodes, and no node is created per pop.
7. Reduced Effects: no VFX at all. The existing booster button burst fade stays.
8. Evidence: 1080x2160 stills for each booster (4 each) and for the pop (3).

## Summary
- `scripts/ui/feel/booster_vfx.gd` (new): one input-transparent Control overlay that draws every effect. It has one child, a ghost TextureRect for Tornado. It reuses the existing `booster_activated_burst.png` and `booster_reward_glow.png` art.
  - Tornado: the vortex arms and rings are drawn. The removed cells are one `ImageTexture` (the ghost) that rotates and shrinks into the eye of the vortex. Up to 48 sampled cells and the colour's tiles also spiral in, and a burst plays at the end.
  - Pops: kept as dict entries and drawn in the same `_draw`. No nodes are created, so there is nothing to pool or leak.
- `scripts/ui/gameplay_screen.gd`:
  - `capture_booster_fx()` reads the view before the action: Tornado cells/tiles and the Selector source tile.
  - `play_booster_activated(id, pre)` feeds the overlay.
  - +1 Slot crossfades a `GameplayShellPrevious` TextureRect (the cached 5-slot master) and fades in the sixth slot view.
  - `set_reduced_effects()` was added.
  - `refresh_slot_snapshot(snaps, batch_fx = true)` pops a slot that goes from occupied to EMPTY.
- `scripts/gameplay/runtime/production_gameplay_host.gd`:
  - `execute_booster` captures before the action and plays after a committed result.
  - `request_booster` now plays the effect for owned +1 Slot / Random used from the row. Before this, that path had no feedback at all.
  - The Reduced Effects setting is wired live.
  - The Retry slot reset passes `batch_fx = false`.
- `tests/sb_polish_003_booster_vfx.gd` (new) and `.github/workflows/android-family-first10.yml`: the suite is added to the CI validate list.
- `TASKS.md`: SB-POLISH-003 is DONE, and SB-POLISH-012 was added as DONE (queue row and checklist line).

Feel-stack note: FeedbackAdapter's Spark/GFF plugins are restricted to meta tiers (max 24 particles, Control punch is a no-op), and the static guard allows only the adapter to name the plugins. So the board-scale effects are drawn by this one overlay, which keeps the existing booster art and the canonical Reduced Effects setting. The adapter's existing F009 SMALL on the HUD booster button still fires unchanged (m43_c005f_phase3 a05 PASS).

## Acceptance criteria
1. [x] Tornado: the suite printed `ok: vortex playing; ghost holds exactly the 298 purged cells (298)`, `ok: <= 48 spiral samples drawn, no per-cell nodes` and `ok: tornado effect ended by itself (768-837 ms)`. Stills: `evidence/tornado_1..4.png` (vortex, rotating and shrinking ghost, supply tiles flying in, burst at the eye).
2. [x] +1 Slot through `request_booster`: `ok: pop effect playing, 5-slot master crossfading, sixth slot fading in`, then `ok: crossfade done, sixth slot fully shown`, ended in about 600 ms. Stills: `evidence/plus_one_slot_1..4.png`.
3. [x] Random: `ok: dice flicker over the visible supply tiles`, ended in 500 ms. Stills: `evidence/random_1..4.png` (dice pips, colours settling, sparkles).
4. [x] Selector: `ok: Selector committed: batch B00017 in a slot` and `ok: reticle lock + fly effect playing`, ended in about 665 ms. Stills: `evidence/selector_1..4.png` (reticle closes on the tile, white flash, tile flies to slot 6 with the reticle, burst on landing).
5. [x] SB-POLISH-012: real play (front batches sent, runtime running) gave `ok: a finished slot batch popped in real play (1)` and `ok: pop ended by itself (510 ms)`. `ok: Retry-style reset (batch_fx false): no pop`. Stills: `evidence/batch_pop_1..3.png` (lift, burst with stars, fade). The pop only observes the snapshot that is already EMPTY, so the slot is never held.
6. [x] Every action result is the action's own: cells CLEARED, batch in its slot, 6 slots, and the charges/economy suites pass unchanged. `ok: one BoosterVfx overlay, input-transparent, one child (Tornado ghost) only`. `ok: no nodes created by pops (overlay children 1, ...)`. The tree-node delta in that line is Scrubbot agents in flight. m55_long_session PASS.
7. [x] `ok: Reduced: Tornado committed, no VFX` and `ok: Reduced Effects: no pop`.
8. [x] 19 PNGs at 1080x2160 in `factory/jobs/087-polish-booster-vfx/evidence/`. They were made with the suite's `--evidence=` mode: run without `--headless`, gl_compatibility, a temp `user://` save via `boot_save_path_override` that is deleted afterwards, and `boot_opening_override = 0`. The effect is stepped to fixed moments for the stills.

## Validation
All runs use `$GODOT --headless --path <worktree> -s res://tests/<suite>.gd` (LOCAL_PASS, Godot 4.7.2):
- sb_polish_003_booster_vfx: exit 0, 0 SCRIPT/Parse errors, `SB-POLISH-003 BOOSTER VFX: PASS`. Run 3x headless and 2x windowed (evidence mode), all PASS.
- m39c_boosters: exit 0, `M39 Phase C evidence: PASS`
- m22_023_booster_state_art: exit 0, PASS
- m22_025_booster_texture_budget: exit 0, PASS
- m39_c003_random_any_booster_rewards: exit 0, PASS
- m43_c005f_phase3_meta_rewards_acquisition: exit 0, `PASS (15/15 cases, 0 fail)`. Its 2 SCRIPT ERROR lines are the suite's own announced `EXPECTED_FAULT_INJECTION` (FaultySpark).
- m55_long_session: exit 0, `M55 LONG SESSION: PASS`
- `git diff --check` on the changed scripts/tests: clean.
- No CI run and no phone build (owner usage rule).

## Log
### Round 1
- Built the four booster effects and the SB-POLISH-012 pop (the coordinator's mid-job owner addition) as described above. Fixed my own early defects:
  - Godot auto-enables `_process` on ready.
  - The +1 Slot pre-capture was missing on the row path. Replaced it with the cached 5-slot master.
  - The sample stride overshot 48.
  - The Selector tile was not drawn during lock-on.
  - The real-play pop test sent only column 0, which was flaky because Random's order varies. It now sends every column.
- Commits: 3c0330f9 (code, test, CI list) and 9329135a (TASKS.md). Not pushed.
- Godot rewrote `project.godot` on every run. I restored it with `git checkout -- project.godot` each time, and it is not committed.
- The worktree still shows Godot import churn: about 248 modified `.import` files and about 1316 untracked `.import`/`.uid` files. All of it was present before this job's first command (the modified `.import` files were already in the starting status), and none of it is staged or committed. That is why `git status --porcelain` is not empty.
