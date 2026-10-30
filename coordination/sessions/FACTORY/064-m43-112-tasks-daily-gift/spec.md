# M43 Tasks / Daily / Gift Bar verify-close (SB-M43-112..121)

> Feature: Queue rows SB-M43-112..117 (TASKS destination with 3 tasks 75/100/125 SB, exactly-once claims, DAILY destination and visual master) and SB-M43-118..121 (Gift Bar claim/history, Gift Bar visual master, no recursive feed, rollover/rollback/duplicate-tap tests).

## Context
Already built; this is a verify-close job (pattern of jobs 057-063). No production code change is expected.
- Suite `tests/m43_master_c009_daily.gd` header says it covers SB-M43-112..121 + R09-001..006. Run locally in this worktree it prints `M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)`. The case ledger (`EXPECTED_CASES`) covers: t01 Tasks destination, three orders, 75/100/125 SB labels from config; t04 per-task claim exactly once (+75 once, facade re-claim refused); t05 ScrubBox (3/3 -> one booster charge once); t06 Daily consecutive count, D1..D5 states and rewards from `data/config/economy_rewards_v1.json`; t07 local-day rollover, missed-day reset, clock rollback (no duplicate login/task claim); t08 Gift Bar claim + history, Gift Meter unchanged (non-recursive), no re-grant, Gift rollover keeps history; t12 duplicate taps never double-grant.
- Implementation: `scripts/ui/daily/daily_screens.gd`, `scripts/economy/daily_orders.gd`, `scripts/economy/gift_meter_service.gd`, `scripts/economy/production_action_facade.gd` (claims go through the facade/services, never UI mutation).
- CI: `.github/workflows/android-family-first10.yml` validate loop (line ~116) already runs `m43_master_c009_daily` (56 suites total), but there is NO exact-summary guard for it (compare the C008 guard near line 223). Header comment list at lines ~39-40 records each job's additions.
- Visual-master rows (113, 116, 119): no new art; the screens use existing promoted assets plus native Controls; owner visual approval is given by CLAUDE.md §0D.1 (same closure wording as SB-M43-080..083).

## Requirements
1. Re-run `m43_master_c009_daily` and confirm the exact 12/12 summary line; if it fails, fix only the real regression.
2. Add an exact-summary guard to the CI validate step, directly after the C008 guard, in the existing style:
   `grep -qxF 'M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)' validate_logs/m43_master_c009_daily.log` -> `M43-C009 verdict=PASS (12/12)`, else `M43-C009 verdict=FAIL (exact 12/12 summary missing)` and `fail=1`.
3. Do not add a duplicate suite entry: the validate list stays at 56 suites (c009_daily is already in it). Add a header comment line "SB-M43-112..121 Tasks/Daily/Gift Bar: m43_master_c009_daily already in list (56 total), + exact 12/12 guard."
4. Only if a requirement text is genuinely uncovered after reading the suite, add a focused assertion to c009 and bump nothing else. Pre-check found none: 75/100/125, 3/3 booster once, D1-D5 + consecutive count, claimed/today/future states (t06), history/non-recursive (t08), rollover/missed/rollback/duplicate (t07, t12) are all asserted. If a case is added, update the CI guard string to match.
5. In `TASKS.md`: tick `[x]` SB-M43-112..121 (rows at lines ~1176-1185) with evidence in the repo's wording ("DONE factory 064 verify-close: LOCAL_PASS m43_master_c009_daily 12/12; already in CI validate with new exact guard; visual master given by CLAUDE.md 0D.1, no new art; CLAUDE_PEER_REVIEW ..."); remove/update the two READY lines (58-59) per queue convention; do not claim CI green until a real run id exists.
6. Update AGENTS.md or docs only if they list the CI validate guards (grep for "m43_master_c008_robots" in docs/AGENTS.md and mirror if present).

## Acceptance criteria
1. `"C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path C:/Users/sekip/AppData/Local/ScrubBotsFactoryWT/064-m43-112-tasks-daily-gift -s res://tests/m43_master_c009_daily.gd` prints exactly `M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)` (run takes >2 min; use a long timeout or background).
2. `grep -n "M43 master C009 Tasks / Daily / Gift evidence: PASS (12/12 cases, 0 fail)" .github/workflows/android-family-first10.yml` finds the guard; `grep -c "m43_master_c009_daily" ` on the validate loop still shows a single list entry (no duplicate); suite count remains 56.
3. Workflow YAML still parses (`python -I -c "import yaml,sys;yaml.safe_load(open('.github/workflows/android-family-first10.yml'))"`) and `git diff --check` is clean.
4. `TASKS.md` rows SB-M43-112..121 are `[x]` with the evidence wording above.
5. Changed files are limited to the workflow, TASKS.md, (optionally docs list) and, only if a gap was found, `tests/m43_master_c009_daily.gd`. No change under `scripts/` or `assets/`.
6. Perf timings are not asserted locally; GitHub CI (validate job on the pushed branch) is the arbiter and must show `M43-C009 verdict=PASS (12/12)` and aggregate PASS.

## Out of scope
New art or visual masters; new reward mechanics; changing 75/100/125, D1-D5 or Gift milestone values; touching other suites (c010, c011_c014 are later rows); economy changes from UI; store/release work.

## Assumptions
- c009 already satisfies all ten rows, so verify-close is correct (evidence: 12/12 local pass, header scope).
- Visual-master rows close under CLAUDE.md §0D.1 with existing assets, matching prior jobs 060-063.
- The 56 count stays because the suite is already registered; only the guard is new.
