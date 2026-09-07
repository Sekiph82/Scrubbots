# Strict Foundation Repair Queue V01

Status: **ACTIVE**

This queue records strict-v2 findings from the M10-M14 re-audit without blocking the currently sequenced M15 -> M16 -> M17 routing-contract repair chain where the finding is not a direct M16 dependency.

## Current state

- M10: AUDITED_PASS. No M10 task reopened.
- M11: AUDITED_PASS / STRICT_V2_FINAL_CLOSURE.
- M12: AUDITED_PASS / STRICT_V2_FINAL_CLOSURE.
- M13: CHANGES_REQUIRED / FINDING_SET_FROZEN. SB-M13-001/004 remain open.
- M14: CHANGES_REQUIRED. Reopen SB-M14-001/004/007/009.

## FOUNDATION-STRICT-001 — BoardState HIGH-RISK VALIDATION GAP

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

The locked full attack-surface rule governs foundation repairs. M11 is final-closed after its frozen full-surface correction + V06 adversarial validation. M12 is final-closed after its frozen correction and V04 validation pass. M13 has now received a fresh full subsystem sweep; its finding set is frozen to F-M13-STRICT-001..003 and `coordination/sessions/M13-C001/CHATGPT_PROMPT_V05.md` is READY. M14 remains blocked until M13 passes and then receives its own full-surface sweep.


## M11 V05 audit transition

- V05 implementation commit: `bcd4ac50df30df95fb11b87dd111ff865029cb10`.
- V05 audit: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**.
- Production source: no new material defect found in frozen F-M11-STRICT-001..005 implementation.
- Runtime: Claude reports 1835/1835 ALL PASS; ChatGPT Godot rerun unavailable.
- Remaining: sensitivity-safe direct tests for post-reset snapshot truth, preserved renderer binding/invalid-size configure blocking, renderer rebind palette isolation, and lifecycle reuse.
- M11 V06: **AUDITED_PASS / FINAL_CLOSED**.
- M12 V03: **CHANGES_REQUIRED / production source accepted; validation gaps**.
- M12 V04: **AUDITED_PASS / FINAL_CLOSED**.
- M13 V03: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**.
- M13 V04: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**.
- M13 V05: **READY**.
- M14: **BLOCKED_BY_PRECEDING_FOUNDATION_REPAIR**.


## M11 V06 final / M12 full-surface transition

- M11-C001 V06: **AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**.
- M11 re-closed: SB-M11-003/005/009/012.
- M12 full-surface sweep completed before correction prompt.
- M12 frozen findings: F-M12-STRICT-001/002.
- M12-C001 V03: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**.
- M12-C001 V04: **AUDITED_PASS / FINAL_CLOSED**.
- M13/M14 remain blocked.
- M19 remains audit-blocked until the entire foundation queue and BoardState validation gap close.


## M12 V03 audit transition

- V03 implementation commit: `42396cc413021dc3e94fe8e0eeef7f4986c1d56b`.
- V03 audit: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**.
- Production F-M12-STRICT-001/002 source accepted.
- Remaining: direct runtime proof for nested malformed configure entries, palette_size <= 0, reconfigure state preservation, caller Array alias isolation, standalone SlotState isolation, and complete malformed-query no-mutation state.
- M12 V04: **READY**.
- M13/M14: **BLOCKED_BY_PRECEDING_FOUNDATION_REPAIR**.


## M12 V04 final / M13 full-surface transition

- M12-C001 V04: **AUDITED_PASS / STRICT_V2_FINAL_CLOSURE**.
- M12 re-closed: SB-M12-005/009/011.
- M13 full-surface sweep completed before correction prompt.
- M13 frozen findings: F-M13-STRICT-001/002/003.
- M13-C001 V03: **READY**.
- M14 remains blocked.
- FOUNDATION-STRICT-001 remains open and separate.
- M19 remains audit-blocked until foundation queue + BoardState validation gap close.


## M13 V03 audit transition

- V03 implementation commit: `50f1f6c2b9d5f2bab082de2a8ada0c6d548cb4a6`.
- V03 audit: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**.
- F-M13-STRICT-002/003 source accepted.
- F-M13-STRICT-001 remains open: bind(null) stale state, live sync dependency return drift, return-contract test gaps, and lifecycle-risk Object acceptance.
- M13 V04: **READY**.
- M14: **BLOCKED_BY_PRECEDING_FOUNDATION_REPAIR**.
- FOUNDATION-STRICT-001 remains separate/open.


## M13 V04 audit transition

- V04 implementation commit: `227fd9a1e3fd050ddffb424fa0e6d088cc5bbd1b`.
- V04 audit: **CHANGES_REQUIRED / FROZEN_SET_REMAINS_OPEN**.
- F-M13-STRICT-001 remains open for indexed-domain contradiction handling and >3481 dependency count rejection.
- M13 V05: **READY**.
- M14: **BLOCKED_BY_PRECEDING_FOUNDATION_REPAIR**.
- FOUNDATION-STRICT-001 remains separate/open.
