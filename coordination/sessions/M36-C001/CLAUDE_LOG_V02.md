# M36-C001 V02 — Claude Remediation Log

V01 audit: `coordination/sessions/M36-C001/CHATGPT_AUDIT_V01.md`
(verdict `CHANGES_REQUIRED / DIFFICULTY_V1_MIGRATION_INCOMPLETE`, F-M36-001)
V02 prompt: `coordination/sessions/M36-C001/CHATGPT_PROMPT_V02.md`
V02 criteria: `coordination/sessions/M36-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## F-M36-001 fix — remove class=dimension from the general production gate
- `scripts/data/production_level_validator.gd`: now rejects TEST, rejects
  unknown class, and requires each dimension in the 20..59 envelope
  (rectangular allowed). No class-specific band check. Class is not derived
  from dimensions.
- `scripts/data/difficulty_rules.gd`: introduces `PRODUCTION_CLASSES`,
  `ENVELOPE_MIN/MAX`, `is_within_production_envelope()`. The old bands are
  retired to `LEGACY_M21_BANDS` and reachable only via the explicitly named
  `legacy_m21_within_band()` seam (with a `BANDS`/`is_within_band` back-compat
  alias for offline M21-style tooling). Doc header rewritten to state the
  Difficulty V1 truth and that the old bands are legacy-only.
- `scripts/data/level_catalog.gd`: comment corrected (no legacy bands re-locked).
- `tests/run_tests.gd`: migrated `_run_production_difficulty_tests` from the
  retired cross-band assertions to the envelope truth (class-independent PASS
  cases + envelope-only rejection).

## Tests
- `tests/m36_v02_migration.gd` — 24x24 VERY_HARD, 38x38 EASY, 59x20 MEDIUM,
  20x59 HARD all production-legal; 19x24 / 60x24 / 30x19 envelope-invalid; TEST
  + unknown class invalid; legacy M21 seam still rejects 24x24 VERY_HARD while
  the general validator accepts it (proving isolation). **PASS**.
- Regression: `m36_difficulty_v1` PASS; `m35_level_catalog` PASS; root suite
  (`tests/run_tests.gd`) rerun after the assertion migration.

## Task logs
`coordination/sessions/M36-C001/task_logs_v02/SB-M36-001,002,006`.

## Gate
SB-M36-005 human difficulty calibration remains OWNER_REQUIRED (not fabricated).

## Handoff
`AWAITING_AUDIT / M36-C001 V02 / OWNER_PLAYTEST_GATE_REMAINS`

Root `TASKS.md` not edited. Continuing to M35 V02.
