# M10-C001 — ChatGPT Audit Criteria (V01)

Audit decision is reserved for ChatGPT after Claude implementation. Claude must not create or modify a ChatGPT audit file.

## Required PASS conditions

1. **Scope**
   - Work remains confined to M10 BoardRenderer debug/manual-QA tooling and required coordination/test/docs updates.
   - M14+ gameplay systems remain untouched.
   - SB-M10-005..011 remain open; no owner manual-QA checkbox is self-approved.

2. **Fixture selector**
   - `scenes/debug/board_renderer_debug.tscn` exposes, through its current script-driven UI, exactly:
     1. Synthetic Stripes
     2. Real Artwork - Level 007
     3. Real Artwork - Level 010
     4. Real Artwork - Level 013
   - Selection order is deterministic.

3. **Existing behavior preserved**
   - Synthetic Stripes retains existing size and ACTIVE/CLEARED pattern functionality.
   - Existing BoardRenderer architecture remains batched/constant-node-count.

4. **Canonical palette/background**
   - All real-artwork logical colors come from C01..C15 in `data/palettes/scrubbots_palette_v1.json`.
   - Local palettes are ascending by global C-ID.
   - BG01 is exactly `#202533` for real-artwork debug backgrounds.
   - BG01 is not inserted as a logical palette color.
   - CLEARED remains alpha 0.

5. **Level 007 exact data**
   - matrix 27×24 = 648 slots;
   - artwork cells 542;
   - VOID 106;
   - C04=217, C10=24, C14=165, C15=136;
   - layout matches `OWNER_FIXTURE_DATA_V01.md`.

6. **Level 010 exact data + recolor**
   - matrix 49×50 = 2450 slots;
   - VOID 0;
   - greens are mapped to blue family:
     bright→C06, mid→C07, dark→C08;
   - counts C01=16, C02=638, C03=560, C06=151, C07=603, C08=211, C14=229, C15=42;
   - layout matches `OWNER_FIXTURE_DATA_V01.md`.

7. **Level 013 exact data**
   - matrix 28×31 = 868 slots;
   - artwork cells 375;
   - VOID 493;
   - C02=68, C03=112, C09=26, C14=156, C15=13;
   - layout matches `OWNER_FIXTURE_DATA_V01.md`.

8. **VOID remains debug-only**
   - No production `BoardState.CellState.VOID` or equivalent production semantic is introduced.
   - VOID positions never become colored artwork when state patterns change.
   - VOID is excluded from used-color counts.
   - Debug implementation does not falsely claim VOID and CLEARED are the same logical concept.

9. **Cell visual contract**
   - Visible square cell separation/boundaries remain readable.
   - Cell interiors are flat canonical colors.
   - No gloss/highlight/bevel/drop-shadow/3D bead material.
   - No per-cell Nodes.
   - Boundary treatment is presentation-only and does not add logical palette colors.

10. **Production validation honesty**
    - The three fixtures are TEST/debug/manual-QA content, not automatically promoted to production catalog.
    - Difficulty rules are not weakened to make 49×50 or 28×31 production-valid.
    - M47/M48 production-content tasks are not marked complete.

11. **Tests/evidence**
    - Full headless regression suite passes.
    - Debug scene parses/boots headlessly without fatal errors.
    - Exact dimensions/counts/array lengths/palette membership are mechanically verified.
    - State-pattern regression proves VOID stability and CLEARED transparency.
    - Synthetic fixture regression passes.
    - Node-count/performance architecture is preserved.

12. **Coordination**
    - Matching `CLAUDE_LOG_V01.md` exists and contains real command/test evidence, failures/fixes, diff review and push status.
    - Session index and H!veAI tracking surfaces reflect M10-C001 as AWAITING_AUDIT after implementation.
    - Claude does not self-audit.

Any mismatch in exact fixture arrays/counts, any off-palette color, any production semantic widening, any per-cell Node design, or any self-closing of owner QA tasks is a FAIL/CHANGES_REQUIRED condition.
