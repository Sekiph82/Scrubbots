# M28-C002-C002-R01 — OWNER VISUAL REVIEW V01

Date: 2026-09-28
Status: **prepared for owner review, not owner-accepted.** Claude only reports what it observed in the renders.

## How the renders were made

- **Harness:** `tests/tools/gameplay_v02_snapshot.gd`, using real production paths:
  - the real app root, launching from the frontier with the owner-approved First 10 click plans;
  - for the 5-col shell, a real host with the M23 generator `column_count = 5`.
- **2x:** bought through the real 2x popup, as current-level 2x.
- **+1 Slot:** activated through the real booster request.
- **Code:** the final code of this cycle. The harness rejects any render whose shell id or terminal state is wrong; none were rejected.

## Screenshots

| # | Prompt item | File |
|---|---|---|
| 1 | Active cleaning 1x, 2.4-cell Scrubbots | [r01_5slot_3col_L2_cleaning_1x_1080x2160.png](evidence/r01_5slot_3col_L2_cleaning_1x_1080x2160.png) |
| 2 | Active cleaning 2x | [r01_5slot_3col_L2_cleaning_2x_1080x2160.png](evidence/r01_5slot_3col_L2_cleaning_2x_1080x2160.png) |
| 3 | Dense multi-agent (40 moving) | [r01_5slot_3col_L2_dense_agents_1080x2160.png](evidence/r01_5slot_3col_L2_dense_agents_1080x2160.png) |
| 4 | Short phone 1080×1920, touch-target-safe layout | [r01_5slot_3col_L3_short_phone_touch_1080x1920.png](evidence/r01_5slot_3col_L3_short_phone_touch_1080x1920.png) |
| 5 | Speech bubble 1080×2160 | [r01_5slot_3col_L2_bubble_1080x2160.png](evidence/r01_5slot_3col_L2_bubble_1080x2160.png) |
| 6 | Speech bubble 1080×1920 | [r01_5slot_3col_L3_bubble_short_1080x1920.png](evidence/r01_5slot_3col_L3_bubble_short_1080x1920.png) |
| 7 | Tablet portrait 1536×2048 | [r01_5slot_3col_L1_tablet_1536x2048.png](evidence/r01_5slot_3col_L1_tablet_1536x2048.png) |
| 8 | +1 Slot six-slot state | [r01_6slot_3col_L2_plus_one_1080x2160.png](evidence/r01_6slot_3col_L2_plus_one_1080x2160.png) |
| extra | Small board (20×20) cleaning | [r01_5slot_3col_L1_cleaning_small_board_1080x2160.png](evidence/r01_5slot_3col_L1_cleaning_small_board_1080x2160.png) |
| extra | Large board (38×38) cleaning | [r01_5slot_3col_L3_cleaning_large_board_1080x2160.png](evidence/r01_5slot_3col_L3_cleaning_large_board_1080x2160.png) |
| extra | 5-column shell bubble | [r01_5slot_5col_L1gen_bubble_1080x2160.png](evidence/r01_5slot_5col_L1gen_bubble_1080x2160.png) |

## Items for the owner

### R01-A: mini Scrubbots at 2.4 cells (was 1.8)

- The bots are clearly larger than the C002 baseline in every cleaning render.
- On the 32×32 apple (#1, #2), each bot is about 58 px tall on screen. Face, visor and leaf are readable on the rail and on the connectors.
- **Dense state (#3, 40 moving):** bots overlap where queues bunch at connector joins and along the bottom board edge. Each silhouette is still individually recognisable, and the rail stays readable between groups.
- **2x (#2):** same readability, with the 2x button showing its active green state.
- **Size is cell-relative, so it varies by board:**
  - 20×20 board: roughly 70 px, very prominent.
  - 38×38 board (#4, large-board extra): roughly 45 px. This is the smallest case and still readable.
- **Owner check:** whether 2.4 cells is right on the largest boards. On a 59-cell board the bots will be proportionally smaller still.

### Retire echo at 2.1 cells (was 1.6)

- The echo keeps the previous ~0.88 echo/live proportion. It is a short 0.28 s shrink-fade at the cleared cell.
- Screenshots do not capture it reliably. The test proves the span over 13,310 sampled real echoes.

### R01-B: live bubble text

- **Copy:**
  - Headline: "LET'S CLEAN THIS MESS!" (bold navy)
  - Instruction: "Tap a batch below to send the Scrubbots." (smaller navy)
- Both strings come from `UiText`. The obsolete baked sentence is masked; no fragment of it shows in any render.
- **1080×2160 (#5):** fonts 21/18 px. Well inside the bubble with comfortable margins.
- **1080×1920 (#6):** fonts 18/15 px.
  - Inspected at 3× zoom: both lines are fully inside the bubble, crisp, and legible, with clear hierarchy.
  - 15 px is the smallest text on this screen. **Owner check:** whether it is large enough on a physical short phone.
- **Tablet (#7) and 5-col (extra):** fits, with the same wrapping.
- **Six-slot (#8):** identical to five-slot. An earlier draft render showed crowded, oversized text after the +1 Slot switch. That was fixed (matrix §4.1) and re-rendered.
- **Owner check:** the copy wording. It is candidate copy, and polishing it would not change gameplay.

### S2-B: invisible touch targets

- Visuals are unchanged: the supply cells in #4 look exactly like C002.
- At 1080×1920 every front hitbox is ≥ 88 px. Hitboxes are invisible and never overlap, and the preview rows stay non-interactive.
- Painted cell sizes: 3-col 89 × 83, 4-col ~88, 5-col ~82 px.
- Nothing to see in a screenshot; the proof is in the tests (matrix §1 C1/C2).

### S3-B: AD placeholder hidden

- No AD band or label appears in any render. The bottom band shows only the master's own art.
- The reserved region still exists in the layout (invisible) as the M57 anchor.

### S6-C: square-board production gate

- The production catalog now rejects a non-square level with an explicit S6-C reason. All First 10 levels are square and load unchanged.
- The generic rectangular engine is untouched.
- Not visible in screenshots.

### Six master hashes

- All six SHA-256 values are re-verified against the owner doc (matrix §5); the master PNGs have no git diff.
- Every render shows the baked shell unchanged: rails, connectors, frames and Scrubby. #8 uses the 6-slot 3-col master.

### S1-A, S4-A, S5-A

- Preserved and unchanged: navy pillarbox on the tablet (#7), native Pause glyph with live 2x, cyan front edge, dimmed previews, cyan edge on ACTIVE slots.

## Not claimed

No owner acceptance. Final acceptance of R01-A and R01-B rests with the owner reviewing #1, #2 and #5/#6.
