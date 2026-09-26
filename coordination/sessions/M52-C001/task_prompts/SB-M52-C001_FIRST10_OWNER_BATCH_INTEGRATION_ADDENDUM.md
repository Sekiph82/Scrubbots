# SB-M52-C001 — FIRST 10 LEVEL PACK OWNER BATCH INTEGRATION ADDENDUM

Status: READY FOR CLAUDE
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: M52-C001 First 10 Level Pack
Authority: This addendum supplements `coordination/sessions/M52-C001/task_prompts/SB-M52-C001_FIRST10_LEVEL_PACK.md`.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M52-C001/task_prompts/SB-M52-C001_FIRST10_LEVEL_PACK.md`
4. `coordination/OWNER_M52_FIRST_10_LEVEL_PACK_V01.md`
5. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
6. `data/palettes/scrubbots_palette_v3.json`
7. `data/levels/catalog/production_catalog_v1.json`
8. `scripts/gameplay/supply/batch_supply_engine.gd`
9. `scripts/gameplay/supply/color_batch.gd`
10. `scripts/gameplay/solver/proof_state.gd`
11. `scripts/gameplay/solver/proof_kernel.gd`
12. `scripts/gameplay/solver/solvability_solver.gd`
13. `scripts/gameplay/runtime/production_gameplay_host.gd`
14. `scripts/app/gameplay_launch_resolver.gd`

Do NOT edit root `TASKS.md`, owner decision files, ChatGPT audit files, or the canonical source PNGs.

## Mission

Finish the playable production pack for campaign Levels 1–10 using the owner-specified batch/color layouts.

Important scope truth:

- Level 1 Hazard Bot already exists in production. **Do not change Level 1 content or its proven gameplay behavior.**
- Level 10 Ice Cube has already been separately supplied to you by the owner. Keep that instruction in force and use its owner input file below.
- This addendum supplies the owner batch/color plans for Levels 2–9 and requires the final runtime result to be a complete, launchable Level 1–10 pack.
- Do not create an eleventh content item, duplicate Level 1, or relabel another level as Level 1.

## Owner batch/color inputs

These files are authoritative first-candidate queue layouts:

- Level 2 Apple:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_002_APPLE_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 3 Palm Tree:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_003_PALM_TREE_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 4 Orange Cat:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_004_ORANGE_CAT_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 5 Party Toucan:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_005_PARTY_TOUCAN_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 6 Chicken:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_006_CHICKEN_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 7 Pigeon:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_007_PIGEON_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 8 Butterfly:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_008_BUTTERFLY_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 9 Frog:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_009_FROG_SUPPLY_BATCH_CANDIDATE_V01.md`
- Level 10 Ice Cube:
  `coordination/sessions/M52-C001/owner_inputs/LEVEL_010_ICE_CUBE_SUPPLY_BATCH_CANDIDATE_V01.md`

## Non-negotiable supply model

For Levels 2–10:

- exactly **3 FIFO supply columns**;
- player-visible depth is exactly **3 rows per column**;
- Row 1 is selectable, Rows 2–3 are preview-only;
- total queue depth is **not** limited to 3;
- every hidden batch in the owner files is real gameplay state and must remain in the FIFO queue;
- baseline slot capacity is **5**;
- every batch robot count must be **1..30**;
- per-color totals must equal the corresponding LevelData pixel totals exactly;
- total supply robot count must equal total ACTIVE cells exactly.

Do not truncate hidden rows. Do not reinterpret `preview_depth = 3` as queue depth.

## Critical color-ID rule

The owner files name colors by canonical global IDs such as `C08`, `C16`, etc.

Gameplay batches use the level's **local palette integer IDs**.

Therefore:

- resolve each owner Cxx through `scrubbots_palette_v3.json`;
- map it to the exact matching color inside that level's local `LevelData.palette`;
- create `ColorBatch` objects using the correct local palette integer ID;
- NEVER assume that global `C08` means local integer 7;
- fail closed if an owner Cxx is absent, duplicated, ambiguous, off-palette, or maps inconsistently.

Add tests for this mapping seam.

## Production implementation requirement

Implement the smallest reusable production mechanism needed to reproduce the owner queues exactly for Levels 2–10.

The implementation must:

1. Keep the owner queue definitions as deterministic content data, not scattered ad-hoc hardcoded branches throughout gameplay logic.
2. Build a real `BatchSupplyEngine` with `column_count = 3` and `preview_depth = 3`.
3. Load the **complete** three queues through accepted M23 supply semantics.
4. Preserve existing FIFO front-only selection behavior.
5. Preserve the current 5-slot placement semantics.
6. Preserve targeting, Railroad routing, clearing, completion and retry semantics.
7. Select the correct supply plan by the resolved production level identity.
8. In the shipping/AppState production path, Levels 2–10 must use their accepted owner supply plan.
9. A missing/malformed required production supply plan must fail closed. Do not silently fall back to a random/generated candidate for Levels 2–10.
10. Keep Level 1's existing proven supply/runtime behavior unchanged unless a tiny generic refactor is strictly necessary. Any such refactor must demonstrate zero behavior change for Level 1.

Do not weaken or replace `BatchSupplyGenerator`, `GenerationGate`, `ProofKernel`, `SolvabilitySolver`, routing, targetability or slot rules merely to make these content plans pass.

## Level content integration

For Levels 2–10, complete the existing M52 first-pack work so each level has honest production artifacts required by the catalog/runtime.

Required final campaign identity:

