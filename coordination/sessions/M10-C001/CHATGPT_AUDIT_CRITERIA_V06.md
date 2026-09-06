# M10-C001 — ChatGPT Audit Criteria (V06)

V06 supersedes unimplemented V05.

PASS requires:

## Palette v2
1. Canonical current palette is data/palettes/scrubbots_palette_v2.json.
2. Palette v2 contains exactly C01..C16.
3. C01..C15 are unchanged from historical v1.
4. C16 = Pure Black #000000 RGB(0,0,0).
5. C16 is a legal logical artwork color and counts when used.
6. BG01 remains #202533, outside C01..C16, never logical/counting.
7. Difficulty used-color bands remain 3–5 / 6–7 / 8–9 / 10–12.
8. Active runtime/debug/validator/test code has no stale hard limit of 15 where canonical palette legality is intended.
9. Historical evidence and palette v1 are preserved as historical.
10. Current fixture metadata points to v2 where such metadata exists; their grids/counts are unchanged.

## Variable canvas
11. 007 source stays 27×24 and fully renders at 30×30 and 59×59, offsets (1,3)/(16,17), artwork 542.
12. 010 source stays 49×50 and fully renders at 50×50 and 59×59, offsets (0,0)/(5,4), artwork 2450.
13. 013 source stays 28×31 and fully renders at 39×39 and 59×59, offsets (5,4)/(15,14), artwork 375.
14. Too-small canvases cannot crop.
15. No logical scaling/resampling; only centered VOID padding.
16. Source/padding VOID never become ACTIVE.
17. Size dropdown remains usable for Real Artwork.
18. Debug info reports source/canvas/offset/artwork/VOID.
19. Synthetic Stripes unchanged.
20. No per-cell Nodes; flat-cell visual contract preserved.

## Coordination
21. CLAUDE.md, coordination/README.md, coordination/VERSIONED_LOG_POLICY.md, level_factory/CLAUDE.md and content_pipeline/CLAUDE.md no longer instruct Claude to update H!veAI/PROJECT_DASHBOARD/SESSION_INDEX.
22. Those files assign tracker/session/dashboard updates to ChatGPT after audit.
23. Claude does not modify those tracker files in V06.
24. tasks.md checkbox state unchanged; SB-M10-005..011 remain owner QA; M14+ untouched.
25. Full headless tests pass; debug scene boots clean.
26. CLAUDE_LOG_V06.md contains real implementation/test/push evidence.
27. Claude does not self-audit.
