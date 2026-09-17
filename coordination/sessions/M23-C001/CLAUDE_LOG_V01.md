# M23-C001 V01 — Batch Supply Engine — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Owner decision: `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
Handoff state: `AWAITING_AUDIT`

## 1. Commit identities

- **Synchronized starting `origin/main` SHA:** `2cbae3b1f7bc671478becc3b684b3660f1eee3dd`.
- **Implementation SHA (pushed first):** `a19e2de18cc0e4ec0a4bfe2c83fd367aea26bf4d`
  (`feat(M23-C001 V01): deterministic batch supply engine`).
- **This log** is a separate evidence commit pushed after the implementation SHA.

Safe sync: fast-forward `1df8b23..2cbae3b`; owner-local `project.godot` +
untracked `.import`/`.uid` sidecars preserved (left unstaged); no
`reset --hard` / `clean -fd` / destructive restore / force push.

## 2. Changed files (implementation commit a19e2de)

New gameplay-domain package `scripts/gameplay/supply/`:
- `color_batch.gd`
- `batch_selection_transaction.gd`
- `batch_supply_engine.gd`
- `batch_supply_generator.gd`

Tests:
- `tests/run_tests.gd` — added `_run_m23_batch_supply_tests` (+ helpers
  `_m23_level` / `_m23_generated_totals`), registered in `_initialize`.
- `tests/m23_v01_batch_supply_evidence.gd` — real Hazard Bot evidence smoke.

No production routing/target/reservation/dispatcher/agent/clearing/SlotSystem
file changed. Owner-local `project.godot` NOT staged. Root `TASKS.md` absent.

## 3. Architecture / public API

Pure `RefCounted` gameplay-domain; no `Control`/scene/BoardRenderer dependency; no
target/reservation/routing/dispatch/spawn/clear. Preload convention used.

`ColorBatch` (`color_batch.gd`)
- `static make(batch_id:String, color_id:int, robot_count:int, palette_size:int=-1) -> ColorBatch|null` (fail-closed)
- `get_batch_id()/get_color_id()/get_robot_count()`, `duplicate_batch()`, `to_dict()`

`BatchSelectionTransaction` (`batch_selection_transaction.gd`)
- immutable token: `get_token_id()/get_column()/get_front_batch_id()/get_front_batch()`

`BatchSupplyEngine` (`batch_supply_engine.gd`)
- `static create(column_count, preview_depth) -> engine|null` (3..5 cols, 3..4 depth)
- `load_columns(cols) -> bool` (fail-closed, no partial mutation)
- `get_front(col)`, `get_preview(col)`, `get_remaining(col)`, `is_column_exhausted(col)`, `is_exhausted()`
- `player_snapshot()` (front + preview≤depth + remaining count; no hidden contents)
- `debug_snapshot()` (full detached; non-player-facing)
- `begin_front_selection(col) -> token|null`, `commit(tx) -> bool`, `cancel(tx) -> bool`, `has_open_transaction(tx)`
- `reset()`, `get_seed()/set_seed()`, `get_column_count()/get_preview_depth()`, `set_palette_size()`

`BatchSupplyGenerator` (`batch_supply_generator.gd`)
- `static color_totals(level) -> Dictionary` (per-color cell totals; {} if malformed)
- `static generate(level, column_count, preview_depth, seed:int) -> engine|null`

## 4. Transaction semantics (two-phase; fail-closed)

`begin_front_selection(col)` registers a private monotonic token id → `{column,
front_batch_id}` and returns a token carrying a detached front copy; **it does not
pop**. `commit(tx)` succeeds only if the token is a real `BatchSelectionTransaction`,
its id is still open, and the column's current front id still equals the recorded
front id — then it removes exactly that front and consumes the token (advancing only
that column). Any mismatch consumes the token and changes nothing. `cancel(tx)`
consumes a valid token and changes nothing. Proven fail-closed: double commit,
cancel-then-commit, stale-front-after-another-commit, cross-column (token binds its
own column), forged Dictionary/null token, and any token created before `reset()`
(reset clears all open tokens).

## 5. Generator / partition (deterministic)

Per-color totals derived from `LevelData.cells` using existing integer palette IDs.
Each positive total T is split into `k` positive parts (`k = 1 + rng.randi()%min(T,8)`,
`_partition` = base + remainder-front, every part ≥ 1, sum = T → exact conservation).
Batches get deterministic unique ids `B%05d` in generation order and are
round-robin distributed across the configured columns. RNG is a private
`RandomNumberGenerator` seeded explicitly (no wall clock, no global RNG). Bounded
(≤ 8 batches/color). Candidates only — no solvability/difficulty logic (M27 scope).

