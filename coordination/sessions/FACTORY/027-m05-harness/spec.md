# Local one-command suite runner + testing conventions (SB-M05-006..010)

> Feature: SB-M05-006..010 — test harness: organize sections, split perf output from assertions, one-command wrapper, regression conventions doc

## Context
- Status on main: none of the five items has a deliverable. `TASKS.md` lines 782-786 are all `[ ]`; queue line 27 is READY. There is no `tests/*.sh|ps1|py` and no runner; `tests/` is ~180 flat `.gd` suites (357 files with `.uid`) run one at a time as `"$GODOT" --headless --path <wt> -s res://tests/<suite>.gd` (AGENTS.md "Local Godot").
- The only suite list is the `for s in ...; do` loop in the `validate` job of `.github/workflows/android-family-first10.yml` (44 suites, ~lines 100-115). Per suite CI: runs with `timeout 1500`, logs to `validate_logs/<s>.log`, counts script diagnostics with `DIAG='^(ERROR: )?(SCRIPT ERROR|Parse Error|Failed to load script)'` (only `m43_c005f_phase4_terminal_home_micro` tolerates `SCRIPT ERROR: Invalid call. Nonexistent function 'explode' in base 'Nil'.`), takes `last=$(grep -E 'PASS|FAIL|RESULT' log | tail -1)`, and is FAIL if exit!=0, diag!=0, last lacks PASS or contains FAIL. Then fixed `grep -qxF` exact-summary guards for CP06 16/16, M44 23/23, M45 8/8, M49 8/8, M50 4/4, M51 4/4, M50S 10/10, M46 22/22 (line format `<Name> evidence: PASS (N/N cases, 0 fail)`).
- Existing docs: `docs/06_TEST_STRATEGY.md` (300 lines, per-prompt sections; "Performance sanity (not a pass/fail gate)" at ~line 78 and 164 already states perf is printed for diagnostics only, no ms threshold). `tests/run_tests.gd` prints perf diagnostics inline alongside assertions (`_run_performance_sanity*`), `tests/m46_performance.gd` is the dedicated perf suite (22 cases).
- Local safety: memory/AGENTS rule that main.tscn/save-writing suites must never touch the owner save (use throw-away save override; see how `tests/m28_c002_c001_gameplay_v02.gd` and `tests/m40_save_system.gd` redirect saves).

