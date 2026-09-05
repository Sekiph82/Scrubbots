---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C002
version: 2
createdAt: 2026-09-05T13:09:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
pr: 3
branch: feature/master-ui-magnific-pipeline
---

# META-C002 Audit Criteria V02

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META2-001 | Main synchronization | Feature branch safely integrates latest origin/main including M12-C001 AUDITED_PASS, with no task loss/history rewrite. |
| AC-META2-002 | 95-task migration | Exactly 95 UI tasks remain added, every current-main canonical SB task remains present exactly once. |
| AC-META2-003 | Per-file owner inventory | All 51 imported inbox files have durable machine-readable path, SHA-256, dimensions, category, provenance/source class and approval/canonical state. |
| AC-META2-004 | Copy integrity | Source/repository hashes are compared where source is available; no Desktop source is modified/deleted/overwritten. |
| AC-META2-005 | Inventory truth | Existing inventory category summaries and README no longer claim supplied categories are missing. External/reference art is not mislabeled as production owner-original level art. |
| AC-META2-006 | Canonical refs | Gameplay, Home and popup/level-intro canonical repo paths are durably recorded. Scrubby remains OWNER_REQUIRED with candidate paths, not silently selected. |
| AC-META2-007 | Manifest truth | Manifest reflects intake-complete/reference-selection state and does not mark Scrubby-dependent generation ready before owner choice. |
| AC-META2-008 | Task truth | Only directly-proven M07/SB-UI tasks close; SB-UI-008 and unproven production-art/M08 tasks remain open. |
| AC-META2-009 | Progress truth | Counts derive from unique canonical SB IDs. V02 records before/after totals and H!ve matches tasks.md exactly. |
| AC-META2-010 | Log integrity | CLAUDE_LOG_V01 is preserved; corrections live in matching CLAUDE_LOG_V02.md. |
| AC-META2-011 | UI regression | Godot parse/startup and full current regression suite remain green after reconciliation. |
| AC-META2-012 | Scope | No broad/final Magnific generation, no Higgsfield, no gameplay redesign, no Level Factory/Content Pipeline changes beyond safe main integration. |
| AC-META2-013 | PR state | PR #3 is updated truthfully and remains unmerged/draft awaiting ChatGPT audit. |
| AC-META2-014 | H!ve/coordination | SESSION_INDEX, ACTIVE_CYCLES, ARTIFACT_MAP, PROGRESS_SNAPSHOT and PROJECT_DASHBOARD match branch truth. |
| AC-META2-015 | Safe Git | Focused correction commits, non-force push, GitHub visibility and final clean/known state. |

Claude-run tests remain E1/E2 evidence. ChatGPT performs the independent audit.
