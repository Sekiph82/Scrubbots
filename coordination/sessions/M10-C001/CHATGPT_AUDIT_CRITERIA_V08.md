# M10-C001 — ChatGPT Audit Criteria (V08)

PASS requires:

1. Debug/manual-QA uses a dedicated gameplay QA rectangle derived from the owner reference, not the entire residual portrait area.
2. Owner reference source is treated as 887×1774 with gameplay region x=13, y=175, w=844, h=942.
3. At 1080×2160, QA region resolves approximately to x=16, y=213, w=1028, h=1147.
4. Selected logical board is centered inside that QA region.
5. BoardRenderer available_size is the QA region size.
6. Integer cell sizing and true logical aspect ratio remain intact.
7. Production maximum remains 59×59; no 75×75 production/debug logical board rule is introduced.
8. Level 007 remains immutable source 27×24 and fully visible at 30×30 and 59×59.
9. 007 logical offsets stay (1,3) and (16,17), artwork count 542.
10. 010/013 variable-canvas behavior remains intact.
11. Palette v2/C01..C16/C16 #000000/BG01 #202533 remain unchanged.
12. VOID semantics remain correct.
13. Flat-cell/no-bead/no-interpolation/no-per-cell-Node contract remains intact.
14. Debug info exposes QA region size, logical canvas, source offset, board pixel size and cell size.
15. Real deferred fixture-change runtime path still executes without error.
16. Full Godot 4.7.1 headless suite passes and debug runtime smoke succeeds.
17. tasks.md unchanged; SB-M10-005..011 remain owner QA gates; M14+ untouched.
18. Claude does not update H!veAI/PROJECT_DASHBOARD/SESSION_INDEX.
19. Matching CLAUDE_LOG_V08.md contains real implementation/test/push evidence.
20. Claude does not self-audit.
