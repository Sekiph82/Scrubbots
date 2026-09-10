# M15-C002 — Upstream Strict Audit Criteria V01

## H!veAI start
1. synced canonical task is M15-C002-V01;
2. starting actor is CLAUDE;
3. starting workflow authorizes implementation;
4. progress starts 278/719 = 38.66%;
5. start transition to IN_PROGRESS is pushed before production edits;
6. matching hiveai-event/v1 start row exists;
7. stale current-state text in `.hiveai/TASKS.md` is reconciled.

## Pre-fix sensitivity
8. scalar access_query is tested against pre-fix source;
9. non-bool true-ish is_targetable return is tested pre-fix;
10. selector.bind re-entry from targetability callback is tested pre-fix;
11. ReservationState rebind from targetability callback is tested pre-fix;
12. exact pre-fix return/fault/mutation/ownership outcomes are recorded;
13. production correction happens only after pre-fix evidence.

## Bind category / coherence
14. real BoardState accepted;
15. null board rejected;
16. scalar/String/Vector2/Array/Dictionary board rejected safely;
17. junk/method-compatible Node board rejected;
18. candidate_index must be RefCounted + required API;
19. candidate method-compatible Node rejected;
20. reservation_state must be RefCounted + complete required API;
21. reservation method-compatible Node rejected;
22. missing candidate/reservation API rejected;
23. candidate is_bound_to non-bool rejected;
24. candidate is_bound_to false rejected;
25. reservation is_bound_to non-bool rejected;
26. reservation is_bound_to false rejected;
27. failed ordinary bind outside selection preserves documented neutralization semantics;
28. valid rebind outside active selection remains supported.

## Bind during active selection
29. nested bind from access callback returns false;
30. nested bind from candidate callback returns false where injected;
31. nested bind from reservation callback returns false where injected;
32. nested bind does not clear active operation binding;
33. nested bind does not install board B;
34. no reservation is created in board B;
35. selector remains coherent with original A bundle until operation ends.

## access_query Variant boundary
36. null access -> -1;
37. int access -> -1/no fault;
38. float access -> -1/no fault;
39. String access -> -1/no fault;
40. bool access -> -1/no fault;
41. Vector2 access -> -1/no fault;
42. Array access -> -1/no fault;
43. Dictionary access -> -1/no fault;
44. plain RefCounted missing is_targetable -> -1;
45. method-compatible Node access rejected;
46. valid RefCounted access accepted.

## targetability return type
47. actual bool true can permit candidate;
48. actual bool false skips candidate;
49. null verdict does not approve;
50. int 1 verdict does not approve;
51. float 1.0 verdict does not approve;
52. String verdict does not approve;
53. Vector2 verdict does not approve;
54. RefCounted/Object verdict does not approve;
55. Array verdict does not approve;
56. Dictionary verdict does not approve;
57. malformed targetability cannot create reservation.

## Dynamic return contracts
58. get_target_for_owner actual int accepted;
59. malformed get_target_for_owner fails closed;
60. get_reserved_indices PackedInt32Array accepted;
61. malformed reserved snapshot fails closed;
62. get_candidates Array accepted;
63. malformed candidate container fails closed;
64. integer candidate entries processed;
65. null candidate entry skipped safely;
66. float candidate entry skipped safely;
67. String candidate entry skipped safely;
68. Vector2/Object/Array/Dictionary candidate entries skipped safely;
69. is_reserved actual bool accepted;
70. non-bool is_reserved fails closed;
71. reserve actual bool true may succeed;
72. reserve actual bool false follows contention path;
73. non-bool reserve result cannot count as success;
74. get_owner ownership-proof return must be int;
75. malformed get_owner prevents success return.

## Operation snapshot / drift
76. operation captures original board/candidate/reservation identity or generation;
77. candidate rebind during targetability callback detected before reserve;
78. ReservationState rebind during targetability callback detected before reserve;
79. selector bind re-entry cannot move bundle;
80. drift during candidate query detected;
81. drift during reserved-snapshot/owner query detected where injected;
82. drift during is_reserved detected where injected;
83. drift during reserve detected after callback;
84. no success returns from a drifted operation;
85. no foreign-board reservation is leaked by selector;
86. original unrelated reservation truth is not erased.

## Post-reserve ownership proof
87. reserve true + exact owner->target + target->owner returns target;
88. reserve true but stores nothing -> -1;
89. reserve true but owner maps to other target -> -1;
90. reserve true but target maps to other owner -> -1;
91. malformed ownership proof -> -1;
92. selector-created reservation is rolled back on post-reserve drift/failure;
93. rollback removes only exact current operation ownership;
94. no unrelated contention reservation is removed.

## Preserve contention semantics
95. same-owner side-effect reservation causes -1;
96. same-owner side-effect reservation is preserved;
97. same-owner case queries no later candidates after owner assignment known;
98. different-owner first-target contention can continue;
99. different-owner path can select next valid target;
100. no double reservation;
101. deterministic ascending selection remains.

## Preserve core M15
102. matching color only;
103. CLEARED never selected;
104. invalid candidate never selected;
105. unreachable candidate skipped;
106. BoardState not mutated;
107. candidate truth not mutated;
108. no routing/path computation in TargetSelector;
109. no M19 dispatch/agent logic added;
110. is_bound_to(board,reservation_state) exact identity preserved;
111. rectangular regression green;
112. 59x59 regression green;
113. no full-board scan introduced.

## Downstream regression
114. M13 strict regressions green;
115. M14 strict regressions green;
116. historical M15-C001 regressions green;
117. M16/M17 routing regressions green;
118. M18 agent regressions green;
119. existing M19 V02/V03 root tests remain green or are updated only where stricter M15 fail-closed semantics require equivalent expectation.

## Scope / governance
120. only TargetSelector production changes;
121. BoardState unchanged;
122. ColorCandidateIndex production unchanged;
123. ReservationState production unchanged;
124. M19 dispatcher production unchanged;
125. root tasks.md checkboxes untouched by Claude;
126. ChatGPT audit/index/CHATGPT_* untouched;
127. legacy H!veAI trackers not maintained;
128. PROJECT.json/RULES.md unchanged.

## Validation / final H!veAI
129. Godot 4.7.1 exact version recorded;
130. full root suite passes;
131. zero SCRIPT/Parse errors;
132. git diff --check clean;
133. matching CLAUDE_LOG_V01 exists;
134. final tracker workflowState AWAITING_AUDIT;
135. final requiredActor CHATGPT;
136. currentTaskId remains M15-C002-V01;
137. progress remains 278/719 = 38.66%;
138. lastCompletedTaskId remains FOUNDATION-C001-V01;
139. blockers empty on success;
140. IN_PROGRESS -> AWAITING_AUDIT event exists;
141. implementation/tests/log/tracker/events pushed to origin/main;
142. Claude does not claim COMPLETE / READY_FOR_NEXT_TASK;
143. Claude does not self-audit;
144. tracker push failure uses GITHUB_TRACKING_NOT_SYNCED;
145. genuine blocker uses canonical BLOCKED state/event;
146. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may close M15-C002 and return to M19-C001 V04. Task checkbox reopen/re-close disposition remains ChatGPT-owned.
