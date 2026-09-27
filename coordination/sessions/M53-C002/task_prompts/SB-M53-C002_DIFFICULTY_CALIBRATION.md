# SB-M53-C002 — DIFFICULTY V1 CALIBRATION / POLICY ROBUSTNESS

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M53-C001/CHATGPT_AUDIT_V01.md`
4. `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
5. `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
6. `data/config/difficulty_score_model_v1.json`
7. `data/config/level_progression_v1.json`
8. all M53-C001 analyzer/evidence/tests
9. M27 solver/proof and current production routing/access code

Do NOT edit root `TASKS.md`.

## Mission

Calibrate the difficulty measurement layer before any production level is changed.

The First 10 are a **holdout evaluation set**, not the calibration target.

Do NOT mutate:
- owner source PNGs;
- production LevelData;
- owner supply plans;
- catalog order;
- owner-locked EASY/EASY/MEDIUM/EASY/HARD/EASY/EASY/MEDIUM/EASY/VERY_HARD labels;
- `difficulty_score_model_v1.json`;
- `level_progression_v1.json`.

Do not force First 10 scores into target windows.

## A. Build an independent calibration corpus

Create deterministic QA-only fixtures under a dedicated tests/fixtures/difficulty_calibration path.

The corpus must deliberately isolate Difficulty V1 axes, including at minimum:

- FLOW/simple-access fixtures at multiple legal board sizes;
- COLOR complexity variants with matched geometry;
- ACCESSIBILITY scarcity variants with matched size/color count;
- UNLOCK-depth / fortress variants;
- ROUTE-complexity variants;
- BOTTLENECK variants;
- SLOT/COLOR-pressure variants;
- workload/session-load variants;
- paired fixtures where exactly one intended axis increases while others are held as constant as practical.

Fixtures are QA-only, never production catalog content.

Document expected ordinal relationships, not arbitrary target scores:
`easy-structure < harder-structure` for each controlled pair.

## B. Remove arbitrary solver-trace dependence from primary Challenge scoring

C001 showed 6–14 D points of solver-path vs owner-path variance.

The production score must not depend materially on DFS/tie-break choice.

Implement a candidate V2 analysis policy that is independent of the oracle trace for policy-dependent components.

Acceptable approach:
- keep oracle solver for solvability/provenance;
- define deterministic reference-policy family for decision-state metrics;
- include at least:
  1. balanced round-robin/neutral valid policy;
  2. productive-greedy policy;
  3. accessibility-aware policy;
  4. bounded stress policy for Frustration diagnostics only.

Primary Challenge B/S/A must use a documented robust aggregate of non-adversarial policies, e.g. median/trimmed mean, rather than one arbitrary oracle path.

Stress/adversarial policy must not inflate primary D; use it for Frustration/robustness evidence.

If you choose a different method, prove that changing solver search/tie-break does not materially change primary D.

## C. Calibration anchors

Do not fit normalization anchors to the First 10 target labels.

Derive candidate anchors from the independent calibration corpus / production envelope in a reproducible way.

For every candidate anchor:
- raw distribution;
- chosen statistic/rule;
- reason;
- version;
- sensitivity.

U/R/A operational normalization must be calibrated enough that controlled corpus pairs preserve intended ordinal difficulty.

W and C locked formulas remain as-is unless the audit discovers an implementation bug; do not change owner-locked weights.

## D. Candidate versioning

Do not overwrite C001 evidence.

Create a candidate analysis version, e.g.:
- `scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd`
- `data/config/level_difficulty_analysis_v2_candidate.json`

It is NOT production authority until owner adoption after ChatGPT audit.

Preserve V1 analyzer for provenance/reproducibility.

## E. Required validity tests

Candidate must prove:

1. deterministic rerun;
2. all W..S finite and bounded;
3. controlled calibration-pair ordinal relationships pass;
4. primary D is independent of oracle solver trace/tie-break;
5. policy spread is reported separately;
6. changing a valid non-adversarial reference policy does not move primary D more than a justified tight tolerance;
7. board size alone does not force class-like score behavior;
8. a compact fixture can be harder than a larger flow fixture;
9. color count alone does not determine D;
10. synthetic route/access changes move the intended R/A/U axes in the expected direction.

## F. First 10 as holdout only

After calibration is frozen, run candidate V2 on Levels 1–10.

Report:
- V1 Stage-A D;
- V2 candidate D;
- policy spread;
- target/delta/window;
- actual recovery gaps;
- Session Load;
- provisional Frustration;
- component vectors.

Do not alter V2 after viewing First 10 results.

If First 10 still misses targets, report it honestly. That would then be stronger evidence that content/targets need a later owner decision.

## G. Structured owner-playtest bridge

Create a simple owner rating sheet for Levels 1–10 with:
- perceived difficulty 1..7;
- fairness 1..7;
- boredom/engagement 1..7;
- attempt duration optional;
- intended class feel: easier / about right / harder.

Do not fabricate ratings. Leave it ready for owner input.

## H. Outputs

Create:

`coordination/sessions/M53-C002/evidence/calibration_corpus_v1.json`

`coordination/sessions/M53-C002/evidence/difficulty_v2_candidate_first10.json`

`coordination/sessions/M53-C002/DIFFICULTY_CALIBRATION_MATRIX_V01.md`

`coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATING_SHEET_V01.md`

`coordination/sessions/M53-C002/CLAUDE_LOG_V01.md`

## I. Regression

Run:
- new M53-C002 calibration tests;
- M53-C001 suite;
- M52 owner-plan suite;
- R01/R02 suites;
- M27/M29/M30/M36/M37 relevant suites;
- root tests;
- `git diff --check`.

No production gameplay behavior changes are authorized.

## Handoff

Commit/push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M53-C002 DIFFICULTY CALIBRATION`

Do not edit TASKS.md.
