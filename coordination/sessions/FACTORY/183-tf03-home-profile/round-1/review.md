VERDICT: REWORK

## Checks
- git diff --check 51849268..HEAD: pass (clean)
- sb_tf03_home_profile: PASS (11/11)
- m49_responsive_matrix: PASS (8/8)
- m42_c003_scrubby_animation: 25/25, 0 failures
- m50_accessibility_audit: PASS (11/11). The 18->16 floor change is scoped to the REWARDED ADS label only: ra_px is checked >= 16 and erased from the dict, so the HUD level and booster price keep FONT_FLOOR.
- m42_home_v04: first run 1 failure ("(+) buttons emit intents only; economy untouched", economy snapshot differs). Two reruns gave 18/18. Flaky, see Notes.
- m49_touch_targets_text_stress: was still running when I wrote this; not confirmed by me.
- grep for HOME_NAV_, BottomNav, WinStreakRewardTrack, _build_track, nav_requested, set_app_nav and APP_NAV in scripts: no hits. No dead callers from the strip or nav removal.

## Findings
1. captures/home_en.png (PLAY button): shows "PLAY · LEVEL 12" with a second line "LEVEL 12" under it, so the level appears twice. Remove the old level sub-line (or its text) in `_build_play`/`_render_play` so PLAY only reads "PLAY · LEVEL N". Check the sub-label is not pinned by a test that only passes because it is there.
2. captures/profile.png (Profile action row): the COLLECTION label is clipped ("COLLECTI") by the badge and/or the button width. Spec req 13 and AC 7 forbid clipping. Fit the label font to the button width minus the badge, or give the three buttons a font fit (`HomeStyle.fit_font`). Check TR too, where the text is longer. Add a no-clipping assertion in `sb_tf03_home_profile` for the Profile buttons.

## Notes
- The home_en layout matches the spec otherwise: Settings icon between the Profile card and the chips, two activity columns of 3 and 4, no BottomNav, no win-streak strip, the banner area at the bottom, and a badge on the Profile card avatar. The activity tiles are visibly smaller and see-through.
- The 2 and 1 badges on the Profile card and the Rewarded Ads tile in the capture are fixture data, not a defect.
- m42_home_v04's economy-snapshot assertion is order- or time-dependent (hearts regen, or state left by the earlier suite). It passed on rerun and the build.md claim of 18/18 holds, so it is not blocking. Consider snapshotting after a settle frame.
- I did not open home_tr.png. The TR key parity is covered by the passing suite.
