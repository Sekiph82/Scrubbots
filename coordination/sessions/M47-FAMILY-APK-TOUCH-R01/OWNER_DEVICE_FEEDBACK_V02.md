# M47-FAMILY-APK-TOUCH-R01 — Owner Multi-Device Family QA Feedback V02

Date: 2026-10-10
Repository: `Sekiph82/Scrubbots`
Status: **OWNER-OBSERVED ISSUES / NOT CODE-VERIFIED / OPEN**.
This document extends `OWNER_DEVICE_FEEDBACK_V01.md`. It is factual owner feedback, not a parallel task-status tracker. Root `TASKS.md` is the only live status tracker.

## Actual device matrix

| Device | Platform | Build provenance | Owner report |
| --- | --- | --- | --- |
| iPhone (owner's) | iOS | **First IPA tested**; exact run, version and source SHA not confirmed; NOT necessarily latest IPA | The Supply tap issue; Collection scroll-down catches/sticks; Rewarded Ads one claimable reward has no red `1` notification on its Home shortcut. |
| Samsung Flip | Android phone | First Family APK (confirmed family first-ten testing context; exact install hash on phone not independently read) | Installed/boots, Supply tap issue. Owner subsequently says the **same problems** occur on the Android devices. |
| Samsung Android tablet (owner calls it "Samsung iPad", daughter's tablet) | Android tablet | Family Android test, exact installed build SHA not independently read | Same mobile problems reported on this device as well. |

Owner's words: "collections daki scroll down takiliyor, benim iphone da da supply tek tikla secme sorunu ayni sekilde var. rewarded ads de claim edilecek bir tane hediye olmasina ragmen kenarinda kirmizi ile 1 yazmiyordu. simdilik bu kadar. iphone da da test ettim ama benim test ettigim ilk ipaydi." Then "kizimin adroidinde de denedim. ayni sikintilar orda da var. yani aslinda hem iphone hem de bir samsung flip ( android) bir de samsung ipad (android) deneme gerceklesmis oldu".

Interpretation: **Three actual physical devices, two platforms, three reported usability problems.** Do not inflate this into device-specific stack traces, exact OS versions or proof a newer build is affected. The broad "same problems" report is accepted as the owner's multi-device observation; only the iPhone message explicitly itemized all three individually.

## Owner-required behavior

1. **Supply → 5 slots:** A normal one-finger *tap* on a live front color batch must transfer exactly ONE complete FIFO batch via production input to the rightmost empty slot. No drag, hold, swipe toward the slots, or tapping a destination. The gesture must work reliably on iOS, Android phone and Android tablet. Input must not duplicate when the platform synthesizes mouse from touch. Only the front row is selectable. Acceptable rejection states (full slots, paused/modal/terminal/exhausted) remain atomic.
2. **Collection scroll:** A normal upward finger swipe inside the Collection list should smoothly move the content **down**, and reverse swipes should move up. Scrolling must neither snag on nested buttons/overlays nor freeze under art load/re-layout. All 15 album sets and Master row remain reachable, scroll offset persists when appropriate within the open popup, and taps on set/detail/Exchange remain responsive without accidental activation during a scroll. Check album and deeper scrollable collection/exchange surfaces, portrait phones and tablet.
3. **Rewarded Ads red badge:** The Home `REWARDED ADS` shortcut shows the existing rounded **red badge with digit 1** when exactly one currently claimable/actionable next sequential reward is available. Slot 1 `ready_free` counts; slots 2..5 `ready_ad` count only if a functioning provider is actually available. Never advertise a blocked/unavailable/pending/claimed/sequence-locked/rollback-locked reward; do not count future slots. Badge updates live when entering Home, after claims, provider-state changes and day rollover. Reuse existing `UiShortcutButton.set_badge`; no separate saved badge state.

## Known code observations requiring investigation, not prejudged causes

- The shipping Supply front input pairs `gui_input` press/release, creates `top_level` `HitArea` children and uses a 200 ms touch→emulated-mouse dedup. Investigate cross-platform capture/hit geometry, not drag implementation.
- The Collection album uses a `ScrollContainer` with `custom_minimum_size.y=1020` inside the shared `BasePopup`; investigate nested input propagation, clipping, fixed-height layout and frame timing.
- `HomeBadges.compute()` has no rewarded-ads key, and `HomeScreen` creates `RewardedAdsButton` but presently has no `set_badge()` call for it. Red badge behavior should reflect `RewardedDailyService.slot_state()`, not invent a grant or bypass sequential unlock. **Older R15 wording "No Home notification/badge is required" is superseded by this new explicit owner decision for Rewarded Ads ONLY.**

## Acceptance boundary

Three installed/booted devices are **owner-reported**, not independently inspected. Previously produced Android APK remains a valid limited export artifact, **not a playable-touch acceptance**. The first iPhone IPA is **historical**; do not misrepresent it as newly rebuilt. Source correction, focused/root tests, new platform builds and **physical owner retest** are required for closure.
