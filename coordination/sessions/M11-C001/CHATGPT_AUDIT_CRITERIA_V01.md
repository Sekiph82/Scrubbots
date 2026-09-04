---
coordinationSchema: scrubbots-coordination/v3
artifactType: chatgpt-audit-criteria
cycleId: M11-C001
version: 1
createdAt: 2026-09-04T10:37:00+03:00
actor: CHATGPT
status: ISSUED
milestone: M11
taskRefs:
  - SB-M11-001
  - SB-M11-002
  - SB-M11-003
  - SB-M11-004
  - SB-M11-005
  - SB-M11-006
  - SB-M11-007
  - SB-M11-008
  - SB-M11-009
  - SB-M11-010
  - SB-M11-011
  - SB-M11-012
---

# SCRUBBOTS - M11-C001 ChatGPT Audit Criteria V01

Claude implements/tests/logs only. ChatGPT performs the independent audit.

## Pass/fail criteria

| ID | Requirement | AUDITED_PASS requires | AUDITED_FAIL if |
| --- | --- | --- | --- |
| AC-M11-001 | Session core boundary | Lifecycle/LevelData/BoardState truth lives in a headless-testable gameplay session core, not UI or renderer. | UI/renderer becomes gameplay truth or the core requires scene-specific UI hierarchy. |
| AC-M11-002 | Explicit lifecycle | UNINITIALIZED/READY/ACTIVE/PAUSED/COMPLETED-equivalent states and deterministic transition rules exist. | State changes are implicit, ambiguous, or scattered. |
| AC-M11-003 | Valid load | Existing LevelLoader is reused; successful load owns LevelData + fresh BoardState and reaches READY. | A parallel loader/validator is invented or successful load leaves incomplete state. |
| AC-M11-004 | Failed-load atomicity | Missing/malformed/invalid replacement loads do not destroy a previously valid session. | Failed load clears/replaces valid level/board or leaves mixed state. |
| AC-M11-005 | BoardState isolation | BoardState is fresh runtime state; LevelData is not mutated; independent sessions do not share mutable board state. | Runtime mutations leak into LevelData or another session. |
| AC-M11-006 | Start/pause/resume | READY->ACTIVE, ACTIVE->PAUSED, PAUSED->ACTIVE are explicit; invalid transitions fail without state mutation. | Invalid calls silently mutate lifecycle. |
| AC-M11-007 | Reset contract | Reset recreates BoardState from immutable LevelData, restores DIRTY cells and deterministic documented lifecycle state. | Reset manually patches stale state incompletely or retains mutated BoardState. |
| AC-M11-008 | Completion design-neutral | Completion is explicit/external lifecycle transition only; no new win/lose/timer/move rule is invented. | Session auto-completes from dirty count or implements an unresolved game rule. |
| AC-M11-009 | Completion robustness | Repeated/invalid completion behavior is deterministic and non-corrupting. | Completion calls corrupt or unpredictably change state. |
| AC-M11-010 | Renderer seam | Existing BoardRenderer is optionally bound/configured from current BoardState + palette; reset updates it to fresh board; renderer remains presentation-only. | Renderer loads level, owns lifecycle, decides completion, or session reads pixels as truth. |
| AC-M11-011 | Variable board support | TEST non-square, legal rectangular production board, and 59x59 initialize/reset correctly. | Session assumes square/fixed board dimensions. |
| AC-M11-012 | No per-cell node regression | Renderer/session integration does not introduce one Node per logical cell. | Board/session creates hundreds/thousands of cell Nodes. |
| AC-M11-013 | UI separation | Session exposes state/results/signals/query APIs without embedding HUD/menu decisions. | M11 implements slot HUD/menu/gameplay UI as truth. |
| AC-M11-014 | Error specificity | Invalid transitions and load failures return actionable deterministic error/result information without normal-use crashes. | Silent failure or runtime crash is the normal invalid-input path. |
| AC-M11-015 | Regression preservation | All prior 447 checks plus new M11 checks pass. | M09 importer, BoardState, renderer, difficulty, or data behavior regresses. |
| AC-M11-016 | Design gates preserved | M10 preset not selected; M12+ slots/routing/agents and win/lose rules remain untouched. | Owner/future design is silently decided. |
| AC-M11-017 | Task truth | SB-M11-001..012 close only with behavioral evidence. | tasks.md overstates completion. |
| AC-M11-018 | Validation traceability | Claude log records every mandatory validation item individually with expected/fail/actual/classification and commit/push evidence. | Aggregate green total substitutes for required named evidence. |
| AC-M11-019 | Scope integrity | Diff stays within session core/binding/tests/docs/task/coordination plus narrowly necessary integration changes. | Unrelated milestones or systems begin. |

## Independent-audit note

Claude-run Godot results are implementation evidence. ChatGPT will independently inspect repository code, lifecycle transitions, failure atomicity, BoardState isolation, renderer separation, tests, task truth, and coordination state before assigning a verdict.
