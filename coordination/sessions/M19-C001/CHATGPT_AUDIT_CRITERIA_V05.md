# M19-C001 — Transaction Boundary Audit Criteria V05

## H!veAI start ordering
1. canonical task is M19-C001-V05;
2. requiredActor is CLAUDE;
3. starting workflow authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. lastCompletedTaskId is M15-C002-V03;
6. CHANGES_REQUIRED -> IN_PROGRESS tracker/event is committed and pushed before ANY V05 production/test edit;
7. remote main is verified to contain the start transition before edits;
8. Claude log explicitly states no V05 production/test edit existed before successful start push;
9. machine/human tracker state agree.

## Pending-owner baseline bracketing
10. pending-owner baseline is captured untyped;
11. reset generation checked immediately after baseline callback;
12. malformed baseline return fails COHERENCE_FAILED;
13. baseline actual int other than -1 fails COHERENCE_FAILED;
14. exact bundle coherence is rechecked after baseline callback;
15. generation is rechecked immediately after baseline coherence;
16. reset during baseline returns RESETTING;
17. ReservationState drift during baseline returns COHERENCE_FAILED;
18. selector call count is zero after baseline reset;
19. selector call count is zero after baseline drift;
20. selector call count is zero after malformed baseline;
21. no route/factory/agent/active entry after baseline failure;
22. no owner id advance after baseline failure;
23. no new reservation after baseline failure.

## Canonical selector -1 owner-query boundary
24. actual-int -1 selector return remains canonical no-target candidate;
25. post--1 owner query is captured untyped;
26. reset generation checked immediately after post--1 owner query;
27. malformed post--1 owner query fails COHERENCE_FAILED;
28. exact bundle coherence rechecked after post--1 owner query;
29. generation rechecked immediately after that coherence callback set;
30. reset during post--1 query returns RESETTING;
31. drift during post--1 query returns COHERENCE_FAILED;
32. actual coherent -1/no side effect returns NO_REACHABLE_TARGET;
33. secret pending-owner reservation with -1 return is cleaned and fails COHERENCE_FAILED;
34. reset/drift/malformed post--1 paths do not route;
35. reset/drift/malformed post--1 paths do not call factory;
36. no agent/active entry on post--1 failure;
37. owner id does not advance on canonical -1 or failed post--1 proof;
38. unrelated reservation survives narrow cleanup.

## `_dispatcher_ownable` generation precedence
39. helper verdict is stored before interpretation;
40. generation checked immediately after helper returns;
41. reset inside subclass get_state is directly injected;
42. injected get_state reset also makes ownability verdict false;
43. final result is RESETTING, not AGENT_ASSIGN_FAILED;
44. assign call count remains zero;
45. no child/active entry;
46. pending reservation absent;
47. later dispatch recovers;
48. owner ids remain monotonic.

## `_agent_assigned_ok` generation precedence
49. postcondition helper verdict is stored before interpretation;
50. generation checked immediately after helper returns;
51. reset inside post-assign get_state/postcondition probe is directly injected;
52. injected reset also makes helper verdict false;
53. final result is RESETTING, not AGENT_ASSIGN_FAILED;
54. add_child is not reached;
55. no active entry;
56. pending reservation absent;
57. dispatcher-owned fresh agent is disposed safely;
58. later dispatch recovers.

## Malformed positive ownership proof
59. positive selector target can establish a real pending reservation before proof test;
60. malformed get_target_for_owner float rejected;
61. malformed get_target_for_owner String/null/object-like rejected;
62. malformed get_owner float rejected;
63. malformed get_owner String/null/object-like rejected;
64. malformed positive proof returns COHERENCE_FAILED;
65. generation still has priority when reset occurs in proof callback;
66. no route after malformed proof;
67. no factory after malformed proof;
68. no agent/active entry;
69. owner id does not advance;
70. pending reservation attributable to current attempt is absent after failure;
71. unrelated reservation remains intact;
72. rollback post-state is directly observed.

## Real M15-C002 V03 integration
73. uses current production TargetSelector from M15-C002 V03;
74. uses real ReservationState;
75. uses current ColorCandidateIndex;
76. targetability callback attempts TargetSelector bind/rebind during selection;
77. M15 selector contains/rejects that rebind;
78. targetability callback attempts ReservationState/candidate drift where applicable;
79. no foreign ReservationState orphan remains;
80. dispatcher does not route under split-brain selector truth;
81. dispatcher creates no invalid active assignment;
82. prior committed assignment remains intact if test includes one;
83. later coherent dispatch succeeds.

## V04 bind transaction regression
84. nested bind from selector coherence rejected;
85. nested bind from reservation coherence rejected;
86. nested bind from routing-access coherence rejected;
87. nested bind from select-access coherence rejected;
88. outer bind identity wins;
89. reset during each bind coherence seam invalidates outer bind;
90. bind guard clears on all failures;
91. parent liveness rechecked before bind commit;
92. explicit factory validity rechecked before bind commit;
93. later clean bind recovers;
94. ordinary already-bound bind remains false/preserve.

