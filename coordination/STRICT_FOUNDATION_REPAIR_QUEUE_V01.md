# Strict Foundation Repair Queue V01

Status: **OPEN**

This queue records strict-v2 findings from the M10-M14 re-audit without blocking the currently sequenced M15 -> M16 -> M17 routing-contract repair chain where the finding is not a direct M16 dependency.

## Current state

- M10: AUDITED_PASS. No M10 task reopened.
- M11: CHANGES_REQUIRED. Reopen SB-M11-003/005/009/012.
- M12: CHANGES_REQUIRED. Reopen SB-M12-005/009/011.
- M13: CHANGES_REQUIRED. Reopen SB-M13-001/004.
- M14: CHANGES_REQUIRED. Reopen SB-M14-001/004/007/009.

## Cross-cutting BoardState validation finding

Current BoardState.set_cell_state(index, state: CellState) validates index but does not explicitly reject a non-canonical integer state before writing the PackedByteArray.

Because Godot is unavailable in the ChatGPT audit environment, whether the enum annotation itself prevents runtime injection of values such as 2/-1/255 is not independently executable here.

Before M19 receives a final strict audit, add a direct Godot adversarial test:
- valid index + state 2;
- valid index + state -1;
- valid index + state 255;
- expected: false/no mutation for every non-ACTIVE/non-CLEARED value.

If Godot accepts such values today, promote this from validation gap to a concrete M02 BoardState defect and repair it before vertical-slice work.

## Ordering rule

The existing routing-contract strict repair sequence may continue:
M15 -> M16 -> M17.

However, M11-M14 strict findings and the BoardState validation gap must be resolved before M19 is finally strict-audited and before M20 vertical-slice truth is accepted.
