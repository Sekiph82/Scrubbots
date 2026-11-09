STATUS: READY

# Build: CI exit heap corruption (m47_touch_r01_mobile_ux, m43_c005f_phase4_terminal_home_micro)

## Summary
Both suites assign test-script lambdas to the static vars `MainScript.boot_clock_override` and `MainScript.boot_local_day_override` in main.gd and never reset them. They are the only CI suites that do this; the other 35 suites that set these overrides reset them to `Callable()`. Factory 144's `economy.dispose()` on PREDELETE breaks the reward-handler cycle, so the AppState graph no longer leaks. Before 144, that leaked graph kept main.gd's GDScript alive until the process exited. Now main.gd is freed normally at exit, its static Callables are destroyed after the test script that owns the lambdas is gone, and that is a use-after-free. glibc reports it as "corrupted size vs. prev_size in fastbins" (exit 134); Windows segfaults (exit 139).

The fix is in tests only. `_cleanup()` now resets both overrides to `Callable()` in the two crashing suites. Two non-CI suites with the same pattern get the same fix. Factory 144's dispose is unchanged, so the leak fix and the final save stay intact.

Files changed:
- tests/m47_touch_r01_mobile_ux.gd
- tests/m43_c005f_phase4_terminal_home_micro.gd
- tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd (not in CI, same pattern)
- tests/m43_c005f_phase5_cleaning_spark_ab.gd (not in CI, same pattern)
- TASKS.md (new DONE row SB-CI-RED-2026-11-09B)

Commits: 242aa21f (tests), d49126be (TASKS.md). Not pushed.

## Acceptance criteria
1. [x] Reproduce. WSL could not start: "WSL2 is unable to start since virtualization is not enabled" (HCS_E_HYPERV_NOT_INSTALLED). So no Linux binary was downloaded. The crash reproduces deterministically on Windows Godot 4.7.2 headless:
   - HEAD ed81298a: m47 printed `PASS (14/14)` and then exited 139 (Segmentation fault), 3 out of 3 runs.
   - Same tree with e467c125's main.gd PREDELETE hunk reverted: exit 0, 3 out of 3 runs.
   - 144 kept and only the override reset added: exit 0, 3 out of 3 runs.
2. [x] Root cause identified and fixed minimally: the static override lambdas that outlive the test script (see Summary). In CI, the crashing set is exactly the suites with zero `_override = Callable()` resets (checked with grep over every test that assigns `boot_clock_override = func`).
3. [x] 144's leak fix is still effective. m55_long_session PASS: `ok: freed app root releases AppState / EconomyServices / StoreService`, `ok: Object count drift 0 <= 64`, and the lap 2 vs lap-1 end check passes with Object drift <= 64.
4. [x] Required suites pass on Windows (LOCAL_PASS). Linux was not possible (see 1).

## Validation
All runs are Windows Godot 4.7.2 headless (`$GODOT --headless --path <worktree> -s res://tests/<suite>.gd`):
- m47_touch_r01_mobile_ux: exit 0, no diagnostics, PASS (14/14), 3 runs.
- m43_c005f_phase4_terminal_home_micro: exit 0, PASS (19/19), 3 runs. The 5 SCRIPT ERRORs are the labelled 'explode' fault injections that CI filters for this suite; the CI log has the same ones.
- m43_c005f_phase4_qa_r01_feel_lifecycle: exit 0, PASS (4/4).
- m43_c005f_phase5_cleaning_spark_ab: exit 0, PASS (13/13). The 2 SCRIPT ERRORs are labelled EXPECTED_FAULT_INJECTION.
- m55_long_session: exit 0, PASS.
- m39e_full_matrix: exit 0, PASS.
- m40_save_system: exit 0, PASS.
- `git diff --check` on the changed tests: clean.

No CI run. The Linux exit crash is fixed by inference: Windows shows the same root cause and fix.

## Log
### Round 1
- WSL was unusable (no virtualization), so the Windows engine was used for reproduction. It segfaults at exit with the same trigger.
- Bisected with the 144 main.gd hunk reverted: no crash. The two suites are the only CI suites that leave main.gd static lambdas set, which identified the mechanism.
- Chose the test cleanup fix over changing dispose. Dispose is correct; the dangling static lambdas were the latent bug that 144 exposed.
- Ran a `--import` in the worktree. Restored the reimported `.import` files with `git checkout -- .` and removed only the untracked import artifacts (`.uid`, `.translation`). Scratch logs were deleted.
- Follow-up not done: a source guard that every test assigning `boot_*_override = func` also resets it. Add it if this recurs.
