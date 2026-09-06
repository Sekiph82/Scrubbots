# M10-C001 — ChatGPT Audit Criteria (V03)

PASS requires:

1. Real Artwork 007/010/013 render on a fixed 59×59 debug master grid.
2. Original JSON source matrices remain unchanged.
3. Deterministic centered offsets are exactly:
   - 007: (16,17)
   - 010: (5,4)
   - 013: (15,14)
4. Artwork cell counts remain exactly 542 / 2450 / 375.
5. Debug VOID counts are exactly 2939 / 1031 / 3106.
6. Source VOID and new padding VOID never become ACTIVE under any pattern.
7. Color counts and canonical palette mappings remain unchanged.
8. BG01 remains #202533 and is not a logical palette color.
9. No resampling/scaling of logical source matrices occurs; only placement/padding.
10. Real-artwork info text reports source size, 59×59 canvas, offset, artwork and VOID counts.
11. Synthetic Stripes remains unchanged.
12. No per-cell Node architecture.
13. Full headless tests pass and debug scene boots clean.
14. tasks.md remains unchanged; SB-M10-005..011 remain owner manual-QA gates; M14+ untouched.
15. Matching CLAUDE_LOG_V03.md contains real implementation/test/push evidence.
16. Claude does not update H!veAI tracker/dashboard files in V03.
