# SB-M43-R15-001-R01 — Sequential Unlock Strict Audit Criteria V01

Date: 2026-10-08
Repository: `Sekiph82/Scrubbots`

## Verdict gate

PASS only if all items below are satisfied.

### Scope / governance
- [ ] Owner-local checkout was synchronized non-destructively from current `origin/main`.
- [ ] Root `TASKS.md` was not edited by Claude.
- [ ] No Remote Content / R2 / Level Factory code or config changed.
- [ ] No unrelated M43 surface was redesigned.

### Sequential authority
- [ ] Fresh local day exposes only Slot 1 as actionable.
- [ ] Slot 1 successful direct grant unlocks only Slot 2.
- [ ] Slot 2 verified grant unlocks only Slot 3.
- [ ] Slot 3 verified grant unlocks only Slot 4.
- [ ] Slot 4 verified grant unlocks only Slot 5.
- [ ] Slot 5 verified grant completes the track.
- [ ] Future-slot service/facade/UI bypass attempts fail closed before provider request.
- [ ] Pending current slot keeps all future slots locked.
- [ ] No-grant outcomes do not advance.
- [ ] Duplicate/late callbacks cannot double-advance.
- [ ] Relaunch reconstructs the exact sequential position from durable canonical truth.
- [ ] Forward-day reset returns to Slot 1.
- [ ] Existing rollback/high-water protection remains fail-closed.

### Existing authority preserved
- [ ] Exactly five slots remain.
- [ ] Reward bundles and deterministic `daily_rewarded:<day>:<slot>` identities are unchanged.
- [ ] Provider token is not the economy idempotency key.
- [ ] Production provider remains honestly unavailable until M57.
- [ ] Existing Heart/booster rewarded paths are unchanged.
- [ ] Daily login, Daily Scrub Orders, Gift Meter, Hearts, boosters and 2x are unchanged.
- [ ] No Home badge added.
- [ ] Current Home CTA and R15-004 accepted placement are unchanged.

### Tests
- [ ] Focused R01 sequence tests PASS.
- [ ] Existing R15 tests PASS.
- [ ] M39 Daily regression PASS.
- [ ] M40 save regression PASS.
- [ ] M43 acquisition / Need a Hand regressions PASS.
- [ ] Root suite ALL PASS.
- [ ] `git diff --check` clean.
- [ ] No unexplained script errors.

### Handoff
- [ ] Claude log exists at `coordination/sessions/M43-OWNER-R15/SB-M43-R15-001-R01_CLAUDE_LOG_V01.md`.
- [ ] Log ends `AWAITING_GPT_SB_M43_R15_001_R01_AUDIT`.
- [ ] Original R15-001 owner visual gate is not falsely closed by this functional remediation.

Final result must be either `PASS / CLOSED` or `CHANGES_REQUIRED` with a narrowly scoped remediation.
