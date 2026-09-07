# M19-C001 — ChatGPT Audit Criteria V01

AUDITED_PASS requires:

1. ScrubbotDispatcher exists.
2. Receives slot/color request.
3. Uses TargetSelector, not raw ColorCandidateIndex alone, for reachable work.
4. No reachable target -> zero spawn.
5. Successful selection atomically reserves target.
6. Exactly one agent per successful dispatch.
7. Unique owner IDs.
8. Agent identity matches owner/color/target.
9. Production routing used.
10. Route target equals reserved target.
11. No silent retarget.
12. Route failure releases reservation.
13. Route failure spawns zero agents.
14. Agent assign failure releases reservation.
15. Agent assign failure leaves no orphan node.
16. Failure-released target is dispatchable again.
17. Duplicate target assignments prevented.
18. Independent targets can dispatch independently.
19. Rapid input preserves uniqueness.
20. One-by-one semantics preserved.
21. BoardState not mutated.
22. Successful reservation remains held after dispatch.
23. Agent completion does not clear BoardState in M19.
24. Agent completion does not release successful reservation in M19.
25. Reset cancels active agents.
26. Reset releases dispatcher-owned reservations.
27. Reset leaves no orphan agents.
28. Reset does not mutate BoardState.
29. New dispatch works after reset.
30. 5-slot concurrent test.
31. 25-request stress.
32. 59×59 coverage.
33. Rectangular Very Hard coverage.
34. No M20 clearing implementation.
35. No pooling unless justified by profiling.
36. tasks.md untouched by Claude.
37. H!veAI / SESSION_INDEX / AUDIT_INDEX untouched.
38. Matching Claude log contains actual evidence.
39. Claude does not self-audit.
40. Godot rerun limitation explicitly disclosed by ChatGPT if not independently rerun.

If all pass, ChatGPT may close SB-M19-001..012.

Expected progress:
- overall 290 / 943 = 30.75%
- main game + SB-UI 290 / 719 = 40.33%
