---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit
cycleId: M12-C001
version: 1
createdAt: 2026-09-05T10:57:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M12
taskRefs:
  - SB-M12-003
  - SB-M12-005
  - SB-M12-009
  - SB-M12-010
  - SB-M12-011
auditedImplementationHead: 49bcabe4b55fe53a2757c414f11c0dcb7fd44cfd
---

# SCRUBBOTS - M12-C001 ChatGPT Independent Audit V01

## Decision

`CHANGES_REQUIRED`

The core M12 design is otherwise sound: SlotState/SlotSystem are lightweight
RefCounted models, the five-slot invariant exists, duplicate palette IDs are
correctly allowed, availability/activity are independent, UI/dispatch/target/
routing scope was respected, and Claude reported 667/667 checks passing.

ChatGPT independently inspected the GitHub implementation diff, SlotState,
SlotSystem, M12 tests, task truth and H!ve/coordination state. ChatGPT did not
execute the owner's local Godot binary; Claude's 667/667 total remains E1/E2
implementation evidence.

## Finding

### F-M12-001 - MEDIUM - Mutable SlotState reference bypasses SlotSystem palette validation

`SlotSystem.get_slot(slot_id)` returns the actual internal `SlotState`
instance owned by the system.

That object exposes public mutators including:

`set_palette_id(palette_id)`

Therefore a caller can do the equivalent of:

`system.get_slot(0).set_palette_id(999)`

and bypass all validation performed by:

`SlotSystem.configure(palette_ids, palette_size)`.

The system can then report itself as configured while containing a palette ID
that was never validated against the authoritative palette boundary.

The current tests prove that `configure()` rejects invalid IDs, but they do
not test mutation through the object reference returned by `get_slot()`.
This makes the validated-palette invariant externally bypassable.

This also weakens the query-API claim: `get_slot()` is not merely a query;
it leaks a mutable internal gameplay-truth object.

## Required correction

Preserve the current architecture and five-slot semantics, but close mutable
internal-state leakage.

The public SlotSystem query surface must not return a mutable internal
SlotState reference that lets callers bypass SlotSystem validation/mutation
rules.

Acceptable patterns include, for example:

- scalar/query methods such as slot ID / palette ID / availability / activity;
- a detached read-only-style snapshot/value object that cannot mutate the
  internally owned state;
- another simple Godot-native approach that preserves encapsulation.

Do not add needless abstraction.

After the correction:

1. palette IDs inside SlotSystem must only change through a validated
   SlotSystem-owned path;
2. caller-facing query access must not expose internal mutable SlotState;
3. exactly-five structure must remain unchanged;
4. duplicate valid palette IDs remain legal;
5. availability/activity semantics remain unchanged;
6. no UI/dispatch/target/routing/agent behavior is introduced.

## Required regression proof

Add a direct test that would fail on the current implementation.

It must prove that a caller using the public SlotSystem API cannot obtain a
mutable internal SlotState and set an invalid palette ID outside the validated
configuration path.

Also preserve the existing invalid configure, state-preservation and
five-slot tests.

## Task truth

Reopen until the correction is validated:

- SB-M12-003 Configure five gameplay slots
- SB-M12-005 Slot palette/color
- SB-M12-009 Query API
- SB-M12-010 Five-slot tests
- SB-M12-011 Invalid slot tests

Other M12 task behavior is accepted baseline.

## Reusable audit learning

- `AL-020`: validation at a manager/system boundary is ineffective if a
  public query API leaks mutable references to internally owned state.
  Regression tests must attempt the bypass path, not only the intended setter.

## Next action

Apply the narrow M12-C001 V02 correction, validate it, write evidence only to
`CLAUDE_LOG_V02.md`, push safely, return `AWAITING_AUDIT`, and stop.

Do not start M13, LF00 or CP00.
