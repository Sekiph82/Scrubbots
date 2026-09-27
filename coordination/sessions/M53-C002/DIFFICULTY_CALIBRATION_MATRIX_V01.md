# M53-C002 — DIFFICULTY CALIBRATION MATRIX V01

Status: GENERATED (tools/calibrate_difficulty_v2.gd) — V2 CANDIDATE, not production authority; awaiting ChatGPT audit and owner decision.
Frozen V2 config sha256: `4cd879c5aa8e6ee141169f29b5f6a758e20a1d88987bbff5c5de091051da14f8` (frozen before any First 10 measurement).

## 1. Calibration corpus (independent, QA-only)

| Fixture | Family | Axis | Size | Colours | D | W | C | A | U | B | R | S | SL | Policy D range | Gated robust max dev | Strategy-family max dev |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| `flow_stripes3_20` | FLOW_SIZE | W | 20 | 3 | 13.97 | 0.000 | 0.499 | 0.303 | 0.000 | 0.000 | 0.026 | 0.017 | 9.1 | 10.42–15.47 | 0.71 | 1.27 |
| `flow_stripes3_24` | FLOW_SIZE | W | 24 | 3 | 12.51 | 0.138 | 0.500 | 0.165 | 0.000 | 0.000 | 0.014 | 0.019 | 13.4 | 10.07–13.73 | 0.49 | 1.07 |
| `flow_stripes3_32` | FLOW_SIZE | W | 32 | 3 | 11.78 | 0.414 | 0.500 | 0.000 | 0.000 | 0.000 | 0.000 | 0.014 | 24.2 | 11.78–11.99 | 0.07 | 0.19 |
| `flow_stripes3_40` | FLOW_SIZE | W | 40 | 3 | 14.57 | 0.690 | 0.500 | 0.000 | 0.000 | 0.000 | 0.001 | 0.016 | 39.1 | 14.52–14.68 | 0.03 | 0.02 |
| `flow_stripes3_48` | FLOW_SIZE | W | 48 | 3 | 17.32 | 0.966 | 0.500 | 0.000 | 0.000 | 0.000 | 0.002 | 0.014 | 57.8 | 17.26–17.38 | 0.02 | 0.00 |
| `color_stripes6_24` | COLOR_EXPLORATORY | C | 24 | 6 | 21.45 | 0.138 | 0.667 | 0.487 | 0.000 | 0.000 | 0.014 | 0.020 | 13.9 | 14.09–24.36 | 1.47 | 2.81 |
| `color_stripes12_24` | COLOR_EXPLORATORY | C | 24 | 12 | 32.15 | 0.138 | 1.000 | 0.776 | 0.000 | 0.000 | 0.014 | 0.011 | 13.9 | 26.37–34.92 | 1.16 | 2.71 |
| `color_skew6_24` | COLOR_EXPLORATORY | C | 24 | 6 | 12.45 | 0.138 | 0.403 | 0.211 | 0.000 | 0.000 | 0.014 | 0.066 | 13.4 | 9.24–14.84 | 0.64 | 1.40 |
| `color_m3_24` | COLOR | C | 24 | 3 | 10.29 | 0.138 | 0.500 | 0.057 | 0.000 | 0.000 | 0.014 | 0.012 | 13.4 | 9.19–10.96 | 0.25 | 0.51 |
| `color_m6_24` | COLOR | C | 24 | 6 | 18.37 | 0.138 | 0.667 | 0.334 | 0.000 | 0.000 | 0.014 | 0.017 | 13.9 | 11.89–21.29 | 1.30 | 2.85 |
| `color_m12_24` | COLOR | C | 24 | 12 | 32.15 | 0.138 | 1.000 | 0.776 | 0.000 | 0.000 | 0.014 | 0.011 | 13.9 | 26.37–34.92 | 1.16 | 2.71 |
| `color_m6skew_24` | COLOR | C | 24 | 6 | 23.15 | 0.138 | 0.578 | 0.632 | 0.000 | 0.000 | 0.014 | 0.031 | 13.6 | 19.04–26.46 | 0.82 | 1.88 |
| `access_band3_24` | ACCESSIBILITY | A | 24 | 3 | 8.72 | 0.138 | 0.298 | 0.079 | 0.000 | 0.000 | 0.085 | 0.045 | 13.5 | 7.64–9.66 | 0.22 | 0.50 |
| `access_shafts3_24` | ACCESSIBILITY | A | 24 | 3 | 18.86 | 0.138 | 0.298 | 0.527 | 0.000 | 0.000 | 0.199 | 0.047 | 13.8 | 17.97–19.68 | 0.23 | 0.41 |
| `access_halves3_24` | ACCESSIBILITY_EXPLORATORY | A | 24 | 3 | 7.02 | 0.138 | 0.332 | 0.000 | 0.000 | 0.000 | 0.015 | 0.051 | 13.4 | 6.78–7.14 | 0.05 | 0.11 |
| `access_comb3_24` | ACCESSIBILITY_EXPLORATORY | A | 24 | 3 | 10.09 | 0.138 | 0.332 | 0.000 | 0.000 | 0.000 | 0.329 | 0.044 | 14.0 | 9.97–10.35 | 0.05 | 0.08 |
| `access_stripes4_24` | ACCESSIBILITY_EXPLORATORY | A | 24 | 4 | 18.27 | 0.138 | 0.556 | 0.410 | 0.000 | 0.000 | 0.014 | 0.021 | 13.2 | 12.74–21.06 | 1.11 | 2.04 |
| `access_mosaic4_24` | ACCESSIBILITY_EXPLORATORY | A | 24 | 4 | 27.56 | 0.138 | 0.556 | 0.179 | 0.669 | 0.000 | 0.084 | 0.005 | 14.7 | 25.21–30.44 | 0.58 | 1.30 |
| `unlock_shallow_24` | UNLOCK | U | 24 | 3 | 15.54 | 0.138 | 0.453 | 0.052 | 0.291 | 0.000 | 0.038 | 0.012 | 13.4 | 14.49–16.57 | 0.31 | 0.67 |
| `unlock_deep_24` | UNLOCK | U | 24 | 3 | 29.45 | 0.138 | 0.483 | 0.041 | 0.954 | 0.012 | 0.064 | 0.012 | 13.5 | 28.35–31.27 | 0.36 | 0.46 |
| `route_straight_24` | ROUTE | R | 24 | 3 | 11.17 | 0.138 | 0.182 | 0.327 | 0.000 | 0.000 | 0.014 | 0.038 | 13.4 | 9.85–11.92 | 0.27 | 0.35 |
| `route_maze_24` | ROUTE | R | 24 | 3 | 36.51 | 0.138 | 0.329 | 1.000 | 0.000 | 0.000 | 1.000 | 0.019 | 15.2 | 31.67–33.49 | 1.51 | 3.74 |
| `bottleneck_low_24` | BOTTLENECK | B | 24 | 3 | 17.57 | 0.138 | 0.426 | 0.010 | 0.451 | 0.000 | 0.049 | 0.010 | 13.4 | 17.37–18.46 | 0.22 | 0.53 |
| `bottleneck_high_24` | BOTTLENECK | B | 24 | 3 | 27.28 | 0.138 | 0.426 | 0.347 | 0.451 | 0.164 | 0.042 | 0.067 | 13.4 | 25.46–30.95 | 0.73 | 1.81 |
| `slot_low_24` | SLOT | S | 24 | 3 | 21.12 | 0.138 | 0.378 | 0.000 | 0.669 | 0.009 | 0.047 | 0.010 | 13.4 | 20.91–21.83 | 0.07 | 0.07 |
| `slot_high_24` | SLOT | S | 24 | 3 | 25.66 | 0.138 | 0.378 | 0.172 | 0.669 | 0.059 | 0.045 | 0.045 | 13.3 | 20.93–31.98 | 1.27 | 3.08 |
| `compact_hard_20` | COMPACT_HARD | D | 20 | 3 | 31.24 | 0.000 | 0.473 | 0.345 | 0.744 | 0.084 | 0.078 | 0.032 | 9.3 | 29.91–33.80 | 0.51 | 1.22 |

