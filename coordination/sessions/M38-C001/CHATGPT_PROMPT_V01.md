# M38-C001 V01 — Win Streak Implementation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Tasks: `SB-M38-001..SB-M38-016`

Read:
- `CLAUDE.md`
- root `TASKS.md` read-only
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`
- `data/config/economy_rewards_v1.json`
- `coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- M30 completion/retry code
- M37 progression implementation produced in this batch

## Batch continuation
Implement/test/commit/push M38 and continue directly to M39.
Do not wait for ChatGPT. Do not edit root `TASKS.md`.
M38 can leave durable disk persistence to M40 only if it provides a complete versioned state snapshot/import contract and the final batch later wires it into M40.

## Implement
1. Create authoritative `WinStreakService`.
2. Increment only on valid first-clear progression wins.
3. Reset exactly on progression loss and restart-after-real-gameplay; not on pre-action exit.
4. Exact SB mapping: 1/5/10/25/100.
5. Grant through canonical `RewardGrantService`, not direct wallet mutation.
6. Feed only streak-bonus SB to canonical `GiftMeterService`.
7. Grant +1 Bot Part at active streak multiples of 5.
8. Replay must not advance any streak economy.
9. Use stable idempotent transaction IDs across duplicate/reentrant callbacks.
10. Provide versioned snapshot/import state for M40.
11. If `RewardGrantService` / `GiftMeterService` do not exist yet, create only the narrow canonical foundation at their final M39 paths. Do not create temporary duplicate services. M39 will extend them.
12. No UI mutation of balances/state.

## Mandatory per-task logs
Create one file for each SB-M38-001 through SB-M38-016 under:
`coordination/sessions/M38-C001/task_logs/`

Each task log must include:
- requirement
- exact production path/API
- changed files
- direct tests
- expected result/failure condition
- actual result/status
- transaction/idempotency notes where relevant
- dependency on M39/M40 if any
- commit evidence

Create canonical:
`coordination/sessions/M38-C001/CLAUDE_LOG_V01.md`
indexing all 16 task logs.

## Git
Preserve owner work. No destructive commands.
Commit implementation/tests before docs. Push M38 before M39.

Final M38 log handoff:
`AWAITING_AUDIT / M38-C001 V01 / DURABLE_SAVE_FINALIZED_BY_M40`

Then continue immediately to M39 through the overnight master pipeline.