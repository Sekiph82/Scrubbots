# M20-C001 — Strict-v2 Lifecycle / Reset Audit Criteria V04

Canonical live tracker: repository-root `TASKS.md` only.

## Tracker / governance
1. synced root TASKS is sole live tracker;
2. V03 audit exists before V04 implementation;
3. V04 full-surface freeze exists;
4. V04 prompt exists;
5. starting state is M20-C001 V03 AWAITING_AUDIT / CHATGPT;
6. progress starts 290/719 main+ui;
7. overall starts 290/943;
8. lastCompletedTaskId starts M19-C001-V06;
9. SB-M20-001..014 remain open;
10. V04 tracker-only IN_PROGRESS transition is committed;
11. transition is pushed before any V04 test edit;
12. transition is pushed before any V04 production edit;
13. remote main start transition is verified;
14. Required Actor becomes CLAUDE only after authorization;
15. no .hiveai live tracker recreated;
16. no CHATGPT_* artifact modified by Claude;
17. no audit verdict self-assigned;
18. no SB-M20 row closed by Claude;
19. owner/local work preserved;
20. implementation scope matches V04 authorization.

## V03 accepted baseline preservation
21. exact BoardState category preserved;
22. exact SlotSystem category preserved;
23. exact ColorCandidateIndex category preserved;
24. exact ReservationState category preserved;
25. exact ScrubbotDispatcher category preserved;
26. exact optional BoardRenderer category preserved;
27. candidate subclass remains production-rejected;
28. reservation subclass remains production-rejected;
29. exact owner-map snapshot remains;
30. exact owner-map successful-resolve proof remains;
31. exact owner-map rollback proof remains;
32. current-arrival owner+agent dedup remains;
33. duplicate queued identity dedup remains;
34. distinct arrival FIFO remains;
35. clear order remains Board->candidate->reservation->dispatcher->renderer;
36. renderer remains post-commit only;
37. no M21/win/lose/scoring/session/slot-policy code added.

## V03-baseline sensitivity S1: Node lifecycle
38. S1 is executed after V04 start push but before production correction;
39. queued exact dispatcher is used, not a wrong-category substitute;
40. queued exact renderer is used, not a wrong-category substitute;
41. at least one post-bind dispatcher queue/free lifecycle case is attempted;
42. actual V03 outcome is recorded;
43. SCRIPT ERROR presence/absence is recorded explicitly;
44. stale true/false coherence outcome is recorded explicitly;
45. no post-fix code is used to claim pre-fix sensitivity;
46. dedicated smoke is used if root runner cannot safely contain the expected failure.

## V03-baseline sensitivity S2: reset inside M19 dispatch
47. S2 runs before M20 production correction;
48. M20 preflight has already passed before reset is injected;
49. reset is injected from a real M19 callback-bearing dispatch phase;
50. callback calls only loop.reset for the reset signal;
51. M19 dispatcher reset generation is not directly changed by the injected callback;
52. arrangement permits V03 M19 dispatch to otherwise succeed;
53. V03 activate_slot returned result is recorded;
54. post-return active_count is recorded;
55. post-return reservation state is recorded;
56. owner counter observation is recorded;
57. intended stale-success sensitivity is directly distinguishable from an earlier failure.

## V03-baseline sensitivity S3: reservation drift reset
58. S3 runs before dispatcher reset correction;
59. real exact ReservationState is used;
60. real active dispatch on board A exists;
61. same ReservationState object is rebound to board B;
62. board B obtains a reservation with same numeric owner token;
63. loop.reset is called;
64. exact B target owner before reset is recorded;
65. exact B target owner after reset is recorded;
66. current V03 collateral deletion/survival is directly observed;
67. same-board replacement case is attempted or separately covered post-fix.

## Exact-script helper Node safety
68. null exact-script input returns false safely;
69. scalar int returns false safely;
70. String returns false safely;
71. Vector2 returns false safely;
72. arbitrary RefCounted wrong script returns false safely;
73. arbitrary live Node wrong script returns false safely;
74. already-freed Node does not receive get_script call;
75. already-freed Node path emits no SCRIPT ERROR;
76. queued-for-deletion dispatcher is rejected for new bind;
77. queued-for-deletion renderer is rejected for new bind;
78. live exact dispatcher is accepted where otherwise valid;
79. live exact renderer is accepted where otherwise valid;
80. RefCounted collaborators are not subjected to Node queue-free API calls.

