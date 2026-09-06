# M17-C002 — ChatGPT Independent Audit V01

Decision: **AUDITED_PASS**

Policy basis:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/README.md

Audited against:
- coordination/sessions/M17-C002/CHATGPT_PROMPT_V01.md
- coordination/sessions/M17-C002/CHATGPT_AUDIT_CRITERIA_V01.md
- coordination/sessions/M17-C002/CLAUDE_LOG_V01.md
- coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md
- implementation base 72ea92f1cbaa01c28ea626dea92fc0b59bca7f4b
- implementation commit 25c71bfa7d077df6a03ee2bab6e0083b4ac92ae8
- actual diff/source/tests/docs

## Evidence classification

### E1/E2 implementer evidence
Claude reports:
- Godot 4.7.1
- full suite 1412/1412 ALL PASS
- git diff --check clean
- 28 production-routing checks
- 59×59 and 53×59 coverage
- blocked/opened-after-clear regressions
- conservative-production-vs-experimental comparison

### E3 independent evidence
ChatGPT independently inspected:
- exact V01 prompt/log/criteria match
- actual commit diff
- production_access_query.gd
- production_routing_system.gd
- M17-C002 test bodies
- ADR-025
- gameplay-spec current-law changes
- M17 lab/prototype retention
- no M18+ leakage
- governance diff

The audit environment does not provide a Godot executable, so 1412/1412 was
not independently rerun by ChatGPT. It remains E2 implementer evidence. Source,
test quality and requirement mapping were independently cross-checked.

## Findings

1. **Owner decision implemented — PASS**
   Organized/curved is the production movement language; deterministic grid-aware
   BFS is the planner backbone.

2. **Production scope — PASS**
   New production code lives outside `prototypes/`.

3. **Direct not promoted — PASS**
   Direct remains only in experimental/debug prototype tooling.

4. **M16 contract preserved — PASS**
   ProductionRoutingSystem subclasses RoutingSystem and keeps the same request/result contract.

5. **No retarget / target identity fixed — PASS**

6. **No BoardState mutation — PASS**

7. **No ReservationState mutation — PASS**

8. **Grid-derived reachability/path truth — PASS**
   Production routing first computes deterministic grid-aware reachability/path.

9. **Final segment validation — PASS**
   Shortcut/rounding segments are checked through access truth; shared RouteValidator
   is also used in direct tests.

10. **Blocked interior -> NO_ROUTE — PASS**

11. **Opened-after-clear -> same target routes — PASS**

12. **Determinism — PASS**

13. **Invalid shortcut rejection — PASS**

14. **More conservative production defaults — PASS**
   - max_shortcut_span = 2
   - corner_radius = 0.25
   versus experimental unbounded shortcut / radius 0.35.
   Tests also compare point count, distance and max segment length on 59×59.

15. **59×59 coverage — PASS**

16. **Rectangular Very Hard 53×59 coverage — PASS**

17. **M17 lab/prototypes/comparison retained — PASS**

18. **Current-law docs updated — PASS**

19. **ADR-025 added — PASS**

20. **No M18+ implementation leakage — PASS**

21. **tasks.md untouched by Claude — PASS**

22. **H!veAI / SESSION_INDEX / AUDIT_INDEX untouched — PASS**

23. **No Claude self-audit — PASS**

## Audit nuance

Production access truth still uses sampled segment checking at 0.1 cell units,
inherited from the M17 lab model. This is now explicitly promoted as production
truth by ADR-025. No failing case was found in the inspected M17-C002 regressions,
but this remains an implementation characteristic to profile/revisit only if later
movement or collision QA exposes an edge case.

## Final verdict

**AUDITED_PASS**

M17-C002 is complete.

M18 — Scrubbot Agent may now open.
