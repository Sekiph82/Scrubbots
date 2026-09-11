# M20-C001 — Strict-v2 Trust-Boundary / Exact-State Audit Criteria V03

Audit stage: **critical/stateful production correction**.

Canonical live tracker: repository-root `TASKS.md` only.

## Tracker / governance
1. synced root TASKS is the sole live tracker;
2. V02 independent audit exists before implementation;
3. V03 full-surface freeze exists;
4. V03 prompt exists;
5. starting task is M20-C001 V02 AWAITING_AUDIT / CHATGPT;
6. starting main+ui progress is 290/719 = 40.33%;
7. starting overall progress is 290/943 = 30.75%;
8. starting lastCompletedTaskId is M19-C001-V06;
9. all SB-M20-001..014 start open;
10. tracker-only V03 IN_PROGRESS transition is committed;
11. tracker-only transition is pushed before any V03 production edit;
12. tracker-only transition is pushed before any V03 test edit;
13. remote main is verified after start transition;
14. Required Actor becomes CLAUDE for implementation;
15. no .hiveai live tracker is recreated;
16. no competing current-state tracker is updated;
17. no CHATGPT_* artifact is modified by Claude;
18. no audit verdict is self-assigned;
19. no SB-M20 row is closed by Claude;
20. owner/local work is preserved.

## Accepted V02 architecture preservation
21. CompleteClearingLoop remains separate from dispatcher;
22. BoardState remains physical truth owner;
23. ColorCandidateIndex remains derived candidate owner;
24. ReservationState remains ownership owner;
25. TargetSelector remains target-choice owner;
26. RoutingSystem remains route owner;
27. ScrubbotAgent remains movement owner;
28. ScrubbotDispatcher remains assignment/agent identity owner;
29. renderer remains presentation-only;
30. ProductionAccessQuery still reads BoardState live;
31. no second access cache is introduced;
32. no RESERVED BoardState state is introduced;
33. clear order remains BoardState -> candidate -> reservation -> dispatcher -> renderer;
34. activation remains serialized;
35. distinct arrivals remain FIFO/lossless;
36. reset remains deferred/transactional;
37. M19 authenticated arrival bridge remains exact;
38. no M21+/win/lose/scoring/session behavior is added.

## Pre-fix sensitivity: subclass-open coherence
39. sensitivity is run against V02 source before exact-category correction;
40. candidate spoof subclass is accepted by V02 bind or exact observed blocker is recorded;
41. spoof can return bool true from is_bound_to for requested board;
42. spoof attempts to leave itself foreign after callback;
43. spoof behavior is repeated across multiple probes;
44. observed final candidate board identity is recorded;
45. observed V02 loop bind/coherence verdict is recorded;
46. test does not become green due unrelated category rejection;
47. reservation spoof equivalent is attempted or candidate proof is sufficient plus source proof for reservation symmetry;
48. temporary sensitivity instrumentation is not retained in final production.

## Pre-fix sensitivity: reservation identity swap
49. prestate includes current target/owner pair;
50. prestate includes unrelated U->ownerU pair;
51. prestate includes another valid V target;
52. mutate-false removes current pair;
53. mutate-false removes U->ownerU;
54. mutate-false reserves ownerU on V;
55. total count is kept compatible with V02 count-only verification;
56. callback returns false;
57. target BoardState is valid ACTIVE pre-arrival;
58. arrival is authentically pending so preflight is not the reason for failure;
59. V02 rollback outcome is recorded;
60. post-rollback owner of U is recorded;
61. post-rollback owner of V is recorded;
62. sensitivity proves or falsifies the count-only exactness gap directly;
63. unrelated reservation state is observed directly, not inferred from total count.

## Pre-fix sensitivity: candidate unrelated loss
64. prestate contains target T candidate;
65. prestate contains unrelated same-color U candidate;
66. target arrival is authentic;
67. fault removes T candidate truth;
68. fault removes unrelated U candidate truth;
69. callback returns false;
70. V02 target rollback outcome is recorded;
71. T membership after rollback is recorded;
72. U membership after rollback is recorded;
73. test directly distinguishes target restoration from unrelated restoration;
74. temporary sensitivity instrumentation is restored.

