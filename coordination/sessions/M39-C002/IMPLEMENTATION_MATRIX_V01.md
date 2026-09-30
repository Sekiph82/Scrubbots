# M39-C002 — IMPLEMENTATION MATRIX V01

| Criterion | Requirement | Implementation / evidence | Status |
|---|---|---|---|
| A | Test-only scope | Only `tests/m39_v04_integration.gd` + `coordination/sessions/M39-C002/**` changed; no production file in diff | DONE |
| B | Root cause: remove moving OS clock | Phase C uses existing `AppState.new(save_path, clock, local_day)` seam injected as `host.app_state`; fixed clock 1790000000, fixed local day 20717 | DONE |
| C | Exact `econ.snapshot() == pre_econ` preserved | Assertion unchanged; no stripped fields, no normalization/tolerance/retry/mock; engine/strip × charge/SB all exercised | DONE |
| D | Fixed-clock evidence | In-test asserts: host economy == injected, hearts/speed/daily clocks fixed, pre anchor/high-water == fixed; pre/post printed per case — `evidence/clock_fixture_proof.txt` | DONE |
| E | Temp-save hygiene | Unique `user://m39_v04_phase_c_fixed_<usec>.dat`, pre-delete, delete main/.bak/.tmp after host free + assert; user:// listing unchanged | DONE |
| F | 10x stability | 10/10 exit 0, 0 Phase C FAIL — `evidence/m39_v04_10x_stability.txt` | DONE |
| G | Existing Phase C checks preserved | All prior checks retained and PASS; clean +1 Slot commits to 6 | DONE |
| H | Wall-clock semantics still tested | `m39b_hearts_speed`, `m55_c002_timed_2x_anti_rollback`, `m55_heart_900_authority` PASS; Phase B OS-local-calendar check unchanged; Phases D/E keep fallback path | DONE |
| I | Regression / governance | root 5323 checks ALL PASS; M39/M40/M43/M55 PASS; `git diff --check` clean; `TASKS.md` untouched — `evidence/regression_summary.txt` | DONE |
