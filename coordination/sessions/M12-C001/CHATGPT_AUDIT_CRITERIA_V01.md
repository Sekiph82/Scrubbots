---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: M12-C001
version: 1
createdAt: 2026-09-05T09:44:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M12
taskRefs:
  - SB-M12-001
  - SB-M12-002
  - SB-M12-003
  - SB-M12-004
  - SB-M12-005
  - SB-M12-006
  - SB-M12-007
  - SB-M12-008
  - SB-M12-009
  - SB-M12-010
  - SB-M12-011
expectedClaudeLog: CLAUDE_LOG_V01.md
---

# SCRUBBOTS - M12-C001 Audit Criteria V01

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-M12-001 | SlotState boundary | Lightweight headless model holds identity, palette ID, availability and activity without UI/Node truth. |
| AC-M12-002 | SlotSystem boundary | Lightweight system owns the five-slot invariant and does not implement dispatch/target/routing. |
| AC-M12-003 | Exactly five | Every valid configured system has exactly five slots and clients cannot structurally mutate the count. |
| AC-M12-004 | Stable identity | Five deterministic identities remain stable across valid state changes. |
| AC-M12-005 | Palette assignment | Exactly five palette IDs are validated against an explicit palette boundary. |
| AC-M12-006 | No invented uniqueness | Duplicate valid palette IDs are accepted unless a future authoritative rule changes this. |
| AC-M12-007 | Availability semantics | Availability is explicit model state only, independent of future TargetSelector/valid-work semantics. |
| AC-M12-008 | Activity semantics | Activity is explicit model state only and does not dispatch/spawn or invent exclusivity. |
| AC-M12-009 | State independence | One slot's palette/availability/activity changes do not silently mutate unrelated slots; availability and activity are independent. |
| AC-M12-010 | Invalid usage | Wrong count, invalid palette IDs and invalid slot IDs fail deterministically without crash or partial mutation. |
| AC-M12-011 | Reconfiguration atomicity | Failed reconfiguration preserves the prior valid five-slot state. |
| AC-M12-012 | Query API | Callers can query count/identity/palette/availability/activity without bypassing structural invariants. |
| AC-M12-013 | UI separation | No UI scene/widget/input becomes slot model truth. |
| AC-M12-014 | Scope integrity | No GameplaySession ownership, dispatch, TargetSelector, RoutingSystem, Scrubbot agent, win/lose, stack/queue/quantity or M10 owner decision is introduced. |
| AC-M12-015 | Test specificity | Direct tests observe the properties they claim to prove, including negative/state-preservation cases. |
| AC-M12-016 | Regression | Prior suite plus M12 tests remains green; Claude totals remain E1/E2 only. |
| AC-M12-017 | Task truth | SB-M12-001..011 close only where validated evidence exists. |
| AC-M12-018 | GitHub-only evidence | First action is safe sync; matching CLAUDE_LOG_V01.md exists; no Desktop phase/handoff log is created or updated. |
| AC-M12-019 | Traceability | All 34 mandatory validation items are individually recorded in CLAUDE_LOG_V01.md. |
| AC-M12-020 | H!ve state | ACTIVE_CYCLES, ARTIFACT_MAP, PROGRESS_SNAPSHOT and PROJECT_DASHBOARD match task/session truth. |
| AC-M12-021 | Safe Git | Focused commit, safe non-force push, GitHub visibility and final status are evidenced. |

Relevant learnings: AL-001, AL-005, AL-009, AL-018, AL-019.
