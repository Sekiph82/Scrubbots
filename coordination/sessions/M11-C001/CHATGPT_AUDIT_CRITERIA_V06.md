# M11-C001 — Strict Validation Criteria V06

## Detached source truth
1. hostile snapshot scalar mutation cannot change source;
2. hostile packed-array replacement cannot change source;
3. hostile packed-array in-place mutation cannot change source;
4. reset restores original BoardState dimensions/color IDs;
5. a NEW post-reset snapshot matches every original LevelData field;
6. failed replacement preserves every LevelData field;
7. failed replacement preserves BoardState identity/state.

## Renderer dependency sensitivity
8. positive-path spy is a real BoardRenderer subclass;
9. spy records configure_calls, last_board, last_palette and last_size;
10. int/String/Vector2/RefCounted/partial fake replacements return false;
11. partial fake configure is never called;
12. malformed replacements preserve original valid binding, proven by configure-count increment on reset;
13. null unbind prevents subsequent configure-count increment.

## Renderer size sensitivity
14. NaN x and NaN y each rejected with zero configure calls;
15. +INF x/y each rejected with zero configure calls;
16. -INF x/y each rejected with zero configure calls;
17. zero x/y each rejected with zero configure calls;
18. negative x/y each rejected with zero configure calls;
19. invalid-size replacement renderer is never configured;
20. invalid-size replacement preserves original renderer and size, proven after reset.

## Freed renderer lifecycle
21. reset after external renderer free succeeds and returns READY;
22. reset produces fresh BoardState;
23. valid level load after renderer free succeeds;
24. lifecycle can bind/configure a fresh renderer after stale-renderer handling.

## Palette/source isolation
25. initial configure receives detached palette;
26. mutating renderer A retained palette cannot change source;
27. renderer rebind to B cannot change source;
28. mutating renderer B retained palette cannot change source;
29. reset/reconfigure preserves source and gives B fresh original-valued palette;
30. no LevelData object is passed to renderer.

## Canonical regression/governance
31. full M11 lifecycle regression remains green;
32. rectangular and 59x59 coverage remains green;
33. no M12+ responsibility leakage;
34. no win/lose/timer/move-limit invention;
35. full Godot 4.7.1 suite passes;
36. git diff --check clean;
37. production session source remains unchanged unless a new strengthened test first exposes a real defect;
38. governance untouched;
39. matching CLAUDE_LOG_V06 exists;
40. Claude does not self-audit;
41. ChatGPT records independent Godot rerun availability.

If all pass, ChatGPT may final-close:
- SB-M11-003
- SB-M11-005
- SB-M11-009
- SB-M11-012
