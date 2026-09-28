# M28-C002-C002 — CLAUDE LOG V01 — 3/4/5 × 5/6 static master shell

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict or owner acceptance is claimed.
Prompt: `coordination/sessions/M28-C002-C002/task_prompts/SB-M28-C002-C002_STATIC_MASTER_SHELL.md`
Owner authority: `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`
Base: fast-forwarded to `origin/main` `cc1e324`. Root `TASKS.md` read only, not edited.

Evidence:
- `coordination/sessions/M28-C002-C002/GAMEPLAY_STATIC_SHELL_MATRIX_V01.md` (intake, measured coordinates, requirement→test table, sensitivity, defects fixed, scope notes)
- `coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md` (12 screenshots, S1–S6 visual-only items)
- `coordination/sessions/M28-C002-C002/evidence/*.png` (12)
- `coordination/sessions/M28-C002-C002/layout_smoke/viewport_metrics.{json,md}`

## History of this cycle

- **Attempts 1 and 2:** stopped at Step 0 with `OWNER_ASSET_REQUIRED`. The masters were not in any authorized location, so nothing was substituted and nothing was changed.
- **Attempt 3 (this log):** the owner placed the six files, under their canonical names, in `ScrubBots Gorselleri\Game Screens\`.

## Step 0 — intake

- All six SHA-256 values matched the locked values exactly, before and after copying.
- All six are 887×1774 RGBA.
- Copied byte-for-byte into `assets/ui/final/gameplay/master/gameplay_v02_shell_{5,6}slot_{3,4,5}col.png`. The table is in matrix §1.
- The owner-side `README.txt` / `SHA256_MANIFEST.json` were read as data only.
- `scrubbots_gameplay_master.png` was preserved.
- Godot needed an import pass for the new PNGs (`godot --headless --import`). As with every asset in this repo, the `.import` files stay untracked.

## Implementation

| File | Change |
|---|---|
| `scripts/ui/gameplay_shell_geometry.gd` (new) | Pure data: the six shells' measured master-px tables (rail centrelines, slot frames, baked connector x, supply cell grid), the shared top boxes, bubble text mask, booster/ad bands, locked SHA-256s. Plus `shell_id(cols, capacity)` (fail-closed "") and small rect helpers. |
| `scripts/ui/gameplay_screen.gd` | Rebuilt as a static-shell overlay screen. <br>- Selection runs from the supply column count and the live strip capacity. <br>- One uniform reference transform (aspect-fit 1:2 inside the safe rect). <br>- `GameplayShell` TextureRect. <br>- Board fitted to the baked rail: square cell at the mean of the two fits, capped at 3 % over the strict fit; integer render cell plus a fractional presentation scale. <br>- `ScrubRailView` hidden (geometry only). <br>- Slots/supply placed on the baked frames/cells. <br>- Profile, Pause/2x and booster/ad overlays; bubble mask. <br>- The C001 HUD, speed, booster and connector APIs are kept. <br>- All C001 native chrome removed. |
| `scripts/ui/five_slot_strip.gd` | Now a `Container`. Even layout by default (as before); `set_slot_rects()` places slot views on explicit rects synchronously, so route origins are valid immediately. The public API is unchanged. |
| `scripts/ui/batch_slot_view.gd` | Shell mode: an empty slot is transparent (baked frame); an occupied slot shows only its live colour, count and state, with a cyan edge when ACTIVE. |
| `scripts/ui/batch_supply_panel.gd` | Shell grid mode: equal cells with the baked gaps and no frame chrome. Empty = transparent; batch = live colour plus count; the front row has a cyan edge; preview rows are dimmed. Input/gesture logic untouched. |
| `scripts/gameplay/board/board_renderer.gd` | `get_cell_center_global` is now transform-aware. Its only caller is the screen accessor, and the result is identical when unscaled. |

Unchanged:
- `ProductionGameplayHost` (its C001 seams drive the 5↔6 switch);
- routing, `ScrubRailGeometry`, targeting, slot/supply engines, input controller logic, completion/retry;
- economy, Heart, 2x rules, anti-rollback;
- level content and supply plans;
- `TASKS.md`.

## Visual self-review (rendered images inspected)

At every size, and for all six shells:
- the master fills the screen;
- level art sits inside the baked board field;
- Scrubbots visibly ride the baked bottom rail and connectors;
- live slot contents fill 5 or 6 baked frames, and supply colours/counts fill 3/4/5 × 3 baked cells;
- the profile, Pause and 2x overlays sit in their baked boxes;
- timed 2x reads "2x / 14:58";
- the bubble is blank, the obsolete sentence is masked, and no duplicate chrome is visible;
- the tall phone letterboxes and the tablet pillarboxes in a dark fill.

Defects found in the renders and tests, and fixed (matrix §6):
- selection timing;
- 13–27 px rail misfit, now ≤ 4.9 px;
- booster-row shrink clamp;
- the missing import pass.

## Tests

**New: `tests/m28_c002_c002_static_shell.gd`**: exit 0, 79 ok, 16/16 cases (the 16 prompt requirements plus the master hash lock). Key measurements:
- rail error ≤ 4.9 px;
- agents within 4.9 px of the baked rail (9 334 samples) and 6.1 px of the baked connectors (6 170);
- supply cells ≤ 2.1 px;
- slots ≤ 1.5 px;
- 3 cycles of 5→6→5 for each of 3/4/5 columns with gameplay state intact;
- 7-size transform matrix plus notch/gesture safe area.

**Sensitivity:** 7 mutations, all failing the suite (matrix §5). One gap was found and closed: a non-uniform stretch initially passed because the test read the transform, not the real shell node.

**Migrated** (owner decision supersedes the C001 native geometry; safety intent kept):

| File | Change |
|---|---|
| `tests/m28_c002_c001_gameplay_v02.gd` | Slot / supply-front minimums (120 / 88 px) become ≥ 80 px baked frames/cells. The auto-2x indicator moves from modulate to the green state fill. "2x at the safe edge" becomes "in the top-right baked boxes". Also prints dominance areas. 14/14. |
| `tests/m28_gameplay_layout_smoke.gd` | Top-right / profile checks use the top-band halves. The supply protected width (620) becomes ≥ 80 px baked column cells. Evidence moved to this session, and the C001 session's metrics files were restored to their committed state. 253 checks, 0 failures. |
| `tests/m29_exact_slot_origin_evidence.gd` | Board and slots now share one uniform transform, so board-local slot origins are correctly size-invariant. "No stale cached coordinate" is now proven by the on-screen anchors moving while the provider returns the live remapped value. A stale global cache still fails the neighbouring "tracks the visible mapping" assertions. PASS. |

## Full regression (Godot 4.7.2.stable.official.ed1daf0bf, headless, 12-way parallel, final production code, 109 suites)

- 106 suites exit 0.
- The root suite `tests/run_tests.gd` reports **5323 checks, RESULT: ALL PASS**.
- `m28_c002_c002_static_shell` 79 ok, `m28_c002_c001_gameplay_v02` 14/14, `m52_owner_supply_plans` 255 (First 10 all WON).
- Everything else in M20–M55 has the same counts as the previous cycle.

Non-zero exits:
- **`m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B):** the identical historical baseline failures, already shown to be present at the previous HEAD. They come from the pre-Railroad-V1 corridor model, and this cycle touched no routing.
- **`m29_exact_slot_origin_evidence`:** its "origins must move" assertion encoded the old non-uniform layout. Migrated as described above and re-run → PASS.

