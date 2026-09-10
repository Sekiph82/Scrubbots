# M20-C001 — Strict-v2 Transaction Correction Audit Criteria V02

Audit stage: **critical/stateful correction**.

Canonical live tracker: repository-root `TASKS.md` only.

A green aggregate suite is necessary but not sufficient. Every callback/re-entry/rollback criterion below needs direct observable evidence or a source proof that makes the challenged callback class impossible by exact dependency narrowing.

## Tracker / governance
1. synced root `TASKS.md` is the sole live tracker;
2. V01 audit exists before V02 implementation starts;
3. V02 prompt exists before implementation starts;
4. V02 criteria exist before implementation starts;
5. starting milestone remains M20;
6. starting progress remains 290/719 main+ui;
7. starting overall progress remains 290/943;
8. starting lastCompletedTaskId remains M19-C001-V06;
9. V02 tracker transition changes current task to M20-C001-V02;
10. V02 tracker transition sets IN_PROGRESS / CLAUDE;
11. tracker-only IN_PROGRESS commit is pushed before any V02 production edit;
12. tracker-only IN_PROGRESS commit is pushed before any V02 test edit;
13. remote main is verified to contain the start transition before implementation;
14. no `.hiveai/*` live tracker is recreated;
15. no competing dashboard/session-index current-state tracker is updated;
16. no SB-M20 checkbox is closed by Claude;
17. no M21+ task row is changed;
18. no `CHATGPT_*` artifact is modified by Claude;
19. no audit verdict is self-assigned by Claude;
20. owner/local pre-existing working-tree changes are preserved.

## Accepted architecture preservation
21. `CompleteClearingLoop` remains a separate M20 orchestrator;
22. M20 does not absorb TargetSelector logic;
23. M20 does not absorb routing algorithm logic;
24. M20 does not own ReservationState storage;
25. M20 does not own ColorCandidateIndex buckets;
26. M20 does not own BoardState storage;
27. M20 does not move movement into the orchestrator;
28. ScrubbotDispatcher remains assignment/agent identity owner;
29. BoardState remains physical ACTIVE/CLEARED truth owner;
30. ColorCandidateIndex remains derived ACTIVE candidate truth;
31. ReservationState remains owner<->target truth;
32. ProductionAccessQuery continues reading BoardState live;
33. no second reachability/access cache is introduced;
34. no RESERVED BoardState state is introduced;
35. no per-cell Node architecture is introduced;
36. explicit preload convention remains used for M20 core;
37. M19 authenticated arrival bridge remains owner/target/color/exact-agent based;
38. M19 bridge remains exactly-once for one assignment;
39. M20 never listens directly to raw agent completion as clearing authority;
40. normal M20 success remains one target clear per authenticated assignment.

## Bind transaction / F-M20-STRICT-001
41. loop exposes an initialization-only bind;
42. a bind-in-progress guard exists or accepted dependency narrowing makes nested bind impossible;
43. the bind guard is armed before the first accepted external callback;
44. no dispatcher arrival callback is connected before all bind validation succeeds;
45. failed fresh bind leaves `_bound == false`;
46. failed fresh bind leaves no arrival signal connection;
47. successful bind creates exactly one arrival connection;
48. nested bind from candidate coherence callback returns false;
49. nested candidate-callback bind cannot replace the outer requested bundle;
50. nested candidate-callback bind creates no ghost signal connection;
51. nested bind from reservation coherence callback returns false;
52. nested reservation-callback bind cannot replace the outer requested bundle;
53. nested reservation-callback bind creates no ghost signal connection;
54. callback-induced candidate foreign-board drift is detected before commit;
55. callback-induced reservation foreign-board drift is detected before commit;
56. same-size different-board drift still fails by identity, not shape;
57. dispatcher exact board+reservation coherence is proven at final bind commit;
58. candidate exact-board coherence is proven at final bind commit;
59. reservation exact-board coherence is proven at final bind commit;
60. renderer exact-board coherence is proven at final bind commit when present;
61. slot system remains configured at final bind commit;
62. slot count remains exactly five at final bind commit;
63. dispatcher active count is still zero at final bind commit;
64. a callback that changes one validated fact before commit causes bind failure;
65. ordinary second bind after success returns false;
66. ordinary second bind preserves original bundle;
67. ordinary second bind preserves original signal connection count;
68. ordinary second bind does not reset/cancel original dispatcher state;
69. no destructive public rebind is introduced;
70. no read-only query leaks mutable dependency references or internal queues.

