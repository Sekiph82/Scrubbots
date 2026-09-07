# M18-C001 — Strict Audit Criteria V02

Strict-v2 final closure requires all of the following.

## Lifecycle re-entry
1. assign succeeds only from UNASSIGNED.
2. valid second assign while MOVING fails.
3. MOVING re-entry failure preserves all identity/route/progress/position state.
4. valid second assign after ARRIVED fails.
5. ARRIVED re-entry preserves endpoint/state/completion truth.
6. valid second assign after CANCELLED fails.
7. CANCELLED re-entry preserves state/identity/position.
8. cancel after ARRIVED does not downgrade ARRIVED.
9. agent reuse cannot create a second completion event.

## Multi-segment observability
10. handcrafted route has known >=3 segments.
11. chosen large delta provably crosses >=2 segment boundaries.
12. agent remains MOVING after that delta.
13. exact expected point on later segment is asserted.
14. huge delta crosses remaining route and exact-snaps endpoint.
15. completion still emits exactly once.

## Performance isolation
16. routes are precomputed before agent lifecycle timer starts.
17. timed region excludes route generation.
18. 5-agent isolated lifecycle timing exists.
19. 10-agent isolated lifecycle timing exists.
20. 25-agent isolated lifecycle timing exists.
21. 40-agent isolated lifecycle timing exists.
22. route timing, if reported, is separate.
23. no FPS/GPU/mobile-frame claim.
24. pooling remains absent unless isolated evidence genuinely justifies it.
25. pooling decision wording is appropriately limited to headless lifecycle evidence.

## Regression
26. no BoardState mutation.
27. no ReservationState mutation.
28. no target selection.
29. no route computation inside agent.
30. no return/carrying.
31. cancel-before-arrival prevents completion.
32. no orphan child/tween/timer lifecycle.
33. 59x59 compatibility.
34. rectangular VH compatibility.
35. debug scene smoke.
36. no M19/M20 leakage.
37. full Godot suite passes.
38. git diff --check clean.

## Governance/evidence
39. tasks.md untouched by Claude.
40. H!veAI/SESSION_INDEX/AUDIT_INDEX untouched.
41. matching CLAUDE_LOG_V02 exists with individual evidence.
42. Claude does not self-audit.
43. ChatGPT explicitly discloses independent runtime rerun availability.

If all pass, ChatGPT may re-close:
- SB-M18-001
- SB-M18-006
- SB-M18-014
- SB-M18-015

Only then is M18 finally closed under Strict Audit Standard v2 and M19 may resume.
