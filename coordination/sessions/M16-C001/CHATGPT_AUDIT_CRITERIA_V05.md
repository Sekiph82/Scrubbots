# M16-C001 — Frozen Strict Audit Criteria V05

Final closure requires all of the following.

## Board boundary
1. RouteValidator rejects null/non-BoardState board.
2. int board rejected.
3. String board rejected.
4. Vector2 board rejected.
5. RefCounted junk board rejected.
6. partial board rejected.
7. full-shape/wrong-return board rejected before its fake returns can poison M16.
8. RouteRequest.center_of_index uses the same safe BoardState boundary.
9. RouteRequest.for_target uses the same safe BoardState boundary.

## RouteRequest canonical factory
10. invalid target -> null.
11. NaN start -> null.
12. +INF start -> null.
13. -INF start -> null.
14. valid outside-left origin succeeds.
15. valid outside-right origin succeeds.
16. valid above origin succeeds.
17. valid below origin succeeds.
18. rectangular board succeeds.
19. target center/dimensions are canonical.
20. request stores no BoardState ref.

## Base RoutingSystem
21. null request does not throw.
22. int request does not throw.
23. String request does not throw.
24. Vector2 request does not throw.
25. RefCounted junk request does not throw.
26. malformed request target is -1.
27. real RouteRequest returns NOT_IMPLEMENTED and retains target.
28. no target selection/retarget/mutation added.

## Preserved validator matrix
29. malformed request object guard remains.
30. scalar board/result/access guards remain.
31. finite request guards remain.
32. finite intermediate point guards remain.
33. result coherence remains.
34. canonical failure validation remains.
35. bool-only access verdict remains.
36. normal true/false access remains.
37. wrong target/start/end rejected.
38. too-few points rejected.
39. blocked/open multi-segment behavior remains.
40. detached points remain.
41. no retarget remains.
42. no BoardState/ReservationState mutation.
43. board-local coordinate contract remains.
44. swappability remains.
45. 59x59 passes.
46. 53x59 passes.
47. no M17 implementation leakage.

## Validation/governance
48. full Godot 4.7.1 suite passes.
49. git diff --check clean.
50. governance untouched.
51. matching CLAUDE_LOG_V05 exists.
52. Claude does not self-audit.
53. ChatGPT records whether independent Godot rerun is available.

If all pass, ChatGPT may final-close M16 and re-close SB-M16-002/003/010/011.
