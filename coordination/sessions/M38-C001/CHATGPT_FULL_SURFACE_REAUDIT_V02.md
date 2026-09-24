# M38-C001 — ChatGPT Full-Surface Re-Audit After V04 Regression Discovery

Date: 2026-09-25
Prior verdict: `AUDITED_PASS / M38 WIN STREAK CLOSED`
Current verdict: **CHANGES_REQUIRED / VALIDATION-EVIDENCE DEFECT / FINDING_SET_FROZEN**

Trigger:
M39/M40 V04 regression execution exposed a pre-existing runtime type error in
`tests/m38_v02_strict.gd::_reward_failure_no_mutation()`.

Observed implementation evidence from Claude:
`WinStreakService.new(fake, g)` raises:
`Invalid type in function 'new' ... argument 1 (_FakeReward) is not a subclass of the expected RewardGrantService`.

The script nevertheless continues and prints:
`M38 V02 strict validation: PASS`.

This means the claimed reward-failure/no-mutation scenario never ran.

## Pass A — implementation/state sweep

Production owner:
`scripts/economy/win_streak_service.gd`

Immediate dependencies:
- `RewardGrantService`
- `GiftMeterService`
- `EconomyWallet`

Immediate downstream:
- M39 `FirstClearTransaction`
- M39/M40 economy/save regressions

Public/stateful M38 surfaces rechecked:
- `streak_sb_for()`
- `process_first_clear_win()`
- `on_gameplay_started()`
- `on_progression_loss()`
- `on_restart()`
- `on_pre_action_exit()`
- `snapshot()/import_snapshot()`
- RewardGrant idempotent duplicate path
- GiftMeter streak-only feed path

No new production-code defect is established by static source review.
The existing WinStreak production implementation still contains the intended
reward-failure guard:
`if not granted_sb and not _reward.already_applied(sb_tx): return reward_failed`.

The missing fact is runtime validation of that branch with a type-valid failing
RewardGrantService collaborator.

## Pass B — evidence/test/policy sweep

### F-M38-REOPEN-001 — failing reward test double violates the typed constructor contract
`WinStreakService._init(reward: RewardGrantService, ...)` requires an actual
RewardGrantService instance/subclass.

The current local class:
`class _FakeReward:`
is an unrelated Object-derived test class.

Therefore the exact high-risk scenario mandated by V02 criteria:
"reward grant failure before any mutation"
has no valid runtime evidence.

### F-M38-REOPEN-002 — the strict suite can report PASS after a sub-test aborts
The suite's PASS decision is based only on `_fail`.

A runtime SCRIPT ERROR can abort one sub-test without incrementing `_fail`,
then later execution reaches `_done()` and exits 0.

The test harness has no expected-case completion ledger/sentinel.

This is a direct false-positive mechanism and invalidates the prior final M38
audit evidence for SB-M38-016.

## Sibling-failure search

Checked:
- other M38 strict cases use real RewardGrantService/GiftMeter/Wallet instances;
- no second M38 fake collaborator crosses a typed WinStreak constructor boundary;
- production WinStreak call sites use the real RewardGrantService graph;
- M39 FirstClearTransaction supplies the canonical EconomyServices streak service.

No sibling typed-fake mismatch was found in M38 source/test surface.

RewardGrantService's generic handler extension seam was reviewed. No additional
M38 production correction is authorized in this validation cycle because the
currently owner-locked WinStreak path supplies canonical integer rewards and a
real RewardGrantService. If the repaired test exposes a real production failure,
Claude must stop rather than patch production in this cycle.

## Interaction sweep

This evidence defect affects:
- M38 SB-M38-016;
- M39 V04 required M38 regression;
- M40 V04 required M38 regression.

It does NOT by itself prove M39/M40 implementation defects, but their final
AUDITED_PASS must wait for the repaired M38 strict suite.

## M38 task ledger

| Task | Status | Evidence |
|---|---|---|
| SB-M38-001 | PROVEN | streak state/source + V01/V02 tests |
| SB-M38-002 | PROVEN | first-clear-only call contract |
| SB-M38-003 | PROVEN | loss/restart/pre-action source + tests |
| SB-M38-004 | PROVISIONAL/DEPENDENT | normal RewardGrant path proven; failure branch runtime evidence repaired by V03 |
| SB-M38-005 | PROVEN | 1 -> 1 |
| SB-M38-006 | PROVEN | 2 -> 5 |
| SB-M38-007 | PROVEN | 3 -> 10 |
| SB-M38-008 | PROVEN | 4 -> 25 |
| SB-M38-009 | PROVEN | 5 -> 100 |
| SB-M38-010 | PROVEN | 6+ -> 100 |
| SB-M38-011 | PROVEN | duplicate/idempotent path |
| SB-M38-012 | PROVEN | snapshot/import |
| SB-M38-013 | PROVEN | GiftMeter source isolation |
| SB-M38-014 | PROVEN | Bot Part at multiples of 5 |
| SB-M38-015 | PROVEN | replay isolation |
| SB-M38-016 | **GAP** | strict suite false-positive can hide aborted sub-test |

Frozen finding set:
**F-M38-REOPEN-001..002**

Only SB-M38-016 is reopened now.
SB-M38-004 remains provisionally accepted unless repaired V03 runtime evidence
shows a real production defect.

Verdict string:
`CHANGES_REQUIRED / M38-C001 / F-M38-REOPEN-001..002 / SB-M38-016 REOPENED`
