# M53-C001 — FIRST 10 M53 MATRIX V01

Status: GENERATED EVIDENCE (tools/analyze_m53_first10.gd merge) — awaiting ChatGPT audit
Analyzer: `scripts/difficulty/level_difficulty_analyzer_v1.gd` (m53-level-difficulty-analyzer/v1), score model v1, progression model v1, analysis config v1 (STAGE_A_PROVISIONAL anchors).
Reference path: canonical SolvabilitySolver trace replayed step-exact through ProofKernel; owner intended click path shown as sensitivity.

Overall: **TUNING_REQUIRED** — in default ±3.5 window: 0/10; static QA PASS: 10/10; TUNING_REQUIRED: m21_level_001_hazard_bot, level_002_apple, level_003_palm_tree, level_004_orange_cat, level_005_party_toucan, level_006_chicken, level_007_pigeon, level_008_butterfly, level_009_frog, level_010_ice_cube

| Level | ID | Class | Target D | Actual D | Delta | W | C | A | U | B | R | S | Session Load | Frustration | Solver | Runtime provenance | M53 QA verdict |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| 1 | `m21_level_001_hazard_bot` | EASY | 20.0 | 46.03 | +26.03 | 0.000 | 0.373 | 0.779 | 0.284 | 0.639 | 0.306 | 0.653 | 9.9 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 19 steps, trace 1618197986 | generator seed 1 (L1 historical) | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 2 | `level_002_apple` | EASY | 22.0 | 45.04 | +23.04 | 0.414 | 0.404 | 0.696 | 0.410 | 0.450 | 0.290 | 0.309 | 24.4 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 36 steps, trace 4098941249 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 3 | `level_003_palm_tree` | MEDIUM | 40.0 | 54.27 | +14.27 | 0.621 | 0.558 | 0.735 | 0.461 | 0.477 | 0.339 | 0.523 | 35.3 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 51 steps, trace 3808086370 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 4 | `level_004_orange_cat` | EASY | 19.0 | 49.49 | +30.49 | 0.414 | 0.511 | 0.688 | 0.410 | 0.459 | 0.342 | 0.542 | 24.9 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 39 steps, trace 2842640196 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 5 | `level_005_party_toucan` | HARD | 58.0 | 53.19 | -4.81 | 0.448 | 0.701 | 0.687 | 0.412 | 0.459 | 0.371 | 0.564 | 26.7 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 41 steps, trace 3056207161 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_DEFAULT_WITHIN_HARD_LIMIT)** |
| 6 | `level_006_chicken` | EASY | 18.0 | 50.91 | +32.91 | 0.414 | 0.540 | 0.706 | 0.410 | 0.474 | 0.342 | 0.583 | 25.0 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 40 steps, trace 3310440768 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 7 | `level_007_pigeon` | EASY | 21.0 | 50.96 | +29.96 | 0.414 | 0.559 | 0.687 | 0.410 | 0.477 | 0.362 | 0.572 | 25.0 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 39 steps, trace 2191893116 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 8 | `level_008_butterfly` | MEDIUM | 42.0 | 47.37 | +5.37 | 0.414 | 0.631 | 0.613 | 0.410 | 0.438 | 0.371 | 0.304 | 24.9 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 37 steps, trace 2524445735 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 9 | `level_009_frog` | EASY | 19.0 | 50.78 | +31.78 | 0.414 | 0.541 | 0.695 | 0.410 | 0.482 | 0.302 | 0.620 | 24.7 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 38 steps, trace 3800836965 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |
| 10 | `level_010_ice_cube` | VERY_HARD | 76.0 | 51.50 | -24.50 | 0.414 | 0.778 | 0.614 | 0.410 | 0.464 | 0.331 | 0.497 | 25.1 | PROVISIONAL_STAGE_A (no scalar) | SOLVED, 40 steps, trace 1480752256 | owner plan v1 | **TUNING_REQUIRED (static PASS, OUTSIDE_HARD_LIMIT)** |

## Sensitivity

| Level | D (solver path) | D (owner click path) | D range over provisional anchors ×0.5/×2 | Session Load range | Est. attempt s (proxy) | Profile | Nearest prior (combined sim) |
|---:|---:|---:|---|---|---:|---|---|
| 1 | 46.03 | n/a | 44.41–49.28 | 7.0–15.6 | 237 | BALANCED | — |
| 2 | 45.04 | 38.60 | 42.27–50.60 | 17.0–39.1 | 712 | BALANCED | m21_level_001_hazard_bot (0.532) |
| 3 | 54.27 | 44.47 | 51.01–60.79 | 24.9–56.0 | 976 | BALANCED | level_002_apple (0.651) |
| 4 | 49.49 | 37.09 | 46.72–55.05 | 17.5–39.6 | 685 | BALANCED | level_002_apple (0.800) |
| 5 | 53.19 | 39.07 | 50.39–58.78 | 18.9–42.3 | 724 | COLOR | level_004_orange_cat (0.725) |
| 6 | 50.91 | 38.75 | 48.13–56.46 | 17.6–39.7 | 675 | BALANCED | level_005_party_toucan (0.837) |
| 7 | 50.96 | 39.47 | 48.18–56.51 | 17.7–39.7 | 699 | BALANCED | level_006_chicken (0.814) |
| 8 | 47.37 | 37.67 | 44.60–52.93 | 17.6–39.6 | 727 | BALANCED | level_006_chicken (0.887) |
| 9 | 50.78 | 41.00 | 48.00–56.33 | 17.3–39.4 | 637 | COLOR | level_004_orange_cat (0.788) |
| 10 | 51.50 | 40.77 | 48.72–57.05 | 17.7–39.8 | 703 | COLOR | level_009_frog (0.813) |

## Recovery cadence (actual D)

| From → To | Actual D from → to | Actual drop | Design min drop | Target drop | Lower than peak | Guard |
|---|---|---:|---:|---:|---|---|
| L3 → L4 | 54.27 → 49.49 | 4.78 | 15.0 | 21.0 | yes | FAIL |
| L5 → L6 | 53.19 → 50.91 | 2.28 | 20.0 | 40.0 | yes | FAIL |
| L8 → L9 | 47.37 → 50.78 | -3.41 | 15.0 | 23.0 | NO (inverted) | FAIL |

L10 boss: actual D 51.50, rank 3 of 10 by actual D, cycle maximum: NO.

## Static QA gates

| Gate | L1 | L2 | L3 | L4 | L5 | L6 | L7 | L8 | L9 | L10 |
|---|---|---|---|---|---|---|---|---|---|---|
| legal_dimensions_envelope | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| owner_locked_class_token | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| canonical_palette_c01_c16 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| used_color_count_3_12 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| exact_cell_count | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| no_invalid_palette_ids | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| source_reconstruction_exact | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| no_unintended_interpolation | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| cleared_transparency_render | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| canonical_solvability | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| routing_access_sanity | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| performance_sanity | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| preview_exact | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| unique_stable_id | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| catalog_order | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| source_metadata_provenance | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| level1_historical_generator_path | PASS | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| owner_supply_plan_provenance | n/a | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |

Frustration Risk: PROVISIONAL_STAGE_A for every level — only the choice-opacity proxy is supported; retry risk (simulated human clear rate), session overrun (no owner slot budget) and late failure (no failing-simulation population) are UNSUPPORTED, so no scalar is claimed. Solver success is not a human first-attempt clear probability.

Machine-readable authority: `evidence/first10_difficulty_v1.json`, `evidence/first10_level_qa_v1.json`, raw replay measurements `evidence/raw/<id>_raw_v1.json`.
