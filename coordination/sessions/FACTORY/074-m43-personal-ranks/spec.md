# Personal Ranks destination

> Feature: SB-M43-122 RANKS tab becomes a real destination. OWNER DECISION (chat 2026-10-31, "Ranks sekmesi ne olsun?"): "Kisisel rutbe" - a PERSONAL rank ladder, no server, no leaderboard, no other players, no privacy exposure. Player's own rank tiers (Bronze/Silver/Gold...) driven by existing progress, plus progress to the next rank. This is the "explicit fair scoring policy" required by coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md section 3.

## Context
- BottomNav is built in `scripts/ui/home/home_screen.gd` (`_build_bottom_nav`, ~L1094). The RANKS tab has nav id `leaderboard` (node `Nav_leaderboard`, text `HOME_NAV_LEADERBOARD` = "RANKS"). It is gated by `HomeBadges.GATED_ENTRIES["leaderboard"] = "ranks"` -> `data/config/feature_unlocks_v1.json` `ranks: 40` (keep; grandfathered saves stay unlocked via `AppState.feature_unlocked`).
- A tab is enabled only if the app root lists it in `APP_NAV` (`scripts/app/main.gd` L51, currently `["events"]`, passed to `_home.set_app_nav`). Today `leaderboard` is not served, so it is disabled with tooltip `HOME_COMING_LATER`.
- `main.gd::_on_home_nav(id)` opens app-level destinations: `"events"` -> `ProfileScreens.open_events(_modals, app_state)` (`scripts/ui/profile/profile_screens.gd`, a `BasePopup` "large" frame on the ModalStack with a `close` action). `open_profile` / `open_events` in that file are the pattern to copy. `open_deep_link` also routes through `_on_home_nav`.
- Existing progress truth: `app.progression.completed_count()` (campaign levels cleared; already in `HomeViewModel` as `completed_levels`). There is no profile XP; do not invent one.
- Existing tests that touch this: `tests/m43_master_c010_meta.gd` m01 (asserts RANKS disabled/coming-later) and m11 (greps profile_screens.gd, home_badges.gd, event_service.gd, player_records.gd for the words `rank_score`, `ranking`, `leaderboard_score`, `placement`); `tests/m44_unlock_gate.gd` L145 asserts RANKS is coming-later on a standalone Home (no app root) - this stays true and must keep passing; `tests/m42_home_v04.gd` L363 asserts tab names/text.

