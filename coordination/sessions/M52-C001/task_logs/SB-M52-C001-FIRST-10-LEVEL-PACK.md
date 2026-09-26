# SB-M52-C001 — FIRST 10 LEVEL PACK — CLAUDE TASK LOG

Status: **BLOCKED — catalog NOT published** (authoritative solver rejects Levels 5, 7, 8, 10 under current canonical supply/slot rules)
Implementer: Claude (Opus 5.5)
Date: 2026-09-26
Prompt: `coordination/sessions/M52-C001/task_prompts/SB-M52-C001-FIRST-10-LEVEL-PACK.md` (incl. owner hidden-FIFO clarification `07289ab`/`d91edd6`/`f861d27`)

Per prompt §D: *"If any Level 2-10 cannot be proven solved under the current canonical rules, stop before publishing the final 1..10 catalog and report that exact level/blocker."* This log is that report. `data/levels/catalog/production_catalog_v1.json` is **unchanged** (still exactly Level 1 Hazard Bot). No gameplay, solver, supply-generator, slot or routing semantics were changed. No source PNG was modified.

## 1. Baseline / sync

- Repository `Sekiph82/Scrubbots`, branch `main`.
- Session start local HEAD `701823f` (behind origin by 14) → fast-forward only to `8b67167`, then to `f861d27` after the owner hidden-FIFO clarification. **Baseline SHA: `f861d277cd254a98a8a615b6a33e50507fe76137`.**
- Pre-existing untracked owner files (`*.import`, `*.uid`, `_owner_inbox`, duplicate root-level `assets/art/levels/source/level_0NN_*.png` copies, UI candidates, audio) were left untouched and are not part of this commit. The root-level PNG copies are byte-identical (`cmp`) to the committed owner sources under `easy/ medium/ hard/ very_hard/`.
- `TASKS.md`, owner decision files, ChatGPT prompt/criteria/audit files: not edited.

## 2. Source integrity (all nine PASS)

All: PNG, RGBA, every pixel alpha 255, every RGB an exact canonical V3 C-ID, 3..12 colors, dimensions 20..59. Bytes untouched.

| L | Source | Git blob | SHA-256 | Size | Used C-IDs (cells) |
|---:|---|---|---|---|---|
| 2 | `easy/level_002_apple_32x32.png` | `f696d8b1…` | `b1dd3b414738cf0557cf9baabb5d3a12208df3c3a57d3ab3184e990df1dcf580` | 32×32 | C01 296, C04 23, C08 639, C11 56, C12 10 (5) |
| 3 | `medium/level_003_palm_tree_38x38.png` | `096a2fef…` | `84960199759b1c3a1e130a24149c14fff9a5ee6ffb53db4ec6f138e34c6116cc` | 38×38 | C02 28, C04 452, C05 88, C08 601, C11 72, C16 203 (6) |
| 4 | `easy/level_004_orange_cat_32x32.png` | `47ab59b3…` | `0b8cbc068d1d070cc5c68ee439ccb908a09cc99180f6a068ba4475339f41c926` | 32×32 | C02 167, C04 2, C08 639, C11 13, C12 68, C13 5, C16 130 (7) |
| 5 | `hard/level_005_party_toucan_33x33.png` | `db6654dd…` | `c95c0fd4021bb90eacd78dbc2279809f26fe0ed435cca260881ee6961eb9874f` | 33×33 | C01 7, C02 26, C03 106, C06 9, C07 8, C08 611, C10 15, C11 52, C14 78, C16 177 (10) |
| 6 | `easy/level_006_chicken_32x32.png` | `ed403914…` | `9e15e570a7b8d5a31f4cd0eb37e4f6e48e18e71f66b7c56e08510738412ff790` | 32×32 | C01 12, C02 5, C03 41, C08 702, C11 58, C12 133, C14 71, C16 2 (8) |
| 7 | `easy/level_007_pigeon_32x32.png` | `434a9214…` | `ca6004936d2ab9f4a8faef3215f9887157a407a7b63743ec07cc0a922530158a` | 32×32 | C01 9, C08 666, C10 2, C11 9, C13 43, C14 126, C15 58, C16 111 (8) |
| 8 | `medium/level_008_butterfly_32x32.png` | `af1a431f…` | `9a623fece67690862ba73b737e5e52d9acfbe1e46b160c411eee5714ea01b2fc` | 32×32 | C01 55, C02 150, C03 47, C08 482, C11 7, C14 15, C15 28, C16 240 (8) |
| 9 | `easy/level_009_frog_32x32.png` | `14cc86e7…` | `b0bd1638961cd69e64f2bd174df117d3c75520be0804a114362efc96663d036f` | 32×32 | C06 15, C07 318, C08 497, C12 40, C13 12, C15 2, C16 140 (7) |
| 10 | `very_hard/level_010_ice_cube_32x32.png` | `229319f4…` | `a39b54c0adc05ca4778536cd9f0b5bccaa7cfde786fb8c72efa4be91029d3d61` | 32×32 | C02 6, C03 14, C05 93, C06 16, C07 2, C08 259, C13 270, C14 78, C15 70, C16 216 (10) |

