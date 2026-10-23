STATUS: READY

# Build: SB-M22-026 step 2: runtime-measured size_limit caps

## Summary
Branch `factory/038-m22-026-measured-caps`, commits `0c2e1be2` (tool, caps, test, ADR) and `5067aec1` (TASKS.md).
- `tests/tools/m22_026_texture_measure.gd` (new) boots the real `main.tscn` in a SubViewport at the m49 logical size, using throw-away `user://m22_026_measure_*.save` files. It walks the whole SubViewport subtree (TextureRect, NinePatchRect, TextureButton normal/pressed/hover/disabled/focused, Sprite2D; an AtlasTexture counts as its atlas). For each texture in each scenario it records the max on-screen side in physical px, plus a `visible` flag and the whole-tree loaded MiB. It runs 9 scenarios x 2 viewports (1080x2400, 1536x2048):
  - home: all 4 gestures stepped frame by frame
  - gameplay_5slot
  - gameplay_6slot: through `activate_plus_one_slot`
  - results_won
  - results_failed
  - shop
  - collection: album, sets 1-3, card detail of every owned card plus one not found, Cards Exchange
  - robots and life (Heart popup): extras, because they draw robot portraits and heart art that also appear elsewhere
- `tools/m22_026_apply_caps.py` (new, stdlib). A dry run prints every observed texture with its side, source size, current limit, computed limit and decision. `--write` edits only the `process/size_limit` line. Rule: `next_pow2(max(2*side, 512))`, written only when it is below the source max side and the .import has no limit yet. The boosters (512) and the step-1 icons keep their value.
- 45 new tracked `.import` files (37 at 512, 8 at 1024), listed below.
- `tests/m22_026_texture_budget.gd`:
  - Budgets are Home 117, Gameplay 69, Results 32, Shop/Collection 41 MiB (measured after + ~10%).
  - New `MEASURED` cap check: for the 45 files, imported size <= limit and alpha kept.
  - The step-1 checks are kept.
  - Lists extended where the measurement showed on-screen textures missing from them:
    - GAMEPLAY: `gameplay_v02_shell_5slot_3col.png` and `gameplay_v02_shell_6slot_3col.png`, the shells drawn at runtime.
    - SHOP_COLLECTION: `common/frames/popup_large_frame.png`, `common/frames/popup_reward_frame.png`, `popups/victory/reward_glow.png`, `robots/bot_parts_icon.png`.
  - Collection card art stays out of the lists because the count depends on owned cards (lazy card-art follow-up). The ADR reports it separately.
- `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`: UI-ADR-008 step 2 section (rule, 45 capped, before/after per screen, budgets, what stayed untouched and why, known limit).
- `coordination/sessions/FACTORY/038-m22-026-measured-caps/measure_merged.json` (7.7 KB): the merged `{path: max_side_px}` map the caps came from. `apply_caps.py` accepts it.
- `TASKS.md`: SB-M22-026 step 2 evidence and queue row. The task stays READY/open.