### Ordinal relationships (declared before measurement)

| Harder | Easier | Axis | Axis harder / easier | D harder / easier | Result |
|---|---|---|---|---|---|
| `color_stripes6_24` | `flow_stripes3_24` | C | 0.667 / 0.500 | 21.45 / 12.51 | PASS |
| `color_stripes12_24` | `color_stripes6_24` | C | 1.000 / 0.667 | 32.15 / 21.45 | PASS |
| `color_stripes6_24` | `color_skew6_24` | C | 0.667 / 0.403 | 21.45 / 12.45 | PASS |
| `access_shafts3_24` | `access_band3_24` | A | 0.527 / 0.079 | 18.86 / 8.72 | PASS |
| `unlock_deep_24` | `unlock_shallow_24` | U | 0.954 / 0.291 | 29.45 / 15.54 | PASS |
| `route_maze_24` | `route_straight_24` | R | 1.000 / 0.014 | 36.51 / 11.17 | PASS |
| `bottleneck_high_24` | `bottleneck_low_24` | B | 0.164 / 0.000 | 27.28 / 17.57 | PASS |
| `slot_high_24` | `slot_low_24` | S | 0.045 / 0.010 | 25.66 / 21.12 | PASS |
| `flow_stripes3_48` | `flow_stripes3_20` | W | 0.966 / 0.000 | 17.32 / 13.97 | PASS |
| `flow_stripes3_48` | `flow_stripes3_20` | SL | 57.776 / 9.056 | 17.32 / 13.97 | PASS |
| `compact_hard_20` | `flow_stripes3_48` | D | 31.241 / 17.319 | 31.24 / 17.32 | PASS |
| `color_m6_24` | `color_m3_24` | C | 0.667 / 0.500 | 18.37 / 10.29 | PASS |
| `color_m12_24` | `color_m6_24` | C | 1.000 / 0.667 | 32.15 / 18.37 | PASS |
| `color_m6_24` | `color_m6skew_24` | C | 0.667 / 0.578 | 18.37 / 23.15 | PASS |

