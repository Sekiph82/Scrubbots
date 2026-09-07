# M17-C002 — Frozen Strict Audit Criteria V03

Final strict closure requires the full matrix below.

## ProductionAccessQuery
1. exact BoardState ownership only;
2. is_bound_to exact identity;
3. invalid/unbound board never throws;
4. invalid target index fails segment access;
5. NaN from endpoint false;
6. INF from/to endpoint false;
7. non-finite cell_of_point safe sentinel;
8. no mutable board reference leak.

## Exact segment truth
9. no SAMPLE_STEP correctness sampling;
10. deterministic exact/supercover traversal;
11. short-chord blocker (7,7) rejected;
12. cleared short-chord accepted when otherwise open;
13. diagonal corner cutting rejected;
14. axis-aligned CLEARED corridor accepted;
15. outside space accepted;
16. final target-center entry accepted;
17. target transit/non-final usage rejected.

## Exterior reachability
18. no correctness-affecting MAX_ENTRIES cap;
19. >12-entry later-only valid entry found;
20. same target retained;
21. direct outside-to-perimeter target succeeds;
22. perimeter target not treated as ordinary transit.

## ProductionRoutingSystem boundary
23. null request safe;
24. scalar request safe;
25. junk request safe;
26. malformed request target -1;
27. scalar access safe;
28. missing seam method safe;
29. same-size different-board access rejected;
30. classify_cell return type/value validated;
31. cell_of_point return type validated;
32. is_segment_traversable return is actual bool.

## Planner edge truth
33. every enqueued/used neighbour edge obeys segment access;
34. blocked-edge sensitivity double directly exercised;
35. alternate route chosen when one exists;
36. NO_ROUTE when blocked edge is the only connection.

## Self-validation/fallback
37. raw backbone route validated;
38. shaping candidate whole-route validated;
39. last-known-valid fallback retained;
40. invalid shortcut cannot escape;
41. invalid rounded route cannot escape;
42. final success internally passes shared RouteValidator;
43. no success returned when validator would reject.

## Tuning robustness
44. NaN corner_radius safe;
45. +INF corner_radius safe;
46. -INF corner_radius safe;
47. negative corner_radius safe;
48. zero/negative corner_samples safe;
49. zero/negative max_shortcut_span safe;
50. no non-finite success points;
51. valid owner defaults unchanged.

## Canonical regression
52. blocked interior -> NO_ROUTE;
53. opened-after-clear -> same target success;
54. no retarget;
55. no BoardState mutation;
56. no ReservationState mutation;
57. no target-selection API;
58. deterministic repeated points;
59. 59x59 coverage;
60. 53x59 coverage;
61. Organized/curved owner decision preserved;
62. Direct remains debug-only;
63. prototypes/lab retained;
64. ADR-025/current-law updated;
65. no M18/M19/M20 feature leakage.

## Validation/governance
66. full Godot 4.7.1 suite passes;
67. git diff --check clean;
68. governance untouched;
69. matching CLAUDE_LOG_V03 exists;
70. Claude does not self-audit;
71. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close the reopened M17 production-routing tasks.
