STATUS: READY

# Build: SB-POLISH-007 Achievements grant rewards, 8 -> 50 data-driven

## Acceptance criteria (written by the builder, no spec-writer)
1. Achievements live in one versioned data file with 40..50 entries (id, name, desc, metric, target, tier, icon, reward). The metrics are only ones the game already records. A new entry needs no code change.
2. Rewards use existing types only (SB, Bot Parts, Card Pack, Premium Pack, Booster of choice, Mystery Booster) and scale with the tier. Totals are sane and listed here.
3. A reward is granted exactly once, through RewardGrantService (idempotent and persisted), with a CLAIM button on the card (the Tasks / Events pattern). A second claim, an unreached claim and a relaunch never pay again.
4. Old saves: progress that already meets a target shows CLAIM on load. The 8 original ids are kept.
5. The Achievements screen scrolls the long list. Each card has a reward line and a CLAIM, COMPLETED or progress state. The summary reads "N / total completed" and the "They do not grant rewards" note is gone. Badges reuse existing art with tier colouring.
6. The Home profile card shows a claimable-achievement count through HomeBadges.
7. The directly affected suites pass locally. A permanent test covers the new behaviour.

## Summary
The 8 achievements in `achievements_v1.json` are replaced by 50 in `data/config/achievements_v2.json` (schema `scrubbots.achievements.v2`). The list keeps the 8 original ids, includes the 32 achievements the owner listed in `coordination/OWNER_META_PROGRESSION_DESIGN_V01.md`, and adds 18 more tiers. `Achievements` validates the file: an unknown metric, tier or reward type rejects the whole file.

Four new metrics are derived from data the game already persists:
- `gift_cycles` from GiftMeterService.cycles_completed.
- `gifts_claimed`, `daily_logins` and `tasks_claimed` from lifetime counts of applied reward-ledger tx ids with the prefixes `gift_ms:`, `daily_login:` and `daily_task:`.

How claiming works:
- The player taps CLAIM, which calls `ProductionActionFacade.claim_achievement(app, id)`. It is `_finish_durable`, the same as the Daily task claims (it saves, and rolls back if the save fails).
- That calls `Achievements.claim`, which grants through `RewardGrantService.grant("achievement:<id>", reward)`.
- "Claimed" is read back from the persisted ledger, so no new save section is needed. Old saves become claimable automatically, and nothing can pay twice.
- Earned packs go to the existing pending-pack queue and ceremony.
- The claim plays the "reward" sound and a SMALL burst on the card through MetaFeedback / MetaRewardFeel.

The Home badge: `HomeBadges.compute()` has a new `achievements` count. Home draws it as the nav tabs' red pill on the profile-card avatar. The pill builder was extracted to `_badge_label`, shared with the nav tabs.

The 2026-10-22 owner doc said achievements should give cosmetic rewards only. The newer owner instruction of 2026-10-31 overrides that, and a supersede note was added to that doc.

Files changed:
- data/config/achievements_v2.json (new); data/config/achievements_v1.json (deleted)
- scripts/progression/achievements.gd
- scripts/economy/production_action_facade.gd
- scripts/ui/profile/profile_screens.gd
- scripts/ui/home/home_badges.gd
- scripts/ui/home/home_screen.gd
- scripts/ui/feel/meta_feedback.gd
- scripts/ui/feel/meta_reward_feel.gd
- scripts/ui/ui_text.gd (ACH_REWARD added; ACH_NO_REWARD and the 16 per-id ACH_ keys removed, because names now come from the data)
- coordination/OWNER_META_PROGRESSION_DESIGN_V01.md (supersede note)
- tests/m43_master_c010_meta.gd
- tests/m47_touch_r01_mobile_ux.gd
- TASKS.md

Commits: f88c4576 (code + tests), 021b4ccb (TASKS.md).

