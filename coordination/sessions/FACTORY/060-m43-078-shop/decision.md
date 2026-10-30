APPROVE

## Why
The change is a verify-close: 4 added assertion cases in the Shop suite, the suite added to the CI validate loop with an exact guard, and TASKS.md ticks. Both round-1 reviews are PASS. CI run 41021184844 succeeded, including m46_performance, so the local m46 failure was machine load. merge-tree reports no conflicts. Post-review commit e548c43b touches only TASKS.md.

## Acceptance criteria
1. Suite prints PASS 15/15: met. build.md records LOCAL_PASS, and CI ran it.
2. Workflow loop and exact guard: met. I checked lines 120 and 210 of the workflow.
3. run_suites green: met on CI (run 41021184844). Locally only m46_performance failed on timing, and CI passed it.
4. shop_screen.gd has only reads: met. The suite asserts it in s15.
5. No billing, storekit, admob or purchase_token strings: met. I grepped and found no hits.
6. Diff limited to the workflow, TASKS.md and the suite: met. The diff stat shows exactly those three files.
7. Only 081 and 084 stay READY: met. I grepped TASKS.md and found READY only on 084 and 081.
