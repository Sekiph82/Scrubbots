# M20-C001 — Final Exact-Evidence Audit Criteria V09

Canonical live tracker: repository-root `TASKS.md` only.

Production is immutable. Aggregate green counts do not substitute for missing direct evidence.

## Tracker / governance

1. root `TASKS.md` is the sole live tracker;
2. V08 independent audit exists before V09 start;
3. V09 full-surface freeze exists before V09 start;
4. V09 prompt and criteria exist before Claude starts;
5. starting task is M20-C001-V08;
6. starting status is AWAITING_AUDIT and actor CHATGPT;
7. starting progress is 290/719 main+ui and 290/943 overall;
8. lastCompletedTaskId is M19-C001-V06;
9. all SB-M20-001..014 start open;
10. V09 tracker-only IN_PROGRESS transition is committed;
11. tracker-only transition is pushed before any V09 test/smoke/support edit;
12. tracker-only transition is pushed before any temporary sensitivity mutation;
13. remote start transition is verified;
14. Claude log explicitly states no V09 validation edit or sensitivity mutation existed before successful start push;
15. owner/local work is preserved;
16. no `.hiveai` live tracker is recreated;
17. Claude creates no ChatGPT audit verdict;
18. Claude closes no SB-M20 task;

## Production immutability

19. starting clearing-loop blob equals `06391839523cbc27e88a4b3ef12b730012cd45fa`;
20. starting dispatcher blob equals `eee10149e4f116af6706beec832042352bf3a6dd`;
21. no committed V09 change exists under `scripts/**`;
22. temporary production mutations occur only after the start push;
23. each temporary mutation is restored before the next;
24. no temporary production mutation is committed;
25. final clearing-loop blob equals the locked V07 blob;
26. final dispatcher blob equals the locked V07 blob;
27. final committed `scripts/**` diff versus `e189ee8` is empty;
28. any exposed production defect causes BLOCKED without production correction;

## Owner claim lifecycle

29. a benign diagnostic assignment_arrived listener is connected BEFORE the first M20 loop bind;
30. first loop still binds with that pre-existing diagnostic observer;
31. diagnostic observer does not count as M20 ownership;
32. second different live loop bind fails;
33. second loop remains explicitly unbound;
34. second loop adds no M20 transaction callback;
35. second loop cleared_count stays zero;
36. second loop cannot successfully activate;
37. second loop reset mutates no canonical BoardState;
38. first loop remains coherent after second-loop rejection;
39. first loop one healthy arrival increments cleared_count exactly once;
40. claim/reset-only operations preserve detached BoardState snapshot;
41. owner-loop reset while owner is live does not release claim;
42. second live loop is still rejected after owner reset;
43. first loop remains usable after its own reset;
44. frame smoke proves old owner loop is genuinely GC'd;
45. WeakRef proves no strong cycle retains old owner loop;
46. old M20 transaction callback disappears after owner GC;
47. diagnostic listener remains independent through owner GC until teardown;
48. fresh loop binds after owner GC;
49. fresh loop contributes exactly one M20 transaction callback;
50. claim lifecycle itself does not mutate reservation or BoardState truth;

## agent_parent / renderer lifecycle regression

51. omitted agent_parent still means dispatcher self;
52. explicit null agent_parent still means dispatcher self;
53. scalar and arbitrary RefCounted parent reject cleanly;
54. queued explicit parent rejects;
55. truly-freed explicit parent rejects with no SCRIPT ERROR and no self fallback;
56. bind-time callback death of explicit parent prevents bind commit;
57. healthy explicit parent receives spawned agent;
58. parent destruction before dispatch fails closed with no active assignment/reservation/orphan;
59. owner IDs remain monotonic across parent failure;
60. explicit factory invalidation law remains unchanged;
61. omitted renderer headless path succeeds;
62. explicit null renderer headless path succeeds;
63. invalid scalar/container/RefCounted/wrong-Node renderer variants reject;
64. queued renderer before bind rejects;
65. truly-freed renderer before bind rejects;
66. failed renderer bind leaves no stale claim/connection/presence metadata;
67. second-bind preservation remains;
68. foreign-board original renderer makes coherence false;
69. queued/dead original renderer makes coherence false;
70. renderer queued/dead after real dispatch before arrival clears nothing and preserves raw candidate/reservation/assignment until reset;
71. healthy renderer clear repaints target alpha 0 and preserves unrelated pixel;

