VERDICT: PASS

## Findings
None.

## Notes
- Re-ran both suites in the worktree. Each exited 0 with no SCRIPT ERROR or Parse Error.
  - `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`
  - `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)`
  - The "29 resources still in use at exit" line is the usual engine shutdown noise, not a failure.
- `git diff origin/main...HEAD -- tests` contains only added lines. No existing assertion was weakened, skipped or removed. The case ledgers are unchanged.
- The new assertions can fail if the behaviour breaks:
  - m06 reads both `HomeBadges.compute()["events"]` and the visibility of `NavBadge_events` in three states (0, then 1, then 0). A badge that spammed, never appeared, or never cleared would fail.
  - c02 has a negative check (no Ready_gift_bar/tasks/events lines when nothing is ready) and a positive check on the exact label text and counts. It also asserts that the wallet, gifts, task and event reward are all untouched.
  - c04 tests the boundary at second 7d-1 versus 7d. It checks the same state after relaunch via snapshot copies. It also checks the fresh-install and restored-claim reinstall cases.
  - a04 has "control" assertions in each empty-state case (task:0 becomes claimable, duplicate listed). The empty-state checks therefore cannot pass vacuously. The network-error retry loop covers every surface in `Popups.NETWORK_SURFACES`, including a failed retry followed by a recovering one.
- The `orders._pool = []` seam is acceptable. It writes the same value that `load_pool` returns for a malformed file (`archetypes: []`, fail-closed). The assertion follows a control where the task is claimable, so the TASK_NONE result comes from the empty pool and not from setup. The cost is that the test touches a private field. A small comment noting the equivalence (it is already there) is enough.
