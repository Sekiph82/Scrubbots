# M28-C002-C002-R01 — CLAUDE LOG V01 — Scrubby scale + bubble + visual gate remediation

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict or owner acceptance is claimed.

Prompts:
- `coordination/sessions/M28-C002-C002-R01/task_prompts/SB-M28-C002-C002-R01_VISUAL_REMEDIATION.md`
- `coordination/sessions/M28-C002-C002-R01/task_prompts/SB-M28-C002-C002-R01_CONTINUE.md`

Owner authority: `coordination/OWNER_GAMEPLAY_STATIC_SHELL_VISUAL_ACCEPTANCE_V01.md`. The locked decisions are S1-A, S2-B, S3-B, S4-A, S5-A and S6-C, plus the R01 A/B changes.

Root `TASKS.md` was read only, not edited.

Evidence:
- `VISUAL_REMEDIATION_MATRIX_V01.md`
- `OWNER_VISUAL_REVIEW_V01.md`
- `evidence/*.png` (11)

## History

1. **First session.** Implemented A–F, and the focused suite reached 10/10. The Claude Code command/file safety check then stopped returning verdicts. I stopped before the hard attempt limit with the whole tree uncommitted and intact.
2. **Continue session** (`SB-…_CONTINUE.md`):
   - `git fetch`, then fast-forwarded `22423ae → 271e498`. That commit contained only the plan and `TASKS.md`, with no overlap with local work.
   - Verified the local R01 diff was intact: `BODY_SPAN_CELLS` 2.4, `ECHO_SPAN_CELLS` 2.1, and the new test present.
   - Then did the rendering, inspection, fixes, regression, docs and commit.

## Implementation (final)

| File | Change |
|---|---|
| `scripts/gameplay/presentation/scrubbot_visual.gd` | `BODY_SPAN_CELLS` 1.8 → 2.4. Presentation only. |
| `scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd` | `ECHO_SPAN_CELLS` 1.6 → 2.1. Lifetime, shrink and cap are unchanged. |
| `scripts/ui/ui_text.gd` | Adds `GP_BUBBLE_HEADLINE` and `GP_BUBBLE_INSTRUCTION`. |
| `scripts/ui/gameplay_screen.gd` | Bubble text:<br>- two live Labels on the master transform;<br>- shrink-to-fit on the uncached Label minimum;<br>- `bubble_text_fits()` / `get_bubble_labels()` accessors.<br>AD region: `StyleBoxEmpty` with no label, plus `is_ad_placeholder_visible()`. Hit areas: min hit size set to `UiTokens.TOUCH_MIN`, refreshed after grid layout. |
| `scripts/ui/batch_supply_panel.gd` | S2-B invisible `top_level` front `HitArea`, clamped to half the baked gap. Adds `set_min_hit_size`, `refresh_hit_areas` and `get_front_hit_rect`. |
| `scripts/data/level_catalog.gd` | S6-C `square_shell_error()`, applied in `load_manifest` and `validate_all`. |

Unchanged:
- the six master PNGs;
- routing, rail geometry, agents, and the slot/supply engines;
- the input controller;
- economy, Heart and 2x rules;
- level content and supply plans;
- the generic rectangular engine;
- `TASKS.md`.

## Continue-session work

1. **Rendered the 11 evidence shots and inspected every one.**
   - The bots are visibly larger and readable at 1x, 2x, dense, small and large board sizes.
   - There is no AD band, and no fragment of the obsolete sentence shows.
   - I checked the 1080×1920 bubble at 3× zoom: it is legible and fully inside the bubble.
2. **Defect found in the renders.** The +1 Slot six-slot bubble had larger, crowded text (25/20 px instead of 21/18).
   - Root cause: `get_combined_minimum_size()` is cached until the next frame, so the fit loop measured stale values. A second layout pass therefore never shrank.
   - Fixed by using `get_minimum_size()`.
   - Added guards: re-layout idempotence, and identical fonts across the 5→6 switch at all five sizes.
   - Mutating back to the cached call fails 5 assertions.
   - Re-rendered: the six-slot bubble now matches the five-slot bubble.
3. **Re-ran all 7 earlier sensitivity mutations on the final code**, plus the new one. All 8 fail the suite, and each file was restored and confirmed with `cmp` (matrix §3).
4. **Migrated `tests/m35_level_catalog.gd` `rect_easy`.** The test asserted the pre-S6-C policy that a 24×28 catalog entry is accepted. It now asserts that the entry's only error is the S6-C square-shell message (so it is otherwise legal) and that the entry is not exposed. Re-run: `M35 level catalog evidence: PASS`.