## Activation transaction / F-M20-STRICT-002
71. at most one `activate_slot()` transaction runs at a time;
72. activation serial guard is active before accepted live-coherence callbacks;
73. activation is rejected while an arrival transaction is committing;
74. activation is rejected while reset is active/requested;
75. nested activation from candidate coherence callback does not reach dispatcher;
76. nested activation from reservation coherence callback does not reach dispatcher;
77. nested activation creates zero additional reservation;
78. nested activation creates zero additional agent;
79. nested activation does not advance dispatcher owner id;
80. nested activation does not mutate slot state;
81. reset injected from activation coherence callback prevents outer dispatcher call;
82. reset-aborted activation creates zero reservation;
83. reset-aborted activation creates zero agent;
84. reset-aborted activation does not advance owner id;
85. callback-induced bundle drift during activation is detected before dispatch;
86. drift-aborted activation creates zero reservation/agent;
87. invalid slot id still fails before dispatch;
88. non-int slot id still fails before dispatch;
89. unavailable slot still fails before dispatch;
90. invalid/non-finite origin still fails before dispatch;
91. invalid/non-positive speed still fails before dispatch;
92. slot palette still drives the dispatch color;
93. successful activation still mutates no slot palette/availability/activity fields;
94. one healthy activation creates at most one new Scrubbot;
95. later ordinary activation works after a rejected nested activation;
96. later ordinary activation works after reset-aborted activation.

## Lossless serial arrival processing / F-M20-STRICT-006
97. at most one cross-module arrival transaction mutates truth at a time;
98. an arrival-in-progress guard exists;
99. distinct authenticated nested arrival cannot execute concurrently with first;
100. distinct authenticated nested arrival is not silently discarded;
101. distinct nested arrival is queued/deferred or equivalently preserved losslessly;
102. queued arrival stores immutable owner identity;
103. queued arrival stores immutable target identity;
104. queued arrival stores immutable color identity;
105. queued arrival stores exact agent identity;
106. duplicate same assignment is not queued twice;
107. duplicate same assignment cannot clear twice;
108. after first transaction completes, queued distinct arrival is processed;
109. two nested distinct healthy arrivals each clear exactly their own target once;
110. first arrival never resolves second arrival reservation;
111. first arrival never finalizes second dispatcher owner;
112. queued item is re-authenticated before mutation when drained;
113. stale queued arrival after reset is discarded safely;
114. private arrival queue is not exposed by reference;
115. activation attempted during arrival commit cannot start a new dispatch;
116. arrival processing remains usable after queue drains.

## Reset/generation transaction / F-M20-STRICT-006
117. loop owns a reset-in-progress/request or generation mechanism;
118. reset is re-entry-safe at M20 level;
119. reset request during activation is observed before new downstream dispatch;
120. reset request during arrival is observed before a new downstream phase begins;
121. reset does not call dispatcher reset in the middle of an un-reconciled partial tuple;
122. reset before BoardState mutation produces zero clear;
123. reset inside candidate sync triggers rollback/reconciliation before dispatcher reset;
124. reset inside reservation resolve triggers rollback/reconciliation before dispatcher reset;
125. if finalization remains callback-capable, reset around finalization is explicitly handled/tested;
126. reset clears queued stale arrival items;
127. final reset state has zero dispatcher active entries for cancelled work;
128. final reset state has zero matching reservations for cancelled work;
129. reset preserves already-committed CLEARED cells;
130. reset preserves candidate truth matching BoardState;
131. reset does not resurrect a successful clear;
132. reset does not rewind dispatcher owner ids;
133. reset during arrival leaves no orphan agent;
134. reset during arrival leaves no CLEARED+candidate contradiction;
135. reset during arrival leaves no CLEARED+reserved contradiction;
136. reset during arrival leaves no ACTIVE+candidate-missing contradiction;
137. second reset is stable/idempotent;
138. stale completion after reset cannot clear;
139. later healthy activation succeeds after reset.

