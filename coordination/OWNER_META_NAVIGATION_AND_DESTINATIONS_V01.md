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
RANKS requires an explicit fair scoring policy before implementation.

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
