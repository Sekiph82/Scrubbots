# M20-C001 — Complete Clearing Vertical Slice Audit Criteria V01

Audit stage: **initial critical/stateful implementation**.

A green full suite is necessary but not sufficient. ChatGPT audits source, exact diff, direct observability, sensitivity and cross-module invariants.

## Tracker / governance
1. root `TASKS.md` is treated as the sole live tracker;
2. no `.hiveai/*` live tracker is recreated;
3. start state is the ChatGPT-issued M20-C001 V01 handoff;
4. IN_PROGRESS tracker transition is pushed before M20 production/test edits;
5. start progress remains 290/719 main+ui and 290/943 overall;
6. start lastCompletedTaskId remains M19-C001-V06;
7. Claude does not close any SB-M20 row;
8. final implementation handoff is AWAITING_AUDIT / CHATGPT;
9. final progress remains unchanged before independent audit;
10. matching CLAUDE_LOG_V01 exists;
11. no CHATGPT_* artifact is modified by Claude;
12. no audit verdict is self-assigned.

## M20 architecture
13. `scripts/gameplay/clearing/complete_clearing_loop.gd` exists;
14. clearing loop is a narrow orchestrator, not a God-manager;
15. BoardState remains physical cell truth owner;
16. ColorCandidateIndex remains derived candidate owner;
17. ReservationState remains assignment-ownership owner;
18. TargetSelector still owns target choice;
19. RoutingSystem still owns route generation;
20. ScrubbotAgent still owns movement only;
21. dispatcher still owns assignment/agent orchestration identity;
22. M20 loop owns the cross-module arrival transaction;
23. ProductionAccessQuery is not duplicated/cached by M20;
24. M20 does not introduce RESERVED cell state;
25. explicit preload convention preserved for core scripts.

## Clearing-loop dependency category
26. real BoardState accepted;
27. null/scalar board rejected safely;
28. real SlotSystem accepted;
29. null/scalar/wrong-category slot system rejected safely;
30. real ColorCandidateIndex accepted;
31. wrong-category candidate dependency rejected;
32. real ReservationState accepted;
33. wrong-category reservation dependency rejected;
34. real ScrubbotDispatcher accepted;
35. wrong-category dispatcher dependency rejected;
36. optional null renderer accepted;
37. live real BoardRenderer accepted when coherent;
38. wrong-category renderer rejected;
39. freed renderer rejected where reproducible;
40. dependency rejection produces no escaped callback/runtime fault.

## Exact bind coherence
41. candidate index exact-bound to same board;
42. reservation state exact-bound to same board;
43. dispatcher exact-bound to same board;
44. dispatcher exact-bound to same ReservationState;
45. same-size different-board candidate bundle rejected;
46. same-size different-board reservation bundle rejected;
47. same-size different-board dispatcher bundle rejected;
48. renderer exact-bound to same board when supplied;
49. wrong-board renderer rejected;
50. SlotSystem must be configured;
51. SlotSystem exposes exactly five slots;
52. dispatcher must have zero active assignments at first loop bind;
53. bind with pre-existing dispatcher assignment rejected;
54. successful bind commits bundle atomically;
55. failed fresh bind leaves loop unbound;
56. ordinary second bind returns false;
57. second bind preserves original bundle;
58. second bind does not cancel/reset existing state;
59. no destructive rebind API silently replaces the bundle;
60. no public query leaks mutable internal dependency/transaction maps.

## Live coherence
61. activation re-checks candidate board identity;
62. activation re-checks reservation board identity;
63. activation re-checks dispatcher bundle identity;
64. renderer coherence rechecked when present;
65. candidate rebind/drift before activation fails closed;
66. reservation rebind/drift before activation fails closed;
67. dispatcher mismatch before activation fails closed;
68. renderer wrong-board drift before activation fails closed;
69. live incoherence produces no new reservation;
70. live incoherence produces no new agent;
71. live incoherence mutates no BoardState cell.

