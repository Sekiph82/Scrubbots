# Close R05 / 013 into CI, build robot + feature unlock feel (MAJOR_UNLOCK)

> Feature: Factory job 059-m43-r05-gift-ticks-handoff. Three related queue rows in one job: SB-M43-R05-001..002 (Gift Meter presentational micro-progress ticks from one GiftMeterService progress model), SB-M43-013 (Results hands off to the M43-C005 robot/collection/feature ceremony after the reward commit), SB-M43-C005F-007 (robot/feature unlock feel with MAJOR_UNLOCK ceiling, after M43-070..072; world part stays gated).

Worktree: `C:/Users/sekip/Desktop/ScrubBots-factory/059-m43-r05-gift-ticks-handoff`
GODOT = `C:/Users/sekip/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`

## Context (what already exists - determined by reading the worktree)

| Task | State | Evidence |
|---|---|---|
| SB-M43-R05-001..002 | BUILT. Commit 671615be. `scripts/economy/gift_progress_model.gd` (one model, `from_service`/`build`), `scripts/ui/components/gift_tick_overlay.gd`; consumed by `home_screen.gd`, `results_screen.gd`, `daily_screens.gd`. Suite `tests/m43_master_c005r_gift_micro_progress.gd` (8 cases g01..g08). NOT in the CI `validate` list. TASKS.md box still `[ ]`. | verify-close |
| SB-M43-013 | BUILT. Commit 46e50fd1. `main.gd` `_begin_results_ceremonies` / `_drain_results_ceremonies` / `RESULTS_CEREMONY_BARRIER`, `ResultsScreen.set_ceremony_barrier`, `CeremonyPresenter.drain("results")`. Covered by `tests/m43_master_c005_meta_ceremonies.gd` cases e27, e28 (32 cases e01..e32). NOT in the CI list. TASKS.md box still `[ ]`. | verify-close |
| SB-M43-C005F-007 | GAP. `scripts/ui/feel/meta_reward_feel.gd` `_on_ceremony_shown` maps only set_complete, master_complete, gift_milestone. `robot_unlock` and `feature_unlock` ceremonies (`meta_ceremonies.gd`, kinds "robot_unlock"/"feature_unlock", HeroArt node) get no GameFeelFlow/Spark feel. `FeedbackAdapter` already has the `MAJOR_UNLOCK` intent (ceiling 24 particles, 1.3 s, REDUCED = none) and `tests/m43_master_c005f_feel.gd` proves the table. | build |

Pattern to reuse: `meta_reward_feel.gd` `_play(child, intent, hero, key)` with a canonical one-shot key (`c005f006:<key>` style); extend the header table comment. Idempotency key comes from the ceremony key (`unlock:<feature_id>` for features, the robot event key for robots), so refresh/equip/re-drain cannot replay.

## Requirements

1. In `meta_reward_feel.gd` `_on_ceremony_shown`, add `robot_unlock` and `feature_unlock` -> `_play("F007", "MAJOR_UNLOCK", hero, "c005f007:" + key)` on the ceremony HeroArt. Add the two rows to the header table comment.
2. FULL adds no new mechanism beyond the existing adapter (punch_scale + capped confetti within the MAJOR_UNLOCK ceiling) and, if the existing `SETTLE` pattern is used, a `MAJOR_UNLOCK` settle no larger than the adapter's ~1.12 peak. No camera manipulation, no strobing flash, no loop/spin.
3. REDUCED: zero plugin work (adapter already returns nothing); popup content and actions unchanged.
4. Presentation only: no grant, spend, equip, claim, save or navigation from the feel code; the Equip/Keep choice (`ceremony_presenter.gd` `equip_robot`) and feature-unlock truth (`AppState.feature_unlocked`) are untouched.
5. World unlock: NOT implemented. `world_transition` is not mapped to any intent. TASKS.md C005F-007 keeps a "world part gated" note.
6. SB-M43-R05-001..002 and SB-M43-013: no source change; only CI wiring, doc/TASKS evidence (below). If their suites fail, fix the real defect minimally.
7. New suite `tests/m43_c005f_phase6_unlock_feel.gd` with an EXPECTED_CASES ledger (pattern: `m43_c005f_phase3_meta_rewards_acquisition.gd`, spy gff/spark backends, real `main.tscn`), cases:
   `u01_robot_major_unlock_once`, `u02_feature_major_unlock_once`, `u03_reduced_zero_plugin_work`, `u04_ceiling_not_exceeded` (particles <= 24, duration <= 1.3 s, one particle group at a time), `u05_no_replay_refresh_equip_redrain`, `u06_truth_unchanged` (wallet, robot roster/equipped id, feature unlock state, reward-applied ledger identical before/after the feel), `u07_world_not_mapped`, `u08_static_boundary` (meta_reward_feel.gd source has no grant/spend/save/equip calls for the new branches).
   Final line: `M43 C005F phase6 unlock feel evidence: PASS (8/8 cases, 0 fail)`.
