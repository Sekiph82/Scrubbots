# M20-C001 — Whole-Sprint Batched Correction Audit Criteria V07

Canonical live tracker: repository-root `TASKS.md` only.

These criteria implement the owner-locked sprint-wide audit policy. Aggregate green counts never substitute for a missing direct or sensitivity check.

## Tracker / governance
1. root `TASKS.md` is the sole live tracker;
2. V06 audit exists before V07 implementation;
3. V07 full-surface freeze exists;
4. V07 prompt exists;
5. starting task is M20-C001-V06;
6. starting state is AWAITING_AUDIT / CHATGPT;
7. progress starts 290/719 = 40.33% main+ui;
8. overall starts 290/943 = 30.75%;
9. lastCompletedTaskId starts M19-C001-V06;
10. SB-M20-001..014 all start open;
11. V07 tracker-only IN_PROGRESS transition is committed;
12. transition is pushed before any V07 production edit;
13. transition is pushed before any V07 test/support edit;
14. transition is pushed before any V07 doc edit;
15. transition is pushed before any temporary sensitivity mutation;
16. remote start transition is verified;
17. Claude log explicitly states no V07 edit existed before the successful start push;
18. owner/local work is preserved;
19. no `.hiveai` live tracker is recreated;
20. Claude does not edit ChatGPT audit artifacts or self-assign an audit verdict;
21. Claude closes no SB-M20 task.

## Accepted V06 baseline
22. V06 implementation commit `b4e960aaad8662ae4192a7ba57530940ff8767f9` is recognized;
23. pre-V07 clearing-loop blob is `514838fa6d965ffa1f5663b9c4c5385c12f63114`;
24. pre-V07 dispatcher blob is `1709b8c8ebf7595596bdf8cbd059f04bf1196ea3`;
25. `_renderer_expected` presence semantics remain;
26. TYPE_NIL remains intentional headless;
27. configured dead renderer never silently becomes headless;
28. healthy order remains BoardState -> candidate -> reservation -> dispatcher finalize -> renderer;
29. exact reservation owner-map rollback proof remains;
30. current-arrival dedup + distinct FIFO remain;
31. reset generation/deferred reset remain;
32. pair-narrow dispatcher reset remains;
33. no M21/win/scoring/session/slot-policy behavior is added.

## Pre-fix observations
34. two-loop same-dispatcher arrangement is run on V06 baseline after start push;
35. first loop bind result is recorded;
36. second loop bind result is recorded;
37. current duplicate transaction-owner/signal behavior is recorded;
38. split-authority consequence is described factually;
39. frame-aware truly-freed explicit `agent_parent` baseline arrangement is run;
40. freed parent is proven invalid after real frame(s);
41. equality-to-null and typeof facts are recorded when observable;
42. V06 dispatcher bind result with the freed explicit parent is recorded;
43. typed-parameter normalization, if any, is recorded exactly.

## F-M20-STRICT-001.M — single M20 transaction owner
44. dispatcher owns one private M20 arrival-consumer claim;
45. claim is non-owning/weak or equivalently cycle-safe;
46. claim is not a global singleton;
47. claim is not implemented as generic signal-connection count;
48. first live M20 consumer claim succeeds;
49. different second live M20 consumer claim fails;
50. claim itself mutates no BoardState/ReservationState and dispatches nothing;
51. CompleteClearingLoop retains full exact bundle validation before claim;
52. dispatcher active-count zero gate remains;
53. claim is attempted only after otherwise-valid bind preconditions;
54. arrival callback connect occurs only with successful claim;
55. failed connect rolls back any newly created claim/connection;
56. failed claim leaves loop fully unbound;
57. failed claim creates no M20 transaction signal connection;
58. benign diagnostic `assignment_arrived` observer does not block first M20 claim;
59. first loop bind succeeds;
60. second different loop bind on same dispatcher fails;
61. second loop remains unbound;
62. second failure does not mutate/disconnect first loop;
63. first loop remains coherent;
64. first loop can activate and clear after second-loop rejection;
65. owning loop increments cleared_count exactly once;
66. second loop cannot steal arrival attribution;
67. second unbound loop cannot successfully activate/reset the first bundle;
68. one authenticated arrival reaches exactly one M20 transaction owner.

