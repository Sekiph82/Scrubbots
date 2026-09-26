# SB-M52-C001 — FIRST 10 LEVEL PACK IMPLEMENTATION PROMPT

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Support repository: `Sekiph82/ScrubBots-Level-Factory`

## Read first

Main game:
1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M52_FIRST_10_LEVEL_PACK_V01.md`
4. `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
5. `data/config/level_progression_v1.json`
6. `data/config/level_generator_acceptance_v1.json`
7. `data/config/difficulty_score_model_v1.json`
8. `data/palettes/scrubbots_palette_v3.json`
9. `docs/03_LEVEL_DATA_SPEC.md`
10. `docs/08_PIXEL_ART_PALETTE_RULES.md`
11. `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
12. `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
13. `scripts/tools/production_art_level_builder.gd`
14. `scripts/tools/level_batch_importer.gd`
15. `scripts/data/production_level_validator.gd`
16. `scripts/data/level_catalog.gd`
17. `scripts/app/gameplay_launch_resolver.gd`
18. `scripts/gameplay/solver/generation_gate.gd`
19. `scripts/gameplay/solver/solvability_solver.gd`
20. `scripts/difficulty/difficulty_progression_v1.gd`

Level Factory current main, read-only authority/reference:
- `src/scrubbots_pixel_factory/difficulty_analysis.py`
- `src/scrubbots_pixel_factory/qa/solver_gate.py`
- `src/scrubbots_pixel_factory/mutation.py`
- `src/scrubbots_pixel_factory/mutation_easing.py`
- `src/scrubbots_pixel_factory/mutation_hardening.py`
- `src/scrubbots_pixel_factory/mutation_attempts.py`
- `src/scrubbots_pixel_factory/mutation_targeting.py`
- current M03/M04/M05/M07 strict audits.

Do NOT edit root `TASKS.md`, owner decision files or ChatGPT audit/criteria files.

## Mission

Create an honest first production pack of Levels 1–10.

Level 1 remains exactly the existing `m21_level_001_hazard_bot`.

Levels 2–10 use the nine owner-selected source concepts already committed to main at:

`1ec599bfef82568f92413ac7dd24f558aa7bf53f`

Sources:

| Order | ID | Display | Required class | Target D | Source |
|---:|---|---|---|---:|---|
| 2 | `level_002_apple` | Apple | EASY | 22.0 | `res://assets/art/levels/source/easy/level_002_apple_32x32.png` |
| 3 | `level_003_palm_tree` | Palm Tree | MEDIUM | 40.0 | `res://assets/art/levels/source/medium/level_003_palm_tree_38x38.png` |
| 4 | `level_004_orange_cat` | Orange Cat | EASY | 19.0 | `res://assets/art/levels/source/easy/level_004_orange_cat_32x32.png` |
| 5 | `level_005_party_toucan` | Party Toucan | HARD | 58.0 | `res://assets/art/levels/source/hard/level_005_party_toucan_33x33.png` |
| 6 | `level_006_chicken` | Chicken | EASY | 18.0 | `res://assets/art/levels/source/easy/level_006_chicken_32x32.png` |
| 7 | `level_007_pigeon` | Pigeon | EASY | 21.0 | `res://assets/art/levels/source/easy/level_007_pigeon_32x32.png` |
| 8 | `level_008_butterfly` | Butterfly | MEDIUM | 42.0 | `res://assets/art/levels/source/medium/level_008_butterfly_32x32.png` |
| 9 | `level_009_frog` | Frog | EASY | 19.0 | `res://assets/art/levels/source/easy/level_009_frog_32x32.png` |
| 10 | `level_010_ice_cube` | Ice Cube | VERY_HARD | 76.0 | `res://assets/art/levels/source/very_hard/level_010_ice_cube_32x32.png` |

The exact source SHA-256 pins are in the owner decision. Verify every pin before doing any content work.

## Non-negotiable truth rules

1. Never change Level 1.
2. Never overwrite any of the nine canonical source PNGs.
3. Do not derive class from dimensions or used-color count.
4. Do not invent Challenge Scores.
5. Do not treat solver UNKNOWN_BOUND / INCONCLUSIVE as SOLVED.
6. Do not put a level in the production catalog merely because the user requested that slot.
7. Do not edit a score/label to force a pass.
8. Do not use old M21 dimension bands as production truth.
9. Do not silently bypass current main-game validators because Factory says ACCEPT.
10. Final production catalog admission is owned by current `Scrubbots@main`.

## Phase A — baseline source audit

For each source:

