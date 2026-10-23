# Difficulty playtest 2026-10 (simulated) — shipped production catalog

Task: SB-M36-005 (factory job 044). Generated from `coordination/sessions/FACTORY/044-m36-005-difficulty-playtest/playtest_v1.json`, written by `tools/difficulty_playtest.gd`; every number below is copied from that JSON.

## Method

- Levels: every entry of `data/levels/catalog/production_catalog_v1.json`, read through `LevelCatalog` (10 levels, orders 1..10). Campaign age k = 0 for all, so P(k) = 0 and lane targets are the base values (CLAUDE.md 11.2).
- Per level, fresh: `SolvabilitySolver.solve` on the catalog supply engine (Level 1: BatchSupplyGenerator seed 1; Levels 2..10: owner supply plans, via `tools/analyze_m53_first10.gd` `reference_inputs`). Solver statuses are reported in docs/10 vocabulary: DEADLOCK = UNSOLVABLE, UNKNOWN_BOUND = INCONCLUSIVE.
- The fresh solver trace (the oracle path) is replayed step-exact through `LevelDifficultyAnalyzerV1.measure` (real ProofKernel, TargetSelector, production routing/access); the replay gives dispatches (= total clears), decisions, dispatch waves and route-validator failures. `score` then gives D, W/C/A/U/B/R/S, target, window, Session Load and the Frustration record. Measure mode for this run: `fresh` (per-level `source` column).
- Every fresh solver trace hash equals the committed M52 reference trace (`traceEqualsCommittedReference`: true, true, true, true, true, true, true, true, true, true).
- Anomaly rules are applied mechanically by the runner: CADENCE (declared class vs CLAUDE.md 11.1 table), BOUNDARY (declared class vs `level_progression_v1.json` cadence), LANE_MISS (|D - target| > defaultPlusMinus 3.5; SOFT up to neverForceLabelOutsidePlusMinus 5.0, OUT_OF_HARD_LIMIT beyond), RECOVERY (`recoveryGuards` on actual D), SOLVER (status not SOLVED), ROUTE (route failures, unsolved replay or final ACTIVE cells), LONG_HIGH_FRICTION (two consecutive levels both above the pack median of D and of Session Load; no config threshold exists, docs/11 section 8 gives only relative rules).
- Run: `"$GODOT" --headless --path . -s res://tools/difficulty_playtest.gd`, wall time 13m42.832s on the owner PC (Godot 4.7.2, headless). `-- --committed-measure` reuses the committed M53 raw replay per level when its trace hash equals the fresh solver trace (about 4 minutes, solver still fresh, labelled `committed_raw`); this report uses the fully fresh run.

## Provenance and versions

- analyzerVersion: `m53-level-difficulty-analyzer/v1`
- analysisConfig: `res://data/config/level_difficulty_analysis_v1.json`
- analysisConfigVersion: `1`
- calibrationStage: `STAGE_A_PROVISIONAL`
- scoreModelSchema: `scrubbots-difficulty-score-model/v1`
- scoreModelVersion: `1`
- progressionModelSchema: `scrubbots-level-progression/v1`
- progressionModelVersion: `1`
- solver: `res://scripts/gameplay/solver/solvability_solver.gd`
- kernel: `res://scripts/gameplay/solver/proof_kernel.gd`
- routing: `res://scripts/gameplay/routing/production_routing_system.gd`
- access: `res://scripts/gameplay/dispatch/production_target_access.gd`
- Challenge Score formula (data/config/difficulty_score_model_v1.json): `100*(0.10W+0.15C+0.20A+0.20U+0.15B+0.10R+0.10S)`; Session Load `100*(0.50 actions + 0.30 routeTime + 0.20 decisions)` (PROVISIONAL_STAGE_A); Frustration `100*(0.35 retryRisk + 0.30 sessionOverrun + 0.20 lateFailure + 0.15 choiceOpacity)`, provisional until human calibration.
- Tolerance (data/config/level_progression_v1.json `challengeTolerance`): default +/-3.5, never label outside +/-5.0.

## Per-level results

