# OWNER_SUPPLY_COLUMNS_3_4_5_PREVIEW3_V01

Status: OWNER APPROVED
Date: 2026-10-01

## Decision

Shipping supply plans and gameplay must support exactly:
- 3 columns;
- 4 columns;
- 5 columns.

Visible preview depth is fixed at:
- 3 rows.

No automatic column-count selection rule is authorized here.

Level Factory may explicitly choose 3, 4, or 5 columns for a level. Default remains 3 until changed by owner.

## Existing compatible game foundations

The current game already supports the core behavior:
- `BatchSupplyEngine.MIN_COLUMNS = 3`
- `BatchSupplyEngine.MAX_COLUMNS = 5`
- `BatchSupplyPanel.MIN_COLUMNS = 3`
- `BatchSupplyPanel.MAX_COLUMNS = 5`
- `BatchSupplyPanel` renders exactly three visible rows.

Therefore this task must not redesign the supply engine or panel.

## Required correction

The current `SupplyPlanLoader` still hard-locks `COLUMN_COUNT := 3`.

Replace that fixed-three plan admission rule with:
- accepted columnCount in `3..5`;
- plan columns array size must equal its declared columnCount;
- engine creation uses that declared validated column count;
- visiblePreviewDepth must equal exactly `3`.

All existing 3-column plans remain valid and unchanged.

## Slot/booster boundary

This decision does not alter slot count.

Canonical level-generation/solver acceptance remains baseline five slots.

The +1 Slot booster is runtime assistance and must not become a prerequisite or generation input.
