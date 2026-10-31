STATUS: READY

# Build: Campaign L11..L30 test fixes (SB-CAMPAIGN-L11-L30-FIX)

## Summary
The m43 end-of-content case now runs on Level 30. On m55, the answer to the key question is NO, and the Requirement 3 (diagnosis-stop) path applies. When the real runtime replays the owner plans, it diverges from the ProofKernel. The runtime picks other targets than the kernel, so some plans dead-end in the real game. Two parts of that are real failures. Level 22 is LOST under every driver. Level 18 is LOST in the app root but WON in a bare host. The m55 driver has been made stricter: it now waits for full quiescence after each plan click and reports a rejected click. m55 was not weakened: LEVELS is still 30, no level is skipped and no assertion was loosened. It stays red, and a READY follow-up row tracks the game/content fix.

Files changed (branch `factory/079-campaign-test-fix`, commits ea71d9c5, 534eff09, 7405602b, a66dfecd, 8718f966):
- `tests/m43_c001b_won_results_visual.gd`: `_level10_unavailable_visual` became `_level30_unavailable_visual`, with `debug_set_current_level(30)` and the log/case text set to Level 30. The `_rich_receipt` streak fixture still uses Level 10.
- `tests/m55_long_session.gd`: `_drive` clicks each plan column, then ticks until `_quiet` is true. `_quiet` means no live assignment, no moving bot, and every occupied slot WAITING. A rejected click returns a `rejected` string, which shows the click index and the slot colors, counts and WAITING/LIVE state. The failure line also prints the number of accepted plan clicks. Level 1 still uses the greedy path.
- `tests/m44_new_badge.gd` (round 2): the stale L40 check "RANKS unserved (disabled) -> no NEW" was replaced. 7f208789 (SB-M43-122) made RANKS a served tab. At L40 on a new profile, `NavBadge_leaderboard` now must show NEW, and pressing `Nav_leaderboard` must mark `feature_visited:ranks` and hide the badge. These are the same NEW semantics as the robots/events check.
- `TASKS.md`: the queue row is DONE with the evidence, including the round 2 m44 fix. The READY `SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE` row now begins: "L22 unwinnable via intended clicks in the real runtime (all layouts); L18/L20 layout/pacing-dependent; likely kernel _origin_for_slot vs runtime SlotOriginProvider". The `SB-M44-NEW-BADGE-RANKS-FIX` row was removed.

## Key question: does the real runtime win L20 with m52 `_play_clicks` pacing?
**No.** I used a scratch probe (deleted afterwards, not committed). It took a bare ProductionGameplayHost per level, with frontier fixtures from `record_win`, and replayed the plan in the m52 style. At the same time it replayed the plan in lockstep through the ProofKernel.

- **L20 Detective, m52 style:** click 72/120 (column 3) is rejected with `terminal`, because the game is already LOST.
  - Runtime: 681 ACTIVE cells. All 5 slots are WAITING: C0 x1, C5 x9, C6 x8, C0 x12, C5 x5.
  - Supply fronts: column 1 shows C5 x8, column 2 is exhausted, column 3 shows C3 x20.
  - Kernel before the same click: 679 ACTIVE, 4 slots occupied, legal columns [0, 2]. So the kernel still has a free slot and the runtime does not.
  - The trajectories first diverge after click 16, where 158 cells differ.
  - When the kernel quiesces the runtime's own state (`ProofState.from_runtime`), nothing changes: 681 -> 681 ACTIVE, 5 -> 5 occupied. The runtime position is a real dead end.
- **m52 pacing is also faulty.** `live_assignment_count() == 0` also holds between two dispatch waves, so m52 can fire the next click before the runtime has settled. With a true-quiescence driver (all occupied slots WAITING), L20 WINS 120/120.
- **Level 22 Crab, true-quiescence driver:** LOST at click 28/43 (column 3).
  - All 5 slots are WAITING. Runtime has 274 ACTIVE; the kernel has 262 ACTIVE and a free slot at the same point.
  - The kernel cannot move from the runtime's state either: 274 -> 274 ACTIVE.
  - First divergence is after click 3. The runtime cleared (29,27) (color 4) where the kernel cleared (7,27), and it then could not reach (8,27) and (8,28) (color 0) in that step.
  - Likely cause: the kernel uses a fixed route origin per slot, `(slot+0.5)*w/cap` below the board (`proof_kernel.gd` `_origin_for_slot`). The runtime uses the laid-out UI slot anchors (`SlotOriginProvider`). Different origins lead to different target picks.
  - This also explains the layout dependence: in the app root (m55), L18 is LOST after 17/40 plan clicks, while in a bare host L18 WINS.

