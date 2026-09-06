# M16-C001 — ChatGPT Independent Audit V01

Decision: **AUDITED_PASS**

Canonical audit policy:
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/README.md`

Audited against:
- `coordination/sessions/M16-C001/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- `coordination/sessions/M16-C001/CLAUDE_LOG_V01.md`
- implementation base `1c6d9c9cb2a02df17690a139ecaf2da4de297200`
- implementation commit `aeb050f90b3c6b7cd9b9356234cb3bd00d49a66b`
- actual implementation diff/source/tests/docs

## Evidence levels

### E0 — not sufficient by itself
Not accepted alone:
- Claude saying M16 is complete;
- file existence;
- the aggregate `1266/1266 ALL PASS` claim;
- prose claims about swappability/no-retarget.

### E1/E2 — Claude implementer evidence
The matching log records:
- Godot `4.7.1.stable.official.a13da4feb`;
- full suite `1266/1266 ALL PASS`;
- `git diff --check`;
- route input/output contract evidence;
- coordinate-space checks;
- route-access query trace checks;
- swappability tests;
- no-retarget tests;
- debug-overlay runtime instantiation;
- 59×59 and 53×59 coverage;
- safe sync / owner-work preservation;
- M17+ non-scope confirmation.

These remain implementer evidence, not independent audit proof alone.

### E3 — ChatGPT independent evidence
Independently inspected:
- exact V01 prompt/criteria/log match;
- actual commit diff;
- all new M16 routing source files;
- debug overlay source;
- access-query double and both fake routing implementations;
- actual M16 test bodies in `tests/run_tests.gd`;
- ADR-024 / gameplay / architecture docs;
- unchanged TargetSelector/ReservationState architectural ownership;
- changed-file scope;
- false-positive risk in negative/observability tests.

The ChatGPT audit environment does **not** provide a Godot executable, so the
Godot suite was **not independently rerun** here. The `1266/1266` result is
therefore E2 evidence. The source/test implementation was independently
cross-checked per AUDIT_POLICY.

### E4 — owner approval
No owner-controlled subjective design gate is required for M16. The debug
visualizer is diagnostic only. Final routing/movement language remains the M17
owner design gate.

---

## Relevant AUDIT_INDEX learnings applied

- **AL-001** explicit preload convention preserved.
- **AL-003** no FPS/GPU inference from headless checks.
- **AL-004** rectangular and max-size coordinate coverage inspected.
- **AL-005** task completion based on direct contract/test evidence, not file existence.
- **AL-009** aggregate green count not used as sole proof.
- **AL-011** negative cases inspected for specificity.
- **AL-018** route segment access truth is directly observable through query logs.
- **AL-020** route points use detached copy-in/copy-out semantics.
- **AL-026** owner/local `project.godot` work stayed outside the implementation diff.
- **AL-027** ACTIVE/CLEARED lifecycle preserved.
- **AL-028** RoutingSystem receives an already-selected target and never silently retargets.
- **AL-033** current palette v2 contract remains untouched.

---

# Requirement-level findings

## Evidence discipline

1. **Exact V01 prompt -> V01 Claude log — PASS**
2. **Aggregate green count not sole proof — PASS**
3. **Actual diff/source/tests independently inspected — PASS**
4. **Relevant AL learnings applied — PASS**
5. **Independent rerun limitation disclosed — PASS**

## Contract / coordinate space

6. **Independent RoutingSystem contract — PASS**
   `routing_system.gd` is separate from TargetSelector and exposes
   `compute_route(request, board, access_query)`.

7. **RouteRequest contract — PASS**

8. **RouteResult contract — PASS**

9. **Board-local cell coordinate space — PASS**
   Route data uses logical cell units, not screen/global Canvas coordinates.

10. **One logical cell = 1×1 units — PASS**
    Direct adjacent-center test observes a 1.0-unit delta.

11. **Target destination = canonical cell center — PASS**
    `RouteRequest.center_of_index()` delegates index→position truth to
    BoardState then adds the half-cell center offset.

12. **Caller-supplied external slot origin — PASS**
    Left/right/above/below origins are preserved.

13. **No 1080×2160 embedded in route data — PASS**

14. **No row-major math re-derived outside BoardState — PASS**
    RouteRequest calls `BoardState.get_cell_position()`.

## Target ownership / separation

15. **Exactly one assigned target in request — PASS**
    No candidate/alternate-target collection or selection callback exists.

16. **RoutingSystem never chooses another target — PASS**

17. **No TargetSelector fallback — PASS**
    Routing source contains no TargetSelector dependency/call.

18. **Reservation ownership not mutated — PASS**
    Routing modules hold no ReservationState dependency; test verifies a live
    reservation remains unchanged.

