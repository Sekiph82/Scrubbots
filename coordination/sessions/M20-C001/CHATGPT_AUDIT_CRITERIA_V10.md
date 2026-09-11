# M20-C001 — Final Closure-Only Audit Criteria V10

Canonical tracker: root `TASKS.md` only.

Production is immutable. V10 closes only G-V09-01..06.

## Governance / scope
1. V09 independent audit exists before V10 execution;
2. V10 freeze exists;
3. V10 prompt exists;
4. V10 criteria exists;
5. starting production loop blob is `06391839523cbc27e88a4b3ef12b730012cd45fa`;
6. starting dispatcher blob is `eee10149e4f116af6706beec832042352bf3a6dd`;
7. no committed V10 `scripts/**` change;
8. all SB-M20-001..014 start open;
9. progress starts 290/719 main+ui and 290/943 overall;
10. lastCompletedTaskId starts M19-C001-V06;
11. V10 tracker IN_PROGRESS transition is pushed before any V10 test/smoke edit;
12. owner/local work is preserved;
13. no `.hiveai` tracker is recreated;
14. Claude assigns no audit verdict;
15. Claude does not start M21.

## G-V09-01 claim/reset actual usability
16. fresh claim arrangement has at least two reachable targets;
17. diagnostic listener is connected before first M20 bind;
18. first loop binds;
19. second different live loop cannot bind;
20. first loop clears target A exactly once;
21. detached BoardState snapshot is captured before owner reset;
22. detached exact reservation map/count snapshot is captured before owner reset;
23. owner reset with no active work preserves BoardState snapshot;
24. owner reset preserves reservation map/count snapshot;
25. owner reset does not release/transfer M20 claim;
26. second loop remains rejected after owner reset;
27. original first loop performs a SECOND real activate_slot after reset;
28. second real activation succeeds;
29. second real arrival clears target B;
30. first loop cleared_count advances exactly one additional time;
31. second loop cleared_count remains zero;
32. single-owner claim remains intact through second operation.

## G-V09-02 activation serialization exactness
33. nested activation test captures owner counter before outer activation;
34. nested activation is injected from activation preflight callback;
35. nested result is REENTRANT;
36. healthy outer activation succeeds;
37. exactly one active assignment exists from outer call;
38. exactly one reservation exists from outer call;
39. next-owner id advances exactly once total;
40. nested rejected request consumes no second owner token;
41. a separate fresh arrangement creates a real assignment A for arrival-drain test;
42. a transaction hook fires while arrival A is actively draining;
43. hook calls a second activate_slot while `_draining` is active;
44. inner drain-time activation returns REENTRANT;
45. inner drain-time activation creates no additional active assignment;
46. inner drain-time activation creates no additional reservation;
47. inner drain-time activation consumes no additional owner token;
48. outer arrival transaction completes normally in healthy arrangement;
49. loop remains usable after arrival drain;
50. a later ordinary activation succeeds after drain completes.

## G-V09-03 failed-preflight exact preservation
51. missing-reservation case is fresh;
52. missing-reservation preflight rejects;
53. missing-reservation cleared_count unchanged;
54. missing-reservation dispatcher assignment is not silently finalized;
55. missing-reservation BoardState remains expected ACTIVE;
56. candidate-foreign case is fresh;
57. candidate-foreign rejects;
58. candidate-foreign exact target->owner reservation remains;
59. candidate-foreign exact owner->target reservation remains;
60. candidate-foreign dispatcher assignment remains pending;
61. candidate-foreign cleared_count remains zero;
62. candidate-null case is fresh;
63. candidate-null rejects cleanly;
64. candidate-null exact target->owner reservation remains;
65. candidate-null exact owner->target reservation remains;
66. candidate-null dispatcher assignment remains pending;
67. candidate-null cleared_count remains zero;
68. externally-CLEARED case is fresh;
69. externally-CLEARED arrival rejects;
70. externally-CLEARED cleared_count stays zero;
71. externally-CLEARED exact reservation remains both directions;
72. externally-CLEARED dispatcher assignment remains pending;
73. renderer-foreign case is fresh after a real dispatch;
74. renderer-foreign arrival clears nothing;
75. renderer-foreign target stays ACTIVE;
76. renderer-foreign raw target candidate remains present;
77. renderer-foreign reservation remains both directions;
78. renderer-foreign dispatcher assignment remains pending;
79. renderer-queued case is fresh after a real dispatch;
80. renderer-queued arrival clears nothing;
81. renderer-queued target stays ACTIVE;
82. renderer-queued raw target candidate remains present;
83. renderer-queued reservation remains both directions;
84. renderer-queued dispatcher assignment remains pending;
85. frame smoke truly frees configured renderer before arrival;
86. truly-freed renderer clears nothing;
87. truly-freed renderer raw target candidate remains present;
88. truly-freed renderer reservation remains both directions;
89. truly-freed renderer dispatcher assignment remains pending until reset;
90. failed-preflight cleanup smoke calls authorized reset;
91. cleanup removes only original reservation pair;
92. unrelated sentinel reservation/cell survives cleanup;
93. cleanup processes SceneTree frames;
94. failed-preflight held agent becomes invalid/freed after frames;
95. no orphan child remains for cleaned assignment.

