# M20-C001 — Final Whole-Sprint Validation-Only Audit Criteria V08

Canonical live tracker: repository-root `TASKS.md` only.

Production is immutable in V08. Aggregate green counts do not substitute for missing direct evidence.

## Tracker / governance
1. root TASKS is the sole live tracker;
2. V07 audit exists before V08 start;
3. V08 freeze exists;
4. V08 prompt exists;
5. starting task is M20-C001-V07;
6. starting status is AWAITING_AUDIT;
7. starting actor is CHATGPT;
8. progress starts 290/719 main+ui;
9. overall starts 290/943;
10. lastCompletedTaskId is M19-C001-V06;
11. SB-M20-001..014 all start open;
12. V08 tracker-only IN_PROGRESS transition is committed;
13. start transition is pushed before any V08 test/smoke edit;
14. start transition is pushed before any V08 doc edit;
15. start transition is pushed before any temporary sensitivity mutation;
16. remote start transition is verified;
17. log states no V08 validation/doc/mutation existed before successful start push;
18. owner/local work is preserved;
19. no .hiveai live tracker is recreated;
20. no CHATGPT_* artifact is modified by Claude;
21. Claude self-assigns no audit verdict;
22. no SB-M20 row is closed by Claude.

## Production immutability
23. starting loop blob is 06391839523cbc27e88a4b3ef12b730012cd45fa;
24. starting dispatcher blob is eee10149e4f116af6706beec832042352bf3a6dd;
25. no committed V08 change under scripts/gameplay/clearing;
26. no committed V08 change under scripts/gameplay/dispatch;
27. no committed V08 change under any scripts/** path;
28. temporary sensitivity edits occur only after start push;
29. temporary edits are never committed;
30. each mutation is restored before the next;
31. final loop blob equals accepted V07 blob;
32. final dispatcher blob equals accepted V07 blob;
33. final committed scripts/** diff vs e189ee8 is empty.

## Single M20 consumer claim
34. first healthy loop binds same dispatcher successfully;
35. benign diagnostic listener does not block claim;
36. second different live loop bind fails;
37. second loop remains unbound;
38. rejected second loop adds no M20 transaction connection;
39. first loop remains coherent;
40. first loop can activate after second-loop rejection;
41. one authenticated arrival increments first-loop cleared_count exactly once;
42. second loop has zero clear attribution;
43. second loop cannot activate canonical state;
44. second loop reset is no-op on first bundle;
45. owning-loop reset does not release claim;
46. second loop remains rejected after owning-loop reset;
47. owner loop remains usable after reset when bundle is healthy;
48. releasing/GCing owner loop removes its signal callback;
49. weak claim no longer resolves to the released loop;
50. fresh loop can claim after owner release when dispatcher has no active work;
51. fresh loop adds exactly one M20 transaction connection;
52. no strong reference cycle keeps old loop alive;
53. diagnostic listener remains independent of M20 claim;
54. claim/reset lifecycle mutates no BoardState by itself.

## agent_parent lifecycle
55. omitted parent binds with dispatcher self;
56. explicit null binds with dispatcher self;
57. scalar parent rejects cleanly;
58. arbitrary RefCounted parent rejects;
59. healthy explicit Node parent binds;
60. healthy explicit parent receives spawned agent;
61. queued explicit parent before bind rejects;
62. truly-freed explicit parent before bind rejects;
63. truly-freed explicit parent emits no SCRIPT ERROR;
64. truly-freed explicit parent does not fall back to self;
65. configured-vs-default truth is captured before callbacks;
66. callback-queued/freed explicit parent prevents bind commit;
67. callback-death failure leaves dispatcher unbound;
68. callback-death failure creates no agent/reservation;
69. healthy explicit parent can die after bind;
70. destroyed parent before dispatch makes dispatch fail closed;
71. destroyed-parent dispatch leaves zero current-attempt reservation;
72. destroyed-parent dispatch leaves zero active/orphan agent;
73. owner id remains monotonic/no reuse;
74. explicit factory semantics remain unchanged;
75. invalidated explicit factory still never falls back to default.

## Renderer lifecycle
76. omitted renderer headless bind succeeds;
77. explicit null headless bind succeeds;
78. int renderer rejects;
79. float renderer rejects;
80. String renderer rejects;
81. Vector2 renderer rejects;
82. representative Array/Dictionary renderer rejects;
83. arbitrary RefCounted renderer rejects;
84. wrong Node renderer rejects;
85. queued exact renderer before bind rejects;
86. truly-freed exact renderer before bind rejects;
87. healthy exact renderer binds;
88. failed invalid-renderer bind leaves no claim/arrival connection;
89. same loop clean retry after failed renderer bind succeeds;
90. no stale renderer-presence metadata survives failed bind;
91. healthy renderer second bind attempt fails/preserves original bundle;
92. original renderer foreign-board after refused second bind makes coherence false;
93. original renderer queued/dead after refused second bind makes coherence false;
94. foreign renderer drift after bind blocks activation before dispatch;
95. foreign renderer drift creates no reservation/agent/BoardState mutation;
96. real assignment can exist before renderer loss;
97. renderer queued after dispatch before arrival causes preflight rejection;
98. queued-before-arrival target remains ACTIVE;
99. queued-before-arrival raw target candidate remains present;
100. queued-before-arrival cleared_count stays zero;
101. queued-before-arrival exact reservation remains held;
102. queued-before-arrival dispatcher assignment remains held;
103. truly-freed renderer after dispatch before arrival causes same no-clear law;
104. dead-renderer path emits no SCRIPT ERROR;
105. explicit reset after renderer loss cleans only original assignment/pair;
106. healthy renderer clear repaints target alpha 0;
107. unrelated renderer pixel is unchanged;
108. headless clear still succeeds.

## Arrival preflight forged identity
109. fresh real arrived-pending assignment is constructed;
110. wrong owner is rejected by M20;
111. wrong target is rejected;
112. wrong color is rejected;
113. wrong source agent is rejected;
114. unknown owner is rejected;
115. each forged identity leaves target BoardState unchanged;
116. each forged identity leaves cleared_count unchanged;
117. each forged identity leaves real dispatcher assignment pending;
118. each forged identity leaves real exact reservation held;
119. unrelated cell/candidate/reservation state remains unchanged.

## Arrival preflight reservation/candidate drift
120. missing reservation is rejected;
121. missing reservation clears nothing;
122. same-board original pair can be replaced with T->different-owner O2 for test;
123. original arrival against T->O2 is rejected;
124. T->O2 replacement survives failed M20 preflight;
125. loop.reset after this case does not delete T->O2;
126. ReservationState rebind to foreign board makes loop incoherent;
127. foreign replacement reservation is created;
128. original arrival against foreign ReservationState is rejected;
129. foreign reservation survives failed preflight;
130. loop.reset preserves foreign replacement reservation;
131. ColorCandidateIndex rebind to foreign board makes loop incoherent;
132. original arrival against foreign candidate index is rejected;
133. candidate-drift reject clears nothing/finalizes nothing;
134. candidate-drift exact reservation remains until explicit reset;
135. ColorCandidateIndex rebind(null) neutralizes/unbinds it;
136. arrival against neutralized candidate index rejects cleanly;
137. neutralized-candidate reject clears nothing/finalizes nothing;
138. already-CLEARED target before arrival is rejected;
139. renderer foreign-board before arrival is rejected;
140. renderer queued/dead before arrival is rejected;
141. stale replay after reset clears nothing;
142. duplicate correct completion does not clear twice;
143. duplicate current/queued owner+agent arrival is deduped;
144. failed-preflight cleanup leaves no orphan agent after explicit reset.

## Activation boundary, per-case snapshots
145. valid finite activation control succeeds when work exists;
146. slot -1 rejects;
147. slot 5 rejects;
148. non-int slot rejects;
149. unavailable slot rejects;
150. origin NaN x rejects;
151. origin NaN y rejects;
152. origin +INF rejects;
153. origin -INF rejects;
154. speed NaN rejects;
155. speed +INF rejects;
156. speed -INF rejects;
157. speed zero rejects;
158. speed negative rejects;
159. absent color/no target returns NO_REACHABLE_TARGET;
160. enclosed matching target returns no reachable target;
161. nested activation returns REENTRANT;
162. activation during arrival drain returns REENTRANT;
163. reset during activation preflight yields RESETTING;
164. reset inside M19 dispatch yields RESETTING not raw success;
165. post-dispatch M20 coherence loss yields COHERENCE_FAILED;
166. each ordinary invalid-request/no-work case preserves BoardState snapshot;
167. each ordinary invalid-request/no-work case preserves dispatcher active count;
168. each ordinary invalid-request/no-work case preserves exact reservation map/count;
169. each ordinary invalid-request/no-work case preserves next owner id;
170. each ordinary invalid-request/no-work case preserves all slot palette fields;
171. each ordinary invalid-request/no-work case preserves all slot availability fields;
172. each ordinary invalid-request/no-work case preserves all slot activity fields;
173. downstream reset/coherence cases document any legitimate consumed owner token;
174. owner ids are never reused;
175. M20 contains no second target-selection/routing algorithm.

## Fresh SB-M20 task ledger
176. SB-M20-001 uses a fresh real-production full sequence;
177. SB-M20-001 target becomes CLEARED;
178. target absent from raw candidate bucket;
179. ProductionAccessQuery classifies cleared target OPEN;
180. reservation owner and owner-target are absent;
181. dispatcher owner is absent;
182. finalized agent is queued for destruction;
183. renderer target alpha is zero when configured;
184. SB-M20-002 no target creates no bot/reservation/clear;
185. enclosed target also creates no bot;
186. SB-M20-003 finalized agent is truly destroyed after frame(s);
187. no orphan child remains;
188. no return path occurs;
189. SB-M20-004 actual 1x1 clears once;
190. 1x1 is exhausted afterward;
191. SB-M20-005 one-color board repeatedly clears to exhaustion;
192. SB-M20-006 multi-color board clears using corresponding colors;
193. multi-color clear does not corrupt other-color candidate truth;
194. SB-M20-007 five activations succeed where targets permit;
195. five owner ids are unique;
196. five targets are distinct;
197. five exact owner<->target pairs exist;
198. resolving first preserves other four exact pairs;
199. all five eventually resolve/finalize;
200. SB-M20-008 Easy representative succeeds;
201. SB-M20-009 Medium representative succeeds;
202. SB-M20-010 Hard representative succeeds;
203. SB-M20-011 Very Hard representative succeeds;
204. SB-M20-012 59x59 maximum succeeds;
205. normal clear path adds no BoardState full scan;
206. SB-M20-013 valid rectangular production board succeeds;
207. SB-M20-014 fresh direct desync matrix runs;
208. SB-M20-014 rollback/reset/duplicate cases run;
209. reset with multiple in-flight assignments is coherent;
210. second-loop same-dispatcher ownership is rejected.

## AL-028 / rapid / slot-state regressions
211. B is initially unreachable behind ACTIVE A;
212. first real activation clears A;
213. second REAL activate_slot selects/routes B;
214. B exact reservation is created;
215. B arrival clears B;
216. no explicit access-cache refresh is used;
217. rapid scenario completes >=25 sequential clear cycles;
218. slot palette/availability/activity unchanged by ordinary M20 success;
219. slot fields unchanged by ordinary M20 failure.

## Rollback / reset / contention
220. candidate mutate-before-false is detected;
221. candidate failure restores exact prestate or reports ROLLBACK_FAILED;
222. reservation mutate-before-false is detected;
223. reservation failure restores exact prestate or reports ROLLBACK_FAILED;
224. candidate true-without-postcondition is detected;
225. reservation true-without-postcondition is detected;
226. unrelated same-color candidate loss cannot be silently accepted;
227. unrelated different-color candidate remains correct;
228. reservation identity swap cannot pass count-only proof;
229. exact owner-map rollback is required;
230. reset during candidate phase leaves no half-clear;
231. reset during reservation phase leaves no half-clear;
232. duplicate current arrival clears at most once;
233. distinct nested arrival remains FIFO/lossless;
234. healthy pair-narrow reset removes original pair;
235. unrelated reservation survives healthy pair reset;
236. foreign-board replacement survives reset;
237. same-board owner replacement survives reset;
238. missing pair does not fabricate/delete unrelated reservation;
239. post-dispatch generation barrier remains;
240. reset re-entry guard remains;
241. owner counter stays monotonic.

## Sensitivity S1-S6
242. S1 consumer-claim bypass is executed after start push;
243. S1 second-loop ownership test fails for intended reason;
244. S1 restored before next mutation;
245. S2 agent_parent equality/null regression is executed;
246. S2 truly-freed explicit-parent test fails for intended reason;
247. S2 restored;
248. S3 renderer equality/null regression is executed;
249. S3 truly-freed renderer test fails for intended reason;
250. S3 restored;
251. S4 post-dispatch generation/reset barrier is weakened;
252. S4 reset-inside-dispatch test fails for intended stale-success reason;
253. S4 restored;
254. S5 exact owner-map proof is weakened to count-only/bypass;
255. S5 reservation identity-swap test fails for intended reason;
256. S5 restored;
257. S6 pair-narrow reset is weakened to owner-wide cleanup;
258. S6 foreign/same-board replacement preservation test fails for intended reason;
259. S6 restored;
260. exact failing validation names/messages/results are logged;
261. no mutation is committed;
262. final full suite runs only after all restoration.

## Documentation reconciliation
263. current docs/02 no longer says M14 reservation is future;
264. current docs/02 no longer says M15 TargetSelector is future;
265. current docs/02 no longer says M16/M17 routing is future;
266. current docs/02 no longer says M18/M19 Scrubbot/dispatcher are future;
267. current docs/02 no longer says completed M10 owner QA is pending;
268. current docs accurately describes M20 current boundary;
269. current docs does not invent M21+ design;
270. touched current tracker reference uses `TASKS.md` casing;
271. historical prompts/audits remain unchanged.

## Final validation / immutability / handoff
272. Godot version is 4.7.1 stable;
273. full root suite passes with exact total/pass/failure recorded;
274. zero final SCRIPT ERROR lines;
275. zero final Parse Error lines;
276. queue_free smoke passes;
277. V04 lifecycle smoke passes;
278. V05 lifecycle smoke passes;
279. V07 lifecycle smoke passes;
280. V08 lifecycle smoke passes if created;
281. git diff --check is clean;
282. exact changed-file list is recorded;
283. final loop blob equals 06391839523cbc27e88a4b3ef12b730012cd45fa;
284. final dispatcher blob equals eee10149e4f116af6706beec832042352bf3a6dd;
285. committed scripts/** diff vs V07 is empty;
286. no M21 real-art behavior is added;
287. no scoring/win/lose/session-complete/economy is added;
288. no slot queue/cooldown/consumption policy is added;
289. no second access cache is added;
290. all prior M20 V01-V07 tests remain enabled;
291. all M19 V01-V06 tests remain enabled;
292. CLAUDE_LOG_V08 exists;
293. log maps evidence to V08 groups and gaps G-V07-01..08;
294. final root task is M20-C001-V08;
295. final status is AWAITING_AUDIT on clean validation;
296. final Required Actor is CHATGPT;
297. progress remains 290/719 main+ui;
298. overall remains 290/943;
299. lastCompletedTaskId remains M19-C001-V06;
300. all SB-M20 rows remain open;
301. validation artifacts/docs/log/tracker are committed + pushed;
302. remote main is verified;
303. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
304. Claude does not begin M21;
305. any production defect exposed causes BLOCKED / V08_VALIDATION_EXPOSED_PRODUCTION_DEFECT with no production fix;
306. clean V08 leaves final task closure solely to independent ChatGPT audit.

Total numbered criteria: **306**.