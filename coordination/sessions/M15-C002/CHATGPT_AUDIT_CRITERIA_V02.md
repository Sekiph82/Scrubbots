# M15-C002 — Strict Closure Audit Criteria V02

## H!veAI start
1. synced canonical task is M15-C002-V02;
2. starting actor is CLAUDE;
3. starting workflow authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. start transition to IN_PROGRESS is pushed before production edits;
6. matching hiveai-event/v1 start row exists;
7. machine and human current-state tracker text agree.

## V02 pre-fix sensitivity
8. V01 source commit `5a2ed276...` is used for sensitivity evidence before correction;
9. initial candidate-coherence callback nested bind is directly run pre-fix;
10. initial reservation-coherence callback nested bind is directly run pre-fix;
11. recursive select_and_reserve from targetability callback is directly run pre-fix;
12. is_reserved true + dependency drift is directly run pre-fix;
13. reserve stores exact pair then returns int 1 is directly run pre-fix;
14. exact pair + malformed get_owner rollback path is directly run pre-fix;
15. same-owner side effect + false targetability later-query behavior is run pre-fix;
16. exact return/mutation/reservation/query-count outcomes are recorded;
17. correction occurs only after those outcomes are recorded.

## Selection guard ordering
18. nested select call sees busy guard before any collaborator callback;
19. `_in_selection` is armed before initial candidate coherence callback;
20. `_in_selection` is armed before initial reservation coherence callback;
21. initial coherence failure clears guard;
22. no stuck-busy state after initial failure;
23. later clean sequential selection succeeds.

## Initial-coherence bind re-entry
24. candidate is_bound_to callback attempts nested bind;
25. nested candidate-coherence bind returns false;
26. reservation is_bound_to callback attempts nested bind;
27. nested reservation-coherence bind returns false;
28. original selector bundle remains A;
29. board/candidate/reservation B are not installed;
30. no reservation is created in B;
31. outer selection remains deterministic/fail-closed.

## Recursive selection
32. recursive select from targetability callback returns -1;
33. recursive same-owner call creates zero new reservation;
34. recursive different-owner call creates zero new reservation;
35. recursive select from candidate-query callback returns -1;
36. recursive select from reservation-query callback returns -1;
37. outer operation state remains coherent;
38. outer transaction does not duplicate reservation;
39. later normal call recovers.

## Bind transaction re-entry
40. outer bind marks bind transaction in progress before collaborator coherence callbacks;
41. candidate bind-time coherence callback nested bind returns false;
42. reservation bind-time coherence callback nested bind returns false;
43. inner bind cannot overwrite outer requested bundle;
44. outer valid bind commits once;
45. outer invalid bind leaves documented neutral state;
46. guard clears after outer bind failure;
47. later clean bind is supported;
48. existing ordinary failed-bind neutralization outside re-entry preserved.

## Coherence after each boundary
49. owner query followed by direct coherence validation;
50. reserved snapshot followed by direct coherence validation;
51. candidate query followed by direct coherence validation;
52. is_reserved false followed by direct coherence validation;
53. is_reserved TRUE also followed by direct coherence validation;
54. targetability callback followed by direct coherence validation;
55. reserve callback followed by direct coherence validation/rollback handling;
56. post-reserve proof callbacks cannot lead to success after drift.

## Direct drift injection coverage
57. candidate-query drift stops before reservation;
58. reserved-snapshot drift stops before candidate query/reservation;
59. owner-query drift stops before later work;
60. is_reserved false drift stops;
61. is_reserved true drift stops BEFORE next candidate;
62. targetability candidate-index rebind stops before reserve;
63. targetability ReservationState rebind stops before reserve;
64. reserve-time candidate drift returns -1;
65. reserve-time reservation drift returns -1;
66. no foreign-board reservation is returned as success;
67. no later targetability call occurs after detected drift.

## Malformed reserve return after mutation
68. baseline target is initially free;
69. baseline owner initially has no reservation;
70. reserve stores exact idx/owner then returns integer 1;
71. selector returns -1;
72. selector does not treat integer 1 as success;
73. exact idx/owner pair is absent after return;
74. reservation count proves no selector-created leak;
75. unrelated reservation is preserved;
76. test would fail if rollback call were removed.

