# M15-C002 — Strict Closure Audit Criteria V03

## H!veAI start
1. canonical task is M15-C002-V03;
2. requiredActor is CLAUDE;
3. workflowState authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. IN_PROGRESS tracker/event is committed and pushed BEFORE any V03 production/test edit;
6. machine and human tracker state agree;
7. V02 process-order nonconformance is not repeated.

## Select during bind transaction
8. selector is first validly bound to bundle A;
9. outer bind to valid bundle B begins;
10. candidate bind-time coherence callback attempts nested selection;
11. nested selection returns -1;
12. nested selection makes zero targetability call;
13. nested selection creates zero A reservation;
14. nested selection creates zero B reservation;
15. outer candidate-callback bind B commits normally;
16. selector ends coherent with B;
17. later selection on B succeeds;
18. same scenario is repeated from reservation bind-time coherence callback;
19. reservation-callback nested selection returns -1;
20. no orphan A reservation exists;
21. outer bind B remains deterministic;
22. select rejection is caused by `_in_bind`, not unrelated invalid input.

## Post-targetability owner-query boundary
23. valid candidate reaches targetability callback;
24. true verdict path reaches post-targetability owner query;
25. candidate drift inside owner query while return remains int -1 is injected;
26. candidate drift returns -1 from selector;
27. candidate drift performs zero reserve;
28. candidate drift creates no reservation;
29. ReservationState drift inside owner query while return remains int -1 is injected;
30. ReservationState drift returns -1;
31. no downstream reserve after ReservationState drift;
32. false-verdict owner-query drift is directly covered;
33. false-verdict drift stops before later candidate targetability;
34. at least one non-bool-verdict owner-query drift path is covered or equivalent sensitivity is demonstrated;
35. owner-query return TYPE_INT is checked before value use;
36. operation coherence is checked after the owner query and before reserve/continue.

## Post-reserve proof ordering
37. baseline reserve stores exact current idx/owner pair;
38. get_owner is called only after successful reserve + coherence;
39. malformed get_owner returns -1 from selector;
40. malformed get_owner exact pair is rolled back;
41. malformed get_owner causes ZERO target-proof callback after known failure;
42. get_owner callback can drift candidate while returning correct owner;
43. that drift returns -1;
44. that drift exact pair is rolled back;
45. target-proof callback is not invoked after detected get_owner drift;
46. get_owner callback ReservationState drift returns -1/no success;
47. no replacement/orphan reservation appears after ReservationState drift;
48. valid typed get_owner is followed by coherence check before target-proof call;
49. target-proof callback can drift candidate while returning correct target;
50. target-proof candidate drift returns -1;
51. target-proof candidate drift exact pair is rolled back;
52. target-proof callback ReservationState drift returns -1/no success;
53. valid typed target-proof is followed by coherence check before success;
54. exact owner/target comparison happens only after both typed/coherent proof steps;
55. unrelated reservation survives each exact rollback case;
56. test sensitivity would fail if either post-proof coherence check were removed.

## Preserve malformed reserve cleanup
57. reserve stores exact pair then returns int 1;
58. selector returns -1;
59. exact pair absent after return;
60. unrelated reservation preserved;
61. non-bool reserve never counts as success.

## Preserve same-owner law
62. same-owner side effect with true verdict returns -1 and preserves external reservation;
63. same-owner side effect with false verdict returns -1 and preserves external reservation;
64. false-verdict case queries no later targetability candidate;
65. non-bool verdict case preserves external same-owner reservation;
66. no selector-created second reservation appears.

## Preserve selection/bind guards
67. `_in_selection` armed before initial candidate coherence callback;
68. `_in_selection` armed before initial reservation coherence callback;
69. recursive selection from targetability returns -1;
70. recursive selection from candidate query returns -1;
71. recursive selection from reservation query returns -1;
72. nested bind during active selection returns false;
73. nested bind during bind transaction returns false;
74. failed initial coherence clears selection guard;
75. failed bind validation clears bind guard;
76. later clean operations recover.

## Preserve per-boundary coherence
77. initial coherence checked;
78. initial owner query checked;
79. reserved snapshot checked;
80. candidate query checked;
81. is_reserved false checked;
82. is_reserved true checked;
83. targetability checked;
84. post-targetability owner query checked;
85. reserve checked;
86. get_owner proof checked;
87. target-proof checked;
88. detected drift cannot return a successful target.

## Preserve Variant/category hardening
89. board must be real BoardState;
90. candidate dependency RefCounted + API;
91. reservation dependency RefCounted + API;
92. method-compatible Nodes rejected;
93. access query RefCounted + is_targetable;
94. scalar/String/Vector2/Array/Dictionary access fails safely;
95. actual bool true targetability accepted;
96. actual bool false not accepted;
97. null/int/float/String/Vector2/Object/Array/Dictionary targetability verdicts do not approve;
98. get_target_for_owner must be int;
99. reserved snapshot must be PackedInt32Array;
100. candidates must be Array;
101. candidate entries must be int before BoardState use;
102. is_reserved must be bool;
103. reserve must be bool;
104. ownership proof returns must be ints;
105. malformed dynamic results cause stable -1/no runtime fault.

## Preserve core M15
106. one target per owner;
107. one owner per target;
108. different-owner contention may continue;
109. deterministic ascending candidate order;
110. matching color only;
111. CLEARED never selected;
112. invalid candidate skipped;
113. unreachable candidate skipped;
114. BoardState not mutated by TargetSelector;
115. candidate truth not mutated by TargetSelector;
116. no routing/path generation;
117. no M19 dispatcher/agent behavior;
118. exact `is_bound_to(board,reservation_state)` seam preserved;
119. no full-board scan;
120. rectangular regression green;
121. 59x59 regression green.

## Downstream regressions
122. M13 strict regressions green;
123. M14 strict regressions green;
124. M15-C001 regressions green;
125. M15-C002 V01/V02 accepted behaviors green;
126. M16/M17 routing regressions green;
127. M18 agent regressions green;
128. M19 V02/V03 tests remain green without M19 production edits.

## Scope/governance
129. only TargetSelector production changes;
130. BoardState unchanged;
131. ColorCandidateIndex production unchanged;
132. ReservationState production unchanged;
133. M19 dispatcher unchanged;
134. routing/ScrubbotAgent production unchanged;
135. root tasks.md checkboxes untouched by Claude;
136. AUDIT_INDEX and CHATGPT_* untouched by Claude;
137. legacy H!veAI trackers not maintained;
138. PROJECT.json/RULES.md unchanged.

## Validation/final H!veAI
139. exact Godot 4.7.1 version recorded;
140. full root suite passes;
141. zero SCRIPT/Parse errors;
142. git diff --check clean;
143. matching CLAUDE_LOG_V03 exists;
144. final workflowState AWAITING_AUDIT;
145. final requiredActor CHATGPT;
146. final currentTaskId M15-C002-V03;
147. blockers empty on success;
148. progress remains 278/719 = 38.66%;
149. lastCompletedTaskId remains FOUNDATION-C001-V01;
150. matching IN_PROGRESS -> AWAITING_AUDIT event exists;
151. implementation/tests/log/tracker/events pushed to origin/main;
152. Claude does not mark COMPLETE/READY_FOR_NEXT_TASK;
153. Claude does not self-audit;
154. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
155. genuine blocker uses BLOCKED state/event;
156. ChatGPT records independent Godot rerun availability.

If all criteria pass, ChatGPT may independently close M15-C002 and issue M19-C001 V04.
