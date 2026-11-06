# Review round 1 - 115-touch-targets-text-stress (single reviewer)

## Checks
- git diff --check origin/main...HEAD: pass (clean)
- tests/m51_localization_readiness.gd: PASS 4/4 (pseudo 0.40 does not break the m51 guards)
- tests/m49_responsive_matrix.gd: PASS 8/8
- tests/m43_master_c007_collection.gd: PASS 19/19 (OPEN PACKS 88 px change ok)
- tests/m49_touch_targets_text_stress.gd: not run, per instruction
- Worktree was dirtied by --import churn only (.import files); worktree is deleted at job end.

## Review
- Fixes are UI-only and small: OPEN PACKS now UiTokens.TOUCH_MIN; HomeStyle.fit_font used in 5 places; PSEUDO_EXPANSION 0.35 -> 0.40 plus comment/message text in m51.
- fit_font: loop only runs while the text is wider than the available width, so English sizes cannot change (the suite asserts 24/26/24). Empty text gives width 0 and keeps px; zero or negative width stops at the 60% floor, no infinite loop. It runs at layout, set_profile and _apply_booster_visual (text change), never per frame. One string-size measurement per font step, which is cheap.
- Removing the REWARDED_ADS add_theme_font_size_override in home_screen is fine, because fit_font sets the same size right after add_child.
- The English overhang allow-list is per size/parent/control, built from the t00 English baseline. Stress copy may not overhang further than English on any side. It is not a blanket exclusion.
- Hidden controls are skipped via is_visible_in_tree, and mouse_filter IGNORE controls are skipped. Both are correct for hit rects. Disabled buttons are still measured, which is the stricter choice. Locked booster plates are covered by the second walk on a non-unlock-all save.
- Saves are throw-away (user://m49_tt_*, boot_save_path_override).

## Findings
None.

## Notes
- The 60% floor is an owner visual call, as build.md says.
- The suite takes about 7 min and is not in CI, which is acceptable.

VERDICT: PASS
