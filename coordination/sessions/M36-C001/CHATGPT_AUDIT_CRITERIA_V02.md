# M36-C001 V02 — Difficulty V1 Migration Audit Criteria

Close F-M36-001.

PASS requires:
1. the general production validator no longer enforces class-specific dimension bands;
2. known classes are EASY/MEDIUM/HARD/VERY_HARD;
3. production dimensions are independently 20..59 and rectangular;
4. TEST is rejected;
5. 24x24 VERY_HARD PASS;
6. 38x38 EASY PASS;
7. 59x20 MEDIUM PASS when all other LevelData requirements pass;
8. 19x24 and 60x24 fail envelope;
9. legacy M21 compatibility, if still needed, is isolated in an explicitly named compatibility seam and does not govern future catalog entries;
10. comments/docs claiming old bands are current single source are removed/corrected;
11. M35 catalog uses the migrated truth and passes its V02 cross-check;
12. cadence/Challenge model regressions stay green.

SB-M36-005 remains OWNER_REQUIRED.

Handoff:
`AWAITING_AUDIT / M36-C001 V02 / OWNER_PLAYTEST_GATE_REMAINS`