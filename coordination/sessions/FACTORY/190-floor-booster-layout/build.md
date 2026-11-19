STATUS: READY

# Build: 190-floor-booster-layout (SB-TF-10)

## Summary
Branch `factory/190-floor-booster-layout`, commit `1dce8e1b` (on top of origin/main `f9af68e8`). Not pushed or merged.

- **Board floor.** The floor is now one constant, `BoardPresentation.BOARD_FLOOR = Color8(0, 104, 216)` (#0068D8, the owner-picked rail-glow blue). The four-entry `BOARD_FLOOR_TONES` list and the `BOARD_FLOOR_TONE` selector are removed. The owner waiver of the 1.3:1 C01..C16 contrast rule is recorded in three places:
  - the code comment;
  - `docs/MASTER_UI_SYSTEM.md`;
  - the new §12 in `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`.

  The measured minimum contrast is now 1.123:1. The test prints this as info only.
- **Masters.** The six masters were regenerated with `tools/gameplay_shell_masters.py`, which lifts the baked navy board field to #0068D8. I also fixed a script bug: the lift now runs after the cut-joins for each variant. When it ran before them, the brighter field moved the 6-slot right rail seam from x 700 to x 703, so the 6-slot rail pixels no longer matched main. Now:
  - the three 5-slot masters are the same either way;
  - the 6-slot seam is back at x 700, and the rail, slot interiors and Supply cells match main byte for byte.

  New SHA-256 values are in `Shell.SHA256` and in doc §12.
- **Boosters.** `Shell.BOOSTERS` is now [172,1516,680,1636]:
  - Same 508x120 band as before, so button size and tap targets are unchanged.
  - Directly under the Supply panel's baked shadow (y 1515).
  - Horizontally centred on the 852 master, which is centred on screen.

  The row may draw over Scrubby. It stays clear of the Supply cells and front tap targets (5-column case included), the slots, the props and the banner. The only ScreenContent child after it is the board-sized magnifier touch area: it does not intersect the row, and its loupe is hidden unless the board is held.
- **Capture tool.** `tests/tools/board_floor_tones_capture.gd` (the four-tone comparison tool) is deleted. It is replaced by `tests/tools/gameplay_layout_capture.gd`.

Files changed:
- `scripts/gameplay/board/board_presentation.gd`
- `scripts/ui/gameplay_shell_geometry.gd`
- `tools/gameplay_shell_masters.py`
- `assets/ui/final/gameplay/master/gameplay_v03_plaza_shell_{5,6}slot_{3,4,5}col.png` (6 files)
- `tests/sb_tf04_gameplay_layout.gd`
- `tests/m28_c002_c002_static_shell.gd` (booster icons may now overlap Scrubby)
- `tests/board_bg01_backdrop.gd`
- `tests/tools/gameplay_layout_capture.gd` (new)
- `tests/tools/board_floor_tones_capture.gd` (deleted)
- `docs/MASTER_UI_SYSTEM.md`
- `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`
- `.github/workflows/android-family-first10.yml` (comment only; the guard line `SB-TF-04 gameplay layout evidence: PASS (7/7 cases, 0 fail)` is unchanged)

TASKS.md was not edited, as the orchestrator instructed.

## Acceptance criteria
1. [x] **Floor #0068D8, alternatives removed, waiver recorded, masters regenerated.** `sb_tf04_gameplay_layout` case `board_floor_tone` checks:
   - `BoardBackground.color == BOARD_FLOOR` == #0068D8;
   - the `BOARD_FLOOR_TONES` and `BOARD_FLOOR_TONE` constants are absent;
   - the floor is brighter than BG01 and equals no C01..C16 colour;
   - the master board-field centre pixel is about #0068D8.

   The capture pixel at (585,1250) in `layout_5slot_5col_1170x2532.png` reads (0,104,216). Case `masters_regenerated` passes: all six SHAs match, and the rail, slot interiors and Supply cells match main byte for byte.
2. [x] **Boosters directly under Supply, centred, same size, may overlap Scrubby, cover nothing, nothing covers them.** `sb_tf04_gameplay_layout` checks all six shells at 8 viewports (720x1280 to 1536x2048):
   - the band is below the Supply panel and at least 2 px above the banner;
   - row and buttons are centred to within 1.5 px (the shell origin and the row separation are whole pixels; the largest offset measured was 1.2 px);
   - the button side equals max(floor(band height), TOUCH_MIN), the same as before;
   - no Supply front tap target, Supply cell or slot is hit;
   - only the non-overlapping magnifier comes after the row in draw order;
   - the band overlapping Scrubby is allowed, and every other overlap check still passes.

   `m28_c002_c002_static_shell` still checks that the icons stay clear of supply, props, bubble and AD.
3. [x] **Evidence PNGs** were produced by `godot --path <wt> -s res://tests/tools/gameplay_layout_capture.gd -- --out <job>/evidence` (windowed, after `--import`):
   - `evidence/layout_5slot_4col_720x1520.png`
   - `evidence/layout_5slot_5col_720x1520.png`
   - `evidence/layout_5slot_4col_1170x2532.png`
   - `evidence/layout_5slot_5col_1170x2532.png`

   I viewed them. The bright blue floor shows through the CLEARED holes and around the board. The four boosters sit centred just under the Supply panel, over Scrubby's broom hand, above the banner, and clear of the bucket and sign.
4. [x] **The touched CI-list suites pass locally** (LOCAL_PASS table below).

## Validation
`$GODOT --headless --path <wt> --import` was re-run after the final master regeneration. Then each suite was run with `godot --headless --path <wt> -s tests/<suite>.gd`. Every one exited 0 with no SCRIPT ERROR or Parse Error. LOCAL_PASS:

| suite | last line |
|---|---|
| sb_tf04_gameplay_layout | `SB-TF-04 gameplay layout evidence: PASS (7/7 cases, 0 fail)` (389 ok) |
| board_bg01_backdrop | `Board BG01 backdrop evidence: PASS (4/4 cases, 0 fail)` |
| m28_c002_c002_static_shell | `M28-C002-C002 static master shell evidence: PASS (16/16 cases, 0 fail)` |
| m28_c002_c002_r01_visual | `M28-C002-C002-R01 visual remediation evidence: PASS (10/10 cases, 0 fail)` |
| m28_c002_c001_gameplay_v02 | `M28-C002-C001 Gameplay V02 core evidence: PASS (14/14 cases, 0 fail)` |
| m28_c002_c003_final_gate | `M28-C002-C003 final popup-inclusive gate: PASS (22/22 cases, 0 fail)` |
| m28_gameplay_layout_smoke | `==== M28 layout smoke: 253 checks, 0 failures ====` |
| m49_ad_store_return_layout | `M49 ad/store return layout evidence: PASS (6/6 cases, 0 fail)` |
| m49_responsive_matrix | `M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)` |
| m50_board_symbols | `M50 board symbols evidence: PASS (8/8 cases, 0 fail)` |
| sb_tf06_tornado_video | `SB-TF-06 tornado video evidence: PASS (12/12 cases, 0 fail)` |
| sb_video_005_level_intro | `SB-VIDEO-005 level intro: PASS (9/9 cases, 0 fail)` |

Other checks:
- `git diff --cached --check` was clean.
- `python -I tools/gameplay_shell_masters.py <owner plaza png> assets/ui/final/gameplay/master/` reproduces the committed SHAs.

Left uncommitted on purpose, as in earlier jobs:
- Godot import churn (`.import`, `.uid`, `project.godot`).
- The `m28_gameplay_layout_smoke` metrics files that the suite rewrites on every run. I restored these to HEAD.

## Log
### Round 1
- Built the change from origin/main `f9af68e8`.
- First run of `sb_tf04` showed two problems, both fixed:
  - The "nothing after the booster row" check was wrong. The magnifier touch area is a visible, board-sized control. The check now requires that it does not intersect the row and that the loupe is not inspecting.
  - The centring tolerance was too tight at 1.0 px. It is now 1.5 px, because of whole-pixel origin and separation rounding.
- Found and fixed the 6-slot seam drift in the master script: the lift now runs after the cut-joins.
- `m28_c002_c002_r01_visual` failed once only because that run read masters I regenerated partway through. It passes on the rerun.
- Commit: `1dce8e1b`.