### Achievement table (50; bronze 13, silver 12, gold 15, platinum 10)
| # | id | name | metric | target | tier | reward |
|---|---|---|---|---|---|---|
| 1 | clean_start | Clean Start | levels_completed | 1 | bronze | SB 100 |
| 2 | warming_up | Warming Up | levels_completed | 5 | bronze | SB 150, Mystery Booster 1 |
| 3 | tidy_ten | Tidy Ten | levels_completed | 10 | bronze | SB 250, Card Pack 1 |
| 4 | scrub_squad | Scrub Squad | levels_completed | 25 | silver | SB 400, BP 5 |
| 5 | spotless_fifty | Spotless Fifty | levels_completed | 50 | silver | SB 600, Card Pack 1, BP 10 |
| 6 | century_clean | Century Clean | levels_completed | 100 | gold | SB 1000, Premium Pack 1, BP 15 |
| 7 | park_protector | Park Protector | levels_completed | 150 | gold | SB 1200, Premium Pack 1, BP 15 |
| 8 | district_defender | District Defender | levels_completed | 300 | gold | SB 1500, Premium Pack 1, BP 25 |
| 9 | polish_pro | Polish Pro | levels_completed | 500 | platinum | SB 2000, Premium Pack 2, BP 25 |
| 10 | five_worlds_clean | Five Worlds Clean | levels_completed | 750 | platinum | SB 2500, Premium Pack 2, BP 50 |
| 11 | thousand_shine | Thousand Shine | levels_completed | 1000 | platinum | SB 3000, Premium Pack 2, BP 50 |
| 12 | halfway_hero | Halfway Hero | levels_completed | 1500 | platinum | SB 4000, Premium Pack 3, BP 75 |
| 13 | ultimate_scrubbot | Ultimate Scrubbot | levels_completed | 3000 | platinum | SB 6000, Premium Pack 5, BP 100 |
| 14 | first_discovery | First Discovery | cards_unique | 1 | bronze | SB 100 |
| 15 | card_collector | Card Collector | cards_unique | 9 | bronze | SB 250, Mystery Booster 1 |
| 16 | card_hunter | Card Hunter | cards_unique | 25 | silver | SB 500, Card Pack 1 |
| 17 | master_collector | Master Collector | cards_unique | 75 | gold | SB 1200, Premium Pack 1 |
| 18 | complete_collection | Complete Collection | cards_unique | 135 | platinum | SB 3000, Premium Pack 2, BP 50 |
| 19 | first_set | First Set | sets_completed | 1 | silver | SB 400, Card Pack 1 |
| 20 | triple_collector | Triple Collector | sets_completed | 3 | gold | SB 800, Premium Pack 1 |
| 21 | collection_champion | Collection Champion | sets_completed | 8 | gold | SB 1500, Premium Pack 1, BP 25 |
| 22 | collection_legend | Collection Legend | sets_completed | 15 | platinum | SB 3000, Premium Pack 2, BP 50 |
| 23 | new_recruit | New Recruit | robots_unlocked | 2 | bronze | SB 300, Booster of choice 1 |
| 24 | robot_crew | Robot Crew | robots_unlocked | 3 | silver | SB 500, Card Pack 1 |
| 25 | half_the_crew | Half the Crew | robots_unlocked | 5 | gold | SB 1000, Premium Pack 1 |
| 26 | robot_squad | Robot Squad | robots_unlocked | 7 | gold | SB 1500, Premium Pack 1 |
| 27 | full_scrubbot_team | Full Scrubbot Team | robots_unlocked | 10 | platinum | SB 3000, Premium Pack 2 |
| 28 | on_a_roll | On a Roll | best_win_streak | 3 | bronze | SB 100 |
| 29 | hot_streak | Hot Streak | best_win_streak | 5 | bronze | SB 200, Mystery Booster 1 |
| 30 | blazing | Blazing | best_win_streak | 10 | silver | SB 400, Booster of choice 1 |
| 31 | unstoppable | Unstoppable | best_win_streak | 15 | silver | SB 600, Card Pack 1 |
| 32 | perfect_rhythm | Perfect Rhythm | best_win_streak | 30 | gold | SB 1200, Premium Pack 1, Booster of choice 2 |
| 33 | streak_master | Streak Master | best_win_streak | 50 | platinum | SB 2500, Premium Pack 2, Booster of choice 3 |
| 34 | no_help_needed | No Help Needed | boosterless_wins | 1 | bronze | SB 100 |
| 35 | bare_hands | Bare Hands | boosterless_wins | 10 | bronze | SB 250, Mystery Booster 1 |
| 36 | hands_on | Hands-On | boosterless_wins | 25 | silver | SB 400, Booster of choice 1 |
| 37 | pure_skill | Pure Skill | boosterless_wins | 50 | silver | SB 600, Card Pack 1 |
| 38 | bare_handed_pro | Bare-Handed Pro | boosterless_wins | 100 | gold | SB 1200, Premium Pack 1 |
| 39 | iron_focus | Iron Focus | best_boosterless_run | 10 | gold | SB 800, Booster of choice 2 |
| 40 | first_try_five | First-Try Five | best_first_try_run | 5 | silver | SB 300, Mystery Booster 1 |
| 41 | flawless_cleaner | Flawless Cleaner | best_first_try_run | 10 | gold | SB 700, Card Pack 1, Booster of choice 1 |
| 42 | perfectionist | Perfectionist | best_first_try_run | 20 | platinum | SB 1500, Premium Pack 1, Booster of choice 2 |
| 43 | gift_hunter | Gift Hunter | gifts_claimed | 1 | bronze | SB 100 |
| 44 | gift_master | Gift Master | gift_cycles | 1 | gold | SB 800, Premium Pack 1 |
| 45 | weekly_visitor | Weekly Visitor | daily_logins | 7 | bronze | SB 200, Mystery Booster 1 |
| 46 | regular | Regular | daily_logins | 30 | silver | SB 500, Card Pack 1 |
| 47 | devoted | Devoted | daily_logins | 100 | gold | SB 1200, Premium Pack 1 |
| 48 | first_order | First Order | tasks_claimed | 1 | bronze | SB 50 |
| 49 | order_runner | Order Runner | tasks_claimed | 25 | silver | SB 300, Mystery Booster 1 |
| 50 | task_master | Task Master | tasks_claimed | 100 | gold | SB 800, Card Pack 1 |

