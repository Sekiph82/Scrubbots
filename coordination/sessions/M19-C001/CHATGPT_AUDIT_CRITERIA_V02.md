# M19-C001 — Frozen Strict Audit Criteria V02

## Fresh bind dependency boundary
1. real BoardState accepted;
2. scalar board rejected safely;
3. selector null/scalar/junk rejected safely;
4. reservation null/scalar/junk rejected safely;
5. routing-system null/scalar/junk rejected safely;
6. routing-access null/scalar/junk rejected safely;
7. select-access null/scalar/junk rejected safely;
8. partial dependency objects rejected before escaped calls;
9. failed fresh bind leaves dispatcher unbound/empty;
10. optional default parent/factory path remains valid.

## Exact bundle coherence
11. selector exact-bound to dispatcher board;
12. selector uses exact dispatcher ReservationState;
13. ReservationState exact-bound to board;
14. routing_access exact-bound to board;
15. select_access exact-coherent with board/routing/access bundle;
16. same-size different-board bundle rejected;
17. mixed reservation bundle rejected;
18. mixed routing/select-access bundle rejected.

## Ordinary repeated bind
19. same-bundle second bind false;
20. different valid bundle second bind false;
21. null/malformed second bind false;
22. original bound flag preserved;
23. original bundle identity preserved;
24. active assignment count preserved;
25. owner->target reservation preserved;
26. active agent identity preserved.

## Live coherence drift
27. reservation rebind drift blocks next dispatch before new reservation;
28. selector drift blocks next dispatch;
29. routing-access drift blocks next dispatch;
30. select-access bundle drift blocks next dispatch;
31. drift failure leaves prior active assignments intact.

## ProductionTargetAccess boundary
32. malformed routing system fails closed;
33. malformed routing access fails closed;
34. malformed/non-BoardState board fails closed;
35. non-finite origin fails closed and clears memo;
36. invalid target index false;
37. malformed route Variant false;
38. wrong-target success route false;
39. invalid route geometry false;
40. valid exact validated route true;
41. failed probe clears stale memo;
42. set_origin clears memo;
43. consume exact successful route works once;
44. second consume returns null;
45. wrong-index consume returns null.

## Dispatcher route validation
46. null route -> ROUTE_FAILED + release;
47. scalar/junk route -> ROUTE_FAILED + release;
48. failure RouteResult -> ROUTE_FAILED + release;
49. wrong-target success -> ROUTE_FAILED + release;
50. wrong-start route -> ROUTE_FAILED + release;
51. wrong-end route -> ROUTE_FAILED + release;
52. non-finite/invalid geometry -> ROUTE_FAILED + release;
53. valid exact RouteResult accepted;
54. no malformed route reaches agent creation;
55. no route failure retargets.

## Agent factory / parent
56. default factory produces valid agent;
57. null/scalar/RefCounted/arbitrary Node product rejected safely;
58. parented ScrubbotAgent rejected without freeing/mutating foreign agent;
59. MOVING agent rejected;
60. ARRIVED agent rejected;
61. CANCELLED agent rejected;
62. valid fresh unparented ScrubbotAgent accepted;
63. invalid factory product releases reservation;
64. invalid product creates no dispatcher child;
65. explicit valid agent_parent works;
66. freed parent before dispatch fails cleanly;
67. queued-for-delete parent handled fail-closed where reproducible.

## Request validation
68. negative color invalid before selector;
69. start x/y NaN invalid;
70. start x/y +INF invalid;
71. start x/y -INF invalid;
72. speed NaN invalid;
73. speed +INF invalid;
74. speed -INF invalid;
75. speed zero invalid;
76. speed negative invalid;
77. invalid request makes no selector/reservation/route/factory side effect;
78. invalid request does not advance owner counter;
79. finite positive speed succeeds.

## Re-entry / reset generation
80. recursive dispatch rejected cleanly;
81. recursive dispatch creates no duplicate owner/reservation;
82. reset during select-access callback cancels pending flow;
83. reset during routing callback releases pending reservation;
84. reset during factory callback releases pending reservation;
85. reset during assign callback leaves no pending assignment;
86. add-child lifecycle reset case handled where reproducible;
87. every reset-during-dispatch case returns RESETTING/CANCELLED;
88. no pending _active entry after reset interruption;
89. no orphan child after reset interruption;
90. BoardState unchanged through interruptions;
91. later dispatch recovers;
92. owner counter remains monotonic/no collision;
93. sequential rapid calls still supported.

## Completion identity
94. correct completion marks arrived;
95. repeated correct completion idempotent;
96. wrong target ignored;
97. wrong color ignored;
98. wrong owner ignored;
99. wrong/stale agent source ignored;
100. post-reset stale completion cannot recreate state;
101. completion does not clear BoardState;
102. completion does not release successful reservation.

## Ordinary M19 regression
103. no raw candidate -> zero spawn;
104. unreachable raw candidate -> zero spawn;
105. reachable target selected/reserved;
106. exactly one agent per success;
107. unique owner ids;
108. duplicate target prevention;
109. independent targets dispatch independently;
110. ordinary route failure releases;
111. ordinary assign failure releases/no orphan;
112. failed target reusable;
113. reset committed agents/releases reservations;
114. reset leaves BoardState unchanged;
115. new dispatch after reset;
116. 5-slot burst;
117. rapid 25+ sequential stress;
118. real production pipeline reachable success;
119. real enclosed target no-work;
120. real 59x59 coverage;
121. rectangular Very Hard coverage;
122. M15-M18 strict regressions remain green.

## Architecture / governance
123. no M20 BoardState clearing;
124. no successful-arrival reservation resolution;
125. no scoring/progression;
126. no routing algorithm moved into dispatcher;
127. no target-selection algorithm moved into dispatcher;
128. no pooling introduced without evidence;
129. full Godot 4.7.1 root suite passes;
130. git diff --check clean;
131. tasks/H!veAI/index/controller governance untouched;
132. matching CLAUDE_LOG_V02 exists;
133. Claude does not self-audit;
134. ChatGPT records independent Godot rerun availability.

If all pass, because M19 is critical/stateful and ChatGPT cannot independently
run Godot, ChatGPT should normally issue an auditor-authored validation-only V03
before final closure unless V02 itself contains the full adversarial matrix with
direct sensitivity sufficient to serve as that stage.

Final-close candidates:
- SB-M19-001..012
