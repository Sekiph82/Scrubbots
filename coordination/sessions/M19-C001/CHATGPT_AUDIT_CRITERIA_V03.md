# M19-C001 — Strict-v2 Closure Criteria V03

## H!veAI start
1. synced canonical task is M19-C001-V03;
2. starting actor is CLAUDE;
3. starting workflow authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. CHANGES_REQUIRED -> IN_PROGRESS tracker transition is pushed before production edits;
6. matching hiveai-event/v1 start event exists.

## Mandatory select-access coherence
7. select_access missing is_targetable rejected;
8. select_access missing is_coherent_with rejected;
9. coherence non-bool rejected;
10. coherence false rejected;
11. exact coherent ProductionTargetAccess accepted;
12. exact coherent AccessQueryDouble accepted;
13. same-shape different select bundle rejected.

## RefCounted collaborator lifecycle
14. selector method-compatible Node rejected;
15. ReservationState method-compatible Node rejected;
16. RoutingSystem method-compatible Node rejected;
17. routing_access method-compatible Node rejected;
18. select_access method-compatible Node rejected;
19. canonical RefCounted dependencies remain accepted;
20. agent_parent valid Node remains supported.

## Re-entry guard ordering
21. recursive dispatch from selector coherence callback -> REENTRANT;
22. recursive dispatch from reservation coherence callback -> REENTRANT;
23. recursive dispatch from routing-access coherence callback -> REENTRANT;
24. recursive dispatch from select-access coherence callback -> REENTRANT;
25. each coherence recursion creates no reservation;
26. each coherence recursion makes no route/factory side effect;
27. each coherence recursion does not advance owner id;
28. reset during coherence -> RESETTING;
29. reset during coherence prevents selection;
30. guard clears after coherence abort;
31. later dispatch recovers.

## Immediate generation checks
32. reset during set_origin -> RESETTING;
33. set_origin reset prevents selector call;
34. set_origin reset creates no reservation;
35. reset during consume_route -> RESETTING;
36. consume reset prevents fresh routing compute;
37. consume reset releases pending reservation;
38. no pending active entry after either reset;
39. no orphan agent after either reset;
40. later dispatch recovers;
41. owner ids remain monotonic.

## Mid-dispatch bundle drift
42. reservation drift during selection/access detected;
43. routing-access drift during routing callback detected;
44. select-access drift during callback detected;
45. selector/bundle drift during callback detected where supported;
46. factory-phase reservation/bundle drift detected;
47. assign-phase reservation/bundle drift detected;
48. drift after pending reservation aborts before active commit;
49. rollback removes current pending reservation when still owned;
50. prior committed active assignments survive pending-drift failure;
51. no orphan agent after drift;
52. later coherent dispatcher/dispatch recovers.

## Cached-route distinction
53. null cached route permits fresh compute;
54. non-null scalar/junk cached route -> ROUTE_FAILED;
55. cached failure RouteResult -> ROUTE_FAILED;
56. cached wrong-target route -> ROUTE_FAILED;
57. cached wrong-start route -> ROUTE_FAILED;
58. cached wrong-end route -> ROUTE_FAILED;
59. cached non-finite route -> ROUTE_FAILED;
60. every non-null invalid cached route releases reservation;
61. every non-null invalid cached route performs ZERO fresh routing compute;
62. every non-null invalid cached route creates zero agent;
63. valid cached route succeeds;
64. valid cached route skips redundant compute.

## Explicit factory Callable drift
65. intentionally empty/default factory still works;
66. explicit valid Callable works;
67. explicit factory target freed after bind makes Callable invalid;
68. invalidated explicit factory does NOT fall back to default agent;
69. invalidated explicit factory -> AGENT_ASSIGN_FAILED;
70. invalidated explicit factory releases reservation;
71. invalidated explicit factory creates no child/active entry.

