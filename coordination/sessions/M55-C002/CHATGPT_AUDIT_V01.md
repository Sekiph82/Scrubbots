# M55-C002 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-28
Auditor: ChatGPT controller
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `023a0fc7d1841307777477863ad73770cc591dc9`
Owner ruling: `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
Prompt: `coordination/sessions/M55-C002/task_prompts/SB-M55-C002_TIMED_2X_ANTI_ROLLBACK.md`
Builder evidence:
- `coordination/sessions/M55-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M55-C002/TIMED_2X_ANTI_ROLLBACK_MATRIX_V01.md`

## Verdict

**AUDITED_PASS / M55-C002 / TIMED 2X ANTI-ROLLBACK / M55 CORE CLOSED**

The owner-selected fail-closed policy is implemented correctly and narrowly.

## 1. Diff/scope

Compared `ec9d597` -> `023a0fc`.

Changed production scope:
- `scripts/economy/speed_entitlement_service.gd` only.

Supporting changes:
- focused C002 regression;
- one stronger assertion in M55 core chaos;
- matrix/log evidence.

No First 10 content, supply plan, owner click, difficulty, Heart or M43+ production surface changed.

## 2. Monotonic timed entitlement

PASS.

The service now keeps `_clock_high_water` and computes timed truth through `_effective_now()`, which is the non-decreasing max of the persisted high-water value and current non-negative wall time.

Independent source inspection confirms:
- `timed_seconds_remaining()` uses effective time;
- timed branch of `is_manual_2x_entitled()` uses effective time;
- `purchase_timed()` extends from `max(effective_now, timed_expiry)`;
- `snapshot()` persists `clock_high_water`.

Therefore, absent a new purchase:
- backward clock movement cannot increase remaining time;
- an expired entitlement cannot become valid again;
- the countdown resumes only after wall time passes the previous high-water point.

## 3. Persistence / migration

PASS.

`snapshot()` adds `clock_high_water` inside the existing `economy.speed` payload.

`import_snapshot()`:
- strictly validates a present guard with the existing integer-domain helper;
- rejects malformed present values before mutating state;
- accepts legacy snapshots where the guard is absent;
- preserves the legacy `timed_expiry`;
- initializes protection at the first upgraded import boundary from observable current wall time.

This matches the owner migration boundary: preserve representable legacy active entitlement state, do not invent pre-upgrade clock history, protect from that point onward.

No save-schema bump is required for this additive nested field because the canonical save validator already delegates economy validity to the service graph import.

## 4. Product/non-effect checks

PASS.

Unchanged:
- current-level 2x = 200 SB;
- timed 2x = 900/300, 1800/500, 3600/750;
- free M23 supply-exhausted auto-2x;
- Heart regen = 900 s;
- First 10 content and progression QA inputs.

The focused production-host test explicitly covers free auto-2x under a rolled-back clock.

## 5. Focused regression quality

PASS.

The new suite covers:
- active rollback;
- expired rollback;
- forward resumption;
- save/relaunch;
- background/foreground;
- legacy snapshot and real legacy save;
- malformed guard values and save fallback;
- purchase while rolled back;
- current-level/free-auto 2x non-effects;
- canonical product/Heart values.

The C001 chaos test's former observation is now a real owner-rule assertion.

Sensitivity evidence is strong: bypassing the high-water clamp produces 10 failures and reproduces the old revival/extension values; restoring it returns the focused suite to PASS.

## 6. Regression evidence

Builder reports:
- focused C002: 53 ok;
- M39/M40/M42/M52/M54/M55 relevant suites green;
- M55 core chaos: 129 ok;
- root: 5323 checks, ALL PASS;
- 0 FAIL, 0 SCRIPT ERROR;
- no new engine-error class;
- diff hygiene clean.

This controller independently verified the source/test contract and diff scope. Runtime counts are builder execution evidence; no contradictory repository evidence was found.

## Final

`AUDITED_PASS / M55-C002 / TIMED 2X ANTI-ROLLBACK / M55 CORE CLOSED`

The current-build M55 core gate is closed. Per owner sequencing, resume M43 Results / Player Experience work.
