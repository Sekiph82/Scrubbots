STATUS: READY

# Build: SB-TEST-RED-2026-11-09 non-CI suite reds (2)

## Summary
Branch `factory/139-noncI-reds-2` (worktree `C:/Users/sekip/AppData/Local/ScrubBotsFactoryWT/139-noncI-reds-2`). I ran all 149 `tests/*.gd` suites that are not in the CI validate loop and fixed every red at its root cause. Two were real product bugs and are fixed in the product. The rest were tests that had not caught up with intended owner changes.

Commits (rebased onto origin/main 1e9c5bf3; factory 137 ed92d4f4 had already landed the same Results row-0 burst fix and the same c005f Credits allow-lists, so my duplicates a142025d / 7db2476a were dropped and main's versions kept):
- 6ae1dea5 a11y: the RANKS All-time / Weekly tabs now take screen-reader focus (`scripts/ui/profile/profile_screens.gd`)
- e7ae3db2 tests: booster / +1 Slot suites set `test_unlock_all`; the rm006 fair-cursor check handles wrap-around (`tests/m28_c002_c002_r01_visual.gd`, `tests/m28_c002_c002_static_shell.gd`, `tests/m28_c002_c003_final_gate.gd`, `tests/m46_rm004_residual_adversarial.gd`, `tests/m46_rm005_terminal_frame_profile.gd`, `tests/m46_rm006_selector_proof_integrity.gd`, `tests/m52_r01_parallel_runtime.gd`, `tests/m55_core_chaos.gd`)
- 7a6cc7d5 tests: railroad exterior, 30-level catalog, VOID levels, L30 featured card (`tests/m21_v08_corridor_validation.gd`, `tests/m21_v09_direct_evidence_reconciliation.gd`, `tests/m43_c001r_c001_results_momentum.gd`, `tests/m53_c002_difficulty_calibration.gd`, `tests/m53_first10_difficulty.gd`, `tests/void_cells_c001.gd`)
- 892e8a3a + 29bc416e docs/tasks: queue row `DONE SB-TEST-RED-2026-11-09` with the census (`TASKS.md`)

## Acceptance criteria
1. [x] **m43_c005f_phase3: the credits screen naming a feel plugin.**
   - Fix: the scan now strips only the two exact licence-path literals (`"res://addons/game_feel_flow/LICENSE"`, `"res://addons/saltmire_spark/LICENSE.txt"`) before checking. Any other mention of a plugin name or path in any script is still flagged, credits_screen.gd included. The adapter-only rule for real plugin use is unchanged.
   - The same red was in m43_c005f_phase1_foundation (a01) and m43_c005f_015_e2e_feel (s01), so both got the same allow-list.
   - Evidence: phase3 PASS (15/15), phase1 PASS (23/23), 015 PASS (6/6).
2. [x] **m43_c005f_phase2 "8-particle pickup": this was a product bug.**
   - Root cause: `ResultsScreen._on_reveal_step` fired row 0's REWARD feel the moment its reveal step started. The freshly added rows had not been laid out yet, so the row 0 burst was placed at (540, 863) while the row's real centre is (540, 1007), 144 px lower. Rows 1 to 4 were correct. The Results video and the Reduced path are not involved.
   - Fix: the row feel now goes through the existing `_after_layout` settle, the same one the WIN confetti already uses. It still re-checks the reveal key.
   - The test is unchanged and now passes: PASS (22/22), row-0 burst at (540, 1007).
3. [x] **Sweep of the 149 non-CI suites** (headless, 360 s cap, 3 parallel shards, then quiet reruns). Final result:

   | Result | Count | Suites |
   |---|---|---|
   | PASS | 145 | Includes 9 old-format `N/N cases, 0 failures` suites: m42_c002_scrubby_scale, m42_c003_scrubby_animation, m42_home_composition, m42_home_v04/v05/v06/v07_safe_area, maint_home_export_asset_gate_c001, maint_supply_columns_c001. Also includes suites whose only diagnostics are documented deliberate fault injections: c005f `explode`, m46_rm004 read-only out array, m46_rm006 `rm006_injected`, m55_player_chaos `explode`. |
   | NOT_RUN | 1 | m50_contrast_surfaces (windowed only, needs a rendering driver) |
   | Skipped, over 6 min | 2 | m25_c004_host_truth, m25_c004_railroad_differential (killed at 360 s) |
   | FAIL | 1 | m46_rm005_terminal_frame_profile: performance finding, see item 5 |

   Fixed this job:

   | Suite | Cause | Fix |
   |---|---|---|
   | m21_v08, m21_v09 | Railroad V1 (M22-C001 V03) replaced the M21 one-cell ring | Now assert the railroad: a start above the board fails closed with NO_ROUTE; a corner route uses the bottom rail plus a vertical rail side |
   | m28_c002_c002_r01_visual / _static_shell, m28_c002_c003_final_gate, m46_rm004 / rm006, m52_r01, m55_core_chaos | Booster and +1 Slot locks (SB-M44-031/032) | Set `AppState.test_unlock_all` |
   | m46_rm006 | The fair cursor wrapped past the list end on a fast machine; the test read the start as the lowest position | Start is now the beginning of the contiguous cyclic run, and must equal the previous cut |
   | m43_c001r | The SB-M44-026 L30 Featured Card ceremony barrier hid the Next Cleanup card | Seed pre-grants the card and marks it seen, as m43_c001b already does |
   | m53_first10, m53_c002 | The catalog now has 30 levels | Assert the catalog has at least 10 entries with orders 1..10 first |
   | void_cells_c001 | L11..L29 are shipped version-2 VOID levels | For version-2 files, check that VOID cells are never ACTIVE and that the supply total equals the artwork cell count; version-1 files keep the old check |
   | m50_a11y_surfaces | RANKS tabs used `FOCUS_NONE` (factory 134) | Product fix: the tabs now use `FOCUS_ACCESSIBILITY` |

4. [x] **Small product bugs fixed:** the Results row-0 burst (item 2) and the RANKS tab screen-reader focus (item 3).
5. [ ] **Product bug found, not fixed: performance.** In m46_rm005 T4, the warm WON terminal tick is 108 to 121 ms against a 60 ms budget (pre-RM005 baseline was 82.7 ms). About 111 ms of that is the `main.gd` terminal lambda.
   - With the Results video disabled as an experiment (reverted afterwards) it was still 108 ms, so the video is not the cause.
   - It needs real profiling, so I left it as a follow-up and did not change the threshold.
   - The CI suite m46_performance passes 22/22.

## Validation
- Sweep logs are in the scratchpad `j139/logs`. Reruns of every changed suite were done on a quiet machine:
  - m43_c005f_phase1 PASS 23/23; m43_c005f_015 PASS 6/6; m43_c005f_phase3 PASS 15/15; m43_c005f_phase2 PASS 22/22
  - m28_c002_c002_static_shell PASS 16/16; m28_c002_c002_r01_visual PASS 10/10; m28_c002_c003_final_gate PASS 22/22
  - m21_v08 PASS; m21_v09 PASS
  - m46_rm004 PASS; m46_rm006 PASS 5/5
  - m52_r01 PASS; m55_core_chaos PASS
  - m53_first10 PASS; m53_c002 PASS
  - void_cells_c001 PASS; m43_c001r PASS 40/40; m50_a11y_surfaces PASS 3/3
- `python tools/run_suites.py` on the 23 CI suites covering `results_screen.gd` / `profile_screens.gd`: aggregate PASS 23/23. These include m42_home, m43_c001a, m43_master_c005/c008/c010/c011_c014, m43_personal_ranks, m43_ranks_weekly, m46_performance 22/22, m49_responsive_matrix, m50_accessibility_audit 11/11, m51, m54 x2, m56, m60, sb_polish_004_006.
- Non-CI suites touching Results / ranks were rerun after the fix, all PASS: m22_026, m22_029, m42_opening, m43_146, m43_c001b 11/11, m43_c004 40/40, m43_c005_c005, m43_c005f_phase2_r01, m43_master_c005f_feel, m49_touch_targets, m49_surface_matrix, m49_surface_stress, m55_player_chaos, sb_polish_011, sb_video_007_008.
- `git diff --check`: clean. Import churn (project.godot, .import, .uid files) was restored or deleted. The coordination metrics files rewritten by the m28 suite were restored. `git status --porcelain` is empty. Nothing pushed, no CI run, no phone build.

## Log
### Round 1
- Imported once, restored the import churn, and computed the non-CI list as all `tests/*.gd` minus `run_suites.py --list` (149 suites).
- Ran the 149 suites in 3 shards and classified each red; fixed them as above.
- Wrote the TASKS queue row. Clean tree.

### Round 1 (rebase, coordinator request)
- Rebased onto origin/main 1e9c5bf3, which includes 137, 140, 141 and 142. Dropped my duplicates of 137's Results row-0 burst fix and Credits allow-lists, keeping main's versions. Kept the a11y fix, the test updates and the TASKS row; TASKS hashes are updated to the rebased SHAs (29bc416e).
- After the rebase and a fresh import, all of these PASS: every suite I changed (m21_v08/v09, m28 x3, m43_c001r 40/40, m46_rm004, m46_rm006 5/5, m52_r01, m53 x2, m55_core_chaos, void_cells_c001), m43_c005f phase1 23/23, phase2 22/22, phase3 15/15, m50_a11y_surfaces 3/3, m43_ranks_weekly 7/7 and m60_release_gates 6/6.
- m43_c001r did not need 141's `ads` erase: it does not compare economy snapshots in a way that sees the ad play counter.
- The only SCRIPT ERROR lines are the documented fault injections.
- m46_rm005 still FAIL, left as is as the coordinator asked.
