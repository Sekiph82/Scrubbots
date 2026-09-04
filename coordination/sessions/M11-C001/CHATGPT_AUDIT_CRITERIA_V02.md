---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M11-C001
version: 2
createdAt: 2026-09-04T19:26:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
taskRefs:
  - SB-M11-005
  - SB-M11-012
triggerAudit: CHATGPT_AUDIT_V01.md
---

# SCRUBBOTS - M11-C001 Audit Criteria V02

This is a narrow correction audit. Preserve all accepted M11 V01 behavior.

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M11R2-001 | Initial renderer binding proof | A real BoardRenderer is shown behaviorally to render from the session-owned BoardState after load/bind. | Test only proves geometry/configuration occurred, not which board drives pixels. |
| AC-M11R2-002 | Reset fresh-board renderer proof | After reset, old/new BoardStates are deliberately made observably different and renderer output is proven to follow the new BoardState. | Test would still pass if renderer remained bound to the old BoardState. |
| AC-M11R2-003 | Test specificity | The renderer itself is observed through existing public rendering behavior; surrounding load/reset state is valid. | An adjacent/proxy assertion substitutes for observing renderer output. |
| AC-M11R2-004 | Color-test robustness | Renderer color assertions use tolerant/property comparison consistent with AL-002. | Brittle exact float equality is introduced. |
| AC-M11R2-005 | No unnecessary production API | No test-only production getter/private-state escape hatch is added unless justified by runtime architecture. | Production API is expanded solely to make the test convenient. |
| AC-M11R2-006 | Regression preservation | All previous 542 checks plus new targeted checks pass. | Any accepted M11/M09/core test regresses. |
| AC-M11R2-007 | Task truth | SB-M11-005 and SB-M11-012 return to complete only after the direct renderer proof passes. | tasks.md overstates validation. |
| AC-M11R2-008 | Validation traceability | Targeted renderer checks and full suite are individually recorded in the existing Claude implementation log. | Aggregate total substitutes for named evidence. |
| AC-M11R2-009 | Scope integrity | Changes are limited to M11 renderer-regression tests and necessary docs/task/coordination updates; production session code changes only if a real defect is discovered. | M12, LF00, CP00, M10 decision work or unrelated refactors begin. |

## Relevant audit learnings

- AL-002
- AL-005
- AL-009
- AL-018

Claude implements/tests/logs only. ChatGPT performs the independent audit.
