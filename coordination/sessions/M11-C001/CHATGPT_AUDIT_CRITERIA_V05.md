# M11-C001 — Frozen Strict Audit Criteria V05

## LevelData ownership
1. session stores its own detached LevelData source;
2. packed palette copied;
3. packed cells copied;
4. get_level_data returns detached snapshot;
5. snapshot scalar mutation cannot change source;
6. snapshot palette mutation cannot change source;
7. snapshot cells mutation cannot change source;
8. reset after hostile snapshot mutation restores original dimensions;
9. reset restores original color ids;
10. new snapshot after reset still matches original source;
11. failed replacement load preserves prior source truth;
12. failed replacement preserves prior BoardState identity/state.

## Renderer dependency
13. null explicitly unbinds;
14. int renderer rejected;
15. String renderer rejected;
16. Vector2 renderer rejected;
17. RefCounted junk renderer rejected;
18. partial/fake configure object rejected;
19. malformed replacement does not corrupt valid binding;
20. no malformed renderer configure call occurs.

## Renderer size
21. NaN size rejected/safely sanitized;
22. +INF size rejected/safely sanitized;
23. -INF size rejected/safely sanitized;
24. zero dimensions rejected/safely sanitized;
25. negative dimensions rejected/safely sanitized;
26. invalid size never reaches renderer geometry math.

## Renderer lifecycle
27. externally freed bound renderer detected safely;
28. reset after renderer free succeeds;
29. reset produces fresh BoardState and READY;
30. valid level load after renderer free succeeds;
31. stale renderer binding is cleared/dropped.

## Presentation/source isolation
32. renderer receives detached palette copy;
33. configure cannot alias internal source palette;
34. reset/reconfigure preserves internal palette;
35. no LevelData object passed to renderer.

## Canonical lifecycle regression
36. initial UNINITIALIZED;
37. valid load READY;
38. failed load clean;
39. fresh BoardState reset;
40. all ACTIVE reset;
41. independent sessions;
42. start/pause/resume transitions;
43. invalid transitions non-mutating;
44. reset from supported states;
45. UNINITIALIZED reset rejected;
46. explicit complete only from ACTIVE;
47. repeated complete safe;
48. no auto-complete from board clear;
49. valid renderer follows live BoardState;
50. renderer follows new BoardState after reset;
51. rectangular coverage;
52. 59x59 coverage;
53. no M12+ responsibility leakage;
54. no win/lose/timer/move-limit invention.

## Validation/governance
55. full Godot 4.7.1 suite passes;
56. git diff --check clean;
57. governance untouched;
58. matching CLAUDE_LOG_V05 exists;
59. Claude does not self-audit;
60. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close SB-M11-003/005/009/012.
