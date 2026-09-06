# M17-C002 — ChatGPT Audit Criteria V01

AUDITED_PASS requires:

1. Exact owner decision is implemented: Organized/curved production language + Grid-aware deterministic backbone.
2. Production routing code exists outside experimental `prototypes/`.
3. Direct is not promoted to production.
4. M16 RoutingSystem/RouteRequest/RouteResult contract remains intact.
5. Target identity never changes.
6. No silent retarget.
7. No BoardState mutation.
8. No ReservationState ownership mutation.
9. Production route is derived from valid grid-aware reachability/path truth.
10. Every final segment is validated through shared access truth/RouteValidator.
11. Blocked interior target returns no route.
12. Newly-opened-after-clear routes the same target.
13. Determinism tests pass.
14. Invalid diagonal/shortcut never gets accepted.
15. Production shortcut/rounding defaults are demonstrably more conservative than M17 experimental defaults.
16. 59×59 coverage exists.
17. Rectangular Very Hard coverage exists.
18. M17 lab/prototypes/comparison remain available.
19. Current-law docs updated.
20. New ADR records owner-selected production movement language.
21. No M18+ implementation leakage.
22. tasks.md untouched by Claude.
23. H!veAI / SESSION_INDEX / AUDIT_INDEX untouched by Claude.
24. Matching CLAUDE_LOG_V01 contains actual implementation/test/push evidence.
25. Claude does not self-audit.
26. Any Godot tests not independently rerun by ChatGPT are explicitly disclosed in audit.
