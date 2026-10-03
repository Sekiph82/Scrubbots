# M43-C005-C003 — COLLECTION CARD CLEAN RE-EXPORT

Status: READY FOR CODEX
Date: 2026-10-03
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Parent task: **SB-M43-076**
Do not edit root `TASKS.md`.

## 0. Mission

Cleanly re-export the canonical **135 Collection card PNGs** from the original owner source sheets.

The current production card crops have uneven dimensions and some contain neighboring-card / sheet-edge contamination. Replace those crops with clean, uniform, deterministic crops that preserve the original owner artwork exactly.

This is a crop/normalization job, **not generative redraw**.

Do not touch pack-opening assets in this cycle.

## 1. First action — safe sync

Work from canonical checkout:
`C:\Users\sekip\Desktop\ScrubBots`

Before material work:
1. `git fetch origin main --prune`
2. inspect local/main vs origin/main;
3. preserve all owner-local edits and untracked files;
4. if canonical checkout is dirty/behind, use a clean worktree from current `origin/main`;
5. never reset/clean/force-push/delete owner files.

## 2. Read first

- `CLAUDE.md`
- root `TASKS.md` READ ONLY
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C002/FINAL_OWNER_ACCEPTANCE_V01.md`
- `data/config/economy_rewards_v1.json`
- `scripts/collection/collection_inventory.gd`
- current `assets/ui/final/collection/cards/`
- original owner sheets under:
  `assets/art/references/_owner_inbox/Collection Cards/`

## 3. Canonical set mapping

Canonical Collection is **15 sets × 9 cards = 135 cards**.

Use config order:

1. Meet the Scrubbots
2. Cleaning Crew
3. Mess Monsters
4. Color Bots
5. Scrubbot Workshop
6. Bathroom Mayhem
7. Kitchen Chaos
8. Garage Grime
9. Sewer Squad
10. Clean City
11. Jungle Cleanup
12. Bath Time Blitz
13. Underwater Heroes
14. Space Cleaners
15. Ultimate Cleaners

Source filenames correspond to these names.

The owner inbox contains both:
- `cleaning crew.jpeg`
- `cleaning crew 2.jpeg`

Treat this as a duplicate/alternate-source anomaly:
- compare them visually and by hash/pixels;
- determine which one matches canonical Set 2 and the existing set_02 art;
- if they are pixel-identical, use `cleaning crew.jpeg` as canonical and record the duplicate;
- if materially different, stop only Set 2 promotion and document the discrepancy rather than guessing.

Do not create a sixteenth set.

## 4. Crop truth

Each owner source sheet contains a 3×3 card grid inside the Collection UI.

For every card:
- crop the complete card tile only;
- include the card's own full outer border/frame;
- include its own rarity header/stars;
- include its own artwork;
- include its own card name;
- exclude all beige album background;
- exclude neighboring-card pixels;
- exclude row/column gaps;
- exclude set title/header/progress/navigation UI;
- exclude any neighboring rarity badge or border sliver.

No card may contain pixels from another card.

## 5. Uniform output contract

Output paths stay canonical:

`assets/ui/final/collection/cards/set_01/card_01.png`
through
`assets/ui/final/collection/cards/set_15/card_09.png`.

All 135 output files must:
- be PNG;
- use one consistent canvas size/aspect ratio;
- preserve the complete card without stretching;
- use transparent padding if necessary to normalize dimensions;
- center the original crop in the normalized canvas;
- preserve original source pixels at native crop scale whenever possible;
- never non-uniformly distort the artwork;
- never recolor or sharpen with generative tools;
- never alter text, rarity, stars, card name, character/art.

If cards differ slightly in crop dimensions because of border antialiasing, normalize by transparent padding, not by destructive resizing.

## 6. Card order / rarity verification

Canonical card ids are:
- Set N: `sN_c0` through `sN_c8`
- file mapping: `card_01.png` = c0 ... `card_09.png` = c8

Expected rarity profiles:
- Sets 1–14: **4 Common / 2 Rare / 2 Epic / 1 Legendary**
- Set 15: **3 Rare / 3 Epic / 3 Legendary**

Do not reorder cards merely to match a rarity profile if the owner sheet establishes a clear left-to-right, top-to-bottom order.

Instead:
- preserve source visual order row-major;
- verify that the resulting rarity sequence matches config;
- if not, document and stop promotion for that set instead of silently shuffling.

## 7. Detection method

Prefer deterministic image analysis:
- establish the 3×3 grid/card rectangles from owner sheets;
- detect each card's outer frame boundaries;
- use one normalized crop policy across all sets;
- allow small per-card boundary adjustments only to capture the full border and eliminate neighboring pixels.

Do not use OCR as the primary crop method.

No image-generation model is required or permitted for card cleanup.

## 8. Visual QA

Create before/after evidence.

Required:
- one contact sheet per set showing all 9 cleaned cards;
- one master 15-set index contact sheet;
- at least one magnified edge QA sheet showing:
  - left/right card boundaries;
  - top rarity header;
  - bottom name area;
  - no neighbor slivers.

Create:
`coordination/sessions/M43-C005-C003/evidence/`

and:
- `COLLECTION_CARD_CROP_MANIFEST_V01.json`
- `COLLECTION_CARD_CLEANUP_MATRIX_V01.md`
- `OWNER_COLLECTION_CARD_REVIEW_V01.md`
- `CODEX_LOG_V01.md`

## 9. Manifest requirements

For all 135 cards record:
- set number;
- card index;
- source sheet;
- source crop box;
- source crop dimensions;
- output canvas dimensions;
- output SHA-256;
- alpha bounding box;
- detected/recorded rarity;
- card name if deterministically available from source metadata/manual inventory;
- neighbor-contamination check;
- mapping result.

Also record:
- source sheet hashes;
- Cleaning Crew duplicate comparison result.

## 10. Automated checks

Add/extend a dedicated validator proving:

1. exactly 15 sets;
2. exactly 9 PNGs per set;
3. exactly 135 PNGs total;
4. all output dimensions identical;
5. all images load correctly;
6. no crop is empty;
7. no card extends beyond normalized canvas;
8. source crop boxes do not overlap neighboring card rectangles;
9. no source crop crosses into another card's canonical region;
10. sets 1–14 visually/catalog-wise resolve to 4C/2R/2E/1L;
11. set 15 resolves to 3R/3E/3L;
12. row-major mapping is preserved;
13. existing gameplay card IDs remain unchanged;
14. no config/service code changed;
15. no pack-opening candidate asset changed.

## 11. Manual audit requirement

The builder must manually inspect **all 15 set contact sheets**.

The log must not say merely “all pass” from metadata.

For each set, record:
- 9/9 cards visually inspected;
- full border present;
- no left/right/top/bottom neighbor sliver;
- name area complete;
- rarity header complete.

If any card cannot be cleanly isolated from the source JPEG without losing part of its own border, do not invent pixels. Mark that card as blocked and report it.

## 12. Promotion safety

These paths are currently under `assets/ui/final/collection/cards/`, so this task replaces existing final crops.

Before replacement:
- snapshot hashes of all existing 135 files into the manifest;
- preserve a before-evidence index;
- ensure exact path count is unchanged.

Do not rename card files or directories.

No runtime code should require changes.

## 13. Regression

Run:
- collection/card asset validator;
- relevant M39 collection tests;
- any visual/path tests that reference card assets;
- root `tests/run_tests.gd`;
- `git diff --check`.

No historical unrelated timing failure should be “fixed” in this task.

## 14. Scope locks

Do not:
- edit root `TASKS.md`;
- change economy/config;
- change card rarities;
- change card names/art;
- change set order;
- create new cards;
- delete cards;
- regenerate artwork;
- touch Standard/Premium pack-opening frames;
- implement ceremonies/runtime;
- alter Booster-of-your-choice in this cycle;
- create Collection screen UI yet.

## 15. Finish

Commit and push safely to `origin/main`.

Return:
- final SHA;
- 135/135 validation summary;
- identical output canvas size;
- list of any blocked cards;
- Cleaning Crew duplicate result;
- master before/after contact-sheet URLs;
- OWNER_COLLECTION_CARD_REVIEW_V01.md URL;
- CODEX_LOG_V01.md URL.

Finish exactly:

`AWAITING_GPT_M43_C005_C003_COLLECTION_CARD_AUDIT`
