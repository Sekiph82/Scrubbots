# Campaign L11..L30 test fixes (SB-CAMPAIGN-L11-L30-FIX)

> Feature: SB-CAMPAIGN-L11-L30-FIX — two test suites are red on main since factory 071 added campaign L11..L30 (30 builtin levels; Level 30 is now end of content): (1) tests/m43_c001b_won_results_visual.gd still treats Level 10 as the last level (coming-soon card / disabled Continue) -> 2 checks fail; move the end-of-content case to Level 30. (2) tests/m55_long_session.gd fails in CI (run 41125628591, "m55_long_session FAIL (6)"); find the root cause, fix the TEST unless it is a real game bug (then describe and stop at diagnosis). Scope: tests only (plus TASKS.md queue row -> DONE). One CI validation_only run on the branch must prove validate is green.

## Context
- `tests/m43_c001b_won_results_visual.gd`, `_level10_unavailable_visual()` (~line 215): uses `app.progression.debug_set_current_level(10)`, expects Victory layout, disabled Continue and the NEXT_CLEANUP_SOON card. With 30 builtin levels, Level 10 now has a next level, so both checks (lines ~228, ~236) fail. Also `_rich_receipt` (~line 341) uses Level 10 only as an arbitrary streak-4 fixture; it is not an end-of-content case and need not change.
- Memory rule: `debug_set_current_level` fixtures never save; use `record_win` for durable fixtures. Reuse whatever frontier approach the suite already uses; if the unavailable-Continue logic reads the frontier/next-level from the catalog, Level 30 is the case.
- `tests/m55_long_session.gd` plays Levels 1..LEVELS back to back. `_drive()` (~line 280) follows the owner supply plan `intendedColumnClicks` in proof-kernel serial order (commit 06fbfbad). Local run (Godot 4.7.2 console) prints 3 distinct failures (each printed twice, total 6): "level 20 terminal [LOST] after 1698 frames (active left 933)", "all 30 production levels WON back-to-back", "frontier advanced to 31 (got 20)". The two latter are cascade of the first.
- Diagnosis already done: for Level 20 (`data/levels/supply/level_020_detective_supply_v1.json`, 120 planned clicks) the driver gets stuck after 55 clicks with all 5 slots full, no live assignment, supply not exhausted -> game reports LOST. Levels 11..19 complete using their full plans (e.g. 39/39, 40/40, 29/29). `tests/campaign_l11_l30.gd` `_win()` validates plans only in the pure `ProofKernel`, and `tests/m52_owner_supply_plans.gd` runs real runtime only for Levels 2..10 (PLAN_LEVELS), so no suite ever played L11..L30 plans through the real runtime before m55 did. So either (a) the m55 driver diverges from m52's `_play_clicks` pacing in some way that matters, or (b) the runtime (targeting/access/slot dispatch) legitimately diverges from the proof kernel on Level 20, which is a game/content bug.

## Requirements
1. m43_c001b: the "end of content, Continue disabled, coming-soon card" case runs on Level 30 (rename the function/log text from "level 10" to "level 30"); it uses the suite's existing frontier mechanism (record_win-based if durable state is needed). Level 10 is no longer asserted as last.
2. m55: determine the Level 20 root cause. First try test-side hypotheses (compare `_drive` with `m52 _play_clicks`: m52 ticks until quiet AND a free slot after EVERY click before the next, and fails if a click is rejected; make m55 equivalent and also detect/report a rejected plan click). If this makes m55 pass, fix only the test.
3. If the stall persists with an m52-equivalent driver (real runtime vs proof-kernel divergence), do NOT change game/content code. Stop at diagnosis: record in the job report the minimal evidence (level, click index at stall, slot colors/state, why no target is reachable) and add one `READY` follow-up row in TASKS.md Autonomous Queue for the game/content fix. m55 then stays red and the builder reports this plainly rather than weakening the test (no skipping Level 20, no lowering LEVELS).
4. Only files changed: `tests/m43_c001b_won_results_visual.gd`, `tests/m55_long_session.gd` (if needed), `TASKS.md` (the SB-CAMPAIGN-L11-L30-FIX row -> DONE with real evidence, run id; follow-up row only in the case of Requirement 3).

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m43_c001b_won_results_visual.gd` exits 0 and its final line is the suite PASS line with 0 failures; output contains a Level 30 end-of-content check ("Level 30: Victory layout, Continue disabled, readable coming-soon card" or equivalent text) and no FAIL.
2. `grep -n "debug_set_current_level(10)" tests/m43_c001b_won_results_visual.gd` shows no use as an end-of-content fixture (only the `_rich_receipt` streak fixture may remain).
3. `"$GODOT" --headless --path <worktree> -s res://tests/m55_long_session.gd` prints `M55 LONG SESSION: PASS`, including "all 30 production levels WON back-to-back in one app session" and "frontier advanced to 31". (Exception only per Requirement 3: report instead the diagnosis and the follow-up row.)
4. `git diff --name-only main...HEAD` lists only files named in Requirement 4 (plus the factory job folder).
5. One CI run: `gh workflow run android-family-first10.yml --repo Sekiph82/Scrubbots --ref factory/079-campaign-test-fix -f mode=validation_only`; its `validate` job concludes success (`gh run view <id> --repo Sekiph82/Scrubbots`), and the run id is recorded in the TASKS.md row. No APK built.
6. `git diff --check` is clean.

## Out of scope
- Any change to game scripts, level data, supply plans, proof kernel or CI workflows.
- Re-running other suites locally (owner dislikes redundant testing); only the two suites plus the one CI run.
- Weakening m55 (fewer levels, skipping L20, loosened assertions) to get green.
- Adding new test suites.

## Assumptions
- Level 30 is the end of content (stated by the task); no L31 exists.
- The 6 reported m55 FAILs are 3 distinct messages printed twice (stdout plus summary), all caused by the Level 20 LOST, per the local run.
- A runtime/proof-kernel divergence on Level 20 is plausible because the runtime was never exercised on L11..L30 plans before; hence the diagnosis-stop branch is allowed rather than silently masked.
