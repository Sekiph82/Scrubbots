# M17-C001 — ChatGPT Independent Audit V01

Decision: **AUDITED_PASS / OWNER_DESIGN_GATE_OPEN**

Canonical audit policy:
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/README.md`

Audited against:
- `coordination/sessions/M17-C001/CHATGPT_PROMPT_V01.md`
- `coordination/sessions/M17-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- `coordination/sessions/M17-C001/CLAUDE_LOG_V01.md`
- `coordination/sessions/M17-C001/ROUTING_COMPARISON_V01.md`
- implementation base `b815b35438f140b5d2d5f87ca28188b632c5efdd`
- implementation commit `ca9124a11522bec53d9fbe8ca313f80dd8f99998`
- actual implementation diff/source/tests/debug scene

## Evidence levels

### E0
Not accepted alone:
- Claude's completion claims;
- file existence;
- aggregate `1384/1384 ALL PASS`;
- comparison-table prose by itself.

### E1/E2
Matching Claude evidence includes:
- Godot 4.7.1;
- `1384/1384 ALL PASS`;
- `git diff --check`;
- direct/grid/organized prototype results;
- blocked-interior and newly-opened-after-clear regressions;
- 5/10/25/50-route comparisons;
- 59×59 and 53×59 comparisons;
- route-distance/crossing/congestion/CPU/determinism tables;
- debug-lab scene smoke;
- explicit missing-original-reference declaration.

### E3
ChatGPT independently inspected:
- exact V01 prompt/criteria/log match;
- actual commit diff;
- Direct/Grid/Organized prototype source;
- experimental access truth;
- route metrics;
- Routing Prototype Lab source/scene;
- actual M17 test bodies;
- comparison artifact definitions and tables;
- no-production-promotion / no-M18+ scope;
- governance diff.

The audit environment does not provide a Godot executable, so `1384/1384`
was not independently rerun. It remains E2 implementer evidence. Source/test
quality and the properties asserted were independently cross-checked.

### E4
The final movement language requires explicit OWNER approval. That gate is
**still open**.

---

## ROUTING_COMPARISON_V01.md assessment

The comparison file is **legitimate and expected**.

The M17 prompt explicitly allowed an optional
`ROUTING_COMPARISON_V01.md` artifact so neutral measurements, limitations and
owner-review instructions could be kept separate from the implementation log.

It is not a second implementation log and it does not self-audit.

Its purpose is to:
- keep Direct/Grid/Organized metrics in one comparable table;
- state exact metric definitions;
- record known experimental limitations;
- avoid hiding trade-offs inside a long Claude log;
- provide the owner a concrete review checklist.

The file correctly declares **no winner** and keeps
`OWNER_DESIGN_GATE OPEN`.

---

# Requirement-level findings

## Prototype architecture

1. **Direct prototype — PASS**
2. **Grid-aware prototype — PASS**
3. **Organized/curved prototype — PASS**
4. **All remain experimental — PASS**
5. **M16 base contract unchanged — PASS**
6. **Successful routes are checked against shared RouteValidator in tests/lab — PASS**
7. **Original target identity retained — PASS**
8. **No TargetSelector retargeting — PASS**
9. **No ReservationState ownership mutation — PASS**
10. **No routing-time BoardState mutation — PASS**

## Direct baseline

11. **Open straight route succeeds — PASS**
12. **Blocked straight route returns NO_ROUTE — PASS**
13. **Direct never detours — PASS**

## Grid-aware

14. **Experimental topology documented — PASS**
    Deterministic 4-neighbour BFS with explicit exterior bridge.

15. **Deterministic tie/order behavior — PASS**

16. **Outside slot origin handled explicitly — PASS**

17. **ACTIVE blocker / CLEARED open / target endpoint semantics — PASS**

18. **Fully enclosed target -> NO_ROUTE — PASS**

19. **Newly-opened-after-clear -> SAME target routable — PASS**

20. **No silent retarget — PASS**

