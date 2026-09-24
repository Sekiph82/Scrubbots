# M37-C001 V03 — Forward-Only Progression Final Criteria

Authority:
- CHATGPT_AUDIT_V02.md frozen F-M37-V02-001..002
- coordination/OWNER_M37_LEVEL_SELECT_DECISION_V01.md

PASS requires:

1. Shipping first-clear acceptance is current-frontier-only.
   - level_number == current_level may become a new first-clear;
   - stale lower level fails;
   - future higher level fails;
   - duplicate fails;
   - replay fails/non-advancing.

2. Failed stale/future/replay calls leave exact state unchanged.

3. Canonical shipping snapshot coherence:
   - current_level >= 1;
   - completed set contains exact positive unique ints;
   - completed set is exactly the contiguous range 1..current_level-1.
   Examples that MUST fail:
   - current=2, completed=[99]
   - current=10, completed=[1,3,9]
   - current=1, completed=[1]
   - current=4, completed=[1,2] (gap)
   - current=4, completed=[1,2,3,99]

4. Valid canonical imports remain all-or-nothing.

5. debug_set_current_level remains explicitly non-shipping.
   - no player-facing Level Select;
   - no shipping code path uses it;
   - synthetic debug states do not weaken persisted shipping validation.

6. Boundary cadence/target behavior remains unchanged.

7. Add sensitivity tests proving that re-enabling future-level record_win would fail the V03 suite for the intended reason.

Regression:
- M35 V02
- M36 V02
- M37 V02/V03
- M38 V02
- root suite
- git diff --check

Handoff:
`AWAITING_AUDIT / M37-C001 V03 / FORWARD_ONLY_REMEDIATION_COMPLETE`
