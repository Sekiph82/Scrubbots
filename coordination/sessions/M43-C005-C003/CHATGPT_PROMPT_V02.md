# M43-C005-C003 — 135 INDIVIDUAL COLLECTION CARD REGENERATION V02

Status: READY FOR CLAUDE
Date: 2026-10-03
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Parent task: **SB-M43-076**
Primary builder: **CLAUDE**
Fallback builder only if Claude cannot generate images: **CODEX**

Root `TASKS.md` is READ ONLY for the builder.

## 0. OWNER LOCK — READ THIS FIRST

The owner has corrected this exact mistake multiple times.

**ALL 135 COLLECTION CARDS MUST BE PRODUCED INDIVIDUALLY, ONE BY ONE.**

This is NOT a crop-cleanup task.
This is NOT a sprite-sheet task.
This is NOT a 3x3-sheet generation task.
This is NOT “generate 9 cards together and slice them”.

The old canonical 135 PNGs are low-quality extractions from owner 3x3 Collection composites. They are reference/provenance only and must be replaced by newly produced individual card assets.

Hard rule:

> **ONE CARD = ONE SEPARATE IMAGE GENERATION / ONE SEPARATE FINAL PNG.**

A final card that was cropped out of a multi-card image is an automatic FAIL.

## 1. Safe sync

Work from the canonical ScrubBots checkout.

Before material work:
1. `git fetch origin main --prune`
2. compare local `main` vs `origin/main`;
3. preserve all owner-local dirty/untracked work;
4. use a clean worktree if needed;
5. never reset/clean/force-push/delete owner work.

## 2. Read first

