---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: META-C004
version: 1
createdAt: 2026-09-05T21:45:00+03:00
actor: CHATGPT
status: ISSUED
milestone: META
expectedClaudeLog: CLAUDE_LOG_V01.md
baselineCommit: 62cde92cdeb443f4f91b31b5c3152b5bab0d8813
---

# META-C004 Audit Criteria V01

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-META4-001 | Owner rule | Current canonical truth uses ACTIVE -> CLEARED, not gameplay-semantic DIRTY/CLEAN. |
| AC-META4-002 | Visible artwork model | ACTIVE displays source palette color; CLEARED is alpha-0 transparent and shows background. No hidden clean artwork/grime layer. |
| AC-META4-003 | BoardState | CellState is ACTIVE/CLEARED, fresh/reset boards are ACTIVE, state/count/isolation tests pass. |
| AC-META4-004 | Renderer | One Image/ImageTexture architecture remains; ACTIVE source-color and CLEARED transparency are directly observed. |
| AC-META4-005 | Obsolete preset removal | DirtyCleanPresets file/dependency/API and A/B/C gameplay preset semantics are removed from current production/tooling. |
| AC-META4-006 | Candidate rename | EligibleTargetIndex is replaced by targeting/ColorCandidateIndex with candidate-specific API language. |
| AC-META4-007 | Candidate semantics | Raw candidate = valid + ACTIVE + matching color + caller exclusion; it does not claim reachability. |
| AC-META4-008 | M13 performance | Cached color query, sync/rebuild/rebind, exclusion, no-candidate, exhausted/last candidate, 59x59 and no-rescan proofs remain valid. |
| AC-META4-009 | Blocking rule | Canonical docs/tasks state matching color is insufficient: blocked/unreachable ACTIVE cells are not final targets. |
| AC-META4-010 | Access semantics | ACTIVE non-target cells block access; CLEARED/background space opens access; exact path topology remains M16/M17. |
| AC-META4-011 | WHAT/HOW seam | ColorCandidateIndex, reachability/access truth, TargetSelector and RoutingSystem responsibilities are distinct; no route generation enters selector. |
| AC-META4-012 | Dispatch contract | No bot leaves slot without ACTIVE+matching+valid+unreserved+reachable target. Arrival CLEARS target and bot disappears; no carry/return. |
| AC-META4-013 | Debug tool | Preset dropdown removed; ACTIVE/CLEARED patterns + visible background + size/rectangular/59x59 controls work. |
| AC-META4-014 | Canonical docs | README, CLAUDE, project brief, gameplay spec, architecture, level-data spec, roadmap, ADRs and test strategy contain new-model truth. |
| AC-META4-015 | ADR history | Renderer ADR remains; new ADR records owner rule/candidate-vs-reachability; conflicting old current consequence is marked superseded, not falsified. |
| AC-META4-016 | Task migration | M02/M10/M11/M13/M15-M20/M21/UI/M40/M41/M48/M49 and any discovered semantic tasks are reconciled. |
| AC-META4-017 | M10 truth | Owner decision may close SB-M10-001; automated migration must not close M10-005..011 manual-QA gates. |
| AC-META4-018 | Future gates | M02-017, M14, M15/M16/M17 implementation remain open; no future subsystem is implemented early. |
| AC-META4-019 | Level Factory | LF canonical docs adopt ACTIVE/CLEARED + blocked reachability semantics through shared gameplay adapter; no LF implementation starts. |
| AC-META4-020 | Content Pipeline | CP is inspected; runtime state remains outside level source data; no needless churn/implementation. |
| AC-META4-021 | Historical integrity | Prior prompts/logs/audits are unchanged; CHANGELOG is append-only. |
| AC-META4-022 | Semantic scan | All current non-historical gameplay-semantic DIRTY/CLEAN/preset/EligibleTargetIndex references are migrated; unrelated ordinary English clean is preserved. |
| AC-META4-023 | Tests | Old dirty-preset tests are replaced with direct ACTIVE/CLEARED/candidate tests; final suite passes even if aggregate count changes for legitimate deletion. |
| AC-META4-024 | Owner work safety | Pre-existing tracked/untracked owner work is classified/preserved and not restored/reset/staged. |
| AC-META4-025 | Progress truth | Unique canonical SB IDs and completion counts are recomputed from tasks.md. If no IDs are added and only M10-001 newly closes, expect 207/943, but actual canonical count controls. |
| AC-META4-026 | Coordination | SESSION_INDEX, AUDIT_INDEX, H!ve files and CLAUDE_LOG_V01 accurately map META-C004 and current truth. |
| AC-META4-027 | Git scope | Focused non-force commit/push, no unrelated code/art/Magnific/LF/CP work. |
| AC-META4-028 | Manual QA gate | M10-005..011 remain open until owner tests the new transparent model after audit. |

Relevant audit learnings: AL-001, AL-002, AL-003, AL-004, AL-005,
AL-009, AL-018, AL-019, AL-020, AL-021, AL-025, AL-026, AL-027, AL-028.
