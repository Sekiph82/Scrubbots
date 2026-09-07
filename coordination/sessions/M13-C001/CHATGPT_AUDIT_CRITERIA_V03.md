# M13-C001 — Frozen Strict Audit Criteria V03

## Dependency boundary
1. int board rejected without fault;
2. String board rejected without fault;
3. Vector2 board rejected without fault;
4. RefCounted junk board rejected without fault;
5. partial API board rejected without fault;
6. wrong get_cell_count return rejected;
7. wrong get_cell_state return rejected;
8. wrong get_color_id return rejected;
9. malformed initial bind leaves unbound empty truth;
10. no malformed bind commits partial buckets;
11. valid compatible BoardState/traversal spy bind still succeeds;
12. malformed bind after valid state cannot leave malformed/stale usable binding;
13. later valid bind recovers;
14. valid rebind A->B replaces truth;
15. rebind(null) leaves safe unbound/empty;
16. malformed rebind leaves safe unbound/empty;
17. recovery after failed rebind succeeds.

## Transactional/canonical build
18. build validates every scanned index;
19. ACTIVE color id must be integer >=0;
20. malformed build return cannot partially commit buckets;
21. normal ACTIVE/CLEARED build truth remains exact.

## Unknown state
22. sync state 2 fails;
23. sync state -1 fails;
24. sync state 255 fails;
25. sync another unknown state fails;
26. unknown sync is not silently treated as CLEARED;
27. unknown sync cannot partially mutate unrelated buckets;
28. post-unknown public query truth is conservative/fail-closed;
29. initial build containing unknown state fails with no partial buckets;
30. rebuild containing unknown state fails;
31. failed unknown-state rebuild commits no partial rebuilt truth;
32. canonical-state restoration permits recovery.

## Exclusion container boundary
33. Array supported;
34. PackedInt32Array supported;
35. Dictionary-key set supported;
36. null behavior explicitly documented/tested;
37. int container fails closed;
38. float container fails closed;
39. String container fails closed;
40. bool container fails closed;
41. Vector2 container fails closed;
42. RefCounted container fails closed;
43. unsupported container cannot mutate cache.

## Exclusion entry boundary
44. valid integer exclusion works;
45. duplicate integer exclusions harmless;
46. negative integer exclusion has no effect;
47. out-of-range integer exclusion has no effect;
48. float 2.0 does not exclude integer index 2;
49. String "2" does not exclude integer index 2;
50. bool entry has no effect;
51. Vector2 entry has no effect;
52. RefCounted entry has no effect;
53. nested Array entry has no effect;
54. nested Dictionary entry has no effect;
55. Dictionary values ignored; keys define exclusions;
56. equivalent valid Array/PackedInt32Array/Dictionary exclusions agree;
57. get_candidates/has_candidates/count_candidates share semantics.

## Canonical cache regression
58. unbound queries safe;
59. color grouping exact;
60. valid ACTIVE matching-color candidate rule exact;
61. CLEARED sync removal;
62. ACTIVE restore/add exactly once;
63. cross-color isolation;
64. invalid sync index atomicity;
65. valid rebuild truth;
66. valid rebind drops stale board truth;
67. present/absent/exhausted/last-candidate semantics;
68. all/partial exclusion semantics;
69. exclusion removal re-exposes candidate;
70. get_candidates detached;
71. get_color_ids detached;
72. deterministic ordering;
73. rectangular-board correctness;
74. 59x59/3481 correctness;
75. steady-state no-rescan proof remains sensitivity-safe;
76. indexed vs naive result agreement.

## Immediate consumer / architecture
77. ReservationState PackedInt32Array exclusion path remains supported;
78. immediate real exclusion consumer result correct;
79. no reservation ownership added;
80. no reachability/TargetSelector/routing/dispatch/agent behavior added;
81. BoardState source unchanged in M13 cycle;
82. FOUNDATION-STRICT-001 remains separate/unresolved unless independently closed elsewhere.

## Validation/governance
83. full Godot 4.7.1 root suite passes;
84. git diff --check clean;
85. governance untouched;
86. matching CLAUDE_LOG_V03 exists;
87. Claude does not self-audit;
88. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M13-001
- SB-M13-004
