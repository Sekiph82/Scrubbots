# 159-gameplay-shell-plaza (SB-GAMEPLAY-BG-2026-11-16)

Owner 2026-11-16 (chat): the gameplay backgrounds distract. Use the owner's new calm plaza gameplay
master (blue sky, trees, pink tile floor; same metal/blue frame, slot row, supply panel, Scrubby,
speech bubble, caution sign) and "produce from this image the 6 versions at the correct measurements".

Owner image: factory/jobs/159-gameplay-shell-plaza/owner_gameplay_shell_plaza_5slot_4col.png
(852x1846, 5 execution slots, 4 supply columns x 3 rows).

## Acceptance
1. Six masters, all derived from THIS image only (no new AI generation): 5slot_3col, 5slot_4col,
   5slot_5col, 6slot_3col, 6slot_4col, 6slot_5col. Same canvas for all six. 5slot_4col = the owner image
   unchanged (or only the minimum fix needed). Others built by slicing/re-laying the image's own parts:
   supply panel (9-slice the panel, repeat the real cell tiles incl. their top clips) for 3/5 columns,
   slot strip widened with a 6th real slot frame + 6th real connector pipe for 6 slots; panels centred,
   symmetric, clean seams, background (floor/sky) restored behind changed areas from the image itself.
   No visible seams/duplicated-shadow artefacts at 100% zoom.
2. Files: assets/ui/final/gameplay/master/gameplay_v03_plaza_shell_<id>.png (+ .import). The old v02
   masters stay byte-identical in the repo, no longer loaded.
3. scripts/ui/gameplay_shell_geometry.gd: SIZE, DIR/filename, SHA256 and every SHELLS rect (rail
   centrelines, slots, connector_x, cols, rows), PROFILE/PAUSE/SPEED, BUBBLE_TEXT/BUBBLE_FILL,
   BOOSTERS/AD bands re-measured from the new masters by pixel analysis (document the method).
   The baked bubble instruction text stays masked. Boosters/ad bands must sit on the empty floor
   below the supply panel and not cover Scrubby/sign more than today.
4. If canvas aspect changes, the gameplay layout must still fit the required viewport matrix
   (tests/m49_responsive_matrix.gd); board stays the dominant region; BoardRenderer, rails, slots,
   supply cells and HUD land exactly on the new baked frames.
5. Update the owner-lock doc coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md with an
   owner 2026-11-16 amendment (new files + SHAs), and the asset manifest entry if one exists.
6. Tests: m28_c002_c002_static_shell, m28_c002_c002_r01_visual, m49_responsive_matrix, board_bg01_backdrop
   and any other suite pinning the v02 shells: updated to the new truth, exact PASS lines.
7. Owner review captures: GPU captures of a real level in all 6 shell variants (any levels/booster state
   that produce them) at a phone viewport, saved in the job folder, plus a contact sheet of the 6 raw masters.
   Never boot main.tscn without a save override.

## Must not change
Gameplay rules/logic, slot/supply behaviour, BoardRenderer, Home (job 158 owns Home files:
home_screen.gd, HOME_ASSET_MANIFEST.json, home_worlds_v1.json, standard_pack_ceremony.gd - do not touch them).