| # | Level | WxH | Class | Slot | D | Target | Delta | Window | W | C | A | U | B | R | S | Session Load | Frustration | Solver | Visited | Solver ms | Dispatches | Decisions | Waves | Route fails | Measure ms | Source |
|---:|---|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | `m21_level_001_hazard_bot` | 20x20 | EASY | 1 | 46.0 | 20 | +26.0 | OUTSIDE_HARD_LIMIT | 0.000 | 0.373 | 0.779 | 0.284 | 0.639 | 0.306 | 0.653 | 9.9 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 20 | 904 | 400 | 19 | 379 | 0 | 7072 | fresh |
| 2 | `level_002_apple` | 32x32 | EASY | 2 | 45.0 | 22 | +23.0 | OUTSIDE_HARD_LIMIT | 0.414 | 0.404 | 0.696 | 0.410 | 0.450 | 0.290 | 0.309 | 24.4 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 37 | 20447 | 1024 | 36 | 1012 | 0 | 57435 | fresh |
| 3 | `level_003_palm_tree` | 38x38 | MEDIUM | 3 | 54.3 | 40 | +14.3 | OUTSIDE_HARD_LIMIT | 0.621 | 0.558 | 0.735 | 0.461 | 0.477 | 0.339 | 0.523 | 35.3 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 59 | 44134 | 1444 | 51 | 1312 | 0 | 113578 | fresh |
| 4 | `level_004_orange_cat` | 32x32 | EASY | 4 | 49.5 | 19 | +30.5 | OUTSIDE_HARD_LIMIT | 0.414 | 0.511 | 0.688 | 0.410 | 0.459 | 0.342 | 0.542 | 24.9 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 40 | 23637 | 1024 | 39 | 968 | 0 | 57496 | fresh |
| 5 | `level_005_party_toucan` | 33x33 | HARD | 5 | 53.2 | 58 | -4.8 | OUTSIDE_DEFAULT_WITHIN_HARD_LIMIT | 0.448 | 0.701 | 0.687 | 0.412 | 0.459 | 0.371 | 0.564 | 26.7 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 46 | 25428 | 1089 | 41 | 1010 | 0 | 62091 | fresh |
| 6 | `level_006_chicken` | 32x32 | EASY | 6 | 50.9 | 18 | +32.9 | OUTSIDE_HARD_LIMIT | 0.414 | 0.540 | 0.706 | 0.410 | 0.474 | 0.342 | 0.583 | 25.0 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 41 | 24088 | 1024 | 40 | 970 | 0 | 62581 | fresh |
| 7 | `level_007_pigeon` | 32x32 | EASY | 7 | 51.0 | 21 | +30.0 | OUTSIDE_HARD_LIMIT | 0.414 | 0.559 | 0.687 | 0.410 | 0.477 | 0.362 | 0.572 | 25.0 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 40 | 22465 | 1024 | 39 | 973 | 0 | 57795 | fresh |
| 8 | `level_008_butterfly` | 32x32 | MEDIUM | 8 | 47.4 | 42 | +5.4 | OUTSIDE_HARD_LIMIT | 0.414 | 0.631 | 0.613 | 0.410 | 0.438 | 0.371 | 0.304 | 24.9 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 38 | 17649 | 1024 | 37 | 994 | 0 | 60464 | fresh |
| 9 | `level_009_frog` | 32x32 | EASY | 9 | 50.8 | 19 | +31.8 | OUTSIDE_HARD_LIMIT | 0.414 | 0.541 | 0.695 | 0.410 | 0.482 | 0.302 | 0.620 | 24.7 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 40 | 26487 | 1024 | 38 | 899 | 0 | 58541 | fresh |
| 10 | `level_010_ice_cube` | 32x32 | VERY_HARD | 10 | 51.5 | 76 | -24.5 | OUTSIDE_HARD_LIMIT | 0.414 | 0.778 | 0.614 | 0.410 | 0.464 | 0.331 | 0.497 | 25.1 | PROVISIONAL_STAGE_A (scalar null) | SOLVED | 47 | 24097 | 1024 | 40 | 956 | 0 | 54045 | fresh |

D, Target and Delta to one decimal; vector to three. Frustration Risk scalar is null for every level (status PROVISIONAL_STAGE_A); no scalar is claimed.

## Recovery guards (actual D)

| From -> To | D from -> to | Actual drop | Design min drop | Pass |
|---|---|---:|---:|---|
| L3 -> L4 | 54.3 -> 49.5 | 4.8 | 15.0 | FAIL |
| L5 -> L6 | 53.2 -> 50.9 | 2.3 | 20.0 | FAIL |
| L8 -> L9 | 47.4 -> 50.8 | -3.4 | 15.0 | FAIL |

