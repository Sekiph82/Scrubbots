VERDICT: REWORK

## Suite results (re-run sequentially, foreground, in the worktree)
- sb_tf05_reward_reveal: PASS 15/15
- sb_phone_2026_11_12_e_win_home: PASS 10/10
- sb_tf03_home_profile: PASS 11/11
- sb_tf04_gameplay_layout: PASS 7/7
- m50_accessibility_audit: PASS 11/11
- ev02_events_v02: PASS 10/10
- m43_c005_c005_reward_reveal_sequencer: PASS 12/12
- m49_ad_store_return_layout: PASS 6/6
- m54_regression_pack_037_038: PASS 6/6 (prints 3x "SCRIPT ERROR: Nonexistent function 'explode' in base 'Nil'"; not in a touched file, not investigated, builder should confirm it is identical on main)
- m57_ads_cadence: PASS 6/6
- m57_native_providers: PASS 14/14
- git diff --check e141f988..HEAD: clean. No .import / .uid / project.godot in the committed diff (they are only untracked or modified in the worktree).
- Spark claim: scripts/economy/events_v02_service.gd has zero diff on this branch, so the m43_master_c005f_feel / m43_c005f_015_e2e_feel / m43_c005f_phase3 "Spark" failures cannot come from this branch's edits to that file. I did not re-run them on main. Not blocking.

## Review against the focus areas
(a) Economy safety: OK. The x2 grant goes Home -> `actions.start_win_double` (facade) -> `RewardedGrantService._request_grant` -> `resolve`. It commits only on `outcome == completed` and `verified is bool and verified`. The tx id is `win_double:<receipt key>`, checked with `already_applied` in `can_start_win_double` and again by `RewardGrantService.grant` (a duplicate returns false). The save callback persists the tx. The amount comes from the committed receipt (`_win_double_sb`, WON only). The pending and closed token sets stop a duplicate callback. `reward_reveal.gd` has no wallet / grant / save call; home_screen only reads `rewarded.result_for` and listens to `resolved`. Non-win sources use `reward.applied_rewards(tx)` or the facade result.
(b) Input lock: OK. The layer is bounded by `_end`, or by AD_TIMEOUT_S while an ad is pending, and the abandon path closes the token as a non-grant. `finish()` frees the lock. The layer lives under Home, so it dies with the scene. Back is gated by `is_reward_flight_running`. Queued reveals start after `_complete`.
(c) All 8 sources: win (`_start_win_rewards`), Tasks/Daily/Gift/Events/Rewarded daily/Shop heart+booster/achievement (`REVEAL_ACTIONS` + `_reveal_action`), Rewarded Heart/booster (`_reveal_rewarded`), SB packs (`_reveal_store`), collection set/master (`_reveal_collection`) all reach `request_reward_reveal`. Verified by reading, plus suite case 13.
(d) The 15 edited suites change only what the new behaviour needs (adding `_land()` / `finish()` before the checks, Reduced now holds, 3 rewards after SB-TF-03, the `has_meta("target")` guard for the dim). No assertion was removed or loosened beyond that. The Reduced case in sb_phone now asserts hold time (1.3 <= t < 3.0) plus zero copies.
(e) Docs amendment is honest (owner 2026-11-18 chat, line 441 of OWNER_ECONOMY_REWARDS_V01.md; the speed 2x is called unrelated). The "no rewarded 2x" header text is fixed.

## Findings
1. scripts/ui/home/home_screen.gd:1167-1180 (`_build_play`) and :1676-1682 (`_render_play`): the PLAY label touches the play triangle. Evidence: evidence/01_win_reveal_hold_x2_button.png shows "PLAY · LEVEL 2" with the "2" touching the arrow. Cause: the text is fitted to `PLAY_SIZE.x - stylebox min width` (`content_margin_left` 24 + `content_margin_right` 96 = 120), so the text can reach x = 374 from the left. The triangle starts at 470 - 104 = 366 (`offset_left = -104`), so the text and triangle overlap or touch by up to 8 px. The text is also centred in the content area and so sits flush against the arrow once it is fitted. Fix: reserve a gap, for example `content_margin_right` of at least 120 (triangle width 58 + offset 46 + gap about 16), or move the triangle further right, and keep the fit width in `_render_play` in sync. It must fit with a clear gap for 1 to 4 digit levels, in EN ("PLAY · LEVEL %d") and TR ("OYNA · LEVEL %d"). Add a suite assertion (for example in sb_tf03_home_profile or sb_tf04) that the fitted text's right edge is at least 8 px left of `PlayTriangle`'s left edge for levels 2, 99, 999, 9999 in both languages. Origin is SB-TF-03, but the orchestrator wants it fixed in this job.
2. scripts/economy/production_action_facade.gd (new `win_double_available`): there is a stray tab run inside the line (`... allowed("rewarded") 		and bool(...)`). It parses, but it is a whitespace oddity. Put it on one line or wrap it with `\`.
3. scripts/app/main.gd `_reveal_action`: for `buy_heart` it hard-codes `{"hearts": 1}` and for `buy_booster_charge` it hard-codes 1 charge, instead of reading the facade result. This is the only place the "committed result, not recomputed" rule is bent. Low risk now, but add `added` / `charges` from the service result as was already done for `refill_hearts`, or leave a comment. Not blocking on its own.

## Reveal readability (screenshots 01 to 04)
Readable. Icons are 132 px with a 56 px white outlined "+N" over a 0.45 dim, centred on Scrubby's head and chest. Each row is clearly legible and the three rows are distinguishable (SB, bolt, gift). They do cover Scrubby's face and upper body, which is acceptable for a 1.5 s hold. The green "WATCH AD · x2" button sits over Scrubby's belly and is clear. I found no readability finding, apart from the PLAY label (finding 1).

## Notes
- AD_TIMEOUT_S = 30 s: a long rewarded video plus end card may exceed 30 s, so a legitimately completed late view would be abandoned (no reward, flight starts). It is a safe fail-closed choice, but consider 45 to 60 s.
- Requests to `request_reward_reveal` outside the Home route return false and show nothing (documented "Home only"). Fine, since the popups open from Home.