## V02 transaction order / F-M20-STRICT-004
140. exact authenticated preflight happens before physical mutation;
141. detached/prestate snapshot needed for rollback is captured before mutation;
142. BoardState ACTIVE->CLEARED is authoritative step 1;
143. candidate single-cell sync is step 2;
144. reservation exact resolve is step 3;
145. dispatcher exact finalization is step 4;
146. renderer repaint is step 5 after gameplay ownership finalization;
147. renderer callback never sits between reservation resolve and dispatcher finalization;
148. ProductionAccessQuery receives no explicit update/cache mutation;
149. normal path does not full-scan BoardState;
150. normal path does not call full candidate rebuild/rebind;
151. normal path mutates exactly one BoardState cell;
152. normal path candidate work is one-cell sync;
153. normal path reservation resolution remains O(1)-style owner pair removal;
154. normal path dispatcher finalization removes exactly one owner;
155. normal renderer update contains exactly the target index.

## Detached pre-state / rollback evidence
156. pre-state captures target index;
157. pre-state captures target original color;
158. pre-state captures target ACTIVE state;
159. pre-state captures raw candidate membership without reservation exclusion;
160. pre-state captures reservation count;
161. pre-state captures detached reserved-index set;
162. pre-state captures exact owner->target;
163. pre-state captures exact target->owner;
164. pre-state captures dispatcher active count;
165. pre-state captures exact dispatcher arrival-pending truth;
166. renderer target pixel/source appearance is captured when required for rollback proof;
167. snapshot collections are detached from collaborator-owned mutable state;
168. pre-state capture itself does not mutate gameplay truth;
169. pre-state capture does not scan all BoardState cells.

## Success postconditions
170. BoardState write return true is followed by direct state check;
171. BoardState target is exactly CLEARED after successful write;
172. target color id remains unchanged after successful write;
173. candidate `sync_cell` return true is followed by direct candidate postcondition;
174. candidate remains exact-bound to original board after successful sync;
175. raw candidate query without reservation exclusion no longer contains target;
176. unrelated same-color candidate remains present;
177. unrelated other-color candidate remains unchanged;
178. reservation resolve return true is followed by direct owner->target postcondition;
179. reservation resolve return true is followed by direct target->owner postcondition;
180. exact owner->target becomes -1;
181. exact target->owner becomes -1;
182. reservation count is pre-count minus one;
183. detached reserved-index set is pre-set minus exactly target;
184. unrelated reservation remains unchanged;
185. dispatcher finalize return true is followed by exact owner absence check;
186. dispatcher active count is pre-count minus one;
187. unrelated active dispatcher assignment remains present;
188. M20 cleared count increments only after authoritative gameplay commit succeeds;
189. one success increments cleared count exactly once;
190. successful final tuple has no active dispatcher owner/reservation/candidate for target.

## Candidate failure / mutation-sensitive rollback
191. ordinary candidate false-without-mutation is still covered;
192. candidate mutation-before-false test actually removes target membership first;
193. candidate mutation-before-false then returns false;
194. M20 detects failure and does not continue to reservation resolve;
195. BoardState is restored exactly ACTIVE;
196. target raw candidate membership is restored;
197. candidate remains/rebecomes exact-bound to original board;
198. original reservation pair remains held;
199. dispatcher arrived assignment remains held;
200. unrelated candidates remain unchanged;
201. unrelated reservations remain unchanged;
202. cleared count does not increment;
203. renderer-bound mutation-before-false test leaves target visually ACTIVE/opaque;
204. candidate neutralize/rebind-before-false is challenged where subclass seam remains accepted;
205. neutralized/drifted candidate is restored to original-board canonical truth or explicit rollback failure is surfaced;
206. exceptional candidate full rebuild/rebind is used only on rollback path, not normal path.

## Candidate lying-success postcondition
207. candidate test can return true while intentionally leaving target in raw candidates;
208. missing candidate postcondition is detected;
209. reservation resolve is not allowed to make a successful commit after candidate postcondition failure;
210. BoardState is restored ACTIVE;
211. candidate truth is restored/proven;
212. original reservation remains held;
213. dispatcher assignment remains held;
214. cleared count remains unchanged;
215. failure is not mislabeled as a successful clear.

## Reservation failure / mutation-sensitive rollback
216. ordinary reservation false-without-mutation remains covered;
217. reservation mutation-before-false test actually removes exact pair first;
218. reservation mutation-before-false then returns false;
219. M20 detects failure and does not finalize dispatcher owner;
220. BoardState is restored ACTIVE;
221. raw candidate membership is restored;
222. exact owner->target reservation is restored;
223. exact target->owner reservation is restored;
224. reservation count/set equals exact pre-state after rollback;
225. unrelated reservations remain unchanged;
226. dispatcher arrived assignment remains held;
227. cleared count remains unchanged;
228. renderer-bound reservation rollback leaves target visually ACTIVE/opaque;
229. restoring removed reservation occurs only after BoardState/candidate are ACTIVE/coherent;
230. reservation restore is verified rather than assumed from return value.

