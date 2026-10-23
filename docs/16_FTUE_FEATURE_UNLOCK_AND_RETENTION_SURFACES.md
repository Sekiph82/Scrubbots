# 16 - FTUE, Feature Unlock and Retention Surfaces

Status: M44 OWNER-REVISED 2026-10-12 / IMPLEMENTATION PENDING
Date: 2026-09-26

## 1. First-session design [LATEST OWNER REVISION 2026-10-12]

**MANDATORY lesson/tutorial capped at THREE first production levels, no fourth–tenth tutorial.** Owner final day-one Tasks 100 SB authority: `coordination/sessions/M44-TUTORIAL-FTUE-C001/OWNER_M44_FIRST3_STARTER_AND_CLAIM_DECISION_V03.md`. Earlier 10-level instructional pacing is obsolete. Authoritative V02 plan: `coordination/sessions/M44-TUTORIAL-FTUE-C001/CHATGPT_OWNER_FTUE_FIRST3_UNLOCK_PLAN_V02.md`.

- Home immediately after the non-skippable native opening cinematic: DAY 1 Daily Rewards and Tasks are both present and actionable. Daily existing login D1 claim is 100 SB; current code does **not** have a ready task on a truly fresh save. Proposed owner-directed solution: once-only fresh-profile day1 easy starter Task (index0, 100 SB) claimable on Home, replacing that day's normal easy task without creating a fourth; ordinary Tasks resume on future days at unchanged canonical tiers 75/100/125 SB. Display and grant the starter TASKS 100 SB through one genuine claim, in addition to the separately claimed DAILY 100 SB; wallet 1,000 -> 1,200 when both are claimed. No fake CLAIM badge and no forced claim. Existing-player tasks state unchanged.
- Level 1 (Hazard Bot): legal front-row selection, rightmost-empty slot, five-slot/preview concept and actual cleaning.
- Level 2 (Apple): contextual compact introduction of ALL FOUR boosters (+1 Slot, Selector, Random, Tornado); optional legal use only, no forced charges spent.
- Level 3 (Palm Tree): consolidate no-current-target/queue, Hearts/Retry rules (no scripted loss), manual/paid 2x versus free automatic endgame 2x. Intro concludes by L3 Results.
- Level 4 onward: NO mandatory tutorial steps; normal real earned/unlocked reward and UI flows continue, as does optional read-only Help if later owner approves.
- Owner-directed starter inventory: new profiles start with exactly **two charges EACH** of the four canonical boosters (8 total), since first-level normal rewards do not guarantee those charges. One-time, save-safe and idempotent, not a fictitious tutorial counter. No duplication for existing profiles, reinstall/replay/skip.
- All tutorial highlights reference real selectable controls/active rules, never mutate solver, level art, economy without an authorized starter grant, or first-clear progression. All coachmarks follow localization, reduced effects and accessibility constraints.
- Skip Tips and hard-vs-soft discovery policy are **not** settled by this update; earlier owner-locked cinematic remains strictly NON-SKIPPABLE. Confirm proposed Skip Tips/read-only Help and existing-feature non-locking before writing the single M44 Claude master implementation prompt.

### 1.1 Implementation (M44 master V01, awaiting ChatGPT audit + owner visual gate)

- Data: `data/config/ftue_onboarding_v1.json` (strict reader `scripts/app/ftue_config.gd`): starter charges 2/2/2/2, first-day Welcome task index 0 = 100 SB, `max_tutorial_level` 3, lessons for Home + L1/L2/L3 bound to catalog ids, once-per-version What's New. The old `soft_no_hard_locks` / `available_from_first_home` policy is retired (see 1.2).
- Fresh profile = `SaveService.load()` found no save artefact at all (`fresh`); `AppState.bootstrap_new_profile()` grants the starter charges (ledger tx `ftue_starter_boosters:v1`) and installs the Welcome task in one saved transaction (rollback on save failure). Existing / migrated / corrupt / backup / future-schema saves are never re-classified.
- `DailyService.task_reward_sb()` is the shown == credited task value; `daily.task_sb` stays 75/100/125. `claim_daily_login` / `claim_daily_task` roll back if the save fails.
- `scripts/app/ftue_director.gd` picks one step; `scripts/ui/tutorial/coachmark_layer.gd` draws it non-blocking with the approved ring / pointer / bubble art; GOT IT / SKIP TIPS (tips only). Read-only Help & Tips: Settings "?". Established saves get the M43 Feature Unlock ceremony once for Help & Tips.
- Skip Tips + read-only Help are the presentation default; owner visual approval (SB-M44-018 / 020) is still pending.

### 1.2 Hard unlock gating (SB-M44-031 part 1, owner table 2026-10-22)

Hard unlock gating is in force per the owner table in `data/config/feature_unlocks_v1.json` (reader `scripts/progression/feature_unlocks.gd`): Hearts L1, Gift Bar L1, Daily 4, Shop 8, Tasks 12, Collection 20, Card Packs 20, Robots 25, Events 30, Achievements screen 35, RANKS 40; boosters +1 Slot 6, Random 11, Selector 16, Tornado 21.

- One gate: `AppState.feature_unlocked(id)`. Unlocked iff the save is grandfathered or the campaign frontier has reached the level; the frontier never decreases, so nothing re-locks.
- Grandfather (orchestrator default, owner may override): every save that is not a new FTUE profile (existing / migrated / established) keeps all features.
- Missing / malformed config or an unknown id unlocks (fail open).
- Gated now: Home DAILY / TASKS / SHOP / COLLECTION shortcuts and ROBOTS / EVENTS / RANKS tabs (disabled, "Unlocks at level N", no badge, no navigation); the booster bar (`locked`, charges kept); FTUE coachmarks skip a locked Home shortcut and drop locked boosters from a booster step.
- Not gated: deep links outside Home and the booster bar (in-context Shop hand-off, Results, Settings).
- Part 2 pending (TASKS.md SB-M44-031 part 2): per-booster lessons at 6/11/16/21, Daily/Tasks coachmarks after L4/L12, deferring the starter booster grant and the 100 SB Welcome task to their unlocks. Until then a fresh profile holds the 8 starter charges and the Welcome task unused until the matching feature unlocks.

## 2. Feature set requiring unlock pacing

- Hearts acquisition education;
- +1 Slot;
- Random;
- Selector;
- Tornado;
- 2x manual acquisition;
- Daily;
- Tasks;
- Collection;
- Card Packs;
- Robots;
- Gift Meter/Gift Bar;
- Shop;
- Achievements;
- Events;
- Ranks.

## 3. Assistance loop

On the third consecutive fail of the same progression level, Need a Hand may appear using the canonical assistance rule.

The game must not secretly reduce difficulty or manipulate supply because a player fails/pays/refuses ads. Assistance is explicit.

## 4. Comeback

Long-absence return may summarize:
- regenerated Hearts;
- Daily availability;
- Tasks availability;
- Gift claimables;
- Event state;
- newly unlocked/NEW destinations.

Do not fabricate rewards merely to stage a comeback unless a later owner reward rule authorizes them.

## 5. Attention hierarchy

Use badges/coachmarks sparingly:
- one primary new thing at a time in FTUE;
- NEW clears after first meaningful visit;
- claimable badges reflect real claimable state;
- no flashing all-nav overload.

## 6. Owner playtest gates

Owner should play:
- completely fresh save through first session;
- first fail and third fail;
- first Heart shortage;
- first booster acquisition;
- first pack;
- first robot unlock;
- first set completion;
- return after simulated absence.
