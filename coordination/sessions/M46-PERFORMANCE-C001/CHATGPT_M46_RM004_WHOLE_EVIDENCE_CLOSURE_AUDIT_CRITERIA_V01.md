# M46-RM-004 — ChatGPT Audit Criteria V01
Applies to frozen V02 finding V2-P2/P3/P4/P5/P6, `CHATGPT_M46_FULL_SURFACE_REAUDIT_V02.md`, and `CHATGPT_M46_RM002_AUDIT_CRITERIA_CLARIFICATION_V02.md`. Each class must have **direct test evidence** or explicit OPEN explanation. Don't invent E3 from Claude green suites.

| Criterion | Direct, fail-closed acceptance |
|---|---|
| RM004-01 | Four canonical boosters, actual 59x59 + 5/6/winding/pocket; **each** legal/illegal branch with exact pre/post SB/charge/slot/FIFO/board/receipt state and rollback fault; no real payment or save. |
| RM004-02 | True WON and LOSE terminal, paused, unknown batch/target, popup cancel/reopen, no second purchase/use/receipt; partial mutation error never consumes resources; explicit infeasibility documented if LOSE not reproducible. |
| RM004-03 | Real `detached_copy()==null` and malformed supply/slot/board/test input triggered, 400ms owner fallback bounded when it runs, no null/classifier wrong-success, no spend; prevent a script error/early return from counting PASS. |
| RM004-04 | Independent positive completed current-state proof under actual DeadlockClassifier vs Random/Selector authorization; `UNKNOWN_BOUND`/deadline/cancel/crash cannot authorize or spend, with 92-id equivalence where relevant; **do not demand impossible iff safe under a timeout**. |
| RM004-05 | True worker null/crash and real time budget can be distinguished in internal proof provenance (test-visible, not necessarily user text); external UI/economy policy remains fail-closed in BOTH, identical 400ms/5s/cached timeout; no endless recheck or telemetry network. If instrumentation deferred, classify NOT_VERIFIED. |
| RM004-06 | Actual 59x59 partial 5-second Selector popup, chip-by-chip keys compared with proven safe IDs/exact current state; no unproven clickable target, no false charge, no implicit demand to reveal all 92. |
| RM004-07 | Retry/host exit/route Home/next-level modal interaction with job running, canceled, completed, repeated callbacks, stale keys, both bought and earned charges; no after-free callback or unjoined worker and no sb double-use. |
| RM004-08 | Cold Results first show attributed separately from steady gameplay, FX, popup rebuild and deferred Random use. p12 49ms near cap investigated with bounded repeat/no threshold relaxation; log p16 ~614ms worst outlier and machine contention but do not invent an optimization. |
| RM004-09 | Owner-local `project.godot` extra autoload and `main.tscn` resave read-only parity cited, no modification; if clean-indexed runtime parity impossible under owner restrictions OPEN accurately, not blanket PASS. |
| RM004-10 | New test cases assert every mandatory branch and sensitivity mutation catches incorrect authorization/charge/chips/cancel. Final production restores exactly with GitHub diff vs frozen baseline and no test markers; subtests can't pass after early error. |
| RM004-11 | Sequential affected regression, master pinned full M46 22/22 final source SHA and true exit 0; <=4 mean / <=16.7 p99 per existing desktop gates, p12 <=50.1, no hidden warning/skip; if timings contended, state limits accurately. |
| RM004-12 | Need-a-Hand owner reserve, R06/R07 F5, phone GPU and cloud CI still OPEN; no GitHub Actions, no billable runner or APK, no owner files/saves/stashes overwritten, Claude doesn't write TASKS, ChatGPT independent audit follows. |

Check one-to-one source/test/log criteria and label SOURCE_PROOF, DIRECT_TEST, SENSITIVITY, LOG_GOVERNANCE, OWNER_GATE. No false milestone closure with missing RM002 criteria, and if new production code defect discovered STOP for full-sprint auditor sweep.