## Ownership-proof rollback
77. reserve true + exact typed owner/target proof succeeds;
78. reserve true + stores nothing -> -1;
79. exact pair + malformed get_owner -> -1;
80. exact pair + malformed get_owner is removed;
81. exact pair + malformed get_target_for_owner -> -1;
82. exact pair + malformed get_target_for_owner is removed;
83. target actually owned by another owner is preserved;
84. owner mapped only to another target is preserved;
85. drift after exact reserve removes exact requested pair;
86. rollback uses exact release(idx,owner), not broad owner release;
87. unrelated contention reservation is never deleted;
88. malformed release return is not blindly treated as proof of cleanup where post-state can be observed.

## Same-owner side-effect no-later-query law
89. targetability callback can independently reserve another target for same owner;
90. with targetability bool true, selector returns -1 and preserves external reservation;
91. with targetability bool false, selector returns -1 and preserves external reservation;
92. with targetability non-bool, selector returns -1 and preserves external reservation;
93. false/non-bool cases query no later targetability candidate;
94. owner query after targetability is actual TYPE_INT validated;
95. malformed owner query after targetability fails closed.

## Preserve Variant boundary hardening
96. scalar/String/Vector2/Array/Dictionary access query returns -1/no fault;
97. method-compatible Node access rejected;
98. plain RefCounted missing is_targetable rejected;
99. actual bool true targetability accepted;
100. actual bool false not accepted;
101. null/int/float/String/Vector2/Object/Array/Dictionary verdicts do not approve;
102. malformed targetability itself cannot create selector-owned reservation.

## Preserve collaborator return hardening
103. get_target_for_owner must be int;
104. get_reserved_indices must be PackedInt32Array;
105. get_candidates must be Array;
106. non-int candidate entries never reach BoardState calls;
107. is_reserved must be bool;
108. reserve must be bool;
109. ownership proof queries must be ints;
110. malformed returns cause stable -1/no runtime fault.

## Preserve bind categories
111. board must be real BoardState;
112. candidate dependency must be RefCounted + required API;
113. reservation dependency must be RefCounted + required API;
114. method-compatible Nodes rejected;
115. candidate is_bound_to requires actual bool true;
116. reservation is_bound_to requires actual bool true.

## Preserve contention / core M15
117. same-owner side-effect reservation remains preserved;
118. different-owner contention may continue to next target;
119. no double reservation;
120. deterministic ascending candidate order;
121. matching color only;
122. CLEARED never selected;
123. invalid candidate skipped;
124. unreachable candidate skipped;
125. BoardState unchanged;
126. candidate truth unchanged;
127. no route/path generation;
128. no M19 dispatcher/agent behavior added;
129. exact `is_bound_to(board,reservation_state)` identity seam preserved;
130. no full-board scan introduced;
131. rectangular regression green;
132. 59x59 regression green.

## Downstream regression
133. M13 strict regressions green;
134. M14 strict regressions green;
135. M15-C001 regressions green;
136. M15-C002 V01 valid behaviors remain green;
137. M16/M17 routing regressions green;
138. M18 agent regressions green;
139. M19 V02/V03 existing regressions green without M19 production edits.

## Scope / governance
140. only TargetSelector production changes;
141. BoardState production unchanged;
142. ColorCandidateIndex production unchanged;
143. ReservationState production unchanged;
144. M19 dispatcher production unchanged;
145. routing/ScrubbotAgent production unchanged;
146. root tasks.md checkboxes untouched by Claude;
147. AUDIT_INDEX/CHATGPT_* untouched by Claude;
148. legacy H!veAI trackers not maintained;
149. PROJECT.json/RULES.md unchanged.

## Validation / H!veAI final
150. exact Godot 4.7.1 version recorded;
151. full root suite passes;
152. zero SCRIPT/Parse errors;
153. git diff --check clean;
154. matching CLAUDE_LOG_V02 exists;
155. final workflowState AWAITING_AUDIT;
156. final requiredActor CHATGPT;
157. final currentTaskId M15-C002-V02;
158. final blockers empty on success;
159. final progress remains 278/719 = 38.66%;
160. lastCompletedTaskId remains FOUNDATION-C001-V01;
161. matching IN_PROGRESS -> AWAITING_AUDIT event exists;
162. implementation/tests/log/tracker/events pushed to origin/main;
163. Claude does not mark COMPLETE / READY_FOR_NEXT_TASK;
164. Claude does not self-audit;
165. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
166. genuine blocker uses BLOCKED state/event;
167. ChatGPT records independent Godot rerun availability.

If all criteria pass, ChatGPT may independently close M15-C002 and issue the frozen M19-C001 V04 remainder prompt.
