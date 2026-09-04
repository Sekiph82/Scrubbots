---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M11-C001
version: 3
createdAt: 2026-09-04T22:01:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
taskRefs:
  - SB-M11-005
  - SB-M11-012
triggerAudit: CHATGPT_AUDIT_V02.md
---

# SCRUBBOTS - M11-C001 Audit Criteria V03

V03 preserves the V02 technical acceptance criteria and adds one mandatory
evidence precondition: there must be a new Claude implementation commit and
an appended V02/V03 implementation session in the existing log.

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-M11R3-001 | New implementation evidence | New commit(s) after b86e25f and appended Claude implementation-log evidence exist on origin/main. |
| AC-M11R3-002 | Initial renderer binding proof | Real BoardRenderer output follows the session-owned BoardState after bind/load. |
| AC-M11R3-003 | Fresh-board reset proof | Test deliberately distinguishes old vs new BoardState and renderer output follows the new board after reset. |
| AC-M11R3-004 | Regression-test specificity | The test would fail if reset-time renderer rebinding were removed. |
| AC-M11R3-005 | Color robustness | Use tolerant/property comparison per AL-002. |
| AC-M11R3-006 | API discipline | No production getter/private-state escape hatch exists solely for tests. |
| AC-M11R3-007 | Regression preservation | Prior 542 checks plus new targeted checks pass. |
| AC-M11R3-008 | Task truth | SB-M11-005 and SB-M11-012 close only after direct proof passes. |
| AC-M11R3-009 | Traceability | Required commands/checks are individually appended to the same Claude log. |
| AC-M11R3-010 | Scope | No M12, LF00, CP00, M10 owner-decision, or unrelated work begins. |

Relevant learnings: AL-002, AL-005, AL-009, AL-018.
