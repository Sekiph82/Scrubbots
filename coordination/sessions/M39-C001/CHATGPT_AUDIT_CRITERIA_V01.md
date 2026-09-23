# M39-C001 V01 — ChatGPT Audit Criteria

Milestone: `M39 — Economy & Rewards V1 [OWNER-LOCKED]`
Tasks: `SB-M39-001..SB-M39-052` including `047A/047B/047C`.

Canonical authority:
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `data/config/economy_rewards_v1.json`
- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- accepted M23/M24/M25/M26/M27/M29/M30/M37/M38 contracts

This is a CRITICAL/STATEFUL milestone. Claude implementation/tests are E1/E2 only. Final closure requires later ChatGPT full-surface/adversarial audit. During the owner-authorized overnight batch Claude may continue to M40 after pushing M39, but it must not self-close M39 or edit root `TASKS.md`.

## Mandatory per-task evidence
Every task gets a separate durable GitHub log:
`coordination/sessions/M39-C001/task_logs/<TASK_ID>.md`
for all 55 IDs.
Canonical:
`coordination/sessions/M39-C001/CLAUDE_LOG_V01.md`
must index every task log and every implementation commit.

Each task log records:
- exact requirement
- production owner/API
- canonical state mutated/read
- changed files
- direct test(s)
- expected outcome + explicit failure condition
- actual result
- rollback/idempotency notes
- dependencies
- commit/push evidence
- blockers/unverified assumptions

# A. Config, Wallet, Reward Transactions, Gift Meter, Robots
## SB-M39-001 Config
Load/version/validate Economy V1 config. Unknown/missing/malformed/out-of-range values fail closed. Do not silently substitute contradictory values.

## SB-M39-002 Wallet
One authoritative Scrub Bucks balance. Non-negative integer domain. UI never mutates balance directly.

## SB-M39-003 Atomic grant/spend
Stable transaction IDs. Duplicate transaction is idempotent. Spend checks sufficient funds before mutation. Partial failure leaves prior state unchanged.

## SB-M39-004 Initial 1000 SB
New player starts at exactly 1000 SB once. Reload/migration/reinitialization never grants again.

## SB-M39-005 First-clear SB
Only first-clear progression wins:
EASY 50 / MEDIUM 75 / HARD 100 / VERY_HARD 150.
Replay no farm.

## SB-M39-006 First-clear Bot Part
+1 Bot Part per first-clear progression level only. Replay/duplicate callbacks no farm.

## SB-M39-007 RewardGrantService
Canonical idempotent reward bundles. Duplicate callback protection and atomic all-or-nothing semantics where a bundle spans multiple resources.

## SB-M39-008 GiftMeterService
ONLY streak-bonus SB advances Gift Meter. Reuse/extend any M38 foundation; no duplicate service.

## SB-M39-009 Milestones
10/50/250/500/1000, exactly once per cycle.

## SB-M39-010 Rollover
One reward may cross multiple thresholds. 1000 rollover carries overflow deterministically.

## SB-M39-011 Gift Bar queue
Crossed rewards queue as claimable records. Do not silently auto-consume.

## SB-M39-012 Exact gift rewards
Implement owner-locked rewards and prove one full cycle totals 10 Bot Parts.

## SB-M39-013 1000 guaranteed-new card
Choose an eligible missing card from unlocked incomplete set. If none exists, fallback exactly 500 SB. No duplicate protected-first-copy corruption.

## SB-M39-014 No recursive Gift Meter
Base level/Daily/Tasks/Gift/Cards Exchange/refunds/purchases never feed Gift Meter.

## SB-M39-015 Robot unlock
Scrubby initially unlocked. Later robots cost exactly 250 Bot Parts. Overflow preserved. No negative parts.

## SB-M39-016 Set rewards + next-robot read model
Owner-locked per-set first 9/9 rewards exactly once, and read-only next-robot notification/progress seam.

