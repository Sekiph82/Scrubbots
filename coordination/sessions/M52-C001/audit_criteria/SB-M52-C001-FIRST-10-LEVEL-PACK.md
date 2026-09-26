# SB-M52-C001 FIRST 10 LEVEL PACK — CHATGPT AUDIT CRITERIA

## Verdicts
- AUDITED_PASS / OWNER_PLAYTEST_REQUIRED
- CHANGES_REQUIRED

## A. Source integrity
For Levels 2-10:
- exact owner source path exists;
- source Git blob/SHA-256 recorded;
- dimensions unchanged;
- alpha 255 for every source cell;
- every source RGB exactly canonical C01..C16;
- used-color count 3..12;
- source PNG bytes unchanged by Claude.

Level 1 source/data/metadata/preview must be baseline-identical.

## B. Production build
Each Level 2-10 must have:
- valid LevelData V1;
- exact owner difficulty;
- width/height equal source;
- ascending canonical local palette with only used colors;
- exact source reconstruction;
- valid metadata/provenance;
- valid preview reconstructed from final LevelData;
- deterministic/idempotent rebuild.

No resize, interpolation, crop, pad, recolor or nearest-color approximation.

## C. Difficulty semantics
Cadence must be exactly:
EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD.

No obsolete class=dimension/color logic.

No fabricated Challenge/SessionLoad/Frustration metrics. If no canonical analyzer exists, evidence must say NOT_AVAILABLE_M52.

## D. Solvability
For every Level 2-10:
- canonical GenerationGate / SolvabilitySolver used;
- deterministic seed/attempt evidence;
- conservation true;
- status SOLVED;
- trace hash recorded;
- replay proves solved;
- DEADLOCK and UNKNOWN_BOUND never treated as pass.

No gameplay/solver weakening.

## D1. Supply queue visibility/depth
- exactly 3 FIFO supply columns are used for this pack;
- player-facing visible depth is exactly 3 rows per column;
- visible depth 3 is NOT a total queue-depth cap;
- full hidden FIFO depth is preserved for each candidate;
- evidence records full queue lengths / hidden layout;
- solver proof consumes the full hidden queue, not only visible rows;
- five-slot capacity remains a separate 5-slot gameplay constraint.

## E. Catalog
Production catalog first ten orders exactly:
1 Hazard Bot
2 Apple
3 Palm Tree
4 Orange Cat
5 Party Toucan
6 Chicken
7 Pigeon
8 Butterfly
9 Frog
10 Ice Cube

Unique IDs/orders/paths; all referenced files exist; no TEST content.

## F. Runtime frontier
- frontier 1..10 resolves one-to-one to real catalog content;
- no Level-1 fallback/spoofing;
- Level 11 = CONTENT_MISSING;
- Home no longer shows Level 2 coming-soon when frontier is 2;
- forward-only/no shipping level-select policy preserved;
- progression/rewards remain exactly-once.

## G. Pack evidence
Machine-readable first-10 evidence sidecar exists and matches files/hashes/solver results.

## H. Tests
Required focused/regression suites from the task prompt all exit 0.
- zero SCRIPT ERROR;
- no new hidden FAIL;
- root suite PASS;
- git diff --check clean.

## I. Protected scope
Claude must not edit:
- TASKS.md;
- owner decision files;
- ChatGPT audit/criteria files;
- M42 approved Home assets/layout except legitimate frontier/content availability behavior;
- Heart economy;
- opening cinematic;
- palette authority.

## Final audit gate
Even on code pass, first 10 pack remains OWNER_PLAYTEST_REQUIRED until owner launches/clears representative levels and confirms visual/gameplay acceptance.
