# Booster texture import limit and gameplay texture memory budget (SB-M22-025, booster slice)

> Feature: Validate import/transparency/filtering/mobile memory before visual closure (SB-M22-025). Scoped fix: cap import size of assets/ui/final/boosters/** via .import settings only (never touch source PNGs), add a measurable mobile memory budget for the booster textures (doc line + test assertion), record the other ~550 final PNGs as a follow-up.

## Context
- `assets/ui/final/boosters/` holds 4 icons (`extra_slot|random|selector|tornado.png`, 1254x1254) and `states/` with 6 state arts (selected_ring 1254x1254, unavailable_overlay 1254x1254, activated_burst 1245x1263, reward_glow 1246x1262, tutorial_pointer 1230x1278, free_badge_frame 1774x887). All RGBA, each has a `.png.import` with `compress/mode=0` (lossless, uncompressed in VRAM), `mipmaps/generate=false`, `process/size_limit=0`. Uncompressed total ~60 MiB (1254x1254x4 = 6.0 MiB each).
- Draw sizes (from code):
  - Gameplay booster row, `scripts/ui/gameplay_screen.gd` ~L565-572: button square `bsz = max(Shell.rect(BOOSTERS).size.y * _scale, UiTokens.TOUCH_MIN=88)`, about 100 px on phones. Selected ring and unavailable overlay (`BOOSTER_SELECTED_ART`, `BOOSTER_UNAVAILABLE_ART`, L74-75, used ~L452-456) are drawn at the button size. Sixth-slot (`plus_one_slot`) uses the same row size.
  - Acquisition popup, `scripts/ui/popup/acquisition_flow.gd` L267 icon `custom_minimum_size` 170x170; L537 card icon 140x140; `_badge` (L785) small.
  - Shop, `scripts/ui/shop/shop_screen.gd`, reuses the same icons at list-item size.
  - Largest planned draw = 170 px; x2 hi-dpi = 340 px. Chosen limit 512 (next power of two above 340, headroom for the tablet row size and the not-yet-bound state arts of SB-M22-023).
- Estimated memory at limit 512 (RGBA8, no mipmaps): each square art 1.0 MiB; free_badge_frame 512x256 = 0.5 MiB; others ~1.0 MiB. Total ~9.5 MiB vs ~60 MiB now (about -84%).
- Existing perf suite `tests/m46_performance.gd` is timing/board oriented (p09/p10 are board memory); do not extend it. Existing test pattern: `extends SceneTree`, `_ok(cond, msg)`, prints PASS/FAIL (see `tests/m39c_boosters.gd`).

## Requirements
1. In each of the 10 `.import` files under `assets/ui/final/boosters/` (including `states/`) set `process/size_limit=512`. No other import key changes (keep lossless, no VRAM/lossy compression: art has soft glows/alpha, lossy would risk visual regression; mipmaps stay off). Let Godot re-import (do not hand-edit `uid`/`path`/`dest_files` lines).
2. No source PNG is modified, resized, renamed or overwritten (CLAUDE.md 16). No `.import` outside `assets/ui/final/boosters/` changes.
3. Add `tests/m22_025_booster_texture_budget.gd` (headless, no timing asserts) that:
   a. enumerates every `*.png` under `res://assets/ui/final/boosters/` (recursive) and asserts count == 10;
   b. loads each as `Texture2D` and asserts `max(width,height) <= BOOSTER_TEXTURE_MAX_DIM (512)` and `get_image().get_format()` has alpha (transparency preserved), and a nonzero fraction of pixels with alpha < 255 is not required;
   c. sums `w*h*4` over all and asserts total <= `BOOSTER_TEXTURE_BUDGET_BYTES` = 12 MiB;
   d. asserts every texture-using booster path referenced by `gameplay_screen.gd` (`BOOSTER_DEFS` arts, `BOOSTER_SELECTED_ART`, `BOOSTER_UNAVAILABLE_ART`) and `acquisition_flow.gd` icons loads non-null;
   e. prints one summary line with the total MiB, and `M22-025 BOOSTER TEXTURE BUDGET: PASS` on success.
4. Add a short budget section to `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` (or the doc this repo uses for UI asset import rules): booster textures import at max 512 px, budget 12 MiB RGBA8 resident for the gameplay screen booster set, rationale (largest draw 170 px x2 hi-dpi, Galaxy A10 2 GB / 720x1520), and the rule that new booster art must stay under it.
5. Update `TASKS.md` SB-M22-025 entry: booster slice done (before/after numbers), NOT closed; add a follow-up item (new ID, e.g. SB-M22-026) for the remaining ~550 final PNGs (est. 2.9 GiB resident if all loaded; needs per-screen budgets, size_limit/VRAM compression, 7 PNGs without alpha review). Update AGENTS.md only if it lists import rules that now conflict (otherwise no change).
6. Builder's report states estimated booster texture memory before and after (computed from source dims and loaded dims).

## Acceptance criteria
1. `git -C <worktree> diff --name-only main` lists only: the 10 `assets/ui/final/boosters/**/*.png.import` files, `tests/m22_025_booster_texture_budget.gd` (+ its `.uid`), the doc file, `TASKS.md` and the job folder. No `*.png` appears. Verify: `git diff --name-only main | grep '\.png$'` prints nothing.
2. Each of the 10 `.import` files contains `process/size_limit=512`: `grep -L "process/size_limit=512" assets/ui/final/boosters/*.import assets/ui/final/boosters/states/*.import` prints nothing; `git diff main -- <import files>` shows only that line (plus Godot-regenerated `path/dest_files/md5` hash lines if any) changed.
3. Source PNG hashes unchanged: `git ls-files -s assets/ui/final/boosters | grep png$` blob IDs equal those on `main` (`git diff main --stat -- 'assets/ui/final/boosters/*.png'` empty).
4. `"$GODOT" --headless --path <worktree> --import` completes without errors on the booster files, then `"$GODOT" --headless --path <worktree> -s res://tests/m22_025_booster_texture_budget.gd` prints `M22-025 BOOSTER TEXTURE BUDGET: PASS` (all dims <= 512, total <= 12 MiB, alpha present, 10 files).
5. The test fails if the limit is reverted (builder confirms by temporarily setting one file's size_limit=0, re-importing, seeing FAIL, then restoring) and the report says so.
6. These suites still PASS with their usual PASS lines: `m28_c002_c001_gameplay_v02`, `m39c_boosters`, `m43_c003_c001_acquisition`, `m50_color_symbols`, `m46_performance` (run as `"$GODOT" --headless --path <worktree> -s res://tests/<name>.gd`; report each PASS/summary line; if a suite was already failing on `main`, show the same result on `main`).
7. Doc contains the budget (grep `512` and `12 MiB` in the edited doc) and TASKS.md contains the follow-up item for the other PNGs.

## Out of scope
- Any of the other ~550 final PNGs; mipmaps or filtering changes; VRAM/lossy compression; changing node/draw sizes or layout.
- Editing, resizing or replacing source PNGs; regenerating art.
- Binding the 4 unbound state arts (SB-M22-023).
- Timing assertions; changes to m46_performance; runtime texture-loading code changes.
- Adding export presets or Android device profiling.

## Assumptions
- Limit 512 for all 10 files (one uniform rule) rather than per-file values: simplest, covers 170 px x2 with margin and the tablet row size.
- Lossless kept: soft glow/ring alpha gradients risk banding under lossy/ETC2; size reduction alone gives -84%.
- Budget 12 MiB gives ~25% slack over the ~9.5 MiB expected so a re-import difference does not flake the test.
- A new small test file is used instead of extending m46_performance, which is a timing/board-memory suite and not a fit for texture assertions.
- The Godot version-specific `.import` regeneration (md5/path lines) is acceptable noise.
