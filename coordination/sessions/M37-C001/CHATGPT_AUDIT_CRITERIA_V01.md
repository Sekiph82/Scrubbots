# M37-C001 V01 — ChatGPT Audit Criteria

Milestone: `M37 — Level Progression`
Tasks: `SB-M37-001..SB-M37-008`

Authority:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `data/config/level_progression_v1.json`
- accepted M35 catalog + M36 Difficulty V1 contracts
- root `TASKS.md`, `CLAUDE.md`, `coordination/AUDIT_POLICY.md`

## Governance
Claude must not edit root `TASKS.md`.
Each task requires a separate durable task log under
`coordination/sessions/M37-C001/task_logs/<TASK_ID>.md`
plus canonical `CLAUDE_LOG_V01.md`.

## SB-M37-001 Repeating 10-level cadence
For every level n>=1:
1 EASY, 2 EASY, 3 MEDIUM, 4 EASY, 5 HARD, 6 EASY, 7 EASY, 8 MEDIUM, 9 EASY, 10 VERY_HARD, repeating exactly.
Test cycle boundaries and large n.

## SB-M37-002 Current level
One authoritative progression service owns current progression level identity/number. Reject invalid <=0 state. UI/gameplay consumers read, not mutate internals directly.

## SB-M37-003 Completion tracking
First-clear completion must be idempotent by stable level ID/number. Duplicate WON callbacks cannot advance progression twice. Completion truth must be separate from replay.

## SB-M37-004 Replay
Replay may load a completed level without changing current progression frontier or first-clear truth. Replay completion must not re-advance progression.

## SB-M37-005 Target curve / micro modifiers
Use the exact owner-locked V1 formula/config. Verify representative levels and boss→recovery drops. No silent coefficient edits.

## SB-M37-006 Level select if approved
No owner approval is currently assumed. Claude must not invent a shipping level-select UI/flow. It may expose a safe read-only/debug selection seam for tests only if clearly non-shipping. Mark `OWNER_REQUIRED` when approval is absent. This gate does not halt the overnight batch.

## SB-M37-007 Service implementation
Provide a narrow progression service separated from UI, economy and save serialization. M40 will own durable save schema. Service must expose snapshot/import seams only if needed, without writing its own incompatible save format.

## SB-M37-008 Tests
Require direct tests for cadence, current level, first-clear, duplicate callback, replay, reset/reload snapshot, large level numbers, invalid inputs, and M36 target calculations.

## Critical adversarial matrix
- complete same level twice
- duplicate/reentrant completion callback
- replay completed level then win
- replay loss
- stale completion from old level after frontier advanced
- invalid level ID/number
- load/import malformed progression snapshot
- level 10→11, 20→21, 310→311 boundaries
- owner cadence for high n
- progression must not mutate level content/catalog

## Regression floor
Focused M37, M36, M35, M30 terminal/retry, root suite, `git diff --check`.

## Successful code target
`AWAITING_AUDIT / M37-C001 V01 / LEVEL_SELECT_OWNER_GATE_REMAINS`