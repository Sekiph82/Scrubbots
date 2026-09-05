---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C004
version: 2
createdAt: 2026-09-05T22:55:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
---

# META-C004 Audit Criteria V02

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META4R2-001 | Preserve core migration | No production ACTIVE/CLEARED/ColorCandidateIndex behavior is redesigned or regressed. |
| AC-META4R2-002 | M48 migration | M48 explicitly encodes CLEARED transparency/background behavior and blocked matching-color reachability/solvability semantics without adding/changing task IDs. |
| AC-META4R2-003 | Project brief truth | "obscured pixel-art image" and equivalent stale current wording are removed; artwork is visible/ACTIVE from level start. |
| AC-META4R2-004 | Semantic scan | Scan includes identifiers plus conceptual stale terms such as obscured/hidden-under/reveal-under-grime; historical and unrelated-English hits are classified. |
| AC-META4R2-005 | Task truth | Unique canonical task IDs remain 943 and completed remain 207; M10-005..011 and all M14+ implementation gates stay open. |
| AC-META4R2-006 | No scope creep | No BoardState/Renderer/CandidateIndex gameplay change, no M14/M15/M16/M17 implementation, no LF00/CP00/Magnific work. |
| AC-META4R2-007 | Owner work safety | Existing tracked/untracked owner/tool changes are preserved, not restored/reset/staged. |
| AC-META4R2-008 | Pre-commit evidence | CLAUDE_LOG_V02 records branch/head/origin/status, owner-path classification, exact intended files, diff-check and progress before commit. |
| AC-META4R2-009 | Focused commit | Exactly one V02 correction commit after V01 implementation head; safe non-force push. |
| AC-META4R2-010 | External receipt | Exactly one commit comment headed "META-C004 V02 POST-PUSH RECEIPT" exists on the V02 commit with exact full commit/main SHA equality, final status, path classification and 207/943 truth. |
| AC-META4R2-011 | No post-receipt commit | Live main remains exactly the SHA named in the receipt. |
| AC-META4R2-012 | Coordination | SESSION_INDEX and H!ve map META-C004 V02 as AWAITING_AUDIT, next actor ChatGPT. |

Relevant learnings: AL-005, AL-009, AL-018, AL-019, AL-021, AL-025,
AL-026, AL-027, AL-028, AL-029, AL-030.
