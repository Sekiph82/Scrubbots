# M55-C002 — CLAUDE LOG V01 — Timed 2x anti-rollback

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict is claimed.
Prompt: `coordination/sessions/M55-C002/task_prompts/SB-M55-C002_TIMED_2X_ANTI_ROLLBACK.md`
Owner ruling: `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
Base: fast-forwarded to `origin/main` `ec9d597`.
Root `TASKS.md` was read only and not edited.
Matrix: `coordination/sessions/M55-C002/TIMED_2X_ANTI_ROLLBACK_MATRIX_V01.md`

## Result

Timed 2x now fails closed on backward device-clock movement. Without a new purchase:
- remaining time never increases;
- an expired entitlement never revives;
- the guard survives save, relaunch, background and foreground.

Legacy saves import unchanged and are protected from their first upgraded load. All ten required test groups pass, and the sensitivity check fails as intended when the guard is bypassed.

## Git / owner work

- `main` was fast-forwarded to `ec9d597`.
- Pre-existing owner/local items were left untouched and not committed:
  - the `project.godot` modification;
  - the untracked opening video;
  - the other agent's untracked `tests/_m55_diag_tmp.gd`.

## Implementation (single production file)

All changes are in `scripts/economy/speed_entitlement_service.gd`:

- **New field** `_clock_high_water`: the highest wall-clock value observed, never decreasing.
- **`_effective_now()`** raises the high-water mark to the current clock and returns it. Timed truth uses this effective time in:
  - `timed_seconds_remaining()`;
  - `is_manual_2x_entitled()` (timed branch only; the current-level branch is unchanged);
  - `purchase_timed()` (base = max(effective now, expiry));
  - `snapshot()`.
- **Effect:**
  - a backward jump freezes the countdown;
  - forward movement below the mark keeps it frozen;
  - past the mark it counts down and expires normally.
- **`snapshot()`** adds `clock_high_water`.
- **`import_snapshot()`** handles the guard:
  - **present:** must pass `IntDomain.nonneg_int` (exact non-negative integer; integral JSON floats accepted), otherwise the whole import returns false before any mutation;
  - **absent (legacy):** initialized at the import boundary from the observed current clock. The legacy `timed_expiry` is imported as-is, so a legitimately active entitlement is kept and no clock history is invented.
- **Read-only accessor:** `clock_high_water()`.

**Why no save-schema version bump:** the field is additive inside `economy.speed`. The M40 `SaveService` validates the economy section by dry-run import, so malformed guards are rejected there as `economy_import`, and an invalid primary falls back to the backup exactly as before.

**Unchanged:**
- prices and durations: 900/300, 1800/500, 3600/750; current level 200;
- current-level 2x logic;
- the free M23 auto-2x (runtime-owned, never in this service);
- Heart rules;
- First 10 content, supply plans, owner clicks and difficulty systems;
- M43+ surfaces.

## Tests

**New: `tests/m55_c002_timed_2x_anti_rollback.gd`** — 53 ok, case ledger 10/10. Before/after values are in the matrix.

| # | Group | Result |
|---|---|---|
| 1 | Active entitlement, rollbacks 1 s…1 year | remaining stays 1200 |
| 2 | Expired entitlement, 5 rollbacks | 0 revivals |
| 3 | Frozen below the high-water mark | resumes only beyond it (1100 at mark + 100); normal expiry still works |
| 4 | Save/relaunch | guard in the save file; relaunch after 5000 s rollback = 1200 (pre-fix 6200); expired stays expired after a 100k s rollback |
| 4b | Production host, background/foreground | 7200 s rollback while backgrounded → 600 unchanged (pre-fix 7800) |
| 5 | Legacy snapshot and a real legacy save file (field stripped) | loads from primary; active entitlement kept; rollback protected afterwards; the first upgraded save writes the guard |
| 6 | Malformed guard | 10/10 malformed values rejected with state untouched; `validate_candidate` → `economy_import`; a malformed primary on relaunch falls back and is never adopted |
| 7 | New purchase | extends from max(effective, expiry) and charges exactly once (300 / 750 SB); insufficient SB → nothing |
| 8 | Current-level 2x and free auto-2x | current-level 2x unchanged; free auto-2x engages on production Level 2 with a rolled-back clock, 0 SB |
| 9 | Product table and Heart 900 s | unchanged |

**Updated: `tests/m55_core_chaos.gd` SB-M55-015.** The former observation print ("timed 2x 5000 s remaining after rollback") is now the owner-rule assertion: remaining 0 and not entitled.

## Sensitivity

`_effective_now()` was temporarily changed to return the raw wall clock, i.e. the high-water clamp was bypassed.

- **Bypassed:** the focused suite gives **exit 1, FAIL (10)**. It reproduces the pre-fix values:
  - 1201 / 1260 / 6200 / 87,600 / 31,537,200;
  - 5 revivals;
  - relaunch 6200;
  - foreground 7800;
  - legacy entitlement extended;
  - a purchase extending from the rolled-back clock.
- **Restored** from a byte-for-byte copy: **exit 0, PASS.** The file was checked for leftover bypass text (0 matches).

## Regression (Godot 4.7.2.stable.official.ed1daf0bf, headless, 12-way parallel)

| Suite | Result |
|---|---|
| `m55_c002_timed_2x_anti_rollback` (new) | exit 0, 53 ok |
| `m39b_hearts_speed` | exit 0, 32 ok |
| `m39a_economy_core` / `m39c_boosters` / `m39d_daily_collection` / `m39e_full_matrix` | exit 0, 38 / 45 / 34 / 21 ok |
| `m39_v02_atomicity` / `_capacity` / `_integration` | exit 0, 21 / 19 / 34 ok |
| `m39_v03_full_surface` / `_integration` | exit 0, 37 / 18 ok (the speed `import_snapshot` sentinel tests still pass) |
| `m39_v04_integration` / `m39_v04_tornado_inflight` | exit 0, 150 / 132 ok |
| `m40_save_system` / `m40_v02_safety` / `m40_v03_canonical` / `m40_v04_bootstrap` | exit 0, 38 / 34 / 21 / 58 ok |
| `m42_navigation` | exit 0, 82 ok |
| `m52_r01_parallel_runtime` / `m52_r02_early_slot_release` / `m52_owner_supply_plans` | exit 0, 79 / 65 / 255 ok (2x popup purchases, R01/R02 behaviour, 9/9 WON) |
| `m54_collection_set_master_exactly_once` | exit 0, 192 ok |
| `m55_core_chaos` | exit 0, 129 ok (+1 for the new rollback assertion) |
| `m55_long_session` | exit 0, 39 ok |
| `m55_heart_900_authority` | exit 0, 19 ok |
| `m55_economy_release_regression` | exit 0, 11 ok |
| root `tests/run_tests.gd` | exit 0, **5323 checks, RESULT: ALL PASS**, 9 engine `ERROR:` lines (baseline fixtures) |
| `git diff --check` / `--cached --check` | clean |

Across all 27 suites there are 0 `FAIL:` and 0 `SCRIPT ERROR`. The only engine `ERROR:` classes are:
- "N resources still in use at exit" (pre-existing);
- M52's intentional malformed-JSON fixture;
- the root suite's intentional corrupt/missing-image fixtures.

No new runtime fault appeared.

## Changed files

- `scripts/economy/speed_entitlement_service.gd`
- `tests/m55_c002_timed_2x_anti_rollback.gd` (new)
- `tests/m55_core_chaos.gd` (the SB-M55-015 observation is now an assertion)
- `coordination/sessions/M55-C002/TIMED_2X_ANTI_ROLLBACK_MATRIX_V01.md` (new)
- `coordination/sessions/M55-C002/CLAUDE_LOG_V01.md` (this file)

## Reproduce

```bash
godot --headless --path . -s res://tests/m55_c002_timed_2x_anti_rollback.gd
```

`AWAITING_CHATGPT_AUDIT / M55-C002 TIMED 2X ANTI-ROLLBACK`
