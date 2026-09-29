# M28-C002-C003-R01 — CHATGPT AUDIT CRITERIA V01

Date: 2026-09-29
Auditor: ChatGPT

## Expected verdict if clean

`AUDITED_PASS / OWNER REPLAY LEVEL 2 -> LEVEL 3 REQUIRED`

## Blocking defect

The pre-remediation state is invalid if:

- timed remaining > 0 after a level transition;
- HUD/presentation says timed entitlement exists;
- live GameplaySpeedAuthority remains 1x.

## A. Root-cause correctness

PASS requires evidence that the implementation fixes the actual production lifecycle:

`AppState timed entitlement -> new ProductionGameplayHost -> live GameplaySpeedAuthority`.

A test-only direct `set_2x(true)` after launch without production wiring is FAIL.

## B. Cross-level continuity

PASS requires a real app-level test:

- timed purchase on Level 2;
- authoritative completion;
- Results -> Continue;
- Level 3;
- remaining time > 0;
- live runtime 2x immediately;
- no extra debit;
- no expiry reset/extension.

## C. Expiry correctness

PASS requires timed expiration to remove paid/manual timed 2x live effect when no other valid 2x authority applies.

Timer/UI expiration with runtime staying 2x is FAIL.

## D. Free auto-2x preservation

PASS requires the M23 supply-exhausted automatic 2x authority to survive timed expiry.

A generic "timer expired -> set 1x" that overrides free auto-2x is FAIL.

## E. Retry/new-attempt

PASS requires active timed entitlement not to be stranded at 1x by Retry/new-attempt reset.

## F. Manual switching

PASS requires active timed entitlement to retain free 1x <-> 2x switching without new SB charges.

## G. Current-level product non-regression

PASS requires:

- current-level entitlement stays scoped to its level;
- successful completion clears it;
- no cross-level leak is introduced for the 200 SB product.

## H. Clock/save non-regression

M55 anti-rollback/high-water and M40 persistence behavior must remain intact.

No gameplay-delta clock is allowed.

## I. UI/runtime agreement

For the same authoritative state, the audit must verify consistency among:

- timed remaining;
- runtime factor/is_2x;
- Gameplay V02 speed presentation.

## J. Regression

Required:
- focused remediation suite;
- previous M28 final gate;
- M29;
- M30;
- M39 relevant;
- M40;
- M43-C003;
- M52;
- M55;
- root suite;
- diff check.

Pre-existing M39 real-clock snapshot flake may remain non-blocking only if unchanged and independently attributable to the already documented deterministic-test defect.

## K. Owner gate

Technical PASS does not close SB-M28-C002-020.

After audit, owner must replay at least:

1. buy 60m timed 2x on Level 2;
2. finish Level 2;
3. Continue to Level 3;
4. verify Level 3 actually runs 2x while timer continues;
5. optionally toggle 1x/2x and verify no new charge.

Only owner PASS closes M28-C002.
