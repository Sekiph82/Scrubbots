# M16-C001 — ChatGPT Audit Criteria V01

Canonical policy:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/README.md

AUDITED_PASS requires all applicable criteria.

## Evidence discipline
1. Exact V01 prompt -> V01 Claude log exists.
2. Claude aggregate green count is not accepted as sole proof.
3. Actual implementation diff/source/tests are independently inspected.
4. Relevant AL learnings are applied.
5. Any test not independently rerun by ChatGPT is explicitly disclosed.

## Contract / coordinate space
6. RoutingSystem contract exists independently from TargetSelector.
7. RouteRequest exists or equivalent narrow input contract exists.
8. RouteResult exists or equivalent output contract exists.
9. Coordinate space is board-local cell units, not screen pixels.
10. One logical cell equals 1×1 coordinate units.
11. Target destination is canonical target-cell center.
12. Slot origin is caller supplied and may lie outside board bounds.
13. 1080×2160/UI pixels are not embedded into route data.
14. BoardState index/position APIs are used rather than re-deriving index math.

## Target ownership / separation
15. Request identifies exactly one already-assigned target.
16. RoutingSystem never chooses another target.
17. RoutingSystem does not call TargetSelector for fallback.
18. RoutingSystem does not mutate ReservationState ownership.
19. RoutingSystem does not mutate BoardState.
20. No route never silently retargets.

## Route output / failure
21. Success result includes target + >=2 route points.
22. First point equals slot origin.
23. Last point equals assigned target center.
24. Failure result has empty route points.
25. Failure reason is explicit/stable enough to test.
26. Failure retains original target identity.
27. Returned point collections are detached.

## Access / validity seam
28. Route validity consumes injected access truth.
29. Missing access truth fails closed.
30. Exact M17 topology/path algorithm is not implemented.
31. Every segment is directly checked through access truth.
32. Direct segment-query observability exists in tests.
33. Blocked segment invalidates route.
34. Open/CLEARED/background/outside segment may validate when access truth says open.
35. Assigned ACTIVE target is permitted only as final endpoint under supplied access truth.
36. Wrong result target invalidates route.
37. Wrong start point invalidates route.
38. Wrong destination invalidates route.

## Swappability
39. At least two fake/test routing implementations satisfy the same contract.
40. Swapping routing implementation requires no TargetSelector source change.
41. No global singleton coupling is introduced.

## Debug visualization
42. Generic debug visualization consumes RouteResult only.
43. Success route polyline/start/end state can be represented.
44. Failure/no-route state can be represented.
45. Debug visualizer does not compute or alter a route.
46. Debug visualization is debug-only, not production gameplay UI.
47. Runtime/headless smoke exists if scene-based debug tooling is added.

## Coverage / locked rules
48. left/right/above-or-below slot-origin tests exist.
49. rectangular-board coordinate test exists.
50. 59×59 coordinate test exists.
51. rectangular Very Hard-sized coordinate test exists.
52. ACTIVE/CLEARED unchanged.
53. 59×59 max unchanged.
54. C01..C16/C16/BG01 unchanged.
55. five-slot contract unchanged.
56. ADR-022 and ADR-023 remain intact.
57. TargetSelector != RoutingSystem remains intact.

## No M17 leakage
58. No production AStar/AStarGrid2D.
59. No BFS/DFS routing implementation.
60. No production direct/curved/grid-aware routing prototype.
61. No collision-radius/congestion/path-crossing optimization.
62. No final movement-language choice.

## Governance
63. tasks.md untouched by Claude.
64. H!veAI files untouched by Claude.
65. SESSION_INDEX untouched by Claude.
66. AUDIT_INDEX untouched by Claude.
67. matching CLAUDE_LOG_V01 contains real evidence.
68. Claude does not self-audit.

## Task closure eligibility

If all criteria pass, ChatGPT may close:
- SB-M16-001
- SB-M16-002
- SB-M16-003
- SB-M16-004
- SB-M16-005
- SB-M16-006
- SB-M16-007
- SB-M16-008
- SB-M16-009
- SB-M16-010
- SB-M16-011

Expected progress after all 11 closures:
- overall: 247 / 943 = 26.19%
- main game + SB-UI: 247 / 719 = 34.35%
