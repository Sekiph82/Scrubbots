# OWNER PLAYER EXPERIENCE SURFACE PROGRAM V01

Date: 2026-09-26
Authority: OWNER
Repository: Sekiph82/Scrubbots
Status: PLANNED / REQUIRED ROADMAP
Scope: complete player-facing screen, popup, destination, reward, recovery and meta-UI coverage.

## 1. Purpose

SCRUBBOTS must not ship with dead buttons, placeholder destinations, invisible economy mutations or missing player-facing recovery/reward surfaces.

The canonical live implementation tracker is root `TASKS.md`. This document is a durable owner rule describing the required player-experience surface family and the completeness standard behind the expanded M28-C002 / M43 / M44 roadmap.

## 2. Canonical completeness rule

Every reachable player-facing action must terminate in exactly one of:

1. a real implemented screen or popup using live authoritative data;
2. an explicitly disabled control with a clear unavailable state; or
3. a platform-native surface that returns safely to the game.

A shipping control may not point to debug UI, a dummy scene, a silent no-op or a fake success state.

## 3. Required V1 surface inventory

The project must plan, visually approve, implement and validate:

- Gameplay V02.
- Pause.
- Level Intro.
- Victory / Results.
- Fail / Retry.
- Life / Heart refill.
- Need a Hand.
- Booster Acquire.
- 2x Acquire.
- Insufficient SB / Shop handoff.
- Shop.
- Collection album.
- Collection set detail.
- Card detail.
- Cards Exchange.
- Standard Pack opening.
- Premium Pack opening.
- Collection set completion.
- Master Collection completion.
- Robots main.
- Robot detail / locked state.
- Robot unlock.
- Tasks.
- Daily.
- Gift Bar.
- Gift Meter milestone.
- Profile.
- Achievements.
- Events list/home.
- Event detail/reward.
- Ranks.
- Comeback / return summary.
- Feature unlock / coachmark.
- World unlock / transition.
- Account/cloud sync/conflict custom UI where needed.
- Generic reward/confirmation.
- Generic error/offline/loading.
- Notification education/settings custom UI where needed.

## 4. Visual rule

Each material surface requires:

1. canonical owner reference or newly produced visual master;
2. subsystem manifest entry and asset inventory;
3. only required illustration generation;
4. owner visual approval before production promotion;
5. responsive Godot implementation with live/localizable text, prices, timers, quantities and state;
6. independent audit;
7. owner runtime/playtest acceptance.

Full-screen AI mockups are references, not shipping flattened UI.

## 5. Existing canonical references

- Gameplay master: `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- Life: `assets/art/references/_owner_inbox/Additionals/life screens.png`
- Need a Hand: `assets/art/references/_owner_inbox/Additionals/need a hand.png`
- Level Intro: `assets/art/references/_owner_inbox/Game Screens/level ekran acilisi.png`
- Home/World 01: current M42 owner-approved authorities.

## 6. Delivery boundary

The current First 10 Level Pack sequencing lock remains unchanged. This owner program is planning authority for work after that block closes. It does not authorize implementation agents to jump ahead of the active M52/M53/M54 closure.

## 7. Related authorities

- `TASKS.md`
- `docs/MASTER_UI_SYSTEM.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`
- `coordination/OWNER_ROBOT_ROSTER_V01.md`
- `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`
- `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md`
- `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md`
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`