## F-M20-STRICT-001.N — explicit agent_parent presence
69. `agent_parent != null` is not configuration authority;
70. omitted parent intentionally selects dispatcher self;
71. actual null parent intentionally selects dispatcher self;
72. every non-NIL parent Variant is treated as explicit configuration;
73. scalar/wrong-object parent is rejected cleanly where runtime boundary permits it;
74. arbitrary RefCounted parent is rejected;
75. queued Node parent is rejected;
76. truly-freed explicit Node parent is rejected;
77. truly-freed explicit parent never falls back to dispatcher self;
78. configured/default truth is captured before external coherence callbacks;
79. explicit parent liveness is checked before those callbacks;
80. explicit parent is revalidated after callbacks using captured presence truth;
81. callback-freed parent blocks bind commit;
82. healthy explicit parent binds;
83. healthy explicit parent becomes actual agent parent;
84. spawned agent attaches to healthy explicit parent;
85. default/null path attaches spawned agent to dispatcher self;
86. post-bind attach-time `_is_live_node(_agent_parent)` gate remains;
87. parent death before attach cleanly releases current reservation;
88. parent failure leaves no orphan agent;
89. explicit factory semantics remain unchanged;
90. invalidated explicit factory still cannot fall back to default;
91. owner id monotonicity remains.

## Renderer bind / lifecycle matrix
92. omitted renderer headless bind succeeds;
93. explicit null renderer headless bind succeeds;
94. int renderer rejected;
95. float renderer rejected;
96. String renderer rejected;
97. Vector2 renderer rejected;
98. Array/Dictionary representative renderer rejected;
99. arbitrary RefCounted renderer rejected;
100. wrong Node renderer rejected;
101. queued exact BoardRenderer rejected;
102. truly-freed exact BoardRenderer rejected;
103. healthy exact BoardRenderer accepted;
104. invalid renderer failure leaves loop unbound;
105. invalid renderer failure creates no M20 claim or arrival connection;
106. failed invalid-renderer bind followed by clean retry on the SAME loop succeeds;
107. failed bind leaves no stale renderer-presence metadata;
108. healthy renderer bind followed by refused second bind preserves original renderer expectation;
109. original renderer queued/dead after refused second bind makes coherence false;
110. renderer reconfigured to same-size foreign board makes coherence false;
111. activation after foreign renderer drift fails before new dispatcher work;
112. foreign renderer drift creates no reservation/agent/BoardState mutation;
113. real dispatch can exist before renderer loss;
114. renderer queued after dispatch but before arrival causes M20 preflight rejection;
115. queued-before-arrival leaves BoardState ACTIVE;
116. queued-before-arrival leaves target candidate present;
117. queued-before-arrival leaves exact reservation + dispatcher pending until explicit reset;
118. queued-before-arrival leaves cleared_count unchanged;
119. explicit reset then cleans only the original assignment/pair;
120. frame-aware truly-freed renderer after dispatch/before arrival also rejects clear;
121. dead-renderer paths emit no SCRIPT ERROR;
122. healthy renderer clear repaints target alpha 0;
123. repaint is after dispatcher finalization;
124. healthy one-cell repaint leaves an unrelated pixel unchanged;
125. headless clear still works.

