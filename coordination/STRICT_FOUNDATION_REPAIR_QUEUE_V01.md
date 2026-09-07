# Strict Foundation Repair Queue V01

Status: **ACTIVE**

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


## Full-surface transition

The locked full attack-surface rule governs foundation repairs. M11 received a full subsystem sweep and frozen finding set. V05 production hardening was source-accepted, but its strict-v2 adversarial tests had direct-observability/sensitivity gaps. READY: `coordination/sessions/M11-C001/CHATGPT_PROMPT_V06.md` (validation-only closure pass). M12-M14 remain blocked until each receives its own full-surface sweep and the preceding repair passes.


## M11 V05 audit transition

- V05 implementation commit: `bcd4ac50df30df95fb11b87dd111ff865029cb10`.
- V05 audit: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**.
- Production source: no new material defect found in frozen F-M11-STRICT-001..005 implementation.
- Runtime: Claude reports 1835/1835 ALL PASS; ChatGPT Godot rerun unavailable.
- Remaining: sensitivity-safe direct tests for post-reset snapshot truth, preserved renderer binding/invalid-size configure blocking, renderer rebind palette isolation, and lifecycle reuse.
- M11 V06: **READY**.
- M12/M13/M14: **BLOCKED_BY_PRECEDING_FOUNDATION_REPAIR**.