## V04 selector/ownership regression
95. selector null/float/String/Vector2/RefCounted/bool/Array/Dictionary returns fail closed;
96. negative int other than -1 fails COHERENCE_FAILED;
97. positive no-reservation selector lie fails;
98. owner->different-target lie fails;
99. target->different-owner lie fails without deleting unrelated owner;
100. exact positive owner<->target proof succeeds;
101. owner id advances only after exact proof;
102. no routing before exact proof.

## V04 route/reset generation regression
103. reset in post-selection coherence -> RESETTING before route;
104. reset in cached RouteValidator access -> RESETTING before factory;
105. reset in fresh RouteValidator access -> RESETTING before factory;
106. reset in post-routing coherence -> RESETTING before factory;
107. reset in post-factory coherence -> RESETTING before assign;
108. reset in post-assign coherence -> RESETTING before add_child;
109. reset generation has priority over ordinary coherence failure on these paths;
110. pending reservation removed on every interrupted path.

## Reset re-entry regression
111. reset while `_resetting` is stable no-op;
112. outer reset increments generation once;
113. nested reset from cancel does not recurse;
114. committed agent cancel count is one;
115. active map empty after reset;
116. committed reservation absent after reset;
117. no orphan child;
118. owner counter not rewound;
119. post-cancel instance revalidation remains present;
120. later dispatch recovers.

## Assign/factory regression
121. assign actual bool false rejected;
122. legal non-bool assign return rejected;
123. valid bool true proceeds to postcondition checks;
124. lying MOVING/owner/color/target postcondition subclasses remain rejected;
125. explicit invalidated factory does not default-fallback;
126. foreign parented/reused factory product not freed/mutated;
127. default factory valid path succeeds;
128. explicit valid factory succeeds.

## Add-child final transaction source/regression
129. generation checked immediately after add_child;
130. post-add exact bundle coherence present;
131. generation checked immediately after post-add coherence;
132. agent instance revalidated before signal connect;
133. exact expected parent revalidated before signal connect;
134. failure path detaches/frees dispatcher-owned agent safely;
135. pending reservation released on post-add failure;
136. no active commit before final checks;
137. documented headless locked-object limitation is preserved truthfully, not claimed as runtime coverage;
138. prior committed assignment survives a later failed pending dispatch.

## Request/completion/production regression
139. negative color fails before side effects;
140. start NaN/INF fails;
141. speed NaN/+INF/-INF fails;
142. speed zero/negative fails;
143. recursive dispatch remains REENTRANT;
144. no-reachable target spawns zero agent;
145. unreachable raw candidate spawns zero agent;
146. success spawns exactly one agent;
147. no retarget after route failure;
148. completion identity owner/target/color/source remains enforced;
149. repeated completion idempotent;
150. completion does not clear BoardState;
151. completion does not release successful reservation;
152. 5-slot burst green;
153. rapid 25+ sequential stress green;
154. production routing reachable success green;
155. enclosed target no-work green;
156. real 59x59 green;
157. rectangular Very Hard green;
158. M13-M18 + M15-C002 regressions green.

## M20/scope
159. no BoardState ACTIVE->CLEARED in M19;
160. no successful-arrival reservation resolution;
161. no scoring/slot progression/follow-up dispatch;
162. TargetSelector production unchanged;
163. ReservationState production unchanged;
164. BoardState/ColorCandidateIndex/routing/ScrubbotAgent production unchanged;
165. production changes confined to `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`.

## Sensitivity
166. removing baseline post-callback coherence or generation makes a direct test fail;
167. removing post--1 callback generation/coherence makes a direct test fail;
168. interpreting ownability verdict before generation makes direct reset test fail;
169. interpreting postcondition verdict before generation makes direct reset test fail;
170. at least one temporary sensitivity mutation is recorded and restored.

## Governance / final H!veAI
171. full Godot 4.7.1 root suite passes;
172. zero final SCRIPT/Parse errors;
173. git diff --check clean;
174. root tasks.md completion truth untouched by Claude;
175. AUDIT_INDEX/strict controllers/CHATGPT_* untouched by Claude;
176. legacy H!veAI trackers not maintained;
177. PROJECT.json/RULES.md unchanged;
178. matching CLAUDE_LOG_V05 exists;
179. final workflowState AWAITING_AUDIT;
180. final requiredActor CHATGPT;
181. final currentTaskId M19-C001-V05;
182. blockers empty on success;
183. progress remains 278/719 = 38.66%;
184. lastCompletedTaskId remains M15-C002-V03;
185. matching IN_PROGRESS -> AWAITING_AUDIT event exists;
186. implementation/tests/log/tracker/events pushed to origin/main;
187. Claude does not mark COMPLETE / READY_FOR_NEXT_TASK;
188. Claude does not self-audit;
189. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
190. genuine blocker uses BLOCKED state/event;
191. ChatGPT records independent Godot rerun availability.

If V05 passes source/test audit, do NOT final-close M19 yet by default. V05 changes production and ChatGPT cannot independently run Godot. Issue a narrow auditor-authored validation-only V06 for final strict-v2 closure of SB-M19-001..012.
