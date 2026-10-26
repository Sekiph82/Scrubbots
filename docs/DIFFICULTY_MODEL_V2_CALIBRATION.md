# Difficulty score model v2: calibration and First 10 recompute (SB-M36-012)

Status: model v2 is the active model for NEW analysis (playtest default, Level Factory targeting signal). v1 and the M53-C002 candidate are unchanged and kept for provenance. Lane targets still come from `data/config/level_progression_v1.json`, which this job does not change.

Decision: the owner chose option B on 2026-10-26 (`docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md`). This resumes the deferred M53-C003 work from the frozen M53-C002 candidate, with the weights locked (CLAUDE.md 11.3).

Files:

- `data/config/difficulty_score_model_v2.json`: schema `scrubbots-difficulty-score-model/v2`, version 2. It has the v1 structure, the locked weights 0.10/0.15/0.20/0.20/0.15/0.10/0.10, and the same formula and vector order. Its `changes` array records every change from v1.
- `data/config/level_difficulty_analysis_v2.json` and `scripts/difficulty/level_difficulty_analyzer_v2.gd` are copies of the frozen candidate. They read the v2 score model. Definitions, policies, fixed parameters and anchors are unchanged.
- `scripts/difficulty/challenge_score_model_v1.gd` accepts the v2 schema only when it is given the v2 path explicitly. The default path and v1 behaviour are unchanged.
- `tools/difficulty_playtest.gd -- --model v1|v2` (default `v2`) writes the evidence file `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json`.
- Suite: `tests/m36_difficulty_v2.gd`.

Every number below is copied from `playtest_v2.json` (fresh solve and fresh six-policy measurement), `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json` (v1) and `coordination/sessions/M53-C002/evidence/difficulty_v2_candidate_first10.json` (candidate). Spearman values use average ranks for ties, with n = 10. The owner ratings are L1..L10 = 6,3,6,3,5,3,3,5,3,5 (`coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md`).

## 1. What changed from v1, and what did not

Each entry is recorded in `difficulty_score_model_v2.json` `changes` as component / before / after / reason:

| Component | v1 | v2 | Why |
|---|---|---|---|
| Policy | one oracle (solver) trace | mean over six non-oracle policies (RR, RR_REV, GREEDY, GREEDY_HI, ACCESS, ACCESS_HI); the solver only proves solvability | the solver's search order is not player behaviour |
| U | colour-agnostic peel, normalised by the 59x59 envelope depth 29 | colour-aware unlock waves with same-colour closure, corpus anchors | v1 U is pure board geometry (0.410 on every 32x32 board) |
| A | 1 - reachable/raw over all ACTIVE cells of a colour | demand-relative, 1 - sum min(reachable, need)/sum need, corpus anchors | v1 A saturates at 0.61..0.78 and is inverted on the corpus |
| B | all decision states, <= 2 productive fronts | only states with >= 2 legal fronts; low-choice also needs fewer productive than legal fronts | with 3 columns v1 low-choice was true in 65..100% of states |
| S | single-productive over all states; imbalance = front shortfall | single-colour term only over states that demand >= 2 colours; imbalance = remaining-work imbalance (docs/09 4.7) | v1 S scored interleaved single-colour EASY supplies high (rho -0.64 vs lane target) |
| R | oracle trace, Stage-A anchors | same measures over the ensemble, corpus anchors | v1 R was flat; the definition is unchanged |
| W, C | sqrt workload; count + entropy | unchanged | both behave as designed |

All of these changes come from the M53-C002 candidate. This job made no change beyond the candidate. Section 4 explains why: the corpus re-check found no defect that would justify one. No constant was tuned against the owner ratings. The ratings are only used for evaluation (section 3).

## 2. First 10 recompute

