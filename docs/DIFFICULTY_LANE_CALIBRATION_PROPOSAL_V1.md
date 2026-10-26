# Difficulty V1 lane calibration proposal V1 (SB-M36-009)

Status: PROPOSAL ONLY. Nothing in `data/config/`, `data/levels/` or any script is changed by this document. Adopting any option below is a separate decision and a separate job.

Inputs (all numbers below are copied from or computed directly on these files):

- `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json` (SB-M36-005, fresh V1 run; report `docs/DIFFICULTY_PLAYTEST_2026-10.md`)
- `coordination/sessions/M53-C001/evidence/first10_difficulty_v1.json` (V1 raw sub-measurements per level, same trace hashes)
- `coordination/sessions/M53-C002/evidence/difficulty_v2_candidate_first10.json` and `DIFFICULTY_CALIBRATION_MATRIX_V01.md` (frozen V2 candidate measurement, never adopted)
- `coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATINGS_V01.md` (owner Stage-B ratings 2026-09-27) and `CHATGPT_STAGE_B_RECONCILIATION_V01.md`
- `data/config/difficulty_score_model_v1.json`, `data/config/level_difficulty_analysis_v1.json`, `data/config/level_progression_v1.json`
- CLAUDE.md section 11, `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`, docs/09, docs/10, docs/11 (section 13 promotion gate)

Rank correlations below are Spearman with average ranks for ties, n = 10 unless stated.

## 1. The problem

All 10 shipped levels miss their CLAUDE.md 11.2 lane target (k = 0, so targets are the base values). Measured V1 D spans only 45.0..54.3; targets span 18..76. EASY slots score 23..33 points too high, L10 VERY_HARD 24.5 too low. Only L5 is inside the +/-5 hard limit.

## 2. Diagnosis: why V1 D is compressed

### 2.1 Per-component picture (V1, the 10 shipped levels)

"Mean pts" = weight x mean value x 100, the average number of D points the component contributes. "Spread pts" = weight x (max - min) x 100, the most the component can separate two shipped levels. rho = Spearman against the lane target and against the owner perceived difficulty (1..7).

| Comp | Weight | Min | Max | Mean | Mean pts | Spread pts | rho vs lane target | rho vs owner rating |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| W | 0.10 | 0.000 | 0.621 | 0.397 | 4.0 | 6.2 | +0.41 | +0.16 |
| C | 0.15 | 0.373 | 0.778 | 0.559 | 8.4 | 6.1 | +0.72 | +0.21 |
| A | 0.20 | 0.613 | 0.779 | 0.690 | 13.8 | 3.3 | -0.57 | +0.13 |
| U | 0.20 | 0.284 | 0.461 | 0.402 | 8.0 | 3.5 | +0.41 | +0.16 |
| B | 0.15 | 0.438 | 0.639 | 0.482 | 7.2 | 3.0 | -0.44 | +0.20 |
| R | 0.10 | 0.290 | 0.371 | 0.336 | 3.4 | 0.8 | +0.22 | +0.09 |
| S | 0.10 | 0.304 | 0.653 | 0.517 | 5.2 | 3.5 | -0.64 | -0.09 |
| D | | 45.0 | 54.3 | 50.0 | | | +0.36 | +0.27 |

Reading: every level carries about 50 points of near-constant "floor"; the components that vary across levels contribute at most 3..6 points of separation each, and three of them (A, B, S) point the wrong way (EASY slots score higher). The one component that tracks the intended class well is C (rho +0.72), and it carries only 15% of the weight.

### 2.2 Cause by component

