STATUS: READY

# Build: Collection card art memory (SB-M22-026 step 3)

## Summary
- **Card art cap:** all 135 collection card arts import with `process/size_limit=1080`. A 1024x1536 card becomes 720x1080, and its resident size drops from 6.00 to 2.97 MiB.
- **Texture cache:** the unbounded static `_tex_cache` in `CollectionScreen` is replaced by a per-visit cache.
  - The cache is a `Dictionary` stored in the album popup's `tex_cache` meta, so the modal stack frees it when the album closes.
  - `_tex(path, cache)` loads into that cache.
  - The album passes it to its thumbnails and to `open_set(..., cache)`. A standalone `open_set` call gets a throw-away `{}`.
  - Repeat set opens within one visit skip the decode, and nothing is kept between visits.
- **Budget test:** checks the card-art cap, alpha and the 440 MiB budget, that no static `_tex_cache` exists, and that a card is released once the visit cache is freed.
- **Docs:** UI-ADR-008 has a step 3 section.

Commits on `factory/040-m22-026-card-art`:
- `ee87dd65` M22-026 step 3: card art size_limit 1080, drop collection texture cache, card-art budget
- `fd8b8c96` tasks: SB-M22-026 step 3 evidence, queue row (factory 040)
- `4386d4ea` M22-026 step 3: per-visit album texture cache, restore 150 ms warm set-detail budget
- `b37605b1` tasks: SB-M22-026 step 3 per-visit cache evidence (factory 040)

Files changed:
- `assets/ui/final/collection/cards/set_*/card_*.png.import`: **135 new tracked `.import` files**.
  - They were untracked before. Glob: `assets/ui/final/collection/cards/set_*/card_*.png.import`.
  - The orchestrator should move the matching untracked copies in the main checkout aside before merging.
  - Compared with the Godot default, the only change is `process/size_limit=1080`. `compress/mode=0` and mipmaps off are kept, and no PNG was touched.
- `scripts/ui/collection/collection_screen.gd`: per-visit cache, as described in the Summary.
- `tests/m22_026_texture_budget.gd`: `_card_art()` check.
- `tests/m43_master_c007_collection.gd`: the only change against main is that `_k10` passes `album.get_meta("tex_cache")` to `open_set`. The 150 ms warm budget and its message are restored as they were.
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`: UI-ADR-008 step 3 section, and the step 2 "Still open" line updated.
- `TASKS.md`: SB-M22-026 queue row and step 3 evidence. The task is not closed. AGENTS.md is unchanged because it does not list texture caps.

## Acceptance criteria
1. [x] **Budget test PASS, including the card-art checks.** `$GODOT --headless --path . -s res://tests/m22_026_texture_budget.gd` exited 0 and printed `M22-026 TEXTURE BUDGET: PASS`. Card-art lines:
   - ok: 135 catalog card arts.
   - Resident RGBA8: 400.45 MiB against a 440 MiB budget.
   - ok: every card is at most 1080 px and keeps alpha.
   - ok: no `_tex_cache` member.
   - ok: card_01 is kept by the visit cache after its TextureRect is freed.
   - ok: card_01 is released once the visit cache is freed (`ResourceLoader.has_cached` false).

   In round 1, the static-member check and the release check both failed against the old static-cache file.
2. [x] **Grep checks.**
   - `grep -L "size_limit=1080" assets/ui/final/collection/cards/set_*/card_*.png.import` prints nothing.
   - `grep -c "_tex_cache" scripts/ui/collection/collection_screen.gd` prints 0. The cache is now held only in the album's `tex_cache` meta.
3. [x] **ADR step 3 numbers.**
   - All 135 cards viewed: 810.0 -> 400.45 MiB.
   - Measure tool, Collection scenario whole-tree: 166.87 -> 127.43 MiB at both 1080x2400 and 1536x2048. This was measured in round 1 with throw-away saves.
   - Card draw sides are unchanged: 540 px on the phone and 512 px on the tablet.
   - The ADR describes the per-visit cache: it is freed when the album closes, nothing is retained between visits, and at most 135 x 2.97 MiB can be held within one visit.
4. [x] **Suites, round 2.** Every suite exited 0 with no `SCRIPT ERROR` or `Parse Error`:
   - m22_026_texture_budget: PASS
   - m43_master_c007_collection, 3 runs: 13/13 each. Set-detail build was cold 311.6 / 222.7 / 285.8 ms and warm 79.3 / 79.6 / 76.6 ms. The warm pass is under the restored 150 ms budget.
   - m43_master_c007r_pity: 9/9
   - m47_touch_r01_mobile_ux: 14/14
   - m49_responsive_matrix: 8/8
   - m22_025_booster_texture_budget: PASS
   - m50_color_symbols: 10/10
5. [x] **Diff checks.** `git diff --name-only 21bc08df..HEAD` lists no `.png` or save paths, and `git diff --check 21bc08df..HEAD` is clean. No tracked file is left modified. Untracked Godot-generated `.uid` and `.import` files from the worktree import remain.

## Validation
LOCAL_PASS on Godot 4.7.2 headless for every suite listed in criterion 4, plus `git diff --check`. The measure tool was run in round 1 and printed DONE. The round 2 change does not affect the measured numbers: the measure tool calls `open_set` without the album cache, so it still loads from scratch each time.

## Log
### Round 1
- Set `process/size_limit=1080` on the 135 card `.import` files with a one-off `sed`, then re-imported.
- Removed `_tex_cache` and made `_tex` a plain `load`.
- Added the card-art check to the budget test.
- Re-measured, and updated the ADR and TASKS.md.
- Loosened the m43 set-detail budget from 150 ms to 500 ms, because without any cache every open decoded its 9 card arts (205-265 ms).

### Round 2
- **review-code.md finding 1 (CHANGES):** fixed. The static cache is replaced by a per-visit cache owned by the album popup, as the review suggested:
  - `open_album` sets `p.set_meta("tex_cache", {})`.
  - `_tex(path, cache)` loads into that cache.
  - `_refresh_album` thumbnails, `_on_album_action` -> `open_set(..., p.get_meta("tex_cache"))` and `_tile` all use it.
  - `open_set` has a new last parameter `cache: Dictionary = {}`.
- **m43 test:** restored the original warm-pass `< 150000` µs budget and its message. `_k10` now passes `album.get_meta("tex_cache")`. Warm is 77-80 ms over 3 runs.
- **Budget test:** the release check now frees the visit cache before asserting `has_cached` is false. It also asserts the card stays cached while the visit cache holds it. The no-static-member assertion is kept.
- **Docs:** the ADR step 3 and TASKS.md wording now describe the per-visit cache with no retention between visits. The 500 ms note is gone.
- **review-rules.md (PASS):** suggested a per-album cache as a follow-up. This round implements it, so no follow-up task is needed.
- **review-tests.md (PASS):** no findings. The 500 ms concern no longer applies.
- **Re-runs:** the five suites the coordinator listed, plus m22_025 and m50, all PASS.