**Lifetime totals, all 50:** 54,550 SB; 495 Bot Parts (about 2 robots at 250 each); 10 Card Packs; 35 Premium Packs; 13 Booster of choice; 7 Mystery Boosters.

The totals are spread over a 3,000-level campaign. Over that campaign, first clears alone pay 50 to 150 SB plus 1 Bot Part per level. The early bronze tier (L1/5/10, first card, streak 3/5, and so on) pays about 2,000 SB in total, a little at a time.

Not used:
- Pixels cleared and boosters used. No lifetime counter for either is recorded today, so no achievement tracks them.
- The login streak. It can reset, so `daily_logins` uses the lifetime count of Daily claims instead.

## Acceptance criteria
1. [x] Data file: m04 "50 definitions (40..50), known metrics", "the 8 original ids are kept". m04 "unknown metric rejects the file" and "a reward type outside the economy lock rejects the file" show validation is fail-closed. The loader takes any number of valid entries.
2. [x] Reward types and totals: m04 "every badge icon is existing final art; every reward is an existing type". The table and totals are above.
3. [x] Exactly once:
   - m04 "CLAIM Tidy Ten: +250 SB and 1 Card Pack through tx achievement:tidy_ten".
   - m04 "second claim / unreached claim refused, nothing paid".
   - m04 "after relaunch: tidy_ten stays claimed, re-claim refused; still claimable [clean_start, warming_up, first_discovery]". This was a real app-root relaunch on the same save.