## Reservation lying-success postcondition
231. reservation test can return true without removing exact pair;
232. missing reservation postcondition is detected;
233. dispatcher finalization does not occur after missing reservation postcondition;
234. BoardState/candidate are restored to pre-arrival state;
235. exact reservation pair remains/restores held;
236. dispatcher assignment remains held;
237. cleared count remains unchanged;
238. no renderer false-clear is emitted.

## Rollback failure handling
239. rollback helper returns/proves success rather than being best-effort void;
240. rollback directly verifies BoardState ACTIVE;
241. rollback directly verifies candidate raw membership;
242. rollback directly verifies candidate original-board coherence;
243. rollback directly verifies reservation owner->target;
244. rollback directly verifies reservation target->owner;
245. rollback directly verifies reservation count/set pre-state;
246. rollback directly verifies dispatcher exact arrived assignment is still pending when rollback is intended to hold it;
247. rollback preserves unrelated dispatcher assignments;
248. rollback with renderer proves pre-clear/source appearance;
249. any rollback that cannot prove the tuple surfaces explicit ROLLBACK_FAILED or equivalent fatal outcome;
250. rollback failure is never reported as CANDIDATE_ROLLBACK/RESERVATION_ROLLBACK success;
251. rollback failure uses a deterministic safe-recovery path;
252. safe recovery does not leave an untracked orphan agent;
253. safe recovery does not silently erase unrelated ownership.

## Dispatcher finalization terminal boundary
254. dispatcher finalization occurs before renderer repaint;
255. wrong/mismatched finalization still returns false/no mutation;
256. healthy exact production finalization succeeds after reservation postcondition;
257. finalize false causes no renderer update;
258. finalize false causes no cleared-count increment;
259. if dispatcher still retains exact arrived owner after false, pre-arrival BoardState/candidate/reservation tuple is restored;
260. finalization-failure rollback is directly proven;
261. no path reports CLEARED outcome while dispatcher owner remains active;
262. if arbitrary dispatcher subclasses are rejected by V02 binding, a source/test proof confirms mutation-before-lie dispatcher class is impossible at M20 boundary;
263. if dispatcher subclasses remain accepted, mutation-before-false/true-without-postcondition finalization is directly challenged;
264. M19 dispatcher does not gain BoardState/candidate/reservation mutation ownership.

## Renderer post-commit presentation
265. null renderer remains valid headless configuration;
266. bound renderer is exact-board coherent;
267. renderer is revalidated/live immediately before repaint;
268. renderer repaint happens only after dispatcher finalization postcondition;
269. successful renderer target becomes alpha 0 within RGBA8 tolerance;
270. successful renderer unrelated pixel remains unchanged;
271. candidate rollback does not show target transparent;
272. reservation rollback does not show target transparent;
273. finalize rollback/failure does not show target transparent;
274. renderer does not mutate BoardState;
275. renderer presentation failure/staleness after gameplay commit does not roll authoritative gameplay truth backward;
276. renderer failure is not allowed to resurrect reservation/dispatcher ownership after successful authoritative finalization.

## Failed-preflight one-shot recovery / F-M20-STRICT-003
277. test creates a genuine M19-authenticated arrived assignment;
278. M20 preflight is then intentionally made to reject through one desync;
279. preflight rejection mutates no BoardState cell;
280. preflight rejection does not falsely remove candidate membership;
281. preflight rejection leaves dispatcher arrived assignment held before recovery;
282. any surviving reservation truth is observed exactly before recovery;
283. `loop.reset()` removes the stranded dispatcher active assignment;
284. `loop.reset()` removes any still-held reservation belonging to stranded assignment;
285. reset leaves BoardState unchanged;
286. candidate truth matches unchanged BoardState after recovery;
287. stale replay after recovery cannot clear;
288. later healthy activation succeeds when work remains;
289. M19 exactly-once arrival bridge remains unchanged.

