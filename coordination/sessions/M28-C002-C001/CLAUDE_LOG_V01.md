# M28-C002-C001 — CLAUDE LOG V01 — Gameplay Screen V02 core

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict or owner acceptance is claimed.
Prompt: `coordination/sessions/M28-C002-C001/task_prompts/SB-M28-C002-C001_GAMEPLAY_V02_CORE.md`
Criteria: `coordination/sessions/M28-C002-C001/audit_criteria/SB-M28-C002-C001_GAMEPLAY_V02_CORE.md`
Base: fast-forwarded to `origin/main` `e6e0ace`.
Root `TASKS.md` was read only and not edited. Results/Victory was not revisited (M43-C001B is FINAL OWNER VISUAL PASS).

Evidence:
- `coordination/sessions/M28-C002-C001/GAMEPLAY_V02_CORE_MATRIX_V01.md`: per-row status, connector/2x/booster contracts, responsive, sensitivity, assets, test migrations.
- `coordination/sessions/M28-C002-C001/OWNER_GAMEPLAY_V02_REVIEW_V01.md`: 8 screenshots, the dependency-deferred rows, and the visual-only owner choices.
- `coordination/sessions/M28-C002-C001/evidence/*.png` (8)
- `coordination/sessions/M28-C002-C001/layout_smoke/viewport_metrics.{json,md}` (migrated M28 smoke metrics)

## Result

The real `ProductionGameplayHost` screen now follows Gameplay Composition V02:
- profile chip top-left; PAUSE | 2x top-right;
- dominant BoardRenderer inside a full four-sided Railroad V1 production skin;
- five permanent slot → bottom-rail connectors that are the real route geometry, with a sixth only while the +1 Slot slot exists;
- slots directly under the board, then a 3/4/5 × 3 Batch Supply;
- Scrubby low-left and props right;
- four live boosters.

The bottom Pause/ad/speed row, the placeholders and the empty top spacer are gone. There is no Settings, Heart HUD or Goal/Moves/Time.

No change to:
- gameplay, routing, input or completion truth;
- economy prices or rules, Heart, 2x entitlement logic or anti-rollback;
- level content or supply plans;
- assets.