## M19 arrival bridge
72. dispatcher exposes an authenticated M20 arrival signal/seam;
73. outward arrival emitted only after M19 identity validation;
74. wrong owner completion emits no arrival;
75. wrong target completion emits no arrival;
76. wrong color completion emits no arrival;
77. wrong source agent emits no arrival;
78. unknown owner emits no arrival;
79. correct completion emits exactly once;
80. repeated correct completion does not emit twice;
81. dispatcher exposes exact read-only bound/coherence query required by M20;
82. dispatcher exposes exact arrived-assignment query required by M20;
83. those queries do not leak `_active` dictionary by reference;
84. dispatcher finalization acts only on exact owner/target/color/agent;
85. finalization requires assignment already arrived;
86. finalization wrong owner returns false/no mutation;
87. finalization wrong target returns false/no mutation;
88. finalization wrong color returns false/no mutation;
89. finalization wrong source agent returns false/no mutation;
90. finalization repeated second call is false/idempotent;
91. finalization does not mutate BoardState;
92. finalization does not release ReservationState itself;
93. finalization erases exact dispatcher active entry;
94. finalization does not erase unrelated active entries;
95. finalization safely queues/defers agent destruction;
96. no synchronous locked-object free error on completion stack.

## Slot activation boundary
97. activate API is headless-testable;
98. method call itself is the activation event;
99. invalid negative slot id rejected;
100. slot id 5+ rejected;
101. non-int Variant slot id rejected if public seam is Variant;
102. unconfigured slots reject activation;
103. unavailable slot rejects activation;
104. available configured slot may dispatch;
105. slot palette id drives dispatcher color;
106. start x NaN rejected;
107. start y NaN rejected;
108. start +/-INF rejected;
109. speed NaN rejected;
110. speed +INF rejected;
111. speed -INF rejected;
112. speed zero rejected;
113. speed negative rejected;
114. invalid activation makes no dispatcher side effect;
115. invalid activation makes no reservation;
116. invalid activation mutates no slot state;
117. successful activation mutates no slot active/availability/palette state;
118. one activation creates at most one agent;
119. M20 does not perform its own target-selection algorithm;
120. M20 does not perform its own route algorithm.

## No-work behavior
121. no raw candidate -> zero agent;
122. no raw candidate -> zero reservation;
123. no raw candidate -> no board mutation;
124. raw matching but enclosed/unreachable candidate -> zero agent;
125. enclosed candidate -> zero reservation;
126. enclosed candidate remains ACTIVE;
127. route failure preserves target ACTIVE;
128. route failure releases reservation via M19;
129. M20 does not silently retarget after route failure.

## Arrival preflight
130. exact arrived assignment accepted;
131. target index validity checked before mutation;
132. target state must be exactly ACTIVE;
133. target color must match assignment color;
134. owner->target reservation must match;
135. target->owner reservation must match;
136. candidate index must still be exact-bound to board;
137. dispatcher must still expose exact pending arrived assignment;
138. renderer must still be coherent when present;
139. target already CLEARED before arrival -> no second clear;
140. reservation missing before arrival -> no clear;
141. reservation wrong-owner -> no clear;
142. candidate dependency drift -> no clear;
143. dispatcher mismatch -> no clear;
144. renderer incoherence -> no clear when renderer is required/bound;
145. failed preflight preserves reservation if it still exists;
146. failed preflight preserves dispatcher arrived assignment;
147. failed preflight mutates no unrelated state.

## Authoritative ACTIVE->CLEARED transaction
148. step order is BoardState clear first;
149. candidate single-cell sync follows BoardState mutation;
150. reservation resolve follows candidate sync;
151. renderer update follows successful gameplay-state mutation;
152. dispatcher finalization occurs after reservation success;
153. successful BoardState state is exactly CLEARED;
154. successful target retains original immutable color id;
155. candidate target is absent after clear;
156. candidate bucket for unrelated same-color cells preserved;
157. other color buckets preserved;
158. reservation target owner becomes -1;
159. reservation owner target becomes -1;
160. exact reservation count decrements by one;
161. unrelated reservations preserved;
162. dispatcher exact owner removed;
163. unrelated dispatcher assignments preserved;
164. optional renderer target alpha becomes 0;
165. renderer unrelated pixels unchanged;
166. ProductionAccessQuery reads the cleared cell as OPEN without explicit sync;
167. no explicit access cache/update is created.

