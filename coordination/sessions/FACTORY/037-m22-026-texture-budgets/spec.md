# Per-screen texture budgets and safe size_limit pass (SB-M22-026, step 1)

> Feature: SB-M22-026 per-screen texture memory budgets for the other ~550 final-art PNGs (all lossless compress/mode=0, mipmaps off, ~2.9 GiB if all resident; 7 PNGs without alpha). Safe, job-sized step: stdlib inventory script; `process/size_limit` only on files far larger than any plausible draw size; budget test for Home, Gameplay, Results, Shop/Collection; doc UI-ADR-008. Low-end target Galaxy A10 (2 GB RAM, 720x1520).

## Context
- `assets/ui/final/**` has 560 PNGs (19 folders: boosters, branding, cards_exchange, characters, collection, common, daily, decorative, difficulty, events, gameplay, home, marketing, popups, rewards, robots, shop, system). Each has a `.import` with `compress/mode=0`, mipmaps off. Estimated resident RGBA8 at source size is 2947.7 MiB; 252 files have a side >= 1500 px (logos 2172x724, button frames 1536x1024, robot poses 1024x1536 and similar).
- Precedent (factory 034): UI-ADR-007 in `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`; boosters set to `process/size_limit=512` in `.import` only; `tests/m22_025_booster_texture_budget.gd` (budget + load check). Follow its structure and `_ok`/PASS-line style.
- Screens: `scripts/ui/gameplay_screen.gd`, Home, Results, Shop/Collection scripts (builder locates the real files; suites `m42_home`, `m43_c001a_results_foundation`, `m28_c002_c001_gameplay_v02` show how they load).

## Requirements
1. Add `tools/m22_026_texture_inventory.py` (stdlib only: `struct` for PNG IHDR, `re`, `os`). For every PNG under `assets/ui/final/**` it prints: path, source WxH, colour type/alpha yes-no, RGBA8 MiB, current `size_limit` (from `.import`), referencing files (grep `res://` path in `*.gd`, `*.tscn`, `*.tres`, `*.json` outside `assets/`), and max on-screen draw size when a literal `custom_minimum_size`/`Vector2` size is determinable (else "unknown"). Output a per-folder MiB table and a CSV/markdown to stdout (do not commit generated output beyond the numbers cited in UI-ADR-008).
2. Apply `process/size_limit` in `.import` files only, and only where all hold: the file is referenced, the draw size is determinable or the category rule below applies, and source max side >= 2x (draw size x 2 for hi-dpi at 1080x2400 portrait). Category rule (conservative):
   - icons/badges/buttons/frames/chips (small UI elements): limit = next power of two >= 4x the largest known draw side, never below 256;
   - full-screen backgrounds, hero art, home robot poses, logos, anything whose draw size is unknown or at/above 540 px: UNTOUCHED (must keep resolution relevant to 1080x2400).
   Files not meeting the rule are left untouched and listed (path + reason) in UI-ADR-008 or the inventory output cited there.
3. No lossy/VRAM compression anywhere (`compress/mode` stays 0); mipmaps unchanged; the 7 no-alpha PNGs are listed in UI-ADR-008 with a note that they stay lossless (no change to them unless they are also size_limit candidates).
4. Never modify any `*.png`. Commit the changed `.import` files. Do not touch booster `.import` files (already done in 034).
5. Add `tests/m22_026_texture_budget.gd` (model on the 034 test). It declares, for each of Home, Gameplay, Results, Shop/Collection, the list of texture paths that screen loads (derived from the inventory's reference data; shared textures counted per screen), sums `w*h*4` of the loaded `Texture2D`s, and asserts each total <= a concrete MiB budget set from the measured post-change value plus about 10% headroom. It also asserts every size_limit'ed file loads at <= its limit and keeps alpha where the source had it. Prints per-screen MiB and ends with `M22-026 TEXTURE BUDGET: PASS` or `FAIL (n)`, exit code 1 on fail. The test must fail if a limit is reverted (builder verifies once by reverting one `.import`).
6. Add `UI-ADR-008` to `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` (same format as UI-ADR-007): decision, the category rule, before/after MiB per category (folder) and per screen, the four budgets, the untouched-files list, the 7 no-alpha PNGs, and follow-ups (VRAM compression, atlasing, runtime lazy loading) as not done. Update the UI-ADR-007 "Consequences" sentence that says other folders have no budget. If the reduction is not meaningful (say, under 15% of total or per-screen unchanged), state this plainly in the ADR and keep the rest as follow-up rather than lowering the safety rule.
7. Update `AGENTS.md`/TASKS.md only as the factory loop needs (SB-M22-026 evidence line stays open/partial if folders remain uncovered); no new tracker files.

## Acceptance criteria
1. `git diff --name-only main` contains no `*.png`. Everything under `assets/` in the diff is a `.import` file: verify with `git diff --name-only main -- assets | grep -v '\.import$'` printing nothing.
2. `python tools/m22_026_texture_inventory.py` runs with stdlib only, exits 0, and prints 560 rows plus a per-folder table whose total before the change is about 2947.7 MiB.
3. Every changed `.import` has `process/size_limit` set, `compress/mode=0` and mipmaps unchanged (`git diff main -- '*.import'` shows only `process/size_limit` lines changed).
4. `"$GODOT" --headless --path <worktree> -s res://tests/m22_026_texture_budget.gd` prints `M22-026 TEXTURE BUDGET: PASS` and shows per-screen MiB for Home, Gameplay, Results, Shop/Collection each under its budget.
5. UI-ADR-008 in `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` has before/after MiB per folder and per screen, and lists untouched files and the 7 no-alpha PNGs.
6. These headless suites print PASS: `m42_home`, `m28_c002_c001_gameplay_v02`, `m43_c001a_results_foundation`, `m49_responsive_matrix`, `m50_color_symbols`, `m22_025_booster_texture_budget` (`-s res://tests/<name>.gd`).
7. `git diff --check` is clean.

## Out of scope
- Editing/regenerating/resizing any source PNG; lossy, VRAM (S3TC/ETC2/ASTC) or Basis compression; enabling mipmaps; atlasing; runtime texture streaming/unloading.
- Changing booster settings, UI layout, draw sizes or any gameplay/economy code.
- Reducing full-screen backgrounds, hero art, home poses or logos, or any file whose draw size cannot be determined.

## Assumptions
- Budgets are measured as resident RGBA8 (`w*h*4`), the same metric as 034, because Godot lossless import keeps uncompressed RGBA on the GPU.
- Per-screen path lists live as constants in the test (no new data file), to keep the job small.
- 4x draw side (2x hi-dpi plus 2x headroom for tablet) is a conservative cap; the 2x-hi-dpi threshold in the request is the minimum source/target ratio for eligibility.
- Where the 1080x2400 reference is the baseline, draw sizes are read as logical px of the 1080-wide layout; unknown means untouched.