### Every L11..L30 plan through the real runtime (bare host)
| Driver | Not WON |
|---|---|
| m52 `_play_clicks` pacing | L20 (click 72/120), L22 (click 26/43); L2..L19, L21, L23..L30 WON |
| full quiescence (new m55 driver) | L22 (click 28/43); all other L2..L30 WON |
| m55 in the real app root (full quiescence) | L18 LOST after 17/40 plan clicks (stops the run, later levels not reached) |

A player who follows the intended clicks can get stuck on L22 in any layout, and on L18/L20 depending on layout and pacing. The kernel proves only that its own trajectory wins.

## Acceptance criteria
1. [x] m43 suite. Re-verified in round 2 after a fresh `--import`; see the Round 2 log. `$GODOT --headless --path <wt> -s res://tests/m43_c001b_won_results_visual.gd` exit 0, last suite line `M43-C001B WON results visual evidence: PASS (11/11 cases, 0 fail)`, contains `ok: Level 30: Victory layout, Continue disabled, readable coming-soon card`, no FAIL/SCRIPT ERROR/Parse Error. The output also contains the engine teardown line `ERROR: 30 resources still in use at exit`. It is not a script diagnostic and does not fail the CI rule.
2. [x] `grep -n "debug_set_current_level(10)"` matches only line 347 (`_rich_receipt` streak fixture).
3. [ ] m55 PASS: **Requirement 3 exception.** `M55 LONG SESSION: FAIL (6)`. The 6 FAILs are 3 distinct lines, each printed in both laps: `level 18 terminal ["LOST"] after 582 frames, 17 plan clicks (active left 351)`, then "all 30 ... WON" and "frontier advanced to 31 (got 18)". Levels 1..17 WON. The diagnosis is above, and the follow-up row `SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE` is READY in TASKS.md.
4. [x] `git diff --name-only main...HEAD`: `TASKS.md`, `tests/m43_c001b_won_results_visual.gd`, `tests/m44_new_badge.gd`, `tests/m55_long_session.gd`. The orchestrator added m44_new_badge to scope in round 2.
5. [ ] CI validation_only run **41150908377** (head ea71d9c5): `validate` = **failure**; export was skipped, so no APK was built.
   - Failing suites: `m55_long_session FAIL (6)` (expected per the Requirement 3 diagnosis) and `m44_new_badge FAIL (1 fail)`.
   - m44_new_badge was not caused by this branch. Its check "L40: RANKS unserved (disabled) -> no NEW" had been stale since 7f208789 (SB-M43-122). Round 2 fixed it, and it now passes locally 6/6. No new CI run was made, as the orchestrator instructed.
   - The run id is recorded in TASKS.md. The remote branch was deleted after the run.
   - m43_c001b is not in the CI suite list, so CI cannot show it.
6. [x] `git diff --check` clean.

## Validation
- `tests/m43_c001b_won_results_visual.gd`: LOCAL_PASS (11/11).
- `tests/m55_long_session.gd`: LOCAL FAIL (6). This is expected per Requirement 3.
- `tests/m44_new_badge.gd`: LOCAL_PASS in round 2. Exit 0, `M44 new badge evidence: PASS (6/6 cases, 0 fail)`, including `ok: L40: served RANKS shows NEW, text 'NEW'` and `ok: Nav_leaderboard press: visited, NEW hidden`. No SCRIPT ERROR or Parse Error. In round 1 it failed with 1 FAIL on the stale check.
- Scratch real-runtime probe over L2..L30: results in the tables above. The probe file was deleted and is not committed.
- CI 41150908377: validate failure (m55 plus m44_new_badge); 60 suites PASS.
- `git diff --check` clean, rechecked in round 2. `git status --porcelain` is empty; Godot import artifacts were removed from the worktree.