## SB-M39-017 Pacing simulation
Provide deterministic simulation/evidence targeting approximately one robot unlock per 150 progression levels for average engaged play. This is evidence, not a hidden hard level gate.

## SB-M39-018 Perks boundary
Robot perks may affect meta/economy convenience only. Tests/sensitivity prove they cannot mutate solver/BoardState/TargetSelector/routing legality.

# B. Hearts and 2x Entitlements
## SB-M39-019 HeartService
Max 5. Regen exactly 1 per 1800 real-world seconds. Offline/menu/background/closed-app time counts. At full, anchor behavior deterministic.

## SB-M39-020 Heart loss
Progression loss or restart-after-real-gameplay consumes 1. Pre-action exit consumes 0. Replay behavior follows owner law and cannot farm/consume unexpectedly.

## SB-M39-021 Heart purchases
+1 Heart = 500 SB.
Full refill = 400 SB per missing Heart.
Atomic wallet spend + heart mutation, no charge on failure.

## SB-M39-022 SpeedEntitlementService
Separate from GameplaySpeedAuthority.

## SB-M39-023 Current-level 2x
200 SB. Bound to current progression level. Survives retries of same level until successful completion.

## SB-M39-024 Timed products
15m/300, 30m/500, 60m/750.

## SB-M39-025 Absolute wall clock
Timed 2x counts through gameplay/menu/pause/background/closed app. Never use gameplay delta or Engine.time_scale as entitlement clock.

## SB-M39-026 Extend expiry
Purchases extend from max(now,current_expiry) deterministically.

## SB-M39-027 Manual 2x gate
Shipping manual 2x requires valid level/timed entitlement or successful purchase flow.

## SB-M39-028 Free automatic endgame 2x
M23-exhausted automatic 2x remains free and entitlement-independent. No charge/refund/extension.

# C. Booster Inventory and Engine Extensions
## SB-M39-029 Booster inventory
Exactly four charge counters: +1 Slot, Random, Selector, Tornado. Charge-first, then SB if no charge. No fifth booster.

## SB-M39-030 +1 Slot
500 SB. At most once/attempt. Capacity 5->6 for current attempt only. New attempt returns to 5 unless activated again. Never 7+.

## SB-M39-031 M24 capacity
Authoritative slot engine supports capacity exactly 5 or 6. Baseline five-slot behavior/regressions remain unchanged.

## SB-M39-032 M27 solver
State encoding/canonicalization/deadlock logic includes active capacity and proves both 5 and 6.

## SB-M39-033 Sixth-slot presentation
Temporary sixth slot renders/updates/touches correctly with mobile safe-area evidence. No seventh slot.

## SB-M39-034 Random booster
350 SB. Reorders only REMAINING unselected M23 batches. Preserve batch identities/colors/counts/conservation.

## SB-M39-035 Random safety proof
Commit only if deterministic solver proves at least 3 consecutive legal non-deadlocking front selections. Failure consumes no charge/SB and makes no reorder.

## SB-M39-036 Selector
500 SB. Expose only solver-safe eligible remaining batches/colors.

## SB-M39-037 Selector atomic extraction
One arbitrary remaining supply batch can be atomically removed and placed into rightmost EMPTY slot. Full capacity/unsafe choice consumes nothing. No duplicate batch.

## SB-M39-038 Tornado choice
750 SB. Exactly one currently present color.

## SB-M39-039 Tornado atomic purge
Atomically clear all remaining ACTIVE cells of selected color and reconcile M23 supply, M24 slots, M25 claims/reservations, M26 in-flight agents/quotas, M27 solver state. No double clear, stale agent, ghost supply, orphan claim.

## SB-M39-040 Tornado rollback
Any failure rolls back all touched systems and consumes no charge/SB. Direct adversarial tests inject failures at multiple transaction stages.

# D. Daily, Collection, Packs, Exchange
## SB-M39-041 DailyService
Visible consecutive login count + repeating 5-day cycle.

