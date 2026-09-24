# M38-C001 V03 — Strict Test-Harness Repair Criteria

Authority:
- CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- frozen F-M38-REOPEN-001..002
- original M38 V02 criteria

This is VALIDATION-FIRST.

Production WinStreak behavior must NOT be changed unless the repaired test
genuinely demonstrates a production defect.

## 1. Type-valid failing reward collaborator

The reward-failure test must pass an actual RewardGrantService subclass to
WinStreakService.

Preferred robust implementation:
- create a test helper script extending
  `res://scripts/economy/reward_grant_service.gd`;
- initialize the real parent with the test wallet;
- override `grant()` to return false;
- override `already_applied()` to return false;
- inherited `wallet()` must return the same wallet.

The test must directly assert the collaborator satisfies the expected
RewardGrantService type before constructing WinStreakService.

Do not weaken/remove the typed production constructor.

## 2. Reward-failure path must actually execute

Directly prove:
- result: applied=false, reason=reward_failed;
- streak unchanged;
- SB unchanged;
- Bot Parts unchanged;
- Gift Meter total/cycle unchanged;
- level is not marked processed, so a later healthy service can process it.

Record a sentinel/counter showing this exact case reached its final assertion.

## 3. Suite-level aborted-subtest detection

The strict suite must maintain an explicit expected sub-test set and completed
sub-test set.

A case is marked complete ONLY at the end of that sub-test after all intended
assertions execute.

Before printing PASS, the suite must:
- verify every expected case completed;
- increment failure / exit nonzero when any case is missing.

Add a pure sensitivity check for the completion-ledger logic:
a synthetic missing case must be detected as incomplete.

The actual final successful run must contain:
- no `SCRIPT ERROR`;
- no parser/runtime error;
- all expected sub-tests completed;
- exit code 0.

## 4. Validation-only stop rule

First run the repaired strict suite against unchanged production code.

If the repaired reward-failure assertions FAIL because WinStreakService has a
real defect:
- do NOT fix production in V03;
- log the exact failure;
- stop with
  `BLOCKED / M38 PRODUCTION_DEFECT_EXPOSED / NEW CHATGPT AUDIT REQUIRED`.

If it passes, production remains unchanged.

## 5. Required regressions

Run and record exact outputs/exit codes:
- `res://tests/m38_win_streak.gd`
- `res://tests/m38_v02_strict.gd`
- `res://tests/m39_v04_integration.gd`
- `res://tests/m39_v04_tornado_inflight.gd`
- `res://tests/m40_v04_bootstrap.gd`
- `res://tests/run_tests.gd`

Explicitly scan the M38 strict output for `SCRIPT ERROR`.
Aggregate root 5336/0 is not sufficient by itself.

## 6. Evidence

Create:
- `coordination/sessions/M38-C001/task_logs_v03/SB-M38-016.md`
- `coordination/sessions/M38-C001/CLAUDE_LOG_V03.md`

Log:
- pre-fix SCRIPT ERROR evidence;
- exact helper/test change;
- expected/completed case ledger;
- repaired reward-failure assertions;
- every required regression result;
- confirmation whether production M38 files changed.

Do not edit root TASKS.md.

Handoff on success:
`AWAITING_AUDIT / M38-C001 V03 / STRICT_EVIDENCE_REPAIRED`
