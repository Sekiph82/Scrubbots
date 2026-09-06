# M10-C001 — ChatGPT Audit Criteria (V04)

V04 supersedes V03 before implementation.

PASS requires:

1. Source matrices stay immutable: 007=27×24, 010=49×50, 013=28×31.
2. Real Artwork uses the selected debug canvas size, not the source bounding size and not a forced 59×59.
3. Selected canvas must fully contain the source matrix; too-small options cannot crop.
4. Placement is centered with floor((canvas-source)/2).
5. 007 fully renders at both 30×30 and 59×59 with offsets (1,3) and (16,17).
6. 007 keeps 542 artwork cells; debug VOID = 358 at 30×30 and 2939 at 59×59.
7. 010 fully renders at 50×50 and 59×59 with offsets (0,0) and (5,4); artwork stays 2450.
8. 013 fully renders at 39×39 and 59×59 with offsets (5,4) and (15,14); artwork stays 375.
9. Source VOID + added padding VOID never become ACTIVE.
10. Color counts/palette mappings remain invariant across canvas sizes.
11. BG01 remains #202533 and is not a logical palette color.
12. No logical resampling/scaling/cropping occurs; only canvas placement/padding.
13. Real Artwork Size dropdown is usable; invalid choices are disabled or rejected without cropping.
14. Debug info reports source size, selected canvas, offset, artwork count and total VOID.
15. Synthetic Stripes remains unchanged.
16. No per-cell Node architecture.
17. Full headless tests pass and debug scene boots clean.
18. tasks.md remains unchanged; SB-M10-005..011 remain owner manual-QA gates; M14+ untouched.
19. Matching CLAUDE_LOG_V04.md contains real implementation/test/push evidence.
20. Claude does not update H!veAI tracker/dashboard files.
