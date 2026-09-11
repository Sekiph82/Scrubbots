# M20-C001 — Final Direct-Assertion Audit Criteria V11

Canonical tracker: root `TASKS.md` only.

Production is immutable. V11 closes only the direct-evidence defects frozen in `CHATGPT_AUDIT_V10.md`.

## Governance / scope
1. `CHATGPT_AUDIT_V10.md` exists before V11 execution.
2. V11 prompt and criteria exist before V11 execution.
3. accepted production basis remains commit `e189ee8bd2b9be68b876cfdb18377622ed3ce832`.
4. loop blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa`.
5. dispatcher blob remains `eee10149e4f116af6706beec832042352bf3a6dd`.
6. no committed V11 `scripts/**` change.
7. no M21 behavior.
8. no scoring/win/lose/session/economy behavior.
9. no slot queue/cooldown/consumption behavior.
10. all SB-M20-001..014 remain open for ChatGPT closure.
11. progress remains 290/719 main+ui and 290/943 overall.
12. `lastCompletedTaskId` remains M19-C001-V06.
13. V11 tracker IN_PROGRESS transition is pushed before any V11 test/smoke edit.
14. owner/local work is preserved.
15. no `.hiveai` live tracker is recreated.
16. Claude assigns no independent audit verdict.

## G-V10-01 — drain-time activation exact side-effect snapshot
17. use a fresh healthy two-target arrangement.
18. create one real assignment A before arrival drain.
19. arrange a hook that runs while the A arrival transaction is actively draining.
20. immediately before the inner `activate_slot()`, capture next-owner id.
21. immediately before the inner call, capture dispatcher active count.
22. immediately before the inner call, capture exact reservation target->owner map.
23. immediately before the inner call, capture reservation count.
24. call inner `activate_slot()` from the active drain hook.
25. inner result is exactly `REENTRANT`.
26. immediately after the inner call returns, next-owner id equals its pre-inner value.
27. immediately after the inner call returns, active count equals its pre-inner value exactly.
28. immediately after the inner call returns, exact reservation target->owner map equals its pre-inner snapshot.
29. immediately after the inner call returns, reservation count equals its pre-inner value.
30. no proxy such as `<=` may substitute for exact equality.
31. no unused baseline variable is accepted as evidence.
32. outer A arrival completes normally.
33. A clears exactly once.
34. after drain completes, a later ordinary activation remains usable and clears B.

## G-V10-02 — missing-reservation dispatcher preservation
35. use a fresh real assignment.
36. remove only its reservation pair before authenticated-arrival preflight.
37. arrival result is `PREFLIGHT_REJECTED`.
38. cleared_count remains zero.
39. target remains ACTIVE.
40. dispatcher `has_owner(owner)` remains true immediately after rejection.
41. unrelated sentinel truth remains unchanged if arranged.

## G-V10-03 — candidate-null exact preservation
42. use a fresh real assignment.
43. candidate index is rebound to null before arrival preflight.
44. arrival result is `PREFLIGHT_REJECTED`.
45. exact `target -> owner` reservation remains.
46. exact `owner -> target` reservation remains.
47. dispatcher assignment remains pending.
48. cleared_count remains zero.
49. BoardState target remains expected ACTIVE.

## G-V10-04 — externally-CLEARED exact preservation
50. use a fresh real assignment.
51. externally set its target to CLEARED before arrival preflight.
52. arrival result is `PREFLIGHT_REJECTED`.
53. M20 cleared_count remains zero.
54. exact `target -> owner` reservation remains.
55. exact `owner -> target` reservation remains.
56. dispatcher assignment remains pending.
57. the test does not claim M20 cleared the already-external CLEARED state.

## G-V10-05 — reservation rollback reverse identities
58. arrange the current pair plus at least one unrelated reservation pair.
59. before the fault, capture full exact target->owner map/count.
60. before the fault, capture `get_target_for_owner(current_owner)`.
61. before the fault, capture `get_target_for_owner(unrelated_owner)` for every unrelated arranged owner.
62. capture BoardState snapshot.
63. capture dispatcher active/current-owner identity.
64. run reservation mutate-before-false fault.
65. outcome is `RESERVATION_ROLLBACK` or `ROLLBACK_FAILED`.
66. if `RESERVATION_ROLLBACK`, exact target->owner map/count matches prestate.
67. if `RESERVATION_ROLLBACK`, current owner->target matches prestate.
68. if `RESERVATION_ROLLBACK`, every unrelated owner->target matches prestate.
69. if `RESERVATION_ROLLBACK`, BoardState matches prestate.
70. if `RESERVATION_ROLLBACK`, dispatcher active/current-owner state matches prestate.
71. a redundant `get_owner(unrelated_target)` check does not substitute for unrelated `get_target_for_owner(unrelated_owner)`.

## G-V10-06 — truthful traceability
72. `CLAUDE_LOG_V11.md` exists.
73. log names the exact V11 test/helper assertions used for G-V10-01..05.
74. log records actual runtime result for each group.
75. log distinguishes root-suite versus frame-smoke evidence where applicable.
76. log does not claim an invariant that is not directly asserted by source.
77. log records Godot version.
78. log records exact full-suite total/pass/fail.
79. log records each required lifecycle smoke result individually.
80. log records exact changed files.
81. log records final production blobs.
82. log records `git diff e189ee8 -- scripts/` result.
83. log is committed and pushed to `main`.
84. final remote GitHub blob URL for `CLAUDE_LOG_V11.md` resolves.
85. Claude's final user-facing response includes the direct GitHub blob URL, not only a local path.

## Final regression / handoff
86. all prior M19 tests remain enabled.
87. all prior M20 V01-V10 tests remain enabled.
88. full root suite passes.
89. queue-free smoke passes.
90. V04 lifecycle smoke passes.
91. V05 lifecycle smoke passes.
92. V07 lifecycle smoke passes.
93. V08 lifecycle smoke passes.
94. V09 lifecycle smoke passes.
95. V10 lifecycle smoke passes.
96. any V11 smoke created passes.
97. final outputs inspected for literal `SCRIPT ERROR`.
98. final outputs inspected for literal `Parse Error`.
99. `git diff --check` clean.
100. no docs change unless ChatGPT explicitly authorized it.
101. final loop blob equals locked blob.
102. final dispatcher blob equals locked blob.
103. committed `scripts/**` diff versus e189ee8 is empty.
104. final clean tracker is `M20-C001-V11 / AWAITING_AUDIT / CHATGPT`.
105. progress remains 290/719 and 290/943.
106. `lastCompletedTaskId` remains M19-C001-V06.
107. SB-M20-001..014 remain open for ChatGPT closure.
108. validation/log/tracker changes are pushed and remote verified.
109. any newly exposed production defect causes BLOCKED with no production fix.

Total numbered criteria: **109**.