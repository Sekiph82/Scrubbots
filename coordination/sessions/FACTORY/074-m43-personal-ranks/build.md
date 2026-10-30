STATUS: READY

# Build: Personal Ranks destination

## Summary
The RANKS BottomNav tab (nav id `leaderboard`) is now a live destination. It opens the player's personal rank ladder: Bronze 0 / Silver 25 / Gold 75 / Platinum 150 / Diamond 300 / Master 500 campaign levels cleared (`progression.completed_count()`). The rank is worked out each time the screen opens and is never saved. There is no server, no other players and no rewards. The L40 unlock gate is unchanged.

Commits on `factory/074-m43-personal-ranks`: `7f208789` (code + tests + CI list), `dd60fd76` (docs + TASKS.md).

Files changed:
- `data/config/personal_ranks_v1.json` (new): schema, version 1, metric `campaign_levels_cleared`, 6 tiers.
- `scripts/progression/personal_rank.gd` (new): static `load_tiers(path)` / `for_cleared(n, path)`. It fails closed: an invalid table gives `[]` / `{}`. It uses `JSON.new().parse`, so a corrupt file logs no engine error. On the top tier, `span` is 0, `next_id` is "", `next_min` is -1 and `into` is the number of levels past the top threshold.
- `scripts/ui/profile/profile_screens.gd`: `open_ranks(stack, app)` is a large BasePopup with `popup_id` "ranks". It has a `CurrentRank` label, a `Cleared` label, a `NextMeter` UiProgressMeter (caption is "N more levels to X" or the top-rank line, bar full at top) and a `Ladder` of `Tier_<id>` cards. The current tier has a gold card, reached tiers carry meta `reached`/`current`, and unreached tiers are dimmed. Also a `SelfOnly` line and a `close` action. No new art.
- `scripts/ui/ui_text.gd`: `RANKS_*` and `RANK_*` keys.
- `scripts/app/main.gd`: `APP_NAV := ["events", "leaderboard"]` (comment updated) and a `"leaderboard"` case in `_on_home_nav`.
- `tests/m43_personal_ranks.gd` (new, 8 cases); `tests/m43_master_c010_meta.gd` m01/m11; `tests/m44_unlock_gate.gd` (L40 and established-save rows).
- `.github/workflows/android-family-first10.yml`: adds `m43_personal_ranks` to the validate loop (62 suites) with an exact 8/8 guard.
- `coordination/OWNER_META_NAVIGATION_AND_DESTINATIONS_V01.md` §3, `AGENTS.md` (new "Personal ranks" section, because AGENTS.md lists per-feature configs), `TASKS.md` (queue row at line 59, SB-M43-122 checklist entry, SB-M58-012 note).

## Acceptance criteria
1. [x] New suite: `$GODOT --headless --path . -s res://tests/m43_personal_ranks.gd` gave exit 0, diag 0, last line `M43 personal ranks evidence: PASS (8/8 cases, 0 fail)`, with a printed line per case.
2. [x] Data: p01 shows schema/version/metric, 6 tiers strictly ascending with the first at 0, and every tier name a UiText key. p02 runs 10 bad tables (unsorted, first not 0, duplicate id, fractional min, string min, wrong metric, wrong schema, empty tiers, invalid JSON, missing file). Each one makes `load_tiers` return `[]` and `for_cleared` return `{}`, with no crash.
3. [x] `for_cleared` (p03): 0 gives bronze with into 0 and span 25. Every exact threshold gives that tier with into 0. Every threshold-1 gives the previous tier with into = span-1. 100000 gives master with next_id "" and next_min -1. -5 gives the same result as 0.
4. [x] Real app root (p04, grandfathered test save): `Nav_leaderboard` is enabled with tooltip "". `pressed` puts popup "ranks" on top. Closing leaves depth 0 and the route on HOME. p06 also covers an FTUE profile walked to L40: the tab is enabled with no tooltip and a press opens "ranks".
5. [x] Screen matches the save (p05, named labels):
   - n=0: "Your rank: Bronze", "25 more levels to Silver".
   - n=27: "Your rank: Silver", "48 more levels to Gold".
   - n=500: "Your rank: Master", "Top rank reached!", bar ratio 1.0.
   - At every n, the reached/current meta on each tier card matches `for_cleared(n)`.
6. [x] Fresh FTUE profile at L1 (p06): `Nav_leaderboard` is disabled and its tooltip is `HOME_UNLOCKS_AT_LEVEL` [40].
7. [x] Read-only (p07): `economy.snapshot()`, `completed_count()` and `current_level()` are identical before and after opening and closing the screen.
8. [x] No network (p08): neither `personal_rank.gd` nor the `open_ranks` body contains `HTTPRequest`, `leaderboard_score`, `ranking`, `http` or `friend`. c010 m11 now also scans `personal_rank.gd` for `httprequest` and `player_id`, and checks that the config has only schema/version/source/metric/tiers. c010 m09 (no `leaderboard`/`http`/`friend` in profile_screens.gd) still passes.
9. [x] Regressions:
   - `m43_master_c010_meta`: PASS 12/12.
   - `m44_unlock_gate`: PASS 6/6.
   - `m42_home_v04`: exit 0, 0 SCRIPT/Parse errors, final line `m42_home_v04: 18/18 cases, 0 failures`.
   - `m42_navigation`: PASS.
   - Extra: `m51_localization_readiness` PASS 4/4 (new UiText keys).
10. [x] `git diff --check 6a8643c7..HEAD` is clean. The coordination doc §3 now carries the personal-ladder policy. TASKS.md closes SB-M43-122 with evidence and adds the SB-M58-012 note.

## Validation
- `python tools/run_suites.py m43_personal_ranks m43_master_c010_meta m44_unlock_gate m42_navigation m51_localization_readiness`: every suite PASS with exit 0 and diag 0. The first run had m44_unlock_gate FAIL, which was fixed (see Log). After the fix, `python tools/run_suites.py m44_unlock_gate` passed 6/6.
- `$GODOT --headless --path . -s res://tests/m42_home_v04.gd`: exit 0, 18/18, 0 failures. It ran directly because it is not in the workflow list.
- `python tools/run_suites.py --selftest`: PASS.
- `git diff --check`: clean.
- Results are LOCAL_PASS on Godot 4.7.2 headless. No CI run was made.

## Log
### Round 1
- Implemented spec requirements 1-9 as above.
- Deviation from the spec context: the spec said `m44_unlock_gate` L145 "stays true". It doesn't. That suite's standalone Home calls `home.set_app_nav(MainScript.APP_NAV)`, so it reflects the app root's served tabs, and RANKS is now enabled at L40 and on established saves. I updated those two assertions to the new truth: all 7 entries enabled, RANKS tooltip "". The L1 locked assertions are unchanged.
- Top-tier semantics: `span` is 0 rather than a fake 1/1, so "exact threshold -> into 0" holds for every tier, including the top one. The UI fills the bar on the top rank.
- `open_deep_link` is unchanged: `NotificationPolicy.deep_link` has no ranks destination, and the spec does not ask for one.
- Workspace: the worktree still has import churn that I did not commit: `project.godot`, `*.import`, untracked `*.uid` (including `personal_rank.gd.uid` / `m43_personal_ranks.gd.uid`, which are untracked like their siblings), and `validate_logs/`. Every job file is committed.
