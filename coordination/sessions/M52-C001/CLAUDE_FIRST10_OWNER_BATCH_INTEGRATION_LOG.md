# M52-C001 — First 10 Owner Batch Integration — Claude Log

Status: **AWAITING_CHATGPT_AUDIT** — Levels 1–10 playable through the production catalog with owner supply plans.
Prompts: `task_prompts/SB-M52-C001_FIRST10_OWNER_BATCH_INTEGRATION_ADDENDUM.md` + `task_prompts/SB-M52-C001_LEVEL002_APPLE_V02_CORRECTION.md`.
Owner authorization for the production catalog edit: given in chat 2026-09-26 (specific to `data/levels/catalog/production_catalog_v1.json`, M52-C001 Levels 2–10).

## Commits

- Implementation: **`2b3d29f550dd985ac0e94ff7ec3f8b7310ad7244`** — `M52-C001: integrate owner supply plans; publish Levels 1-10 catalog` (rebased onto owner docs `f50b8a0`).
- This log: the commit that adds this file (its SHA is the resulting `main` HEAD; reported in the hand-off message).
- Earlier M52-C001 commits kept: `6e092d9` (Level 2–10 LevelData build, importer envelope fix), `f98edbf` (first Level 010 candidate verification; its candidate/evidence files were superseded and removed in `2b3d29f`).

## Files added / changed (implementation commit)

| File | Change |
|---|---|
| `scripts/gameplay/supply/supply_plan_loader.gd` | NEW shipping loader: declarative plan → real `BatchSupplyEngine` (3 cols / 3 visible rows) via `ColorBatch.make` + `load_candidate`; global Cxx → local palette index through the palette authority; full hidden FIFO; batch 1..30; per-color + grand conservation; fail-closed |
| `data/levels/supply/level_0{02..10}_*_supply_v1.json` | NEW owner plans (exact queues + intended clicks + owner-input path/SHA-256). Apple = **V02** |
| `scripts/data/level_catalog.gd`, `level_catalog_entry.gd` | optional `supply_plan_path`; declared plans must be canonical, unique and load for that exact level, else the entry fails closed |
| `scripts/app/gameplay_launch_resolver.gd` | returns `supply_plan_path` |
| `scripts/gameplay/runtime/production_gameplay_host.gd` | `supply_plan_path` export (set from resolver in the AppState path); non-empty → `SupplyPlanLoader`, failure → `supply_plan_invalid:*` (no generator fallback); empty → unchanged seed-1 generator |
| `data/levels/catalog/production_catalog_v1.json` | orders 2–10 added (owner-approved) |
| `tools/verify_m52_supply_candidate.gd` | verifier via the shipping loader (static record, owner click replay per step, solver + replay) |
| `coordination/sessions/M52-C001/evidence/owner_plans/*_verification.json` | per-level evidence (map, full layout, per-step click trace, solver trace/hash/replay) |
| `tests/m52_owner_supply_plans.gd` | NEW focused suite |
| `tests/m40_v04_bootstrap.gd`, `tests/m42_home.gd`, `tests/m42_navigation.gd` | expectations moved from "frontier 2 = CONTENT_MISSING" to frontier 11; frontier 2 now asserts Apple / enabled Play / CONTINUE enabled |

Not changed: `BatchSupplyGenerator`, `BatchSupplyEngine`, `ColorBatch`, `ProofState`, `ProofKernel`, `SolvabilitySolver`, `GenerationGate`, routing/targeting/slots, source PNGs, `TASKS.md`, owner/audit files.

## Catalog (production, final)

| Order | ID | Supply |
|---:|---|---|
| 1 | `m21_level_001_hazard_bot` | M23 generator seed 1 (unchanged, no plan) |
| 2 | `level_002_apple` | `level_002_apple_supply_v1.json` (owner **V02**) |
| 3 | `level_003_palm_tree` | `level_003_palm_tree_supply_v1.json` |
| 4 | `level_004_orange_cat` | `level_004_orange_cat_supply_v1.json` |
| 5 | `level_005_party_toucan` | `level_005_party_toucan_supply_v1.json` |
| 6 | `level_006_chicken` | `level_006_chicken_supply_v1.json` |
| 7 | `level_007_pigeon` | `level_007_pigeon_supply_v1.json` |
| 8 | `level_008_butterfly` | `level_008_butterfly_supply_v1.json` |
| 9 | `level_009_frog` | `level_009_frog_supply_v1.json` |
| 10 | `level_010_ice_cube` | `level_010_ice_cube_supply_v1.json` |

