# Economy Runtime Module

Canonical owner decision: `coordination/OWNER_ECONOMY_REWARDS_V01.md`  
Machine tuning: `data/config/economy_rewards_v1.json`

This directory is reserved for M39 Economy & Rewards V1 runtime services. Do not put authoritative balances inside UI Controls.

Planned modules:

- `economy_wallet.gd` — Scrub Bucks authoritative balance; atomic/idempotent grant/spend.
- `reward_grant_service.gd` — first-clear, streak, Gift Meter, Daily and Collection reward bundles.
- `heart_service.gd` — max-5 Hearts, 30-minute real-world regen, attempt consumption/refill.
- `gift_meter_service.gd` — Win-Streak-SB-only meter, milestones 10/50/250/500/1000, rollover, Gift Bar queue.
- `daily_service.gd` — consecutive-login streak, 5-day cycle and three daily tasks.
- `booster_inventory.gd` — exactly four charge counters: +1 Slot, Random, Selector, Tornado.
- `speed_entitlement_service.gd` — current-level and wall-clock timed 2x entitlements.
- `cards_exchange_service.gd` — protected-first-copy duplicate exchange to SB.

Every mutation must have a stable transaction ID and be safe against duplicate UI callbacks/save retries.

The M29 `GameplaySpeedAuthority` remains factor-only. This module owns manual 2x permission/payment, not cadence math.

Real-money monetization is NOT authorized here; M57 remains separate.
