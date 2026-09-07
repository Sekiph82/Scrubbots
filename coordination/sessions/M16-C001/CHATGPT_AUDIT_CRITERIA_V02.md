# M16-C001 — Strict Audit Criteria V02

Final strict closure requires:

1. NaN start rejected;
2. +INF start rejected;
3. -INF start rejected;
4. non-finite target_position rejected;
5. malformed request fails before access query;
6. NaN intermediate route point rejected;
7. INF intermediate route point rejected;
8. malformed point route makes zero access calls;
9. success + non-NONE reason rejected;
10. canonical failure structural validation exists;
11. failure + NONE rejected;
12. failure with points rejected;
13. failure with wrong target rejected;
14. access verdict must be actual bool;
15. integer/string/null access verdicts fail closed;
16. normal true/false access semantics preserved;
17. detached points preserved;
18. no retarget preserved;
19. no BoardState/ReservationState mutation;
20. swappability preserved;
21. board-local coordinate contract preserved;
22. 59×59 + 53×59 coverage passes;
23. no M17 pathfinding leakage;
24. full Godot suite passes;
25. git diff --check clean;
26. governance untouched;
27. matching CLAUDE_LOG_V02 exists;
28. Claude does not self-audit;
29. ChatGPT discloses runtime rerun availability.

If all pass, re-close SB-M16-002, 003, 010, 011.
