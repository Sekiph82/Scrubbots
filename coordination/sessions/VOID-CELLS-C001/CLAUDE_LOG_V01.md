# VOID-CELLS-C001 — CLAUDE_LOG_V01

Status: **AWAITING_AUDIT** (implementer log; no audit verdict is claimed here)

- Task: VOID cells — transparent artwork pixels as a first-class LevelData cell type
- Owner request: 2026-10-08 (in-chat task, Claude Code desktop session)
- Repository / branch: `Sekiph82/Scrubbots` / `main`
- Baseline: `19a39876` (local `main` == `origin/main`, 0 ahead / 0 behind at sync)
- Godot: 4.7.2.stable.official.ed1daf0bf
- ADR: ADR-030 in `docs/05_TECH_DECISIONS.md`

## 1. Sync and owner-work preservation

`git fetch` confirmed that local `main` matched `origin/main`. The pre-existing local owner work was
left untouched and is not part of this change: the `project.godot` / `scenes/app/main.tscn` /
owner-review `.tscn` edits, `addons/`, `.mcp.json`, the untracked art and level-source PNGs, and
the `.uid` / `.import` files. Only the files listed in section 4 are committed.

## 2. Owner decisions applied (answered in chat, 2026-10-08)

| Gate | Owner answer |
|---|---|
| D1 VOID presentation | **Identical to CLEARED**: BG01 `#202533` shows through, with no grid or border |
| D2 minimum artwork | **>= 200 non-VOID cells AND >= 25% of W*H**; the 20..59 envelope is unchanged |
| TASKS.md | **Owner override:** Claude adds the `SB-VOID-C001` entry to root `TASKS.md` (normally ChatGPT-write-owned) |
| Git | Commit and push directly to `main` |

## 3. Design (summary — full text in ADR-030)

- `-1` = VOID. It is legal only in `"version": 2` files. A version-2 file needs at least one VOID cell and at least one artwork cell. Version 1 is unchanged.
- VOID is not a third cell state. `BoardState` makes VOID cells CLEARED at construction; they can never become ACTIVE, and Retry keeps them CLEARED. Every existing access/claim/route/completion law then treats VOID as open space automatically.
- Supply, the solver, the analyzer and WIN all count artwork cells only. VOID provenance is emitted only for VOID levels, so all version-1 evidence stays byte-identical.
- The production art builder maps alpha 0 to VOID and still rejects alpha 1..254. Scrubpack accepts version-2 levels.

## 4. Changed files

Code:
- `scripts/data/level_data.gd`: adds `FORMAT_VERSION_VOID = 2`, `VOID_CELL = -1`, `is_void()`, `get_void_cell_count()` and `get_artwork_cell_count()`.
- `scripts/data/level_validator.gd`: accepts versions 1 and 2. VOID is allowed only in version 2. Version 2 must contain VOID, and an all-VOID level is rejected. Cell values that are not integers (fractions, strings) fail closed.
- `scripts/data/production_level_validator.gd`: adds the D2 minimum-artwork gate.
- `scripts/gameplay/board/board_state.gd`: VOID starts CLEARED and can never become ACTIVE. Adds `restore_all_active` VOID preservation, `is_void()` and `get_artwork_cell_count()`.
- `scripts/gameplay/targeting/color_candidate_index.gd`: `sync_cell` on a VOID cell is a healthy no-op.
- `scripts/gameplay/supply/batch_supply_generator.gd`: `color_totals` skips VOID, for version 2 only.
- `scripts/gameplay/supply/supply_plan_loader.gd`: the grand total is checked against the artwork cell count.
- `scripts/gameplay/solver/proof_state.gd`: the initial proof state has VOID = `CLEARED_BYTE`.
- `scripts/difficulty/level_difficulty_analyzer_v1.gd`: VOID-aware `color_stats`, `peel_waves`, `color_layer_depth` and progress, plus VOID provenance.
- `scripts/gameplay/runtime/production_gameplay_host.gd`: the Daily Orders `cells` count uses artwork cells.
- `scripts/tools/production_art_level_builder.gd`: alpha 0 maps to VOID and the output is version 2. Builder metadata gains `artworkCellCount` and `voidCellCount` (VOID levels only).
- `scripts/tools/level_importer.gd`: `reconstruct_image` renders VOID as a transparent pixel.
- `scripts/content_runtime/scrubpack_v1.gd`: accepts version-2 levels. The optional metadata counts must match the validated level exactly.

Tests:
- `tests/void_cells_c001.gd` (new, 186 assertions).
- `tests/palette_v3_leveldata_contract.gd`: the "fake V2 rejected" guard now asserts the ADR-030 reason. A void-free version-2 level is still rejected, with "requires at least one VOID cell" in place of "unsupported version". This is the only change to an existing assertion, and the owner decision requires it.