19. **BoardState not mutated — PASS**
    Source performs no mutation; state snapshots verify base/fake calls leave it unchanged.

20. **No route never silently retargets — PASS**
    Failure retains the original target index and empty points.

## Route output / failure

21. **Success result structure — PASS**
    RouteValidator requires >=2 points for a claimed success route.

22. **First point = slot origin — PASS**

23. **Last point = assigned target center — PASS**

24. **Failure route points empty — PASS**

25. **Stable explicit failure reason — PASS**
    StringName constants include INVALID_REQUEST, INVALID_TARGET,
    TARGET_NOT_ACTIVE, MISSING_ACCESS_QUERY, NO_ROUTE, INVALID_ROUTE and
    NOT_IMPLEMENTED.

26. **Failure retains original target identity — PASS**

27. **Detached point collections — PASS**
    Copy-in and copy-out mutation tests directly verify no alias leak.

## Access / validity seam

28. **Injected access truth — PASS**
    `RouteValidator.validate_route()` consumes
    `is_segment_traversable(from,to,target_index)`.

29. **Missing access truth fails closed — PASS**

30. **M17 topology not implemented — PASS**
    No production path algorithm appears in the diff.

31. **Every claimed route segment checked — PASS**
    Validator loops over every consecutive point pair.

32. **Direct segment-query observability — PASS**
    Query log records from/to/target/verdict and tests assert sequence/count.

33. **Blocked segment invalidates route — PASS**

34. **Open segment accepted via access truth — PASS**

35. **Assigned ACTIVE target endpoint semantic preserved — PASS**
    Request validation requires target ACTIVE, endpoint must equal that target
    center, and final segment still requires supplied access approval.

36. **Wrong target result invalid — PASS**

37. **Wrong start invalid — PASS**

38. **Wrong destination invalid — PASS**

### Audit nuance
`RouteRequest.for_target()` itself accepts any valid index even if the cell is
CLEARED; the canonical request validation step then rejects it as
`TARGET_NOT_ACTIVE`. This still satisfies the prompt's “derivable/validated
from BoardState” contract because the active-state requirement is enforced by
the reusable validator before a route can be accepted. No M16 correction is
required for this split.

## Swappability

39. **Two fake routing implementations share the same contract — PASS**
    Straight and relay fakes both implement `compute_route()` and produce
    results validated by the same RouteValidator.

40. **No TargetSelector modification needed to swap routing — PASS**
    TargetSelector is absent from the implementation diff and exposes no
    routing method.

41. **No global singleton coupling — PASS**

## Debug visualization

42. **Consumes RouteResult only — PASS**

43. **Polyline/start/end represented — PASS**

44. **Failure/no-route represented — PASS**

45. **Visualizer does not compute/alter route — PASS**

46. **Debug-only — PASS**
    File lives under `scripts/debug/`; it is not wired into production UI.

47. **Runtime smoke — PASS as E2 + source cross-check**
    No .tscn was added. Test instantiates the Node2D under SceneTree, feeds
    success/failure results and frees it. Claude reports this inside the passing suite.

## Coverage / locked rules

48. **Left/right/above/below origins — PASS**
49. **Rectangular coordinate coverage — PASS**
50. **59×59 coverage — PASS**
51. **Rectangular Very Hard 53×59 coverage — PASS**
52. **ACTIVE/CLEARED unchanged — PASS**
53. **59×59 maximum unchanged — PASS**
54. **C01..C16 / C16 / BG01 unchanged — PASS**
55. **Five-slot contract unchanged — PASS**
56. **ADR-022 / ADR-023 intact — PASS**
57. **TargetSelector != RoutingSystem preserved — PASS**

## No M17 leakage

58. **No production AStar/AStarGrid2D — PASS**
59. **No BFS/DFS — PASS**
60. **No production direct/curved/grid-aware routing prototype — PASS**
    The straight/relay route producers are confined to `tests/support/`.
61. **No collision/congestion/crossing optimization — PASS**
62. **No final movement-language choice — PASS**

## Governance

63. **tasks.md untouched by Claude — PASS**
64. **H!veAI files untouched by Claude — PASS**
65. **SESSION_INDEX untouched by Claude — PASS**
66. **AUDIT_INDEX untouched by Claude — PASS**
67. **Matching Claude log contains real evidence — PASS**
68. **No Claude self-audit — PASS**

---

# Final verdict

**AUDITED_PASS**

No M16 defect requiring a V02 correction prompt was found.

Eligible closures:
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

Next milestone after canonical ledger closure: **M17 Routing Prototype Lab**.
M17 contains the movement-language design gate and remains NOT_STARTED until
intentionally opened.
