---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-prompt
cycleId: M11-C001
version: 3
createdAt: 2026-09-04T22:01:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
supersedes: CHATGPT_PROMPT_V02.md
triggerAudit: CHATGPT_AUDIT_V02.md
baselineCommit: b86e25fabaf04c7da52b8bd411d13a51307e8e4d
taskRefs:
  - SB-M11-005
  - SB-M11-012
---

# SCRUBBOTS - M11-C001 Renderer Proof Execution Recovery V03

## Situation

There is currently no V02 implementation on GitHub.

Do not stop after inspecting the repository and do not report that there is
nothing to push. The correction work must now be implemented.

## Read first

1. Audit V02:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V02.md
2. Original finding:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_V01.md
3. Active criteria V03:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_AUDIT_CRITERIA_V03.md
4. This prompt:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CHATGPT_PROMPT_V03.md
5. Existing implementation log:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md
6. Governance:
   https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
7. Canonical tasks:
   https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
8. Audit learnings:
   https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
9. GameplaySession:
   https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/session/gameplay_session.gd
10. BoardRenderer:
    https://github.com/Sekiph82/Scrubbots/blob/main/scripts/gameplay/board/board_renderer.gd
11. Tests:
    https://github.com/Sekiph82/Scrubbots/blob/main/tests/run_tests.gd

## Implement now

Implement the F-M11-001 correction exactly:

- strengthen M11 renderer tests to behaviorally prove that a real
  BoardRenderer follows the session-owned BoardState after bind/load;
- retain old BoardState, reset to a fresh BoardState, make old/new states
  observably different, call the existing renderer update path, and prove
  renderer pixels follow the fresh board;
- make the test fail if reset-time renderer reconfiguration is removed;
- use tolerant/property-based color comparison per AL-002;
- do not add test-only production getters/APIs;
- change production code only if the stronger test exposes a real defect.

## Mandatory validation/logging

Append a new session to the SAME:
`coordination/sessions/M11-C001/CLAUDE_IMPLEMENTATION_LOG.md`.

Individually record:

1. godot version
2. root project verification
3. root headless boot
4. targeted initial renderer-binding proof
5. targeted reset-to-fresh-board proof
6. explanation showing why stale-old-board semantics would fail the test
7. full headless test suite
8. no test-only production API
9. no M12/LF00/CP00/M10 owner decision
10. git diff --check
11. scope inspection
12. git status before commit
13. focused commit
14. safe push to origin/main
15. final status and pushed commit SHA

After validation:

- mark SB-M11-005 and SB-M11-012 complete only if proven;
- update root SESSION_INDEX and PROJECT_DASHBOARD;
- set M11-C001 to AWAITING_AUDIT;
- push safely;
- verify the appended implementation log and new commit are visible on
  GitHub;
- stop.

Claude implements/tests/logs only.
Do not create any audit/self-audit file.
Do not start M12, LF00, CP00, or later work.