| L | Class | Lane target | v1 D | Candidate D | v2 D | W | C | A | U | B | R | S | v2 delta | v2 window |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | EASY | 20 | 46.0 | 42.4 | 42.4 | 0.000 | 0.373 | 0.628 | 0.406 | 0.699 | 0.085 | 0.477 | +22.4 | OUTSIDE_HARD_LIMIT |
| 2 | EASY | 22 | 45.0 | 22.1 | 22.1 | 0.414 | 0.404 | 0.266 | 0.270 | 0.010 | 0.069 | 0.032 | +0.1 | IN_DEFAULT_WINDOW |
| 3 | MEDIUM | 40 | 54.3 | 38.9 | 38.9 | 0.621 | 0.558 | 0.492 | 0.513 | 0.047 | 0.240 | 0.114 | -1.1 | IN_DEFAULT_WINDOW |
| 4 | EASY | 19 | 49.5 | 25.0 | 25.0 | 0.414 | 0.511 | 0.108 | 0.471 | 0.000 | 0.100 | 0.056 | +6.0 | OUTSIDE_HARD_LIMIT |
| 5 | HARD | 58 | 53.2 | 29.4 | 29.4 | 0.448 | 0.701 | 0.109 | 0.492 | 0.057 | 0.091 | 0.059 | -28.6 | OUTSIDE_HARD_LIMIT |
| 6 | EASY | 18 | 50.9 | 23.6 | 23.6 | 0.414 | 0.540 | 0.044 | 0.436 | 0.008 | 0.112 | 0.050 | +5.6 | OUTSIDE_HARD_LIMIT |
| 7 | EASY | 21 | 51.0 | 33.2 | 33.2 | 0.414 | 0.559 | 0.341 | 0.453 | 0.150 | 0.117 | 0.137 | +12.2 | OUTSIDE_HARD_LIMIT |
| 8 | MEDIUM | 42 | 47.4 | 28.7 | 28.7 | 0.414 | 0.631 | 0.141 | 0.467 | 0.033 | 0.210 | 0.032 | -13.3 | OUTSIDE_HARD_LIMIT |
| 9 | EASY | 19 | 50.8 | 37.1 | 37.1 | 0.414 | 0.541 | 0.408 | 0.530 | 0.152 | 0.261 | 0.125 | +18.1 | OUTSIDE_HARD_LIMIT |
| 10 | VERY_HARD | 76 | 51.5 | 46.7 | 46.7 | 0.414 | 0.778 | 0.453 | 0.967 | 0.030 | 0.109 | 0.098 | -29.3 | OUTSIDE_HARD_LIMIT |

v2 reproduces the candidate D on every level (largest difference 5e-14 D; vectors within 5e-16). This is expected: the definitions and anchors are the candidate's, and the fresh measurement is deterministic. The fresh run (solver + six policies + stress + diagnostics, 10 levels) took 1553 s on the owner PC.

Lane window status under v2: 2 of 10 levels are inside the default window (L2, L3) and 8 are outside the hard limit +/-5. Under v1, 0 of 10 were inside. L5 (HARD, -28.6) and L10 (VERY_HARD, -29.3) are far below their lanes.

U across the 10 levels (requirement: U must not be a pure function of board size). The seven full 32x32 rectangles score U 0.270, 0.471, 0.436, 0.453, 0.467, 0.530 and 0.967 (7 distinct values; p95 wave 1..4, mean wave 0.39..1.63). Under v1 every one of them scored 0.410.

Policy robustness: the tie-break and leave-one-out gate (+/-1.75 D) passes on 9 of 10 levels. It fails on L7 (max deviation 1.89).

## 3. Agreement with the owner and with the cadence

Spearman of D against the owner ratings:

| Scoring | rho vs owner | rho vs owner, without L1 | rho vs lane target |
|---|---:|---:|---:|
| v1 | +0.27 | +0.60 | +0.36 |
| Candidate (M53-C002) | +0.64 | +0.56 | +0.36 |
| v2 | +0.64 (+0.6448) | +0.56 | +0.36 |

Per component, v2 removes the inversions of v1 against the lane target: A goes from -0.57 to +0.28, B from -0.44 to +0.09 and S from -0.64 to -0.10. U goes from +0.41 to +0.38, C stays at +0.72 and R goes from +0.22 to -0.10. Against the owner ratings, A has the strongest v2 signal (+0.61).

Cadence class order (mean v2 D per class, slots 1..10):

- EASY 30.55 (L1, L2, L4, L6, L7, L9) < MEDIUM 33.81 (L3, L8): holds.
- MEDIUM 33.81 < HARD 29.37 (L5): fails.
- HARD 29.37 < VERY_HARD 46.72 (L10): holds.
- The cycle maximum is slot 10 (L10 46.7 > L1 42.4): holds. Under v1, L10 ranked 3rd.

Recovery guards (`recovery_checks` on v2 D; also in `playtest_v2.json` `recovery`):

| Guard | D from -> to | Drop | Design minimum | Result |
|---|---|---:|---:|---|
| L3 -> L4 | 38.9 -> 25.0 | 13.98 | 15 | fail |
| L5 -> L6 | 29.4 -> 23.6 | 5.80 | 20 | fail |
| L8 -> L9 | 28.7 -> 37.1 | -8.45 | 15 | fail |

The owner says all three recoveries feel right. v2 still fails all three. The L3 -> L4 drop (14.0) is close to its minimum; under v1 it was 4.8.

## 4. Corpus anchor derivation and re-check

The anchors were derived by rule from the independent 27-fixture QA corpus `tests/fixtures/difficulty_calibration/` (`tools/calibrate_difficulty_v2.gd --calibrate`, M53-C002). They were frozen before any First 10 file was read (`calibratedAnchors.firstTenRead` false, corpus manifest sha256 `13885bcf...b227f`). v2 copies them unchanged:

