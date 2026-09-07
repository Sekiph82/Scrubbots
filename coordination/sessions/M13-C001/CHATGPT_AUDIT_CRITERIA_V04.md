# M13-C001 — Strict Audit Criteria V04

## bind/null and lifecycle category
1. fresh bind(null) returns false safely;
2. bind(null) after valid bind neutralizes;
3. no stale candidates after bind(null);
4. has/count/color-ids fail closed after bind(null);
5. is_bound_to(old board) false after bind(null);
6. valid bind recovers after bind(null);
7. real BoardState accepted;
8. RefCounted traversal spy accepted;
9. canonical malformed-board RefCounted double accepted;
10. plain RefCounted without API rejected;
11. Node without API rejected;
12. method-compatible Node rejected OR full external-free lifecycle is directly fail-closed.

## transactional build return contract
13. wrong-type get_cell_count rejected;
14. negative get_cell_count rejected;
15. is_valid_index non-bool rejected;
16. is_valid_index false inside declared scan range rejected;
17. get_cell_state non-int rejected;
18. unknown state rejected;
19. ACTIVE get_color_id non-int rejected;
20. ACTIVE get_color_id negative rejected;
21. late-index malformed return cannot commit earlier partial buckets;
22. every malformed build case leaves unbound/empty;
23. valid compatible build remains exact.

## sync live dependency drift
24. healthy invalid index returns false without destroying valid cache;
25. is_valid_index non-bool drift neutralizes;
26. state non-int drift neutralizes;
27. ACTIVE color non-int drift neutralizes;
28. ACTIVE color negative drift neutralizes;
29. CLEARED color non-int drift neutralizes;
30. CLEARED color negative drift neutralizes;
31. every malformed sync case returns false;
32. every malformed sync case leaves is_bound false;
33. every malformed sync case leaves public candidate truth empty;
34. canonical restoration + valid bind/rebind recovers.

## preserved F-M13-STRICT-002
35. state 2 sync fails closed;
36. state -1 sync fails closed;
37. state 255 sync fails closed;
38. state 99 sync fails closed;
39. unknown state never maps silently to CLEARED;
40. initial build unknown state fails transactionally;
41. rebuild unknown state fails transactionally;
42. unknown-state failure exposes no stale candidate truth;
43. canonical restoration recovers.

## preserved F-M13-STRICT-003
44. Array exclusion supported;
45. PackedInt32Array exclusion supported;
46. Dictionary-key exclusion supported;
47. null no-exclusion contract preserved;
48. unsupported exclusion containers fail closed;
49. float 2.0 cannot exclude int 2;
50. String "2" cannot exclude int 2;
51. invalid entry classes have no effect;
52. duplicate/negative/out-of-range integers remain harmless;
53. all three query APIs share exclusion semantics;
54. malformed exclusion cannot mutate cache;
55. real ReservationState PackedInt32Array consumer remains correct.

## canonical M13 regression
56. unbound queries safe;
57. exact color grouping;
58. ACTIVE/CLEARED sync exact;
59. repeated sync no duplicate;
60. cross-color isolation;
61. valid rebuild;
62. valid rebind;
63. exhausted/last-candidate behavior;
64. detached candidate/color-id results;
65. deterministic ordering;
66. rectangular correctness;
67. 59x59/3481 correctness;
68. no-rescan sensitivity remains green;
69. indexed vs naive agreement;
70. no reservation ownership/reachability/selector/routing/dispatch/agent leakage;
71. BoardState source unchanged;
72. FOUNDATION-STRICT-001 remains separate.

## validation/governance
73. full Godot 4.7.1 root suite passes;
74. git diff --check clean;
75. governance untouched;
76. matching CLAUDE_LOG_V04 exists;
77. Claude does not self-audit;
78. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M13-001
- SB-M13-004