- `CLAUDE.md`
- root `TASKS.md` READ ONLY
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C003/CARD_PROVENANCE_FINDING_V01.md`
- `data/config/economy_rewards_v1.json`
- `scripts/collection/collection_inventory.gd`
- `coordination/codex_visual_assets/CODEX_VISUAL_ASSET_MASTER_LIST.md` only as historical provenance
- owner source sheets:
  `assets/art/references/_owner_inbox/Collection Cards/`

Do not treat the historical “prefer crop/extraction” instruction as current authority. It is superseded by this owner lock.

## 3. Claude capability gate

Before touching final assets, determine whether Claude has an approved image-generation/image-edit capability available in the current environment with zero extra API cost.

If YES:
- Claude performs this task.

If NO:
- do not crop old sheets;
- do not fake completion with Pillow crops;
- do not substitute the old PNGs;
- do not hand-author crude placeholder cards;
- stop with exactly:
  `BLOCKED_CLAUDE_IMAGE_GENERATION_UNAVAILABLE`

ChatGPT will then hand this same contract to Codex.

Claude must not silently delegate or change the production method.

## 4. Canonical inventory

Canonical Collection:
- **15 sets**
- **9 cards per set**
- **135 cards total**

Set order:

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

Expected rarity profiles:
- Sets 1–14: **4 Common / 2 Rare / 2 Epic / 1 Legendary**
- Set 15: **3 Rare / 3 Epic / 3 Legendary**

File mapping remains:
- `card_01.png` = c0
- ...
- `card_09.png` = c8

No card IDs, set numbers, names, rarity truth or order may change.

## 5. Build a 135-row source-of-truth inventory BEFORE generation

Before generating Card 001, create:

`coordination/sessions/M43-C005-C003/COLLECTION_CARD_GENERATION_INVENTORY_V01.json`

Exactly 135 rows.

Each row must contain:
- global sequence 1..135;
- set number;
- canonical card file path;
- source owner sheet;
- row/column position in owner sheet;
- exact displayed card name;
- exact rarity;
- star count shown by the source;
- subject/character/object identity;
- key costume/tool/pose/theme traits;
- dominant palette/theme;
- generation status;
- output SHA once complete.

Use the owner 3x3 sheet only to READ identity/name/rarity/theme.

Temporary source crops may be made only for inspection/reference. **No source-sheet pixels may appear in the final card output.**

Do not begin the 135-card production run until the inventory is complete and internally checked against the rarity profiles.

## 6. Individual generation contract

Every one of the 135 cards is generated independently.

For every card:
1. form a card-specific prompt from its inventory row;
2. make a separate image generation/edit call for that one card only;
3. receive one isolated card artwork/result;
4. QA that one card;
5. save that one final PNG;
6. only then advance to the next card.

Never ask the generator for:
- 2 cards together;
- 3 cards together;
- 9 cards together;
- a set sheet;
- a contact sheet as generation output;
- a sprite sheet;
- a collage.

Contact sheets may be assembled **afterward for QA only** from already-finished individual PNGs.

## 7. Final card technical contract

Every final card:
- PNG;
- RGBA;
- canvas exactly **1024×1536 px**;
- transparent outside the card silhouette;
- one complete card only;
- card centered;
- no clipping of frame, stars, rarity header or name;
- no neighboring card pixels;
- no album/background panel;
- no set-navigation UI;
- no pack UI;
- no NEW/DUPLICATE badge baked in;
- no quantity baked in;
- no button/UI around the card.

Use one consistent Collection card family across all 135:
- Common family;
- Rare family;
- Epic family;
- Legendary family.

The card must include exact canonical:
- rarity label;
- rarity/star treatment;
- card name;
- subject identity.

Text accuracy is a hard gate.

If image generation cannot reliably render exact text, generate the unique card illustration separately and compose the exact approved rarity/name typography deterministically into the canonical card frame. This is allowed and preferred over misspelled AI text.

But the unique illustration itself must still be generated individually for that card. Do not reuse sheet crops.

## 8. Visual identity rules

The owner source sheet is the identity reference.

Preserve per-card concepts:
- same named subject/character/object;
- same core role/tool/costume concept;
- same set theme;
- same rarity.

You may improve:
- resolution;
- clean edges;
- lighting;
- composition;
- pose polish;
- material rendering;
- consistency.

Do not turn cards into unrelated new characters.

Do not clone one generated character pose across multiple cards unless the source itself depicts the same identity and the differences are intentionally represented.

Each card should feel like a deliberate individual collectible, not a zoomed screenshot.

## 9. Style consistency

All 135 cards must belong to one coherent SCRUBBOTS collectible-card family.

Lock before production:
- frame geometry;
- rarity color language;
- typography;
- star placement;
- subject safe area;
- name safe area;
- border thickness;
- internal art composition zone.

Create four approved template families first:
- Common
- Rare
- Epic
- Legendary

These templates may be reused as structural frames.

**Do not reuse unique subject art.**

## 10. Pilot gate before full 135 run

Before generating all cards, produce exactly 4 pilot cards:
- one Common;
- one Rare;
- one Epic;
- one Legendary;

preferably from Set 1 so identity is easy to compare against the owner source.

Save them under a candidate/pilot directory, not final paths.

Create:
`coordination/sessions/M43-C005-C003/OWNER_CARD_STYLE_PILOT_V01.md`

The pilot is a builder self-check only. If the four pilots are materially inconsistent, text is wrong, or they resemble source crops, fix the template/prompting pipeline before generating 135.

Do not ask the owner to manually approve 135 cards one by one before production unless ChatGPT explicitly creates a new owner gate.

## 11. Production paths

Once the pipeline passes the pilot self-check, replace exactly:

`assets/ui/final/collection/cards/set_01/card_01.png`
...
`assets/ui/final/collection/cards/set_15/card_09.png`

Snapshot all old 135 SHA-256 values before replacement.

No path additions/deletions inside the canonical 15×9 tree.

## 12. Per-card QA

Every card gets its own QA record.

Hard checks:
- one card only;
- 1024×1536 RGBA;
- transparent exterior;
- exact file path;
- exact name;
- exact rarity;
- exact star treatment;
- subject matches source identity;
- no sheet-crop provenance;
- no neighboring art;
- no malformed hands/limbs/tools severe enough to be production-breaking;
- no duplicated foreign text;
- no watermark;
- no accidental frame number;
- no generator prompt text baked into image.

If one card fails, regenerate that card only.

Do not regenerate an entire set just to fix one card unless absolutely necessary.

## 13. Evidence

Create:

`coordination/sessions/M43-C005-C003/evidence/`

Required evidence:
- 15 set contact sheets, each assembled from the 9 finished individual PNGs;
- one master 135-card contact sheet;
- four rarity-template examples;
- pilot comparison;
- random zoom QA samples from every set.

Contact sheets are QA composites only. They are never source assets.

Create:
- `COLLECTION_CARD_GENERATION_MANIFEST_V01.json`
- `COLLECTION_CARD_QA_MATRIX_V01.md`
- `OWNER_COLLECTION_CARD_REVIEW_V02.md`
- `CLAUDE_LOG_V01.md`

## 14. Manifest

For all 135 cards record:
- set;
- card index;
- name;
- rarity;
- source owner sheet;
- old production SHA;
- new production SHA;
- generation method;
- generation attempt count;
- final dimensions;
- alpha bounds;
- QA result;
- prompt/reference provenance.

The manifest must explicitly state:
`final_asset_origin = individually_generated`

Any row marked `cropped_from_sheet`, `sprite_sheet_slice`, or equivalent is a hard FAIL.

## 15. Automated validation

Add a validator that proves:
1. exactly 15 sets;
2. exactly 9 cards/set;
3. exactly 135 PNGs;
4. every PNG 1024×1536 RGBA;
5. every file has transparency outside card silhouette;
6. no empty image;
7. exact canonical paths unchanged;
8. manifest has 135 rows;
9. every row says individually generated;
10. names/rarities match inventory;
11. rarity profile per set is correct;
12. no multi-card generation artifact path is used as a final source;
13. old and new hashes differ for all cards unless a specific card is explicitly justified and owner-authorized;
14. pack-opening assets unchanged;
15. config/gameplay/runtime code unchanged.

## 16. Manual visual inspection

Claude must visually inspect all 135 final cards.

The log must contain one line per card with:
- identity OK;
- rarity OK;
- text OK;
- frame complete;
- no crop contamination;
- production quality PASS/FAIL.

Do not write “135 PASS” without per-card evidence.

## 17. Regression

Run:
- new card-asset validator;
- relevant M39 Collection tests;
- relevant M43 ceremony preview/card-path tests;
- root `tests/run_tests.gd`;
- `git diff --check`.

Do not “fix” unrelated historical timing failures in this task.

## 18. Scope locks

Do not:
- edit root `TASKS.md`;
- crop the 3x3 sheets into finals;
- generate a 9-card sheet and slice it;
- use current low-quality card PNGs as final art sources;
- change names;
- change rarity;
- change set order;
- change card IDs;
- change economy;
- change pack rules;
- touch Standard/Premium opening frames;
- implement Collection UI;
- implement ceremony runtime;
- work on Booster-of-your-choice in this cycle.

## 19. Failure behavior

If Claude cannot generate images:
finish exactly:
`BLOCKED_CLAUDE_IMAGE_GENERATION_UNAVAILABLE`

Do not attempt the old crop workflow.

If Claude can generate but a particular card cannot be made production-safe after reasonable retries:
- keep the previous canonical file untouched for that one path;
- report the card as blocked;
- do not silently ship a bad card;
- continue the remaining cards only if safe;
- final status must remain BLOCKED/PARTIAL, not PASS.

## 20. Finish

When all 135 independently generated cards are complete and validated:
- commit;
- push safely to `origin/main`;
- root `TASKS.md` remains untouched.

Return:
- final SHA;
- confirmation: **135 separate generation outputs / 135 final PNGs**;
- output dimension;
- number of regeneration retries;
- any blocked cards;
- master 135-card contact sheet URL;
- all 15 set contact-sheet URLs;
- `OWNER_COLLECTION_CARD_REVIEW_V02.md`;
- `COLLECTION_CARD_GENERATION_MANIFEST_V01.json`;
- `CLAUDE_LOG_V01.md`.

Finish exactly:

`AWAITING_GPT_M43_C005_C003_INDIVIDUAL_CARD_AUDIT`
