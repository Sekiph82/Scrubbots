STATUS: READY

# Build: Per-screen texture budgets and safe size_limit pass (SB-M22-026, step 1)

## Summary
- New stdlib inventory `tools/m22_026_texture_inventory.py` covers all 560 final-art PNGs. For each one it prints the source size, colour type and alpha, MiB at source and at loaded size, `size_limit`, and the largest literal draw size found next to every runtime use. The search covers `scripts/`, `data/` and `HOME_ASSET_MANIFEST.json`; it resolves number consts, `custom_minimum_size` within 4 lines, and Vector2 literals on the use line such as `set_hero(path, Vector2(...))`. If any use has no literal, the size is "unknown". The script also prints the UI-ADR-008 action and the referencing files, then a per-folder table. No row comes out as `CANDIDATE`, so the rule has been fully applied.
- `process/size_limit` is now set on 5 small icons whose draw size is known (the 4x rule):
  - 256: `common/icons/icon_clock`, `daily/daily_streak_flame`, `daily/daily_task_check`
  - 1024: `daily/daily_login_calendar`, `popups/failure/heart_large`
- The library goes from 2897.1 to 2875.2 MiB (-21.9 MiB, -0.76%). **This is not a meaningful reduction, and all four screen totals stay the same**, because none of the 5 icons is loaded by Home, Gameplay, Results or Shop/Collection. UI-ADR-008 states this plainly, and the remaining work is listed as follow-ups. The safety rule was not loosened.
- New test `tests/m22_026_texture_budget.gd` sets per-screen budgets (measured value plus about 10%): Home 228, Gameplay 56, Results 73, Shop/Collection 77 MiB. It also checks the 5 caps and that each keeps alpha.
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` adds UI-ADR-008, and the UI-ADR-007 Consequences sentence is updated.
- `TASKS.md` gets step 1 evidence on the `- [ ] SB-M22-026` entry, which stays open, and an updated queue row.

Commits: `d92b2eb5` (imports, tool, test, doc) and `b3e6bf0c` (TASKS.md).

Files changed: the 5 `.png.import` files above (under `assets/ui/final/`), `tools/m22_026_texture_inventory.py`, `tests/m22_026_texture_budget.gd`, `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` and `TASKS.md`.

**Merge note (same as job 034):** the repo tracks no `.import` files apart from the 10 boosters, so the 5 `.import` files are **new tracked files**. The main checkout has the same 5 paths as untracked Godot-generated files. Delete them there before merging, or the merge stops with "untracked working tree files would be overwritten". After the merge, run `--headless --import`. The test's `.gd.uid` was left uncommitted.

## Acceptance criteria
1. [x] No PNGs are changed. `git diff --name-only main | grep '\.png$'` printed nothing, and `git diff --name-only main -- assets | grep -v '\.import$'` printed nothing.
2. [x] `python -I tools/m22_026_texture_inventory.py` exits 0 and prints 560 `assets/...` rows. In the per-folder table, source MiB totals **2947.7**; loaded MiB was 2897.1 before this change (boosters already capped) and is 2875.2 after. It is stdlib only (`os`, `re`, `struct`, `sys`).
3. [x] The 5 `.import` files are new tracked files (see the merge note), so the diff shows the whole file. Their `[params]` block differs from a default Godot import (compared with `icon_currency_heart.png.import`) only in `process/size_limit` (3x 256, 2x 1024). `compress/mode=0` and `mipmaps/generate=false` are unchanged. No booster `.import` was touched.
4. [x] `"$GODOT" --headless --path <wt> -s res://tests/m22_026_texture_budget.gd` exits 0 with 0 SCRIPT ERROR or Parse Error and prints:
   - Home 207.07 MiB (88 textures, budget 228)
   - Gameplay 50.72 MiB (17, budget 56)
   - Results 65.99 MiB (11, budget 73)
   - Shop/Collection 69.99 MiB (15, budget 77)
   - all 5 caps are within their limit and keep alpha
   - last line `M22-026 TEXTURE BUDGET: PASS`

   Revert check: I set `daily_task_check.png.import` to `size_limit=0` and re-imported. The test printed `FAIL: daily/daily_task_check.png 1261x1247 <= 256` and `M22-026 TEXTURE BUDGET: FAIL (1)`, exit 1. I restored 256, re-imported, and it was back to PASS.
5. [x] UI-ADR-008 contains the table of capped files, before/after MiB per folder (common, daily, popups, all files) and per screen, the four budgets, the untouched files by reason with counts, and the 11 untouched files that have a known draw size listed by name. The per-file reasons for every file are in the inventory's `action` column, which the ADR cites. It also lists the 7 PNGs without alpha and the follow-ups (not done).
6. [x] Suites (LOCAL_PASS):
   - `tools/run_suites.py` with the CI rule:
     - m42_home: `M42 home evidence: PASS`
     - m28_c002_c001_gameplay_v02: PASS 14/14
     - m43_c001a_results_foundation: PASS 11/11
     - m49_responsive_matrix: PASS 8/8
     - m50_color_symbols: PASS 10/10 (see the Log for one flaky run)
   - Run directly, both exit 0 with 0 diag:
     - m22_025_booster_texture_budget: PASS, 9.43/12 MiB
     - m22_026_texture_budget: PASS
7. [x] `git diff --check main` is clean (exit 0).

## Validation
- `$GODOT --headless --path <wt> --import`: exit 0, no error lines. Re-run after each `.import` change.
- `python -I tools/m22_026_texture_inventory.py`: exit 0, 560 rows.
- `m22_026_texture_budget`: PASS, and the negative revert check FAILs as expected.
- `m22_025_booster_texture_budget`, `m42_home`, `m28_c002_c001_gameplay_v02`, `m43_c001a_results_foundation`, `m49_responsive_matrix`, `m50_color_symbols`: PASS (LOCAL_PASS).
- `git diff --check main`: clean. `git status --porcelain` shows no tracked changes; only the existing untracked Godot `.import`/`.uid` noise and the new test's `.uid` remain. The Godot import rewrote `project.godot` and the booster `.import` line endings (noise only), and I restored them with `git checkout --` in the worktree.
- The new test is not added to the CI workflow suite list, the same as the 034 booster test. The spec did not ask for it.

## Log
### Round 1
- Wrote the inventory and checked it against the spec numbers: 560 PNGs, 2947.7 MiB, and 7 without alpha (`bot_parts_bar_frame` is indexed with no tRNS).
- The literal draw-size heuristic is deliberately conservative: a size counts only if every use has a literal nearby. I checked each capped file by hand in code:
  - clock: 52x52 in the refill timer pill (`acquisition_flow.gd:145`)
  - heart: 210x190 in a CenterContainer (`:113`)
  - flame: 52 (`daily_screens.gd:216`)
  - check: `CHECK_SIZE` 34
  - calendar: 132 inline (`CALENDAR_SIZE`) and 240 as a popup hero (`set_hero`, `:327`)
- Treated the calendar and the heart as icons with known draw sizes. At 1024 they keep about 4.3x and 4.9x their draw side. A stricter reading of "hero art" would leave these two untouched and lose 4.6 MiB of the 21.9 MiB saving.
- Excluded from the budgets: catalog card art (cached once viewed; up to 135 x 6 MiB) and the gameplay shells other than the 5-col fallback. Both are noted in the ADR and the test comments.
- Flaky run: m50_color_symbols failed once (`FAIL (10/10 cases, 1 fail)`) while running in the 5-suite batch. A direct run and 3 more run_suites runs all passed 10/10. The suite does not load any of the 5 capped textures. I did not capture which case failed.
