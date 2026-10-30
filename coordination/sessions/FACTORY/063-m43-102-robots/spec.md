# M43 Robots destination: verify-close SB-M43-102..111

> Feature: Queue rows SB-M43-102..106 (ROBOTS destination, visual master, lock state + Bot Parts N/250, perk display, select/equip persistence) and SB-M43-107..111 (locked robot detail, active-robot presentation, no gameplay mutation, unlock history/NEW badge, 10-robot check).

## Context
Already built (lane C008): `scripts/ui/robots/robots_screen.gd`, `scripts/progression/robot_roster.gd`, economy robots service, Home/HUD/support/Results presentation, robot-unlock ceremony. Suite `tests/m43_master_c008_robots.gd` runs 10 cases (r01..r10) and prints `M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)`. Locally verified PASS in the worktree. It maps to the rows:
- 102 r01 nav; 104 r02 states/Bot Parts N/250/overflow; 105 r03 perk is 20% meta, no puzzle-power copy; 106 r04 equip + persistence via a reloaded AppState; 107 r05 locked detail (required parts, preview, perk, earned-only, no purchase path); 108 r06; 109 r07 (no forbidden gameplay identifiers in robot files, only the `robots` save section changes on equip); 110 r08 (ceremony once, NEW cleared once seen, legacy saves not flooded); 111 r09 (10 robots at 1080x2160 and 720x1280) and r10 (missing asset falls back to Scrubby).
- 103 visual master: no new art; given by CLAUDE.md 0D.1 using promoted existing robot assets (`RobotRoster` `assets.master`).

The suite is NOT in the CI validate list in `.github/workflows/android-family-first10.yml` (currently 55 suites, loop at lines ~108-121, exact-summary guards at ~187-220). Rows 102..111 are unticked in `TASKS.md`.

Decision: all 10 rows are verify-close. No code changes. Gap review found no uncovered requirement, so no new assertions.

## Requirements
1. Add `m43_master_c008_robots` to the suite loop in `.github/workflows/android-family-first10.yml` (56 total) and add an exact-summary guard in the same style as the C007 one: `grep -qxF 'M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)' validate_logs/m43_master_c008_robots.log`, printing `M43-C008 verdict=PASS (10/10)` or FAIL with `fail=1`. Update the suite-count header comment (add a `SB-M43-102..111 Robots` line; "56 total").
2. Tick `[x]` SB-M43-102..111 in `TASKS.md` with a DONE note (factory 063 verify-close, LOCAL_PASS 10/10, CI list 56 suites, CLAUDE_PEER_REVIEW label only after review actually happens). Change the READY queue lines 57-58 to DONE in the same format as the SB-M43-090..101 line. Note 103 as satisfied by CLAUDE.md 0D.1 with no new art.
3. Add `tests/m43_master_c008_robots.gd` to any pack/suite inventory that lists C007 (grep for `m43_master_c007_collection` in `tools/`, `docs/`; the only known hits are the workflow and docs/07 prose, so likely nothing more).

## Acceptance criteria
1. `"C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path <worktree> -s res://tests/m43_master_c008_robots.gd` prints exactly `M43 master C008 Robots evidence: PASS (10/10 cases, 0 fail)` (the trailing ObjectDB leak warnings are pre-existing and fine).
2. `grep -c m43_master_c008_robots .github/workflows/android-family-first10.yml` is at least 2 (loop and guard); the guard line text equals the suite's summary line byte for byte; the workflow YAML still parses (`python -c "import yaml,sys;yaml.safe_load(open('.github/workflows/android-family-first10.yml'))"`).
3. `grep -n "SB-M43-10[2-9]\|SB-M43-11[01]" TASKS.md` shows rows 102..111 as `[x]` with evidence notes and the queue lines no longer READY.
4. `python tools/run_suites.py` shows no new failures versus main. `m46_performance` or other perf-budget misses from local load are not blockers; GitHub CI is the arbiter.
5. `git diff --check` is clean and the changed set is limited to the workflow, TASKS.md and the job folder.

## Out of scope
New art or asset generation, changing robot roster, perks, unlock costs or Bot Parts rules, any gameplay change (CLAUDE.md section 10), a Bot Parts purchase path, new NEW-badge mechanisms, edits to the suite beyond what a real failure demands, other TASKS rows.

## Assumptions
- Existing 10 cases already assert every row's requirement, so verify-close with no new assertions (matches jobs 057-061 pattern).
- Visual master (103) is closed by CLAUDE.md 0D.1 owner sign-off plus use of existing promoted robot assets.
- The NEW badge here uses the robot-specific seen mark covered by r08; factory 055's generic mechanism need not be touched.
