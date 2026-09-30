# M39-C002 — CLOCK-BOUNDARY TEST STABILITY FOLLOW-UP — IMPLEMENTATION PROMPT V01

Date: 2026-09-30
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M39-053`
Status: READY FOR CLAUDE

Do not edit root `TASKS.md`.

## Mission

Remove the real-wall-clock boundary flake in:

`tests/m39_v04_integration.gd`

specifically in:

`_phase_c_plus_one()`

while PRESERVING the strong exact rollback assertion:

`econ.snapshot() == pre_econ`

This is a TEST-FIXTURE STABILITY task.

Do not change production economy semantics.

## Root cause to verify

The current Phase C host uses the host-private fallback economy:

`ProductionGameplayHost -> EconomyServices.new()`

with the real OS wall clock.

The exact rollback check captures:

`pre_econ = econ.snapshot()`

and later compares:

`econ.snapshot() == pre_econ`

Two production snapshot components are intentionally wall-clock observing:

### HeartService

When hearts are already full:

`HeartService._accrue()`

sets:

`_anchor = _now()`

Therefore two otherwise identical snapshots on opposite sides of a real one-second boundary can differ only in:

`hearts.anchor`

### SpeedEntitlementService

`SpeedEntitlementService.snapshot()`

calls:

`_effective_now()`

which advances the persisted non-decreasing:

`speed.clock_high_water`

Therefore the same real-time boundary can also change:

`speed.clock_high_water`

Those are valid production semantics, not rollback defects.

The test is flaky because it asks for byte/exact snapshot equality while using a moving real clock.

## Required fix

Inject a deterministic fixed wall clock into the Phase C host/economy fixture.

Preferred path: use the EXISTING canonical test seams, not a new shipping API.

Available seam:

`AppState.new(save_path, clock, local_day)`

which creates:

`EconomyServices.new(..., clock, ..., local_day)`

and can already be injected into:

`ProductionGameplayHost.app_state`

before `build()`.

Use this or an equally existing seam.

### Fixed clock

Use a positive deterministic timestamp, e.g. a constant in a safe Unix-time range.

The same Phase C host must observe exactly that clock for:
- HeartService;
- SpeedEntitlementService;
- DailyService clock reads.

Also provide a deterministic local-day provider when using AppState so the fixture is entirely independent of host timezone/date.

## Scope localization

Prefer to make ONLY the Phase C +1 Slot rollback fixture deterministic.

Phases B/D/E should not be semantically rewritten unless a minimal helper refactor is needed.

If `_make_host()` is extended, use an optional deterministic-fixture argument so unrelated tests preserve their prior path unless there is a documented reason to share the fixed AppState.

## Temp-save hygiene

If AppState is used:

- use a unique `user://` test save path;
- delete any pre-existing file before construction;
- clean the file after the host/test case;
- do not touch the canonical player save;
- no test artifact may leak between runs.

The clean committed +1 Slot case may hit the normal save boundary, so cleanup must cover files that are actually created.

## The exact assertion MUST remain strong

Do NOT:
- remove `econ.snapshot() == pre_econ`;
- compare only wallet/boosters;
- strip `hearts.anchor`;
- strip `speed.clock_high_water`;
- normalize timestamps before comparison;
- allow a timestamp delta/tolerance;
- sleep/retry until equality happens;
- mock `snapshot()`;
- patch HeartService or SpeedEntitlementService production behavior.

The rollback assertion must remain an exact whole-economy snapshot equality check.

## Production files — LOCKED

No production code changes are expected or authorized.

In particular do NOT edit:

- `scripts/economy/heart_service.gd`;
- `scripts/economy/speed_entitlement_service.gd`;
- `scripts/economy/economy_services.gd`;
- `scripts/app/app_state.gd`;
- `scripts/gameplay/runtime/production_gameplay_host.gd`;
- booster/capacity/slot production code.

If you believe production code is required, STOP and report why instead of changing it.

## Required focused proof

In the test/evidence, prove:

1. Phase C host uses the deterministic injected AppState/economy clock.
2. Before rollback tests:
   - `hearts.anchor` is deterministic;
   - `speed.clock_high_water` is deterministic.
3. After each forced failure:
   - exact `econ.snapshot() == pre_econ` remains true.
4. Both failure stages remain covered:
   - `engine`;
   - `strip`.
5. Both payment paths remain covered:
   - owned +1 Slot charge;
   - SB purchase.
6. The clean +1 Slot commit still succeeds afterward.
7. No temp save remains after the run.

Do not reduce existing Phase C assertions.

## Stability gate — BLOCKING

Run:

`tests/m39_v04_integration.gd`

**10 consecutive isolated times** on the final code.

Requirements:
- all 10 exit 0;
- zero Phase C failures;
- exact economy rollback assertion passes on every engine/strip × charge/SB case;
- record each run exit code in evidence.

A single PASS is insufficient.

Also run the test once with enough logging/evidence to show the injected fixed timestamp and the exact pre/post heart/speed clock fields.

## Wall-clock production semantics regression

Because the fix removes real time from one test fixture, separately verify that production wall-clock behavior is still covered and unchanged.

Run at minimum:

- `m39b_hearts_speed.gd`;
- `m55_c002_timed_2x_anti_rollback.gd`;
- `m55_heart_900_authority.gd`;
- relevant M39 V04 integration;
- M43/M55 speed/heart regressions if available in the current suite.

Do not weaken those tests.

## General regression

Run:

- 10x isolated `m39_v04_integration`;
- root `tests/run_tests.gd`;
- M39 integration/economy suites;
- M40 save suites;
- M43 acquisition/economy suites;
- M55 economy/clock suites;
- `git diff --check`.

Known historical M21 v08/v09 failures may remain only with their exact known signatures if the broad runner includes them.

## Evidence

Create:

`coordination/sessions/M39-C002/evidence/`

At minimum:

- `m39_v04_10x_stability.txt`
  - run 1..10;
  - exit code;
  - summary;
- `clock_fixture_proof.txt`
  - fixed clock value;
  - deterministic local day;
  - representative pre/post `hearts.anchor`;
  - representative pre/post `speed.clock_high_water`;
  - exact snapshot equality result;
  - temp-save cleanup proof;
- `regression_summary.txt`.

## Governance

Do not edit root `TASKS.md`.

Preserve owner/local untracked files.

No destructive reset/clean/force push.

## Required outputs

Create:

- `coordination/sessions/M39-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M39-C002/IMPLEMENTATION_MATRIX_V01.md`
- evidence files above.

Commit/push to `main`.

Return:
1. final SHA;
2. exact test-fixture change;
3. confirmation production files are unchanged;
4. 10/10 isolated result;
5. representative clock-field proof;
6. regression summary.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M39-C002 CLOCK-BOUNDARY TEST STABILITY V01`