## SB-M39-042 Login rewards
D1 100 SB
D2 Standard Pack
D3 random booster
D4 250 SB + Standard Pack
D5 300 SB + selected booster + Premium Pack

## SB-M39-043 Daily tasks
Exactly three tasks with 75/100/125 SB rewards and one random booster for completing all three. Claims exactly once.

## SB-M39-044 Calendar safety
Missing a local calendar day resets streak/cycle. Clock rollback never duplicates claims. Defensive monotonic claim record required.

## SB-M39-045 Collection inventory
15 sets x 9 cards. First copy protected. Owned counts non-negative. Completion state derived/validated.

## SB-M39-046 Packs
Standard = 3 eligible draws.
Premium = 5 eligible draws with >=1 Rare-or-better.
Duplicates allowed.
Deterministic injectable RNG for tests. Do not make production RNG test-only deterministic globally.

## SB-M39-047 Per-set rewards
Exact first 9/9 rewards:
S1 350/5, S2 400/5, S3 450/6, S4 500/7, S5 550/7,
S6 600/8, S7 700/9, S8 750/9, S9 800/10, S10 900/10,
S11 1000/11, S12 1100/12, S13 1250/13, S14 1500/15, S15 2500/20 (SB/Bot Parts), each once.

## SB-M39-047A Master Collection
When all 15 sets first reach 9/9: +2500 SB +20 Bot Parts exactly once, additional to Set 15.

## SB-M39-047B Totals
Direct arithmetic/integration proof:
15-set milestones = 13,350 SB +147 Bot Parts.
Including Master = 15,850 SB +167 Bot Parts.

## SB-M39-047C Transaction IDs
Persist stable per-set completion transaction IDs and Master transaction ID through snapshot state so relaunch/sync cannot duplicate.

## SB-M39-048 CardsExchangeService
Only copies above protected first copy are exchangeable.

## SB-M39-049 Values
Common 25 / Rare 75 / Epic 200 / Legendary 500 SB.

## SB-M39-050 Atomic exchange
Per-card and EXCHANGE ALL EXTRAS atomic. Never reduce owned count below 1. Duplicate callback/idempotency protected.

## SB-M39-051 Removed economies absent
Stars, Star Exchange, Event Points, profile-XP economic state must not exist in production runtime/save APIs. Decorative art labels do not count as state.

## SB-M39-052 Full regression matrix
Must exercise grants, spends, duplicate transactions, rollover, offline clocks, clock rollback, boosters, collection, exchange, first-clear/replay, 5/6 slot solver, tornado rollback, and idempotency.

# Mandatory adversarial audit classes
Applicable and required:
- malformed config/snapshot input
- min/max/overflow/negative balances
- duplicate/reentrant transaction
- stale level/attempt identity
- partial failure after earlier mutation
- rollback at every multi-service transaction boundary
- reset/retry during active work
- duplicate ownership/contention
- clock rollback/large forward jump
- exact-set postconditions, not count-only
- 5/6 capacity transitions
- no 7+ state
- supply/card conservation
- repeated relaunch/import snapshot
- removed-economy key injection
- deterministic RNG injection isolation

# Performance / scale
Do not invent phone FPS. Measure only subsystem costs actually timed. Economy services must remain bounded and should not iterate unbounded history on every frame. No per-frame economy polling where event-driven/state-query seams suffice.

# Regression floor
- focused M39 full matrix
- M38 streak
- M37 progression
- M29 speed
- M23 supply
- M24 slots
- M25 claims/reservations
- M26 agents/scheduler
- M27 solver/deadlock
- M30 terminal/retry
- root suite
- `git diff --check`

# Handoff
`AWAITING_AUDIT / M39-C001 V01 / CRITICAL_FULL_SURFACE_AUDIT_REQUIRED`

Claude must then continue to M40 under the owner-authorized batch without claiming M39 closure.