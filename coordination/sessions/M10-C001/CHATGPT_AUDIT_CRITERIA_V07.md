# M10-C001 — ChatGPT Audit Criteria (V07)

PASS requires:

1. `get_item_disabled()` is removed from active code.
2. Correct Godot 4.x API `is_item_disabled(idx)` is used.
3. `set_item_disabled()` behavior remains intact.
4. Real Artwork fixture-change path runs without runtime error.
5. Level 007 size validation works: 30×30 and 59×59 valid; too-small choices cannot crop.
6. V05/V06 variable-canvas embedding remains unchanged.
7. Palette v2/C16/BG01 rules remain unchanged.
8. Full headless tests pass.
9. Debug scene runtime smoke executes deferred fixture-change logic, not parse-only.
10. tasks.md unchanged; M10-005..011 remain owner QA; M14+ untouched.
11. Claude does not modify H!veAI/PROJECT_DASHBOARD/SESSION_INDEX.
12. CLAUDE_LOG_V07.md contains real test/push evidence.
13. Claude does not self-audit.
