APPROVE

## Why
The diff contains only the new test suite, a CI workflow entry with an exact-summary guard, and TASKS.md ticks. It has no production code, which matches the verify-close spec. Both final-round reviews (rules, tests) are PASS. merge-tree reports no conflicts. build.md records the new suite at 6/6 and run_suites at 49/49.

## Acceptance criteria
1. New suite prints the exact 6/6 PASS line: met. build.md records it, and the suite and guard are present in the diff.
2. EXPECTED_CASES guard fails on skipped or broken cases: met. build.md records an observed failing run with exit 1.
3. Existing suites still pass: met. run_suites aggregate is 49/49 per build.md.
4. Workflow has the suite in the loop plus a grep -qxF guard, and run_suites reports all pass: met. I read both workflow changes in the diff.
5. Diff limited to the suite, workflow and TASKS.md: met. `git diff --stat origin/main...HEAD` shows exactly those three files and no production code.
6. TASKS.md ticks 074, 075 and 077 with LOCAL_PASS evidence naming the suite, and 076 is untouched: met. I read the diff.