## 6. Same-seed determinism evidence

`BatchSupplyGenerator.generate(lvl, 3, 3, 99)` twice → identical `debug_snapshot()`
(root-suite assertion). Real Hazard Bot `generate(..., seed=20260917)` twice →
identical layout (evidence smoke). Different seed (100) still conserves every color.

## 7. Hazard Bot evidence (`tests/m23_v01_batch_supply_evidence.gd`, PASS exit 0)

```text
M23_LEVEL id=m21_level_001_hazard_bot dims=20x20 palette_size=5 cell_count=400
M23_SOURCE_TOTALS { 2:298, 4:56, 0:30, 1:5, 3:11 } (sum=400)
M23_CONFIG seed=20260917 columns=3 preview_depth=3
M23_COLUMN 0 depth=7 [B00000(c0:5) B00003(c0:4) B00006(c0:4) B00009(c1:1) B00012(c2:298) B00015(c3:3) B00018(c4:14)]
M23_COLUMN 1 depth=7 [B00001(c0:5) B00004(c0:4) B00007(c1:1) B00010(c1:1) B00013(c3:3) B00016(c3:2) B00019(c4:14)]
M23_COLUMN 2 depth=7 [B00002(c0:4) B00005(c0:4) B00008(c1:1) B00011(c1:1) B00014(c3:3) B00017(c4:14) B00020(c4:14)]
M23_GENERATED_TOTALS { 0:30, 1:5, 2:298, 3:11, 4:56 } (sum=400)
```

- Exact per-color conservation source == generated (tested per color, not only grand total).
- Total generated quota == `LevelData.get_cell_count()` = 400 (opaque artwork; no
  background pixel reinterpreted as empty).
- Every column depth 7 > preview depth 3; player-facing preview returns exactly 3
  rows and the deep batch id at index 3 is proven absent from the player preview
  (hidden not leaked); `remaining` exposes only a count.

## 8. Rectangular / 59×59 evidence

- Rectangular `30×12` (=360, colors 0/1 = 180/180), 4 columns, seed 5 → exact
  per-color conservation.
- `59×59` (=3,481, colors 0/1/2), 5 columns, seed 11 → total quota 3,481; same seed
  reproduces identical layout. Performance sanity: two 59×59 generations = **4 ms**
  (`M23_PERF 59x59 x2 generate = 4 ms`). No square-board or 400-cell assumption.

## 9. Validation commands / results / exits

Run from `C:\Users\sekip\Desktop\ScrubBots`.

| # | Literal command | Result | Exit |
|---|-----------------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4885, Failures: 0, ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m23_v01_batch_supply_evidence.gd` | `M23 V01 batch supply evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd` | PASS | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | PASS | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | PASS | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | PASS | 0 |
| 8 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | PASS (full 400-cell clear) | 0 |
| 9 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | PASS | 0 |
| 10 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | PASS | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | PASS | 0 |
| 12 | `git diff --check` | clean | 0 |

Adversarial coverage in item 2 includes: 2/6-column rejection, invalid preview
depth, duplicate/malformed/non-ColorBatch queue entry, invalid color id, zero/
negative/float/bool/String/null quota, empty-column begin, front-only selection,
double commit, cancel-then-commit, stale token, cross-column, forged token,
post-reset token, snapshot-mutation immutability, exhaustion, same-seed
determinism, multi-color conservation, reset restoration.

## 10. Statements

- `root TASKS.md modified = NO` (absent from the implementation diff).
- `M24–M27 implementation = NO` (no five-slot batch engine, target claim, auto
  dispatch, or solvability/deadlock logic).
- `image-generation credits spent = 0`.
- No protected system (TargetSelector / ReservationState / Railroad V1 routing /
  Dispatcher / ScrubbotAgent / CompleteClearingLoop / SlotSystem) modified; fresh
  Hazard Bot C08 routing and all M22/M21/M20 regressions remain green.
- Warnings/limitations: generated layouts are **candidates only** — solvability is
  not asserted (M27). A color's total may generate as a single large batch when the
  seeded partition picks k=1 (e.g. Hazard Bot color 2 = one 298 batch); this is a
  legal M23 candidate that M27 may later reject.
- No audit verdict authored. `AWAITING_AUDIT`.
