# SB-M52-C001 — FIRST 10 LEVEL PACK IMPLEMENTATION PROMPT

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: M52 Production Content Scale-Up
Sprint: M52-C001 First 10 Level Pack

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M52_C001_FIRST_10_LEVEL_PACK_DECISION_V01.md`
4. `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
5. `docs/03_LEVEL_DATA_SPEC.md`
6. `docs/08_PIXEL_ART_PALETTE_RULES.md`
7. `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
8. `scripts/tools/production_art_level_builder.gd`
9. `scripts/tools/level_batch_importer.gd`
10. `scripts/data/level_catalog.gd`
11. `scripts/data/production_level_validator.gd`
12. `scripts/gameplay/solver/generation_gate.gd`
13. `scripts/gameplay/solver/solvability_solver.gd`
14. `scripts/app/gameplay_launch_resolver.gd`
15. `data/levels/catalog/production_catalog_v1.json`
16. `data/config/level_progression_v1.json`
17. `data/config/level_generator_acceptance_v1.json`

Do NOT edit:
- root `TASKS.md`
- owner decision files
- ChatGPT audit/criteria files

## Mission

Turn the owner-selected Level 2-10 PNG sources into real production LevelData, metadata, previews and catalog entries so Levels 1-10 are playable through the real campaign frontier.

Level 1 remains the existing Hazard Bot and must not be modified.

Locked mapping:

| Level | Difficulty | Source | ID |
|---:|---|---|---|
| 1 | EASY | existing Hazard Bot | `m21_level_001_hazard_bot` |
| 2 | EASY | `assets/art/levels/source/easy/level_002_apple_32x32.png` | `level_002_apple` |
| 3 | MEDIUM | `assets/art/levels/source/medium/level_003_palm_tree_38x38.png` | `level_003_palm_tree` |
| 4 | EASY | `assets/art/levels/source/easy/level_004_orange_cat_32x32.png` | `level_004_orange_cat` |
| 5 | HARD | `assets/art/levels/source/hard/level_005_party_toucan_33x33.png` | `level_005_party_toucan` |
| 6 | EASY | `assets/art/levels/source/easy/level_006_chicken_32x32.png` | `level_006_chicken` |
| 7 | EASY | `assets/art/levels/source/easy/level_007_pigeon_32x32.png` | `level_007_pigeon` |
| 8 | MEDIUM | `assets/art/levels/source/medium/level_008_butterfly_32x32.png` | `level_008_butterfly` |
| 9 | EASY | `assets/art/levels/source/easy/level_009_frog_32x32.png` | `level_009_frog` |
| 10 | VERY_HARD | `assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png` | `level_010_ice_cube` |

## A. Baseline / source integrity

Before changing production content:

1. Confirm clean/equal `main`.
2. Record baseline SHA.
3. Record for each Level 2-10 source:
   - Git blob SHA;
   - SHA-256;
   - dimensions;
   - alpha status;
   - exact distinct RGB values;
   - mapped C-IDs and cell counts.
4. Verify:
   - PNG only;
   - width/height each in 20..59;
   - every source cell alpha = 255;
   - every RGB exactly matches canonical C01..C16;
   - distinct used colors = 3..12.
5. Source files are immutable. Do not rewrite or normalize the PNG bytes themselves.

If any source fails those gates, stop before catalog mutation and report the exact blocker.

## B. Production build path

Use `ProductionArtLevelBuilder` semantics, not a shortcut that bypasses canonical production normalization.

You may create a small deterministic headless M52 build/orchestration tool or production batch manifest/runner if needed.

For each new level:

- source PNG remains exact;
- one pixel = one logical cell;
- no resize/resample/crop/pad/recolor;
- LevelData V1 only;
- difficulty exactly as owner-locked above;
- local palette contains only used canonical colors;
- local palette ordered ascending by global C-ID;
- cells remapped only as needed to preserve the exact visible source pixels;
- reconstructed final image must be byte/pixel equivalent to source RGBA;
- metadata must record source/provenance/build information using the existing builder contract.

Desired destinations:

### Level 2
- `data/levels/level_002_apple.json`
- `data/levels/metadata/level_002_apple.metadata.json`
- `assets/art/levels/previews/level_002_apple.png`

### Level 3
- `data/levels/level_003_palm_tree.json`
- `data/levels/metadata/level_003_palm_tree.metadata.json`
- `assets/art/levels/previews/level_003_palm_tree.png`

### Level 4
- `data/levels/level_004_orange_cat.json`
- `data/levels/metadata/level_004_orange_cat.metadata.json`
- `assets/art/levels/previews/level_004_orange_cat.png`

### Level 5
- `data/levels/level_005_party_toucan.json`
- `data/levels/metadata/level_005_party_toucan.metadata.json`
- `assets/art/levels/previews/level_005_party_toucan.png`

### Level 6
- `data/levels/level_006_chicken.json`
- `data/levels/metadata/level_006_chicken.metadata.json`
- `assets/art/levels/previews/level_006_chicken.png`

### Level 7
- `data/levels/level_007_pigeon.json`
- `data/levels/metadata/level_007_pigeon.metadata.json`
- `assets/art/levels/previews/level_007_pigeon.png`

### Level 8
- `data/levels/level_008_butterfly.json`
- `data/levels/metadata/level_008_butterfly.metadata.json`
- `assets/art/levels/previews/level_008_butterfly.png`

### Level 9
- `data/levels/level_009_frog.json`
- `data/levels/metadata/level_009_frog.metadata.json`
- `assets/art/levels/previews/level_009_frog.png`

### Level 10
- `data/levels/level_010_ice_cube.json`
- `data/levels/metadata/level_010_ice_cube.metadata.json`
- `assets/art/levels/previews/level_010_ice_cube.png`

Use deterministic, idempotent generation. Re-running on unchanged source should report unchanged rather than creating divergent output.

## C. Difficulty semantics

The owner has locked the campaign class labels.

Do NOT:
- derive class from dimensions;
- derive class from color count;
- revive old EASY 20..29 / MEDIUM 30..39 / etc rules;
- change the source art merely to satisfy an obsolete difficulty band.

If a canonical real-level Challenge/SessionLoad/Frustration analyzer exists in the repo, run it and preserve its real outputs.

If no such analyzer exists, do NOT invent those values. Record that full Challenge/SessionLoad/Frustration evidence remains an M53 QA gate. This must not be faked inside LevelData or metadata.

## D. Authoritative solvability gate

Every Level 2-10 candidate must be proven playable under the current canonical gameplay semantics before catalog admission.

Use the existing:
- `GenerationGate`
- `SolvabilitySolver`
- canonical BatchSupply/slot/routing rules

Do not invent alternate gameplay.

For each level:
1. locate the canonical runtime column count / preview depth / supply configuration from existing gameplay authority;
2. use deterministic seeds;
3. search only through a bounded, reproducible seed/attempt procedure;
4. require exact per-color conservation;
5. require solver status `SOLVED`;
6. replay the emitted solution trace and require exact completion;
7. record accepted seed, attempt, visited state count, decisions, trace hash and replay result in M52 QA evidence.

Hard rules:
- `DEADLOCK` = reject;
- `UNKNOWN_BOUND` = reject/inconclusive, never pass;
- no solver-bound increase without documenting why;
- no source mutation to force a pass;
- no weakening TargetSelector/routing/reachability/slot semantics.

If any Level 2-10 cannot be proven solved under the current canonical rules, stop before publishing the final 1..10 catalog and report that exact level/blocker.

## E. Production catalog

Only after all nine levels pass source/build/solver gates:

Update:
`data/levels/catalog/production_catalog_v1.json`

Final catalog must contain exactly these campaign orders for the first pack:

1. `m21_level_001_hazard_bot`
2. `level_002_apple`
3. `level_003_palm_tree`
4. `level_004_orange_cat`
5. `level_005_party_toucan`
6. `level_006_chicken`
7. `level_007_pigeon`
8. `level_008_butterfly`
9. `level_009_frog`
10. `level_010_ice_cube`

Requirements:
- unique ID;
- unique order;
- canonical level path;
- metadata path;
- preview path;
- all referenced files exist and validate;
- no TEST content;
- no duplicate/alias path.

Level 1 bytes/data/metadata/preview remain unchanged.

## F. Campaign / Home / launch behavior

Update only what is necessary so the real progression frontier resolves through the expanded catalog.

Prove:
- Level 1 launches Level 1;
- after first clear, frontier Level 2 launches Apple;
- orders 3..10 resolve to the matching real catalog level;
- no fallback-to-Level-1;
- no number spoofing;
- Level 11 returns `CONTENT_MISSING`;
- Home Play subtitle reflects the real frontier;
- the old `Level 2 is coming soon.` state disappears once Level 2 exists;
- forward-only/no-shipping-level-select policy remains unchanged;
- rewards/progression remain exactly-once.

Do not create a player-facing level picker.

## G. First-10 pack evidence / manifest

Create a machine-readable sidecar for this pack, for example:

`data/levels/catalog/first_10_pack_evidence_v1.json`

It should contain per campaign level:
- order;
- ID;
- difficulty;
- source path;
- source SHA-256;
- dimensions;
- used C-IDs / counts;
- LevelData path/hash;
- preview path/hash;
- metadata path/hash;
- source reconstruction equality;
- production validation result;
- solver status;
- accepted deterministic seed/attempt;
- trace hash;
- replay solved;
- Challenge/SessionLoad/Frustration fields only if produced by an existing canonical analyzer; otherwise explicit `NOT_AVAILABLE_M52`, not fabricated numbers.

Keep schema/version explicit.

## H. Focused tests

Add one focused suite such as:
`tests/m52_first_10_level_pack.gd`

It must directly prove at minimum:

1. production catalog size >=10 and orders 1..10 are exact/unique;
2. order 1 remains Hazard Bot;
3. orders 2..10 map exactly to owner IDs;
4. owner difficulty cadence is exact;
5. every Level 2-10 file loads;
6. every dimension remains the source dimension;
7. every palette entry is canonical C01..C16;
8. used-color count 3..12;
9. no semi-alpha logical source;
10. preview reconstruction matches source exactly;
11. metadata source path/hash matches source;
12. production validation passes;
13. solver evidence for each Level 2-10 is SOLVED;
14. replay evidence completes;
15. Level 1 source/output hashes are unchanged from baseline;
16. launch resolver resolves frontier 1..10 one-to-one;
17. frontier 11 is CONTENT_MISSING;
18. no level-select shipping regression;
19. no duplicate production IDs/orders/paths;
20. repeat build is deterministic/idempotent.

Also update existing catalog/progression tests where expectations legitimately change from catalog size 1 to 10. Preserve their adversarial cases.

## I. Required regression runs

Run at minimum:

- `tests/palette_v3_leveldata_contract.gd`
- `tests/m21_real_art_smoke.gd`
- `tests/m27_generation_retry.gd`
- `tests/m35_level_catalog.gd`
- `tests/m35_v02_hardening.gd`
- `tests/m36_difficulty_v1.gd`
- `tests/m36_v02_migration.gd`
- `tests/m37_level_progression.gd`
- `tests/m37_v02_strict.gd`
- `tests/m37_v03_forward_only.gd`
- `tests/m40_v04_bootstrap.gd`
- `tests/m42_home.gd`
- `tests/m42_navigation.gd`
- new `tests/m52_first_10_level_pack.gd`
- root `tests/run_tests.gd`
- `git diff --check`

All must exit 0 with zero SCRIPT ERROR.

Pre-existing intentionally induced engine ERROR lines may remain only if proven baseline-identical.

## J. Do not overreach

Do NOT:
- change gameplay mechanics;
- change palette authority;
- repaint source PNGs;
- add Level 11;
- build Shop/Collection/etc;
- reopen Home visual work;
- alter M42 owner-approved Home;
- modify Heart economy;
- modify opening cinematic;
- create speculative future levels;
- edit `TASKS.md`.

## K. Commit / log

Keep the implementation auditable. One implementation commit is preferred, with a separate evidence/log commit if needed.

Create:
`coordination/sessions/M52-C001/task_logs/SB-M52-C001-FIRST-10-LEVEL-PACK.md`

Log:
- baseline SHA;
- final implementation SHA;
- changed files;
- exact source hashes/dimensions/colors;
- each generated LevelData/metadata/preview hash;
- solver result per Level 2-10;
- catalog mapping 1..10;
- tests;
- any pre-existing engine warnings;
- git status clean / branch equal.

Do NOT claim M52-C001 closed. Finish exactly:

`AWAITING_CHATGPT_AUDIT / M52-C001 FIRST 10 LEVEL PACK`
