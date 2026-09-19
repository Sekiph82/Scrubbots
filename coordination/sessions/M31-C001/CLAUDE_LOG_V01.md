# M31-C001 V01 — Claude Implementation Log

Milestone: `M31 — Cleaning Effects [VISUAL REFERENCE] [PERFORMANCE]`
Actor: Claude (Opus 4.8)
Status handoff: `AWAITING_AUDIT`
Repository: `Sekiph82/Scrubbots` · Branch: `main`

## 1. SHAs

- Implementation commit (implementation-first): `7d929ceb769e9e786340dc517df815c50213bacf`
- This log is committed separately as the final commit (SHA recorded on push).
- Pre-work sync base: fast-forwarded `main` from `f71fc5a` to `origin/main` `fb1c071`
  (M30 CLOSED, M31-C001 sprint opened). No force push, no hard reset. Nine untracked
  owner PNGs that were byte-identical to the incoming merged versions were moved aside
  (not deleted) to allow the fast-forward, then restored as tracked files by the merge.
  The pre-existing local cosmetic `project.godot` edit (Godot-editor comment reflow +
  `handheld/orientation` reorder) was left untouched and is NOT part of any M31 commit.

## 2. Files changed

New:
- `scripts/gameplay/presentation/cleaning_effects_controller.gd` — presentation-only cue controller.
- `tests/m31_cleaning_effects_evidence.gd` — event/geometry/toggle/concurrency/reduced/retry.
- `tests/m31_scale_59_effects.gd` — 59×59 burst stress + timing + pooling decision.
- `scripts/debug/m31_cleaning_fx_playtest.gd` — owner F6 manual scene script.
- `scenes/debug/m31_cleaning_fx_playtest.tscn` — owner F6 manual scene.

Modified:
- `scripts/gameplay/board/board_presentation.gd` — identity-stable `CleaningFxLayer` + `get_cleaning_fx_layer()`.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — wire controller to the clear signal; retry cleanup; `get_cleaning_fx()`.

## 3. Event source and why it is authoritative

The only cue trigger is `CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)`.

Per the M20 contract (`complete_clearing_loop.gd` §J / `_run_transaction` step 7), this
signal is emitted **exactly once** on the committed CLEARED path — after
BoardState → candidate → reservation → dispatcher-finalize all succeed and the optional
renderer repaint runs — and is **never** emitted on preflight rejection, any rollback, a
failed/fatal transaction, or a reset. The controller listens as a pure observer: it reads
`target_index` for placement and ignores owner/color/agent. It never polls BoardState,
never infers from rendered transparency, robot position, route completion, slot quota, or
animation completion. Result: one committed clear → at most one requested cue (proven 1:1
in the evidence test; over-cap requests are suppressed, not clears).

## 4. Assets used (no generation)

- `assets/ui/final/gameplay/effects/fx_clean_puff.png` (1254×1254, CompressedTexture2D, lossless).
- `assets/ui/final/gameplay/effects/fx_clean_sparkle.png` (1254×1254, CompressedTexture2D, lossless).

Both are the existing merged owner assets, loaded read-only. No AI image generation was
performed; no asset was regenerated, replaced, or optimized. Textures are optional inputs —
a failed load degrades to fewer/no sprites (fail open), never a gameplay failure.

## 5. Presentation architecture

Hierarchy inside `BoardPresentation` (Node2D, shared board origin):
`BoardRenderer` → `CleaningFxLayer` → `ScrubRailView` → `AgentLayer`.

- `CleaningFxLayer` is created **once** and rescaled (never recreated) on every responsive
  `configure()`/relayout, exactly like the M29-stabilized Renderer/AgentLayer. Proven by
  `m31_cleaning_effects_evidence` (`CleaningFxLayer identity survives relayout`).
- The layer shares the renderer's integer cell scale, so one board-local unit == one cell.
  A cue placed at `(x + 0.5, y + 0.5)` cell units is centered on the exact cleared cell,
  using `BoardState.get_cell_position()` for read-only index→position only. Verified for a
  rectangular 6×4 board and on the real stack.
- The layer sits **under** the AgentLayer so the short cue reads over the cleared
  (transparent) cell without hiding a moving Scrubbot.
- No permanent per-cell node or data structure exists: a cue is a transient `Node2D`
  container (1–2 `Sprite2D` children) created on a committed clear and freed when its short
  lifetime elapses.

## 6. Visual behavior

Normal cue: soft puff + small sparkle, lifetime `0.30 s`, footprint ~1.4 / ~0.9 cells,
fades alpha 1→0 while softly expanding (×1.45). No screen flash, shake, or reward
explosion. Reduced cue: single puff, lifetime `0.18 s`. No random gameplay-visible values;
tests do not depend on randomness.

## 7. Toggle contract

`set_effects_enabled(bool)` (default ON) + `is_effects_enabled()`. When disabled: zero new
cues; currently-active cues are cleared **immediately** (the chosen deterministic behavior)
and this is tested; gameplay clears continue unchanged (proven on the real stack with FX
OFF). No Settings persistence added (M41 owns that); this is a runtime seam only.

## 8. Concurrency / overload policy