New tracked `.import` paths. The orchestrator must move the matching untracked copies in the main checkout aside before syncing:
- `assets/ui/final/cards_exchange/cards_exchange_header_emblem.png.import`
- `assets/ui/final/characters/robots/atlas/atlas_portrait.png.import`
- `assets/ui/final/characters/robots/bubbles/bubbles_portrait.png.import`
- `assets/ui/final/characters/robots/clippy/clippy_portrait.png.import`
- `assets/ui/final/characters/robots/dusty/dusty_portrait.png.import`
- `assets/ui/final/characters/robots/moppy/moppy_portrait.png.import`
- `assets/ui/final/characters/robots/polly/polly_portrait.png.import`
- `assets/ui/final/characters/robots/rinse/rinse_portrait.png.import`
- `assets/ui/final/characters/robots/spark/spark_portrait.png.import`
- `assets/ui/final/characters/robots/squeegee/squeegee_portrait.png.import`
- `assets/ui/final/characters/scrubby/scrubby_portrait.png.import`
- `assets/ui/final/collection/collection_complete_emblem.png.import`
- `assets/ui/final/collection/master_collection_emblem.png.import`
- `assets/ui/final/collection/states/card_unknown_silhouette.png.import`
- `assets/ui/final/common/currencies/icon_currency_heart.png.import`
- `assets/ui/final/common/currencies/icon_currency_scrub_bucks.png.import`
- `assets/ui/final/common/navigation/icon_nav_events.png.import`
- `assets/ui/final/common/navigation/icon_nav_home.png.import`
- `assets/ui/final/common/navigation/icon_nav_leaderboard.png.import`
- `assets/ui/final/common/navigation/icon_nav_robots.png.import`
- `assets/ui/final/common/navigation/icon_nav_settings.png.import`
- `assets/ui/final/home/gift_meter/gift_meter_emblem.png.import`
- `assets/ui/final/home/gift_meter/gift_meter_reward_crate.png.import`
- `assets/ui/final/home/reward_track/reward_gift_1.png.import`
- `assets/ui/final/home/reward_track/reward_gift_10.png.import`
- `assets/ui/final/home/reward_track/reward_gift_100.png.import`
- `assets/ui/final/home/reward_track/reward_gift_25.png.import`
- `assets/ui/final/home/reward_track/reward_gift_5.png.import`
- `assets/ui/final/home/reward_track/win_streak_reward_badge.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_collection.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_daily.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_no_ads.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_rewarded_ads.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_shop.png.import`
- `assets/ui/final/home/shortcuts/icon_shortcut_tasks.png.import`
- `assets/ui/final/home/top_hud/profile_avatar_frame.png.import`
- `assets/ui/final/home/top_hud/profile_rank_badge.png.import`
- `assets/ui/final/popups/failure/fail_header_emblem.png.import`
- `assets/ui/final/popups/victory/reward_glow.png.import`
- `assets/ui/final/popups/victory/victory_emblem.png.import`
- `assets/ui/final/popups/victory/victory_scrubby_pose.png.import`
- `assets/ui/final/robots/bot_parts_icon.png.import`
- `assets/ui/final/shop/shop_heart_bundle.png.import`
- `assets/ui/final/shop/shop_scrub_bucks_bundle.png.import`
- `assets/ui/final/shop/shop_speed_2x_icon.png.import`

## Acceptance criteria
1. [x] Diff scope:
   - `git diff --name-only main | grep '\.png$'` prints nothing.
   - The rest of `git diff --name-only main` is the 45 `assets/ui/final/**.import` files, `TASKS.md`, `coordination/sessions/FACTORY/038-m22-026-measured-caps/measure_merged.json`, `docs/07_UI_ASSET_PIPELINE_DECISIONS.md`, `tests/m22_026_texture_budget.gd`, `tests/tools/m22_026_texture_measure.gd` and `tools/m22_026_apply_caps.py`.
   - The MD5 over all 560 PNGs under `assets/ui/final` is the same before and after `--write` + `--import` (`83e5743d...`).
2. [x] `$GODOT --headless --path <wt> -s res://tests/tools/m22_026_texture_measure.gd -- --out=<job>/measure.json`:
   - Exit 0, 0 SCRIPT ERROR/Parse Error, a per-scenario summary, and last line `M22-026 MEASURE: DONE (18 scenarios, 144 textures)`.
   - The JSON has all 9 scenarios at both viewports. Every entry has `max_side_px`; the 3 tutorial textures are listed with 0 (loaded, size 0).
   - `skipped` is `{}`: no scenario was skipped, so the 6-slot scenario was reached.
   - The real save `scrubbots_save.dat` (sha256 `f4fe9493...9851c70`, mtime 2026-10-22 11:55:46.7492828) is unchanged after all runs (4 measure runs and the suites).
   - An `ls` of the user dir is the same before and after (170 entries). No `m22_026*` or other temp save is left.
3. [x] Dry run on the pre-cap report:
   - It prints every observed texture: 45 CAP, 85 keep (source <= limit), 11 keep (existing limit), 3 skip (size 0).
   - Script check over every written limit: it equals `cap_for(merged side)`, is >= 512 and is < the source max side (0 bad).
   - `git diff main -- '*.import' | grep '^[-+]process/size_limit'` gives 37 x `+...=512` and 8 x `+...=1024`, with no `-` lines. No existing .import changed: all 45 are new tracked files that had no limit, and the 416 unobserved PNGs are untouched.
   - All 45 keep `compress/mode=0` and `mipmaps/generate=false`.
