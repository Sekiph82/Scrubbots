# 170-billing-admob (SB-M57-014..016 + SB-M57-022)
Owner 2026-11-17: "dukkan ve reklam yerleri var ama gercek satin alma ve gercek reklam bagli degil ... bagla". Free tools only.
Read first: coordination/OWNER_ECONOMY_REWARDS_V01.md, data/config/economy_rewards_v1.json, scripts/economy/store_provider.gd, ad_provider.gd, ad_service.gd, StoreService, TASKS rows SB-M57-014..016 and SB-M57-022.
## Do
1. Android: Google Play Billing via the official free Godot plugin for Godot 4 (GodotGooglePlayBilling / godot-sdk-integrations) implementing store_provider.gd: query products, purchase, acknowledge/consume, restore (queryPurchases), pending purchases; StoreService grants stay idempotent, granted only after a verified purchase state.
2. iOS: StoreKit via a free Godot 4 iOS plugin (official godot-ios-plugins or equivalent maintained MIT plugin) implementing the same provider: products, purchase, restore, transaction finish.
3. Ads: Google AdMob via a free MIT Godot 4 plugin (e.g. poing-studios godot-admob) for Android + iOS implementing ad_provider.gd: rewarded + interstitial exactly at the existing placements (ad_service.gd), banner only if the economy doc has one; Google UMP consent before ads; iOS ATT prompt; use GOOGLE TEST app/unit IDs by default, real IDs injected from config/secrets later (owner item). No new ad placements, no reward changes.
4. Product IDs: take them from the existing shop catalog/economy config; produce a table (id, type consumable/non-consumable, price tier, what it grants) for creating them in Play Console / App Store Connect (owner/Claude later).
5. Export: plugins wired into the Android Gradle build and iOS export in the CI workflows; debug/apk_only and ios builds still succeed (run them on the branch). Editor/desktop/headless keep a mock provider so all suites stay green.
6. Tests: provider contract tests with the mock (purchase -> grant once, restore, cancel, pending, ad rewarded completion grants once, ad failure grants nothing); exact PASS lines; full CI list run locally.
## Must not
No real purchases, no live ad IDs committed, no reward/price changes, no new placements, no paid services.