Dependency rows 012–015 (and 019's popup views) are deferred, not claimed.

## Implementation

| File | Change |
|---|---|
| `scripts/ui/gameplay_screen.gd` | Rewritten to the V02 composition. Layout sizes the board + rail envelope by integer cell size from the space left after the fixed HUD/slots/supply/booster bands; spare height goes above the board and above the boosters. <br>**Connectors:** computed through `SlotOriginProvider` and `ScrubRailGeometry.bottom_entry`, refreshed after layout and after every strip re-sort. <br>**HUD binding:** `set_profile`, `set_speed_presentation` (modes off/level/timed/auto with wall-clock `MM:SS`), `set_paused`, `set_booster_states`. <br>`booster_pressed(id)` intent signal. `has_ad_placeholder` / `has_settings_control` / `has_heart_hud` probes. All existing accessors are kept except the removed bottom-row/ad ones. |
| `scripts/ui/scrub_rail_view.gd` | Railroad V1 production skin from the approved rail art (tube = 1.0 cell on the unchanged centrelines; energy-node corners), drawn through in-memory mipmapped copies. Connector drawing via `set_connectors`. Procedural fallback kept. |
| `scripts/ui/batch_supply_panel.gd` | Tile look only: batch-coloured tile with a centred live count; bright cyan front rim; dimmed preview rows. Input/gesture logic untouched. Adds `get_row_count_text`. |
| `scripts/ui/batch_slot_view.gd` | Look only: native navy empty slot (approved `slot_*.png` have opaque white backgrounds), larger live count. APIs unchanged. |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `_refresh_hud` reads canonical services: frontier level, `RobotUnlockService.next_robot_progress`, `SpeedEntitlementService`, `BoosterInventory` / `EconomyConfig` / wallet / capacity. <br>A 1 s `HudTimer` (`ignore_time_scale`) triggers redraw only. <br>`booster_states()`; `request_booster(id)` with no silent spend; `booster_acquire_requested(id)` seam. <br>Pause calls `set_paused`. The HUD refreshes on speed toggle, purchase, booster commit, terminal and retry. <br>Retry and the +1 Slot rollback re-sync the slot row (five slots / five connectors). |

## Visual self-review (every rendered image inspected)

Two defects were found on the first renders and fixed before regression:
1. **Profile chip:** the name and level overlapped, and a light box showed behind the chip. Cause: `profile_panel_frame.png` has opaque white corners. Fixed with a native panel, a wider chip, and a live Bot Parts `ProgressBar`.
2. **Slots:** empty slots showed white squares on the tablet view. Cause: `slot_*.png` have opaque white backgrounds. Fixed with a native navy slot.

I also made the connectors more visible (connector gap 84 px, 0.9 cell wide) and hid the price on a selected booster.

The final 8 images show:
- correct hierarchy and dominant board;
- the four-sided skin;
- five (or six) vertical connectors aligned to slot centres;
- the 3×3 supply with a distinct front row;
- a live timed countdown "14:58";
- tall, short and tablet views with nothing clipped.

The remaining visual-only owner items are V1–V6 in the review file.

## Tests

**New: `tests/m28_c002_c001_gameplay_v02.gd`**: exit 0, 109 ok, case ledger 14/14.

Cases:
- composition and absence of obsolete elements;
- 7-size responsive matrix;
- notch/gesture safe areas;
- connector truth;
- conditional sixth connector;
- 3/4/5 × 3 supply;
- preview rows non-interactive;
- front click mapping;
- four live boosters;
- no silent booster spend;
- timed 2x on wall clock with rollback frozen;
- 2x modes including free auto;
- Pause top-right;
- no node/signal/timer accumulation over 5 retries.

The Random booster request in the test was refused by the booster's own safety check, and the charge was refunded. The test records that as correct no-spend behaviour.

**Sensitivity** (matrix §7): 5 mutations, each fails the suite; source files were restored from byte copies.

**Migrated** (matrix §9):
- `tests/m28_gameplay_layout_smoke.gd`: 253 checks, 0 failures, V02 assertions; evidence moved to this session so historical M28-C001 evidence is not overwritten;
- `tests/m52_r01_parallel_runtime.gd`: speed text → speed state.

**Updated:** `tests/m43_c001b_won_results_visual.gd`. The owner has since promoted `victory_results` to `MASTER_OWNER_APPROVED` (owner commit `e6e0ace`, `FINAL_OWNER_VISUAL_ACCEPTANCE_V01.md`). The assertion now accepts that status only together with the owner record; it still rejects an unbacked promotion. 11/11 PASS.

## Full regression (Godot 4.7.2.stable.official.ed1daf0bf, headless, 12-way parallel, final code, all 108 suites)

All 108 suites were run. 105 exit 0; the 3 non-zero are explained below.

| Group | ok counts (exit 0) |
|---|---|
| M20 lifecycle | 7 / 13 / 10 / 16 / 13 / 16 (+ `queue_free_smoke` PASS) |
| M21 | 20 / 15 / 14 / 69 (+ `real_art_smoke` PASS); v08 / v09: see below |
| M22 | 84 / 57 / 19 / 54 / 41 / 19 |
| M23 | 14 / 30 / 19 |
| M24 | 10 / 17 / 19 / 13 / 25 |
| M25 | 14 / 11 / 24 / 12 / 54 / 27 |
| M26 | 23 / 14 |
| M27 | 8 / 17 / 6 |
| M28 | V02 core 109; layout smoke 253 checks |
| M29 | 22 / 16 / 38 / 18 / 14 / 15 / 22 |
| M30 | 52 / 49 / 76 |
| M31–M34 | 39 / 12 / 19 / 39 / 114 / 15 / 26 |
| M35–M38 | 20 / 13 / 37 / 25 / 40 / 30 / 29 / 43 / 49 |
| M39 | 21 / 19 / 34 / 37 / 18 / 150 / 132 / 38 / 32 / 45 / 34 / 21 |
| M40 | 38 / 34 / 21 / 58 |
| M41 | 138 |
| M42 | 40 / 224 / 23 / 99 / 88 / 94 / 47 / 82 / 70 |
| M43 | C001A 66; C001B 49 after the owner-status update |
| M52 | `owner_supply_plans` 255 (First 10 all WON); R01 79; R02 65 |
| M53 | 315 / 214 |
| M54 | 192 |
| M55 | core chaos 129; long session 39; 2x anti-rollback 53; Heart 900 19; economy release 11 |
| palette contract | 26 |
| root `tests/run_tests.gd` | **5323 checks, RESULT: ALL PASS** |

**Non-zero exits, all explained:**
- `m43_c001b_won_results_visual`: the stale MASTER_REQUIRED expectation described above; updated and re-run → PASS 11/11.
- `m21_v08_corridor_validation` (FAIL 2) and `m21_v09_direct_evidence_reconciliation` (FAIL 1): **pre-existing.** I swapped in the HEAD versions of all five changed production scripts and got the identical failures (C/043, C/047; B). These historical M21 corridor/ring assertions belong to the pre-Railroad-V1 routing model; this cycle changed no routing code.

**Engine `ERROR:` classes** — the same as baseline:
- "resources still in use";
- the M52 malformed-JSON fixture;
- root corrupt/missing-image fixtures.

Plus `Parameter "t" is null` (×14), which occurs only in `m28_gameplay_layout_smoke`. It comes from that test's own headless PNG-capture attempt (`_try_capture`, unchanged from HEAD; the harness notes blank headless captures are acceptable).

**SCRIPT ERROR hits in M20:** all are the text "no SCRIPT ERROR" inside passing `ok:` lines.

`git diff --check`: clean. No tracked file was modified by the test runs.

## Changed / added files committed

- `scripts/ui/gameplay_screen.gd`
- `scripts/ui/scrub_rail_view.gd`
- `scripts/ui/batch_supply_panel.gd`
- `scripts/ui/batch_slot_view.gd`
- `scripts/gameplay/runtime/production_gameplay_host.gd`
- `tests/m28_c002_c001_gameplay_v02.gd` (new)
- `tests/tools/gameplay_v02_snapshot.gd` (new)
- `tests/m28_gameplay_layout_smoke.gd`
- `tests/m52_r01_parallel_runtime.gd`
- `tests/m43_c001b_won_results_visual.gd`
- `coordination/sessions/M28-C002-C001/`:
  - `GAMEPLAY_V02_CORE_MATRIX_V01.md`
  - `OWNER_GAMEPLAY_V02_REVIEW_V01.md`
  - `CLAUDE_LOG_V01.md`
  - `evidence/*.png`
  - `layout_smoke/viewport_metrics.{json,md}`

Excluded (owner/local, untouched):
- the pre-existing `project.godot` modification;
- untracked `.import`/`.uid` caches;
- owner media and generated candidates;
- `_owner_inbox`;
- `tests/_m55_diag_tmp.gd`.

## Reproduce

```bash
godot --headless --path . -s res://tests/m28_c002_c001_gameplay_v02.gd
```

```bash
godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- coordination/sessions/M28-C002-C001/evidence
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C001 GAMEPLAY V02 CORE`
