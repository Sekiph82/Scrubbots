# M12-C001 — Frozen Strict Audit Criteria V03

## Sentinel/configured query contract
1. fresh system is unconfigured and query -1 returns [] (must fail against the pre-fix sentinel behavior);
2. unconfigured valid integer query 0 returns [];
3. additional negative queries including -2 and -999 return [];
4. failed first configure preserves is_configured() == false;
5. failed first configure leaves every scalar slot palette at -1 and neither -1 nor 0 collection query materializes slots;
6. duplicate valid configuration [0,0,1,1,0] preserves duplicate support and queries exactly 0->[0,1,4], 1->[2,3];
7. non-present/high integer query such as 999 returns [];
8. failed reconfigure preserves prior duplicate palette ids and exact collection-query truth.

## Arbitrary Variant boundary
9. null query returns [] without fault;
10. float 0.0 returns [] without matching integer 0;
11. float 1.0 returns [] without matching integer 1;
12. String returns [] without fault;
13. bool false/true return [] without fault;
14. Vector2 returns [] without fault;
15. RefCounted junk returns [] without fault;
16. Array returns [] without fault;
17. Dictionary returns [] without fault;
18. invalid query never mutates slot/system truth.

## Valid query semantics / isolation
19. duplicate valid palette IDs remain legal;
20. valid integer query returns exact matching slot IDs;
21. valid query order is deterministic ascending slot id;
22. returned query Array is detached;
23. mutating returned Array cannot alter future query truth.

## Configure attack surface
24. exactly five entries required;
25. empty/4/6 entry arrays rejected;
26. null nested entry rejected atomically;
27. float nested entry rejected atomically;
28. String nested entry rejected atomically;
29. bool nested entry rejected atomically;
30. Vector2 nested entry rejected atomically;
31. RefCounted nested entry rejected atomically;
32. negative integer rejected atomically;
33. id == palette_size rejected atomically;
34. large out-of-range integer rejected atomically;
35. palette_size zero rejected;
36. negative palette_size rejected;
37. failed first configure leaves all five scalar palette ids at -1;
38. failed reconfigure preserves all five prior palette ids;
39. failed reconfigure preserves availability/activity;
40. caller palette_ids Array is not retained/aliased.

## Slot/state/encapsulation regression
41. exactly five slots;
42. stable IDs 0..4;
43. invalid slot ids fail with existing sentinel/false/error semantics;
44. availability/activity independent;
45. sibling slots unaffected by one-slot state change;
46. valid reconfigure preserves availability/activity;
47. get_slot() remains absent;
48. public query API exposes no internally owned SlotState;
49. independently-created SlotState cannot mutate SlotSystem truth.

## Architecture/governance
50. RefCounted model boundary preserved;
51. no UI/scene dependency;
52. no dispatch/target/reservation/routing/agent/session responsibility leakage;
53. no M13+ feature added;
54. full Godot 4.7.1 suite passes;
55. git diff --check clean;
56. governance untouched;
57. matching CLAUDE_LOG_V03 exists;
58. Claude does not self-audit;
59. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M12-005
- SB-M12-009
- SB-M12-011
