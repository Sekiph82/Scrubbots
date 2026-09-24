# M38-C001 V03 — Repair False-PASS Strict Test Evidence

Read first:
- coordination/sessions/M38-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V03.md
- coordination/sessions/M38-C001/CHATGPT_AUDIT_CRITERIA_V02.md
- coordination/AUDIT_INDEX.md

Scope: SB-M38-016 evidence repair only unless the corrected test exposes an
actual production defect.

## Required work

1. Fix `tests/m38_v02_strict.gd::_reward_failure_no_mutation` so the injected
failing reward object is a TRUE RewardGrantService subclass accepted by the
typed WinStreakService constructor.

Prefer a dedicated test helper extending the real RewardGrantService script.
Do not weaken production typing.

2. Make the suite fail closed if any named sub-test aborts before completing.
Use an expected/completed sub-test ledger and verify it before PASS.

3. Add a sensitivity check proving the completion-ledger detects a synthetic
missing case.

4. Run the repaired suite FIRST with production WinStreak code unchanged.

If the repaired case reveals a real production failure:
STOP. Do not patch production.
Write CLAUDE_LOG_V03.md with the failure and hand back:
`BLOCKED / M38 PRODUCTION_DEFECT_EXPOSED / NEW CHATGPT AUDIT REQUIRED`

5. If the repaired strict suite passes, run:
- m38_win_streak
- m38_v02_strict
- m39_v04_integration
- m39_v04_tornado_inflight
- m40_v04_bootstrap
- root run_tests

The m38_v02_strict output must contain NO SCRIPT ERROR and every expected
sub-test must be reported complete.

## Evidence

Create:
- task_logs_v03/SB-M38-016.md
- CLAUDE_LOG_V03.md

Commit test/evidence repair, push, verify remote.

Do not edit TASKS.md.
Do not self-audit.
Do not alter M39/M40 production unless this prompt explicitly says so.

Success handoff:
`AWAITING_AUDIT / M38-C001 V03 / STRICT_EVIDENCE_REPAIRED`