## Arrival-preflight desynchronization
126. direct arrangement creates a real M19 ARRIVED pending assignment when needed;
127. wrong owner through M20 arrival boundary is rejected;
128. wrong target is rejected;
129. wrong color is rejected;
130. wrong source agent is rejected;
131. unknown owner is rejected;
132. forged-arrival rejects leave BoardState unchanged;
133. forged-arrival rejects leave cleared_count unchanged;
134. forged-arrival rejects do not finalize real dispatcher assignment;
135. forged-arrival rejects do not release real reservation;
136. missing reservation before arrival is rejected;
137. same-board reservation replaced by different owner is rejected;
138. replacement/wrong-owner reservation survives pair-narrow cleanup;
139. ReservationState rebound to foreign board fails closed;
140. foreign-board replacement reservation survives M20 reset;
141. ColorCandidateIndex rebound to foreign board fails closed;
142. ColorCandidateIndex unbound/neutralized before arrival fails closed where controlled;
143. candidate drift clears nothing and does not finalize assignment;
144. target already CLEARED before arrival is rejected;
145. renderer foreign-board/queued/dead before arrival is rejected;
146. stale replay after reset cannot clear;
147. duplicate correct completion does not clear twice;
148. duplicate current owner+agent arrival is dropped;
149. duplicate queued owner+agent arrival is dropped;
150. distinct nested arrival remains FIFO/lossless;
151. failed preflight followed by reset leaves no orphan agent;
152. unrelated candidate/reservation/cell truth survives failed-preflight cleanup.

## Activation public boundary
153. slot -1 rejected;
154. slot 5 rejected;
155. non-int slot rejected;
156. unavailable slot rejected;
157. valid finite origin/speed succeeds when work exists;
158. NaN x/y origin cases reject;
159. +INF origin rejects;
160. -INF origin rejects;
161. NaN speed rejects;
162. +INF speed rejects;
163. -INF speed rejects;
164. zero speed rejects;
165. negative speed rejects;
166. every rejected activation creates zero new agent;
167. every rejected activation creates zero current-attempt reservation;
168. every rejected activation mutates no BoardState;
169. every rejected activation leaves slot palette/availability/activity unchanged;
170. absent color/no work returns NO_REACHABLE_TARGET;
171. enclosed matching candidate yields no bot;
172. nested activation returns REENTRANT and creates no second reservation;
173. activation during arrival drain returns REENTRANT;
174. reset during preflight returns RESETTING;
175. reset inside M19 dispatch returns RESETTING, never raw SUCCESS;
176. post-dispatch M20 coherence loss returns COHERENCE_FAILED;
177. M20 contains no second target-selection/routing algorithm.

## Fresh SB-M20-001..014 ledger evidence
178. SB-M20-001 fresh healthy full sequence uses real production spine;
179. full sequence proves CLEARED + candidate removal + access OPEN + reservation gone + dispatcher owner gone;
180. full sequence proves finalized agent queued and renderer alpha 0 when configured;
181. SB-M20-002 no-target creates no bot/reservation/clear;
182. enclosed target creates no bot;
183. SB-M20-003 frame-aware finalized agent actually disappears;
184. no orphan/no return remains after frame(s);
185. SB-M20-004 uses actual 1x1, clears once, then exhausted;
186. SB-M20-005 one-color board clears repeatedly to exhaustion;
187. SB-M20-006 multi-color board clears through correct slot colors;
188. SB-M20-007 five activations produce five unique owners;
189. five targets are distinct;
190. five exact reservation pairs exist;
191. resolving one preserves the other four;
192. all five eventually resolve/finalize;
193. SB-M20-008 Easy representative size clears;
194. SB-M20-009 Medium representative size clears;
195. SB-M20-010 Hard representative size clears;
196. SB-M20-011 Very Hard representative size clears;
197. SB-M20-012 59x59 clears with normal single-cell M20 path;
198. CompleteClearingLoop adds no normal-path O(board) scan;
199. SB-M20-013 rectangular production board clears;
200. SB-M20-014 executes the V07 desync/duplicate/reset matrix;
201. reset with multiple in-flight assignments leaves coherent state;
202. second-loop transaction ownership is rejected;
203. AL-028 B is initially unreachable behind ACTIVE A;
204. first real activation clears A;
205. second REAL activation selects/routes B;
206. B arrival clears B;
207. rapid scenario completes >=25 sequential cycles.

