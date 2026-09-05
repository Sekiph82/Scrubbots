---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C002
version: 4
createdAt: 2026-09-05T15:04:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V04.md
triggerAudit: CHATGPT_AUDIT_V03.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# META-C002 Audit Criteria V04

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META4-001 | Baseline preservation | V02/V03 accepted inventory, manifest, tasks, UI architecture and PR body do not regress. |
| AC-META4-002 | Exact V03 provenance | CLAUDE_LOG_V04 records the full V03 commit SHA and verifies that exact SHA was visible on origin before V04 changes. |
| AC-META4-003 | Exact V04 provenance | CLAUDE_LOG_V04 records the full V04 commit SHA and final origin feature-branch head SHA after push. |
| AC-META4-004 | Working-tree truth | Full `git status --short` output is recorded before and after V04; every untracked repo-local path is explicitly classified without deleting owner work. |
| AC-META4-005 | Push truth | Safe non-force push evidence is concrete and final remote head is verified. |
| AC-META4-006 | PR gate | PR #3 remains draft/unmerged and body remains current. |
| AC-META4-007 | Progress | No task truth changes; 196/943 remains exact. |
| AC-META4-008 | Scope | Evidence/coordination only; no gameplay/UI implementation, Magnific generation, M13/LF00/CP00 work. |
| AC-META4-009 | H!ve/coordination | SESSION_INDEX and H!ve map active V04/CLAUDE_LOG_V04 truth correctly. |

Relevant learnings: AL-009, AL-019, AL-023.
