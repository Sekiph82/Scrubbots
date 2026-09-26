# 04 — Roadmap

Status: **current dependency roadmap — 2026-09-18**

`TASKS.md` is the only canonical live milestone/task tracker. This document
describes dependency order and program boundaries. If status text here ever
disagrees with `TASKS.md`, `TASKS.md` wins.

## 1. Completed foundation

The project has already established:

- variable-size LevelData / BoardState;
- exact pixel-art import and reconstruction tooling;
- locked C01..C16 production palette rules;
- batched BoardRenderer with ACTIVE/CLEARED transparency;
- five-slot data/UI foundation;
- color candidate indexing and production access truth;
- reservation and target selection;
- production routing and ScrubbotAgent;
- authenticated clearing loop;
- first real-art Hazard Bot vertical slice;
- Railroad V1 exterior movement and slot connectors;
- legal post-rail OPEN/CLEARED interior corridor routing;
- Batch Supply Engine (M23);
- Five-Slot Batch Engine (M24).

The gameplay architecture remains data-oriented. UI and visual production must
not duplicate gameplay truth.

## 2. Current core-gameplay program

As of 2026-09-18 the active milestone is **M25 — Batch Target Claim Engine**.

Canonical sequence:

```text
M23 Batch Supply Engine                CLOSED
-> M24 Five-Slot Batch Engine          CLOSED
-> M25 Batch Target Claim Engine       ACTIVE
-> M26 Auto Dispatch Scheduler
-> M27 Solvability / Deadlock Engine
```

M25 owns unique batch/target claim identity, same-color arbitration,
transactional claim lifecycle and rollback. M26 must consume those authorities
without inventing a second target/claim truth. M27 must prove a full level has
at least one legal player-choice sequence and must distinguish temporary
WAITING/STALLED states from a proven deadlock.

No production UI milestone may weaken these core invariants.

## 3. Production gameplay presentation

After M25–M27:

### M28 — Gameplay Screen Layout

- canonical `docs/MASTER_UI_SYSTEM.md` composition;
- board is the dominant screen region;
- five-slot/color-selection area stays usable;
- Scrubby and decorative cleaning props remain subordinate to gameplay;
- Railroad V1 presentation uses the same geometry truth as routing;
- no baked dynamic labels, counters or gameplay state.

### M29 — Mobile Touch

- production touch targets and gesture behavior;
- safe-area correctness;
- board/input coordinate accuracy;
- rapid-tap protection where needed.

### M31 / M32 — Effects and final Scrubbot visuals

Illustrative assets are generated only when their owning milestone needs them.
ChatGPT image generation is primary; Magnific MCP remains an approved fallback.
Neither is a runtime dependency.

## 4. Rules / progression / persistence

Canonical later milestones:

```text
M30  Win/Lose Rules
M35  Level Catalog
M36  Difficulty System
M37  Level Progression
M38  Win Streak
M39  Economy
M40  Save System
M41  Settings
```

Win/lose and real-money monetization remain design-gated where `TASKS.md`
marks them as such. Economy/Rewards V1 is now owner-locked by
`coordination/OWNER_ECONOMY_REWARDS_V01.md` and M39 must implement that
contract rather than inventing currency/reward semantics. Difficulty V1 does
not authorize hidden timer/move-limit or monetization mechanics.

## 5. Home and later screens

```text
M42  Home / Navigation
M43  Results + complete Player Experience / Meta UI surface program
M44  Tutorial / FTUE / feature-unlock pacing
M45  Debug Tooling
```

### Player experience completion program

After the locked First 10 Level Pack closes, the roadmap must also close the later Gameplay V02 delta (M28-C002) and the expanded M43/M44 player-facing program defined in root TASKS.md.

The program includes fail/retry/Life/Need-a-Hand, booster and 2x acquisition, Shop, Collection/Cards Exchange, pack opening, Robots, Tasks/Daily/Gift Bar, Profile/Achievements, Events/Ranks, reward/unlock ceremonies, world progression, comeback/notifications, account/cloud recovery, meta audio/haptics and all required visual masters.

Canonical rules:
- `coordination/OWNER_PLAYER_EXPERIENCE_SURFACE_PROGRAM_V01.md`
- `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md`
- `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md`
- `coordination/OWNER_REWARD_CEREMONY_FEATURE_UNLOCK_V01.md`
- `docs/15_PLAYER_EXPERIENCE_UI_ARCHITECTURE.md`
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`

Home preproduction already has:

- canonical owner reference;
- responsive composition contract;
- `assets/ui/HOME_ASSET_MANIFEST.json`;
- raw/final asset directory separation;
- provider/provenance policy.

This is **preproduction only**. It does not mark M42 complete or move Home
implementation ahead of the core-gameplay sequence.

## 6. Mobile quality / release chain

```text
M46  Performance
M47  Android Device Testing
M48  iOS Readiness
M49  Responsive UI
M50  Accessibility
M51  Localization Readiness
M52  Production Content Scale-Up
M53  Level QA
M54  Regression Suite
M55  Chaos / Long-Run QA
M56  Analytics [design gate]
M57  Monetization [design gate]
M58  Privacy & Compliance
M59  Build Pipeline
M60  Release
```

A milestone is not complete merely because a scene/file exists. Required
owner gates, import/binding, viewport/device validation and regression evidence
must also exist.

## 7. Difficulty / progression V1

Canonical sources:

- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`
- `docs/12_ADR_DIFFICULTY_V1.md`
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

Locked high-level principles:

- campaign cadence is separate from board physical dimensions;
- color count alone does not determine difficulty;
- Challenge Score, Session Load and Frustration Risk are separate;
- difficulty class is evaluated from the full model, not one proxy metric;
- content must be solver/QA validated before production acceptance.

## 8. Level Factory / Content Platform boundary

The 224 Level Factory + Content Platform requirements are no longer live
checklist rows in this game repository. Their canonical tracker is:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

The root repository may retain historical/local `level_factory/` and
`content_pipeline/` folders, but live requirement ownership is externalized
to prevent double-counting.

Shipping runtime implementation remains in this game repository when it is
actually needed, especially remote content loading/cache/disable behavior.
Offline generation, solver authoring and publisher credentials never ship in
the mobile app.

## 9. Visual-production dependency rule

Visual production is part of the main SCRUBBOTS project, not a disconnected
final-art project.

Order of authority:

```text
owner-approved original art
-> owner-supplied project references
-> owner-approved generated production assets
-> external inspiration (method/reference only; never copied)
```

Raw generated candidates live under `assets/ui/generated/`; only approved
production assets belong in `assets/ui/final/`.

## 10. Current critical path

```text
M25 claim hardening
-> M26 auto dispatch
-> M27 solvability/deadlock
-> M28/M29 production gameplay UI + touch
-> completion/progression/save
-> Home
-> Gameplay V02 production convergence
-> Results + popup/recovery/acquisition family
-> Shop/Collection/Robots/Tasks/Daily/Gift/Profile/Achievements/Events/Ranks
-> FTUE/feature unlock + reward/pack/robot/world ceremonies
-> mobile performance + responsive/accessibility/localization
-> content scale-up + QA
-> release
```