| Order | ID | Display |
|---:|---|---|
| 1 | existing Hazard Bot ID | Hazard Bot |
| 2 | `level_002_apple` | Apple |
| 3 | `level_003_palm_tree` | Palm Tree |
| 4 | `level_004_orange_cat` | Orange Cat |
| 5 | `level_005_party_toucan` | Party Toucan |
| 6 | `level_006_chicken` | Chicken |
| 7 | `level_007_pigeon` | Pigeon |
| 8 | `level_008_butterfly` | Butterfly |
| 9 | `level_009_frog` | Frog |
| 10 | `level_010_ice_cube` | Ice Cube |

The production catalog must contain exactly these ten campaign orders 1..10 for this pack, with no duplicate ID/order/path.

The AppState progression frontier must resolve each order to the correct real content. There must be no Hazard Bot fallback disguised as another level.

## Exact owner-candidate verification

For **every Level 2–10**:

### A. Static validation

Verify and record:

- source image dimensions;
- source image SHA-256;
- exact source pixel/color totals;
- level artifact dimensions;
- local palette contents;
- exact owner Cxx -> local palette ID mapping;
- queue lengths for Column 1 / 2 / 3;
- every batch count;
- max batch count <= 30;
- full hidden FIFO layout;
- per-color conservation;
- grand-total conservation.

### B. Canonical solver proof

Construct `ProofState` from the **full owner queue state**, including all hidden rows.

Run the canonical `SolvabilitySolver`.

Only `SOLVED` is a pass.

- `DEADLOCK` is not a pass.
- `UNKNOWN_BOUND` is not a pass.
- timeout/incomplete proof is not a pass.

For SOLVED record:

- visited states;
- decisions;
- solver trace;
- trace hash;
- replay result.

Replay the solver trace through the accepted transition semantics and require PASS.

### C. Owner intended solution sequence

Each owner input file includes an **Intended column-click sequence**.

Independently replay that exact intended sequence against the real proof/gameplay transition kernel.

For each step record at minimum:

- step number;
- selected column;
- front batch ID/color/count;
- placed slot;
- number of clears reached after quiescence;
- remaining ACTIVE cells;
- remaining full queue lengths;
- occupied-slot snapshot.

The intended sequence passes only if, at its end:

- ACTIVE cells = 0;
- supply exhausted;
- all 5 slots empty;
- no illegal placement occurred;
- no hidden FIFO batch was skipped.

If canonical solver returns SOLVED but the owner intended sequence fails, **do not silently replace the owner sequence**. Report the divergence and the solver-found alternative trace. Keep that level pending owner approval.

If the owner candidate itself is DEADLOCK/UNKNOWN, do not regenerate/repartition/mutate it without owner approval. Report the exact blocker.

## Runtime proof

After solver acceptance, prove the actual production stack uses the same accepted queues.

For every Level 2–10:

1. Resolve the level through the real production catalog/AppState path.
2. Build `ProductionGameplayHost`.
3. Confirm the supply debug snapshot exactly matches the accepted owner queue layout before any click.
4. Confirm the player snapshot exposes only 3 visible rows per column.
5. Confirm hidden queue depth remains present in authoritative state.
6. Replay the accepted intended sequence through production input where practical, or use the nearest accepted headless production-runtime seam while preserving the same real engines.
7. Confirm terminal result is WON and board/supply/slots are fully exhausted/clear.

No test-only alternate supply implementation may be used as proof of shipping behavior.

## Difficulty metadata

Preserve the owner-locked campaign classes from the canonical M52 prompt.

Do not invent Challenge Score values or analyzer outputs.

If the canonical Difficulty V1 analyzer cannot produce a documented real value for a level, retain/report the explicit unavailable/blocker state required by the master M52 prompt rather than fabricating a score.

## Required tests

At minimum add or update tests covering:

- owner supply plan parsing/loading;
- Cxx global-to-local palette mapping;
- malformed/missing plan fail-closed behavior;
- every Level 2–10 queue exactness;
- hidden FIFO depth > 3 preservation;
- max batch <= 30;
- per-color and grand-total conservation;
- exact intended click-sequence replay for each level;
- canonical solver SOLVED + trace replay for each accepted level;
- production catalog exactly 10 ordered entries;
- progression orders 1..10 resolve to the correct IDs;
- ProductionGameplayHost starts each Level 2–10 with the exact accepted queues;
- Level 1 regression unchanged.

Run the relevant M23–M40 gameplay/catalog/progression regression suites plus any M52 tests affected by the implementation.

Do not claim PASS around pre-existing warnings unless the actual required assertion passed.

## Deliverables

Commit and push to `main`.

Create one implementation log:

`coordination/sessions/M52-C001/CLAUDE_FIRST10_OWNER_BATCH_INTEGRATION_LOG.md`

The log must contain:

- implementation commit SHA(s);
- final main HEAD;
- files added/changed;
- Level 1 regression result;
- one table for Levels 2–10 with:
  - level/order;
  - source SHA-256;
  - dimensions;
  - total cells;
  - batch count;
  - queue depths C1/C2/C3;
  - max batch size;
  - conservation result;
  - canonical solver status;
  - visited;
  - decisions;
  - trace hash;
  - solver replay;
  - exact owner-click replay;
  - production runtime smoke;
  - catalog status;
- exact blocker details for any level not accepted;
- test commands and results;
- `git status` clean confirmation.

## Stop conditions

Stop and report rather than fabricating completion if any of these occur:

- an owner source PNG hash/content does not match current repo truth;
- an owner queue file is internally inconsistent;
- Cxx cannot map exactly to the level's local palette;
- conservation fails;
- an owner batch exceeds 30;
- solver result is not SOLVED;
- solver trace replay fails;
- exact owner intended sequence fails;
- runtime queue differs from the solved queue;
- catalog/progression launches the wrong level;
- a required change would alter Level 1 gameplay behavior;
- a required change would weaken canonical gameplay correctness.

Do not edit `TASKS.md`. ChatGPT will audit the result and update tracking after the implementation is complete.
