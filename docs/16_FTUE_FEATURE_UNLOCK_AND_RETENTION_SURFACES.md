# 16 - FTUE, Feature Unlock and Retention Surfaces

Status: M44 OWNER-REVISED 2026-10-12 / IMPLEMENTATION PENDING
Date: 2026-09-26

## 1. First-session design [LATEST OWNER REVISION 2026-10-12]

**MANDATORY lesson/tutorial capped at THREE first production levels, no fourth–tenth tutorial.** Owner final day-one Tasks 100 SB authority: `coordination/sessions/M44-TUTORIAL-FTUE-C001/OWNER_M44_FIRST3_STARTER_AND_CLAIM_DECISION_V03.md`. Earlier 10-level instructional pacing is obsolete. Authoritative V02 plan: `coordination/sessions/M44-TUTORIAL-FTUE-C001/CHATGPT_OWNER_FTUE_FIRST3_UNLOCK_PLAN_V02.md`.

- Home immediately after the non-skippable native opening cinematic: DAY 1 Daily Rewards and Tasks are both present and actionable. Daily existing login D1 claim is 100 SB; current code does **not** have a ready task on a truly fresh save. Proposed owner-directed solution: once-only fresh-profile day1 easy starter Task (index0, 100 SB) claimable on Home, replacing that day's normal easy task without creating a fourth; ordinary Tasks resume on future days at unchanged canonical tiers 75/100/125 SB. Display and grant the starter TASKS 100 SB through one genuine claim, in addition to the separately claimed DAILY 100 SB; wallet 1,000 -> 1,200 when both are claimed. No fake CLAIM badge and no forced claim. Existing-player tasks state unchanged.
- Level 1 (Hazard Bot): legal front-row selection, rightmost-empty slot, five-slot/preview concept and actual cleaning.
- Level 2 (Apple): contextual compact introduction of ALL FOUR boosters (+1 Slot, Selector, Random, Tornado); optional legal use only, no forced charges spent.
- Level 3 (Palm Tree): manual/paid 2x versus free automatic endgame 2x. Intro concludes by L3 Results. No-current-target (WAITING) and Hearts/Retry are taught contextually at their first real occurrence instead (1.3; no scripted loss or stall).
- Level 4 onward: NO mandatory tutorial steps; normal real earned/unlocked reward and UI flows continue, as does optional read-only Help if later owner approves.
- Owner-directed starter inventory: new profiles start with exactly **two charges EACH** of the four canonical boosters (8 total), since first-level normal rewards do not guarantee those charges. One-time, save-safe and idempotent, not a fictitious tutorial counter. No duplication for existing profiles, reinstall/replay/skip.
- All tutorial highlights reference real selectable controls/active rules, never mutate solver, level art, economy without an authorized starter grant, or first-clear progression. All coachmarks follow localization, reduced effects and accessibility constraints.
- Skip Tips and hard-vs-soft discovery policy are **not** settled by this update; earlier owner-locked cinematic remains strictly NON-SKIPPABLE. Confirm proposed Skip Tips/read-only Help and existing-feature non-locking before writing the single M44 Claude master implementation prompt.

### 1.1 Implementation (M44 master V01, awaiting ChatGPT audit + owner visual gate)

- Data: `data/config/ftue_onboarding_v1.json` (strict reader `scripts/app/ftue_config.gd`): starter charges 2/2/2/2, first-day Welcome task index 0 = 100 SB, `max_tutorial_level` 3, lessons for Home + L1/L2/L3 bound to catalog ids, once-per-version What's New. The old `soft_no_hard_locks` / `available_from_first_home` policy is retired (see 1.2).
- Fresh profile = `SaveService.load()` found no save artefact at all (`fresh`); `AppState.bootstrap_new_profile()` grants the starter charges (ledger tx `ftue_starter_boosters:v1`) and installs the Welcome task in one saved transaction (rollback on save failure). Existing / migrated / corrupt / backup / future-schema saves are never re-classified.
- `DailyService.task_reward_sb()` is the shown == credited task value; `daily.task_sb` stays 75/100/125. `claim_daily_login` / `claim_daily_task` roll back if the save fails.
- `scripts/app/ftue_director.gd` picks one step; `scripts/ui/tutorial/coachmark_layer.gd` draws it non-blocking with the approved ring / pointer / bubble art; GOT IT / SKIP TIPS (tips only). Read-only Help & Tips: Settings "?". Established saves get the M43 Feature Unlock ceremony once for Help & Tips.
- Skip Tips + read-only Help are the presentation default; the coachmark visual language (SB-M44-018) is documented in 1.5.

