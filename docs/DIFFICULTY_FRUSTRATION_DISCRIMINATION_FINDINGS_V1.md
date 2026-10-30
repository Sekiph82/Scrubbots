# Frustration discrimination findings V1 (SB-M36-017)

Status: FINDINGS only. Profiles stay `PRIOR_UNCALIBRATED`, F stays `PROVISIONAL_SIMULATED_HUMAN`.
Nothing was tuned: `data/config/frustration_analysis_v1.json`, the difficulty score/analysis
models and `level_progression_v1/v2.json` are byte-unchanged, and no committed
`playtest_v2.json` / `frustration_v1.*` output was rewritten.

## Method

- Tool: `tools/difficulty_playtest.gd -- --frustration --runs 32 --fixtures <id>` (new opt-in
  path, SB-M36-017). It runs only the HUMAN_BR population of `FrustrationAnalyzerV1` (factory 053).
- Fixtures: the 5 HARD and 5 VERY_HARD anchors of `tests/fixtures/difficulty_anchors`
  (supply = committed `.supply.json`; cadence slot 5 for HARD, 10 for VERY_HARD), plus L1
  `m21_level_001_hazard_bot` as a sanity point only (owner rule: L1..L10 are never calibration
  references).
- Session Load and choice opacity: `LevelDifficultyAnalyzerV2.score()` of the committed raw
  (`coordination/sessions/FACTORY/050-m36-013-anchor-calibration/anchors_raw`, M53-C002
  `holdout_raw` for L1), sha-bound to the level/supply bytes.
- 32 runs per profile (config default), 96 attempts per level, deterministic seeds.
- Raw output: `coordination/sessions/FACTORY/067-m36-017-frustration-discrimination/frustration_<id>_r32.json`.
- Wall time: 11 processes in parallel on one 16-thread machine, 41 min total. Each anchor run
  took 26-41 min under that contention (one attempt costs about 5.6 s uncontended on 24x24).
  That is above the ~20 min per-run guide; runs were not reduced because all finished.

## Results (32 runs/profile)

| Level | Lane / slot | Won N / C / S (of 32) | Ordering N<=C<=S | retryRisk | lateFailure | Dead placements / attempt N / C / S | SL / budget | choiceOpacity | F |
|---|---|---|---|---:|---:|---|---|---:|---:|
| `hard_maze8_24` | HARD / 5 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.31 / 0.03 / 0.03 | 17.0 / 40 | 0.165 | 2.5 |
| `hard_rings10h_26` | HARD / 5 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.03 / 0.06 / 0.03 | 17.2 / 40 | 0.022 | 0.3 |
| `hard_rings8h_24` | HARD / 5 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.12 / 0.00 / 0.00 | 14.0 / 40 | 0.052 | 0.8 |
| `hard_rings9q_split_24` | HARD / 5 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.12 / 0.03 / 0.00 | 15.2 / 40 | 0.067 | 1.0 |
| `hard_tiles9_split_24` | HARD / 5 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.91 / 0.56 / 0.34 | 15.9 / 40 | 0.223 | 3.4 |
| `vh_maze10_24` | VERY_HARD / 10 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.41 / 0.28 / 0.00 | 16.9 / 48 | 0.219 | 3.3 |
| `vh_rings10h_r1_split_24` | VERY_HARD / 10 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.19 / 0.03 / 0.00 | 15.4 / 48 | 0.030 | 0.5 |
| `vh_rings11h_straddle_24` | VERY_HARD / 10 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.12 / 0.06 / 0.00 | 13.9 / 48 | 0.163 | 2.5 |
| `vh_rings12h_split_24` | VERY_HARD / 10 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.06 / 0.03 / 0.00 | 14.0 / 48 | 0.039 | 0.6 |
| `vh_rings12q_split_26` | VERY_HARD / 10 | 32 / 32 / 32 | holds (tie) | 0.000 | 0.000 | 0.09 / 0.03 / 0.00 | 18.9 / 48 | 0.027 | 0.4 |
| L1 `m21_level_001_hazard_bot` (sanity only) | EASY / 1 | 3 / 3 / 2 | **miss** (C 3/32 > S 2/32) | 0.912 | 0.000 (88 LOST, all early) | 4.88 / 4.88 / 4.94 | 7.5 / 26 | 0.648 | 41.7 |

No attempt was INCONCLUSIVE. Wilson 95%: 32/32 = [0.893, 1.000]; L1 3/32 = [0.032, 0.242],
2/32 = [0.017, 0.201], so the L1 miss is inside the interval overlap.

## Findings

1. **Clear-rate ordering.** On all 10 HARD/VERY_HARD anchors NOVICE <= CASUAL <= SKILLED holds
   only as a tie (every profile cleared 32/32). On L1 it misses at CASUAL vs SKILLED (3/32 vs
   2/32), the same direction as the 053 2-run finding, but not significant.
2. **retryRisk pairs.** All 45 anchor-anchor pairs tie at retryRisk 0. The only non-tied pairs are
   L1 (0.912) against each of the 10 anchors (0.000), i.e. the sanity level is "riskier" than every
   HARD/VERY_HARD anchor. That ordering is opposite to the lane intent, and L1 is not a calibration
   reference.
3. **Why.** HUMAN_BR LOST is a proven DEADLOCK. No HUMAN_BR attempt reached a deadlock on any anchor
   supply, so retryRisk and lateFailure are 0 regardless of lane, and anchor F reduces to
   `15 x choiceOpacity` (sessionOverrun is 0: SL 14-19 vs budgets 40/48). L1 loses for every
   profile almost equally (dead placements ~4.9 per attempt for all three), so its losses come from
   the seeded random supply, not from player skill.
4. **Skill does show up below the outcome level.** Dead placements per attempt fall NOVICE ->
   SKILLED on 9 of 10 anchors (SKILLED <= NOVICE on all 10; `hard_rings10h_26` is flat), but this
   diagnostic is not an F input.

## Conclusion

With the current priors and the deadlock-only LOST rule, HUMAN_BR does not discriminate HARD and
VERY_HARD anchors through retryRisk or lateFailure: 35% + 20% of the F weight is constant 0 on the
whole anchor set, and the only loss signal seen (L1) is supply-driven, not skill-driven. F on the
anchors is effectively a rescaled choice-opacity proxy.

## Next step (proposal, not done here)

Measure where a loss is possible before judging the priors: run HUMAN_BR on fixtures whose supply
admits a deadlock (seeded `BatchSupplyGenerator` supplies on the anchor geometries, or corpus
fixtures with a solver-proven DEADLOCK branch), and evaluate whether a skill-sensitive diagnostic
(dead placements, no-target waits) should become an F input under a new model version. Any change
to the profiles, the LOST rule or the F inputs is a versioned config/model change for a separate
task, not a silent edit of v1.