Flow-size family (20..48): D spread 5.54 (< 18) PASS; max D 17.32 (< 40) PASS.

### Frozen anchors (rule-derived from the corpus only)

| Anchor | Value | Rule |
|---|---:|---|
| A_lo | 0.0291 | median over the FLOW_SIZE family of primary A_raw |
| A_hi | 0.5874 | maximum over the whole calibration corpus of primary A_raw |
| U_p95_hi | 4.0000 | maximum over the corpus of p95 unlock wave |
| U_mean_hi | 1.5278 | maximum over the corpus of mean unlock wave |
| R_len_lo | 0.7318 | median over the FLOW_SIZE family of primary mean route length / diagonal |
| R_len_hi | 1.6558 | maximum over the corpus of primary mean route length / diagonal |
| R_detour_lo | 1.2878 | median over the FLOW_SIZE family of primary mean detour |
| R_detour_hi | 2.8803 | maximum over the corpus of primary mean detour |
| R_turn_lo | 2.0625 | median over the FLOW_SIZE family of primary mean turns |
| R_turn_hi | 4.6811 | maximum over the corpus of primary mean turns |

## 2. First 10 holdout — V1 Stage A vs V2 candidate

In default ±3.5 window under V2: **2/10**. Policy robustness within ±1.75 D on all ten: **NO**.