Frontier 1..10 resolve one-to-one through AppState → catalog → resolver → host; frontier 11 = `CONTENT_MISSING`.

## Level 2 Apple

Owner V01 was rejected (its totals included C16 82 and did not match the committed PNG, which has no C16). Only **V02** (`owner_inputs/LEVEL_002_APPLE_SUPPLY_BATCH_CANDIDATE_V02.md`) is used: C08 639, C01 296, C11 56, C04 23, C12 10, total 1024, 36 batches, 12/12/12 — matches the PNG exactly.

## Levels 2–10 results

All: source SHA-256 = committed PNG; plan == owner markdown (columns, counts, clicks; re-parsed in the test); every batch 1..30; per-color + grand conservation exact; solver ProofState holds the full hidden queue; solver decisions = total batches.

| L | ID | Class | Source SHA-256 (prefix) | Dim | Cells | Batches | C1/C2/C3 | Max | Conservation | Solver | Visited | Decisions | Trace hash | Solver replay | Owner-click replay | Runtime | Catalog |
|---:|---|---|---|---|---:|---:|---|---:|---|---|---:|---:|---:|---|---|---|---|
| 2 | `level_002_apple` | EASY | `b1dd3b414738cf05` | 32×32 | 1024 | 36 | 12/12/12 | 30 | PASS | SOLVED | 37 | 36 | 4098941249 | PASS | PASS | WON | order 2 |
| 3 | `level_003_palm_tree` | MEDIUM | `84960199759b1c3a` | 38×38 | 1444 | 51 | 17/17/17 | 30 | PASS | SOLVED | 59 | 51 | 3808086370 | PASS | PASS | WON | order 3 |
| 4 | `level_004_orange_cat` | EASY | `0b8cbc068d1d070c` | 32×32 | 1024 | 39 | 13/13/13 | 30 | PASS | SOLVED | 40 | 39 | 2117980132 | PASS | PASS | WON | order 4 |
| 5 | `level_005_party_toucan` | HARD | `c95c0fd4021bb90e` | 33×33 | 1089 | 41 | 14/14/13 | 30 | PASS | SOLVED | 46 | 41 | 3056207161 | PASS | PASS | WON | order 5 |
| 6 | `level_006_chicken` | EASY | `9e15e570a7b8d5a3` | 32×32 | 1024 | 40 | 14/13/13 | 30 | PASS | SOLVED | 41 | 40 | 315727168 | PASS | PASS | WON | order 6 |
| 7 | `level_007_pigeon` | EASY | `ca6004936d2ab9f4` | 32×32 | 1024 | 39 | 13/13/13 | 30 | PASS | SOLVED | 40 | 39 | 2191893116 | PASS | PASS | WON | order 7 |
| 8 | `level_008_butterfly` | MEDIUM | `9a623fece6769086` | 32×32 | 1024 | 37 | 13/12/12 | 30 | PASS | SOLVED | 38 | 37 | 2524445735 | PASS | PASS | WON | order 8 |
| 9 | `level_009_frog` | EASY | `b0bd1638961cd69e` | 32×32 | 1024 | 38 | 13/13/12 | 30 | PASS | SOLVED | 40 | 38 | 2614056311 | PASS | PASS | WON | order 9 |
| 10 | `level_010_ice_cube` | VERY_HARD | `a39b54c0adc05ca4` | 32×32 | 1024 | 40 | 14/13/13 | 30 | PASS | SOLVED | 47 | 40 | 1273423104 | PASS | PASS | WON | order 10 |

Full SHA-256s, Cxx→local maps, full hidden layouts, per-step click records (column, front batch, placed slot, clears, ACTIVE left, queue lengths, slot snapshot) and solver traces: `evidence/owner_plans/<id>_verification.json`.

Cxx → local palette maps (never Cxx == index), e.g. Ice Cube C02→0, C03→1, C05→2, C06→3, C07→4, C08→5, C13→6, C14→7, C15→8, C16→9; Pigeon C01→0, C08→1, … C16→7.

