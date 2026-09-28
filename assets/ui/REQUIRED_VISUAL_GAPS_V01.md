# SCRUBBOTS — REQUIRED VISUAL GAPS V01

Date: 2026-09-28
Scope: **only visual deliverables that are still required and currently lack an owner-approved full visual master/reference.**
Status authority remains repository-root `TASKS.md`; this file is a scoped visual-production inventory, not a project-status tracker.

## Rules used for this inventory

Included only when all are true:

1. the surface is required by the current V1 player-experience program;
2. the final visual master/reference is not yet owner-approved;
3. the visual still has to be produced/reviewed before the corresponding production surface can close.

Excluded:

- Gameplay V02 — final owner visual PASS.
- Home / World 01 — owner-approved.
- Victory / Results — final owner visual PASS.
- Level Intro — owner reference already selected and production assets already exist.
- Life / Heart refill — owner reference already selected.
- Need a Hand — owner reference already selected.
- all four gameplay booster icons — already present in `assets/ui/final/boosters/`.
- Scrubby / 10-robot production families — already present.
- all 135 Collection cards and rarity/state frames — already present.
- common popup/button/currency/navigation/system icon families — already present.
- speculative/post-launch Friends art.
- optional illustrations whose need has not yet been proven.
- external game screenshots/references, including Colony Flow material.

## A. Required missing visual masters / references

These **33** visual masters are still required.

| # | Required visual deliverable | Milestone / surface | Existing ScrubBots art that should be reused | Net-new standalone image generation required now? |
|---:|---|---|---|---|
| 1 | **Pause popup master** | M43-C002 | common popup frames, close icon, gameplay Pause icon | **No** — compose/approve master from existing art |
| 2 | **Fail / Retry popup master** | M43-C004 | `popups/failure/*`, Heart assets, common frames | **No** |
| 3 | **Booster Acquire popup master** | M43-C003 | four final booster icons, common popup/button frames | **No** |
| 4 | **2x Acquire popup master** | M43-C003 | 2x gameplay/shop assets, common popup/button frames | **No** |
| 5 | **Insufficient SB / Shop handoff master** | M43-C002/C003 | SB currency icon, common warning/confirmation frames, Shop assets | **No** |
| 6 | **Shop full-screen master** | M43-C006 | `assets/ui/final/shop/*`, common HUD/currency assets | **No** |
| 7 | **Collection Album master** | M43-C007 | 135 final cards, rarity frames, Collection panel/state assets | **No** |
| 8 | **Collection Set Detail master** | M43-C007 | set header/frame/navigation assets + card family | **No** |
| 9 | **Card Detail popup master** | M43-C007 | final card art + rarity frames + common popup frames | **No** |
| 10 | **Cards Exchange master** | M43-C007 | `assets/ui/final/cards_exchange/*` + final Collection cards | **No** |
| 11 | **Standard Pack Opening ceremony master** | M43-C005 | standard pack asset, card art/state assets, reward glow | **No** |
| 12 | **Premium Pack Opening ceremony master** | M43-C005 | premium pack asset, card art/state assets, reward glow | **No** |
| 13 | **Collection Set Complete ceremony master** | M43-C005 | `collection_complete_emblem.png`, reward assets | **No** |
| 14 | **Master Collection Complete ceremony master** | M43-C005 | `master_collection_emblem.png`, reward assets | **No** |
| 15 | **Robots Main screen master** | M43-C008 | complete 10-robot families + `assets/ui/final/robots/*` | **No** |
| 16 | **Locked Robot Detail master** | M43-C008 | robot detail frame, locked silhouette, lock emblem, perk assets | **No** |
| 17 | **Robot Unlock ceremony master** | M43-C005/C008 | robot art, unlock glow/burst, Bot Parts assets | **No** |
| 18 | **Tasks screen master** | M43-C009 | common panels/progress/buttons, SB/reward icons, Tasks shortcut icon | **No** — no unique illustration is mandatory |
| 19 | **Daily screen/popup master + reward-state layout** | M43-C009 | complete `assets/ui/final/daily/*` family | **No** |
| 20 | **Gift Bar master + milestone-card layout** | M43-C009 | Gift Meter assets, reward/gift assets, common frames | **No** — compose cards from existing reward art unless owner later requests unique illustration |
| 21 | **Gift Meter milestone ceremony master** | M43-C005 | gift-meter reward crate, gift box, reward assets | **No** |
| 22 | **Profile screen master** | M43-C010 | robot portraits, profile frames, level/rank assets | **No** |
| 23 | **Achievements screen master** | M43-C010 | common frames/badges only | **Yes, partly** — see Section B |
| 24 | **Events Main screen master** | M43-C010 | nav Events icon + common frames only | **Yes** — see Section B |
| 25 | **Event Detail / Reward master** | M43-C010 | common reward assets; no event visual family exists | **Yes** — share Section B event family |
| 26 | **Ranks screen master** | M43-C010 | leaderboard nav icon, profile rank badge, robot portraits, common frames | **No mandatory new image asset yet** |
| 27 | **Comeback / Return Summary master** | M43-C011 | common popup/reward/status assets | **No** |
| 28 | **Feature Unlock / Coachmark master** | M43-C005 / M44 | tutorial pointer, highlight ring, speech bubble, robot art | **No mandatory new pose until a lesson proves it is needed** |
| 29 | **World Unlock / Transition ceremony master** | M43-C005/C011 | World 01 background and common reward/ceremony assets | **No for World 01**; future world backgrounds are Section B |
| 30 | **Account / Cloud Sync Conflict custom master** | M43-C012 | cloud-save, save-conflict, warning/refresh icons + common frames | **No** |
| 31 | **Generic Reward / Confirmation master** | M43-C002 | popup reward/confirmation frames + reward assets | **No** |
| 32 | **Generic Error / Offline / Loading state master** | M43-C002/C013 | offline, connection-lost, warning, refresh, maintenance icons + common frames | **No** |
| 33 | **Notification Education / Settings custom master** | M43-C011 | notification icons, settings/navigation assets, common frames | **No** |