## Rollback / reset / contention regressions
208. candidate mutate-before-false is detected and verified rollback/fatal outcome is correct;
209. reservation mutate-before-false is detected;
210. candidate true-without-postcondition is detected;
211. reservation true-without-postcondition is detected;
212. unrelated same-color candidate loss cannot be silently accepted;
213. unrelated different-color candidate remains unchanged on healthy clear;
214. reservation identity swap cannot pass count-only proof;
215. rollback restores exact owner map or reports ROLLBACK_FAILED;
216. reset during candidate phase leaves no half-clear;
217. reset during reservation phase leaves no half-clear;
218. duplicate current arrival clears at most once;
219. distinct second arrival is not lost;
220. healthy pair-narrow reset removes exact pair;
221. unrelated healthy reservation survives;
222. foreign-board different-target reservation survives;
223. foreign-board same-index reservation survives;
224. same-board owner replacement survives;
225. missing current pair does not fabricate/delete unrelated state;
226. owner counter remains monotonic;
227. stale completion after reset recreates nothing;
228. post-dispatch generation/coherence barriers remain;
229. reset re-entry guard remains.

## Documentation / scope
230. current M20 test overview states dispatcher finalize before renderer;
231. architecture no longer claims a hard simultaneous-bot cap equal to slot count;
232. owner-locked five visible slots remain;
233. architecture states one bot per activation;
234. per-slot/global concurrency cap/queue/cooldown remains design-gated unless implemented;
235. historical prompts/audits are not rewritten;
236. only CompleteClearingLoop + ScrubbotDispatcher change in production;
237. BoardState/BoardRenderer/SlotSystem/ColorCandidateIndex/ReservationState/TargetSelector/routing/ScrubbotAgent/GameplaySession production stay unchanged;
238. no second access cache or one-Node-per-cell architecture is introduced;
239. no M21 real-art/content behavior added;
240. no win/lose/scoring/economy/session-complete behavior added;
241. no slot cooldown/queue/consumption policy added;
242. all prior M20 V01-V06 tests remain enabled;
243. all prior M19 V01-V06 tests remain enabled.

## Sensitivity / restoration
244. S1 consumer-claim bypass is run after start push;
245. named second-loop ownership test fails for intended reason;
246. S1 restored before next mutation;
247. S2 agent_parent equality/null fallback mutation is run;
248. frame-aware truly-freed explicit-parent test fails for intended reason;
249. S2 restored before next mutation;
250. S3 renderer equality/null mutation is run;
251. truly-freed renderer lifecycle test fails for intended reason;
252. S3 restored before final run;
253. exact failing names/messages/results recorded;
254. no sensitivity mutation committed;
255. final full suite only after complete restoration;
256. final clearing-loop blob recorded;
257. final dispatcher blob recorded;
258. final source diff contains only intended V07 production corrections.

## Final validation / handoff
259. Godot version is 4.7.1 stable;
260. full root suite passes with exact total/pass/failure recorded;
261. zero final SCRIPT ERROR lines;
262. zero final Parse Error lines;
263. `m20_queue_free_smoke` passes;
264. V04 lifecycle smoke passes;
265. V05 lifecycle smoke passes;
266. new V07 frame-aware optional-node/renderer smoke passes;
267. `git diff --check` clean;
268. exact changed-file list recorded;
269. forbidden-scope grep recorded;
270. `CLAUDE_LOG_V07.md` exists;
271. log maps direct evidence to the criteria groups;
272. log records both pre-fix observations;
273. log records S1/S2/S3 failure + restoration;
274. final root task is M20-C001-V07;
275. final status is AWAITING_AUDIT;
276. final Required Actor is CHATGPT;
277. progress remains 290/719 = 40.33%;
278. overall remains 290/943 = 30.75%;
279. lastCompletedTaskId remains M19-C001-V06;
280. all SB-M20-001..014 remain open;
281. authorized V07 changes are committed + pushed to origin/main;
282. remote main is verified;
283. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
284. Claude does not begin M21;
285. out-of-scope production need uses BLOCKED instead of silent scope expansion;
286. clean V07 leaves final closure to auditor-authored V08 validation-only gate.

Total numbered criteria: **286**.
