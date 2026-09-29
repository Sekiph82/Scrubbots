# M32-C002 measurement report: board-resolution-independent Scrubbot size

## A. Real production GameplayScreen, one fixed 1080x2160 viewport (focused suite s0)

Seam: `GameplayScreen._layout_board` computes `reference_32_display_cell` with the same rail-loop fit (`_board_display_cell(rr, 32, 32)`) in the same baked rail region. It passes that to `BoardPresentation.set_scrubbot_reference_display_cell()`.

- compensation = reference display cell / (renderer integer cell × presentation scale)
- local span = 2.4 × compensation
- displayed body = 2.4 × reference display cell × shell scale

| board | renderer cell px | pres. scale | display cell px | ref32 display cell px | compensation | local body span (cells) | measured body px | delta vs 32x32 | echo px | pre-C002 body px (delta) |
|---|---|---|---|---|---|---|---|---|---|---|
| 32x32 production L2 apple (REFERENCE) | 24 | 1.0181 | 24.434 | 24.434 | 1.0000 | 2.4000 | 58.64 | +0.000% | 51.31 | 58.6 (+0.0%) |
| 20x20 production L1 hazard bot | 36 | 1.0045 | 36.162 | 24.434 | 0.6757 | 1.6216 | 58.64 | +0.000% | 51.31 | 86.8 (+48.0%) |
| 38x38 production L3 palm tree | 21 | 1.0012 | 21.025 | 24.434 | 1.1622 | 2.7892 | 58.64 | +0.000% | 51.31 | 50.5 (-14.0%) |
| 59x59 TEST stripe | 14 | 1.0090 | 14.126 | 24.434 | 1.7297 | 4.1514 | 58.64 | +0.000% | 51.31 | 33.9 (-42.2%) |
| 59x40 TEST rect (width-limited) | 14 | 1.0281 | 14.393 | 24.434 | 1.6976 | 4.0743 | 58.64 | +0.000% | 51.31 | 34.5 (-41.1%) |
| 24x40 TEST rect (height-limited) | 20 | 1.0458 | 20.916 | 24.434 | 1.1682 | 2.8037 | 58.64 | +0.000% | 51.31 | 50.2 (-14.4%) |
| 100x100 TEST synthetic (not production; screen-only) | 8 | 1.0763 | 8.610 | 24.434 | 2.8378 | 6.8108 | 58.64 | +0.000% | 51.31 | 20.7 (-64.8%) |

Why the local spans differ from the prompt's approximate figures (1.5 / 2.85 / 4.425 / 7.5):

- The prompt's figures assume display cell ∝ 1/N.
- The real screen fits the board **plus its rail loop** (N + 5 cells) into the baked rail region. It then floors the renderer cell and applies a small fractional presentation scale.
- The implementation derives the span from that actual geometry, so the displayed size matches the 32x32 reference exactly (delta 0.000%). No span is tuned per board size.

## B. Standalone BoardPresentation, same generic 800x820 rect (s1/s3)

Default seam when no screen reports a reference: reference = floor(min(rect/32)), compensation = reference / renderer cell.

| board | limited by | cell px | ref32 px | compensation | local span (cells) | naive 2.4·N/32 | measured body px | delta | pre-C002 px (delta) |
|---|---|---|---|---|---|---|---|---|---|
| 20x20 | width | 40 | 25 | 0.6250 | 1.5000 | 1.500 | 60.00 | +0.000% | 96.0 (+60.0%) |
| 32x32 | width | 25 | 25 | 1.0000 | 2.4000 | 2.400 | 60.00 | +0.000% | 60.0 (-0.0%) |
| 38x38 | width | 21 | 25 | 1.1905 | 2.8571 | 2.850 | 60.00 | +0.000% | 50.4 (-16.0%) |
| 59x59 | width | 13 | 25 | 1.9231 | 4.6154 | 4.425 | 60.00 | +0.000% | 31.2 (-48.0%) |
| 59x24 | width | 13 | 25 | 1.9231 | 4.6154 | 4.425 | 60.00 | +0.000% | 31.2 (-48.0%) |
| 24x59 | height | 13 | 25 | 1.9231 | 4.6154 | 4.425 | 60.00 | +0.000% | 31.2 (-48.0%) |
| 40x24 | width | 20 | 25 | 1.2500 | 3.0000 | 3.000 | 60.00 | +0.000% | 48.0 (-20.0%) |
| 24x40 | height | 20 | 25 | 1.2500 | 3.0000 | 3.000 | 60.00 | +0.000% | 48.0 (-20.0%) |
| 100x100 (TEST synthetic) | width | 8 | 25 | 3.1250 | 7.5000 | 7.500 | 60.00 | +0.000% | 19.2 (-68.0%) |

