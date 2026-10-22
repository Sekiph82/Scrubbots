STATUS: READY

# Build: Booster texture import limit and gameplay texture memory budget (SB-M22-025, booster slice)

## Summary
All 10 booster textures (`assets/ui/final/boosters/**`) now import with `process/size_limit=512`. They stay lossless, mipmaps stay off and the source PNGs are untouched. A new headless test enforces the 512 px cap, alpha, the 12 MiB resident budget and that every referenced booster path loads. The doc and TASKS.md are updated.

Estimated resident RGBA8 memory: **before 59.99 MiB** (62,901,844 B from source dims: 6 x 1254x1254, 1245x1263, 1246x1262, 1230x1278, 1774x887). **After 9.43 MiB** (9,889,792 B from loaded dims: 7 x 512x512, 504x512, 505x512, 492x512, 512x256), which is -84%.

Commits: `e37daeb4` (imports + test + doc), `9eb47483` (TASKS.md).

Files changed:
- `assets/ui/final/boosters/{extra_slot,random,selector,tornado}.png.import`
- `assets/ui/final/boosters/states/booster_{activated_burst,free_badge_frame,reward_glow,selected_ring,tutorial_pointer,unavailable_overlay}.png.import`
- `tests/m22_025_booster_texture_budget.gd` (new)
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` (new UI-ADR-007)
- `TASKS.md` (SB-M22-025 entry, new SB-M22-026, queue rows)

**Deviation from the spec premise (important for merge):** the spec assumes the `.import` files are tracked. They are not. The repo tracks 0 `*.import` files, so each fresh checkout regenerated them with the defaults (`size_limit=0`). This branch therefore **adds** the 10 files as new tracked files. The diff is the whole file, not just one line, and only `size_limit` differs from Godot's defaults. The main checkout `C:/Users/sekip/Desktop/ScrubBots` has these same 10 paths as **untracked**, Godot-generated files. A merge or fast-forward there will stop with "untracked working tree files would be overwritten". Before merging, the merger must delete those 10 untracked `assets/ui/final/boosters/**/*.png.import` files in the main checkout. They are generated files, not owner work. After the merge, run `--headless --import` there so the 512 px `.ctex` files are rebuilt. I did not touch the main checkout. The test's `.gd.uid` was left uncommitted; the repo only tracks 3 test uids.

## Acceptance criteria
1. [x] Diff vs main contains only the allowed files: `git diff --name-only main` lists the 10 booster `.png.import` files, `tests/m22_025_booster_texture_budget.gd`, `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` and `TASKS.md`. `git diff --name-only main | grep '\.png$'` printed nothing.
2. [x] `grep -L "process/size_limit=512"` over both globs printed nothing. All 10 files are new tracked files (see the deviation above). Their only non-default key is `process/size_limit=512`, and `compress/mode=0` and `mipmaps/generate=false` are unchanged.
3. [x] `git diff main --stat -- 'assets/ui/final/boosters/*.png'` was empty, so the PNG blobs are unchanged.
4. [x] `"$GODOT" --headless --path <wt> --import` exited 0 with no error lines. The budget test then printed `booster textures resident RGBA8: 9.43 MiB (budget 12 MiB)` and `M22-025 BOOSTER TEXTURE BUDGET: PASS`, exit 0, with no SCRIPT ERROR or Parse Error. It found 10 files, all dims <= 512 and every one RGBA (alpha).
5. [x] Revert check: I set `random.png.import` to `size_limit=0` and re-imported. The test printed `FAIL: ...random.png 1254x1254 <= 512`, `14.43 MiB`, `FAIL: total 15131280 <= 12582912 bytes` and `M22-025 BOOSTER TEXTURE BUDGET: FAIL (2)`, exit 1. I then restored 512, re-imported, and it was back to PASS at 9.43 MiB.
6. [x] Regression suites, all exit 0 with 0 SCRIPT ERROR or Parse Error (LOCAL_PASS):
   - m28_c002_c001_gameplay_v02: `M28-C002-C001 Gameplay V02 core evidence: PASS (14/14 cases, 0 fail)`
   - m39c_boosters: `M39 Phase C evidence: PASS`
   - m43_c003_c001_acquisition: `M43-C003-C001 acquisition evidence: PASS (34/34 cases, 0 fail)`
   - m50_color_symbols: `M50 color symbols evidence: PASS (10/10 cases, 0 fail)`
   - m46_performance: `M46 performance evidence: PASS (22/22 cases, 0 fail)`
7. [x] The doc has UI-ADR-007 with `512` and `12 MiB`. In TASKS.md, SB-M22-025 has the booster-slice note with before/after numbers and stays NOT closed. The new `- [ ] SB-M22-026` item covers the ~550 remaining final PNGs (2.9 GiB, per-screen budgets, size_limit/VRAM compression, 7 no-alpha PNGs). The queue row for 023/025 was updated and a new `READY SB-M22-026` row was added. TASKS.md line endings match the main blob (LF). AGENTS.md was unchanged because it has no conflicting import rules.

## Validation
- `$GODOT --headless --path <wt> --import`: PASS (exit 0)
- `-s res://tests/m22_025_booster_texture_budget.gd`: PASS (LOCAL_PASS); the negative revert check FAILs as expected
- `m28_c002_c001_gameplay_v02`, `m39c_boosters`, `m43_c003_c001_acquisition`, `m50_color_symbols`, `m46_performance`: all PASS (LOCAL_PASS)
- `git status --porcelain` shows no tracked changes; only the pre-existing untracked Godot `.uid`/`.import` noise and the new test's `.uid` remain.

## Log
### Round 1
- Set `process/size_limit=512` in the 10 booster `.import` files, re-imported, and found the `.import` files were untracked repo-wide. I committed these 10 so the setting persists across checkouts.
- Added `tests/m22_025_booster_texture_budget.gd` (count 10, max dim 512, RGBA, total <= 12 MiB, the paths referenced by gameplay_screen `BOOSTERS`/`BOOSTER_SELECTED_ART`/`BOOSTER_UNAVAILABLE_ART` and acquisition_flow `BOOSTER_DEFS` load). Confirmed that it fails when a limit is reverted.
- Added UI-ADR-007 to `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`, updated TASKS.md (SB-M22-025 booster slice done but not closed, new SB-M22-026) and ran the 5 regression suites.
