# M18-C001 — ChatGPT Audit Criteria V01

AUDITED_PASS requires:

1. Lightweight ScrubbotAgent exists.
2. Assigned color is stored.
3. Assigned target is stored.
4. Assigned valid RouteResult/points are stored safely.
5. Spawn origin is stored.
6. Agent consumes route only; no target selection.
7. Agent does not compute routing.
8. Movement uses board-local route coordinates.
9. Small delta progression correct.
10. Large delta traverses multiple segments correctly.
11. Zero delta stable.
12. Exact endpoint arrival.
13. Arrival/completion emitted exactly once.
14. Completion carries correct identity.
15. No BoardState mutation.
16. No ReservationState mutation.
17. No return-to-slot behavior.
18. No resource-carry state/API.
19. Reset/cancel stops movement.
20. Cancel prevents delayed completion.
21. Repeated cancel safe.
22. No orphan nodes after cancel/free.
23. No orphan nodes after completion/free.
24. 5-agent test.
25. 10-agent test.
26. 25-agent test.
27. stress >25.
28. Deterministic repeated movement.
29. 59×59 route compatibility.
30. Rectangular Very Hard compatibility.
31. Pooling added only if profiling justifies it; otherwise explicitly deferred.
32. Production routing ADR-025 remains intact.
33. No M19 Dispatcher implementation.
34. No M20 vertical-slice implementation.
35. tasks.md untouched by Claude.
36. H!veAI / SESSION_INDEX / AUDIT_INDEX untouched.
37. Matching Claude log contains actual evidence.
38. Claude does not self-audit.
39. Godot rerun limitation explicitly disclosed by ChatGPT if not independently rerun.

If all pass, ChatGPT may close SB-M18-001..015.

Expected progress:
- overall 278 / 943 = 29.48%
- main game + SB-UI 278 / 719 = 38.66%
