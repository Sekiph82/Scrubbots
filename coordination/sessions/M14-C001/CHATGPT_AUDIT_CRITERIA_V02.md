# M14-C001 — Frozen Strict Audit Criteria V02

## Initial dependency bind
1. int board rejected safely;
2. String board rejected safely;
3. Vector2 board rejected safely;
4. Array/Dictionary board rejected safely;
5. plain RefCounted rejected;
6. partial API RefCounted rejected;
7. bare Node rejected;
8. method-compatible Node rejected;
9. wrong-type count rejected;
10. negative count rejected;
11. zero count accepted/documented;
12. 3481 count accepted;
13. 3482 count rejected;
14. 1,000,000 count rejected;
15. huge positive count rejected;
16. over-max rejection performs no per-cell board calls;
17. failed initial binds stay unbound/empty;
18. successful bind stores exact board identity/domain.

## Ordinary bind re-entry
19. same-board second bind returns false;
20. different-valid-board bind returns false;
21. null second bind returns false;
22. scalar second bind returns false;
23. partial second bind returns false;
24. method-compatible Node second bind returns false;
25. every second-bind case preserves original is_bound/is_bound_to;
26. every second-bind case preserves all target->owner mappings;
27. every second-bind case preserves all owner->target mappings;
28. every second-bind case preserves count and sorted reserved indices.

## Explicit rebind
29. valid rebind B clears A reservations;
30. valid rebind installs B identity/domain;
31. B reserve succeeds after rebind;
32. same-board rebind intentionally clears reservations;
33. rebind(null) clears old truth and leaves unbound;
34. malformed scalar rebind clears old truth and leaves unbound;
35. partial/malformed RefCounted rebind clears old truth and leaves unbound;
36. oversized-count rebind clears old truth and leaves unbound;
37. failed rebind stores no malformed board;
38. later valid bind/rebind recovers after failed rebind.

## reserve dependency truth
39. target -1 rejected before per-cell board calls;
40. target == stored count rejected before per-cell board calls;
41. large out-of-domain target rejected before per-cell board calls;
42. out-of-domain reserve preserves existing maps;
43. in-domain is_valid_index true can proceed;
44. in-domain is_valid_index false rejects without map mutation;
45. non-bool is_valid_index rejects without map mutation;
46. ACTIVE state valid reserve works;
47. CLEARED state rejected;
48. state 2 rejected;
49. state -1 rejected;
50. state 255 rejected;
51. state 99 rejected;
52. non-int state rejected;
53. every dependency-validation failure preserves existing reservations.

## mirrored ownership
54. valid reserve inserts both map directions;
55. duplicate target other owner rejected;
56. duplicate target same owner rejected;
57. one owner cannot hold second target;
58. independent owners/targets succeed;
59. failed reserve preserves both map directions;
60. wrong-owner release fails/no mutation;
61. correct release removes both directions;
62. repeated release fails/no mutation;
63. released target and owner reusable;
64. release_for_owner unknown owner false/no mutation;
65. release_for_owner valid removes both directions;
66. release_for_owner preserves sibling reservations;
67. repeated release_for_owner false;
68. release_for_owner target/owner reusable;
69. wrong-owner resolve false/no mutation;
70. correct resolve removes exactly once;
71. second resolve false;
72. resolve_arrival does not mutate BoardState.

## reset/query/encapsulation
73. reset clears all reservations;
74. reset keeps board identity/domain;
75. repeated reset harmless;
76. reserve works after reset;
77. invalid is_reserved queries false;
78. invalid/unreserved get_owner -> -1;
79. invalid/unknown get_target_for_owner -> -1;
80. reservation count exact through mixed operations;
81. reserved indices deterministic ascending;
82. reserved-index result detached across repeated calls;
83. snapshot mutation cannot mutate internal ownership;
84. no internal dictionary getter exposed.

## integration/performance/architecture
85. get_reserved_indices remains PackedInt32Array;
86. M13 exclusion seam works with reservation snapshot;
87. release/release_for_owner restores candidate visibility;
88. M13 remains reservation-agnostic;
89. M15 TargetSelector root regressions remain green;
90. real 59x59/3481 bind/reserve/release works;
91. no reserve/release/query full-board scan introduced;
92. BoardState CellState remains exactly ACTIVE/CLEARED;
93. ReservationState does not mutate BoardState;
94. no target-selection/reachability/routing/agent/dispatcher responsibility added;
95. BoardState source unchanged;
96. FOUNDATION-STRICT-001 remains separate.

## Validation/governance
97. full Godot 4.7.1 root suite passes;
98. git diff --check clean;
99. governance untouched;
100. matching CLAUDE_LOG_V02 exists;
101. Claude does not self-audit;
102. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M14-001
- SB-M14-004
- SB-M14-007
- SB-M14-009
