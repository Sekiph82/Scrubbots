# M39-C002 — CLAUDE LOG V01 — Clock-Boundary Test Stability

Date: 2026-09-30
Task: `SB-M39-053`
Prompt: `coordination/sessions/M39-C002/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M39-C002/CHATGPT_AUDIT_CRITERIA_V01.md`
Engine: Godot 4.7.2.stable.official.ed1daf0bf
Status: `AWAITING_CHATGPT_AUDIT`

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`, upstream `origin/main`.
- Local was behind 7 at `649cf62`; fast-forwarded to `8a4f947` (incoming commits touched only `TASKS.md` + coordination docs).
- Pre-existing local owner work preserved and NOT committed: `project.godot` drift, untracked assets / `.import` / `.uid` files, `tests/_m55_diag_tmp.gd`.
- Root `TASKS.md` not edited.

## Root cause (confirmed by reading code)

`_phase_c_plus_one()` used `_make_host()` without an AppState, so the host built its private fallback `EconomyServices.new()` on the real OS clock. `econ.snapshot()` is wall-clock observing by design:

- `HeartService.snapshot()` -> `_accrue()` sets `_anchor = now` when hearts are full -> `hearts.anchor`;
- `SpeedEntitlementService.snapshot()` -> `_effective_now()` advances `clock_high_water` -> `speed.clock_high_water`.

`pre_econ` and the post-rollback snapshot taken on opposite sides of a real 1-second boundary differ only in those two fields, so the exact equality flaked. Production semantics are correct; the fixture used a moving clock.

## Change (test-only)

`tests/m39_v04_integration.gd`:

1. Constants `PHASE_C_FIXED_CLOCK := 1790000000` (2026-09-21 UTC, positive) and `PHASE_C_LOCAL_DAY := PHASE_C_FIXED_CLOCK / 86400` (= 20717).
2. Phase C builds `AppState.new(save_path, func(): return PHASE_C_FIXED_CLOCK, func(): return PHASE_C_LOCAL_DAY)` on a unique `user://m39_v04_phase_c_fixed_<ticks_usec>.dat` (pre-deleted) and injects it via `_make_host(app)` -> `host.app_state = app` before `build()` (existing seam; host consumes `app_state.economy`).
3. New Phase C assertions (additive):
   - host economy is the injected AppState economy;
   - hearts/speed/daily `_clock` return the fixed clock; daily local-day provider returns the fixed day;
   - before each of the 4 cases: `pre_econ.hearts.anchor == speed.clock_high_water == 1790000000`;
   - after host free: temp save `main/.bak/.tmp` removed.
4. Per-case info print of pre/post `hearts.anchor` and `speed.clock_high_water`.
5. `_make_host(app = null)`: optional arg; `null` keeps Phases D/E on the prior host-private fallback path (unchanged).
6. Helper `_remove_save(path)` deletes `path`, `.bak`, `.tmp`.

Unchanged: `_ok(econ.snapshot() == pre_econ, ...)` exact whole-economy equality — no field stripped, no normalization, no tolerance, no retry/sleep, no mock. All prior Phase C checks kept (forced failure false, M24 back at 5, slots exact, strip 5, capacity (5, unused), exact economy, slot 5 unroutable, can grow again, charge/SB refund, clean commit to 6, SB non-negative).

Production files: no changes (HeartService, SpeedEntitlementService, EconomyServices, AppState, ProductionGameplayHost, +1 Slot / booster / capacity code untouched).

## Validation

- `m39_v04_integration.gd` 10 consecutive isolated runs: **10/10 exit 0**, 0 Phase C failures, exact-rollback ok ×4 per run — `evidence/m39_v04_10x_stability.txt`.
- Fixed-clock proof (pre/post anchor + high-water = 1790000000 in all 4 cases; temp save written by clean commit then cleaned) — `evidence/clock_fixture_proof.txt`.
- Regression: root `tests/run_tests.gd` ALL PASS, 5323 checks; M39 (12 suites), M40 (4), M43 (4), M55 (5) all exit 0 PASS; wall-clock suites `m39b_hearts_speed`, `m55_c002_timed_2x_anti_rollback`, `m55_heart_900_authority` PASS — `evidence/regression_summary.txt`.
- `git diff --check` clean.
- `user://` listing identical before the stability batch and after the full regression (no leaked temp saves, canonical save untouched).

No failures encountered; no fixes beyond the fixture change were needed.

## Handoff

`AWAITING_CHATGPT_AUDIT / M39-C002 CLOCK-BOUNDARY TEST STABILITY V01`
