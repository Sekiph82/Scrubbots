# M20-C001 — Auditor-Authored Validation-Only Audit Criteria V05

Canonical live tracker: repository-root `TASKS.md` only.

## Tracker / governance
1. root TASKS is sole live tracker;
2. CHATGPT_AUDIT_V04.md exists before validation starts;
3. CHATGPT_PROMPT_V05.md exists before validation starts;
4. starting task is M20-C001 V04 AWAITING_AUDIT / CHATGPT;
5. starting main+ui progress is 290/719 = 40.33%;
6. starting overall progress is 290/943 = 30.75%;
7. starting lastCompletedTaskId is M19-C001-V06;
8. all SB-M20-001..014 start open;
9. V05 tracker-only IN_PROGRESS transition is committed;
10. V05 tracker-only transition is pushed before any validation test edit;
11. V05 tracker-only transition is pushed before any temporary production mutation;
12. remote main start transition is verified;
13. Required Actor becomes CLAUDE only after authorized transition;
14. no .hiveai live tracker is recreated;
15. no CHATGPT_* artifact is modified by Claude;
16. no audit verdict is self-assigned;
17. no SB-M20 row is closed by Claude;
18. owner/local work is preserved.

## Production immutability
19. accepted implementation commit is 50be126cc7bf82e62650d81287c0bf2ba4ca7064;
20. accepted clearing-loop blob is f00c34021da85e596df58f08857acde8846dd8a4;
21. accepted dispatcher blob is 1709b8c8ebf7595596bdf8cbd059f04bf1196ea3;
22. pre-validation clearing-loop blob matches accepted value;
23. pre-validation dispatcher blob matches accepted value;
24. no committed V05 change under scripts/gameplay/clearing;
25. no committed V05 change under scripts/gameplay/dispatch;
26. no committed V05 change under scripts/gameplay/board;
27. no committed V05 change under scripts/gameplay/slots;
28. no committed V05 change under scripts/gameplay/targeting;
29. no committed V05 change under scripts/gameplay/routing;
30. no committed V05 change under scripts/gameplay/agents;
31. temporary production mutations are one-at-a-time only;
32. each temporary mutation is restored before the next mutation;
33. final clearing-loop blob equals accepted value;
34. final dispatcher blob equals accepted value;
35. final production diff against accepted V04 is clean for scripts/**;
36. any required production correction causes V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT rather than an unreviewed fix.

## Fresh V05 test structure
37. a dedicated V05 auditor-authored validation block exists;
38. fresh arrangements are constructed rather than only invoking old aggregate helpers;
39. all prior M20 V01-V04 tests remain enabled;
40. V05 tests directly observe the protected behaviors;
41. no unrelated earlier failure can make the key V05 assertions green;
42. test-only harness use does not widen production bind categories.

## Node lifecycle A — queued dispatcher before bind
43. exact production ScrubbotDispatcher is used;
44. dispatcher is queued for deletion before loop bind;
45. dispatcher remains instance-valid at the observation point;
46. bind returns false;
47. loop remains unbound;
48. zero assignment_arrived connection is created;
49. no SCRIPT ERROR occurs.

## Node lifecycle B — queued renderer before bind
50. exact production BoardRenderer is used;
51. renderer is queued for deletion before loop bind;
52. renderer remains instance-valid at observation point;
53. bind returns false;
54. loop remains unbound;
55. zero assignment_arrived connection is created;
56. no SCRIPT ERROR occurs.

## Node lifecycle C — dispatcher queued after bind
57. healthy exact loop binds first;
58. loop is coherent before dispatcher queue deletion;
59. dispatcher is queued after bind;
60. loop is_coherent becomes false;
61. activate_slot does not return success;
62. no new assignment is created after queued state;
63. reset is safely callable while dispatcher still instance-valid;
64. future coherence stays false;
65. no SCRIPT ERROR occurs.

## Node lifecycle D — renderer queued with live assignment
66. healthy exact loop with renderer binds;
67. one real active M19 assignment exists before renderer queue deletion;
68. corresponding exact reservation exists;
69. BoardState target is ACTIVE before reset;
70. renderer is queued after assignment creation but before arrival;
71. loop coherence becomes false;
72. loop.reset removes dispatcher-owned active assignment;
73. loop.reset removes the exact original current reservation;
74. BoardState target remains ACTIVE;
75. cleared_count remains unchanged;
76. no false transparent clear is reported.

## Node lifecycle E — truly destroyed nodes
77. a frame-aware SceneTree smoke is used where needed;
78. dispatcher destroyed before bind is instance-invalid;
79. bind with destroyed dispatcher fails cleanly;
80. dispatcher destroyed after healthy bind makes coherence false;
81. activation after destroyed dispatcher fails closed;
82. reset after destroyed dispatcher does not call invalid object;
83. renderer destroyed before bind fails cleanly;
84. renderer destroyed after healthy bind makes coherence false;
85. activation/reset after destroyed renderer follows fail-closed law;
86. no freed-object SCRIPT ERROR occurs.

## Post-dispatch reset barrier
87. exact M20 bundle is used;
88. injected callback occurs inside a real M19 dispatch after M20 preflight;
89. callback calls only loop.reset for reset signal;
90. arrangement otherwise permits M19 success;
91. owner counter before attempt is recorded;
92. owner counter after attempt equals before + 1 in this arrangement;
93. M20 return success is false;
94. failure_reason is RESETTING;
95. raw M19 success does not escape;
96. dispatcher active_count is zero when activate_slot returns;
97. current-attempt reservation is absent on return;
98. target BoardState remains ACTIVE;
99. cleared_count remains zero;
100. consumed owner id is not rewound;
101. later ordinary activation succeeds;
102. later successful owner id is strictly greater than consumed owner.

## Post-dispatch renderer-coherence barrier
103. real renderer is bound;
104. injected callback occurs inside real M19 dispatch;
105. callback only queues/frees renderer as safely executable;
106. arrangement otherwise permits M19 success;
107. exactly one owner token is consumed by the underlying dispatch arrangement;
108. M20 return success is false;
109. failure_reason is COHERENCE_FAILED;
110. raw M19 success does not escape;
111. dispatcher active_count zero on return;
112. current reservation absent on return;
113. target BoardState remains ACTIVE;
114. cleared_count remains zero;
115. no renderer false-clear is observed;
116. a fresh healthy bundle later operates.

## Pair-narrow reset A — healthy current + unrelated pair
117. one real active dispatcher T<->O pair exists;
118. one unrelated valid U<->OU reservation exists and is not a dispatcher active entry;
119. ReservationState remains on original board;
120. reset releases T<->O;
121. U<->OU survives exactly;
122. no unrelated owner/target changes;
123. dispatcher active bookkeeping clears;
124. agent cleanup occurs.

## Pair-narrow reset B — foreign board/different target
125. dispatcher active entry retains A/T/O identity;
126. same ReservationState is rebound to board B;
127. B/V/O is reserved;
128. reset preserves B/V/O exactly;
129. dispatcher active bookkeeping clears;
130. agent cleanup occurs.

## Pair-narrow reset C — foreign board/same numeric target
131. board B target index is numerically equal to original T;
132. B/T/O is reserved;
133. board identity remains foreign;
134. reset preserves B/T/O exactly;
135. dispatcher active bookkeeping clears.

## Pair-narrow reset D — same-board replacement + unrelated pair
136. original T<->O is removed;
137. same original board receives V<->O;
138. unrelated U<->OU also exists;
139. reset preserves V<->O;
140. reset preserves U<->OU;
141. reset does not release by owner token alone;
142. dispatcher active bookkeeping clears.

## Pair-narrow reset E — missing current pair + unrelated pair
143. dispatcher active entry still records T/O;
144. T<->O is absent before reset;
145. unrelated U<->OU exists;
146. reset preserves U<->OU;
147. reset fabricates no reservation;
148. dispatcher active bookkeeping clears.

## Pair-narrow reset F — through M20 loop
149. foreign-board drift is created while M20 loop remains bound to original truth;
150. loop.reset is called rather than direct dispatcher.reset;
151. foreign B reservation survives exact owner/target identity;
152. dispatcher active bookkeeping clears;
153. M20 queue/current bookkeeping clears;
154. BoardState is not rewound to hide drift.

## Arrival queue / authentication
155. wrong owner cannot clear;
156. wrong target cannot clear;
157. wrong color cannot clear;
158. wrong source agent cannot clear;
159. duplicate currently-processing owner+agent is dropped;
160. duplicate already queued owner+agent is dropped;
161. distinct second arrival during current transaction is queued;
162. distinct arrivals drain FIFO;
163. each distinct authenticated arrival clears at most once;
164. current-arrival identity is cleared after transaction;
165. reset clears stale queued arrivals;
166. stale replay after reset cannot clear.

## Reset during transaction
167. reset during candidate phase is injected through test-only seam;
168. target returns/remains ACTIVE after abort;
169. candidate truth restored;
170. no cleared_count increment;
171. in-flight assignment removed safely after reset drain;
172. reset during reservation phase is injected through test-only seam;
173. exact reservation/BoardState rollback law holds;
174. no false renderer clear;
175. later healthy activation recovers where bundle remains healthy.

## Exact reservation/candidate regression
176. successful clear exact owner map is pre minus current target;
177. unrelated reservation owner/target identity survives success;
178. identity-swap corruption yields ROLLBACK_FAILED;
179. identity-swap cannot masquerade as ordinary rollback;
180. same-color unrelated candidate survives successful target clear;
181. other-color candidate bucket survives;
182. rollback restores target candidate;
183. rollback preserves unrelated same-color candidate;
184. no normal-path full-board candidate snapshot is added.

## Failed-preflight recovery
185. authenticated M19 arrival with broken M20 reservation preflight cannot clear;
186. BoardState remains ACTIVE;
187. dispatcher arrived assignment remains held before recovery reset;
188. loop.reset removes stranded assignment safely;
189. stale replay after reset cannot clear;
190. later healthy activation succeeds.

## True 1x1 integration
191. width == 1;
192. height == 1;
193. cell_count == 1;
194. sole ACTIVE cell dispatches;
195. arrival clears sole cell;
196. reservation resolves;
197. dispatcher finalizes;
198. second activation reports no work.

## AL-028 second real dispatch
199. B starts unreachable;
200. A is reachable blocker/gate;
201. first real activate_slot selects A;
202. A arrival clears A;
203. access sees A open;
204. second real activate_slot is invoked;
205. second dispatch selects B;
206. B exact reservation exists;
207. B arrival clears B;
208. B reservation resolves and dispatcher finalizes.

## Five-slot integration
209. exactly five slots configured;
210. five activations succeed where topology permits;
211. five owner ids are unique;
212. five target indices are distinct;
213. five exact reservation pairs exist before arrivals;
214. dispatcher active_count is five;
215. first arrival clears only its pair;
216. other four reservation pairs remain exact;
217. other four dispatcher entries remain;
218. all five eventually clear;
219. dispatcher active_count ends zero;
220. reservations for those five end absent.

## Scale / stress
221. 59x59 validation runs;
222. 59x59 clear changes only intended cell on normal path;
223. rectangular production-board validation runs;
224. no square-only assumption observed;
225. rapid 25+ sequential cycles run;
226. owner ids remain unique/monotonic;
227. no lingering reservations/agents after completed cycles.

## Deferred destruction
228. queue-free smoke runs separately;
229. smoke advances a real SceneTree frame;
230. finalized agent becomes invalid/freed;
231. no orphan child remains;
232. V04 lifecycle smoke runs separately;
233. any V05 lifecycle smoke runs separately if added.

## Sensitivity S1 — Node liveness
234. S1 mutation occurs only after V05 start push;
235. pre-mutation clearing-loop blob is recorded;
236. liveness mutation treats queued Node as healthy;
237. queued dispatcher and/or renderer targeted validation fails for intended reason;
238. exact failing test name/result is recorded;
239. mutation is fully restored;
240. restored clearing-loop blob equals f00c34021da85e596df58f08857acde8846dd8a4.

## Sensitivity S2 — post-dispatch generation barrier
241. S2 mutation occurs after S1 restore;
242. post-dispatch reset/generation check is removed/bypassed temporarily;
243. reset-inside-M19 targeted validation fails for intended stale-success/RESETTING reason;
244. exact failing test name/result is recorded;
245. mutation is fully restored;
246. restored clearing-loop blob equals accepted V04 value.

## Sensitivity S3 — pair-narrow reset
247. S3 mutation occurs after clearing-loop restore;
248. dispatcher reset is weakened to owner-wide or otherwise removes the board/pair guard;
249. foreign/replacement/unrelated preservation targeted validation fails for intended reason;
250. exact failing test name/result is recorded;
251. mutation is fully restored;
252. restored dispatcher blob equals 1709b8c8ebf7595596bdf8cbd059f04bf1196ea3.

## Upstream regression / architecture
253. BoardState strict suite green;
254. BoardRenderer suite green;
255. M11 session green;
256. M12 slots green;
257. M13 candidate green;
258. M14 reservation green;
259. M15-C002 final selector green;
260. M16 routing green;
261. M17 production routing green;
262. M18 agent green;
263. all M19 V01-V06 tests remain enabled and green;
264. all M20 V01-V04 tests remain enabled and green;
265. M19 authenticated arrival identity unchanged;
266. M19 itself still does not clear BoardState;
267. no new access cache is introduced;
268. no RESERVED BoardState state introduced;
269. clear order remains Board -> candidate -> reservation -> dispatcher -> renderer;
270. no normal-path full BoardState scan introduced;
271. no one-Node-per-cell architecture introduced;
272. no automatic next-bot dispatch added;
273. no win/lose/scoring/economy/session-complete implementation added;
274. no M21 production implementation added.

## Final validation / handoff
275. Godot version is 4.7.1 stable;
276. final full root suite command and exact total/pass/failure recorded;
277. zero final M20 SCRIPT ERROR recorded;
278. zero final Parse Error recorded;
279. git diff --check clean;
280. exact final changed-file list recorded;
281. final production file diff is empty for scripts/**;
282. final clearing-loop blob exact;
283. final dispatcher blob exact;
284. CLAUDE_LOG_V05 exists;
285. log records all three sensitivity mutations and restores;
286. log records fresh Node lifecycle results;
287. log records fresh post-dispatch barrier results;
288. log records fresh pair-narrow reset results;
289. log records fresh direct integration results;
290. final root TASKS current task is M20-C001-V05;
291. final status is AWAITING_AUDIT;
292. final Required Actor is CHATGPT;
293. progress remains 290/719 and 290/943;
294. lastCompletedTaskId remains M19-C001-V06;
295. all SB-M20 rows remain open;
296. validation tests/log/tracker are pushed to origin/main;
297. no final production mutation is committed;
298. Claude does not mark COMPLETE or READY_FOR_NEXT_TASK;
299. Claude does not self-audit;
300. production defect uses V05_VALIDATION_EXPOSED_PRODUCTION_DEFECT;
301. tracking failure uses GITHUB_TRACKING_NOT_SYNCED;
302. ChatGPT independent runtime limitation remains disclosed.

If all applicable criteria pass and no production defect is exposed, ChatGPT may final-close M20-C001 and the SB-M20-001..014 task set.