| Anchor | Value | Rule |
|---|---:|---|
| A_lo / A_hi | 0.0291 / 0.5874 | median of the FLOW_SIZE family / corpus maximum of primary A_raw |
| U_p95_hi / U_mean_hi | 4.0 / 1.5278 | corpus maximum of p95 / mean unlock wave |
| R_len_lo / R_len_hi | 0.7318 / 1.6558 | FLOW_SIZE median / corpus maximum of route length per diagonal |
| R_detour_lo / R_detour_hi | 1.2878 / 2.8803 | same for mean detour |
| R_turn_lo / R_turn_hi | 2.0625 / 4.6811 | same for mean turns |

Re-check of the definitions the spec asked about, on the committed corpus evidence (`coordination/sessions/M53-C002/evidence/calibration_corpus_v1.json`, `calibrationPass` true):

- **A:** the declared A pair holds (access_shafts3_24 A 0.527 > access_band3_24 0.079, and D 18.9 > 8.7). The three first-draft A hypotheses were withdrawn before the freeze, with recorded mechanical reasons. The corpus shows no inversion, so A is not changed.
- **B:** after the >= 2-legal-front rule, B does not saturate. Low-choice fraction is 0..0.16 on the corpus and 0..0.32 on L2..L10 (L1 0.70). With 3 columns, the extra condition "fewer productive than legal" already makes the threshold relative to the fronts available, so `lowChoiceThreshold` 2 can never bind on its own. The relative-threshold change is not made. The declared B pair holds (bottleneck_high_24 0.164 > bottleneck_low_24 0.000).
- **S:** S is no longer high on the EASY slots with interleaved single-colour supplies. L2/L4/L6 score 0.03..0.06 (v1: 0.31..0.58). The declared S pair holds (slot_high_24 0.045 > slot_low_24 0.010).
- **U:** the declared U pair holds (unlock_deep_24 0.954 > unlock_shallow_24 0.291). All five flow-size boards (20..48) score U 0, so U does not grow with size.
- **W, C, R:** all colour pairs, the route pair (route_maze_24 R 1.0 > route_straight_24 0.014) and both flow-size family checks (D spread 5.5 < 18, max D 17.3 < 40) pass. No defect, so no change.

## 5. Honest shortfall

- **No owner-agreement gain over the candidate.** Rank correlation is +0.6448, equal to the candidate and not above it. The diagnosis and the corpus justify no change beyond the candidate, and tuning against the owner ratings is not allowed. Without L1, v2 agrees slightly less with the owner (+0.56) than v1 (+0.60).
- **Cadence order is only partial.** The HARD slot (L5 29.4) scores below the MEDIUM mean (33.8), and below the EASY slots L1, L7 and L9. The cause: L5 has the second-highest C (0.701) but low A (0.109) and B (0.057), because most ensemble policies always find reachable work on it. The solver path scores L5 at 45.0 (ORACLE_DIAGNOSTIC), but the oracle trace is not allowed into D.
- **L7 and L9 still score above L8** (33.2 and 37.1 vs 28.7), driven by A (0.34, 0.41 vs 0.14) and B (0.15 vs 0.03). The owner rates L7 and L9 as 3 and L8 as 5. v2 cannot see what makes L8 feel harder.
- **All three recovery guards fail** (drops 14.0, 5.8 and -8.5 against minimums of 15, 20 and 15).
- **Lanes 58 and 76 stay out of reach.** L5 is at 29.4 against 58 and L10 at 46.7 against 76, both outside the +/-5 hard limit. On the corpus no fixture exceeds D 36.5, and on the shipped levels R and S contribute at most 2.6 and 4.8 points. The absolute lane scale (20/40/58/76) and the v2 D scale have never been jointly calibrated. That is the Option C2 lane rescale, filed as SB-M36-013, which needs a later owner decision because the lane bases are owner-locked (CLAUDE.md 11.2).
- **L7 fails the policy-robustness gate** (1.89 > 1.75 D).
- **L1** stays high (42.4 against 20). This is the known content finding, a black batch deep in supply column 1, and is kept as the separate Level 1 supply-order task, not a model issue.

## 6. Promotion (docs/11 section 13)

1. Versioned formulas and config: met (v2 files, v1 untouched; the suite checks the sha256 values against main).
2. Deterministic regression fixtures: met (corpus evidence, `tests/m36_difficulty_v2.gd`, `tests/m36_difficulty_v1.gd`).
3. Accepted levels re-analysed: met (all 10, fresh solve, all SOLVED).
4. Rank inversions inspected: met (section 3 and section 5).
5. Campaign cadence: partly met (section 3: HARD below the MEDIUM mean, all recovery guards fail).
6. Human calibration at least as good: met (+0.64 vs v1 +0.27).
7. No source data or art mutated: met (no `data/levels`, `assets` or `level_progression_v1.json` change).
8. Migration notes: this document and the `changes` array.
9. ChatGPT audit: replaced by factory peer review (CLAUDE.md 0D.4).

v2 is the active model for new analysis because the owner chose B and because v1 is inverted on A, B and S. Gate item 5 is only partly met. Lane acceptance therefore stays diagnostic, as it was under v1. It is not authority to change shipped content.