4. [x] `$GODOT --headless --path <wt> --import`: exit 0. The only warning/error line is the known `Detected another project.godot at res://level_factory` WARNING. The import rewrote `project.godot`; I restored it before the commit.
5. [x] `m22_026_texture_budget`:
   - Prints Home 106.02/117, Gameplay 62.72/69, Results 28.41/32, Shop/Collection 36.98/41 MiB, then `M22-026 TEXTURE BUDGET: PASS`, exit 0.
   - On the step-1 lists: Home 207.07 -> 106.02, Gameplay 50.72 -> 50.72 (equal, because nothing in that list could be capped), Results 65.99 -> 28.41, Shop/Collection 69.99 -> 20.70.
   - Revert check: setting `shop/shop_speed_2x_icon.png.import` size_limit to 0 and re-importing prints `FAIL: Shop/Collection total 44055412 <= 42991616`, `FAIL: shop/shop_speed_2x_icon.png 1278x1230 <= 512` and `M22-026 TEXTURE BUDGET: FAIL (2)`, exit 1. Restored and re-imported: PASS.
   - Reverting all 45 caps gave the "before" figures for the step-2 lists: Home 207.07, Gameplay 62.72, Results 65.99, Shop/Collection 94.00.
6. [x] LOCAL_PASS.
   - `python tools/run_suites.py --path <wt> m42_home m28_c002_c001_gameplay_v02 m43_c001a_results_foundation m49_responsive_matrix m50_color_symbols m43_c005f_phase4_terminal_home_micro`: aggregate=PASS (6/6). Results: `M42 home evidence: PASS`, 14/14, 11/11, `M49 responsive matrix evidence: PASS (8/8 cases, 0 fail)`, 10/10, 19/19.
   - Run directly because they are not in the workflow list; each exited 0 with 0 SCRIPT ERROR/Parse Error:
     - m22_025_booster_texture_budget: PASS
     - m22_026_texture_budget: PASS
     - m28_c002_c002_r01_visual: 10/10 PASS
     - m42_home_v07_safe_area: 9/9, 0 failures
     - m42_home_composition: 9/9, 0 failures
     - m43_master_c006_shop: 11/11
     - m43_master_c007_collection: 13/13
     - m43_master_c008_robots: 10/10
   - No pre-existing failures.
7. [x] The smallest limit / measured side among the capped textures is 2.065 (`home/shortcuts/icon_shortcut_collection.png`, 248 px -> 512), which is >= 2.0. Re-measuring after the caps gives the same rects (only `collection_complete_emblem` is 1 px smaller, from rounding), so no layout depends on texture size.
8. [x] The UI-ADR-008 step 2 table uses the same figures as the test output above, and the TASKS.md step 2 entry cites the same numbers.
9. [x] `git diff --check main`: clean (exit 0).

## Validation
- Measure tool: PASS (exit 0, DONE line, 0 script errors). 4 runs: pre-cap twice (before and after adding the `visible` flag), then once post-cap. The 4th run is the final `measure.json` in the job folder; the pre-cap report produced `measure_merged.json`.
- `tools/m22_026_apply_caps.py`: dry run, then `--write` (45 capped). Run again on the committed merged map it prints `would cap 0`, so it is idempotent.
- `--import`: exit 0.
- `m22_026_texture_budget`: PASS. The revert check gives FAIL/exit 1 as required.
- All suites in criterion 6: PASS (LOCAL_PASS).
- `git diff --check main`: clean. `git status --porcelain` shows no tracked changes. The only untracked files are Godot output (`.uid` and other `.import` files) that were there before the build.

## Notes for review
- Known limit (also in the ADR): the caps cover the sizes the scenarios show. Art drawn larger on a screen the tool does not visit (for example a robot portrait in an unlock ceremony, or the need-a-hand popup) would show at less than 2x there.
- `popups/failure/heart_large.png` keeps its step-1 limit of 1024, although the 2x rule would give 512 (spec: step-1 icons keep their value).
- The measure report's whole-tree "loaded MiB" includes the Home screen, which stays resident behind other screens. The per-screen budget lists are what the budgets are checked against.
- I did not add a `.uid` for the new tool: the repo does not track `tests/tools/*.gd.uid`.

## Log
### Round 1
I built the measure tool and the apply script, applied 45 caps, re-imported, extended and tightened the budget test, and wrote the UI-ADR-008 step 2 section and the TASKS.md evidence. I added Robots and Heart-popup scenarios, and opened the card detail for every owned card, so a texture seen small in one view is also measured at its largest known use. I added a `visible` flag to decide which measured textures belong in a screen's list; without it, overlays on Home or Gameplay would also pull in the textures of the screen underneath.
