---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C003
version: 1
createdAt: 2026-09-05T15:50:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V01.md
triggerAudit: META-C002/CHATGPT_AUDIT_V05.md
pr: 3
branch: feature/master-ui-magnific-pipeline
targetBranch: main
---

# META-C003 Audit Criteria V01

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META3M-001 | Pre-merge sync | Feature branch and main are fetched/synchronized safely with owner work preserved and no destructive Git commands. |
| AC-META3M-002 | META-C002 gate | META-C002 Audit V05 is visible and AUDITED_PASS before merge. |
| AC-META3M-003 | Pre-merge regression | Root verification, headless boot and full Godot suite pass on the exact feature head to be merged. |
| AC-META3M-004 | PR truth | PR #3 body remains current; PR is marked ready only after pre-merge validation; mergeability is re-queried. |
| AC-META3M-005 | Merge strategy | PR #3 is merged with a normal merge commit, not squash/rebase/force history rewriting. |
| AC-META3M-006 | Merge provenance | Exact pre-merge main SHA, exact feature SHA, exact GitHub merge commit SHA and parent relationship are recorded. |
| AC-META3M-007 | Canonical task truth | Merged main has exactly 943 unique canonical SB IDs, 196 complete, 747 remaining, exactly 95 UI migration IDs, and no prior-main completed task regression. |
| AC-META3M-008 | Visual truth | Merged main retains the 51-image/51-inventory mapping, canonical gameplay/Home/popup refs, and Scrubby OWNER_REQUIRED state. |
| AC-META3M-009 | Post-merge regression | Merged main root verification, headless boot and full Godot suite pass. |
| AC-META3M-010 | No scope creep | No M13, LF00, CP00, broad/final Magnific generation, gameplay redesign or owner-gate closure. |
| AC-META3M-011 | Canonical coordination | SESSION_INDEX, AUDIT_INDEX if needed, ACTIVE_CYCLES, ARTIFACT_MAP, PROGRESS_SNAPSHOT and PROJECT_DASHBOARD are reconciled on main. |
| AC-META3M-012 | GitHub-only evidence | Matching META-C003/CLAUDE_LOG_V01.md exists on main; no Desktop/local handoff log is created. |
| AC-META3M-013 | Post-merge main commit | One focused post-merge reconciliation commit is pushed safely to main after validation. |
| AC-META3M-014 | External receipt | Merged PR #3 has one `META-C003 V01 POST-MERGE RECEIPT` with merge SHA, final reconciliation SHA, final origin/main SHA equality proof, final status, progress and PR merged state. |
| AC-META3M-015 | No receipt mutation | No Git commit is created after the receipt; final main head remains the SHA named in the receipt. |
| AC-META3M-016 | Feature preservation | Feature branch is not deleted during this cycle; deletion waits until ChatGPT audits META-C003. |

Relevant learnings: AL-005, AL-009, AL-019, AL-020, AL-021, AL-022, AL-023, AL-025.