Hard cap: `MAX_ACTIVE_EFFECTS = 24` (reduced mode `8`). Presentation protection only — it
never queues, blocks, or delays a clear. At saturation the excess cue is dropped
deterministically and `suppressed` is incremented; there is no backlog allocation and
authenticated-clear processing is untouched (fail open). Diagnostic counters exposed:
`get_active_count()`, `get_peak_active()`, `get_suppressed_count()`.

## 9. Pooling decision (SB-M31-007) — profiling-driven, NO pool

No pool is used. Rationale + evidence: the cap bounds **live** cue nodes to ≤24 regardless
of burst size, so per-frame allocate/free churn is bounded by the cap, not by the (much
larger) clear burst. `m31_scale_59_effects` drives 40 cue requests/frame for 240 frames
(9,600 requests) on a 59×59 board:

```
M31_PERF 1x: 59x59 frames=240 req=9600 cap=24 peak=24 suppressed=9264 spawn+age=17.65 ms (0.0735 ms/frame)
M31_PERF 2x: 59x59 frames=240 req=9600 cap=24 peak=24 suppressed=9432 spawn+age=18.69 ms (0.0779 ms/frame)
```

Peak active held exactly at the cap (never exceeded); ~9.3k over-cap cues were suppressed
with no queue; total spawn+age cost was ≈0.07–0.08 ms/frame — three orders of magnitude
under a 16 ms mobile frame budget for the FX layer alone, at both 1× and a denser 2× event
rate. Allocation/free churn is therefore not a measurable frame-time or pressure source, so
adding a pool would be speculative complexity. SB-M31-007 is satisfied by proving the
decision, not by forcing a pool.

## 10. Reduced-effects mode (SB-M31-010)

Implemented as a tested runtime seam (`set_reduced_effects(bool)` / `is_reduced_effects()`)
even though the normal path passes comfortably, so M41 settings can later bind it without
touching gameplay. Reduced changes presentation cost/density only (single cue, shorter
lifetime, lower cap of 8) — never how many cells clear or when.

## 11. Retry / teardown hygiene

On a **successful** M30 Retry, `ProductionGameplayHost._on_retry_restored()` (the
RetryCoordinator post-success restore seam) calls `reset_for_new_attempt()`, which frees all
active cues immediately and zeroes the peak/suppressed counters. Cues use immediate `free()`
(signal-free leaf nodes), so no one-frame ghost and no delayed callback can repopulate the
fresh attempt. The M30 Retry gate itself is untouched; a failed Retry restores nothing and
therefore triggers no M31 reset. Proven on the real stack (`retry cleared stale cues`,
`retry reset fx counters`, `retry restored full ACTIVE board`).

## 12. Terminal / 1x-2x

M31 decides no terminal state and adds no completion/duplicate result visual. No
`Engine.time_scale` change; the cue uses short real presentation lifetimes and the perf
evidence includes the denser 2× event rate. Not coupled to Economy speed-entitlement logic.

## 13. Tests / evidence

Commands (Godot 4.7.2, headless):

```
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m31_cleaning_effects_evidence.gd
godot --headless --path . -s res://tests/m31_scale_59_effects.gd
godot --headless --path . -s res://tests/m29_presentation_identity_evidence.gd
godot --headless --path . -s res://tests/m29_realtime_movement_smoke.gd
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
godot --headless --path . -s res://tests/m30_completion_authority.gd
godot --headless --path . -s res://tests/m30_transaction_safe_retry.gd
godot --headless --path . -s res://tests/m30_manual_playtest_smoke.gd
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd
git diff --check
```

Results:
- Root suite: `Total checks: 5346 · Failures: 0 · RESULT: ALL PASS`.
- `m31_cleaning_effects_evidence`: PASS (event 1:1, exact-cell geometry incl. rectangular,
  toggle, concurrency cap/suppression, reduced single-cue + lower cap, aging, retry).
- `m31_scale_59_effects`: PASS (timing above).
- M29 identity/movement/runtime, M30 completion/retry/manual, M26 hazard/scale-59: all PASS.
- `git diff --check`: clean.

Baseline: the same root suite + M29/M30/M26 runners were confirmed green on the pre-M31
`fb1c071` tree before any change, so all listed passes are attributable to a clean M31 add.

## 14. Owner F6 gate

`res://scenes/debug/m31_cleaning_fx_playtest.tscn` hosts the real production stack (20×20
Hazard Bot) with debug-only controls: AUTO-SOLVE, FX ON/OFF, REDUCED ON/OFF, SPEED 1x/2x,
BURST (presentation-only density stress — does not clear cells), RETRY, plus a live
active/peak/suppressed readout. Debug controls are confined to this scene and do not leak
into release UI. M31 cannot receive final owner visual closure until this F6 gate is
explicitly accepted.

## 15. Known limitations

- BURST in the F6 scene is a presentation-only visual stress (random cells); it intentionally
  does not clear cells, so it exercises density/cap but not real clear cadence — use
  AUTO-SOLVE for the real event path.
- Cue sizing/lifetime constants are tuned for readability from the evidence, not owner-final;
  they are trivially adjustable and may be revised on F6 feedback.
- No Settings persistence for toggle/reduced (deferred to M41 by design).

## 16. Tracker confirmation

Root `TASKS.md` was **not** edited. M30 was not reopened. No M32/M33 work, no economy/home/
results work, no AI art generation, no new dependency, no `Engine.time_scale` hack, and no
per-cell permanent node were introduced.
