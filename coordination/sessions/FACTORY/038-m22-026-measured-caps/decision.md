APPROVE

## Why
All three round-1 reviews are PASS with no real problems. The diff holds only the 45 new `.import` caps, the measure tool, the apply script, the budget test, the ADR, TASKS.md and the merged map, with no PNG changes. `git merge-tree` reports no conflicts. build.md shows the caps follow the 2x rule (smallest ratio 2.065), the suites pass and the revert check fails as expected.

## Acceptance criteria
1. Diff scope: met. `git diff --stat origin/main...HEAD` lists 51 files, none of them PNG, all inside the allowed set.
2. Measure tool: met per build.md (18 scenarios, DONE line, real save hash unchanged, no temp saves left). I did not re-run the tool.
3. Apply script, dry run and write: met. The code reviewer re-ran the dry run on the post-cap tree and got "would cap 0". The rules reviewer checked all 45 limits against the merged map.
4. `--import` clean: met per build.md. Its only warning is the known `level_factory` project.godot one.
5. Budget test: met. The tests reviewer re-ran it and got PASS. build.md records the revert check as FAIL with exit 1.
6. Suites: met. The tests reviewer re-ran six of them and all passed. build.md records the rest as LOCAL_PASS.
7. Smallest ratio: met. build.md gives 2.065, which is at least 2.0. The rules reviewer independently confirmed every limit is at least 2x its measured side.
8. ADR and TASKS.md figures: met. The reviewers confirmed they match the test output, and the ADR states the known limits.
9. `git diff --check`: met. The code reviewer reports it passes.
