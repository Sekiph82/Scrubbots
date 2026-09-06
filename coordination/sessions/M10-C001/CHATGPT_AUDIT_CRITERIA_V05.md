# M10-C001 — ChatGPT Audit Criteria (V05)

V05 supersedes unimplemented V03/V04.

PASS requires both parts:

## A. Variable canvas placement

1. Source JSON matrices unchanged: 007=27×24, 010=49×50, 013=28×31.
2. Real Artwork uses selected Size canvas, not source dimensions and not forced 59×59.
3. Too-small canvases cannot crop.
4. Placement uses floor((canvas-source)/2).
5. 007 fully renders at 30×30 and 59×59 with offsets (1,3) and (16,17).
6. 007 artwork stays 542; debug VOID = 358 / 2939.
7. 010 fully renders at 50×50 and 59×59 with offsets (0,0) / (5,4); artwork stays 2450.
8. 013 fully renders at 39×39 and 59×59 with offsets (5,4) / (15,14); artwork stays 375.
9. Source/padding VOID never become ACTIVE.
10. Color counts/mappings invariant across canvas sizes.
11. BG01 exactly #202533, not logical palette.
12. No logical scaling/resampling/cropping.
13. Real Artwork Size dropdown remains usable with invalid-size protection.
14. Debug info reports source, canvas, offset, artwork and VOID.
15. Synthetic Stripes unchanged.
16. No per-cell Nodes.
17. Full headless tests pass and debug scene boots clean.

## B. Coordination ownership normalization

18. Root `CLAUDE.md`, `coordination/README.md`, `coordination/VERSIONED_LOG_POLICY.md`, `level_factory/CLAUDE.md`, and `content_pipeline/CLAUDE.md` no longer instruct Claude to update H!veAI tracker files, PROJECT_DASHBOARD, or SESSION_INDEX.
19. Those files explicitly assign:
    - Claude = implement/test/log/push/AWAITING_AUDIT/stop.
    - ChatGPT = independent audit/audit file/tracker+dashboard+SESSION_INDEX updates.
20. Unrelated governance remains intact.
21. `tasks.md` unchanged; SB-M10-005..011 remain owner QA gates; M14+ untouched.
22. Matching `CLAUDE_LOG_V05.md` contains real implementation/test/governance-scan/push evidence.
23. Claude does not update H!veAI tracker/dashboard/SESSION_INDEX files in V05.
24. Claude does not self-audit.