4. [x] Old save: 10 wins were recorded and saved, then the app root was relaunched. m04 "relaunched save with 10 clears: 1 / 5 / 10 claimable, 50 at 10/50".
5. [x] Screen:
   - m04 "summary banner: 3 / 50 completed text + bar" and "every card: tier badge, distinct Title, Desc and its reward line".
   - m04 "no 'They do not grant rewards' note", "completed unclaimed card: CLAIM, no bar", "claimed card: COMPLETED pill, CLAIM gone", "not-done card: Progress 10/50 + n/m text, no CLAIM".
   - m04 "every card label fits and the popup fits the 1080x2160 viewport".
   - m47 c05 "AchievementList: STOP controls 0, scroll room 6084 px, swipe moved 353 px".
   - Rendered capture: `tests/tools/meta_snapshot.gd` gave META_EVIDENCE CLEAN at 5 sizes. `C:\Users\sekip\AppData\Local\Temp\claude\C--Users-sekip-Desktop-ScrubBots\51e2db58-2f8f-47a6-9600-5f09840e2925\scratchpad\shots\2_achievements_1080x2160.png` shows the green CLAIM on Clean Start, bronze/gold tier rings, numbered rank badges, reward lines and "1 / 50 completed".
6. [x] Home badge:
   - m04 "HomeBadges achievements = 3 claimable" and "Home profile card shows the claimable badge '3'".
   - m10 "achievement badge on the profile card (4)", then "all handled -> no badge" once they are claimed.
   - m10 also checks the fresh-profile badge dict, now including `achievements: 0`.
7. [x] Tests: see Validation.

## Validation
Godot 4.7.2 console, headless, in the job worktree:
- `tests/m43_master_c010_meta.gd`: exit 0, no SCRIPT ERROR, "M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)". LOCAL_PASS.
- `tests/m47_touch_r01_mobile_ux.gd`: exit 0, "M47-FAMILY-APK-TOUCH-R01 mobile UX: PASS (14/14 cases, 0 fail)". LOCAL_PASS.
  - The first run failed c05 because the swipe started on `btn[0]`, which is now a CLAIM button far down the list and outside the viewport.
  - The test now starts the swipe on a button inside the visible scroll rect. Scrolling itself was unchanged and works: it moved 353 px.
- `tests/m44_new_badge.gd`: exit 0, "M44 new badge evidence: PASS (6/6 cases, 0 fail)". LOCAL_PASS. It covers the nav badge refactor.
- `tests/m43_c005f_phase3_meta_rewards_acquisition.gd`: exit 0, "PASS (15/15 cases, 0 fail)". LOCAL_PASS. Its one SCRIPT ERROR is the suite's own labelled EXPECTED_FAULT_INJECTION.
- `tests/tools/meta_snapshot.gd` (rendered): exit 0, "META_EVIDENCE CLEAN (0 rejected)".
- `git diff --cached --check`: clean.

Not done, per the owner's usage rule: no full CI list, no CI run, no phone build.

Notes:
- The engine prints "ObjectDB instances leaked / resources still in use at exit" when m43_master_c010_meta quits. This is not a SCRIPT ERROR, and I did not compare it against a baseline run.
- Godot rewrote project.godot and the asset `.import` line endings in the worktree. Both were restored with `git checkout` and are not committed.
- Untracked Godot `.uid` / `.import` artefacts under addons/ were already in this worktree. I did not stage them.

## Log
### Round 1
- Wrote the acceptance criteria myself (no spec-writer). Built the list from the owner's 32 (OWNER_META_PROGRESSION_DESIGN_V01) plus 18 tiers, for 50 entries.
- Reused existing pieces:
  - RewardGrantService ledger tx ids (the Events / rewarded_daily pattern), so no new save section.
  - The facade `_finish_durable` (the Daily task claim pattern).
  - The popup action buttons as CLAIM (the Events screen pattern).
  - The HomeBadges authority.
- The Profile card had no badge before. The nav-tab pill was extracted into `_badge_label` and placed on the avatar, which is a plain Control, so its anchors work inside the PanelContainer card.
- Achievements stay ungated for claiming, the same as the existing Profile -> ACHIEVEMENTS button. The L35 `achievements` unlock in feature_unlocks_v1.json is not enforced by any screen today. The Home profile-card badge is not gated by it either.