## Exact canonical dependency categories
75. exact BoardState accepted;
76. BoardState subclass rejected;
77. exact SlotSystem accepted;
78. SlotSystem subclass rejected;
79. exact ColorCandidateIndex accepted;
80. ColorCandidateIndex subclass rejected;
81. exact ReservationState accepted;
82. ReservationState subclass rejected;
83. exact ScrubbotDispatcher accepted;
84. ScrubbotDispatcher subclass rejected;
85. null renderer accepted;
86. exact live BoardRenderer accepted;
87. BoardRenderer subclass rejected;
88. wrong-category candidate rejected safely;
89. wrong-category reservation rejected safely;
90. rejected candidate subclass callback is not invoked;
91. rejected reservation subclass callback is not invoked;
92. failed category bind connects zero arrival callbacks;
93. failed category bind leaves loop unbound;
94. exact production bundle still binds successfully;
95. ordinary second bind remains false/preserve;
96. no production subclass acceptance exists solely for test injection.

## Exact bundle coherence after narrowing
97. exact candidate must be same-board bound;
98. exact reservation must be same-board bound;
99. dispatcher must be same-board/same-reservation bound;
100. renderer must be same-board bound if present;
101. same-shape foreign exact candidate bundle rejected;
102. same-shape foreign exact reservation bundle rejected;
103. wrong-board exact renderer rejected;
104. healthy bound loop is_coherent true;
105. candidate real rebind/drift after bind makes is_coherent false;
106. reservation real rebind/drift after bind makes is_coherent false;
107. incoherent activation makes no dispatch;
108. incoherent arrival makes no clear;
109. no repeated-probe claim is used as substitute for category safety.

## Reservation snapshot detachment
110. pre-arrival snapshot obtains detached reserved indices;
111. reserved snapshot is not a mutable internal reference;
112. pre-arrival snapshot records exact owner for each reserved target;
113. owner-map snapshot is detached;
114. snapshot records current target owner;
115. snapshot records current owner target;
116. snapshot records reservation count;
117. snapshot consistency is directly checked in tests;
118. malformed impossible exact production returns are not silently invented as valid data.

## Successful reservation resolve exactness
119. successful resolve removes current target;
120. successful resolve removes current owner mapping;
121. successful reserved set equals exactly pre-set minus current target;
122. no extra target disappears;
123. no new target appears;
124. every unrelated preexisting target keeps exact pre-owner;
125. reservation count equals exact expected set size;
126. count equality alone is not the sole postcondition;
127. successful transaction does not alter unrelated reservation pair A;
128. successful transaction does not alter unrelated reservation pair B where present;
129. five-slot first arrival preserves the other four exact pairs;
130. five-slot subsequent arrivals preserve not-yet-arrived pairs.

## Reservation rollback exactness
131. candidate failure rollback restores current reservation pair;
132. reservation failure rollback restores current reservation pair;
133. rollback reserved set equals exact pre-snapshot set;
134. rollback preserves every unrelated target index;
135. rollback preserves every unrelated owner mapping;
136. rollback introduces no foreign replacement target;
137. rollback reservation count equals exact set size;
138. rollback exact target owner matches prestate;
139. rollback exact owner target matches prestate;
140. dispatcher exact arrived assignment remains pending on ordinary rollback;
141. target BoardState returns ACTIVE;
142. target candidate membership returns present;
143. renderer remains source/opaque on rollback;
144. exact verification failure yields ROLLBACK_FAILED;
145. no ordinary CANDIDATE_ROLLBACK is reported with wrong reservation identity;
146. no ordinary RESERVATION_ROLLBACK is reported with wrong reservation identity.

## Candidate unrelated-truth composition
147. final production uses exact ColorCandidateIndex;
148. normal clear uses one sync_cell(target);
149. no normal-path full BoardState candidate rebuild is added;
150. test contains target T and same-color U;
151. successful clear removes T;
152. successful clear preserves U;
153. test includes another-color V candidate;
154. successful clear preserves V;
155. rollback of T preserves U;
156. rollback of T preserves V;
157. M13 strict regression proves sync_cell scope remains canonical;
158. M20 does not duplicate candidate bucket ownership.

## Rollback sensitivity after exact narrowing
159. final production bind rejects V02 candidate fault subclass;
160. final production bind rejects V02 reservation fault subclass;
161. historical V02 support files are not described as valid production collaborators;
162. rollback exceptional-path sensitivity is still exercised by an authorized test method;
163. if temporary ColorCandidateIndex mutation is used, pre-blob/hash recorded;
164. temporary candidate mutation is restored exactly;
165. final candidate production blob/hash equals original;
166. if temporary ReservationState mutation is used, pre-blob/hash recorded;
167. temporary reservation mutation is restored exactly;
168. final reservation production blob/hash equals original;
169. no temporary fault code is committed upstream;
170. full M13 regression runs after restoration;
171. full M14 regression runs after restoration;
172. rollback logic is not declared proven solely because canonical failure is normally unreachable.

