# 15 - Player Experience and Meta UI Architecture

Status: PLANNING AUTHORITY
Date: 2026-09-26
Primary tracker: root `TASKS.md`

## 1. Goal

Provide one coherent UI/navigation architecture for all results, fail-recovery, economy acquisition, collection, robots, tasks/daily, live-ops and account surfaces.

Gameplay/economy services remain authoritative. UI only requests actions and renders snapshots/results.

## 2. Screen layers

Recommended presentation layers:

```text
AppRoot
  NavigationHost
    ScreenLayer
    HudLayer
    ModalLayer
    PlatformOverlayReturnLayer
```

Only the top modal owns modal input. Platform-native store/ad/sign-in UI may temporarily cover the app; callbacks return through bounded transaction state.

## 3. Navigation model

Stable route IDs should be data-driven and include:
- home
- gameplay
- results
- shop
- collection
- collection_set
- robots
- tasks
- daily
- gift_bar
- profile
- achievements
- events
- event_detail
- ranks
- settings

Popup IDs include:
- pause
- level_intro
- fail_retry
- life
- need_a_hand
- booster_acquire
- speed_acquire
- insufficient_sb
- reward
- confirm
- card_detail
- pack_open
- robot_unlock
- feature_unlock
- world_unlock
- error
- loading

## 4. Modal safety

- exactly one top modal receives input;
- background gameplay/Home action surfaces are disabled while modal is active;
- duplicate action buttons are disabled while transaction pending;
- back closes top modal first;
- focus loss/background cannot replay callbacks;
- stale external callbacks are rejected by transaction ID/session context.

## 5. Service boundaries

UI must call existing/new authorities rather than mutate state:
- EconomyWallet
- RewardGrantService
- HeartService
- BoosterInventory
- SpeedEntitlementService
- DailyService
- GiftMeterService
- CardsExchangeService
- CollectionInventory
- RobotUnlockService
- Progression/Save authorities
- future AdService
- future StoreService
- future Account/CloudSaveService
- future EventService / RankService

## 6. Visual production

Subsystem visual inventory: `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`.

Each production scene should be responsive Godot layout plus approved illustration assets. Dynamic labels, prices, quantities, timers, rank, progress and localized copy stay live.

## 7. External transaction abstraction

Future ad/store/account providers should be hidden behind adapters that return explicit states:
- READY
- PENDING
- SUCCEEDED
- CANCELLED
- FAILED
- UNAVAILABLE

UI never assumes success from a button tap.

## 8. Persistence

Persist only durable authoritative state and once-only presentation flags needed to avoid repeated tutorials/ceremonies. Do not persist transient open popup nodes.

## 9. Testing

Every surface must have:
- route/open/close test;
- authoritative data binding test;
- duplicate-tap test where transactional;
- background/resume test where external;
- responsive/localization/accessibility evidence;
- independent audit plus owner visual gate when material.