| L | ID | Class | Target | V1 D | V2 D | V2 delta | V2 window | W | C | A | U | B | R | S | V2 SL | Policy D range (6 non-adv) | Gated robust max dev | Strategy-family max dev | Oracle / owner path D (diag) | Anchor ±sens D |
|---:|---|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---|---|
| 1 | `m21_level_001_hazard_bot` | EASY | 20 | 46.03 | **42.37** | +22.37 | OUTSIDE_HARD_LIMIT | 0.000 | 0.373 | 0.628 | 0.406 | 0.699 | 0.085 | 0.477 | 7.5 | 39.09–48.77 | 1.28 | 3.13 | 43.73 / n/a | 39.76–45.72 |
| 2 | `level_002_apple` | EASY | 22 | 45.04 | **22.08** | +0.08 | IN_DEFAULT_WINDOW | 0.414 | 0.404 | 0.266 | 0.270 | 0.010 | 0.069 | 0.032 | 24.5 | 18.05–24.85 | 0.80 | 1.90 | 18.24 / 18.05 | 20.97–23.49 |
| 3 | `level_003_palm_tree` | MEDIUM | 40 | 54.27 | **38.94** | -1.06 | IN_DEFAULT_WINDOW | 0.621 | 0.558 | 0.492 | 0.513 | 0.047 | 0.240 | 0.114 | 35.6 | 34.03–41.67 | 0.72 | 1.67 | 43.61 / 34.03 | 36.89–41.56 |
| 4 | `level_004_orange_cat` | EASY | 19 | 49.49 | **24.96** | +5.96 | OUTSIDE_HARD_LIMIT | 0.414 | 0.511 | 0.108 | 0.471 | 0.000 | 0.100 | 0.056 | 25.0 | 22.54–28.07 | 0.62 | 1.03 | 32.98 / 22.54 | 23.86–26.33 |
| 5 | `level_005_party_toucan` | HARD | 58 | 53.19 | **29.37** | -28.63 | OUTSIDE_HARD_LIMIT | 0.448 | 0.701 | 0.109 | 0.492 | 0.057 | 0.091 | 0.059 | 26.6 | 25.86–35.59 | 1.43 | 1.77 | 44.98 / 25.86 | 28.27–30.75 |
| 6 | `level_006_chicken` | EASY | 18 | 50.91 | **23.58** | +5.58 | OUTSIDE_HARD_LIMIT | 0.414 | 0.540 | 0.044 | 0.436 | 0.008 | 0.112 | 0.050 | 25.2 | 22.69–24.46 | 0.18 | 0.33 | 34.99 / 22.69 | 22.48–24.95 |
| 7 | `level_007_pigeon` | EASY | 21 | 50.96 | **33.19** | +12.19 | OUTSIDE_HARD_LIMIT | 0.414 | 0.559 | 0.341 | 0.453 | 0.150 | 0.117 | 0.137 | 25.2 | 25.67–42.62 | 1.89 | 3.47 | 38.27 / 26.85 | 31.77–35.01 |
| 8 | `level_008_butterfly` | MEDIUM | 42 | 47.37 | **28.69** | -13.31 | OUTSIDE_HARD_LIMIT | 0.414 | 0.631 | 0.141 | 0.467 | 0.033 | 0.210 | 0.032 | 25.1 | 25.07–34.18 | 1.14 | 1.85 | 30.33 / 25.07 | 27.59–30.07 |
| 9 | `level_009_frog` | EASY | 19 | 50.78 | **37.15** | +18.15 | OUTSIDE_HARD_LIMIT | 0.414 | 0.541 | 0.408 | 0.530 | 0.152 | 0.261 | 0.125 | 25.1 | 33.50–42.51 | 1.38 | 1.04 | 41.37 / 33.50 | 35.45–39.32 |
| 10 | `level_010_ice_cube` | VERY_HARD | 76 | 51.50 | **46.72** | -29.28 | OUTSIDE_HARD_LIMIT | 0.414 | 0.778 | 0.453 | 0.967 | 0.030 | 0.109 | 0.098 | 25.1 | 42.23–52.57 | 1.65 | 0.75 | 53.83 / 44.63 | 44.52–49.14 |

### Recovery cadence (actual V2 D)

| From → To | D from → to | Drop | Design min | Guard |
|---|---|---:|---:|---|
| L3 → L4 | 38.94 → 24.96 | 13.98 | 15 | FAIL |
| L5 → L6 | 29.37 → 23.58 | 5.80 | 20 | FAIL |
| L8 → L9 | 28.69 → 37.15 | -8.45 | 15 | FAIL |

L10 boss: V2 D 46.72, rank 1 of 10, cycle maximum: yes.

### Stress policy / provisional Frustration

| L | Stress completed | Stress stop | Failure progress | Dead placements | Choice opacity | Primary policies completed |
|---:|---|---|---:|---:|---:|---|
| 1 | no | no_legal_placement | 0.00 | 5 | 0.648 | 4/6 |
| 2 | yes | solved | — | 0 | 0.010 | 6/6 |
| 3 | no | no_legal_placement | 0.15 | 5 | 0.047 | 6/6 |
| 4 | yes | solved | — | 1 | 0.000 | 6/6 |
| 5 | no | no_legal_placement | 0.69 | 4 | 0.051 | 6/6 |
| 6 | yes | solved | — | 4 | 0.008 | 6/6 |
| 7 | yes | solved | — | 3 | 0.133 | 6/6 |
| 8 | yes | solved | — | 0 | 0.032 | 6/6 |
| 9 | no | no_legal_placement | 0.20 | 4 | 0.141 | 6/6 |
| 10 | no | no_legal_placement | 0.62 | 5 | 0.030 | 6/6 |

Frustration Risk stays PROVISIONAL_STAGE_A with no scalar; retry risk and session overrun remain UNSUPPORTED. Policy completion is not a human clear rate.