- **U Unlock Depth (20%) is board geometry, not puzzle.** V1 U is a colour-agnostic peel (`operationalDefinitions.U`). On a full rectangle with no VOID cells it depends only on the board size: all seven 32x32 levels have exactly p95 wave 12, mean wave 4.844, locked fraction 0.879, so U = 0.410 for every one of them (20x20: 0.284; 33x33: 0.412; 38x38: 0.461). Normalising by the 59x59 envelope peel depth (`unlockReferenceWave` 29) then turns size into 8.2 D points on every 32x32 board. Together with W (also pure size), every 32x32 level starts at 12.3 points before any puzzle content is measured.
- **A Accessibility Scarcity (20%) saturates at 0.61..0.78.** `1 - reachable/raw` over all ACTIVE cells of a colour measures how compact the colour regions are (interior cells of a filled pixel-art shape are never reachable at first), not whether the batches in play can find targets. Any filled artwork lands near 0.7, worth 13.8 points. M53-C002 already showed this ratio is ordinally inverted on a controlled corpus (comb/maze/mosaic score lower than halves/stripes), so no rescaling can repair it.
- **B Bottleneck Pressure (15%) saturates through the threshold.** `lowChoiceThreshold` is 2 and every shipped supply has 3 front columns (`columnCount` 3; L1 BatchSupplyGenerator 3 columns), so "<= 2 productive fronts" is true at 65..100% of decision states (lowChoiceFraction 0.649..1.0); forcedStreakNorm sits at 0.22..0.33 on every level. B is 0.44..0.48 on nine levels.
- **S Slot/Color Pressure (10%)** is driven by noWorkSlotFraction (0.08..0.90) and singleProductiveSlotFraction (0.57..0.85), which are high on the EASY levels (L1 0.895, L9 0.816) because their supplies interleave many single-colour batches; S is anti-correlated with intended class (rho -0.64).
- **R Route Complexity (10%)** is flat: length 0.36..0.41 of a diagonal, detour 1.31..1.46, turns 2.8..5.2 on every level; spread 0.8 points.
- **W and C** behave as designed (W compresses size; C follows colour count and entropy). C is the only component whose order matches the cadence (L1 0.373, L2 0.404 ... L5 0.701, L10 0.778).

### 2.3 The lane targets and the D scale were never jointly calibrated

`level_difficulty_analysis_v1.json` declares itself `STAGE_A_PROVISIONAL`: every anchor came from envelope geometry or runtime constants before any level was analysed. The lane bases (20/40/58/76) were set on a 0..100 scale that no measured content has been placed against. Two consequences:

- For a 32x32 board under V1 the reachable range is roughly 33..82: the floor is 12.3 (W+U geometry) + about 4 (minimum C) + about 17 (A ~0.6 and B ~0.45 for any filled art) and the ceiling is capped because U cannot rise above 0.41 on that size. EASY 18..22 is below the floor of every filled 20..38 board; VERY_HARD 76 needs C, A, B, R and S averaging about 0.91 together, while the highest R seen on shipped content is 0.371.
- The owner's own ratings agree with the intended order, not with V1 D: owner rating vs lane target rho = +0.55 (+0.79 without L1, which the owner rated "harder than EASY"), and all three recovery transitions and the L10 boss "feel right" to the owner. The content is closer to the design intent than the V1 score says.

Conclusion: the lane misses are a model-calibration defect (U and A measure geometry, B saturates, A/B/S invert), plus an uncalibrated absolute lane scale. They are not evidence that levels 2..10 are mis-built. L1 is the exception: both the owner (rating 6, "harder") and the V2 candidate (42.4 vs target 20) say it is too hard for slot 1; that is the already-known Level 1 supply-order finding (black batch deep in the first column), a content issue separate from calibration.

## 3. Options

### Option A: content-side (swap, re-sequence or regenerate to fit V1)

What it would take:

- **Re-sequence by V1 D**: put the highest V1 levels (L3 54.3, L5 53.2) in slots 5 and 10. This cannot fix any lane miss (the lowest shipped level is 45.0, above every EASY target and above MEDIUM 40), and it would reorder levels the owner already rated as class-appropriate with correct recoveries. L10, the level the owner accepted as the boss, would move to an EASY slot.
- **Generate new EASY content to V1 targets**: Level Factory requests for EASY D 18..22 under V1 need A+B+R+S worth about 4 points on 32x32 (about 10 on 20x20, where W and U are lowest) instead of the shipped 26..35, i.e. near-trivial stripe-like art with every colour touching the border. VERY_HARD 76 is not reachable on 32x32 at all, and on 59x59 only with every component near saturation.
- Owner-original artwork stays untouched in every variant (CLAUDE.md 12): this option can only swap, re-sequence or add generated candidates with lineage.