## Requirements
1. New data file `data/config/personal_ranks_v1.json`: schema id, version 1, `metric: "campaign_levels_cleared"`, and an ascending list of tiers `{id, name_key, min_cleared}`. First tier has `min_cleared` 0. Suggested six tiers: Bronze 0, Silver 25, Gold 75, Platinum 150, Diamond 300, Master 500 (builder may adjust values; must be strictly ascending, integers, first = 0).
2. New pure helper `scripts/progression/personal_rank.gd` (static, no Node, no state, no save writes): loads and validates the JSON (fail closed to an empty/invalid result, never crash) and exposes `for_cleared(n) -> {index, id, name_key, min_cleared, next_id (or ""), next_min (or -1), into, span}` where `into/span` give progress inside the current tier (top tier: complete, no next). Negative n clamps to 0.
3. `ProfileScreens.open_ranks(stack, app)` in `profile_screens.gd`: a BasePopup (`popup_id` "ranks", large frame, title "RANKS", `close` action, same pattern as `open_events`) showing: the player's current rank name, levels cleared, a progress bar/label to the next rank ("N more levels to <Next>" or a top-rank line), and the full ladder list with the current tier highlighted and reached tiers marked. Reuse existing Controls/`UiProgressMeter` and `UiTokens`; final assets already in the repo only - no new art. Read-only: it must not mutate economy, save, or grant anything.
4. Wire it: add `"leaderboard"` to `APP_NAV` in `main.gd` and a `"leaderboard": ProfileScreens.open_ranks(_modals, app_state)` case in `_on_home_nav`. Pressing the enabled tab opens the screen; closing it returns to Home. Update the stale `APP_NAV` comment. Locked state (fresh profile below L40) is unchanged.
5. No dead tab: with the app root running and the unlock satisfied, `Nav_leaderboard` is enabled with empty tooltip.
6. All user text goes through `UiText` (`scripts/ui/ui_text.gd`) keys (e.g. `RANKS_TITLE`, `RANKS_CURRENT`, `RANKS_CLEARED`, `RANKS_NEXT`, `RANKS_TOP`, tier names `RANK_BRONZE`...). Avoid the words `ranking`, `rank_score`, `leaderboard_score`, `placement` in the m11-scanned files.
7. Update existing tests that encoded the old state: m01 in `m43_master_c010_meta.gd` (RANKS now live, opens "ranks"), and m11 (keep the "no scoring/leaderboard invented" intent; point it at the personal ladder: no server, no other-player data). Do not weaken other assertions.
8. One new focused suite `tests/m43_personal_ranks.gd` (register in `tests/run_tests.gd` like sibling suites if they are listed there).
9. Docs: record the owner decision in `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md` section 3 (replace "RANKS requires an explicit fair scoring policy" with the personal-ladder policy: metric, no server/leaderboard/other players/rewards); in `TASKS.md` mark SB-M43-122 done with evidence (lines ~59 and ~1207), note SB-M58-012 is not triggered by Ranks (no social exposure; it remains for any future real leaderboard); mention the new config in AGENTS.md only if it lists config files.

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_personal_ranks.gd` exits 0 and prints a final PASS line (suite prints `PASS` and per-case lines). It covers 2-8 below.
2. Data: JSON loads; tiers strictly ascending, first `min_cleared == 0`; a corrupted/unsorted table makes the helper return the invalid result without crashing.
3. `PersonalRank.for_cleared`: 0 -> first tier; exactly a threshold -> that tier with `into == 0`; threshold-1 -> previous tier; far above top -> top tier with `next_id == ""`; -5 -> first tier.
4. With the real app root (pattern of `m43_master_c010_meta.gd`, test save path) at campaign level >= 40 or a grandfathered save: `Nav_leaderboard` is not disabled; emitting `pressed` makes the ModalStack top popup id `"ranks"`; closing it leaves the route on HOME with no modal.
5. The screen text reflects the save: after recording N cleared levels the shown current rank and "levels to next" match `for_cleared(N)` (assert via named child labels, not pixels).
6. Fresh FTUE profile at L1: `Nav_leaderboard` is disabled with the `HOME_UNLOCKS_AT_LEVEL` tooltip (gate preserved).
7. Opening the screen does not change the economy/save snapshot (`economy.snapshot()` equal before/after).
8. No network/leaderboard: grep of `personal_rank.gd` and the new `open_ranks` code finds no `HTTPRequest`, `leaderboard_score`, `ranking`.
9. Regressions pass: `m43_master_c010_meta.gd`, `m44_unlock_gate.gd`, `m42_home_v04.gd`, `m42_navigation.gd` each print their PASS line.
10. `git diff --check` clean; `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md` contains the personal-ladder decision; TASKS.md SB-M43-122 closed with evidence.

## Out of scope
- Leaderboards, servers, other players, display names, friends, reporting/blocking (SB-M58-012).
- Rank rewards, Stars, Event Points, new currencies, XP system, SB payouts, new boosters.
- New generated art or icons; new fonts.
- Changing the unlock level (40), FTUE, or other BottomNav tabs.
- Adding rank to the save file (rank is derived on read).
- Difficulty/level content changes.

## Assumptions
- Metric = campaign levels cleared (`completed_count()`): it is existing, monotonic truth; the Home "level" badge is current frontier and there is no XP.
- Tier names/thresholds are a placeholder-quality default, editable in the JSON without code changes (owner gave "Bronze/Silver/Gold..." as examples).
- Screen is a large BasePopup on the ModalStack (same as EVENTS/PROFILE) rather than a new route; "back to Home" = close.
- Nav id `leaderboard` is kept internally to avoid churning tests/badges; only the displayed label "RANKS" matters.
