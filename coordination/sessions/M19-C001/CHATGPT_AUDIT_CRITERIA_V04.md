# M19-C001 — Frozen Dispatcher Remainder Audit Criteria V04

## H!veAI start
1. canonical task is M19-C001-V04;
2. requiredActor is CLAUDE;
3. starting workflow authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. lastCompletedTaskId is M15-C002-V03;
6. IN_PROGRESS tracker/event is committed and pushed BEFORE V04 production/test edits;
7. machine and human tracker state agree.

## Bind transaction guard
8. fresh outer bind is protected by explicit bind-in-progress state;
9. selector-coherence callback nested bind returns false;
10. reservation-coherence callback nested bind returns false;
11. routing-access coherence callback nested bind returns false;
12. select-access coherence callback nested bind returns false;
13. nested bind performs no nested bundle commit;
14. outer valid bind commits at most once;
15. outer bundle identity wins after each nested-bind attack;
16. no assignment/reservation is created merely by bind;
17. bind guard clears after successful bind;
18. bind guard clears after failed bind;
19. later clean bind succeeds after failed bind transaction;
20. ordinary bind while already bound remains false/preserve.

## Reset during bind
21. reset from selector coherence invalidates outer bind;
22. reset from reservation coherence invalidates outer bind;
23. reset from routing-access coherence invalidates outer bind;
24. reset from select-access coherence invalidates outer bind;
25. reset-during-bind leaves dispatcher unbound;
26. no collaborator bundle becomes live after reset-during-bind;
27. bind transaction guard clears after reset interruption;
28. generation change is observed before bind commit;
29. explicit factory validity is rechecked after coherence callbacks;
30. agent_parent liveness is rechecked after coherence callbacks;
31. later clean bind recovers.

## Selector result Variant boundary
32. selector raw return is captured untyped before validation;
33. null selector return fails safely;
34. float selector return fails safely;
35. String selector return fails safely;
36. Vector2 selector return fails safely;
37. RefCounted selector return fails safely;
38. bool selector return fails safely;
39. Array/Dictionary selector return fails safely;
40. negative int other than -1 fails as dependency/coherence violation;
41. canonical int -1 with no reservation gives NO_REACHABLE_TARGET;
42. malformed selector returns produce no route call;
43. malformed selector returns produce no factory call;
44. malformed selector returns produce no agent/active entry;
45. malformed selector return does not advance owner id.

## Pending-owner baseline and exact reservation proof
46. dispatcher proves pending owner id is unassigned before selector side effects;
47. pending-owner baseline return is TYPE_INT validated;
48. selector -1 plus secretly-created owner reservation is not treated as ordinary no-target;
49. selector -1 side-effect reservation is cleaned without disturbing unrelated reservations;
50. positive selected target with no reservation fails COHERENCE_FAILED or documented stable dependency failure;
51. positive target with owner mapped to another target fails;
52. positive target with selected target owned by another owner fails;
53. positive target with exact owner->target and target->owner proof succeeds;
54. get_target_for_owner proof requires TYPE_INT;
55. get_owner proof requires TYPE_INT;
56. generation is checked after each ownership proof callback;
57. bundle coherence is checked after each ownership proof callback;
58. owner id advances only after exact reservation proof;
59. routing cannot begin before exact reservation proof;
60. failed ownership proof removes only reservation attributable to this pending attempt;
61. unrelated reservation survives selector-contract rollback;
62. rollback post-state is directly observed, not inferred from return only.

## M15-C002 real integration
63. real final TargetSelector from M15-C002 V03 is used in M19 integration;
64. targetability callback attempts selector/bundle rebind during real selection;
65. real TargetSelector contains/rejects the rebind according to final M15 law;
66. no foreign ReservationState orphan is created;
67. dispatcher does not route against split-brain selector truth;
68. later coherent dispatch remains usable.

