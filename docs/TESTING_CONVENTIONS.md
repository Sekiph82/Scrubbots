# Testing Conventions

Short rules for headless Godot test suites (SB-M05-006..010). The broader history
of what each prompt tested lives in `docs/06_TEST_STRATEGY.md`. These conventions
apply to new work; existing suites are not restructured.

## Suite layout and naming

- One suite = one `extends SceneTree` script in `tests/`, kept flat (no subfolders).
- Name: `<milestone>_<topic>.gd`, e.g. `m45_debug_tooling.gd`, `cp06_disabled_levels.gd`.
- Fixtures (level JSON, packs, images) go in `tests/fixtures/`.
- Inside a suite, group cases into named sections (`s01_...`, `case_01_...`) that each
  print their own PASS/FAIL line. New behaviour = new section, not a new mixed blob.

## Required final summary line

Every new suite ends with one exact line and exits non-zero on failure:

```
<Name> evidence: PASS (N/N cases, 0 fail)
<Name> evidence: FAIL (P/N cases, F fail)
```

This must be the last line of the log that contains `PASS`, `FAIL` or `RESULT`.

Add a CI exact-summary guard (`grep -qxF '<line>' validate_logs/<suite>.log` in the
`validate` job of `.github/workflows/android-family-first10.yml`) when the case
count itself is part of the contract: a milestone gate, or a suite where silently
skipping cases would hide a regression. Update the guard when you add cases.

## Adding a suite to the regression set

Add the suite name to the `for s in ... ; do` loop of the `validate` job in
`.github/workflows/android-family-first10.yml`. That loop is the only suite list;
`tools/run_suites.py` reads it (and the exact-summary guards) directly, so there is
nothing else to update. Never copy the list into another file.

## Running suites

```
python tools/run_suites.py                 # all workflow suites
python tools/run_suites.py m45_debug_tooling run_tests
python tools/run_suites.py --list          # print the suite list
python tools/run_suites.py --selftest      # check the PASS/FAIL rule itself
```

Options: `--path <checkout>` (default: the repo holding the script),
`--timeout <s>` (default 1500, as CI). Godot is `$GODOT`, else `godot_console` /
`godot` on PATH, else the WinGet path from AGENTS.md "Local Godot".

Per suite it runs `"$GODOT" --headless --path <checkout> -s res://tests/<suite>.gd`,
writes `validate_logs/<suite>.log` (git-ignored) and applies the CI rule: FAIL if
the exit code is non-zero, any `SCRIPT ERROR` / `Parse Error` /
`Failed to load script` diagnostic appears (only m43_c005f's documented injected
`explode` line is tolerated), the last PASS/FAIL/RESULT line lacks PASS or contains
FAIL, or a guarded exact summary line is missing. It prints
`<suite> status=PASS|FAIL exit=N diag=N | <last line>` per suite and
`aggregate=PASS|FAIL (p/total)`; exit 0 only when every selected suite passed.

The runner is Python 3 stdlib (not PowerShell or bash) so the same workflow
parser runs on Windows and on the Linux CI image.

## Result labels

- `LOCAL_PASS`: suites passed through `run_suites.py` or a direct headless run on a
  local machine. Always state the commit SHA and the suites (or `aggregate=PASS (p/total)`).
- CI result: cite the GitHub Actions run id and job, e.g. `CI run 39828088266 validate success`.
- Never write a CI label for a local run, or PASS for a suite that was not run.

## Saves and user data

Never touch the owner's real `user://` save or settings. Tests that need a save
use a throw-away path (e.g. `user://m40_<tag>_<usec>.save`, see
`tests/m40_save_system.gd`), pass it to the service explicitly, and delete it at
the end. Do not boot `scenes/app/main.tscn` from a test without such a save
override.

## Performance output

- Assertions must be deterministic: counts, states, structure, bounded work.
  Never assert a millisecond threshold or frame time.
- Timing/benchmark numbers are diagnostics only. Print them on lines starting with
  `PERF` and keep them out of PASS/FAIL decisions (do not put `PASS`/`FAIL` on a
  `PERF` line).
- `tests/m46_performance.gd` is the dedicated performance suite; put new
  structural perf guards there or in a similar dedicated suite.

## Regression gate

A milestone or task is not closed until the full `python tools/run_suites.py`
aggregate is PASS (or the CI `validate` job is green) at the closing SHA. Record
the evidence (SHA plus `aggregate=PASS (p/total)` or the Actions run id) in the
task's evidence file / build.md and in its `TASKS.md` entry.
