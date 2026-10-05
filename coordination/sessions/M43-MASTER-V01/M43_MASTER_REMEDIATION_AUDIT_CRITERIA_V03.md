# M43 — MASTER REMEDIATION V03 AUDIT CRITERIA

## Governance
- [ ] Root TASKS.md untouched by Claude.
- [ ] Scope limited to V01 audit findings.
- [ ] Owner-local files/addons preserved.
- [ ] No blocked authority fabricated.

## SB-M43-155
- [ ] Both local and remote envelopes validated.
- [ ] Exact payload equality is the only unconditional equal case.
- [ ] revision/saved_at participate in conflict rules.
- [ ] same tx/progression + different wallet = conflict.
- [ ] same tx/progression + different Collection = conflict.
- [ ] same tx/progression + different robot/booster/Daily = conflict.
- [ ] safe descendant direction is tested.
- [ ] divergent histories conflict.
- [ ] no field merge of currencies/rewards.
- [ ] child log amended.

## R12-005 / R12-007
- [ ] now < last_sent suppresses proactive notification.
- [ ] rollback suppression survives reload.
- [ ] T+23h suppressed.
- [ ] T+24h eligible.
- [ ] quiet hours/category/priority regressions pass.
- [ ] explicit rollback test added.
- [ ] both child logs amended.

## 161 / 162
- [ ] compact audio family covers confirm/back/popup open/popup close/reward/pack/unlock/error-warning.
- [ ] no false success sound before authoritative success.
- [ ] haptic semantics include success/warning/pack Rare+/unlock.
- [ ] Haptics OFF respected live.
- [ ] Reduced Effects respected live.
- [ ] canonical ceremony kinds mapped correctly.
- [ ] Standard/Premium pack Rare+ hook is presentation-only/idempotent.
- [ ] no pack reroll/reorder/economy mutation.
- [ ] child logs amended.

## 167
- [ ] fatigue tests use real representative UI loops, not only direct repeated method calls.
- [ ] voices/haptics do not stack.
- [ ] refresh/reopen does not duplicate.
- [ ] route/popup close leaves no orphan feedback.
- [ ] child log amended.

## Status corrections
- [ ] R10-004 = BLOCKED_AWAITING_AUTHORITY.
- [ ] 151 = DEFERRED_DEPENDENCY.
- [ ] 165 = DEFERRED_DEPENDENCY.
- [ ] 166 = DEFERRED_DEPENDENCY.
- [ ] no owner reward/rank/provider value invented.
- [ ] master status table/counts corrected.

## Regression
- [ ] updated focused suites pass.
- [ ] affected pack/harness suites pass if touched.
- [ ] M39/M40 regressions pass.
- [ ] root suite passes.
- [ ] git diff --check clean.
- [ ] no unexplained runtime/script errors.

## Handoff
- [ ] M43_MASTER_REMEDIATION_CLAUDE_LOG_V03.md exists.
- [ ] final SHA reported.
- [ ] exact files/tests/status corrections reported.
- [ ] ends AWAITING_GPT_M43_MASTER_REMEDIATION_V03_AUDIT.