## Generation after post-selection coherence
69. post-selection bundle coherence is callback-bearing;
70. reset injected inside post-selection coherence is detected immediately;
71. RESETTING wins over COHERENCE_FAILED when reset occurred there;
72. routing call count remains zero after post-selection coherence reset;
73. pending reservation is removed;
74. no active assignment/agent is created.

## Cached-route validation generation
75. cached valid route reaches RouteValidator/access callback;
76. reset injected from cached-route RouteValidator access is detected immediately;
77. cached-route reset returns RESETTING;
78. cached-route reset releases pending reservation;
79. factory call count remains zero after cached-route reset;
80. ordinary invalid non-null cached route still gives ROUTE_FAILED with zero fresh compute when no reset occurs.

## Fresh-route validation generation
81. fresh route compute path remains supported when cache is null;
82. reset injected from fresh-route RouteValidator access is detected immediately;
83. fresh-route validation reset returns RESETTING;
84. pending reservation is released;
85. factory remains uncalled after validation reset;
86. ordinary invalid fresh route still gives ROUTE_FAILED when no reset occurs.

## Post-routing coherence generation
87. reset inside post-routing bundle coherence is directly injected;
88. reset is checked before factory phase;
89. result is RESETTING;
90. factory call count is zero;
91. pending reservation is removed.

## Factory / ownability generation
92. factory callback reset remains handled;
93. dispatcher-owned candidate agent is safely disposed on factory reset;
94. `_dispatcher_ownable` callback-bearing state probe is challenged where reproducible;
95. reset during ownability is detected before later coherence/assign;
96. no assign call occurs after ownability reset;
97. invalid/foreign factory product protections from V03 remain intact.

## Post-factory coherence generation
98. reset inside post-factory bundle coherence is injected;
99. reset is detected before agent.assign;
100. assign call count is zero;
101. pending reservation is removed;
102. dispatcher-owned fresh agent is freed;
103. result is RESETTING.

## Assign return actual-bool contract
104. assign return is captured before truthiness use;
105. actual bool false fails AGENT_ASSIGN_FAILED;
106. actual bool true proceeds to postcondition proof;
107. legal runtime evidence for non-bool override behavior is recorded;
108. if non-bool return can occur, it is rejected;
109. rejected assign releases reservation;
110. rejected assign frees dispatcher-owned fresh agent safely;
111. rejected assign creates no child/active entry.

## Agent postcondition generation
112. existing MOVING/owner/color/target postconditions remain enforced;
113. reset during callback-bearing agent state/postcondition probe is detected where reproducible;
114. no attach occurs after such reset;
115. lying assign subclass remains rejected;
116. valid subclass remains accepted.

## Post-assign coherence generation
117. reset inside post-assign bundle coherence is injected;
118. reset is detected before add_child;
119. add_child count remains zero;
120. pending reservation is released;
121. fresh agent is freed;
122. result is RESETTING.

## Reset re-entry safety
123. reset returns immediately/no-op when already `_resetting`;
124. outer reset increments generation exactly once;
125. nested reset from agent.cancel does not increment generation again;
126. cancel callback nested reset does not recurse indefinitely;
127. each committed agent is cancelled at most once by the outer pass;
128. each active reservation is absent after outer reset;
129. active map is empty after reset;
130. no orphan child remains;
131. owner counter is not rewound;
132. later dispatch recovers.

## Agent validity after cancel
133. cancel callback that frees its own agent is directly exercised where legal;
134. reset revalidates instance before get_parent/remove/free;
135. no invalid-instance method call occurs after self-free;
136. no double free;
137. reservation cleanup still completes;
138. later dispatch remains usable.

