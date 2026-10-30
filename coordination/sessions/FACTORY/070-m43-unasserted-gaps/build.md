STATUS: READY

# Build: M43 unasserted gaps (SB-M43-134, 143, R12-003, 165, 166)

## Summary
Tests only. No production code changed and no real behavior gap turned up. All the new assertions sit inside existing cases, so the case ledgers (C010 12/12, C011-C014 28/28), the CI exact-summary guards and the "(60 total)" loop stay the same.

- `tests/m43_master_c010_meta.gd`: m06 checks the EVENTS badge (HomeBadges plus Home `NavBadge_events`) at three points: 0 while active with nothing claimable, 1 once a milestone is claimable, 0 after the claim. Adds the helper `_events_badge()`.
- `tests/m43_master_c011_c014.gd`:
  - c02: the comeback Gift/Tasks/Events lines.
  - c04: the Catch-Up expiry boundary and uninstall/reinstall.
  - a04: retry on every network-error surface, plus the no-tasks and no-duplicates empty states on the real popups.
  - Adds preloads for ProfileScreens, DailyScreens, CollectionScreen, Popups and HomeBadges.
- `TASKS.md`:
  - 134, 143 and R12-003 are ticked and their queue rows set to DONE.
  - 165 and 166 stay `[ ]` with honest notes, and their queue rows are set to OWNER (they need live services or Ranks).
  - Only those 10 lines changed, and the CRLF line endings are preserved.

Commits: 9377dc15 (tests), eb1b758b (TASKS.md).

## Acceptance criteria
1. [x] 134 Event badge. c010 log:
   - `ok: SB-M43-134: active event with nothing claimable -> no EVENTS badge (no spam) [0, false]`
   - `... claimable event reward -> EVENTS badge 1 on Home BottomNav [1, true]`
   - `... reward claimed -> EVENTS badge cleared [0, false]`

   m10 already covers the other states. By design the badge counts claimable event rewards, so a bare active event never pings.
2. [x] 143 comeback lines. c011 log:
   - `ok: SB-M43-143: nothing ready -> no Gift / Tasks / Events line (none fabricated)`
   - `ok: Gift line: 2 claimable gift(s)`
   - `ok: Tasks line: 1 task reward ready`
   - `ok: Events line: 1 event reward ready`
   - `ok: summary grants / claims nothing (gifts, task, event reward still waiting)`
3. [x] R12-003. c011 log:
   - `ok: last second before expiry: open, same state after relaunch`
   - `ok: exactly at expiry: expired, wins frozen, summary gone, claims refused, identical after relaunch`
   - `ok: reinstall, no cloud: no window, no Catch-Up, no summary`
   - `ok: relaunching the fresh install opens nothing either`
   - `ok: reinstall + restored copy: claimed step stays claimed, no re-grant`

   What this proves: a reinstall without cloud is a fresh profile (absent `return` section) and has nothing to farm. A restored copy keeps its claimed steps.
4. [x] 165 (asserted part; the item stays open, row OWNER). c011 log shows these three lines for each of rewarded_ad, store, cloud and live_event:
   - `TRY AGAIN control live on the error state`
   - `failed retry -> still open and usable`
   - `second retry recovers and closes`

   Then `ok: retry grants nothing`. Nothing in `scripts/` calls `Popups.network_error` yet: there is no store IAP, no ad provider (M57) and no cloud provider (SB-M43-153), and Ranks is not live.
5. [x] 166 (asserted part; the item stays open, row OWNER). c011 log:
   - `ok: no task ready -> every claim blocked, no Tasks badge`
   - `ok: control: a done task becomes claimable`
   - `ok: no order available -> TASK_NONE on every row`
   - `ok: no duplicates -> CARDS_EMPTY, exchange-all blocked`
   - `ok: control: a duplicate is listed, empty state gone`

   Gifts (a04) and events (m05) were already asserted. No-rankings is out of scope while Ranks is not live.
6. [x] The suites pass (below). In TASKS.md the working copy has 1991 CRLF line endings out of 1991 lines, and the diff touches only the 10 lines.

## Validation
Godot 4.7.2 console, headless, run in the worktree after a one-time `--import`:
- `-s res://tests/m43_master_c010_meta.gd`: exit 0, `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`. LOCAL_PASS.
- `-s res://tests/m43_master_c011_c014.gd`: exit 0, `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)`. LOCAL_PASS.
- Neither log has a `SCRIPT ERROR` or `Parse Error`. Both end with `ERROR: 29/30 resources still in use at exit`, which was already there: the HEAD copy of c010 prints the same line.
- `python tools/run_suites.py --list`: 60 suites, and both touched suites are already in the CI validate loop with exact guards at lines 239/244.
- `git diff --check`: clean.
- Import noise (.import, .uid, project.godot) was reverted, and `git status --porcelain` is empty.

## Log
### Round 1
- Wrote spec.md.
- Added the assertions above to existing cases. They used the real popups (comeback, Tasks, Cards Exchange, network error) and the real Home badge nodes.
- Found no behavior bug.
- The no-order TASK_NONE check sets `orders._pool = []` in the test to mimic the fail-closed empty pool a malformed config yields.
- Updated TASKS.md as described above. Did not push.

CI: GitHub Actions run 41082948565 success; C010 12/12, C011 28/28.
