# M15-C001 — ChatGPT Audit Criteria V01

Canonical audit policy:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/README.md

AUDITED_PASS requires all applicable criteria below.

## Evidence discipline
1. Exact CHATGPT_PROMPT_V01 -> CLAUDE_LOG_V01 match exists.
2. Claude aggregate green total is not treated as sole proof.
3. Audit inspects actual implementation diff/source/tests.
4. Relevant AL-XXX learnings are applied, especially AL-009, AL-011, AL-018, AL-020, AL-028.
5. Any checks not independently rerun by ChatGPT are explicitly disclosed.

## Architecture
6. TargetSelector exists under gameplay/targeting.
7. Uses explicit preload conventions.
8. BoardState access is narrow final-validation only.
9. ColorCandidateIndex remains raw candidate owner.
10. ReservationState remains reservation owner.
11. TargetSelector consumes injected reachability/access truth.
12. Missing access truth fails closed.
13. TargetSelector contains no route generation/pathfinding.
14. M16 RoutingSystem is not implemented.

## Selection correctness
15. Deterministic ascending candidate strategy.
16. Requested color must match.
17. Invalid candidate rejected.
18. CLEARED candidate rejected even under stale/injected candidate conditions.
19. Reserved candidate excluded/skipped.
20. Blocked/unreachable ACTIVE candidate rejected via access query.
21. Fully enclosed matching-color regression yields no target when access truth says blocked.
22. First blocked + later reachable candidate selects the later one.
23. All blocked returns -1.
24. No candidates returns -1.
25. Invalid owner/color/unbound returns -1.

## Atomic assignment
26. Successful selection creates ReservationState ownership before returning.
27. Owner already holding a target gets no second assignment.
28. Primary API avoids choose-then-reserve race gap.
29. Competing owners for one target produce exactly one success under synchronous call model.
30. With multiple candidates, successful target ownership remains unique.
31. If first reserve attempt loses, an unassigned owner can continue to next valid candidate.
32. Selector never directly mutates ReservationState internals.

## Non-mutation / observability
33. BoardState is not mutated by selection.
34. ColorCandidateIndex internal truth is not mutated by selection.
35. Access-query test double directly observes queried indices.
36. Negative tests isolate their intended failure modes.
37. No mutable internal TargetSelector collection leaks if any state is owned.

## Performance
38. Rectangular-board coverage exists.
39. 59×59 / 3481-cell benchmark exists.
40. Steady-state selection iterates requested color candidates, not the whole board.
41. No GPU/FPS claim is made from headless CPU timing.

## Locked-contract preservation
42. Board max remains 59×59.
43. ACTIVE/CLEARED remains unchanged.
44. ReservationState ADR-022 remains intact.
45. C01..C16 / C16 #000000 / BG01 #202533 remain intact.
46. Five-slot contract unchanged.
47. raw candidate != reachable final target preserved.
48. TargetSelector != RoutingSystem preserved.

## Scope/governance
49. M16+ implementation untouched.
50. tasks.md untouched by Claude.
51. H!veAI tracker/dashboard files untouched by Claude.
52. SESSION_INDEX untouched by Claude.
53. AUDIT_INDEX untouched by Claude.
54. matching CLAUDE_LOG_V01 contains real implementation/test/push evidence.
55. Claude does not self-audit.

## Task closure eligibility

If all criteria pass, ChatGPT may close:
- SB-M15-001
- SB-M15-002
- SB-M15-003
- SB-M15-004
- SB-M15-005
- SB-M15-006
- SB-M15-007
- SB-M15-008
- SB-M15-009
- SB-M15-010
- SB-M15-011
- SB-M15-012

Expected progress after all 12 closures:
- ecosystem: 236 / 943 = 25.03%
- main game + SB-UI: 236 / 719 = 32.82%