## Tests

**Focused `tests/m28_c002_c002_r01_visual.gd`:** 10/10 cases, 0 fail.
- Every live agent spans 2.4 cells, e.g. 58.6 px on a 24.4 px cell.
- 400-tick trajectory and board truth are identical with 2.4-cell and 1.8-cell bodies.
- Echoes span 2.1 cells (13,310 samples) with a peak of 16 and the unchanged cap.
- Bubble fonts (headline/instruction): 21/18, 18/15, 26/21, 20/17 and 29/24 px across five sizes. They fit on all six shells, re-layout is idempotent, and the 5→6 switch keeps them stable.
- Front hitboxes at 1080×1920 are at least 88.0 px on 3/4/5 cols, with no overlap and previews left alone.
- A margin tap activates its front.
- The AD placeholder is invisible and the region is reserved.
- S1/S4/S5 are preserved.
- The catalog is square-only.
- The masters are unchanged.
- 4× (+1 Slot, retry) leaves nodes at 118 → 118 and HitAreas at 3 → 3.

## Full regression

Run on Godot 4.7.2 headless, 12-way parallel, on the final production code: 110 suites, 467 s.

**Exit 0:** 107 suites, plus `m35_level_catalog` after its migration and re-run, for 108.

Highlights:
- Root `tests/run_tests.gd`: **Total checks: 5323, RESULT: ALL PASS**.
- M28 suites: `m28_c002_c002_r01_visual` 10/10, `m28_c002_c002_static_shell` 16/16, `m28_c002_c001_gameplay_v02` 14/14, `m28_gameplay_layout_smoke` 253 checks with 0 failures.
- M29, all 7: exact slot-origin, realtime movement, input gate, presentation identity, slot display sync, speed authority and Hazard Bot runtime all PASS.
- M32: `m32_scrubbot_visual_evidence` and `m32_scale_59_visuals` PASS.
- M39 A–E, V02, V03, V04 and V04 tornado in-flight PASS.
- M40 save, V02, V03 and V04 bootstrap PASS.
- `m52_owner_supply_plans` PASS (First 10).
- M55 long session, core chaos, economy release, Heart 900 and C002 timed-2x anti-rollback PASS.

**Non-zero:** only the historical M21 baseline, identical to the C002 cycle. It comes from the pre-Railroad-V1 corridor model, and no routing was touched.
- `m21_v08_corridor_validation` (C/043, C/047)
- `m21_v09_direct_evidence_reconciliation` (B)

**`SCRIPT ERROR`:** there are none. The only matches are assertion names in the m20 lifecycle smokes ("…without SCRIPT ERROR"), and those suites PASS.

**Engine `ERROR:` classes** are the same as baseline:
- "resources still in use";
- `Parameter "t" is null`, only from the M28 smoke's own headless PNG capture;
- the root corrupt/missing-image fixtures;
- the M52 malformed-JSON fixture.

**Other checks:**
- `git diff --check`: clean.
- Master SHA-256s: all six MATCH the owner doc, and `git diff` on `assets/ui/final/gameplay/master` is empty.
- The M28 smoke did not change the committed C002 `layout_smoke` metrics.

## Committed files

Production code:
- `scripts/gameplay/presentation/scrubbot_visual.gd`
- `scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd`
- `scripts/ui/ui_text.gd`
- `scripts/ui/gameplay_screen.gd`
- `scripts/ui/batch_supply_panel.gd`
- `scripts/data/level_catalog.gd`

Tests and harness:
- `tests/m28_c002_c002_r01_visual.gd` (new)
- `tests/m35_level_catalog.gd` (S6-C migration)
- `tests/tools/gameplay_v02_snapshot.gd` (R01 shot list)

Session folder `coordination/sessions/M28-C002-C002-R01/`:
- matrix
- owner review
- this log
- `evidence/*.png` (11)

Excluded (owner/local, untouched):
- the pre-existing `project.godot` modification;
- untracked `.import`/`.uid` caches;
- owner media and generated candidates;
- `_owner_inbox`;
- `tests/_m55_diag_tmp.gd`.

## Reproduce

```bash
godot --headless --path . -s res://tests/m28_c002_c002_r01_visual.gd
```

```bash
godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- coordination/sessions/M28-C002-C002-R01/evidence
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C002-R01 VISUAL REMEDIATION COMPLETE`
