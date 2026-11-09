STATUS: READY

# Build: WON terminal tick perf (m46_rm005 T4 back under 60 ms)

## Summary
The time went to `CeremonyPresenter.pending()`. `main._begin_results_ceremonies()` calls it on the WON -> Results route change, inside the terminal tick. To decide whether each pending ceremony could be shown, it built the full popup with `MetaCeremonies.build()` (textures, video hero, layout nodes) and then freed it. On the warm L1 win that took 60-79 ms. The fix adds `MetaCeremonies.presentable(event)`, which runs the same refusal checks as the builders (unknown kind, non-roster robot, uncatalogued card, missing name/title or missing icon/art) without building any UI. `build()` now checks it first, so the refusal rules live in one place. `pending()` filters with `presentable()`. Behaviour is the same: the same events are pending, and the popup is still built once, when the ceremony is drained on a later frame. The economy and progression transaction and its save are untouched, and the 60 ms budget is unchanged.

Files changed:
- `scripts/ui/ceremony/meta_ceremonies.gd`: new `presentable()` and `_named_art()`; `build()` checks `presentable()` first
- `scripts/ui/ceremony/ceremony_presenter.gd`: `pending()` uses `presentable()` and no longer builds and frees popups
- `tests/m43_master_c005_meta_ceremonies.gd`: new case e33. For 14 events covering every kind, valid and refused, `presentable(e) == (build(e) != null)`, with 7 presentable
- `TASKS.md`: new queue row `DONE SB-M46-RM005-T4`

Commits: 45639202 (fix + test), 4e2580ce (TASKS.md). Not pushed.

## Profiling (scratch instrumentation in main.gd, reverted, not committed)
I timed with `Time.get_ticks_usec` and collected the results into a static array. Printing inline added about 10 ms per print and doubled the numbers. The first 'before' rows are from the instrumented run made just before the fix; the last row is the fixed code with the same instrumentation still in place.

| piece of the main.gd terminal lambda | before warm | before cold | after warm | after cold |
|---|---|---|---|---|
| reconcile_disabled_frontier | 0.01 | 0.01 | 0.01 | 0.01 |
| _track screen_view | 0.01 | 0.01 | 0.01 | 0.01 |
| _results_model (resolver + momentum) | 2.0 | 2.3 | 2.4 | 2.3 |
| _results.show_model | 23.0 | 51.5 | 25.4 | 55.7 |
| _track_results_momentum (analytics) | 0.05 | 0.06 | 0.05 | 0.07 |
| _begin_results_ceremonies (pending()) | **79.0** | **60.4** | **0.14** | **0.15** |
| ftue.settle + refresh_coachmark | 0.03 | 0.03 | 0.02 | 0.02 |
| _terminal_bridge | 0.03 | 0.03 | 0.03 | 0.03 |
| whole nav.on_gameplay_terminal | 104.3 | 114.4 | 28.1 | 58.3 |

None of the other suspects were the cause. Terminal saves, ads counter and cloud bookkeeping all sit in the host handler, which takes 6-11 ms in total. Analytics costs under 0.1 ms, and the featured-card, achievement and FTUE checks under 0.2 ms. There is no JSON stringify or file write in the lambda.

Cost left in the warm tick after the fix: Results `show_model` about 23-25 ms (55 ms cold), host economy + save terminal handler about 10 ms, `_results_model` about 2.4 ms. I left `show_model` alone because the budget is met.

## Acceptance criteria
1. [x] Profile the WON terminal path piece by piece: see the table above (scratch copy, reverted with `cp` from a backup; `git diff` of `scripts/app/main.gd` is empty).
2. [x] Fix the real cause with a minimal, behaviour-preserving change: the per-tick popup construction in `pending()` is gone; e33 shows `presentable` matches `build` on all kinds; m43_master_c005 33/33, c072 9/9, c074_c077 6/6, m44_featured_card_onboarding 8/8 (ceremony behaviour unchanged).
3. [x] Authoritative economy/progression save not moved, budget not raised: `TERMINAL_WARM_MAX_MS` is still 60.0, and the host terminal handler and main.gd are unchanged.
4. [x] m46_rm005_terminal_frame_profile warm tick <= 60 ms: before 108-124 ms FAIL (baseline run this job: warm 124.57, cold 125.35, `FAIL (1 fails) (4/5 groups)`). After: run 1 warm **35.31** / cold 62.31, run 2 warm **37.00** / cold 61.77, `M46 RM005 TERMINAL FRAME: PASS (5/5 groups)` both times.
5. [x] Permanent test for the new behaviour: `tests/m43_master_c005_meta_ceremonies.gd` e33, and T4 itself guards the timing.

## Validation
Godot 4.7.2 console exe, `--headless --path <wt> -s res://tests/<suite>.gd`, after a single `--import`. Every suite below exited with the code shown, printed no `SCRIPT ERROR` or `Parse Error`, and its last line is quoted. All LOCAL_PASS except m55.
- m46_rm005_terminal_frame_profile: exit 0, `PASS (5/5 groups)` (x2)
- m46_performance: exit 0, `PASS (22/22 cases, 0 fail)`
- m43_master_c005_meta_ceremonies: exit 0, `PASS (33/33 cases, 0 fail)`
- m43_c001a_results_foundation: exit 0, `PASS (11/11 cases, 0 fail)`
- m57_ads_cadence: exit 0, `PASS (6/6 cases, 0 fail)`
- m54_cloud_save_seam: exit 0, `PASS (7/7 cases, 0 fail)`
- m44_featured_card_onboarding: exit 0, `PASS (8/8 cases, 0 fail)`
- m40_save_system: exit 0, `PASS`
- m43_c005_c072_feature_unlock_ceremony: exit 0, `PASS (9/9 cases, 0 fail)`
- m43_c005_c074_c077_celebrations: exit 0, `PASS (6/6 cases, 0 fail)`
- m55_long_session: exit 1, `FAIL (2)`. Both failures are only "objects drift 72 > 64" (lap 2 vs lap 1 and steady state). This is the object-drift issue factory 144 is fixing in parallel. Static memory drift and node counts pass.
- `git diff --check` on the changed files: clean.

Cleanup: `git checkout -- .` restored the import-touched `.import` files and `project.godot`. I deleted the 1234 untracked files the import created (`.uid`, `.import`, `.translation`) one by one by path, without `git clean`. I also deleted the scratch suite `tests/zz_scratch_t4.gd` and the temp logs. `git status --porcelain` is empty.

## Log
### Round 1
- Baseline: T4 warm 124.57 ms, FAIL.
- Instrumented a scratch copy of the main.gd lambda and `_on_route_changed`. Found `_begin_results_ceremonies` -> `CeremonyPresenter.pending()` building every pending ceremony popup (60-79 ms), and Results `show_model` (23-55 ms).
- Fixed `pending()` with `MetaCeremonies.presentable()`. Warm tick is now 35-37 ms.
- Added e33 and a TASKS.md row. Ran the suites listed above.