## Requirements
1. Add `tools/run_suites.py` (stdlib Python 3, no deps). It reads the suite names by parsing the `for s in ... ; do` block of `.github/workflows/android-family-first10.yml` (the single source of truth; do NOT copy the list anywhere, and do NOT edit the workflow).
2. It also reads the exact-summary guards from the workflow (every `grep -qxF '<line>' validate_logs/<s>.log`) so a suite with a guard must print that exact line (whole-line match) to pass.
3. Godot binary: `$GODOT` env var, else `godot_console` / `godot` on PATH, else the AGENTS.md WinGet path; clear error and exit 2 if none found.
4. CLI: `python tools/run_suites.py [--path <checkout>=repo root of the script] [--timeout 1500] [suite ...]`. With no suite args runs all; with args runs only those (names without `.gd`; unknown name = error exit 2). `--list` prints the suites and exits 0.
5. Per suite: run headless with the CI command, write the log to `<path>/validate_logs/<suite>.log` (create dir; this dir must be git-ignored or already ignored - add to `.gitignore` if not), apply the CI PASS/FAIL rule above exactly (exit code, DIAG count with the same `explode` exception for m43_c005f, last PASS/FAIL/RESULT line, exact-summary guard), print one line `<suite> status=PASS|FAIL exit=N diag=N | <last line>` and a final `aggregate=PASS|FAIL (p/total)`. Exit 0 only if all selected suites pass, else 1. Continue past failures (do not stop at first).
6. Do not rename, move or edit any existing test file or the workflow. Do not boot `main.tscn` or write the owner save; the runner just runs suites as CI does.
7. Add `docs/TESTING_CONVENTIONS.md` (short, <=120 lines) covering: suite naming (`<milestone>_<topic>.gd`, `tests/` flat, fixtures in `tests/fixtures/`); the required exact final summary line `<Name> evidence: PASS|FAIL (N/N cases, 0 fail)` and when to add a CI exact-summary guard; adding a suite = add it to the workflow loop (the runner picks it up automatically); how to run: `python tools/run_suites.py [suite...]`; result labels `LOCAL_PASS` (runner/headless locally, state SHA) vs CI-run labels (Actions run id); throw-away save override rule (never touch the owner's `user://` save, tests that need saves redirect to a temp path and delete it); perf rule: assertions must be deterministic and never use ms thresholds; timing/benchmark numbers are diagnostics printed with a `PERF` prefix and must not affect PASS/FAIL (m46_performance is the dedicated perf suite); regression gate: a milestone/task is not closed until the full `run_suites.py` aggregate is PASS (or the CI `validate` job is green) at the closing SHA, with evidence recorded in the evidence file.
8. Addressing the five items: 006 (sections) and 007 (perf split) are met by the conventions doc only (explicitly: no restructuring of existing suites; new suites follow the convention). 008 is the runner (Python, not PowerShell, because the CI list parser is shared and Python runs on Windows and Linux; note this in the doc). 009 and 010 are the doc. Mark SB-M05-006..010 `[x]` in `TASKS.md` with a one-line note and remove/close the queue line 27 per the factory convention.
9. Add one line to `AGENTS.md` "Local Godot" pointing at `python tools/run_suites.py` and `docs/TESTING_CONVENTIONS.md`; add one pointer line at the top of `docs/06_TEST_STRATEGY.md` to the conventions doc.

## Acceptance criteria
1. `python tools/run_suites.py --list` prints exactly the suites in the workflow loop (compare: count is 44 and first is `m35_level_catalog`, last is `m46_performance`) and exits 0. `grep -c "m46_performance" tools/run_suites.py` is 0 (no duplicated list).
2. `python tools/run_suites.py m50_accessibility_audit m51_localization_readiness m45_debug_tooling` (with `GODOT` set) prints three lines each ending `status=PASS`, ends with `aggregate=PASS (3/3)`, exit code 0, and the logs exist under `validate_logs/`.
3. `python tools/run_suites.py nonexistent_suite` exits 2 with an error message naming it.
4. Negative check: running the runner against a copy of a guarded suite log is not required; instead the builder temporarily makes a guard unmatched (e.g. via a unit-style `python tools/run_suites.py --selftest` that feeds fake log text to the pass/fail function: exit!=0 -> FAIL, diag>0 -> FAIL, last line lacking PASS -> FAIL, missing exact summary -> FAIL, `explode` line tolerated only for m43_c005f) and prints `selftest PASS`. Verify `python tools/run_suites.py --selftest` prints `selftest PASS` and exits 0.
5. `docs/TESTING_CONVENTIONS.md` exists and contains the strings `LOCAL_PASS`, `evidence: PASS`, `PERF`, `run_suites.py`, `save`; `AGENTS.md` and `docs/06_TEST_STRATEGY.md` each reference `TESTING_CONVENTIONS.md` (grep).
6. `git diff --name-only main...HEAD` contains no file under `tests/` (except none) and not `.github/workflows/*`; `git diff --check` clean.
7. `TASKS.md` shows SB-M05-006..010 as `[x]`.
8. Existing suite still passes: `"$GODOT" --headless --path <worktree> -s res://tests/run_tests.gd` last PASS/FAIL/RESULT line contains PASS.

## Out of scope
- Renaming/moving/splitting existing tests, editing the workflow, adding new Godot test suites, changing perf output inside existing suites (documented as convention for new work only).
- Moving the suite list out of the workflow into a separate file.
- Parallel execution, PowerShell wrapper, HTML reports, CI changes, export/APK steps.
- Running the full 44-suite pass as an acceptance requirement (long); the builder may run it but only the 3-suite subset is required.

## Assumptions
- Python 3 is available locally (verified, Python312) and on ubuntu-latest; chosen over PowerShell/bash so one parser works on both OSes and the workflow stays the only list.
- Parsing the workflow text with a regex (`for s in` ... `; do`, backslash continuations) is acceptable; if the workflow loop format changes, the runner errors loudly rather than guessing (acceptance 1 guards this).
- Tolerating the `explode` diagnostic only for m43_c005f mirrors CI; the runner hardcodes that single exception with a comment pointing at the workflow.
- Items 006/007 are convention-level, because reorganizing flat `tests/` or splitting perf output would break CI paths and exceeds the smallest useful deliverable.