## G-V09-04 ledger exact identity
96. five-slot arrangement creates five unique owners;
97. five-slot arrangement creates five distinct targets;
98. five initial pairs are exact both directions;
99. first arrival makes first target->owner absent;
100. first arrival makes first owner->target absent;
101. remaining four pairs stay exact target->owner;
102. remaining four pairs stay exact owner->target;
103. all five finalize;
104. final active count is zero;
105. final reservation count is zero;
106. Easy row records expected target index;
107. Easy expected target is directly CLEARED;
108. Easy CLEARED count delta is +1;
109. Medium expected target directly CLEARED;
110. Medium CLEARED count delta +1;
111. Hard expected target directly CLEARED;
112. Hard CLEARED count delta +1;
113. Very Hard expected target directly CLEARED;
114. Very Hard CLEARED count delta +1;
115. 59x59 expected target directly CLEARED;
116. 59x59 CLEARED count delta +1;
117. rectangular expected target directly CLEARED;
118. rectangular CLEARED count delta +1.

## G-V09-05 detached rollback prestate
119. candidate mutate-before-false arrangement includes target T;
120. it includes unrelated same-color U;
121. it includes different-color V;
122. detached full BoardState snapshot is captured before candidate fault;
123. detached relevant same-color candidate bucket is captured;
124. detached different-color candidate bucket is captured;
125. detached exact reservation map/count is captured;
126. dispatcher active/owner state is captured;
127. candidate fault yields CANDIDATE_ROLLBACK or ROLLBACK_FAILED;
128. if CANDIDATE_ROLLBACK, BoardState snapshot matches exactly;
129. if CANDIDATE_ROLLBACK, same-color candidate bucket matches exactly;
130. if CANDIDATE_ROLLBACK, different-color candidate bucket matches exactly;
131. if CANDIDATE_ROLLBACK, reservation map/count matches exactly;
132. if CANDIDATE_ROLLBACK, dispatcher state matches exact pre-arrival expectation;
133. reservation mutate-before-false arrangement includes current pair;
134. arrangement includes at least one unrelated reservation pair;
135. detached exact target->owner map/count captured before fault;
136. reverse owner->target identities captured for all arranged owners;
137. BoardState snapshot captured;
138. dispatcher state captured;
139. fault yields RESERVATION_ROLLBACK or ROLLBACK_FAILED;
140. if RESERVATION_ROLLBACK, full target->owner map/count matches exactly;
141. if RESERVATION_ROLLBACK, every reverse owner->target identity matches exactly;
142. if RESERVATION_ROLLBACK, BoardState matches exact prestate;
143. if RESERVATION_ROLLBACK, dispatcher state matches exact pre-arrival expectation.

## G-V09-06 traceability / final validation
144. CLAUDE_LOG_V10 exists;
145. log contains G-V09-01 row;
146. log contains G-V09-02 row;
147. log contains G-V09-03 row;
148. log contains G-V09-04 row;
149. log contains G-V09-05 row;
150. log contains G-V09-06 row;
151. every row names exact test/smoke;
152. every row names direct assertion(s);
153. every row records actual runtime result;
154. log distinguishes root-suite versus frame-smoke evidence;
155. Godot version recorded as 4.7.1 stable;
156. full root suite passes with exact total/pass/fail recorded;
157. queue_free smoke passes;
158. V04 lifecycle smoke passes;
159. V05 lifecycle smoke passes;
160. V07 lifecycle smoke passes;
161. V08 lifecycle smoke passes;
162. V09 lifecycle smoke passes;
163. V10 lifecycle smoke passes if created;
164. final outputs inspected for literal SCRIPT ERROR;
165. final outputs inspected for literal Parse Error;
166. `git diff --check` clean;
167. exact changed files recorded;
168. no docs change;
169. final loop blob equals locked blob;
170. final dispatcher blob equals locked blob;
171. committed `scripts/**` diff vs e189ee8 is empty;
172. all prior M19 tests remain enabled;
173. all prior M20 V01-V09 tests remain enabled;
174. no M21 behavior added;
175. no scoring/win/lose/session/economy added;
176. no slot queue/cooldown/consumption behavior added;
177. final clean tracker is M20-C001-V10 / AWAITING_AUDIT / CHATGPT;
178. progress remains 290/719 and 290/943;
179. lastCompletedTaskId remains M19-C001-V06;
180. SB-M20-001..014 remain open for ChatGPT closure;
181. validation/log/tracker changes are pushed and remote verified;
182. any newly exposed production defect causes BLOCKED with no production fix.

Total numbered criteria: **182**.