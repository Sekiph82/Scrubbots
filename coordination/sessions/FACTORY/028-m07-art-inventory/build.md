STATUS: READY

# Build: M07 level art inventory (SB-M07-011..013)

## Summary
Added docs/LEVEL_ART_INVENTORY.md (9 level images beyond M21 source, dims, palette colors, theme, owner-original; underwater: none supplied as of 2026-10-22; other theme art points to assets/art/references/inventory.json). TASKS.md: 011 and 013 ticked, 012 moved to the Not-queued standing-rules comment (conditional: if supplied), queue row DONE. Files: docs/LEVEL_ART_INVENTORY.md, TASKS.md.

## Acceptance criteria
1. [x] Inventory doc lists every level image: PNG dims read via python header parse of assets/art/levels/source/**; colors from data/levels/*.json palette length.
2. [x] Underwater stated none: grep for underwater found only a collection-card reference.
3. [x] TASKS.md ticks/queue updated as specified.
4. [x] Diff limited to doc + TASKS.md; git diff --check clean.

## Validation
git diff --check: clean. git status --porcelain: clean after commit.

## Log
### Round 1
Built as above.
