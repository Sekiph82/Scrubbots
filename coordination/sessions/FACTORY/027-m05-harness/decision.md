APPROVE

## Why
The change is small and well scoped: a stdlib Python runner that reads the suite list and exact-summary guards from the workflow, a conventions doc, pointer lines, a .gitignore entry and the TASKS.md closure. All three round-1 reviews are PASS with no real problems. merge-tree reports no conflicts. I re-ran `--list` and `--selftest` myself.

## Acceptance criteria
1. `--list`: met. It prints 44 lines. Reviewers confirmed the first suite is m35_level_catalog, the last is m46_performance, and the runner source never mentions m46_performance.
2. 3-suite run: met. The tests reviewer reproduced 3/3 PASS with aggregate=PASS and exit 0.
3. Unknown suite: met. Reproduced by the tests reviewer, exit 2 with an error naming the suite.
4. `--selftest`: met. I ran it and it printed `selftest PASS` with rc=0.
5. Docs strings and pointers: met. Reviewers confirmed the required strings and the references from AGENTS.md and docs/06_TEST_STRATEGY.md.
6. Diff scope: met. The six changed files include nothing under tests/ and no workflow, and `git diff --check` is clean.
7. TASKS.md: met. SB-M05-006..010 are marked [x] and the queue row is DONE.
8. run_tests: met. Build.md reports `RESULT: ALL PASS`, and the tests reviewer reproduced it.

Note: the review was not asked to rerun all 44 suites, and the code reviewer's notes find no real problem. Build.md claims 44/44 locally. I did not reproduce that.