- verify exact SHA-256 from `OWNER_M52_FIRST_10_LEVEL_PACK_V01.md`;
- verify PNG dimensions;
- verify every logical pixel alpha == 255;
- verify every RGB is exactly one of canonical C01..C16;
- verify 3..12 distinct used colors;
- verify no resampling/interpolation metadata is being introduced by the pipeline;
- compute exact per-CID cell counts;
- preserve source bytes unchanged.

Create a deterministic report:
`coordination/sessions/M52-C001/evidence/SOURCE_AUDIT_V01.json`

Hard reject any source mismatch before import.

## Phase B — exact production-art import

Use `ProductionArtLevelBuilder` / existing batch importer semantics. Do not rewrite the historical generic importer.

Baseline candidate output paths:

- LevelData: `data/levels/<id>.json`
- metadata: `data/levels/metadata/<id>.metadata.json`
- preview: `assets/art/levels/previews/<id>.png`

For every baseline candidate prove:

- one source pixel = one logical cell;
- dimensions unchanged;
- C01..C16 only;
- local palette contains only actually-used colors in ascending global C-ID;
- source reconstruction == final LevelData reconstruction pixel-for-pixel;
- LevelValidator PASS;
- ProductionLevelValidator PASS under current Difficulty V1 production envelope.

Do NOT catalog yet.

## Phase C — canonical solver evidence

For each baseline candidate, use the canonical main-game five-slot / supply / routing semantics.

Use existing main-game `GenerationGate` + `SolvabilitySolver` or the exact equivalent accepted solver seam.

Requirements:

- deterministic seed/config recorded;
- exact color conservation PASS;
- authoritative verdict must be SOLVED;
- replay accepted trace against a fresh state and prove completion;
- store visited states, decisions, trace hash and solver version/provenance;
- UNKNOWN_BOUND / DEADLOCK / malformed = not admitted.

Because generated supply can be seed-dependent, bounded deterministic seed search is permitted. Store every attempted seed/outcome.

Create per-level solver evidence sidecars under:
`coordination/sessions/M52-C001/evidence/solver/<id>.json`

## Phase D — Difficulty V1 analysis

Target Challenge comes from the campaign level number, not artwork dimensions.

Targets:
- L2 22
- L3 40
- L4 19
- L5 58
- L6 18
- L7 21
- L8 42
- L9 19
- L10 76

Use the current `ScrubBots-Level-Factory` Difficulty V1 analysis implementation wherever it provides authentic M03/M04 evidence.

Important:
- Factory is an analysis/mutation support system here, not final admission authority.
- Re-resolve current Factory `main` at execution and record SHA.
- Do not use stale fixture-only evidence as production truth.
- If an analysis disposition says UNAVAILABLE / INCONCLUSIVE / ERROR, preserve that truth.
- Do not invent unavailable W/C/A/U/B/R/S components.
- Challenge evidence must be bound to exact level/source/state/solver provenance.

Acceptance:
- preferred |D-target| <= 2.0
- required default |D-target| <= 3.5
- never force beyond 5.0
- for this task, production admission requires <= 3.5 unless a separate owner decision explicitly approves otherwise.

Recovery on actual accepted scores:
- D3 - D4 >= 15
- D5 - D6 >= 20
- D8 - D9 >= 15

Create:
`coordination/sessions/M52-C001/evidence/difficulty/FIRST10_DIFFICULTY_MATRIX_V01.json`

Matrix must include target, actual D, delta, vector/evidence availability, solver binding, disposition, and recovery comparisons.

## Phase E — bounded derivative remediation only when needed

If a baseline candidate does not fit its slot but its source audit/import is legal:

- NEVER mutate the canonical source file.
- Create derivative candidates in:
  `coordination/sessions/M52-C001/candidates/<id>/`
  or a clearly isolated generated-candidate path.
- Use the current Level Factory safe mutation system where applicable.
- Choose easing when measured D is too high and hardening when D is too low.
- Keep the visual subject recognizable.
- Prefer same dimensions.
- Every mutation must preserve canonical palette/opacity.
- Preserve source hash, parent candidate hash, operator/version, seed, ordinal and lineage.
- Full re-import, main-game solver, replay, and Difficulty analysis after every mutation.
- Never edit a score directly.

Bound:
- max 40 mutation attempts per slot.
- stop immediately on first fully-valid candidate within target tolerance after deterministic tie-breaking.
- if no admissible candidate after the budget, mark that slot `NOT_ADMITTED / TARGET_MISS`.

Do not use image generation or silently redraw the source in this task. Mutation is logical/canonical-pixel remediation only.

## Phase F — visual/semantic preservation gate

For any derivative candidate:

- use Level Factory semantic/recognizability QA if current production-capable evidence exists;
- generate an exact nearest-neighbor preview;
- compute changed-cell ratio vs canonical source;
- store a diff mask/evidence;
- reject gross silhouette/subject destruction.

