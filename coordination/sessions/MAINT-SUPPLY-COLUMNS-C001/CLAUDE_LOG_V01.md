# MAINT-SUPPLY-COLUMNS-C001 — CLAUDE LOG V01 — 3/4/5 Supply Columns, Preview Depth 3

Date: 2026-10-01
Prompt: `coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/task_prompts/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/MAINT-SUPPLY-COLUMNS-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Owner decision: `coordination/OWNER_SUPPLY_COLUMNS_3_4_5_PREVIEW3_V01.md`
Engine: Godot 4.7.2.stable.official.ed1daf0bf
Status: `AWAITING_CHATGPT_AUDIT`

## Sync preflight

- Canonical checkout `C:\Users\sekip\Desktop\ScrubBots`, remote `origin` = `https://github.com/Sekiph82/Scrubbots.git`, branch `main`.
- `git fetch origin --prune`; local fast-forwarded `2cfe0b1` -> `fd23293` (`git merge --ff-only`, incoming coordination/docs only). HEAD == origin/main == `fd232935b6fbd86a049dd5196a1f53c1cb8fdf29`, ahead/behind 0/0.
- Pre-existing owner/local state preserved untouched: `project.godot` modification, untracked assets / `.import` files, `tests/_m55_diag_tmp.gd`, `stash@{0}` ("pre-batch TASKS whitespace"), Codex worktree `C:/Users/sekip/.codex/worktrees/m42-c003-v02/ScrubBots` (detached, not mine).
- No branch, clone or worktree created. Root `TASKS.md` not edited. Level Factory repo not touched.

## Files changed (implementation commit `51d260b92087d9a1f66362061d4cc1fd37f191ac`)

- `scripts/gameplay/supply/supply_plan_loader.gd`: `COLUMN_COUNT := 3` replaced by `MIN_COLUMNS := 3` / `MAX_COLUMNS := 5`. `columnCount` must be an exact integer in 3..5 (an integral JSON float such as `4.0` is the same integer, as before; `3.5`, `"4"`, `null`, `0` and `-1` are rejected). `visiblePreviewDepth` must be exactly 3 (separate error). `columns` must be an array whose size equals the declared `columnCount`. The engine is created with `BatchSupplyEngine.create(column_count, 3)`. Unchanged: schema/version, levelId, palette Cxx → local mapping, empty/duplicate batchId, positive integer robots within the positive per-plan `maxRobotsPerBatch` bound (no global cap), per-color and grand-total conservation, and engine `load_candidate` validation. Doc comment updated.
- `scripts/gameplay/runtime/production_gameplay_host.gd` `_make_deadlock_supply` (QA/debug-only `qa_supply_drop_last` path): the rebuilt engine now uses the source engine's `get_column_count()` / `get_preview_depth()` instead of the host's generator exports (`column_count = 3`). A 4/5-column plan plus a QA drop previously failed with "qa deadlock supply build failed". Proven by a negative control: reverting this line makes the two focused checks FAIL; restored before commit.
- `tests/maint_supply_columns_c001.gd` (new).

No owner supply plan, level, Level Factory file or root `TASKS.md` changed.

## Fixed-three audit

| Path | Finding | Action |
|---|---|---|
| `SupplyPlanLoader` | `COLUMN_COUNT := 3` admission, array size and engine creation | **changed** |
| `ProductionGameplayHost._make_deadlock_supply` | engine re-created with host export `column_count` (3) | **changed** |
| `ProductionGameplayHost` generator path (`column_count`/`preview_depth` exports → `BatchSupplyGenerator.generate`) | M23 generator candidate only; plan path never uses them | already correct, unchanged |
| `BatchSupplyEngine` | `MIN_COLUMNS 3` / `MAX_COLUMNS 5`, loops on `_column_count` | already dynamic |
| `BatchSupplyPanel` | clamps 3..5, rebuilds per count, `VISIBLE_ROWS` = 3 | already dynamic |
| `GameplayShellGeometry` / `gameplay_screen.gd` | shells `5slot_{3,4,5}col`, `6slot_{3,4,5}col`; selected from the live snapshot size | already dynamic |
| `ProductionInputController` | binds only when the authoritative M23 count is 3..5; column index passed through | already dynamic |
| `ProofState` / `ProofKernel` / `SolvabilitySolver` | `column_count` taken from the engine debug snapshot; actions by column index | already dynamic |
| `ProductionBoosterAdapter` | scratch engines use `_supply.get_column_count()` / `get_preview_depth()` | already dynamic |
| `LevelCatalog` | delegates plan validation to `SupplyPlanLoader` | covered by the loader change |
| Offline tools (`tools/calibrate_difficulty_v2.gd`, `tools/build_m52_first_10_pack.gd`, probes) and existing test fixtures | author 3-column plans by their own configuration | not shipping paths; left unchanged |

