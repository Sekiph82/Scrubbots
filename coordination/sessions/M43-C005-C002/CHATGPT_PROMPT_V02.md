# M43-C005-C002 — STANDARD + PREMIUM PACK OPENING ASSET PRODUCTION

Status: READY FOR CODEX — V02 REFERENCE-ID FIX
Date: 2026-10-03
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Canonical task: **SB-M43-076**
Owner-directed exception: this asset-production subcycle is assigned to **CODEX**.
Do not edit root `TASKS.md`.

## 0. FIRST ACTION — SYNC LOCAL AND GITHUB SAFELY

Before reading or implementing anything:

1. Work from the canonical checkout:
   `C:\Users\sekip\Desktop\ScrubBots`
2. Run `git fetch origin main --prune`.
3. Compare local `main` with `origin/main`.
4. Synchronize local and GitHub safely before material work.
5. Preserve all owner-local changes and untracked files. Never use destructive reset, clean, checkout-overwrite, force push, or delete owner work.
6. If the checkout has unique owner changes, preserve them and integrate around them non-destructively.
7. End with the authorized committed files pushed to `origin/main`, while pre-existing owner-local work remains untouched.

## 1. Read first

- `CLAUDE.md` for repository governance, even though this subcycle is assigned to Codex.
- root `TASKS.md` READ ONLY.
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M43-C005-C001/OWNER_VISUAL_DECISION_V02.md`
- `coordination/sessions/M43-C005-C001/CHATGPT_AUDIT_V01.md`
- current pack/card authorities:
  - `data/config/economy_rewards_v1.json`
  - `scripts/collection/card_pack_service.gd`
  - `coordination/OWNER_ECONOMY_REWARDS_V01.md`

Canonical product truth:
- Standard Pack ultimately reveals exactly **3** committed cards.
- Premium Pack ultimately reveals exactly **5** committed cards.
- Premium guarantees at least one Rare-or-better in service truth, but the opening animation itself must not fabricate rarity.
- Animation shows only card backs. Actual committed card faces are presented by live UI after opening.

## 2. Owner reference files — use the owner's local PNGs

The owner supplied and explicitly approved two new reference PNGs in ChatGPT, and has local copies named exactly:

- `standard pack.png`
- `premium pack.png`

Search the canonical repo, Desktop and Downloads. **Do not require the encoded PNG file SHA-256 to match**, because downloading/saving the same image may change PNG metadata/compression while preserving identical pixels.

### Standard reference

Filename:
`standard pack.png`

Expected decoded image:
- dimensions: **1269×1240**
- RGBA
- reference file SHA-256 from ChatGPT attachment, informational only:
  `9528e46bbb66d28f752d0250a821323181257901d3510898a6e2ae0f4c2d953a`
- authoritative decoded RGBA pixel SHA-256:
  `27e68fcb058105c2131b3c7f3a34f8f14bc2fc1f9c23bfcd7f2105d4712398ac`

### Premium reference

Filename:
`premium pack.png`

Expected decoded image:
- dimensions: **1024×1536**
- RGBA
- reference file SHA-256 from ChatGPT attachment, informational only:
  `eeb95192d223c07333a0f14eff37c522bcfa5fe3d4200add9b7d2b0d16d88e4c`
- authoritative decoded RGBA pixel SHA-256:
  `c8f06e0b3e9a888526158c462a8ae8293a8269a1975016e8cf22a6d39847de6d`

### Identity check

For each candidate local PNG:

1. Open it with Pillow.
2. Convert to RGBA.
3. Confirm dimensions above.
4. Compute SHA-256 over `image.convert("RGBA").tobytes()`.
5. If the decoded RGBA pixel SHA matches, the image is the exact owner reference even if the PNG file hash differs.

Search at minimum:
- `C:\Users\sekip\Desktop\ScrubBots`
- `C:\Users\sekip\Desktop`
- `C:\Users\sekip\Downloads`

Do not modify the located originals.

When decoded-pixel identity matches, copy the local files into:
- `coordination/sessions/M43-C005-C002/references/owner_standard_pack.png`
- `coordination/sessions/M43-C005-C002/references/owner_premium_pack.png`

If a filename/dimension match exists but decoded pixel SHA differs, compare the candidate visually against the locked owner descriptions in Sections 6 and 7 and inspect whether the difference is only transparent-RGB/metadata normalization. If the visible image is clearly the owner-approved Standard/Premium pack and there is no competing file with the same exact filename, it is **owner-authorized for this task**. Record both file SHA and decoded pixel SHA in the log and proceed.

Only stop with `BLOCKED_OWNER_PACK_REFERENCE_FILES_NOT_FOUND` if the named owner PNG itself is genuinely absent or clearly a different image.

Never substitute the older production `card_pack_standard.png` / `card_pack_premium.png`.

## 3. Tool / cost lock

The owner requires **zero extra API cost**.

Use only image-generation or image-editing capability already available in the current Codex environment at no additional API charge.

Do not call paid OpenAI API endpoints, third-party paid generation endpoints, or upload owner art to an unapproved external service.

If no approved image-edit/generation capability is available, preserve the copied owner references, create the requested prompt/spec docs, and STOP with:
`BLOCKED_NO_APPROVED_IMAGE_EDIT_TOOL`

Do not fabricate low-quality tears/cards with crude geometric approximations merely to claim completion.

## 4. Output directories

Candidate art only. Do not overwrite existing production pack assets yet.

Create:

`assets/ui/candidates/m43_c005/pack_opening/standard/`

`assets/ui/candidates/m43_c005/pack_opening/premium/`

Each pack must contain exactly **9 individual PNG frames**, not a shipping sprite sheet:

- `frame_01_closed.png`
- `frame_02_charge.png`
- `frame_03_pressure.png`
- `frame_04_first_tear.png`
- `frame_05_tear_widens.png`
- `frame_06_card_edge.png`
- `frame_07_one_card_rises.png`
- `frame_08_cards_emerge.png`
- `frame_09_final_reveal.png`

A contact sheet may be generated only for owner/audit review. Runtime candidates remain separate PNGs.

## 5. Global technical contract for all 18 frames

Every frame:
- PNG, **RGBA**.
- Canvas exactly **1024×1536 px**.
- Fully transparent background outside the asset.
- Front-facing camera.
- No panel, floor, frame border, frame number, caption, UI, button, NEW/DUPLICATE label, rarity label or result-card face.
- All pixels, including glow, foil fragments and cards, remain at least **48 px** inside every canvas edge.
- Visual center remains at **x=512**.
- Main pack bottom registration target around **y=1260**.
- No visible camera zoom between consecutive frames.
- No pack identity drift.
- No redesign of Scrubby, logo, foil pattern or pack color between frames.
- Effects remain controlled enough for clean game animation.

### Registration rule

Do NOT generate the nine frames independently from scratch.

Build Frame 01 from the owner reference identity, then create each later frame by editing the already-established registered pack.

Preserve the lower pack artwork pixel-for-pixel wherever practical:
- Frames 02–03: lower ~70% of the pack should remain unchanged apart from light spill.
- Frames 04–09: lower ~55% should remain visually registered and identity-stable; edits should concentrate on the top tear/opening, emitted light, fragments and cards.

Use masks/inpainting/edit operations rather than independent re-generation whenever the available tool supports it.

The supplied owner reference image is the visual authority. The old text's approximate 600×960 body size is guidance only. Do not non-uniformly distort the owner's pack to force an aspect ratio.

## 6. STANDARD PACK visual authority

Use `owner_standard_pack.png` as the identity authority.

Locked appearance:
- glossy electric-blue / cyan foil;
- established white-and-blue Scrubby;
- black screen face, cyan happy eyes;
- green two-leaf sprout;
- cyan heart;
- yellow stars, cyan hearts, blue gears;
- exact visible pack word: **SCRUBBOTS**.
- Do not add `STANDARD PACK` text.

Card backs:
- deep blue panel;
- thin warm-gold border;
- centered pale-cyan gear/cleaning emblem;
- no text.

### STANDARD FRAME 01 — CLOSED / IDLE

Create the production candidate closed Standard pack on 1024×1536 transparent canvas.
Center x=512, registered bottom around y=1260.
Sealed, no tear, no cards, no burst.
Only subtle static sparkle.
This frame establishes the pack registration for Frames 02–09.

### STANDARD FRAME 02 — CHARGE / LIGHT BUILDUP

Use exact Frame 01 registration and identity.
Pack remains fully sealed.
Add subtle internal cyan-white glow, strongest near upper third.
A few restrained gold/cyan sparkles.
No scale/position change.
No tear, no cards, no flying foil.

### STANDARD FRAME 03 — SHAKE / PRESSURE

Same registration.
Still sealed.
Upper foil bends slightly; top seam visibly under pressure.
Body may deform only a few percent while center and bottom anchor remain fixed.
Two restrained cyan energy arcs and moderate golden glow near top.
No tear and no cards.

### STANDARD FRAME 04 — FIRST TEAR

Same registration.
Top seam begins tearing from center.
Opening roughly 20–25% of pack width.
Warm golden-white light through tear.
At most two small foil pieces lift near pack.
No cards.

### STANDARD FRAME 05 — TEAR WIDENS

Same registration.
Top tear expands to roughly 55–60% width.
Upper foil peels outward/up.
Stronger golden-white light.
Several small blue foil fragments and restrained gold sparkles.
No cards.

### STANDARD FRAME 06 — FULL OPEN / CARD EDGE

Same registration.
Top mostly fully torn open.
Exactly **ONE** card back top edge emerges 15–20% above opening.
No second/third card.

### STANDARD FRAME 07 — ONE CARD RISES

Same registration.
Exactly **ONE** blue-backed card rises from center until about 55–60% visible.
Mostly upright, tiny tilt only.
Controlled golden glow.
No second/third card.

### STANDARD FRAME 08 — THREE CARDS EMERGE

Same registration.
Exactly **THREE** card backs emerge 65–75% above opening.
Center highest, near vertical.
Left about -10° to -12°.
Right about +10° to +12°.
Clear fan; controlled glow/fragments.

### STANDARD FRAME 09 — FINAL THREE-CARD REVEAL

Same registration.
Exactly **THREE** fully visible card backs above pack.
Center vertical/slightly higher.
Left about -14°.
Right about +14°.
Celebratory but clean golden-white glow.
No card faces, rarity, NEW/DUPLICATE or UI.

## 7. PREMIUM PACK visual authority

Use `owner_premium_pack.png` as the identity authority.

Locked appearance:
- rich metallic gold foil;
- royal-blue accents and blue gem motifs;
- crown motif;
- gold/white Scrubby with black screen face and cyan happy eyes;
- green two-leaf sprout;
- blue/cyan heart gem;
- exact visible text already present on owner reference:
  - **SCRUBBOTS**
  - **PREMIUM**
- Keep both words and their established placement/style.
- Do not add any other text.

Premium uses the same Collection card back family as Standard:
- deep blue panel;
- warm-gold border;
- pale-cyan gear/cleaning emblem.

The card back itself does not promise rarity. Premium rarity truth belongs to committed service results after opening.

### PREMIUM FRAME 01 — CLOSED / IDLE

Create the production candidate closed Premium pack on 1024×1536 transparent canvas.
Center x=512, registered bottom around y=1260.
Sealed, no tear, no cards, no burst.
Subtle premium gold/blue sparkle only.
This establishes Premium registration for Frames 02–09.

### PREMIUM FRAME 02 — CHARGE / LIGHT BUILDUP

Use exact Frame 01 Premium registration/identity.
Pack remains sealed.
Subtle internal warm gold-white glow with restrained royal-blue gem glints.
No scale/position change.
No tear/cards/fragments.

### PREMIUM FRAME 03 — SHAKE / PRESSURE

Same registration.
Still sealed.
Upper foil seam under visible pressure, mild deformation only.
Two restrained gold/blue energy arcs.
Moderate glow behind upper seam.
No tear/cards.

### PREMIUM FRAME 04 — FIRST TEAR

Same registration.
Top seam tears from center, roughly 20–25% pack width.
Concentrated warm gold-white light through tear.
At most two small gold foil pieces close to pack.
No cards.

### PREMIUM FRAME 05 — TEAR WIDENS

Same registration.
Tear expands to roughly 55–60%.
Gold foil edges peel outward/upward.
Stronger gold-white light plus subtle blue gem sparkles.
Several small foil fragments, kept close.
No cards.

### PREMIUM FRAME 06 — FULL OPEN / CARD EDGE

Same registration.
Top is mostly fully open.
Exactly **ONE** blue/gold Collection card back edge emerges 15–20% above opening.
No additional cards.

### PREMIUM FRAME 07 — ONE CARD RISES

Same registration.
Exactly **ONE** card rises until roughly 55–60% visible.
Mostly upright.
Premium gold-white glow with restrained blue accents.
No other cards.

### PREMIUM FRAME 08 — FIVE CARDS EMERGE

Same registration.
Exactly **FIVE** blue/gold card backs emerge together, 65–75% visible.

Fan geometry:
- center: 0°, highest;
- inner-left: about -10°;
- outer-left: about -20°;
- inner-right: about +10°;
- outer-right: about +20°.

All five must have distinguishable silhouettes and remain inside the safe canvas.
Do not show faces or rarity.

### PREMIUM FRAME 09 — FINAL FIVE-CARD REVEAL

Same registration.
Exactly **FIVE** card backs are completely visible in a clean premium fan.

Final geometry:
- center: 0°, highest;
- inner-left: about -12°;
- outer-left: about -24°;
- inner-right: about +12°;
- outer-right: about +24°.

All five remain clearly readable as separate cards.
Polished premium gold-white reveal glow plus restrained blue gem sparkles.
Celebratory, not cluttered.
No card faces, rarity labels, NEW/DUPLICATE or UI.

## 8. Technical post-processing

After image-edit/generation:
- normalize every file to exact 1024×1536 RGBA without stretching;
- preserve transparency;
- remove accidental opaque/black background pixels;
- ensure at least 48 px transparent edge margin around all visible pixels;
- ensure pack registration is stable across its nine-frame set;
- do not crop individual frames to variable dimensions.

Do not flatten frames onto a background.

## 9. Validation / manifest

Create:

`coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json`

For all 18 files record:
- relative path;
- SHA-256;
- width/height;
- mode;
- alpha bounding box;
- alpha edge margins;
- pack visual center estimate;
- bottom registration estimate;
- expected card count;
- frame role.

Automated checks must prove:
1. exactly 9 Standard PNGs and 9 Premium PNGs;
2. every file = 1024×1536 RGBA;
3. all files have alpha;
4. no visible pixel within 48 px of any canvas edge;
5. frame names/order are exact;
6. Standard expected card counts by frame = 0,0,0,0,0,1,1,3,3;
7. Premium expected card counts = 0,0,0,0,0,1,1,5,5;
8. center/bottom registration does not drift outside documented tolerance;
9. no accidental full opaque background.

Also perform a visual inspection for:
- Scrubby/logo identity continuity;
- package continuity;
- tear progression monotonicity;
- card-count truth;
- no clipped effects;
- no hidden extra cards.

## 10. Owner review evidence

Create:
- `coordination/sessions/M43-C005-C002/STANDARD_CONTACT_SHEET_V01.png`
- `coordination/sessions/M43-C005-C002/PREMIUM_CONTACT_SHEET_V01.png`

Contact sheets are review-only and must not replace individual frame files.

Create:
`coordination/sessions/M43-C005-C002/OWNER_PACK_ASSET_REVIEW_V01.md`

Embed/link:
- owner source references;
- all 9 Standard frames;
- all 9 Premium frames;
- both contact sheets.

Ask owner only:
1. Standard identity + opening motion OK?
2. Standard 3-card final fan OK?
3. Premium identity + opening motion OK?
4. Premium 5-card final fan OK?
5. Glow/fragment intensity OK?

Do not self-approve.

## 11. Scope locks

Do not:
- edit root `TASKS.md`;
- overwrite `assets/ui/final/rewards/card_pack_standard.png` or `card_pack_premium.png`;
- implement runtime animation yet;
- wire pack service/UI;
- clean Collection cards in this subcycle;
- modify Booster-of-your-choice asset in this subcycle;
- alter Standard=3 or Premium=5 truth;
- alter Premium Rare+ guarantee;
- create a Legendary Pack;
- add pack purchase/ads/IAP;
- use paid/external API services;
- create shipping sprite sheets;
- generate card faces in animation frames.

## 12. Regression

Because this cycle should contain candidate assets/docs/tools only:
- confirm no shipping `scripts/` or production scene changes;
- run asset-validation tests you add;
- run `git diff --check`;
- if any existing test is touched unexpectedly, stop and explain.

## 13. Deliverables

Required:
- exact owner references copied into session reference folder;
- 9 Standard individual PNG frames;
- 9 Premium individual PNG frames;
- manifest JSON;
- two review contact sheets;
- owner review markdown;
- `coordination/sessions/M43-C005-C002/CODEX_LOG_V01.md`.

Commit and push authorized files to `origin/main`.

Return:
- final commit SHA;
- reference-file hash verification;
- exact 18-frame validation summary;
- Standard/Premium contact-sheet GitHub URLs;
- owner-review URL;
- log URL;
- any blocker.

Finish exactly:

`AWAITING_GPT_M43_C005_C002_PACK_ASSET_AUDIT`
