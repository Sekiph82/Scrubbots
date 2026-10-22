STATUS: READY

# Build: Local one-command suite runner + testing conventions (SB-M05-006..010)

## Summary
Adds `tools/run_suites.py`, a Python 3 runner that uses only the standard library. It reads the suite list (`for s in ...; do`) and the `grep -qxF` exact-summary guards from `.github/workflows/android-family-first10.yml`. The list is not copied anywhere. The runner runs each suite headless the same way CI does, writes `validate_logs/<suite>.log` and applies the CI PASS/FAIL rule: exit code, DIAG count with only m43_c005f's `explode` line tolerated, the last PASS/FAIL/RESULT line, and the exact whole-line guard. It prints one line per suite plus `aggregate=PASS|FAIL (p/total)`, and exits 0, 1, or 2 for usage or setup errors. It also has `--list` and `--selftest`. Adds `docs/TESTING_CONVENTIONS.md`, which covers items 006, 007, 009 and 010 as conventions only. No existing suite was restructured.

Files changed:
- `tools/run_suites.py` (new)
- `docs/TESTING_CONVENTIONS.md` (new, 99 lines)
- `docs/06_TEST_STRATEGY.md` (one pointer line at the top)
- `AGENTS.md` (one line under "Local Godot")
- `.gitignore` (adds `validate_logs/`)
- `TASKS.md` (SB-M05-006..010 set to `[x]`; queue row 27 set to DONE)

Commits: 2a870231 (runner + docs), 74edd83c (TASKS.md).

## Acceptance criteria
1. [x] `--list`: `python tools/run_suites.py --list` exits 0 and prints 44 lines (counted with wc -l). The first is `m35_level_catalog` and the last is `m46_performance`. `grep -c m46_performance tools/run_suites.py` prints 0.
2. [x] 3-suite run: `python tools/run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling` printed `m50_accessibility_audit status=PASS exit=0 diag=0 | M50 accessibility audit evidence: PASS (4/4 cases, 0 fail)`, the same for m51 (4/4) and m45 (8/8), then `aggregate=PASS (3/3)`, exit 0. The three logs exist in `validate_logs/`. Following spec requirement 5, each line has the format `<suite> status=... exit=N diag=N | <last line>`, so `status=PASS` appears in the middle of each line, before the last-line text, and not at the end.
3. [x] Unknown suite: `python tools/run_suites.py nonexistent_suite` prints `error: not in the workflow suite list: nonexistent_suite` and exits 2.
4. [x] Selftest: `python tools/run_suites.py --selftest` prints `selftest PASS` and exits 0. It covers these cases: exit!=0 is FAIL, a SCRIPT ERROR or Parse Error diag is FAIL, a last line of RESULT without PASS is FAIL, a last line containing FAIL is FAIL, no PASS line at all is FAIL, a wrong summary count is FAIL, an indented summary (not a whole-line match) is FAIL, the `explode` line is tolerated only for m43_c005f, and any other SCRIPT ERROR in m43_c005f is FAIL.
5. [x] Docs: `docs/TESTING_CONVENTIONS.md` contains `LOCAL_PASS`, `evidence: PASS`, `PERF`, `run_suites.py` and `save`. `AGENTS.md` line 8 and `docs/06_TEST_STRATEGY.md` line 3 reference `TESTING_CONVENTIONS.md`.
6. [x] Diff scope: `git diff --name-only main...HEAD` lists `.gitignore, AGENTS.md, TASKS.md, docs/06_TEST_STRATEGY.md, docs/TESTING_CONVENTIONS.md, tools/run_suites.py`. It includes nothing under `tests/` and no workflow file. `git diff --check` is clean.
7. [x] TASKS.md: lines 782-786 show SB-M05-006..010 as `[x]` with SHA and evidence. Queue row 27 is `DONE`.
8. [x] `run_tests`: `python tools/run_suites.py run_tests` printed `run_tests status=PASS exit=0 diag=0 | RESULT: ALL PASS`.

## Validation
- Full regression with the new runner (optional, run anyway): `python tools/run_suites.py` with no arguments printed `aggregate=PASS (44/44)` at 74edd83c. Exit code 0, LOCAL_PASS. All eight guarded exact summaries were matched: CP06 16/16, M44 23/23, M45 8/8, M49 8/8, M50 4/4, M51 4/4, M50S 10/10, M46 22/22.
- The `--selftest`, `--list` and unknown-suite checks above all passed.
- `git diff --check` is clean. `git check-ignore validate_logs/m46_performance.log` confirms the logs are ignored.
- No tests were added under `tests/`; the spec forbids it. The permanent check for the new logic is `--selftest`.
- Worktree note: `git status` shows untracked `*.uid` / `*.import` files that the Godot import created before this build (they are not task files and were not committed). Apart from those, the tree is clean.

## Log
### Round 1
- Wrote the runner, the conventions doc, the pointer lines, the `.gitignore` entry and the TASKS.md closure.
- Godot discovery checks, in order: `$GODOT`, then `godot_console` or `godot` on PATH, then the AGENTS.md WinGet path. If none is found it prints an error and exits 2.
- A timeout is reported as exit 124, as in CI.
- Ran all 44 suites locally: PASS.