Level 1 source/LevelData/metadata/preview: unchanged (no Level 1 file in the diff).

## 3. Production build (all nine PASS)

Tool: `tools/build_m52_first_10_pack.gd` (new) → canonical `ProductionArtLevelBuilder.build` (M09 exact-pixel importer → ascending-C-ID normalization → preview reconstructed from final LevelData → metadata/provenance). LevelData V1, owner difficulty, exact source reconstruction. Rebuild with unchanged sources reports `UNCHANGED` (L3 was built by the first run and reported UNCHANGED on the second).

**Legacy-band blocker found and fixed (in scope):** the canonical build path called the M09 `LevelImporter`, which still enforced the retired class=dimension band (`"Source dimensions 32x32 outside EASY band (20..29)"` for Apple). CLAUDE.md §6 / owner decision 2026-09-12 forbid that rule; `ProductionLevelValidator` was already migrated in M36 V02. `scripts/tools/level_importer.gd` now gates production imports by the 20..59 per-dimension envelope (`DifficultyRules.is_within_production_envelope`), same as `ProductionLevelValidator`. The adversarial `3x2 with EASY rejected` check in `tests/run_tests.gd` still holds (outside envelope). `auto_difficulty` (legacy helper) untouched.

Outputs (sha256, first 16 hex; JSON as written, LF):

| Level | LevelData | Metadata | Preview |
|---|---|---|---|
| `level_002_apple` | `f0cf2a0089858297` | `6b2d50a156b41a9a` | `e9f35fb75dd2cad1` |
| `level_003_palm_tree` | `0aceddb060f9770f` | `ea365d29620dd207` | `612a727c21264cd5` |
| `level_004_orange_cat` | `070ec1f61ebf8c2b` | `ff98079a65de13a7` | `e2ffdec4a0e2f2fe` |
| `level_005_party_toucan` | `b2c61546e75c4a20` | `f0b2d53417251bcf` | `1a1b0d3d342167e3` |
| `level_006_chicken` | `22aa7df9e837e140` | `0b6a054cc28d4b4b` | `02bb365afffcd73f` |
| `level_007_pigeon` | `7b2884005a7685e3` | `a516386a65758985` | `b38ee2742f622b23` |
| `level_008_butterfly` | `672053fc43ec1d5f` | `32f37deb47dd97a2` | `1a597c963b32a8e8` |
| `level_009_frog` | `b5989964a4dd1e90` | `3fdfca3524c98d9c` | `dc9dcd2d7f2f1172` |
| `level_010_ice_cube` | `ab7a93178852441d` | `ee565e8e675f33f0` | `ced7920c12c35d2d` |

These files are committed as build-gate evidence only. **None is referenced by the production catalog**; `LevelCatalog` reads only the manifest (no directory scan), so they are unreachable at runtime.

