APPROVE

## Why
All three round-1 reviews are VERDICT PASS. The merge-tree against origin/main is conflict-free. The change is presentation-only: it reuses the existing meta_ui seen-set, adds no schema bump, and adds no new art. I re-ran the new suite in the worktree as a spot-check.

## Acceptance criteria
1. Frontier walk (NEW list): met. build.md documents the spec's internal conflict (frontier 7 empty vs daily included) and tests the consistent reading.
2. Visit clears NEW: met (visit_clears and home_ui cases).
3. Persistence across save and reload: met.
4. Grandfathered profiles show no NEW: met.
5. Legacy snapshots load without error: met.
6. Locked entries never show NEW or mark visited: met.
7. Home UI shows NEW, a count wins over NEW, and pressing hides it: met.
8. Suite ends with a PASS line and exit 0: met (spot-checked locally).
9. Regression suites: met per build.md (14 suites LOCAL_PASS).
10. docs/16 section, TASKS ticks, clean diff check: met per the diff stat.
