# M53-C002 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-27
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `e7865b493d66a726f5f86ebeeae2e3a6d67827eb`

## Verdict

**AUDITED_PASS / M53-C002 / OWNER DIFFICULTY CALIBRATION REVIEW REQUIRED**

Technical calibration work passes. The V2 candidate remains **candidate-only** and is not adopted as production difficulty authority until owner review.

## 1. Holdout discipline — PASS

Git history proves the calibration corpus/analyzer/config were frozen in commit `4bea41e` before the First 10 holdout evidence was added in `e7865b4`.

The holdout commit does not modify the frozen V2 config or candidate analyzer.

First 10 art, LevelData, supply plans, catalog order, class labels, locked Challenge weights and progression targets remain unchanged.

## 2. Independent corpus — PASS

The calibration corpus is QA-only and outside the production catalog.

It covers controlled W/C/A/U/B/R/S behavior and preserves withdrawn/failed hypotheses instead of silently deleting them.

All declared final ordinal relationships and structural sanity checks pass, including:
- controlled accessibility pair;
- unlock-depth pair;
- route pair;
- bottleneck pair;
- slot-pressure pair;
- compact-hard > large-flow;
- size-only and color-count-only guards.

The corpus was iteratively designed before freeze, which is acceptable because First 10 was not used for calibration.

## 3. Oracle/path dependence — PASS WITH REPORTED STRATEGY SPREAD

The canonical solvability solver no longer supplies the primary Challenge path.

Primary scoring uses six deterministic non-adversarial policies:
RR, RR_REV, GREEDY, GREEDY_HI, ACCESS, ACCESS_HI.

STRESS is excluded from primary D and is used only for Frustration/robustness diagnostics.

The primary aggregate is the component-wise **mean** across the six non-adversarial policies, giving equal weight to the three strategy families.

Tie-break / leave-one-out robustness is explicitly measured.

Calibration corpus max gated deviation is 1.51 D <= declared 1.75 D tolerance.

Whole-family strategy spread is reported separately rather than hidden.

## 4. Candidate normalization — PASS

A/U/R anchors are derived reproducibly from the independent calibration corpus and production envelope rules.

First 10 target labels are not used to fit anchors.

Anchor sensitivity ±20% preserves the declared calibration relationships.

V1 evidence remains intact and V2 is separately versioned/frozen.

## 5. Structural sanity — PASS

The candidate demonstrates:
- board size alone does not determine class-like difficulty;
- a compact 20x20 structural challenge can score above a 48x48 flow board;
- color count alone is not class identity;
- controlled A/U/R/B/S changes move the intended axes in the expected direction;
- W/C weights and TargetChallenge lanes remain the locked V1 values.

## 6. V2 operational deviations — OWNER ADOPTION REQUIRED

V2 intentionally changes two measurement contracts:

1. Accessibility A becomes demand-relative rather than V1 reachable/raw-color-area scarcity.
2. S imbalance is changed to avoid double-counting A.

The evidence supports why these changes were proposed, but they are still deviations from the locked V1 conceptual wording.

Therefore audit PASS does not silently adopt them.

Owner adoption, rejection or request for another candidate must be explicit.

## 7. Holdout result — HONESTLY REPORTED

After freeze, First 10 scores were measured once:

- L2 and L3 fit the current target window.
- L4/L6 are near but outside the hard limit.
- L1/L7/L9 are substantially harder than their EASY targets.
- L5/L8/L10 are substantially easier than their HARD/MEDIUM/VERY_HARD targets.
- L10 is now the highest D level of the ten.
- recovery guards still fail.

No content or target was changed after seeing these results.

This is valid holdout evidence, not a PASS verdict for First 10 difficulty fit.

## 8. Two owner-review warnings

### 8.1 Level 7 robustness

L7 reports gated robustness deviation 1.89 D, slightly above the declared 1.75 D threshold.

This is not hidden and does not invalidate the independent calibration corpus, but it means L7's production candidate score should be treated with caution until owner review / later calibration iteration.

### 8.2 Level 1 neutral-policy deadlock

Two of six non-adversarial round-robin policies deadlock on Level 1 around 25% progress.

This is a real player-choice failure path, not a solver false-LOST bug.

It does not mean Level 1 is unsolvable; canonical solver and owner gameplay still pass.

Because Level 1 is labeled EASY, this is an important owner fairness/difficulty review point.

The V2 primary aggregate currently includes partial metrics from those incomplete policies. This is acceptable for the candidate diagnostic stage only; before production adoption, owner review must decide whether neutral-policy failure belongs in Challenge, Frustration, content tuning, or a future V2.1 rule.

## 9. Documentation note

The header comment in `level_difficulty_analyzer_v2_candidate.gd` still says "median", while the frozen config and implementation use component-wise mean.

The executable behavior/config are consistent; this is a non-blocking documentation defect that must be corrected before any production adoption commit.

## 10. Regression — PASS

Committed evidence reports:
- M53-C002 suite: 214 checks PASS;
- M53-C001 suite: 315 checks PASS;
- M52 owner plans: 255 checks PASS, 9/9 production WON;
- R01/R02 PASS;
- relevant M27/M29/M30/M36/M37 PASS;
- root suite: 5323 checks ALL PASS;
- same 9 known engine ERROR lines;
- no production gameplay behavior changed;
- diff hygiene clean.

## 11. Next gate

Owner review is now required.

Use:
`coordination/sessions/M53-C002/OWNER_CALIBRATION_REVIEW_V01.md`
and the blank:
`coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATING_SHEET_V01.md`.

After owner ratings/review, ChatGPT will decide one of:
- adopt V2 candidate with versioned owner decision;
- request a V2.1 calibration refinement;
- tune specific First 10 content/supply;
- revise difficulty targets only if the owner explicitly chooses to change the progression model.

No production change is authorized before that decision.
