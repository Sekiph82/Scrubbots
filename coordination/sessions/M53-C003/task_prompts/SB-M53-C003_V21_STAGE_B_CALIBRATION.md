# SB-M53-C003 — V2.1 STAGE-B DIFFICULTY CALIBRATION REFINEMENT

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md`
4. `coordination/sessions/M53-C002/CHATGPT_STAGE_B_RECONCILIATION_V01.md`
5. `coordination/sessions/M53-C002/CHATGPT_AUDIT_V01.md`
6. M53-C001/C002 analyzer, configs, evidence and tests
7. `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
8. locked score/progression configs

Do NOT edit root `TASKS.md`.

## Mission

Refine the V2 candidate into a **V2.1 candidate** using the owner's Stage-B perceived-difficulty/class-feel/cadence evidence without overfitting the ten levels.

Do NOT change any production level art, LevelData, supply plan, catalog order or campaign class in this task.

Do NOT fit Fairness or Engagement into Challenge Score.

## Owner Stage-B truth to respect

Owner perceived difficulty:
`[6,3,6,3,5,3,3,5,3,5]`

Owner class feel:
- L1 = harder than intended EASY
- L2–L10 = about right

Owner cadence:
- L3→L4 recovery = yes
- L5→L6 strong recovery = yes
- L8→L9 recovery = yes
- L10 boss = yes

All ten completed first attempt.

## Required work

### A. Diagnose V2 mismatch

Explain component-level reasons for at least:
- L5 too close to EASY recovery levels;
- L7 too high and robustness miss;
- L8 too low relative to owner MEDIUM feel;
- L9 too high / inverted recovery;
- L1 high score and neutral-policy failure.

Do not change the model before producing this diagnosis.

### B. V2.1 candidate

Create a separately versioned V2.1 candidate analyzer/config.

Preserve:
- W/C/A/U/B/R/S conceptual decomposition;
- locked high-level Challenge weights unless a separate explicit owner decision would be required;
- production routing/access truth;
- solver as solvability authority only;
- independent corpus evidence.

You may refine operational definitions/normalization/reference-policy aggregation where the Stage-B evidence reveals a measurable defect, but every change must have an explicit causal reason and must be independently testable.

### C. Anti-overfit validation

The ten owner-rated levels are now Stage-B calibration evidence, so fitting is allowed, but exact memorization is not.

Require at minimum:
- leave-one-level-out validation across Levels 1–10;
- ordinal/cadence constraints rather than fitting exact 1..7 numbers;
- calibration corpus relations remain green;
- perturbation/sensitivity tests;
- no level-ID-specific special cases;
- no hardcoded per-level offsets;
- no content-derived lookup table.

### D. Required owner-alignment checks

V2.1 should at minimum reproduce these qualitative relations:

- L1 harder than normal EASY cluster.
- L2/L4/L6/L7/L9 form the low-difficulty cluster.
- L3 > L4.
- L5 > L6 by a clearly meaningful margin.
- L8 > L9.
- L10 is the cycle boss.
- L5 should not score below L7/L9.
- L8 should not score below L7/L9.

Do not force exact TargetChallenge values merely to pass these relations.

### E. L1 remains content-frozen

Do not fix Level 1 in this task.

Instead create a precise recommendation for the next isolated Level 1 supply-order remediation:
- identify the black batch/order issue;
- reproduce the neutral-policy deadlock;
- state the minimal supply-only correction candidates;
- do not commit them.

### F. Outputs

Create:
- `coordination/sessions/M53-C003/V21_STAGE_B_DIAGNOSIS_V01.md`
- `coordination/sessions/M53-C003/evidence/difficulty_v21_candidate_first10.json`
- `coordination/sessions/M53-C003/V21_OWNER_ALIGNMENT_MATRIX_V01.md`
- `coordination/sessions/M53-C003/L1_SUPPLY_TUNING_RECOMMENDATION_V01.md`
- `coordination/sessions/M53-C003/CLAUDE_LOG_V01.md`

Keep V1 and V2 evidence unchanged.

### G. Tests/regression

Run:
- new V2.1 focused tests;
- calibration corpus tests;
- leave-one-level-out / anti-overfit checks;
- M53-C001/C002 suites;
- M52 owner-plan suite;
- R01/R02;
- relevant M27/M29/M30/M36/M37;
- root suite;
- `git diff --check`.

No production gameplay/content change is authorized.

## Handoff

Commit/push all C003 work.

Finish with:

`AWAITING_CHATGPT_AUDIT / M53-C003 V2.1 STAGE-B CALIBRATION`

Do not edit TASKS.md.
