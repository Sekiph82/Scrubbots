STATUS: READY

# Build: SB-M54-037..038 presentation-plugin one-shot/fail-open regression + GFF/Spark runtime visual regression pack

## Summary
I mapped both rows onto the existing feel suites first, then added two gap suites: a fast headless one for 037 (now in CI) and a windowed rendered one for 038 (local only). The mapping turned up a real product bug: the first Results reward row's REWARD sparkle spawned 144 px above its row. That is fixed. Three stale local-only static guards were also failing. They were broken by the SB-M59 Credits licence paths, and I updated them.

Files changed (branch `factory/137-plugin-regressions`, not pushed):
- `scripts/ui/results_screen.gd`: the row feel waits for the row's own rect to settle. `_after_layout(f, watch)` gained an optional `watch` Control, and a new `_row_feel` re-checks the terminal identity before it plays. Row 0's reveal step starts inside `show_model()`, before the first layout pass, so the deferred burst used a stale rect (y 863 vs the row centre 1007 at 1080x2160). Rows 1..4 were already correct.
- `tests/m43_c005f_phase1_foundation.gd`, `tests/m43_c005f_phase3_meta_rewards_acquisition.gd`, `tests/m43_c005f_015_e2e_feel.gd`: the plugin-name static guards strip the two Credits licence file paths (`res://addons/game_feel_flow/LICENSE`, `res://addons/saltmire_spark/LICENSE.txt`) before they scan. These guards had been failing since 4222bbd7 (SB-M59 Credits).
- `tests/m54_regression_pack_037_038.gd` (new, 6 cases, about 75 s headless): the SB-M54-037 gap matrix.
- `tests/m54_visual_regression_038.gd` (new, 4 cases, windowed, about 1 min): the SB-M54-038 rendered pack. Under `--headless` it prints NOT_RUN and exits 1.
- `.github/workflows/android-family-first10.yml`: header line, the 037 suite appended to the validate list, the exact guard `M54 regression pack 037-038: PASS (6/6 cases, 0 fail)`, and the suite added to the documented injected `explode` exception (same rule as phase4).
- `tools/run_suites.py`: `INJECTED_SUITES` mirrors that exception. `docs/TESTING_CONVENTIONS.md` has a one-line note.
- `TASKS.md`: queue line set to DONE, and the 037/038 checklist rows marked [x] with their coverage.

Commits: `968a5391` (Results fix + guards), `a7a59e27` (suites + CI), `512c2ef3` (docs/tasks).

## Coverage map (row requirement -> existing assertions -> gap filled)
| Requirement | Already covered by | New |
|---|---|---|
| 037 Results `show_model()` / attempt key | phase2 w01..w03 (one WIN per attempt; re-show, resize, barrier and Continue re-arm replay nothing; a new attempt plays once), w06 (Reduced consumes the keys) | m037: in the real app, after a real L1 WON, route re-show + `show_model` x2 + resize add 0 requests, in all 5 arms |
| 037 reward rows | phase2 r01..r05 (one REWARD per row, refresh replays none, Reduced static, bounded, no authority) | r01 was failing locally: the row-0 placement bug, now fixed |
| 037 BasePopup ceremonies / acquisitions | phase3 s01..s03, d01..d05, a01..a05; phase6 u01..u06 (CI); m43_master_c005_meta_ceremonies (CI) | m037: Set Complete closed unacknowledged and re-drained (2 presentations, 1 key) + Heart +1, in all 5 arms |
| 037 terminal -> Results bridge | phase4 t01..t08 (CI): duplicate/stale terminal, missing, throwing and Reduced, each in its own run | m037: 3x duplicate WON + LOST signals under every arm (before, only FULL had duplicates) |
| 037 duplicate provider callbacks | phase3 a03 (one duplicate, FULL only); m54_regression_pack_022_027 (callback ordering, economy) | m037: the same rewarded token delivered 2 more times under every arm (refused, +1 Heart once, one keyed REWARD) |
| 037 feedback adapter fail-open | phase1 a04/a06/i06/r05/b04, master_c005f f04/f10 (spy- or autoload-level) | m037 DISABLED arm: the real app with the GameFeelFlow + Spark autoloads detached before boot and no test seam (the "plugin disabled" shape); THROWING arm: GFF + Spark both raise |
| 037 FULL/REDUCED matrix, truth preserved | e2e 5 arms (local, about 4 min), phase4 t04..t06 | m037 cross-arm: authority truth == FULL for all 5 arms; ABSENT/DISABLED/THROWING make exactly FULL's requests; REDUCED is a subset with 0 plugin calls |
| 037 bounded events, no lingering nodes | e2e (node/tween vs OFF, owned/emitters after the ceilings); m55_player_chaos 025 (lap leak rule, local) | m037: FULL <= 40 requests (12 seen); per arm, 0 owned work / 0 live emitters after the ceilings; nodes/tweens <= the plugin-free ABSENT arm |
| 037 "Godot AI smoke real Results/pack/robot flows" | e2e REAL arm (installed plugins, won/gift/meta/robot/acq) LOCAL_PASS 6/6 | - |
| 038 representative scenes, real shipping nodes | e2e (non-rendered), phase2 g03 (real plugins on a popup layer / SubViewport, non-rendered) | m54_visual_regression_038: real app, installed plugins, rendered frames |
| 038 FULL / REDUCED / plugin-disabled capture | none rendered | 3 arms x 3 effects (Results WIN confetti, Set Complete REWARD pickup above the popup scrim, GFF punch_scale + confetti on a Node2D probe). FULL: ink band + centred bbox. REDUCED/DISABLED: no burst, 0 ink, probe unpunched. All arms: 8-bin luminance histogram vs the committed baseline (tol 0.06) |
| 038 harness causes no duplicate grants/events | - | v04: no key requested twice in any arm, truth identical across arms |
| 038 fixed bounded duration, effect budget | adapter ceilings (phase1 a02/a03) | each burst is freed within its tier ceiling; 0 emitters / owned work left at arm end |
| 038 final visual state restored, no orphan tweens/emitters | phase2 w08, e2e | the probe's rendered bbox after == before (exact) and scale 1; Results emblem / robot slot / hero back to scale 1 |