After the regression, the only changes were test-side: the M29 migration and the smoke evidence directory. Both suites were re-run and pass.

Engine `ERROR:` classes are the same as baseline:
- "resources still in use";
- the M52 malformed-JSON fixture;
- root corrupt/missing-image fixtures;
- `Parameter "t" is null`, only from the M28 smoke's own headless PNG-capture attempt, whose code is unchanged.

`git diff --check`: clean.

## Committed files

- `assets/ui/final/gameplay/master/gameplay_v02_shell_{5slot,6slot}_{3col,4col,5col}.png` (6 owner masters, byte-exact)
- `scripts/ui/gameplay_shell_geometry.gd` (new)
- `scripts/ui/gameplay_screen.gd`
- `scripts/ui/five_slot_strip.gd`
- `scripts/ui/batch_slot_view.gd`
- `scripts/ui/batch_supply_panel.gd`
- `scripts/gameplay/board/board_renderer.gd`
- `tests/m28_c002_c002_static_shell.gd` (new)
- `tests/tools/gameplay_v02_snapshot.gd`
- `tests/m28_c002_c001_gameplay_v02.gd`
- `tests/m28_gameplay_layout_smoke.gd`
- `tests/m29_exact_slot_origin_evidence.gd`
- `coordination/sessions/M28-C002-C002/`:
  - matrix, owner review, this log
  - `evidence/*.png` (12)
  - `layout_smoke/viewport_metrics.{json,md}`

Excluded (owner/local, untouched):
- the pre-existing `project.godot` modification;
- untracked `.import`/`.uid` caches;
- owner media and generated candidates;
- `_owner_inbox`;
- `tests/_m55_diag_tmp.gd`.

## Reproduce

```bash
godot --headless --path . -s res://tests/m28_c002_c002_static_shell.gd
```

```bash
godot --path . -s res://tests/tools/gameplay_v02_snapshot.gd -- coordination/sessions/M28-C002-C002/evidence
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C002 3-4-5 STATIC MASTER SHELL`
