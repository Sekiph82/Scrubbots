# M17-C002 — Strict Audit Criteria V02

Final strict closure requires:

1. production reachability has no correctness-affecting 12-entry cap;
2. >12-entry adversarial board proves later-only valid entry is found;
3. same target retained in that case;
4. sampling is no longer production segment truth;
5. exact/supercover traversal implemented deterministically;
6. short-chord blocker (7,7) is directly rejected;
7. same chord with blocker CLEARED is accepted when otherwise open;
8. exact-corner cutting between blockers rejected;
9. axis-aligned CLEARED corridor accepted;
10. target final-center entry allowed;
11. target pass-through rejected;
12. every BFS neighbor edge checks segment access truth;
13. sensitivity double with OPEN cells + blocked specific edge is obeyed;
14. post-process keeps/falls back to last validated route;
15. final success is internally RouteValidator-clean before return;
16. ProductionRoutingSystem cannot return success for validator-invalid route;
17. missing cell_of_point fails closed;
18. complete topology dependency seam validated;
19. ProductionAccessQuery exact board-coherence query exists;
20. same-size different-board mismatch fails closed;
21. no mutable board reference leak;
22. blocked-interior NO_ROUTE preserved;
23. opened-after-clear same target preserved;
24. deterministic points preserved;
25. no BoardState mutation;
26. no ReservationState mutation;
27. no retarget;
28. owner Organized/curved decision preserved;
29. conservative production shaping preserved;
30. 59×59 passes;
31. 53×59 passes;
32. ADR/current-law docs updated;
33. no M18+ leakage from this correction;
34. full Godot suite passes;
35. git diff --check clean;
36. governance untouched;
37. matching CLAUDE_LOG_V02 exists;
38. Claude does not self-audit;
39. ChatGPT discloses runtime rerun availability.

If all pass, re-close SB-M17-002, 003, 015, 016.
