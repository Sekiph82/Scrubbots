STATUS: READY

# Build: SB-PHONE-2026-11-12-D board top-row contrast (Level 20)

## Summary
Branch `factory/151-board-top-contrast`, commit `fe6bf9d5`.

Root cause: a contrast and background problem. The board is not clipped and not offset.
- The board sits exactly where the baked rail requires: the runtime rail centrelines are 2.5 cells outside the board. No cell sits under the frame tube. The frame's inner metal edge is 24 master px from the rail centreline, and the outermost board edge on a 40x40 board is about 41 master px from it (28.7 px on 59x59).
- The production board had no backdrop of its own. CLEARED holes showed the baked shell's blue board field, which is about (0,48,107) and not BG01 #202533. That breaks CLAUDE.md §7/§8 (CLEARED shows BG01). The board magnifier and the debug/M21 views already draw BG01.
- On any board larger than about 31 cells, the outer row and column overhang the edge of the baked field. On 40x40 (L20/L30) the overhang is about 0.8 cell per side, so the outer cells sit on the field's bright blue bevel, about (0,71,183). The circled cells are C08 Dark Blue #2450A4. Their contrast against that bevel is 1.07:1, so they are effectively invisible, and they also blend into the navy field (1.69:1). Mid-play, once the C08 sky below is cleared, the top row looks like it runs under the top-right frame corner.

Fix: `BoardPresentation` now creates one identity-stable `ColorRect` "BoardBackground" filled with BG01. It is the first child, ignores input, and is sized exactly to the BoardRenderer rect. CLEARED cells (still alpha 0) and the edge rows now sit on BG01. There are no per-cell nodes, the artwork, palette and board geometry are unchanged, and the rail/agent transform is untouched.

Files changed:
- `scripts/gameplay/board/board_presentation.gd`: BG01 const, BoardBackground ColorRect, `get_background()`.
- `tests/board_bg01_backdrop.gd`: new permanent suite, 4 cases, 38 checks.
- `.github/workflows/android-family-first10.yml`: new suite added to the loop, plus an exact `4/4` guard and a header note.

TASKS.md was not edited, as the coordinator instructed.

## Contrast numbers (WCAG ratio; all 30 production catalog levels scanned)
| Colour | vs BG01 | vs shell field | vs field bevel |
|---|---|---|---|
| C08 Dark Blue #2450A4 | 2.01 | 1.69 | 1.07 |
| C14 Dark Gray #515252 | 1.95 | 1.64 | 1.04 |
| C16 Black #000000 | 1.37 | 1.64 | 2.59 |
| C09 Periwinkle | 3.34 | 2.81 | 1.77 |
| C11 Brown | 3.25 | 2.73 | 1.73 |

Levels using colours below 3:1:
- On BG01 (after the fix): C08 in 18 levels, C14 in 13, C16 in 29.
- On the old field: C08 18, C09 4, C11 18, C14 13, C16 29.
- On the old bevel: also C01 16, C07 10, C10 10, plus C08/C09/C11/C14/C16.

The fix improves C08, C14, C09 and C11, and removes the near-invisible bevel case for all edge cells. Trade-off: black (C16, 29 levels) drops from 1.64 to 1.37 against BG01. BG01 is the owner-locked background, and black cells keep the shader's grid gutter and bevel. The largest production boards are 40x40 (L20, L30). The 59x59 envelope was checked with a TEST fixture.

## Captures (in this job folder)
- `before_L20_{720x1520,1080x2400,1170x2532}.png`: fresh L20 before the fix.
- `after_L20_{720x1520,1080x2400,1170x2532}.png`: fresh L20 after the fix.
- `before_midplay_L20_*.png` / `after_midplay_L20_*.png`: matches the owner's state. All 448 C08 cells below the top row are CLEARED as presentation evidence, captured without and with the backdrop. Before: the top C08 row melts into the bevel and field. After: it reads clearly on BG01.

The captures are windowed GPU SubViewport renders of a real ProductionGameplayHost at the given level. They do not boot main.tscn, and each uses a temp save that is deleted afterwards.

