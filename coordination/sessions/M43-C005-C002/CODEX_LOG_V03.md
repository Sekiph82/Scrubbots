# Codex Log V03 — SB-M43-076

Status: `AWAITING_GPT_M43_C005_C002_V04_AUDIT`
Task: M43-C005-C002 / Standard + Premium targeted pack-asset remediation
Base: `origin/main` at `236c5b93d3ae95ca785eda799a7f72e0816cb199`
Root `TASKS.md`: read-only; unchanged.

## Scope and implementation

Changed only Standard and Premium frames 04, 06, and 08, the pack asset manifest, the V04 validator, V03 contact sheets, and the V04 composition/reference assets and scripts listed in the commit.

- Frames 04 use localized generated first-tear foil overlays over the registered closed-pack art. The measured center openings are Standard 101/458 px = 22.1%, and Premium 97/484 px = 20.0%.
- Frames 06 show one shared collection-card back at 16.9% Standard / 17.3% Premium visible exposure. The card is composed behind a visibly irregular foreground foil lip.
- Frames 08 preserve the accepted fan geometry and show exactly three Standard / five Premium card backs. Each card layer is clipped against the rendered uneven lip profile, and the lip is composited in front. Manual review of both contact sheets confirms the cards continue into the pouch, the lip crosses their roots at non-uniform heights, and there is no common straight clipping line.
- The Standard source frames 06/08 had a flattened near-black outer canvas. Only dark pixels connected to the exterior were made transparent, using a feathered alpha ramp; enclosed pack/card shadows remain intact.
- Built-in image generation created localized foil overlays. No external image service/API was used. Shared card-back art and approved pack source art were preserved.

## Verification

Commands run:

```text
python tools/remediate_m43_c005_pack_assets_v04.py
python tools/validate_m43_c005_pack_assets.py
git diff --check
```

Validator result:

```text
PASS: 18 frames; 9 per pack; 1024x1536 RGBA; all edge margins >=48px
PASS: Standard overlays 0,0,0,0,0,1,1,3,3
PASS: Premium overlays 0,0,0,0,0,1,1,5,5
PASS: rendered card-back emblem counts match metadata in frames 07-09
PASS: Frame 06 rendered card edge count=1 for each pack; exposure=15-20%
PASS: Frame 08 rendered counts=3 Standard / 5 Premium
PASS: Frame 04 rendered tear opening=20-25% pack width
PASS: all 12 frozen frame hashes unchanged
```

Manual visual assertion: the irregular front foil is visibly in front of the Frame 08 cards; left/center/right card roots (and Premium's outer roots) disappear at different points behind the foil folds; no shared straight card cutoff is visible; the fan reads as emerging from inside each pouch. The Frame 06 card edge remains behind the same foreground foil lip. Standard and Premium V03 contact sheets were inspected after rebuilding.

`git diff --check` returned no whitespace errors. Frozen-frame hashes are recorded individually in `PACK_ASSET_MANIFEST_V01.json`; all 12 match the V04 prompt locks. The asset validator is pixel-content-aware for rendered card emblems and card-edge matching; automated counts supplement, and do not replace, the manual depth assertion above.

## Review boundary

`OWNER_PACK_ASSET_REVIEW_V03.md` lists only the six requested frames. These remain candidate assets. No production asset, runtime, economy, root `TASKS.md`, Frame 07, or Frame 09 was changed. This log is builder evidence only; owner acceptance and the independent audit remain pending.

## Publication

Publication: this log is included in the final commit pushed to `origin/main`; the handoff reports that commit SHA after verifying remote parity.
