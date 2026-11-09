# OWNER META NAVIGATION AND DESTINATIONS V01

Date: 2026-09-26
Authority: OWNER
Status: PLANNED / REQUIRED
Scope: Home actions, HUD plus controls, BottomNav, destination ownership.

## 1. Home shortcut destinations

Current Home has exactly four main shortcut panels:
- SHOP
- COLLECTION
- TASKS
- DAILY

Each must open a real destination.

Cards Exchange belongs inside Collection.
No Ads belongs inside Shop.
Gift claim/history belongs to Gift Bar, not a Home shortcut.
Win Streak remains represented by the Home reward track rather than a shortcut.

## 2. Home HUD plus controls

- Scrub Bucks + -> Shop / SB acquisition context.
- Heart + -> Life popup.

Return context must be preserved so a player routed to Shop because of insufficient SB can return to the original acquisition action cleanly.

## 3. Bottom navigation

The required BottomNav destinations are:
- EVENTS
- ROBOTS
- HOME
- RANKS
- SETTINGS

No shipping dead tab is allowed.

SETTINGS remains the M41 authority.
ROBOTS uses the canonical 10-robot roster.
EVENTS may not reintroduce Event Points/new event currency without a new owner decision.
RANKS is a personal rank ladder (owner decision in chat 2026-10-31, "Kisisel rutbe"): the player's own tiers in `data/config/personal_ranks_v1.json`, metric = campaign levels cleared (`progression.completed_count()`), derived on read and never saved. No server, no leaderboard, no other players, no display names and no rewards. A future real leaderboard needs a new owner decision and SB-M58-012 first.
RANKS two tables (owner decision 2026-10-22 on SB-M43-131; SB-M43-131/132): the screen has an ALL-TIME tab and a WEEKLY tab. ALL-TIME = highest campaign level reached (`progression.current_level()`, the frontier), shown above the personal ladder. WEEKLY = levels completed in the current week, `scripts/progression/weekly_ranks.gd` (economy save section `ranks`). The week runs Monday 00:00:00 UTC to the next Monday 00:00:00 UTC (exclusive), the same instant on every device. Exact counting rule: +1 for each committed campaign WON (the frontier level's first clear, recorded in the gameplay host terminal); losses, Retry, disabled-level skips, Scrub Bucks, Hearts, booster purchases and booster use add nothing (a level won with boosters counts once, like any completed level). The game has no replay path, so a level counts at most once. Clock rollback: a win dated before the stored week is not counted and never rewrites it, and the WEEKLY tab shows 0 while the clock is behind. Both tables show only the player, as "You"; there is no server, so ranks against other players are an honest offline note (online ranks come with Google Play Games / Game Center). Unlock stays Level 40.

## 4. Profile and Achievements

The Home/player profile card opens Profile.
Profile should surface:
- active robot;
- campaign progression;
- selected lifetime stats;
- Collection completion;
- Achievement summary.

Achievements are data-driven and may have rewards only after their reward policy is defined. They cannot mutate puzzle truth.

## 5. Badges

A shared badge authority may display meaningful attention states:
- Tasks ready;
- Daily ready;
- Gift claimable;
- Robot unlocked/new;
- Collection new;
- Event active/reward;
- approved feature-unlock/new states.

Badges must clear deterministically and must not become notification spam.

## 6. Offline and stale content

Network-dependent destinations must expose honest loading/offline/empty/expired states and fail safely back to valid local UI.
