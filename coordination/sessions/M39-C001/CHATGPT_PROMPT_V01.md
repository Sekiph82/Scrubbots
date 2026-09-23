# M39-C001 V01 — Economy & Rewards V1 Master Implementation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: all 55 M39 task IDs from `SB-M39-001` through `SB-M39-052`, including `SB-M39-047A/B/C`.

Read before editing:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `data/config/economy_rewards_v1.json`
- `coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- M23/M24/M25/M26/M27/M29/M30 source/tests
- M37 progression + M38 streak implementations/logs produced earlier in this batch

## Overnight batch rule
M39 is critical and will NOT be self-audited/closed by Claude.
Nevertheless, owner explicitly authorizes uninterrupted implementation through M40.
After M39 code/tests/task logs/canonical log are committed and pushed, continue immediately to M40.
Do not edit root `TASKS.md`.

## Architecture
Implement explicit services at the canonical boundaries from the owner decision. Prefer:
- `scripts/economy/economy_wallet.gd`
- `scripts/economy/reward_grant_service.gd`
- `scripts/economy/heart_service.gd`
- `scripts/economy/gift_meter_service.gd`
- `scripts/economy/daily_service.gd`
- `scripts/economy/booster_inventory.gd`
- `scripts/economy/speed_entitlement_service.gd`
- `scripts/economy/cards_exchange_service.gd`
- `scripts/progression/robot_unlock_service.gd`
- `scripts/collection/collection_inventory.gd`

Reuse and extend M38-created RewardGrantService/GiftMeterService foundations. Do not create duplicate authorities.

UI may request/read actions but must not mutate wallet/inventory/progression truth directly.

## Implementation phases
### Phase A — Config + wallet + rewards + gift meter + robot parts/unlocks
Implement SB-M39-001..018.
Make transaction IDs stable and all multi-resource grants idempotent.
Integrate first-clear progression truth from M37/M38.
Run focused tests and commit this phase.

### Phase B — Hearts + 2x entitlements
Implement SB-M39-019..028.
Use injectable wall-clock source for deterministic tests.
Never use gameplay delta/Engine.time_scale for Hearts or timed entitlements.
Preserve free M23-exhausted automatic 2x.
Run tests and commit.

### Phase C — Four boosters + engine integration
Implement SB-M39-029..040.
Exactly four boosters.
Extend M24 capacity to authoritative 5/6 only.
Extend M27 solver/canonical state to include capacity.
Add sixth-slot presentation only as required for gameplay state.
Random/Selector/Tornado must be solver/state safe and atomic.
Tornado is a multi-system transaction: design rollback before mutation.
Add fault-injection tests at transaction stages.
Run relevant M23-M30 regression families and commit.

### Phase D — Daily + collection + packs + exchange
Implement SB-M39-041..051.
15x9 collection, protected first copy, exact rewards/totals, duplicate-safe completion transactions, deterministic test RNG seams, atomic exchange.
No Stars/Event Points/profile-XP economy state.
Run focused tests and commit.

### Phase E — Full M39 matrix
Implement SB-M39-052.
Run the entire direct/adversarial matrix from the criteria plus root suite.
Record exact commands and results.

## Mandatory per-task GitHub logging
Create **55 separate task logs** in:
`coordination/sessions/M39-C001/task_logs/`

One file per exact task ID, including 047A/B/C.

Every task log must contain:
- task ID/title
- implementation status
- canonical owner/service
- exact files/APIs changed
- state read/mutated
- direct tests
- expected outcome + explicit failure condition
- actual result
- rollback/idempotency/conservation notes where applicable
- dependency interactions
- commit SHA(s) and GitHub evidence URLs when available
- unresolved risk/blocker

Then create:
`coordination/sessions/M39-C001/CLAUDE_LOG_V01.md`

It must:
- link the M39 prompt + audit criteria
- list all implementation phase commits
- index all 55 task log URLs
- summarize full regression results
- explicitly say Claude did not edit root TASKS.md
- explicitly say no M39 audit verdict was self-assigned
- hand off as AWAITING_AUDIT

## Hard prohibitions
- no Star currency
- no Event Points
- no profile-XP economy
- no fifth booster
- no direct UI balance mutation
- no free shipping manual 2x without entitlement
- no gameplay-delta clock for Hearts/timed 2x
- no 7+ slots
- no solver bypass for boosters
- no silent partial transaction success
- no replay farming
- no duplicate service authorities

## Git discipline
Sync safely before starting M39. Preserve owner/untracked work.
Never reset --hard, clean -fd or force push.
Commit by phase, then commit logs/evidence.
Push all M39 commits before M40.

Final M39 log handoff:
`AWAITING_AUDIT / M39-C001 V01 / CRITICAL_FULL_SURFACE_AUDIT_REQUIRED`

Then continue immediately to M40 through the overnight master pipeline.