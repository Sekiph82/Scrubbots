# M10-C001 — ChatGPT Audit Criteria (V02)

V02 supersedes V01 for implementation. Claude must not self-audit.

PASS requires:

1. Fixture dropdown exactly: Synthetic Stripes, Real Artwork - Level 007, Real Artwork - Level 010, Real Artwork - Level 013.
2. The three real fixtures are loaded directly from:
   - `data/debug/board_renderer_fixtures/level_007.json`
   - `data/debug/board_renderer_fixtures/level_010.json`
   - `data/debug/board_renderer_fixtures/level_013.json`
   with no re-OCR/manual reconstruction.
3. Exact dimensions/counts/VOID/palette subsets match those JSON files.
4. All nonzero logical IDs are legal C01..C15; BG01 is `#202533`, is not C16, and is not inserted into logical palettes.
5. Level 010 preserves JSON blue-family mapping C06/C07/C08.
6. VOID remains a debug-only mask, never becomes colored under state-pattern changes, and no production BoardState VOID state is introduced.
7. ACTIVE is canonical opaque color; CLEARED is alpha 0.
8. Square cell boundaries remain visible while cell fills are flat; no gloss/highlight/bevel/shadow/3D bead styling/interpolation.
9. No per-cell Node architecture. BoardRenderer remains batched/constant-node-count in intent and evidence.
10. Synthetic Stripes retains existing behavior.
11. Real artwork fixed logical sizes are not silently resized/resampled by the size dropdown.
12. These fixtures remain TEST/debug/manual-QA only; no production catalog promotion, no difficulty-rule weakening, no M47/M48 closure.
13. SB-M10-005..011 remain OPEN for owner manual visual approval. M14+ remains untouched.
14. Full headless tests pass and debug scene headless parse/boot has no fatal errors.
15. `CLAUDE_LOG_V02.md` contains real implementation/test/diff/push evidence; H!ve/session tracking is updated to AWAITING_AUDIT.
