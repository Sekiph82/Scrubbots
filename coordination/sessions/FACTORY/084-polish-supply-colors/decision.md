APPROVE

## Why
The preview-row dim is removed in `_bind_row`, so every row uses white modulate. Front-row affordance is unchanged (cyan rim). All three round-1 reviews are PASS with no real problems, and `git merge-tree` reports no conflicts. The diff is small and presentation-only.

## Acceptance criteria
1. The dim colour grep returns nothing: met. I grepped scripts/ and tests/ and found no matches. The diff shows the single line changed to white.
2. c004 tile visual suite passes with the new canonical-colour assertion: met. build.md reports 17/17, and the tests reviewer re-ran it.
3. c001 gameplay suite passes with the updated preview-rows check: met. build.md reports 14/14, and the tests reviewer re-ran it.
4. Reverting the change makes the new assertion fail: met. build.md reports a revert run with 2 fails.
5. Capture PNG at 1080x2160 showing all rows in the original colours: met. The PNG and capture script are in evidence/, and the probe log shows modulate white on every row. I did not open the PNG myself.
6. Other supply suites still pass: met per build.md (static_shell, m23, m24, r01_visual).
7. `git diff --check` is clean and the diff stays in scope: met. The two extra test files that also asserted or copied the dim are justified in build.md.
