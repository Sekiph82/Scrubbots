---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: M12-C001
version: 2
createdAt: 2026-09-05T10:57:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M12
taskRefs:
  - SB-M12-003
  - SB-M12-005
  - SB-M12-009
  - SB-M12-010
  - SB-M12-011
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
---

# SCRUBBOTS - M12-C001 Audit Criteria V02

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-M12R2-001 | Internal-state encapsulation | No public SlotSystem query returns a mutable internally owned SlotState reference. |
| AC-M12R2-002 | Palette invariant | Callers cannot change a SlotSystem-owned palette ID except through a validated SlotSystem path. |
| AC-M12R2-003 | Query completeness | Identity, palette ID, availability and activity remain queryable without leaking mutable internal truth. |
| AC-M12R2-004 | Five-slot invariant | System still owns exactly five deterministic slots with no structural mutation API. |
| AC-M12R2-005 | Duplicate colors | Duplicate valid palette IDs remain accepted. |
| AC-M12R2-006 | State semantics | Availability/activity behavior remains independent and unchanged. |
| AC-M12R2-007 | Direct bypass regression | A test specifically proves the old `get_slot(...).set_palette_id(...)`-style bypass is impossible through public SlotSystem API. |
| AC-M12R2-008 | Negative preservation | Wrong count, negative/out-of-range IDs, invalid slot IDs and failed reconfigure remain deterministic/non-corrupting. |
| AC-M12R2-009 | Minimal scope | No UI, dispatch, TargetSelector, RoutingSystem, Scrubbot agent, GameplaySession ownership, M10 decision or unrelated refactor. |
| AC-M12R2-010 | Regression | Prior suite plus new correction tests remains green. |
| AC-M12R2-011 | Task truth | Reopened SB-M12-003/005/009/010/011 close only after direct bypass proof passes. |
| AC-M12R2-012 | GitHub-only evidence | First action safe sync; only matching CLAUDE_LOG_V02.md is used for durable V02 evidence; no Desktop handoff log. |
| AC-M12R2-013 | Traceability/H!ve | Required checks individually logged and SESSION_INDEX/H!ve files match task truth. |
| AC-M12R2-014 | Safe Git | Focused commit, safe non-force push, GitHub visibility and final status evidence. |

Relevant learnings: AL-001, AL-005, AL-009, AL-018, AL-019, AL-020.
