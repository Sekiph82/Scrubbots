# OWNER HEART REGEN INTERVAL RULING V01

Date: 2026-09-27
Authority: OWNER
Status: OWNER-LOCKED / CANONICAL

## Ruling

**Option A is canonical: Heart regeneration interval = 900 real-world seconds = 15 minutes per Heart.**

Canonical Heart rules now are:

- maximum Hearts: 5;
- passive regeneration: **+1 Heart every 900 real-world seconds / 15 minutes**;
- wall-clock timing continues through menus, pause, background and app closure;
- +1 Heart purchase remains 500 Scrub Bucks;
- full refill remains 400 Scrub Bucks per missing Heart;
- clock-rollback safety remains required;
- Home Heart timer uses HeartService as authority;
- when full, the current V06 Home presentation may show the static 15:00 ready state.

## Supersession

This ruling resolves the conflict identified by M54-C001 audit finding `M54-C001-F01`.

For the Heart regeneration interval only, this ruling supersedes any earlier 30-minute / 1800-second statement, including:

- `coordination/OWNER_FAILURE_RECOVERY_AND_ACQUISITION_V01.md` §4;
- older Heart interval wording in `coordination/OWNER_ECONOMY_REWARDS_V01.md`;
- `data/config/player_experience_plan_v1.json` if it still says 30 minutes;
- `docs/MASTER_UI_SYSTEM.md` if it still says 30 minutes;
- stale tracker/task wording.

Historical owner decision files remain historical evidence and do not need destructive rewriting. Active configs/docs must reconcile to this ruling.

## Non-effects

This ruling does **not** change:

- the 30-minute paid 2x entitlement product;
- any 2x pricing/duration;
- Heart max;
- Heart purchase/refill prices;
- rewarded-ad policy;
- First 10 level content;
- difficulty/solution automation decisions.

## Current implementation state at ruling time

M54-C001 independent audit already verified:

- `data/config/economy_rewards_v1.json` has `hearts.regen_seconds = 900`;
- `HeartService` consumes the canonical config;
- `tests/m39b_hearts_speed.gd` validates 900-second regen, offline catch-up and clock rollback;
- current Home Heart presentation follows the 15-minute V06 rule.

Therefore the owner ruling selects the already-shipping/configured runtime value. No production Heart-behavior remediation is required for M54.

## Governance consequence

- `SB-M54-017` is resolved PASS at 900 seconds.
- M54-C001 First 10 regression gate is fully closed.
- Active nonhistorical planning docs/config that still say 30 minutes must be reconciled by the next Claude cycle.
- Proceed to M55 core Chaos / Long-Run QA under the 900-second Heart authority.
