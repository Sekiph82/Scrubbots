# M38-C001 V03 — Claude Strict-Evidence Repair Log

Re-audit: `coordination/sessions/M38-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
(`CHANGES_REQUIRED / F-M38-REOPEN-001..002 / SB-M38-016 REOPENED`)
Prompt/criteria: `CHATGPT_PROMPT_V03.md` / `CHATGPT_AUDIT_CRITERIA_V03.md`

Scope: SB-M38-016 test-harness evidence only. Root `TASKS.md` untouched. No
audit verdict created. **Production M38 files changed: none** (`git diff` touches
only `tests/`). No M39/M40 production changes.

## Closure

| Finding | Status | Change | Evidence |
|---------|--------|--------|----------|
| F-M38-REOPEN-001 fake violates typed constructor | IMPLEMENTED | `tests/support/failing_reward_grant_service.gd` = true RewardGrantService subclass (real parent init with test wallet; grant/already_applied -> false; call counters). Old `_FakeReward` removed. | `_reward_failure_no_mutation`: 13 assertions incl. type check, call-through counters, applied=false/reward_failed, streak/SB/BP/Gift total+cycle unchanged, level not processed, healthy service still wins level 1, final-assertion sentinel |
| F-M38-REOPEN-002 aborted sub-test can PASS | IMPLEMENTED | `EXPECTED_CASES` ledger; `_complete(name)` only as each case's last line; `_done()` fails + exit 1 for any missing case; prints `cases completed N/M`. | `_ledger_sensitivity` (synthetic missing detected); live abort probe below |

## Pre-fix (unchanged test)
`SCRIPT ERROR: Invalid type in function 'new' in base 'GDScript'. The Object-derived class of argument 1 (RefCounted (_FakeReward)) is not a subclass of the expected argument class.` -> still `M38 V02 strict validation: PASS`, exit 0.

## Validation-first run (production unchanged)
`m38_v02_strict`: all 11 expected cases `[case complete]`, `M38 strict cases completed: 11/11`, 0 SCRIPT ERROR, PASS, exit 0. Reward-failure branch genuinely executed. **No production defect exposed.**

Live abort probe (temporary copy using a non-subclass fake, then deleted): SCRIPT ERROR -> `FAIL: sub-test did not complete (aborted?): reward_failure_no_mutation`, `10/11`, `FAIL (3)`, exit 1.

## Required regressions

| Suite | Exit | SCRIPT ERROR | Result |
|-------|------|--------------|--------|
| tests/m38_win_streak.gd | 0 | 0 | PASS |
| tests/m38_v02_strict.gd | 0 | 0 | PASS (11/11 cases) |
| tests/m39_v04_integration.gd | 0 | 0 | PASS |
| tests/m39_v04_tornado_inflight.gd | 0 | 0 | PASS |
| tests/m40_v04_bootstrap.gd | 0 | 0 | PASS |
| tests/run_tests.gd | 0 | 0 | 5336 checks, 0 failures |

`git diff --check` clean.

Handoff: `AWAITING_AUDIT / M38-C001 V03 / STRICT_EVIDENCE_REPAIRED`