8. CI (`.github/workflows/android-family-first10.yml`, `validate` job): append to the `for s in` list `m43_master_c005r_gift_micro_progress`, `m43_master_c005_meta_ceremonies`, `m43_c005f_phase6_unlock_feel` (suite count 49 -> 52), add exact-summary guards in the existing style (see the 074/077 guard at ~line 181) for:
   - `M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)`
   - `M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)`
   - `M43 C005F phase6 unlock feel evidence: PASS (8/8 cases, 0 fail)`
   and a header comment line "SB-M43-R05-001/002, SB-M43-013, SB-M43-C005F-007: + 3 suites (52 total ...)". `tools/run_suites.py` reads the list/guards from this file; do not edit it.
8b. Docs: update `TASKS.md` (tick R05-001..002 and SB-M43-013 with LOCAL_PASS evidence; tick C005F-007 for robot + feature with a note "world part gated, not implemented"; update the queue block rows accordingly), and mention the new suite/count in `AGENTS.md`/`docs/TESTING_CONVENTIONS.md` only where they list the CI suite count or suites.

## Acceptance criteria

1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c005r_gift_micro_progress.gd` prints `M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)`.
2. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c005_meta_ceremonies.gd` prints `M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)` (includes e27/e28 Results handoff).
3. `"$GODOT" --headless --path <worktree> -s res://tests/m43_c005f_phase6_unlock_feel.gd` prints `M43 C005F phase6 unlock feel evidence: PASS (8/8 cases, 0 fail)`.
4. `"$GODOT" --headless --path <worktree> -s res://tests/m43_master_c005f_feel.gd` and `.../m43_c005f_phase3_meta_rewards_acquisition.gd` still PASS (ceilings table and F006/F008 unchanged).
5. `grep -c "MAJOR_UNLOCK" scripts/ui/feel/meta_reward_feel.gd` >= 2 and `grep -n "world" scripts/ui/feel/meta_reward_feel.gd` shows no intent mapping for world.
6. The workflow `for s in` list contains the 3 new suites and three exact-summary guards exist; `python tools/run_suites.py` runs 52 suites and exits 0 (all PASS, guards satisfied).
7. `git diff --check` clean; changed files limited to `meta_reward_feel.gd`, the new test (+ .uid), the workflow, `TASKS.md`, doc count mentions.
8. TASKS.md R05-001, R05-002, SB-M43-013 are `[x]` with LOCAL_PASS evidence; C005F-007 is `[x]` (robot + feature) with the world-gated note, or stays READY with a stated reason.

## Out of scope

- World / map unlock ceremony feel or any world mapping (gated).
- New art, new particles/presets, new popup layouts, new intents or ceiling changes.
- Any grant/equip/save/navigation change; changing Gift Meter thresholds or the R05 model.
- Rewriting the existing R05 / Results handoff code.
- Owner visual gate / independent audit claims (record only `CLAUDE_PEER_REVIEW` if a reviewer ran).

## Assumptions

- R05 and 013 are verify-close because their code and suites already exist on this branch (commits 671615be, 46e50fd1); only CI wiring and ticking are missing.
- Feature unlock uses the same MAJOR_UNLOCK intent as robot: the TASKS row names "robot/feature unlock" under the single ceiling; reduced/idempotency come free from the adapter.
- Key scheme `c005f007:<ceremony key>` mirrors F006/F008 conventions.
- If the existing robot/feature popup lacks a `HeroArt` node, the feel falls back to no work (like other children) and u01/u02 must then use the actual hero node name via `_hero()`; builder should rename nothing in popups, only resolve the existing hero node.