### Audit nuance
The exterior model uses a nearest-first capped `MAX_ENTRIES=12` perimeter
bridge. This can produce a prototype NO_ROUTE even when another farther exterior
entry might theoretically work. The implementation and comparison file clearly
label this as an **experimental limitation**, not canonical gameplay truth.
That is acceptable for M17 prototype research but must not silently become the
final production access model without owner selection/follow-up validation.

## Organized/curved

21. **Derived from grid-aware source route — PASS**
22. **Deterministic simplification/rounding — PASS**
23. **Blocked shortcuts/segments rejected — PASS**
24. **Fallback behavior exists — PASS**
25. **No final curvature parameter promoted to production law — PASS**

## Metrics / comparison

26. **Distance metric — PASS**
27. **Proper-crossing metric — PASS**
28. **Shared endpoint policy explicit — PASS**
29. **Congestion/overlap proxy explicit — PASS**
30. **CPU reporting is CPU-only — PASS**
31. **Determinism metric — PASS**
32. **Success/no-route reported separately — PASS**
33. **5 routes — PASS**
34. **10 routes — PASS**
35. **25 routes — PASS**
36. **Stress >25 (50) — PASS**
37. **59×59 — PASS**
38. **Rectangular Very Hard 53×59 — PASS**

Comparison-table values were not independently rerun, but the metric code,
scenario harness and test coverage supporting those tables were independently
inspected.

## Visual lab

39. **Debug lab scene exists — PASS**
40. **Strategy switch Direct/Grid/Organized — PASS**
41. **Scenario selector S1..S8 — PASS**
42. **Bot-count selector — PASS**
43. **Route visibility / organized-rounding / S4-clear controls — PASS**
44. **Metric/status panel — PASS**
45. **No target-selection API in lab — PASS**
46. **No production gameplay wiring — PASS**
47. **Headless scene smoke reported and test source inspected — PASS**

## Original SCRUBBOTS direction

48. **No unsupported reference claim — PASS**
49. **Missing movement reference explicitly declared — PASS**
50. **Generic external-game assumption not substituted — PASS**

However:

**SB-M17-010 is NOT complete.**

The comparison against an authoritative original SCRUBBOTS movement reference
could not be performed because no such authoritative reference was found.
This task must remain open until the owner identifies/provides one, or explicitly
decides that the new owner-reviewed movement language supersedes that comparison.

## Owner design gate

51. **Claude declared no winner — PASS**
52. **No final algorithm ADR — PASS**
53. **No prototype promoted to production — PASS**
54. **OWNER_DESIGN_GATE remains OPEN — REQUIRED**

M18 must not be opened yet.

## No M18+ leakage

55. **No ScrubbotAgent — PASS**
56. **No movement playback — PASS**
57. **No Dispatcher/spawn orchestration — PASS**
58. **No vertical slice — PASS**
59. **No route-completion cell clearing — PASS**

## Governance

60. **tasks.md untouched by Claude — PASS**
61. **H!veAI files untouched — PASS**
62. **SESSION_INDEX untouched — PASS**
63. **AUDIT_INDEX untouched — PASS**
64. **matching Claude log exists — PASS**
65. **no Claude self-audit — PASS**

---

# Task closure decision

Close objective/comparison tasks:
- SB-M17-001
- SB-M17-002
- SB-M17-003
- SB-M17-004
- SB-M17-005
- SB-M17-006
- SB-M17-007
- SB-M17-008
- SB-M17-009
- SB-M17-011
- SB-M17-012
- SB-M17-013
- SB-M17-014
- SB-M17-015
- SB-M17-016

Keep open:
- **SB-M17-010 Compare against original SCRUBBOTS visual direction**

Milestone state:
**TECHNICALLY_AUDITED / OWNER_DESIGN_GATE_OPEN**

Next actor:
**OWNER**, not Claude implementation.

The owner should inspect:
`scenes/debug/routing_prototype_lab.tscn`

and select the preferred movement language:
- Direct
- Grid-aware
- Organized/curved
- or request a hybrid/revision.

Do not open M18 until this owner decision is recorded.