## Activation exact snapshots

72. snapshot stores detached full BoardState cell-state array;
73. snapshot stores dispatcher active count;
74. snapshot stores dispatcher next owner id;
75. snapshot stores exact reservation target->owner map;
76. snapshot stores reservation count;
77. snapshot stores all five slot palette IDs;
78. snapshot stores all five slot availability flags;
79. snapshot stores all five slot active flags;
80. post-check compares BoardState snapshot;
81. post-check compares active count;
82. post-check compares next owner id where no downstream owner allocation occurred;
83. post-check compares exact reservation map;
84. post-check compares reservation count;
85. post-check compares all five slot palette IDs;
86. post-check compares all five slot availability flags;
87. post-check compares all five slot active flags;
88. slot -1 rejects with exact snapshot preserved;
89. slot 5 rejects with exact snapshot preserved;
90. non-int slot rejects with exact snapshot preserved;
91. unavailable slot rejects with exact snapshot preserved;
92. NaN-x origin rejects with exact snapshot preserved;
93. NaN-y origin rejects with exact snapshot preserved;
94. +INF origin rejects with exact snapshot preserved;
95. -INF origin rejects with exact snapshot preserved;
96. NaN speed rejects with exact snapshot preserved;
97. +INF speed rejects with exact snapshot preserved;
98. -INF speed rejects with exact snapshot preserved;
99. zero speed rejects with exact snapshot preserved;
100. negative speed rejects with exact snapshot preserved;
101. absent-color/no-target returns NO_REACHABLE_TARGET with exact snapshot preserved;
102. enclosed matching target returns NO_REACHABLE_TARGET with exact snapshot preserved;
103. nested activation returns REENTRANT and creates no second owner/reservation;
104. activation during an active arrival drain returns REENTRANT;
105. reset during activation preflight returns RESETTING;
106. reset inside M19 dispatch returns RESETTING rather than stale SUCCESS;
107. post-dispatch M20 coherence loss returns COHERENCE_FAILED with deterministic cleanup;
108. downstream abort cases explicitly prove owner tokens are monotonic/not reused when already consumed;
109. M20 still contains no second target-selection/routing implementation;

## Arrival preflight exact invariants

110. fresh helper constructs real M19 ARRIVED-but-unconsumed assignment;
111. wrong owner yields PREFLIGHT_REJECTED;
112. wrong target yields PREFLIGHT_REJECTED;
113. wrong color yields PREFLIGHT_REJECTED;
114. wrong source agent yields PREFLIGHT_REJECTED;
115. unknown owner yields PREFLIGHT_REJECTED;
116. each forged identity uses fresh/restored exact arrangement;
117. each forged identity leaves BoardState exact snapshot unchanged;
118. each forged identity leaves cleared_count unchanged;
119. each forged identity preserves exact target->owner reservation;
120. each forged identity preserves exact owner->target reservation;
121. each forged identity leaves real dispatcher assignment pending;
122. each forged identity leaves raw target candidate present while target stays ACTIVE;
123. forged identity cases preserve arranged unrelated sentinel truth;
124. missing reservation is independently tested and rejected;
125. missing-reservation reject clears/finalizes nothing;
126. same-board `(T,O)` can be replaced by `T->O2` for the test;
127. original arrival against `T->O2` rejects;
128. `T->O2` exists immediately after failed preflight;
129. `T->O2` survives later pair-narrow reset;
130. ReservationState rebind to foreign board makes arrival reject;
131. foreign replacement reservation exists immediately after failed preflight;
132. foreign replacement reservation survives later reset;
133. foreign-reservation reject leaves original BoardState/cleared_count unchanged;
134. foreign-reservation reject does not silently finalize dispatcher assignment;
135. ColorCandidateIndex rebind to foreign board causes reject;
136. candidate-foreign reject preserves exact reservation and dispatcher assignment until cleanup;
137. ColorCandidateIndex `rebind(null)` causes clean reject;
138. candidate-unbound reject preserves exact reservation and dispatcher assignment until cleanup;
139. candidate drift/unbound leaves cleared_count zero;
140. externally-CLEARED target is rejected by M20;
141. externally-CLEARED target reject does not finalize dispatcher/release reservation;
142. renderer rebound foreign AFTER real assignment BEFORE arrival rejects clear;
143. renderer-foreign preflight reject preserves candidate/reservation/assignment until reset;
144. renderer queued/dead AFTER real assignment BEFORE arrival rejects clear;
145. renderer-dead preflight reject preserves candidate/reservation/assignment until reset;
146. stale replay after reset cannot clear;
147. duplicate current owner+agent arrival is deduped;
148. duplicate already-queued owner+agent arrival is independently deduped;
149. distinct nested arrival remains FIFO/lossless;
150. failed-preflight cleanup leaves no orphan agent after authorized reset/frame;

