# M12-C001 — Full Attack-Surface Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This supersedes M12-C001 CHATGPT_STRICT_REAUDIT_V01.md as the canonical
correction basis.

The locked full attack-surface rule in coordination/AUDIT_POLICY.md requires a
complete subsystem sweep and frozen finding set before a critical/stateful
correction prompt.

## Sweep scope

ChatGPT inspected:
- scripts/gameplay/slots/slot_system.gd;
- scripts/gameplay/slots/slot_state.gd;
- the complete existing M12 test block in tests/run_tests.gd;
- M12 task/spec/architecture boundaries;
- prior M12 prompt/audit/log artifacts;
- immediate later gameplay modules for consumer assumptions.

Godot is unavailable in the ChatGPT audit environment. Existing runtime evidence
remains E1/E2. Findings below are E3 source/contract inspection.

## Public surface reviewed

SlotSystem:
- constructor / fixed five-slot initialization;
- get_slot_count();
- is_configured();
- get_slot_id();
- configure();
- set_slot_available();
- set_slot_active();
- get_slot_palette_id();
- is_slot_available();
- is_slot_active();
- get_slots_by_palette_id().

SlotState was also inspected as an internal model. Its independently-created
instances are not canonical SlotSystem truth and the system no longer exposes
its owned SlotState references. The prior AL-020 encapsulation correction remains
accepted.

## Frozen findings

### F-M12-STRICT-001 — sentinel/unconfigured palette query is not fail-closed

Retained from CHATGPT_STRICT_REAUDIT_V01.

Each newly-created internal SlotState starts with palette id -1. Current
get_slots_by_palette_id() iterates every slot and compares the requested value
directly against that sentinel.

Therefore, before configuration:

`get_slots_by_palette_id(-1)`

materializes all five unconfigured slots as if -1 were a real gameplay color.

Required:
- unconfigured SlotSystem returns [] for palette collection queries;
- every negative palette id returns [];
- a failed first configure leaves the system unconfigured and cannot create
  sentinel-query matches;
- a failed reconfigure after a valid configuration preserves the prior valid
  query truth;
- duplicate valid palette support remains unchanged.

### F-M12-STRICT-002 — untyped palette query accepts/compares arbitrary Variant values

New full-surface finding.

get_slots_by_palette_id(palette_id) is a public untyped GDScript seam and performs
Variant equality directly:

`slot.get_palette_id() == palette_id`

Palette IDs are an integer domain everywhere else in M12.

Godot's GDScript comparison rules allow cross-type numeric equality (for example
1 == 1.0 is true) and some other cross-type comparisons can raise runtime
errors. Therefore an untyped query must not rely on Variant equality to define
its domain.

Material consequences:
- a float such as 0.0 can query integer palette 0 as if it were a valid ID;
- unsupported Variant classes are not explicitly rejected before comparison;
- the query contract is weaker than configure(), which validates integer
  palette IDs before use.

Required:
- get_slots_by_palette_id() accepts ONLY integer palette IDs >= 0;
- unsupported Variant classes fail closed to [] without runtime fault;
- direct adversarial inputs include null, float, String, bool, Vector2,
  RefCounted junk, Array and Dictionary;
- valid integer duplicate-color queries remain deterministic and correct.

Relevant locked learning:
- AL-053 arbitrary Variant boundary closure.

## Full-surface accepted / not reopened

No additional M12-owned material defect was found in:

### Configuration atomicity
- exactly five palette entries required;
- every entry is validated before any slot write;
- negative entry rejected;
- entry >= palette_size rejected;
- failed reconfiguration preserves prior slot palettes;
- duplicate valid palette IDs are allowed;
- input Array is not retained, so caller mutation after configure cannot alias
  slot truth.

### Fixed structure / identity
- exactly five SlotState objects are created internally;
- slot IDs remain 0..4;
- no public add/remove/resize API exists;
- public query API no longer returns internally owned SlotState references.

### Availability/activity
- availability and activity are independent scalar state;
- invalid typed slot IDs fail without mutation;
- palette configuration does not route/dispatch/select/animate.

### Query ownership
- get_slot_palette_id() returning -1 for invalid/unconfigured scalar lookup is a
  sentinel return value, not a collection materialization defect;
- get_slots_by_palette_id() returns a fresh Array, so caller mutation cannot
  mutate internal ownership;
- valid duplicate queries naturally preserve ascending stable slot order.

### Architecture boundary
- SlotSystem/SlotState remain RefCounted data models;
- no UI/scene dependency;
- no target selection, reservation, routing, agent, dispatcher or
  GameplaySession ownership was added;
- later dispatcher currently consumes color requests directly and does not
  depend on leaked SlotState objects.

### Typed public boundaries
get_slot_id(), set_slot_available(), set_slot_active(),
get_slot_palette_id(), is_slot_available() and is_slot_active() use typed
slot/value parameters. The arbitrary-Variant finding applies to the explicitly
untyped get_slots_by_palette_id seam.

## Frozen M12 finding set

Frozen to:
- F-M12-STRICT-001
- F-M12-STRICT-002

Affected tasks remain:
- SB-M12-005
- SB-M12-009
- SB-M12-011

No other M12 task is reopened.

Next:
`coordination/sessions/M12-C001/CHATGPT_PROMPT_V03.md`
