---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: M13-C001
version: 2
createdAt: 2026-09-05T20:12:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M13
expectedClaudeLog: CLAUDE_LOG_V02.md
triggerAudit: CHATGPT_AUDIT_V01.md
taskRefs:
  - SB-M13-001
  - SB-M13-002
  - SB-M13-003
  - SB-M13-004
  - SB-M13-005
  - SB-M13-006
  - SB-M13-007
  - SB-M13-008
  - SB-M13-009
  - SB-M13-010
---

# SCRUBBOTS - M13-C001 Audit Criteria V02

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-M13R2-001 | Accepted baseline | SB-M13-001/002/004/005 behavior remains correct and is not needlessly redesigned. |
| AC-M13R2-002 | Full query observability | Test instrumentation counts every BoardState traversal API relevant to a steady-state full-board scan, not only get_cell_state(). |
| AC-M13R2-003 | Zero steady-state board traversal | Repeated get_eligible(), has_work() and count_eligible() add zero BoardState traversal/API reads after the cache is built. |
| AC-M13R2-004 | Regression sensitivity | The new observability would detect a query implementation that loops over all cells via get_color_id(), get_cell_state(), get_cell_count()/index validation, or equivalent BoardState traversal. |
| AC-M13R2-005 | Efficient index task | SB-M13-003 closes only after source + direct regression evidence prove steady-state query uses cached color buckets rather than BoardState rescans. |
| AC-M13R2-006 | Reservation seam | SB-M13-006 is formally validated as caller-supplied exclusion only; no persistent ownership, RESERVED state, atomic reserve/release, double-reservation or concurrency semantics. |
| AC-M13R2-007 | Reservation robustness | Multiple/duplicate/invalid excluded indices do not corrupt cache truth; removing exclusion immediately re-exposes unchanged DIRTY candidates. |
| AC-M13R2-008 | No-work query | SB-M13-007 has direct present/absent/all-excluded/partially-excluded coverage. |
| AC-M13R2-009 | Exhausted color | SB-M13-008 directly proves final CLEAN + sync and rebuild truth both produce exhausted/no-work behavior without stale keys/candidates. |
| AC-M13R2-010 | Last target | SB-M13-009 directly proves exactly one candidate, only-target exclusion, and clean-last-target transition to no-work. |
| AC-M13R2-011 | 3,481 correctness | SB-M13-010 exercises 59x59=3,481 cells with exact membership/count/deterministic ordering checks. |
| AC-M13R2-012 | Benchmark discipline | Build/rebuild and repeated-query CPU/index timing recorded; naive comparison may exist only in test harness; no hardware threshold or FPS/GPU claim. |
| AC-M13R2-013 | Benchmark correctness | Indexed and naive benchmark result sinks/membership agree so timing cannot hide incorrect query semantics. |
| AC-M13R2-014 | Rectangular board | Non-square board coverage remains green. |
| AC-M13R2-015 | Cache sync | CLEAN removal, DIRTY restore, no duplicates, invalid sync atomicity, rebuild and fresh-board rebind remain green. |
| AC-M13R2-016 | Detached API | Returned arrays/keys cannot mutate internal bucket truth. |
| AC-M13R2-017 | M14 boundary | M02-017 and all M14 ownership tasks remain open; no reservation-state implementation enters M13. |
| AC-M13R2-018 | WHAT/HOW boundary | No TargetSelector, pathfinding, RoutingSystem, dispatch or Scrubbot-agent work. |
| AC-M13R2-019 | Owner-work safety | Pre-existing tracked/untracked local owner changes are preserved, not git-restored/reset/overwritten/staged. Blocking conflicts fail closed. |
| AC-M13R2-020 | Full regression | Prior suite plus corrected M13 tests remains green; Claude result is E1/E2 evidence. |
| AC-M13R2-021 | Task truth | All SB-M13-001..010 close only if matching V02 evidence passes; otherwise failing tasks stay open. |
| AC-M13R2-022 | Progress truth | Unique canonical SB-ID count matches tasks.md exactly. Expected if all M13 passes: 206/943 ecosystem, 206/719 main+UI. |
| AC-M13R2-023 | GitHub-only evidence | Matching CLAUDE_LOG_V02.md only; no Desktop/local handoff log. |
| AC-M13R2-024 | Traceability | Every mandatory V02 validation is individually recorded with result/evidence. |
| AC-M13R2-025 | H!ve/coordination | SESSION_INDEX, ACTIVE_CYCLES, ARTIFACT_MAP, PROGRESS_SNAPSHOT and PROJECT_DASHBOARD match task truth. |
| AC-M13R2-026 | Safe Git | Focused V02 commit, safe non-force push, no unrelated owner changes staged, GitHub visibility verified. |

Relevant learnings: AL-001, AL-003, AL-005, AL-009, AL-018, AL-019,
AL-020, AL-021, AL-025, AL-026.
