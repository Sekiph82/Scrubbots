# M35-C001 V01 — ChatGPT Audit Criteria

Milestone: `M35 — Level Catalog`
Tasks: `SB-M35-001..SB-M35-011`

Authority:
- root `TASKS.md`
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- current LevelData/LevelLoader/ProductionLevelValidator contracts
- `data/levels/` production/test separation

## Governance
Claude implements/tests only. Root `TASKS.md` is read-only.
Every task gets a separate GitHub log:
`coordination/sessions/M35-C001/task_logs/<TASK_ID>.md`
plus canonical `CLAUDE_LOG_V01.md`.

## SB-M35-001 Production LevelCatalog
Provide one explicit production catalog authority. It must be declarative/read-only from gameplay consumers and must not discover arbitrary files at runtime by broad directory scan if that can accidentally include test fixtures.

## SB-M35-002 Stable IDs
Every production level has a unique stable ID. IDs must not depend on filesystem enumeration order, transient array position, or mutable display name.

## SB-M35-003 Stable ordering
Catalog order must be deterministic and explicitly represented. Duplicate order positions or unstable lexical/OS order are invalid.

## SB-M35-004 Difficulty
Catalog exposes the current player-facing difficulty class. M35 must not re-lock obsolete dimension=difficulty semantics. Difficulty values must be compatible with the owner-locked Difficulty V1 model and M36 migration.

## SB-M35-005 Dimensions
Catalog exposes width/height from validated LevelData and proves rectangular support plus 20..59 production envelope where applicable.

## SB-M35-006 Preview
Catalog provides a stable preview/reference field or read model suitable for later UI without requiring gameplay scene instantiation. Missing preview must have defined behavior; do not fabricate art.

## SB-M35-007 Duplicate detection
Detect duplicate stable IDs, duplicate authoritative ordering keys, and duplicate path aliases that resolve to the same production level. Fail closed.

## SB-M35-008 Missing-file detection
Catalog validation must fail closed when a referenced production level/metadata/required preview path is missing or unreadable.

## SB-M35-009 Production/test separation
Production catalog must exclude engineering fixtures such as `test_3x2.json`, `test_40x40.json`, `test_50x50.json`, `test_59x59.json`.

## SB-M35-010 Reject TEST fixture in production catalog
Even if a TEST file is manually inserted into a catalog source, validation must reject it based on canonical metadata/type/rules, not filename convention alone.

## SB-M35-011 Batch validation
Provide deterministic batch validation over every catalog entry. Result must include entry-specific failures and an aggregate fail-closed verdict. One invalid entry cannot silently vanish from validation.

## Adversarial matrix
Audit must inspect:
- empty catalog
- one valid production level
- duplicate ID
- duplicate order
- missing file
- malformed LevelData
- TEST fixture insertion
- wrong/unknown difficulty token
- rectangular production level
- max-envelope metadata
- path normalization/alias duplicate where applicable
- repeated load/validation determinism
- catalog mutation attempts do not mutate canonical entries

## Required regression floor
- focused M35 tests
- existing LevelData/LevelLoader/ProductionLevelValidator tests
- root suite
- M21 production level still loads
- `git diff --check`

## Successful code target
`AWAITING_AUDIT / M35-C001 V01`
No owner visual gate is required merely to establish catalog correctness.