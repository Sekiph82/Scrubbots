# M43-C005-C003 — CHATGPT AUDIT CRITERIA V01

## Governance
- [ ] root TASKS.md untouched by Codex.
- [ ] no config/economy/runtime code changed.
- [ ] no pack-opening assets changed.
- [ ] no generative redraw used.

## Inventory
- [ ] 15 canonical sets.
- [ ] 9 cards/set.
- [ ] exactly 135 PNGs.
- [ ] canonical paths unchanged.
- [ ] old 135 hashes captured before replacement.

## Crop quality
- [ ] complete own card border retained.
- [ ] rarity header/stars retained.
- [ ] card art retained.
- [ ] card name retained.
- [ ] no neighboring-card pixels.
- [ ] no album background slivers.
- [ ] no row/column-gap contamination.
- [ ] no non-uniform stretching.
- [ ] uniform output dimensions via transparent padding when needed.

## Mapping
- [ ] source order preserved row-major.
- [ ] card_01..09 map to c0..c8.
- [ ] Sets 1–14 rarity profile = 4C/2R/2E/1L.
- [ ] Set 15 rarity profile = 3R/3E/3L.
- [ ] Cleaning Crew duplicate handled explicitly without inventing Set 16.

## Evidence
- [ ] 15 per-set contact sheets.
- [ ] master 15-set contact sheet.
- [ ] magnified edge QA evidence.
- [ ] crop manifest with source boxes + hashes.
- [ ] builder log records manual 9/9 inspection for every set.

## Tests
- [ ] dedicated 135-card validator passes.
- [ ] relevant M39 collection tests pass.
- [ ] root suite passes.
- [ ] git diff --check clean.

Any card with lost border, neighbor contamination, wrong mapping or changed art is a FAIL.