## Log
### Round 1
- Fixed the m43 Level 30 end-of-content case.
- Built a scratch probe that replays every plan through the real runtime and the ProofKernel in lockstep, comparing the two on cell differences and slot states. It also quiesces the kernel from the runtime's state when a level stalls.
- Found that m52-style pacing can click between dispatch waves, and replaced m55's driver with a full-quiescence driver that reports rejected clicks.
- A real runtime/kernel divergence remains: L22 under every driver, and L18 in the app root. Following Requirement 3, game and content were left untouched and m55 stays red. Two follow-up rows were added: the divergence fix, and the unrelated stale m44_new_badge RANKS assertion found by the CI run.

### Round 2
The orchestrator asked for three things:
- **Fix m44_new_badge here instead of queuing it.** Done in 7405602b. The L40 check now expects the served RANKS behaviour: the NEW pill shows, and a press marks it visited and hides it. LOCAL_PASS 6/6.
- **Remove the SB-M44-NEW-BADGE-RANKS-FIX row and note the fix in the SB-CAMPAIGN-L11-L30-FIX evidence.** Done in a66dfecd.
- **Make SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE explicit.** Done in a66dfecd. The row stays READY and now leads with the requested wording.

No new CI run, as instructed. m55 is unchanged and stays red per Requirement 3.

### Round 2 (review findings from round-1/)
1. **TASKS.md missing line break** (review-code, review-rules). My round-2 removal of the m44 row also removed the newline before the next row, so the SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE row ran into `- DONE SB-M43-134`. Fixed in 8718f966: the line break is restored with CRLF (file is 1996 CRLF / 1996 LF). `git diff main -- TASKS.md` now shows only the SB-CAMPAIGN-L11-L30-FIX row and the new divergence row; the SB-M43-134 row is unchanged.
2. **m43_c001b not reproducible** (review-tests): FAIL 2 checks, "each row shows its existing approved icon" and "LOST: Fail robot, not the Victory robot", with script errors. Cause: the worktree's import state. In round 1, after my local runs, I restored the regenerated tracked `.import` files and deleted the untracked `.uid` / `.import` files Godot had generated. The `.godot/` cache stayed, so it no longer matched and textures failed to load in the reviewer's run. Neither check is in code this branch changed.
   - **This branch, after a fresh `$GODOT --headless --path <wt> --import` (exit 0):** m43 exit 0; log lines `21: ok: each row shows its existing approved icon`, `39: ok: LOST: Fail robot, not the Victory robot`, `47: ok: Level 30: Victory layout, Continue disabled, readable coming-soon card`, `67: M43-C001B WON results visual evidence: PASS (11/11 cases, 0 fail)`. No FAIL, SCRIPT ERROR or Parse Error.
   - **origin/main e5da7566, in a temporary detached worktree with a fresh `--import` (exit 0; worktree removed and pruned afterwards):** m43 exit 1; `21: ok: each row shows its existing approved icon`, `39: ok: LOST: Fail robot, not the Victory robot`, `47: FAIL: Level 10: Victory layout, Continue disabled, readable coming-soon card`, `49: FAIL: disabled Continue: no mutation, no transition`, `67: M43-C001B WON results visual evidence: FAIL (11/11 cases, 2 fail)`.
   - So the two checks the reviewer saw fail pass on both trees with a proper import. On main the only failures are the two Level 10 end-of-content checks this job fixes.
   - The import churn is left in the worktree, uncommitted, so reviewers can run the suites: `project.godot` plus regenerated `.import` / `.uid` files. Committed changes are unaffected; `git diff --name-only main...HEAD` is still the four files.
3. **m44_new_badge final PASS line** (review-tests). Full output was redirected to a file and grepped: exit 0; `42: ok: L40: served RANKS shows NEW, text 'NEW'`, `43: ok: Nav_leaderboard press: visited, NEW hidden`, `45: M44 new badge evidence: PASS (6/6 cases, 0 fail)`. No FAIL, SCRIPT ERROR or Parse Error. The tail is only the engine teardown lines (`391 ObjectDB instances were leaked`, `30 resources still in use at exit`).

No-change notes from the reviews:
- review-code: a fully used plan that does not WIN idles to 200000 frames. That matches the previous behaviour; the level then fails as not WON, which is the right result.
- review-rules: merging with m55 red is accepted as the Requirement 3 exception, and SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE should be scheduled next. No change on this branch.
