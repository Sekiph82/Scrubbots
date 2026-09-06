# M17-C001 — ChatGPT Audit Criteria V01

Canonical audit policy:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/README.md

M17 V01 is a prototype/comparison cycle. An implementation can be technically
AUDITED_PASS while the separate OWNER movement-language design gate remains open.

## Evidence discipline
1. Exact V01 prompt -> matching Claude V01 log.
2. Aggregate test count not accepted alone.
3. Actual diff/source/tests/debug tooling independently inspected.
4. Relevant AL learnings applied.
5. Any tests not independently rerun by ChatGPT explicitly disclosed.

## Prototype architecture
6. Direct prototype exists behind M16 contract.
7. Grid-aware prototype exists behind M16 contract.
8. Organized/polyline/curved prototype exists behind M16 contract.
9. Prototypes remain experimental and are not wired as production routing.
10. M16 base contract remains intact.
11. All successful prototype routes pass shared RouteValidator.
12. All prototypes preserve original target identity.
13. No prototype calls TargetSelector to retarget.
14. No prototype mutates ReservationState ownership.
15. No prototype mutates BoardState except explicit test setup outside routing.

## Direct baseline
16. Open straight segment can succeed.
17. Blocked straight segment fails explicitly.
18. Direct prototype never detours on its own.

## Grid-aware
19. Experimental topology is explicitly documented.
20. Topology is deterministic.
21. Caller slot origin outside board is handled explicitly.
22. Non-target ACTIVE blockers represented.
23. CLEARED/open space represented.
24. Assigned ACTIVE target allowed only as final endpoint.
25. Fully enclosed target returns no route.
26. Newly-opened-after-clear case routes to the SAME target.
27. No silent retarget.

## Organized/polyline/curved
28. Built as a deterministic experimental movement-language candidate.
29. Produces a valid route from a valid source path/scenario.
30. Simplification/rounding never accepts a segment rejected by access truth.
31. Invalid simplification falls back or fails safely.
32. Repeated identical state/config produces identical points.

## Metrics
33. Route-distance metric definition/test correct.
34. Crossing metric definition/test correct.
35. Shared-endpoint crossing policy explicitly defined.
36. Congestion/overlap metric explicitly defined/tested.
37. CPU timing harness reports CPU only, no FPS/GPU claim.
38. Determinism comparison exists.
39. Successful/failed route counts are reported separately.

## Comparison scale
40. 5-route comparison exists.
41. 10-route comparison exists.
42. 25-route comparison exists.
43. Stress comparison >25 exists.
44. 59×59 scenario exists.
45. Legal rectangular Very Hard scenario exists.
46. Blocked-interior scenario exists.
47. Newly-opened-after-clear scenario exists.

## Visual lab
48. Debug Routing Prototype Lab exists.
49. Owner can switch between all three strategies without editing source.
50. Owner can select/inspect required scenarios.
51. Owner can inspect bot-count variants.
52. Metrics/state are visible or directly inspectable.
53. Debug lab does not perform target selection.
54. Debug lab does not mutate production gameplay.
55. Headless/runtime smoke passes if a scene is added.

## Original visual direction
56. SB-M17-010 comparison uses an actual authoritative owner/reference source.
57. If no authoritative movement reference exists, Claude explicitly reports
    BLOCKED_BY_MISSING_OWNER_REFERENCE rather than inventing evidence.
58. No generic external game assumption is substituted for missing owner evidence.

## Owner design gate
59. Claude does not declare a production winner.
60. No final movement-language ADR is written before owner selection.
61. No prototype is promoted to production.
62. Audit clearly states whether OWNER_DESIGN_GATE remains open.

## No M18+ leakage
63. No ScrubbotAgent implementation.
64. No movement/animation playback.
65. No Dispatcher/spawn/slot orchestration.
66. No vertical-slice wiring.
67. No route-completion cell clearing.

## Governance
68. tasks.md untouched by Claude.
69. H!veAI files untouched by Claude.
70. SESSION_INDEX untouched by Claude.
71. AUDIT_INDEX untouched by Claude.
72. Matching Claude log has real implementation/test/push evidence.
73. Claude does not self-audit.

## Task closure policy

After technical audit:
- Objective implementation/test tasks may close if directly proven.
- SB-M17-004 visual clarity and SB-M17-010 original-direction comparison must
  not be treated as owner preference decisions.
- The milestone's explicit **OWNER DESIGN GATE remains open until the owner
  selects the final movement language**.

If all SB-M17-001..016 have objective evidence, their checkboxes may close while
the milestone remains in OWNER_DESIGN_GATE state.

Maximum checkbox progress if all 16 task IDs close:
- overall: 263 / 943 = 27.89%
- main game + SB-UI: 263 / 719 = 36.58%

Do not open M18 until the owner movement-language gate is resolved.