## SB-M20 exact final ledger

151. SB-M20-001 healthy sequence uses real production spine;
152. SB-M20-001 target is CLEARED;
153. SB-M20-001 target absent from raw candidate bucket;
154. SB-M20-001 ProductionAccessQuery reports OPEN;
155. SB-M20-001 `get_owner(target) == -1`;
156. SB-M20-001 `get_target_for_owner(owner) == -1`;
157. SB-M20-001 dispatcher owner absent;
158. SB-M20-001 agent queued for deletion;
159. SB-M20-001 configured renderer target alpha 0;
160. SB-M20-002 absent-color no-target yields NO_REACHABLE_TARGET;
161. SB-M20-002 absent-color case proves zero active/reservation/BoardState mutation;
162. SB-M20-002 enclosed matching target yields NO_REACHABLE_TARGET;
163. SB-M20-002 enclosed case proves zero active/reservation/BoardState mutation;
164. SB-M20-003 queue_free smoke proves actual frame destruction;
165. SB-M20-003 no orphan child remains and no return path occurs;
166. SB-M20-004 uses actual 1x1 and clears once;
167. SB-M20-004 1x1 is exhausted afterward;
168. SB-M20-005 one-color board repeatedly clears to exact exhaustion;
169. SB-M20-006 multi-color clears through corresponding slots;
170. SB-M20-006 unrelated other-color candidate truth is directly preserved;
171. SB-M20-007 produces five successful in-flight assignments;
172. SB-M20-007 five owner IDs are unique;
173. SB-M20-007 five targets are distinct;
174. SB-M20-007 every reservation pair is exact target->owner AND owner->target;
175. SB-M20-007 first arrival preserves other four exact pairs in both directions;
176. SB-M20-007 all five eventually finalize;
177. SB-M20-007 final dispatcher active count is zero;
178. SB-M20-007 final reservation count is zero;
179. SB-M20-008 Easy representative succeeds;
180. SB-M20-009 Medium representative succeeds;
181. SB-M20-010 Hard representative succeeds;
182. SB-M20-011 Very Hard representative succeeds;
183. SB-M20-012 59x59 path succeeds;
184. SB-M20-012 exactly intended target state changes through normal M20 path;
185. SB-M20-013 valid rectangular production board succeeds;
186. SB-M20-014 uses fresh exact desync matrix;
187. SB-M20-014 reset with multiple in-flight cleans active/reservation state;
188. multi-in-flight reset preserves BoardState and raw candidate truth;
189. AL-028 B is directly proven unreachable before A clear;
190. first real activation clears A;
191. second REAL activate_slot selects/routes B;
192. B exact reservation pair exists in both directions before B arrival;
193. B arrival clears/finalizes;
194. rapid scenario completes at least 25 sequential clears;
195. all five slot tuples are unchanged by representative ordinary success;
196. all five slot tuples are unchanged by representative ordinary failure;
197. CompleteClearingLoop normal clear adds no BoardState full scan;

## Rollback / reset / contention