## Add-child final transaction
139. add_child/_ready remains a recognized callback boundary;
140. reset during _ready returns RESETTING and prevents active commit;
141. non-reset bundle drift during _ready is detected;
142. non-reset drift returns COHERENCE_FAILED;
143. generation is checked immediately after post-add coherence;
144. dispatcher revalidates agent instance after add_child callbacks;
145. dispatcher revalidates expected parent identity before signal connection;
146. drift/reset detach/free dispatcher-owned agent safely;
147. pending reservation removed on add-child failure;
148. no completion signal/active map commit after drift/reset;
149. prior committed assignments survive pending-dispatch drift;
150. later dispatch recovers.

## Preserve V03 route/cache/factory hardening
151. null cache permits fresh compute;
152. non-null invalid cache performs zero fresh compute;
153. wrong-target/start/end/non-finite routes remain rejected;
154. explicit invalidated factory does not fall back to default;
155. foreign parented/reused factory products are not freed/mutated;
156. valid default factory works;
157. valid explicit factory works;
158. valid explicit agent_parent works;
159. freed/queued parent still fails cleanly.

## Preserve request/completion/core M19
160. negative color invalid before side effects;
161. start NaN/INF invalid;
162. speed NaN/+INF/-INF invalid;
163. speed zero/negative invalid;
164. recursive dispatch remains REENTRANT;
165. ordinary sequential rapid dispatch remains supported;
166. correct completion marks arrived;
167. wrong/stale completion identity ignored;
168. repeated completion idempotent;
169. completion does not clear BoardState;
170. completion does not release successful reservation;
171. no reachable target spawns zero agent;
172. unreachable raw candidate spawns zero agent;
173. successful dispatch spawns exactly one agent;
174. duplicate target prevention preserved;
175. route/assign ordinary rollback preserved;
176. failed target reusable;
177. reset committed agents/releases reservations;
178. BoardState unchanged by M19 reset/arrival observation;
179. 5-slot burst remains green;
180. rapid 25+ sequential stress remains green;
181. real production routing reachable success remains green;
182. enclosed target no-work remains green;
183. real 59x59 remains green;
184. rectangular Very Hard remains green;
185. M13-M18 current regressions remain green.

## M20 / architecture boundary
186. no BoardState ACTIVE->CLEARED in M19;
187. no successful-arrival reservation resolution;
188. no scoring;
189. no slot progression;
190. no automatic follow-up dispatch;
191. no routing algorithm moved into dispatcher;
192. no target-selection algorithm moved into dispatcher;
193. TargetSelector production remains unchanged in V04;
194. BoardState/ColorCandidateIndex/ReservationState/routing/ScrubbotAgent core unchanged.

## Scope / governance
195. production changes are confined to `scripts/gameplay/dispatch/*`;
196. root tasks.md completion truth is untouched by Claude;
197. AUDIT_INDEX / strict controllers / CHATGPT_* untouched by Claude;
198. legacy H!veAI trackers not maintained;
199. PROJECT.json / RULES.md unchanged;
200. matching CLAUDE_LOG_V04 exists.

## Validation / final H!veAI
201. exact Godot 4.7.1 version recorded;
202. full root suite passes;
203. zero final SCRIPT/Parse errors;
204. git diff --check clean;
205. final workflowState AWAITING_AUDIT;
206. final requiredActor CHATGPT;
207. final currentTaskId M19-C001-V04;
208. blockers empty on success;
209. progress remains 278/719 = 38.66%;
210. lastCompletedTaskId remains M15-C002-V03;
211. matching IN_PROGRESS -> AWAITING_AUDIT event exists;
212. implementation/tests/log/tracker/events are pushed to origin/main;
213. Claude does not mark COMPLETE / READY_FOR_NEXT_TASK;
214. Claude does not self-audit;
215. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
216. genuine blocker uses BLOCKED state/event;
217. ChatGPT records independent Godot rerun availability.

If V04 production/source/test audit is clean, M19 is still a critical stateful orchestrator and V04 contains production corrections. Because ChatGPT cannot independently run Godot, ChatGPT should normally issue a narrow auditor-authored validation-only V05 before final-closing SB-M19-001..012, unless the audit policy is revised or independent runtime becomes available.
