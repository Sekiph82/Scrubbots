# SB-M53-C003 — CHATGPT AUDIT CRITERIA

## Verdict purpose

Decide whether V2.1 is sufficiently aligned with Stage-B owner difficulty perception and robust enough to become a candidate for owner adoption.

## 1. No production content mutation

PASS requires no changes to First 10 art, LevelData, supply plans, catalog order or campaign classes.

## 2. Challenge semantics

Fairness and Engagement must not be inserted into Challenge Score.

Challenge remains W/C/A/U/B/R/S.

## 3. Diagnosis before fitting

C003 must preserve a written pre-change diagnosis of V2 mismatch for L1/L5/L7/L8/L9.

## 4. Anti-overfit

No level-ID conditions, per-level offsets or memorized lookup table.

Leave-one-level-out validation must show that owner-order/cadence relations generalize when each level is excluded from calibration.

Independent corpus relations must remain green.

## 5. Owner Stage-B alignment

At minimum:
- L1 remains outside the normal EASY cluster;
- L3 > L4;
- L5 > L6 meaningfully;
- L8 > L9;
- L10 is highest/boss-like;
- L5 > L7 and L9;
- L8 > L7 and L9;
- L2/L4/L6/L7/L9 remain the low cluster.

## 6. Robustness

Policy/tie-break sensitivity must not regress materially from C002.

Any holdout/cross-validation miss must be reported, not hidden.

## 7. L1 separation

C003 may diagnose and recommend L1 supply tuning but must not implement it.

## 8. Regression

Focused V2.1, C001/C002, M52, R01/R02, relevant historical and root suites pass with no new unexplained errors.

## Verdicts

If technically valid and owner-aligned:
`AUDITED_PASS / M53-C003 / OWNER V2.1 ADOPTION REVIEW + L1 TUNING NEXT`

If model still misses core owner cadence/order:
`CHANGES_REQUIRED / M53-C003`
