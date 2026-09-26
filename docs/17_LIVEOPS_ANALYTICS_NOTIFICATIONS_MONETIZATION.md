# 17 - LiveOps, Analytics, Notifications and Monetization Plan

Status: PLANNED / PROVIDER GATED
Date: 2026-09-26

## 1. Events

Events must reuse existing currencies/rewards unless a new owner decision adds more.

Required event states:
- upcoming;
- active;
- completed/claimable;
- claimed;
- ended;
- offline/unavailable.

No Event Points currency is authorized by current V1 rules.

## 2. Ranks

Ranks requires an owner-approved fair metric before implementation. The metric may not incorporate paid purchases, ad watching or premium multipliers as competitive power.

Required states:
- player placement;
- nearby ranks;
- top ranks;
- season/window label;
- loading/offline/empty;
- privacy-safe player identity.

## 3. Analytics

Analytics is for calibration:
- retention/funnel;
- level difficulty/frustration;
- assistance/booster effectiveness;
- economy health;
- collection/robot progression;
- navigation;
- ad/store reliability.

Analytics must not be required for offline gameplay and may not directly mutate game state.

## 4. Notifications

Candidate opt-in categories:
- Hearts ready/full;
- Daily available;
- Event ending;
- claimable approved reward.

Require per-category control, quiet-hours/local-time handling, safe deep links and privacy review.

## 5. Rewarded ads

Approved product direction:
- +1 Heart;
- one charge/use for each of the four canonical boosters;
- Need a Hand reuses the booster placements.

Frequency/cooldown/cap/provider remain owner/provider tuning.

## 6. Store / IAP

Future store may contain:
- Scrub Bucks packs;
- No Ads;
- other explicitly owner-approved non-random products.

No second premium currency and no paid random card pack are authorized by this plan.

## 7. Integrity

All external rewards/purchases are idempotent, receipt/callback verified where applicable, and recoverable after relaunch without duplicate fulfillment.
