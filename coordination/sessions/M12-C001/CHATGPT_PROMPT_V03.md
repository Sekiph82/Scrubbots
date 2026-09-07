# M12-C001 — Frozen Full-Surface Five-Slot Closure V03

Status: **ISSUED — FROZEN FINDING SET**

This supersedes M12 strict correction guidance before V03. Execute this V03
only.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/sessions/M12-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M12-C001/CHATGPT_STRICT_REAUDIT_V01.md
- prior M12 V01/V02 artifacts
- this prompt + V03 criteria

Expected Claude evidence:
`coordination/sessions/M12-C001/CLAUDE_LOG_V03.md`

Fix ONLY frozen:
- F-M12-STRICT-001
- F-M12-STRICT-002

## Mandatory carry-forward from the earlier M12 strict re-audit

The original M12 strict finding MUST remain explicitly covered. Do not let the
broader V03 attack-surface work dilute or replace it.

The pre-fix defect is:

```gdscript
var _palette_id: int = -1
```

combined with collection lookup that compares the requested palette directly
against every slot. On the unfixed implementation, a fresh/unconfigured system
can therefore make:

```gdscript
get_slots_by_palette_id(-1)
```

behave as if the invalid sentinel were a real color and return all five slot
identities.

Canonical requirement:

```text
UNCONFIGURED or INVALID COLOR
            ↓
           []
```

Never:

```text
INVALID -1 SENTINEL
        ↓
[0, 1, 2, 3, 4]
```

The direct regression sequence for F-M12-STRICT-001 is mandatory:

1. create a fresh SlotSystem;
2. prove is_configured() == false;
3. before configure:
   - get_slots_by_palette_id(-1) == [];
   - get_slots_by_palette_id(0) == [];
4. query at least two additional invalid/negative palette ids (for example -2
   and -999) and prove [];
5. perform a FAILED FIRST configure;
6. prove is_configured() is still false;
7. prove every scalar slot palette remains the -1 unconfigured sentinel;
8. after that failed first configure:
   - get_slots_by_palette_id(-1) == [];
   - get_slots_by_palette_id(0) == [];
9. successfully configure duplicate valid colors, for example
   [0, 0, 1, 1, 0];
10. prove duplicate valid palette support:
    - palette 0 -> exactly [0, 1, 4];
    - palette 1 -> exactly [2, 3];
11. query a non-present/high palette id such as 999 and prove [];
12. attempt a FAILED REconfigure;
13. prove the prior valid duplicate palette truth and query results are
    unchanged.

At least one test must be sensitivity-safe against the current pre-fix defect:
it must fail if unconfigured `-1` is still allowed to materialize the five
sentinel slots.

Do not implement M13+ gameplay behavior.

## 1. Fail-closed palette collection query

Harden get_slots_by_palette_id().

Canonical query contract:
- only an integer palette_id >= 0 is valid;
- system must be configured before a collection query can materialize slots;
- invalid/unconfigured query returns a fresh empty Array;
- invalid query never mutates any slot/system state.

Required:
- before configure, get_slots_by_palette_id(-1) == [];
- before configure, get_slots_by_palette_id(0) == [];
- -2 and another clearly negative integer also return [];
- after failed first configure, sentinel/valid collection queries remain [];
- after failed first configure, every scalar slot palette is still -1;
- after successful duplicate configuration, exact valid query identities and
  deterministic order are proven;
- a non-present/high integer palette query returns [];
- after failed reconfigure, prior valid duplicate palette query truth remains
  unchanged.

These checks are the explicit carry-forward of CHATGPT_STRICT_REAUDIT_V01 and
are mandatory even though V03 also closes the broader Variant boundary finding.

## 2. Arbitrary Variant query boundary

get_slots_by_palette_id is the M12 public untyped Variant seam.

It must reject unsupported types BEFORE any equality against SlotState palette
truth.

Direct inputs:
- null
- float 0.0
- float 1.0
- String
- bool false / true
- Vector2
- RefCounted.new()
- Array
- Dictionary

Every unsupported input:
- returns [];
- does not throw/fault;
- does not mutate configuration, palettes, availability or activity.

Do NOT coerce floats/numeric-looking Strings to integers.

Valid integer 0 remains distinct from invalid float 0.0 at the API contract.

## 3. Preserve valid duplicate query semantics

Use a configuration with duplicate valid palette IDs.

Prove:
- duplicates remain legal;
- get_slots_by_palette_id(valid_int) returns only matching slot IDs;
- returned order is deterministic ascending slot identity;
- returned Array is detached;
- mutating/clearing a returned Array cannot alter the next query result.

## 4. Configuration attack-surface regression

Preserve and directly test:
- exactly five entries;
- empty/4/6 entries rejected;
- nested invalid entry types fail closed before writes:
  null, float, String, bool, Vector2, RefCounted;
- negative integer rejected;
- palette ID == palette_size rejected;
- large out-of-range integer rejected;
- palette_size 0 rejected;
- negative palette_size rejected;
- failed FIRST configure leaves is_configured() false and all palette scalars at
  sentinel -1;
- failed REconfigure after valid state preserves:
  - is_configured() true;
  - all five palette IDs;
  - availability/activity state.

Do not retain/alias caller palette_ids Array:
- configure valid;
- mutate/clear caller Array afterward;
- SlotSystem palette truth remains unchanged.

## 5. Slot identity/state regression

Preserve:
- exactly five slots;
- stable slot IDs 0..4;
- invalid slot IDs negative/5/large return existing fail-closed results;
- availability and activity remain independent;
- operations on one slot do not change siblings;
- successful palette reconfigure does not silently reset availability/activity
  unless an existing locked M12 contract explicitly requires it.

## 6. Encapsulation regression

Preserve AL-020:
- no get_slot() method;
- no public query returns a SlotState object;
- all public identity/palette/availability/activity queries are scalar;
- independently-created SlotState mutation cannot affect SlotSystem-owned truth.

Do not redesign SlotState solely because standalone objects are mutable. The
protected invariant is SlotSystem-owned state.

## 7. Scope/architecture regression

Preserve:
- RefCounted model boundary;
- no UI/scene dependency;
- no dispatch;
- no target selection;
- no ReservationState ownership;
- no routing;
- no Scrubbot agent behavior;
- no GameplaySession ownership;
- no M13+ responsibility.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/STRICT_UPSTREAM_REPAIR_SEQUENCE_V01.md
- any CHATGPT_* file

Run and record individually:
- godot --version
- full headless suite
- git diff --check

Write:
`coordination/sessions/M12-C001/CLAUDE_LOG_V03.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