Consequences: shapes future art to a measurement already shown to be inverted on A, B and S; contradicts owner Stage-B evidence; changes shipped campaign order; large content cost. Does not touch the score model.

### Option B: score model v2 (new versioned files; v1 never edited)

Files a v2 would add (not created here): `data/config/difficulty_score_model_v2.json` (schema `scrubbots-difficulty-score-model/v2`, version 2) and `data/config/level_difficulty_analysis_v2.json`. Weights stay the owner-locked 10/15/20/20/15/10/10 (CLAUDE.md 11.3); only component definitions and normalizations change, and every analysed level stores its model version. Promotion follows docs/11 section 13 (re-analyse accepted levels, inspect rank inversions, cadence passes, human calibration not worse, migration notes); the section-13 ChatGPT-audit step is replaced by factory peer review under CLAUDE.md 0D.4.

**B1: pure re-normalization of the V1 measurements (worked recompute).** Keep every V1 definition, change only normalization:

- U: subtract the solid-rectangle peel baseline (U' = 0 for a full board with no VOID cells, because V1 U equals that baseline exactly). Every shipped level gets U' = 0.
- A, B, R, S: linear re-anchor x' = clamp((x - lo) / (hi - lo)). For this worked example lo/hi are the min/max over the 10 shipped levels: A 0.613..0.779, B 0.438..0.639, R 0.290..0.371, S 0.304..0.653. This is in-sample (fitted to the holdout) and is the most favourable anchor choice normalization alone can get; a real v2 must derive anchors from an independent corpus.
- W, C unchanged.

| L | Class | Target | V1 D | W | C | A' | U' | B' | R' | S' | B1 D | B1 delta | V2-cand D (measured, C002) | V2-cand delta |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | EASY | 20 | 46.0 | 0.00 | 0.37 | 1.00 | 0 | 1.00 | 0.19 | 1.00 | 52.5 | +32.5 | 42.4 | +22.4 |
| 2 | EASY | 22 | 45.0 | 0.41 | 0.40 | 0.50 | 0 | 0.06 | 0.00 | 0.01 | 21.2 | -0.8 | 22.1 | +0.1 |
| 3 | MEDIUM | 40 | 54.3 | 0.62 | 0.56 | 0.74 | 0 | 0.20 | 0.60 | 0.63 | 44.6 | +4.6 | 38.9 | -1.1 |
| 4 | EASY | 19 | 49.5 | 0.41 | 0.51 | 0.45 | 0 | 0.10 | 0.64 | 0.68 | 35.7 | +16.7 | 25.0 | +6.0 |
| 5 | HARD | 58 | 53.2 | 0.45 | 0.70 | 0.44 | 0 | 0.10 | 1.00 | 0.74 | 42.8 | -15.2 | 29.4 | -28.6 |
| 6 | EASY | 18 | 50.9 | 0.41 | 0.54 | 0.56 | 0 | 0.18 | 0.65 | 0.80 | 40.5 | +22.5 | 23.6 | +5.6 |
| 7 | EASY | 21 | 51.0 | 0.41 | 0.56 | 0.45 | 0 | 0.19 | 0.89 | 0.77 | 41.0 | +20.0 | 33.2 | +12.2 |
| 8 | MEDIUM | 42 | 47.4 | 0.41 | 0.63 | 0.00 | 0 | 0.00 | 1.00 | 0.00 | 23.6 | -18.4 | 28.7 | -13.3 |
| 9 | EASY | 19 | 50.8 | 0.41 | 0.54 | 0.49 | 0 | 0.22 | 0.14 | 0.91 | 35.8 | +16.8 | 37.2 | +18.2 |
| 10 | VERY_HARD | 76 | 51.5 | 0.41 | 0.78 | 0.00 | 0 | 0.13 | 0.50 | 0.55 | 28.3 | -47.7 | 46.7 | -29.3 |

Summary of the three scorings:

| Scoring | D range | Inside +/-3.5 | Max abs delta | rho vs lane target | rho vs owner rating |
|---|---|---:|---:|---:|---:|
| V1 (shipped) | 45.0..54.3 | 0/10 | 32.9 | +0.36 | +0.27 |
| B1 re-normalization (in-sample anchors) | 21.2..52.5 | 1/10 (L2) | 47.7 | -0.15 | +0.50 |
| V2 candidate (M53-C002, frozen corpus anchors) | 22.1..46.7 | 2/10 (L2, L3) | 29.3 | +0.36 | +0.64 |

B1 widens the range but makes the order worse: a monotone rescale keeps each component's order, so the inverted A, B and S now drive L8 and L10 to the bottom. Normalization alone cannot fix V1; the definitions of A, U, B and S have to change. The M53-C002 V2 candidate already makes those definition changes (demand-relative A, colour-aware U, B over states with >= 2 legal fronts, remaining-work S imbalance, six-policy ensemble instead of the oracle trace, anchors frozen from an independent 27-fixture corpus before the First 10 were read). It has the best owner agreement (+0.64) and puts L10 first, but it is still compressed at the top (L5 29.4 vs 58, L10 46.7 vs 76) and misreads L7/L9 as harder than L8, which is why the 2026-09-27 reconciliation opened M53-C003 (V2.1 refinement) and the owner then deferred C003 the same day.

Consequences: no content change; levels keep their owner-accepted order; the Level Factory gets a target signal that measures puzzle structure instead of board size. Cost: a calibration job (C003-style, with anti-overfit holdout), and the top lanes (58/76) may remain out of reach even under v2, which would then need a progression-v2 lane rescale (Option C) as a second, separate step.

### Option C: acceptance-window adjustment (versioned progression file)

Change how lane misses are judged instead of how D is measured, through a new `data/config/level_progression_v2.json` (v1 untouched):

- **C1 widen the tolerance**: to pass all 10 under V1 the window would need +/-32.9 (and +/-29.3 under the V2 candidate); that is wider than the gap between adjacent lanes (18 points), so classes would overlap and the window would stop meaning anything.
- Superseded (SB-M36-013, 2026-10-26): lanes are never fitted to the shipped levels; they are placed from an independent anchor corpus, see `docs/DIFFICULTY_LANE_ANCHOR_CALIBRATION.md`.
- **C2 rescale the lanes to the measured scale**: map the lane bases onto what content actually scores. Under V1 this cannot work, because V1 D's order disagrees with the intended order (L10 ranks 3rd, L8 ranks 8th); any monotone map of D keeps that order, so L8 and L10 would still miss.
- **C3 ordinal acceptance**: replace absolute lanes with relative checks inside each 10-level cycle (EASY slots below MEDIUM below HARD below VERY_HARD, recovery drops). Under V1 this fails too (L10 is not the cycle maximum; L8 -> L9 rises).

Consequences: cheap, no model work, but under V1 every variant either becomes meaningless (C1) or still fails (C2, C3), because the measurement is the problem. C becomes useful only after a better-ordered model exists, as the step that places v2 D onto lanes.

Interim (no change needed): the M53-C001 verdict already keeps Stage-A D as diagnostics only, not authority to mutate production content, so the lane misses block nothing today.

## 4. Recommendation

**Option B: build score model v2 by resuming the M53-C003 (V2.1) calibration path**, starting from the frozen M53-C002 V2 candidate definitions rather than re-normalizing V1 (B1 shows that cannot work), calibrated against the owner Stage-B ratings with the C002 anti-overfit rules, weights unchanged. Leave levels 2..10 and the campaign order as they are; keep the Level 1 supply-order fix as its own content task. If v2 still cannot reach the HARD/VERY_HARD lanes, follow with a progression-v2 lane rescale (Option C2) as a separate versioned step. Do not pursue Option A.

## 5. Owner decision needed

1. Whether to resume difficulty-model calibration now (M53-C003 / score model v2) even though the owner deferred it on 2026-09-27 "until the broader game systems are built", or keep deferring it (lane misses then stay diagnostic-only, which is the state today).
2. Confirm no content change for levels 2..10 on the strength of V1 lane misses (owner already rated them class-appropriate).
3. Later, after v2 exists: whether the absolute lane targets 20/40/58/76 may be rescaled in a progression v2 (Option C2), since they are owner-locked in CLAUDE.md 11.2.