## Transaction failure / rollback
168. BoardState set failure triggers no candidate sync;
169. BoardState set failure triggers no reservation resolve;
170. BoardState set failure triggers no dispatcher finalization;
171. candidate sync failure restores target ACTIVE;
172. candidate sync failure restores/rebuilds candidate membership;
173. candidate sync failure keeps reservation held;
174. candidate sync failure keeps dispatcher arrived assignment held;
175. candidate sync failure does not finalize/free agent;
176. reservation resolve failure restores target ACTIVE;
177. reservation resolve failure restores candidate membership;
178. reservation resolve failure preserves dispatcher arrived assignment;
179. reservation resolve failure does not finalize agent;
180. rollback never removes unrelated candidate/reservation/dispatcher state;
181. no path leaves CLEARED + still candidate;
182. no path leaves CLEARED + still reserved after reported success;
183. no path leaves ACTIVE + candidate removed after rollback;
184. no reported success leaves dispatcher active owner present.

## Exactly once / spoof / stale
185. wrong owner cannot clear;
186. wrong target cannot clear;
187. wrong color cannot clear;
188. wrong source agent cannot clear;
189. unknown owner cannot clear;
190. duplicate completion cannot clear twice;
191. duplicate finalization cannot decrement counts twice;
192. stale completion after reset cannot clear;
193. completion for already-cleared target cannot affect another cell;
194. one arrival changes exactly one BoardState cell;
195. one arrival removes exactly one candidate;
196. one arrival resolves exactly one reservation;
197. one arrival finalizes exactly one dispatcher assignment.

## Agent disappearance / no return
198. successful arrived agent is scheduled/deferred for destruction;
199. after SceneTree queued-free processing the agent instance is gone;
200. successful agent is not returned to slot origin;
201. no replacement/return agent is spawned automatically;
202. no pixel color/resource transfer is introduced;
203. no orphan Node remains after finalization.

## Reset / lifecycle
204. loop reset cancels in-flight dispatcher agents;
205. loop reset releases their reservations;
206. reset does not mutate BoardState cell states;
207. reset does not remove valid candidate membership for ACTIVE cells;
208. reset does not resurrect already CLEARED cells;
209. reset does not rewind dispatcher owner ids;
210. stale completion after reset ignored;
211. reset with multiple in-flight assignments leaves zero active dispatcher entries;
212. reset with multiple in-flight assignments leaves zero corresponding reservations;
213. reset is re-entry-safe;
214. reset after a successful clear preserves that clear;
215. controlled reset during arrival cannot leave half-cleared tuple.

## Newly-opened reachability
216. real production setup contains initially unreachable target B;
217. ACTIVE blocker/gate A is the reason B is unreachable;
218. B produces no dispatch before A clears;
219. A can be successfully dispatched/arrived/cleared;
220. A becomes CLEARED;
221. A leaves candidate truth;
222. ProductionAccessQuery sees A as OPEN after clear;
223. no explicit access-cache refresh occurs;
224. later activation can reach B;
225. routing still uses ProductionRoutingSystem;
226. selector still selects B rather than routing retargeting.

## One-cell / one-color / multi-color
227. one-cell synthetic board dispatches one agent;
228. one-cell arrival clears the only cell;
229. second activation finds no work;
230. one-color multi-cell board can be repeatedly cleared;
231. each one-color clear removes exactly one candidate;
232. exhausted one-color bucket returns no work;
233. multi-color activation clears only requested color target;
234. other-color candidates remain unchanged;
235. repeated mixed-color clearing preserves deterministic ownership.

## Five-slot behavior
236. SlotSystem remains exactly five slots;
237. five configured slot palette ids are usable;
238. five slot activations can create five distinct in-flight assignments when board topology permits;
239. five assignments have unique owner ids;
240. five assignments have distinct reserved targets;
241. each arrival resolves its own tuple independently;
242. one arrival does not resolve another slot's reservation;
243. after all five arrivals no orphan active entries remain;
244. slot model fields remain unchanged by M20 transaction.