## assign postconditions
72. canonical agent assign true + MOVING accepted;
73. assign true but agent remains UNASSIGNED rejected;
74. assign true but wrong owner identity rejected;
75. assign true but wrong color identity rejected;
76. assign true but wrong target identity rejected;
77. assign true but self-parented/parented during assign rejected;
78. lying dispatcher-owned agent is freed;
79. lying agent failure releases reservation;
80. lying agent creates no active entry;
81. valid subclass remains accepted.

## Preserve V02 F-M19-STRICT-001
82. fresh malformed dependencies fail closed;
83. exact board/selector/reservation bundle coherence;
84. routing_access exact-board coherence;
85. repeated ordinary bind preserves active assignment;
86. pre-dispatch live sibling drift fails before new reservation.

## Preserve ProductionTargetAccess
87. malformed routing system/access/board false;
88. non-finite origin fail closed;
89. invalid target false;
90. wrong-target route false;
91. invalid geometry false;
92. valid exact route true;
93. failed probe clears memo;
94. set_origin clears memo;
95. consume is one-shot.

## Preserve route/factory/parent V02
96. fresh null/junk/failure route rollback;
97. wrong-target/start/end/non-finite fresh route rollback;
98. no route failure retarget;
99. foreign parented/reused factory products not freed/mutated;
100. invalid factory product releases reservation;
101. valid explicit parent works;
102. freed/queued parent fails cleanly.

## Preserve request validation
103. negative color invalid;
104. start NaN/INF invalid;
105. speed NaN/+INF/-INF invalid;
106. speed zero/negative invalid;
107. invalid request makes zero downstream side effect;
108. invalid request does not advance owner id;
109. finite positive request succeeds.

## Preserve reset/completion
110. routing reset injection rollback;
111. factory reset injection rollback;
112. assign reset injection rollback;
113. no pending active/orphan after reset interruption;
114. BoardState unchanged;
115. later dispatch recovery;
116. sequential rapid calls supported;
117. correct completion marks arrived;
118. repeated completion idempotent;
119. wrong target/color/owner ignored;
120. wrong source agent ignored;
121. stale post-reset completion ignored;
122. completion does not clear BoardState;
123. completion does not release success reservation.

## Production regression
124. no raw candidate -> zero spawn;
125. unreachable candidate -> zero spawn;
126. reachable target exactly one agent;
127. unique monotonic owner ids;
128. duplicate target prevention;
129. independent targets independent;
130. route/assign failure rollback;
131. failed target reusable;
132. reset committed agents/releases reservations;
133. 5-slot burst;
134. rapid 25+ sequential stress;
135. real ProductionTargetAccess + ProductionRoutingSystem success;
136. enclosed target no-work;
137. real 59x59 coverage;
138. rectangular Very Hard coverage;
139. M15-M18 strict regressions green.

## M20 / scope
140. no BoardState clear on completion;
141. no successful-arrival reservation resolution;
142. no scoring/slot progression/follow-up dispatch;
143. no routing algorithm moved into dispatcher;
144. no target-selection algorithm moved into dispatcher;
145. BoardState/ReservationState/routing algorithm/ScrubbotAgent core unchanged.

## Validation / H!veAI final
146. full Godot 4.7.1 root suite passes;
147. git diff --check clean;
148. root tasks.md completion truth untouched by Claude;
149. ChatGPT audit/index/controllers/CHATGPT_* untouched;
150. legacy H!veAI trackers not refreshed;
151. matching CLAUDE_LOG_V03 exists;
152. final canonical tracker workflowState AWAITING_AUDIT;
153. final requiredActor CHATGPT;
154. final currentTaskId M19-C001-V03;
155. final progress remains 278/719 = 38.66%;
156. lastCompletedTaskId not advanced;
157. final blockers empty on success;
158. matching IN_PROGRESS -> AWAITING_AUDIT hiveai-event/v1 exists;
159. implementation/log/tracker event are pushed to origin/main;
160. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
161. Claude does not self-audit;
162. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
163. genuine blocker uses canonical BLOCKED state/event;
164. ChatGPT records independent Godot rerun availability.

If all criteria pass, ChatGPT may final-close:
- SB-M19-001..012
