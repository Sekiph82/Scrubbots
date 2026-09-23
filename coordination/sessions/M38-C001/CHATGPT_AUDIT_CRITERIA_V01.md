# M38-C001 V01 — ChatGPT Audit Criteria

Milestone: `M38 — Win Streak [OWNER-LOCKED ECONOMY V1]`
Tasks: `SB-M38-001..SB-M38-016`

Authority:
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `data/config/economy_rewards_v1.json`
- accepted M30 terminal/retry and M37 progression contracts
- root `TASKS.md`, `CLAUDE.md`, `coordination/AUDIT_POLICY.md`

## Governance
Claude does not edit root `TASKS.md`.
Every task requires a separate GitHub log:
`coordination/sessions/M38-C001/task_logs/<TASK_ID>.md`
plus canonical `CLAUDE_LOG_V01.md`.

## SB-M38-001 Streak state
One authoritative WinStreakService owns the active progression streak. State must be non-negative, snapshot/import safe, and not directly mutable by UI.

## SB-M38-002 Increment only on valid first-clear progression wins
Only an authenticated first-clear progression WON may increment streak. Replay wins, duplicate terminal callbacks, old-level callbacks, and non-progression wins do not increment.

## SB-M38-003 Reset semantics
Progression loss resets to 0.
Restart after real gameplay began resets to 0.
Pre-action exit does not reset.
Replay loss must not mutate progression streak unless owner law explicitly says otherwise; default is no progression-streak mutation from replay.

## SB-M38-004 RewardGrantService path
Exact streak SB mapping must be granted through `RewardGrantService`, never direct wallet mutation:
1 -> 1 SB
2 -> 5 SB
3 -> 10 SB
4 -> 25 SB
5+ -> 100 SB per win.
If the full M39 service does not yet exist, M38 may create the narrow canonical service foundation at the final M39 path/API; M39 must extend that same service rather than duplicate it.

## SB-M38-005..010 Mapping tests
Direct tests for 1,2,3,4,5,6+ and long streak values. Mapping is based on active streak AFTER increment.

## SB-M38-011 No duplicate grant
Stable transaction IDs must make repeated/reentrant callbacks idempotent. Duplicate first-clear or duplicate WON cannot double-grant SB, Bot Part, or Gift Meter progress.

## SB-M38-012 Persistence
M38 must expose a versioned deterministic state snapshot/import contract. Durable central file persistence is finalized by M40. If M38 also writes a temporary file, it must not create a competing save authority. The final overnight batch must ensure M40 persists M38 state.

## SB-M38-013 Gift Meter source isolation
Only streak-bonus SB amount is forwarded to `GiftMeterService`. Base first-clear SB, Daily, Gift rewards, exchange, refunds, or arbitrary wallet grants must not call this streak feed. M38 may create only the minimal canonical GiftMeterService seam needed for this, with full M39 behavior added later.

## SB-M38-014 Bot Part multiple-of-5
Grant exactly +1 Bot Part when the active streak reaches 5,10,15,..., once per threshold crossing. No grant at 0 or non-multiples; no duplicate on callback replay.

## SB-M38-015 Replay isolation
Replay must not advance streak, Gift Meter, streak Bot Parts, or first-clear economic state.

## SB-M38-016 Integration tests
Cover reset, replay, duplicate/reentry, stale callbacks, snapshot/import, progression transition, and reward idempotency.

## Critical adversarial matrix
- WON callback twice
- first-clear event twice
- retry/restart callback ordering
- loss after duplicate win
- stale old-level WON after advancing
- replay win/loss
- streak 4->5, 5->6, 9->10
- snapshot/import then duplicate transaction replay
- malformed negative/huge snapshot
- RewardGrantService failure must not partially advance streak economics
- GiftMeterService failure handling must be atomic/fail-closed with no double-spend/grant

## Cross-milestone dependency rule
M39 must reuse/extend any M38-created canonical reward/gift service foundations. Duplicate wallet/reward/gift authorities are a blocking defect.

## Regression floor
Focused M38, M37 progression, M30 completion/retry, root suite, `git diff --check`.

## Expected handoff
`AWAITING_AUDIT / M38-C001 V01 / DURABLE_SAVE_FINALIZED_BY_M40`