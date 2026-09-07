# M15-C001 — Strict Audit Criteria V02

Final strict closure requires:

1. malformed non-null BoardState dependency rejected safely;
2. malformed non-null candidate-index dependency rejected safely;
3. malformed non-null reservation dependency rejected safely;
4. failed bind leaves selector unbound and stale refs unusable;
5. ColorCandidateIndex exposes read-only exact board-identity check;
6. ReservationState exposes read-only exact board-identity check;
7. same-size different-board candidate mismatch fails bind;
8. same-size different-board reservation mismatch fails bind;
9. candidate rebind after valid selector bind causes selection to fail closed;
10. reservation rebind after valid selector bind causes selection to fail closed;
11. no mutable board reference leaks through coherence API;
12. same-owner side-effect contention is directly exercised;
13. after failed reserve, owner-now-assigned condition stops iteration;
14. later candidates are not queried in that condition;
15. only the side-effect reservation remains;
16. different-owner contention still allows unassigned requester to continue;
17. deterministic ascending selection preserved;
18. no blocked/CLEARED/wrong-color target accepted;
19. no routing/pathfinding added;
20. no BoardState mutation;
21. no candidate truth mutation;
22. 59×59 + rectangular regressions pass;
23. full Godot suite passes;
24. git diff --check clean;
25. governance files untouched by Claude;
26. matching CLAUDE_LOG_V02 exists;
27. Claude does not self-audit;
28. ChatGPT discloses runtime rerun availability.

If all pass, re-close SB-M15-001, 007, 008, 011.
