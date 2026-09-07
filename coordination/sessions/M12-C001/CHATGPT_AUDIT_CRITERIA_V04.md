# M12-C001 — Strict Validation Criteria V04

## V03 frozen regressions
1. fresh unconfigured -1 collection query returns [];
2. unconfigured valid/negative queries remain fail-closed;
3. failed first configure preserves -1 scalar truth and empty collection queries;
4. duplicate valid configuration/query truth remains correct;
5. high/non-present integer query returns [];
6. failed reconfigure preserves valid collection-query truth;
7. arbitrary Variant collection query rejection remains green;
8. returned collection Array remains detached.

## Nested malformed configure entries
9. null nested entry fails atomically;
10. float nested entry fails atomically;
11. String nested entry fails atomically;
12. bool nested entry fails atomically;
13. Vector2 nested entry fails atomically;
14. RefCounted nested entry fails atomically;
15. each malformed FIRST configure leaves is_configured() false;
16. each malformed FIRST configure leaves all five palettes at -1;
17. malformed configured-state reconfigure preserves all five palettes;
18. malformed configured-state reconfigure preserves availability/activity.

## palette_size
19. palette_size 0 fails atomically;
20. palette_size -1 fails atomically;
21. both keep fresh system unconfigured;
22. both leave all five palette ids at -1;
23. ==palette_size and large out-of-range regressions remain green.

## Reconfigure state preservation
24. wrong-count failed reconfigure preserves configured flag;
25. wrong-count failed reconfigure preserves all palettes;
26. wrong-count failed reconfigure preserves all availability;
27. wrong-count failed reconfigure preserves all activity;
28. wrong-count failed reconfigure preserves collection-query truth;
29. malformed-entry failed reconfigure preserves configured flag;
30. malformed-entry failed reconfigure preserves all palettes;
31. malformed-entry failed reconfigure preserves all availability;
32. malformed-entry failed reconfigure preserves all activity;
33. malformed-entry failed reconfigure preserves collection-query truth.

## Successful reconfigure
34. second valid configure updates palette IDs;
35. successful reconfigure preserves availability;
36. successful reconfigure preserves activity;
37. successful reconfigure preserves stable IDs 0..4.

## Ownership / aliasing
38. caller palette_ids Array mutation after configure cannot alter palettes;
39. caller Array clear/append cannot alter collection-query truth;
40. standalone SlotState palette mutation cannot alter SlotSystem truth;
41. standalone SlotState availability mutation cannot alter SlotSystem truth;
42. standalone SlotState activity mutation cannot alter SlotSystem truth;
43. get_slot() remains absent;
44. no public query exposes an internally owned SlotState.

## Malformed-query no-mutation
45. complete invalid query set returns [] without runtime fault;
46. invalid query set preserves configured flag;
47. invalid query set preserves all five palettes;
48. invalid query set preserves all availability;
49. invalid query set preserves all activity.

## Canonical regression / governance
50. exactly five slots;
51. duplicate valid palette semantics;
52. invalid slot-id semantics;
53. availability/activity independence;
54. RefCounted/no-scene boundary;
55. no M13+ responsibility leakage;
56. full Godot 4.7.1 suite passes;
57. git diff --check clean;
58. production SlotSystem/SlotState remains unchanged unless strengthened test first exposes a real defect;
59. governance untouched;
60. matching CLAUDE_LOG_V04 exists;
61. Claude does not self-audit;
62. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M12-005
- SB-M12-009
- SB-M12-011