Docs/governance:
- `docs/05_TECH_DECISIONS.md` (ADR-030)
- `docs/03_LEVEL_DATA_SPEC.md` (§2.1 Version 2 / VOID, plus §3, §4.1, §4.2, §7 and §15)
- `docs/08_PIXEL_ART_PALETTE_RULES.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `CLAUDE.md` §7: fixes the documentation drift from "no Level Data V2 exists".
- `TASKS.md`: the owner-authorized `SB-VOID-C001` entry, plus the matching §8.7A sentence.
- This log.

No renderer code changed. `BoardRenderer` already draws CLEARED as alpha 0, and
`board_pixel_grid.gdshader` emits nothing for alpha < 0.5, so D1 holds as-is. The test asserts this.

## 5. Test results (all on the owner-local checkout, headless Godot 4.7.2)

| Suite | Result |
|---|---|
| `tests/run_tests.gd` baseline (before changes) | 5329 / 5329 ALL PASS |
| `tests/run_tests.gd` after changes | **5329 / 5329 ALL PASS** |
| `tests/void_cells_c001.gd` (new) | **PASS (186 ok, 0 fail)** |
| palette_v3_leveldata_contract | PASS (6/6) |
| m52_owner_supply_plans, m52_r01_parallel_runtime, m52_r02_early_slot_release | PASS |
| maint_supply_columns_c001 | PASS (10/10) |
| m26_hazard_bot_integration, m26_scale_59_sanity | PASS |
| m27_generation_retry, m27_hazard_bot_solve, m27_scale_59 | PASS |
| m30_completion_authority, m30_transaction_safe_retry | PASS |
| m35_level_catalog, m35_v02_hardening, m36_difficulty_v1, m36_v02_migration | PASS |
| m21_real_art_smoke | PASS |
| m53_first10_difficulty | PASS |
| **m53_c002_difficulty_calibration** (fresh run == committed corpus raw) | **PASS**: version-1 difficulty evidence is byte-identical |
| m53_c002_canonical_json | PASS (30) |
| cp04_remote_content_runtime / cp05_remote_content_cache / cp05_r01_transaction_cleanup | PASS (28/28, 15/15, 6/6) |
| remote_content_family_fixture | PASS |

`void_cells_c001` coverage:
- Every committed version-1 level loads as version 1 with zero VOID cells. Every cell starts ACTIVE and the supply total equals the cell count. A version-1 `LevelData` containing `-1` is never treated as VOID.
- The loader rejects:
  - `-1` in a version-1 file;
  - a void-free version-2 file;
  - an all-VOID level;
  - the value `-2`;
  - a fractional (semi-transparent) value or a string value;
  - version 3.
- D2 boundaries: on 20x20, 199 is rejected and 200 is accepted. On 40x40, 399 is rejected and 400 (25%) is accepted. The 20..59 envelope is still enforced.
- `BoardState`: VOID starts CLEARED with no colour and can never become ACTIVE, and Retry keeps it CLEARED. `ColorCandidateIndex` never lists VOID, and `sync_cell` on VOID does not neutralize the index.
- D1: the renderer draws VOID identically to CLEARED (`CLEARED_COLOR`).
- Supply: the per-colour and grand totals cover artwork only. A plan that also pays for VOID is rejected, and generated supply equals the artwork count.
- Reachability, measured with the production access path through the analyzer peel, on each fixture:
  - VOID ring: the artwork edge is wave 0.
  - Sealed hole: the cell above the hole peels at geometric depth 7 (no teleport), with 0 geometric mismatches.
  - VOID touching the border: the adjacent artwork column is wave 0.
  - VOID-only rows/columns: the adjacent artwork is wave 0 and the interior is not.
  - Corridor: the block cell is wave 0 through the VOID corridor, and wave 8 when the corridor is filled.
- Corridor-only solvability: with the VOID corridor the level is **SOLVED**. The identical layout with the corridor filled by artwork is **DEADLOCK**.
- All 5 fixtures:
  - the initial proof state counts only artwork as ACTIVE, and the canonical key is stable;
  - each is SOLVED, the trace replays to completion, and a re-solve is deterministic (same trace hash and visited count);
  - each gets a Difficulty V1 score that is finite and within 0..100 (ring 37.60, hole 39.00, border 39.68, rows/cols 38.29, corridor 29.71);
  - W and C are measured over artwork only, VOID provenance is present, and the measurement is deterministic.
- Builder: alpha 0 maps to VOID (version 2, 76 VOID cells, a palette of the 3 used colours, transparent preview). The metadata reports `cellCount 400`, `artworkCellCount 324` and `voidCellCount 76`. Alpha 128 is rejected, opaque art stays version 1, and a D2 violation is rejected.
- Scrubpack: a version-2 VOID remote level with a conserving plan and artwork metadata is accepted. `-1` in a version-1 remote level, a wrong `artworkCellCount`, and a plan that pays for VOID are each rejected.
- Live `ProductionGameplayHost` (corridor + hole fixtures): the solver trace is replayed through real input, ticks and agents, and **WIN latches with VOID present**. Every artwork cell is cleared and VOID stays CLEARED.

`git diff --check`: clean (section 7).

## 6. Sample VOID level JSON (20x20 TEST ring fixture `void_ring` from the test)

```json
{
  "version": 2,
  "id": "void_ring",
  "name": "void_ring",
  "difficulty": "TEST",
  "width": 20,
  "height": 20,
  "palette": ["#FF4500FF", "#FFA800FF"],
  "cells": [
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
  ]
}
```

400 cells: 204 VOID and 196 artwork (98 C01 + 98 C02). This is a TEST fixture. As production content, D2 would reject it (196 < 200 artwork cells).

## 7. Known limits / follow-ups (not done here)

- **Level Factory publisher (separate repository):** it must emit version-2 VOID levels and may add `artworkCellCount` / `voidCellCount`. The game side already accepts both.
- **Difficulty V2 *candidate* analyzer:** `level_difficulty_analyzer_v2_candidate.gd` is not VOID-aware. It is not production authority and was outside the task list.
- **Generic M09 `LevelImporter`:** still records alpha 0 as a raw first-seen palette entry (its audited contract). VOID mapping happens in the production builder.
- **Analyzer anchors:** not recalibrated. No VOID production content exists yet to justify a change.
- **Governance:** the root `TASKS.md` edit by Claude is an explicit owner override for this task only.