## Bind lifecycle
81. freed dispatcher bind returns false;
82. queued dispatcher bind returns false;
83. failed dispatcher lifecycle bind leaves loop unbound;
84. failed dispatcher lifecycle bind creates zero arrival connections;
85. freed renderer bind returns false;
86. queued renderer bind returns false;
87. failed renderer lifecycle bind leaves loop unbound;
88. failed renderer lifecycle bind creates zero arrival connections;
89. healthy exact bundle still binds;
90. ordinary second bind still returns false/preserves;
91. active dispatcher bind rejection remains;
92. five-slot configured requirement remains;
93. same-bundle candidate/reservation identity remains required.

## Live coherence lifecycle
94. healthy exact bundle is_coherent true;
95. candidate real rebind makes coherence false;
96. reservation real rebind makes coherence false;
97. renderer queued after bind makes coherence false;
98. renderer freed after bind makes coherence false without SCRIPT ERROR;
99. dispatcher queued after bind makes coherence false;
100. dispatcher freed after bind makes coherence false without SCRIPT ERROR;
101. no dispatcher method is called after instance-invalid proof;
102. no renderer method is called after instance-invalid proof;
103. queued Node is not treated as healthy merely because is_instance_valid is true.

## Activation preflight regression
104. unbound activation fails;
105. negative slot fails;
106. slot >=5 fails;
107. non-int slot fails;
108. unavailable slot fails;
109. invalid palette fails;
110. Vector2 NaN fails;
111. Vector2 INF fails;
112. speed 0 fails;
113. negative speed fails;
114. speed NaN fails;
115. speed +INF fails;
116. speed -INF fails;
117. nested activation remains REENTRANT;
118. arrival-drain activation remains REENTRANT;
119. pending reset before dispatch yields RESETTING;
120. pre-dispatch incoherence yields stable failure.

## Post-dispatch M20 generation barrier
121. dispatcher result is captured, not immediately returned;
122. M20 reset/generation is checked immediately after dispatch returns;
123. generation check happens before trusting raw success;
124. injected loop.reset inside M19 dispatch yields RESETTING;
125. raw M19 success is not exposed in that case;
126. activate_slot return has success=false;
127. failure_reason is RESETTING;
128. dispatcher active_count is zero when activate_slot returns;
129. current-attempt reservation is absent when activate_slot returns;
130. no agent remains active/orphaned after cleanup;
131. consumed owner token is never rewound;
132. next successful owner token is strictly later if one was consumed;
133. later healthy activation succeeds.

## Post-dispatch M20 coherence barrier
134. full M20 coherence is rechecked after dispatch when no reset moved;
135. check includes dispatcher liveness;
136. check includes renderer liveness when renderer bound;
137. M20-only renderer queue-delete is injected inside M19 dispatch callback;
138. M19 otherwise reaches raw success in sensitivity arrangement;
139. M20 does not expose that raw success;
140. returned failure_reason is COHERENCE_FAILED;
141. M20 requests deterministic cleanup/reset;
142. active dispatcher assignment is gone when activate_slot returns;
143. corresponding current reservation is gone when activate_slot returns;
144. no false BoardState clear occurred;
145. no cleared_count increment occurred;
146. a fresh healthy loop/bundle can later operate.

## Dispatcher reset pair-narrow source law
147. reset no longer uses release_for_owner as active-entry authority;
148. immutable entry target is read for cleanup;
149. ReservationState board identity is proven before reservation mutation;
150. board-coherence return requires actual bool true;
151. get_target_for_owner(O) must equal entry T;
152. get_owner(T) must equal O;
153. only then exact release(T,O) is attempted;
154. failed board/pair proof skips reservation mutation;
155. dispatcher agent disconnect/cancel cleanup still proceeds when proof fails;
156. dispatcher active bookkeeping still clears when proof fails;
157. reset generation semantics remain;
158. nested reset guard remains;
159. owner counter is not rewound.

