# SB-M53-C002 — CHATGPT AUDIT CRITERIA

## Verdict purpose

Decide whether the candidate difficulty measurement is calibrated and robust enough to use for production-content decisions.

## 1. No content fitting

PASS requires:
- First 10 not used to choose calibration anchors;
- no owner art/LevelData/supply/catalog/class mutation;
- locked score weights and progression targets unchanged.

Any tuning directly to make First 10 hit windows = CHANGES_REQUIRED.

## 2. Independent corpus

Calibration corpus contains controlled axis-isolation pairs and expected ordinal relationships.

It must cover W/C/A/U/B/R/S meaningfully.

## 3. Policy robustness

Primary Challenge score cannot be a direct function of arbitrary oracle DFS/tie-break order.

Oracle remains solvability authority only.

Candidate must expose policy spread and use a documented non-adversarial aggregate or equivalent path-robust method.

A solver search-order change must not move primary D beyond the declared tight tolerance.

## 4. Normalization calibration

Candidate anchors are derived reproducibly from the independent corpus/envelope, not fitted to First 10 labels.

Sensitivity is documented.

## 5. Structural sanity

Controlled tests prove:
- intended harder fixture > paired easier fixture;
- board size alone does not determine class-like difficulty;
- compact-hard > larger-flow is possible;
- color count alone does not determine class;
- route/access/unlock changes move intended metrics.

## 6. Holdout discipline

First 10 is scored only after candidate config is frozen.

No post-hoc adjustment after viewing holdout results.

## 7. Owner bridge

Owner rating sheet exists and contains no fabricated owner values.

## 8. Regression

M53-C002 focused tests pass.
M53-C001/M52/R01/R02/relevant historical suites pass.
Root suite passes.
No production gameplay behavior changes.
No new SCRIPT ERROR/unexplained engine errors.
Diff clean.

## Verdicts

If calibration is technically valid:
`AUDITED_PASS / M53-C002 / OWNER DIFFICULTY CALIBRATION REVIEW REQUIRED`

If calibration implementation is invalid:
`CHANGES_REQUIRED / M53-C002`
