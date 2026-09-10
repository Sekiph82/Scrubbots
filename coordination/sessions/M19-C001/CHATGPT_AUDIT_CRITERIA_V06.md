# M19-C001 — Auditor-Authored Validation-Only Criteria V06

## H!veAI start gate
1. canonical currentTaskId is M19-C001-V06;
2. requiredActor is CLAUDE;
3. starting workflow authorizes validation;
4. progress starts 278/719 = 38.66%;
5. lastCompletedTaskId is M15-C002-V03;
6. IN_PROGRESS tracker/event is committed and pushed before ANY V06 test/support edit or temporary production sensitivity mutation;
7. remote main start transition is verified before validation edits;
8. Claude log explicitly states no V06 validation/production edit existed before successful start push;
9. machine and human tracker sections agree.

## Production immutability
10. V05 dispatcher baseline commit is 9cf1e7d75009ba50d02db35802aa5cf345f9752a;
11. V05 dispatcher blob resolves to 0d1a6b1f6e9a6f1788ceb2078473c87bec8986e3;
12. pre-validation current dispatcher hash equals V05 blob;
13. no committed V06 change under scripts/gameplay/dispatch;
14. no committed V06 change under scripts/gameplay/targeting;
15. no committed V06 change under scripts/gameplay/routing;
16. no committed V06 change under scripts/gameplay/agents;
17. no BoardState/SlotSystem/GameplaySession production change;
18. temporary production sensitivity mutations are restored before final validation;
19. final dispatcher hash equals V05 blob;
20. final production diff against V05 baseline is clean for scoped gameplay production.

## Bind transaction adversaries
21. nested bind from selector coherence seam is rejected;
22. nested bind from another coherence seam is rejected;
23. outer bind bundle identity wins after nested-bind attack;
24. reset during a different bind-time coherence seam invalidates bind;
25. reset-during-bind leaves dispatcher unbound;
26. failed bind commits no collaborator bundle/active assignment;
27. clean bind succeeds after failed/reset bind;
28. second valid bind after successful bind returns false;
29. second bind while one live assignment exists preserves that active assignment;
30. second bind preserves original reservation ownership.

## Pre-selector pending-owner boundary
31. baseline callback reset returning -1 yields RESETTING;
32. baseline callback drift returning -1 yields COHERENCE_FAILED;
33. malformed Dictionary baseline yields COHERENCE_FAILED;
34. malformed Vector2 baseline yields COHERENCE_FAILED;
35. valid non--1 baseline yields COHERENCE_FAILED;
36. selector call count remains zero after baseline reset;
37. selector call count remains zero after baseline drift;
38. selector call count remains zero after malformed baseline;
39. route call count remains zero on baseline failure;
40. factory call count remains zero on baseline failure;
41. active count unchanged on baseline failure;
42. owner counter unchanged on baseline failure;
43. no current-attempt reservation appears on baseline failure.

## Selector result / canonical -1
44. non-int selector return fails closed;
45. non-int selector return with secret current-owner reservation cleans that reservation;
46. exact int -1 with no reservation returns NO_REACHABLE_TARGET;
47. canonical -1 does not advance owner counter;
48. -1 with secret current-owner reservation yields COHERENCE_FAILED;
49. secret -1 reservation is removed;
50. reset during post--1 owner query yields RESETTING;
51. drift during post--1 owner query yields COHERENCE_FAILED;
52. post--1 reset/drift paths do not route;
53. post--1 reset/drift paths do not call factory;
54. post--1 failure creates no active agent;
55. unrelated reservation survives narrow cleanup.

## Positive ownership proof
56. exact current owner->target and target->owner proof succeeds;
57. malformed owner->target proof fails COHERENCE_FAILED;
58. malformed target->owner proof fails COHERENCE_FAILED;
59. owner->different-target proof fails;
60. target->different-owner proof fails;
61. reset during owner->target proof yields RESETTING;
62. reset during target->owner proof yields RESETTING;
63. drift during owner->target proof yields COHERENCE_FAILED;
64. drift during target->owner proof yields COHERENCE_FAILED;
65. no routing begins before exact proof passes;
66. current pending reservation is removed after failed proof;
67. unrelated reservation survives failed proof cleanup;
68. owner counter advances only after exact positive proof.

## Routing seam
69. null/no cached route permits fresh compute;
70. present invalid cached route performs zero fresh compute;
71. wrong-target cached route yields ROUTE_FAILED;
72. invalid-geometry cached route yields ROUTE_FAILED;
73. invalid cached route releases pending reservation;
74. reset inside cached RouteValidator access yields RESETTING;
75. cached-validator reset prevents factory;
76. reset inside fresh RouteValidator access yields RESETTING;
77. fresh-validator reset prevents factory;
78. fresh route failure performs no retarget;
79. route-failure target becomes dispatchable again after release.

## Factory ownership
80. invalidated explicit factory does not use default factory;
81. invalidated explicit factory yields AGENT_ASSIGN_FAILED;
82. parented foreign ScrubbotAgent is rejected;
83. parented foreign agent is not freed;
84. parented foreign agent is not cancelled/mutated by dispatcher;
85. MOVING reused agent rejected;
86. ARRIVED reused agent rejected;
87. CANCELLED reused agent rejected;
88. default fresh agent path succeeds.