L10 boss: D 51.5, rank 3 of 10 by D, cycle maximum: no. The 10 -> next-cycle-1 guard needs Level 11, which is not shipped, so it is not evaluated.

## Anomalies (15)

### CADENCE (0)

None.

### BOUNDARY (0)

None.

### LANE_MISS (10)

- L1 `m21_level_001_hazard_bot`: D 46.0 vs target 20.0, delta +26.0, OUT_OF_HARD_LIMIT.
- L2 `level_002_apple`: D 45.0 vs target 22.0, delta +23.0, OUT_OF_HARD_LIMIT.
- L3 `level_003_palm_tree`: D 54.3 vs target 40.0, delta +14.3, OUT_OF_HARD_LIMIT.
- L4 `level_004_orange_cat`: D 49.5 vs target 19.0, delta +30.5, OUT_OF_HARD_LIMIT.
- L5 `level_005_party_toucan`: D 53.2 vs target 58.0, delta -4.8, SOFT.
- L6 `level_006_chicken`: D 50.9 vs target 18.0, delta +32.9, OUT_OF_HARD_LIMIT.
- L7 `level_007_pigeon`: D 51.0 vs target 21.0, delta +30.0, OUT_OF_HARD_LIMIT.
- L8 `level_008_butterfly`: D 47.4 vs target 42.0, delta +5.4, OUT_OF_HARD_LIMIT.
- L9 `level_009_frog`: D 50.8 vs target 19.0, delta +31.8, OUT_OF_HARD_LIMIT.
- L10 `level_010_ice_cube`: D 51.5 vs target 76.0, delta -24.5, OUT_OF_HARD_LIMIT.

### RECOVERY (3)

- L3 `level_003_palm_tree` -> L4 `level_004_orange_cat`: D 54.3 -> 49.5, drop 4.8 < design minimum 15.0.
- L5 `level_005_party_toucan` -> L6 `level_006_chicken`: D 53.2 -> 50.9, drop 2.3 < design minimum 20.0.
- L8 `level_008_butterfly` -> L9 `level_009_frog`: D 47.4 -> 50.8, drop -3.4 < design minimum 15.0.

### SOLVER (0)

None.

### ROUTE (0)

None.

### LONG_HIGH_FRICTION (2)

- L5 `level_005_party_toucan` (D 53.2, Session Load 26.68) then L6 `level_006_chicken` (D 50.9, Session Load 24.96); medians D 50.8, Session Load 24.95.
- L6 `level_006_chicken` (D 50.9, Session Load 24.96) then L7 `level_007_pigeon` (D 51.0, Session Load 25.01); medians D 50.8, Session Load 24.95.

Not a runner rule but recorded as a finding: the Frustration Risk scalar is unsupported for all 10 levels (85% of its V1 weight, retryRisk + sessionOverrun + lateFailure, has no inputs).

Reading: measured D is compressed into 45.0..54.3 for all ten levels while the 11.2 targets span 18..76, so the EASY and MEDIUM slots score above their lane and the HARD/VERY_HARD slots below theirs. The recovery failures and the L5..L7 run follow from the same flat curve; the L6/L7 Session Load margin over the median is only hundredths of a point, so that run is a weak signal.

## What this does and does not prove

It proves, for the 10 shipped levels on the current code: each level is SOLVED by a fresh canonical solver run; the oracle trace replays through the production kernel and routing with 0 route-validator failures and 0 ACTIVE cells left; and the V1 model (Stage-A anchors) scores them as tabled, with the anomalies above. It does not prove how hard the levels feel to people: the path is the solver oracle, not a human or a human-like policy; Session Load is a provisional proxy and attempt seconds are kernel timing, not calibrated play time; Frustration Risk is provisional with no scalar; there is no human feedback or telemetry. The owner live-playtest gate is given by CLAUDE.md 0D.1, so this simulated run is the playtest of record for SB-M36-005; human calibration remains docs/11 sections 3-5 work. No level data, supply plan, catalog, coefficient, anchor, tolerance or model version was changed.

## Filed follow-up tasks

- SB-M36-009 — lane calibration proposal (LANE_MISS, all 10 levels).
- SB-M36-010 — recovery/sequencing proposal (RECOVERY 3->4, 5->6, 8->9; LONG_HIGH_FRICTION L5..L7).
- SB-M36-011 — Frustration Risk inputs (scalar unsupported).

Each is a proposal job: no coefficient or model-version change without a new model version (CLAUDE.md 11.3).