198. candidate mutate-before-false is detected;
199. candidate mutate-before-false restores exact detached prestate or returns ROLLBACK_FAILED;
200. reservation mutate-before-false is detected;
201. reservation mutate-before-false restores exact reservation owner map or returns ROLLBACK_FAILED;
202. candidate true-without-postcondition is detected;
203. reservation true-without-postcondition is detected;
204. unrelated same-color candidate loss is restored exactly or fatal rollback reported;
205. healthy clear preserves unrelated different-color candidate truth;
206. reservation identity swap cannot pass exact owner-map proof;
207. missing-current-pair reset does not fabricate/delete unrelated reservation;
208. healthy pair-narrow reset removes only original pair;
209. healthy pair-narrow reset preserves unrelated reservation;
210. foreign-board replacement reservation survives reset;
211. same-board owner replacement reservation survives reset;
212. reset during candidate phase leaves no half-clear;
213. reset during reservation phase leaves no half-clear;
214. duplicate current arrival clears at most once;
215. duplicate queued arrival is deduped;
216. distinct nested arrival remains FIFO/lossless;
217. post-dispatch generation/reset barrier remains;
218. reset re-entry is safe;
219. owner counter remains monotonic/no reuse;
220. exact production dependency category gates are not widened for testing;

## Sensitivity S1-S6

221. S1 consumer-claim bypass is executed after start push;
222. S1 named V09 second-loop ownership assertion fails for intended reason;
223. S1 restored exactly before S2;
224. S2 agent_parent equality/null regression is executed;
225. S2 truly-freed explicit-parent assertion fails for intended reason;
226. S2 restored exactly before S3;
227. S3 renderer equality/null regression is executed;
228. S3 truly-freed renderer assertion fails for intended reason;
229. S3 restored exactly before S4;
230. S4 post-dispatch generation/reset barrier is weakened;
231. S4 reset-inside-dispatch assertion fails for intended reason;
232. S4 restored exactly before S5;
233. S5 exact owner-map proof is weakened;
234. S5 identity-swap assertion fails for intended reason;
235. S5 restored exactly before S6;
236. S6 pair-narrow reset is weakened to owner-wide;
237. S6 foreign/same-board replacement preservation assertion fails for intended reason;
238. S6 restored exactly before final validation;
239. no sensitivity mutation is committed;
240. exact failing assertion names/messages are logged;
241. locked production blob(s) are reverified after each restoration;

## Evidence traceability / final validation

242. `CLAUDE_LOG_V09.md` contains explicit rows for G-V08-01..06;
243. each gap row names exact test function/smoke;
244. each gap row names direct assertions rather than aggregate count;
245. each gap row records actual runtime result;
246. each applicable gap row names sensitivity mapping;
247. log distinguishes source/static, root-suite, frame-smoke and sensitivity evidence;
248. Godot version recorded as 4.7.1 stable;
249. final full root suite runs only after all sensitivity restoration;
250. final root suite exact total/pass/fail/result recorded;
251. `m20_queue_free_smoke.gd` passes;
252. `m20_v04_lifecycle_smoke.gd` passes;
253. `m20_v05_lifecycle_smoke.gd` passes;
254. `m20_v07_lifecycle_smoke.gd` passes;
255. `m20_v08_lifecycle_smoke.gd` passes;
256. any V09 lifecycle smoke passes;
257. each relevant final output is explicitly inspected for literal `SCRIPT ERROR`;
258. each relevant final output is explicitly inspected for literal `Parse Error`;
259. `git diff --check` is clean;
260. exact changed-file list is recorded;
261. no docs drive-by change exists;
262. final loop blob equals locked V07 blob;
263. final dispatcher blob equals locked V07 blob;
264. committed `scripts/**` diff vs `e189ee8` is empty;
265. all prior M19 V01-V06 tests remain enabled;
266. all prior M20 V01-V08 tests remain enabled;
267. no M21 real-art behavior is added;
268. no win/lose/scoring/session-complete/economy behavior is added;
269. no slot queue/cooldown/consumption policy is added;
270. final root task is M20-C001-V09;
271. final clean status is AWAITING_AUDIT and actor CHATGPT;
272. progress remains 290/719 main+ui and 290/943 overall;
273. lastCompletedTaskId remains M19-C001-V06;
274. all SB-M20-001..014 remain open;
275. allowed validation/log/tracker changes are committed and pushed;
276. remote main is verified;
277. Claude does not start M21;
278. production defect exposure causes BLOCKED with no fix;
279. clean V09 leaves final closure solely to independent ChatGPT audit;

Total numbered criteria: **279**.
