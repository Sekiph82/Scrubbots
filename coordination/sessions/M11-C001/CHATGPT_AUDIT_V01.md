---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit
cycleId: M11-C001
version: 1
createdAt: 2026-09-04T19:26:00+03:00
actor: CHATGPT
status: CHANGES_REQUIRED
milestone: M11
taskRefs:
  - SB-M11-001
  - SB-M11-002
  - SB-M11-003
  - SB-M11-004
  - SB-M11-005
  - SB-M11-006
  - SB-M11-007
  - SB-M11-008
  - SB-M11-009
  - SB-M11-010
  - SB-M11-011
  - SB-M11-012
auditedImplementationHead: 5ca4b81989670055e419fce3a6e3a69eb621bae1
---

# SCRUBBOTS - M11-C001 ChatGPT Independent Audit V01

## Decision

`CHANGES_REQUIRED`

The M11 session-core implementation is structurally strong and the inspected
production code satisfies the intended lifecycle architecture:

- `GameplaySession` is a headless-testable `RefCounted`;
- explicit states are UNINITIALIZED / READY / ACTIVE / PAUSED / COMPLETED;
- valid load uses the existing LevelLoader and creates a fresh BoardState;
- failed replacement load preserves prior valid state;
- reset recreates BoardState from immutable LevelData;
- completion is explicit and does not infer a win rule;
- renderer binding remains optional/presentation-only;
- no M12+ gameplay system or M10 owner decision was introduced.

Claude reported 542/542 checks passing. That remains implementer-run runtime
evidence. ChatGPT independently inspected the implementation diff, source,
tests, task truth and coordination state; ChatGPT did not execute the local
Godot binary.

One required renderer-regression proof is not actually asserted by the test
suite.

## Finding

### F-M11-001 - MEDIUM - Renderer binding/reset tests do not observe the renderer's BoardState source

The prompt's required automated matrix includes:

- renderer sees the same BoardState the session currently owns;
- reset updates renderer to the fresh BoardState rather than a stale runtime
  state.

The production code currently does the right thing:

`_configure_renderer()` calls:

`_renderer.configure(_board_state, _level_data.palette, _renderer_size)`

and reset creates a fresh BoardState before calling `_configure_renderer()`.

However, the tests labeled M11-23 and M11-24 do not prove those properties.

M11-23 only checks:

- `renderer.get_cell_size() > 0`;
- board pixel size is non-zero.

That proves some renderer configuration occurred, but not that the renderer
is reading the same BoardState object owned by the session.

M11-24 only checks:

- session returns to READY;
- `s22.get_board_state().get_cell_state(0)` is DIRTY.

That proves the session owns a fresh/reset board, but it never observes the
renderer after reset. If the reset-time `_configure_renderer()` call were
removed and the renderer remained bound to the old BoardState, M11-24 would
still pass.

This is a false-positive regression gap against AC-M11-010 and the explicit
test matrix in the active prompt.

## Required correction

Add behaviorally specific tests that observe the **real BoardRenderer** after
binding and after reset.

Do not add a production-only getter merely to expose private renderer state
unless there is a genuine runtime need. Prefer observable behavior.

A robust pattern is:

1. bind a real BoardRenderer;
2. load a level;
3. mutate the session's current BoardState;
4. call the renderer's existing `update_cells()`;
5. prove displayed cell color tracks the session-owned board;
6. retain the old BoardState reference;
7. reset, obtaining a fresh BoardState;
8. deliberately give old and new BoardStates different cell states;
9. call `renderer.update_cells([index])`;
10. prove renderer output follows the **new** BoardState, not the old one.

Use tolerant/property-based color comparison consistent with AL-002, not
brittle exact floating-point equality.

The targeted test must fail if reset stops reconfiguring the renderer to the
new BoardState.

## Criteria results

| Criterion | Result |
| --- | --- |
| AC-M11-001..009 | PASS by independent code/test inspection |
| AC-M11-010 Renderer seam | CHANGES_REQUIRED because reset-to-fresh-board behavior lacks direct regression proof |
| AC-M11-011..016 | PASS by independent inspection |
| AC-M11-017 Task truth | CHANGES_REQUIRED for SB-M11-005/SB-M11-012 until renderer proof is added |
| AC-M11-018 Validation traceability | PASS for V01 commands; V02 must log new targeted checks individually |
| AC-M11-019 Scope integrity | PASS |

## Task truth

Keep the implementation itself. Reopen only the task truth whose validation
is incomplete:

- `SB-M11-005 Connect renderer`;
- `SB-M11-012 Headless lifecycle tests where possible`.

The remaining M11 task behavior is independently accepted and does not need
to be rewritten.

## Reusable audit learning

Add:

- `AL-018`: a regression test must observe the subsystem/property it claims
  to verify. A proxy assertion on adjacent state is not evidence if the test
  would remain green after the target behavior regressed.

## Scope note

Repository commit `dec02f6b...` registered the Level Factory and Content
Pipeline architecture after the M11 implementation. Those sidecar docs/tasks
do not alter the M11 production implementation and are not part of this
finding.

## Next action

Claude applies the narrow V02 correction, runs the targeted renderer proof
and full regression suite, appends evidence to the existing
`CLAUDE_IMPLEMENTATION_LOG.md`, restores SB-M11-005/SB-M11-012 only after
validation, sets M11-C001 to `AWAITING_AUDIT`, pushes safely, and stops.

Do not start M12, LF00 or CP00.
