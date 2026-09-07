# M13-C001 — Strict Audit Criteria V05

## Indexed domain metadata
1. successful bind stores the same validated count used for transactional buckets;
2. stored count and buckets commit atomically;
3. neutralize clears stored domain metadata;
4. rebuild updates domain metadata only on successful transactional scan;
5. valid rebind to a different board updates count + buckets together.

## Healthy invalid vs drift
6. sync(-1) returns false and preserves healthy cache;
7. sync(index == stored_count) returns false and preserves healthy cache;
8. sync(large out-of-range) returns false and preserves healthy cache;
9. in-range is_valid_index false is treated as dependency contradiction;
10. in-range false sync neutralizes;
11. no stale candidates after in-range false drift;
12. has/count/color ids fail closed after in-range false drift;
13. is_bound_to(old board) false after in-range false drift;
14. non-bool is_valid_index drift still neutralizes;
15. valid bind/rebind recovers after drift.

## Production max count
16. 3481 canonical count accepted;
17. real 59x59 BoardState accepted;
18. 3482 count rejected;
19. 1,000,000 count rejected;
20. very large positive count rejected;
21. >3481 rejection occurs before per-cell traversal;
22. rejected oversized count leaves unbound/empty;
23. zero-count behavior is explicitly documented/tested.

## Preserved dependency contract
24. bind(null) after valid neutralizes;
25. RefCounted-only boundary preserved;
26. method-compatible Node rejected;
27. wrong-type count rejected;
28. negative count rejected;
29. non-bool is_valid_index build return rejected;
30. in-range false is_valid_index build return rejected;
31. non-int state rejected;
32. unknown state rejected;
33. non-int ACTIVE color rejected;
34. negative ACTIVE color rejected;
35. late malformed build commits no partial buckets;
36. live non-int state drift neutralizes;
37. live ACTIVE color non-int/negative drift neutralizes;
38. live CLEARED color non-int/negative drift neutralizes;
39. valid recovery preserved.

## F-M13-STRICT-002 regression
40. state 2 fails closed;
41. state -1 fails closed;
42. state 255 fails closed;
43. state 99 fails closed;
44. initial unknown-state build fails transactionally;
45. unknown-state rebuild fails transactionally;
46. no stale query truth after unknown-state failure;
47. canonical restoration recovers.

## F-M13-STRICT-003 regression
48. Array exclusion supported;
49. PackedInt32Array supported;
50. Dictionary-key exclusion supported;
51. null no-exclusion preserved;
52. unsupported containers fail closed;
53. float/String cannot coerce-exclude ints;
54. invalid entry classes have no effect;
55. duplicate/negative/out-of-range integer behavior preserved;
56. get/has/count share semantics;
57. malformed exclusion does not mutate cache;
58. real ReservationState PackedInt32Array consumer preserved.

## Canonical M13 regression
59. unbound safe queries;
60. exact grouping;
61. ACTIVE/CLEARED sync;
62. repeated sync no duplicate;
63. cross-color isolation;
64. valid rebuild;
65. valid rebind;
66. exhausted/last candidate;
67. detached result collections;
68. deterministic ordering;
69. rectangular correctness;
70. 59x59/3481 correctness;
71. no-rescan sensitivity;
72. indexed vs naive agreement;
73. no reservation/reachability/selector/routing/dispatch/agent leakage;
74. BoardState unchanged;
75. FOUNDATION-STRICT-001 remains separate.

## Validation/governance
76. full Godot 4.7.1 root suite passes;
77. git diff --check clean;
78. governance untouched;
79. matching CLAUDE_LOG_V05 exists;
80. Claude does not self-audit;
81. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M13-001
- SB-M13-004