## Ownability reset precedence
89. ownability get_state callback triggers reset;
90. same callback returns state that makes ownability false;
91. result is RESETTING rather than AGENT_ASSIGN_FAILED;
92. assign is not entered after ownability reset;
93. no child/active entry after ownability reset;
94. pending reservation removed after ownability reset;
95. later clean dispatch recovers.

## Postcondition reset precedence
96. assigned-agent get_state callback triggers reset during postcondition probe;
97. callback also makes postcondition verdict false;
98. result is RESETTING rather than AGENT_ASSIGN_FAILED;
99. add_child is not entered after postcondition reset;
100. no active/orphan remains;
101. pending reservation removed;
102. later clean dispatch recovers.

## Reset / completion lifecycle
103. recursive dispatch from injected callback returns REENTRANT;
104. recursive dispatch creates no second reservation;
105. recursive dispatch does not advance a second owner id;
106. nested reset from cancel does not recurse;
107. committed agent cancel count is exactly one;
108. outer reset clears active assignments;
109. outer reset releases committed reservations;
110. reset does not rewind owner ids;
111. stale completion after reset cannot recreate state;
112. wrong source agent completion ignored;
113. wrong owner completion ignored;
114. wrong target completion ignored;
115. wrong color completion ignored;
116. correct completion marks arrived;
117. repeated correct completion is idempotent;
118. arrival does not clear BoardState;
119. arrival does not release successful reservation.

## Real production integration
120. uses current production TargetSelector M15-C002 V03;
121. uses real ReservationState and ColorCandidateIndex;
122. one reachable target yields exactly one assignment;
123. assignment reservation owner/target identity is exact;
124. enclosed matching ACTIVE candidate yields no spawn;
125. duplicate target assignment is prevented;
126. five independent reachable targets support five successful independent dispatches;
127. 25+ sequential dispatch stress preserves unique owner ids;
128. 59x59 maximum production board remains green;
129. rectangular Very Hard board remains green;
130. M15 rebind/mutation attempt during targetability creates no foreign reservation;
131. M15 adversary creates no split-brain route/active assignment;
132. later coherent production dispatch remains usable.

## Add-child boundary truth
133. generation check remains immediately after add_child;
134. exact bundle coherence remains before signal-connect/active commit;
135. generation recheck remains after post-add coherence;
136. agent validity remains checked before commit;
137. exact expected parent remains checked before commit;
138. no active commit occurs before all final guards;
139. headless locked-object limitation is reported truthfully and not misrepresented as runtime PASS.

## Sensitivity
140. at least two of S1/S2/S3 temporary mutations are executed after H!veAI start push;
141. S1 baseline-coherence removal makes the intended V06 drift test fail when chosen;
142. S2 ownability-generation reversal makes reset-priority test fail when chosen;
143. S3 invalid-cache fallback mutation makes zero-fresh-compute test fail when chosen;
144. exact failing validation names/results are recorded;
145. each mutation is restored before the next/final run;
146. final production hash proves restoration.

## Regression / scope
147. all prior M19 V01-V05 tests remain enabled;
148. M13-M18 strict regressions remain green;
149. M15-C002 V01-V03 regressions remain green;
150. finite request NaN/INF boundaries remain green;
151. one-by-one flow remains green;
152. rapid-input/concurrent-slot coverage remains green;
153. no M20 BoardState ACTIVE->CLEARED behavior added;
154. no successful-arrival reservation resolution added;
155. no scoring/slot progression/auto follow-up added.

## Final validation / governance
156. Godot version is 4.7.1 stable;
157. full root suite passes with exact total/pass/failure recorded;
158. zero final SCRIPT ERROR / Parse Error lines;
159. git diff --check clean;
160. production immutability proof is recorded in CLAUDE_LOG_V06;
161. root tasks.md completion truth untouched by Claude;
162. AUDIT_INDEX/CHATGPT_* / strict controllers untouched by Claude;
163. PROJECT.json and RULES.md unchanged;
164. deprecated legacy trackers are not maintained;
165. matching CLAUDE_LOG_V06 exists;
166. final workflowState is AWAITING_AUDIT;
167. final requiredActor is CHATGPT;
168. final currentTaskId is M19-C001-V06;
169. final blockers are empty on clean validation;
170. progress remains 278/719 = 38.66%;
171. lastCompletedTaskId remains M15-C002-V03;
172. matching IN_PROGRESS -> AWAITING_AUDIT event exists;
173. validation files/log/tracker/events are pushed to origin/main;
174. Claude does not mark COMPLETE or READY_FOR_NEXT_TASK;
175. Claude does not change root M19 checkboxes;
176. Claude does not self-audit;
177. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
178. discovered production defect uses BLOCKED + V06_VALIDATION_EXPOSED_PRODUCTION_DEFECT;
179. ChatGPT records independent Godot rerun availability.

If all 179 criteria pass, ChatGPT may final-close SB-M19-001..012 and advance H!veAI to the next authorized task.
