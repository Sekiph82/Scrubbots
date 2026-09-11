# M20-C001 — Optional Renderer Lifecycle Correction Audit Criteria V06

Canonical live tracker: repository-root `TASKS.md` only.

## Tracker / governance
1. root TASKS is sole live tracker;
2. V05 audit exists before V06 implementation;
3. V06 freeze exists;
4. V06 prompt exists;
5. starting task is M20-C001 V05;
6. starting state is BLOCKED / CHATGPT;
7. blocker identifies V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT;
8. progress starts 290/719 main+ui;
9. overall starts 290/943;
10. lastCompletedTaskId starts M19-C001-V06;
11. all SB-M20-001..014 start open;
12. V06 tracker-only IN_PROGRESS transition is committed;
13. start transition is pushed before any production edit;
14. start transition is pushed before any test edit;
15. remote main transition is verified;
16. owner/local work is preserved;
17. no .hiveai live tracker is recreated;
18. no CHATGPT_* artifact is modified by Claude;
19. no audit verdict is self-assigned;
20. no SB-M20 row is closed by Claude.

## V05 validation truth preservation
21. V05 validation commit is recognized as validation-only;
22. V04 clearing-loop blob before V06 is f00c34021da85e596df58f08857acde8846dd8a4;
23. V04 dispatcher blob before V06 is 1709b8c8ebf7595596bdf8cbd059f04bf1196ea3;
24. V05 truly-freed renderer defect is reproduced/understood before correction;
25. freed renderer runtime comparison-to-null fact is recorded;
26. freed renderer TYPE_OBJECT fact is recorded;
27. dispatcher truly-freed cases remain known-good baseline;
28. V05 fresh root validation block remains enabled;
29. V05 lifecycle smoke remains present;
30. V04 lifecycle smoke remains present.

## Renderer presence model
31. production owns private renderer-presence metadata;
32. presence metadata is not public mutable state;
33. actual TYPE_NIL maps to intentional headless;
34. non-NIL renderer argument maps to explicit renderer supplied;
35. renderer presence is not derived from `renderer != null` equality;
36. renderer presence is not derived from `_renderer != null` after bind;
37. successful bind commits renderer presence exactly once;
38. failed bind does not commit renderer presence;
39. second bind cannot overwrite renderer presence;
40. test harness mirrors presence truth when bypassing bind.

## Headless bind
41. omitted renderer bind succeeds on otherwise valid bundle;
42. explicit null renderer bind succeeds on otherwise valid bundle;
43. headless bind creates exactly one dispatcher arrival connection;
44. headless loop is bound;
45. headless loop is coherent;
46. headless activation works;
47. headless authenticated arrival clears;
48. headless clear increments cleared_count once;
49. headless clear resolves exact reservation;
50. headless clear finalizes dispatcher assignment.

## Explicit renderer bind category
51. scalar int renderer rejected;
52. float renderer rejected;
53. String renderer rejected;
54. Vector2 renderer rejected;
55. arbitrary RefCounted rejected;
56. arbitrary wrong Node rejected;
57. wrong-script Node rejected;
58. queued exact BoardRenderer rejected;
59. truly-freed BoardRenderer rejected;
60. healthy exact BoardRenderer accepted;
61. rejected explicit renderer leaves loop unbound;
62. rejected explicit renderer binds no arrival signal;
63. truly-freed renderer rejection emits no SCRIPT ERROR;
64. queued renderer rejection emits no SCRIPT ERROR;
65. healthy renderer bind records no false headless state.

## Before-bind freed-object alias law
66. truly-freed renderer runtime equality to null is directly observed in frame-aware test;
67. same freed reference remains TYPE_OBJECT under observed runtime;
68. bind still treats it as explicitly supplied;
69. liveness check runs despite equality-to-null;
70. bind returns false;
71. loop remains unbound;
72. no dispatcher arrival connection is created by failed bind;
73. no get_script/method call occurs after instance-invalid proof;
74. actual null remains distinguishable from the freed Object behaviorally;
75. no criteria relaxation silently reclassifies freed renderer as headless.

