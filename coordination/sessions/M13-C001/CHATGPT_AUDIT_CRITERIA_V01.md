---
coordinationSchema: scrubbots-coordination/v4
artifactType: chatgpt-audit-criteria
cycleId: M13-C001
version: 1
createdAt: 2026-09-05T16:17:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M13
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
expectedClaudeLog: CLAUDE_LOG_V01.md
---

# SCRUBBOTS - M13-C001 Audit Criteria V01

| ID | Requirement | AUDITED_PASS requires |
| --- | --- | --- |
| AC-M13-001 | Eligible definition | Eligible means valid + DIRTY + matching color + not caller-excluded/reserved. No invented route/blocker rules. |
| AC-M13-002 | Color index | DIRTY candidates are grouped/queryable by color without a full BoardState scan on every steady-state query. |
| AC-M13-003 | Board sync | Explicit per-cell synchronization and full rebuild/rebind accurately follow BoardState mutations. |
| AC-M13-004 | CLEAN removal | CLEAN synchronized cells disappear from eligible results. |
| AC-M13-005 | DIRTY restore | DIRTY restoration re-enters eligibility exactly once without duplicates. |
| AC-M13-006 | Fresh-board safety | Rebind/rebuild to a fresh BoardState cannot leak stale candidates from the old board. |
| AC-M13-007 | No-work | Cheap has-work/no-work query is behaviorally correct for present/exhausted/last-target cases. |
| AC-M13-008 | Reservation seam | Caller-supplied reserved/excluded cells are filtered without M13 owning persistent reservation state. |
| AC-M13-009 | M14 boundary | No RESERVED state, reservation owner, atomic reserve, double-reservation prevention, release, arrival/concurrency semantics; M02-017/M14 stay open. |
| AC-M13-010 | Detached API | Candidate query results cannot mutate internal cached truth. |
| AC-M13-011 | Determinism | Candidate ordering is deterministic and stable across sync/rebuild. |
| AC-M13-012 | Invalid usage | Unbound/invalid index/query cases fail safely without cache corruption. |
| AC-M13-013 | Scale | 59×59 / 3,481-cell correctness and benchmark evidence exist; rectangular boards are covered. |
| AC-M13-014 | Performance claim discipline | Benchmark is CPU/index evidence only; no brittle hardware threshold and no FPS/GPU claim. |
| AC-M13-015 | TargetSelector boundary | No target-selection strategy, dispatch, route generation or Scrubbot-agent behavior is implemented. |
| AC-M13-016 | Prior architecture | BoardState indexing stays centralized; BoardRenderer, SlotSystem, TargetSelector-vs-Routing seam and UI architecture do not regress. |
| AC-M13-017 | Direct tests | Tests directly observe CLEAN removal, stale-board replacement, reservation filtering, detached result safety, exhausted/last target and scale behavior. |
| AC-M13-018 | Regression | Full prior suite plus M13 tests remains green; Claude totals remain E1/E2. |
| AC-M13-019 | Task truth | SB-M13-001..010 close only with matching evidence. |
| AC-M13-020 | GitHub-only evidence | First action safe sync; matching CLAUDE_LOG_V01 exists; no Desktop/local handoff log. |
| AC-M13-021 | Traceability | All 51 mandatory validations are individually recorded. |
| AC-M13-022 | H!ve/coordination | SESSION_INDEX and H!ve tracking match canonical task/session truth. |
| AC-M13-023 | Safe Git | Focused commit, safe non-force push, GitHub visibility and known final status. |

Relevant learnings: AL-001, AL-003, AL-005, AL-009, AL-018, AL-019,
AL-020, AL-021, AL-025.