Why the GFF probe is synthetic: production never drives GFF. Every shipping feel target is a Control, and GFF 1.0.0 only scales Node2D/Node3D (adapter `GFF_ALLOWED` + type gate, asserted by e2e "GFF never driven"). The probe is the only way to render GFF through the real adapter.

## Acceptance criteria
1. [x] Coverage map first: the table above.
2. [x] One gap suite for 037, CI-wired with an exact guard: `M54 regression pack 037-038: PASS (6/6 cases, 0 fail)`, LOCAL_PASS via `tools/run_suites.py` with the CI rule (exit 0, diag 0; its 11 labelled `explode` throws are tolerated like phase4's).
3. [x] 038 rendered check: deterministic frozen frames (A vs A again: 0 px noise in every capture), coarse numbers committed in `BASE` (ink bands, histograms), no image baselines in git, NOT_RUN + exit 1 under `--headless` (checked: `M54 visual regression 038: NOT_RUN ...`, ec=1). LOCAL_PASS 4/4 on two runs after baselining. Ink was win 1767/1994/1821, set 278/253/343, gff 1604/1484/1671 px over three runs; histogram distance <= 0.003.
4. [x] The suites bite (mutations, reverted):
   - one-shot gate removed in `FeedbackAdapter.play`: m037 FAIL 13;
   - Spark CanvasLayer reparent removed: 038 FAIL 6 (ink 0: the bursts render outside the app viewport).
5. [x] Real bugs fixed and reported: Results row-0 REWARD burst placement (product). Stale c005f static guards (tests).
6. [x] Throw-away saves only (`user://m54_037_*`, `user://m54_038_*`, removed at the end), injected clock/day, `boot_opening_override = 0` in the windowed run, `test_unlock_all` reset. main.tscn is never booted without a save override.

## Validation
- `--import` once in the worktree. At the end I restored project.godot and the churned tracked `.import` files from the index, and deleted the 1212 generated untracked `.import` / `.uid` / `.translation` files. The worktree is clean; the ignored `.godot/` cache is kept for reviewers.
- `python tools/run_suites.py --selftest` -> selftest PASS.
- CI rule (`tools/run_suites.py`), LOCAL_PASS: m54_regression_pack_037_038 6/6, m43_c005f_phase4_terminal_home_micro 19/19, m43_c001a_results_foundation 11/11, m42_navigation, m42_home, m43_c005f_phase6_unlock_feel 8/8, sb_polish_003_booster_vfx, m59_credits 3/3, m55_long_session, m43_c005_c072_feature_unlock_ceremony 9/9, m43_master_c005_meta_ceremonies 32/32, m43_master_c005r_gift_micro_progress 8/8, m43_master_c008_robots 10/10, m43_master_c011_c014 29/29, m44_contextual_coach 7/7, m46_performance 22/22, m49_responsive_matrix 8/8, m50_accessibility_audit 8/8, m51_localization_readiness 8/8, m54_regression_pack_022_027 12/12, m60_release_gates 6/6, sb_polish_004_006_ui_batch 10/10 -> `aggregate=PASS (22/22)`.
- Local-only suites (direct Godot, exit 0, no SCRIPT ERROR besides the labelled `explode` injections):
  - m43_c005f_phase1_foundation 23/23 (FAIL 22/23 before the guard fix);
  - m43_c005f_phase2_results_pack_feel 22/22 (FAIL r01 before the Results fix);
  - m43_c005f_phase3_meta_rewards_acquisition 15/15 (FAIL b01 before the guard fix);
  - m43_c005f_015_e2e_feel 6/6 (246 s);
  - m43_c005f_phase2_r01_earned_pack_runtime 22/22, m43_c005f_phase4_qa_r01_feel_lifecycle 4/4, m43_c005f_phase5_cleaning_spark_ab 13/13, m43_master_c005f_feel 10/10;
  - m43_c001r_c001_results_momentum 40/40, m43_c001b_won_results_visual 11/11, m43_c005_c005_reward_reveal_sequencer 12/12, m43_c004_c001_fail_need_a_hand 40/40, sb_polish_011_character_motion 16/16, m55_player_chaos PASS (162 s).
- Windowed: `godot --path . -s res://tests/m54_visual_regression_038.gd` -> `M54 visual regression 038: PASS (4/4 cases, 0 fail)` (two runs).
- `git diff --check` clean. `git status --porcelain` empty.
- No CI run (not pushed). No phone build.

## Log
### Round 1
I mapped SB-M54-037/038 onto m43_c005f phase1..6, e2e, master_c005f, m55_player_chaos 025 and sb_polish_003. The baseline run of those suites found three local-only failures:
- phase2 r01: a real Results bug, the row-0 burst placed 144 px off;
- phase1 a01 and phase3 b01: stale guards that broke on the SB-M59 Credits licence paths. e2e s01 has the same guard and was fixed preemptively.

I fixed both. Then I wrote the 037 five-arm gap suite (CI, exact 6/6) and the 038 windowed rendered pack (local, NOT_RUN headless) with committed baselines from three runs. I proved both suites bite with mutations and reran every affected CI and local suite. Nothing pushed.
