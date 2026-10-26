# 11 — Level Difficulty Calibration, QA & Retention Validation V1

Status: **CANONICAL DESIGN V1 — 2026-09-12**
Depends on:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`

## 1. Purpose

The mathematical model is a prediction system. It must be continuously checked against actual gameplay feel. This document defines how SCRUBBOTS prevents the score model from becoming numerically elegant but boring, exhausting or unfair.

The central QA rule is:

> A level is not production-good merely because it is solvable and its scalar Challenge Score matches a target.

Production acceptance also requires Session Load, Frustration Risk, variety, mobile readability and human playtest evidence appropriate to the release stage.

## 2. Four validation layers

### Layer A — legality

Must be deterministic and binary:

- supported logical dimensions;
- valid LevelData;
- canonical C01..C16 only;
- 3..12 used logical colors under V1 unless explicitly versioned otherwise;
- local palette contains only used colors and is in ascending C-ID order;
- ACTIVE alpha 255;
- no unintended interpolation/semi-alpha;
- exact source/provenance requirements;
- no duplicate production ID;
- five-slot data valid;
- runtime/content schemas compatible.

Failure: reject.

### Layer B — puzzle truth

- canonical solvability verdict;
- no false targetability;
- no routing pathology;
- reference completion path where solver can prove one;
- explicit UNSOLVABLE vs INCONCLUSIVE;
- no hidden state desynchronization.

Proven UNSOLVABLE: reject.
Required-authority INCONCLUSIVE: quarantine/retry, never fake PASS.

### Layer C — difficulty/retention model

- Challenge Score target fit;
- challenge-vector fit/diversity;
- Session Load budget;
- Frustration Risk budget;
- novelty target;
- recent similarity;
- local cadence recovery/tension constraints.

Failure: reject for the requested campaign slot, but a legal/solvable level may be reusable in another slot if its measured envelope fits there.

### Layer D — human/mobile quality

- recognizable/readable artwork;
- clear slot choices;
- bot visibility;
- perceived fairness;
- attempt duration;
- boredom/repetition;
- real-device readability/performance;
- owner/design approval where required.

Failure: revise/resequence/reject.

## 3. Pre-telemetry calibration

External analytics are not required to build V1.

Use structured internal playtests with a local record containing:

```text
player/tester id alias
level id
model versions
attempt number
completed yes/no
attempt duration
progress at failure
number of retries
perceived difficulty 1..7
perceived fairness 1..7
engagement 1..7
boredom 1..7
visual readability 1..7
notes
```

No external transmission is implied.

## 4. Calibration dataset design

Do not calibrate only on naturally generated campaign levels. Build controlled contrasts.

Required comparison families:

- same dimensions, different accessibility;
- same dimensions, different color entropy;
- same challenge score, low vs high Session Load;
- same challenge score, different dominant challenge vector;
- compact HARD/VH vs larger EASY/MEDIUM;
- strong bottleneck vs broad-choice level;
- shallow vs deep unlock levels;
- short routes vs detour-heavy routes;
- visually similar but topology-different levels;
- topology-similar but artwork-different levels.

This lets us learn which metrics correlate with human difficulty rather than merely with generator structure.

## 5. Model-quality checks

For a calibration batch calculate at least:

- Spearman correlation between Challenge Score and perceived difficulty;
- class confusion matrix against tester rating buckets;
- mean absolute score/rating error after normalization;
- completion-rate monotonicity by score band;
- attempt-duration correlation with Session Load;
- retry/abandonment correlation with Frustration Risk;
- residual analysis by challenge profile.

A high overall correlation is insufficient if one profile is systematically mispredicted.

## 6. V1 clear-rate targets

Initial targets:

| Class | First-attempt completion target |
|---|---:|
| EASY | 85..95% |
| MEDIUM | 70..85% |
| HARD | 55..70% |
| VERY_HARD | 40..60% |

These are tuning hypotheses.

Red flags:

- EASY below ~75% repeatedly;
- VERY_HARD below ~25% without explicit evidence that players still find it fair/fun;
- recovery slots with similar failure rate to the peak before them;
- level-10 boss causing a large next-session drop;
- attempt time growing much faster than challenge score;
- retry count driven mainly by long late failures.

## 7. Frustration Budget

For every campaign position define a frustration ceiling.

Suggested initial relative ceilings:

```text
slot 1  EASY       low
slot 2  EASY       low
slot 3  MEDIUM     medium-low
slot 4  EASY       very low
slot 5  HARD       medium
slot 6  EASY       very low
slot 7  EASY       low
slot 8  MEDIUM     medium-low
slot 9  EASY       very low
slot 10 VERY_HARD  medium-high, never unbounded
```

A hard level may exceed an easy level's challenge budget, but it may not receive unlimited Session Load or late-failure cost.

SB-M36-015: these ceilings are mapped to per-slot Session Load budgets 22/26/36/40/48 (slots 4,6,9 / 1,2,7 / 3,8 / 5 / 10), labelled `PROXY`, in `data/config/frustration_analysis_v1.json`; F is computable offline as `PROVISIONAL_SIMULATED_HUMAN` (`docs/DIFFICULTY_FRUSTRATION_RISK_PROPOSAL_V1.md` section 8).

## 8. Attempt-duration budgets

Exact minutes must be calibrated from real play rather than hardcoded as eternal rules.

Before data exists, maintain relative rules:

- recovery slots should normally be shorter than the preceding peak;
- a larger board requires explicit Session Load justification;
- consecutive long attempts are strongly penalized;
- boss attempts may be longer than nearby levels but must not become a marathon by default;
- 49..59 logical dimensions require special load/readability review.

The model stores estimated seconds but labels them `PROXY` until calibrated.

SB-M36-015: the frustration analyzer reports `attemptSecondsProxy` (HUMAN_BR think time plus bot travel at 6 cells/s, median over attempts) and `sessionOverrun` against the per-slot budget, both `PROXY`.

## 9. Challenge-vector diversity QA

Campaign-level validation must check rolling windows.

Suggested V1 window rules:

- no dominant challenge profile more than 2 levels consecutively;
- no 3 consecutive levels with `W >= 0.75`;
- no peak + recovery pair where recovery has equal/higher B and U simultaneously;
- within any 10-level cycle, at least 3 distinct dominant challenge profiles where candidate pool permits;
- within any 20-level window, avoid near-duplicate topology/art signatures.

These are configurable campaign rules, not gameplay mechanics.

## 10. Novelty QA

Novelty is not random visual noise.

A candidate receives similarity scores against recent levels for:

- visual silhouette;
- palette set/histogram;
- dimensions/aspect;
- challenge vector;
- unlock/frontier signature;
- route signature;
- dominant profile.

The campaign sequencer may accept moderate visual similarity when puzzle profile changes substantially, or vice versa. Near-duplicate on both visual and structural dimensions should be rejected.

## 11. Recovery QA

Validate actual selected levels, not merely formula targets.

For the final measured Challenge Scores:

- level 4 < level 3 by a meaningful margin;
- level 6 < level 5 by a strong margin;
- level 9 < level 8 by a meaningful margin;
- next-cycle level 1 << prior level 10.

Also compare Session Load and Frustration Risk. A nominal EASY that scores lower but takes twice as long may fail as recovery content.

## 12. Progression QA

For the same cadence slot across distant cycles:

- score trend should rise early/mid campaign;
- rise should slow as progression saturates;
- class ordering should remain separated;
- no late-campaign EASY should become indistinguishable from same-cycle MEDIUM;
- no early VERY_HARD should accidentally be easier than same-cycle HARD from generator noise.

Regression examples must include at least levels:

```text
1, 10, 11, 100, 101, 110, 111, 300, 310, 311, 1000, 1001, 1010
```

## 13. Model-version promotion gate

A score-model version may replace the previous production version only when:

1. formulas/config are versioned;
2. deterministic regression fixtures pass;
3. representative accepted levels are re-analyzed;
4. rank inversions are inspected;
5. campaign cadence still passes;
6. human calibration improves or remains at least as good;
7. no source level data/artwork is silently mutated;
8. migration notes explain changed scores;
9. ChatGPT independent audit passes.

Do not edit coefficients in place under the same version.

Status of model v2 (SB-M36-012, owner decision B 2026-10-26): v2 is active for NEW analysis; v1 is preserved. Gate items 1, 2, 3, 4, 7 and 8 are met (`docs/DIFFICULTY_MODEL_V2_CALIBRATION.md`, suite `tests/m36_difficulty_v2.gd`). Item 6: the owner-rating rank correlation is +0.64, up from +0.27 on v1 and equal to the candidate. Item 5 is only partly met: the HARD slot scores below the MEDIUM mean and all three recovery guards miss. The doc lists this under "Honest shortfall". Item 9 is replaced by factory peer review (CLAUDE.md 0D.4).

Lane placement for v2 (SB-M36-013): `docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md` measures a 24-fixture anchor corpus (`tests/fixtures/difficulty_anchors/`, `tools/build_difficulty_anchors.gd`, `tools/measure_difficulty_anchors.gd -- --measure=<id>` / `-- --merge`) under a decision rule fixed before measurement. Outcome RESCALE: `data/config/level_progression_v2.json` (EASY 13.8, MEDIUM 30.9, HARD 43.8, VERY_HARD 49.6, scale 0.64); `level_progression_v1.json` unchanged. Suite: `tests/m36_anchor_calibration.gd`.

## 14. Later telemetry calibration

Only after explicit owner approval of analytics/privacy design.

Useful aggregated outcomes could include:

- first-attempt completion;
- attempts to completion;
- duration distribution;
- quit/return around a level;
- failure progress;
- replay rate;
- help/booster use if those systems later exist.

Use telemetry to calibrate, not to create manipulative individualized difficulty by default.

Dynamic per-player difficulty is **not authorized** by V1.

## 15. Ethical retention boundary

Retention means making the game consistently enjoyable, legible and rewarding to master.

V1 explicitly does not authorize:

- opaque difficulty spikes designed to sell retries;
- deliberate near-impossible walls;
- hidden dynamic difficulty that punishes success;
- forced monetization tied to failure;
- deceptive probability manipulation;
- unbounded session-length inflation.

Recovery, novelty and fair mastery are the intended retention tools.

## 16. QA report per production level

Every production level should eventually have a machine-readable report containing:

```text
levelId
source hash
level data hash
campaign level number
cadence slot/class
TargetChallenge
actual Challenge Score
tolerance error
W,C,A,U,B,R,S
Session Load
estimated attempt duration + calibration status
Frustration Risk
oracle solvability verdict
reference solution summary
novelty signature
recent similarity score
readability result
performance result
model versions
QA status
owner approval status where required
```

Current shipped-catalog run: `tools/difficulty_playtest.gd` writes the simulated per-level report `docs/DIFFICULTY_PLAYTEST_2026-10.md` (SB-M36-005). Since SB-M36-012 it defaults to `-- --model v2` (writes `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json`); `-- --model v1` reproduces the SB-M36-005 run.

## 17. Batch QA

A 100-level batch report must include:

- generated candidate count;
- rejection counts by reason;
- accepted pool count;
- selected campaign count;
- score error distribution;
- Session Load distribution;
- Frustration distribution;
- class counts matching cadence;
- challenge-vector diversity;
- novelty/similarity violations;
- recovery-rule violations;
- solver inconclusive rate;
- performance outliers.

High rejection rate is acceptable if deterministic, bounded and operationally affordable. Silent acceptance of bad-fit levels is not.

## 18. Release QA checkpoints

Before scaled content publication:

- at least one full 10-level cycle passes automated campaign validation;
- at least three cycles across different progression ages pass internal playtest;
- a late-cycle sample around 300/310/311 demonstrates progression + recovery correctly;
- mobile readability checked for representative compact/standard/large boards;
- score model and campaign config are immutable/versioned for that content release.

## 19. Success criterion

Difficulty V1 is trustworthy when it predicts relative challenge well enough that designers can request a target, the Factory can produce multiple candidates near it, and the final 10-level sequence feels like a deliberate rhythm rather than a random set of boards.