## Acceptance criteria
1. [x] Investigate clip/offset vs contrast for L20 at 720x1520, and check whether the board background is BG01. Evidence: board rect at 720x1520 is (92.3,247.2) size 535.7; rail region is (62.1,210.5) size 596x609. The frame inner edge is at (81.6,229.9) size 557x570, so the board is inside it. Master pixel scan of `gameplay_v02_shell_5slot_3col.png`: field interior is about x127..760 and y263..910, with the bevel just outside it. The board covers x113.8..773.8 and y255..915 in master px, so it overhangs the bevel. The board background was the shell's navy field, not BG01. Root cause as above.
2. [x] Fix without altering artwork or palette. Evidence: only a BG01 ColorRect was added under the renderer. BoardRenderer still draws CLEARED as `Color(0,0,0,0)` (tested). No level, palette or shell file was touched.
3. [x] Scan other levels for poor-contrast colours. Evidence: the table above.
4. [x] Board cell rect fully inside the visible panel/frame area at 720x1520, 1080x2400 and 1170x2532 for L20 and the largest board. Evidence: `tests/board_bg01_backdrop.gd` checks L20, L30 (40x40, the largest production boards) and a 59x59 fixture at all three sizes. Each check asserts the board rect is enclosed by the baked rail rect inset by the 24 master px frame half-width.
5. [x] Board background equals BG01. Evidence: the same suite asserts BG01 equals palette V3 `gameplayBackground` (#202533). It also asserts there is exactly one BoardBackground, at child index 0 under the renderer, ignoring input, with a global rect equal to `get_board_rect()` within 0.5 px, and that a CLEARED cell has alpha 0 over it.
6. [x] Affected suites run and the CI guard added. See Validation.

## Validation (LOCAL_PASS, Godot 4.7.2 headless, worktree)
All of these exited 0 with 0 SCRIPT ERROR / Parse Error lines:
- `board_bg01_backdrop`: PASS (4/4 cases, 0 fail), 38 ok checks.
- `m29_presentation_identity_evidence`: PASS.
- `m32_c002_board_independent_size`: PASS (86 checks, 0 failed).
- `m50_board_symbols`: PASS (8/8).
- `m28_c002_c002_static_shell`: PASS (16/16).
- `m31_cleaning_effects_evidence`: PASS.
- `m28_c002_c001_gameplay_v02`: PASS (14/14).
- `m28_c002_c004_tile_visual`: PASS (17/17).
- `m49_responsive_matrix`: PASS (8/8).
- `m47_touch_r01_mobile_ux`: PASS (14/14).
- `run_tests`: RESULT: ALL PASS.

`m50_color_symbols` FAILS locally on one timing check only: 10/10 cases, 1 fail, "300 rebinds in N ms" with a limit of 3000 ms. The check is a supply-panel rebind loop that never touches the board. Interleaved runs on this machine:
- Without the change: 2185, 3907 and 3739 ms (the last two fail).
- With the change: 4605, 5265, 3309 and 3302 ms.

The baseline fails the same check, so this is pre-existing machine-load timing flake and not caused by this change. No case count changed.

Other checks:
- `python tools/run_suites.py --list` includes `board_bg01_backdrop` (90 suites).
- `--selftest` PASS.
- `git diff --cached --check` clean.

## Log
### Round 0 (first build)
Investigated with GPU captures and a pixel scan of the shell master: no clipping or offset, a contrast and missing-BG01 root cause as above. Added the BG01 BoardBackground to BoardPresentation. The first version drew it in `_draw()`; I switched to a single ColorRect so headless tests can assert it directly. Added the permanent suite and its CI guard, ran the suites, saved before/after captures and committed `fe6bf9d5`.

Worktree note: the Godot `--import` I ran left about 1234 untracked import artefacts (.uid/.import/.translation) in the worktree. The tracked `.import` and `project.godot` rewrites were restored. My `git clean` of the untracked files was denied by the permission system, so they need to go when the worktree is deleted. Nothing is uncommitted apart from those artefacts.