Challenge/SessionLoad/Frustration: no canonical real-level analyzer exists → `NOT_AVAILABLE_M52` (nothing fabricated). M53 gate.

## 4. Authoritative solvability — BLOCKER

Configuration (runtime authority `ProductionGameplayHost`): 3 FIFO columns, `preview_depth=3` = **visible rows only**, 5 slots, `GenerationGate.generate_accepted(level, 3, 3, base_seed=1, …)`, `SolvabilitySolver` default bounds (`max_visited=200000`, `max_depth=400`, unchanged). The solver's `ProofState.from_level_and_supply()` holds the **complete hidden FIFO queue** (evidence: `proofStateQueueLengths == queueLengths`, and `decisions == totalBatches` for every SOLVED level). Attempt bound: 1 for the first pass, raised to 16 then 64 **attempts** (not solver bounds) for L5/L10 to rule out an unlucky seed. Runtime plays only `gen_seed=1`, so a level is admissible only if seed 1 (attempt 0) is SOLVED.

| L | Level | Result | Seed/attempt | Visited | Decisions = batches | Full queue lengths | Trace hash | Replay |
|---:|---|---|---|---:|---:|---|---:|---|
| 1 | Hazard Bot (reference) | **SOLVED** | 1 / 0 | 20 | 19 = 19 | [7, 6, 6] | 1618197986 | exact completion |
| 2 | Apple | **SOLVED** | 1 / 0 | 17 | 16 = 16 | [6, 5, 5] | 2919019324 | exact completion |
| 3 | Palm Tree | **SOLVED** | 1 / 0 | 191 | 18 = 18 | [6, 6, 6] | 1380253315 | exact completion |
| 4 | Orange Cat | **UNRESOLVED** — search still running at report time (>70 min, no verdict) | — | — | — | — | — | — |
| 5 | Party Toucan | **DEADLOCK ×64** (attempts 0..63, every one exhaustive DEADLOCK, never UNKNOWN_BOUND) | — | 82..354 | — | — | — | — |
| 6 | Chicken | **SOLVED** | 1 / 0 | 30 | 29 = 29 | [10, 10, 9] | 84831996 | exact completion |
| 7 | Pigeon | **DEADLOCK** at seed 1 (exhaustive; ~28 min per attempt) | 1 / 0 | 342 | — | — | — | — |
| 8 | Butterfly | **DEADLOCK** at seed 1 (exhaustive; ~28 min per attempt) | 1 / 0 | 429 | — | — | — | — |
| 9 | Frog | **UNRESOLVED** — search still running at report time (>70 min, no verdict) | — | — | — | — | — | — |
| 10 | Ice Cube | **DEADLOCK ×64** (attempts 0..63, every one exhaustive DEADLOCK) | — | 92..440 | — | — | — | — |

Full per-level records (attempt lists, accepted seed, full hidden batch layout per column, ProofState queue lengths, trace summary/hash, replay): `coordination/sessions/M52-C001/evidence/solve_*.json`. Raw tool output lines: `coordination/sessions/M52-C001/evidence/m52_solver_run_lines.txt`.

DEADLOCK is never treated as pass; no UNKNOWN_BOUND occurred; no solver bound raised; no source mutated.

### Root cause (diagnosis, not a fix)

`BatchSupplyGenerator.generate` builds the flat batch list in **ascending local palette index** (= ascending global C-ID after production normalization) and deals it round-robin into the 3 columns. The seed only changes *how many* batches each color is split into (1..min(total,8)); it **never changes color order**. Consequences for these artworks:

- C16 (black outline, highest C-ID) is always queued **last in every column**; the C08 background is mid-queue.
- The first fronts are low-C-ID interior colors fully enclosed by the outline → they occupy slots as WAITING; five of them fill all 5 slots before any reachable batch surfaces.
- Diagnostic greedy probe, Toucan seed 1: after 5 placements all 5 slots hold WAITING C01/C03 batches, `active = 1089 / 1089` (zero cells cleared), no legal placement remains. The exhaustive solver confirms no placement order escapes.