## Dispatcher reset direct case A: healthy pair
160. active exact T<->O exists;
161. ReservationState is bound to original board;
162. reset releases T<->O;
163. unrelated reservation survives;
164. agent is cancelled/detached/queued-free;
165. active_count becomes zero.

## Dispatcher reset direct case B: foreign board different target
166. active dispatcher entry still records board A/T/O;
167. same ReservationState object is rebound to board B;
168. B target V is reserved by numeric O;
169. dispatcher/M20 reset does not release V;
170. B get_owner(V)==O after reset;
171. dispatcher own active bookkeeping clears;
172. agent cleanup occurs.

## Dispatcher reset direct case C: foreign board same numeric target
173. foreign board B uses numeric target index equal to original T;
174. foreign target is owned by numeric O;
175. board identity proof prevents release;
176. foreign T<->O survives reset;
177. dispatcher active bookkeeping clears.

## Dispatcher reset direct case D: same-board replacement
178. ReservationState belongs to original board A;
179. original T<->O pair is absent;
180. O owns V != T;
181. pair proof fails;
182. V<->O survives reset;
183. dispatcher active bookkeeping clears;
184. no unrelated reservation is removed.

## Dispatcher reset direct case E: missing reservation
185. active dispatcher entry exists;
186. corresponding reservation is absent;
187. reset does not fabricate reservation;
188. reset does not delete unrelated reservation;
189. dispatcher active bookkeeping clears;
190. agent cleanup occurs.

## M20 reset with dispatcher lifecycle
191. idle coherent reset remains safe;
192. queued-but-instance-valid dispatcher receives no new work;
193. queued dispatcher reset path does not SCRIPT ERROR;
194. already-freed dispatcher reset path does not call dispatcher methods;
195. already-freed dispatcher reset emits no SCRIPT ERROR;
196. local arrival queue becomes deterministic/cleared as specified;
197. local current-arrival identity becomes deterministic/cleared as specified;
198. reset flags do not remain permanently stuck;
199. BoardState is not mutated to hide destroyed dispatcher;
200. candidate state is not rebuilt merely to hide destroyed dispatcher;
201. foreign ReservationState truth is not cleared merely to hide destroyed dispatcher.

## Arrival authentication / queue regression
202. wrong owner cannot clear;
203. wrong target cannot clear;
204. wrong color cannot clear;
205. wrong source agent cannot clear;
206. unknown owner cannot clear;
207. missing reservation cannot clear;
208. wrong reservation owner cannot clear;
209. already-cleared target cannot clear twice;
210. duplicate current owner+agent is dropped;
211. duplicate queued owner+agent is dropped;
212. distinct nested owner+agent remains FIFO;
213. current identity clears after success;
214. current identity clears after preflight rejection;
215. current identity clears after rollback outcome;
216. reset clears stale queued arrival;
217. stale replay after reset cannot clear.

## Clear transaction regression
218. BoardState mutation is first authoritative mutation;
219. target color stays immutable;
220. target candidate removed after clear;
221. same-color unrelated candidate survives;
222. other-color bucket survives;
223. exact reservation owner map becomes pre minus target;
224. dispatcher finalize follows exact reservation proof;
225. renderer update follows dispatcher finalize;
226. renderer absent remains valid;
227. renderer target alpha becomes zero on success;
228. unrelated renderer pixel unchanged;
229. cleared_count increments exactly once on commit;
230. failed/rollback path does not increment cleared_count;
231. identity-swap harness cannot report ordinary rollback success;
232. candidate unrelated-loss harness restores unrelated truth;
233. renderer rollback remains opaque/source-colored.