## AL-028 newly-opened second-dispatch proof / F-M20-STRICT-005
290. real production bundle contains gate A and blocked target B;
291. B is directly proven unreachable before A clears;
292. A is directly proven reachable before clear;
293. pre-A-clear activation for B/color produces no dispatch when fixture permits direct color isolation;
294. loop activation dispatches A through real TargetSelector/ProductionRoutingSystem;
295. A is the exact reserved/selected target;
296. A arrives and clears successfully;
297. A leaves raw candidate truth;
298. ProductionAccessQuery sees A OPEN with no explicit access refresh;
299. second call to `CompleteClearingLoop.activate_slot()` is executed after A clears;
300. second activation succeeds through real production stack;
301. second activation selects/reserves exact B;
302. routing remains ProductionRoutingSystem and does not retarget;
303. B agent reaches arrival;
304. B becomes CLEARED;
305. B candidate/reservation/dispatcher final tuple is synchronized;
306. no explicit access cache reset/rebuild is introduced.

## True 1x1 generic board
307. test BoardState width is exactly 1;
308. test BoardState height is exactly 1;
309. test BoardState cell count is exactly 1;
310. sole cell starts ACTIVE;
311. slot activation dispatches to the sole cell from outside-board origin;
312. sole cell arrival becomes CLEARED;
313. sole cell leaves candidate truth;
314. sole reservation resolves;
315. sole dispatcher owner finalizes;
316. second activation returns no work;
317. 1x1 remains a TEST/generic-engine fixture and is not claimed production-sized.

## Five-slot direct identity proof
318. real configured SlotSystem has exactly five slots;
319. five healthy activations produce five success results when topology permits;
320. five owner IDs are all unique;
321. five target indices are all distinct;
322. each target has the exact expected ReservationState owner;
323. each owner maps back to the exact expected target;
324. dispatcher active count is exactly five before arrivals;
325. first arrival clears/finalizes only its own tuple;
326. other four target states remain ACTIVE after first arrival;
327. other four reservations remain exact after first arrival;
328. other four dispatcher owners remain active after first arrival;
329. remaining four arrivals resolve independently;
330. after all five, dispatcher active count is zero;
331. after all five, corresponding reservation count is zero;
332. five-slot operations do not mutate slot palette/availability/activity state.

## Deferred agent destruction proof
333. successful finalization queues/defer-destroys exact arrived agent;
334. immediately after finalization the agent cannot be reused/returned by M20;
335. dedicated frame-aware smoke test exists if root runner cannot await a frame;
336. frame-aware smoke uses real M20/M19 agent path;
337. at least one SceneTree frame/queued-free processing step occurs;
338. after processing, exact agent instance is no longer valid;
339. agent parent contains no orphan returned bot;
340. smoke exits nonzero on failed destruction proof;
341. smoke command/result is recorded separately in CLAUDE_LOG_V02.

## Scale / performance / deterministic integration
342. one-color repeated clear still exhausts deterministically;
343. mixed-color clearing still clears only requested colors;
344. no raw candidate still produces no agent;
345. enclosed matching ACTIVE candidate still produces no agent;
346. route failure still does not silently retarget;
347. rapid >=25 sequential activate/arrival cycles pass;
348. owner ids remain monotonic through sequential clears;
349. Easy production dimensions exercised;
350. Medium production dimensions exercised;
351. Hard production dimensions exercised;
352. Very Hard production dimensions exercised;
353. 59x59 maximum exercised;
354. rectangular production board exercised;
355. no square-only assumption introduced;
356. normal healthy clear performs no BoardState full scan;
357. normal healthy clear uses one-cell candidate sync;
358. normal healthy clear uses one-cell renderer update when present;
359. no per-cell Node tree introduced;
360. no second access cache introduced.

## Upstream regression lock
361. BoardState canonical-state regression suite remains green;
362. BoardRenderer ACTIVE/CLEARED regression suite remains green;
363. GameplaySession regression suite remains green;
364. SlotSystem regression suite remains green;
365. ColorCandidateIndex strict regressions remain green;
366. ReservationState strict regressions remain green;
367. M15-C002 TargetSelector final regressions remain green;
368. M16 routing-contract regressions remain green;
369. M17 production-routing regressions remain green;
370. M18 agent regressions remain green;
371. every M19 V01-V06 regression remains green;
372. M19 completion identity remains exact owner/target/color/source-agent;
373. M19 invalid cached route/no-retarget law remains unchanged;
374. M19 reset/owner-id monotonicity remains unchanged;
375. M19 dispatcher still does not clear BoardState or resolve successful reservation by itself.

