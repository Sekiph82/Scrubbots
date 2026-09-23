# M36-C001 V01 — ChatGPT Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M36-C001 V01**

Implementation: `23fe01760eb75cd60ba5a50918c952c285afffaf`
Claude log: `coordination/sessions/M36-C001/CLAUDE_LOG_V01.md`

## Accepted
- Difficulty V1 cadence/target config reader exists.
- W/C/A/U/B/R/S model and separate Challenge/Session Load/Frustration seams exist.
- Representative target/cadence tests were added.
- SB-M36-005 is correctly left OWNER_REQUIRED.

## Blocking finding F-M36-001 — migration did not remove the legacy production legality rule
The current `scripts/data/difficulty_rules.gd` still declares the old dimension bands as the official production bands.
`scripts/data/production_level_validator.gd` still rejects production content whose class does not match those bands.
`LevelCatalog` still invokes that validator before M36's compatibility checker.

Thus the old class=dimension model remains an active production acceptance gate, contrary to SB-M36-001/002 and the 2026-09-12 owner decision.

The M36 comment that this remains for "M21 structural compatibility" is not sufficient: compatibility must be isolated to the legacy M21 path, not applied to future production catalog entries.

## Required migration
- production difficulty token validation must be class-token + 20..59 envelope based, not class-specific dimension bands;
- TEST remains rejected;
- rectangular 20..59 remains legal;
- explicit legacy M21 compatibility, if still needed, must be a narrow named compatibility seam/test rather than the general production validator;
- direct tests must prove 24x24 VERY_HARD and 38x38 EASY production legality.

## Owner gate
Human difficulty calibration (SB-M36-005) remains OWNER_REQUIRED after code remediation.

Verdict string:
`CHANGES_REQUIRED / M36-C001 V01 / DIFFICULTY_V1_MIGRATION_INCOMPLETE`