## Current-arrival identity / duplicate defense
173. loop stores a private current-arrival identity while processing;
174. current identity includes at least unique owner and exact agent;
175. current identity is set before transaction body;
176. current identity is cleared after successful transaction;
177. current identity is cleared after preflight rejection;
178. current identity is cleared after candidate rollback;
179. current identity is cleared after reservation rollback;
180. current identity is cleared after reset-aborted path;
181. current identity is cleared after rollback-failed path;
182. enqueue rejects duplicate of current arrival;
183. enqueue rejects duplicate already in queue;
184. duplicate current arrival does not increment cleared_count twice;
185. duplicate current arrival does not resolve reservation twice;
186. duplicate current arrival does not call dispatcher finalization twice;
187. duplicate current arrival does not overwrite successful state with a misleading second outcome where observable;
188. distinct second owner/agent is still queued;
189. distinct queued arrival preserves FIFO order;
190. distinct queued arrival clears after current transaction;
191. current identity is not exposed by mutable public query;
192. queue is not exposed by mutable public query;
193. reset clears stale queued arrivals;
194. reset leaves no stale current-arrival bookkeeping after drain unwinds.

## Activation preservation
195. negative slot rejected;
196. slot 5+ rejected;
197. non-int slot rejected;
198. unavailable slot rejected;
199. invalid origin rejected;
200. invalid speed rejected;
201. nested activation remains REENTRANT/no side effect;
202. activation during arrival remains rejected;
203. reset during activation remains RESETTING/no dispatch;
204. one activation creates at most one assignment;
205. no-target produces no agent/reservation/board mutation;
206. slot state remains unchanged.

## Arrival authentication preservation
207. wrong owner cannot clear;
208. wrong target cannot clear;
209. wrong color cannot clear;
210. wrong source agent cannot clear;
211. unknown owner cannot clear;
212. reservation missing preflight cannot clear;
213. wrong reservation owner cannot clear;
214. target already CLEARED cannot clear again;
215. candidate drift cannot clear;
216. dispatcher mismatch cannot clear;
217. renderer incoherence cannot clear when bound;
218. exact healthy arrival accepted;
219. failed preflight leaves dispatcher arrived assignment held until reset/recovery;
220. failed-preflight reset recovery still works.

## Transaction order / postconditions
221. BoardState mutation remains first authoritative mutation;
222. target becomes exactly CLEARED;
223. target color remains immutable;
224. candidate target disappears after BoardState clear;
225. reservation resolves only after candidate success;
226. dispatcher finalizes only after reservation exact postcondition;
227. renderer updates only after dispatcher finalization;
228. renderer absent remains valid;
229. renderer target alpha becomes 0 on success;
230. unrelated renderer pixel stays unchanged;
231. ProductionAccessQuery sees cleared target OPEN without explicit cache update;
232. cleared_count increments once only after full authoritative commit;
233. finalize failure does not repaint false-clear;
234. postcondition failure cannot be reported as CLEARED.

## Reset / lifecycle preservation
235. reset with no transaction remains safe;
236. reset during candidate phase aborts transaction;
237. reset during reservation phase aborts transaction;
238. reset does not run dispatcher reset mid-mutated tuple;
239. reset rollback proves target ACTIVE/candidate restored before heavy reset;
240. reset removes in-flight dispatcher entries at safe point;
241. reset releases reservations at safe point;
242. reset preserves already-CLEARED cells;
243. reset does not rewind owner IDs;
244. stale completion after reset cannot clear;
245. reset clears queued stale arrivals;
246. repeated reset is stable;
247. later activation recovers.

## AL-028 full second-dispatch preservation
248. B initially unreachable;
249. A is reachable gate/blocker;
250. first activation selects A;
251. A arrival clears A;
252. A leaves candidate truth;
253. ProductionAccessQuery sees A OPEN;
254. second real activate_slot call occurs;
255. second dispatch selects B;
256. B has exact reservation;
257. B agent reaches arrival;
258. B becomes CLEARED;
259. B reservation resolves;
260. B dispatcher owner finalizes.

## True 1x1 / dimension coverage
261. actual width is 1;
262. actual height is 1;
263. actual cell_count is 1;
264. one ACTIVE target dispatches;
265. arrival clears the sole cell;
266. second activation reports no work;
267. Easy dimension coverage remains;
268. Medium coverage remains;
269. Hard coverage remains;
270. Very Hard coverage remains;
271. 59x59 coverage remains;
272. rectangular coverage remains;
273. no square-only assumption introduced.