## B. Net-new image asset families that really still need to be created

The 33 masters above **do not mean 33 new AI-art batches**.

At the current repository state, only these visual families have a proven need for genuinely new standalone image art rather than composition from existing production components:

### B1. Achievements badge/icon family

Required for the shipping Achievements screen once the achievement definitions are owner-locked.

Minimum deliverable:
- reusable achievement badge/emblem frame if the common badge family is insufficient;
- one distinct readable icon per shipping achievement definition, or a smaller canonical icon family if multiple achievements share categories;
- locked/completed/progress presentation must remain native/live where possible.

Do **not** generate a speculative large icon library before the actual achievement definitions exist.

### B2. Events reusable visual family

`assets/ui/final/events/` currently has no production art.

Required minimum before Events can visually close:
- reusable event-card visual family;
- reusable event-detail/header visual family;
- reusable event state treatment for active / ended / claimed / unavailable;
- event reward presentation that reuses existing SB/Bot Parts/Card Pack/Booster assets;
- hero/theme illustration only for an event that is actually approved to ship.

Do not invent an event currency or speculative seasonal art library.

### B3. Future shipping world backgrounds

World 01 Whispering Park already exists and is approved.

For every **additional world that is actually approved to ship**, create:
- one complete world background/master matching the final Home composition;
- any world-specific decorative illustration required by that approved world;
- transition/unlock presentation can otherwise reuse the generic ceremony system.

Quantity is intentionally **TBD** until owner-approved world ranges/registry exist. Do not generate unnamed future-world backgrounds in advance.

## C. Production rule

For every item in Section A:

1. first try to build the visual master from the already-promoted ScrubBots assets;
2. generate new image art only when Section B or a later owner decision proves it is necessary;
3. dynamic text, prices, timers, counts, ranks, progress, rewards and states stay live in Godot;
4. full-screen AI mockups are visual masters/references, not flattened shipping UI;
5. owner visual approval is required before a master is treated as production authority.

## D. External-reference rule

External-game screenshots are not project assets and are not canonical visual references.

In particular:
- Colony Flow screenshots supplied in chat must **not** be committed to this repository;
- they must not be added to `assets/art/references/`;
- they must not be cited as canonical project authority.

A repository search performed when this inventory was authored found no Colony Flow-named content in the repository.

## Snapshot conclusion

- **33** required surface masters/references remain visually unapproved.
- **30** of those can currently be designed using already-existing ScrubBots production assets and native Godot UI, without a new standalone illustration batch.
- **3 net-new art families** are currently justified:
  1. Achievements iconography after definitions;
  2. Events reusable art family / approved event hero art;
  3. future shipping-world backgrounds after world definitions.

Anything else should **not** be generated merely “just in case.”
