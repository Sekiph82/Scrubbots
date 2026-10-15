# M45 Debug Tooling — CLAUDE milestone master plan V01 (autonomous mode)

Date: 2026-10-15 · Author: Claude Code under `coordination/autonomy/SCRUBBOTS_CLAUDE_AUTONOMOUS_MASTER_V01.md` / `CLAUDE.md §0B`.
This plan is Claude-authored (not a ChatGPT prompt). Scope: the 18 existing `SB-M45-001..018` rows in root `TASKS.md`; no new product rule.

## Why M45 now
- M44 is technically 34/34 CI-green. It awaits peer review and owner phone / visual sign-off, which are not Claude's to give.
- M45 is developer-only, has no owner art / visual / R2 / economy dependency, and touches no shipping gameplay rule.

## Design (reuse existing authority; read-only)
1. `scripts/debug/gameplay_debug_model.gd`: a pure read of one built `ProductionGameplayHost` plus its catalog entry:
   - level id, difficulty, W×H, cell count, artwork cells, ACTIVE / CLEARED counts (`BoardState.count_cells_by_state`);
   - reserved count (`ReservationState`), active bots (`ScrubbotDispatcher.get_active_count`);
   - FPS (`Engine.get_frames_per_second`), frame time (`Performance.TIME_PROCESS`).
   It never mutates anything.
2. `scripts/debug/gameplay_debug_layer.gd`: ONE `Node2D` in board-local cell space (same transform as `AgentLayer`; one node, no per-cell nodes). It draws:
   - the cell grid;
   - reserved-target markers from `ReservationState.get_reserved_indices()`;
   - live agent routes from `ScrubbotAgent.get_route_points()`.
   A static `build_draw_model()` makes it headless-testable.
3. `scripts/debug/gameplay_debug_overlay.gd`: a CanvasLayer HUD with the model text and toggles (targets / routes / grid / cleaning-effects via the existing `CleaningEffectsController.set_effects_enabled`). Refreshed every 0.25 s, not per frame.
4. `scripts/debug/m45_debug_gameplay.gd` + `scenes/debug/m45_debug_gameplay.tscn`: developer harness. It runs a host with **no AppState**, so it has a private economy and never touches the player's save or progression. Instant reset uses the existing transaction-safe `host.retry()`. The level switcher lists the production catalog and rebuilds the host from the entry's level + SupplyPlan; there is no player-facing level select (M37 forward-only rule untouched).
5. Release gate (SB-M45-018): `GameplayDebugOverlay.is_allowed(features)` is false in any exported template build (`OS.has_feature("template")`). The overlay frees itself there, and nothing in the shipping app instantiates it. The harness is not reachable from the shipping navigation.

## Acceptance checklist (gates for review)
- A1: model values equal the live engine values at the same instant (level id / difficulty / W, H / cells / ACTIVE / CLEARED / reserved / active bots); FPS and frame time are finite and ≥ 0.
- A2: the draw model markers equal the reserved indices, routes are one per live agent, and the grid line count is (W+1)+(H+1).
- A3: the overlay and its refresh never mutate the board revision, slots, supply, economy or save (before / after equality).
- A4: the effects toggle flips the real `CleaningEffectsController` flag; instant reset restores a fresh attempt (all artwork ACTIVE, 0 reserved); the level switcher loads the selected catalog level (id / W×H match) through the real host build.
- A5: the release gate is false for a `template` feature set; there is no overlay / debug layer node in the real app root (`main.tscn`).
- A6: one node for the debug layer regardless of board size (59×59 fixture or largest catalog level).
- A7: new suite `tests/m45_debug_tooling.gd` with an exact case ledger, added to the EXISTING Android workflow (`validation_only`); all previous 34 suites stay green; `export` skipped; no APK.
- Review: a fresh-context `CLAUDE_PEER_REVIEW`. Not a ChatGPT independent audit.

## CI budget (self-imposed, mirrors prior milestone caps)
At most **3** `validation_only` runs of the existing workflow for M45. If still red after 3, stop with `AWAITING_OWNER_CI_BUDGET`. Never `build_apk`.

## Out of scope / not invented
- No player-facing level select, no shipping debug UI, no economy / save writes, no new art.
- Profiling budgets belong to M46.
