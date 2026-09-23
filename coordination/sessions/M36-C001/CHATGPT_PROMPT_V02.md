# M36-C001 V02 — Complete Difficulty V1 Production Migration

Read V01 audit + V02 criteria.

Remove the obsolete class=dimension rule from the GENERAL production validation path.
Do not weaken the 20..59 board envelope, TEST rejection, palette/data validation, or rectangular support.

If M21 needs a historical compatibility check, isolate it by name/path so only M21 explicitly opts into it.

Update current comments/docs/tests that still call legacy bands official production truth.

Add direct production-level fixtures:
- 24x24 VERY_HARD valid
- 38x38 EASY valid
- rectangular cross-class valid
- below/above envelope invalid
- TEST invalid

Rerun M35 catalog after migration.

Create V02 task logs for SB-M36-001,002,006 and canonical CLAUDE_LOG_V02.md.
Do not fabricate SB-M36-005 human playtest.

Handoff:
`AWAITING_AUDIT / M36-C001 V02 / OWNER_PLAYTEST_GATE_REMAINS`