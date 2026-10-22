APPROVE

## Why
The branch changes only root TASKS.md. It records the owner's two dashboard answers on the matching item lines, removes the two answered questions and flips the three OWNER queue rows to READY in the required position. The English text of the RANKS policy matches the owner's Turkish answer and adds nothing to it. All factory reviews in round 1 (rules, code, tests) are PASS: the factory's SKILL.md defines three reviewers, not four. Their notes describe no real problem, and the merge-tree check is clean.

## Acceptance criteria
1. Diff scope: met. The only commit is a8efa8ab, and the diff against origin/main touches only TASKS.md. Two reviewers confirmed `git diff --check` is clean. The worktree status is clean.
2. Checker: met. The builder ran the checker and got ANSWERS_CHECK PASS. The rules and tests reviewers each reran it independently and got the same result (357 open IDs, 108 queue lines). I read the diff myself: it changes 2 item lines (appended notes only), removes 2 question lines and replaces 3 rows in place.
3. Faithful decisions: met. I compared the diff with answers-snapshot.md myself. The RANKS answer translates to: two tables; all-time = highest campaign level reached; weekly = levels completed that week, reset Monday 00:00 UTC; nothing bought with money or boosters counts. The diff adds no reward, season length, tie-break or backend. The languages note and row name only English and Turkish.
4. Factory still reads the queue: met. I checked this myself: the first `^- READY ` line in HEAD:TASKS.md is still SB-M50-BOARD-001.

## For the human
None.