Generic sweep: 140 (w, h, rect) presentations, compensation equal to floor-ref / floor-cell every time (0 mismatches). The 20x20 local span changes with the rect ((1400.0, 1000.0) → 1.4880, (333.0, 517.0) → 1.5000, (700.0, 900.0) → 1.4400, (800.0, 820.0) → 1.5000), which shows it is geometry-derived and not a per-size table.

## C. Live relayout (s4, real host, production L3 38x38, same agent)

| | viewport | ref32 display cell px | local span (cells) | displayed body px |
|---|---|---|---|---|
| before | 1080x2160 | 24.434 | 2.7892 | 58.64 |
| after | 1536x2048 | 23.167 | 2.7892 | 55.60 |

Across the relayout:

- the same agent instance, route, progress and board-local position survive;
- the body re-sizes through the visual's own frame update (generation compare);
- the same shared texture object is kept;
- the agent then continues to arrival.

## D. Retire echo (s6, standalone rect)

| board | echo px | live px | echo/live | compensation |
|---|---|---|---|---|
| 32x32 | 52.50 | 60.00 | 0.8750 | 1.0000 |
| 20x20 | 52.50 | 60.00 | 0.8750 | 0.6000 |
| 38x38 | 52.50 | 60.00 | 0.8750 | 1.1667 |
| 59x59 | 52.50 | 60.00 | 0.8750 | 1.9091 |
| 59x24 | 52.50 | 60.00 | 0.8750 | 1.9091 |
| 100x100 | 52.50 | 60.00 | 0.8750 | 3.0000 |

Target ratio 2.1/2.4 = 0.8750. The echo is placed at the exact cleared-cell centre. Unchanged: lifetime 0.28 s, shrink 0.5, cap 16. A mid-echo relayout rescales the echo through the same seam.

## E. Performance (s7, 59x59, 30 live visuals)

- Steady animate: 38.2 µs/frame for 30 visuals.
- First frame after a relayout: 83.0 µs.
- Object count stable over 600 frames (1858 → 1858).
- One shared texture.
- The per-frame cost is one integer generation compare per visual. There is no scene-tree scan.

## F. Screenshot measurements (non-headless snapshot tool, real gameplay at 2x + static lineup probes)

| shot | viewport | display cell px | ref32 display cell px | compensation | local span | expected body px | measured live bodies px (all) |
|---|---|---|---|---|---|---|---|
| m32c002_20x20_L1_hazard_bot_1080x2160 | 1080x2160 | 36.162 | 24.434 | 0.6757 | 1.6216 | 58.64 | 58.64 (4 agents) |
| m32c002_32x32_L2_apple_REFERENCE_1080x2160 | 1080x2160 | 24.434 | 24.434 | 1.0000 | 2.4000 | 58.64 | 58.64 (18 agents) |
| m32c002_38x38_L3_palm_tree_1080x2160 | 1080x2160 | 21.025 | 24.434 | 1.1622 | 2.7892 | 58.64 | 58.64 (4 agents) |
| m32c002_59x59_TEST_stripe_1080x2160 | 1080x2160 | 14.126 | 24.434 | 1.7297 | 4.1514 | 58.64 | 58.64 (87 agents) |
| m32c002_rect_59x40_TEST_width_limited_1080x2160 | 1080x2160 | 14.393 | 24.434 | 1.6976 | 4.0743 | 58.64 | 58.64 (81 agents) |
| m32c002_rect_24x40_TEST_height_limited_1080x2160 | 1080x2160 | 20.916 | 24.434 | 1.1682 | 2.8037 | 58.64 | 58.64 (51 agents) |
| m32c002_synthetic_100x100_TEST_screen_only_1080x2160 | 1080x2160 | 8.610 | 24.434 | 2.8378 | 6.8108 | 58.64 | 58.64 (4 agents) |
| m32c002_relayout_BEFORE_38x38_1080x2160 | 1080x2160 | 21.025 | 24.434 | 1.1622 | 2.7892 | 58.64 | 58.64 (4 agents) |
| m32c002_relayout_AFTER_38x38_tablet_1536x2048 | 1536x2048 | 19.934 | 23.167 | 1.1622 | 2.7892 | 55.60 | 55.60 (4 agents) |