No level returned DEADLOCK/UNKNOWN_BOUND; no owner queue was regenerated, repartitioned or mutated. Solver bounds unchanged (200000 / 400).

## Production-runtime verification (tests/m52_owner_supply_plans.gd, Levels 2–10)

Per level, shipping path: `AppState` frontier N (real `record_win` 1..N-1) → production catalog → `GameplayLaunchResolver` → `ProductionGameplayHost.build()`:

- resolved entry id / level / plan path correct — 9/9;
- runtime supply `debug_snapshot` == accepted owner queues before any click — 9/9;
- player preview ≤ 3 rows per column, authoritative remaining == full queue, hidden depth > 3 present — 9/9;
- owner intended clicks sent through `ProductionInputController.activate_front` (real runtime ticked to quiescence between clicks), every click accepted — 9/9;
- terminal **WON**, 0 ACTIVE cells, supply exhausted, all 5 slots empty — 9/9.

## Level 1

Unchanged. No diff since pre-M52 baseline `f861d27` in Level 1 LevelData/metadata/preview/source, `BatchSupplyGenerator`, `BatchSupplyEngine` or the solver package. Catalog order 1 has no `supply_plan_path`; `m52_owner_supply_plans` asserts Level 1's AppState-built supply equals `BatchSupplyGenerator.generate(level, 3, 3, 1)` exactly; `m27_hazard_bot_solve`, `m26_hazard_bot_integration`, `m29_hazard_bot_runtime_smoke` pass.

## Tests (run on the final code/catalog state)

| Suite | Result |
|---|---|
| `tests/m52_owner_supply_plans.gd` | exit 0 — 255 ok, 0 FAIL, 0 SCRIPT ERROR |
| `tests/m40_v04_bootstrap.gd` | exit 0 — 58 ok, 0 FAIL |
| `tests/m42_home.gd` | exit 0 — 224 ok, 0 FAIL |
| `tests/m42_navigation.gd` | exit 0 — 82 ok, 0 FAIL |
| `palette_v3_leveldata_contract`, `m21_real_art_smoke`, `m23_v01_batch_supply_evidence`, `m23_v02_hardening_evidence`, `m23_v03_transaction_identity_evidence`, `m24_supply_handoff_evidence`, `m25_claim_model_evidence`, `m26_hazard_bot_integration`, `m27_generation_retry`, `m27_hazard_bot_solve`, `m29_hazard_bot_runtime_smoke`, `m30_completion_authority`, `m30_transaction_safe_retry`, `m35_level_catalog`, `m35_v02_hardening`, `m36_difficulty_v1`, `m36_v02_migration`, `m37_level_progression`, `m37_v02_strict`, `m37_v03_forward_only`, `m39_v04_integration`, `m40_v03_canonical` | each exit 0, 0 SCRIPT ERROR, 0 FAIL (`m30_transaction_safe_retry` prints `ok: FAIL-CLOSED[...]` assertion names — all `ok`) |
| root `tests/run_tests.gd` (full regression) | exit 0 — **5322 checks, RESULT: ALL PASS**, 0 SCRIPT ERROR |
| `git diff --cached --check` | clean |

Engine `ERROR:` lines in the root suite: 9, sorted-content hash `34c0bb32` — identical to the pre-M52 baseline run (same count/hash), e.g. "18 resources still in use at exit".

Commands: `godot --headless --path . -s res://tests/<suite>.gd`; verifier `godot --headless --path . -s res://tools/verify_m52_supply_candidate.gd -- <level_id> <evidence_out.json>`.

## Difficulty metadata

Owner-locked classes preserved (EASY, EASY, MEDIUM, EASY, HARD, EASY, EASY, MEDIUM, EASY, VERY_HARD). No Challenge/SessionLoad/Frustration values produced or invented — no canonical real-level analyzer exists (M53 gate).

## Git status

After pushing: `main` == `origin/main`. Remaining `git status` entries are only pre-existing untracked owner/editor files (`*.import`, `*.uid`, `_owner_inbox`, UI candidates, audio, root-level duplicate level PNGs) that were present before this work and are intentionally not committed. Pre-existing owner stash `stash@{0}` untouched.

`AWAITING_CHATGPT_AUDIT / M52-C001 FIRST 10 LEVEL PACK — owner batch integration`
