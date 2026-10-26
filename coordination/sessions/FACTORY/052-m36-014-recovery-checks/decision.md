APPROVE

## Why
All three round-1 reviews are PASS. The change is additive: a pure `recovery_component_checks` function, a new key in the playtest output, a new suite, and docs/10 section 13 text. There are no config changes and no merge conflicts. I re-ran the new suite and it passed.

## Acceptance criteria
1. Suite exits 0 with the PASS line: met. I re-ran it and got `M36_RECOVERY_COMPONENT_CHECKS PASS (26 cases, 0 fail)`.
2. Synthetic fixtures for every rule: met. The run output shows the boundary and strictness cases, and build.md lists the full set.
3. Committed evidence files hold componentChecks equal to a recomputation: met per build.md (suite s02). The reviews found no contrary evidence.
4. Additive-only default output: met per build.md. The diff is +55/-1 per file; the single removed line is `recovery.note` gaining a trailing comma. Anomaly counts are unchanged.
5. The three playtest modes exit 0 and write componentChecks: met per build.md.
6. Informational L1..L10 results recorded: met. They are reported only and nothing was tuned.
7. Regression suites: met per build.md (six suites pass).
8. `data/config` untouched, `git diff --check` clean, docs/10 section 13 updated: met. The `data/config` diff against `origin/main...HEAD` is empty, and the diffstat shows docs/10 changed.