## Five-slot identity preservation
274. exactly five configured slots tested;
275. five activations succeed when topology permits;
276. five owner IDs are unique;
277. five target indices are distinct;
278. five exact reservation pairs exist before arrivals;
279. dispatcher active count is five;
280. first arrival resolves only its pair;
281. other four exact reservations remain;
282. other four dispatcher assignments remain;
283. all five eventually clear;
284. no active dispatcher entries remain after all;
285. no corresponding reservations remain after all.

## Deferred destruction preservation
286. successful finalize queues/deferred-frees exact agent;
287. dedicated smoke still runs separately;
288. smoke observes queued deletion immediately where applicable;
289. smoke advances at least one SceneTree frame;
290. agent instance is invalid/freed afterward;
291. no orphan child remains;
292. no return-to-slot agent is spawned.

## Performance / architecture
293. normal clear performs one BoardState target mutation;
294. normal clear uses single-cell candidate sync;
295. normal clear does not full-scan BoardState;
296. reservation exact snapshot may scale with live reservations, not board cells;
297. renderer uses single-cell update;
298. no one-Node-per-cell architecture;
299. no second access cache;
300. 59x59 remains structurally bounded;
301. rapid 25+ sequential clears remain green.

## Upstream regression lock
302. BoardState canonical tests green;
303. BoardRenderer ACTIVE/CLEARED tests green;
304. GameplaySession tests green;
305. SlotSystem tests green;
306. M13 strict candidate tests green;
307. M14 strict reservation tests green;
308. M15-C002 final selector tests green;
309. M16 routing tests green;
310. M17 production routing tests green;
311. M18 agent tests green;
312. all M19 V01-V06 tests green;
313. M19 arrival identity remains exact;
314. M19 reset queue_free behavior remains safe;
315. no M19 BoardState clearing is introduced.

## Scope / design gates
316. no GameplaySession.complete auto-call;
317. no win condition;
318. no lose condition;
319. no scoring;
320. no economy/currency;
321. no auto next-bot dispatch;
322. no slot queue/cooldown/depletion rule;
323. no collision-radius rule;
324. no M21 owner-art implementation;
325. no production slot UI;
326. no LevelData mutation;
327. no palette-law change;
328. no ACTIVE/CLEARED law change;
329. final production changes are limited to M20 clearing loop unless blocker documented;
330. no final upstream M13/M14/M19 production change remains.

## Documentation / evidence
331. architecture docs still describe corrected V02 order;
332. docs do not claim subclass-open candidate/reservation production support after V03;
333. CLAUDE_LOG_V03 maps evidence to V03 groups;
334. log records pre-fix subclass-spoof sensitivity;
335. log records pre-fix reservation identity-swap sensitivity;
336. log records candidate unrelated-loss sensitivity;
337. log records temporary mutation restoration where used;
338. log records exact changed files;
339. log records failed attempts/fixes;
340. historical audit artifacts are not rewritten.

## Final validation / handoff
341. godot --version reports 4.7.1 stable;
342. targeted V03 exact-category tests pass;
343. targeted reservation-set/owner-map tests pass;
344. targeted duplicate-current-arrival tests pass;
345. full root headless suite runs from final V03 state;
346. full root suite has zero assertion failures;
347. final root run has zero new SCRIPT ERROR / Parse Error;
348. dedicated queue-free smoke passes;
349. git diff --check clean for cycle-owned changes;
350. no temporary sensitivity mutation remains;
351. final candidate production source equals intended upstream source;
352. final reservation production source equals intended upstream source;
353. no SB-M20 task is closed by Claude;
354. final milestone remains M20;
355. final sprint is M20-C001 V03;
356. final current task is M20-C001-V03;
357. final status is AWAITING_AUDIT;
358. final Required Actor is CHATGPT;
359. final progress remains 290/719 = 40.33%;
360. final overall remains 290/943 = 30.75%;
361. final lastCompletedTaskId remains M19-C001-V06;
362. Next Task/Action points to independent ChatGPT V03 audit;
363. implementation/tests/log/tracker handoff are pushed to origin/main;
364. remote main is verified after push;
365. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
366. Claude does not self-audit;
367. successful return is exactly AWAITING_AUDIT;
368. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
369. frozen-scope upstream blocker uses BLOCKED;
370. ChatGPT records independent runtime availability during V03 audit.

## Audit disposition

V03 changes production in a critical/stateful orchestration path. A clean V03 is
normally followed by an auditor-authored validation-only V04 before final closure
of `SB-M20-001..014`, unless equivalent independent runtime E3 evidence is
available.
