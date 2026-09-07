# M12-C001 — Frozen Strict Audit Criteria V03

## Sentinel/configured query contract
1. unconfigured query -1 returns [];
2. unconfigured valid integer query returns [];
3. every negative integer collection query returns [];
4. failed first configure preserves unconfigured state;
5. failed first configure cannot materialize sentinel matches;
6. valid configured integer query works;
7. failed reconfigure preserves prior valid collection-query truth.

## Arbitrary Variant boundary
8. null query returns [] without fault;
9. float 0.0 returns [] without matching integer 0;
10. float 1.0 returns [] without matching integer 1;
11. String returns [] without fault;
12. bool false/true return [] without fault;
13. Vector2 returns [] without fault;
14. RefCounted junk returns [] without fault;
15. Array returns [] without fault;
16. Dictionary returns [] without fault;
17. invalid query never mutates slot/system truth.

## Valid query semantics / isolation
18. duplicate valid palette IDs remain legal;
19. valid integer query returns exact matching slot IDs;
20. valid query order is deterministic ascending slot id;
21. returned query Array is detached;
22. mutating returned Array cannot alter future query truth.

## Configure attack surface
23. exactly five entries required;
24. empty/4/6 entry arrays rejected;
25. null nested entry rejected atomically;
26. float nested entry rejected atomically;
27. String nested entry rejected atomically;
28. bool nested entry rejected atomically;
29. Vector2 nested entry rejected atomically;
30. RefCounted nested entry rejected atomically;
31. negative integer rejected atomically;
32. id == palette_size rejected atomically;
33. large out-of-range integer rejected atomically;
34. palette_size zero rejected;
35. negative palette_size rejected;
36. failed first configure leaves all five scalar palette ids at -1;
37. failed reconfigure preserves all five prior palette ids;
38. failed reconfigure preserves availability/activity;
39. caller palette_ids Array is not retained/aliased.

## Slot/state/encapsulation regression
40. exactly five slots;
41. stable IDs 0..4;
42. invalid slot ids fail with existing sentinel/false/error semantics;
43. availability/activity independent;
44. sibling slots unaffected by one-slot state change;
45. valid reconfigure preserves availability/activity;
46. get_slot() remains absent;
47. public query API exposes no internally owned SlotState;
48. independently-created SlotState cannot mutate SlotSystem truth.

## Architecture/governance
49. RefCounted model boundary preserved;
50. no UI/scene dependency;
51. no dispatch/target/reservation/routing/agent/session responsibility leakage;
52. no M13+ feature added;
53. full Godot 4.7.1 suite passes;
54. git diff --check clean;
55. governance untouched;
56. matching CLAUDE_LOG_V03 exists;
57. Claude does not self-audit;
58. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M12-005
- SB-M12-009
- SB-M12-011
