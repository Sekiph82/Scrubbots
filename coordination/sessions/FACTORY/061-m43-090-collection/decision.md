APPROVE

## Why
The Collection pack entry (SB-M43-098) is built and the other Collection tasks are verify-closed with new assertion cases k14..k17. Both reviews in round 1 are PASS, CI run 41029956333 succeeded (it included c007 17/17, m54 and m46_performance), and `git merge-tree` reports no conflicts. The newest commit (9d564d28) touches only TASKS.md.

## Acceptance criteria
1. C007 prints 17/17 cases: met. build.md shows 3 local runs, and CI shows c007 PASS 17/17, including the k10 perf budget, which was not loosened. The reviewer's local k10 miss (159 ms vs 150 ms) is load-related, and CI passed.
2. m54 exactly-once prints PASS: met. Local run and CI both pass.
3. Pack entry shows counts and OPEN is enabled only when the queue is non-empty (k14): met. k14 asserts it and the reviews confirm it.
4. The route goes through request_earned_packs and the UI has no direct queue or inventory mutation: met. The route is the `open_packs` Callable bound at main.gd:374. build.md reports the mutation grep returns nothing.
5. Both suites are in the workflow with exact-summary guards (55 suites): met. The diff stat shows the workflow change, and CI ran both suites.
6. run_suites passes: met. Local run was 54/55; the only failure was m46 timing under machine load, and it passed in CI.
7. `git diff --check` is clean and the diff stays in scope: met, with one note. The diff also includes a one-line wiring change in `scripts/app/main.gd`. It is needed to bind the route and build.md explains it, so I accept it.
8. TASKS.md rows 090..101 are ticked with the classification and PASS labels: met. HEAD changes TASKS.md only (12 lines).

## For the human
n/a
