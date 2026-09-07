# M12-C001 — Strict V03 Evidence Hardening V04

Status: **ISSUED — VALIDATION-ONLY CLOSURE PASS**

This continues the SAME frozen M12 production finding set:
- F-M12-STRICT-001
- F-M12-STRICT-002

Do not add or redesign M12 gameplay semantics.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/sessions/M12-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md
- coordination/sessions/M12-C001/CHATGPT_PROMPT_V03.md
- coordination/sessions/M12-C001/CHATGPT_AUDIT_CRITERIA_V03.md
- coordination/sessions/M12-C001/CLAUDE_LOG_V03.md
- coordination/sessions/M12-C001/CHATGPT_AUDIT_V03.md
- this prompt + V04 criteria

Expected Claude evidence:
`coordination/sessions/M12-C001/CLAUDE_LOG_V04.md`

## Objective

Close the strict-v2 direct-observability gaps left by V03.

The V03 production implementation in SlotSystem is currently source-accepted.

**Do not modify production SlotSystem/SlotState code unless one of the new V04
tests first exposes a real defect.** If a strengthened test fails against
production, document:
- exact failing test;
- observed behavior;
- minimal frozen-scope production fix.

Do not implement M13+ behavior.

## 1. Preserve V03 sentinel and Variant regressions

Keep all M12-19/20/21 coverage green, including the mandatory pre-fix-sensitive
check:

```text
fresh system
get_slots_by_palette_id(-1)
→ []
```

Preserve:
- unconfigured valid/negative collection queries -> [];
- failed first configure -> unconfigured + scalar palette sentinels remain -1;
- duplicate valid query truth;
- high/non-present integer -> [];
- failed reconfigure query preservation;
- null/float/String/bool/Vector2/RefCounted/Array/Dictionary query rejection;
- detached returned collection Array.

## 2. Nested malformed configure entries

Use a fresh SlotSystem for each case or otherwise prove atomic state isolation.

Directly call configure() with exactly five entries where ONE nested entry is:
- null;
- float 1.0;
- String "1";
- bool true;
- Vector2(1, 1);
- RefCounted.new().

For every case prove:
- configure returns failure;
- is_configured() remains false on first-configure tests;
- every slot palette scalar remains -1;
- no availability/activity mutation occurs.

Then run at least one malformed nested-entry attempt AFTER a valid configuration
with non-default availability/activity markers and prove:
- configure fails;
- is_configured() stays true;
- all five palette IDs preserved;
- availability/activity markers preserved.

## 3. palette_size boundary

Directly prove on a fresh system:
- configure([0,1,2,3,4], 0) fails atomically;
- configure([0,1,2,3,4], -1) fails atomically.

For both:
- is_configured() remains false;
- all five palettes remain -1.

Preserve existing ==palette_size and large out-of-range coverage.

## 4. Failed reconfigure preserves all owned state

Create a valid configured system.

Before the failed reconfigure:
- set at least one slot unavailable;
- set at least one different slot active;
- snapshot all five palette IDs;
- snapshot all five availability values;
- snapshot all five activity values.

Perform at least:
- wrong-count failed reconfigure;
- invalid nested-type failed reconfigure.

After EACH failure prove:
- is_configured() == true;
- every palette unchanged;
- every availability unchanged;
- every activity unchanged;
- valid collection-query truth unchanged.

## 5. Successful reconfigure preserves availability/activity

Create valid configuration and non-default state markers.

Perform a second VALID palette configuration.

Prove:
- new palette IDs take effect;
- is_configured() remains true;
- availability markers are unchanged;
- activity markers are unchanged;
- slot IDs remain 0..4.

This must distinguish palette reconfiguration from slot runtime state.

## 6. Caller Array alias isolation

Use a caller-owned Array variable:

```gdscript
var ids = [0, 1, 2, 3, 4]
system.configure(ids, ...)
```

After successful configure:
- overwrite entries in ids;
- clear ids;
- append junk.

Prove:
- all five SlotSystem palette IDs remain the configured originals;
- valid collection query truth remains original;
- is_configured() remains true.

## 7. Standalone SlotState isolation

Create:
- one SlotSystem with valid configuration;
- one independent SlotState.new(...).

Mutate the standalone SlotState palette/availability/activity aggressively.

Prove SlotSystem:
- slot identities unchanged;
- all five palettes unchanged;
- availability/activity unchanged;
- collection query truth unchanged.

Also preserve:
- get_slot() absent;
- no public query exposes the owned SlotState objects.

## 8. Complete malformed-query no-mutation proof

On a configured SlotSystem, first set non-default state:
- one slot unavailable;
- a different slot active.

Snapshot:
- configured flag;
- all five palette IDs;
- all five availability values;
- all five activity values.

Run the complete invalid collection-query input set:
- null;
- float;
- String;
- bool;
- Vector2;
- RefCounted;
- Array;
- Dictionary;
- negative integer.

After the full set, prove every snapshot value remains identical.

## 9. Regression / architecture

Preserve the complete M12 contract:
- exactly five slots;
- stable IDs 0..4;
- duplicate valid palette IDs;
- invalid slot-id semantics;
- availability/activity independence;
- no mutable internal SlotState leakage;
- RefCounted model boundary;
- no UI;
- no dispatch;
- no target selection;
- no ReservationState ownership;
- no routing;
- no agent behavior;
- no GameplaySession ownership;
- no M13+ responsibility.

Run the FULL root suite, not only M12 tests.

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
`coordination/sessions/M12-C001/CLAUDE_LOG_V04.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
