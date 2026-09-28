# SCRUBBOTS — REQUIRED VISUAL GAPS V02

Date: 2026-09-28
Scope: **only visual masters / visual families that still have to be CREATED or COMPOSED.**
This is not a project-status tracker. Root `TASKS.md` remains authoritative.

## Inclusion rule

An item appears below only when:
1. it is required by the current V1 player-facing plan;
2. a usable ScrubBots-specific final/candidate master has not already been produced for that surface;
3. more visual-production work is still required.

Therefore this list does **not** include visuals that merely await owner approval.

## Already produced / referenced — NOT missing

Do not regenerate these merely to fill a checklist:

- Gameplay V02 six-master family — owner-approved.
- Home / World 01 — owner-approved.
- Victory / Results — owner-approved.
- Level Intro — reference + assets exist.
- Life — ScrubBots-specific owner reference exists at `assets/art/references/_owner_inbox/Additionals/life screens.png`.
- Need a Hand — ScrubBots-specific owner reference exists at `assets/art/references/_owner_inbox/Additionals/need a hand.png`.
- Pause popup — M43-C002 production candidate/evidence already exists; owner review only.
- Generic confirm — M43-C002 candidate exists.
- Generic reward/confirmation — M43-C002 candidate exists.
- Insufficient-SB / Shop handoff — M43-C002 candidate exists.
- Generic network/error/busy/loading/feedback — M43-C002 candidates exist.
- all four gameplay booster icons.
- Scrubby and the full 10-robot production families.
- all 135 Collection card images and rarity/state frames.
- common popup/button/currency/navigation/system icon families.

## A. Visual masters still to create / compose

Exactly **26** currently-required visual deliverables remain to be visually produced.

| # | Visual deliverable still to create | Milestone | Existing assets to reuse | New standalone image art required? |
|---:|---|---|---|---|
| 1 | **Fail / Retry popup master** | M43-C004 | failure/Heart/common popup assets | No |
| 2 | **Booster Acquire popup master** | M43-C003 | four final booster icons + popup/button frames | No |
| 3 | **2x Acquire popup master** | M43-C003 | existing 2x/shop/common popup assets | No |
| 4 | **Shop full-screen master** | M43-C006 | `assets/ui/final/shop/*` + HUD/currency family | No |
| 5 | **Collection Album master** | M43-C007 | 135 cards + rarity/state/panel assets | No |
| 6 | **Collection Set Detail master** | M43-C007 | set frame/navigation + cards | No |
| 7 | **Card Detail popup master** | M43-C007 | card art + rarity/common popup assets | No |
| 8 | **Cards Exchange master** | M43-C007 | `assets/ui/final/cards_exchange/*` + Collection cards | No |
| 9 | **Standard Pack Opening ceremony master** | M43-C005 | pack/card/reward assets | No |
| 10 | **Premium Pack Opening ceremony master** | M43-C005 | pack/card/reward assets | No |
| 11 | **Collection Set Complete ceremony master** | M43-C005 | completion emblem + rewards | No |
| 12 | **Master Collection Complete ceremony master** | M43-C005 | master emblem + rewards | No |
| 13 | **Robots Main screen master** | M43-C008 | 10-robot families + robot UI assets | No |
| 14 | **Locked Robot Detail master** | M43-C008 | silhouette/lock/detail/perk assets | No |
| 15 | **Robot Unlock ceremony master** | M43-C005/C008 | robot art + unlock glow/burst + Bot Parts | No |
| 16 | **Tasks screen master** | M43-C009 | common panels/progress/reward assets | No |
| 17 | **Daily screen/popup master + reward-state layout** | M43-C009 | complete Daily family | No |
| 18 | **Gift Bar master + milestone-card layout** | M43-C009 | Gift Meter/gift/reward/common assets | No |
| 19 | **Gift Meter milestone ceremony master** | M43-C005 | reward crate/gift/reward assets | No |
| 20 | **Profile screen master** | M43-C010 | robot portraits/profile/rank assets | No |
| 21 | **Achievements screen master** | M43-C010 | common frames; new icon family required after definitions lock | **Partly yes** |
| 22 | **Events Main screen master** | M43-C010 | Events nav + common assets; event family absent | **Yes** |
| 23 | **Event Detail / Reward master** | M43-C010 | reuse new event family + existing rewards | **Yes, same family** |
| 24 | **Ranks screen master** | M43-C010 | profile/rank/robot/common assets | No |
| 25 | **Comeback / Return Summary master** | M43-C011 | common status/reward/popup assets | No |
| 26 | **Feature Unlock / Tutorial Coachmark visual family** | M43-C005 / M44 | pointer/highlight/speech bubble/robot art | No mandatory new pose unless a real lesson requires it |

## B. Net-new standalone image art that is actually justified now

Only **two** new art families are proven necessary at the current state:

### B1. Achievements iconography
Create only after the shipping achievement definitions are locked:
- achievement badge/emblem treatment if existing common badges are insufficient;
- distinct readable icons for the actual shipping achievement definitions/categories.

Do not generate a speculative giant badge library.

### B2. Events reusable art family
Before Events can visually close:
- event-card family;
- event-detail/header family;
- active / ended / claimed / unavailable treatments;
- approved event hero/theme art only for real shipping events.

Reuse existing SB / Bot Parts / Card Pack / Booster rewards. Do not invent an event currency.

## C. Conditional visuals — NOT on the current creation list

These become required only after their governing owner/platform decision exists:

- additional world backgrounds beyond approved World 01;
- world-specific decorative hero art;
- account/cloud conflict/sign-in custom screens beyond platform-native UI;
- notification-permission education illustration;
- any extra tutorial character pose not proven necessary by a real lesson;
- Friends/social visuals (post-V1 / conditional).

Do not generate these in advance.

## D. Colony Flow rule

Colony Flow screenshots are **not** ScrubBots project assets or canonical references.

Repository code/text search at this revision finds no Colony Flow-named/text-matching project content.

The two Additionals references named above are ScrubBots-specific Life / Need-a-Hand mockups, not a reason to store external-game screenshots.

Do not commit the Colony Flow screenshots supplied in chat.

## Bottom line

- **26** visual masters/families still genuinely need visual-production work.
- **24** can be composed from assets ScrubBots already owns.
- **2** require net-new standalone art families now: Achievements + Events.
- Conditional future-world/account/notification/Friends art is explicitly excluded until its owner decision exists.
