# M40-C001 V01 — ChatGPT Audit Criteria

Milestone: `M40 — Save System`
Tasks: `SB-M40-001..SB-M40-013`

Authority:
- root `TASKS.md`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- accepted/current M33 audio settings, M34 haptics, M37 progression, M38 streak, M39 economy service contracts

M40 is CRITICAL/STATEFUL. Claude implementation/tests are E1/E2 only. Final closure requires later ChatGPT full-surface/adversarial audit.

## Governance
Claude must not edit root `TASKS.md`.
Every task gets a separate durable GitHub log:
`coordination/sessions/M40-C001/task_logs/<TASK_ID>.md`
plus canonical:
`coordination/sessions/M40-C001/CLAUDE_LOG_V01.md`.

## SB-M40-001 Versioned schema
One canonical save schema with explicit schema ID/version.
Unknown future schema versions fail closed without destructive downgrade.
Every migration is explicit and deterministic.
Runtime services remain state authorities; SaveSystem serializes/imports through narrow snapshot APIs rather than exposing mutable internals.

## SB-M40-002 Settings
Persist settings required by implemented systems, including existing audio Master/Music/SFX, M34 haptics toggle if implemented, and reduced-effects/runtime settings where currently authorized.
Do not create competing settings authorities.
If M33 legacy `user://audio_settings.cfg` exists, define a deterministic one-time migration/compatibility path or keep it as a clearly separated canonical settings domain. Never have two files silently overwrite the same setting in conflicting directions.
M41 owns settings UI, not M40.

## SB-M40-003 Progression
Persist M37 current progression frontier, first-clear/completed level identity set, and replay-safe completion truth.
Duplicate import/load cannot advance progression.

## SB-M40-004 Win streak
Persist M38 active streak plus the transaction/idempotency state necessary to prevent duplicate streak rewards after relaunch.

## SB-M40-005 Economy V1
Persist at minimum:
- scrub_bucks
- hearts_current
- heart regen anchor/next timestamp
- bot_parts
- unlocked_robot_ids
- active_robot_id
- first-clear progression flags
- win streak
- gift meter cycle progress/index
- milestone queued/claimed state
- Gift Bar queue
- owned card counts
- completed set/grant transaction IDs
- Master Collection transaction ID
- exactly four booster charge counts
- current-level 2x entitlement level ID
- timed 2x expiry
- Daily last-claim date/timestamp
- consecutive-login count/cycle position
- Daily task state/claims
- stable reward/spend/exchange transaction IDs needed for idempotency

No Stars, Event Points or profile-XP economic state.

## SB-M40-006 Safe write
Use a crash-resistant strategy: serialize/validate to a temporary file, flush/close, then atomically replace canonical save where platform API permits. Maintain a last-known-good backup or equivalent recovery strategy before destructive replacement.
A failed write must not corrupt the last valid save.
Never write directly over the only good copy before validation.

## SB-M40-007 Missing save
No save => deterministic new-player defaults exactly once, including 1000 SB and Scrubby unlocked. Merely loading repeatedly must not regrant initialization rewards.

## SB-M40-008 Corruption recovery
Malformed/truncated/wrong-type/checksum-or-structure-invalid save fails closed and recovers from last-known-good backup when possible. If no valid backup, enter explicit safe recovery/new-profile state according to documented policy. Never partially import corrupt data.

## SB-M40-009 Migration
Explicit migration chain between schema versions. Migrations are pure/deterministic where possible and run before state commit.
Future-version saves must not be silently rewritten as older versions.

## SB-M40-010 Round-trip
Save -> fresh service graph -> load must reproduce all canonical persisted state exactly, excluding intentionally derived/transient presentation state.

## SB-M40-011 Corrupt-file tests
Test truncated JSON/config, invalid types, missing required root keys, impossible negative balances/counts, bad timestamps, duplicate IDs, unknown schema, future schema, backup fallback, and partial temp-write failure.

## SB-M40-012 Old saves missing Economy V1
Migrate missing fields to safe owner-approved defaults without double-grant.
Never invent Stars/Event Points/profile-XP balances.
Preserve preexisting legitimate progression/settings when migrating.

## SB-M40-013 Wall-clock timestamps
Persist Heart regen and timed 2x timestamps defensively. Clock rollback, duplicate load, repeated resume and large forward jump must not duplicate rewards/refills or extend entitlement incorrectly.
Daily anti-rollback claim history must survive relaunch.

# Atomic import rule
Loading is a transaction:
1. read bytes
2. parse
3. schema/migration
4. validate full candidate snapshot
5. only then apply to live services
If any validation/application stage fails, live state must remain unchanged or be restored exactly.

# Snapshot validation
Reject:
- non-integer balances/counts where integers required
- negative balances/inventory
- hearts outside 0..5
- booster keys other than exactly four canonical boosters
- slot capacity persisted as a permanent >5 base state
- invalid robot/card IDs
- invalid duplicate transaction structures
- non-finite numbers
- impossible/future timestamps beyond documented safe handling
- removed Star/Event/XP economy fields as authoritative state

# Test isolation
All save tests use injected temporary/test paths and never modify the owner's real `user://` save/settings files.

# Adversarial matrix
Required:
- save twice
- load twice
- duplicate callback after load
- crash/failure before replace
- corrupt primary + valid backup
- corrupt primary + corrupt backup
- older schema migration
- future schema refusal
- missing Economy fields
- stale transaction replay after reload
- clock rollback
- large forward clock jump
- M37 current level + M38 streak + M39 wallet/cards/boosters round-trip
- manual 2x current-level entitlement across retry/relaunch
- timed 2x expiry across relaunch
- heart regen across relaunch
- Daily duplicate-claim resistance
- exact set/master completion transaction persistence

# Regression floor
- focused M40 tests
- all M37/M38/M39 state tests
- M33 audio settings persistence regression
- M34 haptics settings regression if present
- root suite
- `git diff --check`

# Successful implementation handoff
`AWAITING_AUDIT / M40-C001 V01 / CRITICAL_FULL_SURFACE_AUDIT_REQUIRED`