## Difficulty / dimension matrix
245. Easy production dimensions exercised;
246. Medium production dimensions exercised;
247. Hard production dimensions exercised;
248. Very Hard production dimensions exercised;
249. 59x59 maximum exercised;
250. rectangular production board exercised;
251. no square-only assumption introduced;
252. BoardState indexing remains canonical;
253. M20 does not impose a smaller fixed board maximum.

## Stress / performance
254. rapid 25+ sequential activation/arrival cycles pass where practical;
255. owner ids stay monotonic across sequential clears;
256. candidate counts converge correctly through sequential clears;
257. normal M20 clear code does not full-scan all board cells;
258. one-cell `sync_cell` seam is used;
259. one-cell renderer update seam is used when renderer present;
260. no per-cell Node architecture introduced;
261. no new access cache introduced;
262. 59x59 stress remains structurally bounded.

## Renderer integration
263. headless M20 works with renderer null;
264. real configured BoardRenderer can bind to M20;
265. renderer exact-board coherence is provable via read-only seam;
266. renderer updates target after successful clear;
267. CLEARED pixel readback alpha is 0 within RGBA8 tolerance;
268. ACTIVE unrelated pixel remains opaque/source color;
269. candidate/reservation failure rollback does not falsely render target cleared;
270. renderer never mutates BoardState.

## Existing subsystem regressions
271. BoardState strict canonical-state tests remain green;
272. M10 renderer ACTIVE/CLEARED tests remain green;
273. M11 session tests remain green;
274. M12 slot tests remain green;
275. M13 candidate-index strict tests remain green;
276. M14 reservation strict tests remain green;
277. M15-C002 final selector tests remain green;
278. M16 routing contract tests remain green;
279. M17 production routing strict tests remain green;
280. M18 agent lifecycle tests remain green;
281. M19 V01-V06 tests remain green;
282. M19 completion identity behavior remains unchanged except the narrow outward arrival bridge;
283. M19 no-route/no-retarget behavior remains unchanged;
284. M19 reset behavior remains unchanged.

## No-scope-creep / design gates
285. no GameplaySession.complete() automatic call;
286. no win-condition implementation;
287. no lose-condition implementation;
288. no scoring implementation;
289. no win-streak reward implementation;
290. no currency/economy implementation;
291. no auto-follow-up bot dispatch;
292. no new slot cooldown rule;
293. no new slot queue rule;
294. no slot consumption/depletion rule;
295. no collision-radius rule invented;
296. no M21 real-art dependency;
297. no production UI implementation;
298. no LevelData mutation;
299. no palette-law change;
300. no ACTIVE/CLEARED semantic change.

## Documentation / architecture evidence
301. architecture docs identify M20 clearing loop as cross-module arrival transaction owner;
302. docs preserve M19 dispatcher separation;
303. docs preserve live BoardState access semantics;
304. docs explicitly say M20 does not define win/session-completion policy;
305. historical audit evidence is not rewritten.

## Final validation
306. `godot --version` records Godot 4.7.1 stable;
307. full root headless suite runs from current implementation commit;
308. full root suite has zero failures;
309. final run has zero SCRIPT ERROR / Parse Error;
310. `git diff --check` clean;
311. exact changed-file list recorded;
312. M20 evidence is mapped criterion-by-criterion or section-by-section in CLAUDE_LOG_V01;
313. failures/fixes during implementation are preserved in log;
314. final remote main contains implementation + tests + CLAUDE_LOG_V01 + AWAITING_AUDIT tracker state;
315. Claude returns AWAITING_AUDIT and stops.

## Audit disposition

V01 introduces critical/stateful production orchestration. Even if all 315 criteria appear green, ChatGPT must independently inspect source, diff, test sensitivity and full attack surface before any SB-M20 row closes.

Possible V01 outcomes:
- CHANGES_REQUIRED;
- SOURCE_CORRECTION_ACCEPTED / auditor-authored validation-only next stage;
- in the exceptional case of unusually complete direct evidence plus independent runtime, final closure.

Task closure candidates after strict final audit:
SB-M20-001..014.