## Live coherence with configured renderer
76. healthy configured renderer -> is_coherent true;
77. configured renderer queue_free before frame -> is_coherent false;
78. configured renderer destroyed across frames -> is_coherent false;
79. configured renderer foreign-board coherence -> false;
80. configured renderer wrong lifecycle never becomes headless;
81. freed renderer path emits no SCRIPT ERROR;
82. queued renderer path emits no SCRIPT ERROR;
83. dispatcher liveness remains checked independently;
84. candidate coherence remains checked;
85. reservation coherence remains checked;
86. headless bundle does not require a renderer;
87. headless coherence remains true when other bundle deps healthy;
88. configured renderer presence survives object equality-to-null after destruction;
89. is_coherent does not mutate gameplay state;
90. is_coherent does not clear renderer-presence metadata.

## Activation against renderer loss
91. configured renderer destroyed after bind causes activation failure;
92. failure occurs before new dispatcher work;
93. no new reservation is created;
94. no new active agent is created;
95. BoardState remains unchanged;
96. candidate state remains unchanged;
97. cleared_count remains unchanged;
98. stable DispatchResult failure is returned;
99. no raw M19 success is exposed;
100. reset remains callable afterward.

## Post-dispatch barrier regression
101. reset inside real M19 dispatch returns RESETTING;
102. raw M19 success remains hidden after M20 reset generation moves;
103. current attempt active assignment is cleaned;
104. current attempt reservation is cleaned;
105. BoardState remains ACTIVE on aborted dispatch;
106. cleared_count remains zero for aborted dispatch;
107. owner id is not rewound;
108. later healthy activation uses a later owner;
109. renderer queue/delete inside M19 dispatch returns COHERENCE_FAILED;
110. corresponding assignment is cleaned;
111. corresponding reservation is cleaned;
112. no false BoardState clear occurs;
113. no false renderer clear occurs;
114. fresh healthy bundle recovers;
115. dispatcher production source is unchanged in V06.

## Arrival preflight with renderer lifecycle
116. authenticated arrival with healthy configured renderer can proceed;
117. renderer destroyed before arrival preflight makes bundle incoherent;
118. such arrival does not mutate BoardState;
119. such arrival does not sync candidate target away;
120. such arrival does not resolve reservation;
121. such arrival does not finalize dispatcher assignment;
122. such arrival does not increment cleared_count;
123. stale replay after renderer-loss/reset cannot clear;
124. wrong owner still cannot clear;
125. wrong target still cannot clear;
126. wrong color still cannot clear;
127. wrong source agent still cannot clear;
128. missing reservation still cannot clear;
129. already-cleared target still cannot clear twice;
130. current-arrival dedup remains.

## Renderer success / presentation
131. healthy configured renderer successful clear commits BoardState first;
132. candidate target removed after BoardState clear;
133. reservation exact pair resolved after candidate proof;
134. dispatcher finalize occurs before repaint;
135. renderer repaint occurs after dispatcher finalize;
136. target renderer alpha becomes zero/CLEARED presentation;
137. unrelated renderer pixel remains unchanged;
138. cleared_count increments exactly once;
139. no renderer/headless success path remains valid;
140. renderer is presentation-only, not canonical gameplay truth.

## Renderer rollback / helper semantics
141. `_renderer_pixel` never calls an invalid renderer;
142. configured renderer live source-pixel snapshot remains available;
143. rollback with healthy renderer remains visually opaque/source-colored;
144. failed candidate transaction does not false-clear renderer;
145. failed reservation transaction does not false-clear renderer;
146. identity-swap still escalates to ROLLBACK_FAILED;
147. unrelated candidate truth is preserved on rollback;
148. no normal-path full-board renderer repaint is introduced;
149. renderer helper uses persisted presence where presence semantics matter;
150. dead renderer is not invoked merely because stored member exists.

## Pair-narrow dispatcher reset regression
151. healthy exact T<->O reset releases T;
152. unrelated healthy reservation survives same reset;
153. foreign-board different-target reservation survives;
154. foreign-board same-numeric-target reservation survives;
155. same-board O->V replacement survives;
156. missing current pair does not delete unrelated reservation;
157. M20 loop.reset foreign-board route preserves foreign reservation;
158. dispatcher active bookkeeping clears in all reset cases;
159. agent cleanup still occurs;
160. owner counter remains monotonic;
161. reset no longer depends on release_for_owner for active-entry cleanup;
162. dispatcher reset source has no V06 production modification;
163. nested reset guard remains;
164. reset generation semantics remain;
165. no foreign reservation is fabricated.

