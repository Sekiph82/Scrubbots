# SB-M52-C001 — FIRST 10 LEVEL PACK CHATGPT AUDIT CRITERIA

Verdict is based on actual admitted production truth, not requested labels.

## 1. Source integrity

Must verify all nine owner-selected source PNGs:
- exact path and SHA-256 match OWNER_M52_FIRST_10_LEVEL_PACK_V01;
- dimensions unchanged;
- alpha 255 for every logical pixel;
- only C01..C16;
- 3..12 used colors;
- source bytes never modified.

Level 1 Hazard Bot must remain byte/path-identical.

## 2. Exact import / LevelData

For each admitted L2..L10:
- one source/final-candidate pixel = one logical cell;
- no resize/resample/crop/pad;
- local palette only used C01..C16 colors, ascending C-ID;
- reconstruction equals final logical art exactly;
- LevelValidator PASS;
- ProductionLevelValidator PASS;
- metadata/preview exist and bind the exact final LevelData.

## 3. Solver

Every admitted level must have:
- authoritative SOLVED verdict;
- exact color conservation;
- deterministic accepted seed/config;
- fresh-trace replay reaches solved state;
- trace hash/evidence recorded.

DEADLOCK, UNKNOWN_BOUND, malformed or inconclusive candidates cannot be admitted.

## 4. Difficulty V1

Required class/order:
1 EASY existing,
2 EASY,
3 MEDIUM,
4 EASY,
5 HARD,
6 EASY,
7 EASY,
8 MEDIUM,
9 EASY,
10 VERY_HARD.

First-cycle target Challenge:
L1 20, L2 22, L3 40, L4 19, L5 58, L6 18, L7 21, L8 42, L9 19, L10 76.

For new levels:
- actual Challenge evidence must be authentic/provenance-bound;
- no score invented from dimensions/color count;
- absolute error <=3.5 for production admission;
- actual recovery guards:
  - D3-D4 >=15
  - D5-D6 >=20
  - D8-D9 >=15.

Unavailable/inconclusive analysis cannot be treated as pass.

## 5. Mutation integrity

If any derivative is used:
- canonical source unchanged;
- mutation lineage complete;
- parent/source hash, seed, operator/version, ordinal recorded;
- canonical palette/opacity preserved;
- full import/solver/analysis rerun after mutation;
- visual subject remains recognizable;
- if semantic evidence is unavailable, owner visual review remains required and production admission must not be falsely claimed.

No score editing or label-forcing.

## 6. Catalog

Full-pass outcome requires:
- exactly 10 production catalog entries;
- orders 1..10 exactly once;
- Level 1 unchanged;
- L2..L10 stable IDs from owner decision/prompt;
- no duplicate ID/order/path;
- level/metadata/preview paths exist;
- LevelCatalog.load_manifest PASS;
- validate_all PASS;
- DifficultyV1CatalogCheck PASS.

If any slot is blocked, the catalog must remain at the last fully valid admitted state rather than contain a fabricated placeholder.

## 7. Progression integration

For 10/10 pass:
- GameplayLaunchResolver resolves orders 1..10 correctly;
- no fallback Level 1 content;
- progression first-clear N -> N+1;
- Level 10 -> frontier 11;
- frontier 11 with no content returns CONTENT_MISSING;
- no shipping Level Select introduced.

## 8. Regression

Required touched suites and root regression exit 0.
- zero SCRIPT ERROR;
- no new unexplained engine errors;
- git diff --check clean.

Factory evidence used by the task must pass the exact relevant M03/M04/M05/M07 tests, but an unaudited/broken cross-repo handoff cannot be represented as trusted just because individual analysis tools work.

## 9. Evidence matrix

FIRST10_FINAL_MATRIX_V01.md must contain Level 1..10 with:
- order/id/subject
- dimensions/colors
- class
- target Challenge
- actual Challenge/delta
- solver status
- source/final hashes
- mutation count
- catalog status.

Every claim in the handoff log must be traceable to repository evidence.

## Verdicts

If all ten are fully admitted:
- AUDITED_PASS / M52-C001 / 10 OF 10 PRODUCTION ADMITTED

If implementation is correct but one or more slots honestly remain blocked:
- CODE_AUDIT_PASS / M52-C001 / PARTIAL CONTENT GATE REMAINS

If false admission, fabricated analysis, source mutation, solver bypass, catalog corruption or regression exists:
- CHANGES_REQUIRED
