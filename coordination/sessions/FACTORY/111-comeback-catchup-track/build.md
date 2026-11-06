STATUS: READY

# Build: SB-M43-R12-001 Comeback Catch-Up Track

## Summary
The Catch-Up track now ships with reward values and grants them. After a genuine absence of at least 48 h, the 1st, 2nd and 3rd first-clear progression wins each grant one step, once, through RewardGrantService (tx `catchup:<track window>:<step>`). The values are in `data/config/comeback_v1.json` version 2:

| Step | Win | Reward |
|---|---|---|
| 1 | 1st first clear | 50 SB |
| 2 | 2nd first clear | 75 SB |
| 3 | 3rd first clear | 100 SB + 1 Bot Part |

That is 225 SB + 1 Bot Part per genuine absence. The track expires 7 days after it opens. A second absence while a track is still running keeps the same track, so there is no stacking and no new tx ids. Replays, losses and clock rollback never advance it.

These values are a Claude proposal under the owner pre-approved rule. The rationale is in `coordination/OWNER_ECONOMY_REWARDS_V01.md` §9.3. In short, the whole track is about a third of one 5-day Daily login cycle (650 SB plus packs and boosters). Gamed perfectly, it gives at most about 112 SB per day. It contains no booster charge, because random-any can roll a booster the player has not unlocked yet.

The UI uses native Controls only:
- The Welcome Back summary gets a `CatchUp` row: "Comeback bonus n/3", three static pips (gold when granted) and a "Next new level win: SB x50" line.
- Results gets a "Comeback bonus n/3 · <reward>" row. It comes from the receipt's reveal_queue, which now holds `catchup_sb`/`catchup_bot_parts`, and the receipt stays reconciled.
- The existing reveal handles Reduced Effects, and the pips are static.
- No UI grants anything. The grant happens in the gameplay host's committed WON terminal, next to orders and events, and only when FirstClearTransaction succeeds.

Files changed:
- data/config/comeback_v1.json
- scripts/economy/return_service.gd: the track has its own window/start; no stacking; auto-grant in `on_first_clear_win(reward_service)`
- scripts/economy/terminal_reward_receipt.gd
- scripts/gameplay/runtime/production_gameplay_host.gd
- scripts/ui/profile/profile_screens.gd
- scripts/ui/results_screen.gd
- scripts/ui/ui_text.gd
- tests/m43_master_c011_c014.gd
- tests/m43_c001a_results_foundation.gd: the exact rewards dict now includes the two catchup keys
- coordination/OWNER_ECONOMY_REWARDS_V01.md
- TASKS.md

## Acceptance criteria
1. [x] Absence < 48 h, no track: c05 "47 h away: no track, no summary"; c01 "47 h: no window".
2. [x] Absence >= 48 h starts the track: c05 "49 h away: Welcome Back shows the Catch-Up row", "3 empty pips", "0/3 + next reward SB x50".
3. [x] 3 first-clear wins grant the steps once each: c05 wins 1/2/3 in the real app, each with its Results row ('Comeback bonus 1/3 · SB x50', '2/3 · SB x75', '3/3 · Bot Parts x1, SB x100'), the receipt reconciled and the step's tx applied; then "3 first clears: track complete" and "4th first clear: track capped, no Catch-Up grant".
4. [x] Replaying a cleared level does not count: c05 "replaying cleared level 1: no win counted, nothing granted, no row".
5. [x] Relaunch/import is idempotent: c05 "relaunch: same wallet / tx / track (import idempotent)" and "facade claims after relaunch re-grant nothing"; c04 restored-copy cases.
6. [x] Expiry: c04 "exactly at expiry: expired, wins frozen, summary gone, claims refused, identical after relaunch".
7. [x] No stacking on a second absence while active: c04 "second absence while active: same track, wins kept (no stacking)", "the running track completes once", "after completion the next genuine absence starts a fresh track".
8. [x] Values are in data/config (versioned) and documented: c03 "config version 2" and "shipped steps: 50 SB / 75 SB / 100 SB + 1 Bot Part"; §9.3 in OWNER_ECONOMY_REWARDS_V01.
9. [x] Existing reward types only, no Daily/event/multiplier coupling: the loader validates approved_reward_types; c04 "never touches Daily / level economy"; the Gift Meter is untouched (it counts Win Streak SB only).

## Validation
Godot 4.7.2 console, headless. Ran `--import` once; project.godot and the .import/.uid/.translation churn were restored or removed afterwards.

All runs below are LOCAL_PASS:
- tests/m43_master_c011_c014.gd: PASS (29/29 cases, 0 fail), exit 0, 0 SCRIPT ERROR
- tests/m43_c001a_results_foundation.gd: PASS (11/11). It failed before the contract update (exact rewards dict), then passed after it.
- tests/m43_c001b_won_results_visual.gd: PASS (11/11)
- tests/m43_c005f_phase2_results_pack_feel.gd: PASS (22/22). Its 7 SCRIPT ERRORs are the suite's own labelled EXPECTED_FAULT_INJECTION.
- tests/m43_master_c010_meta.gd: PASS (12/12)
- tests/sb_video_007_008_set_complete_welcome_video.gd: PASS (8/8)
- tests/m44_ftue.gd: PASS (23/23)
- tests/m43_master_c005r_gift_micro_progress.gd: PASS (8/8)
- tests/m51_localization_readiness.gd: PASS (4/4)
- tests/m39_v02_integration.gd, m39_v02_atomicity.gd, m39_v03_full_surface.gd: PASS
- `git diff --cached --check` was clean for both commits.

Not run: no CI and no phone build (per the brief), and no rendered screenshot of the popup or Results row.

Note: `git status` in the worktree still lists 10 `assets/ui/final/{robots,shop}/*.png.import` files as modified. They are byte-identical to HEAD (`cmp` with `git show HEAD:`), and `git add` stages nothing. This is a line-ending stat artifact, not a content change.

## Log
### Round 1
- Read return_service.gd. The track logic already existed (claim-based) but had no steps, so it was never offered.
- Added the values and switched to granting on the win. The track now owns its window/start, so a second absence while it runs keeps it (no stacking).
- Wired the grant into the host's committed WON terminal and into the Results receipt (reveal row and reconciliation).
- Added the pips and next-reward line to the comeback summary.
- Tests: c03 rewritten for the shipped values, c04 extended with the no-stacking cases, and a new real-app case c05.
- Commits: c00788c4 (config, code, tests) and 71b95b94 (docs/tasks).
- The process was interrupted after the suites ran. On resume I reran c001a and c011, cleaned up the import churn and committed.