Levels 1/2/3/6 pass because their low-C-ID colors are exposed early enough. Every remedy (generator ordering/partitioning change, slot/supply rule change, per-level seed plumbing for a non-1 seed, or art/palette changes) is an **owner-gated gameplay/content decision** outside this prompt, so none was made.

## 5. Catalog / frontier

Not changed. Catalog still has only order 1; frontier 2 remains `CONTENT_MISSING` / "Level 2 is coming soon." (correct fail-closed behavior until the pack can be admitted as a whole).

Prepared-but-not-committed (would be applied only after all nine pass): catalog-10 test expectation updates for `m40_v04_bootstrap`, `m42_home`, `m42_navigation`, the focused suite `tests/m52_first_10_level_pack.gd`, and optional catalog `gen_seed` plumbing. Kept out of the repo because they assert a 10-entry catalog that cannot honestly exist yet.

## 6. Changed files (this commit)

- `scripts/tools/level_importer.gd` — retired class=dimension band → production envelope gate.
- `tools/build_m52_first_10_pack.gd` — new deterministic build + GenerationGate/Solver + evidence tool (`--only=<id>`, per-level solve cache keyed by LevelData hash + solver config; writes `first_10_pack_evidence_v1.json` only when every level passes — not written).
- `data/levels/level_0{02..10}_*.json`, `data/levels/metadata/level_0{02..10}_*.metadata.json`, `assets/art/levels/previews/level_0{02..10}_*.png` — build outputs (not cataloged).
- `coordination/sessions/M52-C001/evidence/*` — solver evidence.
- this log.

## 7. Tests (final code state)

| Suite | Exit | SCRIPT ERROR | FAIL |
|---|---|---|---|
| `tests/palette_v3_leveldata_contract.gd` | 0 | 0 | 0 |
| `tests/m21_real_art_smoke.gd` | 0 | 0 | 0 |
| `tests/m27_generation_retry.gd` | 0 | 0 | 0 |
| `tests/m35_level_catalog.gd` | 0 | 0 | 0 |
| `tests/m35_v02_hardening.gd` | 0 | 0 | 0 |
| `tests/m36_difficulty_v1.gd` | 0 | 0 | 0 |
| `tests/m36_v02_migration.gd` | 0 | 0 | 0 |
| `tests/m37_level_progression.gd` | 0 | 0 | 0 |
| `tests/m37_v02_strict.gd` | 0 | 0 | 0 |
| `tests/m37_v03_forward_only.gd` | 0 | 0 | 0 |
| `tests/m40_v04_bootstrap.gd` | 0 | 0 | 0 |
| `tests/m42_home.gd` | 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 0 | 0 | 0 |
| root `tests/run_tests.gd` | 0 | 0 | 0 (5322 checks, RESULT: ALL PASS) |
| `tests/m52_first_10_level_pack.gd` | not committed (asserts a 10-entry catalog; see §5) |
| `git diff --check` | clean |

Pre-existing engine `ERROR:` lines in the root suite (9, e.g. "resources still in use at exit") are **baseline-identical**: the same suite run with `level_importer.gd` stashed back to baseline produced the same 9 lines (sorted-content hash `34c0bb32` both runs), exit 0, 5322 ALL PASS.

## 8. Owner decision needed

To admit Levels 5/7/8/10 (and possibly 4/9) one of these is required — all are gameplay/content decisions, not implementation:

1. change the M23 supply generator's batch ordering (e.g. seeded color interleaving) — alters canonical supply semantics and every existing proof;
2. allow per-level accepted supply seeds in the catalog **and** a generator that can produce a solvable order (seed alone cannot reorder colors today);
3. revise the Level 5/7/8/10 artworks/outline structure;
4. accept a smaller first pack (e.g. only proven levels) — conflicts with the owner-locked 1..10 mapping/cadence.

`BLOCKED / M52-C001 FIRST 10 LEVEL PACK — Levels 5, 7, 8, 10 DEADLOCK under canonical rules; 4, 9 unresolved; catalog unchanged`
