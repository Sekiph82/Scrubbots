---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M11-C001
version: 2
createdAt: 2026-09-04T19:26:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
supersedes: CHATGPT_PROMPT_V01.md
triggerAudit: CHATGPT_AUDIT_V01.md
auditedImplementationHead: 5ca4b81989670055e419fce3a6e3a69eb621bae1
taskRefs:
  - SB-M11-005
  - SB-M11-012
---

# SCRUBBOTS - M11-C001 Renderer Regression Proof Correction V02

## Objective

Close only `F-M11-001` from independent audit V01.

The M11 production architecture is accepted baseline. Do not redesign
GameplaySession, BoardRenderer, lifecycle states, LevelData/BoardState
ownership or completion behavior unless the new targeted test exposes a real
production defect.

## Mandatory sources

Read before changing anything:

1. Independent audit V01:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md
2. Active audit criteria V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V02.md
3. This active prompt:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V02.md
4. Existing Claude implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md
5. Root governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
6. Canonical task truth:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
7. Audit learnings:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
8. GameplaySession:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/session/gameplay_session.gd
9. BoardRenderer:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/board/board_renderer.gd
10. Tests:
    https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd

Apply AL-002, AL-005, AL-009 and AL-018.

## Required correction

Strengthen the existing M11 renderer tests so they directly observe the real
BoardRenderer's BoardState source through rendering behavior.

### Initial binding proof

After a valid load/bind:

- mutate the session-owned BoardState at a known cell;
- invoke the renderer's existing update path;
- verify the displayed cell changes according to that BoardState and palette.

This must prove more than geometry/non-zero cell size.

### Reset fresh-board proof

Create a test that would fail if `GameplaySession.reset()` stopped
reconfiguring the renderer.

A recommended behavior-level sequence:

1. bind a real BoardRenderer and load a level;
2. capture `old_board = session.get_board_state()`;
3. reset and capture `new_board = session.get_board_state()`;
4. assert old and new are different objects;
5. deliberately assign different states to the same cell in old vs. new;
6. call `renderer.update_cells([cell_index])`;
7. verify the rendered pixel follows `new_board`, not `old_board`;
8. optionally flip the new-board state and verify the renderer follows it.

Use the existing `get_pixel_color()` rendering surface. Use tolerant or
property-based color comparison per AL-002.

Do not add a public `get_board()` or equivalent only for testing. If the
behavioral test reveals an actual production defect, fix it narrowly and
explain why.

## Required validation

Record each item separately in the existing
`CLAUDE_IMPLEMENTATION_LOG.md`:

1. `godot --version`
2. root project verification helper
3. root headless boot
4. targeted initial renderer-binding behavior proof
5. targeted reset-to-fresh-board renderer proof
6. prove the reset test fails conceptually if renderer stays on old-board semantics; document why the assertion specifically distinguishes old vs new board
7. full `tests/run_tests.gd` suite, preserving all prior 542 checks plus new checks
8. confirm no production API was added solely for tests
9. confirm no M12/LF00/CP00 implementation and no M10 owner decision
10. `git diff --check`
11. final diff/scope inspection
12. `git status --short` before commit
13. focused M11-C001 V02 commit
14. safe push to `origin/main` without force
15. final `git status --short` with commit/push evidence

## Task and coordination truth

After targeted and full validation pass:

- restore `SB-M11-005` and `SB-M11-012` to complete with accurate evidence;
- update root `coordination/SESSION_INDEX.md`;
- update root `.hiveai/PROJECT_DASHBOARD.md`;
- append all evidence to the **same**
  `coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md`;
- set M11-C001 to `AWAITING_AUDIT`;
- stop.

Claude must not create an audit/self-audit file or assign an audit verdict.

Do not start M12, LF00, CP00 or any later work.
