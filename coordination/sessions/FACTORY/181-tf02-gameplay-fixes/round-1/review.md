VERDICT: PASS

## Checks
- git diff --check origin/main...HEAD: pass
- tests/sb_phone_2026_11_12_f_slot_pop_hold.gd: pass (100/100 cases, 0 fail)
- tests/sb_video_005_level_intro.gd: pass (9/9 cases, 0 fail)
- tests/m29_speed_authority_evidence.gd: pass

## Findings
None.

## Notes
- Slot hold: release is driven by the live pop (`is_slot_popping`), evaluated in `_refresh_slots` and again in `_commit_activation`. The `pop_duration()` countdown remains the upper bound. If the overlay is freed or a pop is dropped (POP_MAX `pop_front`), `is_slot_popping` is false and the hold is released. Reduced Effects creates no pop, so there is no hold. There is no deadlock path.
- Intro gate: `hold_input_for_intro` runs right after `add_child`. `_input` is created in the host's setup before `main` calls it. The release is on `tree_exited` (ONE_SHOT), which covers skip, fade-out free and host teardown. `activate_front`, `request_booster` and the speed press are all gated, and HitAreas stop picking. The `hold_input_for_intro` call was not re-run without the fix. The suite's `intro_blocks_selection` case covers it.
- Speed: the auto 3x state is separate (`FACTOR_AUTO_3X`) and wins over a paid 2x. `set_2x`, `toggle` and `reset` leave auto mode. Paid 2x stays 2.0. `_drop_expired_paid_2x` keeps its guard while auto is active. There is no change to TargetSelector, RoutingSystem or ordering; it is a temporal factor only.
- Booster icon band overhang: acceptable. The icon is 1.05x the button, so it extends about 2.5 ref px past the 98 px band, and the band's gap to the supply rows above and the AD region (y 1762, band ends 1738) below absorbs that. This is the only way to reach the >=1.35x floor in the current band, and SB-TF-04 relocates the band anyway. The art may overhang the circular plate edge, which is a visual judgement for the owner.
- Honest limit, already in build.md: the pop fix gains at most one frame. Any remaining "not pickable" feel from the faint stars tail is the preset C timing, which the spec puts out of scope.
