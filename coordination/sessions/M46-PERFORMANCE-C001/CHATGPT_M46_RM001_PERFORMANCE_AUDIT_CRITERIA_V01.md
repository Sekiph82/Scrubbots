# M46-RM-001 | ChatGPT Audit Criteria V01
Evidence modes: DIRECT_TEST, SENSITIVITY, LOG_GOVERNANCE, OWNER_GATE. Frozen source baseline R07 `76e4aff8`, audit `CHATGPT_M46_FULL_SURFACE_REAUDIT_V01.md`. **No replacement of E3 by Claude self-assessment.**

| Criterion | Mandatory observable/fail-closed behavior |
|---|---|
| RM001-01 [DIRECT_TEST] | All original `p01..p22` remain present and exercise M46-001..015 as scoped; exact case ledger proves no silent skip. |
| RM001-02 [DIRECT_TEST/SENSITIVITY] | M46-011 detects **transient repeated allocations** when total retained object count returns to baseline, or explicitly fails with `UNPROVEN` and concrete reason (never falsely relabel net growth as allocation throughput). A deliberately injected test-only allocation pulse triggers failure for this criterion. |
| RM001-03 [DIRECT_TEST/SENSITIVITY] | M46-014 high-density threshold is supported by real p13 overlap measurements and fails when peak is substantially reduced. Distinct from p07 200 synthetic agents and from "number of batches". |
| RM001-04 [DIRECT_TEST] | p13/p16/p17/p18/p20 actual full 59x59 WON, 5/6 slots and WAITING, correct 3025/456 and 3481 counts, real routing, 0 duplicated reservations. |
| RM001-05 [DIRECT_TEST] | Mean <=4.0ms, p99 <=16.7ms baseline as previously accepted, one-off max explicitly logged; CPU contention/benchmark selection controlled, no weakening or inferred phone/GPU FPS. |
| RM001-06 [DIRECT_TEST] | 30 restarts node/object/static bounds, cold-vs-warm memory truth, +59x59 board-only delta <=8MiB; reset and idle behavior tests do not count preexisting engine asset caches as leaks. |
| RM001-07 [DIRECT_TEST] | M46-015 plugin FULL/REDUCED ownership, timers, 0 per-cell plugin, 0 leftovers; state GFF production Node2D limitation, not fake plugin activity. |
| RM001-08 [LOG_GOVERNANCE] | One **complete** 22/22 post-R07 suite run and actual process exit 0 at a pinned final SHA. Subset run, even with intended ledger FAIL, cannot close this criterion. Retest only changed tests; no Actions. |
| RM001-09 [SENSITIVITY] | A test-only negative control for each new load-bearing assertion demonstrably fails, and control instrumentation is fully reverted before final source commit. |
| RM001-10 [OWNER_GATE] | R06/R07 F5 visuals, Android/iPhone GPU and cloud CI remain open; no false PASS and no unauthorized Actions. |
| RM001-11 [LOG_GOVERNANCE] | Claude log exact commands, SHA, expected/actual and test exit; no Claude root TASKS.md writes or invented CHATGPT_AUDIT; preserve owner files. |

Mark each PASS/FAIL/NOT_RUN and why. Any new true code defect triggers **stop, document, hand back for whole-sprint reauditing**, not unilateral new issue-specific code remediation.