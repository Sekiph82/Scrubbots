# Collection card art memory (SB-M22-026 step 3)

> Feature: SB-M22-026 step 3 — collection card art memory. Cap all 135 collection card arts with a measured `process/size_limit`, stop the Collection screen keeping every viewed card texture forever, add a card-art budget assertion, update UI-ADR-008.

## Context
- 135 card arts: `assets/ui/final/collection/cards/set_NN/card_NN.png` (paths in `data/config/collection_card_catalog_v1.json`), all 1024x1536, no `size_limit`, so 6.00 MiB resident RGBA8 each (810 MiB for all 135).
- `scripts/ui/collection/collection_screen.gd` line 41-47: `static var _tex_cache` + `_tex(path)` never evicts. Used at line 169 (set thumbnail), 252 (`_tile`, 210x300 logical grid face). Card detail (`open_card`, line 323) uses plain `load()` into a `CardArt` rect with `custom_minimum_size` 380x540 (the largest card draw; the grid face is smaller).
- Step 2 (`coordination/sessions/FACTORY/038-m22-026-measured-caps/measure_merged.json`) already measured card views: all 13 owned/viewed cards report max side 540 px (phone and tablet). The layout is identical for every card (same rect), so 540 applies to all 135. Step 2 did not cap them because its rule `next_pow2(2x540)` = 2048 exceeds the 1536 source side.
- Fix: the cap need not be a power of two (Godot `size_limit` is any int). Use `2 x 540 = 1080` (ratio exactly 2.0, honours the 2x rule). A 1024x1536 source becomes 720x1080 = 2.97 MiB (-50%).
- `tests/m22_026_texture_budget.gd` holds per-screen lists/budgets and a `MEASURED` cap table (card art excluded today). UI-ADR-008 is in `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` (step 2 section ends "Still open: ... lazy card art loading").
- Existing helper: `tools/m22_026_apply_caps.py` (stdlib) writes the `.import` limit line; `tests/tools/m22_026_texture_measure.gd` measures.

## Requirements
1. Every one of the 135 card art `.import` files gets `process/size_limit=1080` (only that line changes; `compress/mode=0`, mipmaps off unchanged). Source PNGs untouched; no lossy or VRAM compression. Set with the apply tool if it can take a fixed limit for these paths, otherwise a one-off edit; do not add a permanent new tool unless needed.
2. Remove the unbounded `_tex_cache` from `collection_screen.gd`: `_tex` becomes a plain `load(path)` (Godot's ResourceLoader already shares a live texture between tiles and frees it when the last TextureRect drops it). Delete the stale `ponytail:` comment. No visual or gameplay change.
3. Re-run `tests/tools/m22_026_texture_measure.gd` (throw-away saves, never the real save) and confirm card art measured side is still 540 on both viewports and the loaded card MiB are lower; record the "all 135 cards viewed" number (see Acceptance 3).
4. `tests/m22_026_texture_budget.gd`: add a card-art check: for all 135 catalog arts, imported (post-limit) image max side <= 1080 and alpha kept, and the summed resident RGBA8 MiB <= 440 (computed 401.2, +~10%). Also assert `CollectionScreen` no longer has a `_tex_cache` member (script constant/static property list does not contain it).
5. Update UI-ADR-008 in `docs/07_UI_ASSET_PIPELINE_DECISIONS.md` with a "step 3" section: rule, why 1080 and not pow2, before/after MiB, the cache removal, and update the step 2 "Still open" line (lazy card art loading done). Update the TASKS.md SB-M22-026 evidence line (not closing the task; VRAM compression/atlasing remain open) and AGENTS.md only if it lists texture caps.

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m22_026_texture_budget.gd` prints its PASS line, including the new card-art cap + budget checks.
2. `grep -L "size_limit=1080" assets/ui/final/collection/cards/set_*/card_*.png.import` prints nothing; `grep -c "_tex_cache" scripts/ui/collection/collection_screen.gd` is 0.
3. ADR step 3 states before -> after resident MiB for all 135 cards viewed: 810.0 -> ~401 (cap) and for the measure tool's Collection scenario whole-tree MiB (was 166.87 with 13 cards at 6 MiB); the builder fills in the re-measured numbers. It also states MiB after closing the Collection popups no longer retains card textures (e.g. `ResourceLoader.has_cached` false for a viewed card after the album is freed, or equivalent check in the test).
4. These PASS: `tests/m43_master_c007_collection.gd`, `tests/m43_master_c007r_pity.gd`, `tests/m22_025_booster_texture_budget.gd`, `tests/m49_responsive_matrix.gd`, `tests/m50_color_symbols.gd`, plus any other `tests/*.gd` that greps `collection_screen` (find with grep) — each run via the headless command above.
5. `git diff --stat` shows no `.png` changes and no change under `user://`/saves; `git diff --check` clean.

## Out of scope
- Any PNG edit, VRAM/lossy compression, atlasing, resizing the card UI, changing layouts.
- An LRU or preload scheme; the cache is simply removed.
- Capping other art, touching economy/collection logic, the owner's real save.

## Assumptions
- 1080 (non power of two) chosen because next_pow2 gives 2048 (no effect) and 1024 would be 1.90x, below the 2x rule; Godot accepts any integer limit.
- Removing the cache is safe: tiles/detail hold their own texture references, and ResourceLoader dedups live loads; a reload cost for a 720x1080 PNG on screen open is acceptable (it is not per-frame).
- Orchestrator note: the 135 new/changed `.import` files may exist untracked in the main checkout; move aside on merge.