The owner-selected subject must remain recognizably:
Apple / Palm Tree / Orange Cat / Party Toucan / Chicken / Pigeon / Butterfly / Frog / Ice Cube.

If semantic QA is unavailable, do not pretend automated recognizability PASS; mark `OWNER_VISUAL_REVIEW_REQUIRED` for the derivative candidate.

Baseline source candidates need no new owner visual approval if they are admitted byte-exactly from the already selected source.

## Phase G — production export and metadata

Only fully admitted final candidates get production artifacts.

Final metadata must bind:

- campaign order
- stable ID
- requested class
- target Challenge
- actual Challenge + delta
- source SHA-256
- final candidate logical-art SHA-256
- LevelData SHA-256
- preview SHA-256
- palette CIDs/counts
- source dimensions
- solver version/config/evidence digest
- accepted seed
- trace hash
- analysis/factory SHA + evidence digest
- mutation lineage if any
- import/builder version

Do not modify core Level Data schema to store derived analytics.

## Phase H — catalog admission

Update:
`data/levels/catalog/production_catalog_v1.json`

Only after all admitted artifacts exist and validate.

Required final catalog:
- exactly 10 entries
- orders exactly 1..10
- order 1 remains `m21_level_001_hazard_bot` byte/path-identical
- orders 2..10 map to the stable IDs above
- no duplicate ID/order/path
- every metadata/preview path exists
- catalog `load_manifest()` PASS
- catalog `validate_all()` PASS
- DifficultyV1CatalogCheck PASS

If any one of L2..L10 remains NOT_ADMITTED:
- do NOT fabricate a 10-entry catalog;
- leave production catalog in last valid state;
- produce a clear blocker matrix and stop with `PARTIAL / OWNER_OR_REMEDIATION_REQUIRED`.

## Phase I — progression / actual game integration

When and only when catalog reaches 10 admitted entries:

Prove:
- `GameplayLaunchResolver` resolves level orders 1..10 exactly;
- no fallback Level 1 content is used for levels 2..10;
- after first-clear of level N, frontier advances to N+1;
- Home Play subtitle/frontier matches the actual next level;
- completion of Level 10 advances frontier to 11 and correctly reports CONTENT_MISSING until Level 11 exists, rather than replaying Level 10/1 under the wrong label;
- owner-locked no-shipping-Level-Select remains intact.

Add:
`tests/m52_first10_levels.gd`

This test must verify exact catalog order/difficulty/source provenance and progression resolution.

## Phase J — regression

Run at minimum:

Main Scrubbots:
- `tests/m21_real_art_level.gd` or current equivalent exact production-art suite
- `tests/m35_level_catalog.gd`
- `tests/m36_difficulty_v1.gd`
- `tests/m37_level_progression.gd`
- `tests/m40_save_system.gd`
- `tests/m52_first10_levels.gd`
- canonical solver/generation-gate suites touched by the task
- root `tests/run_tests.gd`
- `git diff --check`

Factory, if used:
- exact M03 solver tests relevant to evidence
- M04 challenge-score tests
- M05 QA/solver-gate tests used by the analysis path
- M07 mutation tests if any mutation is used

All changed-main suites must exit 0 with zero SCRIPT ERROR.

Do not claim Factory cross-repo handoff itself is audited/pass if its current strict audit does not support that claim.

## Phase K — evidence / log

Create:

`coordination/sessions/M52-C001/task_logs/SB-M52-C001_FIRST10_LEVEL_PACK.md`

Include:

- baseline main SHA
- resolved Factory main SHA
- source SHA verification 9/9
- baseline import results 9/9
- each candidate's target D / actual D / delta
- solver verdict / seed / visited / decisions / trace hash
- mutation count + final lineage if used
- recovery guard matrix
- final catalog count/order
- progression resolver 1..10 evidence
- all test results
- exact list of admitted vs blocked slots
- final implementation SHA

Also create:
`coordination/sessions/M52-C001/evidence/FIRST10_FINAL_MATRIX_V01.md`

One row per Level 1..10 with:
order, id, subject, dimensions, colors, class, target D, actual D, delta, solver, source hash, final hash, mutation count, catalog status.

## Completion labels

Use exactly one:

If all 10 are honestly admitted:
`AWAITING_CHATGPT_AUDIT / M52-C001 FIRST 10 LEVEL PACK / 10 OF 10 ADMITTED`

If any level remains blocked:
`AWAITING_CHATGPT_AUDIT / M52-C001 FIRST 10 LEVEL PACK / PARTIAL — <N> OF 10 ADMITTED`

Do not self-close M52 or edit TASKS.md.
