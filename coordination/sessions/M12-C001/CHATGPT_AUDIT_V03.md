# M12-C001 — ChatGPT Independent Audit V03

Decision: **CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**

Audited implementation commit:
`42396cc413021dc3e94fe8e0eeef7f4986c1d56b`

Active prompt:
`coordination/sessions/M12-C001/CHATGPT_PROMPT_V03.md`

Criteria:
`coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

Claude evidence:
`coordination/sessions/M12-C001/CLAUDE_LOG_V03.md`

Frozen basis:
`coordination/sessions/M12-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`

Audit policy:
`coordination/AUDIT_POLICY.md`

## Independence / runtime disclosure

Claude reports Godot 4.7.1 and **1914 / 1914 ALL PASS**. This is E1/E2 runtime
evidence.

Godot is not installed in the ChatGPT audit environment, so the suite was not
independently rerun. ChatGPT independently inspected the exact implementation
commit, production SlotSystem source and the complete M12 test block as E3
source/diff evidence.

## Production implementation review

No new material production-code defect was found in the V03 implementation.

The hardened collection query now:
- requires the system to be configured;
- accepts only TYPE_INT;
- rejects negative integers;
- returns a fresh [] for unsupported Variant classes;
- scans only after those gates;
- returns a fresh result Array.

This source shape closes the production implementation for:
- F-M12-STRICT-001 sentinel/unconfigured collection materialization;
- F-M12-STRICT-002 arbitrary Variant query boundary.

The mandatory carry-forward test for the old defect is present and
sensitivity-safe: on the pre-fix implementation, fresh
`get_slots_by_palette_id(-1)` would produce all five sentinel slots, so
M12-19 would fail.

## Frozen finding review

### F-M12-STRICT-001 — production CLOSED

Directly covered by V03:
- fresh system unconfigured;
- -1 / 0 / -2 / -999 queries return [];
- failed first configure leaves unconfigured truth and all five scalar palettes
  at -1;
- -1 and 0 still return [] after failed first configure;
- duplicate valid configure [0,0,1,1,0] succeeds;
- exact query truth 0->[0,1,4], 1->[2,3];
- high/non-present integer query returns [];
- failed reconfigure preserves duplicate query truth.

### F-M12-STRICT-002 — production CLOSED

Directly covered by V03:
- null;
- float 0.0 / 1.0;
- String;
- bool false / true;
- Vector2;
- RefCounted;
- Array;
- Dictionary

all fail closed to [] on a configured system. Valid integer 0 remains functional.
Returned query Array mutation is also directly proven detached.

## Strict-v2 evidence gaps

The V03 prompt/criteria intentionally included a broader post-fix attack-surface
regression so M12 could final-close in one pass. Claude added M12-19/20/21 but
left several explicit V03 criteria without direct adversarial proof.

A green full suite does not satisfy criteria that the suite never executes.

### GAP-M12-V03-001 — nested invalid configure entry types not directly tested

Criteria 26..31 require atomic rejection for nested:
- null;
- float;
- String;
- bool;
- Vector2;
- RefCounted.

Existing M12 tests directly cover wrong count, negative integer and out-of-range
integer, but none of the six required malformed nested entry classes.

Production source appears safe because it checks `pid is int` before numeric
range comparison, but Strict Audit Standard v2 requires direct runtime proof for
this public validation seam.

### GAP-M12-V03-002 — palette_size zero/negative not directly tested

Criteria 35 and 36 require:
- palette_size == 0 rejected;
- palette_size < 0 rejected.

Existing tests do not exercise either case.

Production source appears to reject both through the out-of-range condition, but
the behavior must be directly observed.

### GAP-M12-V03-003 — reconfigure/state preservation matrix incomplete

Criteria require direct proof that:
- failed reconfigure preserves availability/activity;
- successful valid reconfigure does not silently reset availability/activity.

Existing M12-13 proves palette preservation after failed reconfigure.
Existing M12-05..07 prove availability/activity independently.
Those are separate scenarios and do not prove state preservation THROUGH
reconfiguration.

### GAP-M12-V03-004 — caller configure Array alias isolation not directly tested

Criterion 40 requires:
1. configure from a caller-owned Array;
2. mutate/clear that Array afterwards;
3. prove all SlotSystem palette truth remains unchanged.

No current M12 test performs this sequence.

Production source appears not to retain the input Array, but this ownership
property needs direct proof.

### GAP-M12-V03-005 — standalone SlotState isolation not directly tested

Criterion 49 requires an independently-created SlotState mutation to be unable to
affect SlotSystem-owned truth.

The prior encapsulation correction proves the system does not expose its owned
SlotState through get_slot(), but there is no direct standalone isolation test.

### GAP-M12-V03-006 — invalid query no-mutation proof is partial

M12-20 proves configured truth and slot-0 palette survive malformed collection
queries, but the V03 prompt explicitly required malformed queries not to mutate:
- configuration;
- palettes;
- availability;
- activity.

The test should establish non-default availability/activity markers and all-five
palette truth before the bad-input loop, then prove the complete markers remain
unchanged afterwards.

## Scope/governance

Commit 42396cc changes only:
- scripts/gameplay/slots/slot_system.gd;
- tests/run_tests.gd;
- matching CLAUDE_LOG_V03.md.

Claude did not modify tasks.md, H!veAI, SESSION_INDEX, AUDIT_INDEX, strict queue
or ChatGPT-owned artifacts, and stopped at AWAITING_AUDIT.

No M13+ behavior was added.

## Verdict

**CHANGES_REQUIRED / VALIDATION_HARDENING_REQUIRED**

Do not add a new frozen production finding. The production implementation for
F-M12-STRICT-001/002 is source-accepted.

Keep open:
- SB-M12-005
- SB-M12-009
- SB-M12-011

Canonical progress remains:
- Ecosystem: **269 / 943 = 28.53%**
- Main + UI: **269 / 719 = 37.41%**
- Level Factory: **0 / 112**
- Content Pipeline: **0 / 112**

Next:
`coordination/sessions/M12-C001/CHATGPT_PROMPT_V04.md`

V04 is an auditor-authored validation-hardening pass. Production SlotSystem
source should remain unchanged unless a strengthened test exposes a real defect.