### 1.2 Hard unlock gating (SB-M44-031 part 1, owner table 2026-10-22)

Hard unlock gating is in force per the owner table in `data/config/feature_unlocks_v1.json` (reader `scripts/progression/feature_unlocks.gd`): Hearts L1, Gift Bar L1, Daily 4, Shop 8, Tasks 12, Collection 20, Card Packs 20, Robots 25, Events 30, Achievements screen 35, RANKS 40; boosters +1 Slot 6, Random 11, Selector 16, Tornado 21.

- One gate: `AppState.feature_unlocked(id)`. Unlocked iff the save is grandfathered or the campaign frontier has reached the level; the frontier never decreases, so nothing re-locks.
- Grandfather (orchestrator default, owner may override): every save that is not a new FTUE profile (existing / migrated / established) keeps all features.
- Missing / malformed config or an unknown id unlocks (fail open).
- Gated now: Home DAILY / TASKS / SHOP / COLLECTION shortcuts and ROBOTS / EVENTS / RANKS tabs (disabled, "Unlocks at level N", no badge, no navigation); the booster bar (`locked`, charges kept); FTUE coachmarks skip a locked Home shortcut and drop locked boosters from a booster step.
- Not gated: deep links outside Home and the booster bar (in-context Shop hand-off, Results, Settings).
- Part 2 pending (TASKS.md SB-M44-031 part 2): per-booster lessons at 6/11/16/21, Daily/Tasks coachmarks after L4/L12, deferring the starter booster grant and the 100 SB Welcome task to their unlocks. Until then a fresh profile holds the 8 starter charges and the Welcome task unused until the matching feature unlocks.

### 1.3 Contextual first-occurrence coachmarks (SB-M44-005 / SB-M44-006)

- Data: top-level `contextual` array in `data/config/ftue_onboarding_v1.json`, strict like the rest (unique ids across lessons and entries, one entry per trigger, known target, existing UiText keys; anything malformed rejects the whole file):
  - `ctx_waiting` (trigger `slot_waiting`, target `slots`): the first time any slot of the live host is WAITING (`AutoDispatchScheduler.is_slot_waiting`).
  - `ctx_result_won` (trigger `result_won`, no pointer): first WON Results. A win costs no Heart; each new level cleared in a row grows the Win Streak.
  - `ctx_result_lost` (trigger `result_lost`, target `results_retry` = the Results RETRY button): first LOST Results. "This try cost 1 Heart." only when the committed terminal receipt's Hearts went down, otherwise a no-loss sentence; RETRY starts the level again; Hearts refill over time.
- The scheduled `l3_waiting` / `l3_hearts` steps are removed from `l3_rules` (only `l3_speed` remains). Old saves that marked them seen stay valid.
- Eligibility: a NEW profile that has not chosen Skip Tips, at any level (not limited to the L1-L3 window or `closed`). Established / grandfathered profiles never see them. A due scheduled step wins; one coachmark at a time.
- One-shot: acknowledged by GOT IT or by the real action (the WAITING situation ends, or Results is left via RETRY / CONTINUE / HOME) into the existing `FtueState.seen` ledger, saved canonically; never shown again after relaunch.
- Presentation only (`main.gd` `_coach_trigger` / `_coach_want`): read-only triggers, hidden under modals / Settings and while the Results reveal or a ceremony barrier runs. No Heart, reward, booster, progression or scheduler change. Evidence: `tests/m44_contextual_coach.gd`.

### 1.4 NEW badge on newly unlocked Home entries (SB-M44-013)