## Scope / design gates
376. no automatic `GameplaySession.complete()` call;
377. no win-condition implementation;
378. no lose-condition implementation;
379. no scoring implementation;
380. no win-streak reward implementation;
381. no currency/economy implementation;
382. no automatic next-bot dispatch after clear;
383. no slot queue rule introduced;
384. no slot cooldown rule introduced;
385. no slot depletion/consumption rule introduced;
386. no collision-radius gameplay rule invented;
387. no M21 owner-art/content implementation;
388. no production slot UI implementation;
389. no LevelData source mutation;
390. no palette-law change;
391. no ACTIVE/CLEARED semantic change;
392. no upstream production rewrite outside authorized M20/M19 narrow seam;
393. if a broader upstream change proves necessary Claude stops BLOCKED rather than silently widening scope.

## V02 sensitivity evidence
394. V01 nested-bind vulnerability is exercised pre-fix or source-sensitivity is recorded concretely;
395. V01 reset-during-arrival vulnerability is exercised pre-fix;
396. V01 candidate mutation-before-false weakness is exercised pre-fix;
397. V01 reservation mutation-before-false weakness is exercised pre-fix;
398. candidate true-without-postcondition sensitivity is shown;
399. reservation true-without-postcondition sensitivity is shown;
400. pre-fix tests use valid/authenticated arrival inputs so failures are not caused by unrelated preflight rejection;
401. mutation-sensitive tests inspect authoritative state after failure, not only outcome labels;
402. at least one load-bearing V02 postcondition/synchronization test is mutation/sensitivity checked by temporary code perturbation or equivalent direct proof;
403. temporary sensitivity mutations are fully restored before final commit;
404. no temporary mutation remains in production/test files.

## Documentation / evidence
405. durable architecture docs reflect renderer-after-finalization V02 ordering;
406. docs describe serial/lossless arrival processing;
407. docs describe M20 reset transaction semantics without inventing win/session policy;
408. docs retain M19 separation;
409. historical audits are not rewritten;
410. `CLAUDE_LOG_V02.md` maps evidence by criterion group;
411. log records pre-fix sensitivity observations individually;
412. log records failed implementation/test attempts rather than erasing them;
413. log records exact production/test changed-file list;
414. log records exact relevant commit chain;
415. log records owner-work preservation.

## Final validation / handoff
416. `godot --version` reports Godot 4.7.1 stable;
417. final full root headless suite runs from final V02 implementation state;
418. final full root suite has zero assertion failures;
419. final run has zero new SCRIPT ERROR / Parse Error;
420. dedicated queue-free frame smoke runs separately;
421. queue-free smoke passes;
422. `git diff --check` is clean for cycle-owned files;
423. no SB-M20 checkbox is changed to `[x]` by Claude;
424. final root tracker current milestone remains M20;
425. final root tracker current sprint is M20-C001 V02;
426. final root tracker current task is M20-C001-V02;
427. final root tracker status is AWAITING_AUDIT;
428. final root tracker required actor is CHATGPT;
429. final main+ui progress remains 290/719 = 40.33%;
430. final overall progress remains 290/943 = 30.75%;
431. final lastCompletedTaskId remains M19-C001-V06;
432. final Next Task/Action points to independent ChatGPT V02 audit;
433. implementation + tests + docs + CLAUDE_LOG_V02 + tracker handoff are pushed to origin/main;
434. remote main is verified after push;
435. Claude does not mark COMPLETE or READY_FOR_NEXT_TASK;
436. Claude does not self-audit;
437. successful return is exactly `AWAITING_AUDIT`;
438. tracker push failure uses `GITHUB_TRACKING_NOT_SYNCED`;
439. frozen-scope blocker uses `BLOCKED`;
440. ChatGPT records whether independent Godot runtime was available during audit.

## Audit disposition

V02 is still a critical/stateful production correction. Even if all 440 criteria appear green, ChatGPT must independently inspect the exact source/diff/test sensitivity and rerun the complete attack surface conceptually before closing any SB-M20 row.

Possible V02 outcomes:
- `CHANGES_REQUIRED`;
- `SOURCE_CORRECTION_ACCEPTED / AUDITOR_VALIDATION_REQUIRED`;
- `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE` only if the required independent evidence standard is satisfied.

Task closure candidates after strict final audit:
`SB-M20-001..SB-M20-014`.