## Focused tests: `tests/maint_supply_columns_c001.gd`

10/10 cases, 77 checks, 0 failures (`evidence/maint_supply_columns_c001_output.txt`). Fixtures are small deterministic `user://` TEST levels (10x4 stripes C01..C05; 8x6 two-color for the big batch).

1. Owner plans for Levels 2–10 load unchanged (3 columns, depth 3).
2–3. 3-, 4- and 5-column plans are accepted. The engine has the declared column count and depth 3. FIFO order, batch ids and Cxx mapping are exact.
4–5. 2 and 6 columns are rejected. Non-integer, string, null, 0 and -1 are rejected; integral `4.0` is accepted.
6–8. Preview depth 2 and 4 are rejected for 3, 4 and 5 columns; depth 3 is accepted.
9. Declared/array mismatches are rejected: 4/3, 4/5, 5/4, 3/4, 5/3.
10. A 31-robot batch is accepted in both a 4- and a 5-column plan. A per-plan `maxRobotsPerBatch` below it is still rejected.
11–12. For 4 and 5 columns, each of these is rejected: per-color mismatch, per-color mismatch with equal grand total, grand-total surplus, duplicate batchId, and a Cxx missing from the palette.
13–15. Real `SolvabilitySolver.solve` returns SOLVED for 3, 4 and 5 columns. The solver state reports the actual column count; the trace uses the last column index. `replay` on a fresh plan-loaded state reaches solved.
16. `BatchSupplyPanel` renders 3, 4, 5 and back to 3 columns, always with exactly 3 visible row panels per column.
17. Real `ProductionGameplayHost` builds 4- and 5-column plans (supply has n columns, depth 3) with baseline `get_slot_count() == 5` and capacity 5 in the proof state; +1 Slot is never used. The QA drop-last rebuild keeps n columns.

## Regression

37/37 suites exit 0 on the implementation tree (`evidence/regression_summary.txt`):

- the new suite;
- M23 ×3, M24 ×5, M25-C003/C004 host truth, M27 ×3, M28 ×7, M29 ×8;
- M52 owner plans / R01 / R02, M53 ×2, M55 core chaos, M39 V04 integration;
- root `tests/run_tests.gd`: 5323 checks, 0 failures, ALL PASS.

Godot headless gates:

- `--check-only` on the 3 changed/new scripts: 0 errors;
- `--headless --quit` boot: 0 errors;
- `project.godot` hash identical before and after.

`git diff --check` clean.

## Publication

- The implementation push was first rejected: origin had advanced with Codex M42-C003 V02 commits (`ac9a03c`, `caf1a7a`, `07bdf97`: assets, coordination and `tools/home_scrubby_prepare_assets.py`, no game-script overlap).
- I integrated them non-destructively with `git merge --no-edit origin/main` (no rebase, reset or force) into merge commit `aaf111a216762498fe8bc36b33acf6ade470d494` and pushed.
- After the merge, re-run on `aaf111a`: `maint_supply_columns_c001` 10/10 cases, 0 failures; `m52_owner_supply_plans` PASS.
- Before the log commit: HEAD == origin/main == `aaf111a216762498fe8bc36b33acf6ade470d494`, `git rev-list --left-right --count HEAD...origin/main` = `0 0`.
- Final log commit: the commit that adds this section (child of `aaf111a`). It is pushed to `main` and then verified at 0/0 against origin/main.

## Handoff

`AWAITING_CHATGPT_AUDIT / MAINT-SUPPLY-COLUMNS-C001`
