---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C002
version: 5
createdAt: 2026-09-05T15:35:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V05.md
triggerAudit: CHATGPT_AUDIT_V04.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# META-C002 Audit Criteria V05

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META5-001 | Baseline preservation | Accepted V01–V04 inventory, manifest, tasks, UI architecture, PR body and progress do not regress. |
| AC-META5-002 | Prior provenance | CLAUDE_LOG_V05 records the exact pre-V05 feature head and the exact V04 final GitHub head `fcac66d459120e0f393bf00e2b41b3adc763f7b8`. |
| AC-META5-003 | Working-tree truth | Full pre-commit `git status --short` and classification of every repo-local untracked path are recorded; owner work is preserved. |
| AC-META5-004 | Single V05 commit | V05 creates one focused coordination/evidence commit and does not amend/rewrite it after push. |
| AC-META5-005 | Post-push receipt | PR #3 contains one `META-C002 V05 POST-PUSH RECEIPT` comment with exact full V05 commit SHA, exact final remote feature-head SHA, equality proof, full final `git status --short`, and PR draft/unmerged state. |
| AC-META5-006 | No post-receipt commit | Feature branch head remains exactly the SHA named in the receipt after the receipt is posted. |
| AC-META5-007 | PR gate | PR #3 remains draft/unmerged; body remains current. |
| AC-META5-008 | Progress | No task truth changes; 196/943 remains exact. |
| AC-META5-009 | Scope | Coordination/evidence only; no gameplay/UI implementation, inventory/manifest change, Magnific generation, M13/LF00/CP00 work. |
| AC-META5-010 | H!ve/coordination | SESSION_INDEX and H!ve map V05/CLAUDE_LOG_V05 AWAITING_AUDIT truth correctly. |

Relevant learnings: AL-009, AL-019, AL-023, AL-024, AL-025.
