APPROVE

## Why
The change adds three one-shot contextual coachmarks (first WAITING, first WON, first LOST). It is presentation-only and reads canonical scheduler and receipt state. The three round-1 reviews (rules, code, tests) are all VERDICT: PASS, and the reviewer-tests agent re-ran the new suite and the six regression suites and confirmed they pass. `git merge-tree` reports no conflicts. The m46_rm002_adversarial T03 failure also occurs on origin/main 3db94a9b in the same worktree and passes in the main checkout. That makes it an environment or worktree timing issue the branch did not cause, so it does not block.

The final round contains three review files, not four. All three present are PASS, and their Notes describe no real problem. The only Notes are non-blocking style and poll-timing remarks.

## Acceptance criteria
1. New suite `m44_contextual_coach` prints PASS (7/7): met. build.md records it and reviewer-tests re-ran it.
2. Config strictness (12 malformed variants rejected; `l3_rules` is only `l3_speed`): met, per the suite's c01.
3. First WAITING shows `ctx_waiting` on the slot strip, then acknowledges and does not re-show: met. The test drives a real scheduler WAITING state.
4. Win/Loss one-shot and independent, with Heart text matching the receipt: met. Terminals are sent through the real `terminal_reached`.
5. Persistence and Skip Tips: met (c05, reboot from the same temp save).
6. Grandfathered profiles see nothing: met (c06; reviewer-rules and reviewer-code confirmed `is_new_profile` gating).
7. Window independence: met (c03, c04, c07 run with `closed == true`).
8. No economy mutation, modal and reveal suppression: met. Snapshots are byte-identical and suppression is asserted in c07.
9. Regression suites m44_ftue 23/23, m44_unlock_gate 6/6, m46_rm003, m46_r07, m51, m55 all PASS: met. Re-run independently by reviewer-tests.
10. Diff check, docs grep and TASKS.md `[x]` lines: met. I spot-checked TASKS.md lines 43, 1347 and 1348 in the worktree, and the diff stat shows the docs/16 update.
