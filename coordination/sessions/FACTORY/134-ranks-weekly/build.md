STATUS: READY

# Build: RANKS two tables (SB-M43-131..133)

## Summary
The RANKS screen now has two tabs, following the owner decision of 2026-10-22. There is no server.
- ALL-TIME (the default tab) shows "Highest level reached: N" (N = `progression.current_level()`, the frontier) and a "You" row with "Level N". The existing personal ladder sits under them (current rank, levels cleared, next-tier meter, tiers).
- WEEKLY shows the week window "This week: YYYY-MM-DD – YYYY-MM-DD (UTC)" (Monday to Sunday), "Levels completed this week: N", a "You" row and "Resets every Monday at 00:00 UTC."
- Both tabs show the note "Online ranks with other players are coming with Google Play Games and Game Center." No fake players are shown. The only identity shown is "You" ("Sen" in Turkish).
- Counting rule (written into coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md): +1 for each committed campaign WON. The hook is the gameplay host `_meta_terminal(true)`, which runs only after FirstClearTransaction commits the frontier first-clear. Losses, Retry, disabled-level skips, Scrub Bucks, Hearts, booster purchases and booster use add nothing. A level won with boosters counts once. The game has no replay path, so each level counts at most once.
- Week: Monday 00:00:00 UTC to the next Monday (exclusive), computed as `ts - posmod(ts - 4*86400, 7*86400)`.
- Clock rollback: a win dated before the stored week is neither counted nor allowed to rewrite the stored week. The tab shows 0 while the clock is behind and the stored count again once the clock returns to that week.
- The economy save has a new `ranks` section: `{version 1, week_start, count}`. Import is strict: an absent section means fresh; a malformed one fails the whole economy import, which rolls back.
- Analytics: opening the screen sends `ranks_view {table: all_time}`. Each tab switch sends `ranks_view {table: weekly}` or `{table: all_time}`. `band` is the personal rank tier on either table.
- Ranks still unlock at L40 (unchanged).
- Layout fix: right-side labels in a row (the ladder "REACHED / YOUR RANK" and the You-row value) had autowrap on and wrapped one character per line. Main had the same defect in the ladder. Autowrap is now off for them, and the tab text has no outline.

Files changed:
- new: scripts/progression/weekly_ranks.gd, tests/m43_ranks_weekly.gd
- scripts/economy/economy_services.gd (`ranks` service + section)
- scripts/gameplay/runtime/production_gameplay_host.gd (one hook in `_meta_terminal`)
- scripts/ui/profile/profile_screens.gd (`open_ranks` tabs, `_you_row`)
- scripts/ui/ui_text.gd and ui_text_tr.gd (11 EN keys / 10 TR keys)
- tests/m56_analytics_taxonomy.gd (asserts the weekly `ranks_view`)
- .github/workflows/android-family-first10.yml (m43_ranks_weekly added to validate, exact 7/7 guard)
- coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md, docs/ANALYTICS_TAXONOMY_V1.md, docs/PRIVACY_DATA_INVENTORY.md, TASKS.md

Commits: ee76a2f8 (code + tests), 75c12e1c (docs/tasks). Not pushed.

## Acceptance criteria
1. [x] All-time = highest campaign level reached. m43_ranks_weekly r06/r07 assert "Highest level reached: 4" and the You row "Level 4" on the real app root after real wins.
2. [x] Weekly = levels completed in the UTC week, resetting Monday 00:00 UTC. r01: week_start at Mon 00:00:00, at Sun 23:59:59 (previous week) and at the next Mon 00:00:00, plus 500 random timestamps, all landing on a Monday 00:00:00 UTC within 7 days. r02: 3 Thursday wins + 1 at Sun 23:59:59 = 4; at Mon 00:00:00 the count is 0 with the new window, and the next win makes it 1. r07: on the screen after the boundary, the window reads 2026-11-16 – 2026-11-22 and the count is 0.
3. [x] Clock rollback is safe (r03): a win with the clock set to the previous Sunday is not counted, the tab shows 0 and the stored week is kept. Back in this week the count is 2 again, not double counted.
4. [x] Only completed levels count; money and boosters add nothing (r05, real app root, throw-away save). SB credit, Heart purchase and Tornado purchase leave it at 0. LOST leaves it at 0. A WON with the purchased Tornado used (1 committed booster action) gives exactly 1. A second WON gives 2. After a reboot on the same save it is still 2, with frontier 4.
5. [x] Persistence and strict import (r04): a valid snapshot and integral JSON floats are accepted. 12 malformed sections are refused with state kept. An absent section means fresh. EconomyServices carries `ranks`, and an old save without it imports. A bad `ranks` section fails the aggregate import with nothing applied.
6. [x] Tabs render in EN and TR (r06): tab labels, ALL-TIME selected by default, the WEEKLY switch, window, count, You row, reset line, offline note, no unformatted `%s`, Turkish copy shown, and switching back. Screenshots were checked by eye: EN all-time and TR weekly at 1080x2160 and 1080x1920 (throw-away capture script, deleted, not committed).
7. [x] Analytics `ranks_view` table weekly is sent: r06 gets all_time / weekly / all_time per language, and m56 `ranks_view` now asserts `[{all_time, 1}, {weekly, 1}]`.
8. [x] Unlock stays L40: m43_personal_ranks p06 and m44_unlock_gate pass.
9. [x] SB-M43-133 visual master is left OWNER with a note and is not claimed.
10. [ ] m60 release gate 005 re-run: SKIPPED. tests/m60_release_gates.gd exists only on factory/132-release-gates-audit and is not on main. Its gate looks for `AllTime*` and `Weekly*` nodes, which this screen provides (AllTimeTab/AllTimeTable, WeeklyTab/WeeklyTable). After 132 merges, run `tests/m60_release_gates.gd -- --write`.

## Validation
Godot 4.7.2 console, headless, all LOCAL_PASS (exit 0, no SCRIPT ERROR / Parse Error):
- m43_ranks_weekly 7/7 (new; re-run after the layout fix)
- m43_personal_ranks 8/8 (re-run after the layout fix)
- m51_localization_readiness 8/8 (re-run after the layout fix)
- m50_accessibility_audit 8/8
- m56_analytics_taxonomy 27/27
- m58_privacy_inventory 7/7
- m44_unlock_gate 6/6
- m44_new_badge 7/7
- m43_master_c010_meta 12/12
- m54_regression_pack_028_036 12/12
- m39_v04_integration PASS

`git diff --cached --check` was clean on both commits. I ran `--import` once. project.godot, the .import EOL churn, the generated .uid files and the .translation files were restored or removed, and the tree is clean. No CI run and no phone build.

## Log
### Round 1
- Implemented WeeklyRanks, the economy section, the host hook, the two-tab RANKS screen, EN/TR copy, the analytics tab switch, docs, the CI validate entry and TASKS rows (131/132 DONE, 133 OWNER).
- Visual check found the per-character wrap of right-side row labels (also present on main for the ladder state) and the tab outline. Both fixed and re-verified.
- The m60 gate 005 re-run was skipped because m60 is not on main yet.