## Queue / reset / concurrency regression
166. duplicate current owner+agent is dropped;
167. duplicate already queued owner+agent is dropped;
168. distinct nested arrival remains FIFO;
169. current identity clears after success;
170. current identity clears after rejection;
171. current identity clears after rollback;
172. reset clears queued stale arrivals;
173. reset clears current-arrival bookkeeping safely;
174. reset during candidate phase restores no-clear state;
175. reset during reservation phase restores no-clear state;
176. later healthy activation recovers when bundle healthy;
177. reset does not rewind already-cleared artwork;
178. no stale replay clear occurs;
179. nested activation remains REENTRANT;
180. activation while arrival drain active remains REENTRANT.

## Direct gameplay integration
181. real 1x1 board dimensions/count are one;
182. sole target dispatches and clears;
183. second 1x1 activation reports no work;
184. AL-028 blocked B is initially unreachable;
185. real A dispatch clears A;
186. second real activation selects B;
187. B exact reservation exists;
188. B arrival clears B;
189. five simultaneous activations yield five unique owners;
190. five targets are distinct;
191. five exact reservation pairs exist;
192. first of five arrival preserves other four pairs;
193. all five eventually resolve;
194. 59x59 case remains green;
195. rectangular case remains green;
196. rapid >=25 cycles remain green;
197. one-color exhaustion remains green;
198. multi-color coverage remains green;
199. Easy/Medium/Hard/Very Hard regressions remain green;
200. newly-opened reachability continues reading BoardState live.

## Sensitivity
201. temporary renderer-presence sensitivity mutation is executed after V06 start push;
202. mutation reintroduces equality/null-style configured-renderer decision;
203. V05 truly-freed renderer smoke fails for intended reason under mutation;
204. at least one V06 direct null-vs-dead test fails for intended reason;
205. mutation is not committed;
206. production is restored before final run;
207. pre-mutation production blob is recorded;
208. post-restore production blob is recorded;
209. restored blob differs from V04 only by intended V06 correction;
210. final full suite is run only after restoration.

## Scope / architecture
211. only complete_clearing_loop.gd changes in production;
212. scrubbot_dispatcher.gd production is unchanged;
213. BoardState production unchanged;
214. BoardRenderer production unchanged;
215. SlotSystem production unchanged;
216. ColorCandidateIndex production unchanged;
217. ReservationState production unchanged;
218. TargetSelector production unchanged;
219. routing/access production unchanged;
220. ScrubbotAgent production unchanged;
221. no M21 production behavior added;
222. no scoring/economy/session-complete behavior added;
223. no slot cooldown/queue/consumption policy added;
224. no second access cache added;
225. no one-Node-per-cell architecture introduced.

## Final validation / handoff
226. Godot version is 4.7.1 stable;
227. V05 lifecycle smoke passes after correction;
228. V04 lifecycle smoke passes;
229. queue_free smoke passes;
230. direct null/headless/dead/wrong/healthy renderer tests pass;
231. full root suite passes with exact total recorded;
232. zero final M20 SCRIPT ERROR lines;
233. zero final Parse Error lines;
234. git diff --check clean;
235. exact changed-file list recorded;
236. final clearing-loop blob recorded;
237. CLAUDE_LOG_V06 exists;
238. log records sensitivity failure and restoration;
239. final root TASKS task is M20-C001-V06;
240. final status is AWAITING_AUDIT;
241. final Required Actor is CHATGPT;
242. progress remains 290/719 main+ui;
243. overall remains 290/943;
244. lastCompletedTaskId remains M19-C001-V06;
245. all SB-M20 rows remain open;
246. implementation/test/log/tracker pushed to origin/main;
247. no CHATGPT_* file modified by Claude;
248. Claude does not mark COMPLETE or READY_FOR_NEXT_TASK;
249. broader production need uses BLOCKED;
250. V06 explicitly stops before M21;
251. V06 does not claim final strict-v2 closure;
252. clean V06 leaves final closure pending auditor-authored V07 validation-only.

If all 252 criteria pass, ChatGPT may source-accept V06 and issue V07 validation-only. M20 tasks remain open until V07 independently audits clean.
