# M12-C001 — Strict Re-Audit V01

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Strict-v2 inspection confirms the prior mutable SlotState leak remains fixed, but finds a fail-closed query defect.

Godot is not available in the ChatGPT audit environment. Existing green runtime results remain E1/E2; the finding below is E3 source inspection.

## Accepted prior correction

SlotSystem no longer exposes internally owned mutable SlotState objects. Palette writes remain controlled by validated configure().

## F-M12-STRICT-001 — sentinel palette -1 is queryable as if it were a real color

Severity: **material fail-closed query defect**

Each new SlotState starts with palette id -1 as the unconfigured sentinel.

Current get_slots_by_palette_id(palette_id) simply compares the supplied value against every slot's current palette id. Before configuration, get_slots_by_palette_id(-1) therefore matches all five unconfigured slots.

An invalid/sentinel palette query must not materialize five matching gameplay slots.

Required correction:
- get_slots_by_palette_id() fails closed when the system is unconfigured;
- negative palette ids return an empty result;
- failed configure must not create sentinel-query matches or corrupt prior configured truth;
- preserve duplicate valid palette support;
- add direct before-configure / after-failed-configure / negative-id adversarial tests.

Affected:
- SB-M12-005
- SB-M12-009
- SB-M12-011

## Strict task state

Reopen:
- SB-M12-005
- SB-M12-009
- SB-M12-011

Other M12 tasks remain accepted.
