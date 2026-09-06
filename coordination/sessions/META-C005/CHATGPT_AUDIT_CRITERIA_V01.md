# META-C005 — ChatGPT Audit Criteria (V01)

Claude does not self-audit. ChatGPT audits after implementation.

PASS requires:

1. Root canonical palette remains unchanged: exactly C01..C15 with the existing IDs/HEX/RGB values.
2. BG01 remains exactly Midnight Slate `#202533` / RGB(32,37,51), is explicitly NOT C16, not a logical cell color, and excluded from difficulty color counts.
3. Difficulty distinct-used-color bands remain exactly EASY 3–5, MEDIUM 6–7, HARD 8–9, VERY_HARD 10–12.
4. `level_factory/CLAUDE.md`, README and relevant docs explicitly require future generator/validator/exporter work to consume the canonical root visual contract.
5. Level Factory docs explicitly record the flat square-cell rendering/generation rule: visible cell separation, flat solid canonical fill, no gloss/highlight/bevel/drop shadow/3D bead styling/interpolation.
6. ACTIVE/CLEARED semantics are correctly propagated: ACTIVE opaque canonical color, CLEARED alpha 0, BG01 visible through CLEARED.
7. A machine-readable descriptor exists under `level_factory/data/` and points back to the root palette source rather than becoming a second independent palette authority.
8. No Level Factory production rule permits off-palette colors, BG01 as a palette color, or grid/border colors to count toward difficulty.
9. No LF generator implementation is started in this docs/data governance cycle.
10. No locked gameplay, palette, background, board-size, or difficulty rule is changed.
11. No unjustified task checkbox/progress change is made.
12. Matching `CLAUDE_LOG_V01.md` contains real diff/verification/push evidence and H!ve/session tracking is updated to AWAITING_AUDIT.