## Direct integration regression
234. true 1x1 width/height/count all equal one;
235. sole target dispatches/clears;
236. second 1x1 activation has no work;
237. AL-028 B starts unreachable;
238. A is first real dispatch/clear;
239. A becomes OPEN/CLEARED;
240. second real activate_slot selects B;
241. B has exact reservation;
242. B arrival clears B;
243. five activations yield five unique owner IDs;
244. five targets are distinct;
245. five exact reservation pairs exist;
246. first arrival preserves other four pairs;
247. all five eventually resolve;
248. failed-preflight reset recovery remains;
249. one-color exhaustion remains;
250. multi-color remains;
251. Easy coverage remains;
252. Medium coverage remains;
253. Hard coverage remains;
254. Very Hard coverage remains;
255. 59x59 remains green;
256. rectangular remains green;
257. rapid 25+ cycles remain green.

## Deferred destruction regression
258. successful finalization still queue_free's agent;
259. dedicated smoke runs separately;
260. smoke advances a real SceneTree frame;
261. agent instance becomes invalid/freed;
262. no orphan child remains.

## Upstream regression lock
263. BoardState strict suite green;
264. BoardRenderer suite green;
265. M11 session green;
266. M12 slots green;
267. M13 candidate green;
268. M14 reservation green;
269. M15-C002 final selector green;
270. M16 routing green;
271. M17 production routing green;
272. M18 agent green;
273. all M19 V01-V06 tests green;
274. M19 completion identity unchanged;
275. M19 arrival still does not clear BoardState itself;
276. M19 successful arrival still does not resolve reservation itself.

## Performance / architecture
277. normal clear still one BoardState target mutation;
278. normal clear still one single-cell candidate sync;
279. no normal-path BoardState full scan introduced;
280. reservation owner-map work scales with live reservations, not board cells;
281. renderer update remains one target cell;
282. no one-Node-per-cell architecture;
283. no second access cache;
284. owner IDs remain monotonic;
285. no automatic next-bot dispatch introduced.

## Source/doc consistency
286. bind comment no longer claims candidate/reservation subclasses accepted in production;
287. architecture prose states exact canonical dependency categories;
288. test harness is explicitly test-only;
289. docs do not present harness subclasses as production collaborators;
290. reset prose describes pair-narrow cleanup truthfully.

## Scope
291. M20 production change limited to complete_clearing_loop.gd;
292. M19 production change limited to reset hardening in scrubbot_dispatcher.gd;
293. no BoardState production change;
294. no SlotSystem production change;
295. no ColorCandidateIndex production change;
296. no ReservationState production change;
297. no TargetSelector production change;
298. no routing production change;
299. no ScrubbotAgent production change;
300. no BoardRenderer production change;
301. no M21 production change;
302. no scoring/economy/session-complete behavior.

## Final validation / handoff
303. Godot version recorded as 4.7.1 stable;
304. S1 actual pre-fix observation recorded;
305. S2 actual pre-fix observation recorded;
306. S3 actual pre-fix observation recorded;
307. targeted post-fix lifecycle command/results recorded;
308. targeted post-dispatch command/results recorded;
309. targeted reset-pair command/results recorded;
310. full root suite command and exact total recorded;
311. zero final SCRIPT ERROR lines recorded;
312. zero final Parse Error lines recorded;
313. queue_free smoke command/result recorded separately;
314. any lifecycle smoke command/result recorded separately;
315. git diff --check recorded;
316. exact changed-file list recorded;
317. CLAUDE_LOG_V04 exists;
318. log maps evidence to F001.K/F002.K/F006.K;
319. log records failed attempts/fixes;
320. no claim of independent ChatGPT runtime execution is made;
321. final root TASKS task is M20-C001-V04;
322. final status AWAITING_AUDIT;
323. final Required Actor CHATGPT;
324. progress remains 290/719 and 290/943;
325. lastCompletedTaskId remains M19-C001-V06;
326. SB-M20 rows remain open;
327. implementation/test/log/tracker commits pushed to origin/main;
328. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
329. tracking failure uses GITHUB_TRACKING_NOT_SYNCED;
330. broader production need uses BLOCKED;
331. V04 handoff explicitly stops before M21;
332. V04 does not claim final strict-v2 closure;
333. clean V04 leaves final closure pending auditor-authored V05 validation-only.

If these criteria pass, V04 production correction may be source-accepted, but M20 must still remain open until the subsequent V05 validation-only audit passes.