- Rule: `HomeBadges.new_features(app)` (`scripts/ui/home/home_badges.gd`, which also owns `GATED_ENTRIES`) lists the gated Home entries (SHOP / COLLECTION / TASKS / DAILY shortcuts, ROBOTS / EVENTS / RANKS tabs) that a NEW FTUE profile has unlocked (`AppState.feature_unlocked`) and not yet visited. Grandfathered profiles never show NEW.
- Visited = the meta_ui presentation key `feature_visited:<feature_id>` (no new save section, no schema bump). The first press of an enabled NEW entry marks it and requests the canonical save, then Home refreshes. Locked or disabled entries cannot be pressed, so they never mark. Old saves load unchanged.
- Presentation: the existing red count badge (`UiShortcutButton.set_badge_text`, `NavBadge_<id>`) shows the localized `HOME_BADGE_NEW` text "NEW"; the pill grows inward from the top-right corner. A real count > 0 on the same entry wins over NEW. No animation, no sound, no new art.
- Evidence: `tests/m44_new_badge.gd`.

### 1.4a Feature Unlock ceremony on reaching a table level (SB-M43-072)

- M43-C005 meta ceremonies (one at a time via `scripts/ui/ceremony/ceremony_presenter.gd`): Collection set 9/9 (`set:<n>`, SB-M43-068), Master Collection (`master`, 069), Robot Unlock with EQUIP / KEEP CURRENT (`robot:<id>`, 070/071), Gift Meter milestone (`gift:`), and the Feature Unlock ceremony (`unlock:<feature_id>`, 072).
- 072 rule: a NEW FTUE profile gets ONE "NEW FEATURE!" ceremony (`MetaCeremonies.feature_unlock`, GOT IT) per owner-table feature with level > 1 once `AppState.feature_unlocked(id)` is true. `CeremonyPresenter.feature_events()` derives them read-only, ascending by table level, after the gift / set / Master / robot events; name / body are `UiText` `FEATURE_<ID>_NAME/BODY`. Grandfathered saves and L1 features (Hearts, Gift Bar) get none.
- Presentable now (existing promoted icon in `CeremonyPresenter.FEATURE_ICONS`): Daily, Shop, Tasks, Collection (`assets/ui/final/home/shortcuts/`). Skipped until art exists (no art invented): Card Packs, Robots, Events, Achievements, RANKS and the four boosters (booster lessons stay with SB-M44-031 part 2).
- Scheduling: rides the existing Results hand-off barrier / quiet Home drain (meta ceremonies first, then earned packs, then What's New), so it never stacks with another popup; coachmarks are hidden under it. The NEW badge (`feature_visited:`) and What's New (`feature:<id>:<v>`) keys are separate and untouched.
- Acknowledged only by its CTA: meta_ui `unlock:<id>` + canonical save; reload never replays. If that save fails the mark is rolled back and the ceremony is snoozed for the session (shown again next launch). Presentation only: no grant, spend or unlock-state change. Evidence: `tests/m43_c005_c072_feature_unlock_ceremony.gd`.

### 1.5 Coachmark visual language (SB-M44-018)

- Location: `scripts/ui/tutorial/coachmark_layer.gd` (CanvasLayer 40: above Home / gameplay / Results, below the ModalStack at 64). One coachmark at a time, picked by `FtueDirector`.
- Parts, all approved existing art under `assets/ui/final/gameplay/tutorial/`: `tutorial_highlight_ring.png` stretched around the real target (target rect grown by 10% of its longer side + 12 px); `tutorial_pointer.png` (side = 10% of the viewport width, 64..128 px) above the ring pointing down, or below it pointing up when there is more room there; `speech_bubble.png` (max 820 px wide, shrunk so it never covers the target) with a navy ink (`#1B2E59`) title (34 px) and body (28 px), then two buttons: SKIP TIPS (cream fill, tan edge) and GOT IT (Home green).
- Cue = shape (ring + arrow) + text, never colour alone. Non-blocking: everything except the two buttons ignores input, so the real control underneath stays tappable. A step without a legal target shows the bubble only (no ring / pointer).
- Motion: the pointer bobs 14 px toward the target, 0.45 s each way (sine), looping. Reduced Effects: no pointer motion (static pointer). Tweens die on hide / exit.
- Reuse rule: every new tutorial highlight must go through CoachmarkLayer (a step in `data/config/ftue_onboarding_v1.json` + `FtueDirector`), never a one-off overlay. Attention on Home entries uses the NEW pill / count badge of 1.4, not a coachmark.
- No additional art and no Scrubby teaching poses are required for M44; the existing ring / pointer / bubble set is final.

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
